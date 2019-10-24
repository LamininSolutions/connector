-- -------------------------------------------------------- 
-- SourceDir: O:\Development\TFSSourceControl\lsconnectwrapper\AncoraScanCapture\ScanCapSQLScripts\ 
-- -------------------------------------------------------- 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 00.001.query.VaultConnectionTest.sql' 
PRINT '**********************************************************************'


/*
Connection Test
*/

SET NOCOUNT ON

DECLARE @MessageOut NVARCHAR(50);
EXEC dbo.spMFVaultConnectionTest @MessageOut = @MessageOut OUTPUT -- nvarchar(50)

GO
 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 00.002.query.GetDBSettings.sql' 
PRINT '**********************************************************************'


/*
Get Configuration settings for AI
*/

DECLARE @varDbase sysname
DECLARE @varDBLoginname NVARCHAR(100)

SELECT @varDbase = CAST([Value] AS sysname) FROM MFSEttings WHERE Name = 'App_Database' AND source_key = 'App_Default'
SELECT @varDBLoginname = CAST([Value] AS NVARCHAR(100)) FROM MFSEttings WHERE Name = 'AppUser' AND source_key = 'App_Default'

SELECT @varDbase AS 'DATABASE', @varDBLoginname AS DBLoginName


 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 00.003.queryGetClassTableDetail.sql' 
PRINT '**********************************************************************'


/*
Get Class table details
NULL	AP Invoice Line	NULL
*/

DECLARE @varInvoiceHeader NVARCHAR(100) = 'AP Invoice'
DECLARE @varInvoiceLine NVARCHAR(100) = 'AP Invoice Line'
DECLARE @varInvoiceDocument NVARCHAR(100) = 'Vendor Invoice Document'
DECLARE @varVendor NVARCHAR(100) = 'Vendor'

EXEC dbo.spMFSynchronizeMetadata @Debug = 0, -- smallint
    @ProcessBatch_ID = 0 -- int


SELECT @varInvoiceDocument as Class1
,(SELECT MC.TableName FROM dbo.MFClass AS MC
WHERE [name] = @varInvoiceDocument) AS ClassTable1
,@varInvoiceLine AS Class2
,(SELECT MC.TableName FROM dbo.MFClass AS MC
WHERE [name] = @varInvoiceLine) AS ClassTable2
,@varInvoiceDocument AS Class3
,(SELECT MC.TableName FROM dbo.MFClass AS MC
WHERE [name] = @varInvoiceDocument) AS ClassTable3
,@varVendor AS Class4
,(SELECT MC.TableName FROM dbo.MFClass AS MC
WHERE [name] = @varVendor) AS ClassTable4

GO



 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 00.004.queryGetFolderWatcherSettings.sql' 
PRINT '**********************************************************************'

/*
Get data for folderWatcher configuration
*/
DECLARE @MonitoredFolder NVARCHAR(100); -- input via app
DECLARE @AuthenticationType NVARCHAR(100); -- custom lookup
DECLARE @MFuserName NVARCHAR(100); -- MFVaultSettings
DECLARE @MFPassword NVARCHAR(100); -- MFVaultSettings
DECLARE @MFDomain NVARCHAR(100); -- MFVaultSettings
DECLARE @MFHost NVARCHAR(100); -- MFVaultSettings
DECLARE @Protocol NVARCHAR(100); -- MFProtocol
DECLARE @MFVaultGuid NVARCHAR(100); -- MFSettings
DECLARE @ClassPropID INT; -- MFclass
DECLARE @WorkflowStatePropID INT; -- MFWorkflowState
DECLARE @WorkflowPropID INT; -- MFWorkflow
DECLARE @FileNamePropID INT; -- MFProperty
DECLARE @AuthenticationType_ID INT; -- MFVaultSettings
DECLARE @Protocol_ID INT; -- MFVaultSettings
DECLARE @MFPort INT; -- MFVaultSettings

SELECT TOP 1
    @MFHost = MVS.NetworkAddress,
    @MFuserName = MVS.Username,
	@MFDomain = mvs.Domain,
    @MFPassword = MVS.Password,
	@Protocol_ID = mvs.MFProtocolType_ID,
	@AuthenticationType_ID = mvs.MFAuthenticationType_ID,
	@MFPort = MVS.Endpoint
FROM dbo.MFVaultSettings AS MVS;

SELECT TOP 1 @Protocol = MPT.MFProtocolTypeValue
FROM dbo.MFVaultSettings AS MVS
INNER JOIN dbo.MFProtocolType AS MPT 
ON MPT.ID = MVS.MFProtocolType_ID
WHERE mpt.id = @Protocol_ID

SELECT @AuthenticationType = CASE WHEN @AuthenticationType_ID = 4 THEN 'MFAuthTypeSpecificMFilesUser'
WHEN @AuthenticationType_ID = 2 THEN'MFAuthTypeLoggedOnWindowsUser'
WHEN @AuthenticationType_ID = 3 THEN'MFAuthTypeSpecificWindowsUser'
WHEN @AuthenticationType_ID = 1 THEN'MFAuthTypeUnknown'
 END


DECLARE @DecryptedPassword NVARCHAR(2000);
EXEC dbo.spMFDecrypt @EncryptedPassword = @MFPassword, -- nvarchar(2000)
    @DecryptedPassword = @DecryptedPassword OUTPUT; -- nvarchar(2000)

SELECT @MFVaultGuid = CAST(Value AS NVARCHAR(100))
FROM MFSettings
WHERE Name = 'VaultGUID';

SELECT @ClassPropID = MFID
FROM MFClass
WHERE Name LIKE 'Vendor Invoice Document';
SELECT @WorkflowPropID = MW.MFID,
    @WorkflowStatePropID = MWS.MFID
FROM dbo.MFWorkflow AS MW
    INNER JOIN dbo.MFWorkflowState AS MWS
        ON MWS.MFWorkflowID = MW.ID
WHERE MW.Name = 'Scan Capture Flow'
      AND MWS.Name = 'Scanned new';

SELECT @FileNamePropID = MFID
FROM dbo.MFProperty AS MP
WHERE Name LIKE 'Scan Capture Ref';

SELECT 
@MonitoredFolder AS MonitoredFolder,
@AuthenticationType AS MFAuthenticationType ,
@MFuserName AS MFUserName,
    @DecryptedPassword AS MFPassword,
	@MFDomain AS MFDomain,
	@Protocol as MFProtocolSequence,
    @MFHost AS NetworkAddress,
	@MFPort AS MFPort,
    @MFVaultGuid AS MFVaultGUID,
    @ClassPropID AS PropertyDefinition_id_100_Value,
    @WorkflowPropID AS PropertyDefinition_id_38_Value,
    @WorkflowStatePropID AS PropertyDefinition_id_39_Value,
    @FileNamePropID AS PropertyDefinition_id_FileName_id;

	GO
     
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.603.spMFCreateWorkflowStateLookupView.sql' 
PRINT '**********************************************************************'
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateWorkflowStateLookupView]';
GO
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateWorkflowStateLookupView', -- nvarchar(100)
    @Object_Release = '3.1.1.32', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFCreateWorkflowStateLookupView'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	DROP PROC spMFCreateWorkflowStateLookupView
	PRINT SPACE(10) + '...Stored Procedure: dropped and recreated'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	

-- the following section will be always executed
SET NOEXEC OFF
GO

create PROCEDURE [dbo].[spMFCreateWorkflowStateLookupView] (
	@WorkflowName NVARCHAR(128) 
	   ,@ViewName NVARCHAR(128)
	,@Debug SMALLINT = 0
	)
AS
/*******************************************************************************
  ** Desc:  The purpose of this procedure is to easily create one or more SQL Views to be used as lookup sources
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **      
  ** Parameters and acceptable values: 
  **		  @ValueListName  NVARCHAR(50)
  **		  @ViewName	   NVARCHAR(128)       
  **		  @Debug		   SMALLINT = 0
  **			         	Any value greater than 0 means to print debugging info
  **
  ** Restart:
  **        Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 
  **					MFValueList				SELECT
  **					MFValueListItems		     SELECT
  **                     MFObjectType				SELECT
  **                     MFWorkflow				SELECT
  **
  ** Return values:		@Output       INT OUTPUT
  **					
  **
  ** Called By:			None
  **
  ** Calls:           
  **					None
  **
  ** Author:          Thejus T V
  ** Date:            15/07/2015 
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 20-07-2015  DEV 2	   New Logic implemented
   ** 12-5-2017		LC			add deleted = 0 as filter
  ******************************************************************************/
BEGIN
	BEGIN TRY
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

		DECLARE @Query NVARCHAR(2500),@OwnerTableJoin NVARCHAR(250)
			,@ProcedureStep SYSNAME = 'Start';
		
		-----------------------------------------
		--DROP THE EXISTSING VIEW
		-----------------------------------------
		IF EXISTS (
				SELECT *
				FROM sys.VIEWS
				WHERE NAME = @ViewName
				)
		BEGIN
			
			-----------------------------------------
			--DEFINE DYNAMIC QUERY
			-----------------------------------------
			DECLARE @DropQuery NVARCHAR(50) = 'DROP VIEW [' + @ViewName + ']'

			SELECT @ProcedureStep = 'DROP EXISTING VIEW'

			IF @debug > 0
			SELECT 'view dropped';
			-----------------------------------------
			--EXECUTE DYNAMIC QUERY
			-----------------------------------------
			EXECUTE (@DropQuery)


		END

		SELECT @ProcedureStep = 'Set Dynamic query'

	
		------------------------------------------------------
		--DEFINE DYNAMIC QUERY TO CREATE VIEW
		------------------------------------------------------
	
		SELECT @Query =
		 'CREATE VIEW ' + QUOTENAME(@ViewName) + '
 AS
					    SELECT  
                            [mwf].[Name] AS Workflow ,
                            [mwf].[Alias] AS WorkflowAlias ,
                            [mwf].[MFID] AS WorkflowMFID,                        
                            [mwfs].[Name] AS [State] ,
                            [mwfs].[Alias] AS StateAlias,
                            [mwfs].[MFID] AS StateMFID
                         
    FROM    [dbo].[MFWorkflow] AS [mwf]
            INNER JOIN [dbo].[MFWorkflowState] AS [mwfs] ON [mwfs].[MFWorkflowID] = [mwf].[ID]
 
  WHERE   mwfs.deleted = 0 and mwf.Name = ''' + @WorkflowName + '''' 

			
	
		IF @Debug > 0
			SELECT @ProcedureStep AS [ProcedureStep]
				,@Query AS [QUERY];

		SELECT @ProcedureStep = 'EXECUTE DYNAMIC QUERY'

		--------------------------------
		--EXECUTE DYNAMIC QUERY
		--------------------------------
		EXECUTE (@Query)
		IF EXISTS (
				SELECT *
				FROM sys.VIEWS
				WHERE NAME = @ViewName
				)
		BEGIN
		RETURN 1 --SUCESS
		END
        ELSE 
		RETURN 0;
	END TRY

	BEGIN CATCH
		SET NOCOUNT ON

		IF @Debug > 0
			SELECT 'spMFCreateValueListLookupView'
				,Error_number()
				,Error_message()
				,Error_procedure()
				,Error_state()
				,Error_severity()
				,Error_line()
				,@ProcedureStep

		--------------------------------------------------
		-- INSERTING ERROR DETAILS INTO LOG TABLE
		--------------------------------------------------
		INSERT INTO MFLog (
			SPName
			,ErrorNumber
			,ErrorMessage
			,ErrorProcedure
			,ErrorState
			,ErrorSeverity
			,ErrorLine
			,ProcedureStep
			)
		VALUES (
			'spMFCreateLookupView'
			,Error_number()
			,Error_message()
			,Error_procedure()
			,Error_state()
			,Error_severity()
			,Error_line()
			,@ProcedureStep
			)

		RETURN 2	--FAILURE
	END CATCH
END
go
 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 00.101.script.CreateLookups_Initialization.sql' 
PRINT '**********************************************************************'


/*
Script to create MFvwScanCaptureStates view
*/



EXEC [dbo].[spMFSynchronizeSpecificMetadata]
    @Metadata = 'Workflow'
  , -- varchar(100)
    @Debug = 0
  , -- smallint
    @IsUpdate = 0 -- smallint

EXEC [dbo].[spMFSynchronizeSpecificMetadata]
    @Metadata = 'State'
  , -- varchar(100)
    @Debug = 0
  , -- smallint
    @IsUpdate = 0 -- smallint

EXEC [dbo].[spMFCreateWorkflowStateLookupView]
    @WorkflowName = N'Scan Capture Flow'
  , -- nvarchar(128)
    @ViewName = N'MFvwScanCaptureStates'
  , -- nvarchar(128)
    @Debug = 0 -- smallint


	EXEC [dbo].[spMFCreateWorkflowStateLookupView]
    @WorkflowName = N'Vendor Invoice Flow'
  , -- nvarchar(128)
    @ViewName = N'MFvwVendorInvoiceFlow'
  , -- nvarchar(128)
    @Debug = 0 -- smallint


/*
Vendor Scan Match lookup for valuelist
*/

--EXEC [dbo].[spMFSynchronizeSpecificMetadata]
--    @Metadata = 'Valuelist'
--  , -- varchar(100)
--    @Debug = 0
--  , -- smallint
--    @IsUpdate = 0 -- smallint

--SELECT * FROM [dbo].[MFValueList] AS [mvl]

--EXEC [dbo].[spMFCreateValueListLookupView]
--    @ValueListName = N'Vendor Name Scan Match'
--  , -- nvarchar(128)
--    @ViewName = N'MFvwVendorNameScanMatch'
--  , -- nvarchar(128)
--    @Debug = 0 -- smallint

	GO

 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 01.002.PermissionsScanCapSchema.sql' 
PRINT '**********************************************************************'
/*
Author: lc
Date:	  2017-05-15

Modified: 
Date:		By:			Details:




*/
/*
	Purpose: To be executed in customer environment before installing ScanCapture Purchases for Ancora 
		Ancora

	Tasks Performed:

		- Create Database Schema(s)
			- ScanCap (owned by dbo)
				Permissions:	INSERT,UPDATE,DELETE,SELECT, EXECUTE to db_MFSQLConnect

		- Create Database Role(s)
			- db_MFSQLConnect			: Used by MFSQL Connector
					Permissions:	INSERT,UPDATE,DELETE,SELECT, EXECUTE on scemas dbo, ScanCap

		- Create Database User(s)
			- DOMAIN\AncoraUsers	: Windows/AD Group allowing Windows Authentication w/Ancora Client
					Member of:	db_reader,db_writer,db_owner

			- MFSQLConnect			: Used by Vault Application	
					Member of:	MFSQLConnect 	
			

*/

--USE {varAppDB} 

DECLARE @varDBName NVARCHAR(128) 
DECLARE @domain VARCHAR(50) = DEFAULT_DOMAIN()
DECLARE @varMFSQLConnectlogin VARCHAR(50) 
DECLARE @dbrole VARCHAR(50) 


PRINT '[' + DB_NAME() + '] ON [' + @@SERVERNAME + ']'
PRINT REPLICATE('-', 80)

/**********************************************************************************
** GET ROLE AND USER FROM MFSETTINGS
*********************************************************************************/

