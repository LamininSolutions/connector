




DECLARE @Rowid UNIQUEIDENTIFIER 
Declare @fileid int 
DECLARE @Document AS VARBINARY(MAX)
 Declare @Location nvarchar(255)
DECLARE @SQL nvarchar(max)

SELECT @rowid = MIN(SiteContentID) FROM SiteContent

/*
INSERT INTO SiteContent
([FileName],[ContentType],[Length])
SELECT [i].[FileName],'images\jpeg',[i].[Length]
FROM [dbo].[Images] AS [i]
*/

 While @rowid is not null
 Begin
-- Load the image data

SELECT @Location ='C:\Temp\Images\' + [f].[FileName] FROM [dbo].[SiteContent] AS [f]
WHERE f.[SiteContentID] = @Rowid
/*
Select @Location = _FullName_ from dbo.files f
inner join scu.FileData fd
on f.id = fd.fileID
where f.id = fd.fileid and fd.id = @Rowid;
*/
Set @SQL = N'
SELECT @Document = CAST(bulkcolumn AS VARBINARY(MAX))
      FROM OPENROWSET(
            BULK ''' + @Location + ''' ,
            SINGLE_BLOB ) AS Doc'

			Exec sp_ExecuteSQL @SQL,N'@Document VARBINARY(MAX) output', @Document output


update sc
set Data = @Document
FROM siteContent sc
where Sitecontentid = @rowid


Select @Rowid = (Select min(SiteContentID) from [dbo].[Sitecontent] where Sitecontentid > @rowid)

END


