/*
============================================================================
LAB 57: SSIS DATA FLOW TRANSFORMATIONS - PART 2
Module 06: ETL SSIS Fundamentals
============================================================================

OBJECTIVE:
- Master Aggregate transformation for summarization
- Use Row Count for tracking and auditing
- Implement Pivot and Unpivot transformations
- Work with Script Component for custom logic
- Understand Slowly Changing Dimension (SCD) transformation

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)

PREREQUISITES:
- Completed Labs 53-56
- Understanding of aggregation concepts
- BookstoreDB and BookstoreETL databases

DATABASE: BookstoreDB, BookstoreETL
============================================================================
*/

USE BookstoreETL;
GO

-- ============================================================================
-- PART 1: AGGREGATE TRANSFORMATION
-- ============================================================================
/*
AGGREGATE TRANSFORMATION performs group-by operations:

OPERATIONS:
- Group By: Grouping columns
- Sum: Total of numeric columns
- Average: Average of numeric columns
- Count: Row count
- Count Distinct: Unique value count
- Minimum: Minimum value
- Maximum: Maximum value

CHARACTERISTICS:
- Fully blocking transformation (waits for all rows)
- Memory intensive for large datasets
- Can be slower than SQL aggregation
- Useful when aggregation needed mid-pipeline

WHEN TO USE:
- Aggregation after complex transformations
- Multiple aggregate outputs from same data
- When SQL aggregation not feasible

ALTERNATIVE:
- SQL aggregation at source (usually faster)
- Use Aggregate only when necessary
*/

-- Create summary tables for aggregate results
CREATE TABLE Sales_Summary_Daily (
    SummaryDate DATE PRIMARY KEY,
    TotalOrders INT,
    TotalRevenue DECIMAL(15, 2),
    AverageOrderValue DECIMAL(10, 2),
    MinOrderValue DECIMAL(10, 2),
    MaxOrderValue DECIMAL(10, 2),
    UniqueCustomers INT,
    LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Sales_Summary_Customer (
    CustomerID INT PRIMARY KEY,
    TotalOrders INT,
    TotalSpent DECIMAL(15, 2),
    AverageOrderValue DECIMAL(10, 2),
    FirstOrderDate DATE,
    LastOrderDate DATE,
    LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Sales_Summary_Category (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100),
    TotalOrders INT,
    TotalRevenue DECIMAL(15, 2),
    TotalQuantity INT,
    LoadDate DATETIME DEFAULT GETDATE()
);

-- SQL equivalent of what Aggregate transformation does
-- Daily summary
SELECT 
    CAST(OrderDate AS DATE) AS SummaryDate,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AverageOrderValue,
    MIN(TotalAmount) AS MinOrderValue,
    MAX(TotalAmount) AS MaxOrderValue,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM BookstoreDB.dbo.Orders
GROUP BY CAST(OrderDate AS DATE)
ORDER BY SummaryDate;

-- Customer summary
SELECT 
    CustomerID,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS TotalSpent,
    AVG(TotalAmount) AS AverageOrderValue,
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM BookstoreDB.dbo.Orders
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

/*
AGGREGATE TRANSFORMATION EXAMPLE: "Daily Sales Summary"

DATA FLOW:
OLE DB Source: Orders
    SELECT OrderID, OrderDate, TotalAmount, CustomerID
    FROM BookstoreDB.dbo.Orders
    ↓
Aggregate Transformation:
    Group By: OrderDate (cast to Date)
    Aggregations:
        - Count: OrderID → TotalOrders
        - Sum: TotalAmount → TotalRevenue
        - Average: TotalAmount → AverageOrderValue
        - Minimum: TotalAmount → MinOrderValue
        - Maximum: TotalAmount → MaxOrderValue
        - Count Distinct: CustomerID → UniqueCustomers
    ↓
Derived Column: Add LoadDate = GETDATE()
    ↓
OLE DB Destination: Sales_Summary_Daily

CONFIGURATION STEPS:
1. Add Aggregate transformation to Data Flow
2. Advanced Editor → Aggregations tab:
   - Add OrderDate as Group By
   - Add aggregation operations on other columns
3. Name output columns appropriately
4. Connect to destination
*/

-- Performance comparison: SQL vs SSIS Aggregate
-- SQL approach (recommended for simple aggregations)
CREATE OR ALTER VIEW vw_DailySalesSummary
AS
SELECT 
    CAST(OrderDate AS DATE) AS SummaryDate,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AverageOrderValue,
    MIN(TotalAmount) AS MinOrderValue,
    MAX(TotalAmount) AS MaxOrderValue,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM BookstoreDB.dbo.Orders
GROUP BY CAST(OrderDate AS DATE);
GO

-- Then in SSIS: Simple OLE DB Source → OLE DB Destination
-- This is faster than using Aggregate transformation!

-- ============================================================================
-- PART 2: ROW COUNT TRANSFORMATION
-- ============================================================================
/*
ROW COUNT tracks number of rows passing through pipeline:

PURPOSE:
- Audit row counts
- Validate data volumes
- Track processing statistics
- Control flow decisions based on row count

CONFIGURATION:
- Specify variable to store count
- Variable must be Int32 type
- Count accumulated as rows flow through

USES:
- Record counts in audit log
- Conditional processing based on volume
- Validation against expected counts
- Performance monitoring
*/

-- Create audit log for row counts
CREATE TABLE RowCount_Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    DataFlowName NVARCHAR(255),
    StepDescription NVARCHAR(255),
    RowCount INT,
    ExecutionTime DATETIME DEFAULT GETDATE()
);

