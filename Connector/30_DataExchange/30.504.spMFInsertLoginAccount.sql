PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertLoginAccount]';
go
 

SET NOCOUNT ON; 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertLoginAccount', -- nvarchar(100)
    @Object_Release = '4.11.33.77', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
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
AS
/*rST**************************************************************************

======================
spMFInsertLoginAccount
======================

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

The purpose of this procedure is to insert Login Account details into MFLoginAccount table.

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-10-12  LC         Update to insert or update changes and set deleted flag for deleted items
2019-08-30  JC         Added documentation
2017-08-22  LC         Add insert/update of userID as MFID column
==========  =========  ========================================================

**rST*************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

            DECLARE @IDoc INT ,
                @ProcedureStep NVARCHAR(128) = 'START' ,
                @XML XML = @Doc;
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertLoginAccount';

            IF @Debug > 0
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
				  [UserID] int ,
				  Status nvarchar(100)

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
					  UserID,
					  Status 
                    )
                    SELECT  t.c.value('(@UserName)[1]', 'NVARCHAR(250)') AS UserName ,
                            t.c.value('(@AccountName)[1]', 'NVARCHAR(250)') AS AccountName ,
                            t.c.value('(@FullName)[1]', 'NVARCHAR(250)') AS FullName ,
                            t.c.value('(@AccountType)[1]', 'NVARCHAR(250)') AS AccountType ,
                            t.c.value('(@EmailAddress)[1]', 'NVARCHAR(250)') AS EmailAddress ,
                            t.c.value('(@DomainName)[1]', 'NVARCHAR(250)') AS DomainName ,
                            t.c.value('(@LicenseType)[1]', 'NVARCHAR(250)') AS LicenseType ,
                            t.c.value('(@Enabled)[1]', 'BIT') AS [Enabled],
							t.c.value('(@UserID)[1]', 'int') AS [UserID],
							case when lia.mfid is null then 'New' Else 'Updated' end
                    FROM    @XML.nodes('/form/loginAccount') AS t ( c )
					left join MFLoginAccount lia
					on lia.MFID = t.c.value('(@UserID)[1]', 'int');

INSERT  INTO #LoginAccountTble
                    ( UserName ,
                      AccountName ,
                      FullName ,
                      AccountType ,
                      EmailAddress ,
                      DomainName ,
                      LicenseType ,
                      [Enabled],
					  UserID,
					  Status
                    )
					Select 
					lia.UserName ,
                      lia.AccountName ,
                       lia.FullName ,
                       lia.AccountType ,
                       lia.EmailAddress ,
                       lia.DomainName ,
                       lia.LicenseType ,
                       lia.[Enabled],
					  MFID,
					  'Deleted'
					from mfloginaccount lia
					left join #LoginAccountTble temp
					on lia.mfid = temp.UserID
					where isnull(temp.UserID,0) = 0 

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                    SELECT  *
                    from mfloginaccount lia
					left join #LoginAccountTble temp
					on lia.mfid = temp.UserID
		--			where isnull(temp.UserID,0) = 0 
                END;

         
            SELECT  @ProcedureStep = 'Set status in temp';

          -----------------------------------------------------------------------
          --Updating status in #DifferenceTable 
          -----------------------------------------------------------------------
            Update  temp
			set Status = case when lia.MFID is null then  'New'
			when (lia.UserName <> temp.userName or
                      lia.AccountName <> temp.Accountname or
                       lia.FullName <> temp.Fullname or
                       lia.AccountType <> temp.AccountType or
                       lia.EmailAddress <> temp.EmailAddress or
                       lia.DomainName <> temp.DomainName or 
                       lia.LicenseType <> temp.licenseType or
                       lia.[Enabled] <> temp.Enabled) 
					   and lia.MFID = temp.UserID then 'Changed'	
			when lia.UserName = temp.userName and
                      lia.AccountName = temp.Accountname and
                       lia.FullName = temp.Fullname and
                       lia.AccountType = temp.AccountType and
                       lia.EmailAddress = temp.EmailAddress and
                       lia.DomainName = temp.DomainName and 
                       lia.LicenseType = temp.licenseType and
                       lia.[Enabled] = temp.Enabled and
					    lia.MFID = temp.UserID and
						isnull(temp.status,'No Status') not in ('Deleted','Changed','New','No Status')
						then 'Unchanged'					
			else temp.Status end
            FROM  #LoginAccountTble temp 
			full outer join mfloginAccount lia
			on lia.MFID = temp.UserID		
			

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                    SELECT  *
                      FROM  #LoginAccountTble temp 
			full outer join mfloginAccount lia
			on lia.MFID = temp.UserID;
                END;

  

            SELECT  @ProcedureStep = 'Update MFLoginAccount';

          -----------------------------------------------------------------------
          --Updating the login accounts
          -----------------------------------------------------------------------
            IF OBJECT_ID('tempdb.dbo.#LoginAccountTble') IS NOT NULL
                BEGIN
                    UPDATE  MFLoginAccount
                    SET     MFLoginAccount.FullName = temp.FullName ,
                            MFLoginAccount.AccountName = temp.AccountName ,
                            MFLoginAccount.AccountType = temp.AccountType ,
                            MFLoginAccount.DomainName = temp.DomainName ,
                            MFLoginAccount.EmailAddress = temp.EmailAddress ,
                            MFLoginAccount.LicenseType = temp.LicenseType ,
                            MFLoginAccount.[Enabled] = temp.[Enabled],
							 MFLoginAccount.[MFID] = temp.[UserID],
							 MFLoginAccount.Deleted = case when temp.status = 'Deleted' then 1 else 0 end
                    FROM    MFLoginAccount
                            INNER JOIN #LoginAccountTble temp ON MFLoginAccount.mfid  = temp.UserID
							where temp.status in ('Changed','Deleted');

                    SELECT  @Output = @@ROWCOUNT;
                END;

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    MFLoginAccount;
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
                    SELECT      UserName ,
                                        AccountName ,
                                        FullName ,
                                        AccountType ,
                                        EmailAddress ,
                                        DomainName ,
                                        LicenseType ,
                                        [Enabled] AS Deleted,
										UserID
                              FROM      #LoginAccountTble TEMP
							  where temp.status = 'New'
                          

            SELECT  @Output = @Output + @@ROWCOUNT;

            IF @Debug > 0
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                    --SELECT  *
                    --FROM    MFLoginAccount;
                END;

            --IF ( @isFullUpdate = 1 )
            --    BEGIN
            --        SELECT  @ProcedureStep = 'Full update';

            --    -----------------------------------------------------------------------
            --    -- Select UserName Which are deleted from M-Files 
            --    -----------------------------------------------------------------------
            --        SELECT  UserName
            --        INTO    #DeletedLoginAccount
            --        FROM    ( SELECT    UserName
            --                  FROM      MFLoginAccount
            --                  EXCEPT
            --                  SELECT    UserName
            --                  FROM      #LoginAccountTble
            --                ) DeletedUserName;

            --        IF @Debug = 1
            --            BEGIN
            --                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

            --                --SELECT  *
            --                --FROM    #DeletedLoginAccount;
            --            END;

            --        SELECT  @ProcedureStep = 'DELETE FROM MFLoginAccount';

            --    -----------------------------------------------------------------------
            --    --Deleting the MFClass Thats deleted from M-Files 
            --    -----------------------------------------------------------------------
            --        UPDATE  MFLoginAccount
            --        SET     Deleted = 1
            --        WHERE   UserName COLLATE DATABASE_DEFAULT IN ( SELECT    UserName
            --                              FROM      #DeletedLoginAccount );
            --    END;

          -----------------------------------------
          --Droping all temperory Table 
          ----------------------------------------- 
            DROP TABLE #LoginAccountTble;

            --DROP TABLE #NewLoginAccountTble;

            --DROP TABLE #MFLoginAccount;

            SELECT  @Output = @@ROWCOUNT;

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
