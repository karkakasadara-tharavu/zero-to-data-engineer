/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  MODULE 07: ADVANCED ETL PATTERNS                                            ║
║  LAB 67: ADVANCED ETL CAPSTONE PROJECT                                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  PROJECT: ENTERPRISE DATA INTEGRATION PLATFORM                               ║
║                                                                              ║
║  Build a complete, production-ready ETL solution that integrates:            ║
║  • Multiple source systems (ERP, CRM, E-Commerce)                           ║
║  • Data quality framework                                                    ║
║  • SCD Type 2 dimensions                                                     ║
║  • Incremental fact table loading                                           ║
║  • Error handling and recovery                                              ║
║  • Metadata-driven orchestration                                            ║
║  • Performance optimization                                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- ============================================================================
-- PROJECT OVERVIEW
-- ============================================================================

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  SCENARIO                                                                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  You are the Lead Data Engineer at GlobalMart, a multinational retailer.    ║
║  Your task is to build an enterprise data integration platform that:        ║
║                                                                              ║
║  1. Extracts data from multiple source systems                              ║
║  2. Applies data quality rules and transformations                          ║
║  3. Loads data into a dimensional data warehouse                           ║
║  4. Provides full audit trail and error handling                           ║
║  5. Supports both full and incremental loads                               ║
║  6. Is configuration-driven for maintainability                            ║
║                                                                              ║
║  Source Systems:                                                             ║
║  - ERP: Products, Inventory, Employees                                      ║
║  - CRM: Customers, Contacts, Campaigns                                      ║
║  - E-Commerce: Orders, OrderItems, WebActivity                              ║
║                                                                              ║
║  Target Data Warehouse:                                                      ║
║  - dim.Customer (SCD Type 2)                                                ║
║  - dim.Product (SCD Type 1)                                                 ║
║  - dim.Employee (SCD Type 2)                                                ║
║  - dim.Date (static)                                                        ║
║  - fact.Sales (append)                                                      ║
║  - fact.Inventory (snapshot)                                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE DataEngineerTraining;
GO

-- ============================================================================
-- SECTION 1: CREATE DATABASE SCHEMAS
-- ============================================================================

-- Create all required schemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'source_erp') EXEC('CREATE SCHEMA source_erp');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'source_crm') EXEC('CREATE SCHEMA source_crm');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'source_ecom') EXEC('CREATE SCHEMA source_ecom');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging') EXEC('CREATE SCHEMA staging');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim') EXEC('CREATE SCHEMA dim');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'fact') EXEC('CREATE SCHEMA fact');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl') EXEC('CREATE SCHEMA etl');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'meta') EXEC('CREATE SCHEMA meta');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dq') EXEC('CREATE SCHEMA dq');
GO

-- ============================================================================
-- SECTION 2: CREATE SOURCE SYSTEM TABLES
-- ============================================================================

-- ERP System Tables
DROP TABLE IF EXISTS source_erp.Products;
CREATE TABLE source_erp.Products (
    ProductID           INT PRIMARY KEY,
    ProductCode         NVARCHAR(20) NOT NULL,
    ProductName         NVARCHAR(100) NOT NULL,
    Category            NVARCHAR(50),
    SubCategory         NVARCHAR(50),
    Brand               NVARCHAR(50),
    UnitCost            DECIMAL(10,2),
    ListPrice           DECIMAL(10,2),
    IsActive            BIT DEFAULT 1,
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    ModifiedDate        DATETIME2 DEFAULT GETDATE()
);

DROP TABLE IF EXISTS source_erp.Employees;
CREATE TABLE source_erp.Employees (
    EmployeeID          INT PRIMARY KEY,
    EmployeeCode        NVARCHAR(20) NOT NULL,
    FirstName           NVARCHAR(50) NOT NULL,
    LastName            NVARCHAR(50) NOT NULL,
    Email               NVARCHAR(100),
    Department          NVARCHAR(50),
    JobTitle            NVARCHAR(100),
    HireDate            DATE,
    TerminationDate     DATE,
    ManagerID           INT,
    IsActive            BIT DEFAULT 1,
    ModifiedDate        DATETIME2 DEFAULT GETDATE()
);

DROP TABLE IF EXISTS source_erp.Inventory;
CREATE TABLE source_erp.Inventory (
    InventoryID         INT IDENTITY(1,1) PRIMARY KEY,
    ProductID           INT NOT NULL,
    WarehouseID         INT NOT NULL,
    QuantityOnHand      INT NOT NULL,
    QuantityReserved    INT DEFAULT 0,
    ReorderPoint        INT,
    SnapshotDate        DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE)
);
GO

-- CRM System Tables
DROP TABLE IF EXISTS source_crm.Customers;
CREATE TABLE source_crm.Customers (
    CustomerID          INT PRIMARY KEY,
    CustomerCode        NVARCHAR(20) NOT NULL,
    CompanyName         NVARCHAR(100),
    FirstName           NVARCHAR(50),
    LastName            NVARCHAR(50),
    Email               NVARCHAR(100),
    Phone               NVARCHAR(30),
    Address             NVARCHAR(200),
    City                NVARCHAR(50),
    State               NVARCHAR(50),
    Country             NVARCHAR(50),
    PostalCode          NVARCHAR(20),
    CustomerType        NVARCHAR(20),     -- 'Individual', 'Business'
    Segment             NVARCHAR(20),     -- 'Premium', 'Standard', 'Basic'
    CreditLimit         DECIMAL(12,2),
    IsActive            BIT DEFAULT 1,
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    ModifiedDate        DATETIME2 DEFAULT GETDATE()
);
GO

-- E-Commerce System Tables
DROP TABLE IF EXISTS source_ecom.OrderItems;
DROP TABLE IF EXISTS source_ecom.Orders;

