/*
================================================================================
LAB 07 (ENHANCED): AGGREGATIONS AND GROUP BY - COMPLETE GUIDE
Module 02: SQL Fundamentals
================================================================================

WHAT YOU WILL LEARN:
✅ All aggregate functions (COUNT, SUM, AVG, MIN, MAX, etc.)
✅ GROUP BY clause and how it works
✅ HAVING vs WHERE - when to use each
✅ Multiple grouping (GROUP BY with multiple columns)
✅ GROUPING SETS, ROLLUP, and CUBE
✅ Common aggregation patterns
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐ (Beginner to Intermediate)
DATABASE: AdventureWorks2022

================================================================================
SECTION 1: AGGREGATE FUNCTIONS - THE BASICS
================================================================================

WHAT ARE AGGREGATE FUNCTIONS?
-----------------------------
Aggregate functions perform calculations on a SET of values and return 
a SINGLE result. They "aggregate" (combine) multiple rows into one.

COMMON AGGREGATE FUNCTIONS:
┌──────────────┬────────────────────────────────────────────────────────────┐
│ Function     │ Description                                                │
├──────────────┼────────────────────────────────────────────────────────────┤
│ COUNT(*)     │ Count ALL rows (including NULLs)                          │
│ COUNT(col)   │ Count NON-NULL values in column                           │
│ SUM(col)     │ Total sum of values                                       │
│ AVG(col)     │ Average of values (ignores NULLs!)                        │
│ MIN(col)     │ Smallest value                                            │
│ MAX(col)     │ Largest value                                             │
│ STDEV(col)   │ Standard deviation                                        │
│ VAR(col)     │ Variance                                                  │
│ STRING_AGG() │ Concatenate values into string                            │
└──────────────┴────────────────────────────────────────────────────────────┘

IMPORTANT: All aggregates IGNORE NULL values except COUNT(*)!
*/

USE AdventureWorks2022;
GO

-- ============================================================================
-- SECTION 2: BASIC AGGREGATE EXAMPLES
-- ============================================================================

-- COUNT Examples
SELECT COUNT(*) AS TotalRows FROM Production.Product;          -- All rows
SELECT COUNT(Color) AS ProductsWithColor FROM Production.Product;  -- Only non-NULL colors
SELECT COUNT(DISTINCT Color) AS UniqueColors FROM Production.Product;  -- Unique colors

/*
VISUAL - COUNT Behavior with NULLs:
┌──────────────┬─────────────┐
│ ProductID    │ Color       │
├──────────────┼─────────────┤
│ 1            │ Red         │
│ 2            │ Blue        │
│ 3            │ NULL        │
│ 4            │ Red         │
│ 5            │ NULL        │
└──────────────┴─────────────┘

COUNT(*)     = 5  (all rows)
COUNT(Color) = 3  (only non-NULL: Red, Blue, Red)
COUNT(DISTINCT Color) = 2  (unique: Red, Blue)
*/

-- SUM and AVG Examples
SELECT 
    SUM(ListPrice) AS TotalListPrice,
    AVG(ListPrice) AS AvgListPrice,
    COUNT(*) AS TotalProducts,
    COUNT(ListPrice) AS ProductsWithPrice
FROM Production.Product
WHERE ListPrice > 0;

-- MIN and MAX Examples
SELECT 
    MIN(ListPrice) AS CheapestProduct,
    MAX(ListPrice) AS MostExpensiveProduct,
    MIN(Name) AS FirstAlphabetically,
    MAX(Name) AS LastAlphabetically,
    MIN(SellStartDate) AS OldestProduct,
    MAX(SellStartDate) AS NewestProduct
FROM Production.Product;

-- ============================================================================
-- SECTION 3: GROUP BY - AGGREGATING BY CATEGORIES
-- ============================================================================
/*
GROUP BY:
---------
Divides rows into groups based on column values.
Aggregate functions are applied to EACH group separately.

RULE: Every column in SELECT must be either:
1. In the GROUP BY clause, OR
2. Inside an aggregate function

VISUAL - How GROUP BY Works:
Before Grouping:                After GROUP BY Color:
┌────────┬───────┬───────┐     ┌───────┬───────────┬──────────┐
│ ID     │ Color │ Price │     │ Color │ COUNT(*)  │ AVG      │
├────────┼───────┼───────┤     ├───────┼───────────┼──────────┤
│ 1      │ Red   │ 100   │     │ Red   │ 3         │ 133.33   │
│ 2      │ Blue  │ 200   │     │ Blue  │ 2         │ 225.00   │
│ 3      │ Red   │ 100   │     └───────┴───────────┴──────────┘
│ 4      │ Blue  │ 250   │     
│ 5      │ Red   │ 200   │     
└────────┴───────┴───────┘     
*/

-- EXAMPLE 1: Count products by color
SELECT 
    Color,
    COUNT(*) AS ProductCount
FROM Production.Product
WHERE Color IS NOT NULL
GROUP BY Color
ORDER BY ProductCount DESC;

-- EXAMPLE 2: Sales by product category
SELECT 
    pc.Name AS Category,
    COUNT(p.ProductID) AS ProductCount,
    SUM(p.ListPrice) AS TotalListPrice,
    AVG(p.ListPrice) AS AvgPrice,
    MIN(p.ListPrice) AS MinPrice,
    MAX(p.ListPrice) AS MaxPrice
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY ProductCount DESC;

-- EXAMPLE 3: Orders by year and month
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;

-- ============================================================================
-- SECTION 4: HAVING VS WHERE
-- ============================================================================
/*
WHERE vs HAVING - THE KEY DIFFERENCE:
-------------------------------------
WHERE:  Filters rows BEFORE grouping (can't use aggregates)
HAVING: Filters groups AFTER grouping (can use aggregates)

PROCESSING ORDER:
1. FROM - Get the table
2. WHERE - Filter individual rows
3. GROUP BY - Create groups
4. HAVING - Filter groups
5. SELECT - Choose columns
6. ORDER BY - Sort results

MEMORY TRICK:
- WHERE filters the ingredients (raw data)
- HAVING filters the dishes (aggregated results)
*/

-- WRONG: Can't use aggregate in WHERE
-- SELECT Color, COUNT(*) FROM Production.Product WHERE COUNT(*) > 5 GROUP BY Color;
-- Error: An aggregate may not appear in the WHERE clause

-- CORRECT: Use HAVING for aggregate conditions
SELECT 
    Color,
    COUNT(*) AS ProductCount
FROM Production.Product
WHERE Color IS NOT NULL    -- Filter rows BEFORE grouping
GROUP BY Color
HAVING COUNT(*) > 10       -- Filter groups AFTER grouping
ORDER BY ProductCount DESC;

-- EXAMPLE: Combining WHERE and HAVING
SELECT 
    ps.Name AS Subcategory,
    COUNT(*) AS ProductCount,
    AVG(p.ListPrice) AS AvgPrice
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
WHERE p.ListPrice > 0            -- Row filter: only products with price
GROUP BY ps.Name
HAVING AVG(p.ListPrice) > 500    -- Group filter: average > $500
ORDER BY AvgPrice DESC;

/*
COMMON INTERVIEW QUESTION:
"What's the difference between WHERE and HAVING?"

ANSWER:
- WHERE filters rows BEFORE grouping, cannot use aggregates
- HAVING filters groups AFTER grouping, can use aggregates
- Use WHERE for row-level conditions (Color = 'Red')
- Use HAVING for aggregate conditions (COUNT(*) > 10)
*/

-- ============================================================================
-- SECTION 5: GROUP BY WITH MULTIPLE COLUMNS
-- ============================================================================
/*
When you GROUP BY multiple columns, you create groups for 
each UNIQUE COMBINATION of values.

Example: GROUP BY Year, Month
Creates groups for: (2023, 1), (2023, 2), ..., (2024, 1), etc.
*/

-- Sales by year, quarter, and region
SELECT 
    YEAR(soh.OrderDate) AS OrderYear,
    DATEPART(QUARTER, soh.OrderDate) AS Quarter,
    st.Name AS Territory,
    COUNT(*) AS OrderCount,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY 
    YEAR(soh.OrderDate), 
    DATEPART(QUARTER, soh.OrderDate),
    st.Name
ORDER BY OrderYear, Quarter, Territory;

-- ============================================================================
-- SECTION 6: GROUPING SETS, ROLLUP, AND CUBE
-- ============================================================================
/*
ADVANCED GROUPING - Multiple Aggregation Levels

GROUPING SETS: Specify exactly which groupings you want
ROLLUP: Hierarchical groupings (with subtotals)
CUBE: All possible combinations of groupings

VISUAL - ROLLUP vs CUBE:

Data: Sales by Year and Category
ROLLUP(Year, Category):          CUBE(Year, Category):
- (Year, Category) detail         - (Year, Category) detail
- (Year) subtotal                 - (Year) subtotal
- () grand total                  - (Category) subtotal
                                  - () grand total

ROLLUP is hierarchical (left to right)
CUBE includes all combinations
*/

