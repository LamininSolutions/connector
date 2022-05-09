GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[FnMFVaultSettings]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'FnMFVaultSettings', -- nvarchar(100)
    @Object_Release = '2.9.28.73', -- varchar(50)
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
2021-12-20  LC         Add guid to vault settings string
2019-08-30  JC         Added documentation
2016-09-14  DEV2       Initial Version - QA
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      DECLARE @ResultString VARCHAR(MAX)
      DECLARE @Guid NVARCHAR(128)


      SELECT @Guid =CAST(value AS NVARCHAR(128)) FROM mfsettings WHERE name = 'VaultGUID'

	 select @ResultString=convert(nvarchar(128),isnull(Username,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Password,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(NetworkAddress,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(VaultName,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(MFPT.MFProtocolTypeValue,'')) 
     FROM MFVaultSettings MFVS inner join MFProtocolType MFPT on MFVS.MFProtocolType_ID=MFPT.ID 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Endpoint,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(MFAT.AuthenticationTypeValue,'')) from MFVaultSettings MFVS inner join MFAuthenticationType MFAT on MFVS.MFAuthenticationType_ID=MFAT.ID 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Domain,'')) from MFVaultSettings 

     select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(@Guid,''))  

      RETURN @ResultString
  END
  
  GO


  