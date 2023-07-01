
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUsersByUsergroup]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFUsersByUsergroup' -- nvarchar(100)
  , @Object_Release = '4.10.32.76'
  , @UpdateFlag = 2

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
----------------------------------------------------------------------------------------------*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFUsersByUsergroup' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFUsersByUsergroup]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFUsersByUsergroup]
	(
	   @Debug			 smallint = 0
	)
as
/*rST**************************************************************************

====================
spMFUsersByUserGroup
====================

Return
  - 1 = Success
  - -1 = Error

  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

To produce a report listing the members of each user group.  The report will include users where the usergroup included another usergroup.

Examples
========

.. code:: sql

    Exec spMFUsersByUserGroup

    select * from ##spMFUsersByUserGroup
    

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------

2023-05-25  LC         Create procedure
==========  =========  ========================================================

**rST*************************************************************************/


begin
		SET NOCOUNT ON;

		-------------------------------------------------------------
		-- CONSTANTS: MFSQL Class Table Specific
		-------------------------------------------------------------
		DECLARE @MFTableName AS NVARCHAR(128) = ''
		DECLARE @ProcessType AS NVARCHAR(50);
        declare @ProcessBatch_id int = null

		SET @ProcessType = ISNULL(@ProcessType, 'User Group Report')

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
	
		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFUsersByUsergroup';
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


		begin try
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = ''
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END


                

declare @vaultsettings nvarchar(400) = dbo.FnMFVaultSettings()
declare @returnVal nvarchar(max);
exec dbo.spMFGetUserGroups @VaultSettings = @vaultsettings
                            , @returnVal = @returnVal output

--select cast(@returnval as xml)

         -----------------------------------------------
          --LOCAL VARIABLE DECLARATION
          -----------------------------------------------
            DECLARE @IDoc INT ,
                @XML XML = @returnVal;

 --           SET @ProcedureStep = 'Creating #UserAccountTble';
  

            --IF @Debug = 1
            --    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

            if (select object_id('tempdb..#UserGroupTble')) is not null
            drop table #UserGroupTble;

            CREATE TABLE #UserGroupTble
                (
                  
                  [Memberid] INT NOT NULL ,
                  [UserGroupID] INT 
                );

 --           SET @ProcedureStep = 'Insert values into #UserGroupTble';

          -----------------------------------------------
          -- INSERT DAT FROM XML INTO TEMPORARY TABLE
          -----------------------------------------------
            INSERT  INTO #UserGroupTble
                    ( MemberID ,
                      UserGroupID 
                      
                    )
                    SELECT  t.c.value('(@MemberID)[1]', 'INT') AS memberID ,
                            t.c.value('(@MFID)[1]', 'INT') AS UserGroupID 
                    FROM    @XML.nodes('/form/UserGroup') AS t ( c );

if (select object_id('tempdb..##spMFUsersByUserGroup')) is not null
drop table ##spMFUsersByUserGroup;

;with cte as
(
select uat.Memberid, uat.UserGroupID, mvli.name as UserGroup, Related_UserGroup = null
from #UserGroupTble as uat
left join MFvaluelistitems mvli
on uat.UserGroupID = mvli.MFID
left join mfValuelist mvl
on mvl.id = mvli.MFValueListID
where mvl.mfid = 16 and uat.memberid > 0
)
, cte2 as
(
select cte.Memberid, uat.UserGroupID, mvli.name as UserGroup, cte.UserGroup as Related_userGroup
from #UserGroupTble as uat
left join MFvaluelistitems mvli
on uat.UserGroupID = mvli.MFID
left join mfValuelist mvl
on mvl.id = mvli.MFValueListID
inner join cte
on cte.UserGroupID = (uat.Memberid * -1)
where mvl.mfid = 16 and uat.memberid < 0
),cte3 as
(select * from cte
union all
select * from cte2
)
select 
cte3.UserGroup
,cte3.userGroupID
,cte3.Related_UserGroup
,mla.mfid as UserID
,mla.UserName
,mla.FullName
,mla.EmailAddress
,mua.internalUser
,mua.Enabled as VaultUser_Enabled
,mla.Enabled as Login_Enabled
,mua.vaultRoles
into ##spMFUsersByUserGroup
from cte3
inner join dbo.MFLoginAccount as mla
on cte3.Memberid = mla.mfid
left join dbo.MFUserAccount as mua
on mla.mfid = mua.UserID



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
			  , @LogType = N'Debug'
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
		end try
		begin catch
			SET @StartTime = GETUTCDATE()
			SET @LogStatus = 'Failed w/SQL Error'
			SET @LogTextDetail = ERROR_MESSAGE()

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			insert into [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			values (
					   @ProcedureName
					 , error_number()
					 , error_message()
					 , error_procedure()
					 , error_state()
					 , error_severity()
					 , error_line()
					 , @ProcedureStep
				   );

			set @ProcedureStep = 'Catch Error'
			-------------------------------------------------------------
			-- Log Error
			-------------------------------------------------------------   
			exec [dbo].[spMFProcessBatch_Upsert]
				@ProcessBatch_ID = @ProcessBatch_ID output
			  , @ProcessType = @ProcessType
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @debug = @Debug

			set @StartTime = getutcdate()

			exec [dbo].[spMFProcessBatchDetail_Insert]
				@ProcessBatch_ID = @ProcessBatch_ID
			  , @LogType = N'Error'
			  , @LogText = @LogTextDetail
			  , @LogStatus = @LogStatus
			  , @StartTime = @StartTime
			  , @MFTableName = @MFTableName
			  , @Validation_ID = @Validation_ID
			  , @ColumnName = null
			  , @ColumnValue = null
			  , @Update_ID = @Update_ID
			  , @LogProcedureName = @ProcedureName
			  , @LogProcedureStep = @ProcedureStep
			  , @debug = 0

			return -1
		end catch

	end

go
