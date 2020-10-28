/*rST**************************************************************************

===============
MFWorkflowState
===============

Columns
=======

ID int (primarykey, not null)
  SQL Primay key
Name varchar(100) (not null)
  M-Files workflow state name
Alias varchar(100)
  M-Files alias
MFID int (not null)
  MFID from M-Files
MFWorkflowID int
  Primary key of MFWorkflow 
ModifiedOn datetime (not null)
  Date last modified in SQL
CreatedOn datetime (not null)
  Date created in SQL
Deleted bit (not null)
  set to 1 if deleted in M-Files
IsNameUpdate bit
  set to 1 to allow update from SQL to M-Files of name

Additional Info
===============

The name and alias can be updated from SQL to M-Files.  New items cannot be created from SQL.

Indexes
=======

idx\_MFWorkflowState\_MFID
  - MFID
TUC\_MFWorkflowState\_MFID
  - MFID
  - MFWorkflowID

Foreign Keys
============

Table relates to MFWorkflow


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
2017-07-02  LC         Change datatype of alias to varchar(100)
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

/*-----------------------------------------------------------------------------------------------
SELECT * FROM MFWorkflowState
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
