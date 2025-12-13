/*
================================================================================
LAB 19 (ENHANCED): DATABASE NORMALIZATION - COMPLETE GUIDE
Module 04: Database Administration
================================================================================

WHAT YOU WILL LEARN:
✅ What normalization is and why it matters
✅ All normal forms (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
✅ How to identify normalization violations
✅ Step-by-step normalization process
✅ When to denormalize (and why)
✅ Real-world examples
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐ (Intermediate)

================================================================================
SECTION 1: UNDERSTANDING NORMALIZATION
================================================================================

WHAT IS NORMALIZATION?
----------------------
Normalization is the process of organizing data to:
1. ELIMINATE REDUNDANCY (same data stored multiple times)
2. ELIMINATE ANOMALIES (insert, update, delete problems)
3. ENSURE DATA INTEGRITY (data is consistent and correct)

WHY NORMALIZE?
--------------
Without normalization, you get:

REDUNDANCY PROBLEM:
┌──────────┬───────────────┬─────────────┬─────────────┐
│ OrderID  │ CustomerName  │ CustomerCity│ Product     │
├──────────┼───────────────┼─────────────┼─────────────┤
│ 1        │ John Smith    │ New York    │ Laptop      │
│ 2        │ John Smith    │ New York    │ Mouse       │  ← John's info repeated!
│ 3        │ John Smith    │ New York    │ Keyboard    │  ← And again!
│ 4        │ Jane Doe      │ Chicago     │ Monitor     │
└──────────┴───────────────┴─────────────┴─────────────┘

ANOMALY PROBLEMS:
1. INSERT ANOMALY: Can't add a customer without an order
2. UPDATE ANOMALY: John moves to Boston → update 3 rows!
3. DELETE ANOMALY: Delete order 4 → lose Jane's info completely!

NORMALIZED SOLUTION:
Customers Table:
┌────────────┬───────────────┬─────────────┐
│ CustomerID │ CustomerName  │ City        │
├────────────┼───────────────┼─────────────┤
│ 1          │ John Smith    │ New York    │
│ 2          │ Jane Doe      │ Chicago     │
└────────────┴───────────────┴─────────────┘

Orders Table:
┌──────────┬────────────┬─────────────┐
│ OrderID  │ CustomerID │ Product     │
├──────────┼────────────┼─────────────┤
│ 1        │ 1          │ Laptop      │
│ 2        │ 1          │ Mouse       │
│ 3        │ 1          │ Keyboard    │
│ 4        │ 2          │ Monitor     │
└──────────┴────────────┴─────────────┘

Now:
✓ John's info stored ONCE
✓ Update John's city = update 1 row
✓ Can add customers without orders
✓ Delete order doesn't lose customer

================================================================================
SECTION 2: FIRST NORMAL FORM (1NF)
================================================================================

RULE: 
1. Each column must contain ATOMIC (indivisible) values
2. Each column must contain values of a SINGLE type
3. Each row must be UNIQUE (have a primary key)
4. NO REPEATING GROUPS

BEFORE 1NF (Violations):
┌──────────┬───────────────┬─────────────────────────────┐
│ StudentID│ StudentName   │ PhoneNumbers                │
├──────────┼───────────────┼─────────────────────────────┤
│ 1        │ John Smith    │ 555-1234, 555-5678, 555-9999│  ← Multiple values!
│ 2        │ Jane Doe      │ 555-4321                    │
└──────────┴───────────────┴─────────────────────────────┘

Another 1NF violation (repeating groups):
┌──────────┬───────────────┬─────────┬─────────┬─────────┐
│ StudentID│ StudentName   │ Course1 │ Course2 │ Course3 │
├──────────┼───────────────┼─────────┼─────────┼─────────┤
│ 1        │ John Smith    │ Math    │ Science │ History │
│ 2        │ Jane Doe      │ Math    │ English │ NULL    │
└──────────┴───────────────┴─────────┴─────────┴─────────┘

AFTER 1NF:
Students Table:
┌──────────┬───────────────┐
│ StudentID│ StudentName   │
├──────────┼───────────────┤
│ 1        │ John Smith    │
│ 2        │ Jane Doe      │
└──────────┴───────────────┘

StudentPhones Table:
┌──────────┬─────────────┐
│ StudentID│ PhoneNumber │
├──────────┼─────────────┤
│ 1        │ 555-1234    │
│ 1        │ 555-5678    │
│ 1        │ 555-9999    │
│ 2        │ 555-4321    │
└──────────┴─────────────┘

StudentCourses Table:
┌──────────┬───────────┐
│ StudentID│ Course    │
├──────────┼───────────┤
│ 1        │ Math      │
│ 1        │ Science   │
│ 1        │ History   │
│ 2        │ Math      │
│ 2        │ English   │
└──────────┴───────────┘
*/

