IF OBJECT_ID('ImportTests.[test reprocessing replaces existing raw data]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE ImportTests.[test reprocessing replaces existing raw data];
END;
GO

CREATE PROCEDURE ImportTests.[test reprocessing replaces existing raw data]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.STAGING_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description, IsValid)
    VALUES
        (130, '2026-09-26', '00001', 300.00, 'Current staging transaction', 1);

    INSERT INTO dbo.RAW_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description)
    VALUES
        (999, '2026-09-26', '99999', 999.00, 'Stale raw transaction'),
        (998, '2026-09-25', '00001', 250.00, 'Previous date raw transaction');

    -- Act
    EXEC dbo.sp_ImportRawTransactions
        @AccountingDate = '2026-09-26';

    -- Assert
    SELECT TransactionId, AccountingDate, AccountNumber, Amount, Description
    INTO #Actual
    FROM dbo.RAW_TRANSACTIONS;

    CREATE TABLE #Expected
    (
        TransactionId BIGINT,
        AccountingDate DATE,
        AccountNumber VARCHAR(20),
        Amount DECIMAL(18, 2),
        Description VARCHAR(200)
    );

    INSERT INTO #Expected
    VALUES
        (130, '2026-09-26', '00001', 300.00, 'Current staging transaction'),
        (998, '2026-09-25', '00001', 250.00, 'Previous date raw transaction');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO