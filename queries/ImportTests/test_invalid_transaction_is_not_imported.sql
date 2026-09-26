IF OBJECT_ID('ImportTests.[test invalid transaction is not imported]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE ImportTests.[test invalid transaction is not imported];
END;
GO

CREATE PROCEDURE ImportTests.[test invalid transaction is not imported]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.STAGING_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description, IsValid)
    VALUES
        (110, '2026-09-26', '00001', 100.00, 'Valid transaction', 1),
        (111, '2026-09-26', '00002', 200.00, 'Invalid transaction', 0);

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
    VALUES (110, '2026-09-26', '00001', 100.00, 'Valid transaction');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO