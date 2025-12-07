/*
 * Lab 32: Performance Monitoring and DMVs
 * Module 04: Database Administration
 * 
 * Objective: Master SQL Server performance monitoring using Dynamic Management Views
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 32: Performance Monitoring';
PRINT '==============================================';
PRINT '';

/*
 * DYNAMIC MANAGEMENT VIEWS (DMVs):
 * 
 * Categories:
 * 1. sys.dm_exec_*: Query execution and plans
 * 2. sys.dm_db_*: Database-level stats
 * 3. sys.dm_os_*: Operating system interactions
 * 4. sys.dm_io_*: I/O statistics
 * 5. sys.dm_tran_*: Transaction information
 * 
 * All DMVs reset on SQL Server restart!
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
 * PART 1: FIND SLOW QUERIES
 */

PRINT 'PART 1: Identifying Slow Queries';
PRINT '----------------------------------';

-- Top 20 slowest queries by total elapsed time
SELECT TOP 20
    qs.execution_count AS ExecutionCount,
    qs.total_elapsed_time / 1000000.0 AS TotalElapsedTimeSec,
    qs.total_elapsed_time / qs.execution_count / 1000.0 AS AvgElapsedTimeMS,
    qs.total_worker_time / 1000000.0 AS TotalCPUTimeSec,
    qs.total_logical_reads AS TotalLogicalReads,
    qs.total_physical_reads AS TotalPhysicalReads,
    qs.creation_time AS PlanCreationTime,
    qs.last_execution_time AS LastExecutionTime,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2)+1) AS QueryText,
    qp.query_plan AS QueryPlan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qt.dbid = DB_ID()
ORDER BY qs.total_elapsed_time DESC;

PRINT '';

-- Queries with highest CPU usage
SELECT TOP 10
    qs.execution_count,
    qs.total_worker_time / 1000000.0 AS TotalCPUSec,
    qs.total_worker_time / qs.execution_count / 1000.0 AS AvgCPUMS,
    SUBSTRING(qt.text, 1, 100) AS QueryTextPreview
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.dbid = DB_ID()
ORDER BY qs.total_worker_time DESC;

PRINT '';

/*
 * PART 2: CURRENTLY EXECUTING QUERIES
 */

PRINT 'PART 2: Currently Executing Queries';
PRINT '-------------------------------------';

-- All active requests
SELECT 
    r.session_id AS SPID,
    r.status AS Status,
    r.blocking_session_id AS BlockedBy,
    r.wait_type AS WaitType,
    r.wait_time AS WaitTimeMS,
    r.cpu_time AS CPUTimeMS,
    r.total_elapsed_time AS ElapsedTimeMS,
    r.reads AS LogicalReads,
    r.writes AS Writes,
    r.command AS Command,
    s.login_name AS LoginName,
    s.host_name AS HostName,
    s.program_name AS ProgramName,
    DB_NAME(r.database_id) AS DatabaseName,
    SUBSTRING(qt.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2)+1) AS CurrentQuery,
    qp.query_plan AS ExecutionPlan
FROM sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp
WHERE r.session_id != @@SPID  -- Exclude current session
    AND s.is_user_process = 1  -- Only user processes
ORDER BY r.total_elapsed_time DESC;

PRINT '';

/*
 * PART 3: BLOCKING AND DEADLOCKS
 */

PRINT 'PART 3: Blocking and Deadlock Detection';
PRINT '----------------------------------------';

-- Find blocking chains
;WITH BlockingChain AS (
    SELECT 
        r.session_id AS BlockedSPID,
        r.blocking_session_id AS BlockingSPID,
        r.wait_type,
        r.wait_time,
        r.wait_resource,
        SUBSTRING(qt.text, 1, 100) AS BlockedQuery,
        s.login_name AS BlockedUser,
        s.host_name AS BlockedHost,
        0 AS Level
    FROM sys.dm_exec_requests r
    INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) qt
    WHERE r.blocking_session_id != 0
    
    UNION ALL
    
    SELECT 
        bc.BlockedSPID,
        r.blocking_session_id,
        r.wait_type,
        r.wait_time,
        r.wait_resource,
        bc.BlockedQuery,
        bc.BlockedUser,
        bc.BlockedHost,
        bc.Level + 1
    FROM BlockingChain bc
    INNER JOIN sys.dm_exec_requests r ON bc.BlockingSPID = r.session_id
    WHERE bc.Level < 10  -- Prevent infinite recursion
)
SELECT * FROM BlockingChain
ORDER BY Level, BlockedSPID;

