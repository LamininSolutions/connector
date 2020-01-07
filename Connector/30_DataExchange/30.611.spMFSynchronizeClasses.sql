PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeClasses]';
GO

   --BELOW HEADER
/*------------------------------------------------------------------------------------------------
	Author: DEV2
	Create date: 27-03-2015
	
	
															
------------------------------------------------------------------------------------------------*/



SET NOCOUNT ON 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeClasses'
  , -- nvarchar(100)
    @Object_Release = '3.1.5.41'
  , -- varchar(50)
    @UpdateFlag = 2
 -- smallint
 
GO


IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFSynchronizeClasses'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeClasses]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFSynchronizeClasses]
      (
        @VaultSettings [NVARCHAR](4000)
      , @Debug SMALLINT = 0
      , @Out [NVARCHAR](MAX) OUTPUT
      , @IsUpdate SMALLINT = 0
      )
AS
/*rST**************************************************************************

======================
spMFSynchronizeClasses
======================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @VaultSettings nvarchar(4000)
    - use fnMFVaultSettings()
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode
  @Out nvarchar(max) (output)
    - XML result
  @IsUpdate smallint (optional)
    - Default = 0
    - 1 = Push updates from SQL to M-Files

Purpose
=======

Internal procedure to synchronize classes
Used by spMFSynchronizeMetadata and spMFSynchronizeSpecificMetadata

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2018-04-04  DEV2       Added Module validation code
2017-12-3   LC         Prevent MFID -100 assignements to be included in update
2017-09-11  LC         Resolve issue with constraints
2016-09-26  DevTeam2   Removed vault settings and pass them as comma separate string in @VaultSettings parameter.
==========  =========  ========================================================

**rST*************************************************************************/

      BEGIN
            SET NOCOUNT ON;

      ---------------------------------------------
      --DECLARE LOCAL VARIABLE
      ---------------------------------------------
            DECLARE @ClassXml [NVARCHAR](MAX)
                  , @ClassPptXml [NVARCHAR](MAX)
                  , @Output INT
                  , @ProcedureName VARCHAR(100) = 'spMFSynchronizeClasses'
                  , @ProcedureStep VARCHAR(100) = 'Start Syncronise Classes ';
            DECLARE @Result_value INT;
  
            IF @Debug = 1
               RAISERROR('%s : Step %s',10,1,@ProcedureName, @ProcedureStep);

            BEGIN TRY
	
        
