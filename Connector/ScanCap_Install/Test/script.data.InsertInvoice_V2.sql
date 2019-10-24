
INSERT INTO [dbo].[Ancora_Invoices]
           ([migration]
           ,[file_path]
           ,[FileName]
           ,[ftf_name]
           ,[LinkID]
           ,[VENDOR NAME]
           ,[VENDOR CODE]
           ,[INVOICE DATE]
           ,[INVOICE NO]
           ,[PO NUMBER]
           ,[SUBTOTAL]
           ,[TAX]
           ,[SHIPPING AND HANDLING]
           ,[OTHER AMOUNT]
           ,[DEPOSIT]
           ,[TOTAL AMOUNT]
           ,[Image Path]
           ,[DESCRIPTION]
           ,[QTY]
           ,[UNIT PRICE]
           ,[LINE TOTAL])
    
	SELECT 
           AIB.migration ,
           AIB.file_path ,
           AIB.FileName ,
           AIB.ftf_name ,
           AIB.LinkID ,
           AIB.[VENDOR NAME] ,
           AIB.[VENDOR CODE] ,
           AIB.[INVOICE DATE] ,
           AIB.[INVOICE NO] ,
           AIB.[PO NUMBER] ,
           AIB.SUBTOTAL ,
           AIB.TAX ,
           AIB.[SHIPPING AND HANDLING] ,
           AIB.[OTHER AMOUNT] ,
           AIB.DEPOSIT ,
           AIB.[TOTAL AMOUNT] ,
           AIB.[Image Path] ,
           AIB.DESCRIPTION ,
           AIB.QTY ,
           AIB.[UNIT PRICE] ,
           AIB.[LINE TOTAL]
		    FROM scancap.ancora_invoices_back AS AIB WHERE filename = '4041882010-04-27'
GO


