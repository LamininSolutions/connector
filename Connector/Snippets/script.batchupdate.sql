

update t
set process_id = 10

from mfLoan t where process_ID = 1

--update t
--set process_id = 0

--from mftenant t where guid is not null

Declare @BatchSize int = 500, @RowCount int = 1, @BatchCounter int = 1, @ProcessBatch_ID int = 0, @UpdateID int

While @RowCount > 0 and @BatchCounter < 201
Begin
update sa
set process_ID = 1 

from mfLoan sa 
inner join (

select top 500 * from mfloan where process_ID  = 10) sa2
on sa.id = sa2.id

select @Rowcount = count(*) from mfloan where process_id = 10


Select @RowCount

exec spmfupdatetable @MFtableName = 'mfLoan',@UpdateMethod = 0, @Update_IDOut = @UpdateID output, @ProcessBatch_ID = @ProcessBatch_ID output
--Update sa3
--Set MFUpdateStatus = 2
Select @BatchCounter as Counter, @UpdateID as UpdateID
--from custom.Staging_Accounts sa3 where MFUpdateStatus = 1

update a
set MFUpdateStatus = 2
from MFLoan t
inner join custom.staging_Loans a
on t.loan_no = a.loan_no
 where t.Update_ID = @UpdateID


set @batchCounter = @BatchCounter + 1

END
