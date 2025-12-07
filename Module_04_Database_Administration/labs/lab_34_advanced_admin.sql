/*
 * Lab 34: Advanced Administration Topics
 * Module 04: Database Administration
 * 
 * Objective: Explore advanced DBA topics including partitioning, compression, and more
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 34: Advanced Administration Topics';
PRINT '==============================================';
PRINT '';

/*
 * ADVANCED TOPICS COVERED:
 * 
 * 1. Table Partitioning
 * 2. Data Compression
 * 3. Filegroups and Files
 * 4. Resource Governor
 * 5. Policy-Based Management
 * 6. Change Data Capture (CDC)
 * 7. Database Snapshots
 */

IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Error: BookstoreDB not found. Run Lab 20 first.';
    RETURN;
END;
GO

USE BookstoreDB;
GO

/*
 * PART 1: TABLE PARTITIONING
 */

PRINT 'PART 1: Table Partitioning';
PRINT '----------------------------';

-- Create partition function (range boundaries)
IF NOT EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PF_OrderDate_Yearly')
BEGIN
    CREATE PARTITION FUNCTION PF_OrderDate_Yearly (DATE)
    AS RANGE RIGHT FOR VALUES 
    ('2022-01-01', '2023-01-01', '2024-01-01', '2025-01-01');
    
    PRINT '✓ Created partition function: PF_OrderDate_Yearly';
    PRINT '  Partitions: <2022 | 2022 | 2023 | 2024 | 2025+';
END;

-- Create partition scheme (map partitions to filegroups)
IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PS_OrderDate_Yearly')
BEGIN
    CREATE PARTITION SCHEME PS_OrderDate_Yearly
    AS PARTITION PF_OrderDate_Yearly
    ALL TO ([PRIMARY]);  -- In production, use separate filegroups
    
    PRINT '✓ Created partition scheme: PS_OrderDate_Yearly';
END;

PRINT '';

-- Create partitioned table
IF OBJECT_ID('OrdersPartitioned', 'U') IS NOT NULL DROP TABLE OrdersPartitioned;

CREATE TABLE OrdersPartitioned (
    OrderID INT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    TotalAmount DECIMAL(10,2),
    Status NVARCHAR(20),
    CONSTRAINT PK_OrdersPartitioned PRIMARY KEY (OrderID, OrderDate)
) ON PS_OrderDate_Yearly(OrderDate);

PRINT '✓ Created partitioned table: OrdersPartitioned';
PRINT '';

-- Insert sample data across partitions
INSERT INTO OrdersPartitioned (OrderDate, CustomerID, TotalAmount, Status)
SELECT 
    DATEADD(DAY, (n.number % 1095), '2022-01-01'),  -- 3 years of data
    (n.number % 100) + 1,
    CAST(RAND(CHECKSUM(NEWID())) * 1000 AS DECIMAL(10,2)),
    CASE (n.number % 4)
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Shipped'
        WHEN 2 THEN 'Delivered'
        ELSE 'Cancelled'
    END
FROM master.dbo.spt_values n
WHERE n.type = 'P' AND n.number BETWEEN 1 AND 10000;

PRINT '✓ Inserted 10,000 orders across multiple years';
PRINT '';

-- View partition distribution
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    p.partition_number AS PartitionNum,
    fg.name AS FileGroup,
    p.rows AS RowCount,
    prv.value AS BoundaryValue,
    CASE pf.boundary_value_on_right
        WHEN 1 THEN 'RIGHT'
        ELSE 'LEFT'
    END AS BoundaryType
FROM sys.partitions p
INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.allocation_units au ON p.partition_id = au.container_id
INNER JOIN sys.filegroups fg ON au.data_space_id = fg.data_space_id
LEFT JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
LEFT JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id 
    AND p.partition_number = prv.boundary_id + pf.boundary_value_on_right
WHERE p.object_id = OBJECT_ID('OrdersPartitioned')
    AND i.index_id IN (0, 1)  -- Heap or clustered index
ORDER BY p.partition_number;

PRINT '';

-- Partition elimination (query only specific partitions)
PRINT 'Demonstrating partition elimination:';
SET STATISTICS IO ON;

