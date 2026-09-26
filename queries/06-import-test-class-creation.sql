IF NOT EXISTS
(
    SELECT 1
    FROM tSQLt.TestClasses
    WHERE Name = 'ImportTests'
)
BEGIN
    EXEC tSQLt.NewTestClass 'ImportTests';
END;
GO