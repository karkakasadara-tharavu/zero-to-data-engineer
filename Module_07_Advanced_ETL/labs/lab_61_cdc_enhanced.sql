/*
================================================================================
LAB 61 (ENHANCED): CHANGE DATA CAPTURE (CDC) - COMPLETE GUIDE
Module 07: Advanced ETL Patterns
================================================================================

WHAT YOU WILL LEARN:
✅ What CDC is and why it's essential for data engineering
✅ How CDC works under the hood
✅ Step-by-step implementation guide
✅ Querying change data effectively
✅ Building incremental ETL with CDC
✅ Performance and best practices
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)
DATABASE: SQL Server 2016+ (Enterprise/Developer Edition)

================================================================================
SECTION 1: UNDERSTANDING CDC - THE FUNDAMENTALS
================================================================================

WHAT IS CHANGE DATA CAPTURE (CDC)?
----------------------------------
CDC is a SQL Server feature that AUTOMATICALLY TRACKS all changes (inserts, 
updates, deletes) made to your tables and stores them in special "change tables."

Think of it as a "security camera" for your database - it records everything 
that happens, so you can replay or analyze changes later.

WHY IS CDC CRITICAL FOR DATA ENGINEERING?
-----------------------------------------
Without CDC (Full Load):
❌ Must reload ENTIRE table every time
❌ Hours to process millions of rows
❌ High resource consumption
❌ Can't identify what changed
❌ No audit trail

With CDC (Incremental Load):
✅ Only process CHANGED records
✅ Minutes instead of hours
✅ Minimal resource usage
✅ Know exactly what changed (and how)
✅ Complete audit history

REAL-WORLD EXAMPLE:
-------------------
E-commerce database with 10 million orders:
- Full load: Process 10M records daily = 3+ hours
- CDC: Process 10K new/changed records = 5 minutes

CDC SAVES 95%+ OF ETL TIME!

HOW CDC WORKS (Architecture):
-----------------------------
1. SQL Server TRANSACTION LOG records all changes
2. CDC CAPTURE JOB reads the transaction log
3. Changes are written to CDC CHANGE TABLES (cdc.dbo_TableName_CT)
4. Your ETL reads from change tables
5. CDC CLEANUP JOB removes old change data

┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│ Transaction │───▶│ CDC Capture  │───▶│ Change Tables│
│    Log      │    │    Job       │    │ (cdc.*_CT)   │
└─────────────┘    └──────────────┘    └──────────────┘
                                              │
                                              ▼
                                       ┌──────────────┐
                                       │  Your ETL    │
                                       │   Process    │
                                       └──────────────┘

PREREQUISITES:
--------------
- SQL Server Enterprise, Developer, or Evaluation Edition
- SQL Server Agent MUST be running (CDC uses Agent jobs)
- Database recovery model: FULL or BULK_LOGGED
- sysadmin or db_owner permissions
*/

USE master;
GO

-- ============================================================================
-- STEP 1: CREATE SAMPLE DATABASE
-- ============================================================================

-- Create demo database
IF DB_ID('CDC_Demo') IS NOT NULL
BEGIN
    ALTER DATABASE CDC_Demo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CDC_Demo;
END;
GO

CREATE DATABASE CDC_Demo;
GO

-- Set recovery model to FULL (required for CDC)
ALTER DATABASE CDC_Demo SET RECOVERY FULL;
GO

USE CDC_Demo;
GO

-- Create sample tables
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    Phone NVARCHAR(20),
    City NVARCHAR(100),
    State NVARCHAR(50),
    JoinDate DATE DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    Category NVARCHAR(100),
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL REFERENCES Customers(CustomerID),
    OrderDate DATETIME2 DEFAULT GETDATE(),
    TotalAmount DECIMAL(12,2),
    Status NVARCHAR(20) DEFAULT 'Pending',
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Insert sample data
INSERT INTO Customers (FirstName, LastName, Email, Phone, City, State)
VALUES 
    ('John', 'Smith', 'john.smith@email.com', '555-0101', 'New York', 'NY'),
    ('Sarah', 'Johnson', 'sarah.johnson@email.com', '555-0102', 'Los Angeles', 'CA'),
    ('Michael', 'Williams', 'michael.williams@email.com', '555-0103', 'Chicago', 'IL'),
    ('Emily', 'Brown', 'emily.brown@email.com', '555-0104', 'Houston', 'TX'),
    ('David', 'Jones', 'david.jones@email.com', '555-0105', 'Phoenix', 'AZ');

INSERT INTO Products (ProductName, Category, Price, StockQuantity)
VALUES
    ('Laptop Pro 15', 'Electronics', 1299.99, 50),
    ('Wireless Mouse', 'Electronics', 29.99, 200),
    ('Office Desk', 'Furniture', 449.99, 30),
    ('Ergonomic Chair', 'Furniture', 299.99, 45),
    ('LED Monitor 27"', 'Electronics', 349.99, 75);

PRINT 'Sample database created successfully!';
GO

-- ============================================================================
-- STEP 2: ENABLE CDC ON DATABASE
-- ============================================================================
/*
WHAT HAPPENS WHEN YOU ENABLE CDC:
1. System tables are created in the cdc schema
2. Two SQL Server Agent jobs are created:
   - Capture job: Reads transaction log and populates change tables
   - Cleanup job: Removes old change data (default: 3 days retention)
*/

-- Check current CDC status
SELECT 
    name AS DatabaseName,
    is_cdc_enabled,
    CASE WHEN is_cdc_enabled = 1 THEN '✅ Enabled' ELSE '❌ Disabled' END AS CDC_Status
FROM sys.databases
WHERE name = 'CDC_Demo';

-- Enable CDC on the database
EXEC sys.sp_cdc_enable_db;
PRINT '✅ CDC enabled on CDC_Demo database';
GO

-- Verify CDC was enabled
SELECT 
    name AS DatabaseName,
    is_cdc_enabled,
    CASE WHEN is_cdc_enabled = 1 THEN '✅ Enabled' ELSE '❌ Disabled' END AS CDC_Status
FROM sys.databases
WHERE name = 'CDC_Demo';

-- View CDC system objects created
SELECT 
    name AS ObjectName,
    type_desc AS ObjectType,
    create_date
FROM sys.objects
WHERE schema_id = SCHEMA_ID('cdc')
ORDER BY type_desc, name;

-- ============================================================================
-- STEP 3: ENABLE CDC ON TABLES
-- ============================================================================
/*
sp_cdc_enable_table PARAMETERS EXPLAINED:
-----------------------------------------
@source_schema     : Schema containing the table (e.g., 'dbo')
@source_name       : Table name to track
@role_name         : Database role that can access change data (NULL = db_owner only)
@capture_instance  : Name for this capture instance (optional, auto-generated)
@supports_net_changes: 
    0 = Only raw changes (before/after for updates)
    1 = Net changes (final state per row in time range)
@index_name        : Required if supports_net_changes = 1 (primary key index)
*/

-- Enable CDC on Customers table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Customers',
    @role_name = NULL,
    @supports_net_changes = 1;
PRINT '✅ CDC enabled on Customers table';
GO

-- Enable CDC on Products table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Products',
    @role_name = NULL,
    @supports_net_changes = 1;
PRINT '✅ CDC enabled on Products table';
GO

-- Enable CDC on Orders table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Orders',
    @role_name = NULL,
    @supports_net_changes = 1;
PRINT '✅ CDC enabled on Orders table';
GO

-- View all CDC-enabled tables
SELECT 
    source_schema,
    source_table,
    capture_instance,
    supports_net_changes,
    create_date
FROM cdc.change_tables;

-- ============================================================================
-- STEP 4: UNDERSTANDING THE CHANGE TABLE STRUCTURE
-- ============================================================================
/*
CHANGE TABLE COLUMNS (__$ prefix):
----------------------------------
__$start_lsn      : Log Sequence Number when change occurred
__$end_lsn        : Always NULL (reserved)
__$seqval         : Sequence within same transaction
__$operation      : Type of change:
                    1 = DELETE
                    2 = INSERT
                    3 = UPDATE (before image - old values)
                    4 = UPDATE (after image - new values)
__$update_mask    : Bitmask showing which columns changed

[Source Columns]  : All columns from the source table

LSN (Log Sequence Number):
--------------------------
LSN is a unique identifier for each transaction in the log.
Format: 0x0000001A:00000098:0001 (example)
LSNs are ALWAYS INCREASING - higher LSN = later change.
*/

-- View change table structure
EXEC sp_help 'cdc.dbo_Customers_CT';

