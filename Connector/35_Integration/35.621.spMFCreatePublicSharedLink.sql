PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.[spMFCreatePublicSharedLink]';

EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFCreatePublicSharedLink'
  , -- nvarchar(100)
    @Object_Release = '3.1.5.41'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 go
 
IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFCreatePublicSharedLink'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFCreatePublicSharedLink]
AS
BEGIN
       SELECT   'created, but not implemented yet.'--just anything will do
END
GO
-- the following section will be always executed
SET NOEXEC OFF
GO

ALTER PROCEDURE [dbo].[spMFCreatePublicSharedLink] ( 		
        @TableName Varchar(250)
	   ,@ExpiryDate DATETIME = null
       ,@ClassID int=null
	   ,@ObjectID int=null
	   ,@ProcessID int=1
)
AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to Create  public shared link from M-files
  **  
  ** Processing Steps:
  **					
  **
  ** Parameters and acceptable values: 
  **					@TableName Varchar(250)
						,@ExpiryDate Datetime
                        ,@ClassID int=null
                       ,@ObjectID int=null
  **					
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					
  **
  ** Called By:			
  **
  ** Calls:           
  **														
  **
  ** Author:			DevTeam2(Rheal)
  ** Date:				05 -15-2017
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
     2018-04-04  DevTeam 2  Added Licensing module validation code.
  ******************************************************************************/
      BEGIN
            SET NOCOUNT ON

    Begin Try

	   Declare 
         @ObjectType int
	    ,@Xml  nvarchar(max)
		,@VaultSettings NVARCHAR(4000)
		,@OutPutXML nvarchar(max)
		,@FilterCondition nvarchar(200) 
		,@Query NVARCHAR(MAX)
		,@XmlOut XML
		,@ServerUrl nvarchar(500)
		,@VaultGUID nvarchar(150)



	  -----------Fetching Vault Settings------------------------------- 
	   
	     SELECT   @VaultSettings = [dbo].[FnMFVaultSettings]();


		  select @VaultGUID=cast(value as nvarchar(150)) from MFSettings where Name='VaultGUID'
          select @ServerUrl=cast(value as nvarchar(500)) from MFSettings where Name='ServerURL'

	  ------------------------------------------

       
	  --------- classID is null the getting classID by using @TableName------------------
	   if @ClassID is Null          
	      Begin
		      Select @ClassID=MFID from MFClass where TableName=@TableName
		  End
      -----------------------------------------------------------------------------------

     
	 -----------------getting ObjectType of table using @TableName-----------------------
	   Select 
         @ObjectType=MFO.MFID 
	   from 
	    MFClass MFC inner join MFObjectType MFO 
	   on 
	     MFC.MFObjectType_ID=MFO.ID 
		 and 
		 MFC.TableName=@TableName
     ---------------------------------------------------------------------------------------
		


	  IF @ObjectType =0     ----If object Type=0 i.e object type is only document then continue process
	    Begin
		

		  if @ObjectID is Not Null
		  Begin

		    --If object ID is passed as parameter then only link of that object is only created
		    set @FilterCondition =' Deleted=0 and  Single_File=1 and  ObjID=' + Cast(@ObjectID as nvarchar(20))

		  End
		  Else
		   Begin

		       --If object ID is not passed as parameter then links are created for objects which are of type single file and has Process_ID=1
		       set @FilterCondition =' Deleted=0 and  Single_File=1 and Process_ID=' + cast(@ProcessID as varchar(20))

		   End
		  
		  set @Query=' select @Xml=(
										select 
											ObjID as ''ObjectDetails/@ID''
											,'''+cast(convert(date,@Expirydate) as varchar(20)) + ''' as ''ObjectDetails/@ExpiryDate''
											,'''' as ''ObjectDetails/@AccessKey''
										from 
											'+@TableName+' 
										where 
		
										 '+ @FilterCondition +' FOR XML PATH(''''),Root(''PSLink'')  )'

          --print @Query
		  EXEC [sys].[sp_executesql]
                     @Query
                    , N'@Xml nvarchar(max) OUTPUT'
                    , @Xml OUTPUT;

             -----------------------------------------------------------------
			-- Checking module access for CLR procdure  spMFCreatePublicSharedLinkInternal
			------------------------------------------------------------------
		   EXEC [dbo].[spMFCheckLicenseStatus] 
		             'spMFCreatePublicSharedLinkInternal'
		             ,'spMFCreatePublicSharedLink'
					 ,'Checking module access for CLR procdure  spMFCreatePublicSharedLinkInternal'			  

			EXEC spMFCreatePublicSharedLinkInternal @VaultSettings,@Xml ,@OutPutXML Output

			SET @XmlOut = @OutPutXML


				
				Create table #TmpLink
				(
				   ID int,
				   ExpiryDate nvarchar(20),
				   AccessKey nvarchar(max),
				   Name_Or_Title nvarchar(200)
				)

				

				insert into #TmpLink
				 (
				   ID,
				   ExpiryDate,
				   AccessKey
				 )

				 Select [t].[c].[value]('@ID[1]','INT') as ID,
				        [t].[c].[value]('@ExpiryDate[1]','NVARCHAR(20)') as ExpiryDate,
						[t].[c].[value]('@AccessKey[1]','NVARCHAR(max)') as AccessKey 
				  from 
				    @XmlOut.[nodes]('/form/ObjectDetails') AS [t] ( [c] )

			

			    set @Query='			

				Update T
				   set Name_Or_Title=TBL.Name_Or_Title
				from 
				   #TmpLink T inner join ' + @TableName+' TBL 
				on 
				   T.ID=TBL.ObjID '

				Exec(@Query)



				--Link='http://192.168.0.150/SharedLinks.aspx?accesskey='+TL.AccessKey+'&VaultGUID=E3DB829A-CDFE-4492-88C1-3E7B567FBD59'
				Update MFPL 
				 Set
				   Accesskey=TL.AccessKey,
				   ExpiryDate=TL.ExpiryDate,
				   DateModified=getdate(),
				   Link=@ServerUrl+'/SharedLinks.aspx?accesskey='+TL.AccessKey+'&VaultGUID='+@VaultGUID,
				   HtmlLink= '<a href="'+@ServerUrl+'/SharedLinks.aspx?accesskey='+TL.AccessKey+'&VaultGUID='+@VaultGUID+'" >'+ Name_Or_Title +'</a>'
				from
				   MFPublicLink MFPL inner join #TmpLink TL on MFPL.ObjectID=TL.ID


				insert into  MFPublicLink (ObjectID,ClassID,ExpiryDate,AccessKey,Link,DateCreated,HtmlLink)
				Select 
				   ID,
				   @ClassID,
				   ExpiryDate,
				   AccessKey,
				   @ServerUrl+'/SharedLinks.aspx?accesskey='+AccessKey+'&VaultGUID='+@VaultGUID,
				   getdate(),
				   '<a href="'+@ServerUrl+'/SharedLinks.aspx?accesskey='+AccessKey+'&VaultGUID='+@VaultGUID+'" >'+ Name_Or_Title +'</a>'
				 from 
				   #TmpLink
				  where 
				    ID not in (Select ObjectID from MFPublicLink )

         if(@ObjectID is null)
		   Begin
		     Declare @Sql nvarchar(500)
			 set @Sql='Update ' + @TableName + ' set Process_ID=0 where Process_ID='+ cast(@ProcessID as varchar(100)) +' and Single_File=1 ' 
		    --exec ('Update ' + @TableName + ' set Process_ID=0 where Process_ID='+ @ProcessID +' and Single_File=1 ' )
			exec (@Sql)
          End 
		
 
		 drop table #TmpLink
		End

 End try
 begin Catch
       DROP TABLE [#TmpLink]

	      
           exec ('Update ' + @TableName + ' set Process_ID=0 where Process_ID=3 and Single_File=1 ' )




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
                  VALUES    ( 'spMFCreatePublicSharedLink'
                            , ERROR_NUMBER()
                            , ERROR_MESSAGE()
                            , ERROR_PROCEDURE()
                            , ''
                            , ERROR_STATE()
                            , ERROR_SEVERITY()
                            , @ObjectID
                            , ERROR_LINE()
                            );
			
			RETURN -1
 End Catch
end 