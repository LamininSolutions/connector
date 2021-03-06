
--EXEC dbo.spMFDeploymentDetails 

SET NOCOUNT OFF;
RETURN 0;
END TRY
BEGIN CATCH
	DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
	DECLARE @ErrorNumber INT
	DECLARE @ErrorLine INT
	DECLARE @ErrorProcedure NVARCHAR(128)
	DECLARE @OptionalMessage VARCHAR(max)

	SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
		@ErrorNumber = ERROR_NUMBER(),
		@ErrorLine = ERROR_LINE(),
		@ErrorProcedure=ERROR_PROCEDURE()

	IF @@TRANCOUNT <> 0
	BEGIN
		ROLLBACK TRAN;
	END	
	
	SET NOCOUNT OFF;

    RAISERROR ( @ErrorMessage, -- Message text.
				@ErrorSeverity, -- Severity.
				@ErrorState -- State.
               );
	

	RETURN -1

END CATCH

GO


