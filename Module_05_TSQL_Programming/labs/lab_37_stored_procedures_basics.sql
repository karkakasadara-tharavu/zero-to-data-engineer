/*
 * Lab 37: Stored Procedures - Basics
 * Module 05: T-SQL Programming
 * 
 * Objective: Master stored procedure fundamentals with parameters
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 37: Stored Procedures - Basics';
PRINT '==============================================';
PRINT '';

IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Error: BookstoreDB not found. Run Module 04 labs first.';
    RETURN;
END;
GO

USE BookstoreDB;
GO

/*
 * PART 1: CREATE SIMPLE STORED PROCEDURE
 */

PRINT 'PART 1: Simple Stored Procedures';
PRINT '----------------------------------';

-- Basic procedure with no parameters
IF OBJECT_ID('usp_GetAllBooks', 'P') IS NOT NULL DROP PROCEDURE usp_GetAllBooks;
GO

CREATE PROCEDURE usp_GetAllBooks
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        BookID,
        Title,
        ISBN,
        Price,
        PublicationYear
    FROM Books
    ORDER BY Title;
END;
GO

PRINT '✓ Created usp_GetAllBooks';

-- Execute the procedure
EXEC usp_GetAllBooks;
PRINT '';

/*
 * PART 2: INPUT PARAMETERS
 */

PRINT 'PART 2: Input Parameters';
PRINT '-------------------------';

-- Single input parameter
IF OBJECT_ID('usp_GetBookByID', 'P') IS NOT NULL DROP PROCEDURE usp_GetBookByID;
GO

CREATE PROCEDURE usp_GetBookByID
    @BookID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        BookID,
        Title,
        ISBN,
        Price,
        PublicationYear
    FROM Books
    WHERE BookID = @BookID;
END;
GO

PRINT '✓ Created usp_GetBookByID';

-- Test with parameter
EXEC usp_GetBookByID @BookID = 1;
PRINT '';

-- Multiple input parameters
IF OBJECT_ID('usp_GetBooksByPriceRange', 'P') IS NOT NULL DROP PROCEDURE usp_GetBooksByPriceRange;
GO

CREATE PROCEDURE usp_GetBooksByPriceRange
    @MinPrice DECIMAL(10,2),
    @MaxPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        BookID,
        Title,
        Price,
        PublicationYear
    FROM Books
    WHERE Price BETWEEN @MinPrice AND @MaxPrice
    ORDER BY Price;
    
    -- Return row count
    SELECT @@ROWCOUNT AS BooksFound;
END;
GO

PRINT '✓ Created usp_GetBooksByPriceRange';

-- Execute with multiple parameters
EXEC usp_GetBooksByPriceRange @MinPrice = 10.00, @MaxPrice = 20.00;
PRINT '';

/*
 * PART 3: DEFAULT PARAMETER VALUES
 */

PRINT 'PART 3: Default Parameter Values';
PRINT '----------------------------------';

IF OBJECT_ID('usp_SearchBooks', 'P') IS NOT NULL DROP PROCEDURE usp_SearchBooks;
GO

CREATE PROCEDURE usp_SearchBooks
    @SearchTerm NVARCHAR(100) = '%',  -- Default: all books
    @MinYear INT = 1900,              -- Default: earliest year
    @MaxResults INT = 100             -- Default: limit results
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@MaxResults)
        BookID,
        Title,
        ISBN,
        PublicationYear,
        Price
    FROM Books
    WHERE Title LIKE '%' + @SearchTerm + '%'
        AND PublicationYear >= @MinYear
    ORDER BY PublicationYear DESC, Title;
END;
GO

PRINT '✓ Created usp_SearchBooks with default parameters';

-- Call with defaults
PRINT 'All books (using defaults):';
EXEC usp_SearchBooks;

-- Call with specific parameters
PRINT '';
PRINT 'Books with "Animal" published after 1940:';
EXEC usp_SearchBooks @SearchTerm = 'Animal', @MinYear = 1940, @MaxResults = 10;
PRINT '';