-- Procedure to log row counts
CREATE OR ALTER PROCEDURE sp_LogRowCount
    @PackageName NVARCHAR(255),
    @DataFlowName NVARCHAR(255),
    @StepDescription NVARCHAR(255),
    @RowCount INT
AS
BEGIN
    INSERT INTO RowCount_Audit (
        PackageName, DataFlowName, StepDescription, RowCount
    )
    VALUES (
        @PackageName, @DataFlowName, @StepDescription, @RowCount
    );
END;
GO

/*
ROW COUNT EXAMPLE: "Multi-Point Counting"

DATA FLOW:
OLE DB Source: Customers
    ↓
Row Count 1 → Variable: SourceRowCount
    ↓
Conditional Split: Active vs Inactive
    ├→ Active Path
    │   ↓
    │   Row Count 2 → Variable: ActiveRowCount
    │   ↓
    │   OLE DB Destination: ActiveCustomers
    │
    └→ Inactive Path
        ↓
        Row Count 3 → Variable: InactiveRowCount
        ↓
        OLE DB Destination: InactiveCustomers

After Data Flow (in Control Flow):
Execute SQL Task: Log all row counts
    EXEC sp_LogRowCount 
        @PackageName = @[System::PackageName],
        @DataFlowName = 'DFT_CustomerLoad',
        @StepDescription = 'Source Records',
        @RowCount = @[User::SourceRowCount]
    
    EXEC sp_LogRowCount ...ActiveRowCount...
    EXEC sp_LogRowCount ...InactiveRowCount...

VALIDATION:
Use Expression in Precedence Constraint:
    @[User::SourceRowCount] == (@[User::ActiveRowCount] + @[User::InactiveRowCount])

If false, send error notification.
*/

-- Query to analyze row count trends
SELECT 
    DataFlowName,
    StepDescription,
    AVG(RowCount) AS AvgRowCount,
    MIN(RowCount) AS MinRowCount,
    MAX(RowCount) AS MaxRowCount,
    COUNT(*) AS ExecutionCount
FROM RowCount_Audit
WHERE ExecutionTime >= DATEADD(DAY, -7, GETDATE())
GROUP BY DataFlowName, StepDescription
ORDER BY DataFlowName, StepDescription;

-- ============================================================================
-- PART 3: PIVOT TRANSFORMATION
-- ============================================================================
/*
PIVOT converts rows to columns:

COMMON USE CASES:
- Create cross-tab reports
- Transform normalized data to wide format
- Generate matrix-style outputs
- Convert categorical data to columns

CONFIGURATION:
1. Pivot Key: Column containing values to become columns
2. Set Key: Column(s) to group by (becomes rows)
3. Pivot Value: Column containing values for cells

EXAMPLE:
Input (normalized):
CustomerID | Month    | Sales
-----------|----------|-------
101        | January  | 1000
101        | February | 1500
102        | January  | 2000

Output (pivoted):
CustomerID | January | February
-----------|---------|----------
101        | 1000    | 1500
102        | 2000    | NULL

LIMITATION:
- Must know column names at design time
- Dynamic pivots difficult in SSIS
- Consider SQL PIVOT for complex scenarios
*/

