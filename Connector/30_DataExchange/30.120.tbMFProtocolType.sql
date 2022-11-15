
/*rST**************************************************************************

==============
MFProtocolType
==============

Columns
=======

ID int (primarykey, not null)
  SQL Primary Key
ProtocolType nvarchar(250)
  MF protocol internal id
MFProtocolTypeValue nvarchar(200)
  Protocol description

Additional Info
===============

Allow for gRPC, HTTPS, IPS and localhost protocol Types and flexible port end points.

Used By
=======

- MFVaultSettings
- MFvwVaultSettings
- spMFVaultConnectionTest
- FnMFVaultSettings


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-06-21  LC         Add gRPC
2019-09-07  JC         Added documentation
2016-08-01  DEV        Created procedure
==========  =========  ========================================================

**rST*************************************************************************/

go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProtocolType]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFProtocolType', -- nvarchar(100)
    @Object_Release = '4.10.30.74', -- varchar(50)
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

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

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



insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('TCP/IP','ncacn_ip_tcp')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('SPX','')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('Local Procedure Call','ncalrpc')
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('HTTPS','ncacn_http')    
insert into MFProtocolType(ProtocolType,MFProtocolTypeValue)values('gRPC','grpc')  
			
  PRINT SPACE(10) + '... Update : Protocol Types';
GO		


