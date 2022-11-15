
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFChangeClass]';
GO

SET NOCOUNT ON;

EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFChangeClass'
  ,-- nvarchar(100)
    @Object_Release = '4.10.30.74'
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
@MFTableName NVARCHAR(128),
    @RetainDeletions bit = 0,
    @IsDocumentCollection BIT = 0,
 @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
)
AS 
/*rST**************************************************************************
   
===============
spMFChangeClass   
===============
   
Return
- 1 = Success
- -1 = Error

Parameters
    @MFTableName
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
    @RetainDeletions bit
    - Default = No
    - Set explicity to 1 if the class table should retain deletions
    @IsDocumentCollection
    - Default = No
    - Set explicitly to 1 if the class table refers to a document collection class table
    @ProcessBatch_ID (optional, output)
    Referencing the ID of the ProcessBatch logging table
    @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode
   
Purpose
=======

The purpose of this procedure is to move the records from one class table to another class table and synxhronize records into M-Files.
   
Additional Info
===============

A prerequisit for running this procedure is to set the new class_ID on the object and set the process_ID = 1 in the table set as @MFTableName.  Then run this procedure.  It will firstly update the records on the source table to M-Files, and then update the records in the destination table from MF to SQL.  Finally, the source table will be updated from MF to SQL to remove the objects where the class was changed.
   
Examples
========
   
.. code:: sql

    DECLARE	@return_value int,
	@ProcessBatch_ID int

    EXEC [dbo].[spMFChangeClass]
		@MFTableName = N'MFCustomer',
		@ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
		@Debug = 0

Changelog
=========
   
==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2022-09-02  LC         Add additional parameters for spmfupdatetable
2020-08-22  LC         Deleted column change
2019-08-30  JC         Added documentation
2017-01-17  LC         Create procedure
==========  =========  ========================================================
   
**rST*************************************************************************/
   
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
                       ,@DeletedColumn NVARCHAR(100);

                SELECT @DeletedColumn = ColumnName FROM MFProperty WHERE MFID = 27;
					 

                SET @ProcedureStep = 'Inserting Source table ObjID with Class_ID into Temp table';

				SET @SqlQuery='insert into #TempChangeClass(ObjID,Class_ID)
							   Select ObjID ,Class_ID from '+@MFTableName+' where Process_ID=1 and '+QUOTENAME(@DeletedColumn)+' is null'

				EXEC [sys].[sp_executesql] 
				           @SqlQuery

				----------Update source table from  Sql to M-files to change class -----------

				SET @ProcedureStep = 'Moving record from Source table to destination table by Synch from sql to M-files';
				
				EXEC dbo.spMFUpdateTable @MFTableName = @MFTablename,
                         @UpdateMethod = 0,                        
                         @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug

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

                        EXEC dbo.spMFUpdateTable @MFTableName = @DestClass_Name,
                         @UpdateMethod = 1,                        
                         @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug


						SET @Counter=@Counter+1
					
				 END
                 
				

				--SET @SqlQuery= 'Update '+ @MFTableName +' set Process_ID=1 where ObjID in (
				--               select ObjID from #TempChangeClass) and Process_ID=0'



				

                EXEC [sys].[sp_executesql] 
				           @SqlQuery

				SET @SqlQuery ='Select @ObjID= COALESCE(@ObjID + '', '', '''') + cast(ObjID as nvarchar(20))from '
				                + @MFTableName +
							   ' where Process_ID=1 and '+QUOTENAME(@DeletedColumn)+' is null'

				EXEC [sys].[sp_executesql] 
				            @SqlQuery
						   , N'@ObjID Nvarchar(4000) OUTPUT'
						   ,@ObjID  OutPut


				
				SET @ProcedureStep = 'remove deleted in Souce table'+@MFTableName+' ;'

				Declare @ObjIDs Nvarchar(4000)
				select @ObjIDs=@ObjID			
                
                EXEC dbo.spMFUpdateTable @MFTableName = @MFTablename,
                         @UpdateMethod = 1,                        
                         @ObjIDs = @objIDs,
                         @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug

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