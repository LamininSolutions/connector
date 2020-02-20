

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
(@id INT, @Debug INT = 0)
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

MFContextMenuQueue is part of the queue processing procedures to process action type 5 context menu actions in M-Files. This particular procedure is designed to reprocess events that has not processed on the first attempt.

Additional Info
===============

It is indented for a SQL agent to trigger this procedure frequently to check for and process unprocessed queue items.

When triggered this procedure will update the oldest row in the queue that has not been updated successfully. Each time it performed an attempted update the update cycle is incremented. The agent can then be tuned to stop after a number of cycles. It is set to 5 cycles by default

Examples
========

.. code:: sql

    EXEC spMFUpdateContextMenuQueue 1

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-01-07  LC         Add routine to clean up the queue
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
    DECLARE @Output NVARCHAR(MAX);
    DECLARE @MFTableName NVARCHAR(200);
    DECLARE @Objids NVARCHAR(100);
    DECLARE @Update_IDOut INT;
    DECLARE @ProcessBatch_ID INT;


	-------------------------------------------------------------
	-- Consolidate queue items by objid
	-------------------------------------------------------------
;
WITH cte
AS (SELECT mcmq.ObjectID
    FROM dbo.MFContextMenuQueue AS mcmq
    GROUP BY mcmq.ObjectID,
             mcmq.ClassID,
			 mcmq.ContextMenu_ID
    HAVING COUNT(*) > 1),
     cte2
AS (SELECT mcmq.ObjectID,
           mcmq.ClassID,
		   mcmq.ContextMenu_ID,
           MAX(mcmq.ObjectVer) AS ObjectVer
    FROM dbo.MFContextMenuQueue AS mcmq
    WHERE mcmq.ObjectID IN
          (
              SELECT cte.ObjectID FROM cte
          )
    GROUP BY mcmq.ObjectID,
             mcmq.ClassID,
			 mcmq.ContextMenu_ID
			 ),
     cte3
AS (SELECT mcmq.id,
mcmq.ContextMenu_ID,
           cte2.ObjectVer
    FROM dbo.MFContextMenuQueue mcmq
        INNER JOIN cte2
            ON cte2.ClassID = mcmq.ClassID
               AND cte2.ObjectID = mcmq.ObjectID
			  AND cte2.contextMenu_ID = mcmq.ContextMenu_ID ),
     cte4
AS (SELECT mcmq.id
    FROM cte3
        INNER JOIN dbo.MFContextMenuQueue AS mcmq
            ON mcmq.id = cte3.id AND mcmq.ContextMenu_ID = cte3.ContextMenu_ID
    WHERE mcmq.ObjectVer < cte3.ObjectVer)
DELETE FROM dbo.MFContextMenuQueue
WHERE id IN
      (
          SELECT cte4.id FROM cte4
      );

	-------------------------------------------------------------
	-- reprocess the item called with @id
	-------------------------------------------------------------
    SET @Params = N'@Output nvarchar(1000) output';
	   
    SELECT @Count = COUNT(*)
    FROM dbo.MFContextMenuQueue cmq
    WHERE cmq.Status <> 1 AND id = @ID ;

BEGIN TRY
    IF @Count > 0
    BEGIN

            SELECT @ContextMenu_ID = cmq.ContextMenu_ID,
                   @ObjectID = cmq.ObjectID,
                   @Objids = CAST(cmq.ObjectID AS NVARCHAR(100)),
                   @ObjectVer = ISNULL(cmq.ObjectVer,0),
                   @ObjectType = cmq.ObjectType,
                   @ClassID = cmq.ClassID,
                   @Procedure = mcm.Action
            FROM dbo.MFContextMenuQueue AS cmq WITH (NOLOCK)
                INNER JOIN dbo.MFContextMenu AS mcm
                    ON cmq.ContextMenu_ID = mcm.ID
            WHERE cmq.id = @id;

            SELECT @MFTableName = TableName
            FROM dbo.MFClass
            WHERE MFID = @ClassID;
	
SET @params = '@output Nvarchar(max) output'
SET @SQL = '
EXEC '+ @Procedure +' @ObjectID = '+ CAST(@ObjectID AS VARCHAR(10))+ ',
@ObjectType = '+ CAST(@ObjectType AS VARCHAR(10))+ ',
@ObjectVer = '+ CAST(ISNULL(@ObjectVer,0) AS VARCHAR(10))+ ',          
@ID = '+ CAST(@ContextMenu_ID AS VARCHAR(10))+ ',        
@OutPut = @OutPut OUTPUT, 
@ClassID = '+ CAST(@ClassID  AS VARCHAR(10))+ ';'
 
 PRINT @SQL

 EXEC sp_executeSQL @Stmt = @SQL, @Param = @Params, @Output = @Output OUTPUT
 
 SELECT @Output

    END; -- en if count > 0
END TRY
BEGIN CATCH
RAISERROR('failed',16,1)
END CATCH

END;

GO
