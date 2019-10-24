using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;

namespace LSConnect.Utilities
{
  
    public class XMLObjLinkDef

    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "PSLink")]

        public partial class PublicSharedLinkCollection
        {
            [System.Xml.Serialization.XmlElementAttribute("ObjectDetails")]
            public List<ObjectDef> LstVObjectDef
            {
                get; set;
            }
        }




        public class ObjectDef
        {
            //[XmlElement("ID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int ID { get; set; }

            //[XmlElement("ExpiryDate")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string ExpiryDate { get; set; }

            //[XmlElement("AccessKey")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string AccessKey { get; set; }


        }
    }
}
