PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.spMFContextMenuActionItem';
GO
SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFContextMenuActionItem', -- nvarchar(100)
                                     @Object_Release = '4.1.5.42',
                                     @UpdateFlag = 2;

GO
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFContextMenuActionItem' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFContextMenuActionItem]
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFContextMenuActionItem]
(
    @ActionName NVARCHAR(100),
    @ProcedureName NVARCHAR(100),
    @Description NVARCHAR(200),
    @RelatedMenu NVARCHAR(100),
    @IsRemove BIT = 0,
    @IsObjectContext BIT = 0,
    @IsWeblink BIT = 0,
    @IsAsynchronous BIT = 1,
    @IsStateAction BIT = 0,
    @PriorAction NVARCHAR(100) = NULL,
    @UserGroup NVARCHAR(100) = NULL,
    @Debug INT = 0
)
AS
/*rST**************************************************************************

=========================
spMFContextMenuActionItem
=========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ActionName nvarchar(100)
    Name visible to the user in the contextmenu
  @ProcedureName nvarchar(100)
    Name of the procedure to be executed
  @Description nvarchar(200)
    Description is visible to the user
  @RelatedMenu nvarchar(100)
    Menu name for the action
  @IsRemove bit (optional)
    - Default = 0
    - 1 = remove the item from the table
  @IsObjectContext bit (optional)
    - Default = 0
    - 1 = the action will be performed as a object context related action
  @IsWeblink bit (optional)
    - Default = 0
    - 1 = the action is a url link
  @IsAsynchronous bit (optional)
    - Default = 0
    - 1 = the action should be performed asynchronously
  @IsStateAction bit (optional)
    - Default = 0
    - 1 = the action will be executed in a workflow state
  @PriorAction nvarchar(100)
    - NULL if not needed
    - The name of the action that should be preceding in the menu
  @UserGroup nvarchar(100)
    The name of the user group which should be able to perform the action
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

This helper procedure is used to add, update or remove an action item from the MFContextMenu table.

Additional Info
===============

By setting each parameter, the correct values will be added to the columns in MFContextMenu for the different types of actions
It is useful the add the menu heading first before adding the action (see spMFContextMenuHeadingItem)

Examples
========

.. code:: sql

    EXEC [dbo].[spMFContextMenuActionItem]
         @ActionName = 'Perform the update' ,
         @ProcedureName = 'Custom.DoMe',
         @Description = 'Procedure to action the update',
         @RelatedMenu = 'Asynchronous Actions',
         @IsRemove = 0,
         @IsObjectContext = 0,
         @IsWeblink = 0,
         @IsAsynchronous = 0,
         @IsStateAction = 0,
         @PriorAction = 'Name if action',
         @UserGroup = 'Internal users',
         @Debug = 0

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2018-07-15  LC         Add state actions
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON;

/*
Procedure to add new line item in MFContextMenu

*/


-------------------------------------------------------------
-- NEW MENU ACTION
-------------------------------------------------------------

