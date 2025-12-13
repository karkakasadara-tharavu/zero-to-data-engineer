/*
================================================================================
LAB 13 (ENHANCED): WINDOW FUNCTIONS - COMPLETE GUIDE
Module 03: Advanced SQL
================================================================================

WHAT YOU WILL LEARN:
✅ What window functions are and how they differ from aggregates
✅ OVER clause - the heart of window functions
✅ PARTITION BY - creating groups without collapsing rows
✅ ORDER BY within windows
✅ Frame specifications (ROWS/RANGE)
✅ Ranking functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE)
✅ Aggregate window functions (SUM, AVG, COUNT, MIN, MAX)
✅ Offset functions (LAG, LEAD, FIRST_VALUE, LAST_VALUE)
✅ Practical use cases and interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)
DATABASE: AdventureWorks2022

================================================================================
SECTION 1: UNDERSTANDING WINDOW FUNCTIONS
================================================================================

WHAT ARE WINDOW FUNCTIONS?
--------------------------
Window functions perform calculations across a set of rows RELATED to the 
current row, WITHOUT collapsing those rows into a single output.

Think of it as: "Calculate something about nearby rows, but keep all rows."

THE KEY DIFFERENCE: GROUP BY vs WINDOW
--------------------------------------
GROUP BY: Collapses rows into groups (5 rows → 1 row per group)
WINDOW:   Keeps all rows, adds calculated columns

EXAMPLE:
┌─────────────────────────────────────────────────────────────────────────┐
│ ORIGINAL DATA                 │ GROUP BY SUM      │ WINDOW SUM         │
├─────────────────────────────────────────────────────────────────────────┤
│ Dept   | Name   | Salary      │ Dept   | TotalSal │ Dept  | Sal | Total│
│ Sales  | Alice  | 50000       │ Sales  | 90000    │ Sales | 50K | 90K  │
│ Sales  | Bob    | 40000       │ IT     | 140000   │ Sales | 40K | 90K  │
│ IT     | Carol  | 60000       │                   │ IT    | 60K | 140K │
│ IT     | David  | 80000       │ 2 rows returned   │ IT    | 80K | 140K │
│                               │                   │ 4 rows returned    │
└─────────────────────────────────────────────────────────────────────────┘

SYNTAX STRUCTURE:
-----------------
function_name(column) OVER (
    [PARTITION BY partition_columns]    -- Optional: divide into groups
    [ORDER BY order_columns]            -- Optional: define order
    [frame_specification]               -- Optional: define row range
)

*/

USE AdventureWorks2022;
GO

-- ============================================================================
-- SECTION 2: THE OVER CLAUSE - Your Window into the Data
-- ============================================================================

/*
OVER() - The Heart of Every Window Function

OVER():           Empty = entire result set is one window
OVER(PARTITION):  Divide into groups (like GROUP BY, but keeps rows)
OVER(ORDER BY):   Define the order for ranking/running calculations
OVER(PARTITION + ORDER BY): Groups + ordering within groups
*/

-- Example 1: OVER() without any specification - entire result set
SELECT 
    Name,
    ListPrice,
    AVG(ListPrice) OVER () AS OverallAvgPrice,  -- Same value for ALL rows
    COUNT(*) OVER () AS TotalProducts            -- Same value for ALL rows
FROM Production.Product
WHERE ListPrice > 0
ORDER BY ListPrice DESC;

-- Example 2: OVER(PARTITION BY) - divide into groups
SELECT 
    pc.Name AS Category,
    p.Name AS Product,
    p.ListPrice,
    AVG(p.ListPrice) OVER (PARTITION BY pc.Name) AS CategoryAvgPrice,  -- Avg per category
    COUNT(*) OVER (PARTITION BY pc.Name) AS ProductsInCategory          -- Count per category
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE p.ListPrice > 0
ORDER BY pc.Name, p.ListPrice DESC;

-- Example 3: OVER(ORDER BY) - running calculations
SELECT 
    Name,
    ListPrice,
    ROW_NUMBER() OVER (ORDER BY ListPrice DESC) AS PriceRank,
    SUM(ListPrice) OVER (ORDER BY ListPrice DESC) AS RunningTotal
FROM Production.Product
WHERE ListPrice > 0;

