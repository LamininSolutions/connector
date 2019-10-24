using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace LSConnect.Entities
{
    public class ObjVersion
    {
        private int objectID;
        private int version;
        private string objectGUID;

        public ObjVersion(XmlNode xmlObjectNode)
        {
            this.objectID = Convert.ToInt32(xmlObjectNode.Attributes["objectID"].Value);
            this.version = Convert.ToInt32(xmlObjectNode.Attributes["version"].Value);
            this.objectGUID = xmlObjectNode.Attributes["objectGUID"].Value;
        }

        public int ObjectID
        {
            get { return this.objectID; }
        }

        public string ObjectGUID
        {
            get { return this.objectGUID; }
        }
        public int Version
        {
            get { return this.version; }
        }
    }
}
