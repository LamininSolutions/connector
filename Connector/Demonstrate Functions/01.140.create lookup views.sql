/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
Creating lookups to work with validation and inserting new objects

Valuelists
Workflows

*/

SELECT *
FROM   [MFValueListItems] [mvli]
INNER JOIN [MFValuelist] [mvl] ON [mvl].[id] = [mvli].[MFValueListID]
WHERE  [mvl].[Name] = 'Country'

EXEC [spMFCreateValueListLookupView] 'Country'
								   , 'MFvwCountry'

SELECT *
FROM   [MFvwCountry]

SELECT *
FROM   [MFWorkflow] [mwf]
INNER JOIN [MFWorkflowState] [mwfs] ON [mwf].[ID] = [mwfs].[MFWorkflowID]

EXEC [spMFCreateWorkflowStateLookupView] 'Contract Approval Workflow'
									   , 'MFvwContractApproval'

SELECT *
FROM   [MFvwContractApproval]