# Slowly Changing Dimensions (SCD) - Complete Guide

## 📚 What You'll Learn
- Understanding dimension changes
- SCD Type 0, 1, 2, 3, 4, 6 implementations
- SQL Server implementation patterns
- SSIS SCD Wizard
- Performance considerations
- Interview preparation

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 What are Slowly Changing Dimensions?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SLOWLY CHANGING DIMENSIONS                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Definition:                                                            │
│   Dimension attributes that change over time in a data warehouse.       │
│   How we handle these changes determines historical accuracy of         │
│   fact data.                                                             │
│                                                                          │
│   Example - Customer Dimension:                                          │
│   ┌───────────────────────────────────────────────────────────────────┐ │
│   │ CustomerID: 1001                                                  │ │
│   │ Name: John Smith                                                  │ │
│   │ Address: 123 Main St → 456 Oak Ave (moved!)                      │ │
│   │ Region: East → West (changed!)                                   │ │
│   │ CreditScore: 750 → 780 (improved!)                               │ │
│   │ JoinDate: 2020-01-15 (never changes)                             │ │
│   └───────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│   Question: When analyzing historical sales by region,                   │
│   should we use current region or region at time of sale?               │
│                                                                          │
│   SCD Types provide different answers to this question!                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 SCD Types Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCD TYPE COMPARISON                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Type │ Name          │ History │ Description                          │
│   ─────┼───────────────┼─────────┼─────────────────────────────────────│
│   0    │ Fixed         │ None    │ Never change (ignore updates)        │
│   1    │ Overwrite     │ None    │ Update in place (lose history)       │
│   2    │ Historical    │ Full    │ Add new row (preserve history)       │
│   3    │ Previous      │ Limited │ Add column for previous value        │
│   4    │ Mini-Dim      │ Full    │ Separate history table               │
│   6    │ Hybrid        │ Full    │ Combination of 1, 2, 3               │
│                                                                          │
│   Most Common in Practice:                                               │
│   ├── Type 1: Simple attributes (typo corrections, non-analytical)     │
│   ├── Type 2: Business-critical attributes (need history)              │
│   └── Type 6: When both current and historical views needed            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📌 SCD Type 0 - Fixed Attributes

Never change, even if source changes.

```sql
-- Example: Customer join date should never change
-- Simply ignore any updates to these columns

-- DimCustomer structure for Type 0 attributes
CREATE TABLE DimCustomer (
    CustomerSK INT IDENTITY PRIMARY KEY,  -- Surrogate Key
    CustomerID INT NOT NULL,              -- Natural Key
    CustomerName VARCHAR(100),
    JoinDate DATE,                        -- Type 0: Never changes!
    OriginalRegion VARCHAR(50),           -- Type 0: Original value preserved
    CurrentRegion VARCHAR(50)             -- Type 1: Overwrites
);

-- ETL Logic: Simply don't update Type 0 columns
UPDATE DimCustomer
SET CustomerName = source.CustomerName,   -- Type 1
    CurrentRegion = source.Region         -- Type 1
    -- JoinDate = source.JoinDate         -- Type 0: NOT updated!
WHERE CustomerID = source.CustomerID;
```

---

## 🔄 SCD Type 1 - Overwrite

Update in place, no history preserved.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCD TYPE 1 - OVERWRITE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   BEFORE:                                                                │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │ CustomerSK │ CustomerID │ Name        │ Address      │ Region │    │
│   ├────────────┼────────────┼─────────────┼──────────────┼────────┤    │
│   │ 1          │ 1001       │ John Smith  │ 123 Main St  │ East   │    │
│   └────────────┴────────────┴─────────────┴──────────────┴────────┘    │
│                                                                          │
│   Change: Customer moves to West region                                  │
│                                                                          │
│   AFTER:                                                                 │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │ CustomerSK │ CustomerID │ Name        │ Address      │ Region │    │
│   ├────────────┼────────────┼─────────────┼──────────────┼────────┤    │
│   │ 1          │ 1001       │ John Smith  │ 456 Oak Ave  │ West   │    │
│   └────────────┴────────────┴─────────────┴──────────────┴────────┘    │
│                                                                          │
│   ⚠️ Historical sales now show West region even for old sales!         │
│                                                                          │
│   Use When:                                                              │
│   ├── Corrections (typos, data quality issues)                          │
│   ├── Non-analytical attributes                                         │
│   └── History not important for analysis                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Type 1 Implementation

