
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateExplorerFileToMFiles]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateExplorerFileToMFiles',
    -- nvarchar(100)
    @Object_Release = '4.10.30.75',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateExplorerFileToMFiles' --name of procedure
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
CREATE PROCEDURE dbo.spMFUpdateExplorerFileToMFiles
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateExplorerFileToMFiles
    @FileName NVARCHAR(1000),
    @FileLocation NVARCHAR(1000),
    @MFTableName NVARCHAR(100),
    @SQLID INT,
    @IsFileDelete BIT = 0,
    @RetainDeletions BIT = 0,
    @IsDocumentCollection BIT = 0,
    @ProcessBatch_id INT = NULL OUTPUT,
    @Debug INT = 0
AS
/*rST**************************************************************************

==============================
spMFUpdateExplorerFileToMFiles
==============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @FileName nvarchar(256)
    Name of file
  @FileLocation nvarchar(256)
    UNC path or Fully qualified path to file
  @MFTableName nvarchar(100)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @SQLID int
    the ID column on the class table
  @IsFileDelete bit (optional)
    - Default = 0
    - 1 = the file should be deleted in folder
  @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
  @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
  @ProcessBatch\_id int (output)
    Output ID in MFProcessBatch for logging the process
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

MFSQL Connector file import provides the capability of attaching a file to a object in a class table.

Additional Info
===============

This functionality will:

- Add the file to an object.  If the object exist as a multidocument object with no files attached, the file will be added to the multidocument object and converted to a single file object.  If the files already exist for the object, the file will be added to the collection.
- The object must pre-exist in the class table. The class table metadata will be applied to object when adding the file. This procedure will add a new object from the class table, or update an existing object in M-Files using the class table metadata.
- The source file will optionally be deleted from the source folder.

The procedure will not automatically change a multifile document to a single file document. To set an object to a single file object the column 'Single_File' can be set to 1 after the file has been added.

Warnings
========

The procedure use the ID in the class table and not the objid column to reference the object.  This allows for referencing an record which does not yet exist in M-Files.

Examples
========

.. code:: sql

    DECLARE @ProcessBatch_id INT;
    DECLARE @FileLocation NVARCHAR(256) = 'C:\Share\Fileimport\2\'
    DECLARE @FileName NVARCHAR(100) = 'CV - Tommy Hart.docx'
    DECLARE @TableName NVARCHAR(256) = 'MFOtherDocument'
    DECLARE @SQLID INT = 1

    EXEC [dbo].[spMFUpdateExplorerFileToMFiles]
        @FileName = @FileName
       ,@FileLocation = @FileLocation
       ,@SQLID = @SQLID
       ,@MFTableName = @TableName
       ,@ProcessBatch_id = @ProcessBatch_id OUTPUT
       ,@Debug = 0
       ,@IsFileDelete = 0

    SELECT * from [dbo].[MFFileImport] AS [mfi]

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-01-23  lc         Fix bug setting single file to 1 when count > 1
2022-12-07  LC         Improve logging messages
2022-09-02  LC         Update to include RetainDeletions and DocumentCollections
2021-08-03  LC         Fix truncate string bug
2021-05-21  LC         improve handling of files on network drive
2020-12-31  LC         Improve error handling in procedure
2020-12-31  LC         Update datetime handling in mffileexport
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -----------------------------------------------------
        --DECLARE VARIABLES FOR LOGGING
        -----------------------------------------------------
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
        DECLARE @ProcedureName sysname = 'spMFUpdateExplorerFileToMFiles';
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

        SET @ProcessType = N'Import File';
        SET @LogText = N' Started ';
        SET @LogStatus = N'Initiate';
        SET @StartTime = GETUTCDATE();
        SET @LogTypeDetail = N'Debug';
        SET @LogStatusDetail = N'In Progress';


        EXECUTE @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_id OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = 'Info',
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = 0;

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_id,
            @LogType = @LogTypeDetail,
            @LogText = @LogText,
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
        --     DECLARE @Counter INT;
        DECLARE @MaxRowID INT;
        DECLARE @ObjIDs NVARCHAR(4000);
        DECLARE @Objid INT;
        DECLARE @Sql NVARCHAR(MAX);
        DECLARE @Params NVARCHAR(MAX);
        DECLARE @Count INT;
        DECLARE @FileID NVARCHAR(250);
        DECLARE @ParmDefinition NVARCHAR(500);
        DECLARE @XMLOut    XML,
            @ObjectVersion INT;
        DECLARE @Start INT;
        DECLARE @End INT;
        DECLARE @length INT;
        DECLARE @SearchTerm NVARCHAR(50) = N'System.';

        SET @ProcedureStep = 'Checking Target class ';
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        IF EXISTS (SELECT TOP 1 * FROM dbo.MFClass WHERE TableName = @MFTableName)
        BEGIN
            SET @LogTextDetail = @MFTableName + N' is valid table';

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

            DECLARE @TempFile VARCHAR(100);

            -------------------------------------------------------------
            -- license check
            -------------------------------------------------------------


EXEC dbo.spMFCheckLicenseStatus @InternalProcedureName = 'spMFUpdateExplorerFileToMFiles',
    @ProcedureName = @ProcedureName,
    @ProcedureStep = @ProcedureStep,
    @ProcessBatch_id = @ProcessBatch_id,
    @Debug = 0

                -------------------------------------------------------------
                -- Get objid for record
                -------------------------------------------------------------         
                
                SET @ProcedureStep = 'Get latest version';
                SET @Params = N'@ObjID INT output, @Count int output, @SQLID int';
                SET @Sql
                    = N'Select @ObjID = Objid, @Count = count(*) FROM ' + QUOTENAME(@MFTableName) + N' WHERE ID = '
                      + CAST(@SQLID AS VARCHAR(10)) + ' Group by Objid';
                
           --     PRINT @SQL
                EXEC sys.sp_executesql @Sql, @Params, @Objid OUTPUT, @Count OUTPUT, @SQLID;

                IF @count > 0 --SQLid is found
                BEGIN 
                SELECT @objid = CASE WHEN @objid > 0 THEN @objid ELSE NULL
                end


                SELECT @ObjIDs = CASE WHEN @objid IS NULL THEN 'null' ELSE CAST(@Objid AS VARCHAR(4000)) end;

                --      SELECT @Objid AS '@ObjId';
                SET @DebugText = N' Objids %s';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Get Objids for update';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDs);
                END;

                -------------------------------------------------------------
                -- get latest version of object
                -------------------------------------------------------------	
                IF @Objid IS NOT NULL
                BEGIN
                    SET @ProcedureStep = 'Update from MF';
                    SET @Params = N'@sqlid int';
                    SET @Sql = N'UPDATE ' + QUOTENAME(@MFTableName) + N' SET [Process_ID] = 0 WHERE id = @sqlid';

                    EXEC sys.sp_executesql @Sql, @Params, @Objid;


EXEC dbo.spMFUpdateTable @MFTableName = @MFTablename,
                         @UpdateMethod = 1,
                         @ObjIDs = @ObjID,
                         @Update_IDOut = @Update_IDOut OUTPUT,
                         @ProcessBatch_ID = @ProcessBatch_ID,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug

               
               END;

                IF @Objid IS NULL
                BEGIN
                    SET @ProcedureStep = 'Create new object into MF';
                    SET @Params = N'@Objid int';
                    SET @Sql = N'UPDATE ' + QUOTENAME(@MFTableName) + N' SET [Process_ID] = 1, single_file = 1 WHERE objid = @Objid';

                    EXEC sys.sp_executesql @Sql, @Params, @Objid;

                    EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName, 
                        @UpdateMethod = 0,                                                       
                        @ObjIDs = @ObjIDs,                                
                        @Update_IDOut = @Update_IDOut OUTPUT,             
                        @ProcessBatch_ID = @ProcessBatch_id,
                        @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug;

                END;

                SET @ProcedureStep = 'Get Objid details';

                DECLARE @CreateColumn   NVARCHAR(100),
                    @LastModifiedColumn NVARCHAR(100),
                    @CreateDate         DATETIME,
                    @lastModified       DATETIME;

                SELECT @CreateColumn = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 20;

                SELECT @LastModifiedColumn = ColumnName
                FROM dbo.MFProperty
                WHERE MFID = 21;

                -- int
                SET @Params
                    = N'@Objid int,@ObjectVersion int output, @CreateDate datetime output, @lastModified datetime output';
                SET @Sql
                    = N' SELECT @ObjectVersion = MFVersion, @CreateDate = ' + QUOTENAME(@CreateColumn)
                      + N'
                        , @lastModified = ' + QUOTENAME(@LastModifiedColumn) + N' from ' + QUOTENAME(@MFTableName)
                      + N' where objid = @Objid;';

                --                            PRINT @Sql;
                EXEC sys.sp_executesql @Sql,
                    @Params,
                    @Objid,
                    @ObjectVersion OUTPUT,
                    @CreateDate OUTPUT,
                    @lastModified OUTPUT;

                IF @Debug > 0
                begin
                    SELECT @Objid      AS Objid,
                        @ObjIDs        AS Objids,
                        @ObjectVersion AS Version,
                        @CreateDate    AS CreateDate,
                        @lastModified  AS LastModified;
                        end
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

                SET @TableWhereClause = 'y.ID = ' + CAST(@SQLID AS VARCHAR(20));
                --+'  

                --IF @Debug > 0
                --    PRINT @TableWhereClause;

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

                --IF @Debug > 0
                --    PRINT @Query;
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
                WHERE mp.MFID IN ( 21, 23, 25, 27 );

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
                    SELECT *
                    FROM @ColumnValuePair AS cvp;

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                ------------------	 Add for checking Required property------------------------------------
                SET @ProcedureStep = 'Convert datatime';

                DELETE FROM @ColumnValuePair
                WHERE ColumnValue IS NULL;

                UPDATE cp
                SET cp.ColumnValue = CONVERT(DATETIME, CAST(cp.ColumnValue AS NVARCHAR(100)))
                FROM @ColumnValuePair                     AS cp
                    INNER JOIN INFORMATION_SCHEMA.COLUMNS AS c
                        ON c.COLUMN_NAME = cp.ColunmName
                WHERE c.DATA_TYPE = 'datetime'
                      AND cp.ColumnValue IS NOT NULL;

                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                --           SELECT @Objid AS [ObjID];
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
                        @SQLID           AS [Object/@sqlID],
                        @Objid           AS [Object/@objID],
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

                    SELECT @XMLFile AS XMLFileForImport;
                END;

                SET @ProcedureStep = 'Prepare XML out';
                SET @Sql = N'';
                ;
                
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

                    SELECT @FileName AS filename;

                    --              SELECT CAST(@XML AS XML) AS '@XML Length';
                    SELECT @XMLStr AS '@XMLStr';

                    SELECT @FileLocation AS filelocation;
                END;

                EXEC dbo.spMFSynchronizeFileToMFilesInternal @VaultSettings,
                    @FileName,
                    @XMLStr,
                    @FileLocation,
                    @Result OUT,
                    @ErrorMsg OUT,
                    @IsFileDelete;

                IF @Debug > 0
                BEGIN
                    SELECT CAST(@Result AS XML) AS Result;

                    SELECT LEN(@ErrorMsg) AS errorlength,
                        @ErrorMsg         AS errormsg;
                END;

               
                                           SET @LogTypeDetail = 'Status';
                                           SET @LogStatusDetail = 'Imported';
                                           SET @LogTextDetail = ' ' + ISNULL(@FileName,'No File') + '; '+ ISNULL(@FileLocation,'No location')+ '; '+ @ErrorMsg
                                           SET @LogColumnName = 'Objid ';
                                           SET @LogColumnValue = CAST(@objid AS VARCHAR(10));
                
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

                -------------------------------------------------------------
                -- Set error message
                -------------------------------------------------------------
                BEGIN
                    SELECT @Start = CASE
                                        WHEN CHARINDEX(@SearchTerm, @ErrorMsg, 1) > 0 THEN
                                            CHARINDEX(@SearchTerm, @ErrorMsg, 1) + LEN(@SearchTerm)
                                        ELSE
                                            1
                                    END;

                    SELECT @End = CASE
                                      WHEN CHARINDEX(@SearchTerm, @ErrorMsg, @Start) < 50 THEN
                                          50
                                      ELSE
                                          CHARINDEX(@SearchTerm, @ErrorMsg, @Start)
                                  END;

                    SELECT @length = ISNULL(@End, 50) - ISNULL(@Start, 1);

                    SELECT @ErrorMsg = SUBSTRING(@ErrorMsg, @Start, @length);
                END;

                -------------------------------------------------------------
                -- update log
                -------------------------------------------------------------
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
                    FileCheckSum NVARCHAR(MAX),
                    ImportError NVARCHAR(4000)
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
                    FileCheckSum,
                    ImportError
                )
                SELECT t.c.value('(@FileName)[1]', 'NVARCHAR(200)')  AS FileName,
                    COALESCE(@FileLocation, NULL),
                    --          ,[t].[c].[value]('(@FileUniqueRef)[1]', 'VARCHAR(100)') AS [FileUniqueRef]
                    t.c.value('(@MFCreated)[1]', 'datetime')         AS MFCreated,
                    t.c.value('(@MFLastModified)[1]', 'datetime')    AS MFLastModified,
                    t.c.value('(@ObjID)[1]', 'INT')                  AS ObjID,
                    t.c.value('(@ObjVer)[1]', 'INT')                 AS ObjVer,
                    t.c.value('(@FileObjectID)[1]', 'INT')           AS FileObjectID,
                    t.c.value('(@FileCheckSum)[1]', 'NVARCHAR(MAX)') AS FileCheckSum,
                    CASE
                        WHEN LEN(@ErrorMsg) = 0 THEN
                            'Success'
                        ELSE
                            @ErrorMsg
                    END                                              AS ImportError
                FROM @ResultXml.nodes('/form/Object') AS t(c);

                -------------------------------------------------------------
                -- when file already exist, get column details from input XML
                -------------------------------------------------------------
                SET @ProcedureStep = 'Set details if file exist';

                UPDATE #TempFileDetails
                SET ObjID = @Objid,
                    ObjVer = @ObjectVersion,
                    MFCreated = @CreateDate,
                    MFLastModified = @lastModified,
                    ImportError = 'Filename Already Exists in object'
                WHERE ObjID = 0;

                IF @Debug > 0
                begin
                    SELECT *
                    FROM #TempFileDetails AS tfd
                    WHERE tfd.ObjID = @Objid;
                    END
                    
                SET @ProcedureStep = 'Update / insert record in MFFileImport';

                IF EXISTS
                (
                    SELECT TOP 1
                        *
                    FROM dbo.MFFileImport
                    WHERE ObjID = @Objid
                          AND TargetClassID = @TargetClassMFID
                          AND FileName = @FileName
                          AND FileUniqueRef = @FileLocation
                )
                BEGIN
                    UPDATE FI
                    SET FI.MFCreated = FD.MFCreated,
                        FI.MFLastModified = FD.MFLastModified,
                        FI.ObjID = FD.ObjID,
                        FI.Version = FD.ObjVer,
                        FI.FileObjectID = FD.FileObjectID,
                        FI.FileCheckSum = FD.FileCheckSum,
                        FI.ImportError = FD.ImportError
                    FROM dbo.MFFileImport           FI
                        INNER JOIN #TempFileDetails FD
                            ON FI.FileUniqueRef = FD.FileUniqueRef
                               AND FD.FileName = FI.FileName;
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
                        FileCheckSum,
                        ImportError
                    )
                    SELECT SUBSTRING(FileName,1,100),
                        FileUniqueRef,
                        GETDATE(),
                        @MFTableName,
                        @TargetClassMFID,
                        CASE
                            WHEN MFCreated = '1900-01-01 00:00:00.000' THEN
                                NULL
                            ELSE
                                CONVERT(DATETIME, MFCreated, 105)
                        END,
                        CASE
                            WHEN MFLastModified = '1900-01-01 00:00:00.000' THEN
                                NULL
                            ELSE
                                CONVERT(DATETIME, MFLastModified, 105)
                        END,
                        ObjID,
                        ObjVer,
                        FileObjectID,
                        FileCheckSum,
                        ImportError
                    FROM #TempFileDetails;
                END;

                DROP TABLE #TempFileDetails;

                IF
                (
                    SELECT OBJECT_ID(@tempTableName)
                ) IS NOT NULL
                    EXEC ('Drop table ' + @TempFile);

                SET @ProcedureStep = 'update from M-Files';
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

                --SET @Sql
                --    = 'Update ' + @MFTableName + ' set Process_ID=0 where Process_ID= '
                --      + CAST(@Process_ID AS VARCHAR(5));;

                ----           PRINT @Sql;
                --EXEC (@Sql);
                EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,
                    @UpdateMethod = 1,
                    @ObjIDs = @ObjIDs,
                    @Update_IDOut = @Update_IDOut OUTPUT,
                    @ProcessBatch_ID = @ProcessBatch_id ,
                     @RetainDeletions = @RetainDeletions,
                     @IsDocumentCollection = @IsDocumentCollection,
                      @Debug = @debug
;

                    SET @Sql = N'
                    UPDATE mc
SET mc.Single_File = 1, mc.Process_ID = 1
FROM ' + QUOTENAME(@MFTablename) + ' AS mc
WHERE ISNULL(mc.FileCount,0) = 1 AND Single_File = 0 AND Update_ID = ' +CAST(ISNULL(@Update_IDOut,0) AS NVARCHAR)

EXEC(@SQL);

EXEC dbo.spMFUpdateTableinBatches @MFTableName = @MFTableName,
    @UpdateMethod = 0,
    @ProcessBatch_id= @ProcessBatch_ID

            END --SQLID is valid
            ELSE
            BEGIN
             SET @DebugText = N'Object not found in ' + @MFTableName ;
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;            
        END; --table is valid
        ELSE
        BEGIN
            SET @DebugText = N'Target Table ' + @MFTableName + N' does not belong to MFClass table';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

    END TRY
    BEGIN CATCH
        SET @StartTime = GETUTCDATE();
        SET @LogStatus = N'Failed w/SQL Error';
        SET @LogTextDetail = ERROR_MESSAGE();
        SET @ErrorMsg = ERROR_MESSAGE();

        -------------------------------------------------------------
        -- Set error message
        -------------------------------------------------------------
        BEGIN
            SELECT @Start = CASE
                                WHEN CHARINDEX(@SearchTerm, @ErrorMsg, 1) > 0 THEN
                                    CHARINDEX(@SearchTerm, @ErrorMsg, 1) + LEN(@SearchTerm)
                                ELSE
                                    1
                            END;

            SELECT @End = CASE
                              WHEN CHARINDEX(@SearchTerm, @ErrorMsg, @Start) < 50 THEN
                                  50
                              ELSE
                                  CHARINDEX(@SearchTerm, @ErrorMsg, @Start)
                          END;

            SELECT @length = @End - @Start;

            SELECT @ErrorMsg = SUBSTRING(@ErrorMsg, ISNULL(@Start, 1), ISNULL(@length, 1));
        END;

        -------------------------------------------------------------
        -- update error in table
        -------------------------------------------------------------
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
            SET FI.FileName = @FileName,
                FI.FileUniqueRef = @FileLocation,
                FI.MFCreated = FI.MFCreated,
                FI.MFLastModified = GETDATE(),
                FI.ObjID = @Objid,
                FI.Version = @ObjectVersion,
                FI.FileObjectID = NULL,
                FI.FileCheckSum = NULL,
                FI.ImportError = @ErrorMsg
            FROM dbo.MFFileImport FI
            WHERE FI.ObjID = @Objid
                  AND FI.FileName = @FileName
                  AND FI.FileUniqueRef = @FileLocation;
        --INNER JOIN [#TempFileDetails] [FD]
        --    ON [FI].[FileUniqueRef] = [FD].[FileUniqueRef];
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
                ImportError
            )
            VALUES
            (@FileName, @FileLocation, GETDATE(), @MFTableName, @TargetClassMFID, NULL, NULL, @Objid, @ErrorMsg);
        END;

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
GO