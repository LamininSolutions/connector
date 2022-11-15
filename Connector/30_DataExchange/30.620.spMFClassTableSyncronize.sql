PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFClassTableSynchronize]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',   @ObjectName = N'spMFClassTableSynchronize', -- nvarchar(100)
    @Object_Release = '4.10.30.74', -- varchar(50)
    @UpdateFlag = 2 -- smallint



/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-02
	Database: 
	Description: Syncronise specific class table
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-8-23		lc			change Objids to NVARCHAR(4000)
	2016-12-20		ac			TFS 972: Comment out EXTRA BEGIN TRAN 
	2017-11-23		lc			localization of MF_LastModified date
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

  EXEC [spMFClassTableSynchronize]    @debug = 2
  
-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFClassTableSynchronize'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFClassTableSynchronize]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

/****** Object:  StoredProcedure [dbo].[spMFClassTableSynchronize]    Script Date: 01/03/2016 05:25:58 ******/


ALTER PROC [dbo].[spMFClassTableSynchronize]
    @TableName sysname ,
     @RetainDeletions BIT = 0,
    @IsDocumentCollection BIT = 0,
    @ProcessBatch_ID INT = NULL OUTPUT,
    @Debug SMALLINT = 0
AS /**************************Update procedure for table change*/
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Process_ID INT ,
            @UpdateMethod INT ,
            @ProcedureName VARCHAR(100) = 'spMFClassTableSynchronize' ,
            @ProcedureStep VARCHAR(100) = 'Start' ,
            @Result_Value INT ,
            @TableLastModified DATETIME ,
            @SQL NVARCHAR(MAX) ,
            @Params NVARCHAR(MAX);

 DECLARE @lastModifiedColumn NVARCHAR(100)

	SELECT @lastModifiedColumn = [mp].[ColumnName] FROM [dbo].[MFProperty] AS [mp] WHERE MFID = 21 --'Last Modified'


        SET @ProcedureStep = 'Get last Modified date';

        SET @SQL = N'Select top 1 @TableLastModified = Max('+ QUOTENAME(@lastModifiedColumn) + ') from '
            + QUOTENAME(@TableName);
        SET @Params = N'@TableLastModified datetime output';

        EXEC sp_executesql @SQL, @Params,
            @TableLastModified = @TableLastModified;

        IF @Debug > 0
            BEGIN
                DECLARE @DateString VARCHAR(50);
                SET @DateString = CAST(@TableLastModified AS VARCHAR(50));
                RAISERROR('Proc: %s Step: %s Table Last Update %s ',10,1,@ProcedureName, @ProcedureStep, @DateString);
            END;

   
        BEGIN TRY

		/*--BEGIN BUG 972 2016-12-20 AC 
            BEGIN TRANSACTION; 
            SET @UpdateMethod = 1;

		-- END BUG 972 2016-12-20 AC  */

            BEGIN TRANSACTION;
            
            SET @UpdateMethod = 0;
            SET @ProcedureStep = 'Transaction Update method'
			;


                EXEC dbo.spMFUpdateTable @MFTableName = @TableName,
                         @UpdateMethod = @UpdateMethod,
                         @ProcessBatch_ID = @ProcessBatch_ID ,
                         @RetainDeletions = @RetainDeletions,
                         @IsDocumentCollection = @IsDocumentCollection,
                         @Debug = @debug

            SELECT  @Result_Value;

            COMMIT TRAN;
            
            IF @Debug > 0
                BEGIN
                    SELECT  @Result_Value;
                    RAISERROR('Proc: %s Step: %s Table update method 0 with result %i ',10,1,@ProcedureName, @ProcedureStep, @Result_Value);
                END;

               
            RETURN @Result_Value;
        END TRY
        BEGIN CATCH
            --ROLLBACK; --BUG 972 2016-12-20 AC 
            RAISERROR('Updating of Table failed %s: updatemethod %i: With Error %i',16,1,@TableName,@UpdateMethod,@Result_Value) WITH NOWAIT;
            IF @@TRANCOUNT <> 0
                BEGIN
                    ROLLBACK TRANSACTION;
                END;

            SET NOCOUNT ON;

           -- UPDATE  MFUpdateHistory
           -- SET     UpdateStatus = 'failed'
           -- WHERE   Id = @Update_ID;

           -- INSERT  INTO MFLog
           --         ( SPName ,
           --           ErrorNumber ,
           --           ErrorMessage ,
           --           ErrorProcedure ,
           --           ProcedureStep ,
           --           ErrorState ,
           --           ErrorSeverity ,
           --           Update_ID ,
           --           ErrorLine
			        --)
           -- VALUES  ( @ProcedureName ,
           --           ERROR_NUMBER() ,
           --           ERROR_MESSAGE() ,
           --           ERROR_PROCEDURE() ,
           --           @ProcedureStep ,
           --           ERROR_STATE() ,
           --           ERROR_SEVERITY() ,
           --           null ,
           --           ERROR_LINE()
           --         );

            IF @Debug > 0
                BEGIN
                    SELECT  ERROR_NUMBER() AS ErrorNumber ,
                            ERROR_MESSAGE() AS ErrorMessage ,
                            ERROR_PROCEDURE() AS ErrorProcedure ,
                            @ProcedureStep AS ProcedureStep ,
                            ERROR_STATE() AS ErrorState ,
                            ERROR_SEVERITY() AS ErrorSeverity ,
                            ERROR_LINE() AS ErrorLine;
                END;

            SET NOCOUNT OFF;

            RETURN 2; --For More information refer Process Table
	   
	   
        END CATCH;
	    
    END;

GO

