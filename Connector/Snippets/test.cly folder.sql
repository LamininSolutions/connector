
SELECT * FROM [dbo].[MFSettings] AS [ms]

DECLARE @FileLocation NVARCHAR(250);
DECLARE @Output NVARCHAR(MAX);
DECLARE @CLRInstallationFlag BIT = 0;
DECLARE @FileName VARCHAR(255);
DECLARE @File_Exists INT;

--test file location
SELECT @FileLocation = CAST(value AS VARCHAR(100)) FROM MFSettings WHERE name = 'AssemblyInstallPath'
SELECT @FileLocation AS filelocation


SELECT @FileName = @FileLocation + '\Laminin.Security.dll';
EXEC master.sys.xp_fileexist @FileName, @File_Exists OUT;
SELECT @File_Exists AS FileExists
IF @File_Exists = 1
BEGIN
    SET @Output = 'Assembly location Found';
    SET @CLRInstallationFlag = 1;
END;
ELSE
BEGIN
    SET @Output = 'Unable to install Assemblies, run installation on SQL Server.';
END;
SELECT @Output
