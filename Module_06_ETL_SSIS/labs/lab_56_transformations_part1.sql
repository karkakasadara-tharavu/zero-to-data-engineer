/*
============================================================================
LAB 56: SSIS DATA FLOW TRANSFORMATIONS - PART 1
Module 06: ETL SSIS Fundamentals
============================================================================

OBJECTIVE:
- Master Conditional Split for row filtering
- Use Multicast for data branching
- Implement Lookup transformation for reference data
- Work with Merge and Merge Join transformations
- Understand Union All for combining datasets

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)

PREREQUISITES:
- Completed Labs 53-55
- Understanding of data flow fundamentals
- BookstoreDB and BookstoreETL databases

DATABASE: BookstoreDB, BookstoreETL
============================================================================
*/

USE BookstoreETL;
GO

-- ============================================================================
-- PART 1: CONDITIONAL SPLIT TRANSFORMATION
-- ============================================================================
/*
CONDITIONAL SPLIT routes rows to different outputs based on conditions:

KEY CONCEPTS:
- Like CASE statement or IF-ELSE logic
- Multiple output paths possible
- Conditions evaluated in order (first match wins)
- Default output for rows matching no condition
- Each row goes to exactly ONE output

USES:
- Separate good vs bad data
- Route by business rules (region, category, status)
- Split for different processing paths
- Implement business logic branching

CONFIGURATION:
1. Define conditions (expressions)
2. Specify output names
3. Set evaluation order
4. Configure default output
*/

-- Create target tables for conditional split examples
CREATE TABLE HighValueCustomers (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    TotalPurchases DECIMAL(12, 2),
    CustomerTier NVARCHAR(50),
    LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE StandardCustomers (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    TotalPurchases DECIMAL(12, 2),
    LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE InactiveCustomers (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    LastOrderDate DATE,
    LoadDate DATETIME DEFAULT GETDATE()
);

-- Create view with customer metrics for conditional split
CREATE OR ALTER VIEW vw_CustomerMetrics
AS
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS FullName,
    c.Email,
    c.IsActive,
    COUNT(o.OrderID) AS OrderCount,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalPurchases,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceLastOrder,
    CASE 
        WHEN ISNULL(SUM(o.TotalAmount), 0) >= 1000 THEN 'Platinum'
        WHEN ISNULL(SUM(o.TotalAmount), 0) >= 500 THEN 'Gold'
        WHEN ISNULL(SUM(o.TotalAmount), 0) >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS CustomerTier
FROM BookstoreDB.dbo.Customers c
LEFT JOIN BookstoreDB.dbo.Orders o ON c.CustomerID = o.CustomerID
GROUP BY 
    c.CustomerID, c.FirstName, c.LastName, c.Email, c.IsActive;
GO

SELECT * FROM vw_CustomerMetrics;

/*
CONDITIONAL SPLIT EXAMPLE: "Customer Segmentation"

CONDITIONS (in order):
1. Output Name: "HighValue"
   Condition: TotalPurchases >= 500 && IsActive == 1
   
2. Output Name: "Standard"  
   Condition: TotalPurchases > 0 && IsActive == 1
   
3. Output Name: "Inactive"
   Condition: IsActive == 0 || DaysSinceLastOrder > 180

4. Default Output: "Unknown"

DATA FLOW:
OLE DB Source (vw_CustomerMetrics)
    ↓
Conditional Split
    ├→ HighValue → OLE DB Destination (HighValueCustomers)
    ├→ Standard → OLE DB Destination (StandardCustomers)
    ├→ Inactive → OLE DB Destination (InactiveCustomers)
    └→ Default → Flat File Destination (UnknownCustomers.txt)

EXPRESSIONS IN SSIS:
- Comparison: ==, !=, <, >, <=, >=
- Logical: &&, ||, !
- Null Check: ISNULL(Column)
- String: Column == "Value"
- Numeric: TotalAmount >= 500
- Date: DATEDIFF("day", OrderDate, GETDATE()) > 30
*/

-- Verify conditional split logic in SQL
SELECT 
    CustomerTier,
    IsActive,
    DaysSinceLastOrder,
    CASE 
        WHEN TotalPurchases >= 500 AND IsActive = 1 THEN 'HighValue'
        WHEN TotalPurchases > 0 AND IsActive = 1 THEN 'Standard'
        WHEN IsActive = 0 OR DaysSinceLastOrder > 180 THEN 'Inactive'
        ELSE 'Unknown'
    END AS OutputPath,
    COUNT(*) AS CustomerCount
FROM vw_CustomerMetrics
GROUP BY 
    CustomerTier, IsActive, DaysSinceLastOrder,
    CASE 
        WHEN TotalPurchases >= 500 AND IsActive = 1 THEN 'HighValue'
        WHEN TotalPurchases > 0 AND IsActive = 1 THEN 'Standard'
        WHEN IsActive = 0 OR DaysSinceLastOrder > 180 THEN 'Inactive'
        ELSE 'Unknown'
    END;

-- ============================================================================
-- PART 2: MULTICAST TRANSFORMATION
-- ============================================================================
/*
MULTICAST creates copies of input data stream to multiple outputs:

KEY CONCEPTS:
- Exact duplicates of input data
- No filtering or transformation
- Multiple processing paths for same data
- Non-blocking transformation (highly efficient)

USES:
- Send data to multiple destinations
- Create different aggregations of same data
- Archive and process simultaneously
- Audit trail while loading

DIFFERENCE FROM CONDITIONAL SPLIT:
- Multicast: ALL rows to ALL outputs (copies)
- Conditional Split: Each row to ONE output (routing)
*/

-- Create tables for multicast demonstration
CREATE TABLE Customer_Production (
    CustomerID INT PRIMARY KEY,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Customer_Archive (
    ArchiveID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    ArchiveDate DATETIME DEFAULT GETDATE(),
    ArchiveReason NVARCHAR(50) DEFAULT 'Daily Backup'
);

CREATE TABLE Customer_Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    RecordHash VARBINARY(32),
    AuditDate DATETIME DEFAULT GETDATE()
);

/*
MULTICAST EXAMPLE: "Multi-Destination Load"

DATA FLOW:
OLE DB Source (Customers)
    ↓
Multicast (creates 3 copies)
    ├→ Output 1 → OLE DB Destination (Customer_Production)
    ├→ Output 2 → OLE DB Destination (Customer_Archive)
    └→ Output 3 → Derived Column → OLE DB Destination (Customer_Audit)
                  (Add RecordHash)

USE CASE:
- Load production table (main purpose)
- Create archive copy (backup)
- Generate audit trail with hash (compliance)

All three destinations receive identical data simultaneously.
*/

-- Generate hash for audit trail (demonstrates derived column after multicast)
SELECT 
    CustomerID,
    FirstName + ' ' + LastName AS FullName,
    Email,
    HASHBYTES('SHA2_256', 
        CAST(CustomerID AS NVARCHAR(20)) + 
        FirstName + LastName + 
        ISNULL(Email, '')
    ) AS RecordHash
FROM BookstoreDB.dbo.Customers;

-- ============================================================================
-- PART 3: LOOKUP TRANSFORMATION
-- ============================================================================
/*
LOOKUP performs reference data lookups (like JOIN):

LOOKUP MODES:
1. Full Cache:
   - Loads entire reference table into memory
   - Fastest for small reference tables (<100MB)
   - Refreshed only at package start

2. Partial Cache:
   - Loads subset of reference data
   - Caches lookup results during execution
   - Good for large reference tables with low hit rate

3. No Cache:
   - Query database for each lookup
   - Slowest but uses least memory
   - Real-time data access

MATCH OPTIONS:
- Exact Match: Column = Column (most common)
- Fuzzy Match: Approximate matching (separate transformation)

OUTPUTS:
- Match Output: Rows with successful lookup
- No Match Output: Rows without match (optional)
- Error Output: Errors during lookup

CONFIGURATION STEPS:
1. Specify reference table or query
2. Set cache mode
3. Configure connection columns (join conditions)
4. Select lookup columns to retrieve
5. Handle no-match rows
*/

-- Create reference/lookup tables
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName NVARCHAR(20),
    Day INT,
    DayOfWeek INT,
    DayName NVARCHAR(20),
    IsWeekend BIT,
    IsHoliday BIT
);

-- Populate date dimension (2024 only for demo)
;WITH DateRange AS (
    SELECT CAST('2024-01-01' AS DATE) AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateRange
    WHERE DateValue < '2024-12-31'
)
INSERT INTO DimDate (
    DateKey, FullDate, Year, Quarter, Month, MonthName,
    Day, DayOfWeek, DayName, IsWeekend, IsHoliday
)
SELECT 
    YEAR(DateValue) * 10000 + MONTH(DateValue) * 100 + DAY(DateValue) AS DateKey,
    DateValue AS FullDate,
    YEAR(DateValue) AS Year,
    DATEPART(QUARTER, DateValue) AS Quarter,
    MONTH(DateValue) AS Month,
    DATENAME(MONTH, DateValue) AS MonthName,
    DAY(DateValue) AS Day,
    DATEPART(WEEKDAY, DateValue) AS DayOfWeek,
    DATENAME(WEEKDAY, DateValue) AS DayName,
    CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    0 AS IsHoliday
FROM DateRange
OPTION (MAXRECURSION 366);

-- Mark holidays
UPDATE DimDate SET IsHoliday = 1
WHERE (Month = 1 AND Day = 1)     -- New Year
   OR (Month = 7 AND Day = 4)      -- Independence Day
   OR (Month = 12 AND Day = 25);   -- Christmas

SELECT TOP 10 * FROM DimDate ORDER BY DateKey;

-- Create category lookup table
CREATE TABLE DimCategory (
    CategoryKey INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT UNIQUE,
    CategoryName NVARCHAR(100),
    CategoryGroup NVARCHAR(50),
    IsActive BIT DEFAULT 1
);

INSERT INTO DimCategory (CategoryID, CategoryName, CategoryGroup, IsActive)
VALUES
    (1, 'Fiction', 'Books', 1),
    (2, 'Non-Fiction', 'Books', 1),
    (3, 'Science', 'Books', 1),
    (4, 'Technology', 'Books', 1),
    (5, 'History', 'Books', 1),
    (6, 'Biography', 'Books', 1),
    (7, 'Children', 'Books', 1),
    (8, 'Mystery', 'Books', 1);

/*
LOOKUP EXAMPLE: "Order Fact Loading with Dimension Lookups"

DATA FLOW:
OLE DB Source (Orders)
    ↓
Lookup 1: DimDate (OrderDate → DateKey)
    ├→ Match: Continue
    └→ No Match: Redirect to error log
    ↓
Lookup 2: DimCustomer (CustomerID → CustomerKey)
    ├→ Match: Continue
    └→ No Match: Redirect to error log
    ↓
Lookup 3: DimCategory (CategoryID → CategoryKey)
    ├→ Match: Continue
    └→ No Match: Insert default category
    ↓
OLE DB Destination (FactSales)

LOOKUP CONFIGURATION:
1. Connection: BookstoreETL
2. Table: DimDate
3. Columns Tab:
   - Available Input: OrderDate
   - Available Lookup: FullDate
   - Connection: OrderDate = FullDate
   - Lookup Columns: [✓] DateKey
4. Advanced Tab:
   - Cache Mode: Full Cache
   - No Match Output: Redirect rows to no match output
*/

-- SQL equivalent of lookup operation
SELECT 
    o.OrderID,
    o.OrderDate,
    d.DateKey,           -- From Lookup
    d.Year,              -- From Lookup
    d.Quarter,           -- From Lookup
    d.MonthName,         -- From Lookup
    d.IsWeekend,         -- From Lookup
    o.TotalAmount
FROM BookstoreDB.dbo.Orders o
LEFT JOIN DimDate d ON CAST(o.OrderDate AS DATE) = d.FullDate;

-- ============================================================================
-- PART 4: MERGE TRANSFORMATION
-- ============================================================================
/*
MERGE combines two sorted datasets into one sorted output:

REQUIREMENTS:
- Both inputs MUST be sorted on merge key
- Merge keys must match (same columns, same order)
- Similar to UNION ALL but maintains sort order
- Non-blocking transformation

USES:
- Combine data from multiple sources
- Merge partitioned datasets
- Incremental + full load combinations

CONFIGURATION:
1. Ensure both inputs are sorted (Sort transformation or sorted source)
2. Specify merge key columns
3. Both inputs must have IsSorted = True property
4. Select columns from both inputs for output

DIFFERENCE FROM UNION ALL:
- Merge: Requires sorted inputs, maintains sort
- Union All: No sort requirement, no sort guarantee
*/

-- Create tables for merge demonstration
CREATE TABLE Orders_Current (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10, 2)
);

CREATE TABLE Orders_Historical (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10, 2)
);

-- Split orders into current (last 30 days) and historical
INSERT INTO Orders_Current (OrderID, CustomerID, OrderDate, TotalAmount)
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM BookstoreDB.dbo.Orders
WHERE OrderDate >= DATEADD(DAY, -30, GETDATE());

INSERT INTO Orders_Historical (OrderID, CustomerID, OrderDate, TotalAmount)
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM BookstoreDB.dbo.Orders
WHERE OrderDate < DATEADD(DAY, -30, GETDATE());

SELECT 'Current' AS Source, COUNT(*) AS RowCount FROM Orders_Current
UNION ALL
SELECT 'Historical', COUNT(*) FROM Orders_Historical;

/*
MERGE EXAMPLE: "Combine Current and Historical Orders"

DATA FLOW:
OLE DB Source 1 (Orders_Current ORDER BY OrderID)
    → IsSorted = True, SortKeyPosition = 1 on OrderID
    ↓
    Merge
    ↓   
OLE DB Source 2 (Orders_Historical ORDER BY OrderID)
    → IsSorted = True, SortKeyPosition = 1 on OrderID
    ↓
OLE DB Destination (Orders_Combined)

CONFIGURATION:
1. Set IsSorted property on both sources:
   - Advanced Editor → Input and Output Properties
   - Set IsSorted = True
   - Set SortKeyPosition = 1 on OrderID column

2. Merge Transformation:
   - Left Input: Orders_Current (OrderID)
   - Right Input: Orders_Historical (OrderID)
   - Output includes all columns from both
*/

