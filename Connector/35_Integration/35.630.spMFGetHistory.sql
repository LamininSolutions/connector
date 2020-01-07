
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetHistory]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFGetHistory'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.4.12.53'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;

GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFGetHistory' --name of procedure
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

CREATE PROCEDURE [dbo].[spMFGetHistory]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFGetHistory]
(
    @MFTableName NVARCHAR(128)
   ,@Process_id INT = 0
   ,@ColumnNames NVARCHAR(4000)
   ,@SearchString nvarchar(4000) = null
   ,@IsFullHistory BIT = 1
   ,@NumberOFDays INT = null
   ,@StartDate DATETIME = null
   ,@Update_ID INT = NULL OUTPUT
   ,@ProcessBatch_id INT = NULL OUTPUT
   ,@Debug INT = 0
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

- Show coimments made on object
- Show a state was entered and exited
- Show when a property was changed
- Discovery reports for changes to certain properties

Prerequisites
=============

Set process_id in the class table to 5 for all the records to be included

Warnings
========

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

    EXECUTE @RC = [dbo].[spMFGetHistory]
    @TableName
    ,@Process_id
    ,@ColumnNames
    ,@IsFullHistory
    ,@NumberOFDays
    ,@StartDate
    ,@ProcessBatch_id OUTPUT
    ,@Debug

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
        DECLARE @ProcedureName sysname = 'spMFGetHistory';
        DECLARE @ProcedureStep sysname = 'Start';
        -----------------------------------------------------
        --DECLARE VARIABLES FOR LOGGING
        -----------------------------------------------------
        --used on MFProcessBatchDetail;
        DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
        DECLARE @DebugText AS NVARCHAR(256) = '';
        DECLARE @LogTypeDetail AS NVARCHAR(MAX) = '';
        DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
        DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
        DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
        DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
        DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
        DECLARE @ProcessType NVARCHAR(50) = 'Object History';
        DECLARE @LogType AS NVARCHAR(50) = 'Status';
        DECLARE @LogText AS NVARCHAR(4000) = 'Get History Initiated';
        DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
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
               @Username  = [Username]
              ,@VaultName = [VaultName]
        FROM [dbo].[MFVaultSettings];

        INSERT INTO [dbo].[MFUpdateHistory]
        (
            [Username]
           ,[VaultName]
           ,[UpdateMethod]
        )
        VALUES
        (@Username, @VaultName, -1);

        SELECT @Update_ID = @@Identity;

        SELECT @Update_IDOut = @Update_ID;

        SET @ProcessType = @ProcedureName;
        SET @LogText = @ProcedureName + ' Started ';
        SET @LogStatus = 'Initiate';
        SET @StartTime = GETUTCDATE();

        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_id OUTPUT
                                                     ,@ProcessType = @ProcessType
                                                     ,@LogType = @LogType
                                                     ,@LogText = @LogText
                                                     ,@LogStatus = @LogStatus
                                                     ,@debug = @Debug;

        SET @ProcedureStep = 'GET Vault LOGIN CREDENTIALS';

        IF @Debug = 1
        BEGIN
            PRINT @ProcedureStep;
        END;

        SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

        IF @Debug = 1
        BEGIN
            SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();
        END;

        ----------------------------------------------------------------------
        --GET PropertyIDS as comma separated string  
        ----------------------------------------------------------------------
        SET @ProcedureStep = 'Get PropertyIDS';
        SET @LogTypeDetail = 'Message';
        SET @LogStatusDetail = 'Started';
        SET @StartTime = GETUTCDATE();

        IF (SELECT OBJECT_ID('tempdb..#TempProperty')) IS NOT NULL
        DROP TABLE #TempProperty;
        CREATE TABLE [#TempProperty]
        (
            [ID] INT IDENTITY(1, 1)
           ,[ColumnName] NVARCHAR(200)
           ,[IsValidProperty] BIT
        );

        INSERT INTO [#TempProperty]
        (
            [ColumnName]
        )
        SELECT [ListItem]
        FROM [dbo].[fnMFParseDelimitedString](@ColumnNames, ',');

        DECLARE @Counter  INT
               ,@MaxRowID INT;

        SELECT @MaxRowID = MAX([ID])
        FROM [#TempProperty];

        SET @Counter = 1;

        WHILE @Counter <= @MaxRowID
        BEGIN
            DECLARE @PropertyName NVARCHAR(200);

            SELECT @PropertyName = [ColumnName]
            FROM [#TempProperty]
            WHERE [ID] = @Counter;

            IF EXISTS
            (
                SELECT TOP 1
                       *
                FROM [dbo].[MFProperty] WITH (NOLOCK)
                WHERE [ColumnName] = @PropertyName
            )
            BEGIN
                UPDATE [#TempProperty]
                SET [IsValidProperty] = 1
                WHERE [ID] = @Counter;
            END;
            ELSE
            BEGIN
                SET @PropertyName = @PropertyName + '_ID';

                IF EXISTS
                (
                    SELECT TOP 1
                           *
                    FROM [dbo].[MFProperty] WITH (NOLOCK)
                    WHERE [ColumnName] = @PropertyName
                )
                BEGIN
                    UPDATE [#TempProperty]
                    SET [IsValidProperty] = 1
                       ,[ColumnName] = @PropertyName
                    WHERE [ID] = @Counter;
                END;
                ELSE
                BEGIN
                    DECLARE @ErrorMsg NVARCHAR(1000);

                    SELECT @ErrorMsg = 'Invalid columnName ' + @PropertyName + ' provided';

                    IF @Debug > 0
                        --	   SELECT @ErrorMsg;
                        RAISERROR(
                                     'Proc: %s Step: %s ErrorInfo %s '
                                    ,16
                                    ,1
                                    ,'spmfGetHistory'
                                    ,'Validating property column name'
                                    ,@ErrorMsg
                                 );
                END;
            END;

            SET @Counter = @Counter + 1;
        END;

        SET @ColumnNames = '';

        SELECT @ColumnNames = COALESCE(@ColumnNames + ',', '') + [ColumnName]
        FROM [#TempProperty];

        SELECT @PropertyIDs = COALESCE(@PropertyIDs + ',', '') + CAST([MFID] AS VARCHAR(20))
        FROM [dbo].[MFProperty] WITH (NOLOCK)
        WHERE [ColumnName] IN (
                                  SELECT [ListItem] FROM [dbo].[fnMFParseDelimitedString](@ColumnNames, ',')
                              );

        SELECT @rowcount = COUNT(*)
        FROM [dbo].[fnMFParseDelimitedString](@ColumnNames, ',');

        SET @LogTextDetail = 'Columns: ' + @ColumnNames;
        SET @LogColumnName = 'Count of columns';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_id
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        ----------------------------------------------------------------------
        --GET ObjectType of Table
        ----------------------------------------------------------------------
        SET @ProcedureStep = 'GET ObjectType of class table ' + @MFTableName;

        SELECT @ObjectType = [OT].[MFID]
        FROM [dbo].[MFClass]                AS [CLS]
            INNER JOIN [dbo].[MFObjectType] AS [OT]
                ON [CLS].[MFObjectType_ID] = [OT].[ID]
        WHERE [CLS].[TableName] = @MFTableName;

        IF @Debug = 1
        BEGIN
            SELECT @ObjectType AS [ObjectType];
        END;

        ---------------------------------------------------------------------
        --GET Comma separated ObjIDS for Getting the History        
        ----------------------------------------------------------------------
        SET @ProcedureStep = 'ObjIDS for History ';

        IF @Debug = 1
        BEGIN
            PRINT @ProcedureStep;
        END;

        SET @StartTime = GETUTCDATE();

        DECLARE @VQuery NVARCHAR(4000)
               ,@Filter NVARCHAR(4000);

        SET @Filter = 'where  Process_ID=' + CONVERT(VARCHAR(10), @Process_id);

        CREATE TABLE [#TempObjIDs]
        (
            [ObjIDS] NVARCHAR(MAX)
        );

        SET @VQuery
            = 'insert into #TempObjIDs(ObjIDS)  select STUFF(( SELECT '',''
											  , CAST([ObjID] AS VARCHAR(10))
										 FROM  ' + @MFTableName + '
										  ' + @Filter
              + '
									   FOR
										 XML PATH('''')
									   ), 1, 1, '''') ';

        EXEC (@VQuery);

        SELECT @ObjIDs = [ObjIDS]
        FROM [#TempObjIDs];

        SELECT @rowcount = COUNT(*)
        FROM [#TempObjIDs] AS [toid];

        SET @LogTypeDetail = 'Message';
        SET @LogStatusDetail = 'Completed';
        SET @LogTextDetail = 'ObjIDS for History';
        SET @LogColumnName = 'Objids count';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(100));

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_id
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        IF @Debug = 1
        BEGIN
            SELECT @ObjIDs AS [ObjIDS];
        END;

        ---------------------------------------------------------------------
        --Calling spMFGetHistoryInternal  procedure to objects history
        ----------------------------------------------------------------------
        DECLARE @Result NVARCHAR(MAX);
        DECLARE @Idoc INT;

        --select @VaultSettings as 'VaultSettings'
        --select @ObjectType as 'ObjectType'
        --select @ObjIDs as 'ObjIDs'
        --select @PropertyIDs as 'PropertyIDs'
        SET @ProcedureStep = 'Calling spMFGetHistoryInternal';

        DECLARE @Criteria VARCHAR(258);

        SET @Criteria = CASE
                            WHEN @IsFullHistory = 1 THEN
                                'Full History '
                            WHEN @IsFullHistory = 0
                                 AND @NumberOFDays > 0 THEN
                                'For Number of days: ' + CAST(@NumberOFDays AS VARCHAR(5)) + ''
                            WHEN @IsFullHistory = 0
                                 AND @NumberOFDays < 0
                                 AND @StartDate <> '1901-01-10' THEN
                                'From date: ' + CAST((CONVERT(DATE, @StartDate)) AS VARCHAR(25)) + ''
                            ELSE
                                'No Criteria'
                        END;

        DECLARE @Params NVARCHAR(MAX);

        SET @VQuery
            = N'SELECT @rowcount = COUNT(*) FROM ' + @MFTableName + ' where process_ID = '
              + CAST(@Process_id AS VARCHAR(5)) + '';
        SET @Params = N'@RowCount int output';

        EXEC [sys].[sp_executesql] @VQuery, @Params, @RowCount = @rowcount OUTPUT;

        SET @LogTypeDetail = 'Message';
        SET @LogStatusDetail = 'Completed';
        SET @LogTextDetail = 'Criteria:  ' + @Criteria;
        SET @LogColumnName = 'Object Count';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(5));
        SET @StartTime = GETUTCDATE();

        UPDATE [dbo].[MFUpdateHistory]
        SET [ObjectDetails] = @ObjIDs
           ,[ObjectVerDetails] = @PropertyIDs
        WHERE [Id] = @Update_ID;

        -- note that ability to use a search criteria is not yet active.

        -----------------------------------------------------------------
        -- Checking module access for CLR procdure  spMFGetHistoryInternal
        ------------------------------------------------------------------
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Check License';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetHistory'
                                           ,@ProcedureName
                                           ,@ProcedureStep;

        EXEC [dbo].[spMFGetHistoryInternal] @VaultSettings
                                           ,@ObjectType
                                           ,@ObjIDs
                                           ,@PropertyIDs
                                           ,@SearchString
                                           ,@IsFullHistory
                                           ,@NumberOFDays
                                           ,@StartDate
                                           ,@Result OUT;

        IF @Debug > 1
        BEGIN
            SELECT CAST(@Result AS XML) AS [HistoryXML];
        END;

        IF (@Update_ID > 0)
            UPDATE [dbo].[MFUpdateHistory]
            SET [NewOrUpdatedObjectVer] = @Result
            WHERE [Id] = @Update_ID;

        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @Result;

        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Geet history in wrapper performed';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_id
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        ----------------------------------------------------------------------------------
        --Creating temp table #Temp_ObjectHistory for storing object history xml records
        --------------------------------------------------------------------------------
        SET @ProcedureStep = 'Creating temp table #Temp_ObjectHistory';

        IF (SELECT OBJECT_ID('tempdb..#TempObjIDs')) IS NOT NULL
        DROP TABLE #TempObjids;
        CREATE TABLE [#Temp_ObjectHistory]
        (
            [RowNr] INT IDENTITY
           ,[ObjectType_ID] INT
           ,[Class_ID] INT
           ,[ObjID] INT
           ,[MFVersion] INT
           ,[LastModifiedUTC] NVARCHAR(100)
           ,[MFLastModifiedBy_ID] INT
           ,[Property_ID] INT
           ,[Property_Value] NVARCHAR(300)
           ,[CreatedOn] DATETIME
        );

        INSERT INTO [#Temp_ObjectHistory]
        (
            [ObjectType_ID]
           ,[Class_ID]
           ,[ObjID]
           ,[MFVersion]
           ,[LastModifiedUTC]
           ,[MFLastModifiedBy_ID]
           ,[Property_ID]
           ,[Property_Value]
           ,[CreatedOn]
        )
        SELECT [ObjectType]
              ,[ClassID]
              ,[ObjID]
              ,[Version]
              ,[LastModifiedUTC]
              ,[LastModifiedBy_ID]
              ,[Property_ID]
              ,[Property_Value]
              ,GETDATE()
        FROM
            OPENXML(@Idoc, '/form/Object/Property', 1)
            WITH
            (
                [ObjectType] INT '../@ObjectType'
               ,[ClassID] INT '../@ClassID'
               ,[ObjID] INT '../@ObjID'
               ,[Version] INT '../@Version'
               --      , [LastModifiedUTC] NVARCHAR(30) '../@LastModifiedUTC'
               ,[LastModifiedUTC] NVARCHAR(100) '../@CheckInTimeStamp'
               ,[LastModifiedBy_ID] INT '../@LastModifiedBy_ID'
               ,[Property_ID] INT '@Property_ID'
               ,[Property_Value] NVARCHAR(300) '@Property_Value'
            );

        IF @Debug > 0
            SELECT *
            FROM [#Temp_ObjectHistory] AS [toh];

        EXEC [sys].[sp_xml_removedocument] @Idoc;

        ----------------------------------------------------------------------------------
        --Merge/Inserting records into the MFObjectChangeHistory from Temp_ObjectHistory
        --------------------------------------------------------------------------------
        SET @ProcedureStep = 'Update MFObjectChangeHistory';

        DECLARE @BeforeCount INT;

        SELECT @BeforeCount = COUNT(*)
        FROM [dbo].[MFObjectChangeHistory];

        MERGE INTO [dbo].[MFObjectChangeHistory] AS [t]
        USING
        (SELECT * FROM [#Temp_ObjectHistory] AS [toh]) AS [s]
        ON [t].[ObjectType_ID] = [s].[ObjectType_ID]
           AND [t].[Class_ID] = [s].[Class_ID]
           AND [t].[ObjID] = [s].[ObjID]
           AND [t].[MFVersion] = [s].[MFVersion]
           AND [t].[Property_ID] = [s].[Property_ID]
        WHEN MATCHED THEN
        UPDATE SET 
		[t].[LastModifiedUtc] = dbo.[fnMFTextToDate](s.[LastModifiedUTC],'/')
		,[t].[Property_Value] = s.[Property_Value]
		WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                [ObjectType_ID]
               ,[Class_ID]
               ,[ObjID]
               ,[MFVersion]
               ,[LastModifiedUtc]
               ,[MFLastModifiedBy_ID]
               ,[Property_ID]
               ,[Property_Value]
               ,[CreatedOn]
            )
            VALUES
            (   [s].[ObjectType_ID], [s].[Class_ID], [s].[ObjID], [s].[MFVersion]
               ,dbo.[fnMFTextToDate](s.[LastModifiedUTC],'/'), [s].[MFLastModifiedBy_ID], [s].[Property_ID]
               ,[s].[Property_Value], [s].[CreatedOn]);

        -------------------------------------------------------------
        -- Delete duplicate change records
        -------------------------------------------------------------
        DELETE [dbo].[MFObjectChangeHistory]
        WHERE [ID] IN (
                          SELECT [toh].[ID]
                          FROM [#Temp_ObjectHistory]                   AS [toh2]
                              INNER JOIN [dbo].[MFObjectChangeHistory] AS [toh]
                                  ON [toh].[ObjID] = [toh2].[ObjID]
                                     AND [toh].[Class_ID] = [toh2].[Class_ID]
                                     AND [toh].[Property_ID] = [toh2].[Property_ID]
                                     AND [toh].[MFVersion] = [toh2].[MFVersion]
                              INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
                                  ON [toh].[ObjID] = [moch].[ObjID]
                                     AND [toh].[Class_ID] = [moch].[Class_ID]
                                     AND [toh].[Property_ID] = [moch].[Property_ID]
                                     AND [toh].[Property_Value] = [moch].[Property_Value]
                          WHERE [toh].[MFVersion] = [moch].[MFVersion] + 1
                      );

        SET @rowcount =
        (
            SELECT COUNT(*) FROM [dbo].[MFObjectChangeHistory] AS [moch]
        ) - @BeforeCount;
        -------------------------------------------------------------
        -- Reset process_ID
        -------------------------------------------------------------
        SET @VQuery = N'
					UPDATE ' + @MFTableName + '
					SET Process_ID = 0 WHERE process_ID = ' + CAST(@Process_id AS VARCHAR(5)) + '';

        EXEC (@VQuery);

        --truncate table MFObjectChangeHistory
        IF (SELECT OBJECT_ID('tempdb..#Temp_ObjectHistory')) IS NOT NULL
        DROP TABLE [#Temp_ObjectHistory];
         IF (SELECT OBJECT_ID('tempdb..#TempObjIDs')) IS NOT NULL
        DROP TABLE #TempObjids;

        SET @ProcessType = @ProcedureName;
        SET @LogText = @ProcedureName + ' Ended ';
        SET @LogStatus = 'Completed';
        SET @StartTime = GETUTCDATE();

        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_id
                                                     ,@ProcessType = @ProcessType
                                                     ,@LogType = @LogType
                                                     ,@LogText = @LogText
                                                     ,@LogStatus = @LogStatus
                                                     ,@debug = @Debug;

        SET @LogTypeDetail = 'Message';
        SET @LogTextDetail = 'History inserted in MFObjectChangeHistory';
        SET @LogStatusDetail = 'Completed';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = 'New History';
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(5));

        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_id
                                                           ,@LogType = @LogTypeDetail
                                                           ,@LogText = @LogTextDetail
                                                           ,@LogStatus = @LogStatusDetail
                                                           ,@StartTime = @StartTime
                                                           ,@MFTableName = @MFTableName
                                                           ,@Validation_ID = @Validation_ID
                                                           ,@ColumnName = @LogColumnName
                                                           ,@ColumnValue = @LogColumnValue
                                                           ,@Update_ID = @Update_ID
                                                           ,@LogProcedureName = @ProcedureName
                                                           ,@LogProcedureStep = @ProcedureStep
                                                           ,@debug = @Debug;
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
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY()
        ,ERROR_LINE(), @ProcedureStep);

        SET @ProcedureStep = 'Catch Error';

        -------------------------------------------------------------
        -- Log Error
        -------------------------------------------------------------   
        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_id OUTPUT
                                            ,@ProcessType = @ProcessType
                                            ,@LogType = N'Error'
                                            ,@LogText = @LogTextDetail
                                            ,@LogStatus = @LogStatus
                                            ,@debug = @Debug;

        SET @StartTime = GETUTCDATE();

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_id
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
END;
GO