SELECT @varDBName = CAST(MS.Value AS VARCHAR(100)) FROM dbo.MFSettings AS MS
WHERE name = 'App_Database' AND MS.source_key = 'App_Default'
SELECT @varMFSQLConnectlogin = CAST(MS.Value AS VARCHAR(100)) FROM dbo.MFSettings AS MS
WHERE name = 'AppUser' AND MS.source_key = 'App_Default'
SELECT @dbrole = CAST(MS.Value AS VARCHAR(100)) FROM dbo.MFSettings AS MS
WHERE name = 'AppUserRole' AND MS.source_key = 'App_Default'

/**********************************************************************************
** CREATE DATABASE SCHEMA(S)
*********************************************************************************/
DECLARE @schema NVARCHAR(50)
SET @schema = 'ScanCap'

PRINT 'CREATE SCHEMA [' + @schema + ']'
IF NOT EXISTS ( SELECT  1
                FROM    [sys].[schemas]
                WHERE   [schemas].[name] = @schema )
   BEGIN
         PRINT SPACE(5) + '    -- adding schema... '
         EXEC ('CREATE SCHEMA [ScanCap] AUTHORIZATION [dbo]')
   END
ELSE
   PRINT SPACE(5) + '    -- schema exists. '


/**********************************************************************************
** APPLY PERMISSIONS TO SCHEMAS
*********************************************************************************/
BEGIN

      SET @schema = 'ScanCap'

      PRINT 'APPLY PERMISSIONS ON SCHEMA [' + @schema + '] TO DATABASE ROLE [' + @dbrole + ']'
      EXEC('GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')

      SET @schema = 'dbo'
      PRINT 'APPLY PERMISSIONS ON SCHEMA [' + @schema + '] TO DATABASE ROLE [' + @dbrole + ']'
      EXEC('GRANT DELETE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT INSERT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT SELECT ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT UPDATE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
      EXEC('GRANT EXECUTE ON SCHEMA::[' + @schema + '] TO [' + @dbrole + ']')
END


GO





 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 10.101.scancap.tb.CreateAncora_Invoices.sql' 
PRINT '**********************************************************************'


go

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-05
	Database: Ancora_Invoices
	Description: Table used by Ancora to export Invoice properties
	
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
  Drop table [ScanCap].[Ancora_Invoices]
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[Ancora_Invoices]';

GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'Ancora_Invoices'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN


CREATE TABLE [dbo].[Ancora_Invoices](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[migration] [bit] NOT NULL,
	[file_path] [varchar](255) NULL,
	[FileName] [varchar](100) NULL,
	[ftf_name] [varchar](255) NOT NULL,
	[LinkID] [varchar](255) NULL,
	[VENDOR NAME] [varchar](100) NULL,
	[VENDOR CODE] [varchar](100) NULL,
	[INVOICE DATE] [date] NULL,
	[INVOICE NO] [varchar](100) NULL,
	[PO NUMBER] [varchar](100) NULL,
	[SUBTOTAL] [float] NULL,
	[TAX] [float] NULL,
	[SHIPPING AND HANDLING] [float] NULL,
	[OTHER AMOUNT] [float] NULL,
	[DEPOSIT] [float] NULL,
	[TOTAL AMOUNT] [float] NULL,
	[Image Path] [varchar](255) NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[QTY] [float] NULL,
	[UNIT PRICE] [float] NULL,
	[LINE TOTAL] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE INDEX Ancora_Invoices_File_Name ON [scancap].[Ancora_Invoices]([FileName])
END

GO


 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 10.102.ScanCap.tb.ScanCaptureLog.sql' 
PRINT '**********************************************************************'

go

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-09
	Database: 
	Description: Scan Capture Process Log
	
	Loggin:	Log of scan capture integration processing

 
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
  Select * from [ScanCap].[ScanCaptureLog]
   --DROP TABLE [ScanCap].[ScanCaptureLog]
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[ScanCap].[ScanCaptureLog]';

GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'ScanCaptureLog'
                        AND SCHEMA_NAME(schema_id) = 'ScanCap' )
    BEGIN

CREATE TABLE [ScanCap].[ScanCaptureLog](
LogID INT IDENTITY,
[FileName] nvarchar(50) NOT NULL,
LineItemCount INT NOT NULL,
LastModified DATETIME null,
UpdateStatus NVARCHAR(128) NULL,
DurationSeconds decimal(18,4) null,
Status_ID INT not null CONSTRAINT  [DF_Scancap_ScanCaptureLog_Status_ID] DEFAULT 0,
[CreatedOn] DATETIME NULL CONSTRAINT [DF_Scancap_ScanCaptureLog_CreatedOn] DEFAULT GETDATE()
)

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


	GO
     
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 10.103.Scancap.tb.ConfigurationMap.sql' 
PRINT '**********************************************************************'


go

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-05
	Database: MFSQL Connector 
	Description: Table used by scan capture to set configuration
	
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
  drop table scancap.configurationMap
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[ScanCap].[ConfigurationMap]';

GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'ConfigurationMap'
                        AND SCHEMA_NAME(schema_id) = 'ScanCap' )
    BEGIN


CREATE TABLE [scancap].[ConfigurationMap](
	[id] [INT] IDENTITY(1,1) NOT NULL,
	
	[MFProperty] [NVARCHAR](100)  NULL,
	[MFproperty_MFID] INT null,
	MFCLass [NVARCHAR](100)  NULL,
	[ScannedColumn] [NVARCHAR](100) NULL,
	[LastModified] [DATETIME] NULL DEFAULT (GETDATE())
) ON [PRIMARY]

END

GO


 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 10.201.trScanCapture_Purchases_ScanCaptureLog.sql' 
PRINT '**********************************************************************'


/*
Trigger on Ancora Invoice table to create ScanCaptureLog

select * from scancap.[ScanCaptureLog]
*/


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[invoice].[invoice_ScanCapLog_ins_trg]';
GO
IF NOT EXISTS ( SELECT  *
                FROM    sys.objects
                WHERE   [type] = 'TR' AND
                        [name] = 'invoice_ScanCapLog_ins_trg' )
   BEGIN
         EXEC ('CREATE TRIGGER  dbo.invoice_ScanCapLog_ins_trg
         ON dbo.Ancora_Invoices
         AFTER INSERT
         AS
         BEGIN
         SELECT 1
         END')  

         PRINT SPACE(10) + ' dbo.invoice_ScanCapLog_ins_trg | Created'
   END
   ELSE
		PRINT SPACE(10) + ' dbo.invoice_ScanCapLog_ins_trg | Updated'
GO
ALTER TRIGGER [dbo].[invoice_ScanCapLog_ins_trg] ON dbo.Ancora_Invoices
    AFTER INSERT 
AS


Declare @Debug int

Insert into scancap.ScanCaptureLog
([FileName], LineItemCount,UpdateStatus)

select DISTINCT [FileName], 
(select count(sc2.[FileName]) from inserted sc2 where sc1.[FileName] = sc2.[FileName] group by [FileName])
,'ScanCaptured'
 from inserted sc1



GO

 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.501.spMFGetObjectvers.sql' 
PRINT '**********************************************************************'
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetObjectvers]';
go
 
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetObjectvers', -- nvarchar(100)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFGetObjectvers'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
	END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFGetObjectvers]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF
go

Alter procedure [dbo].[spMFGetObjectvers](
@TableName nvarchar(100),
@dtModifiedDate datetime,
@MFIDs nvarchar(4000),
@outPutXML nvarchar(max) output
)
as
/*******************************************************************************
  ** Desc:  The purpose of this procedure is to get all the object vers of the class table as XML  
  **  
  ** Version: 2.0.0.2
  **
  ** Processing Steps:
  **					1.Get the ID's not available in Class Tables
                        2.Form the XML with the missing ID
  **
  ** Parameters and acceptable values: 					
  **					@objIDs          VARCHAR(4000)
  **			        @tableName		VARCHAR(30) 	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					@missing
  **
  ** Called By:			spMFUpdateTable
  **
  ** Calls:           
  **					NONE
  **														
  **
  ** Author:			Kishore
  ** Date:				20-06-2016

  Change history

  2016-8-22	 LC		update settings index
  20168-22	lc		change objids to NVARCHAR(4000)
  201509-21 DevTeam2 Removed @Username,@Password,@NetworkAddress,@VaultName Parameters and Just fetch  the vault settings in single comma separated
                     Parameter i.e. @VaultSettings

  ******************************************************************************/

begin

DECLARE @VaultSettings nvarchar(4000)
DECLARE @ClassId int


select @ClassId = MFID from MFClass where TableName = @TableName

					Select @VaultSettings=dbo.FnMFVaultSettings()
                    EXECUTE spMFGetObjectVersInternal @VaultSettings,@ClassId,@dtModifiedDate,@MFIDs,@outPutXML output



end
go


 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.626.spMFTableAudit.sql' 
PRINT '**********************************************************************'

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFTableAudit]';
GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFTableAudit', -- nvarchar(100)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFTableAudit'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFTableAudit]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFTableAudit]
    (
      @MFTableName NVARCHAR(128) ,
      @MFModifiedDate DATETIME = NULL , --NULL to select all records
      @ObjIDs NVARCHAR(4000) = NULL ,
      @Debug SMALLINT = 0 ,-- use 2 for listing of full tables during debugging
      @SessionIDOut INT OUTPUT , -- output of session id
      @NewObjectXml NVARCHAR(MAX) OUTPUT -- return from M-Files
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to Get all Records from MFiles for the selection
  **  					
  **
  ** Author:			leRoux Cilliers
  ** Date:				17-07-2016
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  2016-8-22		lc			change objids to NVARCHAR(4000)

  ** ----------  ---------  -----------------------------------------------------

  USAGE
  Declare @SessionIDOut int, @return_Value int, @NewXML nvarchar(max)
  exec @return_Value = spMFTableAudit 'MFOtherdocument' , null, null, 1, @SessionIDOut = @SessionIDOut output, @NewObjectXml = @NewXML output
  Select @SessionIDOut ,@return_Value, @NewXML


  ******************************************************************************/
    BEGIN

        BEGIN TRY     
            SET NOCOUNT ON;
            SET XACT_ABORT ON;

		-----------------------------------------------------
		--DECLARE LOCAL VARIABLE
		-----------------------------------------------------
            DECLARE @Id INT ,
                @objID INT ,
                @ObjectIdRef INT ,
                @ObjVersion INT ,
                @TableName NVARCHAR(1000) ,
                @TABLE_ID INT ,
                @XMLOut NVARCHAR(MAX) ,
                @ObjIDsForUpdate NVARCHAR(MAX) ,
   --             @Output NVARCHAR(200) ,
                @FullXml XML , --
                @SynchErrorObj NVARCHAR(MAX) , --Declared new paramater
                @DeletedObjects NVARCHAR(MAX) , --Declared new paramater
                @ProcedureName sysname = 'spMFTableAudit' ,
                @ProcedureStep sysname = 'Start' ,
                @ObjectId INT ,
                @ClassId INT ,
                @ErrorInfo NVARCHAR(MAX) ,
                @MFIDs NVARCHAR(2500) = '' ,
                @Update_ID INT ,
                @return_value INT = 1 ,
                @RunTime VARCHAR(20);

            IF EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].['
                                                      + @MFTableName + ']')
                                AND type IN ( N'U' ) )
                BEGIN
            
                    BEGIN TRAN main;
                    IF @Debug > 9
                        BEGIN	
                            SET @RunTime = CONVERT(VARCHAR(20), GETDATE());
                            RAISERROR('Proc: %s Step: %s Time: %s',10,1,@ProcedureName, @ProcedureStep,@RunTime);       
                        END;
	
			-----------------------------------------------------
			--To Get Table Name	
			-----------------------------------------------------
                    SET @ProcedureStep = 'Reset Table name';
                    SET @TableName = @MFTableName;
                    SET @TableName = REPLACE(@TableName, '_', ' ');

                    SELECT  @TABLE_ID = object_id
                    FROM    sys.objects
                    WHERE   name = @TableName;

                    IF @Debug > 9
                        BEGIN
                            RAISERROR('Proc: %s Step: %s Table: %s TableID: %i',10,1,@ProcedureName, @ProcedureStep,@TableName, @TABLE_ID);
                        END;

			-----------------------------------------------------
			--Set Object Type Id and class id
			-----------------------------------------------------
                    SET @ProcedureStep = 'Get Object Type and Class';

                    SELECT  @ObjectIdRef = mc.MFObjectType_ID ,
                            @ObjectId = ob.MFID ,
                            @ClassId = mc.MFID
                    FROM    dbo.MFClass mc
                            INNER JOIN dbo.MFObjectType ob ON ob.[ID] = mc.[MFObjectType_ID]
                    WHERE   mc.TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

                    SELECT  @ObjectId = MFID
                    FROM    dbo.MFObjectType
                    WHERE   ID = @ObjectIdRef;

                    IF @Debug > 9
                        BEGIN
                            RAISERROR('Proc: %s Step: %s ObjectType: %i Class: %i',10,1,@ProcedureName, @ProcedureStep,@ObjectId, @ClassId);
                            IF @Debug = 2
                                BEGIN
                                    SELECT  *
                                    FROM    MFClass
                                    WHERE   MFID = @ClassId;
                                END;
                        END;
		

			-----------------------------------------------------
			--Wrapper Method
			-----------------------------------------------------
                   


EXEC [dbo].[spMFGetObjectvers] @TableName = @TableName, -- nvarchar(max)
    @dtModifiedDate = @MFModifiedDate, -- datetime
    @MFIDs = @ObjIDsForUpdate, -- nvarchar(max)
    @outPutXML = @NewObjectXml output -- nvarchar(max)

	IF @debug > 10 
