GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwValuelistItemByPropertyClass]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwValuelistItemByPropertyClass', -- nvarchar(100)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwValuelistItemByPropertyClass'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW [dbo].[MFvwValuelistItemByPropertyClass]
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2016-5

-- Description:	View of valuelist items by property Class
-- Revision History:  
-- YYYYMMDD Author - Description 

select * from [MFvwValuelistItemByPropertyClass]
-- =============================================
*/		
ALTER VIEW [dbo].[MFvwValuelistItemByPropertyClass]
AS



SELECT ROW_NUMBER() OVER (ORDER BY v.ValuelistItemID) AS ID, v.* FROM  ( Select

mvli.ID AS ValuelistItemID ,
        [mvli].[Name] AS ValuelistItem ,
        [mvli].[MFID] AS ValuelistitemMFID ,
        [mvli].[AppRef] ,
        mvli.[Owner_AppRef] AS OwnerAppRef ,
        mvl.[Name] AS Valuelist ,
        mvli2.ID AS OwnerID ,
        [mvli2].[Name] OwnerValuelistitem ,
        mvl2.[Name] AS OwnerValuelist ,
        mp.[Name] AS PropertyName ,
		mp.MFID AS MFPropertyID,
        mc.Name AS className,
		mc.MFID AS MFClassID

--		SELECT *
FROM    [dbo].[MFValueListItems] AS [mvli]
        INNER JOIN [dbo].[MFValueList] AS [mvl] ON [mvl].[ID] = [mvli].[MFValueListID]
        left JOIN [dbo].[MFValueListItems] AS [mvli2] ON [mvli2].[AppRef] = [mvli].[Owner_AppRef]
        left JOIN [dbo].[MFValueList] AS [mvl2] ON [mvl2].[ID] = [mvli2].[MFValueListID]
        left JOIN [dbo].[MFProperty] AS [mp] ON [mp].[MFValueList_ID] = [mvl].[ID]
        left JOIN [dbo].[MFClassProperty] AS [mcp] ON [mp].ID = mcp.[MFProperty_ID]
        left JOIN [dbo].[MFClass] AS [mc] ON mc.ID = mcp.[MFClass_ID]
WHERE   [mvli].deleted = 0) AS v



GO

