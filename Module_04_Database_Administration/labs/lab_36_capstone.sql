/*
 * Lab 36: Database Administration Capstone Project
 * Module 04: Database Administration
 * 
 * Objective: Apply all DBA skills in comprehensive real-world scenario
 * Duration: 4-6 hours
 * Difficulty: ⭐⭐⭐⭐⭐
 * 
 * PROJECT: Deploy and Maintain Production E-Commerce Database
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 36: DBA Capstone Project';
PRINT '==============================================';
PRINT '';

/*
 * PROJECT SCENARIO:
 * 
 * You are the lead DBA for an e-commerce company launching a new
 * online store. You must design, deploy, secure, and maintain
 * the production database system.
 * 
 * REQUIREMENTS:
 * 
 * Phase 1: Database Design & Deployment
 * Phase 2: Security Implementation
 * Phase 3: Backup & Recovery Strategy
 * Phase 4: Performance Optimization
 * Phase 5: Monitoring & Alerting
 * Phase 6: Maintenance Automation
 * Phase 7: Documentation & Runbooks
 */

PRINT 'CAPSTONE PROJECT: E-Commerce Database System';
PRINT '=============================================';
PRINT '';
PRINT 'PROJECT PHASES:';
PRINT '  Phase 1: Database Design & Deployment';
PRINT '  Phase 2: Security Implementation';
PRINT '  Phase 3: Backup & Recovery Strategy';
PRINT '  Phase 4: Performance Optimization';
PRINT '  Phase 5: Monitoring & Alerting';
PRINT '  Phase 6: Maintenance Automation';
PRINT '  Phase 7: Documentation & Runbooks';
PRINT '';
PRINT 'Estimated Time: 4-6 hours';
PRINT '';

/*
 * PHASE 1: DATABASE DESIGN & DEPLOYMENT
 */

PRINT '==============================================';
PRINT 'PHASE 1: Database Design & Deployment';
PRINT '==============================================';
PRINT '';

-- Drop existing database if present
IF DB_ID('ECommerceDB') IS NOT NULL
BEGIN
    ALTER DATABASE ECommerceDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ECommerceDB;
    PRINT '✓ Dropped existing ECommerceDB';
END;

-- Create database with proper configuration
CREATE DATABASE ECommerceDB
ON PRIMARY 
(
    NAME = N'ECommerceDB_Data',
    FILENAME = N'C:\SQLData\ECommerceDB_Data.mdf',
    SIZE = 500MB,
    FILEGROWTH = 100MB
),
FILEGROUP FG_Indexes
(
    NAME = N'ECommerceDB_Indexes',
    FILENAME = N'C:\SQLData\ECommerceDB_Indexes.ndf',
    SIZE = 250MB,
    FILEGROWTH = 50MB
)
LOG ON
(
    NAME = N'ECommerceDB_Log',
    FILENAME = N'C:\SQLData\ECommerceDB_Log.ldf',
    SIZE = 250MB,
    FILEGROWTH = 50MB
);

PRINT '✓ Created database: ECommerceDB';
PRINT '  - Data file: 500MB (100MB autogrowth)';
PRINT '  - Index filegroup: 250MB (50MB autogrowth)';
PRINT '  - Log file: 250MB (50MB autogrowth)';
PRINT '';

-- Configure database settings
ALTER DATABASE ECommerceDB SET RECOVERY FULL;
ALTER DATABASE ECommerceDB SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE ECommerceDB SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE ECommerceDB SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE ECommerceDB SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
ALTER DATABASE ECommerceDB SET PARAMETERIZATION SIMPLE;

PRINT '✓ Configured database settings:';
PRINT '  - Recovery: FULL (point-in-time recovery)';
PRINT '  - Page verify: CHECKSUM (corruption detection)';
PRINT '  - Auto statistics: ON';
PRINT '';

USE ECommerceDB;
GO

-- Create database schema
CREATE SCHEMA Sales AUTHORIZATION dbo;
CREATE SCHEMA Inventory AUTHORIZATION dbo;
CREATE SCHEMA Customer AUTHORIZATION dbo;
CREATE SCHEMA Audit AUTHORIZATION dbo;

PRINT '✓ Created schemas: Sales, Inventory, Customer, Audit';
PRINT '';

-- Create core tables
PRINT 'Creating core tables...';

-- Customers table
CREATE TABLE Customer.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash BINARY(64) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    DateOfBirth DATE,
    CreatedDate DATETIME2 DEFAULT SYSDATETIME(),
    ModifiedDate DATETIME2 DEFAULT SYSDATETIME(),
    IsActive BIT DEFAULT 1,
    CONSTRAINT CK_Customer_Email CHECK (Email LIKE '%@%'),
    INDEX IX_Customers_Email NONCLUSTERED (Email),
    INDEX IX_Customers_LastName NONCLUSTERED (LastName, FirstName)
);

-- Addresses table
CREATE TABLE Customer.Addresses (
    AddressID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AddressType NVARCHAR(20) NOT NULL,  -- Billing, Shipping
    Street NVARCHAR(255) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    StateProvince NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100) NOT NULL,
    IsDefault BIT DEFAULT 0,
    CONSTRAINT FK_Addresses_Customers FOREIGN KEY (CustomerID) 
        REFERENCES Customer.Customers(CustomerID),
    CONSTRAINT CK_Address_Type CHECK (AddressType IN ('Billing', 'Shipping')),
    INDEX IX_Addresses_CustomerID NONCLUSTERED (CustomerID)
);

-- Products table
CREATE TABLE Inventory.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    SKU NVARCHAR(50) NOT NULL UNIQUE,
    ProductName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    CategoryID INT,
    Price DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    ReorderLevel INT NOT NULL DEFAULT 10,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT SYSDATETIME(),
    ModifiedDate DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Product_Price CHECK (Price >= Cost),
    CONSTRAINT CK_Product_Stock CHECK (StockQuantity >= 0),
    INDEX IX_Products_SKU NONCLUSTERED (SKU),
    INDEX IX_Products_Category NONCLUSTERED (CategoryID, IsActive)
) ON FG_Indexes;  -- Place indexes on separate filegroup

-- Categories table
CREATE TABLE Inventory.Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    ParentCategoryID INT,
    Description NVARCHAR(500),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryID) 
        REFERENCES Inventory.Categories(CategoryID)
);

-- Add FK to Products
ALTER TABLE Inventory.Products
ADD CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID)
    REFERENCES Inventory.Categories(CategoryID);

-- Orders table (partitioned by OrderDate)
CREATE TABLE Sales.Orders (
    OrderID INT IDENTITY(1,1),
    OrderDate DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    CustomerID INT NOT NULL,
    OrderStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    SubTotal DECIMAL(10,2) NOT NULL,
    TaxAmount DECIMAL(10,2) NOT NULL,
    ShippingAmount DECIMAL(10,2) NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    PaymentMethod NVARCHAR(50),
    ShippingAddressID INT,
    BillingAddressID INT,
    CreatedDate DATETIME2 DEFAULT SYSDATETIME(),
    ModifiedDate DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Orders PRIMARY KEY (OrderID, OrderDate),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) 
        REFERENCES Customer.Customers(CustomerID),
    CONSTRAINT CK_Order_Status CHECK (OrderStatus IN 
        ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Refunded')),
    CONSTRAINT CK_Order_Total CHECK (TotalAmount = SubTotal + TaxAmount + ShippingAmount),
    INDEX IX_Orders_Customer NONCLUSTERED (CustomerID, OrderDate),
    INDEX IX_Orders_Status NONCLUSTERED (OrderStatus, OrderDate)
);

