PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFDeleteObject]';
GO
 
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFDeleteObject', -- nvarchar(100)
    @Object_Release = '4.1.5.43', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

/********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-8-14		lc		add objid to output message
  2016-8-22		lc			update settings index
  2016-09-26    DevTeam2   Removed vault settings parameters and pass them as comma
                           separated string in @VaultSettings parameter.
 2018-8-3		LC			Suppress SQL error when no object in MF found

  ******************************************************************************/

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFDeleteObject'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFDeleteObject]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO

ALTER PROCEDURE [dbo].[spMFDeleteObject] @ObjectTypeId INT
                                          ,@objectId   INT
                                          ,@Output      NVARCHAR(2000) OUTPUT
										  ,@DeleteWithDestroy BIT = 0 
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to Delete object from M-Files.  
  **  
  ** Version: 1.0.0.6
  
  ** Author:          Thejus T V
  ** Date:            27-03-2015
  */
  BEGIN
      BEGIN TRY
          -----------------------------------------------------
          -- LOCAL VARIABLE DECLARARTION
          -----------------------------------------------------
          DECLARE @VaultSettings        NVARCHAR(4000)
                  

          -----------------------------------------------------
          -- SELECT CREDENTIAL DETAILS
          -----------------------------------------------------

			SELECT @VaultSettings=dbo.FnMFVaultSettings()

		   ------------------------------------------------------
			  --Validating Module for calling CLR Procedure
	       ------------------------------------------------------
		   EXEC [dbo].[spMFCheckLicenseStatus] 'spMFDeleteObjectInternal','spMFDeleteObject','Deleting object'

          -----------------------------------------------------
          -- CALLS PROCEDURE spMFDeleteObjectInternal
          -----------------------------------------------------
          EXEC spMFDeleteObjectInternal
            @VaultSettings
            ,@ObjectTypeId
            ,@objectId
            ,@Output OUTPUT
			,@DeleteWithDestroy

    --      PRINT @Output + ' ' + CAST(@objectId AS VARCHAR(100))
	
		  RETURN 1
      END TRY

      BEGIN CATCH

	  SET @Output = 'Nothing Deleted'
          --------------------------------------------------------
          ---- INSERTING ERROR DETAILS INTO LOG TABLE
          --------------------------------------------------------
          --INSERT INTO MFLog
          --            (SPName,
          --             ErrorNumber,
          --             ErrorMessage,
          --             ErrorProcedure,
          --             ErrorState,
          --             ErrorSeverity,
          --             ErrorLine)
          --VALUES      ('spMFDeleteObject',
          --             Error_number(),
          --             Error_message(),
          --             Error_procedure(),
          --             Error_state(),
          --             Error_severity(),
          --             Error_line())
		  RETURN 1
	  END CATCH
  END

GO