CREATE TABLE source_ecom.Orders (
    OrderID             INT PRIMARY KEY,
    OrderNumber         NVARCHAR(30) NOT NULL,
    CustomerID          INT NOT NULL,
    OrderDate           DATETIME2 NOT NULL,
    ShipDate            DATETIME2,
    OrderStatus         NVARCHAR(20),     -- 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'
    SalesEmployeeID     INT,
    ShippingAddress     NVARCHAR(300),
    PaymentMethod       NVARCHAR(50),
    OrderTotal          DECIMAL(12,2),
    DiscountAmount      DECIMAL(12,2) DEFAULT 0,
    TaxAmount           DECIMAL(12,2) DEFAULT 0,
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    ModifiedDate        DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE source_ecom.OrderItems (
    OrderItemID         INT IDENTITY(1,1) PRIMARY KEY,
    OrderID             INT NOT NULL REFERENCES source_ecom.Orders(OrderID),
    ProductID           INT NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(10,2) NOT NULL,
    Discount            DECIMAL(5,2) DEFAULT 0,
    LineTotal           AS (Quantity * UnitPrice * (1 - Discount/100)) PERSISTED
);
GO

-- ============================================================================
-- SECTION 3: POPULATE SOURCE SYSTEMS WITH TEST DATA
-- ============================================================================

-- Products (50 products)
INSERT INTO source_erp.Products (ProductID, ProductCode, ProductName, Category, SubCategory, Brand, UnitCost, ListPrice)
SELECT 
    n,
    'PRD-' + RIGHT('0000' + CAST(n AS VARCHAR(4)), 4),
    'Product ' + CAST(n AS VARCHAR(10)),
    CASE (n % 5) WHEN 0 THEN 'Electronics' WHEN 1 THEN 'Clothing' WHEN 2 THEN 'Home' WHEN 3 THEN 'Sports' ELSE 'Books' END,
    'SubCat-' + CAST((n % 10) + 1 AS VARCHAR(5)),
    CASE (n % 4) WHEN 0 THEN 'BrandA' WHEN 1 THEN 'BrandB' WHEN 2 THEN 'BrandC' ELSE 'BrandD' END,
    CAST(10 + (n % 50) * 2 AS DECIMAL(10,2)),
    CAST(20 + (n % 50) * 3 AS DECIMAL(10,2))
FROM (SELECT TOP 50 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) nums;

-- Employees (20 employees)
INSERT INTO source_erp.Employees (EmployeeID, EmployeeCode, FirstName, LastName, Email, Department, JobTitle, HireDate, ManagerID)
SELECT 
    n,
    'EMP-' + RIGHT('000' + CAST(n AS VARCHAR(3)), 3),
    'FirstName' + CAST(n AS VARCHAR(5)),
    'LastName' + CAST(n AS VARCHAR(5)),
    'employee' + CAST(n AS VARCHAR(5)) + '@globalmart.com',
    CASE (n % 4) WHEN 0 THEN 'Sales' WHEN 1 THEN 'Marketing' WHEN 2 THEN 'Operations' ELSE 'Finance' END,
    CASE (n % 3) WHEN 0 THEN 'Manager' WHEN 1 THEN 'Specialist' ELSE 'Analyst' END,
    DATEADD(DAY, -n * 30, GETDATE()),
    CASE WHEN n > 1 THEN ((n - 1) / 5) + 1 ELSE NULL END
FROM (SELECT TOP 20 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) nums;

-- Customers (100 customers)
INSERT INTO source_crm.Customers (CustomerID, CustomerCode, CompanyName, FirstName, LastName, Email, Phone, City, State, Country, CustomerType, Segment, CreditLimit)
SELECT 
    n,
    'CUS-' + RIGHT('00000' + CAST(n AS VARCHAR(5)), 5),
    CASE WHEN n % 3 = 0 THEN 'Company ' + CAST(n AS VARCHAR(10)) ELSE NULL END,
    'First' + CAST(n AS VARCHAR(10)),
    'Last' + CAST(n AS VARCHAR(10)),
    'customer' + CAST(n AS VARCHAR(10)) + '@email.com',
    '555-' + RIGHT('0000' + CAST(n AS VARCHAR(4)), 4),
    CASE (n % 5) WHEN 0 THEN 'New York' WHEN 1 THEN 'Los Angeles' WHEN 2 THEN 'Chicago' WHEN 3 THEN 'Houston' ELSE 'Phoenix' END,
    CASE (n % 5) WHEN 0 THEN 'NY' WHEN 1 THEN 'CA' WHEN 2 THEN 'IL' WHEN 3 THEN 'TX' ELSE 'AZ' END,
    'USA',
    CASE WHEN n % 3 = 0 THEN 'Business' ELSE 'Individual' END,
    CASE (n % 3) WHEN 0 THEN 'Premium' WHEN 1 THEN 'Standard' ELSE 'Basic' END,
    CAST((n % 10 + 1) * 1000 AS DECIMAL(12,2))
FROM (SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) nums;

-- Orders (500 orders)
INSERT INTO source_ecom.Orders (OrderID, OrderNumber, CustomerID, OrderDate, ShipDate, OrderStatus, SalesEmployeeID, PaymentMethod, OrderTotal, DiscountAmount, TaxAmount)
SELECT 
    n,
    'ORD-' + FORMAT(GETDATE(), 'yyyyMM') + '-' + RIGHT('00000' + CAST(n AS VARCHAR(5)), 5),
    (n % 100) + 1,  -- CustomerID
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),  -- Random date in last year
    CASE WHEN n % 10 < 7 THEN DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE()) ELSE NULL END,
    CASE (n % 5) WHEN 0 THEN 'Pending' WHEN 1 THEN 'Processing' WHEN 2 THEN 'Shipped' WHEN 3 THEN 'Delivered' ELSE 'Cancelled' END,
    (n % 20) + 1,  -- SalesEmployeeID
    CASE (n % 3) WHEN 0 THEN 'Credit Card' WHEN 1 THEN 'PayPal' ELSE 'Bank Transfer' END,
    CAST(50 + (n % 500) AS DECIMAL(12,2)),
    CAST((n % 20) AS DECIMAL(12,2)),
    CAST((50 + (n % 500)) * 0.08 AS DECIMAL(12,2))
