

/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/


/*

THIS PROCEDURE ALLOWS FOR THREE SCENARIOS. 
A) Change the class of an object
b) add adhoc property and value to an object
c) combination of a) and b)

Note that this procedure is targeted to update a single object

As an alternative to changing the class of multiple objects one can also use spmfupdatetable with update method 0 and just reset the class of the objects to be changed.  Note that this method requires refresh of both class tables using updatemethod 1 after the update with updatemethod 0 was performed.

*/



/*
Change the class of an object
this example will change the class of one project customer project to internal project
*/

--create customer project class to work with for the example
exec [dbo].[spMFCreateTable] @ClassName = N'Customer Project' -- nvarchar(128)
                           , @Debug = 0       -- smallint

exec [dbo].[spMFUpdateTable] @MFTableName = N'MFCustomerProject'                                              -- nvarchar(200)
                           , @UpdateMethod = 1                                               -- int
                           
--ensure destination class table exists
SELECT * FROM [dbo].[MFClass] AS [mc]

EXEC spmfcreatetable 'Internal Project'

-- determine objid of object to change
SELECT * FROM [dbo].[MFCustomerProject] AS [mcp]
EXEC spmfupdatetable 'MFCustomerProject',1

--determine MFID of destination class

SELECT * FROM mfclass WHERE TableName = 'MFInternalProject'

--execute procedure to change class for an object
--note in this case there are no required properties in the destination that is not provided, if so the see example on how to add propery values for items to change

EXEC [dbo].[spMFUpdateClassAndProperties]
    @MFTableName = 'MFCustomerProject',
    @ObjectID = 18,
    @NewClassId = 85
	-- @ColumnNames = ?,
	--@ColumnValues = ?,
	--@ProcessBatch_ID = @ProcessBatch_ID2 OUTPUT,
	--@Debug = ?

--Result.  : Item is source table is removed from table, and new item create in destination table.

SELECT * FROM mfCustomerProject WHERE objid = 18
SELECT * FROM mfinternalproject WHERE objid = 18


--setting the properties of the destimation class


/*
Demonstrate adding additional adhoc property in M-Files and updating of selected record
note that the class id is not required if it is not changing

When a class is changed, then the requirement properties for the new class can be added at the same time.

The expectation is that 
a) the column will automatically be added in SQL
b) the column will not be added to the metadata card of objects where the column in SQL is null
*/

GO


--example with changing values for single property (column)
DECLARE @ProcessBatch_ID INT

EXEC [dbo].[spMFUpdateClassAndProperties]
    @MFTableName = 'MFCustomerProject',
    @ObjectID = 29,
--	@NewClassId = null
    @ColumnNames = 'Keywords',
    @ColumnValues = 'this value changed',
	@ProcessBatch_ID = @processBatch_ID OUTPUT,
    @Debug = 0


SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

SELECT * FROM [dbo].[MFCustomerProject] AS [mcp] WHERE [mcp].[ObjID] = 29

	--example with change values for multiple columns, including lookups
	--note that multilookup values are delimited with ;
	--the value pairs between columns and column values are delimited with ,
	--The values of a lookup are the MFID or objid of the related object. the label of the lookup should not be used.

	SELECT objid, * FROM [dbo].[MFCustomer] AS [mc]
GO

DECLARE @ProcessBatch_ID INT

EXEC [dbo].[spMFUpdateClassAndProperties]
    @MFTableName = 'MFCustomerProject',
    @ObjectID = 29,
--	@NewClassId = null
    @ColumnNames = 'Customer_ID,MFSSQL_Message',
    @ColumnValues = '148;138,illustrate multilookup',
	@ProcessBatch_ID = @processBatch_ID OUTPUT,
    @Debug = 0

	
	SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID
	
	SELECT * FROM [dbo].[MFCustomerProject] AS [mcp] WHERE [mcp].[ObjID] = 29


