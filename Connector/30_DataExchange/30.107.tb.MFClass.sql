go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFClass]';

GO

/*rST**************************************************************************

===========
dbo.MFClass
===========

Columns
-------

+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| Name                 | Data Type       | Max Length (Bytes)   | Nullability    | Identity   | Default       | Description              |
+======================+=================+======================+================+============+===============+==========================+
| ID                   | int             | 4                    | NOT NULL       | 1 - 1      |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| MFID                 | int             | 4                    | NOT NULL       |            |               | *Per MF Class ID*        |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| Name                 | varchar(100)    | 100                  | NOT NULL       |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| Alias                | nvarchar(100)   | 200                  | NULL allowed   |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| IncludeInApp         | smallint        | 2                    | NULL allowed   |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| TableName            | varchar(100)    | 100                  | NULL allowed   |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| MFObjectType\_ID     | int             | 4                    | NULL allowed   |            |               | *Per MF ObjectType ID*   |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| MFWorkflow\_ID       | int             | 4                    | NULL allowed   |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| FileExportFolder     | nvarchar(500)   | 1000                 | NULL allowed   |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| SynchPrecedence      | int             | 4                    | NULL allowed   |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| ModifiedOn           | datetime        | 8                    | NOT NULL       |            | (getdate())   |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| CreatedOn            | datetime        | 8                    | NOT NULL       |            | (getdate())   |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| Deleted              | bit             | 1                    | NOT NULL       |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+
| IsWorkflowEnforced   | bit             | 1                    | NULL allowed   |            |               |                          |
+----------------------+-----------------+----------------------+----------------+------------+---------------+--------------------------+

--------------

Indexes
-------

+-----------------------------------------+-----------------------------------+--------------------+----------+
| Key                                     | Name                              | Key Columns        | Unique   |
+=========================================+===================================+====================+==========+
| |Cluster Primary Key PK\_MFClass: ID|   | PK\_MFClass                       | ID                 | YES      |
+-----------------------------------------+-----------------------------------+--------------------+----------+
|                                         | FKIX\_MFClass\_MFObjectType\_ID   | MFObjectType\_ID   |          |
+-----------------------------------------+-----------------------------------+--------------------+----------+
|                                         | FKIX\_MFClass\_MFWorkflow\_ID     | MFWorkflow\_ID     |          |
+-----------------------------------------+-----------------------------------+--------------------+----------+
|                                         | udx\_MFClass\_MFID                | MFID               |          |
+-----------------------------------------+-----------------------------------+--------------------+----------+

--------------

Foreign Keys
------------

+-------------------------------+-----------------------------------------------------------------------+
| Name                          | Columns                                                               |
+===============================+=======================================================================+
| FK\_MFClass\_MFWorkflow\_ID   | MFWorkflow\_ID->\  [dbo].[MFWorkflow].[ID]                            |
+-------------------------------+-----------------------------------------------------------------------+
| FK\_MFClass\_ObjectType\_ID   | MFObjectType\_ID->\  [dbo].[MFObjectType].[ID]                        |
+-------------------------------+-----------------------------------------------------------------------+

--------------

Permissions
-----------

+------------------+--------------+--------------------+-----------+
| Type             | Action       | Owning Principal   | Columns   |
+==================+==============+====================+===========+
| GrantWithGrant   | REFERENCES   | db\_MFSQLConnect   | ID        |
+------------------+--------------+--------------------+-----------+


--------------

Uses
----

-  `[dbo].[MFObjectType] <MFObjectType.rst>`__
-  `[dbo].[MFWorkflow] <MFWorkflow.rst>`__

--------------

Used By
-------

-  `[dbo].[MFvwAuditSummary] <../Views/MFvwAuditSummary.rst>`__
-  `[dbo].[MFvwClassTableColumns] <../Views/MFvwClassTableColumns.rst>`__
-  `[dbo].[MFvwMetadataStructure] <../Views/MFvwMetadataStructure.rst>`__
-  `[dbo].[MFvwObjectTypeSummary] <../Views/MFvwObjectTypeSummary.rst>`__
-  `[dbo].[spMFAddCommentForObjects] <../Programmability/Stored_Procedures/spMFAddCommentForObjects.rst>`__
-  `[dbo].[spMFChangeClass] <../Programmability/Stored_Procedures/spMFChangeClass.rst>`__
-  `[dbo].[spMFClassTableColumns] <../Programmability/Stored_Procedures/spMFClassTableColumns.rst>`__
-  `[dbo].[spMFClassTableStats] <../Programmability/Stored_Procedures/spMFClassTableStats.rst>`__
-  `[dbo].[spMFCreateAllLookups] <../Programmability/Stored_Procedures/spMFCreateAllLookups.rst>`__
-  `[dbo].[spMFCreateAllMFTables] <../Programmability/Stored_Procedures/spMFCreateAllMFTables.rst>`__
-  `[dbo].[spMFCreatePublicSharedLink] <../Programmability/Stored_Procedures/spMFCreatePublicSharedLink.rst>`__
-  `[dbo].[spMFCreateTable] <../Programmability/Stored_Procedures/spMFCreateTable.rst>`__
-  `[dbo].[spMFDeleteAdhocProperty] <../Programmability/Stored_Procedures/spMFDeleteAdhocProperty.rst>`__
-  `[dbo].[spMFDeleteObjectList] <../Programmability/Stored_Procedures/spMFDeleteObjectList.rst>`__
-  `[dbo].[spMFDropAllClassTables] <../Programmability/Stored_Procedures/spMFDropAllClassTables.rst>`__
-  `[dbo].[spMFDropAndUpdateMetadata] <../Programmability/Stored_Procedures/spMFDropAndUpdateMetadata.rst>`__
-  `[dbo].[spMFExportFiles] <../Programmability/Stored_Procedures/spMFExportFiles.rst>`__
-  `[dbo].[spMFGetDeletedObjects] <../Programmability/Stored_Procedures/spMFGetDeletedObjects.rst>`__
-  `[dbo].[spMFGetHistory] <../Programmability/Stored_Procedures/spMFGetHistory.rst>`__
-  `[dbo].[spMFGetObjectvers] <../Programmability/Stored_Procedures/spMFGetObjectvers.rst>`__
-  `[dbo].[spMFInsertClass] <../Programmability/Stored_Procedures/spMFInsertClass.rst>`__
-  `[dbo].[spMFInsertClassProperty] <../Programmability/Stored_Procedures/spMFInsertClassProperty.rst>`__
-  `[dbo].[spMFLogProcessSummaryForClassTable] <../Programmability/Stored_Procedures/spMFLogProcessSummaryForClassTable.rst>`__
-  `[dbo].[spMFObjectTypeUpdateClassIndex] <../Programmability/Stored_Procedures/spMFObjectTypeUpdateClassIndex.rst>`__
-  `[dbo].[spMFResultMessageForUI] <../Programmability/Stored_Procedures/spMFResultMessageForUI.rst>`__
-  `[dbo].[spMFSetup\_Reporting] <../Programmability/Stored_Procedures/spMFSetup_Reporting.rst>`__
-  `[dbo].[spMFSynchronizeClasses] <../Programmability/Stored_Procedures/spMFSynchronizeClasses.rst>`__
-  `[dbo].[spMFSynchronizeFilesToMFiles] <../Programmability/Stored_Procedures/spMFSynchronizeFilesToMFiles.rst>`__
-  `[dbo].[spmfSynchronizeLookupColumnChange] <../Programmability/Stored_Procedures/spmfSynchronizeLookupColumnChange.rst>`__
-  `[dbo].[spmfSynchronizeWorkFlowSateColumnChange] <../Programmability/Stored_Procedures/spmfSynchronizeWorkFlowSateColumnChange.rst>`__
-  `[dbo].[spMFTableAudit] <../Programmability/Stored_Procedures/spMFTableAudit.rst>`__
-  `[dbo].[spMFUpdateAllncludedInAppTables] <../Programmability/Stored_Procedures/spMFUpdateAllncludedInAppTables.rst>`__
-  `[dbo].[spMFUpdateClassAndProperties] <../Programmability/Stored_Procedures/spMFUpdateClassAndProperties.rst>`__
-  `[dbo].[spMFUpdateExplorerFileToMFiles] <../Programmability/Stored_Procedures/spMFUpdateExplorerFileToMFiles.rst>`__
-  `[dbo].[spMFUpdateHistoryShow] <../Programmability/Stored_Procedures/spMFUpdateHistoryShow.rst>`__
-  `[dbo].[spMFUpdateItemByItem] <../Programmability/Stored_Procedures/spMFUpdateItemByItem.rst>`__
-  `[dbo].[spMFUpdateMFilesToMFSQL] <../Programmability/Stored_Procedures/spMFUpdateMFilesToMFSQL.rst>`__
-  `[dbo].[spMFUpdateSynchronizeError] <../Programmability/Stored_Procedures/spMFUpdateSynchronizeError.rst>`__
-  `[dbo].[spMFUpdateTable] <../Programmability/Stored_Procedures/spMFUpdateTable.rst>`__
-  `[dbo].[spMFUpdateTableinBatches] <../Programmability/Stored_Procedures/spMFUpdateTableinBatches.rst>`__
-  `[dbo].[spMFUpdateTableInternal] <../Programmability/Stored_Procedures/spMFUpdateTableInternal.rst>`__
-  `[dbo].[fnMFObjectHyperlink] <../Programmability/Functions/Scalar-valued_Functions/fnMFObjectHyperlink.rst>`__

--------------

- Cluster Primary Key PK\_MFClass: ID
- Indexes udx\_MFClass\_MFID
- Indexes FKIX\_MFClass\_MFObjectType\_ID
- Foreign Keys FK\_MFClass\_ObjectType\_ID: [dbo].[MFObjectType].MFObjectType\_ID
- Indexes FKIX\_MFClass\_MFWorkflow\_ID
- Foreign Keys FK\_MFClass\_MFWorkflow\_ID: [dbo].[MFWorkflow].MFWorkflow\_ID


**rST*************************************************************************/

/*rST**************************************************************************

Examples
========

----

.. code:: sql

    Select * from MFClass


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2017-7-6    LC         Add column for filepath
2017-8-22   LC         Add column for syncprecedence
==========  =========  ========================================================


**rST*************************************************************************/



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


