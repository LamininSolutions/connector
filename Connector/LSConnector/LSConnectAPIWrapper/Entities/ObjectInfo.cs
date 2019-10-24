using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;
using System.Xml;

namespace LSConnect.Entities
{
    public class ObjectInfo
    {
        private int id;
        private int sqlId;
        private int objID = -1;
        private int objVersion = -1;
        private ClassInfo classInfo;        

        public ObjectInfo(XmlNode xmlObjectNode, Dictionary<int, PropertyLookupInfo> propertyMappingInfo)
        {
            this.id = Convert.ToInt32(xmlObjectNode.Attributes["id"].Value);
            if (xmlObjectNode.Attributes["sqlID"] != null && xmlObjectNode.Attributes["sqlID"].Value != null && xmlObjectNode.Attributes["sqlID"].Value != "")
            {
                this.sqlId = Convert.ToInt32(xmlObjectNode.Attributes["sqlID"].Value);
            }
            if(xmlObjectNode.Attributes["objID"] != null)
            {
                if(xmlObjectNode.Attributes["objID"].Value != null && xmlObjectNode.Attributes["objID"].Value != "")
                {
                    this.objID = Convert.ToInt32(xmlObjectNode.Attributes["objID"].Value);
                }
            }
            if (xmlObjectNode.Attributes["objVesrion"] != null)
            {
                if (xmlObjectNode.Attributes["objVesrion"].Value != null && xmlObjectNode.Attributes["objVesrion"].Value != "")
                {
                    this.objVersion = Convert.ToInt32(xmlObjectNode.Attributes["objVesrion"].Value);
                }
            }

            try
            {
                XmlNode clsNode = xmlObjectNode.SelectNodes("class")[0];
                this.classInfo = new ClassInfo(clsNode, propertyMappingInfo);
            }
            catch (Exception ex)
            {
                throw new Exception(@"Fails to parse the Class Details.",ex);
            }

        }

        public int Id
        {
            get { return this.id; }
        }

        public int ObjID
        {
            get { return this.objID; }
        }

        public int ObjVersion
        {
            get { return this.objVersion; }
        }
        
        public int SqlID
        {
            get { return this.sqlId; }
        }

        public ClassInfo ClassInfo
        {
            get { return this.classInfo; }
        }

        public PropertyInfoList PropertyCollection
        {
            get { return this.classInfo.PropertyList; }
        }

        public List<PropertyInfo> AllProperties
        {
            get { return this.classInfo.PropertyList.GetAll(); }
        }

        public List<PropertyInfo> LookupProperties
        {
            get { return this.classInfo.PropertyList.LookupPropertyList; }
        }
        
    }   

}