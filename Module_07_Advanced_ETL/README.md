# Module 07: Advanced ETL Patterns

**Duration**: 2 weeks (40-60 hours) | **Difficulty**: ⭐⭐⭐⭐⭐ Expert

## 📖 Overview
Master advanced ETL techniques: Change Data Capture, Slowly Changing Dimensions, incremental loads, and performance optimization for production data warehouses.

---

## 📚 Module Structure

| Section | Topic | Labs | Time |
|---------|-------|------|------|
| 01 | Change Data Capture (CDC) | 3 | 7h |
| 02 | Slowly Changing Dimensions | 4 | 9h |
| 03 | Incremental Loads & Watermarks | 3 | 7h |
| 04 | MERGE for Upserts | 2 | 5h |
| 05 | Orchestration Patterns | 2 | 6h |
| 06 | ETL Performance Tuning | 2 | 5h |
| **Capstone** | Dimensional Warehouse Implementation | 1 | 12h |

**Total**: 17 labs, 2 quizzes, 51 hours

---

## 🎯 Key Patterns

### Change Data Capture (CDC)
**Purpose**: Track changes without triggers

```sql
-- Enable CDC on database
USE AdventureWorks2022;
EXEC sys.sp_cdc_enable_db;

-- Enable CDC on table
EXEC sys.sp_cdc_enable_table
    @source_schema = 'Sales',
    @source_name = 'Customer',
    @role_name = NULL;

-- Query changes
SELECT *
FROM cdc.fn_cdc_get_all_changes_Sales_Customer(
    sys.fn_cdc_get_min_lsn('Sales_Customer'),
    sys.fn_cdc_get_max_lsn(),
    'all'
)
WHERE __$operation IN (2, 4); -- 2=INSERT, 4=UPDATE
```

---

### Slowly Changing Dimensions (SCD)

**Type 1**: Overwrite (no history)
```sql
UPDATE DimCustomer
SET City = 'New York'
WHERE CustomerID = 123;
```

**Type 2**: Add new row (full history)
```sql
-- Close old record
UPDATE DimCustomer
SET EndDate = GETDATE(),
    IsCurrent = 0
WHERE CustomerID = 123 AND IsCurrent = 1;

-- Insert new record
INSERT INTO DimCustomer (CustomerID, City, StartDate, EndDate, IsCurrent)
VALUES (123, 'New York', GETDATE(), '9999-12-31', 1);
```

**Type 3**: Add column (limited history)
```sql
ALTER TABLE DimCustomer ADD PreviousCity NVARCHAR(50);

UPDATE DimCustomer
SET PreviousCity = City,
    City = 'New York'
WHERE CustomerID = 123;
```

**SSIS SCD Transformation**: Built-in component for Type 1/2

---

### Incremental Loads (Watermark Pattern)

**High-Water Mark** (LastModifiedDate):
```sql
-- Store watermark
CREATE TABLE ETL.Watermark (
    TableName NVARCHAR(100) PRIMARY KEY,
    LastLoadDate DATETIME2
);

-- Get watermark
DECLARE @LastLoad DATETIME2;
SELECT @LastLoad = LastLoadDate FROM ETL.Watermark WHERE TableName = 'Customer';

-- Extract changes
SELECT *
FROM Sales.Customer
WHERE ModifiedDate > @LastLoad;

-- Update watermark
UPDATE ETL.Watermark
SET LastLoadDate = GETDATE()
WHERE TableName = 'Customer';
```

---

### MERGE Statement (Upsert)

```sql
MERGE INTO DimProduct AS Target
USING StagingProduct AS Source
ON Target.ProductID = Source.ProductID
WHEN MATCHED AND (Target.ProductName <> Source.ProductName OR Target.Price <> Source.Price) THEN
    UPDATE SET 
        ProductName = Source.ProductName,
        Price = Source.Price,
        ModifiedDate = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductID, ProductName, Price, CreatedDate)
    VALUES (Source.ProductID, Source.ProductName, Source.Price, GETDATE())
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;
```

---

### Orchestration Pattern (Master Package)

**Master Package**:
1. Execute "Load Dimensions" (parallel)
2. Execute "Load Facts" (sequential after dimensions)
3. Execute "Update Aggregates"
4. Send completion email

**Error Handling**:
- Event Handler → OnError → Log error and send alert
- Retry logic with loops
- Checkpoint files for restart

---

### Performance Tuning

**Buffer Tuning**:
- DefaultBufferMaxRows: 10000 (default)
- DefaultBufferSize: 10MB (default)
- Adjust based on row size and memory

**Batch Size**:
- OLE DB Destination: Rows per batch = 50000
- Fast Load options

**Parallelism**:
- MaxConcurrentExecutables = -1 (CPU count)
- Parallel data flows for independent sources

**Indexing**:
- Disable indexes during load
- Rebuild after bulk insert

---

## 📝 Labs

**Labs 69-71**: CDC setup and change tracking  
**Labs 72-75**: SCD Type 1, 2, 3 implementations  
**Labs 76-78**: Incremental load patterns with watermarks  
**Labs 79-80**: MERGE statements and upsert logic  
**Labs 81-82**: Master package orchestration  
**Labs 83-84**: Performance tuning exercises  
**Lab 85**: Capstone - Dimensional warehouse with SCD Type 2, CDC, incremental loads

---

## 🎓 Assessment
- Labs: 40%
- Quiz 11 (Week 1): 15%
- Quiz 12 (Week 2): 15%
- Capstone: 30%

---

**Next**: [Module 08: Power BI Reporting →](../Module_08_PowerBI/README.md)
