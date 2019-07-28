
/*

The context menu is used to control the procedure calls from M_files into the SQL
It is an integral part of building integral applications with MFSQL Connector

The following scripts illustrate adding or removing the most common type of items to and from the context menu table.


*/

-- Sample entries are inserted into the MFContextMenu table during installation. These entries can be removed
SELECT * FROM [dbo].[MFContextMenu] AS [mcm]

--the usergroups to be used in the menu can be obtained using a view

SELECT * FROM [dbo].[MFvwUserGroup] AS [mfug]

--use the following example to build up all the entries in the table. copy and paste these entries into your custom script and expand on it for your requirements

--*****WARNING: Running this example will remove the sample items in the menu

TRUNCATE TABLE mfcontextmenu
 
-- create all menu heading first


EXEC [dbo].[spMFContextMenuHeadingItem] 
@MenuName = 'Asynchronous Actions', -- this is the name visible to the user in the context menu
@PriorMenu = 'Synchronous Actions', -- this can be used to re-organise the menu 
@IsObjectContextMenu = 0, -- set to 1 if the heading is used for object sensitive actions 
@IsRemove = 0, -- set to 1 to remove 
@UserGroup = 'All internal users' -- this will restrict the menu item for to the users in the usergroup

-- add the actions

EXEC [dbo].[spMFContextMenuActionItem] 
@ActionName = 'Perform the update' ,      -- this is the name visible to the user in the context menu
@ProcedureName = 'Custom.DoMe',   -- name of the procedure to be executed
@Description = 'Procedure to action the update',     -- this description is visible to the user
@RelatedMenu = 'Asynchronous Actions',     -- Menu name for the action
@IsRemove = 0,        -- set to 1 to remove the item from the table
@IsObjectContext = 0, -- set to 1 if the action will be performed as a object context related action.
@IsWeblink = 0,       -- set to 1 if the action is a url link
@IsAsynchronous = 0,  -- set to 1 if the action should be performed asynchronously
@IsStateAction = 0,   -- set to 1 if the action will be executed in a workflow state
@PriorAction = 'Name if action',     -- set to null if not needed, or set to the action that should be preceding
@UserGroup = 'All internal users',       -- set to the name of the user group which should be able to perform the action
@Debug = 0            -- int
                                       

                                      
SELECT * from MFContextMenu