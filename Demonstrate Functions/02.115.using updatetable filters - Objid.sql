/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
Using Update Filters - ID's
 

*/
--THE DEFAULT UPDATE METHOD

	DECLARE @RC INT
	DECLARE @MFTableName NVARCHAR(128) = 'MFCustomer'
	DECLARE @UpdateMethod INT = 1 -- 1 = from MF to SQL; 0 = SQL to MF
	DECLARE @UserId NVARCHAR(200) = null-- filter based on thirdparty app user id
	DECLARE @MFModifiedDate DATETIME = NULL -- filter to update only from this date
	DECLARE @ObjIDs NVARCHAR(4000) = NULL -- filter to update only specific objects
	DECLARE @Update_IDOut INT
	DECLARE @ProcessBatch_ID INT
	DECLARE @SyncErrorFlag int = NULL -- set by calling procedure for syncronisation errors
	DECLARE @Debug SMALLINT

-- TODO: Set parameter values here.
	

	EXEC @RC = [dbo].[spMFUpdateTable] @MFTableName = @MFTableName                          
	                            ,@UpdateMethod =  @UpdateMethod                          
	                            ,@UserId = @UserId                              
	                            ,@MFModifiedDate = @MFModifiedDate     
	                            ,@ObjIDs = @ObjIDs                               
	                            ,@Update_IDOut = @Update_IDOut OUTPUT       
	                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT 
	                            ,@SyncErrorFlag = @SyncErrorFlag                    
	                            ,@Debug = 0                                  

SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID
	
	GO

--SHOW RECORDS

	SELECT *
	FROM   [MFCustomer]

--ALTERNATE BETWEEN DIFFERENT EXEC STATEMENTS BY UNCOMMENTING A STATEMENT

--EXEC FROM
	DECLARE @ProcessBatch_ID INT
		  , @Update_ID INT
		  , @MFTablename NVARCHAR(100) = 'MFCustomer'
		  , @LastModified DATETIME

	exec spMFUpdateTable @MFTableName = @MFTablename ,@updatemethod = 1, @objIds = '158,137', @processBatch_ID = @ProcessBatch_ID output, @Update_IDOut = @Update_ID output
--	EXEC [spMFUpdateTable] @MFTableName = @MFTablename , @updatemethod = 1, @processBatch_ID = @ProcessBatch_ID OUTPUT, @Update_IDOut = @Update_ID OUTPUT
	--exec spMFUpdateMFilesToMFSQL @MFTableName = @MFTablename,@updateTypeID = 1, @processBatch_ID = @processBatch_ID output, @update_IDOut = @update_ID output, @Debug = 0 --Incremental
	--exec spMFUpdateMFilesToMFSQL @MFTableName = @MFTablename,@updateTypeID = 0, @processBatch_ID = @processBatch_ID output, @update_IDOut = @update_ID output, @Debug = 0 -- Full refresh
	--exec spMFUpdateTableWithLastModifiedDate @UpdateMethod = 1, @Return_LastModified = @LastModified output, @TableName = @MFTablename, @processBatch_ID = @processBatch_ID output, @update_IDOut = @update_ID output, @Debug = 0


	SELECT *
	FROM   [MFProcessBatch]
	WHERE  [ProcessBatch_ID] = @ProcessBatch_ID

	SELECT *
	FROM   [MFProcessBatchDetail]
	WHERE  [ProcessBatch_ID] = @ProcessBatch_ID

--SHOW ERROR LOG IF ANY
	SELECT *
	FROM   [MFLog]
	WHERE  [Update_ID] = @Update_ID

--SHOW UPDATE HISTORY LOGS 
	SELECT *
	FROM   [MFUpdateHistory]
	WHERE  [id] = @Update_ID
	EXEC [spMFUpdateHistoryShow] @update_ID = @Update_ID
							   , @isSummary = 1
							   , @UpdateColumn = 1 --Data from SQL to M-Files

	EXEC [spMFUpdateHistoryShow] @update_ID = @Update_ID
							   , @isSummary = 0
							   , @UpdateColumn = 7 --Object updated in M-Files

	EXEC [spMFUpdateHistoryShow] @update_ID = @Update_ID
							   , @isSummary = 0
							   , @UpdateColumn = 3 --Data From M-Files to SQL

--SHOW TABLE STATS

	EXEC [spMFClassTableStats] @ClassTableName = 'MFCustomer'

--EXEC TO