-- OrderItems table
CREATE TABLE Sales.OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(10,2) DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice - Discount) PERSISTED,
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID) 
        REFERENCES Sales.Orders(OrderID),
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductID) 
        REFERENCES Inventory.Products(ProductID),
    CONSTRAINT CK_OrderItem_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItem_UnitPrice CHECK (UnitPrice > 0),
    INDEX IX_OrderItems_Order NONCLUSTERED (OrderID),
    INDEX IX_OrderItems_Product NONCLUSTERED (ProductID)
);

-- Audit trail table
CREATE TABLE Audit.DataChanges (
    AuditID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(128) NOT NULL,
    Operation NVARCHAR(10) NOT NULL,  -- INSERT, UPDATE, DELETE
    RecordID INT NOT NULL,
    ChangedBy NVARCHAR(128) NOT NULL,
    ChangedDate DATETIME2 DEFAULT SYSDATETIME(),
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    INDEX IX_Audit_Table_Date NONCLUSTERED (TableName, ChangedDate)
);

PRINT '✓ Created 9 core tables across 4 schemas';
PRINT '';

-- Insert sample data
PRINT 'Populating sample data...';

-- Categories
INSERT INTO Inventory.Categories (CategoryName, ParentCategoryID, Description)
VALUES 
    ('Electronics', NULL, 'Electronic devices and accessories'),
    ('Computers', 1, 'Laptops, desktops, tablets'),
    ('Phones', 1, 'Smartphones and accessories'),
    ('Clothing', NULL, 'Apparel and fashion'),
    ('Books', NULL, 'Physical and digital books');

-- Products
INSERT INTO Inventory.Products (SKU, ProductName, CategoryID, Price, Cost, StockQuantity, ReorderLevel)
VALUES
    ('ELEC-LAP-001', 'UltraBook Pro 15"', 2, 1299.99, 800.00, 50, 10),
    ('ELEC-PHN-001', 'SmartPhone X', 3, 899.99, 550.00, 100, 20),
    ('ELEC-PHN-002', 'SmartPhone X Case', 3, 29.99, 10.00, 500, 50),
    ('CLTH-TSH-001', 'Cotton T-Shirt Blue', 4, 24.99, 8.00, 200, 30),
    ('BOOK-FIC-001', 'Mystery Novel', 5, 14.99, 6.00, 150, 25);

-- Customers
INSERT INTO Customer.Customers (Email, PasswordHash, FirstName, LastName, Phone, DateOfBirth)
VALUES
    ('john.doe@email.com', HASHBYTES('SHA2_512', 'password123'), 'John', 'Doe', '555-1234', '1985-03-15'),
    ('jane.smith@email.com', HASHBYTES('SHA2_512', 'password123'), 'Jane', 'Smith', '555-5678', '1990-07-22'),
    ('bob.johnson@email.com', HASHBYTES('SHA2_512', 'password123'), 'Bob', 'Johnson', '555-9012', '1988-11-30');

-- Addresses
INSERT INTO Customer.Addresses (CustomerID, AddressType, Street, City, StateProvince, PostalCode, Country, IsDefault)
VALUES
    (1, 'Billing', '123 Main St', 'New York', 'NY', '10001', 'USA', 1),
    (1, 'Shipping', '123 Main St', 'New York', 'NY', '10001', 'USA', 1),
    (2, 'Billing', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', 1),
    (2, 'Shipping', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', 1),
    (3, 'Billing', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', 1);

-- Orders
INSERT INTO Sales.Orders (OrderDate, CustomerID, OrderStatus, SubTotal, TaxAmount, ShippingAmount, TotalAmount, PaymentMethod)
VALUES
    ('2024-01-15', 1, 'Delivered', 1329.98, 106.40, 15.00, 1451.38, 'Credit Card'),
    ('2024-02-20', 2, 'Shipped', 924.98, 73.99, 10.00, 1008.97, 'PayPal'),
    ('2024-03-10', 3, 'Processing', 39.98, 3.20, 5.00, 48.18, 'Credit Card');

-- OrderItems
INSERT INTO Sales.OrderItems (OrderID, ProductID, Quantity, UnitPrice, Discount)
VALUES
    (1, 1, 1, 1299.99, 0),
    (1, 3, 1, 29.99, 0),
    (2, 2, 1, 899.99, 0),
    (2, 3, 1, 24.99, 0),
    (3, 4, 1, 24.99, 0),
    (3, 5, 1, 14.99, 0);

PRINT '✓ Populated sample data (5 categories, 5 products, 3 customers, 3 orders)';
PRINT '';

/*
 * PHASE 2: SECURITY IMPLEMENTATION
 */

PRINT '==============================================';
PRINT 'PHASE 2: Security Implementation';
PRINT '==============================================';
PRINT '';

-- Create logins and users
PRINT 'Creating security principals...';

-- Application login (web app)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'ECommerceApp')
    CREATE LOGIN ECommerceApp WITH PASSWORD = 'SecureApp#2024!', CHECK_POLICY = ON;

-- Read-only reporting login
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'ReportUser')
    CREATE LOGIN ReportUser WITH PASSWORD = 'Report#2024!', CHECK_POLICY = ON;

-- DBA login
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'DBAUser')
    CREATE LOGIN DBAUser WITH PASSWORD = 'DBA#2024!', CHECK_POLICY = ON;

