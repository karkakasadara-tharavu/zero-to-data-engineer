/*
 * Lab 35: Advanced Troubleshooting & Performance Tuning
 * Module 04: Database Administration
 * 
 * Objective: Master systematic troubleshooting methodology and performance optimization
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 35: Advanced Troubleshooting';
PRINT '==============================================';
PRINT '';

/*
 * TROUBLESHOOTING TOPICS:
 * 
 * 1. Deadlock Analysis and Resolution
 * 2. Query Performance Tuning Methodology
 * 3. Execution Plan Deep Dive
 * 4. Parameter Sniffing Issues
 * 5. Implicit Conversions
 * 6. TempDB Optimization
 * 7. Blocking and Locking
 * 8. Memory Pressure
 * 9. I/O Bottlenecks
 * 10. Comprehensive Troubleshooting Framework
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
 * PART 1: DEADLOCK ANALYSIS AND RESOLUTION
 */

PRINT 'PART 1: Deadlock Analysis and Resolution';
PRINT '-----------------------------------------';

-- Enable trace flag for detailed deadlock info in error log
-- DBCC TRACEON(1222, -1);  -- Requires admin

-- Create deadlock scenario setup
IF OBJECT_ID('Account', 'U') IS NOT NULL DROP TABLE Account;

CREATE TABLE Account (
    AccountID INT PRIMARY KEY,
    Balance DECIMAL(10,2),
    AccountType NVARCHAR(20)
);

INSERT INTO Account VALUES (1, 1000.00, 'Checking'), (2, 500.00, 'Savings');
PRINT '✓ Created Account table for deadlock demonstration';
PRINT '';

-- Deadlock example (run in separate sessions):
PRINT '-- SESSION 1: Run this in one query window:';
PRINT 'BEGIN TRANSACTION;';
PRINT '  UPDATE Account SET Balance = Balance - 100 WHERE AccountID = 1;';
PRINT '  WAITFOR DELAY ''00:00:05'';';
PRINT '  UPDATE Account SET Balance = Balance + 100 WHERE AccountID = 2;';
PRINT 'COMMIT;';
PRINT '';

PRINT '-- SESSION 2: Run this in another query window immediately:';
PRINT 'BEGIN TRANSACTION;';
PRINT '  UPDATE Account SET Balance = Balance - 50 WHERE AccountID = 2;';
PRINT '  WAITFOR DELAY ''00:00:05'';';
PRINT '  UPDATE Account SET Balance = Balance + 50 WHERE AccountID = 1;';
PRINT 'COMMIT;';
PRINT '';

PRINT 'Result: One session will be deadlock victim (error 1205)';
PRINT '';

-- Query deadlock history from system_health extended event
SELECT 
    CAST(event_data AS XML) AS DeadlockGraph,
    CAST(event_data AS XML).value('(event[@name="xml_deadlock_report"]/@timestamp)[1]', 'datetime2') AS DeadlockTime
FROM sys.fn_xe_file_target_read_file(
    (SELECT LEFT(path, LEN(path) - CHARINDEX('\', REVERSE(path))) + '\system_health*.xel'
     FROM sys.dm_os_server_diagnostics_log_configurations),
    NULL, NULL, NULL
)
WHERE object_name = 'xml_deadlock_report'
ORDER BY DeadlockTime DESC;

PRINT '';

-- Deadlock prevention strategies
PRINT 'DEADLOCK RESOLUTION STRATEGIES:';
PRINT '  1. Access objects in same order (A then B in all transactions)';
PRINT '  2. Keep transactions short';
PRINT '  3. Use lower isolation levels (READ COMMITTED)';
PRINT '  4. Use SNAPSHOT isolation (optimistic locking)';
PRINT '  5. Add index to reduce lock duration';
PRINT '  6. Use ROWLOCK hint if appropriate';
PRINT '';

-- Better approach: Same order
PRINT '-- DEADLOCK-SAFE VERSION (access in same order):';
PRINT 'BEGIN TRANSACTION;';
PRINT '  UPDATE Account SET Balance = Balance - 100 WHERE AccountID = 1;';
PRINT '  UPDATE Account SET Balance = Balance + 100 WHERE AccountID = 2;';
PRINT 'COMMIT;';
PRINT '';

/*
 * PART 2: QUERY PERFORMANCE TUNING METHODOLOGY
 */

PRINT 'PART 2: Query Performance Tuning Methodology';
PRINT '---------------------------------------------';

-- Create slow query example
IF OBJECT_ID('LargeOrders', 'U') IS NOT NULL DROP TABLE LargeOrders;

CREATE TABLE LargeOrders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATETIME,
    CustomerID INT,
    ProductID INT,
    Quantity INT,
    TotalAmount DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO LargeOrders (OrderDate, CustomerID, ProductID, Quantity, TotalAmount)
SELECT 
    DATEADD(DAY, -(n.number % 365), GETDATE()),
    (n.number % 1000) + 1,
    (n.number % 100) + 1,
    (n.number % 50) + 1,
    CAST(RAND(CHECKSUM(NEWID())) * 1000 AS DECIMAL(10,2))
FROM master.dbo.spt_values n
WHERE n.type = 'P' AND n.number BETWEEN 1 AND 50000;

PRINT '✓ Created LargeOrders with 50,000 rows';
PRINT '';

-- STEP 1: Identify slow query
PRINT 'TUNING METHODOLOGY:';
PRINT '';
PRINT 'STEP 1: Identify Problem Query';
PRINT '  - Check sys.dm_exec_query_stats for high duration/CPU';
PRINT '  - Look at wait statistics';
PRINT '  - Review execution plans';
PRINT '';

-- STEP 2: Measure baseline
PRINT 'STEP 2: Measure Baseline Performance';
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Slow query (table scan, no index)
SELECT CustomerID, SUM(TotalAmount) AS TotalSpent
FROM LargeOrders
WHERE OrderDate >= DATEADD(MONTH, -6, GETDATE())
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 5000
ORDER BY TotalSpent DESC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
PRINT '(Note logical reads and elapsed time)';
PRINT '';

-- STEP 3: Analyze execution plan
PRINT 'STEP 3: Analyze Execution Plan';
PRINT '  - Look for table scans (should be index seeks)';
PRINT '  - Check for missing indexes';
PRINT '  - Identify expensive operators (sorts, hash matches)';
PRINT '  - Review estimated vs actual row counts';
PRINT '';

-- STEP 4: Apply optimization
PRINT 'STEP 4: Apply Optimization';
CREATE NONCLUSTERED INDEX IX_LargeOrders_OrderDate_Include
ON LargeOrders(OrderDate)
INCLUDE (CustomerID, TotalAmount);

PRINT '✓ Created covering index on OrderDate';
PRINT '';

-- STEP 5: Verify improvement
PRINT 'STEP 5: Verify Improvement';
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT CustomerID, SUM(TotalAmount) AS TotalSpent
FROM LargeOrders
WHERE OrderDate >= DATEADD(MONTH, -6, GETDATE())
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 5000
ORDER BY TotalSpent DESC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
PRINT '(Compare to baseline - should see dramatic improvement)';
PRINT '';

/*
 * PART 3: EXECUTION PLAN DEEP DIVE
 */

PRINT 'PART 3: Execution Plan Analysis';
PRINT '--------------------------------';

-- Common execution plan operators
PRINT 'COMMON OPERATORS (Cost Implications):';
PRINT '';
PRINT 'LOW COST (Good):';
PRINT '  • Index Seek: Direct lookup (logarithmic cost)';
PRINT '  • Key Lookup: Bookmark lookup (acceptable if few rows)';
PRINT '  • Nested Loops: Best for small result sets';
PRINT '';
PRINT 'MEDIUM COST (Acceptable):';
PRINT '  • Index Scan: Read entire index';
PRINT '  • Merge Join: Requires sorted inputs';
PRINT '  • Compute Scalar: Calculations';
PRINT '';
PRINT 'HIGH COST (Bad):';
PRINT '  • Table Scan: Read entire table (no indexes)';
PRINT '  • Hash Match: Expensive for large datasets';
PRINT '  • Sort: Expensive, avoid if possible';
PRINT '  • Parallelism: Good for large queries, bad overhead for small';
PRINT '';

-- Estimated vs Actual Rows Mismatch
PRINT 'ESTIMATED VS ACTUAL ROWS:';
PRINT '  - Large mismatch indicates stale statistics';
PRINT '  - Can cause wrong join algorithm selection';
PRINT '  - Fix: UPDATE STATISTICS or enable auto-update';
PRINT '';

-- Example: Statistics issue
UPDATE STATISTICS LargeOrders WITH FULLSCAN;
PRINT '✓ Updated statistics on LargeOrders';
PRINT '';

-- Get plan cache for specific query
SELECT 
    qs.execution_count AS ExecCount,
    qs.total_worker_time / 1000 AS TotalCPU_ms,
    qs.total_elapsed_time / 1000 AS TotalElapsed_ms,
    qs.total_logical_reads AS TotalLogicalReads,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2)+1) AS QueryText,
    qp.query_plan AS ExecutionPlan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qt.text LIKE '%LargeOrders%'
    AND qt.text NOT LIKE '%sys.dm_exec_query_stats%'
ORDER BY qs.total_worker_time DESC;

PRINT '';

/*
 * PART 4: PARAMETER SNIFFING
 */

PRINT 'PART 4: Parameter Sniffing Issues';
PRINT '-----------------------------------';

-- Create procedure with parameter sniffing problem
IF OBJECT_ID('usp_GetOrdersByCustomer', 'P') IS NOT NULL 
    DROP PROCEDURE usp_GetOrdersByCustomer;
GO

CREATE PROCEDURE usp_GetOrdersByCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT OrderID, OrderDate, TotalAmount
    FROM LargeOrders
    WHERE CustomerID = @CustomerID
    ORDER BY OrderDate DESC;
END;
GO

PRINT '✓ Created procedure: usp_GetOrdersByCustomer';
PRINT '';

-- First execution (cache plan for CustomerID with many orders)
EXEC usp_GetOrdersByCustomer @CustomerID = 1;

-- Subsequent executions (reuse same plan even if different parameter)
EXEC usp_GetOrdersByCustomer @CustomerID = 999;

PRINT '';
PRINT 'PARAMETER SNIFFING SYMPTOMS:';
PRINT '  - Query fast for some parameters, slow for others';
PRINT '  - Plan cached for first execution parameters';
PRINT '  - Wrong plan reused for different data distribution';
PRINT '';

PRINT 'SOLUTIONS:';
PRINT '';
PRINT '1. RECOMPILE Hint (always recompile):';
PRINT '   ALTER PROCEDURE usp_GetOrdersByCustomer';
PRINT '   WITH RECOMPILE AS ...';
PRINT '';
PRINT '2. OPTIMIZE FOR hint (specific value):';
PRINT '   OPTION (OPTIMIZE FOR (@CustomerID = 100))';
PRINT '';
PRINT '3. OPTIMIZE FOR UNKNOWN (average distribution):';
PRINT '   OPTION (OPTIMIZE FOR (@CustomerID UNKNOWN))';
PRINT '';
PRINT '4. Local variable copy (prevents sniffing):';
PRINT '   DECLARE @LocalCustomerID INT = @CustomerID;';
PRINT '';
PRINT '5. Query Store forced plans';
PRINT '';

/*
 * PART 5: IMPLICIT CONVERSIONS
 */

