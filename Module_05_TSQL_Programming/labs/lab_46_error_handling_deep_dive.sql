/*
 * Lab 46: Error Handling Deep Dive
 * Module 05: T-SQL Programming
 * 
 * Objective: Master comprehensive error handling patterns
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 46: Error Handling Deep Dive';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: ERROR SEVERITY LEVELS
 */

PRINT 'PART 1: Error Severity Levels';
PRINT '-------------------------------';
PRINT '';
PRINT 'SQL Server Error Severity (0-25):';
PRINT '';
PRINT '  0-10: Informational messages';
PRINT '    - No errors, just information';
PRINT '    - Returned as messages, not errors';
PRINT '';
PRINT '  11-16: User-correctable errors';
PRINT '    11: Informational warning';
PRINT '    12-13: Deadlock or transaction error';
PRINT '    14: Security or permission error';
PRINT '    15: Syntax error in T-SQL';
PRINT '    16: General error (most custom errors)';
PRINT '';
PRINT '  17-19: Software errors';
PRINT '    17: Insufficient resources';
PRINT '    18: Internal software problem';
PRINT '    19: Database engine limit exceeded';
PRINT '';
PRINT '  20-25: System/Fatal errors';
PRINT '    20: Statement problem (current statement aborted)';
PRINT '    21: Database problem';
PRINT '    22: Table integrity suspect';
PRINT '    23: Database integrity suspect';
PRINT '    24: Hardware/media failure';
PRINT '    25: System error (connection terminated)';
PRINT '';

-- Demonstrate different severities
RAISERROR('Severity 10: Informational', 10, 1) WITH NOWAIT;
RAISERROR('Severity 11: Warning', 11, 1) WITH NOWAIT;

BEGIN TRY
    RAISERROR('Severity 16: User error', 16, 1);
END TRY
BEGIN CATCH
    PRINT 'Caught severity 16: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

/*
 * PART 2: SYSTEM ERROR MESSAGES
 */

PRINT 'PART 2: System Error Messages';
PRINT '-------------------------------';

-- Query system error messages
SELECT TOP 10
    message_id,
    severity,
    text AS ErrorMessage
FROM sys.messages
WHERE language_id = 1033  -- English
AND severity >= 16
ORDER BY message_id;

PRINT '';
PRINT 'Common system errors:';
PRINT '  515: NULL insert violation';
PRINT '  547: Foreign key constraint violation';
PRINT '  1205: Deadlock victim';
PRINT '  2601: Duplicate key violation';
PRINT '  2627: Unique constraint violation';
PRINT '  8152: String truncation';
PRINT '';

-- Demonstrate common errors
BEGIN TRY
    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES (NULL, '123', 10, 2024);  -- NULL violation
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS Severity,
        ERROR_STATE() AS State,
        ERROR_MESSAGE() AS Message;
END CATCH;

PRINT '';

/*
 * PART 3: COMPREHENSIVE ERROR FUNCTION USAGE
 */

PRINT 'PART 3: Error Functions Deep Dive';
PRINT '-----------------------------------';

IF OBJECT_ID('usp_DetailedErrorInfo', 'P') IS NOT NULL DROP PROCEDURE usp_DetailedErrorInfo;
GO

CREATE PROCEDURE usp_DetailedErrorInfo
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Intentional error: divide by zero
        DECLARE @Result INT = 10 / 0;
    END TRY
    BEGIN CATCH
        -- Comprehensive error information
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS Severity,
            ERROR_STATE() AS State,
            ERROR_PROCEDURE() AS Procedure,
            ERROR_LINE() AS LineNumber,
            ERROR_MESSAGE() AS Message,
            XACT_STATE() AS TransactionState,
            @@TRANCOUNT AS TransactionNestLevel;
        
        -- Detailed explanation
        PRINT '';
        PRINT 'ERROR DETAILS:';
        PRINT '  Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT '  Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(10));
        PRINT '  State: ' + CAST(ERROR_STATE() AS NVARCHAR(10));
        PRINT '  Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        PRINT '  Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        PRINT '  Message: ' + ERROR_MESSAGE();
        PRINT '';
        PRINT 'TRANSACTION STATE:';
        PRINT '  XACT_STATE(): ' + CAST(XACT_STATE() AS NVARCHAR(10));
        PRINT '    1 = committable';
        PRINT '    0 = no transaction';
        PRINT '   -1 = uncommittable (must rollback)';
    END CATCH;
