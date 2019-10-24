using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;
namespace LSConnect.Utilities
{
   public class XMLValueListDef
    {

        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "VList")]


        public partial class ValueListCollection
        {
            [System.Xml.Serialization.XmlElementAttribute("ValueListDetails")]
            public List<ValueListDef> LstValueListDef
            {
                get; set;
            }
        }

        public partial class ValueListDef
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

            //[XmlElement("OwnerID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int OwnerID { get; set; }
        }
    }
}
