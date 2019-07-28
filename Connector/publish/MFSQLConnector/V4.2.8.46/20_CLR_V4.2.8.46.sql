

GO


USE {varAppDB}	
GO

/***************************************************************************
IMPORTANT : READ AND PERFORM ACTION BEFORE EXECUTING THE RELEASE SCRIPT
***************************************************************************/

/*
THIS SCRIPT HAS BEEN PREPARE TO ALLOW FOR THE AUTOMATION OF ALL THE INSTALLATION VARIABLES

2017-3-24-7h30
*/

/*
First time installation only

Find what:					
{varMFUsername}					
{varMFPassword}					
{varNetworkAddress}				
{varVaultName}					
{varProtocolType}
{varEndpoint}
{varAuthenticationType}
{varMFDomain}
{varMFInstallPath}
{varAppDB}						

*/
GO
Go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckMFilesAssemblyVersion]';
GO
 

SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFGetMFilesAssemblyVersion'
  , -- nvarchar(100)
    @Object_Release = '2.1.1.20'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFGetMFilesAssemblyVersion'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFGetMFilesAssemblyVersion]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFGetMFilesAssemblyVersion]
   @IsUpdateAssembly bit =0 Output,
   @MFilesVersion varchar(100) Output
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Meta data  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **					
  **
  ** Parameters and acceptable values: 					
  **					
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					NONE
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					
  **				     spMFSynchronizeLoginAccount
  **														
  **
  ** Author:			DevTeam2
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  
  ******************************************************************************/
				BEGIN
				SET NOCOUNT ON;

				---------------------------------------------
				--DECLARE LOCAL VARIABLE
				--------------------------------------------- 
				DECLARE @VaultSettings NVARCHAR(4000),
				@LsMFileVersion varchar(250),
				@DbMFileVersion varchar(250);

				SELECT  
				@VaultSettings = [dbo].[FnMFVaultSettings]()

				select 
				@DbMFileVersion= CAST(Value AS VARCHAR(250)) 
				from 
				MFSettings
				WHERE   
				Name = 'MFVersion';

				EXECUTE spmfGetMFilesVersionInternal @VaultSettings,@LsMFileVersion OUTPUT

				if @LsMFileVersion= @DbMFileVersion
				Begin
				set @IsUpdateAssembly=0
				print 'Match'
				End
				else
				Begin

				print 'Not Matched Updating M-Files Latest Version'
				
				set @MFilesVersion=@LsMFileVersion
				set @IsUpdateAssembly=1

      
				END

				END
                
				GO

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckMFileAssemblyVersion]';
GO
 

SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFGetMFilesAssemblyVersion'
  , -- nvarchar(100)
    @Object_Release = '3.1.1.41'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFGetMFilesAssemblyVersion'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFGetMFilesAssemblyVersion]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFGetMFilesAssemblyVersion]
   @IsUpdateAssembly bit =0 Output,
   @MFilesVersion varchar(100) Output
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Meta data  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **					
  **
  ** Parameters and acceptable values: 					
  **					
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					NONE
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					
  **				     spMFSynchronizeLoginAccount
  **														
  **
  ** Author:			DevTeam2
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
     2018-04-04   Dev 2     Added Licensing module validation code.
	 2018-09-27		lc		remove licensing check. this procedure is excecuted before license is active
  ******************************************************************************/
				BEGIN
				SET NOCOUNT ON;

				---------------------------------------------
				--DECLARE LOCAL VARIABLE
				--------------------------------------------- 
				DECLARE @VaultSettings NVARCHAR(4000),
				@LsMFileVersion varchar(250),
				@DbMFileVersion varchar(250);

				SELECT  
				@VaultSettings = [dbo].[FnMFVaultSettings]()

				select 
				@DbMFileVersion= CAST(Value AS VARCHAR(250)) 
				from 
				MFSettings
				WHERE   
				Name = 'MFVersion';

		--		SELECT @DbMFileVersion

				-----------------------------------------------------------------
	             -- Checking module access for CLR procdure  spmfGetMFilesVersionInternal
			   ------------------------------------------------------------------

				EXECUTE spmfGetMFilesVersionInternal @VaultSettings,@LsMFileVersion OUTPUT

			--	SELECT @LsMFileVersion

				if @LsMFileVersion= @DbMFileVersion
				Begin
				set @IsUpdateAssembly=0
				 SET @MFilesVersion = @LsMFileVersion
				print 'Match'
				End
				else
				Begin

				print 'Not Matched: Updating M-Files to Latest Version'
				
				set @MFilesVersion=@LsMFileVersion
				set @IsUpdateAssembly=1

      
				END

				END
                
				GO
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckAssemblyVersion]';
GO
 


SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFCheckAndUpdateAssemblyVersion'
  , -- nvarchar(100)
    @Object_Release = '2.1.1.20'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFCheckAndUPdateAssemblyVersion'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFCheckAndUpdateAssemblyVersion]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFCheckAndUpdateAssemblyVersion] (@ScriptFilePath varchar(250))
 
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to check  M-File Version and update it
            database drop and recreeate assembly.
  **  
  ** 
  ** Tables Used:                 					  
  **					MFSettings
  **
  ** Return values:		
  **					NONE
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					
  **				     spMFCheckMFileAssemblyVersion
  **														
  **
  ** Author:			DevTeam2
  ** Date:				28-12-2016
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  2018-09-27		LC		change procedure to work with Release 4 scripts
  ******************************************************************************/
				BEGIN
					SET NOCOUNT ON;

				---------------------------------------------
				Declare @IsVersionMisMatch bit =0,
				        @MFilesVersion varchar(100),
						@MFilesOldVersion varchar(100),
				        @Update_ID INT,
						@ProcedureStep sysname = 'Start',
				        @Username NVARCHAR(2000),
				        @VaultName NVARCHAR(2000);

				SELECT TOP 1
				        @Username = [MFVaultSettings].[Username]
				      , @VaultName = [MFVaultSettings].[VaultName]
				FROM     
				      [dbo].[MFVaultSettings];

				set @ProcedureStep='Get Install assembly Version M-Files '

				exec spMFGetMFilesAssemblyVersion @IsVersionMisMatch Output
												,@MFilesVersion OutPut

				select @MFilesOldVersion= cast(Value as varchar(100)) from MFSettings where Name='MFVersion'
	   
	            
				if @IsVersionMisMatch = 1 
				begin
	       
       

				BEGIN TRY

		
				Update MFSettings set Value=@MFilesVersion where Name='MFVersion';

				INSERT   INTO [dbo].[MFUpdateHistory]
				( [Username]
				, [VaultName]
				, [UpdateMethod]
				)
				VALUES   ( @Username
				, @VaultName
				, 1
				);

				SELECT   @Update_ID = @@IDENTITY;
						
				--set @MFLocation= @MFLocation+'\CLPROC.Sql'
				DECLARE 
				@SQL varchar(MAX),
				@DBName varchar(250),
				@DBServerName varchar(250)

				Select @DBServerName=@@SERVERNAME
				Select @DBName=DB_NAME()

			--	Select @ScriptFilePath=cast(Value as varchar(250)) from MFSettings where Name='AssemblyInstallPath'
			
				SET NOCOUNT ON  
				EXEC master.dbo.sp_configure 'show advanced options', 1 
				RECONFIGURE 
				EXEC master.dbo.sp_configure 'xp_cmdshell', 1 
				RECONFIGURE 
					
				SET XACT_ABORT ON  
				set @ProcedureStep='Run CLR Procedure'
				DECLARE @command  VARCHAR(500)  = 'sqlcmd -S ' + @DBServerName + ' -d  ' + @DBName + ' -i "' + @ScriptFilePath +'"'  
				EXEC xp_cmdshell  @command  
		
		
				SET XACT_ABORT OFF

				EXEC master.dbo.sp_configure 'xp_cmdshell', 0 
				RECONFIGURE 
				EXEC master.dbo.sp_configure 'show advanced options', 0 
				RECONFIGURE  
				SET NOCOUNT OFF 

		 
			
		
				End Try
				Begin Catch

				    Update MFSettings set Value=@MFilesOldVersion  where Name='MFVersion';

					INSERT    INTO [dbo].[MFLog]
					( [SPName]
					, [ErrorNumber]
					, [ErrorMessage]
					, [ErrorProcedure]
					, [ProcedureStep]
					, [ErrorState]
					, [ErrorSeverity]
					, [Update_ID]
					, [ErrorLine]
					)
					VALUES    ( 'spMFUpdateTable'
					, ERROR_NUMBER()
					, ERROR_MESSAGE()
					, ERROR_PROCEDURE()
					, @ProcedureStep
					, ERROR_STATE()
					, ERROR_SEVERITY()
					, @Update_ID
					, ERROR_LINE())
				End catch


	 
				End

				End

				GO
