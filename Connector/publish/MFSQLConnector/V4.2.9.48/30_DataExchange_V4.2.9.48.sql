
USE {varAppDB}

GO

/***************************************************************************
IMPORTANT : READ AND PERFORM ACTION BEFORE EXECUTING THE RELEASE SCRIPT
***************************************************************************/

/*
THIS SCRIPT HAS BEEN PREPARE TO ALLOW FOR THE AUTOMATION OF ALL THE INSTALLATION VARIABLES

2017-3-24-7h30
*/

/*
First time installation only

Find what:					
{varMFUsername}					
{varMFPassword}					
{varNetworkAddress}				
{varVaultName}					
{varProtocolType}
{varEndpoint}
{varAuthenticationType}
{varMFDomain}
{varMFInstallPath}
{varAppDB}						

*/
GO

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-05
	Database: 
	Description: Audit history of comparison between M-Files and SQL
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
  Select * from MFAuditHistory
  drop table mfaudithistory
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFAuditHistory]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFAuditHistory', -- nvarchar(100)
    @Object_Release = '2.0.2.5', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFAuditHistory'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )

    BEGIN
 
 PRINT SPACE(10)+ 'Table created';

CREATE TABLE MFAuditHistory
(ID INT IDENTITY PRIMARY KEY ,
RecID INT,
SessionID INT,
TranDate DATETIME,
ObjectType INT,
Class INT,
[ObjID] INT,
MFVersion smallint,
StatusFlag SMALLINT,
StatusName VARCHAR(100),
UpdateFlag int
)

CREATE INDEX idx_AuditHistory_ObjType_ObjID ON MFAuditHistory(ObjectType, [ObjID])
CREATE INDEX idx_AuditHistory_Class_Flag ON MFAuditHistory(Class, [ObjID])

END

GO

go

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Datatypes match M-Files datatypes with SQL datatypes.  This table must not be changed
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
  Select * from MFDataType
  
-----------------------------------------------------------------------------------------------*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFDataType]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFDataType', -- nvarchar(100)
    @Object_Release = '4.2.7.46', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
changing multi lookup datatype to nvarchar(4000)
2017-2-16 update time datatype to varchar
2018-11-20 update to change datatype back to time
*/
IF NOT EXISTS (SELECT name FROM sys.tables WHERE name='MFDataType' AND SCHEMA_NAME(schema_id)='dbo')
 BEGIN
   CREATE TABLE MFDataType
  (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [MFTypeID]    INT           NOT NULL,
    [SQLDataType] VARCHAR (50)  NULL,
    [Name]        VARCHAR (100) NULL,
    [ModifiedOn]  DATETIME      DEFAULT (getdate()) NOT NULL,
    [CreatedOn]   DATETIME      DEFAULT (getdate()) NOT NULL,
    [Deleted]     BIT           NOT NULL,
    CONSTRAINT [PK_MFDataType] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [TUC_MFDataType_MFTypeID] UNIQUE NONCLUSTERED ([MFTypeID] ASC)
);


	PRINT SPACE(10) + '... Table: created'
END
ELSE
	PRINT SPACE(10) + '... Table: exists'


--INDEXES #############################################################################################################################

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('MFDataType') AND name = N'idx_MFDataType_MFTypeID')
	BEGIN
		PRINT space(10) + '... Index: idx_MFDataType_MFTypeID'
		CREATE NONCLUSTERED INDEX idx_MFDataType_MFTypeID ON dbo.MFDataType (MFTypeID)
	END

--DATA #########################################################################################################################3#######


SET IDENTITY_INSERT [dbo].[MFDataType] ON

GO

PRINT space(5) +'INSERTING DATA INTO TABLE: MFDataType '

SET NOCOUNT ON

TRUNCATE TABLE [dbo].[MFDataType];

INSERT [dbo].[MFDataType]
       ([ID],
        [MFTypeID],
        [SQLDataType],
        [Name],
        [ModifiedOn],
        [CreatedOn],
        [Deleted])
VALUES (1,
        1,
        N'NVARCHAR(100)',
        N'MFDatatypeText',
        Cast(N'2014-09-02 18:58:26.310' AS DATETIME),
        Cast(N'2014-09-02 18:58:26.310' AS DATETIME),
        0),
 (2,
        2,
        N'INTEGER',
        N'MFDatatypeInteger',
        Cast(N'2014-09-02 19:10:43.983' AS DATETIME),
        Cast(N'2014-09-02 19:10:43.983' AS DATETIME),
        0),
 (3,
        3,
        N'Float',
        N'MFDatatypeFloating',
        Cast(N'2014-09-02 19:30:01.263' AS DATETIME),
        Cast(N'2014-09-02 19:30:01.263' AS DATETIME),
        0),
 (4,
        5,
        N'Date',
        N'MFDatatypeDate',
        Cast(N'2014-09-02 19:30:06.480' AS DATETIME),
        Cast(N'2014-09-02 19:30:06.480' AS DATETIME),
        0),
 (5,
        6,
        N'Time(0)',
        N'MFDatatypeTime',
        Cast(N'2014-09-02 19:32:28.677' AS DATETIME),
        Cast(N'2014-09-02 19:32:28.677' AS DATETIME),
        0),
 (6,
        7,
        N'Datetime',
        N'MFDatatypeTimestamp',
        Cast(N'2014-09-02 19:32:40.337' AS DATETIME),
        Cast(N'2014-09-02 19:32:40.337' AS DATETIME),
        0),
 (7,
        8,
        N'BIT',
        N'MFDatatypeBoolean',
        Cast(N'2014-09-02 19:32:49.253' AS DATETIME),
        Cast(N'2014-09-02 19:32:49.253' AS DATETIME),
        0),
 (8,
        9,
        N'INTEGER',
        N'MFDatatypeLookup',
        Cast(N'2014-09-02 19:33:00.037' AS DATETIME),
        Cast(N'2014-09-02 19:33:00.037' AS DATETIME),
        0),
 (9,
        10,
        N'NVARCHAR(4000)',
        N'MFDatatypeMultiSelectLookup',
        Cast(N'2014-09-02 19:33:09.393' AS DATETIME),
        Cast(N'2014-09-02 19:33:09.393' AS DATETIME),
        0),
 (10,
        11,
        N'BigInt',
        N'MFDatatypeInteger64',
        Cast(N'2014-09-02 19:33:28.040' AS DATETIME),
        Cast(N'2014-09-02 19:33:28.040' AS DATETIME),
        0),
 (11,
        12,
        NULL,
        N'MFDatatypeFILETIME',
        Cast(N'2014-09-02 19:33:31.397' AS DATETIME),
        Cast(N'2014-09-02 19:33:31.397' AS DATETIME),
        0),
 (12,
        13,
        N'NVARCHAR(4000)',
        N'MFDatatypeMultiLineText',
        Cast(N'2014-09-02 19:30:06.480' AS DATETIME),
        Cast(N'2014-09-02 19:33:48.030' AS DATETIME),
        0)

SET IDENTITY_INSERT [dbo].[MFDataType] OFF;

GO

IF NOT EXISTS(SELECT value FROM sys.[extended_properties] AS [ep] WHERE value = N'This table is used to update the MF data types and set the related SQL datatypes') 
EXEC sys.sp_addextendedproperty
  @name       =N'MS_Description'
  ,@value     =N'This table is used to update the MF data types and set the related SQL datatypes'
  ,@level0type=N'SCHEMA'
  ,@level0name=N'dbo'
  ,@level1type=N'TABLE'
  ,@level1name=N'MFDataType'

GO 


--SECURITY #########################################################################################################################3#######

GO
GO

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: MFiles Object Type metadata
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
  Select * from MFObjectType
  
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFObjectType]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFObjectType', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFObjectType'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFObjectType]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NULL ,
              [Alias] NVARCHAR(100) NULL ,
              [MFID] INT NOT NULL ,
              [ModifiedOn] DATETIME DEFAULT ( GETDATE() )
                                    NOT NULL ,
              [CreatedOn] DATETIME DEFAULT ( GETDATE() )
                                   NOT NULL ,
              [Deleted] BIT NOT NULL ,
              CONSTRAINT [PK_MFObjectType] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              CONSTRAINT [TUC_MFObjectType_MFID] UNIQUE NONCLUSTERED
                ( [MFID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


IF NOT EXISTS(SELECT value FROM sys.[extended_properties] AS [ep] WHERE value = N'Represents the Object Types of the selected vault')  
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'Represents the Object Types of the selected vault',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFObjectType';

GO
go
SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-01
	Database: 
	Description: MFLog records every system related error with reference to the MFUpdateHistory	
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
  Select * from MFLog
  
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFLog]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFLog', -- nvarchar(100)
    @Object_Release = '2.1.1.12', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFLog'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
  
        CREATE TABLE [dbo].[MFLog]
            (
              [LogID] INT IDENTITY(1, 1)
                          NOT NULL ,
              [SPName] NVARCHAR(MAX) NULL ,
              [Update_ID] INT NULL ,
              [ExternalID] NVARCHAR(50) NULL ,
              [ErrorNumber] INT NULL ,
              [ErrorMessage] NVARCHAR(MAX) NULL ,
              [ErrorProcedure] NVARCHAR(MAX) NULL ,
              [ProcedureStep] NVARCHAR(MAX) NULL ,
              [ErrorState] NVARCHAR(MAX) NULL ,
              [ErrorSeverity] INT NULL ,
              [ErrorLine] INT NULL ,
              [CreateDate] DATETIME
                CONSTRAINT [DF__MFLog__Creat__1367EE2606]
                DEFAULT ( GETDATE() )
                NULL ,
              CONSTRAINT [PK_MFLog] PRIMARY KEY CLUSTERED ( [LogID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    BEGIN

        PRINT SPACE(10) + '... Table: exists';
    END;

--FOREIGN KEYS #############################################################################################################################

--IF NOT EXISTS ( SELECT  *
--                FROM    sys.foreign_keys
--                WHERE   parent_object_id = OBJECT_ID('MFLog')
--                        AND name = N'FK_MFLog_Update_ID' )
--    BEGIN
--        PRINT SPACE(10) + '... Constraint: FK_MFLog_Update_ID';
--        ALTER TABLE dbo.MFLog ADD 
--        CONSTRAINT FK_MFLog_Update_ID FOREIGN KEY (Update_ID)
--        REFERENCES dbo.MFUpdateHistory(Id)
--        ON DELETE NO ACTION;

--    END;

--INDEXES #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFLog')
                        AND name = N'idx_MFLog_id' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFLog_id';
        CREATE NONCLUSTERED INDEX idx_MFLog_id ON dbo.MFLog ([LogID]);
    END;

--TRIGGERS #########################################################################################################################3#######


-- =============================================
-- Author:		leRoux Cilliers
-- Create date: 2015-06-4
-- Description:	Trigger to send email on new error log
-- =============================================

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFLog]: Trigger tMF_OnError_SendEmail';
GO

IF EXISTS ( SELECT  *
                FROM    sys.objects
                WHERE   [type] = 'TR'
                        AND [name] = 'tMF_OnError_SendEmail' )
    BEGIN
        
		DROP TRIGGER tMF_OnError_SendEmail

        PRINT SPACE(10) + '...Trigger dropped.';
    END;

 PRINT SPACE(10) + '...Trigger Created.';

 GO

 
Create TRIGGER [dbo].[tMF_OnError_SendEmail] ON [dbo].[MFLog]
    AFTER INSERT
AS
    BEGIN
	;
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

SET NOCOUNT ON 
	        
        DECLARE @MFLog_ID INT;
        SELECT  @MFLog_ID = [Inserted].[LogID]
        FROM    [Inserted];

		DECLARE @EmailProfile NVARCHAR(128), @rc INT

		SELECT @EmailProfile = CAST(value AS NVARCHAR(100)) FROM MFSettings WHERE name = 'SupportEMailProfile'

		EXEC @rc = [dbo].[spMFValidateEmailProfile]
		    @emailProfile = @EmailProfile
		
		IF @rc = 1
        EXEC dbo.spMFLogError_EMail @LogID = @MFLog_ID, @DebugFlag = 0;


    END;


--SECURITY #########################################################################################################################3#######

GO



GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUpdateHistory]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUpdateHistory', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: MFUpdate history auto assigns a unique id for each update to and from M-Files	
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
  Select * from MFUpdateHistory
  
-----------------------------------------------------------------------------------------------*/




IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUpdateHistory'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFUpdateHistory]
            (
              [Id] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Username] NVARCHAR(250) NOT NULL ,
              [VaultName] NVARCHAR(250) NOT NULL ,
              [UpdateMethod] SMALLINT NOT NULL ,
              [ObjectDetails] XML NULL ,
              [ObjectVerDetails] XML NULL ,
              [NewOrUpdatedObjectVer] XML NULL ,
              [NewOrUpdatedObjectDetails] XML NULL ,
              [SynchronizationError] XML NULL ,
              [MFError] XML NULL ,
              [DeletedObjectVer] XML NULL ,
              [UpdateStatus] VARCHAR(25) NULL ,
              [CreatedAt] DATETIME
                CONSTRAINT [CreatedAt] DEFAULT ( GETDATE() )
                NULL ,
              CONSTRAINT [PK_MFUpdateHistory] PRIMARY KEY CLUSTERED
                ( [Id] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';
	GO

--INDEXES #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFUpdateHistory')
                        AND name = N'idx_MFUpdateHistory_id' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFUpdateHistory_id';
        CREATE NONCLUSTERED INDEX idx_MFUpdateHistory_id ON dbo.MFUpdateHistory (Id);
    END;


--SECURITY #########################################################################################################################3#######

IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'output XML contains updated or Created object detials' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'output XML contains updated or Created object detials',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'NewOrUpdatedObjectDetails';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'output XML contains updated or created ObjVer details' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'output XML contains updated or created ObjVer details',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'NewOrUpdatedObjectVer';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'input XML contains existing ObjVer details' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'input XML contains existing ObjVer details',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'ObjectVerDetails';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'input XML contains updated or created object details ' )
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'input XML contains updated or created object details ',
    @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
    @level1name = N'MFUpdateHistory', @level2type = N'COLUMN',
    @level2name = N'ObjectDetails';

go

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Workflow MFiles metadata	
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
  Select * from MFWorkflow
  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFWorkflow]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFWorkflow', -- nvarchar(100)
    @Object_Release = '2.0.2.2', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFWorkflow'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFWorkflow]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NOT NULL ,
              [Alias] NVARCHAR(100) NULL ,
              [MFID] INT NOT NULL ,
              [ModifiedOn] DATETIME DEFAULT ( GETDATE() )
                                    NOT NULL ,
              [CreatedOn] DATETIME DEFAULT ( GETDATE() )
                                   NOT NULL ,
              [Deleted] BIT NOT NULL ,
              CONSTRAINT [PK_MFWorkflow] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              CONSTRAINT [TUC_MFWorkflow_MFID] UNIQUE NONCLUSTERED
                ( [MFID] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################

IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFWorkflow')
                        AND name = N'idx_MFWorkflow_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFWorkflow_MFID';
        CREATE NONCLUSTERED INDEX idx_MFWorkflow_MFID ON dbo.MFWorkflow (MFID);
    END;

--SECURITY #########################################################################################################################3#######
--** Alternatively add ALL security scripts to single file: script.SQLPermissions_{dbname}.sql



GO
IF NOT EXISTS(SELECT value FROM sys.[extended_properties] AS [ep] WHERE value = N'Per MF Workflow')  
EXECUTE sp_addextendedproperty @name = N'MS_Description',
    @value = N'Per MF Workflow', @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'MFWorkflow',
    @level2type = N'COLUMN', @level2name = N'MFID';

go
go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFClass]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFClass', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: MFiles Class metadata
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-7-6		LC			Add column for filepath
	2017-8-22		LC			Add column for syncprecedence
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFClass
  
-----------------------------------------------------------------------------------------------*/


GO
IF NOT EXISTS (	  SELECT	[name]
				  FROM		[sys].[tables]
				  WHERE		[name] = 'MFClass'
							AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN
		CREATE TABLE [MFClass]
			(
				[ID]			  INT			IDENTITY(1, 1) NOT NULL
			  , [MFID]			  INT			NOT NULL
			  , [Name]			  VARCHAR(100)	NOT NULL
			  , [Alias]			  NVARCHAR(100) NULL
			  , [IncludeInApp]	  SMALLINT		NULL
			  , [TableName]		  VARCHAR(100)	NULL
			  , [MFObjectType_ID] INT			NULL
			  , [MFWorkflow_ID]	  INT			NULL
			  , [FileExportFolder]		  NVARCHAR(500) NULL
			  , SynchPrecedence int NULL 
			  , [ModifiedOn]	  DATETIME
					DEFAULT ( GETDATE()) NOT NULL
			  , [CreatedOn]		  DATETIME
					DEFAULT ( GETDATE()) NOT NULL
			  , [Deleted]		  BIT			NOT NULL
			  , CONSTRAINT [PK_MFClass]
					PRIMARY KEY CLUSTERED ( [ID] ASC )
			);

		PRINT SPACE(10) + '... Table: created';
	END;
ELSE PRINT SPACE(10) + '... Table: exists';

--FOREIGN KEYS #############################################################################################################################

IF NOT EXISTS (	  SELECT	*
				  FROM		[sys].[foreign_keys]
				  WHERE		[parent_object_id] = OBJECT_ID('MFClass')
							AND [name] = N'FK_MFClass_MFWorkflow_ID'
			  )
	BEGIN
		PRINT SPACE(10) + '... Constraint: FK_MFClass_MFWorkflow_ID';
		ALTER TABLE [dbo].[MFClass] WITH CHECK
		ADD CONSTRAINT [FK_MFClass_MFWorkflow_ID]
			FOREIGN KEY ( [MFWorkflow_ID] )
			REFERENCES [dbo].[MFWorkflow] ( [id] ) ON DELETE NO ACTION;

	END;

IF NOT EXISTS (	  SELECT	*
				  FROM		[sys].[foreign_keys]
				  WHERE		[parent_object_id] = OBJECT_ID('MFClass')
							AND [name] = N'FK_MFClass_ObjectType_ID'
			  )
	BEGIN
		PRINT SPACE(10) + '... Constraint: FK_MFClass_ObjectType_ID';
		ALTER TABLE [dbo].[MFClass] WITH CHECK
		ADD CONSTRAINT [FK_MFClass_ObjectType_ID]
			FOREIGN KEY ( [MFObjectType_ID] )
			REFERENCES [dbo].[MFObjectType] ( [id] ) ON DELETE NO ACTION;

	END;

--INDEXES #############################################################################################################################

IF NOT EXISTS (	  SELECT	*
				  FROM		[sys].[indexes]
				  WHERE		[object_id] = OBJECT_ID('MFClass')
							AND [name] = N'udx_MFClass_MFID'
			  )
	BEGIN
		PRINT SPACE(10) + '... Index: udx_MFClass_MFID';
		CREATE NONCLUSTERED INDEX [udx_MFClass_MFID] ON [dbo].[MFClass] ( [MFID] );
	END;

--EXTENDED PROPERTIES #############################################################################################################################

	IF NOT EXISTS (	  SELECT	[ep].[value]
					  FROM		[sys].[extended_properties] AS [ep]
					  WHERE		[ep].[value] = 'Per MF Workflow'
				  )
		EXECUTE [sys].[sp_addextendedproperty]
			@name = N'MS_Description'
		  , @value = N'Per MF Workflow'
		  , @level0type = N'SCHEMA'
		  , @level0name = N'dbo'
		  , @level1type = N'TABLE'
		  , @level1name = N'MFClass'
		  , @level2type = N'COLUMN'
		  , @level2name = N'MFWorkflow_ID';


	GO
	IF NOT EXISTS (	  SELECT	[ep].[value]
					  FROM		[sys].[extended_properties] AS [ep]
					  WHERE		[ep].[value] = N'Per MF ObjectType ID'
				  )
		EXECUTE [sys].[sp_addextendedproperty]
			@name = N'MS_Description'
		  , @value = N'Per MF ObjectType ID'
		  , @level0type = N'SCHEMA'
		  , @level0name = N'dbo'
		  , @level1type = N'TABLE'
		  , @level1name = N'MFClass'
		  , @level2type = N'COLUMN'
		  , @level2name = N'MFObjectType_ID';


	GO
	IF NOT EXISTS (	  SELECT	[ep].[value]
					  FROM		[sys].[extended_properties] AS [ep]
					  WHERE		[ep].[value] = N'Per MF Class ID'
				  )
		EXECUTE [sys].[sp_addextendedproperty]
			@name = N'MS_Description'
		  , @value = N'Per MF Class ID'
		  , @level0type = N'SCHEMA'
		  , @level0name = N'dbo'
		  , @level1type = N'TABLE'
		  , @level1name = N'MFClass'
		  , @level2type = N'COLUMN'
		  , @level2name = N'MFID';

	GO

--TABLE MIGRATIONS #############################################################################################################################
/*	
	Effective Version: 3.1.2.38
	FilePath is used by spmfExportFiles to set the default export path for files for each class table
	SynchPrecedence is used to determine if M-Files or SQL should get precedence when a synchronization error is detected. 
*/
IF NOT EXISTS (	  SELECT	1
				  FROM		[INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE		[c].[TABLE_NAME] = 'MFClass'
							AND [c].[COLUMN_NAME] = 'FileExportFolder'
			  )
	BEGIN
		ALTER TABLE dbo.[MFClass] ADD [FileExportFolder] NVARCHAR(500)

		PRINT SPACE(10) + '... Column [FileExportFolder]: added';

	END

IF NOT EXISTS (	  SELECT	1
				  FROM		[INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE		[c].[TABLE_NAME] = 'MFClass'
							AND [c].[COLUMN_NAME] = 'SynchPrecedence'
			  )
	BEGIN
		ALTER TABLE dbo.[MFClass] ADD SynchPrecedence int

		PRINT SPACE(10) + '... Column [SynchPrecedence]: added';

	END

	--Added fot tasj #1052
	IF NOT EXISTS(SELECT 1 
				  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE [c].TABLE_NAME='MFClass'
				  AND [c].COLUMN_NAME='IsWorkflowEnforced' --added for task 1052
	
				  )
		BEGIN
			ALTER TABLE dbo.[MFClass] add IsWorkflowEnforced bit; --added for task 1052
			PRINT SPACE(10) + '... Column [IsWorkflowEnforced]: added'; 
		END

GO


go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFAuthenticationType]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFAuthenticationType', -- nvarchar(100)
    @Object_Release = '3.1.0.24', -- varchar(50)
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
                WHERE   name = 'MFAuthenticationType'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFAuthenticationType
			(
			    [ID] int IDENTITY(1,1) NOT NULL,
				[AuthenticationType] [varchar](250) NULL,
		        [AuthenticationTypeValue] [varchar](20) NULL,
			   CONSTRAINT [PK_MFAuthenticationType] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
       
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Unknown','0')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Current Windows User','1')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('Specific Windows User','2')
insert into MFAuthenticationType(AuthenticationType,AuthenticationTypeValue)values('M-Files User','3')

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

			
GO		



go 
SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: History of deployment runs	
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
  Select * from MFDeploymentDetail
  Drop table MFDeploymentDetail
  
-----------------------------------------------------------------------------------------------*/

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFDeploymentDetail]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFDeploymentDetail', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFDeploymentDetail'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFDeploymentDetail]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [LSWrapperVersion] NVARCHAR(100) NULL ,
              [MFilesAPIVersion] NVARCHAR(100) NULL ,
              [DeployedBy] NVARCHAR(250) NULL ,
              [DeployedOn] DATETIME NULL ,
              CONSTRAINT [PK_MFDeploymentDetail] PRIMARY KEY CLUSTERED
                ( [id] ASC )
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

GO

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


go
SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: Login Accounts for Vault	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-8-22		LC			Add MFID as a column to the table
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFLoginAccount
  
-----------------------------------------------------------------------------------------------*/



GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFLoginAccount]';


GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFLoginAccount', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFLoginAccount'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
  
        CREATE TABLE [dbo].[MFLoginAccount]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL PRIMARY KEY ,
              [AccountName] NVARCHAR(250) not NULL ,
              [UserName] NVARCHAR(250) NOT NULL ,
			  [MFID] INT NULL,
              [FullName] NVARCHAR(250) NULL ,
              [AccountType] NVARCHAR(250) NULL ,
              [DomainName] NVARCHAR(250) NULL ,
              [EmailAddress] NVARCHAR(250) NULL ,
              [LicenseType] NVARCHAR(250) NULL ,
              [Enabled] BIT NULL ,
              [Deleted] BIT
                CONSTRAINT [DF_MFLoginAccount_Deleted] DEFAULT ( (0) )
                NULL 

            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';
	IF NOT EXISTS ( SELECT  name,c.[COLUMN_NAME]
                FROM    sys.tables st
				LEFT JOIN [INFORMATION_SCHEMA].[COLUMNS] AS [c]
				ON c.[TABLE_NAME] = st.[name]
                WHERE   name = 'MFLoginAccount'
                        AND SCHEMA_NAME(schema_id) = 'dbo'
						AND c.[COLUMN_NAME] = 'MFID'
						 )
	BEGIN
    Alter table MFLoginAccount Add MFID INT
     PRINT SPACE(10) + '... Column MFID added'
	 END


go

SET NOCOUNT ON; 
GO
/*----------leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Valuelist MFiles Metadata 	
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
  Select * from MFValueList

  Alter table MFValueListItems
  Drop CONSTRAINT FK_MFValueListItems_MFValueList

  Alter table MFProperty
  Drop CONSTRAINT FK_MFProperty_MFValueList

  DROP TABLE MFValuelist
  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFValueList]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFValueList', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFValueList'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
   
        CREATE TABLE [dbo].[MFValueList]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NULL ,
              [Alias] NVARCHAR(100) NULL ,
              [MFID] INT NULL ,
              [OwnerID] INT NULL ,
              [ModifiedOn] DATETIME
                CONSTRAINT [DF__MFValueList_ModifiedOn] DEFAULT ( GETDATE() )
                NOT NULL ,
              [CreatedOn] DATETIME
                CONSTRAINT [DF__MFValueList_CreatedOn] DEFAULT ( GETDATE() )
                NOT NULL ,
              [Deleted] BIT CONSTRAINT [DF_MFValueList_Deleted] DEFAULT ((0))
                            NOT NULL ,
              CONSTRAINT [PK_MFValueList] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueList')
                        AND name = N'udx_MFValueList_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: udx_MFValueList_MFID';
        CREATE UNIQUE NONCLUSTERED INDEX udx_MFValueList_MFID ON dbo.MFValueList (MFID) INCLUDE (Name);
    END;


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueList')
                        AND name = N'idx_MFValueList_1' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFValueList_1';
        CREATE NONCLUSTERED INDEX idx_MFValueList_1 ON dbo.MFValueList (ID, Name);
    END;


GO

IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Represents all the valuelists of the selected vault' )
			BEGIN
          
    EXECUTE sp_addextendedproperty @name = N'MS_Description',
        @value = N'Represents all the valuelists of the selected vault',
        @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
        @level1name = N'MFValueList';

		PRINT SPACE(10) + '... Extended Properties Create : ';
		end


IF Not Exists ( Select top 1 *  from INFORMATION_SCHEMA.COLUMNS C where c.COLUMN_NAME='RealObjectType' and C.TABLE_NAME='MFValueList')
	Begin
	ALTER table MFValueList add [RealObjectType] BIT

	PRINT SPACE(10) + '......RealObjectType COLUMN IS ADDED.'
End
GO
GO
-- ** Required
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUserAccount]';
-- ** Required
GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUserAccount', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: User Account M-Files Metdata data
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
  Select * from MFUserAccount
  
-----------------------------------------------------------------------------------------------*/

--** Only include USE statement if database will ALWAYS be guaranteed  to be the same, i.e. master, msdb, etc.
--USE [Database]


--** Use IF EXISTS syntax if table ALWAYS needs to be dropped before being recreated.
--** WARNING: this could cause loss of data

--** Optional
/*
   IF EXISTS (SELECT name FROM sys.tables WHERE name='MFUserAccount' AND SCHEMA_NAME(schema_id)='dbo')
   BEGIN
		DROP TABLE	dbo.MFUserAccount
		PRINT SPACE(10) + '... Table: dropped'
   END
   
*/  
--** Optional

--** Required
--** Use IF NOT EXISTS syntax if the table should ONLY be created the 1st time
--** This protects against accidential loss of data
IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUserAccount'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFUserAccount]
            (
              [UserID] INT NOT NULL ,
              [LoginName] NVARCHAR(250) NULL ,
              [InternalUser] BIT NULL ,
              [Enabled] BIT NULL ,
              [Deleted] BIT
                CONSTRAINT [DF_MFUserAccount_Deleted] DEFAULT ( (0) )
                NULL ,
              CONSTRAINT [PK_MFUserAccount] PRIMARY KEY CLUSTERED
                ( [UserID] ASC ) ,
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFUserAccount')
                        AND name = N'idx_MFUserAccount_User_id' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFUserAccount_User_id';
        CREATE NONCLUSTERED INDEX idx_MFUserAccount_User_id ON dbo.MFUserAccount (UserID);
    END;

GO

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: Valuelist Items MFiles Metadata in one table
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
  Select * from MFValueListItems
  DROP table MFValueListItems
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFValueListItems]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFValueListItems', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
2018-4-18	lc	Fix bug to reset table name data type to nvarchar
*/

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFValueListItems'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
   
			CREATE TABLE [dbo].[MFValueListItems]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] NVARCHAR(100) NULL ,
              [MFID] NVARCHAR(20) NULL ,
              [MFValueListID] INT NULL ,
              [OwnerID] INT NULL ,
              [ModifiedOn] DATETIME
                CONSTRAINT [DF__MFValueListItems__Modify]
                DEFAULT ( GETDATE() )
                NOT NULL ,
              [CreatedOn] DATETIME
                CONSTRAINT [DF__MFValueListItems__Create]
                DEFAULT ( GETDATE() )
                NOT NULL ,
              [Deleted] BIT CONSTRAINT [DF_MFValueListItems_Deleted] DEFAULT ((0))
                            NOT NULL ,
              [AppRef] NVARCHAR(25) NULL ,
              [Owner_AppRef] NVARCHAR(25) NULL ,
			  [ItemGUID]  nvarchar(200),
			  [DisplayID] nvarchar(200),
			  [Process_ID] int DEFAULT ((0)),
              CONSTRAINT [PK_MFValueListItems] PRIMARY KEY CLUSTERED
                ( [ID] ASC ) ,
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--FOREIGN KEYS #############################################################################################################################
 

IF NOT EXISTS ( SELECT  *
                FROM    sys.foreign_keys
                WHERE   parent_object_id = OBJECT_ID('MFValueListItems')
                        AND name = N'FK_MFValueListItems_MFValueList' )

    BEGIN
        PRINT SPACE(10) + '... Constraint: FK_MFValueListItems_MFValueList';
        ALTER TABLE dbo.MFValueListItems WITH CHECK ADD 
        CONSTRAINT [FK_MFValueListItems_MFValueList] FOREIGN KEY ( [MFValueListID] ) REFERENCES [dbo].[MFValueList] ( [id] ) 
        ON DELETE NO ACTION;

    END;

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueListItems')
                        AND name = N'idx_MFValueListItems_AppRef' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFValueListItems_AppRef';
        CREATE NONCLUSTERED INDEX idx_MFValueListItems_AppRef ON dbo.MFValueListItems (AppRef);
    END;

	
IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFValueListItems')
                        AND name = N'fdx_MFValueListItems_MFValueListID' )
    BEGIN
        PRINT SPACE(10) + '... Index: fdx_MFValueListItems_MFValueListID';
        CREATE NONCLUSTERED INDEX fdx_MFValueListItems_MFValueListID ON dbo.MFValueListItems (MFValueListID);
    END;

GO


IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Per MF ValuelistitemID' )
    BEGIN
                
        EXECUTE sp_addextendedproperty @name = N'MS_Description',
            @value = N'Per MF ValuelistitemID', @level0type = N'SCHEMA',
            @level0name = N'dbo', @level1type = N'TABLE',
            @level1name = N'MFValueListItems', @level2type = N'COLUMN',
            @level2name = N'MFID';
        PRINT SPACE(10) + '... Extended Properties Create : ';
    END;

GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Represents on table that contain all the valuelists and all the valuelist items' )
    BEGIN
            
        EXECUTE sp_addextendedproperty @name = N'MS_Description',
            @value = N'Represents on table that contain all the valuelists and all the valuelist items',
            @level0type = N'SCHEMA', @level0name = N'dbo',
            @level1type = N'TABLE', @level1name = N'MFValueListItems';
        PRINT SPACE(10) + '... Extended Properties Create : ' ;
    END;

	IF Not Exists (Select top 1 * from INFORMATION_SCHEMA.COLUMNS C where C.COLUMN_NAME='IsNameUpdate' and C.TABLE_NAME='MFValueListItems')
			Begin

			 Alter table MFValueListItems Add IsNameUpdate Bit
             PRINT SPACE(10) + '... Added column IsNameUpdate  : ' ;
			End
GO
        

go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFSearchLog]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFSearchLog', -- nvarchar(100)
    @Object_Release = '2.0.2.7', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV 2, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFiles Search Log Details
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
  Select * from MFSearchLog
  
-----------------------------------------------------------------------------------------------*/


GO


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFSearchLog'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
	   CREATE TABLE MFSearchLog
			(
			    [ID] INT IDENTITY(1,1) NOT NULL
			  , [TableName] VARCHAR(200)
			  , [SearchClassID] INT
			  , [SearchText] VARCHAR(500)
			  , [SearchDate] DATETIME
			  , [ProcessID] INT
			  , CONSTRAINT [PK_MFSearchLog] PRIMARY KEY CLUSTERED ([ID] ASC)
			);
        

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

			
GO		
			

SET NOCOUNT ON; 
GO

GO
-- ** Required
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFWorkflowState]';
-- ** Required
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFWorkflowState', -- nvarchar(100)
    @Object_Release = '4.2.9.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Workflow State MFiles Metadata	
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-7-2		lc			change datatype of alias to varchar(100)
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFWorkflowState
  
-----------------------------------------------------------------------------------------------*/


--** Use IF EXISTS syntax if table ALWAYS needs to be dropped before being recreated.
--** WARNING: this could cause loss of data

--** Optional
/*
   IF EXISTS (SELECT name FROM sys.tables WHERE name='MFWorkflowState' AND SCHEMA_NAME(schema_id)='dbo')
   BEGIN
		DROP TABLE	dbo.MFWorkflowState
		PRINT SPACE(10) + '... Table: dropped'
   END
   
*/  
--** Optional

--** Required
--** Use IF NOT EXISTS syntax if the table should ONLY be created the 1st time
--** This protects against accidential loss of data
IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFWorkflowState'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
   

        CREATE TABLE [dbo].[MFWorkflowState]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NOT NULL ,
              [Alias] VARCHAR(100) NULL ,
              [MFID] INT NOT NULL ,
              [MFWorkflowID] INT NULL ,
              [ModifiedOn] DATETIME DEFAULT ( GETDATE() )
                                    NOT NULL ,
              [CreatedOn] DATETIME DEFAULT ( GETDATE() )
                                   NOT NULL ,
              [Deleted] BIT NOT NULL ,
              CONSTRAINT [PK_MFWorkflowState] PRIMARY KEY CLUSTERED
                ( [ID] ASC ) ,
              CONSTRAINT [FK_MFWorkflowState_MFWorkflow] FOREIGN KEY ( [MFWorkflowID] ) REFERENCES [dbo].[MFWorkflow] ( [ID] ) ,
              CONSTRAINT [TUC_MFWorkflowState_MFID] UNIQUE NONCLUSTERED
                ( [MFWorkflowID] ASC, [MFID] ASC )
            );


        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';


--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFWorkflowState')
                        AND name = N'idx_MFWorkflowState_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFWorkflowState_MFID';
        CREATE NONCLUSTERED INDEX idx_MFWorkflowState_MFID ON dbo.MFWorkflowState (MFID);
    END;


GO
--TABLE MIGRATIONS ############################################################################################################################
GO
/*	
	Effective Version: 3.1.2.38
*/
IF EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFWorkflowState'
		AND [COLUMN_NAME] = 'Alias'
		AND [CHARACTER_MAXIMUM_LENGTH] <> 100
		)
BEGIN
	ALTER TABLE [dbo].[MFWorkflowState] ALTER COLUMN [Alias] VARCHAR(100)
	PRINT SPACE(10) + '... Column [Alias]: updated column length to VARCHAR(100)';
END

GO
----Added for Bug 1088---
IF Not Exists (Select top 1 * from INFORMATION_SCHEMA.COLUMNS C where C.COLUMN_NAME='IsNameUpdate' and C.TABLE_NAME='MFWorkflowState')
			Begin

			 Alter table MFWorkflowState Add IsNameUpdate Bit
             PRINT SPACE(10) + '... Added column IsNameUpdate  : ' ;
			End
GO

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: {Database}
	Description:Object Type to Class Object Table 
	This is a special table for indexing all the class tables included in app accross all object types.
	This table is updated using the spMFObjectTypeUpdateClassIndex procedure
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
  Select * from 
  
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFObjectTypeToClassObject]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFObjectTypeToClassObject', -- nvarchar(100)
    @Object_Release = '2.0.2.4', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  name
            FROM    sys.tables
            WHERE   name = 'MFObjectTypeToClassObject'
                    AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

        IF EXISTS ( SELECT  *
                    FROM    sys.foreign_keys
                    WHERE   parent_object_id = OBJECT_ID(N'dbo.MFObjectTypeToClassObject') )
            BEGIN
                ALTER TABLE MFObjectTypeToClassObject
                DROP CONSTRAINT FK_ObjectTypeToClassIndex_Class_ID, FK_ObjectTypeToClassIndex_ObjectType_ID;
            END;

        DROP TABLE MFObjectTypeToClassObject;
    END;

CREATE TABLE [dbo].[MFObjectTypeToClassObject]
    (
      [ID] INT IDENTITY(1, 1)
               NOT NULL ,
      ObjectType_ID INT NOT NULL ,
      Class_ID INT NOT NULL ,
      Object_MFID INT NOT null ,
      Object_LastModifiedBy VARCHAR(100) ,
      Object_LastModified DATETIME ,
      Object_Deleted BIT ,
      PRIMARY KEY ( [ObjectType_ID],[Class_ID],[Object_MFID] ) 
     
    );
GO

PRINT SPACE(10) + '... Table: created';

GO

SET NOCOUNT ON 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: {Database}
	Description: Property MFiles Metadata 	
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
  Select * from MFProperty
  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProperty]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFProperty', -- nvarchar(100)
    @Object_Release = '2.0.2.3', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProperty'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFProperty]
            (
              [ID] INT IDENTITY(1, 1)
                       NOT NULL ,
              [Name] VARCHAR(100) NULL ,
              [Alias] VARCHAR(100) NOT NULL ,
              [MFID] INT NOT NULL ,
              [ColumnName] VARCHAR(100) NULL ,
              [MFDataType_ID] INT NULL ,
              [PredefinedOrAutomatic] BIT NULL ,
              [ModifiedOn] DATETIME
                CONSTRAINT [DF__MFProperty__Modify] DEFAULT ( GETDATE() )
                NOT NULL ,
              [CreatedOn] DATETIME
                CONSTRAINT [DF__MFProperty__Create] DEFAULT ( GETDATE() )
                NOT NULL ,
              [Deleted] BIT NULL ,
              [MFValueList_ID] INT NULL ,
              CONSTRAINT [PK_MFProperty] PRIMARY KEY CLUSTERED ( [ID] ASC ) ,
              CONSTRAINT [FK_MFProperty_MFValueList] FOREIGN KEY ( [MFValueList_ID] ) REFERENCES [dbo].[MFValueList] ( [id] ) ,
              CONSTRAINT [TUC_MFProperty_MFID] UNIQUE NONCLUSTERED
                ( [MFID] ASC )
            );


        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFProperty')
                        AND name = N'idx_MFProperty_MFID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFProperty_MFID';
        CREATE NONCLUSTERED INDEX idx_MFProperty_MFID ON dbo.MFProperty (MFID);
    END;


--SECURITY #########################################################################################################################3#######
--** Alternatively add ALL security scripts to single file: script.SQLPermissions_{dbname}.sql


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Per MF DataTypes' )
    EXECUTE sp_addextendedproperty @name = N'MS_Description',
        @value = N'Per MF DataTypes', @level0type = N'SCHEMA',
        @level0name = N'dbo', @level1type = N'TABLE',
        @level1name = N'MFProperty', @level2type = N'COLUMN',
        @level2name = N'MFDataType_ID';


GO
IF NOT EXISTS ( SELECT  value
                FROM    sys.[extended_properties] AS [ep]
                WHERE   value = N'Represents all the properties of the selected vault' )
    EXECUTE sp_addextendedproperty @name = N'MS_Description',
        @value = N'Represents all the properties of the selected vault',
        @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE',
        @level1name = N'MFProperty';

go

SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Class Property links the Class and the Property tables
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2017-07-24		AC			Fix Foreign Key not being created when deployed to existing installation.
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFClassProperty
  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFClassProperty]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', -- nvarchar(128)
 @ObjectName = N'MFClassProperty', -- nvarchar(100)
    @Object_Release = '4.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
2017-09-11	LC	Change name of foreign key
*/

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFClassProperty'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN
        CREATE TABLE [dbo].[MFClassProperty]
            (
              [MFClass_ID] INT NOT NULL ,
              [MFProperty_ID] INT NOT NULL ,
              [Required] BIT NOT NULL 
			  
              CONSTRAINT [PK_MFClassProperty] PRIMARY KEY CLUSTERED
                ( [MFClass_ID] ASC, [MFProperty_ID] ASC ) 
            );

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################


IF NOT EXISTS ( SELECT  *
                FROM    sys.indexes
                WHERE   object_id = OBJECT_ID('MFClassProperty')
                        AND name = N'idx_MFClassProperty_Property_ID' )
    BEGIN
        PRINT SPACE(10) + '... Index: idx_MFClassProperty_Property_ID';
        CREATE NONCLUSTERED INDEX idx_MFClassProperty_Property_ID ON dbo.MFClassProperty (MFProperty_ID);
    END;

GO

DECLARE @dbrole NVARCHAR(50)
SELECT @dbrole = CAST(value AS NVARCHAR(100)) FROM mfsettings WHERE name = 'AppUserRole'



	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (ID) ON [dbo].[MFClass] '+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (ID) ON [dbo].[MFClass] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )

	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (ID) ON [dbo].[MFProperty]'+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (ID) ON [dbo].[MFProperty] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )

	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (MFClass_ID) ON [dbo].[MFClassProperty]'+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (MFClass_ID) ON [dbo].[MFClassProperty] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )

	PRINT space(5) + '    -- ' + 'GRANT REFERENCES (MFProperty_ID) ON [dbo].[MFClassProperty]'+ 'TO [' + @dbrole + '] WITH GRANT OPTION; '	
	EXEC ('GRANT REFERENCES (MFProperty_ID) ON [dbo].[MFClassProperty] TO  [' + @dbrole + ']' +' WITH GRANT OPTION'  )



-- Foreign Keys -- the FK constraints are added when the first metadata sync takes place.
	--IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('MFClassProperty') 
	--				AND name =N'FK_MFProperty_ID' )
	--BEGIN
	--	PRINT space(10) + '... Constraint: FK_MFProperty_ID'
	--	ALTER TABLE [dbo].[MFClassProperty] ADD 
	--		CONSTRAINT [FK_MFClassProperty_MFProperty_ID] FOREIGN KEY ([MFProperty_ID])
	--			REFERENCES [dbo].[MFProperty]([ID])

				
	--END


GO


/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-09
	Database: 
	Description: Connect menu table 
	Used to set the menu items for the specific application


  USAGE:

  Select * from [dbo].[MFContextMenu]

   DROP TABLE MFContextMenu 
-----------------------------------------------------------------------------------------------*/


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFContextMenu]';

GO

EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'MFContextMenu', -- nvarchar(100)
    @Object_Release = '3.2.1.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO
/*
MODIFICATIONS

2017-7-16	lc	Set Default user group to 1 (All internal users)
2017-8-22	lc	add columns Last_Excecuted_by, Last_Executed_Date, ActionUser_ID

*/
SET NOCOUNT ON 

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFContextMenu'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN


	CREATE TABLE [dbo].[MFContextMenu](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[ActionName] [varchar](250) NULL,
		[Action] [varchar](1000) NULL,
		[ActionType] [int] NULL,
		[Message] [varchar](500) NULL,
		[SortOrder] [int] NULL,
	    [ParentID] [int] NULL DEFAULT (0),
		IsProcessRunning bit default(0),
		ISAsync BIT DEFAULT(0),
		[UserGroupID] [int] DEFAULT (1),
		Last_Executed_By INT null,
		Last_Executed_Date DATETIME null,
		ActionUser_ID INT null

		
	 CONSTRAINT [PK_MFContextMenu] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

END

/*
Modification of ContextMenu table / Migration required for all installations prior to Rel 3.2.1.27
*/

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'UserGroupID' AND [c].[TABLE_NAME] = 'MFContextMenu')
alter table MFContextMenu add [UserGroupID] [int] DEFAULT (1)

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'IsProcessRunning' AND [c].[TABLE_NAME] = 'MFContextMenu')
alter table MFContextMenu add IsProcessRunning bit default(0)

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'ISAsync' AND [c].[TABLE_NAME] = 'MFContextMenu')
alter table MFContextMenu add ISAsync BIT DEFAULT(0)

/*
Modification of ContextMenu table / Migration required for all installations prior to Rel 3.2.1.38
*/

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'Last_Executed_By' AND [c].[TABLE_NAME] = 'MFContextMenu')
Alter table MFCONTEXTMENU ADD Last_Executed_By INT;

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'Last_Executed_Date' AND [c].[TABLE_NAME] = 'MFContextMenu')
Alter table MFCONTEXTMENU ADD Last_Executed_Date DATETIME

IF NOT EXISTS(SELECT 1  FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c] WHERE [c].[COLUMN_NAME] = 'ActionUser_ID' AND [c].[TABLE_NAME] = 'MFContextMenu')
ALTER TABLE MFCONTEXTmENU ADD  ActionUser_ID INT 


GO

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFProcessBatch]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFProcessBatch', -- nvarchar(100)
    @Object_Release = '2.1.1.20', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFProcessBatch controls and record the outcome of each major process that is executed
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016 - 10- 16	LC			add column for UTCDate
	2016 - 3- 13	LC			Add trigger to update MFUserMessagesTable
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFProcessBatch

--DROP TABLE [MFProcessBatch]
-----------------------------------------------------------------------------------------------*/



IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFProcessBatch'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

CREATE TABLE [dbo].[MFProcessBatch]
    (
      [ProcessBatch_ID] INT IDENTITY(1, 1)
                            NOT NULL ,
      [ProcessType] NVARCHAR(50) NULL ,
      [LogType] NVARCHAR(50) NULL ,
      [LogText]  NVARCHAR(4000) NULL ,
      [Status] NVARCHAR(50) NULL ,
      [DurationSeconds] DECIMAL(18, 4) NULL ,
      [CreatedOn] DATETIME NULL CONSTRAINT [DF_dbo_MFProcessBatch_CreatedOn] DEFAULT ( GETDATE() ) ,
      [CreatedOnUTC] DATETIME NULL CONSTRAINT [DF_dbo_MFProcessBatch_CreatedOnUTC] DEFAULT ( GETUTCDATE() )
        CONSTRAINT [dbo_MFProcessBatch]
        PRIMARY KEY CLUSTERED ( [ProcessBatch_ID] ASC )
    )


END
GO



GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFProcessBatchDetail]';

GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
								   , @ObjectName = N'MFProcessBatchDetail' -- nvarchar(100)
								   , @Object_Release = '3.1.2.38'		   -- varchar(50)
								   , @UpdateFlag = 2;
-- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-08
	Database: 
	Description: MFProcessBatchDetail table records details about processing of key procuredures
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-10-16		lc			Add Created on ITC Date
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFProcessBatchDetail
  
--DROP TABLE dbo.[MFProcessBatchDetail]
-----------------------------------------------------------------------------------------------*/




IF NOT EXISTS (	  SELECT [name]
				  FROM	 [sys].[tables]
				  WHERE	 [name] = 'MFProcessBatchDetail'
						 AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN

		CREATE TABLE [dbo].[MFProcessBatchDetail]
			(
				[ProcessBatchDetail_ID] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
			  , [ProcessBatch_ID] INT NULL
			  , [LogType] NVARCHAR(50) NULL
			  , [ProcedureRef] NVARCHAR(258) NULL
			  , [LogText] NVARCHAR(4000) NULL
			  , [Status] NVARCHAR(50) NULL
			  , [DurationSeconds] DECIMAL(18, 4) NULL
			  , [CreatedOn] DATETIME NULL
					CONSTRAINT [DF_dbo_MFProcessBatchDetail_CreatedOn]
					DEFAULT ( GETDATE())
			  , [CreatedOnUTC] DATETIME NULL
					CONSTRAINT [DF_dbo_MFProcessBatchDetail_CreatedOnUTC]
					DEFAULT ( GETUTCDATE())
			  , [MFTableName] NVARCHAR(128) NULL
			  , [Validation_ID] INT NULL
			  , [ColumnName] NVARCHAR(128) NULL
			  , [ColumnValue] NVARCHAR(256) NULL
			  , [Update_ID] INT NULL
			);

	END

GO
--Table modifications #############################################################################################################################
-- add column [ProcessRef] to improve ability to track procedurename and procedurestep

IF NOT EXISTS (	  SELECT 1
				  FROM	 [INFORMATION_SCHEMA].[COLUMNS]
				  WHERE	 [TABLE_NAME] = 'MFProcessBatchDetail'
						 AND [COLUMN_NAME] = 'ProcedureRef'
			  )
	BEGIN
		ALTER TABLE [dbo].[MFProcessBatchDetail]
		ADD [ProcedureRef] NVARCHAR(258) NULL;
		PRINT SPACE(10) + '... Adding Column: [ProcedureRef] NVARCHAR(258)';
	END
GO
IF EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFProcessBatchDetail'
		AND [COLUMN_NAME] = 'ProcedureRef'
		AND [CHARACTER_MAXIMUM_LENGTH] <> 258
		)
BEGIN
	ALTER TABLE [dbo].[MFProcessBatchDetail] ALTER COLUMN [ProcedureRef] NVARCHAR(258)
	PRINT SPACE(10) + '... Update Column Size: [ProcedureRef] NVARCHAR(258)';
END

GO

IF NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFProcessBatchDetail'
		AND [COLUMN_NAME] = 'CreatedOnUTC'
		)
BEGIN
	ALTER TABLE [dbo].[MFProcessBatchDetail] ADD  CreatedOnUTC DATETIME NULL
					CONSTRAINT [DF_dbo_MFProcessBatchDetail_CreatedOnUTC]
					DEFAULT ( GETUTCDATE())
	PRINT SPACE(10) + '... Add Column : CreatedOn UTCGETUTCDATE()';
END

GO
--INDEXES #############################################################################################################################


IF NOT EXISTS (	  SELECT *
				  FROM	 [sys].[indexes]
				  WHERE	 [object_id] = OBJECT_ID('dbo.MFProcessBatchDetail')
						 AND [name] = N'idx_dbo_MFProcessBatchDetail'
			  )
	BEGIN
		PRINT SPACE(10) + '... Creating Unique Index: idx_dbo_MFProcessBatchDetail';
		CREATE NONCLUSTERED INDEX [idx_dbo_MFProcessBatchDetail]
			ON [dbo].[MFProcessBatchDetail] ( [ProcessBatch_ID] );
	END;
ELSE
	PRINT SPACE(10) + '... Unique Index: idx_dbo_MFProcessBatchDetail exists';



GO


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFExportFileHistory]';

GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
								   , @ObjectName = N'MFExportFileHistory' -- nvarchar(100)
								   , @Object_Release = '4.2.7.46'		   -- varchar(50)
								   , @UpdateFlag = 2;
-- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-09
	Database: 
	Description: MFExportFileHistory table records for files exported from M-Files
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2018-6-29		lc			Add Column for MultiDocFolder
	2018-9-27		lc			Add script to alter column if missing
	2019-2-22		lc			Increase size of column for filename
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFExportFileHistory
  
--DROP TABLE dbo.[MFExportFileHistory]
-----------------------------------------------------------------------------------------------*/




IF NOT EXISTS (	  SELECT [name]
				  FROM	 [sys].[tables]
				  WHERE	 [name] = 'MFExportFileHistory'
						 AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN




CREATE TABLE MFExportFileHistory
(ID INT IDENTITY PRIMARY key
,FileExportRoot NVARCHAR(100) 
,SubFolder_1 NVARCHAR(100) 
,SubFolder_2 NVARCHAR(100) 
,SubFolder_3 NVARCHAR(100) 
,MultiDocFolder NVARCHAR(100)
,FileName NVARCHAR(256)
,ClassID INT 
,ObjID int
,ObjType int
,Version int
,[FileCheckSum] NVARCHAR(100)
,FileCount INT
,Created DATETIME DEFAULT (GETDATE())
)


	END



GO
--Table modifications #############################################################################################################################

/*	
	Effective Version: 4.2.5.43
	MultiDocFolder is introoduced in this version
*/
IF NOT EXISTS (	  SELECT	1
				  FROM		[INFORMATION_SCHEMA].[COLUMNS] AS [c]
				  WHERE		[c].[TABLE_NAME] = 'MFExportFileHistory'
							AND [c].[COLUMN_NAME] = 'MultiDocFolder'
			  )
	BEGIN
		ALTER TABLE dbo.[MFExportFileHistory] ADD [MultiDocFolder] NVARCHAR(500)

		PRINT SPACE(10) + '... Column [MultiDocFolder]: added';

	END


	GO 

	IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFExportFileHistory'
		AND [COLUMN_NAME] = 'FileObjectID'
		
		)
BEGIN
	ALTER TABLE MFExportFileHistory ADD FileObjectID INT;
	PRINT SPACE(10) + '... Column Message: Added FileObjectID Column';
END

GO
--INDEXES #############################################################################################################################





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





go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFFileImport]';

GO


SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFFileImport', -- nvarchar(100)
    @Object_Release = '4.3.9.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: DEV TEAM2, Laminin Solutions
	Create date: 2018-02
	Database: 
	Description: MFiles FileImport 
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2019-3-23		LC			Add ImportError Column
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  Select * from MFFileImport
  
-----------------------------------------------------------------------------------------------*/
IF NOT EXISTS (	  SELECT	[name]
				  FROM		[sys].[tables]
				  WHERE		[name] = 'MFFileImport'
							AND SCHEMA_NAME([schema_id]) = 'dbo'
			  )
	BEGIN
	      CREATE TABLE MFFileImport
		   (
		      [ID] INT IDENTITY(1,1) NOT NULL,
			  [FileName] VARCHAR(100),
			  [FileUniqueRef] VARCHAR(100),
			  [CreatedOn] DATETIME DEFAULT ( GETDATE()) NOT NULL,
			  [SourceName] VARCHAR(100),
			  [TargetClassID] INT,
			  [MFCreated] DATETIME,
			  [MFLastModified] DATETIME,
			  [ObjID] INT, 
			  [Version] INT,
			  CONSTRAINT [PK_MFFileImport]
					PRIMARY KEY CLUSTERED ( [ID] ASC) 
		   )
	End
ELSE 

PRINT SPACE(10) + '... Table: exist'

GO
IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFFileImport'
		AND [COLUMN_NAME] = 'FileObjectID'
		
		)
BEGIN
	ALTER TABLE MFFileImport ADD FileObjectID INT;
	PRINT SPACE(10) + '... Column Message: Added FileObjectID Column';
END

GO

IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFFileImport'
		AND [COLUMN_NAME] = 'FileCheckSum'
		
		)
BEGIN
	ALTER TABLE MFFileImport ADD FileCheckSum NVARCHAR(MAX);
	PRINT SPACE(10) + '... Column Message: Added FileCheckSum Column';
END

IF  NOT EXISTS(SELECT 1 FROM [INFORMATION_SCHEMA].[COLUMNS] 
		WHERE [TABLE_NAME] = 'MFFileImport'
		AND [COLUMN_NAME] = 'ImportError' 		
		)
BEGIN
	ALTER TABLE MFFileImport ADD ImportError NVARCHAR(4000);
	PRINT SPACE(10) + '... Column Message: Added ImportError Column';

	END
GO
SET NOCOUNT ON; 
GO
/*----------DevTeam 2, Laminin Solutions
	Create date: 2019-02
	Database: 
	Description: UnManaged Metadata 	
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
  Select * from MFUnManagedObject

  Alter table MFUnManagedObject
  

  
  DROP TABLE MFUnManagedObject
  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUnmanagedObject]';

GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUnmanagedObject', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUnmanagedObject'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
    BEGIN

	CREATE TABLE [dbo].[MFUnmanagedObject]
	(
	 [ID] INT IDENTITY (1,1) NOT NULL
	,[Name_Or_Title] NVARCHAR(100)
	,[Remote_Vault_Guid]  NVARCHAR(100)
	,[Location_ID] NVARCHAR(250)
	,[Repository_ID] NVARCHAR(250)
	,[Status_Changed] DATETIME
	,[Created] DATETIME
	,[MF_Last_Modified] DATETIME CONSTRAINT [DF_MFUnmanagedObject_MF_Last_Modified] DEFAULT(GETDATE()) NOT NULL
	,Process_ID INT
	,Single_File BIT
	,Class_ID NVARCHAR(50) 
	,External_ObjectID INT

	CONSTRAINT [PK_MFUnmanagedObject] PRIMARY KEY CLUSTERED([ID] ASC)
	)
   
        

        PRINT SPACE(10) + '... Table: created';
    END;
ELSE
    PRINT SPACE(10) + '... Table: exists';

--INDEXES #############################################################################################################################






GO






















SET NOCOUNT ON; 
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2018-04
	Database: 
	Description: MFUserMessages	
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

  
-----------------------------------------------------------------------------------------------*/

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[MFUserMessages]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFUserMessages', -- nvarchar(100)
    @Object_Release = '4.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUserMessages'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
						BEGIN
                        
						DROP TABLE MFUserMessages;

						END;

    BEGIN

CREATE TABLE [dbo].[MFUserMessages](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[GUID] [NVARCHAR](100) NULL,
	[MX_User_ID] [UNIQUEIDENTIFIER] NULL,
	[Class] [NVARCHAR](100) NULL,
	[Class_ID] [INT] NOT NULL,
	[Created] [DATETIME] NULL,
	[Created_by] [NVARCHAR](100) NULL,
	[Created_by_ID] [INT] NULL,
	[MF_Last_Modified] [DATETIME] NULL,
	[MF_Last_Modified_by] [NVARCHAR](100) NULL,
	[MF_Last_Modified_by_ID] [INT] NULL,
	[Mfsql_Class_Table] [NVARCHAR](100) NULL,
	[Mfsql_Count] INT NULL,
	[Mfsql_Message] [NVARCHAR](4000) NULL,
	[Mfsql_Process_Batch] [INT] NULL,
	[Mfsql_User] [NVARCHAR](100) NULL,
	[Mfsql_User_ID] [INT] NULL,
	[Name_Or_Title] [NVARCHAR](100) NULL,
	[Single_File] [BIT] NOT NULL,
	[Workflow] [NVARCHAR](100) NULL,
	[Workflow_ID] [INT] NULL,
	[State] [NVARCHAR](100) NULL,
	[State_ID] [INT] NULL,
	[LastModified] [DATETIME] NULL,
	[Process_ID] [INT] NULL,
	[ObjID] [INT] NULL,
	[ExternalID] [NVARCHAR](100) NULL,
	[MFVersion] [INT] NULL,
	[FileCount] [INT] NULL,
	[Deleted] [BIT] NULL,
	[Update_ID] [INT] NULL,
 CONSTRAINT [pk_MFUserMessagesID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_Class_MFUserMessages]  DEFAULT ((-1)) FOR [Class_ID]


ALTER TABLE [dbo].[MFUserMessages] ADD  DEFAULT ((0)) FOR [Single_File]


ALTER TABLE [dbo].[MFUserMessages] ADD  DEFAULT (GETDATE()) FOR [LastModified]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_Process_id_MFUserMessages]  DEFAULT ((1)) FOR [Process_ID]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_FileCount_MFUserMessages]  DEFAULT ((0)) FOR [FileCount]


ALTER TABLE [dbo].[MFUserMessages] ADD  CONSTRAINT [DK_Deleted_MFUserMessages]  DEFAULT ((0)) FOR [Deleted]


END

GO


--added 2018-10-30
--4.2.7.46

--foreign key index for FK_MFClass_ObjectType_ID  

IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='FKIX_MFClass_MFObjectType_ID' AND object_id = OBJECT_ID('[dbo].[MFClass]'))
CREATE NONCLUSTERED INDEX FKIX_MFClass_MFObjectType_ID  ON [dbo].[MFClass] ([MFObjectType_ID]) ;

--foreign key index for FK_MFClass_MFWorkflow_ID 
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='FKIX_MFClass_MFWorkflow_ID' AND object_id = OBJECT_ID('[dbo].[MFClass]'))
CREATE NONCLUSTERED INDEX FKIX_MFClass_MFWorkflow_ID  ON [dbo].[MFClass] ([MFWorkflow_ID]);
  
--foreign key index for FK_ObjectTypeToClassIndex_Class_ID  
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='FKIX_MFObjectTypeToClassObject_Class_ID' AND object_id = OBJECT_ID('[dbo].[MFObjectTypeToClassObject]'))
CREATE NONCLUSTERED INDEX FKIX_MFObjectTypeToClassObject_Class_ID  ON [dbo].[MFObjectTypeToClassObject] ([Class_ID]) ;
--foreign key index for FK_ObjectTypeToClassIndex_ObjectType_ID  

IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='FKIX_MFObjectTypeToClassObject_ObjectType_ID' AND object_id = OBJECT_ID('[dbo].[MFObjectTypeToClassObject]'))
CREATE NONCLUSTERED INDEX FKIX_MFObjectTypeToClassObject_ObjectType_ID  ON [dbo].[MFObjectTypeToClassObject] ([ObjectType_ID]);

--foreign key index for FK_MFProperty_MFValueList  
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='FKIX_MFProperty_MFValueList_ID' AND object_id = OBJECT_ID('[dbo].[MFProperty]'))
CREATE NONCLUSTERED INDEX FKIX_MFProperty_MFValueList_ID  ON [dbo].[MFProperty] ([MFValueList_ID]);

--foreign key index for FK_MFVaultSettings_MFAuthenticationType_ID  
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='FKIX_MFVaultSettings_MFAuthenticationType_ID' AND object_id = OBJECT_ID('[dbo].[MFVaultSettings]'))
CREATE NONCLUSTERED INDEX FKIX_MFVaultSettings_MFAuthenticationType_ID  ON [dbo].[MFVaultSettings] ([MFAuthenticationType_ID]);

--foreign key index for FK_MFVaultSettings_MFProtocolType_ID  
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='FKIX_MFVaultSettings_MFProtocolType_ID' AND object_id = OBJECT_ID('[dbo].[MFVaultSettings]'))
CREATE NONCLUSTERED INDEX FKIX_MFVaultSettings_MFProtocolType_ID  ON [dbo].[MFVaultSettings] ([MFProtocolType_ID]) ;


--SELECT * FROM sys.[indexes] AS [i] where OBJECT_ID('[dbo].[MFSettings]') = object_ID
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + 'tMFProcessBatch_UserMessage';
GO

SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS
(
    SELECT *
    FROM [sys].[objects]
    WHERE [type] = 'TR'
          AND [name] = 'tMFProcessBatch_UserMessage'
)
BEGIN
    DROP TRIGGER [dbo].[tMFProcessBatch_UserMessage];

    PRINT SPACE(10) + '...Trigger dropped and recreated';
END;
GO

CREATE TRIGGER [dbo].[tMFProcessBatch_UserMessage]
ON [dbo].[MFProcessBatch]
FOR UPDATE
AS
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-03
	Database: 
	Description: Create User Message in MFUserMessages table where LogType = Message
						
				 Executed when ever [LogType] is updated in [MFProcessBatch]
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	YYYY-MM-DD		{Author}	{Comment}
	2018-11-16		LC			Add test to check for @Usermessageenabled, remove @class param
	2018-11-16		LC			Add error trappaing and reporting
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  update MFProcessBatch set LogType = 'Message' where ProcessBatch_ID = 25
  select * from mfusermessages where MFSQL_Process_batch = 25
  
-----------------------------------------------------------------------------------------------*/
DECLARE @result             INT
       ,@LogType            NVARCHAR(100)
       ,@ProcessBatch_ID    INT
       ,@UserMessageEnabled INT;
DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.tMFProcessBatch_UserMessage';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) 
		DECLARE @LogTypeDetail AS NVARCHAR(50) 
		DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @StartTime AS DATETIME = GETUTCDATE();

IF UPDATE([LogType])
--BEGIN try
Begin
    SELECT @LogType         = [Inserted].[LogType]
          ,@ProcessBatch_ID = [Inserted].[ProcessBatch_ID]
    FROM [Inserted];

    IF @LogType = 'Message'
    BEGIN
        SELECT @UserMessageEnabled = CAST(ISNULL([ms].[Value],0) AS INT)
        FROM [dbo].[MFSettings] AS [ms]
        WHERE [ms].[Name] = 'MFUserMessagesEnabled';

		IF @UserMessageEnabled =1
		Begin
        EXEC  [dbo].[spMFInsertUserMessage] @ProcessBatch_ID = @ProcessBatch_ID
                                                    ,@UserMessageEnabled = @UserMessageEnabled
                                                    ,@Debug = 0;
		        
       
		END --usermessageenabled = 1
    END; --logtype message
	END --logtype updated

	/*
END TRY
		BEGIN CATCH
			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			  , @ProcessType = 'MFProcessBatch Trigger'
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @debug = 0

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = 'MFProcessBatch'
			  , @Validation_ID = null
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = null
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

		
		END CATCH
		*/	
GO
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFCapitalizeFirstLetter]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFCapitalizeFirstLetter', -- nvarchar(100)
    @Object_Release = '2.1.1.12', -- varchar(50)
    @UpdateFlag = 2 -- smallint
gO
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFCapitalizeFirstLetter'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFCapitalizeFirstLetter]
END	
GO

/*
!~
===============================================================================================
OBJECT:        fnMFCapitalizeFirstLetter
===============================================================================================
OBJECT TYPE:   Scalar Valued Function
===============================================================================================
PARAMETERS:		@String - input string to concat words and capitalize first letter of each word
===============================================================================================
PURPOSE:       Used to capitalize first letter of each word and concatinate it
===============================================================================================
DESCRIPTION:  
===============================================================================================
NOTES:                
===============================================================================================
HISTORY:
      09/13/2014 - Dev 2 - Initial Version - QA

===============================================================================================
~!
*/
CREATE FUNCTION [dbo].[fnMFCapitalizeFirstLetter] (@String VARCHAR(250) --STRING NEED TO FORMAT
)
RETURNS VARCHAR(200)
AS
  BEGIN
      -----------------------------
      --DECLARE VARIABLES
      -----------------------------
      DECLARE @Index         INT
              ,@ResultString VARCHAR(250)

      SET @Index = 1
      SET @ResultString = ''

      -------------------------------------------
      --RUN THE LOOP UNTIL END OF THE STRING
      -------------------------------------------
      WHILE ( @Index < Len(@String) + 1 )
        BEGIN
            IF ( @Index = 1 ) --FIRST LETTER OF THE STRING
              BEGIN
                  -------------------------------------------
                  --MAKE THE FIRST LETTER CAPITAL
                  -------------------------------------------
                  SET @ResultString = @ResultString
                                      + Upper(Substring(@String, @Index, 1))
                  -------------------------------------------
                  -------------------------------------------
                  SET @Index = @Index + 1 --increase the index
              END
            --------------------------------------------------------------------------------------
            -- IF THE PREVIOUS CHARACTER IS SPACE OR '-' OR NEXT CHARACTER IS '-'
            --------------------------------------------------------------------------------------
            ELSE IF ( ( Substring(@String, @Index - 1, 1) = ' '
                    OR Substring(@String, @Index - 1, 1) = '-'
                    OR Substring(@String, @Index + 1, 1) = '-' )
                 AND @Index + 1 <> Len(@String) )
              BEGIN
                  -------------------------------------------
                  --MAKE THE LETTER CAPITAL
                  -------------------------------------------
                  SET @ResultString = @ResultString
                                      + Upper(Substring(@String, @Index, 1))
                  SET @Index = @Index + 1 --increase the index
              END
            ELSE -- all others
              BEGIN
                  -------------------------------------------
                  -- MAKE THE LETTER LOWER CASE
                  -------------------------------------------
                  SET @ResultString = @ResultString
                                      + Lower(Substring(@String, @Index, 1))
                  ----------------------------------
                  --INCERASE THE INDEX
                  ----------------------------------
                  SET @Index = @Index + 1
              END
        END --END OF THE LOOP
      --------------------------------------------
      -- ANY ERROR OCCUR RETURN THE SEND STRING
      --------------------------------------------
      IF ( @@ERROR <> 0 )
        BEGIN
            SET @ResultString = @String
        END

      DECLARE @expres AS VARCHAR(50) = '%[~,@,#,$,%,&,/,\,^,'',+,<,>,:,;,?,",*,(,),.,!,-]%'

      WHILE Patindex(@expres, @ResultString) > 0
        SET @ResultString = Replace(@ResultString, Substring(@ResultString, Patindex(@expres, @ResultString), 1), '')

      --------------------------------------------------
      -- IF NO ERROR FOUND RETURN THE NEW STRING
      --------------------------------------------------
      RETURN @ResultString
  END
  go
  
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFParseDelimitedString]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFParseDelimitedString', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFParseDelimitedString'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   SET NOEXEC ON
	GO
CREATE FUNCTION [dbo].[fnMFParseDelimitedString] ( )
RETURNS @tblList TABLE
      (
        ID INT IDENTITY(1, 1)
      , ListItem VARCHAR(1000)
      )
       WITH EXECUTE AS CALLER
AS
    BEGIN
		INSERT @tblList( [ListItem] )
		VALUES  ( 'not implemented' )
        RETURN 
    END
	GO
SET NOEXEC OFF
	GO
/*
!~
===============================================================================
OBJECT:        fnParseDelimitedString
===============================================================================
OBJECT TYPE:   Table Valued Function
===============================================================================
PARAMETERS:		@List - Delimited list to convert to key value pair tabl
				@Delimiter - delimiter, i.e. ','
===============================================================================
PURPOSE:    Converts a delimited list into a table
===============================================================================
DESCRIPTION:  
===============================================================================
NOTES:        
        SELECT * FROM dbo.fnParseDelimitedString('A,B,C',',')      
===============================================================================
HISTORY:
      09/13/2014 - Arnie Cilliers - Initial Version - QA
	  17/12/2017	LeRoux			Increase size of listitem to ensure that it will catr for longer names
===============================================================================
~!
*/ 
ALTER FUNCTION [dbo].[fnMFParseDelimitedString]
      (
        @List VARCHAR(MAX)
      , @Delimeter CHAR(1)
      )
RETURNS @tblList TABLE
      (
        ID INT IDENTITY(1, 1)
      , ListItem VARCHAR(1000)
      )
AS
    BEGIN

        DECLARE @ListItem VARCHAR(1000)
        DECLARE @StartPos INT
              , @Length INT
        WHILE LEN(@List) > 0
              BEGIN
                    SET @StartPos = CHARINDEX(@Delimeter, @List)
                    IF @StartPos < 0
                       SET @StartPos = 0
                    SET @Length = LEN(@List) - @StartPos - 1
                    IF @Length < 0
                       SET @Length = 0
                    IF @StartPos > 0
                       BEGIN
                             SET @ListItem = SUBSTRING(@List, 1, @StartPos - 1)
                             SET @List = SUBSTRING(@List, @StartPos + 1, LEN(@List) - @StartPos)
                       END
                    ELSE
                       BEGIN
                             SET @ListItem = @List
                             SET @List = ''
                       END
                    INSERT  @tblList
                            ( ListItem )
                    VALUES  ( @ListItem )
              END

        RETURN 
    END
	go
	
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFReplaceSpecialCharacter]'
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFReplaceSpecialCharacter', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
2017-12-03	LC fix bug of adding 2 underscores
*/

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFReplaceSpecialCharacter'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFReplaceSpecialCharacter]
END	
GO

CREATE FUNCTION [dbo].[fnMFReplaceSpecialCharacter] (@ColumnName [NVARCHAR](2000))
RETURNS VARCHAR(2000)
AS
  BEGIN
      -------------------------------------
      --Replace Special Characters
      -------------------------------------
      DECLARE @expres AS VARCHAR(50) = '%[~,@,#,$,%,&,/,\,^,+,<,>,'',:,;,?,",*,(,),.,!,-]%'

      WHILE Patindex(@expres, @ColumnName) > 0
        SET @ColumnName = Replace(@ColumnName, Substring(@ColumnName, Patindex(@expres, @ColumnName), 1), '')

      ----------------------------------         
      --Capitalize the First Letter
      ----------------------------------
      SET @ColumnName = dbo.fnMFCapitalizeFirstLetter(@ColumnName)
      ----------------------------------
      --Replace ' ' with '_'
      ----------------------------------
      SET @ColumnName = Replace(@ColumnName, '  ', '_') --two spaces
	  SET @ColumnName = Replace(@ColumnName, ' ', '_') --one space

	

      RETURN @ColumnName
  END

GO
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFSplit]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFSplit', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFSplit'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   SET NOEXEC ON
	GO
	CREATE FUNCTION [dbo].[fnMFSplit] ( )
RETURNS @tblList TABLE
      (
        ID INT IDENTITY(1, 1)
      , ListItem VARCHAR(50)
      )
       WITH EXECUTE AS CALLER
AS
    BEGIN
		INSERT @tblList( [ListItem] )
		VALUES  ( 'not implemented' )
        RETURN 
    END
	GO
SET NOEXEC OFF
	GO
/*
!~
=========================================================================================
OBJECT:        fnMFSplit
=========================================================================================
OBJECT TYPE:   Table Valued Function
========================================================================================
PARAMETERS:		@PropertyIDs    - multiple property id's separated by ',' ie: 1,2,3
				@PropertyValues - multiple property values's separated by ',' ie: a,b,c
				@Delimiter      - delimiter, i.e. ','
=========================================================================================
PURPOSE:    Converts a delimited list into a table
=========================================================================================
DESCRIPTION:  
=========================================================================================
NOTES:        
        SELECT * FROM dbo.fnMFSplit('1,2,3','a,b,c',',')      
=========================================================================================
HISTORY:
      09/13/2014 - Arnie Cilliers - Initial Version - QA

=========================================================================================
~!
*/
alter FUNCTION [dbo].[fnMFSplit] (@PropertyIDs     VARCHAR(MAX)
                               ,@PropertyValues VARCHAR(MAX)
                               ,@Delimiter      CHAR(1))
RETURNS @temptable TABLE (
  PropertyID    VARCHAR(MAX),
  PropertyValue VARCHAR(MAX))
AS
  BEGIN
      DECLARE @idx   INT
              ,@idx1 INT
      DECLARE @slice   VARCHAR(8000)
              ,@slice1 VARCHAR(8000)

      SELECT @idx = 1

      IF Len(@PropertyIDs) < 1
          OR @PropertyIDs IS NULL
        RETURN

      WHILE @idx != 0
        BEGIN
            SET @idx = Charindex(@Delimiter, @PropertyIDs)

            IF @idx != 0
              SET @slice = LEFT(@PropertyIDs, @idx - 1)
            ELSE
              SET @slice = @PropertyIDs

            SET @idx1 = Charindex(@Delimiter, @PropertyValues)

            IF @idx1 != 0
              SET @slice1 = LEFT(@PropertyValues, @idx1 - 1)
            ELSE
              SET @slice1 = @PropertyValues

            IF ( Len(@slice) > 0 )
              INSERT INTO @temptable
                          (PropertyID,
                           PropertyValue)
              VALUES      ( @slice,
                            @slice1 )

            SET @PropertyIDs = RIGHT(@PropertyIDs, Len(@PropertyIDs) - @idx)
            SET @PropertyValues = RIGHT(@PropertyValues, Len(@PropertyValues) - @idx1)

            IF Len(@PropertyIDs) = 0
              BREAK
        END

      RETURN
  END;
  go
  
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFSplitString]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFSplitString', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFSplitString'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[fnMFSplitString]
END	
GO

/*
!~
===============================================================================================
OBJECT:        fnSplitString
===============================================================================================
OBJECT TYPE:   Table Valued Function
===============================================================================================
PARAMETERS:		@Input - multiple column Name's separated by ',' ie: 1,2,3
				@Delimiter      - delimiter, i.e. ','
===============================================================================================
PURPOSE:       Used to Converts a delimited list into a table
===============================================================================================
DESCRIPTION:  
===============================================================================================
NOTES:        SELECT * FROM dbo.fnSplitString('a,b,c',',')           
===============================================================================================
HISTORY:
      14/05/2015 - Dev 2 - Initial Version - QA

===============================================================================================
~!
*/
CREATE FUNCTION [dbo].[fnMFSplitString]
(    
      @Input NVARCHAR(MAX),
      @Character CHAR(1)
)
RETURNS @Output TABLE (
      Item NVARCHAR(1000)
)
AS
BEGIN
      DECLARE @StartIndex INT, @EndIndex INT
 
      SET @StartIndex = 1
      IF SUBSTRING(@Input, LEN(@Input) - 1, LEN(@Input)) <> @Character
      BEGIN
            SET @Input = @Input + @Character
      END
 
      WHILE CHARINDEX(@Character, @Input) > 0
      BEGIN
            SET @EndIndex = CHARINDEX(@Character, @Input)
           
            INSERT INTO @Output(Item)
            SELECT SUBSTRING(@Input, @StartIndex, @EndIndex - 1)
           
            SET @Input = SUBSTRING(@Input, @EndIndex + 1, LEN(@Input))
      END
 
      RETURN
END

GO
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[FnMFVaultSettings]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'FnMFVaultSettings', -- nvarchar(100)
    @Object_Release = '2.1.1.0', -- varchar(50)
    @UpdateFlag = 2 -- smallint


go
IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'FnMFVaultSettings'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].[FnMFVaultSettings]
END	
GO
 

/*
!~
===============================================================================================
OBJECT:        FnMFVaultSettings
===============================================================================================
OBJECT TYPE:   Scalar Valued Function
===============================================================================================
PARAMETERS:		None
===============================================================================================
PURPOSE:       Used to get vault settings from settings table in single string.
===============================================================================================
DESCRIPTION:  
===============================================================================================
NOTES:                
===============================================================================================
HISTORY:
      09/19/2016 - Dev 2 - Initial Version - QA

===============================================================================================
~!
*/
create FUNCTION dbo.FnMFVaultSettings ()
RETURNS VARCHAR(6000)
AS
  BEGIN
      DECLARE @ResultString VARCHAR(MAX)


	 select @ResultString=convert(nvarchar(128),isnull(Username,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Password,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(NetworkAddress,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(VaultName,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(MFPT.MFProtocolTypeValue,'')) from MFVaultSettings MFVS inner join MFProtocolType MFPT on MFVS.MFProtocolType_ID=MFPT.ID 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Endpoint,'')) from MFVaultSettings 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(MFAT.AuthenticationTypeValue,'')) from MFVaultSettings MFVS inner join MFAuthenticationType MFAT on MFVS.MFAuthenticationType_ID=MFAT.ID 
	 select @ResultString= @ResultString+','+convert(nvarchar(128),isnull(Domain,'')) from MFVaultSettings 

      RETURN @ResultString
  END
  
  GO


  
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFVariableTableName]';
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON;
EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'fnMFVariableTableName', -- nvarchar(100)
                                 @Object_Release = '3.1.5.41',            -- varchar(50)
                                 @UpdateFlag = 2;                        -- smallint
GO

/*
MODIFICATIONS
2018-02-28	lc	Include an alternative method of setting the file name based on unique identifyer. this is controlled by using a flag.
*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'fnMFVariableTableName' --name of procedire
          AND ROUTINE_TYPE = 'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    DROP FUNCTION dbo.fnMFVariableTableName;
END;
GO


-- =============================================
-- Author:		leRoux Cilliers
-- Create date: 2016-05-15
-- Description:	Create Unique Table Name
-- =============================================
/*
	Sample:
	SELECT  [dbo].[fnMFVariableTableName]( 'tmpTest','1')
*/
-- =============================================
-- Author:		leRoux Cilliers
-- Create date: 2016-05-15
-- Description:	Create Unique Table Name
-- =============================================
CREATE FUNCTION fnMFVariableTableName
(
    -- Add the parameters for the function here
    @TablePrefix NVARCHAR(100),
    @TableSuffix NVARCHAR(20) = NULL
)
RETURNS NVARCHAR(100)
AS
BEGIN
    -- Declare the return variable here
    DECLARE @TableName NVARCHAR(100);

    DECLARE @Flag BIT = 1;

    -- Add the T-SQL statements to compute the return value here

    -- Variable that will contain the name of the table

    IF @Flag = 0
    BEGIN
        SELECT @TableName = @TablePrefix + '_' + ISNULL(@TableSuffix, CONVERT(CHAR(12), GETDATE(), 14));

        -- Table cannot be created with the character  ":"  in it
        -- The following while loop strips off the colon
        DECLARE @pos INT;
        SELECT @pos = CHARINDEX(':', @TableName);

        WHILE @pos > 0
        BEGIN
            SELECT @TableName = SUBSTRING(@TableName, 1, @pos - 1) + SUBSTRING(@TableName, @pos + 1, 30 - @pos);
            SELECT @pos = CHARINDEX(':', @TableName);
        END;
    END;


    IF @Flag = 1
    BEGIN
        DECLARE @TableGUID UNIQUEIDENTIFIER;


        SELECT @TableGUID = new_id
        FROM dbo.MFvwTableID;

		SELECT @TableSuffix = REPLACE(CAST(@TableGUID AS VARCHAR(50)),'-','')

        SELECT @TableName = @TablePrefix + '_' + @TableSuffix ;
    END;

    -- Return the result of the function
    RETURN @TableName;

END;

GO
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFMultiLookupUpsert]'
PRINT SPACE(10) + '...Function: Create';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFMultiLookupUpsert', -- nvarchar(100)
    @Object_Release = '4.1.5.43', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*
Add or remove list of items from a delimited string
fix bug for deletions
*/

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFMultiLookupUpsert'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
BEGIN					
	DROP FUNCTION [dbo].fnMFMultiLookupUpsert
END	
GO

CREATE FUNCTION [dbo].fnMFMultiLookupUpsert (@ItemList NVARCHAR(4000), @ChangeList NVARCHAR(4000),  @UpdateType SMALLINT = 1 )

RETURNS VARCHAR(4000)
AS
  BEGIN
     
	 
	DECLARE @ListTable  AS TABLE ( Rowid INT IDENTITY NOT null, ID INT NOT null);
	DECLARE @TempTable AS TABLE ( Rowid INT IDENTITY NOT null, ID INT NOT null);
 -- 1 = add , -1 remove

	
 		IF @UpdateType = 1
	BEGIN

 INSERT INTO @TempTable
 (
     ID
 )

 SELECT listitem from [dbo].[fnMFParseDelimitedString](@ItemList,',') GROUP BY ListItem
UNION 
SELECT listitem from [dbo].[fnMFParseDelimitedString](@ChangeList,',') 

INSERT INTO @ListTable
(
    ID
)

SELECT id FROM @TempTable AS tt GROUP BY tt.ID


	END

	IF @UpdateType = -1
	BEGIN

	INSERT INTO @ListTable
 (
     ID
 )
	 SELECT listitem from [dbo].[fnMFParseDelimitedString](@ItemList,',') GROUP BY ListItem

    DELETE FROM @ListTable WHERE id IN (SELECT listitem from [dbo].[fnMFParseDelimitedString](@ChangeList,',') )

	END
	DECLARE @ReturnList NVARCHAR(4000)

	SELECT @ReturnList = COALESCE(@ReturnList + ',','') + CAST(id as NVARCHAR(10)) FROM @ListTable AS [lt]

  RETURN @ReturnList
  END
GO
SET NOCOUNT ON;
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[fnMFSplitPairedStrings]';
PRINT SPACE(10) + '...Function: Create'
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'fnMFSplitPairedStrings', -- nvarchar(100)
    @Object_Release = '3.1.4.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    information_schema.[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'fnMFSplitPairedStrings'--name of procedire
                    AND [ROUTINES].[ROUTINE_TYPE] = 'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   SET NOEXEC ON
	GO
	CREATE FUNCTION [dbo].fnMFSplitPairedStrings ( )
RETURNS @tblList TABLE
      (
        ID INT IDENTITY(1, 1)
      , ListItem VARCHAR(50)
      )
       WITH EXECUTE AS CALLER
AS
    BEGIN
		INSERT @tblList( [ListItem] )
		VALUES  ( 'not implemented' )
        RETURN 
    END
	GO
SET NOEXEC OFF
	GO
/*
!~
=========================================================================================
OBJECT:        fnMFSplitPairedStrings
=========================================================================================
OBJECT TYPE:   Table Valued Function
========================================================================================
PARAMETERS:		@PropertyIDs    - multiple property id's separated by ',' ie: 1,2,3
				@PropertyValues - multiple property values's separated by ',' ie: a,b,c
				@Delimiter      - delimiter, i.e. ','
				@Delimiter_MultiLookup - second delimited used to split multilookop value, e.g. '#'
=========================================================================================
PURPOSE:    Converts a delimited list with two pairing columns into a table, caters for a value as a delimited list 
=========================================================================================
DESCRIPTION:  
=========================================================================================
NOTES:        
        SELECT * FROM dbo.fnMFSplitPairedStrings('1,2,3','a,b,c',',','#')      
=========================================================================================
HISTORY:
      09/13/2014 - Arnie Cilliers - Initial Version - QA
	  2017-12-21	leRoux Cilliers	Change name of function.  Allow for including multilookup value with multiDelimiter, change names of parameters


=========================================================================================
~!
*/
alter FUNCTION [dbo].[fnMFSplitPairedStrings] (@PairColumn1     VARCHAR(MAX)
                               ,@PairColumn2 VARCHAR(MAX)
                               ,@Delimiter      CHAR(1)
							   ,@Delimiter_MultiLookup CHAR(1))

RETURNS @temptable TABLE (
  PairColumn1    VARCHAR(MAX),
  PairColumn2 VARCHAR(MAX))
AS
  BEGIN
      DECLARE @idx   INT
              ,@idx1 INT
      DECLARE @slice   VARCHAR(8000)
              ,@slice1 VARCHAR(8000)

      SELECT @idx = 1

      IF Len(@PairColumn1) < 1
          OR @PairColumn1 IS NULL
        RETURN

      WHILE @idx != 0
        BEGIN
            SET @idx = Charindex(@Delimiter, @PairColumn1)

            IF @idx != 0
              SET @slice = LEFT(@PairColumn1, @idx - 1)
            ELSE
              SET @slice = @PairColumn1

            SET @idx1 = Charindex(@Delimiter, @PairColumn2)

            IF @idx1 != 0
              SET @slice1 = LEFT(@PairColumn2, @idx1 - 1)
            ELSE
              SET @slice1 = @PairColumn2
	  			 
			 SELECT @slice1 = REPLACE(@slice1,@Delimiter_MultiLookup,@Delimiter)

            IF ( Len(@slice) > 0 )
              INSERT INTO @temptable
                          (PairColumn1,
                          PairColumn2)
              VALUES      ( @slice,
                            @slice1 )

            SET @PairColumn1 = RIGHT(@PairColumn1, Len(@PairColumn1) - @idx)
            SET @PairColumn2 = RIGHT(@PairColumn2, Len(@PairColumn2) - @idx1)

            IF Len(@PairColumn1) = 0
              BREAK
        END

      RETURN
  END;
  go
  


GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwTableID]';

GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'MFvwTableID', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.[VIEWS]
            WHERE   [VIEWS].[TABLE_NAME] = 'MFvwTableID'
                    AND [VIEWS].[TABLE_SCHEMA] = 'dbo' )
 BEGIN
    SET NOEXEC ON;
 END
GO
CREATE VIEW dbo.MFvwTableID
AS


       SELECT   [Column1] = 'UNDER CONSTRUCTION';
	GO
SET NOEXEC OFF;
	GO	
/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2018-2

-- Description:	Internally used view to regulate unique table names, used with fnMFVariableTableName
-- Revision History:  
-- YYYYMMDD Author - Description 
-- =============================================

*/		
ALTER VIEW dbo.MFvwTableID
AS

/*************************************************************************
STEP 
NOTES
*/

select newid() as new_id


GO

GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[MFvwClassTableColumns]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'MFvwClassTableColumns' -- nvarchar(100)
                                    ,@Object_Release = '4.2.7.46'           -- varchar(50)
                                    ,@UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[VIEWS]
    WHERE [TABLE_NAME] = 'MFvwClassTableColumns'
          AND [TABLE_SCHEMA] = 'dbo'
)
BEGIN
    SET NOEXEC ON;
END;
GO

CREATE VIEW [dbo].[MFvwClassTableColumns]
AS
SELECT [Column1] = 'UNDER CONSTRUCTION';
GO

SET NOEXEC OFF;
GO

/*
-- ============================================= 
-- Author: leRoux Cilliers, Laminin Solutions
-- Create date: 2018-11

-- Description:	Show nature of columns for class tables
-- Revision History:  
-- YYYYMMDD Author - Description 
-- =============================================
*/
ALTER VIEW [dbo].[MFvwClassTableColumns]
AS
SELECT TOP 1000
       [mc].[TableName]
      ,CASE
           WHEN [mp2].[MFID] > 100
                AND [mcp].[MFProperty_ID] IS NULL THEN
               'Alert'
           ELSE
               NULL
       END          AS [AdditionalProperty]
      ,[mp2].[Name] AS [Property]
      ,[sc].[name]  AS [TableColumn]
      ,CASE
           WHEN [mcp].[MFProperty_ID] IS NULL THEN
               'N'
           ELSE
               'Y'
       END          AS [OnmetadataCard]
      ,CASE
           WHEN [mp2].[MFID] > 100
                AND [mcp].[MFProperty_ID] IS NOT NULL THEN
               'Metadata Card Property'
           WHEN [mp2].[MFID] > 100
                AND [mcp].[MFProperty_ID] IS NULL THEN
               'Add hoc Property'
           WHEN [mp2].[MFID] < 101 THEN
               'MFSystem Property'
           WHEN [mp2].[Name] IS NULL
                AND [sc].[name] IN ( 'Process_id', 'Objid', 'ExternalID', 'MFVersion', 'FileCount' ) THEN
               'MFSQL System Property'
           WHEN [mp2].[Name] IS NULL
                AND [sc].[name] NOT IN ( 'Process_id', 'Objid', 'ExternalID', 'MFVersion', 'FileCount' ) THEN
               'Lookup Lable Column'
       END          AS [ColumnType]
      ,[Column_Datatype]   = [t].[name]
      ,[Length]     = [sc].[max_length]
	  ,[dt].[MFTypeID]
      ,[MFdatatype] = [dt].[Name]
      ,CASE
           WHEN [dt].[MFTypeID] = 10
                AND [t].[max_length] <> 8000 THEN
               'Datatype Error'
			WHEN [dt].[MFTypeID] = 9
                AND [t].[max_length] <> 4 THEN
               'Datatype Error'  
           ELSE
               NULL
       END          AS [DataType_Error]

--SELECT t.*
FROM [dbo].[MFClass]                  AS [mc]
    INNER JOIN [sys].[columns]        [sc]
        ON [sc].[object_id] = OBJECT_ID([mc].[TableName])
    INNER JOIN [sys].[types]          [t]
        ON [t].[user_type_id] = [sc].[user_type_id]
    LEFT JOIN [dbo].[MFProperty]      AS [mp2]
        ON [sc].[name] = [mp2].[ColumnName]
    LEFT JOIN [dbo].[MFDataType]      [dt]
        ON [mp2].[MFDataType_ID] = [dt].[ID]
    LEFT JOIN [dbo].[MFClassProperty] AS [mcp]
        ON [mcp].[MFClass_ID] = [mc].[ID]
           AND [mp2].[ID] = [mcp].[MFProperty_ID]
--LEFT JOIN [dbo].[MFClassProperty] AS [mcp2]
--ON mc.id = mcp.[MFClass_ID]
WHERE [mc].[IncludeInApp] IS NOT NULL
ORDER BY [mc].[TableName];
GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMissingobjectIds]';
go
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetMissingobjectIds', -- nvarchar(100)
    @Object_Release = '4.1.5.43', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go
/*
 Change history

  2016-8-22		LC		change objids to NVARCHAR(4000)
  2017-7-15		Dev2	increase size of objids to overcome cutting off of missing objects
  2017-7-25		LC		remove redundant variables
  2017-10-01	LC		fix bug with parameter sizes
  2018-8-3		LC		Prevent endless loop
*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetMissingobjectIds'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
CREATE PROCEDURE [dbo].[spMFGetMissingobjectIds]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do
go
-- the following section will be always executed
SET NOEXEC OFF;
go

alter PROCEDURE [dbo].[spMFGetMissingobjectIds]
    (
      @objIDs nVARCHAR(max) ,
      @MFtableName VARCHAR(200) ,
      @missing nvarchar(max) OUTPUT ,
	  @Debug SMALLINT = 0
    )

AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to getting the missing id from the class table as XML  
  **  
  ** Version: 2.0.0.1
  **
  ** Author:			Kishore
  ** Date:				25-05-2016

  ******************************************************************************/
  
  
    BEGIN

	DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFGetMissingobjectIds';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''

        --DECLARE @objId nVARCHAR(max);
        --DECLARE @objGuid nVARCHAR(max);
        --DECLARE @objTypeId nVARCHAR(max);
        DECLARE @missingIds nVARCHAR(max);
        DECLARE @retSTring nVARCHAR(max);
        DECLARE @position INT;
        DECLARE @length INT;
        DECLARE @value nVARCHAR(max);
        SET @objIDs = @objIDs  + ',';
        SET @missingIds = '';

        DECLARE @SelectQuery NVARCHAR(MAX);
        DECLARE @Missinglist NVARCHAR(MAX);

        DECLARE @ParmDefinition NVARCHAR(max);
        SET @ParmDefinition = N'@retvalOUT varchar(max) OUTPUT';

/*     SET @SelectQuery = '
select @retvalOUT = coalesce(@retvalOUT+ '','','''') + item from (
  SELECT item FROM dbo.fnMFSplitString(''' + @objIDs
            + ''','','') where item not in (select objid from ' + @tableName
            + ' )
  ) as k;';
     
--	 PRINT @SelectQuery
*/


SET @SelectQuery = 'select @retvalOUT = coalesce(@retvalOUT+ '','','''') + CAST(item AS varchar(10)) FROM (
  SELECT item FROM dbo.fnMFSplitString(''' + @objIDs + ''','','') WHERE item != 0
  EXCEPT SELECT objid FROM ' + @MFtableName +') k'
			
--			select @SelectQuery;

        EXEC sp_executesql @SelectQuery, @ParmDefinition,
            @retvalOUT = @MissingList OUTPUT;

Set @DebugText = ' missing %s'
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Objids '

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@MissingList );
	END

        SET @missingIds = @MissingList + ',';
 


        SET @position = 0;
        SET @length = 0;
        SET @retSTring = '';

		--SELECT @missingIds
		--SELECT CHARINDEX(',', @missingIds, @position + 1) AS value

		Begin
        WHILE CHARINDEX(',', @missingIds, @position + 1) > 0
            BEGIN
                SET @length = CHARINDEX(',', @missingIds, @position + 1)
                    - @position;
                SET @value = SUBSTRING(@missingIds, @position, @length);
                IF ( @value != '' )
                    SET @retSTring = @retSTring + '<objVers objectID='''
                        + @value + ''' version=''' + '-1'
                        + '''   objectGUID='''
                       +'{89CACFAE-E6B0-44EE-8F91-685A4A1D9E08}'+ ''' />';
                SET @position = CHARINDEX(',', @missingIds,
                                          @position + @length) + 1;
            END;
			END
--{89CACFAE-E6B0-44EE-8F91-685A4A1D9E08}
        SET @missing = @retSTring;


    END;


go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertClass]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertClass', -- nvarchar(100)
    @Object_Release = '4.2.7.46', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert Class details into MFClass table.  
  **  

  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 27-05-2015  DEV 2      INSERT/UPDATE logic changed
  ** 14-07-2015  DEV 2      MFValuelist_ID column removed from MFClass
  ** 20-07-2015  DEV 2	   TableName Duplicate Issue Resolved
  ** 19-03-2016  LC			No error for duplicate Report Class
  ** 26-03-2018	Dev2		Workflow required check
	2018-11-10	LC			Add includedinApp update for User Messager table
  ******************************************************************************/
 
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertClass'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertClass]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;

go

ALTER PROCEDURE [dbo].[spMFInsertClass]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT 
	)
AS
    SET NOCOUNT ON;
    BEGIN
        BEGIN TRY
            SET NOCOUNT ON;

            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'START Insert Classes' ,
                @ProcedureName sysname = 'spMFInsertClass' ,
                @XML XML = @Doc;
            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
		---------------------------------------------------
		--Check whether #ClassesTble already exists or not
		---------------------------------------------------
            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#ClassesTble' )
                BEGIN
                    DROP TABLE #ClassesTble;
                END;

		-----------------------------------------------
		--Create temporary table store data from XML
		-----------------------------------------------
            CREATE TABLE #ClassesTble
                (
                  [MFID] INT NOT NULL ,
                  [Name] VARCHAR(100) ,
                  [Alias] NVARCHAR(100) ,
                  [MFObjectType_ID] INT NOT NULL, --added not null for task 975
                  [MFWorkflow_ID] INT,
				  [IsWorkflowEnforced] BIT --added for task 1052
                );



            SELECT  @ProcedureStep = 'Insert values into #ClassesTble';
            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
		-----------------------------------------------
		-- INSERT DATA FROM XML INTO TABLE
		-----------------------------------------------     
            INSERT  INTO #ClassesTble
                    ( MFID ,
                      Name ,
                      Alias ,
                      MFObjectType_ID ,
                      MFWorkflow_ID,
					  IsWorkflowEnforced --added for task 1052
			        )
                    SELECT  t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@MFObjectType_ID)[1]', 'INT') AS MFObjectType_ID ,
                            t.c.value('(@MFWorkflow_ID)[1]', 'INT') AS MFWorkflow_ID,
							t.c.value('(@IsWorkflowEnforced)[1]', 'BIT') AS IsWorkflowEnforced --added for task 1052
                    FROM    @XML.nodes('/form/Class') AS t ( c );
            
			
            SELECT  @ProcedureStep = 'Store current MFClass records int #CurrentMFClass';
            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  *
                    --FROM    [#ClassesTble] AS [ct];
                END;

            DELETE  FROM [#ClassesTble]
            WHERE   MFID = -101; ---Special Report Class, this is not required in Connector

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  *
                    --FROM    [#ClassesTble] AS [ct];
                END;


            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#CurrentMFClass' )
                BEGIN
                    DROP TABLE #CurrentMFClass;
                END;

		------------------------------------------------------
		--Store present records in MFClass to #CurrentMFClass
		------------------------------------------------------
            SELECT  *
            INTO    #CurrentMFClass
            FROM    ( SELECT    *
                      FROM      MFClass
                      WHERE     MFID <> -101
                    ) mfc;

		
            SELECT  @ProcedureStep = 'DROP CONSTRAINT FROM MFClassProperty';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  *
                    --FROM    [#CurrentMFClass] AS [cmc];
                    --SELECT  *
                    --FROM    [dbo].[MFClassProperty] AS [mcp];
                    --SELECT  *
                    --FROM    [dbo].[MFClass] AS [mc];
                END;


            SELECT  @ProcedureStep = 'Update MFClassProperty';
            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;

		---------------------------------------------------------
		--Update the MFClassProperty.MFClass_ID with MFCLass.MFID
		---------------------------------------------------------
            UPDATE  MFClassProperty
            SET     MFClass_ID = MFClass.MFID
            FROM    MFClassProperty
                    INNER JOIN MFClass ON MFClass_ID = MFClass.ID
            WHERE   [MFClass].[MFID] <> -101;

            SELECT  @ProcedureStep = 'Delete records from MFClass';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                    --SELECT  *
                    --FROM    [#ClassesTble] AS [ct];
                    --SELECT  *
                    --FROM    [dbo].[MFClassProperty] AS [mcp]; 
                END;
		----------------------------------------------------
		--Delete records from MFClass
		----------------------------------------------------
            
			
	--		DELETE  FROM MFClass;

            SELECT  @ProcedureStep = 'Update MFID with PK ID';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;

		-----------------------------------------------------------------------
		--Update #ClassesTble with pkId of MFObjecttype,MFWorkFlow,MFValueList
		-----------------------------------------------------------------------
            UPDATE  #ClassesTble
            SET     MFObjectType_ID = ( SELECT  ID
                                        FROM    MFObjectType
                                        WHERE   MFID = MFObjectType_ID
                                      ) ,
                    MFWorkflow_ID = ( SELECT    ID
                                      FROM      MFWorkflow
                                      WHERE     MFID = MFWorkflow_ID
                                    );

            SELECT  @ProcedureStep = 'Insert Records into MFClass';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;

		------------------------------------------------
		--merge Records into MFClass
		------------------------------------------------

            MERGE INTO MFClass AS t
            USING
                ( SELECT    *
                  FROM      ( SELECT    MFID ,
                                        Name ,
                                        Alias ,
                                        'MF'
                                        + REPLACE(dbo.fnMFCapitalizeFirstLetter(Name),
                                                  ' ', '') AS TableName
				--Replacing ' ' and changing each words first letter to UPPERCASE					
                                        ,
                                        MFObjectType_ID ,
                                        MFWorkflow_ID ,
										IsWorkflowEnforced, --added for task 1052
                                        0 AS Deleted
                              FROM      #ClassesTble
                              WHERE     MFID <> -101
                            ) n
                ) AS s
            ON ( t.MFID = s.MFID )
			when Matched then                         --Added By Rheal
			  UPdate  set t.Alias=s.Alias,t.MFWorkflow_ID=s.MFWorkflow_ID, t.Name=s.Name,t.IsWorkflowEnforced=s.IsWorkflowEnforced --Added By Rheal
            WHEN NOT MATCHED BY TARGET THEN
                INSERT ( MFID ,
                         Name ,
                         Alias ,
                         TableName ,
                         MFObjectType_ID ,
                         MFWorkflow_ID ,
						 IsWorkflowEnforced, --added for task 1052
                         Deleted,
						 CreatedOn --Added for task 568
						-- ,ModifiedOn --Added for task 568
			           )
                VALUES ( s.MFID ,
                         s.Name ,
                         s.Alias ,
                         s.TableName ,
                         s.MFObjectType_ID ,
                         s.MFWorkflow_ID ,
						 IsWorkflowEnforced, --added for task 1052
                         s.Deleted,
						 Getdate()  --Added for task 568
						--,null  --Added for task 568
                       )
            WHEN NOT MATCHED BY SOURCE THEN
                DELETE;

    --                SELECT  *
    --                FROM    ( SELECT    MFID ,
    --                                    Name ,
    --                                    Alias ,
    --                                    'MF'
    --                                    + REPLACE(dbo.fnMFCapitalizeFirstLetter(Name),
    --                                              ' ', '') AS TableName
				----Replacing ' ' and changing each words first letter to UPPERCASE					
    --                                    ,
    --                                    MFObjectType_ID ,
    --                                    MFWorkflow_ID ,
    --                                    0 AS Deleted
    --                          FROM      #ClassesTble
    --                          WHERE     MFID <> -101
    --                        ) n;

            SELECT  @Output = @@ROWCOUNT;

            SELECT  @ProcedureStep = 'Update MFClass with Data from old table';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;
		---------------------------------------------------------------------
		--Update MFClass with TableName & IncludeInApp from Old table
		---------------------------------------------------------------------
            UPDATE  MFClass
            SET     TableName = #CurrentMFClass.TableName ,
                    IncludeInApp = #CurrentMFClass.IncludeInApp
            FROM    MFClass
                    INNER JOIN #CurrentMFClass ON MFClass.Name = #CurrentMFClass.Name;

			 
            SELECT  @ProcedureStep = 'Update MFCLassProperty with PK ID Delete not existing';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;
		-----------------------------------------------------------
		--Delete the records of Class which not exists in new vault
		-----------------------------------------------------------
            DELETE  FROM MFClassProperty
            WHERE   MFClass_ID NOT IN ( SELECT  MFID
                                        FROM    MFClass );
    
            SELECT  @ProcedureStep = 'Update MFClassProperty.MFclass_ID with MFClass.ID';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  Tablename = 'MFClassProperty' ,
                    --        *
                    --FROM    [dbo].[MFClassProperty] AS [mcp];
                END;
		
		-------------------------------------------------------------
		-- Update includeInApp for MFSQL Messages
		-------------------------------------------------------------
		DECLARE @DetailLogging NVARCHAR(5)
		SELECT @DetailLogging = CAST([Value] AS VARCHAR(5)) FROM mfsettings WHERE name = 'App_DetailLogging'
		IF @DetailLogging = '1'
		BEGIN
        UPDATE MFClass SET [IncludeInApp] = 1 WHERE name = 'User Messages'

		END
	

		
		-----------------------------------------------------
		--Update MFClassProperty.MFclass_ID with MFClass.ID
		-----------------------------------------------------
            UPDATE  MFClassProperty
            SET     MFClass_ID = MFClass.ID
            FROM    MFClassProperty
                    INNER JOIN MFClass ON MFClassProperty.MFClass_ID = MFClass.MFID
                                          AND MFClass.MFID <> -101;

            --SELECT  @ProcedureStep = 'ADD CONSTRAINT';

            --IF @Debug = 1
            --    BEGIN
            --        RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 

            --    END;

            SET @ProcedureStep = 'Check for duplicate Tablenames';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  t.TableName AS TableName
                    --FROM    dbo.MFClass t
                    --WHERE   t.Deleted = 0
                    --GROUP BY t.TableName
                    --HAVING  COUNT(t.TableName) > 1;
                END;

            IF @Debug = 1
                BEGIN
--				SELECT 'BeforeDuplicates',* FROM [dbo].[MFClass] AS [mc];
                    DECLARE @DupCount INT;
                    SELECT  @DupCount = COUNT(*)
                    FROM    ( SELECT    t.TableName AS TableName
                              FROM      dbo.MFClass t
                              WHERE     t.Deleted = 0
                              GROUP BY  t.TableName
                              HAVING    COUNT(t.TableName) > 1
                            ) m;
					
                    RAISERROR('%s : Step %s Count of duplicates %i',10,1,@ProcedureName,@ProcedureStep, @DupCount); 
                    
                END;

            IF OBJECT_ID('tempdb..#Duplicate01') IS NOT NULL
                DROP TABLE #Duplicate01;

            CREATE TABLE #Duplicate01
                (
                  [MFID] INT ,
                  [TableName] VARCHAR(100) ,
                  [Name] VARCHAR(100) ,
                  [RowNumber] INT
                );
				
            IF ( SELECT COUNT(*)
                 FROM   ( SELECT    t.TableName
                          FROM      dbo.MFClass t
                          WHERE     t.Deleted = 0
                          GROUP BY  t.TableName
                          HAVING    COUNT(t.TableName) > 1
                        ) m
               ) > 0
                BEGIN
                    INSERT  INTO #Duplicate01
                            SELECT  [Duplicate].[MFID] ,
                                    [Duplicate].[TableName] ,
                                    [Duplicate].[Name] ,
                                    [Duplicate].[RowNumber]
                            FROM    ( SELECT    mfp.MFID ,
                                                mfp.TableName ,
                                                mfp.Name ,
                                                ROW_NUMBER() OVER ( PARTITION BY mfp.TableName ORDER BY mfp.MFID DESC ) AS RowNumber
                                      FROM      dbo.MFClass mfp
                                      WHERE     mfp.TableName IN (
                                                SELECT  t.TableName
                                                FROM    dbo.MFClass t
                                                GROUP BY t.TableName
                                                HAVING  COUNT(t.TableName) > 1 )
                                    ) Duplicate;

                    DECLARE @ClassName NVARCHAR(128);

                    SELECT  @ProcedureStep = '#Duplicate list';

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                            --SELECT DISTINCT
                            --        *
                            --FROM    [#Duplicate01]; 
                        END;
                END;

			  ---------------------------------------------
			  --INSERT DUPLICATE DETAILS INTO MFLog TABLE
			  ---------------------------------------------

            SELECT  @ProcedureStep = 'Insert duplicate report into MFLog';

           
            IF @Debug = 1
                BEGIN
                    --SELECT  COUNT(*)
                    --FROM    #Duplicate01 AS [d];
                    RAISERROR('%s : Step %s ',10,1,@ProcedureName,@ProcedureStep);      
                END;

            IF ( SELECT COUNT(*)
                 FROM   #Duplicate01
               ) > 0
                BEGIN
             
                    DECLARE ClassNames CURSOR LOCAL
                    FOR
                        SELECT DISTINCT
                                Name
                        FROM    #Duplicate01; 

                    OPEN ClassNames;

			  --------------------------------------------------------------------------------
			  --CURSOR IS USED TO INORDER TO GET EMAIL NOTIFICATION FOR EACH NEW RECORD
			  --------------------------------------------------------------------------------
                    FETCH NEXT
			  FROM ClassNames
			  INTO @ClassName;

                    WHILE @@FETCH_STATUS = 0
                        BEGIN
				  -----------------------------------------
				  --INSERT INTO MFLog
				  -----------------------------------------
                            INSERT  INTO MFLog
                                    ( SPName ,
                                      ErrorMessage ,
                                      ProcedureStep
					                )
                            VALUES  ( 'spMFInsertClass' ,
                                      'More than one class found with name '
                                      + @ClassName
                                      + ' , Table name for the specified class is automatically renamed.' ,
                                      'Duplicate Table name'
					                );

                            FETCH NEXT
				  FROM ClassNames
				  INTO @ClassName;
                        END;

                    CLOSE ClassNames;

                    DEALLOCATE ClassNames;
                END;

--------------Update name of duplicates

            SELECT  @ProcedureStep = 'Update Name of duplicates';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                           
                END;

            IF ( SELECT COUNT(*)
                 FROM   #Duplicate01
               ) > 0
                BEGIN

                    UPDATE  mfp
                    SET     mfp.TableName = CASE WHEN ( ISNUMERIC(RIGHT(mfp.TableName,
                                                              1)) <> 0 )
                                                 THEN REPLACE(mfp.TableName,
                                                              RIGHT(mfp.TableName,
                                                              1),
                                                              CAST(CAST(RIGHT(mfp.TableName,
                                                              1) AS INT) + 1 AS NVARCHAR(10)))
                                                 ELSE mfp.TableName + '0'
                                                      + CAST(( SELECT
                                                              MAX(#Duplicate01.RowNumber)
                                                              - 1
                                                              FROM
                                                              #Duplicate01
                                                              WHERE
                                                              #Duplicate01.TableName = mfp.TableName
                                                             ) AS NVARCHAR(10)) --APPEND NUMBER LIKE TableName01
                                            END
                    FROM    dbo.MFClass mfp
                            INNER JOIN #Duplicate01 dp ON mfp.MFID = dp.MFID
                                                          AND dp.RowNumber = 1; --SELECT FIRST PROPERTY

                    DROP TABLE #Duplicate01;
                
                END;

--------------------Drop Temp tables

            SELECT  @ProcedureStep = 'Drop Temp Tables';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                           
                END;
                
            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#ClassesTble' )
                BEGIN
                    DROP TABLE #ClassesTble;
                END;

            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#CurrentMFClass' )
                BEGIN
                    DROP TABLE #CurrentMFClass;
                END;

            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#ClassesTble' )
                BEGIN
                    DROP TABLE #ClassesTble;
                END;

            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#CurrentMFClass' )
                BEGIN
                    DROP TABLE #CurrentMFClass;
                END;

            SELECT  @ProcedureStep = 'END Insert Classes';
            DECLARE @Result_Returned INT;
            SET @Result_Returned = 1;
            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s Return %i',10,1,@ProcedureName,@ProcedureStep, @Result_Returned);
                END;

            SET NOCOUNT ON;
            RETURN 1
        END TRY

        BEGIN CATCH
            IF @Debug = 1
                BEGIN
			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
                    INSERT  INTO MFLog
                            ( SPName ,
                              ErrorNumber ,
                              ErrorMessage ,
                              ErrorProcedure ,
                              ErrorState ,
                              ErrorSeverity ,
                              ErrorLine ,
                              ProcedureStep
				            )
                    VALUES  ( 'spMFCreateTable' ,
                              ERROR_NUMBER() ,
                              ERROR_MESSAGE() ,
                              ERROR_PROCEDURE() ,
                              ERROR_STATE() ,
                              ERROR_SEVERITY() ,
                              ERROR_LINE() ,
                              @ProcedureStep
				            );
                END;

            DECLARE @ErrNum INT = ERROR_NUMBER() ,
                @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
                @ErrSeverity INT = ERROR_SEVERITY() ,
                @ErrState INT = ERROR_STATE() ,
                @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
                @ErrLine INT = ERROR_LINE();

            SET NOCOUNT OFF;

            RAISERROR (
				@ErrMessage
				,@ErrSeverity
				,@ErrState
				,@ErrProcedure
				,@ErrState
				,@ErrMessage
				);
        END CATCH;
    END;

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertClassProperty]';
go

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFInsertClassProperty', -- nvarchar(100)
    @Object_Release = '3.1.2.39', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go
 /*
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 07-04-2015		DEV2	resolved synchronization issue (Bug 55)
	11-09-2017		LC		resolve issue with constraints
  ********************************************************************************

*/

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINE_NAME] = 'spMFInsertClassProperty'--name of procedure
                    AND [ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINE_SCHEMA] = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFInsertClassProperty]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertClassProperty]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert Class property details into MFClassProperty table.  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **        1. Insert data from XML into temperory data
  **		2. Update M-Files ID with primary key values
  **		3. Update the Class property details into MFClMFClassPropertyass
  **		4. INsert the new class property details
  **		5. If fullUpdate 
  **				Delete the class property details deleted from M-Files
  **
  ** Author:          Thejus T V
  ** Date:            27-03-2015
 
  ******************************************************************************/

  
    SET NOCOUNT ON;

    BEGIN TRY
          -----------------------------------------------------
          -- LOCAL VARIABLE DECLARATION
          -----------------------------------------------------
        DECLARE @IDoc INT ,
            @ProcedureStep sysname = 'START' ,
			@ProcedureName sysname = 'spMFInsertClassProperty',
            @XML XML = @Doc;


        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
            END;
   
             -----------------------------------------------------
          -- COPY CUSTOM DATA INTO TEMP TABLE

          -----------------------------------------------------    
		   SELECT  @ProcedureStep = 'Copy Custom data into temp table';

		   SELECT * INTO #TempClassProperty FROM MFClassProperty

             -----------------------------------------------------
          -- GET CLASS PROPERTY INFORMATION FROM M-FILES

          -----------------------------------------------------   	   
	   
	   
	    CREATE TABLE [#ClassProperty]
            (
              [MFClass_ID] INT ,
              [MFProperty_ID] INT ,
              [Required] BIT
			 
            );

        SELECT  @ProcedureStep = 'Inserting values into #ClassProperty';
        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
            END;
          --------------------------------------------------------------
          -- INSERT DATA FROM XML INTO TEMPORARY TABLE 
          --------------------------------------------------------------          
        INSERT  INTO [#ClassProperty]
                ( [MFClass_ID] ,
                  [MFProperty_ID] ,
                  [Required]
                )
                SELECT  [t].[c].[value]('(@classID)[1]', 'INT') AS [MFClass_ID] ,
                        [t].[c].[value]('(@PropertyID)[1]', 'INT') AS [MFProperty_ID] ,
                        [t].[c].[value]('(@Required)[1]', 'BIT') AS [Required]
                FROM    @XML.[nodes]('/form/ClassProperty') AS [t] ( [c] );

        SELECT  @ProcedureStep = 'Updating #ClassProperty with Required value from MFClassProperty';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  *
                FROM    [dbo].[MFClass] AS [mc]
                        FULL OUTER JOIN [dbo].[#ClassProperty] AS [mcp] ON [MFClass_ID] = [mc].[ID]
                        INNER JOIN [dbo].[MFProperty] AS [mp] ON [mp].[ID] = [mcp].[MFProperty_ID]; 
            END;
      
        SET @ProcedureStep = 'Updating #ClassProperty';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
            END;

        UPDATE  [#ClassProperty]
        SET     [MFClass_ID] = ( SELECT [ID]
                                 FROM   [MFClass]
                                 WHERE  [MFID] = [#ClassProperty].[MFClass_ID]
                               ) ,
                [MFProperty_ID] = ( SELECT  [ID]
                                    FROM    [MFProperty]
                                    WHERE   [MFID] = [#ClassProperty].[MFProperty_ID]
                                  );
       
        UPDATE  [#ClassProperty]
        SET     [#ClassProperty].[MFClass_ID] = 0
        WHERE   [#ClassProperty].[MFClass_ID] IS NULL; 
 
        SET @ProcedureStep = 'Inserting values into #ClassPpt';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  '#classProperty' ,
                        *
                FROM    [dbo].[MFClass] AS [mc]
                        FULL OUTER JOIN [dbo].[#ClassProperty] AS [mcp] ON [MFClass_ID] = [mc].[ID]
                        INNER JOIN [dbo].[MFProperty] AS [mp] ON [mp].[ID] = [mcp].[MFProperty_ID]; 
            END;
						      --          --------------------------------------------------------------
          --          ----Storing the difference into #tempNewObjectTypeTble 
          --          --------------------------------------------------------------
        SET @ProcedureStep = 'Storing the difference into #tempTbl';
        SELECT  *
        INTO    [#ClassPpt]
        FROM    ( SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [#ClassProperty].[Required]
                  FROM      [#ClassProperty]
                  EXCEPT
                  SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [MFClassProperty].[Required]
                  FROM      [MFClassProperty]
                ) [tempTbl];

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  '#ClassPpt ' ,
                        *
                FROM    [dbo].[MFClass] AS [mc]
                        FULL OUTER JOIN [dbo].[#ClassPpt] AS [mcp] ON [MFClass_ID] = [mc].[ID]
                        INNER JOIN [dbo].[MFProperty] AS [mp] ON [mp].[ID] = [mcp].[MFProperty_ID];
                SELECT  *
                FROM    [#ClassPpt]
                        LEFT JOIN [MFClassProperty] [cp] ON ( [cp].[MFClass_ID] = [#ClassPpt].[MFClass_ID]
                                                              AND [cp].[MFProperty_ID] = [#ClassPpt].[MFProperty_ID]
                                                            );
            END;

		------------------------------------------------------
		--Drop CONSTRAINT
		------------------------------------------------------
        SET @ProcedureStep = 'Drop CONSTRAINT';
        IF @debug  = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

        IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NOT NULL )
            BEGIN
                ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass];
            END;
		IF ( OBJECT_ID('FK_MFClassProperty_MFClass_ID', 'F') IS NOT NULL )
            BEGIN
                ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass_ID];
            END;

          --------------------------------------------------------
          --UPDATE EXISTING CLASS PROPERTY
          --------------------------------------------------------
        BEGIN TRY
            SET @ProcedureStep = 'update MFCLassProperty Required values';
            UPDATE  [MFClassProperty]
            SET     [MFClassProperty].[Required] = [#ClassPpt].[Required]
            FROM    [MFClassProperty] [cp]
                    INNER JOIN [#ClassPpt] ON ( [cp].[MFClass_ID] = [#ClassPpt].[MFClass_ID]
                                                AND [cp].[MFProperty_ID] = [#ClassPpt].[MFProperty_ID]
                                              );

  

            IF @debug  = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    
                END;
        END TRY
        BEGIN CATCH
            RAISERROR('%s : Step %s Failed',16,1,@ProcedureName,@ProcedureStep);

        END CATCH;
          

		  --------------------------------------------------------------
          --Adding The new property 
          --------------------------------------------------------------
        BEGIN TRY
            SET @ProcedureStep = 'insert new items into MFCLassProperty';  
            INSERT  INTO [MFClassProperty]
                    ( [MFClass_ID] ,
                      [MFProperty_ID] ,
                      [Required]
                    )
                    SELECT  *
                    FROM    ( SELECT    [MFClass_ID] ,
                                        [MFProperty_ID] ,
                                        [Required]
                              FROM      [#ClassProperty]
                              EXCEPT
                              SELECT    [MFClass_ID] ,
                                        [MFProperty_ID] ,
                                        [Required]
                              FROM      [MFClassProperty]
                            ) [newPprty];
            SET @Output = @Output + @@ROWCOUNT;
            IF @debug  = 1
                BEGIN
               
                    IF ( @isFullUpdate = 1 )
                        SET @ProcedureStep = @ProcedureStep + ' Full Update';
					
                    RAISERROR('%s : Step %s inserting %i rows',10,1,@ProcedureName,@ProcedureStep, @Output); 

                END;      
        END TRY
        BEGIN CATCH 
            RAISERROR('%s : Step %s Failed',16,1,@ProcedureName,@ProcedureStep);
        END CATCH;
                --------------------------------------------------------------
                -- Select MFID Which are deleted from M-Files 
                --------------------------------------------------------------
        SET @ProcedureStep = 'Deletes objects from MFCLassProperty';
        SELECT  [MFClass_ID] ,
                [MFProperty_ID] ,
                [Required]
        INTO    [#DeletedObjectTypes]
        FROM    ( SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [Required]
                  FROM      [MFClassProperty]
                  EXCEPT
                  SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [Required]
                  FROM      [#ClassProperty]
                ) [#DeletedWorkFlowStates];

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  '#DeletedObjectTypes' ,
                        *
                FROM    [#DeletedObjectTypes]; 
            END;
    
                --------------------------------------------------------------
                --Deleting the Classproperty Thats deleted from M-Files 
                --------------------------------------------------------------

        DELETE  FROM [MFClassProperty]
        WHERE   [MFProperty_ID] IN ( SELECT [MFProperty_ID]
                                     FROM   [#DeletedObjectTypes] )
                AND [MFClass_ID] IN ( SELECT    [MFClass_ID]
                                      FROM      [#DeletedObjectTypes] );


              --------------------------------------------------------------
                --Deleting the system Class for Reporting from ClassProperty 
                --------------------------------------------------------------
        SET @ProcedureStep = 'Delete Report Class from MFCLassProperty';
        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  'Report Class Deleted' ,
                        *
                FROM    [dbo].[MFClassProperty] AS [mcp]; 
            END;

   IF (SELECT count(mfclass_ID) FROM MFClassProperty WHERE MFClass_ID = 0) > 0
        DELETE  FROM [MFClassProperty]
        WHERE   [MFClass_ID] = 0;

	 
	 
	 
	      --------------------------------------------------------------
          --Droping all temperory Table 
          --------------------------------------------------------------
        DROP TABLE [#TempClassProperty]
		DROP TABLE [#ClassProperty];

	
        SELECT  @ProcedureStep = 'END Insert ClassProperty Properties';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s Return 1',10,1,@ProcedureName,@ProcedureStep);
            END;     

        SET NOCOUNT OFF;

        RETURN 1;
    END TRY
    BEGIN CATCH

        SET NOCOUNT ON;


        BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
            INSERT  INTO [MFLog]
                    ( [SPName] ,
                      [ErrorNumber] ,
                      [ErrorMessage] ,
                      [ErrorProcedure] ,
                      [ErrorState] ,
                      [ErrorSeverity] ,
                      [ErrorLine] ,
                      [ProcedureStep]
                    )
            VALUES  ( @ProcedureName ,
                      ERROR_NUMBER() ,
                      ERROR_MESSAGE() ,
                      ERROR_PROCEDURE() ,
                      ERROR_STATE() ,
                      ERROR_SEVERITY() ,
                      ERROR_LINE() ,
                      @ProcedureStep
                    );
        END;

        DECLARE @ErrNum INT = ERROR_NUMBER() ,
            @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
            @ErrSeverity INT = ERROR_SEVERITY() ,
            @ErrState INT = ERROR_STATE() ,
            @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
            @ErrLine INT = ERROR_LINE();

        SET NOCOUNT OFF;

        RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
    END CATCH;
	go
    
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertLoginAccount]';
go
 

SET NOCOUNT ON; 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertLoginAccount', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 /*
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
	2017-8-22	lc			Add insert/update of userID as MFID column
  ** ----------  ---------  -----------------------------------------------------
  ** */
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertLoginAccount'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertLoginAccount]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertLoginAccount]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert Login Account details into MFLoginAccount table.  

  ** Date:            26-05-2015

  ******************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

            DECLARE @IDoc INT ,
                @ProcedureStep NVARCHAR(128) = 'START' ,
                @XML XML = @Doc;
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertLoginAccount';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

            CREATE TABLE #LoginAccountTble
                (
                  [UserName] VARCHAR(250) NOT NULL ,
                  [AccountName] VARCHAR(250) ,
                  [FullName] VARCHAR(250) ,
                  [AccountType] VARCHAR(250) ,
                  [EmailAddress] VARCHAR(250) ,
                  [DomainName] VARCHAR(250) ,
                  [LicenseType] VARCHAR(250) ,
                  [Enabled] BIT,
				  [UserID] int 

                );

            SELECT  @ProcedureStep = 'Insert values into #LoginAccountTble from XML';

          -----------------------------------------------------------------------
          -- INSERT DATA FROM XML INTO TABLE
          -----------------------------------------------------------------------          
            INSERT  INTO #LoginAccountTble
                    ( UserName ,
                      AccountName ,
                      FullName ,
                      AccountType ,
                      EmailAddress ,
                      DomainName ,
                      LicenseType ,
                      [Enabled],
					  UserID
                    )
                    SELECT  t.c.value('(@UserName)[1]', 'NVARCHAR(250)') AS UserName ,
                            t.c.value('(@AccountName)[1]', 'NVARCHAR(250)') AS AccountName ,
                            t.c.value('(@FullName)[1]', 'NVARCHAR(250)') AS FullName ,
                            t.c.value('(@AccountType)[1]', 'NVARCHAR(250)') AS AccountType ,
                            t.c.value('(@EmailAddress)[1]', 'NVARCHAR(250)') AS EmailAddress ,
                            t.c.value('(@DomainName)[1]', 'NVARCHAR(250)') AS DomainName ,
                            t.c.value('(@LicenseType)[1]', 'NVARCHAR(250)') AS LicenseType ,
                            t.c.value('(@Enabled)[1]', 'BIT') AS [Enabled],
							t.c.value('(@UserID)[1]', 'int') AS [UserID]
                    FROM    @XML.nodes('/form/loginAccount') AS t ( c );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                    --SELECT  *
                    --FROM    #LoginAccountTble;
                END;

         
            SELECT  @ProcedureStep = 'Insert values into #DifferenceTable';

          -----------------------------------------------------------------------
          --Storing the difference into #DifferenceTable 
          -----------------------------------------------------------------------
            SELECT  *
            INTO    #DifferenceTable
            FROM    ( SELECT    UserName ,
                                AccountName ,
                                FullName ,
                                AccountType ,
                                EmailAddress ,
                                DomainName ,
                                LicenseType ,
                                [Enabled],
								UserID
                      FROM      #LoginAccountTble
                      EXCEPT
                      SELECT    UserName COLLATE DATABASE_DEFAULT ,
                                AccountName COLLATE DATABASE_DEFAULT ,
                                FullName COLLATE DATABASE_DEFAULT,
                                AccountType COLLATE DATABASE_DEFAULT,
                                EmailAddress COLLATE DATABASE_DEFAULT,
                                DomainName COLLATE DATABASE_DEFAULT,
                                LicenseType COLLATE DATABASE_DEFAULT,
                                [Enabled] ,
								MFID
                      FROM      MFLoginAccount
                    ) tempTbl;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                    --SELECT  *
                    --FROM    #DifferenceTable;
                END;

            SELECT  @ProcedureStep = 'Creating #NewLoginAccountTble';

          -----------------------------------------------------------------------
          --Creatting new table to store the updated property details 
          -----------------------------------------------------------------------
            CREATE TABLE #NewLoginAccountTble
                (
                  [UserName] VARCHAR(250) NOT NULL ,
                  [AccountName] VARCHAR(250) ,
                  [FullName] VARCHAR(250) ,
                  [AccountType] VARCHAR(250) ,
                  [EmailAddress] VARCHAR(250) ,
                  [DomainName] VARCHAR(250) ,
                  [LicenseType] VARCHAR(250) ,
                  [Enabled] BIT,
				  UserID int
                );

            SELECT  @ProcedureStep = 'Insert values into #NewLoginAccountTble';

          -----------------------------------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------------------------------
            INSERT  INTO #NewLoginAccountTble
                    SELECT  *
                    FROM    #DifferenceTable;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    #NewLoginAccountTble;
                END;

            SELECT  @ProcedureStep = 'Update MFLoginAccount';

          -----------------------------------------------------------------------
          --Updating the MFProperties 
          -----------------------------------------------------------------------
            IF OBJECT_ID('tempdb.dbo.#NewLoginAccountTble') IS NOT NULL
                BEGIN
                    UPDATE  MFLoginAccount
                    SET     MFLoginAccount.FullName = #NewLoginAccountTble.FullName ,
                            MFLoginAccount.AccountName = #NewLoginAccountTble.AccountName ,
                            MFLoginAccount.AccountType = #NewLoginAccountTble.AccountType ,
                            MFLoginAccount.DomainName = #NewLoginAccountTble.DomainName ,
                            MFLoginAccount.EmailAddress = #NewLoginAccountTble.EmailAddress ,
                            MFLoginAccount.LicenseType = #NewLoginAccountTble.LicenseType ,
                            MFLoginAccount.[Enabled] = #NewLoginAccountTble.[Enabled],
							 MFLoginAccount.[MFID] = #NewLoginAccountTble.[UserID]
                    FROM    MFLoginAccount
                            INNER JOIN #NewLoginAccountTble ON MFLoginAccount.UserName COLLATE DATABASE_DEFAULT = #NewLoginAccountTble.UserName;

                    SELECT  @Output = @@ROWCOUNT;
                END;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    MFLoginAccount;
                END;

            SELECT  @ProcedureStep = 'Create #MFLoginAccount Table';

            CREATE TABLE #MFLoginAccount
                (
                  [UserName] VARCHAR(250) NOT NULL ,
                  [AccountName] VARCHAR(250) ,
                  [FullName] VARCHAR(250) ,
                  [AccountType] VARCHAR(250) ,
                  [EmailAddress] VARCHAR(250) ,
                  [DomainName] VARCHAR(250) ,
                  [LicenseType] VARCHAR(250) ,
                  [Enabled] BIT,
				  UserID int 
                );

            SELECT  @ProcedureStep = 'Inserting values into #MFLoginAccount';

          -----------------------------------------------------------------------
          --Adding The new property 
          -----------------------------------------------------------------------
            INSERT  INTO #MFLoginAccount
                    SELECT  *
                    FROM    ( SELECT    UserName  ,
                                        AccountName ,
                                        FullName ,
                                        AccountType ,
                                        EmailAddress ,
                                        DomainName ,
                                        LicenseType ,
                                        [Enabled],
										UserID
                              FROM      #LoginAccountTble
                              EXCEPT
                              SELECT    UserName ,
                                        AccountName ,
                                        FullName ,
                                        AccountType ,
                                        EmailAddress COLLATE DATABASE_DEFAULT,
                                        DomainName COLLATE DATABASE_DEFAULT,
                                        LicenseType COLLATE DATABASE_DEFAULT,
                                        [Enabled] ,
										MFID 
                              FROM      MFLoginAccount
                            ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    #MFLoginAccount;
                END;

            SELECT  @ProcedureStep = 'Inserting values into MFLoginAccount';

            INSERT  INTO MFLoginAccount
                    ( UserName ,
                      AccountName ,
                      FullName ,
                      AccountType ,
                      EmailAddress ,
                      DomainName ,
                      LicenseType ,
                      [Enabled],
					  MFID	
                    )
                    SELECT  *
                    FROM    ( SELECT    UserName ,
                                        AccountName ,
                                        FullName ,
                                        AccountType ,
                                        EmailAddress ,
                                        DomainName ,
                                        LicenseType ,
                                        [Enabled] AS Deleted,
										UserID
                              FROM      #MFLoginAccount
                            ) n;

            SELECT  @Output = @Output + @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    MFLoginAccount;
                END;

            IF ( @isFullUpdate = 1 )
                BEGIN
                    SELECT  @ProcedureStep = 'Full update';

                -----------------------------------------------------------------------
                -- Select UserName Which are deleted from M-Files 
                -----------------------------------------------------------------------
                    SELECT  UserName
                    INTO    #DeletedLoginAccount
                    FROM    ( SELECT    UserName
                              FROM      MFLoginAccount
                              EXCEPT
                              SELECT    UserName
                              FROM      #LoginAccountTble
                            ) DeletedUserName;

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                            --SELECT  *
                            --FROM    #DeletedLoginAccount;
                        END;

                    SELECT  @ProcedureStep = 'DELETE FROM MFLoginAccount';

                -----------------------------------------------------------------------
                --Deleting the MFClass Thats deleted from M-Files 
                -----------------------------------------------------------------------
                    UPDATE  MFLoginAccount
                    SET     Deleted = 1
                    WHERE   UserName COLLATE DATABASE_DEFAULT IN ( SELECT    UserName
                                          FROM      #DeletedLoginAccount );
                END;

          -----------------------------------------
          --Droping all temperory Table 
          ----------------------------------------- 
            DROP TABLE #LoginAccountTble;

            DROP TABLE #NewLoginAccountTble;

            DROP TABLE #MFLoginAccount;

            SELECT  @Output = @@ROWCOUNT;

            SET NOCOUNT OFF;

            COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
            ROLLBACK TRANSACTION;

            SET NOCOUNT ON;

            IF @Debug = 1
                BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                    INSERT  INTO MFLog
                            ( SPName ,
                              ErrorNumber ,
                              ErrorMessage ,
                              ErrorProcedure ,
                              ErrorState ,
                              ErrorSeverity ,
                              ErrorLine ,
                              ProcedureStep
                            )
                    VALUES  ( 'spMFCreateTable' ,
                              ERROR_NUMBER() ,
                              ERROR_MESSAGE() ,
                              ERROR_PROCEDURE() ,
                              ERROR_STATE() ,
                              ERROR_SEVERITY() ,
                              ERROR_LINE() ,
                              @ProcedureStep
                            );
                END;

            DECLARE @ErrNum INT = ERROR_NUMBER() ,
                @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
                @ErrSeverity INT = ERROR_SEVERITY() ,
                @ErrState INT = ERROR_STATE() ,
                @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
                @ErrLine INT = ERROR_LINE();

            SET NOCOUNT OFF;

            RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
        END CATCH;
    END;

go
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFInsertObjectType]';
go
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFInsertObjectType', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFInsertObjectType'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertObjectType]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF
go

ALTER PROCEDURE [dbo].[spMFInsertObjectType] (@Doc           NVARCHAR(max)
                                               ,@isFullUpdate BIT
                                               ,@Output       INT OUTPUT
                                               ,@Debug        SMALLINT = 0)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert objectType details into MFobjectType table.  
  **  

  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 
  ******************************************************************************/
  BEGIN
      BEGIN TRY
          BEGIN TRANSACTION

          SET NOCOUNT ON

          -----------------------------------------------
          --LOCAL VARIABLE DECLARATION
          -----------------------------------------------
          DECLARE @IDoc         INT
                  ,@ProcedureStep SYSNAME = 'Start'
                  ,@XML         XML = @Doc

          SET @ProcedureStep = 'Creating #ObjectTypeTble'

          CREATE TABLE #ObjectTypeTble
            (
               [Name]   VARCHAR(100)
               ,[Alias] NVARCHAR(100)
               ,[MFID]  INT NOT NULL
            )

          SET @ProcedureStep = 'Insert values into #ObjectTypeTble'
 DECLARE @procedureName NVARCHAR(128) = 'spMFInsertObjectType';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------
          -- INSERT DAT FROM XML INTO TEMPORARY TABLE
          -----------------------------------------------
          INSERT INTO #ObjectTypeTble
                      (NAME,
                       Alias,
                       MFID)
          SELECT t.c.value('(@Name)[1]', 'NVARCHAR(100)')   AS NAME
                 ,t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias
                 ,t.c.value('(@MFID)[1]', 'INT')            AS MFID
          FROM   @XML.nodes('/form/objectType')AS t(c)

          IF @Debug = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #ObjectTypeTble
            END

          SET @ProcedureStep = 'Insert values into #objectTypes'

          -----------------------------------------------------
          --Storing the difference into #tempNewObjectTypeTble 
          -----------------------------------------------------
          SELECT *
          INTO   #ObjectTypes
          FROM   ( SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   #ObjectTypeTble
                   EXCEPT
                   SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   MFObjectType ) tempTbl

          IF @Debug = 1
            BEGIN
                 RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #ObjectTypes
            END

          SET @ProcedureStep = 'Creating new table #NewObjectTypes'

          ------------------------------------------------------------
          --Creating new table to store the updated ObjectType details 
          ------------------------------------------------------------
          CREATE TABLE #NewObjectTypes
            (
               [Name]   VARCHAR(100)--COLLATE Latin1_General_CI_AS
               ,[Alias] NVARCHAR(100)--COLLATE Latin1_General_CI_AS
               ,[MFID]  INT NOT NULL
            )

          SET @ProcedureStep = 'Inserting values into #NewObjectTypes'

          -----------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------
          INSERT INTO #NewObjectTypes
          SELECT *
          FROM   #ObjectTypes

          IF @Debug = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #NewObjectTypes
            END

          SET @ProcedureStep = 'Inserting values into MFObjectType'

          -----------------------------------------------
          --Updating the MFObjectType 
          -----------------------------------------------
          IF Object_id('tempdb..#NewObjectTypes') IS NOT NULL
            BEGIN
                UPDATE MFObjectType
                SET    MFObjectType.NAME = #NewObjectTypes.NAME,
                       MFObjectType.Alias = #NewObjectTypes.Alias,
                       MFObjectType.Deleted = 0,
					   MFObjectType.ModifiedOn=getdate()  --Added for task 568
                FROM   MFObjectType
                       INNER JOIN #NewObjectTypes
                               ON MFObjectType.MFID = #NewObjectTypes.MFID

                SET @Output = @@ROWCOUNT
            END

          IF @Debug = 1
            BEGIN
            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFObjectType
            END

          SET @ProcedureStep = 'Inserting values into #temp'

          -----------------------------------------------
          --Adding The new property 	
          -----------------------------------------------
          SELECT *
          INTO   #temp
          FROM   ( SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   #ObjectTypeTble
                   EXCEPT
                   SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   MFObjectType ) newPprty

          IF @Debug = 1
            BEGIN
              RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #temp
            END

          SET @ProcedureStep = 'Inserting values into MFObjectType'

          -----------------------------------------------
          -- INSERT NEW OBJECT TYPE DETAILS
          -----------------------------------------------
          INSERT INTO MFObjectType
                      (NAME,
                       Alias,
                       MFID,
                       Deleted,
					   CreatedOn --Added for task 568
					   
					   )
          SELECT NAME
                 ,Alias
                 ,MFID
                 ,0 AS Deleted
				 ,getdate() --Added for task 568
          FROM   #temp

          SET @Output = @Output + @@ROWCOUNT

          IF ( @isFullUpdate = 1 )
            BEGIN
                SET @ProcedureStep = 'Full update'

                -----------------------------------------------
                -- Select MFID Which are deleted from M-Files 
                -----------------------------------------------
                SELECT MFID
                INTO   #DeletedObjectTypes
                FROM   ( SELECT MFID
                         FROM   MFObjectType
                         EXCEPT
                         SELECT MFID
                         FROM   #ObjectTypeTble ) #DeletedWorkFlowStates

                IF @Debug = 1
                  BEGIN
                     RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                      --SELECT *
                      --FROM   #DeletedObjectTypes
                  END

                SET @ProcedureStep = 'updating MFObjectTypes'

                -----------------------------------------------------
                --Deleting the ObjectTypes Thats deleted from M-Files
                ------------------------------------------------------ 
                UPDATE MFObjectType
                SET    DELETED = 1
                WHERE  MFID IN ( SELECT MFID
                                 FROM   #DeletedObjectTypes )
            END

          -----------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------
          DROP TABLE #ObjectTypeTble

          DROP TABLE #NewObjectTypes

          SET NOCOUNT OFF

          COMMIT TRANSACTION
      END TRY

      BEGIN CATCH
          ROLLBACK TRANSACTION

          SET NOCOUNT ON

          IF @Debug = 1
            BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                INSERT INTO MFLog
                            (SPName,
                             ErrorNumber,
                             ErrorMessage,
                             ErrorProcedure,
                             ErrorState,
                             ErrorSeverity,
                             ErrorLine,
                             ProcedureStep)
                VALUES      ('spMFInsertObjectType',
                             Error_number(),
                             Error_message(),
                             Error_procedure(),
                             Error_state(),
                             Error_severity(),
                             Error_line(),
                             @ProcedureStep)
            END

          DECLARE @ErrNum        INT = Error_number()
                  ,@ErrProcedure NVARCHAR(100) =Error_procedure()
                  ,@ErrSeverity  INT = Error_severity()
                  ,@ErrState     INT = Error_state()
                  ,@ErrMessage   NVARCHAR(MAX) = Error_message()
                  ,@ErrLine      INT = Error_line()

          SET NOCOUNT OFF

          RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
      END CATCH
  END

go
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFInsertProperty]';
GO


SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFInsertProperty' -- nvarchar(100)
  , @Object_Release = '4.2.7.46'		-- varchar(50)
  , @UpdateFlag = 2;
-- smallint

GO
/*
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -------------------------------------------------------------
  ** 15-05-2015  Dev 2	   Checking for duplicate ColumnName and auto renaming if exists
  ** 27-05-2015  Dev 2	   New logic for inserting details from M-Files as per LeRoux
  ** 14-07-2015  DEV 2      MFValuelist_ID column Added in MFProperty
	2017-08-22		LC		fix bug with contstraints
	2017-08-22		LC		improve logging  
	2017-09-11		LC		update constraints
	2017-11-23		LC		Localization of last modifed columns
	2017-11-30		LC		Remove duplicate _ID from State_ID
	2017-12-28      Dev2            Change join condition at #1162
	2018-11-4		lc		enhancement to deal with changes in datatype
	**********************************************************************************
*/
IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFInsertProperty' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFInsertProperty]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFInsertProperty]
	(
		@Doc		  NVARCHAR(MAX)
	  , @isFullUpdate BIT
	  , @Output		  NVARCHAR(50) OUTPUT
	  , @Debug		  SMALLINT	   = 0
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert Property details into MFProperty table.  
  **  

  ** Date:            27-03-2015
*****/
	BEGIN
		DECLARE @trancount INT;
		SET @trancount = @@trancount;
		BEGIN TRY
			IF @trancount = 0 BEGIN TRANSACTION;
			ELSE SAVE TRANSACTION [spMFInsertProperty];


			SET NOCOUNT ON;

		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''

			-----------------------------------------------------------
			-- DECLARING LOCAL VARIABLE
			-----------------------------------------------------------
			DECLARE
				@IDoc		   INT
			  , @RowAdded	   INT
			  , @RowUpdated	   INT
			  , @ProcedureStep sysname = 'Start'
			  , @ProcedureName sysname = 'spMFInsertProperty'
			  , @XML		   XML	   = @Doc
			  , @Return_Value  INT;

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			SET @ProcedureStep = 'Create #Properties Table';

			---------------------------------------------------
			--Check whether #Properties already exists or not
			---------------------------------------------------
			IF EXISTS ( SELECT	* FROM	[sysobjects] WHERE	[name] = '#Properties' )
				BEGIN
					DROP TABLE [#Properties];
				END;

			-----------------------------------------------------------
			--CREATING TEMPORARY TABLE TO STORE DATA FROM XML
			-----------------------------------------------------------
			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			CREATE TABLE [#Properties]
				(
					[Name]					VARCHAR(100)
				  , [Alias]					VARCHAR(100)
				  , [MFID]					INT			NOT NULL
				  , [MFDataType_ID]			VARCHAR(100)
				  , [MFValueList_ID]		INT
				  , [PredefinedOrAutomatic] BIT
				);

			IF @Debug > 0
				BEGIN
					SET @ProcedureStep = 'Inserting Values into #Properties';
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;

			IF @Debug > 10
			SELECT @XML;

			-----------------------------------------------------------
			--INSERTING DATA FROM XML TO TEMPORARY TABLE
			-----------------------------------------------------------
			INSERT INTO [#Properties] ( [Name]
									  , [Alias]
									  , [MFID]
									  , [MFDataType_ID]
									  , [MFValueList_ID]
									  , [PredefinedOrAutomatic]
									  )
						SELECT
								[t].[c].[value]('(@Name)[1]', 'NVARCHAR(100)')			AS [NAME]
							  , [t].[c].[value]('(@Alias)[1]', 'NVARCHAR(100)')			AS [Alias]
							  , [t].[c].[value]('(@MFID)[1]', 'INT')					AS [MFID]
							  , [t].[c].[value]('(@MFDataType_ID)[1]', 'NVARCHAR(100)') AS [MFDataType_ID]
							  , [t].[c].[value]('@valueListID[1]', 'INT')				AS [MFValueList_ID]
							  , [t].[c].[value]('(@Predefined)[1]', 'BIT')				AS [PredefinedOrAutomatic]
						FROM	@XML.[nodes]('/form/Property') AS [t]([c]);

			SELECT	@ProcedureStep = 'Store current MFProperty records int #CurrentMFProperty';
			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;

			IF @Debug > 10
			SELECT * FROM [#Properties] AS [p];

			IF EXISTS (	  SELECT	[sysobjects].[name]
						  FROM		[sysobjects]
						  WHERE		[name] = '#CurrentMFProperty'
					  )
				BEGIN
					DROP TABLE [#CurrentMFProperty];
				END;

			------------------------------------------------------
			--Store present records in MFProperty to #CurrentMFProperty
			------------------------------------------------------
			SELECT
					[mfc].[ID]
				  , [mfc].[Name]
				  , [mfc].[Alias]
				  , [mfc].[MFID]
				  , [mfc].[ColumnName]
				  , [mfc].[MFDataType_ID]
				  , [mfc].[PredefinedOrAutomatic]
				  , [mfc].[ModifiedOn]
				  , [mfc].[CreatedOn]
				  , [mfc].[Deleted]
				  , [mfc].[MFValueList_ID]
			INTO	[#CurrentMFProperty]
			FROM	(
						SELECT
								[MFProperty].[ID]
							  , [MFProperty].[Name]
							  , [MFProperty].[Alias]
							  , [MFProperty].[MFID]
							  , [MFProperty].[ColumnName]
							  , [MFProperty].[MFDataType_ID]
							  , [MFProperty].[PredefinedOrAutomatic]
							  , [MFProperty].[ModifiedOn]
							  , [MFProperty].[CreatedOn]
							  , [MFProperty].[Deleted]
							  , [MFProperty].[MFValueList_ID]
						FROM	[MFProperty]
					) AS [mfc];

			SELECT	@ProcedureStep = 'DROP CONSTAINT FROM MFClassProperty';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			------------------------------------------------------
			--Drop CONSTRAINT
			------------------------------------------------------
				DECLARE @Constraint NVARCHAR(100)
					   ,@SQL        NVARCHAR(MAX);
				DECLARE @ConstraintList AS TABLE ([ConstraintName] NVARCHAR(100));
				INSERT INTO @ConstraintList
				(
					[ConstraintName]
				)
				SELECT OBJECT_NAME([object_id]) AS [ConstraintName]
				FROM [sys].[objects]
				WHERE [type_desc] LIKE 'FOREIGN_KEY_CONSTRAINT'
					  AND OBJECT_NAME([parent_object_id]) = 'MFClassProperty';

				WHILE EXISTS (SELECT * FROM @ConstraintList AS [cl])
				BEGIN

					SELECT TOP 1
						@Constraint = [ConstraintName]
					FROM @ConstraintList AS [cl];

					SET @SQL = N' ALTER TABLE [MFClassProperty] DROP CONSTRAINT ' + @Constraint;
					EXEC (@SQL);

					DELETE FROM @ConstraintList
					WHERE [ConstraintName] = @Constraint;

				END;

			SELECT	@ProcedureStep = 'Update MFClassProperty';

			IF @Debug > 0 
							BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			---------------------------------------------------------
			--Update the MFClassProperty.MFProperty_ID with MFProperty.MFID
			---------------------------------------------------------
			--SELECT * FROM    MFClassProperty
			--                 INNER JOIN MFProperty ON MFProperty_ID = MFProperty.ID;
			UPDATE	[MFClassProperty]
			SET		[MFProperty_ID] = [MFProperty].[MFID]
			FROM	[MFClassProperty]
					INNER JOIN [MFProperty] ON [MFProperty_ID] = [MFProperty].[ID];

			SELECT	@ProcedureStep = 'Delete records from MFProperty';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;

-------------------------------------------------------------
-- validate changes to mfdatatype
-------------------------------------------------------------
SET @ProcedureStep = 'Validate datatype changes'
DECLARE @RowCount int
DECLARE @DataTypeChanges
AS TABLE (MFID INT, MFTypeID int)

INSERT INTO @DataTypeChanges
(
    [MFID]
   ,[MFTypeID]
)
SELECT MFID, mdt.id FROM [#Properties] AS [p]
INNER JOIN [dbo].[MFDataType] AS [mdt]
ON p.[MFDataType_ID]= mdt.[Name]
WHERE mfid > 1000
EXCEPT 
SELECT cmp.MFID, cmp.[MFDataType_ID] FROM [#CurrentMFProperty] AS [cmp]
WHERE mfid > 1000

IF @debug > 0
BEGIN
SELECT * FROM @DataTypeChanges AS [dtc]
--raiserror('Databatypes changed', 16,1 )
END
			----------------------------------------------------
			--Delete records from MFProperty
			----------------------------------------------------
			DELETE	FROM [MFProperty];

			SELECT	@ProcedureStep = 'Update MFID with PK ID';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			-----------------------------------------------------------
			--Selecting MFDataType ID Depending Upon Property DataType
			-----------------------------------------------------------
			UPDATE	[#Properties]
			SET		[MFDataType_ID] = ( SELECT	[ID] FROM	[MFDataType] WHERE	[Name] = [#Properties].[MFDataType_ID] );

			----Bug #1162
			UPDATE	[#Properties]
			SET		[MFValueList_ID] = [MFV].[ID]
			FROM	[#Properties]			AS [tmp]
					LEFT JOIN [MFValueList] AS [MFV] ON [tmp].[MFValueList_ID] = [MFV].[MFID]
														AND [Deleted] = 0;

			SELECT	@ProcedureStep = 'Insert Records into MFProperty';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			IF @Debug > 10
			SELECT * FROM [#Properties] AS [p];



			------------------------------------------------
			--Insert Records into MFProperty
			------------------------------------------------
			CREATE TABLE [#MFProperty01]
				(
					[Name]					VARCHAR(100)	--COLLATE Latin1_General_CI_AS
				  , [Alias]					VARCHAR(100)	--COLLATE Latin1_General_CI_AS NOT NULL
				  , [MFID]					INT			 NOT NULL
				  , [ColumnName]			NVARCHAR(250)
				  , [MFDataType_ID]			INT
				  , [MFValueList_ID]		INT
				  , [PredefinedOrAutomatic] BIT
				  , [Deleted]				BIT
				);

			------------------------------------------------
			--Insert New records into Temp table
			------------------------------------------------
			INSERT INTO [#MFProperty01] ( [Name]
										, [Alias]
										, [MFID]
										, [ColumnName]
										, [MFDataType_ID]
										, [MFValueList_ID]
										, [PredefinedOrAutomatic]
										, [Deleted]
										)
						SELECT	*
						FROM	(
									SELECT
											[Name]
										  , [Alias]
										  , [MFID]
										  , CASE WHEN (	  SELECT	[MFTypeID]
														  FROM		[MFDataType]
														  WHERE		[ID] = [MFDataType_ID]
													  ) = 9 THEN [dbo].[fnMFReplaceSpecialCharacter]([Name]) + '_ID'
																								  --REMOVING SPECIAL CHARACTER AND IF DATATYPE IS MFLOOKUP,APPENDING '_ID' TO PROPERTY NAME
												 WHEN (	  SELECT	[MFTypeID]
														  FROM		[MFDataType]
														  WHERE		[ID] = [MFDataType_ID]
													  ) = 10 THEN [dbo].[fnMFReplaceSpecialCharacter]([Name]) + '_ID'
																								  --REMOVING SPECIAL CHARACTER AND IF DATATYPE IS MFMULTISELECTLOOKUP,APPENDING '_ID' TO PROPERTY NAME
												 ELSE [dbo].[fnMFReplaceSpecialCharacter]([Name]) --REMOVING SPECIAL CHARACTER AND 
											END					   AS [ColumnName]
										  , [MFDataType_ID]
										  , [MFValueList_ID]
										  , [PredefinedOrAutomatic]
										  , 0					   AS [Deleted]
									FROM	[#Properties]
								) AS [n];

			------------------------------------------------
			--Check for Duplicate ColumnName,If duplicate 
			--values exists append auto numbering
			------------------------------------------------
			WHILE (	  SELECT	COUNT(*)
					  FROM		(	SELECT		[t].[ColumnName]
									FROM		[#MFProperty01] AS [t]
									GROUP BY	[t].[ColumnName]
									HAVING		COUNT([t].[ColumnName]) > 1
								) AS [m]
				  ) > 0
				BEGIN
					SELECT	*
					INTO	[#Duplicate]
					FROM	(
								SELECT
										[mfp].[MFID]
									  , [mfp].[ColumnName]
									  , ROW_NUMBER() OVER ( PARTITION BY [mfp].[ColumnName]
															ORDER BY [mfp].[MFID] DESC
														  ) AS [RowNumber]
								FROM	[#MFProperty01] AS [mfp]
								WHERE	[mfp].[ColumnName] IN (	  SELECT	[t].[ColumnName]
																  FROM		[#MFProperty01] AS [t]
																  GROUP BY	[t].[ColumnName]
																  HAVING	COUNT([t].[ColumnName]) > 1
															  )
							) AS [Duplicate];

					UPDATE
							[mfp]
					SET
							[mfp].[ColumnName] = [mfp].[ColumnName] + '0'
												 + CAST((	SELECT	MAX([#Duplicate].[RowNumber]) - 1
															FROM	[#Duplicate]
															WHERE	[#Duplicate].[ColumnName] = [mfp].[ColumnName]
														) AS NVARCHAR(10)) --APPEND NUMBER LIKE Property01
					FROM	[#MFProperty01]			AS [mfp]
							INNER JOIN [#Duplicate] AS [dp] ON [mfp].[MFID] = [dp].[MFID]
															   AND [dp].[RowNumber] = 1; --SELECT FIRST PROPERTY

					DROP TABLE [#Duplicate];
				END;

			---------------------------------------------
			--Insert Records into MFProperty
			---------------------------------------------
			INSERT INTO [MFProperty] ( [Name]
									 , [Alias]
									 , [MFID]
									 , [ColumnName]
									 , [MFDataType_ID]
									 , [MFValueList_ID]
									 , [PredefinedOrAutomatic]
									 , [Deleted]
									 )
						SELECT	*
						FROM	(
									SELECT
											[Name]
										  , [Alias]
										  , [MFID]
										  , [ColumnName]
										  , [MFDataType_ID]
										  , [MFValueList_ID]
										  , [PredefinedOrAutomatic]
										  , [Deleted]
									FROM	[#MFProperty01]
								) AS [new];

			SELECT	@Output = @@ROWCOUNT;

			SELECT	@ProcedureStep = 'Update MFProperty with Data from old table';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			UPDATE	[MFProperty]
			SET		[ColumnName] = 'MF_' + ColumnName
			WHERE	[MFID] = 21;

			UPDATE	[MFProperty]
			SET		[ColumnName] = 'MF_' + ColumnName
			WHERE	[MFID] = 23;

	--		UPDATE	[MFProperty] SET [ColumnName] = ColumnName + '_ID' WHERE [MFID] = 39;



			SELECT	@ProcedureStep = 'Update columnNames from previous';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;

			---------------------------------------------------------------------
			--Update MFProperty with ColumnName from Old table
			---------------------------------------------------------------------
			UPDATE	[MFProperty]
			SET		[ColumnName] = [#CurrentMFProperty].[ColumnName]
			FROM	[MFProperty]
					INNER JOIN [#CurrentMFProperty] ON [MFProperty].[Name] = [#CurrentMFProperty].[Name];

			------------------------------------------------
			--Check for Duplicate ColumnName,If duplicate 
			--values exists append auto numbering
			------------------------------------------------

			SELECT	@ProcedureStep = 'Check for duplicates';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;


			WHILE (	  SELECT	COUNT(*)
					  FROM		(	SELECT		[t].[ColumnName]
									FROM		[dbo].[MFProperty] AS [t]
									GROUP BY	[t].[ColumnName]
									HAVING		COUNT([t].[ColumnName]) > 1
								) AS [m]
				  ) > 0
				BEGIN
					SELECT	*
					INTO	[#Duplicate01]
					FROM	(
								SELECT
										[mfp].[MFID]
									  , [mfp].[ColumnName]
									  , ROW_NUMBER() OVER ( PARTITION BY [mfp].[ColumnName]
															ORDER BY [mfp].[MFID] DESC
														  ) AS [RowNumber]
								FROM	[dbo].[MFProperty] AS [mfp]
								WHERE	[mfp].[ColumnName] IN (	  SELECT	[t].[ColumnName]
																  FROM		[dbo].[MFProperty] AS [t]
																  GROUP BY	[t].[ColumnName]
																  HAVING	COUNT([t].[ColumnName]) > 1
															  )
							) AS [Duplicate];

					UPDATE
							[mfp]
					SET
							[mfp].[ColumnName] = CASE WHEN ( ISNUMERIC(RIGHT([mfp].[ColumnName], 1)) <> 0 ) THEN
														   REPLACE(
																	  [mfp].[ColumnName]
																	, RIGHT([mfp].[ColumnName], 1)
																	, CAST(CAST(RIGHT([mfp].[ColumnName], 1) AS INT) + 1 AS NVARCHAR(10))
																  )
													  ELSE [mfp].[ColumnName] + '0'
														   + CAST((
																	  SELECT	MAX([#Duplicate01].[RowNumber]) - 1
																	  FROM		[#Duplicate01]
																	  WHERE		[#Duplicate01].[ColumnName] = [mfp].[ColumnName]
																  ) AS NVARCHAR(10)) --APPEND NUMBER LIKE Property01
												 END
					FROM	[dbo].[MFProperty]		  AS [mfp]
							INNER JOIN [#Duplicate01] AS [dp] ON [mfp].[MFID] = [dp].[MFID]
																 AND   [dp].[RowNumber] = 1; --SELECT FIRST PROPERTY

					DROP TABLE [#Duplicate01];
				END;


			SELECT	@ProcedureStep = 'Update MFCLassProperty with PK ID';;

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
				END;
			-----------------------------------------------------------
			--Delete the records of Property which not exists in new vault
			-----------------------------------------------------------
			DELETE	FROM [MFClassProperty]
			WHERE	[MFProperty_ID] NOT IN ( SELECT [MFID] FROM [MFProperty] );

			-----------------------------------------------------
			--Update MFClassProperty.MFclass_ID with MFProperty.ID
			-----------------------------------------------------
			UPDATE	[MFClassProperty]
			SET		[MFProperty_ID] = [MFProperty].[ID]
			FROM	[MFClassProperty]
					INNER JOIN [MFProperty] ON [MFClassProperty].[MFProperty_ID] = [MFProperty].[MFID];

			SELECT	@ProcedureStep = 'ADD CONSTRAINT';

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
					SELECT	*
					FROM	[dbo].[MFClassProperty]		 AS [CP]
							LEFT JOIN [dbo].[MFProperty] AS [mp] ON [mp].[ID] = [CP].[MFProperty_ID];
				END;
	-------------------------------------------------------------
	-- update required in mfclass property
	-------------------------------------------------------------
			--------------------------------------------
			--	Add CONSTRAINT to [dbo].[MFClassProperty]
			--------------------------------------------
				BEGIN TRY

			Set @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Adding constraint for MFClassProperty'
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END
			
			   IF ( OBJECT_ID('FK_MFClassProperty_MFClass_ID', 'F') IS NULL )
                     BEGIN
					
							ALTER TABLE [dbo].[MFClassProperty]
						ADD CONSTRAINT [FK_MFClassProperty_MFClass_ID]
							FOREIGN KEY ( [MFClass_ID])
							REFERENCES [dbo].[MFClass](ID) 

					END
				
				 IF ( OBJECT_ID('FK_MFClassProperty_MFProperty_ID', 'F') IS NULL )
                     BEGIN			
								ALTER TABLE [dbo].[MFClassProperty]
						ADD CONSTRAINT [FK_MFClassProperty_MFProperty_ID]
							FOREIGN KEY ( [MFProperty_ID])
							REFERENCES [dbo].[MFProperty](ID) 
						END

			END TRY
			BEGIN CATCH
				SET @Return_Value = 2;
				RAISERROR('Adding constraint FK_MFClassProperty_MFProperty could not be resolved', 16, 1);

			END CATCH;


			IF EXISTS ( SELECT	* FROM	[sysobjects] WHERE	[name] = '#Properties' )
				BEGIN
					DROP TABLE [#Properties];
				END;

			IF EXISTS ( SELECT	* FROM	[sysobjects] WHERE	[name] = '#CurrentMFProperty' )
				BEGIN
					DROP TABLE [#CurrentMFProperty];
				END;

			SET @Output = CAST(ISNULL(@RowAdded,0) + ISNULL(@RowUpdated,0) AS VARCHAR(100)) ;

			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
					SELECT @Output AS [output]
				END;

			SELECT	@ProcedureStep = 'END Insert Properties';
			IF @Return_Value IS NULL SET @Return_Value = 1;
			IF @Debug > 0
				BEGIN
					RAISERROR('%s : Step %s Return %i', 10, 1, @ProcedureName, @ProcedureStep, @Return_Value);
				END;

			IF @trancount = 0 COMMIT;
			RETURN 1;
			SET NOCOUNT OFF;

		END TRY
		BEGIN CATCH

			IF XACT_STATE() = -1 ROLLBACK;
			IF XACT_STATE() = 1 AND @trancount = 0 ROLLBACK;
			IF XACT_STATE() = 1
			   AND	@trancount > 0
				ROLLBACK TRANSACTION [spMFInsertProperty];

			SET NOCOUNT ON;

			IF @Debug > 0
				BEGIN
					--------------------------------------------------
					-- INSERTING ERROR DETAILS INTO LOG TABLE
					--------------------------------------------------
					INSERT INTO [MFLog] ( [SPName]
										, [ErrorNumber]
										, [ErrorMessage]
										, [ErrorProcedure]
										, [ErrorState]
										, [ErrorSeverity]
										, [ErrorLine]
										, [ProcedureStep]
										)
					VALUES (
							   'spMFInsertProperty'
							 , ERROR_NUMBER()
							 , ERROR_MESSAGE()
							 , ERROR_PROCEDURE()
							 , ERROR_STATE()
							 , ERROR_SEVERITY()
							 , ERROR_LINE()
							 , @ProcedureStep
						   );
				END;

			DECLARE
				@ErrNum		  INT			= ERROR_NUMBER()
			  , @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE()
			  , @ErrSeverity  INT			= ERROR_SEVERITY()
			  , @ErrState	  INT			= ERROR_STATE()
			  , @ErrMessage	  NVARCHAR(MAX) = ERROR_MESSAGE()
			  , @ErrLine	  INT			= ERROR_LINE();

			SET NOCOUNT OFF;

			RAISERROR(@ErrMessage, @ErrSeverity, @ErrState, @ErrProcedure, @ErrState, @ErrMessage);
			RETURN -1;
		END CATCH;
	END;

GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertUserAccount]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertUserAccount', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertUserAccount'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertUserAccount]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go
ALTER PROCEDURE [dbo].[spMFInsertUserAccount]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert user account details into MFUserAccount table.  
  **  

  ** Date:            26-05-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 
  ******************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

          -----------------------------------------------
          --LOCAL VARIABLE DECLARATION
          -----------------------------------------------
            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'Start' ,
                @XML XML = @Doc;

            SET @ProcedureStep = 'Creating #UserAccountTble';
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertUserAccount';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

            CREATE TABLE #UserAccountTble
                (
                  [LoginName] VARCHAR(100) ,
                  [UserID] INT NOT NULL ,
                  [InternalUser] BIT ,
                  [Enabled] BIT
                );

            SET @ProcedureStep = 'Insert values into #UserAccountTble';

          -----------------------------------------------
          -- INSERT DAT FROM XML INTO TEMPORARY TABLE
          -----------------------------------------------
            INSERT  INTO #UserAccountTble
                    ( LoginName ,
                      UserID ,
                      InternalUser ,
                      [Enabled]
                    )
                    SELECT  t.c.value('(@LoginName)[1]', 'NVARCHAR(100)') AS LoginName ,
                            t.c.value('(@MFID)[1]', 'INT') AS UserID ,
                            t.c.value('(@InternalUser)[1]', 'BIT') AS InternalUser ,
                            t.c.value('(@Enabled)[1]', 'BIT') AS [Enabled]
                    FROM    @XML.nodes('/form/UserAccount') AS t ( c );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    #UserAccountTble;
                END;

            SET @ProcedureStep = 'Insert values into #UserAccountTble';

          -----------------------------------------------------
          --Storing the difference into #tempNewUserAccountTble
          -----------------------------------------------------
            SELECT  *
            INTO    #UserAccount
            FROM    ( SELECT    LoginName ,
                                UserID ,
                                InternalUser ,
                                [Enabled]
                      FROM      #UserAccountTble
                      EXCEPT
                      SELECT    LoginName ,
                                UserID ,
                                InternalUser ,
                                [Enabled]
                      FROM      MFUserAccount
                    ) tempTbl;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    #UserAccount;
                END;

            SET @ProcedureStep = 'Creating new table #NewUserAccount';

          ------------------------------------------------------------
          --Creating new table to store the updated ObjectType details 
          ------------------------------------------------------------
            CREATE TABLE #NewUserAccount
                (
                  [LoginName] VARCHAR(100) ,
                  [UserID] INT NOT NULL ,
                  [InternalUser] BIT ,
                  [Enabled] BIT
                );

            SET @ProcedureStep = 'Inserting values into #NewUserAccount';

          -----------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------
            INSERT  INTO #NewUserAccount
                    SELECT  *
                    FROM    #UserAccount;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                    --SELECT  *
                    --FROM    #NewUserAccount;
                END;

            SET @ProcedureStep = 'Inserting values into MFUserAccount';

          -----------------------------------------------
          --Updating the MFUserAccount 
          -----------------------------------------------
            IF OBJECT_ID('tempdb..#NewUserAccount') IS NOT NULL
                BEGIN
                    UPDATE  MFUserAccount
                    SET     MFUserAccount.LoginName = #NewUserAccount.LoginName ,
                            MFUserAccount.UserID = #NewUserAccount.UserID ,
                            MFUserAccount.InternalUser = #NewUserAccount.InternalUser ,
                            MFUserAccount.[Enabled] = #NewUserAccount.[Enabled]
                    FROM    MFUserAccount
                            INNER JOIN #NewUserAccount ON MFUserAccount.UserID = #NewUserAccount.UserID;

                    SET @Output = @@ROWCOUNT;
                END;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    MFUserAccount;
                END;

            SET @ProcedureStep = 'Inserting values into #temp';

          -----------------------------------------------
          --Adding The new property 	
          -----------------------------------------------
            SELECT  *
            INTO    #temp
            FROM    ( SELECT    LoginName ,
                                UserID ,
                                InternalUser ,
                                [Enabled]
                      FROM      #UserAccountTble
                      EXCEPT
                      SELECT    LoginName ,
                                UserID ,
                                InternalUser ,
                                [Enabled]
                      FROM      MFUserAccount
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    #temp;
                END;

            SET @ProcedureStep = 'Inserting values into MFUserAccount';

          -----------------------------------------------
          -- INSERT NEW OBJECT TYPE DETAILS
          -----------------------------------------------
            INSERT  INTO MFUserAccount
                    ( LoginName ,
                      UserID ,
                      InternalUser ,
                      [Enabled]
                    )
                    SELECT  LoginName ,
                            UserID ,
                            InternalUser ,
                            [Enabled]
                    FROM    #temp;

            SET @Output = @Output + @@ROWCOUNT;

            IF ( @isFullUpdate = 1 )
                BEGIN
                    SET @ProcedureStep = 'Full update';

                -----------------------------------------------
                -- Select UserID Which are deleted from M-Files 
                -----------------------------------------------
                    SELECT  UserID
                    INTO    #DeletedUserAccount
                    FROM    ( SELECT    UserID
                              FROM      MFUserAccount
                              EXCEPT
                              SELECT    UserID
                              FROM      #UserAccountTble
                            ) #DeletedWorkFlowStates;

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                            --SELECT  *
                            --FROM    #DeletedUserAccount;
                        END;

                    SET @ProcedureStep = 'updating MFUserAccounts';

                -----------------------------------------------------
                --Deleting the ObjectTypes Thats deleted from M-Files
                ------------------------------------------------------ 
                    UPDATE  MFUserAccount
                    SET     Deleted = 1
                    WHERE   UserID IN ( SELECT  UserID
                                        FROM    #DeletedUserAccount );
                END;

          -----------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------
            DROP TABLE #UserAccountTble;

            DROP TABLE #NewUserAccount;

            SET NOCOUNT OFF;

            COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
            ROLLBACK TRANSACTION;

            SET NOCOUNT ON;

            IF @Debug = 1
                BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                    INSERT  INTO MFLog
                            ( SPName ,
                              ErrorNumber ,
                              ErrorMessage ,
                              ErrorProcedure ,
                              ErrorState ,
                              ErrorSeverity ,
                              ErrorLine ,
                              ProcedureStep
                            )
                    VALUES  ( 'spMFInsertUserAccount' ,
                              ERROR_NUMBER() ,
                              ERROR_MESSAGE() ,
                              ERROR_PROCEDURE() ,
                              ERROR_STATE() ,
                              ERROR_SEVERITY() ,
                              ERROR_LINE() ,
                              @ProcedureStep
                            );
                END;

            DECLARE @ErrNum INT = ERROR_NUMBER() ,
                @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
                @ErrSeverity INT = ERROR_SEVERITY() ,
                @ErrState INT = ERROR_STATE() ,
                @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
                @ErrLine INT = ERROR_LINE();

            SET NOCOUNT OFF;

            RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
        END CATCH;
    END;

go
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertValueListItems]';
go

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertValueListItems', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
go
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertValueListItems'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertValueListItems]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go
ALTER PROCEDURE [dbo].[spMFInsertValueListItems]
    (
      @Doc NVARCHAR(MAX) ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert ValueList Items details into MFValueListItems table.  
  **  
  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 26-06-2015  DEV 2	   Updating Column appRef
  ******************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

		-----------------------------------------------------
		--DECLARE LOCAL VARIABLE
		-----------------------------------------------------
            DECLARE @idoc INT ,
                @RowUpdated INT ,
                @RowAdded INT ,
                @MFValueListID INT ,
                @ProcedureStep sysname = 'Start' ,
                @XML XML = @Doc;

            SELECT  @ProcedureStep = 'Creating #ValueListItemTemp';
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertValueListItems';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
		-----------------------------------------------------
		--CREATE TEMPORARY TABLE STORE DATA IN XML
		-----------------------------------------------------
            CREATE TABLE #ValueListItemTemp (
			[Name] VARCHAR(100) --COLLATE Latin1_General_CI_AS
			,[MFID] VARCHAR(20) --COLLATE Latin1_General_CI_AS
			,[MFValueListID] INT
			,[OwnerID] INT
			,[DisplayID] nvarchar(200)
			,ItemGUID nvarchar(200)
			)

            SELECT  @ProcedureStep = 'Inserting value into #ValueListItemTemp from XML';

		-----------------------------------------------------
		--INSERT DATA FROM XML INTO TEMPORARY TABLE
		-----------------------------------------------------
            INSERT INTO #ValueListItemTemp (
			NAME
			,MFValueListID
			,MFID
			,OwnerID
			,DisplayID
			,ItemGUID
			)
		SELECT t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME
			,t.c.value('(@MFValueListID)[1]', 'INT') AS MFValueListID
			,t.c.value('(@MFID)[1]', 'INT') AS MFID
			,t.c.value('(@Owner)[1]', 'INT') AS OwnerID
			,t.c.value('(@DisplayID)[1]','nvarchar(200)')
			,t.c.value('(@ItemGUID)[1]','nvarchar(200)')
		FROM @XML.nodes('/VLItem/ValueListItem') AS t(c)

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
			

			--SELECT *
			--FROM #ValueListItemTemp
                END;

            SELECT  @ProcedureStep = 'Updating #ValueListItemTemp with ID of MFValuelist';

		-----------------------------------------------------
		--UPDATE #ValueListItemTemp WITH FK ID
		-----------------------------------------------------
            UPDATE  #ValueListItemTemp
            SET     MFValueListID = ( SELECT    ID
                                      FROM      MFValueList
                                      WHERE     MFID = #ValueListItemTemp.MFValueListID
                                    );

            SELECT  @MFValueListID = ( SELECT DISTINCT
                                                MFValueListID
                                       FROM     #ValueListItemTemp
                                     );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM #ValueListItemTemp
                END;

            SELECT  @ProcedureStep = 'Inserting values into #DifferenceTable';

		-----------------------------------------------------
		--Storing the difference into #tempDifferenceTable 
		-----------------------------------------------------
            SELECT  *
            INTO    #DifferenceTable
            FROM    ( SELECT    Name ,
                                MFID ,
                                MFValueListID ,
                                OwnerID,
								DisplayID,			    
								ItemGUID
                      FROM      #ValueListItemTemp
                      EXCEPT
                      SELECT    Name ,
                                MFID ,
                                MFValueListID ,
                                OwnerID,
								DisplayID,			    
								ItemGUID
                      FROM      MFValueListItems
                    ) tempTbl;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM #DifferenceTable
                END;

            SELECT  @ProcedureStep = 'Creating new table to store the updated property details';

		-------------------------------------------------------------
		--CREATE TEMPORARY TABLE TO STORE NEW VALUELIST ITEMS DETAILS
		--------------------------------------------------------------
            CREATE TABLE #NewValueListItems
                (
                  [Name] VARCHAR(100) --COLLATE Latin1_General_CI_AS
                  ,
                  [MFID] VARCHAR(20) --COLLATE Latin1_General_CI_AS
                  ,
                  [MFValueListID] INT ,
                  OwnerID INT,
				  [DisplayID] nvarchar(200),
			      ItemGUID nvarchar(200)
                );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                END;

            SELECT  @ProcedureStep = 'Inserting values into #NewValueListItems from #DifferenceTable';

		-----------------------------------------------------
		--Inserting the Difference 
		-----------------------------------------------------
            INSERT  INTO #NewValueListItems
                    SELECT  *
                    FROM    #DifferenceTable;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM #NewValueListItems
                END;

            SELECT  @ProcedureStep = 'Updating values into MFValueListItems with #NewValueListItems ';

		-----------------------------------------------------
		--Updating the MFProperties 
		-----------------------------------------------------
            IF OBJECT_ID('tempdb.dbo.#NewValueListItems') IS NOT NULL
                BEGIN

				  /*Added for Task 1160*/
				    UPDATE  MFValueListItems
                    SET     MFValueListItems.IsNameUpdate = 1
                    FROM    MFValueListItems
                            INNER JOIN #NewValueListItems ON MFValueListItems.MFID = #NewValueListItems.MFID
                                                             AND MFValueListItems.MFValueListID = #NewValueListItems.MFValueListID
															 AND MFValueListItems.Name != #NewValueListItems.Name;
				/*Added for Task 1160*/

                    UPDATE  MFValueListItems
                    SET     MFValueListItems.MFValueListID = #NewValueListItems.MFValueListID ,
                            MFValueListItems.MFID = #NewValueListItems.MFID ,
                            MFValueListItems.Name = #NewValueListItems.Name ,
                            MFValueListItems.OwnerID = #NewValueListItems.OwnerID ,
                            MFValueListItems.Deleted = 0,
							MFValueListItems.DisplayID= #NewValueListItems.DisplayID,
				            MFValueListItems.ItemGUID=#NewValueListItems.ItemGUID,
				            MFValueListItems.Process_ID=0,
							MFValueListItems.ModifiedOn=getdate()  --Added for Task 568
                    FROM    MFValueListItems
                            INNER JOIN #NewValueListItems ON MFValueListItems.MFID = #NewValueListItems.MFID
                                                             AND MFValueListItems.MFValueListID = #NewValueListItems.MFValueListID;

                    SELECT  @RowUpdated = @@ROWCOUNT;
                END;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM MFValueListItems
			--INNER JOIN #NewValueListItems ON MFValueListItems.MFID = #NewValueListItems.MFID
			--	AND MFValueListItems.MFValueListID = #NewValueListItems.MFValueListID
                END;

            SELECT  @ProcedureStep = 'Updating values into #temp';

		-----------------------------------------------------
		--Adding The new property 	
		-----------------------------------------------------
            SELECT  *
            INTO    #temp
            FROM    ( SELECT    Name ,
                                MFID ,
                                MFValueListID ,
                                OwnerID,
								DisplayID ,
								ItemGUID 
                      FROM      #ValueListItemTemp
                      EXCEPT
                      SELECT    Name ,
                                MFID ,
                                MFValueListID ,
                                OwnerID,
								DisplayID ,
								ItemGUID 
                      FROM      MFValueListItems
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM #temp
                END;

            SELECT  @ProcedureStep = 'Inserting new values into MFValueListItems';

		-----------------------------------------------------
		-- INSERT NEW VALUE LIST ITEMS DETAILS 
		-----------------------------------------------------
            INSERT  INTO MFValueListItems
                    ( Name ,
                      MFID ,
                      MFValueListID ,
                      OwnerID ,
                      Deleted ,
					  DisplayID, 
					  ItemGUID ,
					  Process_ID,
					  CreatedOn  --Added Task 568
			        )
                    SELECT  Name ,
                            MFID ,
                            MFValueListID ,
                            OwnerID ,
                            0,
							DisplayID, 
					        ItemGUID ,
					        0,
							Getdate() --Added Task 568
                    FROM    #temp;

            SELECT  @RowAdded = @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM MFValueListItems
                END;

		--------------------------------------------------------------
		--CREATING TEMPORARY TABLE TO STORE DELETED VALUELIST ITEMS ID
		--------------------------------------------------------------
            CREATE TABLE #DeletedValueListItems
                (
                  [MFID] VARCHAR(20) --COLLATE Latin1_General_CI_AS
                  ,
                  [MFValueListID] INT ,
                  [OwnerID] INT
                );

            SELECT  @ProcedureStep = 'Inserting Values into #DeletedValueListItems';

		-------------------------------------------------------
		-- Select ValueListItems Which are deleted from M-Files
		------------------------------------------------------- 
            INSERT  INTO #DeletedValueListItems
                    SELECT  *
                    FROM    ( SELECT    MFID ,
                                        MFValueListID ,
                                        OwnerID
                              FROM      MFValueListItems
                              WHERE     MFValueListID = @MFValueListID
                              EXCEPT
                              SELECT    MFID ,
                                        MFValueListID ,
                                        OwnerID
                              FROM      #ValueListItemTemp
                            ) deleted;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM #DeletedValueListItems
                END;

            SELECT  @ProcedureStep = 'Updating MFValueListItems with deleted items';

		---------------------------------------------------------
		--Deleting the ValueListItems Thats deleted from M-Files 
		---------------------------------------------------------
            UPDATE  MFValueListItems
            SET     Deleted = 1
            WHERE   MFID IN ( SELECT    MFID
                              FROM      #DeletedValueListItems )
                    AND MFValueListID IN ( SELECT   MFValueListID
                                           FROM     #DeletedValueListItems );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

			--SELECT *
			--FROM #DeletedValueListItems
                END;

            SELECT  @ProcedureStep = 'Updating MFValueListItems with deleted = 1,for deleted valueLists';

		-----------------------------------------------------------------------
		--UPDATING MFValueListItems WITH DELETED = 1, FOR DELETED VALUE LIST
		-----------------------------------------------------------------------
            UPDATE  MFValueListItems
            SET     Deleted = 1
            WHERE   MFValueListID IN ( SELECT   ID
                                       FROM     MFValueList
                                       WHERE    Deleted = 1 );

		-----------------------------------------------------
		--Droping all temperory Table 
		-----------------------------------------------------
            DROP TABLE #ValueListItemTemp;

            DROP TABLE #NewValueListItems;

            DROP TABLE #DeletedValueListItems;

            SELECT  @ProcedureStep = 'Updating appRef';

		-----------------------------------------------------
		--Updating AppRef and Owner_AppRef
		-----------------------------------------------------
            UPDATE  mvli
            SET     AppRef = CASE WHEN mvl.OwnerID = 7 THEN '0#'
                                  WHEN mvl.OwnerID = 0 THEN '2#'
                                  WHEN mvl.OwnerID IN ( SELECT
                                                              MFID
                                                        FROM  MFValueList )
                                  THEN '2#'
                                  ELSE '1#'
                             END + CAST(mvl.MFID AS NVARCHAR(5)) + '#'
                    + CAST(mvli.MFID AS NVARCHAR(10)) ,
                    Owner_AppRef = CASE WHEN mvl.OwnerID = 7 THEN '0#'
                                        WHEN mvl.OwnerID = 0 THEN '2#'
                                        WHEN mvl.OwnerID IN ( SELECT
                                                              MFID
                                                              FROM
                                                              MFValueList )
                                        THEN '2#'
                                        ELSE '1#'
                                   END + CAST(mvl.OwnerID AS NVARCHAR(5))
                    + '#' + CAST(mvli.OwnerID AS NVARCHAR(10))
            FROM    [dbo].[MFValueListItems] AS [mvli]
                    INNER JOIN [dbo].[MFValueList] AS [mvl] ON [mvl].[ID] = [mvli].[MFValueListID]
            WHERE   mvli.AppRef IS NULL
                    OR mvli.Owner_AppRef IS NULL;

            SELECT  @Output = @RowAdded + @RowUpdated;

            SET NOCOUNT OFF;

            COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
            ROLLBACK TRANSACTION;

            SET NOCOUNT ON;

            IF @Debug = 1
                BEGIN
			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
                    INSERT  INTO MFLog
                            ( SPName ,
                              ErrorNumber ,
                              ErrorMessage ,
                              ErrorProcedure ,
                              ErrorState ,
                              ErrorSeverity ,
                              ErrorLine ,
                              ProcedureStep
				            )
                    VALUES  ( 'spMFInsertValueListItems' ,
                              ERROR_NUMBER() ,
                              ERROR_MESSAGE() ,
                              ERROR_PROCEDURE() ,
                              ERROR_STATE() ,
                              ERROR_SEVERITY() ,
                              ERROR_LINE() ,
                              @ProcedureStep
				            );
                END;

            DECLARE @ErrNum INT = ERROR_NUMBER() ,
                @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
                @ErrSeverity INT = ERROR_SEVERITY() ,
                @ErrState INT = ERROR_STATE() ,
                @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
                @ErrLine INT = ERROR_LINE();

            SET NOCOUNT OFF;

            RAISERROR (
				@ErrMessage
				,@ErrSeverity
				,@ErrState
				,@ErrProcedure
				,@ErrState
				,@ErrMessage
				);
        END CATCH;
    END;

go
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertValueList]';
go
 
SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertValueList', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertValueList'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertValueList]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertValueList]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert ValueList details into MFValueList table.  
  **  
 
  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2018-1-2	Dev2		Add RealObjectType flag
  ******************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'START' ,
                @XML XML = @Doc;

            SELECT  @ProcedureStep = 'Create Table #ValueList';
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertValueList';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------------
          --CREATING TEMPORARY TABLE STORE XML DATA
          -----------------------------------------------------
            CREATE TABLE #ValueList
                (
                  [Name] VARCHAR(100) NOT NULL ,
                  [Alias] NVARCHAR(100) NULL ,
                  [MFID] INT NOT NULL ,
                  OwnerID INT NULL,
				  [RealObjectType] bit
                );

            SELECT  @ProcedureStep = 'Insert values into #ValueList';

          -----------------------------------------------------
          --INSERT DATA FROM XML TO TEMPORARY TABLE
          -----------------------------------------------------
            INSERT  INTO #ValueList
                    ( Name ,
                      Alias ,
                      MFID ,
                      OwnerID,
					  RealObjectType
                    )
                    SELECT  t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Owner)[1]', 'INT') AS OwnerType,
							t.c.value('(@RealObj)[1]', 'bit') AS RealObjectType 
                    FROM    @XML.nodes('/form/valueList') AS t ( c );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

               -- SELECT *
               -- FROM   #ValueList
                END;

            SELECT  @ProcedureStep = 'Inserting New ValueList into #DifferenceTable';

          -----------------------------------------------------
          --Storing the difference into #tempDifferenceTable 
          -----------------------------------------------------
            SELECT  *
            INTO    #DifferenceTable
            FROM    ( SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      #ValueList
                      EXCEPT
                      SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      MFValueList
                    ) tempTbl;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #DifferenceTable
                END;

            SELECT  @ProcedureStep = 'Creating new table to store the updated property details #NewValueListTable';

          -----------------------------------------------------------
          --Creating new table to store the updated property details 
          -----------------------------------------------------------
            CREATE TABLE #NewValueListTable
                (
                  [Name] VARCHAR(100) NOT NULL --COLLATE Latin1_General_CI_AS
                  ,
                  [Alias] NVARCHAR(100) NULL--COLLATE Latin1_General_CI_AS
                  ,
                  [MFID] INT NOT NULL ,
                  [OwnerID] INT NULL,
				  [RealObjectType] BIT NULL
                );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #NewValueListTable
                END;

            SELECT  @ProcedureStep = 'Inserting Values into #NewValueListTable';

          -----------------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------------
            INSERT  INTO #NewValueListTable
                    SELECT  *
                    FROM    #DifferenceTable;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #NewValueListTable
                END;

            SELECT  @ProcedureStep = 'Updating MFValueList with existing and changed values';

          -----------------------------------------------------
          --Updating the MFValueList 
          -----------------------------------------------------
            IF OBJECT_ID('tempdb.dbo.#NewValueListTable') IS NOT NULL
                BEGIN
                    UPDATE  MFValueList
                    SET     MFValueList.Alias = #NewValueListTable.Alias ,
                            MFValueList.Name = #NewValueListTable.Name ,
                            MFValueList.OwnerID = #NewValueListTable.OwnerID ,
                            MFValueList.ModifiedOn = GETDATE() ,
                            MFValueList.Deleted = 0,
							MFValueList.RealObjectType=#NewValueListTable.RealObjectType
                    FROM    MFValueList
                            INNER JOIN #NewValueListTable ON MFValueList.MFID = #NewValueListTable.MFID;

                    SELECT  @Output = @@ROWCOUNT;

                    IF @Debug = 1
                        BEGIN
                            SELECT  @ProcedureStep;

                            SELECT  @Output;

                            SELECT  *
                            FROM    #NewValueListTable;

                            SELECT  *
                            FROM    MFValueList
                                    INNER JOIN #NewValueListTable ON MFValueList.MFID = #NewValueListTable.MFID;

                            SELECT  *
                            FROM    MFValueList;
                        END;
                END;

            SELECT  @ProcedureStep = 'Inserting Value into #temp';

          -----------------------------------------------------
          --Adding The new valeuList 	
          -----------------------------------------------------
            SELECT  *
            INTO    #temp
            FROM    ( SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      #ValueList
                      EXCEPT
                      SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      MFValueList
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #temp
                END;

            SELECT  @ProcedureStep = 'Inserting value into MFValueList';

          -----------------------------------------------------
          --INSERTING NEW VALUELIST DETAILS
          -----------------------------------------------------
            INSERT  INTO MFValueList
                    ( Name ,
                      Alias ,
                      MFID ,
                      OwnerID ,
                      Deleted,
					  CreatedOn ,  --added for task  568
					  RealObjectType
                    )
                    SELECT  Name ,
                            Alias ,
                            MFID ,
                            OwnerID ,
                            0,
							getdate(), --added for task  568
							RealObjectType
                    FROM    #temp;

            SELECT  @Output = @Output + @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    SELECT  @ProcedureStep;

                    SELECT  @Output;

                    SELECT  *
                    FROM    #temp;

                    SELECT  *
                    FROM    MFValueList;
                END;

            SELECT  @ProcedureStep = 'selecting Deleted valueList from M_Files';

            IF ( @isFullUpdate = 1 )
                BEGIN
                    SELECT  @ProcedureStep = 'Full update';

                -----------------------------------------------------
                -- Select MFID Which are deleted from M-Files 
                -----------------------------------------------------
                    SELECT  MFID
                    INTO    #DeletedValueList
                    FROM    ( SELECT    MFID
                              FROM      MFValueList
                              EXCEPT
                              SELECT    MFID
                              FROM      #ValueList
                            ) DeletedMFID;

                    SELECT  @ProcedureStep = 'Updating Deleted = 1';

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                      --SELECT *
                      --FROM   #DeletedValueList
                        END;

                -----------------------------------------------------
                --Deleting the MFValueList Thats deleted from M-Files
                ----------------------------------------------------- 				
                    UPDATE  MFValueList
                    SET     Deleted = 1
                    WHERE   MFID IN ( SELECT    MFID
                                      FROM      #DeletedValueList );
                END;

          -----------------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------------
            DROP TABLE #ValueList;

            DROP TABLE #NewValueListTable;

            DROP TABLE #temp;

            SELECT  @Output = @@ROWCOUNT;

            SET NOCOUNT OFF;

            COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
            ROLLBACK TRANSACTION;

            SET NOCOUNT ON;

            IF @Debug = 1
                BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                    INSERT  INTO MFLog
                            ( SPName ,
                              ErrorNumber ,
                              ErrorMessage ,
                              ErrorProcedure ,
                              ErrorState ,
                              ErrorSeverity ,
                              ErrorLine ,
                              ProcedureStep
                            )
                    VALUES  ( 'spMFInsertValueList' ,
                              ERROR_NUMBER() ,
                              ERROR_MESSAGE() ,
                              ERROR_PROCEDURE() ,
                              ERROR_STATE() ,
                              ERROR_SEVERITY() ,
                              ERROR_LINE() ,
                              @ProcedureStep
                            );
                END;

            DECLARE @ErrNum INT = ERROR_NUMBER() ,
                @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
                @ErrSeverity INT = ERROR_SEVERITY() ,
                @ErrState INT = ERROR_STATE() ,
                @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
                @ErrLine INT = ERROR_LINE();

            SET NOCOUNT OFF;

            RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
        END CATCH;
    END;

go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertWorkflow]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertWorkflow', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertWorkflow'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertWorkflow]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertWorkflow]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert Workflow details into MFWorkflow table.  
  **  
  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 
  ******************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

          -----------------------------------------------------
          --DECLARE LOCAL VARIABLES
          -----------------------------------------------------
            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'Start' ,
                @XML XML = @Doc;
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertWorkflow';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------------
          --CREATING TEMPORERY TABLE TO STORE DATA FROM XML
          -----------------------------------------------------
            CREATE TABLE #WorkflowTble
                (
                  [MFID] INT NOT NULL ,
                  [Alias] NVARCHAR(100) ,
                  [Name] VARCHAR(100)
                );

          ----------------------------------------------------------------------
          --INSERT DATA FROM XML INTO TEPORARY TABLE
          ----------------------------------------------------------------------
            SET @ProcedureStep = 'Inserting values into @WorkflowTble';

            INSERT  INTO #WorkflowTble
                    ( MFID ,
                      Alias ,
                      Name
                    )
                    SELECT  t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME
                    FROM    @XML.nodes('/form/Workflow') AS t ( c );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #WorkflowTble
                END;

          -----------------------------------------------------
          --Storing the difference into #tempNewObjectTypeTble 
          -----------------------------------------------------
            SET @ProcedureStep = 'INSERT Values into #NewWorkflowTble';

            SELECT  *
            INTO    #NewWorkflowTble
            FROM    ( SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      #WorkflowTble
                      EXCEPT
                      SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      MFWorkflow
                    ) tempTbl;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #NewWorkflowTble
                END;

          -------------------------------------------------------------
          --Creatting new table to store the updated property details 
          -------------------------------------------------------------
            CREATE TABLE #NewWorkflowTble2
                (
                  [MFID] INT NOT NULL ,
                  [Alias] NVARCHAR(100) ,
                  [Name] VARCHAR(100)
                );

          -----------------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------------
            SET @ProcedureStep = 'Insert Values into #NewWorkflowTble2';

            INSERT  INTO #NewWorkflowTble2
                    SELECT  *
                    FROM    #NewWorkflowTble;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #NewWorkflowTble2
                END;

          -----------------------------------------------------
          --Updating the MFProperties 
          -----------------------------------------------------
            SET @ProcedureStep = 'Updating MFWorkflow';

            IF OBJECT_ID('tempdb..#NewWorkflowTble2') IS NOT NULL
                BEGIN
                    UPDATE  MFWorkflow
                    SET     MFWorkflow.Name = #NewWorkflowTble2.Name ,
                            MFWorkflow.Alias = #NewWorkflowTble2.Alias ,
                            MFWorkflow.Deleted = 0,
							MFWorkflow.ModifiedOn=GetDate()  --Added for task 568
                    FROM    MFWorkflow
                            INNER JOIN #NewWorkflowTble2 ON MFWorkflow.MFID = #NewWorkflowTble2.MFID;

                    SET @Output = @@ROWCOUNT;
                END;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   MFWorkflow
                END;

          -----------------------------------------------------
          --Adding The new property 	
          -----------------------------------------------------
            SET @ProcedureStep = 'Inserting values into #temp';

            SELECT  *
            INTO    #temp
            FROM    ( SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      #WorkflowTble
                      EXCEPT
                      SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      MFWorkflow
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #temp
                END;

          -----------------------------------------------------
          --INSERT NEW WORKFLOW DETAILS INTO MFWorkflow
          -----------------------------------------------------
            SET @ProcedureStep = 'Inserting values into MFWorkflow';

            INSERT  INTO MFWorkflow
                    ( MFID, Alias, Name, DELETED,CreatedOn )
                    SELECT  MFID ,
                            Alias ,
                            Name ,
                            0,
							Getdate()  --Added for task 568
                    FROM    #temp;

            SET @Output = @Output + @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFWorkflow
                END;

            IF ( @isFullUpdate = 1 )
                BEGIN
                -----------------------------------------------------
                -- Select ObjectTypeID Which are deleted from M-Files  
                -----------------------------------------------------
                    SET @ProcedureStep = '@isFullUpdate = 1';

                    SELECT  MFID
                    INTO    #DeletedWorkflow
                    FROM    ( SELECT    MFID
                              FROM      MFWorkflow
                              EXCEPT
                              SELECT    MFID
                              FROM      #WorkflowTble
                            ) DeletedMFID;

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                      --SELECT *
                      --FROM   #DeletedWorkflow
                        END;

                -----------------------------------------------------
                --Deleting the ObjectTypes Thats deleted from M-Files
                -----------------------------------------------------  
                    SET @ProcedureStep = 'Updating MFWorkflow with Deleted  = 1 ';

                    UPDATE  MFWorkflow
                    SET     Deleted = 1
                    WHERE   MFID IN ( SELECT    MFID
                                      FROM      #DeletedWorkflow );
                END;

          -----------------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------------
            DROP TABLE #WorkflowTble;

            DROP TABLE #NewWorkflowTble2;

            SET NOCOUNT OFF;

            COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
            ROLLBACK TRANSACTION;

            SET NOCOUNT ON;

            IF @Debug = 1
                BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                    INSERT  INTO MFLog
                            ( SPName ,
                              ErrorNumber ,
                              ErrorMessage ,
                              ErrorProcedure ,
                              ErrorState ,
                              ErrorSeverity ,
                              ErrorLine ,
                              ProcedureStep
                            )
                    VALUES  ( 'spMFInsertWorkflow' ,
                              ERROR_NUMBER() ,
                              ERROR_MESSAGE() ,
                              ERROR_PROCEDURE() ,
                              ERROR_STATE() ,
                              ERROR_SEVERITY() ,
                              ERROR_LINE() ,
                              @ProcedureStep
                            );
                END;

            DECLARE @ErrNum INT = ERROR_NUMBER() ,
                @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
                @ErrSeverity INT = ERROR_SEVERITY() ,
                @ErrState INT = ERROR_STATE() ,
                @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
                @ErrLine INT = ERROR_LINE();

            SET NOCOUNT OFF;

            RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
        END CATCH;
    END;

go
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertWorkflowState]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertWorkflowState', -- nvarchar(100)
    @Object_Release = '4.2.9.48', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
 /*
 MODIFICATIONS
 2017-7-2	LC	Change aliase datatype to varchar(100); Edit TRANS loop
2019-3-8	DEV2	Add insert updatecolumn
 */
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertWorkflowState'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertWorkflowState]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertWorkflowState]
    (
      @Doc NVARCHAR(MAX) ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert Workflow State details into MFWorkflowState table.  
  **  

  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 
  ******************************************************************************/
    BEGIN
        BEGIN TRY
      --      BEGIN TRANSACTION;

            SET NOCOUNT ON;

          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
            DECLARE @IDoc INT ,
                @RowUpdated INT ,
                @RowAdded INT ,
                @WorkflowMFID INT ,
                @ProcedureStep sysname = 'Start' ,
                @XML XML = @Doc;
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertWorkflowState';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------------
          --CREATING TEMPORERY TABLE TO STORE DATA FROM XML
          -----------------------------------------------------
            CREATE TABLE #WorkFlowState
                (
                  [MFWorkflowID] INT ,
                  [MFID] INT NOT NULL ,
                  [Name] VARCHAR(100)--COLLATE Latin1_General_CI_AS NOT NULL
                  ,
                  [Alias] NVARCHAR(100)--COLLATE Latin1_General_CI_AS
                );

          ----------------------------------------------------------------------
          --INSERT DATA FROM XML INTO TEPORARY TABLE
          ----------------------------------------------------------------------
            SELECT  @ProcedureStep = 'Inserting CLR values into #WorkFlowStates';

            INSERT  INTO #WorkFlowState
                    ( MFWorkflowID ,
                      MFID ,
                      Name ,
                      Alias
                    )
                    SELECT  t.c.value('(@MFWorkflowID)[1]', 'INT') AS MFWorkflowID ,
                            t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias
                    FROM    @XML.nodes('/form/WorkflowState') AS t ( c );

            IF @Debug = 1
                BEGIN

                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #WorkFlowState
                END;

            SELECT  @ProcedureStep = 'Updating #WorkFlowState with MFWorkflowID';

          -----------------------------------------------------
          --UPDATE MFID WITH PKID
          -----------------------------------------------------
            UPDATE  #WorkFlowState
            SET     MFWorkflowID = ( SELECT ID
                                     FROM   MFWorkflow
                                     WHERE  MFID = MFWorkflowID 
                                   );

            IF @Debug = 1
                BEGIN

                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #WorkFlowState
                END;

            SELECT  @ProcedureStep = 'INSERT VALUES INTO #DIFFERENCETABLE';

          -----------------------------------------------------
          --Storing the difference into #tempDifferenceTable 
          -----------------------------------------------------
            SELECT  *
            INTO    #differenceTable
            FROM    ( SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      #WorkFlowState
                      EXCEPT
                      SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      MFWorkflowState
                    ) tempTbl;

            IF @Debug = 1
                BEGIN

                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #differenceTable
                END;

          -----------------------------------------------------------
          --Creatting new table to store the updated property details
          ----------------------------------------------------------- 
            CREATE TABLE #differenceTable2
                (
                  [MFWorkflowID] INT ,
                  [MFID] INT NOT NULL ,
                  [Name] VARCHAR(100)--COLLATE Latin1_General_CI_AS NOT NULL
                  ,
                  [Alias] NVARCHAR(100)--COLLATE Latin1_General_CI_AS
                );

            SELECT  @ProcedureStep = 'INSERTING NEW VALUES INTO #DIFFERENCETABLE2';

          -----------------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------------
            INSERT  INTO #differenceTable2
                    SELECT  *
                    FROM    #differenceTable;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #differenceTable2
                END;

            SELECT  @ProcedureStep = 'UPDATING MFWORKFLOWSTATES';

          -----------------------------------------------------
          --Updating the MFProperties 
          -----------------------------------------------------
            IF OBJECT_ID('tempdb.dbo.#differenceTable2') IS NOT NULL
                BEGIN

			

				    /*Added for Bug 1088*/
				    UPDATE  MFWorkflowState
                    SET     MFWorkflowState.IsNameUpdate = 1
                    FROM    MFWorkflowState
                            INNER JOIN #differenceTable2 ON MFWorkflowState.MFID = #differenceTable2.MFID
															 AND MFWorkflowState.Name != #differenceTable2.Name;
				/*Added for Bug 1088*/

                    UPDATE  MFWorkflowState
                    SET     MFWorkflowState.MFWorkflowID = #differenceTable2.MFWorkflowID ,
                            MFWorkflowState.Name = #differenceTable2.Name ,
                            MFWorkflowState.Alias = #differenceTable2.Alias ,
                            MFWorkflowState.ModifiedOn = GETDATE() ,
                            MFWorkflowState.Deleted = 0
                    FROM    MFWorkflowState
                            INNER JOIN #differenceTable2 ON MFWorkflowState.MFID = #differenceTable2.MFID;

                    SELECT  @RowUpdated = @@ROWCOUNT;
                END;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFWorkflowState
                END;

            SELECT  @ProcedureStep = 'INSERTING VALUES INTO #TEMP';

          -----------------------------------------------------
          --Adding The new property 
          -----------------------------------------------------
            SELECT  *
            INTO    #temp
            FROM    ( SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      #WorkFlowState
                      EXCEPT
                      SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      MFWorkflowState
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #temp
                END;

            SELECT  @ProcedureStep = 'INSERTING VALUES INTO MFWORKFLOWSTATE';

          -----------------------------------------------------
          --INSERT NEW WORKFLOW STATE DETAILS
          -----------------------------------------------------
            INSERT  INTO MFWorkflowState
                    ( MFWorkflowID ,
                      MFID ,
                      Name ,
                      Alias ,
                      Deleted,
					  CreatedOn  -- Added for task 568
                    )
                    SELECT  MFWorkflowID ,
                            MFID ,
                            Name ,
                            Alias ,
                            0 ,
							getdate() -- Added for task 568
                    FROM    #temp;

            SELECT  @RowAdded = @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFWorkflowState
                END;

            DECLARE @MFWorkflowID INT;

            SELECT DISTINCT
                    @MFWorkflowID = MFWorkflowID
            FROM    #WorkFlowState;

            SELECT  @ProcedureStep = 'INSERTING VALUES INTO #DELETEDWORKFLOWSTATES';

          --------------------------------------------------------
          -- Select ValueListItems Which are deleted from M-Files 
          -----------------------------------------------------  
            SELECT  MFID
            INTO    #DeletedWorkflowStates
            FROM    ( SELECT    MFID
                      FROM      MFWorkflowState
                      WHERE     MFWorkflowState.MFWorkflowID = @MFWorkflowID
                      EXCEPT
                      SELECT    MFID
                      FROM      #WorkFlowState
                    ) #DeletedWorkflowStatesID;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #DeletedWorkflowStates
                END;

            SELECT  @ProcedureStep = 'UPDATING MFWORKFLOWSTATE WITH DELETED = 1 ';

          ---------------------------------------------------------
          --Deleting the ValueListItems Thats deleted from M-Files 
          ---------------------------------------------------------     
            UPDATE  MFWorkflowState
            SET     Deleted = 1
            WHERE   MFID IN ( SELECT    MFID
                              FROM      #DeletedWorkflowStates );

            UPDATE  MFWorkflowState
            SET     Deleted = 1
            WHERE   MFWorkflowID IN ( SELECT    ID
                                      FROM      MFWorkflow
                                      WHERE     deleted = 1 );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   MFWorkflowState
                END;

          -----------------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------------
            DROP TABLE #WorkFlowState;

            DROP TABLE #differenceTable2;

            SELECT  @Output = @RowAdded + @RowUpdated;

            SET NOCOUNT OFF;

     --       COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
    --        ROLLBACK TRANSACTION;

            SET NOCOUNT ON;

            IF @Debug = 1
                BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                    INSERT  INTO MFLog
                            ( SPName ,
                              ErrorNumber ,
                              ErrorMessage ,
                              ErrorProcedure ,
                              ErrorState ,
                              ErrorSeverity ,
                              ErrorLine ,
                              ProcedureStep
                            )
                    VALUES  ( 'spMFInsertWorkflowState' ,
                              ERROR_NUMBER() ,
                              ERROR_MESSAGE() ,
                              ERROR_PROCEDURE() ,
                              ERROR_STATE() ,
                              ERROR_SEVERITY() ,
                              ERROR_LINE() ,
                              @ProcedureStep
                            );
                END;

            DECLARE @ErrNum INT = ERROR_NUMBER() ,
                @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE() ,
                @ErrSeverity INT = ERROR_SEVERITY() ,
                @ErrState INT = ERROR_STATE() ,
                @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE() ,
                @ErrLine INT = ERROR_LINE();

            SET NOCOUNT OFF;

            RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
        END CATCH;
    END;

go


GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableInternal]';
GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFUpdateTableInternal', -- nvarchar(100)
                                     @Object_Release = '4.3.9.47',             -- varchar(50)
                                     @UpdateFlag = 2;
-- smallint
GO
/*
********************************************************************************
    ** Change History
    ********************************************************************************
    ** Date        Author     Description
    ** ----------  ---------  -----------------------------------------------------
    ** 17-04-2015	 Dev 2	DATETIME column value convertion is changed
    ** 16-05-2015	 Dev 2	Record Update/Insert logic is modified 
    **				     (new logic : one record insert/update at a time and 
    **					 skip the records which fails to insert/update)
     25-05-2015	 DEV 2	New input parameter added (@Update_ID)
						Adding @Update_ID & ExtrenalID into MFLog table
     30-06-2015	 DEV 2	Changed the return value to 4 if any record failed insert/Update
     08-07-2015	 DEV 2    Template object issue resolved
     08-07-2015	 DEV 2    BIT Column value resolved
	 22-2-2016     LC   Update Error logging, remove Is_template
	 10-8-2016     lc   update objid filter to fix bug
	 17-8-2016     lc   update conversion of float columns to take account of comma as decimal character
	 19-8-2016     lc   update to take account of class table name in foreign languages 
	26-8-2016		lc		change usage of temptables to global variables and convert to multi user
	10-11-2016    LC    fix bug for records with Null values in required fields
	2017-7-6		LC		Add updating of Filecount
	2017-08-22		LC		Add synch error auto correction
	2017-11-29		lc		Fix Is Templatelist temp file to allow for multiple threads
	2018-06-22		lc		Localisation of workflow_id, name_or_Title property name
	2018-07-03		lc		locatlisation for finish datetime
	2018-08-01		LC		Resolve deletions for filter objid
	2018-08-23		LC		Resolve sync error bug
	2018-10-2		LC		Fix localization bug on  missing quotename
	2018-12-16		LC		prevent record from wrong class in class table
	2018-12-17		LC		formatting of boolean property
	2019-4-01		LC		Add process_id = 0 as condition
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateTableInternal' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateTableInternal]
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFUpdateTableInternal]
(
    @TableName NVARCHAR(128),
    @Xml NVARCHAR(MAX),
    @Update_ID INT,
    @Debug SMALLINT,
    @SyncErrorFlag BIT = 0
)
AS /*******************************************************************************
    ** Desc:  The purpose of this procedure is to Change the class and update any property  of an object
    **  
    ******************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -----------------------------------------------------
        --DECLARE LOCAL VARIABLETempIsTemplatelist
        -----------------------------------------------------
        DECLARE @Idoc INT,
                @ProcedureStep sysname = 'Start',
                @ProcedureName sysname = 'spMFUpdateTableInternal',
                @UpdateColumns NVARCHAR(MAX),
                @UpdateQuery AS NVARCHAR(MAX),
                @InsertQuery AS NVARCHAR(MAX),
                @ColumnNames NVARCHAR(MAX),
                @AlterQuery NVARCHAR(MAX),
                @Columns AS NVARCHAR(MAX),
                @Query AS NVARCHAR(MAX),
                @Params AS NVARCHAR(MAX),
                @ColumnForInsert NVARCHAR(MAX),
                @TempInsertQuery NVARCHAR(MAX),
                @TempUpdateQuery NVARCHAR(MAX),
                @CustomErrorMessage NVARCHAR(MAX),
                @ReturnVariable INT = 1,
                @ExternalID NVARCHAR(100),
                @TempObjectList VARCHAR(100),
                @TempExistingObjects VARCHAR(100),
                @TempNewObjects VARCHAR(100),
                @TempIsTemplatelist VARCHAR(100),
                @Name_or_Title NVARCHAR(100);

        SET @ProcedureStep = 'Drop temptables if exist';
        SELECT @TempObjectList = [dbo].[fnMFVariableTableName]('##ObjectList', DEFAULT);
        SELECT @TempExistingObjects = [dbo].[fnMFVariableTableName]('##ExistingObjects', DEFAULT);
        SELECT @TempNewObjects = [dbo].[fnMFVariableTableName]('##TempNewObjects', DEFAULT);
        SELECT @TempIsTemplatelist = [dbo].[fnMFVariableTableName]('##IsTemplateList', DEFAULT);

        SELECT @Name_or_Title = [ColumnName]
        FROM [dbo].[MFProperty]
        WHERE [MFID] = 0;

        IF EXISTS (SELECT * FROM [sys].[sysobjects] WHERE [name] = '#Properties')
        BEGIN
            DROP TABLE [#Properties];
        END;

        --Parse the Input XML
        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @Xml;

        --------------------------------------------------------------------------------
        --Create Temp Table to Store the Data From XML
        --------------------------------------------------------------------------------
        CREATE TABLE [#Properties]
        (
            [objId] [INT],
            [MFVersion] [INT],
            [GUID] [NVARCHAR](100),
            [ExternalID] [NVARCHAR](100),
            [FileCount] [INT], --Added for task 106
            [propertyId] [INT] NULL,
            [propertyValue] [NVARCHAR](4000) NULL,
            [propertyName] [NVARCHAR](100) NULL,
            [dataType] [NVARCHAR](100) NULL
        );

        SELECT @ProcedureStep = 'Inserting Values into #Properties from XML';

        IF @Debug > 9
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);


        ----------------------------------------
        --Insert XML data into Temp Table
        ----------------------------------------
        INSERT INTO [#Properties]
        (
            [objId],
            [MFVersion],
            [GUID],
            [ExternalID],
            [FileCount], --Added for task 106
            [propertyId],
            [propertyValue],
            [dataType]
        )
        SELECT [objId],
               [MFVersion],
               [GUID],
               [ExternalID],
               [FileCount], --Added for task 106
               [propertyId],
               [propertyValue],
               [dataType]
        FROM
            OPENXML(@Idoc, '/form/Object/properties', 1)
            WITH
            (
                [objId] INT '../@objectId',
                [MFVersion] INT '../@objVersion',
                [GUID] NVARCHAR(100) '../@objectGUID',
                [ExternalID] NVARCHAR(100) '../@DisplayID',
                [FileCount] INT '../@FileCount', --Added for task 106
                [propertyId] INT '@propertyId',
                [propertyValue] NVARCHAR(4000) '@propertyValue',
                [dataType] NVARCHAR(1000) '@dataType'
            );

        SELECT @ProcedureStep = 'Updating Table column Name';

        IF @Debug > 9
        BEGIN
            SELECT 'List of properties from MF' AS [Properties],
                   *
            FROM [#Properties];
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- localisation of date time for finish time
        -------------------------------------------------------------
        UPDATE [p]
        SET [p].[propertyValue] = REPLACE([p].[propertyValue], '.', ':')
        FROM [#Properties] AS [p]
        WHERE [p].[dataType] IN ( 'MFDataTypeTimestamp', 'MFDataTypeDate' );

        ----------------------------------------------------------------
        --Update property name with column name from MFProperty Tbale
        ----------------------------------------------------------------
        UPDATE [#Properties]
        SET [propertyName] =
            (
                SELECT [ColumnName]
                FROM [dbo].[MFProperty]
                WHERE [MFID] = [#Properties].[propertyId]
            );

        -------------------------------------------------------------------------------------------------
        --Update column name if the property datatype is MFDatatypeLookup or MFDatatypeMultiSelectLookup
        -------------------------------------------------------------------------------------------------
        UPDATE [#Properties]
        SET [propertyName] = REPLACE([propertyName], '_ID', '')
        WHERE [dataType] = 'MFDatatypeLookup'
              OR [dataType] = 'MFDatatypeMultiSelectLookup';

        SELECT @ProcedureStep = 'Adding workflow column if not exists';

        IF @Debug > 9
        BEGIN
            SELECT *
            FROM [#Properties];
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

         SELECT @ProcedureStep = 'Adding columns from MFTable which are not exists in #Properties';

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------
        --Select the existing columns from MFTable
        -------------------------------------------------
        INSERT INTO [#Properties]
        (
            [propertyName]
        )
        SELECT *
        FROM
        (
            SELECT [COLUMN_NAME]
            FROM [INFORMATION_SCHEMA].[COLUMNS]
            WHERE [TABLE_NAME] = @TableName
                  AND [COLUMN_NAME] NOT LIKE 'ID'
                  AND [COLUMN_NAME] NOT LIKE 'LastModified'
                  AND [COLUMN_NAME] NOT LIKE 'Process_ID'
                  AND [COLUMN_NAME] NOT LIKE 'Deleted'
                  AND [COLUMN_NAME] NOT LIKE 'ObjID'
                  AND [COLUMN_NAME] NOT LIKE 'MFVersion'
                  AND [COLUMN_NAME] NOT LIKE 'MX_'
                  AND [COLUMN_NAME] NOT LIKE 'GUID'
                  AND [COLUMN_NAME] NOT LIKE 'ExternalID'
                  AND [COLUMN_NAME] NOT LIKE 'FileCount' --Added For Task 106
                  AND [COLUMN_NAME] NOT LIKE 'Update_ID'
            EXCEPT
            SELECT DISTINCT
                   ([propertyName])
            FROM [#Properties]
        ) [m];

        SELECT @ProcedureStep = 'PIVOT';

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --------------------------------------------------------------------------------
        --Selecting The Distinct PropertyName to Create The Columns
        --------------------------------------------------------------------------------
        SELECT @Columns = STUFF(
        (
            SELECT ',' + QUOTENAME([ppt].[propertyName])
            FROM [#Properties] [ppt]
            GROUP BY [ppt].[propertyName]
            ORDER BY [ppt].[propertyName]
            FOR XML PATH(''), TYPE
        ).[value]('.', 'NVARCHAR(MAX)'),
        1   ,
        1   ,
        ''
                               );

        SELECT @ColumnNames = '';

        SELECT @ProcedureStep = 'Select All column names from MFTable';

        IF @Debug > 9
        BEGIN
            SELECT @Columns AS 'Distinct Properties';
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --------------------------------------------------------------------------------
        --Select Column Name Except 'ID','LastModified','Process_ID'
        --------------------------------------------------------------------------------
        SELECT @ColumnNames = @ColumnNames + QUOTENAME([COLUMN_NAME]) + ','
        FROM [INFORMATION_SCHEMA].[COLUMNS]
        WHERE [TABLE_NAME] = @TableName
              AND [COLUMN_NAME] NOT LIKE 'ID'
              AND [COLUMN_NAME] NOT LIKE 'LastModified'
              AND [COLUMN_NAME] NOT LIKE 'Process_ID'
              AND [COLUMN_NAME] NOT LIKE 'Deleted'
              AND [COLUMN_NAME] NOT LIKE 'MX_%'
              AND [COLUMN_NAME] NOT LIKE 'Update_ID';

        SELECT @ColumnNames = SUBSTRING(@ColumnNames, 0, LEN(@ColumnNames));

        SELECT @ProcedureStep = 'Inserting PIVOT Data into  @TempObjectList';



        ------------------------------------------------------------------------------------------------------------------------
        --Dynamic Query to Converting row into columns and inserting into [dbo].[tempobjectlist] USING PIVOT
        ------------------------------------------------------------------------------------------------------------------------
        SELECT @Query
            = 'SELECT *
						INTO ' + @TempObjectList
              + '
						FROM (
							SELECT objId
								,MFVersion
								,GUID
								,ExternalID
								,FileCount     --Added for task 106
								,' + @Columns
              + '
							FROM (
								SELECT objId
									,MFVersion
									,GUID
									,ExternalID
									,FileCount --Added for task 106
									,propertyName new_col
									,value
								FROM #Properties
								UNPIVOT(value FOR col IN (propertyValue)) un
								) src
							PIVOT(MAX(value) FOR new_col IN (' + @Columns + ')) p
							) PVT';


        EXECUTE [sys].[sp_executesql] @Query;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;
        ----------------------------------------
        --Delete objects with Is Template = yes	; Update MFAuditHistory objid with SatusFlag = 6
        ----------------------------------------

        SELECT @ProcedureStep = 'Delete Template objects from objectlist ';


        IF
        (
            SELECT COUNT([o].[name])
            FROM [tempdb].[sys].[objects] AS [o]
            WHERE [o].[name] = @TempIsTemplatelist
        ) > 0
            EXEC (' DROP TABLE ' + @TempIsTemplatelist);

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;


        DECLARE @CLassID INT;
        SELECT @CLassID = [MFID]
        FROM [dbo].[MFClass]
        WHERE [TableName] = @TableName;
        EXEC ('CREATE TABLE ' + @TempIsTemplatelist + ' ( Objid INT ) ');

        SET @Params = N'@Count int output';
        SET @Query
            = N'SELECT @Count = count(*)
		FROM  tempdb.sys.columns where object_ID = object_id(''tempdb..' + @TempObjectList
              + ''')
		and Name = ''Is_Template''

If @Count > 0
begin
Insert into ' + @TempIsTemplatelist + '
Select Objid
from ' + @TempObjectList + '
End		
		';

        --   PRINT @Query;

        EXEC [sys].[sp_executesql] @stmt = @Query,
                                   @param = @Params,
                                   @Count = @ReturnVariable OUTPUT;

        IF @ReturnVariable > 0
        BEGIN
            SET @Params = N'@ClassID int';
            SET @Query
                = '
                    UPDATE  mah
                    SET     [mah].[StatusFlag] = 6 ,
                            mah.[StatusName] = ''Template''
                    FROM    [dbo].[MFAuditHistory] AS [mah]
                            INNER JOIN ' + @TempIsTemplatelist
                  + ' temp ON [mah].[Class] =  @CLassID 
                                                              AND mah.[ObjID] = temp.[Objid];';

            EXEC [sys].[sp_executesql] @stmt = @Query,
                                       @param = @Params,
                                       @ClassID = @CLassID;

            SET @Query = ' DELETE FROM ' + @TempObjectList + ' WHERE isnull(Is_Template,0) = 1';
            EXEC [sys].[sp_executesql] @stmt = @Query;
        END;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s Delete Template', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------
        --Add additional columns to Class Table
        -------------------------------------------------
        SELECT @ProcedureStep = 'Add Additional columns to class table ';

        CREATE TABLE [#Columns]
        (
            [propertyName] [NVARCHAR](100) NULL,
            [dataType] [NVARCHAR](100) NULL
        );

        SET @Query
            = N'
INSERT INTO #Columns (PropertyName) SELECT * FROM (
SELECT Name AS PropertyName FROM tempdb.sys.columns 
			WHERE object_id = Object_id(''tempdb..' + @TempObjectList
              + ''')
		EXCEPT
			SELECT COLUMN_NAME AS name
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = ''' + @TableName + ''') v';

        EXEC [sys].[sp_executesql] @Query;

        IF @Debug > 9
        BEGIN

            RAISERROR('Proc: %s Step: %s Delete Template', 10, 1, @ProcedureName, @ProcedureStep);
        END;


        -------------------------------------------------
        --Updating property datatype
        -------------------------------------------------
        UPDATE [#Columns]
        SET [dataType] =
            (
                SELECT [SQLDataType]
                FROM [dbo].[MFDataType]
                WHERE [ID] IN (
                                  SELECT [MFDataType_ID]
                                  FROM [dbo].[MFProperty]
                                  WHERE [ColumnName] = [#Columns].[propertyName]
                              )
            );

        -------------------------------------------------------------------------
        ----Set dataype = NVARCHAR(100) for lookup and multiselect lookup values
        -------------------------------------------------------------------------
        UPDATE [#Columns]
        SET [dataType] = ISNULL([dataType], 'NVARCHAR(100)');

        SELECT @AlterQuery = '';

        ---------------------------------------------
        --Add new columns into MFTable
        ---------------------------------------------
        SELECT @AlterQuery
            = @AlterQuery + 'ALTER TABLE [' + @TableName + '] Add [' + [propertyName] + '] ' + [dataType] + '  '
        FROM [#Columns];

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

        END;

        EXEC [sys].[sp_executesql] @AlterQuery;


        --------------------------------------------------------------------------------
        --Select Column Name Except 'ID','LastModified','Process_ID'
        --------------------------------------------------------------------------------
        SELECT @ProcedureStep = 'Prepare Column names for insert from class table';


        SELECT @ColumnNames = '';
        SELECT @ColumnNames = @ColumnNames + QUOTENAME([COLUMN_NAME]) + ','
        FROM [INFORMATION_SCHEMA].[COLUMNS]
        WHERE [TABLE_NAME] = @TableName
              AND [COLUMN_NAME] NOT LIKE 'ID'
              AND [COLUMN_NAME] NOT LIKE 'LastModified'
              AND [COLUMN_NAME] NOT LIKE 'Process_ID'
              AND [COLUMN_NAME] NOT LIKE 'Deleted'
              AND [COLUMN_NAME] NOT LIKE 'MX_%'
              AND [COLUMN_NAME] NOT LIKE 'Update_ID';

        SELECT @ColumnNames = SUBSTRING(@ColumnNames, 0, LEN(@ColumnNames));

        IF @Debug > 9
        BEGIN
            --       SELECT  @ColumnNames AS 'Column Names';

            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --------------------------------------------------------------------------------
        --Get datatype of column for Insertion
        --------------------------------------------------------------------------------
        SELECT @ColumnForInsert = '';

        SELECT @ProcedureStep = 'Get datatype of column';

        SELECT @ColumnForInsert
            = @ColumnForInsert
              + CASE
                    WHEN [DATA_TYPE] = 'DATE' THEN
                        ' CONVERT(DATETIME, NULLIF(' + REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105) AS '
                        + QUOTENAME([COLUMN_NAME]) + ','
                    WHEN [DATA_TYPE] = 'DATETIME' THEN
                        ' DATEADD(MINUTE,DATEDIFF(MINUTE,getUTCDATE(),Getdate()),CONVERT(DATETIME, NULLIF('
                        + REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105 )) AS ' + QUOTENAME([COLUMN_NAME])
                        + ','
                    WHEN [DATA_TYPE] = 'BIT' THEN
                        'CASE WHEN ' + QUOTENAME([COLUMN_NAME]) + ' = ''1'' THEN  CAST(''1'' AS BIT) WHEN '
                        + QUOTENAME([COLUMN_NAME]) + ' = ''0'' THEN CAST(''0'' AS BIT)  ELSE 
						null END AS ' + QUOTENAME([COLUMN_NAME]) + ','
                --      + QUOTENAME([COLUMN_NAME]) + ' END AS ' + QUOTENAME([COLUMN_NAME]) + ','
                    WHEN [DATA_TYPE] = 'NVARCHAR' THEN
                        ' CAST(NULLIF(' + QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + '('
                        + CASE
                              WHEN [CHARACTER_MAXIMUM_LENGTH] = -1 THEN
                                  'MAX)) AS ' + QUOTENAME([COLUMN_NAME]) + ','
                              ELSE
                                  CAST(NULLIF([CHARACTER_MAXIMUM_LENGTH], '') AS NVARCHAR) + ')) AS '
                                  + QUOTENAME([COLUMN_NAME]) + ','
                          END
                    WHEN [DATA_TYPE] = 'FLOAT' THEN
                        ' CAST(NULLIF(REPLACE(' + QUOTENAME([COLUMN_NAME]) + ','','',''.''),'''') AS float) AS '
                        + QUOTENAME([COLUMN_NAME]) + ','
                    ELSE
                        ' CAST(NULLIF(' + QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + ') AS '
                        + QUOTENAME([COLUMN_NAME]) + ','
                END
        FROM [INFORMATION_SCHEMA].[COLUMNS]
        WHERE [TABLE_NAME] = @TableName
              AND [COLUMN_NAME] NOT LIKE 'ID'
              AND [COLUMN_NAME] NOT LIKE 'LastModified'
              AND [COLUMN_NAME] NOT LIKE 'Process_ID'
              AND [COLUMN_NAME] NOT LIKE 'Deleted'
              AND [COLUMN_NAME] NOT LIKE 'MX_%'
              AND [COLUMN_NAME] NOT LIKE 'Update_ID';

        ----------------------------------------
        --Remove the Last ','
        ----------------------------------------
        SELECT @ColumnForInsert = SUBSTRING(@ColumnForInsert, 0, LEN(@ColumnForInsert));

        IF @Debug > 9
        BEGIN
            --          SELECT  @ColumnForInsert AS '@ColumnForInsert';
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SELECT @UpdateColumns = '';

        ----------------------------------------
        --Add column values to data type
        ----------------------------------------
        SELECT @UpdateColumns
            = @UpdateColumns
              + CASE
                    WHEN [DATA_TYPE] = 'DATE' THEN
                        '' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + ' = CONVERT(DATETIME, NULLIF(t.'
                        + REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105 ) ,'
                    WHEN [DATA_TYPE] = 'DATETIME' THEN
                        '' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME])
                        + ' = DATEADD(MINUTE,DATEDIFF(MINUTE,getUTCDATE(),Getdate()), CONVERT(DATETIME,NULLIF(t.'
                        + REPLACE(QUOTENAME([COLUMN_NAME]), '.', ':') + ',''''),105 )),'
                    WHEN [DATA_TYPE] = 'BIT' THEN
                        '' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + ' =(CASE WHEN ' + 't.'
                        + QUOTENAME([COLUMN_NAME]) + ' = ''1'' THEN  CAST(''1'' AS BIT)  WHEN t.'
                        + QUOTENAME([COLUMN_NAME]) + ' = ''0'' THEN CAST(''0'' AS BIT)  
						ELSE NULL END ),'
						--WHEN t.'
      --                  + QUOTENAME([COLUMN_NAME]) + ' = ''""'' THEN CAST(''NULL'' AS BIT)  END )  ,'
                    WHEN [DATA_TYPE] = 'NVARCHAR' THEN
                        '' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + '=  CAST(NULLIF(t.'
                        + QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + '('
                        + CASE
                              WHEN [CHARACTER_MAXIMUM_LENGTH] = -1 THEN
                                  CAST('MAX' AS NVARCHAR)
                              ELSE
                                  CAST([CHARACTER_MAXIMUM_LENGTH] AS NVARCHAR)
                          END + ')) ,'
                    WHEN [DATA_TYPE] = 'Float' THEN
                        '' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + '=  CAST(NULLIF(REPLACE(t.'
                        + QUOTENAME([COLUMN_NAME]) + ','','',''.'')' + ','''') AS ' + [DATA_TYPE] + ') ,'
                    ELSE
                        '' + QUOTENAME(@TableName) + '.' + QUOTENAME([COLUMN_NAME]) + '=  CAST(NULLIF(t.'
                        + QUOTENAME([COLUMN_NAME]) + ','''') AS ' + [DATA_TYPE] + ') ,'
                END
        FROM [INFORMATION_SCHEMA].[COLUMNS]
        WHERE [TABLE_NAME] = @TableName
              AND [COLUMN_NAME] NOT LIKE 'ID'
              AND [COLUMN_NAME] NOT LIKE 'LastModified'
              AND [COLUMN_NAME] NOT LIKE 'Process_ID'
              AND [COLUMN_NAME] NOT LIKE 'Deleted'
              AND [COLUMN_NAME] NOT LIKE 'MX_%'
              AND [COLUMN_NAME] NOT LIKE 'Update_ID';

        ----------------------------------------
        --Remove the last ','
        ----------------------------------------
        SELECT @UpdateColumns = SUBSTRING(@UpdateColumns, 0, LEN(@UpdateColumns));




        SELECT @ProcedureStep = 'Create object columns';

        IF @Debug > 9
        BEGIN

            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            IF @Debug > 10
            BEGIN
                SELECT @UpdateColumns AS '@UpdateColumns';
                SET @Query = N'	
					SELECT ''tempobjectlist'' as [TempObjectList],* FROM ' + @TempObjectList + '';
                EXEC (@Query);
            END;
        END;

        ----------------------------------------
        --prepare temp table for existing object
        ----------------------------------------



        SELECT @TempUpdateQuery
            = 'SELECT *
							   INTO ' + @TempExistingObjects + '
							   FROM ' + @TempObjectList + '
							   WHERE ' + @TempObjectList
              + '.[ObjID]  IN (
									   SELECT [ObjiD]
									   FROM [' + @TableName + ']
									   )';

        EXECUTE [sys].[sp_executesql] @TempUpdateQuery;


        SELECT @ProcedureStep = 'Update existing objects';

        IF @Debug > 9
        BEGIN

            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            IF @Debug > 9
            BEGIN
                SET @Query = N'	
					SELECT ''tempExistingobjects'' as [tempExistingobjects],* FROM ' + @TempExistingObjects + '';
                EXEC (@Query);
            END;
        END;

        --------------------------------------------------------------------------------------------
        --Update existing records in Class Table and log the details of records which failed to update
        --------------------------------------------------------------------------------------------
        SELECT @ProcedureStep = 'Determine count of records to Update';

        SET @Params = N'@Count int output';
        SET @Query = N'SELECT @count = count(*)
		FROM  ' + @TempExistingObjects + '';

        EXEC [sys].[sp_executesql] @stmt = @Query,
                                   @param = @Params,
                                   @Count = @ReturnVariable OUTPUT;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s : %i', 10, 1, @ProcedureName, @ProcedureStep, @ReturnVariable);
        END;
        DECLARE @TableID INT;
        IF @ReturnVariable > 0
        BEGIN

            IF @Debug > 10
            BEGIN
                SET @Query
                    = N'	
				SELECT  * FROM ' + QUOTENAME(@TableName) + ' ClassT INNER JOIN ' + @TempExistingObjects
                      + ' T  on ClassT.objid = T.Objid';
                EXECUTE [sys].[sp_executesql] @Query;
            END;


            --			SELECT @UpdateColumns = REPLACE(@UpdateColumns, '+@TempObjectList+', 't')

            IF @Debug > 10
                SELECT @UpdateColumns;
            IF @SyncErrorFlag = 1
            BEGIN

                SELECT @UpdateQuery
                    = '
								UPDATE [' + @TableName + ']
									SET ' + @UpdateColumns + ',LastModified = GETDATE(),Update_ID = '
                      + CAST(@Update_ID AS NVARCHAR(100)) + ', Deleted = 0  ,Process_ID=0           
									FROM [' + @TableName + '] INNER JOIN ' + @TempExistingObjects
                      + ' as t
									ON [' + @TableName + '].ObjID = 
                                t.[ObjID]  AND [' + @TableName + '].Process_ID = 2';



            END;
            ELSE
            BEGIN
                SELECT @UpdateQuery
                    = '
								UPDATE [' + @TableName + ']
									SET ' + @UpdateColumns + ',LastModified = GETDATE(),Update_ID = '
                      + CAST(@Update_ID AS NVARCHAR(100)) + ', Deleted = 0
									FROM [' + @TableName + '] INNER JOIN ' + @TempExistingObjects
                      + ' as t
									ON [' + @TableName + '].ObjID = 
                                t.[ObjID]  AND [' + @TableName + '].Process_ID = 0';
            END;

            ----------------------------------------
            --Executing Dynamic Query
            ----------------------------------------
            IF @Debug > 10
            BEGIN

                SELECT @UpdateQuery AS '@UpdateQuery';
            END;


            EXEC [sys].[sp_executesql] @stmt = @UpdateQuery;





        END;

-------------------------------------------------------------
-- Get class of table
-------------------------------------------------------------       

DECLARE @Class_ID INT, @ClassColumnName NVARCHAR(100)
SELECT @Class_ID = mfid FROM mfclass WHERE tablename = @TableName
SELECT  @ClassColumnName = @TempObjectList +'.'+ ColumnName FROM MFProperty WHERE mfid = 100
 --------------------------------------------------------------------------------
        --Dynamic Query to INSERT new Records into MFTable
        --------------------------------------------------------------------------------


        SELECT @ProcedureStep = 'Setup insert new objects Query';

        SELECT @TempInsertQuery
            = N'Select ' + @TempObjectList + '.* INTO ' + @TempNewObjects + '
			from ' + @TempObjectList + ' left Join ' + QUOTENAME(@TableName) + '
			ON '  + QUOTENAME(@TableName) + '.[ObjID] = ' + @TempObjectList + '.[objid] WHERE '
              + QUOTENAME(@TableName) + '.objid IS null and '+@ClassColumnName+' = ' + CAST(@Class_ID AS NVARCHAR(100));

        IF @Debug > 9
        BEGIN
                  SELECT  @TempInsertQuery AS '@TempInsertQuery';
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
        END;

		 EXECUTE [sys].[sp_executesql] @TempInsertQuery;


        SELECT @ProcedureStep = 'Determine count of records to insert';

        SET @Params = N'@Count int output';
        SET @Query = N'

SELECT @count = count(*)
		FROM  ' + @TempNewObjects + '';

        --           PRINT @Query;

        EXEC [sys].[sp_executesql] @stmt = @Query,
                                   @param = @Params,
                                   @Count = @ReturnVariable OUTPUT;



        IF @ReturnVariable > 0
            SELECT @ProcedureStep = 'Insert new Records';
        IF @Debug > 9
        BEGIN

            RAISERROR('Proc: %s Step: %s : %i', 10, 1, @ProcedureName, @ProcedureStep, @ReturnVariable);
        END;

        BEGIN



            SELECT @ProcedureStep = 'Verify that all required fields have values';

            IF @Debug > 9
            BEGIN

                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @ReturnVariable = COUNT(*)
            FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                LEFT JOIN [#Properties] AS [p]
                    ON [p].[propertyName] = REPLACE([c].[COLUMN_NAME], '_ID', '')
            WHERE [c].[TABLE_NAME] = @TableName
                  AND [c].[IS_NULLABLE] = 'No'
                  AND [c].[COLUMN_NAME] NOT IN ( 'ID' )
                  AND ISNULL([p].[propertyValue], '') = ''
                  AND [c].[COLUMN_NAME] <> @Name_or_Title;

            IF @Debug > 9
            BEGIN

                RAISERROR(
                             'Proc: %s Step: %s; Required properties without value %i',
                             10,
                             1,
                             @ProcedureName,
                             @ProcedureStep,
                             @ReturnVariable
                         );
            END;

            --   IF @ReturnVariable > 0 
            BEGIN

                DECLARE @propertyError VARCHAR(100);


                SELECT TOP 1
                       @propertyError = [p].[propertyName]
                FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                    INNER JOIN [#Properties] AS [p]
                        ON [p].[propertyName] = REPLACE([c].[COLUMN_NAME], '_ID', '')
                WHERE [c].[TABLE_NAME] = @TableName
                      AND [c].[IS_NULLABLE] = 'No'
                      AND [c].[COLUMN_NAME] NOT IN ( 'ID' )
                      AND ISNULL([p].[propertyValue], '') = ''
                      AND [c].[COLUMN_NAME] <> @Name_or_Title;

                IF ISNULL(@propertyError, '') <> ''
                    RAISERROR(
                                 'Proc: %s Step: %s Check Property %s in ClassTable is Null ',
                                 16,
                                 1,
                                 @ProcedureName,
                                 @ProcedureStep,
                                 @propertyError
                             );
            END;


            SELECT @ProcedureStep = 'Insert validated records';

            --           BEGIN TRY

            SELECT @InsertQuery
                = 'INSERT INTO [' + @TableName + '] (' + @ColumnNames
                  + '
										   ,Process_ID
										   ,LastModified
										   ,DELETED
										   ,Update_ID 
										   )
										   SELECT *
										   FROM (
											   SELECT ' + @ColumnForInsert
                  + '
												   ,0 AS Process_ID	
												   ,GETDATE() AS LastModified
												   ,0 AS DELETED
												   ,' + CAST(@Update_ID AS NVARCHAR(100))
                  + ' AS Update_ID	
											   FROM ' + @TempNewObjects + ') t';



            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);
                SELECT @InsertQuery AS '@InsertQuery';
            END;
            SELECT @ProcedureStep = 'Inserted Records';


            EXECUTE [sys].[sp_executesql] @InsertQuery;

            IF @Debug > 9
            BEGIN
                SET @Query
                    = N'	
				SELECT ''Inserted'' as inserted ,* FROM ' + QUOTENAME(@TableName) + ' ClassT INNER JOIN '
                      + @TempNewObjects + ' UpdT  on ClassT.objid = UpdT.Objid';

                EXEC [sys].[sp_executesql] @Query;

                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
            END;


        END;

        ---------------------------------------------------------------
        --Task 1052
        --If IsWorkflowEnforced = 1 and object workflow_ID is null  then 
        --set workflow to Workflow in MFClass_Workflow_ID
        ----------------------------------------------------------------

        DECLARE @WorkflowPropColumnName NVARCHAR(100);
        SELECT @WorkflowPropColumnName = [ColumnName]
        FROM [dbo].[MFProperty]
        WHERE [MFID] = 38;
        IF EXISTS
        (
            SELECT TOP 1
                   *
            FROM [dbo].[MFClass]
            WHERE [IsWorkflowEnforced] = 1
                  AND [TableName] = @TableName
        )
        BEGIN

            DECLARE @IntVariable INT;
            DECLARE @ParmDefinition NVARCHAR(500);

            SET @Query
                = N'SELECT TOP 1  @IntVariable=ID FROM ' + QUOTENAME(@TableName) + ' WHERE ' +@WorkflowPropColumnName+ ' IS NULL';

            SET @ParmDefinition = N'@IntVariable INT OUTPUT';

            EXEC [sys].[sp_executesql] @Query,
                                       @ParmDefinition,
                                       @IntVariable = @IntVariable OUTPUT;

            IF (@IntVariable IS NOT NULL)
            BEGIN

                SET @Query
                    = N'UPDATE ' + @TableName + ' SET ' + @WorkflowPropColumnName
                      + ' = cast( (SELECT w.MFID 
															FROM MFClass c
															INNER JOIN MFWorkflow w ON c.MFWorkflow_ID=W.ID
															WHERE IsWorkflowEnforced=1 AND TableName=''' + @TableName
                      + ''')
									 as VARCHAR(10)),
									 
									 Workflow=cast( (SELECT w.Name 
															FROM MFClass c
															INNER JOIN MFWorkflow w ON c.MFWorkflow_ID=W.ID
															WHERE IsWorkflowEnforced=1 AND TableName=''' + @TableName
                      + ''')
									 as VARCHAR(10))
									  WHERE ' + @WorkflowPropColumnName + ' IS NULL';



                EXEC [sys].[sp_executesql] @Query;
            END;

        END;

        ---------------------------------------------------------------
        --Task 1052
        --If IsWorkflowEnforced = 1 and object workflow_ID is not MFClass_Workflow_ID 
        --then through error and change process_ID to 4
        ----------------------------------------------------------------
        SET @IntVariable = NULL;

        SET @Query
            = N' SELECT TOP 1 @IntVariable=ID 
						FROM ' + QUOTENAME(@TableName) + '
						where ' + @WorkflowPropColumnName
              + ' != (SELECT w.MFID 
													FROM MFClass c
													INNER JOIN MFWorkflow w ON c.MFWorkflow_ID=W.ID
													WHERE IsWorkflowEnforced=1 AND TableName=''' + @TableName + ''')';

        SET @ParmDefinition = N'@IntVariable INT OUTPUT';

        EXEC [sys].[sp_executesql] @Query,
                                   @ParmDefinition,
                                   @IntVariable = @IntVariable OUTPUT;

        IF (@IntVariable IS NOT NULL)
        BEGIN

            SET @Query
                = N'UPDATE ' + QUOTENAME(@TableName) + ' SET Process_ID=4 where ' + @WorkflowPropColumnName
                  + ' =(SELECT w.MFID 
													FROM MFClass c
													INNER JOIN MFWorkflow w ON c.MFWorkflow_ID=W.ID
													WHERE IsWorkflowEnforced=1 AND TableName=''' + @TableName + ''')';

            EXEC [sys].[sp_executesql] @Query;


            RAISERROR(
                         'Proc: %s Step: %s ErrorInfo %s ',
                         16,
                         1,
                         'spMFUpdateTableInternal',
                         'Checking for default workflow ID',
                         'Workflow ID is not equal to default workflow ID'
                     );

        END;

        ----------------------------------------
        --Drop temporary tables
        ----------------------------------------
        SET @Params = N'@TableID int';
        SET @Query = N'
                        DELETE  ' + @TempObjectList + '
                        WHERE   [ObjID] =  @TableID;';

        EXEC [sys].[sp_executesql] @Query, @Params, @TableID;

        SET @Params = N'@TableID int';
        SET @Query = N'
                        DELETE  ' + @TempNewObjects + '
                        WHERE   [ObjID] =  @TableID;';

        EXEC [sys].[sp_executesql] @Query, @Params, @TableID;

        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempExistingObjects
              + ''' )
                BEGIN
                    DROP TABLE ' + @TempExistingObjects + ';
                END ';

        EXEC (@Query);

        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempNewObjects
              + ''' )
                BEGIN
                    DROP TABLE ' + @TempNewObjects + ';
                END ';

        EXEC (@Query);


        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempObjectList
              + ''' )
                BEGIN
                    DROP TABLE ' + @TempObjectList + ';
                END ';

        EXEC (@Query);


        IF EXISTS
        (
            SELECT *
            FROM [sys].[sysobjects]
            WHERE [name] = '##IsTemplateList'
        )
        BEGIN
            DROP TABLE [##IsTemplateList];
        END;

        IF EXISTS (SELECT * FROM [sys].[sysobjects] WHERE [name] = '#Properties')
        BEGIN
            DROP TABLE [#Properties];
        END;


        RETURN 1;
    END TRY
    BEGIN CATCH

        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempExistingObjects
              + ''' )
                BEGIN
                    DROP TABLE ' + @TempExistingObjects + ';
                END ';

        EXEC (@Query);

        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempNewObjects
              + ''' )
                BEGIN
                    DROP TABLE ' + @TempNewObjects + ';
                END ';

        EXEC (@Query);


        SET @Query
            = N' IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = ''' + @TempObjectList
              + ''' )
                BEGIN
                    DROP TABLE ' + @TempObjectList + ';
                END ';

        EXEC (@Query);


        IF EXISTS
        (
            SELECT *
            FROM [sys].[sysobjects]
            WHERE [name] = '##IsTemplateList'
        )
        BEGIN
            DROP TABLE [##IsTemplateList];
        END;

        IF EXISTS (SELECT * FROM [sys].[sysobjects] WHERE [name] = '#Properties')
        BEGIN
            DROP TABLE [#Properties];
        END;

        IF @@TRANCOUNT <> 0
        BEGIN
            ROLLBACK TRAN;
        END;

        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
        DECLARE @ErrorNumber INT;
        DECLARE @ErrorLine INT;
        DECLARE @ErrorProcedure NVARCHAR(128);
        DECLARE @OptionalMessage VARCHAR(MAX);

        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE(),
               @ErrorNumber = ERROR_NUMBER(),
               @ErrorLine = ERROR_LINE(),
               @ErrorProcedure = ERROR_PROCEDURE();

        RAISERROR(   @ErrorMessage,
                                 -- Message text.
                     @ErrorSeverity,
                                 -- Severity.
                     @ErrorState -- State.
                 );

        --------------------------------------------------------------
        --INSERT ERROR DETAILS
        --------------------------------------------------------------
        INSERT INTO [dbo].[MFLog]
        (
            [SPName],
            [ErrorNumber],
            [ErrorMessage],
            [ErrorProcedure],
            [ProcedureStep],
            [ErrorState],
            [ErrorSeverity],
            [ErrorLine],
            [Update_ID]
        )
        VALUES
        ('spMFUpdateTableInternal', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE(),
         ERROR_SEVERITY(), ERROR_LINE(), @Update_ID);
    END CATCH;

    SET NOCOUNT OFF;
END;


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + 'tMFVaultSettings_Password';
GO

SET NOCOUNT ON; 
EXEC [setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'tMFVaultSettings_Password'
  , -- nvarchar(100)
    @Object_Release = '3.1.0.21'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 GO

IF EXISTS ( SELECT  *
            FROM    [sys].[objects]
            WHERE   [objects].[type] = 'TR'
                    AND [objects].[name] = 'tMFVaultSettings_Password' )
   BEGIN
         
         DROP TRIGGER [dbo].[tMFVaultSettings_Password]
         PRINT SPACE(10) + '...Trigger dropped and recreated'
   END
GO

CREATE TRIGGER [dbo].[tMFVaultSettings_Password] ON [dbo].[MFVaultSettings]
       AFTER UPDATE
AS
       /*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2017-03
	Database: 
	Description: Create trigger to encrypt password
						
				 Executed when ever password is updated in [MFVaultSettings]
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
  update MFVaultSettings set Password = 'Password' 
  select * from mfvaultsettings 
  
-----------------------------------------------------------------------------------------------*/
  

       SET NOCOUNT ON;

       DECLARE @result INT
       DECLARE @rc INT
             , @msg AS VARCHAR(250)
             , @Password NVARCHAR(100)
             , @Debug SMALLINT = 0

       IF UPDATE([Password])
          BEGIN
	
                SELECT  @Password = [Inserted].[Password]
                FROM    [Inserted]; 		
	
                IF @Debug > 0
                   SELECT   @Password AS 'InsertedEncryptedPassword'
                EXEC [dbo].[spMFDecrypt]
                    @EncryptedPassword = @Password
                  , -- nvarchar(2000)
                    @DecryptedPassword = @Password OUTPUT;					 	

                IF @Debug > 0
                   SELECT   @Password AS 'InsertedDecryptedPassword'

                IF @Password IS NOT NULL
                   BEGIN

                         DECLARE @EncryptedPassword NVARCHAR(250);
                         DECLARE @PreviousPassword NVARCHAR(100);

				
                         SELECT TOP 1
                                @PreviousPassword = [s].[Password]
                         FROM   [dbo].[MFVaultSettings] [s];

                         IF @Debug > 0
                            SELECT  @PreviousPassword AS '@PreviousPassword'
                                  , LEN(@PreviousPassword) AS [PWLength] 


                         IF LEN(@PreviousPassword) <> 24
                            BEGIN

                                  EXECUTE [dbo].[spMFEncrypt]
                                    @Password
                                  , @EncryptedPassword OUT;
                                  IF @Debug > 0
                                     SELECT @EncryptedPassword AS 'Encrypted PreviousPassword'
                            END
                         ELSE
                            BEGIN         
                                  EXEC [dbo].[spMFDecrypt]
                                    @EncryptedPassword = @PreviousPassword
                                  , -- nvarchar(2000)
                                    @DecryptedPassword = @PreviousPassword OUTPUT;


                                  IF @Debug > 0
                                     SELECT @PreviousPassword AS 'Decrypted PreviousPassword'

                            END

   
                         IF @Password <> @PreviousPassword
                            BEGIN
            
                                  EXECUTE [dbo].[spMFEncrypt]
                                    @Password
                                  , @EncryptedPassword OUT;

                                  UPDATE    [s]
                                  SET       [s].[Password] = @EncryptedPassword
                                  FROM      [dbo].[MFVaultSettings] [s]
                                  WHERE     ( SELECT    COUNT(*)
                                              FROM      [dbo].[MFVaultSettings] AS [mvs]
                                            ) = 1    

                            END
							
                            
                        
			                    	   	
                     


                         IF @Debug > 0
                            SELECT  [mvs].[Password]
                            FROM    [dbo].[MFVaultSettings] AS [mvs]

                   END
                         
                   
          END
   GO
   



GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateClassTableSynchronizeTrigger]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFCreateClassTableSynchronizeTrigger', -- nvarchar(100)
    @Object_Release = '2.0.2.5', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-03
	Database: 
	Description: Procedure to create triggers for syncronisation on class tables
	This procedure is excecuted when the Table is being created.
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

  EXEC [spMFCreateClassTableSynchronizeTrigger]   @TableName = 'MFContactPerson'

  EXEC [spMFCreateClassTableSynchronizeTrigger]   @TableName = 'MFSoftwareOther'
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFCreateClassTableSynchronizeTrigger'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFCreateClassTableSynchronizeTrigger]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO

Alter PROCEDURE spMFCreateClassTableSynchronizeTrigger @TableName sysname, @Debug BIT = 0
As

DECLARE @SQL NVARCHAR(MAX)
--DECLARE @tableName sysname = 'MFContactPerson'

IF EXISTS(SELECT * FROM sys.objects WHERE name = 't'+@TableName +'Synchronize')
BEGIN


SET @SQL = N'
DROP TRIGGER t'+ @TableName +'Synchronize'
	EXEC sp_executeSQL @SQL
	IF @debug > 0
	PRINT 'Trigger dropped';
	END
;


SET @SQL = N'CREATE TRIGGER [dbo].[t'+@TableName +'Synchronize] ON '+QUOTENAME(@TableName)+ '
    AFTER insert, UPDATE 
AS
    /*------------------------------------------------------------------------------------------------
	Author: System Generated, Laminin Solutions
	Description: Trigger immediate update of M-Files					
				 Executed when ever [process_id] is 1

				 This Trigger is automatically created when spMFCreateTable is run
------------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  update MFCustomer set Process_id = 1 where id = 1
    
-----------------------------------------------------------------------------------------------*/
    DECLARE @result INT ,
        @Process_id INT,
		@IncludeInApp smallint;

		 DECLARE @type CHAR(1);
      IF EXISTS ( SELECT    *
                  FROM      inserted )
         IF EXISTS ( SELECT *
                     FROM   deleted )
            SET @type = ''U'';
         ELSE
            SET @type = ''I'';
      ELSE
         SET @type = ''D'';


SELECT @IncludeInApp = [MFClass].[IncludeInApp] FROM MFClass WHERE [MFClass].[TableName] = ''' + @TableName + '''

if @Type = ''U''
Begin
    IF UPDATE(process_id) AND @IncludeInApp = 2
        BEGIN
            IF ( SELECT COUNT(*)
                 FROM  '+QUOTENAME(@TableName)+'
                 WHERE  process_id = 1
               ) > 0
                BEGIN
                    EXEC spmfclassTableSynchronize  @TableName = ' + @TableName + ';
                END;                               
        END;
end

if @Type = ''I''
Begin
    IF @IncludeInApp = 2
        BEGIN
            IF ( SELECT COUNT(*)
                 FROM  '+QUOTENAME(@TableName)+'
                 WHERE  process_id = 1
               ) > 0
                BEGIN
                    EXEC spmfclassTableSynchronize  @TableName = ' + @TableName + ';
                END;                               
        END;
end;

'
		--SELECT @SQL

IF @debug > 0
SELECT @SQL;

		EXEC sp_executeSQL @SQL


Go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeMetadata]';
GO
 

SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeMetadata'
  , -- nvarchar(100)
    @Object_Release = '4.2.7.46'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFSynchronizeMetadata'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeMetadata]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFSynchronizeMetadata]
      @Debug SMALLINT = 0
    , @ProcessBatch_ID INT = NULL OUTPUT 
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Meta data  
  **
  ** Author:			Thejus T V
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 25-05-2015  DEV 2	   UserAccount and Login account is added
  2016-8-22      lc				change settings index
  2016-09-26     DevTeam2  Removed Vaultsettings parametes and pass them as comma
                           separated string in @VaultSettings parameter
2017-08-22		lc			change processBatch_ID to output param
2017-08-22		lc			improve logging
2018-4-30		lc			Add to MFUserMessage
2018-7-25		LC			Auto create MFUserMessages
2018-11-15		LC			fix processbatch_ID logging
  ******************************************************************************/
      BEGIN
            SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      --------------------------------------------- 
            DECLARE @VaultSettings NVARCHAR(4000)
                  , @ProcedureStep sysname = 'START';


            DECLARE @RC INT;
            DECLARE @ProcessType NVARCHAR(50) = 'Metadata Sync';
            DECLARE @LogType NVARCHAR(50);
            DECLARE @LogText NVARCHAR(4000);
            DECLARE @LogStatus NVARCHAR(50);
            DECLARE @ProcedureName VARCHAR(100) = 'spMFSynchronizeMetadata';
            DECLARE @MFTableName NVARCHAR(128);
            DECLARE @Update_ID INT;
            DECLARE @LogProcedureName NVARCHAR(128);
            DECLARE @LogProcedureStep NVARCHAR(128);

      ---------------------------------------------
      -- ACCESS CREDENTIALS FROM Setting TABLE
      ---------------------------------------------

--used on MFProcessBatchDetail;
            DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
            DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
            DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
            DECLARE @EndTime DATETIME
            DECLARE @StartTime DATETIME
            DECLARE @StartTime_Total DATETIME = GETUTCDATE()
            DECLARE @Validation_ID INT
            DECLARE @LogColumnName NVARCHAR(128)
            DECLARE @LogColumnValue NVARCHAR(256)
        

            DECLARE @error AS INT = 0;
            DECLARE @rowcount AS INT = 0;
            DECLARE @return_value AS INT;
            SELECT  @VaultSettings = [dbo].[FnMFVaultSettings]()
        

            BEGIN

                  SET @ProcessType = @ProcedureName
                  SET @LogType = 'Status';
                  SET @LogText = @ProcedureStep + ' | ';
                  SET @LogStatus = 'Initiate';
 
 
                  EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                  , @ProcessType = @ProcessType
                  , @LogType = @LogType
                  , @LogText = @LogText
                  , @LogStatus = @LogStatus
                  , @debug = @debug;
 
 
                  BEGIN TRY
              ---------------------------------------------
              --DECLARE LOCAL VARIABLE
              --------------------------------------------- 
                        DECLARE @ResponseMFObject NVARCHAR(2000)
                              , @ResponseProperties NVARCHAR(2000)
                              , @ResponseValueList NVARCHAR(2000)
                              , @ResponseValuelistItems NVARCHAR(2000)
                              , @ResponseWorkflow NVARCHAR(2000)
                              , @ResponseWorkflowStates NVARCHAR(2000)
                              , @ResponseLoginAccount NVARCHAR(2000)
                              , @ResponseUserAccount NVARCHAR(2000)
                              , @ResponseMFClass NVARCHAR(2000)
                              , @Response NVARCHAR(2000)
                              , @SPName NVARCHAR(100);
		    ---------------------------------------------
              --SYNCHRONIZE Login Accounts
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Login Accounts'
                              , @SPName = 'spMFSynchronizeLoginAccount';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeLoginAccount]
                            @VaultSettings
                          , @Debug
                          , @ResponseLoginAccount OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug

   
		   ---------------------------------------------
              --SYNCHRONIZE Login Accounts
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing User Accounts'
                              , @SPName = 'spMFSynchronizeUserAccount';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeUserAccount]
                            @VaultSettings
                          , @Debug
                          , @ResponseUserAccount OUTPUT;

                        SET @StartTime = GETUTCDATE();


                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
              ---------------------------------------------
              --SYNCHRONIZE OBJECT TYPES
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing ObjectType'
                              , @SPName = 'spMFSynchronizeObjectType';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeObjectType]
                            @VaultSettings
                          , @Debug
                          , @ResponseMFObject OUTPUT;              

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
            
              ---------------------------------------------
              --SYNCHRONIZE VALUE LIST
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing ValueList'
                              , @SPName = 'spMFSynchronizeValueList';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeValueList]
                            @VaultSettings
                          , @Debug
                          , @ResponseValueList OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug

            
              ---------------------------------------------
              --SYNCHRONIZE VALUELIST ITEMS
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing ValueList Items'
                              , @SPName = 'spMFSynchronizeValueListItems';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeValueListItems]
                            @VaultSettings
                          , @Debug
                          , @ResponseValuelistItems OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug

		    ---------------------------------------------
              --SYNCHRONIZE PROEPRTY
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Properties'
                              , @SPName = 'spMFSynchronizeProperties';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeProperties]
                            @VaultSettings
                          , @Debug
                          , @ResponseProperties OUTPUT;
  
                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
            
  
              ---------------------------------------------
              --SYNCHRONIZE WORKFLOW
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing workflow'
                              , @SPName = 'spMFSynchronizeWorkflow';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeWorkflow]
                            @VaultSettings
                          , @Debug
                          , @ResponseWorkflow OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug


              ---------------------------------------------
              --SYNCHRONIZE WORKFLOW STATES
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Workflow states'
                              , @SPName = 'spMFSynchronizeWorkflowsStates';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeWorkflowsStates]
                            @VaultSettings
                          , @Debug
                          , @ResponseWorkflowStates OUTPUT;

                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
            
              ---------------------------------------------
              --SYNCHRONIZE Class
              ---------------------------------------------
                        SELECT  @ProcedureStep = 'Synchronizing Class'
                              , @SPName = 'spMFSynchronizeClasses';

                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        EXECUTE @return_value = [dbo].[spMFSynchronizeClasses]
                            @VaultSettings
                          , @Debug
                          , @ResponseMFClass OUTPUT;

-------------------------------------------------------------
-- Create MFUSerMessage Table
-------------------------------------------------------------


IF NOT EXISTS ( SELECT  name
                FROM    sys.tables
                WHERE   name = 'MFUserMessages'
                        AND SCHEMA_NAME(schema_id) = 'dbo' )
						BEGIN                   					

	EXEC [dbo].[spMFCreateTable] @ClassName = 'User Messages', -- nvarchar(128)
	                             @Debug = 0      -- smallint
	

	END




                        SET @StartTime = GETUTCDATE();

                        SET @LogTypeDetail = 'Message'
                        SET @LogTextDetail = @SPName
                        SET @LogStatusDetail = 'Completed'
                        SET @Validation_ID = NULL
                        SET @LogColumnValue = ''
                        SET @LogColumnValue = ''

                        EXECUTE @RC = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = @Update_ID
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug


                        SET @LogText = 'Processing ' + @ProcedureName + ' completed'
                        SET @LogStatus = 'Completed'
  
                        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @ProcessType = @ProcessType
                          , @LogType = @LogType
                          , @LogText = @LogText					  
                          , @LogStatus = @LogStatus
                          , @debug = @debug
 
                        SELECT  @ProcedureStep = 'Synchronizing metadata completed' 
                        IF @Debug > 9
                           RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

                        RETURN 1
                  END TRY 

                  BEGIN CATCH
                        SET NOCOUNT ON;

                        SET @error = @@ERROR
                        SET @LogStatusDetail = CASE WHEN ( @error <> 0
                                                           OR @return_value = -1
                                                         ) THEN 'Failed'
                                                    WHEN @return_value IN ( 1, 0 ) THEN 'Complete'
                                                    ELSE 'Exception'
                                               END
								
                        SET @LogTextDetail = @ProcedureStep + ' | Return Value: ' + CAST(@return_value AS NVARCHAR(256))
                        SET @LogColumnName = ''
                        SET @LogColumnValue = ''
                        SET @StartTime = GETUTCDATE();

                        EXEC [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = 'System'
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug;

                        SET @LogStatusDetail = NULL
                        SET @LogTextDetail = NULL
                        SET @LogColumnName = NULL
                        SET @LogColumnValue = NULL
                        SET @error = NULL	


                        EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @ProcessType = @ProcessType
                          , @LogType = @LogType
                          , @LogText = @LogText
                          , @LogStatus = @LogStatus
                          , @debug = @debug

                        INSERT  INTO [dbo].[MFLog]
                                ( [SPName]
                                , [ProcedureStep]
                                , [ErrorNumber]
                                , [ErrorMessage]
                                , [ErrorProcedure]
                                , [ErrorState]
                                , [ErrorSeverity]
                                , [ErrorLine]
                                )
                        VALUES  ( @SPName
                                , @ProcedureStep
                                , ERROR_NUMBER()
                                , ERROR_MESSAGE()
                                , ERROR_PROCEDURE()
                                , ERROR_STATE()
                                , ERROR_SEVERITY()
                                , ERROR_LINE()
                                );

                        SET NOCOUNT OFF;

                        RETURN -1;
                  END CATCH;
            END;
      END;


GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeClasses]';
GO

SET NOCOUNT ON 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeClasses'
  , -- nvarchar(100)
    @Object_Release = '3.1.5.41'
  , -- varchar(50)
    @UpdateFlag = 2
 -- smallint
 
GO

/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTeam2   Removed vault settings and pass them as comma separate
                            string in @VaultSettings parameter.
	2017-09-11	LC			Resolve issue with constraints
	2017-12-3	LC			Prevent MFID -100 assignements to be included in update
	2018-04-04  DEV2        Added Module validation code
  ********************************************************************************
*/

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFSynchronizeClasses'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeClasses]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFSynchronizeClasses]
      (
        @VaultSettings [NVARCHAR](4000)
      , @Debug SMALLINT = 0
      , @Out [NVARCHAR](MAX) OUTPUT
      , @IsUpdate SMALLINT = 0
      )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Class details  
  **  

  ** Date:				27-03-2015
   ******************************************************************************/
      BEGIN
            SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------
            DECLARE @ClassXml [NVARCHAR](MAX)
                  , @ClassPptXml [NVARCHAR](MAX)
                  , @Output INT
                  , @ProcedureName VARCHAR(100) = 'spMFSynchronizeClasses'
                  , @ProcedureStep VARCHAR(100) = 'Start Syncronise Classes ';
            DECLARE @Result_value INT;
  
            IF @Debug = 1
               RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

            BEGIN TRY
	
        
------------------------------------------------------
		--Drop CONSTRAINT
		------------------------------------------------------
                  SET @ProcedureStep = 'Drop CONSTRAINT';
                  IF @Debug = 1
                     RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

                  IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NOT NULL )
                     BEGIN
                           ALTER TABLE [dbo].[MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass];
                     END;		
				IF ( OBJECT_ID('FK_MFClassProperty_MFClass_ID', 'F') IS NOT NULL )
					BEGIN
						ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass_ID];
					END;
				IF ( OBJECT_ID('FK_MFProperty_ID', 'F') IS NOT NULL )
					BEGIN
						ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFProperty_ID];
					END;
					IF ( OBJECT_ID('FK_MFClassProperty_MFProperty', 'F') IS NOT NULL )
					BEGIN
						ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFProperty];
					END;
      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET CLASS DETAILS FROM M-FILES
      -------------------------------------------------------------
                  SET @ProcedureStep = 'Get Classes';
                  IF @Debug = 1
                     RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
           
       -----------------------------------------------------------------------
	    --Checking Module access 
	   ------------------------------------------------------------------------

	   EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetClass',@ProcedureName,@ProcedureStep

                  EXEC [dbo].[spMFGetClass]
                    @VaultSettings
                  , @ClassXML OUTPUT
                  , @ClassPptXML OUTPUT;

                  IF @@error <> 0
                     RAISERROR('Error Getting Classes',16,1);
          
      -------------------------------------------------------------------------
      -- CALLS 'spMFInsertClass' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      -------------------------------------------------------------------------
  
                  BEGIN TRY
                        SET @ProcedureStep = 'Insert class detail into MFClass Table';
                        IF @Debug = 1
                           RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

                        IF @IsUpdate = 1
                           BEGIN
						  
                                 SELECT [MFClass].[ID]
                                      , [MFClass].[MFID]
                                      , [MFClass].[Name]
                                      , [MFClass].[Alias]
                                      , [MFClass].[IncludeInApp]
                                      , [MFClass].[TableName]
                                      , [MFClass].[MFObjectType_ID]
                                      , [MFClass].[MFWorkflow_ID]
                                 INTO   [#TmpClass]
                                 FROM   [dbo].[MFClass]
                                 WHERE  [MFClass].[Deleted] = 0 AND MFID >= 0 -- MFID -100 cannot have an alias

                                 EXEC @Result_value = [dbo].[spMFInsertClass]
                                    @ClassXml
                                  , 1 --IsFullUpdate Set to TRUE 
                                  , @Output OUTPUT
                                  , @Debug;

                                 SET @ProcedureStep = 'SQL Class detail inserted';
                                 IF @Debug = 1
                                    RAISERROR('%s : Step %s with return %i',10,1,@ProcedureName,@ProcedureStep,@Result_value);

                                 DECLARE @XML NVARCHAR(MAX)

                                 SET @XML = ( SELECT    ISNULL([MFCLS].[ID], 0) AS 'ClassDetails/@SqlID'
                                                      , ISNULL([MFCLS].[MFID], 0) 'ClassDetails/@MFID'
                                                      , ISNULL([MFCLSN].[Name], '') 'ClassDetails/@Name'
                                                      , ISNULL([MFCLSN].[Alias], '') 'ClassDetails/@Alias'
                                                      , ISNULL([MFCLS].[IncludeInApp], 0) 'ClassDetails/@IncludeInApp'
                                                      , ISNULL([MFCLS].[TableName], '') 'ClassDetails/@TableName'
                                                      , ISNULL([MFCLS].[MFObjectType_ID], 0) 'ClassDetails/@MFObjectType_ID'
                                                      , ISNULL([MFCLS].[MFWorkflow_ID], 0) 'ClassDetails/@MFWorkflow_ID'
                                              FROM      [dbo].[MFClass] [MFCLS]
                                              INNER JOIN [#TmpClass] [MFCLSN] ON [MFCLS].[MFID] = [MFCLSN].[MFID]
                                                                             AND ( [MFCLS].[Alias] != [MFCLSN].[Alias]
                                                                                   OR [MFCLS].[Name] != [MFCLSN].[Name]
                                                                                 )
                                            FOR
                                              XML PATH('')
                                                , ROOT('CLS')
                                            )

								IF @debug = 1
								select @xml;

                                 DECLARE @Output1 NVARCHAR(MAX)

								 -----------------------------------------------------------------------
									--Checking Module access 
								 ------------------------------------------------------------------------

								EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdateClass',@ProcedureName,@ProcedureStep

                                 EXEC [dbo].[spMFUpdateClass]
                                    @VaultSettings
                                  , @XML
                                  , @Output1 OUTPUT

								  IF @debug = 1
								PRINT @Output1;


                                 UPDATE [CLs]
                                 SET    [CLs].[Alias] = [t].[Alias]
                                      , [CLs].[Name] = [t].[Name]
                                 FROM   [dbo].[MFClass] [CLs]
                                 INNER JOIN [#TmpClass] [t] ON [t].[MFID] = [CLs].[MFID]

                                 DROP TABLE [#TmpClass]
                           END
                        ELSE
                           BEGIN
						 
                                 EXEC @Result_value = [dbo].[spMFInsertClass]
                                    @ClassXml
                                  , 1 --IsFullUpdate Set to TRUE 
                                  , @Output OUTPUT
                                  , @Debug;

                           END
                

                        IF @Debug = 1
                           RAISERROR('%s : Step %s completed with result %i',10,1,@ProcedureName,@ProcedureStep,@Result_value);

                        IF ( @Output > 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All Classes are Updated';
                        IF ( ISNULL(@Output, 0) = 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All Classes are up to date';

					
                        IF @Debug = 1
                           RAISERROR('@Result_Value %s',10,1,@Out);

                  END TRY
                  BEGIN CATCH
	
                        RAISERROR('Syncronisation failed to Insert Classes',16,1);
                  END CATCH;
      -------------------------------------------------------------------------------------------------
      -- CALLS 'spMFInsertClassProperty' TO INSERT THE CLASS PROPERTY DETAILS INTO MFClassProperty TABLE
      --------------------------------------------------------------------------------------------------
                  SET @ProcedureStep = 'Insert update detail into MFClassProperty Table';

                  IF @Debug = 1
                     RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

                  BEGIN TRY
 
                        EXEC @Result_value = [dbo].[spMFInsertClassProperty]
                            @ClassPptXml
                          , 1 --IsFullUpdate Set to TRUE 
                          , @Output OUTPUT
                          , @Debug;

                        IF @Debug = 1
                           RAISERROR('%s : Step %s Completed with result %i',10,1,@ProcedureName,@ProcedureStep,@Result_value);

                        IF ( @Output > 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All ClassProperties are Updated';
                        IF ( ISNULL(@Output, 0) = 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All ClassProperties are upto date';


                  END TRY
                  BEGIN CATCH

                        RAISERROR('%s : Step %s InsertClassProperty Failed to complete',16,1,@ProcedureName,@ProcedureStep);
                  END CATCH;
	----------------------------------------------
	--	Add CONSTRAINT to [dbo].[MFClassProperty]
	--	--------------------------------------------
                  SET @ProcedureStep = 'Add Constraint';

                  IF @Debug = 1
                     BEGIN
                           RAISERROR('Step %s',10,1,@ProcedureName,@ProcedureStep);
                           SELECT   *
                           FROM     [dbo].[MFClassProperty] AS [mcp];
                     END;

BEGIN TRY

            IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NULL )
                BEGIN

                    ALTER TABLE [dbo].[MFClassProperty]
                    WITH CHECK  ADD CONSTRAINT [FK_MFClassProperty_MFClass] FOREIGN KEY ([MFClass_ID]) REFERENCES [dbo].[MFClass]([ID]);

                END;
END TRY
BEGIN CATCH
       RAISERROR('%s : Step %s fail to create constraint',10,1,@ProcedureName,@ProcedureStep);
END CATCH;


                  SELECT    @ProcedureStep = 'END Syncronise Classes:' + @Out;

                  IF @Debug = 1
                     BEGIN
                           RAISERROR('%s : Step %s Return %i',10,1,@ProcedureName,@ProcedureStep, @Result_value);
                     END;

                  SET NOCOUNT OFF;
                  RETURN 1;
            END TRY

            BEGIN CATCH

                  SET NOCOUNT ON;

                  BEGIN
			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
                        INSERT  INTO [dbo].[MFLog]
                                ( [SPName]
                                , [ErrorNumber]
                                , [ErrorMessage]
                                , [ErrorProcedure]
                                , [ErrorState]
                                , [ErrorSeverity]
                                , [ErrorLine]
                                , [ProcedureStep]
				                )
                        VALUES  ( @ProcedureName
                                , ERROR_NUMBER()
                                , ERROR_MESSAGE()
                                , ERROR_PROCEDURE()
                                , ERROR_STATE()
                                , ERROR_SEVERITY()
                                , ERROR_LINE()
                                , @ProcedureStep
				                );
                  END;

                  DECLARE @ErrNum INT = ERROR_NUMBER()
                        , @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE()
                        , @ErrSeverity INT = ERROR_SEVERITY()
                        , @ErrState INT = ERROR_STATE()
                        , @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE()
                        , @ErrLine INT = ERROR_LINE();

                  SET NOCOUNT OFF;

                  RAISERROR (
				@ErrMessage
				,@ErrSeverity
				,@ErrState
				,@ErrProcedure
				,@ErrState
				,@ErrMessage
				);
                  RETURN -1;
            END CATCH;
      END;

GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeObjectType]';
GO

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeObjectType', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeObjectType'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeObjectType]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeObjectType]
    (
      @VaultSettings   [NVARCHAR](4000)
      ,@Debug          [SMALLINT] = 0
      ,@Out            [NVARCHAR](max) OUTPUT
	  ,@IsUpdate SMALLINT=0
    )
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File ObjectType details  
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTeam(2) Removed Vault Settings parameters and pass them as 
                            comma separated string in single parameter  (@VaultSettings
     2018-04-04  Devteam(2) Added License module validation code.
   ******************************************************************************/
  BEGIN
      SET NOCOUNT ON

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------    
        DECLARE @Xml [NVARCHAR](MAX) ,
            @Output INT ,
            @ProcedureStep NVARCHAR(128) = 'Wrapper - GetObjectType' ,
            @ProcedureName NVARCHAR(128) = '[spMFSynchronizeObjectType]';
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);
      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET OBJECTTYPE DETAILS FROM M-FILES
      -------------------------------------------------------------
        

        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep); 
	    
          select @VaultSettings=dbo.FnMFVaultSettings()
	  
	   ------------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetObjectType
	   ------------------------------------------------------------------
	     EXEC [dbo].[spMFCheckLicenseStatus] 
		      'spMFGetObjectType',
			  @ProcedureName,
			  @ProcedureStep


          EXEC spMFGetObjectType @VaultSettings,@Xml OUTPUT;


        SET @ProcedureStep = 'GetObjectType Returned from wrapper';

        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep); 
      -------------------------------------------------------------------------
      -- CALL 'spMFInsertObjectType' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      -------------------------------------------------------------------------
        if  @IsUpdate =1
		  Begin
		    
			Declare @ObjTypeXml nvarchar(max)
			Select ID,Name,Alias,MFID into #tempObjectType from MFObjectType where Deleted=0

		     EXEC spMFInsertObjectType @Xml, 1--IsFullUpdate Set to TRUE  
            ,@Output OUTPUT, @Debug;

			set @ObjTypeXml =(Select 
			   isnull(TObTyp.ID,0) as 'ObjTypeDetails/@ID'
			  ,isnull(TObTyp.Name,'') as 'ObjTypeDetails/@Name'
			  ,isnull(TObTyp.Alias,'') as 'ObjTypeDetails/@Alias'
			  ,isnull(TObTyp.MFID ,0) as 'ObjTypeDetails/@MFID'
			 from 
			   MFObjectType ObTyp inner join #tempObjectType TObTyp 
			 on 
			   ObTyp.MFID=TObTyp.MFID 
			   and 
			   (ObTyp.Alias!=TObTyp.Alias or ObTyp.Name!=TObTyp.Name)
			 For XML Path(''),Root('ObjType'))

			 --print @ObjTypeXml
			 ------------------------------------------------------------------
	           -- Checking module access for CLR procdure  spMFGetObjectType
	         ------------------------------------------------------------------
	          EXEC [dbo].[spMFCheckLicenseStatus] 
			       'spMFUpdateObjectType'
				   ,@ProcedureName
				   ,@ProcedureStep

			 Declare @Output1 nvarchar(max)
			 exec spMFUpdateObjectType @VaultSettings,@ObjTypeXml,@Output1

			 Update
			   ObTyp
              set
			   ObTyp.Alias=TObTyp.Alias,
			   ObTyp.Name=TObTyp.Name
			  from 
			   MFObjectType ObTyp inner join #tempObjectType TObTyp 
			 on 
			   ObTyp.MFID=TObTyp.MFID 

			   drop table #tempObjectType
		  End
		else
		  Begin
		      EXEC spMFInsertObjectType @Xml, 1--IsFullUpdate Set to TRUE  
             ,@Output OUTPUT, @Debug;
		  End
        

        SET @ProcedureStep = 'Exec spMFInsertObjectType'; 

        IF @Debug = 1
            RAISERROR('%s : Step %s Output: %i ',10,1,@ProcedureName, @ProcedureStep, @Output);

        IF ( @Output > 0 )
            SET @Out = 'All Object Types Updated';
        ELSE
            SET @Out = 'All Object Types Are Upto Date';

        SET NOCOUNT OFF;
    END;
  GO
  

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeLoginAccount]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeLoginAccount', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSynchronizeLoginAccount'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeLoginAccount]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO
Alter PROCEDURE [dbo].[spMFSynchronizeLoginAccount] (@VaultSettings  [NVARCHAR](4000)
                                                    ,@Debug          [SMALLINT] = 0
                                                    ,@Out            [NVARCHAR](max) OUTPUT)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Login Account details  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **					1.) Call CRL procedure to get Login Account details from M-files
  **					2.) Call spMFInsertLoginAccount to insert Login Account details into Table 
  **
  ** Parameters and acceptable values: 
  **					@VaultSettings       [NVARCHAR](4000)
  **					@Debug          SMALLINT = 0
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					@Out            [NVARCHAR](max)		
  **
  ** Called By:			spMFSynchronizeMetadata
  **
  ** Calls:           
  **					spMFGetLoginAccounts
  **					spMFInsertLoginAccount									
  **
  ** Author:			Thejus T V
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTeam2   Removed vault settings parameters and pass them as 
                            comma separated string in @VaultSettings parameter.
     2017-04-03  DEVTeam2   Added License module validation code.
  ******************************************************************************/
  BEGIN
      SET NOCOUNT ON

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------    
      DECLARE @Xml     [NVARCHAR] (max)
              ,@Output INT
			  ,@ProcedureStep nVARCHAR(128) = 'Wrapper - GetLoginAccounts'
			  ,@ProcedureName nVARCHAR(128) = 'spMFSynchronizeLoginAccount'
			 ;
IF @debug  = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

	 -------------------------------------------------------------------
	  --Checking module access for CLR procedure
	 -------------------------------------------------------------------
	  EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetLoginAccounts',@ProcedureName,@ProcedureStep
      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET Login Account DETAILS FROM M-FILES
      -------------------------------------------------------------
      EXEC spMFGetLoginAccounts
        @VaultSettings
        ,@Xml OUTPUT;

		  SET @ProcedureStep  = 'GetLoginAccounts Returned from wrapper'

IF @debug  = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);
      -------------------------------------------------------------------------
      -- CALL 'spMFInsertLoginAccount' TO INSERT THE Login Account DETAILS INTO MFLoginAccount TABLE
      -------------------------------------------------------------------------
 SET @ProcedureStep  = 'Exec spMFInsertLoginAccount'

 DECLARE @return_Value int
 BEGIN TRY
 
      EXEC @return_Value = spMFInsertLoginAccount
        @Xml
        ,1--IsFullUpdate Set to TRUE  
        , @Output OUTPUT
        ,@Debug;

IF @debug  = 1
            RAISERROR('%s : Step %s Returned: %i : Output: %i ',10,1,@ProcedureName, @ProcedureStep, @return_Value, @Output);

		END TRY
        BEGIN CATCH

		RAISERROR('spMFInsertLoginAccount Failed %i',16,1,@return_Value)

        END CATCH
        



      IF ( @Output > 0 )
        SET @Out = 'All Login Accounts Updated'
      ELSE
        SET @Out = 'All Login Accounts Are Upto Date'

      SET NOCOUNT OFF
  END
  go
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeUserAccount]';
GO
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeUserAccount', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeUserAccount'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeUserAccount]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeUserAccount]
    (
       @VaultSettings  [NVARCHAR](4000)
       ,@Debug          SMALLINT = 0
       ,@Out            [NVARCHAR](max) OUTPUT)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File User Account details  

  ** Date:			26-05-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTean2   Removed vault settings parameters and pass them as 
                            comma separated string in @VaultSettings parameter.
     2018-04-04 DevTeam     Addded License module validation code
  ******************************************************************************/
    BEGIN
        SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------
        DECLARE @UserAccountXML [NVARCHAR](MAX) ,
            @Output INT ,
            @ProcedureStep NVARCHAR(128) = 'Wrapper - GetUserAccounts' ,
            @ProcedureName NVARCHAR(128) = 'spMFSynchronizeUserAccount';
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);



      -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetObjectType
      ------------------------------------------------------------------
	   EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetUserAccounts',@ProcedureName,@ProcedureStep

      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET USER ACCOUNT DETAILS FROM M-FILES
      -------------------------------------------------------------
      EXEC spMFGetUserAccounts
         @VaultSettings
        ,@UserAccountXML OUTPUT
     
        SET @ProcedureStep = 'GetUserAccounts Returned from wrapper';

        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep); 

      -------------------------------------------------------------------------
      -- CALLS 'spMFInsertUserAccount' TO INSERT THE USER ACCOUNT DETAILS INTO MFClass TABLE
      -------------------------------------------------------------------------
        SET @ProcedureStep = 'Exec spMFInsertLoginAccount'; 
   
        EXEC spMFInsertUserAccount @UserAccountXML, 1 --IsFullUpdate Set to TRUE 
            , @Output OUTPUT, @Debug;
  
        IF @Debug = 1
            RAISERROR('%s : Step %s Output: %i ',10,1,@ProcedureName, @ProcedureStep, @Output);


      
        IF ( @Output > 0 )
            SET @Out = 'All User Accounts Updated';
        ELSE
            SET @Out = 'All User Accounts Upto date';

        SET NOCOUNT OFF;
    END;
  GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeProperties]';
GO


SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeProperties'	-- nvarchar(100)
  , @Object_Release = '3.1.5.41'				-- varchar(50)
  , @UpdateFlag = 2;							-- smallint

GO

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFSynchronizeProperties' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeProperties]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeProperties]
	(
		@VaultSettings [NVARCHAR](4000)
	  , @Debug		   SMALLINT
	  , @Out		   [NVARCHAR](MAX) OUTPUT
	  , @IsUpdate	   SMALLINT		   = 0
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Property details  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **					1.) Call CRL procedure to get property details from M-files
  **					2.) Call spMFInsertProperty to insert property details into Table 
  **
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTeam2   Removed vaultsettings parameters and pass them as 
                            comma separated string in @VaultSettings parameter.
	 2018-04-04 DevTeam2    Added License module validation code
  ******************************************************************************/
	BEGIN

		SET NOCOUNT ON;

		---------------------------------------------
		--DECLARE LOCAL VARIABLE
		--------------------------------------------- 
		DECLARE
			@Xml		   [NVARCHAR](MAX)
		  , @Output		   INT			  = 0
		  , @ProcessStep   VARCHAR(100) = 'Get Properties'
		  , @ProcedureName sysname		  = 'spMFSynchronizeProperties'
		  , @Result_Value  INT;
		BEGIN TRY

		    -----------------------------------------------------------------
	          -- Checking module access for CLR procdure  spMFGetProperty
            ------------------------------------------------------------------
		     EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetProperty',@ProcedureName,'Validating module access for clr procedure spMFGetProperty'
			------------------------------------------------------------
			--CALL WRAPPER PROCEDURE TO GET PROPERTY DETAILS FROM M-FILES
			-------------------------------------------------------------

			EXEC [spMFGetProperty] @VaultSettings, @Xml OUTPUT;
			IF @Debug > 0 SELECT	@Xml;
		END TRY
		BEGIN CATCH
			-- SELECT  @Xml;
			RAISERROR('%s : Step %s Error Getting Properties', 16, 1, @ProcedureName, @ProcessStep);

		END CATCH;
		-------------------------------------------------------------------------
		-- CALL 'spMFInsertProperty' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
		------------------------------------------------------------------------- 

		BEGIN TRY
			SET @ProcessStep = 'Insert existing Properties in temp table';
			IF @IsUpdate = 1
				BEGIN
					SELECT
							[ID], [Name], [Alias], [MFID], [ColumnName], [MFDataType_ID], [PredefinedOrAutomatic], [MFValueList_ID]
					INTO	[#TempMFProperty]
					FROM	[MFProperty]
					WHERE	[Deleted] = 0;

					SET @ProcessStep = 'Insert new properties';
					SET @ProcedureName = 'Exec [spMFInsertProperty]';

					EXEC @Result_Value = [spMFInsertProperty]
						@Xml
					  , 1	--IsFullUpdate Set to TRUE  
					  , @Output OUTPUT
					  , @Debug;

					SET @ProcedureName = 'Exec spMFSynchronizeProperties';

					DECLARE @PropXML NVARCHAR(MAX);

					SET @PropXML = (
									   SELECT
											ISNULL([TMP].[ID], 0)			 AS [PropDetails/@ID]
										  , ISNULL([TMP].[Name], '')		 AS [PropDetails/@Name]
										  , ISNULL([TMP].[Alias], '')		 AS [PropDetails/@Alias]
										  , ISNULL([TMP].[MFID], 0)			 AS [PropDetails/@MFID]
										  , ISNULL([TMP].[ColumnName], '')	 AS [PropDetails/@ColumnName]
										  , ISNULL([TMP].[MFDataType_ID], 0) AS [PropDetails/@MFDataType_ID]
										  , CASE WHEN ISNULL([TMP].[PredefinedOrAutomatic], 0) = 0 THEN 'false'
												 ELSE
													  'true'
											END								 AS [PropDetails/@PredefinedOrAutomatic]
								--			,ISNULL(tmp.[MFValueList_ID],0)  AS [PropDetails/@ValuelistID]
									   FROM [MFProperty]				 AS [MP]
											INNER JOIN [#TempMFProperty] AS [TMP] ON [MP].[MFID] = [TMP].[MFID]
																					 AND (
																							 [MP].[Alias] != [TMP].[Alias]
																							 OR [MP].[Name] != [TMP].[Name]
																						 )
									   FOR XML PATH(''), ROOT('Prop')
								   );
					SET @ProcedureName = 'Exec [spMFUpdateProperty] ';

					-----------------------------------------------------------------
	                 -- Checking module access for CLR procdure  spMFUpdateProperty
                    ------------------------------------------------------------------
--		     EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdateProperty',@ProcedureName,'Validating module access for clr procedure spMFUpdateProperty'

					EXEC [spMFUpdateProperty] @VaultSettings, @PropXML, @Output OUTPUT;

					SET @ProcedureName = 'Exec [spMFSynchronizeProperties] ';

					UPDATE	[MP]
					SET
							[MP].[Alias] = [TMP].[Alias], [MP].[Name] = [TMP].[Name]
					FROM	[MFProperty]				 AS [MP]
							INNER JOIN [#TempMFProperty] AS [TMP] ON [MP].[MFID] = [TMP].[MFID];

					DROP TABLE [#TempMFProperty];

				END;
			ELSE
				BEGIN

					EXEC @Result_Value = [spMFInsertProperty]
						@Xml
					  , 1	--IsFullUpdate Set to TRUE  
					  , @Output OUTPUT
					  , @Debug;

				END;



			UPDATE	[mp]
			SET		[mp].[MFValueList_ID] = [mvl].[ID]
			--SELECT mp.[MFValueList_ID] , mvl.[ID] , *
			FROM	[dbo].[MFValueList]			  AS [mvl]
					INNER JOIN [dbo].[MFProperty] AS [mp] ON [mp].[Name] = [mvl].[Name]
															 AND   [mp].[MFDataType_ID] IN ( 8, 9 )
			WHERE	[mp].[Name] = [mvl].[Name];


			IF @Debug > 0
				RAISERROR('%s : Step %s @Result_Value %i', 10, 1, @ProcedureName, @ProcessStep, @Result_Value);


			IF ( @Output > 0 AND @Result_Value = 1 )
				SET @Out = 'All Properties are Updated';
			IF ( ISNULL(@Output, 0) = 0 AND @Result_Value = 1 )
				SET @Out = 'All Properties are up to date';
			IF @Result_Value <> 1
				RAISERROR('%s : Step %s Syncronisation failed to Insert Property', 16, 1, @ProcedureName, @ProcessStep);


			IF @Debug > 0
				RAISERROR('%s : Step %s @Result_Value %s', 10, 1, @ProcedureName, @ProcessStep, @Out);
				
			SET NOCOUNT OFF;
			RETURN 1;
		END TRY
		BEGIN CATCH
	--	ROLLBACK TRANSACTION
			SET NOCOUNT ON;

			BEGIN
				--------------------------------------------------
				-- INSERTING ERROR DETAILS INTO LOG TABLE
				--------------------------------------------------
				INSERT INTO [MFLog] ( [SPName]
									, [ErrorNumber]
									, [ErrorMessage]
									, [ErrorProcedure]
									, [ErrorState]
									, [ErrorSeverity]
									, [ErrorLine]
									, [ProcedureStep]
									)
				VALUES (
						   @ProcedureName
						 , ERROR_NUMBER()
						 , ERROR_MESSAGE()
						 , ERROR_PROCEDURE()
						 , ERROR_STATE()
						 , ERROR_SEVERITY()
						 , ERROR_LINE()
						 , @ProcessStep
					   );
			END;

			DECLARE
				@ErrNum		  INT			= ERROR_NUMBER()
			  , @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE()
			  , @ErrSeverity  INT			= ERROR_SEVERITY()
			  , @ErrState	  INT			= ERROR_STATE()
			  , @ErrMessage	  NVARCHAR(MAX) = ERROR_MESSAGE()
			  , @ErrLine	  INT			= ERROR_LINE();

			SET NOCOUNT OFF;

			RAISERROR(@ErrMessage, @ErrSeverity, @ErrState, @ErrProcedure, @ErrState, @ErrMessage);
		END CATCH;
	END;

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeValueList]';
GO
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeValueList', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSynchronizeValueList'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeValueList]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


alter PROCEDURE [dbo].[spMFSynchronizeValueList] (@VaultSettings       [NVARCHAR](4000)
                                                   ,@Debug          SMALLINT
                                                   ,@Out            [NVARCHAR](max) OUTPUT
												   ,@IsUpdate SMALLINT=0)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Property details  
  **  
  
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTeam2   Removed vault settings parameters and pass them as 
                            comma separated sting in @VaultSettings
  ** 2018-04-04  DevTeam2   Added License module validation code.
  ******************************************************************************/
  BEGIN
      SET NOCOUNT ON

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      --------------------------------------------- 
      DECLARE @Xml     [NVARCHAR] (max)
              ,@Output INT;


	 -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetValueList
     ------------------------------------------------------------------
      EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetValueList','spMFSynchronizeValueList','Checking module access for CLR procdure  spMFGetValueList'

      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET VALUE LIST DETAILS FROM M-FILES
      -------------------------------------------------------------
      EXEC spMFGetValueList
        @VaultSettings
        ,@Xml OUTPUT;

		IF @debug > 10
		SELECT @XML AS ValuelistXML

      -------------------------------------------------------------------------
      -- CALL 'spMFInsertValueList' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      ------------------------------------------------------------------------- 
	  if @IsUpdate=1
	  begin
	    
		Declare @XMLValueList nvarchar(max)
	     Select 
		   ID
		  ,Name
		  ,Alias
          ,MFID
		  ,OwnerID 
         into
		  #TempValueList
		 from
		  MFValueList
		 where
		  Deleted=0

	     EXEC spMFInsertValueList
         @Xml
        ,1 --IsFullUpdate Set to TRUE  
        ,@Output OUTPUT
        ,@Debug;

		set @XMLValueList=( Select 
		   isnull(TMVL.ID,0) as 'ValueListDetails/@ID'
		  ,isnull(TMVL.Name,'') as 'ValueListDetails/@Name'
		  ,isnull(TMVL.Alias,'') as 'ValueListDetails/@Alias'
          ,isnull(TMVL.MFID,0) as 'ValueListDetails/@MFID'
		  ,isnull(TMVL.OwnerID,0) as 'ValueListDetails/@OwnerID'
         from
		  MFValueList MVL inner join #TempValueList TMVL
		 on  
		  MVL.MFID=TMVL.MFID and (MVL.Alias!=TMVL.Alias or MVL.Name!=TMVL.Name)
		 for XML path(''),Root('VList'))

		 Declare @Output1 nvarchar(max)

		  -----------------------------------------------------------------
	       -- Checking module access for CLR procdure  spMFUpdatevalueList
          ------------------------------------------------------------------
          EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdatevalueList','spMFSynchronizeValueList','Checking module access for CLR procdure  spMFUpdatevalueList'

		  exec spMFUpdatevalueList @VaultSettings,@XMLValueList,@Output1 output

		 UPdate 
		   MVL
		  set
		  MVL.Alias=TMVL.Alias,
		  MVL.Name=TMVL.Name
         from
		  MFValueList MVL inner join #TempValueList TMVL
		 on  
		  MVL.MFID=TMVL.MFID

		  drop table #TempValueList

	  End
	  else
	   begin
	    EXEC spMFInsertValueList
         @Xml
        ,1 --IsFullUpdate Set to TRUE  
        ,@Output OUTPUT
        ,@Debug;
	   End
      

		IF @debug > 10
		SELECT @Output AS InsertValuelistOutput

      IF ( @Output > 0 )
        SET @Out = 'All ValueList are Updated'
      ELSE
        SET @Out = 'All ValueList are upto date'

      SET NOCOUNT OFF
  END
  go
  
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeValueListItems]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeValueListItems', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSynchronizeValueListItems'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeValueListItems]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeValueListItems] (@VaultSettings        [NVARCHAR](4000)
                                                        ,@Debug          SMALLINT = 0
                                                        ,@Out            [NVARCHAR](MAX) OUTPUT
														,@MFvaluelistID INT = 0)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File VALUE LIST ITEM details  
  **  
  ** Version: 1.0.0.6
  
  ** Author:			Thejus T V
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2015-3-6    GLC		approach to re-use valuelist item list from M-Files rather than
  					get it for each loop; also to take account of deleted value lists.
  ** 2016-26-09  DevTeam2  Removed vault settings parameters and pass them as comma 
                           separated string in @VaultSettings parameter
	 2018-04-04  DevTeam2  Added License module validation code.
	 2018-5-20	 LC			Delete valuelist items that is deleted in MF
  ******************************************************************************/
  BEGIN
      SET NOCOUNT ON

      DECLARE @ValueListId INT

      -----------------------------------------------------
      -- update mfvaluelistitems for all deleted valuelists
      -----------------------------------------------------
      UPDATE mvli
      SET    deleted = 1
      FROM   MFValueList mvl
             INNER JOIN [dbo].[MFValueListItems] AS [mvli]
                     ON [mvli].[MFValueListID] = [mvl].[ID]
      WHERE  mvl.[Deleted] = 1

	  -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetValueListItems  
      ------------------------------------------------------------------
      EXEC [dbo].[spMFCheckLicenseStatus] 
	                                      'spMFGetValueListItems'
										  ,'spMFSynchronizeValueListItems'
										  ,'Checking module access for CLR procdure  spMFGetValueListItems'

      DECLARE InsertValueLIstItemCursor CURSOR LOCAL FOR
        -----------------------------------------------------
        --Select ValueListId From MFValuelist Table 
        -----------------------------------------------------
        SELECT MFID
        FROM   MFValueList
        WHERE  [Deleted] = 0
		and  [ID] = CASE 
		WHEN @MFvaluelistID = 0 THEN [ID]
		ELSE @MFvaluelistID
		END
		AND [RealObjectType]!=1


      OPEN InsertValueLIstItemCursor

      ----------------------------------------------------------------
      --Select The ValueListId into declared variable '@vlaueListID' 
      ----------------------------------------------------------------
      FETCH NEXT FROM InsertValueLIstItemCursor INTO @ValueListId

      WHILE @@FETCH_STATUS = 0
        BEGIN
            -------------------------------------------------------------------
            --Declare new variable to store the outPut of 'GetMFValueListItems'
            ------------------------------------------------------------------- 
            DECLARE @Xml [NVARCHAR](MAX);

            
DELETE FROM mfvaluelistItems WHERE [MFValueListID] = @ValueListId AND [Deleted] = 1
------------------------------------------------------------------------------------------
            --Execute 'GetMFValueListItems' to get the all MFValueListItems details in xml format 
            ------------------------------------------------------------------------------------------
            EXEC spMFGetValueListItems
               @VaultSettings
              ,@ValueListId
              ,@Xml OUTPUT;

			  IF @debug > 10
			  SELECT @XML AS ValuelistitemXML;

            DECLARE @Output INT;

            ----------------------------------------------------------------------------------------------------------
            --Execute 'InsertMFValueListItems' to insert all property Details into 'MFValueListItems' Table
            ----------------------------------------------------------------------------------------------------------
            EXEC spMFInsertValueListItems
              @Xml
              ,@Output OUTPUT
              ,@Debug; 

			   IF @debug > 10
			  SELECT @Output AS ValuelistitemsInsert;


			  IF EXISTS (Select top 1 * from MFValueListItems where IsNameUpdate=1)
			   Begin
			      
				  EXEC spmfSynchronizeLookupColumnChange

			   ENd

            --------------------------------------------------------------------
            --Select The Next ValueListId into declared variable '@vlaueListID' 
            --------------------------------------------------------------------
            FETCH NEXT FROM InsertValueLIstItemCursor INTO @ValueListId
        END

      -----------------------------------------------------
      --Close the Cursor 
      -----------------------------------------------------
      CLOSE InsertValueLIstItemCursor

      -----------------------------------------------------
      --Deallocate the Cursor 
      -----------------------------------------------------
      DEALLOCATE InsertValueLIstItemCursor

      IF ( @Output > 0 )
        SET @Out = 'All ValueLists are Updated'
      ELSE
        SET @Out = 'All ValueLists are upto date'

      SET NOCOUNT OFF
  END
  go
  
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeWorkflow]';
GO
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeWorkflow', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeWorkflow'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeWorkflow]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFSynchronizeWorkflow]
    (
      @VaultSettings [NVARCHAR](4000) ,
      @Debug SMALLINT ,
      @Out [NVARCHAR](MAX) OUTPUT,
	  @IsUpdate SMALLINT=0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File WORKFLOW details  
  
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2018-04-04  DevTeam2    Added License module validation code
  ******************************************************************************/
    BEGIN
        SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      --------------------------------------------- 
        DECLARE @Xml [NVARCHAR](MAX) ,
            @Output INT ,
            @ProcedureStep NVARCHAR(128) = 'Wrapper - GetWorkflow' ,
            @ProcedureName NVARCHAR(128) = 'spMFSynchronizeWorkflow';
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

      -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetWorkFlow
      ------------------------------------------------------------------
      EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetWorkFlow',@ProcedureName,@ProcedureStep

      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET VALUE LIST DETAILS FROM M-FILES
      -------------------------------------------------------------

        EXEC spMFGetWorkFlow @VaultSettings,
            @Xml OUTPUT;

        SET @ProcedureStep = 'GetWorkflow Returned from wrapper';
	
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep); 

      -------------------------------------------------------------------------
      -- CALL 'spMFInsertValueList' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      ------------------------------------------------------------------------- 

	    if @IsUpdate=1
		 Begin
		     Select ID,Name,Alias,MFID into #TempMFWorkflow from MFWorkflow
		     EXEC spMFInsertWorkflow @Xml, 1 --IsFullUpdate Set to False
            , @Output OUTPUT, @Debug;

			Declare @WorkflowXml nvarchar(max)
			set @WorkflowXml=( Select 
			   isnull(TMWF.ID,0) as 'WorkFlowDetails/@ID'
			  ,isnull(TMWF.Name,0) as 'WorkFlowDetails/@Name'
			  ,isnull(TMWF.Alias,0) as 'WorkFlowDetails/@Alias'
			  ,isnull(TMWF.MFID ,0) as 'WorkFlowDetails/@MFID'
			 from MFWorkflow MWF inner join #TempMFWorkflow TMWF 
			 on MWF.MFID=TMWF.MFID and (MWF.Alias!=TMWF.Alias or MWF.Name=TMWF.Name) for Xml Path(''),Root('WorkFlow'))
			

			-----------------------------------------------------------------
	         -- Checking module access for CLR procdure  spMFUpdateWorkFlow
            ------------------------------------------------------------------
            EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdateWorkFlow',@ProcedureName,@ProcedureStep

			 Declare @OutPut1 nvarchar(max)	
			 exec spMFUpdateWorkFlow @VaultSettings,@WorkflowXml,@OutPut1

			 Update  
			  MWF
             set
			  MWF.Name=TMWF.Name,
			  MWF.Alias=TMWF.Alias
			 from 
			  MFWorkflow MWF inner join #TempMFWorkflow TMWF 
			 on 
			  MWF.MFID=TMWF.MFID 

		 End
		else
		 begin
		     EXEC spMFInsertWorkflow @Xml, 1 --IsFullUpdate Set to False
            , @Output OUTPUT, @Debug;
		 End
       

        SET @ProcedureStep = 'Exec spMFInsertWorkflow'; 

        IF @Debug = 1
            RAISERROR('%s : Step %s Output: %i ',10,1,@ProcedureName, @ProcedureStep, @Output);

        IF ( @Output > 0 )
            SET @Out = 'All Workflow Updated';
        ELSE
            SET @Out = 'All Workflow Are Upto Date';

        SET NOCOUNT OFF;
    END;
  GO
  
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeSpecificMetadata]';
GO


SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeSpecificMetadata'
-- nvarchar(100)
  , @Object_Release = '3.1.3.40'
-- varchar(50)
  , @UpdateFlag = 2;
-- smallint

GO

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINES].[ROUTINE_NAME] = 'spMFSynchronizeSpecificMetadata' --name of procedure
						AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeSpecificMetadata]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeSpecificMetadata]
	(
		@Metadata VARCHAR(100)
	  , @IsUpdate SMALLINT	   = 0
	  , @ItemName VARCHAR(100) = NULL
	  , @Debug	  SMALLINT	   = 0
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize specific M-File Meta data  
 
  ** Author:			Thejus T V
  ** Date:				08-04-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-8-22	 lc	   update settings index
  2016-9-9	 lc	   add login accounts and user accounts
                           provide for slight differences in metadata parameter
  2016-09-26     DevTeam2  Removed vault settings parameters and pass them as 
	                   comma separated string in @VaultSettings parameter
2016-12-08		LC		Add is update as paramter
  ******************************************************************************/
	BEGIN


		---------------------------------------------
		--DECLARE LOCAL VARIABLE
		--------------------------------------------- 
		DECLARE
			@VaultSettings NVARCHAR(4000), @ProcedureStep sysname = 'START', @MFvaluelistID INT = 0;

		---------------------------------------------
		-- ACCESS CREDENTIALS FROM Setting TABLE
		---------------------------------------------

		SELECT	@VaultSettings = [dbo].[FnMFVaultSettings]();


		SET @Metadata = CASE WHEN @Metadata LIKE 'Class%' THEN 'Class'
							 WHEN @Metadata LIKE 'Proper%' THEN 'Properties'
							 WHEN @Metadata LIKE 'Valuelist' THEN 'Valuelist'
							 WHEN @Metadata LIKE '%Item%' THEN 'Valuelistitems'
							 WHEN @Metadata LIKE 'Valuelist%' THEN 'Valuelist'
							 WHEN @Metadata LIKE 'Workflow' THEN 'Workflow'
							 WHEN @Metadata LIKE '%Stat%' THEN 'States'
							 WHEN @Metadata LIKE 'Object%' THEN 'ObjectType'
							 WHEN @Metadata LIKE 'Login%' THEN 'LoginAccount'
							 WHEN @Metadata LIKE 'User%' THEN 'UserAccount'
							 ELSE NULL
						END;

		BEGIN
			BEGIN TRY
				-- BEGIN TRANSACTION;
				---------------------------------------------
				--DECLARE LOCAL VARIABLE
				--------------------------------------------- 
				DECLARE
					@ResponseMFObject		NVARCHAR(2000)
				  , @ResponseProperties		NVARCHAR(2000)
				  , @ResponseValueList		NVARCHAR(2000)
				  , @ResponseValuelistItems NVARCHAR(2000)
				  , @ResponseWorkflow		NVARCHAR(2000)
				  , @ResponseWorkflowStates NVARCHAR(2000)
				  , @ResponseMFClass		NVARCHAR(2000)
				  , @ResponseLoginAccount	NVARCHAR(2000)
				  , @ResponseuserAccount	NVARCHAR(2000)
				  , @Response				NVARCHAR(2000)
				  , @SPName					NVARCHAR(100)
				  , @Return_Value			INT;

				IF @Metadata = 'ObjectType'
					BEGIN
						---------------------------------------------
						--SYNCHRONIZE OBJECT TYPES
						---------------------------------------------
						SELECT
							@ProcedureStep = 'Synchronizing ObjectType', @SPName = 'spMFSynchronizeObjectType';

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeObjectType]
							@VaultSettings, @Debug, @ResponseMFObject OUTPUT, @IsUpdate;
					END;

				IF @Metadata = 'LoginAccount'
					BEGIN
						---------------------------------------------
						--SYNCHRONIZE login accounts
						---------------------------------------------
						SELECT
							@ProcedureStep = 'Synchronizing Login Accoount', @SPName = 'spMFSynchronizeLoginAccounte';

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeLoginAccount]
							@VaultSettings, @Debug, @ResponseLoginAccount OUTPUT;
					END;


				IF @Metadata = 'UserAccount'
					BEGIN
						---------------------------------------------
						--SYNCHRONIZEuser accounts
						---------------------------------------------
						SELECT
							@ProcedureStep = 'Synchronizing UserAccount', @SPName = 'spMFSynchronizeUserAccount';

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeUserAccount]
							@VaultSettings, @Debug, @ResponseMFObject OUTPUT;
					END;


				---------------------------------------------
				--SYNCHRONIZE PROEPRTY
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing Properties', @SPName = 'spMFSynchronizeProperties';

				IF @Metadata = 'Properties'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeProperties]
							@VaultSettings, @Debug, @ResponseProperties OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE VALUE LIST
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing ValueList', @SPName = 'spMFSynchronizeValueList';

				IF @Metadata = 'ValueList'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeValueList]
							@VaultSettings, @Debug, @ResponseValueList OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE VALUELIST ITEMS
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing ValueList Items', @SPName = 'spMFSynchronizeValueListItems';

				IF @Metadata = 'ValueListItems'
					BEGIN
						--print @Metadata

						--Task 1046
						IF @ItemName IS NOT NULL
							BEGIN
								SELECT	@MFvaluelistID = ISNULL([ID], 0)
								FROM	[MFValueList]
								WHERE	[Name] = @ItemName;

							END;
						--print @ItemName 
						--print @MFvaluelistID

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeValueListItems]
							@VaultSettings, @Debug, @ResponseValuelistItems OUTPUT, @MFvaluelistID;

					END;

				---------------------------------------------
				--SYNCHRONIZE WORKFLOW
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing workflow', @SPName = 'spMFSynchronizeWorkflow';

				IF @Metadata = 'Workflow'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeWorkflow]
							@VaultSettings, @Debug, @ResponseWorkflow OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE WORKFLOW STATES
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing Workflow states', @SPName = 'spMFSynchronizeWorkflowsStates';

				IF @Metadata LIKE 'State%'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeWorkflowsStates]
							@VaultSettings, @Debug, @ResponseWorkflowStates OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE Class
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing Class', @SPName = 'spMFSynchronizeClasses';

				IF @Metadata = 'Class'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeClasses]
							@VaultSettings, @Debug, @ResponseMFClass OUTPUT, @IsUpdate;

					--IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NULL )
					--                BEGIN

					--                    ALTER TABLE [dbo].[MFClassProperty]
					--                    WITH CHECK  ADD CONSTRAINT [FK_MFClassProperty_MFClass] FOREIGN KEY ([MFClass_ID]) REFERENCES [dbo].[MFClass]([ID]);

					--                END;

					END;

				DECLARE @ProcessStep VARCHAR(100);
				SELECT	@ProcessStep = 'END Syncronise specific metadata';


				IF @Debug > 0
					BEGIN
						RAISERROR('Step %s Return %i', 10, 1, @ProcessStep, @Return_Value);
					END;

				
				IF @Metadata = NULL
					BEGIN
						PRINT 'Invalid Selection';
						RETURN -1;
					END;
				ELSE RETURN 1;
				SET NOCOUNT OFF;
			--COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
--				ROLLBACK TRANSACTION;

				INSERT INTO [dbo].[MFLog] ( [SPName]
										  , [ProcedureStep]
										  , [ErrorNumber]
										  , [ErrorMessage]
										  , [ErrorProcedure]
										  , [ErrorState]
										  , [ErrorSeverity]
										  , [ErrorLine]
										  )
				VALUES (
						   @SPName
						 , @ProcedureStep
						 , ERROR_NUMBER()
						 , ERROR_MESSAGE()
						 , ERROR_PROCEDURE()
						 , ERROR_STATE()
						 , ERROR_SEVERITY()
						 , ERROR_LINE()
					   );

				RETURN 2;
			END CATCH;
		END;
	END;

GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFClassTableSynchronize]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFClassTableSynchronize', -- nvarchar(100)
    @Object_Release = '3.1.4.40', -- varchar(50)
    @UpdateFlag = 2 -- smallint



/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Syncronise specific class table
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-23		lc			change Objids to NVARCHAR(4000)
	2016-12-20		ac			TFS 972: Comment out EXTRA BEGIN TRAN 
	2017-11-23		lc			localization of MF_LastModified date
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFClassTableSynchronize]    @debug = 2
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFClassTableSynchronize'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFClassTableSynchronize]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

/****** Object:  StoredProcedure [dbo].[spMFClassTableSynchronize]    Script Date: 01/03/2016 05:25:58 ******/


ALTER PROC [dbo].[spMFClassTableSynchronize]
    @TableName sysname ,
    @Debug SMALLINT = 0
AS /**************************Update procedure for table change*/
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Process_ID INT ,
            @UpdateMethod INT ,
            @ProcedureName VARCHAR(100) = 'spMFClassTableSynchronize' ,
            @ProcedureStep VARCHAR(100) = 'Start' ,
            @Result_Value INT ,
            @TableLastModified DATETIME ,
            @SQL NVARCHAR(MAX) ,
            @Params NVARCHAR(MAX);

 DECLARE @lastModifiedColumn NVARCHAR(100)

	SELECT @lastModifiedColumn = [mp].[ColumnName] FROM [dbo].[MFProperty] AS [mp] WHERE MFID = 21 --'Last Modified'


        SET @ProcedureStep = 'Get last Modified date';

        SET @SQL = N'Select top 1 @TableLastModified = Max('+ QUOTENAME(@lastModifiedColumn) + ') from '
            + QUOTENAME(@TableName);
        SET @Params = N'@TableLastModified datetime output';

        EXEC sp_executesql @SQL, @Params,
            @TableLastModified = @TableLastModified;

        IF @Debug > 0
            BEGIN
                DECLARE @DateString VARCHAR(50);
                SET @DateString = CAST(@TableLastModified AS VARCHAR(50));
                RAISERROR('Proc: %s Step: %s Table Last Update %s ',10,1,@ProcedureName, @ProcedureStep, @DateString);
            END;

   
        BEGIN TRY

		/*--BEGIN BUG 972 2016-12-20 AC 
            BEGIN TRANSACTION; 
            SET @UpdateMethod = 1;

		-- END BUG 972 2016-12-20 AC  */

            BEGIN TRANSACTION;
            
            SET @UpdateMethod = 0;
            SET @ProcedureStep = 'Transaction Update method'
			;

            EXEC @Result_Value = [dbo].[spMFUpdateTable] @MFTableName = @TableName, -- nvarchar(128)
                @UpdateMethod = @UpdateMethod, -- int
                @UserId = NULL, -- nvarchar(200)
                @MFModifiedDate = NULL,--NULL to select all records
                @ObjIDs = NULL, @Debug = 0; -- smallint

            SELECT  @Result_Value;

            COMMIT TRAN;
            
            IF @Debug > 0
                BEGIN
                    SELECT  @Result_Value;
                    RAISERROR('Proc: %s Step: %s Table update method 0 with result %i ',10,1,@ProcedureName, @ProcedureStep, @Result_Value);
                END;

               
            RETURN @Result_Value;
        END TRY
        BEGIN CATCH
            --ROLLBACK; --BUG 972 2016-12-20 AC 
            RAISERROR('Updating of Table failed %s: updatemethod %i: With Error %i',16,1,@TableName,@UpdateMethod,@Result_Value) WITH NOWAIT;
            IF @@TRANCOUNT <> 0
                BEGIN
                    ROLLBACK TRANSACTION;
                END;

            SET NOCOUNT ON;

           -- UPDATE  MFUpdateHistory
           -- SET     UpdateStatus = 'failed'
           -- WHERE   Id = @Update_ID;

           -- INSERT  INTO MFLog
           --         ( SPName ,
           --           ErrorNumber ,
           --           ErrorMessage ,
           --           ErrorProcedure ,
           --           ProcedureStep ,
           --           ErrorState ,
           --           ErrorSeverity ,
           --           Update_ID ,
           --           ErrorLine
			        --)
           -- VALUES  ( @ProcedureName ,
           --           ERROR_NUMBER() ,
           --           ERROR_MESSAGE() ,
           --           ERROR_PROCEDURE() ,
           --           @ProcedureStep ,
           --           ERROR_STATE() ,
           --           ERROR_SEVERITY() ,
           --           null ,
           --           ERROR_LINE()
           --         );

            IF @Debug > 0
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

            RETURN 2; --For More information refer Process Table
	   
	   
        END CATCH;
	    
    END;

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeWorkflowsStates]';
GO


SET NOCOUNT ON;
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeWorkflowsStates', -- nvarchar(100)
    @Object_Release = '4.2.7.46',                    -- varchar(50)
    @UpdateFlag = 2;                                 -- smallint
-- smallint

GO

IF EXISTS
    (
        SELECT
            1
        FROM
            [INFORMATION_SCHEMA].[ROUTINES]
        WHERE
            [ROUTINE_NAME] = 'spMFSynchronizeWorkflowsStates' --name of procedure
            AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
            AND [ROUTINE_SCHEMA] = 'dbo'
    )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeWorkflowsStates]
AS
    SELECT
        'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeWorkflowsStates]
    (
        @VaultSettings [NVARCHAR](4000),
        @Debug         SMALLINT,
        @Out           [NVARCHAR](MAX) OUTPUT,
        @IsUpdate      SMALLINT        = 0
    )
AS
    /*******************************************************************************
** Desc:  The purpose of this procedure is to synchronize M-File WORKFLOW STATE details  
**  
** Date:				27-03-2015
********************************************************************************
** Change History
********************************************************************************
** Date        Author     Description
** ----------  ---------  -----------------------------------------------------
** 2016-09-26  DevTeam2   Removed vault settings parameters and pass them as 
                          Comma separated string in @VaultSettings parmeter.
   2018-04-04  DevTeam2   Added License module validation code 
   2018-11-15	LC			remove logging 
******************************************************************************/
    -- ==============================================
    
	BEGIN
        SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = 'ClassTable'
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Sync Workflow States')

		-------------------------------------------------------------
		-- CONSTATNS: MFSQL Global 
		-------------------------------------------------------------
		DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1
		DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0
		DECLARE @Process_ID_1_Update TINYINT = 1
		DECLARE @Process_ID_6_ObjIDs TINYINT = 6 --marks records for refresh from M-Files by objID vs. in bulk
		DECLARE @Process_ID_9_BatchUpdate TINYINT = 9 --marks records previously set as 1 to 9 and update in batches of 250
		DECLARE @Process_ID_Delete_ObjIDs INT = -1 --marks records for deletion
		DECLARE @Process_ID_2_SyncError TINYINT = 2
		DECLARE @ProcessBatchSize INT = 250

		-------------------------------------------------------------
		-- VARIABLES: MFSQL Processing
		-------------------------------------------------------------
		DECLARE @Update_ID INT
		DECLARE @MFLastModified DATETIME
		DECLARE @Validation_ID int
		DECLARE @ProcessBatch_ID int

		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFSynchronizeWorkflowsStates';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

		-------------------------------------------------------------
		-- VARIABLES: LOGGING
		-------------------------------------------------------------
		DECLARE @LogType AS NVARCHAR(50) = 'Status'
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) = 'Started'

		DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
		DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL

		DECLARE @LogColumnName AS NVARCHAR(128) = NULL
		DECLARE @LogColumnValue AS NVARCHAR(256) = NULL

		DECLARE @count INT = 0;
		DECLARE @Now AS DATETIME = GETDATE();
		DECLARE @StartTime AS DATETIME = GETUTCDATE();
		DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
		DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

		-------------------------------------------------------------
		-- VARIABLES: DYNAMIC SQL
		-------------------------------------------------------------
		DECLARE @sql NVARCHAR(MAX) = N''
		DECLARE @sqlParam NVARCHAR(MAX) = N''


	
        DECLARE
            @Xml           [NVARCHAR](MAX),
            @Output        INT

        IF @Debug = 1
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
  
  BEGIN TRY
       
	   CREATE TABLE #TempMFWorkflowState
	   (ID INT, Name NVARCHAR(100), Alias NVARCHAR(100), MFID INT, MFWorkflowID INT)
        ---------------------------------------------------
        --  LOCAL VARIABLE DECLARATION
        ---------------------------------------------------
        --  if( @IsUpdate =1)
        -- Begin
        INSERT INTO [#TempMFWorkflowState]
            (
                [ID],
                [Name],
                [Alias],
                [MFID],
                [MFWorkflowID]
            )
       
		SELECT
            [MFWFS].[ID],
            [MFWFS].[Name],
            [MFWFS].[Alias],
            [MFWFS].[MFID],
            [MFWF].[MFID] AS [MFWorkflowID]
       
        FROM
            [MFWorkflowState] AS [MFWFS]
            INNER JOIN
                [MFWorkflow]  AS [MFWF]
                    ON [MFWFS].[MFWorkflowID] = [MFWF].[ID]
        WHERE
            [MFWF].[Deleted] = 0;

	    --	 End
    DECLARE @WorkflowID INT;

        

		-----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetWorkFlowState
        ------------------------------------------------------------------
        EXEC [dbo].[spMFCheckLicenseStatus] 
		                                    'spMFGetWorkFlowState'
											,@ProcedureName
											,@ProcedureStep



        DECLARE [InsertWorkflowsStatesCursor] CURSOR LOCAL FOR
            -----------------------------------------------------
            --Select WorkflowID From WorkflowsToInclude  Table
            -----------------------------------------------------
            SELECT
                [MFID]
            FROM
                [MFWorkflow];


        OPEN [InsertWorkflowsStatesCursor];
        SET @ProcedureStep = 'Open cursor update 0';
        
           
	    SET @ProcedureStep = 'Workfow start ';
		SET @DebugText = @DefaultDebugText + 'Workflow :%d ' 

        IF @Debug = 1
            RAISERROR(@Debugtext, 10, 1, @ProcedureName, @ProcedureStep,@WorkflowID);


        ------------------------------------------------------------
        --Select The WorkflowID into declared variable '@WorkflowID'
        ------------------------------------------------------------
        FETCH NEXT FROM [InsertWorkflowsStatesCursor]
        INTO
            @WorkflowID;


        WHILE @@FETCH_STATUS = 0
            BEGIN
                -------------------------------------------------------------------
                --Declare new variable to store the outPut of 'GetMFValueListItems'
                -------------------------------------------------------------------

                ------------------------------------------------------------------------------------
                --Execute 'GetMFWorkFlowState' to get the all WorkflowsStates details in xml format
                ------------------------------------------------------------------------------------
				IF @debug = 1
				SELECT ID,mfid FROM [dbo].[MFWorkflow] AS [mw] WHERE MFID = @WorkflowID AND [mw].[Deleted] = 0;

                EXEC [spMFGetWorkFlowState]
                    @VaultSettings,
                    @WorkflowID,
                    @Xml OUTPUT;

					
                SET @ProcedureStep = 'GetWorkflowStates Returned from wrapper';

                IF @Debug = 1
				begin
				SELECT CAST(@Xml AS XML)
					
                    RAISERROR('%s : Step %s for Workflow_ID: %i', 10, 1, @ProcedureName, @ProcedureStep, @WorkflowID);

				END



                ----------------------------------------------------------------------------------------------------------
                --Execute 'InsertMFWorkFlowState' to insert all property Details into 'MFValueListItems' Table
                ----------------------------------------------------------------------------------------------------------

                EXEC [spMFInsertWorkflowState]
                    @Xml,
                    @Output OUTPUT,
                    @Debug;


                SET @ProcedureStep = 'Exec spMFInsertWorkflowStates';

                IF @Debug = 1
                    RAISERROR('%s : Step %s Output: %i ', 10, 1, @ProcedureName, @ProcedureStep, @Output);
                ------------------------------------------------------------------
                --      Select The Next WorkflowID into declared variable '@WorkflowID'
                ------------------------------------------------------------------
                FETCH NEXT FROM [InsertWorkflowsStatesCursor]
                INTO
                    @WorkflowID;
            END;

        -----------------------------------------------------
        --Close the Cursor
        -----------------------------------------------------
        CLOSE [InsertWorkflowsStatesCursor];

        -----------------------------------------------------
        --Deallocate the Cursor
        -----------------------------------------------------
        DEALLOCATE [InsertWorkflowsStatesCursor];
        IF (@IsUpdate = 1)
            BEGIN
                SET @ProcedureStep = 'Update workflow and states';
                IF @Debug = 1
                    RAISERROR('%s : Step %s workflow id: %i ', 10, 1, @ProcedureName, @ProcedureStep, @Output);

                DECLARE @WorkFlowStateXML NVARCHAR(MAX);
                SET @WorkFlowStateXML =
                    (
                        SELECT
                            ISNULL([TMFWFS].[ID], 0)           AS [WorkFlowStateDetails/@ID],
                            ISNULL([TMFWFS].[Name], '')        AS [WorkFlowStateDetails/@Name],
                            ISNULL([TMFWFS].[Alias], '')       AS [WorkFlowStateDetails/@Alias],
                            ISNULL([TMFWFS].[MFID], 0)         AS [WorkFlowStateDetails/@MFID],
                            ISNULL([TMFWFS].[MFWorkflowID], 0) AS [WorkFlowStateDetails/@MFWorkflowID]
                        FROM
                            [MFWorkflowState]          AS [MFWFS]
                            INNER JOIN
                                [#TempMFWorkflowState] AS [TMFWFS]
                                    ON [MFWFS].[MFID] = [TMFWFS].[MFID]
                                       AND
                                           (
                                               [MFWFS].[Name] != [TMFWFS].[Name]
                                               OR [MFWFS].[Alias] != [TMFWFS].[Alias]
                                           )
                        FOR XML PATH(''), ROOT('WorkFlowState')
                    );


                -----------------------------------------------------------------
	              -- Checking module access for CLR procdure  spMFUpdateWorkFlowState
                ------------------------------------------------------------------
                 EXEC [dbo].[spMFCheckLicenseStatus] 
		                                    'spMFUpdateWorkFlowState'
											,@ProcedureName
											,@ProcedureStep

                DECLARE @Outpout1 NVARCHAR(MAX);
                EXEC [spMFUpdateWorkFlowState]
                    @VaultSettings,
                    @WorkFlowStateXML,
                    @Outpout1 OUT;
                SET @ProcedureStep = 'Update MFWorkflowstate with results';
                IF @Debug = 1
                    RAISERROR('%s : Step %s Output: %i ', 10, 1, @ProcedureName, @ProcedureStep, @Output);

                UPDATE
                    [MFWFS]
                SET
                    [MFWFS].[Name] = [TMFWFS].[Name],
                    [MFWFS].[Alias] = [TMFWFS].[Alias]
                FROM
                    [MFWorkflowState]          AS [MFWFS]
                    INNER JOIN
                        [#TempMFWorkflowState] AS [TMFWFS]
                            ON [MFWFS].[MFID] = [TMFWFS].[MFID];

                DROP TABLE [#TempMFWorkflowState];
            END;

        IF (@Output > 0)
            SET @Out = 'All WorkFlowState are Updated';
        ELSE
            SET @Out = 'All WorkFlowState are upto date';

        SET NOCOUNT OFF;
    
		

	RETURN 1
	END try
BEGIN CATCH

				SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			  , @ProcessType = @ProcessType
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN -1
		END CATCH


END

GO

    


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeValueListItemsToMfiles]';
GO

SET NOCOUNT ON 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeValueListItemsToMFiles'
  , -- nvarchar(100)
    @Object_Release = '3.1.5.41'
  , -- varchar(50)
    @UpdateFlag = 2
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFSynchronizeValueListItemsToMFiles'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update'
         SET NOEXEC ON
   END
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeValueListItemsToMFiles]
AS
       SELECT   'created, but not implemented yet.'
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO



ALTER PROCEDURE [dbo].[spMFSynchronizeValueListItemsToMFiles] (  @Debug SMALLINT = 0)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize Sql  VALUE LIST ITEM details to M-files
  **  
  ** Processing Steps:
  **					1.) Set deleted = 1 ,if value list is deletd
  **					2.) Using cursor select the value id from MFValueList and get the valueList Items from SQl 
  **					3.) Insert the value list items into M-Files using CLR procedure
  **					4.) fetch the next value list id using cursor and continue from step 2
  **
  ** Parameters and acceptable values: 
  **					@UpdateMethod  int
  **					
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					
  **
  ** Called By:			
  **
  ** Calls:           
  **														
  **
  ** Author:			DevTeam2(Rheal)
  ** Date:				21-10-2016
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
     2018-04-04   DEV 2     Added Licensing module validation code
  ******************************************************************************/
      BEGIN
            SET NOCOUNT ON

            DECLARE @ID INT
                  , @VaultSettings [NVARCHAR](4000)
                  , @Count INT

            CREATE TABLE [#TempMFID] ( [ID] INT )
			if(@Debug=1)
			 print '#TempMFID is Created'
            BEGIN TRY
		------------------------------------------------------------------------
		--Getting Vault settings

                  SELECT    @VaultSettings = [dbo].[FnMFVaultSettings]()

                  SET @Count = 0
            if(@Debug=1)
		     print 'Inserting Process_ID!=0 records into #TempMFID'

                           INSERT   INTO [#TempMFID]
                                    ( [ID]
                                    )
                                    SELECT  [MVLI].[ID]
                                    FROM    [dbo].[MFValueListItems] [MVLI]
                                    INNER JOIN [dbo].[MFValueList] [MVL] ON [MVLI].[MFValueListID] = [MVL].[ID]
									and MVL.MFID>100
                                    WHERE   [MVLI].[Process_ID] != 0
                                            AND [MVLI].[Deleted] = 0 
                  
                  DECLARE [SynchValueLIstItemCursor] CURSOR LOCAL
                  FOR
                          ----------------------------------------------------
		--Select ID From MFValuelistItem Table 
		-----------------------------------------------------
	     SELECT [#TempMFID].[ID]
         FROM   [#TempMFID]
	  
                  OPEN [SynchValueLIstItemCursor]

		----------------------------------------------------------------
		--Select The ValueListId into declared variable '@vlaueListID' 
		----------------------------------------------------------------
                  FETCH NEXT FROM [SynchValueLIstItemCursor] INTO @ID

                  WHILE @@FETCH_STATUS = 0
                        BEGIN
                              DECLARE @Xml NVARCHAR(MAX)
                                    , @Result NVARCHAR(MAX)
						
		------------------------------------------------------------------------
		--Creating xml of ValueListItem which going to synch in M-Files

		   DECLARE @MFValueListID int ,@DisplayIDProp NVARCHAR(200),@Name NVARCHAR(200)
		   DeClare @ErrMsg NVARCHAR(500),@ValueListName NVARCHAR(200)
		   Select @MFValueListID=MVLI.MFValueListID,@DisplayIDProp=MVLI.DisplayID,@Name=Name from MFValueListItems MVLI where ID = @ID


			if EXISTS (Select * from MFValueListItems where ID!=@ID and MFValueListID=@MFValueListID and Name=@Name)
			 Begin
			     
				 Select @ValueListName=Name from MFValueList where ID=@MFValueListID
				 
			      select @ErrMsg='ValueListItem can not be added with Duplicate Name property= ' + @Name +' for ValueList ' + @ValueListName

								     

								          RAISERROR (
											'Proc: %s Step: %s ErrorInfo %s '
											,16
											,1
											,'spMFSynchronizeValueListItemsToMFiles'
											,'Checking for duplicate Name property'
											, @ErrMsg
						                     );
			 End

			 if EXISTS (Select * from MFValueListItems where ID!=@ID and MFValueListID=@MFValueListID and DisplayID=@DisplayIDProp)
			 Begin
			  
				 Select @ValueListName=Name from MFValueList where ID=@MFValueListID
				 
			      select @ErrMsg='ValueListItem can not be added with Duplicate DisplayID property= ' + @DisplayIDProp +' for ValueList ' + @ValueListName

								     

								          RAISERROR (
											'Proc: %s Step: %s ErrorInfo %s '
											,16
											,1
											,'spMFSynchronizeValueListItemsToMFiles'
											,'Checking for duplicate DisplayID property'
											, @ErrMsg
						                     );
			 End


                              SET @Xml = ( SELECT   [MVLI].[ID] AS 'ValueListItem/@Sql_ID'
                                                  , [MVL].[MFID] AS 'ValueListItem/@MFValueListID'
                                                  , [MVLI].[MFID] AS 'ValueListItem/@MFID'
                                                  , [MVLI].[Name] AS 'ValueListItem/@Name'
                                                  , [MVLI].[OwnerID] AS 'ValueListItem/@Owner'
                                                  , [MVLI].[DisplayID] AS 'ValueListItem/@DisplayID'
                                                  , [MVLI].[ItemGUID] AS 'ValueListItem/@ItemGUID'
                                                  , [MVLI].[Process_ID] AS 'ValueListItem/@Process_ID'
                                           FROM     [dbo].[MFValueListItems] [MVLI]
                                           INNER JOIN [dbo].[MFValueList] [MVL] ON [MVLI].[MFValueListID] = [MVL].[ID]
                                           WHERE    [MVLI].[ID] = @ID
                                         FOR
                                           XML PATH('')
                                             , ROOT('VLItem')
                                         )
 
				IF @Debug > 10
				SELECT @XML AS 'inputXML';
		-------------------------------------------------------------------------

		-- Calling CLR Procedure to synch items into M-Files from sql
		                      -----------------------------------------------------------------
								-- Checking module access for CLR procdure  spMFSynchronizeValueListItemsToMFilesInternal
						       ------------------------------------------------------------------
						     EXEC [dbo].[spMFCheckLicenseStatus] 
							      'spMFSynchronizeValueListItemsToMFilesInternal'
								  ,'spMFSynchronizeValueListItemsToMFiles'
								  ,'Checking module access for CLR procdure  spMFSynchronizeValueListItemsToMFilesInternal'

		--print @Xml
                              EXEC [dbo].[spMFSynchronizeValueListItemsToMFilesInternal]
                                @VaultSettings
                              , @Xml
                              , @Result OUTPUT
		-----------------------------------------------------------------------
                              DECLARE @XmlOut XML
                              SET @XmlOut = @Result

				IF @Debug > 10
				SELECT @XMLOut AS 'inputXML';


                              CREATE TABLE [#ValueListItemTemp]
                                     (
                                       [Name] VARCHAR(100) --COLLATE Latin1_General_CI_AS
                                     , [MFID] VARCHAR(20) --COLLATE Latin1_General_CI_AS
                                     , [MFValueListID] INT
                                     , [OwnerID] INT
                                     , [DisplayID] NVARCHAR(200)
                                     , [ItemGUID] NVARCHAR(200)
                                     )
           
                              INSERT    INTO [#ValueListItemTemp]
                                        ( [Name]
                                        , [MFValueListID]
                                        , [MFID]
                                        , [OwnerID]
                                        , [DisplayID]
                                        , [ItemGUID]
			                            )
                                        SELECT  [t].[c].[value]('(@Name)[1]', 'NVARCHAR(100)') AS [NAME]
                                              , [t].[c].[value]('(@MFValueListID)[1]', 'INT') AS [MFValueListID]
                                              , [t].[c].[value]('(@MFID)[1]', 'INT') AS [MFID]
                                              , [t].[c].[value]('(@Owner)[1]', 'INT') AS [OwnerID]
                                              , [t].[c].[value]('(@DisplayID)[1]', 'nvarchar(200)')
                                              , [t].[c].[value]('(@ItemGUID)[1]', 'nvarchar(200)')
                                        FROM    @XmlOut.[nodes]('/VLItem/ValueListItem') AS [t] ( [c] )
    
                              DECLARE @ProcessID INT

                              SELECT    @ProcessID = [MFValueListItems].[Process_ID]
                              FROM      [dbo].[MFValueListItems]
                              WHERE     [MFValueListItems].[ID] = @ID

		-----------Mark as deleted----------------------------
                              IF @ProcessID = 2
                                 BEGIN
                                       UPDATE   [dbo].[MFValueListItems]
                                       SET      [MFValueListItems].[Deleted] = 1
                                       WHERE    [MFValueListItems].[ID] = @ID
                                 END

		--------------------Set Process_ID=0 after synch ValueListItem--------------
		                
							    UPDATE    [dbo].[MFValueListItems]
                              SET       [MFValueListItems].[Process_ID] = 0
                              WHERE     [MFValueListItems].[ID] = @ID
						
							
                            

		--------------------set MFID and GUID and DisplayID--------------------------

                              DECLARE @OwnerID INT
                                    , @MFID INT
                                    , @DisplayID NVARCHAR(400)
                                    , @ItemGUID NVARCHAR(400)
									, @ValueListMFID int

							  select @ValueListMFID=MFVL.MFID 
							  from MFValueListItems MFVLI inner join MFValueList MFVL on MFVLI.MFValueListID=MFVL.ID 
							  Where MFVLI.ID=@ID

                              SELECT    @MFID = [MFValueListItems].[MFID]
                              FROM      [dbo].[MFValueListItems]
                              WHERE     [MFValueListItems].[ID] = @ID

                              IF @MFID = 0
                                 OR @MFID IS NULL
                                 BEGIN
                                       SELECT   @OwnerID = [#ValueListItemTemp].[OwnerID]
                                              , @MFID = [#ValueListItemTemp].[MFID]
                                              , @DisplayID = [#ValueListItemTemp].[DisplayID]
                                              , @ItemGUID = [#ValueListItemTemp].[ItemGUID]
                                       FROM     [#ValueListItemTemp]

                                       UPDATE   [dbo].[MFValueListItems]
                                       SET     -- [MFValueListItems].[OwnerID] = @OwnerID
                                               [MFValueListItems].[MFID] = @MFID
                                              , [MFValueListItems].[DisplayID] = @DisplayID
                                              , [MFValueListItems].[ItemGUID] = @ItemGUID
                                              , [MFValueListItems].[AppRef] = CASE WHEN [OwnerID] = 7 THEN '0#'
                                                              WHEN [OwnerID] = 0 THEN '2#'
                                                              WHEN [OwnerID] IN ( SELECT  [MFValueList].[MFID]
                                                                                FROM    [dbo].[MFValueList] ) THEN '2#'
                                                              ELSE '1#'
                                                         END + CAST(@ValueListMFID AS NVARCHAR(5)) + '#'
                                                + CAST(@MFID AS NVARCHAR(10))
                                              , [MFValueListItems].[Owner_AppRef] = CASE WHEN [OwnerID] = 7 THEN '0#'
                                                                    WHEN [OwnerID] = 0 THEN '2#'
                                                                    WHEN [OwnerID] IN ( SELECT    [MFValueList].[MFID]
                                                                                      FROM      [dbo].[MFValueList] ) THEN '2#'
                                                                    ELSE '1#'
                                                               END + CAST([OwnerID] AS NVARCHAR(5)) + '#'
                                                + CAST([OwnerID] AS NVARCHAR(10))
                                       WHERE    [ID] = @ID
                                 END



                              DROP TABLE [#ValueListItemTemp]

                              SET @Count = @Count + 1
                              FETCH NEXT FROM [SynchValueLIstItemCursor] INTO @ID
                        END

		-----------------------------------------------------
		--Close the Cursor 
		-----------------------------------------------------
                  CLOSE [SynchValueLIstItemCursor]

		-----------------------------------------------------
		--Deallocate the Cursor 
		-----------------------------------------------------
                  DEALLOCATE [SynchValueLIstItemCursor]
                  DROP TABLE [#TempMFID]

				  RETURN 1

            END TRY
            BEGIN CATCH

                  DROP TABLE [#TempMFID]
                  UPDATE    [dbo].[MFValueListItems]
                  SET       [MFValueListItems].[Process_ID] = 3
                  WHERE     [MFValueListItems].[ID] = @ID




                  INSERT    INTO [dbo].[MFLog]
                            ( [SPName]
                            , [ErrorNumber]
                            , [ErrorMessage]
                            , [ErrorProcedure]
                            , [ProcedureStep]
                            , [ErrorState]
                            , [ErrorSeverity]
                            , [Update_ID]
                            , [ErrorLine]
		                    )
                  VALUES    ( 'spMFSynchronizeValueListItemsToMfile'
                            , ERROR_NUMBER()
                            , ERROR_MESSAGE()
                            , ERROR_PROCEDURE()
                            , ''
                            , ERROR_STATE()
                            , ERROR_SEVERITY()
                            , @ID
                            , ERROR_LINE()
                            );
			
			RETURN -1

            END CATCH

      END

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFVaultConnectionTest]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFVaultConnectionTest' -- nvarchar(100)
                                    ,@Object_Release = '4.3.9.48'             -- varchar(50)
                                    ,@UpdateFlag = 2;                         -- smallint
GO

/*

Add license check into connection test
Add check and update MFVersion if invalid
add is silent option

*/
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFVaultConnectionTest' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFVaultConnectionTest]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFVaultConnectionTest]
    @IsSilent INT = 0
   ,@MessageOut NVARCHAR(250) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    /*
Procedure to perform a test on the vault connection

Created by : Leroux@lamininsolutions.com
Date: 2016-8

Usage

Exec  spMFVaultConnectionTest 

*/
    SET NOCOUNT ON;

    DECLARE @Return_Value INT;
    DECLARE @vaultsettings NVARCHAR(4000)
           ,@ReturnVal     NVARCHAR(MAX);

    SELECT @vaultsettings = [dbo].[FnMFVaultSettings]();

    BEGIN TRY
        DECLARE @IsUpToDate BIT
               ,@RC         INT;

        EXEC @RC = [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

        IF @RC < 0
        BEGIN
            SET @MessageOut = 'Unable to Connect';
		--	SELECT @MessageOut

            RAISERROR('Error:  %s - Check MFlog or email for error detail', 16, 1, @MessageOut)
			RETURN;
        END;

        --SELECT @rc, @IsUpToDate

        -------------------------------------------------------------
        -- validate MFiles version
        -------------------------------------------------------------
        EXEC [dbo].[spMFCheckAndUpdateAssemblyVersion];

        -------------------------------------------------------------
        -- validate login
        -------------------------------------------------------------

        --EXEC [dbo].[spMFGetUserAccounts] @VaultSettings = @vaultsettings -- nvarchar(4000)
        --                                ,@returnVal = @ReturnVal OUTPUT; -- nvarchar(max)
        IF @IsSilent = 0
        BEGIN
            SELECT [mvs].[Username]
                  ,[mvs].[Password] AS [EncryptedPassword]
                  ,[mvs].[Domain]
                  ,[mvs].[NetworkAddress]
                  ,[mvs].[VaultName]
                  ,[mat].[AuthenticationType]
                  ,[mpt].[ProtocolType]
                  ,[mvs].[Endpoint]
            FROM [dbo].[MFVaultSettings]                AS [mvs]
                INNER JOIN [dbo].[MFAuthenticationType] AS [mat]
                    ON [mat].[ID] = [mvs].[MFAuthenticationType_ID]
                INNER JOIN [dbo].[MFProtocolType]       AS [mpt]
                    ON [mpt].[ID] = [mvs].[MFProtocolType_ID];

            SET @MessageOut = 'Successfully connected to vault';

            SELECT @MessageOut AS [OutputMessage];
        END;

        SET @Return_Value = 1;
    END TRY
    BEGIN CATCH
        SET @MessageOut = ERROR_MESSAGE();

        IF @IsSilent = 0
            SELECT @MessageOut AS [OutputMessage];

        DECLARE @EncrytedPassword NVARCHAR(100);

        SELECT TOP 1
               @EncrytedPassword = [mvs].[Password]
        FROM [dbo].[MFVaultSettings] AS [mvs];

        DECLARE @DecryptedPassword NVARCHAR(100);

        EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @EncrytedPassword          -- nvarchar(2000)
                                ,@DecryptedPassword = @DecryptedPassword OUTPUT; -- nvarchar(2000)

        IF @IsSilent = 0
        BEGIN
            SELECT [mvs].[Username]
                  ,@DecryptedPassword AS [DecryptedPassword]
                  ,[mvs].[Domain]
                  ,[mvs].[NetworkAddress]
                  ,[mvs].[VaultName]
                  ,[mat].[AuthenticationType]
                  ,[mpt].[ProtocolType]
                  ,[mvs].[Endpoint]
            FROM [dbo].[MFVaultSettings]                AS [mvs]
                INNER JOIN [dbo].[MFAuthenticationType] AS [mat]
                    ON [mat].[ID] = [mvs].[MFAuthenticationType_ID]
                INNER JOIN [dbo].[MFProtocolType]       AS [mpt]
                    ON [mpt].[ID] = [mvs].[MFProtocolType_ID];

            PRINT ERROR_MESSAGE();
        END;
    END CATCH;

    IF @Return_Value = 1
    BEGIN
        BEGIN TRY
            EXEC @Return_Value = [dbo].[spMFCheckLicenseStatus] @InternalProcedureName = 'spMFGetClass'    -- nvarchar(500)
                                                               ,@ProcedureName = 'spMFVaultConnectionTest' -- nvarchar(500)
                                                               ,@ProcedureStep = 'Validate License: ';     -- sysname

            SET @MessageOut = 'Validated License';

            --   SELECT @Return_Value;
            IF @IsSilent = 0
                SELECT @MessageOut AS [OutputMessage];

            RETURN 1;
        END TRY
        BEGIN CATCH
            SET @MessageOut = 'Invalid License: ' + ERROR_MESSAGE();

            IF @IsSilent = 0
                SELECT @MessageOut AS [OutputMessage];
        END CATCH;
    END;
END;

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFLogError_EMail]';
go

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFLogError_EMail', -- nvarchar(100)
    @Object_Release = '4.2.7.46', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 ;
go
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: To email MFLog error to support when it happens
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
2016-8-22	lc change name of procedure
2016 8-22   lc change settings index
2017-7-25	lc	Add deployed version to email
2018-11-22	LC	Add database to subject line
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

USAGE:	EXEC usp_MFLogError_EMail 
			  @DebugFlag = 1
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFLogError_EMail'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFLogError_EMail]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go
ALTER PROC [dbo].[spMFLogError_EMail]
    @LogID INT ,
    @DebugFlag INT = 0
AS
    BEGIN

--** Stored Proc Content

------------------------------------------------------
-- SET SESSION STATE
-------------------------------------------------------
        SET NOCOUNT ON;

------------------------------------------------------
-- DECLARE VARIABLES
------------------------------------------------------
        DECLARE @ec INT ,
            @rowcount INT ,
            @ProcedureName sysname ,
            @ProcedureStep sysname;
        DECLARE @ErrStep VARCHAR(255) ,
            @Stage VARCHAR(50) ,
            @Step VARCHAR(30);

------------------------------------------------------
-- DEFINE CONSTANTS
------------------------------------------------------
        SET @ProcedureName = '[dbo].[usp_MFLogError_EMail]';
        SET @ec = 0;
        SET @rowcount = 0;
        SET @Stage = 'Email';

        BEGIN TRY
            SET @Step = 'Prepare';

------------------------------------------------------
-- ignore if email is not setup
------------------------------------------------------

IF (SELECT COUNT(*) FROM msdb.[dbo].[sysmail_profile] AS [sp] ) > 0
Begin

	--############################## Get DBMail Profile ##############################
            SET @ProcedureStep = 'Get Email Profile';

            DECLARE @EMAIL_PROFILE VARCHAR(255);
			DECLARE @ReturnValue int

			EXEC @ReturnValue = [dbo].[spMFValidateEmailProfile] @emailProfile = @EMAIL_PROFILE output, -- varchar(100)
			    @debug = @DebugFlag -- smallint
			
			IF @ReturnValue = 1
			BEGIN
            
	--		SELECT @EMAIL_PROFILE

            SELECT  @EMAIL_PROFILE = CONVERT(VARCHAR(50), Value)
            FROM    [dbo].[MFSettings]
            WHERE   Name = 'SupportEMailProfile';	
			END
				

	--############################## Get From, ReplyTo & CC ##############################
            SET @ProcedureStep = 'Get Email Address';

            DECLARE @EMAIL_FROM_ADDR VARCHAR(255) ,
                @EMAIL_REPLYTO_ADDR VARCHAR(255) ,
                @EMAIL_CC_ADDR VARCHAR(255) ,
                @EMAIL_TO_ADDR VARCHAR(255);

            SELECT  @EMAIL_FROM_ADDR = a.email_address
            FROM    msdb.dbo.sysmail_account a
                    INNER JOIN msdb.dbo.sysmail_profileaccount pa ON a.account_id = pa.account_id
                    INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
            WHERE   p.name = @EMAIL_PROFILE
                    AND pa.sequence_number = 1;



            SET @EMAIL_TO_ADDR = ( SELECT   CONVERT(VARCHAR(100), Value)
                                   FROM     dbo.MFSettings
                                   WHERE    [Name] = 'SupportEmailRecipient' AND [source_key] = 'Email'
                                 );
	--############################## Get Subject ##############################
            SET @ProcedureStep = 'Get Email Subject';

            DECLARE @EMAIL_SUBJECT VARCHAR(255);
		
            SELECT  @EMAIL_SUBJECT = @@SERVERNAME + '.' + DB_NAME() + ': MFLog Error';

            SELECT  @EMAIL_SUBJECT = @EMAIL_SUBJECT + ' Log - ID:'
                    + CAST(@LogID AS VARCHAR(10))
            FROM    [dbo].MFLog l
            WHERE   [l].[LogID] = @LogID;

	--############################## Get Body ##############################	
            SET @ProcedureStep = 'Get Email Body';

            DECLARE @SPName NVARCHAR(MAX) ,
                @ErrorMessage NVARCHAR(MAX) ,
                @CreateDate VARCHAR(30) ,
                @ErrorProcedure VARCHAR(MAX) ,
                @ErrorStep NVARCHAR(MAX) ,
                @UpdateID VARCHAR(50) ,
                @ExternalID VARCHAR(50),
				@ProcVersion VARCHAR(50);

            SELECT  @SPName = [l].[SPName] ,
                    @ErrorMessage = [l].[ErrorMessage] ,
                    @CreateDate = ISNULL(CONVERT(VARCHAR(30), CreateDate, 100),
                                         '') ,
                    @ErrorProcedure = [l].[ErrorProcedure] ,
                    @ErrorStep = [l].[ProcedureStep] ,
                    @UpdateID = CAST(ISNULL([l].[Update_ID], 0) AS VARCHAR(50)) ,
                    @ExternalID = ISNULL([l].[ExternalID], '')
            FROM    [dbo].MFLog l
            WHERE   [l].[LogID] = @LogID;

			-- added TFS 1105 LC
			SELECT @ProcVersion = [moc].[Release] FROM setup.[MFSQLObjectsControl] AS [moc] WHERE [moc].[Name] = @SPName

            DECLARE @EMAIL_BODY NVARCHAR(MAX) ,
                @EMAIL_MAILITEM_ID INT ,
                @UpdateStatus NVARCHAR(50);

            IF @DebugFlag <> 0
                SELECT  @EMAIL_PROFILE AS '@EMAIL_PROFILE' ,
                        @EMAIL_TO_ADDR AS '@EMAIL_TO_ADDR' ,
                        @EMAIL_SUBJECT AS '@EMAIL_SUBJECT'; 
            SELECT  @UpdateStatus = UpdateStatus
            FROM    MFUpdateHistory
            WHERE   id = CAST(@UpdateID AS INT);

	--Define StyleSheet
            SET @EMAIL_BODY = N'<html>
			<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<style type="text/css">
				div {line-height: 100%;}  
				body {-webkit-text-size-adjust:none; -ms-text-size-adjust:none;} 
				body {margin:0; padding:0;}
				table td {border-collapse:collapse;}    
				p {margin:0; padding:0; margin-bottom:0;}
				h1, h2, h3, h4, h5, h6 {color: black;line-height: 100%;}  
				body, #body_style {
								min-height:1000px;
								font-family:Arial, Helvetica, sans-serif;
								font-size:12px;
								} 
				
			</style>
			</head>
			<body style="min-height:1000px;font-family:Arial, Helvetica, sans-serif; font-size:12px">
			<div  id="body_style" style="padding:15px">			';
	--Get Process Headers
            SET @ProcedureStep = 'Get Email Body: Process Summary';
            SET @EMAIL_BODY = '<div class="CSSTableGenerator" >
				<table cellpadding="5" cellspacing="1" border="1">
					<tr>
						<td width="20%">Log Error Date:</td>
						<td width="70%">' + ISNULL(@CreateDate, '') + '</td>
					</tr>
					<tr>
						<td width="20%">Server Name:</td>
						<td width="70%">' + @@SERVERNAME + '</td>
					</tr>
					<tr>
						<td width="20%">Database:</td>
						<td width="70%">' + DB_NAME() + '</td>
					</tr>
					<tr>
						<td width="20%">SPName:</td>
						<td width="70%">' + ISNULL(@SPName, '') + '</td>
					</tr>
					<tr>
						<td width="20%">Error Message:</td>
						<td width="70%">' + ISNULL(@ErrorMessage, '') + '</td>
					</tr> 
					<tr>
						<td width="20%">Error Procedure:</td>
						<td width="70%">' + ISNULL(@ErrorProcedure, '')
                + '</td>
					</tr> 
					<tr>
						<td width="20%">Procedure Step:</td>
						<td width="70%">' + ISNULL(@ErrorStep, '') + '</td>
					</tr> 
					<tr>
						<td width="20%">Update ID:</td>
						<td width="70%">' + ISNULL(@UpdateID, '') + '</td>
					</tr> 
					<tr>
						<td width="20%">External ID:</td>
						<td width="70%">' + ISNULL(@ExternalID, '') + '</td>
					</tr>
					<tr>
						<td width="20%">Update Status</td>
						<td width="70%">' + ISNULL(@UpdateStatus, '') + '</td>
					</tr>	
					<tr>
						<td width="20%">Procedure Version</td>
						<td width="70%">' + ISNULL(@ProcVersion, '') + '</td> 
					</tr>				
					</table> 
					 </div></div>
					 
			 </body>
			 </html>';
            SET @Step = 'Send';
            SET @ProcedureStep = 'EXEC msdb.dbo.Sp_send_dbmail';

	--------------------------------------
	--EXECUTE Sp_send_dbmail TO SEND MAIL
	---------------------------------------
     IF @DebugFlag > 0
	 SELECT @EMAIL_BODY



         BEGIN TRY
         
		    EXEC msdb.dbo.sp_send_dbmail @profile_name = @EMAIL_PROFILE,
                @recipients = @EMAIL_TO_ADDR	--, @copy_recipients = @EMAIL_CC_ADDR
                , @subject = @EMAIL_SUBJECT, @body = @EMAIL_BODY,
                @body_format = 'HTML',
                @mailitem_id = @EMAIL_MAILITEM_ID OUTPUT;

		
	
		END TRY

	
        
		BEGIN CATCH

		
		DECLARE @ErrorSeverity INT;
            DECLARE @ErrorState INT;
            DECLARE @ErrorNumber INT;
            DECLARE @ErrorLine INT;
            DECLARE @OptionalMessage VARCHAR(MAX);

            SELECT  @ErrorMessage = ERROR_MESSAGE() ,
                    @ErrorSeverity = ERROR_SEVERITY() ,
                    @ErrorState = ERROR_STATE() ,
                    @ErrorNumber = ERROR_NUMBER() ,
                    @ErrorLine = ERROR_LINE() ,
                    @ErrorProcedure = ERROR_PROCEDURE();

		
            IF @DebugFlag > 0
                RAISERROR (
				'ERROR in %s at %s: %s'
				,16
				,1
				,@ErrorProcedure
				,@ProcedureStep
				,@ErrorMessage
				);

          RAISERROR (@ErrorMessage -- Message text.
			,@ErrorSeverity -- Severity.
			,@ErrorState -- State.
			);
		END CATCH
        
   
			

            RETURN 1;

			END
            ELSE 
			PRINT 'Database mail has not setup been setup. Complete the setup to receive notifications by email'
			RETURN 2;

        END TRY

        BEGIN CATCH
            --DECLARE @ErrorSeverity INT;
            --DECLARE @ErrorState INT;
            --DECLARE @ErrorNumber INT;
            --DECLARE @ErrorLine INT;
            --DECLARE @OptionalMessage VARCHAR(MAX);

            SELECT  @ErrorMessage = ERROR_MESSAGE() ,
                    @ErrorSeverity = ERROR_SEVERITY() ,
                    @ErrorState = ERROR_STATE() ,
                    @ErrorNumber = ERROR_NUMBER() ,
                    @ErrorLine = ERROR_LINE() ,
                    @ErrorProcedure = ERROR_PROCEDURE();
			
                  
            RAISERROR (@ErrorMessage -- Message text.
			,@ErrorSeverity -- Severity.
			,@ErrorState -- State.
			);

            RETURN -1;
        END CATCH;

    END;

go


GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSettingsForVaultUpdate]';
GO

SET NOCOUNT ON;
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSettingsForVaultUpdate', -- nvarchar(100)
    @Object_Release = '3.1.5.41',                -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO
/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-04
	Database: 
	Description: Procedure to allow updating of specific settings
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		lc			change settings index
	2016-10-12		LC			Update procedure to allow for updating of settings into the new MFVaultSettings Table
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFSettingsForVaultUpdate]   
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSettingsForVaultUpdate' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: updated';
    --		DROP PROCEDURE dbo.[spMFSettingsForVaultUpdate]
    SET NOEXEC ON;

END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO


-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSettingsForVaultUpdate]
AS
    SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE dbo.spMFSettingsForVaultUpdate
(
    @Username NVARCHAR(100) = NULL,       --  M-Files user with vault admin rights
    @Password NVARCHAR(100) = NULL,       -- the password will be encrypted 
    @NetworkAddress NVARCHAR(100) = NULL, -- N'laminindev.lamininsolutions.com' -Vault server URL from SQL server
    @Vaultname NVARCHAR(100) = NULL,      -- vault name 
    @MFProtocolType_ID INT = NULL,        -- select items from list in MFProtocolType
    @Endpoint INT = NULL,                 -- default 2266
    @MFAuthenticationType_ID INT = NULL,  -- select item from list of MFAutenticationType
    @Domain NVARCHAR(128) = NULL,
    @VaultGUID NVARCHAR(128) = NULL,      -- N'CD6AEE8F-D8F8-413E-AB2C-398B50097D39' GUID from M-Files admin
    @ServerURL NVARCHAR(128) = NULL,      --- N'laminindev.lamininsolutions.com' Web Address of M-Files
	 @RootFolder nvarchar(128) = null,
	 @FileTransferLocation nvarchar(128) = null,
    @Debug SMALLINT = 0
)
AS
BEGIN



    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM [dbo].[MFVaultSettings] AS [mvs])
    BEGIN

        INSERT INTO [dbo].[MFVaultSettings]
        (
            [Username],
            [Password],
            [NetworkAddress],
            [VaultName],
            [MFProtocolType_ID],
            [Endpoint],
            [MFAuthenticationType_ID],
            [Domain]
        )
        VALUES
        (   '',              -- Username - nvarchar(128)
            NULL,            -- Password - nvarchar(128)
            N'localhost',    -- NetworkAddress - nvarchar(128)
            N'Sample Vault', -- VaultName - nvarchar(128)
            1,               -- MFProtocolType_ID - int
            2266,            -- Endpoint - int
            4,               -- MFAuthenticationType_ID - int
            N''              -- Domain - nvarchar(128)
        );
    END;

    BEGIN

        DECLARE @Prev_Username NVARCHAR(100),
            @Prev_Password NVARCHAR(100),
            @Prev_NetworkAddress NVARCHAR(100),
            @Prev_Vaultname NVARCHAR(100),
            @Prev_MFProtocolType_ID INT,
            @Prev_Endpoint INT,
            @Prev_MFAuthenticationType_ID INT,
            @Prev_Domain NVARCHAR(128),
            @Prev_VaultGUID NVARCHAR(128),
            @Prev_ServerURL NVARCHAR(128);

        SELECT @Prev_Username = Username,
            @Prev_Password = [Password],
            @Prev_NetworkAddress = NetworkAddress,
            @Prev_Vaultname = VaultName,
            @Prev_MFProtocolType_ID = MFProtocolType_ID,
            @Prev_Endpoint = [Endpoint],
            @Prev_MFAuthenticationType_ID = MFAuthenticationType_ID,
            @Prev_Domain = Domain
        FROM dbo.MFVaultSettings AS MVS;

        SELECT @Prev_VaultGUID = CONVERT(NVARCHAR(128), Value)
        FROM MFSettings
        WHERE Name = 'VaultGUID'
              AND [source_key] = 'MF_Default';

        SELECT @Prev_ServerURL = CONVERT(NVARCHAR(128), Value)
        FROM MFSettings
        WHERE Name = 'ServerURL'
              AND [source_key] = 'MF_Default';

        IF @Debug > 0
            SELECT @Prev_Username AS Username,
                @Prev_Password AS [Password],
                @Prev_NetworkAddress AS NetworkAddress,
                @Prev_Vaultname AS Vaultname,
                @Prev_MFProtocolType_ID AS MFProtocolType_ID,
                @Prev_Endpoint AS [Endpoint],
                @Prev_MFAuthenticationType_ID AS MFAuthenticationType_ID,
                @Prev_Domain AS Domain,
                @Prev_VaultGUID AS VaultGuid,
                @Prev_ServerURL AS ServerURL;



        UPDATE mfs
        SET Username = CASE
                           WHEN @Username <> @Prev_Username
                                AND @Username IS NOT NULL THEN
                               @Username
                           ELSE
                               @Prev_Username
                       END,
            NetworkAddress = CASE
                                 WHEN @NetworkAddress <> @Prev_NetworkAddress
                                      AND @NetworkAddress IS NOT NULL THEN
                                     @NetworkAddress
                                 ELSE
                                     @Prev_NetworkAddress
                             END,
            VaultName = CASE
                            WHEN @Vaultname <> @Prev_Vaultname
                                 AND @Vaultname IS NOT NULL THEN
                                @Vaultname
                            ELSE
                                @Prev_Vaultname
                        END,
            MFProtocolType_ID = CASE
                                    WHEN @MFProtocolType_ID <> @Prev_MFProtocolType_ID
                                         AND @MFProtocolType_ID IS NOT NULL THEN
                                        @MFProtocolType_ID
                                    ELSE
                                        @Prev_MFProtocolType_ID
                                END,
            [Endpoint] = CASE
                             WHEN @Endpoint <> @Prev_Endpoint
                                  AND @Endpoint IS NOT NULL THEN
                                 @Endpoint
                             ELSE
                                 @Prev_Endpoint
                         END,
            MFAuthenticationType_ID = CASE
                                          WHEN @MFAuthenticationType_ID <> @Prev_MFAuthenticationType_ID
                                               AND @MFAuthenticationType_ID IS NOT NULL THEN
                                              @MFAuthenticationType_ID
                                          ELSE
                                              @Prev_MFAuthenticationType_ID
                                      END,
            Domain = CASE
                         WHEN @Domain <> @Prev_Domain
                              AND @Domain IS NOT NULL THEN
                             @Domain
                         ELSE
                             @Prev_Domain
                     END
        FROM MFVaultSettings mfs;

        IF @Debug > 0
            SELECT CASE
                       WHEN @VaultGUID IS NOT NULL
                            AND @VaultGUID <> @Prev_VaultGUID THEN
                           CONVERT(SQL_VARIANT, @VaultGUID)
                       ELSE
                           CONVERT(SQL_VARIANT, @Prev_VaultGUID)
                   END AS VaultGUID;

        UPDATE [dbo].[MFSettings]
        SET Value = CASE
                        WHEN @VaultGUID IS NOT NULL
                             AND @VaultGUID <> @Prev_VaultGUID THEN
                            CONVERT(SQL_VARIANT, @VaultGUID)
                        ELSE
                            CONVERT(SQL_VARIANT, @Prev_VaultGUID)
                    END
        WHERE Name = 'VaultGUID'
              AND [source_key] = 'MF_Default';

        IF @Debug > 0
            SELECT CASE
                       WHEN @ServerURL <> @Prev_ServerURL
                            AND @ServerURL IS NOT NULL THEN
                           CONVERT(SQL_VARIANT, @ServerURL)
                       ELSE
                           CONVERT(SQL_VARIANT, @Prev_ServerURL)
                   END;


        UPDATE [dbo].[MFSettings]
        SET Value = CASE
                        WHEN @ServerURL <> @Prev_ServerURL
                             AND @ServerURL IS NOT NULL THEN
                            CONVERT(SQL_VARIANT, @ServerURL)
                        ELSE
                            CONVERT(SQL_VARIANT, @Prev_ServerURL)
                    END
        WHERE Name = 'ServerURL'
              AND [source_key] = 'MF_Default';


        IF @Password IS NOT NULL
        BEGIN



            DECLARE @EncryptedPassword NVARCHAR(250);
            DECLARE @PreviousPassword NVARCHAR(100);


            SELECT TOP 1
                @PreviousPassword = [Password]
            FROM dbo.MFVaultSettings s;

            IF @Debug = 1
                SELECT @EncryptedPassword AS '@EncryptedPassword',
                    @PreviousPassword AS '@PreviousPassword';

            IF @PreviousPassword IS NULL
                EXEC [dbo].[spMFEncrypt] @Password = N'null', -- nvarchar(2000)
                    @EcryptedPassword = @PreviousPassword OUTPUT; -- nvarchar(2000);


            EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @PreviousPassword, -- nvarchar(2000)
                @DecryptedPassword = @PreviousPassword OUTPUT; -- nvarchar(2000)
        END;

        IF @Password IS NOT NULL
           AND @Password <> @PreviousPassword
        BEGIN

            EXECUTE dbo.spMFEncrypt @Password, @EncryptedPassword OUT;

            UPDATE s
            SET [s].[Password] = @EncryptedPassword
            FROM dbo.MFVaultSettings s;


        END;
    END;


    RETURN 1;
END;


GO

go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFProcessBatchDetail_Insert]';
go

SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
								   , @ObjectName = N'spMFProcessBatchDetail_Insert'
								   , @Object_Release = '4.2.8.47'
								   , @UpdateFlag = 2
	  go

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFProcessBatchDetail_Insert'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
go

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFProcessBatchDetail_Insert]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFProcessBatchDetail_Insert]
      (
        @ProcessBatch_ID INT
      , @LogType NVARCHAR(50) = N'Info' -- (Debug | Info | Warning | Error)
      , @LogText NVARCHAR(4000) = NULL
      , @LogStatus NVARCHAR(50) = NULL
      , @StartTime DATETIME
      , @MFTableName NVARCHAR(128) = NULL
      , @Validation_ID INT = NULL
      , @ColumnName NVARCHAR(128) = NULL
      , @ColumnValue NVARCHAR(256) = NULL
      , @Update_ID INT = NULL
      , @LogProcedureName NVARCHAR(128) = NULL
      , @LogProcedureStep NVARCHAR(128) = NULL
	  , @ProcessBatchDetail_ID INT = NULL OUTPUT
      , @debug TINYINT = 0  -- 101 for EpicorEnt Test Mode
												
      )
AS /*******************************************************************************

  **
  ** Author:          leroux@lamininsolutions.com
  ** Date:            2016-08-27
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  add settings option to exclude procedure from executing detail logging
	2017-06-30	AC			- Add @ProcessBatchDetail_ID as param to allow for calculation of duration if provided based on input of a specific ID
								Procedure will use input to overide the passed int StartDate and get start date from the ID provided
								This will allow calculation of @DureationInSecords seconds on a detail proc level
2018-10-31	lc	update logging text								
2019-1-27	LC	exclude MFUserMessage table from any logging
						
  ******************************************************************************/

  /*

  */

      BEGIN

            SET NOCOUNT ON;
            SET XACT_ABORT ON;
	 -------------------------------------------------------------
    -- Logging Variables
    -------------------------------------------------------------
            DECLARE @ProcedureName AS NVARCHAR(128) = 'MFProcessBatchDetail_Insert';
            DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
            DECLARE @DebugText AS NVARCHAR(256) = ''
            DECLARE @DetailLoggingIsActive SMALLINT = 0;
		

            DECLARE @DurationSeconds AS FLOAT;

            DECLARE @rowcount AS INT = 0;
            DECLARE @sql NVARCHAR(MAX) = N''
            DECLARE @sqlParam NVARCHAR(MAX) = N''


            SELECT  @DetailLoggingIsActive = CAST([MFSettings].[Value] AS INT)
            FROM    [dbo].[MFSettings]
            WHERE   [MFSettings].[Name] = 'App_DetailLogging'

  

            BEGIN TRY

					 
                  IF ( @DetailLoggingIsActive = 1 ) AND (ISNULL(@MFTableName,'') <> 'MFUserMessages')
                     BEGIN

                           IF @debug > 100
                              BEGIN
                                    SET @DebugText = @DefaultDebugText + ' ColumnName: %s ColumnValue: %s '	
                                    RAISERROR(@DebugText,10,1,@LogProcedureName,@LogProcedureStep, @ColumnName,@ColumnValue);
                              END
			--	SELECT @StartTime
							DECLARE @CreatedOnUTC DATETIME
							SELECT @CreatedOnUTC = [CreatedOnUTC]
							FROM [dbo].[MFProcessBatchDetail]
							WHERE [ProcessBatchDetail_ID] = @ProcessBatchDetail_ID

							SET @DurationSeconds = DATEDIFF(MS, COALESCE(@CreatedOnUTC,@StartTime,GETUTCDATE()), GETUTCDATE()) / CONVERT(DECIMAL(18,3),1000)
	
			
				
			--	SELECT @DurationSeconds
						DECLARE @ProcedureStep AS NVARCHAR(128) = 'INSERT dbo.MFProcessBatchDetail';
						INSERT [dbo].[MFProcessBatchDetail] (	[ProcessBatch_ID]
															  , [LogType]
															  , [ProcedureRef]
															  , [LogText]
															  , [Status]
															  , [DurationSeconds]
															  , [MFTableName]
															  , [Validation_ID]
															  , [ColumnName]
															  , [ColumnValue]
															  , [Update_ID]
															)
						VALUES (   @ProcessBatch_ID
								 , @LogType			-- LogType - nvarchar(50)
								 , @LogProcedureName + ': ' + @LogProcedureStep
								 , @LogText			-- LogText - nvarchar(4000)
								 , @LogStatus		-- Status - nvarchar(50)
								 , @DurationSeconds -- DurationSeconds - decimal
								 , @MFTableName
								 , @Validation_ID	-- Validation_ID - int
								 , @ColumnName		-- ColumnName - nvarchar(128)
								 , @ColumnValue		-- ColumnValue - nvarchar(256)
								 , @Update_ID
							   )

                           IF @debug > 9
                              BEGIN
                                    SET @ProcedureStep = 'Debug '
                                    SET @DebugText = @DefaultDebugText + ': ' + @LogText
                                    RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep)
                              END
  
                     END
					
                  SET NOCOUNT OFF;

	  

                  RETURN 1



            END TRY

            BEGIN CATCH
          -----------------------------------------------------------------------------
          -- INSERTING ERROR DETAILS INTO LOG TABLE
          -----------------------------------------------------------------------------
                  INSERT    INTO [dbo].[MFLog]
                            ( [SPName]
                            , [ProcedureStep]
                            , [ErrorNumber]
                            , [ErrorMessage]
                            , [ErrorProcedure]
                            , [ErrorState]
                            , [ErrorSeverity]
                            , [ErrorLine]
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
                  SELECT    ERROR_NUMBER() AS [ErrorNumber]
                          , ERROR_MESSAGE() AS [ErrorMessage]
                          , ERROR_PROCEDURE() AS [ErrorProcedure]
                          , ERROR_STATE() AS [ErrorState]
                          , ERROR_SEVERITY() AS [ErrorSeverity]
                          , ERROR_LINE() AS [ErrorLine]
                          , @ProcedureName AS [ProcedureName]
                          , @ProcedureStep AS [ProcedureStep]

                  RETURN 2
            END CATCH

              
      END
go


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSearchForObject]';
go
SET NOCOUNT off
 
go

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSearchForObject', -- nvarchar(100)
    @Object_Release = '4.3.9.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSearchForObject'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSearchForObject]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF
go

ALTER PROCEDURE [dbo].[spMFSearchForObject] (@ClassID     INT
                                              ,@SearchText NVARCHAR (2000)
                                              ,@Count      INT = 1									
											  ,@OutputType INT = 0 -- 0 = output to select 1 = output to temp search table
											  ,@XMLOutPut xml output
											  ,@TableName varchar(200)='' output
											  ,@Debug SMALLINT = 0)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to search for an object in M-Files  
  **  
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 29-04-2014  DEV 2      RETURN statement added
  ** 26-6-2016   LeRoux	Debugging added
  ** 24-8-2016	 DEV 2		TaskID 471
  ** 27-8-2016	LC			Update variabletable function parameters
  ** 26-9-2016  DevTeam2    Removed vault settings parameters and pass them as 
                            comma separated string in @VaultSettings parameter.
	 04-04-2018 DevTeam2    Added License Module validation code.
	 06-5-2019 LC			Change destination of search to a temporary file
  ******************************************************************************/
  BEGIN
      BEGIN TRY
          BEGIN TRANSACTION
		  SET NOCOUNT on
          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
          DECLARE @Xml             [NVARCHAR] (MAX)
                  ,@IsFound        BIT
                  ,@VaultSettings  NVARCHAR(4000)
                  ,@XMLDoc         XML
                  ,@Columns        NVARCHAR(MAX)
                  ,@Query          NVARCHAR(MAX)
				  

          -----------------------------------------------------
          --ACCESS CREDENTIALS
          -----------------------------------------------------
         

		  SELECT @VaultSettings=dbo.FnMFVaultSettings()
         

         -----------------------------------------------------------------
	      -- Checking module access for CLR procdure  spMFSearchForObjectInternal
         ------------------------------------------------------------------
         EXEC [dbo].[spMFCheckLicenseStatus] 
		      'spMFSearchForObjectInternal',
			  'spMFSearchForObject',
			  'Checking module access for CLR procdure  spMFSearchForObjectInternal'
         
          -----------------------------------------------------
          -- CLASS WRAPPER PROCEDURE
          -----------------------------------------------------
          EXEC spMFSearchForObjectInternal
             @VaultSettings
            ,@ClassID
            ,@SearchText
            ,@Count
            ,@Xml OUTPUT
            ,@IsFound OUTPUT

          SELECT @XMLDoc = @Xml

		  IF @debug <> 0
		  SELECT @isFound;

		  IF @debug <> 0
		  SELECT @XMLDoc;
          -----------------------------------------------------
          --IF OBJECT FOUND
          -----------------------------------------------------
          IF ( @IsFound = 1 )
            BEGIN
                -----------------------------------------------------
                --CREATE TEMPORARY TABLE STORE DATA FROM XML
                -----------------------------------------------------
                CREATE TABLE #Properties
                  (
                     [objectId]       [INT]
                     ,[propertyId]    [INT] NULL
                     ,[propertyValue] [NVARCHAR](100) NULL
                     ,[propertyName]  [NVARCHAR](100) NULL
                     ,[dataType]      [NVARCHAR](100) NULL
                  )

                -----------------------------------------------------
                -- INSERT DATA FROM XML
                -----------------------------------------------------
                INSERT INTO #Properties
                            (objectId,
                             propertyId,
                             propertyValue,
                             dataType)
                SELECT t.c.value('(../@objectId)[1]', 'INT')              AS objectId
                       ,t.c.value('(@propertyId)[1]', 'INT')              AS propertyId
                       ,t.c.value('(@propertyValue)[1]', 'NVARCHAR(100)') AS propertyValue
                       ,t.c.value('(@dataType)[1]', 'NVARCHAR(1000)')     AS dataType
                FROM   @XMLDoc.nodes('/form/Object/properties')AS t(c)

                ----------------------------------------------------------------------
                -- UPDATE PROPERTY NAME WITH COLUMN NAME SPECIFIED IN MFProperty TABLE
                ----------------------------------------------------------------------
                UPDATE #Properties
                SET    propertyName = ( SELECT ColumnName
                                        FROM   MFProperty
                                        WHERE  MFID = #properties.propertyId )

                UPDATE #Properties
                SET    propertyName = Replace(propertyName, '_ID', '')
                WHERE  dataType = 'MFDatatypeLookup'
                    OR dataType = 'MFDatatypeMultiSelectLookup'

                -----------------------------------------------------
                ---------------PIVOT--------------------------
                -----------------------------------------------------
                SELECT @Columns = Stuff(( SELECT ',' + Quotename(propertyName)
                                          FROM   #Properties ppt
                                          GROUP  BY ppt.propertyName
                                          ORDER  BY ppt.propertyName
                                          FOR XML PATH(''), TYPE ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

               
				------------------------------------------
				 --This code gets name of new table.
				------------------------------------------
				if @OutputType!=0 
				Begin
					Select @TableName=dbo.fnMFVariableTableName('##MFSearch',Default)
				END
                
	
				 ----------------------------------
                --creating dynamic query for PIVOT
                ----------------------------------

                SELECT @Query = 'SELECT objectId
								,' + @Columns
                                + ' into dbo.'+@TableName+'
						FROM   ( SELECT objectId
										,propertyName new_col
										,value
								 FROM   #Properties
										UNPIVOT ( value
												FOR col IN (propertyValue) ) un ) src
							   PIVOT ( Max(value)
									 FOR new_col IN ( ' + @Columns
                                + ' ) ) p 
								
								'

				IF @debug <> 0
				print @Query;
               
			   
			      if @OutputType!=0
					begin
						EXECUTE (@Query)
						insert into MFSearchLog(TableName,SearchClassID,SearchText,SearchDate,ProcessID)
						values(@TableName,@ClassID,@SearchText,GETDATE(),1)

						
					End
				else
					Begin
						select @XMLOutPut= @Xml
					End


				IF @debug <> 0
				SELECT * FROM [#Properties];

                DROP TABLE #Properties
            END
          ELSE
            BEGIN
                ----------------------------------
                --Showing not Found message
                ----------------------------------
                DECLARE @Output NVARCHAR(MAX)

                SELECT @Output = 'Object with Title " ' + @SearchText
                                 + '  is not found'

                SELECT @Output
            END

          COMMIT TRANSACTION

		  RETURN 1
      END TRY

      BEGIN CATCH
          ROLLBACK TRANSACTION

          --------------------------------------------------
          -- INSERTING ERROR DETAILS INTO LOG TABLE
          --------------------------------------------------
          INSERT INTO MFLog
                      (SPName,
                       ErrorNumber,
                       ErrorMessage,
                       ErrorProcedure,
                       ErrorState,
                       ErrorSeverity,
                       ErrorLine,
                       ProcedureStep)
          VALUES      ('spMFSearchForObject',
                       Error_number(),
                       Error_message(),
                       Error_procedure(),
                       Error_state(),
                       Error_severity(),
                       Error_line(),
                       '')
		  RETURN 2
      END CATCH
  END



go
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateTable]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFCreateTable' -- nvarchar(100)
                                    ,@Object_Release = '4.2.7.46'     -- varchar(50)
                                    ,@UpdateFlag = 2;

-- smallint
/*
 ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 23-05-2015  DEV2		Default column ExternalID added
  ** 25-05-2015  DEV2	     Default column Update_ID added
  ** 27-06-2016  LC			Automatically add includeInApp if null
  18-8-2016 LC  add system columns with localized text names that is required for creating a new record
  10-9-2016		lc			set process_ID default to 1 and deleted default to 0 on creating new record
  2-10-2016		lc			update multi lookup columns to nvarchar(4000)
  13-10-2016    DEV2        Added Single_File Column in Class table
  15-10-2016	lc			Change Default of Single_file to 0
  2017-7-6		LC			Add new default column for FileCount
  2017-11-29	LC			Add error message of file does not exist or table already exist
  2018-4-17		LC			Add condition to only create trigger on table if includedinApp is set to 2 (for transaction based tables.)
  2018-10-30	LC			Add creating unique index on objid and externalid
  */
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFCreateTable' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFCreateTable]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFCreateTable]
(
    @ClassName NVARCHAR(128)
   ,@Debug SMALLINT = 0
)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to create the Table for a Class in M-Files.  
  **  
  ** Version: 1.0.0.6
  **
  ** Author:          Thejus T V
  ** Date:            27-03-2015
  
  ******************************************************************************/
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -------------------------------------------------------------
        -- Local variable Declaration
        -------------------------------------------------------------
        DECLARE @Output        NVARCHAR(200)
               ,@ClassID       INT
               ,@TableName     NVARCHAR(128)
               ,@dsql          NVARCHAR(MAX) = N''
               ,@ConstColumn   NVARCHAR(MAX)
               ,@IDColumn      NVARCHAR(MAX)
               ,@Count         INT
               ,@ProcedureName sysname       = 'spMFCreateTable'
               ,@ProcedureStep sysname       = 'Start';

        -------------------------------------------------------------
        --Check if the name exixsts in MFClass
        -------------------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM [dbo].[MFClass]
            WHERE [Name] = @ClassName
                  AND [Deleted] = 0
        )
        BEGIN
            -------------------------------------------------------------
            --SELECT PROPERTY NAME AND DATA TYPE
            -------------------------------------------------------------
            SET @ProcedureStep = 'SELECT PROPERTY NAME AND DATA TYPE';

            SELECT *
            INTO [#Temp]
            FROM
            (
                SELECT [ColumnName]
                      ,[MFDataType_ID]
                      ,[ID]
                FROM [dbo].[MFProperty]
                WHERE [ID] IN (
                                  SELECT [MFProperty_ID]
                                  FROM [dbo].[MFClassProperty]
                                  WHERE [Deleted] = 0
                                        AND [MFClass_ID] =
                                        (
                                            SELECT [ID]
                                            FROM [dbo].[MFClass]
                                            WHERE [Name] = @ClassName
                                                  AND [Deleted] = 0
                                        )
                              )
            ) AS [columnNameAndDataType];

            SELECT @ClassID = [ID]
            FROM [dbo].[MFClass]
            WHERE [Name] = @ClassName
                  AND [Deleted] = 0;

            ALTER TABLE [#Temp] ADD [PredefinedOrAutomatic] BIT;

            IF @Debug = 1
            BEGIN
                SELECT *
                FROM [#Temp] AS [t];

                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -----------------------------------------------------------------
            --Updating PredefinedOrAutomatic with values from MFClassProperty
            -----------------------------------------------------------------
            SET @ProcedureStep = 'Updating PredefinedOrAutomatic with values from MFClassProperty';

            UPDATE [#Temp]
            SET [PredefinedOrAutomatic] =
                (
                    SELECT [Required]
                    FROM [dbo].[MFClassProperty]
                    WHERE [MFProperty_ID] = [ID]
                          AND [MFClass_ID] = @ClassID
                );

            -----------------------------------------------------------------------------
            --Checking if the required property is autocalculated 
            --     or predefined,if yes, Updating required = FALSE
            -----------------------------------------------------------------------------
            UPDATE [#Temp]
            SET [PredefinedOrAutomatic] =
                (
                    SELECT 1 ^ [PredefinedOrAutomatic]
                    FROM [dbo].[MFProperty]
                    WHERE [ID] = [#Temp].[ID]
                )
            WHERE [PredefinedOrAutomatic] = 1;

            IF @Debug = 1
                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

            -----------------------------------------------------------------------------
            --CHANGE THE 'MFDataType_ID' COLUMN DATA TYPE TO 'NVARCHAR(50)'
            -----------------------------------------------------------------------------
            SET @ProcedureStep = 'CHANGE THE MFDataType_ID COLUMN DATA TYPE TO NVARCHAR(100)';

            ALTER TABLE [#Temp] DROP COLUMN [ID];

            ALTER TABLE [#Temp] ALTER COLUMN [MFDataType_ID] NVARCHAR(50);

            SELECT @TableName = [TableName]
            FROM [dbo].[MFClass]
            WHERE [Name] = @ClassName;

            IF @Debug = 1
                RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

            -----------------------------------------------------------------------------
            --Check If the table already Existing in DB or not
            -----------------------------------------------------------------------------
            SET @ProcedureStep = 'Check If the table already Existing in DB or not';

            IF NOT EXISTS
            (
                SELECT 1
                FROM [sys].[sysobjects]
                WHERE [id] = OBJECT_ID(N'[dbo].[' + @TableName + ']')
                      AND OBJECTPROPERTY([id], N'IsUserTable') = 1
            )
            BEGIN
                INSERT INTO [#Temp]
                (
                    [ColumnName]
                   ,[MFDataType_ID]
                   ,[PredefinedOrAutomatic]
                )
                SELECT *
                FROM
                (
                    SELECT REPLACE([ColumnName], '_ID', '') AS [ColumnName]
                          ,1                                AS [MFDataType_ID]
                          ,'False'                          AS [PredefinedOrAutomatic]
                    FROM [#Temp]
                    WHERE [MFDataType_ID] IN (
                                                 SELECT [ID] FROM [dbo].[MFDataType] WHERE [MFTypeID] IN ( 9 )
                                             )
                ) AS [n1]
                UNION ALL
                SELECT *
                FROM
                (
                    SELECT REPLACE([ColumnName], '_ID', '') AS [ColumnName]
                          ,9                                AS [MFDataType_ID]
                          ,'False'                          AS [PredefinedOrAutomatic]
                    FROM [#Temp]
                    WHERE [MFDataType_ID] IN (
                                                 SELECT [ID] FROM [dbo].[MFDataType] WHERE [MFTypeID] = 10
                                             )
                ) AS [n2];

                IF @Debug = 1
                BEGIN
                    SELECT *
                    FROM [#Temp];

                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -----------------------------------------------------------------------------
                --CHANGE THE FKID WITH SQLDATATYPE
                -----------------------------------------------------------------------------
                UPDATE [#Temp]
                SET [MFDataType_ID] =
                    (
                        SELECT [SQLDataType] FROM [dbo].[MFDataType] WHERE [ID] = [MFDataType_ID]
                    );

                -----------------------------------------------------------------------------
                --ALTERING THE #Temp TABLE COLUMN DATATYPE
                -----------------------------------------------------------------------------
                SET @ProcedureStep = 'ALTERING THE #Temp TABLE COLUMN DATATYPE';

                --		IF EXISTS(SELECT name FROM sys.columns WHERE [columns].[object_id] = OBJECT_ID('tempdb..#Temp') AND name = 'PredefinedOrAutomatic')						  
                ALTER TABLE [#Temp] ALTER COLUMN [PredefinedOrAutomatic] NVARCHAR(50);

                UPDATE [#Temp]
                SET [PredefinedOrAutomatic] = 'NULL'
                WHERE [PredefinedOrAutomatic] = '0';

                UPDATE [#Temp]
                --                 SET     PredefinedOrAutomatic = 'NOT NULL'
                SET [PredefinedOrAutomatic] = 'NULL'
                WHERE [PredefinedOrAutomatic] = '1';

                IF @Debug = 1
                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

                -----------------------------------------------------------------------------
                --Add Additional Default columns in localised text
                -----------------------------------------------------------------------------                  
                SET @ProcedureStep = 'Add Additional Default columns in localised text';

                DECLARE @NameOrTitle       VARCHAR(100)
                       ,@classPropertyName VARCHAR(100)
                       ,@Workflow          VARCHAR(100)
                       ,@State             VARCHAR(100)
                       ,@SingleFile        VARCHAR(100);

                ;

                SELECT @NameOrTitle = [ColumnName]
                FROM [dbo].[MFProperty]
                WHERE [MFID] = 0;

                SELECT @classPropertyName = [ColumnName]
                FROM [dbo].[MFProperty]
                WHERE [MFID] = 100;

                SELECT @Workflow = [ColumnName]
                FROM [dbo].[MFProperty]
                WHERE [MFID] = 39;

                SELECT @State = [ColumnName]
                FROM [dbo].[MFProperty]
                WHERE [MFID] = 38;

                ------Added By DevTeam2 For Task 937
                SELECT @SingleFile = [ColumnName]
                FROM [dbo].[MFProperty]
                WHERE [MFID] = 22;

                ------Added By DevTeam2 For Task 937

                --					SELECT @NameOrTitle,@classPropertyName,@Workflow, @State
                INSERT INTO [#Temp]
                (
                    [ColumnName]
                   ,[MFDataType_ID]
                   ,[PredefinedOrAutomatic]
                )
                VALUES
                (@classPropertyName, 'INTEGER', 'NOT NULL')
               ,(REPLACE(@classPropertyName, '_ID', ''), 'NVARCHAR(100)', 'NULL')
               ,(@Workflow, 'INTEGER', 'NULL')
               ,(REPLACE(@Workflow, '_ID', ''), 'NVARCHAR(100)', 'NULL')
               ,(@State, 'INTEGER', 'NULL')
               ,(REPLACE(@State, '_ID', ''), 'NVARCHAR(100)', 'NULL')
               ,(@SingleFile, 'BIT', 'NOT NULL DEFAULT(0)'); ------Added By DevTeam2 For Task 937

                IF NOT EXISTS
                (
                    SELECT *
                    FROM [#Temp] AS [t]
                    WHERE [t].[ColumnName] = @NameOrTitle
                )
                BEGIN
                    INSERT INTO [#Temp]
                    (
                        [ColumnName]
                       ,[MFDataType_ID]
                       ,[PredefinedOrAutomatic]
                    )
                    VALUES
                    (@NameOrTitle, 'NVARCHAR(100)', 'NULL');
                END;

                IF @Debug = 1
                BEGIN
                    SELECT '#Temp'
                          ,*
                    FROM [#Temp];

                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                /*************************************************************************
					  STEP Get id of of class column to set it up as default
					  NOTES
					  */
                DECLARE @ClassCustomName NVARCHAR(100)
                       ,@ClassMFID       INT;

                SELECT @ClassCustomName = [Name]
                FROM [dbo].[MFProperty]
                WHERE [MFID] = 100;

                SELECT @ClassMFID = [MFID]
                FROM [dbo].[MFClass]
                WHERE [ID] = @ClassID;

                -----------------------------------------------------------------------------
                --GENERATING THE DYNAMIC QUERY TO CREATE TABLE    
                -----------------------------------------------------------------------------                  
                SET @ProcedureStep = 'GENERATING THE DYNAMIC QUERY TO CREATE TABLE';

                SELECT @IDColumn
                    = '[ID]  INT IDENTITY(1,1) NOT NULL ,[GUID] NVARCHAR(100),[MX_User_ID]  UNIQUEIDENTIFIER,';

                SELECT @dsql
                    = @dsql + QUOTENAME([ColumnName]) + ' ' + [MFDataType_ID] + ' ' + [PredefinedOrAutomatic] + ','
                FROM [#Temp]
                ORDER BY [ColumnName];

                SELECT @ConstColumn
                    = '[LastModified]  DATETIME DEFAULT(GETDATE()) , ' + '[Process_ID] INT, ' + '[ObjID]			INT , '
                      + '[ExternalID]			NVARCHAR(100) , '
                      + '[MFVersion]		INT,[FileCount] int , [Deleted] BIT,[Update_ID] int , '; ---- Added for task 106 [FileCount]

                SELECT @dsql = @IDColumn + @dsql + @ConstColumn;

                SELECT @dsql
                    = 'CREATE TABLE ' + QUOTENAME(@TableName) + ' (' + LEFT(@dsql, LEN(@dsql) - 1)
                      + '
								 CONSTRAINT pk_' + @TableName + 'ID PRIMARY KEY (ID))
									ALTER TABLE ' + QUOTENAME(@TableName) + ' ADD  CONSTRAINT [DK_Deleted_'
                      + @TableName + ']  DEFAULT 0 FOR [Deleted]
									ALTER TABLE ' + QUOTENAME(@TableName) + ' ADD  CONSTRAINT [DK_Process_id_'
                      + @TableName + ']  DEFAULT 1 FOR [Process_ID]
				    ALTER TABLE ' + QUOTENAME(@TableName) + ' ADD  CONSTRAINT [DK_FileCount_' + @TableName
                      + ']  DEFAULT 0 FOR [FileCount]
				     ';

                ---------------------------------------------------------------------------
                --EXECUTE DYNAMIC QUERY TO CREATE TABLE
                -----------------------------------------------------------------------------
                IF @Debug = 1
                BEGIN
                    SELECT @dsql AS [CreateTable];
                END;

                EXEC [sys].[sp_executesql] @Stmt = @dsql;

                /*************************************************************************
         STEP alter table to set default for class
         NOTES
         */
                SET @ProcedureStep = 'Set default for Class_ID';

                DECLARE @Params NVARCHAR(100);

                SET @Params = N'@Tablename nvarchar(100)';

                --SELECT  @dsql = N'ALTER TABLE '
                --      + QUOTENAME(@TableName) + ' ADD  CONSTRAINT [DK_Class_' + @TableName + '] DEFAULT('+ CAST(@ClassMFID AS VARCHAR(10)) +') FOR '
                --   + QUOTENAME(@ClassCustomName +'_ID') + '';
                SELECT @dsql
                    = N'ALTER TABLE ' + QUOTENAME(@TableName) + ' ADD  CONSTRAINT [DK_Class_' + @TableName
                      + '] DEFAULT(' + CAST(-1 AS VARCHAR(10)) + ') FOR ' + QUOTENAME(@ClassCustomName + '_ID') + '';

                --SELECT  @dsql = N'ALTER TABLE '
                --                   + QUOTENAME(@TableName) + ' ADD  CONSTRAINT [DK_Class_' + @TableName + '] DEFAULT('+ CAST(@ClassMFID AS VARCHAR(10)) +') FOR [Class_ID] ';
                IF @Debug = 1
                BEGIN
                    SELECT @dsql AS [Alter table for defaults];
                END;

                EXEC [sys].[sp_executesql] @Stmt = @dsql
                                          ,@Param = @Params
                                          ,@Tablename = @TableName;

                IF @Debug = 1
                    RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

                -------------------------------------------------------------
                -- ADD standard Logging properties
                -------------------------------------------------------------
                SET @ProcedureStep = 'Add MFSQL_Message and MFSQL_Process_Batch columns';

                DECLARE @IsDetailLogging SMALLINT
                       ,@SQL             NVARCHAR(MAX);

                SELECT @IsDetailLogging = CAST(ISNULL([ms].[Value], '0') AS INT)
                FROM [dbo].[MFSettings] AS [ms]
                WHERE [ms].[Name] = 'App_DetailLogging';

                IF @IsDetailLogging = 1
                    SELECT @Count = COUNT(*)
                    FROM [dbo].[MFProperty] AS [mp]
                    WHERE [mp].[Name] IN ( 'MFSQL_Message', 'MFSQL_Process_Batch' );

                IF @Count = 2
                BEGIN
                    BEGIN
                        SELECT @Count = COUNT(*)
                        FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                        WHERE [c].[COLUMN_NAME] = 'MFSQL_Message'
                              AND [c].[TABLE_NAME] = @TableName;

                        IF @Count = 0
                        BEGIN
                            SET @SQL = N'
Alter Table ' +             @TableName + '
Add MFSQL_Message nvarchar(100) null;';

                            EXEC (@SQL);
                        END; --columns does not exist on table

                        SELECT @Count = COUNT(*)
                        FROM [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                        WHERE [c].[COLUMN_NAME] = 'MFSQL_Process_batch'
                              AND [c].[TABLE_NAME] = @TableName;

                        IF @Count = 0
                        BEGIN
                            SET @SQL = N'
Alter Table ' +             @TableName + '
Add  MFSQL_Process_batch int null;';

                            EXEC (@SQL);
                        END; --columns does not exist on table
                    END; --properties have been setup
                END;

                --Detail logging  = 1

                -------------------------------------------------------------
                -- Add indexes and foreign keys
                -------------------------------------------------------------
                SET @SQL
                    = N'
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + '_Objid'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                      + '''))
CREATE UNIQUE NONCLUSTERED INDEX IX_' + @TableName + '_Objid
ON dbo.' +      @TableName + '(Objid)
WHERE Objid IS NOT NULL;';

--select @SQL
    --           EXEC (@SQL);

                SET @SQL
                    = N'
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + '_ExternalID'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                      + '''))
CREATE UNIQUE NONCLUSTERED INDEX IX_' + @TableName + '_ExternalID
ON dbo.' +      @TableName + '(ExternalID)
WHERE ExternalID IS NOT NULL;';

      --          EXEC (@SQL);

                /*************************************************************************
STEP Add trigger to table
NOTES
*/
                IF
                (
                    SELECT [IncludeInApp] FROM [dbo].[MFClass] WHERE [TableName] = @TableName
                ) = 2
                BEGIN
                    SET @ProcedureStep = 'Create Trigger for table';

                    EXEC [dbo].[spMFCreateClassTableSynchronizeTrigger] @TableName;

                    IF @Debug = 1
                        RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);
                END;

                IF @Debug = 1
                    RAISERROR('Table %s Created', 10, 1, @TableName);

				IF (OBJECT_ID('tempdb..#Temp')) IS NOT null
                DROP TABLE [#Temp];
            END;
            ELSE
            BEGIN
                -----------------------------------------------------------------------------
                --SHOW ERROR MESSAGE
                -----------------------------------------------------------------------------
                IF @Debug = 1
                    RAISERROR('Table %s Already Exist', 10, 1, @TableName);

				IF (OBJECT_ID('tempdb..#Temp')) IS NOT null
                DROP TABLE [#Temp];
            END;
        END;
        ELSE
        BEGIN
            -----------------------------------------------------------------------------
            --SHOW ERROR MESSAGE
            -----------------------------------------------------------------------------
            RAISERROR('Entered Class Name does not Exists in MFClass Table', 10, 1, @ProcedureName, @ProcedureStep);

            IF (OBJECT_ID('tempdb..#Temp')) IS NOT null
			DROP TABLE [#Temp];

            RETURN -1;
        END;

        -----------------------------------------------------------------------------
        --SET INCLUDEINAPP TO 1 IF NULL
        -----------------------------------------------------------------------------
        SET @ProcedureStep = 'SET INCLUDEINAPP TO 1 IF NULL';

        UPDATE [mc]
        SET [mc].[IncludeInApp] = 1
        FROM [dbo].[MFClass] AS [mc]
        WHERE @TableName = [mc].[TableName]
              AND [mc].[IncludeInApp] IS NULL;

        IF @Debug = 1
            RAISERROR('Proc: %s Step: %s', 10, 1, @ProcedureName, @ProcedureStep);

        RETURN 1;
    END TRY
    BEGIN CATCH
        -----------------------------------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        -----------------------------------------------------------------------------
        INSERT INTO [dbo].[MFLog]
        (
            [SPName]
           ,[ErrorNumber]
           ,[ErrorMessage]
           ,[ErrorProcedure]
           ,[ErrorState]
           ,[ErrorSeverity]
           ,[ErrorLine]
        )
        VALUES
        ('spMFCreateTable', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY()
        ,ERROR_LINE());

        -----------------------------------------------------------------------------
        -- DISPLAYING ERROR DETAILS
        -----------------------------------------------------------------------------
        SELECT ERROR_NUMBER()    AS [ErrorNumber]
              ,ERROR_MESSAGE()   AS [ErrorMessage]
              ,ERROR_PROCEDURE() AS [ErrorProcedure]
              ,ERROR_STATE()     AS [ErrorState]
              ,ERROR_SEVERITY()  AS [ErrorSeverity]
              ,ERROR_LINE()      AS [ErrorLine];

        RETURN 2;
    END CATCH;
END;
GO
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDropAndUpdateMetadata]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFDropAndUpdateMetadata' -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.48'               -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*
MODIFICATIONS
2017-6-20	lc		Fix begin tran bug
2018-6-28	lc		add additional columns to user specific columns fileexportfolder, syncpreference
2018-9-01   lc		add switch to destinguish between structure only on including valuelist items
2018-11-2	lc		add new feature to auto create columns for new properties added to class tables
2019-1-19	LC		add new feature to fix class table columns for changed properties
2019-1-20	LC		add prevent deleting data if license invalid
2019-3-25	LC		fix bug to update when change has taken place and all defaults are specified
*/
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFDropAndUpdateMetadata' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFDropAndUpdateMetadata]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFDropAndUpdateMetadata]
    @IsResetAll SMALLINT = 0
   ,@WithClassTableReset SMALLINT = 0
   ,@WithColumnReset SMALLINT = 0
   ,@IsStructureOnly SMALLINT = 1
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@Debug SMALLINT = 0
AS
SET NOCOUNT ON;

DECLARE @ProcedureStep VARCHAR(100)  = 'start'
       ,@ProcedureName NVARCHAR(128) = 'spMFDropAndUpdateMetadata';
DECLARE @RC INT;
DECLARE @ProcessType NVARCHAR(50) = 'Metadata Sync';
DECLARE @LogType NVARCHAR(50);
DECLARE @LogText NVARCHAR(4000);
DECLARE @LogStatus NVARCHAR(50);
DECLARE @MFTableName NVARCHAR(128);
DECLARE @Update_ID INT;
DECLARE @LogProcedureName NVARCHAR(128);
DECLARE @LogProcedureStep NVARCHAR(128);
DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL;

-------------------------------------------------------------
-- VARIABLES: DEBUGGING
-------------------------------------------------------------
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @DebugText AS NVARCHAR(256) = '';
DECLARE @Msg AS NVARCHAR(256) = '';
DECLARE @MsgSeverityInfo AS TINYINT = 10;
DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

---------------------------------------------
-- ACCESS CREDENTIALS FROM Setting TABLE
---------------------------------------------

--used on MFProcessBatchDetail;
DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System';
DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress';
DECLARE @EndTime DATETIME;
DECLARE @StartTime DATETIME;
DECLARE @StartTime_Total DATETIME = GETUTCDATE();
DECLARE @Validation_ID INT;
DECLARE @LogColumnName NVARCHAR(128);
DECLARE @LogColumnValue NVARCHAR(256);
DECLARE @error AS INT = 0;
DECLARE @rowcount AS INT = 0;
DECLARE @return_value AS INT;

--Custom declarations
DECLARE @Datatype INT;
DECLARE @Property NVARCHAR(100);
DECLARE @rownr INT;
DECLARE @IsUpToDate BIT;
DECLARE @Count INT;
DECLARE @Length INT;
DECLARE @SQLDataType NVARCHAR(100);
DECLARE @MFDatatype_ID INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @rowID INT;
DECLARE @MaxID INT;
DECLARE @ColumnName VARCHAR(100);

BEGIN TRY

    -------------------------------------------------------------
    -- INTIALIZE PROCESS BATCH
    -------------------------------------------------------------
    SET @ProcedureStep = 'Start Logging';
    SET @LogText = 'Processing ';

    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcedureName
                                        ,@LogType = N'Status'
                                        ,@LogText = @LogText
                                        ,@LogStatus = N'In Progress'
                                        ,@debug = @Debug;

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Debug'
                                              ,@LogText = @ProcessType
                                              ,@LogStatus = N'Started'
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = @Validation_ID
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = @Update_ID
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @ProcedureStep
                                              ,@ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT;

    -------------------------------------------------------------
    -- Validate license
    -------------------------------------------------------------
    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'validate lisense';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    DECLARE @VaultSettings NVARCHAR(4000);

    SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

    EXEC @return_value = [dbo].[spMFCheckLicenseStatus] @InternalProcedureName = 'spMFGetClass' -- nvarchar(500)
                                                       ,@ProcedureName = @ProcedureName         -- nvarchar(500)
                                                       ,@ProcedureStep = @ProcedureStep;

Set @DebugText = 'License Return %s'
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = ''

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@return_value );
	END

    -------------------------------------------------------------
    -- Get up to date status
    -------------------------------------------------------------
    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;
    SET @ProcedureStep = 'Get Structure Version ID';

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    EXEC [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate OUTPUT;

    SELECT @IsUpToDate = CASE
                            WHEN @IsResetAll = 1 THEN
                                0
                             ELSE
                                 @IsUpToDate
                         END;
    -------------------------------------------------------------
    -- if Full refresh
    -------------------------------------------------------------
	

    IF (
           @IsUpToDate = 0
           AND @IsStructureOnly = 0
       )
       OR
       (
           @IsUpToDate = 1
           AND @IsStructureOnly = 0
       )
	   OR
	   ( 
	    @IsUpToDate = 0
           AND @IsStructureOnly = 1
	   )
	   OR @IsResetAll = 1
    BEGIN

	Set @DebugText = 'License valid %i'
	Set @DebugText = @DefaultDebugText + @DebugText
	Set @Procedurestep = 'Refresh started '
	
	IF @debug > 0
		Begin
			RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@return_value );
		END
	


        -------------------------------------------------------------
        -- License is valid - continue
        -------------------------------------------------------------			
        IF @return_value = 0 -- license validation returns 0 if correct
        BEGIN
            SELECT @ProcedureStep = 'setup temp tables';

            SET @DebugText = '';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- setup temp tables
            -------------------------------------------------------------
            IF EXISTS (SELECT * FROM [sys].[sysobjects] WHERE [name] = '#MFClassTemp')
            BEGIN
                DROP TABLE [#MFClassTemp];
            END;

            IF EXISTS
            (
                SELECT 1
                FROM [sys].[sysobjects]
                WHERE [name] = '#MFPropertyTemp'
            )
            BEGIN
                DROP TABLE [#MFPropertyTemp];
            END;

            IF EXISTS
            (
                SELECT 1
                FROM [sys].[sysobjects]
                WHERE [name] = '#MFValuelistItemsTemp'
            )
            BEGIN
                DROP TABLE [#MFValuelistItemsTemp];
            END;


			IF EXISTS
            (
                SELECT *
                FROM [sys].[sysobjects]
                WHERE [name] = '#MFWorkflowStateTemp'
            )
            BEGIN
                DROP TABLE [#MFWorkflowStateTemp];
            END;


			
            -------------------------------------------------------------
            -- Populate temp tables
            -------------------------------------------------------------
            SET @ProcedureStep = 'Insert temp table for classes, properties and valuelistitems';

            --Insert Current MFClass table data into temp table
            SELECT *
            INTO [#MFClassTemp]
            FROM
            (SELECT * FROM [dbo].[MFClass]) AS [cls];

            --Insert current MFProperty table data into temp table
            SELECT *
            INTO [#MFPropertyTemp]
            FROM
            (SELECT * FROM [dbo].[MFProperty]) AS [ppt];

            --Insert current MFProperty table data into temp table
            SELECT *
            INTO [#MFValuelistItemsTemp]
            FROM
            (SELECT * FROM [dbo].[MFValueListItems]) AS [ppt];

			  SELECT *
            INTO [#MFWorkflowStateTemp]
            FROM
            (SELECT * FROM [dbo].[MFWorkflowState]) AS [WST];

            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                SELECT *
                FROM [#MFClassTemp] AS [mct];

                SELECT *
                FROM [#MFPropertyTemp] AS [mpt];

                SELECT *
                FROM [#MFValuelistItemsTemp] AS [mvit];

				SELECT * 
				FROM [#MFWorkflowStateTemp] AS [mwst]

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            -------------------------------------------------------------
            -- delete data from main tables
            -------------------------------------------------------------
            SET @ProcedureStep = 'Delete existing tables';

            IF
            (
                SELECT COUNT(*) FROM [#MFClassTemp] AS [mct]
            ) > 0
            BEGIN
                DELETE FROM [dbo].[MFClassProperty]
                WHERE [MFClass_ID] > 0;

                DELETE FROM [dbo].[MFClass]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFProperty]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFValueListItems]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFValueList]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFWorkflowState]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFWorkflow]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFObjectType]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFLoginAccount]
                WHERE [ID] > -99;

                DELETE FROM [dbo].[MFUserAccount]
                WHERE [UserID] > -99;

                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END;

            --delete if count(*) #classTable > 0
            -------------------------------------------------------------
            -- get new data
            -------------------------------------------------------------
            SET @ProcedureStep = 'Start new Synchronization';
            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            --Synchronize metadata
            EXEC @return_value = [dbo].[spMFSynchronizeMetadata] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                                                ,@Debug = @Debug;

            SET @ProcedureName = 'spMFDropAndUpdateMetadata';

            IF @Debug > 0
            BEGIN
                SELECT *
                FROM [dbo].[MFClass];

                SELECT *
                FROM [dbo].[MFProperty];
            END;

            SET @DebugText = ' Reset %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @IsResetAll);
            END;

            -------------------------------------------------------------
            -- update custom settings from previous data
            -------------------------------------------------------------
            --IF synchronize is success
            IF (@return_value = 1 AND @IsResetAll = 0)
            BEGIN
                SET @ProcedureStep = 'Update with no reset';

                UPDATE [dbo].[MFClass]
                SET [TableName] = [#MFClassTemp].[TableName]
                   ,[IncludeInApp] = [#MFClassTemp].[IncludeInApp]
                   ,[FileExportFolder] = [#MFClassTemp].[FileExportFolder]
                   ,[SynchPrecedence] = [#MFClassTemp].[SynchPrecedence]
                FROM [dbo].[MFClass]
                    INNER JOIN [#MFClassTemp]
                        ON [MFClass].[MFID] = [#MFClassTemp].[MFID]
                           AND [MFClass].[Name] = [#MFClassTemp].[Name];

                UPDATE [dbo].[MFProperty]
                SET [ColumnName] = [tmp].[ColumnName]
                FROM [dbo].[MFProperty]          AS [mfp]
                    INNER JOIN [#MFPropertyTemp] AS [tmp]
                        ON [mfp].[MFID] = [tmp].[MFID]
                           AND [mfp].[Name] = [tmp].[Name];

                UPDATE [dbo].[MFValueListItems]
                SET [AppRef] = [tmp].[AppRef]
                   ,[Owner_AppRef] = [tmp].[Owner_AppRef]
                FROM [dbo].[MFValueListItems]          AS [mfp]
                    INNER JOIN [#MFValuelistItemsTemp] AS [tmp]
                        ON [mfp].[MFID] = [tmp].[MFID]
                           AND [mfp].[Name] = [tmp].[Name];

				 UPdate [dbo].[MFWorkflowState]
				 SET [IsNameUpdate]=1 
			     from [dbo].[MFWorkflowState] as [mfws]
					Inner join [#MFWorkflowStateTemp] as [tmp]
					on [mfws].MFID=[tmp].MFID
					AND [mfws].Name!=[tmp].Name

                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END;

            -- update old data
            -------------------------------------------------------------
            -- Class table reset
            -------------------------------------------------------------	
            IF @WithClassTableReset = 1
            BEGIN
                SET @ProcedureStep = 'Class table reset';

                DECLARE @ErrMsg VARCHAR(200);

                SET @ErrMsg = 'datatype of property has changed';

                --RAISERROR(
                --             'Proc: %s Step: %s ErrorInfo %s '
                --            ,16
                --            ,1
                --            ,'spMFDropAndUpdateMetadata'
                --            ,'datatype of property has changed, tables or columns must be reset'
                --            ,@ErrMsg
                --         );
                CREATE TABLE [#TempTableName]
                (
                    [ID] INT IDENTITY(1, 1)
                   ,[TableName] VARCHAR(100)
                );

                INSERT INTO [#TempTableName]
                SELECT DISTINCT
                       [TableName]
                FROM [dbo].[MFClass]
                WHERE [IncludeInApp] IS NOT NULL;

                DECLARE @TCounter  INT
                       ,@TMaxID    INT
                       ,@TableName VARCHAR(100);

                SELECT @TMaxID = MAX([ID])
                FROM [#TempTableName];

                SET @TCounter = 1;

                WHILE @TCounter <= @TMaxID
                BEGIN
                    DECLARE @ClassName VARCHAR(100);

                    SELECT @TableName = [TableName]
                    FROM [#TempTableName]
                    WHERE [ID] = @TCounter;

                    SELECT @ClassName = [Name]
                    FROM [dbo].[MFClass]
                    WHERE [TableName] = @TableName;

                    IF EXISTS
                    (
                        SELECT [K_Table]         = [FK].[TABLE_NAME]
                              ,[FK_Column]       = [CU].[COLUMN_NAME]
                              ,[PK_Table]        = [PK].[TABLE_NAME]
                              ,[PK_Column]       = [PT].[COLUMN_NAME]
                              ,[Constraint_Name] = [C].[CONSTRAINT_NAME]
                        FROM [INFORMATION_SCHEMA].[REFERENTIAL_CONSTRAINTS]     [C]
                            INNER JOIN [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS] [FK]
                                ON [C].[CONSTRAINT_NAME] = [FK].[CONSTRAINT_NAME]
                            INNER JOIN [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS] [PK]
                                ON [C].[UNIQUE_CONSTRAINT_NAME] = [PK].[CONSTRAINT_NAME]
                            INNER JOIN [INFORMATION_SCHEMA].[KEY_COLUMN_USAGE]  [CU]
                                ON [C].[CONSTRAINT_NAME] = [CU].[CONSTRAINT_NAME]
                            INNER JOIN
                            (
                                SELECT [i1].[TABLE_NAME]
                                      ,[i2].[COLUMN_NAME]
                                FROM [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]          [i1]
                                    INNER JOIN [INFORMATION_SCHEMA].[KEY_COLUMN_USAGE] [i2]
                                        ON [i1].[CONSTRAINT_NAME] = [i2].[CONSTRAINT_NAME]
                                WHERE [i1].[CONSTRAINT_TYPE] = 'PRIMARY KEY'
                            )                                                   [PT]
                                ON [PT].[TABLE_NAME] = [PK].[TABLE_NAME]
                        WHERE [PK].[TABLE_NAME] = @TableName
                    )
                    BEGIN
                        SET @ErrMsg = 'Can not drop table ' + +'due to the foreign key';

                        RAISERROR(
                                     'Proc: %s Step: %s ErrorInfo %s '
                                    ,16
                                    ,1
                                    ,'spMFDropAndUpdateMetadata'
                                    ,'Foreign key reference'
                                    ,@ErrMsg
                                 );
                    END;
                    ELSE
                    BEGIN
                        EXEC ('Drop table ' + @TableName);

                        PRINT 'Drop table ' + @TableName;

                        EXEC [dbo].[spMFCreateTable] @ClassName;

                        PRINT 'Created table' + @TableName;
                        PRINT 'Synchronizing table ' + @TableName;

                        EXEC [dbo].[spMFUpdateTable] @TableName, 1;
                    END;

                    SET @TCounter = @TCounter + 1;
                END;

                DROP TABLE [#TempTableName];

                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;
            END;

            --class table reset

            -------------------------------------------------------------
            -- perform validations
            -------------------------------------------------------------
            EXEC [dbo].[spMFClassTableColumns];

            SELECT @Count
                = (SUM(ISNULL([ColumnDataTypeError], 0)) + SUM(ISNULL([missingColumn], 0))
                   + SUM(ISNULL([MissingTable], 0)) + SUM(ISNULL([RedundantTable], 0))
                  )
            FROM [##spmfclasstablecolumns];

            IF @Count > 0
            BEGIN
                SET @DebugText = ' Count of errors %i';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Perform validations';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                END;

                -------------------------------------------------------------
                -- Data type errors
                -------------------------------------------------------------
                SET @Count = 0;

                SELECT @Count = SUM(ISNULL([ColumnDataTypeError], 0))
                FROM [##spmfclasstablecolumns];

                IF @Count > 0
                BEGIN
                    SET @DebugText = ' %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Data Type Error ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                    END;
                END;

                IF @WithColumnReset = 1
                BEGIN
                    -------------------------------------------------------------
                    -- Resolve Class table column errors
                    -------------------------------------------------------------					;
                    SET @rowID =
                    (
                        SELECT MIN([id])
                        FROM [##spMFClassTableColumns]
                        WHERE [ColumnDataTypeError] = 1
                    );

                    WHILE @rowID IS NOT NULL
                    BEGIN
                        SELECT @TableName     = [TableName]
                              ,@ColumnName    = [ColumnName]
                              ,@MFDatatype_ID = [MFDatatype_ID]
                        FROM [##spMFClassTableColumns]
                        WHERE [id] = @rowID;

                        SELECT @SQLDataType = [mdt].[SQLDataType]
                        FROM [dbo].[MFDataType] AS [mdt]
                        WHERE [mdt].[MFTypeID] = @MFDatatype_ID;

                        --	SELECT @TableName,@columnName,@SQLDataType
                        IF @MFDatatype_ID IN ( 1, 10, 13 )
                        BEGIN TRY
                            SET @SQL
                                = N'ALTER TABLE ' + QUOTENAME(@TableName) + ' ALTER COLUMN ' + QUOTENAME(@ColumnName)
                                  + ' ' + @SQLDataType + ';';

                            --	SELECT @SQL
                            EXEC (@SQL);

                        --         RAISERROR('Updated column %s in Table %s', 10, 1, @columnName, @TableName);
                        END TRY
                        BEGIN CATCH
                            RAISERROR('Unable to change column %s in Table %s', 16, 1, @ColumnName, @TableName);
                        END CATCH;

                        SELECT @rowID =
                        (
                            SELECT MIN([id])
                            FROM [##spMFClassTableColumns]
                            WHERE [id] > @rowID
                                  AND [ColumnDataTypeError] = 1
                        );
                    END; --end loop column reset
                END;

                --end WithcolumnReset

                -------------------------------------------------------------
                -- resolve missing column
                -------------------------------------------------------------
                SET @Count = 0;

                SELECT @Count = SUM(ISNULL([missingColumn], 0))
                FROM [##spmfclasstablecolumns];

                IF @Count > 0
                BEGIN
                    SET @DebugText = ' %i';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Missing Column Error ';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                    END;

                    /*
check table before update and auto create any columns
--check existence of table
*/
                    SET @rownr =
                    (
                        SELECT MIN([id]) FROM [##spMFClassTableColumns] WHERE [MissingColumn] = 1
                    );

                    WHILE @rownr IS NOT NULL
                    BEGIN
                        SELECT @MFTableName = [mc].[Tablename]
                              ,@SQLDataType = [mdt].[SQLDataType]
                              ,@ColumnName  = [mc].[ColumnName]
                              ,@Datatype    = [mc].[MFDatatype_ID]
                              ,@Property    = [mc].[Property]
                        FROM [##spMFclassTableColumns]    [mc]
                            INNER JOIN [dbo].[MFDataType] AS [mdt]
                                ON [mc].[MFDatatype_ID] = [mdt].[MFTypeID]
                        WHERE [mc].[ID] = @rownr;

                        IF @Datatype = 9
                        BEGIN
                            SET @SQL
                                = N'Alter table ' + QUOTENAME(@MFTableName) + ' Add ' + QUOTENAME(@ColumnName)
                                  + ' Nvarchar(100);';

                            EXEC [sys].[sp_executesql] @SQL;

                            PRINT '##### ' + @Property + ' property as column ' + QUOTENAME(@ColumnName)
                                  + ' added for table ' + QUOTENAME(@MFTableName) + '';
                        END;
                        ELSE IF @Datatype = 10
                        BEGIN
                            SET @SQL
                                = N'Alter table ' + QUOTENAME(@MFTableName) + ' Add ' + QUOTENAME(@ColumnName)
                                  + ' Nvarchar(4000);';

                            EXEC [sys].[sp_executesql] @SQL;

                            PRINT '##### ' + @Property + ' property as column ' + QUOTENAME(@ColumnName)
                                  + ' added for table ' + QUOTENAME(@MFTableName) + '';
                        END;
                        ELSE
                        BEGIN
                            SET @SQL
                                = N'Alter table ' + QUOTENAME(@MFTableName) + ' Add ' + @ColumnName + ' '
                                  + @SQLDataType + ';';

                            EXEC [sys].[sp_executesql] @SQL;

                            PRINT '##### ' + @ColumnName + ' added for table ' + QUOTENAME(@MFTableName) + '';
                        END;

                        SELECT @rownr =
                        (
                            SELECT MIN([mc].[id])
                            FROM [##spMFClassTableColumns] [mc]
                            WHERE [MissingColumn] = 1
                                  AND [mc].[id] > @rownr
                        );
                    END; -- end of loop
                END; -- End of mising columns

            -------------------------------------------------------------
            -- resolve missing table
            -------------------------------------------------------------

            -------------------------------------------------------------
            -- resolve redundant table
            -------------------------------------------------------------

            --check for any adhoc columns with no data, remove columns
            --check and update indexes and foreign keys
            END; --Validations

            SET @DebugText = ' %i';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Drop temp tables ';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            IF EXISTS (SELECT * FROM [sys].[sysobjects] WHERE [name] = '#MFClassTemp')
            BEGIN
                DROP TABLE [#MFClassTemp];
            END;

            IF EXISTS
            (
                SELECT *
                FROM [sys].[sysobjects]
                WHERE [name] = '#MFPropertyTemp'
            )
            BEGIN
                DROP TABLE [#MFPropertyTemp];
            END;

            IF EXISTS
            (
                SELECT *
                FROM [sys].[sysobjects]
                WHERE [name] = '#MFValueListitemTemp'
            )
            BEGIN
                DROP TABLE [#MFValueListitemTemp];
            END;

            SET NOCOUNT OFF;

            -------------------------------------------------------------
            -- Log End of Process
            -------------------------------------------------------------   
            SET @LogStatus = 'Completed';
            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'End of process';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID 
                                                ,@ProcessType = @ProcedureName
                                                ,@LogType = N'Message'
                                                ,@LogText = @LogText
                                                ,@LogStatus = @LogStatus
                                                ,@debug = @Debug;

            SET @StartTime = GETUTCDATE();

            EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                      ,@LogType = N'Message'
                                                      ,@LogText = @ProcessType
                                                      ,@LogStatus = @LogStatus
                                                      ,@StartTime = @StartTime
                                                      ,@MFTableName = @MFTableName
                                                      ,@Validation_ID = @Validation_ID
                                                      ,@ColumnName = ''
                                                      ,@ColumnValue = ''
                                                      ,@Update_ID = @Update_ID
                                                      ,@LogProcedureName = @ProcedureName
                                                      ,@LogProcedureStep = @ProcedureStep
                                                      ,@debug = 0;

           
        END; -- license is valid

		
    END; -- is updatetodate and istructure only
    ELSE
    BEGIN
        PRINT '###############################';
        PRINT 'Metadata structure is up to date';
    END; --else: no processing, upto date
	 RETURN 1;
END TRY
BEGIN CATCH
   IF @@TranCount > 0
   ROLLBACK;

    SET @StartTime = GETUTCDATE();
    SET @LogStatus = 'Failed w/SQL Error';
    SET @LogTextDetail = ERROR_MESSAGE();

    --------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    --------------------------------------------------
    INSERT INTO [dbo].[MFLog]
    (
        [SPName]
       ,[ErrorNumber]
       ,[ErrorMessage]
       ,[ErrorProcedure]
       ,[ErrorState]
       ,[ErrorSeverity]
       ,[ErrorLine]
       ,[ProcedureStep]
    )
    VALUES
    (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE()
    ,@ProcedureStep);

    SET @ProcedureStep = 'Catch Error';

    -------------------------------------------------------------
    -- Log Error
    -------------------------------------------------------------   
    EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                        ,@ProcessType = @ProcessType
                                        ,@LogType = N'Error'
                                        ,@LogText = @LogTextDetail
                                        ,@LogStatus = @LogStatus
                                        ,@debug = @Debug;

    SET @StartTime = GETUTCDATE();

    EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                              ,@LogType = N'Error'
                                              ,@LogText = @LogTextDetail
                                              ,@LogStatus = @LogStatus
                                              ,@StartTime = @StartTime
                                              ,@MFTableName = @MFTableName
                                              ,@Validation_ID = @Validation_ID
                                              ,@ColumnName = NULL
                                              ,@ColumnValue = NULL
                                              ,@Update_ID = @Update_ID
                                              ,@LogProcedureName = @ProcedureName
                                              ,@LogProcedureStep = @ProcedureStep
                                              ,@debug = 0;

    RETURN -1;
END CATCH;
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spmfSynchronizeLookupColumnChange]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spmfSynchronizeLookupColumnChange', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spmfSynchronizeLookupColumnChange'--name of procedure
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
CREATE PROCEDURE [dbo].[spmfSynchronizeLookupColumnChange]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


Alter PROCEDURE [dbo].[spmfSynchronizeLookupColumnChange]
@TableName Nvarchar(200)=null,
@ProcessBatch_id INT           = NULL OUTPUT,
@Debug           INT           = 0
As
/*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize ValueListItems name change in M-Files into the reference table  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **					1.) Get ValueListItems where IsNameUpdate=and get its corresponding property name from MfProperty table
  **					2.) Get the all table names from database in which above property is used .
  **					3.) Iterate with each table and update the change value in that table.
  **					4.) fetch the next value list id using cursor and continue from step 2
  **
  ** Parameters and acceptable values: 
  **					@TableName Nvarchar(200)=null,
						@ProcessBatch_id INT           = NULL OUTPUT,
	                    @Debug           INT           = 0MALLINT = 0
  
  **
  ** Called By:			spMFSynchronizeValueListItems
  **
  ** Calls:           
  **													
  **
  ** Author:			DEV2
  ** Date:				01-03-2018
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
 
  ******************************************************************************/ 
begin

			BEGIN TRY
			SET NOCOUNT ON;
			-----------------------------------------------------
			--DECLARE VARIABLES FOR LOGGING
			-----------------------------------------------------
			--used on MFProcessBatchDetail;
			DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
			DECLARE @DebugText AS NVARCHAR(256) = '';
			DECLARE @LogTypeDetail AS NVARCHAR(MAX) = '';
			DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
			DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
			DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
			DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
			DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
			DECLARE @ProcessType NVARCHAR(50) = 'Object History';
			DECLARE @LogType AS NVARCHAR(50) = 'Status';
			DECLARE @LogText AS NVARCHAR(4000) = 'Get History Initiated';
			DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
			DECLARE @Status AS NVARCHAR(128) = NULL;
			DECLARE @Validation_ID INT = NULL;
			DECLARE @StartTime AS DATETIME = GETUTCDATE();
			DECLARE @RunTime AS DECIMAL(18, 4) = 0;
			DECLARE @Update_IDOut int;
			DECLARE @error AS INT = 0;
			DECLARE @rowcount AS INT = 0;
			DECLARE @return_value AS INT;
			DECLARE @RC INT;
			DECLARE @Update_ID INT;
			DECLARE @ProcedureName sysname = 'spmfSynchronizeLookupColumnChange';
			DECLARE @ProcedureStep sysname = 'Start';
			
			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			 IF @TableName IS NOT NULL
			 Begin
			   Update MFClass set IncludeInApp=1 where TableName=@TableName
			 End

			DECLARE @Username NVARCHAR(2000);
			DECLARE @VaultName NVARCHAR(2000);

			SELECT TOP 1
			 @Username  = [MFVaultSettings].[Username],
			 @VaultName = [MFVaultSettings].[VaultName]
			FROM
			 [dbo].[MFVaultSettings];



			INSERT INTO [dbo].[MFUpdateHistory]
			(
			 [Username],
			 [VaultName],
			 [UpdateMethod]
			)
			VALUES
			(
			 @Username, @VaultName, -1
			);

			SELECT
			@Update_ID = @@IDENTITY;

			SELECT
			@Update_IDOut = @Update_ID;

			SET @ProcessType = @ProcedureName;
			SET @LogText = @ProcedureName + ' Started ';
			SET @LogStatus = 'Initiate';
			SET @StartTime = GETUTCDATE();
			set @ProcessBatch_ID=0
			EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_id OUTPUT,
			@ProcessType = @ProcessType,
			@LogType = @LogType,
			@LogText = @LogText,
			@LogStatus = @LogStatus,
			@debug = @Debug;


			 SET @ProcedureStep = 'GeT ValueListItems along with where IsNameUpdate=1 ';

            

			Create table #TempChangeValueListItems
			(
			 ID int identity(1,1),
			 ColumnName Nvarchar(100),
			 ValueListItemMFID int,
			 ValueListID int,
			 Name nvarchar(150)
			)

			insert into #TempChangeValueListItems

			select
			  MP.ColumnName as ColumnName,
			  MFVLI.MFID as ValueListItemMFID,
			  MFVLI.MFValueListID as ValueListID,
			  MFVLI.Name 
			from 
			 MFProperty MP  inner join MFValueList MVL 
			on 
			  MP.MFValueList_ID=MVL.ID inner join  MFValueListItems MFVLI 
			on 
			  MVL.ID=  MFVLI.MFValueListID 
			where 
			  MP.MFDataType_ID in (8,9) and
			  MFVLI.IsNameUpdate=1

			 IF @Debug > 0
                BEGIN
                    PRINT @ProcedureStep;
					select * from #TempChangeValueListItems
                END
				  
			DECLARE  
			@PropCounter int,
			@MaxPropCount int,
			@ColumnName nvarchar(100),
			@MFValueListItemMFID int, 
			@Name nvarchar(150),
			@MFValueListID int

			SET @PropCounter=1

			select 
			 @MaxPropCount=max(ID) 
			from 
			 #TempChangeValueListItems 

				   
			EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
			        @ProcessBatch_ID = @ProcessBatch_id,
					@LogType = @LogTypeDetail,
					@LogText = @LogTextDetail,
					@LogStatus = @LogStatusDetail,
					@StartTime = @StartTime,
					@MFTableName = @TableName,
					@Validation_ID = @Validation_ID,
					@ColumnName = @LogColumnName,
					@ColumnValue = @LogColumnValue,
					@Update_ID = @Update_ID,
					@LogProcedureName = @ProcedureName,
					@LogProcedureStep = @ProcedureStep,
					@debug = @Debug;


			While @PropCounter <= @MaxPropCount
				Begin
					   Select 
						@ColumnName=ColumnName,
						@MFValueListItemMFID=ValueListItemMFID,
						@Name=Name ,
						@MFValueListID=ValueListID
					   from 
						#TempChangeValueListItems
					   Where 
						ID=@PropCounter


			           Create Table #TempTables
						(
						  ID int identity(1,1),
						  TableName nvarchar(100)
						)


						SET @ProcedureStep = 'GeT Table names  Which containing the Property='+ @ColumnName;

			           insert into #TempTables
					   Select 
						C.TABLE_NAME 
					   from 
						INFORMATION_SCHEMA.COLUMNS C 
						where 
						C.COLUMN_NAME=@ColumnName and 
						C.TABLE_NAME in ( Select TableName from MFClass where IncludeInApp=1)


						 IF @Debug > 0
							BEGIN
								PRINT @ProcedureStep;
								select @ColumnName as PropertyName,TableName from #TempTables
							END


                       DECLARE 
						@TableCounter int,
						@MaxTableCount int ,
						@TBLName NVARCHAR(100)

			           SET @TableCounter =1 

					   Select 
						@MaxTableCount=max(ID) 
					   from 
						#TempTables 

					if @MaxTableCount>0
			         Begin
					    While @TableCounter <= @MaxTableCount
							Begin
							  
							  set @ProcedureStep ='updating the change lookup value for column '+@ColumnName + 'of table' + @TBLName

							   IF @Debug > 0
									BEGIN
										PRINT @ProcedureStep;
									END
									        
							EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
									@ProcessBatch_ID = @ProcessBatch_id,
									@LogType = @LogTypeDetail,
									@LogText = @LogTextDetail,
									@LogStatus = @LogStatusDetail,
									@StartTime = @StartTime,
									@MFTableName = @TBLName,
									@Validation_ID = @Validation_ID,
									@ColumnName = @LogColumnName,
									@ColumnValue = @LogColumnValue,
									@Update_ID = @Update_ID,
									@LogProcedureName = @ProcedureName,
									@LogProcedureStep = @ProcedureStep,
									@debug = @Debug;

									Select @TBLName=TableName from #TempTables where ID=@TableCounter
											
									DECLARE @Sql NVARCHAR(max)	 
									SET @Sql= 'Update '+ @TBLName + ' Set '+ SUBSTRING(@ColumnName,1,LEN(@ColumnName)-3)
												+'='''+@Name +''' where '+ @ColumnName +'='+ cast(@MFValueListItemMFID as nvarchar(20))

									print @sql
									exec (@Sql)
									set @TableCounter=@TableCounter+1
							End
			          End

				drop table #TempTables

				

				set @PropCounter=@PropCounter+1
			End

			update 
				   MVLI
				set 
				  MVLI.IsNameUpdate=0 
				from 
				  MFValueListItems MVLI inner join #TempChangeValueListItems T on MVLI.MFID=T.ValueListItemMFID and MVLI.MFValueListID=T.ValueListID
				where 
				  MVLI.IsNameUpdate=1
				
				  

			drop table #TempChangeValueListItems
	End Try
	BEGIN CATCH
			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
			, [ErrorNumber]
			, [ErrorMessage]
			, [ErrorProcedure]
			, [ErrorState]
			, [ErrorSeverity]
			, [ErrorLine]
			, [ProcedureStep]
			)
			VALUES (
			@ProcedureName
			, ERROR_NUMBER()
			, ERROR_MESSAGE()
			, ERROR_PROCEDURE()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, @ProcedureStep
			);

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			, @ProcessType = @ProcessType
			, @LogType = N'Error'
			, @LogText = @LogTextDetail
			, @LogStatus = @LogStatus
			, @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
			@ProcessBatch_ID = @ProcessBatch_ID
			, @LogType = N'Error'
			, @LogText = @LogTextDetail
			, @LogStatus = @LogStatus
			, @StartTime = @StartTime
			, @MFTableName = @TableName
			, @Validation_ID = @Validation_ID
			, @ColumnName = NULL
			, @ColumnValue = NULL
			, @Update_ID = @Update_ID
			, @LogProcedureName = @ProcedureName
			, @LogProcedureStep = @ProcedureStep
			, @debug = 0

			RETURN -1
	END CATCH
End
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFProcessBatch_Upsert]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFProcessBatch_Upsert' -- nvarchar(100)
                                    ,@Object_Release = '4.1.8.47'             -- varchar(50)
                                    ,@UpdateFlag = 2;                         -- smallint
GO

/*
2018-08-01	lc		add debugging
2019-1-21	LC		remove unnecessary log entry for dbcc
2019-1-26	LC		Resolve issues with commits
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFProcessBatch_Upsert' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFProcessBatch_Upsert]
AS
BEGIN
    SELECT 'created, but not implemented yet.';
END;
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFProcessBatch_Upsert]
(
    @ProcessBatch_ID INT OUTPUT
   ,@ProcessType NVARCHAR(50) = NULL -- (Debug | | Upsert | Create |Setup |Error)
   ,@LogType NVARCHAR(50) = 'Start'  -- (Start | End)
   ,@LogText NVARCHAR(4000) = NULL   -- text string for updating user
   ,@LogStatus NVARCHAR(50) = NULL   --(Initiate | In Progress | Partial | Completed | Error)
   ,@debug SMALLINT = 0              -- 
)
AS /*******************************************************************************

  **
  ** Author:          leroux@lamininsolutions.com
  ** Date:            2016-08-27
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
    add settings option to exclude procedure from executing detail logging
	2018-10-31	LC improve debugging comments
  ******************************************************************************/

/*
  DECLARE @ProcessBatch_ID INT = 0;
  
  EXEC [dbo].[spMFProcessBatch_Upsert]

      @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
    , @ProcessType = 'Test'
    , @LogText = 'Testing'
    , @LogStatus = 'Start'
    , @debug = 1
  
	select * from MFProcessBatch where ProcessBatch_ID = @ProcessBatch_ID

	WAITFOR DELAY '00:00:02'

  EXEC [dbo].[spMFProcessBatch_Upsert]

      @ProcessBatch_ID = @ProcessBatch_ID
    , @ProcessType = 'Test'
    , @LogText = 'Testing Complete'
    , @LogStatus = 'Complete'
    , @debug = 1
  
	select * from MFProcessBatch where ProcessBatch_ID = @ProcessBatch_ID


  */
SET NOCOUNT ON;
SET XACT_ABORT ON 

DECLARE @trancount INT;

-------------------------------------------------------------
-- Logging Variables
-------------------------------------------------------------
DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFProcessBatch_Upsert';
DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
DECLARE @DebugText AS NVARCHAR(256) = '';
DECLARE @DetailLoggingIsActive SMALLINT = 0;
DECLARE @rowcount AS INT = 0;

/*************************************************************************************
	PARAMETER VALIDATION
*************************************************************************************/
SET @ProcedureStep = 'ProcessBatch input param';

IF @ProcessBatch_ID = 0
    SET @ProcessBatch_ID = NULL;

SELECT @DetailLoggingIsActive = CAST([Value] AS INT)
FROM [dbo].[MFSettings]
WHERE [Name] = 'App_DetailLogging';

IF (
       @ProcessBatch_ID <> 0
       AND NOT EXISTS
(
    SELECT 1
    FROM [dbo].[MFProcessBatch]
    WHERE [ProcessBatch_ID] = @ProcessBatch_ID
)
   )
BEGIN
    SET @LogText
        = 'ProcessBatch_ID [' + ISNULL(CAST(@ProcessBatch_ID AS VARCHAR(20)), '(null)')
          + '] not found - process aborting...';
    SET @LogStatus = 'failed';

    IF @debug > 0
    BEGIN
        RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
    END;

    RETURN -1;
END; --unable TO validate

--SET @DebugText = ' %i';
--SET @DebugText = @DefaultDebugText + @DebugText;
--SET @ProcedureStep = 'Transaction Count';

--IF @debug > 0
--BEGIN
--    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @trancount);
--END;

/*************************************************************************************
	CREATE NEW BATCH ID
*************************************************************************************/
SET @trancount = @@TranCount;

IF @trancount > 0
    -- DBCC OPENTRAN;
    COMMIT;

BEGIN TRY
    BEGIN TRAN;

    IF @ProcessBatch_ID IS NULL
       AND @DetailLoggingIsActive = 1
    BEGIN
        SET @ProcedureStep = 'Create log';

        INSERT INTO [dbo].[MFProcessBatch]
        (
            [ProcessType]
           ,[LogType]
           ,[LogText]
           ,[Status]
        )
        VALUES
        (@ProcessType, @LogType, @LogText, @LogStatus);

        SET @ProcessBatch_ID = SCOPE_IDENTITY();

        IF @debug > 0
        BEGIN
            SET @DebugText = @DefaultDebugText + ' ProcessBatchID: %i';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ProcessBatch_ID);
        END;

		GOTO EXITPROC
        
    END;

    --CREATE NEW BATCH ID

    /*************************************************************************************
	UPDATE EXISTING BATCH ID
*************************************************************************************/
    IF @ProcessBatch_ID IS NOT NULL
       AND @DetailLoggingIsActive = 1
	--  BEGIN TRAN;
        SET @ProcedureStep = 'UPDATE MFProcessBatch';
        SET @DebugText = ' ID: %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @debug > 0
        BEGIN
		SELECT @@TranCount AS trancount
            SELECT @LogType     AS [logtype]
                  ,@LogText     AS [logtext]
                  ,@ProcessType AS [ProcessType]
                  ,@LogStatus   AS [logstatus];

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ProcessBatch_ID);
        END;

		IF @@TranCount > 0
		COMMIT
		BEGIN tran;

        UPDATE [dbo].[MFProcessBatch]
        SET 
		[ProcessType] = CASE
                                WHEN @ProcessType IS NULL THEN
                                    [ProcessType]
                                ELSE
                                    @ProcessType
                            END
           ,[LogType] = CASE
                            WHEN @LogType IS NULL THEN
                                [LogType]
                            ELSE
                                @LogType
                        END
           ,[LogText] = CASE
                            WHEN @LogText IS NULL THEN
                                [LogText]
                            ELSE
                                @LogText
                        END
           --,[Status] = CASE
           --                WHEN @LogStatus IS NULL THEN
           --                    'Completed'
           --                ELSE
           --                    @LogStatus
           --            END
           ,[DurationSeconds] = DATEDIFF(ms, [CreatedOnUTC], GETUTCDATE()) / CONVERT(DECIMAL(18, 3), 1000)
        FROM [dbo].[MFProcessBatch]
        WHERE [ProcessBatch_ID] = @ProcessBatch_ID;

		
	/*	
		       SELECT 
        [ProcessType] = CASE
                                WHEN @ProcessType IS NULL THEN
                                    [ProcessType]
                                ELSE
                                    @ProcessType
                            END
           ,[LogType] = CASE
                            WHEN @LogType IS NULL THEN
                                [LogType]
                            ELSE
                                @LogType
                        END
           ,[LogText] = CASE
                            WHEN @LogText IS NULL THEN
                                [LogText]
                            ELSE
                                @LogText
                        END
           ,[Status] = CASE
                           WHEN @LogStatus IS NULL THEN
                               'Completed'
                           ELSE
                               @LogStatus
                       END
           ,[DurationSeconds] = DATEDIFF(ms, [CreatedOnUTC], GETUTCDATE()) / CONVERT(DECIMAL(18, 3), 1000)
        FROM [dbo].[MFProcessBatch]
        WHERE [ProcessBatch_ID] = @ProcessBatch_ID;
       
	   */

        SET @rowcount = @@RowCount;
		SET @rowcount = ISNULL(@rowcount,0);
        SET @ProcedureStep = 'Processbatch update';
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        --SELECT @trancount = @@TranCount;
		--IF @trancount = 0
		--Begin
		--SAVE TRANSACTION [spMFProcessBatch_Upsert]
		--RETURN 1;
		--END

		GOTO EXITPROC;


		EXITPROC:

		    SET @ProcedureStep = 'Commit log';
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;

		  IF @debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

		 COMMIT;
    DECLARE @xstate INT;

    SELECT @xstate = XACT_STATE();
 --   SELECT @xstate AS exactstate

    RETURN 1;
END TRY
BEGIN CATCH
    -----------------------------------------------------------------------------
    -- INSERTING ERROR DETAILS INTO LOG TABLE
    -----------------------------------------------------------------------------
   

    DECLARE @ErrorMessage NVARCHAR(500) = ERROR_MESSAGE();
 --   DECLARE @xstate INT;

    SELECT @xstate = XACT_STATE();

    -----------------------------------------------------------------------------
    -- DISPLAYING ERROR DETAILS
    -----------------------------------------------------------------------------
    SELECT ERROR_NUMBER()    AS [ErrorNumber]
          ,@ErrorMessage     AS [ErrorMessage]
          ,ERROR_PROCEDURE() AS [ErrorProcedure]
          ,ERROR_STATE()     AS [ErrorState]
          ,ERROR_SEVERITY()  AS [ErrorSeverity]
          ,ERROR_LINE()      AS [ErrorLine]
          ,@ProcedureName    AS [ProcedureName]
          ,@ProcedureStep    AS [ProcedureStep];

    --IF @xstate = -1
    --    ROLLBACK;

    --IF @xstate = 1
    --   AND @trancount = 0
    --    INSERT INTO [dbo].[MFLog]
    --    (
    --        [SPName]
    --       ,[ProcedureStep]
    --       ,[ErrorNumber]
    --       ,[ErrorMessage]
    --       ,[ErrorProcedure]
    --       ,[ErrorState]
    --       ,[ErrorSeverity]
    --       ,[ErrorLine]
    --    )
    --    VALUES
    --    (@ProcedureName, @ProcedureStep, ERROR_NUMBER(), @ErrorMessage, ERROR_PROCEDURE(), ERROR_STATE()
    --    ,ERROR_SEVERITY(), ERROR_LINE());

    --IF @xstate = 1
    --   AND @trancount > 0
    --    ROLLBACK TRANSACTION [spmfprocessbatch_Upsert];

    --SET @LogText = 'SQLERROR %s in %s at %s';

    --RAISERROR(@LogText, 16, 1, @ErrorMessage, @ProcedureName, @ProcedureStep);

    RETURN -1;
END CATCH;
GO

GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTable]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFUpdateTable'
                                    -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.48'
                                    -- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

/*
 ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 08-04-2015  Dev 2	   deleting property value from M-Files (Task 57)
  ** 16-04-2015  Dev 2	   Adding update table details to MFUpdateHistory table
  ** 23-04-2015  Dev 2      Removing Last modified & Last modified by from Update data
  ** 24-06-2015  Dev 2	   Skip the object failed to update in M-Files
  ** 30-06-2015  Dev 2	   New error Tracing and Return Value as LeRoux instruction
  ** 18-07-2015  Dev 2	   New parameter add in spMFCreateObjectInternal
  ** 22-2-2016   LC        Improve debugging information; Remove is_template message when updatemethod = 1
  ** 10-03-2016  Dev 2	   Input variable @FromCreateDate  changed to @MFModifiedDate
  ** 10-03-2016  Dev 2	   New input variable added (@ObjIDs)

  18-8-2016 lc add defaults to parameters
  20-8-2016 LC add Update_ID as output paramter
  2016-8-22	LC	Update settings index
  2016-8-22	lc change objids to NVARCHAR(4000)
  2016-09-21  Removed @UserName,@Password,@NetworkAddress and @VaultName parameters and fectch it as comma separated list in @VaultSettings parameter 
              dbo.fnMFVaultSettings() function
  2016-10-10  Change of name of settings table
  2107-5-12		Set processbatchdetail column detail
2017-06-22	LC	add ability to modify external_id
2017-07-03  lc  modify objids filter to include ids not in sql
2017-07-06	LC	add update of filecount column in class table
2017-08-22	Dev2	add sync error correction
2017-08-23	Dev2	add exclude null properties from update
2017-10-1	LC		fix bug with length of fields
2017-11-03 Dve2     Added code to check required property has value or not
2018-04-04 Dev2     Added Licensing module validation code.
2018-5-16	LC		Fix conversion of float to nvarchar
2018-6-26	LC		Improve reporting of return values
2018-08-01	LC		New parameter @RetainDeletions to allow for auto removal of deletions Default = NO
2018-08-01 lc		Fix deletions of record bug
2018-08-23 LC		Fix bug with presedence = 1
2018-10-20 LC		Set Deleted to != 1 instead of = 0 to ensure new records where deleted is not set is taken INSERT 
2018-10-24 LC		resolve bug when objids filter is used with only one object
2018-10-30 LC		removing cursor method for update method 0 and reducing update time by 100%
2018-11-5	LC		include new parapameter to validate class and property structure
2018-12-6	LC		fix bug t.objid not found
2018-12-18	LC		validate that all records have been updated, raise error if not
2019-01-03	LC		fix bug for updating time property
2019-01-13	LC		fix bug for uniqueidentifyer type columns (e.g. guid)
2019-05-19	LC		terminate early if connection cannot be established
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateTable' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateTable]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFUpdateTable]
(
    @MFTableName NVARCHAR(200)
   ,@UpdateMethod INT               --0=Update from SQL to MF only; 
                                    --1=Update new records from MF; 
                                    --2=initialisation 
   ,@UserId NVARCHAR(200) = NULL    --null for all user update
   ,@MFModifiedDate DATETIME = NULL --NULL to select all records
   ,@ObjIDs NVARCHAR(MAX) = NULL
   ,@Update_IDOut INT = NULL OUTPUT
   ,@ProcessBatch_ID INT = NULL OUTPUT
   ,@SyncErrorFlag BIT = 0          -- note this parameter is auto set by the operation 
   ,@RetainDeletions BIT = 0
                                    --   ,@UpdateMetadata BIT = 0
   ,@Debug SMALLINT = 0
)
AS /*******************************************************************************
  ** Desc:  

  
  ** Date:				27-03-2015
  ********************************************************************************
 
  ******************************************************************************/
DECLARE @Update_ID    INT
       ,@return_value INT = 1;

BEGIN TRY
    --BEGIN TRANSACTION
    SET NOCOUNT ON;

    SET XACT_ABORT ON;

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    DECLARE @Id                 INT
           ,@objID              INT
           ,@ObjectIdRef        INT
           ,@ObjVersion         INT
           ,@VaultSettings      NVARCHAR(4000)
           ,@TableName          NVARCHAR(1000)
           ,@XmlOUT             NVARCHAR(MAX)
           ,@NewObjectXml       NVARCHAR(MAX)
           ,@ObjIDsForUpdate    NVARCHAR(MAX)
           ,@FullXml            XML
           ,@SynchErrorObj      NVARCHAR(MAX) --Declared new paramater
           ,@DeletedObjects     NVARCHAR(MAX) --Declared new paramater
           ,@ProcedureName      sysname        = 'spMFUpdateTable'
           ,@ProcedureStep      sysname        = 'Start'
           ,@ObjectId           INT
           ,@ClassId            INT
           ,@Table_ID           INT
           ,@ErrorInfo          NVARCHAR(MAX)
           ,@Query              NVARCHAR(MAX)
           ,@Params             NVARCHAR(MAX)
           ,@SynchErrCount      INT
           ,@ErrorInfoCount     INT
           ,@MFErrorUpdateQuery NVARCHAR(1500)
           ,@MFIDs              NVARCHAR(2500) = ''
           ,@ExternalID         NVARCHAR(200);

    -----------------------------------------------------
    --DECLARE VARIABLES FOR LOGGING
    -----------------------------------------------------
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = '';
    DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
    DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
    DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
    DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
    DECLARE @ProcessType NVARCHAR(50);
    DECLARE @LogType AS NVARCHAR(50) = 'Status';
    DECLARE @LogText AS NVARCHAR(4000) = '';
    DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
    DECLARE @Status AS NVARCHAR(128) = NULL;
    DECLARE @Validation_ID INT = NULL;
    DECLARE @StartTime AS DATETIME;
    DECLARE @RunTime AS DECIMAL(18, 4) = 0;

    IF EXISTS
    (
        SELECT 1
        FROM [sys].[objects]
        WHERE [object_id] = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND [type] IN ( N'U' )
    )
    BEGIN
        -----------------------------------------------------
        --GET LOGIN CREDENTIALS
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Security Variables';

        DECLARE @Username NVARCHAR(2000);
        DECLARE @VaultName NVARCHAR(2000);

        SELECT TOP 1
               @Username  = [Username]
              ,@VaultName = [VaultName]
        FROM [dbo].[MFVaultSettings];

        SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

        -------------------------------------------------------------
        -- Check connection to vault
        -------------------------------------------------------------
        DECLARE @IsUpToDate INT;

        SET @ProcedureStep = 'Connection test: ';

        EXEC @return_value = [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

        IF @return_value < 0
		        BEGIN
            SET @DebugText = 'Connection failed %i';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep,@return_value);
        END;

        -------------------------------------------------------------
        -- Set process type
        -------------------------------------------------------------
        SELECT @ProcessType = CASE
                                  WHEN @UpdateMethod = 0 THEN
                                      'UpdateMFiles'
                                  ELSE
                                      'UpdateSQL'
                              END;

        -------------------------------------------------------------
        --	Create Update_id for process start 
        -------------------------------------------------------------
        SET @ProcedureStep = 'set Update_ID';
        SET @StartTime = GETUTCDATE();

        INSERT INTO [dbo].[MFUpdateHistory]
        (
            [Username]
           ,[VaultName]
           ,[UpdateMethod]
        )
        VALUES
        (@Username, @VaultName, @UpdateMethod);

        SELECT @Update_ID = @@Identity;

        SELECT @Update_IDOut = @Update_ID;

        SET @ProcedureStep = 'Start ';
        SET @StartTime = GETUTCDATE();
        SET @ProcessType = @ProcedureName;
        SET @LogType = 'Status';
        SET @LogStatus = 'Started';
        SET @LogText = 'Update using Update_ID: ' + CAST(@Update_ID AS VARCHAR(10));

        IF @Debug > 9
        BEGIN
            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        EXECUTE @return_value = [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                                                               ,@ProcessType = @ProcessType
                                                               ,@LogType = @LogType
                                                               ,@LogText = @LogText
                                                               ,@LogStatus = @LogStatus
                                                               ,@debug = @Debug;

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + 'Update_ID %i';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Update_ID);
        END;

        -----------------------------------------------------------------
        -- Checking module access for CLR procdure  spMFCreateObjectInternal
        ------------------------------------------------------------------
        EXEC [dbo].[spMFCheckLicenseStatus] 'spMFCreateObjectInternal'
                                           ,@ProcedureName
                                           ,@ProcedureStep;

        -----------------------------------------------------
        --Determine if any filter have been applied
        --if no filters applied then full refresh, else apply filters
        -----------------------------------------------------
        DECLARE @IsFullUpdate BIT;

        SELECT @IsFullUpdate = CASE
                                   WHEN @UserId IS NULL
                                        AND @MFModifiedDate IS NULL
                                        AND @ObjIDs IS NULL THEN
                                       1
                                   ELSE
                                       0
                               END;

        -----------------------------------------------------
        --Convert @UserId to UNIQUEIDENTIFIER type
        -----------------------------------------------------
        SET @UserId = CONVERT(UNIQUEIDENTIFIER, @UserId);
        -----------------------------------------------------
        --Get Table_ID 
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Table ID';
        SET @TableName = @MFTableName;

        SELECT @Table_ID = [object_id]
        FROM [sys].[objects]
        WHERE [name] = @MFTableName;

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + 'Table: %s';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @TableName);
        END;

        -----------------------------------------------------
        --Get Object Type Id
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Object Type and Class';

        SELECT @ObjectIdRef = [MFObjectType_ID]
        FROM [dbo].[MFClass]
        WHERE [TableName] = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

        SELECT @ObjectId = [MFID]
        FROM [dbo].[MFObjectType]
        WHERE [ID] = @ObjectIdRef;

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + ' ObjectType: %i';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId);
        END;

        -----------------------------------------------------
        --Set class id
        -----------------------------------------------------
        SELECT @ClassId = [MFID]
        FROM [dbo].[MFClass]
        WHERE [TableName] = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + ' Class: %i';

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassId);
        END;

        SET @ProcedureStep = 'Prepare Table ';
        SET @LogTypeDetail = 'Status';
        SET @LogStatusDetail = 'Debug';
        SET @LogTextDetail = 'For UpdateMethod ' + CAST(@UpdateMethod AS VARCHAR(10));
        SET @LogColumnName = 'UpdateMethod';
        SET @LogColumnValue = CAST(@UpdateMethod AS VARCHAR(10));

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        -----------------------------------------------------
        --SELECT THE ROW DETAILS DEPENDS ON UPDATE METHOD INPUT
        -----------------------------------------------------
        SET @StartTime = GETUTCDATE();

        -------------------------------------------------------------
        --Delete records if @Retained records set to 0
        -------------------------------------------------------------
        IF @UpdateMethod = 1
           AND @RetainDeletions = 0
        BEGIN
            SET @Query = N'Delete from ' + QUOTENAME(@MFTableName) + ' Where deleted = 1';

            EXEC (@Query);
        END;

        -- end if delete records;

        -------------------------------------------------------------
        -- PROCESS UPDATEMETHOD = 0
        -------------------------------------------------------------
        IF @UpdateMethod = 0 --- processing of process_ID = 1
        BEGIN
            DECLARE @Count          NVARCHAR(10)
                   ,@SelectQuery    NVARCHAR(MAX)    --query snippet to count records
                   ,@vquery         AS NVARCHAR(MAX) --query snippet for filter
                   ,@ParmDefinition NVARCHAR(500);

            -------------------------------------------------------------
            -- Get localisation names for standard properties
            -------------------------------------------------------------
            DECLARE @Columnname NVARCHAR(100);
            DECLARE @lastModifiedColumn NVARCHAR(100);
            DECLARE @ClassPropName NVARCHAR(100);

            SELECT @Columnname = [ColumnName]
            FROM [dbo].[MFProperty]
            WHERE [MFID] = 0;

            SELECT @lastModifiedColumn = [mp].[ColumnName]
            FROM [dbo].[MFProperty] AS [mp]
            WHERE [mp].[MFID] = 21; --'Last Modified'

            SELECT @ClassPropName = [mp].[ColumnName]
            FROM [dbo].[MFProperty] AS [mp]
            WHERE [mp].[MFID] = 100;

            -------------------------------------------------------------
            -- PROCESS FULL UPDATE FOR UPDATE METHOD 0
            -------------------------------------------------------------		

            -------------------------------------------------------------
            -- START BUILDING OF SELECT QUERY FOR FILTER
            -------------------------------------------------------------
            -------------------------------------------------------------
            -- Set select query snippet to count records
            -------------------------------------------------------------
            SET @ParmDefinition = N'@retvalOUT int OUTPUT';
            SET @SelectQuery = 'SELECT @retvalOUT  = COUNT(ID) FROM [' + @MFTableName + '] WHERE ';
            -------------------------------------------------------------
            -- Get column for name or title and set to 'Auto' if left blank
            -------------------------------------------------------------
            SET @Query = N'UPDATE ' + @MFTableName + '
					SET ' + @Columnname + ' = ''Auto''
					WHERE ' + @Columnname + ' IS NULL AND process_id = 1';

            --		PRINT @SQL
            EXEC (@Query);

            -------------------------------------------------------------
            -- create filter query for update method 0
            -------------------------------------------------------------       
            SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'filter snippet for Updatemethod 0';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            IF @SyncErrorFlag = 1
            BEGIN
                SET @vquery = ' Process_ID = 2  ';
            END;
            ELSE
            BEGIN
                SET @vquery = ' Process_ID = 1 ';
            END;

            IF @IsFullUpdate = 0
            BEGIN
                IF (@UserId IS NOT NULL)
                BEGIN
                    SET @vquery = @vquery + 'AND MX_User_ID =''' + CONVERT(NVARCHAR(100), @UserId) + '''';
                END;

                IF (@MFModifiedDate IS NOT NULL)
                BEGIN
                    SET @vquery
                        = @vquery + ' AND ' + QUOTENAME(@lastModifiedColumn) + ' > = '''
                          + CONVERT(NVARCHAR(50), @MFModifiedDate) + '''';
                END;

                IF (@ObjIDs IS NOT NULL)
                BEGIN
                    SET @vquery
                        = @vquery + ' AND ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs + ','','',''))';

                    IF @Debug > 9
                    BEGIN
                        SELECT @ObjIDs;
                    END;
                END;

                IF @Debug > 100
                    SELECT @vquery;
            END; -- end of setting up filter : is full update

            SET @SelectQuery = @SelectQuery + @vquery;

            IF @Debug > 9
            BEGIN
                SET @DebugText = @DefaultDebugText;

                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);

                IF @Debug > 10
                    SELECT @SelectQuery AS [Select records for update];
            END;

            -------------------------------------------------------------
            -- create filter select snippet
            -------------------------------------------------------------
            EXEC [sys].[sp_executesql] @SelectQuery
                                      ,@ParmDefinition
                                      ,@retvalOUT = @Count OUTPUT;

            -------------------------------------------------------------
            -- Set class ID if not included
            -------------------------------------------------------------
            SET @ProcedureStep = 'Set class ID where null';
            SET @Params = N'@ClassID int';
            SET @Query
                = N'UPDATE t
					SET t.' + @ClassPropName + ' = @ClassId
					FROM ' + QUOTENAME(@MFTableName) + ' t WHERE t.process_ID = 1 AND (' + @ClassPropName
                  + ' IS NULL or ' + @ClassPropName + '= -1) AND t.Deleted != 1';

            EXEC [sys].[sp_executesql] @stmt = @Query
                                      ,@Param = @Params
                                      ,@Classid = @ClassId;

            -------------------------------------------------------------
            -- log number of records to be updated
            -------------------------------------------------------------
            SET @StartTime = GETUTCDATE();
            SET @DebugText = 'Count of records i%';
            SET @DebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Start Processing UpdateMethod 0';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
            END;

            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'Count filtered records with process_id = 1 ';
            SET @LogStatusDetail = 'In Progress';
            SET @Validation_ID = NULL;
            SET @LogColumnName = 'process_ID';
            SET @LogColumnValue = CAST(@Count AS NVARCHAR(256));

            EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                         ,@LogType = @LogTypeDetail
                                                                         ,@LogText = @LogTextDetail
                                                                         ,@LogStatus = @LogStatusDetail
                                                                         ,@StartTime = @StartTime
                                                                         ,@MFTableName = @MFTableName
                                                                         ,@Validation_ID = @Validation_ID
                                                                         ,@ColumnName = @LogColumnName
                                                                         ,@ColumnValue = @LogColumnValue
                                                                         ,@Update_ID = @Update_ID
                                                                         ,@LogProcedureName = @ProcedureName
                                                                         ,@LogProcedureStep = @ProcedureStep
                                                                         ,@debug = @Debug;

            --------------------------------------------------------------------------------------------
            --If Any record Updated/Insert in SQL and @UpdateMethod = 0(0=Update from SQL to MF only)
            --------------------------------------------------------------------------------------------
            IF (@Count > '0' AND @UpdateMethod = 0)
            BEGIN
                DECLARE @vsql    AS NVARCHAR(MAX)
                       ,@XMLFile XML
                       ,@XML     NVARCHAR(MAX);

                SET @FullXml = NULL;
                --	-------------------------------------------------------------
                --	-- anchor list of objects to be updated
                --	-------------------------------------------------------------
                --	    SET @Query = '';
                --		  Declare    @ObjectsToUpdate VARCHAR(100)

                --      SET @ProcedureStep = 'Filtered objects to update';
                --      SELECT @ObjectsToUpdate = [dbo].[fnMFVariableTableName]('##UpdateList', DEFAULT);

                -- SET @Query = 'SELECT * INTO '+ @ObjectsToUpdate +' FROM 
                --  (SELECT ID from '                       + QUOTENAME(@MFTableName) + ' where 
                --' + @vquery + ' )list ';

                --IF @Debug > 0
                --SELECT @Query AS FilteredRecordsQuery;

                --EXEC (@Query)

                -------------------------------------------------------------
                -- start column value pair for update method 0
                -------------------------------------------------------------
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Create Column Value Pair';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                CREATE TABLE [#ColumnValuePair]
                (
                    [Id] INT
                   ,[objID] INT
                   ,[ObjVersion] INT
                   ,[ExternalID] NVARCHAR(100)
                   ,[ColumnName] NVARCHAR(200)
                   ,[ColumnValue] NVARCHAR(4000)
                   ,[Required] INT
                   ,[MFID] INT
                   ,[DataType] INT
                );

                CREATE INDEX [IDX_ColumnValuePair_ColumnName]
                ON [#ColumnValuePair] ([ColumnName]);

                DECLARE @colsUnpivot AS NVARCHAR(MAX)
                       ,@colsPivot   AS NVARCHAR(MAX)
                       ,@DeleteQuery AS NVARCHAR(MAX)
                       ,@rownr       INT
                       ,@Datatypes   NVARCHAR(100);

                -------------------------------------------------------------
                -- prepare column value pair query based on data types
                -------------------------------------------------------------
                SET @Query = '';

                DECLARE @DatatypeTable AS TABLE
                (
                    [id] INT IDENTITY
                   ,[Datatypes] NVARCHAR(20)
                   ,[Type_Ids] NVARCHAR(100)
                );

                INSERT INTO @DatatypeTable
                (
                    [Datatypes]
                   ,[Type_Ids]
                )
                VALUES
                (   N'Float' -- Datatypes - nvarchar(20)
                   ,N'3'     -- Type_Ids - nvarchar(100)
                    )
               ,('Integer', '2,8,10')
               ,('Text', '1')
               ,('MultiText', '12')
               ,('MultiLookup', '9')
               ,('Time', '5')
               ,('DateTime', '6')
               ,('Date', '4')
               ,('Bit', '7');

                SET @rownr = 1;
                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'loop through Columns';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                WHILE @rownr IS NOT NULL
                BEGIN
                    SELECT @Datatypes = [dt].[Type_Ids]
                    FROM @DatatypeTable AS [dt]
                    WHERE [dt].[id] = @rownr;

                    SET @DebugText = 'DataTypes %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Create Column Value Pair';

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Datatypes);
                    END;

                    SELECT @colsUnpivot
                        = STUFF(
                          (
                              SELECT ',' + QUOTENAME([C].[name])
                              FROM [sys].[columns]              AS [C]
                                  INNER JOIN [dbo].[MFProperty] AS [mp]
                                      ON [mp].[ColumnName] = [C].[name]
                              WHERE [C].[object_id] = OBJECT_ID(@MFTableName)
                                    AND ISNULL([mp].[MFID], -1) NOT IN ( - 1, 20, 21, 23, 25 )
                                    AND [mp].[ColumnName] <> 'Deleted'
                                    AND [mp].[MFDataType_ID] IN (
                                                                    SELECT [ListItem] FROM [dbo].[fnMFParseDelimitedString](
                                                                                                                               @Datatypes
                                                                                                                              ,','
                                                                                                                           )
                                                                )
                              FOR XML PATH('')
                          )
                         ,1
                         ,1
                         ,''
                               );

                    IF @Debug > 0
                        SELECT @colsUnpivot AS 'columns';

                    IF @colsUnpivot IS NOT NULL
                    BEGIN
                        SET @Query
                            = @Query
                              + 'Union All
 select ID,  Objid, MFversion, ExternalID, Name as ColumnName, CAST(value AS VARCHAR(4000)) AS Value
        from '                       + QUOTENAME(@MFTableName)
                              + ' t
        unpivot
        (
          value for name in ('       + @colsUnpivot + ')
        ) unpiv
		where 
		'                            + @vquery + ' ';
                    END;

                    SELECT @rownr =
                    (
                        SELECT MIN([dt].[id])
                        FROM @DatatypeTable AS [dt]
                        WHERE [dt].[id] > @rownr
                    );
                END;

                SET @DeleteQuery
                    = N'Union All Select ID, Objid, MFversion, ExternalID, ''Deleted'' as ColumnName, cast(isnull(Deleted,0) as nvarchar(4000))  as Value from '
                      + QUOTENAME(@MFTableName) + ' t where ' + @vquery + ' ';

                --SELECT @DeleteQuery AS deletequery
                SELECT @Query = SUBSTRING(@Query, 11, 8000) + @DeleteQuery;

                IF @Debug > 100
                    PRINT @Query;

                -------------------------------------------------------------
                -- insert into column value pair
                -------------------------------------------------------------
                SELECT @Query
                    = 'INSERT INTO  #ColumnValuePair

SELECT ID,ObjID,MFVersion,ExternalID,ColumnName,Value,NULL,null,null from 
(' +                @Query + ') list';

                IF @Debug = 100
                BEGIN
                    SELECT @Query AS 'ColumnValue pair query';
                END;

                EXEC (@Query);

                -------------------------------------------------------------
                -- Validate class and proerty requirements
                -------------------------------------------------------------
                IF @IsUpToDate = 0
                BEGIN
                    EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'Property';

                    EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'class';

                    WITH [cte]
                    AS (SELECT [mfms].[Property]
                        FROM [dbo].[MFvwMetadataStructure] AS [mfms]
                        WHERE [mfms].[TableName] = @MFTableName
                              AND [mfms].[Property_MFID] NOT IN ( 20, 21, 23, 25 )
                              AND [mfms].[Required] = 1
                        EXCEPT
                        (SELECT [mp].[Name]
                         FROM [#ColumnValuePair]           AS [cvp]
                             INNER JOIN [dbo].[MFProperty] [mp]
                                 ON [cvp].[ColumnName] = [mp].[ColumnName]))
                    INSERT INTO [#ColumnValuePair]
                    (
                        [Id]
                       ,[objID]
                       ,[ObjVersion]
                       ,[ExternalID]
                       ,[ColumnName]
                       ,[ColumnValue]
                       ,[Required]
                       ,[MFID]
                       ,[DataType]
                    )
                    SELECT [cvp].[Id]
                          ,[cvp].[objID]
                          ,[cvp].[ObjVersion]
                          ,[cvp].[ExternalID]
                          ,[mp].[ColumnName]
                          ,'ZZZ'
                          ,1
                          ,[mp].[MFID]
                          ,[mp].[MFDataType_ID]
                    FROM [#ColumnValuePair] AS [cvp]
                        CROSS APPLY [cte]
                        INNER JOIN [dbo].[MFProperty] AS [mp]
                            ON [cte].[Property] = [mp].[Name]
                    GROUP BY [cvp].[Id]
                            ,[cvp].[objID]
                            ,[cvp].[ObjVersion]
                            ,[cvp].[ExternalID]
                            ,[mp].[ColumnName]
                            ,[mp].[MFDataType_ID]
                            ,[mp].[MFID];
                END;

                -------------------------------------------------------------
                -- check for required data missing
                -------------------------------------------------------------
                IF
                (
                    SELECT COUNT(*)
                    FROM [#ColumnValuePair] AS [cvp]
                    WHERE [cvp].[ColumnValue] = 'ZZZ'
                          AND [cvp].[Required] = 1
                ) > 0
                BEGIN
                    DECLARE @missingColumns NVARCHAR(4000);

                    SELECT @missingColumns = STUFF((
                                                       SELECT ',' + [cvp].[ColumnName]
                                                       FROM [#ColumnValuePair] AS [cvp]
                                                       WHERE [cvp].[ColumnValue] = 'ZZZ'
                                                             AND [cvp].[Required] = 1
                                                       FOR XML PATH('')
                                                   )
                                                  ,1
                                                  ,1
                                                  ,''
                                                  );

                    SET @DebugText = ' in columns: ' + @missingColumns;
                    SET @DebugText = @DefaultDebugText + @DebugText;
                    SET @ProcedureStep = 'Required data missing';

                    RAISERROR(@DebugText, 16, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- update column value pair properties
                -------------------------------------------------------------
                UPDATE [CVP]
                SET [CVP].[Required] = CASE
                                           WHEN [c2].[is_nullable] = 1 THEN
                                               0
                                           ELSE
                                               1
                                       END
                   ,[CVP].[ColumnValue] = CASE
                                              WHEN ISNULL([CVP].[ColumnValue], '-1') = '-1'
                                                   AND [c2].[is_nullable] = 0 THEN
                                                  'ZZZ'
                                              ELSE
                                                  [CVP].[ColumnValue]
                                          END
                --SELECT p.name, p.mfid,cp.required
                FROM [#ColumnValuePair]        [CVP]
                    INNER JOIN [sys].[columns] AS [c2]
                        ON [CVP].[ColumnName] = [c2].[name]
                WHERE [c2].[object_id] = OBJECT_ID(@MFTableName);

                UPDATE [cvp]
                SET [cvp].[MFID] = [mp].[MFID]
                   ,[cvp].[DataType] = [mdt].[MFTypeID]
                   ,[cvp].[ColumnValue] = CASE
                                              WHEN [mp].[MFID] = 27
                                                   AND [cvp].[ColumnValue] = '0' THEN
                                                  'ZZZ'
                                              ELSE
                                                  [cvp].[ColumnValue]
                                          END
                FROM [#ColumnValuePair]           AS [cvp]
                    INNER JOIN [dbo].[MFProperty] AS [mp]
                        ON [cvp].[ColumnName] = [mp].[ColumnName]
                    INNER JOIN [dbo].[MFDataType] AS [mdt]
                        ON [mp].[MFDataType_ID] = [mdt].[ID];

                -------------------------------------------------------------
                -- END of preparating column value pair
                -------------------------------------------------------------
                SELECT @Count = COUNT(*)
                FROM [#ColumnValuePair] AS [cvp];

                SET @ProcedureStep = 'ColumnValue Pair ';
                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'Properties for update ';
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnName = 'Properties';
                SET @LogColumnValue = CAST(@Count AS NVARCHAR(256));
                SET @DebugText = 'Column Value Pair: %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Count);
                END;

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                             ,@LogType = @LogTypeDetail
                                                                             ,@LogText = @LogTextDetail
                                                                             ,@LogStatus = @LogStatusDetail
                                                                             ,@StartTime = @StartTime
                                                                             ,@MFTableName = @MFTableName
                                                                             ,@Validation_ID = @Validation_ID
                                                                             ,@ColumnName = @LogColumnName
                                                                             ,@ColumnValue = @LogColumnValue
                                                                             ,@Update_ID = @Update_ID
                                                                             ,@LogProcedureName = @ProcedureName
                                                                             ,@LogProcedureStep = @ProcedureStep
                                                                             ,@debug = @Debug;

                SET @DebugText = '';
                SET @DebugText = @DefaultDebugText + @DebugText;
                SET @ProcedureStep = 'Creating XML for Process_ID = 1';

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -----------------------------------------------------
                --Generate xml file -- 
                -----------------------------------------------------
                SET @XMLFile =
                (
                    SELECT @ObjectId          AS [Object/@id]
                          ,[cvp].[Id]         AS [Object/@sqlID]
                          ,[cvp].[objID]      AS [Object/@objID]
                          ,[cvp].[ObjVersion] AS [Object/@objVesrion]
                          ,[cvp].[ExternalID] AS [Object/@DisplayID] --Added For Task #988
                                                                     --     ( SELECT
                                                                     --       @ClassId AS 'class/@id' ,
                          ,(
                               SELECT
                                   (
                                       SELECT TOP 1
                                              [tmp1].[ColumnValue]
                                       FROM [#ColumnValuePair] AS [tmp1]
                                       WHERE [tmp1].[MFID] = 100
                                   ) AS [class/@id]
                                  ,(
                                       SELECT [tmp].[MFID]     AS [property/@id]
                                             ,[tmp].[DataType] AS [property/@dataType]
                                             ,CASE
                                                  WHEN [tmp].[ColumnValue] = 'ZZZ' THEN
                                                      NULL
                                                  ELSE
                                                      [tmp].[ColumnValue]
                                              END              AS 'property' ----Added case statement for checking Required property
                                       FROM [#ColumnValuePair] AS [tmp]
                                       WHERE [tmp].[MFID] <> 100
                                             AND [tmp].[ColumnValue] IS NOT NULL
                                             AND [tmp].[Id] = [cvp].[Id]
                                       GROUP BY [tmp].[Id]
                                               ,[tmp].[MFID]
                                               ,[tmp].[DataType]
                                               ,[tmp].[ColumnValue]
                                       ORDER BY [tmp].[Id]
                                       --- excluding duplicate class and [tmp].[ColumnValue] is not null added for task 1103
                                       FOR XML PATH(''), TYPE
                                   ) AS [class]
                               FOR XML PATH(''), TYPE
                           )                  AS [Object]
                    FROM [#ColumnValuePair] AS [cvp]
                    GROUP BY [cvp].[Id]
                            ,[cvp].[objID]
                            ,[cvp].[ObjVersion]
                            ,[cvp].[ExternalID]
                    ORDER BY [cvp].[Id]
                    FOR XML PATH(''), ROOT('form')
                );
                SET @XMLFile =
                (
                    SELECT @XMLFile.[query]('/form/*')
                );

                --------------------------------------------------------------------------------------------------
                IF @Debug > 100
                    SELECT @XMLFile AS [@XMLFile];

                SET @FullXml
                    = ISNULL(CAST(@FullXml AS NVARCHAR(MAX)), '') + ISNULL(CAST(@XMLFile AS NVARCHAR(MAX)), '');

                IF @Debug > 100
                BEGIN
                    SELECT *
                    FROM [#ColumnValuePair] AS [cvp];
                END;

                SET @ProcedureStep = 'Get Full Xml';

                IF @Debug > 9
                    RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

                --Count records for ProcessBatchDetail
                SET @ParmDefinition = N'@Count int output';
                SET @Query = N'
					SELECT @Count = COUNT(*) FROM ' + @MFTableName + ' WHERE process_ID = 1';

                EXEC [sys].[sp_executesql] @stmt = @Query
                                          ,@param = @ParmDefinition
                                          ,@Count = @Count OUTPUT;

                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'XML Records for Updated method 0 ';
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnName = 'process_ID = 1';
                SET @LogColumnValue = CAST(@Count AS VARCHAR(5));

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                             ,@LogType = @LogTypeDetail
                                                                             ,@LogText = @LogTextDetail
                                                                             ,@LogStatus = @LogStatusDetail
                                                                             ,@StartTime = @StartTime
                                                                             ,@MFTableName = @MFTableName
                                                                             ,@Validation_ID = @Validation_ID
                                                                             ,@ColumnName = @LogColumnName
                                                                             ,@ColumnValue = @LogColumnValue
                                                                             ,@Update_ID = @Update_ID
                                                                             ,@LogProcedureName = @ProcedureName
                                                                             ,@LogProcedureStep = @ProcedureStep
                                                                             ,@debug = @Debug;

                IF EXISTS (SELECT (OBJECT_ID('tempdb..#ColumnValuePair')))
                    DROP TABLE [#ColumnValuePair];
            END; -- end count > 0 and update method = 0
        END;

        -- End If Updatemethod = 0

        -----------------------------------------------------
        --IF Null Creating XML with ObjectTypeID and ClassId
        -----------------------------------------------------
        IF (@FullXml IS NULL)
        BEGIN
            SET @FullXml =
            (
                SELECT @ObjectId   AS [Object/@id]
                      ,@Id         AS [Object/@sqlID]
                      ,@objID      AS [Object/@objID]
                      ,@ObjVersion AS [Object/@objVesrion]
                      ,@ExternalID AS [Object/@DisplayID] --Added for Task #988
                      ,(
                           SELECT @ClassId AS [class/@id] FOR XML PATH(''), TYPE
                       )           AS [Object]
                FOR XML PATH(''), ROOT('form')
            );
            SET @FullXml =
            (
                SELECT @FullXml.[query]('/form/*')
            );
        END;

        SET @XML = '<form>' + (CAST(@FullXml AS NVARCHAR(MAX))) + '</form>';

        --------------------------------------------------------------------
        --create XML for @UpdateMethod !=0 (0=Update from SQL to MF only)
        -----------------------------------------------------
        SET @StartTime = GETUTCDATE();

        IF (@UpdateMethod != 0)
        BEGIN
            SET @ProcedureStep = 'Xml for Process_ID = 0 ';

            DECLARE @ObjVerXML          XML
                   ,@ObjVerXMLForUpdate XML
                   ,@CreateXmlQuery     NVARCHAR(MAX);

            IF @Debug > 9
                RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            -----------------------------------------------------
            --Create XML with All ObjVer Exists in SQL
            -----------------------------------------------------

            -------------------------------------------------------------
            -- for full update updatemethod 1
            -------------------------------------------------------------
            IF @IsFullUpdate = 1
            BEGIN
                SET @DebugText = ' Full Update';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                SET @CreateXmlQuery
                    = 'SELECT @ObjVerXML = (
								SELECT ' + CAST(@ObjectId AS NVARCHAR(20))
                      + ' AS ''ObjectType/@id'' ,(
										SELECT objID ''objVers/@objectID''
											,MFVersion ''objVers/@version''
											,GUID ''objVers/@objectGUID''
										FROM [' + @MFTableName
                      + ']
										WHERE Process_ID = 0
										FOR XML PATH('''')
											,TYPE
										) AS ObjectType
								FOR XML PATH('''')
									,ROOT(''form'')
								)';

                EXEC [sys].[sp_executesql] @CreateXmlQuery
                                          ,N'@ObjVerXML XML OUTPUT'
                                          ,@ObjVerXML OUTPUT;

                DECLARE @ObjVerXmlString NVARCHAR(MAX);

                SET @ObjVerXmlString = CAST(@ObjVerXML AS NVARCHAR(MAX));

                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXmlString AS [@ObjVerXmlString];
                END;
            END;

            -------------------------------------------------------------
            -- for filtered update update method 0
            -------------------------------------------------------------
            IF @IsFullUpdate = 0
            BEGIN
                SET @ProcedureStep = ' Prepare query for filters ';
                SET @DebugText = ' Filtered Update ';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
                END;

                -------------------------------------------------------------
                -- Sync error flag snippet
                -------------------------------------------------------------
                IF (@SyncErrorFlag = 0)
                BEGIN
                    SET @CreateXmlQuery
                        = 'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM [' + @MFTableName + ']
													WHERE Process_ID = 0 ';
                END;
                ELSE
                BEGIN
                    SET @CreateXmlQuery
                        = 'SELECT @ObjVerXMLForUpdate = (	
													SELECT objID ''objVers/@objectID''
														,MFVersion ''objVers/@version''
														,GUID ''objVers/@objectGUID''
													FROM [' + @MFTableName + ']
													WHERE Process_ID = 2 ';
                END;

                -------------------------------------------------------------
                -- Filter snippet
                -------------------------------------------------------------
                IF (@MFModifiedDate IS NOT NULL)
                BEGIN
                    SET @CreateXmlQuery
                        = @CreateXmlQuery + 'AND ' + QUOTENAME(@lastModifiedColumn) + ' > = '''
                          + CAST(@MFModifiedDate AS VARCHAR(MAX)) + ''' ';
                END;

                IF (@ObjIDs IS NOT NULL)
                BEGIN
                    SET @CreateXmlQuery
                        = @CreateXmlQuery + 'AND ObjID in (SELECT * FROM dbo.fnMFSplitString(''' + @ObjIDs
                          + ''','',''))';
                END;

                --end filters 
                -------------------------------------------------------------
                -- Compile XML query from snippets
                -------------------------------------------------------------
                SET @CreateXmlQuery = @CreateXmlQuery + ' FOR XML PATH(''''),ROOT(''form''))';

                IF @Debug > 9
                    SELECT @CreateXmlQuery AS [@CreateXmlQuery];

                SET @Params = N'@ObjVerXMLForUpdate XML OUTPUT';

                EXEC [sys].[sp_executesql] @CreateXmlQuery
                                          ,@Params
                                          ,@ObjVerXMLForUpdate OUTPUT;

                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
                END;

                -------------------------------------------------------------
                -- validate Objids
                -------------------------------------------------------------
                SET @ProcedureStep = 'Identify Object IDs ';

                IF @ObjIDs != ''
                BEGIN
                    SET @DebugText = 'Objids %s';
                    SET @DebugText = @DefaultDebugText + @DebugText;

                    IF @Debug > 0
                    BEGIN
                        RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjIDs);
                    END;

                    DECLARE @missingXML NVARCHAR(MAX); ---Bug 1098  VARCHAR(8000) to  VARCHAR(max) 
                    DECLARE @objects NVARCHAR(MAX);

                    IF ISNULL(@SyncErrorFlag, 0) = 0 -- exclude routine when sync flag = 1 is processed
                    BEGIN
                        EXEC [dbo].[spMFGetMissingobjectIds] @ObjIDs
                                                            ,@MFTableName
                                                            ,@missing = @objects OUTPUT;

                        SET @DebugText = ' sync flag 0:  Missing objects %s ';
                        SET @DebugText = @DefaultDebugText + @DebugText;

                        IF @Debug > 0
                        BEGIN
                            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objects);
                        END;
                    END;
                    ELSE
                    BEGIN
                        IF @SyncErrorFlag = 1
                        BEGIN
                            SET @objects = @ObjIDs;
                            SET @DebugText = ' SyncFlag 1: Missing objects %s ';
                            SET @DebugText = @DefaultDebugText + @DebugText;

                            IF @Debug > 0
                            BEGIN
                                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objects);
                            END;
                        END;
                    END;

                    SET @missingXML = @objects;

                    IF @Debug > 9
                        SELECT @missingXML AS [@missingXML];

                    -------------------------------------------------------------
                    -- set objverXML for update XML
                    -------------------------------------------------------------
                    IF (@ObjVerXMLForUpdate IS NULL)
                    BEGIN
                        SET @ObjVerXMLForUpdate = '<form>' + CAST(@missingXML AS NVARCHAR(MAX)) + ' </form>';
                    END;
                    ELSE
                    BEGIN
                        SET @ObjVerXMLForUpdate
                            = REPLACE(CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX)), '</form>', @missingXML + '</form>');
                    END;
                END;
                ELSE
                BEGIN
                    SET @ObjVerXMLForUpdate = NULL;
                END;

                IF @Debug > 9
                BEGIN
                    SELECT @ObjVerXMLForUpdate AS [@ObjVerXMLForUpdate];
                END;

                -------------------------------------------------------------
                -- Set the objectver detail XML
                -------------------------------------------------------------
                SET @ProcedureStep = 'ObjverDetails for Update';

                -------------------------------------------------------------
                -- count detail items
                -------------------------------------------------------------
                DECLARE @objVerDetails_Count INT;

                SELECT @objVerDetails_Count = COUNT([o].[objectid])
                FROM
                (
                    SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
                    FROM @ObjVerXMLForUpdate.[nodes]('/form/Object') AS [t1]([c1])
                ) AS [o];

                SET @DebugText = 'Count of objects %i';
                SET @DebugText = @DefaultDebugText + @DebugText;

                IF @Debug > 0
                BEGIN
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @objVerDetails_Count);
                END;

                SET @LogTypeDetail = 'Debug';
                SET @LogTextDetail = 'XML Records in ObjVerDetails for MFiles';
                SET @LogStatusDetail = 'In Progress';
                SET @Validation_ID = NULL;
                SET @LogColumnValue = CAST(@objVerDetails_Count AS VARCHAR(10));
                SET @LogColumnName = 'ObjectVerDetails';

                EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                             ,@LogType = @LogTypeDetail
                                                                             ,@LogText = @LogTextDetail
                                                                             ,@LogStatus = @LogStatusDetail
                                                                             ,@StartTime = @StartTime
                                                                             ,@MFTableName = @MFTableName
                                                                             ,@Validation_ID = @Validation_ID
                                                                             ,@ColumnName = @LogColumnName
                                                                             ,@ColumnValue = @LogColumnValue
                                                                             ,@Update_ID = @Update_ID
                                                                             ,@LogProcedureName = @ProcedureName
                                                                             ,@LogProcedureStep = @ProcedureStep
                                                                             ,@debug = @Debug;

                SET @ProcedureStep = 'Set input XML parameters';
                SET @ObjVerXmlString = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
                SET @ObjIDsForUpdate = CAST(@ObjVerXMLForUpdate AS NVARCHAR(MAX));
            END;
        END;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            IF @Debug > 10
                SELECT @XML             AS [XML]
                      ,@ObjVerXmlString AS [ObjVerXmlString]
                      ,@ObjIDsForUpdate AS [@ObjIDsForUpdate]
                      ,@UpdateMethod    AS [UpdateMethod];
        END;

        -------------------------------------------------------------
        -- Get property MFIDs
        -------------------------------------------------------------
        SET @ProcedureStep = 'Get property MFIDs';

        SELECT @MFIDs = @MFIDs + CAST(ISNULL([MFP].[MFID], '') AS NVARCHAR(10)) + ','
        FROM [INFORMATION_SCHEMA].[COLUMNS] AS [CLM]
            LEFT JOIN [dbo].[MFProperty]    AS [MFP]
                ON [MFP].[ColumnName] = [CLM].[COLUMN_NAME]
        WHERE [CLM].[TABLE_NAME] = @MFTableName;

        SELECT @MFIDs = LEFT(@MFIDs, LEN(@MFIDs) - 1); -- Remove last ','

        IF @Debug > 10
        BEGIN
            SELECT @MFIDs AS [List of Properties];
        END;

        SET @ProcedureStep = 'Update MFUpdateHistory';

        UPDATE [dbo].[MFUpdateHistory]
        SET [ObjectDetails] = @XML
           ,[ObjectVerDetails] = @ObjVerXmlString
        WHERE [Id] = @Update_ID;

        IF @Debug > 9
            RAISERROR(
                         'Proc: %s Step: %s ObjectVerDetails Count: %i'
                        ,10
                        ,1
                        ,@ProcedureName
                        ,@ProcedureStep
                        ,@objVerDetails_Count
                     );

        -----------------------------------------------------
        --Process Wrapper Method
        -----------------------------------------------------
        SET @ProcedureStep = 'CLR Update in MFiles';
        SET @StartTime = GETUTCDATE();

        --IF @Debug > 99
        --BEGIN
        --    SELECT CAST(@XML AS NVARCHAR(MAX))
        --          ,CAST(@ObjVerXmlString AS NVARCHAR(MAX))
        --          ,CAST(@MFIDs AS NVARCHAR(MAX))
        --          ,CAST(@MFModifiedDate AS NVARCHAR(MAX))
        --          ,CAST(@ObjIDsForUpdate AS NVARCHAR(MAX));
        --END;

        ------------------------Added for checking required property null-------------------------------	
        EXECUTE @return_value = [dbo].[spMFCreateObjectInternal] @VaultSettings
                                                                ,@XML
                                                                ,@ObjVerXmlString
                                                                ,@MFIDs
                                                                ,@UpdateMethod
                                                                ,@MFModifiedDate
                                                                ,@ObjIDsForUpdate
                                                                ,@XmlOUT OUTPUT
                                                                ,@NewObjectXml OUTPUT
                                                                ,@SynchErrorObj OUTPUT  --Added new paramater
                                                                ,@DeletedObjects OUTPUT --Added new paramater
                                                                ,@ErrorInfo OUTPUT;

        IF @NewObjectXml = ''
            SET @NewObjectXml = NULL;

        IF @Debug > 10
        BEGIN
            RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 10, 1, @ProcedureName, @ProcedureStep, @ErrorInfo);
        END;

        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail = 'Wrapper turnaround';
        SET @LogStatusDetail = 'Assembly';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = '';
        SET @LogColumnName = '';

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        DECLARE @idoc2 INT;
        DECLARE @idoc3 INT;
        DECLARE @DeletedXML XML;

        SET @ProcedureStep = 'CLR Update in MFiles';

        -------------------------------------------------------------
        -- 
        -------------------------------------------------------------
        IF @Debug > 100
        BEGIN
            SELECT @DeletedObjects AS [DeletedObjects];

            SELECT @NewObjectXml AS [NewObjectXml];
        END;

        EXEC [sys].[sp_xml_preparedocument] @idoc2 OUTPUT, @NewObjectXml;

        IF @DeletedObjects IS NULL
        BEGIN

            --          --	EXEC [sys].[sp_xml_preparedocument] @idoc2 OUTPUT, @NewObjectXml;
            SET @DeletedXML = NULL;
        --(
        --    SELECT *
        --    FROM
        --    (
        --        SELECT [objectID]
        --        FROM
        --            OPENXML(@idoc2, '/form/Object/properties', 1)
        --            WITH
        --            (
        --                [objectID] INT '../@objectId'
        --               ,[propertyId] INT '@propertyId'
        --            )
        --        WHERE [propertyId] = 27
        --    ) AS [objVers]
        --    FOR XML AUTO
        --);
        END;
        ELSE
        BEGIN
            EXEC [sys].[sp_xml_preparedocument] @idoc3 OUTPUT, @DeletedObjects;

            SET @DeletedXML =
            (
                SELECT *
                FROM
                (
                    SELECT [objectID]
                    FROM
                        OPENXML(@idoc3, 'form/objVers', 1) WITH ([objectID] INT '@objectID')
                ) AS [objVers]
                FOR XML AUTO
            );
        END;

        IF @Debug > 100
            SELECT @DeletedXML AS [DeletedXML];

        -------------------------------------------------------------
        -- Remove records returned from M-Files that is not part of the class
        -------------------------------------------------------------

        -------------------------------------------------------------
        -- Update SQL
        -------------------------------------------------------------
        SET @StartTime = GETUTCDATE();

        IF (@Update_ID > 0)
            UPDATE [dbo].[MFUpdateHistory]
            SET [NewOrUpdatedObjectVer] = @XmlOUT
               ,[NewOrUpdatedObjectDetails] = @NewObjectXml
               ,[SynchronizationError] = @SynchErrorObj
               ,[DeletedObjectVer] = @DeletedXML
               ,[MFError] = @ErrorInfo
            WHERE [Id] = @Update_ID;

        DECLARE @NewOrUpdatedObjectDetails_Count INT
               ,@NewOrUpdateObjectXml            XML;

        SET @ProcedureStep = 'Prepare XML for update into SQL';
        SET @NewOrUpdateObjectXml = CAST(@NewObjectXml AS XML);

        SELECT @NewOrUpdatedObjectDetails_Count = COUNT([o].[objectid])
        FROM
        (
            SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
            FROM @NewOrUpdateObjectXml.[nodes]('/form/Object') AS [t1]([c1])
        ) AS [o];

        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail = 'XML NewOrUpdatedObjectDetails returned';
        SET @LogStatusDetail = 'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = CAST(@NewOrUpdatedObjectDetails_Count AS VARCHAR(10));
        SET @LogColumnName = 'NewOrUpdatedObjectDetails';

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        DECLARE @NewOrUpdatedObjectVer_Count INT
               ,@NewOrUpdateObjectVerXml     XML;

        SET @NewOrUpdateObjectVerXml = CAST(@XmlOUT AS XML);

        SELECT @NewOrUpdatedObjectVer_Count = COUNT([o].[objectid])
        FROM
        (
            SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
            FROM @NewOrUpdateObjectVerXml.[nodes]('/form/Object') AS [t1]([c1])
        ) AS [o];

        SET @LogTypeDetail = 'Debug';
        SET @LogTextDetail = 'ObjVer returned';
        SET @LogStatusDetail = 'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnValue = CAST(@NewOrUpdatedObjectVer_Count AS VARCHAR(10));
        SET @LogColumnName = 'NewOrUpdatedObjectVer';

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        DECLARE @IDoc INT;

        --         SET @ProcedureName = 'SpmfUpdateTable';
        --    SET @ProcedureStep = 'Updating MFTable with ObjID and MFVersion';
        --        SET @StartTime = GETUTCDATE();
        CREATE TABLE [#ObjVer]
        (
            [ID] INT
           ,[ObjID] INT
           ,[MFVersion] INT
           ,[GUID] NVARCHAR(100)
           ,[FileCount] INT ---- Added for task 106
        );

        DECLARE @NewXML XML;

        SET @NewXML = CAST(@XmlOUT AS XML);

        DECLARE @NewObjVerDetails_Count INT;

        SELECT @NewObjVerDetails_Count = COUNT([o].[objectid])
        FROM
        (
            SELECT [t1].[c1].[value]('(@objectId)[1]', 'INT') AS [objectid]
            FROM @NewXML.[nodes]('/form/Object') AS [t1]([c1])
        ) AS [o];

        INSERT INTO [#ObjVer]
        (
            [MFVersion]
           ,[ObjID]
           ,[ID]
           ,[GUID]
           ,[FileCount]
        )
        SELECT [t].[c].[value]('(@objVersion)[1]', 'INT')           AS [MFVersion]
              ,[t].[c].[value]('(@objectId)[1]', 'INT')             AS [ObjID]
              ,[t].[c].[value]('(@ID)[1]', 'INT')                   AS [ID]
              ,[t].[c].[value]('(@objectGUID)[1]', 'NVARCHAR(100)') AS [GUID]
              ,[t].[c].[value]('(@FileCount)[1]', 'INT')            AS [FileCount] -- Added for task 106
        FROM @NewXML.[nodes]('/form/Object') AS [t]([c]);

        SET @Count = @@RowCount;

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

            IF @Debug > 10
                SELECT *
                FROM [#ObjVer];
        END;

        DECLARE @UpdateQuery NVARCHAR(MAX);

        SET @UpdateQuery
            = '	UPDATE ['    + @MFTableName + ']
					SET [' + @MFTableName + '].ObjID = #ObjVer.ObjID
					,['    + @MFTableName + '].MFVersion = #ObjVer.MFVersion
					,['    + @MFTableName + '].GUID = #ObjVer.GUID
					,['    + @MFTableName
              + '].FileCount = #ObjVer.FileCount     ---- Added for task 106
					,Process_ID = 0
					,Deleted = 0
					,LastModified = GETDATE()
					FROM #ObjVer
					WHERE [' + @MFTableName + '].ID = #ObjVer.ID';

        EXEC (@UpdateQuery);

        SET @ProcedureStep = 'Update Records in ' + @MFTableName + '';
        SET @LogTextDetail = @ProcedureStep;
        SET @LogStatusDetail = 'Output';
        SET @Validation_ID = NULL;
        SET @LogColumnName = 'NewObjVerDetails';
        SET @LogColumnValue = CAST(@NewObjVerDetails_Count AS VARCHAR(10));

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        DROP TABLE [#ObjVer];

        ----------------------------------------------------------------------------------------------------------
        --Update Process_ID to 2 when synch error occcurs--
        ----------------------------------------------------------------------------------------------------------
        SET @ProcedureStep = 'when synch error occurs';
        SET @StartTime = GETUTCDATE();

        ----------------------------------------------------------------------------------------------------------
        --Create an internal representation of the XML document. 
        ---------------------------------------------------------------------------------------------------------                
        CREATE TABLE [#SynchErrObjVer]
        (
            [ID] INT
           ,[ObjID] INT
           ,[MFVersion] INT
        );

        IF @Debug > 9
            RAISERROR('Proc: %s Step: %s ', 10, 1, @ProcedureName, @ProcedureStep);

        -----------------------------------------------------
        ----Inserting the Xml details into temp Table
        -----------------------------------------------------
        DECLARE @SynchErrorXML XML;

        SET @SynchErrorXML = CAST(@SynchErrorObj AS XML);

        INSERT INTO [#SynchErrObjVer]
        (
            [MFVersion]
           ,[ObjID]
           ,[ID]
        )
        SELECT [t].[c].[value]('(@objVersion)[1]', 'INT') AS [MFVersion]
              ,[t].[c].[value]('(@objectId)[1]', 'INT')   AS [ObjID]
              ,[t].[c].[value]('(@ID)[1]', 'INT')         AS [ID]
        FROM @SynchErrorXML.[nodes]('/form/Object') AS [t]([c]);

        SELECT @SynchErrCount = COUNT(*)
        FROM [#SynchErrObjVer];

        IF @SynchErrCount > 0
        BEGIN
            IF @Debug > 9
            BEGIN
                RAISERROR('Proc: %s Step: %s Count %i ', 10, 1, @ProcedureName, @ProcedureStep, @SynchErrCount);

                PRINT 'Synchronisation error';

                IF @Debug > 10
                    SELECT *
                    FROM [#SynchErrObjVer];
            END;

            SET @LogTypeDetail = 'User';
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Error';
            SET @Validation_ID = 2;
            SET @LogColumnName = 'Synch Errors';
            SET @LogColumnValue = ISNULL(CAST(@SynchErrCount AS VARCHAR(10)), 0);

            EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                         ,@LogType = @LogTypeDetail
                                                                         ,@LogText = @LogTextDetail
                                                                         ,@LogStatus = @LogStatusDetail
                                                                         ,@StartTime = @StartTime
                                                                         ,@MFTableName = @MFTableName
                                                                         ,@Validation_ID = @Validation_ID
                                                                         ,@ColumnName = @LogColumnName
                                                                         ,@ColumnValue = @LogColumnValue
                                                                         ,@Update_ID = @Update_ID
                                                                         ,@LogProcedureName = @ProcedureName
                                                                         ,@LogProcedureStep = @ProcedureStep
                                                                         ,@debug = @Debug;

            -------------------------------------------------------------------------------------
            -- UPDATE THE SYNCHRONIZE ERROR
            -------------------------------------------------------------------------------------
            DECLARE @SynchErrUpdateQuery NVARCHAR(MAX);

            SET @DebugText = ' Update sync errors';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @SynchErrUpdateQuery
                = '	UPDATE ['    + @MFTableName + ']
					SET ['             + @MFTableName + '].ObjID = #SynchErrObjVer.ObjID	,[' + @MFTableName
                  + '].MFVersion = #SynchErrObjVer.MFVersion
					,Process_ID = 2
					,LastModified = GETDATE()
					,Update_ID = '     + CAST(@Update_ID AS VARCHAR(15)) + '
					FROM #SynchErrObjVer
					WHERE ['           + @MFTableName + '].ID = #SynchErrObjVer.ID';

            EXEC (@SynchErrUpdateQuery);

            ------------------------------------------------------
            -- LOGGING THE ERROR
            ------------------------------------------------------
            SET @DebugText = 'log errors';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            ------------------------------------------------------
            --Getting @SyncPrecedence from MFClasss table for @TableName
            --IF NULL THEN insert error in error log 
            ------------------------------------------------------
            DECLARE @SyncPrecedence INT;

            SELECT @SyncPrecedence = [SynchPrecedence]
            FROM [dbo].[MFClass]
            WHERE [TableName] = @TableName;

            IF @SyncPrecedence IS NULL
            BEGIN
                INSERT INTO [dbo].[MFLog]
                (
                    [ErrorMessage]
                   ,[Update_ID]
                   ,[ErrorProcedure]
                   ,[ExternalID]
                   ,[ProcedureStep]
                   ,[SPName]
                )
                SELECT *
                FROM
                (
                    SELECT 'Synchronization error occured while updating ObjID : ' + CAST([ObjID] AS NVARCHAR(10))
                           + ' Version : ' + CAST([MFVersion] AS NVARCHAR(10)) + '' AS [ErrorMessage]
                          ,@Update_ID                                               AS [Update_ID]
                          ,@TableName                                               AS [ErrorProcedure]
                          ,''                                                       AS [ExternalID]
                          ,'Synchronization Error'                                  AS [ProcedureStep]
                          ,'spMFUpdateTable'                                        AS [SPName]
                    FROM [#SynchErrObjVer]
                ) AS [vl];
            END;
        END;

        DROP TABLE [#SynchErrObjVer];

        -------------------------------------------------------------
        --Logging error details
        -------------------------------------------------------------
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Perform checking for SQL Errors ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        CREATE TABLE [#ErrorInfo]
        (
            [ObjID] INT
           ,[SqlID] INT
           ,[ExternalID] NVARCHAR(100)
           ,[ErrorMessage] NVARCHAR(MAX)
        );

        DECLARE @ErrorInfoXML XML;

        SELECT @ErrorInfoXML = CAST(@ErrorInfo AS XML);

        INSERT INTO [#ErrorInfo]
        (
            [ObjID]
           ,[SqlID]
           ,[ExternalID]
           ,[ErrorMessage]
        )
        SELECT [t].[c].[value]('(@objID)[1]', 'INT')                  AS [objID]
              ,[t].[c].[value]('(@sqlID)[1]', 'INT')                  AS [SqlID]
              ,[t].[c].[value]('(@externalID)[1]', 'NVARCHAR(100)')   AS [ExternalID]
              ,[t].[c].[value]('(@ErrorMessage)[1]', 'NVARCHAR(MAX)') AS [ErrorMessage]
        FROM @ErrorInfoXML.[nodes]('/form/errorInfo') AS [t]([c]);

        SELECT @ErrorInfoCount = COUNT(*)
        FROM [#ErrorInfo];

        IF @ErrorInfoCount > 0
        BEGIN
            IF @Debug > 10
            BEGIN
                SELECT *
                FROM [#ErrorInfo];
            END;

            SET @DebugText = 'SQL Error logging errors found ';
            SET @DebugText = @DefaultDebugText + @DebugText;

            IF @Debug > 0
            BEGIN
                RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SELECT @MFErrorUpdateQuery
                = 'UPDATE [' + @MFTableName
                  + ']
									   SET Process_ID = 3
									   FROM #ErrorInfo err
									   WHERE err.SqlID = [' + @MFTableName + '].ID';

            EXEC (@MFErrorUpdateQuery);

            SET @ProcedureStep = 'M-Files Errors ';
            SET @LogTypeDetail = 'User';
            SET @LogTextDetail = @ProcedureStep;
            SET @LogStatusDetail = 'Error';
            SET @Validation_ID = 3;
            SET @LogColumnName = 'M-Files errors';
            SET @LogColumnValue = ISNULL(CAST(@ErrorInfoCount AS VARCHAR(10)), 0);

            EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                         ,@LogType = @LogTypeDetail
                                                                         ,@LogText = @LogTextDetail
                                                                         ,@LogStatus = @LogStatusDetail
                                                                         ,@StartTime = @StartTime
                                                                         ,@MFTableName = @MFTableName
                                                                         ,@Validation_ID = @Validation_ID
                                                                         ,@ColumnName = @LogColumnName
                                                                         ,@ColumnValue = @LogColumnValue
                                                                         ,@Update_ID = @Update_ID
                                                                         ,@LogProcedureName = @ProcedureName
                                                                         ,@LogProcedureStep = @ProcedureStep
                                                                         ,@debug = @Debug;

            INSERT INTO [dbo].[MFLog]
            (
                [ErrorMessage]
               ,[Update_ID]
               ,[ErrorProcedure]
               ,[ExternalID]
               ,[ProcedureStep]
               ,[SPName]
            )
            SELECT 'ObjID : ' + CAST(ISNULL([ObjID], '') AS NVARCHAR(100)) + ',' + 'SQL ID : '
                   + CAST(ISNULL([SqlID], '') AS NVARCHAR(100)) + ',' + [ErrorMessage] AS [ErrorMessage]
                  ,@Update_ID
                  ,@TableName                                                          AS [ErrorProcedure]
                  ,[ExternalID]
                  ,'Error While inserting/Updating in M-Files'                         AS [ProcedureStep]
                  ,'spMFUpdateTable'                                                   AS [spname]
            FROM [#ErrorInfo];
        END;

        DROP TABLE [#ErrorInfo];

        ------------------------------------------------------------------
        SET @NewObjectXml = CAST(@NewObjectXml AS NVARCHAR(MAX));
        -------------------------------------------------------------------------------------
        -- CALL SPMFUpadteTableInternal TO INSERT PROPERTY DETAILS INTO TABLE
        -------------------------------------------------------------------------------------
        SET @DebugText = '';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureName = 'spMFUpdateTableInternal';
        SET @ProcedureStep = 'Update property details from M-Files ';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        SET @StartTime = GETUTCDATE();

        IF (
               @NewObjectXml != '<form />'
               OR @NewObjectXml <> ''
               OR @NewObjectXml <> NULL
           )
        BEGIN
            IF @Debug > 10
                SELECT @NewObjectXml AS [@NewObjectXml before updateobjectinternal];

            EXEC @return_value = [dbo].[spMFUpdateTableInternal] @MFTableName
                                                                ,@NewObjectXml
                                                                ,@Update_ID
                                                                ,@Debug = @Debug
                                                                ,@SyncErrorFlag = @SyncErrorFlag;

            IF @return_value <> 1
                RAISERROR('Proc: %s Step: %s FAILED ', 16, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------------------------------
        --Checked whether all data is updated. #1360
        ------------------------------------------------------------------------------------ 
        --EXEC ('update '+ @MFTableName +' set Process_ID=1 where id =2')
        IF @UpdateMethod = 0
        BEGIN
            DECLARE @Sql NVARCHAR(1000) = 'SELECT @C = COUNT(*) FROM ' + @MFTableName + ' WHERE Process_ID=1';
            DECLARE @CountUpdated AS INT = 0;

            EXEC [sys].[sp_executesql] @Sql
                                      ,N'@C INT OUTPUT'
                                      ,@C = @CountUpdated OUTPUT;

            IF (@CountUpdated > 0)
            BEGIN
                RAISERROR('Error: All data is not updated', 10, 1, @ProcedureName, @ProcedureStep);
            END;
        END;

        --END of task #1360
        SET @ProcedureStep = 'Updating MFTable with deleted = 1,if object is deleted from MFiles';
        -------------------------------------------------------------------------------------
        --Update deleted column if record is deleled from M Files
        ------------------------------------------------------------------------------------               
        SET @StartTime = GETUTCDATE();

        IF @DeletedXML IS NOT NULL
        BEGIN
            CREATE TABLE [#DeletedRecordId]
            (
                [ID] INT
            );

            INSERT INTO [#DeletedRecordId]
            (
                [ID]
            )
            SELECT [t].[c].[value]('(@objectID)[1]', 'INT') AS [ID]
            FROM @DeletedXML.[nodes]('objVers') AS [t]([c]);

            SET @Count = CAST(@@RowCount AS VARCHAR(10));

            IF @Debug > 9
            BEGIN
                SELECT 'Deleted' AS [Deletions]
                      ,[ID]
                FROM [#DeletedRecordId];
            END;

            -------------------------------------------------------------------------------------
            --UPDATE THE DELETED RECORD 
            -------------------------------------------------------------------------------------
            DECLARE @DeletedRecordQuery NVARCHAR(MAX);

            SET @DeletedRecordQuery
                = '	UPDATE [' + @MFTableName + ']
											SET [' + @MFTableName
                  + '].Deleted = 1					
												,Process_ID = 0
												,LastModified = GETDATE()
											FROM #DeletedRecordId
											WHERE [' + @MFTableName + '].ObjID = #DeletedRecordId.ID';

            IF @Debug > 100
            BEGIN
                SELECT *
                FROM [#DeletedRecordId] AS [dri];

                SELECT @DeletedRecordQuery;
            END;

            EXEC (@DeletedRecordQuery);

            SET @Count = CAST(@@RowCount AS VARCHAR(10));
            SET @ProcedureStep = 'Deleted records';
            SET @LogTypeDetail = 'Debug';
            SET @LogTextDetail = 'Deletions';
            SET @LogStatusDetail = 'InProgress';
            SET @Validation_ID = NULL;
            SET @LogColumnName = 'Deletions';
            SET @LogColumnValue = ISNULL(CAST(@Count AS VARCHAR(10)), 0);

            EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                         ,@LogType = @LogTypeDetail
                                                                         ,@LogText = @LogTextDetail
                                                                         ,@LogStatus = @LogStatusDetail
                                                                         ,@StartTime = @StartTime
                                                                         ,@MFTableName = @MFTableName
                                                                         ,@Validation_ID = @Validation_ID
                                                                         ,@ColumnName = @LogColumnName
                                                                         ,@ColumnValue = @LogColumnValue
                                                                         ,@Update_ID = @Update_ID
                                                                         ,@LogProcedureName = @ProcedureName
                                                                         ,@LogProcedureStep = @ProcedureStep
                                                                         ,@debug = @Debug;

            IF @UpdateMethod = 1
               AND @RetainDeletions = 0
            BEGIN
                SET @Query = N'Delete from ' + QUOTENAME(@MFTableName) + ' Where deleted = 1';

                EXEC (@Query);
            END;

            DROP TABLE [#DeletedRecordId];
        END;
    END;
    ELSE
    BEGIN
        SELECT 'Check the table Name Entered';
    END;

    --          SET NOCOUNT OFF;
    --COMMIT TRANSACTION
    SET @ProcedureName = 'spMFUpdateTable';
    SET @ProcedureStep = 'Set update Status';

    IF @Debug > 9
        RAISERROR(
                     'Proc: %s Step: %s ReturnValue %i ProcessCompleted '
                    ,10
                    ,1
                    ,@ProcedureName
                    ,@ProcedureStep
                    ,@return_value
                 );

    -------------------------------------------------------------
    -- Check if precedence is set and update records with synchronise errors
    -------------------------------------------------------------
    IF @SyncPrecedence IS NOT NULL
    BEGIN
        EXEC [dbo].[spMFUpdateSynchronizeError] @TableName = @MFTableName           -- varchar(100)
                                               ,@Update_ID = @Update_IDOut          -- int
                                               ,@ProcessBatch_ID = @ProcessBatch_ID -- int
                                               ,@Debug = 0;                         -- int
    END;

    -------------------------------------------------------------
    -- Finalise logging
    -------------------------------------------------------------
    IF @return_value = 1
    BEGIN
        SET @ProcedureStep = 'Updating Table ';
        SET @LogType = 'Debug';
        SET @LogText = 'Update ' + @TableName + ':Update Method ' + CAST(@UpdateMethod AS VARCHAR(10));
        SET @LogStatus = N'Completed';

        UPDATE [dbo].[MFUpdateHistory]
        SET [UpdateStatus] = 'completed'
        --             [SynchronizationError] = @SynchErrorXML
        WHERE [Id] = @Update_ID;

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                            ,@LogType = @LogType
                                                              -- nvarchar(50)
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        SET @LogTypeDetail = @LogType;
        SET @LogTextDetail = @LogText;
        SET @LogStatusDetail = @LogStatus;
        SET @Validation_ID = NULL;
        SET @LogColumnName = NULL;
        SET @LogColumnValue = NULL;

        EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                                     ,@LogType = @LogTypeDetail
                                                                     ,@LogText = @LogTextDetail
                                                                     ,@LogStatus = @LogStatusDetail
                                                                     ,@StartTime = @StartTime
                                                                     ,@MFTableName = @MFTableName
                                                                     ,@Validation_ID = @Validation_ID
                                                                     ,@ColumnName = @LogColumnName
                                                                     ,@ColumnValue = @LogColumnValue
                                                                     ,@Update_ID = @Update_ID
                                                                     ,@LogProcedureName = @ProcedureName
                                                                     ,@LogProcedureStep = @ProcedureStep
                                                                     ,@debug = @Debug;

        RETURN 1; --For More information refer Process Table
    END;
    ELSE
    BEGIN
        UPDATE [dbo].[MFUpdateHistory]
        SET [UpdateStatus] = 'partial'
        WHERE [Id] = @Update_ID;

        SET @LogStatus = N'Partial Successful';
        SET @LogText = N'Partial Completed';
        SET @LogType = 'Status';

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                                              --				    @LogType = @ProcedureStep, -- nvarchar(50)
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                  ,@Update_ID = @Update_ID
                                                  ,@LogText = @LogText
                                                  ,@LogType = @LogType
                                                  ,@LogStatus = @LogStatus
                                                  ,@StartTime = @StartTime
                                                  ,@MFTableName = @MFTableName
                                                  ,@ColumnName = @LogColumnName
                                                  ,@ColumnValue = @LogColumnValue
                                                  ,@LogProcedureName = @ProcedureName
                                                  ,@LogProcedureStep = @ProcedureStep
                                                  ,@debug = @Debug;

    --    RETURN 0; --For More information refer Process Table
    END;

    IF @SynchErrCount > 0
    BEGIN
        SET @LogStatus = N'Errors';
        SET @LogText = @ProcedureStep + 'with sycnronisation errors: ' + @TableName + ':Return Value 2 ';
        SET @LogType = 'Status';

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                                              --				    @LogType = @ProcedureStep, -- nvarchar(50)
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                  ,@Update_ID = @Update_ID
                                                  ,@LogText = @LogText
                                                  ,@LogType = @LogType
                                                  ,@LogStatus = @LogStatus
                                                  ,@StartTime = @StartTime
                                                  ,@MFTableName = @MFTableName
                                                  ,@ColumnName = @LogColumnName
                                                  ,@ColumnValue = @LogColumnValue
                                                  ,@LogProcedureName = @ProcedureName
                                                  ,@LogProcedureStep = @ProcedureStep
                                                  ,@debug = @Debug;

    --          RETURN 0;
    END;

    --      ELSE
    BEGIN
        IF @ErrorInfoCount > 0
            SET @LogStatus = N'Partial Successful';

        SET @LogText = @LogText + ':' + @ProcedureStep + 'with M-Files errors: ' + @TableName + 'Return Value 3';
        SET @LogType = CASE
                           WHEN @MFTableName = 'MFUserMessages' THEN
                               'Status'
                           ELSE
                               'Message'
                       END;

        EXEC [dbo].[spMFProcessBatch_Upsert] @ProcessBatch_ID = @ProcessBatch_ID
                                                              -- int
                                            ,@ProcessType = @ProcessType
                                            ,@LogText = @LogText
                                                              -- nvarchar(4000)
                                            ,@LogStatus = @LogStatus
                                                              -- nvarchar(50)
                                            ,@debug = @Debug; -- tinyint

        EXEC [dbo].[spMFProcessBatchDetail_Insert] @ProcessBatch_ID = @ProcessBatch_ID
                                                  ,@Update_ID = @Update_ID
                                                  ,@LogText = @LogText
                                                  ,@LogType = @LogType
                                                  ,@LogStatus = @LogStatus
                                                  ,@StartTime = @StartTime
                                                  ,@MFTableName = @MFTableName
                                                  ,@ColumnName = @LogColumnName
                                                  ,@ColumnValue = @LogColumnValue
                                                  ,@LogProcedureName = @ProcedureName
                                                  ,@LogProcedureStep = @ProcedureStep
                                                  ,@debug = @Debug;

        RETURN 0;
    END;
END TRY
BEGIN CATCH
    IF @@TranCount <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    SET NOCOUNT ON;

    UPDATE [dbo].[MFUpdateHistory]
    SET [UpdateStatus] = 'failed'
    WHERE [Id] = @Update_ID;

    INSERT INTO [dbo].[MFLog]
    (
        [SPName]
       ,[ErrorNumber]
       ,[ErrorMessage]
       ,[ErrorProcedure]
       ,[ProcedureStep]
       ,[ErrorState]
       ,[ErrorSeverity]
       ,[Update_ID]
       ,[ErrorLine]
    )
    VALUES
    ('spMFUpdateTable', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE()
    ,ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

    IF @Debug > 9
    BEGIN
        SELECT ERROR_NUMBER()    AS [ErrorNumber]
              ,ERROR_MESSAGE()   AS [ErrorMessage]
              ,ERROR_PROCEDURE() AS [ErrorProcedure]
              ,@ProcedureStep    AS [ProcedureStep]
              ,ERROR_STATE()     AS [ErrorState]
              ,ERROR_SEVERITY()  AS [ErrorSeverity]
              ,ERROR_LINE()      AS [ErrorLine];
    END;

    SET NOCOUNT OFF;

    RETURN -1; --For More information refer Process Table
END CATCH;
GO



PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateTable_ObjIds_GetGroupedList]';

EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTable_ObjIds_GetGroupedList', -- nvarchar(100)
    @Object_Release = '3.1.1.36', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateTable_ObjIds_GetGroupedList'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateTable_ObjIds_GetGroupedList]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL
   DROP TABLE  #ObjIdList;
CREATE TABLE #ObjIdList ( [ObjId] INT )
GO

ALTER PROCEDURE [dbo].[spMFUpdateTable_ObjIds_GetGroupedList]
    (
       @ObjIds_FieldLenth SMALLINT = 2000
	  ,@Debug SMALLINT = 0
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to group source records into batches
  **		and compile a list of OBJIDs in CSV format to pass to spMFUpdateTable
  **  
  ** Version: 1.0.0.0
  **
  ** Processing Steps:
  **					1. Calculate Number of Groups in RecordSet
  **					2. Assign Group Numbers to Source Records
  **					3. Return ObjIDs CSV List by GroupNumber
  **
  ** Parameters and acceptable values: 
  **					@ObjIds_FieldLenth: Indicate the size of each group iteration CSV text field   
  **					@Debug				
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					1 = success
  **					2 = Failure	
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					sp_executesql
  **					spMFUpdateTable
  **
  ** Author:			arnie@lamininsolutions.com
  ** Date:				2016-05-14
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
	2017-06-08	ACILLIERS	change default size of @ObjIds_FieldLenth to 2000 from 4000 as NVARCHAR(4000) is same as VARCHAR(2000)
  ********************************************************************************
  ** EXAMPLE EXECUTE
  ********************************************************************************
		IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL
		   DROP TABLE  #ObjIdList;
		CREATE TABLE #ObjIdList ( [ObjId] INT  PRIMARY KEY )

		INSERT #ObjIdList
				( ObjId )
		SELECT ObjID
		FROM CLGLChart

		EXEC spMFUpdateTable_ObjIDS_GetGroupedList

  ******************************************************************************/
    BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;



	-----------------------------------------------------
	--DECLARE LOCAL VARIABLE
	-----------------------------------------------------
	   DECLARE	@return_value INT = 1
			,	@rowcount INT = 0
			,	@ProcedureName sysname = 'spMFUpdateTable_ObjIds_GetGroupList'
			,	@ProcedureStep sysname = 'Start'
			,	@sqlQuery NVARCHAR(MAX)
			,	@sqlParam NVARCHAR(MAX)

	-----------------------------------------------------
	--Calculate Number of Groups in RecordSet
	-----------------------------------------------------
	SET @ProcedureStep = 'Get Number of Groups '
	DECLARE @NumberofGroups INT

    SELECT  @NumberofGroups = ( SELECT  COUNT(*)
                                FROM    #ObjIdList
                              ) / ( @ObjIds_FieldLenth --ObjIds fieldlenth
                                    / ( SELECT  MAX(LEN([ObjId])) + 2
                                        FROM    #ObjIdList
                                      ) --avg size of each item in csv list including comma
                                    );			

	SET @NumberofGroups = ISNULL(NULLIF(@NumberofGroups,0),1)
		IF @Debug > 0
			    RAISERROR('Proc: %s Step: %s: %d group(s)',10,1,@ProcedureName,@ProcedureStep,@NumberofGroups);
	
	   
	-----------------------------------------------------
	--Assign Group Numbers to Source Records
	-----------------------------------------------------
	SET @ProcedureStep = 'Assign Group Numbers to Source Records '
	CREATE TABLE #GroupDtl ([ObjID] INT,[GroupNumber] int )
	
	INSERT  #GroupDtl
			( [ObjID]
			, [GroupNumber]
			)
	SELECT  [ObjID]
			, NTILE(@NumberofGroups) OVER ( ORDER BY ObjID ) AS GroupNumber
	FROM #ObjIdList

		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s Step: %s: %d record(s)',10,1,@ProcedureName, @ProcedureStep,@rowcount);
		

	-----------------------------------------------------
	--Get ObjIDs CSV List by GroupNumber
	-----------------------------------------------------
	SET @ProcedureStep = 'Get ObjIDs CSV List by GroupNumber '

		CREATE TABLE #GroupHdr ([GroupNumber] INT, [ObjIDs] NVARCHAR(4000))
		INSERT  #GroupHdr
				( [GroupNumber]
				, [ObjIDs]
				)
				SELECT  [source].[GroupNumber]
					  , [ObjIDs] = STUFF(( SELECT ','
											  , CAST([ObjID] AS VARCHAR(10))
										 FROM   #GroupDtl
										 WHERE  [GroupNumber] = [source].[GroupNumber]
									   FOR
										 XML PATH('')
									   ), 1, 1, '')
				FROM    ( SELECT    [GroupNumber]
						  FROM      #GroupDtl
						  GROUP BY  [GroupNumber]
						) [source];

		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s Step: %s: %d record(s)',10,1,@ProcedureName, @ProcedureStep,@rowcount);
		


	-----------------------------------------------------
	--Return GroupedList
	-----------------------------------------------------	
	SELECT * 
	FROM #GroupHdr
	ORDER BY GroupNumber

	END


GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateTable_ObjIDs_Grouped]';

SET NOCOUNT ON;
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTable_ObjIDs_Grouped', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateTable_ObjIDs_Grouped'--name of procedure
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
CREATE PROCEDURE  [dbo].[spMFUpdateTable_ObjIDs_Grouped]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO



ALTER PROCEDURE [dbo].[spMFUpdateTable_ObjIDs_Grouped]
    (
      @MFTableName NVARCHAR(128),
	  @MFTableSchema NVARCHAR(128) = 'dbo',
	  @UpdateMethod INT = 1, 
      @ProcessId INT = 6     ,	-- 6 Merged Updates 
      @UserId NVARCHAR(200) = NULL, --null for all user update
	  @ProcessBatch_ID INT = NULL OUTPUT,
      @Debug SMALLINT = 0
	)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to group source records into batches
  **		and compile a list of OBJIDs in CSV format to pass to spMFUpdateTable
  **  
  ** Version: 1.0.0.0
  **
  ** Processing Steps:
  **					1. Calculate Number of Groups in RecordSet
  **					2. Assign Group Numbers to Source Records
  **					3. Get ObjIDs CSV List by GroupNumber
  **					4. Loop Through Groups - Execute [spMFUpdateTable]
  **						- Update Process_ID = 1
  **						- Execute [spMFUpdateTable] with ObjIDs csv list	
  **
  ** Parameters and acceptable values: 
  **					@MFTableName		NVARCHAR(128)
  **					@MFTableSchema		NVARCHAR(128)
  **					@UpdateMethod	   0: MFSQL to M-Files; 1: M-Files to MFSQL
  **					@ProcessId			INT	  -- The Process_ID in class table to evaluate for grouping
  **					@UserId				NVARCHAR(200)         
  **					@Debug				SMALLINT = 0
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					1 = success
  **					2 = Failure	
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					sp_executesql
  **					spMFUpdateTable
  **
  ** Author:			arnie@lamininsolutions.com
  ** Date:				2016-05-14
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  2017-06-29	ArnieC		- @ObjIds_toUpdate change sizes to NVARCHAR(4000)
							- @ObjIds_FieldLenth change default value to 2000
  ********************************************************************************
  ** EXAMPLE EXECUTE
  ********************************************************************************
		EXEC [spMFUpdateTable_ObjIDs_Grouped]  @MFTableName = 'CLGLChart',
							  @MFTableSchema = 'dbo',
							  @UpdateMethod = 0
							  @ProcessId = 6     ,	-- 6 Merged Updates
							  @UserId = NULL, --null for all user update
							  @Debug  = 1

  ******************************************************************************/
    BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	-----------------------------------------------------
	--DECLARE LOCAL VARIABLE
	-----------------------------------------------------
	   DECLARE	@return_value INT = 1
			,	@rowcount INT = 0
			,	@ProcedureName sysname = 'spMFUpdateTable_ObjIDs_Grouped'
			,	@Procedurestep NVARCHAR(128) = ''
			,	@ObjIds_FieldLenth INT = 2000
			,	@sqlQuery NVARCHAR(MAX)
			,	@sqlParam NVARCHAR(MAX)


-----------------------------------------------------
		--DECLARE VARIABLES FOR LOGGING
		-----------------------------------------------------
                  DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
                  DECLARE @DebugText AS NVARCHAR(256) = '';
                  DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
                  DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
                  DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
                  DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
                  DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
                  DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
                  DECLARE @ProcessType NVARCHAR(50)
                  DECLARE @LogType AS NVARCHAR(50) = 'Status'
                  DECLARE @LogText AS NVARCHAR(4000) = '';
                  DECLARE @LogStatus AS NVARCHAR(50) = 'Started'
                  DECLARE @Status AS NVARCHAR(128) = NULL;
                  DECLARE @Validation_ID INT = NULL;
                  DECLARE @StartTime AS DATETIME;
                  DECLARE @RunTime AS DECIMAL(18, 4) = 0;



                          SET @ProcedureStep = 'Start';
                           SET @StartTime = GETUTCDATE();
                           SET @ProcessType = @ProcedureName
                           SET @LogType = 'Status'
                           SET @LogStatus = 'Started'
                           SET @LogText = 'Group IDs for Process_ID ' + CAST(@ProcessId AS VARCHAR(10))

                           EXECUTE @return_value = [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID OUTPUT
                          , @ProcessType = @ProcessType
                          , @LogType = @LogType
                          , @LogText = @LogText
                          , @LogStatus = @LogStatus
                          , @debug = @debug

	-----------------------------------------------------
	--Calculate Number of Groups in RecordSet
	-----------------------------------------------------
	SET @ProcedureStep = 'Get Number of Groups '
	DECLARE @NumberofGroups INT
		SET @sqlQuery = N'
				SELECT  @NumberofGroups = ( SELECT   COUNT(*)
							   FROM    ' + @MFTableSchema +'.' + @MFTableName + '
							   WHERE    Process_ID = @ProcessId
							 ) / ( @ObjIds_FieldLenth --ObjIds fieldlenth
								   / ( SELECT   MAX(LEN(ObjID)) + 2
									   FROM   ' + @MFTableSchema +'.' + @MFTableName + '
									   WHERE    Process_ID = @ProcessId
									 ) --avg size of each item in csv list including comma
								   );			
				'
		SET @sqlParam = N'
							@ProcessId INT
						  ,	@ObjIds_FieldLenth INT
						  ,	@NumberofGroups INT OUTPUT
						'

		EXEC sys.sp_executesql @sqlQuery
							,	@sqlParam
							,	@ProcessId = @ProcessId
							,	@ObjIds_FieldLenth = @ObjIds_FieldLenth
							,	@NumberofGroups =  @NumberofGroups OUTPUT

		SET @NumberofGroups = ISNULL(NULLIF(@NumberofGroups,0),1)
		IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: %d group(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@NumberofGroups);

	-----------------------------------------------------
	--Logging Number of Groups in RecordSet
	-----------------------------------------------------
	

	       SET @LogTypeDetail = 'Debug'
                           SET @LogTextDetail = @ProcedureStep + @MFTableName + '';
                           SET @LogStatusDetail = 'Calculated'
                           SET @Validation_ID = NULL
                           SET @LogColumnName ='Number of Groups: '
                           SET @LogColumnValue = CAST(@numberofgroups AS VARCHAR(10));

                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug

	   
	-----------------------------------------------------
	--Assign Group Numbers to Source Records
	-----------------------------------------------------
	SET @ProcedureStep = 'Assign Group Numbers to Source Records '
	CREATE TABLE #GroupDtl ([ID] INT, [ObjID] INT,GroupNumber int )
	
	SET @sqlQuery = N'
					SELECT ID
				  , ObjID
				  , NTILE(@NumberofGroups) OVER ( ORDER BY ObjID ) AS GroupNumber
			FROM     ' + @MFTableSchema +'.' + @MFTableName + '
			WHERE   Process_ID = @ProcessId;
			'  

	SET @sqlParam = N'
							@ProcessId INT
						,	@NumberofGroups INT
					'

	INSERT  #GroupDtl
			( ID
			, ObjID
			, GroupNumber
			)
		EXEC sys.sp_executesql @sqlQuery
							,	@sqlParam
							,	@ProcessId = @ProcessId
							,   @NumberofGroups = @NumberofGroups

	
		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: %d record(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@rowcount);
		

	-----------------------------------------------------
	--Get ObjIDs CSV List by GroupNumber
	-----------------------------------------------------
	SET @ProcedureStep = 'Get ObjIDs CSV List by GroupNumber '

		CREATE TABLE #GroupHdr (GroupNumber INT, ObjIDs NVARCHAR(4000))
		INSERT  #GroupHdr
				( GroupNumber
				, ObjIDs
				)
				SELECT  [source].GroupNumber
					  , ObjIDs = STUFF(( SELECT ','
											  , CAST(ObjID AS VARCHAR(10))
										 FROM   #GroupDtl
										 WHERE  GroupNumber = [source].GroupNumber
									   FOR
										 XML PATH('')
									   ), 1, 1, '')
				FROM    ( SELECT    GroupNumber
						  FROM      #GroupDtl
						  GROUP BY  GroupNumber
						) [source];

		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: %d record(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@rowcount);
		

	-----------------------------------------------------
	--Loop Through Groups - Execute [spMFUpdateTable]
	-----------------------------------------------------
	SET @ProcedureStep = 'Loop Through Groups - Execute [spMFUpdateTable] '
		DECLARE @CurrentGroup INT, @ObjIds_toUpdate NVARCHAR(4000)

		SELECT @CurrentGroup = MIN(GroupNumber)
		FROM  #GroupHdr
		WHILE @CurrentGroup IS NOT NULL	
		BEGIN
		
			SET @sqlQuery = N'
						 UPDATE MFTable
						 SET Process_ID = CASE WHEN @UpdateMethod = 0 THEN 1 ELSE 0 END
						 FROM  ' + @MFTableSchema +'.' + @MFTableName + ' MFTable
						 INNER JOIN #GroupDtl t ON MFTable.ID = t.ID
						 WHERE t.GroupNumber = @CurrentGroup
						 AND MFTable.Process_ID = @ProcessID
						'

			SET @sqlParam = N'
								@ProcessId INT
							,	@CurrentGroup INT
							,	@UpdateMethod INT
							'

			EXEC sys.sp_executesql @sqlQuery
							,	@sqlParam
							,	@ProcessId = @ProcessId
							,	@CurrentGroup = @CurrentGroup
							,	@UpdateMethod = @UpdateMethod


			 SELECT @rowcount = @@ROWCOUNT

			 IF @Debug > 0
			    RAISERROR('Proc: %s MFTable: %s Step: %s: GroupNumber: %d: %d record(s)',10,1,@ProcedureName,@MFTableName, @ProcedureStep,@CurrentGroup,@rowcount);
		

			 SELECT @ObjIds_toUpdate = ObjIDs
			 FROM #GroupHdr
			 WHERE GroupNumber = @CurrentGroup	 

			EXEC @return_value = [dbo].[spMFUpdateTable] @MFTableName = @MFTableName
									, @UpdateMethod = @UpdateMethod
									, @UserId = NULL
									, @MFModifiedDate = NULL
									, @ObjIDs = @ObjIds_toUpdate -- CSV List
									,@ProcessBatch_ID = @ProcessBatch_ID
									, @Debug = @Debug;

			  IF @Debug > 0
				PRINT  @ObjIds_toUpdate
			    

-----------------------------------------------------
	--Logging Completion of process for Group
	-----------------------------------------------------
	

	       SET @LogTypeDetail = 'Debug'
                           SET @LogTextDetail = @ProcedureStep + @MFTableName + '';
                           SET @LogStatusDetail = 'Completed'
                           SET @Validation_ID = NULL
                           SET @LogColumnName ='Group Number: '
                           SET @LogColumnValue = CAST(@CurrentGroup AS VARCHAR(10));

                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
		
             --   IF @return_value <> 1
             --   BEGIN
             --       RAISERROR('EXEC [spMFUpdateTable] @MFTableName=%s,@UpdateMethod=0 | Returned with %d',16,1,@MFTableName,@return_value);
             --   END;

	            --IF EXISTS ( SELECT    1
             --           FROM      CLGLChart
             --           WHERE     Process_ID <> 0 )
             --   BEGIN
             --       RAISERROR('EXEC [spMFUpdateTable] @MFTableName=%s,@UpdateMethod=0 | Process_ID=<>0',16,1,@MFTableName);
             --   END;

	
			SELECT @CurrentGroup = MIN(GroupNumber)
			FROM  #GroupHdr
			WHERE GroupNumber > @CurrentGroup
	
		END

--Log end of procedure

		        SET @ProcedureName = 'spMFUpdateTable_ObjIDs_Grouped';
               
                  SET @ProcedureStep = 'Grouping Process Completed ';
                  SET @LogType = 'Status'
                  SET @LogText = @Procedurestep + ':Update Method ' + CAST(@UpdateMethod AS VARCHAR(10));
                  SET @LogStatus = N'Completed';

                  EXEC [dbo].[spMFProcessBatch_Upsert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          ,-- int
                            @LogType = @LogType
                          ,-- nvarchar(50)
                            @LogText = @LogText
                          ,-- nvarchar(4000)
                            @LogStatus = @LogStatus
                          ,-- nvarchar(50)
                            @debug = @debug;-- tinyint


   SET @LogTypeDetail = 'Debug'
                           SET @LogTextDetail = @ProcedureStep + @MFTableName + '';
                           SET @LogStatusDetail = 'Completed'
                           SET @Validation_ID = NULL
                           SET @LogColumnName ='Last Group: '
                           SET @LogColumnValue = CAST(@CurrentGroup AS VARCHAR(10));

                           EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
                            @ProcessBatch_ID = @ProcessBatch_ID
                          , @LogType = @LogTypeDetail
                          , @LogText = @LogTextDetail
                          , @LogStatus = @LogStatusDetail
                          , @StartTime = @StartTime
                          , @MFTableName = @MFTableName
                          , @Validation_ID = @Validation_ID
                          , @ColumnName = @LogColumnName
                          , @ColumnValue = @LogColumnValue
                          , @Update_ID = null
                          , @LogProcedureName = @ProcedureName
                          , @LogProcedureStep = @ProcedureStep
                          , @debug = @debug
		


	END




GO


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableWithLastModifiedDate]';
GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTableWithLastModifiedDate',
    -- nvarchar(100)
    @Object_Release = '4.2.7.46',
    -- varchar(50)
    @UpdateFlag = 2;
-- smallint

GO

IF EXISTS
    (
        SELECT
            1
        FROM
            [INFORMATION_SCHEMA].[ROUTINES]
        WHERE
            [ROUTINE_NAME] = 'spMFUpdateTableWithLastModifiedDate' --name of procedure
            AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
            AND [ROUTINE_SCHEMA] = 'dbo'
    )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';

        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateTableWithLastModifiedDate]
AS
    SELECT
        'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

/*
Procedure that update MF Class table using the last MFUpdate date and returning the new last Update date

Usage: 

Declare @last_Modified datetime
exec spMFUpdateTableWithLastModifiedDate @UpdateMethod = 1, 
@TableName = 'MFSOInvoiced', @Return_LastModified = @last_Modified output
Select @last_Modified

Change history

2016-8-25	LC	Add the Update_ID from UpdateTable as an output on this procedure also to pass it through
2016-10-8   LC fix bug with null values
2017-06-29	AC	fix bug introduced by fix of Bug #1049
2017-06-30  AC	Update LogStatusDetail to be consisted with convention of using Started and Completed as the status descriptions
				Update Logging of MFLastModifiedDate as a Column and Value pair 	
				Update Logging to make use of new @ProcessBatchDetail_ID to calculate duration	

2017-11-23	LC	LastModified column name date localization
2018-10-22  LC  Modify logtext description to align with reporting
2018-10-22  LC  Add 1 second to last modified data to avoid reprocessing the last record.
*/

ALTER PROCEDURE [dbo].[spMFUpdateTableWithLastModifiedDate]
    @UpdateMethod        INT,
    @Return_LastModified DATETIME = NULL OUTPUT,
    @TableName           sysname,
    @Update_IDOut        INT      = NULL OUTPUT,
    @ProcessBatch_ID     INT      = NULL OUTPUT,
    @debug               SMALLINT = 0
AS
    DECLARE
        @SQL           NVARCHAR(MAX),
        @Params        NVARCHAR(MAX),
        @return_Value  INT,
        @LastModified  DATETIME,
		@MFLastUpdate DATETIME,
        @procedureStep VARCHAR(100) = 'Update',
        @procedureName VARCHAR(100) = 'spMFUpdateTableWithLastModifiedDate',
        @MFTableName   sysname      = @TableName;

    /*
Process Batch Declarations to be added
*/

    DECLARE @RC INT;
    DECLARE @ProcessType NVARCHAR(50);
    DECLARE @LogType NVARCHAR(50);
    DECLARE @LogText NVARCHAR(4000);
    DECLARE @LogStatus NVARCHAR(50);
    DECLARE @StartTime DATETIME;
    DECLARE @Validation_ID INT;
    DECLARE @ColumnName NVARCHAR(128);
    DECLARE @ColumnValue NVARCHAR(256);
    DECLARE @LogProcedureName NVARCHAR(128);
    DECLARE @LogProcedureStep NVARCHAR(128);
    DECLARE @update_ID INT = NULL;
    DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
    DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
    DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
    DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
    DECLARE @ProcessBatchDetail_IDOUT INT;

    /*
Process Batch
*/

    /*
Process Batch Initiate
*/

    SET @ProcessType = @procedureName;

    SET @LogType = 'Debug';
    SET @LogText = @procedureStep;
    SET @LogStatus = 'Started';


    EXECUTE @Return_LastModified = [dbo].[spMFProcessBatch_Upsert]
        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = @LogType,
        @LogText = @LogText,
        @LogStatus = @LogStatus,
        @debug = @debug;

    SET @StartTime = GETUTCDATE(); --- position this at the start of the process to be measured
    SET @procedureStep = 'Update Table with LastModified Date';

    IF @debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s ', 10, 1, @procedureName, @procedureStep);

        END;

    SET @StartTime = GETUTCDATE();

    SET @procedureStep = 'Update Table with LastModified filter';
    SET @LogTypeDetail = 'Debug';
    SET @LogStatusDetail = 'Start';
    SET @LogTextDetail = 'Update: ' + CAST(@TableName AS NVARCHAR(256));
    SET @LogColumnName = '';
    SET @LogColumnValue = '';
    SET @ProcessBatchDetail_IDOUT = NULL;

    EXECUTE @return_Value = [dbo].[spMFProcessBatchDetail_Insert]
        @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = @LogTypeDetail,
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatusDetail,
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = @LogColumnName,
        @ColumnValue = @LogColumnValue,
        @Update_ID = @update_ID,
        @LogProcedureName = @procedureName,
        @LogProcedureStep = @procedureStep,
        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT OUTPUT,
        @debug = @debug;

    DECLARE @lastModifiedColumn NVARCHAR(100);
    SELECT
        @lastModifiedColumn = [mp].[ColumnName]
    FROM
        [dbo].[MFProperty] AS [mp]
    WHERE
        [MFID] = 21; --'Last Modified'

    SELECT
        @Params
        = N'@return_Value int output, @TableName sysname, @Debug smallint, @Update_IDOut int Output, @ProcessBatch_ID int output, @MFLastUpdate datetime output';
    SELECT
        @SQL
        = N'
	SELECT @MFLastUpdate = MAX(isnull(' + QUOTENAME(@lastModifiedColumn) + ',0)) FROM dbo.' + QUOTENAME(@TableName)
          + '
	SET @MFLastUpdate = DATEADD(hour,-(DATEDIFF(hour,GETDATE(),GETUTCDATE())) ,@MFLastUpdate)
	SET @MFLastUpdate=DATEADD(Minute,DateDiff(MINUTE,Getdate(),getUTCDate()),@MFLastUpdate) --Added for Bug #1049
	 SELECT @MFLastUpdate =DATEADD(SECOND,1,@MFLastUpdate)
	--PRINT @MFLastUpdate --Added for Bug #1049

	EXEC	@return_value = [dbo].spMFUpdateTable
			@MFTableName = N''' + @TableName
          + ''',
			@UpdateMethod = 1,
			@UserId = NULL,
			@MFModifiedDate = @MFLastUpdate,
			@ObjIDs = NULL,
			@Update_IDOut = @Update_IDOut output,
			@ProcessBatch_ID = @ProcessBatch_ID output,
			@Debug = @Debug
			';

    EXEC [sys].[sp_executesql]
        @SQL,
        @Params,
        @return_Value = @return_Value OUTPUT,
        @TableName = @TableName,
        @debug = @debug,
        @Update_IDOut = @Update_IDOut OUTPUT,
        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
		@MFLastUpdate = @MFLastUpdate output;

    IF @debug > 9
        RAISERROR('Proc: %s Step: %s Table: %s', 10, 1, @procedureName, @procedureStep, @TableName);

    --    SELECT  @return_Value;
    SELECT
        @Params = N'@LastModified datetime output';
    SELECT
        @SQL
        = N'
SELECT @LastModified  = MAX(isnull(' + QUOTENAME(@lastModifiedColumn) + ',0)) FROM dbo.' + QUOTENAME(@TableName)
          + '		
			';

    EXECUTE [sys].[sp_executesql]
        @SQL,
        @Params,
        @LastModified = @LastModified OUTPUT;

    SELECT
        @Return_LastModified = @LastModified;
    --    SELECT  @Return_LastModified = DATEADD(hour,-(DATEDIFF(hour,GETDATE(),GETUTCDATE())) ,@LastModified);

    SET @procedureStep = 'Update: ' + @TableName + ''
    SET @LogText = 'Update : '+ @TableName + ':Update Method ' + CAST(@UpdateMethod AS VARCHAR(2));
    SET @LogStatus = 'Completed'; --- Error , in Progress, Start, End, Completed  

    EXECUTE @return_Value = [dbo].[spMFProcessBatch_Upsert]
        @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
        @ProcessType = @ProcessType,
        @LogType = @LogType,
        @LogText = @LogText,
        @LogStatus = @LogStatus,
        @debug = @debug;


    SET @procedureStep = 'Update';
    SET @LogTypeDetail = 'Status';
    SET @LogStatusDetail = 'Completed';
    SET @LogTextDetail = ' From '+ CAST(@MFLastUpdate AS VARCHAR(25)) + ' to ' + CAST(@LastModified AS VARCHAR(25));
    SET @LogColumnName = 'LastModified';
    SET @LogColumnValue = CONVERT(VARCHAR(30), GETDATE(), 120);

    SET @StartTime = GETUTCDATE();

    EXECUTE @return_Value = [dbo].[spMFProcessBatchDetail_Insert]
        @ProcessBatch_ID = @ProcessBatch_ID,
        @LogType = @LogTypeDetail,
        @LogText = @LogTextDetail,
        @LogStatus = @LogStatusDetail,
        @StartTime = @StartTime,
        @MFTableName = @MFTableName,
        @Validation_ID = @Validation_ID,
        @ColumnName = @LogColumnName,
        @ColumnValue = @LogColumnValue,
        @Update_ID = @Update_IDOut,
        @LogProcedureName = @procedureName,
        @LogProcedureStep = @procedureStep,
        @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT OUTPUT,
        @debug = @debug;

    RETURN 1;

GO




GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spmfUpdateSynchronizeError]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFUpdateSynchronizeError',
                                     -- nvarchar(100)
                                     @Object_Release = '4.2.6.44',
                                     -- varchar(50)
                                     @UpdateFlag = 2;
-- smallint
GO

/*
2018-8-23		LC update procedure to only process the errors from the prior update run
2018-8-29		LC	Include this process as a part of the logging of MFUpdateTable
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateSynchronizeError' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateSynchronizeError]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO
--exec spmfUpdateSynchronizeError 'MFSalesInvoice',1
ALTER PROCEDURE [dbo].[spMFUpdateSynchronizeError]
    @TableName VARCHAR(100),
    @Update_ID INT,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug INT = 0
AS
BEGIN


    IF @Debug > 0
    BEGIN
        PRINT 'Declaring Variables';
    END;

    DECLARE @ParmDefinition NVARCHAR(MAX);
    DECLARE @SelectQuery NVARCHAR(MAX);
    DECLARE @ObjID NVARCHAR(MAX);
    DECLARE @SyncPrecedence INT;

    SET @ParmDefinition = N'@retvalOUT varchar(max) OUTPUT, @Update_ID int';

    IF (@Debug > 0)
    BEGIN
        PRINT 'Getting comma separated ObjIDs whose process_id=2';
    END;

    SET @SelectQuery
        = 'SELECT @retvalOUT= STUFF((
					select '',''+ cast(ObjID as varchar(10))
					from ' + @TableName
          + ' where process_id=2 and Update_id = @Update_ID
					FOR XML PATH('''')
					)
					,1,1,'''') ';

    IF @Debug > 0
        PRINT @SelectQuery;

    EXEC [sys].[sp_executesql] @SelectQuery,
                               @ParmDefinition,
                               @retvalOUT = @ObjID OUTPUT,
                               @Update_ID = @Update_ID;

    IF (@Debug > 0)
    BEGIN
        SELECT @ObjID AS [ObjIDs];
    END;

    ------------------------------------------------------
    --Getting @SyncPrecedence from MFClasss table for @TableName
    ------------------------------------------------------
    SELECT @SyncPrecedence = [SynchPrecedence]
    FROM [dbo].[MFClass]
    WHERE [TableName] = @TableName;

    IF (@SyncPrecedence IS NOT NULL)
       AND @ObjID IS NOT NULL
    BEGIN
        --select @SyncPrecedence
        IF @SyncPrecedence = 1
        BEGIN
            IF (@Debug > 0)
            BEGIN
                PRINT 'M-Files To Sql';
            END;
            EXEC [dbo].[spMFUpdateTable] @MFTableName = @TableName,
                                         @UpdateMethod = 1,
                                         @ObjIDs = @ObjID,
                                         @SyncErrorFlag = 1,
                                         @Update_IDOut = @Update_ID OUTPUT,
										 @ProcessBatch_ID = @ProcessBatch_ID ,
                                         @Debug = @Debug;

            SET @ParmDefinition = N'@Update_ID int';
            SET @SelectQuery
                = N'Update ' + QUOTENAME(@TableName)
                  + ' set  process_id=0 where  process_id=2 and Update_ID = @Update_ID';

            EXEC [sys].[sp_executesql] @SelectQuery,
                                       @ParmDefinition,
                                       @Update_ID = @Update_ID;

        END;

        ELSE
        BEGIN
            IF (@Debug > 0)
            BEGIN
                PRINT 'Sql To M-Files';
            END;
           

            SET @ParmDefinition = N'@Update_ID int';
            SET @SelectQuery
                = N'Update ' + QUOTENAME(@TableName)
                  + ' set  process_id=1 where  process_id=2 and Update_ID = @Update_ID';

            EXEC [sys].[sp_executesql] @SelectQuery,
                                       @ParmDefinition,
                                       @Update_ID = @Update_ID;

			IF @debug > 0
			SELECT @ObjID AS objids;

 EXEC [dbo].[spMFUpdateTable] @MFTableName = @TableName,
                                         @UpdateMethod = 0,
                                         @ObjIDs = @ObjID,
                      --                   @SyncErrorFlag = 0,
										 @ProcessBatch_ID = @ProcessBatch_ID ,
                      --                   @Update_IDOut = @Update_ID OUTPUT,
										 @Debug = @Debug;

        END;

    END;
END;
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFTestMailProfile]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFTestMailProfile', -- nvarchar(100)
    @Object_Release = '2.0.2.3', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-13
	Database: 
	Description: Testing email send for the Connector email profile
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

  EXEC [spMFTestMailProfile]   @InMailProfile= 'LSEmailProfile',@RecipientEmail= 'leroux@lamininsolutions.com'
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFTestMailProfile'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFTestMailProfile]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


ALTER procedure [dbo].[spMFTestMailProfile](@InMailProfile varchar(MAX),@RecipientEmail varchar(MAX), @Debug SMALLINT = 0)
AS
BEGIN
SET NOCOUNT on
BEGIN try

DECLARE @bodyText VARCHAR(100)

SET @bodyText = 'This is a test mail sent for verifying profile:' + @InMailProfile

IF @Debug = 1
SELECT @InMailProfile AS [Profile], @RecipientEmail AS Recipient
EXEC msdb.dbo.sp_send_dbmail
    @recipients=@RecipientEmail,
    @body= @bodyText,
    @subject = 'Mail Profile verification',
    @profile_name = @InMailProfile;


RETURN 1
END TRY
BEGIN CATCH
RETURN -1
END Catch

END

GO
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckLicenseStatus]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFCheckLicenseStatus' -- nvarchar(100)
                                    ,@Object_Release = '4.3.9.47'            -- varchar(50)
                                    ,@UpdateFlag = 2;                        -- smallint
GO

/*
Modifications
2018-07-09		lc	Change name of MFModule table to MFLicenseModule
3019-1-19		LC	Add return values
*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFCheckLicenseStatus' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFCheckLicenseStatus]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFCheckLicenseStatus]
    @InternalProcedureName NVARCHAR(500)
   ,@ProcedureName NVARCHAR(500)
   ,@ProcedureStep sysname = 'Validate connection '
AS
BEGIN
    DECLARE @ModuleID NVARCHAR(20);
    DECLARE @Status NVARCHAR(20);
    DECLARE @VaultSettings NVARCHAR(2000);
    DECLARE @ModuleErrorMessage NVARCHAR(MAX);

    SET @ProcedureStep = 'Validate License ';

    SELECT @ModuleID = CAST(ISNULL([Module], 0) AS NVARCHAR(20))
    FROM [setup].[MFSQLObjectsControl]
    WHERE [Name] = @InternalProcedureName;

    SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

    --from 
    -- MFModule
    IF @ModuleID != '0'
    BEGIN
        EXEC [dbo].[spMFValidateModule] @VaultSettings, @ModuleID, @Status OUT;

        IF @Status = '2'
        BEGIN
            RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep, 'License is not valid.');

            RETURN 2;
        END;

        IF @Status = '3'
        BEGIN
            RAISERROR(
                         'Proc: %s Step: %s ErrorInfo %s '
                        ,16
                        ,1
                        ,@ProcedureName
                        ,@ProcedureStep
                        ,'You dont have access to this module.'
                     );

            RETURN 3;
        END;

        IF @Status = '4'
        BEGIN
            RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep, 'Invalid License key.');

            RETURN 4;
        END;

        IF @Status = '5'
        BEGIN
            RAISERROR(
                         'Proc: %s Step: %s ErrorInfo %s '
                        ,16
                        ,1
                        ,@ProcedureName
                        ,@ProcedureStep
                        ,'Please install the License.'
                     );

            RETURN 5;
        END;

        RETURN @Status;
    END;
--RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,@ModuleErrorMessage);
END;
GO
   PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMfGetSettingsForCofigurator]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMfGetSettingsForCofigurator', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMfGetSettingsForCofigurator'--name of procedure
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
CREATE PROCEDURE [dbo].spMfGetSettingsForCofigurator
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go
ALTER   Procedure dbo.spMfGetSettingsForCofigurator
	 as
	 Begin
	 
	 DECLARE @PATH_CLR_ASSEMBLIES NVARCHAR(128) 
	
	 DECLARE @EDIT_MFVERSION_PROP NVARCHAR(128) 
	
	 DECLARE @EDIT_SQL_IMPORTFOLDER NVARCHAR(128)
	 DECLARE @EDIT_SQL_EXPORTFOLDER NVARCHAR(128)
	 DECLARE @ConnectorVersion AS VARCHAR(100)
	  

	 SELECT  @PATH_CLR_ASSEMBLIES=isnull(CONVERT(NVARCHAR(128), [ms].[Value]),'')
	 FROM   [dbo].[MFSettings] AS [ms] WHERE  [ms].[Name] = 'AssemblyInstallPath' AND [ms].[source_key] = 'App_Default'

	 SELECT  @EDIT_SQL_IMPORTFOLDER=isnull(CONVERT(nvarchar(128),[ms].[Value] ),'')
	 FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'FileTransferLocation' AND source_key	= 'Files_Default'

     SELECT  @EDIT_SQL_EXPORTFOLDER=isnull(CONVERT(nvarchar(128),[ms].[Value] ),'')
	 FROM [dbo].[MFSettings] AS [ms] WHERE [ms].[Name] = 'RootFolder' AND source_key	= 'Files_Default' 

	 SELECT @EDIT_MFVERSION_PROP=isnull(CONVERT(NVARCHAR(128), [ms].[Value]),'')
	 FROM   [dbo].[MFSettings] AS [ms] 		WHERE  [ms].[Name] = 'MFVersion' AND [ms].[source_key] = 'MF_Default'


	 SELECT @ConnectorVersion= CONVERT(nvarchar(128),MAX(Release)) FROM setup.[MFSQLObjectsControl] AS [mco]

	 Select @PATH_CLR_ASSEMBLIES as AssemblyPath,
	        @EDIT_SQL_IMPORTFOLDER as ImportPath,
			@EDIT_SQL_EXPORTFOLDER as ExportPath,
			@EDIT_MFVERSION_PROP   as ClientVersion,
			@ConnectorVersion as ConnectorVersion
	End


GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFValidateEmailProfile]';
GO

SET NOCOUNT ON;
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFValidateEmailProfile', -- nvarchar(100)
    @Object_Release = '3.1.1.32',              -- varchar(50)
    @UpdateFlag = 2;
-- smallint
GO

/*------------------------------------------------------------------------------------------------
	Author: Arnie Cilliers, Laminin Solutions
	Create date: 2015-12
	Database: 
	Description: Performs Vendor Renumbering based on values in apVendorRenumber_vw
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-22		LC			update settings index
	2016-10-12		LC			Change Settings Name
	2017-5-1		LC			Fix validate profile
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  exec spmfvalidateEmailProfile 'MailProfile'
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFValidateEmailProfile' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFValidateEmailProfile]
AS
    SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROC [dbo].[spMFValidateEmailProfile]
    @emailProfile NVARCHAR(100) OUTPUT,
    @debug SMALLINT = 0
AS
    SET NOCOUNT ON;

    DECLARE @ErrorMessage VARCHAR(100);

    DECLARE @Return INT;

    BEGIN TRY

        IF EXISTS
        (
            SELECT Value
            FROM dbo.MFSettings
                INNER JOIN
                 (
                     SELECT p.name
                     FROM msdb.dbo.sysmail_account a
                         INNER JOIN msdb.dbo.sysmail_profileaccount pa
                             ON a.account_id = pa.account_id
                         INNER JOIN msdb.dbo.sysmail_profile p
                             ON pa.profile_id = p.profile_id
                 ) ep
                    ON [ep].[name] = CONVERT(VARCHAR(100), [MFSettings].Value)
            WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                  AND dbo.MFSettings.[source_key] = 'Email'
        )
        BEGIN

            SELECT @emailProfile = CONVERT(VARCHAR(100), [MFSettings].Value)
            FROM dbo.MFSettings
            WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                  AND dbo.MFSettings.[source_key] = 'Email';

            IF @debug > 1
                SELECT @emailProfile AS mailprofile;

            SET @Return = 1;

        END

        ELSE
        BEGIN

            IF @debug > 1
                SELECT Value
                FROM dbo.MFSettings
                WHERE dbo.MFSettings.Name = 'SupportEMailProfile'
                      AND dbo.MFSettings.[source_key] = 'Email';

            SET @ErrorMessage
                = 'Email PROFILE ' + @emailProfile
                  + ' in Settings is not valid, the default profile will be used instead';

			SET @Return = 1

            SELECT TOP 1
                @emailProfile = p.name
            FROM msdb.dbo.sysmail_account a
                INNER JOIN msdb.dbo.sysmail_profileaccount pa
                    ON a.account_id = pa.account_id
                INNER JOIN msdb.dbo.sysmail_profile p
                    ON pa.profile_id = p.profile_id;
            --				where p.name = 'X';
            IF ISNULL(@emailProfile, '') <> ''
			BEGIN
            SET @Return = 0
                RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage)
				
				END;

            IF ISNULL((SUBSTRING(@emailProfile, 1, 1)), '$') = '$'
            BEGIN
                SET @ErrorMessage = 'No Valid Email profile exists';
                RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage);

                SET @Return = 2;

            END;

        END;

        RETURN @Return;

    END TRY
    BEGIN CATCH
        RAISERROR('EmailProfile error: %s', 10, 1, @ErrorMessage);
        RAISERROR('Fix SQL MailManager', 10, 1);
        RETURN -1;

    END CATCH;

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetMetadataStructureVersionID]';
GO
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetMetadataStructureVersionID', -- nvarchar(100)
    @Object_Release = '4.3.9.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

/*
2018-11-22	LC	Fix bug in showing incorrect message
2019-05-19	LC	Add catch try block
*/
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFGetMetadataStructureVersionID'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFGetMetadataStructureVersionID]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO



ALTER Procedure spMFGetMetadataStructureVersionID
@IsUpToDate bit=0 Output
as 

SET NOCOUNT ON

	-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFGetMetadataStructureVersionID';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

		-------------------------------------------------------------
		-- VARIABLES: LOGGING
		-------------------------------------------------------------
		DECLARE @LogType AS NVARCHAR(50) = 'Status'
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) = 'Started'

		DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
		DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL

		DECLARE @LogColumnName AS NVARCHAR(128) = NULL
		DECLARE @LogColumnValue AS NVARCHAR(256) = NULL

		DECLARE @count INT = 0;
		DECLARE @Now AS DATETIME = GETDATE();
		DECLARE @StartTime AS DATETIME = GETUTCDATE();
		DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
		DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

BEGIN TRY	
SET @ProcedureStep = 'Validate connection'
				DECLARE @VaultSettings NVARCHAR(MAX)
				DECLARE @LatestMetadataVersionID INT
				DECLARE @LastMetadataStructureID INT
				DECLARE @OutPUT NVARCHAR(MAX)

				Select @VaultSettings=dbo.FnMFVaultSettings()


				EXEC spMFGetMetadataStructureVersionIDInternal
				     @VaultSettings,
					 @OutPUT OUTPUT
                   

				set @LatestMetadataVersionID=Cast(@OutPUT as INT)
                 
				Select 
				 @LastMetadataStructureID=cast(ISNULL(Value,0) as INT) 
				from 
				 MFSettings 
				where 
				 source_key='MF_Default' 
				 and 
				 Name='LastMetadataStructureID'

				 IF @LatestMetadataVersionID = @LastMetadataStructureID
				  Begin
				     Set @IsUpToDate=1
				  End
				 ELSE
				  Begin
						Update 
						 MFSettings 
						Set 
						 Value=@LatestMetadataVersionID 
						where  
						 source_key='MF_Default' 
						 and 
						 Name='LastMetadataStructureID'

						 SeT @IsUpToDate=0
				  End


	END TRY
		BEGIN CATCH

			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );


		

			RETURN -1
		END CATCH


GO
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.spMFContextMenuActionItem';
GO
SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFContextMenuActionItem', -- nvarchar(100)
                                     @Object_Release = '4.1.5.42',
                                     @UpdateFlag = 2;

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\lerouxc
	Create date: 2018-5-12 09:52
	Database: 
	Description: Add Action item to Context Menu

	PARAMETERS:
			
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE					NAME		DESCRIPTION
2018-07-15					lc			Add state actions	
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  



-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFContextMenuActionItem' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFContextMenuActionItem]
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFContextMenuActionItem]
(
    @ActionName NVARCHAR(100),
    @ProcedureName NVARCHAR(100),
    @Description NVARCHAR(200),
    @RelatedMenu NVARCHAR(100),
    @IsRemove BIT = 0,
    @IsObjectContext BIT = 0,
    @IsWeblink BIT = 0,
    @IsAsynchronous BIT = 1,
    @IsStateAction BIT = 0,
    @PriorAction NVARCHAR(100) = NULL,
    @UserGroup NVARCHAR(100) = NULL,
    @Debug INT = 0
)
AS
SET NOCOUNT ON;

/*
Procedure to add new line item in MFContextMenu

*/


-------------------------------------------------------------
-- NEW MENU ACTION
-------------------------------------------------------------

BEGIN


    DECLARE @Action NVARCHAR(100);
    DECLARE @ActionMessage NVARCHAR(100);
    DECLARE @ActionType INT;

    DECLARE @ParentID INT;
    DECLARE @IsAsync INT;
    DECLARE @UserGroupID INT;
    DECLARE @SortOrder INT;
    DECLARE @MaxSortOrder INT;
    DECLARE @PriorMenu_ID INT;


    BEGIN

        SET @Action = @ProcedureName;

        SET @ActionType = CASE
                              WHEN @IsWeblink = 1 THEN
                                  2
                              WHEN @IsObjectContext = 0
                                   AND @IsAsynchronous = 0
                                   AND @IsStateAction = 0 THEN
                                  1
                              WHEN @IsObjectContext = 1
                                   AND @IsAsynchronous = 0
                                   AND @IsStateAction = 0 THEN
                                  3
                              WHEN @IsObjectContext = 0
                                   AND @IsAsynchronous = 1
                                   AND @IsStateAction = 0 THEN
                                  1
                              WHEN @IsObjectContext = 1
                                   AND @IsAsynchronous = 1
                                   AND @IsStateAction = 0 THEN
                                  3
                              WHEN @IsStateAction = 1
                                   AND @IsAsynchronous = 1 THEN
                                  5
                              WHEN @IsStateAction = 1
                                   AND @IsAsynchronous = 0 THEN
                                  4
                              ELSE
                                  3
                          END;

        SET @ActionMessage = @Description;
        SELECT @ParentID = [mcm].[ID]
        FROM [dbo].[MFContextMenu] AS [mcm]
        WHERE [mcm].[ActionName] = @RelatedMenu;
        SET @IsAsync = CASE
                           WHEN @IsAsynchronous = 0 THEN
                               0
                           ELSE
                               1
                       END;

        SET @UserGroupID = CASE
                               WHEN @UserGroup IS NULL THEN
                                   1
                               ELSE
                           (
                               SELECT [mfug].[UserGroupID]
                               FROM [dbo].[MFvwUserGroup] AS [mfug]
                               WHERE [mfug].[Name] = @UserGroup
                           )
                           END;


        SELECT @MaxSortOrder = ISNULL(MAX([mcm].[SortOrder]), -1)
        FROM [dbo].[MFContextMenu] AS [mcm]
        WHERE [mcm].[ParentID] = @ParentID;


        SELECT @PriorMenu_ID = CASE
                                   WHEN @RelatedMenu IS NOT NULL THEN
        (
            SELECT [ID] FROM [dbo].[MFContextMenu] WHERE [ActionName] = @PriorAction
        )
                                   ELSE
                                       @MaxSortOrder
                               END;


        SELECT @SortOrder = CASE
                                WHEN @MaxSortOrder = -1 THEN
                                    1
                                WHEN @PriorMenu_ID IS NULL THEN
                                    @MaxSortOrder + 1
                                ELSE
                                    @PriorMenu_ID + 1
                            END;



        CREATE TABLE [#ReorderList]
        (
            [id] INT,
            [sortorder] INT
        );
        INSERT INTO [#ReorderList]
        (
            [id],
            [sortorder]
        )
        SELECT [mcm].[ID],
               [mcm].[SortOrder]
        FROM [dbo].[MFContextMenu] AS [mcm]
        WHERE [mcm].[SortOrder] >= @SortOrder
              AND [mcm].[ParentID] = @ParentID;

        UPDATE [cm]
        SET [cm].[SortOrder] = [cm].[SortOrder] + 1
        FROM [dbo].[MFContextMenu] [cm]
            INNER JOIN [#ReorderList] AS [rl]
                ON [cm].[ID] = [rl].[id]
        WHERE [cm].[ID] = [rl].[id];

        IF @Debug > 0
            SELECT @ActionName AS [Actionname],
                   @Action AS [Action],
                   @ActionType AS [ActionType],
                   @ActionMessage AS [ActionMessage],
                   @SortOrder AS [SortOrder],
                   @ParentID AS [ParentID],
                   @IsAsynchronous AS [ISAsync],
                   @UserGroupID AS [UserGroupID];


        MERGE INTO [dbo].[MFContextMenu] [cm]
        USING
        (
            SELECT @ActionName AS [Actionname],
                   @Action AS [Action],
                   @ActionType AS [ActionType],
                   @ActionMessage AS [ActionMessage],
                   @SortOrder AS [SortOrder],
                   @ParentID AS [ParentID],
                   @IsAsynchronous AS [ISAsync],
                   @UserGroupID AS [UserGroupID]
        ) [S]
        ON [cm].[ActionName] = [S].[Actionname]
        WHEN NOT MATCHED THEN
            INSERT
            (
                [ActionName],
                [Action],
                [ActionType],
                [Message],
                [SortOrder],
                [ParentID],
                [ISAsync],
                [UserGroupID]
            )
            VALUES
            ([S].[Actionname], [S].[Action], [S].[ActionType], [S].[ActionMessage], [S].[SortOrder], [S].[ParentID],
             [S].[ISAsync], [S].[UserGroupID])
        WHEN MATCHED AND @IsRemove = 0 THEN
            UPDATE SET [cm].[Action] = [S].[Action],
                       [cm].[ActionType] = [S].[ActionType],
                       [cm].[Message] = [S].[ActionMessage],
                       [cm].[SortOrder] = [S].[SortOrder],
                       [cm].[ParentID] = [S].[ParentID],
                       [cm].[ISAsync] = [S].[ISAsync],
                       [cm].[UserGroupID] = [S].[UserGroupID];


        DROP TABLE [#ReorderList];

        IF @IsRemove = 1
            DELETE FROM [dbo].[MFContextMenu]
            WHERE [ActionName] = @ActionName;
    END;
END;

IF @Debug > 0
    SELECT *
    FROM [dbo].[MFContextMenu] AS [mcm];

GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.spMFContextMenuHeadingItem';
GO
SET NOCOUNT ON;
EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFContextMenuHeadingItem', -- nvarchar(100)
                                 @Object_Release = '4.1.5.42',
                                 @UpdateFlag = 2;

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\lerouxc
	Create date: 2018-5-12 09:52
	Database: 
	Description: Add Heading item to Context Menu

	PARAMETERS:
			
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE					NAME		DESCRIPTION
	2018-07-15				LC			Add ability to change Heading
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  



-----------------------------------------------------------------------------------------------*/
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFContextMenuHeadingItem' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFContextMenuHeadingItem
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE dbo.spMFContextMenuHeadingItem
(

@MenuName NVARCHAR(100) 
, @PriorMenu NVARCHAR(100) = NULL
,@IsObjectContextMenu BIT = 0
,@IsRemove BIT = 0
, @UserGroup NVARCHAR(100) = NULL
,@Debug INT = 0

)
AS
/*
Procedure to add new line item in MFContextMenu
*/


-------------------------------------------------------------
-- NEW MENU HEADING
-------------------------------------------------------------
BEGIN

DECLARE @ActionName NVARCHAR(100)
DECLARE @Action NVARCHAR(100)
DECLARE @ActionMessage NVARCHAR(100)
DECLARE @ActionType INT

DECLARE @ParentID INT
DECLARE @IsAsync INT
DECLARE @UserGroup_ID INT
DECLARE @SortOrder INT
DECLARE @MaxSortOrder INT
DECLARE @PriorMenu_ID int

IF NOT EXISTS(SELECT 1 FROM [dbo].[MFContextMenu] AS [mcm] WHERE [mcm].[ActionName] = @MenuName)
BEGIN


SET @ActionName = @MenuName
SET @Action = NULL
SET @ActionType = CASE WHEN @IsObjectContextMenu = 1 THEN 3 ELSE 0 end
SET @ActionMessage = NULL
SET @ParentID = 0
SET @IsAsync = NULL

SET @Usergroup_ID = CASE WHEN @usergroup IS NULL THEN 1 ELSE (SELECT [mfug].[UserGroupID] FROM [dbo].[MFvwUserGroup] AS [mfug] WHERE mfug.[Name] = @UserGroup)
END


SELECT @MaxSortOrder = ISNULL(MAX([mcm].[SortOrder]),-1) FROM [dbo].[MFContextMenu] AS [mcm]


SELECT @PriorMenu_ID = CASE WHEN @PriorMenu IS NOT NULL THEN (SELECT id FROM MFContextMenu WHERE ActionName = @PriorMenu)
ELSE @MaxSortOrder
END


SELECT @SortOrder = CASE WHEN @MaxSortOrder  = -1 THEN 1
WHEN @PriorMenu_ID IS NULL THEN @MaxSortOrder + 1
ELSE @PriorMenu_ID + 1
END


	
CREATE TABLE #ReorderList (id INT, sortorder int)
INSERT INTO [#ReorderList]
(
    [id],
    [sortorder]
)
SELECT id, [sortorder] FROM [dbo].[MFContextMenu] AS [mcm] WHERE [sortorder] >= @SortOrder

UPDATE cm
SET [sortorder] = cm.[sortorder] + 1
FROM MFContextMenu cm
INNER JOIN [#ReorderList] AS [rl]
ON cm.id = rl.[id]
WHERE cm.id = rl.[id]

      Merge INTO [dbo].[MFContextMenu] cm
       
        
		USING 
		 (SELECT @ActionName AS [Actionname],
               @Action AS [Action],
               @ActionType AS [ActionType],
               @ActionMessage AS [ActionMessage],
               @SortOrder AS [SortOrder],
               @ParentID AS [ParentID],
               @IsAsync AS [ISAsync],
               @UserGroup_ID AS [UserGroupID] ) S 
			   ON cm.[ActionName] = s.[Actionname]
			   WHEN NOT MATCHED THEN INSERT
               (
            [ActionName],
            [Action],
            [ActionType],
            [Message],
            [SortOrder],
            [ParentID],
            [ISAsync],
            [UserGroupID]
			)
			VALUES
             (s.[ActionName],
            s.[Action],
            s.[ActionType],
            s.[ActionMessage],
            s.[SortOrder],
            s.[ParentID],
            s.[ISAsync],
            s.[UserGroupID])
			WHEN MATCHED AND @IsRemove = 0 THEN UPDATE SET
            [Action] = s.[Action] ,
            [ActionType] = s.[ActionType],
            [Message] = s.[ActionMessage],
            [SortOrder] = s.[SortOrder],
            [ParentID] = s.[ParentID],
            [ISAsync] = s.[ISAsync],
            [UserGroupID] = s.[UserGroupID];


        DROP TABLE [#ReorderList];

IF @IsRemove = 1
            DELETE FROM [dbo].[MFContextMenu]
            WHERE [ActionName] = @ActionName;
    END;
	END


IF @Debug > 0
SELECT * FROM [dbo].[MFContextMenu] AS [mcm]

GO

 


/*
Reporting setup

input: classes include in reporting

validate connection
synchronise metadata
create class tables
create all lookup views
create custom update procedure
create menu item in context menu
create update button
create view

*/
GO


PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSetup_Reporting]';
GO

SET NOCOUNT ON;
GO


EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFSetup_Reporting' -- nvarchar(100)
                                    ,@Object_Release = '4.3.9.48'
                                    ,@UpdateFlag = 2;
GO

/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
	Create date: 12/11/2018
	Database: 
	Description: Custom script to prepare database for reporting

	PARAMETERS:
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2019-1-31		LC			Fix bug for spmfDropandUpdateTable parameter
	2019-4-10		LC			Adjust to allow for context menu configuration in different languages
	2019-5-17		LC			Set security for menu to MFSQLConnector group
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFSetup_Reporting' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

CREATE PROCEDURE [dbo].[spMFSetup_Reporting]
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFSetup_Reporting]
    @Classes NVARCHAR(400)
   ,@Debug INT = 0
AS
SET NOCOUNT ON;

BEGIN
    -- Debug params
    DECLARE @DebugText NVARCHAR(100);
    DECLARE @DefaultDebugText NVARCHAR(100) = 'Proc: %s Step: %s';
    DECLARE @Procedurestep NVARCHAR(100);
    DECLARE @ProcedureName NVARCHAR(100) = 'spMFSetup_Reporting';

    SET @Procedurestep = 'Start';

    --Other Variables
    DECLARE @ProcessBatch_ID INT;
    DECLARE @className NVARCHAR(100);
    ------------------------------------------------------------
    -- VARIABLES: T-SQL Processing
    -------------------------------------------------------------
    DECLARE @rowcount AS INT = 0;
    DECLARE @return_value AS INT = 0;
    DECLARE @error AS INT = 0;

    -------------------------------------------------------------
    -- VARIABLES: DYNAMIC SQL
    -------------------------------------------------------------
    DECLARE @sql NVARCHAR(MAX) = N'';
    DECLARE @sqlParam NVARCHAR(MAX) = N'';

    --BEGIN  
    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;


        PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME())
              + 'Script to setup reporting for classes ' + @Classes;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);


    -------------------------------------------------------------
    -- Custom params
    -------------------------------------------------------------
    DECLARE @MessageOUt NVARCHAR(100);

    --<Begin Proc>--
    SET @Procedurestep = 'Connection Test';

    --
    -------------------------------------------------------------
    -- connection test	
    -------------------------------------------------------------
    EXEC @return_value = [dbo].[spMFVaultConnectionTest] @MessageOut = @MessageOUt OUTPUT; -- nvarchar(100)

    IF @return_value <> 1
    BEGIN
        SET @DebugText = ' Unable To connect to Vault - Routine aborted';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @Procedurestep);
    END
	ELSE
	BEGIN
	  SET @DebugText = ' :Connected to vault ';
    SET @DebugText = @DefaultDebugText + @DebugText;
	        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

	END
	 ;

    -------------------------------------------------------------
    -- Update Metadata
    -------------------------------------------------------------
    SET @Procedurestep = 'Synchronize metadata';

    IF
    (
        SELECT COUNT(*) FROM [dbo].[MFClass]
    ) = 0
    BEGIN
        EXEC @return_value = [dbo].[spMFSynchronizeMetadata] @Debug = 0                                  -- smallint
                                                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT; -- int
    END;
    ELSE
    BEGIN
        EXEC @return_value = [dbo].[spMFDropAndUpdateMetadata] @IsResetAll = 0                               -- smallint
                                                              ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                                              ,@Debug = 0                                 -- smallint
                                                              ,@WithClassTableReset = 0                   -- smallint
                                                              ,@IsStructureOnly = 0;                      -- smallint
    END;

    IF @return_value <> 1
    BEGIN
        SET @DebugText = ' Unable to update metadata - Routine aborted';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 16, 1, @ProcedureName, @Procedurestep);
    END;
    ELSE
    BEGIN
        SET @DebugText = ' :Successfully updated Metadata';
        SET @DebugText = @DefaultDebugText + @DebugText;

        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);
    END;
END;

-------------------------------------------------------------
-- Create tables
-------------------------------------------------------------
SET @Procedurestep = 'Create Class tables ';

DECLARE @ClassList AS TABLE
(
    [id] INT IDENTITY
   ,[Item] NVARCHAR(100)
);

INSERT INTO @ClassList
(
    [Item]
)
SELECT ltrim([fmpds].[ListItem])
FROM [dbo].[fnMFParseDelimitedString](@Classes, ',') AS [fmpds];

-------------------------------------------------------------
-- validate classes entered
------------------------------------------------------------
DECLARE @ErrorClasses NVARCHAR(100);

SELECT @ErrorClasses = STUFF((
                                 SELECT ', ' + [cl].[Item]
                                 FROM @ClassList               AS [cl]
                                     LEFT JOIN [dbo].[MFClass] AS [mc]
                                         ON [mc].[Name] = [cl].[Item]
                                 WHERE [mc].[Name] IS NULL
                                 FOR XML PATH('')
                             )
                            ,1
                            ,1
                            ,''
                            );

	--						SELECT @ErrorClasses

IF @ErrorClasses IS NOT NULL
BEGIN
    SET @DebugText = ' Unable to find classes: %s. reenter parameter and try again - Routine aborted';
    SET @DebugText = @DefaultDebugText + @DebugText;

    RAISERROR(@DebugText, 16, 1, @ProcedureName, @Procedurestep, @ErrorClasses);
END;

IF
(
    SELECT COUNT(*) FROM @ClassList
) > 0
AND @ErrorClasses IS NULL
BEGIN
    SET @rowcount = 1;

    WHILE @rowcount IS NOT NULL
    BEGIN
        SELECT @className = [Item]
        FROM @ClassList
        WHERE [id] = @rowcount;

        EXEC @return_value = [dbo].[spMFCreateTable] @className;

        IF @return_value = 1
        BEGIN
            SET @DebugText = ' :Successfully created Table for %s';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @className);
        END;
        ELSE
        BEGIN
            SET @DebugText = ' :Unable to create Table for %s';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @className);
        END;

        SELECT @rowcount =
        (
            SELECT MIN([l].[id]) FROM @ClassList AS [l] WHERE [l].[id] > @rowcount
        );
    END;

    -------------------------------------------------------------
    -- lookups to create
    -------------------------------------------------------------
    DECLARE @Valuelists AS TABLE
    (
        [id] INT IDENTITY
       ,[Name] NVARCHAR(100)
    );

    DECLARE @ValuelistName NVARCHAR(100);
    DECLARE @ViewName NVARCHAR(100);

    EXEC [dbo].[spMFClassTableColumns];

    INSERT INTO @Valuelists
    (
        [Name]
    )
    SELECT REPLACE([lookupType], 'Table_MFValuelist_', '')
    FROM [##spMFClassTableColumns]
    WHERE [class] IN (
                         SELECT [Item] FROM @ClassList
                     )
          AND SUBSTRING([lookupType], 1, 17) = 'Table_MFValuelist'
    GROUP BY [lookupType];

    IF
    (
        SELECT COUNT(*) FROM @Valuelists
    ) > 0
    BEGIN
        SET @rowcount = 1;

        WHILE @rowcount IS NOT NULL
        BEGIN
            SELECT @ValuelistName = [Name]
            FROM @Valuelists
            WHERE [id] = @rowcount;

            SET @ViewName = 'vw' + @ValuelistName;

            EXEC [dbo].[spMFCreateValueListLookupView] @ValueListName = @ValuelistName -- nvarchar(128)
                                                      ,@ViewName = @ViewName           -- nvarchar(128)
                                                      ,@Schema = 'Custom'              -- nvarchar(20)
                                                      ,@Debug = 0;                     -- smallint

            SET @DebugText = ' :Successfully created View for Valuelist %s';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @ValuelistName);

            SELECT @rowcount =
            (
                SELECT MIN([l].[id]) FROM @Valuelists AS [l] WHERE [l].[id] > @rowcount
            );
        END;

		-------------------------------------------------------------
		-- setup MFContextmenu
		-------------------------------------------------------------
		SET @Procedurestep = 'Create MFContextmenu records'
		DECLARE @UserGroup NVARCHAR(100)

	
								SELECT TOP 1 @userGroup = [ug].[UserGroupID] FROM [dbo].[MFVaultSettings] AS [mvs]
								INNER JOIN [dbo].[MFLoginAccount] AS [mla]
								ON mvs.[Username] = mla.[UserName]
								CROSS APPLY (
								SELECT [mfug].[UserGroupID] FROM [dbo].[MFvwUserGroup] AS [mfug]
								WHERE name = 'MFSQLConnector') ug



		EXEC [dbo].[spMFContextMenuHeadingItem] @MenuName = 'Update Tables'            -- nvarchar(100)
		                                       ,@PriorMenu = null          -- nvarchar(100)
		                                       ,@IsObjectContextMenu = 0 -- bit
		                                       ,@IsRemove = 0            -- bit
		                                       ,@UserGroup = @userGroup         -- nvarchar(100)
		                                       ,@Debug = 0               -- int

		EXEC [dbo].[spMFContextMenuActionItem] @ActionName = 'Update Reporting Data'      -- nvarchar(100)
		                                      ,@ProcedureName = 'custom.DoUpdateReportingData'   -- nvarchar(100)
		                                      ,@Description = 'Updating all tables included in App'     -- nvarchar(200)
		                                      ,@RelatedMenu = 'Update Tables'     -- nvarchar(100)
		                                      ,@IsRemove = 0        -- bit
		                                      ,@IsObjectContext = 0 -- bit
		                                      ,@IsWeblink = 0       -- bit
		                                      ,@IsAsynchronous = 1  -- bit
		                                      ,@IsStateAction = 0   -- bit
		                                      ,@PriorAction = null     -- nvarchar(100)
		                                      ,@UserGroup = @userGroup      -- nvarchar(100)
		                                      ,@Debug = 0           -- int
		
	          SET @DebugText = ' :Successfully created menu item for updating tables';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

			-------------------------------------------------------------
			-- Reset messaging to allow for messages to be be produced in app
			-------------------------------------------------------------
				SET @Procedurestep = 'enable User Messages'
			UPDATE [dbo].[MFSettings]
			SET value = '1' WHERE [Name] = 'App_DetailLogging'

			UPDATE [dbo].[MFSettings]
			SET value = '1' WHERE [Name] = 'MFUserMessagesEnabled'

			

			    SET @DebugText = '';
            SET @DebugText = @DefaultDebugText + @DebugText;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);

    END;
END;
GO
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFTableAuditinBatches]';
GO

SET NOCOUNT ON;
GO

/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
	Create date: 15/12/2018
	Database:
	Description: Procedure to update class table in batches

Updating a large number of records from a specific class in MF to SQL in batches 

it is advisable to process updates of large datasets in batches.  
Processing batches will ensure that a logical restart point can be determined in case of failure
It will also keep the size of the dataset for transfer within the limits of 8000 bites.

	PARAMETERS:
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION

	updated version 2018-12-15

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFTableAuditinBatches' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

CREATE PROCEDURE [dbo].[spMFTableAuditinBatches]
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFTableAuditinBatches]
(
    @MFTableName NVARCHAR(100)
   ,@FromObjid INT = 1 -- the starting objid of the update
   ,@ToObjid INT = 100000
   ,@WithStats BIT = 1 -- set to 0 to suppress display messages
   ,@Debug INT = 0     --
)
AS
SET NOCOUNT ON;

BEGIN
    -- Debug params
    DECLARE @DebugText NVARCHAR(100);
    DECLARE @DefaultDebugText NVARCHAR(100);
    DECLARE @Procedurestep NVARCHAR(100);
    DECLARE @ProcedureName NVARCHAR(100) = 'dbo.spMFTableAuditinBatches';

    SET @Procedurestep = 'Start';

    --BEGIN  
    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);
    END;

    --<Begin Proc>--

    --set the parameters

    -------------------------------------------------------------
    -- calculate batch size
    -------------------------------------------------------------
    DECLARE @BatchSize INT;
    -- sizes is restricted by objid length.

    --other parameters 
    DECLARE @StartRow        INT
           ,@MaxRow          INT
           ,@RecCount        INT
           ,@BatchCount      INT           = 1
           ,@BatchesToRun    INT
           ,@ObjIdCount      INT
           ,@ProcessBatch_ID INT
           ,@UpdateID        INT
           ,@SQL             NVARCHAR(MAX)
           ,@Params          NVARCHAR(MAX)
           ,@StartTime       DATETIME
           ,@ProcessingTime  INT
           ,@objids          NVARCHAR(4000)
           ,@Message         NVARCHAR(100)
           ,@Update_IDOut    INT
           ,@Session_ID      INT;

    -------------------------------------------------------------
    -- GET SESSION
    -------------------------------------------------------------
    SELECT @Session_ID = MAX([mah].[SessionID]) + 1
    FROM [dbo].[MFAuditHistory]    AS [mah]
        INNER JOIN [dbo].[MFClass] [mc]
            ON [mah].[Class] = [mc].[MFID]
    WHERE [mc].[TableName] = @MFTableName;

    -------------------------------------------------------------
    -- Batch size
    -------------------------------------------------------------
    BEGIN
        SELECT @RecCount = @ToObjid - @FromObjid + 1;

        --       SELECT @RecCount AS [RecCount];
        SELECT @BatchSize = 4000 / (LEN(@ToObjid));

        --      SELECT @BatchSize AS [MAxBatchsize];

        --     SELECT @ObjIdCount = @BatchSize;
        SELECT @BatchesToRun = CASE
                                   WHEN @RecCount < @BatchCount THEN
                                       1
                                   ELSE
                                       @RecCount / @BatchSize + 1
                               END;

        --     SELECT @BatchesToRun;

        --start
        SET @StartRow = @FromObjid;
        SET @MaxRow = @ToObjid;
        SET @Params = N'@Objids nvarchar(4000) output';

        --while loop
        WHILE @ToObjid > @StartRow
        BEGIN
            SET @StartTime = GETDATE();
            SET @objids = NULL;
            SET @Message
                = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Started: ' + CAST(@StartTime AS VARCHAR(30));

            --IF @WithStats = 1
            --    RAISERROR(@Message, 10, 1) WITH NOWAIT;
            SET @ObjIdCount = CASE
                                  WHEN @BatchesToRun = 1 THEN
                                      @RecCount % @BatchSize
                                  ELSE
                                      @ObjIdCount
                              END;

            --         SELECT @ObjIdCount AS [listcount];

            -------------------------------------------------------------
            -- Get list of id's in numeric sequence
            -------------------------------------------------------------
            IF OBJECT_ID('Tempdb..##ObjidTable') > 0
                DROP TABLE [##ObjidTable];

            SET @SQL
                = N'(SELECT TOP ' + CAST(@ObjIdCount AS VARCHAR(12)) + ' identity(int,'
                  + CAST(@StartRow AS VARCHAR(20)) + ',1) AS objid into ##ObjidTable FROM sys.[columns] AS [c])';

            --SELECT @SQL
            EXEC (@SQL);

            -------------------------------------------------------------
            -- validate objectvers of id (eliminate ids that is not part of class)
            -------------------------------------------------------------
            SELECT @objids = STUFF((
                                       SELECT ',' + CAST([Objid] AS NVARCHAR(20))
                                       FROM [##ObjidTable]
                                       FOR XML PATH('')
                                   )
                                  ,1
                                  ,1
                                  ,''
                                  )
            FROM [##ObjidTable] AS [ot];

            IF @Debug > 0
                SELECT MAX([objid]) AS [MaxObjid]
                      ,COUNT(*)     AS [RecCount]
                FROM [##ObjidTable];

            IF @Debug > 0
                SELECT COUNT(*)
                FROM [dbo].[fnMFParseDelimitedString](@objids, ',') AS [fmpds];

            -------------------------------------------------------------
            -- perform table audit on selected ID's
            -------------------------------------------------------------
            DECLARE @SessionIDOut   INT
                   ,@NewObjectXml   NVARCHAR(MAX)
                   ,@DeletedInSQL   INT
                   ,@UpdateRequired BIT
                   ,@OutofSync      INT
                   ,@ProcessErrors  INT;

            EXEC [dbo].[spMFTableAudit] @MFTableName = @MFTableName                -- nvarchar(128)
                                       ,@MFModifiedDate = NULL                     -- datetime
                                       ,@ObjIDs = @objids                          -- nvarchar(4000)
                                       ,@SessionIDOut = @Session_ID                -- int
                                       ,@NewObjectXml = @NewObjectXml OUTPUT       -- nvarchar(max)
                                       ,@DeletedInSQL = @DeletedInSQL OUTPUT       -- int
                                       ,@UpdateRequired = @UpdateRequired OUTPUT   -- bit
                                       ,@OutofSync = @OutofSync OUTPUT             -- int
                                       ,@ProcessErrors = @ProcessErrors OUTPUT     -- int
                                       ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                       ,@Debug = @Debug;                           -- smallint

            DECLARE @NewXML XML;

            SET @NewXML = CAST(@NewObjectXml AS XML);

            SELECT @RecCount = COUNT(*)
            FROM @NewXML.[nodes]('/form/objVers') AS [t]([c]);

            /*
                SET @Params = '@RecCount int output';
                SET @SQL
                    = 'SELECT @RecCount = COUNT(*) FROM ' + @MFTableName + ' where update_ID ='
                      + CAST(@Update_IDOut AS VARCHAR(10)) + '';

                EXEC [sys].[sp_executesql] @SQL, @Params, @RecCount OUTPUT;

                IF @Debug > 0
                    SELECT @RecCount AS [recordcount];
            */

            -------------------------------------------------------------
            -- performance message
            -------------------------------------------------------------
            SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
            SET @Message
                = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Processing (s) : '
                  + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + ' From Object ID: ' + CAST(@StartRow AS VARCHAR(10))
                  + ' Processed: ' + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));

            IF @WithStats = 1
                RAISERROR(@Message, 10, 1) WITH NOWAIT;

            SET @BatchCount = @BatchCount + 1;
            SET @BatchesToRun = @BatchesToRun - 1;

            --        SELECT @BatchesToRun AS [BatchestoRun];

            --         SELECT @BatchSize AS [batchsize];
            SET @StartRow = @StartRow + @ObjIdCount;

        --        SELECT @StartRow [nextstartrow];
        END;
    END;
END;
GO
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateTableinBatches]';
GO

SET NOCOUNT ON;
GO

/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
	Create date: 15/12/2018
	Database:
	Description: Procedure to update class table in batches

Updating a large number of records from a specific class in MF to SQL in batches 

it is advisable to process updates of large datasets in batches.  
Processing batches will ensure that a logical restart point can be determined in case of failure
It will also keep the size of the dataset for transfer within the limits of 8000 bites.

	PARAMETERS:
															
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION

	updated version 2018-12-15

------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  
-----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFUpdateTableinBatches' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

CREATE PROCEDURE [dbo].[spMFUpdateTableinBatches]
AS
SELECT 'created, but not implemented yet.';
GO

SET NOEXEC OFF;
GO

ALTER PROC [dbo].[spMFUpdateTableinBatches]
(
    @MFTableName NVARCHAR(100)
   ,@UpdateMethod INT = 1
   ,@maxObjid INT = 10000
   ,@BatchestoRun INT = 5 -- use this setting limit the iterations for testing.  To process all records set to a factor of the highest objid / batchsize
   ,@MinObjid INT = 1     -- the starting objid of the update
   ,@WithStats BIT = 1    -- set to 0 to suppress display messages
   ,@Debug INT = 0        --
)
AS
SET NOCOUNT ON;

BEGIN
    -- Debug params
    DECLARE @DebugText NVARCHAR(100);
    DECLARE @DefaultDebugText NVARCHAR(100);
    DECLARE @Procedurestep NVARCHAR(100);
    DECLARE @ProcedureName NVARCHAR(100) = 'dbo.spMFUpdateTableinBatches';

    SET @Procedurestep = 'Start';

    --BEGIN  
    SET @DebugText = '';
    SET @DebugText = @DefaultDebugText + @DebugText;

    IF @Debug > 0
    BEGIN
        RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep);
    END;

    --<Begin Proc>--

    --set the parameters

    -------------------------------------------------------------
    -- calculate batch size
    -------------------------------------------------------------
    DECLARE @BatchSize INT;
    -- sizes is restricted by objid length.

    --other parameters 
    DECLARE @StartRow        INT
           ,@MaxRow          INT
           ,@RecCount        INT
           ,@BatchCount      INT           = 1
           ,@ProcessBatch_ID INT
           ,@UpdateID        INT
           ,@SQL             NVARCHAR(MAX)
           ,@Params          NVARCHAR(MAX)
           ,@StartTime       DATETIME
           ,@ProcessingTime  INT
           ,@objids          NVARCHAR(4000)
           ,@Message         NVARCHAR(100)
           ,@Update_IDOut    INT;

    -------------------------------------------------------------
    -- UPDATE METHOD 1
    -------------------------------------------------------------
    IF @UpdateMethod = 1
    BEGIN
        SELECT @BatchSize = 4000 / (LEN(@maxObjid) + 1);

        --start
        SET @StartRow = @MinObjid;
        SET @MaxRow = @StartRow + (@BatchSize * @BatchestoRun);
        SET @Params = N'@Objids nvarchar(4000) output';

        --while loop
        WHILE @StartRow < @MaxRow
        BEGIN
            SET @StartTime = GETDATE();
            SET @objids = NULL;
            SET @Message
                = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Started: ' + CAST(@StartTime AS VARCHAR(30));

            IF @WithStats = 1
                RAISERROR(@Message, 10, 1) WITH NOWAIT;

            -------------------------------------------------------------
            -- Get list of id's in numeric sequence
            -------------------------------------------------------------
            IF OBJECT_ID('Tempdb..##ObjidTable') > 0
                DROP TABLE [##ObjidTable];

            SET @SQL
                = N'(SELECT TOP ' + CAST(@BatchSize AS VARCHAR(5)) + ' identity(int,' + CAST(@StartRow AS VARCHAR(20))
                  + ',1) AS objid into ##ObjidTable FROM sys.[columns] AS [c])
'           ;

            --SELECT @SQL
            EXEC (@SQL);

            -------------------------------------------------------------
            -- validate objectvers of id (eliminate ids that is not part of class)
            -------------------------------------------------------------
            SELECT @objids = STUFF((
                                       SELECT ',' + CAST([Objid] AS NVARCHAR(20))
                                       FROM [##ObjidTable]
                                       FOR XML PATH('')
                                   )
                                  ,1
                                  ,1
                                  ,''
                                  )
            FROM [##ObjidTable] AS [ot];

            IF @Debug > 0
                SELECT MAX([objid]) AS [MaxObjid]
                      ,COUNT(*)     AS [RecCount]
                FROM [##ObjidTable];

            IF @Debug > 0
                SELECT COUNT(*)
                FROM [dbo].[fnMFParseDelimitedString](@objids, ',') AS [fmpds];

            DECLARE @outPutXML NVARCHAR(MAX);

            EXEC [dbo].[spMFGetObjectvers] @TableName = @MFTableName       -- nvarchar(100)
                                          ,@dtModifiedDate = NULL          -- datetime
                                          ,@MFIDs = @objids                -- nvarchar(4000)
                                          ,@outPutXML = @outPutXML OUTPUT; -- nvarchar(max)

            DECLARE @NewXML XML;

            SET @NewXML = CAST(@outPutXML AS XML);

            IF @Debug > 0
                SELECT @NewXML AS [Objvers];

            SELECT COUNT([t].[c].[value]('(@objectID)[1]', 'INT')) AS [ObjID]
            FROM @NewXML.[nodes]('/form/objVers') AS [t]([c]);

            -------------------------------------------------------------
            -- prepare list for update
            -------------------------------------------------------------
            DECLARE @objidlist AS TABLE
            (
                [Objid] INT
            );

            DELETE FROM @objidlist;

            INSERT INTO @objidlist
            (
                [Objid]
            )
            SELECT [t].[c].[value]('(@objectID)[1]', 'INT') AS [ObjID]
            FROM @NewXML.[nodes]('/form/objVers') AS [t]([c])
                INNER JOIN [##ObjidTable]         [ot]
                    ON [t].[c].[value]('(@objectID)[1]', 'INT') = [ot].[objid];

            SET @objids = NULL;

            SELECT @objids = STUFF((
                                       SELECT ',' + CAST([o].[Objid] AS NVARCHAR(20))
                                       FROM @objidlist AS [o]
                                       FOR XML PATH('')
                                   )
                                  ,1
                                  ,1
                                  ,''
                                  )
            FROM @objidlist AS [o2];

            IF @Debug > 0
                SELECT @objids AS [Objids];

            -------------------------------------------------------------
            -- Update to/from m-files
            -------------------------------------------------------------
            IF @objids IS NOT NULL
            BEGIN
                EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName          -- nvarchar(200)
                                            ,@UpdateMethod = 1                    -- int
                                            ,@ObjIDs = @objids                    -- nvarchar(max)
                                            ,@Update_IDOut = @Update_IDOut OUTPUT -- int
                                            ,@ProcessBatch_ID = @ProcessBatch_ID  -- int
                                            ,@Debug = 0;

                SET @Params = '@RecCount int output';
                SET @SQL
                    = 'SELECT @RecCount = COUNT(*) FROM ' + @MFTableName + ' where update_ID ='
                      + CAST(@Update_IDOut AS VARCHAR(10)) + '';

                EXEC [sys].[sp_executesql] @SQL, @Params, @RecCount OUTPUT;

                IF @Debug > 0
                    SELECT @RecCount AS [recordcount];
            END;

            -------------------------------------------------------------
            -- performance message
            -------------------------------------------------------------
            SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
            SET @Message
                = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Processing (s) : '
                  + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + ' From Object ID: ' + CAST(@StartRow AS VARCHAR(10))
                  + ' Processed: ' + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));

            IF @WithStats = 1
                RAISERROR(@Message, 10, 1) WITH NOWAIT;

            SET @BatchCount = @BatchCount + 1;
            SET @StartRow = @StartRow + @BatchSize;
        END;
    END;

    -------------------------------------------------------------
    -- UPDATE METHOD 0
    -------------------------------------------------------------
    IF @UpdateMethod = 0
    BEGIN
        
        SET @Params = N'@Reccount int output';
        SET @SQL
            = N'SELECT @RecCount = count(*) FROM ' + QUOTENAME(@MFTableName)
              + ' Where process_ID = 1 or process_ID = 99';

	IF @Debug > 0
	SELECT @SQL AS SQL;

        EXEC [sys].[sp_executesql] @stmt = @SQL, @param = @Params, @RecCount = @RecCount OUTPUT;

	IF @Debug > 0
	SELECT @RecCount AS RecCount;

        IF @RecCount > 0
        BEGIN
            SELECT @BatchSize = 4000 / (LEN(@maxObjid) + 1);

			IF @Debug > 0
			SELECT @BatchSize AS Batchsize, @maxObjid AS MaxObject;

            SELECT @BatchestoRun = @RecCount / @BatchSize;

            SET @SQL = N'
UPDATE ' +  QUOTENAME(@MFTableName) + ' 
SET [Process_ID] = 99 WHERE [Process_ID] = 1;';

            EXEC (@SQL);

            WHILE @RecCount > 0
            BEGIN
			SET @StartTime = GETDATE();
                SET @Message
                    = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Started: ' + CAST(@StartTime AS VARCHAR(30));

                IF @WithStats = 1
		--		PRINT @Message;
                   RAISERROR(@Message, 10, 1) WITH NOWAIT;

                SET @SQL
                    = N'UPDATE t
SET process_ID = 1
FROM ' +        QUOTENAME(@MFTableName) + ' t
INNER JOIN (SELECT TOP ' + CAST(@BatchSize AS NVARCHAR(5)) + ' ID FROM ' + +QUOTENAME(@MFTableName)
                      + '  
WHERE [Process_ID] = 99) t2
ON t.id = t2.id';

IF @debug > 0
SELECT @SQL AS SQL;

                EXEC sp_executeSQL @SQL

                EXEC [dbo].[spMFUpdateTable] @MFTableName = @MFTableName                -- nvarchar(200)
                                            ,@UpdateMethod = @UpdateMethod              -- int
                                            ,@Update_IDOut = @Update_IDOut OUTPUT       -- int
                                            ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT -- int
                                            ,@Debug = 0;

                
                -------------------------------------------------------------
                -- performance message
                -------------------------------------------------------------
                SET @ProcessingTime = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
                SET @Message
                    = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Processing (s) : '
                      + CAST(@ProcessingTime / 1000 AS VARCHAR(10)) + ' remaining: ' + CAST(ISNULL(@RecCount, 0) AS VARCHAR(10));
             
			    SET @Params = N'@RecCount int output';
                SET @SQL
                    = N'SELECT @RecCount = COUNT(*) FROM ' + QUOTENAME(@MFTableName)
                      + ' AS [mbs] WHERE process_ID = 99';

                EXEC [sys].[sp_executesql] @SQL, @Params, @RecCount OUTPUT;

				IF @Debug > 0
				SELECT @RecCount AS nextbatch;

                IF @WithStats = 1
			--	PRINT @Message;
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                SET @BatchCount = @BatchCount + 1;
            END; --end loop updatetable
        END; --RecCount > 0
    END; --Update method = 0
END;
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spmfSynchronizeWorkFlowSateColumnChange]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spmfSynchronizeWorkFlowSateColumnChange', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spmfSynchronizeWorkFlowSateColumnChange'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
 --if the routine exists this stub creation step is parsed but not executed
CREATE PROCEDURE [dbo].[spmfSynchronizeWorkFlowSateColumnChange]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


Alter PROCEDURE [dbo].[spmfSynchronizeWorkFlowSateColumnChange]
@TableName Nvarchar(200)=null,
@ProcessBatch_id INT           = NULL OUTPUT,
@Debug           INT           = 0
As
/*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize ValueListItems name change in M-Files into the reference table  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **				
  **
  ** Parameters and acceptable values: 
  **					@TableName Nvarchar(200)=null,
						@ProcessBatch_id INT           = NULL OUTPUT,
	                    @Debug           INT           = 0MALLINT = 0
  
  **
  ** Called By:			spMFSynchronizeValueListItems
  **
  ** Calls:           
  **													
  **
  ** Author:			DEV2
  ** Date:				01-03-2018
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
 
  ******************************************************************************/ 
begin

			BEGIN TRY
			SET NOCOUNT ON;
			-----------------------------------------------------
			--DECLARE VARIABLES FOR LOGGING
			-----------------------------------------------------
			--used on MFProcessBatchDetail;
			DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
			DECLARE @DebugText AS NVARCHAR(256) = '';
			DECLARE @LogTypeDetail AS NVARCHAR(MAX) = '';
			DECLARE @LogTextDetail AS NVARCHAR(MAX) = '';
			DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = '';
			DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
			DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
			DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
			DECLARE @ProcessType NVARCHAR(50) = 'Object History';
			DECLARE @LogType AS NVARCHAR(50) = 'Status';
			DECLARE @LogText AS NVARCHAR(4000) = 'Get History Initiated';
			DECLARE @LogStatus AS NVARCHAR(50) = 'Started';
			DECLARE @Status AS NVARCHAR(128) = NULL;
			DECLARE @Validation_ID INT = NULL;
			DECLARE @StartTime AS DATETIME = GETUTCDATE();
			DECLARE @RunTime AS DECIMAL(18, 4) = 0;
			DECLARE @Update_IDOut int;
			DECLARE @error AS INT = 0;
			DECLARE @rowcount AS INT = 0;
			DECLARE @return_value AS INT;
			DECLARE @RC INT;
			DECLARE @Update_ID INT;
			DECLARE @ProcedureName sysname = 'spmfSynchronizeLookupColumnChange';
			DECLARE @ProcedureStep sysname = 'Start';
			
			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			----------------------------------------------------------------------
			--GET Vault LOGIN CREDENTIALS
			----------------------------------------------------------------------

			 --IF @TableName IS NOT NULL
			 --Begin
			 --  Update MFClass set IncludeInApp=1 where TableName=@TableName
			 --End

			DECLARE @Username NVARCHAR(2000);
			DECLARE @VaultName NVARCHAR(2000);

			SELECT TOP 1
			 @Username  = [MFVaultSettings].[Username],
			 @VaultName = [MFVaultSettings].[VaultName]
			FROM
			 [dbo].[MFVaultSettings];



			INSERT INTO [dbo].[MFUpdateHistory]
			(
			 [Username],
			 [VaultName],
			 [UpdateMethod]
			)
			VALUES
			(
			 @Username, @VaultName, -1
			);

			SELECT
			@Update_ID = @@IDENTITY;

			SELECT
			@Update_IDOut = @Update_ID;

			SET @ProcessType = @ProcedureName;
			SET @LogText = @ProcedureName + ' Started ';
			SET @LogStatus = 'Initiate';
			SET @StartTime = GETUTCDATE();
			set @ProcessBatch_ID=0
			EXECUTE @RC = [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_id OUTPUT,
			@ProcessType = @ProcessType,
			@LogType = @LogType,
			@LogText = @LogText,
			@LogStatus = @LogStatus,
			@debug = @Debug;


			 SET @ProcedureStep = 'GeT ValueListItems along with where IsNameUpdate=1 ';

            

		Create table #WorkflowStateNameChange
				(
				   ID int identity(1,1),
				   WorkflowID int,
				   WorkflowMFID int,
				   WorkflowStateMFID int,
				   Name Nvarchar(200)

				)

				insert into #WorkflowStateNameChange 
				select  
					 WF.ID,
					 WF.MFID,
					 WS.MFID,
					 WS.Name 
				from 
					 MFWorkflowState WS inner join 
					 MFWorkflow WF 
				on 
					 WS.MFWorkflowID=WF.ID 
				where 
					 WS.IsNameUpdate=1

			 IF @Debug > 0
                BEGIN
                    PRINT @ProcedureStep;
					select * from #WorkflowStateNameChange
                END
				  
			

			 DECLARE 
			  @NameChangeCounter INT=1
		     ,@MaxRows int
		     ,@WFID INT
		     ,@WFMFID INT
		     ,@WSMFID INT
			 ,@Name NVARCHAR(200)
		

			Select @MaxRows=MAX(ID) from #WorkflowStateNameChange 

				   
			EXECUTE @return_value = [dbo].[spMFProcessBatchDetail_Insert]
			        @ProcessBatch_ID = @ProcessBatch_id,
					@LogType = @LogTypeDetail,
					@LogText = @LogTextDetail,
					@LogStatus = @LogStatusDetail,
					@StartTime = @StartTime,
					@MFTableName = @TableName,
					@Validation_ID = @Validation_ID,
					@ColumnName = @LogColumnName,
					@ColumnValue = @LogColumnValue,
					@Update_ID = @Update_ID,
					@LogProcedureName = @ProcedureName,
					@LogProcedureStep = @ProcedureStep,
					@debug = @Debug;


			While @NameChangeCounter <= @MaxRows
				Begin
					Select 
					@WFID=WorkflowID
					,@WFMFID=WorkflowMFID
					,@WSMFID=WorkflowStateMFID
					,@Name=Name 
					from 
					#WorkflowStateNameChange 
					where 
					ID=@NameChangeCounter

					Create Table #tables
					(
					TBLID int identity (1,1),
					TBLName Nvarchar(250)
					)
					Insert into #tables Select TableName from MFClass where MFWorkflow_ID=@WFID
					Select * from #tables
		 
		

					DECLARE @TblCounter INT=1
					,@TblMaxRow INT
					,@TblName Nvarchar(250)
		 
					SELECT @TblMaxRow=max(TBLID) from #tables

					While @TblCounter <= @TblMaxRow
					Begin
			   
					Select @TblName=TBLName from #tables where TBLID=@TblCounter
				 
					print @TblName

					IF Exists( Select top 1 * from INFORMATION_SCHEMA.TABLES where TABLE_NAME=@TblName)
					Begin
					   
					DECLARE @Sql NVARCHAR(MAX)
					SET @Sql ='Update '+ @TblName + ' SET ' + SUBSTRING('Workflow_State_ID',1,LEN('Workflow_State_ID')-3) + '='''+@Name+ ''' where '+ @TblName+'.Workflow_State_ID='+cast(@WSMFID as VARCHAR(20))

					print @Sql

					exec (@Sql)

					End
					SET @TblCounter=@TblCounter+1
               
				 drop table #tables

		   Update MFWorkflowState set IsNameUpdate=0 where MFID=@WSMFID

		   SET @NameChangeCounter= @NameChangeCounter+1
   End

				
			End
			
		 
		 

			
			drop table #WorkflowStateNameChange
	End Try
	BEGIN CATCH
			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
			, [ErrorNumber]
			, [ErrorMessage]
			, [ErrorProcedure]
			, [ErrorState]
			, [ErrorSeverity]
			, [ErrorLine]
			, [ProcedureStep]
			)
			VALUES (
			@ProcedureName
			, ERROR_NUMBER()
			, ERROR_MESSAGE()
			, ERROR_PROCEDURE()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, @ProcedureStep
			);

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			, @ProcessType = @ProcessType
			, @LogType = N'Error'
			, @LogText = @LogTextDetail
			, @LogStatus = @LogStatus
			, @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
			@ProcessBatch_ID = @ProcessBatch_ID
			, @LogType = N'Error'
			, @LogText = @LogTextDetail
			, @LogStatus = @LogStatus
			, @StartTime = @StartTime
			, @MFTableName = @TableName
			, @Validation_ID = @Validation_ID
			, @ColumnName = NULL
			, @ColumnValue = NULL
			, @Update_ID = @Update_ID
			, @LogProcedureName = @ProcedureName
			, @LogProcedureStep = @ProcedureStep
			, @debug = 0

			RETURN -1
	END CATCH
End


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.Custom.[DoUpdateReportingData]';
GO
-----------------------------------------------------------------------------------------------*/
IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'DoUpdateReportingData' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'Custom'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE Custom.[DoUpdateReportingData]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE Custom.[DoUpdateReportingData]
	(	@ID INT
	,@Output NVARCHAR(400) OUTPUT
	,	@ProcessBatch_ID INT	  = NULL OUTPUT
	  , @Debug			 SMALLINT = 0
	)
AS
	BEGIN
		SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = ''
		DECLARE @ProcessType AS NVARCHAR(50);

		SET @ProcessType = ISNULL(@ProcessType, 'Update Reporting data')

		-------------------------------------------------------------
		-- CONSTATNS: MFSQL Global 
		-------------------------------------------------------------
		DECLARE @UpdateMethod_1_MFilesToMFSQL TINYINT = 1
		DECLARE @UpdateMethod_0_MFSQLToMFiles TINYINT = 0
		DECLARE @Process_ID_1_Update TINYINT = 1
		DECLARE @Process_ID_6_ObjIDs TINYINT = 6 --marks records for refresh from M-Files by objID vs. in bulk
		DECLARE @Process_ID_9_BatchUpdate TINYINT = 9 --marks records previously set as 1 to 9 and update in batches of 250
		DECLARE @Process_ID_Delete_ObjIDs INT = -1 --marks records for deletion
		DECLARE @Process_ID_2_SyncError TINYINT = 2
		DECLARE @ProcessBatchSize INT = 250

		-------------------------------------------------------------
		-- VARIABLES: MFSQL Processing
		-------------------------------------------------------------
		DECLARE @Update_ID INT
		DECLARE @Update_IDOut INT
		DECLARE @MFLastModified DATETIME
		DECLARE @MFLastUpdateDate Datetime
		DECLARE @Validation_ID int
	
		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'Custom.DoUpdateReportingData';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

		-------------------------------------------------------------
		-- VARIABLES: LOGGING
		-------------------------------------------------------------
		DECLARE @LogType AS NVARCHAR(50) = 'Status'
		DECLARE @LogText AS NVARCHAR(4000) = '';
		DECLARE @LogStatus AS NVARCHAR(50) = 'Started'

		DECLARE @LogTypeDetail AS NVARCHAR(50) = 'System'
		DECLARE @LogTextDetail AS NVARCHAR(4000) = '';
		DECLARE @LogStatusDetail AS NVARCHAR(50) = 'In Progress'
		DECLARE @ProcessBatchDetail_IDOUT AS INT = NULL

		DECLARE @LogColumnName AS NVARCHAR(128) = NULL
		DECLARE @LogColumnValue AS NVARCHAR(256) = NULL

		DECLARE @count INT = 0;
		DECLARE @Now AS DATETIME = GETDATE();
		DECLARE @StartTime AS DATETIME = GETUTCDATE();
		DECLARE @StartTime_Total AS DATETIME = GETUTCDATE();
		DECLARE @RunTime_Total AS DECIMAL(18, 4) = 0;

		-------------------------------------------------------------
		-- VARIABLES: DYNAMIC SQL
		-------------------------------------------------------------
		DECLARE @sql NVARCHAR(MAX) = N''
		DECLARE @sqlParam NVARCHAR(MAX) = N''


		-------------------------------------------------------------
		-- INTIALIZE PROCESS BATCH
		-------------------------------------------------------------
		SET @ProcedureStep = 'Start Logging'

		SET @LogText = 'Processing ' + @ProcedureName

		EXEC [dbo].[spMFProcessBatch_Upsert]
			@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
		  , @ProcessType = @ProcessType
		  , @LogType = N'Status'
		  , @LogText = @LogText
		  , @LogStatus = N'In Progress'
		  , @debug = @Debug


		EXEC [dbo].[spMFProcessBatchDetail_Insert]
			@ProcessBatch_ID = @ProcessBatch_ID
		  , @LogType = N'Debug'
		  , @LogText = @ProcessType
		  , @LogStatus = N'Started'
		  , @StartTime = @StartTime
		  , @MFTableName = @MFTableName
		  , @Validation_ID = @Validation_ID
		  , @ColumnName = NULL
		  , @ColumnValue = NULL
		  , @Update_ID = @Update_ID
		  , @LogProcedureName = @ProcedureName
		  , @LogProcedureStep = @ProcedureStep
		, @ProcessBatchDetail_ID = @ProcessBatchDetail_IDOUT 
		  , @debug = 0


		BEGIN TRY
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Update all tables'
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END


				
				EXEC @return_value = [dbo].[spMFUpdateAllncludedInAppTables] @UpdateMethod = @UpdateMethod_1_MFilesToMFSQL  -- int
				                                                            ,@RemoveDeleted = 1 -- int
				                                                            ,@ProcessBatch_ID = @ProcessBatch_ID              -- int
				                                                            ,@Debug = 0         -- smallint
				
			-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'
			Set @LogStatus = 'Completed'

			-------------------------------------------------------------
			-- Log End of Process
			-------------------------------------------------------------   

			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @ProcessType = @ProcessType
			  , @LogType = N'Message'
			  , @LogText = @LogText
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Message'
			  , @LogText = @ProcessType
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN 1
		END TRY
		BEGIN CATCH
			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );

			SET @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			EXEC [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID OUTPUT
			  , @ProcessType = @ProcessType
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			SET @StartTime = GETUTCDATE()

			EXEC [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = NULL
			  , @ColumnValue = NULL
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			RETURN -1
		END CATCH

	END

GO

GO


/*Update settings script
*/

DECLARE @RC int
DECLARE @Username nvarchar(100) = N'{varMFUsername}'
--DECLARE @Password nvarchar(100) = N'{varMFPassword}'
DECLARE @NetworkAddress nvarchar(100) = N'{varNetworkAddress}'
DECLARE @Vaultname nvarchar(100) = N'{varVaultName}' 
DECLARE @MFProtocolType nvarchar(100) = '{varProtocolType}'
DECLARE @Endpoint nvarchar(100) = '{varEndPoint}'
DECLARE @MFAuthenticationType nvarchar(100) = '{varAuthenticationType}'
DECLARE @Domain nvarchar(128) =  N'{varMFDomain}'
DECLARE @VaultGUID nvarchar(1000) = N'{varGUID}'
DECLARE @ServerURL nvarchar(500) = N'{varWebURL}'
--DECLARE  @RootFolder nvarchar(128) = N'{varExportFolder}'
--DECLARE  @FileTransferLocation nvarchar(128) = N'{varImportFolder}'
--DECLARE @DetailLogging nvarchar(128) = '{varLoggingRequired}'
--DECLARE @MFInstallationPath  nvarchar(128) = N'{varMFInstallPath}'       
--DECLARE @MFilesVersion nvarchar(128) = N'{varMFVersion}'           
--DECLARE  @AssemblyInstallationPath nvarchar(128) = N'{varCLRPath}' 
--DECLARE   @SQLConnectorLogin nvarchar(128) = N'{varAppLogin_Name}'      
--DECLARE  @UserRole nvarchar(128) = N'{varAppDBRole}'              
--DECLARE  @SupportEmailAccount nvarchar(128) = N'{varITSupportEmail}'      
--DECLARE  @EmailProfile nvarchar(128) = N'{varEmailProfile}'

DECLARE @MFProtocolType_ID int 
DECLARE @MFAuthenticationType_ID int
DECLARE @Debug smallint = 0
DECLARE @EndPointInt INT

	 

SET @EndPointInt = cast(@Endpoint AS int)
--SET @MFProtocolType_ID = CAST(@MFProtocolType AS INT)
--SET @MFAuthenticationType_ID = CAST(@MFAuthenticationType AS INT)
Select  @MFProtocolType_ID = id from MFProtocolType mpt where mpt.ProtocolType =  @MFProtocolType
Select  @MFAuthenticationType_ID = id from MFAuthenticationType mat where mat.AuthenticationType = @mfauthenticationType



-------------------------------------------------------------
-- prevent ad hoc running of this procedure to over write existing settings that is not controlled by the installation package
-------------------------------------------------------------




-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] 
   @Username = @username
 --,  @password = @Password
 , @NetworkAddress = @NetworkAddress
  ,@Vaultname = @Vaultname
  ,@MFProtocolType_ID = @MFProtocolType_ID
  ,@Endpoint = @EndPointInt
  ,@MFAuthenticationType_ID = @MFAuthenticationType_ID
  ,@Domain = @Domain
  ,@VaultGUID = @VaultGUID
  ,@ServerURL = @ServerURL
 
/*IF EXISTS(SELECT * FROM sys.objects AS o WHERE o.name = 'spMFDecrypt')
BEGIN
EXECUTE @RC = [dbo].[spMFSettingsForVaultUpdate] 
  @Password = @password
END
*/

 --EXEC dbo.spMFSettingsForDBUpdate @MFInstallationPath = @MFInstallationPath,       
 --                                 @MFilesVersion = @MFilesVersion ,            
 --                                 @AssemblyInstallationPath = @AssemblyInstallationPath,
 --                                 @SQLConnectorLogin = @SQLConnectorLogin,      
 --                                 @UserRole = @UserRole,               
 --                                 @SupportEmailAccount = @SupportEmailAccount,   
 --                                 @EmailProfile = @EmailProfile,           
 --                                 @DetailLogging = @DetailLogging,         
 --                                 @RootFolder = @RootFolder,              
 --                                 @FileTransferLocation = @FileTransferLocation,     
 --                                 @Debug = 0                      


GO



/*
Script to update / set MFSettings 

MODIFIED
2917-6-15	AC	Add script to set default CSS for mail
2017-7-16	LC	Add script to update profile security
2018-9-27	LC	Update logic for mail profile and fix bug with incorrect variable
2019-1-26	LC	Prevent default profile to be created if profile already exists
*/

SET NOCOUNT ON 
DECLARE @msg AS VARCHAR(250);
    DECLARE @EDIT_MAILPROFILE_PROP NVARCHAR(100) 

SET @msg = SPACE(5) + DB_NAME() + ': Update Profile';
RAISERROR('%s', 10, 1, @msg);

-- update mail profile security to include App User to allow for email to be sent using Context Menu

--SELECT * FROM [dbo].[MFSettings] AS [ms]
DECLARE @DBUser VARCHAR(100),
        @profile VARCHAR(100),
        @IsDefault BIT;
SELECT @DBUser = CAST(Value AS VARCHAR(100))
FROM dbo.MFSettings
WHERE Name = 'AppUser';

SELECT @EDIT_MAILPROFILE_PROP = CAST(Value AS VARCHAR(100))
FROM dbo.MFSettings
WHERE Name = 'SupportEMailProfile';

/*
Create mail profile - only when existing profile does not match settings
*/


IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysmail_account a) 
BEGIN
  
  DECLARE @Profiles AS TABLE (profiles NVARCHAR(100))

   INSERT INTO @Profiles
   (
       profiles
  
       )
        SELECT p.name
        FROM msdb.dbo.sysmail_account a
            INNER JOIN msdb.dbo.sysmail_profileaccount pa
                ON a.account_id = pa.account_id
            INNER JOIN msdb.dbo.sysmail_profile p
                ON pa.profile_id = p.profile_id
	
	IF (SELECT COUNT(*) FROM @Profiles AS p2 WHERE p2.profiles= '{varEmailProfile}') = 0
	
    BEGIN

        -- Create a Database Mail profile
        EXECUTE msdb.dbo.sysmail_add_profile_sp @profile_name = '{varEmailProfile}',
                                                @description = 'Profile for MFSQLConnector.';
	
    END;

END;



SELECT @IsDefault = sp.is_default
FROM msdb.dbo.sysmail_principalprofile AS sp
    LEFT JOIN msdb.sys.database_principals AS dp
        ON sp.principal_sid = dp.sid
WHERE dp.name = @DBUser;


IF @IsDefault = 0
BEGIN
    EXECUTE msdb.dbo.sysmail_add_principalprofile_sp @principal_name = @DBUser,
                                                     @profile_name = @profile,
                                                     @is_default = 1;
END;

/*

Set Default Email CSS 
*/

SET NOCOUNT ON;

--DELETE [dbo].[MFSettings] WHERE name = 'DefaultEMailCSS'
DECLARE @DBName AS NVARCHAR(100),
        @EmailStyle AS VARCHAR(8000);

SELECT @DBName = CAST(Value AS VARCHAR(100))
FROM dbo.MFSettings
WHERE Name = 'App_Database';

IF DB_NAME() = @DBName
BEGIN
    SET @msg = SPACE(5) + DB_NAME() + ': MFSettings - Set Email Styling ';
    RAISERROR('%s', 10, 1, @msg);

    BEGIN
        SET NOCOUNT ON;

        SET @EmailStyle
            = N'
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<style type="text/css">
		div {line-height: 100%;}  
		body {-webkit-text-size-adjust:none;-ms-text-size-adjust:none;margin:0;padding:0;} 
		body, #body_style {min-height:1000px;font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;}
		p {margin:0; padding:0; margin-bottom:0;}
		h1, h2, h3, h4, h5, h6 {color: black;line-height: 100%;}  
		table {		   border-collapse: collapse;
  						border: 1px solid #3399FF;
  						font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
  						color: black;
						padding:5;
						border-spacing:1;
						border:0;
					}
		table caption {font-weight: bold;color: blue;}
		table td, table th, table tr,table caption { border: 1px solid #eaeaea;border-collapse:collapse;vertical-align: top; }
		table th {font-weight: bold;font-variant: small-caps;background-color: blue;color: white;vertical-align: bottom;}
	</style>
</head>';


        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.MFSettings
            WHERE source_key = 'Email'
                  AND Name = 'DefaultEMailCSS'
        )
            INSERT dbo.MFSettings
            (
                source_key,
                Name,
                Description,
                Value,
                Enabled
            )
            VALUES
            (   N'Email',                                  -- source_key - nvarchar(20)
                'DefaultEMailCSS',                         -- Name - varchar(50)
                'CSS Style sheet used in email messaging', -- Description - varchar(500)
                @EmailStyle,                               -- Value - sql_variant
                1                                          -- Enabled - bit
                );


        SET NOCOUNT OFF;
    END;



END;

ELSE
BEGIN
    SET @msg = SPACE(5) + DB_NAME() + ': 30.902 script error';
    RAISERROR('%s', 10, 1, @msg);
END;

GO
/*

script to set the module assignments in setup.MFSQLObjectControl
this script is executed as part of the installation procedure
new modules must be added by hand into this script to be licensed

*/
GO

SET NOCOUNT ON


	   PRINT SPACE(10) + '... MFSQLObjectsControl Initialised';

              TRUNCATE TABLE Setup.[MFSQLObjectsControl];

                INSERT  INTO Setup.[MFSQLObjectsControl]
                        ( [Schema] ,
                          [Name] ,
                          [object_id] ,
                          [Type] ,
                          [Modify_Date]
                        )
                        
                       
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'MF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'spMF%'
--UNION ALL
--SELECT s.[name],objects.Name, [objects].[object_id], type, [objects].[modify_date] FROM sys.objects
--INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id] WHERE [objects].[name] like 'tMF%'
                        UNION ALL
                        SELECT  s.[name] ,
                                objects.name ,
                                [objects].[object_id] ,
                                type ,
                                [objects].[modify_date]
                        FROM    sys.objects
                                INNER JOIN sys.[schemas] AS [s] ON [s].[schema_id] = [objects].[schema_id]
                        WHERE   [objects].[name] LIKE 'fnMF%';



DECLARE @ProcRelease VARCHAR(100) = '2.0.2.7'
IF NOT EXISTS ( SELECT  Name
                FROM    Setup.[MFSQLObjectsControl]
                WHERE   [Schema] = 'setup'
                        AND Name = 'MFSQLObjectsControl' )
    BEGIN
        INSERT  INTO Setup.[MFSQLObjectsControl]
                ( [Schema] ,
                  [Name] ,
                  [object_id] ,
                  [Release] ,
                  [Type] ,
                  [Modify_Date]
                )
        VALUES  ( 'setup' , -- Schema - varchar(100)
                  'spMFSQLObjectsControl' , -- Name - varchar(100)
                  0 , -- object_id - int
                   @ProcRelease, -- Release - varchar(50)
                  'P' , -- Type - varchar(10)
                  GETDATE()  -- Modify_Date - datetime
                );
    END;
ELSE
    BEGIN
        UPDATE  moc
        SET      
                [moc].[Release] = @ProcRelease,
				moc.[Modify_Date] = GETDATE()
     
	    FROM    Setup.[MFSQLObjectsControl] AS [moc] WHERE [moc].[Schema] = N'setup' and
                [moc].[Name] = N'MFSQLObjectsControl' ;
    END;




---------------   #tmp_GridResults_1   ---------------
SELECT * INTO #tmp_GridResults_1
FROM (
SELECT N'spMFCreateObjectInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFCreatePublicSharedLinkInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFDecrypt' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFDeleteObjectInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFEncrypt' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetClass' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetDataExportInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetFilesInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFGetHistoryInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFGetLoginAccounts' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetMFilesLogInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spmfGetMFilesVersionInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetObjectType' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetObjectVersInternal' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetProperty' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetUserAccounts' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetValueList' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetValueListItems' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetWorkFlow' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetWorkFlowState' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFSearchForObjectByPropertyValuesInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFSearchForObjectInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFSynchronizeFileToMFilesInternal' AS [name], N'3' AS [Module] UNION ALL
SELECT N'spMFSynchronizeValueListItemsToMFilesInternal' AS [name], N'2' AS [Module] UNION ALL
SELECT N'spMFUpdateClass' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateObjectType' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateProperty' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdatevalueList' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFUpdateWorkFlow' AS [name], N'1' AS [Module] UNION ALL
SELECT N'spMFGetUnManagedObjectDetails' AS [name], N'3' AS [Module] UNION ALL

SELECT N'spMFUpdateWorkFlowState' AS [name], N'1' AS [Module] ) t;
--SELECT [name], [Module]
--FROM #tmp_GridResults_1

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS AS c WHERE c.COLUMN_NAME = 'Module' AND c.TABLE_NAME = 'MFSQLObjectsControl')
Begin
ALTER TABLE setup.MFSQLObjectsControl
ADD Module INT DEFAULT((0))
END

UPDATE moc
SET module = tgr.Module
FROM setup.MFSQLObjectsControl AS moc
INNER JOIN #tmp_GridResults_1 AS tgr
ON tgr.name = moc.Name

DROP TABLE #tmp_GridResults_1
GO

SET NOCOUNT ON;
	
DECLARE @rc INT ,
    @msg AS VARCHAR(250) ,
    @DBName VARCHAR(100),
	@ConnectorVersion varchar(50);

SELECT  @DBName = CAST(Value AS VARCHAR(100))
FROM    MFSettings
WHERE   Name = 'App_Database';



SELECT @ConnectorVersion = MAX(Release) FROM setup.[MFSQLObjectsControl] AS [mco]



    BEGIN
        SET @msg = SPACE(5) + DB_NAME() + ': Update Version log';
        RAISERROR('%s',10,1,@msg); 

        BEGIN
            SET NOCOUNT ON;

            DECLARE @MFVersion VARCHAR(50);
            SELECT  @MFVersion = CAST(Value AS VARCHAR(50))
            FROM    dbo.MFSettings
            WHERE   Name = 'MFVersion';

                  
            INSERT  INTO MFDeploymentDetail
                    ( LSWrapperVersion ,
                      MFilesAPIVersion ,
                      DeployedBy ,
                      DeployedOn
				    )
            VALUES  ( CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                            'VersionMajor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                              'VersionMinor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                              'VersionBuild') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                              'VersionRevision') AS NVARCHAR(3))

			+ ' / MFSQL Connector ' + @ConnectorVersion  ,
                      CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                            'VersionMajor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                              'VersionMinor') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                              'VersionBuild') AS NVARCHAR(3))
                      + '.'
                      + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI',
                                              'VersionRevision') AS NVARCHAR(3))
                      + ' :' + @MFVersion ,
                      SYSTEM_USER ,
                      GETDATE()
                    );

            PRINT 'Deployed version details :' + CHAR(13)
                + 'Assembly Name : LSConnectMFilesAPIWrapper  Version :'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionMajor') AS NVARCHAR(3)) + '.'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionMinor') AS NVARCHAR(3)) + '.'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionBuild') AS NVARCHAR(3)) + '.'
                + CAST(ASSEMBLYPROPERTY('LSConnectMFilesAPIWrapper',
                                        'VersionRevision') AS NVARCHAR(3))
										+ ' / ' + 'MFSQLConnector ' + @ConnectorVersion + 
                + CHAR(13) + 'Assembly Name : Interop.MFilesAPI  Version :'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionMajor') AS NVARCHAR(3))
                + '.'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionMinor') AS NVARCHAR(3))
                + '.'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionBuild') AS NVARCHAR(3))
                + '.'
                + CAST(ASSEMBLYPROPERTY('Interop.MFilesAPI', 'VersionRevision') AS NVARCHAR(3))
                + ' :' + @MFVersion + CHAR(13) + 'Deployed by "' + SYSTEM_USER
                + '" On ' + CAST(GETDATE() AS NVARCHAR(50));
                                  
                          

            SET NOCOUNT OFF;
        END;



    END;


GO

