
/*

*/
--Created on: 2019-07-25 

DECLARE @ID INT
DECLARE @Table NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

if object_id('tempdb..#temptablelist') is not null
begin
    drop table #temptablelist
END

;
WITH cte AS
(
SELECT name, [s].[crdate], [s].[refdate], id FROM tempdb..[sysobjects] AS [s]
WHERE name LIKE '##objectlist_%'
UNION
SELECT name, [s].[crdate], [s].[refdate], id FROM tempdb..[sysobjects] AS [s]
WHERE name LIKE '##IsTemplateList_%'
UNION
SELECT name, [s].[crdate], [s].[refdate], id FROM tempdb..[sysobjects] AS [s]
WHERE name LIKE '##ExistingObject_%'
UNION
SELECT name, [s].[crdate], [s].[refdate], id FROM tempdb..[sysobjects] AS [s]
WHERE name LIKE '##TempNewObject_%'
UNION
SELECT name, [s].[crdate], [s].[refdate], id FROM tempdb..[sysobjects] AS [s]
WHERE name LIKE '##ObjidTable_%'

)

SELECT * INTO #temptablelist FROM [cte]

SELECT @id = MIN(id) FROM [#temptablelist] AS [t]
;

WHILE @id IS NOT NULL
BEGIN

SELECT @Table = name FROM [#temptablelist] AS [t] WHERE id = @ID

SET @SQL = 'Drop Table ' + @Table
EXEC (@SQL)

PRINT 'Table Dropped ' + @table

SELECT @id = (SELECT MIN(id) FROM [#temptablelist] AS [t] WHERE id > @id)

END
GO


