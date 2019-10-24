PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[custom].[DoCMAsyncAction]';
GO
SET NOCOUNT ON
GO
/*
SAMPLE OF PROCEDURE TO ILLUSTRATE LOGGING AND MESSAGING
*/
IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'DoCMAsyncAction' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'custom'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [custom].[DoCMAsyncAction]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [custom].[DoCMAsyncAction]
	( @ID INT
		,@ProcessBatch_ID INT	  = NULL OUTPUT
	   , @Output NVARCHAR(1000) = NULL OUTPUT
	  , @WriteToMFiles bit = 1 --default (No)
	  , @Debug			 SMALLINT = 0
	)
AS
	BEGIN
		SET NOCOUNT ON;

		-------------------------------------------------------------
    -- VARIABLES: CONTEXT MENU
    -------------------------------------------------------------
			DECLARE
				@IsAsync		  BIT			 
			  , @IsProcessRunning BIT
			  , @ContextMenu_ID	  INT
			  , @ActionName		  NVARCHAR(250)
			  , @Action			  NVARCHAR(1000) = 'Custom.DoCMAsyncAction'
			  ,	@Last_Executed_By int
			,@Last_Executed_Date datetime
			,@ActionUser NVARCHAR(100)
			,@ActionUserEmail NVARCHAR(100)

       -- Get Values from contect Menu
            SELECT
                    @IsProcessRunning   = [IsProcessRunning],
                    @ContextMenu_ID     = [cm].[ID],
                    @ActionName         = [ActionName],
                    @IsAsync            = [ISAsync],
                    @Last_Executed_By   = ISNULL([mla].[MFID], 0),
                    @Last_Executed_Date = [Last_Executed_Date],
					@ActionUser			= mla2.[UserName],
                    @ActionUserEmail       = mla2.[EmailAddress]
            FROM
                    [dbo].[MFContextMenu]  AS [cm]
                LEFT JOIN
                    [dbo].[MFLoginAccount] AS [mla]
                        ON [cm].[Last_Executed_By] = [mla].[MFID]
				LEFT JOIN [dbo].[MFLoginAccount] AS [mla2]
						ON [cm].[ActionUser_ID] = [mla2].mfid
            WHERE
                    [Action] = @Action;



		IF @IsProcessRunning = 1
		BEGIN
			SET @Output = 'Process is currently running, please try again later.'
			IF @debug > 0 
				PRINT @Output
			RETURN
		END
	

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = 'MFCustomer'
		DECLARE @ProcessType AS NVARCHAR(50) ;

		SET @ProcessType = 'Update Class Table'
		
		-------------------------------------------------------------
		-- CONSTATNS: MFSQL Global 
		-------------------------------------------------------------
		DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1
		DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0
		DECLARE @Process_ID_1_Update TINYINT = 1
		DECLARE @Process_ID_6_ObjIDs TINYINT = 6 --marks records for refresh from M-Files by objID vs. in bulk
		DECLARE @Process_ID_9_BatchUpdate TINYINT = 9 --marks records previously set as 1 to 9 and update in batches of 250
		DECLARE @Process_ID_Delete_ObjIDs INT = -1 --marks records for deletion
		DECLARE @Process_ID_2_SyncError TINYINT = 2
		DECLARE @ProcessBatchSize INT = 250

		-------------------------------------------------------------
		-- VARIABLES: MFSQL Processing
		-------------------------------------------------------------
		DECLARE @Update_ID INT
		DECLARE @MFLastModified DATETIME
		DECLARE @Validation_ID int

		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'customer.DoCMAsyncAction';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

		-------------------------------------------------------------
		-- VARIABLES: LOGGING
		-------------------------------------------------------------
		DECLARE @LogType AS NVARCHAR(50) = 'Status'
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) = 'Started'

		DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
		DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL

		DECLARE @LogColumnName AS NVARCHAR(128) = NULL
		DECLARE @LogColumnValue AS NVARCHAR(256) = NULL

		DECLARE @count INT = 0;
		DECLARE @Now AS DATETIME = GETDATE();
		DECLARE @StartTime AS DATETIME = GETUTCDATE();
		DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
		DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

		-------------------------------------------------------------
		-- VARIABLES: DYNAMIC SQL
		-------------------------------------------------------------
		DECLARE @sql NVARCHAR(MAX) = N''
		DECLARE @sqlParam NVARCHAR(MAX) = N''


		-------------------------------------------------------------
		-- INTIALIZE PROCESS BATCH
		-------------------------------------------------------------
		SET @ProcedureStep = 'Start Logging'

		SET @LogText = 'Processing ' + @ProcedureName

		EXEC [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
		  , @ProcessType = @ProcessType
		  , @LogType = N'Status'
		  , @LogText = @LogText
		  , @LogStatus = N'In Progress'
		  , @debug = @Debug


		EXEC [dbo].[spMFProcessBatchDetail_Insert]
			@ProcessBatch_ID = @ProcessBatch_ID
		  , @LogType = N'Debug'
		  , @LogText = @ProcessType
		  , @LogStatus = N'Started'
		  , @StartTime = @StartTime
		  , @MFTableName = @MFTableName
		  , @Validation_ID = @Validation_ID
		  , @ColumnName = NULL
		  , @ColumnValue = NULL
		  , @Update_ID = @Update_ID
		  , @LogProcedureName = @ProcedureName
		  , @LogProcedureStep = @ProcedureStep
			-- , @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT --v38
		  , @debug = 0


		BEGIN TRY
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			-------------------------------------------------------------
			-- Updating MFContextMenu to show that process is still running 
			-------------------------------------------------------------   
			UPDATE [dbo].[MFContextMenu]
			SET	   [IsProcessRunning] = 1
			WHERE  [ID] = @ContextMenu_ID


				-------------------------------------------------------------
			    -- Insert new record in Table: from SQL to M-Files
				-- using process batch and MFSQL Message
			    -------------------------------------------------------------
				SET @msg = 'MFSQL added'
				INSERT INTO [dbo].[MFCustomer] ( 
											    [Address_Line_1]										   , [City]													   , [Country_ID]
											   , [Customer_Name]
											   , [Stateprovince]
											   , [Telephone_Number]
											   , [Zippostal_Code]
											  , [Process_ID]
											   , [MFSQL_Message]
											   ,[MFSQL_Process_Batch]
											   )
				VALUES ('23 Ancor Lane'
						,'Portsville'
						,(SELECT [MFID_ValueListItems] FROM MFvwCountry WHERE [Name_ValueListItems] = 'USA')
						,'Excutive Systems Inc'
						,'FL'
						,'0823400234'
						,'08943'
						,1
						,@Msg
						,@ProcessBatch_ID
					   )

					   SET @rowcount = @@ROWCOUNT

					   	-------------------------------------------------------------
					       -- Update M-Files
					       -------------------------------------------------------------

					   EXEC @return_value = [dbo].[spMFUpdateTable]
					   	@MFTableName = @MFTableName							
					     , @UpdateMethod = @UpdateMethod_0_MFSQLToMFiles							
					     , @Update_IDOut = @Update_ID OUTPUT		
					     , @ProcessBatch_ID = @ProcessBatch_ID 	

			-------------------------------------------------------------
		    -- GET COUNT VALUES FOR THE CLASS 
		    -------------------------------------------------------------			   
			SET @ProcedureStep = 'Get Record Counts'

	DECLARE @LogTextDetailOUT NVARCHAR(4000)
		  , @LogStatusDetailOUT NVARCHAR(50);

	EXEC [dbo].[spMFLogProcessSummaryForClassTable] @ProcessBatch_ID = @ProcessBatch_ID
												  , @MFTableName = @MFTableName
												  , @InsertCount = NULL	
												  , @UpdateCount = @rowcount
												  , @LogProcedureName = @ProcedureName
												  , @LogProcedureStep = @ProcedureStep
												  , @LogTextDetailOUT = @LogTextDetailOUT OUTPUT
												  , @LogStatusDetailOUT = @LogStatusDetailOUT OUTPUT
												  , @debug = @debug


	SET @LogText = @LogTextDetailOUT
	SET @LogStatus = @LogStatusDetailOUT
			-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'

			-------------------------------------------------------------
			-- Updating MFContextMenu to show that process is completed
			-------------------------------------------------------------   

			UPDATE [dbo].[MFContextMenu]
			SET	   [IsProcessRunning] = 0
			WHERE  [ID] = @ContextMenu_ID
	

			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   

			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			  , @ProcessType = @ProcessType
			  , @LogType = N'Message'
			  , @LogText = @LogText
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Debug'
			  , @LogText = @ProcessType
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			  -------------------------------------------------------------
			-- Send E-Mail Notification | PRODUCE OUTPUT FOR CONTEXT MENU
			-------------------------------------------------------------
			IF (@rowcount > 0)
			BEGIN
				IF (@IsAsync = 1)
					BEGIN
						SET @ProcedureStep = 'EXEC [spMFProcessBatch_EMail]'
						EXEC [dbo].[spMFProcessBatch_EMail]
							@ProcessBatch_ID = @ProcessBatch_ID
						  , @RecipientEmail = @ActionUserEmail
						  , @RecipientFromMFSettingName = 'DefaultIntegrationEmailRecipients'
						  , @ContextMenu_ID = @ContextMenu_ID
					END
				ELSE
					BEGIN
						SET @ProcedureStep = 'EXEC [spMFResultMessageForUI]'
						EXEC [dbo].[spMFResultMessageForUI]
							@Processbatch_ID = @ProcessBatch_ID
						  , @MessageOUT = @Output OUTPUT
						  , @GetEmailContent = 0
					END
					end
			RETURN 1
		END TRY
		BEGIN CATCH
			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			  , @ProcessType = @ProcessType
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN -1
		END CATCH

	END

GO
