select objId,MFVersion,Document_ID,Single_File,* from MFOtherDocument where Single_File=0
select objId,MFVersion,Document_ID,Single_File,* from MFOtherDocument where Single_File=1

select objId,MFVersion,Document_ID,Single_File,* from MFOtherDocument where Process_ID=1
SELECT ID,ObjID,MFVersion,isnull(Single_File,0),isnull(Name_Or_Title,'') from [MFOtherDocument] WHERE Process_ID = 1 AND Deleted = 0
select * from MFLog order by 1 desc

Update MFOtherDocument set Process_ID=1 where  ObjID in (71,74,77)  ObjID is not null and Deleted=0

select Filecount,OBJID,* from MFOtherDocument where ObjID in (71,74,77)
select * from MFClass

select * from MFObjectType where ID=118

select convert(varchar(10),getdate(),105)

select * from MFVaultSettings

select * from MFSalesInvoice

update MFSalesInvoice set Process_ID=1 where Deleted=0

------UPdating Filecount Column by dpMFUPdateTable------------------

select * from MFClass where MFID=2
drop table MFOtherDocument
exec spmfcreatetable 'Other Document''s'
exec spMFUpdateTable 'MFOtherDocument',1
select FileCount,Single_File,* from MFOtherDocument


drop table MFPurchaseInvoice
exec spmfcreatetable 'Purchase Invoice'
exec spMFUpdateTable 'MFPurchaseInvoice',1
select FileCount,Single_File,* from MFPurchaseInvoice


exec spMFUpdateTable 'MFOtherDocument',0
select FileCount,Single_File,* from MFOtherDocument order by ID desc


INSERT INTO [dbo].[MFOtherDocument]
           (
		   --[GUID]
     --      ,[MX_User_ID]
           --,[Class]
           [Class_ID]
           --,[Created]
           --,[Created_by]
           --,[Created_by_ID]
           ,[Description]
           ,[Keywords]
           --,[MF_Last_Modified]
           --,[MF_Last_Modified_By]
           --,[MF_Last_Modified_By_ID]
           ,[Name_Or_Title]
           ,[Single_File]
           --,[State]
           ,[State_ID]
           --,[Workflow]
           ,[Workflow_ID]
           --,[LastModified]
           ,[Process_ID]
           --,[ObjID]
         --  ,[ExternalID]
           --,[MFVersion]
           ,[Deleted]
           --,[Update_ID]
           --,[Customer]
           ,[Customer_ID]
           ,[Document]
           ,[Document_Date]
           ,[Document_ID]
           --,[Is_Template]
           --,[Project]
           ,[Project_ID])
     VALUES
           (
		   		   --[GUID]
     --      ,[MX_User_ID]
           --,[Class]
           1
           --,[Created]
           --,[Created_by]
           --,[Created_by_ID]
           ,null
           ,null
           --,[MF_Last_Modified]
           --,[MF_Last_Modified_By]
           --,[MF_Last_Modified_By_ID]
           ,'DisplayIDTesting_2'
           ,0
           --,[State]
           ,null
           --,[Workflow]
           ,null
           --,[LastModified]
           ,1
           --,[ObjID]
          -- ,'RhealAVP'
           --,[MFVersion]
           ,0
           --,[Update_ID]
           --,[Customer]
           ,null
           ,null
           ,null
           ,300
           --,[Is_Template]
           --,[Project]
           ,null
		   )


		   select FileCount ,* from MFPicture

		   update MFCustomer set Process_ID=1
		   exec spMFUpdateTable 'MFPicture',1
		   select * from MFClass


		   select * from MFLog order by 1 desc

		   drop table MFPicture

		  exec  spmfcreatetable 'Picture'
		  update MFCustomer set Process_ID=1
		  exec spMFExportFiles 'MFCustomer'

		  select * from MFCustomer
		  exec spmfcreatetable 'Order'
		  select Filecount,* from MFOrder
		  update MForder  set Process_ID=1
		    exec spMFUpdateTable 'MFOrder',1
		  --exec spMFExportFiles 'MFOrder','C:\\MFSQLExport\\',null,null,null,1,1,1


		  select * from MFClass

		  update mfClass set FilePath='SalesInvoice' where ID=1492
		  select Process_ID,Single_File,* from MFSalesInvoice

   update MFSalesInvoice set Process_ID=1 

		  select  * from MFSalesInvoice
--exec spMFExportFiles 'MFSalesInvoice','E:\\MFSQLExport\\','Customer','Created_by',null,1,1,1 MFPurchaseInvoice

exec spMFExportFiles 'MFSalesInvoice','C:\\MFSQLExport\\','Customer','Created_by',null,1,1,1
--C:\\MFSQLExport\\\Purchase Invoice\Document\04-07-2017\ 

SELECT ID,ObjID,MFVersion,isnull(Single_File,0),isnull(Name_Or_Title,''), 
				              isnull(Customer, '') as PathProperty_L1, isnull(Created_by,'') as PathProperty_L2, isnull(Document_Date,'') as PathProperty_L3 from [MFSalesInvoice] WHERE Process_ID = 1    AND Deleted = 0
select * from MFLog order by 1 desc

SELECT ID,ObjID,MFVersion,isnull(Single_File,0),isnull(Name_Or_Title,''), 
				              isnull(Customer, '') as PathProperty_L1, isnull(Created_by,'') as PathProperty_L2, isnull(Document_Date,'') as PathProperty_L3 from [MFSalesInvoice] WHERE Process_ID = 1    AND Deleted = 0



select * from MFOtherDocument

select * from MFPicture

   update MFPicture set Process_ID=1 

   exec spMFExportFiles 'MFPicture','C:\\MFSQLExport\\Picture','Created_by',null,null,1,1,1


   select * from MFClass

   update MFClass set FilePath='MFPurchaseInvoice' where id=1489

   EXEC [dbo].[spMFCreateTable]
   	@ClassName = N''	-- nvarchar(128)
     , @Debug = 0			-- smallint
   
   select * From MFOtherDocument WHERE id < 10 AND [FileCount] > 0

   update MFOtherDocument set process_ID=1 WHERE id < 8 AND [FileCount] > 0
    update MFSalesInvoice set process_ID=1

   truncate table MFCustomer

   exec spMFUpdateTable 'MFCustomerProject',1


   exec spMFExportFiles 'MFOtherDocument','C:\\MFSQLExport\\',null,null,null,1,1,1 --With out L1,L2,L3
   exec spMFExportFiles 'MFOtherDocument','C:\\MFSQLExport\\','Customer',null,null,1,1,0 --with Out L3
  exec spMFExportFiles 'MFSalesInvoice','C:\\MFSQLExport\\','Customer',null,null,1,1,1 --with Out L2,L3

    exec spMFExportFiles 'MFSalesInvoice','C:\\MFSQLExport\\','Name_Or_Title','Customer','Created_by',1,1,1 --with Out L2,L3

   