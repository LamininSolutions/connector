PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFClassTableStats]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFClassTableStats' -- nvarchar(100)
                                    ,@Object_Release = '3.1.4.41'         -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Listing of Class Table stats
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			mflastmodified date show in local time
	2016-9-9		lc			add input parameter to only show table requested
	2017-6-16		LC			remove flag = 1 from listing
	2017-6-29		lc			change mflastmodified date to localtime
	2017-7-22		lc			add parameter to allow the temp table to persist
	2017-11-23		lc			MF_lastModified set to deal with localization
	2017-12-27		lc			run tableaudit for each table to update status from MF
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFClassTableStats]  null , 0,1,0

  exec spmfclasstablestats 'MFCustomer'
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFClassTableStats' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFClassTableStats]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFClassTableStats]
(
    @ClassTableName NVARCHAR(128) = NULL
   ,@Flag INT = NULL
   ,@WithReset INT = 0
   ,@IncludeOutput INT = 0
   ,@Debug SMALLINT = 0
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

==============  ===============================================================
Column          Description
--------------  ---------------------------------------------------------------
ClassID         MFID of the class
TableName       Name of Class table
IncludeInApp    IncludeInApp Flag
SQLRecordCount  Totals records in SQL (Note that this is not necessarily the same as the total per M-Files)
MFRecordCount   Total records in M-Files. This result is derived from the last time that spMFTableAudit procedure was run to produce a list of the objectversions of all the objects for a specific class
MFNotInSQL      Total record in M-Files not yet updated in SQL
Deleted         Total for Deleted flag set to 1
SyncError       Total Synchronization errors (process_id = 2)
Process_ID_1    Total of records with process_id = 1
MFError         Total of records with process_id = 3 as MFError
SQLError        Total of records with process_id =4 as SQL Error
LastModifed     Most recent date that SQL updated a record in the table
MFLastModified  Most recent that an update was made in M-Files on the record
SessionID       ID  of the latest spMFTableAudit procedure execution. 
==============  ===============================================================

Warnings
========

The MFRecordCount results of spMFClassTableStats is only accurate based on the last execution of spMFAuditTable for a particular class table.

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

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON;

DECLARE @ClassIDs AS TABLE
(
    [ClassID] INT
);

IF @ClassTableName IS NULL
BEGIN
    INSERT INTO @ClassIDs
    (
        [ClassID]
    )
    SELECT [MFID]
    FROM [dbo].[MFClass];
END;
ELSE
BEGIN
    INSERT INTO @ClassIDs
    (
        [ClassID]
    )
    SELECT [MFID]
    FROM [dbo].[MFClass]
    WHERE [TableName] = @ClassTableName;
END;

if @Debug > 0
SELECT * FROM @ClassIDs;
 

IF EXISTS
(
    SELECT *
    FROM [tempdb].[INFORMATION_SCHEMA].[TABLES] AS [t]
    WHERE [t].[TABLE_NAME] = '##spMFClassTableStats'
)
    DROP TABLE [##spMFClassTableStats];

CREATE TABLE [##spMFClassTableStats]
(
    [ClassID] INT PRIMARY KEY NOT NULL
   ,[TableName] VARCHAR(100)
   ,[IncludeInApp] SMALLINT
   ,[SQLRecordCount] INT
   ,[MFRecordCount] INT
   ,[MFNotInSQL] INT
   ,[Deleted] INT
   ,[SyncError] INT
   ,[Process_ID_1] INT
   ,[MFError] INT
   ,[SQLError] INT
   ,[LastModified] DATETIME
   ,[MFLastModified] DATETIME
   ,[SessionID] INT
);

DECLARE @SQL       NVARCHAR(MAX)
       ,@params    NVARCHAR(100)
       ,@TableName VARCHAR(100)
       ,@ID        INT;
DECLARE @lastModifiedColumn NVARCHAR(100);
DECLARE @MFCount INT = 0;
DECLARE @NotINSQL INT = 0;
DECLARE @IncludeInApp INT;

SELECT @lastModifiedColumn = [mp].[ColumnName]
FROM [dbo].[MFProperty] AS [mp]
WHERE [mp].[MFID] = 21; --'Last Modified'

INSERT INTO [##spMFClassTableStats]
(
    [ClassID]
   ,[TableName]
   ,[IncludeInApp]
   ,[SQLRecordCount]
   ,[MFRecordCount]
   ,[MFNotInSQL]
   ,[Deleted]
   ,[SyncError]
   ,[Process_ID_1]
   ,[MFError]
   ,[SQLError]
   ,[LastModified]
   ,[MFLastModified]
)
SELECT [mc].[MFID]
      ,[mc].[TableName]
      ,[mc].[IncludeInApp]
      ,NULL
      ,NULL
      ,NULL
      ,NULL
      ,NULL
      ,NULL
      ,NULL
      ,NULL
      ,NULL
      ,NULL
FROM @ClassIDs                AS [cid]
    LEFT JOIN [dbo].[MFClass] AS [mc]
        ON [mc].[MFID] = [cid].[ClassID];

IF @Debug > 0
    SELECT *
    FROM [##spMFClassTableStats];

SELECT @ID = MIN([t].[ClassID])
FROM [##spMFClassTableStats] AS [t];



WHILE @ID IS NOT NULL
BEGIN
    SELECT @TableName    = [t].[TableName]
          ,@IncludeInApp = ISNULL([t].[IncludeInApp], 0)
    FROM [##spMFClassTableStats] AS [t]
    WHERE [t].[ClassID] = @ID;

    IF @Debug > 0
        SELECT @TableName;

    IF @IncludeInApp > 0
	Begin
        SET @params = '@Debug smallint';

    SET @SQL
        = N'
Declare @SQLcount INT, @LastModified datetime, @MFLastModified datetime, @Deleted int, @SyncError int, @ProcessID_1 int, @MFError INt, @SQLError Int


IF EXISTS(SELECT [t].[TABLE_NAME] FROM [INFORMATION_SCHEMA].[TABLES] AS [t] where Table_name = ''' + @TableName
          + ''')
Begin

SELECT @SQLcount = COUNT(*), @LastModified = max(LastModified), @MFLastModified = max('
          + QUOTENAME(@lastModifiedColumn) + ') FROM ' + QUOTENAME(@TableName)
          + '
--Select @MFLastModified = dateadd(hour,DATEDIFF(hour,GETUTCDATE(),GETDATE()),@MFLastModified)
Select @Deleted = count(*) FROM ' + QUOTENAME(@TableName) + ' where deleted <> 0;
Select @SyncError = count(*) FROM ' + QUOTENAME(@TableName)
          + ' where Process_id = 2;
Select @ProcessID_1 = count(*) FROM ' + QUOTENAME(@TableName)
          + ' where Process_id = 1;
Select @MFError = count(*) FROM ' + QUOTENAME(@TableName) + ' where Process_id = 3;
Select @SQLError = count(*) FROM ' + QUOTENAME(@TableName)
          + ' where Process_id = 4;
UPDATE t
SET t.[SQLRecordCount] =  @SQLcount, LastModified = @LastModified, MFLastModified = @MFLastModified,
Deleted = @Deleted, SyncError = @SyncError, Process_ID_1 = @ProcessID_1, MFError = @MFerror, SQLError = @SQLError

FROM [##spMFClassTableStats] AS [t]
WHERE t.[TableName] = ''' + @TableName + '''

END
Else 
If @Debug > 0
print ''' + @TableName + ' has not been created'';
 '  ;

    IF @Debug > 10
        PRINT @SQL;

    EXEC [sys].[sp_executesql] @Stmt = @SQL, @Param = @params, @Debug = @Debug;

    DECLARE @SQLCount INT
           ,@ToObjid  INT;

    SELECT @SQLCount = [smcts].[SQLRecordCount]
    FROM [##spMFClassTableStats] AS [smcts]
    WHERE [smcts].[ClassID] = @ID;

    SELECT @ToObjid = @SQLCount + 5000;

    

        --   declare @SessionIDOut    int
        --         , @NewObjectXml    nvarchar(max)
        --         , @DeletedInSQL    int
        --         , @UpdateRequired  bit
        --         , @OutofSync       int
        --         , @ProcessErrors   int
        --         , @ProcessBatch_ID INT
        --         ,@MFModifiedDate DATETIME
        --,@MFClassTableUpdate DATETIME
        EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = @TableName -- nvarchar(100)
                                            ,@FromObjid = 1            -- int
                                            ,@ToObjid = @ToObjid       -- int
                                            ,@WithStats = 0            -- bit
                                            ,@Debug = 0;

                                                                       -- int

        --exec [dbo].[spMFTableAudit] @MFTableName = @TableName
        --                         , @MFModifiedDate = @MFModifiedDate
        --                          --@ObjIDs = ?,
        --                          , @SessionIDOut = @SessionIDOut output
        --                          , @NewObjectXml = @NewObjectXml output
        --                          , @DeletedInSQL = @DeletedInSQL output
        --                          , @UpdateRequired = @UpdateRequired output
        --                          , @OutofSync = @OutofSync output
        --                          , @ProcessErrors = @ProcessErrors output
        --                          , @ProcessBatch_ID = @ProcessBatch_ID output
        --                          , @Debug = @Debug;

        --if @Debug > 0
        --    select @SessionIDOut as [sessionID];
        SELECT @MFCount = COUNT(*)
        FROM [dbo].[MFAuditHistory] AS [mah]
        WHERE [mah].[Class] = @ID
              AND [mah].[StatusFlag] NOT IN ( 3, 4 ); --not in MF

        SELECT @NotINSQL = COUNT(*)
        FROM [dbo].[MFAuditHistory] AS [mah]
        WHERE [mah].[Class] = @ID
              AND [mah].[StatusFlag] IN ( 5, 6 ); -- templates and other records not in SQL

        UPDATE [smcts]
        SET [smcts].[MFRecordCount] = @MFCount
           ,[smcts].[MFNotInSQL] = @NotINSQL
        FROM [##spMFClassTableStats] AS [smcts]
        WHERE [smcts].[ClassID] = @ID;

        IF EXISTS
        (
            SELECT [t].[TABLE_NAME]
            FROM [INFORMATION_SCHEMA].[TABLES] AS [t]
            WHERE [t].[TABLE_NAME] = @TableName
        )
           AND @WithReset = 1
        BEGIN
            SET @SQL
                = N'delete from ' + QUOTENAME(@TableName)
                  + ' where deleted = 1
		update ##spMFClassTableStats set Deleted = 0 where TableName = ''' + @TableName + '''
		'   ;

            EXEC (@SQL);

            SET @SQL
                = N'delete from ' + QUOTENAME(@TableName)
                  + ' where process_ID = 3
		update ##spMFClassTableStats set MFError = 0 where TableName = ''' + @TableName + '''
		'   ;

            EXEC (@SQL);

            SET @SQL
                = N'Update t set process_ID=0 from ' + QUOTENAME(@TableName)
                  + ' t where process_ID = 2
		update ##spMFClassTableStats set SyncError = 0 where TableName = ''' + @TableName + '''
		'   ;

            EXEC (@SQL);
        END;
		END --included in app

    SELECT @ID = MIN([t].[ClassID])
    FROM [##spMFClassTableStats] AS [t]
    WHERE [t].[ClassID] > @ID;

    IF @Debug > 0
        SELECT @ID AS [nextID];
		
END; -- END while

IF @IncludeOutput = 0
BEGIN
    SELECT [ClassID]
          ,[TableName]
          ,[IncludeInApp]
          ,[SQLRecordCount]
          ,[MFRecordCount]
          ,[MFNotInSQL]
          ,[Deleted]
          ,[SyncError]
          ,[Process_ID_1]
          ,[MFError]
          ,[SQLError]
          ,[LastModified]
          ,[MFLastModified]
          ,1 AS [Flag]
    FROM [##spMFClassTableStats]
    WHERE ISNULL([SQLRecordCount], -1) <> -1;

    DROP TABLE [##spMFClassTableStats];
END;

RETURN 1;
GO
