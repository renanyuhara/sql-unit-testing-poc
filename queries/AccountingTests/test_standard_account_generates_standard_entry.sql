IF OBJECT_ID(
    'AccountingTests.[test standard account generates standard entry]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test standard account generates standard entry];
END;
GO

CREATE PROCEDURE AccountingTests.[test standard account generates standard entry]
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
        '00001',
        'STANDARD',
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
        1,
        '2026-09-26',
        '00001',
        100.00,
        'Standard transaction'
    );

    -- Act
    EXEC dbo.sp_ProcessAccounting
        @AccountingDate = '2026-09-26';

    -- Assert
    DECLARE @Actual VARCHAR(30);

    SELECT @Actual = AccountingType
    FROM dbo.ACCOUNTING_ENTRIES
    WHERE TransactionId = 1;

    EXEC tSQLt.AssertEquals
        @Expected = 'STANDARD_ENTRY',
        @Actual = @Actual;
END;
GO