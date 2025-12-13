# SQL Capstone Project Guide

## 🎯 Learning Objectives
- Apply all SQL concepts learned throughout the course in a real-world scenario
- Design and implement a complete database solution from scratch
- Demonstrate proficiency in DDL, DML, advanced queries, and optimization
- Build production-ready stored procedures and views
- Create comprehensive documentation for your database design

---

## Project Overview: E-Commerce Data Warehouse

### Scenario
You are hired as a Data Engineer at **ShopSmart Inc.**, a growing e-commerce company. Your task is to design and implement a complete SQL Server database that will serve as the foundation for their analytics platform.

### Business Requirements
1. Track customer orders, products, and inventory
2. Monitor sales performance across regions and time periods
3. Analyze customer behavior and purchase patterns
4. Generate reports for management decision-making
5. Ensure data quality and referential integrity

---

## Phase 1: Database Design (25 Points)

### 1.1 Entity Relationship Diagram
Design an ERD with the following entities:

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   Customers     │       │     Orders      │       │   OrderItems    │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ CustomerID (PK) │───┐   │ OrderID (PK)    │───┐   │ OrderItemID(PK) │
│ FirstName       │   └──>│ CustomerID (FK) │   └──>│ OrderID (FK)    │
│ LastName        │       │ OrderDate       │       │ ProductID (FK)  │
│ Email           │       │ ShippingAddress │       │ Quantity        │
│ Phone           │       │ TotalAmount     │       │ UnitPrice       │
│ RegistrationDate│       │ Status          │       │ Discount        │
│ CustomerTier    │       │ PaymentMethod   │       └─────────────────┘
└─────────────────┘       └─────────────────┘               │
                                                            │
┌─────────────────┐       ┌─────────────────┐               │
│   Categories    │       │    Products     │<──────────────┘
├─────────────────┤       ├─────────────────┤
│ CategoryID (PK) │───┐   │ ProductID (PK)  │
│ CategoryName    │   └──>│ CategoryID (FK) │
│ Description     │       │ ProductName     │
│ ParentCategoryID│       │ Description     │
└─────────────────┘       │ UnitPrice       │
                          │ StockQuantity   │
┌─────────────────┐       │ ReorderLevel    │
│   Suppliers     │       │ SupplierID (FK) │
├─────────────────┤       │ IsActive        │
│ SupplierID (PK) │──────>└─────────────────┘
│ CompanyName     │
│ ContactName     │       ┌─────────────────┐
│ Email           │       │   Inventory     │
│ Phone           │       ├─────────────────┤
│ Country         │       │ InventoryID(PK) │
└─────────────────┘       │ ProductID (FK)  │
                          │ WarehouseID(FK) │
┌─────────────────┐       │ Quantity        │
│   Warehouses    │──────>│ LastUpdated     │
├─────────────────┤       └─────────────────┘
│ WarehouseID(PK) │
│ WarehouseName   │
│ Location        │
│ Capacity        │
└─────────────────┘
```

### 1.2 Normalization Requirements
- Ensure all tables are in **3rd Normal Form (3NF)**
- Document any intentional denormalization with justification
- Identify functional dependencies

### 1.3 Deliverables
- [ ] Complete ERD diagram
- [ ] Data dictionary for all tables
- [ ] Normalization documentation

---

## Phase 2: Database Implementation (25 Points)

### 2.1 Create Database and Schema

```sql
-- Create the database
CREATE DATABASE ShopSmartDW;
GO

USE ShopSmartDW;
GO

-- Create schemas for organization
CREATE SCHEMA Sales;
GO

CREATE SCHEMA Inventory;
GO

CREATE SCHEMA Dimension;
GO
```

### 2.2 Create Tables with Constraints

```sql
-- Dimension Tables
CREATE TABLE Dimension.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(20),
    RegistrationDate DATE NOT NULL DEFAULT GETDATE(),
    CustomerTier NVARCHAR(20) DEFAULT 'Bronze' 
        CHECK (CustomerTier IN ('Bronze', 'Silver', 'Gold', 'Platinum')),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    ModifiedAt DATETIME2
);

CREATE TABLE Dimension.Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    ParentCategoryID INT NULL,
    CONSTRAINT FK_Categories_Parent 
        FOREIGN KEY (ParentCategoryID) REFERENCES Dimension.Categories(CategoryID)
);

