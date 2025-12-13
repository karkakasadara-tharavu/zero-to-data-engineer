/*******************************************************************************
 * LAB 77: SQL Capstone - Physical Database Implementation
 * Module 09: SQL Capstone Project
 * 
 * Objective: Implement the physical database design for GlobalMart including
 *            OLTP source system and Data Warehouse with all schemas.
 * 
 * Duration: 8-10 hours
 * 
 * Topics Covered:
 * - Physical database creation
 * - OLTP schema implementation
 * - Data warehouse schema implementation
 * - Sample data generation
 ******************************************************************************/

USE master;
GO

/*******************************************************************************
 * PART 1: CREATE OLTP DATABASE (SOURCE SYSTEM)
 ******************************************************************************/

-- Create OLTP Database
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GlobalMart_OLTP')
BEGIN
    ALTER DATABASE GlobalMart_OLTP SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GlobalMart_OLTP;
END
GO

CREATE DATABASE GlobalMart_OLTP;
GO

USE GlobalMart_OLTP;
GO

-- Create schemas
CREATE SCHEMA Sales AUTHORIZATION dbo;
GO
CREATE SCHEMA Inventory AUTHORIZATION dbo;
GO
CREATE SCHEMA HR AUTHORIZATION dbo;
GO
CREATE SCHEMA Products AUTHORIZATION dbo;
GO

/*******************************************************************************
 * PART 2: CREATE REFERENCE TABLES
 ******************************************************************************/

