

/*
Installation of all the menu item scenarios for  Demo of Context Menu

execute the following statement to reset the menu to the items in this script:
Truncate table MFContextMenu

View the resultin table
SELECT * FROM [dbo].[MFContextMenu] AS [mcm]

View in M-Files using the MFSQL Connector action button to see the menu

View the Asynchronous progress messages
Select * from MFUserMessages

*/
SET NOCOUNT ON;


DECLARE @ItemCount INT;
DECLARE @Debug INT = 0;

SELECT @ItemCount = COUNT(*)
FROM [dbo].[MFContextMenu] AS [mcm]
WHERE [mcm].[ActionName] NOT IN ( 'Synchronous Actions', 'Asynchronous Actions', 'Synchronous Object Actions',
                                  'Asynchronous Object Actions', 'Action Type Sync', 'Action Type Async',
                                  'Sync action for context Object', 'Async action for context Object',
                                  'StateAction1', 'StateAction2','Web Sites','Google website'
                                );

IF @Debug > 0
    SELECT @ItemCount AS [Itemcount];

IF @ItemCount = 0 -- this procedure will only be executed if no custom menus have been created


BEGIN


    /*
Insert menu items
*/

    EXEC [dbo].[spMFContextMenuHeadingItem] @MenuName = 'Synchronous Actions', -- nvarchar(100)
                                                                               --       @PriorMenu = '', -- nvarchar(100)
                                            @IsRemove = 0,                     -- bit
                                            @UserGroup = 'All internal users'; -- nvarchar(100)


    EXEC [dbo].[spMFContextMenuHeadingItem] @MenuName = 'Asynchronous Actions', -- nvarchar(100)
                                            @PriorMenu = 'Synchronous Actions', -- nvarchar(100)
                                            @IsRemove = 0,                      -- bit
                                            @UserGroup = 'All internal users';  -- nvarchar(100)


    EXEC [dbo].[spMFContextMenuHeadingItem] @MenuName = 'Web Sites',             -- nvarchar(100)
                                            @PriorMenu = 'Asynchronous Actions', -- nvarchar(100)
                                            @IsRemove = 0,                       -- bit
                                            @UserGroup = 'All internal users';   -- nvarchar(100)

    EXEC [dbo].[spMFContextMenuHeadingItem] @MenuName = 'Synchronous Object Actions', -- nvarchar(100)
                                            @PriorMenu = 'Web Sites',                 -- nvarchar(100)
                                            @IsRemove = 0,
											@IsObjectContextMenu = 1,                            -- bit
                                            @UserGroup = 'All internal users';        -- nvarchar(100)

    EXEC [dbo].[spMFContextMenuHeadingItem] @MenuName = 'Asynchronous Object Actions', -- nvarchar(100)
                                            @PriorMenu = 'Synchronous Object Actions', -- nvarchar(100)
                                            @IsRemove = 0,                             -- bit
											@IsObjectContextMenu = 1,
                                            @UserGroup = 'All internal users';         -- nvarchar(100)



    /*
Web Site access
*/

    EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'Google website',                  -- nvarchar(100)
                                           @ProcedureName = 'http://google.com',            -- nvarchar(100)
                                           @Description = 'Illustrate access to a website', -- nvarchar(200)
                                           @RelatedMenu = 'Web Sites',                      -- nvarchar(100)
                                           @IsRemove = 0,                                   -- bit
                                           @IsObjectContext = 0,                            -- bit
                                           @IsWeblink = 1,                                  -- bit
                                           @IsAsynchronous = 0,                             -- bit
                                           @IsStateAction = 0,                              -- bit
                                           @PriorAction = NULL,                             -- nvarchar(100)
                                           @UserGroup = 'All internal users',               -- nvarchar(100)
                                           @Debug = @Debug;



    EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'Action Type Sync',                                                        -- nvarchar(100)
                                           @ProcedureName = 'custom.DoCMAction',                                                       -- nvarchar(100)
                                           @Description = 'Action the custom.DoCMAction procedure syncronously with feedback message', -- nvarchar(200)
                                           @RelatedMenu = 'Synchronous Actions',                                                       -- nvarchar(100)
                                           @IsRemove = 0,                                                                              -- bit
                                           @IsObjectContext = 0,                                                                       -- bit
                                           @IsWeblink = 0,                                                                             -- bit
                                           @IsAsynchronous = 0,                                                                        -- bit
                                           @IsStateAction = 0,                                                                         -- bit
                                           @PriorAction = NULL,                                                                        -- nvarchar(100)
                                           @UserGroup = 'All internal users',                                                          -- nvarchar(100)
                                           @Debug = @Debug;


    EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'Action Type Async',        -- nvarchar(100)
                                           @ProcedureName = 'Custom.DoCMAsyncAction', -- nvarchar(100)
                                           @Description = 'Action the custom.DoCMAsyncAction procedure Asyncronously - Feedback in User Messages',
                                                                                      -- nvarchar(200)
                                           @RelatedMenu = 'Asynchronous Actions',     -- nvarchar(100)
                                           @IsRemove = 0,                             -- bit
                                           @IsObjectContext = 0,                      -- bit
                                           @IsWeblink = 0,                            -- bit
                                           @IsAsynchronous = 1,                       -- bit
                                           @IsStateAction = 0,                        -- bit
                                           @PriorAction = NULL,                       -- nvarchar(100)
                                           @UserGroup = 'All internal users',         -- nvarchar(100)
                                           @Debug = @Debug;

    EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'Sync action for context Object ',                                                                  -- nvarchar(100)
                                           @ProcedureName = 'Custom.CMDoObjectAction',                                                                               -- nvarchar(100)
                                           @Description = 'Action the Custom.DoObjectAction procedure Synchronously with related object including feedback message', -- nvarchar(200)
                                           @RelatedMenu = 'Synchronous Object Actions',                                                                                     -- nvarchar(100)
                                           @IsRemove = 0,                                                                                                            -- bit
                                           @IsObjectContext = 1,                                                                                                     -- bit
                                           @IsWeblink = 0,                                                                                                           -- bit
                                           @IsAsynchronous = 0,                                                                                                      -- bit
                                           @IsStateAction = 0,                                                                                                       -- bit
                                           @PriorAction = NULL,                                                                                                      -- nvarchar(100)
                                           @UserGroup = 'All internal users',                                                                                        -- nvarchar(100)
                                           @Debug = @Debug;

    EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'ASync action for context Object ',                                                                         -- nvarchar(100)
                                           @ProcedureName = 'Custom.CMDoObjectAction',                                                                                       -- nvarchar(100)
                                           @Description = 'Action the Custom.DoObjectAction procedure Asynchronously with related object including message in UserMessages', -- nvarchar(200)
                                           @RelatedMenu = 'Asynchronous Object Actions',                                                                                            -- nvarchar(100)
                                           @IsRemove = 0,                                                                                                                    -- bit
                                           @IsObjectContext = 1,                                                                                                             -- bit
                                           @IsWeblink = 0,                                                                                                                   -- bit
                                           @IsAsynchronous = 1,                                                                                                              -- bit
                                           @IsStateAction = 0,                                                                                                               -- bit
                                           @PriorAction = NULL,                                                                                                              -- nvarchar(100)
                                           @UserGroup = 'All internal users',                                                                                                -- nvarchar(100)
                                           @Debug = @Debug;

    /*
Insert procedures for workflow state actions
*/

    EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'StateAction1',         -- nvarchar(100)
                                           @ProcedureName = 'custom.DoCMAction', -- nvarchar(100)
                                           @Description = NULL,                  -- nvarchar(200)
                                           @RelatedMenu = NULL,                  -- nvarchar(100)
                                           @IsRemove = 0,                        -- bit
                                           @IsObjectContext = 0,                 -- bit
                                           @IsWeblink = 0,                       -- bit
                                           @IsAsynchronous = 0,                  -- bit
                                           @IsStateAction = 1,                   -- bit
                                           @PriorAction = NULL,                  -- nvarchar(100)
                                           @UserGroup = 'All internal users',    -- nvarchar(100)
                                           @Debug = @Debug;

    EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'StateAction2',                               -- nvarchar(100)
                                           @ProcedureName = 'Custom.CMDoObjectActionForWorkFlowState', -- nvarchar(100)
                                           @Description = NULL,                                        -- nvarchar(200)
                                           @RelatedMenu = NULL,                                        -- nvarchar(100)
                                           @IsRemove = 0,                                              -- bit
                                           @IsObjectContext = 0,                                       -- bit
                                           @IsWeblink = 0,                                             -- bit
                                           @IsAsynchronous = 1,                                        -- bit
                                           @IsStateAction = 1,                                         -- bit
                                           @PriorAction = NULL,                                        -- nvarchar(100)
                                           @UserGroup = 'Context Menu',                          -- nvarchar(100)
                                           @Debug = 0;


END;




GO



