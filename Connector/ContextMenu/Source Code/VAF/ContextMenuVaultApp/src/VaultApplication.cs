using System.Runtime.Serialization;
using MFiles.VAF;
using MFiles.VAF.Common;
using MFilesAPI;
using System;
using System.Diagnostics;
using MFiles.VAF.Configuration.Domain.Dashboards;
using System.IO;
using System.Data;
using MFiles.VAF.AdminConfigurations;

namespace ContextMenuVaultApp
{
    /// <summary>
    /// Simple configuration.
    /// </summary>
    /// 


    /// <summary>
    /// Simple vau0lt application to demonstrate VAF.
    /// </summary>
    public class VaultApplication : VaultApplicationBase, IUsesAdminConfigurations
    {




        #region License, Dashboard, Validation of configuration item Common code

        string Result = string.Empty, StrSelectedObjInput = string.Empty, StrInputs = string.Empty;
        string ConnectionStr = string.Empty;
        EventHandlerEnvironment envNew;
        [MFConfiguration("MFSQLVaultApp", "config")]
        private Configuration _config = new Configuration();
        private ConfigurationNode<Configuration> config { get; set; }
        string VaultName = string.Empty;
        Vault OVault1 = null;
        string ErrorMsg = string.Empty;
  //      int CommandtimeOut = 14400;

        string DatabaseName { get; set; }
        public VaultApplication()
        {
            try
            {
                // Set up the license decoder.
                var licenseDecoder = new MFiles.VAF.Configuration.LicenseDecoder(MFiles.VAF.Configuration.LicenseDecoder.EncMode.TwoKey);
                // This is from the key file (MainKey.PublicXml).
                licenseDecoder.MainKey = "<RSAKeyValue><Modulus>x/LJ8KGT9EECGFeYAc+MR2zWd5LiHtzPpaGifdbFqnXAUFx7VOC3kwzMYwvJn1yD/K6I+PPUvDGV75gZsIwmDafLb6L2cAVkY3bKl923jJDnYeZ/Xg3umSQCkmPhGQKq2Xx4W/8O7HgUuxXNQyJ4ZhqItF9DpzWqCW1V4kYq39U=</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>";
                // This is from the key file (SecondKey.SecretXml)
                licenseDecoder.AltKey = "<RSAKeyValue><Modulus>ymeorpHJf8L+BD9wnODAdQEYy7fSenYG7GlKdtuECUt8rU24aLgZ1Bhw8G1+DXnYajtkOTyV/ah3RbYjF7JgWmVQbztVEZ8WYyEofkrGFo+zCtbhTN11VENxlK1Y7VxxyCaK1mTRTRHKqJywQBHLSZMjJk6jBapl+sfWYhZjdQk=</Modulus><Exponent>AQAB</Exponent><P>/E/L2diRwA8a9VF3Aupy37ynGoTREbnXYq7Aiza734NZlAYzxPcY5xBrmhyaHgaQ8xpgDxZYS6AHuU8WrLBpLQ==</P><Q>zV0Z01G5PQc9OvdBK6+ddCgx5SOlsQV72zCoCRO74q8QsQUZKhnJuNlIwIvDhB/UoGrMs02C9cVGV514j2mszQ==</Q><DP>KTiUMlQKg9kz605S5jwNZnY4ysFWMtIs2Sd5t4TKrtqTwPY+cPh5rg5ltfjkSPGDruPpO63H4RsVB/Ze2vm7RQ==</DP><DQ>C01/eWD7F//I//DR1myw9s6riFgA65BIs9SmuvEqGxzVh1infOi0cIcM+QP4O9Jgqn+WSpwOhCZaa8IP+5yuVQ==</DQ><InverseQ>17b/SYWRGvb/De5sfH/DRWXrefK6BJpLzXXxLjrOsiAiAPjooc1emkoy5+0v9wzyBlGycCRC8SBKX/leLb9BZA==</InverseQ><D>BtLfnO/nhlsvrKjqcYyrOF/A/EmIn5TySnN3SPbl1DTSMZ+vDTh22HRMWQUAjNDUHnPh7Kej/r7dIR0RCgWWmgUBiovEfn2iwjurU6kKjjTRB3h9OpXJ4NKVS3PxzXUe2Gw8QNJgEQ/FlFn4iriWD+5xemLDgkIzNDrgA/odx30=</D></RSAKeyValue>";
                this.License = new LicenseManagerBase<MFiles.VAF.Configuration.LicenseContentBase>(licenseDecoder);
            }
            catch (Exception ex)
            {
                SysUtils.ReportErrorToEventLog(this.EventSourceIdentifier,
                ex.Message);
            }
        }
        public void InitializeAdminConfigurations(IAdminConfigurations adminConfigurations)

        {


            // Add it to the configuration screen.
            this.config = adminConfigurations.AddSimpleConfigurationNode<Configuration>("MFSQL Connector VaultApp", this.DashboardGenerator);

#if !CLOUD
            string Constr = GetConnectionString(OVault1);
            string[] ConnectComponent = Constr.Split(';');
            this.config.CurrentConfiguration.ServerName = GetConnectionComponentName(ConnectComponent[0]);
            this.config.CurrentConfiguration.DatabaseName = GetConnectionComponentName(ConnectComponent[1]);
            this.config.CurrentConfiguration.UserName = GetConnectionComponentName(ConnectComponent[3]);
#endif
            //this.config.Validator = this.CustomValidator;
            this.config.Changed += (oldConfig, newConfig) =>
            {

            };





        }
        private string DashboardGenerator()

