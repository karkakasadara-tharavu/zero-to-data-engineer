/*
================================================================================
LAB 09 (ENHANCED): SUBQUERIES - COMPLETE GUIDE
Module 02: SQL Fundamentals
================================================================================

WHAT YOU WILL LEARN:
✅ What subqueries are and when to use them
✅ Types of subqueries (scalar, row, table)
✅ Correlated vs non-correlated subqueries
✅ Subqueries in SELECT, FROM, WHERE clauses
✅ EXISTS and NOT EXISTS
✅ Comparison operators with subqueries (ANY, ALL, IN)
✅ When to use subqueries vs JOINs
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐ (Intermediate)
DATABASE: AdventureWorks2022

================================================================================
SECTION 1: WHAT IS A SUBQUERY?
================================================================================

DEFINITION:
-----------
A subquery is a query INSIDE another query. Also called:
- Nested query
- Inner query
- Sub-select

STRUCTURE:
----------
┌─────────────────────────────────────────────────────────────┐
│ OUTER QUERY (Main Query)                                    │
│                                                             │
│   SELECT columns                                            │
│   FROM table                                                │
│   WHERE column = ┌───────────────────────────────────────┐  │
│                  │ SUBQUERY (Inner Query)                │  │
│                  │                                       │  │
│                  │   SELECT column                       │  │
│                  │   FROM table                          │  │
│                  │   WHERE condition                     │  │
│                  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

The subquery executes FIRST, then its result is used by the outer query.

TYPES OF SUBQUERIES:
--------------------
1. SCALAR Subquery - Returns single value (1 row, 1 column)
2. ROW Subquery    - Returns single row (1 row, multiple columns)
3. TABLE Subquery  - Returns multiple rows and columns
*/

USE AdventureWorks2022;
GO

-- ============================================================================
-- SECTION 2: SCALAR SUBQUERIES (Single Value)
-- ============================================================================
/*
SCALAR SUBQUERY:
- Returns exactly ONE value (1 row, 1 column)
- Can be used anywhere a single value is expected
- If returns more than 1 row: ERROR!
- If returns 0 rows: NULL
*/

-- EXAMPLE 1: Find employees who earn more than average salary
-- The subquery calculates the average, outer query uses it
SELECT 
    BusinessEntityID,
    JobTitle,
    Rate
FROM HumanResources.EmployeePayHistory
WHERE Rate > (SELECT AVG(Rate) FROM HumanResources.EmployeePayHistory);

/*
BREAKDOWN:
1. Subquery runs: SELECT AVG(Rate) FROM ... → Returns single value: 18.42
2. Outer query becomes: WHERE Rate > 18.42
3. Results show employees earning above average
*/

-- EXAMPLE 2: Scalar subquery in SELECT clause
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    (SELECT AVG(ListPrice) FROM Production.Product) AS AvgPrice,
    p.ListPrice - (SELECT AVG(ListPrice) FROM Production.Product) AS DiffFromAvg
FROM Production.Product p
WHERE p.ListPrice > 0;

/*
VISUAL:
┌───────────────┐   ┌─────────────────────────────────┐
│ Outer Query   │   │ Scalar Subquery                 │
│               │   │                                 │
│ ProductID     │   │ SELECT AVG(ListPrice)           │
│ Name          │   │ FROM Production.Product         │
│ ListPrice     │   │                                 │
│ [AvgPrice] ←──┼───┤ Returns: 438.67                 │
│               │   │                                 │
└───────────────┘   └─────────────────────────────────┘
*/

-- EXAMPLE 3: Subquery returning MAX value
SELECT 
    ProductID,
    Name,
    ListPrice
FROM Production.Product
WHERE ListPrice = (SELECT MAX(ListPrice) FROM Production.Product);
-- Returns the most expensive product

