PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertClassProperty]';
go

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFInsertClassProperty', -- nvarchar(100)
    @Object_Release = '3.1.2.39', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINE_NAME] = 'spMFInsertClassProperty'--name of procedure
                    AND [ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINE_SCHEMA] = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFInsertClassProperty]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFInsertClassProperty]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT = 0
    )
AS
/*rST**************************************************************************

=======================
spMFInsertClassProperty
=======================

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

To insert Class property details into MFClassProperty table.

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
2017-09-11  LC         Resolve issue with constraints
2015-04-07  DEV2       Resolved synchronization issue (Bug 55)
==========  =========  ========================================================

**rST*************************************************************************/

/*******************************************************************************
** Processing Steps:
**        1. Insert data from XML into temperory data
**		2. Update M-Files ID with primary key values
**		3. Update the Class property details into MFClMFClassPropertyass
**		4. INsert the new class property details
**		5. If fullUpdate 
**				Delete the class property details deleted from M-Files
**
******************************************************************************/

    SET NOCOUNT ON;

    BEGIN TRY
          -----------------------------------------------------
          -- LOCAL VARIABLE DECLARATION
          -----------------------------------------------------
        DECLARE @IDoc INT ,
            @ProcedureStep sysname = 'START' ,
			@ProcedureName sysname = 'spMFInsertClassProperty',
            @XML XML = @Doc;


        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
            END;
   
             -----------------------------------------------------
          -- COPY CUSTOM DATA INTO TEMP TABLE

          -----------------------------------------------------    
		   SELECT  @ProcedureStep = 'Copy Custom data into temp table';

		   SELECT * INTO #TempClassProperty FROM MFClassProperty

             -----------------------------------------------------
          -- GET CLASS PROPERTY INFORMATION FROM M-FILES

          -----------------------------------------------------   	   
	   
	   
	    CREATE TABLE [#ClassProperty]
            (
              [MFClass_ID] INT ,
              [MFProperty_ID] INT ,
              [Required] BIT
			 
            );

        SELECT  @ProcedureStep = 'Inserting values into #ClassProperty';
        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
            END;
          --------------------------------------------------------------
          -- INSERT DATA FROM XML INTO TEMPORARY TABLE 
          --------------------------------------------------------------          
        INSERT  INTO [#ClassProperty]
                ( [MFClass_ID] ,
                  [MFProperty_ID] ,
                  [Required]
                )
                SELECT  [t].[c].[value]('(@classID)[1]', 'INT') AS [MFClass_ID] ,
                        [t].[c].[value]('(@PropertyID)[1]', 'INT') AS [MFProperty_ID] ,
                        [t].[c].[value]('(@Required)[1]', 'BIT') AS [Required]
                FROM    @XML.[nodes]('/form/ClassProperty') AS [t] ( [c] );

        SELECT  @ProcedureStep = 'Updating #ClassProperty with Required value from MFClassProperty';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  *
                FROM    [dbo].[MFClass] AS [mc]
                        FULL OUTER JOIN [dbo].[#ClassProperty] AS [mcp] ON [MFClass_ID] = [mc].[ID]
                        INNER JOIN [dbo].[MFProperty] AS [mp] ON [mp].[ID] = [mcp].[MFProperty_ID]; 
            END;
      
        SET @ProcedureStep = 'Updating #ClassProperty';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
            END;

        UPDATE  [#ClassProperty]
        SET     [MFClass_ID] = ( SELECT [ID]
                                 FROM   [MFClass]
                                 WHERE  [MFID] = [#ClassProperty].[MFClass_ID]
                               ) ,
                [MFProperty_ID] = ( SELECT  [ID]
                                    FROM    [MFProperty]
                                    WHERE   [MFID] = [#ClassProperty].[MFProperty_ID]
                                  );
       
        UPDATE  [#ClassProperty]
        SET     [#ClassProperty].[MFClass_ID] = 0
        WHERE   [#ClassProperty].[MFClass_ID] IS NULL; 
 
        SET @ProcedureStep = 'Inserting values into #ClassPpt';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  '#classProperty' ,
                        *
                FROM    [dbo].[MFClass] AS [mc]
                        FULL OUTER JOIN [dbo].[#ClassProperty] AS [mcp] ON [MFClass_ID] = [mc].[ID]
                        INNER JOIN [dbo].[MFProperty] AS [mp] ON [mp].[ID] = [mcp].[MFProperty_ID]; 
            END;
						      --          --------------------------------------------------------------
          --          ----Storing the difference into #tempNewObjectTypeTble 
          --          --------------------------------------------------------------
        SET @ProcedureStep = 'Storing the difference into #tempTbl';
        SELECT  *
        INTO    [#ClassPpt]
        FROM    ( SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [#ClassProperty].[Required]
                  FROM      [#ClassProperty]
                  EXCEPT
                  SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [MFClassProperty].[Required]
                  FROM      [MFClassProperty]
                ) [tempTbl];

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  '#ClassPpt ' ,
                        *
                FROM    [dbo].[MFClass] AS [mc]
                        FULL OUTER JOIN [dbo].[#ClassPpt] AS [mcp] ON [MFClass_ID] = [mc].[ID]
                        INNER JOIN [dbo].[MFProperty] AS [mp] ON [mp].[ID] = [mcp].[MFProperty_ID];
                SELECT  *
                FROM    [#ClassPpt]
                        LEFT JOIN [MFClassProperty] [cp] ON ( [cp].[MFClass_ID] = [#ClassPpt].[MFClass_ID]
                                                              AND [cp].[MFProperty_ID] = [#ClassPpt].[MFProperty_ID]
                                                            );
            END;

		------------------------------------------------------
		--Drop CONSTRAINT
		------------------------------------------------------
        SET @ProcedureStep = 'Drop CONSTRAINT';
        IF @debug  = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

        IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NOT NULL )
            BEGIN
                ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass];
            END;
		IF ( OBJECT_ID('FK_MFClassProperty_MFClass_ID', 'F') IS NOT NULL )
            BEGIN
                ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass_ID];
            END;

          --------------------------------------------------------
          --UPDATE EXISTING CLASS PROPERTY
          --------------------------------------------------------
        BEGIN TRY
            SET @ProcedureStep = 'update MFCLassProperty Required values';
            UPDATE  [MFClassProperty]
            SET     [MFClassProperty].[Required] = [#ClassPpt].[Required]
            FROM    [MFClassProperty] [cp]
                    INNER JOIN [#ClassPpt] ON ( [cp].[MFClass_ID] = [#ClassPpt].[MFClass_ID]
                                                AND [cp].[MFProperty_ID] = [#ClassPpt].[MFProperty_ID]
                                              );

  

            IF @debug  = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    
                END;
        END TRY
        BEGIN CATCH
            RAISERROR('%s : Step %s Failed',16,1,@ProcedureName,@ProcedureStep);

        END CATCH;
          

		  --------------------------------------------------------------
          --Adding The new property 
          --------------------------------------------------------------
        BEGIN TRY
            SET @ProcedureStep = 'insert new items into MFCLassProperty';  
            INSERT  INTO [MFClassProperty]
                    ( [MFClass_ID] ,
                      [MFProperty_ID] ,
                      [Required]
                    )
                    SELECT  *
                    FROM    ( SELECT    [MFClass_ID] ,
                                        [MFProperty_ID] ,
                                        [Required]
                              FROM      [#ClassProperty]
                              EXCEPT
                              SELECT    [MFClass_ID] ,
                                        [MFProperty_ID] ,
                                        [Required]
                              FROM      [MFClassProperty]
                            ) [newPprty];
            SET @Output = @Output + @@ROWCOUNT;
            IF @debug  = 1
                BEGIN
               
                    IF ( @isFullUpdate = 1 )
                        SET @ProcedureStep = @ProcedureStep + ' Full Update';
					
                    RAISERROR('%s : Step %s inserting %i rows',10,1,@ProcedureName,@ProcedureStep, @Output); 

                END;      
        END TRY
        BEGIN CATCH 
            RAISERROR('%s : Step %s Failed',16,1,@ProcedureName,@ProcedureStep);
        END CATCH;
                --------------------------------------------------------------
                -- Select MFID Which are deleted from M-Files 
                --------------------------------------------------------------
        SET @ProcedureStep = 'Deletes objects from MFCLassProperty';
        SELECT  [MFClass_ID] ,
                [MFProperty_ID] ,
                [Required]
        INTO    [#DeletedObjectTypes]
        FROM    ( SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [Required]
                  FROM      [MFClassProperty]
                  EXCEPT
                  SELECT    [MFClass_ID] ,
                            [MFProperty_ID] ,
                            [Required]
                  FROM      [#ClassProperty]
                ) [#DeletedWorkFlowStates];

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  '#DeletedObjectTypes' ,
                        *
                FROM    [#DeletedObjectTypes]; 
            END;
    
                --------------------------------------------------------------
                --Deleting the Classproperty Thats deleted from M-Files 
                --------------------------------------------------------------

        DELETE  FROM [MFClassProperty]
        WHERE   [MFProperty_ID] IN ( SELECT [MFProperty_ID]
                                     FROM   [#DeletedObjectTypes] )
                AND [MFClass_ID] IN ( SELECT    [MFClass_ID]
                                      FROM      [#DeletedObjectTypes] );


              --------------------------------------------------------------
                --Deleting the system Class for Reporting from ClassProperty 
                --------------------------------------------------------------
        SET @ProcedureStep = 'Delete Report Class from MFCLassProperty';
        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                SELECT  'Report Class Deleted' ,
                        *
                FROM    [dbo].[MFClassProperty] AS [mcp]; 
            END;

   IF (SELECT count(mfclass_ID) FROM MFClassProperty WHERE MFClass_ID = 0) > 0
        DELETE  FROM [MFClassProperty]
        WHERE   [MFClass_ID] = 0;

	 
	 
	 
	      --------------------------------------------------------------
          --Droping all temperory Table 
          --------------------------------------------------------------
        DROP TABLE [#TempClassProperty]
		DROP TABLE [#ClassProperty];

	
        SELECT  @ProcedureStep = 'END Insert ClassProperty Properties';

        IF @debug  = 1
            BEGIN
                RAISERROR('%s : Step %s Return 1',10,1,@ProcedureName,@ProcedureStep);
            END;     

        SET NOCOUNT OFF;

        RETURN 1;
    END TRY
    BEGIN CATCH

        SET NOCOUNT ON;


        BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
            INSERT  INTO [MFLog]
                    ( [SPName] ,
                      [ErrorNumber] ,
                      [ErrorMessage] ,
                      [ErrorProcedure] ,
                      [ErrorState] ,
                      [ErrorSeverity] ,
                      [ErrorLine] ,
                      [ProcedureStep]
                    )
            VALUES  ( @ProcedureName ,
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
	go
    