FROM (SELECT TOP 500 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) nums;

-- Order Items (2000 items)
INSERT INTO source_ecom.OrderItems (OrderID, ProductID, Quantity, UnitPrice, Discount)
SELECT 
    ((n - 1) % 500) + 1,  -- OrderID (1-500)
    ((n - 1) % 50) + 1,   -- ProductID (1-50)
    (n % 10) + 1,         -- Quantity (1-10)
    p.ListPrice,
    CAST(((n % 4) * 5) AS DECIMAL(5,2))  -- Discount (0, 5, 10, 15%)
FROM (SELECT TOP 2000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects a, sys.all_objects b) nums
CROSS APPLY (SELECT ListPrice FROM source_erp.Products WHERE ProductID = ((nums.n - 1) % 50) + 1) p;

PRINT 'Source data populated successfully';
PRINT 'Products: 50, Employees: 20, Customers: 100, Orders: 500, Order Items: 2000';
GO

-- ============================================================================
-- SECTION 4: CREATE DATA WAREHOUSE TABLES
-- ============================================================================

-- Date Dimension
DROP TABLE IF EXISTS dim.Date;
CREATE TABLE dim.Date (
    DateKey             INT NOT NULL PRIMARY KEY,  -- YYYYMMDD format
    FullDate            DATE NOT NULL,
    DayOfWeek           TINYINT NOT NULL,
    DayName             NVARCHAR(10) NOT NULL,
    DayOfMonth          TINYINT NOT NULL,
    DayOfYear           SMALLINT NOT NULL,
    WeekOfYear          TINYINT NOT NULL,
    MonthNumber         TINYINT NOT NULL,
    MonthName           NVARCHAR(10) NOT NULL,
    Quarter             TINYINT NOT NULL,
    Year                SMALLINT NOT NULL,
    IsWeekend           BIT NOT NULL,
    IsHoliday           BIT NOT NULL DEFAULT 0,
    FiscalYear          SMALLINT,
    FiscalQuarter       TINYINT
);
GO

-- Populate Date Dimension (5 years)
;WITH DateSequence AS (
    SELECT CAST('2020-01-01' AS DATE) AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < '2025-12-31'
)
INSERT INTO dim.Date (DateKey, FullDate, DayOfWeek, DayName, DayOfMonth, DayOfYear, WeekOfYear, MonthNumber, MonthName, Quarter, Year, IsWeekend, FiscalYear, FiscalQuarter)
SELECT 
    CAST(FORMAT(DateValue, 'yyyyMMdd') AS INT),
    DateValue,
    DATEPART(WEEKDAY, DateValue),
    DATENAME(WEEKDAY, DateValue),
    DAY(DateValue),
    DATEPART(DAYOFYEAR, DateValue),
    DATEPART(WEEK, DateValue),
    MONTH(DateValue),
    DATENAME(MONTH, DateValue),
    DATEPART(QUARTER, DateValue),
    YEAR(DateValue),
    CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END,
    CASE WHEN MONTH(DateValue) >= 7 THEN YEAR(DateValue) + 1 ELSE YEAR(DateValue) END,
    CASE 
        WHEN MONTH(DateValue) IN (7,8,9) THEN 1
        WHEN MONTH(DateValue) IN (10,11,12) THEN 2
        WHEN MONTH(DateValue) IN (1,2,3) THEN 3
        ELSE 4
    END
FROM DateSequence
OPTION (MAXRECURSION 3000);
GO