END;
GO

EXEC usp_DetailedErrorInfo;
PRINT '';

/*
 * PART 4: NESTED TRY/CATCH BLOCKS
 */

PRINT 'PART 4: Nested Error Handling';
PRINT '-------------------------------';

IF OBJECT_ID('usp_NestedErrorHandling', 'P') IS NOT NULL DROP PROCEDURE usp_NestedErrorHandling;
GO

CREATE PROCEDURE usp_NestedErrorHandling
    @DivideBy INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Outer TRY block
    BEGIN TRY
        PRINT 'Outer TRY: Starting operation';
        
        -- Inner TRY block for specific operation
        BEGIN TRY
            PRINT '  Inner TRY: Performing calculation';
            DECLARE @Result INT = 100 / @DivideBy;
            PRINT '  Inner TRY: Result = ' + CAST(@Result AS NVARCHAR(10));
        END TRY
        BEGIN CATCH
            PRINT '  Inner CATCH: Calculation failed';
            PRINT '  Error: ' + ERROR_MESSAGE();
            
            -- Log error but continue
            INSERT INTO ErrorLog (ErrorProcedure, ErrorNumber, ErrorMessage)
            VALUES ('usp_NestedErrorHandling', ERROR_NUMBER(), ERROR_MESSAGE());
            
            -- Re-throw to outer handler
            ;THROW;
        END CATCH;
        
        PRINT 'Outer TRY: Operation completed successfully';
        
    END TRY
    BEGIN CATCH
        PRINT 'Outer CATCH: Handling error at procedure level';
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        
        -- Return error code
        RETURN -1;
    END CATCH;
    
    RETURN 0;
END;
GO

EXEC usp_NestedErrorHandling @DivideBy = 0;
PRINT '';

/*
 * PART 5: TRANSACTION ERROR HANDLING PATTERNS
 */

PRINT 'PART 5: Transaction Error Patterns';
PRINT '------------------------------------';

IF OBJECT_ID('usp_TransactionWithXACT_STATE', 'P') IS NOT NULL DROP PROCEDURE usp_TransactionWithXACT_STATE;
GO

CREATE PROCEDURE usp_TransactionWithXACT_STATE
    @CustomerID INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;  -- Allow error handling
    
    DECLARE @ErrorOccurred BIT = 0;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Operation 1
        INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
        VALUES (@CustomerID, GETDATE(), @Amount, 'Pending');
        
        -- Operation 2 (intentional error scenario)
        IF @Amount < 0
            RAISERROR('Negative amount not allowed', 16, 1);
        
        -- Operation 3
        UPDATE Customers
        SET TotalOrderValue = TotalOrderValue + @Amount
        WHERE CustomerID = @CustomerID;
        
        -- Check transaction state before commit
        IF XACT_STATE() = 1
        BEGIN
            COMMIT TRANSACTION;
            PRINT 'Transaction committed successfully';
        END;
        
    END TRY
    BEGIN CATCH
        -- Check if transaction is active
        IF XACT_STATE() <> 0
        BEGIN
            IF XACT_STATE() = 1
            BEGIN
                -- Transaction is committable (rare in CATCH)
                COMMIT TRANSACTION;
                PRINT 'Transaction committed in CATCH block';
            END
            ELSE IF XACT_STATE() = -1
            BEGIN
                -- Transaction is doomed, must rollback
                ROLLBACK TRANSACTION;
                PRINT 'Transaction rolled back due to error';
            END;
        END;
        
        -- Log error
        PRINT 'Error: ' + ERROR_MESSAGE();
        
        -- Re-throw
        ;THROW;
    END CATCH;
END;
GO

BEGIN TRY
    EXEC usp_TransactionWithXACT_STATE @CustomerID = 1, @Amount = -100;
END TRY
BEGIN CATCH
    PRINT 'Caught in caller: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

/*
 * PART 6: ERROR HANDLING WITH SAVEPOINTS
 */