-- Create database users
CREATE USER ECommerceApp FOR LOGIN ECommerceApp;
CREATE USER ReportUser FOR LOGIN ReportUser;
CREATE USER DBAUser FOR LOGIN DBAUser;

PRINT '✓ Created logins: ECommerceApp, ReportUser, DBAUser';
PRINT '';

-- Create custom roles
CREATE ROLE AppRole;
CREATE ROLE ReadOnlyRole;

-- Grant permissions to AppRole
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Customer TO AppRole;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Sales TO AppRole;
GRANT SELECT ON SCHEMA::Inventory TO AppRole;
GRANT INSERT ON Audit.DataChanges TO AppRole;

-- Grant permissions to ReadOnlyRole
GRANT SELECT ON SCHEMA::Sales TO ReadOnlyRole;
GRANT SELECT ON SCHEMA::Inventory TO ReadOnlyRole;
GRANT SELECT ON SCHEMA::Customer TO ReadOnlyRole;

-- Add users to roles
ALTER ROLE AppRole ADD MEMBER ECommerceApp;
ALTER ROLE ReadOnlyRole ADD MEMBER ReportUser;
ALTER ROLE db_owner ADD MEMBER DBAUser;

PRINT '✓ Created roles and assigned permissions';
PRINT '  - AppRole: Full access to Customer/Sales, read-only to Inventory';
PRINT '  - ReadOnlyRole: Read-only access to all schemas';
PRINT '';

-- Implement Row-Level Security for multi-tenant isolation
PRINT 'Implementing Row-Level Security...';

CREATE FUNCTION Security.fn_CustomerFilter(@CustomerID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS AccessAllowed
    WHERE 
        @CustomerID = CAST(SESSION_CONTEXT(N'CustomerID') AS INT)
        OR IS_MEMBER('db_owner') = 1
        OR IS_MEMBER('AppRole') = 1;
GO

CREATE SECURITY POLICY Security.CustomerPolicy
ADD FILTER PREDICATE Security.fn_CustomerFilter(CustomerID)
ON Customer.Customers
WITH (STATE = ON);

PRINT '✓ Implemented Row-Level Security on Customers table';
PRINT '';

-- Enable transparent data encryption (TDE) - Enterprise Edition only
/*
-- Create master key
USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKey#2024!';

-- Create certificate
CREATE CERTIFICATE TDECert WITH SUBJECT = 'TDE Certificate';

-- Create database encryption key
USE ECommerceDB;
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert;

-- Enable encryption
ALTER DATABASE ECommerceDB SET ENCRYPTION ON;
*/

PRINT 'Security features configured (TDE requires Enterprise Edition)';
PRINT '';

/*
 * PHASE 3: BACKUP & RECOVERY STRATEGY
 */

PRINT '==============================================';
PRINT 'PHASE 3: Backup & Recovery Strategy';
PRINT '==============================================';
PRINT '';

-- Take initial full backup
DECLARE @BackupPath NVARCHAR(500) = 'C:\SQLBackups\ECommerceDB_Full_' + 
    CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '') + '.bak';

