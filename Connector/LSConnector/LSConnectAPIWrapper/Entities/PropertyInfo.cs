using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;
using System.Xml;

namespace LSConnect.Entities
{
    public class PropertyInfo
    {
        private int id;
        private string value;
        private string name;
        private int dataType;

        private PropertyLookupInfo lookupMap;
        public PropertyInfo(XmlNode xmlPropNode)
        {
            if (xmlPropNode != null)
            {
                this.id = Convert.ToInt32(
                    xmlPropNode.Attributes["id"].Value);
                if (xmlPropNode.Attributes["dataType"] != null)
                {
                    this.dataType = Convert.ToInt32(xmlPropNode.Attributes["dataType"].Value);
                }
                this.value = GetPropertyValue(xmlPropNode);
            }
        }

        private static string GetPropertyValue(XmlNode xmlNode)
        {
            string content = xmlNode.InnerText.Replace("\r\n", string.Empty);
            content = content.Replace("\r", string.Empty);
            content = content.Replace("\n", string.Empty);
            content = content.Trim();
            return content;
        }

        public int Id
        {
            get { return this.id; }
        }

        public int DataType
        {
            get { return this.dataType; }
        }

        public string Value
        {
            get { return this.value; }
        }

        public PropertyLookupInfo LookupInfo
        {
            set { this.lookupMap = value; }
            get { return this.lookupMap; }
        }

        public string Name
        {
            set { this.name = value; }
            get { return this.name; }
        }

        public void AddLookupEntry(int itemId, string itemVal)
        {
            this.LookupInfo.AddLookupEntry(itemId, itemVal);
        }

        public string GetLookupValue(int itemId)
        {
            return this.LookupInfo.GetLookupValue(itemId);
        }

        public int GetLookupId(string itemVal)
        {
            return this.LookupInfo.GetLookupId(itemVal);
        }

        public bool IsSystemList
        {
            get
            {
                return this.LookupInfo.IsSystemList;
            }
        }

        public bool IsValueListWithIdLookup
        {
            get
            {
                return this.LookupInfo.IsValueListWithIdLookup;
            }
        }

        public bool IsValueListWithNameLookup
        {
            get
            {
                return this.LookupInfo.IsValueListWithNameLookup;
            }
        }

        public bool IsObjectListWithIdLookup
        {
            get
            {
                return this.LookupInfo.IsObjectListWithIdLookup;
            }
        }

        public bool IsNameLookup
        {
            get
            {
                return this.LookupInfo.IsNameLookup;
            }
        }

        public bool IsIdLookup
        {
            get
            {
                return this.LookupInfo.IsIdLookup;
            }
        }

    }
}