PRINT '';

-- Deadlock history (from system health session)
SELECT 
    CAST(xet.target_data AS XML) AS DeadlockGraph
FROM sys.dm_xe_session_targets xet
INNER JOIN sys.dm_xe_sessions xe ON xe.address = xet.event_session_address
WHERE xe.name = 'system_health'
    AND xet.target_name = 'ring_buffer';

PRINT 'Deadlock graphs captured in system_health extended event session';
PRINT '';

/*
 * PART 4: WAIT STATISTICS
 */

PRINT 'PART 4: Wait Statistics Analysis';
PRINT '----------------------------------';

-- Top wait types
SELECT TOP 20
    wait_type AS WaitType,
    wait_time_ms / 1000.0 AS WaitTimeSec,
    waiting_tasks_count AS WaitingTasks,
    wait_time_ms / waiting_tasks_count AS AvgWaitTimeMS,
    (wait_time_ms - signal_wait_time_ms) / 1000.0 AS ResourceWaitSec,
    signal_wait_time_ms / 1000.0 AS SignalWaitSec,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS DECIMAL(5,2)) AS PercentTotal
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (  -- Filter out benign waits
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
    'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
    'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE',
    'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
    'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
    'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
    'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
)
    AND waiting_tasks_count > 0
ORDER BY wait_time_ms DESC;

PRINT '';
PRINT 'Common Wait Types:';
PRINT '  LCK_*: Lock waits (blocking issues)';
PRINT '  PAGEIOLATCH_*: Disk I/O waits';
PRINT '  WRITELOG: Transaction log write waits';
PRINT '  CXPACKET: Parallelism waits';
PRINT '  SOS_SCHEDULER_YIELD: CPU pressure';
PRINT '';

/*
 * PART 5: I/O STATISTICS
 */

PRINT 'PART 5: I/O Statistics';
PRINT '-----------------------';

-- Database file I/O stats
SELECT 
    DB_NAME(vfs.database_id) AS DatabaseName,
    mf.name AS FileName,
    mf.type_desc AS FileType,
    vfs.num_of_reads AS NumReads,
    vfs.num_of_bytes_read / 1024.0 / 1024.0 AS ReadMB,
    vfs.io_stall_read_ms AS ReadStallMS,
    CASE WHEN vfs.num_of_reads > 0 
        THEN vfs.io_stall_read_ms / vfs.num_of_reads 
        ELSE 0 END AS AvgReadLatencyMS,
    vfs.num_of_writes AS NumWrites,
    vfs.num_of_bytes_written / 1024.0 / 1024.0 AS WriteMB,
    vfs.io_stall_write_ms AS WriteStallMS,
    CASE WHEN vfs.num_of_writes > 0 
        THEN vfs.io_stall_write_ms / vfs.num_of_writes 
        ELSE 0 END AS AvgWriteLatencyMS,
    (vfs.io_stall_read_ms + vfs.io_stall_write_ms) AS TotalIOStallMS
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
INNER JOIN sys.master_files mf ON vfs.database_id = mf.database_id 
    AND vfs.file_id = mf.file_id
WHERE vfs.database_id = DB_ID()
ORDER BY (vfs.io_stall_read_ms + vfs.io_stall_write_ms) DESC;

PRINT '';

-- I/O latency guidelines
PRINT 'I/O Latency Guidelines:';
PRINT '  < 5ms:   Excellent (SSD)';
PRINT '  5-10ms:  Good (fast HDDs or SAN)';
PRINT '  10-20ms: Acceptable';
PRINT '  > 20ms:  Poor (investigate disk subsystem)';
PRINT '';

/*
 * PART 6: INDEX USAGE STATS
 */

PRINT 'PART 6: Index Usage Statistics';
PRINT '-------------------------------';