CREATE TABLE Dimension.Suppliers (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName NVARCHAR(100) NOT NULL,
    ContactName NVARCHAR(100),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    Country NVARCHAR(50),
    IsActive BIT DEFAULT 1
);

CREATE TABLE Dimension.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    StockQuantity INT NOT NULL DEFAULT 0 CHECK (StockQuantity >= 0),
    ReorderLevel INT DEFAULT 10,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryID) 
        REFERENCES Dimension.Categories(CategoryID),
    CONSTRAINT FK_Products_Supplier FOREIGN KEY (SupplierID) 
        REFERENCES Dimension.Suppliers(SupplierID)
);

-- Fact Tables
CREATE TABLE Sales.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ShippingAddress NVARCHAR(500),
    TotalAmount DECIMAL(12,2),
    Status NVARCHAR(20) DEFAULT 'Pending'
        CHECK (Status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')),
    PaymentMethod NVARCHAR(20)
        CHECK (PaymentMethod IN ('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer')),
    CONSTRAINT FK_Orders_Customer FOREIGN KEY (CustomerID) 
        REFERENCES Dimension.Customers(CustomerID)
);

CREATE TABLE Sales.OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0 CHECK (Discount >= 0 AND Discount <= 100),
    LineTotal AS (Quantity * UnitPrice * (1 - Discount/100)) PERSISTED,
    CONSTRAINT FK_OrderItems_Order FOREIGN KEY (OrderID) 
        REFERENCES Sales.Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Product FOREIGN KEY (ProductID) 
        REFERENCES Dimension.Products(ProductID)
);

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID ON Sales.Orders(CustomerID);
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON Sales.Orders(OrderDate);
CREATE NONCLUSTERED INDEX IX_OrderItems_ProductID ON Sales.OrderItems(ProductID);
CREATE NONCLUSTERED INDEX IX_Products_CategoryID ON Dimension.Products(CategoryID);
```

### 2.3 Deliverables
- [ ] All CREATE TABLE statements
- [ ] All constraint definitions
- [ ] Index creation scripts

---

## Phase 3: Data Population & DML (15 Points)

### 3.1 Sample Data Insertion

```sql
-- Insert sample categories
INSERT INTO Dimension.Categories (CategoryName, Description, ParentCategoryID)
VALUES 
    ('Electronics', 'Electronic devices and accessories', NULL),
    ('Clothing', 'Apparel and fashion items', NULL),
    ('Books', 'Physical and digital books', NULL),
    ('Smartphones', 'Mobile phones and accessories', 1),
    ('Laptops', 'Portable computers', 1),
    ('Men''s Wear', 'Clothing for men', 2),
    ('Women''s Wear', 'Clothing for women', 2);

-- Insert sample suppliers
INSERT INTO Dimension.Suppliers (CompanyName, ContactName, Email, Phone, Country)
VALUES 
    ('TechWorld Inc', 'John Smith', 'john@techworld.com', '555-0101', 'USA'),
    ('Fashion Hub', 'Emily Brown', 'emily@fashionhub.com', '555-0102', 'UK'),
    ('Global Books', 'Michael Lee', 'michael@globalbooks.com', '555-0103', 'Canada');

-- Insert sample customers
INSERT INTO Dimension.Customers (FirstName, LastName, Email, Phone, CustomerTier)
VALUES 
    ('Alice', 'Johnson', 'alice@email.com', '555-1001', 'Gold'),
    ('Bob', 'Williams', 'bob@email.com', '555-1002', 'Silver'),
    ('Carol', 'Davis', 'carol@email.com', '555-1003', 'Bronze'),
    ('David', 'Miller', 'david@email.com', '555-1004', 'Platinum');

-- Insert sample products
INSERT INTO Dimension.Products 
    (CategoryID, SupplierID, ProductName, Description, UnitPrice, StockQuantity)
VALUES 
    (4, 1, 'iPhone 15 Pro', 'Latest Apple smartphone', 1199.99, 50),
    (4, 1, 'Samsung Galaxy S24', 'Samsung flagship phone', 999.99, 75),
    (5, 1, 'MacBook Pro 16"', 'Apple laptop for professionals', 2499.99, 30),
    (6, 2, 'Cotton T-Shirt', 'Premium cotton t-shirt', 29.99, 200),
    (3, 3, 'SQL Mastery Guide', 'Complete SQL reference book', 49.99, 100);

