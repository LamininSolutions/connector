

/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
When there is a need for performing updates into MF a record at a time then the following
procedure can be used.  This is only used in exceptional cases where complex update issues need to be resolved
*/
TRUNCATE TABLE [dbo].[MFOtherDocument]

Declare @SessionID int
exec spMFUpdateItemByItem @TableName = 'MFOtherDocument', @SessionIDOut = @SessionID output
Select @SessionID

--SHOW THE STATUS OF EACH OBJECT IN THE TABLE AUDIT HISTORY
select * from MFAuditHistory where SessionID = @SessionID

/*
Note from the listing if any objects are shown as status flag 5.  This implies that these objects could not be pulled through from M-Files and require further investigation. Note that there are two reasons why there could 
a items shown in status flag 5. a) it is a template b) it is document collection. In both cases these type of 
objects are ignored when updating from M-Files to SQL. 
*/
