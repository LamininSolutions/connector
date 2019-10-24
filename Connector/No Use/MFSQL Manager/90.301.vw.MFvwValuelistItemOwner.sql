GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwValuelistItemOwner]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwValuelistItemOwner', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwValuelistItemOwner'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW [dbo].[MFvwValuelistItemOwner]
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2017-1

-- Description:	View of valuelist items ownership relations
-- Revision History:  
-- YYYYMMDD Author - Description 

select * from [MFvwValuelistItemOwner]
-- =============================================
*/		
ALTER VIEW [dbo].[MFvwValuelistItemOwner]
AS


    SELECT  [mvli].[ID] AS [ValuelistItem_ID]
          , [mvli].[Name] AS [ValuelistItem_Name]
          , [mvli].[MFID] AS [ValuelistItem_MFID]
          , [mvli].[MFValueListID]
          , [mvli].[OwnerID]
          , [mvli].[ItemGUID] AS [ValuelistItem_GUID]
          , [OwnerVL].[Valuelist_ID] AS [Valuelist_ID]
          , [OwnerVL].[Valuelist_Name] AS [Valuelist_Name]
          , [OwnerVL].[Valuelist_MFID] AS [Valuelist_MFID]
			,mvli2.[Name] AS OwnerItem_Name
			,ownervl.[VL_Owner_Name] AS OwnerValueList_Name
    FROM    [dbo].[MFValueListItems] AS [mvli]
    LEFT JOIN ( SELECT  [mvl].[ID] AS [Valuelist_ID]
                      , [mvl].[Name] AS [Valuelist_Name]
                      , [mvl].[MFID] AS [Valuelist_MFID]
                      , [mvl].[OwnerID] AS [VL_Owner_MFID]
                      , [mvl2].[ID] AS [VL_Owner_ID]
                      , [mvl2].[Name] AS [VL_Owner_Name]
                FROM    [dbo].[MFValueList] AS [mvl]
                INNER JOIN [dbo].[MFValueList] AS [mvl2] ON [mvl].[OwnerID] = [mvl2].[MFID]
                WHERE   [mvl].[OwnerID] <> 7
                        AND [mvl].[Deleted] = 0
              ) AS [OwnerVL] ON [OwnerVL].[Valuelist_ID] = [mvli].[MFValueListID]
   LEFT JOIN [dbo].[MFValueListItems] AS [mvli2]
   ON mvli.[OwnerID] = mvli2.[MFID] AND mvli2.[MFValueListID] = OwnerVL.[VL_Owner_ID]
   WHERE mvli.[Deleted] = 0

   GO
   