

GO


PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateContextMenuQueue]';
GO

SET NOCOUNT ON;
GO


EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFUpdateContextMenuQueue', -- nvarchar(100)
                                 @Object_Release = '4.4.14.55',
                                 @UpdateFlag = 2;
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateContextMenuQueue' --name of procedure
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

CREATE PROCEDURE dbo.spMFUpdateContextMenuQueue
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFUpdateContextMenuQueue
(@id INT)
AS

/*rST**************************************************************************

==========================
spMFUpdateContextMenuQueue
==========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ID
    - id of the row in MFContextMenuQueue

Purpose
=======

This procedure is called by the trigger tMFContextMenuQueue_UpdateQueue on the table MFContextMenuQueue.  The entry into MFContextMenu is inserted by adding a row in the MFContextMenuQueue as part of the custom procedure to process action type 5 context menu actions in M-Files

Additional Info
===============

When triggered this procedure will update all the rows in the queue that has not been updated successfully.

Warnings
========

Examples
========

.. code:: sql

    EXEC spMFUpdateContextMenuQueue 1

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-12-06  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    SET NOCOUNT ON;

    DECLARE @Count INT;
    DECLARE @Procedure NVARCHAR(100);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX);
    DECLARE @ContextMenu_ID INT;
    DECLARE @ClassID INT;
    DECLARE @ObjectID INT;
    DECLARE @ObjectVer INT;
    DECLARE @ObjectType INT;
    DECLARE @Output INT;
    DECLARE @MFTableName NVARCHAR(200);
    DECLARE @Objids NVARCHAR(100);
    DECLARE @Update_IDOut INT;
    DECLARE @ProcessBatch_ID INT;

    SET @Params = N'@Output nvarchar(1000) output';

    SELECT @Count = COUNT(*)
    FROM dbo.MFContextMenuQueue cmq
    WHERE cmq.Status <> 1;


    IF @Count > 0
    BEGIN

        SELECT @id = MIN(cmq.id)
        FROM dbo.MFContextMenuQueue cmq
        WHERE cmq.Status <> 1;

        WHILE @id IS NOT NULL
        BEGIN

            SELECT @ContextMenu_ID = cmq.ContextMenu_ID,
                   @ObjectID = cmq.ObjectID,
                   @Objids = CAST(cmq.ObjectID AS NVARCHAR(100)),
                   @ObjectVer = cmq.ObjectVer,
                   @ObjectType = cmq.ObjectType,
                   @ClassID = cmq.ClassID,
                   @Procedure = mcm.Action
            FROM dbo.MFContextMenuQueue AS cmq
                INNER JOIN dbo.MFContextMenu AS mcm
                    ON cmq.ContextMenu_ID = mcm.ID
            WHERE cmq.id = @id;

            SELECT @id;

            SELECT @MFTableName = TableName
            FROM dbo.MFClass
            WHERE MFID = @ClassID;

            EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,                -- nvarchar(200)
                                     @UpdateMethod = 1,                          -- int
                                     @ObjIDs = @Objids,                          -- nvarchar(max)
                                     @Update_IDOut = @Update_IDOut OUTPUT,       -- int
                                     @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
                                     @Debug = 0;                                 -- smallint

            DECLARE @VersionUpdated INT;

            SELECT @VersionUpdated = muh.NewOrUpdatedObjectDetails.value('(/form/Object/@objVersion)[1]', 'int')
            FROM dbo.MFUpdateHistory AS muh
            WHERE muh.Id = @Update_IDOut;

            UPDATE mcl
            SET mcl.UpdateID = @Update_IDOut,
                mcl.ProcessBatch_ID = @ProcessBatch_ID,
                mcl.Status = CASE
                                 WHEN @ObjectVer = @VersionUpdated THEN
                                     1
                                 ELSE
                                     -1
                             END
            FROM dbo.MFContextMenuQueue mcl
            WHERE mcl.id = @id;

            DELETE FROM dbo.MFContextMenuQueue
            WHERE ObjectID = @ObjectID
                  AND ObjectType = @ObjectType
                  AND ObjectVer < @VersionUpdated;


            SELECT @id =
            (
                SELECT MIN(id) FROM dbo.MFContextMenuQueue WHERE id > @id AND Status <> 1
            );

        END; --end loop

    END; -- en if count > 0

END;

GO