```sql
-- Simple UPDATE or MERGE for Type 1
MERGE DimCustomer AS target
USING StagingCustomer AS source
ON target.CustomerID = source.CustomerID

WHEN MATCHED THEN
    UPDATE SET
        CustomerName = source.CustomerName,
        Address = source.Address,
        Region = source.Region,
        LastModified = GETDATE()
        
WHEN NOT MATCHED THEN
    INSERT (CustomerID, CustomerName, Address, Region, LastModified)
    VALUES (source.CustomerID, source.CustomerName, source.Address, 
            source.Region, GETDATE());
```

---

## 📜 SCD Type 2 - Historical Rows

Add new row for each change, preserving complete history.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCD TYPE 2 - HISTORICAL                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   INITIAL:                                                               │
│   ┌────────────────────────────────────────────────────────────────────┐│
│   │ SK │ CustomerID │ Region │ StartDate  │ EndDate    │ IsCurrent    ││
│   ├────┼────────────┼────────┼────────────┼────────────┼──────────────┤│
│   │ 1  │ 1001       │ East   │ 2020-01-01 │ 9999-12-31 │ 1            ││
│   └────┴────────────┴────────┴────────────┴────────────┴──────────────┘│
│                                                                          │
│   Change on 2024-03-15: Customer moves to West                          │
│                                                                          │
│   AFTER CHANGE:                                                          │
│   ┌────────────────────────────────────────────────────────────────────┐│
│   │ SK │ CustomerID │ Region │ StartDate  │ EndDate    │ IsCurrent    ││
│   ├────┼────────────┼────────┼────────────┼────────────┼──────────────┤│
│   │ 1  │ 1001       │ East   │ 2020-01-01 │ 2024-03-14 │ 0            ││
│   │ 2  │ 1001       │ West   │ 2024-03-15 │ 9999-12-31 │ 1            ││
│   └────┴────────────┴────────┴────────────┴────────────┴──────────────┘│
│                                                                          │
│   ✓ Historical sales (2020-2024) correctly show East region            │
│   ✓ New sales correctly show West region                                │
│                                                                          │
│   Tracking Methods:                                                      │
│   ├── Date-based: StartDate, EndDate                                    │
│   ├── Flag-based: IsCurrent (1/0)                                       │
│   ├── Version: RowVersion number                                        │
│   └── Combination: All of the above (most common)                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Type 2 Table Structure

```sql
CREATE TABLE DimCustomer (
    -- Surrogate Key (for fact table joins)
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Natural/Business Key
    CustomerID INT NOT NULL,
    
    -- Attributes
    CustomerName VARCHAR(100),
    Address VARCHAR(200),
    City VARCHAR(100),
    Region VARCHAR(50),
    
    -- SCD Type 2 Tracking Columns
    EffectiveStartDate DATE NOT NULL,
    EffectiveEndDate DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent BIT NOT NULL DEFAULT 1,
    RowVersion INT NOT NULL DEFAULT 1,
    
    -- Audit Columns
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    
    -- Index for efficient lookups
    INDEX IX_CustomerID_Current (CustomerID, IsCurrent)
);
```

### Type 2 Implementation

```sql
-- Complete SCD Type 2 procedure
CREATE PROCEDURE usp_LoadDimCustomer_Type2
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LoadDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @EndDate DATE = DATEADD(DAY, -1, @LoadDate);
    
    -- 1. INSERT new customers (not in dimension)
    INSERT INTO DimCustomer (
        CustomerID, CustomerName, Address, City, Region,
        EffectiveStartDate, EffectiveEndDate, IsCurrent, RowVersion
    )
    SELECT 
        s.CustomerID,
        s.CustomerName,
        s.Address,
        s.City,
        s.Region,
        @LoadDate,      -- EffectiveStartDate
        '9999-12-31',   -- EffectiveEndDate
        1,              -- IsCurrent
        1               -- RowVersion
    FROM StagingCustomer s
    LEFT JOIN DimCustomer d 
        ON s.CustomerID = d.CustomerID 
        AND d.IsCurrent = 1
    WHERE d.CustomerSK IS NULL;
    
    -- 2. Identify changed records
    SELECT 
        d.CustomerSK,
        d.CustomerID,
        s.CustomerName,
        s.Address,
        s.City,
        s.Region,
        d.RowVersion + 1 AS NewRowVersion
    INTO #ChangedRecords
    FROM StagingCustomer s
    INNER JOIN DimCustomer d 
        ON s.CustomerID = d.CustomerID 
        AND d.IsCurrent = 1
    WHERE d.Region <> s.Region     -- Compare Type 2 attributes
       OR d.Address <> s.Address;  -- Add more comparisons as needed
    
    -- 3. Expire current records that have changes
    UPDATE d
    SET d.EffectiveEndDate = @EndDate,
        d.IsCurrent = 0,
        d.ModifiedDate = GETDATE()
    FROM DimCustomer d
    INNER JOIN #ChangedRecords c ON d.CustomerSK = c.CustomerSK;
    
    -- 4. INSERT new version of changed records
    INSERT INTO DimCustomer (
        CustomerID, CustomerName, Address, City, Region,
        EffectiveStartDate, EffectiveEndDate, IsCurrent, RowVersion
    )
    SELECT 
        CustomerID,
        CustomerName,
        Address,
        City,
        Region,
        @LoadDate,      -- EffectiveStartDate
        '9999-12-31',   -- EffectiveEndDate  
        1,              -- IsCurrent
        NewRowVersion   -- Incremented version
    FROM #ChangedRecords;
    
    DROP TABLE #ChangedRecords;
END;
```

### Querying Type 2 Dimensions

```sql
-- Get current customer record
SELECT * 
FROM DimCustomer 
WHERE CustomerID = 1001 
  AND IsCurrent = 1;

-- Get customer as of specific date (point-in-time)
SELECT * 
FROM DimCustomer 
WHERE CustomerID = 1001
  AND '2023-06-15' BETWEEN EffectiveStartDate AND EffectiveEndDate;

-- Fact table join (historical accuracy)
SELECT 
    f.OrderDate,
    f.SalesAmount,
    d.CustomerName,
    d.Region  -- Region at time of sale!
FROM FactSales f
INNER JOIN DimCustomer d ON f.CustomerSK = d.CustomerSK;

-- Alternative: Join on date range (if fact has natural key)
SELECT 
    f.OrderDate,
    f.SalesAmount,
    d.CustomerName,
    d.Region
FROM FactSales f
INNER JOIN DimCustomer d 
    ON f.CustomerID = d.CustomerID
    AND f.OrderDate BETWEEN d.EffectiveStartDate AND d.EffectiveEndDate;
```

---

## 📝 SCD Type 3 - Previous Value Column

Add column to store previous value.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCD TYPE 3 - PREVIOUS VALUE                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   BEFORE:                                                                │
│   ┌────────────────────────────────────────────────────────────────────┐│
│   │ CustomerSK │ CustomerID │ CurrentRegion │ PreviousRegion │ ChgDate ││
│   ├────────────┼────────────┼───────────────┼────────────────┼─────────┤│
│   │ 1          │ 1001       │ East          │ NULL           │ NULL    ││
│   └────────────┴────────────┴───────────────┴────────────────┴─────────┘│
│                                                                          │
│   Change: Customer moves to West                                         │
│                                                                          │
│   AFTER:                                                                 │
│   ┌────────────────────────────────────────────────────────────────────┐│
│   │ CustomerSK │ CustomerID │ CurrentRegion │ PreviousRegion │ ChgDate ││
│   ├────────────┼────────────┼───────────────┼────────────────┼─────────┤│
│   │ 1          │ 1001       │ West          │ East           │ 3/15/24 ││
│   └────────────┴────────────┴───────────────┴────────────────┴─────────┘│
│                                                                          │
│   Pros:                                                                  │
│   ├── Single row per customer (simple joins)                            │
│   ├── Easy to compare current vs previous                               │
│   └── No row explosion                                                  │
│                                                                          │
│   Cons:                                                                  │
│   ├── Only ONE previous value (limited history)                         │
│   ├── Multiple Type 3 columns can get messy                            │
│   └── No intermediate history                                           │
│                                                                          │
│   Use When:                                                              │
│   ├── Only need current + previous value                                │
│   ├── Limited history is acceptable                                     │
│   └── Simple before/after analysis needed                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Type 3 Implementation

```sql
CREATE TABLE DimCustomer_Type3 (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    CustomerName VARCHAR(100),
    
    -- Type 3: Current and Previous columns
    CurrentRegion VARCHAR(50),
    PreviousRegion VARCHAR(50),
    RegionChangeDate DATE,
    
    -- Can have multiple Type 3 attributes
    CurrentAddress VARCHAR(200),
    PreviousAddress VARCHAR(200),
    AddressChangeDate DATE
);

-- Type 3 Update
UPDATE DimCustomer_Type3
SET PreviousRegion = CurrentRegion,
    CurrentRegion = @NewRegion,
    RegionChangeDate = GETDATE()
WHERE CustomerID = @CustomerID
  AND CurrentRegion <> @NewRegion;
```

---

## 🔀 SCD Type 4 - Mini Dimension

Separate rapidly changing attributes into a mini dimension.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCD TYPE 4 - MINI DIMENSION                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Problem: Customer has attributes that change frequently               │
│   (Age Band, Income Band, Credit Score Range)                           │
│   Type 2 would create too many rows!                                    │
│                                                                          │
│   Solution: Extract rapidly changing attributes to mini dimension       │
│                                                                          │
│   ┌─────────────────────────┐      ┌─────────────────────────────────┐  │
│   │ DimCustomer (Stable)    │      │ DimCustomerProfile (Rapid)      │  │
│   ├─────────────────────────┤      ├─────────────────────────────────┤  │
│   │ CustomerSK (PK)         │      │ ProfileSK (PK)                  │  │
│   │ CustomerID              │      │ AgeBand                         │  │
│   │ Name                    │      │ IncomeBand                      │  │
│   │ JoinDate                │      │ CreditScoreRange                │  │
│   │ CurrentProfileSK (FK) ──┼──────│                                 │  │
│   └─────────────────────────┘      └─────────────────────────────────┘  │
│                                                                          │
│   FactSales:                                                             │
│   ├── CustomerSK  (to stable dimension)                                 │
│   └── ProfileSK   (to mini dimension - state at time of sale)          │
│                                                                          │
│   Benefits:                                                              │
│   ├── Mini dimension has all combinations (pre-built)                   │
│   ├── No row explosion in main dimension                                │
│   └── Fact stores exact profile at transaction time                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Type 4 Implementation

