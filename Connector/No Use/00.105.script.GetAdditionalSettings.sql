use {varAppDB}
Go

if exists(
select NAME from SYS.objects WHERE TYPE = 'U' AND NAME = 'MFSettings')
BEGIN

Select 


[EDIT_ITSUPPORTEMAIL_PROP] = (
SELECT  CONVERT(nvarchar(128),[ms].[Value] )
	  FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'SupportEmailRecipient' AND source_key	= 'Email'
)
,[EDIT_MAILPROFILE_PROP] = (
SELECT CONVERT(nvarchar(128),[ms].[Value] )
	  FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'SupportEMailProfile' AND source_key	= 'Email'
)
,[CHECKBOX_LOGGINGREQUIRED_PROP] = (
SELECT  CONVERT(nvarchar(128),[ms].[Value] )
	  FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'App_DetailLogging' AND source_key	= 'App_Default'
),EDIT_SQL_IMPORTFOLDER = (
SELECT  CONVERT(nvarchar(128),[ms].[Value] )
	  FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'FileTransferLocation' AND source_key	= 'Files_Default'
),EDIT_SQL_EXPORTFOLDER = (
SELECT  CONVERT(nvarchar(128),[ms].[Value] )
	  FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'RootFolder' AND source_key	= 'Files_Default' )


	  END
	  Else
	  Begin
	  Select 
 
         N'Support@lamininsolutions.com'  as EDIT_ITSUPPORTEMAIL_PROP 
		, N'MailProfile'  as EDIT_MAILPROFILE_PROP 
        , N'0'  as CHECKBOX_LOGGINGREQUIRED_PROP 
		,'' AS EDIT_SQL_IMPORTFOLDER 
		,'' AS EDIT_SQL_EXPORTFOLDER

end

GO
