

/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
WORKFLOW AND WORKFLOW STATES
*/

/*
Workflows and states join
*/

SELECT
    *
FROM
    [dbo].[MFWorkflowState] AS [MWS]
    INNER JOIN
        [dbo].[MFWorkflow]  AS [MW]
            ON [MWS].[MFWorkflowID] = [MW].[ID];

/*
Creating a workflow state lookupup view for integrations
*/

EXEC [dbo].[spMFCreateWorkflowStateLookupView]
    @WorkflowName = N'Contract Approval Workflow', 
    @ViewName = N'MFvwContractApproval',           
    @Debug = 0;                                    

SELECT
    *
FROM
    [MFvwContractApproval];


/*
Updating workflow state alias
*/

UPDATE
    [dbo].[MFWorkflowState]
SET
    [Alias] = 'ws.' + [dbo].[fnMFReplaceSpecialCharacter]([Name])
WHERE
    [MFWorkflowID] = 14;

--update M-Files with the new aliase
EXEC [dbo].[spMFSynchronizeSpecificMetadata]
    @Metadata = 'state', -- varchar(100)
    @Debug = 0,          -- smallint
    @IsUpdate = 1;       -- smallint

-- check M-Files to view newly created aliases in the states

/*
Updating workflow alias
*/

UPDATE
    [dbo].[MFWorkflow]
SET
    [Alias] = 'wf.' + [dbo].[fnMFReplaceSpecialCharacter]([Name])
WHERE
    [MFID] = 107;

EXEC [dbo].[spMFSynchronizeSpecificMetadata]
    @Metadata = 'workflow', -- varchar(100)
    @Debug = 0,             -- smallint
    @IsUpdate = 1;          -- smallint

-- check M-Files to view newly created aliase for the workflow

/*
Update workflow and state on record
*/

SELECT
    *
FROM
    [dbo].[MFClass] AS [MC]
WHERE
    [Name] = 'Drawing';

EXEC [dbo].[spMFCreateTable]
    @ClassName = N'Drawing', -- nvarchar(128)
    @Debug = 0;              -- smallint


EXEC [dbo].[spMFUpdateTable]
    @MFTableName = N'MFDrawing', -- nvarchar(128)
    @UpdateMethod = 1;           -- int

SELECT workflow, workflow_ID, state, state_ID,
    *
FROM
    [dbo].[MFDrawing] AS [MD];

INSERT INTO [dbo].[MFDrawing]
    (
        [Customer_ID],
        [Drawing_Type_ID],
        [Name_Or_Title],
        [Project_ID],
        [State_ID],
        [Workflow_ID],
        [Process_ID]
    )
VALUES
    (
        149, 1, 'TestWorkflow', 5, NULL, NULL, 1
    );

EXEC [dbo].[spMFUpdateTable]
    @MFTableName = N'MFDrawing', -- nvarchar(128)
    @UpdateMethod = 0;           -- int

--note that the workflow is automatically created as it is set to required on the class configuration

