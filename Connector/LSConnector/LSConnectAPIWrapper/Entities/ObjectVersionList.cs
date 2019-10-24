using LSConnect.MFiles;
using MFilesAPI;
using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace LSConnect.Entities
{
    public class ObjectVersionList
    {
        private ObjVers objVers;
        private List<string> objectGUID;

        public ObjectVersionList(int objectTypeID, XmlDocument xmlDocument)
        {
            XmlNodeList objectNodeList = xmlDocument.SelectNodes("form/objVers");
            if (objectNodeList != null)
            {

                this.objVers = new ObjVers();
                this.objectGUID = new List<string>();

                foreach (XmlNode node in objectNodeList)
                {
                    ObjVer objVer = new ObjVer();
                    ObjectVersion x = null;
                    ObjVersion objInfo = new ObjVersion(node);
                    objVer.ID = objInfo.ObjectID;
                    objVer.ObjID.ID = objInfo.ObjectID;
                    objVer.Version = objInfo.Version;
                    objVer.ObjID.Type = objectTypeID;
                    objVer.Type = objectTypeID;
                    
                    this.objVers.Add(-1, objVer);
                    this.objectGUID.Add(objInfo.ObjectGUID);
                }
            }
        }

        public ObjectVersionList()
        {
            this.objVers = new ObjVers();
            this.objectGUID = new List<string>();
        }
        public ObjVers ObjVers
        {
            get { return this.objVers; }
        }

        public List<string> ObjectGUIDs
        {
            get { return this.objectGUID; }
        }
    }
}
