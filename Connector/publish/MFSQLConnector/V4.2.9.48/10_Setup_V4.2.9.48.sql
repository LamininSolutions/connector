

/*
THIS SCRIPT HAS BEEN PREPARE TO ALLOW FOR THE AUTOMATION OF ALL THE INSTALLATION VARIABLES

2017-3-24-7h30
2018-1-22

*/

/*

Installer variable				Description
{varAppDB}						DatabaseName (new or existing)
{varAuthType}					Options: SQL or WINDOWS
#{varAppLogin_Name}#			LoginName (e.g. MFSQLConnect)
{varAppLogin_Password}			Password (e.g. Connector)
{varAppDBRole}					AppDBRole (e.g. db_MFSQLConnect)				
{varEmailProfile}				Default email profile
{varMFUsername}					M-FilesUserName 
{varMFPassword}					Password
{varNetworkAddress}				VaultNetworkAddress
{varVaultName}					VaultName
{varProtocolType}				MF Connection protocol
{varEndpoint}					MF Connection port
{varAuthenticationType}			MF Connection Authentication Type
{varMFDomain}					MF AD Domain
{varGUID}						Vault Guid
{varWebURL}						Web URL
{varITSupportEmail}				Support email address
{varLoggingRequired}			Detail logging enabled
{varMFInstallPath}				M-Files Installation Path
{varMFVersion}					M-Files Version
{varCLRPath}					CLR Path
{varExportFolder}				Export folder Path
{varImportFolder}				Import Folder Path


C:\Program Files\M-Files

*/
GO
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
USE msdb 

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-------------------------------------------------------------
-- Configure Database Mail if not set
-------------------------------------------------------------


-------------------------------------------------------------
-- Enable database mail
-------------------------------------------------------------


sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Database Mail XPs', 1;  
GO  
RECONFIGURE  
GO  






/**********************************************************************************
** msdb: DATABASE LEVEL SETTINGS/AUTHENTICATION
**		 ALLOW FOR SENDING OF DBMAIL BY APPLICATION USER(s)
*********************************************************************************/

PRINT 'USE [' + DB_NAME() + '] ON [' + @@SERVERNAME + ']'
PRINT REPLICATE('-',80)
/**********************************************************************************
** SCRIPT VARIABLES
*********************************************************************************/
DECLARE @varAuthType varchar(10) = '{varAuthType}'
DECLARE @varAppLogin_Name varchar(128) = '{varAppLogin_Name}'
DECLARE @varAppDBRole varchar(128) = '{varAppDBRole}'
declare @Domain varchar(128) = DEFAULT_DOMAIN()

SET @varAppLogin_Name = RTRIM('{varAppLogin_Name}')

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


USE {varAppDB}
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


GO

/*
Create mail profile result

{varAppDB}						DatabaseName (new or existing)
{varEmailProfile}
*/

USE {varAppDB}

GO


declare @Result_Message nvarchar(200);

declare @EDIT_MAILPROFILE_PROP nvarchar(128);

set @EDIT_MAILPROFILE_PROP = '{varEmailProfile}';

if exists (select 1 from [msdb].[dbo].[sysmail_account] as [a])
begin
    set @Result_Message = 'Database Mail Installed';


    if not exists
    (
        select [p].[name]
        from [msdb].[dbo].[sysmail_account]                  as [a]
            inner join [msdb].[dbo].[sysmail_profileaccount] as [pa]
                on [a].[account_id] = [pa].[account_id]
            inner join [msdb].[dbo].[sysmail_profile]        as [p]
                on [pa].[profile_id] = [p].[profile_id]
        where [p].[name] = @EDIT_MAILPROFILE_PROP
    )
    begin

        -- Create a Database Mail profile
        execute [msdb].[dbo].[sysmail_add_profile_sp] @profile_name = @EDIT_MAILPROFILE_PROP
                                                    , @description = 'Profile for MFSQLConnector.';

    end;

end;
else
begin

    set @Result_Message = 'Database Mail is not installed on the SQL Server';
end;

GO
SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-08
	Description: MFSQLObjectsColtrol have a listing of all the objects included in the MFSQL Connector
	 as standard application objects and the release version of the specific object
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from setup.MFSQLObjectsControl
  
-----------------------------------------------------------------------------------------------*/
--DROP TABLE settings

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[setup].[MFSQLObjectsControl]';

GO

/*
CREATE TABLE IF NOT EXIST
*/
IF NOT EXISTS ( SELECT  object_id
                FROM    sys.objects
				INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                WHERE   objects.name = 'MFSQLObjectsControl' AND s.name = 'setup' )
    BEGIN

        CREATE TABLE Setup.MFSQLObjectsControl
            (
              id INT IDENTITY ,
              [Schema] VARCHAR(100) ,
              Name VARCHAR(100) NOT NULL ,
              [object_id] INT NULL ,
              Release VARCHAR(50) NULL ,
              [Type] VARCHAR(10) NULL ,
              Modify_Date DATETIME NULL
                                   DEFAULT GETDATE(),
				Module int
            );

        PRINT SPACE(10) + '... Table: created';

        IF NOT EXISTS ( SELECT  object_id
                        FROM    sys.indexes
                        WHERE   name = N'idx_MFSQLObjectsControl_name' )
            BEGIN
                PRINT SPACE(10) + '... Index: idx_MFSQLObjectsControl_name';
                CREATE NONCLUSTERED INDEX idx_MFSQLObjectsControl_name ON Setup.MFSQLObjectsControl(Name);

            END;
    END; 

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS AS c WHERE c.COLUMN_NAME = 'Module' AND c.TABLE_NAME = 'MFSQLObjectsControl')
Begin
ALTER TABLE setup.MFSQLObjectsControl
ADD Module INT DEFAULT((0))
END



	go


GO

SET NOCOUNT ON; 
GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.Setup.spMFSQLObjectsControl';

GO
SET NOCOUNT ON; 


/*

------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: 
	Description: Procedure to allow updating of specific release of Object
------------------------------------------------------------------------------------------------

/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  for updating a specific object
  EXEC setup.spMFSQLObjectsControl 'spMFUpdateConnectorObjects', '2.0.2.6',  2, 1

  select * from setup.MFSQLObjectsControl

  for validation
  EXEC setup.spMFSQLObjectsControl @UpdateFlag = 3
  
  select * from sys.objects
-----------------------------------------------------------------------------------------------*/

-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSQLObjectsControl'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'setup' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [Setup].[spMFSQLObjectsControl]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC Setup.spMFSQLObjectsControl
    (
      @SchemaName NVARCHAR(128) = NULL ,
      @ObjectName NVARCHAR(128) = NULL ,
      @Object_Release VARCHAR(50) = NULL ,
      @UpdateFlag SMALLINT = 1 ,
      @debug SMALLINT = 0
    )

--@Updateflags   2 Update Object; 3 Validate
AS
    DECLARE @Query NVARCHAR(MAX) ,
        @Param NVARCHAR(MAX);
    BEGIN

  
        IF @UpdateFlag = 2
            BEGIN


                SELECT  @Query = N'
MERGE INTO setup.[MFSQLObjectsControl] t

USING (SELECT ''' + @SchemaName + ''' AS [Schema],''' + @ObjectName
                        + ''' AS Name, ''' + @Object_Release
                        + ''' AS Release) s 
ON (t.name = s.name and t.[Schema] = s.[Schema])
WHEN MATCHED THEN 
UPDATE 
SET t.Release = s.Release, t.[Modify_Date] = GETDATE()
WHEN NOT MATCHED BY TARGET THEN 
INSERT ([Schema], [Name],[Release],[Modify_Date])
VALUES
(s.[Schema], s.[name], s.[Release],GETDATE())
;
';
                IF @debug <> 0
                    SELECT  @Query;

                EXEC sp_executesql @Query;

            END;

        IF @UpdateFlag = 3
            BEGIN
                PRINT 'Connector Object Validation';

                DECLARE @ObjectList AS TABLE
                    (
                      [Schema] NVARCHAR(128) ,
                      Name NVARCHAR(128)
                    );

                INSERT  INTO @ObjectList
                        ( [Schema] ,
                          [Name]
                        )
                        
                        SELECT  s.[name] ,
                                objects.name
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'MF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'spMF%'
                        UNION ALL
--SELECT s.[name],objects.Name, [objects].[object_id], type, [objects].[modify_date] FROM sys.objects
--INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id] WHERE [objects].[name] like 'tMF%'
--UNION ALL
                        SELECT  s.[name] ,
                                objects.name
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'fnMF%';

                IF @debug > 0
                    BEGIN
                        SELECT  *
                        FROM    @ObjectList AS [ol];
                        SELECT  *
                        FROM    Setup.[MFSQLObjectsControl] AS [moc];
                    END;

                SELECT  ol.[Schema] ,
                        ol.Name ,
                        [mco].[Modify_Date] 'Object has no Release'
                FROM    @ObjectList AS [ol]
                        LEFT JOIN Setup.[MFSQLObjectsControl] AS [mco] ON ol.[Name] = [mco].[Name]
                                                              AND ol.[Schema] = [mco].[Schema]
                WHERE   mco.[Release] IS NULL;


            END;


    END;  


GO

EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'Setup', -- nvarchar(128)
    @ObjectName = N'spMFSQLObjectsControl', -- nvarchar(128)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2, -- smallint
    @debug = 0;
 -- smallint

GO
SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Create Process Table	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-9-1		LC			Change table to MFProcess, extend use of table to be included in logging
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from Process; Process data describe the keys used as the process_id in the class tables.
  
-----------------------------------------------------------------------------------------------*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProcess]';

GO

EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'MFProcess', -- nvarchar(100)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2 -- smallint



IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProcess'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE MFProcess
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(50) NOT NULL ,
              [Description] VARCHAR(1000) NULL ,
              [ModifiedOn] VARCHAR(40)
                CONSTRAINT [DEF_MFProcess_ModifiedOn] DEFAULT ( GETDATE() )
                NULL ,
              CONSTRAINT [PK_MFProcess] PRIMARY KEY CLUSTERED ( [ID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


--INDEXES #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFProcess')
                        AND name = N'idx_MFProcess_id' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_Process_id';
        CREATE NONCLUSTERED INDEX idx_MFProcess_id ON dbo.MFProcess (ID);
    END;

--DATA #########################################################################################################################3#######
/* Example1:
	DELETE Process
	INSERT Process VALUE(...)

   Example2:
	INSERT Process
	....
 	FROM Process trg
	WHERE NOT EXISTS(Select 1 from Process src where src.id = trg.id)
*/

PRINT SPACE(10) + 'INSERTING DATA INTO TABLE: MFProcess ';

SET IDENTITY_INSERT [dbo].[MFProcess] ON; 

DELETE  FROM [dbo].[MFProcess]
WHERE   ID IN ( 0, 1, 2, 3, 4 );

INSERT  [dbo].[MFProcess]
        ( [ID], [Name], [Description], [ModifiedOn] )
VALUES  ( 0, N'To M-Files', N'Set by Connector to show record updated by M-Files',
          GETDATE() ),
        ( 1, N'From M-Files', N'Set by user to show record to be updated to M-Files',
          GETDATE() ),
        ( 2, N'SyncronisationError',
          N'Set by Connector to show Syncronisation errors', GETDATE() ),
        ( 3, N'MFError', N'Set by Connector to show record with MFiles error',
          GETDATE() ),
        ( 4, N'SQLError', N'Set by Connector to show record with SQL error',
          GETDATE() );

SET IDENTITY_INSERT [dbo].[MFProcess] OFF;

PRINT SPACE(10) + 'INSERTING DATA COMPLETED: Process ';

--SECURITY #########################################################################################################################3#######
--** Alternatively add ALL security scripts to single file: script.SQLPermissions_{dbname}.sql
/* Example: 
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Process TO public
*/
GO

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Settings sets all the global parameters for the connector. Users can add additional settings for
	special applications but standard settings should not be changed or deleted.
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			Change primary key to include source_key
	2018-4-28			lc		Add new settings for user messages and vault structure id
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from Settings
  
-----------------------------------------------------------------------------------------------*/
--DROP TABLE settings

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFSettings]';

GO

EXEC setup.spMFSQLObjectsControl @SchemaName = 'dbo',
@ObjectName = N'MFSettings', -- nvarchar(100)
    @Object_Release = '4.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
	


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFSettings'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE dbo.MFSettings
            (
              [id] [INT] IDENTITY(1, 1)
                         NOT NULL ,
              [source_key] [NVARCHAR](20) NULL ,
              [Name] [VARCHAR](50) NOT NULL ,
              [Description] [VARCHAR](500) NULL ,
              [Value] [SQL_VARIANT] NOT NULL ,
              [Enabled] [BIT] NOT NULL ,
              CONSTRAINT [PK_MFSettings] PRIMARY KEY CLUSTERED ( [id] ASC )
                WITH ( PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF,
                       IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON,
                       ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
				
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


--INDEXES #############################################################################################################################


IF EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('dbo.MFSettings')
                        AND name = N'idx_MFSettings_name' ) 
	DROP INDEX idx_MFSettings_name ON dbo.MFSettings
	GO

        PRINT SPACE(10) + '... Index: idx_MFSettings_name';
        CREATE NONCLUSTERED INDEX idx_MFSettings_name ON dbo.MFSettings ([source_key],[name])
	GO
  IF EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFSettings')
                        AND name = N'idx_MFSettings_id' )
	DROP INDEX idx_MFSettings_id ON dbo.MFSettings
	GO
		PRINT SPACE(10) + '... Index: idx_MFSettings_id';
		CREATE NONCLUSTERED INDEX idx_MFSettings_id ON dbo.MFSettings (id)
	GO


	IF EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFSettings')
                        AND name = N'udx_MFSettings_name' )
  
	ALTER TABLE dbo.MFSettings
	DROP CONSTRAINT  udx_MFSettings_name 
	GO
    
		PRINT SPACE(10) + '... Index: udx_MFSettings_name';
		ALTER TABLE dbo.MFSettings
		ADD CONSTRAINT udx_MFSettings_name UNIQUE ([source_key],[name])
	go