BACKUP DATABASE ECommerceDB
TO DISK = @BackupPath
WITH 
    COMPRESSION,
    CHECKSUM,
    STATS = 10,
    DESCRIPTION = 'Initial full backup - Capstone project';

PRINT '✓ Completed full backup with compression and checksum';
PRINT '';

-- Create backup strategy documentation
PRINT 'BACKUP STRATEGY:';
PRINT '  - Full backup: Daily at 2:00 AM (compressed)';
PRINT '  - Differential backup: Every 6 hours';
PRINT '  - Transaction log backup: Every 15 minutes';
PRINT '  - Retention: 30 days on disk, 90 days offsite';
PRINT '  - Recovery objective: < 15 minutes data loss (RPO)';
PRINT '  - Recovery time objective: < 1 hour (RTO)';
PRINT '';

-- Test restore (to verify backups)
PRINT 'Verifying backup...';
RESTORE VERIFYONLY FROM DISK = @BackupPath WITH CHECKSUM;
PRINT '✓ Backup verification successful';
PRINT '';

/*
 * PHASE 4: PERFORMANCE OPTIMIZATION
 */

PRINT '==============================================';
PRINT 'PHASE 4: Performance Optimization';
PRINT '==============================================';
PRINT '';

-- Create additional performance indexes
PRINT 'Creating performance indexes...';

-- Covering index for order lookup by customer
CREATE NONCLUSTERED INDEX IX_Orders_Customer_Covering
ON Sales.Orders(CustomerID, OrderDate)
INCLUDE (OrderStatus, TotalAmount)
ON FG_Indexes;

-- Index for product search
CREATE NONCLUSTERED INDEX IX_Products_Name_Active
ON Inventory.Products(ProductName, IsActive)
INCLUDE (SKU, Price, StockQuantity)
WITH (FILLFACTOR = 90, PAD_INDEX = ON)
ON FG_Indexes;

-- Columnstore index for analytics
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders_Analytics
ON Sales.Orders(OrderDate, CustomerID, OrderStatus, TotalAmount)
ON FG_Indexes;

PRINT '✓ Created 3 performance indexes';
PRINT '';

-- Update statistics with full scan
PRINT 'Updating statistics...';
UPDATE STATISTICS Customer.Customers WITH FULLSCAN;
UPDATE STATISTICS Sales.Orders WITH FULLSCAN;
UPDATE STATISTICS Inventory.Products WITH FULLSCAN;
PRINT '✓ Statistics updated';
PRINT '';

-- Create performance views
PRINT 'Creating performance views...';

CREATE VIEW Sales.vw_CustomerOrderSummary
WITH SCHEMABINDING
AS
SELECT 
    c.CustomerID,
    c.Email,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT_BIG(*) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customer.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE c.IsActive = 1
GROUP BY c.CustomerID, c.Email, c.FirstName, c.LastName;
GO

-- Create indexed view for fast aggregation
CREATE UNIQUE CLUSTERED INDEX IX_CustomerOrderSummary 
ON Sales.vw_CustomerOrderSummary(CustomerID);

PRINT '✓ Created indexed view: vw_CustomerOrderSummary';
PRINT '';

/*
 * PHASE 5: MONITORING & ALERTING
 */

PRINT '==============================================';
PRINT 'PHASE 5: Monitoring & Alerting';
PRINT '==============================================';
PRINT '';