-- Regions
CREATE TABLE HR.Regions (
    RegionID INT IDENTITY(1,1) PRIMARY KEY,
    RegionName NVARCHAR(50) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL,
    TimeZone NVARCHAR(50) NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Countries
CREATE TABLE HR.Countries (
    CountryID INT IDENTITY(1,1) PRIMARY KEY,
    CountryCode CHAR(2) NOT NULL UNIQUE,
    CountryName NVARCHAR(100) NOT NULL,
    RegionID INT NOT NULL FOREIGN KEY REFERENCES HR.Regions(RegionID),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Stores
CREATE TABLE HR.Stores (
    StoreID INT IDENTITY(1,1) PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    StoreCode NVARCHAR(10) NOT NULL UNIQUE,
    CountryID INT NOT NULL FOREIGN KEY REFERENCES HR.Countries(CountryID),
    City NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    ManagerID INT NULL,
    OpenDate DATE NOT NULL,
    SquareFeet INT,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Employees
CREATE TABLE HR.Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    HireDate DATE NOT NULL,
    JobTitle NVARCHAR(50) NOT NULL,
    StoreID INT FOREIGN KEY REFERENCES HR.Stores(StoreID),
    ManagerID INT FOREIGN KEY REFERENCES HR.Employees(EmployeeID),
    Salary DECIMAL(10,2),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Update Stores with Manager FK
ALTER TABLE HR.Stores
ADD CONSTRAINT FK_Stores_Manager FOREIGN KEY (ManagerID) REFERENCES HR.Employees(EmployeeID);

/*******************************************************************************
 * PART 3: CREATE PRODUCT TABLES
 ******************************************************************************/

-- Categories
CREATE TABLE Products.Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL,
    ParentCategoryID INT FOREIGN KEY REFERENCES Products.Categories(CategoryID),
    Description NVARCHAR(200),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Suppliers
CREATE TABLE Products.Suppliers (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName NVARCHAR(100) NOT NULL,
    ContactName NVARCHAR(100),
    ContactEmail NVARCHAR(100),
    Phone NVARCHAR(20),
    Address NVARCHAR(200),
    City NVARCHAR(50),
    CountryID INT FOREIGN KEY REFERENCES HR.Countries(CountryID),
    PaymentTerms NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Brands
CREATE TABLE Products.Brands (
    BrandID INT IDENTITY(1,1) PRIMARY KEY,
    BrandName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Products
CREATE TABLE Products.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    ProductCode NVARCHAR(20) NOT NULL UNIQUE,
    CategoryID INT NOT NULL FOREIGN KEY REFERENCES Products.Categories(CategoryID),
    BrandID INT FOREIGN KEY REFERENCES Products.Brands(BrandID),
    SupplierID INT NOT NULL FOREIGN KEY REFERENCES Products.Suppliers(SupplierID),
    Description NVARCHAR(500),
    UnitPrice DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,
    Weight DECIMAL(8,2),
    Size NVARCHAR(20),
    Color NVARCHAR(30),
    ReorderLevel INT DEFAULT 10,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Price History
CREATE TABLE Products.PriceHistory (
    PriceHistoryID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products.Products(ProductID),
    OldPrice DECIMAL(10,2) NOT NULL,
    NewPrice DECIMAL(10,2) NOT NULL,
    EffectiveDate DATE NOT NULL,
    ChangedBy NVARCHAR(100),
    ChangeReason NVARCHAR(200),
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

/*******************************************************************************
 * PART 4: CREATE INVENTORY TABLES
 ******************************************************************************/

-- Store Inventory
CREATE TABLE Inventory.StoreInventory (
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    StoreID INT NOT NULL FOREIGN KEY REFERENCES HR.Stores(StoreID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products.Products(ProductID),
    QuantityOnHand INT NOT NULL DEFAULT 0,
    QuantityReserved INT NOT NULL DEFAULT 0,
    LastRestockDate DATE,
    LastCountDate DATE,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_StoreInventory UNIQUE (StoreID, ProductID)
);

-- Inventory Movements
CREATE TABLE Inventory.InventoryMovements (
    MovementID INT IDENTITY(1,1) PRIMARY KEY,
    StoreID INT NOT NULL FOREIGN KEY REFERENCES HR.Stores(StoreID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products.Products(ProductID),
    MovementType NVARCHAR(20) NOT NULL, -- 'IN', 'OUT', 'ADJUSTMENT', 'TRANSFER'
    Quantity INT NOT NULL,
    ReferenceType NVARCHAR(20), -- 'ORDER', 'PO', 'ADJUSTMENT'
    ReferenceID INT,
    Notes NVARCHAR(200),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy NVARCHAR(100)
);

/*******************************************************************************
 * PART 5: CREATE CUSTOMER TABLES
 ******************************************************************************/

-- Customer Segments
CREATE TABLE Sales.CustomerSegments (
    SegmentID INT IDENTITY(1,1) PRIMARY KEY,
    SegmentName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200),
    MinAnnualSpend DECIMAL(12,2),
    MaxAnnualSpend DECIMAL(12,2),
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

-- Customers
CREATE TABLE Sales.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    DateOfBirth DATE,
    Gender CHAR(1),
    Address NVARCHAR(200),
    City NVARCHAR(50),
    State NVARCHAR(50),
    PostalCode NVARCHAR(20),
    CountryID INT FOREIGN KEY REFERENCES HR.Countries(CountryID),
    SegmentID INT FOREIGN KEY REFERENCES Sales.CustomerSegments(SegmentID),
    JoinDate DATE NOT NULL DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

/*******************************************************************************
 * PART 6: CREATE SALES TABLES
 ******************************************************************************/

-- Promotions
CREATE TABLE Sales.Promotions (
    PromotionID INT IDENTITY(1,1) PRIMARY KEY,
    PromotionName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    DiscountType NVARCHAR(20) NOT NULL, -- 'PERCENT', 'AMOUNT', 'BOGO'
    DiscountValue DECIMAL(10,2) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    MinPurchaseAmount DECIMAL(10,2),
    MaxDiscountAmount DECIMAL(10,2),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Orders
CREATE TABLE Sales.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber NVARCHAR(20) NOT NULL UNIQUE,
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Sales.Customers(CustomerID),
    StoreID INT NOT NULL FOREIGN KEY REFERENCES HR.Stores(StoreID),
    EmployeeID INT FOREIGN KEY REFERENCES HR.Employees(EmployeeID),
    OrderDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    RequiredDate DATE,
    ShippedDate DATE,
    OrderStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    PaymentMethod NVARCHAR(20),
    ShippingMethod NVARCHAR(20),
    SubTotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    TaxAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    ShippingAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    TotalAmount DECIMAL(12,2) NOT NULL DEFAULT 0,
    Notes NVARCHAR(500),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Order Details
CREATE TABLE Sales.OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Sales.Orders(OrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products.Products(ProductID),
    PromotionID INT FOREIGN KEY REFERENCES Sales.Promotions(PromotionID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(10,2) NOT NULL DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice - Discount) PERSISTED,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

/*******************************************************************************
 * PART 7: CREATE INDEXES
 ******************************************************************************/

-- Customers indexes
CREATE INDEX IX_Customers_Email ON Sales.Customers(Email);
CREATE INDEX IX_Customers_City ON Sales.Customers(City);
CREATE INDEX IX_Customers_SegmentID ON Sales.Customers(SegmentID);

-- Orders indexes
CREATE INDEX IX_Orders_CustomerID ON Sales.Orders(CustomerID);
CREATE INDEX IX_Orders_StoreID ON Sales.Orders(StoreID);
CREATE INDEX IX_Orders_OrderDate ON Sales.Orders(OrderDate);
CREATE INDEX IX_Orders_Status ON Sales.Orders(OrderStatus);

-- OrderDetails indexes
CREATE INDEX IX_OrderDetails_OrderID ON Sales.OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON Sales.OrderDetails(ProductID);

-- Products indexes
CREATE INDEX IX_Products_CategoryID ON Products.Products(CategoryID);
CREATE INDEX IX_Products_SupplierID ON Products.Products(SupplierID);

-- Inventory indexes
CREATE INDEX IX_StoreInventory_ProductID ON Inventory.StoreInventory(ProductID);
CREATE INDEX IX_InventoryMovements_ProductID ON Inventory.InventoryMovements(ProductID);
CREATE INDEX IX_InventoryMovements_MovementDate ON Inventory.InventoryMovements(CreatedDate);

PRINT 'OLTP Database created successfully.';
GO

/*******************************************************************************
 * PART 8: CREATE DATA WAREHOUSE DATABASE
 ******************************************************************************/

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GlobalMart_DW')
BEGIN
    ALTER DATABASE GlobalMart_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GlobalMart_DW;
END
GO

CREATE DATABASE GlobalMart_DW;
GO

USE GlobalMart_DW;
GO

-- Create schemas
CREATE SCHEMA Staging AUTHORIZATION dbo;
GO
CREATE SCHEMA Dim AUTHORIZATION dbo;
GO
CREATE SCHEMA Fact AUTHORIZATION dbo;
GO
CREATE SCHEMA ETL AUTHORIZATION dbo;
GO
CREATE SCHEMA Reporting AUTHORIZATION dbo;
GO

/*******************************************************************************
 * PART 9: CREATE STAGING TABLES
 ******************************************************************************/

-- Staging tables mirror source structure for landing
CREATE TABLE Staging.Customers (
    CustomerID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    DateOfBirth DATE,
    Gender CHAR(1),
    Address NVARCHAR(200),
    City NVARCHAR(50),
    State NVARCHAR(50),
    PostalCode NVARCHAR(20),
    CountryName NVARCHAR(100),
    RegionName NVARCHAR(50),
    SegmentName NVARCHAR(50),
    JoinDate DATE,
    IsActive BIT,
    SourceModifiedDate DATETIME2,
    ETLLoadDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Staging.Products (
    ProductID INT,
    ProductName NVARCHAR(100),
    ProductCode NVARCHAR(20),
    CategoryName NVARCHAR(50),
    ParentCategoryName NVARCHAR(50),
    BrandName NVARCHAR(50),
    SupplierName NVARCHAR(100),
    UnitPrice DECIMAL(10,2),
    Cost DECIMAL(10,2),
    Weight DECIMAL(8,2),
    Size NVARCHAR(20),
    Color NVARCHAR(30),
    IsActive BIT,
    SourceModifiedDate DATETIME2,
    ETLLoadDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Staging.Orders (
    OrderID INT,
    OrderNumber NVARCHAR(20),
    CustomerID INT,
    StoreID INT,
    StoreName NVARCHAR(100),
    EmployeeID INT,
    EmployeeName NVARCHAR(100),
    OrderDate DATETIME2,
    OrderStatus NVARCHAR(20),
    PaymentMethod NVARCHAR(20),
    SubTotal DECIMAL(12,2),
    TaxAmount DECIMAL(10,2),
    ShippingAmount DECIMAL(10,2),
    DiscountAmount DECIMAL(10,2),
    TotalAmount DECIMAL(12,2),
    ETLLoadDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Staging.OrderDetails (
    OrderDetailID INT,
    OrderID INT,
    ProductID INT,
    PromotionID INT,
    PromotionName NVARCHAR(100),
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    Cost DECIMAL(10,2),
    Discount DECIMAL(10,2),
    LineTotal DECIMAL(12,2),
    ETLLoadDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Staging.Stores (
    StoreID INT,
    StoreName NVARCHAR(100),
    StoreCode NVARCHAR(10),
    CountryName NVARCHAR(100),
    RegionName NVARCHAR(50),
    City NVARCHAR(100),
    Address NVARCHAR(200),
    OpenDate DATE,
    SquareFeet INT,
    IsActive BIT,
    SourceModifiedDate DATETIME2,
    ETLLoadDate DATETIME2 DEFAULT GETDATE()
);

/*******************************************************************************
 * PART 10: CREATE DIMENSION TABLES
 ******************************************************************************/

-- DimDate
CREATE TABLE Dim.DimDate (
    DateKey INT NOT NULL PRIMARY KEY,
    [Date] DATE NOT NULL,
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Month] INT NOT NULL,
    [MonthName] NVARCHAR(20) NOT NULL,
    [Week] INT NOT NULL,
    [DayOfMonth] INT NOT NULL,
    [DayOfWeek] INT NOT NULL,
    [DayName] NVARCHAR(20) NOT NULL,
    [DayOfYear] INT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL DEFAULT 0,
    HolidayName NVARCHAR(50),
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL,
    FiscalMonth INT NOT NULL
);

-- DimCustomer (SCD Type 2)
CREATE TABLE Dim.DimCustomer (
    CustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID INT NOT NULL, -- Natural key
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    DateOfBirth DATE,
    Gender NVARCHAR(10),
    Address NVARCHAR(200),
    City NVARCHAR(50),
    State NVARCHAR(50),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100),
    Region NVARCHAR(50),
    Segment NVARCHAR(50),
    AgeGroup NVARCHAR(20),
    JoinDate DATE,
    TenureYears INT,
    IsActive BIT,
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent BIT NOT NULL DEFAULT 1,
    ETLLoadDate DATETIME2 DEFAULT GETDATE(),
    ETLUpdateDate DATETIME2
);

-- DimProduct (SCD Type 2)
CREATE TABLE Dim.DimProduct (
    ProductKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID INT NOT NULL, -- Natural key
    ProductName NVARCHAR(100) NOT NULL,
    ProductCode NVARCHAR(20),
    Category NVARCHAR(50),
    ParentCategory NVARCHAR(50),
    Brand NVARCHAR(50),
    Supplier NVARCHAR(100),
    UnitPrice DECIMAL(10,2),
    Cost DECIMAL(10,2),
    ProfitMargin AS CASE WHEN UnitPrice > 0 THEN (UnitPrice - Cost) / UnitPrice * 100 ELSE 0 END PERSISTED,
    Weight DECIMAL(8,2),
    Size NVARCHAR(20),
    Color NVARCHAR(30),
    PriceRange NVARCHAR(20),
    IsActive BIT,
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent BIT NOT NULL DEFAULT 1,
    ETLLoadDate DATETIME2 DEFAULT GETDATE(),
    ETLUpdateDate DATETIME2
);

-- DimStore (SCD Type 2)
CREATE TABLE Dim.DimStore (
    StoreKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StoreID INT NOT NULL, -- Natural key
    StoreName NVARCHAR(100) NOT NULL,
    StoreCode NVARCHAR(10),
    Country NVARCHAR(100),
    Region NVARCHAR(50),
    City NVARCHAR(100),
    Address NVARCHAR(200),
    OpenDate DATE,
    SquareFeet INT,
    StoreSize NVARCHAR(20), -- Small, Medium, Large
    StoreAge INT,
    IsActive BIT,
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent BIT NOT NULL DEFAULT 1,
    ETLLoadDate DATETIME2 DEFAULT GETDATE(),
    ETLUpdateDate DATETIME2
);

-- DimPromotion
CREATE TABLE Dim.DimPromotion (
    PromotionKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PromotionID INT, -- Natural key (nullable for "No Promotion")
    PromotionName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    DiscountType NVARCHAR(20),
    DiscountValue DECIMAL(10,2),
    StartDate DATE,
    EndDate DATE,
    IsActive BIT,
    ETLLoadDate DATETIME2 DEFAULT GETDATE()
);

-- DimEmployee
CREATE TABLE Dim.DimEmployee (
    EmployeeKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EmployeeID INT, -- Natural key
    EmployeeName NVARCHAR(100) NOT NULL,
    JobTitle NVARCHAR(50),
    StoreKey INT,
    HireDate DATE,
    TenureYears INT,
    IsActive BIT,
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent BIT NOT NULL DEFAULT 1,
    ETLLoadDate DATETIME2 DEFAULT GETDATE()
);

/*******************************************************************************
 * PART 11: CREATE FACT TABLES
 ******************************************************************************/

-- FactSales
CREATE TABLE Fact.FactSales (
    SalesKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    PromotionKey INT NOT NULL,
    EmployeeKey INT,
    OrderID INT NOT NULL, -- Degenerate dimension
    OrderNumber NVARCHAR(20) NOT NULL, -- Degenerate dimension
    LineNumber INT NOT NULL, -- Degenerate dimension
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,
    SalesAmount DECIMAL(12,2) NOT NULL,
    CostAmount DECIMAL(12,2) NOT NULL,
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    Profit DECIMAL(12,2) NOT NULL,
    TaxAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    ETLLoadDate DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign keys
    CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateKey) REFERENCES Dim.DimDate(DateKey),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES Dim.DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES Dim.DimProduct(ProductKey),
    CONSTRAINT FK_FactSales_DimStore FOREIGN KEY (StoreKey) REFERENCES Dim.DimStore(StoreKey),
    CONSTRAINT FK_FactSales_DimPromotion FOREIGN KEY (PromotionKey) REFERENCES Dim.DimPromotion(PromotionKey)
);

-- FactInventory (Periodic snapshot)
CREATE TABLE Fact.FactInventory (
    InventoryKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    QuantityOnHand INT NOT NULL,
    QuantityReserved INT NOT NULL DEFAULT 0,
    QuantityAvailable AS (QuantityOnHand - QuantityReserved) PERSISTED,
    InventoryValue DECIMAL(12,2) NOT NULL,
    DaysOfSupply INT,
    IsOutOfStock BIT,
    IsBelowReorderLevel BIT,
    ETLLoadDate DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT FK_FactInventory_DimDate FOREIGN KEY (DateKey) REFERENCES Dim.DimDate(DateKey),
    CONSTRAINT FK_FactInventory_DimProduct FOREIGN KEY (ProductKey) REFERENCES Dim.DimProduct(ProductKey),
    CONSTRAINT FK_FactInventory_DimStore FOREIGN KEY (StoreKey) REFERENCES Dim.DimStore(StoreKey)
);

/*******************************************************************************
 * PART 12: CREATE DATA WAREHOUSE INDEXES
 ******************************************************************************/

-- FactSales indexes
CREATE INDEX IX_FactSales_DateKey ON Fact.FactSales(DateKey);
CREATE INDEX IX_FactSales_CustomerKey ON Fact.FactSales(CustomerKey);
CREATE INDEX IX_FactSales_ProductKey ON Fact.FactSales(ProductKey);
CREATE INDEX IX_FactSales_StoreKey ON Fact.FactSales(StoreKey);
CREATE INDEX IX_FactSales_OrderID ON Fact.FactSales(OrderID);

-- FactInventory indexes
CREATE INDEX IX_FactInventory_DateKey ON Fact.FactInventory(DateKey);
CREATE INDEX IX_FactInventory_ProductKey ON Fact.FactInventory(ProductKey);
CREATE INDEX IX_FactInventory_StoreKey ON Fact.FactInventory(StoreKey);

-- Dimension indexes
CREATE INDEX IX_DimCustomer_CustomerID ON Dim.DimCustomer(CustomerID);
CREATE INDEX IX_DimCustomer_IsCurrent ON Dim.DimCustomer(IsCurrent);
CREATE INDEX IX_DimProduct_ProductID ON Dim.DimProduct(ProductID);
CREATE INDEX IX_DimProduct_IsCurrent ON Dim.DimProduct(IsCurrent);
CREATE INDEX IX_DimStore_StoreID ON Dim.DimStore(StoreID);
CREATE INDEX IX_DimStore_IsCurrent ON Dim.DimStore(IsCurrent);

/*******************************************************************************
 * PART 13: CREATE ETL METADATA TABLES
 ******************************************************************************/

-- ETL Execution Log
CREATE TABLE ETL.ExecutionLog (
    ExecutionID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(100) NOT NULL,
    ExecutionStartTime DATETIME2 NOT NULL,
    ExecutionEndTime DATETIME2,
    Status NVARCHAR(20) NOT NULL, -- 'Running', 'Success', 'Failed'
    RowsExtracted INT DEFAULT 0,
    RowsInserted INT DEFAULT 0,
    RowsUpdated INT DEFAULT 0,
    RowsRejected INT DEFAULT 0,
    ErrorMessage NVARCHAR(MAX),
    MachineName NVARCHAR(100)
);

-- High Water Mark for incremental loads
CREATE TABLE ETL.HighWaterMark (
    TableName NVARCHAR(100) PRIMARY KEY,
    LastLoadDate DATETIME2 NOT NULL,
    LastLoadedKey INT,
    Notes NVARCHAR(200),
    UpdatedDate DATETIME2 DEFAULT GETDATE()
);

-- Error Log
CREATE TABLE ETL.ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID INT FOREIGN KEY REFERENCES ETL.ExecutionLog(ExecutionID),
    SourceTable NVARCHAR(100),
    SourceKey NVARCHAR(100),
    ErrorCode INT,
    ErrorMessage NVARCHAR(MAX),
    ErrorData NVARCHAR(MAX),
    ErrorDate DATETIME2 DEFAULT GETDATE()
);

/*******************************************************************************
 * PART 14: POPULATE DATE DIMENSION
 ******************************************************************************/

-- Generate DimDate for 10 years
DECLARE @StartDate DATE = '2015-01-01';
DECLARE @EndDate DATE = '2030-12-31';
DECLARE @Date DATE = @StartDate;

WHILE @Date <= @EndDate
BEGIN
    INSERT INTO Dim.DimDate (
        DateKey, [Date], [Year], [Quarter], [Month], [MonthName],
        [Week], [DayOfMonth], [DayOfWeek], [DayName], [DayOfYear],
        IsWeekend, FiscalYear, FiscalQuarter, FiscalMonth
    )
    VALUES (
        CONVERT(INT, CONVERT(VARCHAR(8), @Date, 112)),  -- DateKey as YYYYMMDD
        @Date,
        YEAR(@Date),
        DATEPART(QUARTER, @Date),
        MONTH(@Date),
        DATENAME(MONTH, @Date),
        DATEPART(WEEK, @Date),
        DAY(@Date),
        DATEPART(WEEKDAY, @Date),
        DATENAME(WEEKDAY, @Date),
        DATEPART(DAYOFYEAR, @Date),
        CASE WHEN DATEPART(WEEKDAY, @Date) IN (1, 7) THEN 1 ELSE 0 END,
        CASE WHEN MONTH(@Date) >= 7 THEN YEAR(@Date) + 1 ELSE YEAR(@Date) END, -- FY starts July
        CASE 
            WHEN MONTH(@Date) IN (7,8,9) THEN 1
            WHEN MONTH(@Date) IN (10,11,12) THEN 2
            WHEN MONTH(@Date) IN (1,2,3) THEN 3
            ELSE 4
        END,
        CASE 
            WHEN MONTH(@Date) >= 7 THEN MONTH(@Date) - 6
            ELSE MONTH(@Date) + 6
        END
    );
    
    SET @Date = DATEADD(DAY, 1, @Date);
END;

-- Insert Unknown member for dimensions
INSERT INTO Dim.DimPromotion (PromotionID, PromotionName, Description, DiscountType, DiscountValue)
VALUES (0, 'No Promotion', 'No promotion applied', 'NONE', 0);

INSERT INTO Dim.DimCustomer (CustomerID, CustomerName, Email, City, Country, Region, Segment, JoinDate, IsActive, EffectiveDate)
VALUES (0, 'Unknown Customer', 'unknown@unknown.com', 'Unknown', 'Unknown', 'Unknown', 'Unknown', '1900-01-01', 0, '1900-01-01');

INSERT INTO Dim.DimProduct (ProductID, ProductName, ProductCode, Category, Brand, UnitPrice, Cost, IsActive, EffectiveDate)
VALUES (0, 'Unknown Product', 'UNK000', 'Unknown', 'Unknown', 0, 0, 0, '1900-01-01');

INSERT INTO Dim.DimStore (StoreID, StoreName, StoreCode, Country, Region, City, IsActive, EffectiveDate)
VALUES (0, 'Unknown Store', 'UNK', 'Unknown', 'Unknown', 'Unknown', 0, '1900-01-01');

PRINT 'Data Warehouse created successfully with date dimension populated.';
GO

/*******************************************************************************
 * PART 15: VERIFICATION QUERIES
 ******************************************************************************/

USE GlobalMart_OLTP;

-- Verify OLTP tables
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

USE GlobalMart_DW;

-- Verify DW tables
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- Verify date dimension
SELECT 
    MIN([Date]) AS StartDate,
    MAX([Date]) AS EndDate,
    COUNT(*) AS TotalDays
FROM Dim.DimDate;

PRINT '
=============================================================================
LAB 77 COMPLETE
=============================================================================

Databases created:
1. GlobalMart_OLTP - Transactional source system
2. GlobalMart_DW - Data Warehouse

Next Steps:
- Lab 78: Generate sample data for OLTP system
- Lab 79-80: Implement ETL packages
- Lab 81-82: Create reporting views
- Lab 83: Power BI reports
';
GO
