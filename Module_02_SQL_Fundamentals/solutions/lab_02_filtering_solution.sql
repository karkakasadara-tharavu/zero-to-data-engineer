/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                LAB 02 SOLUTION: FILTERING DATA                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

⚠️ IMPORTANT: Attempt the lab yourself before viewing these solutions!
This file shows multiple approaches where applicable.
*/

USE AdventureWorksLT2022;
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- TASK 1 SOLUTION: Products Under $200
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    ProductID, 
    Name, 
    ListPrice
FROM SalesLT.Product
WHERE ListPrice < 200
ORDER BY ListPrice ASC;

-- 💡 Why this works:
-- - Simple comparison operator (<)
-- - ORDER BY ensures cheapest products shown first
-- - ASC is optional (default), but explicit is clearer

-- 📊 Expected: ~100+ products ranging from $0 to $199.99


-- ═══════════════════════════════════════════════════════════════════════════
-- TASK 2 SOLUTION: Search Customers by Email Pattern
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    CustomerID, 
    FirstName, 
    LastName, 
    EmailAddress
FROM SalesLT.Customer
WHERE EmailAddress LIKE '%adventure%'
ORDER BY LastName;

-- 💡 Why this works:
-- - LIKE with % wildcard matches "adventure" anywhere in email
-- - % before and after means "any characters + adventure + any characters"
-- - SQL Server LIKE is case-insensitive by default

-- 📊 Expected: Multiple customers with "adventure" in email


-- ═══════════════════════════════════════════════════════════════════════════
-- TASK 3 SOLUTION: Orders in Date Range
-- ═══════════════════════════════════════════════════════════════════════════

-- METHOD 1: Using BETWEEN (recommended - cleaner)
SELECT 
    SalesOrderID, 
    OrderDate, 
    CustomerID, 
    TotalDue
FROM SalesLT.SalesOrderHeader
WHERE OrderDate BETWEEN '2008-06-01' AND '2008-06-30'
ORDER BY OrderDate;

-- METHOD 2: Using >= AND <=
SELECT 
    SalesOrderID, 
    OrderDate, 
    CustomerID, 
    TotalDue
FROM SalesLT.SalesOrderHeader
WHERE OrderDate >= '2008-06-01' AND OrderDate <= '2008-06-30'
ORDER BY OrderDate;

-- METHOD 3: Using >= AND < (for precision with datetime)
SELECT 
    SalesOrderID, 
    OrderDate, 
    CustomerID, 
    TotalDue
FROM SalesLT.SalesOrderHeader
WHERE OrderDate >= '2008-06-01' AND OrderDate < '2008-07-01'
ORDER BY OrderDate;

-- 💡 Which to use?
-- - BETWEEN: Most readable for date ranges
-- - Method 3: Best if dealing with datetime (not just date) to avoid missing records

-- 📊 Expected: All June 2008 orders


-- ═══════════════════════════════════════════════════════════════════════════
-- TASK 4 SOLUTION: Multiple Color Filter
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    ProductID, 
    Name, 
    Color, 
    ListPrice
FROM SalesLT.Product
WHERE Color IN ('Red', 'Black', 'Silver')
ORDER BY Color, ListPrice DESC;

-- Alternative (verbose, not recommended):
SELECT 
    ProductID, 
    Name, 
    Color, 
    ListPrice
FROM SalesLT.Product
WHERE Color = 'Red' OR Color = 'Black' OR Color = 'Silver'
ORDER BY Color, ListPrice DESC;

-- 💡 Why IN is better:
-- - More concise
-- - Easier to read
-- - Easier to maintain (add/remove values)

-- 📊 Expected: ~150+ products sorted by Color, then Price (high to low within each color)


-- ═══════════════════════════════════════════════════════════════════════════
-- TASK 5 SOLUTION: Product Name Pattern Search
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    ProductID, 
    Name, 
    ProductCategoryID, 
    ListPrice
FROM SalesLT.Product
WHERE Name LIKE 'Mountain%'
  AND ListPrice > 500
  AND SellEndDate IS NULL
ORDER BY ListPrice DESC;

-- 💡 Key points:
-- - LIKE 'Mountain%' matches names STARTING with "Mountain"
-- - Multiple AND conditions must all be true
-- - IS NULL checks for NULL (not = NULL)
-- - No parentheses needed here (all AND)

-- 📊 Expected: High-end mountain products still being sold


-- ═══════════════════════════════════════════════════════════════════════════
-- TASK 6 SOLUTION: Products with Missing Data
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    ProductID, 
    Name, 
    Color, 
    Size, 
    ListPrice
