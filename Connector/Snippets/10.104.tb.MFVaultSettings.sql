
go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFVaultSettings]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFVaultSettings', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFiles Authentication Type Lookup 
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
  Select * from MFAuthenticationType
  
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFVaultSettings'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFVaultSettings
			(
			    [ID] int IDENTITY(1,1) NOT NULL,
				[Username] nvarchar(128),
		        [Password] nvarchar(128),
				[NetworkAddress] nvarchar(128),
				[VaultName] nvarchar(128),
				[MFProtocolType_ID] INT,
				[Endpoint] int,
				[MFAuthenticationType_ID] int,
				[Domain] nvarchar(128)
			   CONSTRAINT [PK_MFVaultSettings] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
        

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

GO			
--FOREIGN KEYS #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.foreign_keys
                WHERE   parent_object_id = OBJECT_ID('MFVaultSettings')
                        AND name = N'FK_MFVaultSettings_MFProtocolType_ID' )
    BEGIN
        PRINT SPACE(10) + '... Constraint: FK_MFVaultSettings_MFProtocolType_ID';
        ALTER TABLE dbo.MFVaultSettings   WITH CHECK ADD 
         CONSTRAINT FK_MFVaultSettings_MFProtocolType_ID FOREIGN KEY (MFProtocolType_ID)
        REFERENCES [dbo].[MFProtocolType] ([id])
        ON DELETE NO ACTION;

    END;

GO
IF NOT EXISTS ( SELECT  *
                FROM    sys.foreign_keys
                WHERE   parent_object_id = OBJECT_ID('MFVaultSettings')
                        AND name = N'FK_MFVaultSettings_MFAuthenticationType_ID' )
    BEGIN
        PRINT SPACE(10) + '... Constraint: FK_MFVaultSettings_MFAuthenticationType_ID';
        ALTER TABLE dbo.MFVaultSettings WITH CHECK  ADD 
          CONSTRAINT FK_MFVaultSettings_MFAuthenticationType_ID FOREIGN KEY (MFAuthenticationType_ID)
        REFERENCES [dbo].[MFAuthenticationType] ([id])
        ON DELETE NO ACTION;

    END;

GO

