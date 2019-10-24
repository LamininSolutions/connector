
/*
<?xml version="1.0" encoding="UTF-8"?>
<document>
    <name>The name of the document</name>
    <keywords>Keywords in an XML file</keywords>
</document>

select * from mfotherdocument
how to deal with multi lookups

*/

/*
powershell for getting data for table and creating xml files



#Variables
$ServerInstance = "LSUK-SQL03\UKDEV03"
$Database_Table = "MFSQL_Release_46.custom.FileImportXML"
$SQLQuery = "SELECT FileName, XMLData from " + $Database_Table + " ;"
$DestinationPath = "E:\Temp"
$filedata

$FileList = Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $ServerInstance

Foreach($File in $Filelist)
{
$FileName = $File.FileName + ".xml"
$FilePath = join-Path $DestinationPath -childpath $FileName
$filePath 

if (Test-Path $FilePath ) {
   Clear-Content -force $FilePath
	}else
{new-item -path $FilePath -ItemType File
}
set-content -Path $FilePath -Value $File.XMLData

}

*/

--CREATE TABLE custom.FileImportXML (id INT IDENTITY, Filename NVARCHAR(256), XMLData NVARCHAR(MAX))

TRUNCATE TABLE custom.FileImportXML

DECLARE @XMLFiles NVARCHAR(MAX)
DECLARE @ID INT = 1
DECLARE @XMLDeclaration NVARCHAR(100) = '<?xml version="1.0" encoding="UTF-8"?>'
DECLARE @Filename NVARCHAR(265)
DECLARE @Objid INT
DECLARE @ClassID INT
DECLARE @FileCount int
DECLARE @NameOrTitle NVARCHAR(256)
WHILE @ID IS NOT NULL
BEGIN

SELECT @Objid = objid , @ClassID = Class_ID, @fileCount = Filecount 
,@NameOrTitle = [mod].[Name_Or_Title]
FROM [dbo].[MFOtherDocument] AS [mod] WHERE id = @id
SELECT @Filename = @NameOrTitle

SELECT @XMLFiles =  (
SELECT [mod].[Name_Or_Title] AS [NameorTitle], [mod].[Keywords] AS Keywords, [mod].[Customer_ID] AS Customer 
FROM [dbo].[MFOtherDocument] AS [mod] 
WHERE ID = @ID
FOR XML PATH (''), ROOT ('document'))

INSERT INTO custom.FileImportXML

SELECT @Filename AS Filename, @XMLDeclaration + @XMLFiles AS FileData

 
SELECT @ID = (SELECT MIN(id) FROM MFOtherdocument WHERE id > @ID AND [FileCount]>0)
END

SELECT * FROM custom.fileImportXML