-- SQL equivalent
SELECT * FROM Orders_Current
UNION ALL
SELECT * FROM Orders_Historical
ORDER BY OrderID;

-- ============================================================================
-- PART 5: MERGE JOIN TRANSFORMATION
-- ============================================================================
/*
MERGE JOIN performs JOIN operations in data flow:

JOIN TYPES:
1. Inner Join: Matching rows from both inputs
2. Left Outer Join: All from left + matches from right
3. Full Outer Join: All rows from both inputs

REQUIREMENTS:
- Both inputs MUST be sorted on join keys
- IsSorted = True on both inputs
- Join keys must be compatible data types

PERFORMANCE:
- More efficient than Lookup for large datasets
- Processes data in streaming fashion
- Good for joining two large sorted datasets

USES:
- Join fact and dimension tables
- Combine related datasets
- Enrich data with additional attributes

CONFIGURATION:
1. Sort both inputs on join keys
2. Set IsSorted = True on both sources
3. Specify join type
4. Configure join keys
5. Select output columns
*/

-- Create tables for merge join example
CREATE TABLE CustomerOrders_Enriched (
    OrderID INT,
    OrderDate DATETIME,
    CustomerID INT,
    CustomerName NVARCHAR(101),
    CustomerEmail NVARCHAR(100),
    TotalAmount DECIMAL(10, 2),
    LoadDate DATETIME DEFAULT GETDATE()
);

/*
MERGE JOIN EXAMPLE: "Enrich Orders with Customer Data"

DATA FLOW:
OLE DB Source 1: Orders (ORDER BY CustomerID)
    → IsSorted = True on CustomerID
    ↓
    Merge Join (Inner Join on CustomerID)
    ↓
OLE DB Source 2: Customers (ORDER BY CustomerID)
    → IsSorted = True on CustomerID
    ↓
Derived Column: Add LoadDate
    ↓
OLE DB Destination: CustomerOrders_Enriched

MERGE JOIN CONFIGURATION:
1. Join Type: Inner Join
2. Left Input Key: CustomerID (from Orders)
3. Right Input Key: CustomerID (from Customers)
4. Output Columns:
   - From Left: OrderID, OrderDate, TotalAmount
   - From Right: CustomerName, CustomerEmail

PERFORMANCE TIP:
- Ensure both sources have indexed ORDER BY columns
- Use clustered indexes on join keys
- Consider SQL transformation for complex joins
*/

-- SQL equivalent (for comparison)
SELECT 
    o.OrderID,
    o.OrderDate,
    o.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.Email AS CustomerEmail,
    o.TotalAmount
FROM BookstoreDB.dbo.Orders o
INNER JOIN BookstoreDB.dbo.Customers c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderID;

-- Compare Merge Join vs Lookup performance query
-- (Use for large datasets to demonstrate Merge Join advantage)
/*
Lookup: Good for small reference table (< 100MB)
Merge Join: Good when both inputs are large and sorted
*/

-- ============================================================================
-- PART 6: UNION ALL TRANSFORMATION
-- ============================================================================
/*
UNION ALL combines multiple inputs into single output:

KEY CONCEPTS:
- Appends rows from all inputs
- No deduplication (unlike SQL UNION)
- Column mapping by position, not name
- Non-blocking transformation

USES:
- Combine data from multiple sources
- Merge similar datasets
- Consolidate partitioned data

CONFIGURATION:
1. Connect multiple inputs
2. Map columns by position
3. Resolve data type differences
4. Name output columns
*/

-- Create regional customer tables
CREATE TABLE Customers_Region_East (
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    Region NVARCHAR(50) DEFAULT 'East'
);

CREATE TABLE Customers_Region_West (
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    Region NVARCHAR(50) DEFAULT 'West'
);

CREATE TABLE Customers_Region_Central (
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    Region NVARCHAR(50) DEFAULT 'Central'
);

CREATE TABLE Customers_Consolidated (
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    Region NVARCHAR(50),
    LoadDate DATETIME DEFAULT GETDATE()
);

-- Populate regional tables (sample data)
INSERT INTO Customers_Region_East (CustomerID, FullName, Email)
SELECT CustomerID, FirstName + ' ' + LastName, Email
FROM BookstoreDB.dbo.Customers
WHERE CustomerID % 3 = 0;

INSERT INTO Customers_Region_West (CustomerID, FullName, Email)
SELECT CustomerID, FirstName + ' ' + LastName, Email
FROM BookstoreDB.dbo.Customers
WHERE CustomerID % 3 = 1;

INSERT INTO Customers_Region_Central (CustomerID, FullName, Email)
SELECT CustomerID, FirstName + ' ' + LastName, Email
FROM BookstoreDB.dbo.Customers
WHERE CustomerID % 3 = 2;

/*
UNION ALL EXAMPLE: "Regional Consolidation"

DATA FLOW:
OLE DB Source 1: Customers_Region_East
    ↓
OLE DB Source 2: Customers_Region_West
    ↓   Union All
OLE DB Source 3: Customers_Region_Central
    ↓
Derived Column: Add LoadDate
    ↓
OLE DB Destination: Customers_Consolidated

UNION ALL CONFIGURATION:
1. Add Union All transformation
2. Connect three sources as inputs
3. Column Mapping:
   - Output Column 1: CustomerID → Maps to CustomerID from all inputs
   - Output Column 2: FullName → Maps to FullName from all inputs
   - Output Column 3: Email → Maps to Email from all inputs
   - Output Column 4: Region → Maps to Region from all inputs
*/

-- SQL equivalent
SELECT CustomerID, FullName, Email, Region FROM Customers_Region_East
UNION ALL
SELECT CustomerID, FullName, Email, Region FROM Customers_Region_West
UNION ALL
SELECT CustomerID, FullName, Email, Region FROM Customers_Region_Central;

-- Verify consolidation
SELECT Region, COUNT(*) AS CustomerCount
FROM Customers_Consolidated
GROUP BY Region;

-- ============================================================================
-- PART 7: SORT TRANSFORMATION
-- ============================================================================
/*
SORT transformation sorts data in the pipeline:

KEY CONCEPTS:
- Fully blocking transformation (waits for all rows)
- Expensive operation (memory intensive)
- Enables Merge and Merge Join
- Can remove duplicates

CONFIGURATION:
- Select sort columns
- Set sort direction (Ascending/Descending)
- Set sort order (1, 2, 3 for multi-column sort)
- Option to remove duplicates

PERFORMANCE WARNING:
- Avoid if possible (sort at source with ORDER BY)
- Use only when source cannot be sorted
- Large datasets can cause memory pressure
- Consider SQL transformation alternative

WHEN REQUIRED:
- Before Merge transformation
- Before Merge Join
- When deduplication needed
- When downstream needs sorted data
*/

