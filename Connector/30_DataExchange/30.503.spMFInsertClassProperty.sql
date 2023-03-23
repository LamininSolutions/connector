PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFInsertClassProperty]';
GO

SET NOCOUNT ON;
EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFInsertClassProperty', -- nvarchar(100)
                                 @Object_Release = '4.10.30.75',           -- varchar(50)
                                 @UpdateFlag = 2;                          -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFInsertClassProperty' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFInsertClassProperty
AS
SELECT 'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFInsertClassProperty
(
    @Doc NVARCHAR(MAX),
    @isFullUpdate BIT,
    @Output INT OUTPUT,
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
    XML data
  @isFullUpdate bit
    flag from calling procedure
  @Output int (output)
    output status
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

To insert Class property details into MFClassProperty table.  This is procedure is used internally only

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-03-21  LC         Enforce adding name_or_title to class, even if not required
2022-12-01  LC         Improve debugging logging and handling of properties
2022-09-07  LC         Introduce columns RetainIfNull and IsAdditional
2020-12-23  LC         Add class as a property 100
2019-08-30  JC         Added documentation
2017-09-11  LC         Resolve issue with constraints
2015-04-07  DEV2       Resolved synchronization issue (Bug 55)
==========  =========  ========================================================

**rST*************************************************************************/

SET NOCOUNT ON;

BEGIN TRY
    -----------------------------------------------------
    -- LOCAL VARIABLE DECLARATION
    -----------------------------------------------------
    DECLARE @IDoc INT,
            @ProcedureStep sysname = 'START',
            @ProcedureName sysname = 'spMFInsertClassProperty',
            @XML XML = @Doc;

DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		

            	SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			
			IF @debug > 0
				BEGIN
                SELECT CAST(@XML AS XML)
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END


    -----------------------------------------------------
    -- COPY CUSTOM DATA INTO TEMP TABLE

    -----------------------------------------------------    
    SELECT @ProcedureStep = 'Copy Custom data into temp table';

    IF (SELECT OBJECT_ID('tempdb..#TempClassProperty')) IS NOT NULL
    DROP TABLE #TempClassProperty;

     CREATE TABLE #TempClassProperty
    (
        MFClass_ID INT,
        MFProperty_ID INT,
        Required BIT,
        RetainIfNull BIT,
        IsAdditional BIT
    );
    INSERT INTO #TempClassProperty
    (
        MFClass_ID ,
        MFProperty_ID ,
        Required ,
        RetainIfNull ,
        IsAdditional
    )
    SELECT MFClass_ID,
           MFProperty_ID,
           Required ,
        RetainIfNull ,
        IsAdditional
           FROM dbo.MFClassProperty;

    -----------------------------------------------------
    -- GET CLASS PROPERTY INFORMATION FROM M-FILES

    -----------------------------------------------------   	   

        IF (SELECT OBJECT_ID('tempdb..#ClassProperty')) IS NOT NULL
    DROP TABLE #ClassProperty;

    CREATE TABLE #ClassProperty
    (
        MFClass_ID INT,
        MFProperty_ID INT,
        Required BIT,
        RetainIfNull BIT,
        IsAdditional BIT
    );

    SELECT @ProcedureStep = 'Inserting values into #ClassProperty';

    --------------------------------------------------------------
    -- INSERT DATA FROM XML INTO TEMPORARY TABLE 
    --------------------------------------------------------------          
    INSERT INTO #ClassProperty
    (
        MFClass_ID,
        MFProperty_ID,
        [Required],
        RetainIfNull,
        IsAdditional
    )
    SELECT distinct mc.id,
     mp.id,
          CASE when t.c.value('(@Required)[1]', 'varchar(10)') = 'true' THEN 1 ELSE 0 END AS [Required],
           1,
           0
    FROM @XML.nodes('/form/ClassProperty') AS t(c)
     inner JOIN dbo.MFClass mc
                ON t.c.value('(@classID)[1]', 'INT') = mc.MFID
            INNER JOIN dbo.MFProperty AS mp
                ON mp.MFID = t.c.value('(@PropertyID)[1]', 'INT');

    SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			
			IF @debug > 0
				BEGIN
                 SELECT * FROM #ClassProperty AS cp;
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END


    ---------------------------------------------------------------
    ---- insert additional properties properties
    ---------------------------------------------------------------
  
  
  SET @ProcedureStep = 'insert additional properties'
  DECLARE @AdditionalProperties NVARCHAR(MAX) = '22,27,38,39,100'

  SET @DebugText = ' Additional properties %i '
			Set @DebugText = @DefaultDebugText + @DebugText

			
			IF @debug > 0
				BEGIN
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@AdditionalProperties );
				END

