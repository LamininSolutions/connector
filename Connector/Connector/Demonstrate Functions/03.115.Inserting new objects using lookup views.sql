/*
LESSON NOTES
These examples are illustrations on the use of the procedures.
All examples use the Sample Vault as a base
Consult the guide for more detail on the use of the procedures http:\\tinyurl.com\mfsqlconnector
*/

/*
INSERTING NEW RECORDS IN CLASS TABLE USING BATCH UPDATE
note that all the standard columns commented out is optional in the insert statement or is not required when inserting a new record

*/

INSERT INTO dbo.MFCustomer
        ( 
        --GUID , 
        --  MX_User_ID ,
          Address_Line_1 ,
          Address_Line_2 ,
          City ,
          --Class ,
          --Class_ID ,
          --Country ,
          Country_ID ,
          --Created ,
          --Created_by ,
          --Created_by_ID ,
          Customer_Name ,
          --MF_Last_Modified ,
          --MF_Last_Modified_By ,
          --MF_Last_Modified_By_ID ,
       --   Name_Or_Title ,
          --Single_File ,
          --State ,
          --State_ID ,
          Stateprovince ,
          Telephone_Number ,
          Web_Site ,
          --Workflow ,
          --Workflow_ID ,
          Zippostal_Code ,
          --LastModified ,
          Process_ID 
          --ObjID ,
          --ExternalID ,
          --MFVersion ,
          --Deleted ,
          --Update_ID
        )
        values
        ('Building'
        ,'Street Name'
        ,'London'
        ,(select MFID_ValuelistItems from MFvwCountry where name_ValueListItems = 'United Kingdom')
        ,'ABC Customer'
        ,'Hampshire'
        ,'090987098'
        ,'www.abccompany.com'
        ,'PO6 1HT'
        ,1
        )

-- UPDATE INSERTED RECORDS FROM SQL INTO M-FILES
exec spMFUpdateTable 'MFCustomer',0

--CHECK TABLE
select * from mfcustomer

--DELETE THE TEST RECORD
update MFCustomer
set Process_ID = 10
 where Customer_Name = 'ABC Customer'
 
 exec spMFDeleteObjectList @TableName = 'MFCustomer',@Process_ID = 10 , @DeleteWithDestroy = 0
 
