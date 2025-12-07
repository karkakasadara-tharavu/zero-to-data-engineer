/*
 * Lab 43: Triggers - AFTER Triggers
 * Module 05: T-SQL Programming
 * 
 * Objective: Master AFTER triggers for auditing and validation
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 43: AFTER Triggers';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: BASIC AFTER INSERT TRIGGER
 */

PRINT 'PART 1: AFTER INSERT Trigger';
PRINT '-----------------------------';

-- Create audit log table
IF OBJECT_ID('BookAuditLog', 'U') IS NOT NULL DROP TABLE BookAuditLog;
CREATE TABLE BookAuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT,
    Action NVARCHAR(10),
    OldPrice DECIMAL(10,2),
    NewPrice DECIMAL(10,2),
    ChangedBy NVARCHAR(128) DEFAULT SUSER_SNAME(),
    ChangedDate DATETIME2 DEFAULT SYSDATETIME()
);

PRINT '✓ Created BookAuditLog table';

-- Create AFTER INSERT trigger
IF OBJECT_ID('trg_Books_AfterInsert', 'TR') IS NOT NULL DROP TRIGGER trg_Books_AfterInsert;
GO

CREATE TRIGGER trg_Books_AfterInsert
ON Books
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO BookAuditLog (BookID, Action, OldPrice, NewPrice)
    SELECT 
        BookID,
        'INSERT',
        NULL,
        Price
    FROM INSERTED;
    
    PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' book(s) logged in audit';
END;
GO

PRINT '✓ Created trg_Books_AfterInsert';

-- Test trigger
INSERT INTO Books (Title, ISBN, Price, PublicationYear)
VALUES ('Trigger Test Book', '999-9-99-999999-9', 29.99, 2024);

SELECT * FROM BookAuditLog;
PRINT '';

/*
 * PART 2: AFTER UPDATE TRIGGER
 */

PRINT 'PART 2: AFTER UPDATE Trigger';
PRINT '-----------------------------';

IF OBJECT_ID('trg_Books_AfterUpdate', 'TR') IS NOT NULL DROP TRIGGER trg_Books_AfterUpdate;
GO

CREATE TRIGGER trg_Books_AfterUpdate
ON Books
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only log if price changed
    IF UPDATE(Price)
    BEGIN
        INSERT INTO BookAuditLog (BookID, Action, OldPrice, NewPrice)
        SELECT 
            i.BookID,
            'UPDATE',
            d.Price AS OldPrice,
            i.Price AS NewPrice
        FROM INSERTED i
        INNER JOIN DELETED d ON i.BookID = d.BookID
        WHERE i.Price <> d.Price;
        
        PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' price change(s) logged';
    END;
END;
GO

PRINT '✓ Created trg_Books_AfterUpdate';

-- Test trigger
UPDATE Books
SET Price = 34.99
WHERE ISBN = '999-9-99-999999-9';

SELECT * FROM BookAuditLog ORDER BY ChangedDate DESC;
PRINT '';

/*
 * PART 3: AFTER DELETE TRIGGER
 */

PRINT 'PART 3: AFTER DELETE Trigger';
PRINT '-----------------------------';

IF OBJECT_ID('trg_Books_AfterDelete', 'TR') IS NOT NULL DROP TRIGGER trg_Books_AfterDelete;
GO

CREATE TRIGGER trg_Books_AfterDelete
ON Books
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO BookAuditLog (BookID, Action, OldPrice, NewPrice)
    SELECT 
        BookID,
        'DELETE',
        Price,
        NULL
    FROM DELETED;
    
    PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' deletion(s) logged';
END;
GO

PRINT '✓ Created trg_Books_AfterDelete';

-- Test trigger (commented to preserve test data)
-- DELETE FROM Books WHERE ISBN = '999-9-99-999999-9';
-- SELECT * FROM BookAuditLog ORDER BY ChangedDate DESC;
PRINT '';

/*
 * PART 4: MULTI-ROW TRIGGER HANDLING
 */

PRINT 'PART 4: Multi-Row Operations';
PRINT '------------------------------';

IF OBJECT_ID('trg_Books_BulkUpdate', 'TR') IS NOT NULL DROP TRIGGER trg_Books_BulkUpdate;
GO

CREATE TRIGGER trg_Books_BulkUpdate
ON Books
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowCount INT = (SELECT COUNT(*) FROM INSERTED);
    
    -- Handle multiple rows correctly
    IF @RowCount > 1
    BEGIN
        PRINT 'Bulk update detected: ' + CAST(@RowCount AS NVARCHAR(10)) + ' rows';
    END;
    
    -- Process all rows (not just first)
    INSERT INTO BookAuditLog (BookID, Action, OldPrice, NewPrice)
    SELECT 
        i.BookID,
        'BULK UPDATE',
        d.Price,
        i.Price
    FROM INSERTED i
    INNER JOIN DELETED d ON i.BookID = d.BookID;
