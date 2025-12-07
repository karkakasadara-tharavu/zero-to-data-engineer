/*
 * Lab 52: T-SQL Programming Capstone Project
 * Module 05: T-SQL Programming
 * 
 * Project: Enterprise Order Processing System
 * Duration: 3-4 hours
 * Difficulty: ⭐⭐⭐⭐⭐
 * 
 * OBJECTIVE:
 * Build a complete order processing system integrating all T-SQL concepts:
 * - Stored procedures (basic, advanced, error handling)
 * - Functions (scalar, inline TVF, multi-statement TVF)
 * - Triggers (AFTER, INSTEAD OF, DDL)
 * - Transactions and isolation levels
 * - Dynamic SQL
 * - Error handling and logging
 * 
 * EVALUATION: 100 points total
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 52: T-SQL Capstone Project';
PRINT 'Enterprise Order Processing System';
PRINT '==============================================';
PRINT '';

/*
 * PHASE 1: DATABASE SCHEMA (10 points)
 * Create supporting tables for order processing
 */

PRINT 'PHASE 1: Database Schema Setup';
PRINT '================================';
PRINT '';

-- Order processing tables
IF OBJECT_ID('OrderStatuses', 'U') IS NOT NULL DROP TABLE OrderStatuses;
CREATE TABLE OrderStatuses (
    StatusID INT PRIMARY KEY,
    StatusName NVARCHAR(50) UNIQUE NOT NULL,
    Description NVARCHAR(200)
);

INSERT INTO OrderStatuses VALUES
(1, 'Pending', 'Order created, awaiting payment'),
(2, 'Payment Verified', 'Payment confirmed'),
(3, 'Processing', 'Order being prepared'),
(4, 'Shipped', 'Order dispatched'),
(5, 'Delivered', 'Order delivered to customer'),
(6, 'Cancelled', 'Order cancelled'),
(7, 'Refunded', 'Payment refunded');

PRINT '✓ OrderStatuses created';

-- Payment methods
IF OBJECT_ID('PaymentMethods', 'U') IS NOT NULL DROP TABLE PaymentMethods;
CREATE TABLE PaymentMethods (
    PaymentMethodID INT PRIMARY KEY,
    MethodName NVARCHAR(50) UNIQUE NOT NULL,
    IsActive BIT DEFAULT 1
);

INSERT INTO PaymentMethods VALUES
(1, 'Credit Card', 1),
(2, 'Debit Card', 1),
(3, 'PayPal', 1),
(4, 'Bank Transfer', 1),
(5, 'Cash on Delivery', 1);

PRINT '✓ PaymentMethods created';

-- Order payments
IF OBJECT_ID('OrderPayments', 'U') IS NOT NULL DROP TABLE OrderPayments;
CREATE TABLE OrderPayments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderID),
    PaymentMethodID INT NOT NULL FOREIGN KEY REFERENCES PaymentMethods(PaymentMethodID),
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    PaymentDate DATETIME2 DEFAULT SYSDATETIME(),
    TransactionID NVARCHAR(100),
    Status NVARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Approved', 'Declined', 'Refunded'))
);

PRINT '✓ OrderPayments created';

-- Order processing log
IF OBJECT_ID('OrderProcessingLog', 'U') IS NOT NULL DROP TABLE OrderProcessingLog;
CREATE TABLE OrderProcessingLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    StatusFrom NVARCHAR(50),
    StatusTo NVARCHAR(50),
    ChangedBy NVARCHAR(128) DEFAULT SUSER_SNAME(),
    ChangedDate DATETIME2 DEFAULT SYSDATETIME(),
    Notes NVARCHAR(500)
);

PRINT '✓ OrderProcessingLog created';

-- Inventory tracking
IF OBJECT_ID('InventoryTransactions', 'U') IS NOT NULL DROP TABLE InventoryTransactions;
CREATE TABLE InventoryTransactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    TransactionType NVARCHAR(20) CHECK (TransactionType IN ('Sale', 'Return', 'Adjustment', 'Restock')),
    Quantity INT NOT NULL,
    TransactionDate DATETIME2 DEFAULT SYSDATETIME(),
    OrderID INT NULL,
    Notes NVARCHAR(200)
);

PRINT '✓ InventoryTransactions created';
PRINT '';

