
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckAssemblyVersion]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl] @SchemaName = N'dbo'
                                    ,@ObjectName = N'spMFCheckAndUpdateAssemblyVersion'
-- nvarchar(100)
                                    ,@Object_Release = '4.4.11.51'
-- varchar(50)
                                    ,@UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFCheckAndUPdateAssemblyVersion' --name of procedure
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
CREATE PROCEDURE [dbo].[spMFCheckAndUpdateAssemblyVersion]
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFCheckAndUpdateAssemblyVersion] (@Debug INT = 0)
AS
/*rST**************************************************************************

=================================
spMFCheckAndUpdateAssemblyVersion
=================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Debug int (optional)
    - Default = 0
    - 1 = Standard Debug Mode


Purpose
=======
The purpose of this procedure is to check  M-Files Version and update the assemblies.

Additional Info
===============
This procedure is used in the Agent to automatically update the assemblies

Prerequisites
=============
M-Files version on SQL Server is the same as M-Files Server

Warnings
========
This procedure will fail if the SQL Server and M-Files Server have different M-Files versions.

Examples
========
.. code:: sql

    Exec spMFCheckAndUpdateAssemblyVersion

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2016-12-28  DEV2       Create Procedure
2018-09-27  LC         Change procedure to work with Release 4 scripts
2019-05-19  LC         Fix bug - insert null value in MFsettings not allowed
2019-07-25  LC         Add more debug and error trapping, fix issue to prevent update
2019-08-30  JC         Added documentation
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

    BEGIN TRY
        ---------------------------------------------
        DECLARE @IsVersionMisMatch BIT = 0
               ,@MFilesVersion     VARCHAR(100)
               ,@MFilesOldVersion  VARCHAR(100)
               ,@Update_ID         INT
               ,@Username          NVARCHAR(2000)
               ,@RC                INT
               ,@VaultName         NVARCHAR(2000);

        SELECT TOP 1
               @Username  = [Username]
              ,@VaultName = [VaultName]
        FROM [dbo].[MFVaultSettings];

        SET @ProcedureStep = 'Get Install assembly Version M-Files ';

        EXEC @RC = [dbo].[spMFGetMFilesAssemblyVersion] @IsVersionMisMatch OUTPUT
                                                       ,@MFilesVersion OUTPUT;

DECLARE @Mismatch NVARCHAR(10)
SET @Mismatch = CASE WHEN @IsVersionMisMatch = 1 THEN 'Yes' ELSE 'No' end
        SET @DebugText = 'Get assembly version Return %i VersionMismatch %s Version %s';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Get Mfiles Assembly version';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @RC, @MisMatch, @MFilesVersion);
        END;

        SELECT @MFilesOldVersion = CAST([Value] AS VARCHAR(100))
        FROM [dbo].[MFSettings]
        WHERE [Name] = 'MFVersion';

        IF @IsVersionMisMatch = 1
           AND @MFilesVersion <> @MFilesOldVersion
		   Begin
            SET @ProcedureStep = 'Update Matched version ';

        UPDATE [dbo].[MFSettings]
        SET [Value] = ISNULL(@MFilesVersion, '')
        WHERE [Name] = 'MFVersion';

        INSERT INTO [dbo].[MFUpdateHistory]
        (
            [Username]
           ,[VaultName]
           ,[UpdateMethod]
        )
        VALUES
        (@Username, @VaultName, 1);

        SELECT @Update_ID = @@Identity;

        --set @MFLocation= @MFLocation+'\CLPROC.Sql'
        DECLARE @SQL          VARCHAR(MAX)
               ,@DBName       VARCHAR(250)
               ,@DBServerName VARCHAR(250);

        SELECT @DBServerName = @@ServerName;

        SELECT @DBName = DB_NAME();

        --	Select @ScriptFilePath=cast(Value as varchar(250)) from MFSettings where Name='AssemblyInstallPath'
       EXEC [dbo].[spMFUpdateAssemblies];
  END
    END TRY
    BEGIN CATCH
        SET @ProcedureStep = 'Catch matching version error ';

        UPDATE [dbo].[MFSettings]
        SET [Value] = @MFilesOldVersion
        WHERE [Name] = 'MFVersion';

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
        ,ERROR_STATE(), ERROR_SEVERITY(), @Update_ID, ERROR_LINE());
    END CATCH;
END;
GO