-- Insert sample orders with items
DECLARE @OrderID INT;

INSERT INTO Sales.Orders (CustomerID, ShippingAddress, PaymentMethod, Status)
VALUES (1, '123 Main St, New York, NY 10001', 'Credit Card', 'Delivered');
SET @OrderID = SCOPE_IDENTITY();

INSERT INTO Sales.OrderItems (OrderID, ProductID, Quantity, UnitPrice, Discount)
VALUES 
    (@OrderID, 1, 1, 1199.99, 5),
    (@OrderID, 5, 2, 49.99, 0);

-- Update order total
UPDATE Sales.Orders
SET TotalAmount = (SELECT SUM(LineTotal) FROM Sales.OrderItems WHERE OrderID = @OrderID)
WHERE OrderID = @OrderID;
```

### 3.2 Data Generation Script
Create a script to generate 1000+ orders for realistic testing:

```sql
-- Generate random orders for testing
DECLARE @i INT = 1;
DECLARE @CustomerID INT, @ProductID INT, @Qty INT;

WHILE @i <= 1000
BEGIN
    SET @CustomerID = (SELECT TOP 1 CustomerID FROM Dimension.Customers ORDER BY NEWID());
    
    INSERT INTO Sales.Orders (CustomerID, OrderDate, PaymentMethod, Status)
    VALUES (
        @CustomerID,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Credit Card'
            WHEN 1 THEN 'Debit Card'
            WHEN 2 THEN 'PayPal'
            ELSE 'Bank Transfer'
        END,
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'Pending'
            WHEN 1 THEN 'Processing'
            WHEN 2 THEN 'Shipped'
            WHEN 3 THEN 'Delivered'
            ELSE 'Cancelled'
        END
    );
    
    SET @i = @i + 1;
END;
```

---

## Phase 4: Advanced Queries (20 Points)

### 4.1 Required Queries

**Query 1: Monthly Sales Analysis**
```sql
-- Monthly sales with YoY comparison
WITH MonthlySales AS (
    SELECT 
        YEAR(o.OrderDate) AS Year,
        MONTH(o.OrderDate) AS Month,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        SUM(o.TotalAmount) AS Revenue,
        COUNT(DISTINCT o.CustomerID) AS UniqueCustomers
    FROM Sales.Orders o
    WHERE o.Status != 'Cancelled'
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT 
    curr.Year,
    curr.Month,
    curr.TotalOrders,
    curr.Revenue,
    curr.UniqueCustomers,
    prev.Revenue AS PrevYearRevenue,
    CASE 
        WHEN prev.Revenue > 0 
        THEN ROUND((curr.Revenue - prev.Revenue) / prev.Revenue * 100, 2)
        ELSE NULL 
    END AS YoYGrowthPercent
FROM MonthlySales curr
LEFT JOIN MonthlySales prev 
    ON curr.Year = prev.Year + 1 AND curr.Month = prev.Month
ORDER BY curr.Year DESC, curr.Month DESC;
```

**Query 2: Customer Segmentation (RFM Analysis)**
```sql
-- RFM (Recency, Frequency, Monetary) Analysis
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceLastOrder,
        COUNT(o.OrderID) AS TotalOrders,
        SUM(o.TotalAmount) AS TotalSpent
    FROM Dimension.Customers c
    LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
        AND o.Status != 'Cancelled'
    GROUP BY c.CustomerID, c.FirstName, c.LastName
),
RFMScores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY DaysSinceLastOrder DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY TotalOrders) AS F_Score,
        NTILE(5) OVER (ORDER BY TotalSpent) AS M_Score
    FROM CustomerMetrics
    WHERE TotalOrders > 0
)
SELECT 
    CustomerID,
    CustomerName,
    DaysSinceLastOrder,
    TotalOrders,
    TotalSpent,
    R_Score, F_Score, M_Score,
    R_Score + F_Score + M_Score AS RFM_Total,
    CASE 
        WHEN R_Score + F_Score + M_Score >= 12 THEN 'Champions'
        WHEN R_Score + F_Score + M_Score >= 9 THEN 'Loyal Customers'
        WHEN R_Score + F_Score + M_Score >= 6 THEN 'Potential Loyalists'
        WHEN R_Score >= 4 AND F_Score <= 2 THEN 'New Customers'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk'
        ELSE 'Need Attention'
    END AS CustomerSegment