SELECT @NewObjectXml AS ObjVerOutput;

                    IF @Debug > 9
                        BEGIN

                            RAISERROR('Proc: %s Step: %s returned %i  ',10,1,@ProcedureName, @ProcedureStep, @return_value );
                        END;

                    CREATE TABLE #AllObjects
                        (
                          [ID] INT ,
                          Class INT ,
                          ObjectType INT ,
                          [ObjID] INT ,
                          [MFVersion] INT ,
                          StatusFlag SMALLINT
                        );
                    CREATE INDEX idx_AllObjects_ObjID ON #AllObjects([ObjID]);
                    SET @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';

                    DECLARE @NewXML XML;
					 SET @NewXML = CAST(@NewObjectXml AS XML)
					IF @debug > 10 
					BEGIN
                    SELECT @newXML
					SELECT  @ClassId AS Class,
                                    @ObjectId AS objectType ,
                                    t.c.value('(@version)[1]', 'INT') AS [MFVersion] ,
                                    t.c.value('(@objectID)[1]', 'INT') AS [ObjID] 
                            FROM    @NewXML.nodes('/form/objVers') AS t ( c );
					End



                    INSERT  INTO [#AllObjects]
                            ( [Class] ,
                              [ObjectType] ,
                              [MFVersion] ,
                              [ObjID] ,
                              ID ,
                              [StatusFlag]
                            )
                            SELECT  @ClassId ,
                                    @ObjectId ,
                                    t.c.value('(@version)[1]', 'INT') AS [MFVersion] ,
                                    t.c.value('(@objectID)[1]', 'INT') AS [ObjID] ,
									NULL,
                                    --t.c.value('(@ID)[1]', 'INT') AS [ID] ,
                                    --t.c.value('(@objectGUID)[1]',
                                    --          'NVARCHAR(100)') AS [GUID] ,
                                    1
                            FROM    @NewXML.nodes('/form/objVers') AS t ( c );
                  
                 

                    IF @Debug > 9
                        BEGIN
                            RAISERROR('Proc: %s Step: %s ',10,1,@ProcedureName, @ProcedureStep );
                            IF @Debug > 10
                                SELECT  *
                                FROM    #AllObjects AS [ao];
                        END;

                    DECLARE @Query NVARCHAR(MAX) ,
                        @SessionID INT ,
                        @TranDate DATETIME ,
                        @Params NVARCHAR(MAX);
                    SELECT  @TranDate = GETDATE();
                    SELECT  @SessionID = ( SELECT   MAX(SessionID) + 1
                                           FROM     dbo.MFAuditHistory
                                         );
                    SELECT  @SessionID = ISNULL(@SessionID, 1);

                    SELECT  @SessionIDOut = @SessionID;

                    SET @ProcedureStep = 'Insert records into Audit History';

                    SET @Params = N'@SessionID int, @TranDate datetime, @ObjectID int, @ClassID int';
                    SELECT  @Query = N'INSERT INTO [dbo].[MFAuditHistory]
        ( RecID,
		[SessionID] ,
          [TranDate] ,
          [ObjectType] ,
          [Class] ,
          [ObjID] ,
          [MFVersion] ,
          [StatusFlag] ,
          [StatusName]
        )
                   
					SELECT 
					 t.[ID],
					@SessionID,
					@TranDate,
					@objectID,
					@ClassID,
                    CASE WHEN ao.[ObjID] IS NULL
                                            THEN t.[ObjID]
                                            ELSE ao.[ObjID]
                                       END ,
					ao.MFVersion,
                            CASE				WHEN t.Deleted = 1
                                                 THEN 3 --- Marked DELETED in SQL
												 WHEN ao.[MFVersion] IS NULL and isnull(t.deleted,0) = 0
                                                 THEN  4 --SQL to be deleted
                                                 WHEN ao.[MFVersion] = ISNULL(t.[MFVersion],
                                                              -1) and isnull(t.deleted,0) = 0 THEN 0 -- CURRENT VERSIONS ARE THE SAME
                                                 WHEN ao.[MFVersion] < ISNULL(t.[MFVersion],
                                                              -1) THEN 2 -- SQL version is later than M-Files - Sync error
                                                 WHEN t.[MFVersion] is null and ao.[MFVersion] is not null
                                                               THEN 5 -- new in SQL
												 WHEN ao.[MFVersion] > t.[MFVersion] and t.deleted = 0
                                                               THEN 1 -- MFiles is more up to date than SQL
                                            END,
							CASE				WHEN  t.deleted = 1 
                                                 THEN ''Deleted in MF''
										WHEN ao.[MFVersion]  IS NULL and isnull(t.deleted,0) = 0
                                                 THEN ''SQL to be deleted''
                                                 WHEN ao.[MFVersion] = ISNULL(t.[MFVersion],-1) THEN ''Identical''
                                                 WHEN ao.[MFVersion] < ISNULL(t.[MFVersion],-1) THEN ''SQL is later''
                                                 WHEN t.[MFVersion] is null and ao.[MFVersion] is not null
                                                               THEN ''Not in SQL''
												 WHEN ao.[MFVersion] > t.[MFVersion] and t.deleted = 0 THEN ''MF is Later''
                                            END
                    FROM    [#AllObjects] AS [ao]
                            FULL OUTER JOIN [dbo].' + @TableName
                            + ' AS t ON t.[ObjID] = ao.[ObjID]
							;
					

					Update t
					set deleted = 1

					from ' +  @TableName + ' as t 
					inner join MFAuditHistory th
					on t.objid = th.objid 
					where StatusFlag = 4 and SessionID = @SessionID;		
							
							';

							
                    IF @Debug > 9
                        BEGIN                            
                            RAISERROR('Proc: %s Step: %s',10,1,@ProcedureName, @ProcedureStep);
				Select @Query;
                        END; 


	

                    EXEC sp_executesql @Query, @Params,
                        @SessionID = @SessionID, @TranDate = @TranDate,
                        @ObjectID = @ObjectId, @ClassId = @ClassId;

                    SET @ProcedureStep = 'Update Processed';
							
                    IF @Debug > 9
                        BEGIN
                            SET @RunTime = CONVERT(VARCHAR(20), GETDATE());
                            RAISERROR('Proc: %s Step: %s SUCCESS with return %i :%s',10,1,@ProcedureName, @ProcedureStep, @return_value,@RunTime);
                        END; 


                    COMMIT TRAN [main];
                    DROP TABLE #AllObjects
                END;   
            ELSE
                BEGIN
                    SELECT  'Check the table Name Entered';
                END;
            SET NOCOUNT OFF;

        END TRY

        BEGIN CATCH
            IF @@TRANCOUNT <> 0
                BEGIN
                    ROLLBACK TRANSACTION;
                END;

            SET NOCOUNT ON;

            IF @Debug > 9
                BEGIN
                    SELECT  ERROR_NUMBER() AS ErrorNumber ,
                            ERROR_MESSAGE() AS ErrorMessage ,
                            ERROR_PROCEDURE() AS ErrorProcedure ,
                            @ProcedureStep AS ProcedureStep ,
                            ERROR_STATE() AS ErrorState ,
                            ERROR_SEVERITY() AS ErrorSeverity ,
                            ERROR_LINE() AS ErrorLine;
                END;

            SET NOCOUNT OFF;

            RETURN -1; --For More information refer Process Table
        END CATCH;
    END;
GO
 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.628.spMFUpdateMFilesToMFSQL.sql' 
PRINT '**********************************************************************'
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.[spMFUpdateMFilesToMFSQL]';

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFUpdateMFilesToMFSQL'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateMFilesToMFSQL]
AS
BEGIN
       SELECT   'created, but not implemented yet.'--just anything will do
END
GO
-- the following section will be always executed
SET NOEXEC OFF
GO

ALTER PROCEDURE [dbo].[spMFUpdateMFilesToMFSQL] ( @MFTableName NVARCHAR(128)
												 ,  @MFLastUpdateDate SMALLDATETIME =null OUTPUT
												 ,	@UpdateTypeID tinyint = 0 -- 1 = full update 0 = incremental
												    , @Update_IDOut INT = NULL OUTPUT
												   , @ProcessBatch_ID INT = NULL OUTPUT
												 ,  @debug TINYINT = 0  -- 101 for EpicorEnt Test Mode
												  )
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to syncronize records in the CLGLChart
  **		class Table from Epicor into M-Files.  
  **		Full Table Merge with every execution, INSERT, UPDATE, DELETE
  **  
  ** Version: 1.0.0.0
  **
  ** Processing Steps:

  ** Parameters and acceptable values:
  **			@ProcessBatch_ID:	Optional - If not provided will initialize new, else validate against existing.
				@UpdateTypeID:		0			: Full Recordset comparison	| Update/Insert/Delete based on full compare
									1			: Incremental based on timestamp and/last update date
									2			: Deletes Only
  ** 
  ** Tables Used:  

  **               
  ** Return values:   = 1 Success
  **                  < 1 Failure
  **
  ** Called By:       None
  **
  ** Calls:           
  **					Sp_executesql
  **					spMFUpdateTable
  **				  	
  **
  ** Author:          arnie@lamininsolutions.com
  ** Date:            2016-08-11
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ******************************************************************************/

  /*
    SELECT * FROM [dbo].[MFvwMetadataStructure]
	WHERE Class_Alias = 'mfec.CLEpicorCompany'
	AND Property_MFID >1000

	Truncate Table 	CLEpicorCompany
	Sample Execution
  
  
	DECLARE @ProcessBatch_ID int = 20
	, @MFLastUpdateDate smalldatetime

	EXEC [dbo].[UpdateMFilesToMFSQL]   @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
	 										 , @UpdateTypeID = 1 -- Incremental
 										     , @MFTableName = 'CLAPVendor'
											 , @MFLastUpdateDate  = @MFLastUpdateDate OUTPUT
											 , @debug = 0
	PRINT 	@ProcessBatch_ID 
	PRINT   @MFLastUpdateDate
	select * from dbo.MFProcessBatch WHERE MFProcessBatch_ID = @ProcessBatch_ID
	select * from dbo.MFProcessBatchDetail WHERE MFProcessBatch_ID = @ProcessBatch_ID
	select * from MFAuditHistory where sessionid = 32	 
	select * from MFClass where TableName = 'CLEpicorCompany'

  */
  BEGIN

	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	 -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
        DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFUpdateMFilesToMFSQL';
        DECLARE @ProcedureStep AS NVARCHAR(128) = 'Set Variables';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		

		--used on MFProcessBatch;
		DECLARE @ProcessType nvarchar(50)
		DECLARE @LogType AS NVARCHAR(50) = 'Status'
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) = 'Started'

		--used on MFProcessBatchDetail;
		DECLARE @LogTypeDetail AS NVARCHAR(50) = 'Debug'
		DECLARE @LogTextDetail AS NVARCHAR(4000) = @ProcedureStep;
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @EndTime datetime
		DECLARE @StartTime DATETIME
        DECLARE @StartTime_Total DATETIME = GETUTCDATE()
        
		DECLARE @Validation_ID int
		DECLARE @LogColumnName nvarchar(128)
		DECLARE @LogColumnValue nvarchar(256)

        DECLARE @RunTime AS DECIMAL(18, 4) = 0;

        DECLARE @rowcount AS INT = 0;
        DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		DECLARE @output NVARCHAR(200)
		DECLARE @sql nvarchar(max) = N''
		DECLARE @sqlParam nvarchar(max) = N''

	-------------------------------------------------------------
    -- Global Constants
    -------------------------------------------------------------
		DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1
		DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0

		DECLARE @UpdateType_0_FullRefresh	TINYINT = 0
		DECLARE @UpdateType_1_Incremental	TINYINT = 1
		DECLARE @UpdateType_2_Deletes		TINYINT = 2

	BEGIN TRY


	-------------------------------------------------------------
    -- Get/Validate ProcessBatch_ID
    -------------------------------------------------------------
	BEGIN
	SET @ProcedureStep = '... Get/Validate ProcessBatch_ID'
		EXEC @return_value = [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID output
		  , @ProcessType = 'UpdateMFilesToMFSQL'
		  ,@LogText = @ProcedureStep
		  , @LogStatus = 'Started'
		  , @debug = @debug
	END	--Get/Validate ProcessBatch_ID

/*************************************************************************************
	REFRESH M-FILES --> MFSQL	 (Process Codes: M2E2M | M2E | E2M2E | E2M ) --All Process Codes
*************************************************************************************/
BEGIN

		

	
		DECLARE @MFAuditHistorySessionID INT = NULL

		IF @UpdateTypeID = (@UpdateType_0_FullRefresh)
		BEGIN
				SET @StartTime = GETUTCDATE() 
				-------------------------------------------------------------
				-- Update M-Files to MFSQL - Initialize
				-------------------------------------------------------------	
				SET @ProcedureStep = 'Update M-Files to MFSQL - Initialize'
				
				SET @StartTime = GETUTCDATE()
				SET @LogTypeDetail = 'Status'
				SET @LogTextDetail =  'UpdateType full refresh with updatemethod 1'
				SET @LogStatusDetail = 'Started'
				SET @LogColumnName = ''
				SET @LogColumnValue = ''

                EXEC [dbo].[spMFProcessBatchDetail_Insert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , @LogType = @LogTypeDetail
                  , @LogText = @LogTextDetail
                  , @LogStatus = @LogStatusDetail
                  , @StartTime = @StartTime
                  , @MFTableName = @MFTableName
                  , @ColumnName = @LogColumnName
                  , @ColumnValue = @LogColumnValue
                  , @LogProcedureName = @ProcedureName
                  , @LogProcedureStep = @ProcedureStep
                  , @debug = @debug;

					
				EXEC    @return_value = [dbo].[spMFUpdateTable]
						@MFTableName = @MFTableName,
						@UpdateMethod = @UpdateMethod_1_MFilesToMFSQL,
						@UserId = NULL,
						@MFModifiedDate = NULL,
						@ObjIDs = NULL,
						@Update_IDOut = @Update_IDOut OUTPUT,
						@ProcessBatch_ID = @ProcessBatch_ID,
						@Debug = @Debug

				SET @error = @@ERROR
				SET @LogStatusDetail = CASE WHEN (@error <> 0 OR @return_value = -1) THEN 'Failed'
							WHEN @return_value IN(1,0) THEN 'Complete'
							ELSE 'Exception'
							END

				SET @LogTypeDetail = 'Debug'
				SET @LogTextdetail =  ' Return Value: ' + CAST(@return_value AS NVARCHAR(256))
				SET @LogColumnName = 'MFUpdate_ID '
				SET @LogColumnValue = CAST(@Update_IDOut AS NVARCHAR(256))

                EXEC [dbo].[spMFProcessBatchDetail_Insert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , @LogType = @LogTypeDetail
                  , @LogText = @LogTextDetail
                  , @LogStatus = @LogStatusDetail
                  , @StartTime = @StartTime
                  , @MFTableName = @MFTableName
                  , @ColumnName = @LogColumnName
                  , @ColumnValue = @LogColumnValue
                  , @LogProcedureName = @ProcedureName
                  , @LogProcedureStep = @ProcedureStep
                  , @debug = @debug;

				
				      
		END --IF @UpdateTypeID = (@UpdateType_0_FullRefresh)

		IF (@UpdateTypeID IN(@UpdateType_1_Incremental,@UpdateType_2_Deletes))
		BEGIN 
				SET @StartTime = GETUTCDATE() 
				
				SET @ProcedureStep = 'Update M-Files to MFSQL - Initialize'			
				SET @StartTime = GETUTCDATE()
				SET @LogTextDetail =  'UpdateType incremental refresh with updatemethod 1'
				SET @LogStatusDetail = 'Started'
				SET @LogColumnName = ''
				SET @LogColumnValue = ''

                EXEC [dbo].[spMFProcessBatchDetail_Insert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , @LogType = @LogTypeDetail
                  , @LogText = @LogTextDetail
                  , @LogStatus = @LogStatusDetail
                  , @StartTime = @StartTime
                  , @MFTableName = @MFTableName
                  , @ColumnName = @LogColumnName
                  , @ColumnValue = @LogColumnValue
                  , @LogProcedureName = @ProcedureName
                  , @LogProcedureStep = @ProcedureStep
                  , @debug = @debug;

				-------------------------------------------------------------
				-- Incremental Refresh including M-Files Deletes
				-------------------------------------------------------------	
				--EXEC spMFUpdateTableWithLastModifiedDate
					--	@UpdateMethod = @UpdateMethod_1_MFilesToMFSQL
					--	,@Return_LastModified = @MFLastUpdateDate OUTPUT
					--	,@TableName = @MFTableName
					--	,@debug =@Debug

			DECLARE @NewObjectXml NVARCHAR(MAX);
		
			DECLARE @StatusFlag_1_MFilesIsNewer TINYINT = 1;
			DECLARE @StatusFlag_5_NotInMFSQL TINYINT = 5;			

			SET @ProcedureStep = 'spMFTableAudit'
				IF @debug > 9
				  RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep);

			SET @StartTime = GETUTCDATE()
			EXEC @return_value = dbo.spMFTableAudit
				@Debug = @Debug
			,	@MFTableName = @MFTableName
			  , @SessionIDOut = @MFAuditHistorySessionID OUTPUT
			  , @NewObjectXml = @NewObjectXml OUTPUT;

				SET @error = @@ERROR
				SET @LogStatusDetail = CASE WHEN (@error <> 0 OR @return_value = -1) THEN 'Failed'
											WHEN @return_value IN(1,0) THEN 'Complete'
											ELSE 'Exception'
											END

		  		SET @LogTextDetail =  ' Return Value: ' + CAST(@return_value AS NVARCHAR(256))
				SET @LogColumnName = 'MFAuditHistorySessionID '
				SET @LogColumnValue = CAST(@MFAuditHistorySessionID AS NVARCHAR(256))

                EXEC @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , @LogType = @LogTypeDetail
                  , @LogText = @LogTextDetail
                  , @LogStatus = @LogStatusDetail
                  , @StartTime = @StartTime
                  , @MFTableName = @MFTableName
                  , @ColumnName = @LogColumnName
                  , @ColumnValue = @LogColumnValue
                  , @LogProcedureName = @ProcedureName
                  , @LogProcedureStep = @ProcedureStep
                  , @debug = @debug;


			IF EXISTS ( SELECT  1
						FROM    dbo.MFAuditHistory
						WHERE   SessionID = @MFAuditHistorySessionID
								AND StatusFlag IN ( @StatusFlag_1_MFilesIsNewer, @StatusFlag_5_NotInMFSQL ) )
			   BEGIN

				SET @ProcedureStep = 'Get New/Updated ObjIDs from MFAuditHistory'

		  				
					 IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL
						DROP TABLE  #ObjIdList;
					 CREATE TABLE #ObjIdList
							(
							  [ObjId] INT PRIMARY KEY
							);

					 INSERT #ObjIdList
							( [ObjId]
							)
							SELECT  [ObjID]
							FROM    dbo.MFAuditHistory
							WHERE   SessionID = @MFAuditHistorySessionID
									AND StatusFlag IN ( @StatusFlag_1_MFilesIsNewer, @StatusFlag_5_NotInMFSQL );

					SET @rowcount = @@ROWCOUNT
					IF @debug > 9
					BEGIN
					  SET @DebugText = @DefaultDebugText + ' %d record(s) '	
					  RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep, @rowcount);
					END

					SET @ProcedureStep = 'Group ObjID Lists: EXEC spMFUpdateTable_ObjIds_GetGroupedList'
		
					 IF OBJECT_ID('tempdb..#ObjIdGroups') IS NOT NULL
						DROP TABLE  #ObjIdGroups;
					 CREATE TABLE #ObjIdGroups
							(
							  [GroupNumber] INT PRIMARY KEY
							, [ObjIds] NVARCHAR(4000)
							);

					 INSERT #ObjIdGroups
							( GroupNumber
							, ObjIds
							)
	
	
							EXEC spMFUpdateTable_ObjIds_GetGroupedList
								@Debug = @Debug
								

						SET @rowcount = @@ROWCOUNT
						IF @debug > 9
						BEGIN
						  SET @DebugText = @DefaultDebugText + ' %d group(s) '	
						  RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep, @rowcount);
						END

					 --Loop through Groups of ObjIDs
					 DECLARE @CurrentGroup INT
						   , @ObjIds_toUpdate NVARCHAR(4000);

					 SELECT @CurrentGroup = MIN(GroupNumber)
					 FROM   #ObjIdGroups;
					 WHILE @CurrentGroup IS NOT NULL
						   BEGIN
		
								 SELECT @ObjIds_toUpdate = ObjIds
								 FROM   #ObjIdGroups
								 WHERE  GroupNumber = @CurrentGroup;	 

							SET @ProcedureStep = 'EXEC spMFUpdateTable @UpdateMethod_1_MFilesToMFSQL'
							
							
				SET @StartTime = GETUTCDATE()
				SET @LogTextDetail =  ' for Group# '+ ISNULL(CAST(@CurrentGroup AS VARCHAR(20)),'(null)'); 
				SET @LogStatusDetail = 'Started'
				SET @LogColumnName = ''
				SET @LogColumnValue = ''

                EXEC [dbo].[spMFProcessBatchDetail_Insert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , @LogType = @LogTypeDetail
                  , @LogText = @LogTextDetail
                  , @LogStatus = @LogStatusDetail
                  , @StartTime = @StartTime
                  , @MFTableName = @MFTableName
                  , @ColumnName = @LogColumnName
                  , @ColumnValue = @LogColumnValue
                  , @LogProcedureName = @ProcedureName
                  , @LogProcedureStep = @ProcedureStep
                  , @debug = @debug;

		
							
							
							IF @debug > 9
							BEGIN
							  RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep);
							END
								SET @StartTime = GETUTCDATE()
								 EXEC @return_value = [dbo].[spMFUpdateTable]
									@MFTableName = @MFTableName
								  , @UpdateMethod = @UpdateMethod_1_MFilesToMFSQL --M-Files to MFSQL
								  , @UserId = NULL
								  , @MFModifiedDate = NULL
								  , @ObjIDs = @ObjIds_toUpdate -- CSV List
								  , @Update_IDOut = @Update_IDOut OUTPUT
								  , @ProcessBatch_ID = @ProcessBatch_ID
								  , @Debug = @Debug;


								SET @error = @@ERROR
								SET @LogStatusDetail = CASE WHEN (@error <> 0 OR @return_value = -1) THEN 'Failed'
															WHEN @return_value IN(1,0) THEN 'Complete'
															ELSE 'Exception'
															END

								SET @LogText =  'Return Value: ' + CAST(@return_value AS NVARCHAR(256))
								SET @LogColumnName = 'MFUpdate_ID '
								SET @LogColumnValue = CAST(@Update_IDOut AS NVARCHAR(256))

								EXEC @return_value = [dbo].[spMFProcessBatchDetail_Insert]
									@ProcessBatch_ID = @ProcessBatch_ID
								  , @LogType = @LogTypeDetail
								  , @LogText = @LogTextDetail
								  , @LogStatus = @LogStatusDetail
								  , @StartTime = @StartTime
								  , @MFTableName = @MFTableName
								  , @ColumnName = @LogColumnName
								  , @ColumnValue = @LogColumnValue
								  , @LogProcedureName = @ProcedureName
								  , @LogProcedureStep = @ProcedureStep
								  , @debug = @debug;

								 SELECT @CurrentGroup = MIN(GroupNumber)
								 FROM   #ObjIdGroups
								 WHERE  GroupNumber > @CurrentGroup;
						   END;	 --WHILE @CurrentGroup IS NOT NULL	

			   END;	 --IF EXISTS(SELECT 1 FROM dbo.MFAuditHistory WHERE SessionId = @SessionID AND StatusFlag IN(1,5))

		END	-- IF @UpdateTypeID = @UpdateType_1_Incremental

		SET @ProcedureStep = 'SELECT MFLastUpdateDate (UTC)';
		SET @StartTime = GETUTCDATE()

			SET @sql = N'
					SELECT @MFLastUpdateDate = DATEADD(hour,(DATEDIFF(hour,GETUTCDATE(),GETDATE())),MAX(MF_Last_Modified))
					FROM dbo.' + @MFTableName + N'
					WHERE Deleted = 0 '

			SET @sqlParam = N'
								@MFLastUpdateDate SMALLDATETIME OUTPUT
							'

			EXEC sys.sp_executesql   @sql
									,@sqlParam
									,@MFLastUpdateDate = @MFLastUpdateDate OUTPUT

			SET @error = @@ERROR
			SET @LogStatusDetail = CASE WHEN (@error <> 0) THEN 'Failed'
										ELSE 'Complete'
										END
								
			Set @LogTypeDetail = 'Status'
			SET @LogTextDetail =  CONVERT(VARCHAR(20),@MFLastUpdateDate,120)
			SET @LogStatusDetail = 'Completed'
			SET @LogColumnName = ''
			SET @LogColumnValue = ''

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
				, @LogType = @ProcedureName
				, @LogText = @LogTextDetail
				, @LogStatus = @LogStatusDetail		
				, @StartTime = @StartTime
				, @MFTableName = @MFTableName
				, @ColumnName = @LogColumnName
				, @ColumnValue = @LogColumnValue
				, @LogProcedureName = @ProcedureName
				, @LogProcedureStep = @ProcedureStep
				, @debug = @debug;
				

END	 --REFRESH M-FILES --> MFSQL


	  SET NOCOUNT OFF;
      RETURN 1
      END TRY

      BEGIN CATCH
          -----------------------------------------------------------------------------
          -- INSERTING ERROR DETAILS INTO LOG TABLE
          -----------------------------------------------------------------------------
          INSERT    INTO MFLog
                    ( SPName
                    , ProcedureStep
                    , ErrorNumber
                    , ErrorMessage
                    , ErrorProcedure
                    , ErrorState
                    , ErrorSeverity
                    , ErrorLine
                    )
          VALUES    ( @ProcedureName
                    , @ProcedureStep
                    , ERROR_NUMBER()
                    , ERROR_MESSAGE()
                    , ERROR_PROCEDURE()
                    , ERROR_STATE()
                    , ERROR_SEVERITY()
                    , ERROR_LINE()
                    );
		  
          -----------------------------------------------------------------------------
          -- DISPLAYING ERROR DETAILS
          -----------------------------------------------------------------------------
          SELECT Error_number()     AS ErrorNumber
                 ,Error_message()   AS ErrorMessage
                 ,Error_procedure() AS ErrorProcedure
                 ,Error_state()     AS ErrorState
                 ,Error_severity()  AS ErrorSeverity
                 ,Error_line()      AS ErrorLine
				 ,@ProcedureName	AS ProcedureName
				 ,@ProcedureStep	AS ProcedureStep

          RETURN -1
      END CATCH

END

GO
 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 30.001.spGetImageScannedData.sql' 
PRINT '**********************************************************************'

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.scancap.GetScannedData';

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINES].[ROUTINE_NAME] = 'GetScannedData' --name of procedure
          AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINES].[ROUTINE_SCHEMA] = 'scancap'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [ScanCap].[GetScannedData]