/*
 * PART 4: OUTPUT PARAMETERS
 */

PRINT 'PART 4: Output Parameters';
PRINT '--------------------------';

IF OBJECT_ID('usp_AddBook', 'P') IS NOT NULL DROP PROCEDURE usp_AddBook;
GO

CREATE PROCEDURE usp_AddBook
    @Title NVARCHAR(255),
    @ISBN NVARCHAR(20),
    @Price DECIMAL(10,2),
    @PublicationYear INT,
    @NewBookID INT OUTPUT  -- OUTPUT parameter
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES (@Title, @ISBN, @Price, @PublicationYear);
    
    -- Return the new ID
    SET @NewBookID = SCOPE_IDENTITY();
    
    RETURN 0;  -- Success
END;
GO

PRINT '✓ Created usp_AddBook with OUTPUT parameter';

-- Call with OUTPUT parameter
DECLARE @NewID INT;
EXEC usp_AddBook 
    @Title = 'SQL Programming Guide',
    @ISBN = '978-1234567890',
    @Price = 49.99,
    @PublicationYear = 2024,
    @NewBookID = @NewID OUTPUT;

PRINT 'New Book ID: ' + CAST(@NewID AS NVARCHAR(10));
PRINT '';

-- Multiple OUTPUT parameters
IF OBJECT_ID('usp_GetBookStats', 'P') IS NOT NULL DROP PROCEDURE usp_GetBookStats;
GO

CREATE PROCEDURE usp_GetBookStats
    @TotalBooks INT OUTPUT,
    @AvgPrice DECIMAL(10,2) OUTPUT,
    @MaxPrice DECIMAL(10,2) OUTPUT,
    @MinPrice DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        @TotalBooks = COUNT(*),
        @AvgPrice = AVG(Price),
        @MaxPrice = MAX(Price),
        @MinPrice = MIN(Price)
    FROM Books;
END;
GO

PRINT '✓ Created usp_GetBookStats with multiple OUTPUT parameters';

-- Execute and retrieve multiple outputs
DECLARE @Total INT, @Avg DECIMAL(10,2), @Max DECIMAL(10,2), @Min DECIMAL(10,2);
EXEC usp_GetBookStats 
    @TotalBooks = @Total OUTPUT,
    @AvgPrice = @Avg OUTPUT,
    @MaxPrice = @Max OUTPUT,
    @MinPrice = @Min OUTPUT;

PRINT 'Total Books: ' + CAST(@Total AS NVARCHAR(10));
PRINT 'Average Price: $' + CAST(@Avg AS NVARCHAR(10));
PRINT 'Max Price: $' + CAST(@Max AS NVARCHAR(10));
PRINT 'Min Price: $' + CAST(@Min AS NVARCHAR(10));
PRINT '';

/*
 * PART 5: RETURN VALUES
 */

PRINT 'PART 5: Return Values';
PRINT '----------------------';

IF OBJECT_ID('usp_UpdateBookPrice', 'P') IS NOT NULL DROP PROCEDURE usp_UpdateBookPrice;
GO

CREATE PROCEDURE usp_UpdateBookPrice
    @BookID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate inputs
    IF @BookID IS NULL OR @NewPrice IS NULL
        RETURN -1;  -- Invalid input
    
    IF @NewPrice < 0
        RETURN -2;  -- Negative price not allowed
    
    -- Check if book exists
    IF NOT EXISTS (SELECT 1 FROM Books WHERE BookID = @BookID)
        RETURN -3;  -- Book not found
    
    -- Update price
    UPDATE Books
    SET Price = @NewPrice
    WHERE BookID = @BookID;
    
    RETURN 0;  -- Success
END;
GO

PRINT '✓ Created usp_UpdateBookPrice with return codes';

-- Test with various scenarios
DECLARE @Result INT;

-- Success case
EXEC @Result = usp_UpdateBookPrice @BookID = 1, @NewPrice = 25.99;
PRINT 'Update BookID 1: Return code = ' + CAST(@Result AS NVARCHAR(10));

-- Negative price
EXEC @Result = usp_UpdateBookPrice @BookID = 1, @NewPrice = -10.00;
PRINT 'Negative price: Return code = ' + CAST(@Result AS NVARCHAR(10));

-- Book not found
EXEC @Result = usp_UpdateBookPrice @BookID = 9999, @NewPrice = 29.99;
PRINT 'Book not found: Return code = ' + CAST(@Result AS NVARCHAR(10));
PRINT '';

/*
 * PART 6: TABLE-VALUED PARAMETERS
 */

PRINT 'PART 6: Table-Valued Parameters';
PRINT '---------------------------------';

-- Create user-defined table type
IF TYPE_ID('dbo.BookList') IS NOT NULL DROP TYPE dbo.BookList;
GO

CREATE TYPE dbo.BookList AS TABLE (
    Title NVARCHAR(255),
    ISBN NVARCHAR(20),
    Price DECIMAL(10,2),
    PublicationYear INT
);
GO

PRINT '✓ Created BookList table type';

-- Create procedure accepting table-valued parameter
IF OBJECT_ID('usp_BulkAddBooks', 'P') IS NOT NULL DROP PROCEDURE usp_BulkAddBooks;
GO

CREATE PROCEDURE usp_BulkAddBooks
    @BookData BookList READONLY
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    SELECT Title, ISBN, Price, PublicationYear
    FROM @BookData;
    
    SELECT @@ROWCOUNT AS BooksAdded;
END;
GO

PRINT '✓ Created usp_BulkAddBooks';

-- Prepare table variable
DECLARE @NewBooks BookList;
INSERT INTO @NewBooks (Title, ISBN, Price, PublicationYear)
VALUES 
    ('Advanced T-SQL', '978-1111111111', 59.99, 2024),
    ('SQL Server Internals', '978-2222222222', 69.99, 2024),
    ('Query Optimization', '978-3333333333', 54.99, 2024);

-- Execute with table parameter
EXEC usp_BulkAddBooks @BookData = @NewBooks;
PRINT '';

/*
 * PART 7: OPTIONAL PARAMETERS
 */

PRINT 'PART 7: Optional Parameters Pattern';
PRINT '-------------------------------------';

IF OBJECT_ID('usp_GetCustomers', 'P') IS NOT NULL DROP PROCEDURE usp_GetCustomers;
GO

CREATE PROCEDURE usp_GetCustomers
    @CustomerID INT = NULL,
    @LastName NVARCHAR(100) = NULL,
    @City NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        Email,
        City
    FROM Customers
    WHERE 
        (@CustomerID IS NULL OR CustomerID = @CustomerID)
        AND (@LastName IS NULL OR LastName LIKE '%' + @LastName + '%')
        AND (@City IS NULL OR City = @City)
    ORDER BY LastName, FirstName;
END;
GO

PRINT '✓ Created usp_GetCustomers with optional search parameters';

-- Test various combinations
PRINT 'All customers:';
EXEC usp_GetCustomers;

PRINT '';
PRINT 'Customers with last name containing "Smith":';
EXEC usp_GetCustomers @LastName = 'Smith';
PRINT '';

/*
 * PART 8: PARAMETER VALIDATION
 */

PRINT 'PART 8: Parameter Validation';
PRINT '------------------------------';

IF OBJECT_ID('usp_CreateOrder', 'P') IS NOT NULL DROP PROCEDURE usp_CreateOrder;
GO

CREATE PROCEDURE usp_CreateOrder
    @CustomerID INT,
    @OrderDate DATE = NULL,  -- Default to today
    @TotalAmount DECIMAL(10,2),
    @Status NVARCHAR(20) = 'Pending'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Parameter validation
    IF @CustomerID IS NULL
    BEGIN
        RAISERROR('CustomerID cannot be NULL', 16, 1);
        RETURN -1;
    END;
    
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = @CustomerID)
    BEGIN
        RAISERROR('Customer not found', 16, 1);
        RETURN -2;
    END;
    
    IF @TotalAmount <= 0
    BEGIN
        RAISERROR('Order amount must be positive', 16, 1);
        RETURN -3;
    END;
    
    IF @Status NOT IN ('Pending', 'Confirmed', 'Shipped', 'Delivered')
    BEGIN
        RAISERROR('Invalid status. Must be: Pending, Confirmed, Shipped, or Delivered', 16, 1);
        RETURN -4;
    END;
    
    -- Set default date if not provided
    SET @OrderDate = ISNULL(@OrderDate, CAST(GETDATE() AS DATE));
    
    -- Insert order
    INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
    VALUES (@CustomerID, @OrderDate, @TotalAmount, @Status);
    
    SELECT SCOPE_IDENTITY() AS NewOrderID;
    RETURN 0;
END;
GO

PRINT '✓ Created usp_CreateOrder with validation';

-- Test validation
BEGIN TRY
    EXEC usp_CreateOrder @CustomerID = 1, @TotalAmount = 99.99;
    PRINT 'Order created successfully';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

/*
 * PART 9: PROCEDURE METADATA
 */

PRINT 'PART 9: Procedure Metadata';
PRINT '---------------------------';

-- View procedure definition
SELECT 
    OBJECT_NAME(object_id) AS ProcedureName,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.procedures
WHERE OBJECT_NAME(object_id) LIKE 'usp_%'
ORDER BY ProcedureName;

PRINT '';

-- View procedure parameters
SELECT 
    OBJECT_NAME(object_id) AS ProcedureName,
    name AS ParameterName,
    TYPE_NAME(user_type_id) AS DataType,
    max_length AS MaxLength,
    is_output AS IsOutput
FROM sys.parameters
WHERE OBJECT_NAME(object_id) = 'usp_AddBook'
ORDER BY parameter_id;

PRINT '';

-- Get procedure text
EXEC sp_helptext 'usp_GetAllBooks';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Best Practices Summary';
PRINT '---------------------------------';
PRINT '';
PRINT 'NAMING CONVENTIONS:';
PRINT '  - Use prefix: usp_ (user stored procedure)';
PRINT '  - Descriptive names: usp_GetCustomerOrders';
PRINT '  - Avoid sp_ prefix (reserved for system)';
PRINT '';
PRINT 'PARAMETERS:';
PRINT '  - Always use @ParameterName syntax';
PRINT '  - Provide defaults where appropriate';
PRINT '  - Validate all inputs';
PRINT '  - Use OUTPUT for returning single values';
PRINT '';
PRINT 'CODE STRUCTURE:';
PRINT '  - SET NOCOUNT ON (reduce network traffic)';
PRINT '  - Use RETURN for status codes';
PRINT '  - 0 = success, negative = error';
PRINT '  - Handle NULL parameters gracefully';
PRINT '';
PRINT 'PERFORMANCE:';
PRINT '  - Minimize table scans';
PRINT '  - Use appropriate indexes';
PRINT '  - Avoid SELECT *';
PRINT '  - Use SET vs SELECT for assignments';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create usp_GetCustomerOrderHistory with CustomerID parameter
 * 2. Create usp_UpdateCustomer with validation and OUTPUT parameter
 * 3. Create usp_DeleteBook with return codes for different scenarios
 * 4. Create usp_SearchOrdersByDateRange with optional parameters
 * 5. Create usp_BulkUpdatePrices using table-valued parameter
 * 
 * CHALLENGE:
 * Create a comprehensive order processing procedure:
 * - Accept customer ID, multiple order items (table param)
 * - Validate customer exists and credit limit
 * - Calculate totals with tax
 * - Create order and order items
 * - Return order ID via OUTPUT parameter
 * - Return 0 for success, negative codes for errors
 */

PRINT '✓ Lab 37 Complete: Stored procedure basics mastered';
GO
