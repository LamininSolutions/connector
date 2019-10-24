using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using MFilesAPI;

namespace LSConnect.Utilities
{
    public class XMLClass
    {
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlSerializerAssembly("LSConnectMFilesAPIWrapper.XmlSerializers, Version=2.0.0.1, Culture=neutral, PublicKeyToken=null")]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false, ElementName = "form")]
        public partial class ObjectDetailsCollection
        {

            private List<ObjectDetails> objectField;

            /// <remarks/>
            [System.Xml.Serialization.XmlElementAttribute("Object")]
            public List<ObjectDetails> Object
            {
                get
                {
                    return this.objectField;
                }
                set
                {
                    this.objectField = value;
                }
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "Object")]
        public partial class ObjectDetails
        {

            private ClassDetails classField;

            private int idField;

            private int sqlIDField;

            private int objIDField;

            private int objVersionField;

            private string DisplayIDField;

            /// <remarks/>
            [System.Xml.Serialization.XmlElementAttribute("class")]
            public ClassDetails ClassDetail
            {
                get
                {
                    return this.classField;
                }
                set
                {
                    this.classField = value;
                }
            }

            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int objVesrion
            {
                get
                {
                    return this.objVersionField;
                }
                set
                {
                    this.objVersionField = value;
                }
            }
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int objID
            {
                get
                {
                    return this.objIDField;
                }
                set
                {
                    this.objIDField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int id
            {
                get
                {
                    return this.idField;
                }
                set
                {
                    this.idField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int sqlID
            {
                get
                {
                    return this.sqlIDField;
                }
                set
                {
                    this.sqlIDField = value;
                }
            }

            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string DisplayID
            {
                get
                {
                    return this.DisplayIDField;
                }
                set
                {
                    this.DisplayIDField = value;
                }
            }


        }

        /// <remarks/>
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "class")]
        public partial class ClassDetails
        {

            private List<PropertyDetails> propertyField;

            private int idField;

            /// <remarks/>
            [System.Xml.Serialization.XmlElementAttribute("property")]
            public List<PropertyDetails> property
            {
                get
                {
                    return this.propertyField;
                }
                set
                {
                    this.propertyField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int id
            {
                get
                {
                    return this.idField;
                }
                set
                {
                    this.idField = value;
                }
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [XmlRoot(ElementName = "property")]
        public partial class PropertyDetails
        {

            private int idField;

            private int dataTypeField;

            private string valueField;

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int id
            {
                get
                {
                    return this.idField;
                }
                set
                {
                    this.idField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public int dataType
            {
                get
                {
                    return this.dataTypeField;
                }
                set
                {
                    this.dataTypeField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlTextAttribute()]
            public string Value
            {
                get
                {
                    return this.valueField;
                }
                set
                {
                    this.valueField = value;
                }
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
        public partial class RootObjVers
        {

            private RootObjVersObjectType objectTypeField;

            /// <remarks/>
            public RootObjVersObjectType ObjectType
            {
                get
                {
                    return this.objectTypeField;
                }
                set
                {
                    this.objectTypeField = value;
                }
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        public partial class RootObjVersObjectType
        {

            private RootObjVersObjectTypeObjVers[] objVersField;

            private byte idField;

            /// <remarks/>
            [System.Xml.Serialization.XmlElementAttribute("objVers")]
            public RootObjVersObjectTypeObjVers[] objVers
            {
                get
                {
                    return this.objVersField;
                }
                set
                {
                    this.objVersField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public byte id
            {
                get
                {
                    return this.idField;
                }
                set
                {
                    this.idField = value;
                }
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        public partial class RootObjVersObjectTypeObjVers
        {

            private ushort objectIDField;

            private byte versionField;

            private string objectGUIDField;

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public ushort objectID
            {
                get
                {
                    return this.objectIDField;
                }
                set
                {
                    this.objectIDField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public byte version
            {
                get
                {
                    return this.versionField;
                }
                set
                {
                    this.versionField = value;
                }
            }

            /// <remarks/>
            [System.Xml.Serialization.XmlAttributeAttribute()]
            public string objectGUID
            {
                get
                {
                    return this.objectGUIDField;
                }
                set
                {
                    this.objectGUIDField = value;
                }
            }
        }




    }
}
