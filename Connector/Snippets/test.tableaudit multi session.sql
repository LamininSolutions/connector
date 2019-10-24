
/*

*/
--Created on: 2019-06-12 

SELECT objid, * FROM [dbo].[MFLarge_volume] AS [mlv]
WHERE objid IN (100623,106024,10625,10626,11627,12628,13629)
DECLARE @Objids NVARCHAR(4000) =
'100623,106024,10625,10626,11627,12628,13629'

SELECT LEN(@objids)


DECLARE @MFModifiedDate DATETIME, @NewObjectXML NVARCHAR(MAX)

 EXEC [dbo].[spMFGetObjectvers] @TableName = 'MFLarge_Volume'         -- nvarchar(max)
                                      ,@dtModifiedDate = null  -- datetime
                                      ,@MFIDs = @Objids        -- nvarchar(max)
                                      ,@outPutXML = @NewObjectXml OUTPUT; -- nvarchar(max)
SELECT CAST(@NewObjectXML AS xml)

DECLARE @StartTime NVARCHAR(30)
SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('Start %s',10,1,@StartTime) WITH NOWAIT


DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;

	   DECLARE 	   @MFModifiedDate DATETIME;
--SELECT  @MFModifiedDate = MAX([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah]
--WHERE class = 94

SELECT @MFModifiedDate = MAX([mlv].[MF_Last_Modified]) FROM [dbo].[MFBasic_singleprop]  AS [mlv]

SELECT @MFModifiedDate

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFLarge_Volume'    -- nvarchar(128)
                           ,@MFModifiedDate = NULL-- datetime
                           ,@ObjIDs = @Objids         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 0         -- smallint

						   SELECT CAST(@NewObjectXml AS XML) AS [NewObjXML]
						   SELECT @UpdateRequired  AS [UPDATE required]

SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas]

SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('End %s',10,1,@StartTime) WITH NOWAIT

	GO
						  
DECLARE @StartTime NVARCHAR(30)
SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('Start %s',10,1,@StartTime) WITH NOWAIT


DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;

	   DECLARE 	   @MFModifiedDate DATETIME;
--SELECT  @MFModifiedDate = MAX([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah]
--WHERE class = 94

SELECT @MFModifiedDate = MAX([mlv].[MF_Last_Modified]) FROM [dbo].[MFBasic_singleprop]  AS [mlv]

SELECT @MFModifiedDate

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFLarge_Volume'    -- nvarchar(128)
                           ,@MFModifiedDate = @MFModifiedDate -- datetime
                       --    ,@ObjIDs = @Objids         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 0         -- smallint

						   SELECT CAST(@NewObjectXml AS XML)
						   SELECT @UpdateRequired 

SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas]

SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('End %s',10,1,@StartTime) WITH NOWAIT

GO

DECLARE @StartTime NVARCHAR(30)
SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('Start %s',10,1,@StartTime) WITH NOWAIT


DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;

	   DECLARE 	   @MFModifiedDate DATETIME;
--SELECT  @MFModifiedDate = MAX([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah]
--WHERE class = 94

SELECT @MFModifiedDate = MAX([mlv].[MF_Last_Modified]) FROM [dbo].[MFBasic_singleprop]  AS [mlv]

SELECT @MFModifiedDate

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFLarge_Volume'    -- nvarchar(128)
                           ,@MFModifiedDate = @MFModifiedDate -- datetime
                       --    ,@ObjIDs = @Objids         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 0         -- smallint

						   SELECT CAST(@NewObjectXml AS XML)
						   SELECT @UpdateRequired 

SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas]

SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('End %s',10,1,@StartTime) WITH NOWAIT

GO

DECLARE @StartTime NVARCHAR(30)
SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('Start %s',10,1,@StartTime) WITH NOWAIT


DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;

	   DECLARE 	   @MFModifiedDate DATETIME;
--SELECT  @MFModifiedDate = MAX([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah]
--WHERE class = 94

SELECT @MFModifiedDate = MAX([mlv].[MF_Last_Modified]) FROM [dbo].[MFBasic_singleprop]  AS [mlv]

SELECT @MFModifiedDate

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFLarge_Volume'    -- nvarchar(128)
                           ,@MFModifiedDate = @MFModifiedDate -- datetime
                       --    ,@ObjIDs = @Objids         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 0         -- smallint

						   SELECT CAST(@NewObjectXml AS XML)
						   SELECT @UpdateRequired 

SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas]

SET @StartTime = CAST(GETDATE() AS NVARCHAR(30))

RAISERROR('End %s',10,1,@StartTime) WITH NOWAIT

GO
