using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using MFilesAPI;

namespace LSConnect.Utilities
{
    public class ObjVerComparer :IEqualityComparer<ObjVer>
    {
        public bool Equals(ObjVer x, ObjVer y)
        {
            return
                x.ID == y.ID &&
                x.Type == y.Type &&
                x.Version == y.Version;
        }

        public int GetHashCode(ObjVer obj)
        {
            return obj.GetHashCode();
        }
    }
}