SELECT COUNT(*), SUM(TotalAmount)
FROM OrdersPartitioned
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';

SET STATISTICS IO OFF;
PRINT '(Only 2024 partition scanned - partition elimination!)';
PRINT '';

/*
 * PART 2: DATA COMPRESSION (Enterprise Edition Feature)
 */

PRINT 'PART 2: Data Compression';
PRINT '-------------------------';

-- Estimate compression savings
PRINT 'Estimating ROW compression savings:';
EXEC sp_estimate_data_compression_savings 
    @schema_name = 'dbo',
    @object_name = 'OrdersPartitioned',
    @index_id = NULL,
    @partition_number = NULL,
    @data_compression = 'ROW';

PRINT '';

PRINT 'Estimating PAGE compression savings:';
EXEC sp_estimate_data_compression_savings 
    @schema_name = 'dbo',
    @object_name = 'OrdersPartitioned',
    @index_id = NULL,
    @partition_number = NULL,
    @data_compression = 'PAGE';

PRINT '';

-- Apply compression (Enterprise Edition only - will fail on other editions)
/*
-- ROW compression
ALTER TABLE OrdersPartitioned
REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = ROW);

-- PAGE compression (better compression ratio)
ALTER TABLE OrdersPartitioned
REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);

PRINT '✓ Applied PAGE compression to OrdersPartitioned';
*/

PRINT 'Compression types (Enterprise Edition):';
PRINT '  NONE: No compression (default)';
PRINT '  ROW:  Compress fixed-length datatypes (5-15% savings)';
PRINT '  PAGE: Compress duplicate values (15-60% savings)';
PRINT '  Note: PAGE compression includes ROW compression';
PRINT '';

/*
 * PART 3: FILEGROUPS AND FILES
 */

PRINT 'PART 3: Filegroups and Files Management';
PRINT '----------------------------------------';

-- View current filegroups
SELECT 
    fg.name AS FileGroupName,
    fg.type_desc AS FileGroupType,
    fg.is_default AS IsDefault,
    fg.is_read_only AS IsReadOnly,
    df.name AS FileName,
    df.physical_name AS FilePath,
    df.size * 8.0 / 1024 AS SizeMB,
    df.max_size * 8.0 / 1024 AS MaxSizeMB,
    df.growth * 8.0 / 1024 AS GrowthMB
FROM sys.filegroups fg
LEFT JOIN sys.database_files df ON fg.data_space_id = df.data_space_id
WHERE df.database_id = DB_ID() OR df.database_id IS NULL
ORDER BY fg.name, df.name;

PRINT '';

-- Add filegroup (commented - requires disk space)
/*
ALTER DATABASE BookstoreDB
ADD FILEGROUP FG_Indexes;

ALTER DATABASE BookstoreDB
ADD FILE (
    NAME = N'BookstoreDB_Indexes',
    FILENAME = N'C:\SQLData\BookstoreDB_Indexes.ndf',
    SIZE = 100MB,
    FILEGROWTH = 50MB
) TO FILEGROUP FG_Indexes;

PRINT '✓ Created FG_Indexes filegroup';

-- Move index to new filegroup
CREATE NONCLUSTERED INDEX IX_Orders_Customer
ON Orders(CustomerID)
ON FG_Indexes;
*/

PRINT 'Filegroup strategies:';
PRINT '  - PRIMARY: System objects and default user objects';
PRINT '  - Separate FG for indexes (improves I/O parallelism)';
PRINT '  - Separate FG for large tables';
PRINT '  - Read-only FG for historical data (can backup once)';
PRINT '';

/*
 * PART 4: DATABASE SNAPSHOTS
 */

PRINT 'PART 4: Database Snapshots';
PRINT '---------------------------';

-- Create database snapshot (read-only point-in-time copy)
USE master;
GO

IF DB_ID('BookstoreDB_Snapshot') IS NOT NULL
BEGIN
    DROP DATABASE BookstoreDB_Snapshot;
END;

DECLARE @SnapshotSQL NVARCHAR(MAX) = N'
CREATE DATABASE BookstoreDB_Snapshot ON
(
    NAME = BookstoreDB,
    FILENAME = ''C:\SQLData\BookstoreDB_Snapshot.ss''
)
AS SNAPSHOT OF BookstoreDB;
';

EXEC sp_executesql @SnapshotSQL;
PRINT '✓ Created database snapshot: BookstoreDB_Snapshot';
PRINT '';

-- Query snapshot (point-in-time data)
USE BookstoreDB_Snapshot;
SELECT COUNT(*) AS BookCount FROM Books;
PRINT '(Snapshot contains data from snapshot creation time)';
PRINT '';

-- Snapshots use sparse files (only store changed pages)
SELECT 
    name AS SnapshotName,
    create_date AS CreatedDate,
    source_database_id AS SourceDBID,
    DB_NAME(source_database_id) AS SourceDatabase
FROM sys.databases
WHERE source_database_id IS NOT NULL;

PRINT '';
PRINT 'Snapshot use cases:';
PRINT '  - Point-in-time reporting';
PRINT '  - Reverting accidental changes';
PRINT '  - Testing (refresh from snapshot)';
PRINT '  - Baseline comparisons';
PRINT '';

USE BookstoreDB;
GO

/*
 * PART 5: CHANGE DATA CAPTURE (CDC)
 */

PRINT 'PART 5: Change Data Capture (CDC)';
PRINT '-----------------------------------';

-- Enable CDC on database (Enterprise Edition or Developer Edition)
/*
EXEC sys.sp_cdc_enable_db;
PRINT '✓ Enabled CDC on BookstoreDB';

-- Enable CDC on specific table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Books',
    @role_name = NULL,  -- No role restriction
    @supports_net_changes = 1;  -- Track net changes

PRINT '✓ Enabled CDC on Books table';
PRINT '';

-- Make changes (CDC will track)
UPDATE Books SET Price = Price * 1.05 WHERE PublicationYear < 2000;
DELETE FROM Books WHERE BookID = 999;  -- If exists

-- Query CDC changes
SELECT 
    *,
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE (Before)'
        WHEN 4 THEN 'UPDATE (After)'
    END AS OperationType
FROM cdc.dbo_Books_CT  -- CDC change table
WHERE __$start_lsn > sys.fn_cdc_get_min_lsn('dbo_Books')
ORDER BY __$start_lsn;

-- Cleanup CDC (disable)
EXEC sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'Books',
    @capture_instance = N'dbo_Books';

EXEC sys.sp_cdc_disable_db;
*/

PRINT 'CDC capabilities (Enterprise/Developer Edition):';
PRINT '  - Asynchronous change tracking';
PRINT '  - Historical change queries';
PRINT '  - ETL source for data warehouse';
PRINT '  - Audit trails';
PRINT '  Note: Uses transaction log (minimal overhead)';
PRINT '';

/*
 * PART 6: RESOURCE GOVERNOR
 */

PRINT 'PART 6: Resource Governor';
PRINT '--------------------------';

-- Create resource pools (Enterprise Edition)
/*
-- Pool for reporting queries (limited resources)
CREATE RESOURCE POOL ReportingPool
WITH (
    MIN_CPU_PERCENT = 0,
    MAX_CPU_PERCENT = 25,
    MIN_MEMORY_PERCENT = 0,
    MAX_MEMORY_PERCENT = 25
);

-- Pool for OLTP (priority resources)
CREATE RESOURCE POOL OLTPPool
WITH (
    MIN_CPU_PERCENT = 50,
    MAX_CPU_PERCENT = 100,
    MIN_MEMORY_PERCENT = 50,
    MAX_MEMORY_PERCENT = 100
);

-- Create workload groups
CREATE WORKLOAD GROUP ReportingGroup
USING ReportingPool;

CREATE WORKLOAD GROUP OLTPGroup
USING OLTPPool;

-- Create classifier function
CREATE FUNCTION dbo.fnResourceClassifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @WorkloadGroup SYSNAME;
    
    IF APP_NAME() LIKE '%Report%'
        SET @WorkloadGroup = 'ReportingGroup';
    ELSE
        SET @WorkloadGroup = 'OLTPGroup';
    
    RETURN @WorkloadGroup;
END;
GO

-- Configure Resource Governor
ALTER RESOURCE GOVERNOR 
WITH (CLASSIFIER_FUNCTION = dbo.fnResourceClassifier);

-- Enable Resource Governor
ALTER RESOURCE GOVERNOR RECONFIGURE;

PRINT '✓ Configured Resource Governor';
*/

