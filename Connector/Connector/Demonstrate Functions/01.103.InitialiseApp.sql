


/*
Script to initialise MFSQL Connector
*/

--test connection
exec spMFVaultConnectionTest

--first time metadata synchronizaiton
--exec spMFSynchronizeMetadata

--Update synchronization

EXEC [dbo].[spMFDropAndUpdateMetadata] @IsResetAll = 0

GO
							                                -- smallint

EXEC dbo.spMFDropAllClassTables @IncludeInApp = 1, -- int
                                @Debug = 0         -- smallint
  
--View structure
SELECT class,* FROM [dbo].[MFvwMetadataStructure] AS [mfms] WHERE class = 'Tenant'

--create class tables

select * from MFClass

UPDATE MFClass
SET IncludeInApp = 1
WHERE Name IN ('Loan','Member Account','Tenant','Account Document', 'Employee','Document Type', 'Scion Template', 'Address')

Select TableName from MFClass where IncludeInApp = 1

EXEC spMFCreateAllMFTables 

--pull from MF for all class tables

exec spMFUpdateAllncludedInAppTables @UpdateMethod = 1

--check table stats

exec spMFClassTableStats

--

GO

--show errors

SELECT TOP 3 * FROM mflog ORDER BY logid DESC

--Create lookups

EXEC [dbo].[spMFCreateValueListLookupView] @ValueListName = 'Country', 
                                           @ViewName = 'MFvwCpountry',      
                                           @Debug = 0          

EXEC [dbo].[spMFCreateWorkflowStateLookupView] @WorkflowName = 'Approval Flow', 
                                               @ViewName = 'MFvwApproval_State',     
                                               @Debug = 0        
 
 --Create aliases

 DECLARE @ProcessBatch_ID INT;
 EXEC [dbo].[spMFAliasesUpsert] @MFTableNames = 'MFClass', -- nvarchar(400)
                                @Prefix = 'c',       -- nvarchar(10)
                                @IsRemove = 0,     -- bit
                                @WithUpdate = 1,   -- bit
                                @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,            -- int
                                @Debug = 0         -- smallint

--Remove aliases 

 EXEC [dbo].[spMFAliasesUpsert] @MFTableNames = 'MFClass', -- nvarchar(400)
                                @Prefix = 'c',       -- nvarchar(10)
                                @IsRemove = 1,     -- bit
                                @WithUpdate = 1,   -- bit
                                @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,            -- int
                                @Debug = 0         -- smallint

--customise settings

EXEC [dbo].[spMFSettingsForDBUpdate]               
                                     @SupportEmailAccount = 'support@yourdomain.com'      -- nvarchar(128)
                                    

-- add context menu items

EXEC [dbo].[spMFContextMenuHeadingItem] @MenuName = 'MyMenu',            -- nvarchar(100)
                                        @PriorMenu = null,           -- nvarchar(100)
                                        @IsObjectContextMenu = 0, -- bit
                                        @IsRemove = 0,            -- bit
                                        @UserGroup = 'ContextMenu',           -- nvarchar(100)
                                        @Debug = 0                -- int

EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'MyAction',      -- nvarchar(100)
                                       @ProcedureName = 'custom.doUpdate',   -- nvarchar(100)
                                       @Description = '',     -- nvarchar(200)
                                       @RelatedMenu = 'MyMenu',     -- nvarchar(100)
                                       @IsRemove = 0,        -- bit
                                       @IsObjectContext = 0, -- bit
                                       @IsWeblink = 0,       -- bit
                                       @IsAsynchronous = 0,  -- bit
                                       @IsStateAction = 0,   -- bit
                                       @PriorAction = null,     -- nvarchar(100)
                                       @UserGroup = 'Contextmenu',       -- nvarchar(100)
                                       @Debug = 0            -- int

