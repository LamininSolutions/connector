PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFTableAudit]';
GO

set nocount on;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFTableAudit', -- nvarchar(100)
                                 @Object_Release = '4.10.30.75',   -- varchar(50)
                                 @UpdateFlag = 2;                 -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFTableAudit' --name of procedure
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
CREATE PROCEDURE dbo.spMFTableAudit
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFTableAudit
(
    @MFTableName NVARCHAR(128),
    @MFModifiedDate DATETIME = NULL,    --NULL to select all records
    @ObjIDs NVARCHAR(max) = NULL,
    @SessionIDOut INT OUTPUT,           -- output of session id
    @NewObjectXml NVARCHAR(MAX) OUTPUT, -- return from M-Files
    @DeletedInSQL INT = 0 OUTPUT,       -- number of items deleted
    @UpdateRequired BIT = 0 OUTPUT,     --1 is set when the result show a difference between MFiles and SQL  
    @OutofSync INT = 0 OUTPUT,          -- > 0 eminent Sync Error when update from SQL to MF is processed
    @ProcessErrors INT = 0 OUTPUT,      -- > 0 unfixed errors on table
    @UpdateTypeID INT = 1, --set to 0 to force a full update
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0                 -- use 102 for listing of full tables during debugging
)
AS
/*rST**************************************************************************

==============
spMFTableAudit
==============

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(128)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @MFModifiedDate datetime
    Filter by MFiles Last Modified date as a datetime string. Set to null if all records must be selected
  @ObjIDs nvarchar(4000)
    Filter by comma delimited string of objid of the objects to process. Set as null if all records must be included
  @SessionIDOut int (output)
    Output of the session id used to update table MFAuditHistory
  @NewObjectXml nvarchar(max) (output)
    Output of the objver of the record set as a result in nvarchar datatype. This can be converted to an XML record for further processing
  @DeletedInSQL int (output)
    Output the number of items that will be marked as deleted when processing the next spmfUpdateTable
  @UpdateRequired bit (output)
    Set to 1 if any condition exist where M-Files and SQL is not the same.  This can be used to trigger a spmfUpdateTable only when it necessary
  @OutofSync int (output)
    If > 0 then the next updatetable procedure will have synchronisation errors
  @ProcessErrors int (output)
    If > 0 then there are unresolved errors in the table with process_id = 3 or 4
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Update MFAuditHistory and return the sessionid and the M-Files objver of the selection class as a varchar that can be converted to XML if there is a need for further processing of the result.

Additional Info
===============

At the same time spMFTableAudit will set the deleted flag for all the records in the Class Table that is deleted in M-Files.  This is particularly relevant when this procedure is used in conjunction with the spMFUpdateTable procedure with the filter MFLastModified set.

Examples
========

.. code:: sql

    DECLARE @SessionIDOut INT
           ,@NewObjectXml NVARCHAR(MAX)
           ,@DeletedInSQL INT
           ,@UpdateRequired BIT
           ,@OutofSync INT
           ,@ProcessErrors INT
           ,@ProcessBatch_ID INT;

    EXEC [dbo].[spMFTableAudit]
               @MFTableName = N'MFCustomer' -- nvarchar(128)
              ,@MFModifiedDate = null -- datetime
              ,@ObjIDs = null -- nvarchar(4000)
              ,@SessionIDOut = @SessionIDOut OUTPUT -- int
              ,@NewObjectXml = @NewObjectXml OUTPUT -- nvarchar(max)
              ,@DeletedInSQL = @DeletedInSQL OUTPUT -- int
              ,@UpdateRequired = @UpdateRequired OUTPUT -- bit
              ,@OutofSync = @OutofSync OUTPUT -- int
              ,@ProcessErrors = @ProcessErrors OUTPUT -- int
              ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
              ,@Debug = 0 -- smallint

    SELECT @SessionIDOut AS 'session', @UpdateRequired AS UpdateREquired, @OutofSync AS OutofSync, @ProcessErrors AS processErrors
    SELECT * FROM [dbo].[MFProcessBatch] AS [mpb] WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID
    SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-06-30  LC         allow for specifying date in UTC
2023-04-05  LC         refine options for selecting default date
2022-09-08  LC         simplify query for flag 5 to ellimate objects not in Audit table
2022-01-28  LC         set objids datatype to max
2022-01-08  LC         new code to deal with class changes
2021-12-20  LC         add revalidate of deleted objects when incremental update
2021-12-20  LC         add checking of objvers where full update did not update them
2021-12-16  LC         Add additional logging for performance monitoring
2021-04-01  LC         Add statusflag for Collections
2020-09-08  LC         Update to include status code 5 object does not exist
2020-09-04  LC         Add update locking and commit to improve performance
2020-08-22  LC         update to take into account new deleted column
2019-12-10  LC         Fix bug for the removal of records from class table
2019-10-31  LC         Fix bug - change Class_id to Class in delete object section 
2019-09-12  LC         Fix bug - remove deleted objects from table
2019-08-30  JC         Added documentation
2019-08-16  LC         Fix bug for removing destroyed objects
2019-06-22  LC         Objid parameter not yet functional
2019-05-18  LC         Add additional exception for deleted in SQL but not deleted in MF
2019-04-11  LC         Fix collection object type in table
2019-04-11  LC         Add large table protection
2019-04-11  LC         Add validation table exists
2018-12-15  LC         Add ability to get result for selected objids
2018-08-01  LC         Resolve issue with having try catch in transaction processing
2017-12-28  LC         Change insert to merge on audit table
2017-12-27  LC         Remove incorrect error message
2017-08-28  LC         Add param for update required
2017-08-28  LC         Add logging
2017-08-28  LC         Change sequence of params
2016-08-22  LC         Change objids to NVARCHAR(4000)
==========  =========  ========================================================

**rST*************************************************************************/

