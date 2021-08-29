
GO

PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFUpdateItemByItem]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateItemByItem', -- nvarchar(100)
    @Object_Release = '4.9.27.71',         -- varchar(50)
    @UpdateFlag = 2;                       -- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateItemByItem' --name of procedure
          AND ROUTINE_TYPE = 'PROCEDURE' --for a function --'FUNCTION'
          AND ROUTINE_SCHEMA = 'dbo'
)
BEGIN
    PRINT SPACE(10) + '...Stored Procedure: update';

    SET NOEXEC ON;
END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO

-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE dbo.spMFUpdateItemByItem
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE dbo.spMFUpdateItemByItem
    @MFTableName VARCHAR(100),
    @WithTableAudit SMALLINT = 0,
    @RetainDeletions bit = 0,
    @SingleItems BIT = 1, --1 = processed one by one
    @SessionIDOut INT = NULL OUTPUT,
    @Debug SMALLINT = 0
AS
/*rST**************************************************************************

====================
spMFUpdateItemByItem
====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName varchar(100)
    Name of table to be updated
  @WithTableAudit bit (optional) 
    Default = 0, if set to 1 then a table audit will be performed and only non processed items will be included
  @RetainDeletions bit (optional)
    - Default = 0; deletions removed by default, set to 1 to retain deletions in class table  
  @SingleItems bit (optional)
    - Default = 1; processed one-by-one, this is always the case   
  @SessionIDOut int (output)
    Output of the session id that was used to update the results in the MFAuditHistory Table
  @Debug smallint 
    Default = 0

Purpose
=======

This procedure is useful when forcing an update of objects from M-Files to SQL, even if the version have not changed.  This is particular handly when changes in M-Files has taken place that did not trigger a object version change such as changes to objects and valuelist labels and external repository changes.

This is also useful when there are data errors in M-Files and it is necessary to determine which specific records are not being able to be processed.

Additional Info
===============

Note that this procedure use updatemethod 1 by default.  It returns a session id.  this id can be used to inspect the result in the MFAuditHistory Table. Refer to Using Audit History for more information on this table

Examples
========

.. code:: sql

    DECLARE @RC INT
    DECLARE @MFTableName VARCHAR(100) = 'MFCustomer'
    Declare @WithTableAudit bit = 1
    DECLARE @Debug SMALLINT = 101
    DECLARE @SessionIDOut INT

    EXECUTE @RC = [dbo].[spMFUpdateItemByItem]
                        @MFTableName
                        ,@WithTableAudit
                       ,@Debug
                       ,@SessionIDOut OUTPUT

    SELECT @SessionIDOut

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-08-26  LC         fix return value to 1 for success
2021-08-26  LC         Add parameter for RetainDeletions
2021-03-27  LC         Change parameters
2021-03-27  LC         Add option to perform table audit
2021-03-09  LC         Update documentation
2020-08-28  LC         Set getobjver to date 2000-01-01
2020-08-22  LC         Update for new deleted column
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
SET NOCOUNT ON;

-------------------------------------------------------------
		-- VARIABLES: DEBUGGING
		-------------------------------------------------------------
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''
		DECLARE @Msg AS NVARCHAR(256) = ''
		DECLARE @MsgSeverityInfo AS TINYINT = 10
		DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11
		DECLARE @MsgSeverityGeneralError AS TINYINT = 16

BEGIN
    BEGIN TRY
        DECLARE @ClassName VARCHAR(100),
            @ProcedureStep VARCHAR(100) = 'Start',
            @ProcedureName VARCHAR(100) = 'spMFUpdateItemByItem',
            @Result        INT,
            @RunTime       DATETIME,
            --@Query NVARCHAR(MAX),
            @DeletedColumn NVARCHAR(100);

        -------------------------------------------------------------
        -- get deleted column name
        -------------------------------------------------------------
        SELECT @DeletedColumn = ColumnName
        FROM dbo.MFProperty
        WHERE MFID = 27;

        DECLARE @class_ID  INT,
            @objectType_ID INT;

        SELECT @ClassName  = mc.Name,
            @class_ID      = mc.MFID,
            @objectType_ID = mot.MFID
        FROM dbo.MFClass                mc
            INNER JOIN dbo.MFObjectType AS mot
                ON mc.MFObjectType_ID = mot.ID
        WHERE mc.TableName = @MFTableName;

        IF
        (
            SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @MFTableName
        ) = 0
        BEGIN
            EXEC dbo.spMFCreateTable @ClassName = @ClassName; -- nvarchar(128)

            SET @WithTableAudit = 1;
        END;

        DECLARE @NewXML   XML,
            @NewObjectXml VARCHAR(MAX);
        DECLARE @DeletedInSQL INT,
            @UpdateRequired   BIT,
            @OutofSync        INT,
            @ProcessErrors    INT,
            @ProcessBatch_ID  INT;

        IF @WithTableAudit = 1
        BEGIN
        SET @ProcedureStep = 'Perform table audit'
            EXEC dbo.spMFTableAudit @MFTableName = @MFTableName,
                @MFModifiedDate = '2000-01-01',
                @ObjIDs = NULL,
                @SessionIDOut = @SessionIDOut OUTPUT,
                @NewObjectXml = @NewObjectXml OUTPUT,
                @DeletedInSQL = @DeletedInSQL OUTPUT,
                @UpdateRequired = @UpdateRequired OUTPUT,
                @OutofSync = @OutofSync OUTPUT,
                @ProcessErrors = @ProcessErrors OUTPUT,
                @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                @Debug = 0;

                Set @DebugText = ''
                Set @DebugText = @DefaultDebugText + @DebugText
                
                IF @debug > 0
                	Begin
                		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
                	END
                
        END;

        IF @Debug > 0
            SELECT *
            FROM dbo.MFvwAuditSummary AS mfas
            WHERE mfas.TableName = @MFTableName;

        DECLARE @Objids  NVARCHAR(1000),
            @Objid       INT,
            @ReturnValue INT;

        SELECT @Objid = MIN(mah.ObjID)
        FROM dbo.MFAuditHistory AS mah
        WHERE mah.Class = @class_ID
              AND mah.ObjectType = @objectType_ID
              AND mah.StatusFlag <> 0;

  Set @DebugText = 'at %i'
            Set @DebugText = @DefaultDebugText + @DebugText
            Set @Procedurestep = 'update loop start '
            
            IF @debug > 0
            	Begin
            		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@objid );
            	END

        WHILE @Objid IS NOT NULL
        BEGIN --begin loop

            SELECT @Objids = CAST(@Objid AS NVARCHAR(1000));

            SET @ProcedureStep = 'Updating object ' + @Objids;


            EXEC @ReturnValue = dbo.spMFUpdateTable @MFTableName = @MFTableName, 
                @UpdateMethod = 1,                                                                                     
                @ObjIDs = @Objids, 
                @RetainDeletions = @RetainDeletions,
                @ProcessBatch_ID = @ProcessBatch_ID,
                @Debug = 0;


                Set @DebugText = ''
                Set @DebugText = @DefaultDebugText + @DebugText
                
                IF @debug > 0
                	Begin
                		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
                	END
                
            IF @ReturnValue <> 1
            BEGIN

Set @DebugText = ''
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Error '

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
	END


                INSERT INTO dbo.MFLog
                (
                    SPName,
                    ProcedureStep,
                    ErrorNumber,
                    ErrorMessage,
                    ErrorProcedure,
                    ErrorState,
                    ErrorSeverity,
                    ErrorLine
                )
                VALUES
                (@ProcedureName, @ProcedureStep, ERROR_NUMBER(), 'Failed to process object: ' + @Objids, @MFTableName,
                    ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE());
            END;

            SELECT @Objid =
            (
                SELECT MIN(mah.ObjID)
                FROM dbo.MFAuditHistory AS mah
                WHERE mah.Class = @class_ID
                      AND mah.ObjectType = @objectType_ID
                      AND mah.StatusFlag <> 0
                      AND mah.ObjID > @Objid
            );
        END;

        RETURN 1
        SET NOCOUNT OFF;
    END TRY
    BEGIN CATCH
        IF @@TranCount <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        SET NOCOUNT ON;

        IF @Debug > 0
        BEGIN
            SELECT ERROR_NUMBER() AS ErrorNumber,
                ERROR_MESSAGE()   AS ErrorMessage,
                ERROR_PROCEDURE() AS ErrorProcedure,
                @ProcedureStep    AS ProcedureStep,
                ERROR_STATE()     AS ErrorState,
                ERROR_SEVERITY()  AS ErrorSeverity,
                ERROR_LINE()      AS ErrorLine;
        END;

        SET NOCOUNT OFF;

        RETURN -1; --For More information refer Process Table
    END CATCH;
END;
GO