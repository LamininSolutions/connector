PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeUserAccount]';
GO
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeUserAccount', -- nvarchar(100)
    @Object_Release = '4.11.33.77', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO


IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeUserAccount'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeUserAccount]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeUserAccount]
    (
       @VaultSettings  [NVARCHAR](4000)
       ,@Debug          SMALLINT = 0
       ,@Out            [NVARCHAR](max) OUTPUT)
AS
/*rST**************************************************************************

==========================
spMFSynchronizeUserAccount
==========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @VaultSettings nvarchar(4000)
    pass in @fnmfvaultsettings
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
  @Out nvarchar(max) (output)
    listing of user accounts from MF for the vault


Purpose
=======

Procedure is used in other procedures

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2023-10-12  LC         Change to update insert of rows and consolidate procedures
2019-08-30  JC         Added documentation
2016-09-26  DevTean2   Removed vault settings parameters and pass them as comma separated string in @VaultSettings parameter.
2018-04-04  DevTeam    Addded License module validation code
==========  =========  ========================================================

**rST*************************************************************************/
 
    BEGIN
        SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------
        DECLARE @UserAccountXML [NVARCHAR](MAX) ,
            @Output INT ,
            @ProcedureStep NVARCHAR(128) = 'Wrapper - GetUserAccounts' ,
            @ProcedureName NVARCHAR(128) = 'spMFSynchronizeUserAccount';
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);



      -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetObjectType
      ------------------------------------------------------------------
	   EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetUserAccounts',@ProcedureName,@ProcedureStep

      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET USER ACCOUNT DETAILS FROM M-FILES
      -------------------------------------------------------------
      EXEC spMFGetUserAccounts
         @VaultSettings
        ,@UserAccountXML OUTPUT
     
        SET @ProcedureStep = 'GetUserAccounts Returned from wrapper';

        IF @Debug = 1
        begin
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep)
			select cast(@UserAccountXML as xml) as userxml; 
            end

      -------------------------------------------------------------------------
      -- CALLS 'spMFInsertUserAccount' TO INSERT THE USER ACCOUNT DETAILS INTO MFClass TABLE
      -------------------------------------------------------------------------
        SET @ProcedureStep = 'Exec spMFInsertUserAccount'; 
   
        EXEC spMFInsertUserAccount @UserAccountXML, 1 --IsFullUpdate Set to TRUE 
            , @Output OUTPUT, @Debug;
  
        IF @Debug = 1
            RAISERROR('%s : Step %s Output: %i ',10,1,@ProcedureName, @ProcedureStep, @Output);


      
        IF ( @Output > 0 )
            SET @Out = 'All User Accounts Updated';
        ELSE
            SET @Out = 'All User Accounts Upto date';

        SET NOCOUNT OFF;
    END;
  GO