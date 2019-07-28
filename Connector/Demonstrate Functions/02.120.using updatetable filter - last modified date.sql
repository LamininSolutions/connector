/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/
/*

Using update filters WITH MFLastModified date

*/

EXEC [spMFClassTableStats] 'MFCustomer' -- note the lastmodified and mflastmodified dates - it is the Max(date) on the table

--make a change in M-Files to customer


--the following procedures allows you to specify the MFLastModified date as the filter for updating from MF to SQL

GO

DECLARE @Update_IDOut INT,
        @ProcessBatch_ID INT,
		@LastModifiedDate DATETIME;

SELECT @LastModifiedDate = MAX(@LastModifiedDate) FROM [dbo].[MFCustomer] AS [mc]

EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFCustomer',    -- nvarchar(200)
                             @UpdateMethod = 1,   -- int                           
                             @MFModifiedDate = @LastModifiedDate, -- datetime
                             @Update_IDOut = @Update_IDOut OUTPUT,                    -- int
                             @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,             -- int
                             @Debug = 0          -- smallint

SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

GO

--the following procedure has the mfUpdateTable with the last modified date switch built in. It will always reference to max(MFLastModified) date with no need to first define and set it

DECLARE @ReturnDate DATETIME, @ProcessBatch_ID INT, @Update_ID int
EXEC [spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1
										 , @Return_LastModified = @ReturnDate OUTPUT
										 , @TableName = 'MFCustomer'
										 ,@Update_IDOut = @Update_ID output
										 ,@ProcessBatch_ID = @ProcessBatch_ID output
SELECT @ReturnDate

SELECT * FROM [dbo].[MFUpdateHistory] AS [muh] WHERE id = @Update_ID
SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID


