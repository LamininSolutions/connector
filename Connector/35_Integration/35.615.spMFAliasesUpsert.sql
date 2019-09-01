PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFAliasesUpsert]';
GO
SET NOCOUNT ON;
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFAliasesUpsert', -- nvarchar(100)
    @Object_Release = '3.1.4.41',
    @UpdateFlag = 2;

GO
/*------------------------------------------------------------------------------------------------
	Author: RemoteSQL
	Create date: 02/12/2017 18:07
	Database: 
	Description: 

	/*
Adding or removing aliases based on prefix
New alias
Prefix + columnName of property 
*/
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
  EXEC spMFAliasesUpsert @MFTableNames = 'MFProperty,MFClass', @Prefix = 'LSConnect',@WithUpdate = 1, @IsRemove = 0, @Debug = 1

-----------------------------------------------------------------------------------------------*/
IF EXISTS
    (
        SELECT
            1
        FROM
            [INFORMATION_SCHEMA].[ROUTINES]
        WHERE
            [ROUTINE_NAME] = 'spMFAliasesUpsert' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFAliasesUpsert]
AS
    SELECT
        'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFAliasesUpsert]
    (
        @MFTableNames    NVARCHAR(400), --options Property , Class, ObjectType, Valuelist, ValuelistItem
        @Prefix          NVARCHAR(10),  --constant prefer before name
        @IsRemove        BIT      = 0,  --if 1 then the aliases with the prefix will be removed.
        @WithUpdate      BIT      = 0,
        @ProcessBatch_ID INT      = NULL OUTPUT,
        @Debug           SMALLINT = 0
    )
