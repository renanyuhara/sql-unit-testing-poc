IF OBJECT_ID('ImportTests.[test only requested date is imported]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE ImportTests.[test only requested date is imported];
END;
GO

CREATE PROCEDURE ImportTests.[test only requested date is imported]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.STAGING_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description, IsValid)
    VALUES
        (120, '2026-09-26', '00001', 100.00, 'Requested date', 1),
        (121, '2026-09-25', '00001', 200.00, 'Other date', 1);

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
    VALUES (120, '2026-09-26', '00001', 100.00, 'Requested date');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO