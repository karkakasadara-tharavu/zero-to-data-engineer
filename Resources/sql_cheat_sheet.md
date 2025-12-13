# SQL Quick Reference Cheat Sheet

## 🎯 Purpose
A comprehensive quick reference for SQL Server syntax and common patterns. Perfect for interview prep and daily work.

---

## Basic Query Structure

```sql
SELECT [DISTINCT] columns
FROM table
[JOIN other_table ON condition]
[WHERE condition]
[GROUP BY columns]
[HAVING condition]
[ORDER BY columns [ASC|DESC]]
[OFFSET n ROWS FETCH NEXT m ROWS ONLY];
```

---

## SELECT Statements

```sql
-- Basic select
SELECT * FROM Employees;
SELECT FirstName, LastName FROM Employees;

-- Aliases
SELECT FirstName AS [First Name], Salary * 12 AS AnnualSalary
FROM Employees e;

-- Distinct values
SELECT DISTINCT Department FROM Employees;

-- Top N rows
SELECT TOP 10 * FROM Employees ORDER BY Salary DESC;
SELECT TOP 10 PERCENT * FROM Employees;
SELECT TOP 5 WITH TIES * FROM Employees ORDER BY Salary DESC;

-- Pagination (SQL Server 2012+)
SELECT * FROM Employees
ORDER BY EmployeeID
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

## WHERE Clause

```sql
-- Comparison operators
WHERE Salary > 50000
WHERE Department = 'IT'
WHERE HireDate >= '2020-01-01'

-- Logical operators
WHERE Department = 'IT' AND Salary > 50000
WHERE Department = 'IT' OR Department = 'HR'
WHERE NOT Department = 'IT'

-- Range and list
WHERE Salary BETWEEN 40000 AND 60000
WHERE Department IN ('IT', 'HR', 'Finance')
WHERE Department NOT IN ('Sales')

-- Pattern matching
WHERE LastName LIKE 'S%'          -- Starts with S
WHERE Email LIKE '%@gmail.com'    -- Ends with
WHERE Name LIKE '_ohn'            -- Single character wildcard
WHERE Name LIKE '[ABC]%'          -- Starts with A, B, or C
WHERE Name LIKE '[^ABC]%'         -- Does NOT start with A, B, or C

-- NULL handling
WHERE MiddleName IS NULL
WHERE MiddleName IS NOT NULL
```

---

## JOIN Types

```sql
-- INNER JOIN (matching rows only)
SELECT e.Name, d.DepartmentName
FROM Employees e
INNER JOIN Departments d ON e.DeptID = d.DeptID;

-- LEFT JOIN (all from left, matching from right)
SELECT e.Name, d.DepartmentName
FROM Employees e
LEFT JOIN Departments d ON e.DeptID = d.DeptID;

-- RIGHT JOIN (all from right, matching from left)
SELECT e.Name, d.DepartmentName
FROM Employees e
RIGHT JOIN Departments d ON e.DeptID = d.DeptID;

-- FULL OUTER JOIN (all from both)
SELECT e.Name, d.DepartmentName
FROM Employees e
FULL OUTER JOIN Departments d ON e.DeptID = d.DeptID;

-- CROSS JOIN (Cartesian product)
SELECT e.Name, p.ProjectName
FROM Employees e
CROSS JOIN Projects p;

-- Self JOIN
SELECT e.Name AS Employee, m.Name AS Manager
FROM Employees e
LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID;
```

---

## Aggregate Functions

```sql
-- Basic aggregates
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(Salary) AS NonNullSalaries,
    COUNT(DISTINCT Department) AS UniqueDepts,
    SUM(Salary) AS TotalSalary,
    AVG(Salary) AS AvgSalary,
    MIN(Salary) AS MinSalary,
    MAX(Salary) AS MaxSalary
FROM Employees;

-- With GROUP BY
SELECT 
    Department,
    COUNT(*) AS EmpCount,
    AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY Department;

-- Filter groups with HAVING
SELECT Department, AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY Department
HAVING AVG(Salary) > 50000;

-- String aggregation (SQL Server 2017+)
SELECT Department, STRING_AGG(FirstName, ', ') AS Employees
FROM Employees
GROUP BY Department;
```

---

## Window Functions

```sql
-- ROW_NUMBER (unique sequential)
SELECT Name, Salary,
    ROW_NUMBER() OVER (ORDER BY Salary DESC) AS RowNum
FROM Employees;

