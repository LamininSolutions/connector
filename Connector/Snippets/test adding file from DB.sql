
/*

*/
--Created on: 2019-01-14 

DECLARE @Vaultsettings NVARCHAR(1000)
DECLARE @XML NVARCHAR(MAX)
DECLARE @Data varbinary(MAX) 
DECLARE @XMLStr NVARCHAR(MAX)
DECLARE @FileLocation NVARCHAR(100);
DECLARE @FileName NVARCHAR(100);
DECLARE @Result NVARCHAR(MAX)
DECLARE @ErrorMsg NVARCHAR(MAX)
DECLARE @IsFileDelete int

SET @FileName = 'CV - Tommy Hart.docx'
SET @FileLocation = 'C:\Share\Fileimport\2\'

SET @XMLStr = 
'<form><Object id="0" sqlID="1" objID="74" objVesrion="8" DisplayID="0"><class id="1"><property id="0" dataType="1">Floor Plan, Building #43, 1st Floor</property><property id="27" dataType="7">0</property><property id="22" dataType="8">0</property><property id="1078" dataType="10">25</property></class></Object></form>'

SET @Vaultsettings = [dbo].[FnMFVaultSettings]()

EXEC [dbo].[spMFSynchronizeFileToMFilesInternal] @VaultSettings = @Vaultsettings -- nvarchar(4000)
                                                ,@FileName = @FileName      -- nvarchar(max)
                                                ,@XMLFile = @XMLStr       -- nvarchar(max)
                                                ,@FilePath = @FileLocation      -- nvarchar(max)
                                                ,@Result = @Result OUTPUT                              -- nvarchar(max)
                                                ,@ErrorMsg = @ErrorMsg OUTPUT                          -- nvarchar(max)
                                                ,@IsFileDelete = 0  -- int



																	SELECT CAST(@Result AS XML)
																	SELECT @ErrorMsg

														