        {
            string Path = System.IO.Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]);
            //System.IO.Path.GetDirectoryName(Process.GetCurrentProcess().MainModule.FileName)
            Path = "CAP Badge - Premier(1).jpg";

            var image = DashboardHelper.ImageFileToDataUri(Path);
            var Logo = DashboardHelper.ImageFileToDataUri("logo-color(1).png");
            // return "$< div style = 'background-image: url(" + Logo + ");height:50px;display:block; margin-left:auto;margin-right: auto;width:15%; ' ></ div >< div style = 'height:50px;display:block; margin-left:auto;margin-right: auto;width:40%;font-family:Calibri Light (Headings);font-size: 16px;color:#2f5496' > &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; MFSQL Database File Connector</ div >< br />< div style = 'color:black;font-family:Calibri (Body);font-size: 11px;' > The MFSQL Database File Connector is part of the MFSQL Connector suite.The Connector allows the user to browse and search in M - files to file that is saved in SQL Blobs in a SQL Table.< br />< br /> < br /> Connections : < br /></ div >< br />< br />< br />< div style = 'background-image: url(" + image + ");height:130px;display:block; margin-left:auto;margin-right: auto;width:50%; ' ></ div > ";


            String Title = string.Empty;
            String Description = string.Empty;
            String HelpLink = string.Empty;
            String Helptext = string.Empty;
            string modules = GetModules();
            string[] ModulesList = null;
            if (!string.IsNullOrEmpty(modules) && modules.Length > 0)
                ModulesList = modules.Split(',');

            string ModulesHtml = string.Empty;

            ModulesHtml += "<ul>";

            if (ModulesList != null && ModulesList.Length > 0)
            {
                foreach (var item in ModulesList)
                {

                    ModulesHtml += "<li>";
                    ModulesHtml += (Enum.Modules)Convert.ToInt32(item);
                    ModulesHtml += "</li>";
                }
            }

            ModulesHtml += "</ul>";

#if !CLOUD

            Menu menu = new Menu();
            DataTable dtConfigurationSettings = null;
            try
            {
                string Constr = GetConnectionString(OVault1);
                dtConfigurationSettings = menu.GetData("spMfGetSettingsForCofigurator", Constr);
            }
            catch (Exception ex)
            {
                ErrorMsg = "Database Connection Error please check database connection string.";
            }



            string mfSqlConnectorVersion = string.Empty;
            string assemblyInstallationFolder = string.Empty;
            string fileExportFolderFromSQLServer = string.Empty;
            string fileImportFolderFromSQLServer = string.Empty;
            string mFilesClientInstallationVersionOnSQLServer = string.Empty;

            if (dtConfigurationSettings != null && dtConfigurationSettings.Rows.Count > 0)
            {
                mfSqlConnectorVersion = (dtConfigurationSettings.Rows[0]["ConnectorVersion"]).ToString();
                assemblyInstallationFolder = (dtConfigurationSettings.Rows[0]["AssemblyPath"]).ToString();
                fileExportFolderFromSQLServer = (dtConfigurationSettings.Rows[0]["ExportPath"]).ToString();
                fileImportFolderFromSQLServer = (dtConfigurationSettings.Rows[0]["ImportPath"]).ToString();
                mFilesClientInstallationVersionOnSQLServer = (dtConfigurationSettings.Rows[0]["ClientVersion"]).ToString();

            }

#endif
			string logo = string.Empty;
            string title = string.Empty;
            string tdStyle = string.Empty;
            string ExpiryDate = string.Empty;
            string tableStyle = string.Empty;
            string table = string.Empty;
            string details = string.Empty;
            string footer = string.Empty;
            string Step = string.Empty;
            string lblError = string.Empty;
            try
            {
                Step = "Getting License status";
                string licenseStatus = this.License.LicenseStatus == MFApplicationLicenseStatus.MFApplicationLicenseStatusTrial ? "Trial" : this.License.LicenseStatus == MFApplicationLicenseStatus.MFApplicationLicenseStatusValid ? "Valid" : "Invalid or License not installed";
                Step = "Creating Logo";
                logo = $"<div style='background-image: url({Logo});background-repeat:no-repeat;background-position:center;height:100px;'></div>";
                Step = "Apending Title";
                title = $"<div style='font-size: 14px;text-align:center;font-weight:bold;color:#3572b0;font-family:-apple-system, BlinkMacSystemFont, Segoe UI,Roboto,Noto Sans,Ubuntu,Droid Sans,Helvetica Neue,sans-serif;'>  MFSQL Database Connector</div><br/>";
                tdStyle = "border: 1px solid black;border-collapse: collapse; width: 100px;font-size: 15px;color:black;font-family:-apple-system, BlinkMacSystemFont, Segoe UI,Roboto,Noto Sans,Ubuntu,Droid Sans,Helvetica Neue,sans-serif;";
                Step = "Getting License expiry date.";
                ExpiryDate = this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>() != null ? this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>().LicenseExpireDate : string.Empty;
                tableStyle = "border: 1px solid black;border-collapse: collapse;width:100%";
                Step = "Displaying License Information in table format.";
                table = $"<table style='{tableStyle}'><tr><td style = '{tdStyle}'>License Type</td><td style = '{tdStyle}'>Expiry Date</td><td style = '{tdStyle}'>Modules</td></tr><tr><td style = '{tdStyle}'>{licenseStatus}</td><td style = '{tdStyle}'>{ExpiryDate}</td><td style = '{tdStyle}'>{ModulesHtml }</td></tr></table>";
#if !CLOUD
                Step = "Apending Cofiguration setting.";
                details = $"<ul style=' font-size: 14px;color:black;font-family:-apple-system, BlinkMacSystemFont, Segoe UI,Roboto,Noto Sans,Ubuntu,Droid Sans,Helvetica Neue,sans-serif;'><li>MFSQL Connector Version : {mfSqlConnectorVersion}</li><li>Name of Application : MFSQL Connector</li><li>SQL Server :{ this.config.CurrentConfiguration.ServerName}</li><li>Database :{this.config.CurrentConfiguration.DatabaseName}</li><li>MFSQL Database User : {this.config.CurrentConfiguration.UserName}</li><li>Assembly installation folder :{assemblyInstallationFolder}</li><li>File Export Folder from SQL Server :{fileExportFolderFromSQLServer}</li><li>File Import Folder from SQL Server :{fileImportFolderFromSQLServer}</li><li>M-Files Client installation version on SQL Server :{mFilesClientInstallationVersionOnSQLServer}</li></ul>";
#endif
                Step = "Creating footer.";
                footer = $"<div style='background-image: url({image});background-repeat:no-repeat;background-position:center;height:150px;background-size:auto;'></div>";



            }
            catch (Exception ex)
            {
                ErrorMsg = "Error at Dashboard Design at step: " + Step;
            }

