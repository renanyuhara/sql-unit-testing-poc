IF OBJECT_ID(
    'AccountingTests.[test processing date replaces existing entries for that date]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test processing date replaces existing entries for that date];
END;
GO

CREATE PROCEDURE AccountingTests.[test processing date replaces existing entries for that date]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.ACCOUNTS (AccountNumber, AccountType, IsActive)
    VALUES ('00001', 'STANDARD', 1);

    INSERT INTO dbo.RAW_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description)
    VALUES
        (20, '2026-09-26', '00001', 150.00, 'Current source transaction');

    -- Simulates stale output from an earlier processing run.
    INSERT INTO dbo.ACCOUNTING_ENTRIES
        (TransactionId, AccountingDate, AccountNumber, Amount, AccountingType)
    VALUES
        (99, '2026-09-26', '99999', 999.00, 'UNCLASSIFIED');

    -- Act
    EXEC dbo.sp_ProcessAccounting
        @AccountingDate = '2026-09-26';

    -- Assert
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
    VALUES (20, '2026-09-26', '00001', 150.00, 'STANDARD_ENTRY');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO