/*rST**************************************************************************

===============
MFUpdateHistory
===============

Columns
=======

Id int (primarykey, not null)
  fixme description
Username nvarchar(250) (not null)
  fixme description
VaultName nvarchar(250) (not null)
  fixme description
UpdateMethod smallint (not null)
  fixme description
ObjectDetails xml
  fixme description
ObjectVerDetails xml
  fixme description
NewOrUpdatedObjectVer xml
  fixme description
NewOrUpdatedObjectDetails xml
  fixme description
SynchronizationError xml
  fixme description
MFError xml
  fixme description
DeletedObjectVer xml
  fixme description
UpdateStatus varchar(25)
  fixme description
CreatedAt datetime
  fixme description

Indexes
=======

idx\_MFUpdateHistory\_id
  - Id

Used By
=======

- MFvwLogTableStats
- spMFAddCommentForObjects
- spMFCheckAndUpdateAssemblyVersion
- spMFDeleteHistory
- spMFGetHistory
- spMFLogError\_EMail
- spMFSynchronizeFilesToMFiles
- spmfSynchronizeLookupColumnChange
- spMFSynchronizeUnManagedObject
- spmfSynchronizeWorkFlowSateColumnChange
- spMFUpdateClassAndProperties
- spMFUpdateExplorerFileToMFiles
- spMFUpdateHistoryShow
- spMFUpdateTable


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUpdateHistory]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUpdateHistory', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: MFUpdate history auto assigns a unique id for each update to and from M-Files	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFUpdateHistory
  
-----------------------------------------------------------------------------------------------*/




IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUpdateHistory'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFUpdateHistory]
            (
              [Id] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Username] NVARCHAR(250) NOT NULL ,
              [VaultName] NVARCHAR(250) NOT NULL ,
              [UpdateMethod] SMALLINT NOT NULL ,
              [ObjectDetails] XML NULL ,
              [ObjectVerDetails] XML NULL ,
              [NewOrUpdatedObjectVer] XML NULL ,
              [NewOrUpdatedObjectDetails] XML NULL ,
              [SynchronizationError] XML NULL ,
              [MFError] XML NULL ,
              [DeletedObjectVer] XML NULL ,
              [UpdateStatus] VARCHAR(25) NULL ,
              [CreatedAt] DATETIME
                CONSTRAINT [CreatedAt] DEFAULT ( GETDATE() )
                NULL ,
              CONSTRAINT [PK_MFUpdateHistory] PRIMARY KEY CLUSTERED
                ( [Id] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';
	GO

--INDEXES #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFUpdateHistory')
                        AND name = N'idx_MFUpdateHistory_id' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFUpdateHistory_id';
        CREATE NONCLUSTERED INDEX idx_MFUpdateHistory_id ON dbo.MFUpdateHistory (Id);
    END;


--SECURITY #########################################################################################################################3#######

IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'output XML contains updated or Created object detials' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'output XML contains updated or Created object detials',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'NewOrUpdatedObjectDetails';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'output XML contains updated or created ObjVer details' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'output XML contains updated or created ObjVer details',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'NewOrUpdatedObjectVer';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'input XML contains existing ObjVer details' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'input XML contains existing ObjVer details',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'ObjectVerDetails';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'input XML contains updated or created object details ' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'input XML contains updated or created object details ',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'ObjectDetails';

go
