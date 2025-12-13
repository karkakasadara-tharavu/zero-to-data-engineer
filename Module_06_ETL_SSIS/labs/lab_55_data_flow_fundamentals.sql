/*
============================================================================
LAB 55: SSIS DATA FLOW FUNDAMENTALS
Module 06: ETL SSIS Fundamentals
============================================================================

OBJECTIVE:
- Understand data flow architecture and pipeline
- Configure sources (OLE DB, Flat File, Excel)
- Configure destinations and mappings
- Use basic transformations (Derived Column, Data Conversion)
- Monitor data flow performance and buffer usage

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐ (Intermediate-Advanced)

PREREQUISITES:
- Completed Labs 53-54
- Understanding of SSIS Control Flow
- BookstoreDB and BookstoreETL databases
- Sample CSV and Excel files

DATABASE: BookstoreDB, BookstoreETL
============================================================================
*/

USE BookstoreETL;
GO

-- ============================================================================
-- PART 1: DATA FLOW ARCHITECTURE
-- ============================================================================
/*
DATA FLOW PIPELINE ARCHITECTURE:

SOURCES → TRANSFORMATIONS → DESTINATIONS

BUFFER-BASED PROCESSING:
- Data flows through in-memory buffers
- Default buffer size: 10MB
- Default buffer rows: 10,000
- Buffers are reused for efficiency
- Data types must be compatible

DATA FLOW COMPONENTS:

1. SOURCES:
   - Extract data from source systems
   - OLE DB Source, Flat File Source, Excel Source
   - ADO.NET Source, XML Source, ODBC Source
   - Raw File Source (SSIS native format)

2. TRANSFORMATIONS:
   - Modify data in-flight
   - Row transformations (process one row at a time)
   - Rowset transformations (process multiple rows)
   - Blocking vs. non-blocking transformations

3. DESTINATIONS:
   - Load data to target systems
   - OLE DB Destination, Flat File Destination
   - Excel Destination, SQL Server Destination
   - Raw File Destination

DATA FLOW PATHS:
- Connect components (blue arrows)
- Carry data between components
- Can have Data Viewers for debugging
- Show row counts during execution
*/

-- Create destination tables for data flow exercises
CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    JoinYear INT,
    JoinMonth INT,
    JoinDate DATE,
    IsActive BIT,
    LoadDate DATETIME DEFAULT GETDATE(),
    UpdateDate DATETIME
);

CREATE TABLE DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    ProductName NVARCHAR(200),
    CategoryName NVARCHAR(100),
    UnitPrice DECIMAL(10, 2),
    PriceCategory NVARCHAR(50),
    IsAvailable BIT,
    LoadDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    CustomerKey INT,
    ProductKey INT,
    OrderDate DATE,
    Quantity INT,
    UnitPrice DECIMAL(10, 2),
    LineTotal DECIMAL(10, 2),
    DiscountAmount DECIMAL(10, 2),
    TaxAmount DECIMAL(10, 2),
    LoadDate DATETIME DEFAULT GETDATE()
);

-- ============================================================================
-- PART 2: OLE DB SOURCE CONFIGURATION
-- ============================================================================
/*
OLE DB SOURCE is the most common and performant source:

ACCESS MODES:
1. Table or View:
   - Select entire table
   - Simple and straightforward
   - Pulls all columns

2. Table or View - Fast Load:
   - Fastest option for large datasets
   - Uses bulk insert
   - Table Lock required

3. SQL Command:
   - Custom SELECT query
   - Filter rows and columns
   - Join multiple tables
   - Most flexible

4. SQL Command from Variable:
   - Dynamic query construction
   - Runtime query modification
   - Parameterized queries

BEST PRACTICES:
- Use SQL Command mode for filtering at source
- Select only needed columns
- Apply WHERE clauses to reduce data volume
- Use WITH (NOLOCK) for read operations
- Create indexed views for complex joins
*/

-- Create optimized source views
CREATE OR ALTER VIEW vw_CustomerSource
AS
SELECT 
    CustomerID,
    FirstName,
    LastName,
    FirstName + ' ' + LastName AS FullName,
    Email,
    Phone,
    JoinDate,
    YEAR(JoinDate) AS JoinYear,
    MONTH(JoinDate) AS JoinMonth,
    IsActive,
    ISNULL(LastModified, JoinDate) AS LastModified
