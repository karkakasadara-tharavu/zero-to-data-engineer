/*
 * Lab 38: Stored Procedures - Error Handling
 * Module 05: T-SQL Programming
 * 
 * Objective: Master TRY/CATCH, transactions, and error handling in procedures
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 38: Error Handling in Stored Procedures';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: BASIC TRY/CATCH
 */

PRINT 'PART 1: Basic TRY/CATCH Block';
PRINT '-------------------------------';

IF OBJECT_ID('usp_SafeDivide', 'P') IS NOT NULL DROP PROCEDURE usp_SafeDivide;
GO

CREATE PROCEDURE usp_SafeDivide
    @Numerator DECIMAL(10,2),
    @Denominator DECIMAL(10,2),
    @Result DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Attempt division
        SET @Result = @Numerator / @Denominator;
        PRINT 'Division successful: ' + CAST(@Result AS NVARCHAR(20));
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Handle error
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
        SET @Result = NULL;
        RETURN -1;
    END CATCH;
END;
GO

PRINT '✓ Created usp_SafeDivide';

-- Test successful case
DECLARE @Res DECIMAL(10,2), @RetCode INT;
EXEC @RetCode = usp_SafeDivide @Numerator = 100, @Denominator = 5, @Result = @Res OUTPUT;
PRINT 'Result: ' + ISNULL(CAST(@Res AS NVARCHAR(20)), 'NULL') + ', Return Code: ' + CAST(@RetCode AS NVARCHAR(10));

-- Test divide by zero
EXEC @RetCode = usp_SafeDivide @Numerator = 100, @Denominator = 0, @Result = @Res OUTPUT;
PRINT 'Result: ' + ISNULL(CAST(@Res AS NVARCHAR(20)), 'NULL') + ', Return Code: ' + CAST(@RetCode AS NVARCHAR(10));
PRINT '';

/*
 * PART 2: ERROR FUNCTIONS
 */

PRINT 'PART 2: Error Information Functions';
PRINT '-------------------------------------';

IF OBJECT_ID('usp_ErrorDemo', 'P') IS NOT NULL DROP PROCEDURE usp_ErrorDemo;
GO

CREATE PROCEDURE usp_ErrorDemo
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Force a constraint violation
        INSERT INTO Books (BookID, Title, ISBN, Price, PublicationYear)
        VALUES (1, 'Duplicate ID', '123', 10.00, 2024);  -- Duplicate primary key
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE() AS ErrorLine,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

PRINT '✓ Created usp_ErrorDemo';
EXEC usp_ErrorDemo;
PRINT '';

/*
 * PART 3: TRANSACTIONS WITH ERROR HANDLING
 */

PRINT 'PART 3: Transactions with Error Handling';
PRINT '------------------------------------------';

IF OBJECT_ID('usp_TransferFunds', 'P') IS NOT NULL DROP PROCEDURE usp_TransferFunds;
GO

-- Create account table for demo
IF OBJECT_ID('Account', 'U') IS NOT NULL DROP TABLE Account;
CREATE TABLE Account (
    AccountID INT PRIMARY KEY,
    AccountHolder NVARCHAR(100),
    Balance DECIMAL(10,2) CHECK (Balance >= 0)
);

INSERT INTO Account VALUES 
    (1, 'Alice', 1000.00),
    (2, 'Bob', 500.00);

CREATE PROCEDURE usp_TransferFunds
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMsg NVARCHAR(4000);
    
    -- Start transaction
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validate parameters
        IF @Amount <= 0
        BEGIN
            SET @ErrorMsg = 'Transfer amount must be positive';
            THROW 50001, @ErrorMsg, 1;
        END;
        
        IF @FromAccount = @ToAccount
        BEGIN
            SET @ErrorMsg = 'Cannot transfer to same account';
            THROW 50002, @ErrorMsg, 1;
        END;
        
        -- Check sufficient balance
        IF NOT EXISTS (SELECT 1 FROM Account WHERE AccountID = @FromAccount AND Balance >= @Amount)
        BEGIN
            SET @ErrorMsg = 'Insufficient funds in source account';
            THROW 50003, @ErrorMsg, 1;
        END;
        
        -- Debit source account
        UPDATE Account
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromAccount;
        
        -- Credit destination account
        UPDATE Account
        SET Balance = Balance + @Amount
        WHERE AccountID = @ToAccount;
        
        -- Commit if all successful
        COMMIT TRANSACTION;
        PRINT 'Transfer completed successfully';
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Rollback on error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Transfer failed: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;
GO

