![Module 05 Header](../assets/images/module_05_header.svg)

# Module 05: T-SQL Programming

**Duration**: 2 weeks (40-60 hours) | **Difficulty**: ⭐⭐⭐⭐ Advanced

## 📖 Overview
Master T-SQL programming: stored procedures, functions, triggers, error handling, and transactions for building robust database applications.

---

## 📚 Module Structure

| Section | Topic | Labs | Time |
|---------|-------|------|------|
| 01 | Stored Procedures | 3 | 6h |
| 02 | Functions (Scalar & Table-Valued) | 3 | 6h |
| 03 | Triggers (DML & DDL) | 3 | 6h |
| 04 | Error Handling (TRY/CATCH) | 2 | 5h |
| 05 | Transactions & Locking | 2 | 6h |
| 06 | Dynamic SQL | 2 | 5h |
| 07 | Best Practices & Optimization | 1 | 4h |
| **Capstone** | Order Processing System | 1 | 8h |

**Total**: 15 labs, 2 quizzes, 46 hours

---

## 🎯 Key Concepts

### Stored Procedures
```sql
CREATE PROCEDURE usp_GetCustomerOrders
    @CustomerID INT,
    @StartDate DATE = NULL,
    @TotalOrders INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT OrderID, OrderDate, TotalDue
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID
        AND (@StartDate IS NULL OR OrderDate >= @StartDate);
    
    SELECT @TotalOrders = @@ROWCOUNT;
END;

-- Execute
DECLARE @Count INT;
EXEC usp_GetCustomerOrders 
    @CustomerID = 29825,
    @StartDate = '2013-01-01',
    @TotalOrders = @Count OUTPUT;
PRINT 'Orders: ' + CAST(@Count AS VARCHAR);
```

### Functions
```sql
-- Scalar Function
CREATE FUNCTION dbo.fn_CalculateTax(@Amount DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @Amount * 0.08; -- 8% tax
END;

-- Inline Table-Valued Function (better performance)
CREATE FUNCTION dbo.fn_GetCustomersByRegion(@Region NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
    SELECT CustomerID, CustomerName, City
    FROM Sales.Customer
    WHERE Region = @Region
);

-- Use in query
SELECT * FROM dbo.fn_GetCustomersByRegion('West');
```

### Triggers
```sql
-- Audit trigger
CREATE TRIGGER trg_CustomerAudit
ON Sales.Customer
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLog (TableName, Action, ModifiedBy, ModifiedDate)
    SELECT 
        'Customer',
        CASE 
            WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPDATE'
            WHEN EXISTS(SELECT * FROM inserted) THEN 'INSERT'
            ELSE 'DELETE'
        END,
        SUSER_SNAME(),
        GETDATE();
END;
```

### Error Handling
```sql
CREATE PROCEDURE usp_SafeInsertOrder
    @CustomerID INT,
    @TotalDue DECIMAL(10,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO Sales.SalesOrderHeader (CustomerID, OrderDate, TotalDue)
        VALUES (@CustomerID, GETDATE(), @TotalDue);
        
        COMMIT TRANSACTION;
        PRINT 'Order inserted successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH;
END;
```

### Transactions & Isolation Levels
```sql
-- Read Uncommitted (dirty reads allowed)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Read Committed (default - no dirty reads)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Repeatable Read (locks held until end)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Serializable (full locking)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Transaction example
BEGIN TRANSACTION;
    UPDATE Inventory SET Quantity = Quantity - 10 WHERE ProductID = 100;
    INSERT INTO OrderDetail (OrderID, ProductID, Quantity) VALUES (1, 100, 10);
COMMIT TRANSACTION;
```

---

## 📝 Labs

**Labs 36-40**: Stored procedures (CRUD, parameters, OUTPUT)  
**Labs 41-43**: Functions (scalar, inline TVF, multi-statement TVF)  
**Labs 44-46**: Triggers (audit, validation, cascade)  
**Labs 47-48**: Error handling and logging  
**Labs 49-50**: Transactions and deadlock scenarios  
**Lab 51**: Dynamic SQL and SQL injection prevention  
**Lab 52**: Capstone - Order processing system with all concepts

---

## 🎓 Assessment
- Labs: 40%
- Quiz 07 (Week 1): 15%
- Quiz 08 (Week 2): 15%
- Capstone: 30%

**Passing**: 70%

---

## 🔗 Navigation

| Direction | Link |
|-----------|------|
| ⬅️ Previous | [Module 04: Database Administration](../Module_04_Database_Administration/) |
| ➡️ Next | [Module 06: ETL with SSIS](../Module_06_ETL_SSIS/) |
| 🏠 Home | [Main Curriculum](../README.md) |
| 📚 Resources | [Study Materials](../Resources/) |