GO


/*
script to run update of M-files version validation 



IF EXISTS(
select name FROM sys.[assemblies] AS [a] WHERE name = 'Interop.MFilesAPI') AND exists(SELECT 1 FROM mfsettings)
BEGIN

EXEC [dbo].[spMFCheckAndUpdateAssemblyVersion] @ScriptFilePath = 

END
*/
GO

GO

use {varAppDB}
GO

/*
Script to drop all the CLR tables 
Execute before updating Assemblies
*/

/*
MODIFICAITONS TO SCRIPT

version 3.1.2.38	LC	add spMFGetFilesInternal
version 3.1.2.38 ADD spMFGetHistory

*/

DECLARE @rc     INT
       ,@msg    AS VARCHAR(250)
       ,@DBName VARCHAR(100);

SELECT @DBName = CAST([Value] AS VARCHAR(100))
FROM [MFSettings]
WHERE [Name] = 'App_Database';

PRINT DB_NAME();
PRINT '-----';
PRINT @DBName;

IF DB_NAME() = @DBName
BEGIN
    SET @msg = SPACE(5) + DB_NAME() + ': Clear CLR procedures';

    RAISERROR('%s', 10, 1, @msg);

    /*
test that all the clr procedures have been dropped

*/
    DECLARE @ProcList AS TABLE
    (
        [id] INT IDENTITY
       ,[procname] NVARCHAR(100)
       ,[Schemaname] NVARCHAR(100)
       ,[SchemaID] INT
    );

    DECLARE @ID INT = 1;
    DECLARE @ProcName NVARCHAR(100);
    DECLARE @SchemaName NVARCHAR(100);
    DECLARE @SchemaID INT;
    DECLARE @SQL NVARCHAR(MAX);

    INSERT INTO @ProcList
    (
        [procname]
       ,[Schemaname]
       ,[SchemaID]
    )
    SELECT [so].[name] AS [procname]
          ,[ss].[name] AS [schemaname]
          ,[so].[schema_id]
    FROM [sys].[objects]           [so]
        INNER JOIN [sys].[schemas] [ss]
            ON [ss].[schema_id] = [so].[schema_id]
    WHERE [type] = 'PC'
          AND [so].[name] LIKE 'spMF%';

    WHILE @ID IS NOT NULL
    BEGIN
        SELECT @ProcName   = [pl].[procname]
              ,@SchemaName = [pl].[Schemaname]
              ,@SchemaID   = [pl].[SchemaID]
        FROM @ProcList AS [pl]
        WHERE [pl].[id] = @ID;

        IF EXISTS
        (
            SELECT *
            FROM [sys].[objects]
            WHERE [name] = @ProcName
                  AND [schema_id] = @SchemaID
        )
        BEGIN
            PRINT 'Dropping Procedure: ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ProcName);

            SET @SQL = N'DROP PROCEDURE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ProcName);

            EXEC (@SQL);
        END;

        SET @ID =
        (
            SELECT MIN([pl].[id]) FROM @ProcList AS [pl] WHERE [pl].[id] > @ID
        );
    END;
END;
ELSE
BEGIN
    SET @msg = SPACE(10) + ': Database error - rerun Settings Deployment';

    RAISERROR('%s', 10, 1, @msg);
END;
GO

GO

use {varAppDB}

GO

/*
MODIFICATIONS

2017-7-25 LC	ADD SETTING TO SET OWNER TO SA
2018-9-27 LC	Add control to check and update M-Files version. This is to allow for the CLR script to be able to be executed without running the app.
2019-1-9	lc	add additional controls to validate MFversion, exist when not exist.
2019-1-11	LC	IF version in mfsettings is different from installer then use installer 
*/
SET NOCOUNT ON;

DECLARE @rc INT,
        @msg AS VARCHAR(250),
        @DBName VARCHAR(100) = '{varAppDB}',
        @FileLocation NVARCHAR(250) = '{varCLRPath}',
        @MFLocation NVARCHAR(250),
        @MFInstallPath NVARCHAR(100) = '{varMFInstallPath}',
        @Version NVARCHAR(100) = '{varMFVersion}' ,
        @DatabaseName NVARCHAR(100),
        @AlterDBQuery NVARCHAR(500);