-- Example demonstrating need for Sort
CREATE TABLE UnsortedTransactions (
    TransactionID INT,
    TransactionDate DATETIME,
    Amount DECIMAL(10, 2),
    CustomerID INT
);

INSERT INTO UnsortedTransactions
SELECT 
    ROW_NUMBER() OVER (ORDER BY NEWID()) AS TransactionID,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()) AS TransactionDate,
    ABS(CHECKSUM(NEWID())) % 1000 AS Amount,
    (ABS(CHECKSUM(NEWID())) % 100) + 1 AS CustomerID
FROM sys.objects o1
CROSS JOIN sys.objects o2;

SELECT TOP 20 * FROM UnsortedTransactions;

/*
SORT EXAMPLE: "Prepare for Merge Join"

DATA FLOW:
OLE DB Source: UnsortedTransactions (no ORDER BY)
    ↓
Sort Transformation
    - Sort Column: CustomerID (Ascending, Position 1)
    - Sort Column: TransactionDate (Ascending, Position 2)
    - Remove Duplicates: False
    ↓
Merge Join or Merge transformation

ALTERNATIVE (Better Performance):
OLE DB Source with ORDER BY:
    SELECT * FROM UnsortedTransactions
    ORDER BY CustomerID, TransactionDate
    ↓
Set IsSorted = True in Advanced Editor
    ↓
Merge Join or Merge transformation

PERFORMANCE COMPARISON:
- Sort in SQL (source): ~1000 rows/sec
- Sort in SSIS: ~500 rows/sec
- Recommendation: Always sort at source when possible
*/

-- ============================================================================
-- PART 8: MULTICAST VS CONDITIONAL SPLIT
-- ============================================================================
/*
CHOOSING THE RIGHT TRANSFORMATION:

MULTICAST:
- Need same data in multiple destinations
- Creating backups/archives
- Different aggregations of same data
- Audit trails
- Example: Load to both Production and Archive

CONDITIONAL SPLIT:
- Route data based on business rules
- Separate good vs bad data
- Different processing for different segments
- Example: High-value customers vs standard customers

BOTH:
- Can use together in complex scenarios
- Multicast first, then Conditional Split on each copy
- Or Conditional Split first, then Multicast each output
*/

-- Create comprehensive example
CREATE TABLE Process_Type_A (
    ID INT,
    Value NVARCHAR(100),
    ProcessType NVARCHAR(10) DEFAULT 'Type A'
);

CREATE TABLE Process_Type_B (
    ID INT,
    Value NVARCHAR(100),
    ProcessType NVARCHAR(10) DEFAULT 'Type B'
);

CREATE TABLE Archive_All (
    ArchiveID INT IDENTITY(1,1) PRIMARY KEY,
    ID INT,
    Value NVARCHAR(100),
    ProcessType NVARCHAR(10),
    ArchiveDate DATETIME DEFAULT GETDATE()
);

/*
COMPLEX EXAMPLE: "Multicast + Conditional Split"

DATA FLOW:
OLE DB Source
    ↓
Multicast (creates 2 copies)
    ├→ Copy 1 → Conditional Split
    │           ├→ Type A → OLE DB Destination (Process_Type_A)
    │           └→ Type B → OLE DB Destination (Process_Type_B)
    │
    └→ Copy 2 → OLE DB Destination (Archive_All)

USE CASE:
- Process data differently based on type
- Archive ALL data regardless of type
*/

-- ============================================================================
-- PART 9: PERFORMANCE CONSIDERATIONS
-- ============================================================================
/*
TRANSFORMATION PERFORMANCE CHARACTERISTICS:

NON-BLOCKING (Fast):
- Conditional Split
- Derived Column
- Data Conversion
- Multicast
- Union All

SEMI-BLOCKING (Moderate):
- Merge Join (requires sorted inputs)
- Merge (requires sorted inputs)
- Lookup (with cache)

FULLY BLOCKING (Slow):
- Sort
- Aggregate
- Pivot
- Unpivot

OPTIMIZATION STRATEGIES:
1. Minimize blocking transformations
2. Sort at source, not in pipeline
3. Use Full Cache for small lookups
4. Use Merge Join for large sorted datasets
5. Push filtering upstream (Conditional Split early)
6. Consider SQL transformations for complex logic
*/

-- Performance tracking table
CREATE TABLE Transformation_Performance (
    PerfID INT IDENTITY(1,1) PRIMARY KEY,
    TransformationType NVARCHAR(50),
    InputRows INT,
    OutputRows INT,
    DurationSeconds INT,
    RowsPerSecond DECIMAL(10, 2),
    MemoryUsedMB DECIMAL(10, 2),
    TestDate DATETIME DEFAULT GETDATE()
);

-- ============================================================================
-- PART 10: ERROR HANDLING IN TRANSFORMATIONS
-- ============================================================================
/*
Each transformation has error output configuration:

LOOKUP ERROR HANDLING:
- No Match: Ignore, Fail, Redirect
- Error: Fail or Redirect

MERGE JOIN ERROR HANDLING:
- Can redirect unmatched rows from outer joins

CONDITIONAL SPLIT:
- Default output handles "no condition matched"
- Not really "errors" but edge cases

BEST PRACTICE:
- Always configure error outputs
- Log errors to persistent storage
- Include source row data in error logs
- Monitor error rates
- Alert on error threshold
*/

CREATE TABLE Lookup_Errors (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    SourceRow NVARCHAR(MAX),
    LookupKey NVARCHAR(255),
    ErrorDescription NVARCHAR(MAX),
    ErrorDate DATETIME DEFAULT GETDATE()
);

-- ============================================================================
-- EXERCISES
-- ============================================================================

-- EXERCISE 1: Conditional Split (20 minutes)
/*
Create data flow with customer segmentation:
1. Source: vw_CustomerMetrics
2. Conditional Split:
   - VIP: TotalPurchases >= 1000
   - Regular: TotalPurchases >= 100
   - New: OrderCount == 0
   - Default: All others
3. Four destinations for each segment
4. Verify row counts match
*/

-- EXERCISE 2: Lookup with Error Handling (25 minutes)
/*
Create fact table load with dimension lookups:
1. Source: Orders
2. Lookup: DimDate (get DateKey)
   - No Match: Redirect to error
3. Lookup: DimCustomer (get CustomerKey)
   - No Match: Redirect to error
4. Destination: FactSales
5. Error paths: Log to Lookup_Errors table
*/

-- EXERCISE 3: Union All Consolidation (20 minutes)
/*
Consolidate regional customer data:
1. Three OLE DB Sources (East, West, Central regions)
2. Union All transformation
3. Derived Column: Add LoadDate
4. Destination: Customers_Consolidated
5. Verify all regions represented
*/

-- EXERCISE 4: Merge Join (30 minutes)
/*
Create enriched order dataset:
1. Source 1: Orders (sorted by CustomerID)
2. Source 2: Customers (sorted by CustomerID)
3. Merge Join: Inner Join
4. Derived Column: Calculate order age in days
5. Destination: CustomerOrders_Enriched
*/

-- EXERCISE 5: Multicast for Multiple Outputs (25 minutes)
/*
Create multi-destination load:
1. Source: Customers
2. Multicast (3 outputs)
3. Output 1 → Production table
4. Output 2 → Archive table with timestamp
5. Output 3 → Audit table with hash
*/

-- ============================================================================
-- CHALLENGE PROBLEMS
-- ============================================================================

-- CHALLENGE 1: Complex Customer Segmentation (45 minutes)
/*
Implement sophisticated customer classification:
1. Source: vw_CustomerMetrics
2. Derived Column: Calculate additional metrics
   - Recency (days since last order)
   - Frequency (orders per month)
   - Monetary (average order value)
3. Conditional Split: RFM segmentation
   - Champions: R ≤ 30, F ≥ 10, M ≥ 100
   - Loyal: R ≤ 60, F ≥ 5
   - At Risk: R > 90, F ≥ 5
   - Lost: R > 180
   - New: F == 0
4. Multicast after split for:
   - Production tables (5 segment tables)
   - Master archive table (all segments)
5. Implement comprehensive error handling
*/

