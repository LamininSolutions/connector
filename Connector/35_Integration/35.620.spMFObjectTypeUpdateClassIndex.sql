PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFObjectTypeUpdateClassIndex]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFObjectTypeUpdateClassIndex',
                                 @Object_Release = '4.9.29.74',
                                 @UpdateFlag = 2;
GO

/*rST**************************************************************************

==============================
spMFObjectTypeUpdateClassIndex
==============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IsAllTables 
    - Default 0
    - When set to 1 it will get the object versions for all class tables
  @MFTableName
    - Class table name to perform the update for a single table
  @ProcessBatch_ID
    - Process batch id to manage to logging process
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

This procedure will update the table MFObjectTypeToClassObject with the latest version of all objects in the class.

The table is useful to get a total of objects by class and also to identify the class from the objid where multiple classes is related to an object type.

Prerequisites
=============

When parameter @IsAllTables is set to 0 then it will only perform the operation on the class tables with the column IncludeInApp not null.

Examples
========

to update all object types and tables

.. code:: sql

    EXEC [spMFObjectTypeUpdateClassIndex]  @IsAllTables = 1,  @Debug = 0  

    SELECT * FROM dbo.MFvwObjectTypeSummary AS mfots

to update only tables included in the application

.. code:: sql

    EXEC [spMFObjectTypeUpdateClassIndex]  @IsAllTables = 0,  @Debug = 0  

to update a single table

.. code:: sql

    EXEC [spMFObjectTypeUpdateClassIndex]  @IsAllTables = 0, @MFTableName = 'Customer',  @Debug = 0  

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2016-04-24  LC         Created
2017-11-23  lc         localization of MF-LastModified and MFLastModified by
2018-12-15  lc         bug with last modified date; add option to set objecttype
2018-13-21  LC         add feature to get reference of all objects in Vault
2020-08-13  LC         update assemblies to set date formats to local culture
2020-08-22  LC         update to take account of new deleted column
2021-03-17  LC         Set updatestatus = 1 when not matched
2022-04-12  LC         Add logging, remove updating MFclass, add error handling
==========  =========  ========================================================

**rST*************************************************************************/

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFObjectTypeUpdateClassIndex' --name of procedure
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
CREATE PROCEDURE dbo.spMFObjectTypeUpdateClassIndex
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFObjectTypeUpdateClassIndex
    @IsAllTables BIT = 0,
    @MFTableName NVARCHAR(200) = NULL,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
AS
SET NOCOUNT ON;

