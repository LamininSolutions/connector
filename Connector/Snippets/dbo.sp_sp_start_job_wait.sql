/*

	Checks if the given job name is running and if runing, waits for 
	given 'WaitTime' and checks again, in a loop.
	If the job is not running, this proc will start it!

	Once the given job completes execution, this stored procedure will exit
	with a return code for the the status of the job being watched

	Return Codes
	Failed		= 0
	Successful	= 1
	Cancelled	= 3

Example 1> 
DECLARE @RetStatus int
exec dbo.spMFStart_job_wait '','00:00:01',@RetStatus OUTPUT
select @RetStatus

Example 2>
exec dbo.spMFStart_job_wait 'zzzDBATest'
*/

IF ISNULL(OBJECT_ID('dbo.spMFStart_job_wait'), 0) = 0
	EXEC ( 'create procedure dbo.spMFStart_job_wait as print ''temporary procedure to hold location so we can use ALTER in the script''' )
GO

ALTER PROCEDURE [dbo].[spMFStart_job_wait]
	(
		@job_name			 sysname
	  , @WaitTime			 DATETIME = '00:00:05' -- this is parameter for check frequency
	  , @RunStatus INT	  = NULL OUTPUT
  	  , @RunOutcomeMessage NVARCHAR(4000)	  = NULL OUTPUT
	  , @Debug INT = 0

	)
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

	-- DECLARE @job_name	sysname
	DECLARE @job_id UNIQUEIDENTIFIER
	DECLARE @job_owner sysname
	DECLARE @return_value INT
	DECLARE @error INT


	--Createing TEMP TABLE
	CREATE TABLE [#xp_results]
		(
			[job_id]				UNIQUEIDENTIFIER NOT NULL
		  , [last_run_date]			INT				 NOT NULL
		  , [last_run_time]			INT				 NOT NULL
		  , [next_run_date]			INT				 NOT NULL
		  , [next_run_time]			INT				 NOT NULL
		  , [next_run_schedule_id]	INT				 NOT NULL
		  , [requested_to_run]		INT				 NOT NULL -- BOOL
		  , [request_source]		INT				 NOT NULL
		  , [request_source_id]		sysname			 COLLATE DATABASE_DEFAULT NULL
		  , [running]				INT				 NOT NULL -- BOOL
		  , [current_step]			INT				 NOT NULL
		  , [current_retry_attempt] INT				 NOT NULL
		  , [job_state]				INT				 NOT NULL
		)

	SELECT @job_id = [job_id]
	FROM   [msdb].[dbo].[sysjobs]
	WHERE  [name] = @job_name

	SELECT @job_owner = SUSER_SNAME()

	INSERT INTO [#xp_results]
	EXECUTE @return_value = [master].[sys].[xp_sqlagent_enum_jobs] 1, @job_owner, @job_id

	SET @error = @@ERROR
	IF @error <> 0 OR @return_value <> 0 
		GOTO ErrorHandler

	-- Start the job if the job is not running
	IF NOT EXISTS ( SELECT TOP 1 * FROM [#xp_results] WHERE [running] = 1 )
		EXEC @return_value = [msdb].[dbo].[sp_start_job] @job_name = @job_name

	SET @error = @@ERROR
	IF @error <> 0 OR @return_value <> 0 
		GOTO ErrorHandler	

	-- Give 2 sec for think time.
	WAITFOR DELAY '00:00:02'

	DELETE FROM [#xp_results]
	INSERT INTO [#xp_results]
	EXECUTE [master].[sys].[xp_sqlagent_enum_jobs] 1, @job_owner, @job_id
	SET @error = @@ERROR
	IF @error <> 0 OR @return_value <> 0 
		GOTO ErrorHandler

	WHILE EXISTS ( SELECT TOP 1 * FROM [#xp_results] WHERE [running] = 1 )
		BEGIN

			WAITFOR DELAY @WaitTime

			-- Information 
			RAISERROR('... still running', 0, 1)WITH NOWAIT

			DELETE FROM [#xp_results]

			INSERT INTO [#xp_results]
			EXECUTE [master].[sys].[xp_sqlagent_enum_jobs] 1
														 , @job_owner
														 , @job_id

		END


	DECLARE @insance_id INT
		,	@message NVARCHAR(4000)
		,	@run_datetime DATETIME	
		,   @run_duration VARCHAR(20)

	SELECT @insance_id = MAX(instance_id)
	FROM [msdb].[dbo].[sysjobhistory]
	WHERE [job_id] = @job_id
	AND [step_id] = 0

	SET @insance_id = ISNULL(@insance_id,-1)

	SELECT
		  @RunStatus	= [run_status]
		, @message		= [message]
		, @run_datetime = [msdb].[dbo].[agent_datetime]([run_date], [run_time])
		, @run_duration = STUFF(
							  STUFF(
								  REPLACE(STR([run_duration], 6, 0), ' ', '0'), 3
								, 0, ':'), 6, 0, ':')
	FROM  [msdb].[dbo].[sysjobhistory]
	WHERE [job_id] = @job_id AND [instance_id] = @insance_id

	SET @RunOutcomeMessage = ISNULL(@message,'') + '; Run Date: ' + CONVERT(VARCHAR(30),ISNULL(@run_datetime,'')) + '; Duration: ' + ISNULL(@run_duration,'')

	RAISERROR('... %s', 0, 1,@RunOutcomeMessage)WITH NOWAIT

	RETURN @RunStatus

ErrorHandler:
BEGIN
	SET @RunStatus = -1
				 RAISERROR(
					 '[ERROR]:%s job is either failed or not in good state. Please check'
				   , 16, 1, @job_name)WITH LOG

	RETURN @RunStatus
END
GO