FROM BookstoreDB.dbo.SourceCustomers WITH (NOLOCK);
GO

CREATE OR ALTER VIEW vw_ProductSource
AS
SELECT 
    b.BookID AS ProductID,
    b.Title AS ProductName,
    ISNULL(c.CategoryName, 'Uncategorized') AS CategoryName,
    b.Price AS UnitPrice,
    CASE 
        WHEN b.Price < 20 THEN 'Budget'
        WHEN b.Price BETWEEN 20 AND 50 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceCategory,
    CASE WHEN b.Price > 0 THEN 1 ELSE 0 END AS IsAvailable
FROM BookstoreDB.dbo.Books b WITH (NOLOCK)
LEFT JOIN BookstoreDB.dbo.Categories c ON b.CategoryID = c.CategoryID;
GO

-- Sample incremental load query (use in SQL Command mode)
DECLARE @LastExtractDate DATETIME = '2024-01-01';

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    JoinDate,
    IsActive
FROM BookstoreDB.dbo.SourceCustomers WITH (NOLOCK)
WHERE ISNULL(LastModified, JoinDate) > @LastExtractDate;

/*
OLE DB SOURCE EXAMPLE CONFIGURATION:

1. Add OLE DB Source to Data Flow
2. Double-click to open editor
3. OLE DB Connection Manager: BookstoreDB
4. Data Access Mode: SQL Command
5. SQL Command Text:
   SELECT * FROM vw_CustomerSource
   WHERE LastModified > ?
6. Parameters: Map variable to ?
7. Columns: Verify all columns available
8. Preview: Test query execution
*/

-- ============================================================================
-- PART 3: FLAT FILE SOURCE CONFIGURATION
-- ============================================================================
/*
FLAT FILE SOURCE reads delimited or fixed-width text files:

FILE FORMATS:
- CSV (Comma-Separated Values)
- TSV (Tab-Separated Values)
- Fixed-Width (column positions)
- Ragged Right (last column variable width)

CONFIGURATION STEPS:
1. Create Flat File Connection Manager
2. Browse to file location
3. Configure format:
   - Delimited (CSV) or Fixed Width
   - Text Qualifier (usually double quote)
   - Header Row Delimiter
   - Column Names in First Row
4. Define columns and data types
5. Preview data

COMMON ISSUES:
- Incorrect delimiter
- Text qualifiers not configured
- Wrong data types
- Header row not detected
- Encoding issues (UTF-8 vs ASCII)

DATA TYPE MAPPING:
- String → DT_STR (ANSI) or DT_WSTR (Unicode)
- Integer → DT_I4
- Decimal → DT_NUMERIC
- Date → DT_DBTIMESTAMP
*/

-- Create sample CSV data for import
-- In real scenario, this would be a file
-- File: customers.csv content:
/*
CustomerID,FirstName,LastName,Email,Phone,JoinDate
1001,Alice,Anderson,alice.a@email.com,555-1001,2024-01-15
1002,Bob,Baker,bob.b@email.com,555-1002,2024-02-20
1003,Carol,Carter,carol.c@email.com,555-1003,2024-03-10
1004,David,Davis,david.d@email.com,555-1004,2024-04-05
1005,Eve,Edwards,eve.e@email.com,555-1005,2024-05-12
*/

-- Create staging table for flat file imports
CREATE TABLE Staging_FlatFileImport (
    CustomerID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    JoinDate DATE,
    ImportDate DATETIME DEFAULT GETDATE(),
    FileName NVARCHAR(255)
);

/*
FLAT FILE SOURCE EXAMPLE PACKAGE:

1. Create Flat File Connection Manager:
   - Name: "CSV_Customers"
   - File Path: C:\ETL\Input\customers.csv
   - Format: Delimited
   - Text Qualifier: "
   - Column Delimiter: Comma
   - Row Delimiter: {CR}{LF}

2. Add Flat File Source to Data Flow
3. Configure:
   - Connection Manager: CSV_Customers
   - Retain Null Values: True (preserve NULLs)
   - Columns: All selected

4. Connect to OLE DB Destination
*/

