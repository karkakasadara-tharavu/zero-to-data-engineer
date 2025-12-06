-- =============================================
-- Lab 01: SELECT Basics - SOLUTION
-- Module 02: SQL Fundamentals
-- =============================================

-- ⚠️ IMPORTANT: Only view this file AFTER attempting all tasks yourself!
-- Learning happens when you struggle and solve problems independently.

USE AdventureWorksLT2022;
GO

PRINT '========================================';
PRINT 'Lab 01: SELECT Basics - SOLUTIONS';
PRINT '========================================';
GO


-- =============================================
-- TASK 1 SOLUTION: Retrieve All Columns
-- =============================================

PRINT 'Task 1 Solution: All customer data';
GO

SELECT *
FROM SalesLT.Customer;
GO

-- Explanation:
-- - SELECT * retrieves ALL columns from the table
-- - Useful for quick exploration, but avoid in production queries
-- - AdventureWorksLT2022 Customer table has 847 rows


-- =============================================
-- TASK 2 SOLUTION: Select Specific Columns
-- =============================================

PRINT 'Task 2 Solution: Product ID, Name, and Price';
GO

SELECT 
    ProductID,
    Name,
    ListPrice
FROM SalesLT.Product;
GO

-- Explanation:
-- - Specify exact columns you need (better performance than SELECT *)
-- - Comma-separated list of column names
-- - Columns appear in results in the order you specify
-- - 295 products in AdventureWorksLT2022


-- =============================================
-- TASK 3 SOLUTION: Column Aliases
-- =============================================

PRINT 'Task 3 Solution: Customer names with aliases';
GO

-- Method 1: Using + operator (fails if MiddleName is NULL)
SELECT 
    CustomerID AS 'Customer ID',
    FirstName + ' ' + LastName AS 'Full Name',
    EmailAddress AS 'Email'
FROM SalesLT.Customer;
GO

-- Method 2: Using CONCAT (recommended - handles NULLs)
SELECT 
    CustomerID AS 'Customer ID',
    CONCAT(FirstName, ' ', LastName) AS 'Full Name',
    EmailAddress AS 'Email'
FROM SalesLT.Customer;
GO

-- Explanation:
-- - AS keyword creates column aliases (custom headers)
-- - Use single quotes 'Alias Name' for aliases with spaces
-- - CONCAT() is safer than + for string concatenation (handles NULL)
-- - Both methods shown for learning, but CONCAT is preferred


-- =============================================
-- TASK 4 SOLUTION: Arithmetic Calculations
-- =============================================

PRINT 'Task 4 Solution: Product profit analysis';
GO

SELECT 
    ProductID,
    Name,
    StandardCost,
    ListPrice,
    ListPrice - StandardCost AS Profit,
    (ListPrice - StandardCost) / ListPrice * 100 AS ProfitPercentage
FROM SalesLT.Product;
GO

-- Explanation:
-- - Arithmetic operators: + - * / %
-- - Order of operations: () first, then * /, then + -
-- - Profit = Revenue - Cost (basic business metric)
-- - Profit % = (Profit / Revenue) * 100
-- - Parentheses ensure correct calculation order


-- =============================================
-- TASK 5 SOLUTION: String Concatenation
-- =============================================

PRINT 'Task 5 Solution: Product labels';
GO

-- Method 1: Using CONCAT (recommended - handles NULL colors)
SELECT 
    ProductID,
    CONCAT(Name, ' - ', ISNULL(Color, 'No Color'), ' - $', ListPrice) AS ProductLabel
FROM SalesLT.Product;
GO

-- Method 2: Using CASE to handle NULL colors (more explicit)
SELECT 
    ProductID,
    CASE 
        WHEN Color IS NULL THEN CONCAT(Name, ' - No Color - $', ListPrice)
        ELSE CONCAT(Name, ' - ', Color, ' - $', ListPrice)
    END AS ProductLabel
FROM SalesLT.Product;
GO

-- Method 3: Using COALESCE (concise NULL handling)
SELECT 
    ProductID,
    CONCAT(Name, ' - ', COALESCE(Color, 'No Color'), ' - $', ListPrice) AS ProductLabel
FROM SalesLT.Product;
GO

-- Explanation:
-- - CONCAT() automatically converts numbers to strings
-- - ISNULL(Color, 'No Color') replaces NULL with default value
-- - COALESCE() returns first non-NULL value (similar to ISNULL)
-- - CASE provides most control but is more verbose
-- - All three methods are valid; choose based on preference


-- =============================================
-- TASK 6 SOLUTION: Date and Calculation
-- =============================================

PRINT 'Task 6 Solution: Order information with tax';
GO

SELECT 
    OrderDate AS 'Order Date',
    TotalDue AS 'Total Amount',
    TotalDue * 0.065 AS 'Estimated Sales Tax'
FROM SalesLT.SalesOrderHeader;
GO

-- Explanation:
-- - SalesOrderHeader table contains order summary data
-- - OrderDate is a DATETIME column
-- - TotalDue is MONEY datatype
-- - 0.065 = 6.5% sales tax rate
-- - Multiply TotalDue by tax rate to calculate tax amount
-- - 32 sales orders in AdventureWorksLT2022


-- =============================================
-- TASK 7 SOLUTION: Complex String Concatenation
-- =============================================

PRINT 'Task 7 Solution: Customer greeting messages';
GO

-- Method 1: Using CONCAT (recommended)
SELECT 
    CustomerID,
    CONCAT('Dear ', FirstName, ' ', LastName, ', your email is ', EmailAddress) AS GreetingMessage
FROM SalesLT.Customer;
GO

