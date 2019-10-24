GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[vwMFUserGroup]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'vwMFUserGroup', -- nvarchar(100)
    @Object_Release = '3.3.1.32', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'vwMFUserGroup'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW [dbo].[vwMFUserGroup]
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
	
ALTER  VIEW vwMFUserGroup
AS

SELECT CAST(mvli.MFid AS INT) AS UserGroupID, mvli.Name FROM dbo.MFValueListItems AS MVLI
INNER JOIN dbo.MFValueList AS MVL
ON mvli.MFValueListID = mvl.ID
WHERE mvl.name = 'User Group'

GO 
