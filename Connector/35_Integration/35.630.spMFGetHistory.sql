
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetHistory]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFGetHistory',
    -- nvarchar(100)
    @Object_Release = '4.8.27.68',
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
    - Comma delimited list of the columns to be included in the export
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

        ----------------------------------------------------------------------
        --GET Vault LOGIN CREDENTIALS
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

        IF
        (
            SELECT OBJECT_ID('tempdb..#TempProperty')
        ) IS NOT NULL
            DROP TABLE #TempProperty;

        CREATE TABLE #TempProperty
        (
            ID INT IDENTITY(1, 1),
            ColumnName NVARCHAR(200),
            IsValidProperty BIT
                DEFAULT (0)
        );

        INSERT INTO #TempProperty
        (
            ColumnName
        )
        SELECT LTRIM(ListItem)
        FROM dbo.fnMFParseDelimitedString(@ColumnNames, ',');

        DECLARE @ID INT;

        SELECT @ID = MIN(ID)
        FROM #TempProperty;


        -------------------------------------------------------------
        -- Validation of column
        -------------------------------------------------------------
        WHILE @ID IS NOT NULL
        BEGIN --loop FOR validating column
            DECLARE @PropertyName NVARCHAR(200);

            SELECT @PropertyName = ColumnName
            FROM #TempProperty
            WHERE ID = @ID;

            IF EXISTS
            (
                SELECT TOP 1
                    *
                FROM dbo.MFProperty WITH (NOLOCK)
                WHERE ColumnName = @PropertyName
            )
            BEGIN --set validity
                UPDATE #TempProperty
                SET IsValidProperty = 1
                WHERE ID = @ID;
            END;

            --end set validity
            --ELSE
            --Begin
            --IF EXISTS
            --(
            --    SELECT TOP 1
            --        *
            --    FROM dbo.MFProperty WITH (NOLOCK)
            --    WHERE ColumnName = @PropertyName + N'_ID'
            --          AND MFDataType_ID IN ( 8, 9 )
            --)
            --BEGIN --reset column to include _ID
            --    UPDATE #TempProperty
            --    SET IsValidProperty = 1,
            --        ColumnName = @PropertyName + N'_ID'
            --    WHERE ID = @Counter;
            --END; --end reset
            --END; --end else
            SET @ID =
            (
                SELECT MIN(tp.ID) FROM #TempProperty AS tp WHERE tp.ID > @ID
            );
        END; -- end loop for validating column

        BEGIN -- error invalid column
            SET @ProcedureStep = 'Invalid columns: ';

            SELECT @DebugText = ''
            SELECT @DebugText = COALESCE(@ColumnNames + ',', '') + ColumnName
            FROM #TempProperty
            WHERE IsValidProperty = 0;

            SET @DebugText = @DefaultDebugText + ISNULL(@DebugText,'');

            IF @debug > 0 
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END; --end error invalid column

        SET @ColumnNames = NULL;
        SET @ProcedureStep = ' Get validated columns: ';

        SELECT @ColumnNames = COALESCE(@ColumnNames + ',', '') + ColumnName
        FROM #TempProperty
        WHERE IsValidProperty = 1;

        SELECT @PropertyIDs = COALESCE(@PropertyIDs + ',', '') + CAST(MFID AS VARCHAR(20))
        FROM dbo.MFProperty WITH (NOLOCK)
        WHERE ColumnName IN
              (
                  SELECT ListItem FROM dbo.fnMFParseDelimitedString(@ColumnNames, ',')
              );

              IF @debug > 0
              SELECT @ColumnNames AS columnnames, @PropertyIDs AS propertyids;

        SELECT @rowcount = COUNT(*)
        FROM dbo.fnMFParseDelimitedString(@ColumnNames, ',');

        SET @DebugText = @ColumnNames;
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

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

        SELECT @ObjectType = OT.MFID, @Class_ID = cls.mfid
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

        DECLARE @VQuery NVARCHAR(MAX),
            @Filter     NVARCHAR(MAX);

        SET @Filter = N'where  Process_ID=' + CONVERT(VARCHAR(10), @Process_id);

        IF
        (
            SELECT OBJECT_ID('tempdb..#TempObjIDs')
        ) IS NOT NULL
            DROP TABLE #TempObjIDs;

        CREATE TABLE #TempObjIDs
        (
            ObjID INT
        );

        SET @VQuery = N'insert into #TempObjIDs(ObjID)  select [ObjID] 
										 FROM  ' + @MFTableName + N'
										  ' + @Filter + N'';

        EXEC (@VQuery);

        SELECT @rowcount = COUNT(*)
        FROM #TempObjIDs AS toid;

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
        DECLARE @Result NVARCHAR(MAX);
        DECLARE @Idoc INT;

        SET @ProcedureStep = 'Calling spMFGetHistoryInternal ';

        DECLARE @Criteria VARCHAR(258);

        SET @Criteria = CASE
                            WHEN @IsFullHistory = 1 THEN
                                ' Full History '
                            WHEN @IsFullHistory = 0
                                 AND @NumberOFDays > 0 THEN
                                ' For Number of days: ' + CAST(@NumberOFDays AS VARCHAR(5)) + ''
                            WHEN @IsFullHistory = 0
                                 AND @NumberOFDays < 0
                                 AND @StartDate <> '2000-01-01' THEN
                                ' From date: ' + CAST((CONVERT(DATE, @StartDate)) AS VARCHAR(25)) + ''
                            ELSE
                                ' No Criteria'
                        END;

        DECLARE @Params NVARCHAR(MAX);

        SET @VQuery
            = N'SELECT @rowcount = COUNT(*) FROM ' + @MFTableName + N' where process_ID = '
              + CAST(@Process_id AS VARCHAR(5)) + N'';
        SET @Params = N'@RowCount int output';

        EXEC sys.sp_executesql @VQuery, @Params, @RowCount = @rowcount OUTPUT;

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

        -- note that ability to use a search criteria is not yet active.

        -----------------------------------------------------------------
        -- Checking module access for CLR procdure  spMFGetHistoryInternal
        ------------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Check License ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        EXEC dbo.spMFCheckLicenseStatus 'spMFGetHistory',
            @ProcedureName,
            @ProcedureStep;

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

        DECLARE @BatchSize INT = 500;
        DECLARE @MaxBatchrow INT;

        SET @MaxBatchrow =
        (
            SELECT MIN(toid.ObjID) FROM #TempObjIDs AS toid
        );

        WHILE @MaxBatchrow < (SELECT MAX(toid.ObjID) + 1 FROM #TempObjIDs AS toid)
        BEGIN; -- batching objids
            WITH cte
            AS (SELECT TOP 500
                    toid.ObjID
                FROM #TempObjIDs AS toid
                WHERE toid.ObjID > @MaxBatchrow - 1)
            SELECT @ObjIDs = STUFF(
                             (
                                 SELECT ',' + CAST(cte.ObjID AS VARCHAR(10))FROM cte FOR XML PATH('')
                             ),
                                      1,
                                      1,
                                      ''
                                  );

            IF @Debug > 0
            BEGIN
                SELECT @ObjIDs AS ObjIDS;
            END;

            UPDATE dbo.MFUpdateHistory
            SET ObjectDetails = @ObjIDs,
                ObjectVerDetails = @PropertyIDs
            WHERE Id = @Update_ID;

            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'GetHistoryInternal ';

            IF @Debug > 0
            BEGIN
                SELECT @ObjectType AS objecttype,
                    @ObjIDs        AS objids,
                    @PropertyIDs   AS propertyids,
                    @IsFullHistory AS IsfullHistory,
                    @StartDate     AS Startdate;

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            DECLARE @PropertyList AS TABLE
            (
                ID INT
            );

            DECLARE @PropID INT;
            DECLARE @propertyIDString NVARCHAR(100);

            IF ISNULL(@PropertyIDs, '') = ''
            BEGIN;
                WITH cte
                AS (SELECT mfms.Property_MFID property_ID
                    FROM dbo.MFvwMetadataStructure AS mfms
                    WHERE mfms.ObjectType_MFID = @ObjectType
                          AND mfms.class_MFID = @Class_ID
                    GROUP BY mfms.Property_MFID)
                INSERT INTO @PropertyList
                (
                    ID
                )
                SELECT cte.property_ID
                FROM cte;
            END;
            ELSE
                INSERT INTO @PropertyList
                (
                    ID
                )
                SELECT fmpds.ListItem
                FROM dbo.fnMFParseDelimitedString(@PropertyIDs, ',') AS fmpds;

            SELECT @PropID = MIN(pl.ID)
            FROM @PropertyList AS pl;

            WHILE @PropID IS NOT NULL
            BEGIN
                SELECT @propertyIDString = CAST(@PropID AS NVARCHAR(10));

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
                SET @LogStatusDetail = N'Completed column: ' + CAST(@rowcount AS VARCHAR(10));
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
                    Property_Value NVARCHAR(300),
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
                        Property_Value NVARCHAR(300) '@Property_Value'
                    )
                    WHERE  '@Property_ID' IS NOT null ;

                IF @Debug > 0
                    SELECT *
                    FROM #Temp_ObjectHistory AS toh;

                IF @Idoc IS NOT NULL
                    EXEC sys.sp_xml_removedocument @Idoc;

                ----------------------------------------------------------------------------------
                --Merge/Inserting records into the MFObjectChangeHistory from Temp_ObjectHistory
                --------------------------------------------------------------------------------
                SET @ProcedureStep = 'Update MFObjectChangeHistory';

                DECLARE @BeforeCount INT;

                SELECT @BeforeCount = COUNT(*)
                FROM dbo.MFObjectChangeHistory;

                MERGE INTO dbo.MFObjectChangeHistory AS t
                USING
                (SELECT * FROM #Temp_ObjectHistory AS toh) AS s
                ON t.ObjectType_ID = s.ObjectType_ID
                   AND t.Class_ID = s.Class_ID
                   AND t.ObjID = s.ObjID
                   AND t.MFVersion = s.MFVersion
                   AND t.Property_ID = s.Property_ID
                WHEN MATCHED THEN
                    UPDATE SET
                        --    t.LastModifiedUtc = dbo.fnMFTextToDate(s.LastModifiedUTC, '/'),
                        t.LastModifiedUtc = CONVERT(DATETIME, s.LastModifiedUTC),
                        --     t.LastModifiedUtc =s.LastModifiedUTC,
                        t.Property_Value = s.Property_Value
                WHEN NOT MATCHED BY TARGET THEN
                    INSERT
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
                    VALUES
                    (   s.ObjectType_ID, s.Class_ID, s.ObjID, s.MFVersion, CONVERT(DATETIME, s.LastModifiedUTC),
                        --dbo.fnMFTextToDate(s.LastModifiedUTC, '/'),
                        --      s.LastModifiedUTC,
                        s.MFLastModifiedBy_ID, s.Property_ID, s.Property_Value, s.CreatedOn);

                -------------------------------------------------------------
                -- Delete duplicate change records
                -------------------------------------------------------------
                DELETE dbo.MFObjectChangeHistory
                WHERE ID IN
                      (
                          SELECT toh.ID
                          FROM #Temp_ObjectHistory                 AS toh2
                              INNER JOIN dbo.MFObjectChangeHistory AS toh
                                  ON toh.ObjID = toh2.ObjID
                                     AND toh.Class_ID = toh2.Class_ID
                                     AND toh.Property_ID = toh2.Property_ID
                                     AND toh.MFVersion = toh2.MFVersion
                              INNER JOIN dbo.MFObjectChangeHistory AS moch
                                  ON toh.ObjID = moch.ObjID
                                     AND toh.Class_ID = moch.Class_ID
                                     AND toh.Property_ID = moch.Property_ID
                                     AND toh.Property_Value = moch.Property_Value
                          WHERE toh.MFVersion = moch.MFVersion + 1
                      );

                SET @rowcount =
                (
                    SELECT COUNT(*) FROM dbo.MFObjectChangeHistory AS moch
                ) - @BeforeCount;
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
                EXEC sys.sp_executesql @VQuery, @Params, @ObjIDs;

                --truncate table MFObjectChangeHistory
                IF
                (
                    SELECT OBJECT_ID('tempdb..#Temp_ObjectHistory')
                ) IS NOT NULL
                    DROP TABLE #Temp_ObjectHistory;

                                SELECT @PropID =
            (
                SELECT MIN(pl.ID) FROM @PropertyList AS pl WHERE pl.ID > @PropID
            );
        END; -- end processing CLR

          SELECT @MaxBatchrow = @MaxBatchrow + 500;
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