# Stored Procedures - Complete Guide

## 📚 What You'll Learn
- What stored procedures are and why use them
- Creating stored procedures with parameters
- Input, output, and return values
- Error handling in stored procedures
- Best practices and interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is a Stored Procedure?

### Definition
A **stored procedure** is a precompiled collection of SQL statements stored in the database that can be executed as a single unit.

### Real-World Analogy
Think of a stored procedure like a **recipe**:
- You define the steps once
- You can use it repeatedly
- You can customize it with different ingredients (parameters)
- Someone else can use it without knowing all the details

### Why Use Stored Procedures?

| Benefit | Explanation |
|---------|-------------|
| **Performance** | Precompiled and cached - faster execution |
| **Security** | Users can execute without direct table access |
| **Maintainability** | Change logic in one place |
| **Reusability** | Call from multiple applications |
| **Reduced Network Traffic** | Send one call instead of many statements |
| **Encapsulation** | Hide complex logic behind simple interface |

---

## 📖 Basic Syntax

### Creating a Stored Procedure

```sql
CREATE PROCEDURE procedure_name
    @parameter1 datatype,
    @parameter2 datatype = default_value
AS
BEGIN
    SET NOCOUNT ON;
    
    -- SQL statements here
    SELECT * FROM table WHERE column = @parameter1;
END;
```

### Executing a Stored Procedure

```sql
-- Method 1: EXEC
EXEC procedure_name @parameter1 = 'value';

-- Method 2: EXECUTE
EXECUTE procedure_name 'value';

-- Method 3: Positional parameters
EXEC procedure_name 'value1', 'value2';
```

---

## 🔧 Parameter Types

### 1. Input Parameters (Default)

```sql
CREATE PROCEDURE GetEmployeeByID
    @EmployeeID INT  -- Input parameter
AS
BEGIN
    SELECT * FROM Employees WHERE EmployeeID = @EmployeeID;
END;

-- Usage
EXEC GetEmployeeByID @EmployeeID = 5;
```

### 2. Output Parameters

```sql
CREATE PROCEDURE GetEmployeeCount
    @DepartmentID INT,
    @Count INT OUTPUT  -- Output parameter
AS
BEGIN
    SELECT @Count = COUNT(*)
    FROM Employees
    WHERE DepartmentID = @DepartmentID;
END;

-- Usage
DECLARE @EmpCount INT;
EXEC GetEmployeeCount @DepartmentID = 1, @Count = @EmpCount OUTPUT;
PRINT @EmpCount;
```

### 3. Default Parameter Values

```sql
CREATE PROCEDURE GetProducts
    @Category NVARCHAR(50) = NULL,     -- Optional, defaults to NULL
    @MinPrice DECIMAL(10,2) = 0,       -- Optional, defaults to 0
    @MaxPrice DECIMAL(10,2) = 999999   -- Optional, defaults to high value
AS
BEGIN
    SELECT * FROM Products
    WHERE (@Category IS NULL OR Category = @Category)
      AND ListPrice BETWEEN @MinPrice AND @MaxPrice;
END;

-- Usage - all parameters optional!
EXEC GetProducts;                              -- Uses all defaults
EXEC GetProducts @Category = 'Electronics';   -- One parameter
EXEC GetProducts @MinPrice = 100, @MaxPrice = 500;  -- Two parameters
```

### 4. Return Values

```sql
CREATE PROCEDURE ValidateUser
    @Username NVARCHAR(50),
    @Password NVARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Users 
               WHERE Username = @Username AND Password = @Password)
        RETURN 1;  -- Success
    ELSE
        RETURN 0;  -- Failure
END;

-- Usage
DECLARE @Result INT;
EXEC @Result = ValidateUser 'john', 'password123';
IF @Result = 1
    PRINT 'Login successful';
ELSE
    PRINT 'Login failed';
```

---

## ⚠️ Error Handling in Stored Procedures

### Basic TRY-CATCH

```sql
CREATE PROCEDURE TransferFunds
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Deduct from source account
        UPDATE Accounts 
        SET Balance = Balance - @Amount 
        WHERE AccountID = @FromAccount;
        
        -- Add to destination account
        UPDATE Accounts 
        SET Balance = Balance + @Amount 
        WHERE AccountID = @ToAccount;
        
        COMMIT TRANSACTION;
        PRINT 'Transfer successful';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Return error information
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
```

### Error Functions Available in CATCH Block

| Function | Returns |
|----------|---------|
| `ERROR_NUMBER()` | Error number |
| `ERROR_MESSAGE()` | Error message |
| `ERROR_SEVERITY()` | Severity level |
| `ERROR_STATE()` | Error state |
| `ERROR_LINE()` | Line number where error occurred |
| `ERROR_PROCEDURE()` | Procedure name where error occurred |

---

## 🎯 Common Patterns

### Pattern 1: CRUD Operations

```sql
-- CREATE
CREATE PROCEDURE InsertProduct
    @Name NVARCHAR(100),
    @Price DECIMAL(10,2),
    @NewProductID INT OUTPUT
AS
BEGIN
    INSERT INTO Products (Name, Price)
    VALUES (@Name, @Price);
    
    SET @NewProductID = SCOPE_IDENTITY();
END;

-- READ
CREATE PROCEDURE GetProductByID
    @ProductID INT
AS
BEGIN
    SELECT * FROM Products WHERE ProductID = @ProductID;
END;

-- UPDATE
CREATE PROCEDURE UpdateProduct
    @ProductID INT,
    @Name NVARCHAR(100),
    @Price DECIMAL(10,2)
AS
BEGIN
    UPDATE Products
    SET Name = @Name, Price = @Price
    WHERE ProductID = @ProductID;
    
    RETURN @@ROWCOUNT;  -- Return rows affected
END;

-- DELETE
CREATE PROCEDURE DeleteProduct
    @ProductID INT
AS
BEGIN
    DELETE FROM Products WHERE ProductID = @ProductID;
    RETURN @@ROWCOUNT;
END;
```

