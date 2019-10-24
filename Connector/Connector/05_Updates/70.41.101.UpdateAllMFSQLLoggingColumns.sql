

/*
Author: leRoux Cilliers
Date:	25/12/2017  
Time:	06:45  
Applicable from version 3.1.4.41

Purpose: Migration script to add MFSQL message and MFSQL Batch Process to each class table in App

This migration script in not included in the installation procedure, but can be run on demand if required.

*/




SET NOCOUNT ON;

DECLARE @Rowid INT;
DECLARE @TableName NVARCHAR(100);
DECLARE @ProcedureStep NVARCHAR(100);
DECLARE @Count INT;

DECLARE
    @IsDetailLogging SMALLINT,
    @SQL             NVARCHAR(MAX);


SELECT
    @IsDetailLogging = CAST(ISNULL([Value], '0') AS INT)
FROM
    [dbo].[MFSettings] AS [ms]
WHERE
    [Name] = 'App_DetailLogging';


IF @IsDetailLogging = 1
    BEGIN

        SELECT
            @Rowid = MIN([ID])
        FROM
            [MFClass]
        WHERE
            [IncludeInApp] = 1;

        SELECT
           @Count = COUNT(*)
        FROM
            [dbo].[MFProperty] AS [mp]
        WHERE
            [Name] IN (
                          'MFSQL Message', 'MFSQL Process Batch'
                      );

       
	    IF @Count = 2 
            BEGIN

                WHILE @Rowid IS NOT NULL
                    BEGIN

                        SELECT
                            @TableName = [TableName]
                        FROM
                            [MFClass]
                        WHERE
                            [ID] = @Rowid;

                        -------------------------------------------------------------
                        -- ADD standard Logging properties
                        -------------------------------------------------------------
                        SET @ProcedureStep = 'Add MFSQL_Message and MFSQL_Process_Batch columns';




                        BEGIN

                            SELECT
                                @count = COUNT(*)
                            FROM
                                [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                            WHERE
                                [c].[COLUMN_NAME] = 'MFSQL_Message'
                                AND [c].[TABLE_NAME] = @TableName;
       
	    IF @Count = 0
                                BEGIN

                                    SET @SQL = N'
Alter Table ' +                     @TableName + '
Add MFSQL_Message nvarchar(100) null;';

                                    EXEC (@SQL);

                                    PRINT SPACE(5) + 'Added Column MFSQL_Message to ' + @TableName;

                                END; --columns does not exist on table

                             SELECT
                                @count = COUNT(*)
                            FROM
                                [INFORMATION_SCHEMA].[COLUMNS] AS [c]
                            WHERE
                                [c].[COLUMN_NAME] = 'MFSQL_Process_batch'
                                AND [c].[TABLE_NAME] = @TableName;
                           IF @Count = 0
                                BEGIN
                                    SET @SQL = N'
Alter Table ' +                     @TableName + '
Add  MFSQL_Process_batch int null;' ;

                                    EXEC (@SQL);

                                    PRINT SPACE(5) + 'Added Column MFSQL_Process_batch to ' + @TableName;

                                END; --columns does not exist on table


                        END;

                        SELECT
                            @Rowid = MIN([ID])
                        FROM
                            [MFClass]
                        WHERE
                            [IncludeInApp] = 1
                            AND [ID] > @Rowid;

                    END; -- while statement
            END; -- Is properties setup
        ELSE
            BEGIN
                PRINT SPACE(5)
                      + 'Properties MFSQL_Message and MFSQL_Process Batch have not been created. Install MFSQL Context Menu to install properties in vault';
            END; --end else
    END; --Detail logging  = 1
ELSE
    PRINT SPACE(5) + 'Detail logging is not active';


GO

