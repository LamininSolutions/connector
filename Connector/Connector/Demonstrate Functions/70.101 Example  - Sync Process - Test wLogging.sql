/*
Author: LSUSA\ArnieC
Date:	  2017-06-08
Time:	  05:42:35.342
*/
DECLARE @ID INT
DECLARE @OutPut VARCHAR(1000)

SELECT @ID = [ID]  FROM [dbo].[MFContextMenu] WHERE [Action] = 'ContMenu.doARInvoiceDocMatch'

  BEGIN TRY
        
                  SET @OutPut = 'Process Start Time: ' + CAST(GETDATE() AS VARCHAR(50)) --- set custom process start message for user
          
  -- Setting Params
                    
                  DECLARE @ProcessBatch_ID INT
                        , @procedureName NVARCHAR(128) = 'doARInvoiceDocMatch'
                        , @ProcedureStep NVARCHAR(128)
                        , @StartTime DATETIME
                        , @Return_Value INT
						, @ProcessType NVARCHAR(50)='AR Invoice Doc Match'
		
                  BEGIN    

  --Updating MFContextMenu to show that process is still running   

                        UPDATE  [dbo].[MFContextMenu]
                        SET     [MFContextMenu].[IsProcessRunning] = 1
                        WHERE   [MFContextMenu].[ID] = @ID
	
	--Logging start of process batch 
			 
                        EXEC [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, 
                            @ProcessType = @ProcessType,
                            @LogType = N'Message',
                            @LogText = @OutPut,
                            @LogStatus = N'Started',
                            @debug = 0 

                        SET @ProcedureStep = 'doARInvoiceDocMatch'
                        SET @StartTime = GETDATE()

                        EXEC [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID,
                            @LogType = N'Message', 
                            @LogText = @OutPut , 
                            @LogStatus = N'In Progress',
                            @StartTime = @StartTime,
                            @MFTableName = NULL,
                            @Validation_ID = NULL,
                            @ColumnName = NULL,
                            @ColumnValue = NULL,
                            @Update_ID = NULL,
                            @LogProcedureName = @procedureName,
                            @LogProcedureStep = @ProcedureStep,
                            @debug = 0 
								
			
			 
                  END        

--- start of custom process for the action, this example updates perform metadata synchronization
                
                  BEGIN
                   
					EXEC [Custom].[doARInvoiceDocMatch] @WriteToMFiles = 1
													   , @ProcessBatch_ID = @ProcessBatch_ID
													   , @debug = 0
				   

                  END

-- set custom message to user
			
                  SET @OutPut = @OutPut + ' Process End Time= ' + CAST(GETDATE() AS VARCHAR(50))


                  BEGIN

-- reset process running in Context Menu

                        UPDATE  [dbo].[MFContextMenu]
                        SET     [MFContextMenu].[IsProcessRunning] = 0
                        WHERE   [MFContextMenu].[ID] = @ID

-- logging end of process batch
       

                        EXEC [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID,
                            @ProcessType = @ProcessType,
                            @LogType = N'Message',
                            @LogText = @OutPut,
                            @LogStatus = N'Completed',
                            @debug = 0

                        --SET @ProcedureStep = 'End Metadata syncrhorization'
                        SET @StartTime = GETDATE()

						EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
																 , @LogType = N'Message'
																 , @LogText = @OutPut
																 , @LogStatus = N'Success'
																 , @StartTime = @StartTime
																 , @MFTableName = NULL
																 , @Validation_ID = NULL
																 , @ColumnName = NULL
																 , @ColumnValue = NULL		
																 , @Update_ID = NULL
																 , @LogProcedureName = @procedureName
																 , @LogProcedureStep = @ProcedureStep
																 , @debug = 0 
	
								
                  END

-- format message for display in context menu
						DECLARE @RowCount INT
						SELECT @RowCount = COUNT(*) FROM [dbo].[CLARInvoiceDoc] WHERE [Mfsql_Process_Batch] = @ProcessBatch_ID

						EXEC [dbo].[spMFResultMessageForUI] @ClassTable = ''
														  , @RowCount = @RowCount
														  , @Processbatch_ID = @ProcessBatch_ID
														  , @MessageOUT = @OutPut OUTPUT
			

            END TRY
            BEGIN CATCH

					UPDATE  [dbo].[MFContextMenu]
					SET     [MFContextMenu].[IsProcessRunning] = 0
					WHERE   [MFContextMenu].[ID] = @ID
											
                  SET @OutPut = 'Error:'
                  SET @OutPut = @OutPut + ( SELECT  ERROR_MESSAGE()
                                          )

            END CATCH
      END






select *
from [dbo].[MFProcessBatch]
where [ProcessBatch_ID] = @ProcessBatch_ID

select *
from [dbo].[MFProcessBatchDetail]
where [ProcessBatch_ID] = @ProcessBatch_ID

select *
from [dbo].[MFUpdateHistory]
where [Id] in
      (
          select distinct
              [Update_ID]
          from [dbo].[MFProcessBatchDetail]
          where [ProcessBatch_ID] = @ProcessBatch_ID
      )

select * from [dbo].[MFLog] order by [LogID] desc	


