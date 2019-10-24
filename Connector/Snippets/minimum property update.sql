DECLARE
    @VaultSettings   NVARCHAR(1000),
    @XML             NVARCHAR(MAX),
    @objVerXMLString NVARCHAR(MAX),
    @mfids           NVARCHAR(MAX),
    @Updatemethod    INT           = 0,
    @MFModifiedDate  DATETIME      = NULL,
    @ObjIDsForUpdate NVARCHAR(MAX) = null,
    @XmlOUT          NVARCHAR(MAX),
    @NewObjectXml    NVARCHAR(MAX),
    @SynchErrorObj   NVARCHAR(MAX),
    @DeletedObjects  NVARCHAR(MAX),
    @ErrorInfo       NVARCHAR(MAX);

SET @VaultSettings = [dbo].[FnMFVaultSettings]();
SET @XML
    = '<form><Object id="101" sqlID="2" objID="18" objVesrion="8" DisplayID="18"><class id="80"><property id="0" dataType="1">Leadership Training / OMCC</property><property id="1094" dataType="9">6</property><property id="22" dataType="8">0</property></class></Object></form>';
SET @objVerXMLString = NULL;
SET @mfids = 	'0,0,0,0,100,0,1094,22,0,38,0,39,0,0,0,0,0,0,27,0';



------------------------Added for checking required property null-------------------------------	
EXECUTE [dbo].[spMFCreateObjectInternal]
    @VaultSettings,
    @XML,
    @objVerXMLString,
    @mfids,
    @Updatemethod,
    @MFModifiedDate,
    @ObjIDsForUpdate,
    @XmlOUT OUTPUT,
    @NewObjectXml OUTPUT,
    @SynchErrorObj OUTPUT,  --Added new paramater
    @DeletedObjects OUTPUT, --Added new paramater
    @ErrorInfo OUTPUT;


	SELECT CAST(@XMLOUT AS XML)
	SELECT CAST(@NewObjectXml AS XML)
	SELECT @ErrorInfo


	/*
	= '<form><Object id="101" sqlID="2" objID="18" objVesrion="7" DisplayID="18"><class id="80"><property id="0" dataType="1">Leadership Training / OMCC</property>
	<property id="27" dataType="7">0</property><property id="22" dataType="8">0</property><property id="1095" dataType="8">0</property><property id="1094" dataType="9">6</property><property id="1079" dataType="10">148</property><property id="1081" dataType="10">5</property></class></Object></form>';

	<form><Object objID="18" objVesrion="9"><class id="80"><property id="0" dataType="1">Leadership Training / OMCC</property><property id="27" dataType="7">0</property><property id="22" dataType="8">0</property><property id="1095" dataType="8">0</property><property id="1094" dataType="9">1</property><property id="38" dataType="9"/><property id="39" dataType="9"/><property id="1079" dataType="10"/><property id="1081" dataType="10"/></class></Object></form>

	= '<form><Object id="101" sqlID="2" objID="18" objVesrion="7" DisplayID="18"><class id="80">
	<property id="0" dataType="1">Leadership Training / OMCC</property><property id="27" dataType="7">0</property><property id="22" dataType="8">0</property><property id="1095" dataType="8">0</property>
	<property id="1094" dataType="9">6</property>
	<property id="1079" dataType="10">148</property><property id="1081" dataType="10">5</property>
	</class></Object></form>';

	'0,0,0,0,100,0,1081,20,0,25,0,1079,1095,21,0,23,0,0,1094,22,0,38,0,39,0,0,0,0,0,0,27,0';
	0,0,0,0,100,0,1081,20,0,25,0,1079,1095,21,0,23,0,0,1094,22,0,38,0,39,0,0,0,0,0,0,27,0
	'0,0,0,0,100,0,1094,22,0,38,0,39,0,0,0,0,0,0,27,0';

	
	*/