------------------------------------------------------
		--Drop CONSTRAINT
		------------------------------------------------------
                  SET @ProcedureStep = 'Drop CONSTRAINT';
                  IF @Debug = 1
                     RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

                  IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NOT NULL )
                     BEGIN
                           ALTER TABLE [dbo].[MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass];
                     END;		
				IF ( OBJECT_ID('FK_MFClassProperty_MFClass_ID', 'F') IS NOT NULL )
					BEGIN
						ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFClass_ID];
					END;
				IF ( OBJECT_ID('FK_MFProperty_ID', 'F') IS NOT NULL )
					BEGIN
						ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFProperty_ID];
					END;
					IF ( OBJECT_ID('FK_MFClassProperty_MFProperty', 'F') IS NOT NULL )
					BEGIN
						ALTER TABLE [MFClassProperty] DROP CONSTRAINT [FK_MFClassProperty_MFProperty];
					END;
      ------------------------------------------------------------
      --CALL WRAPPER PROCEDURE TO GET CLASS DETAILS FROM M-FILES
      -------------------------------------------------------------
                  SET @ProcedureStep = 'Get Classes';
                  IF @Debug = 1
                     RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);
           
       -----------------------------------------------------------------------
	    --Checking Module access 
	   ------------------------------------------------------------------------

	   EXEC [dbo].[spMFCheckLicenseStatus] 'spMFGetClass',@ProcedureName,@ProcedureStep

                  EXEC [dbo].[spMFGetClass]
                    @VaultSettings
                  , @ClassXML OUTPUT
                  , @ClassPptXML OUTPUT;

                  IF @@error <> 0
                     RAISERROR('Error Getting Classes',16,1);
          
      -------------------------------------------------------------------------
      -- CALLS 'spMFInsertClass' TO INSERT THE CLASS DETAILS INTO MFClass TABLE
      -------------------------------------------------------------------------
  
                  BEGIN TRY
                        SET @ProcedureStep = 'Insert class detail into MFClass Table';
                        IF @Debug = 1
                           RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

                        IF @IsUpdate = 1
                           BEGIN
						  
                                 SELECT [MFClass].[ID]
                                      , [MFClass].[MFID]
                                      , [MFClass].[Name]
                                      , [MFClass].[Alias]
                                      , [MFClass].[IncludeInApp]
                                      , [MFClass].[TableName]
                                      , [MFClass].[MFObjectType_ID]
                                      , [MFClass].[MFWorkflow_ID]
                                 INTO   [#TmpClass]
                                 FROM   [dbo].[MFClass]
                                 WHERE  [MFClass].[Deleted] = 0 AND MFID >= 0 -- MFID -100 cannot have an alias

                                 EXEC @Result_value = [dbo].[spMFInsertClass]
                                    @ClassXml
                                  , 1 --IsFullUpdate Set to TRUE 
                                  , @Output OUTPUT
                                  , @Debug;

                                 SET @ProcedureStep = 'SQL Class detail inserted';
                                 IF @Debug = 1
                                    RAISERROR('%s : Step %s with return %i',10,1,@ProcedureName,@ProcedureStep,@Result_value);

                                 DECLARE @XML NVARCHAR(MAX)

                                 SET @XML = ( SELECT    ISNULL([MFCLS].[ID], 0) AS 'ClassDetails/@SqlID'
                                                      , ISNULL([MFCLS].[MFID], 0) 'ClassDetails/@MFID'
                                                      , ISNULL([MFCLSN].[Name], '') 'ClassDetails/@Name'
                                                      , ISNULL([MFCLSN].[Alias], '') 'ClassDetails/@Alias'
                                                      , ISNULL([MFCLS].[IncludeInApp], 0) 'ClassDetails/@IncludeInApp'
                                                      , ISNULL([MFCLS].[TableName], '') 'ClassDetails/@TableName'
                                                      , ISNULL([MFCLS].[MFObjectType_ID], 0) 'ClassDetails/@MFObjectType_ID'
                                                      , ISNULL([MFCLS].[MFWorkflow_ID], 0) 'ClassDetails/@MFWorkflow_ID'
                                              FROM      [dbo].[MFClass] [MFCLS]
                                              INNER JOIN [#TmpClass] [MFCLSN] ON [MFCLS].[MFID] = [MFCLSN].[MFID]
                                                                             AND ( [MFCLS].[Alias] != [MFCLSN].[Alias]
                                                                                   OR [MFCLS].[Name] != [MFCLSN].[Name]
                                                                                 )
                                            FOR
                                              XML PATH('')
                                                , ROOT('CLS')
                                            )

								IF @debug = 1
								select @xml;

                                 DECLARE @Output1 NVARCHAR(MAX)

								 -----------------------------------------------------------------------
									--Checking Module access 
								 ------------------------------------------------------------------------

								EXEC [dbo].[spMFCheckLicenseStatus] 'spMFUpdateClass',@ProcedureName,@ProcedureStep

                                 EXEC [dbo].[spMFUpdateClass]
                                    @VaultSettings
                                  , @XML
                                  , @Output1 OUTPUT

								  IF @debug = 1
								PRINT @Output1;


                                 UPDATE [CLs]
                                 SET    [CLs].[Alias] = [t].[Alias]
                                      , [CLs].[Name] = [t].[Name]
                                 FROM   [dbo].[MFClass] [CLs]
                                 INNER JOIN [#TmpClass] [t] ON [t].[MFID] = [CLs].[MFID]

                                 DROP TABLE [#TmpClass]
                           END
                        ELSE
                           BEGIN
						 
                                 EXEC @Result_value = [dbo].[spMFInsertClass]
                                    @ClassXml
                                  , 1 --IsFullUpdate Set to TRUE 
                                  , @Output OUTPUT
                                  , @Debug;

                           END
                

                        IF @Debug = 1
                           RAISERROR('%s : Step %s completed with result %i',10,1,@ProcedureName,@ProcedureStep,@Result_value);

                        IF ( @Output > 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All Classes are Updated';
                        IF ( ISNULL(@Output, 0) = 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All Classes are up to date';

					
                        IF @Debug = 1
                           RAISERROR('@Result_Value %s',10,1,@Out);

                  END TRY
                  BEGIN CATCH
	
                        RAISERROR('Syncronisation failed to Insert Classes',16,1);
                  END CATCH;
      -------------------------------------------------------------------------------------------------
      -- CALLS 'spMFInsertClassProperty' TO INSERT THE CLASS PROPERTY DETAILS INTO MFClassProperty TABLE
      --------------------------------------------------------------------------------------------------
                  SET @ProcedureStep = 'Insert update detail into MFClassProperty Table';

                  IF @Debug = 1
                     RAISERROR('%s : Step %s',10,1,@ProcedureName,@ProcedureStep);

                  BEGIN TRY
 
                        EXEC @Result_value = [dbo].[spMFInsertClassProperty]
                            @ClassPptXml
                          , 1 --IsFullUpdate Set to TRUE 
                          , @Output OUTPUT
                          , @Debug;

                        IF @Debug = 1
                           RAISERROR('%s : Step %s Completed with result %i',10,1,@ProcedureName,@ProcedureStep,@Result_value);

                        IF ( @Output > 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All ClassProperties are Updated';
                        IF ( ISNULL(@Output, 0) = 0
                             AND @Result_value = 1
                           )
                           SET @Out = 'All ClassProperties are upto date';


                  END TRY
                  BEGIN CATCH

                        RAISERROR('%s : Step %s InsertClassProperty Failed to complete',16,1,@ProcedureName,@ProcedureStep);
                  END CATCH;
	----------------------------------------------
	--	Add CONSTRAINT to [dbo].[MFClassProperty]
	--	--------------------------------------------
                  SET @ProcedureStep = 'Add Constraint';

                  IF @Debug = 1
                     BEGIN
                           RAISERROR('Step %s',10,1,@ProcedureName,@ProcedureStep);
                           SELECT   *
                           FROM     [dbo].[MFClassProperty] AS [mcp];
                     END;

BEGIN TRY

            IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NULL )
                BEGIN

                    ALTER TABLE [dbo].[MFClassProperty]
                    WITH CHECK  ADD CONSTRAINT [FK_MFClassProperty_MFClass] FOREIGN KEY ([MFClass_ID]) REFERENCES [dbo].[MFClass]([ID]);

                END;
END TRY
BEGIN CATCH
       RAISERROR('%s : Step %s fail to create constraint',10,1,@ProcedureName,@ProcedureStep);
END CATCH;


                  SELECT    @ProcedureStep = 'END Syncronise Classes:' + @Out;

                  IF @Debug = 1
                     BEGIN
                           RAISERROR('%s : Step %s Return %i',10,1,@ProcedureName,@ProcedureStep, @Result_value);
                     END;

                  SET NOCOUNT OFF;
                  RETURN 1;
            END TRY

            BEGIN CATCH

                  SET NOCOUNT ON;

                  BEGIN
			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
                        INSERT  INTO [dbo].[MFLog]
                                ( [SPName]
                                , [ErrorNumber]
                                , [ErrorMessage]
                                , [ErrorProcedure]
                                , [ErrorState]
                                , [ErrorSeverity]
                                , [ErrorLine]
                                , [ProcedureStep]
				                )
                        VALUES  ( @ProcedureName
                                , ERROR_NUMBER()
                                , ERROR_MESSAGE()
                                , ERROR_PROCEDURE()
                                , ERROR_STATE()
                                , ERROR_SEVERITY()
                                , ERROR_LINE()
                                , @ProcedureStep
				                );
                  END;

                  DECLARE @ErrNum INT = ERROR_NUMBER()
                        , @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE()
                        , @ErrSeverity INT = ERROR_SEVERITY()
                        , @ErrState INT = ERROR_STATE()
                        , @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE()
                        , @ErrLine INT = ERROR_LINE();

                  SET NOCOUNT OFF;

                  RAISERROR (
				@ErrMessage
				,@ErrSeverity
				,@ErrState
				,@ErrProcedure
				,@ErrState
				,@ErrMessage
				);
                  RETURN -1;
            END CATCH;
      END;

GO
