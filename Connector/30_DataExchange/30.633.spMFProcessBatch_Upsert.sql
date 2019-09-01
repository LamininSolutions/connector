PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFProcessBatch_Upsert]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFProcessBatch_Upsert' -- nvarchar(100)
                                    ,@Object_Release = '4.1.8.47'             -- varchar(50)
                                    ,@UpdateFlag = 2;                         -- smallint
GO

/*
2018-08-01	lc		add debugging
2019-1-21	LC		remove unnecessary log entry for dbcc
2019-1-26	LC		Resolve issues with commits
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFProcessBatch_Upsert' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFProcessBatch_Upsert]
AS
BEGIN
    SELECT 'created, but not implemented yet.';
END;
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFProcessBatch_Upsert]
(
    @ProcessBatch_ID INT OUTPUT
   ,@ProcessType NVARCHAR(50) = NULL -- (Debug | | Upsert | Create |Setup |Error)
   ,@LogType NVARCHAR(50) = NULL     -- (Start | End)
   ,@LogText NVARCHAR(4000) = NULL   -- text string for updating user
   ,@LogStatus NVARCHAR(50) = NULL   --(Initiate | In Progress | Partial | Completed | Error)
   ,@debug SMALLINT = 0              -- 
)
AS
/*rST**************************************************************************

=======================
spMFProcessBatch_Upsert
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @ProcessType nvarchar(50)
    fixme description
  @LogType nvarchar(50)
    fixme description
  @LogText nvarchar(4000)
    fixme description
  @LogStatus nvarchar(50)
    fixme description
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
 /*******************************************************************************

  **
  ** Author:          leroux@lamininsolutions.com
  ** Date:            2016-08-27
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
    add settings option to exclude procedure from executing detail logging
	2018-10-31	LC improve debugging comments
  ******************************************************************************/

/*
  DECLARE @ProcessBatch_ID INT = 0;
  
  EXEC [dbo].[spMFProcessBatch_Upsert]

      @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
    , @ProcessType = 'Test'
    , @LogText = 'Testing'
    , @LogStatus = 'Start'
    , @debug = 1
  
	select * from MFProcessBatch where ProcessBatch_ID = @ProcessBatch_ID

	WAITFOR DELAY '00:00:02'

  EXEC [dbo].[spMFProcessBatch_Upsert]

      @ProcessBatch_ID = @ProcessBatch_ID
    , @ProcessType = 'Test'
    , @LogText = 'Testing Complete'
    , @LogStatus = 'Complete'
    , @debug = 1
  
	select * from MFProcessBatch where ProcessBatch_ID = @ProcessBatch_ID


  */
SET NOCOUNT ON;

SET XACT_ABORT ON;

DECLARE @trancount INT;

-------------------------------------------------------------
-- Logging Variables
-------------------------------------------------------------
DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFProcessBatch_Upsert';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DebugText AS NVARCHAR(256) = '';
DECLARE @DetailLoggingIsActive SMALLINT = 0;
DECLARE @rowcount AS INT = 0;

/*************************************************************************************
	PARAMETER VALIDATION
*************************************************************************************/
SET @ProcedureStep = 'ProcessBatch input param';

IF @ProcessBatch_ID = 0
    SET @ProcessBatch_ID = NULL;

SELECT @DetailLoggingIsActive = CAST([Value] AS INT)
FROM [dbo].[MFSettings]
WHERE [Name] = 'App_DetailLogging';

IF (
       @ProcessBatch_ID <> 0
       AND NOT EXISTS
(
    SELECT 1
    FROM [dbo].[MFProcessBatch]
    WHERE [ProcessBatch_ID] = @ProcessBatch_ID
)
   )
BEGIN
    SET @LogText
        = 'ProcessBatch_ID [' + ISNULL(CAST(@ProcessBatch_ID AS VARCHAR(20)), '(null)')
          + '] not found - process aborting...';
    SET @LogStatus = 'failed';

    IF @debug > 0
    BEGIN
        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    RETURN -1;
END;

--unable TO validate

--SET @DebugText = ' %i';
--SET @DebugText = @DefaultDebugText + @DebugText;
--SET @ProcedureStep = 'Transaction Count';

--IF @debug > 0
--BEGIN
--    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @trancount);
--END;

IF @DetailLoggingIsActive	= 1
BEGIN

-------------------------------------------------------------
-- Set default logtype
-------------------------------------------------------------
SET @LogType = CASE WHEN @LogStatus LIKE 'Complete%' THEN 'END'
WHEN @LogStatus LIKE 'Error%' THEN 'FAIL'
WHEN @LogType IS NULL  THEN 'Debug'
ELSE @LogType
END

/*************************************************************************************
	CREATE NEW BATCH ID
*************************************************************************************/


SET @trancount = @@TranCount;

