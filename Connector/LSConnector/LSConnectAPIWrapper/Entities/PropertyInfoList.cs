using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;
using System.Xml;

namespace LSConnect.Entities
{
    public class PropertyInfoList
    {
        private List<PropertyInfo> propertyInfoList;

        private Dictionary<int, PropertyInfo> propInfoById;

        private List<PropertyInfo> lookupPropertyList;

        private Dictionary<int, PropertyLookupInfo> propMappingInfo;


        public PropertyInfoList(XmlNodeList xmlPropertyList,
            Dictionary<int, PropertyLookupInfo> propertyMappingInfo)
        {
            if (xmlPropertyList != null)
            {
                propMappingInfo = propertyMappingInfo;
                propertyInfoList = new List<PropertyInfo>();
                lookupPropertyList = new List<PropertyInfo>();
                propInfoById = new Dictionary<int, PropertyInfo>();
                foreach (XmlNode xmlPropertyNode in xmlPropertyList)
                {
                    PropertyInfo propertyInfo = new PropertyInfo(xmlPropertyNode);
                    //if (propertyMappingInfo.ContainsKey(propertyInfo.Id))
                    //{
                    //    propertyInfo.LookupInfo = propertyMappingInfo[propertyInfo.Id];

                    //}
                    AddPropertyInfo(propertyInfo);
                }
            }

        }

        public void AddPropertyInfo(PropertyInfo propInfo)
        {
            this.propertyInfoList.Add(propInfo);
            if (!this.propInfoById.ContainsKey(propInfo.Id))
            {
                this.propInfoById.Add(propInfo.Id,
                    propInfo);
            }

            if (propInfo.LookupInfo != null)
            {
                this.lookupPropertyList.Add(propInfo);
            }
        }

        public List<PropertyInfo> GetAll()
        {
            return this.propertyInfoList;
        }

        public List<PropertyInfo> LookupPropertyList
        {
            get { return this.lookupPropertyList; }
        }

        public bool HasItem(int propertyId)
        {
            return this.propInfoById.ContainsKey(propertyId);
        }

    }
}