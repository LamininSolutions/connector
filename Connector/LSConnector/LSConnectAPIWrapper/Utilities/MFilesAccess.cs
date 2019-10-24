using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using LSConnect.Entities;
using LSConnect.Utilities;
using MFilesAPI;
using DataSet = MFilesAPI.DataSet;
using System.IO;
using System.Security.Cryptography;
////using System.Linq;

namespace LSConnect.MFiles
{
    /// <summary>
    /// This class has all the MFiles related operations
    /// </summary>
    /// 
    public static class AssociatedPropertyDefsExtensionMethods
    {
        public static AssociatedPropertyDefs PopulateFrom(this AssociatedPropertyDefs output, AssociatedPropertyDefs input)
        {
            // Sanity.
            output = output ?? new AssociatedPropertyDefs();
            if (null == input)
                return output;

            // Iterate over the input values.
            foreach (var propertyDef in input.Cast<IAssociatedPropertyDef>())
            {
                // If it's a built-in one then skip it (unless it's name or title!).
                if (propertyDef.PropertyDef < 1000
                    && propertyDef.PropertyDef != (int)MFBuiltInPropertyDef.MFBuiltInPropertyDefNameOrTitle)
                {
                    continue;
                }

                // Add the property to the list (add them all at index zero to ensure order is correct).
                output.Add(0, new AssociatedPropertyDef()
                {
                    PropertyDef = propertyDef.PropertyDef, // The id of the property that's referenced.
                    Required = propertyDef.Required // Whether it's required.
                });
            }

            // Return for chaining.
            return output;
        }
    }
    public class MFilesAccess
    {
       

        /// <summary>
        /// vault object reference
        /// </summary>
        private Vault vault;

        /// <summary>
        /// vault connection info
        /// </summary>
        private VaultConnectionInfo vaultConnInfo;

        /// <summary>
        /// bool indicates vault connected or not
        /// </summary>
        private bool isVaultConnected = false;

        private List<ObjVer> createdObjects = new List<ObjVer>();

        private SetPropertiesParamsOfMultipleObjects propertyParamsOfMultipleObjects = new SetPropertiesParamsOfMultipleObjects();

        /// <summary>
        /// Constructor initializes the vault connection info. 
        /// Connects to vault and sets vault object reference.
        /// Also sets the boolean whether vault connected or not
        /// </summary>
        /// <param name="userName">login name to connect to vault</param>
        /// <param name="password">password to connect to vault</param>
        /// <param name="networkAddress"></param>
        /// <param name="vaultName"></param>
        public MFilesAccess(string userName, string password, string networkAddress, string vaultName)
        {
            ConfigUtil config = new ConfigUtil();
            if (userName != null && password != null && networkAddress != null && vaultName != null)
            {
                string decryptedPassword = password;
                Laminin.CryptoEngine.Decrypt(password, out decryptedPassword);
                // this.vaultConnInfo = config.ReadMFilesConectionInfo(userName, decryptedPassword, networkAddress, vaultName);
                bool isVltConnected = false;
                this.vault = ConnectToVault(vaultConnInfo, ref isVltConnected);
                this.isVaultConnected = isVltConnected;
            }
            else
            {
                throw new Exception("Please Enter all required Credentials");
            }

        }


        public MFilesAccess(string VaultSettings)
        {
            string[] Settings = VaultSettings.Split(',');  //Spliting Vault settings vaule by ',' and store into string array.
            string userName = Settings[0];
            string password = Settings[1];
            string networkAddress = Settings[2];
            string vaultName = Settings[3];
            string Protocol = Settings[4];
            string EndPoint = Settings[5];
            string UserType = Settings[6];
            string Domain = Settings[7];

            ConfigUtil config = new ConfigUtil();
            if (userName != null && password != null && networkAddress != null && vaultName != null && Protocol != null && EndPoint != null && UserType != null && Domain != null)
            {
                string decryptedPassword = password;
                if (UserType == "3" || UserType=="2") Laminin.CryptoEngine.Decrypt(password, out decryptedPassword);
                this.vaultConnInfo = config.ReadMFilesConectionInfo(userName, decryptedPassword, networkAddress, vaultName, Protocol, EndPoint, UserType, Domain);
                bool isVltConnected = false;
                this.vault = ConnectToVault(LoadVaultInfoByAuthenticationType(vaultConnInfo), ref isVltConnected);
                this.isVaultConnected = isVltConnected;
            }
            else
            {
                throw new Exception("Please Enter all required Credentials");
            }

        }

        public void LogOut()
        {
            if(this.vault!=null)
            { 
            this.vault.LogOutSilent();
            }
        }
        private VaultConnectionInfo LoadVaultInfoByAuthenticationType(VaultConnectionInfo vaultConnInfo)
        {
            switch (vaultConnInfo.UserType)
            {
                case 1:
                    //when UserType=1 it means current windows user is trying to connect vault at that we have to pass only usertype and vault name
                    //and rest of all vault connection properties we are settings to  nothing in this case.
                    vaultConnInfo.UserName = string.Empty;
                    vaultConnInfo.Password = string.Empty;
                    vaultConnInfo.Domain = string.Empty;
                    vaultConnInfo.Protocol = string.Empty;
                    vaultConnInfo.NetworkAddress = string.Empty;
                    vaultConnInfo.Endpoint = string.Empty;
                    break;
                case 2:
                    //When user UserType=2 it means specific windows user is trying connect to the vault at that we don't required protocol and endpoint settins.
                    vaultConnInfo.Protocol = string.Empty;
                    vaultConnInfo.Endpoint = string.Empty;
                    //vaultConnInfo.Domain = string.Empty;
                    //vaultConnInfo.NetworkAddress = string.Empty; Commented for task 1121
                    break;
                case 3:
                    //When user UserType=3 it means m-file user is trying connect to the vault .
                    vaultConnInfo.Domain = string.Empty;
                    break;

            }
            return vaultConnInfo;
        }

        /// <summary>
        /// bool indicates vault connected or not
        /// </summary>
        public bool IsVaultConnected
        {
            get
            {
                return isVaultConnected;
            }
        }

        #region Connect To MFiles Server
        /// <summary>
        /// Function used to connect to MFiles Vault
        /// </summary>
        /// <param name="vltConnInfo">MFiles Properties</param>
        /// <returns>Vault Object</returns>        
        private Vault ConnectToVault(VaultConnectionInfo vltConnInfo, ref bool isVltConnected)
        {
            Vault oVault = null;
            try
            {
                
                //Create the server component.
                MFilesServerApplication oServerApp = new MFilesServerApplication();
                //Connect to M-Files server computer "mfserv" by using M-Files user's credentials.
                oServerApp.Connect((MFAuthType)vltConnInfo.UserType, vltConnInfo.UserName, vltConnInfo.Password,
                    vltConnInfo.Domain, vltConnInfo.Protocol, vltConnInfo.NetworkAddress, vltConnInfo.Endpoint, vltConnInfo.LocalComputerName,
                    vltConnInfo.AllowAnonymous);
                //Get and loop through all vaults.
                VaultsOnServer oVaultsOnServer = oServerApp.GetVaults();

                foreach (VaultOnServer vault in oVaultsOnServer)
                {
                    if (String.Compare(vault.Name, vltConnInfo.VaultName, true) == 0)
                    {
                        oVault = vault.LogIn();
                        isVltConnected = oVault != null ? true : false;

                        break;
                    }
                }

                if (oVault == null)
                {
                    throw new Exception("The vault does not exists in this server.Please check the vault name.");
                }
            }
            catch (Exception ex)
            {
                string message = "The User {0} not exists in vault {1}";
                string errorMsg = string.Format(message, vltConnInfo.UserName, vltConnInfo.VaultName);
                //throw new Exception(errorMsg);
                throw;
            }
            return oVault;
        }
        #endregion

        #region Validate Required Fields
        public List<String> ValidateRequiredFields(List<ObjectInfo> objectInfoList)
        {
            List<String> missingRequiredFields = new List<String>();
            try
            {
                foreach (ObjectInfo objInfo in objectInfoList)
                {
                    ObjectClass objectClass = vault.ClassOperations.GetObjectClass(objInfo.ClassInfo.Id);
                    AssociatedPropertyDef origPropertyDef = new AssociatedPropertyDef();
                    ValidateRequiredFields(ref missingRequiredFields, objInfo, objectClass);
                }
            }
            catch (Exception)
            {
                throw;
            }
            return missingRequiredFields;
        }

        private void ValidateRequiredFields(ref List<String> missingRequiredFields,
            ObjectInfo objInfo, ObjectClass objectClass)
        {
            for (int i = 1; i <= objectClass.AssociatedPropertyDefs.Count; i++)
            {
                if (objectClass.AssociatedPropertyDefs[i].Required)
                {
                    PropertyDef propertyDef = vault.PropertyDefOperations.GetPropertyDef(
                        objectClass.AssociatedPropertyDefs[i].PropertyDef);
                    CheckPropertyExists(ref missingRequiredFields, objInfo, propertyDef);
                }
            }
        }

        private void CheckPropertyExists(ref List<String> missingRequiredFields,
            ObjectInfo objInfo, PropertyDef propertyDef)
        {
            int propertyID = propertyDef.ID;
            if ((!propertyDef.Predefined) &&
                (propertyDef.AutomaticValueType == MFAutomaticValueType.MFAutomaticValueTypeNone))
            {
                if (!objInfo.PropertyCollection.HasItem(propertyID))
                {
                    missingRequiredFields.Add(
                        GetMissingFieldMessage(objInfo, propertyID));
                }
            }
        }

        public void GetExternalProperties(ObjectClass objectClass, ref List<int> externalPptId)
        {
            for (int i = 1; i <= objectClass.AssociatedPropertyDefs.Count; i++)
            {

                if (objectClass.AssociatedPropertyDefs[i].PropertyDef > 999)
                {
                    externalPptId.Add(objectClass.AssociatedPropertyDefs[i].PropertyDef);
                }
            }
            if (!externalPptId.Contains(objectClass.NamePropertyDef))
            {
                externalPptId.Add(objectClass.NamePropertyDef);
            }
        }
        private string GetMissingFieldMessage(ObjectInfo objInfo, int propertyID)
        {
            return "The required field is missing for "
                        + " Class id " + objInfo.ClassInfo.Id
                        + " Class Name " + GetClassName(objInfo.Id)
                        + " Property id " + propertyID
                        + " Property Name " + GetPropertyName(propertyID);
        }
        #endregion

        #region Get Value List Items

        /// <summary>
        /// Function used to get the Value List Items
        /// </summary>
        /// <param name="valueListPropertyId">Vault List Property Id</param>
        /// <returns>Dictionary<String,String/></returns>
        private Dictionary<String, String> GetValueListItemsById(int valueListPropertyId)
        {
            Dictionary<String, String> listItems = new Dictionary<String, String>();
            ValueListItems valueListItems = vault.ValueListItemOperations.GetValueListItems(valueListPropertyId, true, MFExternalDBRefreshType.MFExternalDBRefreshTypeNone);
            foreach (ValueListItem item in valueListItems)
            {
                if (!listItems.ContainsKey(item.Name))
                {
                    listItems.Add(item.Name, Convert.ToString(item.ID));
                }
            }
            return listItems;
        }
        #endregion

        #region Set Search Condition
        /// <summary>
        /// Function used to set the search condition for the specified object id.
        /// </summary>
        /// <param name="objectId">objectId</param>
        /// <returns>SearchConditions Object</returns>
        private SearchConditions SetSearchCondition(int objectId)
        {
            // Create a search conditions for the object name.
            SearchConditions searchConditions = new SearchConditions();

            //Set SearchCondition for object type
            SearchCondition searchCondition = new SearchCondition();
            searchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            searchCondition.Expression.SetStatusValueExpression(MFStatusType.MFStatusTypeObjectTypeID);
            searchCondition.TypedValue.SetValue(MFDataType.MFDatatypeLookup, objectId);
            searchConditions.Add(-1, searchCondition);
            return searchConditions;
        }
        #endregion

        #region Get Search Results Based on Search Conditions

        /// <summary>
        /// Function used to return the search results based on the search conditions
        /// <param name="searchConditions">Search Conditions</param>
        /// <returns>ObjectSearchResults</returns>
        private ObjectSearchResults GetSearchResults(SearchConditions searchConditions)
        {
            ObjectSearchResults objectSearchResults = vault.ObjectSearchOperations.SearchForObjectsByConditions(searchConditions, MFSearchFlags.MFSearchFlagNone, false);
            return objectSearchResults;
        }
        #endregion


        #region Get Object Version And its Properties

        /// <summary>
        /// Function used to get the object version and properties
        /// <param name="objID">ObjID</param>
        /// <returns>ObjectVersionAndProperties</returns>
        public ObjectVersionAndProperties GetObjectVersionAndProperties(ObjVer objVer, ref ObjID objID)
        {
            objID = objVer.ObjID;
            ObjectVersionAndProperties objVerAndProps = vault.ObjectOperations.GetLatestObjectVersionAndProperties(objID, true);
            return objVerAndProps;
        }
        #endregion

        #region Get Property Value
        /// <summary>
        /// Function used to return the property value based on the Property Id Passed
        /// </summary>
        /// <param name="oResult">ObjectVersionAndProperties</param>
        /// <param name="propertyId">Property Id</param>
        /// <returns>String</returns>
        private string GetPropertyValue(ObjectVersionAndProperties oResult, int propertyId)
        {
            string propertyValueResult = string.Empty;
            try
            {
                if (oResult.Properties.SearchForProperty(propertyId) != null)
                {
                    propertyValueResult = oResult.Properties.SearchForProperty(propertyId).Value.DisplayValue;
                }
            }
            catch (Exception)
            {
                //Property Does not exist in the wordorder
                throw;
            }
            return propertyValueResult;
        }

        public string GetPropertyName(int propertyId)
        {
            string propertyValueResult = string.Empty;
            try
            {
                if (vault.PropertyDefOperations.GetPropertyDef(propertyId) != null)
                {
                    propertyValueResult = vault.PropertyDefOperations.GetPropertyDef(propertyId).Name;
                }
            }
            catch (Exception)
            {
                //Property Does not exist in the wordorder               
                throw;
            }
            return propertyValueResult;
        }


        /// <summary>
        /// Function used to return the property value of the look up
        /// </summary>
        /// <param name="oResult">ObjectVersionAndProperties</param>
        /// <param name="propertyId">Property Id</param>
        /// <returns>Int</returns>
        private int GetPropertyID(ObjectVersionAndProperties oResult, int propertyId)
        {
            int propertyValueResult = 0;
            try
            {
                if (oResult.Properties.SearchForProperty(propertyId) != null)
                {
                    propertyValueResult = oResult.Properties.SearchForProperty(propertyId).Value.GetLookupID();
                }
            }
            catch (Exception)
            {
                //Property Does not exist in the wordorder              
                throw;
            }
            return propertyValueResult;
        }

        public object GetDataValueBasedOnDataType(int propertyID,MFDataType dataType, object propertyValue)
        {
           if(propertyValue  != null)
           {
               if (dataType == MFDataType.MFDatatypeText)
                   return propertyValue;
               if (dataType == MFDataType.MFDatatypeInteger)
                   return Convert.ToInt32(propertyValue);
               if (dataType == MFDataType.MFDatatypeFloating)
                   return Convert.ToDouble(propertyValue);
               if (dataType == MFDataType.MFDatatypeDate)
                   return GetDateTime(propertyValue);
               if (dataType == MFDataType.MFDatatypeBoolean)
                   return GetBoolean(propertyValue);
               if (dataType == MFDataType.MFDatatypeLookup)
                   return Convert.ToInt32(propertyValue);
               if (dataType == MFDataType.MFDatatypeMultiSelectLookup)
                   return Convert.ToInt32(propertyValue);
               if (dataType == MFDataType.MFDatatypeMultiLineText)
                   return Convert.ToString(propertyValue);
           }
            else
            {

                if (dataType == MFDataType.MFDatatypeBoolean)
                {
                    return GetBoolean(propertyValue);
                }


            }
             return propertyValue;
        }

        private DateTime GetDateTime(object val)
        {
            DateTime toRet = DateTime.MinValue;
            if (val == null || string.IsNullOrEmpty((string)val))
            {
                toRet = DateTime.MinValue;
            }
            else
            {
                string[] dateParts = ((string)val).Split(new char[] { '/', '-', '.' });
                toRet = new DateTime(
                    Convert.ToInt32(dateParts[0]),
                    Convert.ToInt32(dateParts[1]),
                    Convert.ToInt32(dateParts[2]));
            }
            return toRet;
        }

        public bool GetBoolean(object val)
        {
            bool toRet = false;
            if (val == null || string.IsNullOrEmpty((string)val))
            {
                toRet = false;

            }
            else
            {
                string strVal = ((string)val).ToLower().Trim();
                if (strVal == "yes" || strVal == "1")
                {
                    toRet = true;
                }
                else if (strVal == "no" || strVal == "0")
                {
                    toRet = false;
                }
                else
                {
                    toRet = Convert.ToBoolean(strVal);
                }
            }

            return toRet;
        }

        private MFDataType GetPropertyDataType(int propertyID)
        {
            try
            {
                if (vault.PropertyDefOperations.GetPropertyDef(propertyID) != null)
                {
                    return vault.PropertyDefOperations.GetPropertyDef(propertyID).DataType;
                }
                else
                {
                    throw new Exception("Property Does Not Exist In MFiles");
                }
            }
            catch (Exception)
            {
                throw new Exception("Property Does Not Exist In MFiles");
            }
        }
        #endregion

        #region Dynamically Setting the Properties Values
        private void SetProperties(XMLClass.ClassDetails propertyList, ref PropertyValues propertyValues,
            List<int> propIdsToExclude)
        {
            List<int> propertiesToExclude
                = propIdsToExclude != null ? propIdsToExclude : new List<int>();
            foreach (XMLClass.PropertyDetails property in propertyList.property)
            {
                if (!propertiesToExclude.Contains(property.id))
                {
                    PropertyValue propertyValue = new PropertyValue();
                    propertyValue.PropertyDef = property.id;
                    
                    //MFDataType pptDataType = vault.PropertyDefOperations.GetPropertyDef(property.Id).DataType;   //Performance test
                    MFDataType pptDataType = GetMFDataType(property.dataType);
                    if (pptDataType == MFDataType.MFDatatypeMultiSelectLookup)
                    {
                        SetLookupPropertyValue(property, ref propertyValue);
                    }
                    else
                    {
                        SetPropertyValue(property, ref propertyValue);
                    }
                    propertyValues.Add(-1, propertyValue);
                }
            }
        }

        private void SetProperties(XMLClass.ClassDetails propertyList, ref PropertyValues propertyValues)
        {
            SetProperties(propertyList, ref propertyValues, null);
        }

        private void SetLookupPropertyValue(XMLClass.PropertyDetails property,
            ref PropertyValue propertyValue)
        {
            //MFDataType mfDataType = GetPropertyDataType(property.Id); //Performance test
            MFDataType mfDataType = GetMFDataType(property.dataType);
            if (mfDataType != MFDataType.MFDatatypeMultiSelectLookup)
            {
                SetSingleSelectLookupValue(property, ref propertyValue);
            }
            else
            {
                SetMultiSelectLookupValue(property, ref propertyValue);
            }
        }