DECLARE @Output NVARCHAR(MAX);
DECLARE @CLRInstallationFlag BIT = 0;
DECLARE @FileName VARCHAR(255);
DECLARE @File_Exists INT;
/*
Test validity of the Assembly locations before proceding with installation
*/

IF EXISTS(
select name FROM sys.[assemblies] AS [a] WHERE name = 'Interop.MFilesAPI') AND exists(SELECT 1 FROM mfsettings)

BEGIN
SELECT @FileLocation = CAST(VALUE AS NVARCHAR(100)) FROM MFSETTINGS WHERE Name = 'AssemblyInstallPath'
SELECT @MFInstallPath = CAST(VALUE AS NVARCHAR(100)) FROM MFSETTINGS WHERE Name = 'MFInstallPath'

END



SELECT @FileName = @FileLocation + '\Laminin.Security.dll';
EXEC master.sys.xp_fileexist @FileName, @File_Exists OUT;
IF @File_Exists = 1
BEGIN
    SET @Output = 'Assembly location Found: '+ @FileLocation;
	RAISERROR(@Output, 10,1)
    SET @CLRInstallationFlag = 1;

END;
ELSE
BEGIN
    SET @Output = 'Unable to install Assemblies, check access to filelocation, run installation on SQL Server.';
	SET @CLRInstallationFlag = 0;
	RAISERROR(@Output, 16,1)
END;
/*
Test validity of M-Files API folder
*/

SET @MFLocation = @MFInstallPath + '\' + @Version + '\Common';
SET @DatabaseName = 'dbo.' + @DBName;

SELECT @FileName = @MFLocation + '\Interop.MFilesAPI.dll';
EXEC master.sys.xp_fileexist @FileName, @File_Exists OUT;
IF @File_Exists = 1
   AND @CLRInstallationFlag = 1
BEGIN
    SET @Output = 'M-Files API Found: ' + @FileName;
	RAISERROR(@Output, 10,1)
    SET @CLRInstallationFlag = 1;
END;
ELSE
BEGIN
    SET @Output
        = @Output
          + '; Unable to find M-Files Client installation, missing M-Files client '+ @FileName;
    SET @CLRInstallationFlag = 0;
	 RAISERROR('%s', 16, 1, @msg);
END;
IF @CLRInstallationFlag = 1
BEGIN

SET @msg = 'Set database owner to sa'
    EXEC sys.sp_changedbowner 'sa';

    RAISERROR('%s', 10, 1, @msg);

    IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'CLRSerializer')
    BEGIN
        PRINT 'Dropping ASSEMBLY: CLRSerializer ';

        DROP ASSEMBLY CLRSerializer;
    END;


    IF EXISTS
    (
        SELECT *
        FROM sys.assemblies
        WHERE name = 'LSConnectMFilesAPIWrapper'
    )
    BEGIN
        PRINT 'Dropping ASSEMBLY: LSConnectMFilesAPIWrapper ';

        DROP ASSEMBLY LSConnectMFilesAPIWrapper;
    END;



    IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'Laminin.Security')
    BEGIN
        PRINT 'Dropping ASSEMBLY: Laminin.Security ';

        DROP ASSEMBLY [Laminin.Security];
    END;



    IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'Interop.MFilesAPI')
    BEGIN
        PRINT 'Dropping ASSEMBLY: Interop.MFilesAPI ';

        DROP ASSEMBLY [Interop.MFilesAPI];
    END;



    --------------------------------------------------
    --ENABLE CLR
    --------------------------------------------------
    EXEC sys.sp_configure 'clr enabled', 1;


    RECONFIGURE;


    EXEC sys.sp_configure 'clr enabled';


    ALTER DATABASE [{varAppDB}] SET TRUSTWORTHY ON;


    EXECUTE (@AlterDBQuery);

    CREATE ASSEMBLY [Interop.MFilesAPI]
    FROM @MFLocation + '\Interop.MFilesAPI.dll'
    WITH PERMISSION_SET = UNSAFE;

    CREATE ASSEMBLY [Laminin.Security]
    FROM @FileLocation + '\Laminin.Security.dll'
    WITH PERMISSION_SET = SAFE;

    CREATE ASSEMBLY LSConnectMFilesAPIWrapper
    FROM @FileLocation + '\LSConnectMFilesAPIWrapper.dll'
    WITH PERMISSION_SET = UNSAFE;

    CREATE ASSEMBLY CLRSerializer
    FROM @FileLocation + '\LSConnectMFilesAPIWrapper.XmlSerializers.dll'
    WITH PERMISSION_SET = UNSAFE;
