-- Lab 16-19: Execution Plans, Indexing & Capstone
-- Module 03: Advanced SQL
-- Database: AdventureWorks2022

-- =============================================
-- LAB 16: EXECUTION PLANS (⭐⭐⭐⭐⭐) - 5 hours
-- =============================================

-- Enable actual execution plan (Ctrl+M in SSMS)
USE AdventureWorks2022;
GO

-- TASK 1: Identify Table Scans
-- Run this query and analyze the plan:
SELECT * FROM Sales.SalesOrderDetail
WHERE UnitPrice > 1000;

-- Questions:
-- 1. Is it using Index Seek or Table Scan?
-- 2. What's the estimated vs actual row count?
-- 3. What's the most expensive operator?

-- TASK 2: Missing Index Recommendations
-- Run a query that would benefit from an index:
SELECT ProductID, SUM(OrderQty) 
FROM Sales.SalesOrderDetail
WHERE CarrierTrackingNumber LIKE 'AB%'
GROUP BY ProductID;

-- Check for missing index suggestions in the plan
-- Document the recommended index here:

-- TASK 3: Analyze parallelism
-- Run a large aggregation and observe parallelism:
SELECT CustomerID, COUNT(*), SUM(TotalDue)
FROM Sales.SalesOrderHeader
GROUP BY CustomerID;

-- Questions:
-- 1. Did the query run in parallel?
-- 2. How many threads were used?
-- 3. Is there a Sort operator? What's its cost?

-- =============================================
-- LAB 17: INDEXING STRATEGIES (⭐⭐⭐⭐⭐) - 6 hours
-- =============================================

-- TASK 1: Create nonclustered index
-- Measure performance before and after

-- Before index:
SET STATISTICS IO ON;
SELECT ProductID, Name, Color 
FROM Production.Product
WHERE Color = 'Red';
-- Note logical reads: _____

-- Create index:
CREATE NONCLUSTERED INDEX IX_Product_Color
ON Production.Product(Color);

-- After index:
SELECT ProductID, Name, Color 
FROM Production.Product
WHERE Color = 'Red';
-- Note logical reads: _____ (should be lower)

-- TASK 2: Covering index with INCLUDE
CREATE NONCLUSTERED INDEX IX_Product_Color_Covering
ON Production.Product(Color)
INCLUDE (ProductID, Name);

-- Test: Should be even faster
SELECT ProductID, Name, Color 
FROM Production.Product
WHERE Color = 'Red';

-- TASK 3: Index fragmentation
-- Check fragmentation:
SELECT 
    object_name(object_id) AS TableName,
    index_id,
    avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    OBJECT_ID('Sales.SalesOrderDetail'), 
    NULL, NULL, 'LIMITED'
);

-- If fragmentation > 30%, rebuild:
-- ALTER INDEX ALL ON Sales.SalesOrderDetail REBUILD;

-- =============================================
-- LAB 18: ADVANCED TECHNIQUES (⭐⭐⭐⭐⭐) - 5 hours
-- =============================================

-- TASK 1: PIVOT for crosstab report
SELECT *
FROM (
    SELECT YEAR(OrderDate) AS Year, 
           MONTH(OrderDate) AS Month, 
           TotalDue
    FROM Sales.SalesOrderHeader
) AS SourceData
PIVOT (
    SUM(TotalDue)
    FOR Month IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
) AS PivotTable;

-- TASK 2: Dynamic SQL
DECLARE @CategoryName NVARCHAR(50) = 'Bikes';
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
SELECT p.Name, p.ListPrice
FROM Production.Product p
INNER JOIN Production.ProductSubcategory s ON p.ProductSubcategoryID = s.ProductSubcategoryID
INNER JOIN Production.ProductCategory c ON s.ProductCategoryID = c.ProductCategoryID
WHERE c.Name = @Cat';

EXEC sp_executesql @SQL, N'@Cat NVARCHAR(50)', @Cat = @CategoryName;

-- TASK 3: Temp table vs table variable
-- Temp table (persisted, can have indexes):
CREATE TABLE #TempOrders (
    OrderID INT,
    TotalDue MONEY
);

INSERT INTO #TempOrders
SELECT SalesOrderID, TotalDue 
FROM Sales.SalesOrderHeader WHERE YEAR(OrderDate) = 2013;

-- Table variable (in-memory, fast for small datasets):
DECLARE @OrdersVar TABLE (
    OrderID INT,
    TotalDue MONEY
);

-- Compare performance for 10K+ rows

-- =============================================
-- LAB 19: CAPSTONE PROJECT (⭐⭐⭐⭐⭐) - 8 hours
-- =============================================

-- Build a comprehensive sales performance dashboard
-- Requirements:
-- 1. Use CTEs for data staging
-- 2. Use window functions for rankings and trends
-- 3. Optimize with proper indexes
-- 4. Analyze execution plans
-- 5. Document performance improvements

-- Your complete solution here (multi-query report):



-- Deliverables:
-- 1. Customer lifetime value report (CTE + window functions)
-- 2. Month-over-month growth analysis (LAG/LEAD)
-- 3. Top 10 products per category (PARTITION BY)
-- 4. Recursive category hierarchy
-- 5. Performance tuning documentation
-- 6. Before/after execution plans
-- 7. Index recommendations implemented

-- Success criteria:
-- - Query execution < 2 seconds
-- - Proper use of 5+ advanced techniques
-- - Clean, commented code
-- - Comprehensive analysis