-- ============================================================================
-- PART 4: OLE DB DESTINATION CONFIGURATION
-- ============================================================================
/*
OLE DB DESTINATION is the most common and performant destination:

ACCESS MODES:
1. Table or View - Fast Load:
   - BULK INSERT operation
   - Fastest for large datasets
   - Options:
     * Keep Identity: Preserve identity values
     * Keep Nulls: Insert NULL values
     * Table Lock: Lock entire table
     * Check Constraints: Validate constraints
   - Rows per Batch: 0 (all rows in one batch)
   - Maximum Insert Commit Size: 2147483647 (max)

2. Table or View:
   - Row-by-row INSERT statements
   - Slower but more flexible
   - Better for small datasets
   - Allows triggers to fire

3. Table or View Name - Fast Load from Variable:
   - Dynamic table name
   - Uses variable for table name

4. SQL Command:
   - Custom INSERT, UPDATE, or stored procedure
   - Maximum flexibility
   - Can include complex logic

PERFORMANCE OPTIONS:
- Rows per Batch: Number of rows per batch (0 = all)
- Maximum Insert Commit Size: Rows before commit (0 = at end)
- Keep Identity: ON for loading dimension keys
- Check Constraints: OFF during bulk load, rebuild after
- Table Lock: ON for exclusive access during load
*/

-- Create stored procedure for custom destination
CREATE OR ALTER PROCEDURE sp_UpsertCustomer
    @CustomerID INT,
    @FullName NVARCHAR(101),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20),
    @JoinDate DATE,
    @IsActive BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM DimCustomer WHERE CustomerID = @CustomerID)
    BEGIN
        UPDATE DimCustomer
        SET FullName = @FullName,
            Email = @Email,
            Phone = @Phone,
            IsActive = @IsActive,
            UpdateDate = GETDATE()
        WHERE CustomerID = @CustomerID;
    END
    ELSE
    BEGIN
        INSERT INTO DimCustomer (
            CustomerID, FullName, Email, Phone, 
            JoinDate, JoinYear, JoinMonth, IsActive
        )
        VALUES (
            @CustomerID, @FullName, @Email, @Phone,
            @JoinDate, YEAR(@JoinDate), MONTH(@JoinDate), @IsActive
        );
    END
END;
GO

/*
OLE DB DESTINATION EXAMPLE CONFIGURATION:

1. Add OLE DB Destination to Data Flow
2. Connect from source or transformation
3. Configure:
   - Connection Manager: BookstoreETL
   - Data Access Mode: Table or View - Fast Load
   - Table Name: dbo.DimCustomer
4. Options:
   - Keep Identity: Checked (if loading identity column)
   - Keep Nulls: Checked
   - Table Lock: Checked
   - Check Constraints: Unchecked (for speed)
5. Mappings:
   - Automatically map matching column names
   - Manually map any mismatches
   - Ignore unused destination columns
*/

-- ============================================================================
-- PART 5: DERIVED COLUMN TRANSFORMATION
-- ============================================================================
/*
DERIVED COLUMN TRANSFORMATION creates new columns or replaces existing ones:

USES:
- Calculate new values from existing columns
- String concatenation
- Date/time calculations
- Conditional logic
- Type conversions
- Extract parts of strings

EXPRESSION LANGUAGE:
- Operators: +, -, *, /, %, &&, ||, !, ==, !=, <, >, <=, >=
- Functions:
  * String: UPPER, LOWER, SUBSTRING, LEN, TRIM, REPLACE
  * Date: DATEPART, DATEADD, DATEDIFF, YEAR, MONTH, DAY
  * Math: ABS, ROUND, CEILING, FLOOR, SQRT, POWER
  * Null: ISNULL, NULL
  * Conditional: condition ? true_value : false_value
  * Type Cast: (DT_STR, 50, 1252) or (DT_I4)

COMMON PATTERNS:
- Full Name: FirstName + " " + LastName
- Age: DATEDIFF("year", BirthDate, GETDATE())
- Flag: Quantity > 10 ? "Bulk" : "Retail"
- Clean Phone: REPLACE(REPLACE(Phone, "(", ""), ")", "")
*/

