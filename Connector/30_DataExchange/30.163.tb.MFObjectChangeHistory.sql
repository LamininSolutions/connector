


go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFObjectChangeHistory]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFObjectChangeHistory', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2017-08
	Database: 
	Description: MFiles Object History
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
  Select * from MFObjectChangeHistory
  
-----------------------------------------------------------------------------------------------*/


GO


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

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

GO			





