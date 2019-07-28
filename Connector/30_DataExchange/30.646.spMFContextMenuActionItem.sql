PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.spMFContextMenuActionItem';
GO
SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFContextMenuActionItem', -- nvarchar(100)
                                     @Object_Release = '4.1.5.42',
                                     @UpdateFlag = 2;

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\lerouxc
	Create date: 2018-5-12 09:52
	Database: 
	Description: Add Action item to Context Menu

	PARAMETERS:
			
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE					NAME		DESCRIPTION
2018-07-15					lc			Add state actions	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  



-----------------------------------------------------------------------------------------------*/
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

