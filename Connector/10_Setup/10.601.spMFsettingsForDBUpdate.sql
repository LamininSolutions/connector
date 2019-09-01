

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
/*rST**************************************************************************

=======================
spMFsettingsForDBUpdate
=======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFInstallationPath nvarchar(128)
    fixme description
  @MFilesVersion nvarchar(128)
    fixme description
  @AssemblyInstallationPath nvarchar(128)
    fixme description
  @SQLConnectorLogin nvarchar(128)
    fixme description
  @UserRole nvarchar(128)
    fixme description
  @SupportEmailAccount nvarchar(128)
    fixme description
  @EmailProfile nvarchar(128)
    fixme description
  @DetailLogging nvarchar(128)
    fixme description
  @DBName nvarchar(128)
    fixme description
  @RootFolder nvarchar(128)
    fixme description
  @FileTransferLocation nvarchar(128)
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
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
  --select * from mfsettings

END;
 
    RETURN 1;

 GO
 