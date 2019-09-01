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
    fixme description
  @isFullUpdate bit
    fixme description
  @Output int (output)
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
 /*******************************************************************************
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
