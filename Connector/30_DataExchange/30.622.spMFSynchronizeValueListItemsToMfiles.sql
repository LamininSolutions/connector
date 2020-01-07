

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
AS
/*rST**************************************************************************

=====================================
spMFSynchronizeValueListItemsToMfiles
=====================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
 /*******************************************************************************
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
				SELECT @XMLOut AS 'outputXML';


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