-- ============================================================================
-- SECTION 3: ROW SUBQUERIES (Single Row, Multiple Columns)
-- ============================================================================
/*
ROW SUBQUERY:
- Returns single row with multiple columns
- Used with row comparisons
- Less common in SQL Server (more common in MySQL, PostgreSQL)
*/

-- SQL Server doesn't support row comparisons directly like:
-- WHERE (col1, col2) = (SELECT a, b FROM ...)
-- Instead, we use multiple conditions or IN with concatenation

-- EXAMPLE: Find orders with matching customer and employee
-- (Alternative approach for row comparison)
SELECT *
FROM Sales.SalesOrderHeader
WHERE CustomerID = (SELECT TOP 1 CustomerID FROM Sales.SalesOrderHeader ORDER BY TotalDue DESC)
  AND SalesPersonID = (SELECT TOP 1 SalesPersonID FROM Sales.SalesOrderHeader ORDER BY TotalDue DESC);

-- ============================================================================
-- SECTION 4: TABLE SUBQUERIES (Multiple Rows)
-- ============================================================================
/*
TABLE SUBQUERY (Derived Table):
- Returns multiple rows and columns
- Used with IN, ANY, ALL, EXISTS
- Can be used in FROM clause (as derived table)
*/

-- EXAMPLE 1: IN with subquery - Products in specific categories
SELECT 
    ProductID,
    Name,
    ProductSubcategoryID
FROM Production.Product
WHERE ProductSubcategoryID IN (
    SELECT ProductSubcategoryID 
    FROM Production.ProductSubcategory 
    WHERE Name LIKE '%Bike%'
);

/*
BREAKDOWN:
1. Subquery finds all subcategory IDs with 'Bike' in name
   Returns: (1, 2, 3) for example
2. Outer query becomes: WHERE ProductSubcategoryID IN (1, 2, 3)
3. Products in bike subcategories returned
*/

-- EXAMPLE 2: NOT IN - Products that have never been ordered
SELECT 
    ProductID,
    Name
FROM Production.Product
WHERE ProductID NOT IN (
    SELECT DISTINCT ProductID 
    FROM Sales.SalesOrderDetail
    WHERE ProductID IS NOT NULL  -- Important! NULLs cause issues with NOT IN
);

/*
WARNING: NULL Values with NOT IN
--------------------------------
If subquery returns any NULL values:
- IN works correctly
- NOT IN returns EMPTY SET! (All comparisons become UNKNOWN)

ALWAYS add WHERE column IS NOT NULL when using NOT IN!
*/

-- EXAMPLE 3: Subquery in FROM clause (Derived Table)
SELECT 
    CategorySummary.SubcategoryName,
    CategorySummary.TotalProducts,
    CategorySummary.AvgPrice
FROM (
    SELECT 
        ps.Name AS SubcategoryName,
        COUNT(*) AS TotalProducts,
        AVG(p.ListPrice) AS AvgPrice
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    GROUP BY ps.Name
    HAVING AVG(p.ListPrice) > 100
) AS CategorySummary
ORDER BY CategorySummary.AvgPrice DESC;

/*
DERIVED TABLE:
The inner query creates a temporary result set (CategorySummary)
that the outer query treats like a regular table.

Important: Derived tables MUST have an alias!
*/

-- ============================================================================
-- SECTION 5: CORRELATED SUBQUERIES
-- ============================================================================
/*
NON-CORRELATED vs CORRELATED SUBQUERIES:

NON-CORRELATED:
- Subquery is INDEPENDENT of outer query
- Runs ONCE, result used for all outer rows
- More efficient

CORRELATED:
- Subquery REFERENCES columns from outer query
- Runs ONCE FOR EACH ROW of outer query
- Can be slow for large datasets
- Think of it as a loop!

VISUAL - Correlated Subquery:
┌─────────────────────────────────────────────────────────────┐
│ FOR EACH row in outer query:                                │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ Run subquery using outer row's values                │   │
│   │ Compare result with outer row                        │   │
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
*/

