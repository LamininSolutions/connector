


PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateTable_ObjIds_GetGroupedList]';

EXEC Setup.[spMFSQLObjectsControl] @SchemaName = N'dbo',
    @ObjectName = N'spMFUpdateTable_ObjIds_GetGroupedList', -- nvarchar(100)
    @Object_Release = '3.1.1.36', -- varchar(50)
    @UpdateFlag = 2;
 -- smallint

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateTable_ObjIds_GetGroupedList'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFUpdateTable_ObjIds_GetGroupedList]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL
   DROP TABLE  #ObjIdList;
CREATE TABLE #ObjIdList ( [ObjId] INT )
GO

ALTER PROCEDURE [dbo].[spMFUpdateTable_ObjIds_GetGroupedList]
    (
       @ObjIds_FieldLenth SMALLINT = 2000
	  ,@Debug SMALLINT = 0
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
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode


Purpose
=======

Additional Info
===============

Prerequisites
=============

Warnings
========

Examples
========

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
 /*******************************************************************************
  ** Desc:  The purpose of this procedure is to group source records into batches
  **		and compile a list of OBJIDs in CSV format to pass to spMFUpdateTable
  **  
  ** Version: 1.0.0.0
  **
  ** Processing Steps:
  **					1. Calculate Number of Groups in RecordSet
  **					2. Assign Group Numbers to Source Records
  **					3. Return ObjIDs CSV List by GroupNumber
  **
  ** Parameters and acceptable values: 
  **					@ObjIds_FieldLenth: Indicate the size of each group iteration CSV text field   
  **					@Debug				
  **			         	
  ** Restart:
  **					Restart at the beginning.  No code modifications required.
  ** 
  ** Tables Used:                 					  
  **					
  **
  ** Return values:		
  **					1 = success
  **					2 = Failure	
  **
  ** Called By:			NONE
  **
  ** Calls:           
  **					sp_executesql
  **					spMFUpdateTable
  **
  ** Author:			arnie@lamininsolutions.com
  ** Date:				2016-05-14
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
	2017-06-08	ACILLIERS	change default size of @ObjIds_FieldLenth to 2000 from 4000 as NVARCHAR(4000) is same as VARCHAR(2000)
  ********************************************************************************
  ** EXAMPLE EXECUTE
  ********************************************************************************
		IF OBJECT_ID('tempdb..#ObjIdList') IS NOT NULL
		   DROP TABLE  #ObjIdList;
		CREATE TABLE #ObjIdList ( [ObjId] INT  PRIMARY KEY )

		INSERT #ObjIdList
				( ObjId )
		SELECT ObjID
		FROM CLGLChart

		EXEC spMFUpdateTable_ObjIDS_GetGroupedList

  ******************************************************************************/
    BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;



	-----------------------------------------------------
	--DECLARE LOCAL VARIABLE
	-----------------------------------------------------
	   DECLARE	@return_value INT = 1
			,	@rowcount INT = 0
			,	@ProcedureName sysname = 'spMFUpdateTable_ObjIds_GetGroupList'
			,	@ProcedureStep sysname = 'Start'
			,	@sqlQuery NVARCHAR(MAX)
			,	@sqlParam NVARCHAR(MAX)

	-----------------------------------------------------
	--Calculate Number of Groups in RecordSet
	-----------------------------------------------------
	SET @ProcedureStep = 'Get Number of Groups '
	DECLARE @NumberofGroups INT

    SELECT  @NumberofGroups = ( SELECT  COUNT(*)
                                FROM    #ObjIdList
                              ) / ( @ObjIds_FieldLenth --ObjIds fieldlenth
                                    / ( SELECT  MAX(LEN([ObjId])) + 2
                                        FROM    #ObjIdList
                                      ) --avg size of each item in csv list including comma
                                    );			

	SET @NumberofGroups = ISNULL(NULLIF(@NumberofGroups,0),1)
		IF @Debug > 0
			    RAISERROR('Proc: %s Step: %s: %d group(s)',10,1,@ProcedureName,@ProcedureStep,@NumberofGroups);
	
	   
	-----------------------------------------------------
	--Assign Group Numbers to Source Records
	-----------------------------------------------------
	SET @ProcedureStep = 'Assign Group Numbers to Source Records '
	CREATE TABLE #GroupDtl ([ObjID] INT,[GroupNumber] int )
	
	INSERT  #GroupDtl
			( [ObjID]
			, [GroupNumber]
			)
	SELECT  [ObjID]
			, NTILE(@NumberofGroups) OVER ( ORDER BY ObjID ) AS GroupNumber
	FROM #ObjIdList

		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s Step: %s: %d record(s)',10,1,@ProcedureName, @ProcedureStep,@rowcount);
		

	-----------------------------------------------------
	--Get ObjIDs CSV List by GroupNumber
	-----------------------------------------------------
	SET @ProcedureStep = 'Get ObjIDs CSV List by GroupNumber '

		CREATE TABLE #GroupHdr ([GroupNumber] INT, [ObjIDs] NVARCHAR(4000))
		INSERT  #GroupHdr
				( [GroupNumber]
				, [ObjIDs]
				)
				SELECT  [source].[GroupNumber]
					  , [ObjIDs] = STUFF(( SELECT ','
											  , CAST([ObjID] AS VARCHAR(10))
										 FROM   #GroupDtl
										 WHERE  [GroupNumber] = [source].[GroupNumber]
									   FOR
										 XML PATH('')
									   ), 1, 1, '')
				FROM    ( SELECT    [GroupNumber]
						  FROM      #GroupDtl
						  GROUP BY  [GroupNumber]
						) [source];

		SET @rowcount = @@ROWCOUNT
		IF @Debug > 0
			    RAISERROR('Proc: %s Step: %s: %d record(s)',10,1,@ProcedureName, @ProcedureStep,@rowcount);
		


	-----------------------------------------------------
	--Return GroupedList
	-----------------------------------------------------	
	SELECT * 
	FROM #GroupHdr
	ORDER BY GroupNumber

	END


GO


