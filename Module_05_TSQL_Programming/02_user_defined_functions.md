# User-Defined Functions - Complete Guide

## 📚 What You'll Learn
- Types of user-defined functions (Scalar, Table-Valued)
- When to use functions vs stored procedures
- Creating and using each function type
- Performance considerations
- Best practices and interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is a User-Defined Function (UDF)?

### Definition
A **User-Defined Function** is a reusable piece of code that:
- Accepts parameters
- Performs calculations or operations
- **Always returns a value**
- Can be used in SELECT, WHERE, and other clauses

### Function Types in SQL Server

| Type | Returns | Can Be Used In |
|------|---------|----------------|
| **Scalar Function** | Single value | SELECT, WHERE, computed columns |
| **Inline Table-Valued Function (iTVF)** | Table (single SELECT) | FROM clause like a table |
| **Multi-Statement Table-Valued Function (mTVF)** | Table (multiple statements) | FROM clause like a table |

---

## 1️⃣ Scalar Functions

### What They Do
Return a **single value** (int, varchar, date, etc.)

### Syntax

```sql
CREATE FUNCTION function_name (@param1 datatype, @param2 datatype)
RETURNS return_datatype
AS
BEGIN
    DECLARE @result return_datatype;
    
    -- Logic here
    SET @result = <calculation>;
    
    RETURN @result;
END;
```

### Example: Calculate Age

```sql
CREATE FUNCTION dbo.CalculateAge (@BirthDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT;
    
    SET @Age = DATEDIFF(YEAR, @BirthDate, GETDATE())
        - CASE 
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, @BirthDate, GETDATE()), @BirthDate) > GETDATE() 
            THEN 1 
            ELSE 0 
          END;
    
    RETURN @Age;
END;
GO

-- Usage in SELECT
SELECT 
    FirstName,
    LastName,
    BirthDate,
    dbo.CalculateAge(BirthDate) AS Age
FROM Employees;

-- Usage in WHERE
SELECT * FROM Employees
WHERE dbo.CalculateAge(BirthDate) >= 18;
```

### Example: Format Phone Number

```sql
CREATE FUNCTION dbo.FormatPhone (@Phone VARCHAR(20))
RETURNS VARCHAR(14)
AS
BEGIN
    -- Remove all non-numeric characters
    DECLARE @Cleaned VARCHAR(20) = '';
    DECLARE @i INT = 1;
    
    WHILE @i <= LEN(@Phone)
    BEGIN
        IF SUBSTRING(@Phone, @i, 1) LIKE '[0-9]'
            SET @Cleaned = @Cleaned + SUBSTRING(@Phone, @i, 1);
        SET @i = @i + 1;
    END
    
    -- Format as (XXX) XXX-XXXX
    IF LEN(@Cleaned) = 10
        RETURN '(' + LEFT(@Cleaned, 3) + ') ' + 
               SUBSTRING(@Cleaned, 4, 3) + '-' + 
               RIGHT(@Cleaned, 4);
    
    RETURN @Phone;  -- Return original if can't format
END;
GO

-- Usage
SELECT dbo.FormatPhone('5551234567');  -- Returns: (555) 123-4567
```

### Example: Calculate Tax

```sql
CREATE FUNCTION dbo.CalculateTax (@Amount DECIMAL(18,2), @TaxRate DECIMAL(5,2) = 0.10)
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN @Amount * @TaxRate;
END;
GO

-- Usage
SELECT 
    ProductName,
    Price,
    dbo.CalculateTax(Price, 0.08) AS Tax,
    Price + dbo.CalculateTax(Price, 0.08) AS TotalPrice
FROM Products;
```

---

## 2️⃣ Inline Table-Valued Functions (iTVF)

### What They Do
- Return a **table** from a **single SELECT statement**
- Like a parameterized view
- **Best performance** of all function types

### Syntax

```sql
CREATE FUNCTION function_name (@param1 datatype)
RETURNS TABLE
AS
RETURN (
    SELECT column1, column2, ...
    FROM table
    WHERE condition = @param1
);
```

### Example: Get Orders by Customer

```sql
CREATE FUNCTION dbo.GetCustomerOrders (@CustomerID INT)
RETURNS TABLE
AS
RETURN (
    SELECT 
        o.OrderID,
        o.OrderDate,
        o.TotalAmount,
        od.ProductID,
        p.ProductName,
        od.Quantity,
        od.UnitPrice
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.CustomerID = @CustomerID
);
GO

-- Usage - Like a table in FROM clause
SELECT * FROM dbo.GetCustomerOrders(101);

-- Can JOIN with other tables
SELECT 
    c.CustomerName,
    co.*
FROM Customers c
CROSS APPLY dbo.GetCustomerOrders(c.CustomerID) co
WHERE c.Country = 'USA';
```

