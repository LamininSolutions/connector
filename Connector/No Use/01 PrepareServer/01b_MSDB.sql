SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/**********************************************************************************
** msdb: DATABASE LEVEL SETTINGS/AUTHENTICATION
**		 ALLOW FOR SENDING OF DBMAIL BY APPLICATION USER(s)
*********************************************************************************/
USE msdb 
PRINT 'USE [' + DB_NAME() + '] ON [' + @@SERVERNAME + ']'
PRINT REPLICATE('-',80)
/**********************************************************************************
** SCRIPT VARIABLES
*********************************************************************************/
--DECLARE @varAuthType varchar(10) = 'SQL'					-- {varAuthType} --'Options: SQL | WINDOWS
--DECLARE @varAppLogin_Name varchar(128) = 'MFSQLConnect'		-- {varAppLogin_Name}
--DECLARE @varAppDBRole varchar(128) = 'db_MFSQLConnect'		-- {varAppDBRole}

DECLARE @varAuthType varchar(10) = '{varAuthType}'
DECLARE @varAppLogin_Name varchar(128) = '{varAppLogin_Name}'
DECLARE @varAppDBRole varchar(128) = '{varAppDBRole}'

/**********************************************************************************
** CREATE DATABASE ROLE(S)
*********************************************************************************/
DECLARE @dbrole NVARCHAR(50)
SET @dbrole = @varAppDBRole
		
		PRINT 'CREATE DATABASE ROLE [' + @dbrole + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @dbrole AND type = 'R')
		BEGIN
			PRINT SPACE(5) + '    -- adding database role... '
			EXEC ('CREATE ROLE [' + @dbrole +'] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- database role exists. '


	PRINT 'APPLY PERMISSIONS ON ROLE [' + @dbrole + ']'
		EXEC('GRANT SELECT ON [dbo].[sysmail_profile] TO [' + @dbrole + ']')
		EXEC('GRANT SELECT ON [dbo].[sysmail_account] TO [' + @dbrole + ']')
		EXEC('GRANT SELECT ON [dbo].[sysmail_profileaccount] TO [' + @dbrole + ']')
		EXEC('GRANT EXECUTE ON [dbo].[sp_send_dbmail] TO [' + @dbrole + ']')

/**********************************************************************************
** CREATE DATABASE USERS & PERMISSIONS
*********************************************************************************/
DECLARE @domain VARCHAR(50) = DEFAULT_DOMAIN()
DECLARE @dbuser NVARCHAR(128)
SET @dbuser= @varAppLogin_Name 

	PRINT 'CREATE DATABASE USER [' + @dbuser + ']'
	IF EXISTS (SELECT name 
					FROM master.sys.server_principals
					WHERE name = @dbuser
					)
		BEGIN
			IF NOT EXISTS (SELECT name
							FROM sys.database_principals
							WHERE name = @dbuser
							AND [type_desc] = 'SQL_USER'
							)
				BEGIN
					PRINT space(5) + '    -- creating user in [' + db_name() + '] database... '
					EXEC ('CREATE USER [' + @dbuser + ']')
				END
				ELSE
					PRINT space(5) + '    -- user exists in [' + db_name() + '] database. '

				IF isnull(IS_ROLEMEMBER(@dbrole,@dbuser),0) = 0
				BEGIN
						PRINT space(5) + '    -- adding to [' + @dbrole + '] database role... '
						EXEC sp_addrolemember @dbrole, @dbuser
				END
				ELSE
						PRINT space(5) + '    -- is member of [' + @dbrole + '] database role. '


		SET @dbrole = 'DatabaseMailUserRole'
				IF isnull(IS_ROLEMEMBER(@dbrole,@dbuser),0) = 0
				BEGIN
						PRINT space(5) + '    -- adding to [' + @dbrole + '] database role... '
						EXEC sp_addrolemember @dbrole, @dbuser
				END
				ELSE
						PRINT space(5) + '    -- is member of [' + @dbrole + '] database role. '

		END
		ELSE
			 PRINT space(5) + '    -- login ' + QUOTENAME(@dbuser) + ' does not exist. '
GO


