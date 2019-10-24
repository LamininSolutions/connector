using System;
using System.Data;
using System.Data.SqlClient;
using MFilesAPI;

namespace ContextMenuVaultApp
{
#if !CLOUD
	public class Menu
    {
        // string strConnect = "Data Source=DESKTOP-GT362EF\\SQLEXPRESS;Initial Catalog=MFSqlCustomer;Persist Security Info=True;User ID=sa;Password=abvira;";
        int CommandtimeOut = 14400;
        public string ConnectionString { get; set; }
        public string GetContextMenu(string Constr, Vault V, int CurrentUserID)
        {
            string output = string.Empty;
            try
            {
                string ProcName = "spMFGetContextMenu";
                DataTable dtMenu = GetData(ProcName, Constr);
                if (dtMenu.Rows.Count > 0)
                {


                    for (int i = 0; i < dtMenu.Rows.Count; i++)
                    {

                        IDs Members = V.UserGroupOperations.GetUserGroup(Convert.ToInt32(dtMenu.Rows[i]["UserGroupID"])).Members;
                        if (Members.Count > 0)
                        {
                            foreach (var item in Members)
                            {
                                if (Convert.ToInt32(item) < 0)
                                {
                                    if (CheckUserGroupContextMenuAccess(CurrentUserID, Convert.ToInt32(item) * -1, V))
                                    {
                                        output = output + GetContextMenuString(dtMenu, i);
                                        break;
                                    }
                                }
                                else
                                {
                                    if (Convert.ToInt32(item) == CurrentUserID)
                                    {
                                        output = output + GetContextMenuString(dtMenu, i);
                                        break;
                                    }
                                }

                            }
                        }

                    }

                    return output;
                }
            }
            catch (Exception ex)
            {
                output = ex.Message;
            }
            return output;
        }
        public string GetContextMenuForSelectedObject(string Constr, string OjectID, string ObjectType, string ObjectVer, string Name, int ClassID, Vault V, int CurrentUserID)
        {
            string output = string.Empty;
            try
            {
                string ProcName = "spMFGetContextMenu";
                DataTable dtMenu = GetData(ProcName, Constr);
                if (dtMenu.Rows.Count > 0)
                {
                    output = "<div style='padding-left:10px'>Title: " + Name + " ClassID: " + ClassID.ToString() + "<br/>";
                    output = output + " ID: " + OjectID.ToString() + " Type: " + ObjectType.ToString() + "<br/> Version: " + ObjectVer.ToString()+ "</div><br/><hr/>";


                    for (int i = 0; i < dtMenu.Rows.Count; i++)
                    {
                        IDs Members = V.UserGroupOperations.GetUserGroup(Convert.ToInt32(dtMenu.Rows[i]["UserGroupID"])).Members;
                        if (Members.Count > 0)
                        {
                            foreach (var item in Members)
                            {
                                if (Convert.ToInt32(item) < 0)
                                {
                                    if (CheckUserGroupContextMenuAccess(CurrentUserID, Convert.ToInt32(item) * -1, V))
                                    {
                                        output = output + GetContextMenuStringForselectedObject(dtMenu, i, OjectID, ObjectType, ObjectVer, ClassID);
                                        break;
                                    }
                                }
                                else
                                {
                                    if (Convert.ToInt32(item) == CurrentUserID)
                                    {
                                        output = output + GetContextMenuStringForselectedObject(dtMenu, i, OjectID, ObjectType, ObjectVer, ClassID);
                                        break;
                                    }
                                }

                            }
                        }

                    }

                    return output;
                }
            }
            catch (Exception ex)
            {
                output = ex.Message;
            }
            return output;
        }
        public bool CheckUserGroupContextMenuAccess(int CurrentUserID, int UserGroupID, Vault V)
        {
            bool Output = false;
            IDs UserGroupMembers = V.UserGroupOperations.GetUserGroup(Convert.ToInt32(UserGroupID)).Members;
            if (UserGroupMembers.Count > 0)
            {

                foreach (var UserID in UserGroupMembers)
                {
                    if (Convert.ToInt32(UserID) < 0)
                    {
                        Output = CheckUserGroupContextMenuAccess(CurrentUserID, Convert.ToInt32(UserID) * -1, V);
                        if (Output) break;
                    }
                    else
                    {
                        if (Convert.ToInt32(UserID) == CurrentUserID)
                        {
                            Output = true;
                            break;
                        }
                    }
                }
            }
            return Output;
        }
        public string GetContextMenuString(DataTable dtMenu, int i)
        {
            string output = string.Empty;
            if (dtMenu.Rows[i]["ActionType"].ToString() != "3")
            {
                if (dtMenu.Rows[i]["IsHeader"].ToString() == "1")
                {

                    output = output + "<h4>"+ dtMenu.Rows[i]["ActionName"].ToString() +"</h4>";
                }
                else
                {
                    output = output + "<ul style='font-size:12px'>";
                    output = output + "<li ><a  href='#' onclick=\"GetResponse('" + dtMenu.Rows[i]["ActionType"].ToString() + "','" + dtMenu.Rows[i]["Action"].ToString() + "','" + dtMenu.Rows[i]["Message"].ToString() + "','" + dtMenu.Rows[i]["ID"].ToString() + "','" + Convert.ToBoolean(dtMenu.Rows[i]["ISAsync"]) + "' )\"> " + dtMenu.Rows[i]["ActionName"].ToString()+ "</a></li>";
                    output = output + "</ul>";
                }
            }
            return output;
        }
        public string GetContextMenuStringForselectedObject(DataTable dtMenu, int i, string OjectID, string ObjectType, string ObjectVer, int ClassID)
        {
            string output = string.Empty;
            if (dtMenu.Rows[i]["ActionType"].ToString() == "3")
            {
                if (dtMenu.Rows[i]["IsHeader"].ToString() == "1")
                {

                    output = output + "<h4>" + dtMenu.Rows[i]["ActionName"].ToString()+ "</h4>";
                }
                else
                {
                    output = output + "";
                    output = output + "<ul style='font-size:12px'><li > <a  href='#' onclick=\"GetResponseForSelectedObject('" + dtMenu.Rows[i]["ActionType"].ToString() + "','" + dtMenu.Rows[i]["Action"].ToString() + "','" + dtMenu.Rows[i]["Message"].ToString() + "','" + OjectID + "','" + ObjectType + "','" + ObjectVer + "','" + dtMenu.Rows[i]["ID"].ToString() + "','" + Convert.ToBoolean(dtMenu.Rows[i]["ISAsync"]) + "','" + ClassID.ToString() + "')\"> " + dtMenu.Rows[i]["ActionName"].ToString() +"</a></li></ul>";
                    output = output + "";
                }
            }
            return output;
        }

        public string PerformAction(string Action, string ConStr, int ID)
        {
            string Result = string.Empty;
            Result = ExecuteProc(Action, ConStr, ID);
            return Result;
        }
        public string PerformAction(string Action, string ConStr, int ObjectID, int ObjectType, int ObjecyVer, int ID, int ClassID)
        {
            string Result = string.Empty;
            Result = ExecuteProc(Action, ConStr, ObjectID, ObjectType, ObjecyVer, ID, ClassID);
            return Result;
        }

        public DataTable GetData(string ProcName, string ConStr)
        {
            DataTable sqlDt = new DataTable();
            try
            {
                string output = string.Empty;
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = ConStr;
                objConnection.Open();

                SqlCommand Objcmd = new SqlCommand();
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.Connection = objConnection;
                Objcmd.CommandText = ProcName;
                Objcmd.CommandType = CommandType.StoredProcedure;

                SqlDataAdapter SqlDa = new SqlDataAdapter(Objcmd);
                SqlDa.Fill(sqlDt);
                objConnection.Close();
            }
            catch (Exception ex)
            {
                throw ex;
            }
            return sqlDt;
        }

        private string ExecuteProc(string ProcedureName, string ConStr, int ID)
        {
            string Result = string.Empty;
            try
            {
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = ConStr;
                objConnection.Open();
                SqlCommand Objcmd = new SqlCommand(ProcedureName, objConnection);
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.CommandType = CommandType.StoredProcedure;
                Objcmd.Parameters.Add("@OutPut", SqlDbType.VarChar, 1000);
                Objcmd.Parameters.AddWithValue("@ID", ID);
                Objcmd.Parameters["@OutPut"].Direction = ParameterDirection.Output;
                Objcmd.ExecuteNonQuery();
                Result = Objcmd.Parameters["@OutPut"].Value.ToString();
                objConnection.Close();
                return Result;
            }
            catch (Exception ex)
            {
                Result = ex.Message;
            }
            return Result;
        }

        public Boolean ExecuteProc(string ConStr, int ID, out string Username)
        {
            Username = string.Empty;
            Boolean Result = false;
            try
            {
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = ConStr;
                objConnection.Open();
                SqlCommand Objcmd = new SqlCommand("spMfGetProcessStatus", objConnection);
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.CommandType = CommandType.StoredProcedure;
                Objcmd.Parameters.AddWithValue("@ID", ID);
                Objcmd.Parameters.Add("@ProcessStatus", SqlDbType.Bit);
                Objcmd.Parameters["@ProcessStatus"].Direction = ParameterDirection.Output;
                Objcmd.Parameters.Add("@Username", SqlDbType.VarChar,1000);
                Objcmd.Parameters["@Username"].Direction = ParameterDirection.Output;
                Objcmd.ExecuteNonQuery();
                Result = Convert.ToBoolean(Objcmd.Parameters["@ProcessStatus"].Value);
                Username = Objcmd.Parameters["@Username"].Value.ToString();
                objConnection.Close();
                return Result;
            }
            catch (Exception ex)
            {
                Result = false;
            }
            return Result;
        }

