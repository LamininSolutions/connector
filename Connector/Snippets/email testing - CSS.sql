DECLARE @EMAIL_BODY NVARCHAR(max)
DECLARE @EMAIL_PROFILE VARCHAR(255);

EXEC [dbo].[spMFValidateEmailProfile] @emailProfile = @EMAIL_PROFILE OUTPUT -- varchar(100)
																	   
--<body style="min-height:1000px;font-family:Arial, Helvetica, sans-serif; font-size:12px">
			SET @EMAIL_BODY = N'<html>
			<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
				<style type="text/css">

						table {
  							   border-collapse: collapse;
  							   border: 1px solid #3399FF;
  							   font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
  							   color: black;
							   cellpadding:5;
							   cellspacing=1;
							   border=1;
							}
						table caption {   font-weight: bold;
						}
						table td, table th, table caption { border: 1px solid #eaeaea; }

 						 table td {
      							   vertical-align: top;
      							   background: #fdf5f2;
					  			 }
 						table th {
      						padding: 8pt 2pt 5pt 2pt;
      						color: white;
      						font-weight: normal;
      						vertical-align: top;
      						background: #562507;
					}
					table td:first-of-type {font-weight: bold;font-variant: small-caps;}
					table tr:first-of-type {font-weight: bold;font-variant: small-caps;}
					table tr:nth-child(even) td:nth-child(odd){ background: #ffedd9; }
					table tr:nth-child(even) td:nth-child(even){ background: #fcf5ef; }
					table tr:nth-child(odd) td:nth-child(odd){ background: #ffe0bd; }
					table tr:nth-child(odd) td:nth-child(even){ background: #f9e4d4; }
					table th:nth-child(even){ background: #703009; }

				}
				</style>
			</head>
			<div>			';
					--Get Process Headers
					SET @EMAIL_BODY = '<div>
				<table>
					<tr>
						<td>Server Name:</td>
						<td>' + @@SERVERNAME + '</td>
					</tr>
					<tr>
						<td>Database:</td>
						<td>' + DB_NAME() + '</td>
					</tr>
					</table> 
					 </div>

					 </div>
					 
			 </body>
			 </html>';

						EXEC [msdb].[dbo].[sp_send_dbmail] @profile_name = @EMAIL_PROFILE
														 , @recipients = 'leroux@lamininsolutions.com' --, @copy_recipients = @EMAIL_CC_ADDR
														 , @subject = 'Test Email2'
														 , @body = @EMAIL_BODY
														 , @body_format = 'HTML'





SELECT td=F.Employee,'', td=F.Phone,'',td= F.Email
    FROM
      (
      VALUES
        ('Mr. Gustavo Achong',
          '398-555-0132',
			'gustavo0@adventure-works.com'
        ),
        ('Ms. Catherine R.Abel',
          '747-555-0171',
			'catherine0@adventure-works.com'
        )
      ) F(Employee, Phone,Email)
  FOR XML PATH('tr'),  TYPE;

SELECT ISNULL(CAST((SELECT td=F.[Name],'', td=F.[Value]
    FROM
      (
      VALUES
        ('Server Name:',
          @@SERVERNAME
        ),
        ('Database Name',
          DB_NAME()
        )
      ) F([Name], [Value])
  FOR XML PATH('tr'),  TYPE) AS nvarchar(MAX)),'');

SELECT * FROM [dbo].[MFLog]
DECLARE @msg NVARCHAR(MAX)
SELECT @msg = [Message]
FROM [dbo].[MFUserMessages]
WHERE [ProcessBatch_ID] = 100

SELECT @msg = '<tr>'+REPLACE(@msg,'\n','</tr><tr>') + '</tr>'
SELECT @msg


			<table>
 				  <caption>AdventureWorks Customers</caption>
				<tr><th>Employee Name</th><th>Phone</th><th>Email</th></tr>
				<tr><td>Mr. Gustavo Achong</td><td>398-555-0132</td><td>gustavo0@adventure-works.com</td></tr>
				<tr><td>Ms. Catherine R.Abel</td><td>747-555-0171</td><td>catherine0@adventure-works.com</td></tr>
				<tr><td>Ms. Kim Abercrombie</td><td>334-555-0137</td><td>kim2@adventure-works.com</td></tr>
				<tr><td>Sr. Humberto Acevedo</td><td>599-555-0127</td><td>humberto0@adventure-works.com</td></tr>
    				 <!-- and so on .....  -->
				</table>
				'
				+ '<p>&nbsp;</p>'


CREATE TABLE #Stats
			(
				[ClassID] INT
			  , [Tablename] VARCHAR(100)
			  , [IncludeInApp] INT
			  , [SQLRecordCount] INT
			  , [MFRecordCount] INT
			  , [MFNotInSQL] INT
			  , [Deleted] INT
			  , [SyncError] INT
			  , [Process_ID_1] INT
			  , [MFError] INT
			  , [SQLError] INT
			  , [LastModified] SMALLDATETIME
			  , [MFLastModified] SMALLDATETIME
			  , [sessionID] INT
			  , [Flag] INT
			);

		INSERT INTO #Stats
		EXEC [dbo].[spMFClassTableStats] @ClassTableName = 'CLARInvoiceDoc'

SELECT * FROM [#Stats]

SELECT 
    [Tablename]
,   [SQLRecordCount]
,   [SyncError]
,   [MFError]
,   [SQLError]
FROM [#Stats]
UNPIVOT 
(
  --[DataValue] FOR [DataType]
  IN ([Tablename],[SQLRecordCount],[SyncError],[MFError],[SQLError])
)
AS Alias 