-- EXAMPLE 1: Find products above their category's average price
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    p.ProductSubcategoryID
FROM Production.Product p
WHERE p.ListPrice > (
    SELECT AVG(p2.ListPrice)
    FROM Production.Product p2
    WHERE p2.ProductSubcategoryID = p.ProductSubcategoryID  -- CORRELATION!
);

/*
BREAKDOWN:
For EACH product in outer query:
1. Take its ProductSubcategoryID
2. Calculate average price for THAT specific subcategory
3. Compare product's price with its category average
4. If higher, include in results

This runs the subquery ONCE PER PRODUCT - can be slow!
*/

-- EXAMPLE 2: Find customers with at least 10 orders
SELECT 
    c.CustomerID,
    c.PersonID
FROM Sales.Customer c
WHERE (
    SELECT COUNT(*)
    FROM Sales.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID  -- CORRELATION!
) >= 10;

-- EXAMPLE 3: Find the most recent order per customer
SELECT 
    soh1.SalesOrderID,
    soh1.CustomerID,
    soh1.OrderDate,
    soh1.TotalDue
FROM Sales.SalesOrderHeader soh1
WHERE soh1.OrderDate = (
    SELECT MAX(soh2.OrderDate)
    FROM Sales.SalesOrderHeader soh2
    WHERE soh2.CustomerID = soh1.CustomerID  -- CORRELATION!
);

-- ============================================================================
-- SECTION 6: EXISTS AND NOT EXISTS
-- ============================================================================
/*
EXISTS:
- Returns TRUE if subquery returns ANY rows
- Returns FALSE if subquery returns NO rows
- Very efficient - stops as soon as first match found
- Best for "does any matching row exist?" questions

NOT EXISTS:
- Returns TRUE if subquery returns NO rows
- Returns FALSE if subquery returns ANY rows
- Better than NOT IN (handles NULLs correctly!)

SELECT * in EXISTS:
Since EXISTS only checks for existence (not values),
SELECT * is fine and commonly used.
*/

-- EXAMPLE 1: Find customers who have placed orders
SELECT 
    c.CustomerID,
    c.PersonID
FROM Sales.Customer c
WHERE EXISTS (
    SELECT 1  -- or SELECT * - doesn't matter for EXISTS
    FROM Sales.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID
);

-- EXAMPLE 2: Find customers who have NEVER placed orders
SELECT 
    c.CustomerID,
    c.PersonID
FROM Sales.Customer c
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID
);

-- EXAMPLE 3: Find products that have been ordered at least once
SELECT 
    p.ProductID,
    p.Name
FROM Production.Product p
WHERE EXISTS (
    SELECT 1
    FROM Sales.SalesOrderDetail sod
    WHERE sod.ProductID = p.ProductID
);

/*
EXISTS vs IN Performance:
-------------------------
EXISTS is usually faster when:
- Subquery returns large result set
- Outer table is small

IN is usually faster when:
- Subquery returns small result set
- Outer table is large

When in doubt: EXISTS is generally safer and often faster
because it stops at first match.
*/

-- ============================================================================
-- SECTION 7: ANY, SOME, AND ALL
-- ============================================================================
/*
ANY (or SOME - they're identical):
- TRUE if comparison is true for AT LEAST ONE value from subquery
- = ANY is same as IN
- > ANY means greater than the MINIMUM

ALL:
- TRUE if comparison is true for ALL values from subquery
- > ALL means greater than the MAXIMUM
- Returns TRUE for empty set
*/

-- EXAMPLE 1: Products with price greater than ANY bike price
-- (greater than the cheapest bike)
SELECT Name, ListPrice
FROM Production.Product
WHERE ListPrice > ANY (
    SELECT ListPrice 
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    WHERE ps.Name = 'Mountain Bikes'
);