PRINT 'PART 5: Implicit Conversion Detection';
PRINT '--------------------------------------';

-- Create table with implicit conversion issue
IF OBJECT_ID('CustomerLookup', 'U') IS NOT NULL DROP TABLE CustomerLookup;

CREATE TABLE CustomerLookup (
    CustomerCode VARCHAR(20) PRIMARY KEY,  -- VARCHAR (not NVARCHAR)
    CustomerName NVARCHAR(100),
    Region NVARCHAR(50)
);

INSERT INTO CustomerLookup VALUES 
    ('CUST001', 'Acme Corp', 'North'),
    ('CUST002', 'Tech Solutions', 'South'),
    ('CUST003', 'Global Industries', 'East');

CREATE INDEX IX_CustomerLookup_Region ON CustomerLookup(Region);
PRINT '✓ Created CustomerLookup table';
PRINT '';

-- Bad query: Implicit conversion (NVARCHAR parameter to VARCHAR column)
SET STATISTICS IO ON;
DECLARE @Code NVARCHAR(20) = N'CUST001';  -- NVARCHAR parameter

SELECT * FROM CustomerLookup WHERE CustomerCode = @Code;  -- IMPLICIT CONVERSION!
SET STATISTICS IO OFF;

PRINT '(Index scan occurred due to implicit conversion)';
PRINT '';

-- Good query: Explicit conversion
SET STATISTICS IO ON;
DECLARE @Code2 VARCHAR(20) = 'CUST001';  -- Correct datatype

SELECT * FROM CustomerLookup WHERE CustomerCode = @Code2;  -- INDEX SEEK!
SET STATISTICS IO OFF;

PRINT '(Index seek - no conversion needed)';
PRINT '';

-- Find implicit conversions in plan cache
SELECT 
    qs.execution_count,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2)+1) AS QueryText,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE '%CONVERT_IMPLICIT%'
    AND qt.text LIKE '%CustomerLookup%'
ORDER BY qs.total_worker_time DESC;

PRINT '';
PRINT 'IMPLICIT CONVERSION IMPACT:';
PRINT '  - Prevents index usage (index scan instead of seek)';
PRINT '  - CPU overhead for conversion';
PRINT '  - Common: VARCHAR vs NVARCHAR, INT vs BIGINT';
PRINT '';

/*
 * PART 6: TEMPDB OPTIMIZATION
 */

PRINT 'PART 6: TempDB Optimization';
PRINT '----------------------------';

-- Check TempDB configuration
SELECT 
    name AS FileName,
    physical_name AS FilePath,
    size * 8.0 / 1024 AS SizeMB,
    growth * 8.0 / 1024 AS GrowthMB,
    is_percent_growth AS IsPercentGrowth
FROM tempdb.sys.database_files;

PRINT '';

-- TempDB contention detection
SELECT 
    session_id,
    wait_type,
    wait_time_ms,
    blocking_session_id
FROM sys.dm_exec_requests
WHERE wait_type LIKE 'PAGELATCH%'
    AND wait_time_ms > 100
ORDER BY wait_time_ms DESC;

PRINT '';

PRINT 'TEMPDB BEST PRACTICES:';
PRINT '  1. NUMBER OF FILES:';
PRINT '     - 1 file per CPU core (up to 8)';
PRINT '     - For > 8 cores, add 4 at a time if contention persists';
PRINT '';
PRINT '  2. FILE SIZE:';
PRINT '     - All files same size (prevents proportional fill issues)';
PRINT '     - Autogrowth: Fixed size (not percent), 64-256MB increments';
PRINT '     - Pre-size to expected workload';
PRINT '';
PRINT '  3. FILE PLACEMENT:';
PRINT '     - Fast SSD storage';
PRINT '     - Separate from data and log files';
PRINT '';
PRINT '  4. TRACE FLAGS:';
PRINT '     - 1117: Grow all files simultaneously';
PRINT '     - 1118: Reduce mixed extent allocation';
PRINT '     - (SQL 2016+ has these enabled by default)';
PRINT '';

