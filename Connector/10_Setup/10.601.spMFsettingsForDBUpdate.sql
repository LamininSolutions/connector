

GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSettingsForDBUpdate]';
GO

SET NOCOUNT on
  EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFSettingsForDBUpdate', -- nvarchar(100)
      @Object_Release = '4.4.14.55', -- varchar(50)
      @UpdateFlag = 2 -- smallint
;
/*
------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
------------------------------------------------------------------------------------------------
*/

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
   
	  @MFInstallationPath NVARCHAR(128) = null , 
      @MFilesVersion NVARCHAR(128) = null ,
      @AssemblyInstallationPath NVARCHAR(128) = null ,
      @SQLConnectorLogin NVARCHAR(128) = null,
      @UserRole NVARCHAR(128) = null ,
      @SupportEmailAccount NVARCHAR(128) = null ,
      @EmailProfile NVARCHAR(128) = null ,
	  @DetailLogging nvarchar(128) = null,
	  @UserMessageEnabled NVARCHAR(128) = null,
      @DBName nvarchar(128) = null,
	  @RootFolder nvarchar(128) = null,
	  @FileTransferLocation nvarchar(128) = null,
	  @Debug SMALLINT = 0
    )
AS
/*rST**************************************************************************

=======================
spMFsettingsForDBUpdate
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFInstallationPath nvarchar(128)
    - Path where M-Files is installed on SQL server
    - Default assigned by installer 'C:\Program Files\M-Files'
  @MFilesVersion nvarchar(128)
    - M-Files version deployed on SQL server
    - Format '11.2.4320.51'
  @AssemblyInstallationPath nvarchar(128)
    - Path where the Laminin Assemblies have been copied to.
    - Default assigned by installer 'C:\MFSQL\Assemblies'
  @SQLConnectorLogin nvarchar(128)
    - SQL login user for the Connector
    - Default assigned by installer 'MFSQLConnect'
  @UserRole nvarchar(128)
    - Role for SQL user
    - Default assigned by installer 'AppUserRole'
  @SupportEmailAccount nvarchar(128)
    - Email to receive system error emails
    - Default assigned by installer 'support@lamininsolutions.com', semi colon separated for multiple emails
    - Depended on installing Database Mail
  @EmailProfile nvarchar(128)
    - DBMail profile to be used for emails
    - Default assigned by installer 'LSEmailProfile'
    - Depended on Database Mail installation
  @DetailLogging nvarchar(128)
    - 1 = include detail logging
    - Default of 1 assigned by installer
  @UserMessageEnabled nvarchar(128)
    - 1 = messages enabled
	- Default is set to 0 - not enabled
  @DBName nvarchar(128)
    - Connector database name
    - Assigned by installer
  @RootFolder nvarchar(128)
    - Base folder for exporting of files
    - Default assigned by installer 'C:\MFSQL\FileExport'
  @FileTransferLocation nvarchar(128)
    - Base folder for importing files
    - Default assigned by installer 'C:\MFSQL\FileImport'
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Procedure to allow updating of specific settings in the MFSettings table

Additional Info
===============

Include only the the items that need to be changed.
Refer to MFSettings for more information on the use of the settings.

Prerequisites
=============

Email functions is dependent on Database Mail being installed.

Warnings
========

Settings have an impact throughout the Connector.

Examples
========

.. code:: sql

    EXEC [spMFSettingsForDBUpdate]  @SupportEmailAccount = 'YourEmailAccount'
    select * from mfsettings where name = 'SupportEmailRecipient'

.. code:: sql

    DECLARE @RC int
    DECLARE @MFInstallationPath nvarchar(128)
    DECLARE @MFilesVersion nvarchar(128) 
    DECLARE @AssemblyInstallationPath nvarchar(128)
    DECLARE @SQLConnectorLogin nvarchar(128)
    DECLARE @UserRole nvarchar(128)
    DECLARE @SupportEmailAccount nvarchar(128) = 'mfsql@lamininsolutions.com'
    DECLARE @EmailProfile nvarchar(128)
    DECLARE @DetailLogging nvarchar(128)
    DECLARE @DBName nvarchar(128)
    DECLARE @RootFolder nvarchar(128)
    DECLARE @FileTransferLocation nvarchar(128)
    DECLARE @Debug smallint

    EXECUTE @RC = [dbo].[spMFSettingsForDBUpdate] 
    @MFInstallationPath
    ,@MFilesVersion
    ,@AssemblyInstallationPath
    ,@SQLConnectorLogin
    ,@UserRole
    ,@SupportEmailAccount
    ,@EmailProfile
    ,@DetailLogging
    ,@DBName
    ,@RootFolder
    ,@FileTransferLocation
    ,@Debug

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-11-27  LC         Add parameter for setting User message enabled
2019-08-30  JC         Added documentation
2018-04-28  LC         Add user message setting; vault structure setting
2018-02-16  LC         Add file import and export change setting
2017-11-23  LC         Resolve bug for missing value
2017-09-02  LC         Add RootFolder setting
2016-08-22  LC         Change Settings index
==========  =========  ========================================================

**rST*************************************************************************/

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

	
	IF @UserMessageEnabled IS NOT null
			UPDATE [dbo].[MFSettings]
			SET value = @UserMessageEnabled
	FROM mfsettings WHERE name = 'MFUserMessagesEnabled' AND [source_key] = 'APP_Default'

	
END;
 
    RETURN 1;

 GO
 