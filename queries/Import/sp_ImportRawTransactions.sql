IF OBJECT_ID('dbo.sp_ImportRawTransactions', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_ImportRawTransactions;
END;
GO

CREATE PROCEDURE dbo.sp_ImportRawTransactions
    @AccountingDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.RAW_TRANSACTIONS
    WHERE AccountingDate = @AccountingDate;

    INSERT INTO dbo.RAW_TRANSACTIONS
    (
        TransactionId,
        AccountingDate,
        AccountNumber,
        Amount,
        Description
    )
    SELECT
        st.TransactionId,
        st.AccountingDate,
        st.AccountNumber,
        st.Amount,
        st.Description
    FROM dbo.STAGING_TRANSACTIONS st
    WHERE st.AccountingDate = @AccountingDate
      AND st.IsValid = 1;
END;
GO