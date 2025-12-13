# Metadata-Driven ETL - Complete Guide

## 📚 What You'll Learn
- Understanding metadata-driven design
- Configuration tables for ETL
- Dynamic package patterns
- Parameterized pipelines
- Scalable ETL frameworks
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 What is Metadata-Driven ETL?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    METADATA-DRIVEN ETL                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Traditional ETL:                                                       │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│   │ Package for │  │ Package for │  │ Package for │  │ Package for │   │
│   │ Customers   │  │ Orders      │  │ Products    │  │ Employees   │   │
│   │ (hardcoded) │  │ (hardcoded) │  │ (hardcoded) │  │ (hardcoded) │   │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│   100 tables = 100 packages = 100 maintenance points                   │
│                                                                          │
│   Metadata-Driven ETL:                                                   │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ Configuration Database                                           │  │
│   │ ┌────────────────────────────────────────────────────────────┐  │  │
│   │ │ Table    │ Source    │ Target    │ Load Type │ Schedule   │  │  │
│   │ ├──────────┼───────────┼───────────┼───────────┼────────────┤  │  │
│   │ │ Customer │ OLTP.dbo  │ DW.dbo    │ Full      │ Daily      │  │  │
│   │ │ Orders   │ OLTP.dbo  │ DW.dbo    │ Incr      │ Hourly     │  │  │
│   │ │ Products │ OLTP.dbo  │ DW.dbo    │ Full      │ Weekly     │  │  │
│   │ └────────────────────────────────────────────────────────────┘  │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                          │                                               │
│                          ▼                                               │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │                  GENERIC ETL PACKAGE                             │  │
│   │      Reads config → Builds query → Loads data dynamically       │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│   Benefits:                                                              │
│   ├── Add new tables: Update config, not code                           │
│   ├── Single package to maintain                                        │
│   ├── Consistent patterns across all tables                            │
│   ├── Easy testing and deployment                                       │
│   └── Self-documenting (config IS the documentation)                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Configuration Tables Design

### Core Metadata Tables

```sql
-- Master configuration table
CREATE TABLE ETL.TableConfig (
    TableConfigID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Source Information
    SourceSchema VARCHAR(128) NOT NULL,
    SourceTable VARCHAR(128) NOT NULL,
    SourceDatabase VARCHAR(128),
    SourceServer VARCHAR(255),
    SourceConnectionName VARCHAR(100),
    
    -- Target Information
    TargetSchema VARCHAR(128) NOT NULL,
    TargetTable VARCHAR(128) NOT NULL,
    TargetDatabase VARCHAR(128),
    
    -- Load Configuration
    LoadType VARCHAR(20) NOT NULL,       -- Full, Incremental, CDC
    IncrementalColumn VARCHAR(128),       -- For watermark-based loads
    PrimaryKeyColumns VARCHAR(500),       -- For merge operations
    
    -- Scheduling
    LoadGroup VARCHAR(50),               -- Group for parallel execution
    LoadOrder INT DEFAULT 100,           -- Order within group
    IsActive BIT DEFAULT 1,
    
    -- Options
    PreLoadSQL NVARCHAR(MAX),            -- Pre-load commands
    PostLoadSQL NVARCHAR(MAX),           -- Post-load commands
    TruncateTarget BIT DEFAULT 0,
    
    -- Audit
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME,
    
    CONSTRAINT UK_TableConfig UNIQUE (SourceSchema, SourceTable, TargetSchema, TargetTable)
);

-- Column mapping (if source/target differ)
CREATE TABLE ETL.ColumnMapping (
    ColumnMappingID INT IDENTITY(1,1) PRIMARY KEY,
    TableConfigID INT FOREIGN KEY REFERENCES ETL.TableConfig(TableConfigID),
    SourceColumn VARCHAR(128) NOT NULL,
    TargetColumn VARCHAR(128) NOT NULL,
    DataType VARCHAR(50),
    TransformExpression NVARCHAR(MAX),   -- Optional transformation
    IsActive BIT DEFAULT 1
);

-- Load control / watermarks
CREATE TABLE ETL.LoadControl (
    TableConfigID INT PRIMARY KEY FOREIGN KEY REFERENCES ETL.TableConfig(TableConfigID),
    LastLoadDate DATETIME,
    LastWatermark SQL_VARIANT,           -- Flexible type for different watermarks
    LastRowCount INT,
    LastStatus VARCHAR(20),
    LastErrorMessage NVARCHAR(MAX)
);

-- Execution log
CREATE TABLE ETL.ExecutionLog (
    ExecutionLogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TableConfigID INT,
    BatchID UNIQUEIDENTIFIER,
    StartTime DATETIME,
    EndTime DATETIME,
    RowsRead INT,
    RowsInserted INT,
    RowsUpdated INT,
    RowsDeleted INT,
    Status VARCHAR(20),
    ErrorMessage NVARCHAR(MAX)
);
```

### Sample Configuration Data

```sql
-- Insert table configurations
INSERT INTO ETL.TableConfig (
    SourceSchema, SourceTable, SourceDatabase, SourceConnectionName,
    TargetSchema, TargetTable, TargetDatabase,
    LoadType, IncrementalColumn, PrimaryKeyColumns,
    LoadGroup, LoadOrder, IsActive
) VALUES
('dbo', 'Customers', 'OLTP', 'SourceOLTP',
 'dbo', 'DimCustomer', 'DataWarehouse',
 'Full', NULL, 'CustomerID',
 'Dimensions', 10, 1),

('dbo', 'Orders', 'OLTP', 'SourceOLTP',
 'dbo', 'FactOrders', 'DataWarehouse',
 'Incremental', 'ModifiedDate', 'OrderID',
 'Facts', 20, 1),

('dbo', 'Products', 'OLTP', 'SourceOLTP',
 'dbo', 'DimProduct', 'DataWarehouse',
 'Incremental', 'LastUpdated', 'ProductID',
 'Dimensions', 10, 1);

-- Initialize load control
INSERT INTO ETL.LoadControl (TableConfigID, LastWatermark)
SELECT TableConfigID, CAST('1900-01-01' AS DATETIME)
FROM ETL.TableConfig
WHERE LoadType = 'Incremental';
```

---

## 🔧 Dynamic SQL Generation

### Build Queries from Metadata

```sql
-- Generate SELECT query from config
CREATE FUNCTION ETL.fn_BuildSelectQuery (
    @TableConfigID INT,
    @Incremental BIT = 0
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @SourceSchema VARCHAR(128);
    DECLARE @SourceTable VARCHAR(128);
    DECLARE @IncrementalColumn VARCHAR(128);
    
    SELECT 
        @SourceSchema = SourceSchema,
        @SourceTable = SourceTable,
        @IncrementalColumn = IncrementalColumn
    FROM ETL.TableConfig
    WHERE TableConfigID = @TableConfigID;
    
    -- Check for column mapping
    IF EXISTS (SELECT 1 FROM ETL.ColumnMapping WHERE TableConfigID = @TableConfigID)
    BEGIN
        SELECT @SQL = 'SELECT ' + 
            STRING_AGG(
                CASE 
                    WHEN TransformExpression IS NOT NULL 
                    THEN TransformExpression + ' AS ' + QUOTENAME(TargetColumn)
                    ELSE QUOTENAME(SourceColumn) + ' AS ' + QUOTENAME(TargetColumn)
                END, 
                ', '
            ) + ' FROM ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable)
        FROM ETL.ColumnMapping
        WHERE TableConfigID = @TableConfigID AND IsActive = 1;
    END
    ELSE
    BEGIN
        SET @SQL = 'SELECT * FROM ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable);
    END
    
    -- Add incremental filter
    IF @Incremental = 1 AND @IncrementalColumn IS NOT NULL
    BEGIN
        SET @SQL = @SQL + ' WHERE ' + QUOTENAME(@IncrementalColumn) + ' > @LastWatermark';
    END
    
    RETURN @SQL;
END;
```

### Generic Load Procedure

```sql
CREATE PROCEDURE ETL.usp_LoadTable
    @TableConfigID INT,
    @BatchID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SourceSchema VARCHAR(128);
    DECLARE @SourceTable VARCHAR(128);
    DECLARE @TargetSchema VARCHAR(128);
    DECLARE @TargetTable VARCHAR(128);
    DECLARE @LoadType VARCHAR(20);
    DECLARE @IncrementalColumn VARCHAR(128);
    DECLARE @PrimaryKeyColumns VARCHAR(500);
    DECLARE @TruncateTarget BIT;
    DECLARE @PreLoadSQL NVARCHAR(MAX);
    DECLARE @PostLoadSQL NVARCHAR(MAX);
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @MergeSQL NVARCHAR(MAX);
    DECLARE @LastWatermark DATETIME;
    DECLARE @NewWatermark DATETIME;
    DECLARE @RowsAffected INT;
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @LogID BIGINT;
    
    IF @BatchID IS NULL SET @BatchID = NEWID();
    
    BEGIN TRY
        -- Get configuration
        SELECT 
            @SourceSchema = SourceSchema,
            @SourceTable = SourceTable,
            @TargetSchema = TargetSchema,
            @TargetTable = TargetTable,
            @LoadType = LoadType,
            @IncrementalColumn = IncrementalColumn,
            @PrimaryKeyColumns = PrimaryKeyColumns,
            @TruncateTarget = TruncateTarget,
            @PreLoadSQL = PreLoadSQL,
            @PostLoadSQL = PostLoadSQL
        FROM ETL.TableConfig
        WHERE TableConfigID = @TableConfigID;
        
        -- Log start
        INSERT INTO ETL.ExecutionLog (TableConfigID, BatchID, StartTime, Status)
        VALUES (@TableConfigID, @BatchID, @StartTime, 'Running');
        SET @LogID = SCOPE_IDENTITY();
        
        -- Execute pre-load SQL
        IF @PreLoadSQL IS NOT NULL
            EXEC sp_executesql @PreLoadSQL;
        
        -- Get watermark for incremental loads
        IF @LoadType = 'Incremental'
        BEGIN
            SELECT @LastWatermark = CAST(LastWatermark AS DATETIME)
            FROM ETL.LoadControl
            WHERE TableConfigID = @TableConfigID;
        END
        
        -- Handle full load with truncate
        IF @LoadType = 'Full' AND @TruncateTarget = 1
        BEGIN
            SET @SQL = 'TRUNCATE TABLE ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable);
            EXEC sp_executesql @SQL;
        END
        
        -- Build and execute load query
        IF @LoadType = 'Full' OR @TruncateTarget = 1
        BEGIN
            -- Simple INSERT for full loads
            SET @SQL = 'INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' ' +
                       ETL.fn_BuildSelectQuery(@TableConfigID, 0);
            EXEC sp_executesql @SQL;
            SET @RowsAffected = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            -- MERGE for incremental loads
            -- (Dynamic MERGE generation - simplified example)
            SET @MergeSQL = ETL.fn_BuildMergeQuery(@TableConfigID, @LastWatermark);
            EXEC sp_executesql @MergeSQL, 
                              N'@LastWatermark DATETIME', 
                              @LastWatermark;
            SET @RowsAffected = @@ROWCOUNT;
        END
        
        -- Update watermark
        IF @LoadType = 'Incremental'
        BEGIN
            SET @SQL = 'SELECT @NewWM = MAX(' + QUOTENAME(@IncrementalColumn) + ') ' +
                       'FROM ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable);
            EXEC sp_executesql @SQL, N'@NewWM DATETIME OUTPUT', @NewWatermark OUTPUT;
            
            UPDATE ETL.LoadControl
            SET LastWatermark = ISNULL(@NewWatermark, LastWatermark),
                LastLoadDate = GETDATE(),
                LastRowCount = @RowsAffected,
                LastStatus = 'Success'
            WHERE TableConfigID = @TableConfigID;
        END
        
        -- Execute post-load SQL
        IF @PostLoadSQL IS NOT NULL
            EXEC sp_executesql @PostLoadSQL;
        
        -- Log success
        UPDATE ETL.ExecutionLog
        SET EndTime = GETDATE(),
            RowsInserted = @RowsAffected,
            Status = 'Success'
        WHERE ExecutionLogID = @LogID;
        
    END TRY
    BEGIN CATCH
        -- Log failure
        UPDATE ETL.ExecutionLog
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionLogID = @LogID;
        
        UPDATE ETL.LoadControl
        SET LastStatus = 'Failed',
            LastErrorMessage = ERROR_MESSAGE()
        WHERE TableConfigID = @TableConfigID;
        
        THROW;
    END CATCH
END;
```