-- Practical Example: Converting to 1NF
CREATE TABLE #BadTable_1NF (
    OrderID INT,
    CustomerName NVARCHAR(100),
    Products NVARCHAR(500)  -- "Laptop, Mouse, Keyboard" - VIOLATION!
);

-- Fixed 1NF structure
CREATE TABLE #Orders_1NF (
    OrderID INT PRIMARY KEY,
    CustomerName NVARCHAR(100)
);

CREATE TABLE #OrderItems_1NF (
    OrderID INT,
    Product NVARCHAR(100),
    PRIMARY KEY (OrderID, Product)
);

/*
================================================================================
SECTION 3: SECOND NORMAL FORM (2NF)
================================================================================

RULE:
1. Must be in 1NF first
2. NO PARTIAL DEPENDENCIES - Non-key columns must depend on THE WHOLE primary key

Only applies to tables with COMPOSITE primary keys!

BEFORE 2NF:
Table: OrderItems (OrderID, ProductID, ProductName, Quantity, UnitPrice)
Primary Key: (OrderID, ProductID)

┌─────────┬───────────┬─────────────┬──────────┬───────────┐
│ OrderID │ ProductID │ ProductName │ Quantity │ UnitPrice │
├─────────┼───────────┼─────────────┼──────────┼───────────┤
│ 1       │ 101       │ Laptop      │ 2        │ 999.99    │
│ 1       │ 102       │ Mouse       │ 5        │ 29.99     │
│ 2       │ 101       │ Laptop      │ 1        │ 999.99    │  ← Laptop repeated!
└─────────┴───────────┴─────────────┴──────────┴───────────┘

DEPENDENCY ANALYSIS:
- Quantity depends on (OrderID, ProductID) ✓ FULL dependency
- ProductName depends on ProductID only ✗ PARTIAL dependency!
- UnitPrice depends on ProductID only ✗ PARTIAL dependency!

AFTER 2NF:
Products Table:
┌───────────┬─────────────┬───────────┐
│ ProductID │ ProductName │ UnitPrice │
├───────────┼─────────────┼───────────┤
│ 101       │ Laptop      │ 999.99    │
│ 102       │ Mouse       │ 29.99     │
└───────────┴─────────────┴───────────┘

OrderItems Table:
┌─────────┬───────────┬──────────┐
│ OrderID │ ProductID │ Quantity │
├─────────┼───────────┼──────────┤
│ 1       │ 101       │ 2        │
│ 1       │ 102       │ 5        │
│ 2       │ 101       │ 1        │
└─────────┴───────────┴──────────┘
*/

-- Example: Identifying 2NF violations
CREATE TABLE #BadTable_2NF (
    OrderID INT,
    ProductID INT,
    ProductName NVARCHAR(100),  -- Depends on ProductID only!
    CategoryName NVARCHAR(100), -- Depends on ProductID only!
    Quantity INT,
    PRIMARY KEY (OrderID, ProductID)
);

-- Fixed 2NF structure
CREATE TABLE #Products_2NF (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    CategoryName NVARCHAR(100)
);

CREATE TABLE #OrderItems_2NF (
    OrderID INT,
    ProductID INT,
    Quantity INT,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (ProductID) REFERENCES #Products_2NF(ProductID)
);