### Pattern 2: Search with Optional Filters

```sql
CREATE PROCEDURE SearchProducts
    @Name NVARCHAR(100) = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL,
    @Category NVARCHAR(50) = NULL,
    @InStock BIT = NULL
AS
BEGIN
    SELECT *
    FROM Products
    WHERE (@Name IS NULL OR Name LIKE '%' + @Name + '%')
      AND (@MinPrice IS NULL OR Price >= @MinPrice)
      AND (@MaxPrice IS NULL OR Price <= @MaxPrice)
      AND (@Category IS NULL OR Category = @Category)
      AND (@InStock IS NULL OR InStock = @InStock)
    ORDER BY Name;
END;
```

### Pattern 3: Pagination

```sql
CREATE PROCEDURE GetProductsPaged
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @TotalCount INT OUTPUT
AS
BEGIN
    -- Get total count
    SELECT @TotalCount = COUNT(*) FROM Products;
    
    -- Get paged results
    SELECT *
    FROM Products
    ORDER BY ProductID
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
```

---

## 📋 Best Practices

### ✅ DO's

1. **Always use SET NOCOUNT ON**
   ```sql
   CREATE PROCEDURE MyProc
   AS
   BEGIN
       SET NOCOUNT ON;  -- Prevents "X rows affected" messages
       -- Your code here
   END;
   ```

2. **Use meaningful parameter names**
   ```sql
   -- Good
   @CustomerID INT, @OrderDate DATE
   
   -- Bad
   @p1 INT, @p2 DATE
   ```

3. **Validate parameters early**
   ```sql
   IF @Amount <= 0
       THROW 50001, 'Amount must be positive', 1;
   ```

4. **Use transactions for multiple operations**

5. **Document your procedures**
   ```sql
   /*
    * Purpose: Transfer funds between accounts
    * Author: John Doe
    * Date: 2025-01-01
    * Parameters:
    *   @FromAccount - Source account ID
    *   @ToAccount - Destination account ID
    *   @Amount - Amount to transfer
    */
   ```

### ❌ DON'Ts

1. Don't use `SELECT *` - specify columns explicitly
2. Don't ignore error handling
3. Don't use sp_ prefix (reserved for system procedures)
4. Don't create procedures with side effects without documentation
5. Don't use dynamic SQL unless necessary

---

## 🎓 Interview Questions

### Q1: What is a stored procedure?
**A:** A stored procedure is a precompiled collection of SQL statements stored in the database. It can accept parameters, perform operations, and return results. Benefits include improved performance, security, reusability, and maintainability.

### Q2: Difference between stored procedure and function?
**A:**
| Stored Procedure | Function |
|-----------------|----------|
| Can return 0, 1, or multiple values | Must return exactly one value |
| Cannot be used in SELECT | Can be used in SELECT |
| Can have OUTPUT parameters | Cannot have OUTPUT parameters |
| Can use DML (INSERT/UPDATE/DELETE) | Cannot use DML (in most cases) |
| Cannot be called from function | Can be called from procedure |

### Q3: What is SET NOCOUNT ON?
**A:** It prevents the "X rows affected" message from being returned after each statement. This reduces network traffic and improves performance, especially for procedures with many statements.

### Q4: How do you handle errors in stored procedures?
**A:** Use TRY-CATCH blocks. In the TRY block, put your code. In the CATCH block, handle errors using ERROR_MESSAGE(), ERROR_NUMBER(), etc. Always rollback transactions in the CATCH block if @@TRANCOUNT > 0.

### Q5: What is SCOPE_IDENTITY()?
**A:** Returns the last identity value inserted in the current session and scope. Use this instead of @@IDENTITY to avoid issues with triggers that might insert into other tables.

### Q6: How do you pass a table to a stored procedure?
**A:** Use Table-Valued Parameters (TVP):
```sql
CREATE TYPE OrderItems AS TABLE (ProductID INT, Quantity INT);

CREATE PROCEDURE InsertOrder
    @Items OrderItems READONLY
AS
BEGIN
    INSERT INTO OrderDetails (ProductID, Quantity)
    SELECT ProductID, Quantity FROM @Items;
END;
```

### Q7: Can you call a stored procedure from a trigger?
**A:** Yes, but it's not recommended. It can cause unexpected behavior, performance issues, and make debugging difficult.

### Q8: What is the maximum number of parameters a stored procedure can have?
**A:** 2,100 parameters maximum in SQL Server.

### Q9: How do you modify an existing stored procedure?
**A:** Use ALTER PROCEDURE instead of DROP and CREATE. This preserves permissions and dependencies.

### Q10: What is the sp_ prefix issue?
**A:** Procedures starting with sp_ are searched in the master database first, then the current database. This causes performance overhead. Always use a different prefix like usp_ (user stored procedure).

---

## 🔗 Related Topics
- [User-Defined Functions →](./02_user_defined_functions.md)
- [Triggers →](./03_triggers.md)
- [Error Handling →](./04_error_handling.md)
- [Transactions →](./05_transactions.md)

---

*Next: Learn about User-Defined Functions*
