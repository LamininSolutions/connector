
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeValueList]';
GO
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeValueList', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSynchronizeValueList'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSynchronizeValueList]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO


alter PROCEDURE [dbo].[spMFSynchronizeValueList] (@VaultSettings       [NVARCHAR](4000)
                                                   ,@Debug          SMALLINT
                                                   ,@Out            [NVARCHAR](max) OUTPUT
												   ,@IsUpdate SMALLINT=0)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to synchronize M-File Property details  
  **  
  
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2016-09-26  DevTeam2   Removed vault settings parameters and pass them as 
                            comma separated sting in @VaultSettings
  ** 2018-04-04  DevTeam2   Added License module validation code.
  ******************************************************************************/
  BEGIN
      SET NOCOUNT ON

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      --------------------------------------------- 
      DECLARE @Xml     [NVARCHAR] (max)
              ,@Output INT;


	 -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetValueList
     ------------------------------------------------------------------
      EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetValueList','spMFSynchronizeValueList','Checking module access for CLR procdure  spMFGetValueList'

      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET VALUE LIST DETAILS FROM M-FILES
      -------------------------------------------------------------
      EXEC spMFGetValueList
        @VaultSettings
        ,@Xml OUTPUT;

		IF @debug > 10
		SELECT @XML AS ValuelistXML

      -------------------------------------------------------------------------
      -- CALL 'spMFInsertValueList' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      ------------------------------------------------------------------------- 
	  if @IsUpdate=1
	  begin
	    
		Declare @XMLValueList nvarchar(max)
	     Select 
		   ID
		  ,Name
		  ,Alias
          ,MFID
		  ,OwnerID 
         into
		  #TempValueList
		 from
		  MFValueList
		 where
		  Deleted=0

	     EXEC spMFInsertValueList
         @Xml
        ,1 --IsFullUpdate Set to TRUE  
        ,@Output OUTPUT
        ,@Debug;

		set @XMLValueList=( Select 
		   isnull(TMVL.ID,0) as 'ValueListDetails/@ID'
		  ,isnull(TMVL.Name,'') as 'ValueListDetails/@Name'
		  ,isnull(TMVL.Alias,'') as 'ValueListDetails/@Alias'
          ,isnull(TMVL.MFID,0) as 'ValueListDetails/@MFID'
		  ,isnull(TMVL.OwnerID,0) as 'ValueListDetails/@OwnerID'
         from
		  MFValueList MVL inner join #TempValueList TMVL
		 on  
		  MVL.MFID=TMVL.MFID and (MVL.Alias!=TMVL.Alias or MVL.Name!=TMVL.Name)
		 for XML path(''),Root('VList'))

		 Declare @Output1 nvarchar(max)

		  -----------------------------------------------------------------
	       -- Checking module access for CLR procdure  spMFUpdatevalueList
          ------------------------------------------------------------------
          EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdatevalueList','spMFSynchronizeValueList','Checking module access for CLR procdure  spMFUpdatevalueList'

		  exec spMFUpdatevalueList @VaultSettings,@XMLValueList,@Output1 output

		 UPdate 
		   MVL
		  set
		  MVL.Alias=TMVL.Alias,
		  MVL.Name=TMVL.Name
         from
		  MFValueList MVL inner join #TempValueList TMVL
		 on  
		  MVL.MFID=TMVL.MFID


		  drop table #TempValueList

	  End
	  else
	   begin
	    EXEC spMFInsertValueList
         @Xml
        ,1 --IsFullUpdate Set to TRUE  
        ,@Output OUTPUT
        ,@Debug;
	   End
      
      
          UPDATE mvl
          SET mvl.OwnerID = -1
         FROM MFvaluelist mvl
         WHERE mvl.OwnerID = 0

		IF @debug > 10
		SELECT @Output AS InsertValuelistOutput

      IF ( @Output > 0 )
        SET @Out = 'All ValueList are Updated'
      ELSE
        SET @Out = 'All ValueList are upto date'

      SET NOCOUNT OFF
  END
  go
  