-- ============================================================================
-- SECTION 3: RANKING FUNCTIONS
-- ============================================================================
/*
RANKING FUNCTIONS assign a sequential number to each row based on ordering.

ROW_NUMBER(): Unique sequential numbers (1, 2, 3, 4, 5...)
RANK():       Same rank for ties, then SKIPS (1, 1, 3, 4, 4, 6...)
DENSE_RANK(): Same rank for ties, NO skipping (1, 1, 2, 3, 3, 4...)
NTILE(n):     Divides rows into n equal groups (1, 1, 2, 2, 3, 3...)

VISUAL COMPARISON:
┌─────────────────────────────────────────────────────────────────────────┐
│ Salary  │ ROW_NUMBER │  RANK   │ DENSE_RANK │ NTILE(3)                 │
├─────────────────────────────────────────────────────────────────────────┤
│ $100K   │     1      │    1    │      1     │    1                     │
│ $100K   │     2      │    1    │      1     │    1                     │
│ $90K    │     3      │    3    │      2     │    2      ← RANK skips!  │
│ $80K    │     4      │    4    │      3     │    2                     │
│ $70K    │     5      │    5    │      4     │    3                     │
│ $70K    │     6      │    5    │      4     │    3                     │
└─────────────────────────────────────────────────────────────────────────┘
*/

-- Demonstrate all ranking functions
SELECT 
    p.Name,
    pc.Name AS Category,
    p.ListPrice,
    
    -- ROW_NUMBER: Always unique
    ROW_NUMBER() OVER (ORDER BY p.ListPrice DESC) AS RowNum,
    
    -- RANK: Ties get same rank, then skip
    RANK() OVER (ORDER BY p.ListPrice DESC) AS RankNum,
    
    -- DENSE_RANK: Ties get same rank, no skip
    DENSE_RANK() OVER (ORDER BY p.ListPrice DESC) AS DenseRankNum,
    
    -- NTILE: Divide into groups
    NTILE(10) OVER (ORDER BY p.ListPrice DESC) AS Decile  -- Top 10%, 20%, etc.
    
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE p.ListPrice > 0
ORDER BY p.ListPrice DESC;

-- PRACTICAL USE CASE 1: Pagination (ROW_NUMBER)
WITH PagedProducts AS (
    SELECT 
        ProductID,
        Name,
        ListPrice,
        ROW_NUMBER() OVER (ORDER BY Name) AS RowNum
    FROM Production.Product
    WHERE ListPrice > 0
)
SELECT * FROM PagedProducts
WHERE RowNum BETWEEN 21 AND 40  -- Page 2 (20 items per page)
ORDER BY RowNum;

-- PRACTICAL USE CASE 2: Top N Per Group (ROW_NUMBER + PARTITION)
WITH RankedProducts AS (
    SELECT 
        pc.Name AS Category,
        p.Name AS Product,
        p.ListPrice,
        ROW_NUMBER() OVER (
            PARTITION BY pc.Name 
            ORDER BY p.ListPrice DESC
        ) AS CategoryRank
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE p.ListPrice > 0
)
SELECT * FROM RankedProducts
WHERE CategoryRank <= 3  -- Top 3 products per category
ORDER BY Category, CategoryRank;

-- PRACTICAL USE CASE 3: Percentile Analysis (NTILE)
WITH CustomerSpending AS (
    SELECT 
        c.CustomerID,
        SUM(soh.TotalDue) AS LifetimeValue,
        NTILE(100) OVER (ORDER BY SUM(soh.TotalDue) DESC) AS Percentile
    FROM Sales.Customer c
    JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID
)
SELECT 
    Percentile,
    COUNT(*) AS CustomerCount,
    FORMAT(AVG(LifetimeValue), 'C') AS AvgLifetimeValue,
    CASE 
        WHEN Percentile <= 10 THEN '🌟 Top 10%'
        WHEN Percentile <= 25 THEN '⭐ Top 25%'
        WHEN Percentile <= 50 THEN '✓ Top 50%'
        ELSE '📊 Bottom 50%'
    END AS Segment
FROM CustomerSpending
GROUP BY Percentile
ORDER BY Percentile;

-- ============================================================================
-- SECTION 4: AGGREGATE WINDOW FUNCTIONS
-- ============================================================================
/*
Any aggregate function (SUM, AVG, COUNT, MIN, MAX) can be used as a 
window function by adding OVER().

This allows you to:
- Show detail AND summary in the same row
- Calculate running totals
- Compare each row to group averages
- Calculate percentages
*/

