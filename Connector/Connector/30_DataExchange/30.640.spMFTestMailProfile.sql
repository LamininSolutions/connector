PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFTestMailProfile]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFTestMailProfile', -- nvarchar(100)
    @Object_Release = '2.0.2.3', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-13
	Database: 
	Description: Testing email send for the Connector email profile
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFTestMailProfile]   @InMailProfile= 'LSEmailProfile',@RecipientEmail= 'leroux@lamininsolutions.com'
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFTestMailProfile'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFTestMailProfile]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


ALTER procedure [dbo].[spMFTestMailProfile](@InMailProfile varchar(MAX),@RecipientEmail varchar(MAX), @Debug SMALLINT = 0)
AS
BEGIN
SET NOCOUNT on
BEGIN try

DECLARE @bodyText VARCHAR(100)

SET @bodyText = 'This is a test mail sent for verifying profile:' + @InMailProfile

IF @Debug = 1
SELECT @InMailProfile AS [Profile], @RecipientEmail AS Recipient
EXEC msdb.dbo.sp_send_dbmail
    @recipients=@RecipientEmail,
    @body= @bodyText,
    @subject = 'Mail Profile verification',
    @profile_name = @InMailProfile;


RETURN 1
END TRY
BEGIN CATCH
RETURN -1
END Catch

END

GO