AS
/*rST**************************************************************************

=================
spMFAliasesUpsert
=================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableNames nvarchar(400)
    fixme description
  @Prefix nvarchar(10)
    fixme description
  @IsRemove bit
    fixme description
  @WithUpdate bit
    fixme description
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
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

        DECLARE @ProcessType AS NVARCHAR(50);

        SET @ProcessType = ISNULL(@ProcessType, 'Create Aliases');

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
        DECLARE @ProcedureName AS NVARCHAR(128) = '[dbo].[spMFAliasesUpsert]';
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

        EXEC [dbo].[spMFProcessBatch_Upsert]
            @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = N'Status',
            @LogText = @LogText,
            @LogStatus = N'In Progress',
            @debug = @Debug;


        EXEC [dbo].[spMFProcessBatchDetail_Insert]
            @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = N'Debug',
            @LogText = @ProcessType,
            @LogStatus = N'Started',
            @StartTime = @StartTime,
            @MFTableName = @MFTableNames,
            @Validation_ID = @Validation_ID,
            @ColumnName = NULL,
            @ColumnValue = NULL,
            @Update_ID = @Update_ID,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
            @debug = 0;


        BEGIN TRY
            -------------------------------------------------------------
            -- BEGIN PROCESS
            -------------------------------------------------------------
					-----------------------------------------------------------------
	                  -- Checking module access for CLR procedure  
                    ------------------------------------------------------------------
                     EXEC [dbo].[spMFCheckLicenseStatus] 
					      'spMFAliasesUpsert'
						  ,@ProcedureName
						  ,@ProcedureStep
					
            -------------------------------------------------------------
            -- Local declarations
            -------------------------------------------------------------

            --DECLARE @Delimiter NCHAR(1) = ';';
            DECLARE @ValidTableNamesList NVARCHAR(400);
            --DECLARE @NewAlias NVARCHAR(100);

            -------------------------------------------------------------
            -- SETUP VALID META DATA TABLES TO BE INCLUDED
            -------------------------------------------------------------
            SET @ProcedureStep = 'Setup valid metadata tables';

            DECLARE @ValidTableNames AS TABLE
                (
                    [TableName] NVARCHAR(50) NOT NULL
                );
            INSERT INTO @ValidTableNames
                (
                    [TableName]
                )
            VALUES
                (
                    'MFClass'
                ),
                (
                    'MFProperty'
                ),
                (
                    'MFObjectType'
                ),
                (
                    'MFValuelist'
                ),
                (
                    'MFWorkflow'
                ),
                (
                    'MFWorkflowState'
                );

            DECLARE @MetadataList AS TABLE
                (
                    [id]        INT           IDENTITY NOT NULL,
                    [TableName] NVARCHAR(100) NULL,
                    [Metadata]  NVARCHAR(100) NULL
                );

            INSERT INTO @MetadataList
                (
                    [TableName],
                    [Metadata]
                )
                        SELECT
                            LTRIM([ListItem]),
                            REPLACE([ListItem], 'MF', '')
                        FROM
                            [dbo].[fnMFParseDelimitedString](@MFTableNames, ',') AS [fmpds];

            IF @Debug > 0
                SELECT
                    *
                FROM
                    @MetadataList AS [ml];

            -------------------------------------------------------------
            -- vALIDATE TABLE PARAMETERS
            -------------------------------------------------------------
            SET @ProcedureStep = 'Validate input tables';


            SELECT
                @ValidTableNamesList = COALESCE(@ValidTableNamesList + ',', '') + [TableName]
            FROM
                @ValidTableNames AS [vtn];

            IF @Debug > 0
                BEGIN
                    SELECT
                        @ValidTableNamesList;
                    SELECT
                            'invalid' AS [invalids],
                            [ml].[TableName]
                    FROM
                            @MetadataList    AS [ml]
                        LEFT JOIN
                            @ValidTableNames AS [vtn]
                                ON [ml].[TableName] = [vtn].[TableName]
                    WHERE
                            [vtn].[TableName] IS NULL;
                END;

            IF EXISTS
                (
                    SELECT
                            [ml].[TableName]
                    FROM
                            @MetadataList    AS [ml]
                        LEFT JOIN
                            @ValidTableNames AS [vtn]
                                ON [ml].[TableName] = [vtn].[TableName]
                    WHERE
                            [vtn].[TableName] IS NULL
                )
                BEGIN
                    SET @error
                        = '' + @MFTableNames + ' ; Use one or more of the following list: ' + @ValidTableNamesList;
                    SET @DebugText = @DefaultDebugText + 'Invalid TableNames in:%s';



                    SET @LogTypeDetail = 'Validate';
                    SET @LogStatusDetail = 'Error';
                    SET @LogTextDetail = @error;
                    SET @LogColumnName = '';
                    SET @LogColumnValue = '';

                    EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                        @ProcessBatch_ID = @ProcessBatch_ID,
                        @LogType = @LogTypeDetail,
                        @LogText = @LogTextDetail,
                        @LogStatus = @LogStatusDetail,
                        @StartTime = @StartTime,
                        @MFTableName = @MFTableNames,
                        @Validation_ID = @Validation_ID,
                        @ColumnName = @LogColumnName,
                        @ColumnValue = @LogColumnValue,
                        @Update_ID = @Update_ID,
                        @LogProcedureName = @ProcedureName,
                        @LogProcedureStep = @ProcedureStep,
                        @debug = @Debug;



                    RAISERROR(@DebugText, @MsgSeverityGeneralError, 1, @ProcedureName, @ProcedureStep, @error);

                    RETURN 0;
                END;


            -------------------------------------------------------------
            -- PROCESS INSERT ALIASES FOR EACH METADATA TABLE
            -------------------------------------------------------------


            SET @ProcedureStep = 'Process Aliases';
			 SET @StartTime = GETUTCDATE();

            BEGIN

                DECLARE @RowID INT;
                DECLARE @TableName NVARCHAR(100);
                DECLARE @MetadataName NVARCHAR(100);

                SELECT
                    @RowID = MIN([id])
                FROM
                    @MetadataList AS [ml];

                WHILE @RowID IS NOT NULL
                    BEGIN

                        SELECT
                            @TableName    = [TableName],
                            @MetadataName = [Metadata]
                        FROM
                            @MetadataList AS [ml]
                        WHERE
                            [id] = @RowID;

                        -------------------------------------------------------------
                        -- UPDATE METADATA TABLE
                        -------------------------------------------------------------
                        SET @ProcedureStep = 'Synchronize Metadata';

                        EXEC [dbo].[spMFSynchronizeSpecificMetadata]
                            @Metadata = @MetadataName,
                            @IsUpdate = 0,
                            @Debug = 0;

                        -------------------------------------------------------------
                        -- ADD ALIASES
                        -------------------------------------------------------------
                        SET @ProcedureStep = 'Add Aliases';
                        IF @IsRemove = 0
                            BEGIN

IF @TableName = 'MFWorkflowState'
BEGIN
                            
        UPDATE
            mws
        SET
         mws.alias =   SUBSTRING((@Prefix + '.' + [dbo].[fnMFReplaceSpecialCharacter](mw.Name) + '.' + [dbo].[fnMFReplaceSpecialCharacter](mws.Name)),1,100)
        FROM
            [dbo].[MFWorkflowState] AS mws
			INNER JOIN [dbo].[MFWorkflow] AS mw
			ON [mw].[ID] = [mws].[MFWorkflowID]

        WHERE
            mws.[Alias] = ''  

			SET @SQL = ''

END
IF @TableName <> 'MFWorkflowState'
BEGIN



                                SET @sqlParam = N'@Prefix nvarchar(10), @RowCount int output';
                                SET @sql
                                    = N'
        UPDATE
            [TB]
        SET
            [Alias] = @Prefix + ''.'' + [dbo].[fnMFReplaceSpecialCharacter](Name)
        FROM
            [dbo].' +           QUOTENAME(@TableName) + ' AS [TB]
        WHERE
            [Alias] = ''''
			
				 SET @rowcount = @@ROWCOUNT;

			'    ;

END

			IF @Debug > 0
			PRINT @SQL;
                                EXEC [sp_executesql]
                                    @stmt = @sql,
                                    @param = @sqlParam,
                                    @Prefix = @Prefix,
									@RowCount = @RowCount output;

						

IF @Debug > 0
EXEC ('Select * from ' + @TableName);




                                SET @LogTypeDetail = 'Status';
                                SET @LogStatusDetail = 'Completed';
                                SET @LogTextDetail = 'Added Aliases';
                                SET @LogColumnName = @MetadataName;
                                SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));


                                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                                    @ProcessBatch_ID = @ProcessBatch_ID,
                                    @LogType = @LogTypeDetail,
                                    @LogText = @LogTextDetail,
                                    @LogStatus = @LogStatusDetail,
                                    @StartTime = @StartTime,
                                    @MFTableName = @MFTableNames,
                                    @Validation_ID = @Validation_ID,
                                    @ColumnName = @LogColumnName,
                                    @ColumnValue = @LogColumnValue,
                                    @Update_ID = @Update_ID,
                                    @LogProcedureName = @ProcedureName,
                                    @LogProcedureStep = @ProcedureStep,
                                    @debug = @Debug;



                                -------------------------------------------------------------
                                -- Re-assign duplicates with sequence number
                                -------------------------------------------------------------
                                SET @ProcedureStep = 'Re-assign duplicates';

								 SET @StartTime = GETUTCDATE();

                                CREATE TABLE [#DuplicateList]
                                    (
                                        [id]        INT,
                                        [Name]      NVARCHAR(100),
                                        [Alias]     NVARCHAR(100),
                                        [Rownumber] INT
                                    );

                                SET @sql
                                    = N'
SELECT id, mp.name,[mp].[Alias], ROW_NUMBER() OVER (PARTITION BY alias ORDER BY id)  FROM [dbo].'
                                      + QUOTENAME(@TableName)
                                      + ' AS [mp] WHERE alias IN (
SELECT listitem  FROM [dbo].' + QUOTENAME(@TableName)
                                      + ' AS [mp]
CROSS APPLY [dbo].[fnMFParseDelimitedString](mp.Alias,'';'') AS [fmpds]
GROUP BY [fmpds].[ListItem]
HAVING COUNT(*) > 1 ) '         ;

                                INSERT INTO [#DuplicateList]
                                    (
                                        [id],
                                        [Name],
                                        [Alias],
                                        [Rownumber]
                                    )
                                EXEC (@sql);

IF @Debug > 0
SELECT * FROM [#DuplicateList] AS [dl];


                                SET @sql = N'
SELECT * FROM #DuplicateList AS [dl]
INNER JOIN [dbo].' +            QUOTENAME(@TableName) + ' AS [mp]
ON dl.id = mp.[ID]'             ;

                                EXEC (@sql);

                                SET @rowcount = @@ROWCOUNT;

                                SET @LogTypeDetail = 'Status';
                                SET @LogStatusDetail = 'Completed';
                                SET @LogTextDetail = 'Renamed Duplicate Aliases';
                                SET @LogColumnName = @MetadataName;
                                SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));


                                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                                    @ProcessBatch_ID = @ProcessBatch_ID,
                                    @LogType = @LogTypeDetail,
                                    @LogText = @LogTextDetail,
                                    @LogStatus = @LogStatusDetail,
                                    @StartTime = @StartTime,
                                    @MFTableName = @MFTableNames,
                                    @Validation_ID = @Validation_ID,
                                    @ColumnName = @LogColumnName,
                                    @ColumnValue = @LogColumnValue,
                                    @Update_ID = @Update_ID,
                                    @LogProcedureName = @ProcedureName,
                                    @LogProcedureStep = @ProcedureStep,
                                    @debug = @Debug;

                            END; --End add aliases

                        -------------------------------------------------------------
                        -- REMOVE ALIASSES BASED ON PREFIX
                        -------------------------------------------------------------
                        IF @IsRemove = 1
                            BEGIN

								 SET @StartTime = GETUTCDATE();
                                SET @ProcedureStep = 'Remove aliasses';

                                CREATE TABLE [#RemovalList]
                                    (
                                        [id]          INT,
                                        [Name]        NVARCHAR(100),
                                        [AliasString] NVARCHAR(100),
                                        [Alias]       NVARCHAR(100)
                                    );

                                SET @sqlParam = N'@Prefix nvarchar(10)';
                                SET @sql
                                    = N'SELECT [mp].[ID],
       [mp].[Name],
       [mp].[Alias],
     
       [fmpds].[ListItem] FROM ' + @TableName
                                      + ' AS [mp]
CROSS APPLY [dbo].[fnMFParseDelimitedString](Alias,'';'') AS [fmpds]
'                               ;



                                INSERT INTO [#RemovalList]
                                    (
                                        [id],
                                        [Name],
                                        [AliasString],
                                        [Alias]
                                    )
                                EXEC (@sql);

                                SET @sql
                                    = N'
UPDATE mp
SET alias =  REPLACE(rl.Alias,mp.alias,'''') FROM #RemovalList AS [rl] 
INNER JOIN ' +                  QUOTENAME(@TableName) + ' mp
ON mp.id = rl.id
WHERE rl.alias LIKE (@Prefix + ''%'')';

                                EXEC [sp_executesql]
                                    @stmt = @sql,
                                    @param = @sqlParam,
                                    @Prefix = @Prefix;

                                SET @rowcount = @@ROWCOUNT;

                                SET @LogTypeDetail = 'Status';
                                SET @LogStatusDetail = 'Completed';
                                SET @LogTextDetail = 'Removed Aliases';
                                SET @LogColumnName = @MetadataName;
                                SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));


                                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                                    @ProcessBatch_ID = @ProcessBatch_ID,
                                    @LogType = @LogTypeDetail,
                                    @LogText = @LogTextDetail,
                                    @LogStatus = @LogStatusDetail,
                                    @StartTime = @StartTime,
                                    @MFTableName = @MFTableNames,
                                    @Validation_ID = @Validation_ID,
                                    @ColumnName = @LogColumnName,
                                    @ColumnValue = @LogColumnValue,
                                    @Update_ID = @Update_ID,
                                    @LogProcedureName = @ProcedureName,
                                    @LogProcedureStep = @ProcedureStep,
                                    @debug = @Debug;
                            END;

                        -------------------------------------------------------------
                        -- UPDATE M-FILES
                        -------------------------------------------------------------

                        SET @ProcedureStep = 'Update M-Files';
						 SET @StartTime = GETUTCDATE();
                        --	SELECT @Count = COUNT(*) FROM  
                        IF @WithUpdate = 1
                            EXEC [dbo].[spMFSynchronizeSpecificMetadata]
                                @Metadata = @MetadataName,
                                @IsUpdate = 1;

                        SET @rowcount = @@ROWCOUNT;

                        SET @LogTypeDetail = 'Status';
                        SET @LogStatusDetail = 'Completed';
                        SET @LogTextDetail = 'spMFSynchronizeSpecificMetadata with IsUpdate = 1';
                        SET @LogColumnName = @TableName;
                        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));


                        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID,
                            @LogType = @LogTypeDetail,
                            @LogText = @LogTextDetail,
                            @LogStatus = @LogStatusDetail,
                            @StartTime = @StartTime,
                            @MFTableName = @TableName,
                            @Validation_ID = @Validation_ID,
                            @ColumnName = @LogColumnName,
                            @ColumnValue = @LogColumnValue,
                            @Update_ID = @Update_ID,
                            @LogProcedureName = @ProcedureName,
                            @LogProcedureStep = @ProcedureStep,
                            @debug = @Debug;

                        SELECT
                            @RowID = MIN([id])
                        FROM
                            @MetadataList AS [ml]
                        WHERE
                            [id] > @RowID;
                    
					IF OBJECT_ID('tempdb..#DuplicateList') IS NOT NULL
					    DROP TABLE #DuplicateList;
					IF OBJECT_ID('tempdb..#RemovalList') IS NOT NULL
                        DROP TABLE #RemovalList;

                    END; -- end while 
            END; -- end raiseerror invalid name

            -------------------------------------------------------------
            --END PROCESS
            -------------------------------------------------------------


            END_RUN:
            SET @ProcedureStep = 'End';
            SET @LogStatus = 'Completed';
            -------------------------------------------------------------
            -- Log End of Process
            -------------------------------------------------------------   

            EXEC [dbo].[spMFProcessBatch_Upsert]
                @ProcessBatch_ID = @ProcessBatch_ID,
                @ProcessType = @ProcessType,
                @LogType = N'Message',
                @LogText = @LogText,
                @LogStatus = @LogStatus,
                @debug = @Debug;

            SET @StartTime = GETUTCDATE();

            EXEC [dbo].[spMFProcessBatchDetail_Insert]
                @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = N'Debug',
                @LogText = @ProcessType,
                @LogStatus = @LogStatus,
                @StartTime = @StartTime,
                @MFTableName = @MFTableNames,
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
            SET @LogStatus = 'Failed w/SQL Error';
            SET @LogTextDetail = ERROR_MESSAGE();

            --------------------------------------------------
            -- INSERTING ERROR DETAILS INTO LOG TABLE
            --------------------------------------------------
            INSERT INTO [dbo].[MFLog]
                (
                    [SPName],
                    [ErrorNumber],
                    [ErrorMessage],
                    [ErrorProcedure],
                    [ErrorState],
                    [ErrorSeverity],
                    [ErrorLine],
                    [ProcedureStep]
                )
            VALUES
                (
                    @ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(),
                    ERROR_SEVERITY(), ERROR_LINE(), @ProcedureStep
                );

            SET @ProcedureStep = 'Catch Error';
            -------------------------------------------------------------
            -- Log Error
            -------------------------------------------------------------   
            EXEC [dbo].[spMFProcessBatch_Upsert]
                @ProcessBatch_ID = @ProcessBatch_ID,
                @ProcessType = @ProcessType,
                @LogType = N'Error',
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatus,
                @debug = @Debug;

            SET @StartTime = GETUTCDATE();

            EXEC [dbo].[spMFProcessBatchDetail_Insert]
                @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = N'Error',
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatus,
                @StartTime = @StartTime,
                @MFTableName = @MFTableNames,
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

