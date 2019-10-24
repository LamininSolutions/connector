using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace ContextMenuVaultApp
{
   public class XMLDashborad
    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
      //  [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "XMLDashboard")]

        public partial class DashBoardDetails
        {

            [System.Xml.Serialization.XmlElementAttribute("DashboardItem")]

            public List<DashboardItem> List
            {
                get;
                set;
            }

        }
        //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "DashboardItem")]
        public partial class DashboardItem

        {
               [XmlElement(ElementName = "Title")]
            // [System.Xml.Serialization.XmlAttributeAttribute()]
            public string Title { get; set; }

            [XmlElement(ElementName = "Description")]
            // [System.Xml.Serialization.XmlAttributeAttribute()]
            public string Description { get; set; }

            [XmlElement(ElementName = "HelpLink")]
            //[System.Xml.Serialization.XmlAttributeAttribute()]
            public string HelpLink { get; set; }

            [XmlElement(ElementName = "Helptext")]
            //[System.Xml.Serialization.XmlAttributeAttribute()]
            public string Helptext { get; set; }

           

        }
    }
}
