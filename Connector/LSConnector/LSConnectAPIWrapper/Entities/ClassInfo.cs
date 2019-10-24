using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;
using System.Xml;
using LSConnect.MFiles;

namespace LSConnect.Entities
{
    public class ClassInfo
    {
        private int id;

        private PropertyInfoList propertyList;

        public ClassInfo(XmlNode xmlClassNode, Dictionary<int, PropertyLookupInfo> propertyMappingInfo)
        {
            this.id = Convert.ToInt32(xmlClassNode.Attributes["id"].Value);
            XmlNodeList xmlPropertyList = xmlClassNode.SelectNodes("property");
            if (xmlPropertyList != null)
            {
                try
                {
                    this.propertyList = new PropertyInfoList(xmlPropertyList, propertyMappingInfo);
                }
                catch (Exception ex)
                {
                    throw new Exception(@"Fails to parse the Property Details",ex);
                }

            }
        }       

        public int Id
        {
            get { return this.id; }            
        }

        public PropertyInfoList PropertyList
        {
            get { return this.propertyList; }
        }

    }
}