/*rST**************************************************************************

===========
MFValueList
===========

Columns
=======

ID int (primarykey, not null)
  SQL Primary Key
Name varchar(100)
  Name of the valuelist from M-Files
Alias nvarchar(100)
  Alias from M-Files
MFID int
  M-Files ID
OwnerID int
  Owner MFID
ModifiedOn datetime (not null)
  When was the record last modified
CreatedOn datetime (not null)
  When was the record created
Deleted bit (not null)
  Is deleted
RealObjectType bit
  set to 1 if valuelist is an full object type with classes and properties

Additional Info
===============

The column **OwnerID** references the Owner Valuelist MFID or ObjectType MFID in the case of real ObjectTypes. For
example: 'State' is owned by 'Workflow'.

-1 indicates no owner

Indexes
=======

idx\_MFValueList\_1
  - ID
  - Name
udx\_MFValueList\_MFID
  - Name
  - MFID

USAGE
=====

.. code:: sql

   Select * from MFValueList  

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
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFValueList]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFValueList', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFValueList'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
   
        CREATE TABLE [dbo].[MFValueList]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NULL ,
              [Alias] NVARCHAR(100) NULL ,
              [MFID] INT NULL ,
              [OwnerID] INT NULL ,
              [ModifiedOn] DATETIME
                CONSTRAINT [DF__MFValueList_ModifiedOn] DEFAULT ( GETDATE() )
                NOT NULL ,
              [CreatedOn] DATETIME
                CONSTRAINT [DF__MFValueList_CreatedOn] DEFAULT ( GETDATE() )
                NOT NULL ,
              [Deleted] BIT CONSTRAINT [DF_MFValueList_Deleted] DEFAULT ((0))
                            NOT NULL ,
              CONSTRAINT [PK_MFValueList] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueList')
                        AND name = N'udx_MFValueList_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: udx_MFValueList_MFID';
        CREATE UNIQUE NONCLUSTERED INDEX udx_MFValueList_MFID ON dbo.MFValueList (MFID) INCLUDE (Name);
    END;


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueList')
                        AND name = N'idx_MFValueList_1' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFValueList_1';
        CREATE NONCLUSTERED INDEX idx_MFValueList_1 ON dbo.MFValueList (ID, Name);
    END;


GO

IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Represents all the valuelists of the selected vault' )
			BEGIN
          
    EXECUTE sp_addextendedproperty @name = N'MS_Description',
        @value = N'Represents all the valuelists of the selected vault',
        @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
        @level1name = N'MFValueList';

		PRINT SPACE(10) + '... Extended Properties Create : ';
		end


IF Not Exists ( Select top 1 *  from INFORMATION_SCHEMA.COLUMNS C where c.COLUMN_NAME='RealObjectType' and C.TABLE_NAME='MFValueList')
	Begin
	ALTER table MFValueList add [RealObjectType] BIT

	PRINT SPACE(10) + '......RealObjectType COLUMN IS ADDED.'
End
GO
