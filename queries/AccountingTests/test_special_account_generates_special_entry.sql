IF OBJECT_ID(
    'AccountingTests.[test special account generates special entry]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test special account generates special entry];
END;
GO

CREATE PROCEDURE AccountingTests.[test special account generates special entry]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.ACCOUNTS
    (
        AccountNumber,
        AccountType,
        IsActive
    )
    VALUES
    (
        '00002',
        'SPECIAL',
        1
    );

    INSERT INTO dbo.RAW_TRANSACTIONS
    (
        TransactionId,
        AccountingDate,
        AccountNumber,
        Amount,
        Description
    )
    VALUES
    (
        2,
        '2026-09-26',
        '00002',
        250.00,
        'Special transaction'
    );

    -- Act
    EXEC dbo.sp_ProcessAccounting
        @AccountingDate = '2026-09-26';

    -- Assert
    CREATE TABLE #Expected
    (
        TransactionId BIGINT,
        AccountingDate DATE,
        AccountNumber VARCHAR(20),
        Amount DECIMAL(18, 2),
        AccountingType VARCHAR(30)
    );

    INSERT INTO #Expected
    (
        TransactionId,
        AccountingDate,
        AccountNumber,
        Amount,
        AccountingType
    )
    VALUES
    (
        2,
        '2026-09-26',
        '00002',
        250.00,
        'SPECIAL_ENTRY'
    );

    SELECT
        TransactionId,
        AccountingDate,
        AccountNumber,
        Amount,
        AccountingType
    INTO #Actual
    FROM dbo.ACCOUNTING_ENTRIES;

    EXEC tSQLt.AssertEqualsTable
        '#Expected',
        '#Actual';
END;
GO