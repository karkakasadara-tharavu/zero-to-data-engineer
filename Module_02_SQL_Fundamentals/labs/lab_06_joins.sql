/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                          LAB 06: JOINS                                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE AdventureWorksLT2022;
GO

-- TASK 1: Customer Orders (⭐⭐ Medium)
-- INNER JOIN: Customers who placed orders
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
ORDER BY c.CustomerID, soh.OrderDate;


-- TASK 2: Customers WITHOUT Orders (⭐⭐⭐ Hard)
-- LEFT JOIN to find unmatched rows
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.EmailAddress
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE soh.SalesOrderID IS NULL;


-- TASK 3: Order Details with Product Info (⭐⭐⭐ Hard)
-- 3-table JOIN
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    p.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM SalesLT.SalesOrderHeader soh
INNER JOIN SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN SalesLT.Product p ON sod.ProductID = p.ProductID
ORDER BY soh.SalesOrderID, sod.SalesOrderDetailID;


-- TASK 4: Products Never Sold (⭐⭐⭐⭐ Hard)
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    pc.Name AS Category
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
WHERE sod.ProductID IS NULL
ORDER BY p.ListPrice DESC;


-- TASK 5: Complete Sales Report (⭐⭐⭐⭐⭐ Expert)
-- 4-table JOIN with customer, order, details, product
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    soh.SalesOrderID,
    soh.OrderDate,
    p.Name AS Product,
    pc.Name AS Category,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
INNER JOIN SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN SalesLT.Product p ON sod.ProductID = p.ProductID
INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
WHERE soh.OrderDate >= '2008-01-01'
ORDER BY soh.OrderDate DESC, c.CustomerID;


-- 💪 BONUS: Product Sales Summary (⭐⭐⭐⭐⭐)
SELECT 
    p.ProductID,
    p.Name,
    pc.Name AS Category,
    COUNT(sod.SalesOrderDetailID) AS TimesSold,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalRevenue
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
GROUP BY p.ProductID, p.Name, pc.Name
ORDER BY TotalRevenue DESC;

/* Next Lab: lab_07_subqueries.sql */
