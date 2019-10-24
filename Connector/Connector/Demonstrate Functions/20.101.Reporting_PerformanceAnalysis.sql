
/*
using BatchProcessing logging to get performance stats
*/

--review BatchProcess logs
SELECT *
FROM [dbo].[MFProcessBatch] AS [mpb]
ORDER BY [mpb].[ProcessBatch_ID] DESC;

SELECT *
FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
--WHERE [mpbd].[ProcessBatch_ID] = 1180
ORDER BY [mpbd].[ProcessBatch_ID] DESC
        ,[mpbd].[ProcessBatchDetail_ID] DESC;

-- summary of ProcessBatch
SELECT [mpb].[ProcessType]
      ,[mpb].[LogText]
      ,COUNT(*) [Instances]
      ,AVG([mpb].[DurationSeconds])
FROM [dbo].[MFProcessBatch] AS [mpb]
WHERE [mpb].[Status] = 'Completed'
      AND [mpb].[ProcessType] IS NOT NULL
GROUP BY [mpb].[ProcessType]
        ,[mpb].[LogText];

-- ProcessBatch summary by table
SELECT [mpb].[ProcessType]
      ,[mpbd].[MFTableName]
      ,COUNT(*)                     [Instances]
      ,SUM([mpb].[DurationSeconds]) [totalDuration]
FROM [dbo].[MFProcessBatchDetail]     AS [mpbd]
    INNER JOIN [dbo].[MFProcessBatch] AS [mpb]
        ON [mpb].[ProcessBatch_ID] = [mpbd].[ProcessBatch_ID]
WHERE [mpb].[Status] = 'Completed'
      AND [mpb].[ProcessType] IS NOT NULL
      AND [mpbd].[ColumnName] = 'MFUpdateHistory: NewOrUpdatedObjectDetails'
GROUP BY [mpb].[ProcessType]
        ,[mpbd].[MFTableName];

--  records per second
SELECT [mpb].[ProcessType]
      ,[mpbd].[MFTableName]
      ,[mpb].[LogText]
      ,MIN([mpb].[CreatedOn])                 AS [earliestDate]
      ,MAX([mpb].[CreatedOn])                 AS [lastUpdate]
      ,COUNT(*)                               [Instances]
      ,SUM([mpb].[DurationSeconds])           AS [Total_processingTime]
      ,AVG([mpb].[DurationSeconds])           AS [Ave_time]
      ,SUM(CAST([mpbd].[ColumnValue] AS INT)) AS [recordCount]
      ,CASE
           WHEN (SUM(CAST([mpbd].[ColumnValue] AS INT))) > 0 THEN
               CAST(ROUND(SUM(CAST([mpbd].[ColumnValue] AS INT)) / SUM([mpb].[DurationSeconds]), 2, 1) AS DECIMAL(18, 2))
           ELSE
               NULL
       END                                    AS [Records_Per_Second]
FROM [dbo].[MFProcessBatchDetail]     AS [mpbd]
    INNER JOIN [dbo].[MFProcessBatch] AS [mpb]
        ON [mpb].[ProcessBatch_ID] = [mpbd].[ProcessBatch_ID]
WHERE [mpb].[Status] = 'Completed'
      AND [mpb].[ProcessType] IS NOT NULL
      AND [mpbd].[ColumnName] = 'MFUpdateHistory: NewOrUpdatedObjectDetails'
      AND [mpbd].[ColumnValue] <> '0'
GROUP BY [mpb].[ProcessType]
        ,[mpbd].[MFTableName]
        ,[mpb].[LogText]
ORDER BY [mpb].[ProcessType];

--graph by table by session
SELECT [mpb].[ProcessBatch_ID]
      ,[mpb].[LogText]
      ,SUM([mpb].[DurationSeconds])           AS [Total_processingTime]
      ,AVG([mpb].[DurationSeconds])           AS [Ave_time]
      ,SUM(CAST([mpbd].[ColumnValue] AS INT)) AS [recordCount]
      ,CASE
           WHEN (SUM(CAST([mpbd].[ColumnValue] AS INT))) > 0 THEN
               CAST(ROUND(SUM(CAST([mpbd].[ColumnValue] AS INT)) / SUM([mpb].[DurationSeconds]), 2, 1) AS DECIMAL(18, 2))
           ELSE
               NULL
       END                                    AS [Records_Per_Second]
      ,[mpb].[ProcessType]
      ,[mpbd].[MFTableName]
      ,MIN([mpb].[CreatedOn])                 AS [earliestDate]
      ,MAX([mpb].[CreatedOn])                 AS [lastUpdate]
      ,COUNT(*)                               [Instances]
FROM [dbo].[MFProcessBatchDetail]     AS [mpbd]
    INNER JOIN [dbo].[MFProcessBatch] AS [mpb]
        ON [mpb].[ProcessBatch_ID] = [mpbd].[ProcessBatch_ID]
WHERE [mpb].[Status] = 'Completed'
      AND [mpb].[ProcessType] IS NOT NULL
      AND [mpbd].[ColumnName] = 'MFUpdateHistory: NewOrUpdatedObjectDetails'
      AND [mpbd].[ColumnValue] <> '0'
GROUP BY [mpb].[ProcessType]
        ,[mpb].[ProcessBatch_ID]
        ,[mpbd].[MFTableName]
        ,[mpb].[LogText]
ORDER BY [mpb].[ProcessType];

--base data
SELECT [mpb].[ProcessType]
      ,[mpbd].[MFTableName]
      ,[mpb].[LogText]
      ,[mpb].[CreatedOn]
      ,[mpb].[DurationSeconds]
      ,[mpbd].[ColumnValue]
      ,*
FROM [dbo].[MFProcessBatchDetail]     AS [mpbd]
    INNER JOIN [dbo].[MFProcessBatch] AS [mpb]
        ON [mpb].[ProcessBatch_ID] = [mpbd].[ProcessBatch_ID]
WHERE [mpb].[Status] = 'Completed'
      AND [mpb].[ProcessType] IS NOT NULL
      AND [mpbd].[ColumnName] = 'MFUpdateHistory: NewOrUpdatedObjectDetails'
      AND [mpbd].[ColumnValue] <> '0';
