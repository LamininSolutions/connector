CREATE VIEW [dbo].[MFvwSQLAgent_RunStatus]
AS
WITH [cte_]
AS (
   SELECT [j].[job_id]
         ,[job_name]                = [j].[name]
         ,[last_run_status]         = CASE
                                          WHEN [jh].[run_status] = 1 THEN
                                              'Succeeded'
                                          WHEN [jh].[run_status] = 0 THEN
                                              'Failed'
                                          WHEN [jh].[run_status] = 3 THEN
                                              'Cancelled'
                                          WHEN [jh].[run_status] = 5 THEN
                                              'Unknown'
                                          ELSE
                                              'Unknown (' + CAST([jh].[run_status] AS VARCHAR(10)) + ')'
                                      END
         ,[last_run_date]           = ISNULL(
                                                [msdb].[dbo].[agent_datetime]([jh].[run_date], [jh].[run_time])
                                               ,[ja1].[last_executed_step_date]
                                            )
         ,[last_run_duration]       = STUFF(STUFF(REPLACE(STR([jh].[run_duration], 6, 0), ' ', '0'), 3, 0, ':'), 6, 0, ':')
         ,[next_scheduled_run_date] = ISNULL([ja1].[run_requested_date], [ja].[next_scheduled_run_date])
         ,[ja1].[last_executed_step_date]
         ,[jh].[instance_id]
   FROM [msdb].[dbo].[sysjobs] AS [j]
       LEFT OUTER JOIN([msdb].[dbo].[sysjobhistory]  AS [jh]
       INNER JOIN
       (
           SELECT [job_id]
                 ,[instance_id] = MAX([instance_id])
           FROM [msdb].[dbo].[sysjobhistory]
           WHERE [step_id] = 0
           GROUP BY [job_id]
       )                                             AS [jh1]
           ON [jh].[job_id] = [jh1].[job_id]
              AND [jh].[instance_id] = [jh1].[instance_id]
       LEFT OUTER JOIN [msdb].[dbo].[sysjobactivity] AS [ja]
           ON [jh].[job_id] = [ja].[job_id]
              AND [jh].[instance_id] = [ja].[job_history_id])
           ON [j].[job_id] = [jh].[job_id]
              AND [jh].[step_id] = 0
       LEFT OUTER JOIN
       (
           SELECT [ja2].[job_id]
                 ,[ja2].[last_executed_step_date]
                 ,[ja2].[run_requested_date]
           FROM [msdb].[dbo].[sysjobactivity] [ja2]
           WHERE [ja2].[job_history_id] IS NULL
                 AND [ja2].[session_id] =
                 (
                     SELECT MAX([session_id])
                     FROM [msdb].[dbo].[sysjobactivity]
                     WHERE [job_history_id] IS NULL
                           AND [job_id] = [ja2].[job_id]
                 )
       )                       [ja1]
           ON [j].[job_id] = [ja1].[job_id])
SELECT [cte_].[job_id]
      ,[cte_].[job_name]
      ,[cte_].[last_run_status]
      ,[cte_].[last_run_date]
      ,[cte_].[last_run_duration]
      ,[cte_].[next_scheduled_run_date]
      ,[cte_].[last_executed_step_date]
      ,[cte_].[instance_id]
FROM [cte_]
WHERE [cte_].[job_name] LIKE 'SSIS%'
      OR [cte_].[job_name] LIKE 'MFSQL%';