-- Customer Dimension (SCD Type 2)
DROP TABLE IF EXISTS dim.Customer;
CREATE TABLE dim.Customer (
    CustomerKey         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID          INT NOT NULL,                    -- Business Key
    CustomerCode        NVARCHAR(20) NOT NULL,
    CustomerName        NVARCHAR(200) NOT NULL,
    Email               NVARCHAR(100),
    Phone               NVARCHAR(30),
    City                NVARCHAR(50),
    State               NVARCHAR(50),
    Country             NVARCHAR(50),
    CustomerType        NVARCHAR(20),
    Segment             NVARCHAR(20),
    CreditLimit         DECIMAL(12,2),
    -- SCD Type 2 columns
    EffectiveStartDate  DATE NOT NULL,
    EffectiveEndDate    DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent           BIT NOT NULL DEFAULT 1,
    RowHash             VARBINARY(32),
    -- Audit
    SourceSystem        NVARCHAR(20) DEFAULT 'CRM',
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    ModifiedDate        DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX IX_DimCustomer_BusinessKey ON dim.Customer(CustomerID, IsCurrent);
CREATE INDEX IX_DimCustomer_Current ON dim.Customer(IsCurrent) INCLUDE (CustomerID, CustomerName, Segment);
GO

-- Product Dimension (SCD Type 1)
DROP TABLE IF EXISTS dim.Product;
CREATE TABLE dim.Product (
    ProductKey          INT IDENTITY(1,1) PRIMARY KEY,
    ProductID           INT NOT NULL UNIQUE,             -- Business Key
    ProductCode         NVARCHAR(20) NOT NULL,
    ProductName         NVARCHAR(100) NOT NULL,
    Category            NVARCHAR(50),
    SubCategory         NVARCHAR(50),
    Brand               NVARCHAR(50),
    UnitCost            DECIMAL(10,2),
    ListPrice           DECIMAL(10,2),
    IsActive            BIT DEFAULT 1,
    SourceSystem        NVARCHAR(20) DEFAULT 'ERP',
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    ModifiedDate        DATETIME2 DEFAULT GETDATE()
);
GO

-- Employee Dimension (SCD Type 2)
DROP TABLE IF EXISTS dim.Employee;
CREATE TABLE dim.Employee (
    EmployeeKey         INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID          INT NOT NULL,                    -- Business Key
    EmployeeCode        NVARCHAR(20) NOT NULL,
    FullName            NVARCHAR(100) NOT NULL,
    Email               NVARCHAR(100),
    Department          NVARCHAR(50),
    JobTitle            NVARCHAR(100),
    HireDate            DATE,
    IsActive            BIT DEFAULT 1,
    -- SCD Type 2 columns
    EffectiveStartDate  DATE NOT NULL,
    EffectiveEndDate    DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent           BIT NOT NULL DEFAULT 1,
    RowHash             VARBINARY(32),
    SourceSystem        NVARCHAR(20) DEFAULT 'ERP',
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX IX_DimEmployee_BusinessKey ON dim.Employee(EmployeeID, IsCurrent);
GO

-- Sales Fact Table
DROP TABLE IF EXISTS fact.Sales;
CREATE TABLE fact.Sales (
    SalesKey            BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID             INT NOT NULL,                    -- Degenerate dimension
    OrderItemID         INT NOT NULL,
    DateKey             INT NOT NULL,
    CustomerKey         INT NOT NULL,
    ProductKey          INT NOT NULL,
    EmployeeKey         INT,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(10,2) NOT NULL,
    DiscountPercent     DECIMAL(5,2) DEFAULT 0,
    LineTotal           DECIMAL(12,2) NOT NULL,
    OrderStatus         NVARCHAR(20),
    PaymentMethod       NVARCHAR(50),
    LoadBatchID         INT,
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX IX_FactSales_DateKey ON fact.Sales(DateKey);
CREATE INDEX IX_FactSales_CustomerKey ON fact.Sales(CustomerKey);
CREATE INDEX IX_FactSales_ProductKey ON fact.Sales(ProductKey);
GO

-- ============================================================================
-- SECTION 5: CREATE STAGING TABLES
-- ============================================================================

-- Staging tables mirror source structures
DROP TABLE IF EXISTS staging.stg_Customer;
CREATE TABLE staging.stg_Customer (
    CustomerID          INT PRIMARY KEY,
    CustomerCode        NVARCHAR(20),
    CustomerName        NVARCHAR(200),
    Email               NVARCHAR(100),
    Phone               NVARCHAR(30),
    City                NVARCHAR(50),
    State               NVARCHAR(50),
    Country             NVARCHAR(50),
    CustomerType        NVARCHAR(20),
    Segment             NVARCHAR(20),
    CreditLimit         DECIMAL(12,2),
    RowHash             VARBINARY(32),
    LoadDate            DATETIME2 DEFAULT GETDATE()
);

DROP TABLE IF EXISTS staging.stg_Product;
CREATE TABLE staging.stg_Product (
    ProductID           INT PRIMARY KEY,
    ProductCode         NVARCHAR(20),
    ProductName         NVARCHAR(100),
    Category            NVARCHAR(50),
    SubCategory         NVARCHAR(50),
    Brand               NVARCHAR(50),
    UnitCost            DECIMAL(10,2),
    ListPrice           DECIMAL(10,2),
    IsActive            BIT,
    LoadDate            DATETIME2 DEFAULT GETDATE()
);

DROP TABLE IF EXISTS staging.stg_Sales;
CREATE TABLE staging.stg_Sales (
    OrderID             INT,
    OrderItemID         INT,
    OrderDate           DATE,
    CustomerID          INT,
    ProductID           INT,
    SalesEmployeeID     INT,
    Quantity            INT,
    UnitPrice           DECIMAL(10,2),
    DiscountPercent     DECIMAL(5,2),
    LineTotal           DECIMAL(12,2),
    OrderStatus         NVARCHAR(20),
    PaymentMethod       NVARCHAR(50),
    LoadDate            DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================================
-- SECTION 6: ETL INFRASTRUCTURE TABLES
-- ============================================================================

-- ETL Execution Log
DROP TABLE IF EXISTS etl.ExecutionLog;
CREATE TABLE etl.ExecutionLog (
    ExecutionID         INT IDENTITY(1,1) PRIMARY KEY,
    PackageName         NVARCHAR(100) NOT NULL,
    TaskName            NVARCHAR(100),
    ExecutionStatus     NVARCHAR(20) NOT NULL,
    StartTime           DATETIME2 NOT NULL DEFAULT GETDATE(),
    EndTime             DATETIME2,
    RowsRead            INT,
    RowsInserted        INT,
    RowsUpdated         INT,
    RowsErrored         INT,
    ErrorMessage        NVARCHAR(MAX)
);

-- Data Quality Results
DROP TABLE IF EXISTS dq.ValidationResults;
CREATE TABLE dq.ValidationResults (
    ResultID            INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID         INT,
    TableName           NVARCHAR(200) NOT NULL,
    RuleName            NVARCHAR(100) NOT NULL,
    RuleDescription     NVARCHAR(500),
    FailedRowCount      INT,
    TotalRowCount       INT,
    PassRate            DECIMAL(5,2),
    ValidationDate      DATETIME2 DEFAULT GETDATE(),
    IsPassed            BIT
);

-- Watermark table for incremental loads
DROP TABLE IF EXISTS etl.Watermark;
CREATE TABLE etl.Watermark (
    WatermarkID         INT IDENTITY(1,1) PRIMARY KEY,
    TableName           NVARCHAR(200) NOT NULL UNIQUE,
    LastLoadDate        DATETIME2 NOT NULL,
    LastLoadRowCount    INT,
    UpdatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- Initialize watermarks
INSERT INTO etl.Watermark (TableName, LastLoadDate)
VALUES 
    ('source_crm.Customers', '1900-01-01'),
    ('source_erp.Products', '1900-01-01'),
    ('source_ecom.Orders', '1900-01-01');
GO

-- ============================================================================
-- SECTION 7: ETL PROCEDURES - STAGING LOADS
-- ============================================================================

-- Load Staging Customers
CREATE OR ALTER PROCEDURE etl.usp_LoadStaging_Customer
    @ExecutionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowCount INT;
    
    -- Log start
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus)
    VALUES ('DailyLoad', 'Load_Staging_Customer', 'Running');
    SET @ExecutionID = SCOPE_IDENTITY();
    
    BEGIN TRY
        -- Truncate staging
        TRUNCATE TABLE staging.stg_Customer;
        
        -- Load with transformations
        INSERT INTO staging.stg_Customer (
            CustomerID, CustomerCode, CustomerName, Email, Phone, 
            City, State, Country, CustomerType, Segment, CreditLimit, RowHash
        )
        SELECT 
            CustomerID,
            CustomerCode,
            COALESCE(CompanyName, FirstName + ' ' + LastName) AS CustomerName,
            LOWER(TRIM(Email)) AS Email,
            Phone,
            UPPER(City) AS City,
            State,
            Country,
            CustomerType,
            Segment,
            CreditLimit,
            HASHBYTES('SHA2_256', 
                CONCAT(COALESCE(CompanyName, FirstName + ' ' + LastName), '|', 
                       LOWER(Email), '|', City, '|', State, '|', Segment))
        FROM source_crm.Customers
        WHERE IsActive = 1;
        
        SET @RowCount = @@ROWCOUNT;
        
        -- Log success
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Success',
            EndTime = GETDATE(),
            RowsRead = @RowCount,
            RowsInserted = @RowCount
        WHERE ExecutionID = @ExecutionID;
        
        PRINT 'Loaded ' + CAST(@RowCount AS VARCHAR(20)) + ' customers to staging';
        
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Failed',
            EndTime = GETDATE(),
            ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @ExecutionID;
        
        THROW;
    END CATCH
END;
GO

-- Load Staging Products
CREATE OR ALTER PROCEDURE etl.usp_LoadStaging_Product
    @ExecutionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus)
    VALUES ('DailyLoad', 'Load_Staging_Product', 'Running');
    SET @ExecutionID = SCOPE_IDENTITY();
    
    BEGIN TRY
        TRUNCATE TABLE staging.stg_Product;
        
        INSERT INTO staging.stg_Product (
            ProductID, ProductCode, ProductName, Category, SubCategory,
            Brand, UnitCost, ListPrice, IsActive
        )
        SELECT 
            ProductID, ProductCode, TRIM(ProductName), Category, SubCategory,
            Brand, UnitCost, ListPrice, IsActive
        FROM source_erp.Products;
        
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Success',
            EndTime = GETDATE(),
            RowsInserted = @@ROWCOUNT
        WHERE ExecutionID = @ExecutionID;
        
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Failed', EndTime = GETDATE(), ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @ExecutionID;
        THROW;
    END CATCH
END;
GO

-- Load Staging Sales (Incremental)
CREATE OR ALTER PROCEDURE etl.usp_LoadStaging_Sales
    @ExecutionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastLoadDate DATETIME2;
    DECLARE @RowCount INT;
    
    -- Get watermark
    SELECT @LastLoadDate = LastLoadDate FROM etl.Watermark WHERE TableName = 'source_ecom.Orders';
    
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus)
    VALUES ('DailyLoad', 'Load_Staging_Sales', 'Running');
    SET @ExecutionID = SCOPE_IDENTITY();
    
    BEGIN TRY
        TRUNCATE TABLE staging.stg_Sales;
        
        -- Load incremental data
        INSERT INTO staging.stg_Sales (
            OrderID, OrderItemID, OrderDate, CustomerID, ProductID,
            SalesEmployeeID, Quantity, UnitPrice, DiscountPercent,
            LineTotal, OrderStatus, PaymentMethod
        )
        SELECT 
            o.OrderID,
            oi.OrderItemID,
            CAST(o.OrderDate AS DATE),
            o.CustomerID,
            oi.ProductID,
            o.SalesEmployeeID,
            oi.Quantity,
            oi.UnitPrice,
            oi.Discount,
            oi.LineTotal,
            o.OrderStatus,
            o.PaymentMethod
        FROM source_ecom.Orders o
        INNER JOIN source_ecom.OrderItems oi ON o.OrderID = oi.OrderID
        WHERE o.ModifiedDate > @LastLoadDate;
        
        SET @RowCount = @@ROWCOUNT;
        
        -- Update watermark
        UPDATE etl.Watermark
        SET LastLoadDate = GETDATE(),
            LastLoadRowCount = @RowCount,
            UpdatedDate = GETDATE()
        WHERE TableName = 'source_ecom.Orders';
        
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Success', EndTime = GETDATE(), RowsInserted = @RowCount
        WHERE ExecutionID = @ExecutionID;
        
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Failed', EndTime = GETDATE(), ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @ExecutionID;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- SECTION 8: ETL PROCEDURES - DIMENSION LOADS
-- ============================================================================

-- Load Customer Dimension (SCD Type 2)
CREATE OR ALTER PROCEDURE etl.usp_LoadDim_Customer
    @ExecutionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @InsertCount INT = 0, @UpdateCount INT = 0;
    
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus)
    VALUES ('DailyLoad', 'Load_Dim_Customer', 'Running');
    SET @ExecutionID = SCOPE_IDENTITY();
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Step 1: Expire changed records
        UPDATE d
        SET d.EffectiveEndDate = DATEADD(DAY, -1, @Today),
            d.IsCurrent = 0,
            d.ModifiedDate = GETDATE()
        FROM dim.Customer d
        INNER JOIN staging.stg_Customer s ON d.CustomerID = s.CustomerID
        WHERE d.IsCurrent = 1
          AND d.RowHash != s.RowHash;
        
        SET @UpdateCount = @@ROWCOUNT;
        
        -- Step 2: Insert new versions for changed records
        INSERT INTO dim.Customer (
            CustomerID, CustomerCode, CustomerName, Email, Phone,
            City, State, Country, CustomerType, Segment, CreditLimit,
            EffectiveStartDate, RowHash
        )
        SELECT 
            s.CustomerID, s.CustomerCode, s.CustomerName, s.Email, s.Phone,
            s.City, s.State, s.Country, s.CustomerType, s.Segment, s.CreditLimit,
            @Today, s.RowHash
        FROM staging.stg_Customer s
        INNER JOIN dim.Customer d ON s.CustomerID = d.CustomerID
        WHERE d.IsCurrent = 0 AND d.EffectiveEndDate = DATEADD(DAY, -1, @Today);
        
        -- Step 3: Insert brand new customers
        INSERT INTO dim.Customer (
            CustomerID, CustomerCode, CustomerName, Email, Phone,
            City, State, Country, CustomerType, Segment, CreditLimit,
            EffectiveStartDate, RowHash
        )
        SELECT 
            s.CustomerID, s.CustomerCode, s.CustomerName, s.Email, s.Phone,
            s.City, s.State, s.Country, s.CustomerType, s.Segment, s.CreditLimit,
            @Today, s.RowHash
        FROM staging.stg_Customer s
        WHERE NOT EXISTS (
            SELECT 1 FROM dim.Customer d WHERE d.CustomerID = s.CustomerID
        );
        
        SET @InsertCount = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Success',
            EndTime = GETDATE(),
            RowsInserted = @InsertCount,
            RowsUpdated = @UpdateCount
        WHERE ExecutionID = @ExecutionID;
        
        PRINT 'Customer dimension: ' + CAST(@InsertCount AS VARCHAR) + ' inserts, ' + 
              CAST(@UpdateCount AS VARCHAR) + ' updates';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Failed', EndTime = GETDATE(), ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @ExecutionID;
        THROW;
    END CATCH
END;
GO

-- Load Product Dimension (SCD Type 1)
CREATE OR ALTER PROCEDURE etl.usp_LoadDim_Product
    @ExecutionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus)
    VALUES ('DailyLoad', 'Load_Dim_Product', 'Running');
    SET @ExecutionID = SCOPE_IDENTITY();
    
    BEGIN TRY
        -- MERGE for SCD Type 1
        MERGE dim.Product AS target
        USING staging.stg_Product AS source
        ON target.ProductID = source.ProductID
        WHEN MATCHED THEN
            UPDATE SET
                ProductCode = source.ProductCode,
                ProductName = source.ProductName,
                Category = source.Category,
                SubCategory = source.SubCategory,
                Brand = source.Brand,
                UnitCost = source.UnitCost,
                ListPrice = source.ListPrice,
                IsActive = source.IsActive,
                ModifiedDate = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (ProductID, ProductCode, ProductName, Category, SubCategory, Brand, UnitCost, ListPrice, IsActive)
            VALUES (source.ProductID, source.ProductCode, source.ProductName, source.Category, 
                    source.SubCategory, source.Brand, source.UnitCost, source.ListPrice, source.IsActive);
        
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Success', EndTime = GETDATE(), RowsInserted = @@ROWCOUNT
        WHERE ExecutionID = @ExecutionID;
        
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Failed', EndTime = GETDATE(), ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @ExecutionID;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- SECTION 9: ETL PROCEDURES - FACT LOADS
-- ============================================================================

