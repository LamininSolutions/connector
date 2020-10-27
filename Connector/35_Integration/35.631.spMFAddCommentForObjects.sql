
GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFAddCommentForObjects]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
                                 @ObjectName = N'spMFAddCommentForObjects',
                                 -- nvarchar(100)
                                 @Object_Release = '4.8.22.62',
                                 -- varchar(50)
                                 @UpdateFlag = 2;
-- smallint
GO

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFAddCommentForObjects' --name of procedure
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
CREATE PROCEDURE dbo.spMFAddCommentForObjects
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO


ALTER PROCEDURE dbo.spMFAddCommentForObjects
    @MFTableName NVARCHAR(250),
    @Process_id INT = 5,
    @Comment NVARCHAR(1000),
    @Debug SMALLINT = 0
AS
/*rST**************************************************************************

========================
spMFAddCommentForObjects
========================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @MFTableName nvarchar(250)
    - Valid Class TableName as a string
    - Pass the class table name, e.g.: 'MFCustomer'
  @Process\_id int
    process id of the object(s) to add the comment to
  @Comment nvarchar(1000)
    the text of the bulk comment
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Add the same comment to a number of objects in the same class

Additional Info
===============

Set the process_ID for the selected objects before executing the procedure.
Use spGetHistory procedure to access the history of comments of an object in SQL

This procedure will get the latest version of the specified objects, then apply the bulk comment and then update the objects into M-Files.

Warnings
========

Adding bulk comments is a separate process from making a change to the objects. The two processes must run one after the other rather than simultaneously
The same comment will be applied to all the selected objects.

Adding object specific comments can be processed as part of the normal object updating process.

Examples
========

.. code:: sql

    UPDATE [dbo].[MFCustomer]
    SET process_id = 5
    WHERE id IN (1,3,6,9)

    DECLARE @Comment NVARCHAR(100)

    SET @Comment = 'Added a comment for illustration '

    EXEC [dbo].[spMFAddCommentForObjects]
        @MFTableName = 'MFCustomer',
        @Process_id = 5,
        @Comment = @Comment ,
        @Debug = 0

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2020-08-22  LC         change of deleted column definition
2019-11-23  LC         Redesign procedure
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/


SET NOCOUNT ON;


BEGIN TRY
    DECLARE @Update_ID INT,
            @ProcessBatch_ID INT,
            @return_value INT = 1;


    DECLARE @Id INT,
            @objID INT,
            @ObjectIdRef INT,
            @ObjVersion INT,
            @VaultSettings NVARCHAR(4000),
            @TableName NVARCHAR(1000),
            @XmlOUT NVARCHAR(MAX),
            @NewObjectXml NVARCHAR(MAX),
            @ObjIDsForUpdate NVARCHAR(MAX),
            @FullXml XML,
            @SynchErrorObj NVARCHAR(MAX),  --Declared new paramater
            @DeletedObjects NVARCHAR(MAX), --Declared new paramater
            @ProcedureName sysname = 'spmfAddCommentForObjects',
            @ProcedureStep sysname = 'Start',
            @ObjectId INT,
            @ClassId INT,
            @ErrorInfo NVARCHAR(MAX),
            @Query NVARCHAR(MAX),
            @Params NVARCHAR(MAX),
            @SynchErrCount INT,
            @ErrorInfoCount INT,
            @MFErrorUpdateQuery NVARCHAR(1500),
            @MFIDs NVARCHAR(2500) = N'',
            @ExternalID NVARCHAR(120);

    -----------------------------------------------------
    --DECLARE VARIABLES FOR LOGGING
    -----------------------------------------------------
    DECLARE @DefaultDebugText AS NVARCHAR(256) = N'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = N'';
    DECLARE @LogTextDetail AS NVARCHAR(MAX) = N'';
    DECLARE @LogTextAccumulated AS NVARCHAR(MAX) = N'';
    DECLARE @LogStatusDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogTypeDetail AS NVARCHAR(50) = NULL;
    DECLARE @LogColumnName AS NVARCHAR(128) = NULL;
    DECLARE @LogColumnValue AS NVARCHAR(256) = NULL;
    DECLARE @ProcessType NVARCHAR(50);
    DECLARE @LogType AS NVARCHAR(50) = N'Status';
    DECLARE @LogText AS NVARCHAR(4000) = N'';
    DECLARE @LogStatus AS NVARCHAR(50) = N'Started';
    DECLARE @Status AS NVARCHAR(128) = NULL;
    DECLARE @Validation_ID INT = NULL;
    DECLARE @StartTime AS DATETIME;
    DECLARE @RunTime AS DECIMAL(18, 4) = 0;


    IF EXISTS
    (
        SELECT *
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'[dbo].[' + @MFTableName + ']')
              AND type IN ( N'U' )
    )
    BEGIN
        -----------------------------------------------------
        --GET LOGIN CREDENTIALS
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Security Variables';

        DECLARE @Username NVARCHAR(2000);
        DECLARE @VaultName NVARCHAR(2000);

        SELECT TOP 1
               @Username = Username,
               @VaultName = VaultName
        FROM dbo.MFVaultSettings;

        SELECT @VaultSettings = dbo.FnMFVaultSettings();

        IF @Debug > 9
        BEGIN
            RAISERROR('Proc: %s Step: %s Vault: %s', 10, 1, @ProcedureName, @ProcedureStep, @VaultName);

            SELECT @VaultSettings;
        END;

        SET @StartTime = GETUTCDATE();
        /*
	Create ids for process start
	*/
        SET @ProcedureStep = 'Get Update_ID';

        SELECT @ProcessType = N'Update Comments';

        INSERT INTO dbo.MFUpdateHistory
        (
            Username,
            VaultName,
            UpdateMethod
        )
        VALUES
        (@Username, @VaultName, -1);

        SELECT @Update_ID = @@IDENTITY;




        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + N'ProcessBatch_ID %i: Update_ID %i';
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ProcessBatch_ID, @Update_ID);
        END;

        SET @ProcedureStep = 'Start ProcessBatch';
        SET @StartTime = GETUTCDATE();
        SET @ProcessType = @ProcedureName;
        SET @LogType = N'Status';
        SET @LogStatus = N'Started';
        SET @LogText = N'Update using Update_ID: ' + CAST(@Update_ID AS VARCHAR(10));

        EXECUTE @return_value = dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
                                                            @ProcessType = @ProcessType,
                                                            @LogType = @LogType,
                                                            @LogText = @LogText,
                                                            @LogStatus = @LogStatus,
                                                            @debug = @Debug;

        -----------------------------------------------------
        --Set Object Type Id
        -----------------------------------------------------
        SET @ProcedureStep = 'Get Object Type and Class';

        SELECT @ObjectIdRef = MFObjectType_ID
        FROM dbo.MFClass
        WHERE TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

        SELECT @ObjectId = MFID
        FROM dbo.MFObjectType
        WHERE ID = @ObjectIdRef;

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + N'ObjectType: %i';
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ObjectId);
        END;

        -----------------------------------------------------
        --Set class id
        -----------------------------------------------------
        SELECT @ClassId = MFID
        FROM dbo.MFClass
        WHERE TableName = @MFTableName; --SUBSTRING(@TableName, 3, LEN(@TableName))

        -------------------------------------------------------------
        -- Get deleted property name
        -------------------------------------------------------------
        DECLARE @DeletedColumn NVARCHAR(100)
        SELECT @DeletedColumn = ColumnName FROM MFProperty WHERE MFID = 27

        IF @Debug > 9
        BEGIN
            SET @DebugText = @DefaultDebugText + N'Class: %i';
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep, @ClassId);
        END;

        SET @ProcedureStep = 'Prepare Table';
        SET @LogTypeDetail = N'Status';
        SET @LogStatusDetail = N'Start';
        SET @LogTextDetail = N'Update comments';
        SET @LogColumnName = N'';
        SET @LogColumnValue = N'';

        EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                  @LogType = @LogTypeDetail,
                                                                  @LogText = @LogTextDetail,
                                                                  @LogStatus = @LogStatusDetail,
                                                                  @StartTime = @StartTime,
                                                                  @MFTableName = @MFTableName,
                                                                  @Validation_ID = @Validation_ID,
                                                                  @ColumnName = @LogColumnName,
                                                                  @ColumnValue = @LogColumnValue,
                                                                  @Update_ID = @Update_ID,
                                                                  @LogProcedureName = @ProcedureName,
                                                                  @LogProcedureStep = @ProcedureStep,
                                                                  @debug = @Debug;



        -------------------------------------------------------------
        -- process process_id
        -------------------------------------------------------------


        DECLARE @Count NVARCHAR(10),
                @SelectQuery NVARCHAR(MAX),
                @ParmDefinition NVARCHAR(500);
        IF
        (
            SELECT OBJECT_ID('tempdb..#ObjidsForComment')
        ) IS NOT NULL
            DROP TABLE #ObjidsForComment;

        CREATE TABLE #ObjidsForComment
        (
            objid INT
        );

        SET @SelectQuery
            = N'Insert into #ObjidsForComment (Objid) Select t.Objid FROM ' + QUOTENAME(@MFTableName)
              + N' as t WHERE Process_ID = ' + CAST(@Process_id AS NVARCHAR(20)) + N' AND '+QUOTENAME(@DeletedColumn)+' is null';



        EXEC sys.sp_executesql @SelectQuery;

        SELECT @Count = COUNT(*)
        FROM #ObjidsForComment AS ofc;

        SET @DebugText = N'Updating comment ' + @Comment + N' on ' + CAST(@Count AS NVARCHAR(10)) + N' Object';
        SET @DefaultDebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = 'Processing process_id';

        IF @Debug > 0
        BEGIN
            RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;



        IF @Count > 0
        BEGIN
    

            -------------------------------------------------------------
            -- process all comments where process_id is set with spmfUpdateTable
            -------------------------------------------------------------
            SET @DebugText = N'';
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Update objects from MF';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            SET @Query = N'UPDATE t
					SET t.process_id = 0
					FROM ' + QUOTENAME(@MFTableName) + N' t WHERE t.process_ID = ' + CAST(@Process_id AS NVARCHAR(20));

            EXEC sys.sp_executesql @stmt = @Query;

            DECLARE @Objids AS NVARCHAR(4000);

            SELECT @Objids = STUFF(
                             (
                                 SELECT ',' + CAST(ofc.objid AS NVARCHAR(10))
                                 FROM #ObjidsForComment AS ofc
                                 FOR XML PATH('')
                             ),
                             1,
                             1,
                             ''
                                  );

            DECLARE @Update_IDOut INT;

            IF @Debug > 0
                SELECT 'Objids',
                       ofc.objid
                FROM #ObjidsForComment AS ofc;

            EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,                -- nvarchar(200)
                                     @UpdateMethod = 1,                          -- int
                                     @ObjIDs = @Objids,                          -- nvarchar(max)
                                     @Update_IDOut = @Update_IDOut OUTPUT,       -- int
                                     @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
                                     @Debug = 0;                                 -- smallint

