/*rST**************************************************************************

=======
MFClass
=======

Columns
=======

+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| Key                                                                                                                            | Name                 | Data Type       | Max Length (Bytes)   | Nullability    | Identity   | Default       | Description              |
+================================================================================================================================+======================+=================+======================+================+============+===============+==========================+
|  Cluster Primary Key PK\_MFClass: ID                                                                                           | ID                   | int             | 4                    | NOT NULL       | 1 - 1      |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|  Indexes udx\_MFClass\_MFID                                                                                                    | MFID                 | int             | 4                    | NOT NULL       |            |               | *Per MF Class ID*        |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | Name                 | varchar(100)    | 100                  | NOT NULL       |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | Alias                | nvarchar(100)   | 200                  | NULL allowed   |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | IncludeInApp         | smallint        | 2                    | NULL allowed   |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | TableName            | varchar(100)    | 100                  | NULL allowed   |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|  Indexes FKIX\_MFClass\_MFObjectType\_ID \  Foreign Keys FK\_MFClass\_ObjectType\_ID: [dbo].[MFObjectType].MFObjectType\_ID    | MFObjectType\_ID     | int             | 4                    | NULL allowed   |            |               | *Per MF ObjectType ID*   |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|  Indexes FKIX\_MFClass\_MFWorkflow\_ID \  Foreign Keys FK\_MFClass\_MFWorkflow\_ID: [dbo].[MFWorkflow].MFWorkflow\_ID          | MFWorkflow\_ID       | int             | 4                    | NULL allowed   |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | FileExportFolder     | nvarchar(500)   | 1000                 | NULL allowed   |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | SynchPrecedence      | int             | 4                    | NULL allowed   |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | ModifiedOn           | datetime        | 8                    | NOT NULL       |            | (getdate())   |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | CreatedOn            | datetime        | 8                    | NOT NULL       |            | (getdate())   |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | Deleted              | bit             | 1                    | NOT NULL       |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
|                                                                                                                                | IsWorkflowEnforced   | bit             | 1                    | NULL allowed   |            |               |                          |
+--------------------------------------------------------------------------------------------------------------------------------+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+

Indexes
=======

+-----------------------------------------+-----------------------------------+--------------------+----------+
| Key                                     | Name                              | Key Columns        | Unique   |
+=========================================+===================================+====================+==========+
|  Cluster Primary Key PK\_MFClass: ID    | PK\_MFClass                       | ID                 | YES      |
+-----------------------------------------+-----------------------------------+--------------------+----------+
|                                         | FKIX\_MFClass\_MFObjectType\_ID   | MFObjectType\_ID   |          |
+-----------------------------------------+-----------------------------------+--------------------+----------+
|                                         | FKIX\_MFClass\_MFWorkflow\_ID     | MFWorkflow\_ID     |          |
+-----------------------------------------+-----------------------------------+--------------------+----------+
|                                         | udx\_MFClass\_MFID                | MFID               |          |
+-----------------------------------------+-----------------------------------+--------------------+----------+

Foreign Keys
============

+-------------------------------+-----------------------------------------------------------------------+
| Name                          | Columns                                                               |
+===============================+=======================================================================+
| FK\_MFClass\_MFWorkflow\_ID   | MFWorkflow\_ID->\ `[dbo].[MFWorkflow].[ID] <MFWorkflow.md>`__         |
+-------------------------------+-----------------------------------------------------------------------+
| FK\_MFClass\_ObjectType\_ID   | MFObjectType\_ID->\ `[dbo].[MFObjectType].[ID] <MFObjectType.md>`__   |
+-------------------------------+-----------------------------------------------------------------------+

Permissions
===========

+------------------+--------------+--------------------+-----------+
| Type             | Action       | Owning Principal   | Columns   |
+==================+==============+====================+===========+
| GrantWithGrant   | REFERENCES   | db\_MFSQLConnect   | ID        |
+------------------+--------------+--------------------+-----------+

Uses
====

- MFObjectType
- MFWorkflow

Used By
=======

- MFvwAuditSummary
- MFvwClassTableColumns
- MFvwMetadataStructure
- MFvwObjectTypeSummary
- spMFAddCommentForObjects
- spMFChangeClass
- spMFClassTableColumns
- spMFClassTableStats
- spMFCreateAllLookups
- spMFCreateAllMFTables
- spMFCreatePublicSharedLink
- spMFCreateTable
- spMFDeleteAdhocProperty
- spMFDeleteObjectList
- spMFDropAllClassTables
- spMFDropAndUpdateMetadata
- spMFExportFiles
- spMFGetDeletedObjects
- spMFGetHistory
- spMFGetObjectvers
- spMFInsertClass
- spMFInsertClassProperty
- spMFLogProcessSummaryForClassTable
- spMFObjectTypeUpdateClassIndex
- spMFResultMessageForUI
- spMFSetup\_Reporting
- spMFSynchronizeClasses
- spMFSynchronizeFilesToMFiles
- spmfSynchronizeLookupColumnChange
- spmfSynchronizeWorkFlowSateColumnChange
- spMFTableAudit
- spMFUpdateAllncludedInAppTables
- spMFUpdateClassAndProperties
- spMFUpdateExplorerFileToMFiles
- spMFUpdateHistoryShow
- spMFUpdateItemByItem
- spMFUpdateMFilesToMFSQL
- spMFUpdateSynchronizeError
- spMFUpdateTable
- spMFUpdateTableinBatches
- spMFUpdateTableInternal
- fnMFObjectHyperlink


Examples
========

.. code:: sql

    -- show all tables included in app
    Select * from MFClass where includeInApp = 1

    -- use metadata structure view to explore class relationships with other objects
    SELECT * FROM [dbo].[MFvwMetadataStructure] AS [mfms] WHERE class = 'Customer'

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
2017-07-06  LC         Add column for filepath
2017-08-22  LC         Add column for syncprecedence
==========  =========  ========================================================

**rST*************************************************************************/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFClass]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFClass', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO


GO
IF NOT EXISTS (	  SELECT	[name]
				  FROM		[sys].[tables]
				  WHERE		[name] = 'MFClass'
							AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN
		CREATE TABLE [MFClass]
			(
				[ID]			  INT			IDENTITY(1, 1) NOT NULL
			  , [MFID]			  INT			NOT NULL
			  , [Name]			  VARCHAR(100)	NOT NULL
			  , [Alias]			  NVARCHAR(100) NULL
			  , [IncludeInApp]	  SMALLINT		NULL
			  , [TableName]		  VARCHAR(100)	NULL
			  , [MFObjectType_ID] INT			NULL
			  , [MFWorkflow_ID]	  INT			NULL
			  , [FileExportFolder]		  NVARCHAR(500) NULL
			  , SynchPrecedence int NULL 
			  , [ModifiedOn]	  DATETIME
					DEFAULT ( GETDATE()) NOT NULL
			  , [CreatedOn]		  DATETIME
					DEFAULT ( GETDATE()) NOT NULL
			  , [Deleted]		  BIT			NOT NULL
			  , CONSTRAINT [PK_MFClass]
					PRIMARY KEY CLUSTERED ( [ID] ASC )
			);

		PRINT SPACE(10) + '... Table: created';
	END;
ELSE PRINT SPACE(10) + '... Table: exists';

--FOREIGN KEYS #############################################################################################################################

IF NOT EXISTS (	  SELECT	*
				  FROM		[sys].[foreign_keys]
				  WHERE		[parent_object_id] = OBJECT_ID('MFClass')
							AND [name] = N'FK_MFClass_MFWorkflow_ID'
			  )
	BEGIN
		PRINT SPACE(10) + '... Constraint: FK_MFClass_MFWorkflow_ID';
		ALTER TABLE [dbo].[MFClass] WITH CHECK
		ADD CONSTRAINT [FK_MFClass_MFWorkflow_ID]
			FOREIGN KEY ( [MFWorkflow_ID] )
			REFERENCES [dbo].[MFWorkflow] ( [id] ) ON DELETE NO ACTION;

	END;

IF NOT EXISTS (	  SELECT	*
				  FROM		[sys].[foreign_keys]
				  WHERE		[parent_object_id] = OBJECT_ID('MFClass')
							AND [name] = N'FK_MFClass_ObjectType_ID'
			  )
	BEGIN
		PRINT SPACE(10) + '... Constraint: FK_MFClass_ObjectType_ID';
		ALTER TABLE [dbo].[MFClass] WITH CHECK
		ADD CONSTRAINT [FK_MFClass_ObjectType_ID]
			FOREIGN KEY ( [MFObjectType_ID] )
			REFERENCES [dbo].[MFObjectType] ( [id] ) ON DELETE NO ACTION;

	END;

--INDEXES #############################################################################################################################

IF NOT EXISTS (	  SELECT	*
				  FROM		[sys].[indexes]
				  WHERE		[object_id] = OBJECT_ID('MFClass')
							AND [name] = N'udx_MFClass_MFID'
			  )
	BEGIN
		PRINT SPACE(10) + '... Index: udx_MFClass_MFID';
		CREATE NONCLUSTERED INDEX [udx_MFClass_MFID] ON [dbo].[MFClass] ( [MFID] );
	END;

--EXTENDED PROPERTIES #############################################################################################################################

	IF NOT EXISTS (	  SELECT	[ep].[value]
					  FROM		[sys].[extended_properties] AS [ep]
					  WHERE		[ep].[value] = 'Per MF Workflow'
				  )
		EXECUTE [sys].[sp_addextendedproperty]
			@name = N'MS_Description'
		  , @value = N'Per MF Workflow'
		  , @level0type = N'SCHEMA'
		  , @level0name = N'dbo'
		  , @level1type = N'TABLE'
		  , @level1name = N'MFClass'
		  , @level2type = N'COLUMN'
		  , @level2name = N'MFWorkflow_ID';


	GO
	IF NOT EXISTS (	  SELECT	[ep].[value]
					  FROM		[sys].[extended_properties] AS [ep]
					  WHERE		[ep].[value] = N'Per MF ObjectType ID'
				  )
		EXECUTE [sys].[sp_addextendedproperty]
			@name = N'MS_Description'
		  , @value = N'Per MF ObjectType ID'
		  , @level0type = N'SCHEMA'
		  , @level0name = N'dbo'
		  , @level1type = N'TABLE'
		  , @level1name = N'MFClass'
		  , @level2type = N'COLUMN'
		  , @level2name = N'MFObjectType_ID';


	GO
	IF NOT EXISTS (	  SELECT	[ep].[value]
					  FROM		[sys].[extended_properties] AS [ep]
					  WHERE		[ep].[value] = N'Per MF Class ID'
				  )
		EXECUTE [sys].[sp_addextendedproperty]
			@name = N'MS_Description'
		  , @value = N'Per MF Class ID'
		  , @level0type = N'SCHEMA'
		  , @level0name = N'dbo'
		  , @level1type = N'TABLE'
		  , @level1name = N'MFClass'
		  , @level2type = N'COLUMN'
		  , @level2name = N'MFID';

	GO

--TABLE MIGRATIONS #############################################################################################################################
/*	
	Effective Version: 3.1.2.38
	FilePath is used by spmfExportFiles to set the default export path for files for each class table
	SynchPrecedence is used to determine if M-Files or SQL should get precedence when a synchronization error is detected. 
*/
IF NOT EXISTS (	  SELECT	1
				  FROM		[INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE		[c].[TABLE_NAME] = 'MFClass'
							AND [c].[COLUMN_NAME] = 'FileExportFolder'
			  )
	BEGIN
		ALTER TABLE dbo.[MFClass] ADD [FileExportFolder] NVARCHAR(500)

		PRINT SPACE(10) + '... Column [FileExportFolder]: added';

	END

IF NOT EXISTS (	  SELECT	1
				  FROM		[INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE		[c].[TABLE_NAME] = 'MFClass'
							AND [c].[COLUMN_NAME] = 'SynchPrecedence'
			  )
	BEGIN
		ALTER TABLE dbo.[MFClass] ADD SynchPrecedence int

		PRINT SPACE(10) + '... Column [SynchPrecedence]: added';

	END

	--Added fot tasj #1052
	IF NOT EXISTS(SELECT 1 
				  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE [c].TABLE_NAME='MFClass'
				  AND [c].COLUMN_NAME='IsWorkflowEnforced' --added for task 1052
	
				  )
		BEGIN
			ALTER TABLE dbo.[MFClass] add IsWorkflowEnforced bit; --added for task 1052
			PRINT SPACE(10) + '... Column [IsWorkflowEnforced]: added'; 
		END

GO


