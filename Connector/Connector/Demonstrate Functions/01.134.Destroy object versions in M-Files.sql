
/*

Delete object versions

To delete an object version the objid and the version to delete is required.
User spMFGetHistory to get the valid versions of an object
Then use spMFDeleteObject to destroy the specific version

The destroy multiple versions of multiple object one would use a loop

The latest version of the object cannot be destroyed on its own.

*/
--Created on: 2019-08-18 

SELECT * FROM [dbo].[MFClass] AS [mc]
SELECT [mcoa].[MFVersion], [mcoa].[ObjID], [mcoa].[Name_Or_Title] FROM [dbo].[MFCustomer] AS [mcoa]

EXEC spmfupdatetable 'MFCustomer',1

-------------------------------------------------------------
-- get version history
-------------------------------------------------------------

UPDATE Mcoa
SET [mcoa].[Process_ID] = 5
FROM [dbo].[MFCustomer] AS [mcoa]
WHERE [mcoa].[ObjID] = 134

DECLARE @Update_ID       INT
       ,@ProcessBatch_id INT;

EXEC [dbo].[spMFGetHistory] @MFTableName = 'MFCustomer'   -- nvarchar(128)
                           ,@Process_id = 5    -- int
                           ,@ColumnNames = 'MF_Last_modified'   -- nvarchar(4000)
                           ,@IsFullHistory = 1 -- bit
                           ,@NumberOFDays = null  -- int
                           ,@StartDate = null     -- datetime
                           ,@Update_ID = @Update_ID OUTPUT                         -- int
                           ,@ProcessBatch_id = @ProcessBatch_id OUTPUT             -- int
                           ,@Debug = 0        -- int

SELECT * FROM [dbo].[MFObjectChangeHistory] AS [moch] WHERE [moch].[ObjID] = 134

-------------------------------------------------------------
-- Delete a specific version
-------------------------------------------------------------

  /* Return values
1	Success object deleted
2	Success object version destroyed
3	Success object  destroyed
4	 Failure object does not exist
5	Failure object version does not exist
6	Failure destroy latest object version not allowed
*/

GO

DECLARE @Output NVARCHAR(2000);
DECLARE @processBatch_ID INT;
DECLARE @Return_Value int

EXEC  @Return_Value = [dbo].[spMFDeleteObject] @ObjectTypeId = 136      -- int
                             ,@objectId = 134          -- int
                             ,@Output = @Output OUTPUT                                   -- nvarchar(2000)
                             ,@ObjectVersion = 9     -- set to specific version to destroy
                             ,@DeleteWithDestroy = 1 -- object version history is always destroy
							 ,@ProcessBatch_id = @processBatch_ID OUTPUT
                             
SELECT @Return_Value

SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

