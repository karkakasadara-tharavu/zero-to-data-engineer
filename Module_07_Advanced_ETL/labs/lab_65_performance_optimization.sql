/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  MODULE 07: ADVANCED ETL PATTERNS                                            ║
║  LAB 65: ETL PERFORMANCE OPTIMIZATION                                        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Learning Objectives:                                                        ║
║  • Implement batch processing and chunking strategies                       ║
║  • Optimize parallel load patterns                                          ║
║  • Master index management during ETL operations                            ║
║  • Apply minimal logging techniques                                         ║
║  • Tune statistics and query performance                                    ║
║  • Monitor and troubleshoot ETL bottlenecks                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE DataEngineerTraining;
GO

-- ============================================================================
-- SECTION 1: PERFORMANCE BOTTLENECKS IN ETL
-- ============================================================================

/*
Common ETL Performance Bottlenecks:

┌─────────────────────┬────────────────────────────────────────────────────────┐
│ Category            │ Issue                                                  │
├─────────────────────┼────────────────────────────────────────────────────────┤
│ I/O Bound           │ Slow disk, network latency, log file contention       │
│ CPU Bound           │ Complex transformations, row-by-row processing        │
│ Memory Bound        │ Large sorts, hash operations, insufficient buffer     │
│ Lock Contention     │ Table locks during loads, blocking queries            │
│ Index Overhead      │ Index maintenance during bulk inserts                 │
│ Transaction Log     │ Excessive logging, checkpoint storms                  │
│ Query Optimizer     │ Bad execution plans, missing statistics              │
└─────────────────────┴────────────────────────────────────────────────────────┘
*/

-- Create performance testing schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'perf')
    EXEC('CREATE SCHEMA perf');
GO

