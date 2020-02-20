PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSearchForObject]';
go
SET NOCOUNT off
 
go

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSearchForObject', -- nvarchar(100)
    @Object_Release = '4.3.9.48', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSearchForObject'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFSearchForObject]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

go
-- the following section will be always executed
SET NOEXEC OFF
go

ALTER PROCEDURE [dbo].[spMFSearchForObject] (@ClassID     INT
                                              ,@SearchText NVARCHAR (2000)
                                              ,@Count      INT = 1
                                              ,@OutputType INT = 0 -- 0 = output to select 1 = output to temp search table
                                              ,@XMLOutPut xml output
                                              ,@TableName varchar(200)='' output
                                              ,@Debug SMALLINT = 0)
AS
/*rST**************************************************************************

===================
spMFSearchForObject
===================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @ClassID int
    ID of the class
  @SearchText nvarchar(2000)
    Pass name of the object for a specific record else pass NULL to get all objects
  @Count int (optional)
    - Default = 1
    - The maximum number of results to return. Specify 0 to return unlimited number of results.
  @OutputType int
    - 0 = output to XML (default)
    - 1 = output to temporary table and update MFSearchLog
  @XMLOutPut xml (output)
    Used if outputType = 0 then this parameter returns the result in XML format
  @TableName varchar(200) (output)
    Used if outputType = 1 then this parameter returns the name of the temporary file with the result
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode

Purpose
=======

To search for objects with class id and name or title property.

Additional Info
===============

This procedure will call spMFSearchForObjectInternal and get the objects details that satisfies the search conditions and shows the objects details in tabular format.

The result is either:

- inserted in a temporary table. MFSearchLog is updated with the name of the table and summary of result.
- output as an XML output parameter.

Examples
========

.. code:: sql

    EXEC [dbo].[spMFSearchForObject] @ClassID = 78                  -- the class MFID: this can be obtained from select Name, MFID from MFClass
                                    ,@SearchText = 'A'              -- any text value, this can be a part text. It does not cater for wildcards
                                    ,@Count = 5                     -- used to restrict the number of search result returns.
                                    ,@Debug = 0
                                    ,@OutputType = 1                -- set to 1 to channel output to a table
                                    ,@XMLOutPut = @XMLOutPut OUTPUT -- is null 
                                    ,@TableName = @TableName OUTPUT;

                                                                    -- used in subsequent processing to process the search result.
    --show temp table name
    SELECT @TableName AS [TableName];

    --view search result
    SELECT *
    FROM [dbo].[MFSearchLog] AS [msl];
    GO

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
2019-05-06  LC         Change destination of search to a temporary file
2018-04-04  DEV2       Added License Module validation code.
2016-09-26  DEV2       Removed vault settings parameters and pass them as comma separated string in @VaultSettings parameter.
2016-08-27  LC         Update variabletable function parameters
2016-08-24  DEV2       TaskID 471
2016-06-26  LC         Debugging added
2014-04-29  DEV2       RETURN statement added
==========  =========  ========================================================

**rST*************************************************************************/
  BEGIN
      BEGIN TRY
          BEGIN TRANSACTION
		  SET NOCOUNT on
          -----------------------------------------------------
          --DECLARE LOCAL VARIABLE
          -----------------------------------------------------
          DECLARE @Xml             [NVARCHAR] (MAX)
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
	      -- Checking module access for CLR procdure  spMFSearchForObjectInternal
         ------------------------------------------------------------------
         EXEC [dbo].[spMFCheckLicenseStatus] 
		      'spMFSearchForObjectInternal',
			  'spMFSearchForObject',
			  'Checking module access for CLR procdure  spMFSearchForObjectInternal'
         
          -----------------------------------------------------
          -- CLASS WRAPPER PROCEDURE
          -----------------------------------------------------
          EXEC spMFSearchForObjectInternal
             @VaultSettings
            ,@ClassID
            ,@SearchText
            ,@Count
            ,@Xml OUTPUT
            ,@IsFound OUTPUT

          SELECT @XMLDoc = @Xml

		  IF @debug <> 0
		  SELECT @isFound;

		  IF @debug <> 0
		  SELECT @XMLDoc;
          -----------------------------------------------------
          --IF OBJECT FOUND
          -----------------------------------------------------
          IF ( @IsFound = 1 )
            BEGIN
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
                                        FROM   MFProperty
                                        WHERE  MFID = #properties.propertyId )

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
					Select @TableName=dbo.fnMFVariableTableName('##MFSearch',Default)
				END
                
	
				 ----------------------------------
                --creating dynamic query for PIVOT
                ----------------------------------

                SELECT @Query = 'SELECT objectId
								,' + @Columns
                                + ' into dbo.'+@TableName+'
						FROM   ( SELECT objectId
										,propertyName new_col
										,value
								 FROM   #Properties
										UNPIVOT ( value
												FOR col IN (propertyValue) ) un ) src
							   PIVOT ( Max(value)
									 FOR new_col IN ( ' + @Columns
                                + ' ) ) p 
								
								'

				IF @debug <> 0
				print @Query;
               
			   
			      if @OutputType!=0
					begin
						EXECUTE (@Query)
						insert into MFSearchLog(TableName,SearchClassID,SearchText,SearchDate,ProcessID)
						values(@TableName,@ClassID,@SearchText,GETDATE(),1)

						
					End
				else
					Begin
						select @XMLOutPut= @Xml
					End


				IF @debug <> 0
				SELECT * FROM [#Properties];

                DROP TABLE #Properties
            END
          ELSE
            BEGIN
                ----------------------------------
                --Showing not Found message
                ----------------------------------
                DECLARE @Output NVARCHAR(MAX)

                SELECT @Output = 'Object with Title " ' + @SearchText
                                 + '  is not found'

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
          VALUES      ('spMFSearchForObject',
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
