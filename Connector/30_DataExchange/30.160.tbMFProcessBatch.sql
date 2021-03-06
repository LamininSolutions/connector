/*rST**************************************************************************

==============
MFProcessBatch
==============

Columns
=======

ProcessBatch\_ID int (primarykey, not null)
  SQL primary key
ProcessType nvarchar(50)
  Update Table, Synchronize Metadata (overall process being performed)
LogType nvarchar(50)
  - Status = indicate status of process to be reported to user
  - System =  considered internal operations only
  - Debug = only used for debugging purposes
  - Message = need to be reported back to user
LogText nvarchar(4000)
  User message
Status nvarchar(50)
  - Started
  - Completed
  - Failed
DurationSeconds decimal(18,4)
  Auto calculated value for the end to end process duration in seconds
CreatedOn datetime
  Default to GetDate()
CreatedOnUTC datetime
  Default to GetUTCDate()

Additional Info
===============

MFProcessBatch has a unique reference for each process. A single record is created when the process starts and updated with progress of the process until completion.

Used By
=======

- MFvwLogTableStats
- spMFDeleteHistory
- spMFLogProcessSummaryForClassTable
- spMFProcessBatch\_EMail
- spMFProcessBatch\_Upsert
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

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProcessBatch]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFProcessBatch', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFProcessBatch controls and record the outcome of each major process that is executed
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016 - 10- 16	LC			add column for UTCDate
	2016 - 3- 13	LC			Add trigger to update MFUserMessagesTable
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFProcessBatch

--DROP TABLE [MFProcessBatch]
-----------------------------------------------------------------------------------------------*/



IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProcessBatch'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

CREATE TABLE [dbo].[MFProcessBatch]
    (
      [ProcessBatch_ID] INT IDENTITY(1, 1)
                            NOT NULL ,
      [ProcessType] NVARCHAR(50) NULL ,
      [LogType] NVARCHAR(50) NULL ,
      [LogText]  NVARCHAR(4000) NULL ,
      [Status] NVARCHAR(50) NULL ,
      [DurationSeconds] DECIMAL(18, 4) NULL ,
      [CreatedOn] DATETIME NULL CONSTRAINT [DF_dbo_MFProcessBatch_CreatedOn] DEFAULT ( GETDATE() ) ,
      [CreatedOnUTC] DATETIME NULL CONSTRAINT [DF_dbo_MFProcessBatch_CreatedOnUTC] DEFAULT ( GETUTCDATE() )
        CONSTRAINT [dbo_MFProcessBatch]
        PRIMARY KEY CLUSTERED ( [ProcessBatch_ID] ASC )
    )


END
GO