PRINT 'PART 6: Savepoints for Partial Rollback';
PRINT '-----------------------------------------';

IF OBJECT_ID('usp_BatchWithSavepoints', 'P') IS NOT NULL DROP PROCEDURE usp_BatchWithSavepoints;
GO

CREATE PROCEDURE usp_BatchWithSavepoints
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SuccessCount INT = 0;
    DECLARE @FailureCount INT = 0;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Batch 1
        SAVE TRANSACTION Batch1;
        BEGIN TRY
            INSERT INTO Books (Title, ISBN, Price, PublicationYear)
            VALUES ('Batch 1 Book', '111-1-11-111111-1', 25.00, 2024);
            
            SET @SuccessCount = @SuccessCount + 1;
            PRINT '✓ Batch 1 succeeded';
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION Batch1;
            SET @FailureCount = @FailureCount + 1;
            PRINT '✗ Batch 1 failed: ' + ERROR_MESSAGE();
        END CATCH;
        
        -- Batch 2
        SAVE TRANSACTION Batch2;
        BEGIN TRY
            INSERT INTO Books (Title, ISBN, Price, PublicationYear)
            VALUES (NULL, '222-2-22-222222-2', 30.00, 2024);  -- NULL violation
            
            SET @SuccessCount = @SuccessCount + 1;
            PRINT '✓ Batch 2 succeeded';
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION Batch2;
            SET @FailureCount = @FailureCount + 1;
            PRINT '✗ Batch 2 failed: ' + ERROR_MESSAGE();
        END CATCH;
        
        -- Batch 3
        SAVE TRANSACTION Batch3;
        BEGIN TRY
            INSERT INTO Books (Title, ISBN, Price, PublicationYear)
            VALUES ('Batch 3 Book', '333-3-33-333333-3', 35.00, 2024);
            
            SET @SuccessCount = @SuccessCount + 1;
            PRINT '✓ Batch 3 succeeded';
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION Batch3;
            SET @FailureCount = @FailureCount + 1;
            PRINT '✗ Batch 3 failed: ' + ERROR_MESSAGE();
        END CATCH;
        
        -- Commit successful batches
        COMMIT TRANSACTION;
        
        PRINT '';
        PRINT 'SUMMARY:';
        PRINT '  Successful: ' + CAST(@SuccessCount AS NVARCHAR(10));
        PRINT '  Failed: ' + CAST(@FailureCount AS NVARCHAR(10));
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Fatal error: ' + ERROR_MESSAGE();
        ;THROW;
    END CATCH;
END;
GO

EXEC usp_BatchWithSavepoints;
PRINT '';

/*
 * PART 7: DEADLOCK HANDLING
 */

PRINT 'PART 7: Deadlock Detection and Retry';
PRINT '--------------------------------------';

IF OBJECT_ID('usp_DeadlockRetry', 'P') IS NOT NULL DROP PROCEDURE usp_DeadlockRetry;
GO

CREATE PROCEDURE usp_DeadlockRetry
    @BookID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Retries INT = 0;
    DECLARE @MaxRetries INT = 3;
    DECLARE @WaitTime INT = 1000; -- milliseconds
    DECLARE @Success BIT = 0;
    
    WHILE @Retries < @MaxRetries AND @Success = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Update that might deadlock
            UPDATE Books WITH (ROWLOCK)
            SET Price = @NewPrice
            WHERE BookID = @BookID;
            
            COMMIT TRANSACTION;
            
            SET @Success = 1;
            PRINT '✓ Update successful on attempt ' + CAST(@Retries + 1 AS NVARCHAR(10));
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Check if deadlock (error 1205)
            IF ERROR_NUMBER() = 1205
            BEGIN
                SET @Retries = @Retries + 1;
                
                IF @Retries < @MaxRetries
                BEGIN
                    PRINT '⚠️  Deadlock detected. Retry ' + CAST(@Retries AS NVARCHAR(10)) + 
                          ' of ' + CAST(@MaxRetries AS NVARCHAR(10));
                    
                    -- Exponential backoff
                    WAITFOR DELAY CONVERT(VARCHAR(12), DATEADD(ms, @WaitTime * @Retries, 0), 114);
                END
                ELSE
                BEGIN
                    PRINT '✗ Max retries exceeded. Giving up.';
                    ;THROW;
                END;
            END
            ELSE
            BEGIN
                -- Not a deadlock - re-throw immediately
                PRINT '✗ Non-deadlock error: ' + ERROR_MESSAGE();
                ;THROW;
            END;
        END CATCH;
    END;
    
    RETURN CASE WHEN @Success = 1 THEN 0 ELSE -1 END;