AS
    SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [ScanCap].[GetScannedData]
    @ProcessBatch_ID INT = 0 OUTPUT,
    @Debug SMALLINT = 0
AS /*************************************************************************
STEP
NOTES

stage 1
get all inv docs that is not yet matched
get data for all new docs
	if no data - validation message
get all data that is not yet matched
	if not included in match list - error
get existing vouchers and match
	update mathc messages

Stage 2
fetch new vouchers
fetch unmatched inv docs
	match to existing

*/

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
    BEGIN

        DECLARE @ProcedureName AS NVARCHAR(128) = 'ScanCap.GetScannedData';
        DECLARE @ProcedureStep AS NVARCHAR(128) = 'Set Variables';
        DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
        DECLARE @DebugText AS NVARCHAR(256) = '';


        DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
        DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
        DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
        DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
        DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;

        DECLARE @UTCDate AS DATETIME = GETUTCDATE();
        DECLARE @Now AS DATETIME = GETDATE();
        DECLARE @StartTime AS DATETIME;
        DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
        DECLARE @RunTime AS DECIMAL(18, 4) = 0;
        DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;
        DECLARE @Validation_ID INT;
        DECLARE @ColumnName NVARCHAR(128);
        DECLARE @ColumnValue NVARCHAR(256);
        DECLARE @Update_ID INT;

        DECLARE @rowcount AS INT = 0;
        DECLARE @return_value AS INT = 0;
        DECLARE @sql NVARCHAR(MAX) = N'';
        DECLARE @sqlParam NVARCHAR(MAX) = N'';
        DECLARE @sqlExists BIT = 0;
        DECLARE @count INT = 0;

        -------------------------------------------------------------
        -- Global Constants
        -------------------------------------------------------------
        DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
        DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0;
        DECLARE @Process_ID_1_Update_MergeInsert TINYINT = 1;
        DECLARE @Process_ID_5_ObjIDs_MergeDelete TINYINT = 5;
        DECLARE @Process_ID_6_ObjIDs_MergeUpdate TINYINT = 6;

        DECLARE @UpdateType_0_FullRefresh TINYINT = 0;
        DECLARE @UpdateType_1_Incremental TINYINT = 1;
        DECLARE @UpdateType_2_Deletes TINYINT = 2;
        DECLARE @Status_ID_0_Initiated TINYINT = 0;
        DECLARE @Status_ID_1_DataReceived TINYINT = 1;
        DECLARE @Status_ID_2_MFUpdated TINYINT = 2;
        DECLARE @WriteToMFiles_No TINYINT = 0;
        DECLARE @VoucherPaidFlag_No TINYINT = 0;

        -------------------------------------------------------------
        -- Class Table Specific Constants
        -------------------------------------------------------------

        DECLARE @State_ID INT;
        DECLARE @workflow_ID INT;
        DECLARE @JobUpdateStatus NVARCHAR(128);
        DECLARE @JobUpdateStatus_ID INT;
        DECLARE @MFUpdate_ID INT;
        DECLARE @MFLastUpdateDate SMALLDATETIME;
        DECLARE @MFTableName NVARCHAR(128);

    END;

    /*************************************************************************
STEP  States that is regarded as matched
NOTES
select * from [dbo].[MFvwScanCaptureStates]
*/


    BEGIN TRY


        SET @ProcedureStep = 'Set Valid State_id for Scan Capture';

        SET @StartTime = GETUTCDATE();

        DECLARE @State_IDs AS TABLE ([MFID] INT);

        INSERT INTO @State_IDs
        (
            [MFID]
        )
        SELECT [cpscs].[StateMFID]
        FROM [dbo].[MFvwScanCaptureStates] AS [cpscs]
        WHERE [cpscs].[State] IN ( 'Scanned for archive', 'Scan matched' );

        IF @Debug > 10
            SELECT *
            FROM @State_IDs AS [sid];



        /*************************************************************************************
	UPDATE FROM M-FILES
*************************************************************************************/

        SET @ProcedureStep = 'Update Invoice Documents from M-files';

        BEGIN
            SET @MFTableName = 'MFVendorInvoiceDocument';
            --- position this at the start of the process to be measured			
            SET @LogTypeDetail = @ProcedureName;
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Started';
            SET @Validation_ID = NULL;
            -- 2 = sync; 3= MF error 4= SQL Error


            EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = NULL,
                @ColumnName = '',
                @ColumnValue = '',
                @Update_ID = NULL,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;


            /*
Get Vendor Invoice Docs with spmfUpdateTablewithLastModifiedDate for VendorInvoiceDoc 
Update ScanLog with lastModifiedDate
	
*/
            -------------------------------------------------------------
            -- Update from M-Files
            -------------------------------------------------------------





            SET @StartTime = GETUTCDATE();
            IF @Debug > 1
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);


            EXEC @return_value = [dbo].[spMFUpdateMFilesToMFSQL] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
                @UpdateTypeID = @UpdateMethod_1_MFilesToMFSQL,                                               -- tinyint
                @MFTableName = @MFTableName,                                                                 -- nvarchar(128)
                @MFLastUpdateDate = @MFLastUpdateDate OUTPUT,                                                -- smalldatetime
                @debug = @Debug; -- tinyint

        END;




        /*************************************************************************
STEP Get invoice docs that is not matched
NOTES

*/
        BEGIN

            SET @ProcedureStep = 'Insert new images into #newInvDoc';
            IF @Debug > 1
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);


            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = @ProcedureName;
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Started';
            SET @LogColumnName = '';
            SET @LogColumnValue = '';

            EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;





            CREATE TABLE [#NewInvDoc]
            (
                [FileName] NVARCHAR(100),
                [Data_Exists] BIT,
                [Image_id] INT
            );


            /*************************************************************************
STEP Get invoice docs that is not matched
NOTES

*/

            SET @StartTime = GETUTCDATE();

            INSERT INTO [#NewInvDoc]
            (
                [FileName],
                [Image_id]
            )
            SELECT Scan_Capture_Ref,
                [cvid].[ID]
            FROM [dbo].[MFVendorInvoiceDocument] AS [cvid]
            WHERE NOT EXISTS
            (
                SELECT 1 FROM @State_IDs WHERE [@State_IDs].[MFID] = [cvid].[State_ID]
            )
                  AND [cvid].[Deleted] = 0;


            SET @rowcount = @@ROWCOUNT;

            UPDATE [nid]
            SET [nid].[Data_Exists] = 1
            FROM ScanCap.ScanCaptureLog i
                INNER JOIN [#NewInvDoc] AS [nid]
                    ON [nid].[FileName] = [i].[FileName]
            WHERE nid.[FileName] IS NOT NULL;


            --       IF @JobUpdateStatus_ID = @Status_ID_0_Initiated
            SET @ProcedureStep = 'Scanned records inserted';
            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = @ProcedureName;
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Completed';
            SET @LogColumnName = 'Count of Scanned records';
            SET @LogColumnValue = CAST(@rowcount AS VARCHAR(10));

            EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;


            IF @Debug > 10
            BEGIN
                SELECT *
                FROM [#NewInvDoc] AS [nid];
            END;

            SET @DebugText = @DefaultDebugText + 'Inv Images to update: %i';
            IF @Debug > 1
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);

        END;

        /*************************************************************************
STEP setup data from scanned table
NOTES
*/

        /*
THIS SECTION TO BE UPDATED WITH DYNAMIC COLUMN MAPPING
*/
        BEGIN

            SET @ProcedureStep = 'Get Scanned data';
            SET @StartTime = GETUTCDATE();
            SET @LogTypeDetail = @ProcedureName;
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Started';
            SET @LogColumnName = '';
            SET @LogColumnValue = '';

            EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @ColumnName = @LogColumnName,
                @ColumnValue = @LogColumnValue,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;


            CREATE TABLE [#VendorInvoiceDoc]
            (
                [id] INT IDENTITY,
                [Scan_Capture_Ref] NVARCHAR(100) NOT NULL,
                [Invoice_Num] VARCHAR(100) NULL,
                [Invoice_Date] DATETIME NULL,
                [Vendor_Name] VARCHAR(100) NULL,
                [PO_Number] VARCHAR(100) NULL,
                [Invoice_Amount] FLOAT NULL,
                [Vendor_Code] VARCHAR(100) NULL,
                [Tax] FLOAT NULL,
                [Sub_Total] FLOAT NULL,
                [Freight] FLOAT NULL,
                [Other_Amount] FLOAT NULL,
                [Deposit] FLOAT NULL,
                [Validation_Message] NVARCHAR(4000),
                [MatchValidation_ID] INT,
                [MFVersion] INT
                    DEFAULT 0
            );

            CREATE UNIQUE CLUSTERED INDEX [UCX_#VendorInvoiceDoc]
            ON [#VendorInvoiceDoc] ([Scan_Capture_Ref]);

            BEGIN
                INSERT INTO [#VendorInvoiceDoc]
                (
                    [Scan_Capture_Ref],
                    [Invoice_Num],
                    [Invoice_Date],
                    [Vendor_Name],
                    [PO_Number],
                    [Invoice_Amount],
                    [Vendor_Code],
                    [Tax],
                    [Sub_Total],
                    [Freight],
                    [Other_Amount],
                    [Deposit],
                    [Validation_Message],
                    [MatchValidation_ID]
                )
                SELECT DISTINCT
                    [i].[FileName],
                    [i].[INVOICE NO],
                    [i].[INVOICE DATE],
                    [i].[VENDOR NAME],
                    [i].[PO NUMBER],
                    CAST([i].[TOTAL AMOUNT] AS FLOAT),
                    [i].[VENDOR CODE],
                    CAST([i].[TAX] AS FLOAT),
                    CAST([i].[SUBTOTAL] AS FLOAT),
                    CAST([i].[SHIPPING AND HANDLING] AS FLOAT),
                    CAST([i].[OTHER AMOUNT] AS FLOAT),
                    CAST([i].[DEPOSIT] AS FLOAT),
                    'Scanned data is found',
                    0
                FROM dbo.Ancora_Invoices AS [i]
                    INNER JOIN [#NewInvDoc] AS [nid]
                        ON [nid].[FileName] = [i].[FileName];

                /*
END OF SECTION FOR DYNAMIC COLUMN UPDATE
*/

                SET @rowcount = @@ROWCOUNT;

                IF @Debug > 10
                BEGIN
                    SELECT *
                    FROM [#NewInvDoc] AS [nid];
                END;

                SET @DebugText = @DefaultDebugText + 'Data to be updated: %i';
                SET @ProcedureStep = 'Get scanned data: #VendorInvoiceDoc';
                IF @Debug > 1
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount);



                SET @LogTypeDetail = @ProcedureName;
                SET @LogTextDetail = @ProcedureStep;
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnName = 'Invoice Count';
                SET @LogColumnValue = CAST(@rowcount AS VARCHAR(100));

                EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                    @LogType = @LogTypeDetail,
                    @LogText = @LogTextDetail,
                    @LogStatus = @LogStatusDetail,
                    @StartTime = @StartTime,
                    @MFTableName = @MFTableName,
                    @Validation_ID = NULL,
                    @ColumnName = @LogColumnName,
                    @ColumnValue = @LogColumnValue,
                    @Update_ID = NULL,
                    @LogProcedureName = @ProcedureName,
                    @LogProcedureStep = @ProcedureStep,
                    @debug = @Debug;

            END;
        END;





        /*
  SELECT *          FROM    MFvwScanCaptureStates scs
*/
        SET @MFTableName = 'MFVendor';
        SET @ProcedureStep = 'Matching Vendor ' + @MFTableName;

        BEGIN


            SELECT @State_ID = [scs].[StateMFID],
                @workflow_ID = [scs].[WorkflowMFID]
            FROM [dbo].[MFvwScanCaptureStates] [scs]
            WHERE [scs].[State] = 'Scanned not matched';


            /*
Update vendors
Select * from MFVendor
*/

            EXEC [dbo].[spMFUpdateTableWithLastModifiedDate] @UpdateMethod = 1, -- int
                @TableName = @MFTableName,                                      -- sysname
                @Return_LastModified = NULL,                                    -- datetime
                @Update_IDOut = @Update_ID,                                     -- int
                @debug = 0,                                                     -- smallint
                @ProcessBatch_ID = @ProcessBatch_ID; -- int

            CREATE TABLE [#VendorScanList]
            (
                [VendorName] NVARCHAR(100),
				VendorCode NVARCHAR(100),
                [Objid] INT
				
            );

            INSERT INTO [#VendorScanList]
            (
                [VendorName], VendorCode
            )

			SELECT distinct vid.Vendor_name, VID.Vendor_Code FROM #VendorInvoiceDoc AS VID

			UPDATE vsl
			SET VSL.Objid = mv.objid
            FROM #VendorScanList AS VSL
			LEFT JOIN [dbo].[MFVendor] AS [mv]
			ON mv.Vendor_Code = vsl.Vendorcode
   --             CROSS APPLY [dbo].[fnMFParseDelimitedString]([mv].[Vendor_Name_Scan_Match_ID],
   --                                                             ','
   --                                                         ) AS [fmpds]
   --             LEFT JOIN [dbo].[MFvwVendorNameScanMatch] AS [mfvnsm]
   --                 ON [fmpds].[ListItem] = [mfvnsm].[MFID_ValueListItems]
            WHERE mv.[Deleted] = 0;
            /*

START OF SECTION FOR DYNAMIC COLUMN MAPPING
*/
            SET @StartTime = GETUTCDATE();

            UPDATE [cid]
            SET [cid].[Process_ID] = @Process_ID_1_Update_MergeInsert,
                --                   cid.[Ap_Invoice_ID] = ci.[ObjID] ,
                [cid].[Vendor_ID] = [cv].[Objid],
                [cid].[Invoice_Amount] = [sc].[Invoice_Amount],
                [cid].[Invoice_Date] = [sc].[Invoice_Date],
                [cid].[Invoice_Num] = [sc].[Invoice_Num],
                --        , [cid].[Po_Num] = [sc].[PO_Number]
                [cid].[State_ID] = @State_ID,
                [cid].[Workflow_ID] = @workflow_ID,
                --      , [cid].[Process_Batch] = @ProcessBatch_ID
                --- ScanCaputured
                [cid].[Process_Message] = CASE
                                              WHEN ISNULL([cv].[VendorCode],'') = '' AND ISNULL([cv].[VendorName],'') <> ''
                                                             THEN
                                                  'Vendor not in M-Files. ' + ISNULL([sc].[Vendor_Name],'No Vendor')
                                              WHEN ISNULL([cv].[VendorName],'') = '' THEN
                                                 'No Vendor Captured'
                                              ELSE
                                                  'Scanned data added'
                                          END
            FROM [dbo].[MFVendorInvoiceDocument] [cid]
                INNER JOIN [#VendorInvoiceDoc] AS [sc]
                    ON [cid].[Scan_Capture_Ref] = [sc].[Scan_Capture_Ref]
                LEFT JOIN [#VendorScanList] [cv]
                    ON [cv].[VendorName] = [sc].[Vendor_Name]
            WHERE cid.[Deleted] = 0;

            SET @rowcount = @@ROWCOUNT;

        /*
END OF SECTION FOR DYNAMIC COLUMN MAPPING
*/

        END;

        /*************************************************************************
STEP  update invoice images without any scanned data
NOTES
*/

        SET @MFTableName = 'MFVendorInvoiceDocument';
        SET @ProcedureStep = 'Validate image data exists for ' + @MFTableName;


        UPDATE [cvid]
        SET [cvid].[Process_ID] = 1,
            [cvid].[Process_Message] = 'Image Scanned Data is not available - Delete from M-Files and rescan through Ancora',
            [cvid].[Process_Batch] = ISNULL(@ProcessBatch_ID, 0)
        FROM [#NewInvDoc] AS [nid]
            INNER JOIN [dbo].[MFVendorInvoiceDocument] AS [cvid]
                ON [nid].[Image_id] = [cvid].[ID]
        WHERE [nid].[Data_Exists] IS NULL
              AND cvid.[Deleted] = 0;

        /*
Create APInvoice for all invoice docs
*/

        SET @MFTableName = 'MFAPInvoice';
        SET @ProcedureStep = 'Create APInvoice in ' + @MFTableName;

        DECLARE @Class_ID INT;

        SELECT @Class_ID = [MFClass].[MFID]
        FROM [dbo].[MFClass]
        WHERE [MFClass].[TableName] = @MFTableName;
        SET @State_ID = (SELECT StateMFID FROM MFvwVendorInvoiceFlow WHERE StateAlias = 'New_Invoice')
        SET @workflow_ID = (SELECT TOP 1 workflowMFID FROM MFvwVendorInvoiceFlow )

        /*
START OF SECTION FOR DYNAMIC COLUMN MAPPING

*/
        INSERT INTO [dbo].[MFApInvoice]
        (
            [Class_ID],
            [Invoice_Amount],
            [Invoice_Date],
            [Invoice_Num],
            [Po_Num],
            [Purpose],
            [Scan_Capture_Ref],
            [State_ID],
            [Vendor_ID],
            [Workflow_ID],
            [Name_Or_Title],
            [Process_ID]
        )
        SELECT DISTINCT
            @Class_ID,
            CAST([i].[TOTAL AMOUNT] AS MONEY),
            [i].[INVOICE DATE],
            CAST([i].[INVOICE NO] AS NVARCHAR(100)),
            CAST([i].[PO NUMBER] AS NVARCHAR(100)),
            NULL,
            [cvid].[Scan_Capture_Ref],
            @State_ID,
            [cvid].[Vendor_ID],
            @workflow_ID,
            'New',
            @Process_ID_1_Update_MergeInsert
        FROM [dbo].[MFVendorInvoiceDocument] AS [cvid]
            LEFT JOIN [ScanCap].[ScanCaptureLog] AS [scl]
                ON [cvid].[Scan_Capture_Ref] = [scl].[FileName]
            LEFT JOIN dbo.Ancora_Invoices AS [i]
                ON [scl].[FileName] = [i].[FileName]
        WHERE [cvid].[Ap_Invoice_ID] IS NULL
              AND [cvid].[State_ID] IS NOT NULL
              AND cvid.[Deleted] = 0
              AND i.[FileName] IS NOT NULL;

        /*
END OF SECTION FOR DYNAMIC COLUMN MAPPING
*/

        SET @LogTypeDetail = 'System';
        SET @LogTextDetail = @ProcedureStep;
        SET @LogStatusDetail = 'In Progress';
        SET @Validation_ID = NULL;
        -- 2 = sync; 3= MF error 4= SQL Error
        SET @LogColumnName = 'Process_ID 1 Count';
        -- either columnname or description of item that is being counted/summed
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(100));

        EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = NULL,
            @ColumnName = @LogColumnName,
            @ColumnValue = @LogColumnValue,
            @Update_ID = NULL,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;

        SELECT @count = COUNT(*)
        FROM [dbo].[MFApInvoice] [cid]
        WHERE [cid].[Process_ID] = 1;

        EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName, -- nvarchar(128)
            @UpdateMethod = @UpdateMethod_0_MFSQLToMFiles,        -- int
            @Update_IDOut = @Update_ID,                           -- int
            @ProcessBatch_ID = @ProcessBatch_ID,                  -- int
            @Debug = @Debug; -- smallint		


        IF @Debug > 10
        BEGIN
            SELECT *
            FROM [dbo].[MFAPInvoice] AS [cvid]
            WHERE [cvid].[Process_ID] = 1;
        END;

        SET @DebugText = @DefaultDebugText + ' Updated: %i with Update_ID: %i';
        IF @Debug > 1
            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount, @Update_ID);


        /*
Update InvoiceDoc with AP invoice id
SELECT * FROM [dbo].[MFvwScanCaptureStates] AS [cpscs]
*/

        SELECT @State_ID = [cpscs].[StateMFID]
        FROM [dbo].[MFvwScanCaptureStates] AS [cpscs]
        WHERE [cpscs].[State] = 'Scan matched';

        UPDATE [cvid]
        SET [cvid].[Ap_Invoice_ID] = [ci].[ObjID],
            [cvid].[State_ID] = @State_ID,
            [cvid].[Process_Batch] = @ProcessBatch_ID,
            cvid.[Process_Message] = cvid.[Process_Message] + ' AP invoice matched'
        FROM [dbo].[MFVendorInvoiceDocument] AS [cvid]
            LEFT JOIN [dbo].[MFApInvoice] AS [ci]
                ON [cvid].[Scan_Capture_Ref] = [ci].[Scan_Capture_Ref]
        --LEFT JOIN [ScanCap].[ScanCaptureLog] AS [scl] ON [cvid].[Scan_Capture_Ref] = [scl].[FileName]
        --LEFT JOIN [dbo].Ancora_Invoices AS [i] ON [scl].[FileName] = [i].[FileName]
        WHERE [cvid].[Ap_Invoice_ID] IS NULL
              AND [cvid].[State_ID] IS NOT NULL
              AND ci.[Deleted] = 0;


        /*
Insert line items 

*/

        /*
Create APInvoice for all invoice docs
*/
        SET @MFTableName = N'MFAPInvoiceLine';
        SET @ProcedureStep = 'Create APInvoice Lines in ' + @MFTableName;

        SELECT @Class_ID = [MFClass].[MFID]
        FROM [dbo].[MFClass]
        WHERE [MFClass].[TableName] = @MFTableName;
        SET @State_ID = NULL;
        SET @workflow_ID = NULL;

        /*
START OF SECTION ON DYNAMIC COLUMN MAPPING
*/


        INSERT INTO [dbo].[MFApInvoiceLine]
        (
            [Class_ID],
            [Line_Amount],
            [Line_Desc],
            [Line_no],
            [Owner_Ap_Voucher_ID],
            [Quantity],
            [Scan_Capture_Ref],
            [State_ID],
            [Unit_Price],
            [Workflow_ID],
            [Name_Or_Title],
            [Process_ID]
        )
        SELECT @Class_ID,
            CAST([i].[LINE TOTAL] AS MONEY),
            CAST([i].[DESCRIPTION] AS NVARCHAR(100)),
            ROW_NUMBER() OVER (PARTITION BY i.[FileName] ORDER BY i.ID) AS Linenumber,
            [cvid].Ap_Invoice_ID,
            CAST([i].QTY AS FLOAT),
            [cvid].[Scan_Capture_Ref],
            @State_ID,
            CAST([i].[UNIT PRICE] AS MONEY),
            @workflow_ID,
            'New',
            @Process_ID_1_Update_MergeInsert
        FROM [dbo].[MFVendorInvoiceDocument] AS [cvid]
            LEFT JOIN [ScanCap].[ScanCaptureLog] AS [scl]
                ON [cvid].[Scan_Capture_Ref] = [scl].[FileName]
            LEFT JOIN [dbo].Ancora_Invoices AS [i]
                ON [scl].[FileName] = [i].[FileName]
        WHERE [cvid].[Process_ID] = 1
              AND cvid.[Deleted] = 0
        ORDER BY i.ID DESC;

        /*
END OF SECTION FOR DYNAMIC COLUMN MAPPING
*/
        SET @LogTypeDetail = 'System';
        SET @LogTextDetail = @ProcedureStep;
        SET @LogStatusDetail = 'In Progress';
        SET @Validation_ID = NULL;
        -- 2 = sync; 3= MF error 4= SQL Error
        SET @LogColumnName = 'Process_ID 1 Count';
        -- either columnname or description of item that is being counted/summed
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(100));

        EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = NULL,
            @ColumnName = @LogColumnName,
            @ColumnValue = @LogColumnValue,
            @Update_ID = NULL,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;

        SELECT @count = COUNT(*)
        FROM [dbo].[MFApInvoiceLine] [cid]
        WHERE [cid].[Process_ID] = 1
              AND cid.[Deleted] = 0;

        EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName, -- nvarchar(128)
            @UpdateMethod = @UpdateMethod_0_MFSQLToMFiles,        -- int
            @Update_IDOut = @Update_ID,                           -- int
            @ProcessBatch_ID = @ProcessBatch_ID,                  -- int
            @Debug = @Debug; -- smallint		


        IF @Debug > 10
        BEGIN
            SELECT *
            FROM [dbo].[MFApInvoiceLine] AS [cvid]
            WHERE [cvid].[Process_ID] = 1;
        END;

        SET @DebugText = @DefaultDebugText + ' Updated: %i with Update_ID: %i';
        IF @Debug > 1
            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount, @Update_ID);





        /*
count updates due and only process if > 0
*/
        SET @MFTableName = N'MFVendorInvoiceDocument';
        SET @ProcedureStep = 'Update document data in ' + @MFTableName;


        --- position this at the start of the process to be measured			
        SET @LogTypeDetail = 'System';
        SET @LogTextDetail = @ProcedureStep;
        SET @LogStatusDetail = 'In Progress';
        SET @Validation_ID = NULL;
        -- 2 = sync; 3= MF error 4= SQL Error
        SET @LogColumnName = 'Process_ID 1 Count';
        -- either columnname or description of item that is being counted/summed
        SET @LogColumnValue = CAST(@rowcount AS VARCHAR(100));

        EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = NULL,
            @ColumnName = @LogColumnName,
            @ColumnValue = @LogColumnValue,
            @Update_ID = NULL,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;

        SELECT @count = COUNT(*)
        FROM [dbo].[MFVendorInvoiceDocument] [cid]
        WHERE [cid].[Process_ID] = 1
              AND cid.[Deleted] = 0;

        EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName, -- nvarchar(128)
            @UpdateMethod = @UpdateMethod_0_MFSQLToMFiles,        -- int
            @Update_IDOut = @Update_ID,                           -- int
            @ProcessBatch_ID = @ProcessBatch_ID,                  -- int
            @Debug = @Debug; -- smallint		


        IF @Debug > 10
        BEGIN
            SELECT *
            FROM [dbo].[MFVendorInvoiceDocument] AS [cvid]
            WHERE [cvid].[Process_ID] = 1;
        END;

        SET @DebugText = @DefaultDebugText + ' Updated: %i with Update_ID: %i';
        IF @Debug > 1
            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep, @rowcount, @Update_ID);



        BEGIN


            SET @LogTextDetail = @ProcedureStep + ' | Processed: ' + CAST(@count AS NVARCHAR(256));
            SET @LogStatusDetail = 'In Progress';
            SET @LogTypeDetail = 'System';
            SET @Validation_ID = NULL;
            SET @ColumnName = 'Processed count';
            SET @ColumnValue = CAST(@count AS VARCHAR(10));

            EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
                @LogType = @LogTypeDetail,
                @LogText = @LogTextDetail,
                @LogStatus = @LogStatusDetail,
                @StartTime = @StartTime,
                @MFTableName = @MFTableName,
                @Validation_ID = @Validation_ID,
                @ColumnName = @ColumnName,
                @ColumnValue = @ColumnValue,
                @Update_ID = NULL,
                @LogProcedureName = @ProcedureName,
                @LogProcedureStep = @ProcedureStep,
                @debug = @Debug;

            /*************************************************************************
STEP Update Scan Log with completed processed jobs.
NOTES
*/
            SET @ProcedureStep = 'Update ScanCaptureLog';
            BEGIN
                SET @RunTime_Total = DATEDIFF(MS,
                                                 @StartTime_Total,
                                                 GETUTCDATE()
                                             ) / 1000;
                UPDATE [scl]
                SET [scl].[LastModified] = GETDATE(),
                    [scl].[UpdateStatus] = 'MF Updated',
                    [scl].[DurationSeconds] = @RunTime_Total,
                    [scl].[Status_ID] = @Status_ID_2_MFUpdated
                FROM [ScanCap].[ScanCaptureLog] AS [scl]
                    INNER JOIN [#NewInvDoc] AS [nid]
                        ON [nid].[FileName] = [scl].[FileName]
                WHERE scl.[FileName] IS NOT NULL;

            END;


            DROP TABLE [#NewInvDoc];

            DROP TABLE [#VendorInvoiceDoc];

        END;
        RETURN 1;

    END TRY
    BEGIN CATCH

        -----------------------------------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        -----------------------------------------------------------------------------
        INSERT INTO [dbo].[MFLog]
        (
            [SPName],
            [ProcedureStep],
            [ErrorNumber],
            [ErrorMessage],
            [ErrorProcedure],
            [ErrorState],
            [ErrorSeverity],
            [ErrorLine]
        )
        VALUES
        (@ProcedureName,
            @ProcedureStep,
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            ERROR_PROCEDURE(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE()
        );

        -----------------------------------------------------------------------------
        -- DISPLAYING ERROR DETAILS
        -----------------------------------------------------------------------------
        SELECT ERROR_NUMBER() AS [ErrorNumber],
            ERROR_MESSAGE() AS [ErrorMessage],
            ERROR_PROCEDURE() AS [ErrorProcedure],
            ERROR_STATE() AS [ErrorState],
            ERROR_SEVERITY() AS [ErrorSeverity],
            ERROR_LINE() AS [ErrorLine],
            @ProcedureName AS [ProcedureName],
            @ProcedureStep AS [ProcedureStep];

        -----------------------------------------------------------------------------
        -- CLOSE PROCESS
        -----------------------------------------------------------------------------
        SET @RunTime_Total = DATEDIFF(MS, @StartTime_Total, GETUTCDATE()) / 1000;

        SET @LogStatusDetail = 'SQL Error';



        EXECUTE [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID,
            @LogType = @LogTypeDetail,
            @LogText = @LogTextDetail,
            @LogStatus = @LogStatusDetail,
            @StartTime = @StartTime,
            @MFTableName = @MFTableName,
            @Validation_ID = @Validation_ID,
            @ColumnName = @ColumnName,
            @ColumnValue = @ColumnValue,
            @Update_ID = NULL,
            @LogProcedureName = @ProcedureName,
            @LogProcedureStep = @ProcedureStep,
            @debug = @Debug;


        UPDATE [ProcessBatch]
        SET [ProcessBatch].[LogText] = LEFT(@LogTextDetail + CHAR(10) + ERROR_MESSAGE(), 4000),
            [ProcessBatch].[DurationSeconds] = @RunTime_Total,
            [ProcessBatch].[Status] = @LogStatusDetail
        FROM [dbo].[MFProcessBatch] [ProcessBatch]
        WHERE [ProcessBatch].[ProcessBatch_ID] = @ProcessBatch_ID;

        RETURN -1;

    END CATCH;



GO

 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.622.spMFResultMessageForUI.sql' 
PRINT '**********************************************************************'
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFResultMessageForUI]';
go

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFResultMessageForUI', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFResultMessageForUI'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFResultMessageForUI]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER  PROCEDURE spMFResultMessageForUI
    (
      -- Add the parameters for the function here
      @ClassTable VARCHAR(100) = NULL,
      @RowCount INT = NULL,
      @Processbatch_ID INT ,
      @MessageOUT NVARCHAR(4000) OUTPUT
    )
AS
    BEGIN
	-- Declare the return variable here
	
/*
UI Message function
*/

        DECLARE @Message NVARCHAR(4000);   
        DECLARE @SQLRecordCount INT ,
            @MFRecordCount INT ,
            @SyncError INT ,
            @Process_ID_1 INT ,
            @MFError INT ,
            @SQLError INT ,
            @LastModified SMALLDATETIME ,
            @MFLastModified SMALLDATETIME ,
            @SessionID INT ,
            @Status NVARCHAR(50) ,
            @ErrorMessage NVARCHAR(4000) ,
            @ClassName NVARCHAR(100);


        SELECT  @ClassName = Name
        FROM    MFClass mc
        WHERE   TableName = @ClassTable;


        DECLARE @Stats AS TABLE
            (
              ClassID INT ,
              Tablename VARCHAR(100) ,
              IncludeInApp INT ,
              SQLRecordCount INT ,
              MFRecordCount INT ,
              MFNotInSQL INT ,
              Deleted INT ,
              SyncError INT ,
              Process_ID_1 INT ,
              MFError INT ,
              SQLError INT ,
              LastModified SMALLDATETIME ,
              MFLastModified SMALLDATETIME ,
              sessionID INT,
			  Flag int
            );

        INSERT  INTO @Stats
                EXEC [dbo].[spMFClassTableStats] @ClassTableName = @ClassTable, -- nvarchar(128)
                    @Debug = 0;
 -- smallint
        SELECT  @ClassTable = [s].[Tablename] ,
                @SQLRecordCount = [s].[SQLRecordCount] ,
                @MFRecordCount = [s].[MFRecordCount] ,
                @SyncError = [s].[SyncError] ,
                @Process_ID_1 = [s].[Process_ID_1] ,
                @MFError = [s].[MFError] ,
                @SQLError = [s].[SQLError] ,
                @MFLastModified = [s].[MFLastModified] ,
                @SessionID = [s].[sessionID]
        FROM    @Stats AS [s];


        SET @ErrorMessage = CASE WHEN @SQLError <> 0
                                 THEN 'Synchronization Errors: '
                                      + CAST(@SyncError AS VARCHAR(10)) 
                                 ELSE ''
                            END;
        SET @ErrorMessage = ISNULL(@ErrorMessage, '')
            + CASE WHEN @MFError <> 0
                   THEN 'M-Files Processing Errors: '
                        + CAST(@MFError AS VARCHAR(10))
                   ELSE ''
              END;
        SET @ErrorMessage = ISNULL(@ErrorMessage, '')
            + CASE WHEN @SQLError <> 0
                   THEN 'SQL Processing Errors: '
                        + CAST(@SQLError AS VARCHAR(10)) 
                   ELSE ''
              END;
        SET @ErrorMessage = ISNULL(@ErrorMessage, '')
            + CASE WHEN @Process_ID_1 <> 0
                   THEN 'Records not processed: '
                        + CAST(@Process_ID_1 AS VARCHAR(10)) 
                   ELSE ''
              END;

        SELECT  @Message = ISNULL([mpb].[ProcessType],'Process') + ' | ' + ISNULL([mpb].[Status],'(status unknown)') 
				+ '\n' + ISNULL([mpb].[LogText],'(null)')
				+ '\n' + 'Process#: ' + isnull(CAST([mpb].[ProcessBatch_ID] AS VARCHAR(10)),'(null)')
				+ '\n' + 'Duration: ' + CAST(ISNULL([mpb].[DurationSeconds],0) AS VARCHAR(10)) + ' second(s)'
        FROM    [dbo].[MFProcessBatch] AS [mpb]
        WHERE   [mpb].[ProcessBatch_ID] = @Processbatch_ID;

        SELECT  @MessageOUT = @message 
                + CASE WHEN ISNULL(@ErrorMessage,'') = '' THEN ''
                       ELSE '\n' + '\n' +  'Error: ' + @ErrorMessage
                  END;

	-- Return the result of the function
        RETURN 1;

    END;
go

 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 30.601.ContMenu.sp.ScanData.sql' 
PRINT '**********************************************************************'

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.contMenu.ScanData';

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'ScanData'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'contMenu' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [ContMenu].[ScanData]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [ContMenu].[ScanData]
      (
        @Debug SMALLINT = 0,
		@id int,
       @OutPut VARCHAR(1000) OUTPUT
      )
AS
      SET NOCOUNT ON;
      DECLARE @ProcedureName AS NVARCHAR(128) = 'ContMenu.ScanData';
      DECLARE @ProcedureStep AS NVARCHAR(128) = 'Context Menu start';
      DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
      DECLARE @DebugText AS NVARCHAR(256) = '';		 
      DECLARE @ProcessBatch_ID INT;


      DECLARE @LogText AS NVARCHAR(MAX) = '';
      DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
      DECLARE @LogStatus AS NVARCHAR(50) = '';
      DECLARE @LogStatusDetail AS NVARCHAR(50) = '';
      DECLARE @LogType AS NVARCHAR(50) = ''
      DECLARE @LogTypeDetail AS NVARCHAR(50);
      DECLARE @Validation_ID INT = NULL;
      DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
      DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
      DECLARE @UTCDate AS DATETIME = GETUTCDATE();
      DECLARE @Now AS DATETIME = GETDATE();
      DECLARE @StartTime AS DATETIME;
      DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
      DECLARE @ProcessType AS NVARCHAR(50);  
      DECLARE @RunTime AS DECIMAL(18, 4) = 0;
      DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;


      DECLARE @Status_ID_0_Initiated INT = 0;
      DECLARE @Result_Value SMALLINT; 
      DECLARE @count INT;
      DECLARE @Rowcount INT;
      DECLARE @Message NVARCHAR(4000);
      DECLARE @MFTableName NVARCHAR(100);
      DECLARE @MFLastUpdateDate SMALLDATETIME;
      DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1;
        	
      BEGIN TRY
		 /*************************************************************************
		 STEP: PROCESS BATCH START
		 NOTES
		 */
            
            SET @ProcessType = 'Get Scanned Data';  
            SET @LogType = 'Status'
            SET @LogStatus = 'Started'
            SET @LogText = 'Updating scanned data'

            EXEC @Result_Value = [dbo].[spMFProcessBatch_Upsert]
                @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
              , -- int
                @ProcessType = @ProcessType
              , -- nvarchar(50)
                @LogType = @LogType
              , -- nvarchar(50)
                @LogText = @LogText
              , -- nvarchar(4000)
                @LogStatus = @LogStatus
              , -- nvarchar(50)
                @debug = @debug; -- tinyint
			
               
            SET @DebugText = ' ProcessBatch_ID: ' + ISNULL(CAST(@ProcessBatch_ID AS VARCHAR(30)), 'Process not started')
                + CHAR(10);
                       
            SET @DebugText = @DefaultDebugText + @DebugText;           
            IF @Debug >= 1
               RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );	


	
 --- position this at the start of the process to be measured			
            SET @LogTypeDetail = @LogType + ': ' + @ProcedureName 
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'In Progress'; 
            SET @Validation_ID = NULL;
 -- 2 = sync; 3= MF error 4= SQL Error
    

            EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
                @ProcessBatch_ID = @ProcessBatch_ID
              , @LogType = @LogTypeDetail
              , @LogText = @LogTextDetail
              , @LogStatus = @LogStatusDetail
              , @StartTime = @StartTime
              , @MFTableName = @MFTableName
              , @Validation_ID = NULL
              , @ColumnName = ''
              , @ColumnValue = ''
              , @Update_ID = NULL
              , @LogProcedureName = @ProcedureName
              , @LogProcedureStep = @ProcedureStep
              , @debug = @debug;
			
            

    
            
		 /*************************************************************************
		 STEP: BEGIN JOB TO PROCESS
		 NOTES
		 */
            BEGIN          
                    

                  DECLARE @ClassTable NVARCHAR(100);


                  SELECT    @ClassTable = 'Vendor Invoice Document'
				  
				          
SELECT * FROM [scancap].[ConfigurationMap]

                  EXEC @Result_Value = [ScanCap].[GetScannedData]
                    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                  , @Debug = @Debug;
		 
                  IF @Result_Value <> 1
                     BEGIN
                           SET @DebugText = @DefaultDebugText + ' failed unexpectedly '
                           RAISERROR(@DebugText,16,1,@ProcedureName,@ProcedureStep);
                     END

                  SET @Rowcount = NULL;

            END

	-------------------------------------------------------------
    -- Set end of process paramaters
    -------------------------------------------------------------

        
            SET @ProcedureStep = 'END RUN';
            IF @Debug = 1
               BEGIN
                     SET @LogText = 'END: ' + @DefaultDebugText + ' | ' + @LogText; 
                     RAISERROR(@LogText,10,1,@ProcedureName,@ProcedureStep);
               END;
	
            SET @RunTime_Total = DATEDIFF(MS, @StartTime_Total, GETUTCDATE()) / 1000;
                       


                 

/*************************************************************************
STEP Processbatch updated
NOTES
*/
            END_RUN:
            BEGIN
                  SET @ProcedureStep = 'END RUN';
                  SET @LogTypeDetail = 'Admin'; 
                  SET @LogTextDetail = @ProcedureStep;
                  SET @LogStatusDetail = 'Complete'; 
                  SET @Validation_ID = NULL; 
                  SET @LogColumnName = NULL; 
                  SET @LogColumnValue = NULL;


                  EXECUTE [dbo].[spMFProcessBatchDetail_Insert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , @LogType = @LogTypeDetail
                  , @LogText = @LogTextDetail
                  , @LogStatus = @LogStatusDetail
                  , @StartTime = @StartTime
                  , @MFTableName = @MFTableName
                  , @Validation_ID = NULL
                  , @ColumnName = @LogColumnName
                  , @ColumnValue = @LogColumnValue
                  , @Update_ID = NULL
                  , @LogProcedureName = @ProcedureName
                  , @LogProcedureStep = @ProcedureStep
                  , @debug = @debug;


                  SET @LogText = 'Invoice documents updated'; 
                  SET @LogStatus = 'Completed';
				  	
                  EXEC @Result_Value = [dbo].[spMFProcessBatch_Upsert]
                    @ProcessBatch_ID = @ProcessBatch_ID
                  , -- int
                    @ProcessType = @ProcessType
                  , -- nvarchar(50)
                    @LogType = @LogType
                  , -- nvarchar(50)
                    @LogText = @LogText
                  , -- nvarchar(4000)
                    @LogStatus = @LogStatus
                  , -- nvarchar(50)
                    @debug = @debug; -- tinyint

                  IF @Result_Value <> 1
                     BEGIN
                           SET @DebugText = @DefaultDebugText;           
                           RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );	
                     END
            END;
      		
            EXEC [dbo].[spMFResultMessageForUI]
                @ClassTable = @ClassTable
              , -- varchar(100)
                @RowCount = 0
              , -- int
                @Processbatch_ID = @Processbatch_ID
              , -- int
                @MessageOUT = @OutPut OUTPUT; -- nvarchar(4000)
			
            IF @Debug >= 1
               BEGIN
                     SET @DebugText = @DefaultDebugText + ': ' + @OutPut;           
                     RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );	
               END	
				
            RETURN 1;                                    


      END TRY
      BEGIN CATCH

            EXEC [dbo].[spMFResultMessageForUI]
                @ClassTable = @ClassTable
              , -- varchar(100)
                @RowCount = 0
              , -- int
                @Processbatch_ID = @Processbatch_ID
              , -- int
                @MessageOUT = @OutPut OUTPUT; -- nvarchar(4000)

            SET @OutPut = +'Error: Updating scanned records failed: ' + '\n' + @OutPut  
			 			

      END CATCH;
    



    

GO

 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 60.102.Ancora.MFContextMenu.data.sql' 
PRINT '**********************************************************************'

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
/*
	Initialize
	select * 
	from MFContextMenu

*/


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFContextMenu]';

IF EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFContextMenu'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
BEGIN
	DECLARE @rowcount INT
	DECLARE @Heading_ID INT;

	CREATE TABLE #temptable ( [ID] INT , [ActionName] varchar(250), [Action] varchar(1000), [ActionType] int, [Message] varchar(500), [SortOrder] int, [ParentID] int , IsAsync INT, UserGroupID int)
	INSERT INTO #temptable
	(ActionName,Action,ActionType,Message,SortOrder,ParentID, IsAsync, UserGroupID)
	VALUES
	(  N'<h4>Processing</h4>', N'', 0, N'Select an item from the list', 1, 0,0,1)

INSERT INTO #temptable
	(ActionName,Action,ActionType,Message,SortOrder,ParentID,IsAsync,UserGroupID)
	VALUES

	( N'Get Ancora Data', N'ContMenu.ScanData', 1, N'Are you sure you want to get Ancora Data ?', 2, null,1,1)
	
MERGE INTO dbo.MFContextMenu t

USING 
(SELECT ActionName,Action,ActionType,Message,SortOrder,ParentID,IsAsync,UserGroupID from #temptable) AS s
ON t.ActionName = S.ActionName
WHEN NOT MATCHED THEN
INSERT
(ActionName, ACTION, ActionType, MESSAGE, SortOrder, ParentID,IsAsync,UserGroupID)
VALUES
(s.ActionName, s.ACTION, s.ActionType, s.MESSAGE, s.SortOrder, s.ParentID,s.IsAsync,s.UserGroupID)
;

Select @Heading_ID = id FROM dbo.MFContextMenu AS MCM WHERE MCM.ActionName = '<h4>Processing</h4>';	

UPDATE dbo.MFContextMenu
SET ParentID = @Heading_ID
WHERE ActionName = 'Get Ancora Data'



DROP TABLE #temptable
	RAISERROR (N'     ... Table: Update done! ', 10, 1,@rowcount) WITH NOWAIT;
END	
ELSE
	RAISERROR (N'     ... Table: does not exist!', 10, 1) WITH NOWAIT; 


GO

 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 90.100.scancap.sp.DataForConfigurationMap.sql' 
PRINT '**********************************************************************'
/*
Get Ancora invoice columns

SELECT * FROM scancap.ConfigurationMap AS CM


*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.scancap.CreateConfigurationMap';

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'scancap',
    @ObjectName = N'CreateConfigurationMap', -- nvarchar(100)
    @Object_Release = '3.1.4.32', -- varchar(50)
    @UpdateFlag = 2;

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'CreateConfigurationMap'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'scancap' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [ScanCap].[CreateConfigurationMap]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE scancap.CreateConfigurationMap
AS


SET NOCOUNT ON;

DECLARE @Debug SMALLINT = 1;

DECLARE @varInvoiceHeader NVARCHAR(100) = 'AP Invoice';
DECLARE @varInvoiceLine NVARCHAR(100) = 'AP Invoice Line';
DECLARE @varInvoiceDocument NVARCHAR(100) = 'Vendor Invoice Document';
DECLARE @varVendor NVARCHAR(100) = 'Vendor';

TRUNCATE TABLE ScanCap.ConfigurationMap;



INSERT  INTO ScanCap.ConfigurationMap
        ( MFProperty ,
          MFproperty_MFID ,
          MFCLass ,
          ScannedColumn ,
          LastModified
        )
        SELECT  mp.Name ,
                mp.MFID ,
                MC.Name ,
                Ancora.ScannedColumn ,
                GETDATE()
        FROM    MFProperty mp
                INNER JOIN dbo.MFClassProperty AS MCP ON mp.ID = MCP.MFProperty_ID
                INNER JOIN dbo.MFClass AS MC ON MC.ID = MCP.MFClass_ID
                right JOIN ( SELECT  REPLACE(C.COLUMN_NAME, ' ', '_') AS ScannedColumn
                            FROM    INFORMATION_SCHEMA.COLUMNS AS C
                            WHERE   C.TABLE_NAME = 'Ancora_Invoices'
                                    AND C.TABLE_SCHEMA = 'dbo'
                                    AND C.COLUMN_NAME NOT IN ( 'migration',
                                                              'file_path',
                                                              'ftf_name',
                                                              'Image Path',
                                                              'ID', 'LinkID' )
                          ) Ancora ON mp.Alias = ScannedColumn
        WHERE   MC.Name IN ( @varInvoiceHeader, @varInvoiceLine,
                             @varInvoiceDocument, @varVendor )
                AND mp.MFID > 1000;
    

GO
 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 90.110.Script.Scancap.CreateConfigurationMapData.sql' 
PRINT '**********************************************************************'


/*

Script to run the [ScanCap].[CreateConfigurationMap] procedure during installation
*/

DECLARE @return_Value INT

EXEC  scancap.CreateConfigurationMap

GO


 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 90.120.script.CreateClassTables.sql' 
PRINT '**********************************************************************'


/*
Script to Create Class tables
*/


DECLARE @ClassList AS TABLE (id INT, MFClass NVARCHAR(100), TableName NVARCHAR(100))

INSERT INTO @ClassList
        ( id, MFClass, TableName )

SELECT  ROW_NUMBER() OVER( ORDER BY MFClass) AS ID, MFClass , tablename

FROM 
( SELECT DISTINCT MFclass,tablename FROM ScanCap.ConfigurationMap AS CM
LEFT JOIN dbo.MFClass AS MC
ON cm.MFCLass = mc.Name) list

--SELECT * FROM @ClassList AS CL

DECLARE @id INT
DECLARE @ClassName NVARCHAR(100)

WHILE EXISTS(SELECT TOP 1 id FROM @ClassList AS CL ORDER BY id)
BEGIN

SELECT TOP 1 @id = id FROM @ClassList AS CL2 ORDER BY id

SELECT @ClassName = CL.MFClass FROM @ClassList AS CL WHERE id = @id
DELETE FROM @ClassList WHERE id = @id
EXEC dbo.spMFCreateTable @ClassName = @ClassName, -- nvarchar(128)
    @Debug = 0 -- smallint

--SELECT @ClassName

END

EXEC dbo.spMFCreateTable @ClassName = N'Vendor', -- nvarchar(128)
    @Debug = 0 -- smallint


GO



 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 90.101.script.SetLoggingOn.sql' 
PRINT '**********************************************************************'

/*
Set logging on as it is required for Scancapture messages
*/

UPDATE dbo.MFSettings
SET value = '1'

WHERE Name = 'App_DetailLogging'


GO
 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.601.spMFClassTableStats.sql' 
PRINT '**********************************************************************'
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFClassTableStats]';
GO
SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFClassTableStats', -- nvarchar(100)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Listing of Class Table stats
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			mflastmodified date show in local time
	2017-9-9		lc			add input parameter to only show table requested
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFClassTableStats]  null , 0

  exec spmfclasstablestats 'MFCustomer'
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFClassTableStats'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFClassTableStats]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO



ALTER PROCEDURE spMFClassTableStats
    (
      @ClassTableName NVARCHAR(128) = NULL ,
	  @Flag int = NULL,
      @Debug SMALLINT = 0
    )
AS
    SET NOCOUNT ON;

    DECLARE @ClassIDs AS TABLE ( ClassID INT );

    IF @ClassTableName IS NULL
        BEGIN
            INSERT  INTO @ClassIDs
                    ( [ClassID] )
                    SELECT  MFID
                    FROM    MFClass;

        END;
    ELSE
        BEGIN
            INSERT  INTO @ClassIDs
                    ( [ClassID]
                    )
                    SELECT  MFID
                    FROM    MFClass
                    WHERE   TableName = @ClassTableName;
        END;


    CREATE TABLE #Temp
        (
          ClassID INT ,
          TableName VARCHAR(100) ,
          IncludeInApp SMALLINT ,
          SQLRecordCount INT ,
          MFRecordCount INT ,
          MFNotInSQL INT ,
          Deleted INT ,
          SyncError INT ,
          Process_ID_1 INT ,
          MFError INT ,
          SQLError INT ,
          LastModified DATETIME ,
          MFLastModified DATETIME ,
          SessionID INT
		  
        );
    DECLARE @SQL NVARCHAR(MAX) ,
        @params NVARCHAR(100) ,
        @TableName VARCHAR(100) ,
        @ID INT;

    INSERT  INTO [#Temp]
            ( [ClassID] ,
              [TableName] ,
              [IncludeInApp] ,
              [SQLRecordCount] ,
              [MFRecordCount] ,
              MFNotInSQL ,
              [Deleted] ,
              [SyncError] ,
              [Process_ID_1] ,
              [MFError] ,
              [SQLError] ,
              [LastModified] ,
              [MFLastModified] ,
              SessionID
			  

            )
            SELECT  mc.MFID ,
                    mc.TableName ,
                    mc.[IncludeInApp] ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL
					
            FROM    @ClassIDs AS [cid]
                    LEFT JOIN [dbo].[MFClass] AS [mc] ON [mc].MFID = cid.[ClassID];

    SELECT  @ID = MIN(ClassID)
    FROM    [#Temp] AS [t];

    WHILE ISNULL(( SELECT   COUNT(ClassID)
                   FROM     [#Temp] AS [t]
                   WHERE    ClassID = @ID
                 ), 0) > 0
        BEGIN

            SELECT TOP 1
                    @TableName = TableName
            FROM    [#Temp] AS [t]
            WHERE   [t].[ClassID] = @ID;

            SET @params = '@Debug smallint';
            SET @SQL = N'
Declare @SQLcount INT, @LastModified datetime, @MFLastModified datetime, @Deleted int, @SyncError int, @ProcessID_1 int, @MFError INt, @SQLError Int
,@MFCount int

IF EXISTS(SELECT [t].[TABLE_NAME] FROM [INFORMATION_SCHEMA].[TABLES] AS [t] where Table_name = '''
                + @TableName
                + ''')
Begin

SELECT @SQLcount = COUNT(*), @LastModified = max(LastModified), @MFLastModified = max(MF_Last_Modified) FROM '
                + QUOTENAME(@TableName)
                + '
Select @MFLastModified = dateadd(hour,DATEDIFF(hour,GETUTCDATE(),GETDATE()),@MFLastModified)
Select @Deleted = count(*) FROM ' + QUOTENAME(@TableName)
                + ' where deleted <> 0;
Select @SyncError = count(*) FROM ' + QUOTENAME(@TableName)
                + ' where Process_id = 2;
Select @ProcessID_1 = count(*) FROM ' + QUOTENAME(@TableName)
                + ' where Process_id = 1;
Select @MFError = count(*) FROM ' + QUOTENAME(@TableName)
                + ' where Process_id = 3;
Select @SQLError = count(*) FROM ' + QUOTENAME(@TableName)
                + ' where Process_id = 4;
UPDATE t
SET t.[SQLRecordCount] =  @SQLcount, t.MFRecordCount = @MFcount, LastModified = @LastModified, MFLastModified = @MFLastModified,
Deleted = @Deleted, SyncError = @SyncError, Process_ID_1 = @ProcessID_1, MFError = @MFerror, SQLError = @SQLError

FROM [#Temp] AS [t]
WHERE t.[TableName] = ''' + @TableName + '''



END
Else 
If @Debug = 1
print ''' + @TableName + ' has not been created'';
 ';

--SELECT @SQL

            EXEC [sys].[sp_executesql] @Stmt = @SQL, @Param = @params,
                @Debug = @Debug;

            SELECT  @ID = MIN(ClassID)
            FROM    [#Temp] AS [t]
            WHERE   [t].[ClassID] > @ID;

        END;
    DECLARE @TempAudit AS TABLE
        (
          ClassID INT ,
          SessionID INT
        );

    INSERT  INTO @TempAudit
            ( [ClassID] ,
              [SessionID] 
            )
            SELECT  mah1.Class ,
                    MAX(mah1.SessionID) AS sessionID
            FROM    [dbo].[MFAuditHistory] AS [mah1]
                    INNER JOIN MFClass mc ON mah1.Class = mc.MFID
            GROUP BY mah1.Class;

--SELECT * FROM @TempAudit AS [ta]

    DECLARE @AuditCount AS TABLE
        (
          ClassID INT ,
          SessionID INT ,
          RecCount INT ,
          NotInSQL INT
        );

    INSERT  INTO @AuditCount
            ( [ClassID] ,
              [SessionID] ,
              [RecCount]
            )
            SELECT  mah.Class ,
                    mah.SessionID ,
                    COUNT(*)
            FROM    [dbo].[MFAuditHistory] AS [mah]
                    INNER JOIN @TempAudit AS [ta] ON [ta].[SessionID] = [mah].[SessionID]
            WHERE   [mah].[StatusFlag] NOT IN ( 3, 4 )
            GROUP BY mah.Class ,
                    mah.SessionID;

--SELECT * FROM @AuditCount AS [ac]

    DECLARE @NotInSQL AS TABLE
        (
          class INT ,
          flag5count INT
        );

    INSERT  INTO @NotInSQL
            ( [class] ,
              [flag5count]
            )
            SELECT  mah.Class ,
                    COUNT(*) AS flag5count
            FROM    [dbo].[MFAuditHistory] AS [mah]
                    INNER JOIN @TempAudit AS [ta] ON [ta].[SessionID] = [mah].[SessionID]
            WHERE   [mah].[StatusFlag] = 5
            GROUP BY Class ,
                    [mah].[StatusFlag];  
				
--SELECT * FROM @NotInSQL

    UPDATE  @AuditCount
    SET     [@AuditCount].[NotInSQL] = ISNULL([nis].[flag5count], 0)
    FROM    @AuditCount
            INNER JOIN @NotInSQL AS [nis] ON [@AuditCount].[ClassID] = [nis].[class];

--SELECT * FROM [#Temp] INNER JOIN @AuditCount AS [ac]
-- ON [ac].[ClassID] = [#Temp].[ClassID]


    UPDATE  [#Temp]
    SET     [#Temp].[MFRecordCount] = ac.[RecCount] ,
            [#Temp].[MFNotInSQL] = ISNULL(ac.[NotInSQL], 0),
			 SessionID = ac.[SessionID]
    FROM    [#Temp]
            LEFT JOIN @AuditCount AS [ac] ON [ac].[ClassID] = [#Temp].[ClassID];


    SELECT  *, Flag = 1
    FROM    [#Temp]
    WHERE   ISNULL([#Temp].[SQLRecordCount], -1) <> -1;

    DROP TABLE [#Temp];

    RETURN 1;

GO
 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.606.spMFDeleteObject.sql' 
PRINT '**********************************************************************'
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDeleteObject]';
GO
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFDeleteObject', -- nvarchar(100)
    @Object_Release = '3.1.1.32', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFDeleteObject'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFDeleteObject]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO

ALTER PROCEDURE [dbo].[spMFDeleteObject] @ObjectTypeId [INT]
                                          ,@objectId    [INT]
                                          ,@Output      [NVARCHAR](2000) OUTPUT
										  ,@DeleteWithDestroy BIT = 0 
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to Delete object from M-Files.  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **        1. User credential details from Settings Table
  **		2. Class the spMFDeleteObjectInternal to delete object
  **
  ** Parameters and acceptable values: 
  **        @ObjectTypeId [INT]
  **        @objectId    [INT]                    	
  **
  ** Restart:
  **        Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 
  **				  None
  **
  ** Return values:		@Output      [NVARCHAR](2000)
  **					
  **
  ** Called By:			None
  **
  ** Calls:           
  **					spMFDeleteObjectInternal
  **
  ** Author:          Thejus T V
  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-8-14		lc		add objid to output message
  2016-8-22		lc			update settings index
  2016-09-26    DevTeam2   Removed vault settings parameters and pass them as comma
                           separated string in @VaultSettings parameter.
  ******************************************************************************/
  BEGIN
      BEGIN TRY
          -----------------------------------------------------
          -- LOCAL VARIABLE DECLARARTION
          -----------------------------------------------------
          DECLARE @VaultSettings        NVARCHAR(4000)
                  

          -----------------------------------------------------
          -- SELECT CREDENTIAL DETAILS
          -----------------------------------------------------

			SELECT @VaultSettings=dbo.FnMFVaultSettings()

          -----------------------------------------------------
          -- CALLS PROCEDURE spMFDeleteObjectInternal
          -----------------------------------------------------
          EXEC spMFDeleteObjectInternal
            @VaultSettings
            ,@ObjectTypeId
            ,@objectId
            ,@Output OUTPUT
			,@DeleteWithDestroy

          PRINT @Output + ' ' + CAST(@objectId AS VARCHAR(100))

		  RETURN 1
      END TRY

      BEGIN CATCH
          ------------------------------------------------------
          -- INSERTING ERROR DETAILS INTO LOG TABLE
          ------------------------------------------------------
          INSERT INTO MFLog
                      (SPName,
                       ErrorNumber,
                       ErrorMessage,
                       ErrorProcedure,
                       ErrorState,
                       ErrorSeverity,
                       ErrorLine)
          VALUES      ('spMFDeleteObject',
                       Error_number(),
                       Error_message(),
                       Error_procedure(),
                       Error_state(),
                       Error_severity(),
                       Error_line())
		  RETURN -1
	  END CATCH
  END

GO 
 
GO 
PRINT '**********************************************************************' 
PRINT 'SCRIPT FILE: 35.608.spMFDeleteObjectList.sql' 
PRINT '**********************************************************************'
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.dbo.spMFDeleteObjectList';

go
	EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFDeleteObjectList', -- nvarchar(100)
    @Object_Release = '3.1.1.32', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFDeleteObjectList'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFDeleteObjectList
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFDeleteObjectList
    (
      @TableName NVARCHAR(100) ,
      @Process_id INT ,
      @Debug INT = 0,
	  @DeleteWithDestroy BIT = 0
    )
AS /*
Procedure to delete a series of objects



USAGE:
Before running this procedure, set the process_id for the target objects for deletion 
Select * from MFTest
update t
set process_id = 10
from MFTest t where id in(10,11,12)

exec spMFDeleteObjectList @tableName = 'MFTest', @process_ID = 10, @Debug = 1

*/


    DECLARE @Objid INT ,
        @ObjectTypeID INT ,
        @output NVARCHAR(100) ,
        @itemID INT ,
        @Query NVARCHAR(MAX) ,
        @Params NVARCHAR(MAX) ,
        @procedureName NVARCHAR(128) = 'spMFDeleteObjectList' ,
        @ProcedureStep NVARCHAR(128);

    BEGIN TRY
    
        BEGIN
            SET NOCOUNT ON;

            SELECT  @ObjectTypeID = mot.MFID
            FROM    [dbo].[MFClass] AS [mc]
                    INNER JOIN [dbo].[MFObjectType] AS [mot] ON [mot].[ID] = [mc].[MFObjectType_ID]
            WHERE   mc.[TableName] = @TableName;

            IF ISNULL(@ObjectTypeID, -1) = -1
                RAISERROR('ObjectID not found',16,1);

            IF @Debug = 1
                SELECT  @ObjectTypeID AS ObjectTypeid;

            CREATE TABLE #ObjectList ( [Objid] INT );
		
            SET @Params = N'@Process_id INT';
            SET @Query = N'

		INSERT INTO #ObjectList
		        ( [Objid] )

SELECT  t.[ObjID] 
FROM ' + QUOTENAME(@TableName) + ' as t
WHERE  t.[Process_ID] = @Process_id
ORDER BY objid ASC;';

            EXEC sp_executesql @Stmt = @Query, @Param = @Params,
                @Process_id = @Process_id;


            IF @Debug = 1
                SELECT  *
                FROM    [#ObjectList] AS [ol];

            DECLARE @getObjidID CURSOR;
            SET @getObjidID = CURSOR FOR

		SELECT [Objid] FROM [#ObjectList] AS [ol] ORDER BY [Objid] ASC;

            OPEN @getObjidID;
            FETCH NEXT
FROM @getObjidID INTO @Objid;
            WHILE @@FETCH_STATUS = 0
                BEGIN

                    EXEC [dbo].[spMFDeleteObject] @ObjectTypeId = @ObjectTypeId, -- int
                        @objectId = @Objid, -- int
                        @Output = @Output OUTPUT,
						@DeleteWithDestroy=@DeleteWithDestroy; -- nvarchar(2000)

                    FETCH NEXT
FROM @getObjidID INTO @Objid;
                END;
            CLOSE @getObjidID;
            DEALLOCATE @getObjidID;

            SET @Query = N'
        UPDATE  mecr
        SET     [mecr].[Process_ID] = 0
        FROM   ' + QUOTENAME(@TableName) + ' AS [mecr]
        WHERE   [mecr].[Process_ID] = @Process_id;';

            EXEC sp_executesql @Stmt = @Query, @Param = @Params,
                @Process_id = @Process_id;

        END;

        BEGIN


            EXEC [dbo].[spMFTableAudit] @MFTableName = @TableName, -- nvarchar(128)
                @MFModifiedDate = NULL, -- datetime
                @ObjIDs = NULL, -- nvarchar(4000)
                @Debug = 0, -- smallint
                @SessionIDOut = 0, -- int
                @NewObjectXml = N''; -- nvarchar(max)

            SET @Query = N'
        DELETE  FROM ' + QUOTENAME(@TableName) + '
        WHERE   deleted = 1;';
 
            EXEC sp_executesql @Stmt = @Query;
  
        END;

    END TRY
    
    BEGIN CATCH

	        -----------------------------------------------------------------------------
          -- INSERTING ERROR DETAILS INTO LOG TABLE
          -----------------------------------------------------------------------------
        INSERT  INTO MFLog
                ( SPName ,
                  ProcedureStep ,
                  ErrorNumber ,
                  ErrorMessage ,
                  ErrorProcedure ,
                  ErrorState ,
                  ErrorSeverity ,
                  ErrorLine
                )
        VALUES  ( @procedureName ,
                  @ProcedureStep ,
                  ERROR_NUMBER() ,
                  ERROR_MESSAGE() ,
                  ERROR_PROCEDURE() ,
                  ERROR_STATE() ,
                  ERROR_SEVERITY() ,
                  ERROR_LINE()
                );
		  
          -----------------------------------------------------------------------------
          -- DISPLAYING ERROR DETAILS
          -----------------------------------------------------------------------------
        SELECT  ERROR_NUMBER() AS ErrorNumber ,
                ERROR_MESSAGE() AS ErrorMessage ,
                ERROR_PROCEDURE() AS ErrorProcedure ,
                ERROR_STATE() AS ErrorState ,
                ERROR_SEVERITY() AS ErrorSeverity ,
                ERROR_LINE() AS ErrorLine ,
                @procedureName AS ProcedureName ,
                @ProcedureStep AS ProcedureStep;

          -----------------------------------------------------------------------------
          -- CLOSE PROCESS
          -----------------------------------------------------------------------------
      
        RETURN -1;
    
    END CATCH;
    

	GO
    
 
 
GO 
