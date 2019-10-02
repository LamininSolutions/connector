
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spmfUpdateSynchronizeError]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFUpdateSynchronizeError',
                                     -- nvarchar(100)
                                     @Object_Release = '4.2.6.44',
                                     -- varchar(50)
                                     @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateSynchronizeError' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateSynchronizeError]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO
--exec spmfUpdateSynchronizeError 'MFSalesInvoice',1
ALTER PROCEDURE [dbo].[spMFUpdateSynchronizeError]
    @TableName VARCHAR(100),
    @Update_ID INT,
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
    - Pass the class table name, e.g.: ‘MFCustomer’
  @Update\_ID int
    fixme description
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
2019-08-30  JC         Added documentation
2018-08-29  LC         Include this process as a part of the logging of MFUpdateTable
2018-08-23  LC         Update procedure to only process the errors from the prior update run
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN


    IF @Debug > 0
    BEGIN
        PRINT 'Declaring Variables';
    END;

    DECLARE @ParmDefinition NVARCHAR(MAX);
    DECLARE @SelectQuery NVARCHAR(MAX);
    DECLARE @ObjID NVARCHAR(MAX);
    DECLARE @SyncPrecedence INT;

    SET @ParmDefinition = N'@retvalOUT varchar(max) OUTPUT, @Update_ID int';

    IF (@Debug > 0)
    BEGIN
        PRINT 'Getting comma separated ObjIDs whose process_id=2';
    END;

    SET @SelectQuery
        = 'SELECT @retvalOUT= STUFF((
					select '',''+ cast(ObjID as varchar(10))
					from ' + @TableName
          + ' where process_id=2 and Update_id = @Update_ID
					FOR XML PATH('''')
					)
					,1,1,'''') ';

    IF @Debug > 0
        PRINT @SelectQuery;

    EXEC [sys].[sp_executesql] @SelectQuery,
                               @ParmDefinition,
                               @retvalOUT = @ObjID OUTPUT,
                               @Update_ID = @Update_ID;

    IF (@Debug > 0)
    BEGIN
        SELECT @ObjID AS [ObjIDs];
    END;

    ------------------------------------------------------
    --Getting @SyncPrecedence from MFClasss table for @TableName
    ------------------------------------------------------
    SELECT @SyncPrecedence = [SynchPrecedence]
    FROM [dbo].[MFClass]
    WHERE [TableName] = @TableName;

    IF (@SyncPrecedence IS NOT NULL)
       AND @ObjID IS NOT NULL
    BEGIN
        --select @SyncPrecedence
        IF @SyncPrecedence = 1
        BEGIN
            IF (@Debug > 0)
            BEGIN
                PRINT 'M-Files To Sql';
            END;
            EXEC [dbo].[spMFUpdateTable] @MFTableName = @TableName,
                                         @UpdateMethod = 1,
                                         @ObjIDs = @ObjID,
                                         @SyncErrorFlag = 1,
                                         @Update_IDOut = @Update_ID OUTPUT,
										 @ProcessBatch_ID = @ProcessBatch_ID ,
                                         @Debug = @Debug;

            SET @ParmDefinition = N'@Update_ID int';
            SET @SelectQuery
                = N'Update ' + QUOTENAME(@TableName)
                  + ' set  process_id=0 where  process_id=2 and Update_ID = @Update_ID';

            EXEC [sys].[sp_executesql] @SelectQuery,
                                       @ParmDefinition,
                                       @Update_ID = @Update_ID;

        END;

        ELSE
        BEGIN
            IF (@Debug > 0)
            BEGIN
                PRINT 'Sql To M-Files';
            END;
           

            SET @ParmDefinition = N'@Update_ID int';
            SET @SelectQuery
                = N'Update ' + QUOTENAME(@TableName)
                  + ' set  process_id=1 where  process_id=2 and Update_ID = @Update_ID';

            EXEC [sys].[sp_executesql] @SelectQuery,
                                       @ParmDefinition,
                                       @Update_ID = @Update_ID;

			IF @debug > 0
			SELECT @ObjID AS objids;

 EXEC [dbo].[spMFUpdateTable] @MFTableName = @TableName,
                                         @UpdateMethod = 0,
                                         @ObjIDs = @ObjID,
                      --                   @SyncErrorFlag = 0,
										 @ProcessBatch_ID = @ProcessBatch_ID ,
                      --                   @Update_IDOut = @Update_ID OUTPUT,
										 @Debug = @Debug;

        END;

    END;
END;