/*rST**************************************************************************

===================
MFExportFileHistory
===================

Columns
=======

ID int (primarykey, not null)
  SQL primary key
FileExportRoot nvarchar(100)
  - Rootfolder is automatically set to C:\MFSQL\FileExport and can be changed in MFSettings
  - Rootfolder + FileExportFolder
  - The FileExportFolder is class specific and is set in the MFClass table by class. It defaults to NULL.
  - The FileExportFolder will separate the files for different classes in the folder system.
SubFolder\_1 nvarchar(100)
  This parameter is set in the spMFExportFiles procedure
SubFolder\_2 nvarchar(100)
  This parameter is set in the spMFExportFiles procedure
SubFolder\_3 nvarchar(100)
  This parameter is set in the spMFExportFiles procedure
MultiDocFolder nvarchar(100)
  fixme description
FileName nvarchar(256)
  M-Files filename of the file
ClassID int
  M-Files class ID of the related class table
ObjID int
  M-Files ObjID for the metadata object
ObjType int
  M-Files ObjectType for the class
Version int
  Version number of the object that contained the exported file
FileCheckSum nvarchar(100)
  Calculated checksum for the exported file
FileCount int
  The count of the files in the object
Created datetime
  The date and time of the export of the file
FileObjectID int
  fixme description

Used By
=======

- spMFExportFiles


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
2018-06-29  LC         Add Column for MultiDocFolder
2018-09-27  LC         Add script to alter column if missing
2019-02-22  LC         Increase size of column for filename
2017-06-15  LC         Created table
==========  =========  ========================================================

**rST*************************************************************************/
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFExportFileHistory]';

GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
								   , @ObjectName = N'MFExportFileHistory' -- nvarchar(100)
								   , @Object_Release = '4.2.7.46'		   -- varchar(50)
								   , @UpdateFlag = 2;
-- smallint
GO

IF NOT EXISTS (	  SELECT [name]
				  FROM	 [sys].[tables]
				  WHERE	 [name] = 'MFExportFileHistory'
						 AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN

CREATE TABLE MFExportFileHistory
(ID INT IDENTITY PRIMARY key
,FileExportRoot NVARCHAR(100) 
,SubFolder_1 NVARCHAR(100) 
,SubFolder_2 NVARCHAR(100) 
,SubFolder_3 NVARCHAR(100) 
,MultiDocFolder NVARCHAR(100)
,FileName NVARCHAR(256)
,ClassID INT 
,ObjID int
,ObjType int
,Version int
,[FileCheckSum] NVARCHAR(100)
,FileCount INT
,Created DATETIME DEFAULT (GETDATE())
)

ALTER TABLE [dbo].[MFExportFileHistory] ADD CONSTRAINT [PK__MFExportFileHistory_ID] PRIMARY KEY CLUSTERED  ([ID])


	END



GO

IF NOT EXISTS (	  SELECT	1
				  FROM		[INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE		[c].[TABLE_NAME] = 'MFExportFileHistory'
							AND [c].[COLUMN_NAME] = 'MultiDocFolder'
			  )
	BEGIN
		ALTER TABLE dbo.[MFExportFileHistory] ADD [MultiDocFolder] NVARCHAR(500)

		PRINT SPACE(10) + '... Column [MultiDocFolder]: added';

	END


	GO 

	IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFExportFileHistory'
		AND [COLUMN_NAME] = 'FileObjectID'
		
		)
BEGIN
	ALTER TABLE MFExportFileHistory ADD FileObjectID INT;
	PRINT SPACE(10) + '... Column Message: Added FileObjectID Column';
END

GO
--INDEXES #############################################################################################################################