-- View column mappings
SELECT 
    column_name,
    column_ordinal,
    column_type,
    is_computed
FROM cdc.captured_columns
WHERE capture_instance = 'dbo_Customers';

-- ============================================================================
-- STEP 5: GENERATE TEST CHANGES
-- ============================================================================

PRINT 'Generating changes...';

-- INSERT: Add new customers
INSERT INTO Customers (FirstName, LastName, Email, Phone, City, State)
VALUES 
    ('Alice', 'Williams', 'alice.williams@email.com', '555-0201', 'Seattle', 'WA'),
    ('Robert', 'Taylor', 'robert.taylor@email.com', '555-0202', 'Boston', 'MA'),
    ('Jennifer', 'Anderson', 'jennifer.anderson@email.com', '555-0203', 'Denver', 'CO');

WAITFOR DELAY '00:00:02';  -- Wait for capture job

-- UPDATE: Modify existing customers
UPDATE Customers
SET 
    City = 'San Francisco',
    State = 'CA',
    Phone = '555-9999',
    ModifiedDate = GETDATE()
WHERE Email = 'john.smith@email.com';

UPDATE Customers
SET 
    IsActive = 0,
    ModifiedDate = GETDATE()
WHERE Email = 'emily.brown@email.com';

WAITFOR DELAY '00:00:02';

-- DELETE: Remove a customer
DELETE FROM Customers
WHERE Email = 'alice.williams@email.com';

PRINT '✅ Test changes generated: 3 INSERTs, 2 UPDATEs, 1 DELETE';
GO

-- ============================================================================
-- STEP 6: QUERYING CDC DATA
-- ============================================================================
/*
TWO WAYS TO QUERY CDC DATA:

1. DIRECT QUERY on change table (cdc.dbo_TableName_CT)
   - Simple but requires manual LSN handling
   
2. CDC FUNCTIONS (recommended)
   - cdc.fn_cdc_get_all_changes_<instance>: All changes
   - cdc.fn_cdc_get_net_changes_<instance>: Net changes only
   - sys.fn_cdc_get_min_lsn: Get minimum available LSN
   - sys.fn_cdc_get_max_lsn: Get current maximum LSN
   - sys.fn_cdc_map_time_to_lsn: Convert datetime to LSN
*/

-- Method 1: Direct query (see raw change data)
SELECT 
    __$start_lsn,
    __$operation,
    CASE __$operation
        WHEN 1 THEN '🗑️ DELETE'
        WHEN 2 THEN '➕ INSERT'
        WHEN 3 THEN '📝 UPDATE (Before)'
        WHEN 4 THEN '📝 UPDATE (After)'
    END AS OperationType,
    CustomerID,
    FirstName,
    LastName,
    Email,
    City,
    State,
    IsActive
FROM cdc.dbo_Customers_CT
ORDER BY __$start_lsn DESC, __$seqval DESC;

-- Method 2: Using CDC Functions (RECOMMENDED)
DECLARE @FromLSN BINARY(10) = sys.fn_cdc_get_min_lsn('dbo_Customers');
DECLARE @ToLSN BINARY(10) = sys.fn_cdc_get_max_lsn();

PRINT 'Querying changes from LSN ' + CONVERT(VARCHAR(50), @FromLSN, 1) + 
      ' to ' + CONVERT(VARCHAR(50), @ToLSN, 1);

-- Get ALL changes (includes before/after for updates)
SELECT 
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE_BEFORE'
        WHEN 4 THEN 'UPDATE_AFTER'
    END AS Operation,
    sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS ChangeTime,
    CustomerID,
    FirstName,
    LastName,
    Email,
    City,
    IsActive
FROM cdc.fn_cdc_get_all_changes_dbo_Customers(@FromLSN, @ToLSN, 'all')
ORDER BY __$start_lsn, __$seqval;
GO

-- Get NET changes (final state per row - best for ETL!)
DECLARE @FromLSN BINARY(10) = sys.fn_cdc_get_min_lsn('dbo_Customers');
DECLARE @ToLSN BINARY(10) = sys.fn_cdc_get_max_lsn();

SELECT 
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 4 THEN 'UPDATE'
        WHEN 5 THEN 'INSERT_OR_UPDATE'
    END AS NetOperation,
    CustomerID,
    FirstName,
    LastName,
    Email,
    City,
    State,
    IsActive