-- Method 2: Using + operator (works if no NULLs)
SELECT 
    CustomerID,
    'Dear ' + FirstName + ' ' + LastName + ', your email is ' + EmailAddress AS GreetingMessage
FROM SalesLT.Customer;
GO

-- Explanation:
-- - CONCAT() automatically handles multiple strings and spaces
-- - Order matters: strings appear in result exactly as specified
-- - Punctuation (comma, period) included as literals
-- - EmailAddress should never be NULL in this table (business rule)


-- =============================================
-- BONUS CHALLENGE SOLUTION
-- =============================================

PRINT 'BONUS Solution: Comprehensive product summary';
GO

SELECT 
    ProductNumber AS SKU,
    Name AS Product,
    CONCAT('Color: ', COALESCE(Color, 'N/A'), ' | Price: $', 
           CAST(ListPrice AS DECIMAL(10,2))) AS Details,
    ListPrice - StandardCost AS Markup,
    CASE 
        WHEN StandardCost = 0 THEN 0  -- Prevent division by zero
        ELSE ((ListPrice - StandardCost) / StandardCost) * 100 
    END AS 'Markup %'
FROM SalesLT.Product;
GO

-- Alternative with ROUND for cleaner decimals
SELECT 
    ProductNumber AS SKU,
    Name AS Product,
    CONCAT('Color: ', COALESCE(Color, 'N/A'), ' | Price: $', 
           CAST(ListPrice AS DECIMAL(10,2))) AS Details,
    ROUND(ListPrice - StandardCost, 2) AS Markup,
    CASE 
        WHEN StandardCost = 0 THEN 0
        ELSE ROUND(((ListPrice - StandardCost) / StandardCost) * 100, 2)
    END AS 'Markup %'
FROM SalesLT.Product;
GO

-- Explanation:
-- - CAST(ListPrice AS DECIMAL(10,2)) formats price to 2 decimal places
-- - COALESCE(Color, 'N/A') handles NULL colors
-- - CASE prevents division by zero (if StandardCost = 0)
-- - ROUND() function limits decimal places for readability
-- - Markup % = ((Selling Price - Cost) / Cost) * 100
-- - This is ROI (Return on Investment) calculation


-- =============================================
-- KEY LEARNING POINTS
-- =============================================

PRINT '';
PRINT '========================================';
PRINT 'KEY TAKEAWAYS FROM LAB 01';
PRINT '========================================';
PRINT '';
PRINT '✅ SELECT * vs. specific columns';
PRINT '   - Use SELECT * for exploration only';
PRINT '   - Specify columns in production queries';
PRINT '';
PRINT '✅ Column aliases make results readable';
PRINT '   - Always use AS keyword for clarity';
PRINT '   - Use quotes for aliases with spaces';
PRINT '';
PRINT '✅ Arithmetic in SELECT statements';
PRINT '   - Use +, -, *, /, % operators';
PRINT '   - Parentheses control order of operations';
PRINT '';
PRINT '✅ String concatenation methods';
PRINT '   - CONCAT() handles NULLs gracefully (preferred)';
PRINT '   - + operator fails if any value is NULL';
PRINT '   - COALESCE() or ISNULL() provide default values';
PRINT '';
PRINT '✅ NULL handling is critical';
PRINT '   - Always consider NULL values in calculations';
PRINT '   - Use ISNULL(), COALESCE(), or CASE';
PRINT '';
PRINT '========================================';
PRINT 'Ready for Section 02: Filtering Data!';
PRINT '========================================';
PRINT '';
GO


-- =============================================
-- COMMON MISTAKES TO AVOID
-- =============================================

/*
MISTAKE 1: Using + for string concatenation without NULL handling

❌ BAD:
SELECT FirstName + ' ' + MiddleName + ' ' + LastName
FROM Customer;
-- Result: NULL if MiddleName is NULL!

✅ GOOD:
SELECT CONCAT(FirstName, ' ', MiddleName, ' ', LastName)
FROM Customer;
-- Result: "John  Doe" (extra space, but no NULL)

✅ BETTER:
SELECT CONCAT(FirstName, ' ', COALESCE(MiddleName + ' ', ''), LastName)
FROM Customer;
-- Result: "John Doe" (no extra space)


MISTAKE 2: Forgetting aliases for calculated columns

❌ BAD:
SELECT ListPrice - StandardCost
FROM Product;
-- Column header: (No column name)

✅ GOOD:
SELECT ListPrice - StandardCost AS Profit
FROM Product;
-- Column header: Profit


MISTAKE 3: Not using schema names

❌ BAD:
SELECT * FROM Customer;
-- Fails if multiple schemas have Customer table

✅ GOOD:
SELECT * FROM SalesLT.Customer;
-- Explicit schema avoids ambiguity


MISTAKE 4: Using SELECT * in production

❌ BAD:
SELECT * FROM Product;  -- In ETL or reporting query
-- Problems: Retrieves unnecessary data, breaks if columns added

✅ GOOD:
SELECT ProductID, Name, ListPrice FROM Product;
-- Explicit columns, better performance, stable code


MISTAKE 5: Division by zero

❌ BAD:
SELECT ListPrice / StandardCost FROM Product;
-- Fails if StandardCost = 0

✅ GOOD:
SELECT 
    CASE 
        WHEN StandardCost = 0 THEN NULL
        ELSE ListPrice / StandardCost 
    END AS PriceRatio
FROM Product;
-- Handles zero gracefully

*/


-- =============================================
-- END OF SOLUTION FILE
-- =============================================

-- Remember: The goal isn't to memorize solutions, but to UNDERSTAND the logic.
-- Try variations of these queries on your own!
-- 
-- Next: Section 02 - Filtering Data (WHERE clause)
-- 
-- கற்க கசடற - Learn Flawlessly, Grow Together!
