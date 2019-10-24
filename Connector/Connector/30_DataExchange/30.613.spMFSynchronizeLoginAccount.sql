
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeLoginAccount]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeLoginAccount', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSynchronizeLoginAccount'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeLoginAccount]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO
Alter PROCEDURE [dbo].[spMFSynchronizeLoginAccount] (@VaultSettings  [NVARCHAR](4000)
                                                    ,@Debug          [SMALLINT] = 0
                                                    ,@Out            [NVARCHAR](max) OUTPUT)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Login Account details  
  **  
  ** Version: 1.0.0.6
  **
  ** Processing Steps:
  **					1.) Call CRL procedure to get Login Account details from M-files
  **					2.) Call spMFInsertLoginAccount to insert Login Account details into Table 
  **
  ** Parameters and acceptable values: 
  **					@VaultSettings       [NVARCHAR](4000)
  **					@Debug          SMALLINT = 0
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					@Out            [NVARCHAR](max)		
  **
  ** Called By:			spMFSynchronizeMetadata
  **
  ** Calls:           
  **					spMFGetLoginAccounts
  **					spMFInsertLoginAccount									
  **
  ** Author:			Thejus T V
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTeam2   Removed vault settings parameters and pass them as 
                            comma separated string in @VaultSettings parameter.
     2017-04-03  DEVTeam2   Added License module validation code.
  ******************************************************************************/
  BEGIN
      SET NOCOUNT ON

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------    
      DECLARE @Xml     [NVARCHAR] (max)
              ,@Output INT
			  ,@ProcedureStep nVARCHAR(128) = 'Wrapper - GetLoginAccounts'
			  ,@ProcedureName nVARCHAR(128) = 'spMFSynchronizeLoginAccount'
			 ;
IF @debug  = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

	 -------------------------------------------------------------------
	  --Checking module access for CLR procedure
	 -------------------------------------------------------------------
	  EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetLoginAccounts',@ProcedureName,@ProcedureStep
      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET Login Account DETAILS FROM M-FILES
      -------------------------------------------------------------
      EXEC spMFGetLoginAccounts
        @VaultSettings
        ,@Xml OUTPUT;

		  SET @ProcedureStep  = 'GetLoginAccounts Returned from wrapper'

IF @debug  = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);
      -------------------------------------------------------------------------
      -- CALL 'spMFInsertLoginAccount' TO INSERT THE Login Account DETAILS INTO MFLoginAccount TABLE
      -------------------------------------------------------------------------
 SET @ProcedureStep  = 'Exec spMFInsertLoginAccount'

 DECLARE @return_Value int
 BEGIN TRY
 
      EXEC @return_Value = spMFInsertLoginAccount
        @Xml
        ,1--IsFullUpdate Set to TRUE  
        , @Output OUTPUT
        ,@Debug;

IF @debug  = 1
            RAISERROR('%s : Step %s Returned: %i : Output: %i ',10,1,@ProcedureName, @ProcedureStep, @return_Value, @Output);

		END TRY
        BEGIN CATCH

		RAISERROR('spMFInsertLoginAccount Failed %i',16,1,@return_Value)

        END CATCH
        



      IF ( @Output > 0 )
        SET @Out = 'All Login Accounts Updated'
      ELSE
        SET @Out = 'All Login Accounts Are Upto Date'

      SET NOCOUNT OFF
  END
  go