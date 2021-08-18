PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableinBatches]';
GO

SET NOCOUNT ON;
GO

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTableinBatches', -- nvarchar(100)
    @Object_Release = '4.9.27.69',             -- varchar(50)
    @UpdateFlag = 2;                           -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateTableinBatches' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

CREATE PROCEDURE dbo.spMFUpdateTableinBatches
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFUpdateTableinBatches
(
    @MFTableName NVARCHAR(100),
    @UpdateMethod INT = 1,
    @WithTableAudit INT = 0,
    @FromObjid BIGINT = 1,
    @ToObjid BIGINT = 1000000,
    @WithStats BIT = 1,
    @RetainDeletions BIT = 0,
    @ProcessBatch_ID INT = NULL,
    @Debug INT = 0 --
)
AS

/*rST**************************************************************************

========================
spMFUpdateTableinBatches
========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @UpdateMethod INT
    - Default to 1 (From MF to SQL)
    - Set to 0 for updates from SQL to MF
  @WithTableAudit Int
    - Default = 0 (table audit not included)
    - Set to 1 to trigger a table audit on the selected objids
  @FromObjid BIGINT
    Starting objid
  @ToObjid BIGINT
    - End objid inclusive
    - Default = 100 000
  @WithStats BIT
    - Default = 1 (true)
    - When true a log will be produced in the SSMS message window to show the progress
    - Set to 0 to suppress the messages.
  @RetainDeletions BIT
    - Default = 0 (no)
    - Set to 1 to retain the deleted records in the class table
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Procedure to update class table in batches

Additional Info
===============

When updating a large number of records from a specific class in MF to SQL it is advisable to process these updates of large datasets in batches.  
Processing batches will ensure that a logical restart point can be determined in case of failure or to control the updating in large chunks.
It will also keep the size of the dataset for transfer within the limits of the XML transfer file.

Prerequisites
=============

It is good practice to provide the maximum object id in the Object Type + 500 as the @ToObjid instead of just working with the default of 100 000.  One way to obtain the maximum is to use a view in M-Files on the Segment ID.

Examples
========

update SQL to MF

.. code:: sql

    EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'YourTable'
                                         ,@UpdateMethod = 0
                                         ,@WithStats = 1
                                         ,@Debug = 0;


-----

Update MF to SQL : class table initialisation (note the setting with @WithtableAudit)

.. code:: sql

    EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'YourTable'
                                         ,@UpdateMethod = 1
                                         ,@WithTableAudit = 1
                                         ,@FromObjid = 1
                                         ,@ToObjid = 1000
                                         ,@WithStats = 1
                                         ,@Debug = 0;

-----

Update MF to SQL : Retain the deleted objects in the class table

.. code:: sql

    EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'YourTable'
                                         ,@UpdateMethod = 1
                                         ,@WithTableAudit = 1
                                         ,@FromObjid = 1
                                         ,@ToObjid = 1000
                                         ,@WithStats = 1
                                         ,@RetainDeletions = 1
                                         ,@Debug = 0;

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-05-03  LC         Fix bug to include first record of each batch
2020-09-24  LC         Set updatetable objids to include unmatched versions
2020-09-23  LC         Fix batch size calculation
2020-09-04  LC         Fix null count or set operation
2020-08-23  LC         Add parameter to retain deletions, default set to NO
2019-12-18  LC         include status flag 6 from AuditTable
2019-06-22  LC         substantially rebuilt to improve efficiencies
2019-08-05  LC         resolve issue with catching last object if new and only one object exist
2018-12-15  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = ISNULL(@ProcessType, 'Batch Update');

-------------------------------------------------------------
-- CONSTATNS: MFSQL Global 
-------------------------------------------------------------
DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
DECLARE @Process_ID_1_Update TINYINT = 1;
DECLARE @Process_ID_6_ObjIDs TINYINT = 6; --marks records for refresh from M-Files by objID vs. in bulk
DECLARE @Process_ID_9_BatchUpdate TINYINT = 9; --marks records previously set as 1 to 9 and update in batches of 250
DECLARE @Process_ID_Delete_ObjIDs INT = -1; --marks records for deletion
DECLARE @Process_ID_2_SyncError TINYINT = 2;
DECLARE @ProcessBatchSize INT;

-------------------------------------------------------------
-- VARIABLES: MFSQL Processing
-------------------------------------------------------------
DECLARE @Update_ID INT;
DECLARE @Update_IDOut INT;
DECLARE @MFLastModified DATETIME;
DECLARE @MFLastUpdateDate DATETIME;
DECLARE @Validation_ID INT;

-------------------------------------------------------------
-- VARIABLES: T-SQL Processing
-------------------------------------------------------------
DECLARE @rowcount AS INT = 0;
DECLARE @return_value AS INT = 0;
DECLARE @error AS INT = 0;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFUpdateTableInBatches';
DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = N'';
DECLARE @Msg AS NVARCHAR(256) = N'';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- VARIABLES: LOGGING
-------------------------------------------------------------
DECLARE @LogType AS NVARCHAR(50) = N'Status';
DECLARE @LogText AS NVARCHAR(4000) = N'';
DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
DECLARE @LogTypeDetail AS NVARCHAR(50) = N'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = N'';
DECLARE @LogStatusDetail AS NVARCHAR(50) = N'In Progress';
DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;
DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
DECLARE @count INT = 0;
DECLARE @Now AS DATETIME = GETDATE();
DECLARE @StartTime AS DATETIME = GETUTCDATE();
DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

-------------------------------------------------------------
-- VARIABLES: DYNAMIC SQL
-------------------------------------------------------------
DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @sqlParam NVARCHAR(MAX) = N'';

-------------------------------------------------------------
-- INTIALIZE PROCESS BATCH
-------------------------------------------------------------
SET @ProcedureStep = N'Start Logging';
SET @LogText = N'Processing ' + @ProcedureName;

EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @ProcessType = @ProcessType,
    @LogType = N'Status',
    @LogText = @LogText,
    @LogStatus = N'In Progress',
    @debug = @Debug;

EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
    @LogType = N'Debug',
    @LogText = @ProcessType,
    @LogStatus = N'Started',
    @StartTime = @StartTime,
    @MFTableName = @MFTableName,
    @Validation_ID = @Validation_ID,
    @ColumnName = NULL,
    @ColumnValue = NULL,
    @Update_ID = @Update_ID,
    @LogProcedureName = @ProcedureName,
    @LogProcedureStep = @ProcedureStep,
    @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
    @debug = 0;

BEGIN TRY
    -- Debug params
    SET @ProcedureStep = N'Initialise';

    --BEGIN  
    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    --<Begin Proc>--

    --set the parameters

    -------------------------------------------------------------
    -- Get column for last modified
    -------------------------------------------------------------
    DECLARE @lastModifiedColumn NVARCHAR(100);

    SELECT @lastModifiedColumn = mp.ColumnName
    FROM dbo.MFProperty AS mp
    WHERE mp.MFID = 21;

    --'Last Modified'

    -------------------------------------------------------------
    -- calculate batch size
    -------------------------------------------------------------
    DECLARE @BatchSize INT = 500;
    --other parameters 
    DECLARE @StartRow   INT,
        @MaxRow         INT,
        @RecCount       INT,
        @BatchCount     INT           = 1,
        @UpdateID       INT,
        @ProcessingTime INT,
        @objids         NVARCHAR(4000),
        @Message        NVARCHAR(100),
        @Class_ID       INT;
    DECLARE @SessionIDOut   INT,
        @NewObjectXml       NVARCHAR(MAX),
        @DeletedInSQL       INT,
        @UpdateRequired     BIT,
        @OutofSync          INT,
        @ProcessErrors      INT,
        @MFLastModifiedDate DATETIME,
        @Maxid              INT;

    -------------------------------------------------------------
    -- Get class id
    -------------------------------------------------------------
    SELECT @Class_ID = mc.MFID
    FROM dbo.MFClass                         mc
        INNER JOIN INFORMATION_SCHEMA.TABLES AS t
            ON mc.TableName = t.TABLE_NAME
    WHERE mc.TableName = @MFTableName;

    IF @Class_ID IS NOT NULL
    BEGIN
        IF @UpdateMethod = 1
        BEGIN

            -------------------------------------------------------------
            -- with table table set to 1
            -------------------------------------------------------------
            -------------------------------------------------------------
            -- Set last modified date to last update on class table or if class table is empty to full update
            -------------------------------------------------------------
            SET @StartTime = GETDATE();
            SET @ProcedureStep = N'Get last update date';
            SET @sqlParam = N'@MFLastModifiedDate Datetime output';
            SET @sql
                = N'
SELECT @MFLastModifiedDate = (SELECT isnull(MAX(' + QUOTENAME(@lastModifiedColumn) + N'),''1950-01-01'') FROM '
                  + QUOTENAME(@MFTableName) + N' );';

            IF @Debug > 0
                SELECT @sql;

            EXEC sys.sp_executesql @Stmt = @sql,
                @Params = @sqlParam,
                @MFLastModifiedDate = @MFLastModifiedDate OUTPUT;

            SET @DebugText = N' as ' + CAST(@MFLastModifiedDate AS NVARCHAR(25));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep) WITH NOWAIT;
            END;

            SET @Message
                = CASE
                      WHEN @WithTableAudit = 1 THEN
                          'Table audit started ' + CAST(@StartTime AS VARCHAR(30))
                      ELSE
                          'Batch update from ' + CAST(@FromObjid AS VARCHAR(10)) + ' to  '
                          + CAST(@ToObjid AS VARCHAR(30))
                  END;

            IF @WithStats = 1
                RAISERROR(@Message, 10, 1) WITH NOWAIT;

            -------------------------------------------------------------
            -- Setup temp tables for objids
            -------------------------------------------------------------
 /*           IF
            (
                SELECT OBJECT_ID('tempdb..#Objids')
            ) IS NOT NULL
                DROP TABLE #Objids;

            SELECT TOP 1000000
                n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.object_id))
            INTO #Objids
            FROM sys.all_objects           AS s1
                CROSS JOIN sys.all_objects AS s2
            OPTION (MAXDOP 1);

            CREATE UNIQUE CLUSTERED INDEX n ON #Objids (n);
*/
            -------------------------------------------------------------
            -- with accessing the audit table
            -------------------------------------------------------------            
            IF @WithTableAudit = 1
            BEGIN
                SET @ProcedureStep = N'Refresh table audit';

