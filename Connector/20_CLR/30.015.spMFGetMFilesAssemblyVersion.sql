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
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Meta data  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **					
  **
  ** Parameters and acceptable values: 					
  **					
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					NONE
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					
  **				     spMFSynchronizeLoginAccount
  **														
  **
  ** Author:			DevTeam2
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
     2018-04-04   Dev 2     Added Licensing module validation code.
	 2018-09-27		lc		remove licensing check. this procedure is excecuted before license is active
	   2019-5-19		lc			block print of result
  ******************************************************************************/
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
