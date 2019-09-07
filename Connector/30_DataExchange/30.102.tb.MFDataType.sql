/*rST**************************************************************************

==========
MFDataType
==========

Columns
=======

+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+
| Key                                                                  | Name          | Data Type      | Max Length (Bytes)   | Nullability    | Identity   | Default       |
+======================================================================+===============+================+======================+================+============+===============+
|  Cluster Primary Key PK\_MFDataType: ID                              | ID            | int            | 4                    | NOT NULL       | 1 - 1      |               |
+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+
|  Indexes idx\_MFDataType\_MFTypeID TUC\_MFDataType\_MFTypeID \ (2)   | MFTypeID      | int            | 4                    | NOT NULL       |            |               |
+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+
|                                                                      | SQLDataType   | varchar(50)    | 50                   | NULL allowed   |            |               |
+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+
|                                                                      | Name          | varchar(100)   | 100                  | NULL allowed   |            |               |
+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+
|                                                                      | ModifiedOn    | datetime       | 8                    | NOT NULL       |            | (getdate())   |
+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+
|                                                                      | CreatedOn     | datetime       | 8                    | NOT NULL       |            | (getdate())   |
+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+
|                                                                      | Deleted       | bit            | 1                    | NOT NULL       |            |               |
+----------------------------------------------------------------------+---------------+----------------+----------------------+----------------+------------+---------------+

Indexes
=======

+--------------------------------------------+-----------------------------+---------------+----------+
| Key                                        | Name                        | Key Columns   | Unique   |
+============================================+=============================+===============+==========+
|  Cluster Primary Key PK\_MFDataType: ID    | PK\_MFDataType              | ID            | YES      |
+--------------------------------------------+-----------------------------+---------------+----------+
|                                            | TUC\_MFDataType\_MFTypeID   | MFTypeID      | YES      |
+--------------------------------------------+-----------------------------+---------------+----------+
|                                            | idx\_MFDataType\_MFTypeID   | MFTypeID      |          |
+--------------------------------------------+-----------------------------+---------------+----------+

Used By
=======

- MFvwClassTableColumns
- MFvwMetadataStructure
- spMFAddCommentForObjects
- spMFClassTableColumns
- spMFCreateTable
- spMFDropAndUpdateMetadata
- spMFInsertProperty
- spMFSynchronizeFilesToMFiles
- spMFSynchronizeUnManagedObject
- spMFUpdateClassAndProperties
- spMFUpdateExplorerFileToMFiles
- spMFUpdateTable
- spMFUpdateTableInternal


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
go

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Datatypes match M-Files datatypes with SQL datatypes.  This table must not be changed
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
  Select * from MFDataType
  
-----------------------------------------------------------------------------------------------*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFDataType]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFDataType', -- nvarchar(100)
    @Object_Release = '4.2.7.46', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
changing multi lookup datatype to nvarchar(4000)
2017-2-16 update time datatype to varchar
2018-11-20 update to change datatype back to time
*/
IF NOT EXISTS (SELECT name FROM sys.tables WHERE name='MFDataType' AND SCHEMA_NAME(schema_id)='dbo')
 BEGIN
   CREATE TABLE MFDataType
  (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [MFTypeID]    INT           NOT NULL,
    [SQLDataType] VARCHAR (50)  NULL,
    [Name]        VARCHAR (100) NULL,
    [ModifiedOn]  DATETIME      DEFAULT (getdate()) NOT NULL,
    [CreatedOn]   DATETIME      DEFAULT (getdate()) NOT NULL,
    [Deleted]     BIT           NOT NULL,
    CONSTRAINT [PK_MFDataType] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [TUC_MFDataType_MFTypeID] UNIQUE NONCLUSTERED ([MFTypeID] ASC)
);


	PRINT SPACE(10) + '... Table: created'
END
ELSE
	PRINT SPACE(10) + '... Table: exists'


--INDEXES #############################################################################################################################

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('MFDataType') AND name = N'idx_MFDataType_MFTypeID')
	BEGIN
		PRINT space(10) + '... Index: idx_MFDataType_MFTypeID'
		CREATE NONCLUSTERED INDEX idx_MFDataType_MFTypeID ON dbo.MFDataType (MFTypeID)
	END

