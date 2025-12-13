# Triggers - Complete Guide

## 📚 What You'll Learn
- What triggers are and when to use them
- Types of triggers (AFTER, INSTEAD OF, DDL)
- Working with INSERTED and DELETED tables
- Common trigger patterns
- Best practices and interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is a Trigger?

### Definition
A **trigger** is a special type of stored procedure that automatically executes in response to certain events on a table or view.

### Real-World Analogy
Think of a trigger like a **motion sensor light**:
- It activates automatically when someone walks by (event occurs)
- You don't have to manually turn it on
- It performs its action without your intervention

### Types of Triggers

| Type | When It Fires | Use Cases |
|------|---------------|-----------|
| **AFTER (FOR)** | After INSERT/UPDATE/DELETE completes | Auditing, cascading updates, logging |
| **INSTEAD OF** | Replaces the original operation | Custom logic on views, validation |
| **DDL** | On schema changes (CREATE/ALTER/DROP) | Prevent schema changes, audit DDL |
| **LOGON** | On user login events | Security monitoring |

---

## 1️⃣ AFTER Triggers (DML Triggers)

### Basic Syntax

```sql
CREATE TRIGGER trigger_name
ON table_name
AFTER INSERT, UPDATE, DELETE  -- Can be any combination
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Your trigger logic here
END;
```

### The Magic Tables: INSERTED and DELETED

When a trigger fires, SQL Server provides two special tables:

| Operation | INSERTED Contains | DELETED Contains |
|-----------|------------------|------------------|
| INSERT | New rows | Empty |
| UPDATE | New values | Old values |
| DELETE | Empty | Deleted rows |

```
┌─────────────────────────────────────────────────────────┐
│                     TRIGGER OPERATION                    │
├─────────────────────────────────────────────────────────┤
│ INSERT:   [INSERTED] = new rows    [DELETED] = empty   │
│ DELETE:   [INSERTED] = empty       [DELETED] = old rows│
│ UPDATE:   [INSERTED] = new values  [DELETED] = old vals│
└─────────────────────────────────────────────────────────┘
```

### Example: Audit Trail Trigger

```sql
-- Create audit table
CREATE TABLE AuditLog (
    AuditID INT IDENTITY PRIMARY KEY,
    TableName NVARCHAR(128),
    Operation NVARCHAR(10),
    RecordID INT,
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    ChangedBy NVARCHAR(128) DEFAULT SYSTEM_USER,
    ChangedAt DATETIME DEFAULT GETDATE()
);

-- Create trigger for Products table
CREATE TRIGGER trg_Products_Audit
ON Products
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordID, NewValues)
        SELECT 
            'Products', 
            'INSERT', 
            ProductID,
            CONCAT('Name: ', Name, ', Price: ', Price)
        FROM inserted;
    END
    
    -- Handle DELETE
    IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordID, OldValues)
        SELECT 
            'Products', 
            'DELETE', 
            ProductID,
            CONCAT('Name: ', Name, ', Price: ', Price)
        FROM deleted;
    END
    
    -- Handle UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditLog (TableName, Operation, RecordID, OldValues, NewValues)
        SELECT 
            'Products', 
            'UPDATE', 
            i.ProductID,
            CONCAT('Name: ', d.Name, ', Price: ', d.Price),
            CONCAT('Name: ', i.Name, ', Price: ', i.Price)
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID;
    END
END;
GO
```

### Example: Auto-Update Timestamp

```sql
CREATE TRIGGER trg_Products_UpdateTimestamp
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Products
    SET ModifiedDate = GETDATE()
    WHERE ProductID IN (SELECT ProductID FROM inserted);
END;
GO
```

### Example: Prevent Deletes

```sql
CREATE TRIGGER trg_Products_PreventDelete
ON Products
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Instead of deleting, restore and mark as inactive
    INSERT INTO Products (ProductID, Name, Price, IsActive)
    SELECT ProductID, Name, Price, 0  -- IsActive = 0
    FROM deleted;
    
    RAISERROR('Products cannot be deleted. Marked as inactive instead.', 16, 1);
END;
GO
```

---

## 2️⃣ INSTEAD OF Triggers

### What They Do
- **Replace** the original DML operation entirely
- Often used on views to make them updatable
- You must implement the actual logic yourself

### Syntax

```sql
CREATE TRIGGER trigger_name
ON table_or_view
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Your custom implementation
END;
```

### Example: Custom Insert with Validation

