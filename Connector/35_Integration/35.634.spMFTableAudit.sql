

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFTableAudit]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFTableAudit', -- nvarchar(100)
    @Object_Release = '4.9.27.69',   -- varchar(50)
    @UpdateFlag = 2;                 -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFTableAudit' --name of procedure
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
CREATE PROCEDURE dbo.spMFTableAudit
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFTableAudit
(
    @MFTableName NVARCHAR(128),
    @MFModifiedDate DATETIME = NULL,    --NULL to select all records
    @ObjIDs NVARCHAR(4000) = NULL,
    @SessionIDOut INT OUTPUT,           -- output of session id
    @NewObjectXml NVARCHAR(MAX) OUTPUT, -- return from M-Files
    @DeletedInSQL INT = 0 OUTPUT, -- number of items deleted
    @UpdateRequired BIT = 0 OUTPUT,     --1 is set when the result show a difference between MFiles and SQL  
    @OutofSync INT = 0 OUTPUT,          -- > 0 eminent Sync Error when update from SQL to MF is processed
    @ProcessErrors INT = 0 OUTPUT,      -- > 0 unfixed errors on table
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0                 -- use 102 for listing of full tables during debugging
)
AS
/*rST**************************************************************************

==============
spMFTableAudit
==============

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(128)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @MFModifiedDate datetime
    Filter by MFiles Last Modified date as a datetime string. Set to null if all records must be selected
  @ObjIDs nvarchar(4000)
    Filter by comma delimited string of objid of the objects to process. Set as null if all records must be included
  @SessionIDOut int (output)
    Output of the session id used to update table MFAuditHistory
  @NewObjectXml nvarchar(max) (output)
    Output of the objver of the record set as a result in nvarchar datatype. This can be converted to an XML record for further processing
  @DeletedInSQL int (output)
    Output the number of items that will be marked as deleted when processing the next spmfUpdateTable
  @UpdateRequired bit (output)
    Set to 1 if any condition exist where M-Files and SQL is not the same.  This can be used to trigger a spmfUpdateTable only when it necessary
  @OutofSync int (output)
    If > 0 then the next updatetable procedure will have synchronisation errors
  @ProcessErrors int (output)
    If > 0 then there are unresolved errors in the table with process_id = 3 or 4
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Update MFAuditHistory and return the sessionid and the M-Files objver of the selection class as a varchar that can be converted to XML if there is a need for further processing of the result.

Additional Info
===============

At the same time spMFTableAudit will set the deleted flag for all the records in the Class Table that is deleted in M-Files.  This is particularly relevant when this procedure is used in conjunction with the spMFUpdateTable procedure with the filter MFLastModified set.

Examples
========

.. code:: sql

    DECLARE @SessionIDOut INT
           ,@NewObjectXml NVARCHAR(MAX)
           ,@DeletedInSQL INT
           ,@UpdateRequired BIT
           ,@OutofSync INT
           ,@ProcessErrors INT
           ,@ProcessBatch_ID INT;

    EXEC [dbo].[spMFTableAudit]
               @MFTableName = N'MFCustomer' -- nvarchar(128)
              ,@MFModifiedDate = null -- datetime
              ,@ObjIDs = null -- nvarchar(4000)
              ,@SessionIDOut = @SessionIDOut OUTPUT -- int
              ,@NewObjectXml = @NewObjectXml OUTPUT -- nvarchar(max)
              ,@DeletedInSQL = @DeletedInSQL OUTPUT -- int
              ,@UpdateRequired = @UpdateRequired OUTPUT -- bit
              ,@OutofSync = @OutofSync OUTPUT -- int
              ,@ProcessErrors = @ProcessErrors OUTPUT -- int
              ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
              ,@Debug = 0 -- smallint

    SELECT @SessionIDOut AS 'session', @UpdateRequired AS UpdateREquired, @OutofSync AS OutofSync, @ProcessErrors AS processErrors
    SELECT * FROM [dbo].[MFProcessBatch] AS [mpb] WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID
    SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-04-01  LC         Add statusflag for Collections
2020-09-08  LC         Update to include status code 5 object does not exist
2020-09-04  LC         Add update locking and commit to improve performance
2020-08-22  LC         update to take into account new deleted column
2019-12-10  LC         Fix bug for the removal of records from class table
2019-10-31  LC         Fix bug - change Class_id to Class in delete object section 
2019-09-12  LC         Fix bug - remove deleted objects from table
2019-08-30  JC         Added documentation
2019-08-16  LC         Fix bug for removing destroyed objects
2019-06-22  LC         Objid parameter not yet functional
2019-05-18  LC         Add additional exception for deleted in SQL but not deleted in MF
2019-04-11  LC         Fix collection object type in table
2019-04-11  LC         Add large table protection
2019-04-11  LC         Add validation table exists
2018-12-15  LC         Add ability to get result for selected objids
2018-08-01  LC         Resolve issue with having try catch in transaction processing
2017-12-28  LC         Change insert to merge on audit table
2017-12-27  LC         Remove incorrect error message
2017-08-28  LC         Add param for update required
2017-08-28  LC         Add logging
2017-08-28  LC         Change sequence of params
2016-08-22  LC         Change objids to NVARCHAR(4000)
==========  =========  ========================================================

**rST*************************************************************************/

