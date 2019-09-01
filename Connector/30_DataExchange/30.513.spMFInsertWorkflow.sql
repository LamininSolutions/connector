
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertWorkflow]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertWorkflow', -- nvarchar(100)
    @Object_Release = '2.0.2.0', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertWorkflow'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertWorkflow]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertWorkflow]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS
/*rST**************************************************************************

==================
spMFInsertWorkflow
==================

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
  ** Desc:  The purpose of this procedure is to insert Workflow details into MFWorkflow table.  
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
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

          -----------------------------------------------------
          --DECLARE LOCAL VARIABLES
          -----------------------------------------------------
            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'Start' ,
                @XML XML = @Doc;
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertWorkflow';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------------
          --CREATING TEMPORERY TABLE TO STORE DATA FROM XML
          -----------------------------------------------------
            CREATE TABLE #WorkflowTble
                (
                  [MFID] INT NOT NULL ,
                  [Alias] NVARCHAR(100) ,
                  [Name] VARCHAR(100)
                );

          ----------------------------------------------------------------------
          --INSERT DATA FROM XML INTO TEPORARY TABLE
          ----------------------------------------------------------------------
            SET @ProcedureStep = 'Inserting values into @WorkflowTble';

            INSERT  INTO #WorkflowTble
                    ( MFID ,
                      Alias ,
                      Name
                    )
                    SELECT  t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME
                    FROM    @XML.nodes('/form/Workflow') AS t ( c );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #WorkflowTble
                END;

          -----------------------------------------------------
          --Storing the difference into #tempNewObjectTypeTble 
          -----------------------------------------------------
            SET @ProcedureStep = 'INSERT Values into #NewWorkflowTble';

            SELECT  *
            INTO    #NewWorkflowTble
            FROM    ( SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      #WorkflowTble
                      EXCEPT
                      SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      MFWorkflow
                    ) tempTbl;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #NewWorkflowTble
                END;

          -------------------------------------------------------------
          --Creatting new table to store the updated property details 
          -------------------------------------------------------------
            CREATE TABLE #NewWorkflowTble2
                (
                  [MFID] INT NOT NULL ,
                  [Alias] NVARCHAR(100) ,
                  [Name] VARCHAR(100)
                );

          -----------------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------------
            SET @ProcedureStep = 'Insert Values into #NewWorkflowTble2';

            INSERT  INTO #NewWorkflowTble2
                    SELECT  *
                    FROM    #NewWorkflowTble;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #NewWorkflowTble2
                END;

          -----------------------------------------------------
          --Updating the MFProperties 
          -----------------------------------------------------
            SET @ProcedureStep = 'Updating MFWorkflow';

            IF OBJECT_ID('tempdb..#NewWorkflowTble2') IS NOT NULL
                BEGIN
                    UPDATE  MFWorkflow
                    SET     MFWorkflow.Name = #NewWorkflowTble2.Name ,
                            MFWorkflow.Alias = #NewWorkflowTble2.Alias ,
                            MFWorkflow.Deleted = 0,
							MFWorkflow.ModifiedOn=GetDate()  --Added for task 568
                    FROM    MFWorkflow
                            INNER JOIN #NewWorkflowTble2 ON MFWorkflow.MFID = #NewWorkflowTble2.MFID;

                    SET @Output = @@ROWCOUNT;
                END;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   MFWorkflow
                END;

          -----------------------------------------------------
          --Adding The new property 	
          -----------------------------------------------------
            SET @ProcedureStep = 'Inserting values into #temp';

            SELECT  *
            INTO    #temp
            FROM    ( SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      #WorkflowTble
                      EXCEPT
                      SELECT    MFID ,
                                Alias ,
                                Name
                      FROM      MFWorkflow
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #temp
                END;

          -----------------------------------------------------
          --INSERT NEW WORKFLOW DETAILS INTO MFWorkflow
          -----------------------------------------------------
            SET @ProcedureStep = 'Inserting values into MFWorkflow';

            INSERT  INTO MFWorkflow
                    ( MFID, Alias, Name, DELETED,CreatedOn )
                    SELECT  MFID ,
                            Alias ,
                            Name ,
                            0,
							Getdate()  --Added for task 568
                    FROM    #temp;

            SET @Output = @Output + @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFWorkflow
                END;

            IF ( @isFullUpdate = 1 )
                BEGIN
                -----------------------------------------------------
                -- Select ObjectTypeID Which are deleted from M-Files  
                -----------------------------------------------------
                    SET @ProcedureStep = '@isFullUpdate = 1';

                    SELECT  MFID
                    INTO    #DeletedWorkflow
                    FROM    ( SELECT    MFID
                              FROM      MFWorkflow
                              EXCEPT
                              SELECT    MFID
                              FROM      #WorkflowTble
                            ) DeletedMFID;

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                      --SELECT *
                      --FROM   #DeletedWorkflow
                        END;

                -----------------------------------------------------
                --Deleting the ObjectTypes Thats deleted from M-Files
                -----------------------------------------------------  
                    SET @ProcedureStep = 'Updating MFWorkflow with Deleted  = 1 ';

                    UPDATE  MFWorkflow
                    SET     Deleted = 1
                    WHERE   MFID IN ( SELECT    MFID
                                      FROM      #DeletedWorkflow );
                END;

          -----------------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------------
            DROP TABLE #WorkflowTble;

            DROP TABLE #NewWorkflowTble2;

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
                    VALUES  ( 'spMFInsertWorkflow' ,
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