-- Create sample large tables for testing
DROP TABLE IF EXISTS perf.LargeSourceTable;
CREATE TABLE perf.LargeSourceTable (
    RowID               INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID          INT NOT NULL,
    OrderDate           DATE NOT NULL,
    ProductID           INT NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(10,2) NOT NULL,
    TotalAmount         DECIMAL(12,2) NOT NULL,
    Region              NVARCHAR(50),
    Category            NVARCHAR(50),
    SubCategory         NVARCHAR(50),
    Description         NVARCHAR(500),
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- Generate test data (100,000 rows)
PRINT 'Generating test data...';
GO

;WITH Numbers AS (
    SELECT TOP (100000) 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO perf.LargeSourceTable (CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category, SubCategory, Description)
SELECT 
    ABS(CHECKSUM(NEWID())) % 10000 + 1 AS CustomerID,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()) AS OrderDate,
    ABS(CHECKSUM(NEWID())) % 1000 + 1 AS ProductID,
    ABS(CHECKSUM(NEWID())) % 100 + 1 AS Quantity,
    CAST(ABS(CHECKSUM(NEWID())) % 10000 / 100.0 + 1 AS DECIMAL(10,2)) AS UnitPrice,
    CAST(ABS(CHECKSUM(NEWID())) % 100000 / 100.0 AS DECIMAL(12,2)) AS TotalAmount,
    CASE ABS(CHECKSUM(NEWID())) % 4 WHEN 0 THEN 'North' WHEN 1 THEN 'South' WHEN 2 THEN 'East' ELSE 'West' END AS Region,
    CASE ABS(CHECKSUM(NEWID())) % 5 WHEN 0 THEN 'Electronics' WHEN 1 THEN 'Clothing' WHEN 2 THEN 'Books' WHEN 3 THEN 'Home' ELSE 'Sports' END AS Category,
    'SubCat_' + CAST(ABS(CHECKSUM(NEWID())) % 20 + 1 AS VARCHAR(10)) AS SubCategory,
    REPLICATE('X', ABS(CHECKSUM(NEWID())) % 200 + 50) AS Description
FROM Numbers;

PRINT 'Test data generated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' rows';
GO

-- ============================================================================
-- SECTION 2: BATCH PROCESSING AND CHUNKING
-- ============================================================================

/*
Why Batch Processing?
- Reduces transaction log growth
- Allows checkpointing between batches
- Enables progress tracking and recovery
- Reduces lock duration
- Memory-efficient for large datasets
*/

-- Create target table
DROP TABLE IF EXISTS perf.TargetTable;
CREATE TABLE perf.TargetTable (
    RowID               INT PRIMARY KEY,
    CustomerID          INT NOT NULL,
    OrderDate           DATE NOT NULL,
    ProductID           INT NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(10,2) NOT NULL,
    TotalAmount         DECIMAL(12,2) NOT NULL,
    Region              NVARCHAR(50),
    Category            NVARCHAR(50),
    ProcessedDate       DATETIME2 DEFAULT GETDATE()
);
GO

-- Simple batch processing procedure
CREATE OR ALTER PROCEDURE perf.usp_LoadInBatches
    @BatchSize      INT = 10000,
    @ShowProgress   BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @BatchStart INT = 0;
    DECLARE @BatchEnd INT;
    DECLARE @TotalRows INT;
    DECLARE @RowsProcessed INT = 0;
    DECLARE @BatchNum INT = 0;
    DECLARE @BatchStartTime DATETIME2;
    
    -- Get total row count
    SELECT @TotalRows = MAX(RowID) FROM perf.LargeSourceTable;
    
    PRINT 'Starting batch load of ' + CAST(@TotalRows AS VARCHAR(20)) + ' rows...';
    PRINT 'Batch size: ' + CAST(@BatchSize AS VARCHAR(20));
    PRINT '----------------------------------------';
    
    -- Process in batches
    WHILE @BatchStart < @TotalRows
    BEGIN
        SET @BatchNum = @BatchNum + 1;
        SET @BatchEnd = @BatchStart + @BatchSize;
        SET @BatchStartTime = GETDATE();
        
        BEGIN TRY
            BEGIN TRANSACTION;
            
            INSERT INTO perf.TargetTable (RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category)
            SELECT RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category
            FROM perf.LargeSourceTable
            WHERE RowID > @BatchStart AND RowID <= @BatchEnd;
            
            SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;
            
            COMMIT TRANSACTION;
            
            IF @ShowProgress = 1
            BEGIN
                PRINT 'Batch ' + CAST(@BatchNum AS VARCHAR(10)) + 
                      ': Rows ' + CAST(@BatchStart + 1 AS VARCHAR(20)) + 
                      ' - ' + CAST(@BatchEnd AS VARCHAR(20)) +
                      ' (' + CAST(DATEDIFF(MILLISECOND, @BatchStartTime, GETDATE()) AS VARCHAR(20)) + 'ms)';
            END
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            PRINT 'Error in batch ' + CAST(@BatchNum AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
            -- Continue with next batch (skip failed batch)
        END CATCH
        
        SET @BatchStart = @BatchEnd;
    END
    
    PRINT '----------------------------------------';
    PRINT 'Load complete!';
    PRINT 'Total rows: ' + CAST(@RowsProcessed AS VARCHAR(20));
    PRINT 'Total time: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(20)) + ' seconds';
    PRINT 'Rows/second: ' + CAST(@RowsProcessed / NULLIF(DATEDIFF(SECOND, @StartTime, GETDATE()), 0) AS VARCHAR(20));
END;
GO

-- Test batch processing
TRUNCATE TABLE perf.TargetTable;
EXEC perf.usp_LoadInBatches @BatchSize = 10000;
GO

-- ============================================================================
-- SECTION 3: MINIMAL LOGGING FOR BULK OPERATIONS
-- ============================================================================

/*
Minimal Logging Requirements:
1. Database in SIMPLE or BULK_LOGGED recovery model
2. TABLOCK hint (or table-level lock)
3. Target table is empty OR has no indexes
4. Using INSERT...SELECT, SELECT INTO, or BULK INSERT

Benefits:
- Dramatically reduces log I/O
- Can improve load performance 10x or more
*/

-- Check current recovery model
SELECT name, recovery_model_desc 
FROM sys.databases 
WHERE name = DB_NAME();
GO

-- Compare logging methods
DROP TABLE IF EXISTS perf.MinimalLogTest;
CREATE TABLE perf.MinimalLogTest (
    RowID               INT,
    CustomerID          INT,
    OrderDate           DATE,
    TotalAmount         DECIMAL(12,2)
);
GO

-- Method 1: Normal INSERT (full logging)
PRINT 'Method 1: Full Logging INSERT...';
DECLARE @Start1 DATETIME2 = GETDATE();
DECLARE @LogStart1 BIGINT = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Log Bytes Flushed/sec' AND instance_name = DB_NAME());

INSERT INTO perf.MinimalLogTest (RowID, CustomerID, OrderDate, TotalAmount)
SELECT TOP 50000 RowID, CustomerID, OrderDate, TotalAmount
FROM perf.LargeSourceTable;

DECLARE @LogEnd1 BIGINT = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Log Bytes Flushed/sec' AND instance_name = DB_NAME());
PRINT 'Full logging: ' + CAST(DATEDIFF(MILLISECOND, @Start1, GETDATE()) AS VARCHAR(20)) + 'ms';
GO

-- Method 2: WITH TABLOCK (minimal logging when possible)
TRUNCATE TABLE perf.MinimalLogTest;
PRINT 'Method 2: WITH TABLOCK (minimal logging)...';
DECLARE @Start2 DATETIME2 = GETDATE();

INSERT INTO perf.MinimalLogTest WITH (TABLOCK) (RowID, CustomerID, OrderDate, TotalAmount)
SELECT TOP 50000 RowID, CustomerID, OrderDate, TotalAmount
FROM perf.LargeSourceTable;

PRINT 'TABLOCK: ' + CAST(DATEDIFF(MILLISECOND, @Start2, GETDATE()) AS VARCHAR(20)) + 'ms';
GO

-- Method 3: SELECT INTO (minimal logging)
DROP TABLE IF EXISTS perf.MinimalLogTest2;
PRINT 'Method 3: SELECT INTO (minimal logging)...';
DECLARE @Start3 DATETIME2 = GETDATE();

SELECT TOP 50000 RowID, CustomerID, OrderDate, TotalAmount
INTO perf.MinimalLogTest2
FROM perf.LargeSourceTable;

PRINT 'SELECT INTO: ' + CAST(DATEDIFF(MILLISECOND, @Start3, GETDATE()) AS VARCHAR(20)) + 'ms';
GO

-- ============================================================================
-- SECTION 4: INDEX MANAGEMENT DURING LOADS
-- ============================================================================

/*
Index Strategy for Large Loads:
1. Drop non-clustered indexes before load
2. Load data (minimally logged if possible)
3. Rebuild indexes with SORT_IN_TEMPDB
4. Update statistics

For small incremental loads: Keep indexes
For large batch loads: Drop/disable then rebuild
*/

-- Create table with indexes
DROP TABLE IF EXISTS perf.IndexedTable;
CREATE TABLE perf.IndexedTable (
    RowID               INT PRIMARY KEY CLUSTERED,
    CustomerID          INT NOT NULL,
    OrderDate           DATE NOT NULL,
    ProductID           INT NOT NULL,
    Region              NVARCHAR(50),
    Category            NVARCHAR(50),
    TotalAmount         DECIMAL(12,2)
);
GO

-- Create multiple indexes
CREATE NONCLUSTERED INDEX IX_Customer ON perf.IndexedTable(CustomerID);
CREATE NONCLUSTERED INDEX IX_OrderDate ON perf.IndexedTable(OrderDate);
CREATE NONCLUSTERED INDEX IX_ProductRegion ON perf.IndexedTable(ProductID, Region);
CREATE NONCLUSTERED INDEX IX_Category ON perf.IndexedTable(Category) INCLUDE (TotalAmount);
GO

-- Procedure to manage indexes during load
CREATE OR ALTER PROCEDURE perf.usp_LoadWithIndexManagement
    @DisableIndexes     BIT = 1,
    @RebuildAfterLoad   BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @IndexName NVARCHAR(200);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Step 1: Disable non-clustered indexes
    IF @DisableIndexes = 1
    BEGIN
        PRINT 'Disabling non-clustered indexes...';
        
        DECLARE index_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT name 
            FROM sys.indexes 
            WHERE object_id = OBJECT_ID('perf.IndexedTable')
            AND type = 2  -- Non-clustered
            AND is_disabled = 0;
        
        OPEN index_cursor;
        FETCH NEXT FROM index_cursor INTO @IndexName;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON perf.IndexedTable DISABLE';
            EXEC sp_executesql @SQL;
            PRINT '  Disabled: ' + @IndexName;
            FETCH NEXT FROM index_cursor INTO @IndexName;
        END
        
        CLOSE index_cursor;
        DEALLOCATE index_cursor;
    END
    
    -- Step 2: Load data (with TABLOCK for minimal logging)
    PRINT 'Loading data...';
    DECLARE @LoadStart DATETIME2 = GETDATE();
    
    INSERT INTO perf.IndexedTable WITH (TABLOCK) (RowID, CustomerID, OrderDate, ProductID, Region, Category, TotalAmount)
    SELECT RowID, CustomerID, OrderDate, ProductID, Region, Category, TotalAmount
    FROM perf.LargeSourceTable;
    
    PRINT 'Load time: ' + CAST(DATEDIFF(MILLISECOND, @LoadStart, GETDATE()) AS VARCHAR(20)) + 'ms';
    
    -- Step 3: Rebuild indexes
    IF @RebuildAfterLoad = 1
    BEGIN
        PRINT 'Rebuilding indexes...';
        DECLARE @RebuildStart DATETIME2 = GETDATE();
        
        ALTER INDEX ALL ON perf.IndexedTable REBUILD 
            WITH (SORT_IN_TEMPDB = ON, ONLINE = OFF, FILLFACTOR = 90);
        
        PRINT 'Rebuild time: ' + CAST(DATEDIFF(MILLISECOND, @RebuildStart, GETDATE()) AS VARCHAR(20)) + 'ms';
    END
    
    -- Step 4: Update statistics
    PRINT 'Updating statistics...';
    UPDATE STATISTICS perf.IndexedTable WITH FULLSCAN;
    
    PRINT '----------------------------------------';
    PRINT 'Total time: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(20)) + ' seconds';
END;
GO

-- Compare: Load WITH index management
TRUNCATE TABLE perf.IndexedTable;
PRINT 'Load WITH index management:';
EXEC perf.usp_LoadWithIndexManagement @DisableIndexes = 1, @RebuildAfterLoad = 1;
GO

-- Compare: Load WITHOUT index management (indexes remain enabled)
TRUNCATE TABLE perf.IndexedTable;

-- Re-enable indexes first
ALTER INDEX ALL ON perf.IndexedTable REBUILD;
GO

PRINT 'Load WITHOUT index management:';
DECLARE @Start DATETIME2 = GETDATE();

INSERT INTO perf.IndexedTable (RowID, CustomerID, OrderDate, ProductID, Region, Category, TotalAmount)
SELECT RowID, CustomerID, OrderDate, ProductID, Region, Category, TotalAmount
FROM perf.LargeSourceTable;

PRINT 'Direct load time: ' + CAST(DATEDIFF(MILLISECOND, @Start, GETDATE()) AS VARCHAR(20)) + 'ms';
GO

-- ============================================================================
-- SECTION 5: PARALLEL LOAD PATTERNS
-- ============================================================================

/*
Parallel Loading Strategies:
1. Partition by range (date, ID ranges)
2. Partition by category (region, product type)
3. Multiple concurrent connections
4. Partitioned tables with parallel switch

Note: True parallel execution requires multiple sessions/connections
*/

-- Create procedure for range-based parallel loading
CREATE OR ALTER PROCEDURE perf.usp_LoadByRange
    @RangeStart     INT,
    @RangeEnd       INT,
    @RangeName      NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    
    INSERT INTO perf.TargetTable (RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category)
    SELECT RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category
    FROM perf.LargeSourceTable
    WHERE RowID >= @RangeStart AND RowID < @RangeEnd;
    
    PRINT @RangeName + ': Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + 
          ' rows in ' + CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS VARCHAR(20)) + 'ms';
END;
GO

-- Simulate parallel execution (in reality, these would run in separate sessions)
TRUNCATE TABLE perf.TargetTable;

PRINT 'Simulating parallel load by range...';
PRINT '(In production, run each in separate SSMS window/connection)';
PRINT '';

-- Range 1: 1-25000
EXEC perf.usp_LoadByRange @RangeStart = 1, @RangeEnd = 25001, @RangeName = 'Range 1 (1-25000)';

-- Range 2: 25001-50000
EXEC perf.usp_LoadByRange @RangeStart = 25001, @RangeEnd = 50001, @RangeName = 'Range 2 (25001-50000)';

-- Range 3: 50001-75000
EXEC perf.usp_LoadByRange @RangeStart = 50001, @RangeEnd = 75001, @RangeName = 'Range 3 (50001-75000)';

-- Range 4: 75001-100000
EXEC perf.usp_LoadByRange @RangeStart = 75001, @RangeEnd = 100001, @RangeName = 'Range 4 (75001-100000)';
GO

-- ============================================================================
-- SECTION 6: PARTITION SWITCHING FOR FAST LOADS
-- ============================================================================

/*
Partition Switching:
- Near-instantaneous "load" via metadata operation
- Load into staging table, then switch into main table
- Requires aligned indexes and constraints
*/

-- Create partitioned fact table (simplified example)
-- Note: Requires partition function and scheme in production

DROP TABLE IF EXISTS perf.StagingForSwitch;
CREATE TABLE perf.StagingForSwitch (
    OrderDate           DATE NOT NULL,
    CustomerID          INT NOT NULL,
    ProductID           INT NOT NULL,
    TotalAmount         DECIMAL(12,2),
    CONSTRAINT CHK_Staging_Date CHECK (OrderDate >= '2024-01-01' AND OrderDate < '2024-02-01')
);
GO

-- Load into staging
INSERT INTO perf.StagingForSwitch (OrderDate, CustomerID, ProductID, TotalAmount)
SELECT TOP 10000 OrderDate, CustomerID, ProductID, TotalAmount
FROM perf.LargeSourceTable
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2024-02-01';
GO

PRINT 'Staging table loaded with ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' rows';
PRINT 'In production, you would SWITCH this partition into the main table';
GO

-- ============================================================================
-- SECTION 7: QUERY OPTIMIZATION FOR ETL
-- ============================================================================

/*
ETL Query Optimization Tips:
1. Use appropriate JOIN types
2. Filter early (predicate pushdown)
3. Avoid functions on join columns
4. Use OPTION hints when needed
5. Avoid cursors - use set-based operations
*/

-- Create sample dimension tables
DROP TABLE IF EXISTS perf.DimCustomer;
CREATE TABLE perf.DimCustomer (
    CustomerKey         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID          INT UNIQUE,
    CustomerName        NVARCHAR(100)
);
GO

INSERT INTO perf.DimCustomer (CustomerID, CustomerName)
SELECT DISTINCT CustomerID, 'Customer_' + CAST(CustomerID AS VARCHAR(10))
FROM perf.LargeSourceTable;
GO

-- Bad pattern: Function on join column
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

PRINT 'Bad pattern: Function on join column';
SELECT COUNT(*)
FROM perf.LargeSourceTable s
INNER JOIN perf.DimCustomer d ON CAST(s.CustomerID AS VARCHAR(10)) = CAST(d.CustomerID AS VARCHAR(10));
GO

-- Good pattern: Direct join
PRINT 'Good pattern: Direct join';
SELECT COUNT(*)
FROM perf.LargeSourceTable s
INNER JOIN perf.DimCustomer d ON s.CustomerID = d.CustomerID;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Using query hints for ETL
-- OPTION (MAXDOP 4) - Control parallelism
-- OPTION (HASH JOIN) - Force join type
-- OPTION (RECOMPILE) - Fresh plan each execution

-- Example with hints
SELECT COUNT(*)
FROM perf.LargeSourceTable s
INNER JOIN perf.DimCustomer d ON s.CustomerID = d.CustomerID
OPTION (MAXDOP 4, HASH JOIN);
GO

-- ============================================================================
-- SECTION 8: MONITORING ETL PERFORMANCE
-- ============================================================================

-- Create performance monitoring views
CREATE OR ALTER VIEW perf.vw_ETLWaitStats
AS
SELECT 
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    max_wait_time_ms,
    signal_wait_time_ms,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS DECIMAL(5,2)) AS wait_pct
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
    'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
    'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE',
    'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
    'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
    'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
    'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
    'ONDEMAND_TASK_QUEUE', 'BROKER_EVENTHANDLER', 'SLEEP_BPOOL_FLUSH',
    'DIRTY_PAGE_POLL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION'
)
AND wait_time_ms > 0;
GO

