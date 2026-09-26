IF OBJECT_ID(
    'AccountingTests.[test processing date preserves entries from other dates]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test processing date preserves entries from other dates];
END;
GO

CREATE PROCEDURE AccountingTests.[test processing date preserves entries from other dates]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.ACCOUNTS (AccountNumber, AccountType, IsActive)
    VALUES ('00001', 'STANDARD', 1);

    INSERT INTO dbo.RAW_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description)
    VALUES
        (30, '2026-09-26', '00001', 300.00, 'Requested date');

    INSERT INTO dbo.ACCOUNTING_ENTRIES
        (TransactionId, AccountingDate, AccountNumber, Amount, AccountingType)
    VALUES
        (31, '2026-09-25', '00001', 250.00, 'STANDARD_ENTRY');

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
    VALUES
        (30, '2026-09-26', '00001', 300.00, 'STANDARD_ENTRY'),
        (31, '2026-09-25', '00001', 250.00, 'STANDARD_ENTRY');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO