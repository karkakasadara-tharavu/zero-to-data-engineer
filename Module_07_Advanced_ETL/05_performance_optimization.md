# ETL Performance Optimization - Complete Guide

## 📚 What You'll Learn
- ETL performance bottlenecks
- SQL optimization for ETL
- Batch processing strategies
- SSIS performance tuning
- Parallel processing patterns
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 Understanding ETL Performance

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ETL PERFORMANCE FACTORS                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐        │
│   │    SOURCE     │ ──▶ │ TRANSFORMATION│ ──▶ │   TARGET      │        │
│   │   (Extract)   │     │   (Process)   │     │   (Load)      │        │
│   └───────────────┘     └───────────────┘     └───────────────┘        │
│                                                                          │
│   Potential Bottlenecks:                                                 │
│                                                                          │
│   Extract:                                                               │
│   ├── Network latency                                                   │
│   ├── Source query performance                                          │
│   ├── Lock contention on source                                         │
│   └── Large data volumes                                                │
│                                                                          │
│   Transform:                                                             │
│   ├── Memory constraints                                                │
│   ├── CPU-intensive operations                                          │
│   ├── Blocking transformations (Sort, Aggregate)                       │
│   └── Row-by-row processing                                             │
│                                                                          │
│   Load:                                                                  │
│   ├── Index maintenance overhead                                        │
│   ├── Constraint checking                                               │
│   ├── Lock contention on target                                         │
│   └── Transaction log growth                                            │
│                                                                          │
│   Key Metrics:                                                           │
│   ├── Rows per second                                                   │
│   ├── Total elapsed time                                                │
│   ├── CPU utilization                                                   │
│   ├── Memory usage                                                      │
│   └── I/O throughput                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 SQL Server ETL Optimization

### Bulk Operations

```sql
-- OPTION 1: Minimal Logging with BULK INSERT
BULK INSERT Target.FactSales
FROM 'C:\Data\sales.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,           -- Table lock for minimal logging
    BATCHSIZE = 10000  -- Commit every 10K rows
);

-- OPTION 2: SELECT INTO (always minimally logged)
SELECT *
INTO Target.FactSales_New
FROM Source.FactSales
WHERE SalesDate >= '2024-01-01';

-- OPTION 3: INSERT with TABLOCK hint
INSERT INTO Target.FactSales WITH (TABLOCK)
SELECT * FROM Staging.FactSales;

-- Requirements for minimal logging:
-- 1. Recovery model: SIMPLE or BULK_LOGGED
-- 2. TABLOCK hint (or table lock through other means)
-- 3. Empty table OR table with no indexes
-- 4. Heap or empty clustered index
```

### Index Strategy for ETL

```sql
-- Before bulk load: DROP or DISABLE indexes
ALTER INDEX IX_FactSales_Date ON FactSales DISABLE;
ALTER INDEX IX_FactSales_Customer ON FactSales DISABLE;

-- Load data (much faster without indexes)
INSERT INTO FactSales WITH (TABLOCK)
SELECT * FROM Staging.FactSales;

-- After load: REBUILD indexes (parallel)
ALTER INDEX ALL ON FactSales REBUILD 
WITH (ONLINE = OFF, MAXDOP = 4);

-- Or rebuild individually with sort in tempdb
ALTER INDEX IX_FactSales_Date ON FactSales REBUILD
WITH (SORT_IN_TEMPDB = ON, MAXDOP = 4);

-- For small incremental loads: Keep indexes
-- For large loads: Disable → Load → Rebuild
```

### Partition Switching

```sql
-- Instant partition swap for large loads
-- Prerequisites:
-- 1. Staging table in same filegroup
-- 2. Same structure and indexes
-- 3. Check constraints matching partition

-- 1. Create staging table matching partition
CREATE TABLE Staging.FactSales_2024Q1 (
    SalesDate DATE,
    ProductID INT,
    Amount DECIMAL(18,2),
    CONSTRAINT CK_Date CHECK (
        SalesDate >= '2024-01-01' AND 
        SalesDate < '2024-04-01'
    )
) ON [PartitionScheme](SalesDate);

-- 2. Load data to staging
INSERT INTO Staging.FactSales_2024Q1
SELECT * FROM Source.Sales
WHERE SalesDate >= '2024-01-01' 
  AND SalesDate < '2024-04-01';

-- 3. Build indexes on staging (parallel, no blocking)
CREATE CLUSTERED INDEX CIX_Sales ON Staging.FactSales_2024Q1(SalesDate);

-- 4. Switch partition (instant!)
ALTER TABLE Staging.FactSales_2024Q1
SWITCH TO Target.FactSales PARTITION 5;

-- Benefits:
-- No row-by-row insert
-- No blocking on target table
-- Minimal transaction log
-- Instant operation
```

### Batch Processing

```sql
-- Batch delete (avoid log explosion)
DECLARE @BatchSize INT = 10000;
DECLARE @RowsDeleted INT = 1;

WHILE @RowsDeleted > 0
BEGIN
    DELETE TOP (@BatchSize)
    FROM FactSales
    WHERE SalesDate < DATEADD(YEAR, -7, GETDATE());
    
    SET @RowsDeleted = @@ROWCOUNT;
    
    -- Optional: checkpoint to clear log
    CHECKPOINT;
END;

-- Batch update
DECLARE @LastID INT = 0;
DECLARE @RowsUpdated INT = 1;

WHILE @RowsUpdated > 0
BEGIN
    UPDATE TOP (10000) t
    SET t.Status = 'Processed',
        @LastID = t.RecordID
    FROM TargetTable t
    WHERE t.RecordID > @LastID
      AND t.Status = 'Pending'
    ORDER BY t.RecordID;
    
    SET @RowsUpdated = @@ROWCOUNT;
END;
```

---

## ⚙️ SSIS Performance Tuning

### Data Flow Optimization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSIS DATA FLOW TUNING                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   BUFFER CONFIGURATION:                                                  │
│   ├── DefaultBufferSize: Bytes per buffer (default 10MB)               │
│   ├── DefaultBufferMaxRows: Max rows per buffer (default 10,000)       │
│   └── BLOBTempStoragePath: Disk location for large objects             │
│                                                                          │
│   Tuning Guidelines:                                                     │
│   ├── Wide rows → Decrease DefaultBufferMaxRows                        │
│   ├── Narrow rows → Increase DefaultBufferMaxRows                      │
│   ├── Large data → Increase DefaultBufferSize (up to 100MB)           │
│   └── Memory pressure → Reduce buffer sizes                            │
│                                                                          │
│   COMPONENT SETTINGS:                                                    │
│   ├── OLE DB Source:                                                    │
│   │   └── AccessMode: SQL Command (not Table/View)                     │
│   │   └── Packet Size: 32767 (network optimization)                    │
│   │                                                                     │
│   ├── OLE DB Destination:                                               │
│   │   └── AccessMode: Fast Load                                        │
│   │   └── FastLoadOptions: TABLOCK,CHECK_CONSTRAINTS                  │
│   │   └── Rows per batch: 10000                                        │
│   │   └── Maximum insert commit size: 2147483647                       │
│   │                                                                     │
│   ├── Lookup:                                                           │
│   │   └── Cache Mode: Full Cache (when possible)                       │
│   │   └── Use 64-bit runtime for large caches                          │
│   │                                                                     │
│   └── Sort:                                                             │
│       └── AVOID! Sort at source with ORDER BY instead                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Transformation Performance

```
FASTEST (Synchronous - Same Buffer):
├── Derived Column
├── Data Conversion
├── Copy Column
├── Conditional Split
├── Multicast
└── Lookup (Full Cache, no match error)

SLOWER (Partially Blocking):
├── Merge Join (requires sorted input)
├── Merge (requires sorted input)
└── Union All

SLOWEST (Fully Blocking - New Buffer):
├── Sort                    ← AVOID!
├── Aggregate               ← Do in SQL instead
├── Pivot/Unpivot
└── Fuzzy Lookup/Grouping

RECOMMENDATIONS:
1. Filter at source (WHERE clause)
2. Sort at source (ORDER BY)
3. Aggregate at source (GROUP BY)
4. Use stored procedures for complex logic
```

### Parallel Execution

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSIS PARALLELISM                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   CONTROL FLOW PARALLELISM:                                              │
│   ┌───────────┐   ┌───────────┐   ┌───────────┐                        │
│   │ Load Dim  │   │ Load Dim  │   │ Load Dim  │                        │
│   │ Customer  │   │ Product   │   │ Date      │                        │
│   └─────┬─────┘   └─────┬─────┘   └─────┬─────┘                        │
│         │               │               │                               │
│         └───────────────┼───────────────┘                               │
│                         ▼                                                │
│                  ┌───────────┐                                          │
│                  │ Load Fact │                                          │
│                  │ Sales     │                                          │
│                  └───────────┘                                          │
│                                                                          │
│   MaxConcurrentExecutables property controls parallelism                │
│   Default: -1 (logical processors + 2)                                  │
│                                                                          │
│   DATA FLOW PARALLELISM:                                                 │
│   ├── EngineThreads: Threads for data flow engine                      │
│   ├── Multiple data flow tasks can run in parallel                     │
│   └── SSIS Scale Out for distributed execution                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Memory and 64-bit Execution

```
SSIS 32-bit vs 64-bit:

32-bit Limitations:
├── Max ~2GB addressable memory
├── Large lookups fail
└── Buffer constraints

64-bit Benefits:
├── Much larger memory
├── Better for big data
└── Required for large lookups

Run 64-bit:
├── Right-click project → Properties
├── Debugging → Run64BitRuntime = True
├── Or: ISServerExec.exe (64-bit by default)

When to use 32-bit:
├── Connecting to 32-bit drivers
├── Legacy components
├── Specific provider requirements
```

---

## 📊 Query Optimization for ETL

### Avoid Row-by-Row Processing

```sql
-- BAD: Cursor-based processing
DECLARE @OrderID INT;
DECLARE order_cursor CURSOR FOR
    SELECT OrderID FROM Orders WHERE Status = 'New';

OPEN order_cursor;
FETCH NEXT FROM order_cursor INTO @OrderID;

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE Orders SET Status = 'Processed' WHERE OrderID = @OrderID;
    EXEC usp_ProcessOrder @OrderID;
    FETCH NEXT FROM order_cursor INTO @OrderID;
END;

CLOSE order_cursor;
DEALLOCATE order_cursor;

-- GOOD: Set-based processing
UPDATE Orders SET Status = 'Processed' WHERE Status = 'New';

-- If procedure call needed, use batching
INSERT INTO OrdersToProcess
SELECT OrderID FROM Orders WHERE Status = 'New';

-- Then process in batches or parallel
```

### Optimize Source Queries

```sql
-- Include only needed columns
-- BAD:
SELECT * FROM LargeTable;

-- GOOD:
SELECT Column1, Column2, Column3 FROM LargeTable;

-- Filter at source
-- BAD (filter in SSIS):
SELECT * FROM Orders; -- then Conditional Split

-- GOOD (filter in query):
SELECT * FROM Orders WHERE OrderDate >= @StartDate;

-- Use NOLOCK for read-only extracts (if acceptable)
SELECT * FROM Orders WITH (NOLOCK)
WHERE OrderDate >= @StartDate;

-- Avoid functions on indexed columns
-- BAD:
WHERE YEAR(OrderDate) = 2024

-- GOOD:
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01'
```

### Staging Table Strategy

```sql
-- 1. Heap for initial load (fastest insert)
CREATE TABLE Staging.RawData (
    Column1 VARCHAR(100),
    Column2 INT,
    Column3 DECIMAL(18,2)
) WITH (DATA_COMPRESSION = PAGE);  -- Compress if I/O bound

-- 2. Load data (no indexes, minimal logging)
INSERT INTO Staging.RawData WITH (TABLOCK)
SELECT Column1, Column2, Column3
FROM Source.LargeTable;

-- 3. Add indexes for join operations
CREATE CLUSTERED INDEX CIX_RawData ON Staging.RawData(Column1);

-- 4. Process staging to target
MERGE Target.FinalTable AS t
USING Staging.RawData AS s
ON t.Column1 = s.Column1
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...;

-- 5. Truncate staging
TRUNCATE TABLE Staging.RawData;
```

---

## 🔧 Network and I/O Optimization

### Network Tuning

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    NETWORK OPTIMIZATION                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Connection String Settings:                                            │
│   ├── Packet Size=32767       (larger packets, fewer round trips)      │
│   ├── Network=dbmssocn        (TCP/IP only)                            │
│   └── MultipleActiveResultSets=True (for complex scenarios)            │
│                                                                          │
│   SSIS Source Settings:                                                  │
│   ├── CommandTimeout=0        (no timeout for long queries)            │
│   └── IsolationLevel=ReadUncommitted (if dirty reads acceptable)       │
│                                                                          │
│   Data Compression:                                                      │
│   ├── Use compressed tables (PAGE or ROW)                              │
│   ├── Less data transferred = faster network                           │
│   └── Trade CPU for I/O                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Disk I/O Optimization

```sql
-- Separate filegroups for different workloads
ALTER DATABASE DataWarehouse ADD FILEGROUP FG_Staging;
ALTER DATABASE DataWarehouse ADD FILEGROUP FG_Facts;
ALTER DATABASE DataWarehouse ADD FILEGROUP FG_Indexes;

-- Files on different physical disks
ALTER DATABASE DataWarehouse
ADD FILE (
    NAME = 'DW_Staging',
    FILENAME = 'E:\Data\DW_Staging.ndf',
    SIZE = 50GB
) TO FILEGROUP FG_Staging;

-- TempDB optimization for ETL
-- Multiple tempdb files = parallel operations
-- Size appropriately to avoid autogrow during ETL
-- Use fast storage for tempdb

-- Transaction log optimization
-- Pre-size log file to avoid growth during loads
-- Use SIMPLE recovery during ETL window if possible
-- Checkpoint regularly in batch operations
```

---

## 📈 Monitoring and Tuning

### Performance Metrics to Track

```sql
-- SSIS execution statistics (SSISDB)
SELECT 
    es.execution_id,
    es.package_name,
    es.task_name,
    es.execution_path,
    es.start_time,
    es.end_time,
    DATEDIFF(SECOND, es.start_time, es.end_time) AS duration_seconds,
    eds.rows_sent,
    eds.rows_sent / NULLIF(DATEDIFF(SECOND, es.start_time, es.end_time), 0) AS rows_per_second
FROM catalog.executable_statistics es
JOIN catalog.execution_data_statistics eds 
    ON es.execution_id = eds.execution_id
WHERE es.execution_id = @execution_id
ORDER BY es.start_time;

-- SQL Server wait statistics during ETL
SELECT 
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    max_wait_time_ms,
    signal_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type IN (
    'PAGEIOLATCH_SH', 'PAGEIOLATCH_EX',  -- I/O waits
    'WRITELOG',                           -- Log writes
    'LCK_M_X', 'LCK_M_IX',               -- Lock waits
    'CXPACKET', 'CXCONSUMER',            -- Parallelism
    'ASYNC_NETWORK_IO'                    -- Network
)
ORDER BY wait_time_ms DESC;
```

### ETL Baseline and Trending

```sql
-- Create baseline table
CREATE TABLE ETL.PerformanceBaseline (
    BaselineID INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(255),
    LoadDate DATE,
    RowsProcessed INT,
    DurationSeconds INT,
    RowsPerSecond AS (RowsProcessed / NULLIF(DurationSeconds, 0)),
    AvgRowsPerSecond INT  -- Historical average
);

-- Alert on performance degradation
SELECT 
    TableName,
    LoadDate,
    DurationSeconds,
    RowsPerSecond,
    AvgRowsPerSecond,
    CASE 
        WHEN RowsPerSecond < AvgRowsPerSecond * 0.7 
        THEN 'DEGRADED - 30% slower than baseline'
        ELSE 'OK'
    END AS Status
FROM ETL.PerformanceBaseline
WHERE LoadDate = CAST(GETDATE() AS DATE);
```

---

## 🎓 Interview Questions

### Q1: What are the main bottlenecks in ETL processing?
**A:**
- Source: Query performance, network latency, locks
- Transform: Memory, CPU, blocking operations
- Target: Index maintenance, constraints, log growth

### Q2: How do you achieve minimal logging?
**A:**
- SIMPLE or BULK_LOGGED recovery model
- TABLOCK hint on INSERT
- Empty table or table with no indexes
- SELECT INTO (always minimal logged)
- BULK INSERT with TABLOCK

### Q3: When should you disable indexes during ETL?
**A:** For large bulk loads (>10-20% of table size). Disable before load, rebuild after. For small incremental loads, keep indexes enabled.

### Q4: What is partition switching?
**A:** SQL Server feature to instantly swap a staging table into a partition. Requires matching structure and constraints. Near-instant operation, minimal logging.

### Q5: How do you optimize SSIS Data Flow?
**A:**
- Use OLE DB Fast Load destination
- Configure buffer sizes appropriately
- Avoid Sort transformation (sort at source)
- Use Full Cache for Lookups
- Run in 64-bit mode for large data

### Q6: What is the difference between synchronous and asynchronous transformations?
**A:**
- Synchronous: Process in same buffer, fast (Derived Column)
- Asynchronous: Create new buffers, block, slow (Sort, Aggregate)
Always prefer synchronous when possible.

### Q7: How do you handle large lookup tables in SSIS?
**A:**
- Use 64-bit runtime
- Full Cache mode with proper memory
- Partial Cache if table too large
- Consider hash match join at source

### Q8: What is batch processing and why use it?
**A:** Processing data in chunks (e.g., 10,000 rows) instead of all at once. Prevents log explosion, allows checkpointing, reduces lock duration.

### Q9: How do you tune SQL queries for ETL?
**A:**
- Select only needed columns
- Filter at source (not in SSIS)
- Avoid functions on indexed columns
- Use proper indexes
- Consider NOLOCK for read-only extracts

### Q10: What metrics do you monitor for ETL performance?
**A:**
- Rows per second throughput
- Duration vs baseline
- Wait statistics (I/O, locks, log)
- Memory and CPU utilization
- Buffer usage in SSIS

---

## 🔗 Related Topics
- [← Metadata-Driven ETL](./04_metadata_driven_etl.md)
- [SSIS Development →](../Module_06_ETL_SSIS/)
- [SQL Performance →](../Module_04_SQL_Performance/)

---

*Module 07 Complete! Continue to Python Track modules.*
