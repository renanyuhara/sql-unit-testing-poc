IF OBJECT_ID('AccountingTests.SetUp', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.SetUp;
END;
GO

CREATE PROCEDURE AccountingTests.SetUp
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'RAW_TRANSACTIONS';
    EXEC tSQLt.FakeTable 'dbo', 'ACCOUNTS';
    EXEC tSQLt.FakeTable 'dbo', 'ACCOUNTING_ENTRIES';
END;
GO