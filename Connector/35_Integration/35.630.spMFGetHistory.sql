
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetHistory]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFGetHistory',
    -- nvarchar(100)
    @Object_Release = '4.11.33.77',
    -- varchar(50)
    @UpdateFlag = 2;
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFGetHistory' --name of procedure
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

CREATE PROCEDURE dbo.spMFGetHistory
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFGetHistory
(
    @MFTableName NVARCHAR(128),
    @Process_id INT = 5,
    @ColumnNames NVARCHAR(4000),
    @SearchString NVARCHAR(4000) = NULL,
    @IsFullHistory BIT = 1,
    @NumberOFDays INT = NULL,
    @StartDate DATETIME = NULL,
    @Update_ID INT = NULL OUTPUT,
    @ProcessBatch_id INT = NULL OUTPUT,
    @Debug INT = 0
)
AS
/*rST**************************************************************************

==============
spMFGetHistory
==============

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(128)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @Process\_id int
    - Set process_id in the class table for records to be selected
    - Use process_id not in (1-4) e.g. 5
  @ColumnNames nvarchar(4000)
    - The column (Property) to be included in the export 
  @IsFullHistory bit
    - Default = 1
    - 1 will include all the changes of the object for the specified column names
    - Set to 0 to specify any of the other filters
  @SearchString nvarchar(4000)
    - Search for objects included in the object select and property selection with a specific value
    - Search is a 'contain' search
  @NumberOFDays int
    - Set this to show the last x number of days of changes
  @StartDate datetime
    - set to a specific date to only show change history from a specific date (e.g. for the last month)
  @ProcessBatch\_id int (output)
    - Processbatch id for logging
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Allows to update MFObjectChangeHistory table with the change history of the specific property of the object based on certain filters

Additional Info
===============

When the history table is updated it will only report the versions that the property was changed. If the property included in the filter did not change, then to specific version will not be recorded in the table.

Process_id is reset to 0 after completion of the processing.

Use Cases(s)

- Show comments made on object
- Show a state was entered and exited
- Show when a property was changed
- Discovery reports for changes to certain properties

Using a search criteria is not yet active.

Prerequisites
=============

Set process_id in the class table to 5 for all the records to be included

Warnings
========

The columnname must match the property in the ColumnName column of MFProperty

Note that the same filter will apply to all the columns included in the run.  Split the get procedure into different runs if different filters must be applied to different columns.

Producing on the history for all objects in a large table could take a considerable time to complete. Use the filters to limit restrict the number of records to fetch from M-Files to optimise the search time.


Examples
========

This procedure can be used to show all the comments  or the last 5 comments made for a object.  It is also handly to assess when a workflow state was changed

.. code:: sql

    UPDATE mfcustomer
    SET Process_ID = 5
    FROM MFCustomer  WHERE id in (9,10)

    DECLARE @RC INT
    DECLARE @TableName NVARCHAR(128) = 'MFCustomer'
    DECLARE @Process_id INT = 5
    DECLARE @ColumnNames NVARCHAR(4000) = 'Address_Line_1,Country'
    DECLARE @IsFullHistory BIT = 1
    DECLARE @NumberOFDays INT
    DECLARE @StartDate DATETIME --= DATEADD(DAY,-1,GETDATE())
    DECLARE @ProcessBatch_id INT
    DECLARE @Debug INT = 0
    DECLARE @Update_ID int

    EXECUTE @RC = [dbo].[spMFGetHistory]
    @MFTableName = @TableName,
    @Process_id = @Process_id,
    @ColumnNames = @ColumnNames,
    @SearchString = null,
    @IsFullHistory = @IsFullHistory,
    @NumberOFDays = @NumberOFDays,
    @StartDate = @StartDate,
    @Update_ID = @Update_ID OUTPUT,
    @ProcessBatch_id = @ProcessBatch_id OUTPUT,
    @Debug = @Debug

    SELECT * FROM [dbo].[MFProcessBatch] AS [mpb] WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_id
    SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_id

----

Show the results of the table including the name of the property

.. code:: sql

    SELECT toh.*,mp.name AS propertyname FROM mfobjectchangehistory toh
    INNER JOIN mfproperty mp
    ON mp.[MFID] = toh.[Property_ID]
    ORDER BY [toh].[Class_ID],[toh].[ObjID],[toh].[MFVersion],[toh].[Property_ID]

----

Show the results of the table for a state change

.. code:: sql

    SELECT toh.*,mws.name AS StateName, mp.name AS propertyname FROM mfobjectchangehistory toh
    INNER JOIN mfproperty mp
    ON mp.[MFID] = toh.[Property_ID]
    INNER JOIN [dbo].[MFWorkflowState] AS [mws]
    ON [toh].[Property_Value] = mws.mfid
    WHERE [toh].[Property_ID] = 39
    ORDER BY [toh].[Class_ID],[toh].[ObjID],[toh].[MFVersion],[toh].[Property_ID]

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-09-07  LC         Increase size of property value column to 4000
2021-03-12  LC         resolve bug to update multiple columns
2020-06-25  LC         added exception if invalid column is used
2020-03-12  LC         Revise datetime formatting
2019-09-25  LC         Include fnMFTextToDate to set datetime - dealing with localisation
2019-09-19  LC         Resolve dropping of temp table
2019-09-05  LC         Reset defaults
2019-09-05  LC         Add searchstring option
2019-08-30  JC         Added documentation
2019-08-02  LC         Set lastmodifiedUTC datetime conversion to 105
2019-06-02  LC         Fix bug with lastmodifiedUTC date
2019-01-02  LC         Add ability to show updates in MFUpdateHistory
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -----------------------------------------------------
        --DECLARE LOCAL VARIABLE
        ----------------------------------------------------
        DECLARE @VaultSettings NVARCHAR(4000);
        DECLARE @PropertyIDs NVARCHAR(4000);
        DECLARE @ObjIDs NVARCHAR(MAX);
        DECLARE @ObjectType INT;
        DECLARE @Class_ID INT;
        DECLARE @ProcedureName sysname = 'spMFGetHistory';
        DECLARE @ProcedureStep sysname = 'Start';
        -----------------------------------------------------
        --DECLARE VARIABLES FOR LOGGING
        -----------------------------------------------------
        --used on MFProcessBatchDetail;
        DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
        DECLARE @DebugText AS NVARCHAR(256) = N'';
        DECLARE @LogTypeDetail AS NVARCHAR(MAX) = N'';
        DECLARE @LogTextDetail AS NVARCHAR(MAX) = N'';
        DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = N'';
        DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
        DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
        DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
        DECLARE @ProcessType NVARCHAR(50) = N'Object History';
        DECLARE @LogType AS NVARCHAR(50) = N'Status';
        DECLARE @LogText AS NVARCHAR(4000) = N'Get History Initiated';
        DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
        DECLARE @Status AS NVARCHAR(128) = NULL;
        DECLARE @Validation_ID INT = NULL;
        DECLARE @StartTime AS DATETIME = GETUTCDATE();
        DECLARE @RunTime AS DECIMAL(18, 4) = 0;
        DECLARE @Update_IDOut INT;
        DECLARE @error AS INT = 0;
        DECLARE @rowcount AS INT = 0;
        DECLARE @return_value AS INT;
        DECLARE @RC INT;
        --  DECLARE @Update_ID INT;
        DECLARE @Params NVARCHAR(MAX);
        DECLARE @ID INT; --prop mfid;
        DECLARE @VQuery NVARCHAR(MAX);
        DECLARE @Filter NVARCHAR(MAX);
        DECLARE @Result NVARCHAR(MAX);
        DECLARE @Idoc INT;
        DECLARE @Criteria VARCHAR(258);
        DECLARE @BatchSize INT = 500;
        DECLARE @MinBatchRow INT;
        DECLARE @MaxBatchrow INT;
        DECLARE @FromObjid INT;
        DECLARE @ToObjid INT;
        DECLARE @PropID INT;
        DECLARE @propertyIDString NVARCHAR(100);
        DECLARE @BeforeCount INT;
           DECLARE @MFLastModifiedDateColumn NVARCHAR(100);
        ---------------------------------------------------------------
        --      Checking module access for CLR procdure  spMFGetHistoryInternal
        ----------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Check License ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



        -------------------------------------------------------------
        -- get last modified date column
        -------------------------------------------------------------
        SELECT @MFLastModifiedDateColumn = ColumnName
        FROM dbo.MFProperty
        WHERE MFID = 21;

        ----------------------------------------------------------------------
        --initialise entry in UpdateHistory
        ----------------------------------------------------------------------
        DECLARE @Username NVARCHAR(2000);
        DECLARE @VaultName NVARCHAR(2000);

        SELECT TOP 1
            @Username  = Username,
            @VaultName = VaultName
        FROM dbo.MFVaultSettings;

        INSERT INTO dbo.MFUpdateHistory
        (
            Username,
            VaultName,
            UpdateMethod
        )
        VALUES
        (@Username, @VaultName, -1);

        SELECT @Update_ID = @@Identity;

        SELECT @Update_IDOut = @Update_ID;

        SET @ProcessType = @ProcedureName;
        SET @LogText = @ProcedureName + N' Started ';
        SET @LogStatus = N'Initiate';
        SET @StartTime = GETUTCDATE();

        EXECUTE @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id,
            @ProcessType = @ProcessType,
            @LogType = @LogType,
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @ProcedureStep = 'Start GetHistory';
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SELECT @VaultSettings = dbo.FnMFVaultSettings();

        IF @Debug = 1
        BEGIN
            SELECT @VaultSettings = dbo.FnMFVaultSettings();
        END;

        ----------------------------------------------------------------------
        --Validate properties GET PropertyIDS as comma separated string  
        ----------------------------------------------------------------------
        SET @ProcedureStep = 'Validate column : ';
        SET @LogTypeDetail = N'Debug';
        SET @LogStatusDetail = N'Started';
        SET @StartTime = GETUTCDATE();
        SET @LogTextDetail = N' Columns: ' + @ColumnNames;
        SET @LogColumnName = N' Count ';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = @LogColumnName,
            @ColumnValue = @LogColumnValue,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;

        ----------------------------------------------------------------------
        --GET ObjectType of Table
        ----------------------------------------------------------------------
        SET @ProcedureStep = 'GET ObjectType of class table ' + @MFTableName;

        SELECT @ObjectType = OT.MFID,
            @Class_ID      = CLS.MFID
        FROM dbo.MFClass                AS CLS
            INNER JOIN dbo.MFObjectType AS OT
                ON CLS.MFObjectType_ID = OT.ID
        WHERE CLS.TableName = @MFTableName;

        SET @DebugText = N' objecttype %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectType);
        END;

        ---------------------------------------------------------------------
        --GET All ObjIDS for Getting the History        
        ----------------------------------------------------------------------
        SET @ProcedureStep = 'Get ObjIDS for History ';
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @StartTime = GETUTCDATE();
        SET @Filter = N'where  Process_ID=' + CONVERT(VARCHAR(10), @Process_id);

        IF
        (
            SELECT OBJECT_ID('tempdb..#TempObjIDs')
        ) IS NOT NULL
            DROP TABLE #TempObjIDs;

        CREATE TABLE #TempObjIDs
        (
            TempTable_ID INT IDENTITY,
            ObjID INT PRIMARY KEY
        );

        SET @VQuery = N'insert into #TempObjIDs(ObjID)  select [ObjID] 
										 FROM  ' + @MFTableName + N'
										  ' + @Filter + N' ';

        IF @IsFullHistory = 0 AND @StartDate IS NOT null
        BEGIN
        SET @VQuery = @Vquery + ' and '+ QUOTENAME(@MFLastModifiedDateColumn) + ' >= ''' + CAST(CONVERT(DATE, @StartDate) AS NVARCHAR(25)) + ''' ;';
        END

        EXEC (@VQuery);

        SELECT @rowcount = @@RowCount;

        IF @debug > 0
        BEGIN
          SELECT @FromObjid = MIN(toid.ObjID), @ToObjid = MAX(objid), @MaxBatchrow = MAX(toid.TempTable_ID)
            FROM #TempObjIDs AS toid

SELECT @MFTableName AS tablename, @FromObjid fromobjid, @ToObjid Toobjid, @MaxBatchrow AS Lastrow;
end

        -------------------------------------------------------------
        -- set max length
        -------------------------------------------------------------
        SET @LogTypeDetail = N'Debug';
        SET @LogStatusDetail = N'In progress';
        SET @LogTextDetail = N' ObjIDS for History';
        SET @LogColumnName = N' Objids count';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(100));

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = @LogColumnName,
            @ColumnValue = @LogColumnValue,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;

        ---------------------------------------------------------------------
        --Calling spMFGetHistoryInternal  procedure to objects history
        ----------------------------------------------------------------------
        SET @ProcedureStep = 'Set criteria ';
        SET @Criteria = CASE
                            WHEN @IsFullHistory = 1 THEN
                                ' Full History '
                            WHEN @IsFullHistory = 0
                                 AND @NumberOFDays > 0 THEN
                                ' For Number of days: ' + CAST(@NumberOFDays AS VARCHAR(5)) + ''
                            WHEN @IsFullHistory = 0
                                 AND
                                 (
                                     @NumberOFDays < 0
                                     OR @NumberOFDays IS NULL
                                 )
                                 AND @StartDate <> '2000-01-01' THEN
                                ' From date: ' + CAST((CONVERT(DATE, @StartDate)) AS VARCHAR(25)) + ''
                            ELSE
                                ' No Criteria'
                        END;
        SET @LogTypeDetail = N'Debug';
        SET @LogStatusDetail = N'In progress';
        SET @LogTextDetail = N' Criteria:  ' + ISNULL(@Criteria, 'No criteria');
        SET @LogColumnName = N' Object Count';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(5));
        SET @StartTime = GETUTCDATE();

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = @LogColumnName,
            @ColumnValue = @LogColumnValue,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;

        -------------------------------------------------------------
        -- Batch Get history
        -------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = ' Batch loop ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SELECT @MinBatchRow = 1,
            @MaxBatchrow    = MAX(toid.TempTable_ID)
        FROM #TempObjIDs AS toid;

        --start of main loop

        WHILE @MinBatchRow IS NOT NULL
        BEGIN; -- batching objids
            ;

IF @debug > 0
SELECT @MFTableName AS tablename, @FromObjid fromobjid, @MinBatchRow AS nextstartrow, @ToObjid Toobjid, @MaxBatchrow AS Lastrow;


            WITH cte
            AS (SELECT TOP 500
                    toid.ObjID
                FROM #TempObjIDs AS toid
                WHERE toid.TempTable_ID > @MinBatchRow  -1 
                ORDER BY toid.TempTable_ID)
            SELECT @ObjIDs = STUFF(
                             (
                                 SELECT ',' + CAST(cte.ObjID AS VARCHAR(10))FROM cte ORDER BY objid FOR XML PATH('')
                             ),
                                      1,
                                      1,
                                      ''
                                  );

            SELECT @FromObjid = MIN(fmpds.ListItem)
            FROM dbo.fnMFParseDelimitedString(@ObjIDs, ',') AS fmpds;

            SELECT @ToObjid = MAX(fmpds.ListItem)
            FROM dbo.fnMFParseDelimitedString(@ObjIDs, ',') AS fmpds;

            IF @Debug > 0
            BEGIN
                SELECT @FromObjid AS FromObjid,
                    @ToObjid      AS ToObjid;
            END;

            UPDATE dbo.MFUpdateHistory
            SET ObjectDetails = 'From ' + CAST(@FromObjid AS NVARCHAR(100)) + ' To ' + CAST(@ToObjid AS NVARCHAR(100))
                                + '',
                ObjectVerDetails = @PropertyIDs
            WHERE Id = @Update_ID;

            SET @DebugText = N' %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'GetHistoryInternal from objid ';

            IF @Debug > 0
            BEGIN
                SELECT @ObjectType AS objecttype,
                    @ObjIDs        AS objids,
                    @ColumnNames   AS propertyids,
                    @IsFullHistory AS IsfullHistory,
                    @StartDate     AS Startdate;

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @FromObjid);
            END;

            
            SELECT @PropID = MFID
            FROM dbo.MFProperty
            WHERE ColumnName = @ColumnNames;


            SELECT @propertyIDString = CAST(@PropID AS NVARCHAR(10));

            IF @objids IS NOT null
            Begin
            EXEC dbo.spMFGetHistoryInternal @VaultSettings = @VaultSettings,
                @ObjectType = @ObjectType,
                @ObjIDs = @ObjIDs,
                @PropertyIDs = @propertyIDString,
                @SearchString = NULL,
                @IsFullHistory = @IsFullHistory,
                @NumberOfDays = @NumberOFDays,
                @StartDate = @StartDate,
                @Result = @Result OUTPUT;

            IF @Debug > 0
            BEGIN
                SELECT CAST(@Result AS XML) AS ResultsAsXML;

                SELECT @Result AS Results;
            END;

            IF (@Update_ID > 0)
                UPDATE dbo.MFUpdateHistory
                SET NewOrUpdatedObjectVer = @Result
                WHERE Id = @Update_ID;

                END

            EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @Result;

            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Wrapper performed';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @rowcount = COUNT(*)
            FROM
            (SELECT fmss.Item FROM dbo.fnMFSplitString(@ObjIDs, ',') AS fmss ) list;

            SET @LogTypeDetail = N'Debug';
            SET @LogStatusDetail = N'Column: ' + CAST(@rowcount AS VARCHAR(10));
            SET @LogTextDetail = N'Criteria:  ' + @Criteria;
            SET @LogColumnName = N'Object Count';
            SET @LogColumnValue = CAST(@rowcount AS VARCHAR(5));
            SET @StartTime = GETUTCDATE();

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = @Validation_ID,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @Update_ID = @Update_ID,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;

            ----------------------------------------------------------------------------------
            --Creating temp table #Temp_ObjectHistory for storing object history xml records
            --------------------------------------------------------------------------------
            SET @ProcedureStep = 'Creating temp table #Temp_ObjectHistory';

            IF
            (
                SELECT OBJECT_ID('tempdb..#Temp_ObjectHistory')
            ) IS NOT NULL
                DROP TABLE #Temp_ObjectHistory;

            CREATE TABLE #Temp_ObjectHistory
            (
                RowNr INT IDENTITY,
                ObjectType_ID INT,
                Class_ID INT,
                ObjID INT,
                MFVersion INT,
                LastModifiedUTC NVARCHAR(100),
                -- LastModifiedUTC DATETIME,
                MFLastModifiedBy_ID INT,
                Property_ID INT,
                Property_Value NVARCHAR(4000),
                CreatedOn DATETIME
            );

            INSERT INTO #Temp_ObjectHistory
            (
                ObjectType_ID,
                Class_ID,
                ObjID,
                MFVersion,
                LastModifiedUTC,
                MFLastModifiedBy_ID,
                Property_ID,
                Property_Value,
                CreatedOn
            )
            SELECT ObjectType,
                ClassID,
                ObjID,
                Version,
                LastModifiedUTC,
                LastModifiedBy_ID,
                Property_ID,
                Property_Value,
                GETDATE()
            FROM
                OPENXML(@Idoc, '/form/Object', 1)
                WITH
                (
                    ObjectType INT '@ObjectType',
                    ClassID INT '@ClassID',
                    ObjID INT '@ObjID',
                    Version INT '@Version',
                    --      , [LastModifiedUTC] NVARCHAR(30) '../@LastModifiedUTC'
                    LastModifiedUTC NVARCHAR(100) '@CheckInTimeStamp',
                    --        LastModifiedUTC Datetime '../@CheckInTimeStamp',
                    LastModifiedBy_ID INT '@LastModifiedBy_ID',
                    Property_ID INT '@Property_ID',
                    Property_Value NVARCHAR(4000) '@Property_Value'
                )
            WHERE '@Property_ID' IS NOT NULL;

            IF @Debug > 0
                SELECT *
                FROM #Temp_ObjectHistory AS toh;

            IF @Idoc IS NOT NULL
                EXEC sys.sp_xml_removedocument @Idoc;

            ----------------------------------------------------------------------------------
            --Merge/Inserting records into the MFObjectChangeHistory from Temp_ObjectHistory
            --------------------------------------------------------------------------------
            SET @ProcedureStep = 'Update MFObjectChangeHistory';

            SELECT @BeforeCount = COUNT(*)
            FROM dbo.MFObjectChangeHistory;

            BEGIN TRAN;

            INSERT INTO dbo.MFObjectChangeHistory
            (
                ObjectType_ID,
                Class_ID,
                ObjID,
                MFVersion,
                LastModifiedUtc,
                MFLastModifiedBy_ID,
                Property_ID,
                Property_Value,
                CreatedOn
            )
            SELECT s.ObjectType_ID,
                s.Class_ID,
                s.ObjID,
                s.MFVersion,
                CONVERT(DATETIME, s.LastModifiedUTC),
                s.MFLastModifiedBy_ID,
                s.Property_ID,
                s.Property_Value,
                s.CreatedOn
            FROM #Temp_ObjectHistory                AS s
                LEFT JOIN dbo.MFObjectChangeHistory t
                    ON t.ObjectType_ID = s.ObjectType_ID
                       AND t.Class_ID = s.Class_ID
                       AND t.ObjID = s.ObjID
                       AND t.MFVersion = s.MFVersion
                       AND t.Property_ID = s.Property_ID
            WHERE t.ID IS NULL;

            COMMIT TRAN;

            SET @rowcount = @@RowCount;
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Update history table';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @LogTypeDetail = N'Debug';
            SET @LogStatusDetail = N'Column: ' + CAST(@rowcount AS VARCHAR(10));
            SET @LogTextDetail = N'Criteria:  ' + @Criteria;
            SET @LogColumnName = N'Objects inserted';
            SET @LogColumnValue = CAST(@rowcount AS VARCHAR(5));
            SET @StartTime = GETUTCDATE();

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = @Validation_ID,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @Update_ID = @Update_ID,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;

            -------------------------------------------------------------
            -- Reset process_ID
            -------------------------------------------------------------
            SET @Params = N'@objids nvarchar(max)';
            SET @ProcedureStep = 'Reset process_id';
            SET @VQuery
                = N'
					UPDATE t
                    SET Process_ID = 0 
                    From ' + QUOTENAME(@MFTableName)
                  + N' t
                    inner join (Select item from dbo.fnMFSplitString(@Objids,'','') )fmss
                    on fmss.item = t.objid
					WHERE process_ID = ' + CAST(@Process_id AS VARCHAR(5)) + N'';

            --                  IF @debug > 0
            --                  PRINT @VQuery;
--            EXEC sys.sp_executesql @VQuery, @Params, @ObjIDs;

            --truncate table MFObjectChangeHistory
            IF
            (
                SELECT OBJECT_ID('tempdb..#Temp_ObjectHistory')
            ) IS NOT NULL
                DROP TABLE #Temp_ObjectHistory;

            SELECT @MinBatchRow =
            (
                SELECT MIN(toid.TempTable_ID)
                FROM #TempObjIDs AS toid
                WHERE toid.TempTable_ID > @MinBatchRow + 500 
            );

            IF @MinBatchRow > @MaxBatchrow
                SET @MinBatchRow = NULL;
                ;
        END; -- end batch process


        IF
        (
            SELECT OBJECT_ID('tempdb..#TempObjIDs')
        ) IS NOT NULL
            DROP TABLE #TempObjIDs;

        SET @ProcessType = @ProcedureName;
        SET @LogText = @ProcedureName + N' Ended ';
        SET @LogStatus = N'Completed';
        SET @StartTime = GETUTCDATE();

        EXECUTE @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id,
            @ProcessType = @ProcessType,
            @LogType = @LogType,
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @LogTypeDetail = N'Message';
        SET @LogTextDetail = N'History inserted in MFObjectChangeHistory';
        SET @LogStatusDetail = N'Completed';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = N'New History';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(5));

        EXECUTE @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = @LogColumnName,
            @ColumnValue = @LogColumnValue,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;

        RETURN 1;
    END TRY
    BEGIN CATCH
        SET @StartTime = GETUTCDATE();
        SET @LogStatus = N'Failed w/SQL Error';
        SET @LogTextDetail = ERROR_MESSAGE();

        --------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        --------------------------------------------------
        IF @Idoc IS NOT NULL
            EXEC sys.sp_xml_removedocument @Idoc;

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

        SET @ProcedureStep = 'Catch Error';

        -------------------------------------------------------------
        -- Log Error
        -------------------------------------------------------------   
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = N'Error',
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SET @StartTime = GETUTCDATE();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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