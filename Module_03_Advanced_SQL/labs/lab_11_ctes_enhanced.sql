/*
================================================================================
LAB 11 (ENHANCED): COMMON TABLE EXPRESSIONS (CTEs) - COMPLETE GUIDE
Module 03: Advanced SQL
================================================================================

WHAT YOU WILL LEARN:
✅ What CTEs are and why they matter
✅ CTE syntax and structure explained step-by-step
✅ When to use CTEs vs Subqueries vs Temp Tables
✅ Single and Multiple CTEs with real examples
✅ Recursive CTEs for hierarchical data
✅ Performance considerations
✅ Interview preparation with common questions

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐ (Intermediate to Advanced)
DATABASE: AdventureWorks2022

================================================================================
SECTION 1: UNDERSTANDING CTEs - THE FUNDAMENTALS
================================================================================

WHAT IS A CTE (Common Table Expression)?
----------------------------------------
A CTE is a TEMPORARY NAMED RESULT SET that you define within a single SQL 
statement. Think of it as creating a "temporary view" that exists only for 
that one query.

WHY USE CTEs?
-------------
1. READABILITY: Break complex queries into logical, named parts
2. REUSABILITY: Reference the same result set multiple times
3. RECURSION: Only CTEs can do recursive queries in SQL Server
4. MAINTAINABILITY: Easier to understand and modify than nested subqueries

CTE SYNTAX STRUCTURE:
--------------------
WITH CTE_Name (Column1, Column2, ...)  -- Column list is OPTIONAL
AS
(
    -- Your SELECT query goes here
    SELECT ...
)
-- Main query that USES the CTE
SELECT * FROM CTE_Name;

IMPORTANT RULES:
----------------
1. CTE MUST be immediately followed by a SELECT, INSERT, UPDATE, or DELETE
2. CTE is valid ONLY for that single statement
3. You can define MULTIPLE CTEs separated by commas
4. CTEs can reference other CTEs defined earlier (in the same WITH block)
*/

USE AdventureWorks2022;
GO

-- ============================================================================
-- EXAMPLE 1: YOUR FIRST CTE - Understanding the Basics
-- ============================================================================
/*
SCENARIO: Find all products priced above the average price.

WITHOUT CTE (using subquery - harder to read):
*/
SELECT 
    ProductID,
    Name,
    ListPrice,
    (SELECT AVG(ListPrice) FROM Production.Product WHERE ListPrice > 0) AS AvgPrice
FROM Production.Product
WHERE ListPrice > (SELECT AVG(ListPrice) FROM Production.Product WHERE ListPrice > 0);

/*
PROBLEM: The average calculation is duplicated - inefficient and error-prone.

WITH CTE (cleaner and more maintainable):
*/
WITH AvgPriceCTE AS
(
    -- Step 1: Calculate the average price ONCE
    SELECT AVG(ListPrice) AS AveragePrice
    FROM Production.Product
    WHERE ListPrice > 0
)
-- Step 2: Use that calculated value
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    a.AveragePrice,
    p.ListPrice - a.AveragePrice AS AboveAvgBy
FROM Production.Product p
CROSS JOIN AvgPriceCTE a  -- CROSS JOIN because CTE has only 1 row
WHERE p.ListPrice > a.AveragePrice
ORDER BY p.ListPrice DESC;

/*
EXPLANATION:
- AvgPriceCTE calculates the average ONCE
- We can reference it multiple times without recalculation
- The query is more readable and self-documenting
*/

-- ============================================================================
-- EXAMPLE 2: CTE with Column Aliases
-- ============================================================================
/*
You can specify column names in the CTE definition OR in the SELECT.
Both approaches below produce identical results:
*/

-- Approach 1: Column names in CTE definition
WITH ProductStats (CategoryName, TotalProducts, AvgPrice, MaxPrice) AS
(
    SELECT 
        pc.Name,
        COUNT(*),
        AVG(p.ListPrice),
        MAX(p.ListPrice)
    FROM Production.Product p
    INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE p.ListPrice > 0
    GROUP BY pc.Name
)
SELECT * FROM ProductStats ORDER BY TotalProducts DESC;

-- Approach 2: Column aliases in the SELECT (more common)
WITH ProductStats AS
(
    SELECT 
        pc.Name AS CategoryName,
        COUNT(*) AS TotalProducts,
        AVG(p.ListPrice) AS AvgPrice,
        MAX(p.ListPrice) AS MaxPrice
    FROM Production.Product p
    INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE p.ListPrice > 0
    GROUP BY pc.Name
)
SELECT * FROM ProductStats ORDER BY TotalProducts DESC;

-- ============================================================================
-- EXAMPLE 3: MULTIPLE CTEs - Building a Data Pipeline
-- ============================================================================
/*
SCENARIO: Build a customer segmentation report in steps.
This demonstrates how CTEs can chain together like a pipeline.

STEP 1: Calculate metrics per customer
STEP 2: Assign segments based on metrics
STEP 3: Summarize by segment
*/

WITH 
-- CTE 1: Calculate customer spending metrics
CustomerMetrics AS
(
    SELECT 
        c.CustomerID,
        p.FirstName + ' ' + p.LastName AS CustomerName,
        COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
        SUM(soh.TotalDue) AS TotalSpent,
        AVG(soh.TotalDue) AS AvgOrderValue,
        MIN(soh.OrderDate) AS FirstOrder,
        MAX(soh.OrderDate) AS LastOrder
    FROM Sales.Customer c
    INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    INNER JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID, p.FirstName, p.LastName
),
-- CTE 2: Assign customer segments (references CTE 1)
CustomerSegments AS
(
    SELECT 
        CustomerID,
        CustomerName,
        TotalOrders,
        TotalSpent,
        AvgOrderValue,
        FirstOrder,
        LastOrder,
        CASE 
            WHEN TotalSpent >= 50000 THEN 'Platinum'
            WHEN TotalSpent >= 20000 THEN 'Gold'
            WHEN TotalSpent >= 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS Segment,
        DATEDIFF(DAY, FirstOrder, LastOrder) AS CustomerTenureDays
    FROM CustomerMetrics
),
-- CTE 3: Summarize by segment (references CTE 2)
SegmentSummary AS
(
    SELECT 
        Segment,
        COUNT(*) AS CustomerCount,
        SUM(TotalSpent) AS SegmentRevenue,
        AVG(TotalSpent) AS AvgCustomerValue,
        AVG(TotalOrders) AS AvgOrders
    FROM CustomerSegments
    GROUP BY Segment
)
-- Final output: Show segment summary with percentages
SELECT 
    Segment,
    CustomerCount,
    FORMAT(SegmentRevenue, 'C') AS SegmentRevenue,
    FORMAT(AvgCustomerValue, 'C') AS AvgCustomerValue,
    AvgOrders,
    CAST(CustomerCount * 100.0 / SUM(CustomerCount) OVER () AS DECIMAL(5,2)) AS PctOfCustomers,
    CAST(SegmentRevenue * 100.0 / SUM(SegmentRevenue) OVER () AS DECIMAL(5,2)) AS PctOfRevenue
FROM SegmentSummary
ORDER BY 
    CASE Segment 
        WHEN 'Platinum' THEN 1 
        WHEN 'Gold' THEN 2 
        WHEN 'Silver' THEN 3 
        ELSE 4 
    END;

/*
KEY INSIGHT: Notice how each CTE builds on the previous one:
CustomerMetrics → CustomerSegments → SegmentSummary → Final SELECT

This is called a "CTE pipeline" - very useful for complex transformations!
*/

-- ============================================================================
-- EXAMPLE 4: REFERENCING A CTE MULTIPLE TIMES
-- ============================================================================
/*
SCENARIO: Compare each product's price to both the category average AND overall average.
This is where CTEs shine - we calculate averages once and use them twice.
*/

WITH 
CategoryAvg AS
(
    SELECT 
        ps.ProductCategoryID,
        AVG(p.ListPrice) AS CategoryAvgPrice
    FROM Production.Product p
    INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    WHERE p.ListPrice > 0
    GROUP BY ps.ProductCategoryID
),
OverallAvg AS
(
    SELECT AVG(ListPrice) AS OverallAvgPrice
    FROM Production.Product
    WHERE ListPrice > 0
)
SELECT 
    p.Name AS ProductName,
    pc.Name AS Category,
    p.ListPrice,
    ca.CategoryAvgPrice,
    oa.OverallAvgPrice,
    p.ListPrice - ca.CategoryAvgPrice AS VsCategoryAvg,
    p.ListPrice - oa.OverallAvgPrice AS VsOverallAvg,
    CASE 
        WHEN p.ListPrice > ca.CategoryAvgPrice AND p.ListPrice > oa.OverallAvgPrice 
            THEN 'Premium'
        WHEN p.ListPrice < ca.CategoryAvgPrice AND p.ListPrice < oa.OverallAvgPrice 
            THEN 'Budget'
        ELSE 'Mid-Range'
    END AS PricePosition
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
INNER JOIN CategoryAvg ca ON ps.ProductCategoryID = ca.ProductCategoryID
CROSS JOIN OverallAvg oa
WHERE p.ListPrice > 0
ORDER BY pc.Name, p.ListPrice DESC;

-- ============================================================================
-- EXAMPLE 5: CTE WITH INSERT, UPDATE, DELETE
-- ============================================================================
/*
CTEs aren't just for SELECT - you can use them with data modification!
*/

-- Example: UPDATE using CTE (mark inactive products)
-- (Commented out to prevent accidental execution)
/*
WITH InactiveProducts AS
(
    SELECT ProductID
    FROM Production.Product p
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Sales.SalesOrderDetail sod 
        WHERE sod.ProductID = p.ProductID
    )
    AND p.SellEndDate IS NOT NULL
)
UPDATE p
SET p.DiscontinuedDate = GETDATE()
FROM Production.Product p
INNER JOIN InactiveProducts ip ON p.ProductID = ip.ProductID;
*/

-- Example: DELETE using CTE
/*
WITH OldOrders AS
(
    SELECT SalesOrderID
    FROM Sales.SalesOrderHeader
    WHERE OrderDate < DATEADD(YEAR, -10, GETDATE())
)
DELETE FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN (SELECT SalesOrderID FROM OldOrders);
*/

-- ============================================================================
-- SECTION 2: RECURSIVE CTEs
-- ============================================================================
/*
WHAT IS A RECURSIVE CTE?
------------------------
A recursive CTE calls ITSELF to process hierarchical or sequential data.
Think: organization charts, file systems, category trees, date ranges.

STRUCTURE OF RECURSIVE CTE:
---------------------------
WITH RecursiveCTE AS
(
    -- ANCHOR MEMBER: Starting point (base case)
    SELECT ... 
    
    UNION ALL
    
    -- RECURSIVE MEMBER: Calls itself
    SELECT ...
    FROM RecursiveCTE  -- References itself!
    WHERE ...  -- Termination condition
)
SELECT * FROM RecursiveCTE;

RULES FOR RECURSIVE CTEs:
-------------------------
1. Must have exactly ONE UNION ALL between anchor and recursive member
2. Recursive member MUST reference the CTE
3. MUST have a termination condition (or infinite loop!)
4. Default limit is 100 recursions (use OPTION (MAXRECURSION n) to change)
*/

-- EXAMPLE 6: Generate a Number Sequence
-- ============================================================================
/*
Generate numbers 1 to 20. Simple but shows the recursion pattern.
*/

WITH Numbers AS
(
    -- Anchor: Start with 1
    SELECT 1 AS Number
    
    UNION ALL
    
    -- Recursive: Add 1 to previous number
    SELECT Number + 1
    FROM Numbers
    WHERE Number < 20  -- Termination: Stop at 20
)
SELECT Number FROM Numbers;

-- EXAMPLE 7: Generate Date Range
-- ============================================================================
/*
Generate all dates in January 2024 - useful for calendar reports
*/

WITH DateRange AS
(
    -- Anchor: First day of month
    SELECT CAST('2024-01-01' AS DATE) AS TheDate
    
    UNION ALL
    
    -- Recursive: Add one day
    SELECT DATEADD(DAY, 1, TheDate)
    FROM DateRange
    WHERE TheDate < '2024-01-31'  -- Termination: End of month
)
SELECT 
    TheDate,
    DATENAME(WEEKDAY, TheDate) AS DayOfWeek,
    DATEPART(WEEK, TheDate) AS WeekNumber,
    CASE WHEN DATEPART(WEEKDAY, TheDate) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS DayType
FROM DateRange;

-- EXAMPLE 8: Employee Hierarchy (Organization Chart)
-- ============================================================================
/*
Build a complete org chart showing reporting relationships and levels
*/

WITH OrgChart AS
(
    -- Anchor: Find the top-level manager (CEO - no manager)
    SELECT 
        e.BusinessEntityID AS EmployeeID,
        p.FirstName + ' ' + p.LastName AS EmployeeName,
        e.JobTitle,
        CAST(NULL AS INT) AS ManagerID,
        CAST(NULL AS NVARCHAR(200)) AS ManagerName,
        0 AS HierarchyLevel,
        CAST(p.FirstName + ' ' + p.LastName AS NVARCHAR(MAX)) AS ReportingPath
    FROM HumanResources.Employee e
    INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    WHERE e.BusinessEntityID NOT IN (
        SELECT DISTINCT OrganizationNode.GetAncestor(1).GetHashCode() 
        FROM HumanResources.Employee 
        WHERE OrganizationNode.GetAncestor(1) IS NOT NULL
    )
    AND e.JobTitle = 'Chief Executive Officer'
    
    UNION ALL
    
    -- Recursive: Find all employees who report to current level
    SELECT 
        e.BusinessEntityID,
        p.FirstName + ' ' + p.LastName,
        e.JobTitle,
        oc.EmployeeID,
        oc.EmployeeName,
        oc.HierarchyLevel + 1,
        oc.ReportingPath + ' > ' + p.FirstName + ' ' + p.LastName
    FROM HumanResources.Employee e
    INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    INNER JOIN OrgChart oc ON e.OrganizationNode.GetAncestor(1) = 
        (SELECT e2.OrganizationNode FROM HumanResources.Employee e2 WHERE e2.BusinessEntityID = oc.EmployeeID)
)
SELECT 
    EmployeeID,
    REPLICATE('    ', HierarchyLevel) + EmployeeName AS IndentedName,
    JobTitle,
    ManagerName,
    HierarchyLevel,
    ReportingPath
FROM OrgChart
ORDER BY ReportingPath
OPTION (MAXRECURSION 10);  -- Limit depth to prevent infinite loops

-- ============================================================================
-- SECTION 3: CTE vs SUBQUERY vs TEMP TABLE - WHEN TO USE WHICH?
-- ============================================================================
/*
COMPARISON TABLE:
--------------------------------------------------------------------------------
| Feature              | CTE           | Subquery      | Temp Table           |
--------------------------------------------------------------------------------
| Readability          | ✅ Excellent  | ⚠️ Can nest   | ✅ Good              |
| Multiple references  | ✅ Yes        | ❌ Must repeat| ✅ Yes               |
| Scope                | Single query  | Single query  | Session or procedure |
| Performance          | Same as sub   | Same as CTE   | Better for large data|
| Indexing             | ❌ No         | ❌ No         | ✅ Yes               |
| Recursion            | ✅ Yes        | ❌ No         | ❌ No (need loops)   |
| Reusable             | ❌ No         | ❌ No         | ✅ Yes               |
--------------------------------------------------------------------------------

WHEN TO USE EACH:

USE CTE WHEN:
✓ Breaking down complex queries for readability
✓ Need to reference result set multiple times in ONE query
✓ Working with hierarchical/recursive data
✓ Self-documenting code is important

USE SUBQUERY WHEN:
✓ Simple, one-time calculations
✓ EXISTS/NOT EXISTS checks
✓ Inline in WHERE clause
✓ Performance is identical to CTE

USE TEMP TABLE WHEN:
✓ Result set needed across multiple statements
✓ Large data sets (can add indexes)
✓ Complex processing with multiple steps
✓ Need to persist data during a session

PERFORMANCE NOTE:
-----------------
CTEs and subqueries are OPTIMIZED THE SAME WAY by SQL Server!
The query optimizer treats them identically.
Choose based on READABILITY, not performance.
*/