-- Examples of calculations Derived Column can perform
SELECT 
    CustomerID,
    FirstName,
    LastName,
    -- String concatenation
    FirstName + ' ' + LastName AS FullName,
    -- Uppercase transformation
    UPPER(Email) AS EmailUpper,
    -- Extract domain from email
    SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS EmailDomain,
    -- Year extraction
    YEAR(JoinDate) AS JoinYear,
    -- Conditional logic
    CASE WHEN IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS StatusText,
    -- Date difference
    DATEDIFF(DAY, JoinDate, GETDATE()) AS DaysSinceJoin,
    -- Calculated value
    CASE 
        WHEN DATEDIFF(DAY, JoinDate, GETDATE()) < 30 THEN 'New'
        WHEN DATEDIFF(DAY, JoinDate, GETDATE()) < 365 THEN 'Regular'
        ELSE 'Veteran'
    END AS CustomerTenure
FROM BookstoreDB.dbo.SourceCustomers;

/*
DERIVED COLUMN TRANSFORMATION EXAMPLE:

1. Add Derived Column Transformation to Data Flow
2. Connect from source
3. Configure columns:

Column Name         | Derived Column      | Expression
--------------------|---------------------|----------------------------------
FullName            | Add as New Column   | FirstName + " " + LastName
EmailDomain         | Add as New Column   | SUBSTRING(Email, FINDSTRING(Email, "@", 1) + 1, LEN(Email))
JoinYear            | Add as New Column   | YEAR(JoinDate)
JoinMonth           | Add as New Column   | MONTH(JoinDate)
CustomerAge         | Add as New Column   | DATEDIFF("day", JoinDate, GETDATE())
CustomerTier        | Add as New Column   | CustomerAge < 30 ? "New" : (CustomerAge < 365 ? "Regular" : "Veteran")
LoadTimestamp       | Add as New Column   | GETDATE()

4. Advanced Editor → Input and Output Properties:
   - Set data types for new columns
   - Configure length for string columns
   - Set precision for numeric columns
*/

-- ============================================================================
-- PART 6: DATA CONVERSION TRANSFORMATION
-- ============================================================================
/*
DATA CONVERSION TRANSFORMATION changes data types:

WHY NEEDED:
- Source and destination have different data types
- Flat File source (all strings) → Database (typed columns)
- Optimize data types for destination
- Explicit type safety

COMMON CONVERSIONS:
- DT_STR (ANSI string) → DT_WSTR (Unicode string)
- DT_STR → DT_I4 (integer)
- DT_STR → DT_NUMERIC (decimal)
- DT_STR → DT_DBTIMESTAMP (datetime)
- DT_WSTR → DT_STR (Unicode to ANSI)

CONFIGURATION:
- Select input columns to convert
- Set output data type
- Set length, precision, scale
- Set code page (for string conversions)
- Configure error handling (fail, ignore, redirect row)

SSIS DATA TYPES REFERENCE:
DT_BOOL          - Boolean
DT_I1            - Signed 1-byte integer
DT_I2            - Signed 2-byte integer (SMALLINT)
DT_I4            - Signed 4-byte integer (INT)
DT_I8            - Signed 8-byte integer (BIGINT)
DT_UI1           - Unsigned 1-byte integer (TINYINT)
DT_R4            - 4-byte float (REAL)
DT_R8            - 8-byte float (FLOAT)
DT_NUMERIC       - Numeric with precision and scale (DECIMAL)
DT_DECIMAL       - Decimal
DT_CY            - Currency (MONEY)
DT_DATE          - Date structure
DT_DBDATE        - Date (no time)
DT_DBTIME        - Time (no date)
DT_DBTIMESTAMP   - Timestamp (DATETIME)
DT_STR           - ANSI string
DT_WSTR          - Unicode string (NVARCHAR)
DT_BYTES         - Binary data
DT_IMAGE         - Large binary (IMAGE, VARBINARY(MAX))
DT_TEXT          - Large text (TEXT)
DT_NTEXT         - Large Unicode text (NTEXT)
*/

-- Example: Converting flat file strings to proper types
SELECT 
    -- String to Integer
    CAST(CustomerID AS INT) AS CustomerID_INT,
    -- String to Date
    CAST(JoinDate AS DATE) AS JoinDate_DATE,
    -- String to Decimal
    CAST('49.99' AS DECIMAL(10, 2)) AS Price_DECIMAL,
    -- String to DateTime
    CAST('2024-05-20 14:30:00' AS DATETIME) AS OrderTime_DATETIME
