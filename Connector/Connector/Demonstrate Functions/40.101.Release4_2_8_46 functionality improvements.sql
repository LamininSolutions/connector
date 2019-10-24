
/*
Practical demonstration of new or improved functionality in release 4.2.8.46
*/

--Created on: 2019-01-02 


/*
IMPROVEMENTS
Logging
Messages (see Reporting routine under NEW FUNCTIONALITY)
Display of time

*/

--note the improvements in the display of the logging items in MFProcessBatchDetail and MFProcessBatch
--note the improvement in the display of the user message

SELECT * FROM [dbo].[MFContextMenu] AS [mcm]

DECLARE @Return_LastModified DATETIME
       ,@Update_IDOut        INT
       ,@ProcessBatch_ID     INT;

EXEC [dbo].[spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1 -- int
                                                ,@Return_LastModified = @Return_LastModified OUTPUT    -- datetime
                                                ,@TableName = 'MFCustomer'    -- sysname
                                                ,@Update_IDOut = @Update_IDOut OUTPUT                  -- int
                                                ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT            -- int
                                                ,@debug = 0        -- smallint

SELECT * FROM [dbo].[MFProcessBatch] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID


--display of time and boolean

EXEC spmfupdatetable 'MFOtherDocument',1

SELECT [mod].[Iscurrent], * FROM [dbo].[MFOtherDocument] AS [mod] WHERE start_Time IS NOT NULL



/*
NEW FUNCTIONALITY
spMFClassTablecolumns
spMFSetup_Reporting
auto add column of metadata structure change took place
update table in batches
get object version of single record
*/


--view use and errors for class tables columns

EXEC [dbo].[spMFClassTableColumns]
SELECT * FROM ##spMFClassTableColumns

GO

--auto setup reporting
EXEC [dbo].[spMFSetup_Reporting] @Classes = 'Customer, Sales Invoice' -- nvarchar(400)
                                ,@Debug = 0   -- int

SELECT * FROM [dbo].[MFContextMenu] AS [mcm]

DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFUpdateAllncludedInAppTables] @UpdateMethod = 1  -- int
                                            ,@RemoveDeleted = 0 -- int
                                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT            -- int
                                            ,@Debug = 0         -- smallint


SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

EXEC [dbo].[spMFProcessBatch_EMail] @ProcessBatch_ID = @ProcessBatch_ID            -- int
                                   ,@RecipientEmail = 'leroux@lamininsolutions.com'             -- nvarchar(258)
                                   ,@RecipientFromMFSettingName = null -- nvarchar(258)
                                   ,@ContextMenu_ID = null             -- int
                                   ,@DetailLevel = 0                -- int
                                   ,@LogTypes = 'Message'                   -- nvarchar(258)
                                   ,@Debug = 0                      -- int

SELECT [mum].[Mfsql_Message],* FROM [dbo].[MFUserMessages] AS [mum] WHERE [mum].[Mfsql_Process_Batch] = @ProcessBatch_ID

GO

--check validity of columns

DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFDropAndUpdateMetadata] @IsReset = 0             -- smallint
                                      ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT                   -- int
                                      ,@Debug = 0               -- smallint
                                      ,@WithClassTableReset = 0 -- smallint
                                      ,@IsStructureOnly = 0     -- smallint

GO

-- update table in batches : 03.151.using spmfupdatetableInbatches for batch updates

-- all objects in vault


--how to get the max id's in a vault
EXEC [dbo].[spMFObjectTypeUpdateClassIndex] @IsAllTables = 1 -- setting to 0 will only include includedinapp class tables
                                           ,@Debug = 0       -- smallint


SELECT mc.[TableName], mc.[IncludeInApp], COUNT(*), MAX([mottco].[Object_MFID]) FROM [dbo].[MFObjectTypeToClassObject] AS [mottco] 
INNER JOIN MFClass mc
ON mc.mfid = mottco.[Class_ID]
GROUP BY mc.[TableName],mc.[IncludeInApp]

--or

SELECT * FROM [dbo].[MFvwObjectTypeSummary] AS [mfots]

GO

--Get object version of single record

--as xml record
DECLARE @NewObjectXML NVARCHAR(MAX)

        EXEC [dbo].[spMFGetObjectvers] @TableName = 'MFOtherDocument',         -- nvarchar(max)
                                       @dtModifiedDate = null, -- datetime
                                       @MFIDs = '493',         -- nvarchar(max)
                                       @outPutXML = @NewObjectXml OUTPUT; -- nvarchar(max)

SELECT CAST(@NewObjectXML AS XML)
GO
--from MFaudithistory

DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT
	   ,@Objids NVARCHAR(4000) = '492,493';

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFOtherDocument'    -- nvarchar(128)
                        --   ,@MFModifiedDate = ? -- datetime
                           ,@ObjIDs = @Objids         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 0          -- smallint

SELECT * FROM [dbo].[MFAuditHistory] AS [mah] WHERE mah.[ObjID] IN (SELECT ListItem FROM [dbo].[fnMFParseDelimitedString](@objids,','))

GO