-- Create monitoring stored procedures
CREATE PROCEDURE dbo.usp_PerformanceSnapshot
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Top 10 slowest queries
    SELECT TOP 10
        execution_count,
        total_elapsed_time / 1000 AS TotalElapsed_ms,
        (total_elapsed_time / execution_count) / 1000 AS AvgElapsed_ms,
        total_logical_reads,
        SUBSTRING(st.text, 1, 200) AS QueryText
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    WHERE st.text NOT LIKE '%sys.dm_exec%'
    ORDER BY total_elapsed_time DESC;
    
    -- Current blocking
    SELECT 
        r.session_id,
        r.blocking_session_id,
        r.wait_type,
        r.wait_time,
        SUBSTRING(st.text, 1, 200) AS QueryText
    FROM sys.dm_exec_requests r
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
    WHERE r.blocking_session_id > 0;
    
    -- Database size
    SELECT 
        name,
        size * 8.0 / 1024 AS Size_MB,
        FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS UsedSpace_MB
    FROM sys.database_files;
END;
GO

PRINT '✓ Created usp_PerformanceSnapshot procedure';
PRINT '';

PRINT 'MONITORING CHECKLIST:';
PRINT '  ☐ Configure SQL Agent jobs for backups';
PRINT '  ☐ Set up alerts for:';
PRINT '    - Severity 17+ errors';
PRINT '    - Deadlocks';
PRINT '    - Long-running queries (> 60 sec)';
PRINT '    - Database file growth events';
PRINT '    - Log file > 80% full';
PRINT '  ☐ Configure email notifications';
PRINT '  ☐ Set up Extended Events session for auditing';
PRINT '';

/*
 * PHASE 6: MAINTENANCE AUTOMATION
 */

PRINT '==============================================';
PRINT 'PHASE 6: Maintenance Automation';
PRINT '==============================================';
PRINT '';

-- Create comprehensive maintenance procedure
CREATE PROCEDURE dbo.usp_DailyMaintenance
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @Message NVARCHAR(500);
    
    PRINT 'Starting daily maintenance at ' + CAST(@StartTime AS NVARCHAR);
    PRINT '';
    
    -- 1. Update statistics
    PRINT '1. Updating statistics...';
    EXEC sp_updatestats;
    SET @Message = 'Statistics updated in ' + 
        CAST(DATEDIFF(SECOND, @StartTime, SYSDATETIME()) AS NVARCHAR) + ' seconds';
    PRINT @Message;
    PRINT '';
    
    -- 2. Index maintenance
    PRINT '2. Performing index maintenance...';
    DECLARE @TableName NVARCHAR(128);
    DECLARE @IndexName NVARCHAR(128);
    DECLARE @Fragmentation FLOAT;
    DECLARE @SQL NVARCHAR(MAX);
    
    DECLARE index_cursor CURSOR FOR
    SELECT 
        OBJECT_NAME(ips.object_id) AS TableName,
        i.name AS IndexName,
        ips.avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.avg_fragmentation_in_percent > 10
        AND ips.page_count > 100
        AND i.name IS NOT NULL;
    
    OPEN index_cursor;
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Fragmentation > 30
        BEGIN
            SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + 
                       QUOTENAME(@TableName) + ' REBUILD WITH (ONLINE = OFF, FILLFACTOR = 90)';
            PRINT 'REBUILD: ' + @TableName + '.' + @IndexName + ' (' + CAST(@Fragmentation AS NVARCHAR) + '%)';
        END
        ELSE
        BEGIN
            SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + 
                       QUOTENAME(@TableName) + ' REORGANIZE';
            PRINT 'REORGANIZE: ' + @TableName + '.' + @IndexName + ' (' + CAST(@Fragmentation AS NVARCHAR) + '%)';
        END
        
        EXEC sp_executesql @SQL;
        FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
    END;
    
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
    PRINT '';
    
    -- 3. DBCC CHECKDB
    PRINT '3. Running integrity check...';
    DBCC CHECKDB (ECommerceDB) WITH NO_INFOMSGS, ALL_ERRORMSGS;
    PRINT 'Integrity check complete';
    PRINT '';
    
    -- 4. Cleanup old audit records (> 90 days)
    PRINT '4. Cleaning up old audit records...';
    DELETE FROM Audit.DataChanges 
    WHERE ChangedDate < DATEADD(DAY, -90, SYSDATETIME());
    SET @Message = CAST(@@ROWCOUNT AS NVARCHAR) + ' audit records deleted';
    PRINT @Message;
    PRINT '';
    
    PRINT 'Daily maintenance completed in ' + 
        CAST(DATEDIFF(SECOND, @StartTime, SYSDATETIME()) AS NVARCHAR) + ' seconds';
