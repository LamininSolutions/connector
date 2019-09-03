GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckMFileAssemblyVersion]';
GO
 

SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFGetMFilesAssemblyVersion'
  , -- nvarchar(100)
    @Object_Release = '4.3.9.48'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFGetMFilesAssemblyVersion'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
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
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFGetMFilesAssemblyVersion]
   @IsUpdateAssembly bit =0 Output,
   @MFilesVersion varchar(100) Output
AS
/*rST**************************************************************************

============================
spMFGetMFilesAssemblyVersion
============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IsUpdateAssembly bit (output)
    Default = 0
    Returns 1 if M-Files version on the M-Files Server is different from MFSettings
  @MFilesVersion varchar(100) (output)
    Returns M-Files version on the M-Files Server


Purpose
=======
The purpose of this procedure is to validate the M-Files version and return 1 if different 

Additional Info
===============
Used by other procedures.

Warnings
========
This procedure returns to M-Files Version on the M-Files Server and not the SQL Server

Examples
========
.. code:: sql

    Exec spMFGetMFilesAssemblyVersion
    Select * from MFsettings where name = 'MFVersion'

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2015-03-27  DEV2       Create procedure
2018-04-04  DEV2       Added Licensing module validation code.
2018-09-27  LC         Remove licensing check. this procedure is excecuted before license is active
2019-05-19  LC         Block print of result
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/

				BEGIN
				SET NOCOUNT ON;

				---------------------------------------------
				--DECLARE LOCAL VARIABLE
				--------------------------------------------- 
				DECLARE @VaultSettings NVARCHAR(4000),
				@LsMFileVersion varchar(250),
				@DbMFileVersion varchar(250);

				SELECT  
				@VaultSettings = [dbo].[FnMFVaultSettings]()

				select 
				@DbMFileVersion= CAST(Value AS VARCHAR(250)) 
				from 
				MFSettings
				WHERE   
				Name = 'MFVersion';

		--		SELECT @DbMFileVersion

				-----------------------------------------------------------------
	             -- Checking module access for CLR procdure  spmfGetMFilesVersionInternal
			   ------------------------------------------------------------------
	IF (SELECT OBJECT_ID('dbo.spmfGetMFilesVersionInternal')) > 0
				BEGIN
          
				EXECUTE spmfGetMFilesVersionInternal @VaultSettings,@LsMFileVersion OUTPUT
		END
   --             ELSE
			--	BEGIN
   --             EXEC [dbo].[spMFUpdateAssemblies]
			----					SELECT [ms].[Value] AS [MF SEttings MFVersion] FROM [dbo].[MFSettings] AS [ms] WHERE name = 'MFVersion'
   --         --    RAISERROR('Unable to find spmfGetMFilesVersionInternal, manually update MFSettings with version, then run spMFUpdateAssemblies ',16,1)
			--	END
				;
	   
			--	SELECT @LsMFileVersion

				if @LsMFileVersion= @DbMFileVersion
				Begin
				set @IsUpdateAssembly=0
				 SET @MFilesVersion = @LsMFileVersion
	--			print 'Match'
				End
				else
				Begin

	--			print 'Not Matched: Updating M-Files to Latest Version'
				
				set @MFilesVersion=@LsMFileVersion
				set @IsUpdateAssembly=1

      
				END

				END
                
				GO