/*
================================================================================
SECTION 4: THIRD NORMAL FORM (3NF)
================================================================================

RULE:
1. Must be in 2NF first
2. NO TRANSITIVE DEPENDENCIES - Non-key columns must not depend on other non-key columns

"Every non-key column must depend on the key, the WHOLE key, and NOTHING BUT the key"

BEFORE 3NF:
Employees Table:
┌────────────┬──────────────┬────────────┬──────────────────┐
│ EmployeeID │ EmployeeName │ DeptID     │ DeptName         │
├────────────┼──────────────┼────────────┼──────────────────┤
│ 1          │ John Smith   │ 10         │ Engineering      │
│ 2          │ Jane Doe     │ 10         │ Engineering      │  ← DeptName repeated!
│ 3          │ Bob Wilson   │ 20         │ Marketing        │
└────────────┴──────────────┴────────────┴──────────────────┘

DEPENDENCY ANALYSIS:
- EmployeeName depends on EmployeeID ✓
- DeptID depends on EmployeeID ✓
- DeptName depends on DeptID ✗ TRANSITIVE DEPENDENCY!
  (DeptName → DeptID → EmployeeID)

AFTER 3NF:
Departments Table:
┌────────────┬──────────────────┐
│ DeptID     │ DeptName         │
├────────────┼──────────────────┤
│ 10         │ Engineering      │
│ 20         │ Marketing        │
└────────────┴──────────────────┘

Employees Table:
┌────────────┬──────────────┬────────────┐
│ EmployeeID │ EmployeeName │ DeptID     │
├────────────┼──────────────┼────────────┤
│ 1          │ John Smith   │ 10         │
│ 2          │ Jane Doe     │ 10         │
│ 3          │ Bob Wilson   │ 20         │
└────────────┴──────────────┴────────────┘
*/

-- Example: Identifying 3NF violations
CREATE TABLE #BadTable_3NF (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(100),
    DeptID INT,
    DeptName NVARCHAR(100),    -- Transitive: DeptName depends on DeptID!
    DeptLocation NVARCHAR(100) -- Also transitive!
);

-- Fixed 3NF structure
CREATE TABLE #Departments_3NF (
    DeptID INT PRIMARY KEY,
    DeptName NVARCHAR(100),
    DeptLocation NVARCHAR(100)
);

CREATE TABLE #Employees_3NF (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(100),
    DeptID INT FOREIGN KEY REFERENCES #Departments_3NF(DeptID)
);

/*
================================================================================
SECTION 5: BOYCE-CODD NORMAL FORM (BCNF)
================================================================================

RULE:
1. Must be in 3NF first
2. For every functional dependency X → Y, X must be a SUPERKEY

BCNF is a stricter version of 3NF. 
Difference: 3NF allows non-prime attributes to be determined by candidate keys,
BCNF requires that ALL determinants are candidate keys.

EXAMPLE - 3NF but not BCNF:
CourseRegistration:
┌─────────┬────────────┬───────────────┐
│ Student │ Course     │ Instructor    │
├─────────┼────────────┼───────────────┤
│ John    │ Database   │ Prof. Smith   │
│ Jane    │ Database   │ Prof. Smith   │
│ John    │ Networks   │ Prof. Jones   │
│ Bob     │ Networks   │ Prof. Brown   │
└─────────┴────────────┴───────────────┘

Constraints:
- Each student takes each course once: (Student, Course) → Instructor
- Each instructor teaches only ONE course: Instructor → Course

Problem: Instructor determines Course, but Instructor is NOT a superkey!

BCNF Solution:
StudentInstructor:
┌─────────┬───────────────┐
│ Student │ Instructor    │
├─────────┼───────────────┤
│ John    │ Prof. Smith   │
│ Jane    │ Prof. Smith   │
│ John    │ Prof. Jones   │
│ Bob     │ Prof. Brown   │
└─────────┴───────────────┘

InstructorCourse:
┌───────────────┬────────────┐
│ Instructor    │ Course     │
├───────────────┼────────────┤
│ Prof. Smith   │ Database   │
│ Prof. Jones   │ Networks   │
│ Prof. Brown   │ Networks   │
└───────────────┴────────────┘
*/

/*
================================================================================
SECTION 6: FOURTH NORMAL FORM (4NF)
================================================================================

RULE:
1. Must be in BCNF first
2. NO MULTI-VALUED DEPENDENCIES

Multi-valued dependency: A → →B means A determines a SET of B values,
independent of other attributes.

EXAMPLE - BCNF but not 4NF:
EmployeeSkillsLanguages:
┌────────────┬──────────────┬──────────┐
│ Employee   │ Skill        │ Language │
├────────────┼──────────────┼──────────┤
│ John       │ Java         │ English  │
│ John       │ Java         │ Spanish  │
│ John       │ Python       │ English  │
│ John       │ Python       │ Spanish  │
└────────────┴──────────────┴──────────┘

Problem: John's skills and languages are INDEPENDENT of each other,
but we must repeat every combination!

4NF Solution:
EmployeeSkills:
┌────────────┬──────────────┐
│ Employee   │ Skill        │
├────────────┼──────────────┤
│ John       │ Java         │
│ John       │ Python       │
└────────────┴──────────────┘

EmployeeLanguages:
┌────────────┬──────────────┐
│ Employee   │ Language     │
├────────────┼──────────────┤
│ John       │ English      │
│ John       │ Spanish      │
└────────────┴──────────────┘
*/

/*
================================================================================
SECTION 7: FIFTH NORMAL FORM (5NF)
================================================================================

RULE:
1. Must be in 4NF first
2. Table cannot be decomposed into smaller tables without losing information

5NF handles JOIN DEPENDENCIES - when data reconstruction requires 
joining more than 2 tables.

This is rarely encountered in practice. Most databases only need to reach 3NF.
*/

/*
================================================================================
SECTION 8: NORMALIZATION SUMMARY CHART
================================================================================

┌────────┬────────────────────────────────────────────────────────────────┐
│ Form   │ Rule                                                           │
├────────┼────────────────────────────────────────────────────────────────┤
│ 1NF    │ Atomic values, no repeating groups, unique rows                │
├────────┼────────────────────────────────────────────────────────────────┤
│ 2NF    │ 1NF + No partial dependencies (on composite keys)              │
├────────┼────────────────────────────────────────────────────────────────┤
│ 3NF    │ 2NF + No transitive dependencies                               │
├────────┼────────────────────────────────────────────────────────────────┤
│ BCNF   │ 3NF + All determinants are candidate keys                      │
├────────┼────────────────────────────────────────────────────────────────┤
│ 4NF    │ BCNF + No multi-valued dependencies                            │
├────────┼────────────────────────────────────────────────────────────────┤
│ 5NF    │ 4NF + No join dependencies                                     │
└────────┴────────────────────────────────────────────────────────────────┘

PRACTICAL GUIDANCE:
- Most OLTP databases aim for 3NF
- Some data warehouses use 2NF or even denormalized star schemas
- BCNF is ideal but sometimes sacrificed for query performance
- 4NF and 5NF are rarely needed in practice
*/

/*
================================================================================
SECTION 9: DENORMALIZATION - WHEN AND WHY
================================================================================

Denormalization = Intentionally adding redundancy for PERFORMANCE

WHEN TO DENORMALIZE:
--------------------
✓ Read-heavy workloads (reporting, analytics)
✓ Complex JOINs causing performance issues
✓ Data warehouse/OLAP environments
✓ Aggregate values needed frequently
✓ Historical snapshots required

DENORMALIZATION TECHNIQUES:
---------------------------
1. ADDING REDUNDANT COLUMNS
   - Store calculated values
   - Store frequently joined data
   
2. PRE-COMPUTED AGGREGATES
   - Store running totals
   - Store counts and sums

3. STAR SCHEMA
   - Fact tables with foreign keys
   - Dimension tables with denormalized attributes

EXAMPLE: Adding redundant data for performance
*/

-- Normalized (multiple JOINs needed)
CREATE TABLE #Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(50)
);

CREATE TABLE #Products (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    CategoryID INT,
    UnitPrice DECIMAL(10,2)
);

CREATE TABLE #OrderDetails (
    OrderID INT,
    ProductID INT,
    Quantity INT,
    PRIMARY KEY (OrderID, ProductID)
);

-- Query requires 3 JOINs
/*
SELECT c.CategoryName, SUM(od.Quantity * p.UnitPrice) as Revenue
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName;
*/

