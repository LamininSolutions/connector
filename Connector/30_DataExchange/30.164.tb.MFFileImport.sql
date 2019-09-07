/*rST**************************************************************************

============
MFFileImport
============

Columns
=======

+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
| Key                                          | Name             | Data Type        | Max Length (Bytes)   | Nullability    | Identity   | Default       |
+==============================================+==================+==================+======================+================+============+===============+
|  Cluster Primary Key PK\_MFFileImport: ID    | ID               | int              | 4                    | NOT NULL       | 1 - 1      |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | FileName         | varchar(100)     | 100                  | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | FileUniqueRef    | varchar(100)     | 100                  | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | CreatedOn        | datetime         | 8                    | NOT NULL       |            | (getdate())   |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | SourceName       | varchar(100)     | 100                  | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | TargetClassID    | int              | 4                    | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | MFCreated        | datetime         | 8                    | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | MFLastModified   | datetime         | 8                    | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | ObjID            | int              | 4                    | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | Version          | int              | 4                    | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | FileObjectID     | int              | 4                    | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | FileCheckSum     | nvarchar(max)    | max                  | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+
|                                              | ImportError      | nvarchar(4000)   | 8000                 | NULL allowed   |            |               |
+----------------------------------------------+------------------+------------------+----------------------+----------------+------------+---------------+

Indexes
=======

+----------------------------------------------+--------------------+---------------+----------+
| Key                                          | Name               | Key Columns   | Unique   |
+==============================================+====================+===============+==========+
|  Cluster Primary Key PK\_MFFileImport: ID    | PK\_MFFileImport   | ID            | YES      |
+----------------------------------------------+--------------------+---------------+----------+

Used By
=======

- spMFSynchronizeFilesToMFiles
- spMFUpdateExplorerFileToMFiles


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFFileImport]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFFileImport', -- nvarchar(100)
    @Object_Release = '4.3.9.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV TEAM2, Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: MFiles FileImport 
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2019-3-23		LC			Add ImportError Column
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFFileImport
  
-----------------------------------------------------------------------------------------------*/
IF NOT EXISTS (	  SELECT	[name]
				  FROM		[sys].[tables]
				  WHERE		[name] = 'MFFileImport'
							AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN
	      CREATE TABLE MFFileImport
		   (
		      [ID] INT IDENTITY(1,1) NOT NULL,
			  [FileName] VARCHAR(100),
			  [FileUniqueRef] VARCHAR(100),
			  [CreatedOn] DATETIME DEFAULT ( GETDATE()) NOT NULL,
			  [SourceName] VARCHAR(100),
			  [TargetClassID] INT,
			  [MFCreated] DATETIME,
			  [MFLastModified] DATETIME,
			  [ObjID] INT, 
			  [Version] INT,
			  CONSTRAINT [PK_MFFileImport]
					PRIMARY KEY CLUSTERED ( [ID] ASC) 
		   )
	End
ELSE 

PRINT SPACE(10) + '... Table: exist'

GO
IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFFileImport'
		AND [COLUMN_NAME] = 'FileObjectID'
		
		)
BEGIN
	ALTER TABLE MFFileImport ADD FileObjectID INT;
	PRINT SPACE(10) + '... Column Message: Added FileObjectID Column';
END

GO

IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFFileImport'
		AND [COLUMN_NAME] = 'FileCheckSum'
		
		)
BEGIN
	ALTER TABLE MFFileImport ADD FileCheckSum NVARCHAR(MAX);
	PRINT SPACE(10) + '... Column Message: Added FileCheckSum Column';
END

IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFFileImport'
		AND [COLUMN_NAME] = 'ImportError' 		
		)
BEGIN
	ALTER TABLE MFFileImport ADD ImportError NVARCHAR(4000);
	PRINT SPACE(10) + '... Column Message: Added ImportError Column';

	END
GO