END;

IF @CLRInstallationFlag = 0
RAISERROR(@Output,16,1)


GO
-- -------------------------------------------------------- 
-- SourceDir: O:\Development\TFSSourceControl\lsconnectwrapper\LSConnector-Release2\MFSQLConnector\Workings\CLRProcs\ 
-- -------------------------------------------------------- 

--THIS COLLECTION OF PROCEDURES CREATE ALL THE CLR PROCEDURES

/*
MODIFICATIONS TO COLLECTION
version 3.1.2.38 ADD spMFGetFilesInternal
version 3.1.2.38 ADD spMFGetHistory
version 3.1.5.41 ADD spMFSynchronizeFileToMFilesInternal

*/
-- -------------------------------------------------------- 
-- sp.spMFDeleteObjectInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFDeleteObjectInternal]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFDeleteObjectInternal', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter.
    2017-05-04      DevTeam2    Added new parameter @DeleteWithDestroy

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFDeleteObjectInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFDeleteObjectInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFDeleteObjectInternal]
    @VaultSettings NVARCHAR(4000) ,
    @ObjectTypeId INT ,
    @objectId INT ,
    @Output NVARCHAR(2000) OUTPUT,
	@DeleteWithDestroy bit
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[DeleteObject];

GO

-- -------------------------------------------------------- 
-- sp.spMFEncrypt.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFEncrypt]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFEncrypt', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFEncrypt'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFEncrypt]
		
    END;
	GO
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 GO
     
CREATE PROCEDURE [dbo].[spMFEncrypt]
@Password NVARCHAR (2000), @EcryptedPassword NVARCHAR (2000) OUTPUT
AS EXTERNAL NAME [Laminin.Security].[Laminin.CryptoEngine].[Encrypt]

GO
  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetClass.sql 
-- -------------------------------------------------------- 

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetClass]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFGetClass', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault setting parameters and pass them as comma separated
	                            string in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetClass'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetClass];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFGetClass]
    @VaultSettings NVARCHAR(4000) ,
    @ClassXML NVARCHAR(MAX) OUTPUT ,
    @ClassPptXML NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFClasses];



GO





  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetLoginAccounts.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetLoginAccounts]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetLoginAccounts', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameters.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetLoginAccounts'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetLoginAccounts];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFGetLoginAccounts]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetLoginAccounts];

GO




  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetDataExportInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetDataExportInternal]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetDataExportInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetDataExportInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetDataExportInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     
CREATE PROCEDURE [dbo].[spMFGetDataExportInternal]
    @VaultSettings NVARCHAR(4000) ,
    @ExportDatasetName NVARCHAR(2000) ,
    @IsExported BIT OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ExportDataSet];



GO





  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetObjectType.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetObjectType]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetObjectType', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		        DESCRIPTION
	YYYY-MM-DD		{Author}	       {Comment}
	2016-09-26      DevTeam2(Rheal)    Removed Vault settings parametes and passed them as comma
									   separated string single parameter @VaultSettings
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetObjectType'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetObjectType];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFGetObjectType]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetObjectTypes];

GO








  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetObjectVersInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetObjectVersInternal]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetObjectVersInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: Kishore
	Create date: 2016-6-20
	Database: 
	Description: CLR procedure to get all the object version of the class
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-21      DevTeam2    Remove parameters @Username,@Password,@NetworkAddress,@VaultName and fetch 
			        (Rheal)     these parameters in single parameters as comma separate vaules.

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetObjectVersInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFGetObjectVersInternal]
		
    END;
	GO
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 GO

CREATE PROCEDURE [dbo].[spMFGetObjectVersInternal]
	@VaultSettings [nvarchar](4000),
	@ClassID [int],
	@dtModifieDateTime [datetime],
	@MFIDs [nvarchar](4000),
	@ObjverXML [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetOnlyObjectVersions]
