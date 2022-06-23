
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTable]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFUpdateTable',
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
    WHERE ROUTINE_NAME = 'spMFUpdateTable' --name of procedure
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
CREATE PROCEDURE dbo.spMFUpdateTable
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateTable
(
    @MFTableName NVARCHAR(200),
    @UpdateMethod INT,               --0=Update from SQL to MF only; 
                                     --1=Update new records from MF; 
                                     --2=initialisation 
    @UserId NVARCHAR(200) = NULL,    --null for all user update
    @MFModifiedDate DATETIME = NULL, --NULL to select all records
    @ObjIDs NVARCHAR(MAX) = NULL,
    @Update_IDOut INT = NULL OUTPUT,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @SyncErrorFlag BIT = 0,          -- note this parameter is auto set by the operation 
    @RetainDeletions BIT = 0,        --   @UpdateMetadata BIT = 0
    @IsDocumentCollection BIT = 0,   -- =1 will process only document collections for the class
    @Debug SMALLINT = 0
)
AS

/*rST**************************************************************************

===============
spMFUpdateTable
===============

Return
  - 1 = Success
  - 0 = Partial (some records failed to be inserted)
  - -1 = Error
Parameters
  @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @Updatemethod
    - 0 = update from SQL to M-Files
    - 1 = update from M-Files to SQL
  @User_ID (optional)
    - Default = 0
    - User_Id from MX_User_Id column
    - This is NOT the M-Files user.  It is used to set and apply a user_id for a third party system. An example is where updates from a third party system must be filtered by the third party user (e.g. placing an order)
  @MFLastModified (optional)
    - Default = 0
    - Get objects from M-Files that has been modified in M-files later than this date.
  @ObjIDs (optional)
    - Default = null
    - ObjID's of records (separated by comma) e.g. : '10005,13203'
    - Restricted to 4000 charactes including the commas
  @Update_IDOut (optional, output)
    Output id of the record in MFUpdateHistory logging the update ; Also added to the record in the Update_ID column on the class table
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @SyncErrorFlag (optional)
    - Default = 0
    - This parameter is automatically set by spMFUpdateSynchronizeError when synchronization routine is called.
  @RetainDeletions (optional)
    - Default = 0
    - Set to 1 to keep deleted items in M-Files in the SQL table shown as "deleted" or the label of property 27 with the date time of the deletion.
  @IsDocumentCollection (optional)
    - Default = 0 (use default object type for the class)
    - Set to 1 to process objects with object type 9 (document collection) for the class.
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

This procedure get and push data between M-Files and SQL based on a number of filters.  It is very likely that this procedure will be built into your application or own procedures as part of the process of creating, updating, inserting records from your application.

When calling this procedure in a query or via another procedure it will perform the update in batch mode on all the rows with a valid process_id.

When the requirements for transactional mode has been met and a record is updated/inserted in the class table with process_id = 1, a trigger will automatically fire spMFUpdateTable to update SQL to M-Files.

A number of procedures is included in the Connector that use this procedure including:
- spMFUpdateMFilesToSQL
- spMFUpdateTablewithLastModifiedDate
- spMFUpdateTableinBatches
- spMFUpdateAllIncludedInAppTables
- spMFUpdateItembyItem

By default the object type of the class will get the object type from the MFclass Table (using the default object type of the class).  To process Document collection objects for the class, the @IsDocumentCollection must be set to 1.  

Prerequisites
=============

From M-Files to SQL
-------------------
Process_id in class table must be 0. All other rows are ignored.


From SQL to M-Files - batch mode
--------------------------------
Process_id in class table must be 1 for rows to be updated or added to M-Files. All other rows are ignored.

Warnings
========

When using a filter (e.g. for a single object) to update the table with Update method 1 and the filter object process_id is not 0 then the filter will automatically revert to updating all records. Take care to pass valid filters before passing them into the procedure call.

This procedure will not remove destroyed objects from the class table.  Use spMFUpdateMFilestoMFSQL identify and remove destroyed object.

This procedure will not remove objects from the class table where the class of the object was changed in M-Files.  Use spMFUpdateMFilestoMFSQL to identify and remove these objects from the class table.

Deleted objects will only be removed if they are included in the filter 'Objids'.  Use spMFUpdateMFilestoMFSQL to identify deleted objects in general identify and update the deleted objects in the table.

Deleted objects in M-Files will automatically be removed from the class table unless @RetainDeletions is set to 1.

The valid range of real datatype properties for uploading from SQL to M-Files is -1,79E27 and 1,79E27

Examples
========

.. code:: sql

    DECLARE @return_value int

    EXEC    @return_value = [dbo].[spMFUpdateTable]
            @MFTableName = N'MFCustomerContact',
            @UpdateMethod = 1,
            @UserId = NULL,
            @MFModifiedDate = null,
            @update_IDOut = null,
            @ObjIDs = NULL,
            @ProcessBatch_ID = null,
            @SyncErrorFlag = 0,
            @RetainDeletions = 0,
            @Debug = 0

    SELECT  'Return Value' = @return_value

    GO

Execute the core procedure with all parameters

----

.. code:: sql

    DECLARE @return_value int
    DECLARE @update_ID INT, @processBatchID int

    EXEC @return_value = [dbo].[spMFUpdateTable]
         @MFTableName = N'YourTableName', -- nvarchar(128)
         @UpdateMethod = 1, -- int
         @Update_IDOut = @update_ID output, -- int
         @ProcessBatch_ID = @processBatchID output

    SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @processBatchID

    SELECT  'Return Value' = @return_value

Process document collection type objects for the class

----

.. code:: sql

    EXEC dbo.spMFUpdateTable @MFTableName = 'MFOtherDocument',
        @UpdateMethod = 1,
        @IsDocumentCollection = 1,
        @Debug = 101


Update from and to M-Files with all optional parameters set to default.

----

.. code:: sql

    --From M-Files to SQL
    EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer',
                                 @UpdateMethod = 1
    --or
    EXEC spMFupdateTable 'MFCustomer',1

    --From SQL to M-Files
    EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer',
                                 @UpdateMethod = 0
    --or
    EXEC spMFupdateTable 'MFCustomer',0

Update from and to M-Files with all optional parameters set to default.

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-06-01  LC         Resolve bug with data definition in large text properties
2022-03-23  LC         Add protection against locking when updating class table
2022-03-07  LC         Fix bug with not updating AuditTable
2022-02-08  LC         Further optimize, replace UNPIVOT with new case method
2022-02-06  LC         allow null to be passed in for properties   
2022-01-28  lc         Remove table scan when updatemethod 0
2022-01-26  LC         Resolve bug related to audit table deletions removal
2021-12-20  LC         Pair connection test with Wrapper
2021-06-21  LC         Modify proc to include document collections
2021-04-14  LC         fix timestamp datatype bug
2021-03-15  LC         fix changing of class in the same object type in MF
2021-03-11  LC         update maximum valid number range to between -1,79E27 and 1,79E27
2021-01-31  LC         Fix bug on insert new into audithistory
2020-11-28  LC         Improve collection of property ids
2020-11-28  LC         Resolve issue when fail message
2020-11-24  LC         New functionality to deal with changing of classes
2020-10-20  LC         Fix locationlisation for class_id 
2020-09-21  LC         Change column name Value to avoid conflict with property
2020-08-25  LC         Fix debugging and log messaging
2020-08-27  LC         Rework logic to deal with deleted objects
2020-08-29  LC         Update treatment of required workflow errors
2020-08-22  LC         Replace boolean column Deleted with property 27
2020-07-27  LC         Add handling of delete and check out status
2020-06-13  LC         Remove xml_document when transaction failed
2020-05-12  LC         Set last modified user to MFSQL
2020-04-20  LC         exclude last modified and and MF user to be modified
2020-03-09  LC         Resolve issue with timestamp format for finish formatting
2020-02-27  LC         Resolve issue with open XML_Docs
2020-01-06  LC         Resolve issue: variable is null: @RetainDeletions
2020-01-06  LC         Resolving performance bug when filtering on objids  
2019-12-31	DEV2	   New output parameter add in spMFCreateObjectInternal to return the checkout objects.
2019-10-01  LC         Allow for rounding where float has long decimals
2019-09-02  LC         Fix conflict where class table has property with 'Name' as the name V53
2019-08-24  LC         Fix label of audithistory table inserts
2019-07-26  LC         Update removing of redundant items form AuditHistory
2019-07-13  LC         Add working that not all records have been updated
2019-06-17  LC         UPdate MFaudithistory with changes
2019-05-19  LC         Terminate early if connection cannot be established
2019-01-13  LC         Fix bug for uniqueidentifyer type columns (e.g. guid)
2019-01-03  LC         Fix bug for updating time property
2018-12-18  LC         Validate that all records have been updated, raise error if not
2018-12-06  LC         Fix bug t.objid not found
2018-11-05  LC         Include new parapameter to validate class and property structure
2018-10-30  LC         Removing cursor method for update method 0 and reducing update time by 100%
2018-10-24  LC         Resolve bug when objids filter is used with only one object
2018-10-20  LC         Set Deleted to != 1 instead of = 0 to ensure new records where deleted is not set is taken INSERT
2018-08-23  LC         Fix bug with presedence = 1
2018-08-01  LC         Fix deletions of record bug
2018-08-01  LC         New parameter @RetainDeletions to allow for auto removal of deletions Default = NO
2018-06-26  LC         Improve reporting of return values
2018-05-16  LC         Fix conversion of float to nvarchar
2018-04-04  DEV2       Added Licensing module validation code.
2017-11-03  DEV2       Added code to check required property has value or not
2017-10-01  LC         Fix bug with length of fields
2017-08-23  DEV2       Add exclude null properties from update
2017-08-22  DEV2       Add sync error correction
2017-07-06  LC         Add update of filecount column in class table
2017-07-03  LC         Modify objids filter to include ids not in sql
2017-06-22  LC         Add ability to modify external_id
2107-05-12  LC         Set processbatchdetail column detail
2016-10-10  LC         Change of name of settings table
2016-09-21  LC         Removed @UserName,@Password,@NetworkAddress and @VaultName parameters and fectch it as comma separated list in @VaultSettings parameter dbo.fnMFVaultSettings() function
2016-08-22  LC         Change objids to NVARCHAR(4000)
2016-08-22  LC         Update settings index
2016-08-20  LC         Add Update_ID as output paramter
2016-08-18  LC         Add defaults to parameters
2016-03-10  DEV2       New input variable added (@ObjIDs)
2016-03-10  DEV2       Input variable @FromCreateDate  changed to @MFModifiedDate
2016-02-22  LC         Improve debugging information; Remove is_template message when updatemethod = 1
2015-07-18  DEV2       New parameter add in spMFCreateObjectInternal
2015-06-30  DEV2       New error Tracing and Return Value as LeRoux instruction
2015-06-24  DEV2       Skip the object failed to update in M-Files
2015-04-23  DEV2       Removing Last modified & Last modified by from Update data
2015-04-16  DEV2       Adding update table details to MFUpdateHistory table
2015-04-08  DEV2       Deleting property value from M-Files (Task 57)
==========  =========  ========================================================

**rST*************************************************************************/
DECLARE @Update_ID INT,
        @return_value INT = 1;

BEGIN TRY
    --BEGIN TRANSACTION
    SET NOCOUNT ON;

    SET XACT_ABORT ON;

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    DECLARE @Id INT,
            @objID INT,
            @ObjectIdRef INT,
            @ObjVersion INT,
            @VaultSettings NVARCHAR(4000),
            @TableName NVARCHAR(1000),
            @XmlOUT NVARCHAR(MAX),
            @NewObjectXml NVARCHAR(MAX),
            @ObjIDsForUpdate NVARCHAR(MAX),
            @FullXml XML,
            @SynchErrorObj NVARCHAR(MAX),  --Declared new paramater
            @DeletedObjects NVARCHAR(MAX), --Declared new paramater
            @ProcedureName sysname = 'spMFUpdateTable',
            @ProcedureStep sysname = 'Start',
            @ObjectId INT,
            @ClassId INT,
            @Table_ID INT,
            @ErrorInfo NVARCHAR(MAX),
            @Query NVARCHAR(MAX),
            @Params NVARCHAR(MAX),
            @SynchErrCount INT,
            @ErrorInfoCount INT,
            @MFErrorUpdateQuery NVARCHAR(1500),
            @MFIDs NVARCHAR(4000) = N'',
            @ExternalID NVARCHAR(200),
            @Count INT,
            @ObjidCount INT = 0,
            @CheckOutObjects NVARCHAR(MAX),
            @RemoveOtherClass SMALLINT = 0,
            @TempStatusList NVARCHAR(100);


    -----------------------------------------------------
    --DECLARE VARIABLES FOR LOGGING
    -----------------------------------------------------
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';
    DECLARE @LogTextDetail AS NVARCHAR(MAX) = N'';
    DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = N'';
    DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
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

    -----------------------------------------------------
    --GET LOGIN CREDENTIALS
    -----------------------------------------------------
    SET @ProcedureStep = 'Get Security Variables';

    DECLARE @Username NVARCHAR(2000);
    DECLARE @VaultName NVARCHAR(2000);

    SELECT TOP 1
           @Username = Username,
           @VaultName = VaultName
    FROM dbo.MFVaultSettings;

    SELECT @VaultSettings = dbo.FnMFVaultSettings();

    -------------------------------------------------------------
    -- set up temp table for status list
    -------------------------------------------------------------
    SELECT @TempStatusList = dbo.fnMFVariableTableName('##StatusList', DEFAULT);

    -------------------------------------------------------------
    -- Set process type
    -------------------------------------------------------------
    SELECT @ProcessType = CASE
                              WHEN @UpdateMethod = 0 THEN
                                  'UpdateMFiles'
                              ELSE
                                  'UpdateSQL'
                          END;

    -------------------------------------------------------------
    --	Create Update_id for process start 
    -------------------------------------------------------------
    SET @ProcedureStep = 'set Update_ID';
    SET @StartTime = GETUTCDATE();

    INSERT INTO dbo.MFUpdateHistory
    (
        Username,
        VaultName,
        UpdateMethod
    )
    VALUES
    (@Username, @VaultName, @UpdateMethod);

    SELECT @Update_ID = @@Identity;

    SELECT @Update_IDOut = @Update_ID;

    SET @ProcedureStep = 'Start ';
    SET @StartTime = GETUTCDATE();
    SET @ProcessType = @ProcedureName;
    SET @LogType = N'Status';
    SET @LogStatus = N'Started';
    SET @LogText = N'Update using Update_ID: ' + CAST(@Update_ID AS VARCHAR(10));

    IF @Debug > 9
    BEGIN
        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    EXECUTE @return_value = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                        @ProcessType = @ProcessType,
                                                        @LogType = @LogType,
                                                        @LogText = @LogText,
                                                        @LogStatus = @LogStatus,
                                                        @debug = @Debug;

    IF @Debug > 9
    BEGIN
        SET @DebugText = @DefaultDebugText + N' Update_ID %i';


        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Update_ID);
    END;

    -----------------------------------------------------------------
    -- Checking module access for CLR procdure  spMFCreateObjectInternal
    ------------------------------------------------------------------
    EXEC dbo.spMFCheckLicenseStatus 'spMFCreateObjectInternal',
                                    @ProcedureName,
                                    @ProcedureStep;

    -------------------------------------------------------------
    -- Get objids
    -------------------------------------------------------------
    SET @ProcedureStep = 'Get objids into table ';
    IF
    (
        SELECT OBJECT_ID('tempdb..#objidtable')
    ) IS NOT NULL
        DROP TABLE #Objidtable;

    CREATE TABLE #ObjidTable
    (
        objid INT PRIMARY KEY,
        Type INT
    );

    INSERT INTO #ObjidTable
    (
        objid,
        Type
    )
    SELECT fmpds.ListItem,
           1
    FROM dbo.fnMFParseDelimitedString(@ObjIDs, ',') AS fmpds;

    SELECT @ObjidCount = @@RowCount;

    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId, @ClassId, @ObjidCount);
    END;
    -----------------------------------------------------
    --Determine if any filter have been applied
    --if no filters applied then full refresh, else apply filters
    -----------------------------------------------------
    DECLARE @IsFullUpdate BIT;

    SELECT @IsFullUpdate = CASE
                               WHEN @UserId IS NULL
                                    AND @MFModifiedDate IS NULL
                                    AND @ObjidCount = 0 THEN
                                   1
                               ELSE
                                   0
                           END;

    -----------------------------------------------------
    --Convert @UserId to UNIQUEIDENTIFIER type
    -----------------------------------------------------
    SET @UserId = CONVERT(UNIQUEIDENTIFIER, @UserId);
    -----------------------------------------------------
    --Get Table_ID 
    -----------------------------------------------------
    SET @ProcedureStep = 'Get Table ID ';
    SET @TableName = @MFTableName;

    SELECT @Table_ID = object_id
    FROM sys.objects
    WHERE name = @MFTableName;

    IF @Table_ID IS NULL
    BEGIN
        SET @DebugText = N' Class table ' + @MFTableName + N' does not exist';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Table Exist?';

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;

    IF @Debug > 0
    BEGIN
        SET @DebugText = @DefaultDebugText + N'Table: %s ';

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName);
    END;

    -----------------------------------------------------
    --Get Object Type Id
    -----------------------------------------------------
    SET @ProcedureStep = 'Get Object Type and Class ';

    SELECT @ObjectIdRef = MFObjectType_ID,
           @ClassId = MFID
    FROM dbo.MFClass
    WHERE TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

    SELECT @ObjectId = CASE
                           WHEN @IsDocumentCollection = 1 THEN
                               9
                           ELSE
                               MFID
                       END
    FROM dbo.MFObjectType
    WHERE ID = @ObjectIdRef;

    IF @Debug > 0
    BEGIN
        SET @DebugText = @DefaultDebugText + N' ObjectType: %i';

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId);
    END;

    -----------------------------------------------------
    --Set class id
    -----------------------------------------------------
    SELECT @ClassId = MFID
    FROM dbo.MFClass
    WHERE TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

    IF @Debug > 0
    BEGIN
        SET @DebugText = @DefaultDebugText + N' Class: %i';

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassId);
    END;

    SET @ProcedureStep = 'Prepare Table ';
    SET @LogTypeDetail = N'Status';
    SET @LogStatusDetail = N'Debug';
    SET @LogTextDetail = N'For UpdateMethod ' + CAST(@UpdateMethod AS VARCHAR(10));
    SET @LogColumnName = N'UpdateMethod';
    SET @LogColumnValue = CAST(@UpdateMethod AS VARCHAR(10));

    EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

    -----------------------------------------------------
    --SELECT THE ROW DETAILS DEPENDS ON UPDATE METHOD INPUT
    -----------------------------------------------------
    SET @StartTime = GETUTCDATE();

    DECLARE @DeletedColumn NVARCHAR(100);

    SELECT @DeletedColumn = mp.ColumnName
    FROM dbo.MFProperty AS mp
    WHERE mp.MFID = 27;

    -------------------------------------------------------------
    -- PROCESS UPDATEMETHOD = 0
    -------------------------------------------------------------
    SET @ProcedureStep = 'process updatemethod 0';

    IF @UpdateMethod = 0 --- processing of process_ID = 1
    BEGIN
        DECLARE @SelectQuery NVARCHAR(MAX), --query snippet to count records
                @vquery AS NVARCHAR(MAX),   --query snippet for filter
                @ParmDefinition NVARCHAR(500);

        -------------------------------------------------------------
        -- Get localisation names for standard properties
        -------------------------------------------------------------
        DECLARE @Columnname NVARCHAR(100);
        DECLARE @lastModifiedColumn NVARCHAR(100);
        DECLARE @ClassPropName NVARCHAR(100);

        SELECT @Columnname = ColumnName
        FROM dbo.MFProperty
        WHERE MFID = 0;

        SELECT @lastModifiedColumn = mp.ColumnName
        FROM dbo.MFProperty AS mp
        WHERE mp.MFID = 21; --'Last Modified'

        SELECT @ClassPropName = mp.ColumnName
        FROM dbo.MFProperty AS mp
        WHERE mp.MFID = 100;

        -------------------------------------------------------------
        -- Validate if Objids is set to 1 for updatemethod 0
        -------------------------------------------------------------
        --SELECT ot.objid,
        --       ot.Type FROM #ObjidTable AS ot

        -------------------------------------------------------------
        -- PROCESS FULL UPDATE FOR UPDATE METHOD 0
        -------------------------------------------------------------		

        -------------------------------------------------------------
        -- START BUILDING OF SELECT QUERY FOR FILTER
        -------------------------------------------------------------
        -------------------------------------------------------------
        -- Set select query snippet to count records
        -------------------------------------------------------------
        SET @ProcedureStep = 'Build select query';
        SET @ParmDefinition = N'@retvalOUT int OUTPUT';
        SET @SelectQuery = N'SELECT @retvalOUT  = COUNT(isnull(ID,0)) FROM [' + @MFTableName + N'] WHERE ';
        -------------------------------------------------------------
        -- Get column for name or title and set to 'Auto' if left blank
        -------------------------------------------------------------
       BEGIN TRAN
       
       SET @Query = N'
       SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
       ;with cte as
       (
       Select objid from ' + @MFTableName + N' WHERE ' + @Columnname + N' IS NULL AND process_id = 1
       )
       UPDATE t
					SET ' + @Columnname + N' = ''Auto''
                    from ' + @MFTableName + N' t
                    inner join cte
                    on t.objid = cte.objid
					;'

        --		PRINT @SQL
        EXEC (@Query);
        Commit
        -------------------------------------------------------------
        -- create filter query for update method 0
        -------------------------------------------------------------       
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'filter snippet for Updatemethod 0';

        IF @SyncErrorFlag = 1
        BEGIN
            SET @vquery = N' Process_ID = 2  ';
        END;
        ELSE
        BEGIN
            SET @vquery = N' Process_ID = 1 ';
        END;

        IF @IsFullUpdate = 0
        BEGIN
            IF (@UserId IS NOT NULL)
            BEGIN
                SET @vquery = @vquery + N'AND MX_User_ID =''' + CONVERT(NVARCHAR(100), @UserId) + N'''';
            END;

            IF (@MFModifiedDate IS NOT NULL)
            BEGIN
                SET @vquery
                    = @vquery + N' AND ' + QUOTENAME(@lastModifiedColumn) + N' > = '''
                      + CONVERT(NVARCHAR(50), @MFModifiedDate) + N'''';
            END;

            IF (@ObjIDs IS NOT NULL)
            BEGIN
                SET @vquery = @vquery + N' AND ObjID in (SELECT t.objid FROM #ObjidTable t ) ';
            END;
            IF @Debug > 100
            BEGIN
                SELECT 'objids',
                       ot.objid,
                       ot.Type
                FROM #ObjidTable AS ot;
            END;


            IF @Debug > 100
                SELECT @vquery;
        END; -- end of setting up filter : is full update

        SET @SelectQuery = @SelectQuery + @vquery;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

            IF @Debug > 10
                SELECT @SelectQuery AS [Select records for update];
        END;

        -------------------------------------------------------------
        -- create filter select snippet
        -------------------------------------------------------------
        EXEC sys.sp_executesql @SelectQuery,
                               @ParmDefinition,
                               @retvalOUT = @Count OUTPUT;

        -------------------------------------------------------------
        -- Set class ID if not included
        -------------------------------------------------------------
        SET @ProcedureStep = 'Set class ID where null';
        SET @Params = N'@ClassID int';
        SET @Query
            = N'UPDATE t
					SET t.' + @ClassPropName + N' = @ClassId
					FROM ' + QUOTENAME(@MFTableName) + N' t WHERE t.process_ID = 1 AND (' + @ClassPropName
              + N' IS NULL or ' + @ClassPropName + N'= -1) AND t.' + QUOTENAME(@DeletedColumn) + N'is null';

        EXEC sys.sp_executesql @stmt = @Query,
                               @Param = @Params,
                               @Classid = @ClassId;

        -------------------------------------------------------------
        -- is class change application
        -------------------------------------------------------------
        SET @ProcedureStep = 'Get class change indicator';
        SET @Query = N'
; WITH cte AS
(
SELECT ' + QUOTENAME(@ClassPropName) + N' FROM ' + QUOTENAME(@MFTableName) + N' AS mc
GROUP BY ' + QUOTENAME(@ClassPropName) + N'
)
SELECT @RemoveOtherClass = COUNT(*) FROM cte;';

        EXEC sys.sp_executesql @Query,
                               N'@RemoveOtherClass smallint output',
                               @RemoveOtherClass OUTPUT;

        SET @DebugText = N' %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RemoveOtherClass);
        END;

        --if @RemoveOtherclass > 1 then the other class records will be set to deleted in this class table

        -------------------------------------------------------------
        -- log number of records to be updated
        -------------------------------------------------------------
        SET @StartTime = GETUTCDATE();
        SET @DebugText = N'Count of records i%';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Start Processing UpdateMethod 0';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
        END;

        SET @LogTypeDetail = N'Debug';
        SET @LogTextDetail = N'Count filtered records with process_id = 1 ';
        SET @LogStatusDetail = N'In Progress';
        SET @Validation_ID = NULL;
        SET @LogColumnName = N'process_ID';
        SET @LogColumnValue = CAST(ISNULL(@Count, 0) AS NVARCHAR(256));

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

        --------------------------------------------------------------------------------------------
        --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
        --------------------------------------------------------------------------------------------
        IF (@Count > 0 AND @UpdateMethod = 0)
        BEGIN
            DECLARE @vsql AS NVARCHAR(MAX),
                    @XMLFile XML,
                    @XML NVARCHAR(MAX);

            SET @FullXml = NULL;
            --	-------------------------------------------------------------
            --	-- anchor list of objects to be updated
            --	-------------------------------------------------------------
            --	    SET @Query = '';
            --		  Declare    @ObjectsToUpdate VARCHAR(100)

            --      SET @ProcedureStep = 'Filtered objects to update';
            --      SELECT @ObjectsToUpdate = [dbo].[fnMFVariableTableName]('##UpdateList', DEFAULT);

            -- SET @Query = 'SELECT * INTO '+ @ObjectsToUpdate +' FROM 
            --  (SELECT ID from '                       + QUOTENAME(@MFTableName) + ' where 
            --' + @vquery + ' )list ';

            --IF @Debug > 0
            --SELECT @Query AS FilteredRecordsQuery;

            --EXEC (@Query)

            -------------------------------------------------------------
            -- start column value pair for update method 0
            -------------------------------------------------------------
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Create Column Value Pair';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

               IF (SELECT (OBJECT_ID('tempdb..#ColumnValuePair'))) IS NOT null
                         DROP TABLE #ColumnValuePair;


            CREATE TABLE #ColumnValuePair
            (
                Id INT,
                objID INT,
                ObjVersion INT,
                ExternalID NVARCHAR(100),
                ColumnName NVARCHAR(200),
                ColumnValue NVARCHAR(max),
                Required INT,
                MFID INT,
                DataType INT
            );

            CREATE INDEX IDX_ColumnValuePair_ColumnName
            ON #ColumnValuePair (ColumnName);

            DECLARE @colsUnpivot AS NVARCHAR(MAX),
                    @colsPivot AS NVARCHAR(MAX),
                    @DeleteQuery AS NVARCHAR(MAX),
                    @rownr INT,
                    @Datatypes NVARCHAR(100),
                    @TypeGroup NVARCHAR(100);

            -------------------------------------------------------------
            -- prepare column value pair query based on data types
            -------------------------------------------------------------
            SET @Query = N'';
            SET @ProcedureStep = 'Datatype table';

            /*
            DECLARE @DatatypeTable AS TABLE
            (
                id INT IDENTITY,
                Datatypes NVARCHAR(20),
                Type_Ids NVARCHAR(100),
                TypeGroup NVARCHAR(100)
            );

            INSERT INTO @DatatypeTable
            (
                Datatypes,
                Type_Ids,
                TypeGroup
            )
            VALUES
            (N'Float', N'3', 'Real'),
            ('Integer', '2,8,10', 'Int'),
            ('Text', '1', 'String'),
            ('MultiText', '12', 'String'),
            ('MultiLookup', '9', 'String'),
            ('Time', '5', 'time'),
            ('DateTime', '6', 'Datetime'),
            ('Date', '4', 'Date'),
            ('Bit', '7', 'Int');

            SET @rownr = 1;
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'loop through Columns';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @ProcedureStep = 'Pivot Columns';

            WHILE @rownr IS NOT NULL
            BEGIN
                SELECT @Datatypes = dt.Type_Ids,
                    @TypeGroup    = dt.TypeGroup
                FROM @DatatypeTable AS dt
                WHERE dt.id = @rownr;

                SET @DebugText = N'DataTypes %s';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Datatypes);
                END;

                SELECT @colsUnpivot = STUFF(
                                      (
                                          SELECT ',' + QUOTENAME(C.name)
                                          FROM sys.columns              AS C
                                              INNER JOIN dbo.MFProperty AS mp
                                                  ON mp.ColumnName = C.name
                                          WHERE C.object_id = OBJECT_ID(@MFTableName)
                                                --      AND ISNULL([mp].[MFID], -1) NOT IN ( - 1, 20, 21, 23, 25 )
                                                --         AND ISNULL([mp].[MFID], -1) NOT IN ( - 1,20, 21, 23, 25 )
                                                AND ISNULL(mp.MFID, -1) NOT IN ( -1 )
                                                --Removed values to update created and updated values in m-files
                                                --        AND mp.ColumnName <> 'Deleted'
                                                AND mp.MFDataType_ID IN
                (
                    SELECT ListItem FROM dbo.fnMFParseDelimitedString(@Datatypes, ',')
                )
                                          FOR XML PATH('')
                                      ),
                                               1,
                                               1,
                                               ''
                                           );

                IF @Debug > 0
                    SELECT @colsUnpivot AS 'columns';

                IF @colsUnpivot IS NOT NULL
                BEGIN
                    IF @TypeGroup = 'Real'
                    BEGIN
                        SET @Query
                            = @Query
                              + N'Union All
 select ID,  Objid, MFversion, ExternalID, ColName as ColumnName, 
 CAST(CAST(colvalue AS Decimal(32,4)) AS VARCHAR(4000)) AS ColValue from ' + QUOTENAME(@MFTableName)
                              + N' t
        unpivot
        (
          Colvalue for Colname in (' + @colsUnpivot + N')
        ) unpiv
		where 
		'                            + @vquery + N' ';
                    END; --@Typegroup = 'Real'
                    ELSE IF @TypeGroup = 'DateTime'
                    BEGIN
                        SET @Query
                            = @Query
                              + N'Union All
 select ID,  Objid, MFversion, ExternalID, ColName as ColumnName, 
 convert(nvarchar(4000),FORMAT(convert(datetime,Colvalue,102), ''yyyy-MM-dd hh:mm:ss.fff'' )) AS ColValue from ' + QUOTENAME(@MFTableName)
                              + N' t
        unpivot
        (
          Colvalue for Colname in (' + @colsUnpivot + N')
        ) unpiv
		where 
		'                            + @vquery + N' ';
                    END; --@Typegroup = 'DateTime'
                    ELSE
                    BEGIN
                        SET @Query
                            = @Query
                              + N'Union All
 select ID,  Objid, MFversion, ExternalID, ColName as ColumnName, CAST(colvalue AS VARCHAR(4000)) AS ColValue from '
                              + QUOTENAME(@MFTableName)
                              + N' t
        unpivot
        (
          Colvalue for Colname in (' + @colsUnpivot + N')
        ) unpiv
		where 
		'                            + @vquery + N' ';
                    END; --@rownr <> 1
                END;

                SELECT @rownr =
                (
                    SELECT MIN(dt.id) FROM @DatatypeTable AS dt WHERE dt.id > @rownr
                );
            END;

            --SET @DeleteQuery
            --    = N'Union All Select ID, Objid, MFversion, ExternalID, '+@DeletedColumn+' as ColumnName, cast(isnull('+@DeletedColumn+','''') as nvarchar(4000))  as Value from '
            --      + QUOTENAME(@MFTableName) + N' t where ' + @vquery + N' ';

            --SELECT @DeleteQuery AS deletequery
            --   SELECT @Query = SUBSTRING(@Query, 11, 8000) + @DeleteQuery;
            SELECT @Query = SUBSTRING(@Query, 11, 8000);

                         IF @Debug > 100
                             PRINT @Query;

            -------------------------------------------------------------
            -- insert into column value pair
            -------------------------------------------------------------
            SELECT @ProcedureStep = 'Insert into column value pair';

