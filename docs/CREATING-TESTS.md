# Creating tSQLt Tests

This guide explains how to run the existing test suite and how to add isolated unit tests for SQL Server stored procedures.

The intended audience is a developer who is new to this repository and may also be new to tSQLt.

## Core principle

The test adapts to the stored procedure. The stored procedure should not be changed only to make it testable.

For an existing procedure, identify:

1. source/input tables;
2. lookup or reference tables used by joins and business rules;
3. target/output tables modified by the procedure;
4. parameters required to execute the procedure;
5. the observable result that proves the business rule.

The test then replaces the table dependencies with `tSQLt.FakeTable`, inserts only the rows required by the scenario, executes the real stored procedure, and validates the result.

## How many files do I need?

| Situation | Typical change |
| --- | --- |
| Run existing tests | No new files |
| Add a scenario for an already tested procedure | **1 new test file** |
| Test an existing procedure that needs additional table dependencies | 1 new test file and update the existing `SetUp` |
| Introduce a new test area/class | Test-class creation script + `SetUp.sql` + one or more test files |

A new business scenario should normally be represented by one test procedure in one `.sql` file.

## Running existing tests

You do not need to open or modify the stored procedure to run its existing tests.

Run all tests:

```sql
EXEC tSQLt.RunAll;
```

Run a class:

```sql
EXEC tSQLt.Run 'AccountingTests';
```

Run one test:

```sql
EXEC tSQLt.Run
    'AccountingTests.[test special account generates special entry]';
```

A test should be executable independently. If it only works after another test has run, the test is not properly isolated.

## Adding a test to an existing test class

This is the most common workflow.

### 1. Read the stored procedure

Understand what the procedure reads and writes. You are looking for dependencies, not trying to reproduce the implementation in the test.

For `sp_ProcessAccounting`, the important dependencies are conceptually:

```text
RAW_TRANSACTIONS ----+
                     |
ACCOUNTS -------------+--> sp_ProcessAccounting --> ACCOUNTING_ENTRIES
```

### 2. Check the existing SetUp

Open the test class `SetUp.sql`.

For example, `AccountingTests.SetUp` fakes the tables shared by the accounting tests:

```sql
EXEC tSQLt.FakeTable 'dbo', 'RAW_TRANSACTIONS';
EXEC tSQLt.FakeTable 'dbo', 'ACCOUNTS';
EXEC tSQLt.FakeTable 'dbo', 'ACCOUNTING_ENTRIES';
```

`tSQLt` executes `SetUp` automatically before every test in the class.

Do not repeat these `FakeTable` calls inside every test.

If the new scenario requires another table that is a normal dependency of the procedure and should be isolated for all tests in the class, add it to `SetUp`.

### 3. Create one test file

Use a descriptive behavior-based name. For example:

```text
test_special_account_generates_special_entry.sql
```

The test procedure name should describe the expected behavior rather than implementation details.

### 4. Make the test script re-runnable

Every test file should safely recreate its test procedure:

```sql
IF OBJECT_ID(
    'AccountingTests.[test describes expected behavior]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test describes expected behavior];
END;
GO

CREATE PROCEDURE AccountingTests.[test describes expected behavior]
AS
BEGIN
    -- Arrange

    -- Act

    -- Assert
END;
GO
```

### 5. Arrange only the minimum data

Insert only the rows required to prove the scenario.

Do not copy a production-sized dataset into a unit test.

Example:

```sql
INSERT INTO dbo.ACCOUNTS
    (AccountNumber, AccountType, IsActive)
VALUES
    ('00002', 'SPECIAL', 1);

INSERT INTO dbo.RAW_TRANSACTIONS
    (TransactionId, AccountingDate, AccountNumber, Amount, Description)
VALUES
    (1, '2026-09-26', '00002', 100.00, 'Test transaction');
```

This is enough to test the behavior of one account even if the real procedure normally processes millions of rows.

### 6. Act by executing the real procedure

```sql
EXEC dbo.sp_ProcessAccounting
    @AccountingDate = '2026-09-26';
```

Do not duplicate the procedure logic inside the test.

### 7. Assert the expected behavior

Use `tSQLt.AssertEquals` when one scalar value is the clearest expression of the rule:

```sql
DECLARE @Actual VARCHAR(30);

SELECT @Actual = AccountingType
FROM dbo.ACCOUNTING_ENTRIES
WHERE TransactionId = 1;

EXEC tSQLt.AssertEquals
    @Expected = 'SPECIAL_ENTRY',
    @Actual = @Actual;
```

Use `tSQLt.AssertEqualsTable` when the complete resulting dataset matters. This is particularly useful for ETL/batch procedures because it verifies both the rows that should exist and the absence of unexpected rows.

Example pattern:

