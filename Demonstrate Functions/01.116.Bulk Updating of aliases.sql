
/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
Use spMFAliasesUpsert to update aliases in bulk based on a set Prefix
This procedure allows:
Selecting a prefix that would be added for all aliases in the execution
Select one or more of the metadata types that could have aliases.  These include: Properties, Classes, ObjectTypes, Valuelists, Workflows and workflow states
If isRemove is set to 1 then all the aliases in the MFTablesNames list with the set prefix will be removed
If WithUpdate is set to 0 then the aliases will not be pushed into M-Files.  This is mainly used to inspect the aliases before updating M-Files

Naming convensions are: (note that all special characters are removed, spaces are replaced with _)
WorkflowStates : prefix.Workflow.WorkflowState (The full alias will be restricted to 100 characters)
Classes : prefix.cl.Class
ObjectType prefix.ot.ObjectType
Property, Valuelists : prefix.Name

note that this procedure take approx 2 minutes per metadata table to update

*/

/*
Adding workflow and workflow state aliases with a prefix of LS
note that prefixes is flexible.  For instance, use YourCompany.c.classname for classes, or p.property if you dont want any namespace prefix

also note that in the case of the workflows states, the name of the workflow is automatically added in the alias. This will make selection in compliance kit substantially easier.

*/

DECLARE @ProcessBatch_ID INT;
EXEC [dbo].[spMFAliasesUpsert]
    @MFTableNames = 'MFProperty', -- comma delimited string
    @Prefix = 'prop',
    @IsRemove = 0,
    @WithUpdate = 1,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @Debug = 0

	SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

	GO

	SELECT * FROM dbo.MFClass AS mc

/*
Removing all aliases with a prefix of LS from workflow states
*/

DECLARE @ProcessBatch_ID INT;
EXEC [dbo].[spMFAliasesUpsert]
    @MFTableNames = 'MFWorkflowstate',
    @Prefix = 'ws',
    @IsRemove = 0, -- set to 1 to remove all aliases
    @WithUpdate = 1,
    @ProcessBatch_ID = @ProcessBatch_ID OUTPUT,
    @Debug = 0

		SELECT * FROM [dbo].[MFProcessBatchDetail] AS [mpbd] WHERE [mpbd].[ProcessBatch_ID] = @ProcessBatch_ID

		SELECT * FROM dbo.MFWorkflowState AS mws



		GO