-- Create source data for pivot demonstration
CREATE TABLE Sales_Monthly_Normalized (
    CustomerID INT,
    MonthName NVARCHAR(20),
    SalesAmount DECIMAL(10, 2)
);

-- Insert sample data
INSERT INTO Sales_Monthly_Normalized (CustomerID, MonthName, SalesAmount)
VALUES
    (1, 'January', 1000.00), (1, 'February', 1500.00), (1, 'March', 1200.00),
    (2, 'January', 2000.00), (2, 'February', 2200.00), (2, 'March', 1800.00),
    (3, 'January', 1500.00), (3, 'February', 1600.00), (3, 'March', 1700.00),
    (4, 'January', 3000.00), (4, 'February', 3500.00), (4, 'March', 3200.00);

SELECT * FROM Sales_Monthly_Normalized ORDER BY CustomerID, MonthName;

-- Create destination for pivoted data
CREATE TABLE Sales_Monthly_Pivoted (
    CustomerID INT PRIMARY KEY,
    January DECIMAL(10, 2),
    February DECIMAL(10, 2),
    March DECIMAL(10, 2),
    April DECIMAL(10, 2),
    May DECIMAL(10, 2),
    June DECIMAL(10, 2),
    July DECIMAL(10, 2),
    August DECIMAL(10, 2),
    September DECIMAL(10, 2),
    October DECIMAL(10, 2),
    November DECIMAL(10, 2),
    December DECIMAL(10, 2)
);

-- SQL PIVOT equivalent (comparison)
SELECT CustomerID, [January], [February], [March]
FROM (
    SELECT CustomerID, MonthName, SalesAmount
    FROM Sales_Monthly_Normalized
) AS SourceData
PIVOT (
    SUM(SalesAmount)
    FOR MonthName IN ([January], [February], [March])
) AS PivotedData;

/*
PIVOT TRANSFORMATION EXAMPLE: "Monthly Sales Matrix"

DATA FLOW:
OLE DB Source: Sales_Monthly_Normalized
    SELECT CustomerID, MonthName, SalesAmount
    ↓
Pivot Transformation:
    Set Key: CustomerID (grouping column)
    Pivot Key: MonthName (becomes columns)
    Pivot Value: SalesAmount (cell values)
    ↓
    Output columns created: January, February, March, etc.
    ↓
OLE DB Destination: Sales_Monthly_Pivoted

CONFIGURATION:
1. Add Pivot transformation
2. Advanced Editor → Input Columns:
   - PivotUsage = 0 (Pass through): CustomerID
   - PivotUsage = 2 (Pivot Key): MonthName
   - PivotUsage = 3 (Pivot Value): SalesAmount
3. Pivot output values must be known at design time
4. Generate columns for each expected month
*/

-- ============================================================================
-- PART 4: UNPIVOT TRANSFORMATION
-- ============================================================================
/*
UNPIVOT converts columns to rows (reverse of PIVOT):

COMMON USE CASES:
- Normalize denormalized data
- Convert wide format to tall format
- Prepare data for database storage
- Simplify analysis of multiple similar columns

CONFIGURATION:
1. Pass Through columns: Remain unchanged (IDs, dates)
2. Unpivot columns: Columns to convert to rows
3. Destination Column: Column name for values
4. Pivot Key Value Column: Column name for source column names

EXAMPLE:
Input (wide):
CustomerID | Q1_Sales | Q2_Sales | Q3_Sales
-----------|----------|----------|----------
101        | 1000     | 1500     | 1200

Output (normalized):
CustomerID | Quarter  | Sales
-----------|----------|-------
101        | Q1_Sales | 1000
101        | Q2_Sales | 1500
101        | Q3_Sales | 1200
*/

