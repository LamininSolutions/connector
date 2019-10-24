
declare @update_ID int, @ProcessBatch_ID int, @MFTableName nvarchar(100) = 'MFOtherDocument'

--UPDATE METHODS updatemethod 1
--exec spMFUpdateTable @MFTableName = @MFTableName ,@updatemethod = 1, @update_IDOut = @update_ID output, @ProcessBatch_ID = @ProcessBatch_ID output
--exec spMFUpdateTableWithLastModifiedDate @TableName = 'MFOtherDocument',@updatemethod = 1, @update_IDOut = @update_ID output, @ProcessBatch_ID = @ProcessBatch_ID output
--exec spMFUpdateMFilesToMFSQL @MFTableName = @MFTablename,@updateTypeID = 1, @processBatch_ID = @processBatch_ID output, @update_IDOut = @update_ID output

--UPDATE METHODS update method 0
insert into MFOtherDocument (Name_or_title, process_id)  Values ('Test item',1)
exec spMFUpdateTable @MFTableName = @MFTableName ,@updatemethod = 0, @update_IDOut = @update_ID output, @ProcessBatch_ID = @ProcessBatch_ID output


select @update_ID, @ProcessBatch_ID

--PROCESSBATCH LOGS
select * from MFProcessBatch where ProcessBatch_ID = @ProcessBatch_ID
Select * from MFProcessBatchDetail where ProcessBatch_ID = @ProcessBatch_ID

--ERROR LOG
select * from MFLog where Update_ID = @update_ID

--UPDATE HISTORY LOGS 
Select * from MFUpdateHistory where id = @update_ID
exec spMFUpdateHistoryShow @update_ID = @update_ID, @UpdateColumn = 1 --Data from SQL to M-Files
exec spMFUpdateHistoryShow @update_ID  = @update_ID, @UpdateColumn = 2 --Data From M-Files to SQL
exec spMFUpdateHistoryShow @update_ID  = @update_ID, @UpdateColumn = 3--Object updated in M-Files
exec spMFUpdateHistoryShow @update_ID  = @update_ID, @UpdateColumn = 4 --SyncronisationErrors
exec spMFUpdateHistoryShow @update_ID  = @update_ID, @UpdateColumn = 5 --MFError
exec spMFUpdateHistoryShow @update_ID  = @update_ID, @UpdateColumn = 6 --Deleted Objects
exec spMFUpdateHistoryShow @update_ID  = @update_ID, @UpdateColumn = 7 --New Object from SQL

--TABLE STATS
exec spMFClassTableStats @ClassTableName = @MFTablename

--CLASS TABLE 
select * from MFOtherDocument where Update_ID =  @update_ID
select * from MFOtherDocument where process_ID <> 0


select Process_ID,[Update_ID],RecordCount = count(*)
from [dbo].[MFCustomer]
group by Process_ID,[Update_ID]
order by Process_ID,[Update_ID] desc 
 

