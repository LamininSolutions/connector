PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeFilesToMFiles]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeFilesToMFiles',
    -- nvarchar(100)
    @Object_Release = '4.10.30.74',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO


IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSynchronizeFilesToMFiles' --name of procedure
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
CREATE PROCEDURE dbo.spMFSynchronizeFilesToMFiles
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFSynchronizeFilesToMFiles
    @SourceTableName NVARCHAR(100),
    @FileUniqueKeyColumn NVARCHAR(100),
    @FileNameColumn NVARCHAR(100),
    @FileDataColumn NVARCHAR(100),
    @MFTableName NVARCHAR(100),
    @TargetFileUniqueKeycolumnName NVARCHAR(100) = 'MFSQL_Unique_File_Ref',
    @BatchSize INT = 500,
    @Process_ID INT = 5,
    @RetainDeletions BIT = 0,
    @IsDocumentCollection BIT = 0,
    @ProcessBatch_id INT = NULL OUTPUT,
    @Debug INT = 0
AS
/*rST**************************************************************************

============================
spMFSynchronizeFilesToMFiles
============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @SourceTableName nvarchar(100)
    Name of source table
  @FileUniqueKeyColumn nvarchar(100)
    column with unique key to reference file
  @FileNameColumn nvarchar(100)
    column name for file name
  @FileDataColumn nvarchar(100)
    column referencing the file content
  @MFTableName nvarchar(100)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @TargetFileUniqueKeycolumnName nvarchar(100)
    property name of unique key in MF
  @BatchSize int
    set manage import in batches
  @Process\_ID int
    process id for referencing the objects in the class table
  @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
  @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
  @ProcessBatch\_id int (output)
    Process batch for the logging
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode


Purpose
=======

Procedure to synchronize files from a table to M-Files

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-01-10  LC         Fix bug with file import using GUID as unique ref; improve logging messages
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
   
    BEGIN TRY
        SET NOCOUNT ON;

        -----------------------------------------------------
        --DECLARE VARIABLES FOR LOGGING
        -----------------------------------------------------
        --used on MFProcessBatchDetail;
        DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
        DECLARE @DebugText AS NVARCHAR(256) = N'';
        DECLARE @LogTypeDetail AS NVARCHAR(MAX) = N'';
        DECLARE @LogTextDetail AS NVARCHAR(MAX) = N'';
        DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = N'';
        DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
        DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
        DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
        DECLARE @ProcessType NVARCHAR(50) = N'Object History';
        DECLARE @LogType AS NVARCHAR(50) = N'Status';
        DECLARE @LogText AS NVARCHAR(4000) = N'Get History Initiated';
        DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
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
            @Username  = Username,
            @VaultName = VaultName
        FROM dbo.MFVaultSettings;

        INSERT INTO dbo.MFUpdateHistory
        (
            Username,
            VaultName,
            UpdateMethod
        )
        VALUES
        (@Username, @VaultName, -1);

        SELECT @Update_ID = @@Identity;

        SELECT @Update_IDOut = @Update_ID;

        SET @ProcessType = N'Import Files';
        SET @LogText = N' Started ';
        SET @LogStatus = N'Initiate';
        SET @StartTime = GETUTCDATE();
        SET @LogTypeDetail = N'Debug';
        SET @LogStatusDetail = N'In Progress';

        EXECUTE @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = @LogType,
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = 0;

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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
            @debug = 0;

        SET @DebugText = N'';
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
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF EXISTS (SELECT TOP 1 * FROM dbo.MFClass WHERE TableName = @MFTableName)
        BEGIN
            SET @LogTextDetail = @MFTableName + N' is present in the MFClass table';

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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
                @debug = 0;

            SELECT @TargetClassMFID = MC.MFID,
                @ObjectTypeID       = OT.MFID
            FROM dbo.MFClass                MC
                INNER JOIN dbo.MFObjectType OT
                    ON MC.MFObjectType_ID = OT.ID
            WHERE MC.TableName = @MFTableName;

            SET @ProcedureStep = 'Checking File unique key property ';
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            IF EXISTS
            (
                SELECT *
                FROM INFORMATION_SCHEMA.COLUMNS C
                WHERE C.TABLE_NAME = @MFTableName
                      AND C.COLUMN_NAME = @TargetFileUniqueKeycolumnName
            )
            BEGIN
                SET @LogTextDetail
                    = @TargetFileUniqueKeycolumnName + N' is present in the Target class ' + @MFTableName;

                EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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
                    @debug = 0;

                ------------------------------------------------
                --Getting Vault Settings
                ------------------------------------------------
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Getting Vault credentials ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @VaultSettings = dbo.FnMFVaultSettings();

                -------------------------------------------------------------
                -- Validate unique reference
                -------------------------------------------------------------
                SET @ProcedureStep = 'Duplicate unique ref count  ';
                SET @rowcount = NULL;
                SET @Params = N'@rowCount int output';
                SET @Sql = N'	
SELECT @Rowcount = COUNT(*) FROM ' + QUOTENAME(@MFTableName) + N'
where ' +       QUOTENAME(@TargetFileUniqueKeycolumnName) + N' is not null 
GROUP BY ' +    QUOTENAME(@TargetFileUniqueKeycolumnName) + N' HAVING COUNT(*) > 1';

                EXEC sys.sp_executesql @stmt = @Sql,
                    @param = @Params,
                    @rowcount = @rowcount OUTPUT;

                --IF @Debug > 0
                --    PRINT @Sql;
                SELECT @rowcount = ISNULL(@rowcount, 0);

                SET @DebugText = N'Duplicate Rows: %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                END;

                IF @rowcount > 0
                BEGIN
                    SET @DebugText = N'Unique Ref has duplicate items - not allowed ';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Validate Unique File reference ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                    END;

                    SET @LogTextDetail = @DebugText;
                    SET @LogTypeDetail = N'Error';
                    SET @LogStatusDetail = N'Error';

                    EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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
                        @debug = 0;
                END;

                ------------------------------------------------
                --Getting Temp File location to store File
                ------------------------------------------------
                SELECT @FileLocation = ISNULL(CAST(Value AS NVARCHAR(200)), 'Invalid location')
                FROM dbo.MFSettings
                WHERE source_key = 'Files_Default'
                      AND Name = 'FileTransferLocation';

                SET @DebugText = N' ' + @FileLocation;
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

                SELECT @TempFile = '##' + dbo.fnMFVariableTableName('InsertFiles', '');

                SET @DebugText = N'Tempfile %s';
                SET @DebugText = @DefaultDebugText + @DebugText;

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
                    = N' Select * into ' + @TempFile + N' From (select top ' + CAST(@BatchSize AS VARCHAR(10))
                      + N' TN.ID as RowID, SR.' + @FileUniqueKeyColumn + N' as FileUniqueID, '+@FileNameColumn+' as Filename from ' + @SourceTableName
                      + N' SR inner join ' + @MFTableName + N' TN on SR.' + @FileUniqueKeyColumn + N'=TN.'
                      + @TargetFileUniqueKeycolumnName + N' and TN.Process_ID= ' + CAST(@Process_ID AS VARCHAR(5))
                      + N')list;';

                IF @Debug > 0
                    PRINT @Sql;

                EXEC sys.sp_executesql @Stmt = @Sql;

                IF @Debug > 0
                BEGIN
                    EXEC (N'Select Count(*) as FileCount from ' + @TempFile);
                END;

                SET @DebugText = N'TempFile: %s';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TempFile);
                END;

                SET @LogTextDetail = N'Records insert in Temp file';
                SET @LogColumnName = @TempFile;
                SET @LogColumnValue = CAST(@BatchSize AS VARCHAR(10));

                EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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
                    @debug = 0;

                SET @Params = N'@RowID int output';
                SET @Sql = N'
                SELECT @RowID = Min([RowID])
                FROM ' + @TempFile;

                EXEC sys.sp_executesql @Stmt = @Sql,
                    @param = @Params,
                    @RowID = @Counter OUTPUT;

                SET @DebugText = N'  Min RowID %i';
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
                    DECLARE @XMLOut    XML,
                        @SqlID         INT,
                        @ObjId         INT,
                        @ObjectVersion INT;

                    SET @ProcedureStep = 'Get latest version';
                    SET @Params = N'@ObjIDs nvarchar(4000) output, @Counter int';
                    SET @Sql
                        = N'Select @ObjIDs = CAST(Objid AS VARCHAR(4000)) FROM ' + QUOTENAME(@MFTableName)
                          + ' WHERE ID = @Counter';

                    EXEC sys.sp_executesql @Sql, @Params, @ObjIDs OUTPUT, @Counter;

                    SET @DebugText = N' Objids %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Get Objids for update';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDs);
                    END;

                    SET @Params = N'@Objids nvarchar(4000)';
                    SET @Sql
                        = N'UPDATE ' + QUOTENAME(@MFTableName)
                          + ' SET [Process_ID] = 0 WHERE objid = CAST(@Objids AS int)';

                    EXEC sys.sp_executesql @Sql, @Params, @ObjIDs;

                    EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName, -- nvarchar(200)
                        @UpdateMethod = 1,                                -- int                          
                        @ObjIDs = @ObjIDs,                                -- nvarchar(max)
                        @Update_IDOut = @Update_IDOut OUTPUT,             -- int
                        @ProcessBatch_ID = @ProcessBatch_id,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection;


                    SET @Params = N'@Process_ID int, @Objids nvarchar(4000)';
                    SET @Sql
                        = N'UPDATE ' + QUOTENAME(@MFTableName)
                          + ' SET [Process_ID] = @Process_ID WHERE objid = CAST(@Objids AS int)';

                    EXEC sys.sp_executesql @Sql, @Params, @Process_ID, @ObjIDs;

                    SET @ProcedureStep = 'Get uniqueID';
                    SET @Params = N'@FileID nvarchar(250) output, @Counter int';
                    SET @Sql = N'SELECT @FileID = [FileUniqueID] FROM ' + @TempFile + N' WHERE [RowID] = @Counter;';

                    EXEC sys.sp_executesql @Sql, @Params, @FileID OUTPUT, @Counter;

                    SET @DebugText = N' FileID: %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @FileID);
                    END;

                    SET @ProcedureStep = 'Get object Details';
                    SET @Params
                        = N'@SQLID int OUTPUT,@ObjId  INT OUTPUT,@ObjectVersion  INT OUTPUT,@FileID nvarchar(250)';
                    SET @Sql
                        = N'select @SqlID=ID,@ObjId=ObjID,@ObjectVersion=MFVersion  from ' + @MFTableName + N' where '
                          + @TargetFileUniqueKeycolumnName + N'= ''' + @FileID + N'''';

                    IF @Debug > 0
                        PRINT @Sql;

                    EXEC sys.sp_executesql @stmt = @Sql,
                        @param = @Params,
                        @SQLID = @SqlID OUTPUT,
                        @ObjId = @ObjId OUTPUT,
                        @ObjectVersion = @ObjectVersion OUTPUT,
                        @FileID = @FileID;

                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    -------------------------------------------------------------
                    -- Validate file data  (filename not null)
                    -------------------------------------------------------------
                    DECLARE @FileNameExist NVARCHAR(250);

                    SET @Params = '@FileNameExist nvarchar(250) output, @Counter int';
                    SET @Sql
                        = N'
					SELECT @FileNameExist = ' + QUOTENAME(@FileNameColumn) + ' FROM ' + @SourceTableName
                          + ' S
					INNER JOIN ' + @TempFile + ' t
					ON s.' + @FileUniqueKeyColumn + ' = t.FileUniqueID
					WHERE t.RowID = @Counter;';

                    IF @Debug > 0
                        PRINT @Sql;

                    EXEC sys.sp_executesql @Sql, @Params, @FileNameExist OUTPUT, @Counter;

                    IF ISNULL(@FileNameExist, '') <> ''
                    BEGIN

                        -----------------------------------------------------
                        --Creating the xml 
                        ----------------------------------------------------
                        DECLARE @Query NVARCHAR(MAX);

                        SET @ProcedureStep = 'Prepare ColumnValue pair';

                        DECLARE @ColumnValuePair TABLE
                        (
                            ColunmName NVARCHAR(200),
                            ColumnValue NVARCHAR(4000),
                            Required BIT ---Added for checking Required property for table
                        );

                        DECLARE @TableWhereClause VARCHAR(1000),
                            @tempTableName        VARCHAR(1000),
                            @XMLFile              XML;

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
                                  SELECT ' UNION ' + 'SELECT ''' + COLUMN_NAME + ''' as name, CONVERT(VARCHAR(max),['
                                         + COLUMN_NAME + ']) as value, 0  as Required FROM [' + @MFTableName + '] y'
                                         + ISNULL('  WHERE ' + @TableWhereClause, '')
                                  FROM INFORMATION_SCHEMA.COLUMNS
                                  WHERE TABLE_NAME = @MFTableName
                                  FOR XML PATH('')
                              ),
                                       1,
                                       7,
                                       ''
                                   );

                        IF @Debug > 0
                            PRINT @Query;

                        SET @DebugText = N'';
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
                            ColumnName VARCHAR(100)
                        );

                        INSERT INTO @ExcludeList
                        (
                            ColumnName
                        )
                        SELECT mp.ColumnName
                        FROM dbo.MFProperty AS mp
                        WHERE mp.MFID IN ( 20, 21, 23, 25 );

                        --Last Modified, Last Modified by, Created, Created by

                        -----------------------------------------------------
                        --Insert to values INTo temp table
                        -----------------------------------------------------
                        --               PRINT @Query;
                        SET @ProcedureStep = 'Execute query';

                        DELETE FROM @ColumnValuePair;

                        --IF @Debug > 0
                        --SELECT * FROM @ColumnValuePair AS [cvp];
                        INSERT INTO @ColumnValuePair
                        EXEC (@Query);

                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                            SELECT *
                            FROM @ColumnValuePair AS cvp;
                        END;

                        SET @ProcedureStep = 'Remove exclusions';

                        DELETE FROM @ColumnValuePair
                        WHERE ColunmName IN
                              (
                                  SELECT el.ColumnName FROM @ExcludeList AS el
                              );

                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;

                        --SELECT *
                        --FROM @ColumnValuePair;

                        ----------------------	 Add for checking Required property--------------------------------------------
                        SET @ProcedureStep = 'Check for required properties';

                        UPDATE CVP
                        SET CVP.Required = CP.Required
                        FROM @ColumnValuePair              CVP
                            INNER JOIN dbo.MFProperty      P
                                ON CVP.ColunmName = P.ColumnName
                            INNER JOIN dbo.MFClassProperty CP
                                ON P.ID = CP.MFProperty_ID
                            INNER JOIN dbo.MFClass         C
                                ON CP.MFClass_ID = C.ID
                        WHERE C.TableName = @MFTableName;

                        UPDATE @ColumnValuePair
                        SET ColumnValue = 'ZZZ'
                        WHERE Required = 1
                              AND ColumnValue IS NULL;

                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;

                        ------------------	 Add for checking Required property------------------------------------
                        SET @ProcedureStep = 'Convert datatime';

                        --DELETE FROM @ColumnValuePair
                        --WHERE  ColumnValue IS NULL
                        UPDATE cp
                        SET cp.ColumnValue = CONVERT(DATE, CAST(cp.ColumnValue AS NVARCHAR(100)))
                        FROM @ColumnValuePair                     AS cp
                            INNER JOIN INFORMATION_SCHEMA.COLUMNS AS c
                                ON c.COLUMN_NAME = cp.ColunmName
                        WHERE c.DATA_TYPE = 'datetime'
                              AND cp.ColumnValue IS NOT NULL;

                        SET @DebugText = N'';
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
                            SELECT @ObjectTypeID AS [Object/@id],
                                @SqlID           AS [Object/@sqlID],
                                @ObjId           AS [Object/@objID],
                                @ObjectVersion   AS [Object/@objVesrion],
                                0                AS [Object/@DisplayID],
                                (
                                    SELECT
                                        (
                                            SELECT TOP 1
                                                tmp.ColumnValue
                                            FROM @ColumnValuePair         AS tmp
                                                INNER JOIN dbo.MFProperty AS mfp
                                                    ON mfp.ColumnName = tmp.ColunmName
                                            WHERE mfp.MFID = 100
                                        ) AS [class/@id],
                                        (
                                            SELECT mfp.MFID AS [property/@id],
                                                (
                                                    SELECT MFTypeID FROM dbo.MFDataType WHERE ID = mfp.MFDataType_ID
                                                )           AS [property/@dataType],
                                                CASE
                                                    WHEN tmp.ColumnValue = 'ZZZ' THEN
                                                        NULL
                                                    ELSE
                                                        tmp.ColumnValue
                                                END         AS 'property' ----Added case statement for checking Required property
                                            FROM @ColumnValuePair         AS tmp
                                                INNER JOIN dbo.MFProperty AS mfp
                                                    ON mfp.ColumnName = tmp.ColunmName
                                            WHERE mfp.MFID <> 100
                                                  AND tmp.ColumnValue IS NOT NULL --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                            FOR XML PATH(''), TYPE
                                        ) AS class
                                    FOR XML PATH(''), TYPE
                                )                AS Object
                            FOR XML PATH(''), ROOT('form')
                        );
                        SET @XMLFile =
                        (
                            SELECT @XMLFile.query('/form/*')
                        );
                        SET @DebugText = N'';
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
                                FileCheckSum
                            FROM dbo.MFFileImport
                            WHERE FileUniqueRef = @FileID
                                  AND SourceName = @SourceTableName
                        )
                        BEGIN
                            CREATE TABLE #TempCheckSum
                            (
                                FileCheckSum NVARCHAR(MAX)
                            );

                            INSERT INTO #TempCheckSum
                            SELECT TOP 1
                                ISNULL(FileCheckSum, '')
                            FROM dbo.MFFileImport
                            WHERE FileUniqueRef = @FileID
                                  AND SourceName = @SourceTableName
                            ORDER BY 1 DESC;

                            SELECT *
                            FROM #TempCheckSum;

                            SELECT @FileCheckSum = ISNULL(FileCheckSum, '')
                            FROM #TempCheckSum;

                            DROP TABLE #TempCheckSum;
                        END;
                        ELSE
                        BEGIN
                            SET @FileCheckSum = N'';
                        END;

                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;

                        SET @ProcedureStep = 'Prepare XML out';
                        SET @Sql = N'';
                        SET @Sql
                            = N'select @XMLOut=(  Select ''' + @FileID + N''' as ''FileListItem/@ID'' , '
                              + @FileNameColumn + N' as ''FileListItem/@FileName'', [' + @FileDataColumn
                              + N'] as ''FileListItem/@File'', ' + CAST(@TargetClassMFID AS VARCHAR(100))
                              + N' as ''FileListItem/@ClassId'', ' + CAST(@ObjectTypeID AS VARCHAR(10))
                              + N' as ''FileListItem/@ObjType'',''' + @FileCheckSum
                              + N''' as ''FileListItem/@FileCheckSum'' from ' + @SourceTableName + N' where '
                              + @FileUniqueKeyColumn + N'=''' + @FileID
                              + N''' FOR XML PATH('''') , ROOT(''XMLFILE'') )';

                        IF @Debug > 0
                            PRINT @Sql;

                        EXEC sys.sp_executesql @Sql, N'@XMLOut XML OUTPUT', @XMLOut OUTPUT;

                        ;

                        SELECT @XML = CAST(@XMLOut AS NVARCHAR(MAX));

                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;

                        -- PRINT @XML;

                        -------------------------------------------------------------------
                        --Getting the Filedata in @Data variable
                        -------------------------------------------------------------------
                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;
                        SET @ProcedureStep = 'Getting the Filedata in @Data variable';

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;

                        DECLARE @Data VARBINARY(MAX);
                        DECLARE @Filename NVARCHAR(255);


                        SET @Sql = N'';
                        SET @Sql
                            = N'select @Data=[' + @FileDataColumn + N'], @Filename=[' + @FileNameColumn + N']  from '
                              + @SourceTableName + N' where ' + @FileUniqueKeyColumn + N'=''' + @FileID + N'''';

                        -- PRINT @Sql;
                        EXEC sys.sp_executesql @Sql,
                            N'@Data  varbinary(max) OUTPUT, @FileName nvarchar(255) output',
                            @Data OUTPUT,
                            @Filename OUTPUT;;

                        -------------------------------------------------------------------
                        --Importing File into M-Files using Connector
                        -------------------------------------------------------------------
                        SET @ProcedureStep = 'Importing file';

                        DECLARE @XMLStr NVARCHAR(MAX),
                            @Result     NVARCHAR(MAX),
                            @ErrorMsg   NVARCHAR(MAX);

                        SET @XMLStr = N'<form>' + CAST(@XMLFile AS NVARCHAR(MAX)) + N'</form>';
                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                            SELECT CAST(@XML AS XML) AS '@XML Length';

                            SELECT @Data  AS '@data',
                                @Filename AS '@Filename';

                            SELECT CAST(@XMLStr AS XML) AS '@XMLStr';

                            SELECT @FileLocation AS filelocation;
                        END;

                        EXEC dbo.spMFSynchronizeFileToMFilesInternal @VaultSettings = @VaultSettings,
                            @FileName = @Filename,
                            @XMLFile = @XMLStr,           -- nvarchar(max)
                            @FilePath = @FileLocation,    -- nvarchar(max)
                            @Result = @Result OUTPUT,     -- nvarchar(max)
                            @ErrorMsg = @ErrorMsg OUTPUT, -- nvarchar(max)
                            @IsFileDelete = 0;            -- int

                        IF @Debug > 0
                        BEGIN
                            SELECT CAST(@Result AS XML) AS Result;

                            SELECT @ErrorMsg AS errormsg;
                        END;

                        IF @ErrorMsg IS NOT NULL
                           AND LEN(@ErrorMsg) > 0
                        BEGIN
                            --  SET @Sql='update '+@MFTableName+' set Process_Id=2 where '+@FileUniqueKeyColumn+'='+@ID
                            SET @Sql
                                = N'update ' + QUOTENAME(@MFTableName) + N' set Process_ID=2 where '
                                  + QUOTENAME(@TargetFileUniqueKeycolumnName) + N' =''' + @FileID + N'''';

                            --          PRINT @Sql;
                            EXEC (@Sql);
                        END;

                        SET @DebugText = N'';
                        SET @DebugText = @DefaultDebugText + @DebugText;
                        SET @ProcedureStep = 'Insert result in MFFileImport table';

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                        END;

                        DECLARE @ResultXml XML;

                        SET @ResultXml = CAST(@Result AS XML);

                        CREATE TABLE #TempFileDetails
                        (
                            FileName NVARCHAR(200),
                            FileUniqueRef VARCHAR(100),
                            MFCreated DATETIME,
                            MFLastModified DATETIME,
                            ObjID INT,
                            ObjVer INT,
                            FileObjectID INT,
                            FileCheckSum NVARCHAR(MAX)
                        );

                        INSERT INTO #TempFileDetails
                        (
                            FileName,
                            FileUniqueRef,
                            MFCreated,
                            MFLastModified,
                            ObjID,
                            ObjVer,
                            FileObjectID,
                            FileCheckSum
                        )
                        SELECT t.c.value('(@FileName)[1]', 'NVARCHAR(200)')  AS FileName,
                            t.c.value('(@FileUniqueRef)[1]', 'VARCHAR(100)') AS FileUniqueRef,
                            t.c.value('(@MFCreated)[1]', 'DATETIME')         AS MFCreated,
                            t.c.value('(@MFLastModified)[1]', 'DATETIME')    AS MFLastModified,
                            t.c.value('(@ObjID)[1]', 'INT')                  AS ObjID,
                            t.c.value('(@ObjVer)[1]', 'INT')                 AS ObjVer,
                            t.c.value('(@FileObjectID)[1]', 'INT')           AS FileObjectID,
                            t.c.value('(@FileCheckSum)[1]', 'NVARCHAR(MAX)') AS FileCheckSum
                        FROM @ResultXml.nodes('/form/Object') AS t(c);

                        IF EXISTS
                        (
                            SELECT TOP 1
                                *
                            FROM dbo.MFFileImport
                            WHERE FileUniqueRef = @FileID
                                  AND TargetClassID = @TargetClassMFID
                        )
                        BEGIN
                            UPDATE FI
                            SET FI.MFCreated = FD.MFCreated,
                                FI.MFLastModified = FD.MFLastModified,
                                FI.ObjID = FD.ObjID,
                                FI.Version = FD.ObjVer,
                                FI.FileObjectID = FD.FileObjectID,
                                FI.FileCheckSum = FD.FileCheckSum
                            FROM dbo.MFFileImport           FI
                                INNER JOIN #TempFileDetails FD
                                    ON FI.FileUniqueRef = FD.FileUniqueRef;
                        END;
                        ELSE
                        BEGIN
                            INSERT INTO dbo.MFFileImport
                            (
                                FileName,
                                FileUniqueRef,
                                CreatedOn,
                                SourceName,
                                TargetClassID,
                                MFCreated,
                                MFLastModified,
                                ObjID,
                                Version,
                                FileObjectID,
                                FileCheckSum
                            )
                            SELECT FileName,
                                FileUniqueRef,
                                GETDATE(),
                                @SourceTableName,
                                @TargetClassMFID,
                                MFCreated,
                                MFLastModified,
                                ObjID,
                                ObjVer,
                                FileObjectID,
                                FileCheckSum
                            FROM #TempFileDetails;
                        END;

                        DROP TABLE #TempFileDetails;
                    END; --end filename exist
                    ELSE
                    BEGIN
                        SET @DebugText = N'UniqueID %s';
                        SET @DebugText = @DefaultDebugText + @DebugText;
                        SET @ProcedureStep = 'Filename missing';

                        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep, @FileID);
                    END; -- Else end

                    SET @Sql = N'
                    Select @Counter = (SELECT MIN(RowID) FROM ' + @TempFile + N' WHERE Rowid > @Counter);';

                    EXEC sys.sp_executesql @Sql, N'@Counter int output', @Counter OUTPUT;
                END; -- end loop

                SELECT @tempTableName = 'tempdb..' + @TempFile;

                IF
                (
                    SELECT OBJECT_ID(@tempTableName)
                ) IS NOT NULL
                    EXEC ('Drop table ' + @TempFile);

                SET @Sql = N' Synchronizing records  from M-files to the target ' + @MFTableName;

                EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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
                    @debug = 0;

                -------------------------------------------------------------------
                --Synchronizing target table from M-Files
                -------------------------------------------------------------------
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Synchronizing target table from M-Files';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SET @Sql
                    = N'Update ' + @MFTableName + N' set Process_ID=0 where Process_ID= '
                      + CAST(@Process_ID AS VARCHAR(5));;

                --           PRINT @Sql;
                EXEC (@Sql);

                EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName,
                                                 @UpdateTypeID = 1,                                                 
                                                 @WithObjectHistory = 0,
                                                 @RetainDeletions = @RetainDeletions,
                                                 @Update_IDOut = @Update_IDOut OUTPUT,
                                                 @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                 @debug = @Debug
                
      
            END;
            ELSE
            BEGIN
                SET @DebugText = N'File unique column name does not belongs to the table';
                SET @DebugText = @DefaultDebugText + @DebugText;

                RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;
        END;
        ELSE
        BEGIN
            SET @DebugText = N'Target Table ' + @MFTableName + N' does not belong to MFClass table';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;
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

        SET @ProcedureStep = 'Catch Error';

        -------------------------------------------------------------
        -- Log Error
        -------------------------------------------------------------   
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = N'Error',
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatus,
            @debug = 0;

        SET @StartTime = GETUTCDATE();

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
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