-- Create source data for unpivot demonstration
CREATE TABLE Sales_Quarterly_Wide (
    CustomerID INT PRIMARY KEY,
    Q1_Sales DECIMAL(10, 2),
    Q2_Sales DECIMAL(10, 2),
    Q3_Sales DECIMAL(10, 2),
    Q4_Sales DECIMAL(10, 2),
    Year INT
);

INSERT INTO Sales_Quarterly_Wide (CustomerID, Q1_Sales, Q2_Sales, Q3_Sales, Q4_Sales, Year)
VALUES
    (1, 10000, 12000, 11000, 13000, 2024),
    (2, 15000, 16000, 14000, 17000, 2024),
    (3, 20000, 22000, 21000, 23000, 2024);

SELECT * FROM Sales_Quarterly_Wide;

-- Create destination for unpivoted data
CREATE TABLE Sales_Quarterly_Normalized (
    CustomerID INT,
    Quarter NVARCHAR(20),
    SalesAmount DECIMAL(10, 2),
    Year INT
);

-- SQL UNPIVOT equivalent
SELECT CustomerID, Quarter, SalesAmount, Year
FROM Sales_Quarterly_Wide
UNPIVOT (
    SalesAmount FOR Quarter IN (Q1_Sales, Q2_Sales, Q3_Sales, Q4_Sales)
) AS UnpivotedData;

/*
UNPIVOT TRANSFORMATION EXAMPLE: "Quarterly to Monthly Normalization"

DATA FLOW:
OLE DB Source: Sales_Quarterly_Wide
    ↓
Unpivot Transformation:
    Pass Through Columns: CustomerID, Year
    Unpivot Columns: Q1_Sales, Q2_Sales, Q3_Sales, Q4_Sales
    Destination Column: SalesAmount
    Pivot Key Value Column: Quarter
    ↓
OLE DB Destination: Sales_Quarterly_Normalized

OUTPUT:
Each input row becomes 4 output rows (one per quarter)
*/

-- ============================================================================
-- PART 5: SCRIPT COMPONENT (DATA FLOW)
-- ============================================================================
/*
SCRIPT COMPONENT provides custom .NET code in data flow:

COMPONENT TYPES:
1. Source: Generate data from code
2. Transformation: Custom row processing
3. Destination: Custom data writing

USES:
- Complex calculations not possible with Derived Column
- API calls per row
- Custom data formats
- Complex string parsing
- Business logic too complex for expressions

ADVANTAGES:
- Full .NET framework access
- Complex logic implementation
- External API integration
- File system operations

DISADVANTAGES:
- Performance overhead
- Code maintenance
- Debugging complexity
- Not as maintainable as built-in transformations
*/

-- Create table for script component results
CREATE TABLE Email_Validation_Results (
    CustomerID INT,
    Email NVARCHAR(100),
    IsValidFormat BIT,
    IsDisposableEmail BIT,
    ValidationDate DATETIME DEFAULT GETDATE()
);

/*
SCRIPT COMPONENT EXAMPLE: "Email Validation Transform"

C# CODE (Transformation):

public override void Input0_ProcessInputRow(Input0Buffer Row)
{
    string email = Row.Email;
    
    // Email format validation
    string pattern = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";
    Row.IsValidFormat = System.Text.RegularExpressions.Regex.IsMatch(email, pattern);
    
    // Check for disposable email domains
    string[] disposableDomains = { "tempmail.com", "throwaway.email", "guerrillamail.com" };
    string domain = email.Substring(email.IndexOf('@') + 1).ToLower();
    Row.IsDisposableEmail = disposableDomains.Contains(domain);
    
    // Add validation timestamp
    Row.ValidationDate = DateTime.Now;
}

DATA FLOW:
OLE DB Source: Customers
    SELECT CustomerID, Email FROM BookstoreDB.dbo.Customers
    ↓
Script Component (Transformation):
    Input Columns: CustomerID, Email
    Output Columns: IsValidFormat, IsDisposableEmail, ValidationDate
    ↓
Conditional Split:
    ├→ Valid: IsValidFormat == true && IsDisposableEmail == false
    └→ Invalid: Else
    ↓
OLE DB Destinations
*/

