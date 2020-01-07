/*rST**************************************************************************

=====
MFLog
=====

Columns
=======

LogID int (primarykey, not null)
  fixme description
SPName nvarchar(max)
  fixme description
Update\_ID int
  fixme description
ExternalID nvarchar(50)
  fixme description
ErrorNumber int
  fixme description
ErrorMessage nvarchar(max)
  fixme description
ErrorProcedure nvarchar(max)
  fixme description
ProcedureStep nvarchar(max)
  fixme description
ErrorState nvarchar(max)
  fixme description
ErrorSeverity int
  fixme description
ErrorLine int
  fixme description
CreateDate datetime
  fixme description

Indexes
=======

idx\_MFLog\_id
  - LogID

Used By
=======

- MFvwLogTableStats
- spMFAddCommentForObjects
- spMFAliasesUpsert
- spMFChangeClass
- spMFCheckAndUpdateAssemblyVersion
- spMFCreateAllLookups
- spMFCreatePublicSharedLink
- spMFCreateTable
- spMFCreateValueListLookupView
- spMFCreateWorkflowStateLookupView
- spMFDeleteAdhocProperty
- spMFDeleteHistory
- spMFDeleteObjectList
- spMFDeploymentDetails
- spMFDropAndUpdateMetadata
- spMFExportFiles
- spMFGetDeletedObjects
- spMFGetHistory
- spMFGetMetadataStructureVersionID
- spMFGetMfilesLog
- spMFGetObjectvers
- spMFInsertClass
- spMFInsertClassProperty
- spMFInsertLoginAccount
- spMFInsertObjectType
- spMFInsertProperty
- spMFInsertUserAccount
- spMFInsertUserMessage
- spMFInsertValueList
- spMFInsertValueListItems
- spMFInsertWorkflow
- spMFInsertWorkflowState
- spMFLogError\_EMail
- spMFLogProcessSummaryForClassTable
- spMFProcessBatch\_EMail
- spMFProcessBatchDetail\_Insert
- spMFSearchForObject
- spMFSearchForObjectbyPropertyValues
- spMFSynchronizeClasses
- spMFSynchronizeFilesToMFiles
- spmfSynchronizeLookupColumnChange
- spMFSynchronizeMetadata
- spMFSynchronizeProperties
- spMFSynchronizeSpecificMetadata
- spMFSynchronizeUnManagedObject
- spMFSynchronizeValueListItemsToMFiles
- spmfSynchronizeWorkFlowSateColumnChange
- spMFSynchronizeWorkflowsStates
- spMFTableAudit
- spMFUpdateAllncludedInAppTables
- spMFUpdateClassAndProperties
- spMFUpdateItemByItem
- spMFUpdateMFilesToMFSQL
- spMFUpdateTable
- spMFUpdateTableinBatches
- spMFUpdateTableInternal


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-07  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
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