-- Example TempDB configuration script
PRINT '-- EXAMPLE: Configure TempDB (run on restart):';
PRINT 'ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, SIZE = 8192MB, FILEGROWTH = 512MB);';
PRINT 'ALTER DATABASE tempdb ADD FILE (NAME = tempdev2, FILENAME = ''E:\TempDB\tempdev2.ndf'', SIZE = 8192MB, FILEGROWTH = 512MB);';
PRINT '';

/*
 * PART 7: BLOCKING AND LOCK ESCALATION
 */

PRINT 'PART 7: Blocking and Lock Escalation';
PRINT '-------------------------------------';

-- Detect blocking
SELECT 
    r.session_id AS BlockedSessionID,
    r.blocking_session_id AS BlockingSessionID,
    DB_NAME(r.database_id) AS DatabaseName,
    r.wait_type,
    r.wait_time / 1000.0 AS WaitTimeSec,
    r.wait_resource,
    t.text AS BlockedQuery,
    (SELECT text FROM sys.dm_exec_sql_text(
        (SELECT sql_handle FROM sys.dm_exec_requests WHERE session_id = r.blocking_session_id)
    )) AS BlockingQuery
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id > 0
ORDER BY r.wait_time DESC;

PRINT '';

-- Lock escalation control
PRINT 'LOCK ESCALATION:';
PRINT '  - Occurs at 5,000 locks per table (threshold)';
PRINT '  - Escalates to table lock (blocks other queries)';
PRINT '';

PRINT 'PREVENTING ESCALATION:';
PRINT '  1. Disable at table level:';
PRINT '     ALTER TABLE LargeOrders SET (LOCK_ESCALATION = DISABLE);';
PRINT '';
PRINT '  2. Use ROWLOCK hint (if appropriate):';
PRINT '     UPDATE LargeOrders WITH (ROWLOCK) SET ...';
PRINT '';
PRINT '  3. Batch large updates:';
PRINT '     UPDATE TOP (1000) ... WHILE @@ROWCOUNT > 0';
PRINT '';
PRINT '  4. Use READ COMMITTED SNAPSHOT (optimistic):';
PRINT '     ALTER DATABASE BookstoreDB SET READ_COMMITTED_SNAPSHOT ON;';
PRINT '';

/*
 * PART 8: MEMORY PRESSURE
 */

PRINT 'PART 8: Memory Pressure Detection';
PRINT '-----------------------------------';

-- Check memory configuration
SELECT 
    physical_memory_kb / 1024 AS PhysicalMemory_MB,
    virtual_memory_kb / 1024 AS VirtualMemory_MB,
    committed_kb / 1024 AS Committed_MB,
    committed_target_kb / 1024 AS CommittedTarget_MB
FROM sys.dm_os_sys_info;

PRINT '';

-- Check buffer pool usage
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    COUNT(*) * 8 / 1024 AS BufferSize_MB
FROM sys.dm_os_buffer_descriptors
WHERE database_id > 4  -- Exclude system databases
GROUP BY database_id
ORDER BY BufferSize_MB DESC;

PRINT '';

-- Memory grants (sort/hash operations)
SELECT 
    session_id,
    requested_memory_kb / 1024 AS RequestedMemory_MB,
    granted_memory_kb / 1024 AS GrantedMemory_MB,
    used_memory_kb / 1024 AS UsedMemory_MB,
    wait_time_ms / 1000.0 AS WaitTimeSec,
    SUBSTRING(qt.text, (er.statement_start_offset/2)+1,
        ((CASE er.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE er.statement_end_offset
        END - er.statement_start_offset)/2)+1) AS QueryText
