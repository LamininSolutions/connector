PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeObjectType]';
GO

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeObjectType', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeObjectType'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeObjectType]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeObjectType]
    (
      @VaultSettings   [NVARCHAR](4000)
      ,@Debug          [SMALLINT] = 0
      ,@Out            [NVARCHAR](max) OUTPUT
	  ,@IsUpdate SMALLINT=0
    )
AS


    
/*rST**************************************************************************

=========================
spMFSynchronizeObjectType
=========================

Parameters
  @VaultSettings
    - use fnMFVaultSettings()
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
  @Out (Output)
    - XML result
  @IsUpdate (Optional)
    - Default = 0
    - 1 = Push updates from SQL to M-Files

Purpose
=======

Internal procedure to synchronize ObjectTypes
Used by spMFSynchronizeMetadata and spMFSynchronizeSpecificMetadata

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2016-09-26  DevTeam(2) Removed Vault Settings parameters and pass them as comma separated string in single parameter  (@VaultSettings
2018-04-04  Devteam(2) Added License module validation code.
==========  =========  ========================================================

**rST*************************************************************************/

  BEGIN
      SET NOCOUNT ON

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------    
        DECLARE @Xml [NVARCHAR](MAX) ,
            @Output INT ,
            @ProcedureStep NVARCHAR(128) = 'Wrapper - GetObjectType' ,
            @ProcedureName NVARCHAR(128) = '[spMFSynchronizeObjectType]';
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);
      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET OBJECTTYPE DETAILS FROM M-FILES
      -------------------------------------------------------------
        

        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep); 
	    
          select @VaultSettings=dbo.FnMFVaultSettings()
	  
	   ------------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetObjectType
	   ------------------------------------------------------------------
	     EXEC [dbo].[spMFCheckLicenseStatus] 
		      'spMFGetObjectType',
			  @ProcedureName,
			  @ProcedureStep


          EXEC spMFGetObjectType @VaultSettings,@Xml OUTPUT;


        SET @ProcedureStep = 'GetObjectType Returned from wrapper';

        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep); 
      -------------------------------------------------------------------------
      -- CALL 'spMFInsertObjectType' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      -------------------------------------------------------------------------
        if  @IsUpdate =1
		  Begin
		    
			Declare @ObjTypeXml nvarchar(max)
			Select ID,Name,Alias,MFID into #tempObjectType from MFObjectType where Deleted=0

		     EXEC spMFInsertObjectType @Xml, 1--IsFullUpdate Set to TRUE  
            ,@Output OUTPUT, @Debug;

			set @ObjTypeXml =(Select 
			   isnull(TObTyp.ID,0) as 'ObjTypeDetails/@ID'
			  ,isnull(TObTyp.Name,'') as 'ObjTypeDetails/@Name'
			  ,isnull(TObTyp.Alias,'') as 'ObjTypeDetails/@Alias'
			  ,isnull(TObTyp.MFID ,0) as 'ObjTypeDetails/@MFID'
			 from 
			   MFObjectType ObTyp inner join #tempObjectType TObTyp 
			 on 
			   ObTyp.MFID=TObTyp.MFID 
			   and 
			   (ObTyp.Alias!=TObTyp.Alias or ObTyp.Name!=TObTyp.Name)
			 For XML Path(''),Root('ObjType'))

			 --print @ObjTypeXml
			 ------------------------------------------------------------------
	           -- Checking module access for CLR procdure  spMFGetObjectType
	         ------------------------------------------------------------------
	          EXEC [dbo].[spMFCheckLicenseStatus] 
			       'spMFUpdateObjectType'
				   ,@ProcedureName
				   ,@ProcedureStep

			 Declare @Output1 nvarchar(max)
			 exec spMFUpdateObjectType @VaultSettings,@ObjTypeXml,@Output1

			 Update
			   ObTyp
              set
			   ObTyp.Alias=TObTyp.Alias,
			   ObTyp.Name=TObTyp.Name
			  from 
			   MFObjectType ObTyp inner join #tempObjectType TObTyp 
			 on 
			   ObTyp.MFID=TObTyp.MFID 

			   drop table #tempObjectType
		  End
		else
		  Begin
		      EXEC spMFInsertObjectType @Xml, 1--IsFullUpdate Set to TRUE  
             ,@Output OUTPUT, @Debug;
		  End
        

        SET @ProcedureStep = 'Exec spMFInsertObjectType'; 

        IF @Debug = 1
            RAISERROR('%s : Step %s Output: %i ',10,1,@ProcedureName, @ProcedureStep, @Output);

        IF ( @Output > 0 )
            SET @Out = 'All Object Types Updated';
        ELSE
            SET @Out = 'All Object Types Are Upto Date';

        SET NOCOUNT OFF;
    END;
  GO

