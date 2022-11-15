PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDeleteAdhocProperty]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFDeleteAdhocProperty'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.10.30.74'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
                                    -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFDeleteAdhocProperty' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFDeleteAdhocProperty]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFDeleteAdhocProperty]
(
    @MFTableName NVARCHAR(128)
                                --,@ObjId			    INT			-- ObjId the record
   ,@columnNames NVARCHAR(4000) --Property names separated by comma to delete the value 
   ,@process_ID SMALLINT        -- do not use 0
    ,@RetainDeletions BIT = 0
   , @IsDocumentCollection BIT = 0
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=======================
spMFDeleteAdhocProperty
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(128)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @columnNames nvarchar(4000)
    Name of the column to be removed
  @process\_ID smallint
    Use any flag that is not 0 = 4 to indicate the records that should be included. Set the flag on all records if the adhoc property should be removed from all
  @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
  @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

This procedure is specially useful when the metadata design in the vault has changed over time and properties that is not used any longer is still remaining on the metadata card.  Instead of manually deleted these properties from the metadata card, they can be deleted in bulk using the Connector.

Additional Info
===============

When a class table is refreshed in SQL and the properties are not defined on the metadata card, but are still on the object then it will be added as a separate column towards the end of the Class Table list of columns.

Using this procedure can delete these columns and delete it from the metadata.

Prerequisites
=============

There is a few requirements or steps to be taken to use this procedure:

- Identify the adhoc columns towards the end of the Class Table column list.
- Any column that is not a default column can be specified.
- The property will only be removed from the metadata card if there are no objects with values for that property any longer.
- If the property is set on the metadata card it, the value will be set to Null but it will not be removed.

Examples
========

.. code:: sql

    DECLARE @return_value int
    EXEC    @return_value = [dbo].[spMFDeleteAdhocProperty]
                                  @MFTableName =  N'MFCustomer',
                                  @columnNames =  N'Address',
                                  @process_ID = 5,
                                  @Debug =  NULL
    SELECT  'Return Value' = @return_value
    GO

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-09-02  LC         Update to include RetainDeletions and DocumentCollections
2020-08-22  LC         Update code for deleted column change
2019-08-30  JC         Added documentation
2018-04-25  LC         Fix bug to pick up both ID column and label column when deleting columns
2019-03-10  LC         Fix bug on not deleting the data in column
==========  =========  ========================================================

**rST*************************************************************************/
 /*******************************************************************************
  ** Desc:  The purpose of this procedure is used to delete Adhoc property value of objects
  **  
 */
BEGIN
    BEGIN TRY
        --BEGIN TRANSACTION
        SET NOCOUNT ON;

        -------------------------------------------------------------
        -- CONSTANTS: MFSQL Class Table Specific
        -------------------------------------------------------------
        DECLARE @ProcessType AS NVARCHAR(50);

        SET @ProcessType = 'Delete Properties';

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
        DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFDeleteAdhocProperty';
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

        -----------------------------------------------------
        --DECLARE LOCAL VARIABLE
        -----------------------------------------------------
        DECLARE @VaultSettings    NVARCHAR(4000)
               ,@ObjectId         INT
               ,@ClassId          INT
               ,@MFLastUpdateDate SMALLDATETIME
               ,@DeletedColumn      NVARCHAR(100);

-------------------------------------------------------------
-- Get deleted column
-------------------------------------------------------------

SELECT @DeletedColumn = columnName FROM dbo.MFProperty AS mp
WHERE mp.MFID = 27


        --check if table exists
        IF EXISTS
        (
            SELECT *
            FROM [sys].[objects]
            WHERE [object_id] = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
                  AND [type] IN ( N'U' )
        )
        BEGIN
            -----------------------------------------------------
            --GET LOGIN CREDENTIALS
            -----------------------------------------------------
            SET @ProcedureStep = 'Get Security Variables';

            SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

            IF @Debug > 0
            BEGIN
                SELECT @VaultSettings;
            END;

            -----------------------------------------------------
            --Set Object Type Id, class id
            -----------------------------------------------------
            SET @ProcedureStep = 'Get Object Type and Class';

            SELECT @ObjectId = [mot].[MFID]
                  ,@ClassId  = [mc].[MFID]
            FROM [dbo].[MFClass]                AS [mc]
                INNER JOIN [dbo].[MFObjectType] AS [mot]
                    ON [mc].[MFObjectType_ID] = [mot].[ID]
            WHERE [mc].[TableName] = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

            IF @Debug > 0
            BEGIN
                SELECT @ClassId  AS [classid]
                      ,@ObjectId AS [ObjectID];
            END;

            -----------------------------------------------------
            --SELECT THE ROW DETAILS DEPENDS ON USER INPUT
            -----------------------------------------------------
            SET @ProcedureStep = 'Count records to update';

            DECLARE @ColumnCount    INT
                   ,@SelectQuery    NVARCHAR(200)
                   ,@ParmDefinition NVARCHAR(500);

            SET @SelectQuery
                = 'SELECT @retvalOUT  = COUNT(ID) FROM [' + @MFTableName + '] WHERE Process_ID = '
                  + CAST(@process_ID AS NVARCHAR(20)) + ' AND ' +QUOTENAME(@DeletedColumn)+' is null';
            SET @ParmDefinition = N'@retvalOUT int OUTPUT';

            IF @Debug > 0
            BEGIN
                SELECT @SelectQuery AS [SELECT QUERY];
            END;

            EXEC [sys].[sp_executesql] @SelectQuery
                                      ,@ParmDefinition
                                      ,@retvalOUT = @count OUTPUT;

            SET @DebugText = 'Count of items to update %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @count);
            END;

            SELECT @ColumnCount = COUNT(*)
            FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                LEFT JOIN
                (
                    SELECT [ListItem] AS [columnname]
                    FROM [dbo].[fnMFParseDelimitedString](@columnNames, ',')
                )                               AS [list]
                    ON [list].[columnname] = [c].[COLUMN_NAME]
            WHERE [c].[TABLE_NAME] = @MFTableName;

            ----------------------------------------------------------------------------------------------------------
            --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
            ----------------------------------------------------------------------------------------------------------
            IF (@count + @ColumnCount > 0)
            BEGIN

                --Update table
                --EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = @MFTableName                  -- nvarchar(128)
                --                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT -- smalldatetime
                --                                    ,@UpdateTypeID = 1                            -- tinyint
                --                                    ,@Update_IDOut = @Update_ID OUTPUT            -- int
                --                                    ,@ProcessBatch_ID = @ProcessBatch_ID          -- int
                --                                    ,@debug = 0;

                                                                                                  -- tinyint

                --- set values of select columns and objects to null
                DECLARE @ColumnName NVARCHAR(100);

                DECLARE @ColumnList AS TABLE
                (
                    [ColumnName] NVARCHAR(100)
                );

                INSERT INTO @ColumnList
                (
                    [ColumnName]
                )
                SELECT [list].[Item]
                FROM [dbo].[fnMFSplitString](@columnNames, ',') [list]
                    INNER JOIN [dbo].[MFProperty]               AS [mp]
                        ON REPLACE([mp].[ColumnName], '_ID', '') = [list].[Item]
                UNION ALL
                SELECT [mp].[ColumnName]
                FROM [dbo].[fnMFSplitString](@columnNames, ',') [list]
                    INNER JOIN [dbo].[MFProperty]               AS [mp]
                        ON REPLACE([mp].[ColumnName], '_ID', '') = [list].[Item]
                WHERE [list].[Item] <> [mp].[ColumnName];

				Set @DebugText = ''
				Set @DebugText = @DefaultDebugText + @DebugText
				Set @Procedurestep = 'Get columns'
				
				IF @debug > 0
				SELECT * FROM @ColumnList AS [cl];
					Begin
						RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
					END
				

                DECLARE @UpdateQuery NVARCHAR(MAX);

                WHILE EXISTS (SELECT [cl].[ColumnName] FROM @ColumnList AS [cl])
                BEGIN
                    SELECT TOP 1
                           @ColumnName = [cl].[ColumnName]
                    FROM @ColumnList AS [cl];

                    SET @UpdateQuery = N'
					UPDATE tbl
					SET ' + @ColumnName + ' = null
					FROM ' + @MFTableName + ' tbl WHERE Process_ID = ' + CAST(@process_ID AS VARCHAR(10));
                    SET @DebugText = 'Items deleted in column ' + @ColumnName;
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    SET @ProcedureStep = 'Delete column values';

								Set @DebugText = ''
				Set @DebugText = @DefaultDebugText + @DebugText


                    IF @Debug > 0
                    BEGIN
					Select @UpdateQuery AS 'UpdateQuery'
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    EXEC (@UpdateQuery);

                    DELETE FROM @ColumnList
                    WHERE [ColumnName] = @ColumnName;
                END;

				SET @sqlParam = N'@Process_ID int'

				SET @UpdateQuery = N'UPDATE Tbl 
				SET Process_id = 1 
				FROM ' + QUOTENAME(@MFtableName) + ' Tbl
				WHERE process_ID = @process_id'

				EXEC sp_executeSQL @smtp = @UpdateQuery, @Param = @sqlParam, @Process_ID = @Process_ID

                ---update using mfupdatetable method 0

  EXEC dbo.spMFUpdateTable @MFTableName = @MFTablename,
                         @UpdateMethod = 0,
                         @Update_IDOut = @Update_ID OUTPUT,
                         @ProcessBatch_ID = @ProcessBatch_ID,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug                                                                               -- 

                ---if all values for column is null then delete column

                /*
Drop redundant columns
*/
                DECLARE @SQLquery NVARCHAR(MAX);

                INSERT INTO @ColumnList
                (
                    [ColumnName]
                )
                SELECT [Item]
                FROM [dbo].[fnMFSplitString](@columnNames, ',');

                WHILE EXISTS (SELECT TOP 1 [c].[ColumnName] FROM @ColumnList AS [c])
                BEGIN
                    SELECT TOP 1
                           @ColumnName = [c].[ColumnName]
                    FROM @ColumnList AS [c];

                    SET @SQLquery
                        = N'

								IF (SELECT COUNT(*) FROM ' + QUOTENAME(@MFTableName) + ' t WHERE t.' + @ColumnName
                          + ' IS NOT NULL) = 0
								BEGIN
								ALTER TABLE ' + QUOTENAME(@MFTableName) + '
								DROP COLUMN ' + QUOTENAME(@ColumnName) + '
								END;';

                    EXEC [sys].[sp_executesql] @SQLquery;

                    DELETE FROM @ColumnList
                    WHERE [ColumnName] = @ColumnName;
                END; -- while - column exist
            END; -- if count of records to update > 0
        END; -- if MFtableExist
        ELSE
        BEGIN
            SELECT 'Check the table Name Entered';
        END;

        SET NOCOUNT OFF;

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = 'End';
        SET @LogStatus = 'Completed';

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
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
