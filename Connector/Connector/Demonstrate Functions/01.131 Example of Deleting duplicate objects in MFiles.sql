
/*
dentify and delete duplicate records in Mfiles
*/
UPDATE mic2
SET mic2.Process_ID = 1
FROM dbo.MFInventoryCons AS mic2
    INNER JOIN
    (
        SELECT list2.ObjID
        FROM
        (
            SELECT mic.Cast,
                   mic.Mill_Plate,
                   mic.ObjID,
                   ROW_NUMBER() OVER (PARTITION BY mic.Cast,
                                                   mic.Mill_Plate
                                      ORDER BY mic.Cast,
                                               mic.Mill_Plate
                                     ) Rownr
            FROM dbo.MFInventoryCons AS mic
                INNER JOIN
                (
                    SELECT mic.Cast,
                           mic.Mill_Plate
                    FROM dbo.MFInventoryCons AS mic
                    GROUP BY mic.Cast,
                             mic.Mill_Plate
                    HAVING COUNT(*) > 1
                ) l
                    ON l.Cast = mic.Cast
                       AND l.Mill_Plate = mic.Mill_Plate
        ) list2
        WHERE list2.Rownr > 1
    ) list3
        ON mic2.ObjID = list3.ObjID;

EXEC dbo.spMFDeleteObjectList @TableName = N'MFInventoryCons', -- nvarchar(100)
                              @Process_id = 1,                 -- int
                              @Debug = 0,                      -- int
                              @DeleteWithDestroy = 0;       -- bit






