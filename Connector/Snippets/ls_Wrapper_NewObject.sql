
--REPLACE THE FOLLOWING WITH YOUR OBJECT DETAILS
DECLARE @Class_MFID INT = 78
DECLARE @Objid INT = 157
DECLARE @ObjectType_MFID INT = 136




--NO CHANGES BELOW THIS LINE

DECLARE @ObjVerXmlOut      NVARCHAR(MAX)
       ,@NewObjectXml      NVARCHAR(MAX)
       ,@SynchErrorObjects NVARCHAR(MAX)
       ,@DeletedObjVerXML  NVARCHAR(MAX)
       ,@ErrorXML          NVARCHAR(MAX)
	   ,@VaultSettings     NVARCHAR(2000) = [dbo].[FnMFVaultSettings]()
		,@XmlFile		 NVARCHAR(MAX) = '<form><Object id="'+CAST(@ObjectType_MFID AS varchar(10))+'"><class id="'+CAST(@Class_MFID AS varchar(10))+'"/></Object></form>'	
		,@ObjIDsForUpdate NVARCHAR(MAX) = '<form><objVers objectID="'+CAST(@ObjID AS varchar(10))+'" version="-1" objectGUID="{000000-0000-0000-000000000000}"/></form>'
DECLARE @ListOfProperties NVARCHAR(MAX) = '0'
	

EXEC [dbo].[spMFCreateObjectInternal] @VaultSettings = @VaultSettings     -- nvarchar(4000)
                                     ,@XmlFile = @XmlFile           -- nvarchar(max)
                                     ,@objVerXmlIn =  @ObjIDsForUpdate     -- nvarchar(max)
                                     ,@MFIDs = @ListOfProperties             -- nvarchar(2000)
                                     ,@UpdateMethod = 1      -- int
                                     ,@dtModifieDateTime = null -- datetime
                                     ,@sLsOfID = @ObjIDsForUpdate           -- nvarchar(max)
                                     ,@ObjVerXmlOut = @ObjVerXmlOut OUTPUT                       -- nvarchar(max)
                                     ,@NewObjectXml = @NewObjectXml OUTPUT                       -- nvarchar(max)
                                     ,@SynchErrorObjects = @SynchErrorObjects OUTPUT             -- nvarchar(max)
                                     ,@DeletedObjVerXML = @DeletedObjVerXML OUTPUT               -- nvarchar(max)
                                     ,@ErrorXML = @ErrorXML OUTPUT                               -- nvarchar(max)


	SELECT  CAST(@NewObjectXml AS XML)