FROM cdc.fn_cdc_get_net_changes_dbo_Customers(@FromLSN, @ToLSN, 'all')
ORDER BY CustomerID;
GO

-- ============================================================================
-- STEP 7: TIME-BASED CDC QUERIES
-- ============================================================================
/*
Often you want changes "since last ETL run" - use time-based queries.
*/

-- Get changes from the last hour
DECLARE @StartTime DATETIME = DATEADD(HOUR, -1, GETDATE());
DECLARE @EndTime DATETIME = GETDATE();

-- Convert times to LSN
DECLARE @StartLSN BINARY(10) = sys.fn_cdc_map_time_to_lsn('smallest greater than or equal', @StartTime);
DECLARE @EndLSN BINARY(10) = sys.fn_cdc_map_time_to_lsn('largest less than or equal', @EndTime);

-- Handle case where no changes exist in time range
IF @StartLSN IS NULL
    SET @StartLSN = sys.fn_cdc_get_min_lsn('dbo_Customers');

IF @EndLSN IS NULL
    SET @EndLSN = sys.fn_cdc_get_max_lsn();

PRINT 'Changes from ' + CONVERT(VARCHAR, @StartTime, 120) + ' to ' + CONVERT(VARCHAR, @EndTime, 120);

SELECT 
    sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS ChangeTime,
    CASE __$operation WHEN 1 THEN 'DELETE' WHEN 2 THEN 'INSERT' WHEN 4 THEN 'UPDATE' END AS Operation,
    CustomerID,
    FirstName,
    LastName,
    Email
FROM cdc.fn_cdc_get_net_changes_dbo_Customers(@StartLSN, @EndLSN, 'all');
GO

-- ============================================================================
-- STEP 8: BUILDING INCREMENTAL ETL WITH CDC
-- ============================================================================
/*
ETL PATTERN WITH CDC:
1. Track last processed LSN in a control table
2. Get current max LSN
3. Query changes between last and current LSN
4. Process changes (INSERT/UPDATE/DELETE in target)
5. Update control table with current LSN
*/

-- Create ETL control table
CREATE TABLE ETL_CDC_Control (
    ControlID INT IDENTITY(1,1) PRIMARY KEY,
    SourceTable NVARCHAR(255) NOT NULL,
    CaptureInstance NVARCHAR(255) NOT NULL,
    LastProcessedLSN BINARY(10) NOT NULL,
    LastProcessedTime DATETIME2 NOT NULL,
    RecordsProcessed INT DEFAULT 0,
    LastRunDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_CDC_Control UNIQUE (SourceTable)
);

-- Initialize control records
INSERT INTO ETL_CDC_Control (SourceTable, CaptureInstance, LastProcessedLSN, LastProcessedTime)
VALUES 
    ('dbo.Customers', 'dbo_Customers', 0x00000000000000000000, '2000-01-01'),
    ('dbo.Products', 'dbo_Products', 0x00000000000000000000, '2000-01-01'),
    ('dbo.Orders', 'dbo_Orders', 0x00000000000000000000, '2000-01-01');

-- Create target table (staging)
CREATE TABLE Staging_Customers (
    CustomerID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(255),
    Phone NVARCHAR(20),
    City NVARCHAR(100),
    State NVARCHAR(50),
    IsActive BIT,
    CDC_Operation NVARCHAR(20),
    CDC_ChangeTime DATETIME2,
    ETL_LoadDate DATETIME2 DEFAULT GETDATE()
);
GO