GO


  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetProperty.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetProperty]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetProperty', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings and pass them as comma separated string 
	                            in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetProperty'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetProperty];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO


CREATE PROCEDURE [dbo].[spMFGetProperty]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetProperties];

GO








  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetUserAccounts.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetUserAccounts]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetUserAccounts', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetUserAccounts'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetUserAccounts];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFGetUserAccounts]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetUserAccounts];

GO





  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetValueList.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetValueList]';
GO
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetValueList', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetValueList'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetValueList];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     
CREATE PROCEDURE [dbo].[spMFGetValueList]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetValueLists];

GO









  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetValueListItems.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetValueListItems]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetValueListItems', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-26-09      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetValueListItems'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetValueListItems];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     


CREATE PROCEDURE [dbo].[spMFGetValueListItems]
    @VaultSettings NVARCHAR(4000) ,
    @valueListId NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetValueListItems];

GO








  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetWorkFlow.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetWorkFlow]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlow', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated
	                            string in @VaultSettings
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetWorkFlow'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetWorkFlow];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
    


CREATE PROCEDURE [dbo].[spMFGetWorkFlow]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFWorkflow];

GO









  
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetWorkFlowState.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetWorkFlowState]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated 
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetWorkFlowState'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetWorkFlowState];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     
CREATE PROCEDURE [dbo].[spMFGetWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @WorkFlowID NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetWorkflowStates];

GO

  
GO 
-- -------------------------------------------------------- 
-- sp.spMFSearchForObjectByPropertyValuesInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSearchForObjectByPropertyValuesInternal]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSearchForObjectByPropertyValuesInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated string in
	                            @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSearchForObjectByPropertyValuesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFSearchForObjectByPropertyValuesInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFSearchForObjectByPropertyValuesInternal]
    @VaultSettings NVARCHAR(2000) ,
    @ClassId INT ,
    @PropertyIDs NVARCHAR(2000) ,
    @PropertyValues NVARCHAR(2000) ,
    @Count INT ,
    @ResultXml NVARCHAR(MAX) OUTPUT ,
    @isFound BIT OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SearchForObjectByProperties];

GO

  
GO 
-- -------------------------------------------------------- 
-- sp.spMFSearchForObjectInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSearchForObjectInternal]';
GO

SET NOCOUNT on
  EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSearchForObjectInternal', -- nvarchar(100)
      @Object_Release = '2.1.1.0', -- varchar(50)
      @UpdateFlag = 2 -- smallint
GO
 ;
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26     DevTeam2    Removed vault settings parameters and pass them as comma separated
	                           string in @VaultSettings parameters.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSearchForObjectInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFSearchForObjectInternal]
		
    END;
	GO
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 GO
     
CREATE PROCEDURE [dbo].[spMFSearchForObjectInternal]
	@VaultSettings [NVARCHAR](4000),
	@ClassId [INT],
	@SearchText [NVARCHAR](2000),
	@Count [INT],
	@ResultXml [NVARCHAR](MAX) OUTPUT,
	@isFound [BIT] OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SearchForObject]
GO  
GO 
-- -------------------------------------------------------- 
-- sp.spMFUpdateClass.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateClass]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateClass', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update class alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateClass'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateClass];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateClass';
	 GO
     

CREATE PROCEDURE [dbo].[spMFUpdateClass]
    @VaultSettings NVARCHAR(4000) ,
    @ClassXML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateClassAliasInMFiles];



Go  
GO 
-- -------------------------------------------------------- 
-- sp.spMFUpdateProperty.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateProperty]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateProperty', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update property alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateProperty'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateProperty];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateProperty';
	 GO
     

CREATE PROCEDURE [dbo].[spMFUpdateProperty]
    @VaultSettings NVARCHAR(4000) ,
    @PropXML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdatePropertyAliasInMFiles];



GO
  
GO 
-- -------------------------------------------------------- 
-- sp.spMFUpdateObjectType.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateObjectType]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateObjectType', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update objecttype alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateObjectType'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateObjectType];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateObjectType';
	 GO
     

CREATE PROCEDURE [dbo].[spMFUpdateObjectType]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateObjectTypeAliasInMFiles];




GO
  
GO 
-- -------------------------------------------------------- 
-- sp.spMFUpdatevalueList.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdatevalueList]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdatevalueList', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update objecttype alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdatevalueList'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdatevalueList];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdatevalueList';
	 GO
     