go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFAuthenticationType]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFAuthenticationType', -- nvarchar(100)
    @Object_Release = '3.1.0.24', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFiles Authentication Type Lookup 
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFAuthenticationType
  
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFAuthenticationType'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFAuthenticationType
			(
			    [ID] int IDENTITY(1,1) NOT NULL,
				[AuthenticationType] [varchar](250) NULL,
		        [AuthenticationTypeValue] [varchar](20) NULL,
			   CONSTRAINT [PK_MFAuthenticationType] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
       
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Unknown','0')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Current Windows User','1')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Specific Windows User','2')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('M-Files User','3')

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

			
GO		




go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProtocolType]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFProtocolType', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFiles Lookup Protocol  Details
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFProtocolType
  Drop table MFprotocolType
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProtocolType'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFProtocolType
			(
			    [ID] int IDENTITY(1,1) NOT NULL,
				[ProtocolType] [nvarchar](250) NULL,
				[MFProtocolTypeValue] [nvarchar](200) NULL,
			   CONSTRAINT [PK_MFProtocolType] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
     	
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('TCP/IP','ncacn_ip_tcp')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('SPX','')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('Local Procedure Call','ncalrpc')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('HTTPS','ncacn_http')    

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

			
GO		



go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFVaultSettings]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFVaultSettings', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFiles Authentication Type Lookup 
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFAuthenticationType
  
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFVaultSettings'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFVaultSettings
			(
			    [ID] int IDENTITY(1,1) NOT NULL,
				[Username] nvarchar(128),
		        [Password] nvarchar(128),
				[NetworkAddress] nvarchar(128),
				[VaultName] nvarchar(128),
				[MFProtocolType_ID] INT,
				[Endpoint] int,
				[MFAuthenticationType_ID] int,
				[Domain] nvarchar(128)
			   CONSTRAINT [PK_MFVaultSettings] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
        

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

GO			
--FOREIGN KEYS #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.foreign_keys
                WHERE   parent_object_id = OBJECT_ID('MFVaultSettings')
                        AND name = N'FK_MFVaultSettings_MFProtocolType_ID' )
    BEGIN
        PRINT SPACE(10) + '... Constraint: FK_MFVaultSettings_MFProtocolType_ID';
        ALTER TABLE dbo.MFVaultSettings   WITH CHECK ADD 
         CONSTRAINT FK_MFVaultSettings_MFProtocolType_ID FOREIGN KEY (MFProtocolType_ID)
        REFERENCES [dbo].[MFProtocolType] ([id])
        ON DELETE NO ACTION;

    END;

GO
IF NOT EXISTS ( SELECT  *
                FROM    sys.foreign_keys
                WHERE   parent_object_id = OBJECT_ID('MFVaultSettings')
                        AND name = N'FK_MFVaultSettings_MFAuthenticationType_ID' )
    BEGIN
        PRINT SPACE(10) + '... Constraint: FK_MFVaultSettings_MFAuthenticationType_ID';
        ALTER TABLE dbo.MFVaultSettings WITH CHECK  ADD 
          CONSTRAINT FK_MFVaultSettings_MFAuthenticationType_ID FOREIGN KEY (MFAuthenticationType_ID)
        REFERENCES [dbo].[MFAuthenticationType] ([id])
        ON DELETE NO ACTION;

    END;

GO



/*
Migration script for  Settings

to check for existing entries and migrate the new settings definition into the existing table

Last Modified: 
2019-1-9	lc	Exclude MFversion from begin overwritten from SQL, show message when installing manually
2019-1-26	lc	fix futher bug on MFVersion not being updated when version changed.
*/