-- Index usage summary
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    s.user_lookups AS UserLookups,
    s.user_updates AS UserUpdates,
    s.user_seeks + s.user_scans + s.user_lookups AS TotalReads,
    s.last_user_seek AS LastSeek,
    s.last_user_scan AS LastScan,
    s.last_user_lookup AS LastLookup,
    CASE 
        WHEN s.user_seeks + s.user_scans + s.user_lookups = 0 THEN 'UNUSED'
        WHEN s.user_updates > (s.user_seeks + s.user_scans + s.user_lookups) * 5 THEN 'High maintenance cost'
        ELSE 'In use'
    END AS Status
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;

PRINT '';

/*
 * PART 7: MEMORY USAGE
 */

PRINT 'PART 7: Memory Usage Analysis';
PRINT '------------------------------';

-- Buffer pool usage by database
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    COUNT(*) * 8.0 / 1024.0 AS BufferPoolMB,
    SUM(CASE WHEN is_modified = 1 THEN 1 ELSE 0 END) * 8.0 / 1024.0 AS DirtyPagesMB,
    COUNT(*) AS PageCount
FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID()
GROUP BY database_id;

PRINT '';

-- Memory clerks
SELECT TOP 10
    type AS ClerkType,
    SUM(pages_kb) / 1024.0 AS MemoryMB
FROM sys.dm_os_memory_clerks
GROUP BY type
ORDER BY SUM(pages_kb) DESC;

PRINT '';

-- Plan cache usage
SELECT 
    objtype AS ObjectType,
    COUNT(*) AS PlanCount,
    SUM(CAST(size_in_bytes AS BIGINT)) / 1024.0 / 1024.0 AS TotalSizeMB,
    AVG(usecounts) AS AvgUseCounts
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY SUM(CAST(size_in_bytes AS BIGINT)) DESC;

PRINT '';

/*
 * PART 8: CPU USAGE
 */

PRINT 'PART 8: CPU Usage Analysis';
PRINT '---------------------------';

-- SQL Server CPU usage (last 256 minutes)
SELECT TOP 60
    DATEADD(ms, -1 * ((SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info) - timestamp), GETDATE()) AS EventTime,
    SQLProcessUtilization AS SQLServerCPU,
    SystemIdle AS SystemIdleCPU,
    100 - SystemIdle - SQLProcessUtilization AS OtherProcessesCPU
FROM (
    SELECT 
        record.value('(./Record/@id)[1]', 'int') AS record_id,
        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle,
        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilization,
        timestamp
    FROM (
        SELECT timestamp, CONVERT(xml, record) AS record
        FROM sys.dm_os_ring_buffers
        WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
            AND record LIKE '%<SystemHealth>%'
    ) AS x
) AS y
ORDER BY EventTime DESC;

PRINT '';

/*
 * PART 9: CREATE MONITORING DASHBOARD
 */

PRINT 'PART 9: Performance Monitoring Dashboard';
PRINT '-----------------------------------------';

CREATE OR ALTER VIEW dbo.vw_PerformanceSnapshot
AS
SELECT 
    GETDATE() AS SnapshotTime,
    
    -- Current activity
    (SELECT COUNT(*) FROM sys.dm_exec_requests WHERE session_id > 50) AS ActiveSessions,
    (SELECT COUNT(*) FROM sys.dm_exec_requests WHERE blocking_session_id != 0) AS BlockedSessions,
    
    -- Wait stats (top wait)
    (SELECT TOP 1 wait_type FROM sys.dm_os_wait_stats 
     WHERE wait_type NOT LIKE '%SLEEP%' AND waiting_tasks_count > 0
     ORDER BY wait_time_ms DESC) AS TopWaitType,
    
    -- Memory
    (SELECT SUM(pages_kb) / 1024.0 FROM sys.dm_os_memory_clerks) AS TotalMemoryMB,
    (SELECT COUNT(*) * 8.0 / 1024.0 FROM sys.dm_os_buffer_descriptors WHERE database_id = DB_ID()) AS BufferPoolMB,
    
    -- I/O
    (SELECT SUM(num_of_reads + num_of_writes) 
     FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL)) AS TotalIOOperations,
    (SELECT SUM(io_stall_read_ms + io_stall_write_ms) 
     FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL)) AS TotalIOStallMS,
    
    -- Transactions
    (SELECT COUNT(*) FROM sys.dm_tran_active_transactions) AS ActiveTransactions,
    (SELECT (total_log_size_in_bytes - used_log_space_in_bytes) * 100.0 / total_log_size_in_bytes
     FROM sys.dm_db_log_space_usage) AS LogSpaceAvailablePct;
