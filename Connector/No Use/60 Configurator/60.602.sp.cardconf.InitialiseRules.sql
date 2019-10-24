

/*
initialise Rules for classes included in app

this is run as the first step in creating the Metadata Configuration Rules

It will set the root condition and behaviour rulename

 SELECT * FROM cardconf.[MFCardRules] AS [mcr]  

*/


DECLARE @RuleType AS TABLE ( RuleTypes VARCHAR(50) );
INSERT  INTO @RuleType
        ( [RuleTypes] )
VALUES  ( 'Condition'  -- RuleTypes - varchar(50)
          ),
        ( 'Behaviour' );

INSERT  INTO CardConf.[MFCardRules]
        ( [RuleType] ,
          [Class_MFID] ,
          [RuleName] ,
          [Description] ,
          [LevelUpRule_ID] ,
          [RulePriority] ,
          [RuleCondition_ID] ,
          [IsActive]
        )
        SELECT  rt.[RuleTypes] ,	
		mc.MFID  ,
                RuleName = mc.[TableName] + '_Root',
				CASE WHEN rt.[RuleTypes] = 'Condition' THEN  'Root Condition'
				WHEN rt.[RuleTypes] = 'Behaviour' THEN  'Root Behaviour'
				END,
				0,
				1,
				NULL,
				1
        FROM    [dbo].[MFClass] AS [mc]
                LEFT JOIN CardConf.[MFCardRules] AS [mcr] ON mc.MFID = mcr.[Class_MFID]
                CROSS APPLY @RuleType rt
        WHERE   [mc].[IncludeInApp] IS NOT NULL;   

	UPDATE mcr
	SET mcr.[RuleCondition_ID]
	
 = (SELECT TOP 1 Rule_ID FROM [CardConf].[MFCardRules] AS [mcr2]
	WHERE mcr2.[Class_MFID] = mcr.[Class_MFID] AND mcr2.[RuleType] = 'Condition' AND mcr2.[Rule_ID] <> mcr.[Rule_ID] ) 
	
	 FROM cardconf.[MFCardRules] AS [mcr]
		
   