SET NUMERIC_ROUNDABORT OFF;
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS, NOCOUNT ON;
GO
SET XACT_ABORT ON;
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO
	
DECLARE @rc INT
      , @msg AS VARCHAR(250)
      , @DBname NVARCHAR(100) = DB_NAME();

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + 'Migration of Settings table';

--SELECT  @rc = COUNT(*)
--FROM    [dbo].[MFSettings];

SET @msg = SPACE(5) + DB_NAME() + ' : settings migrated: ';
RAISERROR('%s',10,1,@msg); 

BEGIN TRANSACTION;


IF ISNULL(@rc,0) = 0
BEGIN


IF (SELECT object_id('Tempdb..##Settings_temp'))IS NOT NULL
DROP TABLE ##Settings_temp;

SELECT  *
INTO    [#Settings_temp]
FROM    [dbo].[MFSettings];


TRUNCATE TABLE [dbo].[MFSettings];



INSERT  [dbo].[MFSettings]
        ( [source_key], [Name], [Description], [Value], [Enabled] )
VALUES  ( N'Email', N'SupportEmailRecipient', N'Email account for recipient of automated support mails',
          N'{varITSupportEmail}', 1 ),
        ( N'Email', N'SupportEMailProfile', N'SupportEMailProfile', N'{varEmailProfile}', 1 ),
        ( N'MF_Default', N'MFInstallPath', N'Path of MFiles installation on server', N'{varMFInstallPath}', 1 ),
        ( N'MF_Default', N'MFVersion', N'Version Number of MFiles', N'{varMFVersion}', 1 ),
        ( N'App_Default', N'App_Database', N'Database of Connector', N'{varAppDB}', 1 ),
		( N'App_Default', N'App_DetailLogging', N'ProcessBatch Update is active', N'{varLoggingRequired}', 1 ),
        ( N'App_Default', N'AssemblyInstallPath', N'Path where the Assemblies have been saved on the SQL Server',
          N'{varCLRPath}', 1 ),
        ( N'App_Default', N'AppUserRole', N'Database App User role', N'{varAppDBRole}', 1 ),
        ( N'App_Default', N'AppUser', N'Database App User', N'{varAppLogin_Name}', 1 ),
	    (
	      'Files_Default'   
	   , 'RootFolder' 
	   , 'Root folder for exporting files from M-Files'
	   , '{varExportFolder}' 
	    ,1),
	    (
	      'Files_Default'   
	   , 'FileTransferLocation' 
	   , 'Folder temporary filing of imported files from database to M-Files'
	   , '{varImportFolder}' 
	    ,1
		),
('MF_Default', 'LastMetadataStructureID', 'Latest Metadata structure ID', '1', 1),
('MF_Default', 'MFUserMessagesEnabled', 'Enable Update of User Messages in M-Files', '0', 1)

IF '{varMFVersion}' <> (SELECT CAST(VALUE AS NVARCHAR(100)) FROM MFSETTINGS WHERE Name = 'MFVersion')
BEGIN
RAISERROR('MF Version in MFSettings differ from Installation package - package version is applied',10,1)
END
 


UPDATE  [s]
SET     [s].[Value] = [st].[Value]
FROM    [dbo].[MFSettings] [s]
INNER JOIN [#Settings_temp] [st] ON [s].[Name] = [st].[Name]
WHERE st.name NOT IN ('MFVersion')

--SELECT * FROM [dbo].[MFSettings] AS [s]

--migrate custom settings 
INSERT  INTO [dbo].[MFSettings]
        ( [source_key]
        , [Name]
        , [Description]
        , [Value]
        , [Enabled]
        )
        SELECT  [st].[source_key]
              , [st].[Name]
              , [st].[Description]
              , [st].[Value]
              , [st].[Enabled]
        FROM    [dbo].[MFSettings] [s]
        FULL OUTER JOIN [#Settings_temp] [st] ON [s].[Name] = [st].[Name]
        WHERE   [s].[Name] IS NULL;
/*
SELECT  * FROM    MFSettings;
*/
DROP TABLE [#Settings_temp];

END

SELECT  @rc = COUNT(*)
FROM    [dbo].[MFSettings];
IF @rc > 0
   RAISERROR('%s (%d records)',10,1,@msg,@rc); 


COMMIT TRAN

GO

            


GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSettingsForDBUpdate]';
GO

SET NOCOUNT on
  EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSettingsForDBUpdate', -- nvarchar(100)
      @Object_Release = '4.1.5.41', -- varchar(50)
      @UpdateFlag = 2 -- smallint
;
/*
------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: 
	Description: Procedure to allow updating of specific settings
------------------------------------------------------------------------------------------------
*/

/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			Change Settings index
	2017-9-2		LC			Add RootFolder setting
	2017-11-23		lc			resolve bug for missing value
	2018-2-16		c			add file import and export change setting
	2018-4-28		lc			add user message setting; vault structure setting
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFSettingsForDBUpdate]   
  select * from mfsettings

  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSettingsForDBUpdate'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSettingsForDBUpdate]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFSettingsForDBUpdate
    (
   
	  @MFInstallationPath NVARCHAR(128) = null , -- N'C:\Program Files\M-Files'  path where M-Files is installed on SQL server
      @MFilesVersion NVARCHAR(128) = null , -- M-Files version deployed on SQL server
      @AssemblyInstallationPath NVARCHAR(128) = null , -- N'C:\CLR' path where the Laminin Assemblies have been copied to.
      @SQLConnectorLogin NVARCHAR(128) = null, -- 'MFSQLConnect' default SQL login user for the App
      @UserRole NVARCHAR(128) = null ,-- 'AppUserRole' Default role for SQL user
      @SupportEmailAccount NVARCHAR(128) = null , -- N'support@lamininsolutions.com' email to receive system error emails
      @EmailProfile NVARCHAR(128) = null , -- N'LSEmailProfile' DBMail profile to be used for emails
	  @DetailLogging nvarchar(128) = null,
      @DBName nvarchar(128) = null,
	  @RootFolder nvarchar(128) = null,
	  @FileTransferLocation nvarchar(128) = null,
	  @Debug SMALLINT = 0
    )
AS
    BEGIN

        SET NOCOUNT ON;

        IF @SupportEmailAccount IS NOT null
		UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@SupportEmailAccount), Value)
        WHERE   Name = 'SupportEmailRecipient' AND [source_key] = 'Email';

		IF @EmailProfile IS NOT null
        UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@EmailProfile), Value)
        WHERE   Name = 'SupportEMailProfile' AND [source_key] = 'Email';

		IF @MFInstallationPath IS NOT null
        UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@MFInstallationPath), Value)
        WHERE   Name = 'MFInstallPath' AND [source_key] = 'MF_Default';

		IF @AssemblyInstallationPath IS NOT null
        UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@AssemblyInstallationPath), Value)
        WHERE   Name = 'AssemblyInstallPath' AND [source_key] = 'APP_Default' ;
 
 IF @MFilesVersion IS NOT null
        UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@MFilesVersion), Value)
        WHERE   Name = 'MFVersion' AND [source_key] = 'MF_Default';

		IF @DBName IS NOT null
       UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@DBName), Value)
        WHERE   Name = 'App_Database' AND [source_key] = 'APP_Default';

		IF @UserRole IS NOT null
        UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@UserRole), value)
        WHERE   Name = 'AppUserRole' AND [source_key] = 'APP_Default';

		IF @SQLConnectorLogin IS NOT null
        UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@SQLConnectorLogin),Value)
        WHERE   Name = 'AppUser' AND [source_key] = 'APP_Default';

		IF @DetailLogging IS NOT null
        UPDATE  [dbo].[MFSettings]
        SET     Value = isnull(convert(sql_variant,@DetailLogging), Value)
        WHERE   Name = 'App_DetailLogging' AND [source_key] = 'APP_Default';

		IF @RootFolder IS NOT null
			UPDATE [dbo].[MFSettings]
			SET value = @RootFolder
	FROM mfsettings WHERE name = 'RootFolder' AND [source_key] = 'Files_Default'

	IF @FileTransferLocation IS NOT null
			UPDATE [dbo].[MFSettings]
			SET value = @FileTransferLocation
	FROM mfsettings WHERE name = 'FileTransferLocation' AND [source_key] = 'Files_Default'
  --select * from mfsettings

