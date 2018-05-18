
/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
To work through the examples, select the statement as execute (F5)
*/

/*
GETTING STARTED
check connector
synchronize metadata
create first class table
update first class table
*/

-- CHECK VAULT SETTINGS
Select * from mfvaultsettings

--IF MANUAL INSTALL of vault setting THEN SET VAULT ACCESS PASSWORD - check out example script 01.101 Update Settings for more.

EXEC spmfsettingsForVaultUpdate @Password = 'MotSys123'

-- CHECK CONNECTION TO VAULT
EXEC [spMFVaultConnectionTest]

--CHECK GENERAL SETTINGS
sELECT * from mfsettings

-- Before one can start to use the connector, it is necessary to pull the Metadata structure into SQL
-- If you cannot start the sync process it is likely that the installation of the vault applications have not been completed.  From Release 4 this operation is dependent on a valid license.

--SYNCHRONISE METADATA
	EXEC [spMFSynchronizeMetadata]

--if error shown, then it would send email. if database mail not setup, then check error with the following 

SELECT * FROM mflog ORDER BY logid DESC


--During the development process, or any time after the initial build use the following to update the structure.  Note that this procedure is illustrated again in a next example

	EXEC [dbo].[spMFDropAndUpdateMetadata]
	    @IsReset = 0 -- Setting this to 0 will update the metadata structure without resetting all the custom settings in SQL	    
	
--when you want to drop all metadata in SQL then use

	EXEC [dbo].[spMFDropAndUpdateMetadata]
	    @IsReset = 1 --setting to 1 will delete all the current structure data in SQL and rest it to M-Files	    
	
--CHECK STRUCTURE TABLES.  Explore the results.

	SELECT *
	FROM   [MFClass] 

	SELECT *
	FROM   [MFProperty] ORDER BY MFID

	SELECT *
	FROM   [MFValueListItems]

--other structure tables: MFObjectType, MFValuelist, MFworkflow, MFWorkflowstate, MFLoginAccount, MFUserAccount

--explore metadata using a view

--review all the properties for a specific class
	SELECT *
	FROM   [MFvwMetadataStructure]
	WHERE  [class] = 'Customer' ORDER BY Property_MFID

--review all the classes for a specific property
	SELECT class,*
	FROM   [MFvwMetadataStructure]
	WHERE  [Property] = 'Customer' ORDER BY class_MFID

--To get metadata from M-Files in SQL, it is necessary to create the class tables first.

--CREATE CLASS TABLE
		EXEC [spMFCreateTable] 'Customer'
		--or
		EXEC [spMFCreateTable] @className = 'Customer'

--CHECK THE CLASS TABLE. Note that is was created, but has no records
	SELECT *
	FROM   [MFCustomer]

--CHECK THE CHANGE IN MFCLASS. The 'includeinApp' column was automatically set to 1

SELECT * FROM [dbo].[MFClass] AS [mc]

--UPDATE RECORDS IN CLASS TABLE
	EXEC [spMFUpdateTable] 'MFCustomer'
						 , 1
--or
	EXEC [spMFUpdateTable] @MFTableName = 'MFCustomer'
						 , @UpdateMethod = 1
						 , @debug = 0

--Check the table again.  Note all the special columns created, and how the Connector handles the lookup properties (e.g. country)

SELECT * FROM mfcustomer

