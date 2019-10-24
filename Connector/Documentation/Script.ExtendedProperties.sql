
/*
extended properties
Database level

level 0, level 1, level 2

Database
Assembly
	Schema
		Function
			Column
			Constraint
			Parameter
		Procedure
				MF_Description
				Usage
				Type
			Parameter
				Return
				Options
				Example
				Type
		Table
			Column
				MF_Description
				Options
			Constraint
				Relations
			Index
				Relations
			Trigger
				Type
				TriggeredBy
				Action
		View
			Column
				MF_Description
			Index

*/
--Created on: 2019-08-13 

--database level
EXECUTE sys.sp_addextendedproperty @name = 'Version', @Value = '4.4.11.52'
EXECUTE sys.sp_addextendedproperty @name = 'MS_Description', @Value = 'MFSQL Connector'
EXECUTE sys.sp_addextendedproperty @name = 'M-Files Vault', @Value = 'MS_Demo'

--Assembly
SELECT * FROM sys.[assemblies] AS [a]
EXEC sp_dropextendedproperty @Name = 'Installation', @level0type = 'Assembly'

EXECUTE sys.sp_addextendedproperty @name = 'MS_Description', @Value = 'M-files COM APIs.'
, @level0type = 'Assembly', @level0name = 'Interop.MFilesAPI'
EXECUTE sys.sp_addextendedproperty @name = 'Installation', @Value = 'Kept in Sync with installed M-Files Desktop client using spMFUpdateAssemblies'
, @level0type = 'Assembly', @level0name = 'Interop.MFilesAPI'
EXECUTE sys.sp_addextendedproperty @name = 'MS_Description', @Value = 'Encryption of password'
, @level0type = 'Assembly', @level0name = 'Laminin.Security'
EXECUTE sys.sp_addextendedproperty @name = 'MS_Description', @Value = 'SQL Methods to apply M-Files COM APIs'
, @level0type = 'Assembly', @level0name = 'LSConnectMFilesAPIWrapper'
EXECUTE sys.sp_addextendedproperty @name = 'MS_Description', @Value = 'XML handler'
, @level0type = 'Assembly', @level0name = 'CLRSerializer'
EXECUTE sys.sp_addextendedproperty @name = 'Version', @Value = '4.4.11'
, @level0type = 'Assembly', @level0name = 'LSConnectMFilesAPIWrapper'


--table
/*
SELECT name FROM sys.tables t where SUBSTRING(t.NAME,1,2) = 'MF'

Table list
MFAuditHistory
MFAuthenticationType
MFClass
MFClassProperty
MFContextMenu
MFDataType
MFDeploymentDetail
MFEventLog_OpenXML
MFExportFileHistory
MFFileImport
MFilesEvents
MFLog
MFLoginAccount
MFObjectChangeHistory
MFObjectType
MFObjectTypeToClassObject
MFProcess
MFProcessBatch
MFProcessBatchDetail
MFProperty
MFProtocolType
MFPublicLink
MFSearchLog
MFSettings
MFUnmanagedObject
MFUpdateHistory
MFUserAccount
MFUserMessages
MFValueList
MFValueListItems
MFVaultSettings
MFWorkflow
MFWorkflowState
MFSQLObjectsControl

*/


DECLARE @Table NVARCHAR(100)
DECLARE @Schema NVARCHAR(100)
DECLARE @Name1 NVARCHAR(100)
DECLARE @Name2 NVARCHAR(100)
DECLARE @Name3 NVARCHAR(100)
DECLARE @Column NVARCHAR(100)

SET @Schema = 'dbo'
SET @Name1 = 'MS_Description'
SET @name2 = 'Purpose'
SET @name3 = 'Usage'

SET @Table = 'MFClass'

--delete table extended properties if already exist

DECLARE @prop_name  NVARCHAR(256)

DECLARE db_cursor CURSOR FOR  
    SELECT 
        ext.name
    FROM 
        sys.extended_properties ext,
        sys.tables tb
    WHERE 
        ext.major_id = tb.object_id  AND tb.name = @Table

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @prop_name

WHILE @@FETCH_STATUS = 0   
BEGIN
    EXEC sp_dropextendedproperty 
        @name=@prop_name,
        @level0type=N'SCHEMA',
        @level0name=N'dbo', 
        @level1type=N'TABLE',
        @level1name=@table

    FETCH NEXT FROM db_cursor INTO @prop_name
END   

CLOSE db_cursor   
DEALLOCATE db_cursor 


SELECT * FROM sys.[extended_procedures] AS [ep]