-- Denormalized for reporting (redundant data)
CREATE TABLE #OrderDetails_Denorm (
    OrderID INT,
    ProductID INT,
    ProductName NVARCHAR(100),  -- Redundant!
    CategoryName NVARCHAR(50),   -- Redundant!
    Quantity INT,
    UnitPrice DECIMAL(10,2),     -- Redundant!
    LineTotal AS (Quantity * UnitPrice),  -- Calculated!
    PRIMARY KEY (OrderID, ProductID)
);

-- Query is much simpler and faster
/*
SELECT CategoryName, SUM(LineTotal) as Revenue
FROM OrderDetails_Denorm
GROUP BY CategoryName;
*/

/*
================================================================================
SECTION 10: PRACTICAL NORMALIZATION EXERCISE
================================================================================

SCENARIO: Normalize this messy table

BEFORE (Unnormalized):
┌─────────┬──────────┬────────────┬────────────────────┬─────────────────────────────┬─────────────────────┐
│ OrderNo │ CustName │ CustPhone  │ CustAddress        │ Products                    │ OrderTotal          │
├─────────┼──────────┼────────────┼────────────────────┼─────────────────────────────┼─────────────────────┤
│ 1001    │ John     │ 555-1234   │ 123 Main St, NYC   │ Laptop:999.99:1, Mouse:29:2 │ 1057.99             │
│ 1002    │ John     │ 555-1234   │ 123 Main St, NYC   │ Keyboard:49.99:1            │ 49.99               │
│ 1003    │ Jane     │ 555-4321   │ 456 Oak Ave, CHI   │ Monitor:299:1, Mouse:29:1   │ 328.00              │
└─────────┴──────────┴────────────┴────────────────────┴─────────────────────────────┴─────────────────────┘

PROBLEMS:
- Products column has multiple values (violates 1NF)
- Customer info repeated (violates 2NF/3NF)
- Address could be split (Street, City)
- OrderTotal is calculated (should be derived)
*/

-- STEP 1: Convert to 1NF (atomic values)
CREATE TABLE #Step1_Customers (
    CustomerID INT IDENTITY PRIMARY KEY,
    CustomerName NVARCHAR(100),
    CustomerPhone NVARCHAR(20),
    Street NVARCHAR(200),
    City NVARCHAR(100)
);

CREATE TABLE #Step1_Products (
    ProductID INT IDENTITY PRIMARY KEY,
    ProductName NVARCHAR(100),
    UnitPrice DECIMAL(10,2)
);

CREATE TABLE #Step1_Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE DEFAULT GETDATE()
);

CREATE TABLE #Step1_OrderItems (
    OrderID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),  -- Price at time of order
    PRIMARY KEY (OrderID, ProductID)
);

-- STEP 2: Already in 2NF (no composite key with partial dependencies)

-- STEP 3: Check for 3NF (transitive dependencies)
-- All good! No non-key columns depending on other non-key columns

-- Final normalized schema:
PRINT 'FINAL NORMALIZED SCHEMA:';
PRINT '========================';
PRINT 'Customers (CustomerID PK, CustomerName, CustomerPhone, Street, City)';
PRINT 'Products (ProductID PK, ProductName, UnitPrice)';
PRINT 'Orders (OrderID PK, CustomerID FK, OrderDate)';
PRINT 'OrderItems (OrderID PK/FK, ProductID PK/FK, Quantity, UnitPrice)';