END;
GO

PRINT '✓ Created trg_Books_BulkUpdate (multi-row aware)';

-- Test with multiple rows
UPDATE Books
SET Price = Price * 1.05
WHERE PublicationYear = 2024;

PRINT '';

/*
 * PART 5: VALIDATION TRIGGER
 */

PRINT 'PART 5: Data Validation Trigger';
PRINT '---------------------------------';

IF OBJECT_ID('trg_Orders_ValidateAmount', 'TR') IS NOT NULL DROP TRIGGER trg_Orders_ValidateAmount;
GO

CREATE TRIGGER trg_Orders_ValidateAmount
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for negative amounts
    IF EXISTS (SELECT 1 FROM INSERTED WHERE TotalAmount < 0)
    BEGIN
        RAISERROR('Order amount cannot be negative', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Check for unrealistic amounts
    IF EXISTS (SELECT 1 FROM INSERTED WHERE TotalAmount > 100000)
    BEGIN
        RAISERROR('Order amount exceeds maximum allowed ($100,000)', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    PRINT 'Order validation passed';
END;
GO

PRINT '✓ Created trg_Orders_ValidateAmount';

-- Test validation
BEGIN TRY
    INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
    VALUES (1, GETDATE(), -100, 'Pending');
END TRY
BEGIN CATCH
    PRINT 'Caught error: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

/*
 * PART 6: CALCULATED COLUMN UPDATE
 */

PRINT 'PART 6: Automatic Calculation Trigger';
PRINT '---------------------------------------';

-- Add TotalOrderValue column to Customers
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'TotalOrderValue')
    ALTER TABLE Customers ADD TotalOrderValue DECIMAL(10,2) DEFAULT 0;

IF OBJECT_ID('trg_Orders_UpdateCustomerTotal', 'TR') IS NOT NULL DROP TRIGGER trg_Orders_UpdateCustomerTotal;
GO

CREATE TRIGGER trg_Orders_UpdateCustomerTotal
ON Orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get affected customers
    DECLARE @AffectedCustomers TABLE (CustomerID INT);
    
    INSERT INTO @AffectedCustomers
    SELECT DISTINCT CustomerID FROM INSERTED
    UNION
    SELECT DISTINCT CustomerID FROM DELETED;
    
    -- Recalculate totals for affected customers
    UPDATE c
    SET TotalOrderValue = ISNULL(totals.Total, 0)
    FROM Customers c
    INNER JOIN @AffectedCustomers ac ON c.CustomerID = ac.CustomerID
    LEFT JOIN (
        SELECT CustomerID, SUM(TotalAmount) AS Total
        FROM Orders
        GROUP BY CustomerID
    ) totals ON c.CustomerID = totals.CustomerID;
    
    PRINT 'Updated TotalOrderValue for ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' customer(s)';
END;
GO

PRINT '✓ Created trg_Orders_UpdateCustomerTotal';

-- Test calculation
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
VALUES (1, GETDATE(), 500.00, 'Pending');

SELECT CustomerID, FirstName, LastName, TotalOrderValue
FROM Customers
WHERE CustomerID = 1;
PRINT '';

/*
 * PART 7: CASCADE UPDATE TRIGGER
 */

PRINT 'PART 7: Cascade Operations';
PRINT '----------------------------';

IF OBJECT_ID('trg_Products_UpdateInventory', 'TR') IS NOT NULL DROP TRIGGER trg_Products_UpdateInventory;
GO

CREATE TRIGGER trg_Products_UpdateInventory
ON Inventory.Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if stock quantity changed
    IF UPDATE(StockQuantity)
    BEGIN
        -- Alert if stock below reorder level
        DECLARE @LowStockProducts TABLE (
            ProductID INT,
            ProductName NVARCHAR(200),
            StockQuantity INT,
            ReorderLevel INT
        );
        
        INSERT INTO @LowStockProducts
        SELECT 
            i.ProductID,
            i.ProductName,
            i.StockQuantity,
            i.ReorderLevel
        FROM INSERTED i
        WHERE i.StockQuantity < i.ReorderLevel;
        
        IF EXISTS (SELECT 1 FROM @LowStockProducts)
        BEGIN
            PRINT 'LOW STOCK ALERT:';
            SELECT * FROM @LowStockProducts;
        END;
    END;
END;
GO

PRINT '✓ Created trg_Products_UpdateInventory';

-- Test low stock alert
UPDATE Inventory.Products
SET StockQuantity = 5
WHERE ProductID = 1;
PRINT '';

/*
 * PART 8: TRIGGER WITH ERROR HANDLING
 */

PRINT 'PART 8: Trigger Error Handling';
PRINT '--------------------------------';

IF OBJECT_ID('trg_Orders_SafeInsert', 'TR') IS NOT NULL DROP TRIGGER trg_Orders_SafeInsert;
GO

CREATE TRIGGER trg_Orders_SafeInsert
ON Orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate customer exists
        IF EXISTS (
            SELECT 1 FROM INSERTED i
            WHERE NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = i.CustomerID)
        )
        BEGIN
            THROW 50001, 'Invalid CustomerID in order', 1;
        END;
        
        -- Log successful insert
        PRINT 'Order(s) inserted successfully';
        
    END TRY
    BEGIN CATCH
        -- Rollback and log error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        INSERT INTO ErrorLog (ErrorProcedure, ErrorNumber, ErrorMessage)
        VALUES ('trg_Orders_SafeInsert', ERROR_NUMBER(), ERROR_MESSAGE());
        
        THROW;
    END CATCH;