-- ============================================================================
-- PART 6: SLOWLY CHANGING DIMENSION (SCD) TRANSFORMATION
-- ============================================================================
/*
SCD TRANSFORMATION handles dimension changes over time:

SCD TYPES:
1. Type 0: No changes allowed (static)
2. Type 1: Overwrite (no history)
3. Type 2: Add new row (full history)
4. Type 3: Add new column (limited history)

SCD TRANSFORMATION SUPPORTS:
- Type 1: Fixed Attribute (overwrite changes)
- Type 2: Historical Attribute (track changes)
- Type 3: Changing Attribute (store old and new)

CONFIGURATION:
1. Business Key: Column(s) that uniquely identify dimension member
2. Change Type for each attribute:
   - Fixed Attribute (Type 1)
   - Historical Attribute (Type 2)
   - Changing Attribute (Type 3)
3. Outputs:
   - New: New dimension members (INSERT)
   - Unchanged: No changes detected
   - Fixed Attribute Updates: Type 1 changes (UPDATE)
   - Historical Attribute Inserts: Type 2 changes (INSERT new row)
   - Inferred Member Updates: Late-arriving dimensions
*/

-- Create dimension table for SCD demonstration
CREATE TABLE DimProduct_SCD (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,  -- Business Key
    ProductName NVARCHAR(200),
    Category NVARCHAR(100),
    UnitPrice DECIMAL(10, 2),
    IsActive BIT DEFAULT 1,
    StartDate DATETIME DEFAULT GETDATE(),
    EndDate DATETIME,
    IsCurrent BIT DEFAULT 1,
    CONSTRAINT UQ_DimProduct_Current UNIQUE (ProductID, IsCurrent)
);

-- Insert initial dimension data
INSERT INTO DimProduct_SCD (ProductID, ProductName, Category, UnitPrice, IsCurrent)
VALUES
    (1, 'SQL Server Guide', 'Technology', 49.99, 1),
    (2, 'Python Handbook', 'Programming', 39.99, 1),
    (3, 'Data Science Basics', 'Analytics', 59.99, 1);

SELECT * FROM DimProduct_SCD;

-- Create staging table with source data (includes changes)
CREATE TABLE Staging_Products (
    ProductID INT,
    ProductName NVARCHAR(200),
    Category NVARCHAR(100),
    UnitPrice DECIMAL(10, 2),
    LoadDate DATETIME DEFAULT GETDATE()
);

INSERT INTO Staging_Products (ProductID, ProductName, Category, UnitPrice)
VALUES
    (1, 'SQL Server Guide', 'Technology', 49.99),        -- Unchanged
    (2, 'Python Handbook', 'Programming', 44.99),        -- Price change (Type 1)
    (3, 'Data Science Basics', 'Data Analytics', 59.99), -- Category change (Type 2)
    (4, 'New Book Title', 'Fiction', 29.99);             -- New product (INSERT)

/*
SCD TRANSFORMATION EXAMPLE: "Product Dimension"

DATA FLOW:
OLE DB Source: Staging_Products
    ↓
SCD Transformation:
    Connection: BookstoreETL (DimProduct_SCD)
    Business Key: ProductID
    
    Column Configurations:
        ProductName → Historical Attribute (Type 2)
        Category → Historical Attribute (Type 2)
        UnitPrice → Fixed Attribute (Type 1)
    
    Outputs:
        New Records → Derived Column → OLE DB Destination (INSERT)
        Unchanged → Do nothing
        Fixed Attr Updates → OLE DB Command (UPDATE price)
        Historical Inserts → 
            ├→ OLE DB Command (UPDATE old row: IsCurrent=0, EndDate=NOW)
            └→ OLE DB Destination (INSERT new row)

MANUAL IMPLEMENTATION (without SCD transformation):
1. Lookup: Check if ProductID exists
2. Conditional Split:
   - New: No match in lookup
   - Existing: Match found
3. For Existing:
   - Derived Column: Compare old vs new values
   - Conditional Split:
     * Type 1 changes: UPDATE
     * Type 2 changes: INSERT new + UPDATE old
     * Unchanged: Skip
*/