END;
GO

EXEC usp_DeadlockRetry @BookID = 1, @NewPrice = 29.99;
PRINT '';

/*
 * PART 8: ENTERPRISE ERROR LOGGING
 */

PRINT 'PART 8: Enterprise Error Logging';
PRINT '----------------------------------';

-- Enhanced error log table
IF OBJECT_ID('EnterpriseErrorLog', 'U') IS NOT NULL DROP TABLE EnterpriseErrorLog;
CREATE TABLE EnterpriseErrorLog (
    ErrorLogID INT IDENTITY(1,1) PRIMARY KEY,
    ErrorTime DATETIME2 DEFAULT SYSDATETIME(),
    UserName NVARCHAR(128) DEFAULT SUSER_SNAME(),
    ErrorNumber INT,
    ErrorSeverity INT,
    ErrorState INT,
    ErrorProcedure NVARCHAR(128),
    ErrorLine INT,
    ErrorMessage NVARCHAR(4000),
    TransactionID UNIQUEIDENTIFIER,
    SessionID INT DEFAULT @@SPID,
    HostName NVARCHAR(128) DEFAULT HOST_NAME(),
    ApplicationName NVARCHAR(128) DEFAULT APP_NAME(),
    DatabaseName NVARCHAR(128) DEFAULT DB_NAME(),
    AdditionalInfo NVARCHAR(MAX) NULL
);

PRINT '✓ Created EnterpriseErrorLog table';

IF OBJECT_ID('usp_LogError', 'P') IS NOT NULL DROP PROCEDURE usp_LogError;
GO

CREATE PROCEDURE usp_LogError
    @AdditionalInfo NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO EnterpriseErrorLog (
        ErrorNumber,
        ErrorSeverity,
        ErrorState,
        ErrorProcedure,
        ErrorLine,
        ErrorMessage,
        TransactionID,
        AdditionalInfo
    )
    VALUES (
        ERROR_NUMBER(),
        ERROR_SEVERITY(),
        ERROR_STATE(),
        ERROR_PROCEDURE(),
        ERROR_LINE(),
        ERROR_MESSAGE(),
        CAST(@@TRANCOUNT AS UNIQUEIDENTIFIER),
        @AdditionalInfo
    );
    
    RETURN SCOPE_IDENTITY();
END;
GO

PRINT '✓ Created usp_LogError procedure';

-- Example usage
IF OBJECT_ID('usp_ProcessWithLogging', 'P') IS NOT NULL DROP PROCEDURE usp_ProcessWithLogging;
GO

CREATE PROCEDURE usp_ProcessWithLogging
    @InputValue INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Some operation
        IF @InputValue < 0
            RAISERROR('Input value must be non-negative', 16, 1);
        
        PRINT 'Processing completed successfully';
    END TRY
    BEGIN CATCH
        -- Log the error
        DECLARE @ErrorLogID INT;
        EXEC @ErrorLogID = usp_LogError @AdditionalInfo = 'Input value was negative';
        
        PRINT 'Error logged with ID: ' + CAST(@ErrorLogID AS NVARCHAR(10));
        
        -- Optionally re-throw
        ;THROW;
    END CATCH;
END;
GO

BEGIN TRY
    EXEC usp_ProcessWithLogging @InputValue = -5;
END TRY
BEGIN CATCH
    PRINT 'Caught in caller';
END CATCH;

SELECT TOP 5 * FROM EnterpriseErrorLog ORDER BY ErrorTime DESC;
PRINT '';

/*
 * PART 9: ERROR CONTEXT PRESERVATION
 */

PRINT 'PART 9: Preserving Error Context';
PRINT '----------------------------------';

