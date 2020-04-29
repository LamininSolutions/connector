SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
updates
2018-12-11	LC	add grant references to MFSQLConnect to allow user to run metadata sync
2018-12-17	LC	add role for MFSQL_Admin to control Hosted Solution
2018-12-17	LC	add role for reporting
2018-12-17	LC	add Schema for reporting
*/

/**********************************************************************************
** AppDB: DATABASE LEVEL SETTINGS/AUTHENTICATION
**		  
*********************************************************************************/


USE [{varAppDB}]
PRINT 'USE [' + DB_NAME() + '] ON [' + @@SERVERNAME + ']'
PRINT REPLICATE('-',80)
/**********************************************************************************
** SCRIPT VARIABLES
*********************************************************************************/

DECLARE @varAuthType varchar(10) = '{varAuthType}';
DECLARE @varAppLogin_Name varchar(128) = '{varAppLogin_Name}';
DECLARE @varAppDBRole varchar(128) = '{varAppDBRole}';

/*
DECLARE @varAuthType varchar(10) = 'SQL'
DECLARE @varAppLogin_Name varchar(128) = 'MFSQLConnect'
DECLARE @varAppDBRole varchar(128) = 'db_MFSQLConnect'
*/

DECLARE @varAdminRole varchar(128) = 'db_MFSQLAdmin';
DECLARE @varReportRole varchar(128) = 'db_MFSQLReport';


/**********************************************************************************
** CREATE DATABASE ROLE(S)
*********************************************************************************/
BEGIN
DECLARE @dbrole NVARCHAR(50)
SET @dbrole = @varAppDBRole  -- {varAppDBRole}
		
		PRINT 'CREATE DATABASE ROLE [' + @dbrole + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @dbrole AND type = 'R')
		BEGIN
			PRINT SPACE(5) + '    -- adding database role... '
			EXEC ('CREATE ROLE [' + @dbrole +'] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- database role exists. '

			DECLARE @Adminrole NVARCHAR(50)
SET @Adminrole = @varAdminRole  
		
		PRINT 'CREATE DATABASE ROLE [' + @Adminrole + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @Adminrole AND type = 'R')
		BEGIN
			PRINT SPACE(5) + '    -- adding database role... '
			EXEC ('CREATE ROLE [' + @Adminrole +'] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- database role exists. '

DECLARE @Reportrole NVARCHAR(50)
SET @Reportrole = @varReportRole  
		
		PRINT 'CREATE DATABASE ROLE [' + @Reportrole + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @Reportrole AND type = 'R')
		BEGIN
			PRINT SPACE(5) + '    -- adding database role... '
			EXEC ('CREATE ROLE [' + @Reportrole +'] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- database role exists. '

/**********************************************************************************
** CREATE DATABASE PERMISSION
*********************************************************************************/
PRINT 'ADD ROLE TO db_owner: [' + @Adminrole + ']'
EXEC ('ALTER ROLE [db_owner] ADD MEMBER [' + @Adminrole +'] ')
PRINT SPACE(5) + '    -- adding admin role to db-owner... '
			
END

/**********************************************************************************
** CREATE TABLE PERMISSION
*********************************************************************************/

BEGIN

SET @dbrole = @varAppDBRole  -- {varAppDBRole}
		
			PRINT SPACE(5) + '    -- adding create table permission ... '
			EXEC ('GRANT CREATE TABLE TO [' + @dbrole +'] ')

END



/**********************************************************************************
** CREATE DATABASE SCHEMA(S)
*********************************************************************************/
BEGIN
DECLARE @schema NVARCHAR(50)
SET @schema = 'setup'

		PRINT 'CREATE SCHEMA [' + @schema + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name = @schema)
		BEGIN
			PRINT SPACE(5) + '    -- adding schema... '
			EXEC ('CREATE SCHEMA [' + @schema + '] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- schema exists. '

SET @schema = 'ContMenu'

		PRINT 'CREATE SCHEMA [' + @schema + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name = @schema)
		BEGIN
			PRINT SPACE(5) + '    -- adding schema... '
			EXEC ('CREATE SCHEMA [' + @schema + '] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- schema exists. '


SET @schema = 'Custom'

		PRINT 'CREATE SCHEMA [' + @schema + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name = @schema)
		BEGIN
			PRINT SPACE(5) + '    -- adding schema... '
			EXEC ('CREATE SCHEMA [' + @schema + '] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- schema exists. '

SET @schema = 'Report'

		PRINT 'CREATE SCHEMA [' + @schema + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name = @schema)
		BEGIN
			PRINT SPACE(5) + '    -- adding schema... '
			EXEC ('CREATE SCHEMA [' + @schema + '] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- schema exists. '
END

/**********************************************************************************
** APPLY PERMISSIONS TO SCHEMAS
*********************************************************************************/
BEGIN
SET @dbrole = @varAppDBRole  -- {varAppDBRole}

SET @schema = 'dbo'
	PRINT 'APPLY PERMISSIONS ON SCHEMA [' + @schema + '] TO DATABASE ROLE [' + @dbrole + ']'
	PRINT space(5) + '    -- ' + 'GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')

	PRINT space(5) + '    -- ' + 'GRANT ALTER ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT ALTER ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')



SET @schema = 'Setup'
	PRINT 'APPLY PERMISSIONS ON SCHEMA [' + @schema + '] TO DATABASE ROLE [' + @dbrole + ']'
	PRINT space(5) + '    -- ' + 'GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')

SET @schema = 'custom'
	PRINT 'APPLY PERMISSIONS ON SCHEMA [' + @schema + '] TO DATABASE ROLE [' + @dbrole + ']'
	PRINT space(5) + '    -- ' + 'GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')

	PRINT space(5) + '    -- ' + 'GRANT ALTER ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT ALTER ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')


SET @schema = 'ContMenu'
	PRINT 'APPLY PERMISSIONS ON SCHEMA [' + @schema + '] TO DATABASE ROLE [' + @dbrole + ']'
	PRINT space(5) + '    -- ' + 'GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']'
	EXEC('GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')

	SET @schema = 'Report'
	PRINT 'APPLY PERMISSIONS ON SCHEMA [' + @schema + '] TO DATABASE ROLE [' + @dbrole + '],[' + @Reportrole + ']'
	PRINT space(5) + '    -- ' + 'GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']'
	EXEC('GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']'
	EXEC('GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']'
	EXEC('GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']'
	EXEC('GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']')
	
	PRINT space(5) + '    -- ' + 'GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']'
	EXEC('GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + '],[' + @Reportrole + ']')



END
/**********************************************************************************
** CREATE DATABASE USERS & PERMISSIONS
*********************************************************************************/
BEGIN
DECLARE @domain VARCHAR(50) = DEFAULT_DOMAIN()
DECLARE @dbuser NVARCHAR(128)
SET @dbrole = @varAppDBRole
IF @varAuthType = 'SQL'
BEGIN
	SET @dbuser= @varAppLogin_Name -- {varAppWebLogin_Name}

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

		END
		ELSE
			 PRINT space(5) + '    -- login ' + QUOTENAME(@dbuser) + ' does not exist. '

END --IF @varAuthType = 'SQL'
END