GO

-- Query the dashboard
SELECT * FROM dbo.vw_PerformanceSnapshot;

PRINT '✓ Created vw_PerformanceSnapshot dashboard view';
PRINT '';

/*
 * PART 10: PERFORMANCE BASELINE
 */

PRINT 'PART 10: Performance Baseline Capture';
PRINT '---------------------------------------';

-- Create baseline table
IF OBJECT_ID('dbo.PerformanceBaseline', 'U') IS NOT NULL DROP TABLE dbo.PerformanceBaseline;

CREATE TABLE dbo.PerformanceBaseline (
    BaselineID INT IDENTITY(1,1) PRIMARY KEY,
    CaptureTime DATETIME NOT NULL DEFAULT GETDATE(),
    ActiveSessions INT,
    BlockedSessions INT,
    AvgCPUMS FLOAT,
    AvgLogicalReads BIGINT,
    AvgPhysicalReads BIGINT,
    TotalWaitTimeMS BIGINT,
    BufferPoolMB FLOAT,
    LogUsedPct FLOAT
);

-- Capture baseline
INSERT INTO dbo.PerformanceBaseline (
    ActiveSessions, BlockedSessions, AvgCPUMS, AvgLogicalReads, 
    AvgPhysicalReads, TotalWaitTimeMS, BufferPoolMB, LogUsedPct
)
SELECT 
    (SELECT COUNT(*) FROM sys.dm_exec_requests WHERE session_id > 50),
    (SELECT COUNT(*) FROM sys.dm_exec_requests WHERE blocking_session_id != 0),
    (SELECT AVG(total_worker_time / execution_count) FROM sys.dm_exec_query_stats),
    (SELECT AVG(total_logical_reads / execution_count) FROM sys.dm_exec_query_stats),
    (SELECT AVG(total_physical_reads / execution_count) FROM sys.dm_exec_query_stats),
    (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats),
    (SELECT COUNT(*) * 8.0 / 1024.0 FROM sys.dm_os_buffer_descriptors WHERE database_id = DB_ID()),
    (SELECT used_log_space_in_percent FROM sys.dm_db_log_space_usage);

PRINT '✓ Baseline captured';

-- View baseline trend
SELECT 
    CaptureTime,
    ActiveSessions,
    BlockedSessions,
    AvgCPUMS,
    AvgLogicalReads,
    BufferPoolMB,
    LogUsedPct
FROM dbo.PerformanceBaseline
ORDER BY CaptureTime DESC;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create automated monitoring with alerts for performance thresholds
 * 2. Build a query performance dashboard showing top resource consumers
 * 3. Implement blocking detection with automatic email notifications
 * 4. Create historical trending for key performance metrics
 * 5. Design a capacity planning report based on baseline data
 * 
 * CHALLENGE:
 * Build a comprehensive performance monitoring system:
 * - Real-time dashboard with auto-refresh
 * - Anomaly detection using statistical analysis
 * - Predictive alerting (warn before problems occur)
 * - Performance regression detection
 * - Automated performance tuning recommendations
 * - Integration with visualization tools (Power BI, Grafana)
 */

PRINT '✓ Lab 32 Complete: Performance monitoring mastered';
PRINT '';
PRINT 'Key Monitoring Areas:';
PRINT '  1. Query performance (slow queries, execution plans)';
PRINT '  2. Blocking and deadlocks';
PRINT '  3. Wait statistics (identify bottlenecks)';
PRINT '  4. I/O performance (latency, throughput)';
PRINT '  5. Memory usage (buffer pool, plan cache)';
PRINT '  6. CPU utilization';
PRINT '';
PRINT 'DMV Categories:';
PRINT '  sys.dm_exec_*:  Query execution';
PRINT '  sys.dm_db_*:    Database stats';
PRINT '  sys.dm_os_*:    OS interactions';
PRINT '  sys.dm_io_*:    I/O statistics';
PRINT '  sys.dm_tran_*:  Transactions';
GO