-- Create the incremental load procedure
CREATE OR ALTER PROCEDURE sp_CDC_IncrementalLoad_Customers
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastLSN BINARY(10);
    DECLARE @CurrentLSN BINARY(10);
    DECLARE @RowsProcessed INT = 0;
    DECLARE @Inserts INT = 0, @Updates INT = 0, @Deletes INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Step 1: Get last processed LSN
        SELECT @LastLSN = LastProcessedLSN
        FROM ETL_CDC_Control
        WHERE SourceTable = 'dbo.Customers';
        
        -- Step 2: Get current max LSN
        SELECT @CurrentLSN = sys.fn_cdc_get_max_lsn();
        
        -- Step 3: Check if there are new changes
        IF @LastLSN >= @CurrentLSN
        BEGIN
            PRINT '✓ No new changes to process';
            COMMIT;
            RETURN;
        END;
        
        -- Adjust LastLSN if it's the initial run
        IF @LastLSN = 0x00000000000000000000
            SET @LastLSN = sys.fn_cdc_get_min_lsn('dbo_Customers');
        
        -- Step 4: Get net changes into a temp table
        CREATE TABLE #Changes (
            Operation NVARCHAR(20),
            ChangeTime DATETIME2,
            CustomerID INT,
            FirstName NVARCHAR(50),
            LastName NVARCHAR(50),
            Email NVARCHAR(255),
            Phone NVARCHAR(20),
            City NVARCHAR(100),
            State NVARCHAR(50),
            IsActive BIT
        );
        
        INSERT INTO #Changes
        SELECT 
            CASE __$operation
                WHEN 1 THEN 'DELETE'
                WHEN 2 THEN 'INSERT'
                WHEN 4 THEN 'UPDATE'
                WHEN 5 THEN 'MERGE'
            END AS Operation,
            sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS ChangeTime,
            CustomerID,
            FirstName,
            LastName,
            Email,
            Phone,
            City,
            State,
            IsActive
        FROM cdc.fn_cdc_get_net_changes_dbo_Customers(@LastLSN, @CurrentLSN, 'all');
        
        SET @RowsProcessed = @@ROWCOUNT;
        
        -- Step 5: Apply changes to staging table
        
        -- Handle DELETEs
        DELETE s
        FROM Staging_Customers s
        INNER JOIN #Changes c ON s.CustomerID = c.CustomerID
        WHERE c.Operation = 'DELETE';
        
        SET @Deletes = @@ROWCOUNT;
        
        -- Handle INSERTs
        INSERT INTO Staging_Customers (CustomerID, FirstName, LastName, Email, Phone, City, State, IsActive, CDC_Operation, CDC_ChangeTime)
        SELECT CustomerID, FirstName, LastName, Email, Phone, City, State, IsActive, Operation, ChangeTime
        FROM #Changes
        WHERE Operation = 'INSERT';
        
        SET @Inserts = @@ROWCOUNT;
        
        -- Handle UPDATEs (delete then insert for simplicity)
        DELETE s
        FROM Staging_Customers s
        INNER JOIN #Changes c ON s.CustomerID = c.CustomerID
        WHERE c.Operation IN ('UPDATE', 'MERGE');
        
        INSERT INTO Staging_Customers (CustomerID, FirstName, LastName, Email, Phone, City, State, IsActive, CDC_Operation, CDC_ChangeTime)
        SELECT CustomerID, FirstName, LastName, Email, Phone, City, State, IsActive, Operation, ChangeTime
        FROM #Changes
        WHERE Operation IN ('UPDATE', 'MERGE');
        
        SET @Updates = @@ROWCOUNT;
        
        -- Step 6: Update control table
        UPDATE ETL_CDC_Control
        SET 
            LastProcessedLSN = @CurrentLSN,
            LastProcessedTime = GETDATE(),
            RecordsProcessed = @RowsProcessed,
            LastRunDate = GETDATE()
        WHERE SourceTable = 'dbo.Customers';
        
        DROP TABLE #Changes;
        
        COMMIT;
        
        PRINT '=====================================';
        PRINT '✅ CDC Incremental Load Complete';
        PRINT '   Total Records: ' + CAST(@RowsProcessed AS VARCHAR);
        PRINT '   Inserts: ' + CAST(@Inserts AS VARCHAR);
        PRINT '   Updates: ' + CAST(@Updates AS VARCHAR);
        PRINT '   Deletes: ' + CAST(@Deletes AS VARCHAR);
        PRINT '=====================================';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        
        PRINT '❌ ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Execute the incremental load
EXEC sp_CDC_IncrementalLoad_Customers;

-- View results
SELECT * FROM Staging_Customers ORDER BY CustomerID;
SELECT * FROM ETL_CDC_Control;
GO

-- ============================================================================
-- STEP 9: CDC MONITORING AND MAINTENANCE
-- ============================================================================

-- View CDC jobs
SELECT 
    j.name AS JobName,
    j.enabled AS IsEnabled,
    j.description
FROM msdb.dbo.sysjobs j
WHERE j.name LIKE 'cdc%'
ORDER BY j.name;

