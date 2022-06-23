GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[vwMFUserGroup]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwUserGroup', -- nvarchar(100)
    @Object_Release = '3.3.1.37', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
MODIFICATIONS
2017-06-21	LC	change name to standard naming for views

*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwUserGroup'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW [dbo].[MFvwUserGroup]
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
	
ALTER  VIEW MFvwUserGroup
AS

SELECT CAST(mvli.MFid AS INT) AS UserGroupID, mvli.Name FROM dbo.MFValueListItems AS MVLI
INNER JOIN dbo.MFValueList AS MVL
ON mvli.MFValueListID = mvl.ID
WHERE mvl.MFID = 16

GO 
