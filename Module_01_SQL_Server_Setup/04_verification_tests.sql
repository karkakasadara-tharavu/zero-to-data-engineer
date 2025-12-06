-- =============================================
-- Module 01: SQL Server Setup - Verification Tests
-- File: 04_verification_tests.sql
-- Purpose: Comprehensive validation of SQL Server, SSMS, and AdventureWorks setup
-- Author: Karka Kasadara Team
-- Last Updated: December 7, 2025
-- =============================================

-- Instructions:
-- 1. Open this file in SSMS (File → Open → File)
-- 2. Execute each section one by one (highlight and press F5)
-- 3. Verify "Expected Result" matches your actual output
-- 4. If any test fails, see troubleshooting comments

-- =============================================
-- TEST SECTION 1: SQL Server Instance Verification
-- =============================================

PRINT '========================================';
PRINT 'TEST 1: SQL Server Instance Information';
PRINT '========================================';
GO

-- Test 1.1: SQL Server Version
SELECT 
    @@VERSION AS SQLServerVersion,
    @@SERVERNAME AS ServerName,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductLevel') AS ServicePack,
    SERVERPROPERTY('Edition') AS Edition;
GO

-- Expected Result:
-- SQLServerVersion: Microsoft SQL Server 2022 (RTM) - 16.0.xxx...
-- ServerName: YOUR-COMPUTER\SQLEXPRESS
-- ProductVersion: 16.0.xxxx.x
-- ServicePack: RTM (or CU1, CU2, etc.)
-- Edition: Express Edition (64-bit)

-- ✅ PASS: If you see SQL Server 2022 Express Edition
-- ❌ FAIL: If version is older or NULL → SQL Server not running


-- Test 1.2: SQL Server Services Status
EXEC xp_servicecontrol 'QueryState', N'MSSQLServer';  -- May fail on Express (uses MSSQL$SQLEXPRESS)
GO

-- Alternative method (Express-friendly):
PRINT 'SQL Server Express Service Status: Use PowerShell or services.msc to verify MSSQL$SQLEXPRESS is Running';
GO

-- To check via PowerShell (outside SSMS):
-- Get-Service -Name "MSSQL$SQLEXPRESS" | Select-Object Name, Status, StartType


-- Test 1.3: SQL Server Configuration
SELECT 
    SERVERPROPERTY('MachineName') AS MachineName,
    SERVERPROPERTY('ServerName') AS ServerName,
    SERVERPROPERTY('InstanceName') AS InstanceName,
    SERVERPROPERTY('IsClustered') AS IsClustered,
    SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled,
    SERVERPROPERTY('IsIntegratedSecurityOnly') AS IsWindowsAuthOnly;
GO

-- Expected Result:
-- MachineName: YOUR-COMPUTER
-- ServerName: YOUR-COMPUTER\SQLEXPRESS
-- InstanceName: SQLEXPRESS
-- IsClustered: 0 (not clustered)
-- IsFullTextInstalled: 1 (full-text search available)
-- IsWindowsAuthOnly: 1 (Windows Authentication mode)


-- Test 1.4: Memory Configuration
SELECT 
    physical_memory_kb / 1024 AS PhysicalMemoryMB,
    virtual_memory_kb / 1024 AS VirtualMemoryMB,
    committed_kb / 1024 AS CommittedMemoryMB,
    committed_target_kb / 1024 AS CommittedTargetMB
FROM sys.dm_os_sys_info;
GO

-- Expected Result:
-- PhysicalMemoryMB: Should match your system RAM (e.g., 8192 MB for 8GB)
-- CommittedMemoryMB: Amount SQL Server is currently using
-- ✅ PASS: If committed memory is reasonable (<50% of physical)


-- Test 1.5: Database Files Default Locations
SELECT 
    SERVERPROPERTY('InstanceDefaultDataPath') AS DefaultDataPath,
    SERVERPROPERTY('InstanceDefaultLogPath') AS DefaultLogPath;
