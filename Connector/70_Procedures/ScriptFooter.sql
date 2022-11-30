

      SET @DebugText = N' ';
        SET @DebugText = @DefaultDebugText + @DebugText;
        SET @ProcedureStep = N'Finalise update assemblies  ';

         IF @Debug > 0
        BEGIN
            RAISERROR(@DebugText, 10, 1, @ProcedureName, @ProcedureStep);
        END;


EXEC dbo.spMFDeploymentDetails @Type = 0

SET NOCOUNT OFF;
RETURN 0;
END TRY
BEGIN CATCH

EXEC dbo.spMFDeploymentDetails @Type = -1

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


