/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/


/*
Demonstrate adding additional adhoc property in M-Files and updating of records
The expectation is that 
a) the column will automatically be added in SQL
b) the column will not be added to the metadata card of objects where the column in SQL is null
*/

--create table if not exist
EXEC spmfcreatetable 'Customer Project'
SELECT * FROM mfCustomerproject

--add an adhoc property 'description' to one of the projects in M-Files and add information in the property

--update record in SQL
EXEC spmfupdatetable 'MFCustomerProject', 1

--change one of the other projects in SQL with adding some data in the description column
UPDATE cp
SET process_id = 1, Description = 'This is a new customer project'
FROM mfcustomerProject cp WHERE id = 1


EXEC spmfupdatetable 'MFCustomerProject', 0

-- check m-files and review add hoc properties on class

-- add new value
UPDATE cp
SET process_id = 1, Description = 'this is a new value'
FROM mfcustomerProject cp WHERE id = 1

EXEC spmfupdatetable 'MFCustomerProject', 0
-- check m-files and review add hoc properties on class, description should only appear on the item updated.

--set the property to null
UPDATE cp
SET process_id = 1, Description = null
FROM mfcustomerProject cp WHERE id = 1
EXEC spmfupdatetable 'MFCustomerProject', 0
-- check m-files and review add hoc property on object, it should be removed

--change one of the other projects in SQL that does not include description
UPDATE cp
SET process_id = 1, In_Progress = 0
FROM mfcustomerProject cp WHERE id = 6

EXEC spmfupdatetable 'MFCustomerProject', 0
--the adhoc property is not added to object


SELECT * FROM mfcustomerproject WHERE id = 6

--removing all data in adhoc property columns

UPDATE cp
SET process_id = 1
FROM MFCustomerProject cp WHERE description IS NOT NULL

EXEC spmfupdatetable 'MFCustomerProject', 0

EXEC [dbo].[spMFDeleteAdhocProperty]
	@MFTableName = N'MFCustomerProject'	-- nvarchar(128)
  , @columnNames = N'Description'	-- nvarchar(200)
  , @process_ID = 1		-- smallint
  , @Debug = 0			-- smallint

SELECT * FROM mfcustomerproject

-- column is removed and property is removed from all objects in MF
ALTER TABLE mfcustomerproject
ADD [Description] NVARCHAR(100)
UPDATE cp
SET process_id = 0
FROM MFCustomerProject cp WHERE description IS NULL

EXEC [dbo].[spMFDeleteAdhocProperty]
	@MFTableName = N'MFCustomerProject'	-- nvarchar(128)
  , @columnNames = N'Description'	-- nvarchar(200)
  , @process_ID = 0	-- smallint
  , @Debug = 0			-- smallint