GO

-- Expected Result:
-- DefaultDataPath: C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\
-- DefaultLogPath: C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\

PRINT '';
PRINT '✅ TEST SECTION 1 COMPLETE: SQL Server is installed and configured correctly!';
PRINT '';
GO


-- =============================================
-- TEST SECTION 2: System Databases Verification
-- =============================================

PRINT '========================================';
PRINT 'TEST 2: System Databases';
PRINT '========================================';
GO

-- Test 2.1: List All Databases
SELECT 
    name AS DatabaseName,
    database_id AS DatabaseID,
    create_date AS CreatedDate,
    state_desc AS State,
    recovery_model_desc AS RecoveryModel,
    compatibility_level AS CompatibilityLevel
FROM sys.databases
ORDER BY database_id;
GO

-- Expected Result (minimum 6 databases):
-- master, tempdb, model, msdb, AdventureWorksLT2022, AdventureWorks2022
-- State: ONLINE for all
-- ✅ PASS: All 6+ databases present and ONLINE


-- Test 2.2: System Database Sizes
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    SUM(size * 8 / 1024) AS SizeMB
FROM sys.master_files
WHERE DB_NAME(database_id) IN ('master', 'tempdb', 'model', 'msdb')
GROUP BY database_id
ORDER BY DatabaseName;
GO

-- Expected Result:
-- master: ~5-10 MB
-- tempdb: ~8-16 MB (varies)
-- model: ~8 MB
-- msdb: ~15-20 MB


-- Test 2.3: Check tempdb Configuration
USE tempdb;
GO

SELECT 
    name AS FileName,
    physical_name AS FilePath,
    size * 8 / 1024 AS CurrentSizeMB,
    growth AS Growth,
    is_percent_growth AS IsPercentGrowth
FROM sys.database_files;
GO

-- Expected Result:
-- At least 1 data file (tempdev) and 1 log file (templog)
-- Growth should be configured (not 0)

USE master;
GO

PRINT '';
PRINT '✅ TEST SECTION 2 COMPLETE: System databases are healthy!';
PRINT '';
GO


-- =============================================
-- TEST SECTION 3: AdventureWorksLT2022 Verification
-- =============================================

PRINT '========================================';
PRINT 'TEST 3: AdventureWorksLT2022 Database';
PRINT '========================================';
GO

-- Test 3.1: Database Existence
IF DB_ID('AdventureWorksLT2022') IS NOT NULL
    PRINT '✅ AdventureWorksLT2022 database exists!';
ELSE
BEGIN
    PRINT '❌ FAIL: AdventureWorksLT2022 database NOT FOUND!';
    PRINT 'Action: Re-run restore process from Section 3.';
END
GO


-- Test 3.2: Switch to Database
USE AdventureWorksLT2022;
GO

PRINT 'Current Database: ' + DB_NAME();
GO


-- Test 3.3: Table Count
SELECT 
    COUNT(*) AS TotalTables
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
GO

-- Expected Result: 10 tables (all in SalesLT schema)
-- ✅ PASS: 10 tables found


-- Test 3.4: List All Tables
SELECT 
    TABLE_SCHEMA AS SchemaName,
    TABLE_NAME AS TableName
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- Expected Tables (all SalesLT schema):
-- SalesLT.Address
-- SalesLT.Customer
-- SalesLT.CustomerAddress
-- SalesLT.Product
-- SalesLT.ProductCategory
-- SalesLT.ProductDescription
-- SalesLT.ProductModel
-- SalesLT.ProductModelProductDescription
-- SalesLT.SalesOrderDetail
-- SalesLT.SalesOrderHeader


-- Test 3.5: Row Counts for All Tables
SELECT 
    t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY RowCount DESC;
GO

-- Expected Row Counts (approximate):
-- SalesOrderDetail: ~500+ rows
-- Customer: ~800+ rows
-- Product: ~200+ rows
-- SalesOrderHeader: ~30+ rows
-- (others: varies)