PRINT '✓ Created usp_TransferFunds with transaction';

-- Test successful transfer
PRINT 'Before transfer:';
SELECT * FROM Account;

EXEC usp_TransferFunds @FromAccount = 1, @ToAccount = 2, @Amount = 100.00;

PRINT 'After transfer:';
SELECT * FROM Account;

-- Test insufficient funds
EXEC usp_TransferFunds @FromAccount = 2, @ToAccount = 1, @Amount = 10000.00;

PRINT 'After failed transfer (should be rolled back):';
SELECT * FROM Account;
PRINT '';

/*
 * PART 4: NESTED TRY/CATCH
 */

PRINT 'PART 4: Nested TRY/CATCH Blocks';
PRINT '---------------------------------';

IF OBJECT_ID('usp_ProcessOrderWithLogging', 'P') IS NOT NULL DROP PROCEDURE usp_ProcessOrderWithLogging;
GO

-- Create error log table
IF OBJECT_ID('ErrorLog', 'U') IS NOT NULL DROP TABLE ErrorLog;
CREATE TABLE ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    ErrorDate DATETIME2 DEFAULT SYSDATETIME(),
    ErrorProcedure NVARCHAR(128),
    ErrorNumber INT,
    ErrorMessage NVARCHAR(4000)
);

CREATE PROCEDURE usp_ProcessOrderWithLogging
    @OrderID INT,
    @NewStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Main operation
        BEGIN TRANSACTION;
        
        UPDATE Orders
        SET Status = @NewStatus
        WHERE OrderID = @OrderID;
        
        IF @@ROWCOUNT = 0
            THROW 50004, 'Order not found', 1;
        
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error (nested TRY/CATCH for logging)
        BEGIN TRY
            INSERT INTO ErrorLog (ErrorProcedure, ErrorNumber, ErrorMessage)
            VALUES (ERROR_PROCEDURE(), ERROR_NUMBER(), ERROR_MESSAGE());
        END TRY
        BEGIN CATCH
            -- If logging fails, just print
            PRINT 'Failed to log error: ' + ERROR_MESSAGE();
        END CATCH;
        
        -- Re-throw original error
        THROW;
    END CATCH;
END;
GO

PRINT '✓ Created usp_ProcessOrderWithLogging';

-- Test with invalid order ID
BEGIN TRY
    EXEC usp_ProcessOrderWithLogging @OrderID = 99999, @NewStatus = 'Shipped';
END TRY
BEGIN CATCH
    PRINT 'Caught error: ' + ERROR_MESSAGE();
END CATCH;

-- Check error log
SELECT * FROM ErrorLog;
PRINT '';

/*
 * PART 5: RAISERROR vs THROW
 */

PRINT 'PART 5: RAISERROR vs THROW';
PRINT '----------------------------';

IF OBJECT_ID('usp_ValidateBook', 'P') IS NOT NULL DROP PROCEDURE usp_ValidateBook;
GO

CREATE PROCEDURE usp_ValidateBook
    @Title NVARCHAR(255),
    @Price DECIMAL(10,2),
    @ISBN NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Using RAISERROR (older method)
    IF @Title IS NULL OR LEN(@Title) = 0
    BEGIN
        RAISERROR('Title cannot be empty', 16, 1);
        RETURN -1;
    END;
    
    -- Using THROW (modern method, preferred)
    IF @Price <= 0
        THROW 50005, 'Price must be positive', 1;
    
    IF LEN(@ISBN) <> 13 AND LEN(@ISBN) <> 10
        THROW 50006, 'ISBN must be 10 or 13 characters', 1;
    
    PRINT 'Validation passed';
    RETURN 0;
END;
GO

PRINT '✓ Created usp_ValidateBook';

-- Test validation errors
BEGIN TRY
    EXEC usp_ValidateBook @Title = '', @Price = 25.00, @ISBN = '1234567890';
END TRY
BEGIN CATCH
    PRINT 'RAISERROR caught: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC usp_ValidateBook @Title = 'Valid Title', @Price = -10.00, @ISBN = '1234567890';
END TRY
BEGIN CATCH
    PRINT 'THROW caught: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

/*
 * PART 6: TRANSACTION SAVEPOINTS
 */

PRINT 'PART 6: Transaction Savepoints';
PRINT '--------------------------------';

IF OBJECT_ID('usp_BatchInsertBooks', 'P') IS NOT NULL DROP PROCEDURE usp_BatchInsertBooks;
GO

CREATE PROCEDURE usp_BatchInsertBooks
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SavePointName NVARCHAR(50);
    DECLARE @BooksAdded INT = 0;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- First batch
        SET @SavePointName = 'Batch1';
        SAVE TRANSACTION Batch1;
        
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('Book A', '1111111111', 19.99, 2024);
        SET @BooksAdded = @BooksAdded + 1;
        
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('Book B', '2222222222', 29.99, 2024);
        SET @BooksAdded = @BooksAdded + 1;
        
        -- Second batch (will fail due to duplicate ISBN)
        SET @SavePointName = 'Batch2';
        SAVE TRANSACTION Batch2;
        
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('Book C', '3333333333', 39.99, 2024);
        SET @BooksAdded = @BooksAdded + 1;
        
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('Book D', '3333333333', 49.99, 2024);  -- Duplicate ISBN!
        SET @BooksAdded = @BooksAdded + 1;
        
        COMMIT TRANSACTION;
        PRINT 'All books added: ' + CAST(@BooksAdded AS NVARCHAR(10));
        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Rollback to savepoint
        IF @SavePointName = 'Batch2' AND @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION Batch2;
            PRINT 'Batch 2 failed, rolled back to savepoint';
            PRINT 'Batch 1 preserved';
            COMMIT TRANSACTION;  -- Commit Batch 1
            RETURN 1;  -- Partial success
        END
        ELSE IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Complete rollback: ' + ERROR_MESSAGE();
            RETURN -1;
        END;
    END CATCH;
END;
GO

PRINT '✓ Created usp_BatchInsertBooks with savepoints';
EXEC usp_BatchInsertBooks;
PRINT '';

/*
 * PART 7: CUSTOM ERROR MESSAGES
 */

PRINT 'PART 7: Custom Error Messages';
PRINT '-------------------------------';

-- Add custom error messages
IF EXISTS (SELECT * FROM sys.messages WHERE message_id = 50100 AND language_id = 1033)
    EXEC sp_dropmessage 50100, 'us_english';

EXEC sp_addmessage 
    @msgnum = 50100,
    @severity = 16,
    @msgtext = 'Customer %s has exceeded credit limit by $%.2f',
    @lang = 'us_english';

PRINT '✓ Added custom error message 50100';

IF OBJECT_ID('usp_CheckCreditLimit', 'P') IS NOT NULL DROP PROCEDURE usp_CheckCreditLimit;
GO

CREATE PROCEDURE usp_CheckCreditLimit
    @CustomerName NVARCHAR(100),
    @PurchaseAmount DECIMAL(10,2),
    @CreditLimit DECIMAL(10,2),
    @CurrentBalance DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ExcessAmount DECIMAL(10,2);
    
    IF (@CurrentBalance + @PurchaseAmount) > @CreditLimit
    BEGIN
        SET @ExcessAmount = (@CurrentBalance + @PurchaseAmount) - @CreditLimit;
        RAISERROR(50100, 16, 1, @CustomerName, @ExcessAmount);
        RETURN -1;
    END;
    
    PRINT 'Credit check passed';
    RETURN 0;
END;
GO

PRINT '✓ Created usp_CheckCreditLimit';

-- Test custom error
BEGIN TRY
    EXEC usp_CheckCreditLimit 
        @CustomerName = 'John Doe',
        @PurchaseAmount = 500.00,
        @CreditLimit = 1000.00,
        @CurrentBalance = 800.00;
END TRY
BEGIN CATCH
    PRINT 'Custom error: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

/*
 * PART 8: ERROR HANDLING PATTERNS
 */

PRINT 'PART 8: Enterprise Error Handling Pattern';
PRINT '-------------------------------------------';

IF OBJECT_ID('usp_LogError', 'P') IS NOT NULL DROP PROCEDURE usp_LogError;
GO

