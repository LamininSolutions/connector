PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateObjectChangeHistory]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateObjectChangeHistory', -- nvarchar(100)
    @Object_Release = '4.7.18.58',
    @UpdateFlag = 2;
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateObjectChangeHistory' --name of procedure
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

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFUpdateObjectChangeHistory
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateObjectChangeHistory
(
    @MFTableName NVARCHAR(200) = NULL,
    @WithClassTableUpdate INT = 1,
    @Objids NVARCHAR(MAX) = NULL,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS

/*rST**************************************************************************

=============================
spMFUpdateObjectChangeHistory
=============================

Return
  - 1 = Success
  - -1 = Error

  @MFTableName nvarchar(200)
  Class table name to be updated
  If null then all class tables in MFObjectChangeHistoryUpdateControl table is included.

  @WithClassTableUpdate int
  - Default = 1 (yes)  

  @Objids nvarchar(4000)
  - comma delimited list of objids to be included 
  - if null then all objids for the class is included

  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

To process change history for a single or all class tables and property combinations 

Additional Info
===============

Update MFObjectChangeHistoryUpdatecontrol for each class and property to be included in the update. Use separate rows for for each property to be included. A class may have multiple rows if multiple properties are to be processed for the tables.

The routine is designed to get the last updated date for the property and the class from the MFObjectChangeHistory table. The next update will only update records after this date.

Delete the records for the class and the property to reset the records in the table MFObjectChangeHistory or to force updates prior to the last update date

This procedure is included in spMFUpdateMFilesToSQL and spMFUpdateAllIncludedInAppTables routines.  This allows for scheduling these procedures in an agent or another procedure to ensure that all the updates in the App is included.  

spMFUpdateObjectChangeHistory can be run on its own, either by calling it using the Context menu Actions, or any other method.

Prerequisites
=============

The table MFObjectChangeHistoryUpdatecontrol must be updated before this procedure will work

Include this procedure in an agent to schedule to update.

Warnings
========

Do not specify more than one property for a single update, rather specify a separate row for each property.

Examples
========

.. code:: sql

	INSERT INTO dbo.MFObjectChangeHistoryUpdateControl
	(
		MFTableName,
		ColumnNames
	)
	VALUES
	(   N'MFCustomer', 
		N'State_ID'  
		),
	(   N'MFPurchaseInvoice', 
		N'State_ID'  
		)

----updating a class table for specific objids

.. code:: sql

    exec spMFUpdateObjectChangeHistory @MFTableName = 'MFCustomer', @WithClassTableUpdate = 1, @ObjIDs = '1,2,3', @Debug = 0

----updating all class tables (including updating the class table)

.. code:: sql

    exec spMFUpdateObjectChangeHistory @MFTableName = null, @WithClassTableUpdate = 1, @ObjIDs = null, @Debug = 0

    or

    exec spMFUpdateObjectChangeHistory 
    @WithClassTableUpdate = 0, 
    @Debug = 0

    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-06-26  LC         added additional exception management
2020-05-06  LC         Validate the column in control table
2020-03-06  LC         Add MFTableName and objids - run per table
2019-11-04  LC         Create procedure

==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Change History Update');

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
    DECLARE @MFLastModified DATETIME;
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
    DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFUpdateObjectChangeHistory';
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
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Setup ennvironment';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        DECLARE @params NVARCHAR(MAX);
        DECLARE @Process_ID INT = 5;
        DECLARE @ColumnNames NVARCHAR(4000);
        DECLARE @RC INT;
        DECLARE @IsFullHistory BIT = 1;
        DECLARE @NumberOFDays INT;
        DECLARE @StartDate DATETIME; --= DATEADD(DAY,-1,GETDATE())
        DECLARE @ID INT;
        DECLARE @MFID INT;
        DECLARE @ObjectType_ID INT;
        DECLARE @Property_IDs NVARCHAR(MAX);

        -------------------------------------------------------------
        -- Create table update list
        -------------------------------------------------------------
        DECLARE @UpdateList AS TABLE
        (
            ID INT IDENTITY,
            MFTableName NVARCHAR(200),
            ColumnNames NVARCHAR(MAX),
            PropertyIDs NVARCHAR(MAX)
        );

        INSERT INTO @UpdateList
        (
            MFTableName,
            ColumnNames,
            PropertyIDs
        )
        SELECT mochuc.MFTableName,
            STUFF(
            (
                SELECT DISTINCT
                    ',' + fmpds.ListItem
                FROM dbo.MFObjectChangeHistoryUpdateControl                            AS mochuc2
                    CROSS APPLY dbo.fnMFParseDelimitedString(mochuc2.ColumnNames, ',') AS fmpds
                    INNER JOIN dbo.MFProperty AS mp
                        ON fmpds.ListItem = mp.ColumnName
                WHERE mochuc2.MFTableName = mochuc.MFTableName
                FOR XML PATH('')
            ),
                     1,
                     1,
                     ''
                 ),
            STUFF(
            (
                SELECT DISTINCT
                    ',' + CAST(mp.MFID AS VARCHAR(10))
                FROM dbo.MFObjectChangeHistoryUpdateControl                        AS htu
                    CROSS APPLY dbo.fnMFParseDelimitedString(htu.ColumnNames, ',') AS fmpds
                    INNER JOIN dbo.MFProperty mp
                        ON fmpds.ListItem = mp.ColumnName
                WHERE htu.MFTableName = mochuc.MFTableName
                FOR XML PATH('')
            ),
                     1,
                     1,
                     ''
                 )
        FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc
            INNER JOIN dbo.MFClass                  AS mc
                ON mochuc.MFTableName = mc.TableName
        WHERE mochuc.MFTableName = @MFTableName
              OR @MFTableName IS NULL
        GROUP BY mochuc.MFTableName;

        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Get updatelist';

        IF @Debug > 0
        BEGIN
            SELECT *
            FROM @UpdateList AS ul;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SELECT @ID = MIN(htu.ID)
        FROM @UpdateList AS htu;

        SET @params = N'@Process_id int';

        IF ISNULL(@ID, 0) > 0
        BEGIN
            WHILE @ID IS NOT NULL
            BEGIN
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Begin Loop through tables ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- Reset variables
                -------------------------------------------------------------
                SET @StartDate = NULL;
                -------------------------------------------------------------
                -- Get table details
                -------------------------------------------------------------
                SET @ProcedureStep = N'Get Table variables';

                SELECT @MFTableName = htu.MFTableName,
                    @ColumnNames    = htu.ColumnNames,
                    @Property_IDs   = htu.PropertyIDs
                FROM @UpdateList AS htu
                WHERE htu.ID = @ID;

                -------------------------------------------------------------
                -- Validate columns in control table
                -------------------------------------------------------------


                IF @Debug > 0
                BEGIN
                SELECT *
                FROM dbo.MFObjectChangeHistoryUpdateControl AS mochuc;
                    SELECT PropertyIDS = @Property_IDs;

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @Property_IDs IS NULL
                Begin
                                SET @DebugText = N':Invalid Column in dbo.MFObjectChangeHistoryUpdateControl ';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Validate columns for history  ';

                       RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                END
                -------------------------------------------------------------
                -- Update table
                -------------------------------------------------------------
                IF @WithClassTableUpdate = 1
                BEGIN
                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Update class Table included';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    SET @sql = N'UPDATE t
Set process_id = 0 
FROM ' +            QUOTENAME(@MFTableName) + N't
WHERE process_id = ' + CAST(@Process_ID AS VARCHAR(10)) + N';';

                    EXEC (@sql);

                    DECLARE @MFLastUpdateDate SMALLDATETIME,
                        @Update_IDOut         INT,
                        @ProcessBatch_ID1     INT;

                    EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName, -- nvarchar(128)
                        @MFLastUpdateDate = @MFLastUpdateDate OUTPUT,             -- smalldatetime
                        @UpdateTypeID = 1,                                        -- tinyint
                        @Update_IDOut = @Update_IDOut OUTPUT,                     -- int
                        @ProcessBatch_ID = @ProcessBatch_ID1 OUTPUT,              -- int
                        @debug = 0;                                               -- tinyint

                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N'Class Table update completed';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;

                --end with Table update

                -------------------------------------------------------------
                -- Get @startDate
                -------------------------------------------------------------
                SET @ProcedureStep = N'Get Start date ';
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @MFID       = mc.MFID,
                    @ObjectType_ID = ot.MFID
                FROM dbo.MFClass                AS mc
                    INNER JOIN dbo.MFObjectType ot
                        ON mc.MFObjectType_ID = ot.ID
                WHERE mc.TableName = @MFTableName;

                --               SELECT * FROM dbo.MFObjectChangeHistory AS moch
                SELECT @StartDate = MAX(moch.LastModifiedUtc)
                FROM dbo.MFObjectChangeHistory AS moch
                WHERE moch.ObjectType_ID = @ObjectType_ID
                      AND moch.Class_ID = @MFID
                      AND moch.Property_ID IN
                          (
                              SELECT Item FROM dbo.fnMFSplitString(@Property_IDs, ',')
                          );

                SELECT @StartDate = DATEADD(DAY, -1, ISNULL(@StartDate, '2000-01-01'));

                SELECT @IsFullHistory = CASE
                                            WHEN @StartDate > '2000-01-01' THEN
                                                0
                                            ELSE
                                                1
                                        END;

                SET @ProcedureStep = N'Get from date ';
                SET @DebugText = CAST(@StartDate AS NVARCHAR(30));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- Get count of class table records, if > 10 000 then batch history update
                -------------------------------------------------------------
                SET @params = N'@Count int output';
                SET @sql = N'SELECT @count = COUNT(*) FROM ' + QUOTENAME(@MFTableName) + N' t;';

                EXEC sys.sp_executesql @sql, @params, @count OUTPUT;

                SET @DebugText
                    = N'Full history : ' + CAST(@IsFullHistory AS NVARCHAR(30)) + N' Total records: '
                      + CAST(@count AS NVARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;

                --               SET @ProcedureStep = N'Updating change history ';
                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- Set objects to update in batch mode with batch size of ???
                -------------------------------------------------------------
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Get objids ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @Objids IS NOT NULL
                BEGIN
                    SET @params = N'@Process_id int, @ObjIds nvarchar(max)';
                    SET @sql
                        = N'
UPDATE t
SET Process_ID = @Process_ID
FROM ' +            QUOTENAME(@MFTableName)
                          + N' t
where objid in (Select item from dbo.fnMFSplitString(@objIds,'',''))
;'                  ;

                    --PRINT @SQL
                    EXEC sys.sp_executesql @sql, @params, @Process_ID, @Objids;

                    SET @DebugText = N'Filtered ' + ISNULL(@Objids, '');
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;
                ELSE
                BEGIN
                    SET @params = N'@Process_id int';
                    SET @sql = N'
UPDATE t
SET Process_ID = @Process_ID
FROM ' +            QUOTENAME(@MFTableName) + N' t
;'                  ;

                    EXEC sys.sp_executesql @sql, @params, @Process_ID;

                    SET @DebugText = N'All objects ';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;

                --end else all objids   
                -------------------------------------------------------------
                -- Get history
                -------------------------------------------------------------
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Get history with spmfGetObjectHistory';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SET @sqlParam = N'@rowcount int output';
                SET @sql = N'SELECT @rowcount = COUNT(*) FROM ' + QUOTENAME(@MFTableName) + N'
   WHERE Process_ID = '    + CAST(@Process_ID AS VARCHAR(10)) + N'';

                EXEC sys.sp_executesql @sql, @sqlParam, @rowcount OUTPUT;

                SET @DebugText = N': process_id count %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                END;

                IF @rowcount > 0
                Begin
                --SELECT FullHistory = @IsFullHistory,
                --       StartDate = @StartDate;
                EXEC @return_value = dbo.spMFGetHistory @MFTableName = @MFTableName, -- nvarchar(128)
                    @Process_id = @Process_ID,                                       -- int
                    @ColumnNames = @ColumnNames,                                     -- nvarchar(4000)
                    @SearchString = NULL,                                            -- nvarchar(4000)
                    @IsFullHistory = @IsFullHistory,                                 -- bit
                    @NumberOFDays = @NumberOFDays,                                   -- int
                    @StartDate = @StartDate,                                         -- datetime
                    @Update_ID = @Update_ID OUTPUT,                                  -- int
                    @ProcessBatch_id = @ProcessBatch_ID OUTPUT,                      -- int
                    @Debug = @Debug;                                                 -- int

     IF @debug > 0
     SELECT @return_value AS ReturnValue;

                IF  @return_value <> 1
                Begin
                 SET @DebugText = N': spMFGetHistory failed return value ' + CAST(@return_value AS VARCHAR(5));
                SET @DebugText = @DefaultDebugText + @DebugText;
                    RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                END --ifdebug

                  END --if rowcount > 0

                SET @DebugText = @MFTableName + N' records updated: ' + CAST(@rowcount AS VARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N'Get history ';

               

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @ID =
                (
                    SELECT MIN(htu.ID) FROM @UpdateList AS htu WHERE htu.ID > @ID
                );
            END;
        END;

        --end if ChangeHistoryUpdatecontrol exist

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
            @LogType = N'Debug',
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
            @Update_ID = @Update_ID,
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
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
            ERROR_LINE(), @ProcedureStep);

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
END;
GO