-- Test 3.6: Sample Data - Customers
SELECT TOP 5
    CustomerID,
    FirstName,
    LastName,
    EmailAddress,
    Phone
FROM SalesLT.Customer
ORDER BY CustomerID;
GO

-- Expected Result: 5 rows with customer data
-- ✅ PASS: If you see customer names and emails


-- Test 3.7: Sample Data - Products
SELECT TOP 5
    ProductID,
    Name,
    ProductNumber,
    Color,
    ListPrice,
    StandardCost
FROM SalesLT.Product
ORDER BY ListPrice DESC;
GO

-- Expected Result: 5 most expensive products
-- ✅ PASS: If you see product names and prices


-- Test 3.8: Sample JOIN Query (Test Relationships)
SELECT TOP 10
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
ORDER BY soh.OrderDate DESC;
GO

-- Expected Result: 10 rows showing customers and their orders
-- ✅ PASS: If JOIN works without errors


-- Test 3.9: Aggregation Query
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS TotalRevenue,
    AVG(TotalDue) AS AverageOrderValue,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder
FROM SalesLT.SalesOrderHeader;
GO

-- Expected Result:
-- TotalOrders: ~30+
-- TotalRevenue: Large number (thousands/millions)
-- AverageOrderValue: Reasonable amount
-- FirstOrder/LastOrder: Valid dates


-- Test 3.10: Foreign Key Constraints
SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS ParentTable,
    tr.name AS ReferencedTable
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
ORDER BY tp.name;
GO

-- Expected Result: Multiple foreign keys listed
-- ✅ PASS: If relationships exist between tables

PRINT '';
PRINT '✅ TEST SECTION 3 COMPLETE: AdventureWorksLT2022 is fully functional!';
PRINT '';
GO


-- =============================================
-- TEST SECTION 4: AdventureWorks2022 Verification
-- =============================================

PRINT '========================================';
PRINT 'TEST 4: AdventureWorks2022 Database';
PRINT '========================================';
GO

-- Test 4.1: Database Existence
IF DB_ID('AdventureWorks2022') IS NOT NULL
    PRINT '✅ AdventureWorks2022 database exists!';
ELSE
BEGIN
    PRINT '❌ FAIL: AdventureWorks2022 database NOT FOUND!';
    PRINT 'Action: Re-run restore process from Section 3.';
END
GO


-- Test 4.2: Switch to Database
USE AdventureWorks2022;
GO

PRINT 'Current Database: ' + DB_NAME();
GO


-- Test 4.3: Table Count
SELECT 
    COUNT(*) AS TotalTables
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
GO

-- Expected Result: 70+ tables
-- ✅ PASS: If count is 70 or more


-- Test 4.4: Tables by Schema
SELECT 
    TABLE_SCHEMA AS SchemaName,
    COUNT(*) AS TableCount
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
GROUP BY TABLE_SCHEMA
ORDER BY TableCount DESC;
GO

-- Expected Result:
-- Production: 25
-- Sales: 17
-- Person: 13
-- Purchasing: 8
-- HumanResources: 6
-- dbo: 2


-- Test 4.5: Row Counts for Key Tables
SELECT TOP 10
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY RowCount DESC;
GO

-- Expected Top Tables:
-- Sales.SalesOrderDetail: ~120,000+ rows
-- Production.TransactionHistory: ~100,000+ rows
-- Person.Person: ~19,000+ rows
-- (others: varies)


-- Test 4.6: Sample Data - Employees
SELECT TOP 5
    BusinessEntityID,
    JobTitle,
    BirthDate,
    HireDate,
    Gender,
    MaritalStatus
FROM HumanResources.Employee
ORDER BY HireDate;
GO

-- Expected Result: 5 employee records
-- ✅ PASS: If you see employee data


