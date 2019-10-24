using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;

namespace LSConnect.Utilities
{


    public class XMLFile
    {

        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "XMLFILE")]

        public partial class FileListItemDetails
        {

            [System.Xml.Serialization.XmlElementAttribute("FileListItem")]

            public List<FileListItem> FileList
            {
                get;
                set;
            }

        }
        //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "FileList")]
        public partial class FileListItem

        {
            //[XmlElement("FileListItem")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string ID { get; set; }

            //[XmlElement("AccountName")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string AccountName { get; set; }
            //[XmlElement("File")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string File { get; set; }
            //[XmlElement("FileName")]
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string FileName { get; set; }

            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int ClassId { get; set; }

            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int ObjType { get; set; }

            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string FileCheckSum { get; set; }

        }
    }
}
