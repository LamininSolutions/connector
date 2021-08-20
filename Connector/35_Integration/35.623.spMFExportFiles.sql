
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFExportFiles]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFExportFiles',
    -- nvarchar(100)
    @Object_Release = '4.9.26.67',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFExportFiles' --name of procedure
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
CREATE PROCEDURE dbo.spMFExportFiles
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFExportFiles
(
    @TableName NVARCHAR(128),
    @PathProperty_L1 NVARCHAR(128) = NULL,
    @PathProperty_L2 NVARCHAR(128) = NULL,
    @PathProperty_L3 NVARCHAR(128) = NULL,
    @IsDownload BIT = 1,
    @IncludeDocID BIT = 1,
    @Process_id INT = 1,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug INT = 0
)
AS
/*rST**************************************************************************

===============
spMFExportFiles
===============

Return
   1 = Success
   -1 = Error

Parameters
  @TableName nvarchar(128)
    - Name of class table
  @PathProperty\_L1 nvarchar(128) (optional)
    - Default = NULL
    - Optional property column for 1st level path.  
  @PathProperty\_L2 nvarchar(128) (optional)
    - Default = NULL
    - Optional column for 2nd level path
  @PathProperty\_L3 nvarchar(128) (optional)
    - Default = NULL
    - Optional column for 3rd level path
  @IsDownload bit
    - Default = 1 (yes)
    - When set to 0 the file data will be updated in the table but the file is not downloaded.
  @IncludeDocID bit (optional)
    - Default = 1
    - File name include Document id.
  @Process\_id int (optional)
    - Default = 1
    - process Id for records to be included
  @ProcessBatch\_ID int (optional, output)
    - Default = NULL
    - Referencing the ID of the ProcessBatch logging table
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

The procedure is used to export selected files for class records from M-Files to a designated explorer folder on the server.

Additional Info
===============

The main use case for this procedure is to allow access to the files as attachments to emails or other third party system applications. An example is to prepare for bulk emailing of customer invoices.

All Object Types with Files can be included in an export.  Each class export is performed separately.

The destination folder in explorer is defined as:
  - The Root folder or UNC path is defined in MFSettings with name "RootFolder".  The user executing the script must have permission the read and write to this folder.  On installation this folder is automatically set to c:\\MFSQL\\FileExport.  
  - The next layer defines the root folder for the class.  This folder is defined in MFClass by changing the value of the column "FileExportFolder" for the specific class in MFClass. This layer is to set the 'What is being exported' e.g. SalesInvoices.  If the value in "FileExportFolder" for the class is null then the files will be saved to the root folder.
  - Three layers of property related folders can be defined as parameters by setting the PathPropertyL1 to L3 to valid columns on the class table.  These parameters are all optional.  L1 must have a value for L2 to and L3 to be specified.
  - Multi document objects will show the name of the object as the name of the folder for the files in the multi file object.
  - Filename (with or without object id)

For example the folders will be
  -  D:\\MFSQLExport\\SalesInvoices\\ABC Engineering\\Service Invoices\\2009\\ABC Engineering Inv 2324\\INV2345.pdf
  -  D:\\MFSQLExport\\SalesInvoices\\ABC Engineering\\Service Invoices\\2009\\ABC Engineering Inv 2324\\Supplements.pdf

The folder Definition comes from
  -  Root = D:\MFSQLExport (defined in MFSettings)
  -  Class = SalesInvoices (Defined in MFclass)
  -  Property 1 = Customer
  -  Property 2 = Document_type (type of invoice)
  -  Property 3 = Financial_year (Property showing financial year)
  -  MultiFile Object = Name_or_title
  -  Filename with object id

Each Path Property is the column values for the object. Level 3 is nested in Level 2 is nested in Level 1. E.g. CustomerABC\ProjectABC\InvoiceMonth.

The security context of the export functionality is using the SQL Service Account. The SQL Service Account must have appropriate permissions to create folders and files on the Root Folder.  Special care should be taken If a UNC path is used to set the SQL Service Account with appropriate permissions to access the UNC path.

MFExportFileHistory show the export result. Join this table on the class and objid with the class table to relate the files with the metadata.  Additional file data in the MFExportFileHistory table include:
 -  checksum
 -  File size
 -  File Extension
 -  File ID
 -  Count of files in object
 -  Name or title of object for multiple files 
 -  Date lastupdated
 -  Export Result

If IsDownload is set to 0 then the details of the file will be updated in the MFExportFileHistory table will be updated but the file will not be downloaded.

Examples
========

Extract of all sales invoices by customer.

.. code:: sql

    UPDATE  [MFClass] SET   [FileExportFolder] = 'SalesInvoices' WHERE  [ID] = 36;
    EXEC [spMFCreateTable] 'Sales Invoice';
    EXEC [spMFUpdateTable] 'MFSalesInvoice', 1;
    SELECT * FROM  [mfsalesinvoice];
    UPDATE [mfsalesinvoice]
    SET    [process_id] = 1
    WHERE  [filecount] > 0
    EXEC [spMFExportFiles]
        'mfsalesinvoice', 'Customer', NULL, NULL, 0, 0, 1, 0;

----

Produce extract of all sales invoices by Customer by Month (assuming that the invoice Month is a property on the invoice)

.. code:: sql

    DECLARE @ProcessBatch_ID INT;
    EXEC [dbo].[spMFExportFiles] @TableName = 'MFSalesInvoice', 
                                 @PathProperty_L1 = 'Customer', 
                                 @PathProperty_L2 = 'Document_Date', 
                                 @PathProperty_L3 = null, 
                                 @isDownload = 1,
                                 @IncludeDocID = 0, 
                                 @Process_id = 1, 
                                 @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, 
                                 @Debug = 0 

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-01-07  LC         Change CLR to improve downloading multiple files
2021-01-07  LC         Include parameter to restrict download of files
2021-01-05  LC         Improve productivity and processing logic
2021-01-04  LC         Add columns filesize and file extension
2021-01-04  LC         Add new param for GetFiles and set default to 0 
2020-11-01  LC         Fix bug with misplaced as in code
2020-08-22  LC         Update code for deleted column change
2020-05-26  LC         Update fileid into table
2019-08-30  JC         Added documentation
2018-12-03  LC         Bug 'String or binary data truncated' in file name
2018-06-28  LC         Set return success = 1
2018-02-20  LC         Set processbatch_id to output
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
        DECLARE @ProcedureName sysname = 'spMFExportFiles';
        DECLARE @ProcedureStep sysname = 'Start';
        DECLARE @process_ID_text VARCHAR(5),
            @vsql                NVARCHAR(MAX),
            @vquery              NVARCHAR(MAX),
            @Params              NVARCHAR(MAX);

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
        DECLARE @ProcessType NVARCHAR(50);
        DECLARE @LogType AS NVARCHAR(50) = N'Status';
        DECLARE @LogText AS NVARCHAR(4000) = N'';
        DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
        DECLARE @Status AS NVARCHAR(128) = NULL;
        DECLARE @Validation_ID INT = NULL;
        DECLARE @StartTime AS DATETIME;
        DECLARE @RunTime AS DECIMAL(18, 4) = 0;
        DECLARE @error AS INT = 0;
        DECLARE @rowcount AS INT = 0;
        DECLARE @return_value AS INT;
        DECLARE @RC INT;
        DECLARE @Update_ID INT;
        DECLARE @IsIncludePropertyPath BIT = 0;
        DECLARE @IsValidProperty_L1 BIT;
        DECLARE @IsValidProperty_L2 BIT;
        DECLARE @IsValidProperty_L3 BIT;
        DECLARE @MultiDocFolder NVARCHAR(100);
        DECLARE @DeletedColumn NVARCHAR(100);

        ----------------------------------------------------------------------
        --GET Vault LOGIN CREDENTIALS
        ----------------------------------------------------------------------
        DECLARE @Rootfolder NVARCHAR(100) = N'';

        SET @ProcessType = @ProcedureName;
        SET @LogType = N'Status';
        SET @LogText = @ProcedureStep + N' | ';
        SET @LogStatus = N'Initiate';

        EXECUTE @RC = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
            @ProcessType = @ProcessType,
            @LogType = @LogType,
            @LogText = @LogText,
            @LogStatus = @LogStatus,
            @debug = @Debug;

        SELECT @VaultSettings = dbo.FnMFVaultSettings();

        -------------------------------------------------------------
        -- check class table is valid
        -------------------------------------------------------------
        SET @DebugText = N'%s';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'check Table Name: ';

        IF EXISTS (SELECT 1 FROM dbo.MFClass WHERE TableName = @TableName) 
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName);
        
            -------------------------------------------------------------
            -- Get deleted column name
            -------------------------------------------------------------
            SELECT @DeletedColumn = ColumnName
            FROM dbo.MFProperty
            WHERE MFID = 27;

            SELECT @Rootfolder = CAST(Value AS NVARCHAR(100))
            FROM dbo.MFSettings
            WHERE Name = 'RootFolder';

            SELECT @Name_Or_Title_PropName = mp.ColumnName
            FROM dbo.MFProperty AS mp
            WHERE mp.MFID = 0;

            SET @DebugText = N' RootFolder %s';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Getting started';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Rootfolder);
            END;

            SELECT @ClassID              = ISNULL(CL.MFID, 0),
                @ObjType                 = OT.MFID,
                @ClassName               = CL.Name,
                @OjectTypeName           = OT.Name,
                @MFClassFileExportFolder = ISNULL(CL.FileExportFolder, '')
            FROM dbo.MFClass                AS CL
                INNER JOIN dbo.MFObjectType AS OT
                    ON CL.MFObjectType_ID = OT.ID
                       AND CL.TableName = @TableName;

            IF @Rootfolder != ''
            BEGIN
                SET @ProcedureStep = 'File download path: ';
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                ------------------------------------------------------------------------------------------------
                --Creating File path
                -------------------------------------------------------------------------------------------------
                IF @PathProperty_L1 IS NOT NULL
                BEGIN
                    IF EXISTS
                    (
                        SELECT COLUMN_NAME
                        FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = @TableName
                              AND COLUMN_NAME = @PathProperty_L1
                    )
                    BEGIN
                        SET @IsValidProperty_L1 = 1;
                    END;
                END;

                IF @PathProperty_L2 IS NOT NULL
                BEGIN
                    IF EXISTS
                    (
                        SELECT COLUMN_NAME
                        FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = @TableName
                              AND COLUMN_NAME = @PathProperty_L2
                    )
                    BEGIN
                        SET @IsValidProperty_L2 = 1;
                    END;
                END;

                IF @PathProperty_L3 IS NOT NULL
                BEGIN
                    IF EXISTS
                    (
                        SELECT COLUMN_NAME
                        FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = @TableName
                              AND COLUMN_NAME = @PathProperty_L3
                    )
                    BEGIN
                        SET @IsValidProperty_L3 = 1;
                    END;
                END;

                IF @IsValidProperty_L1 = 1
                   OR @IsValidProperty_L2 = 1
                   OR @IsValidProperty_L3 = 1
                BEGIN
                    SET @IsIncludePropertyPath = 1;
                END;

                SET @DebugText = N' Property path included %s';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF (@Debug > 0)
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @MFClassFileExportFolder);

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @PathProperty_L1);

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @PathProperty_L2);

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @PathProperty_L3);
                END;

                SELECT @ProcedureStep = ' Set file path';

                IF @MFClassFileExportFolder != ''
                   OR @MFClassFileExportFolder IS NOT NULL
                BEGIN
                    SET @FilePath = CASE
                                        WHEN PATINDEX('%\%', @MFClassFileExportFolder) > 1 THEN
                                            @Rootfolder + @MFClassFileExportFolder
                                        WHEN @MFClassFileExportFolder = '' THEN
                                            @Rootfolder
                                        ELSE
                                            @Rootfolder + @MFClassFileExportFolder + '\'
                                    END;
                END;

                SET @DebugText = N':' + @FilePath;
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                --SET @FilePath = @FilePath + @PathProperty_L1 + '\' + @PathProperty_L2 + '\' + @PathProperty_L3 + '\';
                SELECT @ProcedureStep = 'Fetching records from ' + @TableName + ' to download document.';

                IF NOT EXISTS
                (
                    SELECT COLUMN_NAME
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_NAME = @TableName
                          AND COLUMN_NAME = 'FileCount'
                )
                BEGIN
                    EXEC ('alter table ' + @TableName + ' add FileCount int CONSTRAINT DK_FileCount_' + @TableName + ' DEFAULT 0 WITH VALUES');

                    SET @DebugText = N'';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                    END;
                END;

                -----------------------------------------------------------------
                -- Checking module access for CLR procdure  spMFGetFilesInternal
                ------------------------------------------------------------------
                SET @ProcedureStep = 'Check license';

                EXEC dbo.spMFCheckLicenseStatus 'spMFGetFilesListInternal',
                    @ProcedureName,
                    @ProcedureStep;

                -------------------------------------------------------------
                -- Create list of objids and filenr
                -------------------------------------------------------------
                SET @ProcedureStep = 'Create list of objids and filenr';

                IF
                (
                    SELECT OBJECT_ID('tempdb..#FileList')
                ) IS NOT NULL
                    DROP TABLE #Filelist;

                DECLARE @filecount INT,
                    @Filenr        INT;

                CREATE TABLE #Filelist
                (
                    Filecount INT,
                    FileNr INT,
                    objid INT,
                    Pathproperty_L1 NVARCHAR(128),
                    Pathproperty_L2 NVARCHAR(128),
                    Pathproperty_L3 NVARCHAR(128)
                );

                                SET @Params = N'@Objid int output, @process_Id int';
                SET @vquery = N'
                Insert into #Filelist
                (Filecount, Filenr, objid)

                SELECT  t.filecount, 1,t.ObjID
                FROM ' + QUOTENAME(@TableName) + N' AS t where process_ID = @Process_ID';

                EXEC sys.sp_executesql @vquery, @Params, @ObjID OUTPUT, @Process_id;

                SELECT @objid = MIN(objid) FROM #Filelist AS f

                SET @DebugText = N' %i ';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Objid id start';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjID);
                END;

                SET @Filenr = 1;


                SET @ProcedureStep = 'Loop Start';
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                WHILE @ObjID IS NOT NULL
                BEGIN --loop start

                SELECT @filecount = filecount, @Filenr = 1 FROM #Filelist AS f WHERE f.[objid] = @Objid

                    IF @filecount > 0
                    BEGIN
                        WHILE @Filenr <= @filecount 
                        BEGIN
                           Merge INTO #Filelist t
                            USING (SELECT 
                            @filecount AS Filecount, @Filenr AS Filenr, @ObjID AS [Objid] ) s
                            ON s.[Objid] = t.[objid] AND s.filenr = t.filenr
                            WHEN NOT MATCHED THEN INSERT
                            (FileCount, filenr, [objid])
                            VALUES 
                            (s.filecount, s.filenr, s.[objid])
                            ;

                            SELECT @Filenr =  @Filenr + 1;
                        END; -- filenr < filecount
                    END; -- filecount > 0

                  
                    SELECT @ObjID = (SELECT MIN(t.[ObjID])
                        FROM #Filelist AS t 
                        WHERE t.[ObjID] > @ObjID) ;                

                       Set @DebugText = ' %i'
                       Set @DebugText = @DefaultDebugText + @DebugText
                       Set @Procedurestep = 'next objid '
                       
                       IF @debug > 0
                       	Begin
                       		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep, @objid );
                       	END
                       
                    SET @Filenr = 1;
                END; --loop end

                SET @ProcedureStep = 'loop end';
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;


                IF @Debug > 0
                Begin
                    SELECT *
                    FROM #Filelist AS f;

                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
                
                -------------------------------------------------------------
                -- Add values of columns for each object
                -------------------------------------------------------------

IF (@PathProperty_L1 IS NOT NULL AND @PathProperty_L2 IS NOT NULL AND @PathProperty_L3 IS NOT NULL)
BEGIN -- all paths define
SET @vquery = N'
UPDATE f
SET PathProperty_L1 = ' + QUOTENAME(@PathProperty_L1) +', PathProperty_L2 = '+ QUOTENAME(@PathProperty_L2) + ', PathProperty_L3 = ' + QUOTENAME(@PathProperty_L3)  + ' FROM ' + QUOTENAME(@TableName) + ' t
INNER JOIN #Filelist AS f
ON t.ObjID = f.objid'
END
ELSE IF (@PathProperty_L1 IS NOT NULL AND @PathProperty_L2 IS NOT NULL AND @PathProperty_L3 IS NULL) 
BEGIN  -- path 1, 2 defined
SET @vquery = N'
UPDATE f
SET PathProperty_L1 =  ' + QUOTENAME(@PathProperty_L1) +',PathProperty_L2 = '+ QUOTENAME(@PathProperty_L2) + ' FROM ' + QUOTENAME(@TableName) + ' t
INNER JOIN #Filelist AS f
ON t.ObjID = f.objid'
END
ELSE IF (@PathProperty_L1 IS NOT NULL AND @PathProperty_L2 IS NULL AND @PathProperty_L3 IS NULL) 
BEGIN -- path 1 defined
SET @vquery = N'
UPDATE f
SET PathProperty_L1 =  ' + QUOTENAME(@PathProperty_L1) +' FROM ' + QUOTENAME(@TableName) + ' t
INNER JOIN #Filelist AS f
ON t.ObjID = f.objid'
END

--IF @debug > 0
--PRINT @vquery;

EXEC (@vquery)

IF @debug > 0
begin
SELECT * FROM #Filelist AS f;
end
-------------------------------------------------------------
-- Replace folder special characters
-------------------------------------------------------------
UPDATE f 
SET f.Pathproperty_L1 = dbo.fnMFReplaceSpecialCharacter(f.Pathproperty_L1),
f.Pathproperty_L2 = dbo.fnMFReplaceSpecialCharacter(f.Pathproperty_L2),
f.Pathproperty_L3 = dbo.fnMFReplaceSpecialCharacter(f.Pathproperty_L3)      
FROM #Filelist AS f

IF @debug > 0
begin
SELECT * FROM #Filelist AS f;
END

Set @DebugText = ''
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Add path property values'

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END

-------------------------------------------------------------
                -- Create #ExportFile 
                -------------------------------------------------------------
                SET @ProcedureStep = 'Create #ExportFiles ';

                /* for testing
 DECLARE @TableName NVARCHAR(258) = 'MFOtherDocument'
DECLARE @process_ID_text VARCHAR(5) = '0'
DECLARE @DeletedColumn NVARCHAR(100) = 'Deleted'
DECLARE @IncludeDocID INT = 0;
DECLARE @FilePath nvarchar(100) = 'C:\MFSQL\FileExport'
DECLARE @IsValidProperty_L1 INT = 1
DECLARE @IsValidProperty_L2 INT = 1
DECLARE @IsValidProperty_L3 INT = 1
DECLARE @Vquery nvarchar(MAX)
DECLARE @Params NVARCHAR(MAX)
DECLARE @Isdownload BIT = 0 
 */
                SELECT @process_ID_text = CAST(@Process_id AS VARCHAR(10));

                IF
                (
                    SELECT OBJECT_ID('Tempdb..#ExportFiles')
                ) IS NOT NULL
                    DROP TABLE #ExportFiles;

                CREATE TABLE #ExportFiles
                (
                    ClassID INT,
                    ObjID INT,
                    ObjType INT,
                    MFVersion INT,
                    Single_file INT,
                    FileNr INT,
                    MultiFolder NVARCHAR(258),
                    FilePath NVARCHAR(258),
                    IsDownload BIT,
                    IncludeDocID BIT,
                    FileName NVARCHAR(258),
                    FileCheckSum NVARCHAR(1000),
                    FileCount INT,
                    FileObjectID INT,
                    Extension NVARCHAR(100),
                    FileSize INT
                );

                SET @Params
                    = N'
@ClassID int,
@ObjType int,
@IncludeDocID int,
@FilePath nvarchar(100),
 @IsValidProperty_L1 INT ,
 @IsValidProperty_L2 INT ,
 @IsValidProperty_L3 INT ,
 @Isdownload bit
'               ;
                SET @vquery
                    = N'
 INSERT INTO #ExportFiles
                (
                    ClassID ,
                    ObjID ,
                    ObjType,
                    MFVersion,
                    Single_file ,
                    FileNr ,
                    MultiFolder,
                    FilePath ,
                    IsDownload ,
                    IncludeDocID 
                )
Select distinct @ClassID, t.ObjID, @ObjType, t.MFVersion,t.Single_File, fl.FileNr ,
FileName = 
case when t.Single_File = 1 then null
when t.Single_File = 0 and @IncludeDocID = 1 then ''\'' + dbo.fnMFReplaceSpecialCharacter(Name_or_title) + '' (ID''  + CAST(t.ObjID AS VARCHAR(10))+'')''
when t.Single_File = 0 and @IncludeDocID = 0 then 
''\'' + dbo.fnMFReplaceSpecialCharacter(Name_or_title)
END,
FilePath = case when single_file = 1 then  @Filepath + isnull(PathProperty_L1,''*'') + ''\'' +  isnull(PathProperty_L2,''*'') + ''\'' +  isnull(PathProperty_L3,''*'') 
else  @Filepath + isnull(PathProperty_L1,''*'') + ''\'' +  isnull(PathProperty_L2,''*'') + ''\'' +  isnull(PathProperty_L3,''*'') + ''\'' + dbo.fnMFReplaceSpecialCharacter(Name_or_title)
end
,

