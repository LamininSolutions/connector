PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateModule]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateModule', -- nvarchar(100)
    @Object_Release = '3.1.5.42', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
go

/*
Modifications:
2018-07-09	LC	change name of MFModule table to MFLicenseModule

*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateModule'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateModule]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go
ALTER  PROCEDURE [dbo].[spMFUpdateModule] 
@ModuleValues NVARCHAR(10),
@VaultName VARCHAR(100),
@LicenseExpiryDate VARCHAR(100),
@LicenseKey NVARCHAR(100)
AS 
BEGIN
    DECLARE @Count INT=0;
    --SET @Count=(SELECT COUNT(*) FROM MFModule);

				IF EXISTS(SELECT TOP 1 * FROM MFLicenseModule)
				BEGIN
					UPDATE 
					 MFLicenseModule 
					SET 
					 ModuleID=@ModuleValues,
					 ExpiryDate=@LicenseExpiryDate,
					 VaultName=@VaultName ,
					 DateModified=GETDATE(),
					 LicenseKey=@LicenseKey
				END
				ELSE
					INSERT INTO MFLicenseModule
							(ModuleID
							,ExpiryDate
							,VaultName
							,DateCreated
							,LicenseKey
							)
							VALUES
							(
								@ModuleValues
								,@LicenseExpiryDate
								,@VaultName
								,GETDATE()
								,@LicenseKey
							)
					

END

GO


