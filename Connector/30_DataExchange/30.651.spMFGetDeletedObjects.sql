
/*

*/
--Created on: 2019-07-03 

--SELECT * FROM [dbo].[MFClass] AS [mc]
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetDeletedObjects]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFGetDeletedObjects' -- nvarchar(100)
                                    ,@Object_Release = '4.4.12.53'
                                    ,@UpdateFlag = 2;
GO



IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFGetDeletedObjects' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFGetDeletedObjects]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFGetDeletedObjects]
(
    @MFTableName NVARCHAR(200)
   ,@LastModifiedDate DATETIME = '2000-01-01'
   ,@RemoveDeleted BIT = 0
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=====================
spMFGetDeletedObjects
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(200)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @LastModifiedDate datetime (optional)
    - Default = 2000-01-01
    - Allows limited search for deleted object
  @RemoveDeleted bit (optional)
    - Default = 1. Deleted records in M-Files are removed from the class table.
    - If set to 0 then deleted items will be marked in the class table column 'Deleted' instead of removing the record.
  @ProcessBatch\_ID int (optional, output)
    - Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Identify and optionally remove deleted objects in M-Files in class table.

Examples
========

.. code:: sql

    DECLARE @ProcessBatch_ID INT;

    EXEC [dbo].[spMFGetDeletedObjects] @MFTableName = 'MFCustomer'            -- nvarchar(200)
                                  ,@LastModifiedDate = '2018-01-01'           -- datetime
                                  ,@RemoveDeleted = 1                         -- bit
                                  ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                  ,@Debug = 101                               -- smallint


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-03  LC         Fix bug related to vaultsettings parameter
2019-09-03  LC         Set LastModifiedDate default to 2000-01-01
2019-08-30  JC         Added documentation
2019-07-04  LC         Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Remove Deleted Objects');

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
    DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFGetDeletedObjects';
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

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    DECLARE @Id           INT
           ,@ObjectTypeId INT
           ,@ObjId        INT
           ,@ClassId      INT;
    DECLARE @Idoc INT;
    DECLARE @outputXML NVARCHAR(MAX);
    DECLARE @Vaultsettings NVARCHAR(400);

    SET @Vaultsettings = [dbo].[FnMFVaultSettings]();
    SET @StartTime = GETUTCDATE();

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    SET @ProcedureStep = 'Start Removal';
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
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Get Deleted Objects';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --Set Object Type Id and class id
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Object Type and Class';

        SELECT @ObjectTypeId = [mc].[MFObjectType_ID]
              ,@ObjId        = [ob].[MFID]
              ,@ClassId      = [mc].[MFID]
        FROM [dbo].[MFClass]                AS [mc]
            INNER JOIN [dbo].[MFObjectType] AS [ob]
                ON [ob].[ID] = [mc].[MFObjectType_ID]
        WHERE [mc].[TableName] = @MFTableName;


        EXEC [dbo].[spMFGetDeletedObjectsInternal] @VaultSettings = @Vaultsettings       -- nvarchar(4000)
                                                  ,@ClassID = @ClassId                   -- int
                                                  ,@LastModifiedDate = @LastModifiedDate -- datetime
                                                  ,@outputXML = @outputXML OUTPUT;

 --SELECT CAST(@outputXML AS XML);
        IF @Debug > 1
        BEGIN
            RAISERROR('Proc: %s Step: %s returned %i  ', 10, 1, @ProcedureName, @ProcedureStep, @return_value);
        END;

        SET @ProcedureStep = 'Create Temp table';

        IF
        (
            SELECT OBJECT_ID('tempdb..#AllObjects')
        ) IS NOT NULL
            DROP TABLE [#AllObjects];

        CREATE TABLE [#AllObjects]
        (
            [ObjID] INT
           ,[ObjectType] INT
           ,[Class] INT
           ,[LastModified] NVARCHAR(30)
           ,[LastModifiedBy] INT
           ,[DeletedTime] NVARCHAR(30)
           ,[DeletedBy] INT
        );

        CREATE INDEX [idx_AllObjects_ObjID] ON [#AllObjects] ([ObjID]);

        SET @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';

        --     DECLARE @NewXML XML;
        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @outputXML;

        SET @ProcedureStep = ' Insert items in Temp Table';

        INSERT INTO [#AllObjects]
        SELECT [xmlfile].[objId]
              ,[xmlfile].[objType]
              ,[xmlfile].[ClassID]
              ,[xmlfile].[LastModified]
              ,[xmlfile].[LastModifiedBy]
              ,[xmlfile].[deletedTime]
              ,[xmlfile].[deletedBy]
        FROM
            OPENXML(@Idoc, '/form/objVers', 1)
            WITH
            (
                [objId] INT './@objId'
               ,[objType] INT './@objType'
               ,[ClassID] INT './@ClassID'
               ,[LastModified] NVARCHAR(30) './@lastModified'
               ,[LastModifiedBy] INT './@lastModifiedBy'
               ,[deletedTime] NVARCHAR(30) './@deletedTime'
               ,[deletedBy] INT './@deletedBy'
            ) [xmlfile];

        ----SELECT *
        ----INTO [#AllObjects]
        ----FROM [cte];

        --SELECT [cte].[objId]
        --      ,[cte].[objType]
        --      ,[cte].[ClassID]
        --      ,[cte].[LastModified]
        --      ,[cte].[LastModifiedBy]
        --      ,[cte].[deletedTime]
        --      ,[cte].[deletedBy]
        --FROM [cte];
        EXEC [sys].[sp_xml_removedocument] @Idoc;

        IF @Debug > 0
            SELECT *
            FROM [#AllObjects] AS [ao];

        -------------------------------------------------------------
        -- Remove deleted
        -------------------------------------------------------------
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Update deleted records';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

		SELECT @RowCount = COUNT(*) FROM [#AllObjects] AS [ao]

        IF
        @rowcount > 0
        BEGIN
            SET @sql = N'UPDATE [t]
		SET Deleted = 1
		FROM ' + QUOTENAME(@MFTableName) + ' t
		INNER JOIN #AllObjects ao
		ON t.[objid]	= ao.[ObjID] ';

            EXEC [sys].[sp_executesql] @sql;

			DECLARE @RemovedRecords INT 
			SET @RemovedRecords = @@RowCount

            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Remove deleted records';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            IF @RemoveDeleted = 1
            BEGIN
                SET @sql = N'Delete from ' + QUOTENAME(@MFTableName) + ' where deleted = 1 ';

                EXEC [sys].[sp_executesql] @sql;

				
				                           SET @ProcedureStep = 'Delete from Table ';
				                           SET @LogTypeDetail = 'Status';
				                           SET @LogStatusDetail = '';
				                           SET @LogTextDetail = ' Removed '+ CAST(@RemoveDeleted AS VARCHAR(10)) + ' records from '+ @MFTableName
				                           SET @LogColumnName = 'Deleted Objects';
				                           SET @LogColumnValue =  CAST(@rowcount AS NVARCHAR(10));
				
				                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
				                            @ProcessBatch_ID = @ProcessBatch_ID
				                          , @LogType = @LogTypeDetail
				                          , @LogText = @LogTextDetail
				                          , @LogStatus = @LogStatusDetail
				                          , @StartTime = @StartTime
				                          , @MFTableName = @MFTableName
				                          , @Validation_ID = @Validation_ID
				                          , @ColumnName = @LogColumnName
				                          , @ColumnValue = @LogColumnValue
				                          , @Update_ID = @Update_ID
				                          , @LogProcedureName = @ProcedureName
				                          , @LogProcedureStep = @ProcedureStep
				                          , @debug = @debug

            END;
        END;

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
                                            ,@LogType = N'Debug'
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