-- Manual Type 2 SCD implementation (SQL example)
-- Step 1: Expire old record
UPDATE d
SET IsCurrent = 0,
    EndDate = GETDATE()
FROM DimProduct_SCD d
INNER JOIN Staging_Products s ON d.ProductID = s.ProductID
WHERE d.IsCurrent = 1
  AND (d.ProductName != s.ProductName OR d.Category != s.Category);

-- Step 2: Insert new record
INSERT INTO DimProduct_SCD (ProductID, ProductName, Category, UnitPrice, IsCurrent, StartDate)
SELECT 
    s.ProductID,
    s.ProductName,
    s.Category,
    s.UnitPrice,
    1,
    GETDATE()
FROM Staging_Products s
WHERE NOT EXISTS (
    SELECT 1 FROM DimProduct_SCD d
    WHERE d.ProductID = s.ProductID
      AND d.IsCurrent = 1
      AND d.ProductName = s.ProductName
      AND d.Category = s.Category
);

-- Verify SCD results
SELECT * FROM DimProduct_SCD ORDER BY ProductID, StartDate;

-- ============================================================================
-- PART 7: PERCENTAGE SAMPLING
-- ============================================================================
/*
PERCENTAGE SAMPLING selects random subset of rows:

USES:
- Data profiling with sample data
- Testing with representative subset
- Statistical analysis
- Performance testing with manageable data size

CONFIGURATION:
- Sampling Percentage: 1-100%
- Number of rows (alternative to percentage)
- Seed value for reproducible sampling

OUTPUTS:
- Selected Rows: Random sample
- Unselected Rows: Remaining rows
*/

-- Create table for sampling results
CREATE TABLE Customer_Sample (
    CustomerID INT PRIMARY KEY,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    SampleDate DATETIME DEFAULT GETDATE()
);

/*
PERCENTAGE SAMPLING EXAMPLE: "10% Customer Sample"

DATA FLOW:
OLE DB Source: Customers (10,000 rows)
    ↓
Percentage Sampling (10%, Seed = 12345)
    ├→ Selected (1,000 rows) → OLE DB Destination (Customer_Sample)
    └→ Unselected (9,000 rows) → Discard or process differently
*/

-- SQL equivalent (for comparison)
SELECT TOP 10 PERCENT *
FROM BookstoreDB.dbo.Customers
ORDER BY NEWID();

-- ============================================================================
-- PART 8: CHARACTER MAP TRANSFORMATION
-- ============================================================================
/*
CHARACTER MAP performs string operations:

OPERATIONS:
- Lowercase
- Uppercase
- Byte reversal
- Hiragana (Japanese)
- Katakana (Japanese)
- Linguistic casing
- Simplified Chinese
- Traditional Chinese

USES:
- Normalize text data
- Clean string values
- Standardize case
- Prepare for comparisons
*/

-- Create table for character map results
CREATE TABLE Customer_Normalized (
    CustomerID INT,
    OriginalName NVARCHAR(100),
    UppercaseName NVARCHAR(100),
    LowercaseName NVARCHAR(100),
    OriginalEmail NVARCHAR(100),
    LowercaseEmail NVARCHAR(100)
);

/*
CHARACTER MAP EXAMPLE: "Email Normalization"

DATA FLOW:
OLE DB Source: Customers
    ↓
Character Map:
    Email → LowercaseEmail (Lowercase operation)
    FirstName → UpperFirstName (Uppercase operation)
    ↓
OLE DB Destination

USAGE TIP:
- Often better to use Derived Column with UPPER() or LOWER()
- Character Map useful for linguistic casing
- Good for international character handling
*/

-- SQL equivalent
SELECT 
    CustomerID,
    FirstName + ' ' + LastName AS OriginalName,
    UPPER(FirstName + ' ' + LastName) AS UppercaseName,
    LOWER(FirstName + ' ' + LastName) AS LowercaseName,
    Email AS OriginalEmail,
    LOWER(Email) AS LowercaseEmail
FROM BookstoreDB.dbo.Customers;

