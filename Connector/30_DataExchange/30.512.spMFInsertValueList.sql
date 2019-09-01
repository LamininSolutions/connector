PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertValueList]';
go
 
SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertValueList', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertValueList'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertValueList]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertValueList]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS
/*rST**************************************************************************

===================
spMFInsertValueList
===================

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
  ** Desc:  The purpose of this procedure is to insert ValueList details into MFValueList table.  
  **  
 
  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2018-1-2	Dev2		Add RealObjectType flag
  ******************************************************************************/
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            SET NOCOUNT ON;

          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'START' ,
                @XML XML = @Doc;

            SELECT  @ProcedureStep = 'Create Table #ValueList';
            DECLARE @procedureName NVARCHAR(128) = 'spMFInsertValueList';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------------
          --CREATING TEMPORARY TABLE STORE XML DATA
          -----------------------------------------------------
            CREATE TABLE #ValueList
                (
                  [Name] VARCHAR(100) NOT NULL ,
                  [Alias] NVARCHAR(100) NULL ,
                  [MFID] INT NOT NULL ,
                  OwnerID INT NULL,
				  [RealObjectType] bit
                );

            SELECT  @ProcedureStep = 'Insert values into #ValueList';

          -----------------------------------------------------
          --INSERT DATA FROM XML TO TEMPORARY TABLE
          -----------------------------------------------------
            INSERT  INTO #ValueList
                    ( Name ,
                      Alias ,
                      MFID ,
                      OwnerID,
					  RealObjectType
                    )
                    SELECT  t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Owner)[1]', 'INT') AS OwnerType,
							t.c.value('(@RealObj)[1]', 'bit') AS RealObjectType 
                    FROM    @XML.nodes('/form/valueList') AS t ( c );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

               -- SELECT *
               -- FROM   #ValueList
                END;

            SELECT  @ProcedureStep = 'Inserting New ValueList into #DifferenceTable';

          -----------------------------------------------------
          --Storing the difference into #tempDifferenceTable 
          -----------------------------------------------------
            SELECT  *
            INTO    #DifferenceTable
            FROM    ( SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      #ValueList
                      EXCEPT
                      SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      MFValueList
                    ) tempTbl;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #DifferenceTable
                END;

            SELECT  @ProcedureStep = 'Creating new table to store the updated property details #NewValueListTable';

          -----------------------------------------------------------
          --Creating new table to store the updated property details 
          -----------------------------------------------------------
            CREATE TABLE #NewValueListTable
                (
                  [Name] VARCHAR(100) NOT NULL --COLLATE Latin1_General_CI_AS
                  ,
                  [Alias] NVARCHAR(100) NULL--COLLATE Latin1_General_CI_AS
                  ,
                  [MFID] INT NOT NULL ,
                  [OwnerID] INT NULL,
				  [RealObjectType] BIT NULL
                );

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #NewValueListTable
                END;

            SELECT  @ProcedureStep = 'Inserting Values into #NewValueListTable';

          -----------------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------------
            INSERT  INTO #NewValueListTable
                    SELECT  *
                    FROM    #DifferenceTable;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #NewValueListTable
                END;

            SELECT  @ProcedureStep = 'Updating MFValueList with existing and changed values';

          -----------------------------------------------------
          --Updating the MFValueList 
          -----------------------------------------------------
            IF OBJECT_ID('tempdb.dbo.#NewValueListTable') IS NOT NULL
                BEGIN
                    UPDATE  MFValueList
                    SET     MFValueList.Alias = #NewValueListTable.Alias ,
                            MFValueList.Name = #NewValueListTable.Name ,
                            MFValueList.OwnerID = #NewValueListTable.OwnerID ,
                            MFValueList.ModifiedOn = GETDATE() ,
                            MFValueList.Deleted = 0,
							MFValueList.RealObjectType=#NewValueListTable.RealObjectType
                    FROM    MFValueList
                            INNER JOIN #NewValueListTable ON MFValueList.MFID = #NewValueListTable.MFID;

                    SELECT  @Output = @@ROWCOUNT;

                    IF @Debug = 1
                        BEGIN
                            SELECT  @ProcedureStep;

                            SELECT  @Output;

                            SELECT  *
                            FROM    #NewValueListTable;

                            SELECT  *
                            FROM    MFValueList
                                    INNER JOIN #NewValueListTable ON MFValueList.MFID = #NewValueListTable.MFID;

                            SELECT  *
                            FROM    MFValueList;
                        END;
                END;

            SELECT  @ProcedureStep = 'Inserting Value into #temp';

          -----------------------------------------------------
          --Adding The new valeuList 	
          -----------------------------------------------------
            SELECT  *
            INTO    #temp
            FROM    ( SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      #ValueList
                      EXCEPT
                      SELECT    Name ,
                                Alias ,
                                MFID ,
                                OwnerID,
								RealObjectType
                      FROM      MFValueList
                    ) newPprty;

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
                --SELECT *
                --FROM   #temp
                END;

            SELECT  @ProcedureStep = 'Inserting value into MFValueList';

          -----------------------------------------------------
          --INSERTING NEW VALUELIST DETAILS
          -----------------------------------------------------
            INSERT  INTO MFValueList
                    ( Name ,
                      Alias ,
                      MFID ,
                      OwnerID ,
                      Deleted,
					  CreatedOn ,  --added for task  568
					  RealObjectType
                    )
                    SELECT  Name ,
                            Alias ,
                            MFID ,
                            OwnerID ,
                            0,
							getdate(), --added for task  568
							RealObjectType
                    FROM    #temp;

            SELECT  @Output = @Output + @@ROWCOUNT;

            IF @Debug = 1
                BEGIN
                    SELECT  @ProcedureStep;

                    SELECT  @Output;

                    SELECT  *
                    FROM    #temp;

                    SELECT  *
                    FROM    MFValueList;
                END;

            SELECT  @ProcedureStep = 'selecting Deleted valueList from M_Files';

            IF ( @isFullUpdate = 1 )
                BEGIN
                    SELECT  @ProcedureStep = 'Full update';

                -----------------------------------------------------
                -- Select MFID Which are deleted from M-Files 
                -----------------------------------------------------
                    SELECT  MFID
                    INTO    #DeletedValueList
                    FROM    ( SELECT    MFID
                              FROM      MFValueList
                              EXCEPT
                              SELECT    MFID
                              FROM      #ValueList
                            ) DeletedMFID;

                    SELECT  @ProcedureStep = 'Updating Deleted = 1';

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                      --SELECT *
                      --FROM   #DeletedValueList
                        END;

                -----------------------------------------------------
                --Deleting the MFValueList Thats deleted from M-Files
                ----------------------------------------------------- 				
                    UPDATE  MFValueList
                    SET     Deleted = 1
                    WHERE   MFID IN ( SELECT    MFID
                                      FROM      #DeletedValueList );
                END;

          -----------------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------------
            DROP TABLE #ValueList;

            DROP TABLE #NewValueListTable;

            DROP TABLE #temp;

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
                    VALUES  ( 'spMFInsertValueList' ,
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
