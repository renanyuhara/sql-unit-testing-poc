IF OBJECT_ID(
    'AccountingTests.[test only requested accounting date is processed]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test only requested accounting date is processed];
END;
GO

CREATE PROCEDURE AccountingTests.[test only requested accounting date is processed]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.ACCOUNTS (AccountNumber, AccountType, IsActive)
    VALUES ('00001', 'STANDARD', 1);

    INSERT INTO dbo.RAW_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description)
    VALUES
        (10, '2026-09-26', '00001', 100.00, 'Requested date'),
        (11, '2026-09-25', '00001', 200.00, 'Other date');

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
    VALUES (10, '2026-09-26', '00001', 100.00, 'STANDARD_ENTRY');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO