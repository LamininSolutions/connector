PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
      + '.[dbo].[spMFSynchronizeValueListItemsToMfiles]';
GO

SET NOCOUNT ON;
EXEC Setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFSynchronizeValueListItemsToMFiles',
                                 -- nvarchar(100)
                                 @Object_Release = '4.6.15.56',
                                 -- varchar(50)
                                 @UpdateFlag = 2;
-- smallint

GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINES.ROUTINE_NAME = 'spMFSynchronizeValueListItemsToMFiles' --name of procedure
          AND ROUTINES.ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINES.ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFSynchronizeValueListItemsToMFiles
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO



ALTER PROCEDURE dbo.spMFSynchronizeValueListItemsToMFiles
(
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=====================================
spMFSynchronizeValueListItemsToMfiles
=====================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table    
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

The purpose of this procedure is to synchronize Sql  MFVALUELISTITEM table to M-files. All items with process_id <> 0 will be considered for updating

Additional Info
===============

Set process_id = 1 to update valuelist item or create new
Set process_id = 2 to delete valuelist item

The name, owner, or display_id of the valuelist item can be changed.

The Valuelistid column in MFValuelistItems refers to the id in the MFValuelist table.

Prerequisites
=============

All items where process_id is 1 or 2 will be included in the update.  Set the process_id for the items to be update before running this procedure

When inserting a new valuelist item the minumum required columns in the table MFValuelistItems are: Name, ValuelistID and process_id


Examples
========

.. code:: sql

    Exec spMFSynchronizeValueListItemsToMfiles

------------------

When updating valulist items from SQL to MF, then synchronising only valuelist items for a specific valuelist becomes very useful

.. code:: sql

	EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'ValuelistItems'

	--or

	EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'ValuelistItem' 
											   , @ItemName = 'Country'

-----------

Create a specific valuelist lookup with the schema 'custom' and a naming convention of the the view that is distinct to improve the use of valuelists and valuelist items in procedures.

.. code:: sql

    EXEC dbo.spMFCreateValueListLookupView @ValueListName = N'Country', 
                                       @ViewName = N'vwCountry',    
                                       @Schema = N'custom',       
                                       @Debug = 0         
	SELECT * FROM   custom.vwCountry

--------------

CHANGING THE NAME OF VALUELIST ITEM (name, owner, DisplayID)

.. code:: sql

	UPDATE [mvli]
	SET	   [Process_ID] = 1
		 , [mvli].[Name] = 'UK'
		 , [DisplayID] = '3'
	FROM   [MFValuelistitems] [mvli]
	INNER JOIN [vwMFCountry] [vc] ON [vc].[AppRef_ValueListItems] = [mvli].[appref]
	WHERE  [mvli].[AppRef] = '2#154#3'

--------------

INSERT NEW VALUE LIST ITEM (note only name process_id and valuelist id is required); display_id must be unique, if not set it will default to the mfid

.. code:: sql

	DECLARE @Valuelist_ID INT
	SELECT @Valuelist_ID = [id]
	FROM   [dbo].[MFValueList]
	WHERE  [name] = 'Country'

	INSERT INTO [MFValueListItems] (   [Name]
									 , [Process_ID]
									 , [DisplayID]
									 , [MFValueListID]
								   )
	VALUES ( 'Russia', 1, 'RU', @Valuelist_ID )


	INSERT INTO [MFValueListItems] (   [Name]
									 , [Process_ID]
									 , [MFValueListID]
								   )
	VALUES ( 'Argentina', 1, @Valuelist_ID )

----------------

DELETE VALUELIST ITEM (note that the procedure will delete the valuelist item only and not the related objects)
the record will not be deleted from the table, however, the deleted column will be set to 1.

.. code:: sql

	UPDATE [mvli]
	SET	   [Process_ID] = 2
	FROM   [MFValuelistitems] [mvli]
	WHERE  [mvli].[AppRef] = '2#154#9'

    
Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-02-20  LC         Add set IsnameUpdate = 1 when update take place
2020-01-10  LC         Improve documentation, add debubbing
2019-08-30  JC         Added documentation
2018-04-04  DEV2       Added Licensing module validation code
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
DECLARE @MFTableName AS NVARCHAR(128) = N'';
DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = ISNULL(@ProcessType, 'Update Valuelist Items');

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
DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFSynchronizeValueListItemsToMFiles';
DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = N'';
DECLARE @Msg AS NVARCHAR(256) = N'';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

-------------------------------------------------------------
-- VARIABLES: LOGGING
-------------------------------------------------------------
DECLARE @LogType AS NVARCHAR(50) = N'Status';
DECLARE @LogText AS NVARCHAR(4000) = N'';
DECLARE @LogStatus AS NVARCHAR(50) = N'Started';

DECLARE @LogTypeDetail AS NVARCHAR(50) = N'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = N'';
DECLARE @LogStatusDetail AS NVARCHAR(50) = N'In Progress';
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
SET @ProcedureStep = N'Start Logging';

SET @LogText = N'Processing ' + @ProcedureName;

EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                 @ProcessType = @ProcessType,
                                 @LogType = N'Status',
                                 @LogText = @LogText,
                                 @LogStatus = N'In Progress',
                                 @Debug = @Debug;


EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                       @LogType = N'Debug',
                                       @LogText = @ProcessType,
                                       @LogStatus = N'Started',
                                       @StartTime = @StartTime,
                                       @MFTableName = @MFTableName,
                                       @Validation_ID = @Validation_ID,
                                       @ColumnName = NULL,
                                       @ColumnValue = NULL,
                                       @Update_ID = @Update_ID,
                                       @LogProcedureName = @ProcedureName,
                                       @LogProcedureStep = @ProcedureStep,
                                       @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT,
                                       @Debug = 0;


BEGIN TRY
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- BEGIN PROCESS
    -------------------------------------------------------------
    SET @DebugText = N'';
    SET @DefaultDebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Process start'

    DECLARE @ID INT, @VaultSettings NVARCHAR(4000)


    CREATE TABLE #TempMFID
    (
        ID INT
    );
    IF (@Debug = 1)
        PRINT '#TempMFID is Created';
    ------------------------------------------------------------------------
    --Getting Vault settings
    SET @ProcedureStep = N'Get Vault settings';

    SELECT @VaultSettings = dbo.FnMFVaultSettings();

    SET @ProcedureStep = N'Get items to update';

    SET @Count = 0;
    IF (@Debug = 1)
        PRINT 'Inserting Process_ID!=0 records into #TempMFID';

    INSERT INTO #TempMFID
    (
        ID
    )
    SELECT MVLI.ID,*
    FROM dbo.MFValueListItems MVLI
        INNER JOIN dbo.MFValueList MVL
            ON MVLI.MFValueListID = MVL.ID
               AND MVL.MFID > 100
    WHERE MVLI.Process_ID != 0
          AND MVLI.Deleted = 0;


    -------------------------------------------------------------
    -- license check
    -------------------------------------------------------------
    SET @ProcedureStep = N'License Check';
    EXEC dbo.spMFCheckLicenseStatus 'spMFSynchronizeValueListItemsToMFilesInternal',
                                    @ProcedureName,
                                    @ProcedureStep;

    -------------------------------------------------------------
    -- Start cursor
    -------------------------------------------------------------   
    SET @ProcedureStep = N'Start update cursor';

    DECLARE SynchValueLIstItemCursor CURSOR LOCAL FOR
    ----------------------------------------------------
    --Select ID From MFValuelistItem Table 
    -----------------------------------------------------
    SELECT ID
    FROM #TempMFID;

    OPEN SynchValueLIstItemCursor;

    ----------------------------------------------------------------
    --Select The ValueListId into declared variable '@vlaueListID' 
    ----------------------------------------------------------------
    FETCH NEXT FROM SynchValueLIstItemCursor
    INTO @ID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Xml NVARCHAR(MAX),
                @Result NVARCHAR(MAX);

        ------------------------------------------------------------------------
        --Creating xml of ValueListItem which going to synch in M-Files

        DECLARE @MFValueListID INT,
                @DisplayIDProp NVARCHAR(200),
                @Name NVARCHAR(200);
        DECLARE @ErrMsg NVARCHAR(500),
                @ValueListName NVARCHAR(200);
        SELECT @MFValueListID = MVLI.MFValueListID,
               @DisplayIDProp = MVLI.DisplayID,
               @Name = Name
        FROM MFValueListItems MVLI
        WHERE ID = @ID;


        IF EXISTS
        (
            SELECT *
            FROM MFValueListItems
            WHERE ID != @ID
                  AND MFValueListID = @MFValueListID
                  AND Name = @Name
        )
        BEGIN

            SELECT @ValueListName = Name
            FROM MFValueList
            WHERE ID = @MFValueListID;

            SELECT @ErrMsg
                = N'ValueListItem can not be added with Duplicate Name property= ' + @Name + N' for ValueList '
                  + @ValueListName;

            SET @DebugText = @ErrMsg;
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Duplicate name validation';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, @MsgSeverityGeneralError, 1, @ProcedureName, @ProcedureStep);
            END;

        END;

        SET @ProcedureStep = 'Validations'
        IF EXISTS
        (
            SELECT *
            FROM MFValueListItems
            WHERE ID != @ID
                  AND MFValueListID = @MFValueListID
                  AND DisplayID = @DisplayIDProp
        )
        BEGIN

            SELECT @ValueListName = Name
            FROM MFValueList
            WHERE ID = @MFValueListID;

            SELECT @ErrMsg
                = N'ValueListItem can not be added with Duplicate DisplayID property= ' + @DisplayIDProp
                  + N' for ValueList ' + @ValueListName;

            SET @DebugText = @ErrMsg;
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = N'Duplicate DisplayID validation';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, @MsgSeverityGeneralError, 1, @ProcedureName, @ProcedureStep);
            END;



        END;

        -------------------------------------------------------------
        -- Prepare XML
        -------------------------------------------------------------
        SET @ProcedureStep = N'Prepare XML';

        SET @Xml =
        (
            SELECT MVLI.ID AS 'ValueListItem/@Sql_ID',
                   MVL.MFID AS 'ValueListItem/@MFValueListID',
                   MVLI.MFID AS 'ValueListItem/@MFID',
                   MVLI.Name AS 'ValueListItem/@Name',
                   MVLI.OwnerID AS 'ValueListItem/@Owner',
                   MVLI.DisplayID AS 'ValueListItem/@DisplayID',
                   MVLI.ItemGUID AS 'ValueListItem/@ItemGUID',
                   MVLI.Process_ID AS 'ValueListItem/@Process_ID'
            FROM dbo.MFValueListItems MVLI
                INNER JOIN dbo.MFValueList MVL
                    ON MVLI.MFValueListID = MVL.ID
            WHERE MVLI.ID = @ID
            FOR XML PATH(''), ROOT('VLItem')
        );

        IF @Debug > 10
            SELECT @Xml AS 'inputXML';

        SET @DebugText = N'';
        SET @DefaultDebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------------------

        -- Calling CLR Procedure to synch items into M-Files from sql
        -----------------------------------------------------------------
        SET @ProcedureStep = 'Call wrapper'
        --print @Xml
        EXEC dbo.spMFSynchronizeValueListItemsToMFilesInternal @VaultSettings,
                                                               @Xml,
                                                               @Result OUTPUT;
        -----------------------------------------------------------------------
        DECLARE @XmlOut XML;
        SET @XmlOut = @Result;

        IF @Debug > 10
            SELECT @XmlOut AS 'outputXML';

Set @DebugText = ''
Set @DefaultDebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Process wrapper results'

IF @debug > 0
	Begin
		RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
	END

        CREATE TABLE #ValueListItemTemp
        (
            Name VARCHAR(100), --COLLATE Latin1_General_CI_AS
            MFID VARCHAR(20),  --COLLATE Latin1_General_CI_AS
            MFValueListID INT,
            OwnerID INT,
            DisplayID NVARCHAR(200),
            ItemGUID NVARCHAR(200)
        );

        INSERT INTO #ValueListItemTemp
        (
            Name,
            MFValueListID,
            MFID,
            OwnerID,
            DisplayID,
            ItemGUID
        )
        SELECT t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME,
               t.c.value('(@MFValueListID)[1]', 'INT') AS MFValueListID,
               t.c.value('(@MFID)[1]', 'INT') AS MFID,
               t.c.value('(@Owner)[1]', 'INT') AS OwnerID,
               t.c.value('(@DisplayID)[1]', 'nvarchar(200)'),
               t.c.value('(@ItemGUID)[1]', 'nvarchar(200)')
        FROM @XmlOut.nodes('/VLItem/ValueListItem') AS t(c);

        DECLARE @ProcessID INT;

        SELECT @ProcessID = MFValueListItems.Process_ID
        FROM dbo.MFValueListItems
        WHERE MFValueListItems.ID = @ID;

  -------------------------------------------------------------
  -- process deletions
  -------------------------------------------------------------
  Set @DebugText = ''
  Set @DefaultDebugText = @DefaultDebugText + @DebugText
  Set @Procedurestep = 'Process Deletions'
  
  IF @debug > 0
  	Begin
  		RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
  	END
  
  IF @ProcessID = 2
        BEGIN
            UPDATE dbo.MFValueListItems
            SET MFValueListItems.Deleted = 1
            WHERE MFValueListItems.ID = @ID;
        END;



  -------------------------------------------------------------
  -- Reset table: process_id
  -------------------------------------------------------------
  
Set @DebugText = ''
Set @DefaultDebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'reset process id'

IF @debug > 0
	Begin
		RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
	END

        --------------------Set Process_ID=0 after synch ValueListItem--------------
        UPDATE dbo.MFValueListItems
        SET MFValueListItems.Process_ID = 0, IsNameUpdate = 1
        WHERE MFValueListItems.ID = @ID;

        --------------------set MFID and GUID and DisplayID--------------------------

        DECLARE @OwnerID INT,
                @MFID INT,
                @DisplayID NVARCHAR(400),
                @ItemGUID NVARCHAR(400),
                @ValueListMFID INT;

        SELECT @ValueListMFID = MFVL.MFID
        FROM MFValueListItems MFVLI
            INNER JOIN MFValueList MFVL
                ON MFVLI.MFValueListID = MFVL.ID
        WHERE MFVLI.ID = @ID;

        SELECT @MFID = MFValueListItems.MFID
        FROM dbo.MFValueListItems
        WHERE MFValueListItems.ID = @ID;

        IF @MFID = 0
           OR @MFID IS NULL
        BEGIN
            SELECT @OwnerID = OwnerID,
                   @MFID = MFID,
                   @DisplayID = DisplayID,
                   @ItemGUID = ItemGUID
            FROM #ValueListItemTemp;

            UPDATE dbo.MFValueListItems
            SET -- [MFValueListItems].[OwnerID] = @OwnerID
                MFValueListItems.MFID = @MFID,
                MFValueListItems.DisplayID = @DisplayID,
                MFValueListItems.ItemGUID = @ItemGUID,
                MFValueListItems.AppRef = CASE
                                              WHEN OwnerID = 7 THEN
                                                  '0#'
                                              WHEN OwnerID = 0 THEN
                                                  '2#'
                                              WHEN OwnerID IN
                                                   (
                                                       SELECT MFValueList.MFID FROM dbo.MFValueList
                                                   ) THEN
                                                  '2#'
                                              ELSE
                                                  '1#'
                                          END + CAST(@ValueListMFID AS NVARCHAR(5)) + '#' + CAST(@MFID AS NVARCHAR(10)),
                MFValueListItems.Owner_AppRef = CASE
                                                    WHEN OwnerID = 7 THEN
                                                        '0#'
                                                    WHEN OwnerID = 0 THEN
                                                        '2#'
                                                    WHEN OwnerID IN
                                                         (
                                                             SELECT MFValueList.MFID FROM dbo.MFValueList
                                                         ) THEN
                                                        '2#'
                                                    ELSE
                                                        '1#'
                                                END + CAST(OwnerID AS NVARCHAR(5)) + '#'
                                                + CAST(OwnerID AS NVARCHAR(10))
            WHERE ID = @ID;
        END;
