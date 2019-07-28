PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetDataExport]';
GO
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetDataExport', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFGetDataExport'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFGetDataExport]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO

ALTER PROCEDURE [dbo].[spMFGetDataExport] (@ExportDatasetName [NVARCHAR](2000)
                                            ,@Debug            INT = 0)
AS
  /*******************************************************************************
    ** Desc:  The purpose of this procedure is to Export data set 
    **  
    ** Version: 1.0.0.6
    **
    ** Processing Steps:
    **        1. Insert data from XML into temperory data
    **		2. Update M-Files ID with primary key values from MFWorkflow,MFValueList,MFObjectType
    **		3. Update the Class details into MFClass
    **		4. INsert the new class details
    **		5. If fullUpdate 
    **				Delete the class details deleted from M-Files
    **
    ** Parameters and acceptable values: 
    **       @ExportDatasetName [NVARCHAR](2000)
    **	   @Debug INT = 0
    **
    ** Restart:
    **        Restart at the beginning.  No code modifications required.
    ** 
    ** Tables Used:                 
    **					
    ** Return values:		
    **					
    **
    ** Called By:			
    **
    ** Calls:           spMFGetDataExportInternal
    **					
    ** Author:          Thejus T V
    ** Date:            27-03-2015
    ********************************************************************************
    ** Change History
    ********************************************************************************
    ** Date        Author     Description
    ** ----------  ---------  -----------------------------------------------------
    ** 2016-09-26  DevTeam2   Removed vault settings parameters and pass them as comma
	                          separated string in @VaultSettings parameter.
		2016-10-11 LC			Change of Settings Tablename
		2018-04-04 DEVTeam2    Added License module validation code
    ******************************************************************************/
  BEGIN
      ------------------------------------------------------
      -- SET SESSION STATE
      -------------------------------------------------------
      SET NOCOUNT ON

      ------------------------------------------------------
      -- DEFINE CONSTANTS
      ------------------------------------------------------
      DECLARE @ProcedureName  SYSNAME = 'spMFGetDataExport'
              ,@ProcedureStep SYSNAME = 'Start'
              ,@ErrStep       VARCHAR(255)
              ,@Output        NVARCHAR(max)

      --BEGIN TRY
      ------------------------------------------------------
      -- GET M-FILES AUTHENTICATION
      -------------------------------------------------------		
      SET @ProcedureStep = 'M-Files Authentication'

      DECLARE @VaultSettings   NVARCHAR(4000)
              
     
     SELECT @VaultSettings=dbo.FnMFVaultSettings()

     DECLARE @Username nvarchar(2000)
     DECLARE @VaultName nvarchar(2000)

	 SELECT TOP 1  @Username = username, @VaultName = vaultname
                    FROM    dbo.MFVaultSettings                   

      IF @debug > 0
        RAISERROR ( '%s: VaultName: %s; UserName: %s',10,1,@ProcedureStep,@VaultName,@Username );

      ------------------------------------------------------
      -- MAIN CODE
      -------------------------------------------------------	
      DECLARE @IsExported BIT

      SET @ProcedureStep = 'EXEC spMFSearchForObjectInternal'

      IF @debug > 0
        RAISERROR ( '   %s',10,1,@ProcedureStep );

		------------------------------------------------------
      -- Validating module for CLR Procedure
      -------------------------------------------------------	
	   EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetDataExportInternal',@ProcedureName,@ProcedureStep

      --SELECT @ExportDatasetName
      ------------------------------------------------------
      --Executing CLR procedure
      ------------------------------------------------------
      EXEC spMFGetDataExportInternal
        @VaultSettings
        ,@ExportDatasetName
        ,@IsExported OUTPUT

      IF( @IsExported = 1 )
        BEGIN
            SELECT 'YES' AS 'EXPORTING STATUS'
        END
      ELSE
        BEGIN
            SELECT 'NO' AS 'EXPORTING STATUS'
        END

      --SELECT @IsExported		
      RETURN 0
  --END TRY
  --BEGIN CATCH
  --	DECLARE @ErrorMessage NVARCHAR(4000)
  --	DECLARE @ErrorSeverity INT
  --	DECLARE @ErrorState INT
  --	DECLARE @ErrorNumber INT
  --	DECLARE @ErrorLine INT
  --	DECLARE @ErrorProcedure NVARCHAR(128)
  --	DECLARE @OptionalMessage VARCHAR(max)
  --	SELECT @ErrorMessage = ERROR_MESSAGE()
  --		,@ErrorSeverity = ERROR_SEVERITY()
  --		,@ErrorState = ERROR_STATE()
  --		,@ErrorNumber = ERROR_NUMBER()
  --		,@ErrorLine = ERROR_LINE()
  --		,@ErrorProcedure = ERROR_PROCEDURE()
  --	IF @debug > 0
  --		RAISERROR (
  --				'FAILED: In %s:%s with Error: %s'
  --				,16
  --				,1
  --				,@ProcedureName
  --				,@ProcedureStep
  --				,@ErrorMessage
  --				)
  --		WITH NOWAIT;
  --	RAISERROR (
  --			 @ErrorMessage	-- Message text.
  --			,@ErrorSeverity -- Severity.
  --			,@ErrorState	-- State.
  --			);
  --	RETURN - 1
  --END CATCH
  END

SET NOCOUNT OFF

GO