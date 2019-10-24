
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




SET NOCOUNT ON; 
GO



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFObjectChangeHistory]';

GO
/*
script to drop format MFObjectChangeHistory and create new format

*/


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFObjectChangeHistory'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
			  CREATE TABLE [dbo].[MFObjectChangeHistory](
			[ID] [int] IDENTITY(1,1) NOT NULL,
			[ObjectType_ID] [int] NULL,
			[Class_ID] [int] NULL,
			[ObjID] [int] NULL,
			[MFVersion] [int] NULL,
			[LastModifiedUtc] [datetime] NULL,
			[MFLastModifiedBy_ID] [int] NULL,
			[Property_ID] [int] NULL,
			[Property_Value] [nvarchar](300) NULL,
			[CreatedOn] [datetime] NULL,
		PRIMARY KEY CLUSTERED 
		(
			[ID] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]

END

IF (
SELECT COUNT(*) FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[TABLE_NAME] = 'MFObjectChangeHistory' AND [c].[COLUMN_NAME] IN ('Enter_TimeStamp','Exit_TimeStamp'))
> 0
BEGIN 

SELECT * INTO #MFobjectChangeHistory FROM [dbo].[MFObjectChangeHistory];

TRUNCATE TABLE [dbo].[MFObjectChangeHistory]

ALTER TABLE [dbo].[MFObjectChangeHistory]
DROP COLUMN [Enter_TimeStamp], COLUMN [Exit_TimeStamp]

ALTER TABLE [dbo].[MFObjectChangeHistory]
ADD [LastModifiedUtc] [datetime] NULL

INSERT INTO [dbo].[MFObjectChangeHistory]
(
    [ObjectType_ID]
   ,[Class_ID]
   ,[ObjID]
   ,[MFVersion]
   ,[LastModifiedUtc]
   ,[MFLastModifiedBy_ID]
   ,[Property_ID]
   ,[Property_Value]
   ,[CreatedOn]
)

SELECT 
  [ObjectType_ID]
   ,[Class_ID]
   ,[ObjID]
   ,[MFVersion]
   ,[Exit_TimeStamp]
   ,[MFLastModifiedBy_ID]
   ,[Property_ID]
   ,[Property_Value]
   ,[CreatedOn]
FROM [#MFobjectChangeHistory] AS [mfch]




END

GO



