select * from MFClass

select * from MFProperty where MFID=40

alter table Mfotherdocument add Moved_Into_Current_State bit

alter table MFPicture add Moved_Into_Current_State bit

select * from MFPicture

exec spMFUpdateTable 'MFOtherDocument',1
select * From MFOtherDocument

Update MFOtherDocument set Process_ID=1 where ObjID=74

exec spMFGetHistory 'MFOtherDocument',1,'Name or title,Keywords','',1,0,'',-1,0
--select * from MFObjectChangeHistory
--truncate table MFObjectChangeHistory
--With FUllUpdate
exec spMFGetHistory 'MFOtherDocument',1,'Name or title,Keywords','',1,-1,'',-1,0
--With Number of day
exec spMFGetHistory 'MFOtherDocument',1,'Name or title,Keywords','',0,9,'',-1,0

--With Start Date
exec spMFGetHistory 'MFOtherDocument',1,'Name or title,Keywords','',0,-1,'201-08-24',-1,0

exec spMFGetHistory 'MFPicture',0,'Name or title,Comment','',1,-1,'',-1,0
