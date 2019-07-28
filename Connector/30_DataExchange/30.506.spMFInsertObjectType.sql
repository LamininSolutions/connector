PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFInsertObjectType]';
go
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFInsertObjectType', -- nvarchar(100)
    @Object_Release = '3.1.2.38', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFInsertObjectType'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFInsertObjectType]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF
go

ALTER PROCEDURE [dbo].[spMFInsertObjectType] (@Doc           NVARCHAR(max)
                                               ,@isFullUpdate BIT
                                               ,@Output       INT OUTPUT
                                               ,@Debug        SMALLINT = 0)
AS
  /*******************************************************************************
  ** Desc:  The purpose of this procedure is to insert objectType details into MFobjectType table.  
  **  

  ** Date:            27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 
  ******************************************************************************/
  BEGIN
      BEGIN TRY
          BEGIN TRANSACTION

          SET NOCOUNT ON

          -----------------------------------------------
          --LOCAL VARIABLE DECLARATION
          -----------------------------------------------
          DECLARE @IDoc         INT
                  ,@ProcedureStep SYSNAME = 'Start'
                  ,@XML         XML = @Doc

          SET @ProcedureStep = 'Creating #ObjectTypeTble'

          CREATE TABLE #ObjectTypeTble
            (
               [Name]   VARCHAR(100)
               ,[Alias] NVARCHAR(100)
               ,[MFID]  INT NOT NULL
            )

          SET @ProcedureStep = 'Insert values into #ObjectTypeTble'
 DECLARE @procedureName NVARCHAR(128) = 'spMFInsertObjectType';

            IF @Debug = 1
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);
          -----------------------------------------------
          -- INSERT DAT FROM XML INTO TEMPORARY TABLE
          -----------------------------------------------
          INSERT INTO #ObjectTypeTble
                      (NAME,
                       Alias,
                       MFID)
          SELECT t.c.value('(@Name)[1]', 'NVARCHAR(100)')   AS NAME
                 ,t.c.value('(@Alias)[1]', 'NVARCHAR(100)') AS Alias
                 ,t.c.value('(@MFID)[1]', 'INT')            AS MFID
          FROM   @XML.nodes('/form/objectType')AS t(c)

          IF @Debug = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #ObjectTypeTble
            END

          SET @ProcedureStep = 'Insert values into #objectTypes'

          -----------------------------------------------------
          --Storing the difference into #tempNewObjectTypeTble 
          -----------------------------------------------------
          SELECT *
          INTO   #ObjectTypes
          FROM   ( SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   #ObjectTypeTble
                   EXCEPT
                   SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   MFObjectType ) tempTbl

          IF @Debug = 1
            BEGIN
                 RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #ObjectTypes
            END

          SET @ProcedureStep = 'Creating new table #NewObjectTypes'

          ------------------------------------------------------------
          --Creating new table to store the updated ObjectType details 
          ------------------------------------------------------------
          CREATE TABLE #NewObjectTypes
            (
               [Name]   VARCHAR(100)--COLLATE Latin1_General_CI_AS
               ,[Alias] NVARCHAR(100)--COLLATE Latin1_General_CI_AS
               ,[MFID]  INT NOT NULL
            )

          SET @ProcedureStep = 'Inserting values into #NewObjectTypes'

          -----------------------------------------------
          --Inserting the Difference 
          -----------------------------------------------
          INSERT INTO #NewObjectTypes
          SELECT *
          FROM   #ObjectTypes

          IF @Debug = 1
            BEGIN
                RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #NewObjectTypes
            END

          SET @ProcedureStep = 'Inserting values into MFObjectType'

          -----------------------------------------------
          --Updating the MFObjectType 
          -----------------------------------------------
          IF Object_id('tempdb..#NewObjectTypes') IS NOT NULL
            BEGIN
                UPDATE MFObjectType
                SET    MFObjectType.NAME = #NewObjectTypes.NAME,
                       MFObjectType.Alias = #NewObjectTypes.Alias,
                       MFObjectType.Deleted = 0,
					   MFObjectType.ModifiedOn=getdate()  --Added for task 568
                FROM   MFObjectType
                       INNER JOIN #NewObjectTypes
                               ON MFObjectType.MFID = #NewObjectTypes.MFID

                SET @Output = @@ROWCOUNT
            END

          IF @Debug = 1
            BEGIN
            RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   MFObjectType
            END

          SET @ProcedureStep = 'Inserting values into #temp'

          -----------------------------------------------
          --Adding The new property 	
          -----------------------------------------------
          SELECT *
          INTO   #temp
          FROM   ( SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   #ObjectTypeTble
                   EXCEPT
                   SELECT NAME
                          ,Alias
                          ,MFID
                   FROM   MFObjectType ) newPprty

          IF @Debug = 1
            BEGIN
              RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                --SELECT *
                --FROM   #temp
            END

          SET @ProcedureStep = 'Inserting values into MFObjectType'

          -----------------------------------------------
          -- INSERT NEW OBJECT TYPE DETAILS
          -----------------------------------------------
          INSERT INTO MFObjectType
                      (NAME,
                       Alias,
                       MFID,
                       Deleted,
					   CreatedOn --Added for task 568
					   
					   )
          SELECT NAME
                 ,Alias
                 ,MFID
                 ,0 AS Deleted
				 ,getdate() --Added for task 568
          FROM   #temp

          SET @Output = @Output + @@ROWCOUNT

          IF ( @isFullUpdate = 1 )
            BEGIN
                SET @ProcedureStep = 'Full update'

                -----------------------------------------------
                -- Select MFID Which are deleted from M-Files 
                -----------------------------------------------
                SELECT MFID
                INTO   #DeletedObjectTypes
                FROM   ( SELECT MFID
                         FROM   MFObjectType
                         EXCEPT
                         SELECT MFID
                         FROM   #ObjectTypeTble ) #DeletedWorkFlowStates

                IF @Debug = 1
                  BEGIN
                     RAISERROR('%s : Step %s',10,1,@procedureName, @ProcedureStep);

                      --SELECT *
                      --FROM   #DeletedObjectTypes
                  END

                SET @ProcedureStep = 'updating MFObjectTypes'

                -----------------------------------------------------
                --Deleting the ObjectTypes Thats deleted from M-Files
                ------------------------------------------------------ 
                UPDATE MFObjectType
                SET    DELETED = 1
                WHERE  MFID IN ( SELECT MFID
                                 FROM   #DeletedObjectTypes )
            END

          -----------------------------------------------
          --Droping all temperory Table 
          -----------------------------------------------
          DROP TABLE #ObjectTypeTble

          DROP TABLE #NewObjectTypes

          SET NOCOUNT OFF

          COMMIT TRANSACTION
      END TRY

      BEGIN CATCH
          ROLLBACK TRANSACTION

          SET NOCOUNT ON

          IF @Debug = 1
            BEGIN
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                INSERT INTO MFLog
                            (SPName,
                             ErrorNumber,
                             ErrorMessage,
                             ErrorProcedure,
                             ErrorState,
                             ErrorSeverity,
                             ErrorLine,
                             ProcedureStep)
                VALUES      ('spMFInsertObjectType',
                             Error_number(),
                             Error_message(),
                             Error_procedure(),
                             Error_state(),
                             Error_severity(),
                             Error_line(),
                             @ProcedureStep)
            END

          DECLARE @ErrNum        INT = Error_number()
                  ,@ErrProcedure NVARCHAR(100) =Error_procedure()
                  ,@ErrSeverity  INT = Error_severity()
                  ,@ErrState     INT = Error_state()
                  ,@ErrMessage   NVARCHAR(MAX) = Error_message()
                  ,@ErrLine      INT = Error_line()

          SET NOCOUNT OFF

          RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
      END CATCH
  END

go