--            SELECT @Query
--                = N'INSERT INTO  #ColumnValuePair

--SELECT ID,ObjID,MFVersion,ExternalID,ColumnName,ColValue,NULL,null,null from 
--(' +            @Query + N') list';

--            IF @Debug > 100
--            BEGIN
--                SELECT @Query AS 'ColumnValue pair query';
--            END;

--            EXEC (@Query);
*/


            --DECLARE @DeleteQuery NVARCHAR(MAX)
            --DECLARE @DeletedColumn datetime = null
            --DECLARE @MFTableName NVARCHAR(100) = 'MFCustomer'
            --DECLARE @vquery NVARCHAR(MAX)= ' process_ID = 0 '
            --DECLARE @DataTypes NVARCHAR(100) 
            DECLARE @CaseQuery NVARCHAR(MAX);
            --DECLARE @SelectQuery NVARCHAR(MAX)
            DECLARE @SQL NVARCHAR(MAX);

            --IF (SELECT (OBJECT_ID('tempdb..#ColumnValuePair'))) IS NOT null
            --             DROP TABLE #ColumnValuePair;

            --         CREATE TABLE #ColumnValuePair
            --         (
            --             Id INT,
            --             objID INT,
            --             ObjVersion INT,
            --             ExternalID NVARCHAR(100),
            --             ColumnName NVARCHAR(200),
            --             ColumnValue NVARCHAR(max),
            --             Required INT,
            --             MFID INT,
            --             DataType INT
            --         );

            DECLARE @DatatypeTable AS TABLE
            (
                id INT IDENTITY,
                Datatypes NVARCHAR(20),
                Type_Ids NVARCHAR(100),
                TypeGroup NVARCHAR(100),
                DataConversion NVARCHAR(100)
            );

            INSERT INTO @DatatypeTable
            (
                Datatypes,
                Type_Ids,
                TypeGroup,
                DataConversion
            )
            VALUES
            (N'Float', N'3', 'Real', 'CAST(CAST(colvalue AS Decimal(32,4)) AS NVARCHAR(4000))'),
            ('Integer', '2', 'Int', 'CAST(colvalue AS NVARCHAR(4000))'),
            ('Integer', '9', 'Int', 'CAST(colvalue AS NVARCHAR(4000))'),
            ('Integer', '10', 'Int', 'CAST(colvalue AS NVARCHAR(4000))'),
            ('Text', '1', 'String', 'CAST(colvalue AS NVARCHAR(4000))'),
            ('MultiText', '13', 'String', 'CAST(colvalue AS NVARCHAR(max))'),
            ('MultiLookup', '10', 'String', 'CAST(colvalue AS NVARCHAR(4000))'),
            ('Time', '6', 'time', 'CAST(cast(colvalue as time(0)) AS NVARCHAR(4000))'),
            ('DateTime', '7', 'Datetime',
             'convert(nvarchar(4000),FORMAT(convert(datetime,Colvalue,102), ''yyyy-MM-dd HH:mm:ss.fff'' ))'),
            ('Date', '5', 'Date', 'CAST(colvalue AS NVARCHAR(4000))'),
            ('Bit', '8', 'Int', 'CAST(colvalue AS NVARCHAR(4000))');

            SET @ProcedureStep = 'Prepare column list';

            IF
            (
                SELECT OBJECT_ID('tempdb..#ColumnList')
            ) IS NOT NULL
                DROP TABLE #ColumnList;

            CREATE TABLE #ColumnList
            (
                MFID INT,
                Column_Name NVARCHAR(100),
                SQLDataType NVARCHAR(100),
                MFDataType_ID INT,
                Required BIT
            );

            INSERT INTO #ColumnList
            (
                MFID,
                Column_Name,
                SQLDataType,
                MFDataType_ID,
                Required
            )
            SELECT mfms.Property_MFID,
                   QUOTENAME(C.name),
                   mdt.SQLDataType,
                   --        mdt.ID,
                   mdt.MFTypeID,
                   CASE
                       WHEN C.is_nullable = 1 THEN
                           0
                       ELSE
                           1
                   END AS Required
            FROM sys.columns AS C
                INNER JOIN dbo.MFvwMetadataStructure AS mfms
                    ON mfms.ColumnName = C.name
                INNER JOIN dbo.MFDataType AS mdt
                    ON mfms.MFTypeID = mdt.MFTypeID
            WHERE C.object_id = OBJECT_ID(@MFTableName)
                  AND ISNULL(mfms.Property_MFID, -1) NOT IN ( -1 )
            GROUP BY mfms.Property_MFID,
                     C.name,
                     mdt.SQLDataType,
                     mdt.MFTypeID,
                     C.is_nullable;

            SET @ProcedureStep = 'Prepare queries';

            IF @Debug > 100
                SELECT '#columnlist',
                       *
                FROM #ColumnList AS cl;

            SELECT @CaseQuery
                =
            (
                SELECT ' when ''' + cl.Column_Name + ''' then '
                       + REPLACE(dt.DataConversion, 'Colvalue', cl.Column_Name) + ' '
                FROM #ColumnList AS cl
                    INNER JOIN @DatatypeTable AS dt
                        ON dt.Type_Ids = cl.MFDataType_ID
                FOR XML PATH('')
            );

            IF @Debug > 100
                SELECT @CaseQuery '@CaseQuery';



            SELECT @SelectQuery
                = N'id,Objid,ExternalID,MFVersion,'
                  + STUFF(
                    (
                        SELECT ',' + cl.Column_Name FROM #ColumnList AS cl FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                         );

            IF @Debug > 100
                SELECT @SelectQuery '@SelectQuery';


            SET @ProcedureStep = 'insert into #ColumnValuePair';

            SET @SQL
                = N'
insert into #ColumnValuePair
select a.id, a.objid, a.MFVersion, a.externalID,  b.column_name as ColumnName
, column_value = 
    case b.column_name
    ' +     @CaseQuery + N'    
    end
    ,b.Required,b.MFID,b.MFDataType_ID
from (
  select ' + @SelectQuery + N'
  from ' +  @MFTableName + N' where ' + @vquery
                  + N'
  ) a
cross join (
    SELECT  MFID,
    Column_Name,
    SQLDataType,
    MFDataType_ID,
    Required
    From #ColumnList
  ) b (MFID,Column_Name,SQLDataType,MFDataType_ID,Required);';

            IF @Debug > 100
            BEGIN
                SELECT @SQL AS 'ColumnValue pair query';
            END;


            EXEC sys.sp_executesql @SQL;

                    SET @ProcedureStep = 'update #ColumnValuePair';


            UPDATE #ColumnValuePair
            SET MFID = mp.MFID,
                DataType = mp.MFDataType_ID
            FROM #ColumnValuePair AS cvp
                INNER JOIN dbo.MFProperty mp
                    ON cvp.ColumnName = mp.ColumnName;


            IF @Debug > 0
                SELECT 'Required_is_null', cvp.Id,
                                          cvp.objID,
                                          cvp.ObjVersion,
                                          cvp.ExternalID,
                                          cvp.ColumnName,
                                          cvp.ColumnValue,
                                          cvp.Required,
                                          cvp.MFID,
                                          cvp.DataType
                FROM #ColumnValuePair AS cvp
                WHERE cvp.Required = 1
                      AND cvp.ColumnValue IS NULL;

            -------------------------------------------------------------
            -- Validate class and property requirements
            -------------------------------------------------------------
            SET @ProcedureStep = 'Validate class and property requirements';
            /*
            DECLARE @IsUpToDate int
            IF @IsUpToDate = 0
            BEGIN
                EXEC dbo.spMFSynchronizeSpecificMetadata @Metadata = 'Property';

                EXEC dbo.spMFSynchronizeSpecificMetadata @Metadata = 'class';

                WITH cte
                AS (SELECT mfms.Property
                    FROM dbo.MFvwMetadataStructure AS mfms
                    WHERE mfms.TableName = @MFTableName
                          --   AND mfms.Property_MFID NOT IN ( 20, 21, 23, 25 )
                          -- AND [mfms].[Property_MFID] NOT IN (  23, 25 )
                          AND mfms.Required = 1
                    EXCEPT
                    (SELECT mp.Name
                     FROM #ColumnValuePair         AS cvp
                         INNER JOIN dbo.MFProperty mp
                             ON cvp.ColumnName = mp.ColumnName))
                INSERT INTO #ColumnValuePair
                (
                    Id,
                    objID,
                    ObjVersion,
                    ExternalID,
                    ColumnName,
                    ColumnValue,
                    Required,
                    MFID,
                    DataType
                )
                SELECT cvp.Id,
                    cvp.objID,
                    cvp.ObjVersion,
                    cvp.ExternalID,
                    mp.ColumnName,
                    'ZZZ',
                    1,
                    mp.MFID,
                    mp.MFDataType_ID
                FROM #ColumnValuePair AS cvp
                    CROSS APPLY cte
                    INNER JOIN dbo.MFProperty AS mp
                        ON cte.Property = mp.Name
                GROUP BY cvp.Id,
                    cvp.objID,
                    cvp.ObjVersion,
                    cvp.ExternalID,
                    mp.ColumnName,
                    mp.MFDataType_ID,
                    mp.MFID;
            END;
*/
            -------------------------------------------------------------
            -- check for required data missing
            -------------------------------------------------------------
            SET @ProcedureStep = 'check for required data missing';

            IF
            (
                SELECT COUNT(ISNULL(cvp.Id, 0))
                FROM #ColumnValuePair AS cvp
                WHERE cvp.ColumnValue IS NULL
                      AND cvp.Required = 1
            ) > 0
            BEGIN
                DECLARE @missingColumns NVARCHAR(4000);

                SELECT @missingColumns = STUFF(
                                         (
                                             SELECT ',' + cvp.ColumnName
                                             FROM #ColumnValuePair AS cvp
                                             WHERE cvp.ColumnValue = NULL
                                                   AND cvp.Required = 1
                                             FOR XML PATH('')
                                         ),
                                         1,
                                         1,
                                         ''
                                              );

                SET @DebugText = N' in columns: ' + @missingColumns;
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Required data missing';

                RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- update column value pair properties
            -------------------------------------------------------------
            --UPDATE CVP
            --SET CVP.Required = CASE
            --                       WHEN c2.is_nullable = 1 THEN
            --                           0
            --                       ELSE
            --                           1
            --                   END,
            --    CVP.ColumnValue = CASE
            --                          WHEN ISNULL(CVP.ColumnValue, '-1') = '-1'
            --                               AND c2.is_nullable = 0 THEN
            --                              'ZZZ'
            --                          ELSE
            --                              CVP.ColumnValue
            --                      END
            --SELECT p.name, p.mfid,cp.required
            --FROM #ColumnValuePair      CVP
            --    INNER JOIN sys.columns AS c2
            --        ON CVP.ColumnName = c2.name
            --WHERE c2.object_id = OBJECT_ID(@MFTableName);

      
            --     INNER JOIN dbo.MFProperty AS mp
            --        ON cvp.ColumnName = mp.ColumnName
            --    INNER JOIN dbo.MFDataType AS mdt
            --        ON mp.MFDataType_ID = mdt.ID;

            -------------------------------------------------------------
            -- update MFlastUpdate datetime; MFLastModified MFSQL user
            -------------------------------------------------------------
            UPDATE cvp
            SET cvp.ColumnValue = CASE
                                      WHEN cvp.MFID = 20 --created
                                           AND cvp.ColumnValue IS NULL THEN
                                          CONVERT(
                                                     NVARCHAR(4000),
                                                     FORMAT(
                                                               CONVERT(DATETIME, GETDATE(), 102),
                                                               'yyyy-MM-dd HH:mm:ss.fff'
                                                           )
                                                 )
                                      ELSE
                                          cvp.ColumnValue
                                  END
            FROM #ColumnValuePair AS cvp;

            UPDATE cvp
            SET cvp.ColumnValue = CONVERT(
                                             NVARCHAR(4000),
                                             FORMAT(CONVERT(DATETIME, GETDATE(), 102), 'yyyy-MM-dd HH:mm:ss.fff')
                                         )
            FROM #ColumnValuePair AS cvp
            WHERE cvp.MFID = 21;

            DECLARE @lastModifiedUser_ID INT;

            SELECT @lastModifiedUser_ID = mla.MFID
            FROM dbo.MFVaultSettings AS mvs
                INNER JOIN dbo.MFLoginAccount AS mla
                    ON mvs.Username = mla.UserName;

            UPDATE cvp
            SET cvp.ColumnValue = CAST(@lastModifiedUser_ID AS NVARCHAR(4000))          
            FROM #ColumnValuePair AS cvp
            WHERE cvp.MFID = 23; -- last modified

           UPDATE cvp
            SET cvp.ColumnValue = CASE WHEN ColumnValue IS NULL THEN CAST(@lastModifiedUser_ID AS NVARCHAR(4000))         ELSE ColumnValue end 
            FROM #ColumnValuePair AS cvp
            WHERE cvp.MFID = 25; -- created by

            IF @Debug > 100
                SELECT 'columnvaluepair',
                       *
                FROM #ColumnValuePair AS cvp;

            -------------------------------------------------------------
            -- END of preparating column value pair
            -------------------------------------------------------------           
            SELECT @Count = COUNT(ISNULL(cvp.Id, 0))
            FROM #ColumnValuePair AS cvp;

            SET @ProcedureStep = 'ColumnValue Pair ';
            SET @LogTypeDetail = N'Debug';
            SET @LogTextDetail = N'Properties for update ';
            SET @LogStatusDetail = N'In Progress';
            SET @Validation_ID = NULL;
            SET @LogColumnName = N'Properties';
            SET @LogColumnValue = CAST(@Count AS NVARCHAR(256));
            SET @DebugText = N'Column Value Pair: %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
            SET @ProcedureStep = 'Creating XML for Process_ID = 1';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -----------------------------------------------------
            --Generate xml file -- 
            -----------------------------------------------------
            SET @XMLFile =
            (
                SELECT @ObjectId AS [Object/@id],
                       cvp.Id AS [Object/@sqlID],
                       cvp.objID AS [Object/@objID],
                       cvp.ObjVersion AS [Object/@objVesrion],
                       cvp.ExternalID AS [Object/@DisplayID], --Added For Task #988
                                                              --     ( SELECT
                                                              --       @ClassId AS 'class/@id' ,
                       (
                           SELECT
                               (
                                   SELECT TOP 1
                                          tmp1.ColumnValue
                                   FROM #ColumnValuePair AS tmp1
                                   WHERE tmp1.MFID = 100
                               ) AS [class/@id],
                               (
                                   SELECT tmp.MFID AS [property/@id],
                                          tmp.DataType AS [property/@dataType],
                                          CASE
                                              WHEN tmp.ColumnValue IS NULL THEN
                                                  NULL
                                              ELSE
                                                  tmp.ColumnValue
                                          END AS 'property' ----Added case statement for checking Required property
                                   FROM #ColumnValuePair AS tmp
                                   WHERE tmp.MFID <> 100
                                         --                    AND tmp.ColumnValue IS NOT NULL
                                         AND tmp.Id = cvp.Id
                                   GROUP BY tmp.Id,
                                            tmp.MFID,
                                            tmp.DataType,
                                            tmp.ColumnValue
                                   ORDER BY tmp.Id
                                   --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                   FOR XML PATH(''), TYPE
                               ) AS class
                           FOR XML PATH(''), TYPE
                       ) AS Object
                FROM #ColumnValuePair AS cvp
                GROUP BY cvp.Id,
                         cvp.objID,
                         cvp.ObjVersion,
                         cvp.ExternalID
                ORDER BY cvp.Id
                FOR XML PATH(''), ROOT('form')
            );
            SET @XMLFile =
            (
                SELECT @XMLFile.query('/form/*')
            );

            --------------------------------------------------------------------------------------------------
            IF @Debug > 100
                SELECT @XMLFile AS [@XMLFile];

            SET @FullXml = ISNULL(CAST(@FullXml AS NVARCHAR(MAX)), '') + ISNULL(CAST(@XMLFile AS NVARCHAR(MAX)), '');

            IF @Debug > 100
            BEGIN
                SELECT *
                FROM #ColumnValuePair AS cvp;
            END;

            SET @ProcedureStep = 'Count Records';

            IF @Debug > 9
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            --Count records for ProcessBatchDetail
            SET @ParmDefinition = N'@Count int output';
            SET @Query = N'
					SELECT @Count = COUNT(ISNULL(id,0)) FROM ' + @MFTableName + N' WHERE process_ID = 1';

            EXEC sys.sp_executesql @stmt = @Query,
                                   @param = @ParmDefinition,
                                   @Count = @Count OUTPUT;

            SET @LogTypeDetail = N'Debug';
            SET @LogTextDetail = N'XML Records for Updated method 0 ';
            SET @LogStatusDetail = N'In Progress';
            SET @Validation_ID = NULL;
            SET @LogColumnName = N'process_ID = 1';
            SET @LogColumnValue = CAST(ISNULL(@Count, 0) AS VARCHAR(5));

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

            IF EXISTS (SELECT (OBJECT_ID('tempdb..#ColumnValuePair')))
                DROP TABLE #ColumnValuePair;
        END; -- end count > 0 and update method = 0
    END;

    -- End If Updatemethod = 0

    -----------------------------------------------------
    --IF Null Creating XML with ObjectTypeID and ClassId
    -----------------------------------------------------
    SET @ProcedureStep = 'Set full XML';

    IF (@FullXml IS NULL)
    BEGIN
        SET @FullXml =
        (
            SELECT @ObjectId AS [Object/@id],
                   @Id AS [Object/@sqlID],
                   @objID AS [Object/@objID],
                   @ObjVersion AS [Object/@objVesrion],
                   @ExternalID AS [Object/@DisplayID], --Added for Task #988
                   (
                       SELECT @ClassId AS [class/@id] FOR XML PATH(''), TYPE
                   ) AS Object
            FOR XML PATH(''), ROOT('form')
        );
        SET @FullXml =
        (
            SELECT @FullXml.query('/form/*')
        );
    END;

    --end of if full method is null
    SET @XML = N'<form>' + (CAST(@FullXml AS NVARCHAR(MAX))) + N'</form>';

    --------------------------------------------------------------------
    --create XML for @UpdateMethod !=0 (0=Update from SQL to MF only)
    -----------------------------------------------------
    SET @StartTime = GETUTCDATE();

    IF (@UpdateMethod != 0)
    BEGIN
        SET @ProcedureStep = 'Xml for Process_ID = 0 ';

        DECLARE @ObjVerXML XML,
                @ObjVerXMLForUpdate XML,
                @CreateXmlQuery NVARCHAR(MAX);

        IF @Debug > 9
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

        -----------------------------------------------------
        --Create XML with All ObjVer Exists in SQL
        -----------------------------------------------------

        -------------------------------------------------------------
        -- for full update updatemethod 1
        -------------------------------------------------------------
        IF @IsFullUpdate = 1
        BEGIN
            SET @ProcedureStep = 'If full update ';
            SET @DebugText = N'';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @CreateXmlQuery
                = N'SELECT @ObjVerXML = (
								SELECT ' + CAST(@ObjectId AS NVARCHAR(20))
                  + N' AS ''ObjectType/@id'' ,(
										SELECT objID ''objVers/@objectID''
											,MFVersion ''objVers/@version''
											,GUID ''objVers/@objectGUID''
										FROM [' + @MFTableName
                  + N']
										WHERE Process_ID = 0
										FOR XML PATH('''')
											,TYPE
										) AS ObjectType
								FOR XML PATH('''')
									,ROOT(''form'')
								)';

            EXEC sys.sp_executesql @CreateXmlQuery,
                                   N'@ObjVerXML XML OUTPUT',
                                   @ObjVerXML OUTPUT;

            DECLARE @ObjVerXmlString NVARCHAR(MAX);

            SET @ObjVerXmlString = CAST(@ObjVerXML AS NVARCHAR(MAX));

            IF @Debug > 9
            BEGIN
                SELECT @ObjVerXmlString AS [@ObjVerXmlString];
            END;
        END;

        -------------------------------------------------------------
        -- for filtered update update method 0
        -------------------------------------------------------------
        IF @IsFullUpdate = 0
        BEGIN
            SET @ProcedureStep = ' Prepare query for filters ';
            SET @DebugText = N' Filtered Update ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- reset process_ID for objects in objids
            -------------------------------------------------------------
-- add isolation level to manage locks
            EXECUTE (N'
            begin tran
            SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
            UPDATE t SET process_ID = 0 FROM ' + @MFTableName + ' t 
            INNER JOIN #ObjidTable AS ot
            ON t.objid = ot.objid
            WHERE process_ID <> 0 and t.objid = ot.objid;
            Commit
            ');

            -------------------------------------------------------------
            -- Sync error flag snippet
            -------------------------------------------------------------
            IF (ISNULL(@SyncErrorFlag, 0) = 0)
            BEGIN
                SET @CreateXmlQuery
                    = N'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM [' + @MFTableName + N']
													WHERE Process_ID = 0 ';
            END;
            ELSE
            BEGIN
                SET @CreateXmlQuery
                    = N'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM [' + @MFTableName + N']
													WHERE Process_ID = 2 ';
            END;

            -------------------------------------------------------------
            -- Filter snippet
            -------------------------------------------------------------
            IF (@MFModifiedDate IS NOT NULL)
            BEGIN
                SET @CreateXmlQuery
                    = @CreateXmlQuery + N'AND ' + QUOTENAME(@lastModifiedColumn) + N' > = '''
                      + CAST(@MFModifiedDate AS VARCHAR(MAX)) + N''' ';
            END;

            IF (@ObjIDs IS NOT NULL)
            BEGIN
                SET @CreateXmlQuery = @CreateXmlQuery + N'AND ObjID in (SELECT t.objid FROM #ObjidTable t )';
            END;

            --end filters 
            -------------------------------------------------------------
            -- Compile XML query from snippets
            -------------------------------------------------------------
            SET @CreateXmlQuery = @CreateXmlQuery + N' FOR XML PATH(''''),ROOT(''form''))';

            IF @Debug > 9
                SELECT @CreateXmlQuery AS [@CreateXmlQuery];

            SET @Params = N'@ObjVerXMLForUpdate XML OUTPUT';

            EXEC sys.sp_executesql @CreateXmlQuery,
                                   @Params,
                                   @ObjVerXMLForUpdate OUTPUT;

            IF @Debug > 9
            BEGIN
                SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
            END;

            -------------------------------------------------------------
            -- validate Objids
            -------------------------------------------------------------
            SET @ProcedureStep = 'Identify Object IDs ';

            IF @ObjidCount > 0
            BEGIN
                SET @DebugText = N'Objids %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjidCount);
                END;

                DECLARE @missingXML NVARCHAR(MAX); ---Bug 1098  VARCHAR(8000) to  VARCHAR(max) 
                DECLARE @objects NVARCHAR(MAX);

                IF ISNULL(@SyncErrorFlag, 0) = 0 -- exclude routine when sync flag = 1 is processed
                BEGIN
                    EXEC dbo.spMFGetMissingobjectIds @ObjIDs,
                                                     @MFTableName,
                                                     @missing = @missingXML OUTPUT;

                    SET @ProcedureStep = 'Missing objects IDs ';
                    SET @DebugText = N' sync flag 0: objids  %s ';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    --						RAISERROR('I am 0',10,1)
                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @missingXML);
                    END;
                END;
                ELSE
                BEGIN
                    IF ISNULL(@SyncErrorFlag, 0) = 1
                    BEGIN
                        SET @missingXML = @ObjIDs;
                        SET @DebugText = N' SyncFlag 1: Missing objects %s ';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @missingXML);
                        END;
                    END;
                END;

                IF @Debug > 9
                    SELECT @missingXML AS [@missingXML];

                -------------------------------------------------------------
                -- set objverXML for update XML
                -------------------------------------------------------------
                IF (@ObjVerXMLForUpdate IS NULL)
                BEGIN
                    SET @ObjVerXMLForUpdate = '<form>' + CAST(@missingXML AS NVARCHAR(MAX)) + ' </form>';
                END;
                ELSE
                BEGIN
                    SET @ObjVerXMLForUpdate
                        = REPLACE(CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX)), '</form>', @missingXML + '</form>');
                END;
            END;
            ELSE
            BEGIN
                SET @ObjVerXMLForUpdate = NULL;
            END;

            IF @Debug > 9
            BEGIN
                SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
            END;

            -------------------------------------------------------------
            -- Set the objectver detail XML
            -------------------------------------------------------------
            SET @ProcedureStep = 'ObjverDetails for Update ';

            -------------------------------------------------------------
            -- count detail items
            -------------------------------------------------------------
            DECLARE @objVerDetails_Count INT;

            SELECT @objVerDetails_Count = COUNT(o.objectid)
            FROM
            (
                SELECT t1.c1.value('(@objectID)[1]', 'INT') AS objectid
                FROM @ObjVerXMLForUpdate.nodes('/form/objVers') AS t1(c1)
            ) AS o;

            SET @DebugText = N'Count of objects %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objVerDetails_Count);
            END;

            SET @LogTypeDetail = N'Debug';
            SET @LogTextDetail = N'XML Records in ObjVerDetails for MFiles';
            SET @LogStatusDetail = N'In Progress';
            SET @Validation_ID = NULL;
            SET @LogColumnValue = CAST(@objVerDetails_Count AS VARCHAR(10));
            SET @LogColumnName = N'ObjectVerDetails';

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

            SET @ProcedureStep = 'Set input XML parameters';
            SET @ObjVerXmlString = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
            SET @ObjIDsForUpdate = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
        END; -- end is full update 0
    END; -- end is not update method 0

    SET @ProcedureStep = 'Get property MFIDs';

    IF @Debug > 0
    BEGIN
        RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

        IF @Debug > 10
            SELECT @XML AS XML,
                   @ObjVerXmlString AS ObjVerXmlString,
                   @ObjIDsForUpdate AS [@ObjIDsForUpdate],
                   @UpdateMethod AS UpdateMethod;
    END;

    -------------------------------------------------------------
    -- Get property MFIDs
    -------------------------------------------------------------
    SELECT @MFIDs = STUFF(
                    (
                        SELECT ',' + CAST(ISNULL(MFP.MFID, '') AS NVARCHAR(10))
                        FROM INFORMATION_SCHEMA.COLUMNS AS CLM
                            LEFT JOIN dbo.MFProperty AS MFP
                                ON MFP.ColumnName = CLM.COLUMN_NAME
                        WHERE CLM.TABLE_NAME = @MFTableName
                        GROUP BY MFP.MFID
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                         );

    IF @Debug > 10
    BEGIN
        SELECT @MFIDs AS [List of Properties];
    END;

    SET @ProcedureStep = 'Update MFUpdateHistory';

    UPDATE dbo.MFUpdateHistory
    SET ObjectDetails = @XML,
        ObjectVerDetails = @ObjVerXmlString
    WHERE Id = @Update_ID;

    IF @Debug > 9
        RAISERROR('Proc: %s Step: %s ObjectVerDetails ', 10, 1, @ProcedureName, @ProcedureStep);


    -----------------------------------------------------
    --Process Wrapper Method
    -----------------------------------------------------
    SET @ProcedureStep = 'CLR Update in MFiles';
    SET @StartTime = GETUTCDATE();

    --IF @Debug > 99
    --BEGIN
    --    SELECT CAST(@XML AS NVARCHAR(MAX))
    --          ,CAST(@ObjVerXmlString AS NVARCHAR(MAX))
    --          ,CAST(@MFIDs AS NVARCHAR(MAX))
    --          ,CAST(@MFModifiedDate AS NVARCHAR(MAX))
    --          ,CAST(@ObjIDsForUpdate AS NVARCHAR(MAX));
    --END;

    -------------------------------------------------------------
    -- Check connection to vault
    -------------------------------------------------------------

    SET @ProcedureStep = 'Connection test: ';

    DECLARE @TestResult INT;

    EXEC @return_value = dbo.spMFConnectionTest;

    IF @return_value <> 1
    BEGIN
        SET @DebugText = N'Connection failed ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
    END;

    ------------------------Added for checking required property null-------------------------------	
    SET @ProcedureStep = 'wrapper';
    SET @ProcedureName = 'spMFCreateObjectInternal';


    EXEC dbo.spMFCreateObjectInternal @VaultSettings = @VaultSettings,            -- nvarchar(4000)
                                      @XmlFile = @XML,                            -- nvarchar(max)
                                      @objVerXmlIn = @ObjVerXmlString,            -- nvarchar(max)
                                      @MFIDs = @MFIDs,                            -- nvarchar(2000)
                                      @UpdateMethod = @UpdateMethod,              -- int
                                      @dtModifieDateTime = @MFModifiedDate,       -- datetime
                                      @sLsOfID = @ObjIDsForUpdate,                -- nvarchar(max)
                                      @CheckOutObjects = @CheckOutObjects OUTPUT,
                                      @ObjVerXmlOut = @XmlOUT OUTPUT,             -- nvarchar(max)
                                      @NewObjectXml = @NewObjectXml OUTPUT,       -- nvarchar(max)
                                      @SynchErrorObjects = @SynchErrorObj OUTPUT, -- nvarchar(max)
                                      @DeletedObjVerXML = @DeletedObjects OUTPUT, -- nvarchar(max)
                                      @ErrorXML = @ErrorInfo OUTPUT;              -- nvarchar(max)

    SET @ProcedureName = 'spMFUpdateTable';

    IF @NewObjectXml = ''
        SET @NewObjectXml = NULL;

    SET @ProcedureStep = 'Analyse output';

    IF @Debug > 10
    BEGIN
        SELECT CAST(@ErrorInfo AS XML) AS Errorinfo;
        RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
    END;

    SET @LogTypeDetail = N'Debug';
    SET @LogTextDetail = N'Wrapper turnaround';
    SET @LogStatusDetail = N'Assembly';
    SET @Validation_ID = NULL;
    SET @LogColumnValue = N'';
    SET @LogColumnName = N'';

    EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

    DECLARE @idoc3 INT;
    DECLARE @DeletedXML XML;

    SET @ProcedureStep = 'Update other status items';
    SET @StartTime = GETUTCDATE();

    -------------------------------------------------------------
    -- 
    -------------------------------------------------------------
    IF @Debug > 100
    BEGIN
        SELECT @XmlOUT AS XMLout;

        SELECT @NewObjectXml AS NewObjectXml;

        SELECT @DeletedObjects AS DeletedObjects;

        SELECT @CheckOutObjects AS CheckedOutObjects;
    END;

    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Process Exceptions';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    -------------------------------------------------------------
    -- Get status of objver
    -------------------------------------------------------------
    IF
    (
        SELECT OBJECT_ID('tempdb..' + @TempStatusList + '')
    ) IS NOT NULL
        EXEC (N'DROP TABLE ' + @TempStatusList + '');

    EXEC (N'CREATE TABLE ' + @TempStatusList + '
    (
        ObjectID INT PRIMARY KEY,
        Status NVARCHAR(25),
        auditStatus int,
        ClassID INT
    );

    CREATE NONCLUSTERED INDEX IDX_StatusList_Status ON ' + @TempStatusList + ' (Status)');

    --IF ISNULL(@NewObjectXml, '') <> ''
    --   OR ISNULL(@DeletedObjects, '') <> ''
    --BEGIN

        -------------------------------------------------------------
        -- get status of updated records
        -------------------------------------------------------------
        IF ISNULL(@NewObjectXml,'') <> ''
        BEGIN

            EXEC sys.sp_xml_preparedocument @idoc3 OUTPUT, @NewObjectXml;

            SET @ProcedureStep = ' Status of returned objects ';
            SET @Query
                = N'INSERT INTO ' + @TempStatusList
                  + N'
        (
            ObjectID,
            Status,
            ClassID
        )
        SELECT t.objectID,
            t.Status,
            t.Class
        FROM
            OPENXML(@idoc3, ''/form/Object/properties'', 1)
            WITH
            (
                objectID INT ''../@objectId'',
                Status NVARCHAR(25) ''../@Status'',
                Class NVARCHAR(100) ''./@propertyValue'',
                ClassID INT ''./@propertyId'',
                DataType NVARCHAR(100) ''./@dataType''
            ) t
        WHERE t.ClassID = 100
              AND t.DataType IS NULL;';

            EXEC sys.sp_executesql @Query, N'@Idoc3 int', @idoc3;

            SET @Count = @@RowCount;
            SET @DebugText = N' %i ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            IF @idoc3 IS NOT NULL
                EXEC sys.sp_xml_removedocument @idoc3;

        END; -- if @newobjectXML is not null

        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Process Deletes phase 2';

        IF ISNULL(@DeletedObjects,'') <> '' 
        BEGIN
            EXEC sys.sp_xml_preparedocument @idoc3 OUTPUT, @DeletedObjects;

            SET @Query
                = N'INSERT INTO ' + @TempStatusList
                  + N'
        (
            ObjectID,
            Status
        )
        SELECT DISTINCT
            t.objectID,
            t.Deleted
        FROM
            OPENXML(@idoc3, ''/DelDataSet/objVers'', 1)
            WITH
            (
                objectID INT ''./Objid'',
                Deleted NVARCHAR(25) ''./Deleted''
            )                     t
            LEFT JOIN '  + @TempStatusList + N' AS sl
                ON sl.ObjectID = t.objectID';

            EXEC sys.sp_executesql @Query, N'@Idoc3 int', @idoc3;

            SET @Count = @@RowCount;
            SET @DebugText = N' %i ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            --       WHERE sl.ObjectID IS NOT NULL;
            IF @idoc3 IS NOT NULL
                EXEC sys.sp_xml_removedocument @idoc3;
        END;

        -- @deletedobjects is not null

        SET @ProcedureStep = ' checked out objects ';
        SET @Query
            = N'UPDATE t 
      Set ' + QUOTENAME(@DeletedColumn) + N' = GetUTCdate()
      FROM ' + QUOTENAME(@MFTableName) + N' t
      inner join ' + @TempStatusList
              + N' l
      on l.ObjectID = t.objid
      where l.Status in (''3'',''NotInClass'')
      ' ;

        --IF @Debug > 0
        --    PRINT @Query;
        EXEC (@Query);

        SET @Count = @@RowCount;
        SET @DebugText = N' %i ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
        END;

        SET @ProcedureStep = ' Prepare @DeletedXML';
        SET @Query
            = N'SET @DeletedXML =
        (
            SELECT *
            FROM
            (
                SELECT sl.ObjectID,
                    sl.Status
                FROM ' + @TempStatusList
              + N' AS sl
                WHERE sl.Status IN ( ''3'', ''NotInClass'' )
                GROUP BY sl.ObjectID,
                    sl.Status
            ) AS objVers
            FOR XML AUTO
        )';

        EXEC sys.sp_executesql @Query, N'@DeletedXML XML output', @DeletedXML;

        SET @DebugText = N' ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- Add audit table statusflag to tempstatus list
        -------------------------------------------------------------
        SET @Query
            = N' UPDATE sl
        SET AuditStatus = ah.StatusFlag
        FROM ' + @TempStatusList
              + N' AS sl
              inner JOIN MFAuditHistory ah
              ON sl.ObjectID = ah.objid AND ah.objecttype = @objectID';

        EXEC sys.sp_executesql @Query, N'@objectID int', @ObjectId;


        IF @Debug > 0
        BEGIN
            EXEC (N'SELECT * FROM ' + @TempStatusList + '');
        END;

        -------------------------------------------------------------
        -- get objects that has changed class without being deleted
        -------------------------------------------------------------
        SET @Params = N'@RemoveOtherClass int output, @ClassID int';
        SET @vquery
            = N'SELECT @RemoveOtherClass = @RemoveOtherClass + count(*) FROM ' + @TempStatusList
              + N' where classID <> @ClassID ';
        EXEC sys.sp_executesql @vquery,
                               @Params,
                               @RemoveOtherClass OUTPUT,
                               @ClassId;

        -------------------------------------------------------------
        -- insert object with class changed into status list
        -------------------------------------------------------------
        SET @ProcedureStep = 'Reset rows not in class';

        IF @RemoveOtherClass > 0
        BEGIN
            -- get records with other class in class_id and set to deleted
            SET @Count = 0;

            IF @Debug > 0
                SELECT @RemoveOtherClass AS count_of_OtherClassObjects;

            DECLARE @RemoveClassObjids NVARCHAR(MAX);

            --get objids of rows that changed class
            SET @Query = NULL;
            SET @Query
                = N' SELECT distinct sl.objectid,4
           FROM ' + @TempStatusList
                  + N' AS sl
                  left join #objidTable t
                  on t.objid = sl.objectid
                   WHERE sl.ClassID <> @ClassId
                   and t.objid is null;                  
  
  '         ;

            IF @Debug > 0
                SELECT @Query;

            IF @Query IS NOT NULL
                INSERT INTO #ObjidTable
                (
                    objid,
                    Type
                )
                EXEC sys.sp_executesql @Query, N'@ClassID int', @ClassId;

            SET @Query = NULL;

            SET @Query
                = N' Update t
 set type  = 4
 From ' +   @TempStatusList
                  + N' AS sl
                  inner join #objidTable t
                  on t.objid = sl.objectid
                   WHERE sl.ClassID <> @ClassId;                                    
                   ';
            IF @Query IS NOT NULL
                EXEC sys.sp_executesql @Query, N'@ClassID int', @ClassId;

            IF @Debug > 0
                SELECT '@RemoveClassObjids',
                       *
                FROM #ObjidTable AS ot
                WHERE ot.Type = 4;

            SET @Query = NULL;

            SET @Query
                = N' Delete FROM ' + QUOTENAME(@MFTableName)
                  + N'
        WHERE objid in (Select t.objid from #objidTable t where type = 4) ;';

            IF @Debug > 0
                SELECT @Query;

            IF @Query IS NOT NULL
                EXEC sys.sp_executesql @Query;

            SET @Count = @@RowCount;
            SET @DebugText = N' Delete rows with other classes %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            -------------------------------------------------------------
            -- update other class
            -------------------------------------------------------------
            SET @ProcedureStep = 'UPdate Other Class Table';

            DECLARE @OtherMFTableName NVARCHAR(100);

            IF EXISTS
            (
                SELECT t.TABLE_NAME
                FROM INFORMATION_SCHEMA.TABLES AS t
                WHERE t.TABLE_NAME = @OtherMFTableName
            )
            BEGIN

                SET @Query
                    = N' SELECT TOP 1
                @OtherMFTableName = mc.TableName
            FROM ' + @TempStatusList
                      + N'  AS sl
                INNER JOIN dbo.MFClass AS mc
                    ON sl.ClassID = mc.MFID
            WHERE sl.ClassID <> @ClassId';

                EXEC sys.sp_executesql @Query,
                                       N'@OtherMFTableName nvarchar(100) output, @classID int',
                                       @OtherMFTableName OUTPUT,
                                       @ClassId;

                IF @OtherMFTableName IS NOT NULL
                BEGIN
                    -------------------------------------------------------------
                    -- reset audit table with class change
                    -------------------------------------------------------------

                    SET @Query = NULL;
                    SET @Query
                        = N' Update ah
           set Class = sl.ClassID, StatusFlag = 1, StatusName = ''MFnotinSQL''
           FROM ' + @TempStatusList
                          + N' AS sl
                  inner join MFauditHistory ah
                  on ah.objid = sl.objectid
                   WHERE sl.ClassID <> @ClassId 
                   and ah.class = @ClassId;   ';

                    IF @Query IS NOT NULL
                        EXEC sys.sp_executesql @Query, N'@ClassID int', @ClassId;

                    -------------------------------------------------------------
                    -- remove items from other class
                    -------------------------------------------------------------

                    SELECT @RemoveClassObjids = STUFF(
                                                (
                                                    SELECT ',' + CAST(ot.objid AS VARCHAR(10))
                                                    FROM #ObjidTable AS ot
                                                    WHERE ot.Type = 4
                                                    FOR XML PATH('')
                                                ),
                                                1,
                                                1,
                                                ''
                                                     );

                    SET @ProcedureStep = 'Remove from class';

                    SET @DebugText = N' %s @RemoveClassObjids %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(
                                     @DebugText,
                                     10,
                                     1,
                                     @ProcedureName,
                                     @ProcedureStep,
                                     @OtherMFTableName,
                                     @RemoveClassObjids
                                 );
                    END;

                    BEGIN
                        EXEC dbo.spMFUpdateTable @MFTableName = @OtherMFTableName,
                                                 @UpdateMethod = 1,
                                                 @ObjIDs = @RemoveClassObjids,
                                                 @Update_IDOut = @Update_IDOut OUTPUT,
                                                 @ProcessBatch_ID = @ProcessBatch_ID,
                                                 @Debug = @Debug;

                        SET @Query
                            = N' SElect @Count = COUNT(*) FROM ' + QUOTENAME(@OtherMFTableName)
                              + N'
                         WHERE update_ID = @Update_IDOut;';

                        EXEC sys.sp_executesql @Query,
                                               N'@count int output, @Update_IDOut int',
                                               @Count OUTPUT,
                                               @Update_IDOut;

                    END; --delete from other table
                    SET @DebugText = N' Delete rows with different class %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                    END;


                END; --update table for other class
            END; -- if other table exist
        END; -- if other class > 0

        -- end processing deletes
        -------------------------------------------------------------
        -- Remove records returned from M-Files that is not part of the class
        -------------------------------------------------------------
        SET @ProcedureStep = 'Remove redundant records';
        SET @Query
            = N'SELECT @Count = COUNT(ISNULL(sl.ObjectID, 0))
    FROM ' + @TempStatusList
              + N' AS sl
    WHERE sl.Status = ''NotInClass''
    GROUP BY sl.ObjectID,
        sl.Status;';

        EXEC sys.sp_executesql @Query, N'@count int output', @Count OUTPUT;

        SET @DebugText = N' Deleted items ' + CAST(ISNULL(@Count, 0) AS NVARCHAR(100));
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @ProcedureStep = 'Add logging';
        SET @ProcedureStep = 'Deleted records';
        SET @LogTypeDetail = N'Debug';
        SET @LogTextDetail = N'Deletions';
        SET @LogStatusDetail = N'InProgress';
        SET @Validation_ID = NULL;
        SET @LogColumnName = N'Deletions';
        SET @LogColumnValue = ISNULL(CAST(@Count AS VARCHAR(10)), 0);

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

        -------------------------------------------------------------
        -- Update SQL
        -------------------------------------------------------------
        SET @ProcedureStep = 'Update History';
        SET @StartTime = GETUTCDATE();

        IF (@Update_ID > 0)
            UPDATE dbo.MFUpdateHistory
            SET NewOrUpdatedObjectVer = @XmlOUT,
                NewOrUpdatedObjectDetails = @NewObjectXml,
                SynchronizationError = @SynchErrorObj,
                DeletedObjectVer = @DeletedXML,
                MFError = @ErrorInfo
            WHERE Id = @Update_ID;

        --New/ update Details count & log
        DECLARE @NewOrUpdatedObjectDetails_Count INT,
                @NewOrUpdateObjectXml XML;

        SET @ProcedureStep = 'Prepare XML for update into SQL';
        SET @NewOrUpdateObjectXml = CAST(@NewObjectXml AS XML);

        SELECT @NewOrUpdatedObjectDetails_Count = COUNT(o.objectid)
        FROM
        (
            SELECT t1.c1.value('(@objectId)[1]', 'INT') AS objectid
            FROM @NewOrUpdateObjectXml.nodes('/form/Object') AS t1(c1)
        ) AS o;

        SET @LogTypeDetail = N'Debug';
        SET @LogTextDetail = N'XML NewOrUpdatedObjectDetails returned';
        SET @LogStatusDetail = N'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = CAST(@NewOrUpdatedObjectDetails_Count AS VARCHAR(10));
        SET @LogColumnName = N'NewOrUpdatedObjectDetails';

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

        --new/update version count and log
        DECLARE @NewOrUpdatedObjectVer_Count INT,
                @NewOrUpdateObjectVerXml XML;

        SET @NewOrUpdateObjectVerXml = CAST(@XmlOUT AS XML);

        SELECT @NewOrUpdatedObjectVer_Count = COUNT(o.objectid)
        FROM
        (
            SELECT t1.c1.value('(@objectId)[1]', 'INT') AS objectid
            FROM @NewOrUpdateObjectVerXml.nodes('/form/Object') AS t1(c1)
        ) AS o;

        SET @LogTypeDetail = N'Debug';
        SET @LogTextDetail = N'ObjVer returned';
        SET @LogStatusDetail = N'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = CAST(@NewOrUpdatedObjectVer_Count AS VARCHAR(10));
        SET @LogColumnName = N'NewOrUpdatedObjectVer';

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

        SET @ProcedureName = 'SpmfUpdateTable';
        SET @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';
        SET @StartTime = GETUTCDATE();

        CREATE TABLE #ObjVer
        (
            ID INT,
            ObjID INT,
            MFVersion INT,
            GUID NVARCHAR(100),
            FileCount INT ---- Added for task 106
        );

        DECLARE @NewObjVerDetails_Count INT;

        INSERT INTO #ObjVer
        (
            MFVersion,
            ObjID,
            ID,
            GUID,
            FileCount
        )
        SELECT t.c.value('(@objVersion)[1]', 'INT') AS MFVersion,
               t.c.value('(@objectId)[1]', 'INT') AS ObjID,
               t.c.value('(@ID)[1]', 'INT') AS ID,
               t.c.value('(@objectGUID)[1]', 'NVARCHAR(100)') AS GUID,
               t.c.value('(@FileCount)[1]', 'INT') AS FileCount -- Added for task 106
        FROM @NewOrUpdateObjectVerXml.nodes('/form/Object') AS t(c);

        SET @Count = @@RowCount;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            IF @Debug > 100
                SELECT '#objver',
                       *
                FROM #ObjVer;
        END;

        DECLARE @UpdateQuery NVARCHAR(MAX);

        SET @UpdateQuery
            = N'	UPDATE [' + @MFTableName + N']
					SET [' + @MFTableName + N'].ObjID = #ObjVer.ObjID
					,['    + @MFTableName + N'].MFVersion = #ObjVer.MFVersion
					,['    + @MFTableName + N'].GUID = #ObjVer.GUID
					,['    + @MFTableName
              + N'].FileCount = #ObjVer.FileCount  
					,Process_ID = 0
					,LastModified = GETDATE()
					FROM #ObjVer
					WHERE [' + @MFTableName + N'].ID = #ObjVer.ID';

        EXEC (@UpdateQuery);

        SET @ProcedureStep = 'Update Records in ' + @MFTableName + '';
        SET @LogTextDetail = @ProcedureStep;
        SET @LogStatusDetail = N'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnName = N'NewObjVerDetails';
        SET @LogColumnValue = CAST(ISNULL(@NewObjVerDetails_Count, 0) AS VARCHAR(10));

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

        DROP TABLE #ObjVer;

        ----------------------------------------------------------------------------------------------------------
        --Update Process_ID to 2 when synch error occcurs--
        ----------------------------------------------------------------------------------------------------------
        SET @ProcedureStep = 'when synch error occurs';
        SET @StartTime = GETUTCDATE();

        ----------------------------------------------------------------------------------------------------------
        --Create an internal representation of the XML document. 
        ---------------------------------------------------------------------------------------------------------                
        CREATE TABLE #SynchErrObjVer
        (
            ID INT,
            ObjID INT,
            MFVersion INT
        );

        -----------------------------------------------------
        ----Inserting the Xml details into temp Table
        -----------------------------------------------------
        DECLARE @SynchErrorXML XML;

        SET @SynchErrorXML = CAST(@SynchErrorObj AS XML);

        INSERT INTO #SynchErrObjVer
        (
            MFVersion,
            ObjID,
            ID
        )
        SELECT t.c.value('(@objVersion)[1]', 'INT') AS MFVersion,
               t.c.value('(@objectId)[1]', 'INT') AS ObjID,
               t.c.value('(@ID)[1]', 'INT') AS ID
        FROM @SynchErrorXML.nodes('/form/Object') AS t(c);

        SELECT @SynchErrCount = COUNT(ISNULL(ID, 0))
        FROM #SynchErrObjVer;

        IF @SynchErrCount > 0
        BEGIN
            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s Count %i ', 10, 1, @ProcedureName, @ProcedureStep, @SynchErrCount);

                IF @Debug > 10
                    SELECT *
                    FROM #SynchErrObjVer;
            END;

            SET @LogTypeDetail = N'User';
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = N'Error';
            SET @Validation_ID = 2;
            SET @LogColumnName = N'Synch Errors';
            SET @LogColumnValue = ISNULL(CAST(@SynchErrCount AS VARCHAR(10)), 0);

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

            -------------------------------------------------------------------------------------
            -- UPDATE THE SYNCHRONIZE ERROR
            -------------------------------------------------------------------------------------
            DECLARE @SynchErrUpdateQuery NVARCHAR(MAX);

            SET @DebugText = N' Update sync errors';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @SynchErrUpdateQuery
                = N'	UPDATE [' + @MFTableName + N']
					SET ['             + @MFTableName + N'].ObjID = #SynchErrObjVer.ObjID	,[' + @MFTableName
                  + N'].MFVersion = #SynchErrObjVer.MFVersion
					,Process_ID = 2
					,LastModified = GETDATE()
					,Update_ID = '     + CAST(@Update_ID AS VARCHAR(15)) + N'
					FROM #SynchErrObjVer
					WHERE ['           + @MFTableName + N'].ID = #SynchErrObjVer.ID';

            EXEC (@SynchErrUpdateQuery);

            ------------------------------------------------------
            -- LOGGING THE ERROR
            ------------------------------------------------------
            SET @DebugText = N'log errors';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            ------------------------------------------------------
            --Getting @SyncPrecedence from MFClasss table for @TableName
            --IF NULL THEN insert error in error log 
            ------------------------------------------------------
            DECLARE @SyncPrecedence INT;

            SELECT @SyncPrecedence = SynchPrecedence
            FROM dbo.MFClass
            WHERE TableName = @TableName;

            IF @SyncPrecedence IS NULL
            BEGIN
                INSERT INTO dbo.MFLog
                (
                    ErrorMessage,
                    Update_ID,
                    ErrorProcedure,
                    ExternalID,
                    ProcedureStep,
                    SPName
                )
                SELECT *
                FROM
                (
                    SELECT 'Synchronization error occured while updating ObjID : ' + CAST(ObjID AS NVARCHAR(10))
                           + ' Version : ' + CAST(MFVersion AS NVARCHAR(10)) + '' AS ErrorMessage,
                           @Update_ID AS Update_ID,
                           @TableName AS ErrorProcedure,
                           '' AS ExternalID,
                           'Synchronization Error' AS ProcedureStep,
                           'spMFUpdateTable' AS SPName
                    FROM #SynchErrObjVer
                ) AS vl;
            END;
        END;
        --end of if syncerror count
        DROP TABLE #SynchErrObjVer;

        -------------------------------------------------------------
        --Logging error details
        -------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Perform checking for SQL Errors ';

        CREATE TABLE #ErrorInfo
        (
            ObjID INT,
            SqlID INT,
            ExternalID NVARCHAR(100),
            ErrorMessage NVARCHAR(MAX)
        );

        DECLARE @ErrorInfoXML XML;

        SELECT @ErrorInfoXML = CAST(@ErrorInfo AS XML);

        INSERT INTO #ErrorInfo
        (
            ObjID,
            SqlID,
            ExternalID,
            ErrorMessage
        )
        SELECT t.c.value('(@objID)[1]', 'INT') AS objID,
               t.c.value('(@sqlID)[1]', 'INT') AS SqlID,
               t.c.value('(@externalID)[1]', 'NVARCHAR(100)') AS ExternalID,
               t.c.value('(@ErrorMessage)[1]', 'NVARCHAR(MAX)') AS ErrorMessage
        FROM @ErrorInfoXML.nodes('/form/errorInfo') AS t(c);

        SELECT @ErrorInfoCount = COUNT(ISNULL(SqlID, 0))
        FROM #ErrorInfo;

        IF @ErrorInfoCount > 0
        BEGIN
            IF @Debug > 10
            BEGIN
                SELECT *
                FROM #ErrorInfo;
            END;

            SET @DebugText = N'SQL Error logging errors found ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @MFErrorUpdateQuery
                = N'UPDATE [' + @MFTableName
                  + N']
									   SET Process_ID = 3
									   FROM #ErrorInfo err
									   WHERE err.SqlID = [' + @MFTableName + N'].ID';

            EXEC (@MFErrorUpdateQuery);

            SET @ProcedureStep = 'M-Files Errors ';
            SET @LogTypeDetail = N'User';
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = N'Error';
            SET @Validation_ID = 3;
            SET @LogColumnName = N'M-Files errors';
            SET @LogColumnValue = ISNULL(CAST(@ErrorInfoCount AS VARCHAR(10)), 0);

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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

            INSERT INTO dbo.MFLog
            (
                ErrorMessage,
                Update_ID,
                ErrorProcedure,
                ExternalID,
                ProcedureStep,
                SPName
            )
            SELECT 'ObjID : ' + CAST(ISNULL(ObjID, '') AS NVARCHAR(100)) + ',' + 'SQL ID : '
                   + CAST(ISNULL(SqlID, '') AS NVARCHAR(100)) + ',' + ErrorMessage AS ErrorMessage,
                   @Update_ID,
                   @TableName AS ErrorProcedure,
                   ExternalID,
                   'Error While inserting/Updating in M-Files' AS ProcedureStep,
                   'spMFUpdateTable' AS spname
            FROM #ErrorInfo;
        END;
        --end of error count
        DROP TABLE #ErrorInfo;

        ------------------------------------------------------------------
        --        SET @NewObjectXml = CAST(@NewObjectXml AS NVARCHAR(MAX));
        -------------------------------------------------------------------------------------
        -- CALL SPMFUpadteTableInternal TO INSERT PROPERTY DETAILS INTO TABLE
        -------------------------------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureName = 'spMFUpdateTableInternal';
        SET @ProcedureStep = 'Update property details from M-Files ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @StartTime = GETUTCDATE();

        IF (
               @NewObjectXml != '<form />'
               OR @NewObjectXml <> ''
               OR @NewObjectXml <> NULL
           )
        BEGIN
            IF @Debug > 10
                SELECT @NewObjectXml AS [@NewObjectXml before updateobjectinternal];

            EXEC @return_value = dbo.spMFUpdateTableInternal @MFTableName,
                                                             @NewObjectXml,
                                                             @Update_ID,
                                                             @Debug = @Debug,
                                                             @SyncErrorFlag = @SyncErrorFlag;

            IF @return_value <> 1
                RAISERROR('Proc: %s Step: %s FAILED ', 16, 1, @ProcedureName, @ProcedureStep);
        END; -- end update table internal

        --IF @debug > 0
        --SELECT 'pre-update audit table', * FROM dbo.MFvwAuditSummary AS mfas;
        -------------------------------------------------------------
        -- Update MFaudithistory for all updated records
        -------------------------------------------------------------
        SET @ProcedureStep = 'Update MFaudithistory ';

  
  BEGIN TRANSACTION;

        SET @ProcedureStep = 'Update MFaudit History ';
        SET @Params = N'@Update_ID int, @ClassID int,@ObjectType int';
        SET @Query
            = N'
        UPDATE mah WITH (UPDLOCK, SERIALIZABLE)
        SET mah.StatusFlag = CASE 
        when sl.status = ''1'' and isnull(sl.AuditStatus,0) = 0 then 0
         WHEN sl.status = ''1'' and isnull(sl.AuditStatus,0) > 0 THEN 0
        WHEN sl.status = ''2'' THEN 3
        WHEN sl.status in (''3'',''Deleted'') THEN 4
         WHEN sl.Status = ''NotInClass'' THEN 5
        end,
            mah.StatusName = CASE 
            when sl.status = ''1'' AND isnull(sl.AuditStatus,0) = 0 then ''Identical''
           WHEN sl.status = ''1'' and sl.AuditStatus > 0 THEN ''Identical''
             WHEN sl.Status = ''2'' THEN ''Checked out''
            WHEN sl.Status = ''3'' then ''Deleted''
            WHEN sl.Status = ''NotInClass'' THEN ''Not in Class'' 
            END,
          RecID = t.ID
        ,SessionID = @Update_ID
        ,TranDate = GETDATE()
        ,MFVersion = t.MFVersion 
        ,updateFlag = 0
        FROM dbo.MFAuditHistory    AS mah
         inner join ' + @TempStatusList + N' sl
         ON sl.objectID = mah.objid 
         INNER JOIN ' + QUOTENAME(@MFTableName)
              + N'  t
         ON t.objid = mah.objid AND
         mah.class = @classid AND mah.objectType = @ObjectType;';

        EXEC sys.sp_executesql @Stmt = @Query,
                               @Params = @Params,
                               @ClassID = @ClassId,
                               @Update_ID = @Update_ID,
                               @ObjectType = @ObjectId;

        SET @rownr = @@RowCount;

        COMMIT TRANSACTION;

        SET @DebugText = N' Count ' + CAST(ISNULL(@rownr, 0) AS NVARCHAR(10));
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            SELECT @Query AS AuditUpdateQuery;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        BEGIN TRANSACTION;

        SET @ProcedureStep = 'insert new into Audit history';
        SET @Params = N'@Update_ID int, @ClassID int,@ObjectType int';
        SET @Query
            = N'INSERT INTO dbo.MFAuditHistory
  (
      RecID,
      SessionID,
      TranDate,
      ObjectType,
      Class,
      ObjID,
      MFVersion,
      StatusFlag,
      StatusName,
      UpdateFlag
  )
  SELECT t.id,
  t.UPDATE_ID,
  t.LastModified, 
  @ObjectType, 
 @ClassID,
  sl.ObjectID,
  t.MFVersion,
  CASE 
        WHEN isnull(sl.status,''1'') = ''1'' THEN 0
        WHEN sl.status = ''2'' THEN 3
        WHEN sl.status = ''3'' THEN 4
        WHEN sl.status  = ''NotInClass'' THEN 5
        end,
  CASE WHEN isnull(sl.status,''1'') = ''1'' THEN ''Identical''
             WHEN sl.Status = ''2'' THEN ''Checked out''
            WHEN sl.Status = ''3'' then ''Deleted''
            WHEN sl.Status = ''NotInClass'' THEN ''Not in Class'' 
            END, 0
  FROM ' + @TempStatusList + N' AS sl
  INNER JOIN ' + QUOTENAME(@MFTableName)
              + N' as t
  ON sl.ObjectID = t.objid
  left JOIN dbo.MFAuditHistory AS mah
  ON sl.ObjectID = mah.objid AND mah.class = @ClassId AND mah.ObjectType = @ObjectType
  WHERE mah.ObjID IS NULL;';

        IF @Debug > 0
            SELECT @Query AS AuditInsertQuery;

        EXEC sys.sp_executesql @Stmt = @Query,
                               @Params = @Params,
                               @ClassID = @ClassId,
                               @Update_ID = @Update_ID,
                               @ObjectType = @ObjectId;

        SET @rownr = @@RowCount;

        COMMIT TRANSACTION;

        SET @DebugText = N' Count ' + CAST(ISNULL(@rownr, 0) AS NVARCHAR(10));
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --IF @debug > 0
        --SELECT 'post-update audit table', * FROM dbo.MFvwAuditSummary AS mfas;


        SET @ProcedureStep = 'Delete redundant from audit history ';

        IF @ObjIDs IS NOT NULL
        BEGIN
            ;
            WITH CTE
            AS (SELECT mah.ID,
                       mah.ObjID
                FROM dbo.MFAuditHistory AS mah
                    INNER JOIN #ObjidTable AS fmpds
                        ON fmpds.objid = mah.ObjID
                WHERE mah.Class = @ClassId
                      AND mah.StatusFlag = 5)
            DELETE FROM dbo.MFAuditHistory
            WHERE ID IN
                  (
                      SELECT CTE.ID FROM CTE
                  );
        END;

        SET @rownr = @@ROWCOUNT;


        SET @DebugText = N' Count ' + CAST(ISNULL(@rownr, 0) AS NVARCHAR(10));
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --end of obids is not null
        -------------------------------------------------------------------------------------
        --Checked whether all data is updated. #1360
        ------------------------------------------------------------------------------------ 
        --EXEC ('update '+ @MFTableName +' set Process_ID=1 where id =2')
        SET @ProcedureStep = 'Check updated data ';

        --   IF @UpdateMethod = 0 AND @Debug > 0
        --    BEGIN

        --    DECLARE @Sql NVARCHAR(1000) = N'
        --    IF EXISTS(
        --SELECT  1 FROM ' + @MFTableName + N' WHERE Process_ID=1)'


        --     RAISERROR(''Error: All data is not updated'', 10, 1, @ProcedureName, @ProcedureStep);
        --     END               
        --EXEC(@sql)
        --   END;    --end of update method 0

        SET @ProcedureStep = 'Remove redundant items';

        -------------------------------------------------------------
        -- Remove redundant items from MFAuditHistory
        -------------------------------------------------------------

        SET @ProcedureStep = 'Delete class objects';

        IF @RetainDeletions = 0
        BEGIN
            SET @ProcedureStep = 'RetainDeletions = 0 ';
            SET @Query
                = N'DELETE FROM ' + QUOTENAME(@MFTableName) + N' WHERE ' + QUOTENAME(@DeletedColumn) + N' is not null';
            SET @Count = @@RowCount;
            SET @DebugText = N' Removed ' + CAST(ISNULL(@Count, 0) AS VARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            EXEC (@Query);
        END;
        --end of retain deletions
        SET @ProcedureName = 'spMFUpdateTable';
        SET @ProcedureStep = 'Set update Status';
        SET @Count = NULL;
        SET @Query
            = N'SELECT @rowcount = COUNT(isnull(id,0)) FROM ' + QUOTENAME(@TableName) + N' WHERE process_id = 4';

        EXEC sys.sp_executesql @Query, N'@rowcount int output', @Count OUTPUT;

        IF (@Count <> 0)
        BEGIN
            SET @return_value = 4;
        END;

        IF @Debug > 9
            RAISERROR(
                         'Proc: %s Step: %s ReturnValue %i Completed ',
                         10,
                         1,
                         @ProcedureName,
                         @ProcedureStep,
                         @return_value
                     );

        -------------------------------------------------------------
        -- Check if precedence is set and update records with synchronise errors
        -------------------------------------------------------------
        IF @SyncPrecedence IS NOT NULL
        BEGIN
            EXEC dbo.spMFUpdateSynchronizeError @TableName = @MFTableName,           -- varchar(100)
                                                @Update_ID = @Update_IDOut,          -- int
                                                @ProcessBatch_ID = @ProcessBatch_ID, -- int
                                                @Debug = 0;                          -- int
        END;

        -- end of sync precedence
        -------------------------------------------------------------
        -- Finalise logging
        -------------------------------------------------------------
        DECLARE @MessageSwitch SMALLINT;

        SET @MessageSwitch = CASE
                                 WHEN @return_value = 1
                                      AND @SynchErrCount = 0
                                      AND @ErrorInfoCount = 0 THEN
                                     1
                                 WHEN @return_value = 1
                                      AND
                                      (
                                          @SynchErrCount = 1
                                          OR @ErrorInfoCount = 1
                                      ) THEN
                                     2
                                 WHEN @return_value <> 1
                                      AND @SynchErrCount = 1
                                      AND @ErrorInfoCount = 3 THEN
                                     3
                                 WHEN @return_value <> 1
                                      AND @ErrorInfoCount > 0 THEN
                                     4
                                 ELSE
                                     -1
                             END;
        SET @ProcedureStep = 'Updating Table - Finalise ';
        SET @LogType = N'Message';
        SET @LogText
            = CASE
                  WHEN @MessageSwitch = 1 THEN
                      N'Update ' + @MFTableName + N':Update Method ' + CAST(@UpdateMethod AS VARCHAR(10))
                  WHEN @MessageSwitch = 2 THEN
                      N'Update ' + @MFTableName + N':Update Method ' + CAST(@UpdateMethod AS VARCHAR(10))
                      + N' Partial Completed '
                  WHEN @MessageSwitch = 3 THEN
                      N'Update ' + @MFTableName + N'with sycnronisation errors: process_id = 2 '
                  WHEN @MessageSwitch = 4 THEN
                      N'Update ' + @MFTableName + N'with MFiles errors: process_id = 3 '
              END;
        SET @LogStatus = CASE
                             WHEN @MessageSwitch = 1 THEN
                                 N'Completed'
                             WHEN @MessageSwitch = 2 THEN
                                 N'Partial'
                             WHEN @MessageSwitch IN ( 3, 4 ) THEN
                                 N'Errors'
                         END;

        UPDATE dbo.MFUpdateHistory
        SET UpdateStatus = @LogStatus
        WHERE Id = @Update_ID;

        -------------------------------------------------------------
        -- output completion message
        -------------------------------------------------------------
        EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                                          -- int
                                         @ProcessType = @ProcessType,
                                         @LogText = @LogText,
                                                          -- nvarchar(4000)
                                         @LogStatus = @LogStatus,
                                                          -- nvarchar(50)
                                         @debug = @Debug; -- tinyint

        EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                               @Update_ID = @Update_ID,
                                               @LogText = @LogText,
                                               @LogType = @LogType,
                                               @LogStatus = @LogStatus,
                                               @StartTime = @StartTime,
                                               @MFTableName = @MFTableName,
                                               @ColumnName = @LogColumnName,
                                               @ColumnValue = @LogColumnValue,
                                               @LogProcedureName = @ProcedureName,
                                               @LogProcedureStep = @ProcedureStep,
                                               @debug = @Debug;

    
    RETURN @return_value; --For More information refer Process Table      
END TRY
BEGIN CATCH
    --IF @idoc3 IS NOT NULL
    --    EXEC sys.sp_xml_removedocument @idoc3;

    IF @@TranCount <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    SET NOCOUNT ON;

    UPDATE dbo.MFUpdateHistory
    SET UpdateStatus = 'failed'
    WHERE Id = @Update_ID;

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
    ('spMFUpdateTable', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE(),
     ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

    IF @Debug > 9
    BEGIN
        SELECT ERROR_NUMBER() AS ErrorNumber,
               ERROR_MESSAGE() AS ErrorMessage,
               ERROR_PROCEDURE() AS ErrorProcedure,
               @ProcedureStep AS ProcedureStep,
               ERROR_STATE() AS ErrorState,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_LINE() AS ErrorLine;
    END;

    SET NOCOUNT OFF;

    RETURN -1; --For More information refer Process Table
END CATCH;
GO