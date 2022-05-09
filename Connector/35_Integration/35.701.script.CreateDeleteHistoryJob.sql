
/*
Update history

2021-12-15  LC  only update agent if agent does not already exist
2019-08-01	LC	fic bug to set name of agent to include DB.  Note that the old agent must be removed manually

*/

SET NOCOUNT ON;

DECLARE @rc  INT,
    @msg     AS VARCHAR(250),
    @DBName  VARCHAR(100),
    @JobName VARCHAR(100);

SET @msg = SPACE(5) + DB_NAME() + ': Create Job to Delete History Records';

RAISERROR('%s', 10, 1, @msg);

SELECT @DBName = CAST(Value AS VARCHAR(100))
FROM dbo.MFSettings
WHERE Name = 'App_Database';

SET @JobName = N'MFSQL Delete History for ' + @DBName;

IF DB_NAME() = @DBName
BEGIN
    DECLARE @JobID BINARY(16);
    DECLARE @ReturnCode INT;

    SELECT @ReturnCode = 0;

    -- Delete the job with the same name (if it exists)  
    SELECT @JobID = job_id
    FROM msdb.dbo.sysjobs
    WHERE (name = @JobName);

    --IF (@JobID IS NOT NULL)  
    --BEGIN
    --IF (EXISTS (SELECT *   
    --FROM msdb.dbo.sysjobservers   
    --WHERE (job_id = @JobID) AND (server_id = 0)))   
    ---- Delete the [local] job   
    --EXECUTE msdb.dbo.sp_delete_job @job_name = @JobName
    --SELECT @JobID = NULL 
    --END
     IF (@JobID IS NOT NULL)
     Begin
   SET @msg = SPACE(5) + DB_NAME() + ': Job ' + @JobName + ' already exists';
   RAISERROR('%s', 10, 1, @msg);
   end
    IF (@JobID IS NULL)
    BEGIN

        /****** Object:  Job [Delete History]    Script Date: 12/12/2016 16:35:56 ******/
        BEGIN TRANSACTION;

        SELECT @ReturnCode = 0;

        /****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/12/2016 16:35:56 ******/
        IF NOT EXISTS
        (
            SELECT syscategories.name
            FROM msdb.dbo.syscategories
            WHERE syscategories.name = N'Database Maintenance'
                  AND syscategories.category_class = 1
        )
        BEGIN
            EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N'JOB',
                @type = N'LOCAL',
                @name = N'Database Maintenance';

            IF (@@Error <> 0 OR @ReturnCode <> 0)
                GOTO QuitWithRollback;
        END;

        EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name = @JobName,
            @enabled = 1,
            @notify_level_eventlog = 0,
            @notify_level_email = 0,
            @notify_level_netsend = 0,
            @notify_level_page = 0,
            @delete_level = 0,
            @description = N'Delete MFSQL Connector history records',
            @category_name = N'Database Maintenance',
            @owner_login_name = N'MFSQLConnect',
            @job_id = @JobID OUTPUT;

        IF (@@Error <> 0 OR @ReturnCode <> 0)
            GOTO QuitWithRollback;

        /****** Object:  Step [Delete older than 90 days]    Script Date: 12/12/2016 16:35:56 ******/
        EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID,
            @step_name = N'Delete older than 90 days',
            @step_id = 1,
            @cmdexec_success_code = 0,
            @on_success_action = 1,
            @on_success_step_id = 0,
            @on_fail_action = 2,
            @on_fail_step_id = 0,
            @retry_attempts = 0,
            @retry_interval = 0,
            @os_run_priority = 0,
            @subsystem = N'TSQL',
            @command = N'DECLARE @date DATETIME
SET @date =  DATEADD(mm,-3,GETDATE())
EXEC [dbo].[spMFDeleteHistory] @DeleteBeforeDate = @date -- datetime',
            @database_name = @DBName,
            @flags = 0;

        IF (@@Error <> 0 OR @ReturnCode <> 0)
            GOTO QuitWithRollback;

        EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID,
            @start_step_id = 1;

        IF (@@Error <> 0 OR @ReturnCode <> 0)
            GOTO QuitWithRollback;

        EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @JobID,
            @name = N'Monthly schedule',
            @enabled = 0,
            @freq_type = 32,
            @freq_interval = 1,
            @freq_subday_type = 1,
            @freq_subday_interval = 0,
            @freq_relative_interval = 1,
            @freq_recurrence_factor = 1,
            @active_start_date = 20161022,
            @active_end_date = 99991231,
            @active_start_time = 220000,
            @active_end_time = 235959,
            @schedule_uid = N'ddde2312-6c0c-4d31-aa7c-3f8301e65940';

        IF (@@Error <> 0 OR @ReturnCode <> 0)
            GOTO QuitWithRollback;

        EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID,
            @server_name = N'(local)';

        IF (@@Error <> 0 OR @ReturnCode <> 0)
            GOTO QuitWithRollback;

        COMMIT TRANSACTION;

        GOTO EndSave;

        QuitWithRollback:
        IF (@@TranCount > 0)
            ROLLBACK TRANSACTION;

        EndSave:
   SET @msg = SPACE(5) + DB_NAME() + ': Job ' + @JobName + ' created';
   RAISERROR('%s', 10, 1, @msg);

   END
  
END;
GO