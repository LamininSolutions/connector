GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckAssemblyVersion]';
GO
 


SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFCheckAndUpdateAssemblyVersion'
  , -- nvarchar(100)
    @Object_Release = '4.3.9.48'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFCheckAndUPdateAssemblyVersion'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFCheckAndUpdateAssemblyVersion]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFCheckAndUpdateAssemblyVersion]
 
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to check  M-File Version and update it
            database drop and recreeate assembly.
						
  **
  ** Author:			DevTeam2
  ** Date:				28-12-2016
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  2018-09-27		LC		change procedure to work with Release 4 scripts
  2019-05-19		LC		Fix bug - insert null value in MFsettings not allowed
  ******************************************************************************/
				BEGIN
					SET NOCOUNT ON;

				---------------------------------------------
				Declare @IsVersionMisMatch bit =0,
				        @MFilesVersion varchar(100),
						@MFilesOldVersion varchar(100),
				        @Update_ID INT,
						@ProcedureStep sysname = 'Start',
				        @Username NVARCHAR(2000),
						@RC INT,
				        @VaultName NVARCHAR(2000);

				SELECT TOP 1
				        @Username = [MFVaultSettings].[Username]
				      , @VaultName = [MFVaultSettings].[VaultName]
				FROM     
				      [dbo].[MFVaultSettings];

				set @ProcedureStep='Get Install assembly Version M-Files '


	
				exec @RC = spMFGetMFilesAssemblyVersion @IsVersionMisMatch Output
												,@MFilesVersion OutPut

				select @MFilesOldVersion= cast(Value as varchar(100)) from MFSettings where Name='MFVersion'
				
				;
	            
				if @IsVersionMisMatch = 1 AND @MFilesVersion IS NOT null
				begin
	       
       

				BEGIN TRY

		set @ProcedureStep='Update Matched version '

				Update MFSettings set Value=ISNULL(@MFilesVersion,'') where Name='MFVersion';

				INSERT   INTO [dbo].[MFUpdateHistory]
				( [Username]
				, [VaultName]
				, [UpdateMethod]
				)
				VALUES   ( @Username
				, @VaultName
				, 1
				);

				SELECT   @Update_ID = @@IDENTITY;
						
				--set @MFLocation= @MFLocation+'\CLPROC.Sql'
				DECLARE 
				@SQL varchar(MAX),
				@DBName varchar(250),
				@DBServerName varchar(250)

				Select @DBServerName=@@SERVERNAME
				Select @DBName=DB_NAME()

			--	Select @ScriptFilePath=cast(Value as varchar(250)) from MFSettings where Name='AssemblyInstallPath'
			
				SET NOCOUNT ON  
			
				EXEC spmfUpdateAssemblies

				End Try
				Begin Catch

				set @ProcedureStep='Catch matching version error '
				    Update MFSettings set Value=@MFilesOldVersion  where Name='MFVersion';

					INSERT    INTO [dbo].[MFLog]
					( [SPName]
					, [ErrorNumber]
					, [ErrorMessage]
					, [ErrorProcedure]
					, [ProcedureStep]
					, [ErrorState]
					, [ErrorSeverity]
					, [Update_ID]
					, [ErrorLine]
					)
					VALUES    ( 'spMFCheckAndUpdateAssemblyVersion'
					, ERROR_NUMBER()
					, ERROR_MESSAGE()
					, ERROR_PROCEDURE()
					, @ProcedureStep
					, ERROR_STATE()
					, ERROR_SEVERITY()
					, @Update_ID
					, ERROR_LINE())
				End catch


	 
				End

				End

				GO