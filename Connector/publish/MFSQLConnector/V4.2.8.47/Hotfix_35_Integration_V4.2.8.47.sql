
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwObjectTypeSummary]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'MFvwObjectTypeSummary' -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.46'           -- varchar(50)
                                    ,@UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[VIEWS]
    WHERE [TABLE_NAME] = 'MFvwObjectTypeSummary'
          AND [TABLE_SCHEMA] = 'dbo'
)
BEGIN
    SET NOEXEC ON;
END;
GO

CREATE VIEW [dbo].[MFvwObjectTypeSummary]
AS
SELECT [Column1] = 'UNDER CONSTRUCTION';
GO

SET NOEXEC OFF;
GO

/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2018-12

-- Description:	Summary of Records by object type and class
-- Revision History:  
-- YYYYMMDD Author - Description 

2019-1-18 LC	Fix bug on document collections
-- =============================================
*/
ALTER VIEW [dbo].[MFvwObjectTypeSummary]
AS
WITH [cte]
AS (
   SELECT [mottco].[ObjectType_ID]
         ,[mottco].[Class_ID]
         ,COUNT(*)                    [RecordCount]
         ,MAX([mottco].[Object_MFID]) [MaximumObjid]
   FROM [dbo].[MFObjectTypeToClassObject] AS [mottco]
   GROUP BY [mottco].[ObjectType_ID]
           ,[mottco].[Class_ID])
SELECT [mc].[Name]  AS [Class]
      ,[mot].[Name] AS [ObjectType]
      ,[cte].[RecordCount]
      ,[cte].[MaximumObjid]
      ,[mc].[IncludeInApp]
FROM [cte]
    INNER JOIN [dbo].[MFClass]      AS [mc]
        ON [cte].[Class_ID] = [mc].[MFID]
    INNER JOIN [dbo].[MFObjectType] AS [mot]
        ON [cte].[ObjectType_ID] = [mot].MFID
GO
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeFilesToMFiles]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFSynchronizeFilesToMFiles'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.47'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  2019-1-15		LC			Fix bug with file import using GUID as unique ref; improve logging messages

  ********************************************************************************
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFSynchronizeFilesToMFiles' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeFilesToMFiles]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeFilesToMFiles]
    @SourceTableName NVARCHAR(100)
   ,@FileUniqueKeyColumn NVARCHAR(100)
   ,@FileNameColumn NVARCHAR(100)
   ,@FileDataColumn NVARCHAR(100)
   ,@MFTableName NVARCHAR(100)
   ,@TargetFileUniqueKeycolumnName NVARCHAR(100) = 'MFSQL_Unique_File_Ref'
   ,@BatchSize INT = 500
   ,@Process_ID INT = 5
   ,@ProcessBatch_id INT = NULL OUTPUT
   ,@Debug INT = 0
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

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
        DECLARE @Update_ID INT;
        DECLARE @ProcedureName sysname = 'spMFSynchronizeFilesToMFiles';
        DECLARE @ProcedureStep sysname = 'Start';

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

        SET @ProcessType = 'Import Files';
        SET @LogText = ' Started ';
        SET @LogStatus = 'Initiate';
        SET @StartTime = GETUTCDATE();
        SET @LogTypeDetail = 'Debug';
        SET @LogStatusDetail = 'In Progress';

        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_id OUTPUT
                                                     ,@ProcessType = @ProcessType
                                                     ,@LogType = @LogType
                                                     ,@LogText = @LogText
                                                     ,@LogStatus = @LogStatus
                                                     ,@debug = 0;

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
                                                                     ,@debug = 0;

        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        ----------------------------------------
        --DECLARE VARIABLES
        ----------------------------------------
        DECLARE @TargetClassMFID INT;
        DECLARE @ObjectTypeID INT;
        DECLARE @VaultSettings NVARCHAR(MAX);
        DECLARE @XML NVARCHAR(MAX);
        DECLARE @Counter INT;
        DECLARE @MaxRowID INT;
        DECLARE @ObjIDs NVARCHAR(4000);
        DECLARE @FileLocation VARCHAR(200);
        DECLARE @Sql NVARCHAR(MAX);
        DECLARE @Params NVARCHAR(MAX);

        SET @ProcedureStep = 'Checking Target class ';
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF EXISTS
        (
            SELECT TOP 1
                   *
            FROM [dbo].[MFClass]
            WHERE [TableName] = @MFTableName
        )
        BEGIN
            SET @LogTextDetail = @MFTableName + ' is present in the MFClass table';

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
                                                                         ,@debug = 0;

            SELECT @TargetClassMFID = [MC].[MFID]
                  ,@ObjectTypeID    = [OT].[MFID]
            FROM [dbo].[MFClass]                [MC]
                INNER JOIN [dbo].[MFObjectType] [OT]
                    ON [MC].[MFObjectType_ID] = [OT].[ID]
            WHERE [MC].[TableName] = @MFTableName;

            SET @ProcedureStep = 'Checking File unique key property ';
            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            IF EXISTS
            (
                SELECT *
                FROM [INFORMATION_SCHEMA].[COLUMNS] [C]
                WHERE [C].[TABLE_NAME] = @MFTableName
                      AND [C].[COLUMN_NAME] = @TargetFileUniqueKeycolumnName
            )
            BEGIN
                SET @LogTextDetail
                    = @TargetFileUniqueKeycolumnName + ' is present in the Target class ' + @MFTableName;

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
                                                                             ,@debug = 0;

                ------------------------------------------------
                --Getting Vault Settings
                ------------------------------------------------
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Getting Vault credentials ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

                -------------------------------------------------------------
                -- Validate unique reference
                -------------------------------------------------------------
                SET @ProcedureStep = 'Duplicate unique ref count  ';
                SET @rowcount = NULL;
                SET @Params = N'@rowCount int output';
                SET @Sql = N'	