/*

DECLARE @SessionIDOut int, @return_Value int, @NewXML nvarchar(max)
EXEC @return_Value = spMFTableAudit 'MFOtherdocument' , null, null, 1, @SessionIDOut = @SessionIDOut output, @NewObjectXml = @NewXML output
SELECT @SessionIDOut ,@return_Value, @NewXML

*/

-------------------------------------------------------------
-- CONSTANTS: MFSQL Class Table Specific
-------------------------------------------------------------
SET NOCOUNT ON;

DECLARE @ProcessType AS NVARCHAR(50);

SET @ProcessType = N'Table Audit';

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
DECLARE @ProcedureName AS NVARCHAR(128) = N'spMFTableAudit';
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
    @debug = @Debug;

EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
    @LogType = N'Debug',
    @LogText = @LogText,
    @LogStatus = N'Started',
    @StartTime = @StartTime,
    @MFTableName = @MFTableName,
    @Validation_ID = @Validation_ID,
    @ColumnName = NULL,
    @ColumnValue = NULL,
    @Update_ID = @Update_ID,
    @LogProcedureName = @ProcedureName,
    @LogProcedureStep = @ProcedureStep,
    @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
    @debug = @Debug;

BEGIN TRY
    SET XACT_ABORT ON;

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    DECLARE @Id          INT,
        @objID           INT,
        @ObjectIdRef     INT,
        @ObjVersion      INT,
        @XMLOut          NVARCHAR(MAX),
        @ObjIDsForUpdate NVARCHAR(MAX),
        @MinObjid        INT,
        @MaxObjid        INT,
        @DefaultDate     DATETIME       = '1975-01-01',
                                        --             @Output NVARCHAR(200) ,
        @FullXml         XML,           --
        @SynchErrorObj   NVARCHAR(MAX), --Declared new paramater
        @DeletedObjects  NVARCHAR(MAX), --Declared new paramater
        @ObjectId        INT,
        @ClassId         INT,
        @ErrorInfo       NVARCHAR(MAX),
        @MFIDs           NVARCHAR(2500) = N'',
        @RunTime         VARCHAR(20),
        @DeletedColumn   NVARCHAR(100),
        @MFidsNotFound BIT = 0;

        -------------------------------------------------------------
        -- get deleted column name
        -------------------------------------------------------------

        SELECT @DeletedColumn = columnName FROM MFProperty WHERE mfid = 27;


    DECLARE @Idoc INT;

    SET @StartTime = GETUTCDATE();

    IF EXISTS
    (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND type IN ( N'U' )
    )
    BEGIN

        --        BEGIN TRAN [main];
        --IF @Debug > 0
        --BEGIN
        --    SET @RunTime = CONVERT(VARCHAR(20), GETDATE());

        --    RAISERROR('Proc: %s Step: %s Time: %s', 10, 1, @ProcedureName, @ProcedureStep, @RunTime);
        --END;

        -----------------------------------------------------
        --Set Object Type Id and class id
        -----------------------------------------------------
        SET @ProcedureStep = N'Get Object Type and Class';

        SELECT @ObjectIdRef = mc.MFObjectType_ID,
            @ObjectId       = ob.MFID,
            @ClassId        = mc.MFID
        FROM dbo.MFClass                AS mc
            INNER JOIN dbo.MFObjectType AS ob
                ON ob.ID = mc.MFObjectType_ID
        WHERE mc.TableName = @MFTableName;

        IF @Debug > 0
        BEGIN
            RAISERROR(
                         'Proc: %s Step: %s ObjectType: %i Class: %i',
                         10,
                         1,
                         @ProcedureName,
                         @ProcedureStep,
                         @ObjectId,
                         @ClassId
                     );

        --SELECT *
        --FROM [dbo].[MFClass]
        --WHERE [MFID] = @ClassId;
        END;

        --SET @DebugText = 'ObjectIDs for update %s';
        --SET @DebugText = @DefaultDebugText + @DebugText;
        --SET @ProcedureStep = '';

        --IF @Debug > 0
        --BEGIN
        --    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDsForUpdate);
        --END;

        -------------------------------------------------------------
        -- Get class table name
        -------------------------------------------------------------
        DECLARE @ClassTableColumn NVARCHAR(100);

        SELECT @ClassTableColumn = ColumnName
        FROM dbo.MFProperty
        WHERE MFID = 100;

        -----------------------------------------------------
        --Wrapper Method
        -----------------------------------------------------
        SET @ProcedureStep = N'Filters';

        SELECT @ObjIDsForUpdate = @ObjIDs;

        SET @DebugText = N':on objids %s ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDsForUpdate);
        END;

        SET @DefaultDate = CASE
                               WHEN @ObjIDs IS NOT NULL THEN
                                   @DefaultDate
                               WHEN @MFModifiedDate IS NULL THEN
                                   @DefaultDate
                               ELSE
                                   @MFModifiedDate
                           END;
        SET @DebugText = N' :on date ' + CAST(@DefaultDate AS NVARCHAR(30));
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @ProcedureStep = N' Wrapper: getObjectvers ';

        EXEC @return_value = dbo.spMFGetObjectvers @TableName = @MFTableName, -- nvarchar(max)
            @dtModifiedDate = @DefaultDate,                                   -- datetime
            @MFIDs = @ObjIDs,                                                 -- nvarchar(max)
            @outPutXML = @NewObjectXml OUTPUT,                                -- nvarchar(max)
            @ProcessBatch_ID = @ProcessBatch_ID,
            @Debug = @Debug;

			IF @Debug > 0
			SELECT CAST(@NewObjectXml AS XML) , @NewObjectXml;

        EXEC sys.sp_xml_preparedocument @Idoc OUTPUT, @NewObjectXml;

        IF @NewObjectXml = '<form></form>' AND @ObjIDs IS NOT NULL
        SET @MFidsNotFound = 1;
          
          		IF @Debug > 0
			SELECT @MFidsNotFound  AS MFIDsisNotFound, @objids AS objids;
          
        BEGIN
            SET @ProcedureStep = N'Create Temp table';

            IF
            (
                SELECT OBJECT_ID('tempdb..#AllObjects')
            ) IS NOT NULL
                DROP TABLE #AllObjects;

            CREATE TABLE #AllObjects
            (
                ID INT,
                Class INT,
                ObjectType INT,
                [ObjID] INT,
                MFVersion INT,
                Deleted NVARCHAR(10),
                LastModifiedUtc datetime,
                CheckedOutTo INT,
                LatestCheckedInVersion INT,
                StatusFlag SMALLINT
            );

            CREATE INDEX idx_AllObjects_ObjID ON #AllObjects ([ObjID]);

            SET @ProcedureStep = N' Insert items in Temp Table';

            IF  @NewObjectXml <> '<form></form>'
            Begin
            WITH cte
            AS (SELECT distinct xmlfile.[objId],
                    xmlfile.MFVersion,
                    xmlfile.ObjType,
                    xmlfile.Deleted,
                    xmlfile.LastModifiedUtc,
                    xmlfile.CheckedOutTo,
                    xmlfile.LatestCheckedInVersion
                    FROM

                    OPENXML(@Idoc, '/form/objVers', 1)
                    WITH
                    (
                        objId INT './@objectID',
                        MFVersion INT './@version',
                        --         ,[GUID] NVARCHAR(100) './@objectGUID'
                        ObjType INT './@objectType',
                        Deleted nvarchar(10) './@Deleted',
                        LastModifiedUtc datetime './@LastModifiedUtc',
                        CheckedOutTo INT './@CheckedOutTo',
                        LatestCheckedInVersion INT './@LatestCheckedInVersion'
                    ) xmlfile			
					)
            INSERT INTO #AllObjects
            (
                Class,
                ObjectType,
                MFVersion,
                ObjID,
                Deleted,
                LastModifiedUtc,
                CheckedOutTo,
                LatestCheckedInVersion
            )
            SELECT @ClassId,
                cte.ObjType,
                cte.MFVersion,
                cte.objId,
                cte.Deleted,
                cte.LastModifiedUtc,
                cte.CheckedOutTo,
                cte.LatestCheckedInVersion
            FROM cte;

            END

            IF @MFidsNotFound = 1
            BEGIN
            
            INSERT INTO #AllObjects
            (
                ID,
                Class,
                ObjectType,
                ObjID,
                MFVersion,
                Deleted,
                LastModifiedUtc,
                CheckedOutTo,
                LatestCheckedInVersion,
                StatusFlag
            )
           SELECT mah.id, @ClassId, @ObjectId, fmpds.ListItem, NULL, 'True', NULL, 0, NULL, 4 FROM dbo.fnMFParseDelimitedString(@ObjIDs,',') AS fmpds
           left JOIN dbo.MFAuditHistory AS mah
           ON fmpds.ListItem = mah.objid AND mah.Class = @ClassId AND mah.ObjectType = @ObjectId 

           END

		SELECT @rowcount = ISNULL(COUNT(ao.objid),0) FROM #AllObjects AS ao

		Set @DebugText = ' count ' + CAST(ISNULL(@rowcount,0) AS NVARCHAR(10))
		Set @DebugText = @DefaultDebugText + @DebugText
		Set @Procedurestep = ' Create #AllObjects '
		
		IF @debug > 0
			Begin
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
			END
		

            IF @Idoc IS NOT null
			EXEC sys.sp_xml_removedocument @Idoc;


            SET @ProcedureStep = N'Get Object Versions';
            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = N'Debug';
            SET @LogTextDetail = N'Objects from M-Files';
            SET @LogStatusDetail = N'Status';
            SET @LogColumnName = N'Objvers returned';
            SET @LogColumnValue = CAST(ISNULL(@rowcount,0) AS VARCHAR(10));

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
                @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
                @debug = 0;

            IF @Debug > 0
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                SELECT 'PreFlag',
                    *
                FROM #AllObjects AS ao;
            END;

            DECLARE @Query NVARCHAR(MAX),
                @SessionID INT,
                @TranDate  DATETIME,
                @Params    NVARCHAR(MAX);

            SELECT @TranDate = GETDATE();

            SET @ProcedureStep = N'Get Session ID';

            -- check if MFAuditHistory has been initiated
            SELECT @count = COUNT(ISNULL(id,0))
            FROM dbo.MFAuditHistory AS mah;
           
            SELECT @SessionID = CASE
                                    WHEN @SessionIDOut IS NULL
                                         AND @count = 0 THEN
                                        1
                                    WHEN @SessionIDOut IS NULL
                                         AND @count > 0 THEN
            (
                SELECT MAX(ISNULL(SessionID, 0)) + 1 FROM dbo.MFAuditHistory
            )
                                    ELSE
                                        @SessionIDOut
                                END;

            SET @DebugText =  CAST(@SessionID AS NVARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- pre validations
            -------------------------------------------------------------
            /*

0 = identical : [ao].[LatestCheckedInVersion] = [t].[MFVersion] AND [ao].[deleted]= 'False' and DeletedColumn is null
1 = MF IS Later : [ao].[LatestCheckedInVersion] > [t].[MFVersion]  
2 = SQL is later : ao.[LatestCheckedInVersion] < ISNULL(t.[MFVersion],-1) 
3 = Checked out : ao.CheckedoutTo <> 0
4 =  Deleted SQL to be updated : WHEN isnull(ao.[Deleted],'True' and isnull(t.DeletedColumn,'False')
5 =  In SQL Not in audit table : N t.[MFVersion] is null and ao.[MFVersion] is not null   
6 = Not yet process in SQL : t.id IS NOT NULL AND t.objid IS NULL
9 = Object is collection : ObjectType = 9 
*/
            SET @ProcedureStep = N' set id and flags ';

            SELECT @Query
                = N'UPDATE ao
SET ao.[ID] = t.id
,StatusFlag = CASE 
WHEN ao.ObjectType = 9 then 9
WHEN isnull(ao.CheckedOutTo,0) <> 0 then 3
WHEN ISNULL(ao.Deleted,''False'') = ''True''  THEN 4
WHEN ao.[LatestCheckedInVersion] < ISNULL(t.[MFVersion],-1) THEN 2
WHEN [ao].[LatestCheckedInVersion] > ISNULL([t].[MFVersion],-1)  THEN 1
WHEN [ao].[LatestCheckedInVersion] = ISNULL([t].[MFVersion],-1) THEN 0
WHEN ISNULL(ao.id,0) = 0 AND ISNULL(ao.[objid],0) > 0 THEN 6
END 
FROM [#AllObjects] AS [ao]
left JOIN ' +   QUOTENAME(@MFTableName) + N' t
ON ao.[objid] = t.[objid] ;';


  --                  select @Query;
  Set @DebugText = ''
  Set @DebugText = @DefaultDebugText + @DebugText

  
  IF @debug > 0
  	BEGIN
  		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
  	END
  

           EXEC sys.sp_executesql @Stmt = @Query;

                     SET @ProcedureStep = N' reset flag 5 ';
            -------------------------------------------------------------
            -- Insert records within the range of the audit that is in SQL but not in table audit
            -------------------------------------------------------------
            SET @Params = N'@ClassID int, @ObjectID int,  @ObjidsForUpdate nvarchar(max)';
            SET @sql
                = N'MERGE INTO [#AllObjects] t
           USING(
SELECT @ClassID AS Class,@ObjectId AS objectType,ct.MFVersion,ct.Objid FROM ' + QUOTENAME(@MFTableName)
                  + ' AS ct
INNER JOIN dbo.fnMFSplitString(@ObjIDsForUpdate,'','') AS fmss
ON fmss.Item = ct.objid) s
ON s.Class = t.Class AND s.ObjID = t.ObjID
WHEN NOT MATCHED THEN INSERT
(
Class,ID, ObjectType,MFVersion,StatusFlag
)
VALUES
(
s.Class,s.ObjID,s.objectType,s.MFVersion,5
);'         ;

            EXEC sys.sp_executesql @Stmt = @sql,
                @Param = @Params,
                @ClassId = @ClassId,
                @ObjectId = @ObjectId,
                @ObjIDsForUpdate = @ObjIDsForUpdate;

				SET @rowcount = @@RowCount


            SET @DebugText = N' count ' + CAST(ISNULL(@rowcount,0) AS NVARCHAR(10));
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                SELECT 'Postflag',
                    *
                FROM #AllObjects AS ao;
            END;

                     SET @ProcedureStep = N' update audit history ';

            DECLARE @TotalObjver INT;
            DECLARE @FilteredObjver INT;
            DECLARE @ToUpdateObjver INT;
            DECLARE @NotInAuditHistory INT;

            SELECT @TotalObjver = COUNT(ISNULL(id,0))
            FROM dbo.MFAuditHistory AS mah
            WHERE mah.Class = @ClassId;

            SELECT @FilteredObjver = COUNT(ISNULL(id,0))
            FROM #AllObjects AS ao;

            SELECT @ToUpdateObjver = COUNT(ISNULL(id,0))
            FROM #AllObjects AS ao
            WHERE ao.StatusFlag <> 0;

            SELECT @NotInAuditHistory = COUNT(ISNULL(ao.id,0))
            FROM #AllObjects                 AS ao
                LEFT JOIN dbo.MFAuditHistory AS mah
                    ON mah.Class = ao.Class
                       AND mah.ObjID = ao.ObjID
            WHERE mah.ObjID IS NULL;

            SET @LogTypeDetail = N'Status';
            SET @LogStatusDetail = N'In progress';
            SET @LogTextDetail
                = N'MFAuditHistory: Total: ' + CAST(COALESCE(@TotalObjver, 0) AS NVARCHAR(10)) + N' From MF: '
                  + CAST(COALESCE(@FilteredObjver, 0) AS NVARCHAR(10)) + N' Flag not 0: '
                  + CAST(COALESCE(@ToUpdateObjver, 0) AS NVARCHAR(10)) + N' New in audit history: '
                  + CAST(COALESCE(@NotInAuditHistory, 0) AS NVARCHAR(10));
            SET @LogColumnName = N'Objvers to update';
            SET @LogColumnValue = CAST(COALESCE(@ToUpdateObjver, 0) AS NVARCHAR(10));

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

            --Delete redundant objects in class table in SQL: this can only be applied when a full Audit is performed
            --7 = Marked deleted in SQL not deleted in MF : [t].[Deleted] = 1
 /*
            SET @ProcedureStep = N'Delete redudants in SQL';

            IF @DeletedInSQL = 1
            BEGIN
                SELECT @Query
                    = N'DELETE FROM ' + QUOTENAME(@MFTableName)
                      + N'
WHERE id IN (
SELECT t.id
FROM [#AllObjects] AS [ao]
right JOIN '                    + QUOTENAME(@MFTableName) + N' t
ON ao.objid = t.objid 
WHERE Flagstatus = 5) ;';

                --            SELECT @Query;
                EXEC sys.sp_executesql @Query;

                SET @DebugText = N'';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END;

            -- Delete from SQL
*/
            -------------------------------------------------------------
            -- Process objversions to audit history
            -------------------------------------------------------------
            IF @ToUpdateObjver > 0
               OR @NotInAuditHistory > 0
            BEGIN

                SET @ProcedureStep = N'Update records in Audit History';
 
 /*               SET @DebugText = N' Count %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                SELECT @rowcount = COUNT(*)
                FROM #AllObjects AS ao;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
                END;

                SELECT @ProcedureStep = N'Merge into MFAuditHistory';
*/

BEGIN TRAN

UPDATE targ
SET targ.RecID = Src.ID,
                        targ.SessionID = @SessionID,
                        targ.TranDate = @TranDate,
                        targ.MFVersion = Src.MFVersion,
                        targ.StatusFlag = Src.Statusflag,
                        targ.StatusName =  CASE
                            WHEN Src.StatusFlag = 0 THEN
                                'Identical'
                            WHEN src.StatusFlag = 1 THEN
                                'MF is later'
                            WHEN src.StatusFlag = 2 THEN
                                'SQL is later'
                            WHEN src.StatusFlag = 3 THEN
                                'Checked out'
                            WHEN src.StatusFlag = 4 THEN
                                'Deleted'
                            WHEN src.StatusFlag = 5 THEN
                                'Not in Class'
                            WHEN src.StatusFlag = 6 THEN
                                'Not yet processed in SQL'
WHEN src.StatusFlag = 9 THEN
                                'Document Collection'
                        END,
                        targ.UpdateFlag =  CASE
                            WHEN ISNULL(src.StatusFlag, 0) <> 0 THEN
                                1
                            ELSE
                                0
                        END   
FROM dbo.MFAuditHistory AS targ
INNER JOIN #AllObjects AS src
                ON targ.[ObjID] = Src.[ObjID]
                   AND targ.Class = Src.Class AND targ.ObjectType = src.ObjectType
WHERE 1=1;

                   SET @rowcount = @@RowCount
COMMIT TRAN

   SET @DebugText = N' Count ' + CAST(@rowcount AS NVARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                End

        SET @ProcedureStep = N'Insert into Audit History';
 

INSERT INTO dbo.MFAuditHistory
(
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
SELECT 
 @SessionID, @TranDate, Src.ObjectType, Src.Class, Src.[ObjID], Src.MFVersion,
                        Src.Statusflag, 
                        CASE
                            WHEN Src.StatusFlag = 0 THEN
                                'Identical'
                            WHEN src.StatusFlag = 1 THEN
                                'MF is later'
                            WHEN src.StatusFlag = 2 THEN
                                'SQL is later'
                            WHEN src.StatusFlag = 3 THEN
                                'Checked out'
                            WHEN src.StatusFlag = 4 THEN
                                'Deleted'
                            WHEN src.StatusFlag = 5 THEN
                                'Not in Class'
                            WHEN src.StatusFlag = 6 THEN
                                'Not yet processed in SQL'
                            WHEN src.StatusFlag = 9 THEN
                                'Document Collection'
                        END,
                         1
FROM  #AllObjects AS src 
LEFT JOIN dbo.MFAuditHistory AS targ
                ON targ.[ObjID] = Src.[ObjID]
                   and targ.Class = Src.Class AND targ.ObjectType = src.ObjectType
WHERE targ.id IS null
                   SET @rowcount = @@RowCount

     SET @DebugText = N' Count ' + CAST(@rowcount AS NVARCHAR(10));
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

                    SELECT *
                    FROM dbo.MFAuditHistory                                   AS mah
                        INNER JOIN dbo.fnMFSplitString(@ObjIDsForUpdate, ',') AS fms
                            ON fms.Item = mah.ObjID
                               AND mah.Class = @ClassId;
                END;
            END;

            --update items into MFaudithisitory

            -------------------------------------------------------------
            -- Remove from MFauditHistory where objids is not returned from MF
            -------------------------------------------------------------
            SET @ProcedureStep = N'Delete from audit history not in MF';

            IF @ObjIDs IS NOT NULL
            BEGIN
                ;
                WITH cte
                AS (SELECT fps.ListItem AS Objid
                    FROM dbo.fnMFParseDelimitedString(@ObjIDs, ',') fps
                        LEFT JOIN #AllObjects                       AS ao
                            ON fps.ListItem = ao.ObjID
                    WHERE ao.StatusFlag = 5)
                --	SELECT * FROM cte
                DELETE FROM dbo.MFAuditHistory
                WHERE Class = @ClassId
                      AND ObjID IN
                          (
                              SELECT cte.Objid FROM cte
                          );
        SET @rowcount = @@RowCount

            END;

            SET @DebugText = N' Count ' + CAST(@rowcount AS NVARCHAR(10));
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

                     -------------------------------------------------------------
            -- Set UpdateRequired
            -------------------------------------------------------------
            DECLARE @MFRecordCount INT,
                @MFNotInSQL        INT,
                @LaterInMF         INT,
                @Process_id_1      INT,
                @NewSQL            INT;

 IF (SELECT OBJECT_ID('tempdb..##spMFclassTableStats')) IS null
 BEGIN

 EXEC [dbo].[spMFClassTableStats] @IncludeOutput = 1, @ClassTableName = @MFTableName    
                                            ,@Debug = 0            
END
            SELECT @MFNotInSQL = MFNotInSQL-Collections, @OutofSync = SyncError, @ProcessErrors = MFError + SQLError, @Process_id_1 = Process_id_Not_0  FROM ##spmfclasstablestats
            WHERE TableName = @MFTableName
            SELECT @LaterInMF = COUNT(ISNULL(id,0))
            FROM dbo.MFAuditHistory AS mah
            WHERE mah.SessionID = @SessionIDOut
                  AND mah.StatusFlag = 1;

            SELECT @NewSQL = COUNT(ISNULL(id,0))
            FROM dbo.MFAuditHistory AS mah
            WHERE mah.SessionID = @SessionIDOut
                  AND mah.StatusFlag = 5;

            SELECT @UpdateRequired = CASE
                                         WHEN @LaterInMF > 0
                                              OR @MFNotInSQL > 0
                                              OR @Process_id_1 > 0
                                              OR @NewSQL > 0 THEN
                                             1
                                         ELSE
                                             0
                                     END;

            SET @Msg = N'Session: ' + CAST(@SessionIDOut AS VARCHAR(5));

            IF @UpdateRequired > 0
                SET @Msg = @Msg + N' | Update Required: ' + CAST(@UpdateRequired AS VARCHAR(5));

            IF @LaterInMF > 0
                SET @Msg = @Msg + N' | MF Updates : ' + CAST(@LaterInMF AS VARCHAR(5));

            IF @Process_id_1 > 0
                SET @Msg = @Msg + N' | SQL Updates : ' + CAST(@Process_id_1 AS VARCHAR(5));

            IF @Process_id_1 > 0
                SET @Msg = @Msg + N' | SQL New : ' + CAST(@NewSQL AS VARCHAR(5));

            EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                @ProcessType = @ProcessType,
                @LogType = N'Debug',
                @LogText = @LogText,
                @LogStatus = @LogStatus,
                @debug = @Debug;

            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = N'Debug';
            SET @LogTextDetail = @Msg;
            SET @LogStatusDetail = N'Status';
            SET @LogColumnName = N'Objects';
            SET @LogColumnValue = N'';

            EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
                @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
                @debug = 0;

            --        COMMIT TRAN [main];
            DROP TABLE #AllObjects;
        END; --nothing to update in AuditHistory

    END;
    ELSE
    BEGIN
        RAISERROR('Table does not exist', 10, 1);
    END;

    -------------------------------------------------------------
    --END PROCESS
    -------------------------------------------------------------
    END_RUN:
    SET @ProcedureStep = N'End';
    SET @LogStatus = N'Completed';
    SET @LogText = N'Completed ' + @ProcedureName;

    EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
        @ProcessType = @ProcessType,
        @LogType = N'Debug',
        @LogText = @LogText,
        @LogStatus = @LogStatus,
        @debug = @Debug;

    SET @StartTime = GETUTCDATE();
    SET @LogTypeDetail = N'Debug';
    SET @LogTextDetail = @LogText;
    SET @LogStatusDetail = N'Status';
    SET @LogColumnName = N'';
    SET @LogColumnValue = N'';

    EXEC dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
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
        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT, --v38
        @debug = 0;

    -------------------------------------------------------------
    -- Log End of Process
    ------------------------------------------------------------- 
    SELECT @SessionIDOut = @SessionID;

    IF @Debug > 0
        SELECT @SessionIDOut AS SessionID;

    RETURN 1;

    SET NOCOUNT OFF;
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
        @debug = @Debug;

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
        @debug = 0;

    RETURN -1;
END CATCH;
GO