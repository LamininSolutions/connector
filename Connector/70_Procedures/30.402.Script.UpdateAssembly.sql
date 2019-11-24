
/*
MODIFICATIONS

2017-7-25 LC	ADD SETTING TO SET OWNER TO SA
2018-9-27 LC	Add control to check and update M-Files version. This is to allow for the CLR script to be able to be executed without running the app.
2019-1-9	lc	add additional controls to validate MFversion, exist when not exist.
2019-1-11	LC	IF version in mfsettings is different from installer then use installer 
add parameter to set MFVersion
 
*/


DECLARE @Msg NVARCHAR(400),
        @DBName VARCHAR(100) = '{varAppDB}',
        @FileLocation NVARCHAR(250) ,
        @MFLocation NVARCHAR(250),
        @MFInstallPath NVARCHAR(100) ,
        @Version NVARCHAR(100) ,
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


SELECT @FileName = ISNULL(@FileLocation,'{varCLRPath}') + '\Laminin.Security.dll';
EXEC master.sys.xp_fileexist @FileName, @File_Exists OUT;
IF @File_Exists = 1
BEGIN
    SET @Output = 'Assembly location Found: '+ ISNULL(@FileLocation,'{varCLRPath}');
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

DECLARE @IsUpdateAssembly BIT


IF ISNULL(@MFilesVersion,'') = ''
SELECT @Version = CAST(value AS varchar) FROM MFSettings WHERE name = 'MFVersion'
ELSE
SET @Version = @MFilesVersion;

SET @MFLocation = ISNULL(@MFInstallPath,'{varMFInstallPath}') + '\' + ISNULL(@Version,'{varMFVersion}') + '\Common';
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
IF @File_Exists = 0
BEGIN
    SET @Output
        = @Output
          + '; Unable to find M-Files Client installation, missing M-Files client '+ @FileName;
    SET @CLRInstallationFlag = 0;
	 RAISERROR('%s', 10, 1, @Output);
END;
IF @CLRInstallationFlag = 1
BEGIN

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

