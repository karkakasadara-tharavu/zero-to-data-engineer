/*
 * Lab 44: Triggers - INSTEAD OF Triggers
 * Module 05: T-SQL Programming
 * 
 * Objective: Master INSTEAD OF triggers for complex logic
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 44: INSTEAD OF Triggers';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: BASIC INSTEAD OF INSERT
 */

PRINT 'PART 1: INSTEAD OF INSERT Trigger';
PRINT '-----------------------------------';

-- Create view for book display
IF OBJECT_ID('vw_BookDisplay', 'V') IS NOT NULL DROP VIEW vw_BookDisplay;
GO

CREATE VIEW vw_BookDisplay
AS
SELECT 
    b.BookID,
    b.Title,
    b.ISBN,
    b.Price,
    a.FirstName + ' ' + a.LastName AS AuthorName,
    c.CategoryName
FROM Books b
LEFT JOIN Authors a ON b.AuthorID = a.AuthorID
LEFT JOIN Categories c ON b.CategoryID = c.CategoryID;
GO

PRINT '✓ Created vw_BookDisplay';

-- Create INSTEAD OF INSERT trigger
IF OBJECT_ID('trg_vw_BookDisplay_Insert', 'TR') IS NOT NULL DROP TRIGGER trg_vw_BookDisplay_Insert;
GO

CREATE TRIGGER trg_vw_BookDisplay_Insert
ON vw_BookDisplay
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Parse inserted data
    DECLARE @AuthorName NVARCHAR(200);
    DECLARE @CategoryName NVARCHAR(100);
    
    -- Process each inserted row
    INSERT INTO Books (Title, ISBN, Price, AuthorID, CategoryID)
    SELECT 
        i.Title,
        i.ISBN,
        i.Price,
        (SELECT TOP 1 AuthorID FROM Authors 
         WHERE FirstName + ' ' + LastName = i.AuthorName),
        (SELECT CategoryID FROM Categories WHERE CategoryName = i.CategoryName)
    FROM INSERTED i;
    
    PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' book(s) inserted via view';
END;
GO

PRINT '✓ Created trg_vw_BookDisplay_Insert';

-- Test insert through view
INSERT INTO vw_BookDisplay (Title, ISBN, Price, AuthorName, CategoryName)
VALUES ('View Insert Test', '888-8-88-888888-8', 19.99, 'John Smith', 'Fiction');

SELECT * FROM vw_BookDisplay WHERE Title = 'View Insert Test';
PRINT '';

/*
 * PART 2: INSTEAD OF UPDATE
 */

PRINT 'PART 2: INSTEAD OF UPDATE Trigger';
PRINT '-----------------------------------';

IF OBJECT_ID('trg_vw_BookDisplay_Update', 'TR') IS NOT NULL DROP TRIGGER trg_vw_BookDisplay_Update;
GO

CREATE TRIGGER trg_vw_BookDisplay_Update
ON vw_BookDisplay
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update only the base table (Books)
    -- Ignore updates to calculated columns
    UPDATE b
    SET 
        Title = i.Title,
        ISBN = i.ISBN,
        Price = i.Price
    FROM Books b
    INNER JOIN INSERTED i ON b.BookID = i.BookID;
    
    PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' book(s) updated via view';
END;
GO

PRINT '✓ Created trg_vw_BookDisplay_Update';

-- Test update through view
UPDATE vw_BookDisplay
SET Price = 24.99
WHERE Title = 'View Insert Test';

SELECT * FROM vw_BookDisplay WHERE Title = 'View Insert Test';
PRINT '';

/*
 * PART 3: INSTEAD OF DELETE (SOFT DELETE)
 */

PRINT 'PART 3: INSTEAD OF DELETE - Soft Delete';
PRINT '-----------------------------------------';

-- Add IsDeleted column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Books') AND name = 'IsDeleted')
    ALTER TABLE Books ADD IsDeleted BIT DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Books') AND name = 'DeletedDate')
    ALTER TABLE Books ADD DeletedDate DATETIME2 NULL;

IF OBJECT_ID('trg_Books_SoftDelete', 'TR') IS NOT NULL DROP TRIGGER trg_Books_SoftDelete;
GO

CREATE TRIGGER trg_Books_SoftDelete
ON Books
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Mark as deleted instead of actual deletion
    UPDATE b
    SET 
        IsDeleted = 1,
        DeletedDate = SYSDATETIME()
    FROM Books b
    INNER JOIN DELETED d ON b.BookID = d.BookID;
    
    PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' book(s) soft deleted';
    PRINT '(Records marked as deleted, not physically removed)';
END;
GO

PRINT '✓ Created trg_Books_SoftDelete';

-- Test soft delete
DELETE FROM Books WHERE Title = 'View Insert Test';