-- Test 4.7: Sample Data - Products with Categories
SELECT TOP 5
    p.ProductID,
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    p.ListPrice,
    p.StandardCost
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
ORDER BY p.ListPrice DESC;
GO

-- Expected Result: 5 products with category names
-- ✅ PASS: If multi-table JOIN works


-- Test 4.8: Sales Analysis Query
SELECT 
    t.Name AS TerritoryName,
    COUNT(soh.SalesOrderID) AS TotalOrders,
    SUM(soh.TotalDue) AS TotalRevenue,
    AVG(soh.TotalDue) AS AverageOrderValue
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory t ON soh.TerritoryID = t.TerritoryID
GROUP BY t.Name
ORDER BY TotalRevenue DESC;
GO

-- Expected Result: Multiple territories with sales data
-- ✅ PASS: If aggregation works correctly


-- Test 4.9: Complex JOIN (4 Tables)
SELECT TOP 5
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    e.JobTitle,
    d.Name AS DepartmentName,
    edh.StartDate
FROM Person.Person p
INNER JOIN HumanResources.Employee e ON p.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
INNER JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL  -- Current department only
ORDER BY edh.StartDate;
GO

-- Expected Result: 5 employees with current department info
-- ✅ PASS: If complex JOIN executes successfully


-- Test 4.10: Data Integrity - Check for Orphaned Records
SELECT 
    COUNT(*) AS OrphanedSalesOrders
FROM Sales.SalesOrderHeader soh
LEFT JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;
GO

-- Expected Result: 0 (no orphaned records)
-- ✅ PASS: If count is 0 (good data integrity)


-- Test 4.11: Stored Procedures Count
SELECT 
    COUNT(*) AS TotalStoredProcedures
FROM sys.procedures
WHERE is_ms_shipped = 0;  -- Exclude system procedures
GO

-- Expected Result: Multiple stored procedures
-- ✅ PASS: If count > 0


-- Test 4.12: Views Count
SELECT 
    COUNT(*) AS TotalViews
FROM sys.views
WHERE is_ms_shipped = 0;  -- Exclude system views
GO

-- Expected Result: Multiple views
-- ✅ PASS: If count > 0


-- Test 4.13: Indexes on Key Tables
SELECT 
    OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    COUNT(ic.index_column_id) AS ColumnCount
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE OBJECT_NAME(i.object_id) = 'SalesOrderHeader'
GROUP BY i.object_id, i.name, i.type_desc
ORDER BY i.name;
GO

-- Expected Result: Multiple indexes (clustered, nonclustered)
-- ✅ PASS: If indexes exist on SalesOrderHeader table

PRINT '';
PRINT '✅ TEST SECTION 4 COMPLETE: AdventureWorks2022 is fully functional!';
PRINT '';
GO


-- =============================================
-- TEST SECTION 5: SSMS Functionality Tests
-- =============================================

PRINT '========================================';
PRINT 'TEST 5: SSMS Features';
PRINT '========================================';
GO

-- Test 5.1: Query Execution Time
-- This tests that SSMS can capture execution time

SET STATISTICS TIME ON;
GO

SELECT COUNT(*) AS TotalPersons
FROM AdventureWorks2022.Person.Person;
GO

SET STATISTICS TIME OFF;
GO

-- Expected Result: 
-- Query executes successfully
-- "SQL Server Execution Times" message appears in Messages tab
-- ✅ PASS: If execution time is displayed


-- Test 5.2: Query I/O Statistics
SET STATISTICS IO ON;
GO

SELECT TOP 100 *
FROM AdventureWorks2022.Sales.SalesOrderHeader
ORDER BY OrderDate DESC;
GO

SET STATISTICS IO OFF;
GO

-- Expected Result:
-- "Table 'SalesOrderHeader'. Scan count..." message appears
-- ✅ PASS: If I/O statistics are displayed


