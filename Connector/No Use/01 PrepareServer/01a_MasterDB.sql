SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
	Purpose: To be executed in customer environment before installing any of the following applications 
		MFSQL Connector

	Pre-Req:
		- DOMAIN\ accounts has been created in Active Directory
		- Review all areas marked with --*** USER VARIABLE to ensure correct values as set for the implementation.

	Tasks Performed:
		- Create Databases 
			- MFSQLConnect_{VaultName}	: MFSQL Connector Database
		
		- Create SQL Server Logins
			- MFSQLConnect			: SQL Login used by MFSQL Connector Vault Application and Management Portal w/SQL Auth.

*/
USE master
PRINT 'USE [' + DB_NAME() + '] ON [' + @@SERVERNAME + ']'
PRINT REPLICATE('-',80)
/**********************************************************************************
** SCRIPT VARIABLES
*********************************************************************************/
--DECLARE @varAppDB varchar(128) = 'MFSQLConnect_ProLaw'			-- {varAppDB}
--DECLARE @varAuthType varchar(10) = 'SQL'							-- {varAuthType} --'Options: SQL | WINDOWS
--DECLARE @varAppLogin_Name varchar(128) = 'MFSQLConnect'		-- {varAppLogin_Name}
--DECLARE @varAppLogin_Password varchar(128) = 'Connector01'		-- {varAppLogin_Password}
--DECLARE @varAppName varchar(128) = 'ProLaw'' MFSQL Connector'-- {varAppName}

DECLARE @varAppDB varchar(128) = '{varAppDB}'
DECLARE @varAuthType varchar(10) =  '{varAuthType}' --'Options: SQL | WINDOWS
DECLARE @varAppLogin_Name varchar(128) = '{varAppLogin_Name}'
DECLARE @varAppLogin_Password varchar(128) = '{varAppLogin_Password}'
DECLARE @varAppName varchar(128) = '{varAppName}'


/**********************************************************************************
** CREATE DATABASES
*********************************************************************************/
BEGIN
PRINT 'CREATE DATABASES ON ' + QUOTENAME(@@SERVERNAME) 
DECLARE @dbName nvarchar(128)

SET @dbName = @varAppDB
	PRINT space(5) + 'CREATE [' + @dbName + '] database for use with MFSQL Connector' 
	IF NOT EXISTS (SELECT name 
					FROM sys.databases
					WHERE name = @dbName
					)
		BEGIN
			PRINT space(5) + '    -- creating database... ' 
			EXEC ('CREATE DATABASE [' + @dbName + ']')
		END
		ELSE
			PRINT space(5) + '    -- database exists. '

END

/**********************************************************************************
** CREATE SQL LOGINS
*********************************************************************************/
BEGIN
PRINT 'CREATE SQL LOGINS ON ' + QUOTENAME(@@SERVERNAME) 
DECLARE @login varchar(50)
DECLARE @domain VARCHAR(50) = DEFAULT_DOMAIN()

SET @login= @varAppLogin_Name

	PRINT space(5) + 'CREATE [' + @Login + '] SQL Login for SQL Authentication' 
	IF NOT EXISTS (SELECT name 
					FROM sys.server_principals
					WHERE name = @login
					)
		BEGIN
			PRINT space(5) + '    -- creating login... ' 
			EXEC ('CREATE LOGIN [' + @login + '] WITH PASSWORD = ''' + @varAppLogin_Password + '''') 
		END
		ELSE
			PRINT space(5) + '    -- login exists. '

			
END


GO
