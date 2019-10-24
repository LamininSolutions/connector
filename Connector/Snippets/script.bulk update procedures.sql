
/*

*/
--Created on: 2019-06-13 

--TABLE AUDIT

DECLARE @SessionIDOut    INT
       ,@NewObjectXml    NVARCHAR(MAX)
       ,@DeletedInSQL    INT
       ,@UpdateRequired  BIT
       ,@OutofSync       INT
       ,@ProcessErrors   INT
       ,@ProcessBatch_ID INT
	   ,@MFModifiedDate DATETIME;

SELECT  @MFModifiedDate = MAX([mah].[TranDate]) FROM [dbo].[MFAuditHistory] AS [mah]
WHERE class = 94

SELECT @MFModifiedDate = ISNULL(@MFModifiedDate,'2000-01-01')

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFBasic_SingleProp'    -- nvarchar(128)
                           ,@MFModifiedDate = null -- datetime
                           ,@ObjIDs = null         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 101        -- smallint

SELECT @SessionIDOut
SELECT CAST(@NewObjectXml AS xml)

DECLARE @Update_IDOut     INT
       ,@ProcessBatch_ID1 INT;

GO



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

SELECT @MFModifiedDate = MAX([mlv].[MF_Last_Modified]) FROM [dbo].[MFLarge_volume] AS [mlv]

SELECT @MFModifiedDate = ISNULL(@MFModifiedDate,'2000-01-01')

EXEC [dbo].[spMFTableAudit] @MFTableName = 'MFLarge_Volume'    -- nvarchar(128)
                      --     ,@MFModifiedDate = @MFModifiedDate -- datetime
                       --    ,@ObjIDs = ?         -- nvarchar(4000)
                           ,@SessionIDOut = @SessionIDOut OUTPUT                    -- int
                           ,@NewObjectXml = @NewObjectXml OUTPUT                    -- nvarchar(max)
                           ,@DeletedInSQL = @DeletedInSQL OUTPUT                    -- int
                           ,@UpdateRequired = @UpdateRequired OUTPUT                -- bit
                           ,@OutofSync = @OutofSync OUTPUT                          -- int
                           ,@ProcessErrors = @ProcessErrors OUTPUT                  -- int
                           ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                           ,@Debug = 0        -- smallint	         
						   
						   
GO



--UPDATE TABLE STANDARD


EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFBasic_SingleProp'     -- nvarchar(200)
                            ,@UpdateMethod = 1    -- int
                       
                        --    ,@ObjIDs = '80184,80313'         -- nvarchar(max)
                            ,@Update_IDOut = @Update_IDOut OUTPUT                     -- int
                            ,@ProcessBatch_ID = @ProcessBatch_ID1 OUTPUT              -- int
  ;

  GO

EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFLarge_Volume' -- nvarchar(200)
                            ,@UpdateMethod = 1               -- int                       
                            ,@ObjIDs = '80184,80313'         -- nvarchar(max)
                        
  ;

  GO


DECLARE @Return_LastModified DATETIME
       ,@Update_IDOut1       INT
       ,@ProcessBatch_ID2    INT;


	   --UDPATE TABLE MODIFIED DATE

EXEC [dbo].[spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1 -- int
                                                ,@Return_LastModified = @Return_LastModified OUTPUT    -- datetime
                                                ,@TableName = 'MFBasic_SingleProp'    -- sysname
                                                ,@Update_IDOut = @Update_IDOut1 OUTPUT                 -- int
                                                ,@ProcessBatch_ID = @ProcessBatch_ID2 OUTPUT           -- int
                                                ,@debug = 0       -- smallint
  
  GO
DECLARE @Return_LastModified DATETIME
       ,@Update_IDOut        INT
       ,@ProcessBatch_ID1    INT;

EXEC [dbo].[spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1                                  -- int
                                                ,@Return_LastModified = @Return_LastModified OUTPUT -- datetime
                                                ,@TableName = 'MFLarge_Volume'                      -- sysname
                                                ,@Update_IDOut = @Update_IDOut OUTPUT               -- int
                                                ,@ProcessBatch_ID = @ProcessBatch_ID1 OUTPUT        -- int
                                                ,@debug = 0;                                        -- smallint
GO
  -- UPDATE TABLE MF TO SQL
 
 DECLARE @MFLastUpdateDate SMALLDATETIME
        ,@Update_IDOut2    INT
        ,@ProcessBatch_ID  INT;
 
 EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'MFCustomer'  -- nvarchar(128)
                                     ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT          -- smalldatetime
                                     ,@UpdateTypeID = 1 -- tinyint
                                     ,@Update_IDOut = @Update_IDOut2 OUTPUT                 -- int
                                     ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT            -- int
                                     ,@debug = 0     -- tinyint
 

 GO

  DECLARE @MFLastUpdateDate SMALLDATETIME
        ,@Update_IDOut2    INT
        ,@ProcessBatch_ID  INT;
 
 EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'MFLarge_Volume'  -- nvarchar(128)
                                     ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT          -- smalldatetime
                                     ,@UpdateTypeID = 1 -- tinyint
                                     ,@Update_IDOut = @Update_IDOut2 OUTPUT                 -- int
                                     ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT            -- int
                                     ,@debug = 0     -- tinyint
 

 GO
 -- BULK UPDATE
 
EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = 'MFLarge_volume' -- nvarchar(100)
                                    ,@FromObjid = 1  -- int
                                    ,@ToObjid = 1000     -- int
                                    ,@WithStats = 1   -- bit
                                    ,@Debug = 1      -- int
	  
						   
                                                
DECLARE @MFLastUpdateDate SMALLDATETIME
       ,@Update_IDOut1    INT
       ,@ProcessBatch_ID  INT;

EXEC [dbo].[spMFUpdateMFilesToMFSQL] @MFTableName = 'MFLarge_Volume'  -- nvarchar(128)
                                    ,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT          -- smalldatetime
                                    ,@UpdateTypeID = 1 -- tinyint
                                    ,@Update_IDOut = @Update_IDOut1 OUTPUT                 -- int
                                    ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT            -- int
                                    ,@debug = 0        -- tinyint

go



SELECT * FROM [dbo].[MFClass] AS [mc]

EXEC [dbo].[spMFUpdateTableinBatches] @MFTableName = 'MFBasic_SingleProp'  -- nvarchar(100)
                                     ,@UpdateMethod = 0 -- int
									,@WithTableAudit = 0
									,@FromObjid = 1
                                     ,@ToObjid = 10    -- int
                                     ,@WithStats = 1   -- bit
                                     ,@Debug = 101      -- int

									 GO

                                     

