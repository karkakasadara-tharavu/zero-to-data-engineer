# Error Handling in T-SQL - Complete Guide

## 📚 What You'll Learn
- Structured error handling with TRY-CATCH
- Error functions and how to use them
- Raising custom errors (RAISERROR, THROW)
- Transaction error handling
- Best practices and interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Why Error Handling Matters

### Without Error Handling

```sql
-- BAD: No error handling
BEGIN TRANSACTION
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 2;  -- What if this fails?
COMMIT;

-- If second UPDATE fails:
-- - First update is committed (or rolled back depending on settings)
-- - No notification of the problem
-- - Data could be inconsistent!
```

### With Error Handling

```sql
-- GOOD: Proper error handling
BEGIN TRY
    BEGIN TRANSACTION
        UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;
        UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 2;
    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    
    -- Report the error
    SELECT 
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_NUMBER() AS ErrorNumber;
END CATCH;
```

---

## 1️⃣ TRY-CATCH Basics

### Syntax

```sql
BEGIN TRY
    -- Code that might fail
END TRY
BEGIN CATCH
    -- Handle the error
END CATCH;
```

### Simple Example

```sql
BEGIN TRY
    -- This will cause an error (divide by zero)
    SELECT 1/0;
END TRY
BEGIN CATCH
    PRINT 'An error occurred!';
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- Output:
-- An error occurred!
-- Error: Divide by zero error encountered.
```

### Error Functions

| Function | Returns | Example Value |
|----------|---------|---------------|
| `ERROR_NUMBER()` | Error number | 8134 |
| `ERROR_MESSAGE()` | Error message text | "Divide by zero error encountered." |
| `ERROR_SEVERITY()` | Severity level (0-25) | 16 |
| `ERROR_STATE()` | Error state number | 1 |
| `ERROR_LINE()` | Line number where error occurred | 5 |
| `ERROR_PROCEDURE()` | Procedure name (or NULL) | "usp_TransferFunds" |

### Complete Error Information

```sql
BEGIN TRY
    -- Force an error
    INSERT INTO NonExistentTable VALUES (1);
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_LINE() AS ErrorLine,
        ERROR_PROCEDURE() AS ErrorProcedure;
END CATCH;
```

---

## 2️⃣ Raising Errors

### RAISERROR (Legacy but still common)

```sql
-- Basic syntax
RAISERROR('Error message', severity, state);

-- With parameters (like printf)
RAISERROR('Error in %s: Value %d is invalid', 16, 1, 'OrderProcess', -5);
-- Output: Error in OrderProcess: Value -5 is invalid

-- Common severities:
-- 10 or less: Informational (not error)
-- 11-16: User errors (most common)
-- 17-19: Resource/system errors
-- 20-25: Fatal errors (terminate connection)
```

### THROW (Modern, SQL Server 2012+)

```sql
-- Basic syntax (re-throw in CATCH)
BEGIN TRY
    -- code
END TRY
BEGIN CATCH
    THROW;  -- Re-throws the original error
END CATCH;

-- Throw custom error
THROW 50001, 'Custom error message', 1;

-- Note: THROW requires semicolon before it if not first statement
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;  -- Correct: preceded by semicolon (after ROLLBACK)
END CATCH;
```

### RAISERROR vs THROW

