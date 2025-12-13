# Change Data Capture (CDC) - Complete Guide

## 📚 What You'll Learn
- Understanding CDC fundamentals
- SQL Server CDC implementation
- CDC in ETL pipelines
- Performance considerations
- Alternative change tracking methods
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 What is Change Data Capture?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CHANGE DATA CAPTURE (CDC)                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Definition:                                                            │
│   CDC is a technology that captures INSERT, UPDATE, and DELETE          │
│   operations on database tables and records changes in a readable        │
│   format for downstream processing.                                      │
│                                                                          │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────────────────┐   │
│   │ Source      │ →→→ │ Transaction │ →→→ │ CDC Change Tables       │   │
│   │ Tables      │     │ Log         │     │ (cdc.dbo_tablename_CT)  │   │
│   │ (DML ops)   │     │             │     │                         │   │
│   └─────────────┘     └─────────────┘     └───────────┬─────────────┘   │
│                                                        │                 │
│                                           ┌────────────▼────────────┐   │
│                                           │ ETL Process             │   │
│                                           │ - Read changes          │   │
│                                           │ - Apply to target       │   │
│                                           │ - Track LSN             │   │
│                                           └─────────────────────────┘   │
│                                                                          │
│   Key Benefits:                                                          │
│   ├── No triggers needed (uses transaction log)                        │
│   ├── Minimal impact on source system                                   │
│   ├── Captures all change types (I/U/D)                                │
│   ├── Supports incremental loading                                      │
│   └── Preserves change history                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 SQL Server CDC Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CDC ARCHITECTURE                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                     SOURCE DATABASE                              │   │
│   │  ┌──────────┐                                                    │   │
│   │  │ Table    │  DML Operations                                    │   │
│   │  │ (Orders) │  (INSERT, UPDATE, DELETE)                         │   │
│   │  └────┬─────┘                                                    │   │
│   │       │                                                          │   │
│   │       ▼                                                          │   │
│   │  ┌──────────────────┐     ┌─────────────────────────────────┐   │   │
│   │  │ Transaction Log  │ ──▶ │ CDC Capture Process             │   │   │
│   │  │ (LDF file)       │     │ (SQL Server Agent Job)          │   │   │
│   │  └──────────────────┘     └─────────────┬───────────────────┘   │   │
│   │                                          │                       │   │
│   │                                          ▼                       │   │
│   │  ┌────────────────────────────────────────────────────────────┐ │   │
│   │  │ CDC System Tables                                          │ │   │
│   │  │ ├── cdc.dbo_Orders_CT         (Change Table)              │ │   │
│   │  │ ├── cdc.change_tables         (Metadata)                  │ │   │
│   │  │ ├── cdc.captured_columns      (Column info)               │ │   │
│   │  │ ├── cdc.index_columns         (Index info)                │ │   │
│   │  │ └── cdc.lsn_time_mapping      (LSN to time mapping)       │ │   │
│   │  └────────────────────────────────────────────────────────────┘ │   │
│   │                                                                  │   │
│   │  SQL Agent Jobs (automatically created):                        │   │
│   │  ├── cdc.<capture_instance>_capture  (reads log, populates CT)│   │
│   │  └── cdc.<capture_instance>_cleanup  (removes old entries)    │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Log Sequence Number (LSN)

```
LSN Structure:
┌────────────────────────────────────────┐
│ 00000024:00000A40:0001                 │
│ └──┬───┘ └──┬───┘ └─┬─┘               │
│    │        │       │                  │
│    │        │       └── Slot Number    │
│    │        └────────── Block Number   │
│    └─────────────────── VLF Sequence   │
└────────────────────────────────────────┘

Purpose:
├── Uniquely identifies log record
├── Chronologically ordered
├── Used to track CDC read position
└── Maps to approximate time via lsn_time_mapping
```

---

## 💻 Enabling CDC

### Database Level

```sql
-- Enable CDC on database
USE YourDatabase;
EXEC sys.sp_cdc_enable_db;

-- Verify CDC is enabled
SELECT name, is_cdc_enabled 
FROM sys.databases 
WHERE name = 'YourDatabase';
```

### Table Level

```sql
-- Enable CDC on table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Orders',
    @role_name = N'cdc_admin',      -- Security role (optional)
    @capture_instance = N'dbo_Orders', -- Name for capture instance
    @supports_net_changes = 1,      -- Enable net changes queries
    @index_name = N'PK_Orders',     -- Unique index for net changes
    @captured_column_list = NULL,   -- NULL = all columns
    @filegroup_name = N'PRIMARY';   -- Filegroup for change table

-- Verify table is enabled
SELECT * FROM cdc.change_tables;

-- List captured columns
SELECT * FROM cdc.captured_columns;
```

### Disabling CDC

```sql
-- Disable CDC on table
EXEC sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'Orders',
    @capture_instance = N'dbo_Orders';

-- Disable CDC on database
EXEC sys.sp_cdc_disable_db;
```

---

## 📊 Reading CDC Changes

### Change Table Structure

```sql
-- Change table columns (cdc.dbo_Orders_CT)
/*
__$start_lsn      - LSN when change was committed
__$end_lsn        - Reserved (NULL)
__$seqval         - Sequence value for ordering within transaction
__$operation      - 1=Delete, 2=Insert, 3=Before Update, 4=After Update
__$update_mask    - Bitmask of changed columns
[captured columns] - All source table columns captured
*/

-- Operation codes
-- 1 = Delete (row before delete)
-- 2 = Insert (row after insert)
-- 3 = Update (row BEFORE update - old values)
-- 4 = Update (row AFTER update - new values)
```

### Getting All Changes

```sql
-- Get all changes between two LSN values
DECLARE @from_lsn BINARY(10), @to_lsn BINARY(10);

-- Get LSN range (e.g., last 24 hours)
SET @from_lsn = sys.fn_cdc_map_time_to_lsn('smallest greater than or equal', 
                                            DATEADD(HOUR, -24, GETDATE()));
SET @to_lsn = sys.fn_cdc_get_max_lsn();

-- Query all changes
SELECT 
    __$operation,
    CASE __$operation
        WHEN 1 THEN 'Delete'
        WHEN 2 THEN 'Insert'
        WHEN 3 THEN 'Before Update'
        WHEN 4 THEN 'After Update'
    END AS OperationType,
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount
FROM cdc.fn_cdc_get_all_changes_dbo_Orders(@from_lsn, @to_lsn, 'all')
ORDER BY __$start_lsn, __$seqval;
```

### Getting Net Changes

```sql
-- Net changes: Final state only (requires @supports_net_changes = 1)
-- Only one row per primary key showing final result

SELECT 
    __$operation,
    CASE __$operation
        WHEN 1 THEN 'Delete'
        WHEN 2 THEN 'Insert'
        WHEN 4 THEN 'Update'
    END AS OperationType,
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount
FROM cdc.fn_cdc_get_net_changes_dbo_Orders(@from_lsn, @to_lsn, 'all')
ORDER BY OrderID;

-- row_filter_option:
-- 'all' - Returns all rows with __$update_mask
-- 'all with mask' - Same as 'all'
-- 'all with merge' - Merges inserts and updates
```

### Working with LSN

```sql
-- Get current maximum LSN
SELECT sys.fn_cdc_get_max_lsn() AS CurrentMaxLSN;

-- Get minimum LSN for a capture instance
SELECT sys.fn_cdc_get_min_lsn('dbo_Orders') AS MinAvailableLSN;

-- Increment LSN (for next batch start)
SELECT sys.fn_cdc_increment_lsn(@to_lsn) AS NextStartLSN;

-- Map time to LSN
SELECT sys.fn_cdc_map_time_to_lsn('smallest greater than', '2024-01-15 00:00:00');

-- Map LSN to time
SELECT sys.fn_cdc_map_lsn_to_time(@lsn) AS ApproximateTime;

-- LSN range checking
SELECT 
    CASE 
        WHEN @from_lsn >= sys.fn_cdc_get_min_lsn('dbo_Orders') 
        THEN 'Valid Range'
        ELSE 'Data Already Cleaned Up!'
    END AS RangeStatus;
```

---

## 🔄 CDC in ETL Pipeline

### Incremental Load Pattern

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CDC ETL PATTERN                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. Track Last Processed LSN                                            │
│      ├── Store in control table                                         │
│      └── Retrieve at start of each run                                  │
│                                                                          │
│   2. Get Current Maximum LSN                                             │
│      └── sys.fn_cdc_get_max_lsn()                                       │
│                                                                          │
│   3. Query Changes                                                       │
│      └── cdc.fn_cdc_get_net_changes(last_lsn + 1, current_lsn)         │
│                                                                          │
│   4. Apply Changes to Target                                             │
│      ├── Inserts → INSERT                                               │
│      ├── Updates → UPDATE or MERGE                                      │
│      └── Deletes → DELETE or soft delete                                │
│                                                                          │
│   5. Update Tracking Table                                               │
│      └── Store current_lsn for next run                                 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### ETL Implementation Example

```sql
-- 1. Create control table for LSN tracking
CREATE TABLE ETL_CDC_Control (
    SourceTable VARCHAR(255) PRIMARY KEY,
    LastProcessedLSN BINARY(10),
    LastProcessedTime DATETIME,
    RowsProcessed INT,
    LastRunStatus VARCHAR(20)
);

-- Initialize
INSERT INTO ETL_CDC_Control 
VALUES ('dbo.Orders', 0x00000000000000000000, NULL, 0, 'Initialized');

-- 2. ETL Procedure
CREATE PROCEDURE usp_ETL_ProcessOrdersCDC
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @from_lsn BINARY(10);
    DECLARE @to_lsn BINARY(10);
    DECLARE @min_lsn BINARY(10);
    DECLARE @rows_processed INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get last processed LSN
        SELECT @from_lsn = LastProcessedLSN 
        FROM ETL_CDC_Control 
        WHERE SourceTable = 'dbo.Orders';
        
        -- Get current max LSN
        SET @to_lsn = sys.fn_cdc_get_max_lsn();
        
        -- Validate LSN range
        SET @min_lsn = sys.fn_cdc_get_min_lsn('dbo_Orders');
        
        IF @from_lsn < @min_lsn
        BEGIN
            RAISERROR('CDC data has been cleaned up. Full reload required.', 16, 1);
            RETURN;
        END
        
        -- Increment from_lsn to avoid reprocessing
        SET @from_lsn = sys.fn_cdc_increment_lsn(@from_lsn);
        
        -- Process changes if any
        IF @from_lsn <= @to_lsn
        BEGIN
            -- Apply to staging/target using MERGE
            MERGE DW.dbo.DimOrders AS target
            USING (
                SELECT 
                    __$operation,
                    OrderID,
                    CustomerID,
                    OrderDate,
                    TotalAmount
                FROM cdc.fn_cdc_get_net_changes_dbo_Orders(
                    @from_lsn, @to_lsn, 'all with merge')
            ) AS source
            ON target.OrderID = source.OrderID
            
            WHEN MATCHED AND source.__$operation = 1 THEN
                DELETE
                
            WHEN MATCHED AND source.__$operation IN (4, 5) THEN
                UPDATE SET 
                    CustomerID = source.CustomerID,
                    OrderDate = source.OrderDate,
                    TotalAmount = source.TotalAmount,
                    LastModified = GETDATE()
                    
            WHEN NOT MATCHED AND source.__$operation IN (2, 4) THEN
                INSERT (OrderID, CustomerID, OrderDate, TotalAmount, LastModified)
                VALUES (source.OrderID, source.CustomerID, source.OrderDate, 
                        source.TotalAmount, GETDATE());
            
            SET @rows_processed = @@ROWCOUNT;
        END
        
        -- Update control table
        UPDATE ETL_CDC_Control
        SET LastProcessedLSN = @to_lsn,
            LastProcessedTime = GETDATE(),
            RowsProcessed = @rows_processed,
            LastRunStatus = 'Success'
        WHERE SourceTable = 'dbo.Orders';
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        UPDATE ETL_CDC_Control
        SET LastRunStatus = 'Failed: ' + ERROR_MESSAGE()
        WHERE SourceTable = 'dbo.Orders';
        
        THROW;
    END CATCH
END;
```

---

## ⚙️ CDC Configuration

### Capture Job Settings

```sql
-- View capture job parameters
EXEC sys.sp_cdc_help_jobs;

-- Modify capture job (runs by default every 5 seconds)
EXEC sys.sp_cdc_change_job
    @job_type = N'capture',
    @maxtrans = 500,        -- Max transactions per scan
    @maxscans = 10,         -- Max scans per polling interval
    @continuous = 1,        -- Run continuously
    @pollinginterval = 5;   -- Seconds between scans

-- Start/Stop capture job
EXEC sys.sp_cdc_start_job @job_type = N'capture';
EXEC sys.sp_cdc_stop_job @job_type = N'capture';
```

### Cleanup Job Settings

```sql
-- Modify cleanup job (default: 3 days retention)
EXEC sys.sp_cdc_change_job
    @job_type = N'cleanup',
    @retention = 4320;      -- Minutes (3 days = 4320)

-- Clean up manually
DECLARE @low_watermark BINARY(10);
SET @low_watermark = sys.fn_cdc_map_time_to_lsn(
    'largest less than or equal',
    DATEADD(DAY, -7, GETDATE())
);

EXEC sys.sp_cdc_cleanup_change_table
    @capture_instance = N'dbo_Orders',
    @low_water_mark = @low_watermark,
    @threshold = 5000;
```

---

## 🔀 Alternative: Change Tracking

```
┌─────────────────────────────────────────────────────────────────────────┐
│               CDC vs CHANGE TRACKING                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Feature              │ CDC                │ Change Tracking            │
│   ─────────────────────┼────────────────────┼───────────────────────────│
│   Tracks what changed  │ ✓ Full row data   │ ✗ Only primary keys       │
│   Overhead             │ Higher             │ Lower                      │
│   Transaction log      │ Required           │ Not required               │
│   Old values captured  │ ✓ Before/After    │ ✗ No                       │
│   Asynchronous         │ ✓                  │ ✗ Synchronous             │
│   SQL Agent required   │ ✓                  │ ✗ No                       │
│   Which columns changed│ ✓                  │ ✓                          │
│   Order of changes     │ ✓                  │ ✗ No                       │
│                                                                          │
│   Use CDC when:                                                          │
│   ├── Need complete row data                                            │
│   ├── Need before/after values                                          │
│   ├── Need order of changes                                             │
│   └── Data warehouse loading                                            │
│                                                                          │
│   Use Change Tracking when:                                              │
│   ├── Only need to know what changed (not values)                       │
│   ├── Low overhead is critical                                          │
│   ├── Sync scenarios (like Sync Framework)                              │
│   └── Can query source for current values                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Change Tracking Example

```sql
-- Enable on database
ALTER DATABASE YourDatabase
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

-- Enable on table
ALTER TABLE dbo.Orders
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON);

-- Query changes
DECLARE @last_sync_version BIGINT = 0;

SELECT 
    CT.OrderID,
    CT.SYS_CHANGE_OPERATION, -- I, U, D
    CT.SYS_CHANGE_COLUMNS,
    O.CustomerID,
    O.OrderDate,
    O.TotalAmount
FROM CHANGETABLE(CHANGES dbo.Orders, @last_sync_version) AS CT
LEFT JOIN dbo.Orders O ON CT.OrderID = O.OrderID;

-- Get current version
SELECT CHANGE_TRACKING_CURRENT_VERSION();
```

---

## 🎓 Interview Questions

### Q1: What is Change Data Capture (CDC)?
**A:** CDC is a SQL Server feature that captures INSERT, UPDATE, and DELETE operations by reading the transaction log and storing changes in system change tables. Enables incremental data loading without triggers.

### Q2: How does CDC differ from triggers?
**A:**
- **CDC**: Asynchronous, reads transaction log, minimal overhead
- **Triggers**: Synchronous, runs during DML, adds latency to transactions
- CDC is preferred for ETL; triggers for immediate business logic

### Q3: What is an LSN and why is it important?
**A:** Log Sequence Number uniquely identifies transaction log records. Used to track CDC read position and ensure changes are processed in order. Critical for incremental loading - track last LSN to know where to resume.

### Q4: What is the difference between all changes and net changes?
**A:**
- **All Changes**: Every change record (may have multiple rows per key)
- **Net Changes**: Final state only (one row per key showing end result)
- Net changes requires unique index and @supports_net_changes=1

### Q5: How do you handle CDC cleanup removing needed data?
**A:**
- Monitor minimum LSN vs last processed LSN
- Increase retention period (sp_cdc_change_job)
- If gap detected, perform full reload
- Store last processed LSN in control table and validate

### Q6: What happens if capture job stops?
**A:**
- Changes accumulate in transaction log
- Log file may grow significantly
- When restarted, processes accumulated changes
- If log wraps before capture, data loss occurs

### Q7: How do you enable CDC?
**A:**
1. Enable on database: `sys.sp_cdc_enable_db`
2. Enable on table: `sys.sp_cdc_enable_table`
3. SQL Agent must be running for capture/cleanup jobs

### Q8: What is the __$operation column?
**A:** Operation type: 1=Delete, 2=Insert, 3=Before Update (old values), 4=After Update (new values)

### Q9: What is Change Tracking and when use it over CDC?
**A:** Change Tracking is lighter-weight, only tracks which rows changed (not values). Use when you only need to know what changed and can query source for current values. Lower overhead but less information.

### Q10: How do you implement incremental ETL with CDC?
**A:**
1. Store last processed LSN in control table
2. Get current max LSN
3. Query fn_cdc_get_net_changes between LSNs
4. Apply changes using MERGE
5. Update control table with new LSN

---

## 🔗 Related Topics
- [Slowly Changing Dimensions →](./02_slowly_changing_dimensions.md)
- [Incremental Loading →](./03_incremental_loading.md)
- [SSIS CDC Components →](../Module_06_ETL_SSIS/)

---

*Next: Learn about Slowly Changing Dimensions*
