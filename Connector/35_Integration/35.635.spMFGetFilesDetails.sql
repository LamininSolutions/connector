
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetFilesDetails]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFGetFilesDetails',
                                     -- nvarchar(100)
                                     @Object_Release = '4.8.24.65',
                                     -- varchar(50)
                                     @UpdateFlag = 2;
-- smallint
GO
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFGetFilesDetails' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFGetFilesDetails]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFGetFilesDetails]
(
   @MFTableName NVARCHAR(256),
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug INT = 0
)
AS
/*rST**************************************************************************

===================
spMFGetFilesDetails
===================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Process\_id int (optional)
    - Default = 1
    - process Id for records to be included
  @ProcessBatch\_ID int (optional, output)
    - Default = NULL
    - Referencing the ID of the ProcessBatch logging table
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

The procedure is used to get details of files for objects as set in the MFAuditHistory table and update MFFileExportHistory

Additional Info
===============

The main use case for this procedure is the explore details of files in SQL.  Details captured include: filename, FileID, File Extention, File size, objid, class id and object type.

Version 1 will export all information for all files from a class.  The export is performed in batches of 1000 records

Use the procedure spMFExportFiles to work with specific or individual objects and files.

Examples
========

Extract of all sales invoices by customer.

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-01-04  LC         Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    BEGIN TRY

        SET NOCOUNT ON;

        -----------------------------------------------------
        --DECLARE LOCAL VARIABLE
        ----------------------------------------------------

        DECLARE @VaultSettings NVARCHAR(4000);
        DECLARE @ClassID INT;
        DECLARE @ObjType INT;
        DECLARE @FilePath NVARCHAR(1000);
        DECLARE @FileExport NVARCHAR(MAX);
        DECLARE @ClassName NVARCHAR(128);
        DECLARE @OjectTypeName NVARCHAR(128);
        DECLARE @ID INT;
        DECLARE @ObjID INT;
        DECLARE @MFVersion INT;
        DECLARE @SingleFile BIT;
        DECLARE @Name_Or_Title_PropName NVARCHAR(250);
        DECLARE @Name_Or_title_ObjName NVARCHAR(250);
        DECLARE @IncludeDocIDTemp BIT;
        DECLARE @MFClassFileExportFolder NVARCHAR(200);
        DECLARE @ProcedureName sysname = 'spMFGetFilesDetails';
        DECLARE @ProcedureStep sysname = 'Start';
      


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
        DECLARE @ProcessType NVARCHAR(50);
        DECLARE @LogType AS NVARCHAR(50) = 'Status';
        DECLARE @LogText AS NVARCHAR(4000) = '';
        DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
        DECLARE @Status AS NVARCHAR(128) = NULL;
        DECLARE @Validation_ID INT = NULL;
        DECLARE @StartTime AS DATETIME;
        DECLARE @RunTime AS DECIMAL(18, 4) = 0;

        DECLARE @error AS INT = 0;
        DECLARE @rowcount AS INT = 0;
        DECLARE @return_value AS INT;
        DECLARE @RC INT;
        DECLARE @Update_ID INT;
   
   Declare @PathProperty_L1 NVARCHAR(128) = NULL,
    @PathProperty_L2 NVARCHAR(128) = NULL,
    @PathProperty_L3 NVARCHAR(128) = NULL,
    @IsIncludePropertyPath BIT = 0,
    @IsValidProperty_L1 bit = 0,
    @IsValidProperty_L2 bit = 0,
    @IsValidProperty_L3 bit = 0,
    @PathProperty_ColValL1 NVARCHAR(256)  = NULL,
    @PathProperty_ColValL2 NVARCHAR(256)  = NULL,
    @PathProperty_ColValL3 NVARCHAR(256)  = NULL,
    @DeletedColumn NVARCHAR(256)  = NULL,
    @MultiDocFolder NVARCHAR(256)  = NULL,
    @IncludeDocID int
    ----------------------------------------------------------------------
        --GET Vault LOGIN CREDENTIALS
        ----------------------------------------------------------------------

        SET @ProcessType = @ProcedureName;
        SET @LogType = 'Status';
        SET @LogText = @ProcedureStep + ' | ';
        SET @LogStatus = 'Initiate';

        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                      @ProcessType = @ProcessType,
                                                      @LogType = @LogType,
                                                      @LogText = @LogText,
                                                      @LogStatus = @LogStatus,
                                                      @debug = @Debug;

        SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();
	
    -------------------------------------------------------------
    -- get listing of objects
    -------------------------------------------------------------

   

             -----------------------------------------------------------------
            -- Checking module access for CLR procdure  spMFGetFilesInternal
            ------------------------------------------------------------------
            SET @Procedurestep = 'Check license'
            EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetFilesDetail',
                                                @ProcedureName,
                                                @ProcedureStep;
           
            -----------------------------------------------------------------------------
            --Creating the cursor and cursor query.
            -----------------------------------------------------------------------------
            SET @ProcedureStep = 'Loop through objects'

            DECLARE @GetDetailsCursor AS CURSOR;
            DECLARE @CursorQuery NVARCHAR(200),
                    @process_ID_text VARCHAR(5),
                    @vsql  NVARCHAR(MAX),
                    @vquery  NVARCHAR(MAX),
                    @IsDownLoad NVARCHAR(4) = '0';


            IF @IsIncludePropertyPath = 1
            BEGIN

                SET @vquery
                    = 'SELECT ID,ObjID,MFVersion,isnull(Single_File,0) as Single_File,isnull('
                      + @Name_Or_Title_PropName + ','''') as Name_Or_Title';

                IF @IsValidProperty_L1 = 1
                BEGIN
                    SET @vquery = @vquery + ', isnull(' + @PathProperty_L1 + ', '''') as PathProperty_L1';
                END;
                ELSE
                BEGIN
                    SET @vquery = @vquery + ', '''' as PathProperty_L1';
                END;

                IF @IsValidProperty_L2 = 1
                BEGIN
                    SET @vquery = @vquery + ', isnull(' + @PathProperty_L2 + ', '''') as PathProperty_L2';
                END;
                ELSE
                BEGIN
                    SET @vquery = @vquery + ', '''' as PathProperty_L2';
                END;

                IF @IsValidProperty_L3 = 1
                BEGIN
                    SET @vquery = @vquery + ', isnull(' + @PathProperty_L3 + ', '''') as PathProperty_L3';
                END;
                ELSE
                BEGIN
                    SET @vquery = @vquery + ', '''' as PathProperty_L3';
                END;

                SET @vquery
                    = @vquery + ' from [' + @MFTableName + '] WHERE Process_ID = ' + @process_ID_text
                      + ' AND ' +QUOTENAME(@DeletedColumn)+' is null';

                IF @Debug > 0
                    PRINT @vquery;
            END;
            ELSE
            BEGIN
                IF @Debug > 0
                    PRINT 'test';

                SET @vquery
                    = 'SELECT ID,ObjID,MFVersion,isnull(Single_File,0) as Single_File,isnull('
                      + @Name_Or_Title_PropName
                      + ','''') as Name_Or_Title,'''' as PathProperty_L1, '''' as  PathProperty_L2, '''' as PathProperty_L3  from ['
                      + @MFTableName + '] WHERE Process_ID = ' + @process_ID_text + ' AND ' +QUOTENAME(@DeletedColumn)+' is null';
                IF @Debug > 0
                    PRINT @vquery;
            END;

            --SET @vquery
            --             = 'SELECT ID,ObjID,MFVersion,isnull(Single_File,0),isnull('+@Name_Or_Title_PropName+','''') from [' + @MFTableName
            --               + '] WHERE Process_ID = '+ @Process_id_text +'    AND Deleted = 0';


            SET @vsql = 'SET @cursor = cursor forward_only static FOR ' + @vquery + ' OPEN @cursor;';

            IF @Debug > 0
                PRINT @vsql;

            EXEC [sys].[sp_executesql] @vsql,
                                       N'@cursor cursor output',
                                       @GetDetailsCursor OUTPUT;






            FETCH NEXT FROM @GetDetailsCursor
            INTO @ID,
                 @ObjID,
                 @MFVersion,
                 @SingleFile,
                 @Name_Or_title_ObjName,
                 @PathProperty_ColValL1,
                 @PathProperty_ColValL2,
                 @PathProperty_ColValL3;

            WHILE (@@FETCH_STATUS = 0)
            BEGIN


                SELECT @ProcedureStep = 'Started downloading Files for  objectID: ' + CAST(@ObjID AS VARCHAR(10));
                IF @Debug > 0
                BEGIN
                    PRINT 'Started downloading Files for  objectID=' + CAST(@ObjID AS VARCHAR(10));
                    RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                DECLARE @TempFilePath NVARCHAR(MAX);
                SET @TempFilePath = @FilePath;

                IF @IsIncludePropertyPath = 1
                BEGIN
                    --SET @TempFilePath = @TempFilePath+@PathProperty_ColValL1+'\'+@PathProperty_ColValL2+'\'+@PathProperty_ColValL3+'\';

                    IF @Debug > 0
                    BEGIN
                        SELECT @TempFilePath + @PathProperty_ColValL1 + @PathProperty_ColValL2
                               + +@PathProperty_ColValL3;
                    END;


                    --IF @PathProperty_ColValL1 IS NOT NULL
                    --   OR	@PathProperty_ColValL1 != ''
                    SET @TempFilePath = CASE
                                            WHEN @PathProperty_ColValL1 IS NOT NULL THEN
                                                @TempFilePath + CAST(@PathProperty_ColValL1 AS NVARCHAR(200)) + '\'
                                            ELSE
                                                @TempFilePath
                                        END;

                    --IF @PathProperty_ColValL2 IS NOT NULL
                    --   OR	@PathProperty_ColValL2 != ''
                    SET @TempFilePath = CASE
                                            WHEN @PathProperty_ColValL2 IS NULL THEN
                                                @TempFilePath
                                            WHEN @PathProperty_ColValL2 = '' THEN
                                                @TempFilePath
                                            WHEN @PathProperty_ColValL2 IS NOT NULL THEN
                                                @TempFilePath + CAST(@PathProperty_ColValL2 AS NVARCHAR(200)) + '\'
                                        END;

                    --IF @PathProperty_ColValL3 IS NOT NULL
                    --   OR	@PathProperty_ColValL3 != ''
                    SET @TempFilePath = CASE
                                            WHEN @PathProperty_ColValL3 IS NULL THEN
                                                @TempFilePath
                                            WHEN @PathProperty_ColValL3 = '' THEN
                                                @TempFilePath
                                            WHEN @PathProperty_ColValL3 IS NOT NULL THEN
                                                @TempFilePath + CAST(@PathProperty_ColValL3 AS NVARCHAR(200)) + '\'
                                        END;

                --SET @TempFilePath = @TempFilePath
                --					+ CAST(@PathProperty_ColValL3 AS NVARCHAR(200)) + '\';


                END;
                IF @Debug > 0
                BEGIN
                    SELECT @TempFilePath AS [TempFilePath];
                END;


                IF @SingleFile = 0
                BEGIN
                    SET @MultiDocFolder = @Name_Or_title_ObjName;
                    IF @IncludeDocID = 1
                    BEGIN
                        SELECT @TempFilePath
                            = @TempFilePath + '\' + REPLACE(REPLACE(@Name_Or_title_ObjName, ':', '{3}'), '/', '{2}')
                              + ' (ID ' + CAST(@ObjID AS VARCHAR(10)) + ')\';

                        SET @IncludeDocIDTemp = 0;
                    END;
                    ELSE
                    BEGIN
                        SELECT @TempFilePath
                            = @TempFilePath + '\' + REPLACE(REPLACE(@Name_Or_title_ObjName, ':', '{3}'), '/', '{2}')
                              + '\';
                        SET @IncludeDocIDTemp = 0;
                    END;

                    SET @ProcedureStep = 'Calculate multi-file document path';
                    IF @Debug > 0
                    BEGIN
                        PRINT 'testing2';

                        PRINT 'MultiFile document';
                        PRINT @TempFilePath;
                        RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
                        SELECT @TempFilePath AS [MultiFileDownloadPath];
                    END;
                END;
                ELSE
                BEGIN
                    SET @IncludeDocIDTemp = @IncludeDocID;
                END;
                IF @Debug > 0
                BEGIN
                    PRINT @TempFilePath;
                    SELECT @VaultSettings AS [VaulSettings];
                    SELECT @ClassID AS [ClassID];
                    SELECT @ObjID AS [ObjID];
                    SELECT @ObjType AS [ObjType];
                    SELECT @MFVersion AS [MFVersion];
                    SELECT @TempFilePath AS [TempFilePath];
                    SELECT @IncludeDocIDTemp AS [IncludeDocIDTemp];

                -------------------------------------------------------------------
                --- Calling  the CLR StoredProcedure to Download file for @ObJID
                -------------------------------------------------------------------

                END;
                SET @ProcedureStep = 'Calling CLR GetFilesInternal';

                EXEC [dbo].[spMFGetFilesInternal] @VaultSettings,
                                                  @ClassID,
                                                  @ObjID,
                                                  @ObjType,
                                                  @MFVersion,
                                                  @TempFilePath,
                                                   @IsDownload,
                                                  @IncludeDocIDTemp,
                                                  @FileExport OUT;


                IF @Debug > 0
                BEGIN
                    SELECT @FileExport AS [FileExport];
                END;

                IF @Debug > 0
                BEGIN
                    PRINT @TempFilePath;
                    PRINT 'Resetting the Process_ID column';
                END;

                IF @FileExport IS NULL
                    SET @DebugText = 'Failed to get File from MF for Objid %i ';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = '';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjID);
                END;


                DECLARE @XmlOut XML;
                SET @XmlOut = @FileExport;

                EXEC ('Update ' + @MFTableName + ' set Process_ID=0 where ObjID=' + 'cast(' + @ObjID + 'as varchar(10))');

				

                CREATE TABLE [#temp]
                (
                    [FileName] NVARCHAR(400),
                    [ClassID] INT,
                    [ObjID] INT,
                    [ObjType] INT,
                    [Version] INT,
                    [FileCheckSum] NVARCHAR(1000),
                    [FileCount] INT,
					[FileObjectID] INT
                );
                INSERT INTO [#temp]
                (
                    [FileName],
                    [ClassID],
                    [ObjID],
                    [ObjType],
                    [Version],
                    [FileCheckSum],
                    [FileCount],
					[FileObjectID]
                )
                SELECT [t].[c].[value]('(@FileName)[1]', 'NVARCHAR(400)') AS [FileName],
                       [t].[c].[value]('(@ClassID)[1]', 'INT') AS [ClassID],
                       [t].[c].[value]('(@ObjID)[1]', 'INT') AS [ObjID],
                       [t].[c].[value]('(@ObjType)[1]', 'INT') AS [ObjType],
                       [t].[c].[value]('(@Version)[1]', 'INT') AS [Version],
                       [t].[c].[value]('(@FileCheckSum)[1]', 'nvarchar(1000)') AS [FileCheckSum],
                       [t].[c].[value]('(@FileCount)[1]', 'INT') AS [FileCount],
					   [t].[c].[value]('(@FileObjectID)[1]','INT') as [FileObjectID]
                FROM @XmlOut.[nodes]('/Files/FileItem') AS [t]([c]);

               IF @Debug > 0
               SELECT * FROM #temp AS t;

			
                MERGE INTO [dbo].[MFExportFileHistory] [t]
                USING
                (
                    SELECT @FilePath AS [FileExportRoot],
                           @PathProperty_ColValL1 AS [subFolder_1],
                           @PathProperty_ColValL2 AS [subFolder_2],
                           @PathProperty_ColValL3 AS [subFolder_3],
                           [FileName],
                           [ClassID],
                           [ObjID],
                           [ObjType],
                           [Version],
                           @MultiDocFolder AS [MultiDocFolder],
                           [FileCheckSum],
                           [FileCount],
						   [FileObjectID]
                    FROM [#temp]
                ) [S]
                ON [t].[ClassID] = [S].[ClassID]
                   AND [t].[ObjID] = [S].[ObjID]
                   AND [t].[FileName] = [S].[FileName]
                WHEN NOT MATCHED THEN
                    INSERT
                    (
                        [FileExportRoot],
                        [SubFolder_1],
                        [SubFolder_2],
                        [SubFolder_3],
                        [FileName],
                        [ClassID],
                        [ObjID],
                        [ObjType],
                        [Version],
                        [MultiDocFolder],
                        [FileCheckSum],
                        [FileCount],
						[FileObjectID]
                    )
                    VALUES
                    ([S].[FileExportRoot], [S].[subFolder_1], [S].[subFolder_2], [S].[subFolder_3], [S].[FileName],
                     [S].[ClassID], [S].[ObjID], [S].[ObjType], [S].[Version], [S].[MultiDocFolder],
                     [S].[FileCheckSum], [S].[FileCount],[S].[FileObjectID])
                WHEN MATCHED THEN
                    UPDATE SET [t].[FileExportRoot] = [S].[FileExportRoot],
                               [t].[SubFolder_1] = [S].[subFolder_1],
                               [t].[SubFolder_2] = [S].[subFolder_2],
                               [t].[SubFolder_3] = [S].[subFolder_3],
                               [t].[Version] = [S].[Version],
                               [t].[MultiDocFolder] = [S].[MultiDocFolder],
                               [t].[FileCount] = [S].[FileCount],
                               [t].[Created] = GETDATE(),
							   [t].[FileObjectID]=[S].[FileObjectID];


                EXEC ('Update  MFT  set MFT.FileCount= t.FileCount
									From ' + @MFTableName + ' MFT inner join #temp t
									on MFT.ObjID=t.ObjID 
									where MFT.ObjID=cast(' + @ObjID + 'as varchar(10))');



                DROP TABLE [#temp];

                FETCH NEXT FROM @GetDetailsCursor
                INTO @ID,
                     @ObjID,
                     @MFVersion,
                     @SingleFile,
                     @Name_Or_title_ObjName,
                     @PathProperty_ColValL1,
                     @PathProperty_ColValL2,
                     @PathProperty_ColValL3;
            END;

            CLOSE @GetDetailsCursor;
            DEALLOCATE @GetDetailsCursor;



            SET @StartTime = GETUTCDATE();

            SET @LogTypeDetail = 'Download files';
            SET @LogTextDetail = @ProcedureName;
            SET @LogStatusDetail = 'Completed';
            SET @Validation_ID = NULL;
            SET @LogColumnValue = '';
            SET @LogColumnValue = '';

            EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
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

            RETURN 1;

    END TRY
    BEGIN CATCH

        EXEC ('Update ' + @MFTableName + ' set Process_ID=3 where ObjID=' + 'cast(' + @ObjID + 'as varchar(10))');

        INSERT INTO [dbo].[MFLog]
        (
            [SPName],
            [ErrorNumber],
            [ErrorMessage],
            [ErrorProcedure],
            [ProcedureStep],
            [ErrorState],
            [ErrorSeverity],
            [Update_ID],
            [ErrorLine]
        )
        VALUES
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE(),
         ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

        SET NOCOUNT OFF;
    END CATCH;
END;

GO