SELECT BookID, Title, IsDeleted, DeletedDate
FROM Books
WHERE Title = 'View Insert Test';
PRINT '';

/*
 * PART 4: DATA VALIDATION AND TRANSFORMATION
 */

PRINT 'PART 4: Data Validation Transform';
PRINT '-----------------------------------';

IF OBJECT_ID('trg_Orders_ValidateInsert', 'TR') IS NOT NULL DROP TRIGGER trg_Orders_ValidateInsert;
GO

CREATE TRIGGER trg_Orders_ValidateInsert
ON Orders
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate and transform data
    DECLARE @ValidatedOrders TABLE (
        CustomerID INT,
        OrderDate DATETIME2,
        TotalAmount DECIMAL(10,2),
        Status NVARCHAR(50),
        ValidationMessage NVARCHAR(200)
    );
    
    INSERT INTO @ValidatedOrders
    SELECT 
        CustomerID,
        CASE 
            WHEN OrderDate IS NULL THEN GETDATE()
            WHEN OrderDate > GETDATE() THEN GETDATE()
            ELSE OrderDate
        END,
        CASE 
            WHEN TotalAmount < 0 THEN 0
            ELSE TotalAmount
        END,
        CASE 
            WHEN Status IS NULL THEN 'Pending'
            WHEN Status NOT IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled') 
                THEN 'Pending'
            ELSE Status
        END,
        CASE 
            WHEN OrderDate > GETDATE() THEN 'Future date adjusted to today'
            WHEN TotalAmount < 0 THEN 'Negative amount adjusted to 0'
            WHEN Status NOT IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled') 
                THEN 'Invalid status changed to Pending'
            ELSE 'Validated'
        END
    FROM INSERTED;
    
    -- Insert validated data
    INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
    SELECT CustomerID, OrderDate, TotalAmount, Status
    FROM @ValidatedOrders;
    
    -- Report validation results
    SELECT ValidationMessage, COUNT(*) AS Count
    FROM @ValidatedOrders
    GROUP BY ValidationMessage;
END;
GO

PRINT '✓ Created trg_Orders_ValidateInsert';

-- Test validation
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
VALUES 
    (1, '2025-12-31', 100, 'Pending'),  -- Future date
    (2, GETDATE(), -50, 'Processing'),  -- Negative amount
    (3, GETDATE(), 200, 'InvalidStatus'); -- Invalid status

PRINT '';

/*
 * PART 5: COMPLEX MULTI-TABLE UPDATE
 */

PRINT 'PART 5: Multi-Table Update';
PRINT '----------------------------';

-- Create comprehensive customer view
IF OBJECT_ID('vw_CustomerSummary', 'V') IS NOT NULL DROP VIEW vw_CustomerSummary;
GO

CREATE VIEW vw_CustomerSummary
AS
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    COUNT(o.OrderID) AS OrderCount,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email;
GO

IF OBJECT_ID('trg_vw_CustomerSummary_Update', 'TR') IS NOT NULL DROP TRIGGER trg_vw_CustomerSummary_Update;
GO

CREATE TRIGGER trg_vw_CustomerSummary_Update
ON vw_CustomerSummary
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only update columns from base table
    UPDATE c
    SET 
        FirstName = i.FirstName,
        LastName = i.LastName,
        Email = i.Email
    FROM Customers c
    INNER JOIN INSERTED i ON c.CustomerID = i.CustomerID
    WHERE 
        c.FirstName <> i.FirstName 
        OR c.LastName <> i.LastName 
        OR c.Email <> i.Email;
    
    PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' customer(s) updated';
    
    -- Cannot update calculated columns
    IF EXISTS (
        SELECT 1 FROM INSERTED i
        INNER JOIN DELETED d ON i.CustomerID = d.CustomerID
        WHERE i.OrderCount <> d.OrderCount OR i.TotalSpent <> d.TotalSpent
    )
    BEGIN
        PRINT 'WARNING: OrderCount and TotalSpent are calculated columns and cannot be updated';
    END;
END;
GO

PRINT '✓ Created trg_vw_CustomerSummary_Update';
PRINT '';

/*
 * PART 6: CONDITIONAL INSERT
 */

PRINT 'PART 6: Conditional Insert Logic';
PRINT '----------------------------------';

IF OBJECT_ID('trg_Books_ConditionalInsert', 'TR') IS NOT NULL DROP TRIGGER trg_Books_ConditionalInsert;
GO

