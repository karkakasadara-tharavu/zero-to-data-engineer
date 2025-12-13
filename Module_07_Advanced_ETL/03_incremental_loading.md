# Incremental Loading Patterns - Complete Guide

## 📚 What You'll Learn
- Incremental vs full load strategies
- Watermark-based loading
- Timestamp-based detection
- Hash-based change detection
- Delta loading patterns
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Why Incremental Loading?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FULL LOAD vs INCREMENTAL LOAD                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   FULL LOAD:                                                             │
│   ┌────────────────────┐         ┌────────────────────┐                 │
│   │ Source Table       │ ──ALL──▶│ Target Table       │                 │
│   │ 10 million rows    │  ROWS   │ (truncated first)  │                 │
│   └────────────────────┘         └────────────────────┘                 │
│   Time: 2 hours | Pros: Simple | Cons: Slow, resource heavy            │
│                                                                          │
│   INCREMENTAL LOAD:                                                      │
│   ┌────────────────────┐         ┌────────────────────┐                 │
│   │ Source Table       │ CHANGED │ Target Table       │                 │
│   │ 10 million rows    │──ONLY──▶│ (append/update)    │                 │
│   │ (1000 changed)     │         │                    │                 │
│   └────────────────────┘         └────────────────────┘                 │
│   Time: 2 minutes | Pros: Fast, efficient | Cons: More complex         │
│                                                                          │
│   When to Use Incremental:                                               │
│   ├── Large tables (millions of rows)                                   │
│   ├── Frequent loads (hourly, daily)                                    │
│   ├── Limited ETL window                                                │
│   └── Network/resource constraints                                      │
│                                                                          │
│   When to Use Full Load:                                                 │
│   ├── Small tables (thousands of rows)                                  │
│   ├── No reliable change detection                                      │
│   ├── Periodic full refresh required                                    │
│   └── Source doesn't support incremental                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Incremental Loading Strategies

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CHANGE DETECTION METHODS                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. TIMESTAMP-BASED (Most Common)                                       │
│      └── Use LastModifiedDate column                                    │
│                                                                          │
│   2. CDC/CHANGE TRACKING (Most Reliable)                                │
│      └── SQL Server CDC or Change Tracking                              │
│                                                                          │
│   3. VERSION/SEQUENCE-BASED                                              │
│      └── Incrementing version number or ID                              │
│                                                                          │
│   4. HASH-BASED                                                          │
│      └── Compare row hash values                                        │
│                                                                          │
│   5. TRIGGER-BASED                                                       │
│      └── Log changes to tracking table                                  │
│                                                                          │
│   6. FULL TABLE COMPARISON                                               │
│      └── EXCEPT/MINUS operations                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## ⏰ Timestamp-Based Loading

### High Watermark Pattern

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    HIGH WATERMARK PATTERN                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Run 1: Load records where ModifiedDate > '2024-01-01 00:00:00'        │
│          Store watermark: '2024-01-15 14:30:00' (max ModifiedDate)      │
│                                                                          │
│   Run 2: Load records where ModifiedDate > '2024-01-15 14:30:00'        │
│          Store watermark: '2024-01-16 10:45:00'                         │
│                                                                          │
│   Run 3: Load records where ModifiedDate > '2024-01-16 10:45:00'        │
│          Store watermark: '2024-01-16 18:20:00'                         │
│                                                                          │
│   ┌─────────────┐                                                        │
│   │ Control     │  Stores last processed timestamp                       │
│   │ Table       │  for each source table                                │
│   └──────┬──────┘                                                        │
│          │                                                               │
│          ▼                                                               │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ SELECT * FROM Source                                              │  │
│   │ WHERE ModifiedDate > @LastWatermark                              │  │
│   │   AND ModifiedDate <= @CurrentWatermark                          │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Implementation

