﻿




PRINT space(10) + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateAssemblies]'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFUpdateAssemblies', -- nvarchar(100)
    @Object_Release = '4.4.13.53', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFUpdateAssemblies'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    SET NOEXEC ON
GO
	PRINT SPACE(10) + '...creating a stub'
GO
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateAssemblies]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO
ALTER PROC [dbo].[spMFUpdateAssemblies]
(@MFilesVersion NVARCHAR(100) = NULL
,@Debug INT = 0
)
    
AS 


/*rST**************************************************************************

====================
spMFUpdateAssemblies
====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFilesVersion 
    - Default is null
    - if the @MFilesVersion is null, it will use the value in MFSettings, else it will reset MFSettings with the value
  @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

Update assemblies when M-Files version changes

Additional Info
===============

This procedure is compiled during installation. The procedure can only be used in the specific database.

Use the @MFilesVersion parameter to reset the MFVersion in MFSettings.  This allows for using this procedure to fix an erroneous version in the MFSettings table

It will use the MFversion in the MFsettings table to drop all CLR procedures, reload all the CLR assemblies, and reload all the CLR Procedures

Examples
========

To update the assemblies based on the MFVersion in MFSettings

.. code:: sql

    Exec spMFUpdateAssemblies

------

To update the assemblies with a different MFVersion or manually update the assemblies

.. code:: sql

    Exec spMFUpdateAssemblies @MFilesVersion = '19.8.8082.5'

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-10-07  LC         add spMFGetFilesInternal, spMFGetHistory
2021-04-01  LC         Get master db owner and set DB to default owner
2020-11-10  LC         test that all the clr procedures have been dropped
2020-11-10  LC         prevent assemblies to be deleted 
2020-10-27  LC         Refine error messages and logging
2019-09-27  LC         Add MFilesVersion parameter with default
2019-01-11  LC         IF version in mfsettings is different from installer then use installer add parameter to set MFVersion
2019-01-09	LC         Add additional controls to validate MFversion, exist when not exist.
2018-09-27  LC         Add control to check and update M-Files version. This is to allow for the CLR script to be able to be executed without running the app.
2017-07-25  LC	       ADD SETTING TO SET OWNER TO SA
2017-05-04  DevTeam2   Added new parameter DeleteWithDestroy
2016-09-26  DevTeam2   Removed vault settings parameters and pass them as comma separated string in VaultSettings parameter.
2016-03-10  LC         Created
==========  =========  ========================================================

**rST*************************************************************************/

Begin Try

/*
Script to drop all the CLR tables 
Execute before updating Assemblies
*/

IF (SELECT OBJECT_ID('dbo.spMFConnectionTestInternal')) IS null
--EXEC spmfupdateassemblies @MfilesVersion = @MFilesVersion;
RAISERROR('CLR assemblies are not available',10,1);

SET NOCOUNT ON;

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
    DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFUpdateAssemblies';
    DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = '';  

    
        SET @DebugText = N' ';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'drop all the CLR tables  ';

         IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



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

/*
MODIFICATIONS
Validate assemblies
 
*/

DECLARE @Msg                  NVARCHAR(400),
    @DBName                   VARCHAR(100) = '{varAppDB}',
    --@DBName VARCHAR(100) = '[MFSQL_Release_58]',
    @FileLocation             NVARCHAR(250),
    @MFLocation               NVARCHAR(250),
    @FrameworkLocation        NVARCHAR(250),
    @NewtonSoftJsonDependency NVARCHAR(250),
    @MFInstallPath            NVARCHAR(100),
    @Version                  NVARCHAR(100),
    @DatabaseName             NVARCHAR(100),
    @AlterDBQuery             NVARCHAR(500);
DECLARE @Output NVARCHAR(MAX);
DECLARE @CLRInstallationFlag BIT = 0;
DECLARE @FileName VARCHAR(255);
DECLARE @File_Exists INT;

      SET @DebugText = N' ';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Validateassemblies  ';

         IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



/*
Test validity of the Assembly locations before proceding with installation
*/
IF EXISTS
(
    SELECT a.name
    FROM sys.assemblies AS a
    WHERE a.name = 'Interop.MFilesAPI'
)
   AND EXISTS
(
    SELECT 1
    FROM dbo.MFSettings
)
BEGIN

    SELECT @MFInstallPath = CAST(Value AS NVARCHAR(100))
    FROM dbo.MFSettings
    WHERE Name = 'MFInstallPath';
END;

IF EXISTS
(
    SELECT 1
    FROM dbo.MFSettings
)
BEGIN
    SELECT @FileLocation = CAST(Value AS NVARCHAR(100))
    FROM dbo.MFSettings
    WHERE Name = 'AssemblyInstallPath';
END
ELSE
 SELECT @FileLocation = '{varCLRPath}';

SELECT @FileName = ISNULL(@FileLocation, '{varCLRPath}') + 'Laminin.Security.dll';

EXEC master.sys.xp_fileexist @FileName, @File_Exists OUT;

IF @File_Exists = 1
BEGIN
    SET @Output = N'Assembly location Found: ' + ISNULL(@FileLocation, '{varCLRPath}');

    RAISERROR(@Output, 10, 1);

    SET @CLRInstallationFlag = 1;
END;
ELSE
BEGIN
    SET @Output = N'Unable to install Assemblies, check access to filelocation, run installation on SQL Server.';
    SET @CLRInstallationFlag = 0;

    RAISERROR(@Output, 16, 1);
END;

/*
Test validity of M-Files API folder
*/
DECLARE @IsUpdateAssembly BIT;

IF ISNULL(@MFilesVersion, '') = ''
    SELECT @Version = CAST(Value AS VARCHAR)
    FROM dbo.MFSettings
    WHERE Name = 'MFVersion';
ELSE
BEGIN

    SET @Version = @MFilesVersion
    UPDATE dbo.MFSettings
    SET value = @Version
    WHERE Name = 'MFVersion'
    ;
END
SET @MFLocation
    = ISNULL(@MFInstallPath, '{varMFInstallPath}') + N'\' + ISNULL(@Version, '{varMFVersion}') + N'\Common';
SET @DatabaseName = N'dbo.' + @DBName;

SELECT @FileName = @MFLocation + '\Interop.MFilesAPI.dll';

EXEC master.sys.xp_fileexist @FileName, @File_Exists OUT;

IF @File_Exists = 1
   AND @CLRInstallationFlag = 1
BEGIN
    SET @Output = N'M-Files API Found: ' + @FileName;

    RAISERROR(@Output, 10, 1);

    SET @CLRInstallationFlag = 1;
END;

IF @File_Exists = 0
BEGIN
    SET @Output = @Output + N'; Unable to find M-Files Client installation, missing M-Files client ' + @FileName;
    SET @CLRInstallationFlag = 0;

    RAISERROR('%s', 10, 1, @Output);
END;

IF @CLRInstallationFlag = 1
BEGIN

DECLARE @DBowner sysname
SELECT @DBowner = SUSER_SNAME(owner_sid) 
FROM sys.databases WHERE name = 'master' 

IF(SELECT SUSER_SNAME(owner_sid) 
FROM sys.databases WHERE name = @DBName ) <> @DBowner
 Begin
 SET @Msg = 'Change database owner to ' + @DBowner
    EXEC sys.sp_changedbowner @DBowner;
    RAISERROR('%s', 10, 1, @Msg);
    END