/*

DECLARE @SessionIDOut int, @return_Value int, @NewXML nvarchar(max)
EXEC @return_Value = spMFTableAudit 'MFOtherdocument' , null, null, 1, @SessionIDOut = @SessionIDOut output, @NewObjectXml = @NewXML output
SELECT @SessionIDOut ,@return_Value, @NewXML

*/

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
SET NOCOUNT ON;

DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = N'Table Audit';

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
DECLARE @ProcedureName AS NVARCHAR(128) = N'spMFTableAudit';
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

DECLARE @Username NVARCHAR(2000);
DECLARE @VaultName NVARCHAR(2000);
DECLARE @VaultSettings NVARCHAR(4000);
DECLARE @updateMethod INT = 10;

SELECT TOP 1
       @Username = Username,
       @VaultName = VaultName
FROM dbo.MFVaultSettings;

SELECT @VaultSettings = dbo.FnMFVaultSettings();

SET @StartTime = GETUTCDATE();

INSERT INTO dbo.MFUpdateHistory
(
    Username,
    VaultName,
    UpdateMethod
)
VALUES
(@Username, @VaultName, @updateMethod);

SELECT @Update_ID = @@Identity;

EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                 @ProcessType = @ProcessType,
                                 @LogType = N'Status',
                                 @LogText = @LogText,
                                 @LogStatus = N'In Progress',
                                 @debug = @Debug;

EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                       @LogType = N'Debug',
                                       @LogText = @LogText,
                                       @LogStatus = N'Started',
                                       @StartTime = @StartTime,
                                       @MFTableName = @MFTableName,
                                       @Validation_ID = @Validation_ID,
                                       @ColumnName = NULL,
                                       @ColumnValue = NULL,
                                       @Update_ID = @Update_ID,
                                       @LogProcedureName = @ProcedureName,
                                       @LogProcedureStep = @ProcedureStep,
                                       @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
                                       @debug = @Debug;

