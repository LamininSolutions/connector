
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwClassTableColumns]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'MFvwClassTableColumns' -- nvarchar(100)
                                    ,@Object_Release = '4.10.30.74'           -- varchar(50)
                                    ,@UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[VIEWS]
    WHERE [TABLE_NAME] = 'MFvwClassTableColumns'
          AND [TABLE_SCHEMA] = 'dbo'
)
BEGIN
    SET NOEXEC ON;
END;
GO

CREATE VIEW [dbo].[MFvwClassTableColumns]
AS
SELECT [Column1] = 'UNDER CONSTRUCTION';
GO

SET NOEXEC OFF;
GO

ALTER VIEW [dbo].[MFvwClassTableColumns]
AS

/*rST**************************************************************************

=====================
MFvwClassTableColumns
=====================

Purpose
=======

To view the definition of the class tables columns

The procedure spmfClassTableColumns provide a more indepth look at the class tables and column errors

Examples
========

.. code:: sql

   Select * from MFvwClassTablecolumns

----

.. code:: sql

    EXEC [dbo].[spMFClassTableColumns] 
    --review result
    SELECT * FROM ##spMFClassTableColumns



Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-09-27  LC         updates following changes to additional property identification
2021-10-26  LC         Set max columns to 10000
2018-11-01  LC         Create view
==========  =========  ========================================================

**rST*************************************************************************/

SELECT TOP 10000
       [mc].[TableName]
      ,CASE
           WHEN [mp2].[MFID] < 1000
                AND [mcp].[MFProperty_ID] IS NULL THEN
               'Alert'           
 WHEN [mp2].[MFID] = 100 THEN 'No'
 WHEN mcp.MFProperty_ID IS NULL THEN 'SQL only'
           WHEN  mcp.IsAdditional = 0 THEN 'No'
           WHEN  mcp.IsAdditional = 1 THEN 'Yes'
           ELSE
            null  
       END          AS [AdditionalProperty]
      ,[mp2].[Name] AS [Property]
      ,[sc].[name]  AS [TableColumn]
      ,CASE
           WHEN [mcp].[MFProperty_ID] IS NULL THEN
               'N'
           ELSE
               'Y'
       END          AS [OnmetadataCard]
      ,CASE
           WHEN [mp2].[MFID] > 100
                AND [mcp].[MFProperty_ID] IS NOT NULL THEN
               'Metadata Card Property'
           WHEN [mp2].[MFID] > 100
                AND [mcp].[MFProperty_ID] IS NULL THEN
               'Add hoc Property'
           WHEN [mp2].[MFID] < 101 THEN
               'MFSystem Property'
           WHEN [mp2].[Name] IS NULL
                AND [sc].[name] IN ( 'Process_id', 'Objid', 'ExternalID', 'MFVersion', 'FileCount' ) THEN
               'MFSQL System Property'
           WHEN [mp2].[Name] IS NULL
                AND [sc].[name] NOT IN ( 'Process_id', 'Objid', 'ExternalID', 'MFVersion', 'FileCount' ) THEN
               'Lookup Lable Column'
       END          AS [ColumnType]
      ,[Column_Datatype]   = [t].[name]
      ,[Length]     = [sc].[max_length]
	  ,[dt].[MFTypeID]
      ,[MFdatatype] = [dt].[Name]
      ,CASE
           WHEN [dt].[MFTypeID] = 10
                AND [t].[max_length] <> 8000 THEN
               'Datatype Error'
			WHEN [dt].[MFTypeID] = 9
                AND [t].[max_length] <> 4 THEN
               'Datatype Error'  
           ELSE
               NULL
       END          AS [DataType_Error]

--SELECT t.*
FROM [dbo].[MFClass]                  AS [mc]
    INNER JOIN [sys].[columns]        [sc]
        ON [sc].[object_id] = OBJECT_ID([mc].[TableName])
    INNER JOIN [sys].[types]          [t]
        ON [t].[user_type_id] = [sc].[user_type_id]
    LEFT JOIN [dbo].[MFProperty]      AS [mp2]
        ON [sc].[name] = [mp2].[ColumnName]
    LEFT JOIN [dbo].[MFDataType]      [dt]
        ON [mp2].[MFDataType_ID] = [dt].[ID]
    LEFT JOIN [dbo].[MFClassProperty] AS [mcp]
        ON [mcp].[MFClass_ID] = [mc].[ID]
           AND [mp2].[ID] = [mcp].[MFProperty_ID]
--LEFT JOIN [dbo].[MFClassProperty] AS [mcp2]
--ON mc.id = mcp.[MFClass_ID]
WHERE [mc].[IncludeInApp] IS NOT NULL
ORDER BY [mc].[TableName];
GO