-- CHALLENGE 2: Multi-Source Data Warehouse Load (60 minutes)
/*
Build complete fact table ETL:
1. Union All: Combine Orders from 3 regional databases
2. Lookup 1: DimDate (get DateKey)
3. Lookup 2: DimCustomer (get CustomerKey)
4. Lookup 3: DimProduct (get ProductKey)
5. Conditional Split: Separate valid vs invalid
6. Valid path:
   - Derived Column: Calculate metrics
   - Multicast: Production + Archive
7. Invalid path:
   - Log errors with details
8. Track performance metrics
*/

-- CHALLENGE 3: Incremental Load with Merge Join (90 minutes)
/*
Implement SCD Type 1 update pattern:
1. Source 1: Staging table (new/changed data)
2. Source 2: Dimension table (existing data)
3. Merge Join: Full Outer Join on business key
4. Conditional Split:
   - New Records: In staging, not in dimension → INSERT
   - Changed Records: In both, but values differ → UPDATE  
   - Unchanged: In both, values match → Skip
   - Deleted: In dimension, not in staging → Soft delete
5. Use OLE DB Command for UPDATEs
6. Regular INSERT for new records
7. Comprehensive logging and error handling
*/

-- ============================================================================
-- BEST PRACTICES
-- ============================================================================
/*
1. CONDITIONAL SPLIT:
   - Order conditions by frequency (most common first)
   - Use simple expressions for performance
   - Always handle default output
   - Test all condition branches

2. LOOKUP:
   - Use Full Cache for small reference tables
   - Index lookup columns in reference table
   - Handle no-match scenarios explicitly
   - Consider Merge Join for large lookups

3. MERGE/MERGE JOIN:
   - Always sort at source with ORDER BY
   - Verify IsSorted property is set
   - Use indexes on sort columns
   - Consider blocking impact on large datasets

4. UNION ALL:
   - Ensure column compatibility
   - Map columns carefully by position
   - Test with data from all sources
   - Validate row counts

5. MULTICAST:
   - Use for exact copies only
   - Consider memory impact of multiple outputs
   - Don't use when conditional routing needed
   - Good for parallel processing

6. PERFORMANCE:
   - Avoid Sort transformation (sort at source)
   - Push filtering upstream
   - Use appropriate lookup cache mode
   - Monitor memory usage
   - Profile transformation performance
*/

-- ============================================================================
-- REFERENCE QUERIES
-- ============================================================================

-- Verify conditional split results
SELECT 
    'HighValue' AS Segment, COUNT(*) AS Count FROM HighValueCustomers
UNION ALL
SELECT 'Standard', COUNT(*) FROM StandardCustomers
UNION ALL
SELECT 'Inactive', COUNT(*) FROM InactiveCustomers;

-- Check lookup match rates
SELECT 
    CAST(CAST(COUNT(CASE WHEN DateKey IS NOT NULL THEN 1 END) AS FLOAT) / 
         NULLIF(COUNT(*), 0) * 100 AS DECIMAL(5, 2)) AS MatchPercentage
FROM (
    SELECT o.OrderID, d.DateKey
    FROM BookstoreDB.dbo.Orders o
    LEFT JOIN DimDate d ON CAST(o.OrderDate AS DATE) = d.FullDate
) AS LookupTest;

-- Analyze transformation performance
SELECT 
    TransformationType,
    AVG(RowsPerSecond) AS AvgThroughput,
    AVG(MemoryUsedMB) AS AvgMemoryMB,
    COUNT(*) AS TestRuns
FROM Transformation_Performance
GROUP BY TransformationType
ORDER BY AvgThroughput DESC;

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Mastered Conditional Split for business rule routing
□ Used Multicast for multi-destination loads
□ Implemented Lookup with Full Cache mode
□ Configured Merge and Merge Join with sorted inputs
□ Combined datasets with Union All
□ Understood performance implications of each transformation
□ Handled errors and no-match scenarios
□ Completed all exercises
□ Solved at least one challenge problem

NEXT LAB: Lab 57 - SSIS Data Flow Transformations - Part 2
============================================================================
*/
