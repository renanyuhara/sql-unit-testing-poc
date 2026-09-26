# SQL Server Unit Testing POC

This repository demonstrates how existing SQL Server stored procedures can be tested in isolation with [tSQLt](https://tsqlt.org/) using small, deterministic datasets instead of processing production-scale volumes.

The main goal of the POC is to show that legacy stored procedures can be tested without changing their implementation just to make them testable.

## Example pipeline

```text
STAGING_TRANSACTIONS
        |
        v
sp_ImportRawTransactions
        |
        v
RAW_TRANSACTIONS
        |
        | + ACCOUNTS
        v
sp_ProcessAccounting
        |
        v
ACCOUNTING_ENTRIES
```

The two stages are tested independently:

- `ImportTests`: `STAGING_TRANSACTIONS -> RAW_TRANSACTIONS`
- `AccountingTests`: `RAW_TRANSACTIONS + ACCOUNTS -> ACCOUNTING_ENTRIES`

A test for the second stage does not need to execute the first stage. Each test creates only the minimum data required for its scenario.

## Prerequisites

- SQL Server
- SQL Server Management Studio (SSMS) or another SQL client
- tSQLt
- CLR enabled on the SQL Server instance

`tSQLt` is intentionally not included in this repository. Download and install it from the official tSQLt distribution into a dedicated development/test database.

Do not install this POC or tSQLt into a production database.

## Initial database setup

Create a dedicated database for the POC, install tSQLt in it, and then execute the repository scripts required by the scenario.

The current POC uses the scripts under `queries/` to create the example tables, stored procedures, test classes, setup procedures, and test procedures.

All repository SQL scripts are intended to be re-runnable. Object creation scripts use a drop/create pattern or explicitly check whether the tSQLt test class already exists.

## Running tests

Run every test in the database:

```sql
EXEC tSQLt.RunAll;
```

Run one test class:

```sql
EXEC tSQLt.Run 'AccountingTests';
```

or:

```sql
EXEC tSQLt.Run 'ImportTests';
```

Run one test:

```sql
EXEC tSQLt.Run
    'AccountingTests.[test special account generates special entry]';
```

The current POC contains 13 tests: 9 `AccountingTests` and 4 `ImportTests`.

## Test isolation

Each test class has a `SetUp` procedure. tSQLt executes it automatically before each test in that class.

For example, `AccountingTests.SetUp` replaces the real source, lookup, and target tables with tSQLt fake tables. The stored procedure under test therefore executes normally, but only against the small dataset inserted by that test.

The data created by a test is isolated and rolled back by tSQLt. Tests should not depend on data created by another test and should be safe to run individually or in any order.

## Creating tests

For a stored procedure that already has a test class and `SetUp`, a new scenario normally requires only **one new SQL file** containing the new test procedure.

Do not modify the production stored procedure only to make a test possible. Identify its source tables, lookup/reference tables, and target tables; fake those dependencies; arrange the minimum dataset; execute the real procedure; and assert the result.

See [`docs/CREATING-TESTS.md`](docs/CREATING-TESTS.md) for the complete step-by-step guide, templates, and guidance for adding a new test class.
