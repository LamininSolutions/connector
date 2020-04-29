PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeProperties]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeProperties', -- nvarchar(100)
    @Object_Release = '4.6.17.58',              -- varchar(50)
    @UpdateFlag = 2;                            -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFSynchronizeProperties' --name of procedure
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
CREATE PROCEDURE dbo.spMFSynchronizeProperties
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFSynchronizeProperties
(
    @VaultSettings NVARCHAR(4000),
    @Debug SMALLINT,
    @Out NVARCHAR(MAX) OUTPUT,
    @IsUpdate SMALLINT = 0
)
AS
/*rST**************************************************************************

=========================
spMFSynchronizeProperties
=========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @VaultSettings nvarchar(4000)
    Vault login credentials
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
  @Out nvarchar(max) (output)
    output of spmfInsertProperty
  @IsUpdate smallint
    when set to 1 the procedure will perform full update


Purpose
=======
This is an internal procedure and is part of the metadata synchronisation process

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-04-07  LC         Resolve issue with synchronise properties
2019-08-30  JC         Added documentation
2016-09-26  DevTeam2   Removed vaultsettings parameters and pass them as 
                       comma separated string in @VaultSettings parameter
2018-04-04 DevTeam2    Added License module validation code
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------
    --DECLARE LOCAL VARIABLE
    --------------------------------------------- 
    DECLARE @Xml       NVARCHAR(MAX),
        @Output        INT          = 0,
        @ProcessStep   VARCHAR(100) = 'Start',
        @ProcedureName sysname      = 'spMFSynchronizeProperties',
        @Result_Value  INT;

    BEGIN TRY

        -----------------------------------------------------------------
        -- Checking module access for CLR procdure  spMFGetProperty
        ------------------------------------------------------------------
        EXEC dbo.spMFCheckLicenseStatus 'spMFGetProperty',
            @ProcedureName,
            'Validating module access for clr procedure spMFGetProperty';

        ------------------------------------------------------------
        --CALL WRAPPER PROCEDURE TO GET PROPERTY DETAILS FROM M-FILES
        -------------------------------------------------------------
        SET @ProcessStep = 'Run spmfGetProperty';

        EXEC dbo.spMFGetProperty @VaultSettings, @Xml OUTPUT;

        IF @Debug > 0
            SELECT @Xml;
    END TRY
    BEGIN CATCH
        -- SELECT  @Xml;
        RAISERROR('%s : Step %s Error Getting Properties', 16, 1, @ProcedureName, @ProcessStep);
    END CATCH;

    -------------------------------------------------------------------------
    -- CALL 'spMFInsertProperty' 
    ------------------------------------------------------------------------- 
    BEGIN TRY
        IF @IsUpdate = 1 --full update
        BEGIN
            SET @ProcessStep = 'Update properties';

            SELECT ID,
                Name,
                Alias,
                MFID,
                ColumnName,
                MFDataType_ID,
                PredefinedOrAutomatic,
                MFValueList_ID
            INTO #TempMFProperty
            FROM dbo.MFProperty
            WHERE Deleted = 0;

            EXEC @Result_Value = dbo.spMFInsertProperty @Xml,
                1, --IsFullUpdate Set to TRUE  
                @Output OUTPUT,
                @Debug;

            --				SET @ProcedureName = 'Exec spMFSynchronizeProperties';
            DECLARE @PropXML NVARCHAR(MAX);

            SET @PropXML =
            (
                SELECT ISNULL(TMP.ID, 0)         AS [PropDetails/@ID],
                    ISNULL(TMP.Name, '')         AS [PropDetails/@Name],
                    ISNULL(TMP.Alias, '')        AS [PropDetails/@Alias],
                    ISNULL(TMP.MFID, 0)          AS [PropDetails/@MFID],
                    ISNULL(TMP.ColumnName, '')   AS [PropDetails/@ColumnName],
                    ISNULL(TMP.MFDataType_ID, 0) AS [PropDetails/@MFDataType_ID],
                    CASE
                        WHEN ISNULL(TMP.PredefinedOrAutomatic, 0) = 0 THEN
                            'false'
                        ELSE
                            'true'
                    END                          AS [PropDetails/@PredefinedOrAutomatic]
                --			,ISNULL(tmp.[MFValueList_ID],0)  AS [PropDetails/@ValuelistID]
                FROM dbo.MFProperty            AS MP
                    INNER JOIN #TempMFProperty AS TMP
                        ON MP.MFID = TMP.MFID
                           AND
                           (
                               MP.Alias != TMP.Alias
                               OR MP.Name != TMP.Name
                           )
                FOR XML PATH(''), ROOT('Prop')
            );

            --				SET @ProcedureName = 'Exec [spMFUpdateProperty] ';

            -----------------------------------------------------------------
            -- Checking module access for CLR procdure  spMFUpdateProperty
            ------------------------------------------------------------------
            --		     EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdateProperty',@ProcedureName,'Validating module access for clr procedure spMFUpdateProperty'
            EXEC dbo.spMFUpdateProperty @VaultSettings, @PropXML, @Output OUTPUT;

            --				SET @ProcedureName = 'Exec [spMFSynchronizeProperties] ';
            UPDATE MP
            SET MP.Alias = TMP.Alias,
                MP.Name = TMP.Name
            FROM dbo.MFProperty            AS MP
                INNER JOIN #TempMFProperty AS TMP
                    ON MP.MFID = TMP.MFID;

            DROP TABLE #TempMFProperty;
        END;
        ELSE
        BEGIN
            EXEC @Result_Value = dbo.spMFInsertProperty @Xml,
                1, --IsFullUpdate Set to TRUE  
                @Output OUTPUT,
                @Debug;
        END;

        SET @ProcessStep = 'Insert existing Properties in temp table';

        UPDATE mp
        SET mp.MFValueList_ID = mvl.ID
        --SELECT mp.[MFValueList_ID] , mvl.[ID] , *
        FROM dbo.MFValueList          AS mvl
            INNER JOIN dbo.MFProperty AS mp
                ON mp.Name = mvl.Name
                   AND mp.MFDataType_ID IN ( 8, 9 )
        WHERE mp.Name = mvl.Name;

        IF @Debug > 0
            RAISERROR('%s : Step %s @Result_Value %i', 10, 1, @ProcedureName, @ProcessStep, @Result_Value);

        IF (@Output > 0 AND @Result_Value = 1)
            SET @Out = 'All Properties are Updated';

        IF (ISNULL(@Output, 0) = 0 AND @Result_Value = 1)
            SET @Out = 'All Properties are up to date';

        IF @Result_Value <> 1
            RAISERROR('%s : Step %s Syncronisation failed to Insert Property', 16, 1, @ProcedureName, @ProcessStep);

        IF @Debug > 0
            RAISERROR('%s : Step %s @Result_Value %s', 10, 1, @ProcedureName, @ProcessStep, @Out);

        SET NOCOUNT OFF;

        RETURN 1;
    END TRY
    BEGIN CATCH
        --	ROLLBACK TRANSACTION
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
                ERROR_LINE(), @ProcessStep);
        END;

        DECLARE @ErrNum   INT           = ERROR_NUMBER(),
            @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE(),
            @ErrSeverity  INT           = ERROR_SEVERITY(),
            @ErrState     INT           = ERROR_STATE(),
            @ErrMessage   NVARCHAR(MAX) = ERROR_MESSAGE(),
            @ErrLine      INT           = ERROR_LINE();

        SET NOCOUNT OFF;

        RAISERROR(@ErrMessage, @ErrSeverity, @ErrState, @ErrProcedure, @ErrState, @ErrMessage);
    END CATCH;
END;
GO