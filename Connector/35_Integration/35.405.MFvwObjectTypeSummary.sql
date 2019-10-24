
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwObjectTypeSummary]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'MFvwObjectTypeSummary' -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.47'           -- varchar(50)
                                    ,@UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[VIEWS]
    WHERE [TABLE_NAME] = 'MFvwObjectTypeSummary'
          AND [TABLE_SCHEMA] = 'dbo'
)
BEGIN
    SET NOEXEC ON;
END;
GO

CREATE VIEW [dbo].[MFvwObjectTypeSummary]
AS
SELECT [Column1] = 'UNDER CONSTRUCTION';
GO

SET NOEXEC OFF;
GO

/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2018-12

-- Description:	Summary of Records by object type and class
-- Revision History:  
-- YYYYMMDD Author - Description 

2019-1-18 LC	Fix bug on document collections
-- =============================================
*/
ALTER VIEW [dbo].[MFvwObjectTypeSummary]
AS
WITH [cte]
AS (
   SELECT [mottco].[ObjectType_ID]
         ,[mottco].[Class_ID]
         ,COUNT(*)                    [RecordCount]
         ,MAX([mottco].[Object_MFID]) [MaximumObjid]
   FROM [dbo].[MFObjectTypeToClassObject] AS [mottco]
   GROUP BY [mottco].[ObjectType_ID]
           ,[mottco].[Class_ID])
SELECT [mc].[Name]  AS [Class]
      ,[mot].[Name] AS [ObjectType]
      ,[cte].[RecordCount]
      ,[cte].[MaximumObjid]
      ,[mc].[IncludeInApp]
FROM [cte]
    INNER JOIN [dbo].[MFClass]      AS [mc]
        ON [cte].[Class_ID] = [mc].[MFID]
    INNER JOIN [dbo].[MFObjectType] AS [mot]
        ON [cte].[ObjectType_ID] = [mot].MFID
GO