BEGIN TRY
    SET XACT_ABORT ON;

    SET @StartTime = GETUTCDATE();

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    DECLARE @Id INT,
            @objID INT,
            @ObjectIdRef INT,
            @ObjVersion INT,
            @XMLOut NVARCHAR(MAX),
            @MinObjid INT,
            @MaxObjid INT,
            @DefaultDate DATETIME = '1975-01-01',
                                           --             @Output NVARCHAR(200) ,
            @FullXml XML,                  --
            @SynchErrorObj NVARCHAR(MAX),  --Declared new paramater
            @DeletedObjects NVARCHAR(MAX), --Declared new paramater
            @ObjectId INT,
            @ClassId INT,
            @ErrorInfo NVARCHAR(MAX),
            @MFIDs NVARCHAR(2500) = N'',
            @RunTime VARCHAR(20),
            @DeletedColumn NVARCHAR(100),
            @MFidsNotFound BIT = 0;
    DECLARE @outPutDeletedXML NVARCHAR(MAX);

    -------------------------------------------------------------
    -- get deleted column name
    -------------------------------------------------------------
    SELECT @DeletedColumn = ColumnName
    FROM dbo.MFProperty
    WHERE MFID = 27;

    DECLARE @Idoc INT;

    IF EXISTS
    (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND type IN ( N'U' )
    )
    BEGIN
        -----------------------------------------------------
        --Set Object Type Id and class id
        -----------------------------------------------------
        SET @ProcedureStep = N'Get Object Type and Class';

        SELECT @ObjectIdRef = mc.MFObjectType_ID,
               @ObjectId = ob.MFID,
               @ClassId = mc.MFID
        FROM dbo.MFClass AS mc
            INNER JOIN dbo.MFObjectType AS ob
                ON ob.ID = mc.MFObjectType_ID
        WHERE mc.TableName = @MFTableName;

        SET @ProcedureStep = N'Table details ';
        SET @DebugText = N'ObjectType: %i Class: %i Objids count %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF
        (
            SELECT OBJECT_ID('tempdb..#objidtable')
        ) IS NOT NULL
            DROP TABLE #Objidtable;

        CREATE TABLE #ObjidTable
        (
            objid INT PRIMARY KEY
        );

        INSERT INTO #ObjidTable
        (
            objid
        )
        SELECT DISTINCT fmpds.ListItem
        FROM dbo.fnMFParseDelimitedString(@ObjIDs, ',') AS fmpds;

        SELECT @count = @@RowCount;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId, @ClassId, @count);
        END;

        -------------------------------------------------------------
        -- Get class table name
        -------------------------------------------------------------
        DECLARE @ClassTableColumn NVARCHAR(100);

        SELECT @ClassTableColumn = ColumnName
        FROM dbo.MFProperty
        WHERE MFID = 100;

        -----------------------------------------------------
        --Set default date
        -----------------------------------------------------
        SET @DefaultDate = CASE
                               WHEN @MFModifiedDate is not null and @ObjIDs is null THEN
                                    dateadd(day,0,@MFModifiedDate)
                               WHEN @MFModifiedDate is not null and @ObjIDs is not null THEN
                                    dateadd(day,0,@MFModifiedDate)
                               when @MFModifiedDate is null and @ObjIDs IS NOT null THEN
                                   @DefaultDate
                               WHEN @MFModifiedDate IS null and @ObjIDs is null THEN
                                   @DefaultDate                                
                               ELSE
                                   @DefaultDate
                           END;
        --SET @DebugText = N' filter on date ' + CAST(@DefaultDate AS NVARCHAR(30));
        --SET @DebugText = @DefaultDebugText + @DebugText;

        --IF @Debug > 0
        --BEGIN
        --    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        --END;

        -------------------------------------------------------------
        -- update MFupdateHistory
        -------------------------------------------------------------
        SET @ProcedureStep = N'Update MFUpdateHistory';

        DECLARE @ObjectDetails XML;
        DECLARE @ObjectVersionDetails XML;

        SET @ObjectDetails =
        (
            SELECT @ObjectId AS [ObjectType/@ObjectTypeid],
                   @ClassId AS [ObjectType/@ClassID]
            FOR XML PATH(''), ROOT('form')
        );
        SET @ObjectVersionDetails =
        (
            SELECT ot.objid AS [Object/@Objectid]
            FROM #ObjidTable AS ot
            FOR XML PATH(''), ROOT('form')
        );

        UPDATE dbo.MFUpdateHistory
        SET ObjectDetails = @ObjectDetails,
            ObjectVerDetails = @ObjectVersionDetails
        WHERE Id = @Update_ID;

        SET @ProcedureStep = N' Get Filters ';
        SET @LogTypeDetail = N'Debug';
        SET @LogTextDetail
            = N'Criteria: date ' + CAST(@DefaultDate AS NVARCHAR(30)) + N' Objids: '
              + CAST(ISNULL(@count, 0) AS NVARCHAR(10));
        SET @LogStatusDetail = N'Objid Count';
        SET @Validation_ID = NULL;
        SET @LogColumnName = @MFTableName;
        SET @LogColumnValue = CAST(ISNULL(@count, 0) AS NVARCHAR(10));

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

        --SET @DebugText = N' :on date ' + CAST(@DefaultDate AS NVARCHAR(30));
        --SET @DebugText = @DefaultDebugText + @DebugText;

        --IF @Debug > 0
        --BEGIN
        --    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        --END;

        --IF @Debug > 0
        --    RAISERROR('Proc: %s Step: %s ObjectVerDetails ', 10, 1, @ProcedureName, @ProcedureStep);

        -------------------------------------------------------------
        -- Check connection to vault
        -------------------------------------------------------------
        SET @ProcedureStep = N'Connection test: ';

        EXEC @return_value = dbo.spMFConnectionTest;

        IF @return_value <> 1
        BEGIN
            SET @DebugText = N'Connection failed ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @StartTime = GETUTCDATE();
        SET @ProcedureStep = N'wrapper';

        IF @return_value = 1 
        BEGIN

        --IF @debug > 0
        --SELECT 'objids',* FROM dbo.fnMFParseDelimitedString(@Objids,',') AS fmpds;

            EXECUTE @return_value = dbo.spMFGetObjectVersInternal @VaultSettings = @VaultSettings,
                                                                  @ClassID = @ClassId,
                                                                  @dtModifieDateTime = @DefaultDate,
                                                                  @MFIDs = @ObjIDs,
                                                                  @ObjverXML = @NewObjectXml OUTPUT,
                                                                  @DelObjverXML = @outPutDeletedXML OUTPUT;
        END;

        SET @LogTypeDetail = N'Status';
        SET @LogStatusDetail = N' Assembly';
        SET @LogTextDetail = N'spMFGetObjectVersInternal';
        SET @LogColumnName = N'';
        SET @LogColumnValue = N'';

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

        IF @Debug > 0
        BEGIN
            SELECT @NewObjectXml AS ObjVerOutput_preformatted,
                   @outPutDeletedXML AS DeletedObject;
        END;

        SELECT @NewObjectXml = CASE
                                   WHEN @NewObjectXml = '' THEN
                                       '<form>'
                                   WHEN @NewObjectXml = '<form />' THEN
                                       '<form>'
                                   ELSE
                                       REPLACE(@NewObjectXml, '</form>', '')
                               END + CASE
                                         WHEN @outPutDeletedXML = '' THEN
                                             '</form>'
                                         WHEN @outPutDeletedXML = '<form />' THEN
                                             '</form>'
                                         ELSE
                                             REPLACE(@outPutDeletedXML, '<form>', '')
                                     END;

        IF (
               @NewObjectXml <> '<form /><form />'
               OR ISNULL(@NewObjectXml, '<form />') <> '<form />'
           )
        BEGIN
            EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @NewObjectXml;

            SELECT @rowcount = COUNT(xmlfile.objId)
            FROM
                OPENXML(@Idoc, '/form/objVers', 1)WITH (objId INT './@objectID') xmlfile;

            SET @DebugText = N' wrapper returned result with count %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Processing result ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                SELECT CAST(@NewObjectXml AS XML) AS [@NewObjectXml_postformatted];

            END;                     

            SET @LogTypeDetail = N'Debug';
            SET @LogTextDetail = N'get objver in batches';
            SET @LogStatusDetail = N'in Progress';
            SET @Validation_ID = NULL;
            SET @LogColumnValue = N'';
            SET @LogColumnName = N'';

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
    
            SET @StartTime = GETUTCDATE();

            UPDATE dbo.MFUpdateHistory
            SET NewOrUpdatedObjectVer = CAST(@NewObjectXml AS XML)
            WHERE Id = @Update_ID;

            --       EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @NewObjectXml;
            IF @NewObjectXml = '<form></form>'
               AND @ObjIDs IS NOT NULL
                SET @MFidsNotFound = 1;

            --IF @Debug > 0
            --BEGIN
            --    SELECT @MFidsNotFound AS Null_return;
          --  END;

            BEGIN
                SET @ProcedureStep = N'Create Temp table';

                IF
                (
                    SELECT OBJECT_ID('tempdb..#AllObjects')
                ) IS NOT NULL
                    DROP TABLE #AllObjects;

                CREATE TABLE #AllObjects
                (
                    ID INT,
                    Class INT,
                    ObjectType INT,
                    ObjID INT,
                    MFVersion INT,
                    Deleted NVARCHAR(10),
                    LastModifiedUtc DATETIME,
                    CheckedOutTo INT,
                    LatestCheckedInVersion INT,
                    StatusFlag SMALLINT
                );

                CREATE INDEX idx_AllObjects_ObjID ON #AllObjects (ObjID);

                SET @ProcedureStep = N' Insert items in Temp Table';

                IF @NewObjectXml <> '<form></form>'
                BEGIN;
                    WITH cte
                    AS (SELECT DISTINCT
                               xmlfile.objId,
                               xmlfile.MFVersion,
                               xmlfile.ObjType,
                               xmlfile.Deleted,
                               xmlfile.LastModifiedUtc,
                               xmlfile.CheckedOutTo,
                               xmlfile.LatestCheckedInVersion
                        FROM
                            OPENXML(@Idoc, '/form/objVers', 1)
                            WITH
                            (
                                objId INT './@objectID',
                                MFVersion INT './@version',
                                --         ,[GUID] NVARCHAR(100) './@objectGUID'
                                ObjType INT './@objectType',
                                Deleted NVARCHAR(10) './@Deleted',
                                LastModifiedUtc DATETIME './@LastModifiedUtc',
                                CheckedOutTo INT './@CheckedOutTo',
                                LatestCheckedInVersion INT './@LatestCheckedInVersion'
                            ) xmlfile)
                    INSERT INTO #AllObjects
                    (
                        Class,
                        ObjectType,
                        MFVersion,
                        ObjID,
                        Deleted,
                        LastModifiedUtc,
                        CheckedOutTo,
                        LatestCheckedInVersion
                    )
                    SELECT @ClassId,
                           cte.ObjType,
                           cte.MFVersion,
                           cte.objId,
                           cte.Deleted,
                           cte.LastModifiedUtc,
                           cte.CheckedOutTo,
                           cte.LatestCheckedInVersion
                    FROM cte;
                END;

                IF @MFidsNotFound = 1
                BEGIN
                    INSERT INTO #AllObjects
                    (
                        ID,
                        Class,
                        ObjectType,
                        ObjID,
                        MFVersion,
                        Deleted,
                        LastModifiedUtc,
                        CheckedOutTo,
                        LatestCheckedInVersion,
                        StatusFlag
                    )
                    SELECT mah.ID,
                           @ClassId,
                           @ObjectId,
                           fmpds.objid,
                           NULL,
                           'True',
                           NULL,
                           0,
                           NULL,
                           4
                    FROM #ObjidTable AS fmpds
                        LEFT JOIN dbo.MFAuditHistory AS mah
                            ON fmpds.objid = mah.ObjID
                               AND mah.Class = @ClassId
                               AND mah.ObjectType = @ObjectId;
                END; --@MFidsNotFound = 1

                SELECT @rowcount = ISNULL(COUNT(ao.ObjID), 0)
                FROM #AllObjects AS ao;

                SET @DebugText = N' count ' + CAST(ISNULL(@rowcount, 0) AS NVARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = N' Create #AllObjects ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @Idoc IS NOT NULL
                    EXEC sys.sp_xml_removedocument @Idoc;

                SET @ProcedureStep = N'Get Object Versions';
                SET @StartTime = GETUTCDATE();
                SET @LogTypeDetail = N'Debug';
                SET @LogTextDetail = N'Objects from M-Files';
                SET @LogStatusDetail = N'Status';
                SET @LogColumnName = N'Objvers returned';
                SET @LogColumnValue = CAST(ISNULL(@rowcount, 0) AS VARCHAR(10));

                EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
                                                       @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
                                                       @debug = 0;
            END; -- return is not null

            SET @StartTime = GETUTCDATE();

            IF @Debug > 0
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                SELECT 'PreFlag',
                       *
                FROM #AllObjects AS ao;
            END;

            DECLARE @Query NVARCHAR(MAX),
                    @SessionID INT,
                    @TranDate DATETIME,
                    @Params NVARCHAR(MAX);

            SELECT @TranDate = GETDATE();

            SET @ProcedureStep = N'Get Session ID ';

            -- check if MFAuditHistory has been initiated
            SELECT @count = COUNT(ISNULL(mah.ID, 0))
            FROM dbo.MFAuditHistory AS mah;

            SELECT @SessionID = CASE
                                    WHEN @SessionIDOut IS NULL
                                         AND @count = 0 THEN
                                        1
                                    WHEN @SessionIDOut IS NULL
                                         AND @count > 0 THEN
            (
                SELECT MAX(ISNULL(SessionID, 0)) + 1 FROM dbo.MFAuditHistory
            )
                                    ELSE
                                        @SessionIDOut
                                END;

            SET @DebugText = CAST(@SessionID AS NVARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- pre validations
            -------------------------------------------------------------
            /*

0 = identical : [ao].[LatestCheckedInVersion] = [t].[MFVersion] AND [ao].[deleted]= 'False' and DeletedColumn is null
1 = MF IS Later : [ao].[LatestCheckedInVersion] > [t].[MFVersion]  
2 = SQL is later : ao.[LatestCheckedInVersion] < ISNULL(t.[MFVersion],-1) 
3 = Checked out : ao.CheckedoutTo <> 0
4 =  Deleted SQL to be updated : WHEN isnull(ao.[Deleted],'True' and isnull(t.DeletedColumn,'False')
5 =  In SQL Not in audit table : N t.[MFVersion] is null and ao.[MFVersion] is not null   
6 = Not yet process in SQL : t.id IS NOT NULL AND t.objid IS NULL
9 = Object is collection : ObjectType = 9 
*/
            SET @ProcedureStep = N' set flags: ';

            SELECT @Query
                = N'UPDATE ao
SET ao.[ID] = isnull(t.id,-1)
,StatusFlag = CASE 
WHEN ao.ObjectType = 9 then 9
WHEN isnull(ao.CheckedOutTo,0) <> 0 then 3
WHEN ISNULL(ao.Deleted,''False'') = ''True''  THEN 4
WHEN ao.[LatestCheckedInVersion] < ISNULL(t.[MFVersion],-1) THEN 2
WHEN [ao].[LatestCheckedInVersion] > ISNULL([t].[MFVersion],-1)  THEN 1
WHEN [ao].[LatestCheckedInVersion] = ISNULL([t].[MFVersion],-1) THEN 0
WHEN ISNULL(ao.id,0) = 0 AND ISNULL(ao.[objid],0) > 0 THEN 6
else 
1
END 
FROM [#AllObjects] AS [ao]
left JOIN ' +   QUOTENAME(@MFTableName) + N' t
ON ao.[objid] = t.[objid] ;';

            EXEC sys.sp_executesql @Stmt = @Query;

            SET @DebugText = N'Updated Ids and flags';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                SELECT 'Flagged',
                       *
                FROM #AllObjects AS ao;

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

        
            -------------------------------------------------------------
            -- Insert records within the range of the audit that is in SQL but not in table audit
            -- only applies when full update
            -------------------------------------------------------------
IF @UpdateTypeID = 0
BEGIN
SET @SQL = NULL
    SET @ProcedureStep = N' reset flag 5 ';
            SET @Params = N'@ClassID int, @ObjectID int,  @Objids nvarchar(max)';
            SET @sql
                =  N' SELECT t.id, GETDATE(), @ObjectID, @Classid, t.objid,  t.MFVersion,0
                    FROM ' + QUOTENAME(@MFTableName)
                          + N' t
                    LEFT JOIN dbo.MFAuditHistory mah
        ON t.ObjID = mah.ObjID AND mah.Class = @ClassID AND mah.ObjectType = @ObjectID
WHERE mah.ObjID IS NULL AND t.GUID IS NOT NULL;

                     ;
                    '
                    ; --end case
          
            SET @ProcedureStep = N' Added mismatches ';
            SET @rowcount = 0;

            IF @sql IS NOT NULL
            BEGIN
                INSERT INTO #AllObjects
                (
                    ID,
                    LastModifiedUtc,
                    ObjectType,
                    Class,
                    ObjID,
                    MFVersion,
                    StatusFlag
                )
                EXEC sys.sp_executesql @Stmt = @sql,
                                       @Param = @Params,
                                       @ClassId = @ClassId,
                                       @ObjectId = @ObjectId,
                                       @ObjIDs = @ObjIDs;

                SET @rowcount = @@RowCount;

                SET @DebugText = N' count ' + CAST(ISNULL(@rowcount, 0) AS NVARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END; -- if @sql is not null

            END --- updatetypeID = 0
            -------------------------------------------------------------
            -- processing destroyed 
            -----------------------------------------------------------
  
  IF @objids IS NULL AND @UpdateTypeID = 0
          BEGIN
          SET @ProcedureStep = N' Destroyed objects ';

            SET @rowcount = 0;
            WITH cte
            AS (SELECT mah.ObjectType,
                       mah.Class,
                       mah.ObjID
                FROM dbo.MFAuditHistory AS mah
                WHERE mah.ObjectType = @ObjectId
                      AND mah.Class = @ClassId
                EXCEPT
                SELECT ao.ObjectType,
                       ao.Class,
                       ao.ObjID
                FROM #AllObjects AS ao)
            UPDATE mah
            SET mah.StatusFlag = 5,
                mah.StatusName = 'Not in Class'
            FROM dbo.MFAuditHistory AS mah
                INNER JOIN cte
                    ON cte.ObjID = mah.ObjID
                    WHERE cte.Class = mah.Class
                       AND cte.ObjectType = mah.ObjectType;

            SET @rowcount = @@RowCount;
            SET @DebugText = N' count ' + CAST(ISNULL(@rowcount, 0) AS NVARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                

                SELECT 'Added_mismatches',
                       ao.ID,
                       ao.Class,
                       ao.ObjectType,
                       ao.ObjID,
                       ao.MFVersion,
                       ao.Deleted,
                       ao.LastModifiedUtc,
                       ao.CheckedOutTo,
                       ao.LatestCheckedInVersion,
                       ao.StatusFlag
                FROM #AllObjects AS ao;
                END -- debug
            END;
            -- if @NewXML is not empty
            -------------------------------------------------------------
            -- reset status flag where version is the same 
            -----------------------------------------------------------
            SET @ProcedureStep = N' Reset status flag for matching versions ';

            SET @rowcount = 0;
            UPDATE mah
            SET mah.StatusFlag = ao.StatusFlag,
                mah.StatusName = CASE
                                     WHEN ao.StatusFlag = 0 THEN
                                         'Identical'
                                     WHEN ao.StatusFlag = 1 THEN
                                         'MF is later'
                                     WHEN ao.StatusFlag = 3 THEN
                                         'Checked out'
                                     WHEN ao.StatusFlag = 4 THEN
                                         'Deleted'
                                 END,
                mah.UpdateFlag = 0
            FROM #AllObjects AS ao
                INNER JOIN dbo.MFAuditHistory AS mah
                    ON ao.ObjectType = mah.ObjectType
                       AND ao.Class = mah.Class
                       AND ao.ObjID = mah.ObjID
            WHERE ao.MFVersion = mah.MFVersion
                  AND ao.StatusFlag <> mah.StatusFlag;


            SET @rowcount = @@RowCount;
            SET @DebugText = N' count ' + CAST(ISNULL(@rowcount, 0) AS NVARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- Processing class changes
            -------------------------------------------------------------
     IF @UpdateTypeID = 0
     Begin
     SET @ProcedureStep = N' Class changes ';

            SET @rowcount = 0;
            WITH cte
            AS (SELECT mah.ObjID
                FROM dbo.MFAuditHistory AS mah
                WHERE mah.ObjectType =  @ObjectId
                GROUP BY mah.ObjID
                HAVING COUNT(mah.ObjID) > 1),
                 cte2
            AS (SELECT RANK() OVER (PARTITION BY cte.ObjID ORDER BY mah.MFVersion DESC) versionrank,
                       mah.ID,
                       mah.Class,
                       mah.MFVersion,
                       cte.ObjID
                FROM dbo.MFAuditHistory mah
                    INNER JOIN cte
                        ON mah.ObjID = cte.ObjID
                WHERE mah.ObjectType = @ObjectId)
            UPDATE mah
            SET mah.StatusFlag = 5,
                mah.StatusName = 'Not In Class'
            FROM dbo.MFAuditHistory AS mah
                INNER JOIN cte2
                    ON mah.ID = cte2.ID
            WHERE cte2.versionrank <> 1;

            SET @rowcount = @@RowCount;
            SET @DebugText = N' count ' + CAST(ISNULL(@rowcount, 0) AS NVARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            END -- if UpdateID = 0

            SET @ProcedureStep = N' update audit history ';

            DECLARE @TotalObjver INT;
            DECLARE @FilteredObjver INT;
            DECLARE @ToUpdateObjver INT;
            DECLARE @NotInAuditHistory INT;

            SELECT @TotalObjver = COUNT(ISNULL(mah.ID, 0))
            FROM dbo.MFAuditHistory AS mah
            WHERE mah.Class = @ClassId;

            SELECT @FilteredObjver = COUNT(ISNULL(ao.ID, 0))
            FROM #AllObjects AS ao;

            SELECT @ToUpdateObjver = COUNT(ISNULL(ao.ID, 0))
            FROM #AllObjects AS ao
            WHERE ao.StatusFlag <> 0;

            SELECT @NotInAuditHistory = COUNT(ISNULL(ao.ID, 0))
            FROM #AllObjects AS ao
                LEFT JOIN dbo.MFAuditHistory AS mah
                    ON mah.Class = ao.Class
                       AND mah.ObjID = ao.ObjID
            WHERE mah.ObjID IS NULL;

            SET @LogTypeDetail = N'Status';
            SET @LogStatusDetail = N'In progress';
            SET @LogTextDetail
                = N'MFAuditHistory: Total: ' + CAST(COALESCE(@TotalObjver, 0) AS NVARCHAR(10)) + N' From MF: '
                  + CAST(COALESCE(@FilteredObjver, 0) AS NVARCHAR(10)) + N' Flag not 0: '
                  + CAST(COALESCE(@ToUpdateObjver, 0) AS NVARCHAR(10)) + N' New in audit history: '
                  + CAST(COALESCE(@NotInAuditHistory, 0) AS NVARCHAR(10));
            SET @LogColumnName = N'Objvers to update';
            SET @LogColumnValue = CAST(COALESCE(@ToUpdateObjver, 0) AS NVARCHAR(10));

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

            --Delete redundant objects in class table in SQL: this can only be applied when a full Audit is performed
            --7 = Marked deleted in SQL not deleted in MF : [t].[Deleted] = 1
            SET @ProcedureStep = N'Delete redundants in SQL';
            SET @StartTime = GETUTCDATE();


            -------------------------------------------------------------
            -- Process objversions to audit history
            -------------------------------------------------------------
             IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                    SELECT 'After flag reset',
                           ao.ID,
                           ao.Class,
                           ao.ObjectType,
                           ao.ObjID,
                           ao.MFVersion,
                           ao.Deleted,
                           ao.LastModifiedUtc,
                           ao.CheckedOutTo,
                           ao.LatestCheckedInVersion,
                           ao.StatusFlag
                    FROM #AllObjects AS ao;
                END;
            IF @ToUpdateObjver > 0
               OR @NotInAuditHistory > 0
            BEGIN
                SET @ProcedureStep = N'Insert into Audit History';

                IF @Debug > 0
                BEGIN
                    SELECT 'Insert into AuditHistory ',
                           src.ID,
                           src.Class,
                           src.ObjectType,
                           src.ObjID,
                           src.MFVersion,
                           src.Deleted,
                           src.LastModifiedUtc,
                           src.CheckedOutTo,
                           src.LatestCheckedInVersion,
                           src.StatusFlag                           
                    FROM #AllObjects AS src
                        LEFT JOIN dbo.MFAuditHistory AS targ
                            ON targ.ObjID = src.ObjID
                               AND targ.Class = src.Class
                               AND targ.ObjectType = src.ObjectType
                    WHERE targ.ID IS NULL;
                END;

                INSERT INTO dbo.MFAuditHistory
                (
                    SessionID,
                    TranDate,
                    ObjectType,
                    Class,
                    ObjID,
                    MFVersion,
                    StatusFlag,
                    StatusName,
                    UpdateFlag
                )
                SELECT @SessionID,
                       @TranDate,
                       src.ObjectType,
                       src.Class,
                       src.ObjID,
                       src.MFVersion,
                       src.StatusFlag,
                       CASE
                           WHEN src.StatusFlag = 0 THEN
                               'Identical'
                           WHEN src.StatusFlag = 1 THEN
                               'MF is later'
                           WHEN src.StatusFlag = 2 THEN
                               'SQL is later'
                           WHEN src.StatusFlag = 3 THEN
                               'Checked out'
                           WHEN src.StatusFlag = 4 THEN
                               'Deleted'
                           WHEN src.StatusFlag = 5 THEN
                               'Not in Class'
                           WHEN src.StatusFlag = 6 THEN
                               'Not yet processed in SQL'
                           WHEN src.StatusFlag = 9 THEN
                               'Document Collection'
                       END,
                       1
                FROM #AllObjects AS src
                    LEFT JOIN dbo.MFAuditHistory AS targ
                        ON targ.ObjID = src.ObjID
                           AND targ.Class = src.Class
                           AND targ.ObjectType = src.ObjectType
                WHERE targ.ID IS NULL;

                SET @rowcount = @@RowCount;
                SET @DebugText = N' Count %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

               
                SET @ProcedureStep = N'Update records in Audit History';

                IF @Debug > 0
                BEGIN
                    SELECT 'To update',
                           *
                    FROM dbo.MFAuditHistory AS targ
                        INNER JOIN #AllObjects AS src
                            ON targ.ObjID = src.ObjID
                               AND targ.Class = src.Class
                               AND targ.ObjectType = src.ObjectType
                    WHERE src.ID <> ISNULL(targ.RecID,0)
                          OR src.MFVersion <> ISNULL(targ.MFVersion,0)
                          OR src.StatusFlag <> ISNULL(targ.StatusFlag,0)
                          OR ISNULL(targ.StatusName,0) <>  CASE
                           WHEN src.StatusFlag = 0 THEN
                               'Identical'
                           WHEN src.StatusFlag = 1 THEN
                               'MF is later'
                           WHEN src.StatusFlag = 2 THEN
                               'SQL is later'
                           WHEN src.StatusFlag = 3 THEN
                               'Checked out'
                           WHEN src.StatusFlag = 4 THEN
                               'Deleted'
                           WHEN src.StatusFlag = 5 THEN
                               'Not in Class'
                           WHEN src.StatusFlag = 6 THEN
                               'Not yet processed in SQL'
                           WHEN src.StatusFlag = 9 THEN
                               'Document Collection'
                               END;
                END;

                BEGIN TRAN;
                UPDATE targ
                SET targ.RecID = src.ID,
                    targ.SessionID = @SessionID,
                    targ.TranDate = @TranDate,
                    targ.MFVersion = src.MFVersion,
                    targ.StatusFlag = src.StatusFlag,
                    targ.StatusName = CASE
                                          WHEN src.StatusFlag = 0 THEN
                                              'Identical'
                                          WHEN src.StatusFlag = 1 THEN
                                              'MF is later'
                                          WHEN src.StatusFlag = 2 THEN
                                              'SQL is later'
                                          WHEN src.StatusFlag = 3 THEN
                                              'Checked out'
                                          WHEN src.StatusFlag = 4 THEN
                                              'Deleted'
                                          WHEN src.StatusFlag = 5 THEN
                                              'Not in Class'
                                          WHEN src.StatusFlag = 6 THEN
                                              'Not yet processed in SQL'
                                          WHEN src.StatusFlag = 9 THEN
                                              'Document Collection'
                                      END,
                    targ.UpdateFlag = CASE
                                          WHEN ISNULL(src.StatusFlag, 0) <> 0 THEN
                                              1
                                          ELSE
                                              0
                                      END
                FROM dbo.MFAuditHistory AS targ
                    INNER JOIN #AllObjects AS src
                        ON targ.ObjID = src.ObjID
                           AND targ.Class = src.Class
                           AND targ.ObjectType = src.ObjectType
                 WHERE src.ID <> ISNULL(targ.RecID,0)
                          OR src.MFVersion <> ISNULL(targ.MFVersion,0)
                          OR src.StatusFlag <> ISNULL(targ.StatusFlag,0)
                           OR ISNULL(targ.StatusName,0) <>  CASE
                           WHEN src.StatusFlag = 0 THEN
                               'Identical'
                           WHEN src.StatusFlag = 1 THEN
                               'MF is later'
                           WHEN src.StatusFlag = 2 THEN
                               'SQL is later'
                           WHEN src.StatusFlag = 3 THEN
                               'Checked out'
                           WHEN src.StatusFlag = 4 THEN
                               'Deleted'
                           WHEN src.StatusFlag = 5 THEN
                               'Not in Class'
                           WHEN src.StatusFlag = 6 THEN
                               'Not yet processed in SQL'
                           WHEN src.StatusFlag = 9 THEN
                               'Document Collection'
                               END;

                SET @rowcount = @@RowCount;

                COMMIT TRAN;

                SET @DebugText = N' Count %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                END;


            END;

            -------------------------------------------------------------
            -- Set UpdateRequired
            -------------------------------------------------------------
            DECLARE @MFRecordCount INT,
                    @MFNotInSQL INT,
                    @Deleted INT,
                    @NotInClass INT,
                    @Identical INT,
                    @Checkedout INT;

            --IF
            --(
            --    SELECT OBJECT_ID('tempdb..##spMFclassTableStats')
            --) IS NULL
            --BEGIN
            --    EXEC dbo.spMFClassTableStats @IncludeOutput = 0,
            --                                 @ClassTableName = @MFTableName,
            --                                 @Debug = 0;
            --END;

            SELECT @MFRecordCount = COUNT(ISNULL(id,0)) FROM dbo.MFAuditHistory AS mah WHERE class = @ClassId
            SELECT @MFNotInSQL = COUNT(ISNULL(id,0))  FROM dbo.MFAuditHistory AS mah WHERE class = @ClassId AND mah.StatusFlag = 1
            SELECT @Deleted = COUNT(ISNULL(id,0))  FROM dbo.MFAuditHistory AS mah WHERE class = @ClassId AND mah.StatusFlag = 4
            SELECT @NotInClass = COUNT(ISNULL(id,0))  FROM dbo.MFAuditHistory AS mah WHERE class = @ClassId AND mah.StatusFlag = 5
            SELECT @Identical = COUNT(ISNULL(id,0))  FROM dbo.MFAuditHistory AS mah WHERE class = @ClassId AND mah.StatusFlag = 0
             SELECT @Checkedout = COUNT(ISNULL(id,0))  FROM dbo.MFAuditHistory AS mah WHERE class = @ClassId AND mah.StatusFlag = 3
            
           
                SET @Msg = @Msg + N'Record count: ' + CAST(ISNULL(@MFRecordCount,'') AS VARCHAR(5));
           
                SET @Msg = @Msg + N' | Up to date : ' + CAST(ISNULL(@Identical,'') AS VARCHAR(5));

                SET @Msg = @Msg + N' | Deleted : ' + CAST(ISNULL(@Deleted,'') AS VARCHAR(5));

           SET @Msg = @Msg + N' | Checked out : ' + CAST(ISNULL(@Checkedout,'') AS VARCHAR(5));

                SET @Msg = @Msg + N' | Not in Class : ' + CAST(ISNULL(@NotInClass,'') AS VARCHAR(5));

            SET @LogTypeDetail = N'Debug';
            SET @LogTextDetail = @Msg;
            SET @LogStatusDetail = N'status';
            SET @LogColumnName = N'';
            SET @LogColumnValue = N'';

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
                                                   @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
                                                   @debug = 0;

            --        COMMIT TRAN [main];
            DROP TABLE #AllObjects;
        END; --nothing to update in AuditHistory
    END;
    ELSE
    BEGIN
        RAISERROR('Table does not exist', 10, 1);
    END;

    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = N'End';
    SET @LogStatus = N'Completed';
    SET @LogText = N'Completed ' + @ProcedureName;

    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Debug',
                                     @LogText = @LogText,
                                     @LogStatus = @LogStatus,
                                     @debug = @Debug;

    SET @StartTime = GETUTCDATE();
    SET @LogTypeDetail = N'Debug';
    SET @LogTextDetail = @LogText;
    SET @LogStatusDetail = @LogStatus;
    SET @LogColumnName = N'';
    SET @LogColumnValue = N'';

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
                                           @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
                                           @debug = 0;

    UPDATE dbo.MFUpdateHistory
    SET UpdateStatus = @LogStatus
    WHERE Id = @Update_ID;

    -------------------------------------------------------------
    -- Log End of Process
    ------------------------------------------------------------- 
    SELECT @SessionIDOut = @SessionID;

    IF @Debug > 0
        SELECT @SessionIDOut AS SessionID;

    RETURN 1;

    SET NOCOUNT OFF;
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

    UPDATE dbo.MFUpdateHistory
    SET UpdateStatus = @LogStatus
    WHERE Id = @Update_ID;

    RETURN -1;
END CATCH;
GO