using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;
using System.Configuration;
using LSConnect.MFiles;
using LSConnect.Entities;

namespace LSConnect.Utilities
{
    public class ConfigUtil
    {
        private Dictionary<string, string> appSetting = new Dictionary<string, string>();

        public void setUtilities()
        {

            if (appSetting.Count == 0)
            {
                appSetting.Add("Protocol", "ncacn_ip_tcp");                
                appSetting.Add("Endpoint", "2266");
                //appSetting.Add("Protocol", "ncacn_https");
                //appSetting.Add("Endpoint", "2266");
                appSetting.Add("AllowAnonymous", "false");
                appSetting.Add("MaxResultCount", "50000");
                appSetting.Add("SearchTimeoutInSeconds", "30000");
                appSetting.Add("RollBackChangesInCaseOfError", "false");                
                appSetting.Add("ReleaseVersion", "1.1");
                appSetting.Add("BuildVersion", "1.1.0.1");
                appSetting.Add("Domain", "");
                appSetting.Add("Usertype", "3");
            }
        }

        public object GetConfigurationValue(string configKeyName)
        {
            if (appSetting.Count == 0)
            {
                setUtilities();
            }
            if (appSetting != null)
            {
                return appSetting[configKeyName];
            }
            else
            {
                throw new Exception("Configuration Key not available, key : " + configKeyName);
            }

        }

        public static string GetBoldText(object data)
        {
            string toRet = null;
            if (data != null)
            {
                toRet = "<b>" + data.ToString() + "</b>";
            }
            return toRet;
        }

        public static bool IsEmptyStringList(List<String> list)
        {
            return list == null || list.Count == 0;
        }

        public VaultConnectionInfo ReadMFilesConectionInfo(string userName, string password, string NetworkAddress, string vaultName, string Protocol, string EndPoint, string UserType, string Domain)
        {
            VaultConnectionInfo vltConnInfo = new VaultConnectionInfo();
            vltConnInfo = new VaultConnectionInfo();
            vltConnInfo.UserName = userName;
            vltConnInfo.Password = password;
            //vltConnInfo.Domain = (string) GetConfigurationValue("Domain");
            vltConnInfo.Domain = Domain;
            // vltConnInfo.Protocol = (string) GetConfigurationValue("Protocol");
            vltConnInfo.Protocol = Protocol;
            //vltConnInfo.UserType = Convert.ToInt32(GetConfigurationValue("Usertype"));
            vltConnInfo.UserType = Convert.ToInt32(UserType);
            // (string)ConfigUtil.GetConfigurationValue("NetworkAddress");
            vltConnInfo.NetworkAddress = Protocol== "ncalrpc"?string.Empty: NetworkAddress;
            //vltConnInfo.Endpoint = (string)GetConfigurationValue("Endpoint");
            vltConnInfo.Endpoint = Protocol== "ncalrpc"?string.Empty: EndPoint;
            vltConnInfo.AllowAnonymous = Convert.ToBoolean(GetConfigurationValue("AllowAnonymous"));
            vltConnInfo.VaultName = vaultName;// (string)ConfigUtil.GetConfigurationValue("VaultName");
            vltConnInfo.MaxResultCount = Convert.ToInt32(GetConfigurationValue("MaxResultCount"));
            vltConnInfo.SearchTimeoutInSeconds = Convert.ToInt32(GetConfigurationValue("SearchTimeoutInSeconds"));
            return vltConnInfo;
        }

    }
}