```sql
-- Mini dimension with all possible combinations
CREATE TABLE DimCustomerProfile (
    ProfileSK INT IDENTITY(1,1) PRIMARY KEY,
    AgeBand VARCHAR(20),        -- '18-25', '26-35', '36-45', etc.
    IncomeBand VARCHAR(20),     -- 'Low', 'Medium', 'High'
    CreditScoreRange VARCHAR(20) -- 'Poor', 'Fair', 'Good', 'Excellent'
);

-- Pre-populate all combinations
INSERT INTO DimCustomerProfile (AgeBand, IncomeBand, CreditScoreRange)
SELECT DISTINCT AgeBand, IncomeBand, CreditScoreRange
FROM (
    VALUES 
        ('18-25'), ('26-35'), ('36-45'), ('46-55'), ('56-65'), ('65+')
) AS A(AgeBand)
CROSS JOIN (
    VALUES ('Low'), ('Medium'), ('High')
) AS I(IncomeBand)
CROSS JOIN (
    VALUES ('Poor'), ('Fair'), ('Good'), ('Excellent')
) AS C(CreditScoreRange);

-- Main dimension references current profile
CREATE TABLE DimCustomer (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    CustomerName VARCHAR(100),
    JoinDate DATE,
    CurrentProfileSK INT FOREIGN KEY REFERENCES DimCustomerProfile(ProfileSK)
);

-- Fact table stores both keys
CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerSK INT,
    ProfileSK INT,  -- Profile at time of sale!
    DateKey INT,
    Amount DECIMAL(18,2)
);
```

---

## 🌟 SCD Type 6 - Hybrid (1 + 2 + 3)

Combines Type 1, 2, and 3 for maximum flexibility.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCD TYPE 6 - HYBRID                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Combines: Type 1 (Current), Type 2 (History), Type 3 (Previous)       │
│                                                                          │
│   CustomerID: 1001, moves East → Central → West                         │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │SK│ID  │Name │HistRegion│CurrRegion│StartDate │EndDate   │IsCurr│   │
│   ├──┼────┼─────┼──────────┼──────────┼──────────┼──────────┼──────┤   │
│   │1 │1001│John │East      │West      │2020-01-01│2022-06-30│0     │   │
│   │2 │1001│John │Central   │West      │2022-07-01│2024-03-14│0     │   │
│   │3 │1001│John │West      │West      │2024-03-15│9999-12-31│1     │   │
│   └──┴────┴─────┴──────────┴──────────┴──────────┴──────────┴──────┘   │
│                                                                          │
│   HistRegion = Region at that time (Type 2)                             │
│   CurrRegion = Current region (Type 1 - updated in ALL rows)           │
│                                                                          │
│   Benefits:                                                              │
│   ├── Easy current value access (CurrRegion in any row)                 │
│   ├── Full history preserved (HistRegion)                               │
│   ├── Flexible analysis (compare current vs historical)                │
│   └── Avoids complex joins for current value                           │
│                                                                          │
│   Use When:                                                              │
│   ├── Need both historical and current perspectives                    │
│   ├── Reports frequently compare "then vs now"                         │
│   └── Willing to accept update overhead for all rows                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Type 6 Implementation

