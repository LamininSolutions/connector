PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDeleteObject]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFDeleteObject' -- nvarchar(100)
                                    ,@Object_Release = '4.4.12.52'     -- varchar(50)
                                    ,@UpdateFlag = 2;                  -- smallint
GO

/********************************************************************************
  ** Change History
  ********************************************************************************
   Date        Author     Description
   ----------  ---------  -----------------------------------------------------
  2016-8-14		lc		add objid to output message
  2016-8-22		lc			update settings index
  2016-09-26    DevTeam2   Removed vault settings parameters and pass them as comma
                           separated string in @VaultSettings parameter.
 2018-8-3		LC			Suppress SQL error when no object in MF found
 2019-8-13		DevTeam2	Added objversion to delete particular version.
 2019-8-20		LC			Expand routine to respond to output and remove object from change history
  ******************************************************************************/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFDeleteObject' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFDeleteObject]
AS
SELECT 'created, but not implemented yet.'; --just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFDeleteObject]
    @ObjectTypeId INT
   ,@objectId INT
   ,@Output NVARCHAR(2000) OUTPUT
   ,@ObjectVersion INT = 0
   ,@DeleteWithDestroy BIT = 0
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@Debug SMALLINT = 0
AS
/*rST**************************************************************************

================
spMFDeleteObject
================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ObjectTypeId int
    fixme description
  @objectId int
    fixme description
  @Output nvarchar(2000) (output)
    fixme description
  @DeleteWithDestroy bit
    fixme description


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

/*******************************************************************************
  ** Desc:  The purpose of this procedure is to Delete object from M-Files.  
  **  
  ** Version: 1.0.0.6
  
  ** Author:          Thejus T V
  ** Date:            27-03-2015

    */


  /*
1	Success object deleted
2	Success object version destroyed
3	Success object  destroyed
4	 Failure object does not exist
5	Failure object version does not exist
6	Failure destroy latest object version not allowed
*/


BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @MFTableName AS NVARCHAR(128);
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Delete Object');

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
    DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFDeleteObject';
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

    DECLARE @ObjectType NVARCHAR(100);

    SELECT @ObjectType = [mot].[Name]
    FROM [dbo].[MFObjectType] AS [mot]
    WHERE [mot].[MFID] = @ObjectTypeId;

    SET @LogText
        = CASE
              WHEN @DeleteWithDestroy = 1 THEN
                  'Destroy objid ' + CAST(@objectId AS VARCHAR(10)) + ' for Object Type ' + @ObjectType + ' Version '
                  + CAST(@ObjectVersion AS NVARCHAR(10))
              ELSE
                  'Delete objid ' + CAST(@objectId AS VARCHAR(10)) + ' for Object Type ' + @ObjectType + ' Version '
                  + CAST(@ObjectVersion AS NVARCHAR(10))
          END;

    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Status'
                                        ,@LogText = @LogText
                                        ,@LogStatus = N'In Progress'
                                        ,@debug = @Debug;

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Debug'
                                              ,@LogText = @LogText
                                              ,@LogStatus = N'Started'
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = NULL
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
        SET @DebugText = 'Object Type %i; Objid %i; Version %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectTypeId, @objectId, @ObjectVersion);
        END;

        -----------------------------------------------------
        -- LOCAL VARIABLE DECLARARTION
        -----------------------------------------------------
        DECLARE @VaultSettings NVARCHAR(4000);
        DECLARE @Idoc INT;
        DECLARE @StatusCode INT;
        DECLARE @Message NVARCHAR(100);

        -----------------------------------------------------
        -- SELECT CREDENTIAL DETAILS
        -----------------------------------------------------
        SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

        ------------------------------------------------------
        --Validating Module for calling CLR Procedure
        ------------------------------------------------------
        EXEC [dbo].[spMFCheckLicenseStatus] 'spMFDeleteObjectInternal'
                                           ,'spMFDeleteObject'
                                           ,'Deleting object';

        -----------------------------------------------------
        -- CALLS PROCEDURE spMFDeleteObjectInternal
        -----------------------------------------------------
        -- nvarchar(2000)
        SET @ProcedureStep = 'Wrapper result';

        EXEC [dbo].[spMFDeleteObjectInternal] @VaultSettings
                                             ,@ObjectTypeId
                                             ,@objectId
                                             ,@DeleteWithDestroy
                                             ,@ObjectVersion
                                             ,@Output OUTPUT;

        --      PRINT @Output + ' ' + CAST(@objectId AS VARCHAR(100))
        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @Output;

        SELECT @StatusCode = [xmlfile].[StatusCode]
              ,@Message    = [xmlfile].[Message]
        FROM
            OPENXML(@Idoc, '/form/objVers', 1)
            WITH
            (
                [objId] INT './@objId'
               ,[MFVersion] INT './@ObjVers'
               ,[StatusCode] INT './@statusCode'
               ,[Message] NVARCHAR(100) './@Message'
            ) [xmlfile];

        EXEC [sys].[sp_xml_removedocument] @Idoc;

        SET @DebugText = 'Statuscode %i; Message %s';
        SET @DebugText = @DefaultDebugText + @DebugText;


        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @StatusCode, @Message);
        END;

IF @StatusCode = 2
BEGIN 


      DELETE 
        FROM [dbo].[MFObjectChangeHistory] 
        WHERE [ObjectType_ID] = @ObjectTypeId
              AND [ObjID] = @objectId
              AND [MFVersion] = @ObjectVersion;
END

IF @StatusCode IN (1,3)
BEGIN

 DELETE 
        FROM [dbo].[MFObjectChangeHistory] 
        WHERE [ObjectType_ID] = @ObjectTypeId
              AND [ObjID] = @objectId;
END

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = 'End';
        SET @LogStatus = CASE WHEN @StatusCode IN (1,2,3) THEN 'Completed' ELSE 'Failed' end
		
		SET @logtext = @Message

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
                                                  ,@LogText = @LogText
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

        RETURN @StatusCode;
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