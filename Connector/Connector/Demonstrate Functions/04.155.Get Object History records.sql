



		-------------------------------------------------------------
	    -- GET HISTORY RECORDS
	    -------------------------------------------------------------

		
/*
Using spMFGetHistory

*/

--getting a class table to work with

EXEC spmfcreatetable 'Purchase Invoice'

SELECT * FROM [dbo].[MFPurchaseInvoice] AS [mc] 

EXEC spmfupdatetable 'MFPurchaseInvoice',1

--execute from here

UPDATE [MFPurchaseInvoice]
SET Process_ID = 5

DECLARE @RC INT
DECLARE @TableName NVARCHAR(128) = 'MFPurchaseInvoice'
DECLARE @Process_id INT = 5
DECLARE @ColumnNames NVARCHAR(4000) = 'State'
DECLARE @IsFullHistory BIT = 1
DECLARE @NumberOFDays INT  
DECLARE @SearchString NVARCHAR(MAX) = null
DECLARE @StartDate DATETIME --= DATEADD(DAY,-1,GETDATE())
DECLARE @ProcessBatch_id INT
DECLARE @Debug INT = 1
DECLARE @Update_ID        INT


EXEC [dbo].[spMFGetHistory] @MFTableName =  @TableName   -- nvarchar(128)
                           ,@Process_id = @Process_id    -- int
                           ,@ColumnNames = @ColumnNames   -- nvarchar(4000)
                           ,@SearchString = null  -- nvarchar(4000)
                           ,@IsFullHistory = @IsFullHistory -- bit
                           ,@NumberOFDays = @NumberOFDays  -- int
                           ,@StartDate = @StartDate     -- datetime
                           ,@Update_ID = @Update_ID OUTPUT                         -- int
                           ,@ProcessBatch_id = @ProcessBatch_id OUTPUT            -- int
                           ,@Debug = @debug         -- int



SELECT * FROM [dbo].[MFProcessBatch] AS [mpb] WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_id
SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_id

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch]

--to here

-- show list of values including property value

SELECT toh.*,mp.name AS propertyname FROM mfobjectchangehistory toh
INNER JOIN mfproperty mp
ON mp.[MFID] = toh.[Property_ID]
ORDER BY [toh].[Class_ID],[toh].[ObjID],[toh].[MFVersion],[toh].[Property_ID]

-- show list of values where property is a state

SELECT toh.*,mp.name AS propertyname, [mws].[Name] AS State FROM mfobjectchangehistory toh
INNER JOIN mfproperty mp
ON mp.[MFID] = toh.[Property_ID]
LEFT JOIN [dbo].[MFWorkflowState] AS [mws]
ON mws.mfid = toh.[Property_Value]
WHERE toh.[Property_ID] = 39
ORDER BY [toh].[Class_ID],[toh].[ObjID],[toh].[MFVersion],[toh].[Property_ID]
GO

--Deleting records

DELETE FROM [dbo].[MFObjectChangeHistory] 
WHERE [Class_ID] IN (SELECT MFID FROM MFClass WHERE [TableName] = 'MFPurchaseInvoice')


-- views for the change history table

--object types in change history table
SELECT DISTINCT mot.Name AS objectType FROM [dbo].[MFObjectType] AS [mot]
INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
ON mot.[MFID] = moch.[ObjectType_ID]

--getting the object type id for the class

SELECT MC2.MFID class_id, mot.MFID ObjectType_ID, mc2.name Class, mot.name ObjectType FROM [dbo].[MFClass] AS [mc2]
INNER JOIN [dbo].[MFObjectType] AS [mot]
ON mot.id = mc2.[MFObjectType_ID]

--show classes in table
SELECT mc2.name FROM [dbo].[MFClass] AS [mc2]
INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
ON mc2.mfid = moch.[Class_ID]
GROUP BY mc2.name

--converting universal time