FROM sys.dm_exec_query_memory_grants qmg
INNER JOIN sys.dm_exec_requests er ON qmg.session_id = er.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) qt
WHERE granted_memory_kb > 0
ORDER BY granted_memory_kb DESC;

PRINT '';

PRINT 'MEMORY PRESSURE INDICATORS:';
PRINT '  - RESOURCE_SEMAPHORE waits';
PRINT '  - Page life expectancy < 300 seconds';
PRINT '  - Lazy writes/sec consistently high';
PRINT '  - Memory grants waiting';
PRINT '';

/*
 * PART 9: I/O BOTTLENECK DETECTION
 */

PRINT 'PART 9: I/O Bottleneck Analysis';
PRINT '--------------------------------';

-- I/O statistics by database file
SELECT 
    DB_NAME(vfs.database_id) AS DatabaseName,
    mf.physical_name AS FilePath,
    mf.type_desc AS FileType,
    vfs.num_of_reads AS NumReads,
    vfs.num_of_writes AS NumWrites,
    vfs.num_of_bytes_read / 1024 / 1024 AS ReadMB,
    vfs.num_of_bytes_written / 1024 / 1024 AS WriteMB,
    vfs.io_stall_read_ms / NULLIF(vfs.num_of_reads, 0) AS AvgReadLatency_ms,
    vfs.io_stall_write_ms / NULLIF(vfs.num_of_writes, 0) AS AvgWriteLatency_ms
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
INNER JOIN sys.master_files mf ON vfs.database_id = mf.database_id 
    AND vfs.file_id = mf.file_id
WHERE vfs.database_id > 4
ORDER BY (vfs.io_stall_read_ms + vfs.io_stall_write_ms) DESC;

PRINT '';

PRINT 'I/O LATENCY GUIDELINES:';
PRINT '  Excellent: < 5ms';
PRINT '  Good:      5-10ms';
PRINT '  Fair:      10-20ms';
PRINT '  Poor:      > 20ms';
PRINT '';

PRINT 'I/O OPTIMIZATION:';
PRINT '  - Move to faster storage (SSD/NVMe)';
PRINT '  - Separate data, log, and tempdb';
PRINT '  - Add missing indexes';
PRINT '  - Enable data compression';
PRINT '  - Implement partitioning';
PRINT '';

/*
 * PART 10: COMPREHENSIVE TROUBLESHOOTING FRAMEWORK
 */

PRINT 'PART 10: Troubleshooting Framework';
PRINT '------------------------------------';
PRINT '';

-- Create comprehensive health check procedure
IF OBJECT_ID('usp_DatabaseHealthCheck', 'P') IS NOT NULL 
    DROP PROCEDURE usp_DatabaseHealthCheck;
GO

