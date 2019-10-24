
/*
LESSON NOTES

How to create a comment for an abject in SQL and update it into M-Files
Note that comments cannot be deleted.

applies from version 3.1.4.40 

All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

--Step 1: set process_id on the class objects to be included in the comment. Use any process_id excluding 1-4.

SELECT * FROM [dbo].[MFCustomer] AS [mc]

UPDATE [dbo].[MFCustomer]
SET process_id = 5
WHERE id IN (1,3,6,9)

DECLARE @Comment NVARCHAR(100)

SET @Comment = 'Added a comment for illustration '



EXEC [dbo].[spMFAddCommentForObjects]
    @MFTableName = 'MFCustomer',
	@Process_id = 5,
    @Comment = @Comment ,
    @Debug = 0

--Note that the comment is shown in M-Files. 
-- To get comments in SQL use the spmfGetChangeHistory procedure and join with the class table.