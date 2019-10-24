

DECLARE @Modules NVARCHAR(10)

SET @Modules = '1'

MERGE INTO dbo.MFSettings t
USING (SELECT @Modules AS [Value]) s
ON t.Name = 'Modules'
WHEN NOT MATCHED THEN
INSERT 
(Name,source_key,Description,Value,Enabled)
VALUES
('Modules','License','Licensed Modules',s.Value,1)
WHEN MATCHED THEN 
UPDATE SET
t.value = s.value
;

