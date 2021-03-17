PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFObjectTypeUpdateClassIndex]';
GO

SET NOCOUNT ON;

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFObjectTypeUpdateClassIndex', -- nvarchar(100)
    @Object_Release = '4.8.22.62',                   -- varchar(50)
    @UpdateFlag = 2;                                 -- smallint
GO

/*rST**************************************************************************

==============================
spMFObjectTypeUpdateClassIndex
==============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @IsAllTables 
    - Default 0
    - When set to 1 it will get the object versions for all class tables
  @Debug (optional)
    - Default = 0
    - 1 = Standard Debug Mode

Purpose
=======

This procedure will update the table MFObjectTypeToClassObject with the latest version of all objects in the class.

The table is useful to get a total of objects by class and also to identify the class from the objid where multiple classes is related to an object type.

Prerequisites
=============

When parameter @IsAllTables is set to 0 then it will only perform the operation on the class tables with the column IncludeInApp not null.

Examples
========

.. code:: sql

    EXEC [spMFObjectTypeUpdateClassIndex]  @IsAllTables = 1,  @Debug = 0  

    SELECT * FROM dbo.MFvwObjectTypeSummary AS mfots

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2016-04-24  LC         Created
2017-11-23  lc         localization of MF-LastModified and MFLastModified by
2018-12-15  lc         bug with last modified date; add option to set objecttype
2018-13-21  LC         add feature to get reference of all objects in Vault
2020-08-13  LC         update assemblies to set date formats to local culture
2020-08-22  LC         update to take account of new deleted column
2021-03-17  LC         Set updatestatus = 1 when not matched
==========  =========  ========================================================

**rST*************************************************************************/

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFObjectTypeUpdateClassIndex' --name of procedure
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
CREATE PROCEDURE dbo.spMFObjectTypeUpdateClassIndex
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROC dbo.spMFObjectTypeUpdateClassIndex
    @IsAllTables BIT = 0,
    @MFTableName NVARCHAR(200) = NULL,
    @Debug SMALLINT = 0
AS
SET NOCOUNT ON;