-- I/O Statistics view
CREATE OR ALTER VIEW perf.vw_TableIOStats
AS
SELECT 
    OBJECT_SCHEMA_NAME(ios.object_id) + '.' + OBJECT_NAME(ios.object_id) AS TableName,
    SUM(ios.leaf_insert_count) AS LeafInserts,
    SUM(ios.leaf_update_count) AS LeafUpdates,
    SUM(ios.leaf_delete_count) AS LeafDeletes,
    SUM(ios.range_scan_count) AS RangeScans,
    SUM(ios.singleton_lookup_count) AS Lookups,
    SUM(ios.page_latch_wait_count) AS PageLatchWaits,
    SUM(ios.page_latch_wait_in_ms) AS PageLatchWaitMs,
    SUM(ios.row_lock_count) AS RowLocks,
    SUM(ios.row_lock_wait_count) AS RowLockWaits
FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ios
WHERE OBJECT_SCHEMA_NAME(ios.object_id) = 'perf'
GROUP BY ios.object_id;
GO

-- Query execution stats
CREATE OR ALTER VIEW perf.vw_QueryPerformance
AS
SELECT TOP 20
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2)+1) AS query_text,
    qs.execution_count,
    qs.total_worker_time / 1000 AS total_cpu_ms,
    qs.total_worker_time / qs.execution_count / 1000 AS avg_cpu_ms,
    qs.total_elapsed_time / 1000 AS total_duration_ms,
    qs.total_elapsed_time / qs.execution_count / 1000 AS avg_duration_ms,
    qs.total_logical_reads,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    qs.last_execution_time
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.dbid = DB_ID()
ORDER BY qs.total_worker_time DESC;
GO

