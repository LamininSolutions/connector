
/*
Processing deleted records in M-Files

*/

--Select an customer in M-Files and make a note of the id from the metadata card

--Review result in SQL 

SELECT objid, [Deleted], [Name_Or_Title], update_id  FROM mfcustomer WHERE [ExternalID] = '152'

--Delete the customer in M-Files

--By default deletions in MF will be removed from SQL 
EXEC spmfupdatetable @MFTableName = 'MFCustomer', @UpdateMethod = 1, @ObjIDs = '152', @debug = 0

SELECT objid, [Deleted], [Name_Or_Title], update_id  FROM mfcustomer WHERE [ExternalID] = '152'


--By default deletions in MF will be removed from SQL - without specifying the objid
EXEC spmfupdatetable @MFTableName = 'MFCustomer', @UpdateMethod = 1,  @debug = 0

SELECT objid, [Deleted], [Name_Or_Title], update_id  FROM mfcustomer WHERE [ExternalID] = '152'



--using the @RetainDeletions = 1 paramters will ensure deletions in MF will be set to Deleted = 1 and retained in SQL
EXEC spmfupdatetable @MFTableName = 'MFCustomer', @UpdateMethod = 1, @ObjIDs = '152', @RetainDeletions = 1, @debug = 0

SELECT objid, [Deleted], [Name_Or_Title], update_id  FROM mfcustomer WHERE [ExternalID] = '152'

-- USE the FOLLOWING procedure to show the entries in the updatehistory log.  The update_id is shown on the class table.
 
DECLARE @UpdateID SMALLINT
SET @updateID = 126

SELECT * FROM [dbo].[MFUpdateHistory] AS [muh] WHERE id > @UpdateID

EXEC [dbo].[spMFUpdateHistoryShow] @Update_ID = @UpdateID,    -- int
                                   @IsSummary = 1,    -- smallint
                                   @UpdateColumn = 0, -- int
                                   @Debug = 0         -- smallint


EXEC [dbo].[spMFUpdateHistoryShow] @Update_ID = @UpdateID,    -- int
                                   @IsSummary = 0,    -- smallint
                                   @UpdateColumn = 3, -- int
                                   @Debug = 0         -- smallint


EXEC [dbo].[spMFUpdateHistoryShow] @Update_ID = @UpdateID,    -- int
                                   @IsSummary = 0,    -- smallint
                                   @UpdateColumn = 6, -- int
                                   @Debug = 0         -- smallint
								   
	