
--added 2018-10-30
--4.2.7.46
--foreign key index for FK_MFClass_ObjectType_ID  
--4.6.16.57
--add more indexes

SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'FKIX_MFClass_MFObjectType_ID'
          AND object_id = OBJECT_ID('[dbo].[MFClass]')
)
    CREATE NONCLUSTERED INDEX FKIX_MFClass_MFObjectType_ID
    ON dbo.MFClass (MFObjectType_ID);

--foreign key index for FK_MFClass_MFWorkflow_ID 
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'FKIX_MFClass_MFWorkflow_ID'
          AND object_id = OBJECT_ID('[dbo].[MFClass]')
)
    CREATE NONCLUSTERED INDEX FKIX_MFClass_MFWorkflow_ID
    ON dbo.MFClass (MFWorkflow_ID);

--foreign key index for FK_ObjectTypeToClassIndex_Class_ID  
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'FKIX_MFObjectTypeToClassObject_Class_ID'
          AND object_id = OBJECT_ID('[dbo].[MFObjectTypeToClassObject]')
)
    CREATE NONCLUSTERED INDEX FKIX_MFObjectTypeToClassObject_Class_ID
    ON dbo.MFObjectTypeToClassObject (Class_ID);

--foreign key index for FK_ObjectTypeToClassIndex_ObjectType_ID  
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'FKIX_MFObjectTypeToClassObject_ObjectType_ID'
          AND object_id = OBJECT_ID('[dbo].[MFObjectTypeToClassObject]')
)
    CREATE NONCLUSTERED INDEX FKIX_MFObjectTypeToClassObject_ObjectType_ID
    ON dbo.MFObjectTypeToClassObject (ObjectType_ID);

--foreign key index for FK_MFProperty_MFValueList  
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'FKIX_MFProperty_MFValueList_ID'
          AND object_id = OBJECT_ID('[dbo].[MFProperty]')
)
    CREATE NONCLUSTERED INDEX FKIX_MFProperty_MFValueList_ID
    ON dbo.MFProperty (MFValueList_ID);

--foreign key index for FK_MFVaultSettings_MFAuthenticationType_ID  
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'FKIX_MFVaultSettings_MFAuthenticationType_ID'
          AND object_id = OBJECT_ID('[dbo].[MFVaultSettings]')
)
    CREATE NONCLUSTERED INDEX FKIX_MFVaultSettings_MFAuthenticationType_ID
    ON dbo.MFVaultSettings (MFAuthenticationType_ID);

--foreign key index for FK_MFVaultSettings_MFProtocolType_ID  
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'FKIX_MFVaultSettings_MFProtocolType_ID'
          AND object_id = OBJECT_ID('[dbo].[MFVaultSettings]')
)
    CREATE NONCLUSTERED INDEX FKIX_MFVaultSettings_MFProtocolType_ID
    ON dbo.MFVaultSettings (MFProtocolType_ID);


--add indexes for change history


IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_ObjectChangeHistory_ObjType_ObjID'
)
       CREATE INDEX idx_ObjectChangeHistory_ObjType_ObjID ON [MFObjectChangeHistory](ObjectType_ID, [ObjID]);

IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_ObjectChangeHistory_Class_Objid'
)
 CREATE INDEX idx_ObjectChangeHistory_Class_Objid ON [MFObjectChangeHistory](Class_ID, [ObjID])


--add indexes for MFcontextmenuqueue


IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_contextmenuqueue_ObjType_ObjectID'
)
       CREATE INDEX idx_contextmenuqueue_ObjType_ObjectID ON [MFcontextmenuqueue](ObjectType, [ObjectID]);

IF NOT EXISTS(SELECT 1 
FROM sys.indexes 
WHERE name='idx_contextmenuqueue_ClassID_Objectid'
)
 CREATE INDEX idx_contextmenuqueue_ClassID_Objectid ON [MFcontextmenuqueue](ClassID, [ObjectID])


GO




