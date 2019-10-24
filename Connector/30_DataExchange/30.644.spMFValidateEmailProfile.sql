
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFValidateEmailProfile]';
GO

SET NOCOUNT ON;
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFValidateEmailProfile', -- nvarchar(100)
    @Object_Release = '3.1.1.32',              -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: Arnie Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: Performs Vendor Renumbering based on values in apVendorRenumber_vw
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		LC			update settings index
	2016-10-12		LC			Change Settings Name
	2017-5-1		LC			Fix validate profile
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  exec spmfvalidateEmailProfile 'MailProfile'
  
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
    SET NOCOUNT ON;

    DECLARE @ErrorMessage VARCHAR(100);

    DECLARE @Return INT;

    BEGIN TRY

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
        )
        BEGIN

            SELECT @emailProfile = CONVERT(VARCHAR(100), [MFSettings].Value)
            FROM dbo.MFSettings
            WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                  AND dbo.MFSettings.[source_key] = 'Email';

            IF @debug > 1
                SELECT @emailProfile AS mailprofile;

            SET @Return = 1;

        END

        ELSE
        BEGIN

            IF @debug > 1
                SELECT Value
                FROM dbo.MFSettings
                WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                      AND dbo.MFSettings.[source_key] = 'Email';

            SET @ErrorMessage
                = 'Email PROFILE ' + @emailProfile
                  + ' in Settings is not valid, the default profile will be used instead';

			SET @Return = 1

            SELECT TOP 1
                @emailProfile = p.name
            FROM msdb.dbo.sysmail_account a
                INNER JOIN msdb.dbo.sysmail_profileaccount pa
                    ON a.account_id = pa.account_id
                INNER JOIN msdb.dbo.sysmail_profile p
                    ON pa.profile_id = p.profile_id;
            --				where p.name = 'X';
            IF ISNULL(@emailProfile, '') <> ''
			BEGIN
            SET @Return = 0
                RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage)
				
				END;

            IF ISNULL((SUBSTRING(@emailProfile, 1, 1)), '$') = '$'
            BEGIN
                SET @ErrorMessage = 'No Valid Email profile exists';
                RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage);

                SET @Return = 2;

            END;

        END;

        RETURN @Return;

    END TRY
    BEGIN CATCH
        RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage);
        RAISERROR('Fix SQL MailManager', 10, 1);
        RETURN -1;

    END CATCH;

GO