@IsDownload,@IncludeDocID 
  from [' +     @TableName + N'] as t
  inner join #Filelist fl
  on t.objid = fl.objid
  WHERE Process_ID = ' + @process_ID_text + N' AND ' + QUOTENAME(@DeletedColumn) + N' is null
  and Filenr = 1'
  
  ;
                SET @DebugText = N'Vquery ';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Prepare query ';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                          --IF @Debug > 0
                          --      PRINT @vquery;
                ;

                SET @ProcedureStep = 'Insert into #ExportFiles';

                EXEC sys.sp_executesql @stmt = @vquery,
                    @param = @Params,
                    @ClassID = @ClassID,
                    @ObjType = @ObjType,
                    @IncludeDocID = @IncludeDocID,
                    @IsValidProperty_L1 = @IsValidProperty_L1,
                    @IsValidProperty_L2 = @IsValidProperty_L2,
                    @IsValidProperty_L3 = @IsValidProperty_L3,
                    @Filepath = @FilePath,
                    @IsDownload = @IsDownload;

                SET @RC = @@RowCount;
                SET @DebugText = N' RowCount %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RC);
                END;

                IF @Debug > 100
                    SELECT *
                    FROM #ExportFiles AS ef;

                -------------------------------------------------------------
                -- create input XML
                -------------------------------------------------------------
                SET @ProcedureStep = 'Create input XML';

                DECLARE @XML NVARCHAR(MAX);

                SET @XML =
                (
                    SELECT @ClassID       AS [ObjectFilesItem/@ClassID],
                        @ObjType          AS [ObjectFilesItem/@ObjType],
                        moch.ObjID        AS [ObjectFilesItem/@ObjID],
                        moch.MFVersion    AS [ObjectFilesItem/@ObjVersion],
                        moch.IsDownload   AS [ObjectFilesItem/@IsDownload],
                        moch.IncludeDocID AS [ObjectFilesItem/@IncludeDocID],
                        REPLACE(moch.FilePath,'\*','') + '\'    AS [ObjectFilesItem/@FilePath]
                    FROM #ExportFiles AS moch
                    ORDER BY moch.ObjID
                    FOR XML PATH(''), ROOT('ObjectFilesList')
                );
                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                 BEGIN
                    SELECT CAST(@XML AS XML) inputXML;              
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                DECLARE @XMLInput NVARCHAR(MAX);

                SELECT @XMLInput = CAST(@XML AS NVARCHAR(MAX));

                -------------------------------------------------------------
                -- Call Wrapper
                -------------------------------------------------------------
                SET @ProcedureStep = 'Wrapper spMFGetFilesListInternal ';

                EXEC dbo.spMFGetFilesListInternal @VaultSettings,
                    @XMLInput,
                    @IsDownload,
                    @IncludeDocID,
                    @FileExport OUT;

                /*
                -----------------------------------------------------------------------------
                SET @ProcedureStep = 'Loop to get files';

                DECLARE @FullFilePath NVARCHAR(258);

                SELECT @ObjID = MIN(ef.ObjID)
                FROM #ExportFiles AS ef;

                WHILE @ObjID IS NOT NULL
                BEGIN
                    SELECT @MFVersion = ef.MFVersion,
                        @FullFilePath = ef.FilePath + N'\'
                    FROM #ExportFiles AS ef
                    WHERE ef.ObjID = @ObjID;

                    -------------------------------------------------------------------
                    --- Calling  the CLR StoredProcedure to Download file for @ObJID
                    -------------------------------------------------------------------
                    SET @ProcedureStep = 'Calling CLR GetFilesInternal';
                    SET @DebugText = N'Get files for %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjID);
                    END;

                    DECLARE @IsDownloadText NVARCHAR(5);

                    SET @IsDownloadText = CAST(@IsDownload AS VARCHAR(4));

                    EXEC dbo.spMFGetFilesInternal @VaultSettings,
                        @ClassID,
                        @ObjID,
                        @ObjType,
                        @MFVersion,
                        @FullFilePath,
                        @IsDownloadText,
                        @IncludeDocIDTemp,
                        @FileExport OUT;

*/
                SET @ProcedureStep = ' Return from wrapper ';

                IF @Debug > 0
                BEGIN
               --    SELECT @FileExport
                    SELECT CAST(@FileExport AS XML) AS FileExport;
                END;

                --    IF @FileExport IS NULL
                SET @DebugText = N' ';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                DECLARE @XmlOut XML;

                SET @XmlOut = @FileExport;
                SET @ProcedureStep = 'Reset process_ID ';

                --             EXEC ('Update ' + @TableName + ' set Process_ID=0 where ObjID=' + 'cast(' + @ObjID + 'as varchar(10))');
                SET @ProcedureStep = 'Update ExportFiles with return ';

                UPDATE ef
                SET ef.FileName = t.c.value('(@FileName)[1]', 'NVARCHAR(400)'),
                    ef.FileCheckSum = t.c.value('(@FileCheckSum)[1]', 'nvarchar(1000)'),
                    ef.FileCount = t.c.value('(@FileCount)[1]', 'INT'),
                    ef.FileObjectID = t.c.value('(@FileObjectID)[1]', 'INT'),
                    ef.Extension = t.c.value('(@Extension)[1]', 'nvarchar(100)'),
                    ef.FileSize = t.c.value('(@FileSize)[1]', 'INT')
                FROM @XmlOut.nodes('/document/Files/FileItem') AS t(c)
                    INNER JOIN #Filelist              AS f
                        ON t.c.value('(@ObjID)[1]', 'INT') = f.objid
                    INNER JOIN #ExportFiles           AS ef
                        ON ef.ObjID = f.objid;
 --                          AND ef.FileNr = f.FileNr;

                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @Debug > 10
                BEGIN
                    SELECT * FROM #ExportFiles AS ef
                    INNER JOIN #Filelist  AS ef2
                    ON ef.ObjID = ef2.ObjID 
                END;


                SET @ProcedureStep = ' Update table MFExportfilehistory ';

                MERGE INTO dbo.MFExportFileHistory t
                USING
                (
                    SELECT distinct ef.ClassID,
                        ef.ObjID,
                        ef.ObjType,
                        ef.MFVersion,
                        ef.Single_file,
                        ef.FileNr,
                        ef.MultiFolder   AS MultiDocFolder,
                        ef.FilePath,
                        ef.IsDownload,
                        ef.IncludeDocID,
                        ef.FileName,
                        ef.FileCheckSum,
                        ef.FileCount,
                        ef.FileObjectID,
                        ef.Extension,
                        ef.FileSize,
                        @FilePath     AS FileExportRoot,
                        ef2.PathProperty_L1 AS subFolder_1,
                        ef2.PathProperty_L2 AS subFolder_2,
                        ef2.PathProperty_L3 AS subFolder_3
                    FROM #ExportFiles AS ef
                    INNER JOIN #Filelist  AS ef2
                    ON ef.ObjID = ef2.ObjID 
                ) S
                ON t.ClassID = S.ClassID
                   AND t.ObjID = S.ObjID
                   AND t.FileName = S.FileName
                WHEN NOT MATCHED THEN
                    INSERT
                    (
                        FileExportRoot,
                        SubFolder_1,
                        SubFolder_2,
                        SubFolder_3,
                        FileName,
                        ClassID,
                        ObjID,
                        ObjType,
                        Version,
                        MultiDocFolder,
                        FileCheckSum,
                        FileCount,
                        FileObjectID,
                        FileExtension,
                        FileSize
                    )
                    VALUES
                    (S.FileExportRoot, S.subFolder_1, S.subFolder_2, S.subFolder_3, S.FileName, S.ClassID, S.ObjID,
                        S.ObjType, S.MFVersion, S.MultiDocFolder, S.FileCheckSum, S.FileCount, S.FileObjectID,
                        S.Extension, S.FileSize)
                WHEN MATCHED THEN
                    UPDATE SET t.FileExportRoot = S.FileExportRoot,
                        t.SubFolder_1 = S.subFolder_1,
                        t.SubFolder_2 = S.subFolder_2,
                        t.SubFolder_3 = S.subFolder_3,
                        t.Version = S.MFVersion,
                        t.MultiDocFolder = S.MultiDocFolder,
                        t.FileCount = S.FileCount,
                        t.Created = GETDATE(),
                        t.FileObjectID = S.FileObjectID,
                        t.FileExtension = S.Extension,
                        t.FileSize = S.FileSize;

                SET @RC = @@RowCount;
                SET @DebugText = N'Updated %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RC);
                END;

                SET @ProcedureStep = 'Update process_ID';
                SET @vquery = N'Update  MFT  set Process_id = 0
									From ' + @TableName + N' MFT 
									where process_id = @process_ID';

                --IF @Debug > 0
                --    PRINT @vquery;

                EXEC sys.sp_executesql @vquery, N'@process_id int', @Process_id;

                SET @RC = @@RowCount;
                SET @DebugText = N'Updated %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RC);
                END;

                /*
                    SELECT @ObjID =
                    (
                        SELECT MIN(ef.ObjID) FROM #ExportFiles AS ef WHERE ef.ObjID > @ObjID 
                    );
                END; --end while
*/
                SET @StartTime = GETUTCDATE();
                SET @LogTypeDetail = N'Updated files';
                SET @LogTextDetail = @ProcedureName;
                SET @LogStatusDetail = N'Completed';
                SET @Validation_ID = NULL;
                SET @LogColumnValue = N'';
                SET @LogColumnValue = N'';

                EXECUTE @RC = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

                RETURN 1;
            END; -- rootfolder
        END; -- class table
    END TRY
    BEGIN CATCH
        --       EXEC ('Update ' + @TableName + ' set Process_ID=3 where ObjID=' + 'cast(' + @ObjID + 'as varchar(10))');
        INSERT INTO dbo.MFLog
        (
            SPName,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ProcedureStep,
            ErrorState,
            ErrorSeverity,
            Update_ID,
            ErrorLine
        )
        VALUES
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE(),
            ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

        SET NOCOUNT OFF;
    END CATCH;
END;
GO