---

## 🔄 SSIS Dynamic Package Pattern

### ForEach Loop with Metadata

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSIS METADATA-DRIVEN PATTERN                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ Execute SQL Task                                                 │   │
│   │ "Get Active Tables"                                             │   │
│   │ SELECT TableConfigID, SourceTable, TargetTable, LoadType        │   │
│   │ FROM ETL.TableConfig WHERE IsActive = 1                         │   │
│   │ ResultSet → Object Variable: @TableList                         │   │
│   └──────────────────────────────┬──────────────────────────────────┘   │
│                                  │                                       │
│   ┌──────────────────────────────▼──────────────────────────────────┐   │
│   │ For Each Loop Container (ADO Enumerator)                        │   │
│   │ Enumerate: @TableList                                           │   │
│   │ Variable Mappings:                                              │   │
│   │   Index 0 → @TableConfigID                                      │   │
│   │   Index 1 → @SourceTable                                        │   │
│   │   Index 2 → @TargetTable                                        │   │
│   │   Index 3 → @LoadType                                           │   │
│   │ ┌─────────────────────────────────────────────────────────────┐ │   │
│   │ │ Execute SQL Task                                            │ │   │
│   │ │ EXEC ETL.usp_LoadTable @TableConfigID = ?                   │ │   │
│   │ │ Parameter: @TableConfigID                                   │ │   │
│   │ └─────────────────────────────────────────────────────────────┘ │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Dynamic Data Flow (Advanced)

```
Using Script Component or BiML for dynamic sources:

1. Parent Package:
   - Loops through configuration
   - Sets variables for current table
   - Calls child package

2. Child Package (Generic):
   - Uses expressions for source/target
   - Source query from variable
   - Destination table from variable

Expression Examples:
Source Query: @[User::SourceQuery]
Destination: @[User::TargetSchema] + "." + @[User::TargetTable]
```

---

## 📋 Load Group Orchestration

### Parallel and Sequential Processing

```sql
-- Load groups configuration
CREATE TABLE ETL.LoadGroup (
    LoadGroupID INT IDENTITY(1,1) PRIMARY KEY,
    GroupName VARCHAR(50) NOT NULL,
    ExecutionOrder INT NOT NULL,
    MaxParallelTasks INT DEFAULT 4,
    IsActive BIT DEFAULT 1
);

INSERT INTO ETL.LoadGroup VALUES
('Staging', 1, 8, 1),       -- Run first, 8 parallel
('Dimensions', 2, 4, 1),    -- Run second, 4 parallel
('Facts', 3, 2, 1),         -- Run third, 2 parallel
('Aggregates', 4, 1, 1);    -- Run last, sequential

-- Master orchestration procedure
CREATE PROCEDURE ETL.usp_RunDailyETL
    @BatchID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    IF @BatchID IS NULL SET @BatchID = NEWID();
    
    DECLARE @GroupName VARCHAR(50);
    DECLARE @MaxParallel INT;
    
    -- Process each group in order
    DECLARE group_cursor CURSOR FOR
        SELECT GroupName, MaxParallelTasks
        FROM ETL.LoadGroup
        WHERE IsActive = 1
        ORDER BY ExecutionOrder;
    
    OPEN group_cursor;
    FETCH NEXT FROM group_cursor INTO @GroupName, @MaxParallel;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Load all tables in group (could parallelize here)
        EXEC ETL.usp_LoadGroup @GroupName, @BatchID, @MaxParallel;
        
        FETCH NEXT FROM group_cursor INTO @GroupName, @MaxParallel;
    END
    
    CLOSE group_cursor;
    DEALLOCATE group_cursor;
END;
```

---

## 📊 Monitoring Dashboard

