


-------------------------------------------------------------
	    -- Setup security for MFSQL Connector on third party DB
	    -------------------------------------------------------------

--Logins

DECLARE @AppLogin_Password varchar(128)
DECLARE @login varchar(50)

SET @login= 'MFSQLConnect'
Set @AppLogin_Password = 'Connector01'

	PRINT space(5) + 'CREATE [' + @Login + '] SQL Login for SQL Authentication' 
	IF NOT EXISTS (SELECT name 
					FROM sys.server_principals
					WHERE name = @login
					)
		BEGIN
			PRINT space(5) + '    -- creating login... ' 
			EXEC ('CREATE LOGIN [' + @login + '] WITH PASSWORD = ''' + @AppLogin_Password + '''') 
		END
		ELSE
			PRINT space(5) + '    -- login exists. ';
			


SET @login= 'MFSQLAdmin'
Set @AppLogin_Password = 'Admin01#2017'

	PRINT space(5) + 'CREATE [' + @Login + '] SQL Login for SQL Authentication' 
	IF NOT EXISTS (SELECT name 
					FROM sys.server_principals
					WHERE name = @login
					)
		BEGIN
			PRINT space(5) + '    -- creating login... ' 
			EXEC ('CREATE LOGIN [' + @login + '] WITH PASSWORD = ''' + @AppLogin_Password + '''') 
		END
		ELSE
			PRINT space(5) + '    -- login exists. ';
			

--Roles

        DECLARE @DBRole NVARCHAR(100), @Schema NVARCHAR(100)
		SET @dbrole = 'db_MFSQLConnect'

			PRINT 'CREATE DATABASE ROLE [' + @dbrole + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @dbrole AND type = 'R')
		BEGIN
			PRINT SPACE(5) + '    -- adding database role... '
			EXEC ('CREATE ROLE [' + @dbrole +'] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- database role exists. '

		SET @dbrole = 'db_MFSQLAdmin'

			PRINT 'CREATE DATABASE ROLE [' + @dbrole + ']'
		IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = @dbrole AND type = 'R')
		BEGIN
			PRINT SPACE(5) + '    -- adding database role... '
			EXEC ('CREATE ROLE [' + @dbrole +'] AUTHORIZATION [dbo]')
		END
		ELSE 
			PRINT space(5) + '    -- database role exists. '

--Schema permission
		SET @dbrole = 'db_MFSQLConnect'


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

	SET @dbrole = 'db_MFSQLAdmin'

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

		 
-- DB user
DECLARE @dbuser NVARCHAR(128)


BEGIN
	SET @dbuser='MFSQLConnect' -- {varAppWebLogin_Name}
	Set @DBRole='db_MFSQLConnect'

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

	SET @dbuser='MFSQLAdmin' -- {varAppWebLogin_Name}
	SET @dbrole = 'db_MFSQLAdmin'
	
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
END 