-- Display monitoring data
SELECT * FROM perf.vw_ETLWaitStats ORDER BY wait_time_ms DESC;
SELECT * FROM perf.vw_TableIOStats;
SELECT * FROM perf.vw_QueryPerformance;
GO

-- ============================================================================
-- SECTION 9: PERFORMANCE BENCHMARKING FRAMEWORK
-- ============================================================================

-- Create benchmarking table
DROP TABLE IF EXISTS perf.BenchmarkResults;
CREATE TABLE perf.BenchmarkResults (
    BenchmarkID         INT IDENTITY(1,1) PRIMARY KEY,
    TestName            NVARCHAR(100),
    TestDescription     NVARCHAR(500),
    RowCount            INT,
    DurationMs          INT,
    RowsPerSecond       DECIMAL(12,2),
    LogicalReads        BIGINT,
    PhysicalReads       BIGINT,
    CPUTime             INT,
    TestDate            DATETIME2 DEFAULT GETDATE()
);
GO

-- Benchmarking procedure
CREATE OR ALTER PROCEDURE perf.usp_RunBenchmark
    @TestName           NVARCHAR(100),
    @TestDescription    NVARCHAR(500),
    @TestSQL            NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @EndTime DATETIME2;
    DECLARE @RowCount INT;
    DECLARE @LogicalReads BIGINT, @PhysicalReads BIGINT;
    DECLARE @CPUTime INT;
    
    -- Get baseline I/O stats
    DECLARE @LogicalReadsBefore BIGINT = (
        SELECT SUM(num_of_reads) FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL)
    );
    
    -- Execute test
    EXEC sp_executesql @TestSQL;
    SET @RowCount = @@ROWCOUNT;
    SET @EndTime = GETDATE();
    
    -- Get ending I/O stats
    DECLARE @LogicalReadsAfter BIGINT = (
        SELECT SUM(num_of_reads) FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL)
    );
    
    -- Record results
    INSERT INTO perf.BenchmarkResults (TestName, TestDescription, RowCount, DurationMs, RowsPerSecond, LogicalReads)
    VALUES (
        @TestName,
        @TestDescription,
        @RowCount,
        DATEDIFF(MILLISECOND, @StartTime, @EndTime),
        CASE WHEN DATEDIFF(MILLISECOND, @StartTime, @EndTime) > 0 
             THEN @RowCount * 1000.0 / DATEDIFF(MILLISECOND, @StartTime, @EndTime)
             ELSE @RowCount END,
        @LogicalReadsAfter - @LogicalReadsBefore
    );
    
    -- Return result
    SELECT 
        @TestName AS TestName,
        @RowCount AS RowCount,
        DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS DurationMs,
        CASE WHEN DATEDIFF(MILLISECOND, @StartTime, @EndTime) > 0 
             THEN @RowCount * 1000.0 / DATEDIFF(MILLISECOND, @StartTime, @EndTime)
             ELSE @RowCount END AS RowsPerSecond;