-------------------------------------------------------------
-- drop tables
-------------------------------------------------------------
Set @DebugText = ''
Set @DefaultDebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Closing cursor'

IF @debug > 0
	Begin
		RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
	END


        DROP TABLE #ValueListItemTemp;

        SET @Count = @Count + 1;
        FETCH NEXT FROM SynchValueLIstItemCursor
        INTO @ID;
    END;

    -----------------------------------------------------
    --Close the Cursor 
    -----------------------------------------------------
    CLOSE SynchValueLIstItemCursor;

    -----------------------------------------------------
    --Deallocate the Cursor 
    -----------------------------------------------------
    DEALLOCATE SynchValueLIstItemCursor;
    DROP TABLE #TempMFID;


    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = N'End';
    SET @LogStatus = N'Completed';
    -------------------------------------------------------------
    -- Log End of Process
    -------------------------------------------------------------   

    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Message',
                                     @LogText = @LogText,
                                     @LogStatus = @LogStatus,
                                     @Debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                           @LogType = N'Debug',
                                           @LogText = @ProcessType,
                                           @LogStatus = @LogStatus,
                                           @StartTime = @StartTime,
                                           @MFTableName = @MFTableName,
                                           @Validation_ID = @Validation_ID,
                                           @ColumnName = NULL,
                                           @ColumnValue = NULL,
                                           @Update_ID = @Update_ID,
                                           @LogProcedureName = @ProcedureName,
                                           @LogProcedureStep = @ProcedureStep,
                                           @Debug = 0;
    RETURN 1;
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
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
     @ProcedureStep);

    SET @ProcedureStep = N'Catch Error';
    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                     @ProcessType = @ProcessType,
                                     @LogType = N'Error',
                                     @LogText = @LogTextDetail,
                                     @LogStatus = @LogStatus,
                                     @Debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
                                           @Debug = 0;

    RETURN -1;
END CATCH;

GO

