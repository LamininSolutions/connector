   PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMfGetSettingsForConfigurator]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMfGetSettingsForConfigurator', -- nvarchar(100)
    @Object_Release = '4.9.29.74', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME IN ('spMfGetSettingsForCofigurator','spMfGetSettingsForConfigurator')--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';       
        SET NOEXEC ON;
    END;


ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].spMfGetSettingsForConfigurator
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go
ALTER   Procedure dbo.spMfGetSettingsForConfigurator
	 as
	 Begin
	 
	 DECLARE @PATH_CLR_ASSEMBLIES NVARCHAR(128) 
	
	 DECLARE @EDIT_MFVERSION_PROP NVARCHAR(128) 
	
	 DECLARE @EDIT_SQL_IMPORTFOLDER NVARCHAR(128)
	 DECLARE @EDIT_SQL_EXPORTFOLDER NVARCHAR(128)
	 DECLARE @ConnectorVersion AS VARCHAR(100)
	  

	 SELECT  @PATH_CLR_ASSEMBLIES=isnull(CONVERT(NVARCHAR(128), [ms].[Value]),'')
	 FROM   [dbo].[MFSettings] AS [ms] WHERE  [ms].[Name] = 'AssemblyInstallPath' AND [ms].[source_key] = 'App_Default'

	 SELECT  @EDIT_SQL_IMPORTFOLDER=isnull(CONVERT(nvarchar(128),[ms].[Value] ),'')
	 FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'FileTransferLocation' AND source_key	= 'Files_Default'

     SELECT  @EDIT_SQL_EXPORTFOLDER=isnull(CONVERT(nvarchar(128),[ms].[Value] ),'')
	 FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'RootFolder' AND source_key	= 'Files_Default' 

	 SELECT @EDIT_MFVERSION_PROP=isnull(CONVERT(NVARCHAR(128), [ms].[Value]),'')
	 FROM   [dbo].[MFSettings] AS [ms] 		WHERE  [ms].[Name] = 'MFVersion' AND [ms].[source_key] = 'MF_Default'


	 SELECT @ConnectorVersion= CONVERT(nvarchar(128),MAX(Release)) FROM setup.[MFSQLObjectsControl] AS [mco]

	 Select @PATH_CLR_ASSEMBLIES as AssemblyPath,
	        @EDIT_SQL_IMPORTFOLDER as ImportPath,
			@EDIT_SQL_EXPORTFOLDER as ExportPath,
			@EDIT_MFVERSION_PROP   as ClientVersion,
			@ConnectorVersion as ConnectorVersion
	End

