USE [msdb]
GO

sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Database Mail XPs', 1;  
GO  
RECONFIGURE  
GO  


-- Create a Database Mail account
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'MFSQL Connector',
    @description = 'Mail account for MFSQL Connector notifications.',
    @email_address = 'NoReply@lamininsolutions.com',
    @replyto_address = 'support@lamininsolutions.com',
    @display_name = 'MFSQL Connector notification',
    @mailserver_name = 'smtp.office365.com' ,
	@port =  587,
	@username = 'NoReply@lamininsolutions.com',
	 @password = 'v5R&onCYMKO6Vf',
	 @enable_ssl = 1
	;

-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'MFAccounting' ,
    @description = 'Profile used for EpicorConnector.' 
	;

	EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @principal_name = 'MFSQLConnect',
    @profile_name = 'MFAccounting',
    @is_default = 1 ;

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'MFAccounting' ,
    @account_name = 'MFSQL Connector',
    @sequence_number =1 ;

