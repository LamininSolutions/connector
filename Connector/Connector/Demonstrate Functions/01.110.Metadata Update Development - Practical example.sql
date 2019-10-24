/*
SYNCHRONIZE METADATA - REAL LIFE EXAMPLE

Use as template for additional objects
Use during development stage and part of production deployment plan
- Syncronize Metadata
- Update Property.ColumnName
- Section for each class table I am working with
	- Update Class.ClassTable Names
	- Drop And Create ClassTable
	- Create Class Table additional Indexes (if needed)

*/

--Syncronize Metadata
	EXEC [dbo].[spMFDropAndUpdateMetadata] @IsReset = 0 --Set to 1 if want to start over
	--EXEC [dbo].[spMFSynchronizeMetadata]

	--Specific metadata updates

	EXEC [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'Properties'
	--EXEC [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'Class'
	--EXEC [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'ValueList'
	--EXEC [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'ValueListItems'
	--EXEC [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'User'
	--EXEC [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'Login'
	--Exec [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'Workflow'
	--Exec [dbo].[spMFSynchronizeSpecificMetadata]   @Metadata = 'State'

--Update Specific Property Column Names, i.e. when you have a property called Process ID, which is reserved, it needs to get a new column name
	UPDATE [dbo].[MFProperty]
	SET [ColumnName] = 'Epicor_Process'
	WHERE name = 'Process ID'

-- Easy to read view of class tables with their properties for a specific list of classes you are working with currently
-- It is highly recommended to add aliasses for all your classes and properties in M-Files
SELECT [Class]
	 , [Class_Alias]
	 , [class_MFID]
	 , [TableName]
	 , [Property]
	 , [Property_alias]
	 , [Property_MFID]
	 , [Property_ID]
	 , [ColumnName]
	 , [PredefinedOrAutomatic]
	 , [Required]
	 , [Valuelist]
	 , [Valuelist_Alias]
	 , [Valuelist_ID]
	 , [Valuelist_MFID]
	 , [Valuelist_Owner]
	 , [Valuelist_Owner_MFID]
	 , [Valuelist_OwnerAlias]
	 , [IncludeInApp]
	 , [Workflow]
	 , [Workflow_Alias]
	 , [Workflow_MFID]
	 , [ObjectType]
	 , [ObjectType_Alias]
	 , [ObjectType_MFID]
	 , [SQLDataType]
	 , [MFDataType]
FROM [dbo].[MFvwMetadataStructure] WHERE [Class_Alias] IN('cARCreditMemoDoc','cARInvoiceDoc','cARStatementDoc','cCustomer')
ORDER BY [Class_Alias],[Propert_alias]


-------------------------------------------------------
-- Example of scripts for setup of Class: CLCustomer
-------------------------------------------------------
BEGIN
    SET NOCOUNT ON;
    PRINT 'Initializing CLCustomer'

    UPDATE [dbo].[MFClass]
    SET    [TableName] = 'CLCustomer'
    WHERE  [Name] = 'Customer'

    IF OBJECT_ID('CLCustomer') IS NOT NULL
        DROP TABLE [dbo].[CLCustomer]

    EXEC [dbo].[spMFCreateTable] @ClassName = 'Customer'

--setup of index on Class table
    CREATE INDEX [UDX_CLCustomer]
        ON [dbo].[CLCustomer]
        (
            [Epicor_Company_ID]
          , [Customer_Code]
        )

    DECLARE @Update_IDOut INT
          , @ProcessBatch_ID INT;

    EXEC [dbo].[spMFUpdateTable] @MFTableName = 'CLCustomer'
                               , @UpdateMethod = 1 --M-Files To MFSQL
                               , @Update_IDOut = @Update_IDOut OUTPUT
                               , @ProcessBatch_ID = @ProcessBatch_ID OUTPUT

    SET NOCOUNT OFF;
    SELECT *
    FROM   [dbo].[CLCustomer]
END

GO
GO