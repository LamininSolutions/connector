SELECT TOP 10
       *
FROM dbo.MFLog
ORDER BY LogID DESC;

EXEC dbo.spMFUpdateHistoryShow @Update_ID = 42558, -- int
                               @IsSummary = 1,     -- smallint
                               @UpdateColumn = 0,  -- int
                               @Debug = 0;         -- smallint


SELECT *
FROM dbo.MFClass AS mc
    INNER JOIN dbo.MFWorkflow AS mw
        ON mw.ID = mc.MFWorkflow_ID
WHERE mc.Name = 'Customer Project';

SELECT mws.MFID,
       mws.Name
FROM dbo.MFWorkflowState AS mws
WHERE mws.MFWorkflowID = 576;


SELECT mpc.Name_Or_Title,
       mpc.Workflow_ID,
       mpc.State,
       mpc.State_ID
FROM dbo.MFProject_Customer AS mpc
WHERE mpc.Workflow_ID <> 108;

UPDATE mpc
SET mpc.Process_ID = 1,
    mpc.Workflow_ID = 108,
    mpc.State_ID = 266
FROM dbo.MFProject_Customer AS mpc
WHERE mpc.Workflow_ID <> 108;

DECLARE @Update_IDOut INT,
        @ProcessBatch_ID INT;
EXEC dbo.spMFUpdateTable @MFTableName = N'MFProject_Customer', -- nvarchar(200)
                         @UpdateMethod = 0;

