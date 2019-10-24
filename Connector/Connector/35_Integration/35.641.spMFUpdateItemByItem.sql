
go

PRINT SPACE(5) + QUOTENAME(@@SERVERNAME) + '.' + QUOTENAME(DB_NAME())
    + '.[dbo].[spMFUpdateItemByItem]';
GO
SET NOCOUNT ON 
EXEC setup.[spMFSQLObjectsControl] @SchemaName = N'dbo', @ObjectName = N'spMFUpdateItemByItem', -- nvarchar(100)
    @Object_Release = '2.1.1.13', -- varchar(50)
    @UpdateFlag = 2 -- smallint
go

/*-----------------------------------------------------------------------------------------------
  USAGE:
  =====
  debug mode
  DECLARE @Sessionid int
  EXEC [spMFUpdateItemByItem] 'MFOtherDocument', 1, @SessionIDOut = @SessionID output
  SELECT @SessionID
-----------------------------------------------------------------------------------------------*/

IF EXISTS ( SELECT  1
            FROM    INFORMATION_SCHEMA.ROUTINES
            WHERE   ROUTINE_NAME = 'spMFUpdateItemByItem'--name of procedure
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
CREATE PROCEDURE [dbo].[spMFUpdateItemByItem]
AS
    SELECT  'created, but not implemented yet.';
--just anything will do

GO
-- the following section will be always executed
SET NOEXEC OFF;
GO

ALTER PROCEDURE [dbo].[spMFUpdateItemByItem]
    @TableName VARCHAR(100) ,
    @Debug SMALLINT = 0 ,
    @SingleItems BIT = 1, --1 = processed one by one, 0 = processed in blocks
    @SessionIDOut INT OUTPUT
AS
/*rST**************************************************************************

====================
spMFUpdateItemByItem
====================

Return
  - 1 = Success
  - -1 = Error
Parameters
  @TableName varchar(100)
    Name of table to be updated
  @Debug smallint (optional)
    - Default = 0
    - 1 = Standard Debug Mode
    - 101 = Advanced Debug Mode
  @SingleItems bit (optional)
    - Default = 1; processed one-by-one
    - 0 = processed in blocks
  @SessionIDOut int (output)
    Output of the session id that was used to update the results in the MFAuditHistory Table

Purpose
=======

This is a special procedure that is useful when there are data errors in M-Files and it is necessary to determine which specific records are not being able to be processed.

Additional Info
===============

Note that this procedure use updatemethod 1 by default.  It returns a session id.  this id can be used to inspect the result in the MFAuditHistory Table. Refer to Using Audit History for more information on this table

Examples
========

.. code:: sql

    DECLARE @RC INT
    DECLARE @TableName VARCHAR(100) = 'MFCustomer'
    DECLARE @Debug SMALLINT
    DECLARE @SessionIDOut INT

    -- TODO: Set parameter values here.
    EXECUTE @RC = [dbo].[spMFUpdateItemByItem]
                        @TableName
                       ,@Debug
                       ,@SessionIDOut OUTPUT
    SELECT @SessionIDOut

Changelog
=========

==========  =========  ========================================================
Date        Author     Description
----------  ---------  --------------------------------------------------------
2019-08-30  JC         Added documentation
==========  =========  ========================================================

**rST*************************************************************************/
 /*
update check by record from objvers list
*/
    SET NOCOUNT ON;

    BEGIN
        BEGIN TRY
    

            DECLARE @ClassName VARCHAR(100) ,
                @ProcedureStep VARCHAR(100) = 'Start' ,
                @ProcedureName VARCHAR(100) = 'spMFUpdateItemByItem' ,
                @Result INT ,
                @RunTime DATETIME ,
                @Query NVARCHAR(MAX);

            SELECT  @ClassName = Name
            FROM    MFClass
            WHERE   [MFClass].[TableName] = @TableName; 
            SET @Query = N'SELECT OBJECT_ID(''' + @TableName + ''')';
            EXEC @Result = sp_executesql @Query;

            IF @Debug > 0
                SELECT  @Result;

            IF @Result = 0
                BEGIN
                    EXEC [dbo].[spMFCreateTable] @ClassName = @ClassName;-- nvarchar(128)
                END;

            DECLARE @NewXML XML ,
                @NewObjectXml VARCHAR(MAX); 

            EXEC [dbo].[spMFGetObjectvers] @TableName = @TableName, -- nvarchar(max)
                @dtModifiedDate = NULL, -- datetime
                @MFIDs = NULL, -- nvarchar(max)
                @outPutXML = @NewObjectXml OUTPUT;
 -- nvarchar(max)

            IF @Debug <> 0
                SELECT  @NewObjectXml;

            CREATE TABLE #ObjVersList
                (
                  ObjectType INT ,
                  [ObjID] INT ,
                  [MFVersion] INT ,
                  UpdateStatus INT
                );

            SET @NewXML = CAST(@NewObjectXml AS XML);
            IF @Debug = 2
                BEGIN
                    SELECT  @NewXML;
                    SELECT  t.c.value('(@version)[1]', 'INT') AS [MFVersion] ,
                            t.c.value('(@objectID)[1]', 'INT') AS [ObjID] ,
                            t.c.value('(@objectType)[1]', 'INT') AS [ObjectType]
                    FROM    @NewXML.nodes('/form/objVers') AS t ( c );
                END;

            INSERT  INTO [#ObjVersList]
                    ( [MFVersion] ,
                      [ObjID] ,
                      [ObjectType] 
                 
                    )
                    SELECT  t.c.value('(@version)[1]', 'INT') AS [MFVersion] ,
                            t.c.value('(@objectID)[1]', 'INT') AS [ObjID] ,
                            t.c.value('(@objectType)[1]', 'INT') AS [ObjectType]
                    FROM    @NewXML.nodes('/form/objVers') AS t ( c );
 
            DECLARE @Objids VARCHAR(10) ,
                @Objid INT ,
                @ReturnValue INT;
            SELECT  @Objid = CAST(MIN([ObjID]) AS VARCHAR(10))
            FROM    [#ObjVersList] AS [ovl]; 

			
			DECLARE @session int
			EXEC [dbo].[spMFTableAudit] @MFTableName = @TableName, -- nvarchar(128)
			    @MFModifiedDate = null, -- datetime
			    @ObjIDs = null, -- nvarchar(2500)
			    @Debug = 0, -- smallint
			    @SessionIDOut = @session output, -- int
			    @NewObjectXml = N'' -- nvarchar(max)
			
			DECLARE @Deletelist AS TABLE ([Objid] int)
			INSERT INTO @Deletelist
			        ( [Objid] )
			
			SELECT mah.[objid] FROM [dbo].[MFAuditHistory] AS [mah]
			INNER JOIN [#ObjVersList] AS [ovl]
			ON [ovl].[ObjID] = [mah].[ObjID]

			WHERE [mah].[SessionID] = @session AND [mah].[StatusFlag] <> 0

--			DELETE FROM [#ObjVersList] WHERE objid IN (SELECT objid FROM @Deletelist AS [d])

 
            WHILE EXISTS ( SELECT   ObjID
                           FROM     [#ObjVersList] AS [ovl]
                           WHERE    ObjID > @Objid )
                BEGIN
 
 
                    SELECT TOP 1
                            @Objid = ObjID
                    FROM    [#ObjVersList] AS [ovl]
                    WHERE   [ObjID] > @Objid
                    ORDER BY [ObjID];

                    IF @Debug <> 0
                        SELECT  @Objid AS nextObjid;

                    SET @Objids = CAST(@Objid AS VARCHAR(10)); 

UPDATE [mah]
SET UpdateFlag = 1

FROM [dbo].[MFAuditHistory] AS [mah] WHERE objid = @objid
              
SET @ProcedureStep = 'Updating object '+ @Objids 

                    EXEC @ReturnValue = [dbo].[spMFUpdateTable] @MFTableName = @TableName, -- nvarchar(128)
                        @UpdateMethod = 1, -- int
                        @UserId = NULL, -- nvarchar(200)
                        @MFModifiedDate = NULL, -- datetime
                        @ObjIDs = @ObjIDs, -- nvarchar(2500)
                        @Debug = 0; -- smallint

                    UPDATE  [#ObjVersList]
                    SET     [#ObjVersList].[UpdateStatus] = @ReturnValue
                    WHERE   ObjID = @Objid;

IF @ReturnValue <> 1
BEGIN
 INSERT  INTO MFLog
                    ( SPName ,
                      ProcedureStep ,
                      ErrorNumber ,
                      ErrorMessage ,
                      ErrorProcedure ,
                      ErrorState ,
                      ErrorSeverity ,
                      ErrorLine
                    )
            VALUES  ( @ProcedureName ,
                      @ProcedureStep ,
                      ERROR_NUMBER() ,
                      'Failed to process object' ,
                      'MFUpdateTable',
                      ERROR_STATE() ,
                      ERROR_SEVERITY() ,
                      ERROR_LINE()
                    );

END


                END;

            IF @Debug > 0
                BEGIN
                    SELECT  *
                    FROM    [#ObjVersList] AS [ovl];
                END;
	
			-----------------------------------------------------
			--Set Object Type Id and class id
			-----------------------------------------------------
            SET @ProcedureStep = 'Get Object Type and Class';

            DECLARE @objectIDRef INT ,
                @objectID INT ,
                @ClassID INT;
            SELECT  @objectIDRef = mc.MFObjectType_ID ,
                    @objectID = ob.MFID ,
                    @ClassID = mc.MFID
            FROM    dbo.MFClass mc
                    INNER JOIN dbo.MFObjectType ob ON ob.[ID] = mc.[MFObjectType_ID]
            WHERE   mc.TableName = @TableName;

            SELECT  @objectID = MFID
            FROM    dbo.MFObjectType
            WHERE   ID = @objectIDRef;

            IF @Debug > 0
                BEGIN
                    RAISERROR('Proc: %s Step: %s ObjectType: %i Class: %i',10,1,@ProcedureName, @ProcedureStep,@objectID, @ClassID);
                    IF @Debug = 2
                        BEGIN
                            SELECT  *
                            FROM    MFClass
                            WHERE   MFID = @ClassID;
                        END;
                END;
		
            IF @Debug > 0
                BEGIN
                    RAISERROR('Proc: %s Step: %s ',10,1,@ProcedureName, @ProcedureStep );
                           
                END;

            DECLARE @SessionID INT ,
                @TranDate DATETIME ,
                @Params NVARCHAR(MAX);
            SELECT  @TranDate = GETDATE();
            SELECT  @SessionID = ( SELECT   MAX(SessionID) + 1
                                   FROM     dbo.MFAuditHistory
                                 );
            SELECT  @SessionID = ISNULL(@SessionID, 1);

            SELECT  @SessionIDOut = @SessionID;

            BEGIN TRANSACTION;
            SET @ProcedureStep = 'Insert records into Audit History';

            SET @Params = N'@SessionID int, @TranDate datetime, @ObjectID int, @ClassID int';
            SELECT  @Query = N'INSERT INTO [dbo].[MFAuditHistory]
        ( RecID,
		[SessionID] ,
          [TranDate] ,
          [ObjectType] ,
          [Class] ,
          [ObjID] ,
          [MFVersion] ,
          [StatusFlag] ,
          [StatusName]
        )
                   
					SELECT 
					 t.[ID],
					@SessionID,
					@TranDate,
					@objectID,
					@ClassID,
                    CASE WHEN ao.[ObjID] IS NULL
                                            THEN t.[ObjID]
                                            ELSE ao.[ObjID]
                                       END ,
					ao.MFVersion,
                            CASE				WHEN t.Deleted = 1
                                                 THEN 3 --- Marked DELETED in SQL
												 WHEN ao.[MFVersion] IS NULL and isnull(t.deleted,0) = 0
                                                 THEN  4 --SQL to be deleted
                                                 WHEN ao.[MFVersion] = ISNULL(t.[MFVersion],
                                                              -1) and isnull(t.deleted,0) = 0 THEN 0 -- CURRENT VERSIONS ARE THE SAME
                                                 WHEN ao.[MFVersion] < ISNULL(t.[MFVersion],
                                                              -1) THEN 2 -- SQL version is later than M-Files - Sync error
                                                 WHEN t.[MFVersion] is null and ao.[MFVersion] is not null
                                                               THEN 5 -- new in SQL
												 WHEN ao.[MFVersion] > t.[MFVersion] and t.deleted = 0
                                                               THEN 1 -- MFiles is more up to date than SQL
                                            END,
							CASE				WHEN  t.deleted = 1 
                                                 THEN ''Deleted in MF''
										WHEN ao.[MFVersion]  IS NULL and isnull(t.deleted,0) = 0
                                                 THEN ''SQL to be deleted''
                                                 WHEN ao.[MFVersion] = ISNULL(t.[MFVersion],-1) THEN ''Identical''
                                                 WHEN ao.[MFVersion] < ISNULL(t.[MFVersion],-1) THEN ''SQL is later''
                                                 WHEN t.[MFVersion] is null and ao.[MFVersion] is not null
                                                               THEN ''New in SQL''
												 WHEN ao.[MFVersion] > t.[MFVersion] and t.deleted = 0 THEN ''MF is Later''
                                            END
                    FROM    [#ObjVerslist] AS [ao]
                            FULL OUTER JOIN [dbo].' + @TableName
                    + ' AS t ON t.[ObjID] = ao.[ObjID]
							;';


							
            IF @Debug > 0
                BEGIN                            
                    RAISERROR('Proc: %s Step: %s',10,1,@ProcedureName, @ProcedureStep);
                END; 



            EXEC sp_executesql @Query, @Params, @SessionID = @SessionID,
                @TranDate = @TranDate, @ObjectID = @objectID,
                @ClassId = @ClassID;

            SET @ProcedureStep = 'Update Processed';
							
            COMMIT TRAN [main];
            DROP TABLE [#ObjVersList];
           
            SET NOCOUNT OFF;

        END TRY

        BEGIN CATCH
            IF @@TRANCOUNT <> 0
                BEGIN
                    ROLLBACK TRANSACTION;
                END;

            SET NOCOUNT ON;

            IF @Debug > 0
                BEGIN
                    SELECT  ERROR_NUMBER() AS ErrorNumber ,
                            ERROR_MESSAGE() AS ErrorMessage ,
                            ERROR_PROCEDURE() AS ErrorProcedure ,
                            @ProcedureStep AS ProcedureStep ,
                            ERROR_STATE() AS ErrorState ,
                            ERROR_SEVERITY() AS ErrorSeverity ,
                            ERROR_LINE() AS ErrorLine;
                END;

            SET NOCOUNT OFF;

            RETURN 2; --For More information refer Process Table

        END CATCH;
    END;


GO
