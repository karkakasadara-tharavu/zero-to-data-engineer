/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                       LAB 09: CASE EXPRESSIONS                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE AdventureWorksLT2022;
GO

-- TASK 1: Simple CASE - Size Labels (⭐⭐ Medium)
SELECT 
    ProductID,
    Name,
    Size,
    CASE Size
        WHEN 'S' THEN 'Small'
        WHEN 'M' THEN 'Medium'
        WHEN 'L' THEN 'Large'
        WHEN 'XL' THEN 'Extra Large'
        ELSE 'Unknown'
    END AS SizeLabel
FROM SalesLT.Product
WHERE Size IS NOT NULL;


-- TASK 2: Price Categories (⭐⭐ Medium)
SELECT 
    ProductID,
    Name,
    ListPrice,
    CASE
        WHEN ListPrice < 100 THEN 'Budget'
        WHEN ListPrice < 500 THEN 'Mid-Range'
        WHEN ListPrice < 1000 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceCategory
FROM SalesLT.Product
ORDER BY ListPrice;


-- TASK 3: Customer Segmentation (⭐⭐⭐ Hard)
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    COUNT(soh.SalesOrderID) AS TotalOrders,
    SUM(soh.TotalDue) AS TotalSpent,
    CASE
        WHEN SUM(soh.TotalDue) > 10000 THEN 'VIP'
        WHEN SUM(soh.TotalDue) > 5000 THEN 'High Value'
        WHEN SUM(soh.TotalDue) > 1000 THEN 'Regular'
        ELSE 'Low Value'
    END AS CustomerTier
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;


-- TASK 4: Product Status (⭐⭐⭐⭐ Hard)
SELECT 
    ProductID,
    Name,
    ListPrice,
    StandardCost,
    SellStartDate,
    SellEndDate,
    CASE
        WHEN SellEndDate IS NOT NULL THEN 'Discontinued'
        WHEN SellStartDate > GETDATE() THEN 'Coming Soon'
        WHEN ListPrice = 0 THEN 'Free'
        ELSE 'Active'
    END AS ProductStatus,
    CASE
        WHEN StandardCost = 0 THEN 'N/A'
        WHEN (ListPrice - StandardCost) / StandardCost * 100 > 100 THEN 'High Margin'
        WHEN (ListPrice - StandardCost) / StandardCost * 100 > 50 THEN 'Good Margin'
        ELSE 'Low Margin'
    END AS MarginCategory
FROM SalesLT.Product;


-- TASK 5: Order Priority (⭐⭐⭐⭐ Hard)
SELECT 
    SalesOrderID,
    OrderDate,
    TotalDue,
    CASE
        WHEN TotalDue > 5000 THEN 'Express'
        WHEN TotalDue > 1000 AND DATEDIFF(DAY, OrderDate, GETDATE()) < 7 THEN 'Standard'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) > 30 THEN 'Completed'
        ELSE 'Economy'
    END AS ShippingPriority,
    IIF(TotalDue > 1000, 'High Value', 'Standard') AS OrderType
FROM SalesLT.SalesOrderHeader;


-- 💪 BONUS: Complex Engagement Score (⭐⭐⭐⭐⭐)
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    COUNT(soh.SalesOrderID) AS Orders,
    SUM(soh.TotalDue) AS TotalSpent,
    DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS DaysSinceLastOrder,
    CASE
        WHEN COUNT(soh.SalesOrderID) = 0 THEN 0
        WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 365 THEN 10
        WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 180 THEN 30
        WHEN COUNT(soh.SalesOrderID) >= 5 AND SUM(soh.TotalDue) > 5000 THEN 100
        WHEN COUNT(soh.SalesOrderID) >= 3 THEN 70
        ELSE 50
    END AS EngagementScore
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY EngagementScore DESC;

/* Next Lab: lab_10_project.sql */
