
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwVaultSettings]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwVaultSettings', -- nvarchar(100)
    @Object_Release = '3.1.2.37', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwVaultSettings'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW dbo.MFvwVaultSettings
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2016-5

-- Description:	Summary of AuditHistory by Flag and Class
-- Revision History:  
-- YYYYMMDD Author - Description 
-- =============================================
MODIFICATIONS
2017-06-21	LC	Change Name
*/		
ALTER VIEW dbo.MFvwVaultSettings
AS

/*************************************************************************
STEP view all vault settings
NOTES
*/

SELECT [mvs].[ID] ,
       [mvs].[Username] ,
       [mvs].[Password] ,
       [mvs].[NetworkAddress] ,
       [mvs].[VaultName] ,
   [mat].[AuthenticationType] ,
 mat.ID AS Authentication_ID,
       [mpt].[ProtocolType] ,
	 mpt.id AS ProtocolType_ID,
       [mvs].[Endpoint] 

  FROM [dbo].[MFVaultSettings] AS [mvs]
INNER JOIN [dbo].[MFAuthenticationType] AS [mat]
ON [mat].[ID] = [mvs].[MFAuthenticationType_ID]
INNER JOIN [dbo].[MFProtocolType] AS [mpt]
ON [mpt].[ID] = [mvs].[MFProtocolType_ID]

--SELECT * FROM [dbo].[MFAuthenticationType] AS [mat]

--SELECT * FROM [dbo].[MFProtocolType] AS [mpt]