END;
 
    RETURN 1;

 GO
 


GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSettingsForVaultUpdate]';
GO

SET NOCOUNT ON;
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSettingsForVaultUpdate', -- nvarchar(100)
    @Object_Release = '3.1.1.34',                -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: 
	Description: Procedure to allow updating of specific settings
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			change settings index
	2016-10-12		LC			Update procedure to allow for updating of settings into the new MFVaultSettings Table
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFSettingsForVaultUpdate]   
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSettingsForVaultUpdate' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: updated';
    --		DROP PROCEDURE dbo.[spMFSettingsForVaultUpdate]
    SET NOEXEC ON;

END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO


-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSettingsForVaultUpdate]
AS
    SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE dbo.spMFSettingsForVaultUpdate
(
    @Username NVARCHAR(100) = NULL,       --  M-Files user with vault admin rights
    @Password NVARCHAR(100) = NULL,       -- the password will be encrypted 
    @NetworkAddress NVARCHAR(100) = NULL, -- N'laminindev.lamininsolutions.com' -Vault server URL from SQL server
    @Vaultname NVARCHAR(100) = NULL,      -- vault name 
    @MFProtocolType_ID INT = NULL,        -- select items from list in MFProtocolType
    @Endpoint INT = NULL,                 -- default 2266
    @MFAuthenticationType_ID INT = NULL,  -- select item from list of MFAutenticationType
    @Domain NVARCHAR(128) = NULL,
    @VaultGUID NVARCHAR(128) = NULL,      -- N'CD6AEE8F-D8F8-413E-AB2C-398B50097D39' GUID from M-Files admin
    @ServerURL NVARCHAR(128) = NULL,      --- N'laminindev.lamininsolutions.com' Web Address of M-Files
    @Debug SMALLINT = 0
)
AS
BEGIN



    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM [dbo].[MFVaultSettings] AS [mvs])
    BEGIN

        INSERT INTO [dbo].[MFVaultSettings]
        (
            [Username],
            [Password],
            [NetworkAddress],
            [VaultName],
            [MFProtocolType_ID],
            [Endpoint],
            [MFAuthenticationType_ID],
            [Domain]
        )
        VALUES
        (   '',              -- Username - nvarchar(128)
            NULL,            -- Password - nvarchar(128)
            N'localhost',    -- NetworkAddress - nvarchar(128)
            N'Sample Vault', -- VaultName - nvarchar(128)
            1,               -- MFProtocolType_ID - int
            2266,            -- Endpoint - int
            4,               -- MFAuthenticationType_ID - int
            N''              -- Domain - nvarchar(128)
        );
    END;

    BEGIN

        DECLARE @Prev_Username NVARCHAR(100),
            @Prev_Password NVARCHAR(100),
            @Prev_NetworkAddress NVARCHAR(100),
            @Prev_Vaultname NVARCHAR(100),
            @Prev_MFProtocolType_ID INT,
            @Prev_Endpoint INT,
            @Prev_MFAuthenticationType_ID INT,
            @Prev_Domain NVARCHAR(128),
            @Prev_VaultGUID NVARCHAR(128),
            @Prev_ServerURL NVARCHAR(128);

        SELECT @Prev_Username = Username,
            @Prev_Password = [Password],
            @Prev_NetworkAddress = NetworkAddress,
            @Prev_Vaultname = VaultName,
            @Prev_MFProtocolType_ID = MFProtocolType_ID,
            @Prev_Endpoint = [Endpoint],
            @Prev_MFAuthenticationType_ID = MFAuthenticationType_ID,
            @Prev_Domain = Domain
        FROM dbo.MFVaultSettings AS MVS;

        SELECT @Prev_VaultGUID = CONVERT(NVARCHAR(128), Value)
        FROM MFSettings
        WHERE Name = 'VaultGUID'
              AND [source_key] = 'MF_Default';

        SELECT @Prev_ServerURL = CONVERT(NVARCHAR(128), Value)
        FROM MFSettings
        WHERE Name = 'ServerURL'
              AND [source_key] = 'MF_Default';

        IF @Debug > 0
            SELECT @Prev_Username AS Username,
                @Prev_Password AS [Password],
                @Prev_NetworkAddress AS NetworkAddress,
                @Prev_Vaultname AS Vaultname,
                @Prev_MFProtocolType_ID AS MFProtocolType_ID,
                @Prev_Endpoint AS [Endpoint],
                @Prev_MFAuthenticationType_ID AS MFAuthenticationType_ID,
                @Prev_Domain AS Domain,
                @Prev_VaultGUID AS VaultGuid,
                @Prev_ServerURL AS ServerURL;



        UPDATE mfs
        SET Username = CASE
                           WHEN @Username <> @Prev_Username
                                AND @Username IS NOT NULL THEN
                               @Username
                           ELSE
                               @Prev_Username
                       END,
            NetworkAddress = CASE
                                 WHEN @NetworkAddress <> @Prev_NetworkAddress
                                      AND @NetworkAddress IS NOT NULL THEN
                                     @NetworkAddress
                                 ELSE
                                     @Prev_NetworkAddress
                             END,
            VaultName = CASE
                            WHEN @Vaultname <> @Prev_Vaultname
                                 AND @Vaultname IS NOT NULL THEN
                                @Vaultname
                            ELSE
                                @Prev_Vaultname
                        END,
            MFProtocolType_ID = CASE
                                    WHEN @MFProtocolType_ID <> @Prev_MFProtocolType_ID
                                         AND @MFProtocolType_ID IS NOT NULL THEN
                                        @MFProtocolType_ID
                                    ELSE
                                        @Prev_MFProtocolType_ID
                                END,
            [Endpoint] = CASE
                             WHEN @Endpoint <> @Prev_Endpoint
                                  AND @Endpoint IS NOT NULL THEN
                                 @Endpoint
                             ELSE
                                 @Prev_Endpoint
                         END,
            MFAuthenticationType_ID = CASE
                                          WHEN @MFAuthenticationType_ID <> @Prev_MFAuthenticationType_ID
                                               AND @MFAuthenticationType_ID IS NOT NULL THEN
                                              @MFAuthenticationType_ID
                                          ELSE
                                              @Prev_MFAuthenticationType_ID
                                      END,
            Domain = CASE
                         WHEN @Domain <> @Prev_Domain
                              AND @Domain IS NOT NULL THEN
                             @Domain
                         ELSE
                             @Prev_Domain
                     END
        FROM MFVaultSettings mfs;

        IF @Debug > 0
            SELECT CASE
                       WHEN @VaultGUID IS NOT NULL
                            AND @VaultGUID <> @Prev_VaultGUID THEN
                           CONVERT(SQL_VARIANT, @VaultGUID)
                       ELSE
                           CONVERT(SQL_VARIANT, @Prev_VaultGUID)
                   END AS VaultGUID;

        UPDATE [dbo].[MFSettings]
        SET Value = CASE
                        WHEN @VaultGUID IS NOT NULL
                             AND @VaultGUID <> @Prev_VaultGUID THEN
                            CONVERT(SQL_VARIANT, @VaultGUID)
                        ELSE
                            CONVERT(SQL_VARIANT, @Prev_VaultGUID)
                    END
        WHERE Name = 'VaultGUID'
              AND [source_key] = 'MF_Default';

        IF @Debug > 0
            SELECT CASE
                       WHEN @ServerURL <> @Prev_ServerURL
                            AND @ServerURL IS NOT NULL THEN
                           CONVERT(SQL_VARIANT, @ServerURL)
                       ELSE
                           CONVERT(SQL_VARIANT, @Prev_ServerURL)
                   END;


        UPDATE [dbo].[MFSettings]
        SET Value = CASE
                        WHEN @ServerURL <> @Prev_ServerURL
                             AND @ServerURL IS NOT NULL THEN
                            CONVERT(SQL_VARIANT, @ServerURL)
                        ELSE
                            CONVERT(SQL_VARIANT, @Prev_ServerURL)
                    END
        WHERE Name = 'ServerURL'
              AND [source_key] = 'MF_Default';


        IF @Password IS NOT NULL
        BEGIN



            DECLARE @EncryptedPassword NVARCHAR(250);
            DECLARE @PreviousPassword NVARCHAR(100);


            SELECT TOP 1
                @PreviousPassword = [Password]
            FROM dbo.MFVaultSettings s;

            IF @Debug = 1
                SELECT @EncryptedPassword AS '@EncryptedPassword',
                    @PreviousPassword AS '@PreviousPassword';

            IF @PreviousPassword IS NULL
                EXEC [dbo].[spMFEncrypt] @Password = N'null', -- nvarchar(2000)
                    @EcryptedPassword = @PreviousPassword OUTPUT; -- nvarchar(2000);


            EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @PreviousPassword, -- nvarchar(2000)
                @DecryptedPassword = @PreviousPassword OUTPUT; -- nvarchar(2000)
        END;

        IF @Password IS NOT NULL
           AND @Password <> @PreviousPassword
        BEGIN

            EXECUTE dbo.spMFEncrypt @Password, @EncryptedPassword OUT;

            UPDATE s
            SET [s].[Password] = @EncryptedPassword
            FROM dbo.MFVaultSettings s;


        END;
    END;


    RETURN 1;
END;


GO
