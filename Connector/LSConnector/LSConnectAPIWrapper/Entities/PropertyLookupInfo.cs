using System;
using System.Collections.Generic;
////using System.Linq;
using System.Web;

namespace LSConnect.Entities
{
    public class PropertyLookupInfo
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string ListType { get; set; }
        public string ObjectId { get; set; }
        public string ValueListId { get; set; }
        public string ObjectTypeId { get; set; } //added by LC 2018-9-3
        public string CheckAgainst { get; set; }
        public string ProcessType { get; set; }
        public bool IsItemExcluded { get; set; }        

        private Dictionary<int, string> lookupValueById = new Dictionary<int,string>();
        private Dictionary<string, int> lookupIdByVal = new Dictionary<string, int>();

        public void AddLookupEntry(int itemId, string itemVal)
        {
            if(!lookupValueById.ContainsKey(itemId))
            {
                lookupValueById.Add(itemId, itemVal);
            }

            if (!lookupIdByVal.ContainsKey(itemVal))
            {
                lookupIdByVal.Add(itemVal, itemId);
            }
        }

        public string GetLookupValue(int itemId)
        {
            return lookupValueById[itemId];
        }

        public int GetLookupId(string itemVal)
        {
            return lookupIdByVal[itemVal];
        }

        public bool IsSystemList
        {
            get
            {
                return this.ListType.ToLower().Trim() == "systemlist";
            }
        }

        public bool IsValueListWithIdLookup
        {
            get
            {
                return this.ListType.ToLower().Trim() == "valuelist" 
                    && !String.IsNullOrEmpty(this.ValueListId) 
                    && this.CheckAgainst.ToLower().Trim() == "id"; 
            }
        }

        public bool IsValueListWithNameLookup
        {
            get
            {
                return this.ListType.ToLower().Trim() == "valuelist"
                    && !String.IsNullOrEmpty(this.ValueListId)
                    && this.CheckAgainst.ToLower().Trim() == "name";
            }
        }

        public bool IsObjectListWithIdLookup
        {
            get
            {
                return this.ListType.ToLower().Trim() == "lookup"
                    && !String.IsNullOrEmpty(this.ObjectId)
                    && this.CheckAgainst.ToLower().Trim() == "id";
            }
        }

        public bool IsNameLookup
        {
            get
            {
                return this.CheckAgainst.ToLower().Trim() == "name";
            }
        }

        public bool IsIdLookup
        {
            get
            {
                return this.CheckAgainst.ToLower().Trim() == "id";
            }
        }

    }   
}