-------------------------------------------------------------
-- reset comments
-------------------------------------------------------------
        DECLARE @PropName NVARCHAR(100);
            SELECT @PropName = mp.ColumnName
            FROM dbo.MFProperty AS mp
            WHERE mp.MFID = 33;

            SET @DebugText = N'';
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Process Comment';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;


            SET @Params = N'@Comment nvarchar(4000)';
            SET @Query = N'UPDATE t
					SET t.' + @PropName + N' = @Comment, t.process_id = 1
					FROM ' + QUOTENAME(@MFTableName) +
					                  + N' t
					inner join #ObjidsForComment o
					on t.objid = o.objid
					;';

					
            EXEC sys.sp_executesql @stmt = @Query, @Params = @Params, @comment = @Comment

            SET @DebugText = N'';
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Update from SQL';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;


            EXEC dbo.spMFUpdateTable @MFTableName = @MFTableName,                -- nvarchar(200)
                                     @UpdateMethod = 0,                          -- int
                                     @Update_IDOut = @Update_IDOut OUTPUT,       -- int
                                     @ProcessBatch_ID = @ProcessBatch_ID OUTPUT, -- int
                                     @Debug = 0;                                 -- smallint

            -------------------------------------------------------------
            -- END
            -------------------------------------------------------------         
            UPDATE dbo.MFUpdateHistory
            SET UpdateStatus = 'completed'
            WHERE Id = @Update_ID;

            SET @DebugText = N'';
            SET @DefaultDebugText = @DefaultDebugText + @DebugText;
            SET @ProcedureStep = 'Completed';

            IF @Debug > 0
            BEGIN
                RAISERROR(@DefaultDebugText, 10, 1, @ProcedureName, @ProcedureStep);
            END;

            EXEC dbo.spMFProcessBatch_Upsert @ProcessBatch_ID = @ProcessBatch_ID,
                                                              -- int
                                             @LogType = @LogType,
                                                              -- nvarchar(50)
                                             @LogText = @LogText,
                                                              -- nvarchar(4000)
                                             @LogStatus = @LogStatus,
                                                              -- nvarchar(50)
                                             @debug = @Debug; -- tinyint

            SET @LogTypeDetail = @LogType;
            SET @LogTextDetail = @LogText;
            SET @LogStatusDetail = @LogStatus;
            SET @Validation_ID = NULL;
            SET @LogColumnName = NULL;
            SET @LogColumnValue = NULL;

            EXECUTE @return_value = dbo.spMFProcessBatchDetail_Insert @ProcessBatch_ID = @ProcessBatch_ID,
                                                                      @LogType = @LogTypeDetail,
                                                                      @LogText = @LogTextDetail,
                                                                      @LogStatus = @LogStatusDetail,
                                                                      @StartTime = @StartTime,
                                                                      @MFTableName = @MFTableName,
                                                                      @Validation_ID = @Validation_ID,
                                                                      @ColumnName = @LogColumnName,
                                                                      @ColumnValue = @LogColumnValue,
                                                                      @Update_ID = @Update_ID,
                                                                      @LogProcedureName = @ProcedureName,
                                                                      @LogProcedureStep = @ProcedureStep,
                                                                      @debug = @Debug;

        END; --if count > 0

        RETURN 1; --For More information refer Process Table
    END; --If table exists

END TRY
BEGIN CATCH
    IF @@TRANCOUNT <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    SET NOCOUNT ON;

    UPDATE dbo.MFUpdateHistory
    SET UpdateStatus = 'failed'
    WHERE Id = @Update_ID;

    INSERT INTO dbo.MFLog
    (
        SPName,
        ErrorNumber,
        ErrorMessage,
        ErrorProcedure,
        ProcedureStep,
        ErrorState,
        ErrorSeverity,
        Update_ID,
        ErrorLine
    )
    VALUES
    ('spMFUpdateTable', ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_PROCEDURE(), @ProcedureStep, ERROR_STATE(),
     ERROR_SEVERITY(), @Update_ID, ERROR_LINE());

    IF @Debug > 9
    BEGIN
        SELECT ERROR_NUMBER() AS ErrorNumber,
               ERROR_MESSAGE() AS ErrorMessage,
               ERROR_PROCEDURE() AS ErrorProcedure,
               @ProcedureStep AS ProcedureStep,
               ERROR_STATE() AS ErrorState,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_LINE() AS ErrorLine;
    END;

    SET NOCOUNT OFF;

    RETURN -1; --For More information refer Process Table
END CATCH;

GO