SELECT SYSDATETIME() AS [SYSDATETIME()]  
    ,SYSDATETIMEOFFSET() AS [SYSDATETIMEOFFSET()]  
    ,SYSUTCDATETIME() AS [SYSUTCDATETIME()]  
    ,CURRENT_TIMESTAMP AS [CURRENT_TIMESTAMP]  
    ,GETDATE() AS [GETDATE()]  
    ,GETUTCDATE() AS [GETUTCDATE()];  

	--adjust for local time (where the time offset is known)

	SELECT TOP 5 [moch].[LastModifiedUtc], DATEADD(HOUR,-5,[moch].[LastModifiedUtc]) EasternTime FROM [dbo].[MFObjectChangeHistory] AS [moch]

	--user id

	SELECT mla.[UserName], [mla].[FullName] FROM [dbo].[MFObjectChangeHistory] AS [moch]
	INNER JOIN [dbo].[MFLoginAccount] AS [mla]
	ON moch.[MFLastModifiedBy_ID] = mla.[MFID]

	--property name


SELECT mp.name AS propertyName FROM [dbo].[MFProperty] mp 
INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
ON mp.[MFID] = moch.[Property_ID]

--property values

--workflow
SELECT name, mfid FROM [dbo].[MFWorkflow] AS [mw]
INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
ON moch.[Property_Value] = mw.[MFID]
WHERE [moch].[Property_ID] = 38

--State
SELECT name, mfid FROM [dbo].[MFWorkflowState] AS [mw]
INNER JOIN [dbo].[MFObjectChangeHistory] AS [moch]
ON moch.[Property_Value] = mw.[MFID]
WHERE [moch].[Property_ID] = 39

--Valuelist items

SELECT moch.id,[moch].[ObjID], moch.MFVersion,  moch.[Property_ID], moch.[Property_Value]
, mp.name Property, mvl.name AS Valuelist, mvl.[RealObjectType]
, mvli.name AS Valuelistitem
  FROM [dbo].[MFObjectChangeHistory] AS [moch]
INNER JOIN [dbo].[MFProperty] AS [mp]
ON moch.[Property_ID] = mp.[MFID]
INNER JOIN [dbo].[MFValueList] AS [mvl]
ON mp.[MFValueList_ID] = mvl.[ID]
INNER JOIN [dbo].[MFValueListItems] AS [mvli]
ON moch.[Property_Value] = mvli.[MFID] AND mvli.[MFValueListID] = mvl.[ID]
ORDER BY [moch].[ObjID]

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch]
INNER JOIN [dbo].[MFvwMetadataStructure] AS [mfms]
ON [mfms].[Property_MFID] = [moch].[Property_ID] AND moch.[Class_ID] = mfms.[class_MFID]
INNER JOIN [dbo].[MFValueListItems] AS [mvli]
ON mvli.[MFID] = moch.[Property_Value] AND mfms.[Valuelist_ID] = mvli.[MFValueListID]

--creating a valuelist item view for currency

--EXEC [dbo].[spMFCreateValueListLookupView] @ValueListName = 'Currency' -- nvarchar(128)
--                                          ,@ViewName = 'vwCurrency'      -- nvarchar(128)
--                                          ,@Schema = 'Custom'        -- nvarchar(20)
--                                          ,@Debug = 0         -- smallint

--SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch]
--INNER JOIN [dbo].[MFProperty] AS [mp]
--ON moch.[Property_ID] = mp.mfid
--INNER JOIN custom.[VLvwCurrency] AS [vlc]
--ON vlc.[MFID_ValueListItems] = moch.[Property_Value] AND vlc.[ID_ValueList] = mp.[MFValueList_ID]
--ON 

-- working with a multi lookup valuelist

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch]
CROSS APPLY [dbo].[fnMFParseDelimitedString]([moch].[Property_Value],',') AS [fmpds]
INNER JOIN [dbo].[MFvwMetadataStructure] AS [mfms]
ON [mfms].[Property_MFID] = moch.[Property_ID] AND moch.[Class_ID] = mfms.[class_MFID]
INNER JOIN [dbo].[MFValueListItems] AS [mvli]
ON mvli.[MFID] = [fmpds].[ListItem] AND mfms.[Valuelist_ID] = mvli.[MFValueListID]

--Real object type Property Values

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch]
INNER JOIN [dbo].[MFvwMetadataStructure] AS [mfms]
ON [mfms].[Property_MFID] = moch.[Property_ID] AND moch.[Class_ID] = mfms.[class_MFID]
INNER JOIN [dbo].[MFPurchaseInvoice] AS [ma]
ON moch.[Property_Value] = ma.[ObjID]
WHERE [mfms].[IsObjectType] = 1