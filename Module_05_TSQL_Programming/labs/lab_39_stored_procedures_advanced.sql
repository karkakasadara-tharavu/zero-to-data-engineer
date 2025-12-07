/*
 * Lab 39: Stored Procedures - Advanced Topics
 * Module 05: T-SQL Programming
 * 
 * Objective: Master dynamic SQL, cursors, and advanced procedure techniques
 * Duration: 2 hours
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 39: Advanced Stored Procedures';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: DYNAMIC SQL WITH sp_executesql
 */

PRINT 'PART 1: Dynamic SQL with sp_executesql';
PRINT '----------------------------------------';

IF OBJECT_ID('usp_DynamicSearch', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicSearch;
GO

CREATE PROCEDURE usp_DynamicSearch
    @TableName NVARCHAR(128),
    @SearchColumn NVARCHAR(128),
    @SearchValue NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500);
    
    -- Build dynamic SQL (parameterized for SQL injection prevention)
    SET @SQL = N'SELECT TOP 100 * FROM ' + QUOTENAME(@TableName) + 
               N' WHERE ' + QUOTENAME(@SearchColumn) + N' LIKE @Search';
    
    SET @Params = N'@Search NVARCHAR(255)';
    
    -- Execute with parameter
    EXEC sp_executesql @SQL, @Params, @Search = @SearchValue;
END;
GO

PRINT '✓ Created usp_DynamicSearch';

-- Test dynamic search
EXEC usp_DynamicSearch 
    @TableName = 'Books',
    @SearchColumn = 'Title',
    @SearchValue = '%SQL%';
PRINT '';

/*
 * PART 2: DYNAMIC PIVOT QUERIES
 */

PRINT 'PART 2: Dynamic Pivot Queries';
PRINT '-------------------------------';

-- Create sales data for pivot demo
IF OBJECT_ID('MonthlySales', 'U') IS NOT NULL DROP TABLE MonthlySales;
CREATE TABLE MonthlySales (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100),
    SaleMonth NVARCHAR(20),
    SaleAmount DECIMAL(10,2)
);

INSERT INTO MonthlySales (ProductName, SaleMonth, SaleAmount)
VALUES
    ('Widget', 'Jan', 1000), ('Widget', 'Feb', 1500), ('Widget', 'Mar', 1200),
    ('Gadget', 'Jan', 2000), ('Gadget', 'Feb', 2500), ('Gadget', 'Mar', 1800),
    ('Gizmo', 'Jan', 500), ('Gizmo', 'Feb', 600), ('Gizmo', 'Mar', 700);

PRINT '✓ Created sample MonthlySales data';

IF OBJECT_ID('usp_DynamicPivot', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicPivot;
GO

CREATE PROCEDURE usp_DynamicPivot
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Columns NVARCHAR(MAX);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Get distinct months for pivot columns
    SELECT @Columns = STRING_AGG(QUOTENAME(SaleMonth), ', ')
    FROM (SELECT DISTINCT SaleMonth FROM MonthlySales) AS Months;
    
    -- Build pivot query
    SET @SQL = N'
    SELECT ProductName, ' + @Columns + N'
    FROM (
        SELECT ProductName, SaleMonth, SaleAmount
        FROM MonthlySales
    ) AS SourceTable
    PIVOT (
        SUM(SaleAmount)
        FOR SaleMonth IN (' + @Columns + N')
    ) AS PivotTable
    ORDER BY ProductName;';
    
    PRINT 'Executing dynamic pivot:';
    PRINT @SQL;
    PRINT '';
    
    EXEC sp_executesql @SQL;
END;
GO

PRINT '✓ Created usp_DynamicPivot';
EXEC usp_DynamicPivot;
PRINT '';

/*
 * PART 3: CURSOR OPERATIONS
 */

PRINT 'PART 3: Cursor Operations';
PRINT '--------------------------';

IF OBJECT_ID('usp_ProcessBooksWithCursor', 'P') IS NOT NULL DROP PROCEDURE usp_ProcessBooksWithCursor;
GO

CREATE PROCEDURE usp_ProcessBooksWithCursor
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BookID INT;
    DECLARE @Title NVARCHAR(255);
    DECLARE @Price DECIMAL(10,2);
    DECLARE @NewPrice DECIMAL(10,2);
    DECLARE @Count INT = 0;
    
    -- Declare cursor
    DECLARE book_cursor CURSOR FOR
        SELECT BookID, Title, Price
        FROM Books
        WHERE Price > 0
        ORDER BY BookID;
    
    -- Open cursor
    OPEN book_cursor;
    
    -- Fetch first row
    FETCH NEXT FROM book_cursor INTO @BookID, @Title, @Price;
    
    -- Loop through rows
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Process each book (e.g., apply 10% discount)
        SET @NewPrice = @Price * 0.9;
        
        PRINT 'Book ' + CAST(@BookID AS NVARCHAR(10)) + ': ' + @Title + 
              ' - Price: $' + CAST(@Price AS NVARCHAR(10)) + 
              ' → $' + CAST(@NewPrice AS NVARCHAR(10));
        
        SET @Count = @Count + 1;
        
        -- Fetch next row
        FETCH NEXT FROM book_cursor INTO @BookID, @Title, @Price;
    END;
    
    -- Clean up
    CLOSE book_cursor;
    DEALLOCATE book_cursor;
    
    PRINT '';
    PRINT 'Processed ' + CAST(@Count AS NVARCHAR(10)) + ' books';
    PRINT '';
    PRINT 'NOTE: Cursors are slow! Prefer set-based operations.';
END;
GO

PRINT '✓ Created usp_ProcessBooksWithCursor';
EXEC usp_ProcessBooksWithCursor;
PRINT '';

/*
 * PART 4: RECURSIVE PROCEDURES
 */

PRINT 'PART 4: Recursive Procedures';
PRINT '-----------------------------';

-- Create category hierarchy
IF OBJECT_ID('CategoryHierarchy', 'U') IS NOT NULL DROP TABLE CategoryHierarchy;
CREATE TABLE CategoryHierarchy (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100),
    ParentCategoryID INT
);

INSERT INTO CategoryHierarchy VALUES
    (1, 'Electronics', NULL),
    (2, 'Computers', 1),
    (3, 'Laptops', 2),
    (4, 'Desktops', 2),
    (5, 'Phones', 1),
    (6, 'Smartphones', 5);

PRINT '✓ Created CategoryHierarchy';

IF OBJECT_ID('usp_GetCategoryPath', 'P') IS NOT NULL DROP PROCEDURE usp_GetCategoryPath;
GO

CREATE PROCEDURE usp_GetCategoryPath
    @CategoryID INT,
    @Path NVARCHAR(MAX) OUTPUT,
    @Level INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CategoryName NVARCHAR(100);
    DECLARE @ParentID INT;
    
    -- Get category info
    SELECT 
        @CategoryName = CategoryName,
        @ParentID = ParentCategoryID
    FROM CategoryHierarchy
    WHERE CategoryID = @CategoryID;
    
    -- Build path
    IF @Path IS NULL
        SET @Path = @CategoryName;
    ELSE
        SET @Path = @CategoryName + ' > ' + @Path;
    
    -- Recursive call if has parent
    IF @ParentID IS NOT NULL
    BEGIN
        EXEC usp_GetCategoryPath 
            @CategoryID = @ParentID,
            @Path = @Path OUTPUT,
            @Level = @Level + 1;
    END;
END;
GO

PRINT '✓ Created usp_GetCategoryPath (recursive)';

-- Test recursion
DECLARE @CategoryPath NVARCHAR(MAX);
EXEC usp_GetCategoryPath @CategoryID = 3, @Path = @CategoryPath OUTPUT;
PRINT 'Path for Laptops: ' + @CategoryPath;
PRINT '';

/*
 * PART 5: TEMP TABLE AND TABLE VARIABLE STRATEGIES
 */

PRINT 'PART 5: Temp Tables vs Table Variables';
PRINT '----------------------------------------';

IF OBJECT_ID('usp_ComplexReportWithTemp', 'P') IS NOT NULL DROP PROCEDURE usp_ComplexReportWithTemp;
GO

CREATE PROCEDURE usp_ComplexReportWithTemp
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Temp table (better for large datasets, statistics available)
    CREATE TABLE #CustomerSummary (
        CustomerID INT PRIMARY KEY,
        TotalOrders INT,
        TotalSpent DECIMAL(10,2),
        AvgOrderValue DECIMAL(10,2)
    );
    
    INSERT INTO #CustomerSummary
    SELECT 
        c.CustomerID,
        COUNT(o.OrderID) AS TotalOrders,
        ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent,
        ISNULL(AVG(o.TotalAmount), 0) AS AvgOrderValue
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID;
    
    -- Create index on temp table
    CREATE INDEX IX_Temp_TotalSpent ON #CustomerSummary(TotalSpent DESC);
    
    -- Query temp table
    SELECT 
        CustomerID,
        TotalOrders,
        TotalSpent,
        AvgOrderValue,
        CASE 
            WHEN TotalSpent >= 1000 THEN 'Gold'
            WHEN TotalSpent >= 500 THEN 'Silver'
            ELSE 'Bronze'
        END AS CustomerTier
    FROM #CustomerSummary
    ORDER BY TotalSpent DESC;
    
    -- Temp table auto-drops when procedure ends
END;
GO

PRINT '✓ Created usp_ComplexReportWithTemp';
EXEC usp_ComplexReportWithTemp;
PRINT '';

IF OBJECT_ID('usp_SmallDatasetWithVariable', 'P') IS NOT NULL DROP PROCEDURE usp_SmallDatasetWithVariable;
GO

CREATE PROCEDURE usp_SmallDatasetWithVariable
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Table variable (better for small datasets, no statistics)
    DECLARE @RecentOrders TABLE (
        OrderID INT,
        OrderDate DATE,
        TotalAmount DECIMAL(10,2),
        RowNum INT
    );
    
    INSERT INTO @RecentOrders
    SELECT TOP 10
        OrderID,
        OrderDate,
        TotalAmount,
        ROW_NUMBER() OVER (ORDER BY OrderDate DESC) AS RowNum
    FROM Orders
    ORDER BY OrderDate DESC;
    
    SELECT * FROM @RecentOrders;
END;
GO

PRINT '✓ Created usp_SmallDatasetWithVariable';
EXEC usp_SmallDatasetWithVariable;
PRINT '';

/*
 * PART 6: OUTPUT CLAUSE IN PROCEDURES
 */

PRINT 'PART 6: OUTPUT Clause for Auditing';
PRINT '------------------------------------';

IF OBJECT_ID('usp_BulkUpdateWithAudit', 'P') IS NOT NULL DROP PROCEDURE usp_BulkUpdateWithAudit;
GO

CREATE PROCEDURE usp_BulkUpdateWithAudit
    @PriceIncreasePercent DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Table to capture changes
    DECLARE @Changes TABLE (
        Action NVARCHAR(10),
        BookID INT,
        OldPrice DECIMAL(10,2),
        NewPrice DECIMAL(10,2)
    );
    
    -- Update with OUTPUT clause
    UPDATE Books
    SET Price = Price * (1 + @PriceIncreasePercent / 100)
    OUTPUT 
        'UPDATE' AS Action,
        INSERTED.BookID,
        DELETED.Price AS OldPrice,
        INSERTED.Price AS NewPrice
    INTO @Changes
    WHERE PublicationYear >= 2020;
    
    -- Display changes
    SELECT 
        Action,
        BookID,
        OldPrice,
        NewPrice,
        NewPrice - OldPrice AS PriceChange,
        (NewPrice - OldPrice) / OldPrice * 100 AS PercentChange
    FROM @Changes
    ORDER BY BookID;
    
    PRINT '';
    PRINT 'Updated ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' books';
END;
GO

PRINT '✓ Created usp_BulkUpdateWithAudit';
PRINT 'Applying 5% price increase to recent books:';
EXEC usp_BulkUpdateWithAudit @PriceIncreasePercent = 5.0;
PRINT '';

/*
 * PART 7: RECOMPILE AND OPTIMIZE FOR HINTS
 */

PRINT 'PART 7: Query Hints (RECOMPILE, OPTIMIZE FOR)';
PRINT '-----------------------------------------------';

IF OBJECT_ID('usp_SearchWithHints', 'P') IS NOT NULL DROP PROCEDURE usp_SearchWithHints;
GO

CREATE PROCEDURE usp_SearchWithHints
    @MinPrice DECIMAL(10,2),
    @MaxPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Option 1: RECOMPILE (always generate new plan)
    SELECT BookID, Title, Price
    FROM Books
    WHERE Price BETWEEN @MinPrice AND @MaxPrice
    OPTION (RECOMPILE);
    
    -- Option 2: OPTIMIZE FOR (optimize for specific values)
    -- SELECT BookID, Title, Price
    -- FROM Books
    -- WHERE Price BETWEEN @MinPrice AND @MaxPrice
    -- OPTION (OPTIMIZE FOR (@MinPrice = 10.00, @MaxPrice = 50.00));
END;
GO

PRINT '✓ Created usp_SearchWithHints';
EXEC usp_SearchWithHints @MinPrice = 15.00, @MaxPrice = 30.00;
PRINT '';

/*
 * PART 8: XML AND JSON OUTPUT
 */

PRINT 'PART 8: XML and JSON Output';
PRINT '-----------------------------';

IF OBJECT_ID('usp_GetBooksAsXML', 'P') IS NOT NULL DROP PROCEDURE usp_GetBooksAsXML;
GO

CREATE PROCEDURE usp_GetBooksAsXML
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
    FOR XML AUTO, ROOT('Books'), ELEMENTS;
END;
GO

PRINT '✓ Created usp_GetBooksAsXML';

IF OBJECT_ID('usp_GetBooksAsJSON', 'P') IS NOT NULL DROP PROCEDURE usp_GetBooksAsJSON;
GO

CREATE PROCEDURE usp_GetBooksAsJSON
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
    FOR JSON AUTO, ROOT('Books');
END;
GO

PRINT '✓ Created usp_GetBooksAsJSON';

PRINT 'XML Output:';
EXEC usp_GetBooksAsXML;

PRINT '';
PRINT 'JSON Output:';
EXEC usp_GetBooksAsJSON;
PRINT '';

/*
 * PART 9: ENCRYPTION AND OBFUSCATION
 */

PRINT 'PART 9: Procedure Encryption';
PRINT '------------------------------';

IF OBJECT_ID('usp_SensitiveOperation', 'P') IS NOT NULL DROP PROCEDURE usp_SensitiveOperation;
GO

CREATE PROCEDURE usp_SensitiveOperation
WITH ENCRYPTION  -- Encrypt procedure text
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Sensitive business logic here
    SELECT 'This procedure is encrypted' AS Message;
    
    -- Encryption prevents:
    -- - sp_helptext from showing source
    -- - sys.sql_modules from showing definition
END;
GO

PRINT '✓ Created usp_SensitiveOperation (encrypted)';

-- Try to view (will fail)
BEGIN TRY
    EXEC sp_helptext 'usp_SensitiveOperation';
END TRY
BEGIN CATCH
    PRINT 'Cannot view encrypted procedure: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

/*
 * PART 10: BEST PRACTICES SUMMARY
 */

PRINT 'PART 10: Advanced Techniques Best Practices';
PRINT '---------------------------------------------';
PRINT '';
PRINT 'DYNAMIC SQL:';
PRINT '  - Always use sp_executesql (not EXEC string)';
PRINT '  - Parameterize to prevent SQL injection';
PRINT '  - Use QUOTENAME for identifiers';
PRINT '  - Careful with privileges (runs as caller)';
PRINT '';
PRINT 'CURSORS:';
PRINT '  - AVOID if possible (use set-based operations)';
PRINT '  - If needed: FAST_FORWARD cursor type';
PRINT '  - Always CLOSE and DEALLOCATE';
PRINT '  - Consider table variables + WHILE loop instead';
PRINT '';
PRINT 'TEMP TABLES vs TABLE VARIABLES:';
PRINT '  - Temp tables: Large datasets (> 1000 rows)';
PRINT '  - Temp tables: Need indexes or statistics';
PRINT '  - Table variables: Small datasets (< 100 rows)';
PRINT '  - Table variables: No locking overhead';
PRINT '';
PRINT 'RECURSION:';
PRINT '  - Set MAXRECURSION option to prevent infinite loops';
PRINT '  - Alternative: Recursive CTE often better';
PRINT '  - Document maximum expected recursion depth';
PRINT '';
PRINT 'PERFORMANCE HINTS:';
PRINT '  - RECOMPILE: For parameter sniffing issues';
PRINT '  - OPTIMIZE FOR: When data skewed';
PRINT '  - MAXDOP: Control parallelism';
PRINT '  - Test impact before production use';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create dynamic search procedure with multiple optional columns
 * 2. Build procedure that generates INSERT scripts dynamically
 * 3. Implement batch processing with cursor (last resort!)
 * 4. Create recursive category tree procedure
 * 5. Build audit trail using OUTPUT clause
 * 
 * CHALLENGE:
 * Create metadata-driven ETL procedure:
 * - Read table list from configuration table
 * - Dynamically build SQL for each table
 * - Execute with sp_executesql
 * - Capture row counts using OUTPUT
 * - Log results to audit table
 * - Handle errors with retry logic
 */

PRINT '✓ Lab 39 Complete: Advanced stored procedures mastered';
GO
