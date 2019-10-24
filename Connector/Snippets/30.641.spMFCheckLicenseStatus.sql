PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCheckLicenseStatus]';
GO


SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFCheckLicenseStatus'	-- nvarchar(100)
  , @Object_Release = '3.1.5.43'				-- varchar(50)
  , @UpdateFlag = 2;							-- smallint

GO

/*
Modifications
2018-07-09		lc	Change name of MFModule table to MFLicenseModule
*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFCheckLicenseStatus' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFCheckLicenseStatus]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER  PROCEDURE [dbo].[spMFCheckLicenseStatus]
@InternalProcedureName NVARCHAR(500),
@ProcedureName NVARCHAR(500),
@ProcedureStep SYSNAME
AS 
BEGIN
				DECLARE @ModuleID NVARCHAR(20)
				DECLARE @Status NVARCHAR(20)
				DECLARE @VaultSettings NVARCHAR(2000)
				DECLARE @ModuleErrorMessage NVARCHAR(MAX)

				--select 
				-- @ModuleID=CAST(ISNULL(Module,0) as NVARCHAR(20))
				--from 
				-- setup.MFSQLObjectsControl 
				--WHERE 
				-- Name=@InternalProcedureName

				--Select 
				-- @VaultSettings=dbo.FnMFVaultSettings()
				----from 
				---- MFModule

	  
				--IF @ModuleID !='0'
				--Begin
				--EXEC spMFValidateModule 
				--                      @VaultSettings,
				--					  @ModuleID,
				--					  @Status OUT
		   
				--IF @Status ='2'
				--Begin
				--  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'License is not valid.');
				--ENd

				--IF @Status='3'
				--Begin
				--  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'You dont have access to this module.');
				--ENd

				--IF @Status='4'
				--Begin
				--  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'Invalid License key.');
				--ENd

				--IF @Status='5'
				--Begin
				--  RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,'Please install the License.');
				--ENd


				--End
				--RAISERROR('Proc: %s Step: %s ErrorInfo %s ', 16, 1, @ProcedureName, @ProcedureStep,@ModuleErrorMessage);
	
END


GO




