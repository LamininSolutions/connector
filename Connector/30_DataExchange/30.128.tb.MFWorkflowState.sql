/*rST**************************************************************************

===============
MFWorkflowState
===============

Columns
=======

+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
| Key                                                                                                                     | Name           | Data Type      | Max Length (Bytes)   | Nullability    | Identity   | Default       |
+=========================================================================================================================+================+================+======================+================+============+===============+
|  Cluster Primary Key PK\_MFWorkflowState: ID                                                                            | ID             | int            | 4                    | NOT NULL       | 1 - 1      |               |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|                                                                                                                         | Name           | varchar(100)   | 100                  | NOT NULL       |            |               |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|                                                                                                                         | Alias          | varchar(100)   | 100                  | NULL allowed   |            |               |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|  Indexes idx\_MFWorkflowState\_MFID TUC\_MFWorkflowState\_MFID \ (2)                                                    | MFID           | int            | 4                    | NOT NULL       |            |               |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|  Indexes TUC\_MFWorkflowState\_MFID \  Foreign Keys FK\_MFWorkflowState\_MFWorkflow: [dbo].[MFWorkflow].MFWorkflowID    | MFWorkflowID   | int            | 4                    | NULL allowed   |            |               |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|                                                                                                                         | ModifiedOn     | datetime       | 8                    | NOT NULL       |            | (getdate())   |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|                                                                                                                         | CreatedOn      | datetime       | 8                    | NOT NULL       |            | (getdate())   |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|                                                                                                                         | Deleted        | bit            | 1                    | NOT NULL       |            |               |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+
|                                                                                                                         | IsNameUpdate   | bit            | 1                    | NULL allowed   |            |               |
+-------------------------------------------------------------------------------------------------------------------------+----------------+----------------+----------------------+----------------+------------+---------------+

Indexes
=======

+-------------------------------------------------+------------------------------+----------------------+----------+
| Key                                             | Name                         | Key Columns          | Unique   |
+=================================================+==============================+======================+==========+
|  Cluster Primary Key PK\_MFWorkflowState: ID    | PK\_MFWorkflowState          | ID                   | YES      |
+-------------------------------------------------+------------------------------+----------------------+----------+
|                                                 | TUC\_MFWorkflowState\_MFID   | MFWorkflowID, MFID   | YES      |
+-------------------------------------------------+------------------------------+----------------------+----------+
|                                                 | idx\_MFWorkflowState\_MFID   | MFID                 |          |
+-------------------------------------------------+------------------------------+----------------------+----------+

Foreign Keys
============

+-----------------------------------+---------------------------------------------------------------+
| Name                              | Columns                                                       |
+===================================+===============================================================+
| FK\_MFWorkflowState\_MFWorkflow   | MFWorkflowID->\ `[dbo].[MFWorkflow].[ID] <MFWorkflow.md>`__   |
+-----------------------------------+---------------------------------------------------------------+

Uses
====

- MFWorkflow

Used By
=======

- spMFAliasesUpsert
- spMFDropAndUpdateMetadata
- spMFInsertUserMessage
- spMFInsertWorkflowState
- spmfSynchronizeWorkFlowSateColumnChange
- spMFSynchronizeWorkflowsStates


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON; 
GO

GO
-- ** Required
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFWorkflowState]';
-- ** Required
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFWorkflowState', -- nvarchar(100)
    @Object_Release = '4.2.9.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Workflow State MFiles Metadata	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-7-2		lc			change datatype of alias to varchar(100)
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFWorkflowState
  
-----------------------------------------------------------------------------------------------*/


--** Use IF EXISTS syntax if table ALWAYS needs to be dropped before being recreated.
--** WARNING: this could cause loss of data

--** Optional
/*
   IF EXISTS (SELECT name FROM sys.tables WHERE name='MFWorkflowState' AND SCHEMA_NAME(schema_id)='dbo')
   BEGIN
		DROP TABLE	dbo.MFWorkflowState
		PRINT SPACE(10) + '... Table: dropped'
   END
   
*/  
--** Optional

--** Required
--** Use IF NOT EXISTS syntax if the table should ONLY be created the 1st time
--** This protects against accidential loss of data
IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFWorkflowState'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
   

        CREATE TABLE [dbo].[MFWorkflowState]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NOT NULL ,
              [Alias] VARCHAR(100) NULL ,
              [MFID] INT NOT NULL ,
              [MFWorkflowID] INT NULL ,
              [ModifiedOn] DATETIME DEFAULT ( GETDATE() )
                                    NOT NULL ,
              [CreatedOn] DATETIME DEFAULT ( GETDATE() )
                                   NOT NULL ,
              [Deleted] BIT NOT NULL ,
              CONSTRAINT [PK_MFWorkflowState] PRIMARY KEY CLUSTERED
                ( [ID] ASC ) ,
              CONSTRAINT [FK_MFWorkflowState_MFWorkflow] FOREIGN KEY ( [MFWorkflowID] ) REFERENCES [dbo].[MFWorkflow] ( [ID] ) ,
              CONSTRAINT [TUC_MFWorkflowState_MFID] UNIQUE NONCLUSTERED
                ( [MFWorkflowID] ASC, [MFID] ASC )
            );


        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFWorkflowState')
                        AND name = N'idx_MFWorkflowState_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFWorkflowState_MFID';
        CREATE NONCLUSTERED INDEX idx_MFWorkflowState_MFID ON dbo.MFWorkflowState (MFID);
    END;


GO
--TABLE MIGRATIONS ############################################################################################################################
GO
/*	
	Effective Version: 3.1.2.38
*/
IF EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFWorkflowState'
		AND [COLUMN_NAME] = 'Alias'
		AND [CHARACTER_MAXIMUM_LENGTH] <> 100
		)
BEGIN
	ALTER TABLE [dbo].[MFWorkflowState] ALTER COLUMN [Alias] VARCHAR(100)
	PRINT SPACE(10) + '... Column [Alias]: updated column length to VARCHAR(100)';
END

GO
----Added for Bug 1088---
IF Not Exists (Select top 1 * from INFORMATION_SCHEMA.COLUMNS C where C.COLUMN_NAME='IsNameUpdate' and C.TABLE_NAME='MFWorkflowState')
			Begin

			 Alter table MFWorkflowState Add IsNameUpdate Bit
             PRINT SPACE(10) + '... Added column IsNameUpdate  : ' ;
			End
GO