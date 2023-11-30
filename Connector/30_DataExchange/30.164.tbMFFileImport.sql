/*rST**************************************************************************

============
MFFileImport
============

Columns
=======

ID int (primarykey, not null)
  SQL primary key
FileName nvarchar(100)
  File name
FileUniqueRef nvarchar(100)
  Full file path
CreatedOn datetime (not null)
  Date of import
SourceName nvarchar(100)
  source folder name of the file
TargetClassID int
  class of the target object
MFCreated datetime
  datetime in UTC of the last modified of the object
MFLastModified datetime
  datetime in UTC of the last modified of the object
ObjID int
  objid of the imported object
Version int
  version of the object
FileObjectID int
  file id of the imported object
FileCheckSum nvarchar(max)
  Checksum of file
ImportError nvarchar(4000)
  Import related errors

Additional Info
===============
The MFFileImport table is the logging table to record the results of the import routines

Used By
=======

- spMFSynchronizeFilesToMFiles
- spMFUpdateExplorerFileToMFiles


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-08-03  LC         Change datatype of varchar to nvarchar
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFFileImport]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFFileImport', -- nvarchar(100)
    @Object_Release = '4.3.27.70', -- varchar(50)
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
			  [FileName] NVARCHAR(100),
			  [FileUniqueRef] NVARCHAR(100),
			  [CreatedOn] DATETIME DEFAULT ( GETDATE()) NOT NULL,
			  [SourceName] NVARCHAR(100),
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