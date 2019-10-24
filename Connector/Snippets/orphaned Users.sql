/*

Resolve orphaned users

*/

EXEC sp_change_users_login @Action='Report';


              USE master 
GO
sp_password @old=NULL, @new='Connector01', @loginame='MFSQLConnect';
GO   


             USE MFSQL@IntownSuites;
GO

sp_change_users_login @Action='update_one', @UserNamePattern='MFSQLConnect', 
   @LoginName='MFSQLConnect';
GO


             USE ScanCapturePurchases
			 GO
             
sp_change_users_login @Action='update_one', @UserNamePattern='MFSQLConnect', 
   @LoginName='MFSQLConnect';
GO

