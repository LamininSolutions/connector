using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;
using System.Xml;
using System.IO;
using System.Text.RegularExpressions;
using LSConnect.Entities;
using LSConnect.MFiles;

namespace LSConnect.Utilities
{
    public class XMLHelper
    {
        /// <summary>
        /// Parse file by reading html file content, then 
        /// by getting the xml string from that
        /// </summary>
        /// <param name="inputFileStream"></param>
        /// <returns></returns>
        public static ObjectInfoList ParseFile(string xmlFile,
            MFilesAccess mFilesAccess)
        {
            //XmlDocument xmlDocument = null;
            ObjectInfoList objectInfoList = null;
            string xmlString = GetXmlFromContent(xmlFile);

            if (!String.IsNullOrEmpty(xmlString))
            {
                XmlDocument xmlDocument = new XmlDocument();
                xmlDocument.LoadXml(xmlString);
                objectInfoList = GetMFilesObjectInfoList(xmlDocument, mFilesAccess);
            }
            return objectInfoList;
        }

        public static ObjectVersionList ParseFileObjVerXml(int objectTypeID, string xmlFile)
        {
            //XmlDocument xmlDocument = null;
            ObjectVersionList objectVersionList = null;
            string xmlString = GetXmlFromContent(xmlFile);

            if (!String.IsNullOrEmpty(xmlString))
            {
                XmlDocument xmlDocument = new XmlDocument();
                xmlDocument.LoadXml(xmlString);
                objectVersionList = GetMFilesObjectVersionList(objectTypeID,xmlDocument);
            }
            return objectVersionList;
        }

        /// <summary>
        /// Gets the xml from input html file content
        /// </summary>
        /// <param name="fileContent"></param>
        /// <returns></returns>
        private static string GetXmlFromContent(string fileContent)
        {
            if (!String.IsNullOrEmpty(fileContent))
            {
                fileContent = fileContent.Replace("&gt;", ">");
                fileContent = fileContent.Replace("&lt;", "<");
                fileContent = fileContent.Replace("propery", "property"); //???
                fileContent = fileContent.Replace("&gt", ">");
                fileContent = fileContent.Replace("&lt", "<");
                fileContent = Regex.Replace(fileContent, "<br.*?>", string.Empty);
                int formTagStIndex = fileContent.IndexOf("<form>",
                    StringComparison.OrdinalIgnoreCase);
                int formTagEndIndex = fileContent.IndexOf("</form>",
                    StringComparison.OrdinalIgnoreCase);
                int endFormTagLength = "</form>".Length;
                if (formTagStIndex != -1 && formTagEndIndex != -1)
                {
                    fileContent = fileContent.Substring(formTagStIndex,
                        (formTagEndIndex - formTagStIndex) + endFormTagLength);
                }
                else
                {
                    throw new Exception("Does not contain form tag in the input html");
                }
            }
            return fileContent;
        }

        public XmlNodeList GetValueListItems(XmlDocument xmlDocument)
        {
            if (xmlDocument != null)
            {
                return xmlDocument.SelectNodes("form/object/class/property[@valId]");
            }
            return null;
        }

        private static ObjectInfoList GetMFilesObjectInfoList(XmlDocument xmlDocument, MFilesAccess mFilesAccess)
        {
            try
            {
                ObjectInfoList objectInfoList = new ObjectInfoList(xmlDocument, mFilesAccess);
                return objectInfoList;
            }
            catch(Exception)
            {
                throw;
            }
        }

        private static ObjectVersionList GetMFilesObjectVersionList(int objectTypeID,XmlDocument xmlDocument)
        {
            ObjectVersionList objectVersionList = new ObjectVersionList(objectTypeID,xmlDocument);
            return objectVersionList;
        }

        public static Dictionary<int, PropertyLookupInfo> GetPropertyMappingDetails(string xmlMappingFilePath)
        {

            Dictionary<int, PropertyLookupInfo> mappingList = new Dictionary<int, PropertyLookupInfo>();
            if (!String.IsNullOrEmpty(xmlMappingFilePath))
            {
                XmlDocument xmlDocument = new XmlDocument();
                xmlDocument.Load(xmlMappingFilePath);
                if (xmlDocument != null)
                {
                    XmlNodeList xmlObjectList = xmlDocument.SelectNodes("propertyListMapping/property");
                    if (xmlObjectList != null)
                    {
                        foreach (XmlNode xmlNode in xmlObjectList)
                        {
                            int propertyId = 0;
                            PropertyLookupInfo propertyMapping = new PropertyLookupInfo();
                            //name="Organisation" id="1071" listType="lookUp" objectId="113"
                            if (xmlNode.Attributes["name"] != null)
                            {
                                propertyMapping.Name = Convert.ToString(xmlNode.Attributes["name"].Value);
                            }
                            if (xmlNode.Attributes["id"] != null)
                            {
                                propertyId = Convert.ToInt32(xmlNode.Attributes["id"].Value);
                            }
                            if (xmlNode.Attributes["listType"] != null)
                            {
                                propertyMapping.ListType = Convert.ToString(xmlNode.Attributes["listType"].Value);
                            }
                            if (xmlNode.Attributes["objectId"] != null)
                            {
                                propertyMapping.ObjectId = Convert.ToString(xmlNode.Attributes["objectId"].Value);
                            }
                            if (xmlNode.Attributes["valueListId"] != null)
                            {
                                propertyMapping.ValueListId = Convert.ToString(xmlNode.Attributes["valueListId"].Value);
                            }
                            if (xmlNode.Attributes["against"] != null)
                            {
                                propertyMapping.CheckAgainst = Convert.ToString(xmlNode.Attributes["against"].Value);
                            }
                            if (xmlNode.Attributes["id"] != null)
                            {
                                propertyMapping.Id = Convert.ToString(xmlNode.Attributes["id"].Value);
                            }
                            if (xmlNode.Attributes["process"] != null)
                            {
                                propertyMapping.ProcessType = Convert.ToString(xmlNode.Attributes["process"].Value);
                            }
                            if (xmlNode.Attributes["isItemExcluded"] != null)
                            {
                                propertyMapping.IsItemExcluded = Convert.ToBoolean(xmlNode.Attributes["isItemExcluded"].Value);
                            }
                            mappingList.Add(propertyId, propertyMapping);
                        }

                    }
                }
            }
            return mappingList;
        }
    }



}