-- ============================================================================
-- SECTION 4: COMMON MISTAKES AND HOW TO AVOID THEM
-- ============================================================================
/*
MISTAKE 1: Forgetting that CTE expires after one statement
*/

-- This FAILS:
/*
WITH MyCTE AS (SELECT 1 AS Value);
SELECT * FROM MyCTE;  -- ERROR: Invalid object name 'MyCTE'
SELECT * FROM MyCTE;  -- CTE no longer exists!
*/

-- CORRECT: Use CTE immediately
WITH MyCTE AS (SELECT 1 AS Value)
SELECT * FROM MyCTE;

/*
MISTAKE 2: Not providing termination condition in recursive CTE
*/

-- This will ERROR after 100 iterations:
/*
WITH Infinite AS
(
    SELECT 1 AS N
    UNION ALL
    SELECT N + 1 FROM Infinite  -- No WHERE clause = infinite!
)
SELECT * FROM Infinite;
*/

-- CORRECT: Always include termination
WITH SafeCTE AS
(
    SELECT 1 AS N
    UNION ALL
    SELECT N + 1 FROM SafeCTE
    WHERE N < 100  -- Termination condition
)
SELECT * FROM SafeCTE;

/*
MISTAKE 3: Trying to use CTE in a view without WITH at the start
*/

-- Views with CTEs work, but syntax matters:
/*
CREATE VIEW vw_ProductAnalysis AS
WITH ProductStats AS (SELECT ...)  -- This works!
SELECT * FROM ProductStats;
*/

-- ============================================================================
-- SECTION 5: PRACTICE EXERCISES
-- ============================================================================

/*
EXERCISE 1: Simple CTE
-----------------------
Create a CTE that finds all employees hired in 2013.
Include: EmployeeID, Name, HireDate, JobTitle
*/
-- Your solution here:



/*
EXERCISE 2: Multiple CTEs
-------------------------
Create a 3-CTE pipeline:
1. MonthlySales: Total sales per month in 2013
2. Quarterlysales: Aggregate monthly sales into quarters
3. Final: Show Q-over-Q growth percentage
*/
-- Your solution here:



/*
EXERCISE 3: Recursive CTE
-------------------------
Generate a multiplication table (1-10 × 1-10)
Output: Num1, Num2, Product
*/
-- Your solution here:



-- ============================================================================
-- SECTION 6: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: CTEs - Top 15 Questions
================================================================================

Q1: What is a CTE and why would you use it?
A1: A CTE (Common Table Expression) is a temporary named result set defined 
    within a single SQL statement using the WITH clause. Use cases:
    - Improve query readability
    - Reference a subquery multiple times
    - Recursive queries for hierarchical data
    - Self-documenting code

Q2: What's the difference between a CTE and a temporary table?
A2: 
    CTE:
    - Exists only for ONE statement
    - Cannot be indexed
    - Stored in memory (no I/O)
    - Good for readability
    
    Temp Table:
    - Persists until dropped or session ends
    - Can be indexed
    - Stored in tempdb (I/O overhead)
    - Good for large datasets, multiple uses

Q3: Can a CTE improve query performance?
A3: Generally NO - CTEs and subqueries are optimized identically by SQL Server.
    CTEs improve READABILITY, not performance. For performance, use temp tables
    with indexes, or indexed views.

Q4: What are the two parts of a recursive CTE?
A4: 
    1. ANCHOR MEMBER: The base case that starts the recursion
    2. RECURSIVE MEMBER: The part that references the CTE itself
    They are connected with UNION ALL.

Q5: What is MAXRECURSION and when do you use it?
A5: MAXRECURSION limits recursive iterations (default = 100).
    Use OPTION (MAXRECURSION n) to change:
    - MAXRECURSION 0 = unlimited (dangerous!)
    - MAXRECURSION 500 = allow up to 500 iterations

