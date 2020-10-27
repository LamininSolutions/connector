PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFGetMissingobjectIds]';
go
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFGetMissingobjectIds', -- nvarchar(100)
    @Object_Release = '4.8.22.62', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go
/*
 Change history

  2016-8-22		LC		change objids to NVARCHAR(4000)
  2017-7-15		Dev2	increase size of objids to overcome cutting off of missing objects
  2017-7-25		LC		remove redundant variables
  2017-10-01	LC		fix bug with parameter sizes
  2018-8-3		LC		Prevent endless loop
  2020-08-31    LC      prevent null warning
*/
IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFGetMissingobjectIds'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
    BEGIN
        PRINT SPACE(10) + '...Stored Procedure: update';
        SET NOEXEC ON;
    END;
ELSE
    PRINT SPACE(10) + '...Stored Procedure: create';
go
CREATE PROCEDURE [dbo].[spMFGetMissingobjectIds]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do
go
-- the following section will be always executed
SET NOEXEC OFF;
go

alter PROCEDURE [dbo].[spMFGetMissingobjectIds]
    (
      @objIDs nVARCHAR(max) ,
      @MFtableName VARCHAR(200) ,
      @missing nvarchar(max) OUTPUT ,
	  @Debug SMALLINT = 0
    )

AS /*******************************************************************************
  ** Desc:  The purpose of this procedure is to getting the missing id from the class table as XML  
  **  
  ** Version: 2.0.0.1
  **
  ** Author:			Kishore
  ** Date:				25-05-2016

  ******************************************************************************/
  
  
    BEGIN

	DECLARE @ProcedureName AS NVARCHAR(128) = 'spMFGetMissingobjectIds';
		DECLARE @ProcedureStep AS NVARCHAR(128) = 'Start';
		DECLARE @DefaultDebugText AS NVARCHAR(256) = 'Proc: %s Step: %s'
		DECLARE @DebugText AS NVARCHAR(256) = ''

        --DECLARE @objId nVARCHAR(max);
        --DECLARE @objGuid nVARCHAR(max);
        --DECLARE @objTypeId nVARCHAR(max);
        DECLARE @missingIds nVARCHAR(max);
        DECLARE @retSTring nVARCHAR(max);
        DECLARE @position INT;
        DECLARE @length INT;
        DECLARE @value nVARCHAR(max);
        SET @objIDs = @objIDs  + ',';
        SET @missingIds = '';

        DECLARE @SelectQuery NVARCHAR(MAX);
        DECLARE @Missinglist NVARCHAR(MAX);

        DECLARE @ParmDefinition NVARCHAR(max);
        SET @ParmDefinition = N'@retvalOUT varchar(max) OUTPUT';

/*     SET @SelectQuery = '
select @retvalOUT = coalesce(@retvalOUT+ '','','''') + item from (
  SELECT item FROM dbo.fnMFSplitString(''' + @objIDs
            + ''','','') where item not in (select objid from ' + @tableName
            + ' )
  ) as k;';
     
--	 PRINT @SelectQuery
*/


SET @SelectQuery = 'select @retvalOUT = coalesce(@retvalOUT+ '','','''') + CAST(item AS varchar(10)) FROM (
  SELECT item FROM dbo.fnMFSplitString(''' + @objIDs + ''','','') WHERE item != 0
  EXCEPT SELECT objid FROM ' + @MFtableName +') k'
			
--			select @SelectQuery;

        EXEC sp_executesql @SelectQuery, @ParmDefinition,
            @retvalOUT = @MissingList OUTPUT;

Set @DebugText = ' missing %s'
Set @DebugText = @DefaultDebugText + @DebugText
Set @Procedurestep = 'Objids '

IF @debug > 0
	Begin
		RAISERROR(@DebugText,10,1,@ProcedureName,@ProcedureStep,@MissingList );
	END

        SET @missingIds = @MissingList + ',';
 


        SET @position = 0;
        SET @length = 0;
        SET @retSTring = '';

		--SELECT @missingIds
		--SELECT CHARINDEX(',', @missingIds, @position + 1) AS value

		Begin
        WHILE CHARINDEX(',', @missingIds, @position + 1) > 0
            BEGIN
                SET @length = CHARINDEX(',', @missingIds, @position + 1)
                    - @position;
                SET @value = SUBSTRING(@missingIds, @position, @length);
                IF ( @value != '' )
                    SET @retSTring = @retSTring + '<objVers objectID='''
                        + @value + ''' version=''' + '-1'
                        + '''   objectGUID='''
                       +'{89CACFAE-E6B0-44EE-8F91-685A4A1D9E08}'+ ''' />';
                SET @position = CHARINDEX(',', @missingIds,
                                          @position + @length) + 1;
            END;
			END
--{89CACFAE-E6B0-44EE-8F91-685A4A1D9E08}
        SET @missing = @retSTring;


    END;


go