PRINT 'Resource Governor (Enterprise Edition):';
PRINT '  - Limit CPU and memory per workload';
PRINT '  - Prioritize OLTP over reporting';
PRINT '  - Prevent runaway queries';
PRINT '  - Classify by app, login, or database';
PRINT '';

/*
 * PART 7: POLICY-BASED MANAGEMENT
 */

PRINT 'PART 7: Policy-Based Management';
PRINT '--------------------------------';

-- Create policy condition (via T-SQL - usually done in SSMS)
/*
-- Example: Ensure all databases have Full recovery model
DECLARE @condition_id INT;
DECLARE @policy_id INT;

-- Create condition
EXEC msdb.dbo.sp_syspolicy_add_condition
    @name = N'FullRecoveryModel',
    @description = N'Database must use Full recovery model',
    @facet = N'Database',
    @expression = N'
<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>Numeric</TypeClass>
    <Name>RecoveryModel</Name>
  </Attribute>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <Value>1</Value>
  </Constant>
</Operator>',
    @condition_id = @condition_id OUTPUT;

-- Create policy
EXEC msdb.dbo.sp_syspolicy_add_policy
    @name = N'RequireFullRecovery',
    @condition_name = N'FullRecoveryModel',
    @policy_category = N'Database Administration',
    @description = N'All production databases must use Full recovery',
    @help_text = N'Change recovery model to Full',
    @help_link = N'https://docs.microsoft.com/sql/recovery-models',
    @schedule_uid = NULL,
    @execution_mode = 0,  -- On demand
    @policy_id = @policy_id OUTPUT;
*/

PRINT 'Policy-Based Management capabilities:';
PRINT '  - Enforce standards across servers';
PRINT '  - Automated compliance checking';
PRINT '  - Preventive policies (block violations)';
PRINT '  - Central policy management';
PRINT '  Common policies: Naming conventions, recovery models, settings';
PRINT '';

/*
 * PART 8: TEMPORAL TABLES (System-Versioned)
 */

PRINT 'PART 8: Temporal Tables (System-Versioned)';
PRINT '--------------------------------------------';

-- Create temporal table
IF OBJECT_ID('ProductPrices', 'U') IS NOT NULL
BEGIN
    IF OBJECTPROPERTY(OBJECT_ID('ProductPrices'), 'TableTemporalType') = 2
        ALTER TABLE ProductPrices SET (SYSTEM_VERSIONING = OFF);
    DROP TABLE IF EXISTS ProductPrices;
    DROP TABLE IF EXISTS ProductPricesHistory;
END;

CREATE TABLE ProductPrices (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductPricesHistory));

PRINT '✓ Created temporal table: ProductPrices';
PRINT '';

-- Insert and update data
INSERT INTO ProductPrices (ProductID, ProductName, Price)
VALUES 
    (1, 'Widget', 10.00),
    (2, 'Gadget', 15.00);

WAITFOR DELAY '00:00:02';

UPDATE ProductPrices SET Price = 12.00 WHERE ProductID = 1;
UPDATE ProductPrices SET Price = 18.00 WHERE ProductID = 2;

PRINT '✓ Made price changes (automatically versioned)';
PRINT '';

-- Query historical data
PRINT 'Current prices:';
SELECT * FROM ProductPrices;

PRINT '';
PRINT 'Historical prices:';
SELECT * FROM ProductPricesHistory;

PRINT '';
PRINT 'All history (including current):';
SELECT * FROM ProductPrices FOR SYSTEM_TIME ALL ORDER BY ProductID, ValidFrom;

PRINT '';

/*
 * PART 9: COLUMNSTORE INDEXES
 */

PRINT 'PART 9: Columnstore Indexes';
PRINT '----------------------------';

-- Create table for columnstore demo
IF OBJECT_ID('SalesAnalytics', 'U') IS NOT NULL DROP TABLE SalesAnalytics;