-- ROLLUP Example - Hierarchical totals
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    SUM(TotalDue) AS TotalSales,
    COUNT(*) AS OrderCount
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01'
GROUP BY ROLLUP(YEAR(OrderDate), MONTH(OrderDate))
ORDER BY OrderYear, OrderMonth;

/*
ROLLUP Results:
OrderYear  OrderMonth  TotalSales   OrderCount
2013       1           1000000      500        <- Detail
2013       2           1200000      600
...
2013       NULL        12000000     6000       <- Year subtotal
2014       1           1100000      550
...
NULL       NULL        25000000     12000      <- Grand total
*/

-- CUBE Example - All combinations
SELECT 
    pc.Name AS Category,
    st.Name AS Territory,
    SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY CUBE(pc.Name, st.Name)
ORDER BY Category, Territory;

-- GROUPING SETS - Custom combinations
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY GROUPING SETS (
    (YEAR(OrderDate), MONTH(OrderDate)),  -- Year-Month detail
    (YEAR(OrderDate)),                     -- Year subtotal
    ()                                     -- Grand total
)
ORDER BY OrderYear, OrderMonth;

-- GROUPING function - Identify which level (0 = real value, 1 = subtotal)
SELECT 
    CASE WHEN GROUPING(YEAR(OrderDate)) = 1 THEN 'TOTAL' 
         ELSE CAST(YEAR(OrderDate) AS VARCHAR) END AS OrderYear,
    CASE WHEN GROUPING(MONTH(OrderDate)) = 1 THEN 'ALL MONTHS' 
         ELSE CAST(MONTH(OrderDate) AS VARCHAR) END AS OrderMonth,
    SUM(TotalDue) AS TotalSales,
    GROUPING(YEAR(OrderDate)) AS YearGrouping,
    GROUPING(MONTH(OrderDate)) AS MonthGrouping
FROM Sales.SalesOrderHeader
GROUP BY ROLLUP(YEAR(OrderDate), MONTH(OrderDate));

-- ============================================================================
-- SECTION 7: STRING_AGG - CONCATENATE VALUES
-- ============================================================================
/*
STRING_AGG (SQL Server 2017+):
Concatenates values from multiple rows into a single string.
Similar to GROUP_CONCAT in MySQL.
*/

-- List all colors in one cell
SELECT STRING_AGG(DISTINCT Color, ', ') AS AllColors
FROM Production.Product
WHERE Color IS NOT NULL;

-- Products grouped by category with names concatenated
SELECT 
    pc.Name AS Category,
    COUNT(*) AS ProductCount,
    STRING_AGG(p.Name, ' | ') WITHIN GROUP (ORDER BY p.Name) AS ProductList
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name;

-- ============================================================================
-- SECTION 8: AGGREGATE WITH DISTINCT
-- ============================================================================

-- Count distinct customers who ordered
SELECT 
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS TotalOrders,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    SUM(TotalDue) AS TotalRevenue,
    SUM(TotalDue) / COUNT(DISTINCT CustomerID) AS AvgRevenuePerCustomer
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;

-- ============================================================================
-- SECTION 9: NULL HANDLING IN AGGREGATES
-- ============================================================================
/*
IMPORTANT: Aggregates IGNORE NULL values (except COUNT(*))

This can lead to unexpected results!

Example Data:
┌─────────────┬───────────┐
│ Employee    │ Bonus     │
├─────────────┼───────────┤
│ Alice       │ 1000      │
│ Bob         │ NULL      │
│ Charlie     │ 2000      │
│ Diana       │ NULL      │
└─────────────┴───────────┘

AVG(Bonus) = (1000 + 2000) / 2 = 1500  ← Only 2 values counted!
Not (1000 + 0 + 2000 + 0) / 4 = 750

If you want to treat NULL as 0:
AVG(ISNULL(Bonus, 0)) = 750
*/

-- Demo: NULL handling
SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(Color) AS ProductsWithColor,
    AVG(Weight) AS AvgWeight,                    -- Ignores NULLs
    AVG(ISNULL(Weight, 0)) AS AvgWeightWith0     -- Treats NULL as 0
FROM Production.Product;

-- ============================================================================
-- SECTION 10: COMMON AGGREGATION PATTERNS
-- ============================================================================

-- PATTERN 1: Find duplicates
SELECT 
    Name,
    COUNT(*) AS DuplicateCount
