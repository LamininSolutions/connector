
--SELECT TOP 10 objid, * FROM [dbo].[MFotherdocument] AS [mic]

--DECLARE @Update_IDOut int
--EXEC spmfupdatetable @MFTableName = 'MFOtherDocument', @UpdateMethod = 1, @Objids = '71', @Update_IDOut = @Update_IDOut OUTPUT, @Debug = 101

DECLARE @ObjVerXmlOut      NVARCHAR(MAX)
       ,@NewObjectXml      NVARCHAR(MAX)
       ,@SynchErrorObjects NVARCHAR(MAX)
       ,@DeletedObjVerXML  NVARCHAR(MAX)
       ,@ErrorXML          NVARCHAR(MAX)
	   ,@VaultSettings		NVARCHAR(400)
	  , @XMLFile NVARCHAR(MAX)
	  ,@objVerXMLIn NVARCHAR(MAX)
	  ,@MFIDs NVARCHAR(MAX)
	  ,@UpdateMethod INT = 0
	  ,@dtModifiedDateTime  DATETIME = null
	  	  ,@sLsOfID  NVARCHAR(MAX) 
		  
--SELECT @objVerXMLIn=CAST([muh].[ObjectVerDetails] AS NVARCHAR(MAX)) 
--,@XMLFile = CAST(ObjectDetails AS NVARCHAR(max))
--FROM [dbo].[MFUpdateHistory] AS [muh] WHERE id = @Update_IDOut

	  SET @VaultSettings = [dbo].[FnMFVaultSettings]()
      
--replace the text of these with the output from step 1
	SET @objVerXMLIn = null
	SET @XMLFile = '<form><Object id="160" sqlID="13527" objID="11604" objVesrion="6" DisplayID="11604"><class id="94"><property id="0" dataType="1">REPUBLIC STEEL (FMINC 002510 604)</property><property id="22" dataType="8">0</property><property id="27" dataType="7"/><property id="1149" dataType="2">604</property><property id="1339" dataType="1">FMINC</property><property id="1340" dataType="1">REPUBLIC STEEL</property><property id="1341" dataType="13">RM 115 410 OBERLIN RD. S.W. MASSILLON  OH 44647</property><property id="1342" dataType="1">20-MRO</property><property id="1343" dataType="1">20-MRO</property><property id="1344" dataType="1">002510</property><property id="1345" dataType="1">REPUBLIC STEEL (FMINC 002510 604)</property><property id="1346" dataType="1">D</property><property id="1347" dataType="8">0</property><property id="1348" dataType="8">0</property><property id="1355" dataType="2">71492</property><property id="1398" dataType="1">I</property></class></Object></form>'
	SELECT CAST(@XMLFile AS XML)
	  SET @sLsOfID  = null
	  SET @MFIDs = '0,0,0,1341,1182,0,1173,1178,1180,1179,0,100,1339,0,1081,20,0,25,0,1161,1347,1344,1346,1149,1181,21,0,23,1355,0,1348,1342,1177,22,0,39,1343,1340,1398,1345,0,38,0,0,0,0,0,0,27,0,0,1174,0,1408,0,44'



EXEC [dbo].[spMFCreateObjectInternal] @VaultSettings = @VaultSettings     -- nvarchar(4000)
                                     ,@XmlFile = @XMLFile          -- nvarchar(max)
                                     ,@objVerXmlIn = @objVerXMLIn       -- nvarchar(max)
                                     ,@MFIDs = @MFIDs             -- nvarchar(2000)
                                     ,@UpdateMethod = @UpdateMethod      -- int
                                     ,@dtModifieDateTime = @dtModifiedDateTime -- datetime
                                     ,@sLsOfID = @sLsOfID           -- nvarchar(max)
                                     ,@ObjVerXmlOut = @ObjVerXmlOut OUTPUT                       -- nvarchar(max)
                                     ,@NewObjectXml = @NewObjectXml OUTPUT                       -- nvarchar(max)
                                     ,@SynchErrorObjects = @SynchErrorObjects OUTPUT             -- nvarchar(max)
                                     ,@DeletedObjVerXML = @DeletedObjVerXML OUTPUT               -- nvarchar(max)
                                     ,@ErrorXML = @ErrorXML OUTPUT                               -- nvarchar(max)

									 SELECT CAST(@NewObjectXml AS XML)
									 SELECT CAST(@ObjVerXmlOut AS XML)
                                     SELECT @ErrorXML


