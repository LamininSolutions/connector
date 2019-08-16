/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
DELETING OBJECTS

Options include delete or destroy
delete in batch based on process_id

*/

SELECT id, objid, deleted, [Process_ID], *
FROM   [MFCustomer]

UPDATE [MFCustomer]
SET	   [Process_ID] = 10
WHERE  [ID] = 13

--CHECK MFILES BEFORE DELETING TO SHOW DIFF

--to delete
EXEC [spMFDeleteObjectList] 'MFCustomer'
						  , 10
						  , 0

--or

EXEC [spMFDeleteObjectList] @tableName = 'MFCustomer'
						  , @Process_ID = 10
						  , @DeleteWithDestroy = 0

-- to destroy

EXEC [spMFDeleteObjectList] 'MFCustomer'
						  , 10
						  , 1

