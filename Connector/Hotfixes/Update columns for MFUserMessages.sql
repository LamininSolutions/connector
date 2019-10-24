

/*
Hotfix
Apply to version 4.1.5.41 only

*/



IF EXISTS ( 
SELECT * FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
WHERE [c].[TABLE_NAME] = 'MFUserMessages' AND [c].[COLUMN_NAME] IN ('Workflow_State','Workflow_State_id')

 )
BEGIN

DECLARE @StateProp NVARCHAR(100)
DECLARE @SQL NVARCHAR(MAX)

SELECT @StateProp = name FROM MFProperty WHERE mfid = 39


SET @SQL = N'

ALTER TABLE [dbo].[MFUserMessages]
ADD ' + QUOTENAME(@StateProp) + ' NVARCHAR(100), ' + @StateProp + '_ID INT'

PRINT 'Columns added ' + QUOTENAME(@StateProp) + ' NVARCHAR(100), ' + @StateProp + '_ID INT'

EXEC (@SQL)

ALTER TABLE [dbo].[MFUserMessages]
DROP COLUMN Workflow_state_id, Workflow_State


PRINT 'Columns dropped  Workflow_state_id, Workflow_State' 

END