/*
 * PHASE 2: VALIDATION FUNCTIONS (15 points)
 * Create reusable validation functions
 */

PRINT 'PHASE 2: Validation Functions';
PRINT '===============================';
PRINT '';

-- Validate customer eligibility
IF OBJECT_ID('fn_ValidateCustomer', 'FN') IS NOT NULL DROP FUNCTION fn_ValidateCustomer;
GO

CREATE FUNCTION fn_ValidateCustomer(@CustomerID INT)
RETURNS TABLE
AS
RETURN (
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        c.Email,
        CASE 
            WHEN c.IsActive = 0 THEN 'Inactive'
            WHEN ISNULL(c.TotalOrderValue, 0) > 10000 THEN 'Premium'
            WHEN ISNULL(c.TotalOrderValue, 0) > 5000 THEN 'Gold'
            WHEN ISNULL(c.TotalOrderValue, 0) > 1000 THEN 'Silver'
            ELSE 'Standard'
        END AS CustomerTier,
        CASE 
            WHEN c.IsActive = 0 THEN 0
            ELSE 1
        END AS CanPlaceOrder,
        CASE 
            WHEN c.IsActive = 0 THEN 'Customer account is inactive'
            ELSE 'Eligible'
        END AS ValidationMessage
    FROM Customers c
    WHERE c.CustomerID = @CustomerID
);
GO

PRINT '✓ fn_ValidateCustomer created';

-- Check product availability
IF OBJECT_ID('fn_CheckProductAvailability', 'IF') IS NOT NULL DROP FUNCTION fn_CheckProductAvailability;
GO

CREATE FUNCTION fn_CheckProductAvailability(@ProductID INT, @Quantity INT)
RETURNS @Result TABLE (
    ProductID INT,
    ProductName NVARCHAR(200),
    StockQuantity INT,
    RequestedQuantity INT,
    IsAvailable BIT,
    Message NVARCHAR(200)
)
AS
BEGIN
    INSERT INTO @Result
    SELECT 
        p.ProductID,
        p.ProductName,
        p.StockQuantity,
        @Quantity,
        CASE WHEN p.StockQuantity >= @Quantity THEN 1 ELSE 0 END,
        CASE 
            WHEN p.StockQuantity >= @Quantity THEN 'Available'
            WHEN p.StockQuantity > 0 THEN 'Insufficient stock. Available: ' + CAST(p.StockQuantity AS NVARCHAR(10))
            ELSE 'Out of stock'
        END
    FROM Inventory.Products p
    WHERE p.ProductID = @ProductID;
    
    -- Handle non-existent product
    IF NOT EXISTS (SELECT 1 FROM @Result)
    BEGIN
        INSERT INTO @Result
        VALUES (@ProductID, 'UNKNOWN', 0, @Quantity, 0, 'Product not found');
    END;
    
    RETURN;
END;
GO

PRINT '✓ fn_CheckProductAvailability created';

-- Calculate order discount
IF OBJECT_ID('fn_CalculateOrderDiscount', 'FN') IS NOT NULL DROP FUNCTION fn_CalculateOrderDiscount;
GO

