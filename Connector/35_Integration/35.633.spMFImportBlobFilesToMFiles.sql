PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFImportBlobFilesToMFiles]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFImportBlobFilesToMFiles',
    -- nvarchar(100)
    @Object_Release = '4.7.18.59',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFImportBlobFilesToMFiles' --name of procedure
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
CREATE PROCEDURE dbo.spMFImportBlobFilesToMFiles
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFImportBlobFilesToMFiles
    @SourceTableName NVARCHAR(100),
    @FileUniqueKeyColumn NVARCHAR(100),
    @FileNameColumn NVARCHAR(100),
    @FileDataColumn NVARCHAR(100),
    @MFTableName NVARCHAR(100),
    @TargetFileUniqueKeycolumnName NVARCHAR(100) = 'MFSQL_Unique_File_Ref',
    @BatchSize INT = 500,
    @Process_ID INT = 5,
    @ProcessBatch_id INT = NULL OUTPUT,
    @Debug INT = 0
AS
/*rST**************************************************************************

===========================
spMFImportBlobFilesToMFiles
===========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @SourceTableName
   -  Fully qualified name of the table or view for the blob data.
  @FileUniqueKeyColumn
   -  Unique reference in blob table to reference the file to be imported. Th value in this column must corresponde with the value in the column set in @TargetFileUniqueKeycolumnName on the class table
  @FileNameColumn
   -  Name of column in blob table referencing the file name
  @FileDataColumn
   -  Name of column in blob table referencing the blob file in bit format
  @MFTableName
   - Target class tablename
  @TargetFileUniqueKeycolumnName
   - Property in class table for unique file reference of blob file
   - mfsql_File_Unique_ref is added by the installation package and can be used for this purpose
  @BatchSize (optional)
   - set batchsize for importing of files
   - default = 500
  @Process_id (required)
   - recommended to set to 6
   - set process_id for the targeted records for import on the class table prior to running this procedure
  @ProcessBatch_id (optional) OUTPUT
   - Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
   - Default = 0
   - 1 = Standard Debug Mode

Purpose
=======

This procedure will get a blob file from a designated table and import the file to a object in the class table

Additional Info
===============

Uploading blob files involve
 #. having a DB with all the files and source metadata. This could be a pre-existing third party application, or one can upload files from explorer into a temp db as part of the data refinement process and preparing the data for import, and then use MFSQL to import the data.

 #. using MFSQL to extract the blob files and associate the files with metadata

The import history is in the table MFFileImport

Prerequisites
=============

The file source table as columns for a unique reference for each row, the file name and the blob data in bit format.
The class table has a column (the default property is Mfsql_File_Unique_Ref ) 
This column includes a reference that is a unique one to one relation to the file source table for every row that must import a file
The process_id column for the rows in the class table to be included in the import is set to 6

The import will be performed in batches of 500

Examples
========

.. code:: sql

   DECLARE @Processbatch_id int
   EXEC dbo.spMFImportBlobFilesToMFiles @SourceTableName = 'filedata.dbo.[FileIndex_FileData]',               
                                     @FileUniqueKeyColumn = 'SerialNumber', 
                                     @FileNameColumn = 'NameFile', 
                                     @FileDataColumn = 'Chart', 
                                     @MFTableName = 'MFDrawing',
                                     @BatchSize = 500,   
									 @Process_id = 6,  
                                     @ProcessBatch_id = @ProcessBatch_id OUTPUT, 
                                     @Debug = 0 , 
                                     @TargetFileUniqueKeycolumnName = 'mfsql_File_Unique_ref'; 

----

View import result

.. code:: sql

    SELECT * FROM dbo.MFFileImport

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-05-13  LC         Reset the procedure and issue as new
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
        DECLARE @ProcedureName sysname = 'spMFImportBlobFilesToMFiles';
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

        SET @ProcessType = @ProcedureName;
        SET @LogText = @ProcedureName + N' Started ';
        SET @LogStatus = N'Initiate';
        SET @StartTime = GETUTCDATE();
        SET @ProcessBatch_id = 0;

        EXECUTE @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = @LogType,
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        ----------------------------------------
        --DECLARE VARIABLES
        ----------------------------------------
        DECLARE @TargetClassMFID INT;
        DECLARE @ObjectTypeID INT;
        DECLARE @VaultSettings NVARCHAR(MAX);
        DECLARE @XML NVARCHAR(MAX);
        DECLARE @Counter INT;
        DECLARE @MaxRowID INT;
        DECLARE @FileLocation VARCHAR(200);
        DECLARE @Sql NVARCHAR(MAX);
        DECLARE @Params NVARCHAR(MAX);

        SET @ProcedureStep = 'Checking Target class ' + @MFTableName + ' is present in the MFClass table';

        IF @Debug > 0
            PRINT @ProcedureStep;

        IF EXISTS (SELECT TOP 1 * FROM dbo.MFClass WHERE TableName = @MFTableName)
        BEGIN
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
                @debug = @Debug;

            SELECT @TargetClassMFID = MC.MFID,
                @ObjectTypeID       = OT.MFID
            FROM dbo.MFClass                MC
                INNER JOIN dbo.MFObjectType OT
                    ON MC.MFObjectType_ID = OT.ID
            WHERE MC.TableName = @MFTableName;

            SET @ProcedureStep
                = 'Checking File unique key property ' + @TargetFileUniqueKeycolumnName
                  + ' is present in the Target class ' + @MFTableName;
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
                    @debug = @Debug;

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
                SET @rowcount = NULL;
                SET @Sql = N'	
SELECT ' +      QUOTENAME(@TargetFileUniqueKeycolumnName) + N', COUNT(*) FROM ' + QUOTENAME(@MFTableName) + N'
where ' +       QUOTENAME(@TargetFileUniqueKeycolumnName) + N' is not null 
GROUP BY ' +    QUOTENAME(@TargetFileUniqueKeycolumnName) + N' HAVING COUNT(*) > 1';

                EXEC sys.sp_executesql @stmt = @Sql;

                SET @rowcount = @@RowCount;
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Duplicate unique ref count  ' + CAST(@rowcount AS VARCHAR(10));

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @rowcount > 0
                BEGIN
                    SET @DebugText = N'Unique Ref has duplicate items';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Validate Unique File reference ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;

                ------------------------------------------------
                --Getting Temp File location to store File
                ------------------------------------------------
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Getting Temp File location to store File ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @FileLocation = CAST(Value AS VARCHAR(200))
                FROM dbo.MFSettings
                WHERE source_key = 'Files_Default'
                      AND Name = 'FileTransferLocation';

                SET @DebugText = @FileLocation;
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Get file transfer location ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                ------------------------------------------------
                --Creating Temp table to fecth only 500 records
                ------------------------------------------------
                DECLARE @TempFile VARCHAR(100);

                SELECT @TempFile = dbo.fnMFVariableTableName('InsertFiles', '');

                CREATE TABLE #TempFiles
                (
                    RowID INT IDENTITY(1, 1),
                    FileUniqueID NVARCHAR(250)
                );

                SET @ProcedureStep
                    = 'Getting top ' + CAST(@BatchSize AS VARCHAR(10)) + ' records from source ' + @SourceTableName;
                -----------------------------------------------------
                --Inserting @BatchSize records into the Temp table
                ----------------------------------------------------
                SET @Sql
                    = N' Insert into #TempFiles select top ' + CAST(@BatchSize AS VARCHAR(10)) + N' SR.'
                      + @FileUniqueKeyColumn + N' from ' + @SourceTableName + N' SR inner join ' + @MFTableName
                      + N' TN on SR.' + CAST(@FileUniqueKeyColumn AS NVARCHAR(100)) + N'=TN.' + @TargetFileUniqueKeycolumnName
                      + N' and TN.Process_ID= ' + CAST(@Process_ID AS VARCHAR(5));

                IF @Debug > 0
                    PRINT @Sql;

                EXEC (@Sql);

                SELECT @rowcount = COUNT(*) FROM #TempFiles AS tf
                SET @DebugText = N' Count #TempFiles ' + CAST(@rowcount AS NVARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

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
                    @debug = @Debug;

                SET @Counter = 1;

                SELECT @MaxRowID = MAX(RowID)
                FROM #TempFiles;

                SET @ProcedureStep = 'Importing file loop start ';

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
                    @debug = @Debug;

                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                WHILE @Counter <= @MaxRowID
                BEGIN
                    DECLARE @ID NVARCHAR(250);
                    DECLARE @ParmDefinition NVARCHAR(500);
                    DECLARE @XMLOut    XML,
                        @SqlID         INT,
                        @ObjId         INT,
                        @ObjectVersion INT;

                    SELECT @ID = FileUniqueID
                    FROM #TempFiles
                    WHERE RowID = @Counter;

                    SET @Sql
                        = N'select @SqlID=ID,@ObjId=ObjID,@ObjectVersion=MFVersion  from ' + @MFTableName + N' where '
                          + @TargetFileUniqueKeycolumnName + N' = ''' + @ID + N'''';

                    IF @Debug > 0
                        PRINT @Sql;

                    EXEC sys.sp_executesql @Sql,
                        N'@SqlID  INT OUTPUT,@ObjId  INT OUTPUT,@ObjectVersion  INT OUTPUT',
                        @SqlID OUTPUT,
                        @ObjId OUTPUT,
                        @ObjectVersion OUTPUT;

                    -----------------------------------------------------
                    --Creating the xml 
                    ----------------------------------------------------
                    SET @ProcedureStep = 'Create XML ';

                    DECLARE @Query NVARCHAR(MAX);

                    DECLARE @ColumnValuePair TABLE
                    (
                        ColunmName NVARCHAR(200),
                        ColumnValue NVARCHAR(4000),
                        Required BIT ---Added for checking Required property for table
                    );

                    DECLARE @TableWhereClause VARCHAR(1000),
                        @tempTableName        VARCHAR(1000),
                        @XMLFile              XML;

                    DELETE FROM @ColumnValuePair;

                    SET @TableWhereClause
                        = 'y.' + @TargetFileUniqueKeycolumnName + '=cast(''' + @ID
                          + ''' as nvarchar(100)) and Process_Id= ' + CAST(@Process_ID AS VARCHAR(5));

                    ----------------------------------------------------------------------------------------------------------
                    --Generate query to get column values as row value
                    ----------------------------------------------------------------------------------------------------------
                    SET @ProcedureStep = 'Get column Values';

                    SELECT @Query
                        = STUFF(
                          (
                              SELECT ' UNION ' + 'SELECT ''' + COLUMN_NAME + ''' as name, CONVERT(VARCHAR(max),['
                                     + COLUMN_NAME + ']) as value, 0  as Required FROM [' + @MFTableName + '] y'
                                     + ISNULL('  WHERE ' + @TableWhereClause, '')
                              FROM INFORMATION_SCHEMA.COLUMNS
                              WHERE TABLE_NAME = @MFTableName AND COLUMN_NAME <> 'Deleted'
                              FOR XML PATH('')
                          ),
                                   1,
                                   7,
                                   ''
                               );

                    -----------------------------------------------------
                    --List of columns to exclude
                    -----------------------------------------------------
                    SET @ProcedureStep = 'Get exclusions ';

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
                    WHERE mp.MFID IN ( 20, 21, 23, 25 )
                    UNION 
                    SELECT 'Process_ID' 
                    UNION 
                    SELECT 'Deleted';

                    --Last Modified, Last Modified by, Created, Created by

                    -----------------------------------------------------
                    --Insert to values INTo temp table
                    -----------------------------------------------------
                    SET @ProcedureStep = 'Create Temp table ';

                    IF @Debug > 0
                        PRINT @Query;

                    INSERT INTO @ColumnValuePair
                    EXEC (@Query);

                    DELETE FROM @ColumnValuePair
                    WHERE ColunmName IN
                          (
                              SELECT el.ColumnName FROM @ExcludeList AS el
                          );

                    IF @Debug > 0
                        SELECT 'afterExclude',
                            *
                        FROM @ColumnValuePair;

                    ----------------------	 Add for checking Required property--------------------------------------------
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

                    ------------------	 Add for checking Required property------------------------------------
                    SET @ProcedureStep = 'Convert datatime ';

                    --DELETE FROM @ColumnValuePair
                    --WHERE  ColumnValue IS NULL
                    UPDATE cp
                    SET cp.ColumnValue = CONVERT(DATETIME, CAST(cp.ColumnValue AS NVARCHAR(100)))
                    FROM @ColumnValuePair                     AS cp
                        INNER JOIN INFORMATION_SCHEMA.COLUMNS AS c
                            ON c.COLUMN_NAME = cp.ColunmName
                    WHERE c.DATA_TYPE = 'datetime'
                          AND cp.ColumnValue IS NOT NULL;

                    SET @ProcedureStep = 'Creating XML ';

                    -----------------------------------------------------
                    --Generate xml file -- 
                    -----------------------------------------------------
                    IF @Debug > 0
                        SELECT 'Columnvaluepair',
                            *
                        FROM @ColumnValuePair;

                    SET @XMLFile =
                    (
                        SELECT @ObjectTypeID AS [Object/@id],
                            @SqlID           AS [Object/@sqlID],
                            @ObjId           AS [Object/@objID],
                            @ObjectVersion   AS [Object/@objVesrion],
           
       --    0                AS [Object/@DisplayID)
              --              0                AS [Object/@DisplayID],
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
                                        WHERE mfp.MFID NOT IN ( 100 )
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

                        SELECT @XMLFile AS XMLFile;
                    END;

                    SET @ProcedureStep = 'Get Checksum ';

                    DECLARE @FileCheckSum NVARCHAR(MAX);

                    IF EXISTS
                    (
                        SELECT TOP 1
                            FileCheckSum
                        FROM dbo.MFFileImport
                        WHERE FileUniqueRef = @ID
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
                        WHERE FileUniqueRef = @ID
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

                    SET @ProcedureStep = 'Get XMLout ';
                    SET @Sql = N'';
                    SET @Sql
                        = N'select @XMLOut=
							                   (  Select cast(''' + @ID
                          + N''' as nvarchar(100)) as ''FileListItem/@ID'' , ' + @FileNameColumn
                          + N' as ''FileListItem/@FileName'', [' + @FileDataColumn + N'] as ''FileListItem/@File'', '
                          + CAST(@TargetClassMFID AS VARCHAR(100)) + N' as ''FileListItem/@ClassId'', '
                          + CAST(@ObjectTypeID AS VARCHAR(10)) + N' as ''FileListItem/@ObjType'',''' + @FileCheckSum
                          + N''' as ''FileListItem/@FileCheckSum'' from ' + @SourceTableName + N' where '
                          + @FileUniqueKeyColumn + N'=cast(''' + @ID
                          + N''' as nvarchar(100)) FOR XML PATH('''') , ROOT(''XMLFILE'') )';

                    IF @Debug > 0
                        PRINT @Sql;

                    EXEC sys.sp_executesql @Sql, N'@XMLOut XML OUTPUT', @XMLOut OUTPUT;

                    ;

                    SELECT @XML = CAST(@XMLOut AS NVARCHAR(MAX));

                    IF @Debug > 0
                        SELECT CAST(@XML AS XML);

                    -------------------------------------------------------------------
                    --Getting the Filedata in @Data variable
                    -------------------------------------------------------------------
                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Getting the Filedata';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    DECLARE @Data VARBINARY(MAX);

                    SET @Sql = N'';
                    SET @Sql
                        = N'select @Data=[' + @FileDataColumn + N']  from ' + @SourceTableName + N' where '
                          + @FileUniqueKeyColumn + N'=cast(''' + @ID + N''' as nvarchar(100))';

                    -- PRINT @Sql;
                    EXEC sys.sp_executesql @Sql, N'@Data  varbinary(max) OUTPUT', @Data OUTPUT;;

                    -------------------------------------------------------------------
                    --Importing File into M-Files using Connector
                    -------------------------------------------------------------------
                    DECLARE @XMLStr NVARCHAR(MAX),
                        @Result     NVARCHAR(MAX),
                        @ErrorMsg   NVARCHAR(MAX);

                    SET @XMLStr = N'<form>' + CAST(@XMLFile AS NVARCHAR(MAX)) + N'</form>';
                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Importing File ' + @ID + ' into M-Files using Connector ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    IF @debug > 0
                    Begin
                    SELECT LEN(@XML) AS '@XML Length';

                    SELECT LEN(@Data) AS '@data length';

                    SELECT LEN(@XMLStr) AS '@XMLStr';
                    END

                    EXEC dbo.spMFImportBlobFileToMFilesInternal @VaultSettings,
                        @XML,
                        @Data,
                        @XMLStr,
                        @FileLocation,
                        @Result OUT,
                        @ErrorMsg OUT;

                    --SELECT @Result
                    --SELECT @ErrorMsg
                    IF @ErrorMsg IS NOT NULL
                       AND LEN(@ErrorMsg) > 0
                    BEGIN
                        --  SET @Sql='update '+@MFTableName+' set Process_Id=2 where '+@FileUniqueKeyColumn+'='+@ID
                        SET @Sql
                            = N'update ' + QUOTENAME(@MFTableName) + N' set Process_ID=2 where '
                              + QUOTENAME(@TargetFileUniqueKeycolumnName) + N' =' + @ID;

                        --          PRINT @Sql;
                        EXEC (@Sql);
                    END;

                    SET @DebugText = N'';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Insert result in MFFileImport ';

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
                        MFCreated VARCHAR(100),
                        MFLastModified VARCHAR(100),
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
                    SELECT t.c.value('(@FileName)[1]', 'NVARCHAR(200)')   AS FileName,
                        t.c.value('(@FileUniqueRef)[1]', 'VARCHAR(100)')  AS FileUniqueRef,
                        t.c.value('(@MFCreated)[1]', 'VARCHAR(100)')      AS MFCreated,
                        t.c.value('(@MFLastModified)[1]', 'VARCHAR(100)') AS MFLastModified,
                        t.c.value('(@ObjID)[1]', 'INT')                   AS ObjID,
                        t.c.value('(@ObjVer)[1]', 'INT')                  AS ObjVer,
                        t.c.value('(@FileObjectID)[1]', 'INT')            AS FileObjectID,
                        t.c.value('(@FileCheckSum)[1]', 'NVARCHAR(MAX)')  AS FileCheckSum
                    FROM @ResultXml.nodes('/form/Object') AS t(c);

                    IF EXISTS
                    (
                        SELECT TOP 1
                            *
                        FROM dbo.MFFileImport
                        WHERE FileUniqueRef = @ID
                              AND TargetClassID = @TargetClassMFID
                    )
                    BEGIN
                        UPDATE FI
                        SET FI.MFCreated = CONVERT(DATETIME, FD.MFCreated),
                            FI.MFLastModified = CONVERT(DATETIME, FD.MFLastModified),
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
                            CONVERT(DATETIME, MFCreated),
                            CONVERT(DATETIME, MFLastModified),
                            ObjID,
                            ObjVer,
                            FileObjectID,
                            FileCheckSum
                        FROM #TempFileDetails;
                    END;

                    DROP TABLE #TempFileDetails;

                    SET @Counter = @Counter + 1;
                END;

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
                    @debug = @Debug;

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

                DECLARE @MFLastUpdateDate SMALLDATETIME;

                EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName, -- nvarchar(128)
                    @MFLastUpdateDate = @MFLastUpdateDate OUTPUT,             -- smalldatetime
                    @UpdateTypeID = 1,                                        -- tinyint
                    @Update_IDOut = @Update_IDOut OUTPUT,                     -- int
                    @ProcessBatch_ID = @ProcessBatch_id,                      -- int
                    @debug = 0;                                               -- tinyint
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
            @debug = @Debug;

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