| Feature | RAISERROR | THROW |
|---------|-----------|-------|
| SQL Server version | All versions | 2012+ |
| Parameter substitution | ✅ Yes (`%s`, `%d`) | ❌ No |
| Severity specification | Required | Always 16 (can't change) |
| Re-throw original error | ❌ Must rebuild | ✅ Use THROW; alone |
| Terminate batch | Only severity ≥ 20 | Always terminates batch |
| Custom error number | Must be defined in sys.messages | Any number ≥ 50000 |

### Recommendation
```sql
-- Use THROW for new code (simpler, cleaner)
-- Use RAISERROR when you need:
--   - Parameter substitution
--   - Custom severity
--   - Compatibility with older SQL Server
```

---

## 3️⃣ Creating Custom Errors

### Add to sys.messages (for RAISERROR)

```sql
-- Add custom error
EXEC sp_addmessage 
    @msgnum = 50001, 
    @severity = 16,
    @msgtext = 'Invalid product ID: %d',
    @lang = 'us_english';

-- Use it
RAISERROR(50001, 16, 1, 999);
-- Output: Invalid product ID: 999

-- Drop custom error
EXEC sp_dropmessage @msgnum = 50001;
```

### Inline Custom Error (with THROW)

```sql
-- No need to register - just use number >= 50000
IF @ProductID IS NULL
    THROW 50001, 'Product ID cannot be null', 1;

IF @Quantity <= 0
    THROW 50002, 'Quantity must be positive', 1;
```

---

## 4️⃣ Error Handling with Transactions

### Critical Pattern: Always Handle Transaction State

```sql
CREATE PROCEDURE usp_TransferFunds
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- Recommended!
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate
        IF @Amount <= 0
            THROW 50001, 'Amount must be positive', 1;
        
        -- Check source balance
        DECLARE @Balance DECIMAL(18,2);
        SELECT @Balance = Balance FROM Accounts WHERE AccountID = @FromAccount;
        
        IF @Balance < @Amount
            THROW 50002, 'Insufficient funds', 1;
        
        -- Perform transfer
        UPDATE Accounts SET Balance = Balance - @Amount WHERE AccountID = @FromAccount;
        UPDATE Accounts SET Balance = Balance + @Amount WHERE AccountID = @ToAccount;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        -- ALWAYS check for open transaction!
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Re-throw the error
        THROW;
    END CATCH
END;
```

### Understanding XACT_ABORT

```sql
-- XACT_ABORT OFF (default): Some errors don't rollback
SET XACT_ABORT OFF;
BEGIN TRANSACTION;
    INSERT INTO Table1 VALUES (1);
    INSERT INTO Table1 VALUES (1);  -- PK violation - only this fails
    INSERT INTO Table1 VALUES (2);  -- This still runs!
COMMIT;
-- Result: Rows 1 and 2 are inserted (inconsistent!)

-- XACT_ABORT ON: Any error rolls back entire transaction
SET XACT_ABORT ON;
BEGIN TRANSACTION;
    INSERT INTO Table1 VALUES (1);
    INSERT INTO Table1 VALUES (1);  -- PK violation - ENTIRE tx rolls back
    INSERT INTO Table1 VALUES (2);  -- Never reaches this
COMMIT;
-- Result: Nothing inserted (consistent!)
```

### @@TRANCOUNT Explained

```sql
PRINT @@TRANCOUNT;  -- 0 (no transaction)

BEGIN TRANSACTION;
PRINT @@TRANCOUNT;  -- 1

BEGIN TRANSACTION;  -- Nested transaction
PRINT @@TRANCOUNT;  -- 2

COMMIT;
PRINT @@TRANCOUNT;  -- 1 (only decrements by 1)

COMMIT;
PRINT @@TRANCOUNT;  -- 0

-- NOTE: ROLLBACK sets @@TRANCOUNT to 0 immediately (rolls back all nested)
```

---

## 5️⃣ Nested TRY-CATCH

### Outer and Inner Error Handling

```sql
CREATE PROCEDURE usp_OuterProcedure
AS
BEGIN
    BEGIN TRY
        PRINT 'Starting outer procedure';
        
        BEGIN TRY
            PRINT 'Starting inner block';
            SELECT 1/0;  -- Error here
            PRINT 'This will not print';
        END TRY
        BEGIN CATCH
            PRINT 'Caught in inner CATCH: ' + ERROR_MESSAGE();
            -- Re-throw to outer
            THROW;
        END CATCH
        
        PRINT 'This will not print either';
    END TRY
    BEGIN CATCH
        PRINT 'Caught in outer CATCH: ' + ERROR_MESSAGE();
    END CATCH
END;
```

### Calling Procedures with Error Handling

```sql
CREATE PROCEDURE usp_CallingProcedure
AS
BEGIN
    BEGIN TRY
        EXEC usp_ProcedureThatMightFail;
        PRINT 'Procedure succeeded';
    END TRY
    BEGIN CATCH
        PRINT 'Procedure failed: ' + ERROR_MESSAGE();
        -- Handle or re-throw
    END CATCH
END;
```

---

## 6️⃣ Common Patterns

### Pattern 1: Log Error and Continue

```sql
CREATE PROCEDURE usp_ProcessOrders
AS
BEGIN
    DECLARE @OrderID INT;
    DECLARE cur CURSOR FOR SELECT OrderID FROM OrdersToProcess;
    
    OPEN cur;
    FETCH NEXT FROM cur INTO @OrderID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC usp_ProcessSingleOrder @OrderID;
        END TRY
        BEGIN CATCH
            -- Log error but continue processing other orders
            INSERT INTO ErrorLog (OrderID, ErrorMessage, ErrorDate)
            VALUES (@OrderID, ERROR_MESSAGE(), GETDATE());
        END CATCH
        
        FETCH NEXT FROM cur INTO @OrderID;
    END
    
    CLOSE cur;
    DEALLOCATE cur;
END;
```

### Pattern 2: Error with Details

```sql
CREATE PROCEDURE usp_InsertProduct
    @Name NVARCHAR(100),
    @Price DECIMAL(10,2)
AS
BEGIN
    BEGIN TRY
        INSERT INTO Products (Name, Price)
        VALUES (@Name, @Price);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg NVARCHAR(4000);
        SET @ErrorMsg = 'Failed to insert product. ' +
            'Name: ' + ISNULL(@Name, 'NULL') + ', ' +
            'Price: ' + ISNULL(CAST(@Price AS NVARCHAR), 'NULL') + '. ' +
            'Error: ' + ERROR_MESSAGE();
        
        THROW 50010, @ErrorMsg, 1;
    END CATCH
END;
```

### Pattern 3: Retry Logic

```sql
CREATE PROCEDURE usp_InsertWithRetry
    @Data NVARCHAR(100),
    @MaxRetries INT = 3
AS
BEGIN
    DECLARE @RetryCount INT = 0;
    DECLARE @Success BIT = 0;
    
    WHILE @RetryCount < @MaxRetries AND @Success = 0
    BEGIN
        BEGIN TRY
            INSERT INTO TargetTable (Data) VALUES (@Data);
            SET @Success = 1;
        END TRY
        BEGIN CATCH
            SET @RetryCount = @RetryCount + 1;
            
            IF @RetryCount >= @MaxRetries
                THROW;  -- Max retries reached, throw error
            
            -- Wait before retry (deadlock scenario)
            WAITFOR DELAY '00:00:01';
        END CATCH
    END
END;
```

### Pattern 4: Validation with Multiple Checks

```sql
CREATE PROCEDURE usp_CreateOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    -- Validate all inputs before any DML
    IF @CustomerID IS NULL
        THROW 50001, 'Customer ID is required', 1;
    
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = @CustomerID)
        THROW 50002, 'Customer not found', 1;
    
    IF @ProductID IS NULL
        THROW 50003, 'Product ID is required', 1;
    
    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
        THROW 50004, 'Product not found', 1;
    
    IF @Quantity IS NULL OR @Quantity <= 0
        THROW 50005, 'Quantity must be positive', 1;
    
    -- All validations passed, proceed with insert
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO Orders (CustomerID, ProductID, Quantity, OrderDate)
        VALUES (@CustomerID, @ProductID, @Quantity, GETDATE());
        
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
```

---

## 📋 Best Practices

### ✅ DO's

1. **Always use TRY-CATCH for critical operations**
2. **Always check @@TRANCOUNT before ROLLBACK**
3. **Use SET XACT_ABORT ON in procedures with transactions**
4. **Log errors for debugging**
5. **Include context in error messages**
6. **Use THROW for new code (SQL 2012+)**
7. **Validate inputs early, before any DML**

### ❌ DON'Ts

1. Don't ignore errors with empty CATCH blocks
2. Don't use `RETURN` to exit from CATCH without handling
3. Don't assume @@ERROR will still have value after another statement
4. Don't forget semicolon before THROW in CATCH
5. Don't mix RAISERROR and THROW unnecessarily

---

## 🎓 Interview Questions

### Q1: What is TRY-CATCH in SQL Server?
**A:** TRY-CATCH is structured error handling. Code in TRY block is executed; if an error occurs, execution jumps to CATCH block where you can handle the error using error functions.

### Q2: What error functions are available in CATCH block?
**A:** ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(), ERROR_PROCEDURE()

### Q3: Difference between RAISERROR and THROW?
**A:**
- THROW (2012+): Simpler, always severity 16, can re-throw with just `THROW;`
- RAISERROR: Older, supports parameter substitution, can specify severity

### Q4: What is XACT_ABORT?
**A:** When ON, any error automatically rolls back the entire transaction. When OFF (default), only some errors cause rollback. Recommended to set ON in procedures with transactions.

### Q5: What is @@TRANCOUNT?
**A:** System variable that returns the current transaction nesting level. 0 means no transaction is active. Important to check before ROLLBACK to avoid errors.

### Q6: Can TRY-CATCH catch all errors?
**A:** No. It cannot catch:
- Errors with severity ≤ 10 (informational)
- Errors with severity ≥ 20 that terminate connection
- Compile errors (syntax, object not found during compile)
- Statement-level recompilation errors

### Q7: How do you re-throw an error in CATCH?
**A:** Use `THROW;` without parameters. This re-throws the original error with all its original details.

### Q8: What happens if you don't check @@TRANCOUNT before ROLLBACK?
**A:** If there's no active transaction, ROLLBACK throws an error. Always check `IF @@TRANCOUNT > 0` before ROLLBACK.

### Q9: How to create a custom error?
**A:** 
- For THROW: Use any number ≥ 50000 inline
- For RAISERROR with message: Use sp_addmessage to register first

### Q10: What's the best practice for error handling in stored procedures?
**A:**
```sql
CREATE PROCEDURE MyProc AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        -- code
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
```

---

## 🔗 Related Topics
- [← Triggers](./03_triggers.md)
- [Transactions →](./05_transactions.md)
- [Dynamic SQL →](./06_dynamic_sql.md)

---

*Next: Learn about Transactions in depth*
