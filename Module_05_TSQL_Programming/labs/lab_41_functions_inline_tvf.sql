/*
 * Lab 41: Functions - Table-Valued Functions (Inline)
 * Module 05: T-SQL Programming
 * 
 * Objective: Master inline table-valued functions for optimal performance
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 41: Inline Table-Valued Functions';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: BASIC INLINE TVF
 */

PRINT 'PART 1: Basic Inline Table-Valued Functions';
PRINT '---------------------------------------------';

-- Simple TVF returning filtered results
IF OBJECT_ID('dbo.fn_GetBooksByYear', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetBooksByYear;
GO

CREATE FUNCTION dbo.fn_GetBooksByYear (
    @Year INT
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        BookID,
        Title,
        ISBN,
        Price,
        PublicationYear
    FROM Books
    WHERE PublicationYear = @Year
);
GO

PRINT '✓ Created fn_GetBooksByYear';

-- Use TVF like a table
SELECT * FROM dbo.fn_GetBooksByYear(2024);
PRINT '';

/*
 * PART 2: TVF WITH MULTIPLE PARAMETERS
 */

PRINT 'PART 2: Multiple Parameters';
PRINT '-----------------------------';

IF OBJECT_ID('dbo.fn_GetBooksByPriceRange', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetBooksByPriceRange;
GO

CREATE FUNCTION dbo.fn_GetBooksByPriceRange (
    @MinPrice DECIMAL(10,2),
    @MaxPrice DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        BookID,
        Title,
        ISBN,
        Price,
        PublicationYear,
        Price - @MinPrice AS PriceAboveMin,
        @MaxPrice - Price AS PriceBelowMax
    FROM Books
    WHERE Price BETWEEN @MinPrice AND @MaxPrice
);
GO

PRINT '✓ Created fn_GetBooksByPriceRange';

SELECT * FROM dbo.fn_GetBooksByPriceRange(15.00, 50.00)
ORDER BY Price;
PRINT '';

/*
 * PART 3: TVF WITH JOINS
 */

PRINT 'PART 3: TVF with Joins';
PRINT '-----------------------';

IF OBJECT_ID('dbo.fn_GetCustomerOrders', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetCustomerOrders;
GO

CREATE FUNCTION dbo.fn_GetCustomerOrders (
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        o.OrderID,
        o.OrderDate,
        o.Status,
        o.TotalAmount,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        c.Email
    FROM Orders o
    INNER JOIN Customers c ON o.CustomerID = c.CustomerID
    WHERE o.CustomerID = @CustomerID
);
GO

PRINT '✓ Created fn_GetCustomerOrders';

SELECT * FROM dbo.fn_GetCustomerOrders(1)
ORDER BY OrderDate DESC;
PRINT '';

/*
 * PART 4: TVF WITH AGGREGATIONS
 */

PRINT 'PART 4: TVF with Aggregations';
PRINT '-------------------------------';

IF OBJECT_ID('dbo.fn_GetOrderSummary', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetOrderSummary;
GO

CREATE FUNCTION dbo.fn_GetOrderSummary (
    @StartDate DATE,
    @EndDate DATE
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent,
        AVG(o.TotalAmount) AS AvgOrderValue,
        MIN(o.OrderDate) AS FirstOrder,
        MAX(o.OrderDate) AS LastOrder
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
        AND o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY c.CustomerID, c.FirstName, c.LastName
);
GO

PRINT '✓ Created fn_GetOrderSummary';

SELECT * FROM dbo.fn_GetOrderSummary('2024-01-01', '2024-12-31')
ORDER BY TotalSpent DESC;
PRINT '';

/*
 * PART 5: TVF REPLACING VIEWS
 */

PRINT 'PART 5: Parameterized Views (TVF)';
PRINT '-----------------------------------';

-- Traditional view (no parameters)
IF OBJECT_ID('vw_RecentOrders', 'V') IS NOT NULL DROP VIEW vw_RecentOrders;
GO

CREATE VIEW vw_RecentOrders
AS
SELECT 
    OrderID,
    OrderDate,
    CustomerID,
    TotalAmount,
    Status
FROM Orders
WHERE OrderDate >= DATEADD(DAY, -30, GETDATE());
GO

PRINT '✓ Created vw_RecentOrders (view)';

-- Better: TVF with parameter
IF OBJECT_ID('dbo.fn_GetRecentOrders', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetRecentOrders;
GO

CREATE FUNCTION dbo.fn_GetRecentOrders (
    @Days INT
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        OrderID,
        OrderDate,
        CustomerID,
        TotalAmount,
        Status,
        DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysAgo
    FROM Orders
    WHERE OrderDate >= DATEADD(DAY, -@Days, GETDATE())
);
GO

PRINT '✓ Created fn_GetRecentOrders (TVF)';

-- Compare
PRINT 'View (fixed 30 days):';
SELECT * FROM vw_RecentOrders;

PRINT '';
PRINT 'TVF (flexible days parameter):';
SELECT * FROM dbo.fn_GetRecentOrders(7);  -- Last 7 days
PRINT '';

/*
 * PART 6: TVF WITH CROSS APPLY
 */

PRINT 'PART 6: TVF with CROSS APPLY';
PRINT '------------------------------';

IF OBJECT_ID('dbo.fn_GetTopOrderItems', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetTopOrderItems;
GO

CREATE FUNCTION dbo.fn_GetTopOrderItems (
    @OrderID INT,
    @TopN INT
)
RETURNS TABLE
AS
RETURN (
    SELECT TOP (@TopN)
        oi.OrderItemID,
        oi.ProductID,
        oi.Quantity,
        oi.UnitPrice,
        oi.LineTotal
    FROM OrderItems oi
    WHERE oi.OrderID = @OrderID
    ORDER BY oi.LineTotal DESC
);
GO

PRINT '✓ Created fn_GetTopOrderItems';

-- Use CROSS APPLY to get top items for each order
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    items.ProductID,
    items.Quantity,
    items.LineTotal
FROM Orders o
CROSS APPLY dbo.fn_GetTopOrderItems(o.OrderID, 2) items
ORDER BY o.OrderID;
PRINT '';

/*
 * PART 7: TVF WITH COMMON TABLE EXPRESSIONS
 */

PRINT 'PART 7: TVF with CTEs';
PRINT '-----------------------';

IF OBJECT_ID('dbo.fn_GetCustomerTierAnalysis', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetCustomerTierAnalysis;
GO

CREATE FUNCTION dbo.fn_GetCustomerTierAnalysis (
    @MinOrders INT
)
RETURNS TABLE
AS
RETURN (
    WITH OrderStats AS (
        SELECT 
            CustomerID,
            COUNT(*) AS OrderCount,
            SUM(TotalAmount) AS TotalSpent
        FROM Orders
        GROUP BY CustomerID
    )
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        ISNULL(os.OrderCount, 0) AS OrderCount,
        ISNULL(os.TotalSpent, 0) AS TotalSpent,
        CASE 
            WHEN os.TotalSpent >= 5000 THEN 'Platinum'
            WHEN os.TotalSpent >= 2500 THEN 'Gold'
            WHEN os.TotalSpent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS Tier
    FROM Customers c
    LEFT JOIN OrderStats os ON c.CustomerID = os.CustomerID
    WHERE ISNULL(os.OrderCount, 0) >= @MinOrders
);
GO

PRINT '✓ Created fn_GetCustomerTierAnalysis';

SELECT * FROM dbo.fn_GetCustomerTierAnalysis(1)
ORDER BY TotalSpent DESC;
PRINT '';

/*
 * PART 8: TVF FOR REPORTING
 */

PRINT 'PART 8: Reporting Functions';
PRINT '-----------------------------';

IF OBJECT_ID('dbo.fn_GetSalesByPeriod', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetSalesByPeriod;
GO

CREATE FUNCTION dbo.fn_GetSalesByPeriod (
    @StartDate DATE,
    @EndDate DATE,
    @GroupBy NVARCHAR(10)  -- 'DAY', 'MONTH', 'YEAR'
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        CASE @GroupBy
            WHEN 'DAY' THEN CAST(OrderDate AS DATE)
            WHEN 'MONTH' THEN DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
            WHEN 'YEAR' THEN DATEFROMPARTS(YEAR(OrderDate), 1, 1)
        END AS Period,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSales,
        AVG(TotalAmount) AS AvgOrderValue
    FROM Orders
    WHERE OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY 
        CASE @GroupBy
            WHEN 'DAY' THEN CAST(OrderDate AS DATE)
            WHEN 'MONTH' THEN DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
            WHEN 'YEAR' THEN DATEFROMPARTS(YEAR(OrderDate), 1, 1)
        END
);
GO

PRINT '✓ Created fn_GetSalesByPeriod';

PRINT 'Sales by month:';
SELECT * FROM dbo.fn_GetSalesByPeriod('2024-01-01', '2024-12-31', 'MONTH')
ORDER BY Period;
PRINT '';

/*
 * PART 9: PERFORMANCE COMPARISON
 */

PRINT 'PART 9: Performance Comparison';
PRINT '--------------------------------';
PRINT '';
PRINT 'INLINE TVF vs SCALAR FUNCTION:';
PRINT '  - Inline TVF: Inlined into query plan (fast!)';
PRINT '  - Scalar Function: Called per row (slow)';
PRINT '';

-- Example: Using TVF in JOIN (efficient)
SET STATISTICS TIME ON;

SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    orders.OrderCount
FROM Customers c
CROSS APPLY (
    SELECT COUNT(*) AS OrderCount
    FROM dbo.fn_GetCustomerOrders(c.CustomerID)
) orders;

SET STATISTICS TIME OFF;
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Best Practices Summary';
PRINT '---------------------------------';
PRINT '';
PRINT 'INLINE TVF ADVANTAGES:';
PRINT '  - Query optimizer inlines into main query';
PRINT '  - Can use indexes efficiently';
PRINT '  - Supports parallelism';
PRINT '  - Better performance than multi-statement TVF';
PRINT '';
PRINT 'WHEN TO USE:';
PRINT '  - Parameterized views';
PRINT '  - Reusable query logic';
PRINT '  - Complex filtering with parameters';
PRINT '  - CROSS APPLY scenarios';
PRINT '';
PRINT 'SYNTAX RESTRICTIONS:';
PRINT '  - Single RETURN statement';
PRINT '  - Must return TABLE';
PRINT '  - No procedural code (DECLARE, IF, etc.)';
PRINT '  - Use CTEs for complex logic';
PRINT '';
PRINT 'TIPS:';
PRINT '  - Prefer inline TVF over multi-statement TVF';
PRINT '  - Use SCHEMABINDING for optimization';
PRINT '  - Consider indexed views if no parameters needed';
PRINT '  - Test with actual execution plans';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create fn_GetActiveProducts with optional category filter
 * 2. Create fn_GetOrdersByStatus with status parameter
 * 3. Create fn_GetCustomersByCity with city filter
 * 4. Create fn_GetTop NProducts with TOP N parameter
 * 5. Create fn_GetSalesRanking returning ranking by sales
 * 
 * CHALLENGE:
 * Create a flexible analytics function:
 * - fn_GetSalesAnalytics(@StartDate, @EndDate, @GroupBy, @FilterColumn, @FilterValue)
 * - Support multiple GROUP BY options (day/month/year/customer)
 * - Support dynamic filtering
 * - Return: Period, OrderCount, TotalSales, AvgOrderValue, GrowthRate
 * - Use CTEs and window functions
 */

PRINT '✓ Lab 41 Complete: Inline TVFs mastered';
GO
