IF OBJECT_ID(
    'AccountingTests.[test inactive account generates inactive account entry]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test inactive account generates inactive account entry];
END;
GO

CREATE PROCEDURE AccountingTests.[test inactive account generates inactive account entry]
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
        '00003',
        'STANDARD',
        0
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
        3,
        '2026-09-26',
        '00003',
        300.00,
        'Inactive account transaction'
    );

    -- Act
    EXEC dbo.sp_ProcessAccounting
        @AccountingDate = '2026-09-26';

    -- Assert
    DECLARE @Actual VARCHAR(30);

    SELECT @Actual = AccountingType
    FROM dbo.ACCOUNTING_ENTRIES
    WHERE TransactionId = 3;

    EXEC tSQLt.AssertEquals
        @Expected = 'INACTIVE_ACCOUNT',
        @Actual = @Actual;
END;
GO