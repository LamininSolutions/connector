PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateWorkflowStateLookupView]';
GO

SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFCreateWorkflowStateLookupView', -- nvarchar(100)
                                     @Object_Release = '3.1.5.41',                       -- varchar(50)
                                     @UpdateFlag = 2;                                    -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFCreateWorkflowStateLookupView' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    DROP PROC [dbo].[spMFCreateWorkflowStateLookupView];
    PRINT SPACE(10) + '...Stored Procedure: dropped and recreated';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO


-- the following section will be always executed
SET NOEXEC OFF;
GO

CREATE PROCEDURE [dbo].[spMFCreateWorkflowStateLookupView]
(
    @WorkflowName NVARCHAR(128),
    @ViewName NVARCHAR(128),
    @Schema NVARCHAR(20) = 'dbo',
    @Debug SMALLINT = 0
)
AS
/*******************************************************************************
  ** Desc:  The purpose of this procedure is to easily create one or more SQL Views to be used as lookup sources
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **      
  
  **
  ** Author:          Thejus T V
  ** Date:            15/07/2015 
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 20-07-2015  DEV 2	   New Logic implemented
   ** 12-5-2017		LC			add deleted = 0 as filter
   ** 1-6-2017		LC		add ID columns, change naming of columns to align with valuelist views, remove
    deleted as filter
  ** 2017-12-10		lc			Add Schema
  ** 2018-05-20		LC			add error check if workflow does not exist
  ******************************************************************************/
BEGIN
    BEGIN TRY
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;

        -------------------------------------------------------------
        -- Validate that workflow exist
        -------------------------------------------------------------

        IF
        (
            SELECT COUNT(*)
            FROM [dbo].[MFWorkflow] AS [mw]
            WHERE [mw].[Name] = @WorkflowName
        ) = 1
        BEGIN

            DECLARE @Query NVARCHAR(2500),
                    @OwnerTableJoin NVARCHAR(250),
                    @ProcedureStep sysname = 'Start';
            -----------------------------------------
            --DROP THE EXISTSING VIEW
            -----------------------------------------
            DECLARE @object NVARCHAR(100);
            SET @object = DB_NAME() + '.' + QUOTENAME(@Schema) + '.' + QUOTENAME(@ViewName);

            IF
            (
                SELECT OBJECT_ID(@object, 'V')
            ) IS NOT NULL
            BEGIN

                -----------------------------------------
                --DEFINE DYNAMIC QUERY
                -----------------------------------------


                DECLARE @DropQuery NVARCHAR(100) = 'DROP VIEW ' + QUOTENAME(@Schema) + '.' + QUOTENAME(@ViewName) + '';

                SELECT @ProcedureStep = 'DROP EXISTING VIEW';

                IF @Debug > 0
                    SELECT 'view dropped';
                -----------------------------------------
                --EXECUTE DYNAMIC QUERY
                -----------------------------------------
                EXECUTE (@DropQuery);


            END;

            SELECT @ProcedureStep = 'Set Dynamic query';


            ------------------------------------------------------
            --DEFINE DYNAMIC QUERY TO CREATE VIEW
            ------------------------------------------------------

            SELECT @Query
                = 'CREATE VIEW ' + @Schema + '.' + QUOTENAME(@ViewName)
                  + '
 AS
					    SELECT  
                            [mwf].[Name] AS Name_Workflow ,
                            [mwf].[Alias] AS Alias_Workflow ,
                            [mwf].[MFID] AS MFID_Workflow,  
							[mwf].[ID] AS ID_Workflow,                       
                            [mwfs].[Name] AS Name_State ,
                            [mwfs].[Alias] AS Alias_State,
                            [mwfs].[MFID] AS MFID_State,
							[mwfs].[ID] AS ID_State,
							[mwfs].[Deleted] AS Deleted_State
                         
    FROM    [dbo].[MFWorkflow] AS [mwf]
            INNER JOIN [dbo].[MFWorkflowState] AS [mwfs] ON [mwfs].[MFWorkflowID] = [mwf].[ID]
 
  WHERE    mwf.Name = '''   + @WorkflowName + '''';



            IF @Debug > 0
                SELECT @ProcedureStep AS [ProcedureStep],
                       @Query AS [QUERY];

            SELECT @ProcedureStep = 'EXECUTE DYNAMIC QUERY';

            --------------------------------
            --EXECUTE DYNAMIC QUERY
            --------------------------------
            EXECUTE (@Query);
            IF EXISTS (SELECT * FROM [sys].[views] WHERE [name] = @ViewName)
            BEGIN
                RETURN 1; --SUCESS
            END;
        END;
        ELSE
            DECLARE @DebugMessage NVARCHAR(100);
        SET @DebugMessage = 'Workflowname: ' + @WorkflowName + ' Does not exist or is a duplicate';
        RAISERROR(@DebugMessage, 16, 1);
        RETURN 0;

    END TRY
    BEGIN CATCH
        SET NOCOUNT ON;

        IF @Debug > 0
            SELECT 'spMFCreateValueListLookupView',
                   ERROR_NUMBER(),
                   ERROR_MESSAGE(),
                   ERROR_PROCEDURE(),
                   ERROR_STATE(),
                   ERROR_SEVERITY(),
                   ERROR_LINE(),
                   @ProcedureStep;

        --------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        --------------------------------------------------
        INSERT INTO [dbo].[MFLog]
        (
            [SPName],
            [ErrorNumber],
            [ErrorMessage],
            [ErrorProcedure],
            [ErrorState],
            [ErrorSeverity],
            [ErrorLine],
            [ProcedureStep]
        )
        VALUES
        ('spMFCreateLookupView', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
         ERROR_LINE(), @ProcedureStep);

        RETURN 2; --FAILURE
    END CATCH;
END;
GO
