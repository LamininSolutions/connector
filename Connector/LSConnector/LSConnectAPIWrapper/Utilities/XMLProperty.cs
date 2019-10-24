using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;


namespace LSConnect.Utilities
{
    public class XMLProperty
    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "Prop")]

        public class PropertyList
        {
            [System.Xml.Serialization.XmlElementAttribute("PropDetails")]

            public List<PropertyDef> Lst
            {
                get;
                set;
            }
        }
        //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "PropertyList")]
        public class PropertyDef
        {
            //[XmlElement("ID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int ID { get; set; }

            //[XmlElement("Name")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string Name { get; set; }

            //[XmlElement("Alias")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string Alias { get; set; }

            //[XmlElement("MFID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFID { get; set; }

            //[XmlElement("ColumnName")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string ColumnName { get; set; }

            //[XmlElement("MFDataType_ID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFDataType_ID { get; set; }

      
            //[XmlElement("PredefinedOrAutomatic")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public bool PredefinedOrAutomatic { get; set; }


        }
    }
}
