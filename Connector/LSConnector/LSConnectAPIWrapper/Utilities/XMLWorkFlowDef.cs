using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;

namespace LSConnect.Utilities
{
    public class XMLWorkFlowDef
    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "WorkFlow")]

        public partial class WorkFlowCollection
        {
            [System.Xml.Serialization.XmlElementAttribute("WorkFlowDetails")]

            public List<WorkFlowDef> LstWorkFlowDef
            {
                get;set;
            }

        }


        public partial class WorkFlowDef
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
        }
    }
}
