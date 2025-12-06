/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                   LAB 03: SORTING & LIMITING RESULTS                         ║
║                        Module 02: SQL Fundamentals                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

Estimated Time: 45 minutes
Difficulty: ⭐ Beginner
Database: AdventureWorksLT2022
*/

USE AdventureWorksLT2022;
GO

-- TASK 1: Top 10 Most Expensive Products (⭐ Easy)
-- Return: ProductID, Name, ListPrice
-- Sort: Price descending, Limit: 10

SELECT TOP 10 
    ProductID, 
    Name, 
    ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;


-- TASK 2: All Unique Product Colors (⭐ Easy)
-- Remove duplicates, exclude NULLs, sort alphabetically

SELECT DISTINCT Color
FROM SalesLT.Product
WHERE Color IS NOT NULL
ORDER BY Color;


-- TASK 3: Products Sorted by Multiple Columns (⭐⭐ Medium)
-- Sort by Color (A-Z), then ListPrice (high to low), then Name (A-Z)

SELECT ProductID, Name, Color, ListPrice
FROM SalesLT.Product
WHERE Color IS NOT NULL
ORDER BY Color ASC, ListPrice DESC, Name ASC;


-- TASK 4: Pagination - Page 2 of Products (⭐⭐ Medium)
-- Show rows 11-20 when sorted by ProductID
-- Use OFFSET/FETCH

SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ProductID
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;


-- TASK 5: Top 5 Customers by Total Spending (⭐⭐⭐ Hard)
-- Aggregate by customer, calculate total, show top 5

SELECT TOP 5
    CustomerID,
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS TotalSpent
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
ORDER BY TotalSpent DESC;


-- TASK 6: Recent Orders with Pagination (⭐⭐⭐ Hard)
-- Show orders 21-30 when sorted by OrderDate (newest first)

SELECT 
    SalesOrderID,
    OrderDate,
    CustomerID,
    TotalDue
FROM SalesLT.SalesOrderHeader
ORDER BY OrderDate DESC
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;


-- 💪 BONUS: Top 10 WITH TIES (⭐⭐⭐⭐)
-- Include all products with same price as 10th product

SELECT TOP 10 WITH TIES
    ProductID,
    Name,
    ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;

/*
═══════════════════════════════════════════════════════════════════════════════
✅ COMPLETION CHECKLIST
═══════════════════════════════════════════════════════════════════════════════

□ Understand ASC vs DESC sorting
□ Can sort by multiple columns
□ Know when to use TOP vs OFFSET/FETCH
□ Can remove duplicates with DISTINCT
□ Understand WITH TIES behavior

Next Lab: lab_04_aggregates.sql
*/
