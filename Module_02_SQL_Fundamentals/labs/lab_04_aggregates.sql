/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                      LAB 04: AGGREGATE FUNCTIONS                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE AdventureWorksLT2022;
GO

-- TASK 1: Count Products (⭐ Easy)
SELECT COUNT(*) AS TotalProducts FROM SalesLT.Product;
SELECT COUNT(Color) AS ProductsWithColor FROM SalesLT.Product;
SELECT COUNT(DISTINCT Color) AS UniqueColors FROM SalesLT.Product;


-- TASK 2: Price Statistics (⭐⭐ Medium)
SELECT 
    MIN(ListPrice) AS MinPrice,
    MAX(ListPrice) AS MaxPrice,
    AVG(ListPrice) AS AvgPrice,
    SUM(ListPrice) AS TotalListValue
FROM SalesLT.Product;


-- TASK 3: Order Totals (⭐⭐ Medium)
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS TotalRevenue,
    AVG(TotalDue) AS AvgOrderValue,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder
FROM SalesLT.SalesOrderHeader;


-- TASK 4: Product Statistics by Category (⭐⭐⭐ Hard)
SELECT 
    pc.Name AS Category,
    COUNT(p.ProductID) AS ProductCount,
    AVG(p.ListPrice) AS AvgPrice,
    MIN(p.ListPrice) AS MinPrice,
    MAX(p.ListPrice) AS MaxPrice
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY ProductCount DESC;


-- TASK 5: Customer Order Statistics (⭐⭐⭐ Hard)
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSpent,
    AVG(TotalDue) AS AvgOrderValue,
    MIN(TotalDue) AS SmallestOrder,
    MAX(TotalDue) AS LargestOrder
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
ORDER BY TotalSpent DESC;


-- 💪 BONUS: Handle NULLs in Aggregates (⭐⭐⭐⭐)
SELECT 
    COUNT(*) AS AllProducts,
    COUNT(Color) AS WithColor,
    COUNT(Weight) AS WithWeight,
    AVG(Weight) AS AvgWeight,
    AVG(ISNULL(Weight, 0)) AS AvgWeightIncludingNulls
FROM SalesLT.Product;

/* Next Lab: lab_05_groupby.sql */
