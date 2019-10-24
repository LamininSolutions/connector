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
AS
/*rST**************************************************************************

========================
spMFInsertValueListItems
========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Doc nvarchar(max)
    fixme description
  @Output int (output)
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Insert ValueList Items details into MFValueListItems table.

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
2015-06-26  DEV2       Updating Column appRef
==========  =========  ========================================================

**rST*************************************************************************/
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
