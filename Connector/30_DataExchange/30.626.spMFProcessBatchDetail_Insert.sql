
go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFProcessBatchDetail_Insert]';
go

SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
								   , @ObjectName = N'spMFProcessBatchDetail_Insert'
								   , @Object_Release = '4.2.8.47'
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
AS /*******************************************************************************

  **
  ** Author:          leroux@lamininsolutions.com
  ** Date:            2016-08-27
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  add settings option to exclude procedure from executing detail logging
	2017-06-30	AC			- Add @ProcessBatchDetail_ID as param to allow for calculation of duration if provided based on input of a specific ID
								Procedure will use input to overide the passed int StartDate and get start date from the ID provided
								This will allow calculation of @DureationInSecords seconds on a detail proc level
2018-10-31	lc	update logging text								
2019-1-27	LC	exclude MFUserMessage table from any logging
						
  ******************************************************************************/

  /*

  */

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
								 , @LogProcedureName + ': ' + @LogProcedureStep
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
                                    
                                    SET @DebugText = @DefaultDebugText + ': ' + @LogText + ' ColumnName: %s ColumnValue: %s '	
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


