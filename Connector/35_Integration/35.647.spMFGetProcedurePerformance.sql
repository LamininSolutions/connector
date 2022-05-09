PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetProcedurePerformance]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFGetProcedurePerformance' -- nvarchar(100)
  , @Object_Release = '4.9.27.72'
  , @UpdateFlag = 2

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
----------------------------------------------------------------------------------------------*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFGetProcedurePerformance' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFGetProcedurePerformance]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFGetProcedurePerformance]
	(
@WithUpdateEvents BIT = 0 
,@MFSQL_User NVARCHAR(100) = N'MFSQLConnect'
,@ProcessBatch_ID INT
,@Debug INT = 0 
	)
AS
/*rST**************************************************************************

===========================
spMFGetProcedurePerformance
===========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @WithUpdateEvents (BIT)
    - default = 0
    - Set to 1 to update events from MF
  @MFSQL_User 
    - default MFSQLConnect
    - change to another user if the event log is using a different MFSQL user
  @ProcessBatch_ID (required)
    Referencing the ID of the ProcessBatch to be analysed
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
  
Purpose
=======

To review performance for a specific process based on a processbatch_id 

Get processbatch id to focus on
select top 100 * from mfprocessbatch order by processbatch_id desc


Additional Info
===============

This procedure combines the data in the logs to get a complete picture of the entire transaction on a timeline

processbatch - get transactions (ref, type, begin, end, duration, outcome, overlapping processing)
processbatch detail - get steps (steps type, begin, end, duration
mfupdatehistory - get volume, class, outcome (class, objects, begin, end , property count, update type)
mfilesevents - get MF processing during the same time (event type, start, stop, duration, related to object)

This procedure will create a number of interim global temp files (for further analysis) and a final stats summary

##spMFBatchProcess
##spMFBatchProcessDetail
##spMFUpdateHistory
##spMFUpdateHistoryShow
##spMFObjlist
##spMFEventList
##spMFProcessStats

Examples
========

.. code:: sql

    EXEC spMFGetProcedurePerformance
    @ProcessBatch_ID = 1050
    ,@WithUpdateEvents = 0
    ,@MFSQL_User  = N'MFSQLConnect'
    ,@Debug = 0 
   

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-12-15  LC         Create new procedure
==========  =========  ========================================================

**rST*************************************************************************/


BEGIN
		SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Performance Monitor')


		-------------------------------------------------------------
		-- VARIABLES: MFSQL Processing
		-------------------------------------------------------------
		DECLARE @Update_ID INT
	
		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFGetProcedurePerformance';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''



		BEGIN TRY
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Start'
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END




SET NOCOUNT ON;

DECLARE @ProcessStart DATETIME;
DECLARE @ProcessEnd DATETIME;

IF @WithUpdateEvents = 1
BEGIN
    EXEC dbo.spMFGetMfilesLog @IsClearMfilesLog = 0, -- bit  select 1 to delete the log in M-Files
        @Debug = 0;
END;

IF
(
    SELECT OBJECT_ID('tempdb..##spMFBatchProcess')
) IS NOT NULL
    DROP TABLE ##spMFBatchProcess;

SELECT mpb.CreatedOnUTC,
    mpb.ProcessBatch_ID,
    mpb.ProcessType,
    mpb.LogType,
    mpb.LogText,
    mpb.Status,
    mpb.DurationSeconds
INTO ##spMFBatchProcess
FROM dbo.MFProcessBatch AS mpb
WHERE (
          mpb.ProcessBatch_ID = @ProcessBatch_ID
          OR @ProcessBatch_ID IS NULL
      )
ORDER BY mpb.ProcessBatch_ID DESC;

IF @ProcessBatch_ID IS NOT NULL
    SELECT @ProcessStart = mbp.CreatedOnUTC
    FROM ##spMFBatchProcess AS mbp;

IF @Debug > 100
BEGIN
    SELECT COUNT(*) BatchProcessCount
    FROM ##spMFBatchProcess AS mbp;

    SELECT TOP 10
        *
    FROM ##spMFBatchProcess AS mbp;
END;

IF
(
    SELECT OBJECT_ID('tempdb..##spMFBatchProcessDetail')
) IS NOT NULL
    DROP TABLE ##spMFBatchProcessDetail;

SELECT bp.ProcessBatch_ID,
    mpbd.ProcessBatchDetail_ID,
    CASE
        WHEN mpbd.Update_ID IS NULL THEN
            bp.ProcessBatch_ID
        ELSE
            mpbd.Update_ID
    END                  AS Update_ID,
    mpbd.CreatedOnUTC    CreatedOnUTC_pbd,
    mpbd.ProcedureRef,
    mpbd.logtext AS LogText_pbd,
    mpbd.LogType         Logtype_pbd,
    mpbd.Status          status_pbd,
    bp.DurationSeconds,
    mpbd.DurationSeconds DurationSeconds_pbd,
    mpbd.MFTableName,
    mpbd.ColumnName,
    mpbd.ColumnValue
INTO ##spMFBatchProcessDetail
FROM ##spMFBatchProcess                   bp
    INNER JOIN dbo.MFProcessBatchDetail AS mpbd
        ON mpbd.ProcessBatch_ID = bp.ProcessBatch_ID
ORDER BY mpbd.ProcessBatchDetail_ID;

CREATE INDEX BatchProcessDetail_ProcessBatch_ID
ON ##spMFBatchProcessDetail (ProcessBatch_ID);

ALTER TABLE ##spMFBatchProcessDetail
ADD ProcessTimeUnit NVARCHAR(100),
    ProcessTimeDuration FLOAT,
    ProcessTimeStart DATETIME,
    ProcessTimeEnd DATETIME,
    ProcessStepEnd DATETIME,
    MFEventDuration FLOAT,
    MFEventCount int;

IF @ProcessBatch_ID IS NOT NULL
    SELECT @ProcessEnd = MAX(mbpd.CreatedOnUTC_pbd)
    FROM ##spMFBatchProcessDetail AS mbpd;

DECLARE @NextUpdate_ID INT;
DECLARE @ProcessBatchDetail_ID INT;
DECLARE @ProcessTimeUnit INT = 0;

DECLARE BPDCursor CURSOR FOR
SELECT bd.ProcessBatchDetail_ID,
    bd.Update_ID
FROM ##spMFBatchProcessDetail bd
ORDER BY bd.CreatedOnUTC_pbd;

OPEN BPDCursor;

FETCH NEXT FROM BPDCursor
INTO @ProcessBatchDetail_ID,
    @NextUpdate_ID;

WHILE @@Fetch_Status = 0
BEGIN
    SET @ProcessTimeUnit = CASE
                               WHEN @update_ID = @NextUpdate_ID THEN
                                   @ProcessTimeUnit
                               ELSE
                                   @ProcessTimeUnit + 1
                           END;

    UPDATE bd
    SET processTimeUnit = @ProcessTimeUnit
    FROM ##spMFBatchProcessDetail bd
    WHERE bd.ProcessBatchDetail_ID = @ProcessBatchDetail_ID;

    SELECT @update_ID = bd.Update_ID
    FROM ##spMFBatchProcessDetail bd
    WHERE bd.ProcessBatchDetail_ID = @ProcessBatchDetail_ID;

    FETCH NEXT FROM BPDCursor
    INTO @ProcessBatchDetail_ID,
        @NextUpdate_ID;
END;

CLOSE BPDCursor;
DEALLOCATE BPDCursor;

WITH cte
AS (SELECT bd.ProcessBatch_ID,
        ProcessTimeUnit,
        bd.Update_ID,
        MIN(bd.CreatedOnUTC_pbd)                                                         SubProcessStart,
        MAX(bd.CreatedOnUTC_pbd)                                                         SubProcessEnd,
        DATEDIFF(MILLISECOND, MIN(bd.CreatedOnUTC_pbd), MAX(bd.CreatedOnUTC_pbd)) * .001 ProcessTimeDuration
        
    FROM ##spMFBatchProcessDetail bd
    GROUP BY bd.ProcessBatch_ID,
        ProcessTimeUnit,
        bd.Update_ID)
UPDATE bd
SET processTimeDuration = cte.ProcessTimeDuration,
    ProcessTimeStart = cte.SubProcessStart,
    ProcessTimeEnd = cte.SubProcessEnd
