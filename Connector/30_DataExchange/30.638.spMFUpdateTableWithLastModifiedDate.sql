PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableWithLastModifiedDate]';
GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTableWithLastModifiedDate',
    -- nvarchar(100)
    @Object_Release = '4.3.10.49',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint

GO

IF EXISTS
    (
        SELECT
            1
        FROM
            [INFORMATION_SCHEMA].[ROUTINES]
        WHERE
            [ROUTINE_NAME] = 'spMFUpdateTableWithLastModifiedDate' --name of procedure
            AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
            AND [ROUTINE_SCHEMA] = 'dbo'
    )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';

        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateTableWithLastModifiedDate]
AS
    SELECT
        'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

/*
Procedure that update MF Class table using the last MFUpdate date and returning the new last Update date

Usage: 

Declare @last_Modified datetime
exec spMFUpdateTableWithLastModifiedDate @UpdateMethod = 1, 
@TableName = 'MFSOInvoiced', @Return_LastModified = @last_Modified output
Select @last_Modified

Change history

2016-8-25	LC	Add the Update_ID from UpdateTable as an output on this procedure also to pass it through
2016-10-8   LC fix bug with null values
2017-06-29	AC	fix bug introduced by fix of Bug #1049
2017-06-30  AC	Update LogStatusDetail to be consisted with convention of using Started and Completed as the status descriptions
				Update Logging of MFLastModifiedDate as a Column and Value pair 	
				Update Logging to make use of new @ProcessBatchDetail_ID to calculate duration	

2017-11-23	LC	LastModified column name date localization
2018-10-22  LC  Modify logtext description to align with reporting
2018-10-22  LC  Add 1 second to last modified data to avoid reprocessing the last record.
2019-07-07	LC	Change sequnce of paramters, add new method to include updating deletions.

*/

ALTER PROCEDURE [dbo].[spMFUpdateTableWithLastModifiedDate]
    @TableName           sysname,
    @UpdateMethod        INT,
    @Return_LastModified DATETIME = NULL OUTPUT,
    @Update_IDOut        INT      = NULL OUTPUT,
    @ProcessBatch_ID     INT      = NULL OUTPUT,
    @debug               SMALLINT = 0