IF OBJECT_ID('usp_ErrorContextPreservation', 'P') IS NOT NULL DROP PROCEDURE usp_ErrorContextPreservation;
GO

CREATE PROCEDURE usp_ErrorContextPreservation
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Nested procedure call
        EXEC usp_ProcessWithLogging @InputValue = -10;
    END TRY
    BEGIN CATCH
        -- Preserve original error context
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        
        -- Log with full context
        INSERT INTO EnterpriseErrorLog (
            ErrorNumber, ErrorSeverity, ErrorState,
            ErrorProcedure, ErrorLine, ErrorMessage,
            AdditionalInfo
        )
        VALUES (
            @ErrorNumber, @ErrorSeverity, @ErrorState,
            @ErrorProcedure, @ErrorLine, @ErrorMessage,
            'Called from: usp_ErrorContextPreservation'
        );
        
        -- Re-raise with original details
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

BEGIN TRY
    EXEC usp_ErrorContextPreservation;
END TRY
BEGIN CATCH
    PRINT 'Final handler - Error: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

/*
 * PART 10: BEST PRACTICES SUMMARY
 */

PRINT 'PART 10: Error Handling Best Practices';
PRINT '----------------------------------------';
PRINT '';
PRINT 'ALWAYS:';
PRINT '  ✓ Use TRY/CATCH for all procedures';
PRINT '  ✓ Check XACT_STATE() before rollback';
PRINT '  ✓ Log errors to permanent table';
PRINT '  ✓ Include context in error messages';
PRINT '  ✓ Use appropriate severity levels';
PRINT '  ✓ Return status codes from procedures';
PRINT '  ✓ Document expected errors';
PRINT '';
PRINT 'NEVER:';
PRINT '  ✗ Ignore errors silently';
PRINT '  ✗ Use empty CATCH blocks';
PRINT '  ✗ Commit after errors';
PRINT '  ✗ Lose original error context';
PRINT '  ✗ Return data from CATCH blocks';
PRINT '';
PRINT 'PATTERNS:';
PRINT '  - Deadlock retry with exponential backoff';
PRINT '  - Savepoints for partial rollback';
PRINT '  - Nested TRY/CATCH for granular handling';
PRINT '  - Centralized error logging procedure';
PRINT '  - THROW to preserve stack trace';
PRINT '';
PRINT 'TRANSACTION HANDLING:';
PRINT '  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;';
PRINT '  IF XACT_STATE() = -1 ROLLBACK TRANSACTION;';
PRINT '  IF XACT_STATE() = 1 COMMIT TRANSACTION;';
PRINT '';
PRINT 'TESTING:';
PRINT '  - Test all error paths';
PRINT '  - Verify transaction cleanup';
PRINT '  - Check error log entries';
PRINT '  - Simulate deadlocks';
PRINT '  - Test nested scenarios';
PRINT '';

-- Error handling statistics
SELECT 
    'Enterprise Error Log Summary' AS Report,
    COUNT(*) AS TotalErrors,
    COUNT(DISTINCT ErrorProcedure) AS AffectedProcedures,
    COUNT(DISTINCT ErrorNumber) AS UniqueErrorTypes,
    MIN(ErrorTime) AS FirstError,
    MAX(ErrorTime) AS LastError
FROM EnterpriseErrorLog;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create procedure with retry logic for timeout errors (error -2)
 * 2. Implement circuit breaker pattern (stop retrying after N failures)
 * 3. Create error notification system (email DBA on critical errors)
 * 4. Build error analytics: most common errors, trends over time
 * 5. Create error recovery procedure that can restart failed operations
 * 
 * CHALLENGE:
 * Build enterprise error handling framework:
 * - ErrorLog table with retention policy (archive old errors)
 * - usp_LogError with automatic categorization (transient vs permanent)
 * - usp_NotifyOnError with severity-based routing
 * - Error dashboard views (errors by procedure, by time, by user)
 * - Automated retry mechanism for known transient errors
 * - Error correlation (group related errors together)
 * - Performance impact monitoring
 * - Self-healing capabilities (automatic remediation)
 */

PRINT '✓ Lab 46 Complete: Error handling mastery achieved';
GO