-- Load Sales Fact
CREATE OR ALTER PROCEDURE etl.usp_LoadFact_Sales
    @ExecutionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LoadBatchID INT = (SELECT ISNULL(MAX(LoadBatchID), 0) + 1 FROM fact.Sales);
    DECLARE @RowCount INT;
    
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus)
    VALUES ('DailyLoad', 'Load_Fact_Sales', 'Running');
    SET @ExecutionID = SCOPE_IDENTITY();
    
    BEGIN TRY
        -- Load fact with dimension lookups
        INSERT INTO fact.Sales (
            OrderID, OrderItemID, DateKey, CustomerKey, ProductKey, EmployeeKey,
            Quantity, UnitPrice, DiscountPercent, LineTotal, 
            OrderStatus, PaymentMethod, LoadBatchID
        )
        SELECT 
            s.OrderID,
            s.OrderItemID,
            CAST(FORMAT(s.OrderDate, 'yyyyMMdd') AS INT) AS DateKey,
            ISNULL(dc.CustomerKey, -1) AS CustomerKey,  -- -1 for unknown
            ISNULL(dp.ProductKey, -1) AS ProductKey,
            ISNULL(de.EmployeeKey, -1) AS EmployeeKey,
            s.Quantity,
            s.UnitPrice,
            s.DiscountPercent,
            s.LineTotal,
            s.OrderStatus,
            s.PaymentMethod,
            @LoadBatchID
        FROM staging.stg_Sales s
        LEFT JOIN dim.Customer dc ON s.CustomerID = dc.CustomerID AND dc.IsCurrent = 1
        LEFT JOIN dim.Product dp ON s.ProductID = dp.ProductID
        LEFT JOIN dim.Employee de ON s.SalesEmployeeID = de.EmployeeID AND de.IsCurrent = 1
        WHERE NOT EXISTS (
            SELECT 1 FROM fact.Sales f 
            WHERE f.OrderID = s.OrderID AND f.OrderItemID = s.OrderItemID
        );
        
        SET @RowCount = @@ROWCOUNT;
        
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Success', EndTime = GETDATE(), RowsInserted = @RowCount
        WHERE ExecutionID = @ExecutionID;
        
        PRINT 'Sales fact loaded: ' + CAST(@RowCount AS VARCHAR) + ' rows';
        
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Failed', EndTime = GETDATE(), ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @ExecutionID;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- SECTION 10: DATA QUALITY VALIDATION
-- ============================================================================

