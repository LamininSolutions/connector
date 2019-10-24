


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[Custom].[CMDoObjectActionForWorkFlowState]]';
GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'[Custom].[CMDoObjectActionForWorkFlowState]', -- nvarchar(100)
    @Object_Release = '4.1.5.42', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO

/*
update messaging with latest procs
*/

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'CMDoObjectActionForWorkFlowState'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'custom' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [Custom].[CMDoObjectActionForWorkFlowState]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


Alter PROCEDURE [Custom].[CMDoObjectActionForWorkFlowState]
      @ObjectID INT
    , @ObjectType INT
    , @ObjectVer INT
    , @ID INT
    , @OutPut VARCHAR(1000) OUTPUT
	, @ClassID int
AS
      BEGIN

            DECLARE @MFClassTable NVARCHAR(128) 
            DECLARE @SQLQuery NVARCHAR(MAX)
            DECLARE @Params NVARCHAR(MAX)

            BEGIN TRY
        
 
  
                  SET @OutPut = 'Process Start Time: ' + CAST(GETDATE() AS VARCHAR(50)) --- set custom process start message for user
    BEGIN       
  -- Setting Params
               
			         
                        DECLARE @ProcessBatch_ID INT
                              , @procedureName NVARCHAR(128) = 'custom.CMDoObjectAction'
                              , @ProcedureStep NVARCHAR(128)
                              , @StartTime DATETIME
                              , @Return_Value INT

							  
						Select @MFClassTable=TableName from MFClass where MFID=@ClassID

  --Updating MFContextMenu to show that process is still running    

                        UPDATE  [dbo].[MFContextMenu]
                        SET     [MFContextMenu].[IsProcessRunning] = 1
                        WHERE   [MFContextMenu].[ID] = @ID

