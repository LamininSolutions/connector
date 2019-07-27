
/*
Context Menu 
Test Procedures
*/

/* the following test context menu procedure will demonstrate:
a) Action type  1 (procedure without input parameters)
b) can be used for both synchronous and unsyncronous actions, use asynchronous for long running procedures
c) setup messages for user in Context menu window
d) logging & updating the message table
e) logging the batch process

Example uses: 
- trigger external import
- update process a batch run
- perform a validation or matching routine
- send database mail for all objects in a certain state

*/




PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[custom].[DoCMAction]';
GO
SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'custom'
  , @ObjectName = N'DoCMAction'		-- nvarchar(100)
  , @Object_Release = '4.1.5.42'	-- varchar(50)
  , @UpdateFlag = 2;				-- smallint

GO

/*
CHANGE HISTORY
--------------
2017-06-21	ACilliers  - Add RowCount based on MFSQL Process Batch in Class Table, if column exists
					  - remove datatype comments
					  - format sql text
					  - add @ProcessType constant
					  - reset InProcessRunning if error occured

2017-07-16 LCilliers - Add send email when process is asynchronous
2018-7-16				Update messaging with latest procs

*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'DoCMAction' --name of procedure
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
CREATE PROCEDURE [Custom].[DoCMAction]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO



ALTER PROCEDURE [Custom].[DoCMAction]
	@ID INT, @OutPut VARCHAR(4000) OUTPUT, @Debug SMALLINT = 0
AS
	BEGIN
		BEGIN TRY

			SET @OutPut = 'Process Start Time: ' + CAST(GETDATE() AS VARCHAR(50)); --- set custom process start message for user

			-- Setting Params

			DECLARE
				@ProcessBatch_ID INT
			  , @procedureName	 NVARCHAR(128) = 'ContMenu.DoCMAction'
			  , @ProcedureStep	 NVARCHAR(128)
			  , @StartTime		 DATETIME
			  , @Return_Value	 INT
			  , @ProcessType	 NVARCHAR(50)  = N'Syncronize metadata';

			BEGIN

				--Updating MFContextMenu to show that process is still running   

				UPDATE	[dbo].[MFContextMenu]
				SET		[MFContextMenu].[IsProcessRunning] = 1
				WHERE	[MFContextMenu].[ID] = @ID;

				--Logging start of process batch 

				EXEC [dbo].[spMFProcessBatch_Upsert]
					@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
				  , @ProcessType = @ProcessType
				  , @LogType = N'Message'
				  , @LogText = @OutPut
				  , @LogStatus = N'Started'
				  , @debug = 0;

				SET @ProcedureStep = 'Metadata Syncronization ';
				SET @StartTime = GETDATE();

				EXEC [dbo].[spMFProcessBatchDetail_Insert]
					@ProcessBatch_ID = @ProcessBatch_ID
				  , @LogType = N'Message'
				  , @LogText = @OutPut
				  , @LogStatus = N'In Progress'
				  , @StartTime = @StartTime
				  , @MFTableName = NULL
				  , @Validation_ID = NULL
				  , @ColumnName = NULL
				  , @ColumnValue = NULL
				  , @Update_ID = NULL
				  , @LogProcedureName = @procedureName
				  , @LogProcedureStep = @ProcedureStep
				  , @debug = 0;



			END;

			--- start of custom process for the action, this example updates perform metadata synchronization

			BEGIN

				EXEC @Return_Value = [dbo].[spMFSynchronizeMetadata]
					@Debug = @Debug, @ProcessBatch_ID = @ProcessBatch_ID;

	
			END;

			-- set custom message to user

--			SET @OutPut = @OutPut + ' Process End Time= ' + CAST(GETDATE() AS VARCHAR(50));


			BEGIN

				-- reset process running in Context Menu

				-- logging end of process batch


				EXEC [dbo].[spMFProcessBatch_Upsert]
					@ProcessBatch_ID = @ProcessBatch_ID
				  , @ProcessType = @ProcessType
				  , @LogType = N'Message'
				  , @LogText = @OutPut
				  , @LogStatus = N'Completed'
				  , @debug = 0;

				SET @ProcedureStep = 'End Metadata synchronization';
				SET @StartTime = GETDATE();

				EXEC [dbo].[spMFProcessBatchDetail_Insert]
					@ProcessBatch_ID = @ProcessBatch_ID
				  , @LogType = N'Message'
				  , @LogText = @OutPut
				  , @LogStatus = N'Success'
				  , @StartTime = @StartTime
				  , @MFTableName = NULL
				  , @Validation_ID = NULL
				  , @ColumnName = NULL
				  , @ColumnValue = NULL
				  , @Update_ID = NULL
				  , @LogProcedureName = @procedureName
				  , @LogProcedureStep = @ProcedureStep
				  , @debug = 0;


			END;

			-- format message for display in context menu


				-- send email if async process


			IF	(	SELECT	[mcm].[ISAsync]
					FROM	[dbo].[MFContextMenu] AS [mcm]
					WHERE	[ID] = @ID
				) = 1
				BEGIN
					EXEC [dbo].[spMFProcessBatch_EMail] @ProcessBatch_ID = @ProcessBatch_ID;
				END;

			-- set up message for M-Files feedback
	
DECLARE @MessageOUT NVARCHAR(4000),
        @MessageForMFilesOUT NVARCHAR(4000),
        @EMailHTMLBodyOUT NVARCHAR(MAX),
        @RecordCount INT,
        @UserID INT,
        @ClassTableList NVARCHAR(100),
        @MessageTitle NVARCHAR(100);

SET @MessageOut = @OutPut

EXEC [dbo].[spMFResultMessageForUI] @Processbatch_ID = @ProcessBatch_ID, -- int
                                    @Detaillevel = 0,     -- int
                                    @MessageOUT = @MessageOUT OUTPUT,                         -- nvarchar(4000)
                                    @MessageForMFilesOUT = @MessageForMFilesOUT OUTPUT,       -- nvarchar(4000)
                                    @GetEmailContent = 0, -- bit
                                    @EMailHTMLBodyOUT = @EMailHTMLBodyOUT OUTPUT,             -- nvarchar(max)
                                    @RecordCount = @RecordCount OUTPUT,                       -- int
                                    @UserID = @UserID OUTPUT,                                 -- int
                                    @ClassTableList = @ClassTableList OUTPUT,                 -- nvarchar(100)
                                    @MessageTitle = @MessageTitle OUTPUT                      -- nvarchar(100)

			

	

			UPDATE	[dbo].[MFContextMenu]
			SET		[MFContextMenu].[IsProcessRunning] = 0
			WHERE	[MFContextMenu].[ID] = @ID;

			RETURN 1;

		END TRY
		BEGIN CATCH

			UPDATE	[dbo].[MFContextMenu]
			SET		[MFContextMenu].[IsProcessRunning] = 0
			WHERE	[MFContextMenu].[ID] = @ID;

			SET @OutPut = 'Error:';
			SET @OutPut = @OutPut + ( SELECT	ERROR_MESSAGE());

		END CATCH;
	END;


GO
