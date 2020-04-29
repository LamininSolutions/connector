
PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSetUniqueIndexes]';
GO
SET NOCOUNT ON
EXEC [setup].[spMFSQLObjectsControl]
	@SchemaName = N'dbo'
  , @ObjectName = N'spMFSetUniqueIndexes' -- nvarchar(100)
  , @Object_Release = '4.6.16.57'
  , @UpdateFlag = 2

GO
/*------------------------------------------------------------------------------------------------
	Author: LSUSA\LeRouxC
----------------------------------------------------------------------------------------------*/

IF EXISTS (	  SELECT	1
			  FROM		[INFORMATION_SCHEMA].[ROUTINES]
			  WHERE		[ROUTINE_NAME] = 'spMFSetUniqueIndexes' --name of procedure
						AND [ROUTINE_TYPE] = 'PROCEDURE' --for a function --'FUNCTION'
						AND [ROUTINE_SCHEMA] = 'dbo'
		  )
	BEGIN
		PRINT SPACE(10) + '...Stored Procedure: update';
		SET NOEXEC ON;
	END;
ELSE PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSetUniqueIndexes]
AS
	SELECT	'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO
ALTER PROCEDURE [dbo].[spMFSetUniqueIndexes]
	(
	   @Debug			 SMALLINT = 0
	)
AS
/*rST**************************************************************************

====================
spMFSetUniqueIndexes
====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======
This procedure sets the unique indexes for all class tables. The use of indexes on the objid and external ID is optional.  When the setting CreateUniqueClassIndexes are set to 1 in the MFSettings table then the indexes will automatically be created when the procedure spMFCreateTable is run.  The default setting in the MFSettings table is to not create indexes.  This allows installations to approach the management of the indexes differently.

Examples
========

.. code:: sql

   Exec spMFSetUniqueIndexes

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-03-27  LC         Create Procedure
==========  =========  ========================================================

**rST*************************************************************************/


BEGIN
		SET NOCOUNT ON;


		-------------------------------------------------------------
		-- VARIABLES: T-SQL Processing
		-------------------------------------------------------------
		DECLARE @rowcount AS INT = 0;
		DECLARE @return_value AS INT = 0;
		DECLARE @error AS INT = 0;

		-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @ProcedureName AS NVARCHAR(128) = 'dbo.spMFSetUniqueIndexes';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

		-------------------------------------------------------------
		-- VARIABLES: DYNAMIC SQL
		-------------------------------------------------------------
		DECLARE @sql NVARCHAR(MAX) = N''
		DECLARE @sqlParam NVARCHAR(MAX) = N''


		BEGIN TRY
			-------------------------------------------------------------
			-- BEGIN PROCESS
			-------------------------------------------------------------
			SET @DebugText = ''
			Set @DefaultDebugText = @DefaultDebugText + @DebugText
			Set @Procedurestep = 'Set class indexes'
			
			IF @debug > 0
				Begin
					RAISERROR(@DefaultDebugText,10,1,@ProcedureName,@ProcedureStep );
				END
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

-------------------------------------------------------------
-- Class tables
-------------------------------------------------------------

--validate that class tables in database is set to included in app
UPDATE mc
SET mc.IncludeInApp = 1
FROM INFORMATION_SCHEMA.TABLES AS t
    INNER JOIN dbo.MFClass     mc
        ON t.TABLE_NAME = mc.TableName
WHERE mc.IncludeInApp IS NULL;

--loop through all class tables
DECLARE @Tables AS TABLE
(
    id INT,
    TableName sysname
);

DECLARE @ID INT;
DECLARE @TableName sysname;
DECLARE @ConstraintName sysname;

INSERT INTO @Tables
(
    id,
    TableName
)
SELECT mc.ID,
    mc.TableName
FROM INFORMATION_SCHEMA.TABLES AS t
    INNER JOIN dbo.MFClass     mc
        ON t.TABLE_NAME = mc.TableName
WHERE mc.IncludeInApp IS NOT NULL;

SELECT @ID = MIN(t.id)
FROM @Tables AS t;

WHILE @ID IS NOT NULL
BEGIN
    SELECT @TableName = t.TableName
    FROM @Tables AS t
    WHERE t.id = @ID;

    --add constraint on objid
    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints              AS dc
        INNER JOIN sys.objects                AS o
            ON dc.parent_object_id = o.object_id
        INNER JOIN INFORMATION_SCHEMA.COLUMNS AS c
            ON c.TABLE_NAME = o.name
               AND dc.parent_column_id = c.ORDINAL_POSITION
               AND c.TABLE_NAME = @TableName
               AND c.COLUMN_NAME = 'Objid';

    IF @ConstraintName IS NOT NULL
    BEGIN
        SET @SQL = N'
        SET QUOTED_IDENTIFIER ON;
ALTER TABLE '+QUOTENAME(@TableName)+'
DROP CONSTRAINT ' + @ConstraintName;

        EXEC (@SQL);
    END;

    SET @SQL
        = N'

       SET QUOTED_IDENTIFIER ON;

IF EXISTS(SELECT 1 FROM FROM sys.default_constraints AS dc WHERE name = ''DF_'+@TableName+'_ObjID''
ALTER TABLE ' + QUOTENAME(@TableName) + N'
DROP CONSTRAINT ''DF_'+@TableName+'_ObjID'';
ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD  CONSTRAINT [DF_' + @TableName
          + N'_ObjID]  DEFAULT (IDENT_CURRENT('''+@TableName+'''*(-1)) FOR [ObjID]';

    EXEC (@SQL);

    -------------------------------------------------------------
    -- Add indexes and foreign keys
    -------------------------------------------------------------
    SET @SQL
        = N'
                SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + N'_Objid'' AND object_id = OBJECT_ID(''dbo.' + @TableName
          + N'''))
CREATE UNIQUE NONCLUSTERED INDEX IX_' + @TableName + N'_Objid
ON dbo.' + @TableName + N'(Objid);';

    EXEC (@SQL);


                --select @SQL
                --           EXEC (@SQL);
                SET @SQL
                    = N'
                           SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name=''IX_' + @TableName + N'_ExternalID'' AND object_id = OBJECT_ID(''dbo.' + @TableName
                      + N'''))
CREATE UNIQUE NONCLUSTERED INDEX IX_' + @TableName + N'_ExternalID
ON dbo.' +      @TableName + N'(ExternalID)
WHERE ExternalID IS NOT NULL;';

                EXEC (@SQL);

SELECT @ConstraintName = null
    SELECT @ID =
    (
        SELECT MIN(t.id) FROM @Tables AS t WHERE t.id > @ID
    );
END;


			-------------------------------------------------------------
			--END PROCESS
			-------------------------------------------------------------
			END_RUN:
			SET @ProcedureStep = 'End'
			RETURN 1
		END TRY
		BEGIN CATCH

			--------------------------------------------------
			-- INSERTING ERROR DETAILS INTO LOG TABLE
			--------------------------------------------------
			INSERT INTO [dbo].[MFLog] ( [SPName]
									  , [ErrorNumber]
									  , [ErrorMessage]
									  , [ErrorProcedure]
									  , [ErrorState]
									  , [ErrorSeverity]
									  , [ErrorLine]
									  , [ProcedureStep]
									  )
			VALUES (
					   @ProcedureName
					 , ERROR_NUMBER()
					 , ERROR_MESSAGE()
					 , ERROR_PROCEDURE()
					 , ERROR_STATE()
					 , ERROR_SEVERITY()
					 , ERROR_LINE()
					 , @ProcedureStep
				   );

			SET @ProcedureStep = 'Catch Error'
			RETURN -1
		END CATCH

	END

GO