CREATE TABLE SalesAnalytics (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate DATE,
    ProductID INT,
    Quantity INT,
    Revenue DECIMAL(10,2),
    Region NVARCHAR(50)
);

-- Insert sample data
INSERT INTO SalesAnalytics (SaleDate, ProductID, Quantity, Revenue, Region)
SELECT 
    DATEADD(DAY, n.number % 365, '2024-01-01'),
    (n.number % 100) + 1,
    (n.number % 50) + 1,
    CAST(RAND(CHECKSUM(NEWID())) * 1000 AS DECIMAL(10,2)),
    CASE (n.number % 4)
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        ELSE 'West'
    END
FROM master.dbo.spt_values n
WHERE n.type = 'P' AND n.number BETWEEN 1 AND 100000;

PRINT '✓ Created SalesAnalytics with 100,000 rows';
PRINT '';

-- Create columnstore index (excellent for analytics)
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesAnalytics
ON SalesAnalytics (SaleDate, ProductID, Quantity, Revenue, Region);

PRINT '✓ Created columnstore index';
PRINT '';

-- Test analytical query
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT 
    Region,
    YEAR(SaleDate) AS Year,
    SUM(Revenue) AS TotalRevenue,
    SUM(Quantity) AS TotalQuantity
FROM SalesAnalytics
GROUP BY Region, YEAR(SaleDate)
ORDER BY Region, Year;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

PRINT '(Columnstore provides 10-100x compression and fast aggregations)';
PRINT '';

/*
 * PART 10: BEST PRACTICES SUMMARY
 */

PRINT 'PART 10: Advanced Administration Best Practices';
PRINT '------------------------------------------------';
PRINT '';
PRINT 'PARTITIONING:';
PRINT '  - Use for very large tables (>100GB)';
PRINT '  - Partition on date columns for sliding windows';
PRINT '  - Place partitions on separate filegroups';
PRINT '  - Monitor partition alignment for joins';
PRINT '';
PRINT 'COMPRESSION:';
PRINT '  - Always estimate savings first';
PRINT '  - Start with ROW, upgrade to PAGE if needed';
PRINT '  - Consider CPU trade-off vs disk savings';
PRINT '  - Archive compression for cold data';
PRINT '';
PRINT 'FILEGROUPS:';
PRINT '  - Separate data, indexes, and logs';
PRINT '  - Read-only FG for historical data';
PRINT '  - Place on different physical drives';
PRINT '';
PRINT 'CDC:';
PRINT '  - Use for audit trails and ETL';
PRINT '  - Monitor CDC job health';
PRINT '  - Clean up old change data regularly';
PRINT '';
PRINT 'TEMPORAL TABLES:';
PRINT '  - Perfect for audit requirements';
PRINT '  - Automatic versioning (no triggers)';
PRINT '  - Consider history table retention';
PRINT '';
PRINT 'COLUMNSTORE:';
PRINT '  - Use for data warehouse and analytics';
PRINT '  - Not suitable for OLTP (frequent updates)';
PRINT '  - Combine with partitioning for best results';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Implement partition switching for sliding window (archive old data)
 * 2. Compare ROW vs PAGE compression on different table types
 * 3. Design filegroup strategy for 1TB database
 * 4. Build CDC-based audit system
 * 5. Create Resource Governor policy for mixed workloads
 * 
 * CHALLENGE:
 * Design enterprise-grade database architecture:
 * - Partitioning strategy for 10TB fact table
 * - Compression policy based on access patterns
 * - Resource governance for multi-tenant system
 * - Temporal table implementation for compliance
 * - Columnstore for real-time analytics
 * - AlwaysOn availability groups
 * - Performance monitoring and optimization
 */

PRINT '✓ Lab 34 Complete: Advanced administration topics covered';
PRINT '';
PRINT 'Enterprise Features Explored:';
PRINT '  ✓ Table partitioning';
PRINT '  ✓ Data compression';
PRINT '  ✓ Database snapshots';
PRINT '  ✓ Change Data Capture (CDC)';
PRINT '  ✓ Resource Governor';
PRINT '  ✓ Temporal tables';
PRINT '  ✓ Columnstore indexes';
GO
