-- Solution: Lab 11 - Common Table Expressions
-- Module 03: Advanced SQL

USE AdventureWorks2022;
GO

-- =============================================
-- TASK 1: Simple CTE for Product Analysis
-- =============================================

-- METHOD 1: Basic CTE
WITH AvgPrice AS (
    SELECT AVG(ListPrice) AS AvgListPrice
    FROM Production.Product
    WHERE ListPrice > 0
)
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    a.AvgListPrice,
    p.ListPrice - a.AvgListPrice AS DifferenceFromAvg
FROM Production.Product p
CROSS JOIN AvgPrice a
WHERE p.ListPrice > a.AvgListPrice
ORDER BY p.ListPrice DESC;

-- METHOD 2: Using subquery (for comparison)
SELECT 
    ProductID,
    Name,
    ListPrice,
    (SELECT AVG(ListPrice) FROM Production.Product WHERE ListPrice > 0) AS AvgListPrice
FROM Production.Product
WHERE ListPrice > (SELECT AVG(ListPrice) FROM Production.Product WHERE ListPrice > 0)
ORDER BY ListPrice DESC;

-- ✅ Why CTE is better: More readable, calculates average once

-- =============================================
-- TASK 2: Multiple CTEs - Customer Segmentation
-- =============================================

WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        COUNT(o.SalesOrderID) AS OrderCount,
        SUM(o.TotalDue) AS TotalSpent,
        AVG(o.TotalDue) AS AvgOrderValue
    FROM Sales.Customer c
    INNER JOIN Sales.SalesOrderHeader o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID
),
CustomerSegments AS (
    SELECT 
        CustomerID,
        OrderCount,
        TotalSpent,
        AvgOrderValue,
        CASE 
            WHEN TotalSpent >= 10000 THEN 'VIP'
            WHEN TotalSpent >= 1000 THEN 'Regular'
            ELSE 'New'
        END AS Segment
    FROM CustomerMetrics
),
SegmentStats AS (
    SELECT 
        Segment,
        COUNT(*) AS CustomerCount,
        AVG(TotalSpent) AS AvgSpent,
        MIN(TotalSpent) AS MinSpent,
        MAX(TotalSpent) AS MaxSpent
    FROM CustomerSegments
    GROUP BY Segment
)
SELECT * FROM SegmentStats
ORDER BY AvgSpent DESC;

-- Expected output:
-- Segment  | CustomerCount | AvgSpent    | MinSpent | MaxSpent
-- VIP      | ~500         | $50,000     | $10,000  | $250,000
-- Regular  | ~8,000       | $3,500      | $1,000   | $9,999
-- New      | ~10,000      | $350        | $10      | $999

-- =============================================
-- TASK 3: CTE with JOINs - Top Sellers
-- =============================================

WITH ProductRevenue AS (
    SELECT 
        p.ProductID,
        p.Name,
        pc.Name AS Category,
        SUM(sod.LineTotal) AS TotalRevenue,
        SUM(sod.OrderQty) AS TotalQuantity
    FROM Production.Product p
    INNER JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    GROUP BY p.ProductID, p.Name, pc.Name
)
SELECT TOP 5
    ProductID,
    Name,
    Category,
    TotalRevenue,
    TotalQuantity
FROM ProductRevenue
ORDER BY TotalRevenue DESC;

-- Expected: Mountain-200 series, Road bikes dominate

-- =============================================
-- TASK 4: Year-over-Year Comparison
-- =============================================

WITH Sales2013 AS (
    SELECT 
        MONTH(OrderDate) AS Month,
        SUM(TotalDue) AS Revenue2013
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2013
    GROUP BY MONTH(OrderDate)
),
Sales2014 AS (
    SELECT 
        MONTH(OrderDate) AS Month,
        SUM(TotalDue) AS Revenue2014
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2014
    GROUP BY MONTH(OrderDate)
)
SELECT 
    COALESCE(s13.Month, s14.Month) AS Month,
    DATENAME(MONTH, DATEADD(MONTH, COALESCE(s13.Month, s14.Month) - 1, 0)) AS MonthName,
    ISNULL(s13.Revenue2013, 0) AS Revenue2013,
    ISNULL(s14.Revenue2014, 0) AS Revenue2014,
    ISNULL(s14.Revenue2014, 0) - ISNULL(s13.Revenue2013, 0) AS Difference,
    CASE 
        WHEN s13.Revenue2013 IS NULL OR s13.Revenue2013 = 0 THEN NULL
        ELSE CAST((s14.Revenue2014 - s13.Revenue2013) / s13.Revenue2013 * 100 AS DECIMAL(10,2))
    END AS GrowthPercent
FROM Sales2013 s13
FULL OUTER JOIN Sales2014 s14 ON s13.Month = s14.Month
ORDER BY Month;

-- =============================================
-- COMMON MISTAKES
-- =============================================

-- ❌ MISTAKE 1: Forgetting to filter NULL prices
-- This inflates the average:
WITH AvgPrice AS (
    SELECT AVG(ListPrice) AS Avg FROM Production.Product  -- includes zeros!
)
-- ✅ FIX: WHERE ListPrice > 0

-- ❌ MISTAKE 2: Missing GROUP BY in aggregation CTE
-- ✅ FIX: Always GROUP BY non-aggregated columns

-- ❌ MISTAKE 3: Referencing CTE outside its scope
WITH TempData AS (SELECT * FROM Product)
SELECT * FROM TempData;  -- ✅ Works

SELECT * FROM TempData;  -- ❌ Error: "Invalid object name"

-- =============================================
-- REFLECTION ANSWERS
-- =============================================
-- 1. Use CTE when: query is complex, need readability, reference multiple times
-- 2. CTE limitations: single query scope, no indexes, no statistics
-- 3. Yes! Reference multiple times with CROSS JOIN or multiple SELECTs from same CTE
