
/*
LESSON NOTES
Al large part of the value MFSQL Connector is to enhance to vault development process. This section elaborate on some of the tools to use.

All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/


/*
SYNCHRONIZE METADATA DURING ITERATIVE VAULT DEVELOPMENT
Structure changes in M-Files
Custom changes in SQL
Synchronize during development
Making Custom changes to Tablename, columns, and more
Synchronize specific metadata
*/


--- refresh metadata with different methods

-- use for first time refresh
EXEC [spMFSynchronizeMetadata]; 

-- use during iterative design
EXEC [spMFDropAndUpdateMetadata]; 

-- use to drop all custom settings in the metadata structure table settings
EXEC [dbo].[spMFDropAndUpdateMetadata]
    @IsResetAll = 1 

--- use to only update specific metadata
EXEC [spMFSynchronizeSpecificMetadata] 'Class'; 
--OR 
EXEC [dbo].[spMFSynchronizeSpecificMetadata]
    @Metadata = 'User', --  ObjectType; Class; Property; Valuelist; ValuelistItem; Workflow; State; User; Login
    @IsUpdate = 0,  -- set to 1 to push updates to M-Files, see example usage
    @ItemName = NULL , --only application for valuelists
    @Debug = 0

	
	SELECT TOP 100 * FROM [dbo].[MFProperty] as [mp]
	SELECT TOP 100 * FROM [dbo].[MFClass] as [mc]
	SELECT TOP 100 * FROM [dbo].[MFValueList] as [mvl]
	SELECT TOP 100 * FROM [dbo].[MFValueListItems] as [mvli]
	SELECT TOP 100 * FROM [dbo].[MFWorkflow] as [mw]
	SELECT TOP 100 * FROM [dbo].[MFWorkflowState] as [mws]
	SELECT TOP 100 * FROM [dbo].[MFObjectType] as [mot]
	SELECT TOP 100 * FROM [dbo].[MFObjectType] as [mot]
	SELECT TOP 100 * FROM [dbo].[MFUserAccount] as [mua]
	SELECT TOP 100 * FROM [dbo].[MFLoginAccount] as [mla]

	
-- use to only update value list items for a specific valuelist 
EXEC [dbo].[spMFSynchronizeSpecificMetadata] 
	@Metadata = 'Valuelist'	-- to set this for Valuelists
  , @ItemName = 'Country'	-- use any valuelist name to update only that valuelist items

-- The structure: Object Type; Class; Property; Valuelist; Valuelist Items; Workflow; Workflow States; user Account; LoginAccount

--build the process logging into the procedure to build any metadata structure update into a procedure by using the ProcessBatch_ID
DECLARE @ProcessBatch_ID INT;
EXEC [dbo].[spMFDropAndUpdateMetadata]
    @IsResetAll = 0,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @Debug = 0

SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd]
INNER JOIN [dbo].[MFProcessBatch] AS [mpb]
ON [mpb].[ProcessBatch_ID] = [mpbd].[ProcessBatch_ID]
WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID

---DEEPER EXPLORATION OF METADATA STRUCTURE

SELECT *
FROM [dbo].[MFClass];

--View other metadata Structure tables using joins
--Property / class : relationship between classes and properties through MFClassProperty

SELECT *
FROM [MFProperty] AS [mp]
    INNER JOIN [MFClassProperty] AS [mcp]
        ON [mcp].[MFProperty_ID] = [mp].[ID]
    INNER JOIN [MFClass] AS [mc]
        ON [mcp].[MFClass_ID] = [mc].[ID]
WHERE [mc].[Name] = 'Customer';

--Valuelist /Valuelist items
SELECT * FROM [dbo].[MFValueList] AS [mvl]
INNER JOIN [dbo].[MFValueListItems] AS [mvli]
ON [mvli].[MFValueListID] = [mvl].[ID]
WHERE mvl.[Name] = 'Country'

--workflow and states
SELECT *
FROM [dbo].[MFWorkflow] AS [mw]
    INNER JOIN [dbo].[MFWorkflowState] AS [mws]
        ON [mws].[MFWorkflowID] = [mw].[ID]
WHERE [mw].[Name] = 'Processing job applications';


--Using the structure view
select * FROM [dbo].[MFvwMetadataStructure] AS [mfms]
WHERE [mfms].[class] = 'Customer'

select * FROM [dbo].[MFvwMetadataStructure] AS [mfms]
WHERE [mfms].[Property] = 'Customer'

select * FROM [dbo].[MFvwMetadataStructure] AS [mfms]
WHERE [mfms].[Valuelist] = 'country'

select * FROM [dbo].[MFvwMetadataStructure] AS [mfms]
WHERE [mfms].[Workflow] = 'Processing job applications'


/*
MAKING STRUCTURE CHANGES

Changes in M-Files
	- adding / deleting structure objects

In SQL
	- adding / changing deleting valuelist items
	- name / alias changes for classes, properties, valuelists, workflows, states

Integration setup changes
	- changing the defaults: Tablename ;Columnname; AppRef 
	- using IncludeInApp

*/

--using Class Table Stats

-- list all class tables 
EXEC [spMFClassTableStats]; 

-- for a specific class table
EXEC [dbo].[spMFClassTableStats] 
	@ClassTableName = N'MFCustomer'	

-- export to temporary table for use in procedures

EXEC [dbo].[spMFClassTableStats] 
	@ClassTableName = N'MFCustomer'	
  , @IncludeOutput = 1		
  , @Debug = 0	
 SELECT * FROM ##spmfclasstablestats
 		
--class Tables need to be dropped before resetting metadata 

EXEC [dbo].[spMFDropAllClassTables] @IncludeInApp = 1;

--Changes in M-Files

EXEC [dbo].[spMFDropAndUpdateMetadata] @IsReset = 1, @Debug = 0; 


--changes in SQL

--change name of classtable
UPDATE [dbo].[MFClass]
SET [TableName] = 'MyAgenda'
WHERE [mfid] = 15;

--create table
EXEC [dbo].[spMFCreateTable] @ClassName = N'Agenda', 
                             @Debug = 0;             


--pull from M-Files

EXEC [dbo].[spMFUpdateTable] @MFTableName = N'MyAgenda', 
                             @UpdateMethod = 1;

-- make change to columnname
SELECT *
FROM [MFProperty];

UPDATE [MFProperty]
SET [ColumnName] = 'PostalCode'
WHERE [ID] = 591;

SELECT *
FROM [MFCustomer];
DROP TABLE [MFCustomer];
EXEC [spMFCreateTable] 'Customer';

-- update metadata - no reset of custom columns
EXEC [dbo].[spMFDropAndUpdateMetadata] @IsReset = 0, @Debug = 0; -- smallint

--when the IsReset flag is set to 1 it will reset all custom changes in the metadata structure in SQL to what is in M-Files.

--using full logging

DECLARE @ProcessBatch_ID int
EXEC [dbo].[spMFDropAndUpdateMetadata]
	@IsReset = 1	-- int
  , @Debug = 0		-- smallint
  ,@ProcessBatch_ID = @ProcessBatch_ID output
SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID
Go


--create table to demonstrate change

SELECT *
FROM [dbo].[MFClass];

EXEC [dbo].[spMFCreateTable] @ClassName = N'Agenda', -- nvarchar(128)
                             @Debug = 0;             -- smallint

SELECT *
FROM [MyAgenda];

--Getting back to the beginning - reset to defaults

EXEC [dbo].[spMFDropAndUpdateMetadata] @IsReset = 1, @Debug = 0; 

