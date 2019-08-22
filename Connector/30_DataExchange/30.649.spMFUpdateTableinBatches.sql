PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableinBatches]';
GO

SET NOCOUNT ON;
GO

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFUpdateTableinBatches' -- nvarchar(100)
                                    ,@Object_Release = '4.4.12.52'             -- varchar(50)
                                    ,@UpdateFlag = 2;                          -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
	Create date: 15/12/2018
	Database:
	Description: Procedure to update class table in batches

Updating a large number of records from a specific class in MF to SQL in batches 

it is advisable to process updates of large datasets in batches.  
Processing batches will ensure that a logical restart point can be determined in case of failure
It will also keep the size of the dataset for transfer within the limits of 8000 bites.

	PARAMETERS:
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION

	updated version 2018-12-15
	2019-06-22	LC			substantially rebuilt to improve efficiencies
	2019-08-05	LC			resolve issue with catching last object if new and only one object exist

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateTableinBatches' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

CREATE PROCEDURE [dbo].[spMFUpdateTableinBatches]
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFUpdateTableinBatches]
(
    @MFTableName NVARCHAR(100)
   ,@UpdateMethod INT = 1
   ,@WithTableAudit INT = 0
   ,@FromObjid BIGINT = 1
   ,@ToObjid BIGINT = 100000
   ,@WithStats BIT = 1 -- set to 0 to suppress display messages
   ,@ProcessBatch_ID INT = NULL
   ,@Debug INT = 0     --
)
AS
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
DECLARE @ProcessBatchSize INT = 250;

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
DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFUpdateTableInBatches';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
DECLARE @Msg AS NVARCHAR(256) = '';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- VARIABLES: LOGGING
-------------------------------------------------------------
DECLARE @LogType AS NVARCHAR(50) = 'Status';
DECLARE @LogText AS NVARCHAR(4000) = '';
DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress';
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
SET @ProcedureStep = 'Start Logging';
SET @LogText = 'Processing ' + @ProcedureName;

EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                    ,@ProcessType = @ProcessType
                                    ,@LogType = N'Status'
                                    ,@LogText = @LogText
                                    ,@LogStatus = N'In Progress'
                                    ,@debug = @Debug;

EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                          ,@LogType = N'Debug'
                                          ,@LogText = @ProcessType
                                          ,@LogStatus = N'Started'
                                          ,@StartTime = @StartTime
                                          ,@MFTableName = @MFTableName
                                          ,@Validation_ID = @Validation_ID
                                          ,@ColumnName = NULL
                                          ,@ColumnValue = NULL
                                          ,@Update_ID = @Update_ID
                                          ,@LogProcedureName = @ProcedureName
                                          ,@LogProcedureStep = @ProcedureStep
                                          ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT
                                          ,@debug = 0;

BEGIN TRY
    -- Debug params
    SET @ProcedureStep = 'Initialise';

    --BEGIN  
    SET @DebugText = '';
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

    SELECT @lastModifiedColumn = [mp].[ColumnName]
    FROM [dbo].[MFProperty] AS [mp]
    WHERE [mp].[MFID] = 21;

    --'Last Modified'

    -------------------------------------------------------------
    -- calculate batch size
    -------------------------------------------------------------
    DECLARE @BatchSize INT;
    -- sizes is restricted by objid length.

    --other parameters 
    DECLARE @StartRow       INT
           ,@MaxRow         INT
           ,@RecCount       INT
           ,@BatchCount     INT           = 1
           ,@UpdateID       INT
           ,@ProcessingTime INT
           ,@objids         NVARCHAR(4000)
           ,@Message        NVARCHAR(100)
           ,@Class_ID       INT;
    DECLARE @SessionIDOut       INT
           ,@NewObjectXml       NVARCHAR(MAX)
           ,@DeletedInSQL       INT
           ,@UpdateRequired     BIT
           ,@OutofSync          INT
           ,@ProcessErrors      INT
           ,@MFLastModifiedDate DATETIME
           ,@Maxid              INT;

    -------------------------------------------------------------
    -- UPDATE METHOD 1
    -------------------------------------------------------------
    IF @UpdateMethod = 1
    BEGIN
        --   SELECT @BatchSize = 4000 / (LEN(@maxObjid) + 1);
        SELECT @BatchSize = 500;

        --start
        --    SET @StartRow = @MinObjid;
        --   SET @MaxRow = @StartRow + (@BatchSize * @BatchestoRun);
        --    SET @SQLParam = N'@Objids nvarchar(4000) output';

        -------------------------------------------------------------
        -- Get class id
        -------------------------------------------------------------
        SELECT @Class_ID = [mc].[MFID]
        FROM [dbo].[MFClass]                         [mc]
            INNER JOIN [INFORMATION_SCHEMA].[TABLES] AS [t]
                ON [mc].[TableName] = [t].[TABLE_NAME]
        WHERE [mc].[TableName] = @MFTableName;

        IF @Class_ID IS NOT NULL
        BEGIN
            -------------------------------------------------------------
            --	Perform table audit
            -------------------------------------------------------------
            --    SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
            --    SET @Message = CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + ' Batch updated started ';

            --  SET @StartTime = GETDATE();
            --        SET @objids = NULL;
            --        SET @Message
            --            = ' Batch updated started ' + CAST(@StartTime AS VARCHAR(30));

            --IF @WithStats = 1
            --    RAISERROR(@Message, 10, 1) WITH NOWAIT;
   
   -------------------------------------------------------------
   -- with table table set to 1
   -------------------------------------------------------------
                 SET @StartTime = GETDATE();    
	        IF @WithTableAudit = 1
            BEGIN

                SET @objids = NULL;
                SET @Message = 'Table audit started ' + CAST(@StartTime AS VARCHAR(30));

                IF @WithStats = 1
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                SET @ProcedureStep = 'Get last update date';
                SET @sqlParam = N'@MFLastModifiedDate Datetime output';
                SET @sql
                    = N'