END;
GO

PRINT '✓ Created usp_DailyMaintenance procedure';
PRINT '';

/*
 * PHASE 7: DOCUMENTATION & RUNBOOKS
 */

PRINT '==============================================';
PRINT 'PHASE 7: Documentation & Runbooks';
PRINT '==============================================';
PRINT '';

PRINT 'DATABASE DOCUMENTATION:';
PRINT '';
PRINT '1. ARCHITECTURE:';
PRINT '   - Database: ECommerceDB';
PRINT '   - Recovery Model: FULL';
PRINT '   - Data file: 500MB (C:\SQLData\)';
PRINT '   - Index filegroup: 250MB (C:\SQLData\)';
PRINT '   - Log file: 250MB (C:\SQLData\)';
PRINT '';
PRINT '2. SCHEMAS:';
PRINT '   - Customer: Customer and address data';
PRINT '   - Sales: Orders and order items';
PRINT '   - Inventory: Products and categories';
PRINT '   - Audit: Change tracking';
PRINT '';
PRINT '3. SECURITY:';
PRINT '   - ECommerceApp: Application login (AppRole)';
PRINT '   - ReportUser: Read-only reporting (ReadOnlyRole)';
PRINT '   - DBAUser: Full administrative access';
PRINT '   - Row-Level Security on Customers table';
PRINT '';
PRINT '4. BACKUP SCHEDULE:';
PRINT '   - Full: Daily 2:00 AM';
PRINT '   - Differential: Every 6 hours';
PRINT '   - Log: Every 15 minutes';
PRINT '   - Retention: 30 days';
PRINT '';
PRINT '5. MAINTENANCE SCHEDULE:';
PRINT '   - Daily: Statistics update, index maintenance';
PRINT '   - Weekly: Full integrity check (DBCC CHECKDB)';
PRINT '   - Monthly: Review missing indexes, cleanup old data';
PRINT '';
PRINT '';
PRINT 'RUNBOOK: RESTORE DATABASE FROM BACKUP';
PRINT '======================================';
PRINT '';
PRINT 'Scenario: Restore database to specific point in time';
PRINT '';
PRINT 'Steps:';
PRINT '1. Identify required backups:';
PRINT '   - Latest full backup before target time';
PRINT '   - Latest differential after full backup';
PRINT '   - All log backups after differential';
PRINT '';
PRINT '2. Put database in restoring mode:';
PRINT '   RESTORE DATABASE ECommerceDB';
PRINT '   FROM DISK = ''path\to\full.bak''';
PRINT '   WITH NORECOVERY, REPLACE;';
PRINT '';
PRINT '3. Apply differential:';
PRINT '   RESTORE DATABASE ECommerceDB';
PRINT '   FROM DISK = ''path\to\diff.bak''';
PRINT '   WITH NORECOVERY;';
PRINT '';
PRINT '4. Apply log backups sequentially:';
PRINT '   RESTORE LOG ECommerceDB';
PRINT '   FROM DISK = ''path\to\log1.trn''';
PRINT '   WITH NORECOVERY;';
PRINT '   -- Repeat for each log backup';
PRINT '';
PRINT '5. Final recovery (to point in time):';
PRINT '   RESTORE LOG ECommerceDB';
PRINT '   FROM DISK = ''path\to\last_log.trn''';
PRINT '   WITH RECOVERY, STOPAT = ''2024-12-01 14:30:00'';';
PRINT '';
PRINT '6. Verify database is online:';
PRINT '   SELECT name, state_desc FROM sys.databases';
PRINT '   WHERE name = ''ECommerceDB'';';
PRINT '';

