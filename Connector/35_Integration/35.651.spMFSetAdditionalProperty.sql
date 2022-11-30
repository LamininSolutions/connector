PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSetAdditionalProperty]';
GO
SET NOCOUNT ON;
EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFSetAdditionalProperty', -- nvarchar(100)
                                 @Object_Release = '4.10.30.74',
                                 @UpdateFlag = 2;

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSetAdditionalProperty' --name of procedure
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
CREATE PROCEDURE dbo.spMFSetAdditionalProperty
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE dbo.spMFSetAdditionalProperty
(
    @MFTableName NVARCHAR(4000),
    @MFProperty NVARCHAR(4000),
    @RetainIfNull BIT,
    @RetainDeletions INT = 0,
    @IsDocumentCollection INT = 0,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=========================
SpmfSetAdditionalProperty
=========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string, comma delimited string is allowed
    - Pass the class table name, e.g.: 'MFCustomer'
  @MFProperty
    - Valid Property Name as a string, comma delimited string is allowed    
  @RetainIfNull (bit)
    - set to 1 to retain the property on the metadata card, even if null
    - default = 0
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To change the behaviour of updating an additional property when the property value is null.

Additional Info
===============

By default, a property that is not defined on the metadata card will be not be added, or removed if the value of the property is null
When the property is set to retain if null, then the property will be updated and set on the metadata card, even if null

Properties defined on the metadata card will always be retained on the metadata card, even if they are null

If the parameter is set to retain null = 0 and all the values in the class for the property is null then the procedure spMFDeleteAdhocProperty will automatically be triggered to remove the column from the class table and from the metadata cards.

To remove a property that is defined as an additional property, or changed from being on the metadata card, to not being on the metadata card, the following steps should be followed
 - After a change to the metadata definition, the procedure spMFDropAndUpdateMetadata must be run before an update is process from SQL to MF.
 - Ensure that the value of the property is null in the class table. Follow the instructions below in a case where the value is not null, and the property should be set to null and then removed.
 - Set the property definition for the class to not retain the property if null using this procudure. Note that the setting is by default set to 0.
 - Process an update to the object by setting the process_id = 1. Other updates to the class table is optional. When spmfUpdateTable is used to perform the update, the additional property should be removed from the metadata card.

To remove a property that is defined as an additional property with a current value that need to be removed from the metadata card of of the object. or changed from being on the metadata card, to not being on the metadata card, the steps to follow is slightly different from the above.
 - Before running spMFDropAndUpdateMetadata, first execute his procedure to set the property to retain the value if set to null. This step is required to allow for the removal of the value of the property.
 - If the property was removed from the metadata card, the procedure spMFDropAndUpdateMetadata must be run before further processing.
 - Set the value (s) of the property to be removed from the objects to null in SQL and process an update from SQL to MF.  This should set the value on the object to null.
 - Reset the property definition to not retain the property if null using this procudure. 
 - Process another update to the object by setting the process_id = 1. When spmfUpdateTable is used to perform the update, the additional property should be removed from the metadata card.

This procedure can be used to set or reset multiple properties by using a comma delimited string.  Note that all the properies in the list will be set to the same @RetainIfNull parameter.
The procedure can be also be used the set multiple classes by using a comma delimited string in @MFTableName. Note that the same rules will apply for the properties defined in the parameter for all classes.

Prerequisites
=============

Version 4.10.30.74 or higher.

This procedure does not reset the definition of the property in M-Files. Use M-Files admin to redefine the property in M-Files before using this procedure to manipulate the values of the properties.

Warnings
========

The property rule is set by class.  It will apply to all the objects that is included in the update routine.

The procedure will perform a metadata synchronization and table update and may run for a considerable time to complete.

Examples
========

.. code:: sql

    exec spmfSetAdditionalProperty 'MFCustomer','Keywords',1  --set to retain null values

    exec spmfSetAdditionalProperty 'MFCustomer','Keywords',0  --reset to remove property if null

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-09-20  LC         Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/


BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------

    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Set Additionl properties');

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
    DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFSetAdditionalProperty';
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
    -- Custom variables
    -------------------------------------------------------------
    DECLARE @Updatetype INT;

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
        -------------------------------------------------------------
        -- Process metadata
        -------------------------------------------------------------

        EXEC dbo.spMFDropAndUpdateMetadata @IsStructureOnly = 0,
                                           @RetainDeletions = @RetainDeletions,
                                           @IsDocumentCollection = @IsDocumentCollection,
                                           @ProcessBatch_ID = @ProcessBatch_ID,
                                           @Debug = 0;



        SET @DebugText = N' %s set to %i';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Update property definition';

        SET @Updatetype = CAST(@RetainIfNull AS INT);

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @MFProperty, @Updatetype);
        END;


        DECLARE @ClassID INT;
        DECLARE @PropertyID INT;
        DECLARE @ColumnName NVARCHAR(100);

        SELECT @ClassID = ID
        FROM dbo.MFClass
        WHERE TableName = @MFTableName;

        SELECT @PropertyID = ID,
               @ColumnName = ColumnName
        FROM dbo.MFProperty
        WHERE Name = @MFProperty;

        UPDATE mcp
        SET mcp.RetainIfNull = @RetainIfNull
        FROM dbo.MFClassProperty AS mcp
        WHERE mcp.MFClass_ID = @ClassID
              AND mcp.MFProperty_ID = @PropertyID;

        IF @RetainIfNull = 0 
        AND exists(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS AS c WHERE c.COLUMN_NAME = @ColumnName AND c.TABLE_NAME = @MFTableName)
        BEGIN

          SET @DebugText = N' ' + @MFtableName;
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Reset class table';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;


            SET @sql = N'Select @Count = count(*) from ' + QUOTENAME(@MFTableName) + '';

            EXEC sys.sp_executesql @sql, N'@Count int output', @count OUTPUT;

            SET @sql
                = N'Select @Count = count(*) from ' + QUOTENAME(@MFTableName) + ' where ' + QUOTENAME(@ColumnName)
                  + ' is not null';

            EXEC sys.sp_executesql @sql, N'@Count int output', @count OUTPUT;

            IF @count = 0
            BEGIN

                SET @sql = N'UPDATE mc
SET process_ID = 5
FROM ' +        QUOTENAME(@MFTableName) + ' AS mc 
WHERE objid > 0 and GUID is null';

                EXEC (@sql);

                EXEC dbo.spMFDeleteAdhocProperty @MFTableName = @MFTableName,
                                                 @columnNames = @ColumnName,
                                                 @process_ID = 5,
                                                 @Debug = 0;

            END;

        END;

        SET @LogTypeDetail = N'Status';
        SET @LogStatusDetail = N'Debug';
        SET @LogTextDetail = @MFProperty + N' for ' + @MFTableName + N' set to ' + CAST(@Updatetype AS VARCHAR(10));
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
                                         @LogType = N'Message',
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
