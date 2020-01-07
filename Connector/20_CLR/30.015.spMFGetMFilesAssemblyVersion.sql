
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetMFilesAssemblyVersion]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFGetMFilesAssemblyVersion'
-- nvarchar(100)
                                    ,@Object_Release = '4.4.13.53'
-- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFGetMFilesAssemblyVersion' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFGetMFilesAssemblyVersion]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFGetMFilesAssemblyVersion]
    @IsUpdateAssembly BIT = 0 OUTPUT
   ,@MFilesVersion VARCHAR(100) OUTPUT
AS
/*rST**************************************************************************

============================
spMFGetMFilesAssemblyVersion
============================

Return
  - 1 = Success
  - 0 = Error
Parameters
  @IsUpdateAssembly bit (output)
    - Default = 0
    - Returns 1 if M-Files version on the M-Files Server is different from MFSettings
  @MFilesVersion varchar(100) (output)
    - Returns M-Files version on the M-Files Server


Purpose
=======

The purpose of this procedure is to validate the M-Files version and return 1 if different

Additional Info
===============

Used by other procedures.


Warnings
========

This procedure returns to M-Files Version on the M-Files Server and not the SQL Server
When the procedure to update the assemblies fail, the CLR will have been deleted with reinstatement. When this happens the MFiles version must be updated manually in MFSettings table.

Examples
========

.. code:: sql

    Declare @rt int, @MFilesVersion nvarchar(25)
    Exec @rt = spMFGetMFilesAssemblyVersion @MFilesVersion = @MFilesVersion output
    Select @rt, @MFilesVersion

    Select * from MFsettings where name = 'MFVersion'

    UPDATE [dbo].[MFSettings]
    SET value = '19.8.8114.8' WHERE name = 'MFVersion'

    Exec spMFUpdateAssemblies

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-09-17  LC         Update documentation
2019-09-17  LC         Improve error trapping, add MFlog msg
2019-09-17  LC         Add condition to deal with scenario where CLR has been deleted
2019-08-30  JC         Added documentation
2019-05-19  LC         Block print of result
2018-09-27  LC         Remove licensing check. this procedure is excecuted before license is active
2018-04-04  DEV2       Added Licensing module validation code.
2015-03-27  DEV2       Create procedure
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

        -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFCheckAndUpdateAssemblyVersion';
    DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = '';
    DECLARE @Msg AS NVARCHAR(256) = '';

    ---------------------------------------------
    --DECLARE LOCAL VARIABLE
    --------------------------------------------- 
    DECLARE @VaultSettings  NVARCHAR(4000)
           ,@LsMFilesVersion VARCHAR(250)
           ,@DbMFileVersion VARCHAR(250);

    SELECT @VaultSettings = [dbo].[FnMFVaultSettings]();

    SELECT @DbMFileVersion = CAST([Value] AS VARCHAR(250))
    FROM [dbo].[MFSettings]
    WHERE [Name] = 'MFVersion';

    --		SELECT @DbMFileVersion

    -----------------------------------------------------------------
    -- Checking module access for CLR procdure  spmfGetMFilesVersionInternal
    ------------------------------------------------------------------
    IF
    (
        SELECT OBJECT_ID('dbo.spmfGetMFilesVersionInternal')
    ) IS NOT NULL
    BEGIN
        EXECUTE [spmfGetMFilesVersionInternal] @VaultSettings
                                              ,@LsMFilesVersion OUTPUT;

        SELECT @LsMFilesVersion;

        IF @LsMFilesVersion = @DbMFileVersion
        BEGIN
            SET @IsUpdateAssembly = 0;
            SET @MFilesVersion = @LsMFilesVersion;
        --			print 'Match'
        END; --if version match
        END -- if CLR exist
        ELSE
        BEGIN

            SELECT @MFilesVersion = CAST([ms].[Value] AS VARCHAR(100) )
            FROM [dbo].[MFSettings] AS [ms]
            WHERE [ms].[Name] = 'MFVersion';
            Set @Msg =  'Current version in MFSettings is ' + @MFilesVersion + '. Unable to find CLR spmfGetMFilesVersionInternal, manually update MFSettings with correct version, then run exec spMFUpdateAssemblies '

            SET @ProcedureStep = 'Catch CLR error ';

        INSERT INTO [dbo].[MFLog]
        (
            [SPName]
           ,[ErrorNumber]
           ,[ErrorMessage]
           ,[ErrorProcedure]
           ,[ProcedureStep]
           ,[ErrorState]
           ,[ErrorSeverity]
           ,[Update_ID]
           ,[ErrorLine]
        )
        VALUES
        ('spMFCheckAndUpdateAssemblyVersion', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep
        ,ERROR_STATE(), ERROR_SEVERITY(), null, ERROR_LINE());

            RAISERROR(@Msg,16,1);
        END;

    END;

GO