-- ============================================================================
-- PART 9: COPY COLUMN TRANSFORMATION
-- ============================================================================
/*
COPY COLUMN creates exact copy of input column:

USES:
- Preserve original before transformation
- Create multiple versions of data
- Compare before/after transformations
- Audit trail

CONFIGURATION:
- Select columns to copy
- Specify output column names

NOTE: Simple transformation, rarely needed
      Often better to reference same column multiple times
*/

-- Example scenario: Preserve original before cleaning
CREATE TABLE Customer_Cleaned (
    CustomerID INT,
    OriginalEmail NVARCHAR(100),
    CleanedEmail NVARCHAR(100),
    OriginalPhone NVARCHAR(20),
    FormattedPhone NVARCHAR(20)
);

/*
COPY COLUMN EXAMPLE: "Data Cleaning Audit"

DATA FLOW:
OLE DB Source: Customers
    ↓
Copy Column:
    Email → OriginalEmail
    Phone → OriginalPhone
    ↓
Derived Column:
    Email = LOWER(TRIM(Email))
    Phone = Clean formatting
    ↓
OLE DB Destination (has both original and cleaned versions)
*/

-- ============================================================================
-- PART 10: EXPORT/IMPORT COLUMN TRANSFORMATION
-- ============================================================================
/*
EXPORT/IMPORT COLUMN handles file data in pipeline:

EXPORT COLUMN:
- Write BLOB data to files
- Extract images, documents from database
- File path specified per row

IMPORT COLUMN:
- Read file content into BLOB column
- Load images, documents to database
- File path specified per row

USES:
- Document management systems
- Image processing pipelines
- File archival workflows
*/

-- Create table for file metadata
CREATE TABLE Document_Metadata (
    DocumentID INT IDENTITY(1,1) PRIMARY KEY,
    DocumentName NVARCHAR(255),
    DocumentPath NVARCHAR(500),
    DocumentContent VARBINARY(MAX),
    FileSize BIGINT,
    LoadDate DATETIME DEFAULT GETDATE()
);

/*
EXPORT COLUMN EXAMPLE: "Extract Documents"

DATA FLOW:
OLE DB Source: Document table
    SELECT DocumentID, DocumentName, DocumentContent
    ↓
Export Column:
    Column: DocumentContent (DT_IMAGE)
    File Path Column: C:\Exports\ + DocumentName
    ↓
Writes files to disk

IMPORT COLUMN EXAMPLE: "Load Documents"

DATA FLOW:
Flat File Source: List of file paths
    ↓
Import Column:
    File Path Column: FilePath
    Destination Column: DocumentContent (DT_IMAGE)
    ↓
OLE DB Destination: Document_Metadata
*/

-- ============================================================================
-- EXERCISES
-- ============================================================================

-- EXERCISE 1: Aggregate Transformation (20 minutes)
/*
Create daily sales summary:
1. Source: Orders table
2. Aggregate: Group by OrderDate (as Date)
   - Count orders
   - Sum total amount
   - Average order value
   - Min/Max order values
3. Destination: Sales_Summary_Daily
4. Verify results match SQL aggregation
*/

-- EXERCISE 2: Row Count Tracking (25 minutes)
/*
Implement comprehensive row counting:
1. Source: Customers
2. Row Count 1: Total source rows
3. Conditional Split: Active vs Inactive
4. Row Count 2: Active customers
5. Row Count 3: Inactive customers
6. Validate: Source = Active + Inactive
7. Log all counts to RowCount_Audit
*/

-- EXERCISE 3: Pivot Transformation (30 minutes)
/*
Create monthly sales matrix:
1. Source: Sales_Monthly_Normalized
2. Pivot: MonthName to columns, SalesAmount as values
3. Destination: Sales_Monthly_Pivoted
4. Compare with SQL PIVOT results
*/

-- EXERCISE 4: Script Component (35 minutes)
/*
Build custom email validator:
1. Source: Customers
2. Script Component:
   - Validate email format with regex
   - Check domain against blacklist
   - Flag suspicious patterns
3. Conditional Split: Valid vs Invalid
4. Destinations: Separate tables
*/

-- EXERCISE 5: SCD Type 2 (40 minutes)
/*
Implement Type 2 slowly changing dimension:
1. Source: Staging_Products
2. Lookup: Check existing ProductID
3. Conditional Split: New vs Existing
4. For Existing, detect changes:
   - Type 1: Price changes (UPDATE)
   - Type 2: Name/Category changes (INSERT new + UPDATE old)
5. Handle all scenarios properly
*/

