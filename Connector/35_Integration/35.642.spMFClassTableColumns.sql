GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].spMFClassTableColumns';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFClassTableColumns'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.4.11.53'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  2019-1-19		LC			Change datatype from bit to smallint for error columns
  2019-3-25		LC			add error checking for text columns that is not varcahr 200
  2019-6-7		LC			add error for lookup column label with incorrect length
  2019-08-29    LC          add predefined or automatic column
  ********************************************************************************
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFClassTableColumns' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFClassTableColumns]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFClassTableColumns] 
AS
/*rST**************************************************************************

=====================
spMFClassTableColumns
=====================


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    SET NOCOUNT ON;

    IF
    (
        SELECT ISNULL(OBJECT_ID('tempdb..##spMFClassTableColumns'), 0)
    ) > 0
        DROP TABLE [##spMFClassTableColumns];



    --SELECT * FROM [dbo].[MFvwClassTableColumns] AS [mfctc]
    DECLARE @IsUpToDate BIT;

    EXEC [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

    IF @IsUpToDate = 0
    BEGIN
        EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'Property'; -- varchar(100)

        EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'Class'; -- varchar(100)
    END;

    CREATE TABLE [##spMFClassTableColumns]
    (
        [id] INT IDENTITY
       ,[ColumnType] NVARCHAR(100)
       ,[Class] NVARCHAR(200)
       ,[TableName] NVARCHAR(200)
       ,[Property] NVARCHAR(100)
       ,[Property_MFID] INT
       ,[columnName] NVARCHAR(100)
       ,[AdditionalProperty] BIT
       ,[IncludedInApp] BIT
       ,[Required] BIT
	   ,PredefinedOrAutomatic bit
       ,[LookupType] NVARCHAR(100)
       ,[MFdataType_ID] INT
       ,[MFDataType] NVARCHAR(100)
       ,[column_DataType] NVARCHAR(100)
       ,[length] INT
       ,[ColumnDataTypeError] smallint
       ,[MissingColumn] smallint
       ,[MissingTable] smallint
       ,[RedundantTable] smallint
    );

    INSERT INTO [##spMFClassTableColumns]
    (
        [Property]
       ,[Property_MFID]
       ,[columnName]
       ,[Class]
       ,[TableName]
       ,[IncludedInApp]
       ,[Required]
	   ,PredefinedOrAutomatic
       ,[LookupType]
       ,[MFdataType_ID]
       ,[MFDataType]
       ,[AdditionalProperty]
    )
    SELECT [mp2].[Name] [property]
          ,[mp2].[MFID]
          ,[mp2].[ColumnName]
          ,[mc2].[Name] AS [class]
          ,[mc2].[TableName]
          ,[mc2].[IncludeInApp]
          ,[mcp2].[Required]
		  ,[mp2].[PredefinedOrAutomatic]
          ,CASE
               WHEN [mvl].[RealObjectType] = 1
                    AND [mdt].[MFTypeID] IN ( 9, 10 ) THEN
                   'ClassTable_' + [mvl].[Name]
               WHEN [mvl].[RealObjectType] = 0
                    AND [mvl].[Name] NOT IN ( 'class', 'Workflow', 'Workflow State' )
                    AND [mdt].[MFTypeID] IN ( 9, 10 ) THEN
                   'Table_MFValuelist_' + [mvl].[Name]
           END
          ,[mdt].[MFTypeID]
          ,[mdt].[Name]
          ,0
    --select *
    FROM [dbo].[MFProperty]                AS [mp2]
        INNER JOIN [dbo].[MFClassProperty] AS [mcp2]
            ON [mcp2].[MFProperty_ID] = [mp2].[ID]
        INNER JOIN [dbo].[MFClass]         AS [mc2]
            ON [mc2].[ID] = [mcp2].[MFClass_ID]
        INNER JOIN [dbo].[MFDataType]      AS [mdt]
            ON [mdt].[ID] = [mp2].[MFDataType_ID]
        INNER JOIN [dbo].[MFValueList]     AS [mvl]
            ON [mvl].[ID] = [mp2].[MFValueList_ID]
    --		WHERE mc2.name = 'Customer';
    ;

    MERGE INTO [##spMFClassTableColumns] [t]
    USING
    (
        SELECT [sc].[name]         AS [ColumnName]
              ,[sc].[max_length]   AS [length]
              ,[sc].[is_nullable]
              ,[st].[name]         AS [TableName]
              ,[t].[name]          AS [Column_DataType]
              ,[mc].[Name]         AS [class]
              ,[mc].[IncludeInApp] AS [IncludedInApp]
        FROM [sys].[columns]           [sc]
            INNER JOIN [sys].[tables]  [st]
                ON [st].[object_id] = [sc].[object_id]
            INNER JOIN [dbo].[MFClass] AS [mc]
                ON [mc].[TableName] = [st].[name]
            INNER JOIN [sys].[types]   AS [t]
                ON [sc].[user_type_id] = [t].[user_type_id]
    ) [s]
    ON [s].[ColumnName] = [t].[ColumnName]
       AND [s].[TableName] = [t].[TableName]
    WHEN MATCHED THEN
        UPDATE SET [t].[Column_Datatype] = [s].[Column_DataType]
                  ,[t].[Length] = [s].[length]
                  ,[t].[IncludedInApp] = [s].[IncludedInApp]
    WHEN NOT MATCHED THEN
        INSERT
        (
            [TableName]
           ,[ColumnName]
           ,[Column_DataType]
           ,[length]
           ,[class]
           ,[IncludedInApp]
        )
        VALUES
        ([s].[TableName], [s].[ColumnName], [s].[Column_DataType], [s].[length], [s].[class], [s].[IncludedInApp]);

    UPDATE [##spMFClassTableColumns]
    SET [Property] = [mp].[Name]
       ,[Property_MFID] = [mp].[MFID]
       ,[MFdataType_ID] = [mdt].[MFTypeID]
       ,[MFDataType] = [mdt].[Name]
       ,[Required] = 0
    ,[LookupType] = CASE
                           WHEN [mp].[MFID] = 100 THEN
                               'Table_MFClass'
                           WHEN [mp].[MFID] = 38 THEN
                               'Table_MFWorkflow'
                           WHEN [mp].[MFID] = 39 THEN
                               'Table_MFWorkflowState'
							  END
		
	FROM [##spMFClassTableColumns]    AS [pc]
        INNER JOIN [dbo].[MFProperty] AS [mp]
            ON [pc].[columnName] = [mp].[ColumnName]
        INNER JOIN [dbo].[MFDataType] [mdt]
            ON [mp].[MFDataType_ID] = [mdt].[ID]
    WHERE [pc].[Property] IS NULL;

    UPDATE [##spMFClassTableColumns]
    SET [AdditionalProperty] = CASE
                                   WHEN [pc].[Property] IN ( 'GUID', 'Objid', 'MFVersion', 'ExternalID' ) THEN
                                       0
                                   WHEN [pc].[columnName] IN ( 'ID', 'Process_id', 'Lastmodified', 'FileCount'
                                                              ,'Deleted', 'Update_ID'
                                                             ) THEN
                                       0
                                   WHEN SUBSTRING([pc].[columnName], 1, 2) = 'MX' THEN
                                       0
                                   WHEN [pc].[Property_MFID] > 101
                                        AND [pc].[AdditionalProperty] IS NULL THEN
                                       1
                               END
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[AdditionalProperty] IS NULL;

  
    UPDATE [##spMFClassTableColumns]
    SET [ColumnType] = CASE
                           WHEN [IncludedInApp] IS NULL
                                AND [column_DataType] IS NULL THEN
                               'Not used'
                           WHEN [Property_MFID] > 100
                                AND [AdditionalProperty] = 0 THEN
                               'Metadata Card Property'
                           WHEN [AdditionalProperty] = 1 THEN
                               'Additional Property'
                           WHEN [Property_MFID] < 101 THEN
                               'MFSystem Property'
                           WHEN [columnName] IN ( 'GUID', 'Objid', 'MFVersion', 'ExternalID' ) THEN
                               'MFSystem Property'
                           WHEN [columnName] IN ( 'ID', 'Process_id', 'Lastmodified', 'FileCount', 'Deleted'
                                                 ,'Update_ID'
                                                ) THEN
                               'MFSQL System Property'
                           WHEN SUBSTRING([columnName], 1, 2) = 'MX' THEN
                               'Excluded from MF'
                           WHEN [Property] IS NULL
                                AND [IncludedInApp] = 1
                                AND [ColumnType] IS NULL THEN
                               'Lookup Lable Column'
                       END;

					         
WITH [cte]
AS (SELECT REPLACE([columnName], '_ID', '') AS [columnname]
          ,[columnType]
          ,[Property]
          ,[Property_MFID]
          ,[lookupType]
          ,[MFdatatype]
          ,[MFDataType_ID]
    FROM [##spMFClassTablecolumns]
    WHERE [MFDataType_ID] IN ( 9, 10 )
          AND [columnname] LIKE '%_ID')
UPDATE [c]
SET [columnType] = 'Lookup Lable Column'
   ,[lookupType] = [cte].[lookuptype]
   ,[property] = [cte].[property]
   ,[property_mfid] = [cte].[property_mfid]
   ,[MFDataType] = [cte].[MFDataType]
   ,[MFDatatype_ID] = [cte].[MFDatatype_ID]
--SELECT *
FROM [cte]
    INNER JOIN [##spMFClassTablecolumns] [c]
        ON [cte].[columnname] = [c].[columnname]
WHERE [c].[property_mfid] IS NULL;

  UPDATE [##spMFClassTableColumns]
    SET [MissingColumn] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[IncludedInApp] IS NOT NULL
          AND [pc].[column_DataType] IS NULL;

    UPDATE [##spMFClassTableColumns]
    SET [RedundantTable] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[IncludedInApp] IS NULL
          AND [pc].[column_DataType] IS NOT NULL;

    UPDATE [##spMFClassTableColumns]
    SET [MissingTable] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[IncludedInApp] IS NOT NULL
          AND [pc].[column_DataType] IS NULL
          AND [pc].[MissingColumn] IS NULL;

		      UPDATE [##spMFClassTableColumns]
    SET [ColumnDataTypeError] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[MFdataType_ID] in (1)
          AND [pc].[length] <> 200
          AND [pc].[IncludedInApp] = 1;

    UPDATE [##spMFClassTableColumns]
    SET [ColumnDataTypeError] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[MFdataType_ID] in (10,13)
          AND [pc].[length] <> 8000
          AND [pc].[IncludedInApp] IS NOT NULL;


--SELECT *
--FROM [##spMFClassTableColumns] AS [pc]
--WHERE [pc].[TableName] = @TableName
--      OR @TableName IS NULL
--ORDER BY [pc].[TableName]
--        ,[pc].[columnName];
END;
GO