CREATE OR ALTER PROCEDURE dq.usp_ValidateLoad
    @TableName NVARCHAR(200),
    @ExecutionID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TotalRows INT, @FailedRows INT;
    
    -- Validation based on table
    IF @TableName = 'staging.stg_Customer'
    BEGIN
        -- Check for NULL customer names
        SELECT @TotalRows = COUNT(*), @FailedRows = SUM(CASE WHEN CustomerName IS NULL OR CustomerName = '' THEN 1 ELSE 0 END)
        FROM staging.stg_Customer;
        
        INSERT INTO dq.ValidationResults (ExecutionID, TableName, RuleName, RuleDescription, FailedRowCount, TotalRowCount, PassRate, IsPassed)
        VALUES (@ExecutionID, @TableName, 'NotNull_CustomerName', 'Customer name cannot be NULL', @FailedRows, @TotalRows,
                CASE WHEN @TotalRows > 0 THEN CAST((@TotalRows - @FailedRows) * 100.0 / @TotalRows AS DECIMAL(5,2)) ELSE 100 END,
                CASE WHEN @FailedRows = 0 THEN 1 ELSE 0 END);
        
        -- Check for valid email format
        SELECT @FailedRows = COUNT(*)
        FROM staging.stg_Customer
        WHERE Email IS NOT NULL AND Email NOT LIKE '%@%.%';
        
        INSERT INTO dq.ValidationResults (ExecutionID, TableName, RuleName, RuleDescription, FailedRowCount, TotalRowCount, PassRate, IsPassed)
        VALUES (@ExecutionID, @TableName, 'Format_Email', 'Email must contain @ and .', @FailedRows, @TotalRows,
                CASE WHEN @TotalRows > 0 THEN CAST((@TotalRows - @FailedRows) * 100.0 / @TotalRows AS DECIMAL(5,2)) ELSE 100 END,
                CASE WHEN @FailedRows = 0 THEN 1 ELSE 0 END);
    END
    
    IF @TableName = 'fact.Sales'
    BEGIN
        -- Check for orphan customers
        SELECT @TotalRows = COUNT(*) FROM fact.Sales;
        SELECT @FailedRows = COUNT(*) FROM fact.Sales WHERE CustomerKey = -1;
        
        INSERT INTO dq.ValidationResults (ExecutionID, TableName, RuleName, RuleDescription, FailedRowCount, TotalRowCount, PassRate, IsPassed)
        VALUES (@ExecutionID, @TableName, 'Orphan_Customer', 'Sales must have valid customer', @FailedRows, @TotalRows,
                CASE WHEN @TotalRows > 0 THEN CAST((@TotalRows - @FailedRows) * 100.0 / @TotalRows AS DECIMAL(5,2)) ELSE 100 END,
                CASE WHEN @FailedRows = 0 THEN 1 ELSE 0 END);
    END
    
    -- Return results
    SELECT * FROM dq.ValidationResults WHERE ExecutionID = @ExecutionID OR @ExecutionID IS NULL ORDER BY ValidationDate DESC;
