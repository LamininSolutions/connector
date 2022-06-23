



GO


PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSetContextMenuQueue]';
GO

SET NOCOUNT ON;
GO


EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFSetContextMenuQueue', -- nvarchar(100)
                                 @Object_Release = '4.10.29.74',
                                 @UpdateFlag = 2;
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSetContextMenuQueue' --name of procedure
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

CREATE PROCEDURE dbo.spMFSetContextMenuQueue
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFSetContextMenuQueue
(@updateType INT,
@UpdateStatus NVARCHAR(128) ,
@Job_ID INT,
@ContextMenu_Id INT,
 @ClassID INT = null,
 @ObjectID INT = null,
 @ObjectVer INT = null,
 @ObjectType INT = null,
 @ContextMenuLog_ID INT OUTPUT,
@Debug INT = 0)
AS

/*rST**************************************************************************
========================
spMFSetContextMenuQueue
========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ID   - id of Contextmenu

  @Updatetype 

    1 - insert new queue
    2 - update Task
    3 - initiate procedure
    4 - complete procedure
    5 - update error

  @Debug

Purpose
=======

MFContextMenuQueue is part of the queue processing procedures to process action types for context menu actions in M-Files. This particular procedure is designed to set and update entries in the MFContextMenuQueue.

Insert new queue - executed by VAF when call is received from M-Files
Update queue status - when VAF executes Task
Update queue status - when procedure is initiated
Update queue status - when procedure is completed

Additional Info
===============

It is used by the VAF to insert and update the status of the queue and must be included in the custom procedure to process the action.

Examples
========

update queue for contextmenu action 1,4 based procedure

.. code:: sql

    EXEC spMFSetContextMenuQueue @ID = 1, @UpdateType = 3

update queue for contextmenu action 3,5 based procedure

.. code:: sql

    EXEC spMFSetContextMenuQueue @ID = 1, @UpdateType = 4

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-04-28  LC         This procedure is being revised in the light of the new
                       task system in the VAF
2020-01-07  LC         Add routine to clean up the queue
2019-12-06  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


    SET NOCOUNT ON;

    DECLARE @Count INT;
    DECLARE @Procedure NVARCHAR(100);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX);
    DECLARE @Output NVARCHAR(MAX);
    DECLARE @MFTableName NVARCHAR(200);
    DECLARE @Objids NVARCHAR(100);
    DECLARE @Update_IDOut INT;
    DECLARE @ProcessBatch_ID INT;
    DECLARE @StartTime DATETIME;
    

    -------------------------------------------------------------
    -- Add new queue item
    -------------------------------------------------------------

BEGIN TRY

SELECT * FROM dbo.MFContextMenuQueue AS mcmq

    IF @UpdateType = 1
    BEGIN 

     INSERT INTO dbo.MFContextMenuQueue
    (
        ContextMenu_ID,
        ObjectID,
        ObjectType,
        ObjectVer,
        ClassID,
        Status,
        UpdateCycle,
        ProcessBatch_ID,
        UpdateID,
        CreatedOn
    )
    VALUES
    (@ContextMenu_Id, @ObjectID, @ObjectType, @ObjectVer, @ClassID, 1, 1, @ProcessBatch_ID, NULL, @StartTime);
    SET @ContextMenuLog_ID = @@IDENTITY;
    
    END

    IF @UpdateStatus > 1

    BEGIN
    UPDATE cmq
    SET Status = @updateType 
    FROM MFContextMenuQueue cmq
    WHERE cmq.id = @ContextMenuLog_ID

    END




  
  RETURN @ContextMenuLog_ID
    
END TRY
BEGIN CATCH
RAISERROR('failed',16,1)
END CATCH

GO
