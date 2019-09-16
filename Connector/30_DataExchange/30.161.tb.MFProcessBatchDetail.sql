/*rST**************************************************************************

====================
MFProcessBatchDetail
====================

Columns
=======

ProcessBatchDetail\_ID int (primarykey, not null)
  fixme description
ProcessBatch\_ID int
  fixme description
LogType nvarchar(50)
  fixme description
ProcedureRef nvarchar(258)
  fixme description
LogText nvarchar(4000)
  fixme description
Status nvarchar(50)
  fixme description
DurationSeconds decimal(18,4)
  fixme description
CreatedOn datetime
  fixme description
CreatedOnUTC datetime
  fixme description
MFTableName nvarchar(128)
  fixme description
Validation\_ID int
  fixme description
ColumnName nvarchar(128)
  fixme description
ColumnValue nvarchar(256)
  fixme description
Update\_ID int
  fixme description

Indexes
=======

idx\_dbo\_MFProcessBatchDetail
  - ProcessBatch\_ID

Used By
=======

- MFvwLogTableStats
- spMFDeleteHistory
- spMFProcessBatchDetail\_Insert
- spMFResultMessageForUI


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFProcessBatchDetail]';

GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
								   , @ObjectName = N'MFProcessBatchDetail' -- nvarchar(100)
								   , @Object_Release = '3.1.2.38'		   -- varchar(50)
								   , @UpdateFlag = 2;
-- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFProcessBatchDetail table records details about processing of key procuredures
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-10-16		lc			Add Created on ITC Date
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFProcessBatchDetail
  
--DROP TABLE dbo.[MFProcessBatchDetail]
-----------------------------------------------------------------------------------------------*/




IF NOT EXISTS (	  SELECT [name]
				  FROM	 [sys].[tables]
				  WHERE	 [name] = 'MFProcessBatchDetail'
						 AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN

		CREATE TABLE [dbo].[MFProcessBatchDetail]
			(
				[ProcessBatchDetail_ID] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
			  , [ProcessBatch_ID] INT NULL
			  , [LogType] NVARCHAR(50) NULL
			  , [ProcedureRef] NVARCHAR(258) NULL
			  , [LogText] NVARCHAR(4000) NULL
			  , [Status] NVARCHAR(50) NULL
			  , [DurationSeconds] DECIMAL(18, 4) NULL
			  , [CreatedOn] DATETIME NULL
					CONSTRAINT [DF_dbo_MFProcessBatchDetail_CreatedOn]
					DEFAULT ( GETDATE())
			  , [CreatedOnUTC] DATETIME NULL
					CONSTRAINT [DF_dbo_MFProcessBatchDetail_CreatedOnUTC]
					DEFAULT ( GETUTCDATE())
			  , [MFTableName] NVARCHAR(128) NULL
			  , [Validation_ID] INT NULL
			  , [ColumnName] NVARCHAR(128) NULL
			  , [ColumnValue] NVARCHAR(256) NULL
			  , [Update_ID] INT NULL
			);

	END

GO
--Table modifications #############################################################################################################################
-- add column [ProcessRef] to improve ability to track procedurename and procedurestep

IF NOT EXISTS (	  SELECT 1
				  FROM	 [INFORMATION_SCHEMA].[COLUMNS]
				  WHERE	 [TABLE_NAME] = 'MFProcessBatchDetail'
						 AND [COLUMN_NAME] = 'ProcedureRef'
			  )
	BEGIN
		ALTER TABLE [dbo].[MFProcessBatchDetail]
		ADD [ProcedureRef] NVARCHAR(258) NULL;
		PRINT SPACE(10) + '... Adding Column: [ProcedureRef] NVARCHAR(258)';
	END
GO
IF EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFProcessBatchDetail'
		AND [COLUMN_NAME] = 'ProcedureRef'
		AND [CHARACTER_MAXIMUM_LENGTH] <> 258
		)
BEGIN
	ALTER TABLE [dbo].[MFProcessBatchDetail] ALTER COLUMN [ProcedureRef] NVARCHAR(258)
	PRINT SPACE(10) + '... Update Column Size: [ProcedureRef] NVARCHAR(258)';
END

GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFProcessBatchDetail'
		AND [COLUMN_NAME] = 'CreatedOnUTC'
		)
BEGIN
	ALTER TABLE [dbo].[MFProcessBatchDetail] ADD  CreatedOnUTC DATETIME NULL
					CONSTRAINT [DF_dbo_MFProcessBatchDetail_CreatedOnUTC]
					DEFAULT ( GETUTCDATE())
	PRINT SPACE(10) + '... Add Column : CreatedOn UTCGETUTCDATE()';
END

GO
--INDEXES #############################################################################################################################


IF NOT EXISTS (	  SELECT *
				  FROM	 [sys].[indexes]
				  WHERE	 [object_id] = OBJECT_ID('dbo.MFProcessBatchDetail')
						 AND [name] = N'idx_dbo_MFProcessBatchDetail'
			  )
	BEGIN
		PRINT SPACE(10) + '... Creating Unique Index: idx_dbo_MFProcessBatchDetail';
		CREATE NONCLUSTERED INDEX [idx_dbo_MFProcessBatchDetail]
			ON [dbo].[MFProcessBatchDetail] ( [ProcessBatch_ID] );
	END;
ELSE
	PRINT SPACE(10) + '... Unique Index: idx_dbo_MFProcessBatchDetail exists';



GO


