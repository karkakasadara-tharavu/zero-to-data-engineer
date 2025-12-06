# Section 02: Recursive CTEs

**Estimated Time**: 4 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced  

---

## 🎯 Learning Objectives

✅ Understand recursive CTE structure  
✅ Query hierarchical data (org charts, categories)  
✅ Build bill of materials queries  
✅ Generate number sequences  
✅ Traverse graphs and trees  
✅ Control recursion depth  

---

## 🔄 What is a Recursive CTE?

**Recursive CTE** = CTE that references itself to process hierarchical data.

**Use cases**:
- Organizational charts (employee → manager)
- Product categories (parent → child)
- Bill of materials (assembly → parts)
- File/folder structures
- Social network connections

**Structure**:
```sql
WITH RecursiveCTE AS (
    -- ANCHOR: Base case (starting point)
    SELECT columns FROM table WHERE condition
    
    UNION ALL
    
    -- RECURSIVE: References itself
    SELECT columns FROM table
    INNER JOIN RecursiveCTE ON relationship
)
SELECT * FROM RecursiveCTE;
```

---

## 📊 Example: Employee Hierarchy

### Sample Data
```
EmployeeID | Name     | ManagerID
-----------|----------|----------
1          | CEO      | NULL
2          | VP Sales | 1
3          | VP Eng   | 1
4          | Manager  | 2
5          | Dev1     | 3
6          | Dev2     | 3
```

### Recursive Query: Show Full Hierarchy

```sql
WITH EmployeeHierarchy AS (
    -- ANCHOR: Start with CEO (no manager)
    SELECT 
        EmployeeID,
        Name,
        ManagerID,
        0 AS Level,
        CAST(Name AS VARCHAR(1000)) AS HierarchyPath
    FROM Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    -- RECURSIVE: Find employees reporting to current level
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        eh.Level + 1,
        CAST(eh.HierarchyPath + ' > ' + e.Name AS VARCHAR(1000))
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT 
    EmployeeID,
    Name,
    Level,
    REPLICATE('  ', Level) + Name AS IndentedName,
    HierarchyPath
FROM EmployeeHierarchy
ORDER BY HierarchyPath;
```

**Output**:
```
EmployeeID | Name     | Level | IndentedName      | HierarchyPath
-----------|----------|-------|-------------------|------------------
1          | CEO      | 0     | CEO              | CEO
2          | VP Sales | 1     |   VP Sales       | CEO > VP Sales
4          | Manager  | 2     |     Manager      | CEO > VP Sales > Manager
3          | VP Eng   | 1     |   VP Eng         | CEO > VP Eng
5          | Dev1     | 2     |     Dev1         | CEO > VP Eng > Dev1
6          | Dev2     | 2     |     Dev2         | CEO > VP Eng > Dev2
```

---

## 🎯 AdventureWorks Example: Product Categories

```sql
USE AdventureWorks2022;  -- Full version (not LT)
GO

-- Show full category hierarchy with depth
WITH CategoryHierarchy AS (
    -- ANCHOR: Top-level categories (no parent)
    SELECT 
        ProductCategoryID,
        Name,
        ParentProductCategoryID,
        0 AS Level,
        CAST(Name AS NVARCHAR(500)) AS CategoryPath
    FROM Production.ProductCategory
    WHERE ParentProductCategoryID IS NULL
    
    UNION ALL
    
    -- RECURSIVE: Child categories
    SELECT 
        pc.ProductCategoryID,
        pc.Name,
        pc.ParentProductCategoryID,
        ch.Level + 1,
        CAST(ch.CategoryPath + ' > ' + pc.Name AS NVARCHAR(500))
    FROM Production.ProductCategory pc
    INNER JOIN CategoryHierarchy ch 
        ON pc.ParentProductCategoryID = ch.ProductCategoryID
)
SELECT 
    ProductCategoryID,
    REPLICATE('--', Level) + ' ' + Name AS Category,
    Level,
    CategoryPath
FROM CategoryHierarchy
ORDER BY CategoryPath;
```

---

## 🔢 Example: Generate Number Sequence

```sql
-- Generate numbers 1-100 without a numbers table
WITH Numbers AS (
    -- ANCHOR: Start with 1
    SELECT 1 AS Num
    
    UNION ALL
    
    -- RECURSIVE: Add 1 until 100
    SELECT Num + 1
    FROM Numbers
    WHERE Num < 100
)
SELECT Num
FROM Numbers
OPTION (MAXRECURSION 100);  -- Prevent infinite loop
```

**Use case**: Create date ranges, fill gaps in data.

---

## 🛠️ Controlling Recursion

### MAXRECURSION Option

```sql
-- Default: 100 levels
WITH RecursiveCTE AS (...)
SELECT * FROM RecursiveCTE;

-- Custom limit: 1000 levels
WITH RecursiveCTE AS (...)
SELECT * FROM RecursiveCTE
OPTION (MAXRECURSION 1000);

-- Unlimited (dangerous!)
WITH RecursiveCTE AS (...)
SELECT * FROM RecursiveCTE
OPTION (MAXRECURSION 0);
```

**Best practice**: Always set MAXRECURSION to prevent infinite loops.

---

## 🎯 Practical Example: Find All Reports

```sql
-- Find all employees reporting to a specific manager (direct + indirect)
DECLARE @ManagerID INT = 2;  -- VP Sales

WITH AllReports AS (
    -- ANCHOR: Direct reports
    SELECT 
        EmployeeID,
        Name,
        ManagerID,
        1 AS Level
    FROM Employees
    WHERE ManagerID = @ManagerID
    
    UNION ALL
    
    -- RECURSIVE: Indirect reports
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        ar.Level + 1
    FROM Employees e
    INNER JOIN AllReports ar ON e.ManagerID = ar.EmployeeID
)
SELECT * FROM AllReports
ORDER BY Level, Name;
```

---

## 📝 Lab 12: Recursive CTEs

Complete `labs/lab_12_recursive.sql`.

**Tasks**:
1. Build organizational chart (employee hierarchy)
2. Calculate total reports for each manager
3. Find longest reporting chain
4. Generate date range (recursively)
5. Bill of materials explosion (parts hierarchy)

---

## ✅ Section Summary

Recursive CTEs handle **hierarchical data** elegantly. Key points:
- Anchor + Recursive parts
- UNION ALL (not UNION)
- Always set MAXRECURSION
- Common uses: org charts, categories, graphs

**Next**: [Section 03: Window Functions - Ranking →](./03_window_ranking.md)
