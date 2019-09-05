PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSearchForObjectbyPropertyValues]';
go
 

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSearchForObjectbyPropertyValues', -- nvarchar(100)
    @Object_Release = '4.3.9.49', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
go

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSearchForObjectbyPropertyValues'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
go
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSearchForObjectbyPropertyValues]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF
go

ALTER PROCEDURE [dbo].[spMFSearchForObjectbyPropertyValues] (@ClassID         [INT]
                                                              ,@PropertyIds    [NVARCHAR](2000)
                                                              ,@PropertyValues [NVARCHAR](2000)
                                                              ,@Count          [INT]
                                                              ,@OutputType int
                                                              ,@IsEqual int=0
                                                              ,@XMLOutPut xml output
                                                              ,@TableName varchar(200)='' output)
AS
/*rST**************************************************************************

===================================
spMFSearchForObjectbyPropertyValues
===================================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ClassID int
    ID of the class
  @PropertyIds nvarchar(2000)
    Property ID’s separated by comma
  @PropertyValues nvarchar(2000)
    Property values separated by comma
  @Count int
    The maximum number of results to return
  @OutputType int
    - 0 = output to XML (default)
    - 1 = output to temporary table and update MFSearchLog
  @XMLOutPut xml (output)
    Used if outputType = 0 then this parameter returns the result in XML format
  @TableName varchar(200) (output)
    Used if outputType = 1 then this parameter returns the name of the temporary file with the result

Purpose
=======

To search for objects with class id and some specific property id and value.

Additional Info
===============

This procedure will call spMFSearchForObjectByPropertyValuesInternal and get the objects details that satisfies the search conditions and shows the objects details in tabular format.

Examples
========

.. code:: sql

    DECLARE @RC INT
    DECLARE @ClassID INT
    DECLARE @PropertyIds NVARCHAR(2000)
    DECLARE @PropertyValues NVARCHAR(2000)
    DECLARE @Count INT
    DECLARE @OutputType INT
    DECLARE @XMLOutPut XML
    DECLARE @TableName VARCHAR(200)

    -- TODO: Set parameter values here.
    EXECUTE @RC = [dbo].[spMFSearchForObjectbyPropertyValues]
       @ClassID
      ,@PropertyIds
      ,@PropertyValues
      ,@Count
      ,@OutputType
      ,@XMLOutPut OUTPUT
      ,@TableName OUTPUT
    GO

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2019-08-13  LC         Added Additional option for search procedure
2019-05-08  LC         Change target table to a temporary table
2018-04-04  DEV2       Added License module validation code.
2016-09-26  DEV2       Removed vault settings parameters and pass them as comma separated string in @VaultSettings parameters.
2016-08-27  LC         Update variable function paramaters
2016-08-24  DEV2       TaskID 471
2014-04-29  DEV2       RETURN statement added
==========  =========  ========================================================

**rST*************************************************************************/
  BEGIN
      BEGIN TRY
          BEGIN TRANSACTION
		SET NOCOUNT ON
          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
          DECLARE @Xml             [NVARCHAR](MAX)
                  ,@IsFound        BIT
                  ,@VaultSettings  NVARCHAR(4000)
                  ,@XMLDoc         XML
                  ,@Columns        NVARCHAR(MAX)
                  ,@Query          NVARCHAR(MAX)

          -----------------------------------------------------
          --ACCESS CREDENTIALS
          -----------------------------------------------------
          

		  SELECT @VaultSettings=dbo.FnMFVaultSettings()

		-----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFSearchForObjectByPropertyValuesInternal
		------------------------------------------------------------------
		EXEC [dbo].[spMFCheckLicenseStatus] 
		   'spMFSearchForObjectByPropertyValuesInternal'
		   ,'spMFSearchForObjectbyPropertyValues'
		   ,'Checking module access for CLR procdure spMFSearchForObjectByPropertyValuesInternal
