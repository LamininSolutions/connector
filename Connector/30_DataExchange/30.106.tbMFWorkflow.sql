/*rST**************************************************************************

==========
MFWorkflow
==========

Columns
=======

ID int (primarykey, not null)
  SQL primary key
Name varchar(100) (not null)
  Name of Workflow from M-Files
Alias nvarchar(100)
  Alias in M-Files
MFID int (not null)
  MFID of workflow 
ModifiedOn datetime (not null)
  Date last changed in SQL
CreatedOn datetime (not null)
  Date Created in SQL
Deleted bit (not null)
  set to 1 if deleted in M-Files

Indexes
=======

idx\_MFWorkflow\_MFID
  - MFID
TUC\_MFWorkflow\_MFID
  - MFID

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
/*

SELECT * FROM MFWorkflow

*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFWorkflow]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFWorkflow', -- nvarchar(100)
    @Object_Release = '2.0.2.2', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFWorkflow'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFWorkflow]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NOT NULL ,
              [Alias] NVARCHAR(100) NULL ,
              [MFID] INT NOT NULL ,
              [ModifiedOn] DATETIME DEFAULT ( GETDATE() )
                                    NOT NULL ,
              [CreatedOn] DATETIME DEFAULT ( GETDATE() )
                                   NOT NULL ,
              [Deleted] BIT NOT NULL ,
              CONSTRAINT [PK_MFWorkflow] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              CONSTRAINT [TUC_MFWorkflow_MFID] UNIQUE NONCLUSTERED
                ( [MFID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFWorkflow')
                        AND name = N'idx_MFWorkflow_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFWorkflow_MFID';
        CREATE NONCLUSTERED INDEX idx_MFWorkflow_MFID ON dbo.MFWorkflow (MFID);
    END;

--SECURITY #########################################################################################################################3#######
--** Alternatively add ALL security scripts to single file: script.SQLPermissions_{dbname}.sql



GO
IF NOT EXISTS(SELECT value FROM sys.[extended_properties] AS [ep] WHERE value = N'Per MF Workflow')  
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'Per MF Workflow', @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'MFWorkflow',
    @level2type = N'COLUMN', @level2name = N'MFID';

go
