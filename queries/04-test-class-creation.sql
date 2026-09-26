IF NOT EXISTS
(
    SELECT 1
    FROM tSQLt.TestClasses
    WHERE Name = 'AccountingTests'
)
BEGIN
    EXEC tSQLt.NewTestClass 'AccountingTests';
END;
GO