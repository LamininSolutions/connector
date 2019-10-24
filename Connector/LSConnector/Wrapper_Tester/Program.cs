using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Wrapper_Tester
{
	class Program
	{
		static void Main(string[] args)
		{


            string Result = String.Empty;
            Boolean IsFound = false;
            string VaultSettingsNew = System.Configuration.ConfigurationSettings.AppSettings["VaultSettings"].ToString();
            //MFilesWrapper.GetUserAccounts(VaultSettings, out Result);
            MFilesWrapper.SearchForObject(VaultSettingsNew, 78, "a", 5,out Result, out IsFound);

            Console.WriteLine(Result);
            Console.ReadKey();

            //MF username
            string sUsername = "ls-Cilliersl";

			//MF password
			string sPassword = "3c5eFonmffOU0omIPxjyhw==";

			//Netwrok
			string sNetworkAddress = "laminindev.lamininsolutions.com";

			//vault name
			string sVaultName = "ConnectorSamplevault";


			//Object type and class info
			string sXmlFile = "<form><Object id='136'><class id='94' /></Object></form>";
			

			//Object details  WE NEED THIS INFO ALSO
			string sObjVerXml = "<form><ObjectType id='0'><objVers objectID='74' version='7' objectGUID='{65EEBEE6-591A-4FD8-8750-C7000C36261B}' /> <objVers objectID='77' version='13' objectGUID='{B00FD5C3-5881-45BC-B61A-0C924FE26B33}' /></ObjectType></form>";

			//Properties Def NEED THIS
			string sPropertyIds = "0,0,0,20,0,25,1034,1004,21,0,23,0,0,100,0,38,0,39,0,0,0,0,0,27,0,0,1079,1002,0,1078,37,0,1076,0,1132";
			
			//Update Method
			int iUpdateMethod = 2;

			//Last Modifies Date
			DateTime? dtModifieDateTime = Convert.ToDateTime("2015-07-04 14:43:56.953");

			//List of ObjID (if you want to do objID filter use this)
			//string sLsOfID =  ;

			//"<form><objVers objectID='4' version='-1' objectGUID='{11DFDE45-881C-4825-9991-969E8F75578C}'/><objVers objectID='5' version='-1' objectGUID='{11DFDE45-881C-4825-9991-969E8F75578C}'/></form>"
			//Out params
			string sInsertObjectIdAndVersion;
			string sNewObjectDetails;
			string synchErrorObjID;
			string sDeletedObjVerXml;
			string errorInfoXML;

            //string sObjver;
            //MFilesWrapper.GetOnlyObjectVersions(sUsername, sPassword, sNetworkAddress, sVaultName, 1, null, null, out sObjver);
            string VaultSettings = sUsername + "," + sPassword + "," + sNetworkAddress + "," + sVaultName;
			MFilesWrapper.CreateNewObject(VaultSettings, sXmlFile, sObjVerXml, sPropertyIds, iUpdateMethod, dtModifieDateTime, null, out sInsertObjectIdAndVersion
				, out sNewObjectDetails, out synchErrorObjID, out sDeletedObjVerXml, out errorInfoXML);


		}
	}
}
