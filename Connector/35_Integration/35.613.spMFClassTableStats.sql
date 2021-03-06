PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFClassTableStats]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFClassTableStats', -- nvarchar(100)
    @Object_Release = '4.8.26.68',        -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFClassTableStats' --name of procedure
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
CREATE PROCEDURE dbo.spMFClassTableStats
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFClassTableStats
(
    @ClassTableName NVARCHAR(128) = NULL,
    @Flag INT = NULL,
    @WithReset INT = 0,
    @WithAudit INT = 0,
    @IncludeOutput INT = 0,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

===================
spMFClassTableStats
===================

Return
  - 1 = Success
  - -1 = Error

Parameters
  @ClassTableName nvarchar(128) (optional)
    - Default = NULL (all tables will be listed)
    - ClassTableName to show table stats for
  @Flag int (optional)
    - Default = NULL
  @WithReset int (optional)
    - Default = 0
    - 1 = deleted object will be removed, sync error reset to 0, error 3 records deleted.
  @WithAudit int
    - Default = 0
    - 1 = will include running spmftableaudit and updating info from MF
  @IncludeOutput int (optional)
    set to 1 to output result to a table ##spMFClassTableStats
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

To show an extract of all the Class Tables created in the Connector database, the IncludedInApp status of the tables in MFClass the number of records in the class table and the date and time of the last updated record in the table. The date of the most recent MF_Last_Modified is also shown.

Additional Info
===============

The procedure also show a summary of the key status records from the process_id column of the tables. The number of records in the following categories are shown:

=====================  =====================================================================================================
Column                 Description
---------------------  -----------------------------------------------------------------------------------------------------
ClassID                MFID of the class
TableName              Name of Class table
IncludeInApp           IncludeInApp Flag
SQLRecordCount         Totals records in SQL (Note that this is not necessarily the same as the total per M-Files)
MFRecordCount          Total records in M-Files including deleted objects. 
                       This result is derived from the last time that spMFTableAudit procedure was run to produce a list
                       of the objectversions of all the objects for a specific class. 
MFNotInSQL             Total record in M-Files not yet updated in SQL. This excludes deleted objects in M-Files which are recorded in MFAuditTable with statusflag = 4
Templates              Total records with IsTemplate Flag.  These records are excluded from the the class table
Deleted                Total for Deleted flag set to 1 plus deleted in M-Files and not in class table
CheckedOut             Total number of records from MFAuditHistory that is checked out for the class 
RequiredWorkflowError  Total number of records with empty workflow where workflow is required in class definition
SyncError              Total Synchronization errors (process_id = 2)
Process_ID_not_0       Total of records with process_id <> 0 this includes the errors and show records that will be
                       excluded from an @updatemethod = 1 routine
MFError                Total of records with process_id = 3 as MFError
SQLError               Total of records with process_id =4 as SQL Error
LastModifed            Most recent date that SQL updated a record in the table
MFLastModified         Most recent that an update was made in M-Files on the record
SessionID              ID  of the latest spMFTableAudit procedure execution.
=====================  =====================================================================================================

Warnings
========

The MFRecordCount results of spMFClassTableStats is only accurate based on the last execution of spMFTableAudit for a particular class table.

Examples
========

.. code:: sql

   EXEC [dbo].[spMFClassTableStats]

----

To show a specific table.

.. code:: sql

   EXEC [dbo].[spMFClassTableStats] @ClassTableName = N'YourTablename'

----

To insert the report into a temporary table that can be used in messaging.

.. code:: sql

   EXEC [dbo].[spMFClassTableStats]
        @ClassTableName = N'YourTablename'
       ,@IncludeOutput = 1

----

To include updating object information from M-files.

.. code:: sql

   EXEC [dbo].[spMFClassTableStats]
        @ClassTableName = N'YourTablename'
       ,@IncludeOutput = 1
       ,@WithAudit = 1

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-03-11  LC         Add column to report on number of templates
2021-03-11  LC         fix calculation of deleted objects
2021-03-02  LC         Add column to report on records without required workflow
2021-03-02  LC         Add column to report on Checked out objects
2020-12-10  LC         add new parameter to allow for a quick run without table audit
2020-09-04  LC         rebase MFObjectTotal to include checkedout
2020-08-22  LC         Update code for new deleted column
2020-04-16  LC         Add with nolock option
2020-03-06  LC         Remove statusflag 6 from notinSQL
2020-03-06  LC         Change deleted to include deleted from audit table
2020-03-06  LC         Change Column to show process_id not 0
2019-09-26  LC         Update documentation
2019-08-30  JC         Added documentation
2017-12-27  LC         run tableaudit for each table to update status from MF
2017-11-23  LC         MF_lastModified set to deal with localization
2017-07-22  LC         add parameter to allow the temp table to persist
2017-06-29  LC         change mflastmodified date to localtime
2017-06-16  LC         remove flag = 1 from listing
2016-09-09  LC         add input parameter to only show table requested
2016-08-22  LC         mflastmodified date show in local time
2016-02-30  DEV2       Created procedure
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

SET ANSI_WARNINGS OFF;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFclassTableStats';
DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = N'';
DECLARE @Msg AS NVARCHAR(256) = N'';
DECLARE @SQL   NVARCHAR(MAX),
    @params    NVARCHAR(100),
    @TableName VARCHAR(100),
    @ID        INT;
DECLARE @lastModifiedColumn NVARCHAR(100);
DECLARE @MFCount INT = 0;
DECLARE @NotINSQL INT = 0;
DECLARE @IncludeInApp INT;
DECLARE @DeletedColumn NVARCHAR(100);
DECLARE @WorkflowColumn NVARCHAR(100);
DECLARE @RequiredWorkflow INT;
DECLARE @ClassPropertyColumn NVARCHAR(100);
DECLARE @NotInMF INT;

DECLARE @ClassIDs AS TABLE
(
    ClassID INT
);

IF @ClassTableName IS NULL
BEGIN
    INSERT INTO @ClassIDs
    (
        ClassID
    )
    SELECT MFID
    FROM dbo.MFClass;
END;
ELSE
BEGIN
    INSERT INTO @ClassIDs
    (
        ClassID
    )
    SELECT MFID
    FROM dbo.MFClass
    WHERE TableName = @ClassTableName;
END;

IF @Debug > 0
    SELECT *
    FROM @ClassIDs;

IF EXISTS
(
    SELECT *
    FROM tempdb.INFORMATION_SCHEMA.TABLES AS t
    WHERE t.TABLE_NAME = '##spMFClassTableStats'
)
    DROP TABLE ##spMFClassTableStats;

CREATE TABLE ##spMFClassTableStats
(
    ClassID INT PRIMARY KEY NOT NULL,
    TableName VARCHAR(100),
    IncludeInApp SMALLINT,
    SQLRecordCount INT,
    MFRecordCount INT,
    MFNotInSQL INT,
    SQLNotInMF INT
        DEFAULT (0),
    Templates INT,
    Deleted INT,
    CheckedOut INT,
    RequiredWorkflowError INT,
    SyncError INT,
    Process_ID_not_0 INT,
    MFError INT,
    SQLError INT,
    LastModified DATETIME,
    MFLastModified DATETIME,
    SessionID INT
);

SELECT @DeletedColumn = mp.ColumnName
FROM dbo.MFProperty AS mp
WHERE mp.MFID = 27; --'Deleted'

SELECT @lastModifiedColumn = mp.ColumnName
FROM dbo.MFProperty AS mp
WHERE mp.MFID = 21; --'Last Modified'

SELECT @WorkflowColumn = mp.ColumnName
FROM dbo.MFProperty AS mp
WHERE mp.MFID = 38; --'Workflow'

SELECT @ClassPropertyColumn = mp.ColumnName
FROM dbo.MFProperty AS mp
WHERE mp.MFID = 100; --'Class'

INSERT INTO ##spMFClassTableStats
(
    ClassID,
    TableName,
    IncludeInApp
)
SELECT mc.MFID,
    mc.TableName,
    mc.IncludeInApp
FROM @ClassIDs            AS cid
    LEFT JOIN dbo.MFClass AS mc
        ON mc.MFID = cid.ClassID;

IF @Debug > 0
    SELECT *
    FROM ##spMFClassTableStats;

SELECT @ID = MIN(t.ClassID)
FROM ##spMFClassTableStats AS t;

WHILE @ID IS NOT NULL
BEGIN
    SELECT @TableName = t.TableName,
        @IncludeInApp = ISNULL(t.IncludeInApp, 0)
    FROM ##spMFClassTableStats AS t
    WHERE t.ClassID = @ID;

    SELECT @RequiredWorkflow = mc.IsWorkflowEnforced
    FROM ##spMFClassTableStats AS smcts
        INNER JOIN dbo.MFClass mc
            ON smcts.ClassID = mc.MFID
    WHERE mc.MFID = @ID;

    IF @Debug > 0
        SELECT @TableName     AS Classtable,
            @RequiredWorkflow AS requiredworkflow,
            @ClasspropertyColumn AS ClassProperty
            ;

    -------------------------------------------------------------
    -- audit table validation
    -------------------------------------------------------------
    SET @ProcedureStep = N'Remove redundant objects where object type does not exist';

    WITH cte
    AS (SELECT mah.ID
        FROM dbo.MFAuditHistory        mah
            LEFT JOIN dbo.MFObjectType AS mot
                ON mah.ObjectType = mot.MFID
        WHERE mot.Name IS NULL)
    DELETE FROM dbo.MFAuditHistory
    WHERE ID IN
          (
              SELECT cte.ID FROM cte
          );

    SET @ProcedureStep = N'Remove redundant objects where class does not exist';

    WITH cte
    AS (SELECT mah.ID
        FROM dbo.MFAuditHistory   mah
            LEFT JOIN dbo.MFClass mc
                ON mah.class = mc.MFID
        WHERE mc.Name IS NULL)
    DELETE FROM dbo.MFAuditHistory
    WHERE ID IN
          (
              SELECT cte.ID FROM cte
          );

    SET @ProcedureStep = N'Prepare stats';

    IF @IncludeInApp > 0
    BEGIN
        SET @params = N'@Debug smallint, @RequiredWorkflow int';
        SET @SQL
            = N'
Declare @SQLcount INT, @LastModified datetime, @MFLastModified datetime, @Deleted int, @Templates int, @SyncError int, @ProcessID_not_0 int, @MFError INt, @SQLError Int, @RequiredWorkflowCount int, @CheckedOutCount int;



IF EXISTS(SELECT [t].[TABLE_NAME] FROM [INFORMATION_SCHEMA].[TABLES] AS [t] where Table_name = ''' + @TableName
              + N''')
Begin

SELECT @SQLcount = COUNT(*), @LastModified = max(LastModified), @MFLastModified = max('
              + QUOTENAME(@lastModifiedColumn) + N') FROM ' + QUOTENAME(@TableName)
              + N'
--Select @MFLastModified = dateadd(hour,DATEDIFF(hour,GETUTCDATE(),GETDATE()),@MFLastModified)
Select @Deleted = count(*) FROM ' + QUOTENAME(@TableName) + N' where ' + QUOTENAME(@DeletedColumn)
              + N' is not null;
Select @SyncError = count(*) FROM ' + QUOTENAME(@TableName)
              + N' where Process_id = 2;
Select @ProcessID_not_0 = count(*) FROM ' + QUOTENAME(@TableName)
              + N' where Process_id <> 0;
Select @MFError = count(*) FROM ' + QUOTENAME(@TableName)
              + N' where Process_id = 3;
Select @SQLError = count(*) FROM ' + QUOTENAME(@TableName)
              + N' where Process_id = 4;
Select @RequiredWorkflowCount = count(*) FROM ' + QUOTENAME(@TableName) + N' t where ' + @WorkflowColumn
              + N' is null and  @RequiredWorkflow = 1;

select @Deleted = count(*) from MFauditHistory ah
inner join MFClass mc
on ah.class = mc.mfid
where mc.tablename = ''' + @TableName
              + N'''
and ah.statusflag in (4,7);

select @Templates = count(*) from MFauditHistory ah
inner join MFClass mc
on ah.class = mc.mfid
where mc.tablename = ''' + @TableName
              + N'''
and ah.statusflag = 6;

UPDATE t
SET t.[SQLRecordCount] =  @SQLcount, LastModified = @LastModified, MFLastModified = @MFLastModified,
Deleted = @Deleted, Templates = @Templates, RequiredWorkflowError = @RequiredWorkflowCount,
SyncError = @SyncError, Process_ID_not_0 = @ProcessID_not_0, MFError = @MFerror, SQLError = @SQLError

FROM [##spMFClassTableStats] AS [t]
WHERE t.[TableName] = ''' + @TableName + N'''

END
Else 
If @Debug > 0
print ''' + @TableName + N' has not been created'';
 '      ;

        IF @Debug > 10
            PRINT @SQL;

        EXEC sys.sp_executesql @Stmt = @SQL,
            @Param = @params,
            @Debug = @Debug,
            @RequiredWorkflow = @RequiredWorkflow;

        SET @RequiredWorkflow = 0;

        -------------------------------------------------------------
        -- update checked out
        -------------------------------------------------------------
        DECLARE @CheckedOutCount INT;

        SELECT @CheckedOutCount = COUNT(*)
        FROM dbo.MFAuditHistory              AS mah
            INNER JOIN ##spMFClassTableStats AS smcts
                ON mah.Class = smcts.ClassID
        WHERE mah.Class = @ID
              AND mah.StatusFlag = 3; --checked out

        UPDATE smcts
        SET smcts.CheckedOut = @CheckedOutCount
        FROM ##spMFClassTableStats AS smcts
        WHERE smcts.ClassID = @ID;

        -------------------------------------------------------------
        -- Include table audit
        -------------------------------------------------------------
        DECLARE @SQLCount INT,
            @ToObjid      INT;

        SELECT @SQLCount = smcts.SQLRecordCount
        FROM ##spMFClassTableStats AS smcts
        WHERE smcts.ClassID = @ID;

        SELECT @ToObjid = @SQLCount + 5000;

        IF @WithAudit = 1
        BEGIN
            DECLARE @SessionIDOut INT,
                @NewObjectXml     NVARCHAR(MAX),
                @DeletedInSQL     INT,
                @UpdateRequired   BIT,
                @OutofSync        INT,
                @ProcessErrors    INT,
                @ProcessBatch_ID  INT;

            EXEC dbo.spMFTableAudit @MFTableName = @TableName,
                @MFModifiedDate = '2000-01-01',
                --  @ObjIDs = ?,
                @SessionIDOut = @SessionIDOut OUTPUT,
                @NewObjectXml = @NewObjectXml OUTPUT,
                @DeletedInSQL = @DeletedInSQL OUTPUT,
                @UpdateRequired = @UpdateRequired OUTPUT,
                @OutofSync = @OutofSync OUTPUT,
                @ProcessErrors = @ProcessErrors OUTPUT,
                @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                @Debug = 0;
 
 END; -- include table audit

 -------------------------------------------------------------
 -- audit table dependent updates
 -------------------------------------------------------------

        SELECT @MFCount = COUNT(*)
        FROM dbo.MFAuditHistory AS mah WITH (NOLOCK)
        WHERE mah.Class = @ID;

        --           AND [mah].[StatusFlag] NOT IN ( 4 ); --not in MF
  
        SET @params = N'@NotinMF int output';
        SET @SQL
            = N'
        Select @NotinMF = count(*) from ' + QUOTENAME(@TableName)
              + N' t
left join MFAuditHistory ah
on t.objid = ah.objid and t.' + @ClassPropertyColumn + N' = ah.class
where ah.objid is null;';

        EXEC sys.sp_executesql @SQL, @params, @NotInMF OUTPUT;

        UPDATE smcts
        SET smcts.SQLNotInMF = @NotInMF
        FROM ##spMFClassTableStats AS smcts
        WHERE smcts.ClassID = @ID;



  SELECT @NotINSQL = COUNT(*)
        FROM dbo.MFAuditHistory AS mah WITH (NOLOCK)
        WHERE mah.Class = @ID
              AND mah.StatusFlag IN ( 1, 5 ); -- templates and other records not in SQL

        UPDATE smcts
        SET smcts.MFRecordCount = @MFCount,
            smcts.MFNotInSQL = @NotINSQL
        FROM ##spMFClassTableStats AS smcts
        WHERE smcts.ClassID = @ID;

        IF EXISTS
        (
            SELECT t.TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES AS t
            WHERE t.TABLE_NAME = @TableName
        )
           AND @WithReset = 1
        BEGIN
            SET @SQL
                = N'delete from ' + QUOTENAME(@TableName) + N' where ' + QUOTENAME(@DeletedColumn)
                  + N' is not null
		update ##spMFClassTableStats set Deleted = 0 where TableName = ''' + @TableName + N'''
		'   ;

            EXEC (@SQL);

            SET @SQL
                = N'delete from ' + QUOTENAME(@TableName)
                  + N' where process_ID = 3
		update ##spMFClassTableStats set MFError = 0 where TableName = ''' + @TableName + N'''
		'   ;

            EXEC (@SQL);

            SET @SQL
                = N'Update t set process_ID=0 from ' + QUOTENAME(@TableName)
                  + N' t where process_ID = 2
		update ##spMFClassTableStats set SyncError = 0 where TableName = ''' + @TableName + N'''
		'   ;

            EXEC (@SQL);
        END;
    END; --included in app

    SELECT @ID = MIN(t.ClassID)
    FROM ##spMFClassTableStats AS t
    WHERE t.ClassID > @ID;

    IF @Debug > 0
        SELECT @ID AS nextID;
END; -- END while

IF @IncludeOutput = 0
BEGIN
    SELECT *
    FROM ##spMFClassTableStats
    WHERE ISNULL(SQLRecordCount, -1) <> -1;

    DROP TABLE ##spMFClassTableStats;
END;

RETURN 1;
GO