-- ============================================================================
-- CHALLENGE PROBLEMS
-- ============================================================================

-- CHALLENGE 1: Multi-Level Aggregation (45 minutes)
/*
Create hierarchical sales summary:
1. Source: Orders with OrderDetails
2. Aggregate Level 1: Daily summary
3. Multicast to create multiple aggregation paths:
   - Path A: Weekly summary
   - Path B: Monthly summary
   - Path C: Customer summary
4. Store all summaries in respective tables
5. Validate aggregation accuracy
*/

-- CHALLENGE 2: Complex SCD Implementation (60 minutes)
/*
Build complete SCD solution:
1. Customer dimension with Type 1, Type 2, and Type 3 attributes
2. Handle new customers (INSERT)
3. Type 1: Email, Phone (overwrite)
4. Type 2: Address (historical tracking)
5. Type 3: Status (current and previous)
6. Include audit columns (StartDate, EndDate, IsCurrent)
7. Comprehensive error handling and logging
*/

-- CHALLENGE 3: Custom Transformation Pipeline (90 minutes)
/*
Build advanced data quality pipeline:
1. Source: Raw customer data
2. Copy Column: Preserve originals
3. Character Map: Normalize case
4. Script Component: Advanced validation
   - Email format and domain validation
   - Phone format standardization
   - Address parsing
5. Aggregate: Data quality metrics
6. Percentage Sampling: QA sample (10%)
7. Multiple destinations:
   - Clean data → Production
   - Errors → Error log
   - Sample → QA review
   - Metrics → Dashboard
*/

-- ============================================================================
-- BEST PRACTICES
-- ============================================================================
/*
1. AGGREGATE:
   - Prefer SQL aggregation when possible
   - Use when mid-pipeline aggregation needed
   - Monitor memory usage for large datasets
   - Consider sorting input for better performance

2. ROW COUNT:
   - Track counts at multiple points
   - Validate counts balance correctly
   - Log for audit purposes
   - Use for conditional execution decisions

3. PIVOT/UNPIVOT:
   - Know limitations (static columns)
   - Consider SQL PIVOT for complex scenarios
   - Document expected column names
   - Test with various data patterns

4. SCRIPT COMPONENT:
   - Use only when necessary
   - Keep code simple and focused
   - Handle errors properly
   - Document code thoroughly
   - Consider performance impact

5. SCD:
   - Choose appropriate SCD type
   - Index business key columns
   - Test all change scenarios
   - Include audit columns
   - Consider manual implementation for complex logic
*/

-- ============================================================================
-- REFERENCE QUERIES
-- ============================================================================

-- Verify aggregate results
SELECT 
    'SQL Aggregate' AS Method,
    COUNT(*) AS RecordCount,
    SUM(TotalAmount) AS TotalRevenue
FROM BookstoreDB.dbo.Orders
UNION ALL
SELECT 
    'SSIS Load',
    COUNT(*),
    SUM(TotalRevenue)
FROM Sales_Summary_Daily;

-- SCD history view
SELECT 
    ProductID,
    ProductName,
    Category,
    UnitPrice,
    StartDate,
    EndDate,
    IsCurrent,
    DATEDIFF(DAY, StartDate, ISNULL(EndDate, GETDATE())) AS DaysActive
FROM DimProduct_SCD
ORDER BY ProductID, StartDate;

-- Row count audit report
SELECT 
    DataFlowName,
    StepDescription,
    AVG(RowCount) AS AvgRowCount,
    MAX(ExecutionTime) AS LastRun
FROM RowCount_Audit
GROUP BY DataFlowName, StepDescription;

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Mastered Aggregate transformation for summarization
□ Used Row Count for tracking and validation
□ Implemented Pivot and Unpivot transformations
□ Created custom Script Component transformations
□ Understood SCD types and implementation
□ Worked with sampling and character transformations
□ Completed all exercises
□ Solved at least one challenge problem

NEXT LAB: Lab 58 - Package Configuration and Deployment
============================================================================
*/
