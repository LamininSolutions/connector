PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFGetMfilesLog]';
go
 
SET NOCOUNT ON; 
EXEC [Setup].[spMFSQLObjectsControl]
    @SchemaName = N'dbo'
  , @ObjectName = N'spMFGetMfilesLog'
  , -- nvarchar(100)
    @Object_Release = '3.1.5.41'
  , -- varchar(50)
    @UpdateFlag = 2;
 -- smallint
 go

 /*
 CHANGE HISTORY
  
 */
IF EXISTS ( SELECT  1
            FROM    [INFORMATION_SCHEMA].[ROUTINES]
            WHERE   [ROUTINES].[ROUTINE_NAME] = 'spMFGetMfilesLog'--name of procedure
                    AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE'--for a function --'FUNCTION'
                    AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo' )
   BEGIN
         PRINT SPACE(10) + '...Stored Procedure: update';
         SET NOEXEC ON;
   END;
ELSE
   PRINT SPACE(10) + '...Stored Procedure: create';
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFGetMfilesLog]
AS
       SELECT   'created, but not implemented yet.';
--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF;
go

ALTER PROCEDURE [dbo].[spMFGetMfilesLog] ( @IsClearMfilesLog BIT = 0, @Debug smallint = 0 )
AS
/*rST**************************************************************************

================
spMFGetMfilesLog
================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IsClearMfilesLog bit (optional)
    - Default = 0
    - 1 = Clear Mfiles log
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

The purpose of this procedure is to insert Mfiles Log details into MFEventLog_OpenXML table.

Additional Info
===============

This procedure can be used on demand. Alternatively it can be included in an Agent to schedule the export on a regular basis.  This may be particularly relevant as M-Files automatically drops events and only maintain the last 10 000 event records.


Example XML for a new object
----------------------------

.. code:: xml

    <event>
      <id>35543</id>
      <type id="NewObject">New document or other object</type>
      <category id="3">NewObject</category>
      <timestamp>2016-11-25 16:27:57.226000000</timestamp>
      <causedbyuser loginaccount="LS-CilliersL" />
      <data>
        <objectversion>
          <objver>
            <objtype id="162">Test</objtype>
            <objid>1163</objid>
            <version>1</version>
          </objver>
          <extid extidstatus="Internal">1163</extid>
          <objectguid>{84E076F0-92A1-49CD-961E-D4A293512FC3}</objectguid>
          <versionguid>{6B2E37C4-2D8F-4B33-A5BE-A117BB9EF7D3}</versionguid>
          <objectflags value="64">
            <objectflag id="64">normal</objectflag>
          </objectflags>
          <originalobjid>
            <vault>{3F4B2DFA-6D56-4D2D-AC4C-8AB3EF7DFE54}</vault>
            <objtype>162</objtype>
            <id>1163</id>
          </originalobjid>
          <title>Lakeisha222</title>
          <displayid>1163</displayid>
        </objectversion>
      </data>
    </event>

Examples
========

.. code:: sql

    EXEC [dbo].[spMFGetMfilesLog]
         @IsClearMfilesLog = 0 -- bit

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2018-04-04  DEV2       Added Licensing module validation code.
2017-09-24  LC         Fix bug 'unknown column'
2017-01-23  DEV2       The purpose of this procedure is to insert Mfiles Log details into MFEventLog_OpenXML table.
==========  =========  ========================================================

**rST*************************************************************************/
      BEGIN
            BEGIN TRY

                  SET NOCOUNT ON;

          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
                  DECLARE @Xml [NVARCHAR](MAX)
                        , @VaultSettings NVARCHAR(4000)
                        , @XMLDoc XML
                        , @ProcedureStep NVARCHAR(MAX)
						, @LoadDate datetime

                  SELECT    @ProcedureStep = 'Create Table #ValueList';
                  DECLARE @procedureName NVARCHAR(128) = 'spMFInsertValueList';

				
			 -----------------------------------------------------
          --ACCESS CREDENTIALS
          -----------------------------------------------------
         

                  SELECT    @VaultSettings = [dbo].[FnMFVaultSettings]()
         

		  -----------------------------------------------------
          -- Remove redundant downloads
          -----------------------------------------------------

		  DELETE FROM [dbo].[MFEventLog_OpenXML]
		  WHERE id > 0

		  -----------------------------------------------------
          -- Get M-Files Log
          -----------------------------------------------------

		  SET @Loaddate = GETDATE()

		  -----------------------------------------------------------------
	        -- Checking module access for CLR procdure  spMFGetObjectType
          ------------------------------------------------------------------
                 EXEC [dbo].[spMFCheckLicenseStatus] 
				      'spMFGetMFilesLogInternal'
					   ,@ProcedureName
					   ,@ProcedureStep


                  EXEC [dbo].[spMFGetMFilesLogInternal]
                    @VaultSettings
                  , @IsClearMFilesLog
                  , @Xml OUTPUT
            
			  IF @Debug > 0
				  SELECT @XML AS XMLReturned;

                  SELECT    @XMLDoc = @Xml

                  INSERT    INTO [dbo].[MFEventLog_OpenXML]
                            ( [XMLData], [LoadedDateTime] )
                  VALUES    ( @XMLDoc, @Loaddate )

				   IF @Debug > 0
				  SELECT * from MFEventLog_OpenXML;

		    -----------------------------------------------------
          -- Add events to MfilesEvents
          -----------------------------------------------------

		  

                  CREATE TABLE [#TempEvent]
                         (
                           [ID] INT
                         , [Type] NVARCHAR(100)
                         , [Category] NVARCHAR(100)
                         , [TimeStamp] NVARCHAR(100)
                         , [CausedByUser] NVARCHAR(100)
                         , [loaddate] DATETIME
                         , [Events] XML
                         )

                  INSERT    INTO [#TempEvent]
                            ( [loaddate]
                            , [Events]
                            )
                            SELECT  [MFEventLog_OpenXML].[LoadedDateTime]
                                  , [tab].[col].[query]('.') AS [event]
                            FROM    [dbo].[MFEventLog_OpenXML]
                            CROSS APPLY [XMLData].[nodes]('/root/event') AS [tab] ( [Col] )
							WHERE [MFEventLog_OpenXML].[LoadedDateTime] = @LoadDate


                  UPDATE    [te]
                  SET       [te].[ID] = [te].[Events].[value]('(/event/id)[1]', 'int')
                          , [te].[Type] = [te].[Events].[value]('(/event/type)[1]', 'varchar(100)')
                          , [te].[Category] = [te].[Events].[value]('(/event/category)[1]', 'varchar(100)')
                          , [te].[TimeStamp] = [te].[Events].[value]('(/event/timestamp)[1]', 'varchar(40)')
                          , [te].[CausedByUser] = [te].[Events].[value]('(/event/causedbyuser/@loginaccount)[1]', 'varchar(100)')
                  FROM      [#TempEvent] AS [te]
				  WHERE te.[loaddate] = @LoadDate

                  MERGE INTO [dbo].[MFilesEvents] [T]
                  USING [#TempEvent] AS [S]
                  ON [T].[ID] = [S].[ID]
                  WHEN MATCHED THEN
                    UPDATE SET [T].[loaddate] = [S].[loaddate]
                  WHEN NOT MATCHED THEN
                    INSERT
                    VALUES ( [S].[ID]
                           , [S].[Type]
                           , [S].[Category]
                           , [S].[TimeStamp]
                           , [S].[CausedByUser]
                           , [S].[loaddate]
                           , [S].[Events]
                           );


                  --SELECT    *
                  --FROM      [dbo].[MFilesEvents]

                  DROP TABLE [#TempEvent]


                  SET NOCOUNT OFF;

          
            END TRY

            BEGIN CATCH

                  SET NOCOUNT ON;

         
                --------------------------------------------------
                -- INSERTING ERROR DETAILS INTO LOG TABLE
                --------------------------------------------------
                  INSERT    INTO [dbo].[MFLog]
                            ( [SPName]
                            , [ErrorNumber]
                            , [ErrorMessage]
                            , [ErrorProcedure]
                            , [ErrorState]
                            , [ErrorSeverity]
                            , [ErrorLine]
                            , [ProcedureStep]
                            )
                  VALUES    ( 'spMFInsertValueList'
                            , ERROR_NUMBER()
                            , ERROR_MESSAGE()
                            , ERROR_PROCEDURE()
                            , ERROR_STATE()
                            , ERROR_SEVERITY()
                            , ERROR_LINE()
                            , @ProcedureStep
                            );

                  DECLARE @ErrNum INT = ERROR_NUMBER()
                        , @ErrProcedure NVARCHAR(100) = ERROR_PROCEDURE()
                        , @ErrSeverity INT = ERROR_SEVERITY()
                        , @ErrState INT = ERROR_STATE()
                        , @ErrMessage NVARCHAR(MAX) = ERROR_MESSAGE()
                        , @ErrLine INT = ERROR_LINE();

                  SET NOCOUNT OFF;

                  RAISERROR (@ErrMessage,@ErrSeverity,@ErrState,@ErrProcedure,@ErrState,@ErrMessage);
            END CATCH;
      END;

go
