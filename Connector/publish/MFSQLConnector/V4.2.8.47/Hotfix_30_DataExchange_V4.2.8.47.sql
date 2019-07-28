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
PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFVaultConnectionTest]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFVaultConnectionTest' -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.47'             -- varchar(50)
                                    ,@UpdateFlag = 2;                         -- smallint
GO

/*

Add license check into connection test

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

ALTER PROC [dbo].[spMFVaultConnectionTest] @MessageOut NVARCHAR(250) = NULL OUTPUT
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
        EXEC [dbo].[spMFGetUserAccounts] @VaultSettings = @vaultsettings -- nvarchar(4000)
                                        ,@returnVal = @ReturnVal OUTPUT; -- nvarchar(max)

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

        SET @Return_Value = 1;
    END TRY
    BEGIN CATCH
        SET @MessageOut = 'Unable to connect with vault - check settings';

        SELECT @MessageOut AS [OutputMessage];

        DECLARE @EncrytedPassword NVARCHAR(100);

        SELECT TOP 1
               @EncrytedPassword = [mvs].[Password]
        FROM [dbo].[MFVaultSettings] AS [mvs];

        DECLARE @DecryptedPassword NVARCHAR(100);

        EXEC [dbo].[spMFDecrypt] @EncryptedPassword = @EncrytedPassword          -- nvarchar(2000)
                                ,@DecryptedPassword = @DecryptedPassword OUTPUT; -- nvarchar(2000)

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
    END CATCH;

    IF @Return_Value = 1
    BEGIN
        BEGIN TRY
            EXEC @Return_Value = [dbo].[spMFCheckLicenseStatus] @InternalProcedureName = 'spMFGetClass'    -- nvarchar(500)
                                                               ,@ProcedureName = 'spMFVaultConnectionTest' -- nvarchar(500)
                                                               ,@ProcedureStep = 'Validate License: ';     -- sysname

            SET @MessageOut = 'Validated License';

            --   SELECT @Return_Value;
            SELECT @MessageOut AS [OutputMessage];

            RETURN 1;
        END TRY
        BEGIN CATCH
            SET @MessageOut = 'Invalid License: ' + ERROR_MESSAGE();

            SELECT @MessageOut AS [OutputMessage];
        END CATCH;
    END;
END;

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


PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDropAndUpdateMetadata]';
GO

SET NOCOUNT ON;

EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFDropAndUpdateMetadata' -- nvarchar(100)
                                    ,@Object_Release = '4.2.8.47'               -- varchar(50)
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

    --SELECT @IsUpToDate = CASE
    --                         WHEN @IsResetAll = 1 THEN
    --                             0
    --                         ELSE
    --                             @IsUpToDate
    --                     END;
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
    BEGIN


        -------------------------------------------------------------
        -- License is valid - continue
        -------------------------------------------------------------			
        IF @return_value = 1
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

            RETURN 1;
        END; -- license is valid

		
    END; -- is updatetodate and istructure only
    ELSE
    BEGIN
        PRINT '###############################';
        PRINT 'Metadata structure is up to date';
    END; --else: no processing, upto date
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
                                    ,@Object_Release = '4.2.7.46'
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
                    RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep,@Datatypes);
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
                DECLARE @IsUpToDate BIT;

                EXEC [dbo].[spMFGetMetadataStructureVersionID] @IsUpToDate = @IsUpToDate OUTPUT; -- bit

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
        END
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
                END; --end filters 
-------------------------------------------------------------
-- Compile XML query from snippets
-------------------------------------------------------------

                SET @CreateXmlQuery = @CreateXmlQuery + ' FOR XML PATH(''''),ROOT(''form''))';

                IF @Debug > 9
                    SELECT @CreateXmlQuery AS [@CreateXmlQuery];         

                SET @Params = N'@ObjVerXMLForUpdate XML OUTPUT';

                EXEC [sys].[sp_executesql] @CreateXmlQuery, @Params, @ObjVerXMLForUpdate OUTPUT;

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

                   IF ISNULL(@SyncErrorFlag, 0) = 0  -- exclude routine when sync flag = 1 is processed
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

 SET @ProcedureStep = 'Set input XML parameters'
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
           SET @DeletedXML = null
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


        IF (@NewObjectXml != '<form />' OR @NewObjectXml <> '' OR @newObjectXML <> NULL)
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

        SET @ProcedureStep = 'Updating MFTable with deleted = 1,if object is deleted from MFiles';
        -------------------------------------------------------------------------------------
        --Update deleted column if record is deleled from M Files
        ------------------------------------------------------------------------------------               
        SET @StartTime = GETUTCDATE();

		IF @DeletedXML IS NOT NULL
        Begin
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
		END
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
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckLicenseStatus]';
GO


SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFCheckLicenseStatus'	-- nvarchar(100)
  , @Object_Release = '4.2.8.47'				-- varchar(50)
  , @UpdateFlag = 2;							-- smallint

GO

/*
Modifications
2018-07-09		lc	Change name of MFModule table to MFLicenseModule
3019-1-19		LC	Add return values
*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFCheckLicenseStatus' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFCheckLicenseStatus]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER  PROCEDURE [dbo].[spMFCheckLicenseStatus]
@InternalProcedureName NVARCHAR(500),
@ProcedureName NVARCHAR(500),
@ProcedureStep SYSNAME
AS 
BEGIN
				DECLARE @ModuleID NVARCHAR(20)
				DECLARE @Status NVARCHAR(20)
				DECLARE @VaultSettings NVARCHAR(2000)
				DECLARE @ModuleErrorMessage NVARCHAR(MAX)

				select 
				 @ModuleID=CAST(ISNULL(Module,0) as NVARCHAR(20))
				from 
				 setup.MFSQLObjectsControl 
				WHERE 
				 Name=@InternalProcedureName

				Select 
				 @VaultSettings=dbo.FnMFVaultSettings()
				--from 
				-- MFModule

	  
				IF @ModuleID !='0'
				Begin
				EXEC spMFValidateModule 
				                      @VaultSettings,
									  @ModuleID,
									  @Status OUT
		   
				IF @Status ='2'
				BEGIN
                
				  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'License is not valid.');
				  RETURN 2
				ENd

				IF @Status='3'
				Begin
				  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'You dont have access to this module.');
				  RETURN 3
				ENd

				IF @Status='4'
				Begin
				  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'Invalid License key.');
				  RETURN 4
				ENd

				IF @Status='5'
				Begin
				  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'Please install the License.');
				  RETURN 5
				ENd

				RETURN 1

				End
				--RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,@ModuleErrorMessage);
	
END


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
