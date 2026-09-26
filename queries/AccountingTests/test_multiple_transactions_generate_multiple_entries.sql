IF OBJECT_ID(
    'AccountingTests.[test multiple transactions generate multiple entries]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test multiple transactions generate multiple entries];
END;
GO

CREATE PROCEDURE AccountingTests.[test multiple transactions generate multiple entries]
AS
BEGIN
    -- Arrange
    INSERT INTO dbo.ACCOUNTS (AccountNumber, AccountType, IsActive)
    VALUES
        ('00001', 'STANDARD', 1),
        ('00002', 'SPECIAL', 1);

    INSERT INTO dbo.RAW_TRANSACTIONS
        (TransactionId, AccountingDate, AccountNumber, Amount, Description)
    VALUES
        (40, '2026-09-26', '00001', 100.00, 'Standard transaction'),
        (41, '2026-09-26', '00002', 200.00, 'Special transaction'),
        (42, '2026-09-26', '99999', 300.00, 'Unknown account transaction');

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
        (40, '2026-09-26', '00001', 100.00, 'STANDARD_ENTRY'),
        (41, '2026-09-26', '00002', 200.00, 'SPECIAL_ENTRY'),
        (42, '2026-09-26', '99999', 300.00, 'UNCLASSIFIED');

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO