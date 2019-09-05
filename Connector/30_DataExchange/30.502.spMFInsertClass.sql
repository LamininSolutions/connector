PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFInsertClass]';
go
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFInsertClass', -- nvarchar(100)
    @Object_Release = '4.2.7.46', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
go

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFInsertClass'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFInsertClass]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;

go

ALTER PROCEDURE [dbo].[spMFInsertClass]
    (
      @Doc NVARCHAR(MAX) ,
      @isFullUpdate BIT ,
      @Output INT OUTPUT ,
      @Debug SMALLINT 
	)
AS
/*rST**************************************************************************

===============
spMFInsertClass
===============

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

The purpose of this procedure is to insert Class details into MFClass table.

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
2018-11-10  LC         Add includedinApp update for User Messager table
2018-03-26  DEV2       Workflow required check
2016-03-19  LC         No error for duplicate Report Class
2015-07-20  DEV2       TableName Duplicate Issue Resolved
2015-07-14  DEV2       MFValuelist_ID column removed from MFClass
2015-05-27  DEV2       INSERT/UPDATE logic changed
==========  =========  ========================================================

**rST*************************************************************************/

    SET NOCOUNT ON;
    BEGIN
        BEGIN TRY
            SET NOCOUNT ON;

            DECLARE @IDoc INT ,
                @ProcedureStep sysname = 'START Insert Classes' ,
                @ProcedureName sysname = 'spMFInsertClass' ,
                @XML XML = @Doc;
            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
		---------------------------------------------------
		--Check whether #ClassesTble already exists or not
		---------------------------------------------------
            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#ClassesTble' )
                BEGIN
                    DROP TABLE #ClassesTble;
                END;

		-----------------------------------------------
		--Create temporary table store data from XML
		-----------------------------------------------
            CREATE TABLE #ClassesTble
                (
                  [MFID] INT NOT NULL ,
                  [Name] VARCHAR(100) ,
                  [Alias] NVARCHAR(100) ,
                  [MFObjectType_ID] INT NOT NULL, --added not null for task 975
                  [MFWorkflow_ID] INT,
				  [IsWorkflowEnforced] BIT --added for task 1052
                );



            SELECT  @ProcedureStep = 'Insert values into #ClassesTble';
            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
		-----------------------------------------------
		-- INSERT DATA FROM XML INTO TABLE
		-----------------------------------------------     
            INSERT  INTO #ClassesTble
                    ( MFID ,
                      Name ,
                      Alias ,
                      MFObjectType_ID ,
                      MFWorkflow_ID,
					  IsWorkflowEnforced --added for task 1052
			        )
                    SELECT  t.c.value('(@MFID)[1]', 'INT') AS MFID ,
                            t.c.value('(@Name)[1]', 'NVARCHAR(100)') AS NAME ,
                            t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias ,
                            t.c.value('(@MFObjectType_ID)[1]', 'INT') AS MFObjectType_ID ,
                            t.c.value('(@MFWorkflow_ID)[1]', 'INT') AS MFWorkflow_ID,
							t.c.value('(@IsWorkflowEnforced)[1]', 'BIT') AS IsWorkflowEnforced --added for task 1052
                    FROM    @XML.nodes('/form/Class') AS t ( c );
            
			
            SELECT  @ProcedureStep = 'Store current MFClass records int #CurrentMFClass';
            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  *
                    --FROM    [#ClassesTble] AS [ct];
                END;

            DELETE  FROM [#ClassesTble]
            WHERE   MFID = -101; ---Special Report Class, this is not required in Connector

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  *
                    --FROM    [#ClassesTble] AS [ct];
                END;


            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#CurrentMFClass' )
                BEGIN
                    DROP TABLE #CurrentMFClass;
                END;

		------------------------------------------------------
		--Store present records in MFClass to #CurrentMFClass
		------------------------------------------------------
            SELECT  *
            INTO    #CurrentMFClass
            FROM    ( SELECT    *
                      FROM      MFClass
                      WHERE     MFID <> -101
                    ) mfc;

		
            SELECT  @ProcedureStep = 'DROP CONSTRAINT FROM MFClassProperty';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  *
                    --FROM    [#CurrentMFClass] AS [cmc];
                    --SELECT  *
                    --FROM    [dbo].[MFClassProperty] AS [mcp];
                    --SELECT  *
                    --FROM    [dbo].[MFClass] AS [mc];
                END;


            SELECT  @ProcedureStep = 'Update MFClassProperty';
            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;

		---------------------------------------------------------
		--Update the MFClassProperty.MFClass_ID with MFCLass.MFID
		---------------------------------------------------------
            UPDATE  MFClassProperty
            SET     MFClass_ID = MFClass.MFID
            FROM    MFClassProperty
                    INNER JOIN MFClass ON MFClass_ID = MFClass.ID
            WHERE   [MFClass].[MFID] <> -101;

            SELECT  @ProcedureStep = 'Delete records from MFClass';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                    --SELECT  *
                    --FROM    [#ClassesTble] AS [ct];
                    --SELECT  *
                    --FROM    [dbo].[MFClassProperty] AS [mcp]; 
                END;
		----------------------------------------------------
		--Delete records from MFClass
		----------------------------------------------------
            
			
	--		DELETE  FROM MFClass;

            SELECT  @ProcedureStep = 'Update MFID with PK ID';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;

		-----------------------------------------------------------------------
		--Update #ClassesTble with pkId of MFObjecttype,MFWorkFlow,MFValueList
		-----------------------------------------------------------------------
            UPDATE  #ClassesTble
            SET     MFObjectType_ID = ( SELECT  ID
                                        FROM    MFObjectType
                                        WHERE   MFID = MFObjectType_ID
                                      ) ,
                    MFWorkflow_ID = ( SELECT    ID
                                      FROM      MFWorkflow
                                      WHERE     MFID = MFWorkflow_ID
                                    );

            SELECT  @ProcedureStep = 'Insert Records into MFClass';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;

		------------------------------------------------
		--merge Records into MFClass
		------------------------------------------------

            MERGE INTO MFClass AS t
            USING
                ( SELECT    *
                  FROM      ( SELECT    MFID ,
                                        Name ,
                                        Alias ,
                                        'MF'
                                        + REPLACE(dbo.fnMFCapitalizeFirstLetter(Name),
                                                  ' ', '') AS TableName
				--Replacing ' ' and changing each words first letter to UPPERCASE					
                                        ,
                                        MFObjectType_ID ,
                                        MFWorkflow_ID ,
										IsWorkflowEnforced, --added for task 1052
                                        0 AS Deleted
                              FROM      #ClassesTble
                              WHERE     MFID <> -101
                            ) n
                ) AS s
            ON ( t.MFID = s.MFID )
			when Matched then                         --Added By Rheal
			  UPdate  set t.Alias=s.Alias,t.MFWorkflow_ID=s.MFWorkflow_ID, t.Name=s.Name,t.IsWorkflowEnforced=s.IsWorkflowEnforced --Added By Rheal
            WHEN NOT MATCHED BY TARGET THEN
                INSERT ( MFID ,
                         Name ,
                         Alias ,
                         TableName ,
                         MFObjectType_ID ,
                         MFWorkflow_ID ,
						 IsWorkflowEnforced, --added for task 1052
                         Deleted,
						 CreatedOn --Added for task 568
						-- ,ModifiedOn --Added for task 568
			           )
                VALUES ( s.MFID ,
                         s.Name ,
                         s.Alias ,
                         s.TableName ,
                         s.MFObjectType_ID ,
                         s.MFWorkflow_ID ,
						 IsWorkflowEnforced, --added for task 1052
                         s.Deleted,
						 Getdate()  --Added for task 568
						--,null  --Added for task 568
                       )
            WHEN NOT MATCHED BY SOURCE THEN
                DELETE;

    --                SELECT  *
    --                FROM    ( SELECT    MFID ,
    --                                    Name ,
    --                                    Alias ,
    --                                    'MF'
    --                                    + REPLACE(dbo.fnMFCapitalizeFirstLetter(Name),
    --                                              ' ', '') AS TableName
				----Replacing ' ' and changing each words first letter to UPPERCASE					
    --                                    ,
    --                                    MFObjectType_ID ,
    --                                    MFWorkflow_ID ,
    --                                    0 AS Deleted
    --                          FROM      #ClassesTble
    --                          WHERE     MFID <> -101
    --                        ) n;

            SELECT  @Output = @@ROWCOUNT;

            SELECT  @ProcedureStep = 'Update MFClass with Data from old table';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;
		---------------------------------------------------------------------
		--Update MFClass with TableName & IncludeInApp from Old table
		---------------------------------------------------------------------
            UPDATE  MFClass
            SET     TableName = #CurrentMFClass.TableName ,
                    IncludeInApp = #CurrentMFClass.IncludeInApp
            FROM    MFClass
                    INNER JOIN #CurrentMFClass ON MFClass.Name = #CurrentMFClass.Name;

			 
            SELECT  @ProcedureStep = 'Update MFCLassProperty with PK ID Delete not existing';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                END;
		-----------------------------------------------------------
		--Delete the records of Class which not exists in new vault
		-----------------------------------------------------------
            DELETE  FROM MFClassProperty
            WHERE   MFClass_ID NOT IN ( SELECT  MFID
                                        FROM    MFClass );
    
            SELECT  @ProcedureStep = 'Update MFClassProperty.MFclass_ID with MFClass.ID';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  Tablename = 'MFClassProperty' ,
                    --        *
                    --FROM    [dbo].[MFClassProperty] AS [mcp];
                END;
		
		-------------------------------------------------------------
		-- Update includeInApp for MFSQL Messages
		-------------------------------------------------------------
		DECLARE @DetailLogging NVARCHAR(5)
		SELECT @DetailLogging = CAST([Value] AS VARCHAR(5)) FROM mfsettings WHERE name = 'App_DetailLogging'
		IF @DetailLogging = '1'
		BEGIN
        UPDATE MFClass SET [IncludeInApp] = 1 WHERE name = 'User Messages'

		END
	

		
		-----------------------------------------------------
		--Update MFClassProperty.MFclass_ID with MFClass.ID
		-----------------------------------------------------
            UPDATE  MFClassProperty
            SET     MFClass_ID = MFClass.ID
            FROM    MFClassProperty
                    INNER JOIN MFClass ON MFClassProperty.MFClass_ID = MFClass.MFID
                                          AND MFClass.MFID <> -101;

            --SELECT  @ProcedureStep = 'ADD CONSTRAINT';

            --IF @Debug = 1
            --    BEGIN
            --        RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 

            --    END;

            SET @ProcedureStep = 'Check for duplicate Tablenames';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep); 
                    --SELECT  t.TableName AS TableName
                    --FROM    dbo.MFClass t
                    --WHERE   t.Deleted = 0
                    --GROUP BY t.TableName
                    --HAVING  COUNT(t.TableName) > 1;
                END;

            IF @Debug = 1
                BEGIN
--				SELECT 'BeforeDuplicates',* FROM [dbo].[MFClass] AS [mc];
                    DECLARE @DupCount INT;
                    SELECT  @DupCount = COUNT(*)
                    FROM    ( SELECT    t.TableName AS TableName
                              FROM      dbo.MFClass t
                              WHERE     t.Deleted = 0
                              GROUP BY  t.TableName
                              HAVING    COUNT(t.TableName) > 1
                            ) m;
					
                    RAISERROR('%s : Step %s Count of duplicates %i',10,1,@ProcedureName,@ProcedureStep, @DupCount); 
                    
                END;

            IF OBJECT_ID('tempdb..#Duplicate01') IS NOT NULL
                DROP TABLE #Duplicate01;

            CREATE TABLE #Duplicate01
                (
                  [MFID] INT ,
                  [TableName] VARCHAR(100) ,
                  [Name] VARCHAR(100) ,
                  [RowNumber] INT
                );
				
            IF ( SELECT COUNT(*)
                 FROM   ( SELECT    t.TableName
                          FROM      dbo.MFClass t
                          WHERE     t.Deleted = 0
                          GROUP BY  t.TableName
                          HAVING    COUNT(t.TableName) > 1
                        ) m
               ) > 0
                BEGIN
                    INSERT  INTO #Duplicate01
                            SELECT  [Duplicate].[MFID] ,
                                    [Duplicate].[TableName] ,
                                    [Duplicate].[Name] ,
                                    [Duplicate].[RowNumber]
                            FROM    ( SELECT    mfp.MFID ,
                                                mfp.TableName ,
                                                mfp.Name ,
                                                ROW_NUMBER() OVER ( PARTITION BY mfp.TableName ORDER BY mfp.MFID DESC ) AS RowNumber
                                      FROM      dbo.MFClass mfp
                                      WHERE     mfp.TableName IN (
                                                SELECT  t.TableName
                                                FROM    dbo.MFClass t
                                                GROUP BY t.TableName
                                                HAVING  COUNT(t.TableName) > 1 )
                                    ) Duplicate;

                    DECLARE @ClassName NVARCHAR(128);

                    SELECT  @ProcedureStep = '#Duplicate list';

                    IF @Debug = 1
                        BEGIN
                            RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                            --SELECT DISTINCT
                            --        *
                            --FROM    [#Duplicate01]; 
                        END;
                END;

			  ---------------------------------------------
			  --INSERT DUPLICATE DETAILS INTO MFLog TABLE
			  ---------------------------------------------

            SELECT  @ProcedureStep = 'Insert duplicate report into MFLog';

           
            IF @Debug = 1
                BEGIN
                    --SELECT  COUNT(*)
                    --FROM    #Duplicate01 AS [d];
                    RAISERROR('%s : Step %s ',10,1,@ProcedureName,@ProcedureStep);      
                END;

            IF ( SELECT COUNT(*)
                 FROM   #Duplicate01
               ) > 0
                BEGIN
             
                    DECLARE ClassNames CURSOR LOCAL
                    FOR
                        SELECT DISTINCT
                                Name
                        FROM    #Duplicate01; 

                    OPEN ClassNames;

			  --------------------------------------------------------------------------------
			  --CURSOR IS USED TO INORDER TO GET EMAIL NOTIFICATION FOR EACH NEW RECORD
			  --------------------------------------------------------------------------------
                    FETCH NEXT
			  FROM ClassNames
			  INTO @ClassName;

                    WHILE @@FETCH_STATUS = 0
                        BEGIN
				  -----------------------------------------
				  --INSERT INTO MFLog
				  -----------------------------------------
                            INSERT  INTO MFLog
                                    ( SPName ,
                                      ErrorMessage ,
                                      ProcedureStep
					                )
                            VALUES  ( 'spMFInsertClass' ,
                                      'More than one class found with name '
                                      + @ClassName
                                      + ' , Table name for the specified class is automatically renamed.' ,
                                      'Duplicate Table name'
					                );

                            FETCH NEXT
				  FROM ClassNames
				  INTO @ClassName;
                        END;

                    CLOSE ClassNames;

                    DEALLOCATE ClassNames;
                END;

--------------Update name of duplicates

            SELECT  @ProcedureStep = 'Update Name of duplicates';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                           
                END;

            IF ( SELECT COUNT(*)
                 FROM   #Duplicate01
               ) > 0
                BEGIN

                    UPDATE  mfp
                    SET     mfp.TableName = CASE WHEN ( ISNUMERIC(RIGHT(mfp.TableName,
                                                              1)) <> 0 )
                                                 THEN REPLACE(mfp.TableName,
                                                              RIGHT(mfp.TableName,
                                                              1),
                                                              CAST(CAST(RIGHT(mfp.TableName,
                                                              1) AS INT) + 1 AS NVARCHAR(10)))
                                                 ELSE mfp.TableName + '0'
                                                      + CAST(( SELECT
                                                              MAX(#Duplicate01.RowNumber)
                                                              - 1
                                                              FROM
                                                              #Duplicate01
                                                              WHERE
                                                              #Duplicate01.TableName = mfp.TableName
                                                             ) AS NVARCHAR(10)) --APPEND NUMBER LIKE TableName01
                                            END
                    FROM    dbo.MFClass mfp
                            INNER JOIN #Duplicate01 dp ON mfp.MFID = dp.MFID
                                                          AND dp.RowNumber = 1; --SELECT FIRST PROPERTY

                    DROP TABLE #Duplicate01;
                
                END;

--------------------Drop Temp tables

            SELECT  @ProcedureStep = 'Drop Temp Tables';

            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
                           
                END;
                
            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#ClassesTble' )
                BEGIN
                    DROP TABLE #ClassesTble;
                END;

            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#CurrentMFClass' )
                BEGIN
                    DROP TABLE #CurrentMFClass;
                END;

            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#ClassesTble' )
                BEGIN
                    DROP TABLE #ClassesTble;
                END;

            IF EXISTS ( SELECT  *
                        FROM    sysobjects
                        WHERE   name = '#CurrentMFClass' )
                BEGIN
                    DROP TABLE #CurrentMFClass;
                END;

            SELECT  @ProcedureStep = 'END Insert Classes';
            DECLARE @Result_Returned INT;
            SET @Result_Returned = 1;
            IF @Debug = 1
                BEGIN
                    RAISERROR('%s : Step %s Return %i',10,1,@ProcedureName,@ProcedureStep, @Result_Returned);
                END;

            SET NOCOUNT ON;
            RETURN 1
        END TRY

        BEGIN CATCH
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

