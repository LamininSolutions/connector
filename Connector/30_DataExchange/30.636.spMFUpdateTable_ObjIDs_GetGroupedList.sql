PRINT SPACE(5) + QUOTENAME(@@ServerName) + '.' + QUOTENAME(DB_NAME())
      + '.[dbo].[spMFUpdateTable_ObjIds_GetGroupedList]';

EXEC setup.spMFSQLObjectsControl @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTable_ObjIds_GetGroupedList', -- nvarchar(100)
    @Object_Release = '4.9.27.69',                          -- varchar(50)
    @UpdateFlag = 2;

-- smallint
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_NAME = 'spMFUpdateTable_ObjIds_GetGroupedList' --name of procedure
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
CREATE PROCEDURE dbo.spMFUpdateTable_ObjIds_GetGroupedList
AS
SELECT 'created, but not implemented yet.';
--just anything will do
GO

-- the following section will be always executed
SET NOEXEC OFF;
GO

IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL
    DROP TABLE #ObjIdList;

CREATE TABLE #ObjIdList
(
    ObjId INT,
    Flag INT
);
GO

ALTER PROCEDURE dbo.spMFUpdateTable_ObjIds_GetGroupedList
(
    @ObjIds_FieldLenth SMALLINT = 3900,
    @Debug SMALLINT = 0
)
AS
/*rST**************************************************************************

=====================================
spMFUpdateTable_ObjIDs_GetGroupedList
=====================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ObjIds\_FieldLenth smallint
    Indicate the size of each group iteration CSV text field
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

The purpose of this procedure is to group source records into batches and compile a list of OBJIDs in CSV format to pass to spMFUpdateTable

Examples
========

.. code:: sql

    IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL DROP TABLE #ObjIdList;
    CREATE TABLE #ObjIdList ( [ObjId] INT  PRIMARY KEY )

    INSERT #ObjIdList ( ObjId )
    SELECT ObjID
    FROM MFYourTable

    EXEC spMFUpdateTable_ObjIDS_GetGroupedList

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2021-05-10  LC         prevent group list process when objid count < 500
2021-03-10  LC         set default field length to 3900
2020-12-11  LC         fix bug related to number of objids in list
2020-09-08  Lc         resolve number of objids in batch
2020-04-08  LC         Resolve issue with #objidlist not exist 
2019-08-30  JC         Added documentation
2017-06-08  AC         Change default size of @ObjIds_FieldLenth 
==========  =========  ========================================================

**rST*************************************************************************/
BEGIN
    SET NOCOUNT ON;

    SET XACT_ABORT ON;

    -----------------------------------------------------
    --DECLARE LOCAL VARIABLE
    -----------------------------------------------------
    DECLARE @return_value INT     = 1,
        @rowcount         INT     = 0,
        @ProcedureName    sysname = 'spMFUpdateTable_ObjIds_GetGroupList',
        @ProcedureStep    sysname = 'Start',
        @sqlQuery         NVARCHAR(MAX),
        @sqlParam         NVARCHAR(MAX);

    -----------------------------------------------------
    --Calculate Number of Groups in RecordSet
    -----------------------------------------------------
    SET @ProcedureStep = 'Create #objidlist table';

    IF OBJECT_ID('tempdb..#ObjIdList') IS NULL
    BEGIN
        CREATE TABLE #ObjIdList
        (
            ObjId INT,
            Flag INT
        );

        IF @Debug > 0
            RAISERROR('Proc: %s Step: %s: ', 10, 1, @ProcedureName, @ProcedureStep);
    END;

    --Begin
    IF
    (
        SELECT OBJECT_ID('tempdb..##GroupHdr')
    ) IS NOT NULL
        DROP TABLE ##GroupHdr;

    SET @ProcedureStep = 'Create #GroupHdr table';

    --IF (SELECT OBJECT_ID('tempdb..##GroupHdr')) IS  NULL
    CREATE TABLE #GroupHdr
    (
        GroupNumber INT,
        ObjIDs NVARCHAR(MAX)
    );

    IF @Debug > 0
        RAISERROR('Proc: %s Step: %s: ', 10, 1, @ProcedureName, @ProcedureStep);

    SET @ProcedureStep = 'Create #GroupDtl table';

    IF
    (
        SELECT OBJECT_ID('tempdb..##GroupDtl')
    ) IS NOT NULL
        DROP TABLE ##GroupDtl;

    --   IF (SELECT OBJECT_ID('tempdb..##GroupDtl')) IS NULL	
    CREATE TABLE #GroupDtl
    (
        ObjID INT,
        GroupNumber INT
    );

    IF @Debug > 0
        RAISERROR('Proc: %s Step: %s: ', 10, 1, @ProcedureName, @ProcedureStep);

    SET @ProcedureStep = 'Get Number of Groups ';

    DECLARE @NumberofGroups INT;

    --IF
    --(
    --    SELECT COUNT(ISNULL(ObjId, 0)) FROM #ObjIdList
    --) > 0
    --BEGIN
    --    SET @ProcedureStep = 'Get number of groups ';


        --SELECT @NumberofGroups =
        --(
        --    SELECT COUNT(ISNULL(ObjId, 0)) FROM #ObjIdList
        --) / (@ObjIds_FieldLenth --ObjIds fieldlenth
        --     /
        --(
        --    SELECT MAX(LEN(ObjId)) + 2 FROM #ObjIdList
        --)   --avg size of each item in csv list including comma
        --    ) + CASE
        --            WHEN
        --(
        --    SELECT COUNT(ISNULL(ObjId, 0)) FROM #ObjIdList
        --) % (@ObjIds_FieldLenth --ObjIds fieldlenth
        --     /
        --(
        --    SELECT MAX(LEN(ObjId)) + 2 FROM #ObjIdList
        --)
        --    ) > 0 THEN
        --                1
        --            ELSE
        --                0
        --        END;
        ----SELECT  @NumberofGroups = ( SELECT  COUNT(ISNULL(objid,0))
        ----                            FROM    #ObjIdList
        ----                          ) / 500
        --;

    --    SET @NumberofGroups = ISNULL(NULLIF(@NumberofGroups, 0), 1);

    --    IF @Debug > 0
    --        SELECT @NumberofGroups AS 'number OF groups';
    --END;

    --IF @Debug > 0
    --BEGIN
    --    SELECT @NumberofGroups AS 'number of groups';

    --    RAISERROR('Proc: %s Step: %s: %d group(s)', 10, 1, @ProcedureName, @ProcedureStep, @NumberofGroups);
    --END;

    -----------------------------------------------------
    --Assign Group Numbers to Source Records
    -----------------------------------------------------
    SET @ProcedureStep = 'Assign Group Numbers to Source Records ';

    --INSERT #GroupDtl
    --(
    --    ObjID,
    --    GroupNumber
    --)
    --SELECT ObjId,
    --    NTILE(@NumberofGroups) OVER (ORDER BY ObjId) AS GroupNumber
    --FROM #ObjIdList;


    --SET @rowcount = @@RowCount;

    --IF @Debug > 0
    --BEGIN
    --    SELECT COUNT(*) AS ObjCount
    --    FROM #ObjIdList;

    --    RAISERROR('Proc: %s Step: %s: %d record(s)', 10, 1, @ProcedureName, @ProcedureStep, @rowcount);
    --END;

    -----------------------------------------------------
    --Get ObjIDs CSV List by GroupNumber
    -----------------------------------------------------
    SET @ProcedureStep = 'Get ObjIDs CSV List by GroupNumber ';

    --INSERT INTO #GroupHdr
    --(
    --    GroupNumber,
    --    ObjIDs
    --)
    SELECT source.GroupNumber,
        ObjIDs = STUFF(
                 (
                     SELECT ',',
                         CAST(ObjID AS VARCHAR(10))
                     FROM #GroupDtl
                     WHERE GroupNumber = source.GroupNumber
                     FOR XML PATH('')
                 ),
                          1,
                          1,
                          ''
                      )
    FROM
    (SELECT GroupNumber FROM #GroupDtl GROUP BY GroupNumber) source;

    SET @rowcount = @@RowCount;

    IF @Debug > 0
        RAISERROR('Proc: %s Step: %s: %d record(s)', 10, 1, @ProcedureName, @ProcedureStep, @rowcount);

    --END

    -----------------------------------------------------
    --Return GroupedList
    -----------------------------------------------------	
    SELECT GroupNumber,
        ObjIDs
    FROM #GroupHdr
    ORDER BY GroupNumber;
END;
GO