SET @Msg = 'Drop assemblies'
RAISERROR('%s', 10, 1, @Msg);

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

	    IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'Newtonsoft.Json')
    BEGIN
        PRINT 'Dropping ASSEMBLY: Newtonsoft.Json';

        DROP ASSEMBLY [Newtonsoft.Json];
    END;

    IF EXISTS
    (
        SELECT *
        FROM sys.assemblies
        WHERE name = 'System.Runtime.Serialization'
    )
    BEGIN
        PRINT 'Dropping ASSEMBLY: System.Runtime.Serialization ';

        DROP ASSEMBLY [System.Runtime.Serialization];
    END;

    IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'Newtonsoft.Json')
    BEGIN
        PRINT 'Dropping ASSEMBLY: Newtonsoft.Json';

        DROP ASSEMBLY [Newtonsoft.Json];
    END;

    IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'SMDiagnostics')
    BEGIN
        PRINT 'Dropping ASSEMBLY: Newtonsoft.Json';

        DROP ASSEMBLY SMDiagnostics;
    END;

    IF EXISTS
    (
        SELECT *
        FROM sys.assemblies
        WHERE name = 'System.ServiceModel.Internals'
    )
    BEGIN
        PRINT 'Dropping ASSEMBLY: System.ServiceModel.Internals';

        DROP ASSEMBLY [System.ServiceModel.Internals];
    END;

    --------------------------------------------------
    --ENABLE CLR
    --------------------------------------------------
    EXEC sys.sp_configure 'clr enabled', 1;

    RECONFIGURE;

    EXEC sys.sp_configure 'clr enabled';

    ALTER DATABASE [{varAppDB}] SET TRUSTWORTHY ON;

    SET @Msg = 'Create assemblies'
RAISERROR('%s', 10, 1, @Msg);

 SET @Msg = @MFLocation + '\Interop.MFilesAPI.dll'
RAISERROR('%s', 10, 1, @Msg);

    --  EXECUTE (@AlterDBQuery);
    CREATE ASSEMBLY [Interop.MFilesAPI]
    FROM @MFLocation + '\Interop.MFilesAPI.dll'
    WITH PERMISSION_SET = UNSAFE;

SET @Msg = @FileLocation + 'Laminin.Security.dll'
RAISERROR('%s', 10, 1, @Msg);

    CREATE ASSEMBLY [Laminin.Security]
    FROM @FileLocation + 'Laminin.Security.dll'
    WITH PERMISSION_SET = SAFE;

SET @Msg = @FileLocation + 'LSConnectMFilesAPIWrapper.dll'
RAISERROR('%s', 10, 1, @Msg);

    CREATE ASSEMBLY LSConnectMFilesAPIWrapper
    FROM @FileLocation + 'LSConnectMFilesAPIWrapper.dll'
    WITH PERMISSION_SET = UNSAFE;

SET @Msg = @FileLocation + 'LSConnectMFilesAPIWrapper.XmlSerializers.dll'
RAISERROR('%s', 10, 1, @Msg);

    CREATE ASSEMBLY CLRSerializer
    FROM @FileLocation + 'LSConnectMFilesAPIWrapper.XmlSerializers.dll'
    WITH PERMISSION_SET = UNSAFE;

END;

IF @CLRInstallationFlag = 0
    RAISERROR(@Output, 16, 1);





--THIS COLLECTION OF PROCEDURES CREATE ALL THE CLR PROCEDURES


-- -------------------------------------------------------- 
-- sp.spMFEncrypt.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFEncrypt]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFEncrypt', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFEncrypt]
@Password NVARCHAR (2000), @EcryptedPassword NVARCHAR (2000) OUTPUT
AS EXTERNAL NAME [Laminin.Security].[Laminin.CryptoEngine].[Encrypt]
')

  
 
-- -------------------------------------------------------- 
-- sp.spMFGetClass.sql 
-- -------------------------------------------------------- 

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetClass]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFGetClass', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetClass]
    @VaultSettings NVARCHAR(4000) ,
    @ClassXML NVARCHAR(MAX) OUTPUT ,
    @ClassPptXML NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFClasses];
	')

-- -------------------------------------------------------- 
-- sp.spMFGetLoginAccounts.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetLoginAccounts]';

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetLoginAccounts', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetLoginAccounts]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetLoginAccounts];
	');

-- -------------------------------------------------------- 
-- sp.spMFGetDataExportInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetDataExportInternal]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetDataExportInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFGetDataExportInternal]
    @VaultSettings NVARCHAR(4000) ,
    @ExportDatasetName NVARCHAR(2000) ,
    @IsExported BIT OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ExportDataSet];
');








  
 
-- -------------------------------------------------------- 
-- sp.spMFGetObjectType.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetObjectType]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetObjectType', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetObjectType]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetObjectTypes];
');









  
 
