
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
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('gRPC','grpc') 

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
Begin
    PRINT SPACE(10) + '... Table: exists';

    IF (SELECT COUNT(*) FROM dbo.MFProtocolType AS mpt) > 6
    Begin
DECLARE @ReferencedId INT, @ReferencedItem NVARCHAR(250)
SELECT @ReferencedId = MFProtocolType_ID , @ReferencedItem = mpt.protocoltype FROM dbo.MFVaultSettings AS mvs
INNER JOIN dbo.MFProtocolType AS mpt
ON mpt.ID = mvs.MFProtocolType_ID
WHERE mvs.id = 1

DELETE FROM dbo.MFProtocolType
WHERE ID <> @ReferencedItem
end
;
MERGE dbo.MFProtocolType t
USING 
(SELECT ProtocolType = 'TCP/IP', MFProtocolTypeValue = 'ncacn_ip_tcp'
UNION
SELECT ProtocolType = 'SPX', MFProtocolTypeValue = ''
UNION
SELECT ProtocolType = 'Local Procedure Call', MFProtocolTypeValue = 'ncalrpc'
UNION
SELECT ProtocolType = 'HTTPS', MFProtocolTypeValue = 'ncacn_http'
UNION
SELECT ProtocolType = 'gRPC', MFProtocolTypeValue = 'grpc'
) s
ON t.ProtocolType = s.ProtocolType
WHEN NOT MATCHED then
INSERT 
(ProtocolType,MFProtocolTypeValue)
VALUES
(s.ProtocolType,s.MFProtocolTypeValue)
WHEN MATCHED THEN
UPDATE SET
t.MFProtocolTypeValue = s.MFProtocolTypeValue
;

end
			
GO		


