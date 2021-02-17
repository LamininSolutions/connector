
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFValidateEmailProfile]';
GO

SET NOCOUNT ON;
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFValidateEmailProfile', -- nvarchar(100)
    @Object_Release = '4.9.26.67',              -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

 
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFValidateEmailProfile' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFValidateEmailProfile]
AS
    SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROC [dbo].[spMFValidateEmailProfile]
    @emailProfile NVARCHAR(100) OUTPUT,
    @debug SMALLINT = 0
AS

/*rST**************************************************************************

========================
spMFValidateEmailProfile
========================

Return
  - 1 = Profile is valid
  - -1 = Profile is invalid and no default profile exists
Parameters
  @emailProfile
   - if null is passed or the value passed in is invalid then the default profile will be returned
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To validate the email profile or return the default profile from the settings table MFSettings.

Additional info
===============

This procedure will test any profile. if the parameter is null, it would automatically return the default profile, if the paramater is another profile, then it would return the default profile if the parameter profile is invalid, if both parameter profile is invalid and the default profile is invalid, it will return an error.

Examples
========

 .. code:: sql

    exec spmfvalidateEmailProfile 'MailProfile'  

Using a custom profile that is not the default profile

.. code:: sql

    DECLARE @profile NVARCHAR(100) = 'TestProfile'
    EXEC spMFValidateEmailProfile @emailProfile = @profile OUTPUT
    SELECT @profile

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-01-20  LC         Allow for multiple profiles
2017-05-01  LC         Fix validate profile
2016-10-12  LC         Change Settings Name
2016-08-22  LC         update settings index
2015-12-10  AC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


    SET NOCOUNT ON;

    DECLARE @ErrorMessage VARCHAR(100);
    DECLARE @Return INT;

    BEGIN TRY

    IF @emailProfile IS NOT null
    BEGIN --email profile not null
    
    IF NOT EXISTS (
    SELECT p.name
                     FROM msdb.dbo.sysmail_account a
                         INNER JOIN msdb.dbo.sysmail_profileaccount pa
                             ON a.account_id = pa.account_id
                         INNER JOIN msdb.dbo.sysmail_profile p
                             ON pa.profile_id = p.profile_id
                             WHERE p.name = @emailProfile
        ) 
        SET @emailProfile = null
    END --email profile not null

        IF EXISTS
        (
            SELECT Value
            FROM dbo.MFSettings
                INNER JOIN
                 (
                     SELECT p.name
                     FROM msdb.dbo.sysmail_account a
                         INNER JOIN msdb.dbo.sysmail_profileaccount pa
                             ON a.account_id = pa.account_id
                         INNER JOIN msdb.dbo.sysmail_profile p
                             ON pa.profile_id = p.profile_id
                 ) ep
                    ON [ep].[name] = CONVERT(VARCHAR(100), [MFSettings].Value)
            WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                  AND dbo.MFSettings.[source_key] = 'Email'
        ) --AND @emailProfile IS null
        BEGIN

            SELECT @emailProfile = CONVERT(VARCHAR(100), [MFSettings].Value)
            FROM dbo.MFSettings
            WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                  AND dbo.MFSettings.[source_key] = 'Email';

            IF @debug > 1
                SELECT @emailProfile AS mailprofile;

          END
                IF @emailProfile IS NOT null
                SET @Return = 1;
   
            IF @debug > 1
                SELECT Value
                FROM dbo.MFSettings
                WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                      AND dbo.MFSettings.[source_key] = 'Email';

IF @emailProfile IS NULL
BEGIN -- email profile null
            SELECT TOP 1
                @emailProfile = p.name
            FROM msdb.dbo.sysmail_account a
                INNER JOIN msdb.dbo.sysmail_profileaccount pa
                    ON a.account_id = pa.account_id
                INNER JOIN msdb.dbo.sysmail_profile p
                    ON pa.profile_id = p.profile_id;
            --				where p.name = 'X';
 
 IF @debug > 0 
      SELECT @emailProfile AS mailprofile;

 END -- email profile null

  IF @emailProfile IS NULL
			BEGIN -- email profile is null
  SET @ErrorMessage = 'Email profile is invalid'
            SET @Return = -1
                RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage)
				
				END; -- end email profile is null

    IF ISNULL((SUBSTRING(@emailProfile, 1, 1)), '$') = '$'
            BEGIN
                SET @ErrorMessage = 'No Valid Email profile exists';
                RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage);

                SET @Return = -1;
     END;
        RETURN @Return;

    END TRY
    BEGIN CATCH
        RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage);
        RETURN -1;

    END CATCH;

GO