```sql
CREATE TRIGGER trg_Employees_InsteadOfInsert
ON Employees
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate data before inserting
    IF EXISTS (SELECT 1 FROM inserted WHERE Email NOT LIKE '%@%.%')
    BEGIN
        RAISERROR('Invalid email format', 16, 1);
        RETURN;
    END
    
    IF EXISTS (SELECT 1 FROM inserted WHERE Salary < 0)
    BEGIN
        RAISERROR('Salary cannot be negative', 16, 1);
        RETURN;
    END
    
    -- Perform the actual insert with modifications
    INSERT INTO Employees (FirstName, LastName, Email, Salary, HireDate)
    SELECT 
        UPPER(FirstName),  -- Uppercase first name
        UPPER(LastName),   -- Uppercase last name
        LOWER(Email),      -- Lowercase email
        Salary,
        ISNULL(HireDate, GETDATE())  -- Default hire date to today
    FROM inserted;
END;
GO
```

### Example: Make View Updatable

```sql
-- Create a view joining two tables
CREATE VIEW vw_EmployeeDepartment AS
SELECT 
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    e.DepartmentID,
    d.DepartmentName
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID;
GO

-- View can't be updated directly because of JOIN
-- Create INSTEAD OF trigger to enable updates
CREATE TRIGGER trg_vw_EmployeeDepartment_Update
ON vw_EmployeeDepartment
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update Employees table
    UPDATE e
    SET FirstName = i.FirstName,
        LastName = i.LastName,
        DepartmentID = i.DepartmentID
    FROM Employees e
    INNER JOIN inserted i ON e.EmployeeID = i.EmployeeID;
END;
GO

-- Now you can update the view!
UPDATE vw_EmployeeDepartment
SET DepartmentID = 2
WHERE EmployeeID = 5;
```

---

## 3️⃣ DDL Triggers

### What They Do
Fire on Data Definition Language events like CREATE, ALTER, DROP

### Syntax

```sql
CREATE TRIGGER trigger_name
ON DATABASE  -- or ON ALL SERVER
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE  -- Specific events
AS
BEGIN
    -- Your logic here
END;
```

### Example: Prevent Table Drops

```sql
CREATE TRIGGER trg_PreventTableDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'Table drops are not allowed in this database!';
    ROLLBACK;  -- Undo the DROP
END;
GO

-- Test it
DROP TABLE Products;  -- Will fail
```

### Example: Log All DDL Changes

```sql
-- Create log table
CREATE TABLE DDLAuditLog (
    LogID INT IDENTITY PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(256),
    ObjectType NVARCHAR(100),
    TSQLCommand NVARCHAR(MAX),
    LoginName NVARCHAR(256),
    EventDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER trg_DDLAudit
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO DDLAuditLog (EventType, ObjectName, ObjectType, TSQLCommand, LoginName)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(256)')
    );
END;
GO
```

### Example: Enforce Naming Convention

```sql
CREATE TRIGGER trg_EnforceNamingConvention
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE
AS
BEGIN
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @TableName NVARCHAR(256);
    
    SET @TableName = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)');
    
    -- Tables must start with 'tbl_'
    IF @TableName NOT LIKE 'tbl_%'
    BEGIN
        RAISERROR('Table names must start with "tbl_"', 16, 1);
        ROLLBACK;
    END
END;
GO
```

---

## 🔧 Managing Triggers

### Enable/Disable Triggers

```sql
-- Disable a specific trigger
DISABLE TRIGGER trg_Products_Audit ON Products;

-- Enable a specific trigger
ENABLE TRIGGER trg_Products_Audit ON Products;

-- Disable all triggers on a table
DISABLE TRIGGER ALL ON Products;

-- Enable all triggers on a table
ENABLE TRIGGER ALL ON Products;
```

### View Existing Triggers

```sql
-- List all triggers in database
SELECT 
    t.name AS TriggerName,
    OBJECT_NAME(t.parent_id) AS TableName,
    t.is_disabled,
    t.is_instead_of_trigger,
    OBJECTPROPERTY(t.object_id, 'ExecIsAfterTrigger') AS IsAfterTrigger
FROM sys.triggers t
WHERE t.parent_class = 1;  -- Object triggers

-- Get trigger definition
SELECT OBJECT_DEFINITION(OBJECT_ID('trg_Products_Audit'));
```

### Drop Triggers

```sql
DROP TRIGGER trg_Products_Audit ON Products;
DROP TRIGGER trg_DDLAudit ON DATABASE;
```

---

## ⚠️ Common Pitfalls

### 1. Triggers Can Fire Recursively

```sql
-- This trigger updates Products, which fires the trigger again!
CREATE TRIGGER trg_Dangerous
ON Products
AFTER UPDATE
AS
BEGIN
    UPDATE Products SET Price = Price * 1.1;  -- INFINITE LOOP!
END;

-- Solution: Check for recursion or disable recursive triggers
ALTER DATABASE YourDB SET RECURSIVE_TRIGGERS OFF;
```