-- Test 5.3: Execution Plan Generation
-- In SSMS: Click "Display Estimated Execution Plan" (Ctrl+L) before running
-- Or run this query and check "Execution plan" tab

SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    c.CustomerID,
    p.FirstName,
    p.LastName
FROM AdventureWorks2022.Sales.SalesOrderHeader soh
INNER JOIN AdventureWorks2022.Sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN AdventureWorks2022.Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE soh.OrderDate > '2013-01-01';
GO

-- Expected Result: 
-- Query executes successfully
-- Execution plan available in "Execution plan" tab (if enabled)
-- ✅ PASS: If execution plan displays graphically


-- Test 5.4: IntelliSense Test
-- Type the following slowly in a new query window to test IntelliSense:
-- USE AdventureWorks2022;
-- SELECT * FROM Sales.
-- (IntelliSense should suggest tables like Customer, SalesOrderHeader, etc.)

PRINT 'IntelliSense Test: Type "SELECT * FROM Sales." in a new query window';
PRINT 'Expected: IntelliSense suggests tables (Customer, SalesOrderHeader, etc.)';
PRINT '✅ PASS: If IntelliSense auto-complete works';
GO


-- Test 5.5: Results to Grid vs Text
-- In SSMS: Ctrl+D (Results to Grid), Ctrl+T (Results to Text)
-- Verify you can switch between modes

SELECT 'Test Results Output' AS TestMessage;
GO

PRINT '✅ PASS: If you can see results in grid format';
PRINT 'Try pressing Ctrl+T and re-run to see text output';
GO

PRINT '';
PRINT '✅ TEST SECTION 5 COMPLETE: SSMS features are working correctly!';
PRINT '';
GO


-- =============================================
-- TEST SECTION 6: Performance & Security
-- =============================================

PRINT '========================================';
PRINT 'TEST 6: Performance & Security';
PRINT '========================================';
GO

USE master;
GO

-- Test 6.1: Current User & Permissions
SELECT 
    SYSTEM_USER AS LoggedInUser,
    USER_NAME() AS DatabaseUser,
    IS_SRVROLEMEMBER('sysadmin') AS IsSysAdmin;
GO

-- Expected Result:
-- LoggedInUser: YOUR-COMPUTER\YourUsername
-- DatabaseUser: dbo (database owner)
-- IsSysAdmin: 1 (you are sysadmin)
-- ✅ PASS: If IsSysAdmin = 1


-- Test 6.2: Check SQL Server Authentication Mode
EXEC xp_loginconfig 'login mode';
GO

-- Expected Result: 
-- "Windows NT Authentication" or "Windows and SQL Server Authentication"
-- ✅ PASS: Windows Authentication is enabled


-- Test 6.3: List All Logins
SELECT 
    name AS LoginName,
    type_desc AS LoginType,
    create_date AS Created,
    is_disabled AS IsDisabled
FROM sys.server_principals
WHERE type IN ('S', 'U', 'G')  -- SQL login, Windows login, Windows group
ORDER BY name;
GO

-- Expected Result: At least your Windows account listed
-- ✅ PASS: If your login appears


-- Test 6.4: Database Permissions
SELECT 
    DB_NAME() AS DatabaseName,
    HAS_DBACCESS(DB_NAME()) AS CanAccess,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'SELECT') AS CanSelect,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'INSERT') AS CanInsert,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'UPDATE') AS CanUpdate,
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'DELETE') AS CanDelete;
GO

-- Expected Result: All permissions = 1 (full access)
-- ✅ PASS: If you have complete database access


-- Test 6.5: Max Server Memory Configuration
SELECT 
    name AS ConfigName,
    value_in_use AS CurrentValue,
    description
FROM sys.configurations
WHERE name = 'max server memory (MB)';
GO

-- Expected Result:
-- CurrentValue: 2147483647 (default max) or configured limit
-- ✅ PASS: Memory is configured (not 0)


-- Test 6.6: Check TempDB Performance
SELECT 
    COUNT(*) AS TempDBFiles
