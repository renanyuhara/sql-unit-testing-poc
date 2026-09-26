IF OBJECT_ID(
    'AccountingTests.[test unknown account generates unclassified entry]',
    'P'
) IS NOT NULL
BEGIN
    DROP PROCEDURE AccountingTests.[test unknown account generates unclassified entry];
END;
GO

CREATE PROCEDURE AccountingTests.[test unknown account generates unclassified entry]
AS
BEGIN
    -- Arrange
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
        4,
        '2026-09-26',
        '99999',
        400.00,
        'Unknown account transaction'
    );

    -- ACCOUNTS intentionally remains empty.

    -- Act
    EXEC dbo.sp_ProcessAccounting
        @AccountingDate = '2026-09-26';

    -- Assert
    DECLARE @Actual VARCHAR(30);

    SELECT @Actual = AccountingType
    FROM dbo.ACCOUNTING_ENTRIES
    WHERE TransactionId = 4;

    EXEC tSQLt.AssertEquals
        @Expected = 'UNCLASSIFIED',
        @Actual = @Actual;
END;
GO