        private void SetPropertyValue(XMLClass.PropertyDetails property,
            ref PropertyValue propertyValue)
        {
            propertyValue.TypedValue.SetValue(GetMFDataType(property.dataType),
                             GetDataValueBasedOnDataType(property.id,GetMFDataType(property.dataType), property.Value));
        }

        private MFDataType GetMFDataType(int dataTypeID)
        {
            MFDataType dataType = new MFDataType();
            switch (dataTypeID)
            {
                case 0:
                    dataType = MFDataType.MFDatatypeUninitialized;
                    break;
                case 1:
                    dataType = MFDataType.MFDatatypeText;
                    break;
                case 2:
                    dataType = MFDataType.MFDatatypeInteger;
                    break;
                case 3:
                    dataType = MFDataType.MFDatatypeFloating;
                    break;
                case 5:
                    dataType = MFDataType.MFDatatypeDate;
                    break;
                case 6:
                    dataType = MFDataType.MFDatatypeTime;
                    break;
                case 7:
                    dataType = MFDataType.MFDatatypeTimestamp;
                    break;
                case 8:
                    dataType = MFDataType.MFDatatypeBoolean;
                    break;
                case 9:
                    dataType = MFDataType.MFDatatypeLookup;
                    break;
                case 10:
                    dataType = MFDataType.MFDatatypeMultiSelectLookup;
                    break;
                case 11:
                    dataType = MFDataType.MFDatatypeInteger64;
                    break;
                case 12:
                    dataType = MFDataType.MFDatatypeFILETIME;
                    break;
                case 13:
                    dataType = MFDataType.MFDatatypeMultiLineText;
                    break;
                case 14:
                    dataType = MFDataType.MFDatatypeACL;
                    break;
                default:
                    throw new Exception("Invalid DataType");
            }
            return dataType;

        }

        private static void SetMultiSelectLookupValue(XMLClass.PropertyDetails property,
            ref PropertyValue propertyValue)
        {
            string ids = property.Value;
            if (!string.IsNullOrEmpty(ids))
            {
                Lookups lookUps = new Lookups();
                string[] values = ids.Split(new string[] { "," }, StringSplitOptions.None);
                foreach (var lookupItem in values)
                {
                    if (!string.IsNullOrEmpty(lookupItem))
                    {
                        Lookup lookUp = new Lookup();
                        lookUp.Item = Convert.ToInt32(lookupItem);
                        lookUp.Version = -1;
                        lookUps.Add(-1, lookUp);
                    }
                }
                propertyValue.TypedValue.SetValueToMultiSelectLookup(lookUps);
            }
            else
            {

                propertyValue.TypedValue.SetValue(MFDataType.MFDatatypeMultiSelectLookup,null);
            }
        }

        private void SetSingleSelectLookupValue(XMLClass.PropertyDetails property,
            ref PropertyValue propertyValue)
        {
            int lookupId = property.id;
            propertyValue.TypedValue.SetValue(GetMFDataType(property.id),
                GetDataValueBasedOnDataType(property.id,GetMFDataType(property.dataType), lookupId));
        }
        #endregion

        #region Get Class Name
        /// <summary>
        /// Function to get the class name
        /// </summary>
        /// <param name="objectId"></param>
        /// <returns></returns>
        public string GetClassName(int objectId)
        {
            SearchConditions searchConditions = SetSearchCondition(objectId);
            ObjectSearchResults objectSearchResults = GetSearchResults(searchConditions);
            string className = string.Empty;
            if (objectSearchResults != null)
            {
                foreach (ObjectVersion objectWorkOrderVersion in objectSearchResults)
                {
                    ObjID objID = null;
                    ObjectVersionAndProperties objectVersionAndProperties = GetObjectVersionAndProperties(objectWorkOrderVersion.ObjVer, ref objID);
                    className = objectVersionAndProperties.Properties.SearchForProperty(100).TypedValue.DisplayValue;
                    break;
                }
            }
            return className;
        }
        #endregion

        #region Create Object

        /// <summary>
        /// Fuction to set required properties and then call the API method
        /// </summary>
        /// <param name="objInfo"></param>
        /// <param name="objVersion"></param>
        /// <param name="objectVersion"></param>
        public void CreateObject(XMLClass.ObjectDetails objInfo, ref ObjVer objVersion, ref ObjectVersion objectVersion)
        {
            try
            {
                PropertyValues propertyValues = new PropertyValues();
                SetClassProperty(objInfo, ref propertyValues);
                //Setting Dynamically the Property Values
                SetProperties(objInfo.ClassDetail, ref propertyValues);
                //SetFileProperty(ref propertyValues); --Commented by DevTeam2
                CreateNewObject(objInfo, propertyValues, ref objVersion, ref objectVersion);
            }
            catch (Exception ex)
            {
                throw new Exception("Please check the object (objID : " + objVersion.ID.ToString() + "@\n" + ex.Message);            
            }            
        }

        #endregion
        #region M-FilesVersion task 11202

        public void CreateObject(ref ObjVer ObjVersion, ref ObjectVersion objectVersion, XMLFile.FileListItem Item, String FilePath, XMLClass.ObjectDetails objInfo,ref int FileObjectID,string TempFolderPath,ref string chkSum)
        {
            try
            {
                string[] FileDetails = Item.FileName.Split('.');
                PropertyValues propertyValues = new PropertyValues();

                //Setting Class property for object
                SetClassProperty(objInfo, ref propertyValues);



                //Setting Dynamically the Property Values
                SetProperties(objInfo.ClassDetail, ref propertyValues);

                //Settings Single file property for object
                //PropertyValue propvalue = new PropertyValue();
                //propvalue.PropertyDef = (int)MFBuiltInPropertyDef.MFBuiltInPropertyDefSingleFileObject;
                //propvalue.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, true);
                //propertyValues.Add(-1, propvalue);


                ////Setting name or tile property for object.
                //PropertyValue propertyValue = new PropertyValue();
                //propertyValue.PropertyDef = 0;
                //propertyValue.TypedValue.SetValue(MFDataType.MFDatatypeText,
                //           GetDataValueBasedOnDataType(0, MFDataType.MFDatatypeText, FileDetails[0]));
                //propertyValues.Add(-1,propertyValue);


                //int iPropDef1 = vault.PropertyDefOperations.GetPropertyDefIDByAlias("FileObjectID");
                //PropertyValue PropValue = new PropertyValue();
                //PropValue.PropertyDef = iPropDef1;
                //PropValue.TypedValue.SetValue(MFDataType.MFDatatypeText,
                //           GetDataValueBasedOnDataType(0, MFDataType.MFDatatypeText, Item.ID));
                //propertyValues.Add(-1, PropValue);

                //SetFileProperty(ref propertyValues); --Commented by DevTeam2
                // CreateNewObject(objInfo, propertyValues, ref objVersion, ref objectVersion);


                SourceObjectFiles SrcObject = new SourceObjectFiles();
                SourceObjectFile ObjFile = new SourceObjectFile { Extension = FileDetails[1], Title = FileDetails[0], SourceFilePath = FilePath };
                SrcObject.Add(-1, ObjFile);


                ObjectVersionAndProperties objectVersionAndProperties
                  = vault.ObjectOperations.CreateNewObject(Item.ObjType, propertyValues, SrcObject);

                objectVersion = vault.ObjectOperations.CheckIn(objectVersionAndProperties.ObjVer);

                if (objectVersionAndProperties.ObjVer.ID > 0)
                {
                    ObjVersion = objectVersionAndProperties.ObjVer;
                    createdObjects.Add(objectVersionAndProperties.ObjVer);
                }

                ObjectFile oCheckedOutFile;
                var Files= vault.ObjectFileOperations.GetFiles(objectVersionAndProperties.ObjVer).Cast<ObjectFile>().ToArray(); ;
                oCheckedOutFile = Files[0];
                string FilePath1 = Path.Combine(TempFolderPath, FileDetails[0] + "." + FileDetails[1]);
                DownloadFile(oCheckedOutFile.FileVer.ID, oCheckedOutFile.FileVer.Version, FilePath1);
                chkSum = GetFileChecksum(FilePath1, new MD5CryptoServiceProvider());
                System.IO.File.Delete(FilePath1);
                FileObjectID = oCheckedOutFile.FileVer.ID;

            }
            catch (Exception ex)
            {
                throw new Exception("Please check the object (objID : " + ObjVersion.ID.ToString() + "@\n" + ex.Message);
            }
        }

        #region UpdateImportFileObject

        public void UpdateImportFileObject(ref ObjVer objVers, ref ObjectVersion objectVersion, string FileName, String FilePath, XMLClass.ObjectDetails objInfo, ref int FileObjectID, string FileCheckSum, string TempFolderPath, ref string FChkSum)
        {

            string[] FileDetails = FileName.Split('.');
            PropertyValues propertyValues = new PropertyValues();
            SetClassProperty(objInfo, ref propertyValues);
            //Setting Dynamically the Property Values
            SetProperties(objInfo.ClassDetail, ref propertyValues);
            // SetFileProperty(ref propertyValues); --Commented by DevTeam2

            //AllowCheckOut = True and UpdateFromServer = true
            objVers = vault.ObjectOperations.GetLatestObjVer(objVers.ObjID, true, true);
            ObjectVersionAndProperties objVerAndProp = vault.ObjectOperations.GetLatestObjectVersionAndProperties(objVers.ObjID, true, true);

            //Check the CheckOut Status of the object
            if (!objVerAndProp.VersionData.ObjectCheckedOut && !objVerAndProp.VersionData.Deleted)
            {
                if (objVerAndProp.VersionData.SingleFile)
                {



                    ObjectFiles oCheckedOutFiles;
                    ObjectFile oCheckedOutFile;
                    oCheckedOutFiles = vault.ObjectFileOperations.GetFiles(objVers);
                    oCheckedOutFile = oCheckedOutFiles[1];

                    //Getting the File
                    var files = vault.ObjectFileOperations.GetFiles(objVers).Cast<ObjectFile>().ToArray();
                    var fileToUpdate = files[0];
                    string TempFilePath = Path.Combine(TempFolderPath, fileToUpdate.Title + "." + fileToUpdate.Extension);
                    DownloadFile(files[0].FileVer.ID, files[0].FileVer.Version, TempFilePath);

                    string TempFileCheckSum = GetFileChecksum(TempFilePath, new MD5CryptoServiceProvider());
                    FileObjectID = files[0].ID;
                    //if (fileToUpdate.Title == FileDetails[0]) //if document is single file and file name is same then overright file
                    if (fileToUpdate.Title == FileDetails[0])
                    {
                        if (TempFileCheckSum != FileCheckSum)
                        {
                            try
                            {
                                objVers = vault.ObjectOperations.CheckOut(objVers.ObjID).ObjVer;
                                ObjectVersionAndProperties objectVersionAndProperties
                                   = vault.ObjectPropertyOperations.SetAllProperties(objVers, true, propertyValues);
                                // Set to MFD (as we are removing a file, it will have zero files so is no longer a single-file-document).
                                vault.ObjectOperations.SetSingleFileObject(objVers, false);

                                // Remove the old one.
                                vault.ObjectFileOperations.RemoveFile(objVers, fileToUpdate.FileVer);

                                // Add the new one.
                                var File_Ver = vault.ObjectFileOperations.AddFile(objVers, FileDetails[0], FileDetails[1], FilePath);
                                FileObjectID = File_Ver.ID;
                                vault.ObjectOperations.SetSingleFileObject(objVers, true);
                                objectVersion = vault.ObjectOperations.CheckIn(objectVersionAndProperties.ObjVer);
                            }
                            catch (Exception ex)
                            {
                                objectVersion = vault.ObjectOperations.CheckIn(objVers);
                                throw ex;
                            }
                        }
                    }
                    else
                    {
                        try
                        {
                            objVers = vault.ObjectOperations.CheckOut(objVers.ObjID).ObjVer;
                            ObjectVersionAndProperties objectVersionAndProperties
                          = vault.ObjectPropertyOperations.SetAllProperties(objVers, true, propertyValues);
                            //if objet is single file name current and new file name is different then just change object to multifile document and add file to it
                            // Set to MFD (as we are removing a file, it will have zero files so is no longer a single-file-document).
                            vault.ObjectOperations.SetSingleFileObject(objVers, false);
                            var File_Ver = vault.ObjectFileOperations.AddFile(objVers, FileDetails[0], FileDetails[1], FilePath);
                            //string TempFilePath1 = Path.Combine(TempFolderPath, FileDetails[0] + "." + FileDetails[1]);
                            //DownloadFile(File_Ver.ID, File_Ver.Version, TempFilePath1);
                            //FChkSum = GetFileChecksum(TempFilePath1, new MD5CryptoServiceProvider());
                            //System.IO.File.Delete(TempFilePath1);
                            FileObjectID = File_Ver.ID;
                            objectVersion = vault.ObjectOperations.CheckIn(objectVersionAndProperties.ObjVer);
                        }
                        catch (Exception ex)
                        {
                            objectVersion = vault.ObjectOperations.CheckIn(objVers);
                            throw ex;
                        }
                    }
                }
                else
                {
                    try
                    {
                        Boolean IsAddFile = true;
                        Boolean IsRemoved = false;
                        var files = vault.ObjectFileOperations.GetFiles(objVers).Cast<ObjectFile>().ToArray();
                        foreach (ObjectFile OF in files)
                        {
                            if (OF.Title == FileDetails[0])
                            {
                                string TempFilePath = Path.Combine(TempFolderPath, OF.Title + "." + OF.Extension);
                                DownloadFile(OF.FileVer.ID, OF.FileVer.Version, TempFilePath);
                                string TempFileCheckSum = GetFileChecksum(TempFilePath, new MD5CryptoServiceProvider());
                                System.IO.File.Delete(TempFilePath);
                                if (FileCheckSum == TempFileCheckSum)
                                {
                                    IsAddFile = false;
                                    FChkSum = FileCheckSum;
                                }
                                else
                                {
                                    // Remove the old one.
                                    objVers = vault.ObjectOperations.CheckOut(objVers.ObjID).ObjVer;
                                    vault.ObjectFileOperations.RemoveFile(objVers, OF.FileVer);
                                    IsRemoved = true;
                                }
                            }
                        }

                        if (IsAddFile)
                        {

                            //IF file document is multifile document the add file into it
                            if (!IsRemoved) objVers = vault.ObjectOperations.CheckOut(objVers.ObjID).ObjVer;
                            ObjectVersionAndProperties objectVersionAndProperties
                                = vault.ObjectPropertyOperations.SetAllProperties(objVers, true, propertyValues);
                            var FileVer = vault.ObjectFileOperations.AddFile(objVers, FileDetails[0], FileDetails[1], FilePath);
                            FileObjectID = FileVer.ID;
                            if (objectVersionAndProperties.VersionData.FilesCount <= 1) vault.ObjectOperations.SetSingleFileObject(objVers, true); // 2nd may 2018
                            objectVersion = vault.ObjectOperations.CheckIn(objectVersionAndProperties.ObjVer);
                            FChkSum = FileCheckSum;
                        }
                    }
                    catch (Exception ex)
                    {
                        objectVersion = vault.ObjectOperations.CheckIn(objVers);
                        throw ex;
                    }
                }

            }
            //Added Rheal for task #1368
            else if (objVerAndProp.VersionData.ObjectCheckedOut) throw new Exception(objVerAndProp.ObjVer.ObjID.ID.ToString()+" Object Already CheckedOut");             

        }
        #endregion  1202

        public void GetMFilesVersion(ref string MFilesVersion)
        {
            MFilesVersion = string.Empty;
            MFilesVersion MFVer= vault.GetServerVersionOfVault();
            MFilesVersion = MFVer.Display;
        }

        public void UpdateObject(XMLClass.ObjectDetails objInfo, ref ObjVer objVers, ref ObjectVersion checkedInObjectVersion, ref DataTable dtDeleted)
        {
            PropertyValues propertyValues = new PropertyValues();
            SetClassProperty(objInfo, ref propertyValues);
            //Setting Dynamically the Property Values
            SetProperties(objInfo.ClassDetail, ref propertyValues);
            // SetFileProperty(ref propertyValues); --Commented by DevTeam2

            //AllowCheckOut = True and UpdateFromServer = true
            objVers = vault.ObjectOperations.GetLatestObjVer(objVers.ObjID, true, true);
            ObjectVersionAndProperties objVerAndProp = vault.ObjectOperations.GetLatestObjectVersionAndProperties(objVers.ObjID, true, true);

            //Check the CheckOut Status of the object
            if (!objVerAndProp.VersionData.ObjectCheckedOut && !objVerAndProp.VersionData.Deleted)
            {
                UpdateObjects(objInfo, propertyValues, ref objVers, ref checkedInObjectVersion);
            }
            else if (objVerAndProp.VersionData.Deleted)
            {
                dtDeleted.Rows.Add(objVers.ID.ToString(), objVers.Version.ToString());
            }
           
        }

        /// <summary>
        /// API method to update an  existing object
        /// </summary>
        /// <param name="objInfo"></param>
        /// <param name="propertyValues"></param>
        /// <param name="objVers"></param>
        /// <param name="checkedInObjectVersion"></param>
        private void UpdateObjects(XMLClass.ObjectDetails objInfo, PropertyValues propertyValues, ref ObjVer objVers, ref ObjectVersion checkedInObjectVersion)
        {
            try
            {
                objVers = vault.ObjectOperations.CheckOut(objVers.ObjID).ObjVer;
                ObjectVersionAndProperties objectVersionAndProperties
                    = vault.ObjectPropertyOperations.SetAllProperties(objVers, true, propertyValues);

                //Added below code for update modified_by,modified_date,Create_date and Created_by in  the m-files 05/09/2019

                vault.ObjectPropertyOperations.SetLastModificationInfoAdmin(objVers, true, propertyValues.SearchForProperty(23).TypedValue, true, propertyValues.SearchForProperty(21).TypedValue);

                vault.ObjectPropertyOperations.SetCreationInfoAdmin(objVers, true, propertyValues.SearchForProperty(25).TypedValue, true, propertyValues.SearchForProperty(20).TypedValue);

                checkedInObjectVersion = vault.ObjectOperations.CheckIn(objectVersionAndProperties.ObjVer);
                try
                {
                    if (!string.IsNullOrEmpty(objInfo.DisplayID)) //Added by rheal for task 1097
                    {
                        if (checkedInObjectVersion.DisplayIDAvailable && checkedInObjectVersion.DisplayID != objInfo.DisplayID) //Added by rheal for task 1097
                            vault.ObjectOperations.SetExternalID(objVers.ObjID, objInfo.DisplayID); //Added by Rheal to set externalID for Task 988
                    }
                }
                catch(Exception ex)
                {
                    throw new Exception (" ExternalID= "+objInfo.DisplayID+"  "+ ex.Message); //Added by rheal for task 1097
                }


                if (objectVersionAndProperties.ObjVer.ID > 0)
                {
                    objVers = objectVersionAndProperties.ObjVer;
                    createdObjects.Add(objectVersionAndProperties.ObjVer);
                }
            }
            catch (Exception ex)
            {
                vault.ObjectOperations.CheckIn(objVers);
                throw new Exception("Please check the object (objID : " + objVers.ID.ToString() + "\n " + ex.Message);
            }
            
        }

