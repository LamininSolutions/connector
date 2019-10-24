using System;
using System.Collections.Generic;
using MFilesAPI;
using LSConnect.Entities;
using LSConnect.Utilities;
using LSConnect.MFiles;
using System.Xml;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Xml.Serialization;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Collections;


public class MFilesWrapper
{

    #region File Wrapper
    /// <summary>
    /// Used to attach file to an Object
    /// </summary>
    /// <param name="sUsername"></param>
    /// <param name="sPassword"></param>
    /// <param name="sNetworkAddress"></param>
    /// <param name="sVaultName"></param>
    /// <param name="sFilePath"></param>
    /// <param name="sFileTitle"></param>
    /// <param name="iObjId"></param>
    /// <param name="iVersion"></param>
    /// <param name="iObjTypeId"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //   public static void InsertFile(string sUsername, string sPassword, string sNetworkAddress, string sVaultName, string sFilePath, string sFileTitle, int iObjId, int iVersion, int iObjTypeId)
    public static void InsertFile(string VaultSettings, string sFilePath, string sFileTitle, int iObjId, int iVersion, int iObjTypeId)
    {
        if (File.Exists(sFilePath))
        {
            //MFilesAccess mFileAccess = GetMFilesAccess(sUsername, sPassword, sNetworkAddress, sVaultName);
            MFilesAccess mFileAccess = GetMFilesAccessNew(VaultSettings);
            //Creating ObjVer object
            ObjVer objVer = new ObjVer();
            objVer.ID = iObjId;
            objVer.ObjID.ID = iObjId;
            objVer.ObjID.Type = iObjTypeId;
            objVer.Type = iObjTypeId;
            objVer.Version = iVersion;

            try
            {
                mFileAccess.UploadFile(sFilePath, sFileTitle, ref objVer);
            }
            catch (Exception)
            {
                mFileAccess.UndoCheckout(objVer);
                throw;
            }
            finally
            {
                mFileAccess.LogOut();
            }
        }
        else
        {
            throw new Exception("File Not exists in the specified location");
        }
    }

    #endregion

    #region Create New Object


    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetOnlyObjectVersions(string sUsername, string sPassword, string sNetworkAddress, string sVaultName, int classID, DateTime? dtModifieDateTime, string sLsOfID, out string objverXML)
    public static void GetOnlyObjectVersions(string VaultSettings, int classID, DateTime? dtModifieDateTime, string sLsOfID, out string objverXML)
    {
        //    System.Diagnostics.Debugger.Launch();
        string sMFileObjVersXML = "";

        //MFilesAccess mFilesAccess = GetMFilesAccess(sUsername, sPassword, sNetworkAddress, sVaultName); Commented by DevTeam2
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings); //Added by DevTeam2(Rheal) getting vault connection settings in single varible.
        SearchConditions oSearchConditions = new SearchConditions();

        List<string> lsID = new List<string>();

        if (!string.IsNullOrEmpty(sLsOfID))
        {
            string[] arrofId = sLsOfID.Split(',');
            lsID = arrofId.Where(x => !string.IsNullOrEmpty(x)).ToList();
            //sMFileObjVersXML = CreateMFileObjVersXmlWithType(mFileObjVers, lsID);
            ObjectVersionAndPropertiesOfMultipleObjects objVerMultiObjects = mFilesAccess.GetAllObjVersByObjIDs(lsID, classID);
            sMFileObjVersXML = CreateMFileObjVersObjIDsXmlWithType(objVerMultiObjects, classID);
        }
        else
        {
            SetSearchConditionForClass(classID, dtModifieDateTime, ref oSearchConditions);
            ObjectVersions mFileObjVers = mFilesAccess.GetAllObjVersOfAClass(oSearchConditions);
            sMFileObjVersXML = CreateMFileObjVersXmlWithType(mFileObjVers, lsID);
        }

