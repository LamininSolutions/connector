/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
learn how to use all the dfferent methods of synchronizing metadata
The following procedure all operations on ALL the class tables 

Creata all class tables
drop all class tables
update all class tables

*/
--CHECK THE LIST OF CLASS TABLE
	SELECT *
	FROM   [MFClass]

--if list is empty then perform first syncrononization
	EXEC [spMFSynchronizeMetadata]

--SET TO INCLUED IN APP TO ANY VALUE (NOTE 1, AND 2 ARE RESERVED). 2 SHOULD ONLY BE USED FOR CLASSES WHERE TRANSACTION UPDATE IS REQUIRED

--this is only necessary of you want to perform bulk operations on a subset of class tables
	UPDATE [MFClass]
	SET	   [IncludeInApp] = 3
	WHERE  [ID] IN ( 418, 420, 422 )

--SHOW QUICK STATS ON ALL THE TABLES
	EXEC [spMFClassTableStats] -- list all class tables, show only tables that has already been created

--SHOW THE STATS FOR A SINGLE TABLE
	EXEC [spMFClassTableStats] 'MFCustomer'

--CREATE ALL CLASS TABLES WITH INCLUDED IN APP 1 OR 2 IN ONE GO
	EXEC [spMFCreateAllMFTables]

-- create some more
	UPDATE [MFClass]
	SET	   [IncludeInApp] = 3
	WHERE  [MFID] IN (14, 85 )


--UPDATE RECORDS FOR ALL CLASS TABLED WITH INCLUDEINAPP = 1
	EXEC [spMFUpdateAllncludedInAppTables] 1
--or
	EXEC [spMFUpdateAllncludedInAppTables] @UpdateMethod = 1 

--DROP ALL CLASS TABLES WITH A SPECIFIC INCLUDED IN APP
	EXEC [spMFDropAllClassTables] 1 -- does not reset included in app to allow for recreation
--or
	EXEC [spMFDropAllClassTables] @IncludeinApp = 1