END;
GO

-- ============================================================================
-- SECTION 11: MASTER ETL ORCHESTRATION
-- ============================================================================

CREATE OR ALTER PROCEDURE etl.usp_RunDailyLoad
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecID INT;
    DECLARE @MasterExecID INT;
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @HasError BIT = 0;
    
    -- Log master job start
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus)
    VALUES ('MasterJob', 'Daily_ETL_Load', 'Running');
    SET @MasterExecID = SCOPE_IDENTITY();
    
    PRINT '╔══════════════════════════════════════════════════════════════════════════════╗';
    PRINT '║                    STARTING DAILY ETL LOAD                                   ║';
    PRINT '║                    ' + CONVERT(VARCHAR(30), GETDATE(), 120) + '                              ║';
    PRINT '╚══════════════════════════════════════════════════════════════════════════════╝';
    PRINT '';
    
    BEGIN TRY
        -- Step 1: Load Staging
        PRINT '=== STAGE 1: STAGING LOADS ===';
        EXEC etl.usp_LoadStaging_Customer @ExecutionID = @ExecID OUTPUT;
        EXEC etl.usp_LoadStaging_Product @ExecutionID = @ExecID OUTPUT;
        EXEC etl.usp_LoadStaging_Sales @ExecutionID = @ExecID OUTPUT;
        
        -- Step 2: Data Quality Validation
        PRINT '';
        PRINT '=== STAGE 2: DATA QUALITY VALIDATION ===';
        EXEC dq.usp_ValidateLoad @TableName = 'staging.stg_Customer', @ExecutionID = @MasterExecID;
        
        -- Step 3: Load Dimensions
        PRINT '';
        PRINT '=== STAGE 3: DIMENSION LOADS ===';
        EXEC etl.usp_LoadDim_Customer @ExecutionID = @ExecID OUTPUT;
        EXEC etl.usp_LoadDim_Product @ExecutionID = @ExecID OUTPUT;
        
        -- Step 4: Load Facts
        PRINT '';
        PRINT '=== STAGE 4: FACT LOADS ===';
        EXEC etl.usp_LoadFact_Sales @ExecutionID = @ExecID OUTPUT;
        
        -- Step 5: Post-load validation
        PRINT '';
        PRINT '=== STAGE 5: POST-LOAD VALIDATION ===';
        EXEC dq.usp_ValidateLoad @TableName = 'fact.Sales', @ExecutionID = @MasterExecID;
        
        -- Complete master job
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Success',
            EndTime = GETDATE()
        WHERE ExecutionID = @MasterExecID;
        
        PRINT '';
        PRINT '╔══════════════════════════════════════════════════════════════════════════════╗';
        PRINT '║                    DAILY ETL LOAD COMPLETE                                   ║';
        PRINT '║                    Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + ' seconds                                      ║';
        PRINT '╚══════════════════════════════════════════════════════════════════════════════╝';
        
    END TRY
    BEGIN CATCH
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Failed',
            EndTime = GETDATE(),
            ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @MasterExecID;
        
        PRINT '';
        PRINT '*** ETL LOAD FAILED: ' + ERROR_MESSAGE() + ' ***';
        THROW;
    END CATCH
    
    -- Summary report
    SELECT 
        TaskName,
        ExecutionStatus,
        DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
        RowsInserted,
        RowsUpdated,
        RowsErrored
    FROM etl.ExecutionLog
    WHERE StartTime >= @StartTime
    ORDER BY ExecutionID;