END;
GO

PRINT '✓ Created trg_Orders_SafeInsert';
PRINT '';

/*
 * PART 9: NESTED TRIGGER HANDLING
 */

PRINT 'PART 9: Nested Triggers';
PRINT '------------------------';
PRINT '';
PRINT 'NESTED TRIGGERS:';
PRINT '  - Trigger fires another trigger';
PRINT '  - Maximum nesting level: 32';
PRINT '  - Can cause infinite loops!';
PRINT '  - Use TRIGGER_NESTLEVEL() to detect';
PRINT '';

IF OBJECT_ID('trg_PreventNesting', 'TR') IS NOT NULL DROP TRIGGER trg_PreventNesting;
GO

CREATE TRIGGER trg_PreventNesting
ON Books
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Prevent nested execution
    IF TRIGGER_NESTLEVEL() > 1
    BEGIN
        PRINT 'Nested trigger detected - skipping execution';
        RETURN;
    END;
    
    PRINT 'First-level trigger execution';
    -- Regular trigger logic here
END;
GO

PRINT '✓ Created trg_PreventNesting';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Trigger Best Practices';
PRINT '---------------------------------';
PRINT '';
PRINT 'DO:';
PRINT '  - Keep triggers short and fast';
PRINT '  - Handle multiple rows (not just first)';
PRINT '  - Use SET NOCOUNT ON';
PRINT '  - Log errors appropriately';
PRINT '  - Document trigger purpose';
PRINT '';
PRINT 'DON''T:';
PRINT '  - Return result sets';
PRINT '  - Use PRINT statements (in production)';
PRINT '  - Create infinite loops';
PRINT '  - Perform slow operations';
PRINT '  - Ignore DELETED/INSERTED tables';
PRINT '';
PRINT 'PERFORMANCE:';
PRINT '  - Triggers run in transaction (blocks other operations)';
PRINT '  - Keep logic minimal';
PRINT '  - Avoid cursors';
PRINT '  - Use EXISTS instead of COUNT';
PRINT '  - Consider alternative solutions (computed columns, constraints)';
PRINT '';
PRINT 'DEBUGGING:';
PRINT '  - Use TRY/CATCH';
PRINT '  - Log to error table';
PRINT '  - Test with single and multiple rows';
PRINT '  - Check INSERTED and DELETED tables';
PRINT '';

-- View all triggers
SELECT 
    OBJECT_NAME(parent_id) AS TableName,
    name AS TriggerName,
    type_desc AS TriggerType,
    is_disabled AS IsDisabled,
    is_instead_of_trigger AS IsInsteadOf
FROM sys.triggers
WHERE parent_id = OBJECT_ID('Books')
ORDER BY name;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create trigger to maintain ProductHistory table on price changes
 * 2. Create trigger to prevent deletion of orders with status 'Shipped'
 * 3. Create trigger to update modified_date automatically
 * 4. Create trigger to enforce business rule: max 5 orders per day per customer
 * 5. Create trigger for referential integrity enforcement
 * 
 * CHALLENGE:
 * Create comprehensive audit system:
 * - Single audit table for all tables
 * - Track INSERT/UPDATE/DELETE
 * - Store OLD and NEW values as JSON
 * - Include user, timestamp, application name
 * - Handle errors gracefully
 * - Support multi-row operations
 * - Add trigger to 5+ different tables
 */

PRINT '✓ Lab 43 Complete: AFTER triggers mastered';
GO
