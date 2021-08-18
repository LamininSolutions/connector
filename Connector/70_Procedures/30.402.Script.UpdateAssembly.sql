
/*
MODIFICATIONS

2017-7-25 LC	ADD SETTING TO SET OWNER TO SA
2018-9-27 LC	Add control to check and update M-Files version. This is to allow for the CLR script to be able to be executed without running the app.
2019-1-9	lc	add additional controls to validate MFversion, exist when not exist.
2019-1-11	LC	IF version in mfsettings is different from installer then use installer 
add parameter to set MFVersion
2021-4-01   LC  get master db owner and set DB to default owner
 
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



