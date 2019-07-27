
/*
Demonstrating the new feature that when the name of a state is updated in M-Files, the Class tables referencing the name can be updated with the change

*/
--Created on: 2019-03-09 

--check workflow state in SQL

SELECT *
FROM [dbo].[MFWorkflowState] AS [mws]
INNER JOIN [dbo].[MFWorkflow] AS [mw]
ON [mw].[ID] = [mws].[MFWorkflowID]

--make a change to workflow state in MF Admin

-- update metadata
EXEC [dbo].[spMFDropAndUpdateMetadata] @IsStructureOnly = 0;

--recheck workflow state table in SQL - this should show ISNameUpdate column = 1 for the changed object.

--you can also use other metadata update methods
EXEC [dbo].[spMFSynchronizeSpecificMetadata] @Metadata = 'States' -- varchar(100)
                                            ,@IsUpdate = 0        -- smallint
                                            ,@ItemName = NULL     -- varchar(100)
                                            ,@Debug = 0;

                                                                  -- smallint

--or

EXEC [dbo].[spMFSynchronizeMetadata];

-- to update a class table with the state change

-- check which classes are using the workflow

SELECT class FROM [dbo].[MFvwMetadataStructure] AS [mfms] 
INNER JOIN [dbo].[MFWorkflow] AS [mw]
ON [mfms].[Workflow_MFID] = mw.[MFID]
INNER JOIN [dbo].[MFWorkflowState] AS [mws]
ON [mws].[MFWorkflowID] = [mw].[ID]
WHERE mws.[IsNameUpdate] = 1
GROUP BY [mfms].[Class]

--it may be necessary to create the class table if it is not already done in SQL
EXEC [dbo].[spMFCreateTable] @ClassName = 'Contract or Agreement' -- nvarchar(128)
                            ,@Debug = 0     -- smallint


							
							EXEC [dbo].[spMFUpdateTable] @MFTableName = 'MFcontractorAgreement'     -- nvarchar(200)
							                            ,@UpdateMethod = 1    -- int
							                          
							

--check to see if the workflow state name change has been processed (it is expected to not change have changed)

SELECT Workflow_State FROM MFcontractorAgreement


--use the following procedure to update all the state label changes

DECLARE @ProcessBatch_id INT;

EXEC [dbo].[spmfSynchronizeWorkFlowSateColumnChange] @TableName = 'MFContractorAgreement' -- nvarchar(200)
                                                    ,@ProcessBatch_id = @ProcessBatch_id OUTPUT         -- int
                                                    ,@Debug = 1     -- int

--OR 


EXEC [dbo].[spmfSynchronizeWorkFlowSateColumnChange]