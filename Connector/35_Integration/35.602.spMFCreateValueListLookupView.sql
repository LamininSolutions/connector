PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFCreateValueListLookupView]';
GO
SET NOCOUNT ON;
EXEC [setup].[spMFSQLObjectsControl] @SchemaName = N'dbo',
                                     @ObjectName = N'spMFCreateValueListLookupView', -- nvarchar(100)
                                     @Object_Release = '3.1.5.41',                   -- varchar(50)
                                     @UpdateFlag = 2;                                -- smallint

GO

IF EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[ROUTINES]
    WHERE [ROUTINE_NAME] = 'spMFCreateValueListLookupView' --name of procedure
          AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
          AND [ROUTINE_SCHEMA] = 'dbo'
)
BEGIN
    DROP PROC [dbo].[spMFCreateValueListLookupView];
    PRINT SPACE(10) + '...Stored Procedure: dropped and recreated';
    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO


-- the following section will be always executed
SET NOEXEC OFF;
GO

CREATE PROCEDURE [dbo].[spMFCreateValueListLookupView]
(
    @ValueListName NVARCHAR(128),
    @ViewName NVARCHAR(128),
    @Schema NVARCHAR(20) = 'dbo',
    @Debug SMALLINT = 0
)
AS


/*rST**************************************************************************

=============================
spMFCreateValueListLookupView
=============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ValueListName NVARCHAR(128)
    Name of the valuelist
  @ViewName NVARCHAR(128)
    Name of view.  example  'vwCountry'
  @Schema NVARCHAR(20)
    Default = 'dbo'
    We recommend to set it as 'custom'
  @Debug SMALLINT = 0
   - Default = 0
   - 1 = Standard Debug Mode
   - 101 = Advanced Debug Mode

Purpose
=======

To automatically create a view showing all the related columns for the specific valuelist

Additional Info
===============

The view has the following standard columns:
 - Name_ValueListItems : name of the valuelist item
 - MFID_ValueListItems : M-Files internal id of the item
 - DisplayID_ValueListItems : M-files external (visible) id of the item
 - AppRef_ValueListItems : unique reference for item
 - GUID_ValueListItems : GUID if the item
 - OwnerName_ValueListItems : owner valuelist item
 - OwnerMFID_ValueListItems : internal id of owner - default to 0
 - OwnerAppRef_ValueListItems : unique reference for the owner
 - Name_ValueList : name of the valuelist
 - MFID_ValueList : Internal id of valuelist
 - ID_ValueList : SQL ID of the valuelist. This ID joins the valuelist and valuelist item tables
 - OwnerMFID_ValueList : Owner valuelist
 - Deleted : set to 1 if the valuelist item has been deleted
 - Process_ID : default is 0 this is used in processing the valuelist items

Warnings
========

Deleted items are not being pulled into the table when synchronising the valuelist items for the first time.  However, the deleted flag will be updated for items that has been deleted after the initial synchronisation

Examples
========

.. code:: sql

    EXEC dbo.spMFCreateValueListLookupView @ValueListName = 'Country',
    @ViewName = 'vwCountry',
    @Schema = 'custom',
    @Debug = 0

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2018-05-20	LC         Add error check that Valuelist exist
2017-12-10	LC         Add Schema
2017-07-25	AC         Update the join statement to fix error with ownership relationship
2017-05-12	LC         Add deleted = 0 as filter
2015-07-20  DEV2	   New Logic implemented
==========  =========  ========================================================

**rST*************************************************************************/

