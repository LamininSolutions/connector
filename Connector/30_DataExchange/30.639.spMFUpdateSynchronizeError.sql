
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spmfUpdateSynchronizeError]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFUpdateSynchronizeError',
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
    WHERE ROUTINE_NAME = 'spMFUpdateSynchronizeError' --name of procedure
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
CREATE PROCEDURE dbo.spMFUpdateSynchronizeError
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO
--exec spmfUpdateSynchronizeError 'MFSalesInvoice',1
ALTER PROCEDURE dbo.spMFUpdateSynchronizeError
    @TableName VARCHAR(100),
    @Update_ID INT,
    @RetainDeletions BIT = 0,
    @IsDocumentCollection BIT = 0,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug INT = 0
AS
/*rST**************************************************************************

==========================
spMFUpdateSynchronizeError
==========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @TableName varchar(100)
    - Valid Class TableName as a string
    - Pass the class table name, e.g. MFCustomer
  @Update\_ID int
    Related update id output
  @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
  @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
  @ProcessBatch\_ID int (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Fix synchronization errors.

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-09-02  LC         Update to include RetainDeletions and DocumentCollections
2022-08-03  LC         fix bug on calling proc in sync precedence
2022-08-03  LC         Updating debug logging to aid error trapping
2019-08-30  JC         Added documentation
2018-08-29  LC         Include this process as a part of the logging of MFUpdateTable
2018-08-23  LC         Update procedure to only process the errors from the prior update run
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN


    DECLARE @ParmDefinition NVARCHAR(MAX);
    DECLARE @SelectQuery NVARCHAR(MAX);
    DECLARE @ObjIDs NVARCHAR(MAX);
    DECLARE @SyncPrecedence INT;
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';
    DECLARE @ProcedureName sysname = 'spMFUpdateSynchronizeError';
    DECLARE @ProcedureStep sysname = 'Start';
    DECLARE @Update_IDOut INT;


    SET @ParmDefinition = N'@retvalOUT varchar(max) OUTPUT, @Update_ID int';

    SET @DebugText = N'';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    SET @ProcedureStep = 'Getting comma separated ObjIDs for process_id=2';

    SET @SelectQuery
        = N'SELECT @retvalOUT= STUFF((
					select '',''+ cast(ObjID as varchar(10))
					from ' + @TableName
          + N' where process_id=2 and Update_id = @Update_ID
					FOR XML PATH('''')
					)
					,1,1,'''') ';

    --IF @Debug > 0
    --    PRINT @SelectQuery;

    EXEC sys.sp_executesql @SelectQuery,
                           @ParmDefinition,
                           @retvalOUT = @ObjIDs OUTPUT,
                           @Update_ID = @Update_ID;

    SET @DebugText = N' Objids %s';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDs);
    END;
    ------------------------------------------------------
    --Getting @SyncPrecedence from MFClasss table for @TableName
    ------------------------------------------------------
    SET @ProcedureStep = ' Reset sync error items ';
    SELECT @SyncPrecedence = SynchPrecedence
    FROM dbo.MFClass
    WHERE TableName = @TableName;

    SET @DebugText = N' Precedence %i';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF (@SyncPrecedence IS NOT NULL)
       AND @ObjIDs IS NOT NULL
    BEGIN
        --select @SyncPrecedence
        IF @SyncPrecedence = 1
        BEGIN

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @SyncPrecedence);
            END;

            SET @ParmDefinition = N'@Update_ID int';
            SET @SelectQuery
                = N'Update ' + QUOTENAME(@TableName)
                  + N' set  process_id=0 where  process_id=2 and Update_ID = @Update_ID';

            EXEC sys.sp_executesql @SelectQuery,
                                   @ParmDefinition,
                                   @Update_ID = @Update_ID;

            EXEC dbo.spMFUpdateTable @MFTableName = @TableName,
                                     @UpdateMethod = 1,
                                     @ObjIDs = @ObjIDs,
                                     --     @SyncErrorFlag = 0,
                                     @Update_IDOut = @Update_IDOut OUTPUT,
                                     @ProcessBatch_ID = @ProcessBatch_ID,
                                     @RetainDeletions = @RetainDeletions,
                                     @IsDocumentCollection = @IsDocumentCollection,
                                     @Debug = @Debug;

            SET @DebugText = N' Update_ID %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Update_IDOut);
            END;


        END;

        ELSE
        BEGIN
            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @SyncPrecedence);
            END;


            SET @ParmDefinition = N'@Update_ID int';
            SET @SelectQuery
                = N'Update ' + QUOTENAME(@TableName)
                  + N' set  process_id=1 where  process_id=2 and Update_ID = @Update_ID';

            EXEC sys.sp_executesql @SelectQuery,
                                   @ParmDefinition,
                                   @Update_ID = @Update_ID;


            EXEC dbo.spMFUpdateTable @MFTableName = @TableName,
                                     @UpdateMethod = 0,
                                     @ObjIDs = @ObjIDs,
                                     @ProcessBatch_ID = @ProcessBatch_ID,
                                     @Update_IDOut = @Update_ID OUTPUT,
                                     @RetainDeletions = @RetainDeletions,
                                     @IsDocumentCollection = @IsDocumentCollection,
                                     @Debug = @Debug;

            SET @DebugText = N' Update_ID %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Update_IDOut);
            END;
        END;

    END;
END;