CREATE FUNCTION fn_CalculateOrderDiscount(
    @CustomerID INT,
    @OrderTotal DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Discount DECIMAL(10,2) = 0;
    DECLARE @CustomerTier NVARCHAR(20);
    DECLARE @TotalSpent DECIMAL(10,2);
    
    SELECT @TotalSpent = ISNULL(TotalOrderValue, 0)
    FROM Customers
    WHERE CustomerID = @CustomerID;
    
    -- Tier-based discounts
    IF @TotalSpent > 10000
        SET @Discount = @OrderTotal * 0.15;  -- 15% for Premium
    ELSE IF @TotalSpent > 5000
        SET @Discount = @OrderTotal * 0.10;  -- 10% for Gold
    ELSE IF @TotalSpent > 1000
        SET @Discount = @OrderTotal * 0.05;  -- 5% for Silver
    
    -- Additional discount for large orders
    IF @OrderTotal > 500
        SET @Discount = @Discount + (@OrderTotal * 0.02);
    
    -- Cap discount at 20%
    IF @Discount > @OrderTotal * 0.20
        SET @Discount = @OrderTotal * 0.20;
    
    RETURN @Discount;
END;
GO

PRINT '✓ fn_CalculateOrderDiscount created';
PRINT '';

/*
 * PHASE 3: ORDER CREATION PROCEDURES (20 points)
 * Build comprehensive order creation workflow
 */

PRINT 'PHASE 3: Order Creation Procedures';
PRINT '====================================';
PRINT '';

-- Main order creation procedure
IF OBJECT_ID('usp_CreateOrder', 'P') IS NOT NULL DROP PROCEDURE usp_CreateOrder;
GO

CREATE PROCEDURE usp_CreateOrder
    @CustomerID INT,
    @OrderItems NVARCHAR(MAX),  -- JSON: [{"ProductID":1,"Quantity":2,"Price":29.99}]
    @PaymentMethodID INT,
    @NewOrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Step 1: Validate customer
        DECLARE @CanOrder BIT;
        DECLARE @ValidationMsg NVARCHAR(200);
        
        SELECT 
            @CanOrder = CanPlaceOrder,
            @ValidationMsg = ValidationMessage
        FROM fn_ValidateCustomer(@CustomerID);
        
        IF @CanOrder = 0
        BEGIN
            THROW 50001, @ValidationMsg, 1;
        END;
        
        -- Step 2: Parse order items
        DECLARE @Items TABLE (
            ProductID INT,
            Quantity INT,
            Price DECIMAL(10,2)
        );
        
        INSERT INTO @Items (ProductID, Quantity, Price)
        SELECT 
            JSON_VALUE(value, '$.ProductID'),
            JSON_VALUE(value, '$.Quantity'),
            JSON_VALUE(value, '$.Price')
        FROM OPENJSON(@OrderItems);
        
        -- Step 3: Check inventory
        DECLARE @ProductID INT, @Quantity INT;
        DECLARE item_cursor CURSOR FOR
        SELECT ProductID, Quantity FROM @Items;
        
        OPEN item_cursor;
        FETCH NEXT FROM item_cursor INTO @ProductID, @Quantity;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @IsAvailable BIT;
            SELECT @IsAvailable = IsAvailable 
            FROM fn_CheckProductAvailability(@ProductID, @Quantity);
            
            IF @IsAvailable = 0
            BEGIN
                DECLARE @ErrorMsg NVARCHAR(200);
                SELECT @ErrorMsg = Message 
                FROM fn_CheckProductAvailability(@ProductID, @Quantity);
                
                CLOSE item_cursor;
                DEALLOCATE item_cursor;
                
                THROW 50002, @ErrorMsg, 1;
            END;
            
            FETCH NEXT FROM item_cursor INTO @ProductID, @Quantity;
        END;
        
        CLOSE item_cursor;
        DEALLOCATE item_cursor;
        
        -- Step 4: Calculate totals
        DECLARE @Subtotal DECIMAL(10,2);
        DECLARE @Discount DECIMAL(10,2);
        DECLARE @Tax DECIMAL(10,2);
        DECLARE @Total DECIMAL(10,2);
        
        SELECT @Subtotal = SUM(Price * Quantity) FROM @Items;
        SET @Discount = dbo.fn_CalculateOrderDiscount(@CustomerID, @Subtotal);
        SET @Tax = (@Subtotal - @Discount) * 0.08;  -- 8% tax
        SET @Total = @Subtotal - @Discount + @Tax;
        
        -- Step 5: Create order
        INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
        VALUES (@CustomerID, SYSDATETIME(), @Total, 'Pending');
        
        SET @NewOrderID = SCOPE_IDENTITY();
        
        -- Step 6: Create order items (would need OrderItems table)
        -- INSERT INTO OrderItems (OrderID, ProductID, Quantity, Price)
        -- SELECT @NewOrderID, ProductID, Quantity, Price FROM @Items;
        
        -- Step 7: Reserve inventory
        INSERT INTO InventoryTransactions (ProductID, TransactionType, Quantity, OrderID, Notes)
        SELECT 
            ProductID, 
            'Sale', 
            -Quantity,  -- Negative for reduction
            @NewOrderID,
            'Reserved for order'
        FROM @Items;
        
        -- Step 8: Log order creation
        INSERT INTO OrderProcessingLog (OrderID, StatusFrom, StatusTo, Notes)
        VALUES (@NewOrderID, NULL, 'Pending', 'Order created');
        
        COMMIT TRANSACTION;
        
        PRINT '✓ Order ' + CAST(@NewOrderID AS NVARCHAR(10)) + ' created successfully';
        PRINT '  Subtotal: $' + CAST(@Subtotal AS NVARCHAR(20));
        PRINT '  Discount: $' + CAST(@Discount AS NVARCHAR(20));
        PRINT '  Tax: $' + CAST(@Tax AS NVARCHAR(20));
        PRINT '  Total: $' + CAST(@Total AS NVARCHAR(20));
        
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO EnterpriseErrorLog (
            ErrorNumber, ErrorSeverity, ErrorState,
            ErrorProcedure, ErrorLine, ErrorMessage
        )
        VALUES (
            ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
            ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE()
        );
        
        THROW;
    END CATCH;
END;
GO

PRINT '✓ usp_CreateOrder created';

-- Payment processing procedure
IF OBJECT_ID('usp_ProcessPayment', 'P') IS NOT NULL DROP PROCEDURE usp_ProcessPayment;
GO

CREATE PROCEDURE usp_ProcessPayment
    @OrderID INT,
    @PaymentMethodID INT,
    @TransactionID NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Get order amount
        DECLARE @Amount DECIMAL(10,2);
        DECLARE @CurrentStatus NVARCHAR(50);
        
        SELECT 
            @Amount = TotalAmount,
            @CurrentStatus = Status
        FROM Orders
        WHERE OrderID = @OrderID;
        
        IF @OrderID IS NULL
        BEGIN
            THROW 50003, 'Order not found', 1;
        END;
        
        IF @CurrentStatus <> 'Pending'
        BEGIN
            THROW 50004, 'Order is not in pending status', 1;
        END;
        
        -- Record payment
        INSERT INTO OrderPayments (OrderID, PaymentMethodID, Amount, TransactionID, Status)
        VALUES (@OrderID, @PaymentMethodID, @Amount, @TransactionID, 'Approved');
        
        -- Update order status
        UPDATE Orders
        SET Status = 'Payment Verified'
        WHERE OrderID = @OrderID;
        
        -- Log status change
        INSERT INTO OrderProcessingLog (OrderID, StatusFrom, StatusTo, Notes)
        VALUES (@OrderID, 'Pending', 'Payment Verified', 'Payment processed: ' + @TransactionID);
        
        COMMIT TRANSACTION;
        
        PRINT '✓ Payment processed for Order ' + CAST(@OrderID AS NVARCHAR(10));
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        EXEC usp_LogError;
        THROW;
    END CATCH;
END;
GO

PRINT '✓ usp_ProcessPayment created';
PRINT '';

/*
 * PHASE 4: ORDER STATUS MANAGEMENT (15 points)
 * Status transitions with validation
 */

PRINT 'PHASE 4: Order Status Management';
PRINT '==================================';
PRINT '';

IF OBJECT_ID('usp_UpdateOrderStatus', 'P') IS NOT NULL DROP PROCEDURE usp_UpdateOrderStatus;
GO

CREATE PROCEDURE usp_UpdateOrderStatus
    @OrderID INT,
    @NewStatus NVARCHAR(50),
    @Notes NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentStatus NVARCHAR(50);
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        SELECT @CurrentStatus = Status
        FROM Orders WITH (UPDLOCK)
        WHERE OrderID = @OrderID;
        
        IF @OrderID IS NULL
        BEGIN
            THROW 50005, 'Order not found', 1;
        END;
        
        -- Validate status transition
        DECLARE @ValidTransition BIT = 0;
        
        IF (@CurrentStatus = 'Pending' AND @NewStatus = 'Payment Verified')
            OR (@CurrentStatus = 'Payment Verified' AND @NewStatus = 'Processing')
            OR (@CurrentStatus = 'Processing' AND @NewStatus = 'Shipped')
            OR (@CurrentStatus = 'Shipped' AND @NewStatus = 'Delivered')
            OR (@CurrentStatus IN ('Pending', 'Payment Verified', 'Processing') AND @NewStatus = 'Cancelled')
            SET @ValidTransition = 1;
        
        IF @ValidTransition = 0
        BEGIN
            DECLARE @TransitionError NVARCHAR(200) = 
                'Invalid status transition: ' + @CurrentStatus + ' → ' + @NewStatus;
            THROW 50006, @TransitionError, 1;
        END;
        
        -- Update status
        UPDATE Orders
        SET Status = @NewStatus
        WHERE OrderID = @OrderID;
        
        -- Log change
        INSERT INTO OrderProcessingLog (OrderID, StatusFrom, StatusTo, Notes)
        VALUES (@OrderID, @CurrentStatus, @NewStatus, @Notes);
        
        COMMIT TRANSACTION;
        
        PRINT '✓ Order ' + CAST(@OrderID AS NVARCHAR(10)) + ' status: ' + 
              @CurrentStatus + ' → ' + @NewStatus;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        EXEC usp_LogError;
        THROW;
    END CATCH;
END;
GO

PRINT '✓ usp_UpdateOrderStatus created';
PRINT '';

/*
 * PHASE 5: AUDIT TRIGGERS (15 points)
 */

PRINT 'PHASE 5: Audit Triggers';
PRINT '=========================';
PRINT '';

-- Order audit trigger
IF OBJECT_ID('trg_Orders_AuditChanges', 'TR') IS NOT NULL DROP TRIGGER trg_Orders_AuditChanges;
GO

CREATE TRIGGER trg_Orders_AuditChanges
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only audit status changes
    IF UPDATE(Status)
    BEGIN
        INSERT INTO OrderProcessingLog (OrderID, StatusFrom, StatusTo, Notes)
        SELECT 
            i.OrderID,
            d.Status,
            i.Status,
            'Automatic audit trail'
        FROM INSERTED i
        INNER JOIN DELETED d ON i.OrderID = d.OrderID
        WHERE i.Status <> d.Status;
    END;
END;
GO

PRINT '✓ trg_Orders_AuditChanges created';

-- Payment audit trigger
IF OBJECT_ID('trg_OrderPayments_Audit', 'TR') IS NOT NULL DROP TRIGGER trg_OrderPayments_Audit;
GO

CREATE TRIGGER trg_OrderPayments_Audit
ON OrderPayments
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO DetailedAudit (TableName, Operation, RecordID, NewValues)
    SELECT 
        'OrderPayments',
        CASE WHEN EXISTS (SELECT 1 FROM DELETED) THEN 'UPDATE' ELSE 'INSERT' END,
        PaymentID,
        (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM INSERTED i;
END;
GO

PRINT '✓ trg_OrderPayments_Audit created';
PRINT '';

/*
 * PHASE 6: REPORTING FUNCTIONS (10 points)
 */

PRINT 'PHASE 6: Reporting Functions';
PRINT '==============================';
PRINT '';

-- Order summary report
IF OBJECT_ID('fn_GetOrderSummary', 'IF') IS NOT NULL DROP FUNCTION fn_GetOrderSummary;
GO

CREATE FUNCTION fn_GetOrderSummary(@StartDate DATE, @EndDate DATE)
RETURNS TABLE
AS
RETURN (
    SELECT 
        Status,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalRevenue,
        AVG(TotalAmount) AS AvgOrderValue,
        MIN(TotalAmount) AS MinOrderValue,
        MAX(TotalAmount) AS MaxOrderValue
    FROM Orders
    WHERE OrderDate >= @StartDate 
    AND OrderDate < DATEADD(DAY, 1, @EndDate)
    GROUP BY Status
);
GO

PRINT '✓ fn_GetOrderSummary created';

-- Customer order history
IF OBJECT_ID('fn_GetCustomerOrderHistory', 'IF') IS NOT NULL DROP FUNCTION fn_GetCustomerOrderHistory;
GO

CREATE FUNCTION fn_GetCustomerOrderHistory(@CustomerID INT)
RETURNS TABLE
AS
RETURN (
    SELECT 
        o.OrderID,
        o.OrderDate,
        o.Status,
        o.TotalAmount,
        p.MethodName AS PaymentMethod,
        DATEDIFF(DAY, o.OrderDate, GETDATE()) AS DaysSinceOrder
    FROM Orders o
    LEFT JOIN OrderPayments op ON o.OrderID = op.OrderID
    LEFT JOIN PaymentMethods p ON op.PaymentMethodID = p.PaymentMethodID
    WHERE o.CustomerID = @CustomerID
);
GO

PRINT '✓ fn_GetCustomerOrderHistory created';
PRINT '';

/*
 * PHASE 7: DYNAMIC REPORTING (10 points)
 */

PRINT 'PHASE 7: Dynamic Reporting';
PRINT '============================';
PRINT '';

IF OBJECT_ID('usp_GenerateOrderReport', 'P') IS NOT NULL DROP PROCEDURE usp_GenerateOrderReport;
GO

CREATE PROCEDURE usp_GenerateOrderReport
    @GroupBy NVARCHAR(50) = 'Status',  -- Status, Date, Customer
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default date range
    IF @StartDate IS NULL SET @StartDate = DATEADD(DAY, -30, GETDATE());
    IF @EndDate IS NULL SET @EndDate = GETDATE();
    
    -- Validate group by
    IF @GroupBy NOT IN ('Status', 'Date', 'Customer')
    BEGIN
        RAISERROR('Invalid GroupBy. Use: Status, Date, or Customer', 16, 1);
        RETURN;
    END;
    
    -- Build dynamic query
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT ' +
            CASE @GroupBy
                WHEN 'Status' THEN N'Status'
                WHEN 'Date' THEN N'CAST(OrderDate AS DATE) AS OrderDate'
                WHEN 'Customer' THEN N'CustomerID'
            END + N' AS GroupKey,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalRevenue,
        AVG(TotalAmount) AS AvgOrderValue
        FROM Orders
        WHERE OrderDate >= @StartDateParam
        AND OrderDate < DATEADD(DAY, 1, @EndDateParam)
        GROUP BY ' +
            CASE @GroupBy
                WHEN 'Status' THEN N'Status'
                WHEN 'Date' THEN N'CAST(OrderDate AS DATE)'
                WHEN 'Customer' THEN N'CustomerID'
            END + N'
        ORDER BY TotalRevenue DESC';
    
    DECLARE @Params NVARCHAR(MAX) = N'@StartDateParam DATE, @EndDateParam DATE';
    
    PRINT 'Order Report - Grouped by: ' + @GroupBy;
    PRINT '';
    
    EXEC sp_executesql @SQL, @Params, @StartDateParam = @StartDate, @EndDateParam = @EndDate;
END;
GO

PRINT '✓ usp_GenerateOrderReport created';
PRINT '';

/*
 * PHASE 8: ERROR RECOVERY (5 points)
 */

PRINT 'PHASE 8: Error Recovery Procedures';
PRINT '====================================';
PRINT '';

IF OBJECT_ID('usp_RecoverFailedOrder', 'P') IS NOT NULL DROP PROCEDURE usp_RecoverFailedOrder;
GO

CREATE PROCEDURE usp_RecoverFailedOrder
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Analyzing order ' + CAST(@OrderID AS NVARCHAR(10)) + '...';
        
        -- Check order exists
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @OrderID)
        BEGIN
            PRINT '✗ Order not found';
            RETURN;
        END;
        
        -- Check payment status
        DECLARE @PaymentStatus NVARCHAR(20);
        SELECT @PaymentStatus = Status
        FROM OrderPayments
        WHERE OrderID = @OrderID;
        
        IF @PaymentStatus IS NULL
        BEGIN
            PRINT '✗ No payment record found';
            PRINT '  Recommendation: Process payment or cancel order';
        END
        ELSE IF @PaymentStatus = 'Declined'
        BEGIN
            PRINT '✗ Payment was declined';
            PRINT '  Recommendation: Request alternative payment';
        END
        ELSE
        BEGIN
            PRINT '✓ Payment status OK: ' + @PaymentStatus;
        END;
        
        -- Check inventory reservations
        IF NOT EXISTS (
            SELECT 1 FROM InventoryTransactions 
            WHERE OrderID = @OrderID
        )
        BEGIN
            PRINT '⚠️  No inventory transactions found';
            PRINT '  Recommendation: Re-reserve inventory';
        END
        ELSE
        BEGIN
            PRINT '✓ Inventory transactions recorded';
        END;
        
        -- View status history
        PRINT '';
        PRINT 'Status History:';
        SELECT 
            StatusFrom,
            StatusTo,
            ChangedDate,
            Notes
        FROM OrderProcessingLog
        WHERE OrderID = @OrderID
        ORDER BY ChangedDate;
        
    END TRY
    BEGIN CATCH
        PRINT 'Error analyzing order: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

PRINT '✓ usp_RecoverFailedOrder created';
PRINT '';

/*
 * EVALUATION & TESTING
 */

PRINT '==============================================';
PRINT 'CAPSTONE PROJECT COMPLETE';
PRINT '==============================================';
PRINT '';
PRINT 'EVALUATION RUBRIC (100 points):';
PRINT '';
PRINT 'Phase 1: Database Schema (10 points)';
PRINT '  - All tables created correctly: 5 pts';
PRINT '  - Proper constraints and relationships: 5 pts';
PRINT '';
PRINT 'Phase 2: Validation Functions (15 points)';
PRINT '  - fn_ValidateCustomer: 5 pts';
PRINT '  - fn_CheckProductAvailability: 5 pts';
PRINT '  - fn_CalculateOrderDiscount: 5 pts';
PRINT '';
PRINT 'Phase 3: Order Creation (20 points)';
PRINT '  - usp_CreateOrder implementation: 10 pts';
PRINT '  - usp_ProcessPayment implementation: 5 pts';
PRINT '  - Transaction handling: 5 pts';
PRINT '';
PRINT 'Phase 4: Status Management (15 points)';
PRINT '  - usp_UpdateOrderStatus: 10 pts';
PRINT '  - Status validation logic: 5 pts';
PRINT '';
PRINT 'Phase 5: Audit Triggers (15 points)';
PRINT '  - Order audit trigger: 8 pts';
PRINT '  - Payment audit trigger: 7 pts';
PRINT '';
PRINT 'Phase 6: Reporting Functions (10 points)';
PRINT '  - Order summary function: 5 pts';
PRINT '  - Customer history function: 5 pts';
PRINT '';
PRINT 'Phase 7: Dynamic Reporting (10 points)';
PRINT '  - Dynamic report generation: 10 pts';
PRINT '';
PRINT 'Phase 8: Error Recovery (5 points)';
PRINT '  - Recovery procedure: 5 pts';
PRINT '';
PRINT 'TOTAL: 100 points';
PRINT '';
PRINT 'TESTING CHECKLIST:';
PRINT '  ☐ Create order with valid customer';
PRINT '  ☐ Create order with inactive customer (should fail)';
PRINT '  ☐ Create order with insufficient inventory (should fail)';
PRINT '  ☐ Process payment successfully';
PRINT '  ☐ Update order status through lifecycle';
PRINT '  ☐ Attempt invalid status transition (should fail)';
PRINT '  ☐ Verify audit logs created';
PRINT '  ☐ Generate reports with different groupings';
PRINT '  ☐ Test error recovery procedure';
PRINT '  ☐ Verify all transactions rollback on error';
PRINT '';
PRINT 'EXTENSION IDEAS:';
PRINT '  + Add order cancellation with refund processing';
PRINT '  + Implement partial shipments';
PRINT '  + Add order modification capabilities';
PRINT '  + Create notification system';
PRINT '  + Build order tracking API';
PRINT '  + Add performance monitoring';
PRINT '  + Implement fraud detection';
PRINT '  + Create customer loyalty program integration';
PRINT '';
PRINT '✓ Lab 52 Complete: T-SQL Capstone Project finished!';
PRINT '';
PRINT '★★★ MODULE 05 COMPLETE ★★★';
PRINT 'All 15 T-SQL Programming labs completed successfully!';
PRINT '';
PRINT 'Skills Mastered:';
PRINT '  ✓ Stored Procedures (basic, advanced, error handling)';
PRINT '  ✓ Functions (scalar, inline TVF, multi-statement TVF)';
PRINT '  ✓ Triggers (AFTER, INSTEAD OF, DDL)';
PRINT '  ✓ Error Handling (TRY/CATCH, custom errors)';
PRINT '  ✓ Transactions (isolation levels, concurrency)';
PRINT '  ✓ Dynamic SQL (sp_executesql, security)';
PRINT '';
PRINT 'Next Steps:';
PRINT '  → Module 06: ETL SSIS Fundamentals';
PRINT '  → Module 07: Advanced ETL Patterns';
PRINT '  → Module 08: PowerBI Reporting';
PRINT '  → Module 09: SQL Capstone Project';
GO