-- -------------------------------------------------------- 
-- sp.spMFGetObjectVersInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetObjectVersInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetObjectVersInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetObjectVersInternal]
	@VaultSettings [nvarchar](4000),
	@ClassID [int],
	@dtModifieDateTime [datetime],
	@MFIDs [nvarchar](max),
	@ObjverXML [nvarchar](max) OUTPUT,
    @DelObjverXML [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetOnlyObjectVersions]
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFGetProperty.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetProperty]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetProperty', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetProperty]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetProperties];
');









  
 
-- -------------------------------------------------------- 
-- sp.spMFGetUserAccounts.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetUserAccounts]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetUserAccounts', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetUserAccounts]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetUserAccounts];
');






  
 
-- -------------------------------------------------------- 
-- sp.spMFGetValueList.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetValueList]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetValueList', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
 EXEC (N'    
CREATE PROCEDURE [dbo].[spMFGetValueList]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetValueLists];
');










  
 
-- -------------------------------------------------------- 
-- sp.spMFGetValueListItems.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetValueListItems]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetValueListItems', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetValueListItems]
    @VaultSettings NVARCHAR(4000) ,
    @valueListId NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetValueListItems];
');









  
 
-- -------------------------------------------------------- 
-- sp.spMFGetWorkFlow.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetWorkFlow]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlow', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
    

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetWorkFlow]
    @VaultSettings NVARCHAR(4000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFWorkflow];
');










  
 
-- -------------------------------------------------------- 
-- sp.spMFGetWorkFlowState.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetWorkFlowState]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFGetWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @WorkFlowID NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetWorkflowStates];

');

  
 
-- -------------------------------------------------------- 
-- sp.spMFSearchForObjectByPropertyValuesInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSearchForObjectByPropertyValuesInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSearchForObjectByPropertyValuesInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFSearchForObjectByPropertyValuesInternal]
    @VaultSettings NVARCHAR(2000) ,
    @ClassId INT ,
    @PropertyIDs NVARCHAR(2000) ,
    @PropertyValues NVARCHAR(2000) ,
    @Count INT ,
	@isEqual INT,
    @ResultXml NVARCHAR(MAX) OUTPUT ,
    @isFound BIT OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SearchForObjectByProperties];
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFSearchForObjectInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSearchForObjectInternal]';


SET NOCOUNT on
  EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSearchForObjectInternal', -- nvarchar(100)
      @Object_Release = '2.1.1.0', -- varchar(50)
      @UpdateFlag = 2 -- smallint

 ;

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
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
EXEC (N'     
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
 '); 
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateClass.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateClass]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateClass', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateClass';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateClass]
    @VaultSettings NVARCHAR(4000) ,
    @ClassXML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateClassAliasInMFiles];
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateProperty.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateProperty]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateProperty', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateProperty';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateProperty]
    @VaultSettings NVARCHAR(4000) ,
    @PropXML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdatePropertyAliasInMFiles];
');



  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateObjectType.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateObjectType]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateObjectType', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateObjectType';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateObjectType]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateObjectTypeAliasInMFiles];
');




  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdatevalueList.sql 
-- -------------------------------------------------------- 


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdatevalueList]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdatevalueList', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdatevalueList';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdatevalueList]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateValueListAliasInMFiles];
');


  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateWorkFlow.sql 
-- -------------------------------------------------------- 



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateWorkFlow]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateWorkFlow', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFUpdateWorkFlow';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateWorkFlow]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateWorkFlowtAliasInMFiles];
');

  
 
-- -------------------------------------------------------- 
-- sp.spMFUpdateWorkFlowState.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateWorkFlowState]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUpdateWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUpdateWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @XML NVARCHAR(MAX)  ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UpdateWorkFlowtStateAliasInMFiles];
');









PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())  + '.[dbo].[spMFGetWorkFlowState]';


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetWorkFlowState', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
EXEC (N'     
CREATE PROCEDURE [dbo].[spMFGetWorkFlowState]
    @VaultSettings NVARCHAR(4000) ,
    @WorkFlowID NVARCHAR(2000) ,
    @returnVal NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetWorkflowStates];
');






  
 