FROM (
    SELECT 
        '1001' AS CustomerID,
        '2024-01-15' AS JoinDate
) AS StringData;

/*
DATA CONVERSION TRANSFORMATION EXAMPLE:

SCENARIO: Flat File (all strings) → Database (typed columns)

1. Add Data Conversion Transformation after Flat File Source
2. Configure conversions:

Input Column | Output Alias        | Data Type       | Length | Precision | Scale
-------------|--------------------|--------------------|--------|-----------|------
CustomerID   | CustomerID_INT     | DT_I4              |        |           |
JoinDate     | JoinDate_DATE      | DT_DBTIMESTAMP     |        |           |
Phone        | Phone_WSTR         | DT_WSTR            | 20     |           |
Price        | Price_DECIMAL      | DT_NUMERIC         |        | 10        | 2

3. In OLE DB Destination Mappings:
   - Map CustomerID_INT → CustomerID
   - Map JoinDate_DATE → JoinDate
   - Map Phone_WSTR → Phone
   - Map Price_DECIMAL → Price
*/

-- ============================================================================
-- PART 7: COLUMN MAPPINGS
-- ============================================================================
/*
COLUMN MAPPING connects source columns to destination columns:

AUTOMATIC MAPPING:
- SSIS auto-maps columns with matching names
- Case-insensitive matching
- Must have compatible data types

MANUAL MAPPING:
- Drag source column to destination column
- Required when names don't match
- Required for derived columns

UNMAPPED COLUMNS:
- Source: Column is ignored (not loaded)
- Destination: Must allow NULL or have DEFAULT

MAPPING ISSUES:
- Data type mismatch (fix with Data Conversion)
- Column name mismatch (manual mapping)
- NULL handling (configure destination to allow NULLs)
- Identity columns (set Keep Identity = true)
*/

-- View column metadata for mapping reference
SELECT 
    c.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_SCHEMA = 'dbo'
    AND c.TABLE_NAME IN ('DimCustomer', 'DimProduct', 'FactSales')
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- ============================================================================
-- PART 8: ERROR OUTPUT AND ROW REDIRECTION
-- ============================================================================
/*
ERROR OUTPUT handles rows that fail during transformation:

ERROR TYPES:
- Truncation: Data too long for destination column
- Conversion error: Cannot convert data type
- Constraint violation: Primary key, foreign key, check
- NULL error: NULL value in non-nullable column

ERROR HANDLING OPTIONS:
1. Fail Component: Stop package execution (default)
2. Ignore Failure: Skip error, continue processing
3. Redirect Row: Send row to error output

ERROR OUTPUT COLUMNS:
- All input columns
- ErrorCode: Integer error code
- ErrorColumn: ID of column causing error

IMPLEMENTATION:
1. Configure error output on transformation/destination
2. Add error path (red arrow) from component
3. Direct error rows to:
   - Flat File Destination (error log file)
   - Database table (error tracking)
   - Script Component (custom handling)
*/

-- Create error logging table
CREATE TABLE DataFlow_ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    DataFlowName NVARCHAR(255),
    ErrorCode INT,
    ErrorColumn INT,
    ErrorDescription NVARCHAR(MAX),
    SourceRow NVARCHAR(MAX),
    ErrorDate DATETIME DEFAULT GETDATE()
);

-- Procedure to log data flow errors
CREATE OR ALTER PROCEDURE sp_LogDataFlowError
    @PackageName NVARCHAR(255),
    @DataFlowName NVARCHAR(255),
    @ErrorCode INT,
    @ErrorColumn INT,
    @SourceRow NVARCHAR(MAX)
AS
BEGIN
    -- Lookup error description
    DECLARE @ErrorDescription NVARCHAR(MAX);
    
    SET @ErrorDescription = 
        CASE @ErrorCode
            WHEN -1071607685 THEN 'Data conversion failed'
            WHEN -1071607684 THEN 'Truncation occurred'
            WHEN -1071607778 THEN 'Error output row disposition'
            WHEN -1071607676 THEN 'Lookup match failed'
            ELSE 'Unknown error: ' + CAST(@ErrorCode AS VARCHAR)
        END;
    
    INSERT INTO DataFlow_ErrorLog (
        PackageName, DataFlowName, ErrorCode, 
        ErrorColumn, ErrorDescription, SourceRow
    )
    VALUES (
        @PackageName, @DataFlowName, @ErrorCode,
        @ErrorColumn, @ErrorDescription, @SourceRow
    );
