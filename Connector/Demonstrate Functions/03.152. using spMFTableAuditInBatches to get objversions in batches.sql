
/*
The following procedure illustrates the use of a procedure to process spMFTableAudit in batches
this is particularly relevant when a large number of objects are in the table and you would like to validate which items must be updated

THIS PROCEDURE IS CURRENTLY UNDER REVIEW - A CHANGE WILL BE PUBLISHED IN THE NEAR FUTURE
*/
--Created on: 2019-04-12 


EXEC [dbo].[spMFTableAuditinBatches] @MFTableName = 'MFCustomer'  -- nvarchar(100)                                  
                                    ,@FromObjid = 1     -- int
                                    ,@ToObjid = 1000    -- int
                                    ,@WithStats = 1    -- bit
                                    ,@Debug = 0        -- int

SELECT * FROM [dbo].[MFAuditHistory] ah
INNER JOIN [dbo].[MFClass] AS [mc]
ON ah.[Class] = mc.mfid


