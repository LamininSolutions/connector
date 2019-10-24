using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;
using MFiles.VAF.Configuration;
using MFiles.VAF;
namespace ContextMenuVaultApp
{
    [DataContract]
    class Configuration
    {


#if !CLOUD
        [DataMember]
        [TextEditor(HelpText = "SQL server name to connect with database.", Label = "Server Name", Hidden = true)]
        public string ServerName;
        //public string ServerName  = "AMRUTAVPC";

        [DataMember]
        [MFiles.VAF.Configuration.TextEditor(HelpText = "Database name", Label = "Database Name", Hidden = true)]
        public string DatabaseName;
        //public string DatabaseName  = "MFSQLConnector";

        [DataMember]
        [MFiles.VAF.Configuration.TextEditor(HelpText = "User name to connect with database", Label = "UserName", Hidden = true)]
        public string UserName;
        //public string UserName  = "MFSQLConnector1414141";
#endif



        [DataMember]
        [TextEditor(HelpText = "License Key", Hidden = true)]
        public string LicenseKey;


        // *************************************[DataMember] Craig Solution for setting default value********************************************************************
        // [MFiles.VAF.Configuration.TextEditor(HelpText = "User name to connect with database", Label = "UserName", Hidden = true,DefaultValue = "MFSQLConnector1414141)]
        //public string UserName  = "MFSQLConnector1414141";

        public Configuration()
        {


        }


    }

}
