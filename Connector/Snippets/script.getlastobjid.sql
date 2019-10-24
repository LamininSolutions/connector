

/*

*/
--Created on: 2019-07-10 

DECLARE @Maxobjid INT
,@MFTableName  NVARCHAR(100) = 'MFLarge_Volume'
,@FromObjid INT = 1
,@ToObjid INT = 600000
,@upperRange INT
,@LowerRange INT
,@Test1 INT
,@Test2 int
,@Random INT
,@MFIDs NVARCHAR(4000)
,@IDoc INT
,@rcount INT
,@Cycles INT = 1
,@Interval INT = 10000

DECLARE @ValidatedIds AS TABLE  (id INT, matchedItems bit )

DECLARE @TestIds AS TABLE (id INT )

INSERT INTO @TestIds
(
    [id]
)
VALUES
(@FromObjid
    ),(@ToObjid)

SET @Random = @ToObjid

WHILE  ISNULL(@LowerRange,0)  = ISNULL(@upperRange,0) AND @Cycles < 10

BEGIN

SELECT @LowerRange = MIN(id) FROM @ValidatedIds AS [vi] WHERE [vi].[matchedItems] = 1
SELECT @upperRange = Max(id) FROM @ValidatedIds AS [vi] WHERE [vi].[matchedItems] = 1 

SELECT @Interval = CASE WHEN ISNULL(@LowerRange,0)  = ISNULL(@upperRange,0) THEN 10000
ELSE  1000 END

SELECT @LowerRange = CASE WHEN ISNULL(@LowerRange,0)  < ISNULL(@upperRange,0)  THEN @upperRange
ELSE  @LowerRange END

SELECT @LowerRange AS lowerRange, @UpperRange AS UpperRange, @Cycles AS Cycle, @Interval AS Interval

SELECT @MFIDs =  STUFF((SELECT DISTINCT ',' + CAST(ti.id AS NVARCHAR(10)) FROM @TestIds AS [ti]
FOR XML PATH ('')),1,1,'') 

--SELECT @MFIDs

DECLARE @outPutXML       NVARCHAR(MAX)
       ,@ProcessBatch_ID INT;

EXEC [dbo].[spMFGetObjectvers] @TableName = @MFTableName      -- nvarchar(100)
                              ,@dtModifiedDate = null -- datetime
                              ,@MFIDs =   @MFIDs       -- nvarchar(4000)
                              ,@outPutXML = @outPutXML OUTPUT                          -- nvarchar(max)
                              ,@ProcessBatch_ID = @ProcessBatch_ID OUTPUT              -- int
                              ,@Debug = 0        -- smallint

	--						  SELECT @outPutXML AS outputXML

   EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @outPutXML;


   INSERT INTO @ValidatedIds
   (
       [id]
      ,[matchedItems]
   )
   SELECT id,0 FROM @TestIds AS [ti]
;
    
   ; 
	  WITH [cte]
    AS (SELECT [xmlfile].[objId]
              ,[xmlfile].[MFVersion]
              ,[xmlfile].[GUID]
              ,[xmlfile].[ObjectType_ID]
			  ,1 AS matchedItems
        FROM
            OPENXML(@Idoc, '/form/objVers', 1)
            WITH
            (
                [objId] INT './@objectID'
               ,[MFVersion] INT './@version'
               ,[GUID] NVARCHAR(100) './@objectGUID'
               ,[ObjectType_ID] INT './@objectType'
            ) [xmlfile])
					 Merge INTO @ValidatedIds t
					 USING cte s
					ON s.[objId] = t.id
					WHEN MATCHED THEN 
					UPDATE SET 
					matchedItems = s.[matchedItems]
					WHEN NOT MATCHED THEN 
					INSERT 
					(id,[matchedItems])
					VALUES
                   ( s.[objId],s.[matchedItems])

;

--SELECT * FROM @TestIds AS [ti]
--SELECT * FROM @ValidatedIds AS [vi]


			
  SELECT @rcount = COUNT(*) FROM @ValidatedIds AS [ti]
  INNER JOIN @TestIds AS [ti2]
  ON [ti2].[id] = ti.[id]
     WHERE [ti].[matchedItems] = 1
  
  EXEC [sys].[sp_xml_removedocument] @Idoc;

  SELECT @Test1 = MIN(vi.id) FROM @ValidatedIds AS [vi] INNER JOIN @TestIds AS [ti] ON [ti].[id] = [vi].[id] WHERE [vi].[matchedItems] = 0
  
  SELECT @Test2 = MAX(vi.id) FROM @ValidatedIds AS [vi] INNER JOIN @TestIds AS [ti] ON [ti].[id] = [vi].[id] WHERE [vi].[matchedItems] = 1

  IF ISNULL(@Test1,0)=0
  SET @Random = @Test2 + 10000;

  				   
DELETE FROM @TestIds

INSERT INTO @TestIds
(
    [id]
)
VALUES

( CASE WHEN @Random - @Interval < 0 THEN 0 ELSE @Random - @Interval END),
(CASE WHEN @Random - @Interval < 0 THEN 0 ELSE @Random - @Interval END),
(@Random),
( @Random + @Interval),
( @Random + @Interval)

SELECT @Random =  min(id) FROM @TestIds AS [ti]



    Set @Cycles = @Cycles + 1

  END