CREATE PROCEDURE [dbo].[spMFUpdatevalueList]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateValueListAliasInMFiles];



Go  
GO 
-- -------------------------------------------------------- 
-- sp.spMFUpdateWorkFlow.sql 
-- -------------------------------------------------------- 



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateWorkFlow]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateWorkFlow', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update workflow alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateWorkFlow'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateWorkFlow];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateWorkFlow';
	 GO
     

CREATE PROCEDURE [dbo].[spMFUpdateWorkFlow]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateWorkFlowtAliasInMFiles];


  
GO 
-- -------------------------------------------------------- 
-- sp.spMFUpdateWorkFlowState.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateWorkFlowState]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update workflow alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateWorkFlowState'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUpdateWorkFlowState];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFUpdateWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateWorkFlowtStateAliasInMFiles];



GO






PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())  + '.[dbo].[spMFGetWorkFlowState]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2016-09-26      DevTeam2    Removed vault settings parameters and pass them as comma separated 
	                            string in @VaultSettings parameter
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetWorkFlowState'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetWorkFlowState];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     
CREATE PROCEDURE [dbo].[spMFGetWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @WorkFlowID NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetWorkflowStates];

GO





  
GO 
-- -------------------------------------------------------- 
-- sp.spMFCreateObjectInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreateObjectInternal]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateObjectInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	20016-09-21     DevTeam2    Removed @Username, @Password, @NetworkAddress and @VaultName and
	                Rheal       fetch this vault settings from dbo.FnMFVaultSettings() as comma 
					            separate string in @VaultSettings parameter.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFCreateObjectInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFCreateObjectInternal]
		
    END;
	GO
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 GO
     
CREATE PROCEDURE [dbo].[spMFCreateObjectInternal]
	@VaultSettings [nvarchar](4000),
	@XmlFile [nvarchar](max),
	@objVerXmlIn [nvarchar](max),
	@MFIDs [nvarchar](2000),
	@UpdateMethod [int],
	@dtModifieDateTime [datetime],
	@sLsOfID [nvarchar](max),
	@ObjVerXmlOut [nvarchar](max) OUTPUT,
	@NewObjectXml [nvarchar](max) OUTPUT,
	@SynchErrorObjects [nvarchar](max) OUTPUT,
	@DeletedObjVerXML [nvarchar](max) OUTPUT,
	@ErrorXML [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[CreateNewObject]


GO

    
GO 
-- -------------------------------------------------------- 
-- sp.spMFGetMFilesVersionInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spmfGetMFilesVersionInternal]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spmfGetMFilesVersionInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*------------------------------------------------------------------------------------------------
	Author: DevTeam2, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: CLR procedure to update workflow alias and name
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spmfGetMFilesVersionInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spmfGetMFilesVersionInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create spmfGetMFilesVersionInternal';
	 GO
     

CREATE PROCEDURE [dbo].[spmfGetMFilesVersionInternal]
    @VaultSettings NVARCHAR(4000) ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFilesVersion];

Go  
GO 
-- -------------------------------------------------------- 
-- sp.spMFDecrypt.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFDecrypt]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFDecrypt', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFDecrypt'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
       DROP PROCEDURE [dbo].[spMFDecrypt]
		
    END;
	GO
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 GO
     



CREATE PROCEDURE [dbo].[spMFDecrypt]
@EncryptedPassword NVARCHAR (2000), @DecryptedPassword NVARCHAR (2000) OUTPUT
AS EXTERNAL NAME [Laminin.Security].[Laminin.CryptoEngine].[Decrypt]

