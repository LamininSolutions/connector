/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
USING UPDATE FILTER 

MXUser_ID

this column is unique to MFSQL Connector to allow you to add a unique identifyer as the SQL user 
that is in control of the record and to restrict update operations to only specific users.
this is particularly useful in environments where the external application have 
multiple users that will update the same class table at the same time. An example would be
customers placing orders.

*/
-- REVIEW THE TABLE STATS 
exec spMFClassTableStats 'MFCustomer'

-- USING AN UPDATE FROM MF TO SQL WITHOUT ANY FILTER
exec spMFUpdateTable MFCustomer,1

-- REVIEW THE TABLE TO INSPECT THE MX_USER_id COLUMN
select * from MFCustomer -- check update_id or version

-- GENERATE A UNIQUE ID FOR TWO USERS AND ADDING IT TO THE RECORD
Declare @JohnID uniqueidentifier
Set @JohnID = NEWID()

Declare @PeteID uniqueidentifier
Set @PeteID = NEWID()

update MFCustomer
set MX_User_ID = @JohnID , process_id = 1, [description] = 'John Update'
where ID in (2,4,6)

update MFCustomer
set MX_User_ID = @PeteID , process_id = 1, [description] = 'Pete Update'
where ID in (1,3,5)

--UPDATE THE RECORDS INTO MF FOR ONLY ONE OF THE USERS
exec spMFUpdateTable 'MFCustomer', 0 , @JohnID
--or
exec spMFUpdateTable @MFTableName = 'MFCustomer', @Updatemethod = 0 , @UserID = @JohnID

/*
Check the records in MF, only the customers with John's id will be updated.
Note that any column with a prefix of MX is ignored when updating M-Files.