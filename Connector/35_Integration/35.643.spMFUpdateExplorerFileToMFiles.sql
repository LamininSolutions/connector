GO
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateExplorerFileToMFiles]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFUpdateExplorerFileToMFiles'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.3.09.48'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateExplorerFileToMFiles' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateExplorerFileToMFiles]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFUpdateExplorerFileToMFiles]
    @FileName NVARCHAR(256)
   ,@FileLocation NVARCHAR(256)
   ,@MFTableName NVARCHAR(100)
   ,@SQLID INT
   ,@IsFileDelete BIT = 0
   ,@ProcessBatch_id INT = NULL OUTPUT
   ,@Debug INT = 0
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
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        -----------------------------------------------------
        --DECLARE VARIABLES FOR LOGGING
        -----------------------------------------------------
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
        DECLARE @ProcedureName sysname = 'spMFUpdateExplorerFileToMFiles';
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

        SET @ProcessType = 'Import File';
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
        --     DECLARE @Counter INT;
        DECLARE @MaxRowID INT;
        DECLARE @ObjIDs NVARCHAR(4000);
        DECLARE @Objid INT;
        DECLARE @Sql NVARCHAR(MAX);
        DECLARE @Params NVARCHAR(MAX);
        DECLARE @FileID NVARCHAR(250);
        DECLARE @ParmDefinition NVARCHAR(500);
        DECLARE @XMLOut        XML
               ,@ObjectVersion INT;
        DECLARE @Start INT;
        DECLARE @End INT;
        DECLARE @length INT;
        DECLARE @SearchTerm NVARCHAR(50) = 'System.';

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
            SET @LogTextDetail = @MFTableName + ' is valid MFClass table';

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

            DECLARE @TempFile VARCHAR(100);

            -------------------------------------------------------------
            -- 
            -------------------------------------------------------------
            SET @ProcedureStep = ' import file from source ';

            --               WHILE @Counter IS NOT NULL
            BEGIN

                -------------------------------------------------------------
                -- Get objid for record
                -------------------------------------------------------------
                SET @ProcedureStep = 'Get latest version';
                SET @Params = N'@ObjID INT output, @SQLID int';
                SET @Sql
                    = N'Select @ObjID = Objid FROM ' + QUOTENAME(@MFTableName) + ' WHERE ID = '
                      + CAST(@SQLID AS VARCHAR(10));

                PRINT @Sql;

                EXEC [sys].[sp_executesql] @Sql, @Params, @Objid OUTPUT, @SQLID;

                SELECT @ObjIDs = CAST(@Objid AS VARCHAR(4000));

                SELECT @Objid AS '@ObjId';

                SET @DebugText = ' Objids %s';
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
                    SET @Params = N'@Objid int';
                    SET @Sql = N'UPDATE ' + QUOTENAME(@MFTableName) + ' SET [Process_ID] = 0 WHERE objid = @Objid';

                    EXEC [sys].[sp_executesql] @Sql, @Params, @Objid;

                    EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName          -- nvarchar(200)
                                                ,@UpdateMethod = 1                    -- int                          
                                                ,@ObjIDs = @ObjIDs                    -- nvarchar(max)
                                                ,@Update_IDOut = @Update_IDOut OUTPUT -- int
                                                ,@ProcessBatch_ID = @ProcessBatch_id;

                    -- int
                    SET @Params = N'@ObjectVersion int output,@Objid int';
                    SET @Sql
                        = N' SELECT @ObjectVersion=MFVersion from ' + QUOTENAME(@MFTableName)
                          + ' where objid = 
                          @ObjID;';

                    --            PRINT @Sql;
                    EXEC [sys].[sp_executesql] @Sql, @Params, @ObjectVersion OUTPUT, @Objid;
                END;

                IF @Objid IS NULL
                BEGIN
                    SET @Params = N'@Objid int';
                    SET @Sql = N'UPDATE ' + QUOTENAME(@MFTableName) + ' SET [Process_ID] = 1 WHERE objid = @Objid';

                    EXEC [sys].[sp_executesql] @Sql, @Params, @Objid;

                    EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName          -- nvarchar(200)
                                                ,@UpdateMethod = 0                    -- int                          
                                                ,@ObjIDs = @ObjIDs                    -- nvarchar(max)
                                                ,@Update_IDOut = @Update_IDOut OUTPUT -- int
                                                ,@ProcessBatch_ID = @ProcessBatch_id; -- int

                    SET @Params = N'@ObjectVersion int output,@Objid int';
                    SET @Sql
                        = N' SELECT @ObjectVersion=MFVersion from ' + QUOTENAME(@MFTableName)
                          + ' where objid = @ObjID;';

                    --           PRINT @Sql;
                    EXEC [sys].[sp_executesql] @Sql, @Params, @ObjectVersion OUTPUT, @Objid;
                END;

                IF @Debug > 0
                    SELECT @Objid         AS [Objid]
                          ,@ObjIDs        AS [Objids]
                          ,@ObjectVersion AS [Version];

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

                --IF @Debug > 0
                --    PRINT @Query;
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

                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                    SELECT *
                    FROM @ColumnValuePair AS [cvp];
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
                    SELECT @ObjectTypeID  AS [Object/@id]
                          ,@SQLID         AS [Object/@sqlID]
                          ,@Objid         AS [Object/@objID]
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

                    SELECT @XMLFile AS [XMLFile];
                END;

                SET @ProcedureStep = 'Prepare XML out';
                SET @Sql = '';
                ;
                /*
                --SELECT @XML = CAST(@XMLOut AS NVARCHAR(MAX));
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -- PRINT @XML;
				*/
                -------------------------------------------------------------
                -- Set filedata for CLR to null - this is an explorer inpu routine
                -------------------------------------------------------------
                --           DECLARE @Data VARBINARY(MAX);

                --          SELECT @Data = NULL;

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

                    SELECT @FileName AS [filename];

                    --              SELECT CAST(@XML AS XML) AS '@XML Length';
                    SELECT @XMLStr AS '@XMLStr';

                    SELECT @FileLocation AS [filelocation];
                END;

                EXEC [dbo].[spMFSynchronizeFileToMFilesInternal] @VaultSettings
                                                                ,@FileName
                                                                ,@XMLStr
                                                                ,@FileLocation
                                                                ,@Result OUT
                                                                ,@ErrorMsg OUT
                                                                ,@IsFileDelete;

                IF @Debug > 0
                BEGIN
                    SELECT CAST(@Result AS XML) AS [Result];

                    SELECT @ErrorMsg AS [errormsg];
                END;

                -------------------------------------------------------------
                -- Set error message
                -------------------------------------------------------------
                IF @ErrorMsg <> ''
                BEGIN
                    SELECT @Start = CHARINDEX(@SearchTerm, @ErrorMsg, 1) + LEN(@SearchTerm);

                    SELECT @End = CHARINDEX(@SearchTerm, @ErrorMsg, @Start);

                    SELECT @length = @End - @Start;

                    SELECT @ErrorMsg = SUBSTRING(@ErrorMsg, @Start, @length);
                END;

                -------------------------------------------------------------
                -- update log
                -------------------------------------------------------------
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
                   ,[ImportError] NVARCHAR(4000)
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
                   ,[ImportError]
                )
                SELECT [t].[c].[value]('(@FileName)[1]', 'NVARCHAR(200)')     AS [FileName]
                      ,COALESCE(@FileLocation, NULL)
                      --          ,[t].[c].[value]('(@FileUniqueRef)[1]', 'VARCHAR(100)') AS [FileUniqueRef]
                      ,[t].[c].[value]('(@MFCreated)[1]', 'DATETIME')         AS [MFCreated]
                      ,[t].[c].[value]('(@MFLastModified)[1]', 'DATETIME')    AS [MFLastModified]
                      ,[t].[c].[value]('(@ObjID)[1]', 'INT')                  AS [ObjID]
                      ,[t].[c].[value]('(@ObjVer)[1]', 'INT')                 AS [ObjVer]
                      ,[t].[c].[value]('(@FileObjectID)[1]', 'INT')           AS [FileObjectID]
                      ,[t].[c].[value]('(@FileCheckSum)[1]', 'NVARCHAR(MAX)') AS [FileCheckSum]
                      ,CASE
                           WHEN @ErrorMsg = '' THEN
                               'Success'
                           ELSE
                               @ErrorMsg
                       END                                                    AS [ImportError]
                FROM @ResultXml.[nodes]('/form/Object') AS [t]([c]);

			

				Update #TempFileDetails set ImportError='File Already Exists' where ObjID=0

                IF @Debug > 0
                    SELECT *
                    FROM [#TempFileDetails] AS [tfd]
                    WHERE [tfd].[ObjID] = @Objid;

                IF EXISTS
                (
                    SELECT TOP 1
                           *
                    FROM [dbo].[MFFileImport]
                    WHERE [ObjID] = @Objid
                          AND [TargetClassID] = @TargetClassMFID
                          AND [FileName] = @FileName
                          AND [FileUniqueRef] = @FileLocation
                )
                BEGIN
                    UPDATE [FI]
                    SET [FI].[MFCreated] =case when [FD].[MFCreated] ='1900-01-01 00:00:00.000' then Null else [FD].[MFCreated] end  
                       ,[FI].[MFLastModified] = case when [FD].[MFLastModified] ='1900-01-01 00:00:00.000' then Null else [FD].[MFLastModified] end
                       ,[FI].[ObjID] = [FD].[ObjID]
                       ,[FI].[Version] = [FD].[ObjVer]
                       ,[FI].[FileObjectID] = [FD].[FileObjectID]
                       ,[FI].[FileCheckSum] = [FD].[FileCheckSum]
                       ,[FI].[ImportError] = [FD].[ImportError]
                    FROM [dbo].[MFFileImport]         [FI]
                        INNER JOIN [#TempFileDetails] [FD]
                            ON [FI].[FileUniqueRef] = [FD].[FileUniqueRef]
                               AND [FD].[FileName] = [FI].[FileName];
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
                       ,[ImportError]
                    )
                    SELECT [FileName]
                          ,[FileUniqueRef]
                          ,GETDATE()
                          ,@MFTableName
                          ,@TargetClassMFID
                          ,case when [MFCreated] ='1900-01-01 00:00:00.000' then Null else [MFCreated] end 
                          ,case when [MFLastModified] ='1900-01-01 00:00:00.000' then Null else [MFLastModified] end 
                          ,[ObjID]
                          ,[ObjVer]
                          ,[FileObjectID]
                          ,[FileCheckSum]
                          ,[ImportError]
                    FROM [#TempFileDetails];
                END;

                DROP TABLE [#TempFileDetails];

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

                --SET @Sql
                --    = 'Update ' + @MFTableName + ' set Process_ID=0 where Process_ID= '
                --      + CAST(@Process_ID AS VARCHAR(5));;

                ----           PRINT @Sql;
                --EXEC (@Sql);
                DECLARE @Return_LastModified DATETIME;

            DECLARE @MFLastUpdateDate SMALLDATETIME
                 
            EXEC dbo.spMFUpdateMFilesToMFSQL @MFTableName = @MFTableName,                           -- nvarchar(128)
                                             @MFLastUpdateDate = @MFLastUpdateDate OUTPUT, -- smalldatetime
                                             @UpdateTypeID = 1,                            -- tinyint
                                             @MaxObjects = 0,                              -- int
                                             @Update_IDOut = @Update_IDOut OUTPUT,         -- int
                                             @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,   -- int
                                             @debug = 0                                    -- tinyint
            


            END;
        END;
        ELSE
        BEGIN
            SET @DebugText = 'Target Table ' + @MFTableName + ' does not belong to MFClass table';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;
    END TRY
    BEGIN CATCH
        SET @StartTime = GETUTCDATE();
        SET @LogStatus = 'Failed w/SQL Error';
        SET @LogTextDetail = ERROR_MESSAGE();
		SET @ErrorMsg = ERROR_MESSAGE();

		         -------------------------------------------------------------
                -- Set error message
                -------------------------------------------------------------
                IF @ErrorMsg <> ''
                BEGIN
                    SELECT @Start = CHARINDEX(@SearchTerm, @ErrorMsg, 1) + LEN(@SearchTerm);

                    SELECT @End = CHARINDEX(@SearchTerm, @ErrorMsg, @Start);

                    SELECT @length = @End - @Start;

                    SELECT @ErrorMsg = SUBSTRING(@ErrorMsg, ISNULL(@Start,1), ISNULL(@length,1));
                END;

        -------------------------------------------------------------
        -- update error in table
        -------------------------------------------------------------
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
            SET [FI].[FileName] = @FileName
               ,[FI].[FileUniqueRef] = @FileLocation
               ,[FI].[MFCreated] = [FI].[MFCreated]
               ,[FI].[MFLastModified] = GETDATE()
               ,[FI].[ObjID] = @Objid
               ,[FI].[Version] = @ObjectVersion
               ,[FI].[FileObjectID] = NULL
               ,[FI].[FileCheckSum] = NULL
               ,[FI].[ImportError] =  @ErrorMsg
            FROM [dbo].[MFFileImport] [FI]
            WHERE [FI].[ObjID] = @Objid
                  AND [FI].[FileName] = @FileName
				  AND [FI].[FileUniqueRef] = @FileLocation;
        --INNER JOIN [#TempFileDetails] [FD]
        --    ON [FI].[FileUniqueRef] = [FD].[FileUniqueRef];
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
               ,[ImportError]
            )
            VALUES
            (@FileName, @FileLocation, GETDATE(), @MFTableName, @TargetClassMFID, NULL, NULL, @Objid
            ,@ErrorMsg);
        END;
/*
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
*/
        RETURN -1;
    END CATCH;
END;

GO