FROM ##spMFBatchProcessDetail bd
    INNER JOIN cte
        ON cte.ProcessTimeUnit = bd.ProcessTimeUnit
           AND bd.Update_ID = cte.Update_ID
           AND cte.ProcessBatch_ID = bd.ProcessBatch_ID;
;
WITH cte AS
(SELECT ProcessBatchDetail_ID, LEAD(CreatedOnUTC_pbd) OVER ( ORDER BY ProcessBatchDetail_ID) ProcessStepEnd
FROM ##spMFBatchProcessDetail bd)
UPDATE bd
SET ProcessStepEnd = cte.ProcessStepEnd
FROM ##spMFBatchProcessDetail bd
INNER JOIN cte
ON bd.ProcessBatchDetail_ID = cte.ProcessBatchDetail_ID;

IF @Debug > 100
BEGIN
    SELECT COUNT(*) MFBatchProcessDetail
    FROM ##spMFBatchProcessDetail AS mbp;

    SELECT TOP 100
        *
    FROM ##spMFBatchProcessDetail AS mbpd;
END;

IF
(
    SELECT OBJECT_ID('tempdb..##spMFUpdateHistory')
) IS NOT NULL
    DROP TABLE ##spMFUpdateHistory;

SELECT 
  mbpd.Update_ID,
    muh.UpdateMethod,
    muh.UpdateStatus,  
    muh.CreatedAt

INTO ##spMFUpdateHistory
FROM dbo.MFUpdateHistory              AS muh
    INNER JOIN ##spMFBatchProcessDetail AS mbpd
        ON muh.Id = mbpd.Update_ID
WHERE mbpd.Update_ID IS NOT NULL
GROUP BY mbpd.Update_ID,
    muh.UpdateMethod,
    muh.UpdateStatus,    
    muh.CreatedAt
    ;

IF @Debug > 100
BEGIN
    SELECT COUNT(*) MFUpdateHistory
    FROM ##spMFUpdateHistory AS mbp;

    -- SELECT TOP 100
    --    *
    --FROM MFUpdateHistory AS muh
    --WHERE id = 119;
    SELECT TOP 100
        *
    FROM ##spMFUpdateHistory AS muh;
END;

IF
(
    SELECT OBJECT_ID('tempdb..##spMFUpdateHistoryShow')
) IS NOT NULL
    DROP TABLE ##spMFUpdateHistoryShow;

CREATE TABLE ##spMFUpdateHistoryShow
(
    Update_ID INT,
    UpdateType NVARCHAR(100),
    UpdateColumn INT,
    ColumnName NVARCHAR(100),
    UpdateDescription NVARCHAR(100),
    Updatemethod INT,
    RecCount INT,
    class NVARCHAR(100),
    ObjectType NVARCHAR(100),
    TableName NVARCHAR(100)
);

IF
(
    SELECT OBJECT_ID('tempdb..##spMFObjlist')
) IS NOT NULL
    DROP TABLE ##spMFObjlist;


CREATE TABLE ##spMFObjlist
(
    Update_ID INT,
    objid INT,
    mfversion INT
);

CREATE INDEX oblist ON ##spMFObjlist (Update_ID, objid, mfversion);

DECLARE @Updatemethod INT;
DECLARE @XML2 XML;
DECLARE @XML3 XML;
DECLARE @Idoc INT;

SELECT @update_ID = MIN(muh.Update_ID)
FROM ##spMFBatchProcessDetail AS muh
WHERE muh.Update_ID IS NOT NULL AND Muh.ProcessBatch_ID <> muh.Update_ID;

WHILE @update_ID IS NOT NULL 
BEGIN
    IF
    (
        SELECT OBJECT_ID('tempdb..#Showresult')
    ) IS NOT NULL
        DROP TABLE #Showresult;

    CREATE TABLE #Showresult
    (
        UpdateColumn INT,
        UpdateType NVARCHAR(100),
        ColumnName NVARCHAR(100),
        UpdateDescription NVARCHAR(100),
        Updatemethod INT,
        RecCount INT,
        class NVARCHAR(100),
        ObjectType NVARCHAR(100),
        TableName NVARCHAR(100)
    );

    INSERT INTO #Showresult
    EXEC dbo.spMFUpdateHistoryShow @Update_ID = @update_ID, @IsSummary = 1;

    IF @Debug > 100
    BEGIN
        SELECT *
        FROM dbo.MFUpdateHistory
        WHERE Id = @update_ID;

        SELECT 'showresult',
            *
        FROM #Showresult AS s;
    END;

    INSERT INTO ##spMFUpdateHistoryShow
    (
        Update_ID,
        UpdateColumn,
        UpdateType,
        ColumnName,
        UpdateDescription,
        Updatemethod,
        RecCount,
        class,
        ObjectType,
        TableName
    )
    SELECT @update_ID,
        s.UpdateColumn,
        s.UpdateType,
        s.ColumnName,
        s.UpdateDescription,
        s.Updatemethod,
        s.RecCount,
        s.class,
        s.ObjectType,
        s.TableName
    FROM #Showresult AS s;

    SELECT @Updatemethod = muh.UpdateMethod      
    FROM ##spMFUpdateHistoryShow AS muh
    WHERE muh.Update_id = @update_ID
    GROUP BY Updatemethod
    ;

IF @Updatemethod in (0,1,10,11)
BEGIN

DECLARE @updateColumn INT
DECLARE @objidtable AS TABLE (Objid INT)

SET @updateColumn = CASE WHEN @Updatemethod = 0 THEN 2
WHEN @Updatemethod = 1 THEN 1
ELSE NULL
End


IF (SELECT OBJECT_ID('tempdb..#temp')) IS NOT NULL
DROP TABLE #temp;

CREATE TABLE #Temp
(  objId int,
           MFVersion int,
           GUID nvarchar(100)  ) 
           ;
        insert INTO #Temp  
        (objId,MFVersion,GUID)
        EXEC dbo.spMFUpdateHistoryShow @Update_ID = @Update_ID,
    @IsSummary = 0,
    @UpdateColumn = @UpdateColumn,
    @Debug = 0


     INSERT INTO ##spMFObjlist
        (
            Update_ID,
            objid,
            mfversion
        )
        SELECT DISTINCT
            @update_ID,
            x.objId,
            x.MFVersion
        FROM #temp x
    
    end

 
    SELECT @update_ID =
    (
        SELECT MIN(muh.Update_ID)
        FROM ##spMFBatchProcessDetail AS muh
        WHERE muh.Update_ID > @update_ID AND Muh.ProcessBatch_ID <> muh.Update_ID
    );
END;

IF @Debug > 100
BEGIN
    SELECT COUNT(*) ObList
    FROM ##spMFObjlist AS mbp;

    SELECT TOP 10000
        *
    FROM ##spMFUpdateHistoryShow AS muhs;

    SELECT TOP 100
        *
    FROM ##spMFObjlist AS muhs;
END;

IF
(
    SELECT OBJECT_ID('tempdb..##spMFEventList')
) IS NOT NULL
    DROP TABLE ##spMFEventList;

CREATE TABLE ##spMFEventList
(
    id INT,
    EventType NVARCHAR(100),
    Category NVARCHAR(100),
    EventDate DATETIME,
    ProcessLead DATETIME,
    Name_Or_title NVARCHAR(100),
    ObjectType NVARCHAR(100),
    objid INT,
    version INT,
    ProcessDuration_MS float
);

IF @Debug > 0
    SELECT @ProcessStart Processstart,
        @ProcessEnd      ProcessEnd;

WITH cte
AS (SELECT me.ID,
        me.Type                                                                          AS EventType,
        me.Category,
        me.CausedByUser,
        CONVERT(DATETIME, SUBSTRING(me.TimeStamp, 1, 22))                                AS EventDate,
        me.Events.value('(/event/data/objectversion/title)[1]', 'varchar(100)')          AS NameOrTitle,
        me.Events.value('(/event/data/objectversion/objver/objtype)[1]', 'varchar(100)') AS ObjectType,
        me.Events.value('(/event/data/objectversion/objver/objid)[1]', 'varchar(100)')   AS Objid,
        me.Events.value('(/event/data/objectversion/objver/version)[1]', 'varchar(100)') AS Version
    FROM dbo.MFilesEvents me
    WHERE me.CausedByUser = @MFSQL_User
--     
),
CTE2
AS (SELECT cte.ID,
        LEAD(cte.EventDate) OVER (ORDER BY cte.ID) ProcessEnd,
        --,LAG([cte].Eventdate) OVER (ORDER BY [cte].[ID])  [LagStart]
        cte.EventDate                              AS ProcessStart
    FROM cte)
INSERT INTO ##spMFEventList
(
    id,
    EventType,
    Category,
    EventDate,
    ProcessLead,
    Name_Or_title,
    ObjectType,
    objid,
    version,
    ProcessDuration_MS
)
SELECT cte.ID,
    cte.EventType,
    cte.Category,
    CTE2.ProcessStart,
    CTE2.ProcessEnd,
    cte.NameOrTitle,
    cte.ObjectType,
    cte.Objid,
    cte.Version,
    (DATEDIFF(MILLISECOND, CTE2.ProcessStart, CTE2.ProcessEnd))*.0001  ProcessDuration
FROM cte
    INNER JOIN CTE2
        ON cte.ID = CTE2.ID
WHERE CTE2.ProcessStart
BETWEEN @ProcessStart AND @ProcessEnd;

IF @Debug > 100
BEGIN
    SELECT COUNT(*) EventList
    FROM ##spMFEventList AS mbp;

    SELECT TOP 100
        *
    FROM ##spMFEventList AS el
    ORDER BY el.EventDate;
END;

;WITH cte AS
(
SELECT ProcessBatchDetail_ID,
mfEventDuration= (SELECT SUM(ProcessDuration_MS) 
FROM ##spMFEventList
WHERE EventDate BETWEEN CreatedOnUTC_pbd AND ProcessStepEnd
),
mfEventCount = (SELECT count(ProcessDuration_MS) 
FROM ##spMFEventList
WHERE EventDate BETWEEN CreatedOnUTC_pbd AND ProcessStepEnd
)
FROM ##spMFBatchProcessDetail
)
UPDATE bd
SET mfEventDuration = cte.mfEventDuration, MFeventCount = cte.mfEventCount
FROM ##spMFBatchProcessDetail bd
INNER JOIN cte
ON bd.ProcessBatchDetail_ID = CTE.ProcessBatchDetail_ID;

IF
(
    SELECT OBJECT_ID('tempdb..##spMFProcessStats')
) IS NOT NULL
    DROP TABLE ##spMFProcessStats;

CREATE TABLE ##spMFProcessStats
(
    ProcessStats_ID INT IDENTITY,
    ProcessTimeUnit int,
    Update_ID INT,
    ProcessBatch_ID INT,
    ProcessType NVARCHAR(100),
    Process_Description NVARCHAR(1000),
    MFTableName NVARCHAR(100),
    UpdateMethod INT,
    ProcessStart DATETIME,
    ProcessEnd DATETIME,
    SubProcessStart DATETIME,
    SubProcessEnd DATETIME,
    ProcessDuration_S FLOAT,
    SubProcessDuration_S FLOAT,
    SubProcessLag_ms INT,
    ProcessTimeStart DATETIME,
    ProcessTimeEnd DATETIME,
    ProcessTimeDuration FLOAT,
    ProcessStatus NVARCHAR(100),
    ObjectCount INT,
    PropertyCount INT,
    PropertiesPerObject INT,
    DurationPerObject FLOAT,
    Assembly_Duration FLOAT,
    Assembly_Ratio FLOAT,
    MFEventDuration FLOAT,
    MFEventCount int
);

CREATE INDEX ProcessStats_ProcessBatch_ID
ON ##spMFProcessStats (ProcessBatch_ID);

INSERT INTO ##spMFProcessStats
(
    ProcessTimeUnit,
    Update_ID,
    ProcessBatch_ID,
    ProcessType,
    Process_Description,
    ProcessStatus,
    ProcessStart,
    ps.ProcessDuration_S,
    ProcessTimeDuration,
    ProcessTimeStart,
    ProcessTimeEnd,
    MFEventDuration,
    MFEventCount
)
SELECT 
    CAST(mbpd.ProcessTimeunit AS INT),
    mbpd.Update_ID,
    mbp.ProcessBatch_ID,
    mbp.ProcessType,
    mbp.LogText,
    mbp.Status,
    mbp.CreatedOnUTC,
    mbp.DurationSeconds,
    mbpd.ProcessTimeDuration,
    mbpd.ProcessTimeStart,
    mbpd.ProcessTimeEnd,
    MFEventDuration,
    MFEventCount
--SELECT mbpd.Update_ID, *
FROM ##spMFBatchProcessDetail     AS mbpd
    LEFT JOIN ##spMFObjlist          AS ol
        ON ol.Update_ID = mbpd.Update_ID
    INNER JOIN ##spMFBatchProcess AS mbp
        ON mbpd.ProcessBatch_ID = mbp.ProcessBatch_ID
        GROUP BY
    mbpd.ProcessTimeunit,
    mbpd.Update_ID,
    mbp.ProcessBatch_ID,
    mbp.ProcessType,
    mbp.LogText,
    mbp.Status,
    mbp.CreatedOnUTC,
    mbp.DurationSeconds,
    mbpd.ProcessTimeDuration,
    mbpd.ProcessTimeStart,
    mbpd.ProcessTimeEnd,
    MFEventDuration,
    MFEventCount
;

WITH cte
AS (SELECT ProcessTimeUnit,
        mbpd.Update_ID,
        mbpd.ProcessBatch_ID,
        mbpd.MFTableName,
        MIN(mbpd.CreatedOnUTC_pbd)    SubProcessStart,
        MAX(mbpd.CreatedOnUTC_pbd)    SubProcessEnd,
        SUM(mbpd.DurationSeconds_pbd) SubProcessDuration,
        DATEDIFF(MILLISECOND,MAX(mbpd.CreatedOnUTC_pbd), LEAD(MIN(mbpd.CreatedOnUTC_pbd)) OVER (ORDER BY processTimeUnit) ) SubProcessLag
    FROM ##spMFBatchProcessDetail     AS mbpd
        INNER JOIN ##spMFBatchProcess AS mbp
            ON mbpd.ProcessBatch_ID = mbp.ProcessBatch_ID
    GROUP BY mbpd.ProcessTimeUnit,
        mbpd.Update_ID,
        mbpd.ProcessBatch_ID,
        mbpd.MFTableName)
UPDATE ps
SET ps.MFTableName = cte.MFTableName,
    ps.SubProcessStart = cte.SubProcessStart,
    ps.SubProcessEnd = cte.SubProcessEnd,
    --,ps.SubProcessDuration_S = cte.SubProcessDuration
    ps.SubProcessDuration_S = DATEDIFF(MILLISECOND, cte.SubProcessStart, cte.SubProcessEnd) * .001,
    ps.subProcessLag_ms = cte.subprocessLag
--SELECT cte.SubProcessStart,cte.SubProcessEnd,ps.SubProcessDuration_S, DATEDIFF(MILLISECOND, cte.SubProcessStart,cte.SubProcessEnd) / 100
FROM cte
    INNER JOIN ##spMFProcessStats AS ps
        ON cte.ProcessBatch_ID = ps.ProcessBatch_ID
           AND ps.Update_ID = cte.Update_ID
           AND cte.ProcessTimeUnit = ps.ProcessTimeUnit
WHERE cte.ProcessBatch_ID = ps.ProcessBatch_ID
      AND ps.Update_ID = cte.Update_ID
      AND cte.ProcessTimeUnit = ps.ProcessTimeUnit;

UPDATE ps
SET ps.UpdateMethod = mbpd.ColumnValue
--SELECT ColumnValue 
FROM ##spMFProcessStats                   AS ps
    INNER JOIN ##spMFBatchProcessDetail AS mbpd
        ON ps.ProcessBatch_ID = mbpd.ProcessBatch_ID
           AND ps.Update_ID = mbpd.Update_ID
WHERE mbpd.ColumnName = 'UpdateMethod';

UPDATE ps
SET ps.ObjectCount = COALESCE(mbpd.ColumnValue, 0)
--SELECT ColumnValue 
FROM ##spMFProcessStats                   AS ps
    INNER JOIN ##spMFBatchProcessDetail AS mbpd
        ON ps.ProcessBatch_ID = mbpd.ProcessBatch_ID
           AND ps.Update_ID = mbpd.Update_ID
WHERE mbpd.ColumnName = 'NewOrUpdatedObjectDetails';

UPDATE ps
SET ps.PropertyCount = COALESCE(mbpd.ColumnValue, 0)
--SELECT ColumnValue 
FROM ##spMFProcessStats                   AS ps
    INNER JOIN ##spMFBatchProcessDetail AS mbpd
        ON ps.ProcessBatch_ID = mbpd.ProcessBatch_ID
           AND ps.Update_ID = mbpd.Update_ID
WHERE mbpd.ColumnName = 'Properties';

UPDATE ps
SET ps.Assembly_Duration = COALESCE(mbpd.DurationSeconds_pbd, 0)
--SELECT ColumnValue ,*
FROM ##spMFProcessStats                   AS ps
    INNER JOIN ##spMFBatchProcessDetail AS mbpd
        ON ps.ProcessBatch_ID = mbpd.ProcessBatch_ID
           AND ps.Update_ID = mbpd.Update_ID
WHERE mbpd.logtext_pbd = 'Wrapper turnaround';

WITH cte
AS (SELECT ol.Update_ID,
        COUNT(ol.objid) rcount
    FROM ##spMFObjlist AS ol
    GROUP BY ol.Update_ID)
UPDATE ps
SET ps.ObjectCount = cte.rcount
FROM ##spMFProcessStats AS ps
    INNER JOIN cte
        ON ps.Update_ID = cte.Update_ID;

UPDATE ps
SET ps.PropertiesPerObject = CAST(NULLIF(ISNULL(ps.PropertyCount,0) / ISNULL(ps.ObjectCount, 1),0) AS DECIMAL(18,2))
,ps.DurationPerObject = CASE
                               WHEN ISNULL(ps.ObjectCount, 0) = 0 THEN
                                   ps.SubProcessDuration_S
                               ELSE
                                   CAST(NULLIF(ps.SubProcessDuration_S / ISNULL(ps.ObjectCount, 1), 0)AS DECIMAL(18,2))
                           END
--select *
FROM ##spMFProcessStats AS ps
WHERE ISNULL(ps.ObjectCount, -1) <> -1;

UPDATE ps
SET ps.Assembly_Ratio = CASE
                            WHEN ps.UpdateMethod IS NOT NULL AND ps.Assembly_Duration IS NOT null THEN
                                CAST(nullif(isnull(ps.Assembly_Duration, 0) / isnull(ps.SubProcessDuration_S, 1),1) * .001 AS DECIMAL(18, 2))
                            ELSE
                                NULL
                        END
--select *
FROM ##spMFProcessStats AS ps
WHERE ISNULL(ps.Assembly_Ratio, -1) <> -1;

WITH cte
AS (SELECT ps.ProcessBatch_ID,
        MAX(ps.SubProcessEnd) processEnd
    FROM ##spMFProcessStats AS ps
    GROUP BY ps.ProcessBatch_ID)
UPDATE ps
SET ps.ProcessEnd = cte.processEnd
FROM ##spMFProcessStats AS ps
    INNER JOIN cte
        ON ps.ProcessBatch_ID = cte.ProcessBatch_ID;

SELECT '##spMFProcessStats',
    *
FROM ##spMFProcessStats AS ps
ORDER BY ps.ProcessTimeUnit;

SELECT '##spMFBatchProcess',
    *
FROM ##spMFBatchProcess
ORDER BY DurationSeconds;

SELECT '##spMFBatchProcessDetail',
    *
FROM ##spMFBatchProcessDetail
ORDER BY ProcessBatchDetail_ID;

SELECT '##spMFUpdateHistory',
    *
FROM ##spMFUpdateHistory;

SELECT '##spMFUpdateHistoryShow',
    *
FROM ##spMFUpdateHistoryShow;

SELECT '##spMFObjlist',
    *
FROM ##spMFObjlist
ORDER BY Update_ID,
    objid;

SELECT '##spMFEventList',
    *
FROM ##spMFEventList
ORDER BY EventDate;

			-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'

			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   
			RETURN 1
		END TRY
		BEGIN CATCH
	
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
		
			RETURN -1
		END CATCH

	END

GO
 