Q6: Can you have multiple CTEs in one query?
A6: Yes! Separate them with commas. Later CTEs can reference earlier ones:
    WITH CTE1 AS (...), CTE2 AS (SELECT * FROM CTE1), CTE3 AS (...)
    SELECT * FROM CTE3;

Q7: Can you UPDATE or DELETE using a CTE?
A7: Yes! The CTE can be the target of UPDATE/DELETE:
    WITH ToDelete AS (SELECT * FROM Table WHERE condition)
    DELETE FROM ToDelete;

Q8: What's the difference between CTE and subquery?
A8: 
    - Syntax: CTE uses WITH clause, subquery is inline
    - Reusability: CTE can be referenced multiple times
    - Recursion: Only CTEs support recursion
    - Performance: Identical (same execution plan)

Q9: Name 3 real-world uses for recursive CTEs.
A9: 
    1. Organization charts (employee hierarchies)
    2. Bill of Materials (product components)
    3. Category trees (nested categories)
    4. File system paths
    5. Network graphs (friend-of-friend)

Q10: What happens if a recursive CTE has no termination condition?
A10: It will run until MAXRECURSION limit (default 100), then error:
     "The maximum recursion 100 has been exhausted before statement completion."

Q11: Can you use ORDER BY inside a CTE?
A11: Only with TOP, OFFSET/FETCH, or FOR XML. Otherwise, ORDER BY 
     belongs in the outer SELECT, not inside the CTE.

Q12: Can a CTE reference itself in a non-recursive context?
A12: No - self-reference is only allowed in recursive CTEs. A CTE can
     reference OTHER CTEs defined before it, but not itself unless recursive.

Q13: How do you handle infinite loops in recursive CTEs?
A13: Three approaches:
     1. Proper WHERE clause termination
     2. Set MAXRECURSION limit
     3. Track visited nodes (add path/visited column)

Q14: Can you use CTEs in stored procedures, functions, and views?
A14: Yes, all of them! Just ensure the WITH is the first statement
     (after any SET statements in procedures).

Q15: What are the limitations of CTEs?
A15: 
     - Scope limited to single statement
     - Cannot be indexed
     - Cannot be used in a different batch
     - Column names must be unique
     - Must be followed immediately by SELECT/INSERT/UPDATE/DELETE

================================================================================
CODING CHALLENGE (Common Interview Problem):
================================================================================
"Write a query to find all employees and their complete management chain 
up to the CEO. Include each level in the hierarchy."

SOLUTION:
*/

WITH ManagementChain AS
(
    -- Anchor: Start with each employee
    SELECT 
        e.BusinessEntityID AS EmployeeID,
        p.FirstName + ' ' + p.LastName AS EmployeeName,
        e.JobTitle,
        e.BusinessEntityID AS CurrentManagerID,
        p.FirstName + ' ' + p.LastName AS CurrentManagerName,
        0 AS Level
    FROM HumanResources.Employee e
    INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    
    UNION ALL
    
    -- Recursive: Find the manager of the current manager
    SELECT 
        mc.EmployeeID,
        mc.EmployeeName,
        mc.JobTitle,
        e.BusinessEntityID,
        p.FirstName + ' ' + p.LastName,
        mc.Level + 1
    FROM ManagementChain mc
    INNER JOIN HumanResources.Employee e 
        ON mc.CurrentManagerID != mc.EmployeeID  -- Prevent self-reference
        AND e.OrganizationNode = (
            SELECT e2.OrganizationNode.GetAncestor(1)
            FROM HumanResources.Employee e2 
            WHERE e2.BusinessEntityID = mc.CurrentManagerID
        )
    INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    WHERE mc.Level < 10  -- Safety limit
)
SELECT * FROM ManagementChain 
WHERE Level > 0  -- Exclude self
ORDER BY EmployeeID, Level
OPTION (MAXRECURSION 10);

/*
================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand basic CTE syntax and structure
□ Created single CTEs for readability
□ Built multi-CTE pipelines
□ Used recursive CTEs for hierarchical data
□ Know when to use CTE vs Temp Table vs Subquery
□ Can answer interview questions confidently
□ Completed practice exercises

NEXT LAB: Lab 12 - Recursive CTEs Deep Dive
================================================================================
*/