CREATE TRIGGER trg_Books_ConditionalInsert
ON Books
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for duplicates by ISBN
    IF EXISTS (
        SELECT 1 FROM INSERTED i
        INNER JOIN Books b ON i.ISBN = b.ISBN
        WHERE b.IsDeleted = 0
    )
    BEGIN
        -- Don't insert, just report
        SELECT 
            i.ISBN,
            i.Title AS NewTitle,
            b.Title AS ExistingTitle,
            'Duplicate ISBN - Insert prevented' AS Message
        FROM INSERTED i
        INNER JOIN Books b ON i.ISBN = b.ISBN
        WHERE b.IsDeleted = 0;
        
        RETURN;
    END;
    
    -- Check if restoring soft-deleted book
    IF EXISTS (
        SELECT 1 FROM INSERTED i
        INNER JOIN Books b ON i.ISBN = b.ISBN
        WHERE b.IsDeleted = 1
    )
    BEGIN
        -- Restore soft-deleted record
        UPDATE b
        SET 
            IsDeleted = 0,
            DeletedDate = NULL,
            Title = i.Title,
            Price = i.Price
        FROM Books b
        INNER JOIN INSERTED i ON b.ISBN = i.ISBN
        WHERE b.IsDeleted = 1;
        
        PRINT 'Restored ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' previously deleted book(s)';
        RETURN;
    END;
    
    -- Normal insert for new books
    INSERT INTO Books (Title, ISBN, Price, PublicationYear, AuthorID, CategoryID)
    SELECT Title, ISBN, Price, PublicationYear, AuthorID, CategoryID
    FROM INSERTED;
    
    PRINT 'Inserted ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' new book(s)';
END;
GO

PRINT '✓ Created trg_Books_ConditionalInsert';
PRINT '';

/*
 * PART 7: AUDIT TRAIL WITH INSTEAD OF
 */

PRINT 'PART 7: Audit Trail Integration';
PRINT '---------------------------------';

-- Create detailed audit table
IF OBJECT_ID('DetailedAudit', 'U') IS NOT NULL DROP TABLE DetailedAudit;
CREATE TABLE DetailedAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(128),
    Operation NVARCHAR(10),
    RecordID INT,
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    ChangedBy NVARCHAR(128) DEFAULT SUSER_SNAME(),
    ChangedDate DATETIME2 DEFAULT SYSDATETIME(),
    ApplicationName NVARCHAR(128) DEFAULT APP_NAME()
);

IF OBJECT_ID('trg_Customers_AuditUpdate', 'TR') IS NOT NULL DROP TRIGGER trg_Customers_AuditUpdate;
GO

