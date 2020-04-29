PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFImportBlobFilesToMFiles]';
GO

SET NOCOUNT ON;
EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFImportBlobFilesToMFiles',
                                 -- nvarchar(100)
                                 @Object_Release = '4.6.18.58',
                                 -- varchar(50)
                                 @UpdateFlag = 2;
-- smallint

GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  
  ********************************************************************************
*/

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
	@Process_ID int = 5,
    @ProcessBatch_id INT = NULL OUTPUT,
    @Debug INT = 0
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
        DECLARE @ProcedureName sysname = 'spMFImportBlobFilesToMFiles';
        DECLARE @ProcedureStep sysname = 'Start';


        ----------------------------------------------------------------------
        --GET Vault LOGIN CREDENTIALS
        ----------------------------------------------------------------------



        DECLARE @Username NVARCHAR(2000);
        DECLARE @VaultName NVARCHAR(2000);

        SELECT TOP 1
               @Username = Username,
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

        SELECT @Update_ID = @@IDENTITY;

        SELECT @Update_IDOut = @Update_ID;

        SET @ProcessType = @ProcedureName;
        SET @LogText = @ProcedureName + ' Started ';
        SET @LogStatus = 'Initiate';
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
                   @ObjectTypeID = OT.MFID
            FROM dbo.MFClass MC
                INNER JOIN dbo.MFObjectType OT
                    ON MC.MFObjectType_ID = OT.ID
            WHERE MC.TableName = @MFTableName;

            SET @ProcedureStep
                = 'Checking File unique key property ' + @TargetFileUniqueKeycolumnName + ' is present in the Target class '
                  + @MFTableName;

            SET @DebugText = '';
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
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
                SET @DebugText = '';
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Getting Vault credentials ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @VaultSettings = dbo.FnMFVaultSettings();

                -------------------------------------------------------------
                -- Validate unique reference
                -------------------------------------------------------------
                SET @rowcount = NULL;
                SET @Sql
                    = N'	
SELECT ' +      QUOTENAME(@TargetFileUniqueKeycolumnName) + ', COUNT(*) FROM ' + QUOTENAME(@MFTableName)
                      + '
