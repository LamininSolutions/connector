PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertWorkflowState]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertWorkflowState', -- nvarchar(100)
    @Object_Release = '4.2.9.48', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
 /*
 MODIFICATIONS
 2017-7-2	LC	Change aliase datatype to varchar(100); Edit TRANS loop
2019-3-8	DEV2	Add insert updatecolumn
 */
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertWorkflowState'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertWorkflowState]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertWorkflowState]
    (
      @Doc NVARCHAR(MAX) ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS
/*rST**************************************************************************

=======================
spMFInsertWorkflowState
=======================

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
  ** Desc:  The purpose of this procedure is to insert Workflow State details into MFWorkflowState table.  
  **  

  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 
  ******************************************************************************/
    BEGIN
        BEGIN TRY
      --      BEGIN TRANSACTION;

            SET NOCOUNT ON;

          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
            DECLARE @IDoc INT ,
                @RowUpdated INT ,
                @RowAdded INT ,
                @WorkflowMFID INT ,
                @ProcedureStep sysname = 'Start' ,
                @XML XML = @Doc;
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertWorkflowState';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------------
          --CREATING TEMPORERY TABLE TO STORE DATA FROM XML
          -----------------------------------------------------
            CREATE TABLE #WorkFlowState
                (
                  [MFWorkflowID] INT ,
                  [MFID] INT NOT NULL ,
                  [Name] VARCHAR(100)--COLLATE Latin1_General_CI_AS NOT NULL
                  ,
                  [Alias] NVARCHAR(100)--COLLATE Latin1_General_CI_AS
                );

          ----------------------------------------------------------------------
          --INSERT DATA FROM XML INTO TEPORARY TABLE
          ----------------------------------------------------------------------
            SELECT  @ProcedureStep = 'Inserting CLR values into #WorkFlowStates';

            INSERT  INTO #WorkFlowState
                    ( MFWorkflowID ,
                      MFID ,
                      Name ,
                      Alias
                    )
                    SELECT  t.c.value('(@MFWorkflowID)[1]', 'INT') AS MFWorkflowID ,
                            t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias
                    FROM    @XML.nodes('/form/WorkflowState') AS t ( c );

            IF @Debug = 1
                BEGIN

                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #WorkFlowState
                END;

            SELECT  @ProcedureStep = 'Updating #WorkFlowState with MFWorkflowID';

          -----------------------------------------------------
          --UPDATE MFID WITH PKID
          -----------------------------------------------------
            UPDATE  #WorkFlowState
            SET     MFWorkflowID = ( SELECT ID
                                     FROM   MFWorkflow
                                     WHERE  MFID = MFWorkflowID 
                                   );

            IF @Debug = 1
                BEGIN

                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #WorkFlowState
                END;

            SELECT  @ProcedureStep = 'INSERT VALUES INTO #DIFFERENCETABLE';

          -----------------------------------------------------
          --Storing the difference into #tempDifferenceTable 
          -----------------------------------------------------
            SELECT  *
            INTO    #differenceTable
            FROM    ( SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      #WorkFlowState
                      EXCEPT
                      SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      MFWorkflowState
                    ) tempTbl;

            IF @Debug = 1
                BEGIN

                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #differenceTable
                END;

          -----------------------------------------------------------
          --Creatting new table to store the updated property details
          ----------------------------------------------------------- 
            CREATE TABLE #differenceTable2
                (
                  [MFWorkflowID] INT ,
                  [MFID] INT NOT NULL ,
                  [Name] VARCHAR(100)--COLLATE Latin1_General_CI_AS NOT NULL
                  ,
                  [Alias] NVARCHAR(100)--COLLATE Latin1_General_CI_AS
                );

            SELECT  @ProcedureStep = 'INSERTING NEW VALUES INTO #DIFFERENCETABLE2';

          -----------------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------------
            INSERT  INTO #differenceTable2
                    SELECT  *
                    FROM    #differenceTable;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #differenceTable2
                END;

            SELECT  @ProcedureStep = 'UPDATING MFWORKFLOWSTATES';

          -----------------------------------------------------
          --Updating the MFProperties 
          -----------------------------------------------------
            IF OBJECT_ID('tempdb.dbo.#differenceTable2') IS NOT NULL
                BEGIN

			

				    /*Added for Bug 1088*/
				    UPDATE  MFWorkflowState
                    SET     MFWorkflowState.IsNameUpdate = 1
                    FROM    MFWorkflowState
                            INNER JOIN #differenceTable2 ON MFWorkflowState.MFID = #differenceTable2.MFID
															 AND MFWorkflowState.Name != #differenceTable2.Name;
				/*Added for Bug 1088*/

                    UPDATE  MFWorkflowState
                    SET     MFWorkflowState.MFWorkflowID = #differenceTable2.MFWorkflowID ,
                            MFWorkflowState.Name = #differenceTable2.Name ,
                            MFWorkflowState.Alias = #differenceTable2.Alias ,
                            MFWorkflowState.ModifiedOn = GETDATE() ,
                            MFWorkflowState.Deleted = 0
                    FROM    MFWorkflowState
                            INNER JOIN #differenceTable2 ON MFWorkflowState.MFID = #differenceTable2.MFID;

                    SELECT  @RowUpdated = @@ROWCOUNT;
                END;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFWorkflowState
                END;

            SELECT  @ProcedureStep = 'INSERTING VALUES INTO #TEMP';

          -----------------------------------------------------
          --Adding The new property 
          -----------------------------------------------------
            SELECT  *
            INTO    #temp
            FROM    ( SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      #WorkFlowState
                      EXCEPT
                      SELECT    MFWorkflowID ,
                                MFID ,
                                Name ,
                                Alias
                      FROM      MFWorkflowState
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #temp
                END;

            SELECT  @ProcedureStep = 'INSERTING VALUES INTO MFWORKFLOWSTATE';

          -----------------------------------------------------
          --INSERT NEW WORKFLOW STATE DETAILS
          -----------------------------------------------------
            INSERT  INTO MFWorkflowState
                    ( MFWorkflowID ,
                      MFID ,
                      Name ,
                      Alias ,
                      Deleted,
					  CreatedOn  -- Added for task 568
                    )
                    SELECT  MFWorkflowID ,
                            MFID ,
                            Name ,
                            Alias ,
                            0 ,
							getdate() -- Added for task 568
                    FROM    #temp;

            SELECT  @RowAdded = @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFWorkflowState
                END;

            DECLARE @MFWorkflowID INT;

            SELECT DISTINCT
                    @MFWorkflowID = MFWorkflowID
            FROM    #WorkFlowState;

            SELECT  @ProcedureStep = 'INSERTING VALUES INTO #DELETEDWORKFLOWSTATES';

          --------------------------------------------------------
          -- Select ValueListItems Which are deleted from M-Files 
          -----------------------------------------------------  
            SELECT  MFID
            INTO    #DeletedWorkflowStates
            FROM    ( SELECT    MFID
                      FROM      MFWorkflowState
                      WHERE     MFWorkflowState.MFWorkflowID = @MFWorkflowID
                      EXCEPT
                      SELECT    MFID
                      FROM      #WorkFlowState
                    ) #DeletedWorkflowStatesID;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #DeletedWorkflowStates
                END;

            SELECT  @ProcedureStep = 'UPDATING MFWORKFLOWSTATE WITH DELETED = 1 ';

          ---------------------------------------------------------
          --Deleting the ValueListItems Thats deleted from M-Files 
          ---------------------------------------------------------     
            UPDATE  MFWorkflowState
            SET     Deleted = 1
            WHERE   MFID IN ( SELECT    MFID
                              FROM      #DeletedWorkflowStates );

            UPDATE  MFWorkflowState
            SET     Deleted = 1
            WHERE   MFWorkflowID IN ( SELECT    ID
                                      FROM      MFWorkflow
                                      WHERE     deleted = 1 );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   MFWorkflowState
                END;

          -----------------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------------
            DROP TABLE #WorkFlowState;

            DROP TABLE #differenceTable2;

            SELECT  @Output = @RowAdded + @RowUpdated;

            SET NOCOUNT OFF;

     --       COMMIT TRANSACTION;
        END TRY

        BEGIN CATCH
    --        ROLLBACK TRANSACTION;

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
                    VALUES  ( 'spMFInsertWorkflowState' ,
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