CREATE TRIGGER trg_Customers_AuditUpdate
ON Customers
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Perform the update
    UPDATE c
    SET 
        FirstName = i.FirstName,
        LastName = i.LastName,
        Email = i.Email
    FROM Customers c
    INNER JOIN INSERTED i ON c.CustomerID = i.CustomerID;
    
    -- Log changes with old and new values
    INSERT INTO DetailedAudit (TableName, Operation, RecordID, OldValues, NewValues)
    SELECT 
        'Customers',
        'UPDATE',
        i.CustomerID,
        (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM INSERTED i
    INNER JOIN DELETED d ON i.CustomerID = d.CustomerID;
    
    PRINT 'Updated and audited ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' customer(s)';
END;
GO

PRINT '✓ Created trg_Customers_AuditUpdate';

-- Test audit
UPDATE Customers
SET Email = 'newemail@example.com'
WHERE CustomerID = 1;

SELECT TOP 1 * FROM DetailedAudit ORDER BY ChangedDate DESC;
PRINT '';

/*
 * PART 8: BUSINESS RULE ENFORCEMENT
 */

PRINT 'PART 8: Business Rule Enforcement';
PRINT '-----------------------------------';

IF OBJECT_ID('trg_Orders_BusinessRules', 'TR') IS NOT NULL DROP TRIGGER trg_Orders_BusinessRules;
GO

CREATE TRIGGER trg_Orders_BusinessRules
ON Orders
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(10) = 
        CASE WHEN EXISTS (SELECT * FROM DELETED) THEN 'UPDATE' ELSE 'INSERT' END;
    
    -- Rule 1: Cannot create orders for inactive customers
    IF EXISTS (
        SELECT 1 FROM INSERTED i
        INNER JOIN Customers c ON i.CustomerID = c.CustomerID
        WHERE c.IsActive = 0
    )
    BEGIN
        RAISERROR('Cannot create/update orders for inactive customers', 16, 1);
        RETURN;
    END;
    
    -- Rule 2: Order total must match sum of order items
    -- (Simplified check - assumes order items exist)
    
    -- Rule 3: Cannot change order status from Delivered back to Processing
    IF @Action = 'UPDATE'
    BEGIN
        IF EXISTS (
            SELECT 1 FROM INSERTED i
            INNER JOIN DELETED d ON i.OrderID = d.OrderID
            WHERE d.Status = 'Delivered' AND i.Status IN ('Pending', 'Processing')
        )
        BEGIN
            RAISERROR('Cannot revert delivered orders to earlier status', 16, 1);
            RETURN;
        END;
    END;
    
    -- Rules passed - perform action
    IF @Action = 'INSERT'
    BEGIN
        INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
        SELECT CustomerID, OrderDate, TotalAmount, Status
        FROM INSERTED;
        
        PRINT 'Order(s) created with business rules validated';
    END
    ELSE
    BEGIN
        UPDATE o
        SET 
            Status = i.Status,
            TotalAmount = i.TotalAmount
        FROM Orders o
        INNER JOIN INSERTED i ON o.OrderID = i.OrderID;
        
        PRINT 'Order(s) updated with business rules validated';
    END;
END;
GO

PRINT '✓ Created trg_Orders_BusinessRules';
PRINT '';

/*
 * PART 9: PARTITIONED VIEW UPDATES
 */

PRINT 'PART 9: Partitioned View Updates';
PRINT '----------------------------------';
PRINT '';
PRINT 'INSTEAD OF triggers enable updates to partitioned views:';
PRINT '  - Views combining multiple tables (UNION ALL)';
PRINT '  - Distributed data across servers';
PRINT '  - Route INSERTs to correct partition';
PRINT '';
PRINT 'Example structure:';
PRINT '  CREATE VIEW AllOrders AS';
PRINT '    SELECT * FROM Orders2023';
PRINT '    UNION ALL';
PRINT '    SELECT * FROM Orders2024;';
PRINT '';
PRINT '  CREATE TRIGGER trg_AllOrders_Insert';
PRINT '  ON AllOrders INSTEAD OF INSERT';
PRINT '  AS';
PRINT '    INSERT INTO Orders2024 SELECT * FROM INSERTED';
PRINT '    WHERE YEAR(OrderDate) = 2024;';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: INSTEAD OF Trigger Best Practices';
PRINT '--------------------------------------------';
PRINT '';
PRINT 'USE CASES:';
PRINT '  ✓ Updatable views (multi-table views)';
PRINT '  ✓ Soft deletes (mark deleted, don''t remove)';
PRINT '  ✓ Data validation and transformation';
PRINT '  ✓ Complex business rules';
PRINT '  ✓ Conditional logic (insert vs update existing)';
PRINT '  ✓ Audit logging with full control';
PRINT '  ✓ Partitioned view routing';
PRINT '';
PRINT 'AFTER vs INSTEAD OF:';
PRINT '  AFTER:';
PRINT '    - Fires AFTER action completes';
PRINT '    - Cannot prevent action';
PRINT '    - Can roll back in trigger';
PRINT '    - Use for: audit, cascade, validation';
PRINT '';
PRINT '  INSTEAD OF:';
PRINT '    - Fires BEFORE action (replaces it)';
PRINT '    - Full control over action';
PRINT '    - Must implement the action manually';
PRINT '    - Use for: views, soft delete, transforms';
PRINT '';
PRINT 'CONSIDERATIONS:';
PRINT '  - More complex than AFTER triggers';
PRINT '  - Must handle INSERT, UPDATE, DELETE explicitly';
PRINT '  - Check for INSERTED and DELETED tables';
PRINT '  - Handle multi-row operations';
PRINT '  - Test edge cases thoroughly';
PRINT '  - Document expected behavior';
PRINT '';
PRINT 'PERFORMANCE:';
PRINT '  - Can be slower than AFTER (more logic)';
PRINT '  - Avoid nested triggers';
PRINT '  - Keep logic efficient';
PRINT '  - Use indexes on underlying tables';
PRINT '';

-- View all INSTEAD OF triggers
SELECT 
    OBJECT_SCHEMA_NAME(parent_id) + '.' + OBJECT_NAME(parent_id) AS ObjectName,
    name AS TriggerName,
    type_desc AS ObjectType,
    is_instead_of_trigger AS IsInsteadOf
FROM sys.triggers
WHERE is_instead_of_trigger = 1
ORDER BY ObjectName, TriggerName;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create INSTEAD OF trigger for order deletion that archives to OrderHistory
 * 2. Create view joining Orders + Customers with INSTEAD OF INSERT trigger
 * 3. Create INSTEAD OF UPDATE that validates email format before updating
 * 4. Create soft delete system for multiple tables with restore capability
 * 5. Create INSTEAD OF trigger that prevents weekend order insertions
 * 
 * CHALLENGE:
 * Create complete soft delete framework:
 * - Add IsDeleted, DeletedDate, DeletedBy to 5 tables
 * - Create INSTEAD OF DELETE triggers for each
 * - Create stored procedure usp_RestoreDeleted(@TableName, @RecordID)
 * - Create view showing all soft-deleted records across tables
 * - Create cleanup job to hard-delete records older than 90 days
 * - Add referential integrity checks (can't delete if children exist)
 */

PRINT '✓ Lab 44 Complete: INSTEAD OF triggers mastered';
GO