SELECT @Rowcount = COUNT(*) FROM ' + QUOTENAME(@MFTableName) + '
where ' +       QUOTENAME(@TargetFileUniqueKeycolumnName) + ' is not null 
GROUP BY ' +    QUOTENAME(@TargetFileUniqueKeycolumnName) + ' HAVING COUNT(*) > 1';

                EXEC [sys].[sp_executesql] @stmt = @Sql
                                          ,@param = @Params
                                          ,@rowcount = @rowcount OUTPUT;

                --IF @Debug > 0
                --    PRINT @Sql;
                SELECT @rowcount = ISNULL(@rowcount, 0);

                SET @DebugText = 'Duplicate Rows: %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                END;

                IF @rowcount > 0
                BEGIN
                    SET @DebugText = 'Unique Ref has duplicate items - not allowed ';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Validate Unique File reference ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                    END;

                    SET @LogTextDetail = @DebugText;
                    SET @LogTypeDetail = 'Error';
                    SET @LogStatusDetail = 'Error';

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
                                                                                 ,@debug = 0;
                END;

                ------------------------------------------------
                --Getting Temp File location to store File
                ------------------------------------------------
                SELECT @FileLocation = ISNULL(CAST([Value] AS NVARCHAR(200)), 'Invalid location')
                FROM [dbo].[MFSettings]
                WHERE [source_key] = 'Files_Default'
                      AND [Name] = 'FileTransferLocation';

                SET @DebugText = ' ' + @FileLocation;
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Get file transfer location: ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                ------------------------------------------------
                --Creating Temp table to fecth only 500 records
                ------------------------------------------------
                SET @ProcedureStep = 'Create Temp file';

                DECLARE @TempFile VARCHAR(100);

                SELECT @TempFile = '##' + [dbo].[fnMFVariableTableName]('InsertFiles', '');

                SET @DebugText = 'Tempfile %s';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = '';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TempFile);
                END;

                --SET @SQL = N'
                --            CREATE TABLE '+@TempFile + '
                --            (
                --                [RowID] INT IDENTITY(1, 1)
                --               ,[FileUniqueID] NVARCHAR(250)
                --            );'

                --            EXEC (@SQL)
                -----------------------------------------------------
                --Inserting @BatchSize records into the Temp table
                ----------------------------------------------------
                SET @ProcedureStep = 'Insert records into TempFile';
                SET @Sql
                    = N' Select * into ' + @TempFile + ' From (select top ' + CAST(@BatchSize AS VARCHAR(10))
                      + ' TN.ID as RowID, SR.' + @FileUniqueKeyColumn + ' as FileUniqueID from ' + @SourceTableName
                      + ' SR inner join ' + @MFTableName + ' TN on SR.' + @FileUniqueKeyColumn + '=TN.'
                      + @TargetFileUniqueKeycolumnName + ' and TN.Process_ID= ' + CAST(@Process_ID AS VARCHAR(5))
                      + ')list;';

                IF @Debug > 0
                    PRINT @Sql;

                EXEC [sys].[sp_executesql] @Stmt = @Sql;

                IF @Debug > 0
                BEGIN
                    EXEC (N'Select Count(*) as FileCount from ' + @TempFile);
                END;

                SET @DebugText = 'TempFile: %s';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TempFile);
                END;

                SET @LogTextDetail = 'Records insert in Temp file';
                SET @LogColumnName = @TempFile;
                SET @LogColumnValue = CAST(@BatchSize AS VARCHAR(10));

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
                                                                             ,@debug = 0;

                SET @Params = N'@RowID int output';
                SET @Sql = N'
                SELECT @RowID = Min([RowID])
                FROM ' + @TempFile;

                EXEC [sys].[sp_executesql] @Stmt = @Sql
                                          ,@param = @Params
                                          ,@RowID = @Counter OUTPUT;

                SET @DebugText = '  Min RowID %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Counter);
                END;

                SET @ProcedureStep = 'Loop for importing file from source ';

                WHILE @Counter IS NOT NULL
                BEGIN
                    DECLARE @FileID NVARCHAR(250);
                    DECLARE @ParmDefinition NVARCHAR(500);
                    DECLARE @XMLOut        XML
                           ,@SqlID         INT
                           ,@ObjId         INT
                           ,@ObjectVersion INT;

                    SET @ProcedureStep = 'Get latest version';

					SET @params = N'@ObjIDs nvarchar(4000) output, @Counter int'
					SET @SQL = N'Select @ObjIDs = CAST(Objid AS VARCHAR(4000)) FROM '+QUOTENAME(@MFTableName) + ' WHERE ID = @Counter'

					EXEC sp_executeSQL @SQL, @Params, @Objids OUTPUT, @Counter

					Set @DebugText = ' Objids %s'
					Set @DebugText = @DefaultDebugText + @DebugText
					Set @Procedurestep = 'Get Objids for update'
					
					IF @debug > 0
						Begin
							RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@Objids );
						END
					
					SET @Params = N'@Objids nvarchar(4000)'
					SET @SQL = N'UPDATE '+ QUOTENAME(@MFTableName)+' SET [Process_ID] = 0 WHERE objid = CAST(@Objids AS int)'
					EXEC sp_executeSQL @SQL, @Params, @Objids 

                    EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName                 -- nvarchar(200)
                                                ,@UpdateMethod = 1                           -- int                          
                                                ,@ObjIDs = @ObjIDs                           -- nvarchar(max)
                                                ,@Update_IDOut = @Update_IDOut OUTPUT        -- int
                                                ,@ProcessBatch_ID = @ProcessBatch_id; -- int
					
					SET @Params = N'@Process_ID int, @Objids nvarchar(4000)'
					SET @SQL = N'UPDATE '+ QUOTENAME(@MFTableName)+' SET [Process_ID] = @Process_ID WHERE objid = CAST(@Objids AS int)'
					EXEC sp_executeSQL @SQL, @Params, @process_ID, @Objids 


                    SET @ProcedureStep = 'Get uniqueID';
                    SET @Params = N'@FileID nvarchar(250) output, @Counter int';
                    SET @Sql = N'SELECT @FileID = [FileUniqueID] FROM ' + @TempFile + ' WHERE [RowID] = @Counter;';

                    EXEC [sys].[sp_executesql] @Sql, @Params, @FileID OUTPUT, @Counter;

                    SET @DebugText = ' FileID: %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @FileID);
                    END;

                    SET @ProcedureStep = 'Get object Details';
                    SET @Params
                        = N'@SQLID int OUTPUT,@ObjId  INT OUTPUT,@ObjectVersion  INT OUTPUT,@FileID nvarchar(250)';
                    SET @Sql
                        = 'select @SqlID=ID,@ObjId=ObjID,@ObjectVersion=MFVersion  from ' + @MFTableName + ' where '
                          + @TargetFileUniqueKeycolumnName + '= ''' + @FileID + '''';

                    IF @Debug > 0
                        PRINT @Sql;

                    EXEC [sys].[sp_executesql] @stmt = @Sql
                                              ,@param = @Params
                                              ,@SQLID = @SqlID OUTPUT
                                              ,@ObjId = @ObjId OUTPUT
                                              ,@ObjectVersion = @ObjectVersion OUTPUT
                                              ,@FileID = @FileID;

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

					-------------------------------------------------------------
					-- Validate file data  (filename not null)
					-------------------------------------------------------------
					DECLARE @FileNameExist nvarchar(250) 
					SET @params = '@FileNameExist nvarchar(250) output, @Counter int'
					SET @SQL = N'
					SELECT @FileNameExist = FileName FROM '+ @SourceTableName +' S
					INNER JOIN '+ @Tempfile + ' t
					ON s.'+ @FileUniqueKeyColumn +' = t.FileUniqueID
					WHERE t.RowID = @Counter;'

					IF @Debug > 0
					PRINT @SQL;

					EXEC sp_executeSQL @SQL, @Params, @FileNameExist OUTPUT, @counter

					IF ISNULL(@FileNameExist,'') <> ''
					Begin

                    -----------------------------------------------------
                    --Creating the xml 
                    ----------------------------------------------------
                    DECLARE @Query NVARCHAR(MAX);

                    SET @ProcedureStep = 'Prepare ColumnValue pair';

                    DECLARE @ColumnValuePair TABLE
                    (
                        [ColunmName] NVARCHAR(200)
                       ,[ColumnValue] NVARCHAR(4000)
                       ,[Required] BIT ---Added for checking Required property for table
                    );

                    DECLARE @TableWhereClause VARCHAR(1000)
                           ,@tempTableName    VARCHAR(1000)
                           ,@XMLFile          XML;

                    SET @TableWhereClause
                        = 'y.' + @TargetFileUniqueKeycolumnName + '=cast(''' + @FileID
                          + ''' as nvarchar(100)) and Process_Id= ' + CAST(@Process_ID AS VARCHAR(5));

                    IF @Debug > 0
                        PRINT @TableWhereClause;

                    ----------------------------------------------------------------------------------------------------------
                    --Generate query to get column values as row value
                    ----------------------------------------------------------------------------------------------------------
                    SET @ProcedureStep = 'Prepare query';

                    SELECT @Query
                        = STUFF(
                          (
                              SELECT ' UNION ' + 'SELECT ''' + [COLUMN_NAME] + ''' as name, CONVERT(VARCHAR(max),['
                                     + [COLUMN_NAME] + ']) as value, 0  as Required FROM [' + @MFTableName + '] y'
                                     + ISNULL('  WHERE ' + @TableWhereClause, '')
                              FROM [INFORMATION_SCHEMA].[COLUMNS]
                              WHERE [TABLE_NAME] = @MFTableName
                              FOR XML PATH('')
                          )
                         ,1
                         ,7
                         ,''
                               );

                    IF @Debug > 0
                        PRINT @Query;

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    -----------------------------------------------------
                    --List of columns to exclude
                    -----------------------------------------------------
                    SET @ProcedureStep = 'Prepare exclusion list';

                    DECLARE @ExcludeList AS TABLE
                    (
                        [ColumnName] VARCHAR(100)
                    );

                    INSERT INTO @ExcludeList
                    (
                        [ColumnName]
                    )
                    SELECT [mp].[ColumnName]
                    FROM [dbo].[MFProperty] AS [mp]
                    WHERE [mp].[MFID] IN ( 20, 21, 23, 25 );

                    --Last Modified, Last Modified by, Created, Created by

                    -----------------------------------------------------
                    --Insert to values INTo temp table
                    -----------------------------------------------------
                    --               PRINT @Query;
                    SET @ProcedureStep = 'Execute query';

					DELETE FROM @ColumnValuePair 
					--IF @Debug > 0
					--SELECT * FROM @ColumnValuePair AS [cvp];

                    INSERT INTO @ColumnValuePair
                    EXEC (@Query);

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
								SELECT * FROM @ColumnValuePair AS [cvp];
                    END;

                    SET @ProcedureStep = 'Remove exclusions';

                    DELETE FROM @ColumnValuePair
                    WHERE [ColunmName] IN (
                                              SELECT [el].[ColumnName] FROM @ExcludeList AS [el]
                                          );

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    --SELECT *
                    --FROM @ColumnValuePair;

                    ----------------------	 Add for checking Required property--------------------------------------------
                    SET @ProcedureStep = 'Check for required properties';

                    UPDATE [CVP]
                    SET [CVP].[Required] = [CP].[Required]
                    FROM @ColumnValuePair                  [CVP]
                        INNER JOIN [dbo].[MFProperty]      [P]
                            ON [CVP].[ColunmName] = [P].[ColumnName]
                        INNER JOIN [dbo].[MFClassProperty] [CP]
                            ON [P].[ID] = [CP].[MFProperty_ID]
                        INNER JOIN [dbo].[MFClass]         [C]
                            ON [CP].[MFClass_ID] = [C].[ID]
                    WHERE [C].[TableName] = @MFTableName;

                    UPDATE @ColumnValuePair
                    SET [ColumnValue] = 'ZZZ'
                    WHERE [Required] = 1
                          AND [ColumnValue] IS NULL;

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    ------------------	 Add for checking Required property------------------------------------
                    SET @ProcedureStep = 'Convert datatime';

                    --DELETE FROM @ColumnValuePair
                    --WHERE  ColumnValue IS NULL
                    UPDATE [cp]
                    SET [cp].[ColumnValue] = CONVERT(DATE, CAST([cp].[ColumnValue] AS NVARCHAR(100)))
                    FROM @ColumnValuePair                         AS [cp]
                        INNER JOIN [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                            ON [c].[COLUMN_NAME] = [cp].[ColunmName]
                    WHERE [c].[DATA_TYPE] = 'datetime'
                          AND [cp].[ColumnValue] IS NOT NULL;

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    SET @ProcedureStep = 'Creating XML';
                    -----------------------------------------------------
                    --Generate xml file -- 
                    -----------------------------------------------------
                    --SELECT *
                    --FROM @ColumnValuePair;
                    SET @XMLFile =
                    (
                        SELECT @ObjectTypeID  AS [Object/@id]
                              ,@SqlID         AS [Object/@sqlID]
                              ,@ObjId         AS [Object/@objID]
                              ,@ObjectVersion AS [Object/@objVesrion]
                              ,0              AS [Object/@DisplayID]
                              ,(
                                   SELECT
                                       (
                                           SELECT TOP 1
                                                  [tmp].[ColumnValue]
                                           FROM @ColumnValuePair             AS [tmp]
                                               INNER JOIN [dbo].[MFProperty] AS [mfp]
                                                   ON [mfp].[ColumnName] = [tmp].[ColunmName]
                                           WHERE [mfp].[MFID] = 100
                                       ) AS [class/@id]
                                      ,(
                                           SELECT [mfp].[MFID] AS [property/@id]
                                                 ,(
                                                      SELECT [MFTypeID]
                                                      FROM [dbo].[MFDataType]
                                                      WHERE [ID] = [mfp].[MFDataType_ID]
                                                  )            AS [property/@dataType]
                                                 ,CASE
                                                      WHEN [tmp].[ColumnValue] = 'ZZZ' THEN
                                                          NULL
                                                      ELSE
                                                          [tmp].[ColumnValue]
                                                  END          AS 'property' ----Added case statement for checking Required property
                                           FROM @ColumnValuePair             AS [tmp]
                                               INNER JOIN [dbo].[MFProperty] AS [mfp]
                                                   ON [mfp].[ColumnName] = [tmp].[ColunmName]
                                           WHERE [mfp].[MFID] <> 100
                                                 AND [tmp].[ColumnValue] IS NOT NULL --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                           FOR XML PATH(''), TYPE
                                       ) AS [class]
                                   FOR XML PATH(''), TYPE
                               )              AS [Object]
                        FOR XML PATH(''), ROOT('form')
                    );
                    SET @XMLFile =
                    (
                        SELECT @XMLFile.[query]('/form/*')
                    );
                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                        SELECT @XMLFile;
                    END;

                    SET @ProcedureStep = 'Get Checksum';

                    DECLARE @FileCheckSum NVARCHAR(MAX);

                    IF EXISTS
                    (
                        SELECT TOP 1
                               [FileCheckSum]
                        FROM [dbo].[MFFileImport]
                        WHERE [FileUniqueRef] = @FileID
                              AND [SourceName] = @SourceTableName
                    )
                    BEGIN
                        CREATE TABLE [#TempCheckSum]
                        (
                            [FileCheckSum] NVARCHAR(MAX)
                        );

                        INSERT INTO [#TempCheckSum]
                        SELECT TOP 1
                               ISNULL([FileCheckSum], '')
                        FROM [dbo].[MFFileImport]
                        WHERE [FileUniqueRef] = @FileID
                              AND [SourceName] = @SourceTableName
                        ORDER BY 1 DESC;

                        SELECT *
                        FROM [#TempCheckSum];

                        SELECT @FileCheckSum = ISNULL([FileCheckSum], '')
                        FROM [#TempCheckSum];

                        DROP TABLE [#TempCheckSum];
                    END;
                    ELSE
                    BEGIN
                        SET @FileCheckSum = '';
                    END;

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    SET @ProcedureStep = 'Prepare XML out';
                    SET @Sql = '';
                    SET @Sql
                        = 'select @XMLOut=(  Select ''' + @FileID + ''' as ''FileListItem/@ID'' , ' + @FileNameColumn
                          + ' as ''FileListItem/@FileName'', [' + @FileDataColumn + '] as ''FileListItem/@File'', '
                          + CAST(@TargetClassMFID AS VARCHAR(100)) + ' as ''FileListItem/@ClassId'', '
                          + CAST(@ObjectTypeID AS VARCHAR(10)) + ' as ''FileListItem/@ObjType'',''' + @FileCheckSum
                          + ''' as ''FileListItem/@FileCheckSum'' from ' + @SourceTableName + ' where '
                          + @FileUniqueKeyColumn + '=''' + @FileID + ''' FOR XML PATH('''') , ROOT(''XMLFILE'') )';

                    IF @Debug > 0
                        PRINT @Sql;

                    EXEC [sys].[sp_executesql] @Sql, N'@XMLOut XML OUTPUT', @XMLOut OUTPUT;

                    ;

                    SELECT @XML = CAST(@XMLOut AS NVARCHAR(MAX));

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    -- PRINT @XML;

                    -------------------------------------------------------------------
                    --Getting the Filedata in @Data variable
                    -------------------------------------------------------------------
                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Getting the Filedata in @Data variable';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    DECLARE @Data VARBINARY(MAX);

                    SET @Sql = '';
                    SET @Sql
                        = 'select @Data=[' + @FileDataColumn + ']  from ' + @SourceTableName + ' where '
                          + @FileUniqueKeyColumn + '=''' + @FileID + '''';

                    -- PRINT @Sql;
                    EXEC [sys].[sp_executesql] @Sql
                                              ,N'@Data  varbinary(max) OUTPUT'
                                              ,@Data OUTPUT;;

                    -------------------------------------------------------------------
                    --Importing File into M-Files using Connector
                    -------------------------------------------------------------------
                    SET @ProcedureStep = 'Importing file';

                    DECLARE @XMLStr   NVARCHAR(MAX)
                           ,@Result   NVARCHAR(MAX)
                           ,@ErrorMsg NVARCHAR(MAX);

                    SET @XMLStr = '<form>' + CAST(@XMLFile AS NVARCHAR(MAX)) + '</form>';
                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                        SELECT CAST(@XML AS XML) AS '@XML Length';

                        SELECT @Data AS '@data';

                        SELECT CAST(@XMLStr AS XML) AS '@XMLStr';
						SELECT @FileLocation AS filelocation

                    END;

                    EXEC [dbo].[spMFSynchronizeFileToMFilesInternal] @VaultSettings
                                                                    ,@XML
                                                                    ,@Data
                                                                    ,@XMLStr
                                                                    ,@FileLocation
                                                                    ,@Result OUT
                                                                    ,@ErrorMsg OUT;

                  IF @Debug > 0  
				  Begin
					SELECT CAST(@Result AS XML) AS Result
					SELECT @ErrorMsg AS errormsg
					END
                    
                    IF @ErrorMsg IS NOT NULL
                       AND LEN(@ErrorMsg) > 0
                    BEGIN
                        --  SET @Sql='update '+@MFTableName+' set Process_Id=2 where '+@FileUniqueKeyColumn+'='+@ID
                        SET @Sql
                            = 'update ' + QUOTENAME(@MFTableName) + ' set Process_ID=2 where '
                              + QUOTENAME(@TargetFileUniqueKeycolumnName) + ' =''' + @FileID + '''';

                        --          PRINT @Sql;
                        EXEC (@Sql);
                    END;

                    SET @DebugText = '';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Insert result in MFFileImport table';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    DECLARE @ResultXml XML;

                    SET @ResultXml = CAST(@Result AS XML);

                    CREATE TABLE [#TempFileDetails]
                    (
                        [FileName] NVARCHAR(200)
                       ,[FileUniqueRef] VARCHAR(100)
                       ,[MFCreated] DATETIME
                       ,[MFLastModified] DATETIME
                       ,[ObjID] INT
                       ,[ObjVer] INT
                       ,[FileObjectID] INT
                       ,[FileCheckSum] NVARCHAR(MAX)
                    );

                    INSERT INTO [#TempFileDetails]
                    (
                        [FileName]
                       ,[FileUniqueRef]
                       ,[MFCreated]
                       ,[MFLastModified]
                       ,[ObjID]
                       ,[ObjVer]
                       ,[FileObjectID]
                       ,[FileCheckSum]
                    )
                    SELECT [t].[c].[value]('(@FileName)[1]', 'NVARCHAR(200)')     AS [FileName]
                          ,[t].[c].[value]('(@FileUniqueRef)[1]', 'VARCHAR(100)') AS [FileUniqueRef]
                          ,[t].[c].[value]('(@MFCreated)[1]', 'DATETIME')         AS [MFCreated]
                          ,[t].[c].[value]('(@MFLastModified)[1]', 'DATETIME')    AS [MFLastModified]
                          ,[t].[c].[value]('(@ObjID)[1]', 'INT')                  AS [ObjID]
                          ,[t].[c].[value]('(@ObjVer)[1]', 'INT')                 AS [ObjVer]
                          ,[t].[c].[value]('(@FileObjectID)[1]', 'INT')           AS [FileObjectID]
                          ,[t].[c].[value]('(@FileCheckSum)[1]', 'NVARCHAR(MAX)') AS [FileCheckSum]
                    FROM @ResultXml.[nodes]('/form/Object') AS [t]([c]);

                    IF EXISTS
                    (
                        SELECT TOP 1
                               *
                        FROM [dbo].[MFFileImport]
                        WHERE [FileUniqueRef] = @FileID
                              AND [TargetClassID] = @TargetClassMFID
                    )
                    BEGIN
                        UPDATE [FI]
                        SET [FI].[MFCreated] = [FD].[MFCreated]
                           ,[FI].[MFLastModified] = [FD].[MFLastModified]
                           ,[FI].[ObjID] = [FD].[ObjID]
                           ,[FI].[Version] = [FD].[ObjVer]
                           ,[FI].[FileObjectID] = [FD].[FileObjectID]
                           ,[FI].[FileCheckSum] = [FD].[FileCheckSum]
                        FROM [dbo].[MFFileImport]         [FI]
                            INNER JOIN [#TempFileDetails] [FD]
                                ON [FI].[FileUniqueRef] = [FD].[FileUniqueRef];
                    END;
                    ELSE
                    BEGIN
                        INSERT INTO [dbo].[MFFileImport]
                        (
                            [FileName]
                           ,[FileUniqueRef]
                           ,[CreatedOn]
                           ,[SourceName]
                           ,[TargetClassID]
                           ,[MFCreated]
                           ,[MFLastModified]
                           ,[ObjID]
                           ,[Version]
                           ,[FileObjectID]
                           ,[FileCheckSum]
                        )
                        SELECT [FileName]
                              ,[FileUniqueRef]
                              ,GETDATE()
                              ,@SourceTableName
                              ,@TargetClassMFID
                              ,[MFCreated]
                              ,[MFLastModified]
                              ,[ObjID]
                              ,[ObjVer] 
                              ,[FileObjectID]
                              ,[FileCheckSum]
                        FROM [#TempFileDetails];
                    END;

                    DROP TABLE [#TempFileDetails];

					END --end filename exist
					ELSE 
					BEGIN
                    Set @DebugText = 'UniqueID %s'
                    Set @DebugText = @DefaultDebugText + @DebugText
                    Set @Procedurestep = 'Filename missing'

                    RAISERROR(@DebugText,16,1,@ProcedureName,@ProcedureStep,@FileID );

					END -- Else end


                    SET @Sql = N'
                    Select @Counter = (SELECT MIN(RowID) FROM ' + @TempFile + ' WHERE Rowid > @Counter);';

                    EXEC [sys].[sp_executesql] @Sql, N'@Counter int output', @Counter OUTPUT;
                END; -- end loop

                SELECT @tempTableName = 'tempdb..' + @TempFile;

                IF
                (
                    SELECT OBJECT_ID(@tempTableName)
                ) IS NOT NULL
                    EXEC ('Drop table ' + @TempFile);

                SET @Sql = ' Synchronizing records  from M-files to the target ' + @MFTableName;

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
                                                                             ,@debug = 0;

                -------------------------------------------------------------------
                --Synchronizing target table from M-Files
                -------------------------------------------------------------------
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Synchronizing target table from M-Files';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SET @Sql
                    = 'Update ' + @MFTableName + ' set Process_ID=0 where Process_ID= '
                      + CAST(@Process_ID AS VARCHAR(5));;

                --           PRINT @Sql;
                EXEC (@Sql);

				DECLARE @Return_LastModified DATETIME

                EXEC [dbo].[spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1                                  -- int
                                                                ,@Return_LastModified = @Return_LastModified OUTPUT -- datetime
                                                                ,@TableName = @MFTableName                          -- sysname
                                                                ,@Update_IDOut = @Update_IDOut OUTPUT               -- int
                                                                ,@ProcessBatch_ID = @ProcessBatch_id         -- int
                                                                ,@debug = 0;                                        -- smallint
            END;
            ELSE
            BEGIN
                SET @DebugText = 'File unique column name does not belongs to the table';
                SET @DebugText = @DefaultDebugText + @DebugText;

                RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;
        END;
        ELSE
        BEGIN
            SET @DebugText = 'Target Table ' + @MFTableName + ' does not belong to MFClass table';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;
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
                                            ,@debug = 0;

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
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].spMFClassTableColumns';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFClassTableColumns'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.47'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  2019-1-19		LC			Change datatype from bit to smallint for error columns
  ********************************************************************************
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFClassTableColumns' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFClassTableColumns]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFClassTableColumns] 
AS
BEGIN
    SET NOCOUNT ON;

    IF
    (
        SELECT ISNULL(OBJECT_ID('tempdb..##spMFClassTableColumns'), 0)
    ) > 0
        DROP TABLE [##spMFClassTableColumns];



    --SELECT * FROM [dbo].[MFvwClassTableColumns] AS [mfctc]
    DECLARE @IsUpToDate BIT;

    EXEC [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

    IF @IsUpToDate = 0
    BEGIN
        EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'Property'; -- varchar(100)

        EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'Class'; -- varchar(100)
    END;

    CREATE TABLE [##spMFClassTableColumns]
    (
        [id] INT IDENTITY
       ,[ColumnType] NVARCHAR(100)
       ,[Class] NVARCHAR(200)
       ,[TableName] NVARCHAR(200)
       ,[Property] NVARCHAR(100)
       ,[Property_MFID] INT
       ,[columnName] NVARCHAR(100)
       ,[AdditionalProperty] BIT
       ,[IncludedInApp] BIT
       ,[Required] BIT
       ,[LookupType] NVARCHAR(100)
       ,[MFdataType_ID] INT
       ,[MFDataType] NVARCHAR(100)
       ,[column_DataType] NVARCHAR(100)
       ,[length] INT
       ,[ColumnDataTypeError] smallint
       ,[MissingColumn] smallint
       ,[MissingTable] smallint
       ,[RedundantTable] smallint
    );

    INSERT INTO [##spMFClassTableColumns]
    (
        [Property]
       ,[Property_MFID]
       ,[columnName]
       ,[Class]
       ,[TableName]
       ,[IncludedInApp]
       ,[Required]
       ,[LookupType]
       ,[MFdataType_ID]
       ,[MFDataType]
       ,[AdditionalProperty]
    )
    SELECT [mp2].[Name] [property]
          ,[mp2].[MFID]
          ,[mp2].[ColumnName]
          ,[mc2].[Name] AS [class]
          ,[mc2].[TableName]
          ,[mc2].[IncludeInApp]
          ,[mcp2].[Required]
          ,CASE
               WHEN [mvl].[RealObjectType] = 1
                    AND [mdt].[MFTypeID] IN ( 9, 10 ) THEN
                   'ClassTable_' + [mvl].[Name]
               WHEN [mvl].[RealObjectType] = 0
                    AND [mvl].[Name] NOT IN ( 'class', 'Workflow', 'Workflow State' )
                    AND [mdt].[MFTypeID] IN ( 9, 10 ) THEN
                   'Table_MFValuelist_' + [mvl].[Name]
           END
          ,[mdt].[MFTypeID]
          ,[mdt].[Name]
          ,0
    --select *
    FROM [dbo].[MFProperty]                AS [mp2]
        INNER JOIN [dbo].[MFClassProperty] AS [mcp2]
            ON [mcp2].[MFProperty_ID] = [mp2].[ID]
        INNER JOIN [dbo].[MFClass]         AS [mc2]
            ON [mc2].[ID] = [mcp2].[MFClass_ID]
        INNER JOIN [dbo].[MFDataType]      AS [mdt]
            ON [mdt].[ID] = [mp2].[MFDataType_ID]
        INNER JOIN [dbo].[MFValueList]     AS [mvl]
            ON [mvl].[ID] = [mp2].[MFValueList_ID]
    --		WHERE mc2.name = 'Customer';
    ;

    MERGE INTO [##spMFClassTableColumns] [t]
    USING
    (
        SELECT [sc].[name]         AS [ColumnName]
              ,[sc].[max_length]   AS [length]
              ,[sc].[is_nullable]
              ,[st].[name]         AS [TableName]
              ,[t].[name]          AS [Column_DataType]
              ,[mc].[Name]         AS [class]
              ,[mc].[IncludeInApp] AS [IncludedInApp]
        FROM [sys].[columns]           [sc]
            INNER JOIN [sys].[tables]  [st]
                ON [st].[object_id] = [sc].[object_id]
            INNER JOIN [dbo].[MFClass] AS [mc]
                ON [mc].[TableName] = [st].[name]
            INNER JOIN [sys].[types]   AS [t]
                ON [sc].[user_type_id] = [t].[user_type_id]
    ) [s]
    ON [s].[ColumnName] = [t].[ColumnName]
       AND [s].[TableName] = [t].[TableName]
    WHEN MATCHED THEN
        UPDATE SET [t].[Column_Datatype] = [s].[Column_DataType]
                  ,[t].[Length] = [s].[length]
                  ,[t].[IncludedInApp] = [s].[IncludedInApp]
    WHEN NOT MATCHED THEN
        INSERT
        (
            [TableName]
           ,[ColumnName]
           ,[Column_DataType]
           ,[length]
           ,[class]
           ,[IncludedInApp]
        )
        VALUES
        ([s].[TableName], [s].[ColumnName], [s].[Column_DataType], [s].[length], [s].[class], [s].[IncludedInApp]);

    UPDATE [##spMFClassTableColumns]
    SET [Property] = [mp].[Name]
       ,[Property_MFID] = [mp].[MFID]
       ,[MFdataType_ID] = [mdt].[MFTypeID]
       ,[MFDataType] = [mdt].[Name]
       ,[Required] = 0
    ,[LookupType] = CASE
                           WHEN [mp].[MFID] = 100 THEN
                               'Table_MFClass'
                           WHEN [mp].[MFID] = 38 THEN
                               'Table_MFWorkflow'
                           WHEN [mp].[MFID] = 39 THEN
                               'Table_MFWorkflowState'
							  END
		
	FROM [##spMFClassTableColumns]    AS [pc]
        INNER JOIN [dbo].[MFProperty] AS [mp]
            ON [pc].[columnName] = [mp].[ColumnName]
        INNER JOIN [dbo].[MFDataType] [mdt]
            ON [mp].[MFDataType_ID] = [mdt].[ID]
    WHERE [pc].[Property] IS NULL;

    UPDATE [##spMFClassTableColumns]
    SET [AdditionalProperty] = CASE
                                   WHEN [pc].[Property] IN ( 'GUID', 'Objid', 'MFVersion', 'ExternalID' ) THEN
                                       0
                                   WHEN [pc].[columnName] IN ( 'ID', 'Process_id', 'Lastmodified', 'FileCount'
                                                              ,'Deleted', 'Update_ID'
                                                             ) THEN
                                       0
                                   WHEN SUBSTRING([pc].[columnName], 1, 2) = 'MX' THEN
                                       0
                                   WHEN [pc].[Property_MFID] > 101
                                        AND [pc].[AdditionalProperty] IS NULL THEN
                                       1
                               END
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[AdditionalProperty] IS NULL;

    UPDATE [##spMFClassTableColumns]
    SET [MissingColumn] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[IncludedInApp] IS NOT NULL
          AND [pc].[column_DataType] IS NULL;

    UPDATE [##spMFClassTableColumns]
    SET [RedundantTable] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[IncludedInApp] IS NULL
          AND [pc].[column_DataType] IS NOT NULL;

    UPDATE [##spMFClassTableColumns]
    SET [MissingTable] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[IncludedInApp] IS NOT NULL
          AND [pc].[column_DataType] IS NULL
          AND [pc].[MissingColumn] IS NULL;

    UPDATE [##spMFClassTableColumns]
    SET [ColumnDataTypeError] = 1
    FROM [##spMFClassTableColumns] AS [pc]
    WHERE [pc].[MFdataType_ID] in (10,13)
          AND [pc].[length] <> 8000
          AND [pc].[IncludedInApp] IS NOT NULL;

    UPDATE [##spMFClassTableColumns]
    SET [ColumnType] = CASE
                           WHEN [IncludedInApp] IS NULL
                                AND [column_DataType] IS NULL THEN
                               'Not used'
                           WHEN [Property_MFID] > 100
                                AND [AdditionalProperty] = 0 THEN
                               'Metadata Card Property'
                           WHEN [AdditionalProperty] = 1 THEN
                               'Additional Property'
                           WHEN [Property_MFID] < 101 THEN
                               'MFSystem Property'
                           WHEN [columnName] IN ( 'GUID', 'Objid', 'MFVersion', 'ExternalID' ) THEN
                               'MFSystem Property'
                           WHEN [columnName] IN ( 'ID', 'Process_id', 'Lastmodified', 'FileCount', 'Deleted'
                                                 ,'Update_ID'
                                                ) THEN
                               'MFSQL System Property'
                           WHEN SUBSTRING([columnName], 1, 2) = 'MX' THEN
                               'Excluded from MF'
                           WHEN [Property] IS NULL
                                AND [IncludedInApp] = 1
                                AND [ColumnType] IS NULL THEN
                               'Lookup Lable Column'
                       END;

--SELECT *
--FROM [##spMFClassTableColumns] AS [pc]
--WHERE [pc].[TableName] = @TableName
--      OR @TableName IS NULL
--ORDER BY [pc].[TableName]
--        ,[pc].[columnName];
END;
GO
