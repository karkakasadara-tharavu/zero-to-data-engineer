/*
 * Lab 47: Custom Errors and Advanced Messaging
 * Module 05: T-SQL Programming
 * 
 * Objective: Master custom error messages and advanced error patterns
 * Duration: 75 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 47: Custom Errors and Messaging';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: RAISERROR vs THROW
 */

PRINT 'PART 1: RAISERROR vs THROW Comparison';
PRINT '---------------------------------------';

-- RAISERROR syntax and features
PRINT 'RAISERROR Examples:';
PRINT '';

BEGIN TRY
    -- Basic RAISERROR
    RAISERROR('Basic error message', 16, 1);
END TRY
BEGIN CATCH
    PRINT '  Caught: ' + ERROR_MESSAGE();
    PRINT '  Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));  -- 50000 (default)
END CATCH;

PRINT '';

BEGIN TRY
    -- RAISERROR with parameters
    DECLARE @Username NVARCHAR(50) = 'JohnDoe';
    DECLARE @Balance DECIMAL(10,2) = 1500.75;
    
    RAISERROR('User %s has insufficient balance: $%.2f', 16, 1, @Username, @Balance);
END TRY
BEGIN CATCH
    PRINT '  Parameterized: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

BEGIN TRY
    -- RAISERROR with NOWAIT (immediate display)
    RAISERROR('Step 1 processing', 10, 1) WITH NOWAIT;
    WAITFOR DELAY '00:00:01';
    RAISERROR('Step 2 processing', 10, 1) WITH NOWAIT;
    WAITFOR DELAY '00:00:01';
    RAISERROR('Step 3 complete', 10, 1) WITH NOWAIT;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT 'THROW Examples:';
PRINT '';

BEGIN TRY
    -- Basic THROW (re-throws current error)
    -- THROW;  -- Must be in CATCH block
    
    -- THROW with error number
    THROW 50001, 'Custom error with THROW', 1;
END TRY
BEGIN CATCH
    PRINT '  Caught: ' + ERROR_MESSAGE();
    PRINT '  Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
END CATCH;

PRINT '';

-- THROW vs RAISERROR differences
BEGIN TRY
    BEGIN TRY
        RAISERROR('RAISERROR test', 16, 1);
    END TRY
    BEGIN CATCH
        PRINT 'Inner CATCH - RAISERROR:';
        PRINT '  Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));  -- Shows RAISERROR line
        THROW;  -- Re-throw to outer
    END CATCH;
END TRY
BEGIN CATCH
    PRINT 'Outer CATCH - RAISERROR:';
    PRINT '  Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));  -- Shows THROW line
END CATCH;

PRINT '';
PRINT 'COMPARISON SUMMARY:';
PRINT '';
PRINT 'RAISERROR:';
PRINT '  - Legacy (SQL Server 2000+)';
PRINT '  - Supports parameter substitution (%s, %d, %.2f)';
PRINT '  - WITH NOWAIT for immediate messages';
PRINT '  - WITH LOG to write to error log';
PRINT '  - Severity 0-18 (19-25 requires sysadmin)';
PRINT '  - Does NOT abort batch by default';
PRINT '';
PRINT 'THROW:';
PRINT '  - Modern (SQL Server 2012+)';
PRINT '  - No parameter substitution (format first)';
PRINT '  - ALWAYS severity 16';
PRINT '  - Always aborts batch';
PRINT '  - Preserves stack trace when re-throwing';
PRINT '  - Simpler syntax';
PRINT '';
PRINT 'RECOMMENDATION: Use THROW for new code';
PRINT '';

/*
 * PART 2: CUSTOM ERROR MESSAGES WITH sp_addmessage
 */

PRINT 'PART 2: Custom Error Messages';
PRINT '-------------------------------';

-- Add custom messages
EXEC sp_addmessage 
    @msgnum = 50100, 
    @severity = 16,
    @msgtext = 'Customer %s has exceeded credit limit by $%s',
    @lang = 'us_english',
    @replace = 'replace';