### 2. Triggers Can Cause Performance Issues

```sql
-- BAD: Cursor in trigger (very slow)
CREATE TRIGGER trg_SlowTrigger
ON Orders
AFTER INSERT
AS
BEGIN
    DECLARE @OrderID INT;
    DECLARE cur CURSOR FOR SELECT OrderID FROM inserted;
    
    OPEN cur;
    FETCH NEXT FROM cur INTO @OrderID;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Process each row (SLOW!)
        FETCH NEXT FROM cur INTO @OrderID;
    END
    CLOSE cur;
    DEALLOCATE cur;
END;

-- GOOD: Set-based operation
CREATE TRIGGER trg_FastTrigger
ON Orders
AFTER INSERT
AS
BEGIN
    -- Process all rows at once (FAST!)
    INSERT INTO OrderLog (OrderID, LogDate)
    SELECT OrderID, GETDATE()
    FROM inserted;
END;
```

### 3. INSERTED/DELETED Can Have Multiple Rows

```sql
-- BAD: Assumes only one row
CREATE TRIGGER trg_BadAssumption
ON Products
AFTER INSERT
AS
BEGIN
    DECLARE @ProductID INT;
    SELECT @ProductID = ProductID FROM inserted;  -- Only gets ONE row!
END;

-- GOOD: Handle multiple rows
CREATE TRIGGER trg_HandleMultiple
ON Products
AFTER INSERT
AS
BEGIN
    -- Works for any number of rows
    INSERT INTO ProductLog (ProductID, Action)
    SELECT ProductID, 'INSERT'
    FROM inserted;  -- Handles all rows
END;
```

---

## 📋 Best Practices

### ✅ DO's
1. Always use `SET NOCOUNT ON`
2. Handle multiple rows (use set-based operations)
3. Keep triggers short and fast
4. Document what the trigger does
5. Test with bulk operations
6. Consider AFTER vs INSTEAD OF carefully

### ❌ DON'Ts
1. Don't use cursors in triggers
2. Don't call stored procedures with side effects
3. Don't use triggers for business logic that belongs in application
4. Don't create triggers that call other triggers
5. Don't forget about rollback cascading

---

## 🎓 Interview Questions

### Q1: What is a trigger?
**A:** A trigger is a special stored procedure that automatically executes in response to DML (INSERT, UPDATE, DELETE), DDL (CREATE, ALTER, DROP), or LOGON events. Unlike stored procedures, triggers cannot be called directly.

### Q2: What's the difference between AFTER and INSTEAD OF triggers?
**A:**
- **AFTER**: Fires after the operation completes. The original operation happens first, then the trigger runs. Used for auditing, logging.
- **INSTEAD OF**: Replaces the original operation. You must implement the logic yourself. Used for custom validation, making views updatable.

### Q3: What are INSERTED and DELETED tables?
**A:** Special tables available inside triggers:
- **INSERTED**: Contains new values (INSERT: new rows, UPDATE: new values)
- **DELETED**: Contains old values (DELETE: deleted rows, UPDATE: old values)

### Q4: Can a trigger call another trigger?
**A:** Yes, this is called nested triggers. A trigger can cause another trigger to fire. This can be controlled with the `RECURSIVE_TRIGGERS` database option and `nested triggers` server option.

### Q5: Can triggers prevent data modification?
**A:** Yes. Use `ROLLBACK` in the trigger to undo the entire transaction including the original operation that fired the trigger.

### Q6: What are DDL triggers?
**A:** Triggers that fire on Data Definition Language events like CREATE TABLE, ALTER PROCEDURE, DROP VIEW. Used for auditing schema changes or enforcing naming conventions.

### Q7: How do you debug triggers?
**A:** 
1. Use PRINT statements
2. Insert into debug/log tables
3. Use SQL Server Profiler
4. Disable trigger temporarily
5. Test with explicit transactions that you rollback

### Q8: What is the order of trigger execution?
**A:** For multiple triggers on same table:
- INSTEAD OF triggers fire first (only one allowed per action)
- AFTER triggers fire after, order is non-deterministic unless you use sp_settriggerorder

### Q9: Can you have multiple triggers on one table?
**A:** Yes for AFTER triggers. Only one INSTEAD OF trigger per action (INSERT, UPDATE, DELETE) is allowed.

### Q10: Why should you avoid cursors in triggers?
**A:** Cursors process row-by-row, which is extremely slow compared to set-based operations. Since triggers fire on every DML operation, slow triggers significantly impact performance.

---

## 🔗 Related Topics
- [← User-Defined Functions](./02_user_defined_functions.md)
- [Error Handling →](./04_error_handling.md)
- [Transactions →](./05_transactions.md)

---

*Next: Learn about Error Handling*