--table level

EXECUTE sys.sp_addextendedproperty @Name1,'Table of M-Files Classes'
,'schema',@Schema, 'Table', @Table

EXECUTE sys.sp_addextendedproperty @Name2
,'Each M-Files class can have a MFSQL Class Table holding all the latest versions of the objects of the class as a record with all the properties of the class as columns. The MFClass table controls and configure operations at class level'
,'schema',@Schema, 'Table', @Table

EXECUTE sys.sp_addextendedproperty @Name3
,'Select * from MFClass where IncludedInApp = 1'
,'schema',@Schema, 'Table', @Table

--Columns
SET @name2 = 'Options'
SET @name3 = 'Usage'
/*
SET @column = ''
EXECUTE sys.sp_addextendedproperty @Name1,
  ''
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

EXECUTE sys.sp_addextendedproperty @Name2,
  ''
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

EXECUTE sys.sp_addextendedproperty @Name3,
  ''
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

*/

--ID
SET @column = 'ID'
EXECUTE sys.sp_addextendedproperty @Name1,
  'Primary Key, Row ID'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

EXECUTE sys.sp_addextendedproperty @Name2,
  'SQL row identifyer'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

EXECUTE sys.sp_addextendedproperty @Name3,
  ''
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--MFID
SET @column = 'MFID'
EXECUTE sys.sp_addextendedproperty @Name1,
  'MF Class ID'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

EXECUTE sys.sp_addextendedproperty @Name3,
  ''
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--Name
SET @column = 'Name'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--Alias
SET @column = 'Alias'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--IncludeInApp
SET @column = 'IncludeInApp'
EXECUTE sys.sp_addextendedproperty @Name1,
  'Show which class tables are included in MFSQL and allows for procedures to run accross multiple class tables.  When table is created it is automatically set to 1. When set to 2 it will trigger any update or insert on the class table to automatically update into M-Files. Any other number can be used to sub group sets of class tables. For instance, set all the class tables related to project documents to 3 and then run an spMFUpdateAllIncludedinAppTables 3 to update only the class tables related to project documents.
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

EXECUTE sys.sp_addextendedproperty @Name2,
  'Default = null
  1 = included as a standard class table in MFSQL
  2 = transaction based updates
  3+ = open for custom use
  '
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--TableName
SET @column = 'TableName'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--MFObjectType_ID
SET @column = 'MFObjectType_ID'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--MFWorkflow_ID
SET @column = 'MFWorkflow_ID'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--FileExportFolder
SET @column = 'FileExportFolder'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--SynchPrecedence
SET @column = 'SynchPrecedence'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--ModifiedOn
SET @column = 'ModifiedOn'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--CreatedOn
SET @column = 'CreatedOn'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--Deleted
SET @column = 'Deleted'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;

--IsWorkflowEnforced
SET @column = 'IsWorkflowEnforced'
EXECUTE sys.sp_addextendedproperty @Name1,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;
EXECUTE sys.sp_addextendedproperty @Name2,
  '
'
,'schema',@Schema, 'Table', @Table
, 'column', @Column;


  --update

  EXECUTE sys.sp_updateextendedproperty 'MS_Description',
  'Show which class tables are included in MFSQL and allows for procedures to run accross multiple class tables.  When table is created it is automatically set to 1. When set to 2 it will trigger any update or insert on the class table to automatically update into M-Files. Any other number can be used to sub group sets of class tables. For instance, set all the class tables related to project documents to 3 and then run an spMFUpdateAllIncludedinAppTables 3 to update only the class tables related to project documents.
  ', 'schema', 'dbo', 'Table',
  'MFClass', 'column', 'IncludeInApp';
/* we can list this column */
SELECT *
  FROM::fn_listextendedproperty('MS_Description', 'schema', 'dbo', 'table', 'MFClass', 'column', 'IncludeInApp');
/* or all the properties for the table column of dbo.Customer*/
SELECT *
  FROM::fn_listextendedproperty(DEFAULT, 'schema', 'dbo', 'table', 'MFClass', 'column', DEFAULT);
/* And now we drop the MS_Description property of   dbo.Customer.InsertionDate column */


--delete
EXECUTE sys.sp_dropextendedproperty 'MS_Description', 'schema', 'dbo',
  'table', 'Customer', 'column', 'InsertionDate';

 
  EXECUTE sys.sp_dropextendedproperty 

  --delete item
  EXECUTE sys.sp_dropextendedproperty 'MS_Description',
  'schema', 'dbo', 'Table',
  'MFClass', 'column', 'IncludeInApp';