-- EXAMPLE 2: Products more expensive than ALL bikes
-- (more expensive than the most expensive bike)
SELECT Name, ListPrice
FROM Production.Product
WHERE ListPrice > ALL (
    SELECT ListPrice 
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    WHERE ps.Name = 'Mountain Bikes'
);

/*
COMPARISON TABLE:
┌────────────────────┬─────────────────────────────────────┐
│ Expression         │ Equivalent To                       │
├────────────────────┼─────────────────────────────────────┤
│ = ANY (subquery)   │ IN (subquery)                       │
│ <> ALL (subquery)  │ NOT IN (subquery)                   │
│ > ANY (subquery)   │ > MIN(subquery)                     │
│ > ALL (subquery)   │ > MAX(subquery)                     │
│ < ANY (subquery)   │ < MAX(subquery)                     │
│ < ALL (subquery)   │ < MIN(subquery)                     │
└────────────────────┴─────────────────────────────────────┘
*/

-- ============================================================================
-- SECTION 8: SUBQUERY VS JOIN
-- ============================================================================
/*
WHEN TO USE SUBQUERY:
--------------------
✓ When you need a single calculated value
✓ When checking for existence (EXISTS/NOT EXISTS)
✓ When using IN with a list of values
✓ When the logic is clearer as a subquery
✓ For filtering based on aggregate calculations

WHEN TO USE JOIN:
-----------------
✓ When you need columns from multiple tables in output
✓ When retrieving large datasets
✓ Usually better performance for data retrieval
✓ More intuitive for combining related data
*/

-- SAME RESULT - Different Approaches

-- Approach 1: Using Subquery (IN)
SELECT ProductID, Name, ProductSubcategoryID
FROM Production.Product
WHERE ProductSubcategoryID IN (
    SELECT ProductSubcategoryID 
    FROM Production.ProductSubcategory 
    WHERE Name = 'Road Bikes'
);

-- Approach 2: Using JOIN
SELECT p.ProductID, p.Name, p.ProductSubcategoryID
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
WHERE ps.Name = 'Road Bikes';

/*
DIFFERENCE:
- Subquery: Only products table columns in output
- JOIN: Can include columns from both tables
- JOIN is typically preferred when you need data from both tables
*/

-- ============================================================================
-- SECTION 9: COMMON SUBQUERY PATTERNS
-- ============================================================================

-- PATTERN 1: Find Top N per group (using correlated subquery)
SELECT 
    p.ProductID,
    p.Name,
    p.ProductSubcategoryID,
    p.ListPrice
FROM Production.Product p
WHERE (
    SELECT COUNT(*)
    FROM Production.Product p2
    WHERE p2.ProductSubcategoryID = p.ProductSubcategoryID
      AND p2.ListPrice >= p.ListPrice
) <= 3
ORDER BY p.ProductSubcategoryID, p.ListPrice DESC;
-- Top 3 most expensive products in each subcategory

-- PATTERN 2: Find duplicate records
SELECT *
FROM Production.Product p1
WHERE EXISTS (
    SELECT 1
    FROM Production.Product p2
    WHERE p2.Name = p1.Name
      AND p2.ProductID <> p1.ProductID  -- Different record, same name
);

-- PATTERN 3: Find records with no match in another table
SELECT 
    p.ProductID,
    p.Name
FROM Production.Product p
WHERE NOT EXISTS (
    SELECT 1 
    FROM Sales.SalesOrderDetail sod 
    WHERE sod.ProductID = p.ProductID
);

-- PATTERN 4: Compare each row to group statistics
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    sub.AvgPrice,
    sub.MaxPrice,
    CASE 
        WHEN p.ListPrice > sub.AvgPrice THEN 'Above Average'
        WHEN p.ListPrice < sub.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory
FROM Production.Product p
CROSS JOIN (
    SELECT 
        AVG(ListPrice) AS AvgPrice,
        MAX(ListPrice) AS MaxPrice
    FROM Production.Product
    WHERE ListPrice > 0
) AS sub
WHERE p.ListPrice > 0;

