
go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProtocolType]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFProtocolType', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFiles Lookup Protocol  Details
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
  Select * from MFProtocolType
  Drop table MFprotocolType
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProtocolType'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFProtocolType
			(
			    [ID] int IDENTITY(1,1) NOT NULL,
				[ProtocolType] [nvarchar](250) NULL,
				[MFProtocolTypeValue] [nvarchar](200) NULL,
			   CONSTRAINT [PK_MFProtocolType] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
     	
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('TCP/IP','ncacn_ip_tcp')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('SPX','')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('Local Procedure Call','ncalrpc')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('HTTPS','ncacn_http')    

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

			
GO		


