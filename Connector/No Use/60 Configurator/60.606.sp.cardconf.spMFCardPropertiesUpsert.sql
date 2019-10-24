GO

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[cardconf].[spMFCardPropertyUpsert]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'cardconf',   @ObjectName = N'spMFCardPropertyUpsert', -- nvarchar(100)
    @Object_Release = '2.1.1.17', -- varchar(50)
    @UpdateFlag = 2 -- smallint



/*------------------------------------------------------------------------------------------------
	Author: leRoux Cilliers, Laminin Solutions
	Create date: 2016-12
	Database: 
	Description: Upsert Card Property table
------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
  MODIFICATION HISTORY
  ====================
 	DATE			NAME		DESCRIPTION
	2016-12-10		lc			Add to MFSQLConnector
------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====

exec CardConf.spMFCardPropertyUpsert @Rule_ID = 12
select * from CardConf.[MFProperties] T
select * from MFClass

-----------------------------------------------------------------------------------------------*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFCardPropertyUpsert'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'cardconf' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE cardconf.spMFCardPropertyUpsert
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

alter PROCEDURE CardConf.spMFCardPropertyUpsert
    (
      @Rule_ID int
    )
AS 
   
    BEGIN



	DECLARE @Class_ID INT
	SELECT @Class_ID = class_MFID FROM [CardConf].[MFCardRules] AS [mcr] WHERE mcr.[Rule_ID] = @Rule_ID
	

        MERGE INTO CardConf.[MFCardProperties] T
        USING
            ( SELECT    mcr.[Rule_ID],mp.[MFID] AS Property_MFID

              FROM      [dbo].[MFProperty] AS [mp]
                        LEFT JOIN [dbo].[MFClassProperty] AS [mcp] ON mp.ID = mcp.[MFProperty_ID]
                        LEFT JOIN [dbo].[MFClass] AS [mc] ON mc.ID = mcp.[MFClass_ID]
						LEFT JOIN cardconf.[MFCardRules] AS [mcr]
						ON [mcr].[Class_MFID] = [mc].mfid
              WHERE     mc.mfid = @Class_ID
                        AND mp.MFID > 1000 AND [mcr].[RuleType] = 'Behaviour'
            ) S
        ON ( T.[Property_MFID] = S.[Property_MFID]
             AND T.[Rule_ID] = S.[Rule_ID]
           )
        WHEN NOT MATCHED BY TARGET THEN
            INSERT ( [Rule_ID]
			,[Property_MFID]
                   )
            VALUES ( s.[Rule_ID]
			,s.[Property_MFID]
                   )
			WHEN NOT MATCHED BY SOURCE AND [T].[Rule_ID] = @Rule_ID THEN DELETE 	   
				   ;

    END;

GO



