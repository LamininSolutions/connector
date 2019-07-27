select Process_ID,RecordCount = count(*)
from [dbo].[CLARCreditMemoDoc]
group by Process_ID
order by Process_ID

select Process_ID,Mfsql_Process_Batch,RecordCount = count(*)
from [dbo].[CLARCreditMemoDoc]
group by Process_ID,Mfsql_Process_Batch
order by Process_ID,Mfsql_Process_Batch

select Process_ID,Mfsql_Process_Batch,[Update_ID],RecordCount = count(*)
from [dbo].[CLARCreditMemoDoc]
group by Process_ID,Mfsql_Process_Batch,[Update_ID]
order by Process_ID,Mfsql_Process_Batch,[Update_ID]

SELECT * FROM [dbo].[CLARCreditMemoDoc]  WHERE [Mfsql_Process_Batch] = 84