```sql
-- Current batch status
CREATE VIEW ETL.vw_CurrentBatchStatus AS
SELECT 
    tc.SourceTable,
    tc.TargetTable,
    tc.LoadType,
    tc.LoadGroup,
    lc.LastLoadDate,
    lc.LastStatus,
    lc.LastRowCount,
    el.Status AS CurrentStatus,
    el.StartTime,
    DATEDIFF(SECOND, el.StartTime, GETDATE()) AS RunningSeconds
FROM ETL.TableConfig tc
LEFT JOIN ETL.LoadControl lc ON tc.TableConfigID = lc.TableConfigID
LEFT JOIN (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY TableConfigID ORDER BY StartTime DESC) AS rn
    FROM ETL.ExecutionLog
    WHERE Status = 'Running'
) el ON tc.TableConfigID = el.TableConfigID AND el.rn = 1
WHERE tc.IsActive = 1;

-- Daily summary
CREATE VIEW ETL.vw_DailySummary AS
SELECT 
    CAST(StartTime AS DATE) AS LoadDate,
    COUNT(*) AS TotalTables,
    SUM(CASE WHEN Status = 'Success' THEN 1 ELSE 0 END) AS Succeeded,
    SUM(CASE WHEN Status = 'Failed' THEN 1 ELSE 0 END) AS Failed,
    SUM(RowsInserted) AS TotalRows,
    AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSeconds,
    MAX(DATEDIFF(SECOND, StartTime, EndTime)) AS MaxDurationSeconds
FROM ETL.ExecutionLog
WHERE StartTime >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(StartTime AS DATE)
ORDER BY LoadDate DESC;

-- Failed tables detail
SELECT 
    tc.SourceTable,
    tc.TargetTable,
    el.StartTime,
    el.ErrorMessage
FROM ETL.ExecutionLog el
JOIN ETL.TableConfig tc ON el.TableConfigID = tc.TableConfigID
WHERE el.Status = 'Failed'
  AND el.StartTime >= DATEADD(DAY, -1, GETDATE())
ORDER BY el.StartTime DESC;
```

---

## 🎓 Interview Questions

### Q1: What is metadata-driven ETL?
**A:** An ETL approach where configuration (tables, mappings, rules) is stored in database tables rather than hardcoded in packages. A generic process reads config and dynamically builds/executes loads.

### Q2: What are the benefits of metadata-driven ETL?
**A:**
- Add new tables without code changes
- Single package to maintain
- Consistent patterns across all loads
- Self-documenting (config = documentation)
- Easy testing and deployment

### Q3: What information is typically stored in configuration tables?
**A:**
- Source/target table names and connections
- Load type (Full/Incremental/CDC)
- Primary key and incremental columns
- Load order and grouping
- Pre/post-load SQL commands
- Column mappings and transformations

### Q4: How do you handle incremental loads with metadata?
**A:** Store watermark column name in config, actual watermark value in control table. Generic procedure reads both, builds query with filter, executes, updates watermark.

### Q5: How do you orchestrate load groups?
**A:** Define load groups with execution order (Staging→Dimensions→Facts). Process groups sequentially, with parallel execution within groups based on MaxParallelTasks setting.

### Q6: How do you implement dynamic SSIS packages?
**A:**
- ForEach Loop over configuration result set
- Variables for source/target populated from loop
- Expressions to build connection strings and queries
- Child packages with parameterized sources

### Q7: How do you handle different load types in one framework?
**A:** Switch statement based on LoadType column:
- Full: Truncate + INSERT
- Incremental: MERGE with watermark filter
- CDC: Read from change tables

### Q8: How do you add a new table to the framework?
**A:** Simply INSERT a row into TableConfig with source, target, load type, etc. No package changes needed.

### Q9: How do you monitor metadata-driven ETL?
**A:**
- ExecutionLog table tracks every run
- Views for current status, daily summary
- Alerts on failures
- Row count trending

### Q10: What are the challenges of metadata-driven ETL?
**A:**
- Initial framework development effort
- Complex transformations may not fit generic pattern
- Debugging dynamic SQL can be harder
- Performance tuning across all tables
Solution: Allow custom SQL/stored procs for complex cases.

---

## 🔗 Related Topics
- [← Incremental Loading](./03_incremental_loading.md)
- [ETL Performance →](./05_performance_optimization.md)
- [SSIS Development →](../Module_06_ETL_SSIS/)

---

*Next: Learn about ETL Performance Optimization*