FROM Production.Product
GROUP BY Name
HAVING COUNT(*) > 1;

-- PATTERN 2: Running totals (with window function - preview)
SELECT 
    OrderDate,
    TotalDue,
    SUM(TotalDue) OVER (ORDER BY OrderDate) AS RunningTotal
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2014-01-01' AND OrderDate < '2014-02-01'
ORDER BY OrderDate;

-- PATTERN 3: Percentage of total
SELECT 
    Color,
    COUNT(*) AS ProductCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS Percentage
FROM Production.Product
WHERE Color IS NOT NULL
GROUP BY Color
ORDER BY ProductCount DESC;

-- PATTERN 4: Top N per group (combined with window functions)
SELECT * FROM (
    SELECT 
        pc.Name AS Category,
        p.Name AS ProductName,
        p.ListPrice,
        ROW_NUMBER() OVER (PARTITION BY pc.Name ORDER BY p.ListPrice DESC) AS PriceRank
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
) ranked
WHERE PriceRank <= 3;

-- ============================================================================
-- SECTION 11: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: AGGREGATIONS AND GROUP BY
================================================================================

Q1: What's the difference between WHERE and HAVING?
A1: WHERE filters rows BEFORE grouping (can't use aggregates).
    HAVING filters groups AFTER grouping (can use aggregates).
    Use WHERE for row conditions, HAVING for aggregate conditions.

Q2: What's the difference between COUNT(*) and COUNT(column)?
A2: COUNT(*) counts ALL rows, including those with NULL values.
    COUNT(column) counts only NON-NULL values in that column.

Q3: How do aggregate functions handle NULL values?
A3: All aggregates IGNORE NULL values except COUNT(*).
    This affects AVG especially - it only averages non-NULL values.
    Use ISNULL(column, 0) if you want to treat NULL as 0.

Q4: Can you use an aggregate function in WHERE clause?
A4: No! Aggregates cannot appear in WHERE clause.
    Use HAVING for aggregate conditions, or use a subquery.

Q5: What is ROLLUP?
A5: ROLLUP creates hierarchical subtotals from left to right.
    GROUP BY ROLLUP(A, B) gives: (A,B), (A), () grand total.
    Useful for reports with subtotals.

Q6: What is CUBE?
A6: CUBE creates subtotals for ALL possible combinations.
    GROUP BY CUBE(A, B) gives: (A,B), (A), (B), () grand total.
    More combinations than ROLLUP.

Q7: How do you concatenate values from multiple rows?
A7: Use STRING_AGG(column, delimiter) with optional WITHIN GROUP (ORDER BY).
    Available in SQL Server 2017+.

Q8: Write a query to find products with duplicate names.
A8: SELECT Name, COUNT(*) 
    FROM Products 
    GROUP BY Name 
    HAVING COUNT(*) > 1;

Q9: What's the SQL execution order?
A9: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
    This is why WHERE can't use aggregates (happens before grouping).

Q10: How do you calculate percentage of total in each group?
A10: Use window function with aggregate:
     COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS Percentage

Q11: What is GROUPING function used for?
A11: GROUPING(column) returns 1 if the row is a subtotal for that column,
     0 if it's a regular value. Helps identify rollup/cube summary rows.

Q12: Can you GROUP BY columns not in SELECT?
A12: Yes, you can GROUP BY any column, but only columns in GROUP BY
     (or aggregates) can appear in SELECT.

Q13: How do you find the second highest salary?
A13: SELECT MAX(Salary) FROM Employees 
     WHERE Salary < (SELECT MAX(Salary) FROM Employees);
     Or use OFFSET-FETCH or window functions.

Q14: What's the difference between AVG and calculating SUM/COUNT?
A14: AVG ignores NULLs in both numerator and denominator.
     SUM(col)/COUNT(*) would include NULLs in denominator.
     SUM(col)/COUNT(col) is equivalent to AVG.

Q15: Can you use DISTINCT with SUM?
A15: Yes! SUM(DISTINCT column) adds only unique values.
     Useful when you have duplicates you want to count once.

================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand all aggregate functions (COUNT, SUM, AVG, MIN, MAX)
□ Know how NULL values affect aggregates
□ Can use GROUP BY with single and multiple columns
□ Understand WHERE vs HAVING (when to use each)
□ Know how to use ROLLUP, CUBE, and GROUPING SETS
□ Can write percentage of total and running total queries
□ Can answer interview questions confidently

NEXT LAB: Lab 08 - CASE Statements and Conditional Logic
================================================================================
*/