FROM RFMScores
ORDER BY RFM_Total DESC;
```

**Query 3: Product Performance Dashboard**
```sql
-- Product performance with ranking
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    COUNT(DISTINCT oi.OrderID) AS TimesOrdered,
    SUM(oi.Quantity) AS TotalQuantitySold,
    SUM(oi.LineTotal) AS TotalRevenue,
    AVG(oi.LineTotal) AS AvgOrderValue,
    p.StockQuantity AS CurrentStock,
    CASE 
        WHEN p.StockQuantity <= p.ReorderLevel THEN 'Reorder Needed'
        ELSE 'In Stock'
    END AS StockStatus,
    RANK() OVER (ORDER BY SUM(oi.LineTotal) DESC) AS RevenueRank,
    RANK() OVER (PARTITION BY c.CategoryID ORDER BY SUM(oi.LineTotal) DESC) AS CategoryRank
FROM Dimension.Products p
JOIN Dimension.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Sales.OrderItems oi ON p.ProductID = oi.ProductID
LEFT JOIN Sales.Orders o ON oi.OrderID = o.OrderID AND o.Status != 'Cancelled'
GROUP BY p.ProductID, p.ProductName, c.CategoryName, c.CategoryID, 
         p.StockQuantity, p.ReorderLevel
ORDER BY TotalRevenue DESC;
```

**Query 4: Running Totals and Moving Averages**
```sql
-- Daily sales with running total and 7-day moving average
WITH DailySales AS (
    SELECT 
        CAST(OrderDate AS DATE) AS SaleDate,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS DailyRevenue
    FROM Sales.Orders
    WHERE Status != 'Cancelled'
    GROUP BY CAST(OrderDate AS DATE)
)
SELECT 
    SaleDate,
    OrderCount,
    DailyRevenue,
    SUM(DailyRevenue) OVER (ORDER BY SaleDate) AS RunningTotal,
    AVG(DailyRevenue) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS SevenDayMovingAvg
FROM DailySales
ORDER BY SaleDate;
```

---

## Phase 5: Stored Procedures & Functions (15 Points)

### 5.1 Required Stored Procedures

**Procedure 1: Process New Order**
```sql
CREATE OR ALTER PROCEDURE Sales.usp_ProcessOrder
    @CustomerID INT,
    @ShippingAddress NVARCHAR(500),
    @PaymentMethod NVARCHAR(20),
    @OrderItems Sales.OrderItemsType READONLY,  -- Table-valued parameter
    @OrderID INT OUTPUT,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    SET @ErrorMessage = NULL;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate customer exists
        IF NOT EXISTS (SELECT 1 FROM Dimension.Customers WHERE CustomerID = @CustomerID)
        BEGIN
            SET @ErrorMessage = 'Customer not found';
            RETURN;
        END
        
        -- Validate stock availability
        IF EXISTS (
            SELECT 1 
            FROM @OrderItems oi
            JOIN Dimension.Products p ON oi.ProductID = p.ProductID
            WHERE p.StockQuantity < oi.Quantity
        )
        BEGIN
            SET @ErrorMessage = 'Insufficient stock for one or more products';
            RETURN;
        END
        
        -- Create order
        INSERT INTO Sales.Orders (CustomerID, ShippingAddress, PaymentMethod)
        VALUES (@CustomerID, @ShippingAddress, @PaymentMethod);
        
        SET @OrderID = SCOPE_IDENTITY();
        
        -- Insert order items
        INSERT INTO Sales.OrderItems (OrderID, ProductID, Quantity, UnitPrice, Discount)
        SELECT @OrderID, oi.ProductID, oi.Quantity, p.UnitPrice, ISNULL(oi.Discount, 0)
        FROM @OrderItems oi
        JOIN Dimension.Products p ON oi.ProductID = p.ProductID;
        
        -- Update order total
        UPDATE Sales.Orders
        SET TotalAmount = (
            SELECT SUM(LineTotal) 
            FROM Sales.OrderItems 
            WHERE OrderID = @OrderID
        )
        WHERE OrderID = @OrderID;
        
        -- Update stock quantities
        UPDATE p
        SET StockQuantity = p.StockQuantity - oi.Quantity
        FROM Dimension.Products p
        JOIN @OrderItems oi ON p.ProductID = oi.ProductID;
        
        COMMIT TRANSACTION;
        SET @Success = 1;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END;