AS
/*rST**************************************************************************

===================================
spMFUpdateTableWithLastModifiedDate
===================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @TableName sysname
    fixme description
  @UpdateMethod int
    fixme description
  @Return\_LastModified datetime (output)
    fixme description
  @Update\_IDOut int (output)
    fixme description
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @debug smallint
    fixme description


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

    DECLARE
        @SQL           NVARCHAR(MAX),
        @Params        NVARCHAR(MAX),
        @return_Value  INT,
        @LastModified  DATETIME,
		@MFLastUpdate DATETIME,
        @procedureStep VARCHAR(100) = 'Update',
        @procedureName VARCHAR(100) = 'spMFUpdateTableWithLastModifiedDate',
        @MFTableName   sysname      = @TableName;

    /*
Process Batch Declarations to be added
*/

    DECLARE @RC INT;
    DECLARE @ProcessType NVARCHAR(50);
    DECLARE @LogType NVARCHAR(50);
    DECLARE @LogText NVARCHAR(4000);
    DECLARE @LogStatus NVARCHAR(50);
    DECLARE @StartTime DATETIME;
    DECLARE @Validation_ID INT;
    DECLARE @ColumnName NVARCHAR(128);
    DECLARE @ColumnValue NVARCHAR(256);
    DECLARE @LogProcedureName NVARCHAR(128);
    DECLARE @LogProcedureStep NVARCHAR(128);
    DECLARE @update_ID INT = NULL;
    DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
    DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
    DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
    DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
    DECLARE @ProcessBatchDetail_IDOUT INT;

    /*
Process Batch
*/

    /*
Process Batch Initiate
*/

    SET @ProcessType = @procedureName;

    SET @LogType = 'Debug';
    SET @LogText = @procedureStep;
    SET @LogStatus = 'Started';


    EXECUTE @Return_LastModified = [dbo].[spMFProcessBatch_Upsert]
        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = @LogType,
        @LogText = @LogText,
        @LogStatus = @LogStatus,
        @debug = @debug;

    SET @StartTime = GETUTCDATE(); --- position this at the start of the process to be measured
    SET @procedureStep = 'Update Table with LastModified Date';

    IF @debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @procedureName, @procedureStep);

        END;

    SET @StartTime = GETUTCDATE();

    SET @procedureStep = 'Update Table with LastModified filter';
    SET @LogTypeDetail = 'Debug';
    SET @LogStatusDetail = 'Start';
    SET @LogTextDetail = 'Update: ' + CAST(@TableName AS NVARCHAR(256));
    SET @LogColumnName = '';
    SET @LogColumnValue = '';
    SET @ProcessBatchDetail_IDOUT = NULL;

    EXECUTE @return_Value = [dbo].[spMFProcessBatchDetail_Insert]
        @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = @LogTypeDetail,
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatusDetail,
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = @LogColumnName,
        @ColumnValue = @LogColumnValue,
        @Update_ID = @update_ID,
        @LogProcedureName = @procedureName,
        @LogProcedureStep = @procedureStep,
        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT OUTPUT,
        @debug = @debug;

    DECLARE @lastModifiedColumn NVARCHAR(100);
    SELECT
        @lastModifiedColumn = [mp].[ColumnName]
    FROM
        [dbo].[MFProperty] AS [mp]
    WHERE
        [MFID] = 21; --'Last Modified'

    SELECT
        @Params
        = N'@return_Value int output, @TableName sysname, @Debug smallint, @Update_IDOut int Output, @ProcessBatch_ID int output, @MFLastUpdate datetime output';
    SELECT
        @SQL
        = N'
	SELECT @MFLastUpdate = MAX(isnull(' + QUOTENAME(@lastModifiedColumn) + ',0)) FROM dbo.' + QUOTENAME(@TableName)
          + '
	SET @MFLastUpdate = DATEADD(hour,-(DATEDIFF(hour,GETDATE(),GETUTCDATE())) ,@MFLastUpdate)
	SET @MFLastUpdate=DATEADD(Minute,DateDiff(MINUTE,Getdate(),getUTCDate()),@MFLastUpdate) --Added for Bug #1049
	 SELECT @MFLastUpdate =DATEADD(SECOND,1,@MFLastUpdate)
	--PRINT @MFLastUpdate --Added for Bug #1049

	EXEC	@return_value = [dbo].spMFUpdateTable
			@MFTableName = N''' + @TableName
          + ''',
			@UpdateMethod = 1,
			@UserId = NULL,
			@MFModifiedDate = @MFLastUpdate,
			@ObjIDs = NULL,
			@Update_IDOut = @Update_IDOut output,
			@ProcessBatch_ID = @ProcessBatch_ID output,
			@Debug = @Debug
			';

    EXEC [sys].[sp_executesql]
        @SQL,
        @Params,
        @return_Value = @return_Value OUTPUT,
        @TableName = @TableName,
        @debug = @debug,
        @Update_IDOut = @Update_IDOut OUTPUT,
        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
		@MFLastUpdate = @MFLastUpdate output;

    IF @debug > 9
        RAISERROR('Proc: %s Step: %s Table: %s', 10, 1, @procedureName, @procedureStep, @TableName);

    --    SELECT  @return_Value;
    SELECT
        @Params = N'@LastModified datetime output';
    SELECT
        @SQL
        = N'
SELECT @LastModified  = MAX(isnull(' + QUOTENAME(@lastModifiedColumn) + ',0)) FROM dbo.' + QUOTENAME(@TableName)
          + '		
			';

    EXECUTE [sys].[sp_executesql]
        @SQL,
        @Params,
        @LastModified = @LastModified OUTPUT;

    SELECT
        @Return_LastModified = @LastModified;
    --    SELECT  @Return_LastModified = DATEADD(hour,-(DATEDIFF(hour,GETDATE(),GETUTCDATE())) ,@LastModified);

    SET @procedureStep = 'Update: ' + @TableName + ''
    SET @LogText = 'Update : '+ @TableName + ':Update Method ' + CAST(@UpdateMethod AS VARCHAR(2));
    SET @LogStatus = 'Completed'; --- Error , in Progress, Start, End, Completed  

    EXECUTE @return_Value = [dbo].[spMFProcessBatch_Upsert]
        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = @LogType,
        @LogText = @LogText,
        @LogStatus = @LogStatus,
        @debug = @debug;


    SET @procedureStep = 'Update';
    SET @LogTypeDetail = 'Status';
    SET @LogStatusDetail = 'Completed';
    SET @LogTextDetail = ' From '+ CAST(@MFLastUpdate AS VARCHAR(25)) + ' to ' + CAST(@LastModified AS VARCHAR(25));
    SET @LogColumnName = 'LastModified';
    SET @LogColumnValue = CONVERT(VARCHAR(30), GETDATE(), 120);

    SET @StartTime = GETUTCDATE();

    EXECUTE @return_Value = [dbo].[spMFProcessBatchDetail_Insert]
        @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = @LogTypeDetail,
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatusDetail,
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = @LogColumnName,
        @ColumnValue = @LogColumnValue,
        @Update_ID = @Update_IDOut,
        @LogProcedureName = @procedureName,
        @LogProcedureStep = @procedureStep,
        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT OUTPUT,
        @debug = @debug;

    RETURN 1;

GO