CREATE PROCEDURE usp_LogError
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ErrorLog (ErrorProcedure, ErrorNumber, ErrorMessage)
    VALUES (
        ISNULL(ERROR_PROCEDURE(), 'Ad-hoc query'),
        ERROR_NUMBER(),
        ERROR_MESSAGE()
    );
    
    RETURN @@IDENTITY;
END;
GO

PRINT '✓ Created usp_LogError utility procedure';

IF OBJECT_ID('usp_ComplexOperation', 'P') IS NOT NULL DROP PROCEDURE usp_ComplexOperation;
GO

CREATE PROCEDURE usp_ComplexOperation
    @CustomerID INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorLogID INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Multiple operations...
        UPDATE Customers SET TotalPurchases = TotalPurchases + @Amount WHERE CustomerID = @CustomerID;
        
        IF @@ROWCOUNT = 0
            THROW 50007, 'Customer not found', 1;
        
        -- More operations...
        
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        EXEC @ErrorLogID = usp_LogError;
        
        -- Return detailed error info
        SELECT 
            @ErrorLogID AS ErrorLogID,
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE() AS ErrorLine;
        
        RETURN -1;
    END CATCH;
END;
GO

PRINT '✓ Created usp_ComplexOperation with enterprise pattern';
PRINT '';

/*
 * PART 9: DEADLOCK RETRY LOGIC
 */

PRINT 'PART 9: Deadlock Retry Pattern';
PRINT '--------------------------------';

IF OBJECT_ID('usp_UpdateWithRetry', 'P') IS NOT NULL DROP PROCEDURE usp_UpdateWithRetry;
GO

CREATE PROCEDURE usp_UpdateWithRetry
    @OrderID INT,
    @NewStatus NVARCHAR(20),
    @MaxRetries INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Attempts INT = 0;
    DECLARE @Success BIT = 0;
    
    WHILE @Attempts < @MaxRetries AND @Success = 0
    BEGIN
        SET @Attempts = @Attempts + 1;
        
        BEGIN TRY
            BEGIN TRANSACTION;
            
            UPDATE Orders
            SET Status = @NewStatus
            WHERE OrderID = @OrderID;
            
            COMMIT TRANSACTION;
            SET @Success = 1;
            PRINT 'Update succeeded on attempt ' + CAST(@Attempts AS NVARCHAR(10));
            RETURN 0;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Check if deadlock (error 1205)
            IF ERROR_NUMBER() = 1205
            BEGIN
                PRINT 'Deadlock detected, attempt ' + CAST(@Attempts AS NVARCHAR(10));
                
                IF @Attempts < @MaxRetries
                BEGIN
                    -- Wait before retry (exponential backoff)
                    WAITFOR DELAY '00:00:01';
                END
                ELSE
                BEGIN
                    PRINT 'Max retries reached';
                    THROW;
                END;
            END
            ELSE
            BEGIN
                -- Non-deadlock error, don't retry
                THROW;
            END;
        END CATCH;
    END;
    
    RETURN -1;
END;
GO

PRINT '✓ Created usp_UpdateWithRetry';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Error Handling Best Practices';
PRINT '----------------------------------------';
PRINT '';
PRINT 'TRY/CATCH:';
PRINT '  - Always use TRY/CATCH for error handling';
PRINT '  - CATCH block must handle all errors';
PRINT '  - Never leave CATCH block empty';
PRINT '';
PRINT 'TRANSACTIONS:';
PRINT '  - Check @@TRANCOUNT before ROLLBACK';
PRINT '  - Always COMMIT or ROLLBACK';
PRINT '  - Use XACT_ABORT ON for automatic rollback';
PRINT '  - Keep transactions short';
PRINT '';
PRINT 'ERROR INFORMATION:';
PRINT '  - Use ERROR_NUMBER(), ERROR_MESSAGE()';
PRINT '  - Log errors for troubleshooting';
PRINT '  - Include procedure name and line number';
PRINT '';
PRINT 'THROW vs RAISERROR:';
PRINT '  - Prefer THROW (simpler, modern)';
PRINT '  - THROW preserves original error';
PRINT '  - RAISERROR needed for custom messages with parameters';
PRINT '';
PRINT 'RETURN CODES:';
PRINT '  - 0 = success';
PRINT '  - Negative = error codes';
PRINT '  - Document error codes';
PRINT '';

PRINT '✓ Lab 38 Complete: Error handling mastered';
GO