EXEC sp_addmessage 
    @msgnum = 50101, 
    @severity = 16,
    @msgtext = 'Invalid book ISBN: %s. Format must be XXX-X-XX-XXXXXX-X',
    @lang = 'us_english',
    @replace = 'replace';

EXEC sp_addmessage 
    @msgnum = 50102, 
    @severity = 11,
    @msgtext = 'Order %d is pending approval. Estimated processing time: %d hours',
    @lang = 'us_english',
    @replace = 'replace';

PRINT '✓ Added custom messages 50100-50102';
PRINT '';

-- Use custom messages
BEGIN TRY
    RAISERROR(50100, 16, 1, 'John Smith', '250.00');
END TRY
BEGIN CATCH
    PRINT 'Custom error caught: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

-- View all custom messages
SELECT 
    message_id,
    severity,
    text
FROM sys.messages
WHERE message_id >= 50000
AND language_id = 1033
ORDER BY message_id;

PRINT '';

/*
 * PART 3: PARAMETERIZED ERROR MESSAGES
 */

PRINT 'PART 3: Parameterized Messages';
PRINT '--------------------------------';

IF OBJECT_ID('usp_ValidateBookPrice', 'P') IS NOT NULL DROP PROCEDURE usp_ValidateBookPrice;
GO

CREATE PROCEDURE usp_ValidateBookPrice
    @BookID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentPrice DECIMAL(10,2);
    DECLARE @Title NVARCHAR(255);
    
    SELECT @CurrentPrice = Price, @Title = Title
    FROM Books
    WHERE BookID = @BookID;
    
    IF @BookID IS NULL
    BEGIN
        DECLARE @ErrorMsg NVARCHAR(255) = 
            FORMATMESSAGE('Book ID %d does not exist', @BookID);
        THROW 50001, @ErrorMsg, 1;
    END;
    
    -- Check price increase limit (max 50%)
    IF @NewPrice > @CurrentPrice * 1.5
    BEGIN
        DECLARE @PercentIncrease DECIMAL(5,2) = 
            ((@NewPrice - @CurrentPrice) / @CurrentPrice) * 100;
        
        DECLARE @Msg NVARCHAR(500) = 
            FORMATMESSAGE(
                'Price increase of %.2f%% for "%s" exceeds 50%% limit. Current: $%.2f, Proposed: $%.2f',
                @PercentIncrease, @Title, @CurrentPrice, @NewPrice
            );
        
        THROW 50002, @Msg, 1;
    END;
    
    PRINT 'Price validation passed';
END;
GO

BEGIN TRY
    EXEC usp_ValidateBookPrice @BookID = 1, @NewPrice = 999.99;
END TRY
BEGIN CATCH
    PRINT 'Validation failed: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

/*
 * PART 4: ERROR MESSAGE FORMATTING
 */

PRINT 'PART 4: Message Formatting Techniques';
PRINT '---------------------------------------';

IF OBJECT_ID('usp_FormatErrorMessages', 'P') IS NOT NULL DROP PROCEDURE usp_FormatErrorMessages;
GO