FROM SalesLT.Product
WHERE Color IS NULL OR Size IS NULL
ORDER BY ListPrice DESC;

-- 💡 Key points:
-- - IS NULL (not = NULL)
-- - OR means "either condition (or both) is true"
-- - Useful for data quality checks

-- 📊 Expected: Products missing color or size specification


-- ═══════════════════════════════════════════════════════════════════════════
-- TASK 7 SOLUTION: Complex Business Filter
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    ProductID, 
    Name, 
    Color, 
    Size, 
    ListPrice, 
    StandardCost,
    ListPrice - StandardCost AS Profit
FROM SalesLT.Product
WHERE (Color = 'Red' OR Color = 'Black')
  AND ListPrice >= 1000
  AND StandardCost > 0
  AND ProductNumber LIKE 'BK-%'
  AND SellEndDate IS NULL
ORDER BY Profit DESC;

-- 💡 Critical detail: Parentheses around OR conditions!
-- Without parentheses:
-- ❌ WHERE Color = 'Red' OR Color = 'Black' AND ListPrice >= 1000
-- This evaluates as: (Red) OR (Black AND Price>=1000)
-- Meaning: ALL red products + ONLY black products over $1000

-- ✅ WITH parentheses:
-- WHERE (Color = 'Red' OR Color = 'Black') AND ListPrice >= 1000
-- Meaning: (Red OR Black) AND all other conditions

-- 📊 Expected: Premium red or black bikes currently for sale


-- ═══════════════════════════════════════════════════════════════════════════
-- BONUS SOLUTION: Customer Search
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    CustomerID, 
    Title, 
    FirstName, 
    LastName, 
    CompanyName, 
    EmailAddress
FROM SalesLT.Customer
WHERE LastName LIKE '[ABC]%'  -- Starts with A, B, or C
  AND SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, 100) <> 'example.com'
  AND CompanyName IS NOT NULL
  AND Title IS NOT NULL
ORDER BY LastName, FirstName;

-- 💡 Breaking down the email domain check:
-- 1. CHARINDEX('@', EmailAddress) finds position of @
-- 2. + 1 starts after the @
-- 3. SUBSTRING extracts everything after @ (domain)
-- 4. <> checks it's NOT 'example.com'

-- Alternative: Using LIKE
SELECT 
    CustomerID, 
    Title, 
    FirstName, 
    LastName, 
    CompanyName, 
    EmailAddress
FROM SalesLT.Customer
WHERE LastName LIKE '[ABC]%'
  AND EmailAddress NOT LIKE '%@example.com'
  AND CompanyName IS NOT NULL
  AND Title IS NOT NULL
ORDER BY LastName, FirstName;

-- 💡 Which is better?
-- - LIKE NOT: Simpler, easier to read
-- - SUBSTRING: More precise (doesn't match "example.com" in username)


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ COMMON MISTAKES TO AVOID                                                     ║
╚══════════════════════════════════════════════════════════════════════════════╝

1. ❌ Using = NULL instead of IS NULL
   WHERE Color = NULL     -- WRONG (always returns 0 rows)
   WHERE Color IS NULL    -- CORRECT

2. ❌ Forgetting parentheses with OR + AND
   WHERE Color = 'Red' OR Color = 'Black' AND Price > 1000  -- WRONG
   WHERE (Color = 'Red' OR Color = 'Black') AND Price > 1000  -- CORRECT

3. ❌ Case-sensitive wildcards (SQL Server is case-insensitive by default)
   WHERE Name LIKE 'mountain%'  -- Still matches "Mountain"

4. ❌ Not using schema names
   WHERE Name LIKE '%Bike%'           -- Ambiguous if multiple tables
   WHERE SalesLT.Product.Name LIKE '%Bike%'  -- Clear

5. ❌ Inefficient OR chains when IN works
   WHERE Color = 'Red' OR Color = 'Black' OR Color = 'Silver'  -- Verbose
   WHERE Color IN ('Red', 'Black', 'Silver')  -- Clean

═══════════════════════════════════════════════════════════════════════════════
🎓 KEY TAKEAWAYS
═══════════════════════════════════════════════════════════════════════════════

✅ WHERE filters rows BEFORE they're returned
✅ Use IN for multiple OR conditions on same column
✅ BETWEEN is inclusive (includes both boundaries)
✅ LIKE with % matches any characters
✅ IS NULL / IS NOT NULL for NULL checks
✅ Use parentheses to control AND/OR evaluation order
✅ String comparisons are case-insensitive in SQL Server by default

═══════════════════════════════════════════════════════════════════════════════
*/
