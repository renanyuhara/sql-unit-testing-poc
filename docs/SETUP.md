# Setting Up the SQL Unit Testing POC

This guide explains how to reproduce the current POC from a clean SQL Server database, including tSQLt installation and the required script execution order.

Use a dedicated local/development database. Do not install this POC or tSQLt in a production database.

## Table of contents

- [1. Prerequisites](#1-prerequisites)
- [2. Create a dedicated database](#2-create-a-dedicated-database)
- [3. Enable CLR](#3-enable-clr)
- [4. Install tSQLt](#4-install-tsqlt)
- [5. Verify the tSQLt installation](#5-verify-the-tsqlt-installation)
- [6. Create the POC database objects](#6-create-the-poc-database-objects)
- [7. Create the test classes](#7-create-the-test-classes)
- [8. Create SetUp procedures](#8-create-setup-procedures)
- [9. Create the tests](#9-create-the-tests)
- [10. Run the test suite](#10-run-the-test-suite)
- [11. Expected result](#11-expected-result)
- [12. Re-running the setup](#12-re-running-the-setup)
- [Quick execution checklist](#quick-execution-checklist)

## 1. Prerequisites

You need:

- SQL Server;
- SQL Server Management Studio (SSMS), or another SQL client capable of executing the scripts;
- permission to create a development/test database;
- permission to enable CLR on the SQL Server instance;
- the official tSQLt distribution.

Download tSQLt from the official tSQLt website. The tSQLt distribution itself is intentionally not committed to this repository.

## 2. Create a dedicated database

Create a database specifically for the POC. For example:

```sql
CREATE DATABASE SqlUnitTestingPoc;
GO
```

Then make sure every following script is executed against that database:

```sql
USE SqlUnitTestingPoc;
GO
```

The database name is not important. What matters is that the POC is isolated from production databases.

## 3. Enable CLR

tSQLt requires CLR support.

Run the following at SQL Server instance level using an account with the required permissions:

```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO
```

Verify the configuration:

```sql
SELECT
    name,
    value_in_use
FROM sys.configurations
WHERE name IN ('show advanced options', 'clr enabled');
```

For this POC, both values should report `1` before continuing.

> Enabling CLR is an instance-level configuration. In a company-managed SQL Server environment this may require DBA approval. Do not change server configuration without following the environment's operational rules.

## 4. Install tSQLt

Extract the official tSQLt distribution locally.

Inside the extracted package, locate the tSQLt installation script supplied by the framework (normally `tSQLt.class.sql`).

In SSMS:

1. connect to the SQL Server instance;
2. select the dedicated POC database;
3. open the tSQLt installation script;
4. verify that the query window is connected to the POC database;
5. execute the complete script.

The installation creates the `tSQLt` schema and the framework objects inside that database.

`tSQLt` is installed per database. Installing it in `SqlUnitTestingPoc` does not automatically install it in other databases on the same SQL Server instance.

## 5. Verify the tSQLt installation

Run:

```sql
EXEC tSQLt.RunAll;
```

Immediately after installing tSQLt, before this repository's test classes have been created, a result equivalent to the following is expected:

```text
Test Case Summary: 0 test case(s) executed,
0 succeeded, 0 skipped, 0 failed, 0 errored.
```

This confirms that the framework can execute successfully even though no POC tests exist yet.

You can also confirm that the framework schema exists:

```sql
SELECT name
FROM sys.schemas
WHERE name = 'tSQLt';
```

## 6. Create the POC database objects

From the repository, execute these scripts in this order:

```text
1. queries/01-table-creation.sql
2. queries/02-procedure-creation.sql
3. queries/03-insert-data.sql
4. queries/05-staging-table-creation.sql
5. queries/Import/sp_ImportRawTransactions.sql
```

Their roles are:

| Script | Purpose |
| --- | --- |
| `01-table-creation.sql` | Creates the core RAW, reference, and accounting tables used by the example |
| `02-procedure-creation.sql` | Creates the accounting processing stored procedure |
| `03-insert-data.sql` | Inserts the normal sample data used outside the isolated unit tests |
| `05-staging-table-creation.sql` | Creates the staging table for the first pipeline stage |
| `Import/sp_ImportRawTransactions.sql` | Creates the staging-to-RAW import procedure |

At this point the example application/database pipeline exists, but the POC test classes have not yet been created.

## 7. Create the test classes

Execute:

```text
6. queries/04-test-class-creation.sql
7. queries/06-import-test-class-creation.sql
```

These create the two tSQLt test classes used by the POC:

```text
AccountingTests
ImportTests
```

You can verify the registered classes with:

```sql
SELECT *
FROM tSQLt.TestClasses;
```

## 8. Create SetUp procedures

Execute:

```text
8. queries/AccountingTests/SetUp.sql
9. queries/ImportTests/SetUp.sql
```

`tSQLt` automatically executes the appropriate `SetUp` procedure before each test in its class.

The `SetUp` procedures call `tSQLt.FakeTable` for the tables that must be isolated. This is what allows the real stored procedures to execute against a tiny test-specific dataset instead of the normal database contents.

## 9. Create the tests

Execute every `test_*.sql` file under:

```text
queries/AccountingTests/
queries/ImportTests/
```

Do not execute the test files as an alternative to `tSQLt.Run`. Executing these scripts **creates the test stored procedures** in the database. The tests themselves are subsequently run by tSQLt.

The current POC contains:

```text
AccountingTests: 9 tests
ImportTests:     4 tests
Total:          13 tests
```

The order in which the individual `test_*.sql` creation scripts are executed is not important once their test class and `SetUp` exist.

## 10. Run the test suite

First, optionally validate each class independently:

```sql
EXEC tSQLt.Run 'ImportTests';
GO

EXEC tSQLt.Run 'AccountingTests';
GO
```

Then run the complete suite:

```sql
EXEC tSQLt.RunAll;
```

You can run an individual test during development:

```sql
EXEC tSQLt.Run
    'AccountingTests.[test special account generates special entry]';
```

## 11. Expected result

With the current repository version, `tSQLt.RunAll` should report:

```text
13 test case(s) executed
13 succeeded
0 failed
0 errored
```

The important architecture is:

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

The stages are tested independently:

```text
ImportTests:
STAGING_TRANSACTIONS -> sp_ImportRawTransactions -> RAW_TRANSACTIONS

AccountingTests:
RAW_TRANSACTIONS + ACCOUNTS -> sp_ProcessAccounting -> ACCOUNTING_ENTRIES
```

## 12. Re-running the setup

The repository scripts are designed to be re-runnable where appropriate:

- object scripts use drop/create patterns;
- test procedure scripts use drop/create patterns;
- test-class scripts check whether the class already exists before calling `tSQLt.NewTestClass`.

Be aware that table creation scripts may drop and recreate example tables. Re-running the full setup is appropriate for this disposable POC database, but the same deployment strategy should not be copied blindly to a real application database containing valuable data.

After changing or recreating database objects, the final validation remains:

```sql
EXEC tSQLt.RunAll;
```

## Quick execution checklist

For a clean environment:

```text
[ ] Create/select the dedicated POC database
[ ] Enable CLR and verify clr enabled = 1
[ ] Run the official tSQLt installation script in the POC database
[ ] EXEC tSQLt.RunAll -> 0 tests, no errors

[ ] queries/01-table-creation.sql
[ ] queries/02-procedure-creation.sql
[ ] queries/03-insert-data.sql
[ ] queries/05-staging-table-creation.sql
[ ] queries/Import/sp_ImportRawTransactions.sql

[ ] queries/04-test-class-creation.sql
[ ] queries/06-import-test-class-creation.sql

[ ] queries/AccountingTests/SetUp.sql
[ ] queries/ImportTests/SetUp.sql

[ ] Execute all queries/AccountingTests/test_*.sql files
[ ] Execute all queries/ImportTests/test_*.sql files

[ ] EXEC tSQLt.RunAll
[ ] Confirm 13/13 tests succeed
```

Once the environment is working, continue with [CREATING-TESTS.md](CREATING-TESTS.md) to add new test scenarios.