CREATE PROCEDURE usp_FormatErrorMessages
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Formatting Techniques:';
    PRINT '';
    
    -- 1. String concatenation
    DECLARE @Name NVARCHAR(50) = 'Test User';
    DECLARE @Count INT = 5;
    DECLARE @Msg1 NVARCHAR(200) = 'User ' + @Name + ' has ' + CAST(@Count AS NVARCHAR(10)) + ' orders';
    PRINT '1. Concatenation: ' + @Msg1;
    PRINT '';
    
    -- 2. FORMATMESSAGE (recommended)
    DECLARE @Msg2 NVARCHAR(200) = FORMATMESSAGE('User %s has %d orders', @Name, @Count);
    PRINT '2. FORMATMESSAGE: ' + @Msg2;
    PRINT '';
    
    -- 3. CONCAT function
    DECLARE @Msg3 NVARCHAR(200) = CONCAT('User ', @Name, ' has ', @Count, ' orders');
    PRINT '3. CONCAT: ' + @Msg3;
    PRINT '';
    
    -- 4. STRING_AGG for lists
    DECLARE @Issues TABLE (Issue NVARCHAR(50));
    INSERT INTO @Issues VALUES ('Missing ISBN'), ('Negative price'), ('Invalid year');
    
    DECLARE @IssueList NVARCHAR(500);
    SELECT @IssueList = STRING_AGG(Issue, ', ') FROM @Issues;
    DECLARE @Msg4 NVARCHAR(500) = 'Validation failed: ' + @IssueList;
    PRINT '4. STRING_AGG: ' + @Msg4;
    PRINT '';
    
    -- 5. JSON formatting for complex data
    DECLARE @Details NVARCHAR(MAX) = (
        SELECT 
            'John Doe' AS UserName,
            5 AS OrderCount,
            1500.50 AS TotalSpent
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    PRINT '5. JSON formatting: ' + @Details;
    PRINT '';
END;
GO

EXEC usp_FormatErrorMessages;
PRINT '';

/*
 * PART 5: MULTILINGUAL ERROR MESSAGES
 */

PRINT 'PART 5: Multilingual Support';
PRINT '------------------------------';
PRINT '';

-- Add Spanish message
EXEC sp_addmessage 
    @msgnum = 50103,
    @severity = 16,
    @msgtext = 'Insufficient inventory',
    @lang = 'us_english',
    @replace = 'replace';

-- Check if Spanish language installed (typically not in default install)
IF EXISTS (SELECT * FROM sys.syslanguages WHERE name = 'Español')
BEGIN
    EXEC sp_addmessage 
        @msgnum = 50103,
        @severity = 16,
        @msgtext = 'Inventario insuficiente',
        @lang = 'Español';
    
    PRINT '✓ Added Spanish translation';
END
ELSE
BEGIN
    PRINT 'Spanish language not installed - skipping translation';
END;

PRINT '';
PRINT 'Multilingual message usage:';
PRINT '  - Add same message_id for each language';
PRINT '  - SQL Server selects based on session language';
PRINT '  - SET LANGUAGE affects message selection';
PRINT '  - Falls back to English if translation missing';
PRINT '';

-- View message in all languages
SELECT 
    m.message_id,
    l.name AS LanguageName,
    m.text AS MessageText
FROM sys.messages m
INNER JOIN sys.syslanguages l ON m.language_id = l.msglangid
WHERE m.message_id = 50103
ORDER BY l.name;

PRINT '';

/*
 * PART 6: CONTEXTUAL ERROR INFORMATION
 */

PRINT 'PART 6: Error Context Enrichment';
PRINT '----------------------------------';

IF OBJECT_ID('usp_RichErrorContext', 'P') IS NOT NULL DROP PROCEDURE usp_RichErrorContext;
GO

CREATE PROCEDURE usp_RichErrorContext
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CustomerName NVARCHAR(200);
    DECLARE @OrderDate DATETIME2;
    DECLARE @OrderTotal DECIMAL(10,2);
    
    BEGIN TRY
        -- Get order details
        SELECT 
            @CustomerName = c.FirstName + ' ' + c.LastName,
            @OrderDate = o.OrderDate,
            @OrderTotal = o.TotalAmount
        FROM Orders o
        INNER JOIN Customers c ON o.CustomerID = c.CustomerID
        WHERE o.OrderID = @OrderID;
        
        IF @OrderID IS NULL
        BEGIN
            -- Rich error with context
            DECLARE @ContextError NVARCHAR(1000) = 
                FORMATMESSAGE(
                    'Order not found. Order ID: %d, User: %s, Time: %s',
                    @OrderID,
                    SUSER_SNAME(),
                    CONVERT(NVARCHAR(30), SYSDATETIME(), 121)
                );
            
            THROW 50003, @ContextError, 1;
        END;
        
        -- Intentional error for demo
        IF @OrderTotal > 10000
        BEGIN
            DECLARE @RichMsg NVARCHAR(1000) = 
                FORMATMESSAGE(
                    'High-value order requires manager approval. Customer: %s, Amount: $%.2f, Order Date: %s',
                    @CustomerName,
                    @OrderTotal,
                    CONVERT(NVARCHAR(30), @OrderDate, 120)
                );
            
            THROW 50004, @RichMsg, 1;
        END;
        
    END TRY
    BEGIN CATCH
        -- Add execution context
        DECLARE @EnhancedError NVARCHAR(MAX) = ERROR_MESSAGE() +
            ' | Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A') +
            ' | Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) +
            ' | User: ' + SUSER_SNAME() +
            ' | Database: ' + DB_NAME() +
            ' | SPID: ' + CAST(@@SPID AS NVARCHAR(10));
        
        PRINT 'Enhanced Error:';
        PRINT @EnhancedError;
        
        -- Log to error table
        INSERT INTO EnterpriseErrorLog (
            ErrorNumber, ErrorSeverity, ErrorState,
            ErrorProcedure, ErrorLine, ErrorMessage,
            AdditionalInfo
        )
        VALUES (
            ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
            ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE(),
            @EnhancedError
        );
        
        ;THROW;
    END CATCH;
END;
GO

BEGIN TRY
    EXEC usp_RichErrorContext @OrderID = 999999;
END TRY
BEGIN CATCH
    PRINT 'Caller received: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

/*
 * PART 7: ERROR CATEGORIZATION
 */

PRINT 'PART 7: Error Categories';
PRINT '-------------------------';

-- Create error categories table
IF OBJECT_ID('ErrorCategories', 'U') IS NOT NULL DROP TABLE ErrorCategories;
CREATE TABLE ErrorCategories (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(50),
    Description NVARCHAR(200),
    IsTransient BIT,  -- Can retry?
    RequiresAlert BIT,  -- Notify DBA?
    SeverityLevel INT
);

INSERT INTO ErrorCategories VALUES
(1, 'Validation', 'User input validation errors', 0, 0, 16),
(2, 'Authorization', 'Permission denied errors', 0, 1, 16),
(3, 'Resource', 'Database resource constraints', 1, 1, 17),
(4, 'Deadlock', 'Transaction deadlocks', 1, 0, 13),
(5, 'Data Integrity', 'Constraint violations', 0, 0, 16),
(6, 'System', 'System-level failures', 0, 1, 20);

PRINT '✓ Created ErrorCategories';

-- Categorization function
IF OBJECT_ID('fn_CategorizeError', 'FN') IS NOT NULL DROP FUNCTION fn_CategorizeError;
GO

CREATE FUNCTION fn_CategorizeError(@ErrorNumber INT)
RETURNS TABLE
AS
RETURN (
    SELECT 
        CategoryID,
        CategoryName,
        IsTransient,
        RequiresAlert
    FROM ErrorCategories
    WHERE CategoryID = CASE 
        WHEN @ErrorNumber IN (515, 547, 2601, 2627) THEN 5  -- Data Integrity
        WHEN @ErrorNumber = 1205 THEN 4  -- Deadlock
        WHEN @ErrorNumber IN (229, 230) THEN 2  -- Authorization
        WHEN @ErrorNumber IN (1204, 1222) THEN 3  -- Resource
        WHEN @ErrorNumber >= 50000 THEN 1  -- Validation (custom)
        ELSE 6  -- System
    END
);
GO

-- Usage example
SELECT 
    1205 AS ErrorNumber,
    c.*
FROM fn_CategorizeError(1205) c;

PRINT '';

/*
 * PART 8: USER-FRIENDLY ERROR MESSAGES
 */

PRINT 'PART 8: User-Friendly Messages';
PRINT '--------------------------------';

IF OBJECT_ID('usp_TranslateErrorToUserFriendly', 'P') IS NOT NULL DROP PROCEDURE usp_TranslateErrorToUserFriendly;
GO

CREATE PROCEDURE usp_TranslateErrorToUserFriendly
    @TechnicalError NVARCHAR(4000),
    @UserMessage NVARCHAR(1000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Translate technical errors to user-friendly messages
    SET @UserMessage = CASE 
        WHEN @TechnicalError LIKE '%NULL%' 
            THEN 'Please fill in all required fields.'
        
        WHEN @TechnicalError LIKE '%FOREIGN KEY%' OR @TechnicalError LIKE '%REFERENCE%'
            THEN 'This record is related to other data and cannot be deleted. Please remove dependencies first.'
        
        WHEN @TechnicalError LIKE '%duplicate key%' OR @TechnicalError LIKE '%UNIQUE%'
            THEN 'This information already exists in the system. Please use a different value.'
        
        WHEN @TechnicalError LIKE '%deadlock%'
            THEN 'The system is busy. Please try again in a moment.'
        
        WHEN @TechnicalError LIKE '%timeout%'
            THEN 'The operation is taking longer than expected. Please try again later.'
        
        WHEN @TechnicalError LIKE '%permission%' OR @TechnicalError LIKE '%denied%'
            THEN 'You do not have permission to perform this action. Please contact your administrator.'
        
        ELSE 
            'An unexpected error occurred. Please contact support with error code: ' + 
            CAST(ERROR_NUMBER() AS NVARCHAR(10))
    END;
END;
GO

PRINT '✓ Created usp_TranslateErrorToUserFriendly';

-- Demo
BEGIN TRY
    -- Simulate foreign key violation
    DELETE FROM Customers WHERE CustomerID = 1;  -- Assuming FK exists
END TRY
BEGIN CATCH
    DECLARE @UserMsg NVARCHAR(1000);
    EXEC usp_TranslateErrorToUserFriendly 
        @TechnicalError = ERROR_MESSAGE(),
        @UserMessage = @UserMsg OUTPUT;
    
    PRINT 'Technical: ' + ERROR_MESSAGE();
    PRINT 'User-friendly: ' + @UserMsg;
END CATCH;

PRINT '';

/*
 * PART 9: ERROR MESSAGE TEMPLATES
 */

PRINT 'PART 9: Reusable Error Templates';
PRINT '----------------------------------';

-- Error template table
IF OBJECT_ID('ErrorTemplates', 'U') IS NOT NULL DROP TABLE ErrorTemplates;
CREATE TABLE ErrorTemplates (
    TemplateID INT PRIMARY KEY,
    TemplateName NVARCHAR(100),
    MessageTemplate NVARCHAR(1000),
    Severity INT,
    CategoryID INT FOREIGN KEY REFERENCES ErrorCategories(CategoryID)
);

INSERT INTO ErrorTemplates VALUES
(1, 'INVALID_INPUT', 'Invalid {0}: {1}. Expected format: {2}', 16, 1),
(2, 'NOT_FOUND', '{0} with ID {1} was not found', 16, 1),
(3, 'LIMIT_EXCEEDED', '{0} limit of {1} exceeded. Current value: {2}', 16, 1),
(4, 'UNAUTHORIZED', 'User {0} is not authorized to {1} on {2}', 16, 2),
(5, 'DUPLICATE', '{0} already exists: {1}', 16, 5);

PRINT '✓ Created ErrorTemplates';

-- Template usage function
IF OBJECT_ID('fn_FormatErrorTemplate', 'FN') IS NOT NULL DROP FUNCTION fn_FormatErrorTemplate;
GO

CREATE FUNCTION fn_FormatErrorTemplate(
    @TemplateID INT,
    @Param0 NVARCHAR(100) = NULL,
    @Param1 NVARCHAR(100) = NULL,
    @Param2 NVARCHAR(100) = NULL
)
RETURNS NVARCHAR(1000)
AS
BEGIN
    DECLARE @Template NVARCHAR(1000);
    DECLARE @Message NVARCHAR(1000);
    
    SELECT @Template = MessageTemplate
    FROM ErrorTemplates
    WHERE TemplateID = @TemplateID;
    
    SET @Message = @Template;
    SET @Message = REPLACE(@Message, '{0}', ISNULL(@Param0, ''));
    SET @Message = REPLACE(@Message, '{1}', ISNULL(@Param1, ''));
    SET @Message = REPLACE(@Message, '{2}', ISNULL(@Param2, ''));
    
    RETURN @Message;
END;
GO

-- Example usage
DECLARE @Error NVARCHAR(1000);

SET @Error = dbo.fn_FormatErrorTemplate(1, 'ISBN', '123-456', 'XXX-X-XX-XXXXXX-X');
PRINT 'Template 1: ' + @Error;

SET @Error = dbo.fn_FormatErrorTemplate(2, 'Customer', '999');
PRINT 'Template 2: ' + @Error;

SET @Error = dbo.fn_FormatErrorTemplate(3, 'Order', '100', '150');
PRINT 'Template 3: ' + @Error;

PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Error Messaging Best Practices';
PRINT '-----------------------------------------';
PRINT '';
PRINT 'MESSAGE DESIGN:';
PRINT '  ✓ Be specific and actionable';
PRINT '  ✓ Include relevant context';
PRINT '  ✓ Avoid technical jargon for users';
PRINT '  ✓ Provide error codes for support';
PRINT '  ✓ Suggest remediation steps';
PRINT '';
PRINT 'THROW vs RAISERROR:';
PRINT '  THROW:';
PRINT '    - Modern, simpler syntax';
PRINT '    - Always severity 16';
PRINT '    - Preserves stack trace';
PRINT '    - Use for new development';
PRINT '';
PRINT '  RAISERROR:';
PRINT '    - Legacy support';
PRINT '    - Parameter substitution';
PRINT '    - WITH NOWAIT for progress';
PRINT '    - WITH LOG for critical errors';
PRINT '';
PRINT 'CUSTOM MESSAGES:';
PRINT '  - Use sp_addmessage for reusable errors';
PRINT '  - Number custom errors 50001-2147483647';
PRINT '  - Support multiple languages';
PRINT '  - Document all custom errors';
PRINT '';
PRINT 'ERROR CONTEXT:';
PRINT '  - Include: What, Where, When, Who';
PRINT '  - Add business context (customer, order, etc.)';
PRINT '  - Separate technical vs user messages';
PRINT '  - Log full details, show summary to users';
PRINT '';
PRINT 'FORMATTING:';
PRINT '  - Use FORMATMESSAGE for parameters';
PRINT '  - Consider JSON for complex data';
PRINT '  - Keep messages concise but informative';
PRINT '  - Use templates for consistency';
PRINT '';

-- View all custom errors
SELECT 
    et.TemplateName,
    et.MessageTemplate,
    ec.CategoryName,
    ec.IsTransient,
    ec.RequiresAlert
FROM ErrorTemplates et
INNER JOIN ErrorCategories ec ON et.CategoryID = ec.CategoryID
ORDER BY et.TemplateID;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create 10 custom error messages for common scenarios
 * 2. Build error translation function (technical → user-friendly)
 * 3. Implement error template system with parameter replacement
 * 4. Create multilingual error messages (English + 1 other language)
 * 5. Build error categorization and routing system
 * 
 * CHALLENGE:
 * Create enterprise error messaging framework:
 * - ErrorMessages table (ID, language, technical, user-friendly)
 * - ErrorTemplates with placeholders
 * - fn_GetUserMessage(@ErrorNumber, @Language) function
 * - usp_RaiseStandardizedError procedure
 * - Error localization support (5+ languages)
 * - Context enrichment (user, session, environment)
 * - Automatic error code generation
 * - Integration with logging system
 * - Error message versioning
 * - A/B testing for user messages (track which are clearer)
 */

PRINT '✓ Lab 47 Complete: Custom error messaging mastered';
PRINT '';
PRINT 'Error Handling section complete!';
PRINT 'Next: Transactions and Isolation Levels (Labs 48-49)';
GO
