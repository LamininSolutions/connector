using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;

namespace LSConnect.Utilities
{
    public class XmLWorkFlowStateDef
    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "WorkFlowState")]

        public partial class WorkFlowStateCollection
        {
            [System.Xml.Serialization.XmlElementAttribute("WorkFlowStateDetails")]

            public List<WorkFlowStateDef> LstWorkFlowstateDef
            {
                get; set;
            }

        }


        public partial class WorkFlowStateDef
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

            //[XmlElement("MFWorkflowID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFWorkflowID { get; set; }
        }
    }
}
