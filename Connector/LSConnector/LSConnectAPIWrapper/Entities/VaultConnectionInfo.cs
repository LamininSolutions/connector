using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;

namespace LSConnect.Entities
{
    public class VaultConnectionInfo
    {
        public int UserType { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
        public string Domain { get; set; }
        public string Protocol { get; set; }
        public string NetworkAddress { get; set; }
        public string Endpoint { get; set; }
        public string LocalComputerName { get; set; }
        public bool AllowAnonymous { get; set; }
        public string VaultName { get; set; }
        public int MaxResultCount { get; set; }
        public int SearchTimeoutInSeconds { get; set; }  
    }
}