```sql
CREATE TABLE DimCustomer_Type6 (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    CustomerName VARCHAR(100),
    
    -- Historical value (Type 2 - never changes after insert)
    HistoricalRegion VARCHAR(50),
    
    -- Current value (Type 1 - updated in ALL rows for customer)
    CurrentRegion VARCHAR(50),
    
    -- Previous value (Type 3 - in current row only)
    PreviousRegion VARCHAR(50),
    
    -- Type 2 tracking
    EffectiveStartDate DATE,
    EffectiveEndDate DATE DEFAULT '9999-12-31',
    IsCurrent BIT DEFAULT 1
);

-- Type 6 Update procedure
CREATE PROCEDURE usp_UpdateCustomer_Type6
    @CustomerID INT,
    @NewRegion VARCHAR(50)
AS
BEGIN
    DECLARE @LoadDate DATE = GETDATE();
    DECLARE @PreviousRegion VARCHAR(50);
    
    -- Get previous region
    SELECT @PreviousRegion = HistoricalRegion
    FROM DimCustomer_Type6
    WHERE CustomerID = @CustomerID AND IsCurrent = 1;
    
    IF @PreviousRegion <> @NewRegion
    BEGIN
        -- 1. Update CurrentRegion in ALL rows for this customer (Type 1)
        UPDATE DimCustomer_Type6
        SET CurrentRegion = @NewRegion
        WHERE CustomerID = @CustomerID;
        
        -- 2. Expire current row (Type 2)
        UPDATE DimCustomer_Type6
        SET EffectiveEndDate = DATEADD(DAY, -1, @LoadDate),
            IsCurrent = 0
        WHERE CustomerID = @CustomerID AND IsCurrent = 1;
        
        -- 3. Insert new current row (Type 2 + Type 3)
        INSERT INTO DimCustomer_Type6 (
            CustomerID, CustomerName,
            HistoricalRegion, CurrentRegion, PreviousRegion,
            EffectiveStartDate, IsCurrent
        )
        SELECT 
            CustomerID,
            CustomerName,
            @NewRegion,         -- Historical = new value (frozen)
            @NewRegion,         -- Current = new value
            @PreviousRegion,    -- Previous (Type 3)
            @LoadDate,
            1
        FROM DimCustomer_Type6
        WHERE CustomerID = @CustomerID 
          AND EffectiveEndDate = DATEADD(DAY, -1, @LoadDate);
    END
END;
```

---

## 🎓 Interview Questions

### Q1: What is a Slowly Changing Dimension?
**A:** A dimension attribute that changes over time in a data warehouse. SCD strategies determine how to handle these changes while preserving historical accuracy for fact data analysis.

### Q2: Explain SCD Type 1 vs Type 2.
**A:**
- **Type 1**: Overwrite - update in place, lose history. Use for corrections.
- **Type 2**: Historical - add new row, preserve history. Use for business-critical attributes.

### Q3: When would you use SCD Type 2?
**A:** When historical accuracy matters for analysis. Example: Customer region changes - historical sales should show region at time of sale, not current region.

### Q4: What columns are needed for SCD Type 2?
**A:**
- Surrogate Key (for fact joins)
- Natural Key (business identifier)
- EffectiveStartDate, EffectiveEndDate (date range)
- IsCurrent flag (optional but helpful)
- RowVersion (optional)

### Q5: What is SCD Type 6?
**A:** Hybrid combining Types 1+2+3. Has HistoricalValue (Type 2), CurrentValue (Type 1 updated in all rows), and PreviousValue (Type 3). Provides maximum flexibility.

### Q6: What is a Mini Dimension (Type 4)?
**A:** Separate rapidly changing attributes into small dimension. Prevents row explosion in main dimension. Fact table references both dimensions to capture state at transaction time.

### Q7: How do you handle multiple SCD types on same dimension?
**A:** Apply different types to different attributes:
- Type 0: JoinDate (never changes)
- Type 1: Name (corrections only)
- Type 2: Region (need history)
Each attribute handled according to its requirements.

### Q8: What is an Inferred Member in SCD?
**A:** A dimension record created when fact data arrives before dimension data (early arriving fact). Create placeholder row with natural key and defaults, update later when real data arrives.

### Q9: How do you query point-in-time from Type 2?
**A:** Filter where date BETWEEN EffectiveStartDate AND EffectiveEndDate:
```sql
WHERE '2023-06-15' BETWEEN EffectiveStartDate AND EffectiveEndDate
```

### Q10: What are the performance considerations for SCD Type 2?
**A:**
- Row growth (storage, query performance)
- Index on NaturalKey + IsCurrent
- Consider partitioning large dimensions
- Regular statistics updates
- May need to archive old versions

---

## 🔗 Related Topics
- [← Change Data Capture](./01_change_data_capture.md)
- [Incremental Loading →](./03_incremental_loading.md)
- [SSIS SCD Wizard →](../Module_06_ETL_SSIS/)

---

*Next: Learn about Incremental Loading Patterns*