BEGIN
    DECLARE @result    INT,
        @ClassName     NVARCHAR(100),
        @TableName     NVARCHAR(100),
        @id            INT,
        @schema        NVARCHAR(5)  = N'dbo',
        @SQL           NVARCHAR(MAX),
        @ObjectType    VARCHAR(100),
        @ObjectTypeID  INT,
        @ProcessStep   sysname      = 'START',
        @ProcedureName sysname      = 'spMFObjectTypeUpdateClassIndex';

    --SELECT * FROM [dbo].[MFClass] AS [mc]
    --SELECT * FROM [dbo].[MFObjectType] AS [mot]
    IF @Debug > 0
    BEGIN
        RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcessStep);
    END;

        -------------------------------------------------------------
    -- VARIABLES: DEBUGGING
    -------------------------------------------------------------
    DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
    DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s';
    DECLARE @DebugText AS NVARCHAR(256) = '';
    DECLARE @Msg AS NVARCHAR(256) = '';
    DECLARE @MsgSeverityInfo AS TINYINT = 10;
    DECLARE @MsgSeverityObjectDoesNotExist AS TINYINT = 11;
    DECLARE @MsgSeverityGeneralError AS TINYINT = 16;
	
	
	-------------------------------------------------------------
    --	Set all tables to be included
    -------------------------------------------------------------
    IF @IsAllTables = 1
    BEGIN
        UPDATE dbo.MFClass
        SET IncludeInApp = 10
        WHERE IncludeInApp IS NULL;
    END;

    --Select * from mfclass
    -------------------------------------------------------------
    -- Get objvers
    -------------------------------------------------------------
    DECLARE @RowID INT;
    DECLARE @outPutXML NVARCHAR(MAX);
    DECLARE @Idoc INT;
    DECLARE @Class_ID INT;
    DECLARE @MFTableName_ID INT;
    DECLARE @LatestupdateDate DATETIME;
    DECLARE @Objvercount INT = NULL;
    DECLARE @MaxObjid INT;
    DECLARE @Iterations INT = 0;
    DECLARE @Days INT;

    SELECT @MFTableName_ID = MFID
    FROM dbo.MFClass
    WHERE TableName = @MFTableName;

    IF @Debug > 0
    SELECT @MFTableName, @MFTableName_ID;

    SELECT @RowID = CASE
                        WHEN @MFTableName IS NULL THEN
    (
        SELECT MIN(MFID) FROM dbo.MFClass WHERE IncludeInApp IS NOT NULL
    )
                        ELSE
                            @MFTableName_ID
                    END;

    IF @Debug > 0
        SELECT @RowID,
            @MFTableName_ID;

    WHILE @RowID IS NOT NULL
    BEGIN
        SET @MaxObjid = NULL;

        SELECT @id        = mc.ID,
            @Class_ID     = mc.MFID,
            @ClassName    = mc.Name,
            @TableName    = mc.TableName,
            @ObjectTypeID = mot.MFID
        FROM dbo.MFClass                mc
            INNER JOIN dbo.MFObjectType AS mot
                ON mc.MFObjectType_ID = mot.ID
        WHERE mc.MFID = @RowID
              AND mc.IncludeInApp IS NOT NULL;

        IF @Debug > 0
            SELECT @RowID,
                @TableName;



            EXEC dbo.spMFGetObjectvers @TableName = @TableName, -- nvarchar(100)
                @dtModifiedDate = '2000-01-01',            -- datetime
                @MFIDs = null,                                  -- nvarchar(4000)
                @outPutXML = @outPutXML OUTPUT;                 -- nvarchar(max)




            IF @Debug > 0
                SELECT @TableName           AS tablename,
                    @outPutXML  AS outPutXML;

            IF @outPutXML != '<form />'
  Begin
     

	        EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @outPutXML;

		Set @DebugText = ' for table ' + @MFTableName
		Set @DebugText = @DefaultDebugText + @DebugText
		Set @Procedurestep = ' Get ObjectVer'
		
		IF @debug > 0
			Begin
				RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep );
			END
	
    BEGIN tran
            MERGE INTO dbo.MFAuditHistory [t]
            USING
            (
                SELECT distinct xmlfile.objId
                      ,xmlfile.MFVersion
                      ,xmlfile.GUID
                      ,xmlfile.ObjectType_ID
                      ,xmlfile.Object_Deleted
                      ,xmlfile.CheckedOutTo
                      ,xmlfile.Object_LastModifiedUtc
                      ,xmlfile.LatestCheckedInVersion
                FROM
                    OPENXML(@Idoc, '/form/objVers', 1)
                    WITH
                    (
                        [objId] INT './@objectID'
                       ,[MFVersion] INT './@version'
                       ,[GUID] NVARCHAR(100) './@objectGUID'
                       ,[ObjectType_ID] INT './@objectType'
                       ,[Object_Deleted] NVARCHAR(10) './@Deleted'
                       ,CheckedOutTo INT './@CheckedOutTo'
                       ,[Object_LastModifiedUtc] NVARCHAR(30) './@LastModifiedUtc'
                       ,LatestCheckedInVersion INT './@LatestCheckedInVersion'
                    ) [xmlfile]
            ) [s]
            ON t.ObjectType = s.ObjectType_ID
               AND t.ObjID = s.objId
			   AND t.Class = @Class_ID
  --          WHEN NOT MATCHED  BY TARGET THEN
  WHEN NOT MATCHED THEN
                INSERT
                ( TranDate
                   , [ObjectType]
                   ,[Class]
                   ,[ObjID]
                   ,MFVersion
                   ,StatusFlag
                   ,StatusName
                   ,UpdateFlag
               
                )
                VALUES
                (GetUTCdate(), s.ObjectType_ID, @Class_ID, s.objId, s.LatestCheckedInVersion, 
                CASE WHEN s.Object_Deleted = 'true' THEN 4 
                WHEN s.CheckedOutTo > 0 THEN 3
                ELSE 1 END
                ,CASE WHEN s.Object_Deleted = 'true' THEN 'Deleted in MF'
                WHEN s.CheckedOutTo > 0 THEN 'Checked Out'
                ELSE 'Not matched' END
                ,CASE WHEN s.Object_Deleted = 'true' THEN 0 ELSE 1 end)
                 ;

                
				IF @idoc IS NOT null
				EXEC [sys].[sp_xml_removedocument] @Idoc;

				                     COMMIT TRAN
		
        END;

        SET @RowID = CASE
                         WHEN @MFTableName_ID IS NULL THEN
                         (
                             SELECT MIN(mc.MFID)
                             FROM dbo.MFClass mc
                             WHERE mc.MFID > @RowID
                                   AND mc.IncludeInApp IS NOT NULL
                         )
                         ELSE
                             NULL
                     END;
                     SET @Iterations = 0


    END;
END;

SET @ProcessStep = 'END';

IF @Debug > 0
BEGIN
    RAISERROR('%s : Step %s', 10, 1, @ProcedureName, @ProcessStep);
END;

-------------------------------------------------------------
--	ReSet all tables to be included
-------------------------------------------------------------
IF @IsAllTables = 1
    UPDATE dbo.MFClass
    SET IncludeInApp = NULL
    WHERE IncludeInApp = 10;
--SELECT  *
--    FROM    [dbo].[MFObjectTypeToClassObject] AS [mottco];
