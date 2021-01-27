/*rST**************************************************************************

============
MFObjectType
============

Columns
=======

ID int (primarykey, not null)
  SQL id
Name varchar(100)
  Name of Object Type
Alias nvarchar(100)
  Aliase of object type
MFID int (not null)
  M-Files id
ModifiedOn datetime (not null)
  last modified in SQL
CreatedOn datetime (not null)
  created in SQL
Deleted bit (not null)
  set to 1 when object is deleted in MF

Indexes
=======

TUC\_MFObjectType\_MFID
  - MFID

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
GO

SET NOCOUNT ON; 
GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFObjectType]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFObjectType', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFObjectType'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFObjectType]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NULL ,
              [Alias] NVARCHAR(100) NULL ,
              [MFID] INT NOT NULL ,
              [ModifiedOn] DATETIME DEFAULT ( GETDATE() )
                                    NOT NULL ,
              [CreatedOn] DATETIME DEFAULT ( GETDATE() )
                                   NOT NULL ,
              [Deleted] BIT NOT NULL ,
              CONSTRAINT [PK_MFObjectType] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              CONSTRAINT [TUC_MFObjectType_MFID] UNIQUE NONCLUSTERED
                ( [MFID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


IF NOT EXISTS(SELECT value FROM sys.[extended_properties] AS [ep] WHERE value = N'Represents the Object Types of the selected vault')  
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'Represents the Object Types of the selected vault',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFObjectType';

GO