-- -------------------------------------------------------- 
-- sp.spMFCreateObjectInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreateObjectInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateObjectInternal', -- nvarchar(100)
    @Object_Release = '4.5.14.56', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	2019-12-31      LC			Add new output param - checkedoutobjects
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
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
 EXEC (N'    
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
	@ErrorXML [nvarchar](max) OUTPUT,
	@CheckOutObjects [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[CreateNewObject]
');



    
 
-- -------------------------------------------------------- 
-- sp.spMFGetMFilesVersionInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spmfGetMFilesVersionInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spmfGetMFilesVersionInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create spmfGetMFilesVersionInternal';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spmfGetMFilesVersionInternal]
    @VaultSettings NVARCHAR(4000) ,
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFilesVersion];
');
  
 
-- -------------------------------------------------------- 
-- sp.spMFDecrypt.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFDecrypt]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFDecrypt', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

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
	
    
	 PRINT SPACE(10) + '...Stored Procedure: create'
	 
     


EXEC (N'
CREATE PROCEDURE [dbo].[spMFDecrypt]
@EncryptedPassword NVARCHAR (2000), @DecryptedPassword NVARCHAR (2000) OUTPUT
AS EXTERNAL NAME [Laminin.Security].[Laminin.CryptoEngine].[Decrypt]
');
  
 
-- -------------------------------------------------------- 
-- sp.spMFSynchronizeValueListItemsToMFilesInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeValueListItemsToMFilesInternal]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSynchronizeValueListItemsToMFilesInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     


EXEC (N'
Create Procedure dbo.spMFSynchronizeValueListItemsToMFilesInternal
@VaultSettings [nvarchar](4000),
@XmlFile [nvarchar](max),
@Result [nvarchar](max) OutPut
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[SynchValueListItems]
');



-- -------------------------------------------------------- 
-- sp.spMFCreatePublicSharedLinkInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFCreatePublicSharedLinkInternal]';

  
 
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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFCreatePublicSharedLinkInternal]
    @VaultSettings NVARCHAR(max) ,
    @XML nvarchar(max) ,
    @OutputXml NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetPublicSharedLink];
');




-- -------------------------------------------------------- 
-- sp.spMFGetMFilesLogInternal
-- -------------------------------------------------------- 

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMFilesLogInternal]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetMFilesLogInternal', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     


EXEC (N'
Create Procedure dbo.spMFGetMFilesLogInternal
@VaultSettings [nvarchar](4000),
@IsClearMFileLog bit,
@Result [nvarchar](max) OutPut
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMFilesEventLog]
');

-- -------------------------------------------------------- 
-- sp.spMFGetFilesInternal
-- --------------------------------------------------------   


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetFilesInternal]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetFilesInternal', -- nvarchar(100)
    @Object_Release = '4.9.26.67', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

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
--IF EXISTS ( SELECT  1
--            FROM    INFORMATION_SCHEMA.ROUTINES
--            WHERE   ROUTINE_NAME = 'spMFGetFilesInternal'--name of procedure
--                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
--                    AND ROUTINE_SCHEMA = 'dbo' )
--    BEGIN
--        PRINT SPACE(10) + '...Drop CLR Procedure';
--        DROP PROCEDURE [dbo].[spMFGetFilesInternal];
		
--    END;
	
    
--PRINT SPACE(10) + '...Stored Procedure: create';
	 
     


--EXEC (N'
--Create Procedure dbo.spMFGetFilesInternal
--@VaultSettings [nvarchar](4000) ,
--@ClassID nvarchar(10),
--@ObjID nvarchar(20),
--@ObjType nvarchar(10),
--@ObjVersion nvarchar(10),
--@FilePath nvarchar(max),
--@IsDownload bit,
--@IncludeDocID bit,
--@FileExport  nvarchar(max) Output
--WITH EXECUTE AS CALLER
--AS
--EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetFiles]
--');


-- -------------------------------------------------------- 
-- sp.spMFGetFilesListInternal
-- --------------------------------------------------------   


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetFilesListInternal]';

 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetFilesListInternal', -- nvarchar(100)
    @Object_Release = '4.9.26.67', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 