        public void BulkUpdateObjects()
        {
            ObjectVersionAndPropertiesOfMultipleObjects m= vault.ObjectPropertyOperations.SetPropertiesOfMultipleObjects(propertyParamsOfMultipleObjects);
        }
        /// <summary>
        /// Function to create new object
        /// </summary>
        /// <param name="objInfo"></param>
        /// <param name="propertyValues"></param>
        /// <param name="objVersion"></param>
        /// <param name="objectVersion"></param>
        private void CreateNewObject(XMLClass.ObjectDetails objInfo, PropertyValues propertyValues, ref ObjVer objVersion, ref ObjectVersion objectVersion)
        {
            try
            {
                ObjectVersionAndProperties objectVersionAndProperties
                    = vault.ObjectOperations.CreateNewObject(objInfo.id, propertyValues);
                try
                {
                    if (!string.IsNullOrEmpty(objInfo.DisplayID))
                        vault.ObjectOperations.SetExternalID(objectVersionAndProperties.ObjVer.ObjID, objInfo.DisplayID);
                }
                catch (Exception ex)
                {
                    throw new Exception(" ExternalID=" + objInfo.DisplayID + "  "+ ex.Message); //Added by rheal for task 1097
                }

            objectVersion = vault.ObjectOperations.CheckIn(objectVersionAndProperties.ObjVer);

                if (objectVersionAndProperties.ObjVer.ID > 0)
                {
                    objVersion = objectVersionAndProperties.ObjVer;
                    createdObjects.Add(objectVersionAndProperties.ObjVer);
                }
            }
            catch(Exception ex)
            {
                throw new Exception("Please check the object (objID : " + objVersion.ID.ToString() + "  \n " + ex.Message);
            }
        }

        /// <summary>
        /// function to set file property of an object
        /// </summary>
        /// <param name="propertyValues"></param>
        private static void SetFileProperty(ref PropertyValues propertyValues)
        {
            PropertyValue propertyValue = new PropertyValue();
            //Setting Single File Property To False          
            propertyValue.PropertyDef = (int)MFBuiltInPropertyDef.MFBuiltInPropertyDefSingleFileObject;
            propertyValue.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, false);
            propertyValues.Add(-1, propertyValue);
        }
       
        private static void SetClassProperty(XMLClass.ObjectDetails objInfo,
            ref PropertyValues propertyValues)
        {
            PropertyValue propertyValue = new PropertyValue();
            //Set Case Class Id 
            propertyValue.PropertyDef = (int)MFBuiltInPropertyDef.MFBuiltInPropertyDefClass;
            propertyValue.TypedValue.SetValue(MFDataType.MFDatatypeLookup, objInfo.ClassDetail.id);
            propertyValues.Add(-1, propertyValue);
        }
        #endregion 

        #region Delete Object
        /// <summary>
        /// API method to destroy an Object
        /// </summary>
        /// <param name="objID"></param>
        public string DeleteObject(ObjID objID, bool DeleteWithDestroy,int ObjectVersion)
        {
            int status;
            string msg = "";
            if (DeleteWithDestroy == true && ObjectVersion == 0)
            {
                vault.ObjectOperations.DestroyObject(objID, true, -1);
                status = 3;
                msg = "Success object deleted";
            }
            else if (DeleteWithDestroy == true && ObjectVersion > 0)
            {
                vault.ObjectOperations.DestroyObject(objID, false, ObjectVersion);
                status = 2;
                msg = "Success object version destroyed";
            }
            else
            {
                vault.ObjectOperations.DeleteObject(objID);
                status = 1;
                msg = "Success object deleted";
            }
            return MFilesWrapper.CreateDeleteObjXML(objID.ID, ObjectVersion, status,msg);

        }
        #endregion

        #region Properties
        /// <summary>
        /// API method To Get All Properties in the Seleted Vault
        /// </summary>
        /// <returns></returns>
        public List<PropertyDef> GetAllProperties()
        {
            var properties = vault.PropertyDefOperations.GetPropertyDefs();

            List<PropertyDef> propertyList = new List<PropertyDef>();

            foreach (PropertyDef ppt in properties)
            {
                PropertyDef property = new PropertyDef();
                property.ID = ppt.ID;
                property.Name = ppt.Name;
                property.DataType = ppt.DataType;
                property.ValueList = ppt.ValueList;
                property.ObjectType = ppt.ObjectType;
                propertyList.Add(property);
            }

            return propertyList;
        }

        /// <summary>
        /// API method To Get Details of a Specific Properties
        /// </summary>
        /// <param name="sPropertiesId"></param>
        /// <returns></returns>
        public List<PropertyDef> GetProperties(string sPropertiesId)
        {
            string[] ids = sPropertiesId.Split(new string[] { "," }, StringSplitOptions.None);

            return ids.Select(propertyId => vault.PropertyDefOperations.GetPropertyDef(Convert.ToInt16(propertyId))).ToList();
        }

        public PropertyDef GetPropertyDef(int propertyId)
        {
            return vault.PropertyDefOperations.GetPropertyDef(propertyId); ;
        }

        /// <summary>
        /// API method to Get property details
        /// </summary>
        /// <param name="iPropertyId"></param>
        /// <returns></returns>
        public PropertyDefAdmin GetPropertyDefAdmin(int iPropertyId)
        {
            return vault.PropertyDefOperations.GetPropertyDefAdmin(iPropertyId);
        }
        #endregion

        #region ObjectType
        /// <summary>
        /// API method To get All ObjectTypes in Selected Vault
        /// </summary>
        /// <returns></returns>
        public List<ObjType> GetAllObjectTypes()
        {
            var objectTypes = vault.ObjectTypeOperations.GetObjectTypes();

            List<ObjType> objectTypeList = new List<ObjType>();

            foreach (ObjType objectType in objectTypes)
            {
                objectTypeList.Add(objectType);
            }
            return objectTypeList;
        }

        /// <summary>
        /// API method To get details of Specific Objecttypes
        /// </summary>
        /// <param name="sObjectTypeIds"></param>
        /// <returns></returns>
        public List<ObjType> GetObjectTypes(string sObjectTypeIds)
        {
            string[] ids = sObjectTypeIds.Split(new string[] { "," }, StringSplitOptions.None);

            List<ObjType> objectTypeList = new List<ObjType>();

            foreach (var objectTypeId in ids)
            {
                var objectTypes = vault.ObjectTypeOperations.GetObjectType(Convert.ToInt16(objectTypeId));
                objectTypeList.Add(objectTypes);
            }
            return objectTypeList;
        }

        /// <summary>
        /// API method to get ObjectType details
        /// </summary>
        /// <param name="iObjectTypeId"></param>
        /// <returns></returns>
        public ObjTypeAdmin GetObjectTypeAdmin(int iObjectTypeId)
        {
            return vault.ObjectTypeOperations.GetObjectTypeAdmin(iObjectTypeId);
        }
        #endregion

        #region ValueList
        /// <summary>
        /// API Method To Get All ValueLists In selected Vault
        /// </summary>
        /// <returns></returns>
        public List<ObjType> GetAllValueLists()
        {
            var valueLists = vault.ValueListOperations.GetValueLists(); //Objtype

            List<ObjType> allValueList = new List<ObjType>();

            foreach (ObjType valueList in valueLists)
            {
                //if (valueList.RealObjectType == false)      //To distinguish objectTypes And valueList
                //{
                    allValueList.Add(valueList);
                //}
            }

            return allValueList;
        }

        /// <summary>
        /// API Method To get Details of Specific ValueList 
        /// </summary>
        /// <param name="sValueListIds"></param>
        /// <returns></returns>
        public List<ObjType> GetValueLists(string sValueListIds)
        {
            string[] ids = sValueListIds.Split(new string[] { "," }, StringSplitOptions.None);

            List<ObjType> allValueList = new List<ObjType>();

            foreach (var valueListId in ids)
            {
                var valueList = vault.ValueListOperations.GetValueList(Convert.ToInt16(valueListId)); //Objtype

                if (valueList.RealObjectType == false)      //To distinguish objectTypes And valueList
                {
                    allValueList.Add(valueList);
                }

            }
            return allValueList;
        }

        public IObjectTypeAdmin GetValueListAdmin(int valuelistID)
        {
            return vault.ValueListOperations.GetValueListAdmin(valuelistID);
        }
        /// <summary>
        /// API method To get The Value List Items of specific ValueLists
        /// </summary>
        /// <param name="sValueListIds"></param>
        /// <returns></returns>
        public List<ValueListItem> GetMFValueLists(string sValueListIds)
        {
            string[] ids = sValueListIds.Split(new string[] { "," }, StringSplitOptions.None);

            List<ValueListItem> valueListItemsList = new List<ValueListItem>();

            foreach (var valueListId in ids)
            {
                var valueListItems = vault.ValueListItemOperations.GetValueListItems(Convert.ToInt16(valueListId), false, MFExternalDBRefreshType.MFExternalDBRefreshTypeNone); //ValueListItem

                foreach (ValueListItem valueListItem in valueListItems)
                {
                    valueListItemsList.Add(valueListItem);
                }
            }
            return valueListItemsList;
        }

