PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertUserAccount]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertUserAccount', -- nvarchar(100)
    @Object_Release = '4.11.33.77', -- varchar(50)
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
AS
/*rST**************************************************************************

=====================
spMFInsertUserAccount
=====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Doc nvarchar(max)
    listing of user accounts
  @isFullUpdate bit
    always 1
  @Output int (output)
    update result
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
   

Purpose
=======

The purpose of this procedure is to insert user account details into MFUserAccount table.


Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-10-12  LC         Update to insert or update changes and set deleted flag for deleted items
2023-05-24  LC         Add vault roles
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

            -------------------------------------------------------------
            -- Vault roles
            -------------------------------------------------------------
            if (Select object_id('..mfVaultRoles')) is not null
drop table MFVaultRoles;

create table MFVaultRoles (Role nvarchar(100), Enumerator int, Description nvarchar(100));

insert into MFVaultRoles

Values
('MFUserAccountVaultRoleAnonymousUser',65536,'Anonymous user.'),
('MFUserAccountVaultRoleCannotManagePrivateViews',32768,'Cannot manage private views and notification rules.'),
('MFUserAccountVaultRoleChangeMetadataStructure',256,'Change metadata structure.'),
('MFUserAccountVaultRoleChangeObjectSecurity',128,'Change permissions for all objects.'),
('MFUserAccountVaultRoleCreateObjects',4,'Can create documents or other objects.'),
('MFUserAccountVaultRoleDefaultRoles',3078,'The default vault roles for a normal user.'),
('MFUserAccountVaultRoleDefineTemplates',4096,'Manage templates (obsolete).'),
('MFUserAccountVaultRoleDestroyObjects',32,'Destroy objects.'),
('MFUserAccountVaultRoleForceUndoCheckout',64,'Force undo checkout.'),
('MFUserAccountVaultRoleFullControl',1,'Full control of vault.'),
('MFUserAccountVaultRoleInternalUser',1024,'Internal user (as opposed to external user).'),
('MFUserAccountVaultRoleLogIn',2,'Can log into the vault.'),
('MFUserAccountVaultRoleManageCommonViews',8192,'Manage common views and notification rules.'),
('MFUserAccountVaultRoleManageTraditionalFolders',2048,'Can create and modify traditional folders.'),
('MFUserAccountVaultRoleManageUserAccounts',512,'Manage user accounts.'),
('MFUserAccountVaultRoleManageWorkflows',16384,'Manage workflows.'),
('MFUserAccountVaultRoleNone',0,'None.'),
('MFUserAccountVaultRoleSeeAllObjects',8,'See and read all vault content (including deleted objects).'),
('MFUserAccountVaultRoleUndeleteObjects',16,'See and undelete deleted objects.')
;

          -----------------------------------------------
          --LOCAL VARIABLE DECLARATION
          -----------------------------------------------
            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'Start' ,
                @XML XML = @Doc;

            SET @ProcedureStep = 'Creating #UserAccountTble';
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertUserAccount';

            IF @Debug > 0
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

            CREATE TABLE #UserAccountTble
                (
                  [LoginName] VARCHAR(100) ,
                  [UserID] INT NOT NULL ,
                  [InternalUser] BIT ,
                  [Enabled] BIT,
                  VaultRoles varchar(100),
				  Status nvarchar(100)
                    
                );

            SET @ProcedureStep = 'Insert values into #UserAccountTble';

          -----------------------------------------------
          -- INSERT DAT FROM XML INTO TEMPORARY TABLE
          -----------------------------------------------
            INSERT  INTO #UserAccountTble
                    ( LoginName ,
                      UserID ,
                      InternalUser ,
                      [Enabled],
                      VaultRoles,
					  Status
                    )
                    SELECT  t.c.value('(@LoginName)[1]', 'NVARCHAR(100)') AS LoginName ,
                            t.c.value('(@MFID)[1]', 'INT') AS UserID ,
                            t.c.value('(@InternalUser)[1]', 'BIT') AS InternalUser ,
                            t.c.value('(@Enabled)[1]', 'BIT') AS [Enabled],
                             t.c.value('(@VaultRoles)[1]', 'NVARCHAR(100)') AS [VaultRoles],
							 case when ua.userid is null then 'New' Else 'Updated' end
                    FROM    @XML.nodes('/form/UserAccount') AS t ( c )
					left join MFUserAccount ua
					on ua.userid = t.c.value('(@MFID)[1]', 'INT');

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                    SELECT  *
                    FROM    #UserAccountTble;
                END;

-------------------------------------------------------------
-- Update Vault roles
-------------------------------------------------------------
update uat
set uat.VaultRoles = case when isnumeric(vaultRoles) = 1 and cast(vaultroles as int) % 2 = 1 then 'Full control'
when isnumeric(vaultRoles) = 1 and cast(vaultroles as int) % 2 = 0 then 'Several Other Roles'
else VaultRoles
end
from #UserAccountTble as uat


            SET @ProcedureStep = 'Insert deleted items into #UserAccountTble';

-------------------------------------------------------------
-- Validate MFuser account table
-------------------------------------------------------------

if not exists(select 1 from INFORMATION_SCHEMA.COLUMNS as c where c.TABLE_NAME = 'MFUserAccount' and c.COLUMN_NAME = 'Vaultroles')
alter table MFuserAccount
add VaultRoles nvarchar(100);

          
            
            insert INTO    #UserAccountTble
			( LoginName ,
                      UserID ,
                      InternalUser ,
                      [Enabled],
                      VaultRoles,
					  Status
                    )
             SELECT    ua.LoginName ,
                                ua.UserID ,
                                ua.InternalUser ,
                                ua.[Enabled],
                                ua.VaultRoles,
								'Deleted'
                      FROM      MFUserAccount ua
                      left join #UserAccountTble temp
					  on ua.UserID = temp.UserID
					  where temp.UserID is null

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                END;

          --  SET @ProcedureStep = 'Creating new table #NewUserAccount';

          --------------------------------------------------------------
          ----Creating new table to store the updated ObjectType details 
          --------------------------------------------------------------
          --  CREATE TABLE #NewUserAccount
          --      (
          --        [LoginName] VARCHAR(100) ,
          --        [UserID] INT NOT NULL ,
          --        [InternalUser] BIT ,
          --        [Enabled] bit,
          --        VaultRoles nvarchar(100)
          --      );

          --  SET @ProcedureStep = 'Inserting values into #NewUserAccount';

          -------------------------------------------------
          ----Inserting the Difference 
          -------------------------------------------------
          --  INSERT  INTO #NewUserAccount
          --          SELECT  *
          --          FROM    #UserAccount;

          --  IF @Debug > 0
          --      BEGIN
          --          RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          --          --SELECT  *
          --          --FROM    #NewUserAccount;
          --      END;

		              SELECT  @ProcedureStep = 'Set status in temp';

          -----------------------------------------------------------------------
          --Updating status in #UserAccountTble
          -----------------------------------------------------------------------
            Update  temp
			set Status = case when ua.userID is null then  'New'
			when ( ua.LoginName <> temp.LoginName or
                                ua.InternalUser <> temp.InternalUser or
                                ua.[Enabled] <> temp.[Enabled] or
                                ua.VaultRoles <> temp.VaultRoles) 
					   and ua.userID = temp.UserID then 'Changed'	
			when  ua.LoginName = temp.LoginName and
                                ua.InternalUser = temp.InternalUser and
                                ua.[Enabled] = temp.[Enabled] and
                                ua.VaultRoles = temp.VaultRoles and
					    ua.userID = temp.UserID and
						isnull(temp.status,'No Status') not in ('Deleted','Changed','New','No Status')
						then 'Unchanged'					
			else temp.Status end
            FROM  #UserAccountTble temp 
			full outer join mfUserAccount ua
			on ua.userID = temp.UserID		
			

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                    SELECT  *
                      FROM  #UserAccountTble temp 
			full outer join  mfUserAccount lia
			on lia.UserID = temp.UserID;
                END;



            SET @ProcedureStep = 'Inserting values into MFUserAccount';

          -----------------------------------------------
          --Updating the MFUserAccount 
          -----------------------------------------------
            IF OBJECT_ID('tempdb..#NewUserAccount') IS NOT NULL
                BEGIN
                    UPDATE  ua
                    SET     ua.LoginName = temp.LoginName ,
                            ua.UserID = temp.UserID ,
                            ua.InternalUser = temp.InternalUser ,
                            ua.[Enabled] = temp.[Enabled],
                            ua.[VaultRoles] = temp.[vaultRoles],
							ua.Deleted = case when temp.status = 'Deleted' then 1 else 0 end
                    FROM    MFUserAccount ua
                             INNER JOIN #UserAccountTble temp ON ua.userid  = temp.UserID
							where temp.status in ('Changed','Deleted');

                    SET @Output = @@ROWCOUNT;
                END;

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    MFUserAccount;
                END;

            SET @ProcedureStep = 'Inserting values into #temp';

          -----------------------------------------------
          --Insert new users	
          -----------------------------------------------
          insert into MFUserAccount
		  (LoginName ,
                                UserID ,
                                InternalUser ,
                                [Enabled],
                                VaultRoles
		  )
           SELECT    LoginName ,
                                UserID ,
                                InternalUser ,
                                [Enabled],
                                VaultRoles
                      FROM      #UserAccountTble temp
					   where temp.status = 'New'

            SET @Output = @Output + @@ROWCOUNT;                      

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    #temp;
                END;

     
            SET @Output = @Output + @@ROWCOUNT;
      
          -----------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------
            DROP TABLE #UserAccountTble;
        
            SET NOCOUNT OFF;

            COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
            ROLLBACK TRANSACTION;

            SET NOCOUNT ON;

            IF @Debug > 0
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
