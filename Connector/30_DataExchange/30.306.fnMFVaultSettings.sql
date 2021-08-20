GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[FnMFVaultSettings]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'FnMFVaultSettings', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


go
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'FnMFVaultSettings'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[FnMFVaultSettings]
END	
GO
 
create FUNCTION dbo.FnMFVaultSettings ()
RETURNS VARCHAR(6000)
AS
/*rST**************************************************************************

=================
FnMFVaultSettings
=================

Return
  VaultSettings as a string

Purpose
=======

Used to return the vault settings in a string for other procedures

Examples
========

.. code:: sql

    Declare @VaultSettings nvarchar(400)
	SET @VaultSettings = fnMFVaultSettings()

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2016-09-14  DEV2       Initial Version - QA
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      DECLARE @ResultString VARCHAR(MAX)


	 select @ResultString=convert(nvarchar(128),isnull(Username,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Password,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(NetworkAddress,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(VaultName,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(MFPT.MFProtocolTypeValue,'')) from MFVaultSettings MFVS inner join MFProtocolType MFPT on MFVS.MFProtocolType_ID=MFPT.ID 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Endpoint,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(MFAT.AuthenticationTypeValue,'')) from MFVaultSettings MFVS inner join MFAuthenticationType MFAT on MFVS.MFAuthenticationType_ID=MFAT.ID 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Domain,'')) from MFVaultSettings 

      RETURN @ResultString
  END
  
  GO


  