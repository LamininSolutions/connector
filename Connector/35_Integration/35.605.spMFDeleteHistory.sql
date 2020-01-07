PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDeleteHistory]';
GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFDeleteHistory', -- nvarchar(100)
    @Object_Release = '2.1.1.13', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFDeleteHistory'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFDeleteHistory]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO
Alter procedure [dbo].[spMFDeleteHistory](
@DeleteBeforeDate DATETIME 
)
as
/*******************************************************************************
  ** Desc:  The purpose of this procedure is to delete all records in MFlog,MFUpdateHistory,MFAuditHistory till the given date  
  **  
  ** Version: 2.0.2.5
  **
  ** Processing Steps:
  **					1.delete the records in MFLog
                         2.delete the records in MFUpdateHistory
					3.delete the records in MFAuditHistory
  **
  ** Parameters and acceptable values: 					
  **					@DeleteBeforeDate        DATETIME
  **			       
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					
  **
  ** Called By:			
  **
  ** Calls:           
  **					NONE
  **														
  **
  ** Author:			Kishore
  ** Date:				28-07-2016

  Change history

  2016-11-10 LC Add ProcessBatch and ProcessBatchDetail to delete

  ******************************************************************************/
  SET NOCOUNT on
BEGIN

delete from MFLog where CreateDate < = @DeleteBeforeDate 
delete from MFUpdateHistory where CreatedAt < = @DeleteBeforeDate
delete from MFAuditHistory where [TranDate] < = @DeleteBeforeDate
DELETE FROM [dbo].[MFProcessBatchDetail] WHERE [MFProcessBatchDetail].[CreatedOn] < = @DeleteBeforeDate
DELETE FROM [dbo].[MFProcessBatch] WHERE [MFProcessBatch].[CreatedOn] < = @DeleteBeforeDate

END
RETURN 1
GO