--                SELECT @MFLastModified = '1950-01-01';

                -------------------------------------------------------------
                -- Get object version result based on date
                -------------------------------------------------------------	    
                EXEC dbo.spMFTableAudit @MFTableName = @MFTableName,
                    @MFModifiedDate = @MFLastModified,
                    @ObjIDs = NULL,
                    @SessionIDOut = @SessionIDOut OUTPUT,
                    @NewObjectXml = @NewObjectXml OUTPUT,
                    @DeletedInSQL = @DeletedInSQL OUTPUT,
                    @UpdateRequired = @UpdateRequired OUTPUT,
                    @OutofSync = @OutofSync OUTPUT,
                    @ProcessErrors = @ProcessErrors OUTPUT,
                    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                    @Debug = 0;

                -------------------------------------------------------------
                -- Get records count
                -------------------------------------------------------------
                SELECT @RecCount = ISNULL(COUNT(ID), 0)
                FROM dbo.MFAuditHistory
                WHERE Class = @Class_ID;

                SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
                SET @Message
                    = N'MFAuditHistory : Processing time (s): '
                      + CAST((CONVERT(DECIMAL(18, 2), @ProcessingTime / 1000)) AS VARCHAR(10)) + N' Records %i';

                IF @WithStats = 1
                BEGIN
                    RAISERROR(@Message, 10, 1, @RecCount) WITH NOWAIT;
                END;
            END; --end with table audit

            -- en get audit objid
            -------------------------------------------------------------
            -- Get full list of object ids to update from tableAudit
            -------------------------------------------------------------
            SET @ProcedureStep = N'Get Objids';

            --IF
            --(
            --    SELECT COALESCE(COUNT(mah.ID), 0)
            --    FROM dbo.MFAuditHistory AS mah
            --    WHERE mah.Class = @Class_ID
            --) > 0
            --BEGIN
            --    SELECT @FromObjid = MIN(a.ObjID),
            --        @ToObjid      = MAX(a.ObjID)
            --    FROM dbo.MFAuditHistory a
            --    WHERE a.Class = @Class_ID;
            --END;
            SELECT @MaxRow = @ToObjid + 500;

            --    IF @WithTableAudit = 0
            SET @DebugText = N' From Objid %i to %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @FromObjid, @ToObjid);
            END;

            -------------------------------------------------------------
            -- Get number series
            -------------------------------------------------------------
            --SELECT COUNT(*) FROM #Objids AS o
            --SELECT @FromObjid, @MaxRow
     IF
            (
                SELECT OBJECT_ID('tempdb..#TableAuditList')
            ) IS NOT NULL
                DROP TABLE #TableAuditList;

                CREATE TABLE #TableAuditList
                (objid INT NOT NULL PRIMARY KEY)

   INSERT INTO #TableAuditList
            (
                Objid
            )
            /*            SELECT o.n
            FROM #Objids AS o
            WHERE o.n >= @FromObjid
                  AND o.n <= @MaxRow;
*/
            SELECT mah.ObjID
            FROM dbo.MFAuditHistory AS mah
            WHERE mah.Class = @Class_ID
                  AND mah.ObjID >= @FromObjid
                  AND mah.ObjID <= @ToObjid
                  AND mah.StatusFlag <> 0;

            SELECT @StartRow = ISNULL(MIN(tal.Objid), 0) , @MaxRow = ISNULL(max(tal.Objid), 0)
            FROM #TableAuditList AS tal;

            --         SELECT * FROM #TableAuditList AS tal
            -------------------------------------------------------------
            -- setup update batches
            -------------------------------------------------------------
            IF @Debug > 0
                SELECT @StartRow AS startrow,
                    @MaxRow      AS MaxRow;

            IF @StartRow IS NOT NULL
               AND @ToObjid >= @StartRow
            BEGIN

                --while loop
                WHILE @StartRow <= @MaxRow
                BEGIN
                    SET @StartTime = GETDATE();
                    SET @objids = NULL;
                    SET @Message
                        = N'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + N' Started: '
                          + CAST(@StartTime AS VARCHAR(30));

                    IF @WithStats = 1
                        RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SELECT @objids = STUFF(
                                     (
                                         SELECT TOP 500
                                             ',' + CAST(o.Objid AS NVARCHAR(20))
                                         FROM #TableAuditList AS o
                                         WHERE o.Objid >= @StartRow
                                         ORDER BY o.Objid
                                         FOR XML PATH('')
                                     ),
                                              1,
                                              1,
                                              ''
                                          )
                    FROM #TableAuditList AS o2
                    WHERE o2.Objid >= @StartRow
                    ORDER BY o2.Objid;

                    SET @ProcedureStep = N'Action spMFUpdateTable';

                    IF @Debug > 0
                        SELECT @objids AS Objids;

                    -------------------------------------------------------------
                    -- Update to/from m-files
                    -------------------------------------------------------------
                    SET @RecCount = 0;

                    IF @objids IS NOT NULL
                    BEGIN
                        EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName, -- nvarchar(200)
                            @UpdateMethod = 1,                                -- int
                            @ObjIDs = @objids,                                -- nvarchar(max)
                            @Update_IDOut = @Update_IDOut OUTPUT,             -- int
                            @ProcessBatch_ID = @ProcessBatch_ID,              -- int
                            @RetainDeletions = @RetainDeletions,
                            @Debug = 0;

                        SET @sqlParam = N'@RecCount int output';
                        SET @sql
                            = N'SELECT @RecCount = isnull(COUNT(id),0) FROM ' + @MFTableName + N' where update_ID ='
                              + CAST(@Update_IDOut AS VARCHAR(10)) + N'';

                        EXEC sys.sp_executesql @sql, @sqlParam, @RecCount OUTPUT;

                        IF @Debug > 0
                            SELECT @RecCount AS recordcount;
                    END;

                    -------------------------------------------------------------
                    -- performance message
                    -------------------------------------------------------------
                    SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
                    SET @Message
                        = N'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + N' Processing (s) : '
                          + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + N' From Object ID: '
                          + CAST(@StartRow AS VARCHAR(10)) + N' Processed: '
                          + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));

                    IF @WithStats = 1
                        RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SET @BatchCount = @BatchCount + 1;
                    SET @StartRow =
                    (
                        SELECT MAX(CAST(ListItem AS INT)) + 1
                        FROM dbo.fnMFParseDelimitedString(@objids, ',')
                    );
                END;

                IF @WithStats = 1
                   AND @Debug > 0
                BEGIN
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SELECT *
                    FROM dbo.MFvwAuditSummary AS mfas
                    WHERE mfas.TableName = @MFTableName;
                END;
            END;
            ELSE
            BEGIN
                SET @DebugText = N'Nothing to update';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END; -- startrow is null
        END;

        --end updatemehtod 1

        -------------------------------------------------------------
        -- UPDATE METHOD 0
        -------------------------------------------------------------
        IF @UpdateMethod = 0
        BEGIN
            SET @sqlParam = N'@Reccount int output';
            SET @sql
                = N'SELECT @RecCount = count(ISNULL(id,0)) FROM ' + QUOTENAME(@MFTableName)
                  + N' Where process_ID = 1 or process_ID = 99';

            IF @Debug > 0
                SELECT @sql AS SQL;

            EXEC sys.sp_executesql @stmt = @sql,
                @param = @sqlParam,
                @RecCount = @RecCount OUTPUT;

            IF @Debug > 0
                SELECT @RecCount AS RecCount;

            IF @RecCount > 0
            BEGIN
             

                --     SELECT @BatchestoRun = @RecCount / @BatchSize;
                SET @sql = N'