END;
GO

-- Run benchmarks
TRUNCATE TABLE perf.TargetTable;

-- Test 1: Simple INSERT
EXEC perf.usp_RunBenchmark 
    @TestName = 'Simple INSERT',
    @TestDescription = 'Basic INSERT without optimizations',
    @TestSQL = N'INSERT INTO perf.TargetTable (RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category)
                 SELECT TOP 50000 RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category
                 FROM perf.LargeSourceTable';
GO

TRUNCATE TABLE perf.TargetTable;

-- Test 2: INSERT with TABLOCK
EXEC perf.usp_RunBenchmark 
    @TestName = 'INSERT with TABLOCK',
    @TestDescription = 'INSERT with table lock hint for minimal logging',
    @TestSQL = N'INSERT INTO perf.TargetTable WITH (TABLOCK) (RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category)
                 SELECT TOP 50000 RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category
                 FROM perf.LargeSourceTable';
GO

-- View benchmark comparison
SELECT TestName, RowCount, DurationMs, RowsPerSecond, TestDate
FROM perf.BenchmarkResults
ORDER BY TestDate DESC;
GO

-- ============================================================================
-- SECTION 10: EXERCISES
-- ============================================================================

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 1: OPTIMIZE A SLOW ETL PROCESS                                     ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Given the following slow procedure, apply optimizations:                    ║
║  - Batch processing                                                          ║
║  - Index management                                                          ║
║  - Minimal logging                                                           ║  
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Original slow procedure
CREATE OR ALTER PROCEDURE perf.usp_SlowLoad
AS
BEGIN
    DECLARE @RowID INT, @CustomerID INT, @OrderDate DATE;
    
    DECLARE slow_cursor CURSOR FOR
        SELECT RowID, CustomerID, OrderDate FROM perf.LargeSourceTable;
    
    OPEN slow_cursor;
    FETCH NEXT FROM slow_cursor INTO @RowID, @CustomerID, @OrderDate;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO perf.TargetTable (RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category)
        SELECT RowID, CustomerID, OrderDate, ProductID, Quantity, UnitPrice, TotalAmount, Region, Category
        FROM perf.LargeSourceTable WHERE RowID = @RowID;
        
        FETCH NEXT FROM slow_cursor INTO @RowID, @CustomerID, @OrderDate;
    END
    
    CLOSE slow_cursor;
    DEALLOCATE slow_cursor;