--Logging start of process batch 

                        EXEC [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                          , -- int
                            @ProcessType = @procedureName
                          , -- nvarchar(50)
                            @LogType = N'Message'
                          , -- nvarchar(50)
                            @LogText = @OutPut
                          , -- nvarchar(4000)
                            @LogStatus = N'Started'
                          , -- nvarchar(50)
                            @debug = 0 -- tinyint

                        SET @ProcedureStep = 'Start custom.DoObjectAction'
                        SET @StartTime = GETDATE()

                        EXEC [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , -- int
                            @LogType = N'Message'
                          , -- nvarchar(50)
                            @LogText = @OutPut
                          , -- nvarchar(4000)
                            @LogStatus = N'In Progress'
                          , -- nvarchar(50)
                            @StartTime = @StartTime
                          , -- datetime
                            @MFTableName = @MFClassTable
                          , -- nvarchar(128)
                            @Validation_ID = NULL
                          , -- int
                            @ColumnName = NULL
                          , -- nvarchar(128)
                            @ColumnValue = NULL
                          , -- nvarchar(256)
                            @Update_ID = NULL
                          , -- int
                            @LogProcedureName = @procedureName
                          , -- nvarchar(128)
                            @LogProcedureStep = @ProcedureStep
                          , -- nvarchar(128)
                            @debug = 0 -- tinyint
			 
                  END     
				     
					--- start of custom process for the action, this example updates keywords property on the object
                
                  BEGIN

				        WAITFOR DELAY '00:01:00';  
                        DECLARE @Name_or_Title NVARCHAR(100)
                        DECLARE @Update_ID INT
						



						--get object from M-Files
                      

					    

					    
						 				 
                         EXEC [dbo].[spMFUpdateTable]
                            @MFTableName = @MFClassTable
                          , -- nvarchar(128)
                            @UpdateMethod = 1
                          , -- int
                            @ObjIDs = @ObjectID
                          , -- nvarchar(4000)
                            @Update_IDOut = @Update_ID OUTPUT
                          , -- int
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , -- int
                            @Debug = 0 -- smallint

--Perform action on/with object
				     
                        SET @Params = N'@Output nvarchar(100), @ObjectID int'
                        SET @SQLQuery = N'              

				 
					UPDATE mot
					SET process_ID = 1
					--,Keywords = ''Updated in '' + @OutPut 
					FROM ' + @MFClassTable + ' mot WHERE [objid] = @ObjectID '
				   
                        EXEC [sys].[sp_executesql]
                            @SQLQuery
                          , @Params
                          , @OutPut = @OutPut
                          , @ObjectID = @ObjectID

--process update of object into M-Files
				   

                        EXEC [dbo].[spMFUpdateTable]
                            @MFTableName = @MFClassTable
                          , -- nvarchar(128)
                            @UpdateMethod = 0
                          , -- int
                            @ObjIDs = @ObjectID
                          , -- nvarchar(4000)
                            @Update_IDOut = @Update_ID OUTPUT
                          , -- int
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , -- int
                            @Debug = 0 -- smallint
				   

                  END
-- reset process running in Context Menu

                  UPDATE    [dbo].[MFContextMenu]
                  SET       [MFContextMenu].[IsProcessRunning] = 0
                  WHERE     [MFContextMenu].[ID] = @ID

-- set custom message to user

                  SET @OutPut = @OutPut + ' Process End Time= ' + CAST(GETDATE() AS VARCHAR(50))

-- logging end of process batch

                  EXEC [dbo].[spMFProcessBatch_Upsert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , -- int
                    @ProcessType = @procedureName
                  , -- nvarchar(50)
                    @LogType = N'Message'
                  , -- nvarchar(50)
                    @LogText = @OutPut
                  , -- nvarchar(4000)
                    @LogStatus = N'Completed'
                  , -- nvarchar(50)
                    @debug = 0 -- tinyint

                  SET @ProcedureStep = 'End custom.DoObjectAction'
                  SET @StartTime = GETDATE()

                  EXEC [dbo].[spMFProcessBatchDetail_Insert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , -- int
                    @LogType = N'Message'
                  , -- nvarchar(50)
                    @LogText = @OutPut
                  , -- nvarchar(4000)
                    @LogStatus = N'Success'
                  , -- nvarchar(50)
                    @StartTime = @StartTime
                  , -- datetime
                    @MFTableName = @MFClassTable
                  , -- nvarchar(128)
                    @Validation_ID = NULL
                  , -- int
                    @ColumnName = NULL
                  , -- nvarchar(128)
                    @ColumnValue = NULL
                  , -- nvarchar(256)
                    @Update_ID = NULL
                  , -- int
                    @LogProcedureName = @procedureName
                  , -- nvarchar(128)
                    @LogProcedureStep = @ProcedureStep
                  , -- nvarchar(128)
                    @debug = 0 -- tinyint
								
-- format message for display in context menu

DECLARE @MessageOUT NVARCHAR(4000),
        @MessageForMFilesOUT NVARCHAR(4000),
        @EMailHTMLBodyOUT NVARCHAR(MAX),
        @RecordCount INT,
        @UserID INT,
        @ClassTableList NVARCHAR(100),
        @MessageTitle NVARCHAR(100);

SET @MessageOut = @OutPut

EXEC [dbo].[spMFResultMessageForUI] @Processbatch_ID = @ProcessBatch_ID, -- int
                                    @Detaillevel = 0,     -- int
                                    @MessageOUT = @MessageOUT OUTPUT,                         -- nvarchar(4000)
                                    @MessageForMFilesOUT = @MessageForMFilesOUT OUTPUT,       -- nvarchar(4000)
                                    @GetEmailContent = 0, -- bit
                                    @EMailHTMLBodyOUT = @EMailHTMLBodyOUT OUTPUT,             -- nvarchar(max)
                                    @RecordCount = @RecordCount OUTPUT,                       -- int
                                    @UserID = @UserID OUTPUT,                                 -- int
                                    @ClassTableList = @ClassTableList OUTPUT,                 -- nvarchar(100)
                                    @MessageTitle = @MessageTitle OUTPUT                      -- nvarchar(100)

			

            END TRY
            BEGIN CATCH
                  SET @OutPut = 'Error:'
                  SET @OutPut = @OutPut + ( SELECT  ERROR_MESSAGE()
                                          )

            END CATCH
      END


GO