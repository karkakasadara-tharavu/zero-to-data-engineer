/*
 * Lab 42: Functions - Multi-Statement TVFs
 * Module 05: T-SQL Programming
 * 
 * Objective: Learn multi-statement table-valued functions for complex logic
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 42: Multi-Statement Table-Valued Functions';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: BASIC MULTI-STATEMENT TVF
 */

PRINT 'PART 1: Basic Multi-Statement TVF';
PRINT '-----------------------------------';

IF OBJECT_ID('dbo.fn_GetEnrichedBooks', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_GetEnrichedBooks;
GO

CREATE FUNCTION dbo.fn_GetEnrichedBooks()
RETURNS @Result TABLE (
    BookID INT,
    Title NVARCHAR(255),
    Price DECIMAL(10,2),
    PriceCategory NVARCHAR(20),
    AgeInYears INT
)
AS
BEGIN
    -- Insert base data
    INSERT INTO @Result (BookID, Title, Price, PriceCategory, AgeInYears)
    SELECT 
        BookID,
        Title,
        Price,
        CASE 
            WHEN Price < 20 THEN 'Budget'
            WHEN Price < 50 THEN 'Standard'
            ELSE 'Premium'
        END,
        YEAR(GETDATE()) - PublicationYear
    FROM Books;
    
    -- Additional processing
    UPDATE @Result
    SET Title = UPPER(Title)
    WHERE PriceCategory = 'Premium';
    
    RETURN;
END;
GO

PRINT '✓ Created fn_GetEnrichedBooks';

SELECT * FROM dbo.fn_GetEnrichedBooks()
ORDER BY Price DESC;
PRINT '';

/*
 * PART 2: TVF WITH COMPLEX LOGIC
 */

PRINT 'PART 2: Complex Logic with Variables';
PRINT '---------------------------------------';

IF OBJECT_ID('dbo.fn_GetCustomerAnalysis', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_GetCustomerAnalysis;
GO

CREATE FUNCTION dbo.fn_GetCustomerAnalysis (
    @MinOrderCount INT
)
RETURNS @Result TABLE (
    CustomerID INT,
    CustomerName NVARCHAR(200),
    OrderCount INT,
    TotalSpent DECIMAL(10,2),
    AvgOrderValue DECIMAL(10,2),
    Tier NVARCHAR(20),
    DaysSinceLastOrder INT,
    Status NVARCHAR(20)
)
AS
BEGIN
    DECLARE @AvgOrderValue DECIMAL(10,2);
    
    -- Calculate average order value
    SELECT @AvgOrderValue = AVG(TotalAmount)
    FROM Orders;
    
    -- Insert customer data
    INSERT INTO @Result
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName,
        COUNT(o.OrderID) AS OrderCount,
        ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent,
        ISNULL(AVG(o.TotalAmount), 0) AS AvgOrderValue,
        NULL AS Tier,  -- Calculated later
        DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceLastOrder,
        NULL AS Status  -- Calculated later
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName
    HAVING COUNT(o.OrderID) >= @MinOrderCount;
    
    -- Update tier
    UPDATE @Result
    SET Tier = CASE
        WHEN TotalSpent >= 5000 THEN 'Platinum'
        WHEN TotalSpent >= 2500 THEN 'Gold'
        WHEN TotalSpent >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END;
    
    -- Update status
    UPDATE @Result
    SET Status = CASE
        WHEN DaysSinceLastOrder IS NULL THEN 'New'
        WHEN DaysSinceLastOrder <= 30 THEN 'Active'
        WHEN DaysSinceLastOrder <= 90 THEN 'At Risk'
        ELSE 'Churned'
    END;
    
    RETURN;
END;
GO

PRINT '✓ Created fn_GetCustomerAnalysis';

SELECT * FROM dbo.fn_GetCustomerAnalysis(1)
ORDER BY TotalSpent DESC;
PRINT '';

/*
 * PART 3: TVF WITH LOOPS
 */

PRINT 'PART 3: TVF with Iterative Logic';
PRINT '----------------------------------';

IF OBJECT_ID('dbo.fn_GenerateDateRange', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_GenerateDateRange;
GO

CREATE FUNCTION dbo.fn_GenerateDateRange (
    @StartDate DATE,
    @EndDate DATE
)
RETURNS @Dates TABLE (
    DateValue DATE,
    DayOfWeek NVARCHAR(20),
    IsWeekend BIT,
    IsHoliday BIT
)
AS
BEGIN
    DECLARE @CurrentDate DATE = @StartDate;
    
    -- Loop through date range
    WHILE @CurrentDate <= @EndDate
    BEGIN
        INSERT INTO @Dates (DateValue, DayOfWeek, IsWeekend, IsHoliday)
        VALUES (
            @CurrentDate,
            DATENAME(WEEKDAY, @CurrentDate),
            CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END,
            0  -- Simplified: not checking actual holidays
        );
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;
    
    -- Mark specific holidays
    UPDATE @Dates
    SET IsHoliday = 1
    WHERE (MONTH(DateValue) = 1 AND DAY(DateValue) = 1)  -- New Year
       OR (MONTH(DateValue) = 7 AND DAY(DateValue) = 4)  -- Independence Day
       OR (MONTH(DateValue) = 12 AND DAY(DateValue) = 25);  -- Christmas
    
    RETURN;
END;
GO

PRINT '✓ Created fn_GenerateDateRange';

SELECT * FROM dbo.fn_GenerateDateRange('2024-12-01', '2024-12-31')
ORDER BY DateValue;
PRINT '';

/*
 * PART 4: HIERARCHICAL DATA PROCESSING
 */

PRINT 'PART 4: Hierarchical Data';
PRINT '---------------------------';

IF OBJECT_ID('dbo.fn_GetCategoryTree', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_GetCategoryTree;
GO

CREATE FUNCTION dbo.fn_GetCategoryTree (
    @RootCategoryID INT
)
RETURNS @Tree TABLE (
    CategoryID INT,
    CategoryName NVARCHAR(100),
    ParentCategoryID INT,
    Level INT,
    Path NVARCHAR(500)
)
AS
BEGIN
    -- Insert root category
    INSERT INTO @Tree
    SELECT 
        CategoryID,
        CategoryName,
        ParentCategoryID,
        0 AS Level,
        CAST(CategoryName AS NVARCHAR(500))
    FROM CategoryHierarchy
    WHERE CategoryID = @RootCategoryID;
    
    DECLARE @CurrentLevel INT = 0;
    DECLARE @RowsAdded INT = 1;
    
    -- Loop through levels
    WHILE @RowsAdded > 0
    BEGIN
        INSERT INTO @Tree
        SELECT 
            ch.CategoryID,
            ch.CategoryName,
            ch.ParentCategoryID,
            @CurrentLevel + 1,
            t.Path + ' > ' + ch.CategoryName
        FROM CategoryHierarchy ch
        INNER JOIN @Tree t ON ch.ParentCategoryID = t.CategoryID
        WHERE t.Level = @CurrentLevel
            AND NOT EXISTS (SELECT 1 FROM @Tree WHERE CategoryID = ch.CategoryID);
        
        SET @RowsAdded = @@ROWCOUNT;
        SET @CurrentLevel = @CurrentLevel + 1;
        
        -- Safety: prevent infinite loop
        IF @CurrentLevel > 10
            BREAK;
    END;
    
    RETURN;
END;
GO

PRINT '✓ Created fn_GetCategoryTree';

SELECT * FROM dbo.fn_GetCategoryTree(1)
ORDER BY Level, CategoryName;
PRINT '';

/*
 * PART 5: AGGREGATION AND CALCULATIONS
 */

PRINT 'PART 5: Aggregations and Calculations';
PRINT '---------------------------------------';

IF OBJECT_ID('dbo.fn_GetOrderStatistics', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_GetOrderStatistics;
GO

CREATE FUNCTION dbo.fn_GetOrderStatistics (
    @Year INT
)
RETURNS @Stats TABLE (
    StatisticName NVARCHAR(100),
    StatisticValue DECIMAL(18,2)
)
AS
BEGIN
    DECLARE @TotalOrders INT;
    DECLARE @TotalRevenue DECIMAL(18,2);
    DECLARE @AvgOrderValue DECIMAL(18,2);
    DECLARE @MaxOrderValue DECIMAL(18,2);
    DECLARE @MinOrderValue DECIMAL(18,2);
    
    -- Calculate statistics
    SELECT 
        @TotalOrders = COUNT(*),
        @TotalRevenue = SUM(TotalAmount),
        @AvgOrderValue = AVG(TotalAmount),
        @MaxOrderValue = MAX(TotalAmount),
        @MinOrderValue = MIN(TotalAmount)
    FROM Orders
    WHERE YEAR(OrderDate) = @Year;
    
    -- Insert results
    INSERT INTO @Stats VALUES ('Total Orders', @TotalOrders);
    INSERT INTO @Stats VALUES ('Total Revenue', @TotalRevenue);
    INSERT INTO @Stats VALUES ('Average Order Value', @AvgOrderValue);
    INSERT INTO @Stats VALUES ('Highest Order', @MaxOrderValue);
    INSERT INTO @Stats VALUES ('Lowest Order', @MinOrderValue);
    
    -- Additional calculated metrics
    INSERT INTO @Stats
    SELECT 
        'Orders per Month',
        CAST(@TotalOrders AS DECIMAL(18,2)) / 12;
    
    INSERT INTO @Stats
    SELECT 
        'Revenue per Order',
        @TotalRevenue / NULLIF(@TotalOrders, 0);
    
    RETURN;
END;
GO

PRINT '✓ Created fn_GetOrderStatistics';

SELECT * FROM dbo.fn_GetOrderStatistics(2024);
PRINT '';

/*
 * PART 6: DATA TRANSFORMATION
 */

PRINT 'PART 6: Data Transformation';
PRINT '-----------------------------';

IF OBJECT_ID('dbo.fn_ParseCSVToTable', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_ParseCSVToTable;
GO

CREATE FUNCTION dbo.fn_ParseCSVToTable (
    @CSV NVARCHAR(MAX),
    @Delimiter NVARCHAR(1) = ','
)
RETURNS @Result TABLE (
    RowNum INT,
    Value NVARCHAR(MAX)
)
AS
BEGIN
    DECLARE @Pos INT = 1;
    DECLARE @NextPos INT;
    DECLARE @Value NVARCHAR(MAX);
    DECLARE @RowNum INT = 1;
    
    WHILE @Pos <= LEN(@CSV)
    BEGIN
        SET @NextPos = CHARINDEX(@Delimiter, @CSV, @Pos);
        
        IF @NextPos = 0
            SET @NextPos = LEN(@CSV) + 1;
        
        SET @Value = SUBSTRING(@CSV, @Pos, @NextPos - @Pos);
        
        INSERT INTO @Result VALUES (@RowNum, LTRIM(RTRIM(@Value)));
        
        SET @Pos = @NextPos + 1;
        SET @RowNum = @RowNum + 1;
    END;
    
    RETURN;
END;
GO

PRINT '✓ Created fn_ParseCSVToTable';

SELECT * FROM dbo.fn_ParseCSVToTable('Apple,Banana,Cherry,Date,Fig', ',');
PRINT '';

/*
 * PART 7: CONDITIONAL DATA ASSEMBLY
 */

PRINT 'PART 7: Conditional Data Assembly';
PRINT '-----------------------------------';

IF OBJECT_ID('dbo.fn_GetRecommendedProducts', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_GetRecommendedProducts;
GO

CREATE FUNCTION dbo.fn_GetRecommendedProducts (
    @CustomerID INT,
    @MaxResults INT = 5
)
RETURNS @Recommendations TABLE (
    ProductID INT,
    ProductName NVARCHAR(200),
    Price DECIMAL(10,2),
    RecommendationReason NVARCHAR(100),
    Priority INT
)
AS
BEGIN
    -- Get customer's purchase history
    DECLARE @HasOrders BIT = 0;
    
    SELECT @HasOrders = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
    FROM Orders
    WHERE CustomerID = @CustomerID;
    
    IF @HasOrders = 1
    BEGIN
        -- Recommend based on purchase history
        INSERT INTO @Recommendations
        SELECT TOP (@MaxResults)
            p.ProductID,
            p.ProductName,
            p.Price,
            'Frequently purchased together',
            1 AS Priority
        FROM Inventory.Products p
        WHERE p.IsActive = 1
            AND NOT EXISTS (
                SELECT 1 
                FROM Orders o
                INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
                WHERE o.CustomerID = @CustomerID
                    AND oi.ProductID = p.ProductID
            )
        ORDER BY p.StockQuantity DESC;
    END
    ELSE
    BEGIN
        -- Recommend popular products for new customers
        INSERT INTO @Recommendations
        SELECT TOP (@MaxResults)
            p.ProductID,
            p.ProductName,
            p.Price,
            'Popular with new customers',
            2 AS Priority
        FROM Inventory.Products p
        WHERE p.IsActive = 1
        ORDER BY p.Price ASC;
    END;
    
    RETURN;
END;
GO

PRINT '✓ Created fn_GetRecommendedProducts';

SELECT * FROM dbo.fn_GetRecommendedProducts(1, 3);
PRINT '';

/*
 * PART 8: ERROR HANDLING IN TVF
 */

PRINT 'PART 8: Error Handling';
PRINT '-----------------------';

IF OBJECT_ID('dbo.fn_SafeDivideTable', 'TF') IS NOT NULL DROP FUNCTION dbo.fn_SafeDivideTable;
GO

CREATE FUNCTION dbo.fn_SafeDivideTable (
    @Numerator DECIMAL(18,2),
    @Denominator DECIMAL(18,2)
)
RETURNS @Result TABLE (
    Result DECIMAL(18,4),
    ErrorMessage NVARCHAR(200)
)
AS
BEGIN
    IF @Denominator = 0
    BEGIN
        INSERT INTO @Result VALUES (NULL, 'Division by zero error');
    END
    ELSE IF @Numerator IS NULL OR @Denominator IS NULL
    BEGIN
        INSERT INTO @Result VALUES (NULL, 'NULL input values');
    END
    ELSE
    BEGIN
        INSERT INTO @Result VALUES (@Numerator / @Denominator, NULL);
    END;
    
    RETURN;
END;
GO

PRINT '✓ Created fn_SafeDivideTable';

SELECT * FROM dbo.fn_SafeDivideTable(100, 5);
SELECT * FROM dbo.fn_SafeDivideTable(100, 0);
SELECT * FROM dbo.fn_SafeDivideTable(NULL, 5);
PRINT '';

/*
 * PART 9: PERFORMANCE CONSIDERATIONS
 */

PRINT 'PART 9: Performance Considerations';
PRINT '------------------------------------';
PRINT '';
PRINT 'MULTI-STATEMENT TVF CHARACTERISTICS:';
PRINT '  - NOT inlined (treated as black box by optimizer)';
PRINT '  - Cannot use indexes from source tables efficiently';
PRINT '  - Estimated row count often wrong (100 rows default)';
PRINT '  - Slower than inline TVFs';
PRINT '';
PRINT 'WHEN TO USE:';
PRINT '  - Complex procedural logic required';
PRINT '  - Multiple INSERT/UPDATE operations needed';
PRINT '  - Loops or recursion necessary';
PRINT '  - Cannot express logic as single SELECT';
PRINT '';
PRINT 'OPTIMIZATION TIPS:';
PRINT '  - Minimize use (prefer inline TVF if possible)';
PRINT '  - Add PRIMARY KEY to table variable for index';
PRINT '  - Limit result set size';
PRINT '  - Consider stored procedure if updating data';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Best Practices Summary';
PRINT '---------------------------------';
PRINT '';
PRINT 'DESIGN:';
PRINT '  - Define table structure clearly';
PRINT '  - Include all necessary columns';
PRINT '  - Use appropriate data types';
PRINT '  - Add constraints if needed';
PRINT '';
PRINT 'PERFORMANCE:';
PRINT '  - Prefer inline TVF when possible';
PRINT '  - Use multi-statement only when necessary';
PRINT '  - Add indexes to table variables (PRIMARY KEY)';
PRINT '  - Limit rows returned';
PRINT '';
PRINT 'MAINTAINABILITY:';
PRINT '  - Document complex logic';
PRINT '  - Use meaningful variable names';
PRINT '  - Break complex operations into steps';
PRINT '  - Handle edge cases';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create fn_GetMonthlyCalendar (year, month) with all dates
 * 2. Create fn_CalculateAmortizationSchedule (loan amount, rate, term)
 * 3. Create fn_GetProductRecommendations with collaborative filtering
 * 4. Create fn_ParseJSON to extract key-value pairs
 * 5. Create fn_GenerateFibonacci sequence up to N terms
 * 
 * CHALLENGE:
 * Create fn_BuildOrgChart function:
 * - Accept @RootEmployeeID
 * - Build organizational hierarchy
 * - Calculate reporting levels
 * - Include employee count under each manager
 * - Add formatted org path (CEO > VP > Manager > Employee)
 * - Calculate span of control for each manager
 */

PRINT '✓ Lab 42 Complete: Multi-statement TVFs mastered';
GO
