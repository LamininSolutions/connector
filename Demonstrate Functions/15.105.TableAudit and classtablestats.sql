
/*
How to use table audit and class table stats
*/

DECLARE @MFTableName NVARCHAR(100) = 'MFCustomer'
	-------------------------------------------------------------
    -- USING SPMFCLASSTABLESTATS AND TABLE AUDIT TO WORK WITH CLASS TABLE RESULTS
    -------------------------------------------------------------

	EXEC [dbo].[spMFClassTableStats] @ClassTableName = @MFTableName -- nvarchar(128)
	                                ,@Flag = 0             -- int
	                                ,@IncludeOutput = 0    -- int
	                                ,@Debug = 0            -- smallint
	

	EXEC [dbo].[spMFClassTableStats] @IncludeOutput = 1    -- int
	SELECT * FROM ##spmfclasstablestats

		-------------------------------------------------------------
	    -- SPMFTABLEAUDIT to validate the objectversions from M-Files
	    -------------------------------------------------------------
GO


--SELECT FROM HERE

		DECLARE @MFTableName NVARCHAR(100) = 'MFCustomer'
		DECLARE @Class NVARCHAR(100) 
		SELECT @Class = [Name] FROM mfclass WHERE tablename = @MFTableName

		DECLARE @Session      INT
					   ,@ReturnedDate DATETIME
					   ,@UpdateRequired  BIT
				       ,@NewObjectXml    NVARCHAR(MAX)		
				       ,@OutofSync       INT
				       ,@ProcessErrors   INT
					   ,@DeletedInSQL	INT
					   ,@ProcessBatch_ID INT = null

				EXEC [dbo].[spMFTableAudit] @MFTableName = @MFTableName                        -- nvarchar(128)
				                           ,@MFModifiedDate = null    -- datetime
				                           ,@ObjIDs = null                             -- nvarchar(4000)
				                           ,@SessionIDOut = @Session OUTPUT       -- int
				                           ,@NewObjectXml = @NewObjectXml OUTPUT      -- nvarchar(max)
				                           ,@DeletedInSQL = @DeletedInSQL OUTPUT       -- int
				                           ,@UpdateRequired = @UpdateRequired OUTPUT  -- bit
				                           ,@OutofSync = @OutofSync OUTPUT             -- int
				                           ,@ProcessErrors = @ProcessErrors OUTPUT     -- int
				                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
				                           ,@Debug = 101  

										   SELECT @Session AS Session
										   , @UpdateRequired AS UpdateRequired
										   , @DeletedInSQL AS DeletedINSQL
										   , @OutofSync AS OutofSync
										   ,@ProcessErrors AS ProcessErrors

SELECT * FROM [dbo].[MFvwAuditSummary] AS [mfas] WHERE [mfas].[Class] = @Class
SELECT * FROM [dbo].[MFProcessBatch] AS [mpb] WHERE [mpb].[ProcessBatch_ID] = @ProcessBatch_ID
SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID



--send email with result
EXEC [dbo].[spMFProcessBatch_EMail] @ProcessBatch_ID = @ProcessBatch_ID             -- int
                                   ,@RecipientEmail = N'leroux@lamininsolutions.com'             -- nvarchar(258)
                                   ,@RecipientFromMFSettingName = null -- nvarchar(258)
                                   ,@ContextMenu_ID = 0               -- int
                                   ,@Debug = 0                        -- int




--example using table audit to set update

	IF @UpdateRequired = 1	
			Begin
				DECLARE @MFLastUpdateDate SMALLDATETIME;
				EXEC [dbo].[spMFUpdateMFilesToMFSQL] @ProcessBatch_ID = @ProcessBatch_ID          -- int
													,@UpdateTypeID = 0                   -- tinyint
													,@MFTableName = @MFTableName                  -- nvarchar(128)
													,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT -- smalldatetime
													,@debug = 0;    
				END
		
	
	
--send email with result
EXEC [dbo].[spMFProcessBatch_EMail] @ProcessBatch_ID = @ProcessBatch_ID             -- int
                                   ,@RecipientEmail = N'leroux@lamininsolutions.com'             -- nvarchar(258)
                                   ,@RecipientFromMFSettingName = null -- nvarchar(258)
                                   ,@ContextMenu_ID = 0               -- int
                                   ,@Debug = 0                        -- int

	GO
					
--SELECT TO HERE THEN PRESS F5