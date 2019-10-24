using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;

namespace LSConnect.Utilities
{

    public class XMLCls
    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "CLS")]
        public partial class ClassList
        {

            [System.Xml.Serialization.XmlElementAttribute("ClassDetails")]

            public List<ClassDetail> Lst
            {
                get;
                set;
            }

        }
        //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "ClassList")]
        public partial class ClassDetail
        {
            //[XmlElement("SqlID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int SqlID { get; set; }

            //[XmlElement("MFID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFID { get; set; }


            //[XmlElement("Name")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string Name { get; set; }

            //[XmlElement("Alias")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string Alias { get; set; }


            //[XmlElement("IncludeInApp")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int IncludeInApp { get; set; }


            //[XmlElement("TableName")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string TableName { get; set; }


            //[XmlElement("MFObjectType_ID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFObjectType_ID { get; set; }

            //[XmlElement("MFWorkflow_ID")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int MFWorkflow_ID { get; set; }

        }

       
    }
}
