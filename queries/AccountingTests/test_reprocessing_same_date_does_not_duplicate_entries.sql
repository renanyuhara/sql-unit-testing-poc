IF OBJECT_ID(
    'AccountingTests.[test reprocessing same date does not duplicate entries]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test reprocessing same date does not duplicate entries];
END;
GO

CREATE PROCEDURE AccountingTests.[test reprocessing same date does not duplicate entries]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.ACCOUNTS (AccountNumber, AccountType, IsActive)
    VALUES ('00001', 'STANDARD', 1);

    INSERT INTO dbo.RAW_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description)
    VALUES
        (50, '2026-09-26', '00001', 500.00, 'Transaction to reprocess');

    -- Act
    EXEC dbo.sp_ProcessAccounting
        @AccountingDate = '2026-09-26';

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
    VALUES (50, '2026-09-26', '00001', 500.00, 'STANDARD_ENTRY');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO