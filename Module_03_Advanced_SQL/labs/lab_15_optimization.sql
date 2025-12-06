-- Lab 15: Query Optimization
-- Module 03: Advanced SQL
-- Database: AdventureWorks2022
-- Difficulty: ⭐⭐⭐⭐

-- =============================================
-- SETUP: Enable execution statistics
-- =============================================
USE AdventureWorks2022;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- =============================================
-- TASK 1: Fix Non-SARGable Queries (⭐⭐⭐)
-- =============================================

-- ❌ BAD: Function on column
SELECT * FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013;

-- ✅ GOOD: Rewrite to be SARGable (your solution):



-- ❌ BAD: Leading wildcard
SELECT * FROM Production.Product
WHERE Name LIKE '%Bike%';

-- ✅ GOOD: If you only need "starts with", rewrite:



-- Expected Result: GOOD query should have fewer logical reads
-- Self-Check: Compare IO statistics before and after

-- =============================================
-- TASK 2: Optimize JOINs (⭐⭐⭐⭐)
-- =============================================

-- ❌ BAD: Filter after JOIN
SELECT p.ProductID, p.Name, c.Name AS Category
FROM Production.Product p
INNER JOIN Production.ProductSubcategory s ON p.ProductSubcategoryID = s.ProductSubcategoryID
INNER JOIN Production.ProductCategory c ON s.ProductCategoryID = c.ProductCategoryID
WHERE c.Name = 'Bikes';

-- ✅ GOOD: Filter before JOIN using subquery or CTE (your solution):



-- Expected Result: Faster execution, fewer rows processed
-- Self-Check: Check actual rows read in execution plan

-- =============================================
-- TASK 3: Replace SELECT * (⭐⭐⭐)
-- =============================================

-- ❌ BAD: Retrieves all columns
SELECT * FROM Sales.SalesOrderHeader
WHERE TotalDue > 10000;

-- ✅ GOOD: Only needed columns (assume we need ID, Date, Total):



-- Expected Result: Less data transferred, potential covering index
-- Self-Check: Compare execution time and logical reads

-- =============================================
-- TASK 4: EXISTS vs IN (⭐⭐⭐⭐)
-- =============================================

-- Find customers who placed orders in 2013

-- Option 1: IN
SELECT CustomerID, AccountNumber
FROM Sales.Customer
WHERE CustomerID IN (
    SELECT CustomerID 
    FROM Sales.SalesOrderHeader 
    WHERE YEAR(OrderDate) = 2013
);

-- Option 2: EXISTS (your solution - optimize the date filter too):



-- Expected Result: EXISTS should be faster for large datasets
-- Self-Check: Compare execution plans and times

-- =============================================
-- TASK 5: Avoid DISTINCT with Poor JOINs (⭐⭐⭐⭐⭐)
-- =============================================

-- ❌ BAD: JOIN then DISTINCT (duplicates then removes them)
SELECT DISTINCT c.CustomerID, c.AccountNumber
FROM Sales.Customer c
INNER JOIN Sales.SalesOrderHeader o ON c.CustomerID = o.CustomerID;

-- ✅ GOOD: Use EXISTS to check existence (your solution):



-- Expected Result: No DISTINCT needed, faster execution
-- Self-Check: EXISTS stops at first match per customer

-- =============================================
-- TASK 6: Optimize Aggregates with WHERE (⭐⭐⭐)
-- =============================================

-- Calculate total sales for 2013

-- ❌ BAD: Aggregate then filter
SELECT SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
HAVING YEAR(OrderDate) = 2013;

-- ✅ GOOD: Filter then aggregate (your solution):



-- Expected Result: WHERE is faster than HAVING for row filters
-- Self-Check: Fewer rows aggregated

-- =============================================
-- CHALLENGE: Comprehensive Optimization (⭐⭐⭐⭐⭐)
-- =============================================

-- Optimize this poorly written query:
SELECT DISTINCT *
FROM Production.Product p
INNER JOIN Production.ProductSubcategory s ON p.ProductSubcategoryID = s.ProductSubcategoryID
INNER JOIN Production.ProductCategory c ON s.ProductCategoryID = c.ProductCategoryID
WHERE YEAR(p.SellStartDate) = 2013
AND c.Name LIKE '%Bike%'
ORDER BY p.Name;

-- List all optimizations you would apply:
-- 1. 
-- 2. 
-- 3. 
-- 4. 
-- 5. 

-- Your optimized query:



-- =============================================
-- REFLECTION QUESTIONS
-- =============================================
-- 1. What does SARGable mean? Give 2 examples
-- 2. Why is EXISTS often faster than IN?
-- 3. When is DISTINCT a sign of poor query design?

-- ANSWER 1: 

-- ANSWER 2: 

-- ANSWER 3: 

-- =============================================
-- CLEANUP
-- =============================================
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