END;
GO

/*
ERROR OUTPUT EXAMPLE CONFIGURATION:

1. Double-click Data Conversion Transformation
2. Configure Error Output:
   - Error: Redirect Row
   - Truncation: Redirect Row
3. Connect error output (red arrow) to Flat File Destination
4. Configure Flat File for error logging:
   - File: C:\ETL\Errors\DataConversion_Errors_YYYYMMDD.txt
   - Columns: All input columns + ErrorCode + ErrorColumn
*/

-- ============================================================================
-- PART 9: DATA VIEWERS
-- ============================================================================
/*
DATA VIEWERS allow real-time data inspection during debugging:

VIEW TYPES:
1. Grid: Tabular view of data rows
2. Histogram: Distribution of values in a column
3. Scatter Plot: Compare two numeric columns
4. Column Chart: Bar chart of data values

USES:
- Debug transformation logic
- Verify calculations
- Check data quality
- Analyze data distribution
- Troubleshoot issues

ADDING DATA VIEWER:
1. Right-click data flow path (blue arrow)
2. Select "Enable Data Viewer"
3. Choose viewer type (Grid is most common)
4. Configure columns to display
5. Run package in Debug mode
6. Viewer pops up during execution showing data

PERFORMANCE IMPACT:
- Pauses data flow at viewer point
- Manual "Play" continues flow
- Remove viewers for production
- Use only during development/debugging
*/

-- Query to analyze what Data Viewer would show
SELECT TOP 100
    CustomerID,
    FirstName,
    LastName,
    FirstName + ' ' + LastName AS FullName,
    Email,
    SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS EmailDomain,
    JoinDate,
    YEAR(JoinDate) AS JoinYear,
    DATEDIFF(DAY, JoinDate, GETDATE()) AS DaysSinceJoin
FROM BookstoreDB.dbo.SourceCustomers
ORDER BY CustomerID;

-- ============================================================================
-- PART 10: DATA FLOW PERFORMANCE MONITORING
-- ============================================================================
/*
PERFORMANCE METRICS:

1. ROWS/SEC:
   - Throughput rate
   - Displayed during execution
   - Visible on data flow paths

2. BUFFER MEMORY:
   - DefaultBufferMaxRows: 10,000
   - DefaultBufferSize: 10MB
   - Adjust in Data Flow properties

3. EXECUTION TREE:
   - Blocking transformations pause pipeline
   - Non-blocking transformations stream data
   - Minimize blocking transformations

BLOCKING CHARACTERISTICS:
- Non-Blocking: Data flows immediately (Derived Column, Data Conversion)
- Semi-Blocking: Some rows buffered (Merge Join, Union All)
- Fully Blocking: All rows required before output (Sort, Aggregate)

OPTIMIZATION TECHNIQUES:
- Push filtering to source (WHERE clause)
- Select only needed columns
- Remove unnecessary transformations
- Adjust buffer sizes for large datasets
- Use SQL transformation instead of SSIS when possible
- Parallel execution for independent paths
*/

-- Create performance tracking table
CREATE TABLE DataFlow_Performance (
    PerfID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    DataFlowName NVARCHAR(255),
    StartTime DATETIME,
    EndTime DATETIME,
    DurationSeconds INT,
    RowsProcessed INT,
    RowsPerSecond DECIMAL(10, 2),
    BufferCount INT,
    MemoryUsedMB DECIMAL(10, 2)
);

-- Procedure to log data flow performance
CREATE OR ALTER PROCEDURE sp_LogDataFlowPerformance
    @PackageName NVARCHAR(255),
    @DataFlowName NVARCHAR(255),
    @StartTime DATETIME,
    @EndTime DATETIME,
    @RowsProcessed INT,
    @BufferCount INT = NULL,
    @MemoryUsedMB DECIMAL(10, 2) = NULL