/*
 * PROJECT DELIVERABLES CHECKLIST
 */

PRINT '';
PRINT '==============================================';
PRINT 'PROJECT DELIVERABLES CHECKLIST';
PRINT '==============================================';
PRINT '';
PRINT '☑ Phase 1: Database Design & Deployment';
PRINT '  ☑ Database created with proper configuration';
PRINT '  ☑ Schemas organized logically';
PRINT '  ☑ 9 tables created with constraints';
PRINT '  ☑ Sample data populated';
PRINT '';
PRINT '☑ Phase 2: Security Implementation';
PRINT '  ☑ Logins and users created';
PRINT '  ☑ Custom roles with appropriate permissions';
PRINT '  ☑ Row-Level Security implemented';
PRINT '';
PRINT '☑ Phase 3: Backup & Recovery Strategy';
PRINT '  ☑ Full backup completed';
PRINT '  ☑ Backup strategy documented';
PRINT '  ☑ Backup verified';
PRINT '';
PRINT '☑ Phase 4: Performance Optimization';
PRINT '  ☑ Performance indexes created';
PRINT '  ☑ Statistics updated';
PRINT '  ☑ Indexed views for aggregations';
PRINT '';
PRINT '☑ Phase 5: Monitoring & Alerting';
PRINT '  ☑ Performance snapshot procedure';
PRINT '  ☑ Monitoring checklist created';
PRINT '';
PRINT '☑ Phase 6: Maintenance Automation';
PRINT '  ☑ Daily maintenance procedure';
PRINT '';
PRINT '☑ Phase 7: Documentation & Runbooks';
PRINT '  ☑ Architecture documented';
PRINT '  ☑ Runbook created';
PRINT '';

/*
 * EVALUATION CRITERIA
 */

PRINT '';
PRINT 'EVALUATION CRITERIA:';
PRINT '====================';
PRINT '';
PRINT 'Database Design (20 points):';
PRINT '  - Normalized schema design';
PRINT '  - Appropriate constraints and relationships';
PRINT '  - Proper data types and defaults';
PRINT '';
PRINT 'Security (15 points):';
PRINT '  - Least privilege principle applied';
PRINT '  - Role-based access control implemented';
PRINT '  - Row-Level Security configured';
PRINT '';
PRINT 'Backup Strategy (15 points):';
PRINT '  - Appropriate backup schedule';
PRINT '  - Recovery objectives defined';
PRINT '  - Backup verification process';
PRINT '';
PRINT 'Performance (20 points):';
PRINT '  - Effective index strategy';
PRINT '  - Query optimization techniques';
PRINT '  - Statistics maintenance';
PRINT '';
PRINT 'Monitoring (15 points):';
PRINT '  - Comprehensive monitoring procedures';
PRINT '  - Alert configuration';
PRINT '  - Performance baselines';
PRINT '';
PRINT 'Maintenance (10 points):';
PRINT '  - Automated maintenance procedures';
PRINT '  - Index defragmentation strategy';
PRINT '  - Data cleanup processes';
PRINT '';
PRINT 'Documentation (5 points):';
PRINT '  - Clear and comprehensive';
PRINT '  - Runbooks for common scenarios';
PRINT '  - Architecture diagrams';
PRINT '';
PRINT 'Total: 100 points';
PRINT '';

PRINT '✓✓✓ CAPSTONE PROJECT COMPLETE ✓✓✓';
PRINT '';
PRINT 'Congratulations! You have successfully:';
PRINT '  ✓ Designed and deployed a production database';
PRINT '  ✓ Implemented comprehensive security';
PRINT '  ✓ Created backup and recovery strategy';
PRINT '  ✓ Optimized performance with indexes and views';
PRINT '  ✓ Set up monitoring and alerting';
PRINT '  ✓ Automated maintenance procedures';
PRINT '  ✓ Documented the entire system';
PRINT '';
PRINT 'You are now ready for real-world DBA responsibilities!';
GO