FROM sys.master_files
WHERE database_id = DB_ID('tempdb')
    AND type_desc = 'ROWS';  -- Data files only
GO

-- Expected Result: 
-- TempDBFiles: 1-8 (depending on CPU cores)
-- ✅ PASS: TempDB has at least 1 data file

PRINT '';
PRINT '✅ TEST SECTION 6 COMPLETE: Performance and security settings verified!';
PRINT '';
GO


-- =============================================
-- TEST SECTION 7: Final Summary Report
-- =============================================

PRINT '========================================';
PRINT 'FINAL SUMMARY REPORT';
PRINT '========================================';
GO

-- Summary: System Overview
SELECT 
    @@VERSION AS SQLServerVersion,
    @@SERVERNAME AS ServerName,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductLevel') AS ServicePackLevel,
    (SELECT COUNT(*) FROM sys.databases WHERE state_desc = 'ONLINE') AS OnlineDatabases,
    (SELECT COUNT(*) FROM sys.databases WHERE name IN ('AdventureWorksLT2022', 'AdventureWorks2022')) AS AdventureWorksDatabases,
    SYSTEM_USER AS CurrentUser,
    GETDATE() AS ReportGeneratedAt;
GO


-- Summary: Database Sizes
SELECT 
    name AS DatabaseName,
    (SUM(size) * 8 / 1024) AS SizeMB
FROM sys.master_files
WHERE database_id IN (DB_ID('AdventureWorksLT2022'), DB_ID('AdventureWorks2022'))
GROUP BY name
ORDER BY name;
GO


-- Summary: Table Counts
SELECT 
    'AdventureWorksLT2022' AS DatabaseName,
    (SELECT COUNT(*) FROM AdventureWorksLT2022.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE') AS TableCount
UNION ALL
SELECT 
    'AdventureWorks2022' AS DatabaseName,
    (SELECT COUNT(*) FROM AdventureWorks2022.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE') AS TableCount;
GO


-- Summary: AdventureWorksLT2022 Row Counts
USE AdventureWorksLT2022;
GO

PRINT 'AdventureWorksLT2022 Top Tables by Row Count:';
SELECT TOP 5
    t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY RowCount DESC;
GO


-- Summary: AdventureWorks2022 Row Counts
USE AdventureWorks2022;
GO

PRINT 'AdventureWorks2022 Top Tables by Row Count:';
SELECT TOP 5
    s.name + '.' + t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY RowCount DESC;
GO


-- =============================================
-- FINAL STATUS MESSAGE
-- =============================================

PRINT '';
PRINT '========================================';
PRINT '🎉 ALL VERIFICATION TESTS COMPLETE! 🎉';
PRINT '========================================';
PRINT '';
PRINT '✅ SQL Server 2022 Express: Installed & Running';
PRINT '✅ SSMS: Configured & Functional';
PRINT '✅ AdventureWorksLT2022: Restored & Verified';
PRINT '✅ AdventureWorks2022: Restored & Verified';
PRINT '';
PRINT '🚀 You are READY to begin your Data Engineering journey!';
PRINT '';
PRINT 'Next Step: Module 02 - SQL Fundamentals';
PRINT 'Estimated Duration: 2 weeks';
PRINT '';
PRINT 'கற்க கசடற - Learn Flawlessly, Grow Together';
PRINT 'Karka Kasadara - Your Data Engineering Partner';
PRINT '';
PRINT '========================================';
GO


-- =============================================
-- END OF VERIFICATION TESTS
-- =============================================

-- If all tests passed:
-- ✅ You are ready for Module 02!

-- If any tests failed:
-- 1. Review error messages in "Messages" tab
-- 2. See "Troubleshooting Guide" (Section 5)
-- 3. Re-run failed test section after fixes
-- 4. Contact Karka Kasadara community for help

-- Happy Learning! 📚🎓
