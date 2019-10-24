
/*
Table initiation

This assumes that the class table is empty and MFAuditHistory for the class is null

Both methods assumes that you know the largest objid of the object type. 

Select 
*/
--Created on: 2019-07-25 

TRUNCATE TABLE mfbasic_SingleProp
SELECT MFID FROM MFClass WHERE  tablename = 'MFBasic_SingleProp'
DELETE from [dbo].[MFAuditHistory] WHERE class = 94

--Check MFAuditHistory
SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas] WHERE class = 'Basic_SingleProp'



--OPTION 1 : With updating table audit

--the FOLLOWING PROCEDURE will first populate the MFAuditHistory and then get all the class table records for the series.
-- Audit takes approx 73 seconds for 10 0000 records
-- Class table records takes approx 14 seconds per 500 items 
-- total time for 10 000 records 6:13 minutes

EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'MFBasic_SingleProp' -- nvarchar(100)
                                     ,@UpdateMethod = 1          -- int
                                     ,@WithTableAudit = 1      -- int
                                     ,@FromObjid = 1             -- bigint
                                     ,@ToObjid = 10000        -- bigint
                                     ,@WithStats = 1             -- bit
                                     ,@Debug = 0;                -- int
GO



--OPTION  : Without updating table audit
-- this option does not pre-populate the audit table, it will simply process the class table in series.
-- the average update time is similar to the above, although 
-- overall time is likely to be less.  10 000 items updated in 4:49 minutes.

EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'MFBasic_SingleProp' -- nvarchar(100)
                                     ,@UpdateMethod = 1          -- int
                                     ,@WithTableAudit = 0     -- int
                                     ,@FromObjid = 1             -- bigint
                                     ,@ToObjid = 10000        -- bigint
                                     ,@WithStats = 1             -- bit
                                     ,@Debug = 0;                -- int
GO

--it is recommended to run the table audit in any case, but it can be done subsequently

EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = 'MFBasic_SingleProp'  -- nvarchar(100)
                                    ,@FromObjid = 500000  -- int
                                    ,@ToObjid = 501000    -- int
                                    ,@WithStats = 1  -- bit
                                    ,@Debug = 1      -- int


--OPTION 3


EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = 'MFOtherDocument'  -- nvarchar(100)
                                    ,@FromObjid = 99   -- int
                                    ,@ToObjid = 100     -- int
                                    ,@WithStats = 1  -- bit
                                    ,@Debug = 1      -- int


