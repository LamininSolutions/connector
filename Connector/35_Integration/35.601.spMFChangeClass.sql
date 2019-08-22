
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFChangeClass]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFChangeClass'
  ,-- nvarchar(100)
    @Object_Release = '2.1.0.0'
  ,-- varchar(50)
    @UpdateFlag = 2;
	-- smallint
GO

IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFChangeClass' --name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';

         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFChangeClass]
AS
       SELECT   'created, but not implemented yet.';
	--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

--spMFChangeClass 'MFCustomer'
alter Procedure spMFChangeClass
(
		@MFTableName NVARCHAR(128)
)
AS /*******************************************************************************
   ** Desc:  The purpose of this procedure is to move the records from one class 
          table to another class table and synxhronize records into M-Files.
   ** Calls: spMFUpdateTable

   ** Date:  06-01-2017

   ******************************************************************************/
      Begin
	   
			  BEGIN TRY
					
				CREATE TABLE #TempChangeClass
				( 
				  ObjID int,
				  Class_ID int
				)

				DECLARE @SqlQuery nvarchar(max)
					   ,@Total_Rows int
					   ,@Counter int
					   ,@DestiClass_ID int
					   ,@DestClass_Name NVARCHAR(128)
					   ,@ProcedureStep sysname = 'Start'
					   ,@ObjID NVARCHAR(4000)
					 

                SET @ProcedureStep = 'Inserting Source table ObjID with Class_ID into Temp table';

				SET @SqlQuery='insert into #TempChangeClass(ObjID,Class_ID)
							   Select ObjID ,Class_ID from '+@MFTableName+' where Process_ID=1 and Deleted=0'

				EXEC [sys].[sp_executesql] 
				           @SqlQuery

				----------Update source table from  Sql to M-files to change class -----------

				SET @ProcedureStep = 'Moving record from Source table to destination table by Synch from sql to M-files';
				
				EXEC spMFUpdateTable @MFTableName,0

				Create table #TempDestinationClass
				(
				 RowID int identity(1,1)
				,Class_ID int
				)
				insert into #TempDestinationClass
				(
				 Class_ID
				)
				select distinct
				(
				 Class_ID
				) 
				from 
				 #TempChangeClass

				select @Total_Rows=max(RowID) from #TempDestinationClass

				Set @Counter =1

				while @Counter<= @Total_Rows
				 BEGIN
						Select @DestiClass_ID=Class_ID from #TempDestinationClass where RowID=@Counter
						select @DestClass_Name=TableName from MFClass where MFID=@DestiClass_ID

						----------Update Destination table from M-files to Sql-----------
						SET @ProcedureStep = 'Synch records from M_files to sql in destination table'+@DestClass_Name+' ;'
						EXEC spMFUpdateTable @DestClass_Name,1 
						SET @Counter=@Counter+1
					
				 END
                 
				

				--SET @SqlQuery= 'Update '+ @MFTableName +' set Process_ID=1 where ObjID in (
				--               select ObjID from #TempChangeClass) and Process_ID=0'



				

                EXEC [sys].[sp_executesql] 
				           @SqlQuery

				SET @SqlQuery ='Select @ObjID= COALESCE(@ObjID + '', '', '''') + cast(ObjID as nvarchar(20))from '
				                + @MFTableName +
							   ' where Process_ID=1 and deleted=0'

				EXEC [sys].[sp_executesql] 
				            @SqlQuery
						   , N'@ObjID Nvarchar(4000) OUTPUT'
						   ,@ObjID  OutPut


				
				SET @ProcedureStep = 'Marking moved records as Deleted=1 from in Souce table'+@MFTableName+' ;'

				Declare @ObjIDs Nvarchar(4000)
				select @ObjIDs=@ObjID

				
				Exec spMFUpdateTable @MFTableName,1,null,null,@objIDs,null,null,null
				


				
				DROP TABLE #TempChangeClass
				DROP TABLE #TempDestinationClass

			  End try
			  BEGIN CATCH
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
                  VALUES    ( 'spMFUpdateTable'
                            , ERROR_NUMBER()
                            , ERROR_MESSAGE()
                            , ERROR_PROCEDURE()
                            , @ProcedureStep
                            , ERROR_STATE()
                            , ERROR_SEVERITY()
                            , 0
                            , ERROR_LINE()
                            );

			  End CATCH
End