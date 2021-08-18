PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDeleteObject]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFDeleteObject' -- nvarchar(100)
                                    ,@Object_Release = '4.9.27.69'     -- varchar(50)
                                    ,@UpdateFlag = 2;                  -- smallint
GO
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
  - 1 = Success object deleted
  - 2 =	Success object version destroyed
  - 3 =	Success object destroyed  
  - 3 = Successfully destroyed deleted object (when the object is already deleted)
  - 4 = Failed to destroy, object not found
  - 5 =	Failed to delete, object not found
  - 6 = Failed to remove version, version not found

  - -1 = SQL Error

Parameters
  @ObjectTypeId int
    OBJECT Type MFID from MFObjectType
  @objectId int
    Objid of record
  @Output nvarchar(2000) (output)
    Output message
  @objectVersion int
    the object version to be removed. 
    default = 0 which indicates the delete the object rather than a version
  @DeleteWithDestroy bit (optional)
    - Default = 0
    - 1 = Destroy

Purpose
=======

An object can be deleted from M-Files using the ClassTable by using the spMFDeleteObject procedure. Is it optional to delete or destroy the object in M-Files.

The procedure can also be used to destroy a specific version of an object.  This is particularly useful when old or outdataed versions must be removed from the system.

Additional Information
======================

Use this procedure to delete or destroy a single object or object version.  spMFDeleteObjectList can be used to delete a series of objects.

When DeleteWithDestroy = 1 the objectversion specified in ObjectVersion will be ignored and the ObjectVersion will automatically be set to -1.  This will trigger the method to destroy the whole object.  There is no need to manually set the ObjectVersion to -1.  A status code 3 will be returned.
When DeleteWithDestroy = 1 and the objectversion is set to 0 then the object will be destroyed.
When DeleteWithDestroy = 1 and the object does not exist an error code of 4 will be returned 

When DeleteWithDestroy = 0 and the ObjectVersion is set to 0 the whole object will be deleted. Status code 1 is returned.
When DeleteWithDestroy = 0 and an ObjectVersion less that the latest object version is specified the ObjectVersion will be removed.  A status code 2 is returned

When DeleteWithDestroy = 0 and an ObjectVersion that is equal to latest object version is specified the delete will fail with error 6 returned
When DeletedWithDestroy = 0 and the object does not exist an error code 4 will be returned
When DeletedWithDestroy = 0 and the object version does not exist, is not 0 and is not the latest version of the object then an error code 5 will be returned


Warnings
========

To delete an object the object version must be set to 0 and DeleteWithDestroy must be set to 0.

Note that when a object is deleted it will not show in M-Files but it will still show in the class table. However, in the class table the deleted column will have a date.

To delete a object version, the specified version must exist.  Use spMFGetHistory to first pull all the versions of an object or objects, and then use the MFObjectChangeHistory table to determine the object versions to be removed.

Deleting and object version performs a destroy of the version. There is no possibility to undelete a deleted version.

The latest version of the object cannot be specified as the object version to be destroyed.  When the latest version of the object is specified the object will be deleted.

Examples
========

Deleting and object
~~~~~~~~~~~~~~~~~~~

.. code:: sql

    DECLARE @return_value int, @Output nvarchar(2000)

    EXEC @return_value = [dbo].[spMFDeleteObject]
         @ObjectTypeId =128,-- OBJECT MFID
         @objectId =4700,-- Objid of record
         @Output = @Output OUTPUT,
         @DeleteWithDestroy = 0
    SELECT @Output as N'@Output'
    SELECT'Return Value'= @return_value


Delete object versions
~~~~~~~~~~~~~~~~~~~~~~

To delete an object version the objid and the version to delete is required.
Use spMFGetHistory to get the valid versions of an object
Then use spMFDeleteObject to destroy the specific version

.. code:: sql

    UPDATE Mcoa
    SET [mcoa].[Process_ID] = 5
    FROM [dbo].[MFCustomer] AS [mcoa]
    WHERE [mcoa].[ObjID] = 134
    DECLARE @Update_ID INT
    ,@ProcessBatch_id INT;
    EXEC [dbo].[spMFGetHistory] @MFTableName = 'MFCustomer'   
                           ,@Process_id = 5    
                           ,@ColumnNames = 'MF_Last_modified'  
                           ,@IsFullHistory = 1 
                           ,@NumberOFDays = null  
                           ,@StartDate = null     
                           ,@Update_ID = @Update_ID OUTPUT  
                           ,@ProcessBatch_id = @ProcessBatch_id OUTPUT 
                           ,@Debug = 0 
    SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch] WHERE [moch].[ObjID] = 134

Use a loop to destroy multiple versions of multiple objects

.. code:: sql

    DECLARE @Output NVARCHAR(2000);
    DECLARE @processBatch_ID INT;
    DECLARE @Return_Value int

    EXEC  @Return_Value = [dbo].[spMFDeleteObject] @ObjectTypeId = 136  
                             ,@objectId = 134 
                             ,@Output = @Output OUTPUT                                
                             ,@ObjectVersion = 9     -- set to specific version to destroy
                             ,@DeleteWithDestroy = 1 -- object version history is always destroy
							 ,@ProcessBatch_id = @processBatch_ID OUTPUT
                             
    SELECT @Return_Value

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-08-15  LC         Remove incorrect license check
2021-05-05  LC         Align single delete object without class table with wrapper
2020-12-08  LC         Change status messages and validate different methods
2020-04-28  LC         Update documentation for Object Versions
2019-08-30  JC         Added documentation
2019-08-20  LC         Expand routine to respond to output and remove object from change history
2019-08-13  DEV2       Added objversion to delete particular version.
2018-08-03  LC         Suppress SQL error when no object in MF found
2016-09-26  DEV2       Removed vault settings parameters
2016-08-22  LC         Update settings index
2016-08-14  LC         Add objid to output message
==========  =========  ========================================================

**rST*************************************************************************/

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
        EXEC [dbo].[spMFCheckLicenseStatus] 'spMFDeleteObjectListInternal'
                                           ,'spMFDeleteObject'
                                           ,'Deleting object';

        -----------------------------------------------------
        -- CALLS PROCEDURE spMFDeleteObjectInternal
        -----------------------------------------------------
        -- nvarchar(2000)
        SET @ProcedureStep = 'Wrapper result';

        SELECT @objectVersion = CASE WHEN @DeleteWithDestroy = 1 AND @ObjectVersion <> -1 THEN -1 ELSE @objectVersion END    
         DECLARE @XML XML;
         DECLARE @XMLinput NVARCHAR(MAX);
         DECLARE @XMLout NVARCHAR(MAX)

         SET @XML =
    (
        SELECT @ObjectTypeId AS [ObjectDeleteItem/@ObjectType_ID],
            @objectId            [ObjectDeleteItem/@ObjId],
            @objectVersion        [ObjectDeleteItem/@MFVersion],
            @DeleteWithDestroy         AS [ObjectDeleteItem/@Destroy]      
        FOR XML PATH(''), ROOT('ObjectDeleteList'))


        SET @XMLinput = CAST(@XML AS NVARCHAR(MAX))
       
        EXEC dbo.spMFDeleteObjectListInternal @VaultSettings = @VaultSettings,
            @XML = @XMLinput,
            @XMLOut = @XMLOut OUTPUT

            IF @debug > 0
            SELECT @XMLout;

        --      PRINT @Output + ' ' + CAST(@objectId AS VARCHAR(100))
        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @XMLOut;

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

        IF @idoc IS NOT null
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

        SELECT @output = @Message
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