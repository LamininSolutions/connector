PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.dbo.[spMFCreatePublicSharedLink]';

EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFCreatePublicSharedLink'
  , -- nvarchar(100)
    @Object_Release = '4.9.26.68'
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
	   ,@ProcessID int=1,
       @Debug SMALLINT = 0 
)
AS
/*rST**************************************************************************

==========================
spMFCreatePublicSharedLink
==========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @TableName varchar(250)
    Name of class table
  @ExpiryDate datetime
    Set to NULL to getdata() + 1 month
  @ClassID int (optional)
    - Default = NULL
    - Class_ID of the Record
  @ObjectID int (optional)
    - Default = NULL
    - ObjID column of the Record
  @ProcessID int (optional)
    - Default = 1
    - set process_id = 0 to update all the records with singlefile = 1 in the class
    - set process_id to a number > 4 if you want to create the link for a set list of records

Purpose
=======

Create or update the link to the specified object and add the link in the MFPublicLink table. A join can then be used to access the link and include it in any custom view.

Additional Info
===============

If you are making updates to a record and want to set the public link at the same time then run the shared link procedure after setting the process_id and before updating the records to M-Files.

The expire date can be set for the number of weeks or month from the current date by using the dateadd function (e.g. Dateadd(m,6,Getdate())).

Warnings
========

This procedure will use the ServerURL setting in MFSettings and expects eiher 'http://' or 'https://' and a fully qualified dns name as the value. Example: 'http://contoso.com'

Examples
========

.. code:: sql

    EXEC dbo.spMFCreatePublicSharedLink
         @TableName = 'ClassTableName', 
         @ExpiryDate = '2017-05-21',    
         @ClassID = null,               
         @ObjectID = null ,                  
         @ProcessID = 0                 

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-03-04  LC         fix bug and add debugging
2020-08-22  LC         update for new deleted column
2019-08-30  JC         Added documentation
2018-04-04  DEV2       Added Licensing module validation code
==========  =========  ========================================================

**rST*************************************************************************/
      BEGIN
            SET NOCOUNT ON

            	-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFCreatePublicSharedLink';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16
           

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
        ,@DeletedColumn NVARCHAR(100)


Set @DebugText = ''
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Start'

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END

	  -----------Fetching Vault Settings------------------------------- 
	   
	     SELECT   @VaultSettings = [dbo].[FnMFVaultSettings]();


		  select @VaultGUID=cast(value as nvarchar(150)) from MFSettings where Name='VaultGUID'
          select @ServerUrl=cast(value as nvarchar(500)) from MFSettings where Name='ServerURL'

	  ------------------------------------------

      Set @DebugText = ''
      Set @DebugText = @DefaultDebugText + @DebugText
      Set @Procedurestep = 'Get column names '
      
      IF @debug > 0
      	Begin
      		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
      	END
      
      -------------------------------------------------------------
      -- get deleted column name
      -------------------------------------------------------------
      
      SELECT @DeletedColumn = columnName FROM dbo.MFProperty AS mp 
      WHERE MFID = 27
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
		    set @FilterCondition ='' +QUOTENAME(@DeletedColumn)+' is null and  Single_File=1 and  ObjID=' + Cast(@ObjectID as nvarchar(20))

		  End
		  Else
		   Begin

		       --If object ID is not passed as parameter then links are created for objects which are of type single file and has Process_ID=1
		       set @FilterCondition =' ' +QUOTENAME(@DeletedColumn)+' is null and  Single_File=1 and Process_ID=' + cast(@ProcessID as varchar(20))

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

                    Set @DebugText = ''
                    Set @DebugText = @DefaultDebugText + @DebugText
                    Set @Procedurestep = 'Get XML'
                    
                    IF @debug > 0
                    	BEGIN
                        SELECT CAST(@XML AS XML)
                    		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
                    	END
                    
             -----------------------------------------------------------------
			-- Checking module access for CLR procdure  spMFCreatePublicSharedLinkInternal
			------------------------------------------------------------------
	Set @DebugText = ''
	Set @DebugText = @DefaultDebugText + @DebugText
	Set @Procedurestep = 'Check license '
	
	IF @debug > 0
		Begin
			RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
		END
	
     
EXEC dbo.spMFCheckLicenseStatus @InternalProcedureName = 'spMFCreatePublicSharedLinkInternal',
    @ProcedureName = @ProcedureName,
    @ProcedureStep = @ProcedureStep,
--    @ProcessBatch_id = @ProcessBatch_id,
    @Debug = 0            
                 

Set @DebugText = ''
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'process wrapper '

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END

			EXEC spMFCreatePublicSharedLinkInternal @VaultSettings,@Xml ,@OutPutXML Output

			SET @XmlOut = @OutPutXML

Set @DebugText = ''
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Wrapper output '

IF @debug > 0
	BEGIN
         SELECT CAST(@XmlOut AS XML)
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END

				
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

Set @DebugText = ''
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Update table'

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END


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
		END
        
        Set @DebugText = ''
        Set @DebugText = @DefaultDebugText + @DebugText
        Set @Procedurestep = 'Completed '
        
        IF @debug > 0
        	Begin
        		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
        	END
        

 End try
 begin CATCH
    IF (SELECT OBJECT_ID('tempdb..#tmpLink')) IS NOT null
       DROP TABLE [#TmpLink];

	      
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