-- Check CDC latency (time since last capture)
SELECT 
    ct.capture_instance,
    ct.start_lsn,
    sys.fn_cdc_map_lsn_to_time(ct.start_lsn) AS StartTime,
    sys.fn_cdc_map_lsn_to_time(sys.fn_cdc_get_max_lsn()) AS LastCaptureTime,
    DATEDIFF(SECOND, sys.fn_cdc_map_lsn_to_time(sys.fn_cdc_get_max_lsn()), GETDATE()) AS LatencySeconds
FROM cdc.change_tables ct;

-- Check change table sizes
SELECT 
    OBJECT_NAME(ct.source_object_id) AS SourceTable,
    ct.capture_instance,
    p.rows AS ChangeRowCount,
    CAST(ROUND((a.total_pages * 8) / 1024.0, 2) AS DECIMAL(10,2)) AS SizeMB
FROM cdc.change_tables ct
INNER JOIN sys.partitions p ON p.object_id = OBJECT_ID('cdc.' + ct.capture_instance + '_CT')
INNER JOIN sys.allocation_units a ON a.container_id = p.partition_id
WHERE p.index_id <= 1;

-- Manual cleanup (removes changes older than specified minutes)
DECLARE @RetentionMinutes INT = 4320;  -- 3 days = 72 hours = 4320 minutes
EXEC sys.sp_cdc_cleanup_change_table
    @capture_instance = 'dbo_Customers',
    @low_water_mark = NULL,
    @threshold = 5000;  -- Max rows to delete per batch
GO

-- ============================================================================
-- STEP 10: CDC BEST PRACTICES AND TROUBLESHOOTING
-- ============================================================================
/*
================================================================================
BEST PRACTICES:
================================================================================

1. MONITOR CDC LAG:
   - Check latency regularly
   - Set up alerts if capture falls behind
   
2. MANAGE RETENTION:
   - Default is 3 days - adjust based on ETL frequency
   - Run cleanup during off-peak hours
   
3. HANDLE SCHEMA CHANGES:
   - Adding columns: Create new capture instance
   - Dropping columns: Old capture instance still works
   - Best practice: Disable old, enable new capture instance

4. PERFORMANCE:
   - CDC adds ~10-15% overhead on write operations
   - Use net_changes for dimension tables
   - Use all_changes for audit requirements
   
5. ERROR HANDLING:
   - Always track LSN in control tables
   - Handle reprocessing scenarios
   - Log failed records for investigation

================================================================================
COMMON ISSUES AND SOLUTIONS:
================================================================================

ISSUE 1: CDC capture job not running
SOLUTION: 
- Check SQL Server Agent is running
- Verify job is enabled: SELECT * FROM msdb.dbo.sysjobs WHERE name LIKE 'cdc%'
- Start job manually: EXEC msdb.dbo.sp_start_job @job_name = 'cdc.CDC_Demo_capture'

ISSUE 2: Changes not appearing in change table
SOLUTION:
- Wait for capture job interval (default 5 seconds)
- Check transaction log hasn't been truncated
- Verify CDC is enabled: SELECT is_cdc_enabled FROM sys.databases

ISSUE 3: "The specified @low_water_mark is greater than the start_lsn"
SOLUTION:
- Your LSN tracking is ahead of available changes
- Reset to minimum LSN: sys.fn_cdc_get_min_lsn('capture_instance')

ISSUE 4: Change table growing too large
SOLUTION:
- Run cleanup more frequently
- Reduce retention period
- Process changes more frequently in ETL

================================================================================
*/

-- ============================================================================
-- SECTION 11: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: CDC - Top 15 Questions
================================================================================

Q1: What is Change Data Capture (CDC)?
A1: CDC is a SQL Server feature that tracks INSERT, UPDATE, and DELETE 
    operations on tables and records the changes in special "change tables."
    It enables incremental data loading for ETL processes.

Q2: How does CDC work under the hood?
A2: CDC works by:
    1. Reading the SQL Server transaction log
    2. A capture job extracts changes asynchronously
    3. Changes are stored in cdc.schema_table_CT tables
    4. Cleanup job removes old changes based on retention

Q3: What is an LSN and why is it important?
A3: LSN (Log Sequence Number) uniquely identifies each transaction in the log.
    - Monotonically increasing (higher = later)
    - Used to track "where you left off" in ETL
    - Critical for reliable incremental processing

Q4: What's the difference between fn_cdc_get_all_changes and fn_cdc_get_net_changes?
A4: 
    all_changes: Returns every change including before/after for updates
                 Use for: Audit trails, debugging
    
    net_changes: Returns only final state per row in the time range
                 Use for: ETL loading (most efficient)