END;
GO

-- ============================================================================
-- SECTION 12: EXECUTE THE ETL
-- ============================================================================

-- Run the complete ETL process
EXEC etl.usp_RunDailyLoad;
GO

-- Verify results
SELECT 'dim.Customer' AS TableName, COUNT(*) AS RowCount FROM dim.Customer UNION ALL
SELECT 'dim.Product', COUNT(*) FROM dim.Product UNION ALL
SELECT 'fact.Sales', COUNT(*) FROM fact.Sales UNION ALL
SELECT 'dim.Date', COUNT(*) FROM dim.Date;
GO

-- ============================================================================
-- SECTION 13: EVALUATION RUBRIC
-- ============================================================================

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                         CAPSTONE EVALUATION RUBRIC                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  SECTION 1: DATA MODELING (40 points)                                        ║
║  ─────────────────────────────────────                                       ║
║  □ Proper star schema design (10 pts)                                       ║
║  □ Appropriate SCD implementation (10 pts)                                  ║
║  □ Correct fact table grain (10 pts)                                        ║
║  □ Proper indexing strategy (10 pts)                                        ║
║                                                                              ║
║  SECTION 2: ETL PROCESSES (50 points)                                        ║
║  ─────────────────────────────────────                                       ║
║  □ Complete staging layer (10 pts)                                          ║
║  □ SCD Type 2 implementation (15 pts)                                       ║
║  □ Incremental loading (10 pts)                                             ║
║  □ Error handling and logging (10 pts)                                      ║
║  □ Transaction management (5 pts)                                           ║
║                                                                              ║
║  SECTION 3: DATA QUALITY (30 points)                                         ║
║  ─────────────────────────────────────                                       ║
║  □ Validation rules defined (10 pts)                                        ║
║  □ Quality metrics captured (10 pts)                                        ║
║  □ Error quarantine process (10 pts)                                        ║
║                                                                              ║
║  SECTION 4: OPERATIONS (30 points)                                           ║
║  ─────────────────────────────────────                                       ║
║  □ Execution logging (10 pts)                                               ║
║  □ Performance monitoring (10 pts)                                          ║
║  □ Recovery procedures (10 pts)                                             ║
║                                                                              ║
║  SECTION 5: DOCUMENTATION (25 points)                                        ║
║  ─────────────────────────────────────                                       ║
║  □ Data lineage tracking (10 pts)                                           ║
║  □ Process documentation (10 pts)                                           ║
║  □ Code comments (5 pts)                                                    ║
║                                                                              ║
║  BONUS (25 points)                                                           ║
║  ─────────────────────────────────────                                       ║
║  □ Metadata-driven design (10 pts)                                          ║
║  □ Parallel processing (10 pts)                                             ║
║  □ Advanced optimization (5 pts)                                            ║
║                                                                              ║
║  TOTAL: 200 points                                                           ║
║  Passing Score: 150 points (75%)                                            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
/*
-- Drop fact tables first (foreign keys)
DROP TABLE IF EXISTS fact.Sales;
DROP TABLE IF EXISTS fact.Inventory;

-- Drop dimension tables
DROP TABLE IF EXISTS dim.Customer;
DROP TABLE IF EXISTS dim.Product;
DROP TABLE IF EXISTS dim.Employee;
DROP TABLE IF EXISTS dim.Date;

-- Drop staging tables
DROP TABLE IF EXISTS staging.stg_Customer;
DROP TABLE IF EXISTS staging.stg_Product;
DROP TABLE IF EXISTS staging.stg_Sales;

-- Drop source tables
DROP TABLE IF EXISTS source_ecom.OrderItems;
DROP TABLE IF EXISTS source_ecom.Orders;
DROP TABLE IF EXISTS source_crm.Customers;
DROP TABLE IF EXISTS source_erp.Inventory;
DROP TABLE IF EXISTS source_erp.Employees;
DROP TABLE IF EXISTS source_erp.Products;

-- Drop ETL tables
DROP TABLE IF EXISTS etl.ExecutionLog;
DROP TABLE IF EXISTS etl.Watermark;
DROP TABLE IF EXISTS dq.ValidationResults;

-- Drop procedures
DROP PROCEDURE IF EXISTS etl.usp_LoadStaging_Customer;
DROP PROCEDURE IF EXISTS etl.usp_LoadStaging_Product;
DROP PROCEDURE IF EXISTS etl.usp_LoadStaging_Sales;
DROP PROCEDURE IF EXISTS etl.usp_LoadDim_Customer;
DROP PROCEDURE IF EXISTS etl.usp_LoadDim_Product;
DROP PROCEDURE IF EXISTS etl.usp_LoadFact_Sales;
DROP PROCEDURE IF EXISTS dq.usp_ValidateLoad;
DROP PROCEDURE IF EXISTS etl.usp_RunDailyLoad;

-- Drop schemas
DROP SCHEMA IF EXISTS source_erp;
DROP SCHEMA IF EXISTS source_crm;
DROP SCHEMA IF EXISTS source_ecom;
DROP SCHEMA IF EXISTS staging;
DROP SCHEMA IF EXISTS dim;
DROP SCHEMA IF EXISTS fact;
DROP SCHEMA IF EXISTS etl;
DROP SCHEMA IF EXISTS meta;
DROP SCHEMA IF EXISTS dq;
*/

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════════';
PRINT '  MODULE 07 CAPSTONE: ENTERPRISE DATA INTEGRATION PLATFORM - COMPLETE';
PRINT '═══════════════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '  Congratulations! You have built a complete ETL solution including:';
PRINT '  ✓ Multiple source system integration';
PRINT '  ✓ Staging layer with transformations';
PRINT '  ✓ SCD Type 1 and Type 2 dimensions';
PRINT '  ✓ Incremental fact table loading';
PRINT '  ✓ Data quality validation';
PRINT '  ✓ Error handling and logging';
PRINT '  ✓ Master orchestration';
PRINT '';
GO
