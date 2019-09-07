/*rST**************************************************************************

===========
MFValueList
===========

Columns
=======

+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
| Key                                                                        | Name             | Data Type       | Max Length (Bytes)   | Nullability    | Identity   | Default       |
+============================================================================+==================+=================+======================+================+============+===============+
|  Cluster Primary Key PK\_MFValueList: ID \  Indexes idx\_MFValueList\_1    | ID               | int             | 4                    | NOT NULL       | 1 - 1      |               |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|  Indexes idx\_MFValueList\_1 udx\_MFValueList\_MFID \ (2)                  | Name             | varchar(100)    | 100                  | NULL allowed   |            |               |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|                                                                            | Alias            | nvarchar(100)   | 200                  | NULL allowed   |            |               |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|  Indexes udx\_MFValueList\_MFID                                            | MFID             | int             | 4                    | NULL allowed   |            |               |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|                                                                            | OwnerID          | int             | 4                    | NULL allowed   |            |               |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|                                                                            | ModifiedOn       | datetime        | 8                    | NOT NULL       |            | (getdate())   |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|                                                                            | CreatedOn        | datetime        | 8                    | NOT NULL       |            | (getdate())   |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|                                                                            | Deleted          | bit             | 1                    | NOT NULL       |            | ((0))         |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+
|                                                                            | RealObjectType   | bit             | 1                    | NULL allowed   |            |               |
+----------------------------------------------------------------------------+------------------+-----------------+----------------------+----------------+------------+---------------+

Indexes
=======

+---------------------------------------------+--------------------------+---------------+--------------------+----------+
| Key                                         | Name                     | Key Columns   | Included Columns   | Unique   |
+=============================================+==========================+===============+====================+==========+
|  Cluster Primary Key PK\_MFValueList: ID    | PK\_MFValueList          | ID            |                    | YES      |
+---------------------------------------------+--------------------------+---------------+--------------------+----------+
|                                             | udx\_MFValueList\_MFID   | MFID          | Name               | YES      |
+---------------------------------------------+--------------------------+---------------+--------------------+----------+
|                                             | idx\_MFValueList\_1      | ID, Name      |                    |          |
+---------------------------------------------+--------------------------+---------------+--------------------+----------+

Used By
=======

- MFProperty
- MFValueListItems
- MFvwMetadataStructure
- MFvwUserGroup
- spMFClassTableColumns
- spMFCreateAllLookups
- spMFCreateValueListLookupView
- spMFDropAndUpdateMetadata
- spMFInsertProperty
- spMFInsertValueList
- spMFInsertValueListItems
- spmfSynchronizeLookupColumnChange
- spMFSynchronizeProperties
- spMFSynchronizeSpecificMetadata
- spMFSynchronizeValueList
- spMFSynchronizeValueListItems
- spMFSynchronizeValueListItemsToMFiles


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
/*----------leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Valuelist MFiles Metadata 	
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
  Select * from MFValueList

  Alter table MFValueListItems
  Drop CONSTRAINT FK_MFValueListItems_MFValueList

  Alter table MFProperty
  Drop CONSTRAINT FK_MFProperty_MFValueList

  DROP TABLE MFValuelist
  
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