BEGIN
    DECLARE @result INT,
            @ClassName NVARCHAR(100),
            @TableName NVARCHAR(100),
            @id INT,
            @schema NVARCHAR(5) = N'dbo',
            @SQL NVARCHAR(MAX),
            @ObjectType VARCHAR(100),
            @ObjectTypeID INT,
            @ProcessStep sysname,
            @ProcedureName sysname = 'spMFObjectTypeUpdateClassIndex';
    DECLARE @ProcessType AS NVARCHAR(50);
    DECLARE @Update_ID INT;

    SET @ProcessType = ISNULL(@ProcessType, 'All Tables audit');

    --SELECT * FROM [dbo].[MFClass] AS [mc]
    --SELECT * FROM [dbo].[MFObjectType] AS [mot]
    IF @Debug > 0
    BEGIN
        RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcessStep);
    END;

    -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';
    DECLARE @Msg AS NVARCHAR(256) = N'';
    DECLARE @MsgSeverityInfo AS TINYINT = 10;
    DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
    DECLARE @MsgSeverityGeneralError AS TINYINT = 16;
    DECLARE @Return_Value INT;

    -------------------------------------------------------------
    -- VARIABLES: MFSQL Processing
    -------------------------------------------------------------

    DECLARE @MFLastModified DATETIME;
    DECLARE @Validation_ID INT;

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
    DECLARE @sqlParam NVARCHAR(MAX) = N'';

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    SET @ProcedureStep = N'Start Logging';

    SET @LogText = N'Processing ' + @ProcedureName;


    DECLARE @Username NVARCHAR(2000);
    DECLARE @VaultName NVARCHAR(2000);
    DECLARE @updateMethod INT = 10;

    SELECT TOP 1
           @Username = Username,
           @VaultName = VaultName
    FROM dbo.MFVaultSettings;



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
        SET @ProcedureStep = N'Begin processing';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



        -------------------------------------------------------------
        --	Set all tables to be included
        -------------------------------------------------------------

        IF
        (
            SELECT OBJECT_ID('tempdb..#Indexclasstablelist')
        ) IS NOT NULL
            DROP TABLE #Indexclasstablelist;

        CREATE TABLE #Indexclasstablelist
        (
            mfid INT NOT NULL,
            ClassName NVARCHAR(200) NOT NULL,
            Tablename NVARCHAR(200) NOT NULL,
            ObjectTypeID INT NOT NULL,
            IncludeInApp INT NOT NULL
        );
        INSERT INTO #Indexclasstablelist
        (
            mfid,
            ClassName,
            Tablename,
            ObjectTypeID,
            IncludeInApp
        )
        SELECT mc.MFID,
               mc.Name,
               mc.TableName,
               mot.MFID,
               ISNULL(mc.IncludeInApp, 0)
        FROM dbo.MFClass mc
            INNER JOIN dbo.MFObjectType AS mot
                ON mc.MFObjectType_ID = mot.ID;

      IF @debug > 0 
      SELECT * from #Indexclasstablelist AS i;
        -------------------------------------------------------------
        -- Get objvers
        -------------------------------------------------------------
        DECLARE @RowID INT;
        DECLARE @outPutXML NVARCHAR(MAX);
        DECLARE @Idoc INT;
        DECLARE @Class_ID INT;
        DECLARE @MFTableName_ID INT;
        DECLARE @LatestupdateDate DATETIME;
        DECLARE @Objvercount INT = NULL;
        DECLARE @MaxObjid INT;
        DECLARE @Days INT;
        DECLARE @IncludeInApp INT;

        SELECT @MFTableName_ID = ISNULL(mfid, 0)
        FROM #Indexclasstablelist
        WHERE Tablename = ISNULL(@MFTableName, '');

        DECLARE @IsAllTablesText NVARCHAR(10);
        SELECT @IsAllTablesText = CASE
                                      WHEN @IsAllTables = 1 THEN
                                          'Yes'
                                      ELSE
                                          'No'
                                  END;

        SET @DebugText = N'Params: IsAlltables %s; Table Name %s';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Setup class table loop:';


        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @IsAllTablesText, @MFTableName);
        END;



        SELECT @RowID = CASE WHEN @MFTableName IS NULL THEN (SELECT MIN(mfid)
        FROM #Indexclasstablelist) ELSE (SELECT mfid
        FROM #Indexclasstablelist WHERE tablename = @MFTableName) end;


        WHILE @RowID IS NOT NULL
        BEGIN

            SET @MaxObjid = NULL;
            SELECT @TableName = i.Tablename,
                   @ClassName = i.ClassName,
                   @IncludeInApp = i.IncludeInApp,
                   @ObjectType = i.ObjectTypeID
            FROM #Indexclasstablelist AS i
            WHERE i.mfid = @RowID;

      SET @DebugText = N' %s includeinapp %i';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Get objversions for ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName, @IncludeInApp  );
        END;

            IF (
                   @IsAllTables = 1
                   AND @IncludeInApp = 0
               )
               OR
               (
                   @IsAllTables = 0
                   AND @IncludeInApp <> 0
               )
            BEGIN

                SET @ProcedureStep = N'Get object versions start';


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


                SET @LogType = N'Status';
                SET @LogText = N'Start update for ' + @TableName;
                SET @LogStatus = N'In Progress';


                EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                       @LogType = @LogType,
                                                       @LogText = @ProcessType,
                                                       @LogStatus = @LogStatus,
                                                       @StartTime = @StartTime,
                                                       @MFTableName = @TableName,
                                                       @Validation_ID = @Validation_ID,
                                                       @ColumnName = NULL,
                                                       @ColumnValue = NULL,
                                                       @Update_ID = @Update_ID,
                                                       @LogProcedureName = @ProcedureName,
                                                       @LogProcedureStep = @ProcedureStep,
                                                       @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
                                                       @debug = 0;


                EXEC dbo.spMFGetObjectvers @TableName = @TableName,        
                                           @dtModifiedDate = '2000-01-01', 
                                           @MFIDs = NULL,                  
                                           @outPutXML = @outPutXML OUTPUT,
                                           @ProcessBatch_ID = @ProcessBatch_ID,
                                           @debug = @debug; 


                IF @Debug > 0
                    SELECT @TableName AS tablename,
                           @outPutXML AS outPutXML;

                IF @outPutXML != '<form />'
                BEGIN



                    SET @StartTime = GETUTCDATE();

                    DECLARE @ObjectDetails XML;
        

        SET @ObjectDetails =
        (
            SELECT @ObjectType AS [ObjectType/@ObjectTypeid],
                   @RowId AS [ObjectType/@ClassID]
            FOR XML PATH(''), ROOT('form')
        );

                    UPDATE dbo.MFUpdateHistory
                    SET ObjectDetails = @ObjectDetails,
                     NewOrUpdatedObjectVer = CAST(@outPutXML AS XML)
                    WHERE Id = @Update_ID;

                    EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @outPutXML;

                    SET @DebugText = N' update audit history for table ' + @TableName;
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = N' Get ObjectVer';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    BEGIN TRAN;
                    MERGE INTO dbo.MFAuditHistory t
                    USING
                    (
                        SELECT DISTINCT
                               xmlfile.objId,
                               xmlfile.MFVersion,
                               xmlfile.GUID,
                               xmlfile.ObjectType_ID,
                               xmlfile.Object_Deleted,
                               xmlfile.CheckedOutTo,
                               xmlfile.Object_LastModifiedUtc,
                               xmlfile.LatestCheckedInVersion
                        FROM
                            OPENXML(@Idoc, '/form/objVers', 1)
                            WITH
                            (
                                objId INT './@objectID',
                                MFVersion INT './@version',
                                GUID NVARCHAR(100) './@objectGUID',
                                ObjectType_ID INT './@objectType',
                                Object_Deleted NVARCHAR(10) './@Deleted',
                                CheckedOutTo INT './@CheckedOutTo',
                                Object_LastModifiedUtc NVARCHAR(30) './@LastModifiedUtc',
                                LatestCheckedInVersion INT './@LatestCheckedInVersion'
                            ) xmlfile
                    ) s
                    ON t.ObjectType = s.ObjectType_ID
                       AND t.ObjID = s.objId
                       AND t.Class = @RowID
                    WHEN NOT MATCHED  BY TARGET THEN
                  --  WHEN NOT MATCHED THEN
                        INSERT
                        (
                            TranDate,
                            ObjectType,
                            Class,
                            ObjID,
                            MFVersion,
                            StatusFlag,
                            StatusName,
                            UpdateFlag
                        )
                        VALUES
                        (   GETUTCDATE(), s.ObjectType_ID, @Class_ID, s.objId, s.LatestCheckedInVersion,
                            CASE
                                WHEN s.Object_Deleted = 'true' THEN
                                    4
                                WHEN s.CheckedOutTo > 0 THEN
                                    3
                                ELSE
                                    1
                            END, CASE
                                     WHEN s.Object_Deleted = 'true' THEN
                                         'Deleted in MF'
                                     WHEN s.CheckedOutTo > 0 THEN
                                         'Checked Out'
                                     ELSE
                                         'Not matched'
                                 END, CASE
                                          WHEN s.Object_Deleted = 'true' THEN
                                              0
                                          ELSE
                                              1
                                      END);
                COMMIT TRAN;

                    IF @Idoc IS NOT NULL
                        EXEC sys.sp_xml_removedocument @Idoc;

    

                END; -- return is not null



                SET @LogStatus = 'Completed';
                UPDATE dbo.MFUpdateHistory
                SET UpdateStatus = @LogStatus
                WHERE Id = @Update_ID;

            END; -- conditional update



            SET @RowID = CASE
                             WHEN @MFTableName IS null THEN
                             (
                                 SELECT MIN(mc.mfid)
                                 FROM #Indexclasstablelist AS mc
                                 WHERE mc.mfid > @RowID
                             )
                             ELSE
                                 NULL
                         END;


        END;

        SET @ProcessStep = 'END';
        SET @LogStatus = N'Completed';

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcessStep);
        END;

        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                         @ProcessType = @ProcessType,
                                         @LogType = N'Message',
                                         @LogText = @LogText,
                                         @LogStatus = @LogStatus,
                                         @debug = @Debug;

        SET @StartTime = GETUTCDATE();

        SET @LogTypeDetail = N'Status';
        SET @LogStatusDetail = @LogStatus;
        SET @LogTextDetail = @LogText;
        SET @LogColumnName = N'';
        SET @LogColumnValue = N'';

        EXECUTE @Return_Value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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