END;
GO

-- Your optimized version here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 2: IMPLEMENT ADAPTIVE BATCH SIZE                                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create a procedure that automatically adjusts batch size based on:          ║
║  - Current system load                                                       ║
║  - Transaction log usage                                                     ║
║  - Time constraints                                                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 3: CREATE PERFORMANCE DASHBOARD                                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create views that show:                                                     ║
║  - Slowest running ETL processes                                            ║
║  - Tables with most I/O activity                                            ║
║  - Index usage patterns                                                      ║
║  - Wait type analysis                                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
/*
DROP TABLE IF EXISTS perf.LargeSourceTable;
DROP TABLE IF EXISTS perf.TargetTable;
DROP TABLE IF EXISTS perf.IndexedTable;
DROP TABLE IF EXISTS perf.MinimalLogTest;
DROP TABLE IF EXISTS perf.MinimalLogTest2;
DROP TABLE IF EXISTS perf.StagingForSwitch;
DROP TABLE IF EXISTS perf.DimCustomer;
DROP TABLE IF EXISTS perf.BenchmarkResults;

DROP VIEW IF EXISTS perf.vw_ETLWaitStats;
DROP VIEW IF EXISTS perf.vw_TableIOStats;
DROP VIEW IF EXISTS perf.vw_QueryPerformance;

DROP PROCEDURE IF EXISTS perf.usp_LoadInBatches;
DROP PROCEDURE IF EXISTS perf.usp_LoadWithIndexManagement;
DROP PROCEDURE IF EXISTS perf.usp_LoadByRange;
DROP PROCEDURE IF EXISTS perf.usp_RunBenchmark;
DROP PROCEDURE IF EXISTS perf.usp_SlowLoad;

DROP SCHEMA IF EXISTS perf;
*/

PRINT '═══════════════════════════════════════════════════════════════════════════';
PRINT '  Lab 65: ETL Performance Optimization - Complete';
PRINT '═══════════════════════════════════════════════════════════════════════════';
GO