/*
================================================================================
SECTION 11: INTERVIEW QUESTIONS AND ANSWERS
================================================================================

Q1: What is normalization?
A1: Normalization is the process of organizing database tables to minimize 
    redundancy and avoid data anomalies (insert, update, delete anomalies).
    It involves decomposing tables into smaller, well-structured tables.

Q2: What are the three types of anomalies?
A2: 
    INSERT ANOMALY: Cannot insert data without other unrelated data
    UPDATE ANOMALY: Must update same data in multiple places
    DELETE ANOMALY: Deleting data causes loss of other unrelated data

Q3: Explain 1NF, 2NF, and 3NF.
A3: 
    1NF: Atomic values, no repeating groups, unique rows with primary key
    2NF: 1NF + no partial dependencies (all non-key columns depend on WHOLE key)
    3NF: 2NF + no transitive dependencies (non-key columns only depend on the key)

Q4: What is a partial dependency?
A4: A partial dependency exists when a non-key column depends on only PART of 
    a composite primary key. Only applies to tables with composite keys.
    Example: In (OrderID, ProductID), if ProductName depends only on ProductID.

Q5: What is a transitive dependency?
A5: A transitive dependency exists when a non-key column depends on another 
    non-key column, which depends on the key.
    Example: EmployeeID → DeptID → DeptName (DeptName transitively depends on EmployeeID)

Q6: What is BCNF and how is it different from 3NF?
A6: BCNF (Boyce-Codd Normal Form) requires that every determinant is a candidate key.
    3NF allows non-prime attributes to be determined by candidate keys.
    BCNF is stricter - if a table is in BCNF, it's in 3NF, but not vice versa.

Q7: What is denormalization and when would you use it?
A7: Denormalization is intentionally adding redundancy to improve read performance.
    Use cases:
    - Reporting/analytics databases
    - Read-heavy workloads
    - Complex JOINs causing performance issues
    - Data warehouses (star schema)

Q8: What normal form should production databases be in?
A8: Most OLTP databases aim for 3NF. This provides a good balance between 
    data integrity and query performance. Data warehouses often use 2NF 
    or denormalized schemas for reporting performance.

Q9: What is a candidate key?
A9: A candidate key is a minimal set of columns that uniquely identifies 
    each row. A table can have multiple candidate keys. One becomes the 
    primary key, others are alternate keys.

Q10: What is a superkey?
A10: A superkey is any set of columns that uniquely identifies rows.
     A candidate key is a MINIMAL superkey (remove any column and it's 
     no longer unique).

Q11: How do you identify normalization violations?
A11: Look for:
     - Multiple values in one cell (1NF violation)
     - Repeating data for composite key columns (2NF violation)
     - Non-key columns that determine other non-key columns (3NF violation)
     - Data that must be updated in multiple places

Q12: What is a functional dependency?
A12: A functional dependency X → Y means that if two rows have the same 
     value for X, they must have the same value for Y.
     Example: EmployeeID → EmployeeName (ID determines Name)

Q13: Can you have a table in 2NF but not 3NF?
A13: Yes! 2NF eliminates partial dependencies, but 3NF eliminates transitive 
     dependencies. A table can satisfy 2NF and still have transitive dependencies.

Q14: What is 4NF?
A14: 4NF eliminates multi-valued dependencies. If A determines a SET of B 
     values independent of C, separate them into different tables.

Q15: What are the disadvantages of normalization?
A15: 
     - More tables = more JOINs = slower queries
     - Complex queries for simple data retrieval
     - More foreign key constraints to manage
     - May need denormalization for performance

================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand what normalization is and why it matters
□ Can explain 1NF, 2NF, 3NF with examples
□ Know the difference between partial and transitive dependencies
□ Understand BCNF and when it differs from 3NF
□ Know when and how to denormalize
□ Can normalize a messy table step by step
□ Can answer interview questions confidently

NEXT LAB: Lab 20 - Database Design and Constraints
================================================================================
*/

-- Cleanup temp tables
DROP TABLE IF EXISTS #BadTable_1NF;
DROP TABLE IF EXISTS #Orders_1NF;
DROP TABLE IF EXISTS #OrderItems_1NF;
DROP TABLE IF EXISTS #BadTable_2NF;
DROP TABLE IF EXISTS #Products_2NF;
DROP TABLE IF EXISTS #OrderItems_2NF;
DROP TABLE IF EXISTS #BadTable_3NF;
DROP TABLE IF EXISTS #Departments_3NF;
DROP TABLE IF EXISTS #Employees_3NF;
DROP TABLE IF EXISTS #Categories;
DROP TABLE IF EXISTS #Products;
DROP TABLE IF EXISTS #OrderDetails;
DROP TABLE IF EXISTS #OrderDetails_Denorm;
DROP TABLE IF EXISTS #Step1_Customers;
DROP TABLE IF EXISTS #Step1_Products;
DROP TABLE IF EXISTS #Step1_Orders;
DROP TABLE IF EXISTS #Step1_OrderItems;
