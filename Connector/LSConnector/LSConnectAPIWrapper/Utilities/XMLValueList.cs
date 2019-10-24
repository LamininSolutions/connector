using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;

namespace LSConnect.Utilities
{
   public class XMLValueList
    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "VLItem")]

        public partial class ValueListItemDetails
        {

            [System.Xml.Serialization.XmlElementAttribute("ValueListItem")]

            public List<ValueListItem> ValueList
            {
                get;
                set;
            }

        }
        //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "ValueList")]
        public partial class ValueListItem

        {
            //[XmlElement("MFValueListID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFValueListID { get; set; }

            //[XmlElement("MFID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFID { get; set; }
            //[XmlElement("Name")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string Name { get; set; }
            //[XmlElement("Owner")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int Owner { get; set; }

            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string DisplayID { get; set; }

            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int Process_ID { get; set; }



            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string ItemGUID { get; set; }

        }
    }
}