--DATA #########################################################################################################################3#######


SET IDENTITY_INSERT [dbo].[MFDataType] ON

GO

PRINT space(5) +'INSERTING DATA INTO TABLE: MFDataType '

SET NOCOUNT ON

TRUNCATE TABLE [dbo].[MFDataType];

INSERT [dbo].[MFDataType]
       ([ID],
        [MFTypeID],
        [SQLDataType],
        [Name],
        [ModifiedOn],
        [CreatedOn],
        [Deleted])
VALUES (1,
        1,
        N'NVARCHAR(100)',
        N'MFDatatypeText',
        Cast(N'2014-09-02 18:58:26.310' AS DATETIME),
        Cast(N'2014-09-02 18:58:26.310' AS DATETIME),
        0),
 (2,
        2,
        N'INTEGER',
        N'MFDatatypeInteger',
        Cast(N'2014-09-02 19:10:43.983' AS DATETIME),
        Cast(N'2014-09-02 19:10:43.983' AS DATETIME),
        0),
 (3,
        3,
        N'Float',
        N'MFDatatypeFloating',
        Cast(N'2014-09-02 19:30:01.263' AS DATETIME),
        Cast(N'2014-09-02 19:30:01.263' AS DATETIME),
        0),
 (4,
        5,
        N'Date',
        N'MFDatatypeDate',
        Cast(N'2014-09-02 19:30:06.480' AS DATETIME),
        Cast(N'2014-09-02 19:30:06.480' AS DATETIME),
        0),
 (5,
        6,
        N'Time(0)',
        N'MFDatatypeTime',
        Cast(N'2014-09-02 19:32:28.677' AS DATETIME),
        Cast(N'2014-09-02 19:32:28.677' AS DATETIME),
        0),
 (6,
        7,
        N'Datetime',
        N'MFDatatypeTimestamp',
        Cast(N'2014-09-02 19:32:40.337' AS DATETIME),
        Cast(N'2014-09-02 19:32:40.337' AS DATETIME),
        0),
 (7,
        8,
        N'BIT',
        N'MFDatatypeBoolean',
        Cast(N'2014-09-02 19:32:49.253' AS DATETIME),
        Cast(N'2014-09-02 19:32:49.253' AS DATETIME),
        0),
 (8,
        9,
        N'INTEGER',
        N'MFDatatypeLookup',
        Cast(N'2014-09-02 19:33:00.037' AS DATETIME),
        Cast(N'2014-09-02 19:33:00.037' AS DATETIME),
        0),
 (9,
        10,
        N'NVARCHAR(4000)',
        N'MFDatatypeMultiSelectLookup',
        Cast(N'2014-09-02 19:33:09.393' AS DATETIME),
        Cast(N'2014-09-02 19:33:09.393' AS DATETIME),
        0),
 (10,
        11,
        N'BigInt',
        N'MFDatatypeInteger64',
        Cast(N'2014-09-02 19:33:28.040' AS DATETIME),
        Cast(N'2014-09-02 19:33:28.040' AS DATETIME),
        0),
 (11,
        12,
        NULL,
        N'MFDatatypeFILETIME',
        Cast(N'2014-09-02 19:33:31.397' AS DATETIME),
        Cast(N'2014-09-02 19:33:31.397' AS DATETIME),
        0),
 (12,
        13,
        N'NVARCHAR(4000)',
        N'MFDatatypeMultiLineText',
        Cast(N'2014-09-02 19:30:06.480' AS DATETIME),
        Cast(N'2014-09-02 19:33:48.030' AS DATETIME),
        0)

SET IDENTITY_INSERT [dbo].[MFDataType] OFF;

GO

IF NOT EXISTS(SELECT value FROM sys.[extended_properties] AS [ep] WHERE value = N'This table is used to update the MF data types and set the related SQL datatypes') 
EXEC sys.sp_addextendedproperty
  @name       =N'MS_Description'
  ,@value     =N'This table is used to update the MF data types and set the related SQL datatypes'
  ,@level0type=N'SCHEMA'
  ,@level0name=N'dbo'
  ,@level1type=N'TABLE'
  ,@level1name=N'MFDataType'

GO 


--SECURITY #########################################################################################################################3#######

GO
