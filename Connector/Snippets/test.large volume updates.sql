


DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT;

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFBasic_SingleProp'    -- nvarchar(128)
                           ,@MFModifiedDate = null -- datetime
                          ,@ObjIDs = '515029'        -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 101        -- smallint


						   SELECT * FROM mflog ORDER BY logid DESC
       
	   EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = 'MFOtherDocument' -- nvarchar(100)
	                                       ,@FromObjid = 1   -- int
	                                       ,@ToObjid = 1000     -- int
	                                       ,@WithStats = 1   -- bit
	                                       ,@Debug = 1      -- int
	                 

					 SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas]