AS
BEGIN
    DECLARE @DurationSeconds INT;
    DECLARE @RowsPerSecond DECIMAL(10, 2);
    
    SET @DurationSeconds = DATEDIFF(SECOND, @StartTime, @EndTime);
    SET @RowsPerSecond = CASE 
        WHEN @DurationSeconds > 0 
        THEN CAST(@RowsProcessed AS DECIMAL(10, 2)) / @DurationSeconds
        ELSE @RowsProcessed
    END;
    
    INSERT INTO DataFlow_Performance (
        PackageName, DataFlowName, StartTime, EndTime,
        DurationSeconds, RowsProcessed, RowsPerSecond,
        BufferCount, MemoryUsedMB
    )
    VALUES (
        @PackageName, @DataFlowName, @StartTime, @EndTime,
        @DurationSeconds, @RowsProcessed, @RowsPerSecond,
        @BufferCount, @MemoryUsedMB
    );
END;
GO

-- Performance analysis query
SELECT 
    DataFlowName,
    AVG(DurationSeconds) AS AvgDuration,
    AVG(RowsProcessed) AS AvgRows,
    AVG(RowsPerSecond) AS AvgThroughput,
    MAX(RowsPerSecond) AS MaxThroughput,
    COUNT(*) AS ExecutionCount
FROM DataFlow_Performance
GROUP BY DataFlowName
ORDER BY AvgThroughput DESC;

-- ============================================================================
-- EXERCISES
-- ============================================================================

-- EXERCISE 1: Simple Extract-Load (20 minutes)
/*
Create data flow "DFT_Customer_Extract":
1. OLE DB Source: vw_CustomerSource
2. Derived Column: Add LoadDate = GETDATE()
3. OLE DB Destination: DimCustomer (Fast Load)
4. Add Data Viewer to inspect data
5. Execute and verify row count matches
*/

SELECT COUNT(*) AS SourceCount FROM BookstoreDB.dbo.SourceCustomers;
SELECT COUNT(*) AS DestCount FROM DimCustomer;

-- EXERCISE 2: Flat File Import (25 minutes)
/*
Create data flow "DFT_Import_CSV":
1. Create CSV file with customer data
2. Flat File Source: Read CSV
3. Data Conversion: Convert all strings to proper types
4. Derived Column: Add FileName variable value
5. OLE DB Destination: Staging_FlatFileImport
6. Handle errors by redirecting to error file
*/

-- EXERCISE 3: Calculated Columns (20 minutes)
/*
Create data flow "DFT_Product_Transform":
1. OLE DB Source: Books table
2. Derived Column transformations:
   - FullPrice: Price * 1.0 (no discount)
   - DiscountPrice: Price * 0.9 (10% off)
   - PriceCategory: Budget/Standard/Premium based on price
   - IsExpensive: Flag for price > 50
3. OLE DB Destination: DimProduct
*/

-- EXERCISE 4: Error Handling (25 minutes)
/*
Create data flow with intentional errors:
1. Create CSV with bad data (invalid dates, non-numeric IDs)
2. Flat File Source
3. Data Conversion (will fail on bad data)
4. Configure error output: Redirect Row
5. Good rows → OLE DB Destination
6. Error rows → Flat File Destination (error log)
7. Execute and verify error handling
*/

-- EXERCISE 5: Performance Comparison (30 minutes)
/*
Compare performance of different approaches:
1. Create Data Flow A: Row-by-row destination (Table or View mode)
2. Create Data Flow B: Bulk load destination (Fast Load mode)
3. Load 10,000 rows with each approach
4. Measure and compare execution time
5. Document results in DataFlow_Performance table
*/

-- ============================================================================
-- CHALLENGE PROBLEMS
-- ============================================================================

-- CHALLENGE 1: Complex Transformation Pipeline (45 minutes)
/*
Create comprehensive customer dimension load:
1. OLE DB Source: Multiple customer sources (UNION)
2. Derived Column: Calculate customer attributes
   - FullName
   - CustomerAge (days since join)
   - CustomerTier (New/Regular/Veteran)
   - PreferredCustomer (flag based on tier)
3. Data Conversion: Ensure proper types
4. Conditional Split: Separate active vs inactive
5. Two destinations:
   - Active customers → DimCustomer
   - Inactive customers → DimCustomer_Inactive
6. Implement full error handling
7. Log performance metrics
*/

CREATE TABLE DimCustomer_Inactive (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    FullName NVARCHAR(101),
    Email NVARCHAR(100),
    InactiveSince DATETIME,
    LoadDate DATETIME DEFAULT GETDATE()
);

