PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME()) + '.[dbo].[spMFSynchronizeValueListItems]';
GO

SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFSynchronizeValueListItems', -- nvarchar(100)
    @Object_Release = '3.1.5.41', -- varchar(50)
    @UpdateFlag = 2 -- smallint
 
GO

IF EXISTS ( SELECT  1
            FROM   information_schema.Routines
            WHERE   ROUTINE_NAME = 'spMFSynchronizeValueListItems'--name of procedure
                    AND ROUTINE_TYPE = 'PROCEDURE'--for a function --'FUNCTION'
                    AND ROUTINE_SCHEMA = 'dbo' )
BEGIN
	PRINT SPACE(10) + '...Stored Procedure: update'
    SET NOEXEC ON
END
ELSE
	PRINT SPACE(10) + '...Stored Procedure: create'
GO
	
-- if the routine exists this stub creation stem is parsed but not executed
CREATE PROCEDURE [dbo].[spMFSynchronizeValueListItems]
AS
       SELECT   'created, but not implemented yet.'--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF
GO

ALTER PROCEDURE [dbo].[spMFSynchronizeValueListItems] (@VaultSettings        [NVARCHAR](4000)
                                                        ,@Debug          SMALLINT = 0
                                                        ,@Out            [NVARCHAR](MAX) OUTPUT
														,@MFvaluelistID INT = 0)
AS
/*rST**************************************************************************

=============================
spMFSynchronizeValueListItems
=============================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @VaultSettings nvarchar(4000)
    fixme description
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode
  @Out nvarchar(max) (output)
    fixme description
  @MFvaluelistID int
    fixme description


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
  ** Desc:  The purpose of this procedure is to synchronize M-File VALUE LIST ITEM details  
  **  
  ** Version: 1.0.0.6
  
  ** Author:			Thejus T V
  ** Date:				27-03-2015
  ********************************************************************************
  ** Change History
  ********************************************************************************
  ** Date        Author     Description
  ** ----------  ---------  -----------------------------------------------------
  ** 2015-3-6    GLC		approach to re-use valuelist item list from M-Files rather than
  					get it for each loop; also to take account of deleted value lists.
  ** 2016-26-09  DevTeam2  Removed vault settings parameters and pass them as comma 
                           separated string in @VaultSettings parameter
	 2018-04-04  DevTeam2  Added License module validation code.
	 2018-5-20	 LC			Delete valuelist items that is deleted in MF
  ******************************************************************************/
  BEGIN
      SET NOCOUNT ON

      DECLARE @ValueListId INT

      -----------------------------------------------------
      -- update mfvaluelistitems for all deleted valuelists
      -----------------------------------------------------
      UPDATE mvli
      SET    deleted = 1
      FROM   MFValueList mvl
             INNER JOIN [dbo].[MFValueListItems] AS [mvli]
                     ON [mvli].[MFValueListID] = [mvl].[ID]
      WHERE  mvl.[Deleted] = 1

	  -----------------------------------------------------------------
	    -- Checking module access for CLR procdure  spMFGetValueListItems  
      ------------------------------------------------------------------
      EXEC [dbo].[spMFCheckLicenseStatus] 
	                                      'spMFGetValueListItems'
										  ,'spMFSynchronizeValueListItems'
										  ,'Checking module access for CLR procdure  spMFGetValueListItems'

      DECLARE InsertValueLIstItemCursor CURSOR LOCAL FOR
        -----------------------------------------------------
        --Select ValueListId From MFValuelist Table 
        -----------------------------------------------------
        SELECT MFID
        FROM   MFValueList
        WHERE  [Deleted] = 0
		and  [ID] = CASE 
		WHEN @MFvaluelistID = 0 THEN [ID]
		ELSE @MFvaluelistID
		END
		AND [RealObjectType]!=1


      OPEN InsertValueLIstItemCursor

      ----------------------------------------------------------------
      --Select The ValueListId into declared variable '@vlaueListID' 
      ----------------------------------------------------------------
      FETCH NEXT FROM InsertValueLIstItemCursor INTO @ValueListId

      WHILE @@FETCH_STATUS = 0
        BEGIN
            -------------------------------------------------------------------
            --Declare new variable to store the outPut of 'GetMFValueListItems'
            ------------------------------------------------------------------- 
            DECLARE @Xml [NVARCHAR](MAX);

            
DELETE FROM mfvaluelistItems WHERE [MFValueListID] = @ValueListId AND [Deleted] = 1
------------------------------------------------------------------------------------------
            --Execute 'GetMFValueListItems' to get the all MFValueListItems details in xml format 
            ------------------------------------------------------------------------------------------
            EXEC spMFGetValueListItems
               @VaultSettings
              ,@ValueListId
              ,@Xml OUTPUT;

			  IF @debug > 10
			  SELECT @XML AS ValuelistitemXML;

            DECLARE @Output INT;

            ----------------------------------------------------------------------------------------------------------
            --Execute 'InsertMFValueListItems' to insert all property Details into 'MFValueListItems' Table
            ----------------------------------------------------------------------------------------------------------
            EXEC spMFInsertValueListItems
              @Xml
              ,@Output OUTPUT
              ,@Debug; 

			   IF @debug > 10
			  SELECT @Output AS ValuelistitemsInsert;


			  IF EXISTS (Select top 1 * from MFValueListItems where IsNameUpdate=1)
			   Begin
			      
				  EXEC spmfSynchronizeLookupColumnChange

			   ENd

            --------------------------------------------------------------------
            --Select The Next ValueListId into declared variable '@vlaueListID' 
            --------------------------------------------------------------------
            FETCH NEXT FROM InsertValueLIstItemCursor INTO @ValueListId
        END

      -----------------------------------------------------
      --Close the Cursor 
      -----------------------------------------------------
      CLOSE InsertValueLIstItemCursor

      -----------------------------------------------------
      --Deallocate the Cursor 
      -----------------------------------------------------
      DEALLOCATE InsertValueLIstItemCursor

      IF ( @Output > 0 )
        SET @Out = 'All ValueLists are Updated'
      ELSE
        SET @Out = 'All ValueLists are upto date'

      SET NOCOUNT OFF
  END
  go
  