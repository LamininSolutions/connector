

CREATE TABLE [dbo].[FileImportBlob](
[tbId] [int] IDENTITY(1,1) NOT NULL,
[tbName] [varchar](50) NULL,
[tbDesc] [varchar](100) NULL,
[tbBin] [varbinary](max) NULL
) ON [PRIMARY]   


Insert FileImportBlob(tbName, tbDesc, tbBin) Select 
'81.pdf','PDF file', BulkColumn from Openrowset( Bulk 
'C:\blob\udoc\81.pdf', Single_Blob) as tb 

Insert FileImportBlob(tbName, tbDesc, tbBin) Select 'mountain.jpg','Image 
jpeg', BulkColumn from Openrowset( Bulk 'C:\blob\udoc\mountain.jpg', 
Single_Blob) as tb

Insert FileImportBlob(tbName, tbDesc, tbBin) Select 'Questionnaire.docx','Doc 
Question', BulkColumn from Openrowset( Bulk 
'C:\blob\udoc\Questionnaire.docx', Single_Blob) as tb

Insert FileImportBlob(tbName, tbDesc, tbBin) Select 'txpeng542.exe','Texpad 
Exe', BulkColumn from Openrowset( Bulk 'C:\blob\udoc\txpeng542.exe', 
Single_Blob) as tb