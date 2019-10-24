using System;
using System.Collections.Generic;
using System.Web;
using System.Xml;
using MFilesAPI;
using LSConnect.MFiles;
using LSConnect.Utilities;

namespace LSConnect.Entities
{
    public class ObjectInfoList
    {
        private List<ObjectInfo> objectInfoList;

        private Dictionary<int, ObjectInfo> objectInfoById;

        private Dictionary<int, PropertyLookupInfo> propertyMappingInfo;

        private bool hasRequiredObjects;

        private int objectTypeID;

        public int objectId;

        public ObjVer objVersion;

        private bool hasPropertyValidationErrors;

        private List<string> requiredPropertyErrors;

        private bool isValid;

        private int classID;


        public ObjectInfoList(XmlDocument xmlDocument, MFilesAccess mFilesAccess)
        {
            XmlNodeList objectNodeList = xmlDocument.SelectNodes("form/Object");
            if (objectNodeList != null)
            {
                this.objectTypeID = new int();
                this.objectInfoList = new List<ObjectInfo>();
                this.objectInfoById = new Dictionary<int, ObjectInfo>();
                foreach (XmlNode node in objectNodeList)
                {
                    try
                    {
                        ObjectInfo objInfo = new ObjectInfo(node, this.propertyMappingInfo);
                        this.objectTypeID = objInfo.Id;
                        this.classID = objInfo.ClassInfo.Id;
                        if (objInfo.AllProperties.Count > 0)
                        {
                            AddObjectInfo(objInfo);
                        }
                    }
                    catch (Exception ex)
                    {
                        throw new Exception(@"Failed to Parse the ObjectType Details", ex);
                    }
                }
                this.hasRequiredObjects = CheckRequiredObjects(this.ObjectTypeId);
                this.requiredPropertyErrors = ValidateRequiredProperties(mFilesAccess);
                this.hasPropertyValidationErrors = !ConfigUtil.IsEmptyStringList(this.requiredPropertyErrors);
                this.isValid = this.hasRequiredObjects && !this.hasPropertyValidationErrors;

                if (this.requiredPropertyErrors.Count > 0)
                {
                    string errorMsg = string.Join(",", this.requiredPropertyErrors.ToArray());
                    throw new Exception(errorMsg);
                }
            }
        }

        public void AddObjectInfo(ObjectInfo objInfo)
        {
            this.objectInfoList.Add(objInfo);
            if (!this.objectInfoById.ContainsKey(objInfo.Id))
            {
                this.objectInfoById.Add(objInfo.Id,
                    objInfo);
            }
        }

        public List<ObjectInfo> ObjectInfoLists
        {
            get { return this.objectInfoList; }
        }

        public int ObjectTypeId
        {
            get { return this.objectTypeID; }
        }

        public bool IsValid
        {
            get { return this.isValid; }
        }

        private bool CheckRequiredObjects(int objectTypeID)
        {
            return objectInfoById.ContainsKey(objectTypeID);

        }

        private List<String> ValidateRequiredProperties(MFilesAccess mFilesAccess)
        {
            List<String> requiredFieldMissingItems
                = mFilesAccess.ValidateRequiredFields(this.objectInfoList);
            return requiredFieldMissingItems;
        }

        public int ClassID
        {
            get { return this.classID; }
        }

    }
}