        public Boolean UpdateCurrentUserIDForAction(string ConStr,int CurrentUserID,string Action,int ID)
        {
            Boolean Result = true;
            try
            {
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = ConStr;
                objConnection.Open();
                SqlCommand Objcmd = new SqlCommand("spMfUpdateCurrentUserIDForAction", objConnection);
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.CommandType = CommandType.StoredProcedure;
                Objcmd.Parameters.AddWithValue("@UserID", CurrentUserID);
                Objcmd.Parameters.AddWithValue("@Action", Action);
                Objcmd.Parameters.AddWithValue("@ID", ID);


                Objcmd.ExecuteNonQuery();
                objConnection.Close();
                return Result;
            }
            catch (Exception ex)
            {
                Result = false;
            }
            return Result;

        }


        public Boolean UpdateLastExecutedBy(string Constr,int CurrentUserID, int ID)
        {
            Boolean Result = true;
            try
            {
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = Constr;
                objConnection.Open();
                SqlCommand Objcmd = new SqlCommand("spMFUpdateLastExecutedBy", objConnection);
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.CommandType = CommandType.StoredProcedure;
                Objcmd.Parameters.AddWithValue("@ID", ID);
                Objcmd.Parameters.AddWithValue("@UserID", CurrentUserID);
                Objcmd.ExecuteNonQuery();
                objConnection.Close();
                return Result;
            }
            catch (Exception ex)
            {
                Result = false;
            }
            return Result;
        }

        private string ExecuteProc(string ProcedureName, string ConStr, int ObjectID, int ObjectType, int ObjectVer, int ID, int ClassID)
        {
            string Result = string.Empty;
            try
            {
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = ConStr;
                objConnection.Open();
                SqlCommand Objcmd = new SqlCommand(ProcedureName, objConnection);
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.CommandType = CommandType.StoredProcedure;
                Objcmd.Parameters.AddWithValue("@ObjectID", ObjectID);
                Objcmd.Parameters.AddWithValue("@ObjectType", ObjectType);
                Objcmd.Parameters.AddWithValue("@ObjectVer", ObjectVer);
                Objcmd.Parameters.AddWithValue("@ID", ID);
                Objcmd.Parameters.AddWithValue("@ClassID", ClassID);

                Objcmd.Parameters.Add("@OutPut", SqlDbType.VarChar, 1000);
                Objcmd.Parameters["@OutPut"].Direction = ParameterDirection.Output;
                Objcmd.ExecuteNonQuery();
                Result = Objcmd.Parameters["@OutPut"].Value.ToString();
                objConnection.Close();
                return Result;
            }
            catch (Exception ex)
            {
                Result = ex.Message;
            }
            return Result;
        }

        public string GetStoredProcedureNameByContextMenuID(String ActionName, int ActionType)
        {
            string Result = string.Empty;
            try
            {
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = this.ConnectionString;
                objConnection.Open();
                SqlCommand Objcmd = new SqlCommand("spmfGetAction", objConnection);
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.CommandType = CommandType.StoredProcedure;
                Objcmd.Parameters.Add("@Action", SqlDbType.VarChar, 1000);
                Objcmd.Parameters.AddWithValue("@ActionType", ActionType);
                Objcmd.Parameters.AddWithValue("@ActionName", ActionName);
                Objcmd.Parameters["@Action"].Direction = ParameterDirection.Output;
                Objcmd.ExecuteNonQuery();
                Result = Objcmd.Parameters["@Action"].Value.ToString();
                objConnection.Close();
                return Result;
            }
            catch (Exception ex)
            {
                Result = ex.Message;
            }
            return Result;
        }

        public int GetContextMenuID(String ActionName, int ActionType)
        {
            int Result = 0;
            try
            {
                SqlConnection objConnection = new SqlConnection();
                objConnection.ConnectionString = this.ConnectionString;
                objConnection.Open();
                SqlCommand Objcmd = new SqlCommand("spmfGetContextMenuID", objConnection);
                Objcmd.CommandTimeout = CommandtimeOut;
                Objcmd.CommandType = CommandType.StoredProcedure;
                Objcmd.Parameters.Add("@ID", SqlDbType.Int);
                Objcmd.Parameters.AddWithValue("@ActionType", ActionType);
                Objcmd.Parameters.AddWithValue("@ActionName", ActionName);
                Objcmd.Parameters["@ID"].Direction = ParameterDirection.Output;
                Objcmd.ExecuteNonQuery();
                Result = Convert.ToInt32( Objcmd.Parameters["@ID"].Value.ToString());
                objConnection.Close();
                return Result;
            }
            catch (Exception ex)
            {
                Result = 0;
            }
            return Result;
        }
    }
#endif
}