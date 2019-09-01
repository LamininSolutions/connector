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
