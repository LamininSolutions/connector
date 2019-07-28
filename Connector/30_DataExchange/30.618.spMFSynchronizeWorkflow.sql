PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFSynchronizeWorkflow]';
GO
 

SET NOCOUNT ON; 
EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFSynchronizeWorkflow', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFSynchronizeWorkflow'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeWorkflow]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE [dbo].[spMFSynchronizeWorkflow]
    (
      @VaultSettings [NVARCHAR](4000) ,
      @Debug SMALLINT ,
      @Out [NVARCHAR](MAX) OUTPUT,
	  @IsUpdate SMALLINT=0
    )
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File WORKFLOW details  
  
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2018-04-04  DevTeam2    Added License module validation code
  ******************************************************************************/
    BEGIN
        SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      --------------------------------------------- 
        DECLARE @Xml [NVARCHAR](MAX) ,
            @Output INT ,
            @ProcedureStep NVARCHAR(128) = 'Wrapper - GetWorkflow' ,
            @ProcedureName NVARCHAR(128) = 'spMFSynchronizeWorkflow';
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

      -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetWorkFlow
      ------------------------------------------------------------------
      EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetWorkFlow',@ProcedureName,@ProcedureStep

      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET VALUE LIST DETAILS FROM M-FILES
      -------------------------------------------------------------

        EXEC spMFGetWorkFlow @VaultSettings,
            @Xml OUTPUT;

        SET @ProcedureStep = 'GetWorkflow Returned from wrapper';
	
        IF @Debug = 1
            RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep); 

      -------------------------------------------------------------------------
      -- CALL 'spMFInsertValueList' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      ------------------------------------------------------------------------- 

	    if @IsUpdate=1
		 Begin
		     Select ID,Name,Alias,MFID into #TempMFWorkflow from MFWorkflow
		     EXEC spMFInsertWorkflow @Xml, 1 --IsFullUpdate Set to False
            , @Output OUTPUT, @Debug;

			Declare @WorkflowXml nvarchar(max)
			set @WorkflowXml=( Select 
			   isnull(TMWF.ID,0) as 'WorkFlowDetails/@ID'
			  ,isnull(TMWF.Name,0) as 'WorkFlowDetails/@Name'
			  ,isnull(TMWF.Alias,0) as 'WorkFlowDetails/@Alias'
			  ,isnull(TMWF.MFID ,0) as 'WorkFlowDetails/@MFID'
			 from MFWorkflow MWF inner join #TempMFWorkflow TMWF 
			 on MWF.MFID=TMWF.MFID and (MWF.Alias!=TMWF.Alias or MWF.Name=TMWF.Name) for Xml Path(''),Root('WorkFlow'))
			

			-----------------------------------------------------------------
	         -- Checking module access for CLR procdure  spMFUpdateWorkFlow
            ------------------------------------------------------------------
            EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdateWorkFlow',@ProcedureName,@ProcedureStep

			 Declare @OutPut1 nvarchar(max)	
			 exec spMFUpdateWorkFlow @VaultSettings,@WorkflowXml,@OutPut1

			 Update  
			  MWF
             set
			  MWF.Name=TMWF.Name,
			  MWF.Alias=TMWF.Alias
			 from 
			  MFWorkflow MWF inner join #TempMFWorkflow TMWF 
			 on 
			  MWF.MFID=TMWF.MFID 

		 End
		else
		 begin
		     EXEC spMFInsertWorkflow @Xml, 1 --IsFullUpdate Set to False
            , @Output OUTPUT, @Debug;
		 End
       

        SET @ProcedureStep = 'Exec spMFInsertWorkflow'; 

        IF @Debug = 1
            RAISERROR('%s : Step %s Output: %i ',10,1,@ProcedureName, @ProcedureStep, @Output);

        IF ( @Output > 0 )
            SET @Out = 'All Workflow Updated';
        ELSE
            SET @Out = 'All Workflow Are Upto Date';

        SET NOCOUNT OFF;
    END;
  GO
  