
/*

*/
--Created on: 2019-09-22

DECLARE @TextDate NVARCHAR(40),@character CHAR
SET @TextDate = '1/13/2009'
--SET @TextDate = '21/09/2019 08:41:20 p. m.'
--SET @TextDate = '21/09/2019 08:41:20.768 AM'
--SET @TextDate = '21/09/2019 14:41:20.200'

SELECT dbo.[fnMFTextToDate](@TextDate,'/')
