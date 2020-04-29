
go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFProcessBatchDetail_Insert]';
go

SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
								   , @ObjectName = N'spMFProcessBatchDetail_Insert'
								   , @Object_Release = '4.6.15.57'
								   , @UpdateFlag = 2
	  go

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFProcessBatchDetail_Insert'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
go

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFProcessBatchDetail_Insert]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFProcessBatchDetail_Insert]
      (
        @ProcessBatch_ID INT
      , @LogType NVARCHAR(50) = N'Info' -- (Debug | Info | Warning | Error)
      , @LogText NVARCHAR(4000) = NULL
      , @LogStatus NVARCHAR(50) = NULL
      , @StartTime DATETIME
      , @MFTableName NVARCHAR(128) = NULL
      , @Validation_ID INT = NULL
      , @ColumnName NVARCHAR(128) = NULL
      , @ColumnValue NVARCHAR(256) = NULL
      , @Update_ID INT = NULL
      , @LogProcedureName NVARCHAR(128) = NULL
      , @LogProcedureStep NVARCHAR(128) = NULL
	  , @ProcessBatchDetail_ID INT = NULL OUTPUT
      , @debug TINYINT = 0  -- 101 for EpicorEnt Test Mode
												
      )
AS
/*rST**************************************************************************

=============================
spMFProcessBatchDetail_Insert
=============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch\_ID int (optional)
    Referencing the ID of the ProcessBatch logging table
  @LogType nvarchar(50)
    - Type of logging:
    - Status
    - Error
    - Message
  @LogText nvarchar(4000)
    Include inputs or outputs of logging step
  @LogStatus nvarchar(50)
    - Indicate status of log:
    - Start
    - In Progress
    - Done
  @StartTime datetime
    - Set to GETUTCDATE()
  @MFTableName nvarchar(128)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @Validation\_ID int
    - Use this for a custom table with validation errors
  @ColumnName nvarchar(128)
    - Show the name of the column for the value in ColumnValue
  @ColumnValue nvarchar(256)
    - Show value such as count of records / count of errors etc
  @Update\_ID int
    - Set to Update_ID output from from the calling procedure
  @LogProcedureName nvarchar(128)
    - Set to the name of the procedure that is currently running
  @LogProcedureStep nvarchar(128)
    - Set to a description of the procedure step that is currently being executed
  @ProcessBatchDetail\_ID int (output)
    Add ProcessBatchDetail_ID as parameter to allow for calculation of duration if provided based on input of a specific ID. Procedure will use input to override the passed int StartDate and get start date from the ID provided. This will allow calculation of DurationInSecords seconds on a detail procedure level
  @debug tinyint
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Add a record to the MFProcessBatchDetail table. This procedure is executed for specific procedure steps.

Additional Info
===============

The columns to be populated will depend on the nature of the sub procedure that is monitored.

Examples
========

.. code:: sql

    SET @ProcedureStep = 'Prepare Table';
    SET @LogTypeDetail = 'Status';
    SET @LogStatusDetail = 'Start';
    SET @LogTextDetail = 'For UpdateMethod ' + CAST(@UpdateMethod AS VARCHAR(10));
    SET @LogColumnName = '';
    SET @LogColumnValue = '';

    EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                                  @ProcessBatch_ID = @ProcessBatch_ID
                                , @LogType = @LogTypeDetail
                                , @LogText = @LogTextDetail
                                , @LogStatus = @LogStatusDetail
                                , @StartTime = @StartTime
                                , @MFTableName = @MFTableName
                                , @Validation_ID = @Validation_ID
                                , @ColumnName = @LogColumnName
                                , @ColumnValue = @LogColumnValue
                                , @Update_ID = @Update_ID
                                , @LogProcedureName = @ProcedureName
                                , @LogProcedureStep = @ProcedureStep
                                , @ProcessBatchDetail_ID =   @ProcessBatchDetail_ID output
                                , @debug = @debug

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-03-12  LC         Improve default wording of text
2019-08-30  JC         Added documentation
2019-01-27  LC         Exclude MFUserMessage table from any logging
2018-10-31  LC         Update logging text
2017-06-30  AC         This will allow calculation of @DureationInSecords seconds on a detail proc level
2017-06-30  AC         Procedure will use input to overide the passed int StartDate and get start date from the ID provided
2017-06-30  AC         Add @ProcessBatchDetail_ID as param to allow for calculation of duration if provided based on input of a specific ID
==========  =========  ========================================================

**rST*************************************************************************/
      BEGIN

            SET NOCOUNT ON;
            SET XACT_ABORT ON;
	 -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
            DECLARE @ProcedureName AS NVARCHAR(128) = 'MFProcessBatchDetail_Insert';
            DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
            DECLARE @DebugText AS NVARCHAR(256) = ''
            DECLARE @DetailLoggingIsActive SMALLINT = 0;
		

            DECLARE @DurationSeconds AS FLOAT;

            DECLARE @rowcount AS INT = 0;
            DECLARE @sql NVARCHAR(MAX) = N''
            DECLARE @sqlParam NVARCHAR(MAX) = N''


            SELECT  @DetailLoggingIsActive = CAST([MFSettings].[Value] AS INT)
            FROM    [dbo].[MFSettings]
            WHERE   [MFSettings].[Name] = 'App_DetailLogging'

  

            BEGIN TRY

					 
                  IF ( @DetailLoggingIsActive = 1 ) AND (ISNULL(@MFTableName,'') <> 'MFUserMessages')
                     BEGIN

                           --IF @debug > 0
                           --   BEGIN
                           --         SET @DebugText = @DefaultDebugText + ' ColumnName: %s ColumnValue: %s '	
                           --         RAISERROR(@DebugText,10,1,@LogProcedureName,@LogProcedureStep, @ColumnName,@ColumnValue);
                           --   END
			--	SELECT @StartTime
							DECLARE @CreatedOnUTC DATETIME
							SELECT @CreatedOnUTC = [CreatedOnUTC]
							FROM [dbo].[MFProcessBatchDetail]
							WHERE [ProcessBatchDetail_ID] = @ProcessBatchDetail_ID

							SET @DurationSeconds = DATEDIFF(MS, COALESCE(@CreatedOnUTC,@StartTime,GETUTCDATE()), GETUTCDATE()) / CONVERT(DECIMAL(18,3),1000)
	
			
				
			--	SELECT @DurationSeconds
						DECLARE @ProcedureStep AS NVARCHAR(128) = ' MFProcessBatchDetail inserted ';
						INSERT [dbo].[MFProcessBatchDetail] (	[ProcessBatch_ID]
															  , [LogType]
															  , [ProcedureRef]
															  , [LogText]
															  , [Status]
															  , [DurationSeconds]
															  , [MFTableName]
															  , [Validation_ID]
															  , [ColumnName]
															  , [ColumnValue]
															  , [Update_ID]
															)
						VALUES (   @ProcessBatch_ID
								 , @LogType			-- LogType - nvarchar(50)
							--	 , @LogProcedureName + ': ' + @LogProcedureStep
                             , @LogProcedureName
								 , @LogText			-- LogText - nvarchar(4000)
								 , @LogStatus		-- Status - nvarchar(50)
								 , @DurationSeconds -- DurationSeconds - decimal
								 , @MFTableName
								 , @Validation_ID	-- Validation_ID - int
								 , @ColumnName		-- ColumnName - nvarchar(128)
								 , @ColumnValue		-- ColumnValue - nvarchar(256)
								 , @Update_ID
							   )

                           IF @debug > 0
                              BEGIN
                                    
                                    SET @DebugText = @DefaultDebugText + ': ' + @LogText + '  %s  %s '	
                                    RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep, @ColumnName, @ColumnValue)
                              END
  
                     END
					
                  SET NOCOUNT OFF;

	  

                  RETURN 1



            END TRY

            BEGIN CATCH
          -----------------------------------------------------------------------------
          -- INSERTING ERROR DETAILS INTO LOG TABLE
          -----------------------------------------------------------------------------
                  INSERT    INTO [dbo].[MFLog]
                            ( [SPName]
                            , [ProcedureStep]
                            , [ErrorNumber]
                            , [ErrorMessage]
                            , [ErrorProcedure]
                            , [ErrorState]
                            , [ErrorSeverity]
                            , [ErrorLine]
                            )
                  VALUES    ( @ProcedureName
                            , @ProcedureStep
                            , ERROR_NUMBER()
                            , ERROR_MESSAGE()
                            , ERROR_PROCEDURE()
                            , ERROR_STATE()
                            , ERROR_SEVERITY()
                            , ERROR_LINE()
                            );
		  
          -----------------------------------------------------------------------------
          -- DISPLAYING ERROR DETAILS
          -----------------------------------------------------------------------------
                  SELECT    ERROR_NUMBER() AS [ErrorNumber]
                          , ERROR_MESSAGE() AS [ErrorMessage]
                          , ERROR_PROCEDURE() AS [ErrorProcedure]
                          , ERROR_STATE() AS [ErrorState]
                          , ERROR_SEVERITY() AS [ErrorSeverity]
                          , ERROR_LINE() AS [ErrorLine]
                          , @ProcedureName AS [ProcedureName]
                          , @ProcedureStep AS [ProcedureStep]

                  RETURN 2
            END CATCH

              
      END
go


