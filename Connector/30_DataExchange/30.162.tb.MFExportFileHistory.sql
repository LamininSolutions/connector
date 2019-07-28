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
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-09
	Database: 
	Description: MFExportFileHistory table records for files exported from M-Files
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2018-6-29		lc			Add Column for MultiDocFolder
	2018-9-27		lc			Add script to alter column if missing
	2019-2-22		lc			Increase size of column for filename
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFExportFileHistory
  
--DROP TABLE dbo.[MFExportFileHistory]
-----------------------------------------------------------------------------------------------*/




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


	END



GO
--Table modifications #############################################################################################################################

/*	
	Effective Version: 4.2.5.43
	MultiDocFolder is introoduced in this version
*/
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


