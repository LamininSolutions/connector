
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



