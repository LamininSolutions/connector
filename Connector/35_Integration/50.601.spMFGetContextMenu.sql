
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetContextMenu]';
GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFGetContextMenu', -- nvarchar(100)
    @Object_Release = '4.10.30.75', -- varchar(50)
    @UpdateFlag = 2 -- smallint

GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetContextMenu'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFGetContextMenu]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

alter PROCEDURE [dbo].[spMFGetContextMenu]
AS

BEGIN
 
			select 
				IDENTITY(bigint,1,1) AS ROWID,
				CAST([ID] AS BIGINT) [ID],
				ActionName,
				Action,
				ActionType,
				Message,
				SortOrder,
				ParentID,
				0 as IsHeader,
				0 as ParentSortOrder,
				ISAsync,
				UserGroupID
				into 
				#Temp
			from 
				MFContextMenu 
			where 
				1=2

			insert into  #Temp 
			select 
				ID,
				ActionName,
				Action,
				ActionType,
				Message,
				SortOrder,
				ParentID,
				1,
				SortOrder as ParentSortOrder,
				isnull(ISAsync,0) as ISAsync,
				UserGroupID
			from 
				MFContextMenu 
			where 
            	ParentID=0 and ActionType not in (4,5)
		--		ActionType in (1,2,3,4,5) and Action is not null
			order by 
				SortOrder


			insert into  #Temp 
			select 
				MFCM.ID,
				MFCM.ActionName,
				MFCM.Action,
				MFCM.ActionType,
				MFCM.Message,
				MFCM.SortOrder,
				MFCM.ParentID,
				0,
				T.ParentSortOrder,
				isnull(MFCM.ISAsync,0) as ISAsynch,
				MFCM.UserGroupID
			from 
				MFContextMenu MFCM inner join #Temp T on T.ID=MFCM.parentID


			select 
				ID
				,ActionName
				,Action
				,ActionType
				,Message
				,IsHeader
				, ISAsync
				,isnull(UserGroupID,0) as UserGroupID
			from 
				#Temp 
			order by 
				ParentSortOrder,
				IsHeader desc,
				sortorder
 
			 drop table #Temp


END

GO