-- RANK (same rank for ties, gaps after)
SELECT Name, Salary,
    RANK() OVER (ORDER BY Salary DESC) AS Rank
FROM Employees;

-- DENSE_RANK (same rank for ties, no gaps)
SELECT Name, Salary,
    DENSE_RANK() OVER (ORDER BY Salary DESC) AS DenseRank
FROM Employees;

-- NTILE (divide into N groups)
SELECT Name, Salary,
    NTILE(4) OVER (ORDER BY Salary DESC) AS Quartile
FROM Employees;

-- Partition by department
SELECT Name, Department, Salary,
    ROW_NUMBER() OVER (PARTITION BY Department ORDER BY Salary DESC) AS DeptRank
FROM Employees;

-- Running totals
SELECT OrderDate, Amount,
    SUM(Amount) OVER (ORDER BY OrderDate) AS RunningTotal
FROM Orders;

-- Moving average
SELECT OrderDate, Amount,
    AVG(Amount) OVER (ORDER BY OrderDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS MovingAvg7Day
FROM Orders;

-- LAG / LEAD (previous/next row)
SELECT OrderDate, Amount,
    LAG(Amount, 1, 0) OVER (ORDER BY OrderDate) AS PrevAmount,
    LEAD(Amount, 1, 0) OVER (ORDER BY OrderDate) AS NextAmount
FROM Orders;

-- FIRST_VALUE / LAST_VALUE
SELECT Name, Salary,
    FIRST_VALUE(Name) OVER (ORDER BY Salary DESC) AS HighestPaid,
    LAST_VALUE(Name) OVER (ORDER BY Salary DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LowestPaid
FROM Employees;
```

---

## Common Table Expressions (CTE)

```sql
-- Basic CTE
WITH HighEarners AS (
    SELECT * FROM Employees WHERE Salary > 80000
)
SELECT * FROM HighEarners;

-- Multiple CTEs
WITH 
DeptStats AS (
    SELECT Department, AVG(Salary) AS AvgSalary
    FROM Employees GROUP BY Department
),
CompanyAvg AS (
    SELECT AVG(Salary) AS OverallAvg FROM Employees
)
SELECT d.Department, d.AvgSalary, c.OverallAvg
FROM DeptStats d, CompanyAvg c;

-- Recursive CTE (hierarchy)
WITH OrgChart AS (
    -- Anchor: top-level managers
    SELECT EmployeeID, Name, ManagerID, 0 AS Level
    FROM Employees WHERE ManagerID IS NULL
    
    UNION ALL
    
    -- Recursive: employees under managers
    SELECT e.EmployeeID, e.Name, e.ManagerID, oc.Level + 1
    FROM Employees e
    INNER JOIN OrgChart oc ON e.ManagerID = oc.EmployeeID
)
SELECT * FROM OrgChart ORDER BY Level, Name;
```

---

## Subqueries

```sql
-- Scalar subquery (returns single value)
SELECT Name, Salary,
    (SELECT AVG(Salary) FROM Employees) AS CompanyAvg
FROM Employees;

-- IN subquery
SELECT * FROM Employees
WHERE DepartmentID IN (
    SELECT DepartmentID FROM Departments WHERE Location = 'New York'
);

-- EXISTS subquery
SELECT * FROM Departments d
WHERE EXISTS (
    SELECT 1 FROM Employees e WHERE e.DepartmentID = d.DepartmentID
);

-- NOT EXISTS
SELECT * FROM Departments d
WHERE NOT EXISTS (
    SELECT 1 FROM Employees e WHERE e.DepartmentID = d.DepartmentID
);

-- Correlated subquery
SELECT e.Name, e.Salary,
    (SELECT COUNT(*) FROM Employees e2 WHERE e2.Salary > e.Salary) AS PeopleEarningMore
FROM Employees e;
```

---

## Data Modification

```sql
-- INSERT
INSERT INTO Employees (FirstName, LastName, Salary)
VALUES ('John', 'Doe', 50000);

-- Insert multiple rows
INSERT INTO Employees (FirstName, LastName, Salary)
VALUES 
    ('John', 'Doe', 50000),
    ('Jane', 'Smith', 55000);

-- Insert from select
INSERT INTO EmployeeArchive
SELECT * FROM Employees WHERE Status = 'Inactive';

-- UPDATE
UPDATE Employees
SET Salary = Salary * 1.10
WHERE Department = 'IT';

-- Update with JOIN
UPDATE e
SET e.Salary = e.Salary * 1.10
FROM Employees e
INNER JOIN Departments d ON e.DeptID = d.DeptID
WHERE d.DeptName = 'IT';

-- DELETE
DELETE FROM Employees WHERE Status = 'Inactive';

-- Delete with JOIN
DELETE e
FROM Employees e
INNER JOIN Departments d ON e.DeptID = d.DeptID
WHERE d.IsActive = 0;

-- MERGE (upsert)
MERGE INTO TargetTable AS target
USING SourceTable AS source ON target.ID = source.ID
WHEN MATCHED THEN UPDATE SET target.Name = source.Name
WHEN NOT MATCHED THEN INSERT (ID, Name) VALUES (source.ID, source.Name)
WHEN NOT MATCHED BY SOURCE THEN DELETE;
```

---

## String Functions

```sql
SELECT
    LEN('Hello')               AS Length,        -- 5
    DATALENGTH('Hello')        AS Bytes,         -- 5 (10 for NVARCHAR)
    LEFT('Hello World', 5)     AS LeftStr,       -- Hello
    RIGHT('Hello World', 5)    AS RightStr,      -- World
    SUBSTRING('Hello', 2, 3)   AS SubStr,        -- ell
    CHARINDEX('o', 'Hello')    AS Position,      -- 5
    REPLACE('Hello', 'l', 'L') AS Replaced,      -- HeLLo
    UPPER('hello')             AS Upper,         -- HELLO
    LOWER('HELLO')             AS Lower,         -- hello
    LTRIM('  hello  ')         AS LeftTrim,      -- 'hello  '
    RTRIM('  hello  ')         AS RightTrim,     -- '  hello'
    TRIM('  hello  ')          AS Trimmed,       -- 'hello'
    REVERSE('Hello')           AS Reversed,      -- olleH
    REPLICATE('Ab', 3)         AS Replicated,    -- AbAbAb
    CONCAT('Hello', ' ', 'World') AS Concatenated, -- Hello World
    CONCAT_WS(', ', 'A', 'B', 'C') AS WithSep,   -- A, B, C
    FORMAT(1234567.89, 'N2')   AS Formatted;     -- 1,234,567.89
```

---

## Date Functions

```sql
SELECT
    GETDATE()                              AS CurrentDateTime,
    SYSDATETIME()                          AS CurrentDateTime2,
    CAST(GETDATE() AS DATE)                AS TodayDate,
    YEAR(GETDATE())                        AS Year,
    MONTH(GETDATE())                       AS Month,
    DAY(GETDATE())                         AS Day,
    DATEPART(QUARTER, GETDATE())           AS Quarter,
    DATEPART(WEEKDAY, GETDATE())           AS DayOfWeek,
    DATENAME(MONTH, GETDATE())             AS MonthName,
    DATENAME(WEEKDAY, GETDATE())           AS DayName,
    DATEADD(DAY, 7, GETDATE())             AS NextWeek,
    DATEADD(MONTH, -1, GETDATE())          AS LastMonth,
    DATEDIFF(DAY, '2020-01-01', GETDATE()) AS DaysSince,
    DATEDIFF(YEAR, BirthDate, GETDATE())   AS Age,
    EOMONTH(GETDATE())                     AS EndOfMonth,
    EOMONTH(GETDATE(), 1)                  AS EndOfNextMonth,
    DATEFROMPARTS(2024, 12, 25)            AS Christmas,
    ISDATE('2024-13-01')                   AS IsValid;  -- 0 (invalid)
```

---

## NULL Handling

```sql
SELECT
    ISNULL(MiddleName, 'N/A')              AS WithDefault,
    COALESCE(Phone, Mobile, Email, 'None') AS FirstNonNull,
    NULLIF(Quantity, 0)                    AS NullIfZero,
    CASE WHEN Value IS NULL THEN 'Null' ELSE 'Not Null' END AS NullCheck;
    
-- Count NULLs
SELECT COUNT(*) - COUNT(MiddleName) AS NullCount FROM Employees;

-- Replace NULL in aggregates
SELECT ISNULL(SUM(Bonus), 0) AS TotalBonus FROM Employees;
```

---

## CASE Expression

```sql
-- Simple CASE
SELECT Name, 
    CASE Department
        WHEN 'IT' THEN 'Technology'
        WHEN 'HR' THEN 'Human Resources'
        ELSE 'Other'
    END AS DeptCategory
FROM Employees;

-- Searched CASE
SELECT Name, Salary,
    CASE 
        WHEN Salary >= 100000 THEN 'Executive'
        WHEN Salary >= 70000 THEN 'Senior'
        WHEN Salary >= 40000 THEN 'Mid-Level'
        ELSE 'Entry'
    END AS Level
FROM Employees;

-- CASE in ORDER BY
SELECT * FROM Employees
ORDER BY 
    CASE WHEN Status = 'Active' THEN 0 ELSE 1 END,
    Name;

-- CASE in aggregation
SELECT 
    SUM(CASE WHEN Department = 'IT' THEN 1 ELSE 0 END) AS ITCount,
    SUM(CASE WHEN Department = 'HR' THEN 1 ELSE 0 END) AS HRCount
FROM Employees;
```

---

## Constraints Quick Reference

```sql
-- Primary Key
EmployeeID INT PRIMARY KEY

-- Foreign Key
DepartmentID INT FOREIGN KEY REFERENCES Departments(DeptID)

-- With options
FOREIGN KEY (DeptID) REFERENCES Departments(DeptID)
    ON DELETE CASCADE ON UPDATE NO ACTION

-- Unique
Email NVARCHAR(100) UNIQUE

-- Check
Salary DECIMAL(10,2) CHECK (Salary >= 0)
Status NVARCHAR(20) CHECK (Status IN ('Active', 'Inactive'))

-- Default
CreatedAt DATETIME2 DEFAULT SYSDATETIME()
IsActive BIT DEFAULT 1

-- Not Null
FirstName NVARCHAR(50) NOT NULL

-- Computed Column
LineTotal AS (Quantity * UnitPrice) PERSISTED
```

---

## Index Types

```sql
-- Clustered (one per table, defines physical order)
CREATE CLUSTERED INDEX IX_Emp_ID ON Employees(EmployeeID);

-- Non-clustered (multiple allowed)
CREATE NONCLUSTERED INDEX IX_Emp_Name ON Employees(LastName, FirstName);

-- Unique
CREATE UNIQUE INDEX IX_Emp_Email ON Employees(Email);

-- Filtered
CREATE INDEX IX_Active_Emp ON Employees(LastName) WHERE IsActive = 1;

-- Covering (included columns)
CREATE INDEX IX_Emp_Dept ON Employees(DepartmentID)
INCLUDE (FirstName, LastName, Salary);

-- Columnstore (for analytics)
CREATE COLUMNSTORE INDEX IX_CS_Orders ON Orders(OrderDate, CustomerID, Amount);
```

---

## Transactions

```sql
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 2;
    
    IF @@ERROR <> 0
        ROLLBACK TRANSACTION;
    ELSE
        COMMIT TRANSACTION;

-- With TRY-CATCH
BEGIN TRY
    BEGIN TRANSACTION;
        -- Operations
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;  -- Re-raise error
END CATCH
```

---

## Stored Procedure Template

```sql
CREATE OR ALTER PROCEDURE usp_GetEmployeesByDept
    @DepartmentID INT,
    @MinSalary DECIMAL(10,2) = 0,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        SELECT @TotalCount = COUNT(*)
        FROM Employees
        WHERE DepartmentID = @DepartmentID AND Salary >= @MinSalary;
        
        SELECT EmployeeID, FirstName, LastName, Salary
        FROM Employees
        WHERE DepartmentID = @DepartmentID AND Salary >= @MinSalary
        ORDER BY Salary DESC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- Execute
DECLARE @Count INT;
EXEC usp_GetEmployeesByDept @DepartmentID = 1, @MinSalary = 50000, @TotalCount = @Count OUTPUT;
SELECT @Count AS TotalEmployees;
```

---

## Quick Tips

| Need | Solution |
|------|----------|
| Remove duplicates | `SELECT DISTINCT` or `GROUP BY` |
| Top N per group | `ROW_NUMBER() OVER (PARTITION BY...)` |
| Running total | `SUM() OVER (ORDER BY...)` |
| Compare with previous row | `LAG()` window function |
| Hierarchical data | Recursive CTE |
| Upsert (update or insert) | `MERGE` statement |
| Avoid divide by zero | `NULLIF(denominator, 0)` |
| First non-null value | `COALESCE(a, b, c)` |
| Conditional aggregation | `SUM(CASE WHEN...)` |
| Check execution plan | `SET STATISTICS IO ON` |
