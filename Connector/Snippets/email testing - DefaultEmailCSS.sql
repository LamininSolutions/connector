SET NOCOUNT ON
DECLARE @EMAIL_BODY NVARCHAR(max)
DECLARE @EMAIL_PROFILE VARCHAR(255);

EXEC [dbo].[spMFValidateEmailProfile] @emailProfile = @EMAIL_PROFILE OUTPUT -- varchar(100)
																	   
--<body style="min-height:1000px;font-family:Arial, Helvetica, sans-serif; font-size:12px">
			DECLARE @msg NVARCHAR(MAX)
			SELECT @msg = [Message]
			FROM [dbo].[MFUserMessages]
			WHERE [ProcessBatch_ID] = 100

			SET @msg = '<tr>'+REPLACE(@msg,'\n','</tr><tr>') + '</tr>'

			SET @EMAIL_BODY = N'<html>'

			SELECT @EMAIL_BODY = @EMAIL_BODY + CAST(value AS VARCHAR(8000))
			FROM [dbo].[MFSettings] 
			WHERE source_key = 'Email'
			AND  [Name] = 'DefaultEMailCSS'
			
			DECLARE @MFVaultSetting_VaultName NVARCHAR(100)
			SELECT @MFVaultSetting_VaultName = [VaultName]
			FROM [dbo].[MFVaultSettings]

			--SELECT [Mfsql_Process_Batch],COUNT(*)
			--FROM [dbo].[CLARInvoiceDoc]
			--GROUP BY [Mfsql_Process_Batch]

			EXEC [spMFResultMessageForUI]	

			DECLARE @MessageOUT NVARCHAR(4000)
			EXEC [dbo].[spMFResultMessageForUI] @ClassTable = 'CLARInvoiceDoc'
											  , @RowCount = 115
											  , @Processbatch_ID = 94
											  , @MessageOUT = @MessageOUT OUTPUT

			SET @MessageOUT = '<tr>'+REPLACE(@MessageOUT,'\n','</tr><tr>') + '</tr>'
			
			SET @EMAIL_BODY = @EMAIL_BODY + N'
			<body> <div id="body_style" >'
			+ '<table>' 			
			+ '<caption>MFSQL Connector message from [' + @MFVaultSetting_VaultName + '] Vault</caption>'
			+  @MessageOUT 
			+ '</table>'
			+ '</div></body></html>';

						EXEC [msdb].[dbo].[sp_send_dbmail] @profile_name = @EMAIL_PROFILE
														 , @recipients = 'arnie@lamininsolutions.com' --, @copy_recipients = @EMAIL_CC_ADDR
														 , @subject = 'Test Email2'
														 , @body = @EMAIL_BODY
														 , @body_format = 'HTML'



SET NOCOUNT OFF	
				
				
			--+ '<table>
			--	  <caption>Server Information</caption>'
			--	  + 
			--	  ISNULL(CAST((SELECT td=F.[Name],'', td=F.[Value]
   -- 				FROM
   --   				  (
   --   				  VALUES
   --     				('Server Name:',
   --       				  @@SERVERNAME
   --     				),
   --     				('Database Name:',
   --       				  DB_NAME()
   --     				)
   --   				  ) F([Name], [Value])
  	--			  FOR XML PATH('tr'),  TYPE) AS nvarchar(MAX)),'')
			--	+ '</table>'
			--	+ '<p>&nbsp;</p>'
			--	+ '<table>'
			--	+ '<caption>Process Message</caption>'
			--	+ @msg
			--	+ '</table>'