```sql
SELECT
    TransactionId,
    AccountingDate,
    AccountNumber,
    Amount,
    AccountingType
INTO #Actual
FROM dbo.ACCOUNTING_ENTRIES;

CREATE TABLE #Expected
(
    TransactionId BIGINT,
    AccountingDate DATE,
    AccountNumber VARCHAR(20),
    Amount DECIMAL(18, 2),
    AccountingType VARCHAR(30)
);

INSERT INTO #Expected
VALUES
    (1, '2026-09-26', '00002', 100.00, 'SPECIAL_ENTRY');

EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
```

### 8. Run the new test alone

```sql
EXEC tSQLt.Run
    'AccountingTests.[test describes expected behavior]';
```

Fix the test or implementation until the expected behavior is correctly represented.

### 9. Run the complete test class

```sql
EXEC tSQLt.Run 'AccountingTests';
```

This detects regressions within the same area.

### 10. Run the complete suite before committing

```sql
EXEC tSQLt.RunAll;
```

All existing tests should remain green.

## Complete test template

Copy this template when adding a scenario to an existing class:

```sql
IF OBJECT_ID(
    'AccountingTests.[test describes expected behavior]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test describes expected behavior];
END;
GO

CREATE PROCEDURE AccountingTests.[test describes expected behavior]
AS
BEGIN
    -- Arrange
    -- Insert only the minimum source/reference data required by the scenario.

    -- Act
    EXEC dbo.sp_ProcessAccounting
        @AccountingDate = '2026-09-26';

    -- Assert
    -- Use AssertEquals for a focused scalar assertion,
    -- or AssertEqualsTable when the resulting dataset is the behavior.
END;
GO
```

## Creating a new test class

Create a new class when the tests represent a different unit or processing stage rather than adding unrelated tests to an existing class.

This POC deliberately has two classes:

```text
ImportTests
    STAGING_TRANSACTIONS -> sp_ImportRawTransactions -> RAW_TRANSACTIONS

AccountingTests
    RAW_TRANSACTIONS + ACCOUNTS -> sp_ProcessAccounting -> ACCOUNTING_ENTRIES
```

This means a failure in the accounting transformation can be investigated without first running the staging/import process.

### 1. Create the class once

Use an idempotent script:

```sql
IF NOT EXISTS
(
    SELECT 1
    FROM tSQLt.TestClasses
    WHERE Name = 'MyProcedureTests'
)
BEGIN
    EXEC tSQLt.NewTestClass 'MyProcedureTests';
END;
GO
```

`tSQLt.NewTestClass` creates/marks the schema as a tSQLt test class. Do not call it unconditionally in a re-runnable deployment script.

### 2. Create SetUp.sql

Create a `SetUp` procedure for dependencies shared by the class:

```sql
IF OBJECT_ID('MyProcedureTests.SetUp', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE MyProcedureTests.SetUp;
END;
GO

CREATE PROCEDURE MyProcedureTests.SetUp
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'SOURCE_TABLE';
    EXEC tSQLt.FakeTable 'dbo', 'REFERENCE_TABLE';
    EXEC tSQLt.FakeTable 'dbo', 'TARGET_TABLE';
END;
GO
```

Then create one test file for each behavior.

## Why FakeTable is important

`FakeTable` allows the real stored procedure to refer to its normal table names while the test operates on isolated, empty table structures.

Therefore a procedure that normally processes millions of rows can be exercised against one or two rows without adding artificial filtering parameters to the production procedure.

This is the central technique demonstrated by this POC.

## Testing multi-stage pipelines

Do not automatically execute an entire pipeline to test one stage.

For a pipeline such as:

```text
TMP -> Procedure A -> RAW -> Procedure B + LOOKUPS -> MAIN
```

prefer independent tests:

```text
Test class A:
TMP -> Procedure A -> RAW

Test class B:
RAW + LOOKUPS -> Procedure B -> MAIN
```

For a Procedure B test, arrange the required RAW and lookup rows directly. Procedure A does not need to execute.

An end-to-end/integration test can still exist separately when useful, but it serves a different purpose from these isolated unit tests.

## Checklist for a new test

Before committing, confirm:

- The production stored procedure was not changed only to enable the test.
- The test belongs to the correct test class.
- Shared table dependencies are faked in `SetUp`.
- The test file is re-runnable (`DROP` / `CREATE`).
- Arrange contains only the minimum required data.
- The real stored procedure is executed in Act.
- The assertion describes observable business behavior.
- The test passes when run alone.
- The complete test class passes.
- `EXEC tSQLt.RunAll;` passes.

## Common mistakes

Avoid these patterns:

- relying on existing development database data;
- requiring another test to run first;
- inserting thousands or millions of rows when a few rows prove the rule;
- copying the stored procedure business logic into the test;
- changing the stored procedure only to add test-specific parameters;
- repeating the same `FakeTable` calls in every test instead of using `SetUp`;
- checking only that an expected row exists when unexpected extra rows would also represent a bug.

The objective is a small, deterministic test that explains one behavior and fails for one understandable reason.