        objverXML = sMFileObjVersXML;
        mFilesAccess.LogOut();
    }
    /// <summary>
    /// Get Deleted objects from M-Files
    /// </summary>
    /// <param name="VaultSettings"></param>
    /// <param name="classID"></param>
    /// <param name="dtModifieDateTime"></param>
    /// <param name="objverXML"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void GetDeletedObjects(string VaultSettings, int classID, DateTime? dtModifieDateTime, out string objverXML)
    {
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
        SearchConditions oSearchConditions = new SearchConditions();

        SetSearchConditionForDeleted(classID, dtModifieDateTime, ref oSearchConditions);
        ObjectVersions mFileObjVers = mFilesAccess.GetAllObjVersOfAClass(oSearchConditions);
        ObjVers objVer = mFileObjVers.GetAsObjVers();

        ObjectVersionAndPropertiesOfMultipleObjects objVerMultiObjects = mFilesAccess.GetObjectVersionAndPropertiesOfMultipleObjects(objVer);

        objverXML = CreateMFileDeletedObjXML(objVerMultiObjects);

        mFilesAccess.LogOut();

    }
    /// <summary>
    /// CLR Method to insert/Update objects in M-Files/SQL
    /// </summary>
    /// <param name="sUsername"></param>
    /// <param name="sPassword"></param>
    /// <param name="sNetworkAddress"></param>
    /// <param name="sVaultName"></param>
    /// <param name="sXmlFile"></param>
    /// <param name="sObjVerXml"></param>
    /// <param name="sPropertyIds"></param>
    /// <param name="iUpdateMethod"></param>
    /// <param name="sInsertObjectIdAndVersion"></param>
    /// <param name="sNewObjectDetails"></param>
    /// <param name="synchErrorObjID"></param>
    /// <param name="sDeletedObjVerXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //public static void CreateNewObject(string sUsername, string sPassword, string sNetworkAddress, string sVaultName, string sXmlFile, string sObjVerXml, string sPropertyIds, int iUpdateMethod, DateTime? dtModifieDateTime, string sLsOfID, out string sInsertObjectIdAndVersion, out string sNewObjectDetails, out string synchErrorObjID, out string sDeletedObjVerXml, out string errorInfoXML)
    public static void CreateNewObject(string VaultSettings, string sXmlFile, string sObjVerXml, string sPropertyIds, int iUpdateMethod, DateTime? dtModifieDateTime, string sLsOfID, out string sInsertObjectIdAndVersion, out string sNewObjectDetails, out string synchErrorObjID, out string sDeletedObjVerXml, out string errorInfoXML)
    {


        sInsertObjectIdAndVersion = null;
        sNewObjectDetails = null;
        synchErrorObjID = null;
        sDeletedObjVerXml = null;
        errorInfoXML = null;

        if (sLsOfID == "<form/>")
        {
            sLsOfID = null;
        }


        //Creating new Data Table and setting column mapping type to Attribute
        DataTable dtDeleted = new DataTable { TableName = "objVers" };
        dtDeleted.Columns.Add("objectID", typeof(String));
        dtDeleted.Columns.Add("version", typeof(String));
        foreach (DataColumn dc in dtDeleted.Columns)
        {
            dc.ColumnMapping = MappingType.Attribute;
        }

        try
        {
            // MFilesAccess mFilesAccess = GetMFilesAccess(sUsername, sPassword, sNetworkAddress, sVaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);

            List<int> ids = sPropertyIds.Split(',').Select(int.Parse).ToList().Distinct().ToList();
            List<int> externalPptDef = ListOfInternalProperties().ConvertAll(s => int.Parse(s));

            if (ids.Count > 0)
                externalPptDef = externalPptDef.Except(ids).ToList();

            Dictionary<int, ObjectVersion> sqlLink = new Dictionary<int, ObjectVersion>();
            Dictionary<int, ObjVer> synchError = new Dictionary<int, ObjVer>();
            List<ErrorInfo> errorInfoList = new List<ErrorInfo>();
            List<int> errorList = new List<int>();

            ObjectVersionList oNewObjVers = new ObjectVersionList();

            XmlSerializer serializer = new XmlSerializer(typeof(XMLClass.ObjectDetailsCollection));
            StringReader reader = new StringReader(sXmlFile);
            XMLClass.ObjectDetailsCollection objectDetailCollection = (XMLClass.ObjectDetailsCollection)serializer.Deserialize(reader);
            reader.Close();

            if (objectDetailCollection.Object[0].ClassDetail.property.Count > 0)
            {
                ObjVers objCreated = new ObjVers();

                try
                {
                    CreateObject(objectDetailCollection, mFilesAccess, ref sqlLink, ref synchError, ref objCreated, ref dtDeleted, ref errorInfoList);
                    //mFilesAccess.CheckInAll(objCreated);
                    sInsertObjectIdAndVersion = CreateXml(sqlLink);
                    synchErrorObjID = CreateSynchronisationErrorXml(synchError);

                    if (iUpdateMethod == 0)
                    {
                        sDeletedObjVerXml = DataTableConvertion(sDeletedObjVerXml, dtDeleted);
                    }

                    errorInfoXML = CreateErrorInfoXml(errorInfoList);
                }
                catch (Exception)
                {
                    throw;
                }
            }

            //Removing NamePropertyDef from ExternalPptDef 
            AddNamePropertyDef(mFilesAccess, objectDetailCollection.Object[0].ClassDetail.id, ref externalPptDef);

            if (iUpdateMethod != 0 && sLsOfID == null)
            {
                //Get All objVers of a specific class from M-Files 
                SearchConditions oSearchConditions = new SearchConditions();

                SetSearchConditionForClass(objectDetailCollection.Object[0].ClassDetail.id, dtModifieDateTime, ref oSearchConditions);



                ObjectVersions mFileObjVers = mFilesAccess.GetAllObjVersOfAClass(oSearchConditions);

                DataTable dtMFObjVers;
                DataTable dtSQLObjVers;

                //Convert ObjVers object to XML
                string sMFileObjVersXML = CreateMFileObjVersXml(mFileObjVers);
                //Convert XML to DataTable
                GetDataTablesFromXml(sObjVerXml, sMFileObjVersXML, out dtMFObjVers, out dtSQLObjVers);

                DataTable dtNewObjVer = CompareDataTables(dtMFObjVers, dtSQLObjVers);
                DataTable dtDeletedRecord = GetDeletedObjectId(dtSQLObjVers, dtMFObjVers);

                if (dtDeleted.Rows.Count > 0)
                {
                    dtDeletedRecord.Merge(dtDeleted, false);
                    dtDeletedRecord.TableName = "objVers";
                }

                //Deleted Record from M _Files

                if (dtModifieDateTime == null)
                {
                    sDeletedObjVerXml = DataTableConvertion(sDeletedObjVerXml, dtDeletedRecord);
                }


                //Newly added Record details in M-Files
                if (dtNewObjVer.Rows.Count > 0)
                {

                    //Serialize the DataTable
                    string sNewObjVerXml = DataTableSerialization(dtNewObjVer);

                    //Remane the node name to form
                    if (sNewObjVerXml.Contains("DocumentElement"))
                    {
                        sNewObjVerXml = sNewObjVerXml.Replace("DocumentElement", "form");
                    }

                    oNewObjVers = ParseObjVerXml(objectDetailCollection.Object[0].id, sNewObjVerXml);       //objectTypeId = objectDetailCollection.Object[0].id               

                    errorList.AddRange(synchError.Select(key => key.Value.ID));

                    errorList.AddRange(from errInfo in errorInfoList where errInfo.objID != null select (int)errInfo.objID);

                    sNewObjectDetails = CreateNewObjectXML(mFilesAccess, externalPptDef, oNewObjVers, errorList, dtModifieDateTime);

                }
            }
            else if (iUpdateMethod != 0 && sLsOfID != null)
            {
                oNewObjVers = ParseObjVerXml(objectDetailCollection.Object[0].id, sLsOfID);       //objectTypeId = objectDetailCollection.Object[0].id               

                errorList.AddRange(synchError.Select(key => key.Value.ID));

                errorList.AddRange(from errInfo in errorInfoList where errInfo.objID != null select (int)errInfo.objID);

                sNewObjectDetails = CreateNewObjectXML(mFilesAccess, externalPptDef, oNewObjVers, errorList, dtModifieDateTime);


                if (string.IsNullOrEmpty(sNewObjectDetails))
                {
                    sNewObjectDetails = null;
                }
            }
            else
            {
                if (sqlLink.Count <= 0) return;
                AddNewObjVers(sqlLink, oNewObjVers.ObjVers, oNewObjVers.ObjectGUIDs);
                sNewObjectDetails = CreateNewObjectXML(mFilesAccess, externalPptDef, oNewObjVers, errorList, dtModifieDateTime);
            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            throw;
        }
    }




    private static ObjVers CreateObjVers(XMLClass.RootObjVers sqlObjVers)
    {
        ObjVers objVers = new ObjVers();

        foreach (XMLClass.RootObjVersObjectTypeObjVers objVerObject in sqlObjVers.ObjectType.objVers)
        {
            ObjVer objVer = new ObjVer();
            objVer.ID = objVerObject.objectID;
            objVer.ObjID.ID = objVerObject.objectID;
            objVer.ObjID.Type = sqlObjVers.ObjectType.id;
            objVer.Type = sqlObjVers.ObjectType.id;
            objVer.Version = objVerObject.version;
            objVers.Add(-1, objVer);
        }

        return objVers;
    }

    private static ObjVers CompareObjVers(ObjVers sqlObjVers, ObjVers mFileObjVers)
    {

        List<ObjVer> sqlObjVersList = new List<ObjVer>();
        List<ObjVer> mFileObjVersList = new List<ObjVer>();
        ObjVers updatedObjVers = new ObjVers();

        foreach (ObjVer objVer in sqlObjVers)
        {
            sqlObjVersList.Add(objVer);
        }

        foreach (ObjVer objVer in mFileObjVers)
        {
            mFileObjVersList.Add(objVer);
        }

        var commonList = mFileObjVersList.Except(sqlObjVersList, new ObjVerComparer()).ToList();

        foreach (ObjVer objVer in commonList)
        {
            updatedObjVers.Add(-1, objVer);
        }
        return updatedObjVers;

    }
    /// <summary>
    /// Serialize the Data table contents
    /// </summary>
    /// <param name="sDeletedObjVerXml"></param>
    /// <param name="dtDeletedRecord"></param>
    /// <returns></returns>
    private static string DataTableConvertion(string sDeletedObjVerXml, DataTable dtDeletedRecord)
    {
        if (dtDeletedRecord.Rows.Count > 0)
        {
            sDeletedObjVerXml = DataTableSerialization(dtDeletedRecord);

            if (sDeletedObjVerXml.Contains("DocumentElement"))
            {
                sDeletedObjVerXml = sDeletedObjVerXml.Replace("DocumentElement", "form");
            }
        }
        return sDeletedObjVerXml;
    }

    /// <summary>
    /// Used to convert Dictionary to list of ObjVer and String(GUID)
    /// </summary>
    /// <param name="sqlLink"></param>
    /// <param name="oNewObjVers"></param>
    /// <param name="objectGUIDs"></param>
    private static void AddNewObjVers(Dictionary<int, ObjectVersion> sqlLink, ObjVers oNewObjVers, List<string> objectGUIDs)
    {
        foreach (KeyValuePair<int, ObjectVersion> objectVersion in sqlLink)
        {
            oNewObjVers.Add(-1, objectVersion.Value.ObjVer);
            objectGUIDs.Add(objectVersion.Value.ObjectGUID);
        }
    }

    /// <summary>
    /// Used to create XML of insert/Updated Object properties
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="externalPptDef"></param>
    /// <param name="oNewObjVers"></param>
    /// <param name="errorList"></param>
    /// <returns></returns>
    private static string CreateNewObjectXML(MFilesAccess mFilesAccess, List<int> externalPptDef, ObjectVersionList oNewObjVers, List<int> errorList, DateTime? modifiedDate)
    {
        ObjectVersionAndPropertiesOfMultipleObjects pptOfNewObjects = GetObjVerAndPropertiesInBatch(mFilesAccess, oNewObjVers.ObjVers);

        //Create an XML Contains all details of All new properties
        return CreateSearchResultXml1(pptOfNewObjects, oNewObjVers, externalPptDef, errorList, modifiedDate);

    }

    public static ObjectVersionAndPropertiesOfMultipleObjects GetObjVerAndPropertiesInBatch(MFilesAccess mFilesAccess, ObjVers oObjVers)
    {
        int iObjVarCount = oObjVers.Count;
        int iBatchCount = 600;
        int iRunningNumber = 0;
        int iCurrentBatchNo = 0;
        ObjectVersionAndPropertiesOfMultipleObjects allObjectDetails = null;

        //Grouping the ObjVers with 1000
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
                    checkInVers.Add(-1, oObjVers[iRunningNumber + j]);
                }
                iRunningNumber += iCurrentBatchNo;




                ObjectVersionAndPropertiesOfMultipleObjects pptOfNewObjects = mFilesAccess.GetObjectVersionAndPropertiesOfMultipleObjects(checkInVers);

                if (i == 0)
                {
                    allObjectDetails = pptOfNewObjects;
                }
                else
                {

                    foreach (ObjectVersionAndProperties objVerAndPpt in pptOfNewObjects)
                    {
                        allObjectDetails.Add(-1, objVerAndPpt);
                    }
                }

            }


        }
        return allObjectDetails;
    }

    /// <summary>
    /// Used to Create XML of inserted/updated object property details
    /// </summary>
    /// <param name="pptOfMultipleObjects"></param>
    /// <param name="objVers"></param>
    /// <param name="ExternalPptDef"></param>
    /// <returns></returns>
    private static string CreateSearchResultXml1(ObjectVersionAndPropertiesOfMultipleObjects pptOfMultipleObjects, ObjectVersionList objVers, List<int> ExternalPptDef, List<int> errorList, DateTime? modifiedDate)
    {
        //Used to store running object details
        ObjVer currentObjVer = new ObjVer();
        PropertyValue currentPropertyValue = new PropertyValue();

        bool isHasData = false;
        //Creating XmlDocument
        var doc = new XmlDocument();
        string strDebug = "starts ";
        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            if (pptOfMultipleObjects != null)
            {
                strDebug = strDebug + " pptOfMultipleObjects.Count =" + pptOfMultipleObjects.Count.ToString();
                for (int i = 1; i <= pptOfMultipleObjects.Count; i++)
                {
                    strDebug = strDebug + " i =" + i.ToString();
                    ////kishore
                    DateTime currentModified = new DateTime();

                    string sModifiedDate = string.Empty;
                    if (pptOfMultipleObjects[i] != null && pptOfMultipleObjects[i].Properties != null && pptOfMultipleObjects[i].Properties.SearchForProperty(21) != null && pptOfMultipleObjects[i].Properties.SearchForProperty(21).TypedValue != null && pptOfMultipleObjects[i].Properties.SearchForProperty(21).TypedValue.DisplayValue != null)
                        sModifiedDate = pptOfMultipleObjects[i].Properties.SearchForProperty(21).TypedValue.DisplayValue;

                    if (modifiedDate != null)
                    {
                        currentModified = Convert.ToDateTime(modifiedDate);
                    }

                    strDebug = strDebug + " currentModified =" + currentModified.ToString();
                    DateTime objectModified = Convert.ToDateTime(sModifiedDate);

                    if (objectModified >= currentModified)
                    {

                        if (!errorList.Contains(pptOfMultipleObjects[i].ObjVer.ID))// == -1 || pptOfMultipleObjects[i].SearchForProperty(37).TypedValue.DisplayValue == "No")
                        {
                            isHasData = true;

                            XmlElement searchObject = doc.CreateElement("Object");

                            //Store current objVer value to log in case of error
                            currentObjVer = pptOfMultipleObjects[i].ObjVer;

                            //Adding 'objectId' Attribute
                            XmlAttribute objectId = doc.CreateAttribute("objectId"); //objectId
                            objectId.Value = Convert.ToString(pptOfMultipleObjects[i].ObjVer.ID);
                            searchObject.Attributes.Append(objectId);

                            strDebug = strDebug + " objectId =" + objectId.ToString();

                            XmlAttribute objVersion = doc.CreateAttribute("objVersion");
                            objVersion.Value = Convert.ToString(pptOfMultipleObjects[i].ObjVer.Version);
                            searchObject.Attributes.Append(objVersion);

                            XmlAttribute objectGUID = doc.CreateAttribute("objectGUID");
                            objectGUID.Value = pptOfMultipleObjects[i].VersionData.ObjectGUID;
                            searchObject.Attributes.Append(objectGUID);

                            XmlAttribute displayID = doc.CreateAttribute("DisplayID");
                            displayID.Value = pptOfMultipleObjects[i].VersionData.DisplayID;
                            searchObject.Attributes.Append(displayID);

                            //Added for Task 106
                            XmlAttribute File_Count = doc.CreateAttribute("FileCount");
                            File_Count.Value = pptOfMultipleObjects[i].VersionData.FilesCount.ToString();
                            searchObject.Attributes.Append(File_Count);
                            //Added for Task 106

                            strDebug = strDebug + " displayID =" + displayID.ToString();



                            // pptOfMultipleObjects[i].Properties.SearchForProperty()
                            foreach (PropertyValue propertyValue in pptOfMultipleObjects[i].Properties)
                            {

                                if (!ExternalPptDef.Contains(propertyValue.PropertyDef))
                                {
                                    XmlElement properties = doc.CreateElement("properties");

                                    //Store current property value to log in case of error

                                    currentPropertyValue = propertyValue;

                                    // strDebug.Concat("   propertyValue  ", propertyValue.ToString());// todo

                                    if (propertyValue.PropertyDef == 33)  //Added for task 1115
                                    {
                                        goto NEXT;
                                    }
                                    XmlAttribute propertyId = doc.CreateAttribute("propertyId"); //propertyId
                                    propertyId.Value = propertyValue.PropertyDef.ToString();
                                    properties.Attributes.Append(propertyId);



                                    XmlAttribute dataType = doc.CreateAttribute("dataType"); //dataType                    
                                    dataType.Value = Convert.ToString(propertyValue.TypedValue.DataType);
                                    properties.Attributes.Append(dataType);

                                    XmlAttribute propertyDisplayValue = doc.CreateAttribute("propertyValue"); //propertyValue

                                    //Formating the date to "dd-MM-yyyy HH:mm"
                                    if (propertyValue.TypedValue.DataType == MFDataType.MFDatatypeDate || propertyValue.TypedValue.DataType == MFDataType.MFDatatypeTimestamp)
                                    {
                                        if (propertyValue.Value.DisplayValue != "")
                                        {
                                            System.DateTime MyDateTime = (DateTime)propertyValue.TypedValue.Value;
                                            // DateTime MyDateTime = Convert.ToDateTime();//, System.Globalization.CultureInfo.InvariantCulture);//new DateTime(propertyValue.Value.DisplayValue);
                                            String DateString = MyDateTime.ToString("dd-MM-yyyy HH:mm");
                                            propertyDisplayValue.Value = DateString;
                                            //strDebug.Concat("   DateString  ", DateString); // todo
                                        }
                                        else
                                        {
                                            propertyDisplayValue.Value = "";
                                        }
                                    }
                                    else
                                    {
                                        if (propertyValue.TypedValue.DataType == MFDataType.MFDatatypeBoolean)
                                        {
                                            if (!string.IsNullOrEmpty(propertyValue.Value.Value.ToString()))
                                            {
                                                if (Convert.ToBoolean(propertyValue.Value.Value))
                                                    propertyDisplayValue.Value = "1";
                                                else
                                                    propertyDisplayValue.Value = "0";
                                            }
                                            else
                                            {
                                                propertyDisplayValue.Value = "";
                                                // propertyDisplayValue.Value = "0";
                                            }
                                        }
                                        else
                                        {
                                            propertyDisplayValue.Value = propertyValue.Value.DisplayValue;
                                        }

                                    }

                                    properties.Attributes.Append(propertyDisplayValue);


                                    if (searchObject != null)
                                    {
                                        searchObject.AppendChild(properties);
                                    }

                                    if (propertyValue.TypedValue.DataType == MFDataType.MFDatatypeLookup || propertyValue.TypedValue.DataType == MFDataType.MFDatatypeMultiSelectLookup)
                                    {

                                        XmlElement valueListItem = doc.CreateElement("properties");

                                        XmlAttribute valuelistPropertyID = doc.CreateAttribute("propertyId"); //propertyId
                                        valuelistPropertyID.Value = propertyValue.PropertyDef.ToString();
                                        valueListItem.Attributes.Append(valuelistPropertyID);

                                        XmlAttribute valueListItemID = doc.CreateAttribute("propertyValue"); //propertyValue

                                        string valueListItemIds = null;

                                        if (propertyValue.TypedValue.Value != null && propertyValue.TypedValue.Value.ToString() != "")
                                        {
                                            Array valueListObject = (Array)(propertyValue.TypedValue.Value);

                                            for (int j = 0; j <= valueListObject.GetUpperBound(0); j++)
                                            {
                                                if (!String.IsNullOrEmpty(valueListItemIds))
                                                {
                                                    valueListItemIds = valueListItemIds + "," + valueListObject.GetValue(j, 0).ToString();
                                                }
                                                else
                                                {
                                                    valueListItemIds = valueListObject.GetValue(j, 0).ToString();
                                                }
                                            }
                                        }
                                        valueListItemID.Value = valueListItemIds;
                                        valueListItem.Attributes.Append(valueListItemID);

                                        if (searchObject != null)
                                        {
                                            searchObject.AppendChild(valueListItem);
                                        }
                                    }

                                    NEXT:;
                                }

                            }

                            if (node != null)
                            {
                                //Append the element to XmlDocument
                                node.AppendChild(searchObject);
                            }
                        }




                    }





                }
            }

        }
        catch (Exception ex)
        {
            string customError = "Please check the property (" + currentPropertyValue.PropertyDef.ToString() + ")  value of the object (" +
                         currentObjVer.ID.ToString() + "strDebug =" + strDebug + " \n MSG:" + ex.Message + ") @\n";

            throw new Exception(customError + ex.StackTrace);
        }

        if (isHasData)
        {
            return doc.InnerXml;
        }
        else
        {
            return "";
        }

    }

    /// <summary>
    /// Used to Generate DATA TABLe from XML for M-File object version comparison
    /// </summary>
    /// <param name="objVerXml"></param>
    /// <param name="mFileObjVersXML"></param>
    /// <param name="D1"></param>
    /// <param name="D2"></param>
    /// <returns></returns>
    private static string GetDataTablesFromXml(string objVerXml, string mFileObjVersXML, out DataTable D1, out DataTable D2)
    {
        D1 = new DataTable();
        D2 = new DataTable();

        if (!string.IsNullOrEmpty(objVerXml))
        {
            objVerXml = objVerXml.Replace("<form><ObjectType id=", "");
            objVerXml = objVerXml.Replace("</form>", "");

            int endIndex = objVerXml.IndexOf(">");

            if (endIndex > -1)
            {
                objVerXml = objVerXml.Substring(endIndex + 1);
            }

            objVerXml = objVerXml.Replace("</ObjectType>", "");
            objVerXml = "<form>" + objVerXml + "</form>";

            System.Data.DataSet dsSqlObjVer = new System.Data.DataSet();
            dsSqlObjVer.ReadXml(XmlReader.Create(new StringReader(objVerXml)));


            if (dsSqlObjVer.Tables.Count > 0)
            {
                D2 = dsSqlObjVer.Tables[0];
            }
        }

        if (string.IsNullOrEmpty(mFileObjVersXML)) return objVerXml;
        System.Data.DataSet dsMFilesObjVer = new System.Data.DataSet();
        dsMFilesObjVer.ReadXml(XmlReader.Create(new StringReader(mFileObjVersXML)));

        if (dsMFilesObjVer.Tables.Count > 0)
        {
            D1 = dsMFilesObjVer.Tables[0];
        }
        return objVerXml;
    }

    /// <summary>
    /// Used to compare DATA TABLE to get Updated objects ObjID
    /// </summary>
    /// <param name="dtMfile"></param>
    /// <param name="dtSql"></param>
    /// <returns></returns>
    private static DataTable CompareDataTables(DataTable dtMfile, DataTable dtSql)
    {
        DataTable dtResults = dtMfile.Clone();
        if (dtSql.Rows.Count > 0)
        {
            for (int i = 0; i < dtMfile.Rows.Count; i++)
            {
                var sMFileObjID = dtMfile.Rows[i][0].ToString();
                var sMFileVersion = dtMfile.Rows[i][1].ToString();
                var sMFIleGUID = dtMfile.Rows[i][2].ToString();
                DataRow[] dr = dtSql.Select("objectID='" + sMFileObjID + "'");

                if (dr.Length > 0)
                {
                    var sSqlVersion = dr[0][1].ToString();

                    if (!sSqlVersion.Equals(sMFileVersion))
                    {
                        DataRow drResults = dtResults.NewRow();
                        drResults[0] = sMFileObjID;
                        drResults[1] = sMFileVersion;
                        drResults[2] = sMFIleGUID;
                        dtResults.Rows.Add(drResults);
                    }
                }
                else
                {
                    DataRow drResults = dtResults.NewRow();
                    drResults[0] = sMFileObjID;
                    drResults[1] = sMFileVersion;
                    drResults[2] = sMFIleGUID;
                    dtResults.Rows.Add(drResults);
                }

            }
        }
        else
        {
            dtResults = dtMfile;
        }
        return dtResults;
    }

    /// <summary>
    /// Used to compare DATA TABLE to get deleted objects OBjID from M-File
    /// </summary>
    /// <param name="dtMfile"></param>
    /// <param name="dtSql"></param>
    /// <returns></returns>
    private static DataTable GetDeletedObjectId(DataTable dtMfile, DataTable dtSql)
    {
        String sMFileObjID = "";
        String sMFileVersion = "";
        DataRow[] dr;
        DataTable dtResults = dtMfile.Clone();
        if (dtSql.Rows.Count > 0)
        {
            for (int i = 0; i < dtMfile.Rows.Count; i++)
            {
                sMFileObjID = dtMfile.Rows[i][0].ToString();
                sMFileVersion = dtMfile.Rows[i][1].ToString();
                dr = dtSql.Select("objectID='" + sMFileObjID + "'");

                if (dr.Length == 0)
                {
                    DataRow drResults = dtResults.NewRow();
                    drResults[0] = sMFileObjID;
                    drResults[1] = sMFileVersion;
                    dtResults.Rows.Add(drResults);
                }

            }
        }
        else
        {
            dtResults = dtMfile;
        }
        return dtResults;
    }

    /// <summary>
    /// Used to serialize DATA TABLE
    /// </summary>
    /// <param name="datatable"></param>
    /// <returns></returns>
    private static string DataTableSerialization(DataTable datatable)
    {

        MemoryStream str = new MemoryStream();
        datatable.WriteXml(str, true);
        str.Seek(0, SeekOrigin.Begin);
        StreamReader sr = new StreamReader(str);
        return sr.ReadToEnd();
    }

    private static string QuoteValue(string value)
    {
        return String.Concat("\"", value.Replace("\"", "\"\""), "\"");
    }

    //Can change to direct serialization to improve performance
    /// <summary>
    /// Used to Convert collection of ObjectVersion to XML
    /// </summary>
    /// <param name="objectVersions"></param>
    /// <returns></returns>
    private static string CreateMFileObjVersXml(ObjectVersions objectVersions)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            foreach (ObjectVersion objectVersion in objectVersions)
            {
                XmlElement searchObject = doc.CreateElement("objVers");

                XmlAttribute objectId = doc.CreateAttribute("objectID"); //objectId
                objectId.Value = objectVersion.ObjVer.ID.ToString();
                searchObject.Attributes.Append(objectId);

                XmlAttribute objVersion = doc.CreateAttribute("version"); //objVersion
                objVersion.Value = objectVersion.ObjVer.Version.ToString();
                searchObject.Attributes.Append(objVersion);

                XmlAttribute objectGUID = doc.CreateAttribute("objectGUID"); //objVersion
                objectGUID.Value = objectVersion.ObjectGUID;
                searchObject.Attributes.Append(objectGUID);

                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(searchObject);
                }
            }

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    /*Rheal: added method to return xml after object delete: 13-aug-2019*/
    public static string CreateDeleteObjXML(int objectId, int objVersion,int status,string msg)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            XmlElement deleteObject = doc.CreateElement("objVers");

            XmlAttribute objId = doc.CreateAttribute("objId");
            objId.Value = objectId.ToString();
            deleteObject.Attributes.Append(objId);

            XmlAttribute objVers = doc.CreateAttribute("ObjVers");
            objVers.Value = objVersion.ToString();
            deleteObject.Attributes.Append(objVers);

            XmlAttribute statusCode = doc.CreateAttribute("statusCode");
            statusCode.Value = status.ToString();
            deleteObject.Attributes.Append(statusCode);

            XmlAttribute message = doc.CreateAttribute("Message");
            message.Value = msg.ToString();
            deleteObject.Attributes.Append(message);

            if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(deleteObject);
                }          

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    private static string CreateMFileObjVersXmlWithType(ObjectVersions objectVersions, List<string> lsID)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            foreach (ObjectVersion objectVersion in objectVersions)
            {


                XmlElement searchObject = doc.CreateElement("objVers");

                XmlAttribute objectId = doc.CreateAttribute("objectID"); //objectId
                objectId.Value = objectVersion.ObjVer.ID.ToString();
                searchObject.Attributes.Append(objectId);

                XmlAttribute objVersion = doc.CreateAttribute("version"); //objVersion
                objVersion.Value = objectVersion.ObjVer.Version.ToString();
                searchObject.Attributes.Append(objVersion);

                XmlAttribute objectGUID = doc.CreateAttribute("objectGUID"); //objGUID
                objectGUID.Value = objectVersion.ObjectGUID;
                searchObject.Attributes.Append(objectGUID);

                XmlAttribute objectType = doc.CreateAttribute("objectType"); //objVersion
                objectType.Value = objectVersion.ObjVer.Type.ToString();
                searchObject.Attributes.Append(objectType);


                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(searchObject);
                }

            }

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    //**Rheal Test102 24/06/2019    
    public static string CreateMFileDeletedObjXML(ObjectVersionAndPropertiesOfMultipleObjects objVerMultiObjects)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            foreach (ObjectVersionAndProperties objectVersion in objVerMultiObjects)
            {
                XmlElement searchObject = doc.CreateElement("objVers");

                XmlAttribute objId = doc.CreateAttribute("objId");
                objId.Value = objectVersion.ObjVer.ObjID.ID.ToString();
                searchObject.Attributes.Append(objId);

                XmlAttribute objType = doc.CreateAttribute("objType");
                objType.Value = objectVersion.ObjVer.ObjID.Type.ToString();
                searchObject.Attributes.Append(objType);

                XmlAttribute classId = doc.CreateAttribute("ClassID");
                classId.Value = objectVersion.Properties.SearchForProperty(100).Value.GetLookupID().ToString();
                searchObject.Attributes.Append(classId);

                XmlAttribute lastModified = doc.CreateAttribute("lastModified");
                lastModified.Value = objectVersion.Properties.SearchForProperty(21).Value.DisplayValue;
                searchObject.Attributes.Append(lastModified);

                XmlAttribute lastModifiedBy = doc.CreateAttribute("lastModifiedBy");
                lastModifiedBy.Value = objectVersion.Properties.SearchForProperty(23).Value.GetLookupID().ToString();
                searchObject.Attributes.Append(lastModifiedBy);

                XmlAttribute deletedTime = doc.CreateAttribute("deletedTime");
                deletedTime.Value = objectVersion.Properties.SearchForProperty(27).Value.DisplayValue;
                searchObject.Attributes.Append(deletedTime);

                XmlAttribute deletedBy = doc.CreateAttribute("deletedBy");
                deletedBy.Value = objectVersion.Properties.SearchForProperty(28).Value.GetLookupID().ToString();
                searchObject.Attributes.Append(deletedBy);

                XmlAttribute deletionStatus = doc.CreateAttribute("deletionStatus");
                deletionStatus.Value = objectVersion.Properties.SearchForProperty(93).Value.DisplayValue;
                searchObject.Attributes.Append(deletionStatus);


                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(searchObject);
                }

            }

        }
        catch (Exception ex)
        {
            throw ex;
        }

        return doc.InnerXml;
    }
    //***Rheal Task101 20/06/2019
    private static string CreateMFileObjVersObjIDsXmlWithType(ObjectVersionAndPropertiesOfMultipleObjects objectVersions, int classID)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            for (int i = 1; i <= objectVersions.Count; i++)
            {
                if (objectVersions[i].Properties.SearchForProperty(100).Value.GetLookupID().Equals(classID))
                {
                    XmlElement searchObject = doc.CreateElement("objVers");


                    XmlAttribute objectId = doc.CreateAttribute("objectID"); //objectId
                    objectId.Value = Convert.ToString(objectVersions[i].ObjVer.ID);
                    searchObject.Attributes.Append(objectId);

                    XmlAttribute objVersion = doc.CreateAttribute("version"); //objVersion
                    objVersion.Value = objectVersions[i].ObjVer.Version.ToString();
                    searchObject.Attributes.Append(objVersion);

                    XmlAttribute objectGUID = doc.CreateAttribute("objectGUID"); //objGUID
                    objectGUID.Value = objectVersions[i].VersionData.ObjectGUID;
                    searchObject.Attributes.Append(objectGUID);

                    XmlAttribute objectType = doc.CreateAttribute("objectType"); //objVersion
                    objectType.Value = objectVersions[i].ObjVer.Type.ToString();
                    searchObject.Attributes.Append(objectType);


                    if (node != null)
                    {
                        //Append the element to XmlDocument
                        node.AppendChild(searchObject);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            throw;
        }

        return doc.InnerXml;
    }

    private static string CreateErrorInfoXml(List<ErrorInfo> errorInfoList)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            foreach (ErrorInfo errorInf in errorInfoList)
            {
                XmlElement errorInfo = doc.CreateElement("errorInfo");

                XmlAttribute sqlID = doc.CreateAttribute("sqlID");
                sqlID.Value = errorInf.sqlID.ToString();
                errorInfo.Attributes.Append(sqlID);

                XmlAttribute objID = doc.CreateAttribute("objID");
                objID.Value = errorInf.objID.ToString();
                errorInfo.Attributes.Append(objID);

                XmlAttribute errorMessage = doc.CreateAttribute("ErrorMessage");
                errorMessage.Value = errorInf.errorMessage.ToString();
                errorInfo.Attributes.Append(errorMessage);

                XmlAttribute externalID = doc.CreateAttribute("externalID");
                externalID.Value = null;
                errorInfo.Attributes.Append(externalID);

                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(errorInfo);
                }
            }

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    /// <summary>
    /// Used to Get list of M-File default properties
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="classPpt"></param>
    /// <returns></returns>
    private static List<int> GetClassExtenalProperties(MFilesAccess mFilesAccess, ObjectClass classPpt)
    {
        List<int> externalPptId = new List<int>();

        mFilesAccess.GetExternalProperties(classPpt, ref externalPptId);
        return externalPptId;
    }

    /// <summary>
    /// Used to generate XML of synchronization error object details
    /// </summary>
    /// <param name="objectVersionAndProperties"></param>
    /// <returns></returns>
    private static string CreateSynchronisationErrorXml(Dictionary<int, ObjVer> objectVersionAndProperties)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            foreach (KeyValuePair<int, ObjVer> versionAndProperty in objectVersionAndProperties)
            {
                XmlElement searchObject = doc.CreateElement("Object");

                //Adding 'objectId' Attribute
                XmlAttribute ID = doc.CreateAttribute("ID"); //objectId
                ID.Value = versionAndProperty.Key.ToString();
                searchObject.Attributes.Append(ID);

                XmlAttribute objectId = doc.CreateAttribute("objectId"); //objectId
                objectId.Value = versionAndProperty.Value.ID.ToString();
                searchObject.Attributes.Append(objectId);

                XmlAttribute objVersion = doc.CreateAttribute("objVersion"); //objVersion
                objVersion.Value = versionAndProperty.Value.Version.ToString();
                searchObject.Attributes.Append(objVersion);

                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(searchObject);
                }
            }

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    /// <summary>
    /// Used to generate XML
    /// </summary>
    /// <param name="objectVersionAndProperties"></param>
    /// <returns></returns>
    private static string CreateXml(Dictionary<int, ObjectVersion> objectVersionAndProperties)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            foreach (KeyValuePair<int, ObjectVersion> versionAndProperty in objectVersionAndProperties)
            {
                XmlElement searchObject = doc.CreateElement("Object");

                //Adding 'objectId' Attribute
                XmlAttribute ID = doc.CreateAttribute("ID"); //objectId
                ID.Value = versionAndProperty.Key.ToString();
                searchObject.Attributes.Append(ID);

                XmlAttribute objectId = doc.CreateAttribute("objectId"); //objectId
                objectId.Value = versionAndProperty.Value.ObjVer.ID.ToString();
                searchObject.Attributes.Append(objectId);

                XmlAttribute objVersion = doc.CreateAttribute("objVersion"); //objVersion
                objVersion.Value = versionAndProperty.Value.ObjVer.Version.ToString();
                searchObject.Attributes.Append(objVersion);

                XmlAttribute objectGUID = doc.CreateAttribute("objectGUID"); //objVersion
                objectGUID.Value = versionAndProperty.Value.ObjectGUID;
                searchObject.Attributes.Append(objectGUID);

                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(searchObject);
                }
            }

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    /// <summary>
    /// Create or Update objects into M-Files
    /// </summary>
    /// <param name="objectDetailsCollection"></param>
    /// <param name="mFilesAccess"></param>
    /// <param name="sqlLink"></param>
    /// <param name="synchError"></param>
    /// <param name="objVersion"></param>
    /// <param name="dtDeleted"></param>
    private static void CreateObject(XMLClass.ObjectDetailsCollection objectDetailsCollection,
           MFilesAccess mFilesAccess, ref Dictionary<int, ObjectVersion> sqlLink, ref Dictionary<int, ObjVer> synchError, ref ObjVers objVersion, ref DataTable dtDeleted, ref List<ErrorInfo> errorInfoList)
    {

        foreach (XMLClass.ObjectDetails objectDetails in objectDetailsCollection.Object)
        {
            ErrorInfo errorInfo = new ErrorInfo();

            if (objectDetails.objID != 0 && objectDetails.objVesrion != 0)
            {
                ObjectVersion objectVersion = null;
                ObjVer objVer = new ObjVer();
                objVer.ID = objectDetails.objID;
                objVer.Type = objectDetails.id;
                objVer.ObjID.ID = objectDetails.objID;
                objVer.ObjID.Type = objectDetails.id;
                objVer.Version = objectDetails.objVesrion;

                ObjVer latestObjVer = GetlatestVersion(mFilesAccess, dtDeleted, objVer);

                int iCurrentVersion = objVer.Version;

                if (objVer.Version == latestObjVer.Version)
                {
                    try
                    {
                        mFilesAccess.UpdateObject(objectDetails, ref objVer, ref objectVersion, ref dtDeleted);
                        if (!sqlLink.ContainsKey(objectDetails.sqlID) && iCurrentVersion != objVer.Version && objectVersion != null)
                        {
                            objVersion.Add(-1, objVer);
                            sqlLink.Add(objectDetails.sqlID, objectVersion);
                        }
                    }
                    catch (Exception ex)
                    {
                        mFilesAccess.UndoCheckout(objVer);
                        errorInfo.errorMessage = ex.Message;
                        errorInfo.objID = objectDetails.objID;
                        errorInfo.sqlID = objectDetails.sqlID;
                        errorInfo.externalID = null;
                        errorInfoList.Add(errorInfo);
                    }
                }
                else
                {
                    objVer.Version = latestObjVer.Version; //Added for task 954
                    synchError.Add(objectDetails.sqlID, objVer);
                    //mFilesAccess.UndoCheckoutMultipleObjects(objVersion);
                    //throw new Exception(@"Syncronisation conflict on objectID," + objVer.ObjID.ID);
                }

            }
            else
            {
                try
                {
                    ObjVer objVer = new ObjVer();
                    ObjectVersion objectVersion = null;
                    //**********************************************Start of Code for Task 935(Set name_or_Title default as 'Auto' )******************************************//
                    //Getting name propertyDef of the class
                    int nameProperty = mFilesAccess.GetClass(objectDetails.ClassDetail.id).NamePropertyDef;
                    XMLClass.PropertyDetails ObjPropDef = null;
                    try
                    {
                        ObjPropDef = objectDetails.ClassDetail.property.First(p => p.id == nameProperty);
                    }
                    catch (Exception ex)
                    {
                        if (ex.Message.Contains("Sequence"))
                        {
                            string propertyname = mFilesAccess.GetPropertyName(nameProperty);
                            throw new Exception("Missing value for Property " + propertyname);
                        }
                        else
                        {
                            throw ex;
                        }
                    }
                    XMLClass.PropertyDetails ObjPropDefName_Title = objectDetails.ClassDetail.property.First(p => p.id == 0);

                    if (nameProperty != 0 && string.IsNullOrEmpty(ObjPropDef.Value) && !string.IsNullOrEmpty(ObjPropDefName_Title.Value))
                    {
                        int PropertyIndex = 0;
                        string Name_Or_Title = string.Empty, OtherNameProperty = string.Empty;
                        for (int i = 0; i < objectDetails.ClassDetail.property.Count; i++)
                        {
                            if (objectDetails.ClassDetail.property[i].id == 0)
                            {
                                if (!string.IsNullOrEmpty(objectDetails.ClassDetail.property[i].Value.ToString()))
                                    Name_Or_Title = objectDetails.ClassDetail.property[i].Value.ToString();
                            }

                            if (objectDetails.ClassDetail.property[i].id == nameProperty)
                            {
                                PropertyIndex = i;
                                if (string.IsNullOrEmpty(objectDetails.ClassDetail.property[i].Value))
                                {
                                    if (!string.IsNullOrEmpty(Name_Or_Title))
                                    {
                                        objectDetails.ClassDetail.property[i].Value = Name_Or_Title;
                                    }
                                }
                            }

                        }

                    }
                    else if (nameProperty != 0 && !string.IsNullOrEmpty(ObjPropDef.Value) && string.IsNullOrEmpty(ObjPropDefName_Title.Value))
                    {
                        for (int i = 0; i < objectDetails.ClassDetail.property.Count; i++)
                        {
                            if (objectDetails.ClassDetail.property[i].id == 0)
                            {
                                objectDetails.ClassDetail.property[i].Value = ObjPropDef.Value;
                            }


                        }
                    }
                    //**********************************************End of Code for Task 935(Set name_or_Title default as 'Auto' )******************************************//

                    mFilesAccess.CreateObject(objectDetails, ref objVer, ref objectVersion);

                    if (objVer.ID < 0)
                    {
                        throw new Exception(@"Error in processing object. 
                               Please check with Administrator for error details");
                    }
                    else
                    {
                        objVersion.Add(-1, objVer);
                        if (!sqlLink.ContainsKey(objectDetails.sqlID))
                        {
                            sqlLink.Add(objectDetails.sqlID, objectVersion);
                        }
                    }
                }
                catch (Exception ex)
                {
                    errorInfo.errorMessage = ex.Message;
                    errorInfo.objID = null;
                    errorInfo.sqlID = objectDetails.sqlID;
                    errorInfo.externalID = null;
                    errorInfoList.Add(errorInfo);
                }
            }
        }
    }

    /// <summary>
    /// Get Latest objVer,If object is deleted from M-Files adding that object details to DataTable
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="dtDeletedObjects"></param>
    /// <param name="objID"></param>
    /// <returns></returns>
    private static ObjVer GetlatestVersion(MFilesAccess mFilesAccess, DataTable dtDeletedObjects, ObjVer objVer)
    {
        ObjVer latestObjVer = new ObjVer();

        try
        {
            latestObjVer = mFilesAccess.GetLatestVersion(objVer.ObjID);
        }
        catch (Exception ex)
        {
            dtDeletedObjects.Rows.Add(objVer.ID.ToString(), objVer.Version.ToString());
        }

        return latestObjVer;
    }

    /// <summary>
    /// To parse the Xml to get all ObjVer in SQl Table
    /// </summary>
    /// <param name="xmlFile"></param>
    /// <returns></returns>
    private static ObjectVersionList ParseObjVerXml(int objevtTypeID, string xmlFile)
    {

        ObjectVersionList objectVersionList = new ObjectVersionList();
        if (xmlFile != null && xmlFile != string.Empty)
        {
            objectVersionList
                = XMLHelper.ParseFileObjVerXml(objevtTypeID, xmlFile);
        }
        return objectVersionList;
    }

    /// <summary>
    /// Used to Login into the vault
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <returns></returns>
    private static MFilesAccess GetMFilesAccess(string username, string password, string networkAddress, string vaultName)
    {
        MFilesAccess mFilesAccess = new MFilesAccess(
            Convert.ToString(username),
            Convert.ToString(password), Convert.ToString(networkAddress), Convert.ToString(vaultName));
        return mFilesAccess;
    }

    private static MFilesAccess GetMFilesAccessNew(string VaultSettings)
    {
        MFilesAccess mFilesAccess = new MFilesAccess(VaultSettings);
        return mFilesAccess;
    }

    /// <summary>
    /// Used to parse the Xml to get property value,object Type ID,class ID
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="xmlFile"></param>
    /// <returns></returns>
    private static ObjectInfoList GetObjectListInfo(MFilesAccess mFilesAccess, string xmlFile)
    {
        ObjectInfoList objectInfoList = null;
        if (xmlFile != null && xmlFile != string.Empty)
        {
            objectInfoList
                = XMLHelper.ParseFile(xmlFile, mFilesAccess);
        }
        return objectInfoList;
    }

    /// <summary>
    /// Used to get List of system property ID
    /// </summary>
    /// <returns></returns>
    private static List<string> ListOfInternalProperties()
    {
        // const string sInternalProeperties = "0,22,24,28,30,31,32,34,35,36,40,41,42,43,44,45,46,47,75,76,77,78,79,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,101"; //Commented for Task 1123
        const string sInternalProeperties = "0,22,24,28,30,31,32,34,35,36,40,41,42,43,45,46,47,75,76,77,78,79,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,101"; //44  removed to test the functionality
        string[] ids = sInternalProeperties.Split(new string[] { "," }, StringSplitOptions.None);
        List<string> internalPropertiesList = new List<string>(ids);
        return internalPropertiesList;
    }
    #endregion

    #region Get M-File Properties
    /// <summary>
    /// CLR Method to Get All property details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="propertyXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetProperties(string username, string password, string networkAddress, string vaultName, out string propertyXml)
    public static void GetProperties(string VaultSettings, out string propertyXml)

    {
        try
        {
            // MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName); Commented by DevTeam2
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings); //Added by DevTeam2(Rheal) getting vault connection settings in single varible.
            List<PropertyDef> mFProperties = mFilesAccess.GetAllProperties();

            propertyXml = CreatePropertyXmlFile(mFilesAccess, mFProperties);
            mFilesAccess.LogOut();

        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// CLR Method to Get specific property details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="propertiesId"></param>
    /// <param name="propertyXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetSpecificProperties(string username, string password, string networkAddress, string vaultName, string propertiesId, out string propertyXml)
    public static void GetSpecificProperties(string VaultSettings, string propertiesId, out string propertyXml)

    {
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);

            List<PropertyDef> mFProperties = mFilesAccess.GetProperties(propertiesId);
            propertyXml = CreatePropertyXmlFile(mFilesAccess, mFProperties);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Used to generate XML 
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="propertyList"></param>
    /// <returns></returns>
    private static string CreatePropertyXmlFile(MFilesAccess mFilesAccess, List<PropertyDef> propertyList)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        foreach (var ppt in propertyList)
        {
            //Creating XmlElement
            XmlElement property = doc.CreateElement("Property");

            //Adding 'PropertyName' Attribute
            XmlAttribute propertyName = doc.CreateAttribute("Name"); //PropertyName
            propertyName.Value = ppt.Name;
            property.Attributes.Append(propertyName);

            String alias = mFilesAccess.GetPropertyDefAdmin(ppt.ID).SemanticAliases.Value;
            //Adding 'ID' Attribute
            XmlAttribute Alias = doc.CreateAttribute("Alias"); //pkID
            Alias.Value = alias;
            property.Attributes.Append(Alias);

            //Adding 'PropertID' Attribute
            XmlAttribute propertId = doc.CreateAttribute("MFID"); //PropertID
            propertId.Value = ppt.ID.ToString();
            property.Attributes.Append(propertId);

            //Adding 'ValuelistID' attribute
            XmlAttribute valueListID = doc.CreateAttribute("valueListID"); //valueListID
            valueListID.Value = ppt.ValueList.ToString();
            property.Attributes.Append(valueListID);

            //Adding 'ObjectType' attribute -- Added by LC 2018-9-3
            XmlAttribute ObjectTypeID = doc.CreateAttribute("ObjectypeID"); //ObjectTypeID
            ObjectTypeID.Value = ppt.ObjectType.ToString();
            property.Attributes.Append(ObjectTypeID);

            //Adding 'GUID' attribute -- Added by LC 2018-9-3
            XmlAttribute GUID = doc.CreateAttribute("GUID"); //GUID
            GUID.Value = ppt.GUID.ToString();
            property.Attributes.Append(GUID);

            PropertyDef propertyDef = mFilesAccess.GetPropertyDef(ppt.ID);

            XmlAttribute predefined = doc.CreateAttribute("Predefined"); //Predefined
            if (propertyDef.AutomaticValueType != MFAutomaticValueType.MFAutomaticValueTypeNone || propertyDef.Predefined)
            {
                predefined.Value = "True";
            }
            else
            {
                predefined.Value = "False";
            }
            //predefined.Value = ppt.AutomaticValueType.ToString();
            property.Attributes.Append(predefined);

            //Adding 'PropertyType' Attribute
            XmlAttribute propertyType = doc.CreateAttribute("MFDataType_ID"); //PropertyType
            propertyType.Value = ppt.DataType.ToString();
            property.Attributes.Append(propertyType);

            //Adding 'Created on' Attribute
            DateTime currentDate = DateTime.Now;
            XmlAttribute valueListId = doc.CreateAttribute("CreatedOn");
            valueListId.Value = Convert.ToString(currentDate.ToString("d"));
            property.Attributes.Append(valueListId);

            if (node != null)
            {
                //Appending the Element to node
                node.AppendChild(property);
            }
        }

        //Convert The innerXml to String
        var xmlString = doc.InnerXml;

        return xmlString;
    }

    #endregion

    #region Get M-File Object Types

    /// <summary>
    /// CLR Method to Get All ObjectType details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="objectTypeXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetObjectTypes(string username, string password, string networkAddress, string vaultName, out string objectTypeXml)
    public static void GetObjectTypes(string VaultSettings, out string objectTypeXml)
    {
        try
        {
            //MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName); Commented by DevTeam2
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings); //Added by DevTeam2(Rheal) getting vault connection settings in single varible.

            List<ObjType> mFObjectTypes = mFilesAccess.GetAllObjectTypes();
            objectTypeXml = CreateObjectTypeXmlFile(mFilesAccess, mFObjectTypes);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// CLR Method to Get Specific ObjectType details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="objectTypeIds"></param>
    /// <param name="objectTypeXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //public static void GetSpecificObjectTypes(string username, string password, string networkAddress, string vaultName, string objectTypeIds, out string objectTypeXml)
    public static void GetSpecificObjectTypes(string Vaultsettings, string objectTypeIds, out string objectTypeXml)
    {
        try
        {

            // MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(Vaultsettings);
            List<ObjType> mFObjectTypes = mFilesAccess.GetObjectTypes(objectTypeIds);
            objectTypeXml = CreateObjectTypeXmlFile(mFilesAccess, mFObjectTypes);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Used to generate XML
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="mFObjectTypeList"></param>
    /// <returns></returns>
    private static string CreateObjectTypeXmlFile(MFilesAccess mFilesAccess, List<ObjType> mFObjectTypeList)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        foreach (var objectTypeDetails in mFObjectTypeList)
        {
            //Creating XmlElement
            XmlElement objectType = doc.CreateElement("objectType");

            //Adding 'ObjectTypeName' Attribute
            XmlAttribute objectTypeName = doc.CreateAttribute("Name"); //ObjectTypeName
            objectTypeName.Value = objectTypeDetails.NameSingular;
            objectType.Attributes.Append(objectTypeName);

            string alias = mFilesAccess.GetObjectTypeAdmin(objectTypeDetails.ID).SemanticAliases.Value;
            //Adding 'ObjectAliases' Attribute
            XmlAttribute objectAliases = doc.CreateAttribute("Alias"); //ObjectAliases
            objectAliases.Value = alias;
            objectType.Attributes.Append(objectAliases);

            //Adding 'ObjectTypeId' Attribute
            XmlAttribute objectTypeId = doc.CreateAttribute("MFID"); //ObjectTypeId
            objectTypeId.Value = objectTypeDetails.ID.ToString();
            objectType.Attributes.Append(objectTypeId);

            if (node != null)
            {
                //Appending the Element to node
                node.AppendChild(objectType);
            }
        }
        //Convert The innerXml to String
        var xmlString = doc.InnerXml;

        return xmlString;
    }

    #endregion

    #region Get M-File ValueList

    /// <summary>
    /// CLR Method to Get All ValueList details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="valueListXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetValueLists(string username, string password, string networkAddress, string vaultName, out string valueListXml)
    public static void GetValueLists(string VaultSettings, out string valueListXml)
    {
        try
        {
            // MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);  Commented by DevTeam2
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings); //Added by DevTeam2(Rheal) getting vault connection settings in single varible.
            List<ObjType> mFValueLists = mFilesAccess.GetAllValueLists();
            valueListXml = CreateValueListXmlFile(mFilesAccess, mFValueLists);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// CLR Method to Get Specific ValueList details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="valueListIds"></param>
    /// <param name="valueListXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void GetSpecificValueLists(string username, string password, string networkAddress, string vaultName, string valueListIds, out string valueListXml)
    {
        try
        {

            MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);

            List<ObjType> mFValueLists = mFilesAccess.GetValueLists(valueListIds);
            valueListXml = CreateValueListXmlFile(mFilesAccess, mFValueLists);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Used to genarate XML
    /// </summary>
    /// <param name="mFValueLists"></param>
    /// <returns></returns>
    private static string CreateValueListXmlFile(MFilesAccess mFilesAccess, List<ObjType> mFValueLists)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        foreach (var valueListDetails in mFValueLists)
        {
            //Creating XmlElement
            XmlElement valueList = doc.CreateElement("valueList");

            //Adding 'ValueListName' Attribute
            XmlAttribute valueListName = doc.CreateAttribute("Name"); //ValueListName
            valueListName.Value = valueListDetails.NameSingular;
            valueList.Attributes.Append(valueListName);

            string alias = mFilesAccess.GetValueListAdmin(valueListDetails.ID).SemanticAliases.Value;
            //Adding 'valueListAlias' Attribute
            XmlAttribute valueListAlias = doc.CreateAttribute("Alias"); //valueListAlias
            valueListAlias.Value = alias;
            valueList.Attributes.Append(valueListAlias);

            //Adding 'ValueListId' Attribute
            XmlAttribute valueListId = doc.CreateAttribute("MFID"); //ValueListId
            valueListId.Value = valueListDetails.ID.ToString();
            valueList.Attributes.Append(valueListId);

            //Adding 'ValueListOwner' Attribute
            XmlAttribute valueListOwner = doc.CreateAttribute("Owner"); //Owner
            valueListOwner.Value = valueListDetails.OwnerType.ToString();
            valueList.Attributes.Append(valueListOwner);

            //Adding 'RealObj' Attribute for task 1125 and 1160
            XmlAttribute valuelistRealObject = doc.CreateAttribute("RealObj"); //RealObj
            valuelistRealObject.Value = valueListDetails.RealObjectType.ToString();
            valueList.Attributes.Append(valuelistRealObject);

            if (node != null)
            {
                //Appending the Element to node
                node.AppendChild(valueList);
            }
        }
        //Convert The innerXml to String
        var xmlString = doc.InnerXml;

        return xmlString;
    }

    #endregion

    #region Get M-File ValueList Items

    /// <summary>
    /// CLR Method to Get ValueList Items details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="valueListIds"></param>
    /// <param name="valueListItemsXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetValueListItems(string username, string password, string networkAddress, string vaultName, string valueListIds, out string valueListItemsXml)
    public static void GetValueListItems(string VaultSettings, string valueListIds, out string valueListItemsXml)
    {
        try
        {

            // MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName); Commented by DevTeam2
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings); //Added by DevTeam2(Rheal) getting vault connection settings in single varible.
            List<ValueListItem> mFValueListItems = mFilesAccess.GetMFValueLists(valueListIds);
            valueListItemsXml = CreateValueListItemsXmlFile(mFValueListItems);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void UpdateClassAliasInMFiles(string VaultSettings, string Xml, out string Msg)
    {
        Msg = string.Empty;
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            if (!string.IsNullOrEmpty(Xml))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(XMLCls.ClassList));
                StringReader reader = new StringReader(Xml);
                XMLCls.ClassList objectClassDetailsCollection = (XMLCls.ClassList)serializer.Deserialize(reader);
                reader.Close();
                foreach (XMLCls.ClassDetail CLS in objectClassDetailsCollection.Lst)
                {
                    mFilesAccess.UpdateClassAliasAndName(CLS);

                }
            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void UpdatePropertyAliasInMFiles(string VaultSettings, string Xml, out string Msg)
    {
        Msg = string.Empty;
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            if (!string.IsNullOrEmpty(Xml))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(XMLProperty.PropertyList));
                StringReader reader = new StringReader(Xml);
                XMLProperty.PropertyList objectPropertyDetailsCollection = (XMLProperty.PropertyList)serializer.Deserialize(reader);
                reader.Close();
                foreach (XMLProperty.PropertyDef PropDef in objectPropertyDetailsCollection.Lst)
                {
                    mFilesAccess.UpdatePropertyAliasAndName(PropDef);

                }
            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void UpdateObjectTypeAliasInMFiles(string VaultSettings, string Xml, out string Msg)
    {
        Msg = string.Empty;
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            if (!string.IsNullOrEmpty(Xml))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(XMLObjectType.ObjectTypeList));
                StringReader reader = new StringReader(Xml);
                XMLObjectType.ObjectTypeList ObjectTypeCollection = (XMLObjectType.ObjectTypeList)serializer.Deserialize(reader);
                reader.Close();
                foreach (XMLObjectType.ObjectType ObjDef in ObjectTypeCollection.ObjTypList)
                {
                    mFilesAccess.UpdateObjectTypeAliasAndName(ObjDef);


                }
            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void UpdateValueListAliasInMFiles(string VaultSettings, string Xml, out string Msg)
    {
        Msg = string.Empty;
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            if (!string.IsNullOrEmpty(Xml))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(XMLValueListDef.ValueListCollection));
                StringReader reader = new StringReader(Xml);
                XMLValueListDef.ValueListCollection ValueListCollection = (XMLValueListDef.ValueListCollection)serializer.Deserialize(reader);
                reader.Close();
                foreach (XMLValueListDef.ValueListDef ObjDef in ValueListCollection.LstValueListDef)
                {
                    mFilesAccess.UpdatevalueListAliasAndName(ObjDef);


                }
            }
            mFilesAccess.LogOut();

        }
        catch (Exception ex)
        {
            throw ex;
        }
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void UpdateWorkFlowtAliasInMFiles(string VaultSettings, string Xml, out string Msg)
    {
        Msg = string.Empty;
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            if (!string.IsNullOrEmpty(Xml))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(XMLWorkFlowDef.WorkFlowCollection));
                StringReader reader = new StringReader(Xml);
                XMLWorkFlowDef.WorkFlowCollection workflowCollection = (XMLWorkFlowDef.WorkFlowCollection)serializer.Deserialize(reader);
                reader.Close();
                foreach (XMLWorkFlowDef.WorkFlowDef ObjDef in workflowCollection.LstWorkFlowDef)
                {
                    mFilesAccess.UpdateWorkFlowAliasAndName(ObjDef);


                }
            }
            mFilesAccess.LogOut();

        }
        catch (Exception ex)
        {
            throw ex;
        }
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void UpdateWorkFlowtStateAliasInMFiles(string VaultSettings, string Xml, out string Msg)
    {
        Msg = string.Empty;
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            if (!string.IsNullOrEmpty(Xml))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(XmLWorkFlowStateDef.WorkFlowStateCollection));
                StringReader reader = new StringReader(Xml);
                XmLWorkFlowStateDef.WorkFlowStateCollection workflowStateCollection = (XmLWorkFlowStateDef.WorkFlowStateCollection)serializer.Deserialize(reader);
                reader.Close();
                foreach (XmLWorkFlowStateDef.WorkFlowStateDef ObjDef in workflowStateCollection.LstWorkFlowstateDef)
                {
                    mFilesAccess.UpdateWorkFlowStateAliasAndName(ObjDef);


                }
            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }


    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void SynchValueListItems(string VaultSettings, string Xml, out String Msg)
    {
        System.Diagnostics.Debugger.Launch();
        Msg = string.Empty;
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            if (!string.IsNullOrEmpty(Xml))
            {
                XmlSerializer serializer = new XmlSerializer(typeof(XMLValueList.ValueListItemDetails));
                StringReader reader = new StringReader(Xml);
                XMLValueList.ValueListItemDetails objectDetailCollection = (XMLValueList.ValueListItemDetails)serializer.Deserialize(reader);
                reader.Close();
                foreach (XMLValueList.ValueListItem Item in objectDetailCollection.ValueList)
                {
                    ValueListItem objValueListItem = new ValueListItem();
                    objValueListItem.ID = Item.MFID;
                    objValueListItem.ValueListID = Item.MFValueListID;
                    objValueListItem.Name = Item.Name;
                    if (Item.Owner != 0)
                    {
                        objValueListItem.HasOwner = true;
                        objValueListItem.OwnerID = Item.Owner;
                    }

                    //objValueListItm.DisplayID = Item.DisplayID;
                    //objValueListItm.ItemGUID = Item.ItemGUID;
                    ValueListItem FinalValueListItem = mFilesAccess.SaveValueListItem(objValueListItem, Item.Process_ID, Item.DisplayID, Item.ItemGUID);
                    List<ValueListItem> mFValueListItems = new List<ValueListItem>();
                    if (Item.MFID == 0)
                        mFValueListItems.Add(FinalValueListItem);
                    else
                        mFValueListItems.Add(objValueListItem);

                    Msg = CreateValueListItemsXmlFile(mFValueListItems);
                }
            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }

    /// <summary>
    /// Used to Create XML
    /// </summary>
    /// <param name="mFValueListItemsList"></param>
    /// <returns></returns>
    private static string CreateValueListItemsXmlFile(List<ValueListItem> mFValueListItemsList)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("VLItem");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("VLItem");

        foreach (var valueListItem in mFValueListItemsList)
        {
            //Creating XmlDocument
            XmlElement ValueListItem = doc.CreateElement("ValueListItem");

            //Adding 'ValueListID' Attribute
            XmlAttribute valueListID = doc.CreateAttribute("MFValueListID"); //ValueListID
            valueListID.Value = valueListItem.ValueListID.ToString();
            ValueListItem.Attributes.Append(valueListID);

            //Adding 'ValueListItemID' Attribute
            XmlAttribute valueListItemID = doc.CreateAttribute("MFID"); //ValueListItemID
            valueListItemID.Value = valueListItem.ID.ToString();
            ValueListItem.Attributes.Append(valueListItemID);

            //Adding 'ValueListItemName' Attribute
            XmlAttribute valueListItemName = doc.CreateAttribute("Name"); //ValueListItemName
            valueListItemName.Value = valueListItem.Name;
            ValueListItem.Attributes.Append(valueListItemName);

            //Adding 'Owner' Attribute
            XmlAttribute valuelistItemOwner = doc.CreateAttribute("Owner"); //ValuelistItem Owner
            valuelistItemOwner.Value = valueListItem.OwnerID.ToString();
            ValueListItem.Attributes.Append(valuelistItemOwner);


            //Adding 'Owner' Attribute
            XmlAttribute valuelistItemDisplayID = doc.CreateAttribute("DisplayID"); //ValuelistItem Owner
            valuelistItemDisplayID.Value = valueListItem.DisplayID.ToString();
            ValueListItem.Attributes.Append(valuelistItemDisplayID);



            //Adding 'Owner' Attribute
            XmlAttribute valuelistItemItemGUID = doc.CreateAttribute("ItemGUID"); //ValuelistItem Owner
            valuelistItemItemGUID.Value = valueListItem.ItemGUID.ToString();
            ValueListItem.Attributes.Append(valuelistItemItemGUID);

            if (node != null)
            {
                //Append the element to XmlDocument
                node.AppendChild(ValueListItem);
            }
        }
        //Convert The innerXml to String
        var xmlString = doc.InnerXml;

        return xmlString;
    }

    #endregion

    #region Get M-File Classes

    /// <summary>
    /// CLR Method to Get All Class details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="classXml"></param>
    /// <param name="classPropertyXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //public static void GetMFClasses(string username, string password, string networkAddress, string vaultName, out string classXml, out string classPropertyXml)
    public static void GetMFClasses(string VaultSettings, out string classXml, out string classPropertyXml)
    {
        classPropertyXml = null;
        classXml = null;

        try
        {
            // MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName); Commented by DevTeam2
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings); //Added by DevTeam2(Rheal) getting vault connection settings in single varible.

            List<ObjectClass> mFClassesList = mFilesAccess.GetAllClasses();
            CreateClassXmlFile(mFilesAccess, mFClassesList, ref classXml, ref classPropertyXml);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// CLR Method to Get specific Class details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="classIds"></param>
    /// <param name="classXml"></param>
    /// <param name="classPropertyXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //public static void GetSpecificMFClasses(string username, string password, string networkAddress, string vaultName, string classIds, out string classXml, out string classPropertyXml)
    public static void GetSpecificMFClasses(string Vaultsettings, string classIds, out string classXml, out string classPropertyXml)
    {
        classPropertyXml = null;
        classXml = null;

        try
        {

            //MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(Vaultsettings);
            List<ObjectClass> mFClassesList = mFilesAccess.GetClasses(classIds);
            CreateClassXmlFile(mFilesAccess, mFClassesList, ref classXml, ref classPropertyXml);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Used to create XML
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="classList"></param>
    /// <param name="classXml"></param>
    /// <param name="classPropertyXml"></param>
    private static void CreateClassXmlFile(MFilesAccess mFilesAccess, List<ObjectClass> classList, ref string classXml, ref string classPropertyXml)
    {
        //Creating XmlDocument
        var classDoc = new XmlDocument();
        var classPropertyDoc = new XmlDocument();

        //Creating XmlElement
        XmlElement classForm = classDoc.CreateElement("form");
        XmlElement classPropertyForm = classPropertyDoc.CreateElement("form");

        //Append the element to XmlDocument
        classDoc.AppendChild(classForm);
        classPropertyDoc.AppendChild(classPropertyForm);

        //Creating XmlNode
        XmlNode classNode = classDoc.SelectSingleNode("form");
        XmlNode classPropertyNode = classPropertyDoc.SelectSingleNode("form");

        foreach (var classDetails in classList)
        {
            //Creating XmlElement
            XmlElement classElement = classDoc.CreateElement("Class");

            //Adding 'ClassID' Attribute
            XmlAttribute MFID = classDoc.CreateAttribute("MFID"); //ClassID
            MFID.Value = classDetails.ID.ToString();
            classElement.Attributes.Append(MFID);

            //Adding 'ClassName' Attribute
            XmlAttribute className = classDoc.CreateAttribute("Name"); //ClassName
            className.Value = classDetails.Name;
            classElement.Attributes.Append(className);

            string alias = mFilesAccess.GetClassAdmin(classDetails.ID).SemanticAliases.Value;
            //Adding 'ClassAliases' Attribute
            XmlAttribute classAliases = classDoc.CreateAttribute("Alias"); //ClassAliases
            classAliases.Value = alias;
            classElement.Attributes.Append(classAliases);

            XmlAttribute objectTypeId = classDoc.CreateAttribute("MFObjectType_ID"); //objectTypeId
            objectTypeId.Value = classDetails.ObjectType.ToString();
            classElement.Attributes.Append(objectTypeId);

            XmlAttribute workflowId = classDoc.CreateAttribute("MFWorkflow_ID"); //workflowId
            workflowId.Value = classDetails.Workflow.ToString();
            classElement.Attributes.Append(workflowId);

            XmlAttribute IsWorkflowEnforced = classDoc.CreateAttribute("IsWorkflowEnforced"); //workflowId
            IsWorkflowEnforced.Value = classDetails.ForceWorkflow.ToString();
            classElement.Attributes.Append(IsWorkflowEnforced);

            XmlAttribute valueListId = classDoc.CreateAttribute("MFValueList_ID"); //MFValueList_ID
            valueListId.Value = "";
            classElement.Attributes.Append(valueListId);


            if (classNode != null)
            {
                //Appending the Element to node
                classNode.AppendChild(classElement);
            }

            //Appending the Element to node
            CreateClassPropertyXml(mFilesAccess, classDetails.AssociatedPropertyDefs, classDetails.ID, ref classPropertyDoc, ref classPropertyNode);

            //Adding The NameOrTitle Property
            XmlElement classPropertyElement = classPropertyDoc.CreateElement("ClassProperty");

            //Set the Assocoiated propertydef 
            SetNameProperty(ref classPropertyDoc, classDetails.AssociatedPropertyDefs, classDetails.ID, classDetails.NamePropertyDef, ref classPropertyElement);

            //GetDetails of objectType
            ObjTypeAdmin objectType = mFilesAccess.GetObjectTypeAdmin(classDetails.ObjectType);

            //If hasOwnerType = True,then it will add ownerPropertyDef
            if (objectType.ObjectType.HasOwnerType)
            {
                ObjTypeAdmin ownerObjectType = mFilesAccess.GetObjectTypeAdmin(objectType.ObjectType.OwnerType);
                SetNameProperty(ref classPropertyDoc, classDetails.AssociatedPropertyDefs, classDetails.ID, ownerObjectType.ObjectType.OwnerPropertyDef, ref classPropertyElement);
            }
            if (classPropertyNode != null)
            {
                //Appending the Element to node
                classPropertyNode.AppendChild(classPropertyElement);
            }
        }
        //Convert The innerXml to String
        classXml = classDoc.InnerXml;
        classPropertyXml = classPropertyDoc.InnerXml;

    }

    private static void SetNameProperty(ref XmlDocument classPropertyDoc, AssociatedPropertyDefs associatedProperties, int classId, int propertyId, ref XmlElement classPropertyElement)
    {
        bool isRequired = false;

        //Adding 'ClassID' Attribute
        XmlAttribute classID = classPropertyDoc.CreateAttribute("classID"); //ClassID
        classID.Value = classId.ToString();
        classPropertyElement.Attributes.Append(classID);

        //Adding 'PropertyID' Attribute
        XmlAttribute propertyID = classPropertyDoc.CreateAttribute("PropertyID"); //PropertyID
        propertyID.Value = propertyId.ToString();
        classPropertyElement.Attributes.Append(propertyID);

        foreach (AssociatedPropertyDef pptDef in associatedProperties)
        {
            if (pptDef.PropertyDef == propertyId)
            {
                isRequired = pptDef.Required;
            }
        }
        XmlAttribute required = classPropertyDoc.CreateAttribute("Required"); //Required
        required.Value = isRequired.ToString();
        classPropertyElement.Attributes.Append(required);
    }

    /// <summary>
    /// Used create XML
    /// </summary>
    /// <param name="mFilesAccess"></param>
    /// <param name="classProperty"></param>
    /// <param name="mFClassID"></param>
    /// <param name="classPropertyDoc"></param>
    /// <param name="node"></param>
    private static void CreateClassPropertyXml(MFilesAccess mFilesAccess, AssociatedPropertyDefs classProperty, int mFClassID, ref XmlDocument classPropertyDoc, ref XmlNode node)
    {
        //List of properties to be excluded
        List<int> externalPptDef = ListOfInternalProperties().ConvertAll(s => int.Parse(s));

        foreach (AssociatedPropertyDef clsPpt in classProperty)
        {
            if (!externalPptDef.Contains(clsPpt.PropertyDef))
            {
                //Creating XmlElement
                XmlElement classElement = classPropertyDoc.CreateElement("ClassProperty");

                //Adding 'ClassID' Attribute
                XmlAttribute classID = classPropertyDoc.CreateAttribute("classID"); //ClassID
                classID.Value = mFClassID.ToString();
                classElement.Attributes.Append(classID);

                //Adding 'PropertyID' Attribute
                XmlAttribute propertyID = classPropertyDoc.CreateAttribute("PropertyID"); //PropertyID
                propertyID.Value = clsPpt.PropertyDef.ToString();
                classElement.Attributes.Append(propertyID);

                XmlAttribute required = classPropertyDoc.CreateAttribute("Required"); //Required
                required.Value = clsPpt.Required.ToString();
                classElement.Attributes.Append(required);

                if (node != null)
                {
                    //Appending the Element to node
                    node.AppendChild(classElement);
                }
            }

        }

    }

    #endregion

    #region Get M-File Workflows

    /// <summary>
    /// Used to get All workflow Details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="workflowXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetMFWorkflow(string username, string password, string networkAddress, string vaultName, out string workflowXml)
    public static void GetMFWorkflow(string VaultSettings, out string workflowXml)
    {
        try
        {
            // MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            List<WorkflowAdmin> mFWorkflows = mFilesAccess.GetAllWorkflows();
            workflowXml = CreateWorkFlowListXmlFile(mFWorkflows);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Used to get specific workflow Details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="workflowIds"></param>
    /// <param name="workflowXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void GetSpecificMFWorkflow(string username, string password, string networkAddress, string vaultName, string workflowIds, out string workflowXml)
    {
        try
        {
            MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            List<WorkflowAdmin> mFWorkflows = mFilesAccess.GetWorkflows(workflowIds);
            workflowXml = CreateWorkFlowListXmlFile(mFWorkflows);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Creates workflow xml file
    /// </summary>
    /// <param name="mFWorkFlowList"></param>
    /// <returns></returns>
    private static string CreateWorkFlowListXmlFile(List<WorkflowAdmin> mFWorkFlowList)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        foreach (WorkflowAdmin workflowDetails in mFWorkFlowList)
        {
            //Creating XmlDocument
            XmlElement workflow = doc.CreateElement("Workflow");

            //Adding 'WorkflowID' Attribute
            XmlAttribute workflowID = doc.CreateAttribute("MFID"); //ValueListID
            workflowID.Value = workflowDetails.Workflow.ID.ToString();
            workflow.Attributes.Append(workflowID);

            //Adding 'WorkflowName' Attribute
            XmlAttribute workflowName = doc.CreateAttribute("Name"); //WorkflowName
            workflowName.Value = workflowDetails.Workflow.Name;
            workflow.Attributes.Append(workflowName);

            //Adding 'WorkflowAlias' Attribute
            XmlAttribute workflowAlias = doc.CreateAttribute("Alias"); //WorkflowAlias
            workflowAlias.Value = workflowDetails.SemanticAliases.Value;
            workflow.Attributes.Append(workflowAlias);

            if (node != null)
            {
                //Append the element to XmlDocument
                node.AppendChild(workflow);
            }
        }
        //Convert The innerXml to String
        var xmlString = doc.InnerXml;

        return xmlString;
    }

    #endregion

    #region GET M-File Workflow States

    /// <summary>
    /// Used to get workflow state Details from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="workflowIds"></param>
    /// <param name="workflowStatesXml"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //  public static void GetWorkflowStates(string username, string password, string networkAddress, string vaultName, string workflowIds, out string workflowStatesXml)
    public static void GetWorkflowStates(string VaultSettings, string workflowIds, out string workflowStatesXml)
    {
        try
        {
            //MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            List<States> mFWorkflowStates = mFilesAccess.GetAllWorkflowStates(workflowIds);
            workflowStatesXml = CreateWorkFlowStateXmlFile(mFWorkflowStates, workflowIds, mFilesAccess);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Creates the workflow xml file to get workflow state details from 
    /// </summary>
    /// <param name="mFWorkFlowStateList"></param>
    /// <returns></returns>
    private static string CreateWorkFlowStateXmlFile(List<States> mFWorkFlowStateList, string workflowIds, MFilesAccess mFilesAccess)
    {
        string[] ids = workflowIds.Split(new string[] { "," }, StringSplitOptions.None);

        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        int count = 0;

        foreach (States statesList in mFWorkFlowStateList)
        {
            foreach (State stateDetails in statesList)
            {
                //Creating XmlDocument
                XmlElement workflowState = doc.CreateElement("WorkflowState");

                //Adding 'WorkflowStateID' Attribute
                XmlAttribute workflowID = doc.CreateAttribute("MFWorkflowID"); //WorkflowID
                workflowID.Value = ids[count].ToString();
                workflowState.Attributes.Append(workflowID);

                //Adding 'WorkflowStateID' Attribute
                XmlAttribute workflowStateID = doc.CreateAttribute("MFID"); //WorkflowStateID
                workflowStateID.Value = stateDetails.ID.ToString();
                workflowState.Attributes.Append(workflowStateID);

                //Adding 'WorkflowStateName' Attribute
                XmlAttribute workflowStateName = doc.CreateAttribute("Name"); //WorkflowStateName
                workflowStateName.Value = stateDetails.Name;
                workflowState.Attributes.Append(workflowStateName);

                //Adding 'WorkflowStateAlias' Attribute
                XmlAttribute workflowStateAlias = doc.CreateAttribute("Alias"); //WorkflowStateAlias
                //workflowStateAlias.Value = ""; 
                workflowStateAlias.Value = mFilesAccess.GetWorkFlowStateAlias(Convert.ToInt32(workflowID.Value), stateDetails.ID);
                workflowState.Attributes.Append(workflowStateAlias);

                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(workflowState);
                }
            }
            count++;
        }
        //Convert The innerXml to String
        var xmlString = doc.InnerXml;

        return xmlString;
    }

    #endregion

    #region Get M-File User Accounts
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetUserAccounts(string username, string password, string networkAddress, string vaultName, out string userAccountsXml)
    public static void GetUserAccounts(string VaultSettings, out string userAccountsXml)
    {
        userAccountsXml = null;

        try
        {
            //MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            UserAccounts userAccounts = mFilesAccess.GetUserAccounts();
            CreateUserAccountsXmlFile(mFilesAccess, userAccounts, ref userAccountsXml);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    private static void CreateUserAccountsXmlFile(MFilesAccess mFilesAccess, UserAccounts userAccounts, ref string userAccountsXml)
    {
        //Creating XmlDocument
        var userAccountDoc = new XmlDocument();

        //Creating XmlElement
        XmlElement classForm = userAccountDoc.CreateElement("form");

        //Append the element to XmlDocument
        userAccountDoc.AppendChild(classForm);

        //Creating XmlNode
        XmlNode userAccountNode = userAccountDoc.SelectSingleNode("form");

        foreach (UserAccount userAccount in userAccounts)
        {
            //Creating XmlElement
            XmlElement userAccountElement = userAccountDoc.CreateElement("UserAccount");

            //Adding 'ID' Attribute
            XmlAttribute MFID = userAccountDoc.CreateAttribute("MFID"); //ID
            MFID.Value = userAccount.ID.ToString();
            userAccountElement.Attributes.Append(MFID);

            //Adding 'loginName' Attribute
            XmlAttribute loginName = userAccountDoc.CreateAttribute("LoginName"); //loginName
            loginName.Value = userAccount.LoginName;
            userAccountElement.Attributes.Append(loginName);

            //Adding 'ClassAliases' Attribute
            XmlAttribute internalUser = userAccountDoc.CreateAttribute("InternalUser"); //internalUser
            internalUser.Value = userAccount.InternalUser.ToString();
            userAccountElement.Attributes.Append(internalUser);

            XmlAttribute enabled = userAccountDoc.CreateAttribute("Enabled"); //Enabled
            enabled.Value = userAccount.Enabled.ToString();
            userAccountElement.Attributes.Append(enabled);

            if (userAccountNode != null)
            {
                //Appending the Element to node
                userAccountNode.AppendChild(userAccountElement);
            }

        }
        //Convert The innerXml to String
        userAccountsXml = userAccountDoc.InnerXml;

    }

    #endregion

    #region Get M-Files Login Accounts
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void GetLoginAccounts(string username, string password, string networkAddress, string vaultName, out string loginAccountsXml)
    public static void GetLoginAccounts(string VaultSettings, out string loginAccountsXml)
    {
        loginAccountsXml = null;

        try
        {
            //MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            LoginAccounts loginAccounts = mFilesAccess.GetLoginAccounts();
            UserAccounts UserAccs = mFilesAccess.GetUserAccounts();
            CreateLoginAccountsXmlFile(mFilesAccess, loginAccounts, ref loginAccountsXml, UserAccs);
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    private static void CreateLoginAccountsXmlFile(MFilesAccess mFilesAccess, LoginAccounts loginAccounts, ref string loginAccountsXml, UserAccounts UserAccs)
    {
        //Creating XmlDocument
        var loginAccountDoc = new XmlDocument();

        //Creating XmlElement
        XmlElement loginForm = loginAccountDoc.CreateElement("form");

        //Append the element to XmlDocument
        loginAccountDoc.AppendChild(loginForm);

        //Creating XmlNode
        XmlNode loginAccountNode = loginAccountDoc.SelectSingleNode("form");

        foreach (LoginAccount loginAccount in loginAccounts)
        {

            //added for  adding userid column in mfllogin table 
            int UserMFID = 0;
            foreach (UserAccount U in UserAccs)
            {
                if (U.LoginName == loginAccount.AccountName) UserMFID = U.ID;

            }   //added for  adding userid column in mfllogin table 


            //Creating XmlElement
            XmlElement loginAccountElement = loginAccountDoc.CreateElement("loginAccount");


            //Adding 'AccountName' Attribute
            XmlAttribute UserId = loginAccountDoc.CreateAttribute("UserID"); //  //added for  adding userid column in mfllogin table 
            UserId.Value = UserMFID.ToString();
            loginAccountElement.Attributes.Append(UserId);

            //Adding 'AccountName' Attribute
            XmlAttribute accountName = loginAccountDoc.CreateAttribute("AccountName"); //AccountName
            accountName.Value = loginAccount.AccountName.ToString();
            loginAccountElement.Attributes.Append(accountName);

            //Adding 'AccountType' Attribute
            XmlAttribute accountType = loginAccountDoc.CreateAttribute("AccountType"); //AccountType
            accountType.Value = loginAccount.AccountType.ToString();
            loginAccountElement.Attributes.Append(accountType);

            //Adding 'DomainName' Attribute
            XmlAttribute domainName = loginAccountDoc.CreateAttribute("DomainName"); //DomainName
            if (loginAccount.DomainName == null)
            {
                domainName.Value = "";
            }
            else
            {
                domainName.Value = loginAccount.DomainName.ToString();
            }

            loginAccountElement.Attributes.Append(domainName);

            XmlAttribute emailAddress = loginAccountDoc.CreateAttribute("EmailAddress"); //EmailAddress
            emailAddress.Value = loginAccount.EmailAddress.ToString();
            loginAccountElement.Attributes.Append(emailAddress);

            XmlAttribute enabled = loginAccountDoc.CreateAttribute("Enabled"); //Enabled
            enabled.Value = loginAccount.Enabled.ToString();
            loginAccountElement.Attributes.Append(enabled);

            XmlAttribute fullName = loginAccountDoc.CreateAttribute("FullName"); //fullName
            fullName.Value = loginAccount.FullName.ToString();
            loginAccountElement.Attributes.Append(fullName);

            XmlAttribute licenseType = loginAccountDoc.CreateAttribute("LicenseType"); //licenseType
            licenseType.Value = loginAccount.LicenseType.ToString();
            loginAccountElement.Attributes.Append(licenseType);

            XmlAttribute userName = loginAccountDoc.CreateAttribute("UserName"); //UserName
            userName.Value = loginAccount.UserName.ToString();
            loginAccountElement.Attributes.Append(userName);

            if (loginAccountNode != null)
            {
                //Appending the Element to node
                loginAccountNode.AppendChild(loginAccountElement);
            }

        }
        //Convert The innerXml to String
        loginAccountsXml = loginAccountDoc.InnerXml;

    }

    #endregion

    #region Delete M-File Object

    /// <summary>
    /// Used to delete an Object from M-Files
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="objectTypeID"></param>
    /// <param name="objId"></param>
    /// <param name="output"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void DeleteObject(string username, string password, string networkAddress, string vaultName, int objectTypeID, int objId, out string output)
    public static void DeleteObject(string VaultSettings, int objectTypeID, int objId, bool DeleteWithDestroy, int ObjectVersion, out string output)
    {
        try
        {
            ObjID objectId = new ObjID();
            objectId.ID = objId;
            objectId.Type = objectTypeID;

            //MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            string xmlOut=  mFilesAccess.DeleteObject(objectId, DeleteWithDestroy, ObjectVersion);
            output = xmlOut;
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            if (ex.Message.Contains("The object has been removed")) //bug 1215 changes
            {
                output=CreateDeleteObjXML(objId, ObjectVersion,4 , "Failure object does not exist");
            }
            else if(ex.Message.Contains("Not found"))
            {
                output=CreateDeleteObjXML(objId, ObjectVersion, 5, "Failure object version does not exist");
            }
            else if (ex.Message.Contains("Destroying the latest checked-in version of an object is not allowed"))
            {
                output = CreateDeleteObjXML(objId, ObjectVersion, 6, "Failure destroy latest object version not allowed");
            }
            else
            throw;
        }

    }

    #endregion

    #region Create public shared link
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void GetPublicSharedLink(string VaultSettings, string XML, out string OutputXml)
    {
        OutputXml = string.Empty;
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);

        if (!string.IsNullOrEmpty(XML))
        {
            XmlSerializer serializer = new XmlSerializer(typeof(XMLObjLinkDef.PublicSharedLinkCollection));
            StringReader reader = new StringReader(XML);
            XMLObjLinkDef.PublicSharedLinkCollection psCollection = (XMLObjLinkDef.PublicSharedLinkCollection)serializer.Deserialize(reader);
            reader.Close();
            foreach (XMLObjLinkDef.ObjectDef ObjDef in psCollection.LstVObjectDef)
            {
                //mFilesAccess.UpdateWorkFlowAliasAndName(ObjDef);
                ObjDef.AccessKey = mFilesAccess.GetPublicLink(ObjDef.ID, Convert.ToDateTime(ObjDef.ExpiryDate).Day, Convert.ToDateTime(ObjDef.ExpiryDate).Month, Convert.ToDateTime(ObjDef.ExpiryDate).Year);

            }
            mFilesAccess.LogOut();
            var doc = new XmlDocument();
            string strDebug = "starts ";
            //Creating XmlElement
            XmlElement form = doc.CreateElement("form");

            //Append the element to XmlDocument
            doc.AppendChild(form);

            //Creating XmlNode
            XmlNode node = doc.SelectSingleNode("form");

            for (int i = 0; i < psCollection.LstVObjectDef.Count; i++)
            {
                XmlElement searchObject = doc.CreateElement("ObjectDetails");

                //Store current objVer value to log in case of error


                //Adding 'objectId' Attribute
                XmlAttribute ID = doc.CreateAttribute("ID"); //objectId
                ID.Value = Convert.ToString(psCollection.LstVObjectDef[i].ID);
                searchObject.Attributes.Append(ID);

                XmlAttribute ExpiryDate = doc.CreateAttribute("ExpiryDate");
                ExpiryDate.Value = Convert.ToString(psCollection.LstVObjectDef[i].ExpiryDate);
                searchObject.Attributes.Append(ExpiryDate);

                XmlAttribute AccessKey = doc.CreateAttribute("AccessKey");
                AccessKey.Value = psCollection.LstVObjectDef[i].AccessKey;
                searchObject.Attributes.Append(AccessKey);

                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(searchObject);
                }
            }

            OutputXml = doc.InnerXml;

        }

    }
    #endregion

    #region Import File
    //Task #1202
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void Importfile(string VaultSettings, string FileName, string PrpertyXML, string FilePath, out string OutputXml, out string ErrorMsg, int IsFileDelete)
    {
        try
        {


            //  Data = null;
            String FchkSum = string.Empty;
            OutputXml = string.Empty;
            ErrorMsg = string.Empty;
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            Boolean IsSubFolder = false;
            List<string> LstsubFolderFile = new List<string>();
            string FileCheckSum = string.Empty;

            if (!string.IsNullOrEmpty(FileName))
            {

                //XmlSerializer serializer = new XmlSerializer(typeof(XMLFile.FileListItemDetails));
                //StringReader reader = new StringReader(XML);
                //XMLFile.FileListItemDetails objectDetailCollection = (XMLFile.FileListItemDetails)serializer.Deserialize(reader);
                //reader.Close();

                XmlSerializer serializer1 = new XmlSerializer(typeof(XMLClass.ObjectDetailsCollection));
                StringReader reader1 = new StringReader(PrpertyXML);
                XMLClass.ObjectDetailsCollection objectDetailCollection1 = (XMLClass.ObjectDetailsCollection)serializer1.Deserialize(reader1);
                reader1.Close();

                //foreach (XMLFile.FileListItem Item in objectDetailCollection.FileList)
                //{
                int FileObjectID = 0;
                string str = string.Empty;
                string Root = FilePath;
                string folder = Path.Combine(Root, "");
                if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
                string file = Path.Combine(folder, FileName);

                ObjVer objVer = new ObjVer();
                ObjectVersion objectVersion = null;

                if (File.Exists(file))
                {

                    if (objectDetailCollection1.Object[0].objID > 0)
                    {
                        objVer.ID = objectDetailCollection1.Object[0].objID;
                        objVer.Type = objectDetailCollection1.Object[0].id;
                        objVer.ObjID.ID = objectDetailCollection1.Object[0].objID;
                        objVer.ObjID.Type = objectDetailCollection1.Object[0].id;
                        objVer.Version = objectDetailCollection1.Object[0].objVesrion;
                        DataTable dtDeleted = null;
                        ObjVer latestObjVer = GetlatestVersion(mFilesAccess, dtDeleted, objVer);

                        int iCurrentVersion = objVer.Version;


                        if (objVer.Version == latestObjVer.Version)
                        {
                            string TempFolder = Path.Combine(Root, "Temp");
                            if (!Directory.Exists(TempFolder)) Directory.CreateDirectory(TempFolder);
                            string ObjIDfolder = Path.Combine(Root, objectDetailCollection1.Object[0].objID.ToString());
                            if (Directory.Exists(ObjIDfolder))
                            {

                                int Filecount = (Directory.GetFiles(ObjIDfolder).Length);

                                if (Filecount > 0)
                                {
                                    IsSubFolder = true;
                                    string[] Files = Directory.GetFiles(ObjIDfolder);

                                    foreach (string strFileName in Files)
                                    {
                                        FileCheckSum = mFilesAccess.GetFileChecksum(Path.Combine(ObjIDfolder, strFileName), new MD5CryptoServiceProvider());
                                        mFilesAccess.UpdateImportFileObject(ref objVer, ref objectVersion, strFileName, Path.Combine(ObjIDfolder, strFileName), objectDetailCollection1.Object[0], ref FileObjectID, FileCheckSum, TempFolder, ref FchkSum);
                                        LstsubFolderFile.Add(strFileName + "|" + FileObjectID.ToString() + "|" + FileCheckSum);
                                        if (IsFileDelete > 0) System.IO.File.Delete(Path.Combine(ObjIDfolder, strFileName));
                                    }
                                }

                            }
                            else
                            {

                                FileCheckSum = mFilesAccess.GetFileChecksum(file, new MD5CryptoServiceProvider());
                                mFilesAccess.UpdateImportFileObject(ref objVer, ref objectVersion, FileName, file, objectDetailCollection1.Object[0], ref FileObjectID, FileCheckSum, TempFolder, ref FchkSum);
                                if (IsFileDelete > 0) System.IO.File.Delete(file);
                            }

                        }
                        else
                        {
                            ErrorMsg = " M-Files has different version than SQL Objid= " + objVer.ID.ToString();
                            throw new Exception(" M-Files has different version than SQL Objid= " + objVer.ID.ToString()); //Added by rheal for task 1097
                        }
                    }
                    else
                    {
                        string TempFolder = Path.Combine(Root, "Temp");
                        if (!Directory.Exists(TempFolder)) Directory.CreateDirectory(TempFolder);
                        FchkSum = FileCheckSum;
                        // mFilesAccess.CreateObject(ref objVer, ref objectVersion, Item, file, objectDetailCollection1.Object[0], ref FileObjectID, TempFolder, ref FchkSum);
                    }
                    if (!IsSubFolder)
                        OutputXml = CreateImportFileXml(objectVersion, FileName, FileObjectID, FchkSum);
                    else
                        OutputXml = CreateImportFileXml(objectVersion, LstsubFolderFile);


                    if (Directory.Exists(Path.Combine(Root, "Temp"))) Directory.Delete(Path.Combine(Root, "Temp"));
                    //mFilesAccess.ImportFile(Item, file, objVer);
                    //}

                }
                else
                {
                    throw new Exception("File not found at location " + file);
                }

            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            //Added Rheal for task #1368
            ErrorMsg = ex.ToString();
            throw ex;
        }
    }



    private static string CreateImportFileXml(ObjectVersion ObjVersion, string Filename, int FileObjectID, string FileCheckSum)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {

            XmlElement searchObject = doc.CreateElement("Object");

            //Adding 'objectId' Attribute


            XmlAttribute FileName = doc.CreateAttribute("FileName"); //FileName
            FileName.Value = Filename.ToString();
            searchObject.Attributes.Append(FileName);

            XmlAttribute FileUniqueRef = doc.CreateAttribute("FileUniqueRef"); //FileUniqueRef
            FileUniqueRef.Value = "";
            searchObject.Attributes.Append(FileUniqueRef);

            XmlAttribute TargetClassID = doc.CreateAttribute("TargetClassID"); //FileUniqueRef
            TargetClassID.Value = "1";
            searchObject.Attributes.Append(TargetClassID);

            XmlAttribute MFFileObjectID = doc.CreateAttribute("FileObjectID"); //FileObjectID
            MFFileObjectID.Value = FileObjectID.ToString();
            searchObject.Attributes.Append(MFFileObjectID);

            XmlAttribute FileCheck_Sum = doc.CreateAttribute("FileCheckSum"); //FileCheckSum
            FileCheck_Sum.Value = FileCheckSum.ToString();
            searchObject.Attributes.Append(FileCheck_Sum);

            XmlAttribute MFCreated = doc.CreateAttribute("MFCreated"); //MFCreated
            MFCreated.Value = ObjVersion != null ? ObjVersion.CreatedUtc.ToString() : null;
            searchObject.Attributes.Append(MFCreated);


            XmlAttribute MFLastModified = doc.CreateAttribute("MFLastModified"); //MFLastModified
            MFLastModified.Value = ObjVersion != null ? ObjVersion.LastModifiedUtc.ToString() : null;
            searchObject.Attributes.Append(MFLastModified);

            XmlAttribute ObjID = doc.CreateAttribute("ObjID"); //ObjID
            ObjID.Value = ObjVersion != null ? ObjVersion.ObjVer.ID.ToString() : null;
            searchObject.Attributes.Append(ObjID);

            XmlAttribute ObjVer = doc.CreateAttribute("ObjVer"); //ObjVer
            ObjVer.Value = ObjVersion != null ? ObjVersion.ObjVer.Version.ToString() : null;
            searchObject.Attributes.Append(ObjVer);

            if (node != null)
            {
                //Append the element to XmlDocument
                node.AppendChild(searchObject);
            }

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    private static string CreateImportFileXml(ObjectVersion ObjVersion, List<string> SubFolderFileList)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {

            foreach (string fileItem in SubFolderFileList)
            {
                string[] FileDetails = fileItem.Split('|');
                XmlElement searchObject = doc.CreateElement("Object");
                //Adding 'objectId' Attribute


                XmlAttribute FileName = doc.CreateAttribute("FileName"); //FileName
                FileName.Value = FileDetails[0].ToString();
                searchObject.Attributes.Append(FileName);

                XmlAttribute FileUniqueRef = doc.CreateAttribute("FileUniqueRef"); //FileUniqueRef
                FileUniqueRef.Value = "";
                searchObject.Attributes.Append(FileUniqueRef);

                XmlAttribute TargetClassID = doc.CreateAttribute("TargetClassID"); //FileUniqueRef
                TargetClassID.Value = "1";
                searchObject.Attributes.Append(TargetClassID);

                XmlAttribute MFFileObjectID = doc.CreateAttribute("FileObjectID"); //FileObjectID
                MFFileObjectID.Value = FileDetails[1].ToString();
                searchObject.Attributes.Append(MFFileObjectID);

                XmlAttribute FileCheck_Sum = doc.CreateAttribute("FileCheckSum"); //FileCheckSum
                FileCheck_Sum.Value = FileDetails[2].ToString();
                searchObject.Attributes.Append(FileCheck_Sum);

                XmlAttribute MFCreated = doc.CreateAttribute("MFCreated"); //MFCreated
                MFCreated.Value = ObjVersion != null ? ObjVersion.CreatedUtc.ToString() : null;
                searchObject.Attributes.Append(MFCreated);


                XmlAttribute MFLastModified = doc.CreateAttribute("MFLastModified"); //MFLastModified
                MFLastModified.Value = ObjVersion != null ? ObjVersion.LastModifiedUtc.ToString() : null;
                searchObject.Attributes.Append(MFLastModified);

                XmlAttribute ObjID = doc.CreateAttribute("ObjID"); //ObjID
                ObjID.Value = ObjVersion != null ? ObjVersion.ObjVer.ID.ToString() : null;
                searchObject.Attributes.Append(ObjID);

                XmlAttribute ObjVer = doc.CreateAttribute("ObjVer"); //ObjVer
                ObjVer.Value = ObjVersion != null ? ObjVersion.ObjVer.Version.ToString() : null;
                searchObject.Attributes.Append(ObjVer);

                if (node != null)
                {
                    //Append the element to XmlDocument
                    node.AppendChild(searchObject);
                }
            }

        }
        catch (Exception)
        {
            throw;
        }

        return doc.InnerXml;
    }

    #endregion

    #region Search For Object

    /// <summary>
    /// CLR method to search for objects in M-Files by Class ID and search text
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="classId"></param>
    /// <param name="searchText"></param>
    /// <param name="count"></param>
    /// <param name="resultXml"></param>
    /// <param name="isFound"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    // public static void SearchForObject(string username, string password, string networkAddress, string vaultName, int classId, string searchText, int count, out string resultXml, out bool isFound)
    public static void SearchForObject(string VaultSettings, int classId, string searchText, int count, out string resultXml, out bool isFound)
    {
        resultXml = "No result Found..!!!";
        isFound = false;

        try
        {
            // MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);

            // mFilesAccess.UploadFile(1, 1, "");
            SearchConditions searchConditions = new SearchConditions();

            SetSearchConditionForClass(classId, null, ref searchConditions);

            if (searchText != null && searchText != "*")
            {
                SetSearchConditionForProperty(mFilesAccess, searchText, 0, ref searchConditions);
            }

            ObjVers objVers = new ObjVers();

            PropertyValuesOfMultipleObjects objectSearchResult = mFilesAccess.SearchForObject(searchConditions, count, ref objVers);

            if (objectSearchResult.Count > 0)
            {
                GetObjectsDetails(mFilesAccess, objVers, objectSearchResult, classId, out resultXml);
                isFound = true;
            }
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// CLR method to search for objects in M-Files by Class ID and property value
    /// </summary>
    /// <param name="username"></param>
    /// <param name="password"></param>
    /// <param name="networkAddress"></param>
    /// <param name="vaultName"></param>
    /// <param name="classId"></param>
    /// <param name="propertyIds"></param>
    /// <param name="propertyValues"></param>
    /// <param name="count"></param>
    /// <param name="resultXml"></param>
    /// <param name="isFound"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //public static void SearchForObjectByProperties(string username, string password, string networkAddress, string vaultName, int classId, string propertyIds, string propertyValues, int count, out string resultXml, out bool isFound)
    public static void SearchForObjectByProperties(string VaultSettings, int classId, string propertyIds, string propertyValues, int count,int IsEqual , out string resultXml, out bool isFound)
    {
        resultXml = "No result Found..!!!";
        isFound = false;

        try
        {
            SearchConditions searchConditions;

            //MFilesAccess mFilesAccess = GetMFilesAccess(username, password, networkAddress, vaultName);
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);

            if (classId != -1)
            {
                searchConditions = SearchForObjectWithClassId(classId, propertyIds, propertyValues, mFilesAccess, IsEqual);
            }
            else
            {
                searchConditions = SearchForObjectWithOutClassId(propertyIds, propertyValues, mFilesAccess, IsEqual);
            }
            ObjVers objVers = new ObjVers();

            PropertyValuesOfMultipleObjects objectSearchResult = mFilesAccess.SearchForObject(searchConditions, count, ref objVers);

            if (objectSearchResult.Count > 0)
            {
                GetObjectsDetails(mFilesAccess, objVers, objectSearchResult, classId, out resultXml);
                isFound = true;
            }
            mFilesAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }
    }

    /// <summary>
    /// Used to create Search Condition for Property
    /// </summary>
    /// <param name="propertyIds"></param>
    /// <param name="propertyValues"></param>
    /// <param name="mFilesAccess"></param>
    /// <returns></returns>
    private static SearchConditions SearchForObjectWithOutClassId(string propertyIds, string propertyValues, MFilesAccess mFilesAccess,int IsEqual)
    {

        SearchConditions searchConditions = new SearchConditions();

        string[] ids = propertyIds.Split(new string[] { "," }, StringSplitOptions.None);
        string[] values = propertyValues.Split(new string[] { "," }, StringSplitOptions.None);

        int i = 0;

        foreach (var id in ids)
        {
            SetSearchConditionForProperty(mFilesAccess, values[i], Convert.ToInt32(id), ref searchConditions, IsEqual);

            i++;
        }
        return searchConditions;
    }

    /// <summary>
    /// Used to create Search Condition for Class
    /// </summary>
    /// <param name="classId"></param>
    /// <param name="propertyIds"></param>
    /// <param name="propertyValues"></param>
    /// <param name="mFilesAccess"></param>
    /// <returns></returns>
    private static SearchConditions SearchForObjectWithClassId(int classId, string propertyIds, string propertyValues, MFilesAccess mFilesAccess,int IsEqual)
    {
        ObjectClass objectClass = mFilesAccess.GetClass(classId);
        List<int> classProperties = GetClassExtenalProperties(mFilesAccess, objectClass);

        SearchConditions searchConditions = new SearchConditions();

        SetSearchConditionForClass(classId, null, ref searchConditions);

        string[] ids = propertyIds.Split(new string[] { "," }, StringSplitOptions.None);
        string[] values = propertyValues.Split(new string[] { "," }, StringSplitOptions.None);

        int i = 0;

        foreach (var id in ids)
        {
            if (classProperties.Contains(Convert.ToInt32(id)))
            {
                SetSearchConditionForProperty(mFilesAccess, values[i], Convert.ToInt32(id), ref searchConditions, IsEqual);
            }
            else
            {
                string errorMsg = "The property ID '{0}' is not associated with {1} class or Not Exists in M-Files";
                string message = string.Format(errorMsg, id, objectClass.Name);
                throw new Exception(message);
            }
            i++;
        }
        return searchConditions;
    }

    private static void SetSearchConditionForProperty(MFilesAccess mFilesAccess, string searchText, int propertyId, ref SearchConditions searchConditions,int IsEqual=0)
    {
        SearchCondition searchCondition = new SearchCondition();
        searchCondition.Expression.DataPropertyValuePropertyDef = propertyId;  //MFBuiltInPropertyDef.MFBuiltInPropertyDefNameOrTitle;
        MFDataType dataType = mFilesAccess.GetPropertyDefAdmin(propertyId).PropertyDef.DataType;

        //If dataType is Boolean or LookUp then ConditionType is MFConditionTypeEqual
        if ((dataType == MFDataType.MFDatatypeText || dataType == MFDataType.MFDatatypeMultiLineText) && IsEqual==0)
        {
            searchCondition.ConditionType = MFConditionType.MFConditionTypeContains;
        }
        else
        {
            //Else ConditionType is MFConditionTypeEqual
            searchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
        }
        object searchValue = mFilesAccess.GetDataValueBasedOnDataType(propertyId, mFilesAccess.GetPropertyDef(propertyId).DataType, searchText);
        searchCondition.TypedValue.SetValue(dataType, searchValue);
        searchConditions.Add(-1, searchCondition);
    }

    /// <summary>
    /// Set Search Conditions(classId and CheckedOut = False)
    /// </summary>
    /// <param name="classId"></param>
    /// <param name="searchConditions"></param>
    private static void SetSearchConditionForClass(int classId, DateTime? dtLastModified, ref SearchConditions searchConditions)
    {
        //Search with ClassID
        SearchCondition objectTypeCondition = new SearchCondition();
        objectTypeCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
        objectTypeCondition.Expression.DataPropertyValuePropertyDef = 100;
        objectTypeCondition.TypedValue.SetValue(MFDataType.MFDatatypeLookup, classId);
        searchConditions.Add(-1, objectTypeCondition);

        //search for CheckedIn objects
        SearchCondition checkIn = new SearchCondition();
        checkIn.ConditionType = MFConditionType.MFConditionTypeEqual;
        checkIn.Expression.DataStatusValueType = MFStatusType.MFStatusTypeCheckedOut;
        checkIn.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, false);
        searchConditions.Add(-1, checkIn);

        SearchCondition deleted = new SearchCondition();
        deleted.ConditionType = MFConditionType.MFConditionTypeEqual;
        deleted.Expression.DataStatusValueType = MFStatusType.MFStatusTypeDeleted;
        deleted.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, false);
        searchConditions.Add(-1, deleted);


        if (dtLastModified != null)
        {
            SearchCondition checkCondition = new SearchCondition();
            checkCondition.ConditionType = MFConditionType.MFConditionTypeGreaterThanOrEqual;
            checkCondition.Expression.DataPropertyValuePropertyDef = 21;
            checkCondition.TypedValue.SetValue(MFDataType.MFDatatypeTimestamp, dtLastModified);
            searchConditions.Add(-1, checkCondition);
        }

    }
    private static void SetSearchConditionForDeleted(int classId, DateTime? dtLastModified, ref SearchConditions searchConditions)
    {
        //Search with ClassID
        SearchCondition objectTypeCondition = new SearchCondition();
        objectTypeCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
        objectTypeCondition.Expression.DataPropertyValuePropertyDef = 100;
        objectTypeCondition.TypedValue.SetValue(MFDataType.MFDatatypeLookup, classId);
        searchConditions.Add(-1, objectTypeCondition);


        //SearchCondition deleted = new SearchCondition();
        //deleted.ConditionType = MFConditionType.MFConditionTypeEqual;
        //deleted.Expression.DataStatusValueType = MFStatusType.MFStatusTypeDeleted;
        //deleted.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, true);
        //searchConditions.Add(-1, deleted);


        SearchCondition deletedTimeStamp = new SearchCondition();
        deletedTimeStamp.ConditionType = MFConditionType.MFConditionTypeNotEqual;
        deletedTimeStamp.Expression.DataPropertyValuePropertyDef = 27;
        deletedTimeStamp.TypedValue.SetValue(MFDataType.MFDatatypeTimestamp, null);
        searchConditions.Add(-1, deletedTimeStamp);

        if (dtLastModified != null)
        {
            SearchCondition checkCondition = new SearchCondition();
            checkCondition.ConditionType = MFConditionType.MFConditionTypeGreaterThanOrEqual;
            checkCondition.Expression.DataPropertyValuePropertyDef = 21;
            checkCondition.TypedValue.SetValue(MFDataType.MFDatatypeTimestamp, dtLastModified);
            searchConditions.Add(-1, checkCondition);
        }


    }


    /// <summary>
    /// Get the property details in XML format
    /// </summary>
    /// <param name="mFileAccess"></param>
    /// <param name="objVers"></param>
    /// <param name="pptOfMultipleObjects"></param>
    /// <param name="classId"></param>
    /// <param name="resultXml"></param>
    private static void GetObjectsDetails(MFilesAccess mFileAccess, ObjVers objVers, PropertyValuesOfMultipleObjects pptOfMultipleObjects, int classId, out string resultXml)
    {
        resultXml = null;

        //Remove the internal property id's from ClassProperties
        List<int> externalPptDef = ListOfInternalProperties().ConvertAll(s => int.Parse(s));

        if (classId != -1)
        {
            AddNamePropertyDef(mFileAccess, classId, ref externalPptDef);
        }
        else
        {
            externalPptDef.Remove(0);
        }

        if (pptOfMultipleObjects != null && pptOfMultipleObjects.Count > 0)
        {
            resultXml = CreateSearchResultXml(pptOfMultipleObjects, objVers, externalPptDef);
        }
    }

    private static void AddNamePropertyDef(MFilesAccess mFileAccess, int classId, ref List<int> externalPptDef)
    {
        //Getting name propertyDef of the class
        int nameProperty = mFileAccess.GetClass(classId).NamePropertyDef;

        //If namePropertyDef exists in externalPropertyDef removing from the list
        if (externalPptDef.Contains(nameProperty))
        {
            externalPptDef.Remove(nameProperty);
        }
    }

    private static List<ObjectVersionAndProperties> GetSearchResultObjectProperties(MFilesAccess mFileAccess, ObjectSearchResults searchResults)
    {
        List<ObjectVersionAndProperties> pptValues = new List<ObjectVersionAndProperties>();
        try
        {
            if (searchResults != null)
            {
                // the code that you want to measure comes here               
                foreach (ObjectVersion objVersion in searchResults)
                {
                    ObjID objID = null;
                    ObjectVersionAndProperties objectProperties = mFileAccess.GetObjectVersionAndProperties(objVersion.ObjVer, ref objID);
                    pptValues.Add(objectProperties);
                }

                //xml = CreateSearchResultXml(mFileAccess,pptValues);
            }
        }
        catch (Exception)
        {
            throw;
        }
        return pptValues;
    }

    /// <summary>
    /// Used to create XML
    /// </summary>
    /// <param name="pptOfMultipleObjects"></param>
    /// <param name="objVers"></param>
    /// <param name="externalPptDef"></param>
    /// <returns></returns>
    private static string CreateSearchResultXml(PropertyValuesOfMultipleObjects pptOfMultipleObjects, ObjVers objVers, List<int> externalPptDef)
    {
        //Used to store running object details
        ObjVer currentObjVer = new ObjVer();
        PropertyValue currentPropertyValue = new PropertyValue();

        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        try
        {
            for (int i = 1; i <= pptOfMultipleObjects.Count; i++)
            {
                //if (pptOfMultipleObjects[i].IndexOf(37) == -1 )
                {
                    //storing current objVer to log in case of error
                    currentObjVer = objVers[i];

                    XmlElement searchObject = doc.CreateElement("Object");

                    //Adding 'objectId' Attribute
                    XmlAttribute objectId = doc.CreateAttribute("objectId"); //objectId
                    objectId.Value = Convert.ToString(objVers[i].ID);
                    searchObject.Attributes.Append(objectId);

                    XmlAttribute objVersion = doc.CreateAttribute("objVersion");
                    objVersion.Value = Convert.ToString(objVers[i].Version);
                    searchObject.Attributes.Append(objVersion);

                    foreach (PropertyValue propertyValue in pptOfMultipleObjects[i])
                    {
                        if (!externalPptDef.Contains(propertyValue.PropertyDef))
                        {
                            //storing current property details to log in case of error
                            currentPropertyValue = propertyValue;

                            XmlElement properties = doc.CreateElement("properties");

                            XmlAttribute propertyId = doc.CreateAttribute("propertyId"); //propertyId
                            propertyId.Value = propertyValue.PropertyDef.ToString();
                            properties.Attributes.Append(propertyId);

                            XmlAttribute dataType = doc.CreateAttribute("dataType"); //dataType                    
                            dataType.Value = Convert.ToString(propertyValue.TypedValue.DataType);
                            properties.Attributes.Append(dataType);

                            XmlAttribute propertyDisplayValue = doc.CreateAttribute("propertyValue"); //propertyValue

                            propertyDisplayValue.Value = propertyValue.Value.DisplayValue;

                            properties.Attributes.Append(propertyDisplayValue);

                            if (searchObject != null)
                            {
                                searchObject.AppendChild(properties);
                            }

                            if (propertyValue.TypedValue.DataType == MFDataType.MFDatatypeLookup || propertyValue.TypedValue.DataType == MFDataType.MFDatatypeMultiSelectLookup)
                            {

                                XmlElement valueListItem = doc.CreateElement("properties");

                                XmlAttribute valuelistPropertyID = doc.CreateAttribute("propertyId"); //propertyId
                                valuelistPropertyID.Value = propertyValue.PropertyDef.ToString();
                                valueListItem.Attributes.Append(valuelistPropertyID);

                                XmlAttribute valueListItemID = doc.CreateAttribute("propertyValue"); //propertyValue

                                string valueListItemIds = null;

                                if (propertyValue.TypedValue.Value != null && propertyValue.TypedValue.Value.ToString() != "")
                                {
                                    Array valueListObject = (Array)(propertyValue.TypedValue.Value);

                                    for (int j = 0; j <= valueListObject.GetUpperBound(0); j++)
                                    {
                                        if (!String.IsNullOrEmpty(valueListItemIds))
                                        {
                                            valueListItemIds = valueListItemIds + "," + valueListObject.GetValue(j, 0).ToString();
                                        }
                                        else
                                        {
                                            valueListItemIds = valueListObject.GetValue(j, 0).ToString();
                                        }
                                    }
                                }
                                valueListItemID.Value = valueListItemIds;
                                valueListItem.Attributes.Append(valueListItemID);

                                if (searchObject != null)
                                {
                                    searchObject.AppendChild(valueListItem);
                                }
                            }
                        }
                    }

                    if (node != null)
                    {
                        //Append the element to XmlDocument
                        node.AppendChild(searchObject);
                    }
                }
            }

        }
        catch (Exception ex)
        {
            string customError = "Please check the property (" + currentPropertyValue.PropertyDef.ToString() + ")  value of the object (" +
                         currentObjVer.ID.ToString() + ") @\n";
            throw new Exception(customError + ex.Message);
        }

        return doc.InnerXml;
    }

    #endregion

    #region DataSet Export

    /// <summary>
    /// CLR method for DATA SET export
    /// </summary>
    /// <param name="sUsername"></param>
    /// <param name="sPassword"></param>
    /// <param name="sNetworkAddress"></param>
    /// <param name="sVaultName"></param>
    /// <param name="sDataSetName"></param>
    /// <param name="isExporting"></param>
    [Microsoft.SqlServer.Server.SqlProcedure]
    //public static void ExportDataSet(string sUsername, string sPassword, string sNetworkAddress, string sVaultName, string sDataSetName, out bool isExporting)
    public static void ExportDataSet(string VaultSettings, string sDataSetName, out bool isExporting)

    {
        isExporting = false;

        try
        {
            //MFilesAccess mFileAccess = GetMFilesAccess(sUsername, sPassword, sNetworkAddress, sVaultName);
            MFilesAccess mFileAccess = GetMFilesAccessNew(VaultSettings);
            DataSetExportingStatus oExportStatus = mFileAccess.DataSetExport(sDataSetName, ref isExporting);
            mFileAccess.LogOut();
        }
        catch (Exception)
        {
            throw;
        }

    }
    #endregion

    public static void Test()
    {
        MFilesAccess mFileAccess = GetMFilesAccess("thejus", "3j3Hf4biZZk=", "localhost", "sample vault");
        ObjVer objVer = new ObjVer();
        objVer.ID = 3840;
        objVer.ObjID.ID = 3840;
        objVer.ObjID.Type = 136;
        objVer.Type = 136;
        objVer.Version = 2;

        ObjID objID = new ObjID();
        ObjectVersionAndProperties pp = mFileAccess.GetObjectVersionAndProperties(objVer, ref objID);
        //mFileAccess.GetUserDetails();
        //ObjVer objVer = new ObjVer();
        //objVer.ID = 402;
        //objVer.ObjID.ID = 402;
        //objVer.ObjID.Type = 0;
        //objVer.Type = 0;
        //objVer.Version = 1;
        ////ObjID objID = new ObjID();

        //ObjectVersionAndProperties x = mFileAccess.GetObjectVersionAndProperties(objVer, ref objID);

        //string path = mFileAccess.GetPathInDefaultView(x.VersionData.Files);
        //string cc = x.VersionData.GetNameForFileSystem(true);
        //string ccc = x.VersionData.GetNameForFileSystem(false);
    }

    public static void SearchTest(string sXmlFile)
    {
        XmlSerializer serializer = new XmlSerializer(typeof(XMLClass.RootObjVers));
        StringReader reader = new StringReader(sXmlFile);
        XMLClass.RootObjVers objectDetailCollection = (XMLClass.RootObjVers)serializer.Deserialize(reader);
        reader.Close();

        MFilesAccess mFileAccess = GetMFilesAccess("thejus", "3j3Hf4biZZk=", "localhost", "sample vault");

        SearchConditions oSearchConditions = new SearchConditions();
        SetSearchConditionForClass(78, null, ref oSearchConditions);
        ObjectVersions mFileObjVers = mFileAccess.GetAllObjVersOfAClass(oSearchConditions);

        Stopwatch stopwatch = new Stopwatch();
        stopwatch.Start();

        List<ObjVer> l1 = new List<ObjVer>();
        List<ObjVer> l2 = new List<ObjVer>();
        foreach (ObjVer objVer in mFileObjVers.GetAsObjVers())
        {
            l1.Add(objVer);
            l2.Add(objVer);
        }

        var commonList = l1.Except(l2, new ObjVerComparer()).ToList();

        var xx = stopwatch.Elapsed;
        stopwatch.Stop();
    }

    public static void GetMFilesVersion(string VaultSettings, out string MFileVersion)
    {
        MFileVersion = string.Empty;
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
        mFilesAccess.GetMFilesVersion(ref MFileVersion);
        mFilesAccess.LogOut();
    }

    public static void GetMFilesEventLog(string VaultSettings, bool IsClearMFileLog, out string xml)
    {
        xml = string.Empty;
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
        xml = mFilesAccess.GetMFilesLog();

        if (IsClearMFileLog)
        {
            mFilesAccess.ClearMfilesLog();
        }
        mFilesAccess.LogOut();
    }
    // Task 1100
    [Microsoft.SqlServer.Server.SqlProcedure]

    public static void GetHistory(string VaultSettings, string ObjectType, string ObjIDs, string PropertyIDS, string Searchstring, string IsFullUpdate, string NumberOfDays, string StartDate, out string Result)
    {
        Result = string.Empty;
        string OutXML = string.Empty;
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("form");

        string[] ObjIDCollection = ObjIDs.Split(',');
        List<ObjectVersions> Lst_ObjectVersions = new List<ObjectVersions>();

        if (ObjIDCollection.Length > 0)
        {

            foreach (string ID in ObjIDCollection)
            {
                ObjectVersions obj = mFilesAccess.GetHistory(Convert.ToInt32(ObjectType), Convert.ToInt32(ID));
                Lst_ObjectVersions.Add(obj);

            }
        }

        OutXML = OutXML + CreateObjectHistoryXML(doc, node, Lst_ObjectVersions, PropertyIDS, mFilesAccess, IsFullUpdate == "1" ? true : false, StartDate, NumberOfDays);
        Result = OutXML;
        mFilesAccess.LogOut();
    }

    private static string CreateObjectHistoryXML(XmlDocument doc, XmlNode node, List<ObjectVersions> Lst_ObjectVersions, string PropertyIDS, MFilesAccess mFilesAccess, Boolean IsFullUpdate, string StartDate, string NumberOfDays)
    {
        string Result = string.Empty;
        string[] PropertyID = PropertyIDS.Split(',');

        if (PropertyID.Length > 0)
        {
            foreach (ObjectVersions ObjVers in Lst_ObjectVersions)
            {
                foreach (ObjectVersion ObjDetails in ObjVers)
                {
                    if (IsFullUpdate)
                    {
                        goto Start;
                    }
                    else
                    {
                        if (!string.IsNullOrEmpty(StartDate))
                        {
                            if (ObjDetails.LastModifiedUtc.Date >= Convert.ToDateTime(StartDate).Date)
                            {
                                goto Start;
                            }
                            else
                            {
                                break;
                            }
                        }

                        else if (!string.IsNullOrEmpty(NumberOfDays) || NumberOfDays != "-1")
                        {
                            if (ObjDetails.LastModifiedUtc.Date >= DateTime.Now.AddDays(-1 * Convert.ToInt32(NumberOfDays)).Date)
                            {
                                goto Start;
                            }
                            else
                            {
                                break;
                            }
                        }
                        else
                        {
                            break;
                        }
                    }

                    Start:
                    XmlElement searchObject = doc.CreateElement("Object");
                    XmlAttribute ObjectType = doc.CreateAttribute("ObjectType"); //ObjectType
                    ObjectType.Value = Convert.ToString(ObjDetails.ObjVer.ObjID.Type);
                    searchObject.Attributes.Append(ObjectType);


                    XmlAttribute ClassID = doc.CreateAttribute("ClassID"); //ClassID
                    ClassID.Value = Convert.ToString(ObjDetails.Class);
                    searchObject.Attributes.Append(ClassID);

                    XmlAttribute ObjID = doc.CreateAttribute("ObjID"); //ObjID
                    ObjID.Value = Convert.ToString(ObjDetails.ObjVer.ObjID.ID);
                    searchObject.Attributes.Append(ObjID);

                    XmlAttribute Version = doc.CreateAttribute("Version"); //Version
                    Version.Value = Convert.ToString(ObjDetails.ObjVer.Version);
                    searchObject.Attributes.Append(Version);

                    //XmlAttribute CheckOutTimeStamp = doc.CreateAttribute("CheckOutTimeStamp"); //CheckOutTimeStamp
                    //CheckOutTimeStamp.Value = Convert.ToString(ObjDetails.CheckedOutAtUtc);
                    //searchObject.Attributes.Append(CheckOutTimeStamp);

                    XmlAttribute CheckInTimeStamp = doc.CreateAttribute("CheckInTimeStamp"); //CheckInTimeStamp
                    CheckInTimeStamp.Value = Convert.ToString(ObjDetails.LastModifiedUtc);
                    searchObject.Attributes.Append(CheckInTimeStamp);


                    //XmlAttribute LastModifiedBy_ID = doc.CreateAttribute("LastModifiedBy_ID"); //LastModifiedBy_ID
                    //LastModifiedBy_ID.Value = Convert.ToString(ObjDetails.CheckedOutToUserName);
                    //searchObject.Attributes.Append(LastModifiedBy_ID);



                    MFilesAPI.PropertyValues m_oPropertyValues = new MFilesAPI.PropertyValues();
                    m_oPropertyValues = mFilesAccess.GetObjectPrperties(ObjDetails.ObjVer);

                    foreach (PropertyValue P in m_oPropertyValues)
                    {

                        if (P.PropertyDef.ToString() == "23")
                        {

                            XmlAttribute LastModifiedBy_ID = doc.CreateAttribute("LastModifiedBy_ID"); //LastModifiedBy_ID
                            LastModifiedBy_ID.Value = Convert.ToString(((object[,])P.TypedValue.Value)[0, 0]);
                            searchObject.Attributes.Append(LastModifiedBy_ID);
                        }

                        foreach (string ID in PropertyID)
                        {
                            if (P.PropertyDef.ToString() == ID)
                            {
                                XmlElement PropertyObject = doc.CreateElement("Property");
                                XmlAttribute Property_ID = doc.CreateAttribute("Property_ID"); //Property_ID
                                Property_ID.Value = Convert.ToString(P.PropertyDef.ToString());
                                PropertyObject.Attributes.Append(Property_ID);

                                XmlAttribute Property_Value = doc.CreateAttribute("Property_Value"); //Property_Value
                                                                                                     //Property_Value.Value = Convert.ToString(P.Value.Value.ToString());
                                                                                                     //PropertyObject.Attributes.Append(Property_Value);

                                if (P.TypedValue.DataType == MFDataType.MFDatatypeDate || P.TypedValue.DataType == MFDataType.MFDatatypeTimestamp)
                                {
                                    if (P.Value.DisplayValue != "")
                                    {
                                        System.DateTime MyDateTime = (DateTime)P.TypedValue.Value;
                                        // DateTime MyDateTime = Convert.ToDateTime();//, System.Globalization.CultureInfo.InvariantCulture);//new DateTime(propertyValue.Value.DisplayValue);
                                        String DateString = MyDateTime.ToString("dd-MM-yyyy HH:mm");
                                        Property_Value.Value = DateString;
                                        //strDebug.Concat("   DateString  ", DateString); // todo
                                    }
                                    else
                                    {
                                        Property_Value.Value = "";
                                    }
                                }
                                else
                                {
                                    if (P.TypedValue.DataType == MFDataType.MFDatatypeBoolean)
                                    {
                                        if (!string.IsNullOrEmpty(P.Value.Value.ToString()))
                                        {
                                            if (Convert.ToBoolean(P.Value.Value))
                                                Property_Value.Value = "1";
                                            else
                                                Property_Value.Value = "0";
                                        }
                                        else
                                        {
                                            Property_Value.Value = "";
                                            // Property_Value.Value = "0"; //set to null when not filled in
                                        }
                                    }

                                    else
                                    {
                                        if (P.TypedValue.DataType == MFDataType.MFDatatypeLookup || P.TypedValue.DataType == MFDataType.MFDatatypeMultiSelectLookup)
                                        {


                                            string valueListItemIds = null;
                                            if (P.TypedValue.Value != null && P.TypedValue.Value.ToString() != "")
                                            {
                                                Array valueListObject = (Array)(P.TypedValue.Value);

                                                for (int j = 0; j <= valueListObject.GetUpperBound(0); j++)
                                                {
                                                    if (!String.IsNullOrEmpty(valueListItemIds))
                                                    {
                                                        valueListItemIds = valueListItemIds + "," + valueListObject.GetValue(j, 0).ToString();
                                                    }
                                                    else
                                                    {
                                                        valueListItemIds = valueListObject.GetValue(j, 0).ToString();
                                                    }
                                                }
                                            }
                                            Property_Value.Value = valueListItemIds;

                                        }
                                        else
                                        {
                                            Property_Value.Value = P.Value.DisplayValue;
                                        }
                                    }

                                }
                                PropertyObject.Attributes.Append(Property_Value);

                                if (searchObject != null)
                                {
                                    searchObject.AppendChild(PropertyObject);
                                }

                            }

                        }

                    }

                    if (node != null)
                    {
                        //Append the element to XmlDocument
                        node.AppendChild(searchObject);
                    }
                }
            }
            Result = doc.InnerXml;
        }
        return Result;
    }
    // Task 1100
    //Task #106
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void GetFiles(string VaultSettings, string ClassID, string ObjID, string ObjType, string ObjVersion, string FilePath, string IncludeDocID, out string FileExport)
    {
        //Connecting Vault 
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
        // MFilesAPI.PropertyValues m_oPropertyValues = new MFilesAPI.PropertyValues();
        ObjectVersionAndProperties m_ObjectVersionAndProperties = mFilesAccess.GetObjectProperties(Convert.ToInt32(ObjID), Convert.ToInt32(ObjType), Convert.ToInt32(ObjVersion));
        //Getting files from M-files server of Objects
        ObjectFiles ObjFiles = mFilesAccess.GetFilesFromMFiles(Convert.ToInt32(ObjID), Convert.ToInt32(ObjType), Convert.ToInt32(ObjVersion));
        FileExport = string.Empty;
        foreach (ObjectFile OF in ObjFiles)
        {
            //Checking folder exist or not.
            bool exists = System.IO.Directory.Exists(FilePath);
            if (!exists)
                System.IO.Directory.CreateDirectory(FilePath); //If folder doesn't exist the creates folder.

            string szTargetPath = string.Empty;
            szTargetPath = OF.GetNameForFileSystem();
            if (IncludeDocID == "1") //Checking that Include object ID into the File name.
            {
                string[] FileName = szTargetPath.Split('.');
                szTargetPath = FileName[0] + "(ID " + ObjID.ToString() + ")." + FileName[1];
            }
            mFilesAccess.DownloadFile(OF.ID, OF.Version, FilePath + szTargetPath);
        }

        FileExport = CreateFileExportXml(ObjFiles, ClassID, ObjID, ObjType, ObjVersion, IncludeDocID, FilePath, ((MFilesAPI.ObjectVersionClass)((MFilesAPI.ObjectVersionAndPropertiesClass)m_ObjectVersionAndProperties).VersionData).FilesCount);
        mFilesAccess.LogOut();
    }

    private static string CreateFileExportXml(ObjectFiles ObjFiles, string ClassID, string ObjID, string ObjType, string Version, string IncludeDocID, string FilePath, int FileCount)
    {
        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("Files");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("Files");

        foreach (ObjectFile OF in ObjFiles)
        {
            //Creating XmlDocument
            XmlElement ValueListItem = doc.CreateElement("FileItem");

            //Adding 'ValueListID' Attribute
            XmlAttribute FileName = doc.CreateAttribute("FileName"); //FileName
            string szTargetPath = OF.GetNameForFileSystem();
            if (IncludeDocID == "1")
            {
                string[] Name = szTargetPath.Split('.');
                szTargetPath = Name[0] + "(ID " + ObjID.ToString() + ")." + Name[1];
            }
            FileName.Value = szTargetPath;
            ValueListItem.Attributes.Append(FileName);

            //Adding 'ValueListItemID' Attribute
            XmlAttribute Class_ID = doc.CreateAttribute("ClassID"); //ClassID
            Class_ID.Value = ClassID.ToString();
            ValueListItem.Attributes.Append(Class_ID);

            //Adding 'ValueListItemName' Attribute
            XmlAttribute Obj_ID = doc.CreateAttribute("ObjID"); //ObjID
            Obj_ID.Value = ObjID;
            ValueListItem.Attributes.Append(Obj_ID);

            //Adding 'Owner' Attribute
            XmlAttribute Obj_Type = doc.CreateAttribute("ObjType"); //ObjType
            Obj_Type.Value = ObjType;
            ValueListItem.Attributes.Append(Obj_Type);


            //Adding 'Owner' Attribute
            XmlAttribute Ver = doc.CreateAttribute("Version"); //ValuelistItem Owner
            Ver.Value = Version;
            ValueListItem.Attributes.Append(Ver);

            XmlAttribute FileCheckSum = doc.CreateAttribute("FileCheckSum"); //FileCheckSum
            FileCheckSum.Value = GetFileChecksum(FilePath + szTargetPath, new MD5CryptoServiceProvider());
            ValueListItem.Attributes.Append(FileCheckSum);

            //XmlAttribute FileCount = doc.CreateAttribute("File"); //File
            //File.Value = System.IO.File.ReadAllBytes(FilePath + szTargetPath); 
            //ValueListItem.Attributes.Append(FileCheckSum);

            XmlAttribute FileCountx = doc.CreateAttribute("FileCount"); //FileCheckSum
            FileCountx.Value = FileCount.ToString();
            ValueListItem.Attributes.Append(FileCountx);

            //Task 1234 Rheal : Added fileobjectId 14/06/2019
            XmlAttribute File_Object_ID = doc.CreateAttribute("FileObjectID"); //ObjID
            File_Object_ID.Value = OF.ID.ToString();
            ValueListItem.Attributes.Append(File_Object_ID);


            if (node != null)
            {
                //Append the element to XmlDocument
                node.AppendChild(ValueListItem);
            }
        }
        //Convert The innerXml to String
        var xmlString = doc.InnerXml;

        return xmlString;
    }
    private static string GetFileChecksum(string file, System.Security.Cryptography.HashAlgorithm algorithm)
    {
        string result = string.Empty;

        using (FileStream fs = File.OpenRead(file))
        {
            result = BitConverter.ToString(algorithm.ComputeHash(fs)).ToLower().Replace("-", "");
        }

        return result;
    }

    #region Task 1164
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void ValidateModule(string VaultSettings, string ModuleID, out string Status)
    {
    
        Status = string.Empty;
        try
        {

            //Variable Declaration
            string Result = string.Empty;
            string DecryptLicenseKey = string.Empty;
            Boolean LicenseValid = false, IsModuleValid = false; ;


            //Getting License key from vault by Calling Vault Extention method
            #region Task 1232
            MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
            Result = mFilesAccess.GetLicenseKey();


            #endregion

            if (!string.IsNullOrEmpty(Result))
            {
                Laminin.CryptoEngine.Decrypt(Result, out DecryptLicenseKey);
                ///Validating license and module
                string[] LicenseElement = DecryptLicenseKey.Split('|');
                if (LicenseElement.Length > 0)
                {
                    string[] Modules = LicenseElement[0].Split(','); //Getting Module array.
                    string ExpiryDate = !string.IsNullOrEmpty(LicenseElement[1]) ? LicenseElement[1] : string.Empty; //Getting License expiry date.
                    if (!string.IsNullOrEmpty(ExpiryDate))
                    {
                        DateTime SystemCurrentDate = DateTime.Now.Date;
                        var NewExpireDate = ExpiryDate.Split('/');
                        DateTime LicenseExpiryDate = new DateTime(Convert.ToInt32(NewExpireDate[2]), Convert.ToInt32(NewExpireDate[0]), Convert.ToInt32(NewExpireDate[1]));

                        if (SystemCurrentDate < LicenseExpiryDate)
                        {
                            LicenseValid = true;
                            Status = "1";
                        }
                        else
                        {
                            LicenseValid = false;
                            Status = "2" ;  //Status means License has expired.
                        }
                    }
                    else
                    {
                        LicenseValid = false;
                        Status = "4"; //if licenkey does not contain any module key then Invalid License Key;
                    }


                    //Checking for Module

                    if (LicenseValid && Status == "1") //First checking  license expired or not before validating module
                    {

                        if (Modules.Length > 0)
                        {
                            foreach (string Item in Modules)
                            {
                                if (Item == ModuleID)
                                {

                                    IsModuleValid = true;
                                }
                            }

                            if (IsModuleValid)
                                Status = "1|" +ExpiryDate; //LC add expirydate to output
                            else
                                Status = "3|" + ExpiryDate; //LC add expirydate to output";

                        }
                        else
                        {
                            Status = "4"; //if licenkey does not contain any module key then Invalid License Key;
                        }

                    }


                }
                else
                {
                    Status = "4"; //Invalid License Key;
                }
            }
            else
            {
                Status = "5";
            }
            mFilesAccess.LogOut();
        }
        catch (Exception ex)
        {
            Status = "4"; //Invalid License Key;
        }

        
    }
    #endregion Task 1164

    #region Task 1087
    public static void GetMetadataStructureVersionID(string VaultSettings, out string Result)
    {
        Result = "0";
        MFilesAccess mFilesAccess = GetMFilesAccessNew(VaultSettings);
        long VersionID = mFilesAccess.GetMetadataStructureVersionID();
        Result = VersionID.ToString();
        mFilesAccess.LogOut();
    }
    #endregion


    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void GetUnManagedObjectDetails(string ExternalRepositoryObjectIDs, string VaultSettings, out string Result)
    {

        Result = string.Empty;
        Dictionary<int, MFilesAPI.PropertyValues> dict = new Dictionary<int, MFilesAPI.PropertyValues>();
        MFilesAccess objMFilesAccess = new MFilesAccess(VaultSettings);
        Vault V = objMFilesAccess.GetConnectionForUnManageObject(VaultSettings);
        ObjectVersions NewCollection = new ObjectVersions();

        if (!string.IsNullOrEmpty(ExternalRepositoryObjectIDs))
        {
            string[] ObjectIDs = ExternalRepositoryObjectIDs.Split(',');
            if (ObjectIDs.Length > 0)
            {



                foreach (string Id in ObjectIDs)
                {
                    //System.Diagnostics.Debugger.Launch();
                    ObjectVersions objVersionsCollection = objMFilesAccess.GetAllUnManagedObjVers(Convert.ToInt32(Id), V);
                    FillObjectVersionsDictionary(objVersionsCollection, ref dict, objMFilesAccess);
                }


            }
        }
        //else
        //{
        //    ObjectVersions objVersionsCollection = objMFilesAccess.GetAllUnManagedObjVers(Convert.ToInt32(0), V);
        //    FillObjectVersionsDictionary(objVersionsCollection,ref dict, objMFilesAccess);
        //}


        Result = GetUnmanagedObjectDetailsXML(objMFilesAccess, dict);
       
    }

    public static void FillObjectVersionsDictionary(ObjectVersions objVersionsCollection, ref Dictionary<int, MFilesAPI.PropertyValues> dict, MFilesAccess objMFilesAccess)
    {

        if (objVersionsCollection != null && objVersionsCollection.Count > 0)
        {
            int i = 1;
            foreach (ObjectVersion objv in objVersionsCollection)
            {

                if (objv.ObjVer.ObjID.IsUnmanaged())
                {

                    MFilesAPI.PropertyValues m_oPropertyValues = new MFilesAPI.PropertyValues();
                    m_oPropertyValues = objMFilesAccess.GetObjectPrperties(objv.ObjVer);
                    // Result = Result + GetUnmanagedObjectDetailsXML(m_oPropertyValues, objMFilesAccess, Convert.ToInt32(Id));
                    dict.Add(Convert.ToInt32(objv.ObjVer.ObjID.ExternalRepositoryObjectID.Split('!')[1]), m_oPropertyValues);
                }

            }

        }
    }
    public static string GetUnmanagedObjectDetailsXML(MFilesAccess objMFilesAccess, Dictionary<int, MFilesAPI.PropertyValues> dict)
    {

        //Creating XmlDocument
        var doc = new XmlDocument();

        //Creating XmlElement
        XmlElement form = doc.CreateElement("Form");

        //Append the element to XmlDocument
        doc.AppendChild(form);

        //Creating XmlNode
        XmlNode node = doc.SelectSingleNode("Form");


        foreach (KeyValuePair<int, PropertyValues> item in dict)
        {

            XmlElement searchObject = doc.CreateElement("Object");


            //Adding 'objectId' Attribute
            XmlAttribute objectId = doc.CreateAttribute("objectId"); //objectId
            objectId.Value = Convert.ToString(item.Key.ToString());
            searchObject.Attributes.Append(objectId);

            PropertyValues m_oPropertyValues = item.Value;
            foreach (PropertyValue p in m_oPropertyValues)
            {



                //Creating XmlDocument
                XmlElement Property = doc.CreateElement("Properties");

                //Adding 'ValueListItemID' Attribute
                XmlAttribute ID = doc.CreateAttribute("ID"); //ClassID
                ID.Value = p.PropertyDef.ToString();
                Property.Attributes.Append(ID);


                XmlAttribute Name = doc.CreateAttribute("Name"); //ClassID
                Name.Value = objMFilesAccess.GetPropertyName(p.PropertyDef).ToString();
                Property.Attributes.Append(Name);


                XmlAttribute DisplayValue = doc.CreateAttribute("DisplayValue"); //ClassID
                DisplayValue.Value = Convert.ToString(p.TypedValue.DataType) == "MFDatatypeBoolean" ? p.TypedValue.DisplayValue.ToString() == "Yes" ? "1" : "0" : p.TypedValue.DisplayValue.ToString();
                Property.Attributes.Append(DisplayValue);

                XmlAttribute DataType = doc.CreateAttribute("DataType"); //ClassID
                DataType.Value = Convert.ToString(p.TypedValue.DataType);
                Property.Attributes.Append(DataType);


                if (searchObject != null)
                {
                    //Append the element to XmlDocument
                    searchObject.AppendChild(Property);
                }
            }
            //Convert The innerXml to String

            if (node != null)
            {
                node.AppendChild(searchObject);
            }

        }

        var xmlString = doc.InnerXml;

        return xmlString;
    }
}