/*------------------------------------------------------------------------------------------------
	Author: LC, Laminin Solutions
	Create date: 2021-01
	Database: 
	Description: CLR procedure to Get list of files
------------------------------------------------------------------------------------------------*/

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetFilesListInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetFilesListInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
EXEC (N'
Create Procedure dbo.spMFGetFilesListInternal
@VaultSettings [nvarchar](4000) ,
@XMLInput nvarchar(max),
@IsDownload bit,
@IncludeDocID bit,
@FileExport  nvarchar(max) Output
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetFilesList]
');



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetHistoryInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetHistoryInternal', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
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
');


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeFileToMFilesInternal]';




SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeFileToMFilesInternal', -- nvarchar(100)
    @Object_Release = '3.1.5.42', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Import files into M-files
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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	
EXEC (N'	 
Create Procedure dbo.spMFSynchronizeFileToMFilesInternal  
@VaultSettings [nvarchar](4000) ,
@FileName  nvarchar(MAX),
@XMLFile nvarchar(MAX),
@FilePath nvarchar(MAX),
@Result nvarchar(max) Output,
@ErrorMsg nvarchar(max) Output,
@IsFileDelete INT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[Importfile]
');


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFImportBlobFileToMFilesInternal]';




SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFImportBlobFileToMFilesInternal', -- nvarchar(100)
    @Object_Release = '4.6.17.58', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: , Laminin Solutions
	Create date: 2020-04
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
            WHERE   ROUTINE_NAME = 'spMFImportBlobFileToMFilesInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].spMFImportBlobFileToMFilesInternal;
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	
EXEC (N'	 
Create Procedure dbo.spMFImportBlobFileToMFilesInternal  
@VaultSettings [nvarchar](4000) ,
@XML nvarchar(MAX),
@Data  VARBINARY(MAX),
@XMLStr nvarchar(MAX),
@FileLocation nvarchar(MAX),
@Result nvarchar(max) OUT,
@ErrorMsg nvarchar(max) OUT

WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ImportBlobfile]
');


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFValidateModule]';




SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFValidateModule', -- nvarchar(100)
    @Object_Release = '4.10.30.74', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';

EXEC (N'	 
CREATE PROCEDURE [dbo].[spMFValidateModule]
	@VaultSettings [nvarchar](2000),
	@ModuleID [nvarchar](20),
	@Status [nvarchar](100) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ValidateModule]
');


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMetadataStructureVersionIDInternal]';




SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetMetadataStructureVersionIDInternal', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint


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
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
EXEC (N'	 
CREATE PROCEDURE [dbo].[spMFGetMetadataStructureVersionIDInternal]
	@VaultSettings [nvarchar](4000),
	@Result nvarchar(max) Output,
	@ValidGuid nvarchar(max) Output

WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetMetadataStructureVersionID]
');



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetUnManagedObjectDetails', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: ,DevTeam2 Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: CLR procedure to Get UnManaged object Details
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
            WHERE   ROUTINE_NAME = 'spMFGetUnManagedObjectDetails'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetUnManagedObjectDetails];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetUnManagedObjectDetails]
	@ExternalRepositoryObjectID [NVARCHAR](MAX),
	@VaultSettings [nvarchar](4000),
	@Result [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetUnManagedObjectDetails]
');



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetDeletedObjectsInternal', -- nvarchar(100)
    @Object_Release = '4.3.10.49', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: ,DevTeam2 Laminin Solutions
	Create date: 2019-07
	Database: 
	Description: CLR procedure to Get deleted object Details
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
            WHERE   ROUTINE_NAME = 'spMFGetDeletedObjectsInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFGetDeletedObjectsInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';

EXEC (N'
CREATE PROCEDURE [dbo].[spMFGetDeletedObjectsInternal]
	@VaultSettings [nvarchar](4000),
	@ClassID [int],
	@LastModifiedDate [DateTime],
	@outputXML [nvarchar](max) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetDeletedObjects]
');

-- -------------------------------------------------------- 
-- sp.spMFGetMFilesVersionInternal.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spmfGetLocalMFilesVersionInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spmfGetLocalMFilesVersionInternal', -- nvarchar(100)
    @Object_Release = '4.5.15.56', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: LC, Laminin Solutions
	Create date: 2020-02
	Database: 
	Description: CLR procedure to get M-Files version on SQL server
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