-- Example: Compare each product to its category
SELECT 
    pc.Name AS Category,
    p.Name AS Product,
    p.ListPrice,
    
    -- Category statistics
    AVG(p.ListPrice) OVER (PARTITION BY pc.Name) AS CategoryAvg,
    MIN(p.ListPrice) OVER (PARTITION BY pc.Name) AS CategoryMin,
    MAX(p.ListPrice) OVER (PARTITION BY pc.Name) AS CategoryMax,
    COUNT(*) OVER (PARTITION BY pc.Name) AS CategoryCount,
    
    -- Comparison
    p.ListPrice - AVG(p.ListPrice) OVER (PARTITION BY pc.Name) AS VsAverage,
    
    -- Percentage of category total
    CAST(p.ListPrice * 100.0 / SUM(p.ListPrice) OVER (PARTITION BY pc.Name) AS DECIMAL(5,2)) AS PctOfCategory
    
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE p.ListPrice > 0
ORDER BY pc.Name, p.ListPrice DESC;

-- Running Total Example
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    
    -- Cumulative (running) total
    SUM(soh.TotalDue) OVER (ORDER BY soh.OrderDate, soh.SalesOrderID) AS RunningTotal,
    
    -- Running count
    COUNT(*) OVER (ORDER BY soh.OrderDate, soh.SalesOrderID) AS OrderNumber,
    
    -- Running average
    AVG(soh.TotalDue) OVER (ORDER BY soh.OrderDate, soh.SalesOrderID) AS RunningAvg
    
FROM Sales.SalesOrderHeader soh
WHERE soh.OrderDate >= '2014-01-01' AND soh.OrderDate < '2014-02-01'
ORDER BY soh.OrderDate, soh.SalesOrderID;

-- ============================================================================
-- SECTION 5: FRAME SPECIFICATIONS (ROWS / RANGE)
-- ============================================================================
/*
When you use ORDER BY in a window, you can specify exactly which rows 
to include in the calculation using ROWS or RANGE.

SYNTAX:
ROWS BETWEEN <start> AND <end>
RANGE BETWEEN <start> AND <end>

Options for <start> and <end>:
- UNBOUNDED PRECEDING: All previous rows
- n PRECEDING: n rows before current
- CURRENT ROW: Current row
- n FOLLOWING: n rows after current
- UNBOUNDED FOLLOWING: All following rows

DEFAULT BEHAVIOR:
- Without ORDER BY: RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING (entire partition)
- With ORDER BY: RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW (running total)

ROWS vs RANGE:
- ROWS: Literal row positions
- RANGE: Values (ties are included together)
*/

-- Example: Moving Average (Last 3 rows)
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    
    -- Running total (default with ORDER BY)
    SUM(soh.TotalDue) OVER (
        ORDER BY soh.OrderDate, soh.SalesOrderID
    ) AS RunningTotal,
    
    -- 3-row moving average
    AVG(soh.TotalDue) OVER (
        ORDER BY soh.OrderDate, soh.SalesOrderID
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3,
    
    -- 5-row moving average
    AVG(soh.TotalDue) OVER (
        ORDER BY soh.OrderDate, soh.SalesOrderID
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS MovingAvg5,
    
    -- Centered moving average (1 before, current, 1 after)
    AVG(soh.TotalDue) OVER (
        ORDER BY soh.OrderDate, soh.SalesOrderID
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS CenteredAvg
    
FROM Sales.SalesOrderHeader soh
WHERE soh.OrderDate >= '2014-01-01' AND soh.OrderDate < '2014-02-01'
ORDER BY soh.OrderDate, soh.SalesOrderID;

-- ============================================================================
-- SECTION 6: OFFSET FUNCTIONS (LAG, LEAD, FIRST_VALUE, LAST_VALUE)
-- ============================================================================
/*
Offset functions let you access values from OTHER ROWS relative to current row.

LAG(column, n, default):        Value from n rows BEFORE (default if no row)
LEAD(column, n, default):       Value from n rows AFTER (default if no row)
FIRST_VALUE(column):            First value in the window
LAST_VALUE(column):             Last value in the window
NTH_VALUE(column, n):           Nth value in the window (SQL Server 2022+)
*/

-- Example: Compare each sale to previous and next
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    
    -- Previous row value
    LAG(soh.TotalDue, 1, 0) OVER (ORDER BY soh.OrderDate, soh.SalesOrderID) AS PreviousOrderAmount,
    
    -- Next row value
    LEAD(soh.TotalDue, 1, 0) OVER (ORDER BY soh.OrderDate, soh.SalesOrderID) AS NextOrderAmount,
    
    -- Change from previous
    soh.TotalDue - LAG(soh.TotalDue, 1, soh.TotalDue) OVER (ORDER BY soh.OrderDate, soh.SalesOrderID) AS ChangeFromPrevious,
    
    -- First value in window
    FIRST_VALUE(soh.TotalDue) OVER (ORDER BY soh.OrderDate, soh.SalesOrderID) AS FirstOrderAmount
    
FROM Sales.SalesOrderHeader soh
WHERE soh.OrderDate >= '2014-01-01' AND soh.OrderDate < '2014-02-01'
ORDER BY soh.OrderDate, soh.SalesOrderID;

-- Year-over-Year Comparison using LAG
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS SalesYear,
        MONTH(OrderDate) AS SalesMonth,
        SUM(TotalDue) AS MonthlyTotal
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    SalesYear,
    SalesMonth,
    FORMAT(MonthlyTotal, 'C') AS Revenue,
    FORMAT(LAG(MonthlyTotal, 12) OVER (ORDER BY SalesYear, SalesMonth), 'C') AS PrevYearRevenue,
    CASE 
        WHEN LAG(MonthlyTotal, 12) OVER (ORDER BY SalesYear, SalesMonth) IS NULL THEN NULL
        ELSE CAST((MonthlyTotal - LAG(MonthlyTotal, 12) OVER (ORDER BY SalesYear, SalesMonth)) * 100.0 
             / LAG(MonthlyTotal, 12) OVER (ORDER BY SalesYear, SalesMonth) AS DECIMAL(5,2))
    END AS YoYGrowthPct
FROM MonthlySales
ORDER BY SalesYear, SalesMonth;

-- ============================================================================
-- SECTION 7: PRACTICAL USE CASES
-- ============================================================================

-- USE CASE 1: Remove duplicates (keep first)
WITH RankedDuplicates AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY Email ORDER BY CreatedDate) AS rn
    FROM #TempUsers
)
DELETE FROM RankedDuplicates WHERE rn > 1;

-- USE CASE 2: Find gaps in sequence
WITH NumberedOrders AS (
    SELECT 
        SalesOrderID,
        LAG(SalesOrderID) OVER (ORDER BY SalesOrderID) AS PrevOrderID
    FROM Sales.SalesOrderHeader
)
SELECT SalesOrderID, PrevOrderID, SalesOrderID - PrevOrderID AS Gap
FROM NumberedOrders
WHERE SalesOrderID - PrevOrderID > 1;

-- USE CASE 3: Identify consecutive events (streaks)
WITH DailySales AS (
    SELECT 
        CAST(OrderDate AS DATE) AS SaleDate,
        SUM(TotalDue) AS DailySales
    FROM Sales.SalesOrderHeader
    GROUP BY CAST(OrderDate AS DATE)
),
Streaks AS (
    SELECT 
        SaleDate,
        DailySales,
        SaleDate,
        DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY SaleDate), SaleDate) AS StreakGroup
    FROM DailySales
)
SELECT 
    MIN(SaleDate) AS StreakStart,
    MAX(SaleDate) AS StreakEnd,
    COUNT(*) AS StreakLength,
    SUM(DailySales) AS StreakTotal
FROM Streaks
GROUP BY StreakGroup
HAVING COUNT(*) >= 5  -- At least 5 consecutive days
ORDER BY StreakStart;

-- ============================================================================
-- SECTION 8: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: WINDOW FUNCTIONS - Top 15 Questions
================================================================================

Q1: What is a window function and how does it differ from aggregate functions?
A1: A window function performs calculations across a set of rows related to 
    the current row WITHOUT collapsing those rows. Unlike GROUP BY which 
    produces one row per group, window functions keep all rows and add 
    calculated columns.

Q2: Explain the OVER() clause.
A2: OVER() defines the "window" (set of rows) for the function:
    - OVER(): Entire result set
    - OVER(PARTITION BY x): Divide into groups
    - OVER(ORDER BY x): Define order for rankings/running calcs
    - OVER(PARTITION BY x ORDER BY y): Both

