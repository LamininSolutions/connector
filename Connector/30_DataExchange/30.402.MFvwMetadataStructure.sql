GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwMetadataStructure]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwMetadataStructure', -- nvarchar(100)
    @Object_Release = '4.10.30.74', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwMetadataStructure'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW [dbo].[MFvwMetadataStructure]
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2016-5

-- Description:	View of metadata structure
-- Revision History:  
-- 2017-8-22	lc	fix property_alias spelling error
--2019-4-10		lc	add RealObjectType
-- =============================================
*/		
ALTER VIEW MFvwMetadataStructure
AS

/*rST**************************************************************************

=====================
MFvwMetadataStructure
=====================

Purpose
=======

This view allows for exploring the metadadata structure

Examples
========

review all the properties for a specific class

.. code:: sql

	SELECT *
	FROM   [MFvwMetadataStructure]
	WHERE  [class] = 'Customer' ORDER BY Property_MFID

----

review all the classes for a specific property

.. code:: sql

	SELECT class,*
	FROM   [MFvwMetadataStructure]
	WHERE  [Property] = 'Customer' ORDER BY class_MFID

----

review all the valueslists and their associated properties by class. Use to IsObjectType switch to show for valuelists or object types

.. code:: sql

   SELECT Valuelist, [mfms].[Property], class FROM [dbo].[MFvwMetadataStructure] AS [mfms]
   WHERE IsObjectType = 1

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-09-03  LC         Add Retain if null for ad hoc properties
2021-09-01  LC         Add valuelist_Class_MFID
2020-12-20  LC         Add MFDatatype_ID
2020-08-22  LC         Deleted column change to localisation
2020-07-08  LC         Add Valuelist Table name to columns
2020-03-27  LC         Add documentation for the view
==========  =========  ========================================================

**rST*************************************************************************/

    SELECT  [mp].[Name] AS Property ,
            [mp].[Alias] AS Property_alias ,
            [mp].[MFID] AS Property_MFID ,
			mp.[ID] AS Property_ID,
            [mp].[ColumnName] ,
            [mp].[PredefinedOrAutomatic] ,
            [mcp].[Required] ,
            RetainIfNull = CASE WHEN [mcp].isAdditional = 0 THEN 1 else ISNULL(mcp.RetainIfNull,0) end,
            IsAdditional = mcp.IsAdditional,
            CASE WHEN mvl.mfid = 0 THEN NULL ELSE [mvl].[Name] end AS Valuelist ,
             CASE WHEN mvl.mfid = 0 THEN NULL ELSE [mvl].[Alias] end AS Valuelist_Alias ,
			 CASE WHEN mvl.mfid = 0 THEN NULL ELSE mvl.id end AS Valuelist_ID,
             CASE WHEN mvl.mfid = 0 THEN NULL ELSE  [mvl].[MFID] END AS Valuelist_MFID ,
			CASE WHEN mvl.[RealObjectType] = 1 AND mvl.mfid = 0 THEN null ELSE mvl.[RealObjectType]  end AS IsObjectType,
            case when mvl.[RealObjectType] = 1 AND mvl.mfid > 0 then  mcmot.TableName else null end  as Valuelist_TableName,
            case when mvl.[RealObjectType] = 1 AND mvl.mfid > 0 then  mcmot.MFID else null end  as Valuelist_Class_MFID,
           [ValuelistOwner].[Name] AS Valuelist_Owner ,
            [mvl].[OwnerID] AS Valuelist_Owner_MFID ,
            [ValuelistOwner].[Alias] AS Valuelist_OwnerAlias ,
            [mc].[Name] AS Class ,
            [mc].[Alias] AS Class_Alias ,
            [mc].[MFID] AS class_MFID ,
            [mc].[IncludeInApp] ,
            [mc].[TableName] ,
            [mw].[Name] AS Workflow ,
            [mw].[Alias] AS Workflow_Alias ,
            [mw].[MFID] AS Workflow_MFID ,
            [mot].[Name] AS ObjectType ,
            [mot].[Alias] AS ObjectType_Alias ,
            [mot].[MFID] AS ObjectType_MFID ,
            [mdt].[SQLDataType] ,
            [mdt].[Name] AS MFDataType,
            mdt.MFTypeID
    FROM    [dbo].[MFProperty] AS [mp]
            LEFT JOIN [dbo].[MFClassProperty] AS [mcp] ON [mcp].[MFProperty_ID] = mp.[ID]
            LEFT JOIN [dbo].[MFClass] AS [mc] ON mc.[ID] = [mcp].[MFClass_ID]
            LEFT JOIN [dbo].[MFObjectType] AS [mot] ON mc.[MFObjectType_ID] = [mot].[ID]
            LEFT JOIN [dbo].[MFDataType] AS [mdt] ON mp.[MFDataType_ID] = [mdt].[ID]
            LEFT JOIN [dbo].[MFWorkflow] AS [mw] ON mw.[ID] = [mc].[MFWorkflow_ID]
            LEFT JOIN [dbo].[MFValueList] AS [mvl] ON mp.[MFValueList_ID] = mvl.[ID]
            left JOIN dbo.MFObjectType AS motmvl
            ON mvl.mfid = motmvl.mfid and mvl.mfid > 0
            LEFT JOIN dbo.MFClass AS mcmot
            ON motmvl.id = mcmot.MFObjectType_ID

            LEFT JOIN ( SELECT  [MFValueList].[Name] ,
                                [MFValueList].[Alias] ,
                                [MFValueList].[MFID]
                        FROM    MFValueList
                        UNION 
                        SELECT  [mot].[Name] ,
                                [mot].[Alias] ,
                                [mot].[MFID]
                        FROM    [dbo].[MFObjectType] AS [mot]
                      ) AS ValuelistOwner ON [mvl].[OwnerID] = [ValuelistOwner].MFID
    WHERE   mp.[Deleted] = 0;

	GO