        public ValueListItem SaveValueListItem(ValueListItem ValueListItem, int Process_ID,string DisplayID,string ItemGUID)
        {
            ValueListItem ListItem = ValueListItem;


            switch (Process_ID)
            {

                case 1: //Add or UPdate ValuListItem
                    //if (!string.IsNullOrEmpty(DisplayID) && !string.IsNullOrEmpty(ItemGUID))
                    if (!string.IsNullOrEmpty(ItemGUID))
                    {
                        vault.ValueListItemOperations.UpdateValueListItem(ValueListItem);
                        //added by LC to check for duplicate DisplayID--if found skip update
   
                        try
                        {
                            vault.ValueListItemOperations.GetValueListItemByDisplayID(ValueListItem.ValueListID, DisplayID);
                        }
                        catch 
                        {

                            //Added by Rheal to set externalID

                            if (!string.IsNullOrEmpty(DisplayID)) 
                            {
                                var objectToAddTo = new ObjID();
                                objectToAddTo.SetIDs(ValueListItem.ValueListID, ValueListItem.ID);
                                vault.ObjectOperations.SetExternalID(objectToAddTo, DisplayID);
                                ValueListItem TempValue = vault.ValueListItemOperations.GetValueListItemByID(ValueListItem.ValueListID, ValueListItem.ID);
                                ListItem = TempValue;
                            }
                            //Added by Rheal to set externalID
                        }
                    }
                    else
                    {
                        ListItem = vault.ValueListItemOperations.AddValueListItem(ValueListItem.ValueListID, ValueListItem, true);
                        //Added by Rheal to set externalID
                        if (!string.IsNullOrEmpty(DisplayID))
                        {
                           var objectToAddTo = new ObjID();
                            objectToAddTo.SetIDs(ListItem.ValueListID, ListItem.ID);
                            vault.ObjectOperations.SetExternalID(objectToAddTo, DisplayID);
                            ValueListItem TempValue = vault.ValueListItemOperations.GetValueListItemByID(ListItem.ValueListID, ListItem.ID);
                            ListItem = TempValue;
                        }
                        //Added by Rheal to set externalID
                    }

                    break;
                case 2: //Delete ValueListItem
                    if (!string.IsNullOrEmpty(DisplayID) && !string.IsNullOrEmpty(ItemGUID) && vault.ValueListItemOperations.GetValueListItemIDByGUID(ValueListItem.ValueListID, ItemGUID, false) > -1)
                    {
                        vault.ValueListItemOperations.RemoveValueListItem(ValueListItem.ValueListID, ValueListItem.ID);
                    }
                    break;
            }

            return ListItem;
        }
        #endregion

        #region Class
        /// <summary>
        /// API Method To get Details of All Class In Selected Vault
        /// </summary>
        /// <returns></returns>
        public List<ObjectClass> GetAllClasses()
        {
            var classes = vault.ClassOperations.GetAllObjectClasses();

            List<ObjectClass> mfClassesList = new List<ObjectClass>();

            foreach (ObjectClass classDetails in classes)
            {
                mfClassesList.Add(classDetails);
            }
            return mfClassesList;
        }

        /// <summary>
        /// API method To Get Details of Specific Classes
        /// </summary>
        /// <param name="sClassIds"></param>
        /// <returns></returns>
        public List<ObjectClass> GetClasses(string sClassIds)
        {
          
            string[] ids = sClassIds.Split(new string[] { "," }, StringSplitOptions.None);


            List<ObjectClass> mfClassesList = new List<ObjectClass>();
            

            foreach (var classId in ids)
            {
                var classDetails = vault.ClassOperations.GetObjectClass(Convert.ToInt16(classId));
                mfClassesList.Add(classDetails);
            }
            return mfClassesList;

        }

        /// <summary>
        /// To Get Alias name
        /// </summary>
        /// <param name="iClassId"></param>
        /// <returns></returns>
        public ObjectClassAdmin GetClassAdmin(int iClassId)
        {
            return vault.ClassOperations.GetObjectClassAdmin(iClassId);
        }

        /// <summary>
        /// API method to get details of all class 
        /// </summary>
        /// <param name="iClassId"></param>
        /// <returns></returns>
        public ObjectClass GetClass(int iClassId)
        {
            return vault.ClassOperations.GetObjectClass(iClassId); ;
        }
        #endregion

        #region Work Flow
        /// <summary>
        /// API method To Get All Workflows in Selected Vault
        /// </summary>
        /// <returns></returns>
        public List<WorkflowAdmin> GetAllWorkflows()
        {
            var workflows = vault.WorkflowOperations.GetWorkflowsAdmin();

            List<WorkflowAdmin> mfWorkflowList = new List<WorkflowAdmin>();

            foreach (WorkflowAdmin ppt in workflows)
            {
                mfWorkflowList.Add(ppt);
            }
            return mfWorkflowList;
        }

        /// <summary>
        /// API method To Get Specific Workflows in Selected vault
        /// </summary>
        /// <param name="sWorkflowIds"></param>
        /// <returns></returns>
        public List<WorkflowAdmin> GetWorkflows(string sWorkflowIds)
        {
            string[] ids = sWorkflowIds.Split(new string[] { "," }, StringSplitOptions.None);

            List<WorkflowAdmin> mfWorkflowList = new List<WorkflowAdmin>();
            foreach (var workflowId in ids)
            {
                var workflowsDetails = vault.WorkflowOperations.GetWorkflowAdmin(Convert.ToInt16(workflowId));

                mfWorkflowList.Add(workflowsDetails);
            }
            return mfWorkflowList;
        }

        /// <summary>
        /// API method to Get workFlow states of multiple workflows
        /// </summary>
        /// <param name="sWorkflowIds"></param>
        /// <returns></returns>
        public List<States> GetAllWorkflowStates(string sWorkflowIds)
        {
            string[] ids = sWorkflowIds.Split(new string[] { "," }, StringSplitOptions.None);

            List<States> mfWorkflowList = new List<States>();

            foreach (var workflowsId in ids)
            {
                States workflowStates = vault.WorkflowOperations.GetWorkflowStates(Convert.ToInt16(workflowsId), null);

                mfWorkflowList.Add(workflowStates);
            }
            return mfWorkflowList;
        }
        #endregion

        #region User Account
        /// <summary>
        /// Used to get all user accounts from M-Files
        /// </summary>
        /// <returns></returns>
        public UserAccounts GetUserAccounts()
        {
            return vault.UserOperations.GetUserAccounts();
        }

        /// <summary>
        /// Used to get a User account from M-Files
        /// </summary>
        /// <param name="userID"></param>
        /// <returns></returns>
        public UserAccount GetUserAccount(int userID)
        {
            return vault.UserOperations.GetUserAccount(userID);
        }

        #endregion

        #region Login Account
        /// <summary>
        /// Used to get Login accounts from MFiles
        /// </summary>
        /// <returns></returns>
        public LoginAccounts GetLoginAccounts()
        {
            return vault.UserOperations.GetLoginAccounts();
        }

        /// <summary>
        /// Used to get Login account of a user from M-Files
        /// </summary>
        /// <param name="loginID"></param>
        /// <returns></returns>
        public LoginAccount GetLoginAccount(int loginID)
        {
            return vault.UserOperations.GetLoginAccountOfUser(loginID);
        }

        #endregion
        
        #region Search
        /// <summary>
        /// API method to Search with conditions and returns properties of search result objects
        /// </summary>
        /// <param name="searchConditions"></param>
        /// <param name="count"></param>
        /// <param name="objVers"></param>
        /// <returns></returns>
        public PropertyValuesOfMultipleObjects SearchForObject(SearchConditions searchConditions, int count, ref ObjVers objVers)
        {

            ObjectSearchResults searchResults = vault.ObjectSearchOperations.SearchForObjectsByConditionsEx(searchConditions, MFSearchFlags.MFSearchFlagNone, false, MaxResultCount: count, SearchTimeoutInSeconds: 0);
            objVers = searchResults.GetAsObjectVersions().GetAsObjVers();
            PropertyValuesOfMultipleObjects pptOfObjects = vault.ObjectPropertyOperations.GetPropertiesOfMultipleObjects(objVers);
            return pptOfObjects;
        }

        /// <summary>
        /// API method to Get Properties of multiple objects
        /// </summary>
        /// <param name="oObjVers"></param>
        /// <returns></returns>
        public PropertyValuesOfMultipleObjects GetPropertyValuesOfMultipleobjects(ObjVers oObjVers)
        {
            return vault.ObjectPropertyOperations.GetPropertiesOfMultipleObjects(oObjVers);
        }

        /// <summary>
        /// API method to search with ClassID
        /// </summary>
        /// <param name="oSearchCondition"></param>
        /// <returns></returns>
        public ObjectVersions GetAllObjVersOfAClass(SearchConditions oSearchCondition)
        {
           
            ObjectSearchResults searchResult = vault.ObjectSearchOperations.SearchForObjectsByConditionsEx(oSearchCondition, MFSearchFlags.MFSearchFlagNone, true, 0, 0);
            return searchResult.GetAsObjectVersions();
        }
        //Rheal task101 20/06/2019
        public ObjectVersionAndPropertiesOfMultipleObjects GetAllObjVersByObjIDs(List<string> lsIDs, int classID)
        {
            ObjVers objVers = new ObjVers();
            int objType = vault.ClassOperations.GetObjectClass(classID).ObjectType;
            foreach (var id in lsIDs)
            {
                ObjVer objVer = new ObjVer();
                objVer.ObjID.ID = Convert.ToInt32(id);
                objVer.Type = objType;
                objVer.ID = Convert.ToInt32(id);
                objVers.Add(-1, objVer);
            }

            return GetObjectVersionAndPropertiesOfMultipleObjects(objVers);
        }