/*

Get largest objid

*/
--Created on: 2019-07-10 

    DECLARE @DebugText NVARCHAR(100);
    DECLARE @DefaultDebugText NVARCHAR(100);
    DECLARE @Procedurestep NVARCHAR(100);
    DECLARE @ProcedureName NVARCHAR(100) = 'dbo.spMFUpdateTableinBatches';


    --other parameters 
    DECLARE @StartRow        INT
           ,@MaxRow          INT
           ,@RecCount        INT
           ,@BatchCount      INT           = 1
           ,@BatchesToRun    INT
           ,@ObjIdCount      INT
           ,@ProcessBatch_ID INT
           ,@UpdateID        INT
           ,@SQL             NVARCHAR(MAX)
           ,@Params          NVARCHAR(MAX)
           ,@StartTime       DATETIME
           ,@ProcessingTime  INT
           ,@objids          NVARCHAR(4000)
           ,@Message         NVARCHAR(100)
           ,@Update_IDOut    INT
           ,@Session_ID      INT
		   ,@Idoc int
		   ,@Class_ID INT
		   ,@FromObjid INT = 560000
		   ,@toObjid INT = 560001
		   ,@Debug INT = 1
		  , @WithStats int = 1
DECLARE @TableName NVARCHAR(100) = 'MFLarge_Volume'

       DECLARE @TableAuditList AS TABLE
        (
            [Objid] INT
        );

        IF
        (
            SELECT COUNT(*)
            FROM [dbo].[MFAuditHistory] AS [mah]
            WHERE [mah].[Class] = @Class_ID
        ) = 0
        BEGIN
            IF
            (
                SELECT OBJECT_ID('tempdb..#Objids')
            ) IS NOT NULL
                DROP TABLE [#Objids];

            SELECT TOP (2000000)
                   [n] = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY [s1].[object_id]))
            INTO [#Objids]
            FROM [sys].[all_objects]           AS [s1]
                CROSS JOIN [sys].[all_objects] AS [s2]
            OPTION (MAXDOP 1);

            CREATE UNIQUE CLUSTERED INDEX [n]
            ON [#Objids] ([n])
            -- WITH (DATA_COMPRESSION = PAGE)
            ;

            INSERT INTO @TableAuditList
            (
                [Objid]
            )
            SELECT [o].[n]
            FROM [#Objids] AS [o]
            WHERE [o].[n]
            BETWEEN @FromObjid AND @ToObjid;
        END;
        ELSE
        BEGIN
            INSERT INTO @TableAuditList
            (
                [Objid]
            )
            SELECT [mah].[ObjID]
            FROM [dbo].[MFAuditHistory] AS [mah]
            WHERE [mah].[StatusFlag] IN ( 1, 5 )
                  AND [mah].[Class] = @Class_ID;
        END;

        SELECT @RecCount = COUNT(*)
        FROM @TableAuditList AS [tal];

        SET @DebugText = ' Objid count %i';
        SET @DebugText = @DefaultDebugText + @DebugText;

        IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @Procedurestep, @RecCount);
        END;

        SELECT @StartRow = MIN([tal].[Objid])
              ,@MaxRow   = MAX([tal].[Objid])
        FROM @TableAuditList AS [tal];

        IF @Debug > 0
            SELECT @StartRow AS [startrow]
                  ,@MaxRow   AS [MaxRow];

        IF @StartRow IS NOT NULL
        BEGIN

            --while loop
            WHILE @StartRow < @MaxRow
            BEGIN
                SET @StartTime = GETDATE();
                SET @objids = NULL;
                SET @Message
                    = 'Batch: ' + CAST(@BatchCount AS VARCHAR(10)) + ' Started: ' + CAST(@StartTime AS VARCHAR(30));

                IF @WithStats = 1
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                SET @objids = NULL;

                SELECT @objids = STUFF((
                                           SELECT TOP 1
                                                  ',' + CAST([o].[Objid] AS NVARCHAR(20))
                                           FROM @TableAuditList AS [o]
                                           WHERE [o].[Objid] >= @StartRow
                                           ORDER BY [Objid]
                                           FOR XML PATH('')
                                       )
                                      ,1
                                      ,1
                                      ,''
                                      )
                FROM @TableAuditList AS [o2]
                WHERE [o2].[Objid] >= @StartRow
                ORDER BY [o2].[Objid];

                IF @Debug > 0
                    SELECT @objids AS [Objids];



DECLARE @outputXML NVARCHAR(MAX)

         EXEC [dbo].[spMFGetObjectvers] @TableName = @TableName         -- nvarchar(100)
                                          ,@dtModifiedDate = NULL          -- datetime
                                          ,@MFIDs = @objids                  -- nvarchar(4000)
                                          ,@outPutXML = @outPutXML OUTPUT; -- nvarchar(max)

      EXEC [sys].[sp_xml_preparedocument] @Idoc OUTPUT, @outPutXML;

  
            WITH [cte]
            AS (SELECT [xmlfile].[objId]
                      ,[xmlfile].[MFVersion]
                      --       ,[xmlfile].[GUID]
                      ,[xmlfile].[ObjType]
                FROM
                    OPENXML(@Idoc, '/form/objVers', 1)
                    WITH
                    (
                        [objId] INT './@objectID'
                       ,[MFVersion] INT './@version'
                       --         ,[GUID] NVARCHAR(100) './@objectGUID'
                       ,[ObjType] INT './@objectType'
                    ) [xmlfile])
            SELECT COUNT(*) AS rcount FROM cte
  
  
  EXEC [sys].[sp_xml_removedocument] @Idoc;


     IF @WithStats = 1
                    RAISERROR(@Message, 10, 1) WITH NOWAIT;

                SET @BatchCount = @BatchCount + 1;
                SET @StartRow =
                (
                    SELECT MAX([ListItem]) + 1
                    FROM [dbo].[fnMFParseDelimitedString](@objids, ',')
                );

										  END

										  END