-- ============================================================================
-- SECTION 10: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: SUBQUERIES
================================================================================

Q1: What is a subquery?
A1: A subquery is a query nested inside another query. It executes first,
    and its result is used by the outer query. Also called nested query
    or inner query.

Q2: What are the types of subqueries?
A2: 
    - Scalar: Returns single value (1 row, 1 column)
    - Row: Returns single row with multiple columns
    - Table: Returns multiple rows and columns (used with IN, EXISTS)

Q3: What is the difference between correlated and non-correlated subqueries?
A3: 
    Non-correlated: Independent of outer query, runs once
    Correlated: References outer query, runs once per outer row (slower!)

Q4: When would you use EXISTS vs IN?
A4: 
    EXISTS: Better for large subquery results, stops at first match
    IN: Better for small, known value lists
    EXISTS handles NULLs correctly, NOT IN can fail with NULLs

Q5: What happens if a scalar subquery returns more than one row?
A5: SQL Server returns an error:
    "Subquery returned more than 1 value. This is not permitted..."
    Use TOP 1 or ensure the subquery returns only one row.

Q6: What happens if a scalar subquery returns no rows?
A6: It returns NULL. This can cause unexpected results in comparisons
    since any comparison with NULL returns UNKNOWN (not TRUE or FALSE).

Q7: Why is NOT IN dangerous with NULL values?
A7: If the subquery returns any NULL values, NOT IN returns empty set!
    Example: WHERE x NOT IN (1, 2, NULL) → always FALSE
    Solution: Filter out NULLs or use NOT EXISTS instead.

Q8: What is a derived table?
A8: A subquery in the FROM clause that acts as a temporary table.
    Must have an alias. Also called inline view.

Q9: Can you use ORDER BY in a subquery?
A9: Yes, but only if you also use TOP (or OFFSET-FETCH).
    Without TOP, ORDER BY in subquery has no effect.

Q10: Which is faster - subquery or JOIN?
A10: Depends on the situation:
     - JOINs are often faster for simple data retrieval
     - EXISTS can be faster than JOIN for existence checks
     - Correlated subqueries can be slower (run per row)
     - Modern query optimizers often generate same plan for both

Q11: Can a subquery return multiple columns?
A11: Yes, when used with EXISTS, or as a derived table in FROM.
     Cannot use multi-column subquery with = or IN comparison directly.

Q12: What is the difference between ANY and ALL?
A12: 
     ANY: TRUE if condition is true for at least one value
     ALL: TRUE if condition is true for all values
     Example: > ANY means > MIN, > ALL means > MAX

Q13: Can subqueries be nested multiple levels deep?
A13: Yes, SQL Server supports up to 32 levels of nesting.
     However, deeply nested subqueries are hard to read and maintain.
     Consider using CTEs or breaking into multiple queries.

Q14: Write a query to find employees earning above average salary.
A14: 
     SELECT EmployeeID, Salary
     FROM Employees
     WHERE Salary > (SELECT AVG(Salary) FROM Employees);

Q15: Write a query to find the second highest salary.
A15: 
     SELECT MAX(Salary) 
     FROM Employees 
     WHERE Salary < (SELECT MAX(Salary) FROM Employees);
     
     Or better:
     SELECT DISTINCT Salary FROM Employees
     ORDER BY Salary DESC
     OFFSET 1 ROW FETCH NEXT 1 ROW ONLY;

================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand what subqueries are and when to use them
□ Can write scalar, row, and table subqueries
□ Know the difference between correlated and non-correlated
□ Understand EXISTS and NOT EXISTS with proper NULL handling
□ Know when to use ANY, SOME, and ALL
□ Can choose between subquery and JOIN appropriately
□ Can answer interview questions confidently

NEXT LAB: Lab 10 - Complex Queries Practice
================================================================================
*/
