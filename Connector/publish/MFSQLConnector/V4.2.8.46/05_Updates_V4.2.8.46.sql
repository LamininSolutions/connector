
GO

USE {varAppDB}	

GO

/*
THIS SCRIPT HAS BEEN PREPARED TO RUN UPDATES TO PREVIOUS INSTALLATIONS OF THE CONNECTOR BEFORE THE LATEST VERSION IS INSTALLED
*/

/*

lIST OF SCRIPT VARIABLES

{varAppDB}						DatabaseName (new or existing)


*/

GO

/*
Run this script once as the first step
*/

IF 
			 EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFModule'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

DROP TABLE MFModule

END


IF 
			 EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFLicenseModule'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

DROP TABLE MFLicenseModule

END


SET NOCOUNT ON; 
GO



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUserMessages]';

GO
/*
script to test connection, update metadata and run initialisation actions
a) drop and create MFUserMessages (note this must be taken off when

*/

DECLARE @MessageOut NVARCHAR(50);
EXEC [dbo].[spMFVaultConnectionTest] @MessageOut = @MessageOut OUTPUT -- nvarchar(50)


-------------------------------------------------------------
-- rest mfsettings for logging error
-------------------------------------------------------------
IF (SELECT CAST(Value AS NVARCHAR(5)) FROM MFSettings WHERE id = 8) not IN ('0','1')
begin
									UPDATE [dbo].[MFSettings]
									SET value = '0' WHERE id = 8
									END



-------------------------------------------------------------
-- update metadata
-------------------------------------------------------------
IF @MessageOut = 'Successfully connected to vault'
BEGIN

DECLARE @ProcessBatch_ID INT;
EXEC  [dbo].[spMFDropAndUpdateMetadata] @IsReset = 0,            -- int
                                       @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,                  -- int
                                       @Debug = 0,              -- smallint
                                       @WithClassTableReset = 0 -- int

-------------------------------------------------------------
-- reset user messages if old table
-------------------------------------------------------------
/*
DECLARE @IsOldTable int 
SELECT @IsOldTable = COUNT(*) FROM sys.columns WHERE [object_id] = OBJECT_ID('MFUserMessages') AND name = 'GUID'

IF (SELECT MAX(SUBSTRING([mdd].[LSWrapperVersion],7,2)) FROM [dbo].[MFDeploymentDetail] AS [mdd]) >= '41'
AND @IsOldTable > 0
*/
BEGIN


IF EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUserMessages'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
						BEGIN
                        
						DROP TABLE MFUserMessages;

						END;

    BEGIN

	EXEC [dbo].[spMFCreateTable] @ClassName = 'User Messages', -- nvarchar(128)
	                             @Debug = 0      -- smallint
	

	END

END

END

GO



