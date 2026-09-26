IF OBJECT_ID('ImportTests.[test valid transaction is imported]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE ImportTests.[test valid transaction is imported];
END;
GO

CREATE PROCEDURE ImportTests.[test valid transaction is imported]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.STAGING_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description, IsValid)
    VALUES
        (100, '2026-09-26', '00001', 100.00, 'Valid staging transaction', 1);

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
    VALUES (100, '2026-09-26', '00001', 100.00, 'Valid staging transaction');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO