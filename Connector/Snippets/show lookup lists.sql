




--workflows to create

Select distinct COLUMN_NAME,mc.MFWorkflow_ID,mw.Name from INFORMATION_SCHEMA.COLUMNS c
inner join MFProperty mp
on mp.ColumnName = c.COLUMN_NAME
inner join MFClassProperty mcp
on  mcp.MFProperty_ID = mp.id
inner join mfclass mc
on mc.ID = mcp.MFClass_ID
inner join MFWorkflow mw
on mw.ID = mc.MFWorkflow_ID
where TABLE_NAME in ( 
Select TableName from MFClass where IncludeInApp is not null)
and mp.MFDataType_ID in (8,9)
and mp.MFID > 1000

--valuelists to create

Select distinct COLUMN_NAME,mvl.ID,mvl.Name from INFORMATION_SCHEMA.COLUMNS c
inner join MFProperty mp
on mp.ColumnName = c.COLUMN_NAME
inner join MFClassProperty mcp
on  mcp.MFProperty_ID = mp.id
inner join MFValueList mvl
on mvl.ID = mp.MFValueList_ID
where TABLE_NAME in ( 
Select TableName from MFClass where IncludeInApp is not null)
and mp.MFDataType_ID in (8,9)
and mp.MFID > 1000

