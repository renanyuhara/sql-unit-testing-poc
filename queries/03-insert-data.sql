INSERT INTO dbo.ACCOUNTS
(
    AccountNumber,
    AccountType,
    IsActive
)
VALUES
    ('00001', 'STANDARD', 1),
    ('00002', 'SPECIAL',  1),
    ('00003', 'STANDARD', 0);
GO


INSERT INTO dbo.RAW_TRANSACTIONS
(
    TransactionId,
    AccountingDate,
    AccountNumber,
    Amount,
    Description
)
VALUES
    (1, '2026-09-26', '00001', 100.00, 'Standard transaction'),
    (2, '2026-09-26', '00002', 250.00, 'Special transaction'),
    (3, '2026-09-26', '00003', 300.00, 'Inactive account transaction'),
    (4, '2026-09-26', '99999', 400.00, 'Unknown account transaction'),

    -- Another date, which must NOT be processed
    (5, '2026-09-25', '00001', 500.00, 'Previous day transaction');
GO