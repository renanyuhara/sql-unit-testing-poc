CREATE OR ALTER PROCEDURE dbo.sp_ProcessAccounting
    @AccountingDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.ACCOUNTING_ENTRIES
    WHERE AccountingDate = @AccountingDate;

    INSERT INTO dbo.ACCOUNTING_ENTRIES
    (
        TransactionId,
        AccountingDate,
        AccountNumber,
        Amount,
        AccountingType
    )
    SELECT
        rt.TransactionId,
        rt.AccountingDate,
        rt.AccountNumber,
        rt.Amount,

        CASE
            WHEN a.AccountNumber IS NULL
                THEN 'UNCLASSIFIED'

            WHEN a.IsActive = 0
                THEN 'INACTIVE_ACCOUNT'

            WHEN a.AccountType = 'SPECIAL'
                THEN 'SPECIAL_ENTRY'

            ELSE 'STANDARD_ENTRY'
        END

    FROM dbo.RAW_TRANSACTIONS rt

    LEFT JOIN dbo.ACCOUNTS a
        ON a.AccountNumber = rt.AccountNumber

    WHERE rt.AccountingDate = @AccountingDate;
END;
GO