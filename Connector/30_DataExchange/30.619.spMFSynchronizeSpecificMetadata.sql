PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeSpecificMetadata]';
GO


SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFSynchronizeSpecificMetadata'
-- nvarchar(100)
  , @Object_Release = '3.1.3.40'
-- varchar(50)
  , @UpdateFlag = 2;
-- smallint

GO

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINES].[ROUTINE_NAME] = 'spMFSynchronizeSpecificMetadata' --name of procedure
						AND [ROUTINES].[ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINES].[ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeSpecificMetadata]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeSpecificMetadata]
	(
		@Metadata VARCHAR(100)
	  , @IsUpdate SMALLINT	   = 0
	  , @ItemName VARCHAR(100) = NULL
	  , @Debug	  SMALLINT	   = 0
	)
AS
/*rST**************************************************************************

===============================
spMFSynchronizeSpecificMetadata
===============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Metadata varchar(100)
    type of metadata from list below
  @IsUpdate smallint
    default = 0
    if set to 1 the procedure will update from SQL to M-Files
  @ItemName varchar(100)
    default = null
    only applicable for valuelistitems.  Use name of valuelist to synchronise a specific valuelist
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

Procedure will synchronise the metadata for one of the following

- Properties
- Valuelist
- Valuelistitems
- Workflow
- States
- ObjectType
- LoginAccount
- UserAccount

Using the @ItemName parameter for the specifying a valuelist name, the valuelists items for a specific valuelist can be updated.

Setting the @IsUpdate parameter to 1 will allow for the updating of the name from SQL to M-Files.

Additional Info
===============

This procedure is particularly useful when a small change was made in the vault that need to be pulled through.  

When changes are made to classes it is very important to perform all the dependent specific synchronizations before doing the class synchronization.

WHEN using the @Metadata parameter, only partial names can be used. 
							- use 'Proper' for 'Properties'
							 - use 'Valuelist' for'Valuelist'
							 - use 'Item' for'Valuelistitems'
							 - use 'Workflow' for'Workflow'
							 - use 'Stat' for'States'
							 - use 'Object' for'ObjectType'
							 - use 'Login' for'LoginAccount'
							 - use 'User' for'UserAccount'

The @Update parameter is used for making a change to the name for the following objects.  A separate routine is used to make a change to valuelist items.  This update only include changing an existing item and cannot add new rows for these objects.

- Properties
- Valuelist
- Workflow
- States
- ObjectType
- LoginAccount
- UserAccount

Refer to :doc:`/procedures/spMFSynchronizeValueListItemsToMfiles/` for updating valuelist items

Examples
========

.. code:: sql

   EXEC [spMFSynchronizeSpecificMetadata] 'Class'; 

.. code:: sql

    EXEC [dbo].[spMFSynchronizeSpecificMetadata]
    @Metadata = 'User', --  ObjectType; Class; Property; Valuelist; ValuelistItem; Workflow; State; User; Login
    @IsUpdate = 0,  -- set to 1 to push updates to M-Files
    @ItemName = NULL , --only application for valuelists
    @Debug = 0

------

Only update value list items for a specific valuelist

.. code:: sql

    EXEC [dbo].[spMFSynchronizeSpecificMetadata] 
	@Metadata = 'Valuelist'	-- to set this for Valuelists
    ,@ItemName = 'Country'	-- use any valuelist name to update only the valuelist items for the selected item

-----

Review the tables with the metadata

.. code:: sql

	SELECT TOP 100 * FROM [dbo].[MFProperty] as [mp]
	SELECT TOP 100 * FROM [dbo].[MFClass] as [mc]
	SELECT TOP 100 * FROM [dbo].[MFValueList] as [mvl]
	SELECT TOP 100 * FROM [dbo].[MFValueListItems] as [mvli]
	SELECT TOP 100 * FROM [dbo].[MFWorkflow] as [mw]
	SELECT TOP 100 * FROM [dbo].[MFWorkflowState] as [mws]
	SELECT TOP 100 * FROM [dbo].[MFObjectType] as [mot]
	SELECT TOP 100 * FROM [dbo].[MFUserAccount] as [mua]
	SELECT TOP 100 * FROM [dbo].[MFLoginAccount] as [mla]

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2016-08-22  LC         Update settings index
2016-09-09  LC         Add login accounts and user accounts
2016-09-09  LC         provide for slight differences in metadata parameter
2016-09-26  DevTeam2   Removed vault settings parameters 
2016-12-08  LC         Add update as parameter
2015-04-08  Dev1       Create procedure
==========  =========  ========================================================

**rST*************************************************************************/

	BEGIN


		---------------------------------------------
		--DECLARE LOCAL VARIABLE
		--------------------------------------------- 
		DECLARE
			@VaultSettings NVARCHAR(4000), @ProcedureStep sysname = 'START', @MFvaluelistID INT = 0;

		---------------------------------------------
		-- ACCESS CREDENTIALS FROM Setting TABLE
		---------------------------------------------

		SELECT	@VaultSettings = [dbo].[FnMFVaultSettings]();


		SET @Metadata = CASE WHEN @Metadata LIKE 'Class%' THEN 'Class'
							 WHEN @Metadata LIKE 'Proper%' THEN 'Properties'
							 WHEN @Metadata LIKE 'Valuelist' THEN 'Valuelist'
							 WHEN @Metadata LIKE '%Item%' THEN 'Valuelistitems'
							 WHEN @Metadata LIKE 'Valuelist%' THEN 'Valuelist'
							 WHEN @Metadata LIKE 'Workflow' THEN 'Workflow'
							 WHEN @Metadata LIKE '%Stat%' THEN 'States'
							 WHEN @Metadata LIKE 'Object%' THEN 'ObjectType'
							 WHEN @Metadata LIKE 'Login%' THEN 'LoginAccount'
							 WHEN @Metadata LIKE 'User%' THEN 'UserAccount'
							 ELSE NULL
						END;

		BEGIN
			BEGIN TRY
				-- BEGIN TRANSACTION;
				---------------------------------------------
				--DECLARE LOCAL VARIABLE
				--------------------------------------------- 
				DECLARE
					@ResponseMFObject		NVARCHAR(2000)
				  , @ResponseProperties		NVARCHAR(2000)
				  , @ResponseValueList		NVARCHAR(2000)
				  , @ResponseValuelistItems NVARCHAR(2000)
				  , @ResponseWorkflow		NVARCHAR(2000)
				  , @ResponseWorkflowStates NVARCHAR(2000)
				  , @ResponseMFClass		NVARCHAR(2000)
				  , @ResponseLoginAccount	NVARCHAR(2000)
				  , @ResponseuserAccount	NVARCHAR(2000)
				  , @Response				NVARCHAR(2000)
				  , @SPName					NVARCHAR(100)
				  , @Return_Value			INT;

				IF @Metadata = 'ObjectType'
					BEGIN
						---------------------------------------------
						--SYNCHRONIZE OBJECT TYPES
						---------------------------------------------
						SELECT
							@ProcedureStep = 'Synchronizing ObjectType', @SPName = 'spMFSynchronizeObjectType';

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeObjectType]
							@VaultSettings, @Debug, @ResponseMFObject OUTPUT, @IsUpdate;
					END;

				IF @Metadata = 'LoginAccount'
					BEGIN
						---------------------------------------------
						--SYNCHRONIZE login accounts
						---------------------------------------------
						SELECT
							@ProcedureStep = 'Synchronizing Login Accoount', @SPName = 'spMFSynchronizeLoginAccounte';

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeLoginAccount]
							@VaultSettings, @Debug, @ResponseLoginAccount OUTPUT;
					END;


				IF @Metadata = 'UserAccount'
					BEGIN
						---------------------------------------------
						--SYNCHRONIZEuser accounts
						---------------------------------------------
						SELECT
							@ProcedureStep = 'Synchronizing UserAccount', @SPName = 'spMFSynchronizeUserAccount';

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeUserAccount]
							@VaultSettings, @Debug, @ResponseMFObject OUTPUT;
					END;


				---------------------------------------------
				--SYNCHRONIZE PROEPRTY
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing Properties', @SPName = 'spMFSynchronizeProperties';

				IF @Metadata = 'Properties'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeProperties]
							@VaultSettings, @Debug, @ResponseProperties OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE VALUE LIST
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing ValueList', @SPName = 'spMFSynchronizeValueList';

				IF @Metadata = 'ValueList'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeValueList]
							@VaultSettings, @Debug, @ResponseValueList OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE VALUELIST ITEMS
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing ValueList Items', @SPName = 'spMFSynchronizeValueListItems';

				IF @Metadata = 'ValueListItems'
					BEGIN
						--print @Metadata

						--Task 1046
						IF @ItemName IS NOT NULL
							BEGIN
								SELECT	@MFvaluelistID = ISNULL([ID], 0)
								FROM	[MFValueList]
								WHERE	[Name] = @ItemName;

							END;
						--print @ItemName 
						--print @MFvaluelistID

						EXECUTE @Return_Value = [dbo].[spMFSynchronizeValueListItems]
							@VaultSettings, @Debug, @ResponseValuelistItems OUTPUT, @MFvaluelistID;

					END;

				---------------------------------------------
				--SYNCHRONIZE WORKFLOW
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing workflow', @SPName = 'spMFSynchronizeWorkflow';

				IF @Metadata = 'Workflow'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeWorkflow]
							@VaultSettings, @Debug, @ResponseWorkflow OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE WORKFLOW STATES
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing Workflow states', @SPName = 'spMFSynchronizeWorkflowsStates';

				IF @Metadata LIKE 'State%'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeWorkflowsStates]
							@VaultSettings, @Debug, @ResponseWorkflowStates OUTPUT, @IsUpdate;
					END;

				---------------------------------------------
				--SYNCHRONIZE Class
				---------------------------------------------
				SELECT
					@ProcedureStep = 'Synchronizing Class', @SPName = 'spMFSynchronizeClasses';

				IF @Metadata = 'Class'
					BEGIN
						EXECUTE @Return_Value = [dbo].[spMFSynchronizeClasses]
							@VaultSettings, @Debug, @ResponseMFClass OUTPUT, @IsUpdate;

					--IF ( OBJECT_ID('FK_MFClassProperty_MFClass', 'F') IS NULL )
					--                BEGIN

					--                    ALTER TABLE [dbo].[MFClassProperty]
					--                    WITH CHECK  ADD CONSTRAINT [FK_MFClassProperty_MFClass] FOREIGN KEY ([MFClass_ID]) REFERENCES [dbo].[MFClass]([ID]);

					--                END;

					END;

				DECLARE @ProcessStep VARCHAR(100);
				SELECT	@ProcessStep = 'END Syncronise specific metadata';


				IF @Debug > 0
					BEGIN
						RAISERROR('Step %s Return %i', 10, 1, @ProcessStep, @Return_Value);
					END;

				
				IF @Metadata = NULL
					BEGIN
						PRINT 'Invalid Selection';
						RETURN -1;
					END;
				ELSE RETURN 1;
				SET NOCOUNT OFF;
			--COMMIT TRANSACTION;
			END TRY
			BEGIN CATCH
--				ROLLBACK TRANSACTION;

				INSERT INTO [dbo].[MFLog] ( [SPName]
										  , [ProcedureStep]
										  , [ErrorNumber]
										  , [ErrorMessage]
										  , [ErrorProcedure]
										  , [ErrorState]
										  , [ErrorSeverity]
										  , [ErrorLine]
										  )
				VALUES (
						   @SPName
						 , @ProcedureStep
						 , ERROR_NUMBER()
						 , ERROR_MESSAGE()
						 , ERROR_PROCEDURE()
						 , ERROR_STATE()
						 , ERROR_SEVERITY()
						 , ERROR_LINE()
					   );

				RETURN 2;
			END CATCH;
		END;
	END;

GO