'
          
          -----------------------------------------------------
          -- CLASS WRAPPER PROCEDURE
          -----------------------------------------------------
          EXEC dbo.spMFSearchForObjectByPropertyValuesInternal
             @VaultSettings
            ,@ClassID
            ,@PropertyIds
            ,@PropertyValues
            ,@Count
			,@IsEqual
            ,@Xml OUTPUT
            ,@IsFound OUTPUT

          IF ( @IsFound = 1 )
            BEGIN
                SELECT @XMLDoc = @Xml

                -----------------------------------------------------
                --CREATE TEMPORARY TABLE STORE DATA FROM XML
                -----------------------------------------------------
                CREATE TABLE #Properties
                  (
                     [objectId]       [INT]
                     ,[propertyId]    [INT] NULL
                     ,[propertyValue] [NVARCHAR](100) NULL
                     ,[propertyName]  [NVARCHAR](100) NULL
                     ,[dataType]      [NVARCHAR](100) NULL
                  )

                -----------------------------------------------------
                -- INSERT DATA FROM XML
                -----------------------------------------------------
                INSERT INTO #Properties
                            (objectId,
                             propertyId,
                             propertyValue,
                             dataType)
                SELECT t.c.value('(../@objectId)[1]', 'INT')              AS objectId
                       ,t.c.value('(@propertyId)[1]', 'INT')              AS propertyId
                       ,t.c.value('(@propertyValue)[1]', 'NVARCHAR(100)') AS propertyValue
                       ,t.c.value('(@dataType)[1]', 'NVARCHAR(1000)')     AS dataType
                FROM   @XMLDoc.nodes('/form/Object/properties')AS t(c)

                ----------------------------------------------------------------------
                -- UPDATE PROPERTY NAME WITH COLUMN NAME SPECIFIED IN MFProperty TABLE
                ----------------------------------------------------------------------				
                UPDATE #Properties
                SET    propertyName = ( SELECT ColumnName
                                        FROM   dbo.MFProperty
                                        WHERE  MFID = #Properties.propertyId )

                UPDATE #Properties
                SET    propertyName = Replace(propertyName, '_ID', '')
                WHERE  dataType = 'MFDatatypeLookup'
                    OR dataType = 'MFDatatypeMultiSelectLookup'

                -----------------------------------------------------
                ---------------PIVOT--------------------------
                -----------------------------------------------------
                SELECT @Columns = Stuff(( SELECT ',' + Quotename(propertyName)
                                          FROM   #Properties ppt
                                          GROUP  BY ppt.propertyName
                                          ORDER  BY ppt.propertyName
                                          FOR XML PATH(''), TYPE ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

				------------------------------------------
				 --This code gets name of new table.
				------------------------------------------
				if @OutputType!=0 
				Begin
					Select @TableName=dbo.fnMFVariableTableName('##MFSearch', Default)
				End

                ----------------------------------
                --creating dynamic query for PIVOT
                ----------------------------------
                SET @Query = 'SELECT objectId
								,' + @Columns
                                + ' into '+@TableName+'
						FROM   ( SELECT objectId
										,propertyName new_col
										,value
								 FROM   #Properties
										UNPIVOT ( value
												FOR col IN (propertyValue) ) un ) src
							   PIVOT ( Max(value)
									 FOR new_col IN ( ' + @Columns
                                + ' ) ) p '


                --EXECUTE (@Query)

				 if @OutputType!=0
					begin
						EXECUTE (@Query)
						insert into MFSearchLog(TableName,SearchClassID,SearchText,SearchDate,ProcessID)
						values(@TableName,@ClassID,'PropertyIds:'+@PropertyIds+' PropertyValues:'+@PropertyValues,GETDATE(),2)
						
					End
				else
					Begin
						select @XMLOutPut= @Xml
					End

				
                DROP TABLE #Properties
            END
          ELSE
            BEGIN
                ----------------------------------
                --Showing not Found message
                ----------------------------------
                DECLARE @Output NVARCHAR(MAX)

                SET @Output = 'Object not exists in this vault'

                SELECT @Output
            END

          COMMIT TRANSACTION

		  RETURN 1
      END TRY

      BEGIN CATCH
          ROLLBACK TRANSACTION

          --------------------------------------------------
          -- INSERTING ERROR DETAILS INTO LOG TABLE
          --------------------------------------------------
          INSERT INTO MFLog
                      (SPName,
                       ErrorNumber,
                       ErrorMessage,
                       ErrorProcedure,
                       ErrorState,
                       ErrorSeverity,
                       ErrorLine,
                       ProcedureStep)
          VALUES      ('spMFSearchForObjectbyPropertyValues',
                       Error_number(),
                       Error_message(),
                       Error_procedure(),
                       Error_state(),
                       Error_severity(),
                       Error_line(),
                       '')
		RETURN 2
	  END CATCH
  END



go