        public void UpdateClassAliasAndName(XMLCls.ClassDetail ObjClass)
        {
            try
            {

                




                // Get our  class by id and add an alias.
                var ObjectClassAdmin = vault.ClassOperations.GetObjectClassAdmin(ObjClass.MFID);

                // Before we update, get the current associated property defs from the class (not class admin).
                // This is needed due to bug 18003 (ClassAdmin.AssociatedPropertyDefs is incorrect).
                var associatedPropertyDefs = vault.ClassOperations
                    .GetObjectClass(ObjClass.MFID)
                    .AssociatedPropertyDefs
                    .Clone();

                // Update the aliases.
                ObjectClassAdmin.SemanticAliases = AddAlias(ObjectClassAdmin.SemanticAliases, ObjClass.Alias);

                // Now add all the property defs back.
                ObjectClassAdmin.AssociatedPropertyDefs = new AssociatedPropertyDefs()
                    .PopulateFrom(associatedPropertyDefs); // Note the call to the extension method.

                // Update the server.
                vault.ClassOperations.UpdateObjectClassAdmin(ObjectClassAdmin);
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        private static SemanticAliases AddAlias(SemanticAliases aliases, string newAlias)
        {
            // Sanity.
            aliases = aliases ?? new SemanticAliases();

            // Add the alias (no attempt to validate).
            aliases.Value =  newAlias;

            // Return.
            return aliases;
        }
        public void UpdatePropertyAliasAndName(XMLProperty.PropertyDef PropDef)
        {
            try
            {
                PropertyDefAdmin Padmin = vault.PropertyDefOperations.GetPropertyDefAdmin(PropDef.MFID);
                Padmin.SemanticAliases.Value = PropDef.Alias;
                Padmin.PropertyDef.Name = PropDef.Name;
                vault.PropertyDefOperations.UpdatePropertyDefAdmin(Padmin);

                PropertyDef pdef = vault.PropertyDefOperations.GetPropertyDef(PropDef.MFID);
                pdef.Name = PropDef.Name;

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public void UpdateObjectTypeAliasAndName(XMLObjectType.ObjectType objectDef)
        {
            try
            {
                MFilesAPI.ObjTypeAdmin objtype = vault.ObjectTypeOperations.GetObjectTypeAdmin(objectDef.MFID);
                objtype.SemanticAliases.Value = objectDef.Alias;
                objtype.ObjectType.NameSingular = objectDef.Name;
                vault.ObjectTypeOperations.UpdateObjectTypeAdmin(objtype);

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public void UpdatevalueListAliasAndName(XMLValueListDef.ValueListDef ValLstDef)
        {
            try
            {
                ObjTypeAdmin ObjValueList = vault.ValueListOperations.GetValueListAdmin(ValLstDef.MFID);
                ObjValueList.SemanticAliases.Value = ValLstDef.Alias;
                ObjValueList.ObjectType.NameSingular = ValLstDef.Name;
                vault.ValueListOperations.UpdateValueListAdmin(ObjValueList);
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public void UpdateWorkFlowAliasAndName(XMLWorkFlowDef.WorkFlowDef WrkFlowDef)
        {
            try
            {
                WorkflowAdmin ObjWrkFlwAdmin = vault.WorkflowOperations.GetWorkflowAdmin(WrkFlowDef.MFID);
                ObjWrkFlwAdmin.SemanticAliases.Value = WrkFlowDef.Alias;
                ObjWrkFlwAdmin.Workflow.Name = WrkFlowDef.Name;
                vault.WorkflowOperations.UpdateWorkflowAdmin(ObjWrkFlwAdmin);


            }
            catch (Exception ex)
            {
                throw ex;
            }
        }


        public void UpdateWorkFlowStateAliasAndName(XmLWorkFlowStateDef.WorkFlowStateDef WrkFlowStateDef)
        {
            try
            {
                // var stateAdmin = vault.WorkflowOperations.GetWorkflowAdmin(1037).States.Cast<IStateAdmin>().FirstOrDefault(sa => sa.ID == 108).SemanticAliases.Value;
                WorkflowAdmin ObjWrkFlwAdmin = vault.WorkflowOperations.GetWorkflowAdmin(WrkFlowStateDef.MFWorkflowID);
                ObjWrkFlwAdmin.States.Cast<IStateAdmin>().FirstOrDefault(sa => sa.ID == WrkFlowStateDef.MFID).SemanticAliases.Value = WrkFlowStateDef.Alias;
                ObjWrkFlwAdmin.States.Cast<IStateAdmin>().FirstOrDefault(sa => sa.ID == WrkFlowStateDef.MFID).Name = WrkFlowStateDef.Name;
                vault.WorkflowOperations.UpdateWorkflowAdmin(ObjWrkFlwAdmin);
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public string GetWorkFlowStateAlias(int WorkFlowID,int WorkFlowStateID)
        {
            try
            {
                // var stateAdmin = vault.WorkflowOperations.GetWorkflowAdmin(1037).States.Cast<IStateAdmin>().FirstOrDefault(sa => sa.ID == 108).SemanticAliases.Value;
                WorkflowAdmin ObjWrkFlwAdmin = vault.WorkflowOperations.GetWorkflowAdmin(WorkFlowID);
                return ObjWrkFlwAdmin.States.Cast<IStateAdmin>().FirstOrDefault(sa => sa.ID == WorkFlowStateID).SemanticAliases.Value ;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
      


       public string GetMFilesLog()
        {
            return vault.EventLogOperations.ExportAll();
        }

        public void ClearMfilesLog()
        {
            vault.EventLogOperations.Clear();
        }

        public ObjectVersionAndPropertiesOfMultipleObjects GetObjectVersionAndPropertiesOfMultipleObjects(ObjVers objVers)
        {
            return vault.ObjectOperations.GetObjectVersionAndPropertiesOfMultipleObjects(objVers, true, false, true);
        }
        #endregion

        #region CheckIn
        /// <summary>
        /// API method call to CheckIn multiple Objects
        /// </summary>
        /// <param name="oObjVers"></param>
        public void CheckInAll(ObjVers oObjVers)
        {
            int iObjVarCount = oObjVers.Count;
            const int iBatchCount = 500;
            int iRunningNumber = 0;
            int iCurrentBatchNo = 0;

            //Grouping the ObjVers with 500
            for (int i = 0; i < iObjVarCount / iBatchCount + 1; i++)
            {
                ObjVers checkInVers = new ObjVers();
                if (iRunningNumber < iObjVarCount)
                {
                    if (iObjVarCount - iRunningNumber >= iBatchCount)
                    {
                        iCurrentBatchNo = iBatchCount;
                    }
                    else
                    {
                        iCurrentBatchNo = iObjVarCount - iRunningNumber;
                    }

                    for (int j = 1; j <= iCurrentBatchNo; j++)
                    {
                        checkInVers.Add(-1, oObjVers[j]);
                    }
                    iRunningNumber += iCurrentBatchNo;
                    vault.ObjectOperations.CheckInMultipleObjects(checkInVers);
                }

            }
        }
        #endregion

        #region Undo CheckOut
        /// <summary>
        /// API method call to undo checkOut
        /// </summary>
        /// <param name="oObjVers"></param>
        public void UndoCheckoutMultipleObjects(ObjVers oObjVers)
        {
            foreach (ObjVer objVer in oObjVers)
            {
                vault.ObjectOperations.UndoCheckout(objVer);
            }
        }

        public void UndoCheckout(ObjVer oObjVer)
        {
            ObjectVersionAndProperties objVerAndProp = vault.ObjectOperations.GetLatestObjectVersionAndProperties(oObjVer.ObjID, true, true);

            //Undo checkOut if object is checked Out
            if (objVerAndProp.VersionData.ObjectCheckedOut)
            {
                vault.ObjectOperations.UndoCheckout(oObjVer);
            }
        }

        public bool ObjecctCheckoutStatus(ObjVer oObjVer)
        {
            ObjectVersionAndProperties objVerAndProp = vault.ObjectOperations.GetLatestObjectVersionAndProperties(oObjVer.ObjID, true, true);

            //Undo checkOut if object is checked Out
          return  objVerAndProp.VersionData.ObjectCheckedOut;
            
        }
        #endregion

        #region Get Latest Version
        /// <summary>
        /// API method call to Get latest version of an object
        /// </summary>
        /// <param name="oObjID"></param>
        /// <returns></returns>
        public ObjVer GetLatestVersion(ObjID oObjID)
        {
            return vault.ObjectOperations.GetLatestObjVer(oObjID, false);
        }
        #endregion

        #region File wrapper
        /// <summary>
        /// API method call to insert file into an object
        /// </summary>
        /// <param name="sFilePath"></param>
        /// <param name="sfileTitle"></param>
        /// <param name="iObjID"></param>
        /// <param name="iVersion"></param>
        /// <param name="iObjTypeId"></param>
        public void UploadFile(string sFilePath,string sfileTitle,ref ObjVer oObjVer)
        {

            string x = vault.ObjectFileOperations.DownloadFileAsDataURI(oObjVer, 432, 1);
            //ObjectFiles oObjectFiles = vault.ObjectFileOperations.GetFiles(oObjVer);
            //oObjVer = vault.ObjectOperations.CheckOut(oObjVer.ObjID).ObjVer;
            //vault.ObjectFileOperations.AddFile(oObjVer, sfileTitle, "jpg", sFilePath);
            //vault.ObjectOperations.CheckIn(oObjVer);

        }

        public DataSetExportingStatus DataSetExport(string sDataSetName,ref bool isExporting)
        {                        
            DataSetExportingStatus status = null;
            DataSets dataSets = vault.DataSetOperations.GetDataSets();            

            foreach (DataSet ds in dataSets)
            {
                if (ds.Name == sDataSetName)
                {
                    vault.DataSetOperations.StartDataSetExport(ds.ID);                                                            
                    status = vault.DataSetOperations.GetDataSetExportingStatus(ds.ID);
                    isExporting = status.IsExporting;
                }
            }

            return status;
        }
        #endregion

        public string GetObjectGUID(ObjID objID)
        {
            return vault.ObjectOperations.GetObjectGUID(objID);
        }

        public string GetPathInDefaultView(ObjectFiles files)
        {
            foreach(ObjectFile file in files)
            {
                string path = "H:\\New folder\\"+ file.Title.Replace("/","")+"."+file.Extension;
                vault.ObjectFileOperations.DownloadFile(file.ID,file.Version,path );
            }
            
            return "f";
        }
        
        public void GetUserDetails()
        {
            LoginAccounts loginAcc = vault.UserOperations.GetLoginAccounts();
            UserAccounts userAcc = vault.UserOperations.GetUserAccounts();
        }
        public string GetPublicLink(int ObjectID, int pDay, int pMonth, int pYear)
        {

            //  ObjID obj = new ObjID();
            //  obj.ID = ObjectID;
            //   obj.Type = 0;
            //   ObjVer ObjverNew = vault.ObjectOperations.GetLatestObjVer(obj, false);
            //  FileVer FV = new FileVer();
            //  FV.Version = -1;
            ////  FV.ID = ObjectID;
            //  SharedLinkInfo ObjSharedLinkInfo = new SharedLinkInfo();
            //  ObjSharedLinkInfo.ObjVer = ObjverNew;
            //  //ObjSharedLinkInfo.FileVer = FV;
            //  //SharedLinkInfos Link = vault.SharedLinkOperations.GetSharedLinksByObject(obj);
            //  ObjSharedLinkInfo = vault.SharedLinkOperations.CreateSharedLink(ObjSharedLinkInfo);
            //  return "";


            //var serverApplication = new MFilesServerApplication();
            //serverApplication.ConnectAdministrative();
            //var vault = serverApplication.LogInToVaultAdministrative("{E3DB829A-CDFE-4492-88C1-3E7B567FBD59}");

            // Get the current version of the object to share.
            var objVer = vault.ObjectOperations.GetLatestObjVer(new ObjID()
            {
                ID = ObjectID,
                Type = (int)MFBuiltInObjectType.MFBuiltInObjectTypeDocument
            }, AllowCheckedOut: false, UpdateFromServer: true);

            //Timestamp TS = new Timestamp();
            ////TS.Hour = 48;
            //TS.Day = 8;
            // Define the shared link attributes.
            var sharedLinkInfo = new SharedLinkInfo()
            {
                ObjVer = objVer,
                FileVer = vault
                          .ObjectFileOperations
                          .GetFiles(objVer)
                          .Cast<ObjectFile>()
                          .ElementAt(0)
                          .FileVer, // This should be nicer!
                //ExpirationTime = new Timestamp()
                //{
                //    Day = 1,
                //    Month = 4,
                //    Year = 2018
                //}
                ExpirationTime = new Timestamp()
                {
                    Day = Convert.ToUInt32(pDay),
                    Month = Convert.ToUInt32(pMonth),
                    Year = Convert.ToUInt32(pYear)
                }

            };

            // Ensure that, if we have a file, we set version to -1
            // (https://www.m-files.com/api/documentation/latest/index.html#MFilesAPI~VaultSharedLinkOperations~CreateSharedLink.html)
            if (null != sharedLinkInfo.FileVer)
            {
                sharedLinkInfo.FileVer.Version = -1;
            }

            // Create the link and output the token.
            sharedLinkInfo = vault.SharedLinkOperations.CreateSharedLink(sharedLinkInfo);
            //Console.WriteLine(sharedLinkInfo.AccessKey);

            return sharedLinkInfo.AccessKey;





        }
        //task 1100
        public ObjectVersions GetHistory(int ObjType,int ObjID)
        {
            ObjVer ObjV = new ObjVer();
            ObjV.ID = ObjID;
            ObjV.ObjID.ID = ObjID;
            ObjV.ObjID.Type = ObjType;
            ObjectVersions objVersions = vault.ObjectOperations.GetHistory(ObjV.ObjID);
            return objVersions;

        }

        public PropertyValues GetObjectPrperties(ObjVer Obj)
        {
            return vault.ObjectPropertyOperations.GetProperties(Obj, true);
        }

        //task 1100
        //Task #106
        public ObjectFiles GetFilesFromMFiles(int ObjID, int ObjectType, int ObjectVersion)
        {
            ObjVer ObjV = new ObjVer();
            ObjV.ID = ObjID;
            ObjV.ObjID.ID = ObjID;
            ObjV.ObjID.Type = ObjectType;
            ObjV.Version = ObjectVersion;
            ObjV.Type = ObjectType;
            return vault.ObjectFileOperations.GetFiles(ObjV);
        }

        public void DownloadFile(int FileID, int FileVersion,string FilePath)
        {
            vault.ObjectFileOperations.DownloadFile(FileID, FileVersion, FilePath);
        }
        public ObjectVersionAndProperties GetObjectProperties(int ObjID, int ObjectType, int ObjectVersion)
        {
            ObjVer ObjV = new ObjVer();
            ObjV.ID = ObjID;
            ObjV.ObjID.ID = ObjID;
            ObjV.ObjID.Type = ObjectType;
            ObjV.Version = ObjectVersion;
            ObjV.Type = ObjectType;
           return vault.ObjectOperations.GetLatestObjectVersionAndProperties(ObjV.ObjID, false);
        }
        //Task #106

        #region 1087 Vault.GetMetadataStructureVersionID to auto update metadata structure
        public long GetMetadataStructureVersionID()
        {
            return vault.GetMetadataStructureVersionID();
        }
        #endregion
        public  string GetFileChecksum(string file, System.Security.Cryptography.HashAlgorithm algorithm)
        {
            string result = string.Empty;

            using (FileStream fs = File.OpenRead(file))
            {
                result = BitConverter.ToString(algorithm.ComputeHash(fs)).ToLower().Replace("-", "");
            }

            return result;
        }

        #region Task 1232
        public string GetLicenseKey()
        {
            string Result = vault.ExtensionMethodOperations.ExecuteVaultExtensionMethod("GetLicenseKeyFromCloudVault", string.Empty);
            return Result;
                
        }
        #endregion

        public  ObjectVersions GetAllUnManagedObjVers(int ExternalFileRepositoryObjectID,Vault UmngVault)
        {

          
            SearchConditions oSearchConditions = new SearchConditions();
            //MFilesAPI.SearchCondition oSearchCondition = new MFilesAPI.SearchCondition();
            //// ' Create a search condition for the object type id
            //oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            //oSearchCondition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeObjectTypeID;
            //oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeLookup, 0);
            //oSearchConditions.Add(-1, oSearchCondition);


            ////' Create a search condition is not deleted
            //oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            //oSearchCondition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeDeleted;
            //oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, false);
            //oSearchConditions.Add(-1, oSearchCondition);

            //if (ExternalFileRepositoryObjectID >0)
            //{ 
                var condition = new SearchCondition();
                // Set the expression.
                condition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeExtID;
                // Set the condition type.
                condition.ConditionType = MFConditionType.MFConditionTypeEqual;
                // Set the value.
                // In this case "MyExternalObjectId" is the ID of the object in the remote system.
                condition.TypedValue.SetValue(MFDataType.MFDatatypeText, ExternalFileRepositoryObjectID.ToString());
                oSearchConditions.Add(-1, condition);
            //}
            //else
            //{
            //    var condition = new SearchCondition();
            //    // Set the expression.
            //    condition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeExtID;
            //    // Set the condition type.
            //    condition.ConditionType = MFConditionType.MFConditionTypeNotEqual;
            //    // Set the value.
            //    // In this case "MyExternalObjectId" is the ID of the object in the remote system.
            //    condition.TypedValue.SetValue(MFDataType.MFDatatypeText,"0");
            //    oSearchConditions.Add(-1, condition);
            //}
           
            ObjectSearchResults searchResult = UmngVault.ObjectSearchOperations.SearchForObjectsByConditions(oSearchConditions,MFSearchFlags.MFSearchFlagIncludeUnmanagedObjects, false);
            return searchResult.GetAsObjectVersions();
        }


        public Vault GetConnectionForUnManageObject(string VaultSettings)
        {

            string[] Settings = VaultSettings.Split(',');  //Spliting Vault settings vaule by ',' and store into string array.
            string userName = Settings[0];
            string password = Settings[1];
            string networkAddress = Settings[2];
            string vaultName = Settings[3];
            string Protocol = Settings[4];
            string EndPoint = Settings[5];
            string UserType = Settings[6];
            string Domain = Settings[7];

            ConfigUtil config = new ConfigUtil();
            if (userName != null && password != null && networkAddress != null && vaultName != null && Protocol != null && EndPoint != null && UserType != null && Domain != null)
            {
                string decryptedPassword = password;
                if (UserType == "3" || UserType == "2") Laminin.CryptoEngine.Decrypt(password, out decryptedPassword);
                this.vaultConnInfo = config.ReadMFilesConectionInfo(userName, decryptedPassword, networkAddress, vaultName, Protocol, EndPoint, UserType, Domain);
                bool isVltConnected = false;
                this.vaultConnInfo = LoadVaultInfoByAuthenticationType(vaultConnInfo);
                this.vault = ConnectToVault(LoadVaultInfoByAuthenticationType(vaultConnInfo), ref isVltConnected);

                Vault oVault = null;
                //Create the server component.
                MFilesServerApplication oServerApp = new MFilesServerApplication();
                //Connect to M-Files server computer "mfserv" by using M-Files user's credentials.
                oServerApp.ConnectEx5(
                                       null,
                                       (MFAuthType)vaultConnInfo.UserType,
                                       vaultConnInfo.UserName,
                                       vaultConnInfo.Password,
                                       vaultConnInfo.Domain,
                                       "",
                                       vaultConnInfo.Protocol,
                                       vaultConnInfo.NetworkAddress,
                                       vaultConnInfo.Endpoint,
                                       false,
                                       vaultConnInfo.LocalComputerName,
                                       false,
                                       true,
                                       "",
                                       "",
                                       true
                                       );
                //Get and loop through all vaults.
                VaultsOnServer oVaultsOnServer = oServerApp.GetVaults();

                foreach (VaultOnServer vault in oVaultsOnServer)
                {
                    if (String.Compare(vault.Name, vaultConnInfo.VaultName, true) == 0)
                    {
                        oVault = vault.LogIn();
                        //   isVltConnected = oVault != null ? true : false;

                        break;
                    }
                }

                if (oVault == null)
                {
                    throw new Exception("The vault does not exists in this server.Please check the vault name.");
                }

                this.vault = oVault;

                this.isVaultConnected = isVltConnected;
            }
            else
            {
                throw new Exception("Please Enter all required Credentials");
            }


            return this.vault;
        }
    }
}