/*rST**************************************************************************

================
MFValueListItems
================

Columns
=======

+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
| Key                                                                                                                                   | Name            | Data Type       | Max Length (Bytes)   | Nullability    | Identity   | Default       | Description                |
+=======================================================================================================================================+=================+=================+======================+================+============+===============+============================+
|  Cluster Primary Key PK\_MFValueListItems: ID                                                                                         | ID              | int             | 4                    | NOT NULL       | 1 - 1      |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | Name            | nvarchar(100)   | 200                  | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | MFID            | nvarchar(20)    | 40                   | NULL allowed   |            |               | *Per MF ValuelistitemID*   |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|  Indexes fdx\_MFValueListItems\_MFValueListID \  Foreign Keys FK\_MFValueListItems\_MFValueList: [dbo].[MFValueList].MFValueListID    | MFValueListID   | int             | 4                    | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | OwnerID         | int             | 4                    | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | ModifiedOn      | datetime        | 8                    | NOT NULL       |            | (getdate())   |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | CreatedOn       | datetime        | 8                    | NOT NULL       |            | (getdate())   |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | Deleted         | bit             | 1                    | NOT NULL       |            | ((0))         |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|  Indexes idx\_MFValueListItems\_AppRef                                                                                                | AppRef          | nvarchar(25)    | 50                   | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | Owner\_AppRef   | nvarchar(25)    | 50                   | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | ItemGUID        | nvarchar(200)   | 400                  | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | DisplayID       | nvarchar(200)   | 400                  | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | Process\_ID     | int             | 4                    | NULL allowed   |            | ((0))         |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+
|                                                                                                                                       | IsNameUpdate    | bit             | 1                    | NULL allowed   |            |               |                            |
+---------------------------------------------------------------------------------------------------------------------------------------+-----------------+-----------------+----------------------+----------------+------------+---------------+----------------------------+

Indexes
=======

+--------------------------------------------------+----------------------------------------+-----------------+----------+
| Key                                              | Name                                   | Key Columns     | Unique   |
+==================================================+========================================+=================+==========+
|  Cluster Primary Key PK\_MFValueListItems: ID    | PK\_MFValueListItems                   | ID              | YES      |
+--------------------------------------------------+----------------------------------------+-----------------+----------+
|                                                  | fdx\_MFValueListItems\_MFValueListID   | MFValueListID   |          |
+--------------------------------------------------+----------------------------------------+-----------------+----------+
|                                                  | idx\_MFValueListItems\_AppRef          | AppRef          |          |
+--------------------------------------------------+----------------------------------------+-----------------+----------+

Foreign Keys
============

+-------------------------------------+------------------------------------------------------------------+
| Name                                | Columns                                                          |
+=====================================+==================================================================+
| FK\_MFValueListItems\_MFValueList   | MFValueListID->\ `[dbo].[MFValueList].[ID] <MFValueList.md>`__   |
+-------------------------------------+------------------------------------------------------------------+

Uses
====

- MFValueList

Used By
=======

- MFvwUserGroup
- spMFDropAndUpdateMetadata
- spMFInsertValueListItems
- spmfSynchronizeLookupColumnChange
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
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: Valuelist Items MFiles Metadata in one table
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
  Select * from MFValueListItems
  DROP table MFValueListItems
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFValueListItems]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFValueListItems', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
2018-4-18	lc	Fix bug to reset table name data type to nvarchar
*/

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFValueListItems'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
   
			CREATE TABLE [dbo].[MFValueListItems]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] NVARCHAR(100) NULL ,
              [MFID] NVARCHAR(20) NULL ,
              [MFValueListID] INT NULL ,
              [OwnerID] INT NULL ,
              [ModifiedOn] DATETIME
                CONSTRAINT [DF__MFValueListItems__Modify]
                DEFAULT ( GETDATE() )
                NOT NULL ,
              [CreatedOn] DATETIME
                CONSTRAINT [DF__MFValueListItems__Create]
                DEFAULT ( GETDATE() )
                NOT NULL ,
              [Deleted] BIT CONSTRAINT [DF_MFValueListItems_Deleted] DEFAULT ((0))
                            NOT NULL ,
              [AppRef] NVARCHAR(25) NULL ,
              [Owner_AppRef] NVARCHAR(25) NULL ,
			  [ItemGUID]  nvarchar(200),
			  [DisplayID] nvarchar(200),
			  [Process_ID] int DEFAULT ((0)),
              CONSTRAINT [PK_MFValueListItems] PRIMARY KEY CLUSTERED
                ( [ID] ASC ) ,
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--FOREIGN KEYS #############################################################################################################################
 

IF NOT EXISTS ( SELECT  *
                FROM    sys.foreign_keys
                WHERE   parent_object_id = OBJECT_ID('MFValueListItems')
                        AND name = N'FK_MFValueListItems_MFValueList' )

    BEGIN
        PRINT SPACE(10) + '... Constraint: FK_MFValueListItems_MFValueList';
        ALTER TABLE dbo.MFValueListItems WITH CHECK ADD 
        CONSTRAINT [FK_MFValueListItems_MFValueList] FOREIGN KEY ( [MFValueListID] ) REFERENCES [dbo].[MFValueList] ( [id] ) 
        ON DELETE NO ACTION;

    END;

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueListItems')
                        AND name = N'idx_MFValueListItems_AppRef' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFValueListItems_AppRef';
        CREATE NONCLUSTERED INDEX idx_MFValueListItems_AppRef ON dbo.MFValueListItems (AppRef);
    END;

	
IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueListItems')
                        AND name = N'fdx_MFValueListItems_MFValueListID' )
    BEGIN
        PRINT SPACE(10) + '... Index: fdx_MFValueListItems_MFValueListID';
        CREATE NONCLUSTERED INDEX fdx_MFValueListItems_MFValueListID ON dbo.MFValueListItems (MFValueListID);
    END;

GO


IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Per MF ValuelistitemID' )
    BEGIN
                
        EXECUTE sp_addextendedproperty @name = N'MS_Description',
            @value = N'Per MF ValuelistitemID', @level0type = N'SCHEMA',
            @level0name = N'dbo', @level1type = N'TABLE',
            @level1name = N'MFValueListItems', @level2type = N'COLUMN',
            @level2name = N'MFID';
        PRINT SPACE(10) + '... Extended Properties Create : ';
    END;

GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Represents on table that contain all the valuelists and all the valuelist items' )
    BEGIN
            
        EXECUTE sp_addextendedproperty @name = N'MS_Description',
            @value = N'Represents on table that contain all the valuelists and all the valuelist items',
            @level0type = N'SCHEMA', @level0name = N'dbo',
            @level1type = N'TABLE', @level1name = N'MFValueListItems';
        PRINT SPACE(10) + '... Extended Properties Create : ' ;
    END;

	IF Not Exists (Select top 1 * from INFORMATION_SCHEMA.COLUMNS C where C.COLUMN_NAME='IsNameUpdate' and C.TABLE_NAME='MFValueListItems')
			Begin

			 Alter table MFValueListItems Add IsNameUpdate Bit
             PRINT SPACE(10) + '... Added column IsNameUpdate  : ' ;
			End
GO
        