GO
```

**Procedure 2: Generate Sales Report**
```sql
CREATE OR ALTER PROCEDURE Sales.usp_GenerateSalesReport
    @StartDate DATE,
    @EndDate DATE,
    @CategoryID INT = NULL,
    @GroupBy NVARCHAR(20) = 'Daily'  -- Daily, Weekly, Monthly
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CASE @GroupBy
            WHEN 'Daily' THEN CAST(o.OrderDate AS DATE)
            WHEN 'Weekly' THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, o.OrderDate), 0)
            WHEN 'Monthly' THEN DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
        END AS Period,
        c.CategoryName,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
        SUM(oi.Quantity) AS ItemsSold,
        SUM(oi.LineTotal) AS Revenue,
        AVG(o.TotalAmount) AS AvgOrderValue
    FROM Sales.Orders o
    JOIN Sales.OrderItems oi ON o.OrderID = oi.OrderID
    JOIN Dimension.Products p ON oi.ProductID = p.ProductID
    JOIN Dimension.Categories c ON p.CategoryID = c.CategoryID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
        AND o.Status != 'Cancelled'
        AND (@CategoryID IS NULL OR c.CategoryID = @CategoryID)
    GROUP BY 
        CASE @GroupBy
            WHEN 'Daily' THEN CAST(o.OrderDate AS DATE)
            WHEN 'Weekly' THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, o.OrderDate), 0)
            WHEN 'Monthly' THEN DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
        END,
        c.CategoryName
    ORDER BY Period, Revenue DESC;