Q3: What's the difference between ROW_NUMBER, RANK, and DENSE_RANK?
A3: For values 100, 100, 90:
    - ROW_NUMBER: 1, 2, 3 (always unique)
    - RANK: 1, 1, 3 (ties get same, then skips)
    - DENSE_RANK: 1, 1, 2 (ties get same, no skip)

Q4: How do you find the Nth highest salary?
A4: 
    WITH Ranked AS (
        SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
        FROM employees
    )
    SELECT DISTINCT salary FROM Ranked WHERE rnk = N;

Q5: How do you get top 3 per group?
A5: 
    WITH Ranked AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
        FROM products
    )
    SELECT * FROM Ranked WHERE rn <= 3;

Q6: What is NTILE and when would you use it?
A6: NTILE(n) divides rows into n equal groups. Use for:
    - Percentile analysis (NTILE(100))
    - Quartiles (NTILE(4))
    - Distributing work across workers

Q7: Explain LAG and LEAD functions.
A7: LAG(col, n) gets value from n rows BEFORE current row.
    LEAD(col, n) gets value from n rows AFTER current row.
    Useful for: YoY comparisons, detecting changes, gap analysis.

Q8: What is a running total and how do you create one?
A8: SUM(amount) OVER (ORDER BY date) creates a cumulative sum.
    Default frame with ORDER BY is UNBOUNDED PRECEDING to CURRENT ROW.

Q9: What is the difference between ROWS and RANGE?
A9: ROWS: Counts literal row positions
    RANGE: Groups rows with same ORDER BY values together
    
    Example with ORDER BY date:
    - ROWS: 3 preceding rows exactly
    - RANGE: All rows with dates in preceding range (ties included)

Q10: How do you calculate a moving average?
A10:
    AVG(value) OVER (
        ORDER BY date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3Day

Q11: Can you use window functions in WHERE clause?
A11: No! Window functions are evaluated AFTER WHERE/GROUP BY/HAVING.
     Solution: Use a CTE or subquery first, then filter.
     
     WITH Ranked AS (SELECT *, ROW_NUMBER() OVER (...) AS rn FROM t)
     SELECT * FROM Ranked WHERE rn = 1;

Q12: How do you calculate percentage of total using window functions?
A12:
    amount * 100.0 / SUM(amount) OVER () AS PctOfTotal
    amount * 100.0 / SUM(amount) OVER (PARTITION BY category) AS PctOfCategory

Q13: How do you find duplicate records using window functions?
A13:
    WITH Ranked AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
        FROM users
    )
    SELECT * FROM Ranked WHERE rn > 1;  -- Duplicates

Q14: What is FIRST_VALUE and LAST_VALUE?
A14: Return first/last value in the window frame.
     CAUTION: LAST_VALUE default frame is to CURRENT ROW!
     Use: ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

Q15: Can you combine multiple window functions?
A15: Yes! Each can have different OVER() specifications:
     SELECT 
         SUM(x) OVER (ORDER BY date) AS Running,
         AVG(x) OVER (PARTITION BY category) AS CategoryAvg,
         ROW_NUMBER() OVER (ORDER BY date DESC) AS Rank
     FROM table;

================================================================================
*/

-- ============================================================================
-- SECTION 9: PRACTICE EXERCISES
-- ============================================================================

/*
EXERCISE 1: Create employee ranking by salary within each department
*/
-- Your solution here:



/*
EXERCISE 2: Calculate the percentage of department salary for each employee
*/
-- Your solution here:



/*
EXERCISE 3: Find the month-over-month growth in sales
*/
-- Your solution here:



/*
EXERCISE 4: Calculate a 7-day moving average of daily sales
*/
-- Your solution here:



/*
================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand what window functions are and when to use them
□ Master the OVER() clause variations
□ Can use all ranking functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE)
□ Can use aggregate window functions for running totals
□ Understand frame specifications (ROWS/RANGE)
□ Can use offset functions (LAG, LEAD, FIRST_VALUE, LAST_VALUE)
□ Know practical use cases (Top N, duplicates, gaps, percentages)
□ Can answer interview questions confidently
□ Completed practice exercises

NEXT LAB: Lab 14 - Window Analytical Functions (Advanced)
================================================================================
*/