### Example: Date Range Filter

```sql
CREATE FUNCTION dbo.GetSalesInRange (@StartDate DATE, @EndDate DATE)
RETURNS TABLE
AS
RETURN (
    SELECT 
        SalesOrderID,
        OrderDate,
        CustomerID,
        TotalDue
    FROM Sales.SalesOrderHeader
    WHERE OrderDate BETWEEN @StartDate AND @EndDate
);
GO

-- Usage
SELECT * FROM dbo.GetSalesInRange('2024-01-01', '2024-03-31');
```

### Example: Search Function

```sql
CREATE FUNCTION dbo.SearchProducts (@SearchTerm NVARCHAR(100))
RETURNS TABLE
AS
RETURN (
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        Description
    FROM Products
    WHERE ProductName LIKE '%' + @SearchTerm + '%'
       OR Description LIKE '%' + @SearchTerm + '%'
);
GO

-- Usage
SELECT * FROM dbo.SearchProducts('laptop');
```

---

## 3️⃣ Multi-Statement Table-Valued Functions (mTVF)

### What They Do
- Return a **table** built from **multiple statements**
- More flexible but **slower** than iTVF
- Requires DECLARE @TableVariable

### Syntax

```sql
CREATE FUNCTION function_name (@param1 datatype)
RETURNS @ResultTable TABLE (
    Column1 datatype,
    Column2 datatype,
    ...
)
AS
BEGIN
    -- Multiple INSERT statements
    INSERT INTO @ResultTable (Column1, Column2)
    SELECT ... FROM ...;
    
    INSERT INTO @ResultTable (Column1, Column2)
    VALUES (...);
    
    RETURN;
END;
```

### Example: Get Employee Hierarchy

```sql
CREATE FUNCTION dbo.GetEmployeeHierarchy (@ManagerID INT)
RETURNS @Employees TABLE (
    EmployeeID INT,
    EmployeeName NVARCHAR(100),
    ManagerID INT,
    Level INT
)
AS
BEGIN
    DECLARE @Level INT = 0;
    
    -- Insert the manager
    INSERT INTO @Employees (EmployeeID, EmployeeName, ManagerID, Level)
    SELECT EmployeeID, FirstName + ' ' + LastName, ManagerID, @Level
    FROM Employees
    WHERE EmployeeID = @ManagerID;
    
    -- Insert all subordinates (recursively via loop)
    WHILE @@ROWCOUNT > 0
    BEGIN
        SET @Level = @Level + 1;
        
        INSERT INTO @Employees (EmployeeID, EmployeeName, ManagerID, Level)
        SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName, e.ManagerID, @Level
        FROM Employees e
        INNER JOIN @Employees eh ON e.ManagerID = eh.EmployeeID
        WHERE eh.Level = @Level - 1
          AND e.EmployeeID NOT IN (SELECT EmployeeID FROM @Employees);
    END
    
    RETURN;
END;
GO

-- Usage
SELECT * FROM dbo.GetEmployeeHierarchy(1) ORDER BY Level, EmployeeName;
```

### Example: Split String (Before STRING_SPLIT)

```sql
CREATE FUNCTION dbo.SplitString (@String NVARCHAR(MAX), @Delimiter CHAR(1))
RETURNS @Result TABLE (
    Position INT IDENTITY(1,1),
    Value NVARCHAR(MAX)
)
AS
BEGIN
    DECLARE @Start INT = 1, @End INT;
    
    WHILE @Start <= LEN(@String)
    BEGIN
        SET @End = CHARINDEX(@Delimiter, @String, @Start);
        IF @End = 0 SET @End = LEN(@String) + 1;
        
        INSERT INTO @Result (Value)
        VALUES (SUBSTRING(@String, @Start, @End - @Start));
        
        SET @Start = @End + 1;
    END
    
    RETURN;
END;
GO

-- Usage
SELECT * FROM dbo.SplitString('apple,banana,cherry', ',');
-- Returns:
-- Position | Value
-- 1        | apple
-- 2        | banana
-- 3        | cherry
```

---

## ⚖️ Function Comparison

| Feature | Scalar | Inline TVF | Multi-Statement TVF |
|---------|--------|------------|---------------------|
| Returns | Single value | Table | Table |
| Performance | Slowest | Fastest | Medium |
| Complexity | Simple | Single SELECT | Multiple statements |
| Can use in WHERE | ✅ Yes | ❌ No | ❌ No |
| Can use in FROM | ❌ No | ✅ Yes | ✅ Yes |
| Optimizer can inline | ❌ No | ✅ Yes | ❌ No |

### When to Use Each

