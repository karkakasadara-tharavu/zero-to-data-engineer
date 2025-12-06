/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                          LAB 07: SUBQUERIES                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE AdventureWorksLT2022;
GO

-- TASK 1: Products Above Average Price (⭐⭐ Medium)
-- Scalar subquery
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
WHERE ListPrice > (SELECT AVG(ListPrice) FROM SalesLT.Product)
ORDER BY ListPrice DESC;


-- TASK 2: Customers Who Placed Orders (⭐⭐ Medium)
-- IN operator
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer
WHERE CustomerID IN (SELECT DISTINCT CustomerID FROM SalesLT.SalesOrderHeader);


-- TASK 3: Customers WITHOUT Orders (⭐⭐⭐ Hard)
-- NOT EXISTS (safer than NOT IN)
SELECT CustomerID, FirstName, LastName, EmailAddress
FROM SalesLT.Customer c
WHERE NOT EXISTS (
    SELECT 1 
    FROM SalesLT.SalesOrderHeader soh 
    WHERE soh.CustomerID = c.CustomerID
);


-- TASK 4: Products Above Category Average (⭐⭐⭐⭐ Hard)
-- Correlated subquery
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    pc.Name AS Category
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
WHERE p.ListPrice > (
    SELECT AVG(ListPrice)
    FROM SalesLT.Product p2
    WHERE p2.ProductCategoryID = p.ProductCategoryID
)
ORDER BY pc.Name, p.ListPrice DESC;


-- TASK 5: Top Spenders (Top 20%) (⭐⭐⭐⭐⭐ Expert)
SELECT 
    CustomerID,
    SUM(TotalDue) AS TotalSpent
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
HAVING SUM(TotalDue) >= (
    SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY CustomerTotal)
    FROM (
        SELECT CustomerID, SUM(TotalDue) AS CustomerTotal
        FROM SalesLT.SalesOrderHeader
        GROUP BY CustomerID
    ) AS Totals
)
ORDER BY TotalSpent DESC;


-- 💪 BONUS: Latest Order Per Customer (⭐⭐⭐⭐⭐)
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE soh.OrderDate = (
    SELECT MAX(OrderDate)
    FROM SalesLT.SalesOrderHeader soh2
    WHERE soh2.CustomerID = c.CustomerID
)
ORDER BY soh.OrderDate DESC;

/* Next Lab: lab_08_functions.sql */