UPDATE ' +      QUOTENAME(@MFTableName) + N' 
SET [Process_ID] = 99 WHERE [Process_ID] = 1;';

                EXEC (@sql);

                WHILE @RecCount > 0
                BEGIN
                    SET @StartTime = GETDATE();
                    SET @Message
                        = N'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + N' Started: '
                          + CAST(@StartTime AS VARCHAR(30));

                    IF @WithStats = 1
                        --		PRINT @Message;
                        RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SET @sql
                        = N'UPDATE t
SET process_ID = 1
FROM ' +            QUOTENAME(@MFTableName) + N' t
INNER JOIN (SELECT TOP ' + CAST(@BatchSize AS NVARCHAR(5)) + N' ID FROM ' + +QUOTENAME(@MFTableName)
                          + N'   
WHERE [Process_ID] = 99 order by id asc) t2
ON t.id = t2.id
'                   ;

                    EXEC sys.sp_executesql @sql;

                    SET @sqlParam = N'@Maxid int output';
                    SET @sql = N'
SELECT @maxid = MAX(id) FROM ' + +QUOTENAME(@MFTableName) + N' AS [mlv] WHERE [mlv].[Process_ID] = 1';

                    IF @Debug > 0
                        SELECT @sql AS SQL;

                    EXEC sys.sp_executesql @stmt = @sql,
                        @param = @sqlParam,
                        @Maxid = @Maxid OUTPUT;

                    IF @Debug > 0
                        SELECT @sql AS SQL;

                    EXEC @return_value = dbo.spMFUpdateTable @MFTableName = @MFTableName, -- nvarchar(200)
                        @UpdateMethod = @UpdateMethod,                                    -- int
                        @Update_IDOut = @Update_IDOut OUTPUT,                             -- int
                        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,                       -- int
                        @Debug = 0;

                    --IF @return_value <> 1
                    --BEGIN
                    --    SET @DebugText = ' : Unable to update all records - batch processing terminated';
                    --    SET @DebugText = @DefaultDebugText + @DebugText;
                    --    SET @ProcedureStep = 'Updating M-Files';

                    --    RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                    --END;

                    -------------------------------------------------------------
                    -- performance message
                    -------------------------------------------------------------
                    SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
                    SET @Message
                        = N'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + N' Processing (s) : '
                          + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + N' Ids up to : '
                          + CAST(ISNULL(@Maxid, 0) AS VARCHAR(10)) + N' remaining count: '
                          + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));
                    SET @sqlParam = N'@RecCount int output';
                    SET @sql
                        = N'SELECT @RecCount = COUNT(ISNULL(id,0)) FROM ' + QUOTENAME(@MFTableName)
                          + N' AS [mbs] WHERE process_ID = 99';

                    EXEC sys.sp_executesql @sql, @sqlParam, @RecCount OUTPUT;

                    IF @Debug > 0
                        SELECT @RecCount AS nextbatch;

                    IF @WithStats = 1
                        --	PRINT @Message;
                        RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SET @StartTime = GETUTCDATE();


                    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                        @LogType = N'Debug',
                        @LogText = @Message,
                        @LogStatus = @LogStatus,
                        @StartTime = @StartTime,
                        @MFTableName = @MFTableName,
                        @Validation_ID = @Validation_ID,
                        @ColumnName = NULL,
                        @ColumnValue = NULL,
                        @Update_ID = @Update_IDOut,
                        @LogProcedureName = @ProcedureName,
                        @LogProcedureStep = @ProcedureStep,
                        @debug = 0;

                    SET @BatchCount = @BatchCount + 1;
                END; --end loop updatetable
            END; --RecCount > 0
        END; --Update method = 0
    END; -- class table null
    ELSE
    BEGIN
        SET @DebugText = N' Invalid table name or table does not exist: ' + @MFTableName;
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;

    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = N'End';
    SET @LogStatus = N'Completed';

    -------------------------------------------------------------
    -- Log End of Process
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
        @ProcessType = @ProcessType,
        @LogType = N'Message',
        @LogText = @LogText,
        @LogStatus = @LogStatus,
        @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = N'Debug',
        @LogText = @ProcessType,
        @LogStatus = @LogStatus,
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = NULL,
        @ColumnValue = NULL,
        @Update_ID = @Update_IDOut,
        @LogProcedureName = @ProcedureName,
        @LogProcedureStep = @ProcedureStep,
        @debug = 0;

    RETURN 1;
END TRY
BEGIN CATCH
    SET @StartTime = GETUTCDATE();
    SET @LogStatus = N'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
    INSERT INTO dbo.MFLog
    (
        SPName,
        ErrorNumber,
        ErrorMessage,
        ErrorProcedure,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ProcedureStep
    )
    VALUES
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
        @ProcedureStep);

    SET @ProcedureStep = N'Catch Error';

    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = N'Error',
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatus,
        @debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = N'Error',
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatus,
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = NULL,
        @ColumnValue = NULL,
        @Update_ID = @Update_ID,
        @LogProcedureName = @ProcedureName,
        @LogProcedureStep = @ProcedureStep,
        @debug = 0;

    RETURN -1;
END CATCH;
GO