```sql
-- Control table for watermarks
CREATE TABLE ETL_Watermark (
    TableName VARCHAR(255) PRIMARY KEY,
    LastWatermark DATETIME2,
    LastRunTime DATETIME2,
    RowsProcessed INT,
    Status VARCHAR(20)
);

-- Initialize watermark
INSERT INTO ETL_Watermark 
VALUES ('dbo.Orders', '1900-01-01', NULL, 0, 'Ready');

-- Incremental load procedure
CREATE PROCEDURE usp_IncrementalLoad_Orders
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastWatermark DATETIME2;
    DECLARE @CurrentWatermark DATETIME2;
    DECLARE @RowCount INT;
    
    BEGIN TRY
        -- Get last watermark
        SELECT @LastWatermark = LastWatermark
        FROM ETL_Watermark
        WHERE TableName = 'dbo.Orders';
        
        -- Get current watermark (capture before processing)
        SELECT @CurrentWatermark = MAX(ModifiedDate)
        FROM SourceDB.dbo.Orders
        WHERE ModifiedDate > @LastWatermark;
        
        -- If no new data, exit
        IF @CurrentWatermark IS NULL
        BEGIN
            PRINT 'No new data to process';
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Load changed records to staging
        INSERT INTO Staging.dbo.Orders_Incremental (
            OrderID, CustomerID, OrderDate, TotalAmount, 
            ModifiedDate, ChangeType
        )
        SELECT 
            s.OrderID,
            s.CustomerID,
            s.OrderDate,
            s.TotalAmount,
            s.ModifiedDate,
            CASE 
                WHEN t.OrderID IS NULL THEN 'INSERT'
                ELSE 'UPDATE'
            END AS ChangeType
        FROM SourceDB.dbo.Orders s
        LEFT JOIN TargetDB.dbo.Orders t ON s.OrderID = t.OrderID
        WHERE s.ModifiedDate > @LastWatermark
          AND s.ModifiedDate <= @CurrentWatermark;
        
        SET @RowCount = @@ROWCOUNT;
        
        -- Apply changes using MERGE
        MERGE TargetDB.dbo.Orders AS target
        USING Staging.dbo.Orders_Incremental AS source
        ON target.OrderID = source.OrderID
        
        WHEN MATCHED THEN
            UPDATE SET
                CustomerID = source.CustomerID,
                OrderDate = source.OrderDate,
                TotalAmount = source.TotalAmount,
                ModifiedDate = source.ModifiedDate
        
        WHEN NOT MATCHED THEN
            INSERT (OrderID, CustomerID, OrderDate, TotalAmount, ModifiedDate)
            VALUES (source.OrderID, source.CustomerID, source.OrderDate, 
                    source.TotalAmount, source.ModifiedDate);
        
        -- Update watermark
        UPDATE ETL_Watermark
        SET LastWatermark = @CurrentWatermark,
            LastRunTime = GETDATE(),
            RowsProcessed = @RowCount,
            Status = 'Success'
        WHERE TableName = 'dbo.Orders';
        
        -- Clear staging
        TRUNCATE TABLE Staging.dbo.Orders_Incremental;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        UPDATE ETL_Watermark
        SET Status = 'Failed: ' + ERROR_MESSAGE(),
            LastRunTime = GETDATE()
        WHERE TableName = 'dbo.Orders';
        
        THROW;
    END CATCH
END;
```

### Handling Late-Arriving Data

```sql
-- Problem: Records might be modified with earlier timestamps

-- Solution 1: Look back window
WHERE ModifiedDate > DATEADD(HOUR, -1, @LastWatermark)  -- 1 hour overlap

-- Solution 2: Dual watermark (High + Low)
WHERE ModifiedDate > @LowWatermark   -- Allow some overlap
  AND ModifiedDate <= @HighWatermark

-- Solution 3: Track max ID along with timestamp
WHERE ModifiedDate > @LastWatermark
   OR (ModifiedDate = @LastWatermark AND OrderID > @LastOrderID)
```

---

## 🔢 Sequence-Based Loading

Using auto-increment ID or sequence numbers.

```sql
-- Control table
CREATE TABLE ETL_Sequence_Control (
    TableName VARCHAR(255) PRIMARY KEY,
    LastProcessedID BIGINT,
    LastRunTime DATETIME
);

-- Incremental load using ID
DECLARE @LastID BIGINT;
SELECT @LastID = LastProcessedID 
FROM ETL_Sequence_Control 
WHERE TableName = 'Orders';

-- Get new/changed records
INSERT INTO Target.Orders
SELECT *
FROM Source.Orders
WHERE OrderID > @LastID;

-- Update control
UPDATE ETL_Sequence_Control
SET LastProcessedID = (SELECT MAX(OrderID) FROM Source.Orders),
    LastRunTime = GETDATE()
WHERE TableName = 'Orders';

-- LIMITATION: Only works for INSERTS, not updates!
-- Need additional strategy for updates
```

---

## 🔐 Hash-Based Change Detection

Compare row hashes to detect changes.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    HASH-BASED CHANGE DETECTION                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Source Row:                                                            │
│   OrderID=1, Customer='John', Amount=100                                │
│   HASH → 0x7A4B2C1D                                                     │
│                                                                          │
│   Target Row:                                                            │
│   OrderID=1, Customer='John', Amount=100                                │
│   HASH → 0x7A4B2C1D                                                     │
│                                                                          │
│   Compare: Hashes match → No change                                      │
│                                                                          │
│   After update (Amount changed):                                         │
│   Source HASH → 0x8B5C3D2E                                              │
│   Target HASH → 0x7A4B2C1D                                              │
│                                                                          │
│   Compare: Hashes differ → Changed record!                              │
│                                                                          │
│   Advantages:                                                            │
│   ├── Works without ModifiedDate column                                 │
│   ├── Detects any column change                                         │
│   └── Single comparison per row                                         │
│                                                                          │
│   Disadvantages:                                                         │
│   ├── Must read entire table to compare                                 │
│   ├── Compute overhead for hash calculation                            │
│   └── Collision risk (very low)                                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Hash Implementation

```sql
-- Add hash column to table
ALTER TABLE Target.Orders
ADD RowHash VARBINARY(32);

-- Calculate hash for a row (SQL Server)
SELECT 
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount,
    HASHBYTES('SHA2_256', 
        CONCAT(
            CAST(CustomerID AS VARCHAR(20)), '|',
            CONVERT(VARCHAR(30), OrderDate, 121), '|',
            CAST(TotalAmount AS VARCHAR(30))
        )
    ) AS RowHash
FROM Orders;

-- Compare source and target hashes
SELECT 
    s.OrderID,
    CASE 
        WHEN t.OrderID IS NULL THEN 'INSERT'
        WHEN s.RowHash <> t.RowHash THEN 'UPDATE'
        ELSE 'NO CHANGE'
    END AS ChangeType
FROM (
    SELECT OrderID, 
           HASHBYTES('SHA2_256', 
               CONCAT(CustomerID, '|', OrderDate, '|', TotalAmount)) AS RowHash
    FROM Source.Orders
) s
FULL OUTER JOIN Target.Orders t ON s.OrderID = t.OrderID
WHERE t.OrderID IS NULL              -- New in source
   OR s.OrderID IS NULL              -- Deleted in source
   OR s.RowHash <> t.RowHash;        -- Changed
```

### Using Checksum

```sql
-- Faster but less collision-resistant than HASHBYTES
SELECT 
    OrderID,
    CHECKSUM(CustomerID, OrderDate, TotalAmount) AS RowChecksum
FROM Orders;

-- Binary checksum (byte-by-byte)
SELECT 
    OrderID,
    BINARY_CHECKSUM(*) AS RowChecksum
FROM Orders;
```

---

## 🔄 Full Table Comparison

Using EXCEPT for change detection.

```sql
-- Find new/changed records in source
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM Source.Orders

EXCEPT

SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM Target.Orders;

-- Find deleted records (in target but not source)
SELECT OrderID
FROM Target.Orders

EXCEPT

SELECT OrderID
FROM Source.Orders;

-- Complete comparison procedure
CREATE PROCEDURE usp_SyncOrders
AS
BEGIN
    -- Insert new/updated records
    MERGE Target.Orders AS t
    USING (
        SELECT * FROM Source.Orders
        EXCEPT
        SELECT * FROM Target.Orders
    ) AS s
    ON t.OrderID = s.OrderID
    
    WHEN MATCHED THEN
        UPDATE SET
            CustomerID = s.CustomerID,
            OrderDate = s.OrderDate,
            TotalAmount = s.TotalAmount
    
    WHEN NOT MATCHED THEN
        INSERT (OrderID, CustomerID, OrderDate, TotalAmount)
        VALUES (s.OrderID, s.CustomerID, s.OrderDate, s.TotalAmount);
    
    -- Handle deletes
    DELETE FROM Target.Orders
    WHERE OrderID NOT IN (SELECT OrderID FROM Source.Orders);
END;
```

---

## 📋 Delta Table Pattern

Capture changes in a delta/staging table.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DELTA TABLE PATTERN                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────────┐     ┌─────────────────┐     ┌────────────────┐         │
│   │ Source     │ ──▶ │ Delta Table     │ ──▶ │ Target Table   │         │
│   │ System     │     │ (Changes Only)  │     │ (Final State)  │         │
│   └────────────┘     └─────────────────┘     └────────────────┘         │
│                                                                          │
│   Delta Table Structure:                                                 │
│   ├── All source columns                                                │
│   ├── ChangeType (I/U/D)                                                │
│   ├── ChangeTimestamp                                                   │
│   ├── BatchID                                                           │
│   └── ProcessedFlag                                                     │
│                                                                          │
│   Process Flow:                                                          │
│   1. Extract changes from source to Delta                               │
│   2. Apply Delta to Target (in correct order)                          │
│   3. Mark Delta records as processed                                   │
│   4. Archive or purge old Delta records                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Delta Table Implementation

```sql
-- Delta table structure
CREATE TABLE Delta.Orders (
    DeltaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(18,2),
    ChangeType CHAR(1),        -- I=Insert, U=Update, D=Delete
    ChangeTimestamp DATETIME DEFAULT GETDATE(),
    BatchID UNIQUEIDENTIFIER,
    IsProcessed BIT DEFAULT 0,
    ProcessedTime DATETIME NULL
);

-- Apply delta changes
CREATE PROCEDURE usp_ApplyDeltaChanges
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    -- Process DELETES first
    DELETE t
    FROM Target.Orders t
    INNER JOIN Delta.Orders d 
        ON t.OrderID = d.OrderID
    WHERE d.BatchID = @BatchID 
      AND d.ChangeType = 'D'
      AND d.IsProcessed = 0;
    
    -- Process INSERTS
    INSERT INTO Target.Orders (OrderID, CustomerID, OrderDate, TotalAmount)
    SELECT OrderID, CustomerID, OrderDate, TotalAmount
    FROM Delta.Orders
    WHERE BatchID = @BatchID 
      AND ChangeType = 'I'
      AND IsProcessed = 0;
    
    -- Process UPDATES
    UPDATE t
    SET t.CustomerID = d.CustomerID,
        t.OrderDate = d.OrderDate,
        t.TotalAmount = d.TotalAmount
    FROM Target.Orders t
    INNER JOIN Delta.Orders d 
        ON t.OrderID = d.OrderID
    WHERE d.BatchID = @BatchID 
      AND d.ChangeType = 'U'
      AND d.IsProcessed = 0;
    
    -- Mark as processed
    UPDATE Delta.Orders
    SET IsProcessed = 1,
        ProcessedTime = GETDATE()
    WHERE BatchID = @BatchID;
END;
```

---

## 📈 Partition-Based Incremental Loading

For very large fact tables.

```sql
-- Partition switching for incremental loads
-- (SQL Server Enterprise Edition)

-- 1. Create staging table with same structure
CREATE TABLE Staging.FactSales (
    DateKey INT,
    ProductKey INT,
    SalesAmount DECIMAL(18,2),
    Quantity INT
) ON [PartitionScheme](DateKey);

-- 2. Load new partition data to staging
INSERT INTO Staging.FactSales
SELECT * FROM Source.Sales
WHERE DateKey BETWEEN @StartDate AND @EndDate;

-- 3. Switch partition (instant operation!)
ALTER TABLE Staging.FactSales
SWITCH PARTITION @PartitionNumber
TO Warehouse.FactSales PARTITION @PartitionNumber;

-- Benefits:
-- ├── No row-by-row insert
-- ├── Instant partition switch
-- ├── Minimal logging
-- └── No blocking on main table
```

---

## 🎓 Interview Questions

### Q1: What is incremental loading?
**A:** Loading only new or changed records since the last ETL run, rather than reloading the entire table. More efficient for large tables with frequent loads.

### Q2: What is a watermark in ETL?
**A:** A marker (usually timestamp or ID) that tracks the last successfully processed point in the source data. Used to identify new/changed records in subsequent runs.

### Q3: What are the main change detection strategies?
**A:**
- Timestamp-based (ModifiedDate > LastWatermark)
- CDC/Change Tracking (SQL Server features)
- Sequence-based (ID > LastProcessedID)
- Hash-based (compare row hashes)
- Full comparison (EXCEPT queries)

### Q4: When would you use hash-based change detection?
**A:** When source has no timestamp/audit columns, need to detect any column change, or comparing across different database platforms.

### Q5: What is late-arriving data and how do you handle it?
**A:** Data with older timestamps that arrives after the watermark has advanced. Handle with:
- Look-back window (overlap period)
- Full comparison for critical tables
- Dual watermarks (low + high)

### Q6: What is a delta table?
**A:** A staging table that stores only changed records with change type (I/U/D). Acts as a buffer between source and target, allowing controlled application of changes.

### Q7: How do you handle deletes in incremental loads?
**A:**
- Soft delete (flag as deleted)
- Full comparison to find missing records
- CDC captures deletes automatically
- Trigger-based delete tracking

### Q8: What is partition switching?
**A:** SQL Server Enterprise feature to instantly swap a partition between tables. Used for bulk loading without row-by-row inserts, minimal logging.

### Q9: How do you ensure idempotency in incremental loads?
**A:**
- Use MERGE instead of INSERT for upserts
- Check if record exists before processing
- Store watermarks in same transaction as data
- Design for re-runnable processes

### Q10: What are the risks of timestamp-based loading?
**A:**
- Clock skew between servers
- Transactions in progress during capture
- Missing timestamps on old data
- Incorrect timestamp updates
Always capture watermark BEFORE extracting data.

---

## 🔗 Related Topics
- [← Slowly Changing Dimensions](./02_slowly_changing_dimensions.md)
- [Metadata-Driven ETL →](./04_metadata_driven_etl.md)
- [CDC in SQL Server →](./01_change_data_capture.md)

---

*Next: Learn about Metadata-Driven ETL*