--IF @trancount > 0
--GOTO EXITPROC;

IF @Debug > 0
SELECT @trancount AS processBatch_TranCount_New;

--IF @trancount > 0
--SAVE TRANSACTION [spMFProcessBatch_Upsert]
--    DBCC OPENTRAN;
--COMMIT;
;



IF @ProcessBatch_ID IS NULL
   
BEGIN
--BEGIN TRAN
    SET @ProcedureStep = 'Create log';

    INSERT INTO [dbo].[MFProcessBatch]
    (
        [ProcessType]
       ,[LogType]
       ,[LogText]
       ,[Status]
    )
    VALUES
    (@ProcessType, @LogType, @LogText, @LogStatus);

    SET @ProcessBatch_ID = SCOPE_IDENTITY();

    --IF @debug > 0
    --BEGIN
    --    SET @DebugText = @DefaultDebugText + ' ProcessBatchID: %i';

    --    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ProcessBatch_ID);
    --END;

--	COMMIT
    
 --   GOTO EXITPROC;

END;

--CREATE NEW BATCH ID

/*************************************************************************************
	UPDATE EXISTING BATCH ID
*************************************************************************************/

IF @ProcessBatch_ID IS NOT NULL
  BEGIN
  
--      BEGIN TRAN;
           SET @ProcedureStep = 'Updated MFProcessBatch';
           SET @DebugText = ' ID: %i';
           SET @DebugText = @DefaultDebugText + @DebugText;

           IF @debug > 0
           BEGIN

               SELECT @LogType     AS [logtype]
                     ,@LogText     AS [logtext]
                     ,@ProcessType AS [ProcessType]
                     ,@LogStatus   AS [logstatus];

               RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ProcessBatch_ID);
           END;

		   IF @Debug > 0
SELECT @trancount AS processBatch_TranCount_Update;

--    IF @@TranCount > 0
--	SAVE TRANSACTION [spMFProcessBatch_Upsert]
--       COMMIT;


UPDATE [dbo].[MFProcessBatch]
SET [ProcessType] = CASE
                        WHEN @ProcessType IS NULL THEN
                            [ProcessType]
                        ELSE
                            @ProcessType
                    END
   ,[LogType] = CASE
                    WHEN @LogType IS NULL THEN
                        [LogType]
                    ELSE
                        @LogType
                END
   ,[LogText] = CASE
                    WHEN @LogText IS NULL THEN
                        [LogText]
                    ELSE
                        @LogText
                END
   ,[Status] = CASE
                   WHEN @LogStatus IS NULL THEN
                       'Completed'
                   ELSE
                       @LogStatus
               END
   ,[DurationSeconds] = DATEDIFF(ms, [CreatedOnUTC], GETUTCDATE()) / CONVERT(DECIMAL(18, 3), 1000)
FROM [dbo].[MFProcessBatch]
WHERE [ProcessBatch_ID] = @ProcessBatch_ID;


END;

/*	
		       SELECT 
        [ProcessType] = CASE
                                WHEN @ProcessType IS NULL THEN
                                    [ProcessType]
                                ELSE
                                    @ProcessType
                            END
           ,[LogType] = CASE
                            WHEN @LogType IS NULL THEN
                                [LogType]
                            ELSE
                                @LogType
                        END
           ,[LogText] = CASE
                            WHEN @LogText IS NULL THEN
                                [LogText]
                            ELSE
                                @LogText
                        END
           ,[Status] = CASE
                           WHEN @LogStatus IS NULL THEN
                               'Completed'
                           ELSE
                               @LogStatus
                       END
           ,[DurationSeconds] = DATEDIFF(ms, [CreatedOnUTC], GETUTCDATE()) / CONVERT(DECIMAL(18, 3), 1000)
        FROM [dbo].[MFProcessBatch]
        WHERE [ProcessBatch_ID] = @ProcessBatch_ID;
       
	   
SET @rowcount = @@RowCount;
SET @rowcount = ISNULL(@rowcount, 0);
SET @ProcedureStep = 'Processbatch updated with ' + @LogText;
SET @DebugText = '';
SET @DebugText = @DefaultDebugText + @DebugText;

IF @debug > 0
BEGIN
    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
END;
*/
--SELECT @trancount = @@TranCount;
--IF @trancount = 0
--Begin
----SAVE TRANSACTION [spMFProcessBatch_Upsert]


/*
EXITPROC:
SET @ProcedureStep = 'Commit log';
SET @DebugText = '';
SET @DebugText = @DefaultDebugText + @DebugText;

IF @debug > 0
BEGIN
    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
END;



DECLARE @xstate INT;

SELECT @xstate = XACT_STATE();

--   SELECT @xstate AS exactstate
RETURN 1;

*/

END --no detail logging

RETURN 1

GO