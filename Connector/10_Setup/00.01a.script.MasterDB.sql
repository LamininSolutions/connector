SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
	Purpose: To be executed in Target SQL Server environment before installing any of the following applications 
		MFSQL Connector

	Pre-Req:
		- DOMAIN\ accounts has been created in Active Directory

	Tasks Performed:
		- Create Databases 
		- Set database Mail roles and permissions	
		- Create SQL Server Logins for MFSQL Connector User


*/
USE master


PRINT 'USE [' + DB_NAME() + '] ON [' + @@SERVERNAME + ']'
PRINT REPLICATE('-',80)
/**********************************************************************************
** SCRIPT VARIABLES
*********************************************************************************/
declare @Domain varchar(128) = DEFAULT_DOMAIN();
DECLARE @varAppDB varchar(128) = '{varAppDB}';
DECLARE @varAuthType varchar(10) =  '{varAuthType}' --'Options: SQL | WINDOWS;
DECLARE @varAppLogin_Name varchar(128) = '{varAppLogin_Name}';
DECLARE @varAppLogin_Password varchar(128) = '{varAppLogin_Password}';

SET @varAppLogin_Name = RTRIM('{varAppLogin_Name}')

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