Q5: What are the __$operation values?
A5: 
    1 = DELETE
    2 = INSERT
    3 = UPDATE (before image - old values)
    4 = UPDATE (after image - new values)
    5 = MERGE (used with net_changes)

Q6: What SQL Server editions support CDC?
A6: Enterprise, Developer, and Evaluation editions only.
    Standard and Express do NOT support CDC.
    Alternative for Standard: Change Tracking (simpler, less info)

Q7: What happens to CDC when the source table schema changes?
A7: 
    - Adding columns: New columns NOT captured (need new capture instance)
    - Dropping columns: Existing capture continues working
    - Renaming: Capture continues with old column names
    Best practice: Create new capture instance after schema changes.

Q8: How do you handle initial load with CDC?
A8: Two approaches:
    1. Full load first, then enable CDC for incremental
    2. Enable CDC first, track initial LSN, full load, then incremental
    Always record your starting LSN!

Q9: What is the CDC retention period and how do you change it?
A9: Default is 3 days (4320 minutes).
    Change with: EXEC sys.sp_cdc_change_job @job_type = 'cleanup', 
                                            @retention = 7200;  -- 5 days
    
Q10: What is the __$update_mask column?
A10: A bitmask showing which columns changed in an UPDATE.
     Each bit represents a column (by ordinal position).
     Use sys.fn_cdc_is_bit_set() to check specific columns.

Q11: How does CDC affect database performance?
A11: 
     - Adds 10-15% overhead on write operations
     - Capture job runs asynchronously (minimal impact)
     - Change tables consume disk space
     - Transaction log retained longer
     Trade-off: Worth it for efficient incremental ETL!

Q12: What is a capture instance?
A12: A capture instance is the configuration for tracking a table.
     - Named: schema_tablename (e.g., dbo_Customers)
     - Defines which columns to capture
     - Each table can have up to 2 capture instances

Q13: How do you reprocess failed CDC data?
A13: Store the LSN from failed runs:
     1. Don't update LastProcessedLSN on failure
     2. Rerun ETL - it will pick up from last good LSN
     3. Implement idempotent loading (MERGE/UPSERT)

Q14: Compare CDC vs Change Tracking.
A14: 
     CDC:
     - Captures actual data values (before/after)
     - Requires Enterprise edition
     - More storage overhead
     - Full audit capability
     
     Change Tracking:
     - Only tracks which rows changed (not values)
     - Available in Standard edition
     - Less storage
     - Good for sync scenarios

Q15: What happens if the transaction log is truncated before CDC processes it?
A15: Data loss! The capture job cannot read truncated log entries.
     Prevention:
     - Monitor CDC latency
     - Don't shrink log aggressively
     - Ensure capture job is running
     - Consider longer log retention

================================================================================
COMMON CDC INTERVIEW SCENARIO:
================================================================================
"Design an incremental ETL process using CDC for a data warehouse refresh."

SOLUTION:
1. Enable CDC on source tables
2. Create control table to track LSNs per table
3. Initial load: Full extract, record starting LSN
4. Incremental load procedure:
   - Read last processed LSN from control table
   - Get current max LSN
   - Query net_changes between LSNs
   - Apply changes to target (MERGE/UPSERT)
   - Update control table with new LSN
5. Schedule via SQL Agent or Airflow
6. Monitor: Latency, failures, data volumes

================================================================================
*/

-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
/*
-- Disable CDC on tables
EXEC sys.sp_cdc_disable_table 
    @source_schema = 'dbo', 
    @source_name = 'Customers',
    @capture_instance = 'dbo_Customers';

-- Disable CDC on database
EXEC sys.sp_cdc_disable_db;

-- Drop demo database
USE master;
DROP DATABASE CDC_Demo;
*/

/*
================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand what CDC is and why it matters
□ Enabled CDC on database and tables
□ Understand change table structure and __$ columns
□ Generated and captured INSERT/UPDATE/DELETE changes
□ Query changes using CDC functions
□ Built incremental ETL procedure with LSN tracking
□ Understand monitoring and maintenance
□ Know CDC best practices and troubleshooting
□ Can answer interview questions confidently

NEXT LAB: Lab 62 - Slowly Changing Dimensions
================================================================================
*/
