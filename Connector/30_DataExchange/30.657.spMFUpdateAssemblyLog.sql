
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateAssemblyLog]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFUpdateAssemblyLog' -- nvarchar(100)
  , @Object_Release = '4.9.28.73'
  , @UpdateFlag = 2

GO

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFUpdateAssemblyLog' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateAssemblyLog]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFUpdateAssemblyLog]
	(
		@ProcessBatch_ID INT	  = NULL OUTPUT
	  , @Debug			 SMALLINT = 0
	)
AS
/*rST**************************************************************************

=====================
spMFUpdateAssemblyLog
=====================

THIS PROCEDURE IS UNDER DEVELOPMENT

Return
  - 1 = Success
  - -1 = Error
Parameters  
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To process the logging of the methods in the assembly for a specific procedure

The assembly will call this procedure to update the logging statistics in the MFAssemblyLog table.

Additional Info
===============


.. code:: sql

      EXEC spMFUpdateAssemblyLog 

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------

2022-01-04  DEV        Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


BEGIN
		SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Assembly Logging')

		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFUpdateAssemblyLog';
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
		  , @MFTableName = null
		  , @Validation_ID = null
		  , @ColumnName = NULL
		  , @ColumnValue = NULL
		  , @Update_ID = null
		  , @LogProcedureName = @ProcedureName
		  , @LogProcedureStep = @ProcedureStep
		, @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT 
		  , @debug = 0


		BEGIN TRY
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			SET @DebugText = 'Start logging'
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Logging update'
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END


			-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'
			Set @LogStatus = 'Completed'
			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   

			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
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
			  , @MFTableName = null
			  , @Validation_ID = null
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = null
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0
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
			  , @MFTableName = null
			  , @Validation_ID = null
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = null
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN -1
		END CATCH

	END

GO