            if (!string.IsNullOrEmpty(ErrorMsg))
            {
                lblError = $"<br/><br/><div ><p style='font-size:14px;color:Red;font-weight:bold;font-family:-apple-system, BlinkMacSystemFont, Segoe UI,Roboto,Noto Sans,Ubuntu,Droid Sans,Helvetica Neue,sans-serif;'><br/>{ErrorMsg}</p></div>";
            }
            StatusDashboard dashboard;
            dashboard = new StatusDashboard()
            {
                Contents = {
                                  new DashboardPanel()
                                  {
                                         Title = "Summary",
                                         Background = PanelBackground.None,
                                         Commands = {
                                                //DashboardHelper.CreateDomainCommand( "Remove Connection", "RemoveConfiguration" )
                                         },

                                       //  InnerContent = new DashboardCustomContent($"<div style='background-image: url({Logo});height:50px;display:block; margin-left:auto;margin-right: auto;width:15%; '></div><div style='height:50px;display:block; margin-left:auto;margin-right: auto;width:40%;font-family:Calibri Light (Headings);font-size: 16px;color:#2f5496'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;MFSQL Database File Connector</div><br/><div style='color:black;font-family:Calibri (Body);font-size: 11px;'> The MFSQL Database File Connector is part of the MFSQL Connector suite. The Connector allows the user to browse and search in M-files to file that is saved in SQL Blobs in a SQL Table.<br/><br/> </div><br/><br/><br/><div style='background-image: url({image});height:130px;display:block; margin-left:auto;margin-right: auto;width:50%; '></div>" )
                                         InnerContent = new DashboardCustomContent($"{logo}{title}{table}{details}{lblError}{footer}")
                                  }
                           }
            };
            return dashboard.ToString();
        }
        public override void StartOperations(Vault vaultPersistent)
        {

            // Evaluate the license validity.
            this.License.Evaluate(vaultPersistent, false);

            string ModuleValues = string.Empty;

            OVault1 = vaultPersistent;
            VaultName = vaultPersistent.Name;

            // Output the license status.
            switch (this.License.LicenseStatus)
            {
                case MFApplicationLicenseStatus.MFApplicationLicenseStatusTrial:
                    {
                        SysUtils.ReportToEventLog(
                        "Application is running in a trial mode.",
                        System.Diagnostics.EventLogEntryType.Warning);
                        break;
                    }
                case MFApplicationLicenseStatus.MFApplicationLicenseStatusValid:
                    {
                        SysUtils.ReportInfoToEventLog(
                        "Application is licensed.");
                        break;
                    }
                default:
                    {
                        SysUtils.ReportToEventLog(
                        $"Application is in an unexpected state: { this.License.LicenseStatus}.", EventLogEntryType.Error);
                        break;
                    }
            }

            base.StartOperations(vaultPersistent);
        }
        private string GetModules()
        {

            string ModuleValues = string.Empty;
            if (this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>() != null)
            {

                var modulesList = this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>().Modules;

                if (modulesList != null)
                {
                    foreach (var item in modulesList)
                        ModuleValues += item + ",";

                    ModuleValues = ModuleValues.Remove(ModuleValues.Length - 1, 1);
                    return ModuleValues;
                }
            }
            return string.Empty;


        }
        [VaultExtensionMethod("GetLicenseKeyFromCloudVault", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        public string GetLicenseKeyFromCloudVault(EventHandlerEnvironment env)
        {
            string Result = string.Empty;
            try
            {
                string LicenseExpiryDate = this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>().LicenseExpireDate;
                string ModuleValues = GetModules();
                string LicenseKey = string.Empty;
                Laminin.CryptoEngine.Encrypt(ModuleValues + "|" + LicenseExpiryDate, out LicenseKey);
                Result = LicenseKey;
            }
            catch (Exception ex)
            {

                Result = "";
            }
            return Result;
        }




        #endregion


        #region OnPremise code

#if !CLOUD

        public string GetConnectionComponentName(string Input)
        {
            string[] Output = Input.Split('=');
            string Result = string.Empty;
            if (Output.Length > 0)
            {
                Result = Output[1];
            }
            return Result;
        }
        //public void CheckLicenseStatus(EventHandlerEnvironment env)
        //{
        //    try
        //    {
        //        // Evaluate the license validity.
        //        //this.License.Evaluate(vaultPersistent, false);

        //        string ModuleValues = string.Empty;



        //        // Output the license status.
        //        switch (this.License.LicenseStatus)
        //        {
        //            case MFApplicationLicenseStatus.MFApplicationLicenseStatusTrial:
        //                {
        //                    SysUtils.ReportToEventLog(
        //                    "Application is running in a trial mode.",
        //                    System.Diagnostics.EventLogEntryType.Warning);
        //                    string LicenseExpiryDate = this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>().LicenseExpireDate;
        //                    ModuleValues = GetModules();
        //                    string LicenseKey = string.Empty;
        //                    Laminin.CryptoEngine.Encrypt(ModuleValues + "|" + LicenseExpiryDate, out LicenseKey);
        //                    this.config.CurrentConfiguration.LicenseKey = LicenseKey;
        //                    UpdateMFModule(ModuleValues, VaultName, LicenseExpiryDate, GetConnectionString(env));
        //                    CreateSqlForModule(LicenseExpiryDate, VaultName, ModuleValues); //Added for task #1220
        //                    break;
        //                }
        //            case MFApplicationLicenseStatus.MFApplicationLicenseStatusValid:
        //                {
        //                    SysUtils.ReportInfoToEventLog(
        //                    "Application is licensed.");
        //                    string LicenseExpiryDate = this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>().LicenseExpireDate;
        //                    ModuleValues = GetModules();
        //                    string LicenseKey = string.Empty;
        //                    Laminin.CryptoEngine.Encrypt(ModuleValues + "|" + LicenseExpiryDate, out LicenseKey);
        //                    this.config.CurrentConfiguration.LicenseKey = LicenseKey;
        //                    UpdateMFModule(ModuleValues, VaultName, LicenseExpiryDate, GetConnectionString(env));
        //                    CreateSqlForModule(LicenseExpiryDate, VaultName, ModuleValues); //Added for task #1220
        //                    break;
        //                }
        //            case MFApplicationLicenseStatus.MFApplicationLicenseStatusInvalid:
        //                {
        //                    SysUtils.ReportInfoToEventLog(
        //                    "Application is Invalid.");
        //                    ModuleValues = GetModules();
        //                    string LicenseExpiryDate = this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>().LicenseExpireDate;
        //                    string LicenseKey = string.Empty;
        //                    Laminin.CryptoEngine.Encrypt(ModuleValues + "|" + LicenseExpiryDate, out LicenseKey);
        //                    this.config.CurrentConfiguration.LicenseKey = LicenseKey;
        //                    UpdateMFModule(ModuleValues, VaultName, LicenseExpiryDate, GetConnectionString(env));
        //                    CreateSqlForModule(LicenseExpiryDate, VaultName, ModuleValues); //Added for task #1220

        //                    break;
        //                }
        //            default:
        //                {
        //                    SysUtils.ReportToEventLog(
        //                    $"Application is in an unexpected state: { this.License.LicenseStatus}.", EventLogEntryType.Error);
        //                    break;
        //                }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        throw ex;
        //    }
        //}

        [VaultExtensionMethod("CheckUserContextMenuAccess", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        public string CheckUserContextMenuAccess(EventHandlerEnvironment env)
        {
            string Output = string.Empty;
            try
            {

                Output = "0";
                int UserGroupID = 0;
                Menu ObjMenu = new Menu();
                UserGroupID = env.Vault.UserGroupOperations.GetUserGroupIDByAlias("UsrGrp_ContextMenu");
                if (UserGroupID > 0)
                {
                    IDs Members = env.Vault.UserGroupOperations.GetUserGroup(UserGroupID).Members;
                    if (Members.Count > 0)
                    {
                        foreach (var item in Members)
                        {
                            if (Convert.ToInt32(item) < 0)  //Indicates that Usergroup in 
                            {
                                bool IsAccess = ObjMenu.CheckUserGroupContextMenuAccess(env.CurrentUserID, Convert.ToInt32(item) * -1, env.Vault);
                                if (IsAccess)
                                {
                                    Output = "1";
                                    break;
                                }

                            }
                            else
                            {

                                if (Convert.ToInt32(item) == env.CurrentUserID)
                                {
                                    Output = "1";
                                    break;
                                }
                                else
                                {
                                    Output = env.CurrentUserID.ToString();
                                }
                            }
                        }
                    }

                }
                //string LicenseExpiryDate = this.License.Content<MFiles.VAF.Configuration.LicenseContentBase>().LicenseExpireDate;
                //string ModuleValues = GetModules();
                //String LicenseKey = string.Empty;
                //Laminin.CryptoEngine.Encrypt(ModuleValues + "|" + LicenseExpiryDate, out LicenseKey);
                //if (this.config.CurrentConfiguration.LicenseKey != LicenseKey) CheckLicenseStatus(env);
            }
            catch (Exception ex)
            {
                Output = Output + "|" + ex.Message;
            }

            return Output;


        }


        //private void UpdateMFModule(string ModuleValues, string VaultName, string LicenseExpiryDate, string constr)
        //{
        //    //string conStr = GetConnectionStringByVault(objVault);


        //    try
        //    {
        //        string LicenseKey = string.Empty;
        //        Laminin.CryptoEngine.Encrypt(ModuleValues + "|" + LicenseExpiryDate, out LicenseKey);
        //        SqlConnection objConnection = new SqlConnection();
        //        objConnection.ConnectionString = constr;
        //        objConnection.Open();
        //        SqlCommand Objcmd = new SqlCommand("spMFUpdateModule", objConnection);
        //        Objcmd.CommandTimeout = CommandtimeOut;
        //        Objcmd.CommandType = CommandType.StoredProcedure;
        //        Objcmd.Parameters.AddWithValue("@ModuleValues", ModuleValues);
        //        Objcmd.Parameters.AddWithValue("@VaultName", VaultName);
        //        Objcmd.Parameters.AddWithValue("@LicenseExpiryDate", LicenseExpiryDate);
        //        //Objcmd.Parameters.AddWithValue("@LicenseErrorMessage", "License is not valid.");
        //        //Objcmd.Parameters.AddWithValue("@ModuleErrorMessage", "You dont have access to this module.");
        //        Objcmd.Parameters.AddWithValue("@LicenseKey", LicenseKey);

        //        Objcmd.ExecuteNonQuery();
        //        //Result = Objcmd.Parameters["@OutPut"].Value.ToString();
        //        objConnection.Close();
        //        //return Result;
        //    }
        //    catch (Exception ex)
        //    {
        //        throw ex;
        //    }
        //}

        [VaultExtensionMethod("GetContextMenuJson", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string GetContextMenuJson(EventHandlerEnvironment env)
        {
           
            string ConStr = GetConnectionString(env);
            Menu ObjMenu = new Menu();
            string Result = ObjMenu.GetContextMenu(ConStr, env.Vault, env.CurrentUserID);
            return Result;
        }

        [VaultExtensionMethod("GetContextMenuForSelectedObject", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string GetContextMenuForSelectedObject(EventHandlerEnvironment env)
        {

            string Input = env.Input;
            string[] ObjectDetails = Input.Split('|');
            string ObjectID = ObjectDetails[0];
            string ObjectType = ObjectDetails[1];
            string objectVer = ObjectDetails[2];

            //Added for Task 983
            string Name = string.Empty;
            int ClassID = 0;
            ObjID Obj_ID = new ObjID() { ID = Convert.ToInt32(ObjectID), Type = Convert.ToInt32(ObjectType) };
            ObjVer ObjVer = new ObjVer() { ID = Convert.ToInt32(ObjectID), ObjID = Obj_ID, Version = Convert.ToInt32(objectVer) };
            MFilesAPI.PropertyValues m_oPropertyValues = new MFilesAPI.PropertyValues();
            m_oPropertyValues = env.Vault.ObjectPropertyOperations.GetProperties(ObjVer, true);
            //Added for Task 983

            foreach (PropertyValue pf in m_oPropertyValues)
            {
                if (pf.PropertyDef == 0)
                {
                    Name = pf.Value.DisplayValue;
                }

                if (pf.PropertyDef == 100)
                {
                    var ClassID12 = ((object[,])((MFilesAPI.TypedValueClass)pf.Value).Value)[0, 0];

                    ClassID = Convert.ToInt32(ClassID12);
                }
            }
            string ConStr = GetConnectionString(env);
            Menu ObjMenu = new Menu();
            string Result = ObjMenu.GetContextMenuForSelectedObject(ConStr, ObjectID, ObjectType, objectVer, Name, ClassID, env.Vault, env.CurrentUserID);
            return Result;
        }

        [VaultExtensionMethod("GetPerformActionJson", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string GetPerformActionJson(EventHandlerEnvironment env)
        {
            envNew = env;
            ConnectionStr = GetConnectionString(env);
            StrInputs = env.Input;
            BackgroundOperation operation = this.BackgroundOperations.CreateBackgroundOperation("OperationName", BackgroundOperationMethod);
            operation.RunOnce();
            return Result.Replace("\\n", "\n");
        }

        [VaultExtensionMethod("GetPerformAction", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string GetPerformAction(EventHandlerEnvironment env)
        {

            string[] parameters = env.Input.Split('|');
            string ConStr = GetConnectionString(env);
            UpdateUserIDInCurrentAction(env, ConStr, parameters[0], Convert.ToInt32(parameters[1].ToString()));
            Menu ObjMenu = new Menu();
            Result = ObjMenu.PerformAction(parameters[0], ConStr, Convert.ToInt32(parameters[1].ToString()));
            ObjMenu.UpdateLastExecutedBy(ConStr, env.CurrentUserID, Convert.ToInt32(parameters[1].ToString()));
            return Result.Replace("\\n", "\n");
        }

        [VaultExtensionMethod("GetProcessStatus", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string GetProcessStatus(EventHandlerEnvironment env)
        {
            Boolean Output;
            string Result = string.Empty;
            string ID = env.Input;
            //string[] Parameters = Inputs.Split('|');
            //if (Parameters.Length > 0)
            //{
            string ConStr = GetConnectionString(env);
            Menu ObjMenu = new Menu();
            string UserName = string.Empty;
            Output = ObjMenu.ExecuteProc(ConStr, Convert.ToInt32(ID), out UserName);
            if (Output)
            {
                Result = "Process is Already running by the user " + UserName;
            }
            else
            {
                Result = "true";
            }

            //}
            return Result;
        }
        [VaultExtensionMethod("GetPerformActionOnSelectedObjectNew", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string GetPerformActionOnSelectedObject(EventHandlerEnvironment env)
        {

            envNew = env;
            StrSelectedObjInput = env.Input;
            ConnectionStr = GetConnectionString(env);
            BackgroundOperation operation = this.BackgroundOperations.CreateBackgroundOperation("OperationName", BackgroudOperation1);
            operation.RunOnce();
            return Result.Replace("\\n", "\n");
        }

        [VaultExtensionMethod("GetPerformActionOnSelectedObjectForSynchProcess", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string GetPerformActionOnSelectedObjectForSynchProcess(EventHandlerEnvironment env)
        {

            string Result = string.Empty;
            string[] ObjectDetails = env.Input.Split('|');
            string Action = ObjectDetails[0];
            string ObjectID = ObjectDetails[1];
            string ObjectType = ObjectDetails[2];
            string objectVer = ObjectDetails[3];
            string ID = ObjectDetails[4];
            string ClassID = ObjectDetails[5];
            string ConStr = GetConnectionString(env);
            UpdateUserIDInCurrentAction(env, ConStr, Action, Convert.ToInt32(ID));
            Menu ObjMenu = new Menu();
            Result = ObjMenu.PerformAction(Action, ConStr, Convert.ToInt32(ObjectID), Convert.ToInt32(ObjectType), Convert.ToInt32(objectVer), Convert.ToInt32(ID), Convert.ToInt32(ClassID));
            ObjMenu.UpdateLastExecutedBy(ConStr, env.CurrentUserID, Convert.ToInt32(ID));
            return Result.Replace("\\n", "\n");
        }


        [VaultExtensionMethod("AsynchAction", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string AsynchAction(EventHandlerEnvironment env)
        {
            string Input = env.Input;
            string[] parameters = Input.Split('|');
            //  string Action = "spMFInsertStudent";
            string ConStr = GetConnectionString(env);
            Menu ObjMenu = new Menu();
            string Result = ObjMenu.PerformAction(parameters[0], ConStr, Convert.ToInt32(parameters[1].ToString()));


            // Simulate long-running process.
            System.Threading.Thread.Sleep(10 * 1000);

            return Result.Replace("\\n", "\n");
        }

        [VaultExtensionMethod("PerformActionMethod", RequiredVaultAccess = MFVaultAccess.MFVaultAccessNone)]
        private string PerformActionMethod(EventHandlerEnvironment env)
        {
            Menu ObjData = new Menu();
            string Result = string.Empty;

            //Get Connection string value from vault
            ObjData.ConnectionString = GetConnectionString(env);

            //Get input parameters from vb script
            var ObjDetails = Newtonsoft.Json.JsonConvert.DeserializeObject<ObjectDetails>(env.Input) ?? new ObjectDetails();

            // Get Stored Procedure name by ActionName and ActionType
            string ProcedureName = ObjData.GetStoredProcedureNameByContextMenuID(ObjDetails.ActionName, Convert.ToInt32(ObjDetails.ActionTypeID));
            int ContextMenuID = ObjData.GetContextMenuID(ObjDetails.ActionName, Convert.ToInt32(ObjDetails.ActionTypeID));
            if (!string.IsNullOrEmpty(ProcedureName))
            {
                switch (ObjDetails.ActionTypeID)
                {
                    case "4":  //Calling stored procedure without parameters
                        envNew = env;
                        ConnectionStr = GetConnectionString(env);
                        StrInputs = string.Empty;
                        StrInputs = ProcedureName + "|" + ContextMenuID.ToString();
                        BackgroundOperation operation1 = this.BackgroundOperations.CreateBackgroundOperation("OperationName", BackgroundOperationMethod);
                        operation1.RunOnce();
                        //Result = ObjData.PerformAction(ProcedureName, ObjData.ConnectionString, 0);
                        break;
                    case "5": //Calling stored procedure with parameters
                        envNew = env;
                        StrSelectedObjInput = string.Empty;
                        StrSelectedObjInput = ProcedureName + "|" + ObjDetails.ObjectID.ToString() + "|" + ObjDetails.ObjectType.ToString() + "|" + ObjDetails.Objectver.ToString() + "|" + ContextMenuID.ToString() + "|" + ObjDetails.ClassID.ToString();
                        ConnectionStr = GetConnectionString(env);
                        BackgroundOperation operation = this.BackgroundOperations.CreateBackgroundOperation("OperationName", BackgroudOperation1);
                        operation.RunOnce();
                        //Result = ObjData.PerformAction(ProcedureName, ObjData.ConnectionString, Convert.ToInt32(ObjDetails.ObjectID), Convert.ToInt32(ObjDetails.ObjectType), Convert.ToInt32(ObjDetails.Objectver), 0,Convert.ToInt32(ObjDetails.ClassID));
                        break;

                }
            }
            else
            {
                Result = "Procedure not found";
            }

            return Result;



        }

        private string GetConnectionString(EventHandlerEnvironment env)
        {
            string Result = string.Empty;
            //Result = "Data Source=" + this.config.CurrentConfiguration.ServerName + ";Initial Catalog =" + this.config.CurrentConfiguration.DatabaseName + ";User Id=" + this.config.CurrentConfiguration.UserName + ";Password=" + this.config.CurrentConfiguration.Password + ";";
            MFilesAPI.Vault oVault = env.Vault;
            MFilesAPI.SearchConditions oSearchConditions = new MFilesAPI.SearchConditions();
            //' Create a search condition for the object type
            MFilesAPI.SearchCondition oSearchCondition = new MFilesAPI.SearchCondition();

            // ' Create a search condition for the object type id
            int iObjectTypeId = oVault.ObjectTypeOperations.GetObjectTypeIDByAlias("oMFSQLConfiguration");
            oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            oSearchCondition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeObjectTypeID;
            oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeLookup, iObjectTypeId);
            oSearchConditions.Add(-1, oSearchCondition);

            //' Create a search condition is not deleted
            oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            oSearchCondition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeDeleted;
            oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, false);
            oSearchConditions.Add(-1, oSearchCondition);

            //' By Integration Status Display = "In Epicor"
            oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            oSearchCondition.Expression.DataPropertyValuePropertyDef = oVault.PropertyDefOperations.GetPropertyDefIDByAlias("SettingsName");
            oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeText, "ConnectionString");
            oSearchConditions.Add(-1, oSearchCondition);

            MFilesAPI.ObjectSearchResults oSearchResults = oVault.ObjectSearchOperations.SearchForObjectsByConditionsEx(oSearchConditions, MFilesAPI.MFSearchFlags.MFSearchFlagNone, false);

            MFilesAPI.ObjectVersions oObjectVersions = new MFilesAPI.ObjectVersions();
            oObjectVersions = oSearchResults.GetAsObjectVersions();
            foreach (ObjectVersion oObjectVersion in oObjectVersions)
            {
                MFilesAPI.PropertyValues m_oPropertyValues = new MFilesAPI.PropertyValues();
                m_oPropertyValues = oVault.ObjectPropertyOperations.GetProperties(oObjectVersion.ObjVer, true);
                int iPropDef1 = oVault.PropertyDefOperations.GetPropertyDefIDByAlias("SettingsDetail");
                if (m_oPropertyValues.IndexOf(iPropDef1) != -1)
                {
                    dynamic szProfVal = m_oPropertyValues.SearchForProperty(iPropDef1).TypedValue.DisplayValue;
                    Result = szProfVal;
                }
            }

            return Result;


        }

        private string GetConnectionString(Vault oVlt)
        {
            string Result = string.Empty;
            //Result = "Data Source=" + this.config.CurrentConfiguration.ServerName + ";Initial Catalog =" + this.config.CurrentConfiguration.DatabaseName + ";User Id=" + this.config.CurrentConfiguration.UserName + ";Password=" + this.config.CurrentConfiguration.Password + ";";
            MFilesAPI.Vault oVault = oVlt;
            MFilesAPI.SearchConditions oSearchConditions = new MFilesAPI.SearchConditions();
            //' Create a search condition for the object type
            MFilesAPI.SearchCondition oSearchCondition = new MFilesAPI.SearchCondition();

            // ' Create a search condition for the object type id
            int iObjectTypeId = oVault.ObjectTypeOperations.GetObjectTypeIDByAlias("oMFSQLConfiguration");
            oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            oSearchCondition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeObjectTypeID;
            oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeLookup, iObjectTypeId);
            oSearchConditions.Add(-1, oSearchCondition);

            //' Create a search condition is not deleted
            oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            oSearchCondition.Expression.DataStatusValueType = MFStatusType.MFStatusTypeDeleted;
            oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeBoolean, false);
            oSearchConditions.Add(-1, oSearchCondition);

            //' By Integration Status Display = "In Epicor"
            oSearchCondition.ConditionType = MFConditionType.MFConditionTypeEqual;
            oSearchCondition.Expression.DataPropertyValuePropertyDef = oVault.PropertyDefOperations.GetPropertyDefIDByAlias("SettingsName");
            oSearchCondition.TypedValue.SetValue(MFDataType.MFDatatypeText, "ConnectionString");
            oSearchConditions.Add(-1, oSearchCondition);

            MFilesAPI.ObjectSearchResults oSearchResults = oVault.ObjectSearchOperations.SearchForObjectsByConditionsEx(oSearchConditions, MFilesAPI.MFSearchFlags.MFSearchFlagNone, false);

            MFilesAPI.ObjectVersions oObjectVersions = new MFilesAPI.ObjectVersions();
            oObjectVersions = oSearchResults.GetAsObjectVersions();
            foreach (ObjectVersion oObjectVersion in oObjectVersions)
            {
                MFilesAPI.PropertyValues m_oPropertyValues = new MFilesAPI.PropertyValues();
                m_oPropertyValues = oVault.ObjectPropertyOperations.GetProperties(oObjectVersion.ObjVer, true);
                int iPropDef1 = oVault.PropertyDefOperations.GetPropertyDefIDByAlias("SettingsDetail");
                if (m_oPropertyValues.IndexOf(iPropDef1) != -1)
                {
                    dynamic szProfVal = m_oPropertyValues.SearchForProperty(iPropDef1).TypedValue.DisplayValue;
                    Result = szProfVal;
                }
            }

            return Result;


        }



        private void BackgroundOperationMethod()
        {
            //string Input = envNew.Input;
            string[] parameters = StrInputs.Split('|');
            //  string Action = "spMFInsertStudent";
            string ConStr = ConnectionStr;
            UpdateUserIDInCurrentAction(envNew, ConnectionStr, parameters[0], Convert.ToInt32(parameters[1].ToString()));
            Menu ObjMenu = new Menu();
            Result = ObjMenu.PerformAction(parameters[0], ConStr, Convert.ToInt32(parameters[1].ToString()));
            ObjMenu.UpdateLastExecutedBy(ConStr, envNew.CurrentUserID, Convert.ToInt32(parameters[1].ToString()));
        }

        private void BackgroudOperation1()
        {
            string Result = string.Empty;
            // string Input = envNew.Input;
            //string[] ObjectDetails = Input.Split('|');
            string[] ObjectDetails = StrSelectedObjInput.Split('|');
            string Action = ObjectDetails[0];
            string ObjectID = ObjectDetails[1];
            string ObjectType = ObjectDetails[2];
            string objectVer = ObjectDetails[3];
            string ID = ObjectDetails[4];
            string ClassID = ObjectDetails[5];
            //string ConStr = GetConnectionString(envNew);
            string ConStr = ConnectionStr;
            UpdateUserIDInCurrentAction(envNew, ConnectionStr, Action, Convert.ToInt32(ID));
            Menu ObjMenu = new Menu();
            Result = ObjMenu.PerformAction(Action, ConStr, Convert.ToInt32(ObjectID), Convert.ToInt32(ObjectType), Convert.ToInt32(objectVer), Convert.ToInt32(ID), Convert.ToInt32(ClassID));
            ObjMenu.UpdateLastExecutedBy(ConStr, envNew.CurrentUserID, Convert.ToInt32(ID));
            // return Result.Replace("\\n", "\n"); // The implementation for background operation.
        }

        private void UpdateUserIDInCurrentAction(EventHandlerEnvironment env, string ConnectioString, string ActionName, int ID)
        {
            //string ConStr = GetConnectionString();
            int CurrenUserID = env.CurrentUserID;
            Menu ObjMenu = new Menu();
            Boolean Result = ObjMenu.UpdateCurrentUserIDForAction(ConnectioString, CurrenUserID, ActionName, ID);

        }



        #region Task 1220
        private void CreateSqlForModule(String LicenseExpiryDate, string VaultName, string ModuleValues)
        {

            string LicenseKey = string.Empty;
            Laminin.CryptoEngine.Encrypt(ModuleValues + "|" + LicenseExpiryDate, out LicenseKey);
            //string UserActiveDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);  
            string FileDirectory = "C:\\Program Files (x86)\\Common Files\\MFSQLConnector";
            if (!Directory.Exists(FileDirectory))
            {
                Directory.CreateDirectory(FileDirectory);
            }
            string physicalPath = FileDirectory + "\\Spmflicenseupdate.Sql";
            if (!File.Exists(physicalPath))
            {

                var Obj = File.Create(physicalPath);
                Obj.Close();
            }
            else
            {
                File.Delete(physicalPath);
                var Obj = File.Create(physicalPath);
                Obj.Close();
            }

            string Sql = @"USE [" + this.config.CurrentConfiguration.DatabaseName.ToString() + @"]
                            GO
                            TRUNCATE TABLE[dbo].[MFModule]
                            INSERT INTO[dbo].[MFModule]
                           (
                            [ModuleID]
                           ,[ExpiryDate]
                           ,[VaultName]
                           ,[DateCreated]
                           ,[DateModified]
                           ,[LicenseErrorMessage]
                           ,[ModuleErrorMessage]
                           ,[LicenseKey])
                            VALUES
                            (
                              '" + ModuleValues + @"'
                             ,'" + LicenseExpiryDate + @"'
                             ,'" + VaultName + @"'
                             ,'" + DateTime.Now.ToString() + @"'
                             ,'" + DateTime.Now.ToString() + @"'
                             ,'Licence is invalid'
                             ,'The executed procedure is not included in the license'
                             ,'" + LicenseKey + @"')
                             GO";

            StreamWriter sw = new StreamWriter(physicalPath, true);
            sw.WriteLine(Sql);
            sw.Flush();
            sw.Close();

        }
        #endregion
#endif
        #endregion

        #region Cloud code
#if CLOUD

       
#endif


        #endregion

    }

#if !CLOUD
    [DataContract]
    public class ObjectDetails
    {
        [DataMember(Name = "ObjectID")]
        public string ObjectID { get; set; }
        [DataMember(Name = "ObjectType")]
        public string ObjectType { get; set; }
        [DataMember(Name = "Objectver")]
        public string Objectver { get; set; }

        [DataMember(Name = "ActionName")]
        public string ActionName { get; set; }

        [DataMember(Name = "ActionTypeID")]
        public string ActionTypeID { get; set; }

        [DataMember(Name = "ClassID")]
        public string ClassID { get; set; }
    }


    //public class LicenseContent : LicenseContentBase
    //{
    //    [DataMember]
    //    public string[] Test { get; set; }
    //}
#endif
}