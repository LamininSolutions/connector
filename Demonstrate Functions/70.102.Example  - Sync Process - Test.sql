/*
Author: LSUSA\ArnieC
Date:	  2017-06-08
Time:	  05:42:35.342
*/
declare @ProcessBatch_ID int

exec [custom].[doARCreditMemoDocMatch] @WriteToMFiles = 1
                                 , @ProcessBatch_ID = @ProcessBatch_ID output

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
