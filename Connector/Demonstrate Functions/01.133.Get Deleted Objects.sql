
/*


illustrate get deleted objects
*/
--Created on: 2019-07-04 

DECLARE @ProcessBatch_ID INT;

EXEC [dbo].[spMFGetDeletedObjects] @MFTableName = 'MFLarge_Volume'      -- nvarchar(200)
                                  ,@LastModifiedDate = null -- datetime
                                  ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT                -- int
                                  ,@Debug = 101          -- smallint


