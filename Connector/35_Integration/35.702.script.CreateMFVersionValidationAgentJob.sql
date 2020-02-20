
/*
Create agent to check MFiles version on a daily basis and update if changed

change log

2020-02-08 LC  Set agent by default to unable
2020-02-08 LC  Prevent agent to be updated on upgrading or reinstallation if exist 

*/

SET NOCOUNT ON;

DECLARE @rc          INT
       ,@msg         AS VARCHAR(250)
       ,@DBName      VARCHAR(100)
       ,@JobName     VARCHAR(100) 
       ,@Description VARCHAR(100) = 'validate M-Files version and update Assemblies when changed';

SET @msg = SPACE(5) + DB_NAME() + ': Create Job to ' + @Description;

RAISERROR('%s', 10, 1, @msg);

SELECT @DBName = CAST([Value] AS VARCHAR(100))
FROM [dbo].[MFSettings]
WHERE [Name] = 'App_Database';

SET @JobName = N'MFSQL Validate ' + @DBName + ' M-Files Version'

IF DB_NAME() = @DBName
BEGIN
    DECLARE @JobID BINARY(16);
    DECLARE @ReturnCode INT;

    SELECT @ReturnCode = 0;

    -- Delete the job with the same name (if it exists)  
    SELECT @JobID = [job_id]
    FROM [msdb].[dbo].[sysjobs]
    WHERE ([name] = @JobName);

	  --SELECT [job_id],*
   -- FROM [msdb].[dbo].[sysjobs]
   -- WHERE ([name] = @JobName);
   /*
    IF (@JobID IS NOT NULL)
    BEGIN
        IF (EXISTS
        (
            SELECT *
            FROM [msdb].[dbo].[sysjobservers]
            WHERE ([job_id] = @JobID)
                  AND ([server_id] = 0)
        )
           )
            -- Delete the [local] job   
  --          EXECUTE [msdb].[dbo].[sp_delete_job] @job_name = @JobName;

        SELECT @JobID = NULL;
    END;
    */
    /****** Object:  Job [Delete History]    Script Date: 12/12/2016 16:35:56 ******/
    BEGIN TRANSACTION;

    SELECT @ReturnCode = 0;

    /****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/12/2016 16:35:56 ******/
    IF NOT EXISTS
    (
        SELECT [syscategories].[name]
        FROM [msdb].[dbo].[syscategories]
        WHERE [syscategories].[name] = N'Database Maintenance'
              AND [syscategories].[category_class] = 1
    )
    BEGIN
        EXEC @ReturnCode = [msdb].[dbo].[sp_add_category] @class = N'JOB'
                                                         ,@type = N'LOCAL'
                                                         ,@name = N'Database Maintenance';

        RAISERROR('Install Database Maintenance Category: ReturnCode %i', 10, 1, @ReturnCode);

        IF (@@Error <> 0 OR @ReturnCode <> 0)
            GOTO QuitWithRollback;
    END;

    IF @JobID IS NULL
    BEGIN
    
    EXEC @ReturnCode = [msdb].[dbo].[sp_add_job] @job_name = @JobName
                                                ,@enabled = 0
                                                ,@notify_level_eventlog = 0
                                                ,@notify_level_email = 0
                                                ,@notify_level_netsend = 0
                                                ,@notify_level_page = 0
                                                ,@delete_level = 0
                                                ,@description = @Description
                                                ,@category_name = N'Database Maintenance'
                                                ,@owner_login_name = N'MFSQLConnect'
                                                ,@job_id = @JobID OUTPUT;

    RAISERROR('Add job: ReturnCode %i', 10, 1, @ReturnCode);

    IF (@@Error <> 0 OR @ReturnCode <> 0)
        GOTO QuitWithRollback;

    /****** Object:  Step [Delete older than 90 days]    Script Date: 12/12/2016 16:35:56 ******/
    EXEC @ReturnCode = [msdb].[dbo].[sp_add_jobstep] @job_id = @JobID
                                                    ,@step_name = N'Validate MFVersion'
                                                    ,@step_id = 1
                                                    ,@cmdexec_success_code = 0
                                                    ,@on_success_action = 1
                                                    ,@on_success_step_id = 0
                                                    ,@on_fail_action = 2
                                                    ,@on_fail_step_id = 0
                                                    ,@retry_attempts = 0
                                                    ,@retry_interval = 0
                                                    ,@os_run_priority = 0
                                                    ,@subsystem = N'TSQL'
                                                    ,@command = N'EXEC [dbo].[spMFCheckAndUpdateAssemblyVersion] '
                                                    ,@database_name = @DBName
                                                    ,@flags = 0;

    RAISERROR('Add Step: ReturnCode %i', 10, 1, @ReturnCode);

    IF (@@Error <> 0 OR @ReturnCode <> 0)
        GOTO QuitWithRollback;

    EXEC @ReturnCode = [msdb].[dbo].[sp_update_job] @job_id = @JobID
                                                   ,@start_step_id = 1;

    RAISERROR('Set Start step: ReturnCode %i', 10, 1, @ReturnCode);

    IF (@@Error <> 0 OR @ReturnCode <> 0)
        GOTO QuitWithRollback;

    EXEC @ReturnCode = [msdb].[dbo].[sp_add_jobschedule] @job_id = @JobID
                                                        ,@name = N'MFSQL MFVersion Daily schedule'
                                                        ,@enabled = 0
                                                        ,@freq_type = 4
                                                        ,@freq_interval = 1
                                                        ,@freq_subday_type = 1
                                                        ,@freq_subday_interval = 0
                                                        ,@freq_relative_interval = 0
                                                        ,@freq_recurrence_factor = 1
                                                        ,@active_start_date = 20190326
                                                        ,@active_end_date = 99991231
                                                        ,@active_start_time = 63000;

    RAISERROR('Add Schedule: ReturnCode %i', 10, 1, @ReturnCode);

    IF (@@Error <> 0 OR @ReturnCode <> 0)
        GOTO QuitWithRollback;

    EXEC @ReturnCode = [msdb].[dbo].[sp_add_jobserver] @job_id = @JobID
                                                      ,@server_name = N'(local)';

    RAISERROR('Set Server: ReturnCode %i', 10, 1, @ReturnCode);

        END

    IF (@@Error <> 0 OR @ReturnCode <> 0)
        GOTO QuitWithRollback;

    COMMIT TRANSACTION;


    GOTO EndSave;



    QuitWithRollback:
    RAISERROR('Unable to create Validate MFVersion agent', 10, 1);

    IF (@@TranCount > 0)
        ROLLBACK TRANSACTION;

        

    EndSave:
END;
GO