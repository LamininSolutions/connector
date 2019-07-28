

/*
Script to add FileCount column to class tables for an existing installation prior to version 3.1.2.38

*/
SET NOCOUNT ON 

DECLARE @SQL NVARCHAR(MAX)

CREATE TABLE #IncludedInApp (TableName NVARCHAR(100))

INSERT INTO [#IncludedInApp]
(
    [TableName])

SELECT [mc].[TableName] FROM [dbo].[MFClass] AS [mc] WHERE [mc].[IncludeInApp] IN (1,2)

DECLARE @tableName NVARCHAR(100)

WHILE EXISTS(SELECT * FROM [#IncludedInApp] AS [iia])
BEGIN
select TOP 1 @Tablename = tablename FROM #includedInApp
IF NOT EXISTS(
SELECT * FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[TABLE_NAME] = @tableName
AND [c].[COLUMN_NAME] = 'FileCount')
BEGIN 
IF EXISTS(
SELECT * FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[TABLE_NAME] = @tableName)
Begin
PRINT 'Add column FileCount to ' + @TableName

SET @SQL = N'
ALTER TABLE ' +@TableName +'
add FileCount int'

EXEC (@SQL)
END
END
DELETE FROM [#IncludedInApp] WHERE [TableName] = @tableName
END

--SELECT * FROM [#IncludedInApp] AS [iia]

DROP TABLE [#IncludedInApp]

GO