BEGIN


    DECLARE @Action NVARCHAR(100);
    DECLARE @ActionMessage NVARCHAR(100);
    DECLARE @ActionType INT;

    DECLARE @ParentID INT;
    DECLARE @IsAsync INT;
    DECLARE @UserGroupID INT;
    DECLARE @SortOrder INT;
    DECLARE @MaxSortOrder INT;
    DECLARE @PriorMenu_ID INT;


    BEGIN

        SET @Action = @ProcedureName;

        SET @ActionType = CASE
                              WHEN @IsWeblink = 1 THEN
                                  2
                              WHEN @IsObjectContext = 0
                                   AND @IsAsynchronous = 0
                                   AND @IsStateAction = 0 THEN
                                  1
                              WHEN @IsObjectContext = 1
                                   AND @IsAsynchronous = 0
                                   AND @IsStateAction = 0 THEN
                                  3
                              WHEN @IsObjectContext = 0
                                   AND @IsAsynchronous = 1
                                   AND @IsStateAction = 0 THEN
                                  1
                              WHEN @IsObjectContext = 1
                                   AND @IsAsynchronous = 1
                                   AND @IsStateAction = 0 THEN
                                  3
                              WHEN @IsStateAction = 1
                                   AND @IsAsynchronous = 1 THEN
                                  5
                              WHEN @IsStateAction = 1
                                   AND @IsAsynchronous = 0 THEN
                                  4
                              ELSE
                                  3
                          END;

        SET @ActionMessage = @Description;
        SELECT @ParentID = [mcm].[ID]
        FROM [dbo].[MFContextMenu] AS [mcm]
        WHERE [mcm].[ActionName] = @RelatedMenu;
        SET @IsAsync = CASE
                           WHEN @IsAsynchronous = 0 THEN
                               0
                           ELSE
                               1
                       END;

        SET @UserGroupID = CASE
                               WHEN @UserGroup IS NULL THEN
                                   1
                               ELSE
                           (
                               SELECT [mfug].[UserGroupID]
                               FROM [dbo].[MFvwUserGroup] AS [mfug]
                               WHERE [mfug].[Name] = @UserGroup
                           )
                           END;


        SELECT @MaxSortOrder = ISNULL(MAX([mcm].[SortOrder]), -1)
        FROM [dbo].[MFContextMenu] AS [mcm]
        WHERE [mcm].[ParentID] = @ParentID;


        SELECT @PriorMenu_ID = CASE
                                   WHEN @RelatedMenu IS NOT NULL THEN
        (
            SELECT [ID] FROM [dbo].[MFContextMenu] WHERE [ActionName] = @PriorAction
        )
                                   ELSE
                                       @MaxSortOrder
                               END;


        SELECT @SortOrder = CASE
                                WHEN @MaxSortOrder = -1 THEN
                                    1
                                WHEN @PriorMenu_ID IS NULL THEN
                                    @MaxSortOrder + 1
                                ELSE
                                    @PriorMenu_ID + 1
                            END;



        CREATE TABLE [#ReorderList]
        (
            [id] INT,
            [sortorder] INT
        );
        INSERT INTO [#ReorderList]
        (
            [id],
            [sortorder]
        )
        SELECT [mcm].[ID],
               [mcm].[SortOrder]
        FROM [dbo].[MFContextMenu] AS [mcm]
        WHERE [mcm].[SortOrder] >= @SortOrder
              AND [mcm].[ParentID] = @ParentID;

        UPDATE [cm]
        SET [cm].[SortOrder] = [cm].[SortOrder] + 1
        FROM [dbo].[MFContextMenu] [cm]
            INNER JOIN [#ReorderList] AS [rl]
                ON [cm].[ID] = [rl].[id]
        WHERE [cm].[ID] = [rl].[id];

        IF @Debug > 0
            SELECT @ActionName AS [Actionname],
                   @Action AS [Action],
                   @ActionType AS [ActionType],
                   @ActionMessage AS [ActionMessage],
                   @SortOrder AS [SortOrder],
                   @ParentID AS [ParentID],
                   @IsAsynchronous AS [ISAsync],
                   @UserGroupID AS [UserGroupID];


        MERGE INTO [dbo].[MFContextMenu] [cm]
        USING
        (
            SELECT @ActionName AS [Actionname],
                   @Action AS [Action],
                   @ActionType AS [ActionType],
                   @ActionMessage AS [ActionMessage],
                   @SortOrder AS [SortOrder],
                   @ParentID AS [ParentID],
                   @IsAsynchronous AS [ISAsync],
                   @UserGroupID AS [UserGroupID]
        ) [S]
        ON [cm].[ActionName] = [S].[Actionname]
        WHEN NOT MATCHED THEN
            INSERT
            (
                [ActionName],
                [Action],
                [ActionType],
                [Message],
                [SortOrder],
                [ParentID],
                [ISAsync],
                [UserGroupID]
            )
            VALUES
            ([S].[Actionname], [S].[Action], [S].[ActionType], [S].[ActionMessage], [S].[SortOrder], [S].[ParentID],
             [S].[ISAsync], [S].[UserGroupID])
        WHEN MATCHED AND @IsRemove = 0 THEN
            UPDATE SET [cm].[Action] = [S].[Action],
                       [cm].[ActionType] = [S].[ActionType],
                       [cm].[Message] = [S].[ActionMessage],
                       [cm].[SortOrder] = [S].[SortOrder],
                       [cm].[ParentID] = [S].[ParentID],
                       [cm].[ISAsync] = [S].[ISAsync],
                       [cm].[UserGroupID] = [S].[UserGroupID];


        DROP TABLE [#ReorderList];

        IF @IsRemove = 1
            DELETE FROM [dbo].[MFContextMenu]
            WHERE [ActionName] = @ActionName;
    END;
END;

IF @Debug > 0
    SELECT *
    FROM [dbo].[MFContextMenu] AS [mcm];

GO

