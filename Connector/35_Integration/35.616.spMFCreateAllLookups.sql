PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateAllLookups]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFCreateAllLookups' -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.48'
                                    ,@UpdateFlag = 2;
GO

/*------------------------------------------------------------------------------------------------
	Author: RemoteSQL
	Create date: 10/12/2017 16:29
	Database: 
	Description: Prodecedure to create all workflow and Valuelist lookups that is used in the included in App class tables

															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2019-1-30		LC			Valuelist name: Source Does not exist or is a duplicate
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFCreateAllLookups' --name of procedure
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

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFCreateAllLookups]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFCreateAllLookups]
(
    @ProcessBatch_ID INT = NULL OUTPUT
   ,@Schema NVARCHAR(20) = 'dbo'
   ,@IncludeInApp INT = 1
   ,@WithMetadataSync BIT = 0
   ,@Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

====================
spMFCreateAllLookups
====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Schema nvarchar(20)
    fixme description
  @IncludeInApp int
    fixme description
  @WithMetadataSync bit
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @MFTableName AS NVARCHAR(128) = 'MFValuelist';
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Create Lookups');

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
    DECLARE @ProcedureName AS NVARCHAR(128) = '[dbo].[spMFCreateAllLookups]';
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
                                              ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT --v38
                                              ,@debug = 0;

    BEGIN TRY
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------

        -------------------------------------------------------------
        -- CUSTOM VARIABLES
        -------------------------------------------------------------
        DECLARE @Lookuplist AS TABLE
        (
            [Rowid] INT IDENTITY
           ,[id] INT
           ,[Name] NVARCHAR(100)
        );

        DECLARE @RowID INT;
        DECLARE @LookupName NVARCHAR(100);
        DECLARE @ViewName NVARCHAR(100);

        -------------------------------------------------------------
        -- UPDATE WORKFLOWS AND VALUELISTS
        -------------------------------------------------------------
        SET @ProcedureStep = 'Update from M-Files';

        IF @WithMetadataSync = 1
        BEGIN
            EXEC [dbo].[spMFDropAndUpdateMetadata] @IsResetAll = 0
                                                  ,@IsStructureOnly = 0
                                                  ,@ProcessBatch_ID = @ProcessBatch_ID
                                                  ,@Debug = 0;
        END;

        -------------------------------------------------------------
        -- GET WORKFLOWS
        -------------------------------------------------------------
        SET @ProcedureStep = 'Get Workflows to include';
        SET @MFTableName = 'MFWorkflow';

        MERGE INTO @Lookuplist AS [t]
        USING
        (
            SELECT DISTINCT
                   [mc].[MFWorkflow_ID]
                  ,[mw].[Name]
            FROM [INFORMATION_SCHEMA].[COLUMNS]    AS [c]
                INNER JOIN [dbo].[MFProperty]      AS [mp]
                    ON [mp].[ColumnName] = [c].[COLUMN_NAME]
                INNER JOIN [dbo].[MFClassProperty] AS [mcp]
                    ON [mcp].[MFProperty_ID] = [mp].[ID]
                INNER JOIN [dbo].[MFClass]         AS [mc]
                    ON [mc].[ID] = [mcp].[MFClass_ID]
                INNER JOIN [dbo].[MFWorkflow]      AS [mw]
                    ON [mw].[ID] = [mc].[MFWorkflow_ID]
            WHERE [c].[TABLE_NAME] IN (
                                          SELECT [TableName] FROM [dbo].[MFClass] WHERE [IncludeInApp] IS NOT NULL
                                      )
                  AND [mp].[MFDataType_ID] IN ( 8, 9 )
                  AND [mp].[MFID] > 1000
        ) AS [s]
        ON [t].[id] = [s].[MFWorkflow_ID]
        WHEN NOT MATCHED THEN
            INSERT
            (
                [id]
               ,[Name]
            )
            VALUES
            ([s].[MFWorkflow_ID], [s].[Name]);

        IF @Debug > 0
            SELECT *
            FROM @Lookuplist AS [l];

        -------------------------------------------------------------
        -- CREATE WORKFLOW LOOKUPS
        -------------------------------------------------------------
        SET @ProcedureStep = 'Create workflow lookups';

        SELECT @RowID = MIN([l].[Rowid])
        FROM @Lookuplist AS [l];

        WHILE @RowID IS NOT NULL
        BEGIN
            SELECT @LookupName = [l].[Name]
                  ,@ViewName   = 'WFvw' + [dbo].[fnMFReplaceSpecialCharacter]([l].[Name])
            FROM @Lookuplist AS [l]
            WHERE [l].[Rowid] = @RowID;

			
            IF NOT EXISTS
            (
                SELECT 1
                FROM [INFORMATION_SCHEMA].[TABLES] AS [t]
                WHERE [t].[TABLE_TYPE] = 'VIEW'
                      AND [t].[TABLE_NAME] = @ViewName
            )
            BEGIN

            EXEC [dbo].[spMFCreateWorkflowStateLookupView] @WorkflowName = @LookupName
                                                          ,@ViewName = @ViewName
                                                          ,@Schema = @Schema
                                                          ,@Debug = 0;

            SET @LogTypeDetail = 'Status';
            SET @LogStatusDetail = 'In Progress';
            SET @LogTextDetail = 'Created Workflow View ' + @Schema + '.' + @ViewName;
            SET @LogColumnName = @LookupName;
            SET @LogColumnValue = '';

            EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
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
END;

            SELECT @RowID = MIN([l].[Rowid])
            FROM @Lookuplist AS [l]
            WHERE [l].[Rowid] > @RowID;
        END;

        -------------------------------------------------------------
        -- GET VALUELISTS
        -------------------------------------------------------------
        SET @ProcedureStep = 'Get Valuelists to include';
        SET @MFTableName = 'MFValuelist';

        DELETE FROM @Lookuplist;

        MERGE INTO @Lookuplist AS [t]
        USING
        (
            SELECT DISTINCT
                   [mvl].[ID]
                  ,[mvl].[Name]
            FROM [INFORMATION_SCHEMA].[COLUMNS]    AS [c]
                INNER JOIN [dbo].[MFProperty]      AS [mp]
                    ON [mp].[ColumnName] = [c].[COLUMN_NAME]
                INNER JOIN [dbo].[MFClassProperty] AS [mcp]
                    ON [mcp].[MFProperty_ID] = [mp].[ID]
                INNER JOIN [dbo].[MFValueList]     AS [mvl]
                    ON [mvl].[ID] = [mp].[MFValueList_ID]
            WHERE [c].[TABLE_NAME] IN (
                                          SELECT [TableName] FROM [dbo].[MFClass] WHERE [IncludeInApp] IS NOT NULL
                                      )
                  AND [mp].[MFDataType_ID] IN ( 8, 9 )
                  AND [mp].[MFID] > 1000
        ) AS [s]
        ON [t].[id] = [s].[ID]
        WHEN NOT MATCHED THEN
            INSERT
            (
                [id]
               ,[Name]
            )
            VALUES
            ([s].[ID], [s].[Name]);

        IF @Debug > 0
            SELECT *
            FROM @Lookuplist AS [l];

        -------------------------------------------------------------
        -- CREATE VALUELIST LOOKUPS
        -------------------------------------------------------------
        SET @ProcedureStep = 'Create valuelist lookups';

        SELECT @RowID = MIN([l].[Rowid])
        FROM @Lookuplist AS [l];

        WHILE @RowID IS NOT NULL
        BEGIN
            SELECT @LookupName = [l].[Name]
                  ,@ViewName   = 'VLvw' + [dbo].[fnMFReplaceSpecialCharacter]([l].[Name])
            FROM @Lookuplist AS [l]
            WHERE [l].[Rowid] = @RowID;

            IF NOT EXISTS
            (
                SELECT 1
                FROM [INFORMATION_SCHEMA].[TABLES] AS [t]
                WHERE [t].[TABLE_TYPE] = 'VIEW'
                      AND [t].[TABLE_NAME] = @ViewName
            )
            BEGIN
                EXEC [dbo].[spMFCreateValueListLookupView] @ValueListName = @LookupName
                                                          ,@ViewName = @ViewName
                                                          ,@Schema = @Schema
                                                          ,@Debug = 0;

                SET @LogTypeDetail = 'Status';
                SET @LogStatusDetail = 'In Progress';
                SET @LogTextDetail = 'Created Valuelist View ' + @Schema + '.' + @ViewName;
                SET @LogColumnName = @LookupName;
                SET @LogColumnValue = '';

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
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
            END;

            SELECT @RowID = MIN([l].[Rowid])
            FROM @Lookuplist AS [l]
            WHERE [l].[Rowid] > @RowID;
        END;

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = 'End';

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        SET @LogStatus = 'Completed';

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
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
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY()
        ,ERROR_LINE(), @ProcedureStep);

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
END;
GO