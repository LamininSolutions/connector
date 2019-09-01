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
   ,@WithReset INT = 0     --- 1 = deleted object will be removed, sync error reset to 0, error 3 records deleted.
   ,@IncludeOutput INT = 0 -- set to 1 to output result to a table ##spMFClassTableStats
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
  @ClassTableName nvarchar(128)
    fixme description
  @Flag int
    fixme description
  @WithReset int
    fixme description
  @IncludeOutput int
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

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