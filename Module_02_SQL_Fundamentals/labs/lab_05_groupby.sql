/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                        LAB 05: GROUP BY & HAVING                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE AdventureWorksLT2022;
GO

-- TASK 1: Product Count by Color (⭐⭐ Medium)
SELECT 
    Color,
    COUNT(*) AS ProductCount
FROM SalesLT.Product
WHERE Color IS NOT NULL
GROUP BY Color
ORDER BY ProductCount DESC;


-- TASK 2: Customers with Multiple Orders (⭐⭐⭐ Hard)
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSpent
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY OrderCount DESC;


-- TASK 3: Monthly Sales Summary (⭐⭐⭐ Hard)
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    DATENAME(MONTH, OrderDate) AS MonthName,
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS MonthlyRevenue,
    AVG(TotalDue) AS AvgOrderValue
FROM SalesLT.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY Year, Month;


-- TASK 4: High-Value Products by Category (⭐⭐⭐⭐ Hard)
SELECT 
    pc.Name AS Category,
    COUNT(p.ProductID) AS ProductCount,
    AVG(p.ListPrice) AS AvgPrice
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
HAVING AVG(p.ListPrice) > 500  -- Only categories with avg price > $500
ORDER BY AvgPrice DESC;


-- TASK 5: Customer Segmentation (⭐⭐⭐⭐ Hard)
SELECT 
    CASE
        WHEN SUM(TotalDue) > 10000 THEN 'VIP'
        WHEN SUM(TotalDue) > 5000 THEN 'High Value'
        WHEN SUM(TotalDue) > 1000 THEN 'Regular'
        ELSE 'Low Value'
    END AS Segment,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    AVG(SUM(TotalDue)) AS AvgLifetimeValue
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
ORDER BY Segment;


-- 💪 BONUS: ROLLUP for Subtotals (⭐⭐⭐⭐⭐)
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalDue) AS Revenue
FROM SalesLT.SalesOrderHeader
GROUP BY ROLLUP(YEAR(OrderDate), MONTH(OrderDate))
ORDER BY Year, Month;

/* Next Lab: lab_06_joins.sql */