END;
GO
```

**Function: Calculate Customer Lifetime Value**
```sql
CREATE OR ALTER FUNCTION Sales.fn_CalculateCLV
(
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN
(
    WITH CustomerOrders AS (
        SELECT 
            CustomerID,
            MIN(OrderDate) AS FirstOrderDate,
            MAX(OrderDate) AS LastOrderDate,
            COUNT(OrderID) AS TotalOrders,
            SUM(TotalAmount) AS TotalRevenue,
            AVG(TotalAmount) AS AvgOrderValue,
            DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate)) + 1 AS CustomerMonths
        FROM Sales.Orders
        WHERE CustomerID = @CustomerID AND Status != 'Cancelled'
        GROUP BY CustomerID
    )
    SELECT 
        CustomerID,
        TotalOrders,
        TotalRevenue,
        AvgOrderValue,
        CustomerMonths,
        CASE 
            WHEN CustomerMonths > 0 
            THEN CAST(TotalOrders AS FLOAT) / CustomerMonths 
            ELSE TotalOrders 
        END AS OrderFrequency,
        -- Estimated CLV for next 12 months
        AvgOrderValue * 
        (CASE WHEN CustomerMonths > 0 THEN CAST(TotalOrders AS FLOAT) / CustomerMonths ELSE 1 END) * 
        12 AS EstimatedAnnualCLV
    FROM CustomerOrders
);
GO
```

---

## Evaluation Criteria

| Phase | Points | Criteria |
|-------|--------|----------|
| Database Design | 25 | ERD completeness, normalization, documentation |
| Implementation | 25 | Table creation, constraints, indexes |
| Data Population | 15 | Sample data quality, data generation scripts |
| Advanced Queries | 20 | Query complexity, optimization, correctness |
| Stored Procedures | 15 | Error handling, transactions, reusability |
| **Total** | **100** | |

### Bonus Points (Up to 10 extra)
- Implement audit logging triggers (+3)
- Create a data archival strategy (+2)
- Add full-text search capability (+2)
- Implement row-level security (+3)

---

## Submission Guidelines

1. **SQL Scripts**: All DDL and DML scripts in separate .sql files
2. **Documentation**: ERD diagram (use draw.io or similar)
3. **Data Dictionary**: Excel/Markdown file describing all tables
4. **Query Results**: Screenshots or exported results
5. **README**: Project overview and setup instructions

---

## 📚 Interview Questions (10 Q&A)

### Q1: How did you ensure data integrity in your database design?
**Answer**: Data integrity was ensured through multiple mechanisms:
- **Primary Keys**: Every table has a unique identifier
- **Foreign Keys**: Maintain referential integrity between related tables
- **CHECK Constraints**: Validate business rules (e.g., positive prices, valid status values)
- **UNIQUE Constraints**: Prevent duplicate emails
- **DEFAULT Values**: Ensure required fields have sensible defaults
- **NOT NULL Constraints**: Enforce mandatory fields

### Q2: Explain your normalization strategy and any denormalization decisions.
**Answer**: All tables are designed in 3NF:
- **1NF**: All columns contain atomic values
- **2NF**: All non-key attributes depend on the entire primary key
- **3NF**: No transitive dependencies

Intentional denormalization: The `LineTotal` computed column in `OrderItems` is stored (PERSISTED) for query performance, as it's frequently accessed in aggregations.

### Q3: How would you optimize a slow-running report query?
**Answer**: Optimization approach:
1. **Analyze execution plan** to identify bottlenecks
2. **Add appropriate indexes** on JOIN and WHERE columns
3. **Consider covered indexes** for frequently accessed columns
4. **Use query hints** sparingly if needed
5. **Partition large tables** by date for time-based queries
6. **Create indexed views** for complex aggregations
7. **Update statistics** regularly

### Q4: Why did you use schemas to organize your tables?
**Answer**: Schemas provide several benefits:
- **Logical organization**: Group related objects (Sales, Inventory, Dimension)
- **Security management**: Grant permissions at schema level
- **Avoid naming conflicts**: Same table names can exist in different schemas
- **Easier maintenance**: Identify object purpose from schema name
- **Team collaboration**: Different teams can own different schemas

### Q5: How does your stored procedure handle errors and transactions?
**Answer**: The `usp_ProcessOrder` procedure uses:
- **TRY-CATCH blocks** to capture errors
- **Explicit transactions** to ensure atomicity
- **Validation before operations** to fail fast
- **ROLLBACK on error** to maintain consistency
- **OUTPUT parameters** to communicate status to caller
- **Meaningful error messages** for debugging

### Q6: Explain the RFM analysis query. Why is it useful?
**Answer**: RFM (Recency, Frequency, Monetary) analysis segments customers based on:
- **Recency**: How recently they purchased
- **Frequency**: How often they purchase
- **Monetary**: How much they spend

Each metric is scored 1-5 using NTILE(), and combined scores classify customers into segments (Champions, Loyal, At Risk, etc.). This helps marketing teams target the right customers with appropriate campaigns.

### Q7: What is the purpose of the computed column `LineTotal`?
**Answer**: The `LineTotal` computed column:
- Calculates `Quantity * UnitPrice * (1 - Discount/100)`
- Is marked as `PERSISTED` so it's physically stored
- Automatically recalculates if source columns change
- Improves query performance by avoiding runtime calculations
- Can be indexed for even better performance
- Ensures consistent calculation across all queries

### Q8: How would you implement audit logging for this database?
**Answer**: Implement audit logging using:
```sql
CREATE TABLE Audit.ChangeLog (
    LogID BIGINT IDENTITY PRIMARY KEY,
    TableName NVARCHAR(100),
    Action NVARCHAR(10),  -- INSERT, UPDATE, DELETE
    RecordID INT,
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    ChangedBy NVARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedAt DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TRIGGER trg_Customers_Audit
ON Dimension.Customers
AFTER INSERT, UPDATE, DELETE
AS BEGIN
    -- Log changes with JSON-serialized old/new values
END;
```

### Q9: How would you scale this database for millions of orders?
**Answer**: Scaling strategies:
- **Partitioning**: Partition Orders by OrderDate (monthly/yearly)
- **Archiving**: Move old data to archive tables
- **Indexed views**: Pre-aggregate common queries
- **Columnstore indexes**: For analytical queries
- **Read replicas**: Offload reporting queries
- **Data compression**: Reduce storage and I/O
- **Query optimization**: Regular performance tuning
- **Caching**: Use Redis for frequently accessed data

### Q10: What improvements would you make for a production deployment?
**Answer**: Production improvements:
- Add **temporal tables** for historical tracking
- Implement **row-level security** for multi-tenant access
- Add **data masking** for sensitive columns (email, phone)
- Create **backup and recovery** procedures
- Set up **monitoring and alerting** for performance
- Implement **change data capture** for ETL processes
- Add **connection pooling** configuration
- Create **maintenance jobs** for index and statistics updates