GO  
GO 
-- -------------------------------------------------------- 
-- sp.spMFSynchronizeValueListItemsToMFilesInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeValueListItemsToMFilesInternal]';
GO
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSynchronizeValueListItemsToMFilesInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO
/*------------------------------------------------------------------------------------------------
	Author: Dev2, Laminin Solutions
	Create date: 2016-10
	Database: 
	Description: CLR procedure to create objects
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeValueListItemsToMFilesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFSynchronizeValueListItemsToMFilesInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     



Create Procedure dbo.spMFSynchronizeValueListItemsToMFilesInternal
@VaultSettings [nvarchar](4000),
@XmlFile [nvarchar](max),
@Result [nvarchar](max) OutPut
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SynchValueListItems]
GO



-- -------------------------------------------------------- 
-- sp.spMFCreatePublicSharedLinkInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreatePublicSharedLinkInternal]';
GO
  
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFCreatePublicSharedLinkInternal', -- nvarchar(100)
    @Object_Release = '3.1.1.34', -- varchar(50)
    @UpdateFlag = 2 -- smallint


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFCreatePublicSharedLinkInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFCreatePublicSharedLinkInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

CREATE PROCEDURE [dbo].[spMFCreatePublicSharedLinkInternal]
    @VaultSettings NVARCHAR(max) ,
    @XML nvarchar(max) ,
    @OutputXml NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetPublicSharedLink];


GO


-- -------------------------------------------------------- 
-- sp.spMFGetMFilesLogInternal
-- -------------------------------------------------------- 

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMFilesLogInternal]';
go
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetMFilesLogInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go
/*------------------------------------------------------------------------------------------------
	Author: Dev2, Laminin Solutions
	Create date: 2017-01
	Database: 
	Description: CLR procedure to Get M-Files Log
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetMFilesLogInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetMFilesLogInternal];
		
    END;
	go
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 go
     



Create Procedure dbo.spMFGetMFilesLogInternal
@VaultSettings [nvarchar](4000),
@IsClearMFileLog bit,
@Result [nvarchar](max) OutPut
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFilesEventLog]
go

-- -------------------------------------------------------- 
-- sp.spMFGetMFilesLogInternal
-- --------------------------------------------------------   


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetFilesInternal]';
go
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetFilesInternal', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go
/*------------------------------------------------------------------------------------------------
	Author: Dev2, Laminin Solutions
	Create date: 2017-07
	Database: 
	Description: CLR procedure to Get M-Files files
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetFilesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetFilesInternal];
		
    END;
	go
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 go
     



Create Procedure dbo.spMFGetFilesInternal
@VaultSettings [nvarchar](4000) ,
@ClassID nvarchar(10),
@ObjID nvarchar(20),
@ObjType nvarchar(10),
@ObjVersion nvarchar(10),
@FilePath nvarchar(max),
@IncludeDocID nvarchar(4),
@FileExport  nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetFiles]
GO

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetHistoryInternal]';
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetHistoryInternal', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: CLR procedure to create objects
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetHistoryInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetHistoryInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
     

Create Procedure dbo.spMFGetHistoryInternal  
@VaultSettings [nvarchar](4000) ,
@ObjectType  nvarchar(10),
@ObjIDs nvarchar(max),
@PropertyIDs  nvarchar(4000),
@SearchString nvarchar(4000),
@IsFullHistory  nvarchar(4),
@NumberOfDays   nvarchar(4),
@StartDate   nvarchar(20),
@Result nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetHistory]
GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeFileToMFilesInternal]';
GO



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeFileToMFilesInternal', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Import blob file into M-files
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeFileToMFilesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFSynchronizeFileToMFilesInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
Create Procedure dbo.spMFSynchronizeFileToMFilesInternal  
@VaultSettings [nvarchar](4000) ,
@XML  nvarchar(MAX),
@Data varbinary(max),
@XMLFile nvarchar(MAX),
@FilePath nvarchar(MAX),
@Result nvarchar(max) Output,
@ErrorMsg nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[Importfile]
GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFValidateModule]';
GO



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFValidateModule', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Validate module and license
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFValidateModule'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFValidateModule];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
CREATE PROCEDURE [dbo].[spMFValidateModule]
	@VaultSettings [nvarchar](2000),
	@ModuleID [nvarchar](20),
	@Status [nvarchar](20) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ValidateModule]
GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMetadataStructureVersionIDInternal]';
GO



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetMetadataStructureVersionIDInternal', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Get latest Metadata structure version ID
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


-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetMetadataStructureVersionIDInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetMetadataStructureVersionIDInternal];
		
    END;
	GO
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 GO
CREATE PROCEDURE [dbo].[spMFGetMetadataStructureVersionIDInternal]
	@VaultSettings [nvarchar](4000),
	@Result nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMetadataStructureVersionID]
GO











GO

/*Create settings script for password setting only


*/

DECLARE @RC int

DECLARE @Password nvarchar(100) = N'{varMFPassword}'

EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] 

  @Password = @password


GO

