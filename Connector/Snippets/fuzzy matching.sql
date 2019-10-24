http://www.sqlservercentral.com/articles/Fuzzy+Match/65702/
https://www.red-gate.com/simple-talk/sql/t-sql-programming/fuzzy-searches-sql-server/

https://www.google.com/search?q=SQL+Fuzzy+name+matching&rlz=1C1CHZL_enUS710US710&oq=SQL+Fuzzy+name+matching&aqs=chrome..69i57j0.7143j0j8&sourceid=chrome&ie=UTF-8



SELECT custom.[f_MatchData] ('Baystream Corp.','Baystream Corporation')

Baystream Corp.
Baystream Corporation
Baystream Corporation

CREATE FUNCTION [custom].[f_MatchData]
    (
        @Column1 VARCHAR(MAX),
        @Column2 VARCHAR(MAX)
    )

--------------------------------------------------
--  Developed by Martin Fourie - 20160902
--------------------------------------------------
RETURNS DECIMAL(18, 2)
AS
    BEGIN

        DECLARE
            @Max    INT,
            @Left   INT,
            @Right  INT,
            @Check  INT,
            @Result DECIMAL(18, 2);

        SET @Check = 0;

        SET @Max = CASE
                       WHEN LEN(@Column1) > LEN(@Column2)
                           THEN LEN(@Column1)
                       ELSE
                           LEN(@Column2)
                   END;
        SET @Left = 1;
        SET @Right = 1;

        WHILE @Max > 0
            BEGIN

                DECLARE
                    @T1 VARCHAR(1),
                    @T2 VARCHAR(1);
                SET @T1 = (RIGHT(LEFT(@Column1, @Left), @Right));
                SET @T2 = (RIGHT(LEFT(@Column2, @Left), @Right));

                SET @Check = @Check + (CASE
                                           WHEN @T1 = @T2
                                               THEN 1
                                           ELSE
                                               0
                                       END
                                      );

                SET @Left = @Left + 1;
                SET @Max = @Max - 1;

            END;
        -----------------------------------------------------------------
        --
        -----------------------------------------------------------------
        SET @Max = CASE
                       WHEN LEN(@Column1) > LEN(@Column2)
                           THEN LEN(@Column1)
                       ELSE
                           LEN(@Column2)
                   END;
        SET @Left = 1;
        SET @Right = 1;

        WHILE @Max > 0
            BEGIN

                DECLARE
                    @T3 VARCHAR(1),
                    @T4 VARCHAR(1);
                SET @T3 = (LEFT(RIGHT(@Column1, @Right), @Left));
                SET @T4 = (LEFT(RIGHT(@Column2, @Right), @Left));

                SET @Check = @Check + (CASE
                                           WHEN @T3 = @T4
                                               THEN 1
                                           ELSE
                                               0
                                       END
                                      );

                SET @Left = @Right + 1;
                SET @Max = @Max - 1;

            END;

        SET @Max = CASE
                       WHEN LEN(@Column1) > LEN(@Column2)
                           THEN LEN(@Column1)
                       ELSE
                           LEN(@Column2)
                   END;

        SET @Result = CAST((@Check * 1.00) / (@Max * 2.00) * 100 AS DECIMAL(18, 2));

        RETURN @Result;

    END;