where ' +    QUOTENAME(@TargetFileUniqueKeycolumnName) + ' is not null 
GROUP BY ' +    QUOTENAME(@TargetFileUniqueKeycolumnName) + ' HAVING COUNT(*) > 1';

                EXEC sys.sp_executesql @stmt = @Sql;
                SET @rowcount = @@ROWCOUNT;

				SET @DebugText = '';
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Duplicate unique ref count  ' + CAST(@rowcount AS VARCHAR(10));

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @rowcount > 0
                BEGIN


                    SET @DebugText = 'Unique Ref has duplicate items - not allowed ';
                    SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Validate Unique File reference ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DefaultDebugText, 16, 1, @ProcedureName, @ProcedureStep);
                    END;

                END;

                ------------------------------------------------
                --Getting Temp File location to store File
                ------------------------------------------------
                SET @DebugText = '';
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Getting Temp File location to store File ';
                IF @Debug > 0
                BEGIN
                    RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SELECT @FileLocation = CAST(Value AS VARCHAR(200))
                FROM dbo.MFSettings
                WHERE source_key = 'Files_Default'
                      AND Name = 'FileTransferLocation';

                SET @DebugText = @FileLocation;
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Get file transfer location ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;


                ------------------------------------------------
                --Creating Temp table to fecth only 500 records
                ------------------------------------------------
				DECLARE @TempFile VARCHAR(100)
				SELECT @TempFile = dbo.fnMFVariableTableName('InsertFiles','')
                CREATE TABLE #TempFiles
                (
                    RowID INT IDENTITY(1, 1),
                    FileUniqueID NVARCHAR(250)
                );

                SET @ProcedureStep
                    = 'Getting top ' + CAST(@BatchSize AS VARCHAR(10)) + ' records from source' + @SourceTableName;
                -----------------------------------------------------
                --Inserting @BatchSize records into the Temp table
                ----------------------------------------------------
                SET @Sql
                    = ' Insert into #TempFiles select top ' + CAST(@BatchSize AS VARCHAR(10)) + ' SR.'
                      + @FileUniqueKeyColumn + ' from ' + @SourceTableName + ' SR inner join ' + @MFTableName
                      + ' TN on SR.' + @FileUniqueKeyColumn + '=TN.' + @TargetFileUniqueKeycolumnName
                      + ' and TN.Process_ID= ' + CAST(@Process_ID AS VARCHAR(5))

					  IF @Debug > 0
                            PRINT @Sql;

                EXEC (@Sql);

                SET @DebugText = '';
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;


                IF @Debug > 0
                BEGIN
                    RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                
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

                SET @DebugText = '';
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                WHILE @Counter <= @MaxRowID
                BEGIN
                    DECLARE @ID NVARCHAR(250);
                    DECLARE @ParmDefinition NVARCHAR(500);
                    DECLARE @XMLOut XML,
                            @SqlID INT,
                            @ObjId INT,
                            @ObjectVersion INT;

                    SELECT @ID = FileUniqueID
                    FROM #TempFiles
                    WHERE RowID = @Counter;

                    SET @Sql
                        = 'select @SqlID=ID,@ObjId=ObjID,@ObjectVersion=MFVersion  from ' + @MFTableName + ' where '
                          + @TargetFileUniqueKeycolumnName + ' = ''' + @ID + '''';

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
                    SET @ProcedureStep = 'Create XML '

                    DECLARE @Query NVARCHAR(MAX);

                    DECLARE @ColumnValuePair TABLE
                    (
                        ColunmName NVARCHAR(200),
                        ColumnValue NVARCHAR(4000),
                        Required BIT ---Added for checking Required property for table
                    );
                    DECLARE @TableWhereClause VARCHAR(1000),
                            @tempTableName VARCHAR(1000),
                            @XMLFile XML;

                    DELETE FROM @ColumnValuePair;

                    SET @TableWhereClause
                        = 'y.' + @TargetFileUniqueKeycolumnName + '=cast(''' + @ID + ''' as nvarchar(100)) and Process_Id= ' + CAST(@Process_ID AS VARCHAR(5));

                    ----------------------------------------------------------------------------------------------------------
                    --Generate query to get column values as row value
                    ----------------------------------------------------------------------------------------------------------
      SET @ProcedureStep = 'Get column Values'

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
                    -----------------------------------------------------
                    --List of columns to exclude
                    -----------------------------------------------------
      SET @ProcedureStep = 'Get exclusions '

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
                    WHERE mp.MFID IN ( 20, 21, 23, 25 ); --Last Modified, Last Modified by, Created, Created by

                    -----------------------------------------------------
                    --Insert to values INTo temp table
                    -----------------------------------------------------
                    
      SET @ProcedureStep = 'Create Temp table '

      IF @debug > 0
                    PRINT @Query;

      INSERT INTO @ColumnValuePair
                    EXEC (@Query);


                    DELETE FROM @ColumnValuePair
                    WHERE ColunmName IN (
                                            SELECT el.ColumnName FROM @ExcludeList AS el
                                        );



                    --SELECT *
                    --FROM @ColumnValuePair;


                    ----------------------	 Add for checking Required property--------------------------------------------

                    UPDATE CVP
                    SET CVP.Required = CP.Required
                    FROM @ColumnValuePair CVP
                        INNER JOIN dbo.MFProperty P
                            ON CVP.ColunmName = P.ColumnName
                        INNER JOIN dbo.MFClassProperty CP
                            ON P.ID = CP.MFProperty_ID
                        INNER JOIN dbo.MFClass C
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
                    SET cp.ColumnValue = CONVERT(DATE, CAST(cp.ColumnValue AS NVARCHAR(100)))
                    FROM @ColumnValuePair AS cp
                        INNER JOIN INFORMATION_SCHEMA.COLUMNS AS c
                            ON c.COLUMN_NAME = cp.ColunmName
                    WHERE c.DATA_TYPE = 'datetime'
                          AND cp.ColumnValue IS NOT NULL;


                    SET @ProcedureStep = 'Creating XML ';
                    -----------------------------------------------------
                    --Generate xml file -- 
                    -----------------------------------------------------
                    IF @debug > 0
                    SELECT 'Columnvaluepair',*
                    FROM @ColumnValuePair;
             
             SET @XMLFile =
                    (
                        SELECT @ObjectTypeID AS [Object/@id],
                               @SqlID AS [Object/@sqlID],
                               @ObjId AS [Object/@objID],
                               @ObjectVersion AS [Object/@objVesrion],
                               0 AS [Object/@DisplayID],
                               (
                                   SELECT
                                       (
                                           SELECT TOP 1
                                                  tmp.ColumnValue
                                           FROM @ColumnValuePair AS tmp
                                               INNER JOIN dbo.MFProperty AS mfp
                                                   ON mfp.ColumnName = tmp.ColunmName
                                           WHERE mfp.MFID = 100
                                       ) AS [class/@id],
                                       (
                                           SELECT mfp.MFID AS [property/@id],
                                                  (
                                                      SELECT MFTypeID FROM dbo.MFDataType WHERE ID = mfp.MFDataType_ID
                                                  ) AS [property/@dataType],
                                                  CASE
                                                      WHEN tmp.ColumnValue = 'ZZZ' THEN
                                                          NULL
                                                      ELSE
                                                          tmp.ColumnValue
                                                  END AS 'property' ----Added case statement for checking Required property
                                           FROM @ColumnValuePair AS tmp
                                               INNER JOIN dbo.MFProperty AS mfp
                                                   ON mfp.ColumnName = tmp.ColunmName
                                           WHERE mfp.MFID <> 100
                                                 AND tmp.ColumnValue IS NOT NULL --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                           FOR XML PATH(''), TYPE
                                       ) AS class
                                   FOR XML PATH(''), TYPE
                               ) AS Object
                        FOR XML PATH(''), ROOT('form')
                    );
                    SET @XMLFile =
                    (
                        SELECT @XMLFile.query('/form/*')
                    );

                    SET @DebugText = '';
                    SET @DefaultDebugText = @DefaultDebugText + @DebugText;


                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);

                        Select @XMLFile AS XMLFile;
                    END;

                    SET @ProcedureStep = 'Get Checksum '

					DECLARE @FileCheckSum NVARCHAR(MAX)

					IF EXIStS (SELECT top 1 FileCheckSum FROM MFFileImport WHERE FileUniqueRef=@ID and SourceName=@SourceTableName)
					  Begin
					     Create table #TempCheckSum
						 (
						    FileCheckSum NVARCHAR(MAX)
						 )
						 insert into #TempCheckSum select top 1 isnull(FileCheckSum,'') from MFFileImport WHERE FileUniqueRef=@ID and SourceName=@SourceTableName order by 1 desc

						 select * from #TempCheckSum
						 Select @FileCheckSum=isnull(FileCheckSum,'') from #TempCheckSum
						 
						 drop table #TempCheckSum
					  End
					Else
					 Begin
					    set @FileCheckSum=''
					 End

                     SET @ProcedureStep = 'Get XMLout '

                    SET @Sql = '';
                    SET @Sql
                        = 'select @XMLOut=
							                   (  Select cast(''' + @ID + ''' as nvarchar(100)) as ''FileListItem/@ID'' , ' + @FileNameColumn
                          + ' as ''FileListItem/@FileName'', [' + @FileDataColumn + '] as ''FileListItem/@File'', '
                          + CAST(@TargetClassMFID AS VARCHAR(100)) + ' as ''FileListItem/@ClassId'', '
                          + CAST(@ObjectTypeID AS VARCHAR(10)) + ' as ''FileListItem/@ObjType'','''
						  + @FileCheckSum+ ''' as ''FileListItem/@FileCheckSum'' from '
                          + @SourceTableName + ' where ' + @FileUniqueKeyColumn + '=cast(''' + @ID + ''' as nvarchar(100)) FOR XML PATH('''') , ROOT(''XMLFILE'') )';
                    
                    IF @Debug > 0
                    PRINT @Sql;

                    EXEC sys.sp_executesql @Sql, N'@XMLOut XML OUTPUT', @XMLOut OUTPUT;;

                    SELECT @XML = CAST(@XMLOut AS NVARCHAR(MAX));
                    
                    IF @Debug > 0
                    SELECT CAST(@XML AS XML);


                    -------------------------------------------------------------------
                    --Getting the Filedata in @Data variable
                    -------------------------------------------------------------------
                    SET @DebugText = '';
                    SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Getting the Filedata';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

                    DECLARE @Data VARBINARY(MAX);
                    SET @Sql = '';
                    SET @Sql
                        = 'select @Data=[' + @FileDataColumn + ']  from ' + @SourceTableName + ' where '
                          + @FileUniqueKeyColumn + '=cast(''' + @ID + ''' as nvarchar(100))';
                    -- PRINT @Sql;
                    EXEC sys.sp_executesql @Sql,
                                           N'@Data  varbinary(max) OUTPUT',
                                           @Data OUTPUT;;
                    -------------------------------------------------------------------
                    --Importing File into M-Files using Connector
                    -------------------------------------------------------------------
                    DECLARE @XMLStr NVARCHAR(MAX),
                            @Result NVARCHAR(MAX),
                            @ErrorMsg NVARCHAR(MAX);
                    SET @XMLStr = '<form>' + CAST(@XMLFile AS NVARCHAR(MAX)) + '</form>';

                    SET @DebugText = '';
                    SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Importing File ' + @ID + ' into M-Files using Connector ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;

					SELECT LEN(@XML) AS '@XML Length'
					SELECT LEN(@Data) AS '@data length'
					SELECT LEN(@XMLStr) AS '@XMLStr'


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
                            = 'update ' + QUOTENAME(@MFTableName) + ' set Process_ID=2 where ' + QUOTENAME(@TargetFileUniqueKeycolumnName)
                              + ' =' + @ID;
                        --          PRINT @Sql;
                        EXEC (@Sql);

                    END;

                    SET @DebugText = '';
                    SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Insert result in MFFileImport ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
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
                    SELECT t.c.value('(@FileName)[1]', 'NVARCHAR(200)') AS FileName,
                           t.c.value('(@FileUniqueRef)[1]', 'VARCHAR(100)') AS FileUniqueRef,
                           t.c.value('(@MFCreated)[1]', 'VARCHAR(100)') AS MFCreated,
                           t.c.value('(@MFLastModified)[1]', 'VARCHAR(100)') AS MFLastModified,
                           t.c.value('(@ObjID)[1]', 'INT') AS ObjID,
                           t.c.value('(@ObjVer)[1]', 'INT') AS ObjVer,
						   t.c.value('(@FileObjectID)[1]', 'INT') AS FileObjectID,
						   t.c.value('(@FileCheckSum)[1]', 'NVARCHAR(MAX)') AS FileCheckSum
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
							FI.FileObjectID=FD.FileObjectID,
							FI.FileCheckSum=FD.FileCheckSum
                        FROM dbo.MFFileImport FI
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
                               CONVERT(DATETIME,MFCreated),
                               CONVERT(DATETIME,MFLastModified),
                               ObjID,
                               ObjVer,
							   FileObjectID,
							   FileCheckSum
                        FROM #TempFileDetails;
                    END;
                    DROP TABLE #TempFileDetails;

                    SET @Counter = @Counter + 1;
                END;

                SET @Sql = ' Synchronizing records  from M-files to the target ' + @MFTableName;

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
                SET @DebugText = '';
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Synchronizing target table from M-Files';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;


                SET @Sql = 'Update ' + @MFTableName + ' set Process_ID=0 where Process_ID= ' + CAST(@Process_ID AS VARCHAR(5));;
                --           PRINT @Sql;
                EXEC (@Sql);
                DECLARE @MFLastUpdateDate SMALLDATETIME;

                EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName,                  -- nvarchar(128)
                                                 @MFLastUpdateDate = @MFLastUpdateDate OUTPUT, -- smalldatetime
                                                 @UpdateTypeID = 1,                            -- tinyint
                                                 @Update_IDOut = @Update_IDOut OUTPUT,         -- int
                                                 @ProcessBatch_ID = @ProcessBatch_id,          -- int
                                                 @debug = 0;                                   -- tinyint


            END;
            ELSE
            BEGIN

                SET @DebugText = 'File unique column name does not belongs to the table';
                SET @DefaultDebugText = @DefaultDebugText + @DebugText;

                RAISERROR(@DefaultDebugText, 16, 1, @ProcedureName, @ProcedureStep);

            END;

        END;
        ELSE
        BEGIN

            SET @DebugText = 'Target Table ' + @MFTableName + ' does not belong to MFClass table';
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DefaultDebugText, 16, 1, @ProcedureName, @ProcedureStep);
        END;
    END TRY
    BEGIN CATCH
        SET @StartTime = GETUTCDATE();
        SET @LogStatus = 'Failed w/SQL Error';
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