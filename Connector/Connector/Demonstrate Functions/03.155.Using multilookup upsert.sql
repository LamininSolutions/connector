


/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/



/*
Using Mulitlookup upsert to modify of delete items in a multi lookup scenario
*/

/*
create contacts if not already done
*/

exec [dbo].[spMFCreateTable] @ClassName = N'Contact Person' -- nvarchar(128)
                           , @Debug = 0       -- smallint

						   exec [dbo].[spMFUpdateTable] @MFTableName = N'MFContactPerson'                                              -- nvarchar(200)
						                              , @UpdateMethod = 1


-- to add items to the list use updateflag = 1
select [dbo].[fnMFMultiLookupUpsert]('12,456,34','6,12',1)

--example of usage to add all the contacts for customer to the customer project 
declare @NewContact_ID int

update mcp
set [mcp].[Contact_Person_ID] = [dbo].[fnMFMultiLookupUpsert]([mcp].[Contact_Person_ID],cast(mcp2.[ObjID] as varchar(10)),1), process_ID = 1
--select *
from [dbo].[MFCustomerProject] as [mcp]
cross apply [dbo].[fnMFSplitString](customer_ID,',') as [fmss]
left join [dbo].[MFContactPerson] as [mcp2]
on fmss.[Item] = mcp2.[Owner_Customer_ID]
where mcp.[Project_Manager_ID] is not null

--check before update
select * from [dbo].[MFCustomerProject] as [mcp] where [mcp].[Process_ID] = 1

--update to MF
declare @PROCESSBATCH_id INT
exec [dbo].[spMFUpdateTable] @MFTableName = N'MFCustomerProject'                                              -- nvarchar(200)
                           , @UpdateMethod = 0 
						   ,@ProcessBatch_ID = @PROCESSBATCH_id output
						   ,@debug = 0
						   				   
						   SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

--Check result						                   
select * from [dbo].[MFCustomerProject] as [mcp]


--to delete an item from the list use updateflag = -1
select [dbo].[fnMFMultiLookupUpsert]('12,456,34','34',-1)



