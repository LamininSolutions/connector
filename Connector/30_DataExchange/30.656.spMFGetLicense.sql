PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetLicense]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFGetLicense', -- nvarchar(100)
    @Object_Release = '4.8.24.66',
    @UpdateFlag = 2;
GO

/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
----------------------------------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFGetLicense' --name of procedure
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
CREATE PROCEDURE dbo.spMFGetLicense
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFGetLicense
(
    @ModuleID NVARCHAR(10),
    @ExpiryDate DATETIME OUTPUT,
    @Errorcode NVARCHAR(10) output,
    @CheckStatus INT OUTPUT,
    @Status NVARCHAR(100) OUTPUT,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

===============
spMFGetLicense
===============

Return
  - 1 = Success
  - -1 = Error

Parameters
  @ModuleID nvarchar(10)
   input module to check
  @ExpiryDate datetime output
    output expiry date
    null of not exist
  @CheckStatus int output
    output precheck status
  @Status nvarchar(100) output
    output text for status
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

This is a internal procedure
Procedure is used as part of the license validation routine called by spMFCheckLicenseStatus
Execute spMFValidateModule and return the interpreted result

Examples
========

.. code:: sql

    DECLARE @ExpiryDate DATETIME,
    @Errorcode      NVARCHAR(10),
    @CheckStatus    INT,
    @Status         NVARCHAR(100);

    EXEC dbo.spMFGetLicense @ModuleID = 1,
    @ExpiryDate = @ExpiryDate OUTPUT,
    @Errorcode = @Errorcode OUTPUT,
    @CheckStatus = @CheckStatus OUTPUT,
    @Status = @Status OUTPUT,
    @Debug = 0;

    SELECT @ExpiryDate ExpiryDate,
    @Errorcode     Errorcode,
    @CheckStatus   Checkstatus,
    @Status        Status;

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-12-04  LC         Create procedure to aid spMFChecklicense status
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- CONSTANTS: MFSQL Class Table Specific
    -------------------------------------------------------------
    DECLARE @ProcessType AS NVARCHAR(50);

    SET @ProcessType = ISNULL(@ProcessType, 'Get License');

    -------------------------------------------------------------
    -- VARIABLES: T-SQL Processing
    -------------------------------------------------------------
    DECLARE @rowcount AS INT = 0;
    DECLARE @return_value AS INT = 0;
    DECLARE @error AS INT = 0;
    DECLARE @VaultSettings NVARCHAR(2000);
    DECLARE @LicenseExpiryTXT NVARCHAR(10);
    DECLARE @CurrentDate DATE;
    DECLARE @DaysToExpiry INT;
    -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = N'dbo.spMFGetLicense';
    DECLARE @ProcedureStep AS NVARCHAR(128) = N'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';
    DECLARE @Msg AS NVARCHAR(256) = N'';
    DECLARE @MsgSeverityInfo AS TINYINT = 10;
    DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
    DECLARE @MsgSeverityGeneralError AS TINYINT = 16;

    -------------------------------------------------------------
    -- VARIABLES: DYNAMIC SQL
    -------------------------------------------------------------
    DECLARE @sql NVARCHAR(MAX) = N'';
    DECLARE @sqlParam NVARCHAR(MAX) = N'';

    BEGIN TRY
        -------------------------------------------------------------
        -- BEGIN PROCESS
        -------------------------------------------------------------
        SET @DebugText = N'';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Begin process';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- Get settings
        -------------------------------------------------------------
        SELECT @VaultSettings = dbo.FnMFVaultSettings();

        SET @ProcedureStep = 'Validate module'
       
       EXEC dbo.spMFValidateModule @VaultSettings = @VaultSettings,
            @ModuleID = @ModuleID,
            @Status = @Status OUTPUT;

        SET @DebugText = N' Returned license module %s Status %s  ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID, @Status);
        END;

        -------------------------------------------------------------
        -- parse result
        -------------------------------------------------------------
        SET @ProcedureStep = 'Parse result'

            /*
    returns delimited string with validity code and licnese expiry date
    1 = module exist in license; 
    2 = with no date if license expired
    3 = module does not exist in license; 
    4 no license exist (no date returned)
    */

        SELECT @errorCode = fmss.ListItem
        FROM dbo.fnMFParseDelimitedString(@Status, '|') AS fmss
        WHERE fmss.ID = 1;

        SELECT @LicenseExpiryTXT = fmss.ListItem
        FROM dbo.fnMFParseDelimitedString(@Status, '|') AS fmss
        WHERE fmss.ID = 2;

        
        SET @DebugText = N' Error %s ExpiryDate %s  ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @error, @LicenseExpiryTXT);
        END;

        -------------------------------------------------------------
        -- validate date
        -------------------------------------------------------------
                SET @ProcedureStep = 'Validate date'

        --convert license expiry date to date format
        SELECT @ExpiryDate = CASE
                                 WHEN LEN(@LicenseExpiryTXT) > 0 THEN
                                     dbo.fnMFTextToDate(@LicenseExpiryTXT, '/')
                                 ELSE
                                     NULL
                             END;

        SET @CurrentDate = CONVERT(DATE, DATEADD(DAY, 1, GETDATE()));
        SET @DaysToExpiry = CASE
                                WHEN @ExpiryDate IS NULL THEN
                                    0
                                ELSE
                                    DATEDIFF(DAY,  @CurrentDate,@ExpiryDate)
                            END;

        SET @DebugText = N' Days to expire ' + CAST(@DaysToExpiry AS NVARCHAR(10));
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;

        -------------------------------------------------------------
        -- set check status
        -------------------------------------------------------------
                SET @ProcedureStep = 'Get check status'

        SELECT @CheckStatus = CASE
                                  WHEN @errorCode = '3' THEN
                                      2 --module does not exist
                                  WHEN @errorCode = '1'
                                       AND @DaysToExpiry > 30 THEN
                                      10
                                  WHEN @errorCode = '1'
                                       AND @DaysToExpiry < 30 THEN
                                      9
                                  WHEN @errorCode = '2'
                                       OR @DaysToExpiry = 0 THEN
                                      7
                                  WHEN @errorCode = '4' THEN
                                      8
                                  ELSE
                                      @CheckStatus
                              END;

        SET @DebugText = N' CheckStatus %i  ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ModuleID, @CheckStatus);
        END;

        -------------------------------------------------------------
        -- set status
        -------------------------------------------------------------
                SET @ProcedureStep = 'Set status'

        SELECT @Status = CASE
                             WHEN @CheckStatus = 10 THEN
                                 N'License is valid and requires re-validation '
                             WHEN @CheckStatus = 9 THEN
                                 N'License is due to expire on ' + @LicenseExpiryTXT
                             WHEN @CheckStatus = 7 THEN
                                 N'License validation - expired '
                             WHEN @CheckStatus = 8 THEN
                                 N'License validation not exist '
                             WHEN @CheckStatus = 2 THEN
                                 N'Module does not exist '
                             ELSE
                                 'Status not verified'
                         END;

        SET @DebugText = N' Status %s  ';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            SELECT @ExpiryDate AS expirydate,
                @errorCode         AS StatusError,
                @CheckStatus   AS checkstatus;

            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @Status);
        END;

        -------------------------------------------------------------
        --END PROCESS
        -------------------------------------------------------------
        END_RUN:
        SET @ProcedureStep = N'End';

        -------------------------------------------------------------
        -- Log End of Process
        -------------------------------------------------------------   
        RETURN @Errorcode;
    END TRY
    BEGIN CATCH
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

        RETURN -1;
    END CATCH;
END;
GO