;WITH cte AS
                (SELECT cp.MFClass_ID FROM #ClassProperty AS cp
                GROUP BY cp.MFClass_ID)
    INSERT  INTO [#ClassProperty]
                    ( [MFClass_ID] ,
                           [MFProperty_ID] ,
                      [Required],
        RetainIfNull,
        IsAdditional
                    )SELECT DISTINCT cte.MFClass_ID,p.id,1,1,0  FROM mfproperty p
                    CROSS APPLY cte
                    INNER JOIN dbo.fnMFParseDelimitedString(@AdditionalProperties,',') AS fmpds
                    ON fmpds.ListItem = p.MFID
                    LEFT JOIN #ClassProperty AS cp                   
                    ON p.id = cp.MFProperty_ID
                    WHERE cp.MFProperty_ID IS null

                     SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			
			IF @debug > 0
				BEGIN
                 SELECT cp.MFClass_ID,p.mfid, p.ColumnName FROM #ClassProperty AS cp
                 LEFT JOIN dbo.MFProperty p
                 ON cp.MFProperty_ID = p.id
                 LEFT JOIN dbo.fnMFParseDelimitedString(@AdditionalProperties,',') AS fmpds
                 ON p.mfid = fmpds.ListItem
                 ORDER BY cp.MFClass_ID;
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

    -------------------------------------------------------------
    -- add additional properties by class
    -------------------------------------------------------------

     SET @ProcedureStep = 'add non standard properties';


          INSERT INTO #ClassProperty
          (
              MFClass_ID,
              MFProperty_ID,
              Required,
              RetainIfNull,
              IsAdditional
          )
        SELECT DISTINCT mc.ID MFclass_ID,
               mp.ID MFProperty_ID,
               CASE WHEN mp.mfid < 999 THEN 1 ELSE 0 END,
               RetainIfNull = 0,
               CASE WHEN mp.mfid < 999 THEN 0 ELSE 1 END           
        FROM sys.tables AS t
         INNER JOIN  dbo.MFClass mc
                ON mc.TableName = t.name
            INNER JOIN sys.columns c
                ON c.object_id = t.object_id
            INNER JOIN dbo.MFProperty AS mp
                ON c.name = mp.ColumnName
            LEFT JOIN #ClassProperty AS mcp
                ON mcp.MFClass_ID = mc.ID
                   AND mcp.MFProperty_ID = mp.ID
    WHERE mcp.MFClass_ID IS NULL   

    SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText

            -------------------------------------------------------------
            -- enforce property 0 - should always be present
            -------------------------------------------------------------

            declare @Name_or_title_id  int
            select @Name_or_title_id = id from dbo.MFProperty as mp where mfid = 0

            ;with cte as
            (
            select mcp.MFClass_ID from #ClassProperty mcp
                    
            group by mcp.MFClass_ID
            except
            select mcp.MFClass_ID from #ClassProperty mcp
                    left join dbo.MFProperty as mp
            on mp.ID = mcp.MFProperty_ID
            where mp.mfid = 0
            group by mcp.MFClass_ID
            )
            insert into #ClassProperty
            (
                MFClass_ID
              , MFProperty_ID
              , Required
              , RetainIfNull
              , IsAdditional
            )
            select MFClass_Id, @Name_or_title_id,0,1,1 from cte

	
			IF @debug > 0
				BEGIN
                  SELECT '#classProperty',
               mcp.*, mc.TableName, mc.mfid classmfid, mp.ColumnName, mp.mfid PropertyID
        FROM #ClassProperty AS mcp
         inner JOIN  dbo.MFClass AS mc
                ON mcp.MFClass_ID = mc.ID
            INNER JOIN dbo.MFProperty AS mp
                ON mp.ID = mcp.MFProperty_ID
                ORDER BY mc.mfid, mp.mfid;

					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

    -------------------------------------------------------------
    -- Update settings for RetainIfNull
    -------------------------------------------------------------
         SET @ProcedureStep = 'Update settings for RetainIfNull';


    UPDATE cp
    SET cp.RetainIfNull = tcp.RetainIfNull
    FROM #ClassProperty AS cp
    INNER JOIN #TempClassProperty AS tcp
    ON cp.MFClass_ID = tcp.MFClass_ID AND cp.MFProperty_ID = tcp.MFProperty_ID
    WHERE cp.RetainIfNull <> tcp.RetainIfNull

    SET @DebugText = ''
			Set @DebugText = @DefaultDebugText + @DebugText
			
			IF @debug > 0
				Begin
					RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
				END

   
    ------------------------------------------------------
    --Drop CONSTRAINT
    ------------------------------------------------------
    SET @ProcedureStep = 'Drop CONSTRAINT';
    IF @Debug > 0
    Begin
        RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
    End
    IF (SELECT OBJECT_ID('FK_MFClassProperty_MFClass', 'F')) IS NOT NULL
    BEGIN
        ALTER TABLE dbo.MFClassProperty
        DROP CONSTRAINT FK_MFClassProperty_MFClass;
    END;
    IF (SELECT OBJECT_ID('FK_MFClassProperty_MFClass_ID', 'F')) IS NOT NULL
    BEGIN
        ALTER TABLE dbo.MFClassProperty
        DROP CONSTRAINT FK_MFClassProperty_MFClass_ID;
    END;

    --------------------------------------------------------
    --UPDATE EXISTING CLASS PROPERTY
    --------------------------------------------------------
    SET @ProcedureStep = 'update MFCLassProperty';   
 --  BEGIN TRY

        --UPDATE dbo.MFClassProperty
        --SET Required = #ClassPpt.Required,
        --    RetainIfNull = cp.RetainIfNull
        --FROM dbo.MFClassProperty cp
        --    INNER JOIN #ClassPpt
        --        ON (
        --               cp.MFClass_ID = #ClassPpt.MFClass_ID
        --               AND cp.MFProperty_ID = #ClassPpt.MFProperty_ID
        --           );

        TRUNCATE TABLE dbo.MFClassProperty

        INSERT INTO dbo.MFClassProperty
        (
            MFClass_ID,
            MFProperty_ID,
            Required,
            RetainIfNull,
            IsAdditional
        )
        SELECT cp.MFClass_ID,
               cp.MFProperty_ID,
               cp.Required,
               cp.RetainIfNull,
               cp.IsAdditional FROM #ClassProperty AS cp
               WHERE cp.MFClass_ID IS NOT null

       --          SET @Output = 'Updated records ' + CAST(@@ROWCOUNT AS VARCHAR(10));

        IF @Debug > 0
        BEGIN
            RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);

        END;
    --END TRY
    --BEGIN CATCH
    --    RAISERROR('%s : Step %s Failed', 16, 1, @ProcedureName, @ProcedureStep);

    --END CATCH;


    ----------------------------------------------------------------
    ----Adding The new property 
    ----------------------------------------------------------------
    --BEGIN TRY
    --    SET @ProcedureStep = 'insert new items into MFCLassProperty';
    --    INSERT INTO dbo.MFClassProperty
    --    (
    --        MFClass_ID,
    --        MFProperty_ID,
    --        Required,
    --        RetainIfNull,
    --        IsAdditional
    --    )
    --    SELECT *
    --    FROM
    --    (
    --        SELECT MFClass_ID,
    --               MFProperty_ID,
    --               Required,
    --               RetainIfNull,
    --               IsAdditional
    --        FROM #ClassProperty
    --        EXCEPT
    --        SELECT MFClass_ID,
    --               MFProperty_ID,
    --               Required,
    --               RetainIfNull,
    --               IsAdditional
    --        FROM dbo.MFClassProperty
    --    ) newPprty;
        --SET @Output = @Output + @@ROWCOUNT;
        IF @Debug> 0
        BEGIN

            IF (@isFullUpdate = 1)
                SET @ProcedureStep = @ProcedureStep + ' Full Update';

            RAISERROR('%s : Step %s inserting %i rows', 10, 1, @ProcedureName, @ProcedureStep, @Output);

        END;
    --END TRY
    --BEGIN CATCH
    --    RAISERROR('%s : Step %s Failed', 16, 1, @ProcedureName, @ProcedureStep);
    --END CATCH;
    --------------------------------------------------------------
    -- Select MFID Which are deleted from M-Files 
    --------------------------------------------------------------
    --SET @ProcedureStep = 'Deletes objects from MFCLassProperty';
    --SELECT #DeletedWorkFlowStates.MFClass_ID,
    --       #DeletedWorkFlowStates.MFProperty_ID,
    --       #DeletedWorkFlowStates.Required
    --INTO #DeletedObjectTypes
    --FROM
    --(
    --    SELECT MFClass_ID,
    --           MFProperty_ID,
    --           Required
    --    FROM dbo.MFClassProperty
    --    EXCEPT
    --    SELECT MFClass_ID,
    --           MFProperty_ID,
    --           Required
    --    FROM #ClassProperty
    --) #DeletedWorkFlowStates;

    --IF @Debug = 1
    --BEGIN
    --    RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
    --    SELECT '#DeletedObjectTypes',
    --           *
    --    FROM #DeletedObjectTypes;
    --END;

    --------------------------------------------------------------
    --Deleting the Classproperty Thats deleted from M-Files 
    --------------------------------------------------------------

    --DELETE FROM dbo.MFClassProperty
    --WHERE MFProperty_ID IN
    --      (
    --          SELECT MFProperty_ID FROM #DeletedObjectTypes
    --      )
    --      AND MFClass_ID IN
    --          (
    --              SELECT MFClass_ID FROM #DeletedObjectTypes
    --          );


    --------------------------------------------------------------
    --Deleting the system Class for Reporting from ClassProperty 
    --------------------------------------------------------------
    --SET @ProcedureStep = 'Delete Report Class from MFCLassProperty';
    --IF @Debug = 1
    --BEGIN
    --    RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcedureStep);
    --    SELECT 'Report Class Deleted',
    --           *
    --    FROM dbo.MFClassProperty AS mcp;
    --END;


    -------------------------------------------------------------
    -- Update isAdditional columns
    -------------------------------------------------------------           
    --MERGE INTO dbo.MFClassProperty AS t
    --USING
    --(
    --    SELECT mc.ID MFclass_ID,
    --           mp.ID MFProperty_ID,
    --           mcp.Required,
    --           RetainIfNull = CASE
    --                              WHEN mcp.IsAdditional = 1 THEN
    --                                  mcp.RetainIfNull
    --                              WHEN mcp.Required = 1 THEN
    --                                  1
    --                              ELSE
    --                                  1
    --                          END,
    --           ISAdditional = CASE
    --                              WHEN mp.MFID < 999 THEN
    --                                  0
    --                              WHEN mcp.IsAdditional = 1 THEN
    --                                  0
    --                              ELSE
    --                                  0
    --                          END,
    --           mp.MFID,
    --           mc.TableName,
    --           mp.ColumnName
    --    FROM dbo.MFClass mc
    --        INNER JOIN sys.tables AS t
    --            ON mc.TableName = t.name
    --        INNER JOIN sys.columns c
    --            ON c.object_id = t.object_id
    --        INNER JOIN dbo.MFProperty AS mp
    --            ON c.name = mp.ColumnName
    --        LEFT JOIN dbo.MFClassProperty AS mcp
    --            ON mcp.MFClass_ID = mc.ID
    --               AND mcp.MFProperty_ID = mp.ID
    ----WHERE mp.mfid > 999
    --) s
    --ON s.MFclass_ID = t.MFClass_ID
    --   AND s.MFProperty_ID = t.MFProperty_ID
    --WHEN NOT MATCHED THEN
    --    INSERT
    --    (
    --        MFClass_ID,
    --        MFProperty_ID,
    --        Required,
    --        RetainIfNull,
    --        IsAdditional
    --    )
    --    VALUES
    --    (s.MFclass_ID, s.MFProperty_ID, 0, 0, 1)
    --WHEN MATCHED THEN
    --    UPDATE SET t.RetainIfNull = s.RetainIfNull;

    -------------------------------------------------------------
    -- Remove invalid class items
    -------------------------------------------------------------

    --IF
    --(
    --    SELECT COUNT(MFClass_ID)FROM dbo.MFClassProperty WHERE MFClass_ID = 0
    --) > 0
    --    DELETE FROM dbo.MFClassProperty
    --    WHERE MFClass_ID = 0;




    --------------------------------------------------------------
    --Droping all temporary Tables
    --------------------------------------------------------------
    DROP TABLE #TempClassProperty;
    DROP TABLE #ClassProperty;


    SELECT @ProcedureStep = 'END Insert ClassProperty Properties';

    IF @Debug > 0
    BEGIN
        RAISERROR('%s : Step %s Return 1', 10, 1, @ProcedureName, @ProcedureStep);
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
        INSERT INTO dbo.MFLog
        (
            SPName,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ErrorState,
            ErrorSeverity,
            ErrorLine,
            ProcedureStep
        )
        VALUES
        (@ProcedureName, ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
         ERROR_LINE(), @ProcedureStep);
    END;

    DECLARE @ErrNum INT = ERROR_NUMBER(),
            @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE(),
            @ErrSeverity INT = ERROR_SEVERITY(),
            @ErrState INT = ERROR_STATE(),
            @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE(),
            @ErrLine INT = ERROR_LINE();

    SET NOCOUNT OFF;

    RAISERROR(@ErrMessage, @ErrSeverity, @ErrState, @ErrProcedure, @ErrState, @ErrMessage);
END CATCH;
GO