BEGIN
    BEGIN TRY
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;

        -------------------------------------------------------------
        -- Validate that valuelist exist
        -------------------------------------------------------------

        IF
        (
            SELECT COUNT(*) FROM [dbo].[MFValueList] WHERE [Name] = @ValueListName
        ) = 1
        BEGIN

            DECLARE @Query NVARCHAR(2500),
                    @OwnerTableJoin NVARCHAR(250),
                    @ProcedureStep sysname = 'Start';

            -----------------------------------------
            --DROP THE EXISTSING VIEW
            -----------------------------------------
            DECLARE @object NVARCHAR(100);
            SET @object = DB_NAME() + '.' + QUOTENAME(@Schema) + '.' + QUOTENAME(@ViewName);
            IF
            (
                SELECT OBJECT_ID(@object, 'V')
            ) IS NOT NULL
            BEGIN

                -----------------------------------------
                --DEFINE DYNAMIC QUERY
                -----------------------------------------


                DECLARE @DropQuery NVARCHAR(100) = 'DROP VIEW ' + QUOTENAME(@Schema) + '.' + QUOTENAME(@ViewName) + '';

                SELECT @ProcedureStep = 'DROP EXISTING VIEW';

                IF @Debug > 0
                    SELECT 'view dropped';
                -----------------------------------------
                --EXECUTE DYNAMIC QUERY
                -----------------------------------------
                EXECUTE (@DropQuery);


            END;

            SELECT @ProcedureStep = 'Set Dynamic query';


            ------------------------------------------------------
            --DEFINE DYNAMIC QUERY TO CREATE VIEW
            ------------------------------------------------------

            SELECT @Query
                = 'CREATE VIEW ' + @Schema + '.' + QUOTENAME(@ViewName)
                  + '
 AS
				   
            SELECT 
            Name_ValueListItems = mvli.Name ,
			MFID_ValueListItems = mvli.MFID ,
			DisplayID_ValueListItems = mvli.DisplayID,
            AppRef_ValueListItems = mvli.AppRef ,
			GUID_ValueListItems = mvli.ItemGUID,
			OwnerName_ValueListItems = mvli2.Name ,
			OwnerMFID_ValueListItems = mvli.OwnerID ,
            OwnerAppRef_ValueListItems = mvli2.AppRef ,
			Name_ValueList = mvl.Name ,
            MFID_ValueList = mvl.MFID ,
            ID_ValueList = mvl.ID ,
            OwnerMFID_ValueList = mvl.OwnerID,
			Deleted = mvli.Deleted,
			Process_ID = mvli.Process_ID
    FROM    [dbo].[MFValueListItems] AS [mvli]
            INNER JOIN [dbo].[MFValueList] AS [mvl] ON mvl.ID = mvli.[MFValueListID]
            LEFT OUTER JOIN ( [MFValueListItems] [mvli2]
                  LEFT OUTER JOIN MFValueList mvl2 ON mvl2.id = [mvli2].MFValueListId
                ) ON mvli.ownerid = mvli2.mfid
                     AND [mvl].[OwnerID] = [mvl2].[MFID]
    WHERE    mvl.Name = ''' + @ValueListName + '''';

            IF @Debug > 0
                SELECT @ProcedureStep AS [ProcedureStep],
                       @Query AS [QUERY];

            SELECT @ProcedureStep = 'EXECUTE DYNAMIC QUERY';

            --------------------------------
            --EXECUTE DYNAMIC QUERY
            --------------------------------
            EXECUTE (@Query);
            IF EXISTS (SELECT * FROM [sys].[views] WHERE [name] = @ViewName)
            BEGIN
                RETURN 1; --SUCESS
            END;
        END;
        ELSE
            DECLARE @DebugMessage NVARCHAR(100);
        SET @DebugMessage = 'Valuelist name: ' + @ValueListName + ' Does not exist or is a duplicate';
        RAISERROR(@DebugMessage, 16, 1);
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET NOCOUNT ON;

        IF @Debug > 0
            SELECT 'spMFCreateValueListLookupView',
                   ERROR_NUMBER(),
                   ERROR_MESSAGE(),
                   ERROR_PROCEDURE(),
                   ERROR_STATE(),
                   ERROR_SEVERITY(),
                   ERROR_LINE(),
                   @ProcedureStep;

        --------------------------------------------------
        -- INSERTING ERROR DETAILS INTO LOG TABLE
        --------------------------------------------------
        INSERT INTO [dbo].[MFLog]
        (
            [SPName],
            [ErrorNumber],
            [ErrorMessage],
            [ErrorProcedure],
            [ErrorState],
            [ErrorSeverity],
            [ErrorLine],
            [ProcedureStep]
        )
        VALUES
        ('spMFCreateLookupView', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), ERROR_STATE(), ERROR_SEVERITY(),
         ERROR_LINE(), @ProcedureStep);

        RETURN 2; --FAILURE
    END CATCH;
END;
GO
