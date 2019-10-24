--select top 1 * from dbo1.Account order by 1 desc


SELECT  FROM dbo.files

--Go
DECLARE @Document AS VARBINARY(MAX)
 
-- Load the image data
SELECT @Document = CAST(bulkcolumn AS VARBINARY(MAX))
      FROM OPENROWSET(
            BULK
            'C:\Shared\Files\CV -  Samuel Lewis.docx',
            SINGLE_BLOB ) AS Doc
            
-- Insert the data to the table           
INSERT INTO dbo1.Account (AccountName,[File], [FileName], CreatedBy,IsConnect,GUID,LoanName)
SELECT '000',@Document,'A guide to using the Vault Application Framework Licensing(1).pdf',getdate(),0,'74738B15-EC36-FC25-7532-842106CD3ECB', '000'

update dbo1.account set createdby='00' where id=1001