/*
================================================================================
LAB 06 (ENHANCED): SQL JOINS - COMPLETE GUIDE
Module 02: SQL Fundamentals
================================================================================

WHAT YOU WILL LEARN:
✅ All JOIN types explained with visual diagrams
✅ When and why to use each JOIN type
✅ INNER JOIN - matching records only
✅ LEFT/RIGHT JOIN - all from one side
✅ FULL OUTER JOIN - all from both sides
✅ CROSS JOIN - cartesian product
✅ SELF JOIN - table joined to itself
✅ Multiple table JOINs
✅ JOIN performance considerations
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐ (Intermediate)
DATABASE: AdventureWorks2022

================================================================================
SECTION 1: UNDERSTANDING JOINS - THE FUNDAMENTALS
================================================================================

WHAT IS A JOIN?
---------------
A JOIN combines rows from two or more tables based on a related column.
JOINs are the foundation of relational databases - they're how we 
connect data spread across multiple tables.

WHY DO WE NEED JOINS?
---------------------
Relational databases NORMALIZE data into separate tables to:
- Reduce redundancy (don't repeat customer info on every order)
- Maintain consistency (update in one place)
- Save storage space

JOINs let us recombine this data when we need it.

THE 7 TYPES OF JOINS:
---------------------
1. INNER JOIN    - Only matching rows
2. LEFT JOIN     - All left + matching right
3. RIGHT JOIN    - All right + matching left
4. FULL OUTER    - All from both sides
5. CROSS JOIN    - Every combination (cartesian product)
6. SELF JOIN     - Table joined to itself
7. NATURAL JOIN  - Auto-match on column names (avoid in production!)

VISUAL REPRESENTATION:
----------------------
Consider two tables:
Table A (Customers): [1, 2, 3, 4]
Table B (Orders):    [2, 3, 3, 5]

INNER JOIN:     [2, 3]           Only rows with matching IDs
LEFT JOIN:      [1, 2, 3, 4]     All from A, matching from B
RIGHT JOIN:     [2, 3, 5]        All from B, matching from A
FULL OUTER:     [1, 2, 3, 4, 5]  All from both, NULLs where no match
CROSS JOIN:     4 × 4 = 16 rows  Every combination
*/

USE AdventureWorks2022;
GO

-- ============================================================================
-- SETUP: Create simple sample tables for clear examples
-- ============================================================================

-- Drop if exists
IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;
IF OBJECT_ID('tempdb..#Orders') IS NOT NULL DROP TABLE #Orders;

CREATE TABLE #Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(50),
    City NVARCHAR(50)
);

CREATE TABLE #Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    Amount DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO #Customers VALUES 
    (1, 'Alice', 'New York'),
    (2, 'Bob', 'Chicago'),
    (3, 'Carol', 'Los Angeles'),
    (4, 'David', 'Houston');  -- No orders

INSERT INTO #Orders VALUES
    (101, 2, '2024-01-15', 500.00),   -- Bob
    (102, 2, '2024-01-20', 750.00),   -- Bob
    (103, 3, '2024-02-01', 1200.00),  -- Carol
    (104, 3, '2024-02-15', 300.00),   -- Carol
    (105, 5, '2024-03-01', 450.00);   -- CustomerID 5 doesn't exist!

-- View our sample data
SELECT 'Customers' AS TableName, * FROM #Customers;
SELECT 'Orders' AS TableName, * FROM #Orders;

-- ============================================================================
-- SECTION 2: INNER JOIN
-- ============================================================================
/*
INNER JOIN: Returns ONLY rows that have matching values in BOTH tables.

VISUAL:
    Customers         Orders           INNER JOIN Result
    ┌───────┐        ┌───────┐        ┌─────────────────┐
    │ 1-Alice│        │ 101-2 │        │ 2-Bob   │ 101   │
    │ 2-Bob  │───────▶│ 102-2 │───────▶│ 2-Bob   │ 102   │
    │ 3-Carol│───────▶│ 103-3 │        │ 3-Carol │ 103   │
    │ 4-David│        │ 104-3 │        │ 3-Carol │ 104   │
    └───────┘        │ 105-5 │        └─────────────────┘
                     └───────┘
    
    Alice (1) - No match in Orders → EXCLUDED
    David (4) - No match in Orders → EXCLUDED
    Order 105 (CustomerID 5) - No match in Customers → EXCLUDED

WHEN TO USE:
- You only want data where there's a relationship in BOTH tables
- Most common JOIN type (probably 80% of queries)
- Reporting where incomplete data should be excluded
*/

-- Syntax Option 1: Explicit JOIN (RECOMMENDED)
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City,
    o.OrderID,
    o.OrderDate,
    o.Amount
FROM #Customers c
INNER JOIN #Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID, o.OrderID;

-- Result: 4 rows (Bob × 2, Carol × 2)
-- Alice and David are EXCLUDED (no orders)
-- Order 105 is EXCLUDED (customer doesn't exist)

-- Syntax Option 2: Implicit JOIN (old style, avoid)
SELECT c.*, o.*
FROM #Customers c, #Orders o
WHERE c.CustomerID = o.CustomerID;  -- Same result but harder to read

-- ============================================================================
-- SECTION 3: LEFT JOIN (LEFT OUTER JOIN)
-- ============================================================================
/*
LEFT JOIN: Returns ALL rows from the LEFT table, and matching rows from 
the right table. Non-matching right rows show as NULL.

VISUAL:
    Customers (LEFT)  Orders (RIGHT)   LEFT JOIN Result
    ┌───────┐        ┌───────┐        ┌──────────────────────┐
    │ 1-Alice│────────────────────────▶│ 1-Alice │ NULL       │
    │ 2-Bob  │───────▶│ 101-2 │───────▶│ 2-Bob   │ 101        │
    │        │───────▶│ 102-2 │───────▶│ 2-Bob   │ 102        │
    │ 3-Carol│───────▶│ 103-3 │        │ 3-Carol │ 103        │
    │        │───────▶│ 104-3 │        │ 3-Carol │ 104        │
    │ 4-David│────────────────────────▶│ 4-David │ NULL       │
    └───────┘        │ 105-5 │        └──────────────────────┘
                     └───────┘         Order 105 excluded!

WHEN TO USE:
- You need ALL records from the main table
- Finding records WITHOUT matches (customers without orders)
- Reporting where you need complete list from one side
- Master-detail relationships where master is required
*/

SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City,
    o.OrderID,
    o.Amount
FROM #Customers c
LEFT JOIN #Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID;

-- Result: 6 rows (all 4 customers shown)
-- Alice and David have NULL for order columns

-- PRACTICAL USE: Find customers WITHOUT orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City
FROM #Customers c
LEFT JOIN #Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;  -- Filter for non-matches

-- Result: Alice and David (customers with no orders)

-- ============================================================================
-- SECTION 4: RIGHT JOIN (RIGHT OUTER JOIN)
-- ============================================================================
/*
RIGHT JOIN: Returns ALL rows from the RIGHT table, and matching rows from 
the left table. Non-matching left rows show as NULL.

RIGHT JOIN is essentially LEFT JOIN with tables swapped.
Most developers prefer LEFT JOIN (easier to read left-to-right).

VISUAL:
    Customers (LEFT)  Orders (RIGHT)   RIGHT JOIN Result
    ┌───────┐        ┌───────┐        ┌──────────────────────┐
    │ 2-Bob  │◀──────│ 101-2 │───────▶│ 2-Bob   │ 101        │
    │        │◀──────│ 102-2 │───────▶│ 2-Bob   │ 102        │
    │ 3-Carol│◀──────│ 103-3 │───────▶│ 3-Carol │ 103        │
    │        │◀──────│ 104-3 │───────▶│ 3-Carol │ 104        │
    │ 1-Alice│       │ 105-5 │───────▶│ NULL    │ 105        │
    │ 4-David│       └───────┘        └──────────────────────┘
    └───────┘                          Customer 5 not in table!

WHEN TO USE:
- You need ALL records from the secondary table
- Finding orphan records (orders with invalid customers)
- Less common than LEFT JOIN (can rewrite as LEFT JOIN)
*/

SELECT 
    o.OrderID,
    o.Amount,
    c.CustomerID,
    c.CustomerName
FROM #Customers c
RIGHT JOIN #Orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderID;

-- Result: 5 rows (all orders shown)
-- Order 105 has NULL for customer columns (orphan record!)

-- Same result using LEFT JOIN (preferred style):
SELECT 
    o.OrderID,
    o.Amount,
    c.CustomerID,
    c.CustomerName
FROM #Orders o
LEFT JOIN #Customers c ON c.CustomerID = o.CustomerID
ORDER BY o.OrderID;

-- ============================================================================
-- SECTION 5: FULL OUTER JOIN
-- ============================================================================
/*
FULL OUTER JOIN: Returns ALL rows from BOTH tables.
Matching rows are combined, non-matching rows show NULL for the missing side.

VISUAL:
    Customers (LEFT)  Orders (RIGHT)   FULL JOIN Result
    ┌───────┐        ┌───────┐        ┌──────────────────────┐
    │ 1-Alice│────────────────────────▶│ 1-Alice │ NULL       │
    │ 2-Bob  │◀──────│ 101-2 │───────▶│ 2-Bob   │ 101        │
    │        │◀──────│ 102-2 │───────▶│ 2-Bob   │ 102        │
    │ 3-Carol│◀──────│ 103-3 │───────▶│ 3-Carol │ 103        │
    │        │◀──────│ 104-3 │───────▶│ 3-Carol │ 104        │
    │ 4-David│────────────────────────▶│ 4-David │ NULL       │
    └───────┘        │ 105-5 │───────▶│ NULL    │ 105        │
                     └───────┘        └──────────────────────┘

WHEN TO USE:
- Data reconciliation between systems
- Finding ALL discrepancies (both sides)
- Comparing two datasets for differences
- Less common in typical queries
*/

SELECT 
    c.CustomerID AS CustID,
    c.CustomerName,
    o.OrderID,
    o.CustomerID AS OrderCustID,
    o.Amount
FROM #Customers c
FULL OUTER JOIN #Orders o ON c.CustomerID = o.CustomerID
ORDER BY COALESCE(c.CustomerID, o.CustomerID);

-- Result: 7 rows (all records from both tables)
-- Includes: Customers without orders AND orders without valid customers

-- PRACTICAL USE: Find all mismatches
SELECT 
    COALESCE(c.CustomerID, o.CustomerID) AS ID,
    c.CustomerName,
    o.OrderID,
    CASE 
        WHEN c.CustomerID IS NULL THEN 'Orphan Order'
        WHEN o.OrderID IS NULL THEN 'Customer Without Orders'
        ELSE 'Matched'
    END AS Status
FROM #Customers c
FULL OUTER JOIN #Orders o ON c.CustomerID = o.CustomerID
ORDER BY Status, ID;

-- ============================================================================
-- SECTION 6: CROSS JOIN
-- ============================================================================
/*
CROSS JOIN: Returns the CARTESIAN PRODUCT of both tables.
Every row from table A is combined with every row from table B.

If Table A has 4 rows and Table B has 5 rows: Result = 4 × 5 = 20 rows

WARNING: Can create VERY large result sets!
         10,000 × 10,000 = 100,000,000 rows

VISUAL:
    Customers      Sizes           CROSS JOIN Result
    ┌───────┐     ┌─────┐         ┌────────────────┐
    │ Alice │     │ S   │         │ Alice │ S      │
    │ Bob   │  ×  │ M   │    =    │ Alice │ M      │
    └───────┘     │ L   │         │ Alice │ L      │
                  └─────┘         │ Bob   │ S      │
    2 × 3 = 6 rows                │ Bob   │ M      │
                                  │ Bob   │ L      │
                                  └────────────────┘

WHEN TO USE:
- Generate all possible combinations
- Creating a calendar table
- Generating test data
- Pairing every item with every category
*/

-- Create sizes table
CREATE TABLE #Sizes (Size VARCHAR(10));
INSERT INTO #Sizes VALUES ('Small'), ('Medium'), ('Large');

-- CROSS JOIN: Every customer × every size
SELECT 
    c.CustomerName,
    s.Size
FROM #Customers c
CROSS JOIN #Sizes s
ORDER BY c.CustomerName, 
    CASE s.Size WHEN 'Small' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;

-- Result: 4 customers × 3 sizes = 12 rows

-- PRACTICAL USE: Generate date calendar
WITH Dates AS (
    SELECT CAST('2024-01-01' AS DATE) AS TheDate
    UNION ALL
    SELECT DATEADD(DAY, 1, TheDate)
    FROM Dates
    WHERE TheDate < '2024-01-07'
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    d.TheDate
FROM #Customers c
CROSS JOIN Dates d
ORDER BY c.CustomerID, d.TheDate;

-- Result: All 7 dates for each of 4 customers = 28 rows

DROP TABLE #Sizes;

-- ============================================================================
-- SECTION 7: SELF JOIN
-- ============================================================================
/*
SELF JOIN: A table joined to ITSELF.
Used when rows in a table are related to OTHER ROWS in the same table.

COMMON USE CASES:
- Employee-Manager hierarchies
- Comparing rows within same table
- Finding duplicates
- Bill of materials (parent-child parts)

EXAMPLE SCENARIO: Employee reporting structure
    ID  | Name    | ManagerID
    1   | Alice   | NULL        (CEO - no manager)
    2   | Bob     | 1           (reports to Alice)
    3   | Carol   | 1           (reports to Alice)
    4   | David   | 2           (reports to Bob)
*/

-- Create employee hierarchy
IF OBJECT_ID('tempdb..#Employees') IS NOT NULL DROP TABLE #Employees;

CREATE TABLE #Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(50),
    ManagerID INT NULL
);

INSERT INTO #Employees VALUES
    (1, 'Alice CEO', NULL),
    (2, 'Bob VP', 1),
    (3, 'Carol VP', 1),
    (4, 'David Manager', 2),
    (5, 'Eve Engineer', 4),
    (6, 'Frank Engineer', 4);

-- SELF JOIN: Show each employee with their manager
SELECT 
    e.EmployeeID,
    e.EmployeeName AS Employee,
    e.ManagerID,
    m.EmployeeName AS Manager
FROM #Employees e
LEFT JOIN #Employees m ON e.ManagerID = m.EmployeeID  -- Join to SAME table
ORDER BY e.ManagerID, e.EmployeeID;

-- Result shows hierarchy with manager names

-- PRACTICAL USE: Find employees who earn more than their manager
-- (using AdventureWorks)
SELECT 
    emp.BusinessEntityID AS EmployeeID,
    empPerson.FirstName + ' ' + empPerson.LastName AS EmployeeName,
    emp.JobTitle,
    mgrPerson.FirstName + ' ' + mgrPerson.LastName AS ManagerName
FROM HumanResources.Employee emp
JOIN Person.Person empPerson ON emp.BusinessEntityID = empPerson.BusinessEntityID
JOIN HumanResources.Employee mgr ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
JOIN Person.Person mgrPerson ON mgr.BusinessEntityID = mgrPerson.BusinessEntityID
WHERE emp.BusinessEntityID <> mgr.BusinessEntityID;

-- ============================================================================
-- SECTION 8: MULTIPLE TABLE JOINS
-- ============================================================================
/*
You can chain multiple JOINs to connect 3, 4, 5+ tables.
Each JOIN adds columns from another table.

ORDER MATTERS for LEFT/RIGHT JOINs!
Process is left-to-right, each result becomes input for next JOIN.
*/

-- Example: Customers → Orders → Order Details → Products
-- (Using AdventureWorks)
SELECT TOP 20
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    soh.SalesOrderID,
    soh.OrderDate,
    sod.OrderQty,
    prod.Name AS ProductName,
    prod.ListPrice
FROM Sales.Customer c
INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
INNER JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product prod ON sod.ProductID = prod.ProductID
WHERE c.PersonID IS NOT NULL
ORDER BY soh.OrderDate DESC;

-- ============================================================================
-- SECTION 9: JOIN PERFORMANCE CONSIDERATIONS
-- ============================================================================
/*
JOIN OPTIMIZATION TIPS:

1. INDEXES:
   - JOIN columns should be indexed
   - Primary key and foreign key columns get indexes

2. JOIN ORDER:
   - Start with smallest table (fewer rows)
   - Filter early with WHERE clause

3. SELECT ONLY NEEDED COLUMNS:
   - Avoid SELECT *
   - Less data to move = faster

4. AVOID FUNCTIONS ON JOIN COLUMNS:
   - BAD:  ON UPPER(a.name) = b.name  (can't use index)
   - GOOD: ON a.name = b.name

5. USE APPROPRIATE JOIN TYPE:
   - INNER is fastest (fewest rows)
   - Avoid FULL OUTER if not needed
   - Never CROSS JOIN large tables accidentally

6. ANALYZE EXECUTION PLAN:
   - Look for table scans
   - Check estimated vs actual rows
*/

-- ============================================================================
-- SECTION 10: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: SQL JOINS - Top 15 Questions
================================================================================

Q1: What is the difference between INNER JOIN and LEFT JOIN?
A1: INNER JOIN returns only matching rows from both tables.
    LEFT JOIN returns ALL rows from left table plus matching from right.
    Non-matching rows from right show as NULL.

Q2: What is a CROSS JOIN?
A2: CROSS JOIN returns the Cartesian product - every row from table A 
    combined with every row from table B. Result size = A rows × B rows.
    Use carefully - can create massive result sets!

Q3: Can you explain SELF JOIN with an example?
A3: SELF JOIN is when a table is joined to itself, typically for 
    hierarchical data. Example: employee-manager relationship where
    ManagerID references EmployeeID in the same table.

Q4: What happens with NULL in JOIN conditions?
A4: NULL never equals anything, including NULL. So NULL = NULL is false.
    Rows with NULL in the join column won't match other NULL rows.
    Use IS NULL in WHERE clause to find them.

Q5: What's the difference between WHERE and ON in JOINs?
A5: ON: Defines the JOIN condition (how tables relate)
    WHERE: Filters the result set after JOINing
    
    For INNER JOIN: Same result either way
    For OUTER JOIN: WHERE filters AFTER join (removes NULLs)
                    ON filters DURING join (preserves NULLs)

Q6: How do you find records in table A that don't exist in table B?
A6: 
    -- Method 1: LEFT JOIN + NULL check
    SELECT a.* FROM TableA a
    LEFT JOIN TableB b ON a.id = b.id
    WHERE b.id IS NULL;
    
    -- Method 2: NOT EXISTS
    SELECT * FROM TableA a
    WHERE NOT EXISTS (SELECT 1 FROM TableB b WHERE b.id = a.id);

Q7: What is an equi-join vs non-equi join?
A7: Equi-join: Uses = operator (most common)
    Non-equi join: Uses <, >, <=, >=, <>, BETWEEN
    Example non-equi: Finding overlapping date ranges

Q8: How do you optimize JOIN performance?
A8: 
    - Index JOIN columns
    - Join on primary/foreign keys
    - Filter early (WHERE before SELECT)
    - Select only needed columns
    - Start with smaller tables
    - Avoid functions on join columns

Q9: What is a NATURAL JOIN and why avoid it?
A9: NATURAL JOIN automatically joins on columns with same names.
    Avoid because:
    - Implicit behavior can break if schema changes
    - Hard to read/maintain
    - May join on wrong columns accidentally

Q10: Explain the execution order of JOINs.
A10: JOINs are processed left-to-right in the FROM clause.
     Each JOIN result becomes input for the next.
     Optimizer may reorder INNER JOINs for efficiency.
     OUTER JOIN order matters and isn't reordered.

Q11: How do you join on multiple columns?
A11: Use AND in the ON clause:
     ON a.col1 = b.col1 AND a.col2 = b.col2
     Common for composite keys.

Q12: What is a semi-join?
A12: A semi-join returns rows from table A where matching rows exist in B,
     but doesn't return columns from B.
     Implemented with: EXISTS or IN subqueries
     SELECT * FROM A WHERE EXISTS (SELECT 1 FROM B WHERE A.id = B.id)

Q13: What's the difference between LEFT JOIN and LEFT OUTER JOIN?
A13: They are exactly the same! OUTER is optional.
     LEFT JOIN = LEFT OUTER JOIN
     Same for RIGHT and FULL.

Q14: How do you write a JOIN that returns only one row per left table row?
A14: Use ROW_NUMBER in a subquery or CTE:
     WITH Ranked AS (
         SELECT *, ROW_NUMBER() OVER (PARTITION BY leftID ORDER BY date) AS rn
         FROM RightTable
     )
     SELECT * FROM LeftTable l JOIN Ranked r ON l.id = r.leftID AND r.rn = 1

Q15: What causes a Cartesian product accidentally?
A15: 
     - Missing or incorrect JOIN condition
     - Using comma syntax without WHERE
     - Joining on columns that aren't unique
     Always verify row counts after JOINs!

================================================================================
*/

-- Cleanup
DROP TABLE #Customers;
DROP TABLE #Orders;
DROP TABLE #Employees;

/*
================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand all JOIN types (INNER, LEFT, RIGHT, FULL, CROSS, SELF)
□ Know when to use each JOIN type
□ Can find records that don't match
□ Can perform multi-table JOINs
□ Understand JOIN performance considerations
□ Can answer interview questions confidently
□ Practice with real database (AdventureWorks)

NEXT LAB: Lab 07 - Subqueries
================================================================================
*/