-- ---------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spmfGetLocalMFilesVersionInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spmfGetMFilesVersionInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spmfGetLocalMFilesVersionInternal';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spmfGetLocalMFilesVersionInternal]
    @Result NVARCHAR(MAX) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[GetLocalMFilesVersion];
');
  
 
 
-- -------------------------------------------------------- 
-- sp.spMFConnectionTest.sql 
-- -------------------------------------------------------- 
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFConnectionTestInternal]';



SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFConnectionTestInternal', -- nvarchar(100)
    @Object_Release = '4.7.20.60', -- varchar(50)
    @UpdateFlag = 2 -- smallint


/*------------------------------------------------------------------------------------------------
	Author: LC, Laminin Solutions
	Create date: 2020-02
	Database: 
	Description: CLR procedure to test a connection to the vault
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


-- ---------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFConnectionTestInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].spMFConnectionTestInternal;
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create spMFConnectionTestInternal';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFConnectionTestInternal]
    @VaultSetting NVARCHAR(400), @TestResult int OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[ConnectionTest];
');
  
  /*------------------------------------------------------------------------------------------------
	Author: LC, Laminin Solutions
	Create date: 2020-02
	Database: 
	Description: CLR procedure to delete list of ojects
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


-- ---------------------------------------------------------------------------------------------*/
 SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFDeleteObjectListInternal', -- nvarchar(100)
    @Object_Release = '4.8.24.66', -- varchar(50)
    @UpdateFlag = 2 -- smallint


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFDeleteObjectListInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFDeleteObjectInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFDeleteObjectListInternal]
    @VaultSettings NVARCHAR(4000) ,
    @XML nvarchar(max),    
    @XMLOut NVARCHAR(max) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[DeleteObjectList];
')
 

 
  /*------------------------------------------------------------------------------------------------
	Author: LC, Laminin Solutions
	Create date: 2022-02
	Database: 
	Description: CLR procedure to undeletedelete list of ojects
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


-- ---------------------------------------------------------------------------------------------*/
 SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',     @ObjectName = N'spMFUnDeleteObjectListInternal', -- nvarchar(100)
    @Object_Release = '4.9.29.73', -- varchar(50)
    @UpdateFlag = 2 -- smallint


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUnDeleteObjectListInternal'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Drop CLR Procedure';
        DROP PROCEDURE [dbo].[spMFUnDeleteObjectInternal];
		
    END;
	
    
PRINT SPACE(10) + '...Stored Procedure: create';
	 
     
EXEC (N'
CREATE PROCEDURE [dbo].[spMFUnDeleteObjectListInternal]
    @VaultSettings NVARCHAR(4000) ,
    @XML nvarchar(max),    
    @XMLOut NVARCHAR(max) OUTPUT
AS EXTERNAL NAME
    [LSConnectMFilesAPIWrapper].[MFilesWrapper].[UnDeleteObjectList];
')
 








      SET @DebugText = N' ';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Finalise update assemblies  ';

         IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;


EXEC dbo.spMFDeploymentDetails @Type = 0

SET NOCOUNT OFF;
RETURN 0;
END TRY
BEGIN CATCH

EXEC dbo.spMFDeploymentDetails @Type = -1

	DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
	DECLARE @ErrorNumber INT
	DECLARE @ErrorLine INT
	DECLARE @ErrorProcedure NVARCHAR(128)
	DECLARE @OptionalMessage VARCHAR(max)

	SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
		@ErrorNumber = ERROR_NUMBER(),
		@ErrorLine = ERROR_LINE(),
		@ErrorProcedure=ERROR_PROCEDURE()

	IF @@TRANCOUNT <> 0
	BEGIN
		ROLLBACK TRAN;
	END	
	
	SET NOCOUNT OFF;

    RAISERROR ( @ErrorMessage, -- Message text.
				@ErrorSeverity, -- Severity.
				@ErrorState -- State.
               );
	

	RETURN -1

END CATCH

GO


