/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                    LAB 08: STRING & DATE FUNCTIONS                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE AdventureWorksLT2022;
GO

-- TASK 1: Email Analysis (⭐⭐ Medium)
SELECT 
    EmailAddress,
    LEFT(EmailAddress, CHARINDEX('@', EmailAddress) - 1) AS Username,
    SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, 100) AS Domain,
    LEN(EmailAddress) AS EmailLength,
    UPPER(EmailAddress) AS Uppercase
FROM SalesLT.Customer
WHERE EmailAddress IS NOT NULL;


-- TASK 2: Product Name Manipulation (⭐⭐ Medium)
SELECT 
    Name,
    UPPER(LEFT(Name, 1)) + LOWER(SUBSTRING(Name, 2, 100)) AS TitleCase,
    REPLACE(Name, 'Bike', 'Bicycle') AS ReplacedName,
    LEN(Name) AS NameLength,
    REVERSE(Name) AS ReversedName
FROM SalesLT.Product;


-- TASK 3: Date Analysis (⭐⭐⭐ Hard)
SELECT 
    SalesOrderID,
    OrderDate,
    YEAR(OrderDate) AS Year,
    DATENAME(MONTH, OrderDate) AS MonthName,
    DATENAME(WEEKDAY, OrderDate) AS DayName,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysSinceOrder,
    DATEADD(DAY, 30, OrderDate) AS EstimatedDelivery,
    FORMAT(OrderDate, 'MMMM dd, yyyy') AS FormattedDate
FROM SalesLT.SalesOrderHeader;


-- TASK 4: Customer Lifecycle (⭐⭐⭐⭐ Hard)
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    MIN(soh.OrderDate) AS FirstOrder,
    MAX(soh.OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(soh.OrderDate), MAX(soh.OrderDate)) AS LifespanDays,
    DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS DaysSinceLastOrder,
    CASE
        WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 365 THEN 'Inactive'
        WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 180 THEN 'At Risk'
        ELSE 'Active'
    END AS Status
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;


-- 💪 BONUS: Parse Product Number (⭐⭐⭐⭐⭐)
SELECT 
    ProductNumber,
    LEFT(ProductNumber, CHARINDEX('-', ProductNumber) - 1) AS Prefix,
    SUBSTRING(
        ProductNumber, 
        CHARINDEX('-', ProductNumber) + 1,
        CHARINDEX('-', ProductNumber, CHARINDEX('-', ProductNumber) + 1) - CHARINDEX('-', ProductNumber) - 1
    ) AS MiddleCode,
    RIGHT(ProductNumber, CHARINDEX('-', REVERSE(ProductNumber)) - 1) AS Suffix
FROM SalesLT.Product
WHERE ProductNumber LIKE '%-%-%';

/* Next Lab: lab_09_case.sql */