CREATE PROCEDURE usp_DatabaseHealthCheck
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '========================================';
    PRINT 'DATABASE HEALTH CHECK';
    PRINT '========================================';
    PRINT '';
    
    -- 1. Top CPU queries
    PRINT '1. TOP 10 CPU QUERIES:';
    SELECT TOP 10
        total_worker_time / 1000 AS TotalCPU_ms,
        execution_count AS ExecCount,
        (total_worker_time / execution_count) / 1000 AS AvgCPU_ms,
        SUBSTRING(qt.text, 1, 100) AS QuerySnippet
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
    WHERE qt.text NOT LIKE '%sys.dm_exec_query_stats%'
    ORDER BY total_worker_time DESC;
    PRINT '';
    
    -- 2. Top wait types
    PRINT '2. TOP 10 WAIT TYPES:';
    WITH Waits AS (
        SELECT 
            wait_type,
            wait_time_ms / 1000.0 AS WaitTimeSec,
            (wait_time_ms * 100.0) / SUM(wait_time_ms) OVER() AS Percentage
        FROM sys.dm_os_wait_stats
        WHERE wait_type NOT IN (
            'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
            'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
            'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE',
            'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
            'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
            'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
            'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
        )
    )
    SELECT TOP 10 * FROM Waits
    WHERE WaitTimeSec > 0
    ORDER BY WaitTimeSec DESC;
    PRINT '';
    
    -- 3. Blocking
    PRINT '3. CURRENT BLOCKING:';
    SELECT 
        r.session_id AS BlockedSession,
        r.blocking_session_id AS BlockingSession,
        r.wait_type,
        r.wait_time / 1000.0 AS WaitTimeSec,
        SUBSTRING(qt.text, 1, 100) AS BlockedQuery
    FROM sys.dm_exec_requests r
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) qt
    WHERE r.blocking_session_id > 0;
    PRINT '';
    
    -- 4. Missing indexes
    PRINT '4. TOP 10 MISSING INDEXES:';
    SELECT TOP 10
        DB_NAME(mid.database_id) AS DatabaseName,
        OBJECT_NAME(mid.object_id, mid.database_id) AS TableName,
        migs.avg_user_impact AS AvgImpact,
        migs.user_seeks + migs.user_scans AS TotalSeeksScans,
        mid.equality_columns AS EqualityColumns,
        mid.inequality_columns AS InequalityColumns,
        mid.included_columns AS IncludedColumns
    FROM sys.dm_db_missing_index_groups mig
    INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
    INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
    WHERE mid.database_id = DB_ID()
    ORDER BY migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC;
    PRINT '';
    
    -- 5. Index fragmentation
    PRINT '5. FRAGMENTED INDEXES (>30%):';
    SELECT 
        OBJECT_NAME(ips.object_id) AS TableName,
        i.name AS IndexName,
        ips.avg_fragmentation_in_percent AS FragmentationPercent,
        ips.page_count AS PageCount
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.avg_fragmentation_in_percent > 30
        AND ips.page_count > 1000
    ORDER BY ips.avg_fragmentation_in_percent DESC;
    PRINT '';
    
    PRINT '✓ Health check complete';
END;
GO

PRINT '✓ Created usp_DatabaseHealthCheck procedure';
PRINT '';

-- Execute health check
EXEC usp_DatabaseHealthCheck;

PRINT '';
PRINT 'SYSTEMATIC TROUBLESHOOTING STEPS:';
PRINT '';
PRINT '1. IDENTIFY PROBLEM';
PRINT '   - User reports, monitoring alerts';
PRINT '   - Baseline comparison';
PRINT '';
PRINT '2. GATHER EVIDENCE';
PRINT '   - DMVs, execution plans, wait stats';
PRINT '   - Extended Events for detailed tracing';
PRINT '';
PRINT '3. FORM HYPOTHESIS';
PRINT '   - Missing index?';
PRINT '   - Blocking/deadlocks?';
PRINT '   - Memory/I/O bottleneck?';
PRINT '   - Parameter sniffing?';
PRINT '';
PRINT '4. TEST HYPOTHESIS';
PRINT '   - Apply fix in dev environment';
PRINT '   - Measure improvement';
PRINT '';
PRINT '5. IMPLEMENT SOLUTION';
PRINT '   - Controlled deployment';
PRINT '   - Monitor impact';
PRINT '';
PRINT '6. DOCUMENT';
PRINT '   - Root cause';
PRINT '   - Solution applied';
PRINT '   - Lessons learned';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create and resolve a deadlock scenario
 * 2. Tune a slow query using execution plan analysis
 * 3. Identify and fix implicit conversion issues
 * 4. Configure TempDB for optimal performance
 * 5. Build comprehensive monitoring dashboard
 * 
 * CHALLENGE:
 * Troubleshoot complex production issue:
 * - Application reports intermittent slowness
 * - Some users affected, others not
 * - Problem occurs during peak hours
 * - Use systematic methodology to identify root cause
 * - Implement solution without downtime
 * - Create prevention strategy
 */

PRINT '✓ Lab 35 Complete: Advanced troubleshooting mastered';
GO
