Go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckMFilesAssemblyVersion]';
GO
 

SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFGetMFilesAssemblyVersion'
  , -- nvarchar(100)
    @Object_Release = '4.3.7.48'
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

  ** Author:			DevTeam2
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
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

				EXECUTE spmfGetMFilesVersionInternal @VaultSettings,@LsMFileVersion OUTPUT

				if @LsMFileVersion= @DbMFileVersion
				Begin
				set @IsUpdateAssembly=0
		--		print 'Match'
				End
				else
				Begin

		--		print 'Not Matched Updating M-Files Latest Version'
				
				set @MFilesVersion=@LsMFileVersion
				set @IsUpdateAssembly=1

      
				END

				END
                
				GO