SELECT @MFLastModifiedDate = (SELECT MAX(' + QUOTENAME(@lastModifiedColumn) + ') FROM ' + QUOTENAME(@MFTableName)
                      + ' );';

                EXEC [sys].[sp_executesql] @Stmt = @sql
                                          ,@Params = @sqlParam
                                          ,@MFLastModifiedDate = @MFLastModifiedDate OUTPUT;

                SET @DebugText = ' as ' + CAST(@MFLastModifiedDate AS NVARCHAR(25));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep) WITH NOWAIT;
                END;

                SET @ProcedureStep = 'Refresh table audit';

             
                BEGIN
                    EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = @MFTableName -- nvarchar(100)
                                                        ,@FromObjid = @FromObjid     -- int
                                                        ,@ToObjid = @ToObjid         -- int
                                                        ,@WithStats = @WithStats     -- bit
														,@ProcessBatch_ID = @ProcessBatch_ID 
                                                        ,@Debug = 0-- @Debug;            -- int
                END;

           

                IF @Debug > 0
                    SELECT *
                    FROM [dbo].[MFvwMetadataStructure] AS [mfms]
                    WHERE [mfms].[class_MFID] = @Class_ID;
            END;


            -------------------------------------------------------------
            -- Get full list of object ids to update from tableAudit
            -------------------------------------------------------------
            SET @ProcedureStep = 'Get Objids';

            DECLARE @TableAuditList AS TABLE
            (
                [Objid] INT
            );

            IF
            (
                SELECT COUNT(*)
                FROM [dbo].[MFAuditHistory] AS [mah]
                WHERE [mah].[Class] = @Class_ID
            ) = 0
            BEGIN
                IF
                (
                    SELECT OBJECT_ID('tempdb..#Objids')
                ) IS NOT NULL
                    DROP TABLE [#Objids];

                SELECT TOP (2000000)
                       [n] = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY [s1].[object_id]))
                INTO [#Objids]
                FROM [sys].[all_objects]           AS [s1]
                    CROSS JOIN [sys].[all_objects] AS [s2]
                OPTION (MAXDOP 1);

                CREATE UNIQUE CLUSTERED INDEX [n]
                ON [#Objids] ([n])
                -- WITH (DATA_COMPRESSION = PAGE)
                ;

                INSERT INTO @TableAuditList
                (
                    [Objid]
                )
                SELECT [o].[n]
                FROM [#Objids] AS [o]
                WHERE [o].[n]
                BETWEEN @FromObjid AND @ToObjid;
            END;
            ELSE
            BEGIN
                INSERT INTO @TableAuditList
                (
                    [Objid]
                )
                SELECT [mah].[ObjID]
                FROM [dbo].[MFAuditHistory] AS [mah]
                WHERE [mah].[StatusFlag] IN ( 1, 4, 5 )
                      AND [mah].[Class] = @Class_ID;
            END;

            SELECT @RecCount = COUNT(*)
            FROM @TableAuditList AS [tal];

            SET @DebugText = ' Objid count %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RecCount);
            END;

			     SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
                SET @Message
                    = 'MFAuditHistory updated in batches: Processing time (s): '
                      + CAST((CONVERT (decimal(18,2),@ProcessingTime /1000 )) AS VARCHAR(10)) + ' Records %i';

                IF @WithStats = 1
                BEGIN
                    RAISERROR(@Message, 10, 1,@RecCount) WITH NOWAIT;
                END;

            SELECT @StartRow = MIN(ISNULL([tal].[Objid],1))
                  ,@MaxRow   = MAX([tal].[Objid]) + 500
            FROM @TableAuditList AS [tal];

            IF @Debug > 0
                SELECT @StartRow AS [startrow]
                      ,@MaxRow   AS [MaxRow];

            IF @StartRow IS NOT NULL
            BEGIN

                --while loop
                WHILE @StartRow < @MaxRow
                BEGIN
                    SET @StartTime = GETDATE();
                    SET @objids = NULL;
                    SET @Message
                        = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Started: ' + CAST(@StartTime AS VARCHAR(30));

                    IF @WithStats = 1
                        RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SET @objids = NULL;

                    SELECT @objids = STUFF((
                                               SELECT TOP 500
                                                      ',' + CAST([o].[Objid] AS NVARCHAR(20))
                                               FROM @TableAuditList AS [o]
                                               WHERE [o].[Objid] >= @StartRow
                                               ORDER BY [Objid]
                                               FOR XML PATH('')
                                           )
                                          ,1
                                          ,1
                                          ,''
                                          )
                    FROM @TableAuditList AS [o2]
                    WHERE [o2].[Objid] >= @StartRow
                    ORDER BY [o2].[Objid];

                    IF @Debug > 0
                        SELECT @objids AS [Objids];

                    -------------------------------------------------------------
                    -- Update to/from m-files
                    -------------------------------------------------------------
                    IF @objids IS NOT NULL
                    BEGIN
                        EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName          -- nvarchar(200)
                                                    ,@UpdateMethod = 1                    -- int
                                                    ,@ObjIDs = @objids                    -- nvarchar(max)
                                                    ,@Update_IDOut = @Update_IDOut OUTPUT -- int
                                                    ,@ProcessBatch_ID = @ProcessBatch_ID  -- int
                                                    ,@Debug = 0;

                        SET @sqlParam = '@RecCount int output';
                        SET @sql
                            = 'SELECT @RecCount = COUNT(*) FROM ' + @MFTableName + ' where update_ID ='
                              + CAST(@Update_IDOut AS VARCHAR(10)) + '';

                        EXEC [sys].[sp_executesql] @sql, @sqlParam, @RecCount OUTPUT;

                        IF @Debug > 0
                            SELECT @RecCount AS [recordcount];
                    END;

                    -------------------------------------------------------------
                    -- performance message
                    -------------------------------------------------------------
                    SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
                    SET @Message
                        = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Processing (s) : '
                          + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + ' From Object ID: '
                          + CAST(@StartRow AS VARCHAR(10)) + ' Processed: ' + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));

                    IF @WithStats = 1
                        RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SET @BatchCount = @BatchCount + 1;
                    SET @StartRow =
                    (
                        SELECT MAX([ListItem]) + 1
                        FROM [dbo].[fnMFParseDelimitedString](@objids, ',')
                    );
                END;

                IF @WithStats = 1
                   AND @Debug > 0
                BEGIN
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                    SELECT *
                    FROM [dbo].[MFvwAuditSummary] AS [mfas]
                    WHERE [mfas].[TableName] = @MFTableName;
                END;
            END;
            ELSE
            BEGIN
                SET @DebugText = 'Nothing to update';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END; -- startrow is null
        END;
        ELSE
        BEGIN
            SET @DebugText = ' Invalid table name or table does not exist: ' + @MFTableName;
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;
    END;

    -------------------------------------------------------------
    -- UPDATE METHOD 0
    -------------------------------------------------------------
    IF @UpdateMethod = 0
    BEGIN
        SET @sqlParam = N'@Reccount int output';
        SET @sql
            = N'SELECT @RecCount = count(*) FROM ' + QUOTENAME(@MFTableName)
              + ' Where process_ID = 1 or process_ID = 99';

        IF @Debug > 0
            SELECT @sql AS [SQL];

        EXEC [sys].[sp_executesql] @stmt = @sql
                                  ,@param = @sqlParam
                                  ,@RecCount = @RecCount OUTPUT;

        IF @Debug > 0
            SELECT @RecCount AS [RecCount];

        IF @RecCount > 0
        BEGIN
            SELECT @BatchSize = 500;

            --     SELECT @BatchestoRun = @RecCount / @BatchSize;
            SET @sql = N'
UPDATE ' +  QUOTENAME(@MFTableName) + ' 
SET [Process_ID] = 99 WHERE [Process_ID] = 1;';

            EXEC (@sql);

            WHILE @RecCount > 0
            BEGIN
                SET @StartTime = GETDATE();
                SET @Message
                    = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Started: ' + CAST(@StartTime AS VARCHAR(30));

                IF @WithStats = 1
                    --		PRINT @Message;
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                SET @sql
                    = N'UPDATE t
SET process_ID = 1
FROM ' +        QUOTENAME(@MFTableName) + ' t
INNER JOIN (SELECT TOP ' + CAST(@BatchSize AS NVARCHAR(5)) + ' ID FROM ' + +QUOTENAME(@MFTableName)
                      + '   
WHERE [Process_ID] = 99 order by id asc) t2
ON t.id = t2.id
'               ;

                EXEC [sys].[sp_executesql] @sql;

                SET @sqlParam = N'@Maxid int output';
                SET @sql = N'
SELECT @maxid = MAX(id) FROM ' + +QUOTENAME(@MFTableName) + ' AS [mlv] WHERE [mlv].[Process_ID] = 1';

                IF @Debug > 0
                    SELECT @sql AS [SQL];

                EXEC [sys].[sp_executesql] @stmt = @sql
                                          ,@param = @sqlParam
                                          ,@Maxid = @Maxid OUTPUT;

                IF @Debug > 0
                    SELECT @sql AS [SQL];

                EXEC @return_value = [dbo].[spMFUpdateTable] @MFTableName = @MFTableName                -- nvarchar(200)
                                                            ,@UpdateMethod = @UpdateMethod              -- int
                                                            ,@Update_IDOut = @Update_IDOut OUTPUT       -- int
                                                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                                            ,@Debug = 0;

                IF @return_value <> 1
                BEGIN
                    SET @DebugText = ' : Unable to update all records - batch processing terminated';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Updating M-Files';

                    RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- performance message
                -------------------------------------------------------------
                SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
                SET @Message
                    = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Processing (s) : '
                      + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + ' Ids up to : '
                      + CAST(ISNULL(@Maxid, 0) AS VARCHAR(10)) + ' remaining count: '
                      + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));
                SET @sqlParam = N'@RecCount int output';
                SET @sql
                    = N'SELECT @RecCount = COUNT(*) FROM ' + QUOTENAME(@MFTableName)
                      + ' AS [mbs] WHERE process_ID = 99';

                EXEC [sys].[sp_executesql] @sql, @sqlParam, @RecCount OUTPUT;

                IF @Debug > 0
                    SELECT @RecCount AS [nextbatch];

                IF @WithStats = 1
                    --	PRINT @Message;
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                SET @BatchCount = @BatchCount + 1;
            END; --end loop updatetable
        END; --RecCount > 0
    END;

    --Update method = 0

    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = 'End';
    SET @LogStatus = 'Completed';

    -------------------------------------------------------------
    -- Log End of Process
    -------------------------------------------------------------   
    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Message'
                                        ,@LogText = @LogText
                                        ,@LogStatus = @LogStatus
                                        ,@debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Debug'
                                              ,@LogText = @ProcessType
                                              ,@LogStatus = @LogStatus
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = @Validation_ID
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = @Update_ID
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @ProcedureStep
                                              ,@debug = 0;

    RETURN 1;
END TRY
BEGIN CATCH
    SET @StartTime = GETUTCDATE();
    SET @LogStatus = 'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
    INSERT INTO [dbo].[MFLog]
    (
        [SPName]
       ,[ErrorNumber]
       ,[ErrorMessage]
       ,[ErrorProcedure]
       ,[ErrorState]
       ,[ErrorSeverity]
       ,[ErrorLine]
       ,[ProcedureStep]
    )
    VALUES
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE()
    ,@ProcedureStep);

    SET @ProcedureStep = 'Catch Error';

    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Error'
                                        ,@LogText = @LogTextDetail
                                        ,@LogStatus = @LogStatus
                                        ,@debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Error'
                                              ,@LogText = @LogTextDetail
                                              ,@LogStatus = @LogStatus
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = @Validation_ID
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = @Update_ID
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @ProcedureStep
                                              ,@debug = 0;

    RETURN -1;
END CATCH;
GO