-- CHALLENGE 2: Multi-Source Integration (60 minutes)
/*
Create data flow that combines multiple sources:
1. OLE DB Source: Database customers
2. Flat File Source: New customers from CSV
3. Excel Source: VIP customers from Excel
4. Union All: Combine all sources
5. Derived Column: Add source identifier
6. Sort: Order by CustomerID
7. Aggregate: Remove duplicates (keep most recent)
8. Lookup: Validate against existing data
9. OLE DB Destination: Final customer table
10. Comprehensive error handling and logging
*/

-- CHALLENGE 3: Incremental Load with Change Detection (90 minutes)
/*
Implement slowly changing dimension (Type 1):
1. OLE DB Source: New/changed customers (use watermark)
2. Lookup: Check if customer exists in DimCustomer
3. Conditional Split: New vs Existing customers
4. For New:
   - Derived Column: Set LoadDate
   - OLE DB Destination: INSERT into DimCustomer
5. For Existing:
   - Derived Column: Set UpdateDate
   - OLE DB Command: UPDATE DimCustomer
6. Update watermark table after successful load
7. Log statistics (inserts, updates, errors)
8. Implement comprehensive error handling
*/

-- ============================================================================
-- BEST PRACTICES
-- ============================================================================
/*
1. SOURCE OPTIMIZATION:
   - Filter at source level (WHERE clause)
   - Select only required columns
   - Use indexed views for complex joins
   - Apply WITH (NOLOCK) for read operations
   - Consider incremental loads vs full extracts

2. TRANSFORMATION EFFICIENCY:
   - Minimize number of transformations
   - Use SQL transformations when possible
   - Avoid blocking transformations
   - Use Derived Column instead of Script Component
   - Proper data type usage from the start

3. DESTINATION CONFIGURATION:
   - Use Fast Load mode for bulk inserts
   - Disable constraints during load
   - Rebuild indexes after load
   - Set appropriate batch sizes
   - Use Table Lock for exclusive access

4. ERROR HANDLING:
   - Always configure error outputs
   - Log errors to persistent storage
   - Use Redirect Row, not Ignore Failure
   - Include source row data in error logs
   - Monitor error rates

5. PERFORMANCE:
   - Adjust buffer sizes for dataset
   - Use parallel execution where possible
   - Monitor row throughput
   - Profile memory usage
   - Remove data viewers in production

6. DEBUGGING:
   - Use Data Viewers during development
   - Test with small datasets first
   - Validate results with SQL queries
   - Check row counts at each step
   - Log execution statistics
*/

-- ============================================================================
-- REFERENCE QUERIES
-- ============================================================================

-- Verify data flow results
SELECT 'Source' AS Location, COUNT(*) AS RowCount 
FROM BookstoreDB.dbo.SourceCustomers
UNION ALL
SELECT 'Destination', COUNT(*) 
FROM DimCustomer;

-- Error analysis
SELECT 
    ErrorCode,
    ErrorDescription,
    COUNT(*) AS Occurrences,
    MAX(ErrorDate) AS LastOccurrence
FROM DataFlow_ErrorLog
GROUP BY ErrorCode, ErrorDescription
ORDER BY Occurrences DESC;

-- Performance trends
SELECT 
    CAST(StartTime AS DATE) AS ExecutionDate,
    DataFlowName,
    COUNT(*) AS Executions,
    AVG(RowsPerSecond) AS AvgThroughput,
    AVG(DurationSeconds) AS AvgDuration
FROM DataFlow_Performance
WHERE StartTime >= DATEADD(DAY, -7, GETDATE())
GROUP BY CAST(StartTime AS DATE), DataFlowName
ORDER BY ExecutionDate DESC, AvgThroughput DESC;

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Understood data flow architecture and buffer-based processing
□ Configured OLE DB Source with different access modes
□ Configured Flat File Source for CSV import
□ Used Derived Column for calculated values
□ Applied Data Conversion for type changes
□ Configured OLE DB Destination with Fast Load
□ Implemented error output and row redirection
□ Used Data Viewers for debugging
□ Monitored data flow performance
□ Completed all exercises and at least one challenge

NEXT LAB: Lab 56 - SSIS Data Flow Transformations
============================================================================
*/