| Use Case | Best Function Type |
|----------|-------------------|
| Simple calculations | Scalar |
| Formatting values | Scalar |
| Parameterized views | Inline TVF |
| Complex filtering logic | Inline TVF |
| Multiple operations needed | Multi-Statement TVF |
| Building hierarchies | Multi-Statement TVF |

---

## 🔄 Functions vs Stored Procedures

| Aspect | Function | Stored Procedure |
|--------|----------|------------------|
| **Return value** | Must return value | Optional (0, 1, or many) |
| **Use in SELECT** | ✅ Yes | ❌ No |
| **Use in WHERE** | ✅ Yes (scalar) | ❌ No |
| **DML operations** | ❌ Cannot INSERT/UPDATE/DELETE | ✅ Can perform DML |
| **Try-Catch** | ❌ Not allowed | ✅ Allowed |
| **Transactions** | ❌ Cannot manage | ✅ Can BEGIN/COMMIT/ROLLBACK |
| **Output parameters** | ❌ Not allowed | ✅ Allowed |
| **Call other** | Can call functions | Can call functions and procedures |

### Decision Guide

```
Need to modify data?
  ├─ Yes → Use Stored Procedure
  └─ No → 
      Need to use in SELECT/WHERE?
        ├─ Yes → Use Function
        └─ No → Either works (prefer SP for complex logic)
```

---

## ⚠️ Performance Considerations

### Scalar Function Problems

```sql
-- ❌ BAD: Scalar function called for EACH ROW (slow!)
SELECT 
    OrderID,
    dbo.CalculateTax(TotalAmount, 0.08) AS Tax
FROM Orders;  -- Function called 1 million times for 1M rows!

-- ✅ BETTER: Inline calculation
SELECT 
    OrderID,
    TotalAmount * 0.08 AS Tax
FROM Orders;

-- ✅ OR: Use Inline TVF with CROSS APPLY
CREATE FUNCTION dbo.GetTaxAmount (@Amount DECIMAL(18,2), @Rate DECIMAL(5,2))
RETURNS TABLE
AS
RETURN (SELECT @Amount * @Rate AS Tax);

SELECT 
    o.OrderID,
    t.Tax
FROM Orders o
CROSS APPLY dbo.GetTaxAmount(o.TotalAmount, 0.08) t;
```

### Best Practices for Performance

1. **Prefer Inline TVF over scalar functions**
2. **Avoid functions in WHERE clauses** (prevents index usage)
3. **Use WITH SCHEMABINDING** for deterministic functions
4. **Consider computed columns** instead of runtime calculations

---

## 🎓 Interview Questions

### Q1: What are the types of user-defined functions in SQL Server?
**A:** Three types:
1. **Scalar Functions** - Return single value, can be used in SELECT/WHERE
2. **Inline Table-Valued Functions** - Return table from single SELECT, best performance
3. **Multi-Statement Table-Valued Functions** - Return table from multiple statements

### Q2: Can you use DML statements in a function?
**A:** No. Functions cannot contain INSERT, UPDATE, DELETE, or MERGE statements that modify database tables. They can only read data.

### Q3: Why are scalar functions slow?
**A:** Scalar functions are called once per row and cannot be inlined by the optimizer. For a table with 1 million rows, the function executes 1 million times. Use inline TVFs or computed columns instead.

### Q4: What is WITH SCHEMABINDING?
**A:** It binds the function to the schema of underlying objects, preventing changes to those objects that would affect the function. Required for creating indexed views with functions.

### Q5: Difference between Inline TVF and Multi-Statement TVF?
**A:**
- **Inline TVF**: Single SELECT, no table variable declaration, best performance, optimizer can inline it
- **Multi-Statement TVF**: Multiple statements, must declare return table, slower, treated as black box by optimizer

### Q6: Can functions call stored procedures?
**A:** No. Functions cannot call stored procedures. They can only call other functions.

### Q7: What is a deterministic function?
**A:** A function that always returns the same result for the same input values. GETDATE() is non-deterministic, but DATEADD() is deterministic.

### Q8: Can you use TRY-CATCH in functions?
**A:** No. TRY-CATCH blocks are not allowed in functions. Use CASE statements or IF conditions for error handling.

### Q9: How do you modify an existing function?
**A:** Use ALTER FUNCTION instead of DROP and CREATE to preserve permissions.

### Q10: When would you choose a function over a stored procedure?
**A:** Choose function when:
- You need to use the result in a SELECT or WHERE clause
- You need a reusable calculation
- You don't need to modify data
- You want to use it in a computed column

---

## 🔗 Related Topics
- [← Stored Procedures](./01_stored_procedures.md)
- [Triggers →](./03_triggers.md)
- [Error Handling →](./04_error_handling.md)

---

*Next: Learn about Triggers*
