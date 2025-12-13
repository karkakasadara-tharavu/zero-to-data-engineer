/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  MODULE 07: ADVANCED ETL PATTERNS                                            ║
║  LAB 62: SLOWLY CHANGING DIMENSIONS (SCD)                                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Learning Objectives:                                                        ║
║  • Understand SCD Types 0, 1, 2, 3, 4, and 6                                ║
║  • Implement SCD Type 1 (Overwrite)                                         ║
║  • Implement SCD Type 2 (Historical Tracking)                               ║
║  • Implement SCD Type 3 (Previous Value Column)                             ║
║  • Master hybrid SCD approaches                                              ║
║  • Handle complex dimension scenarios                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- ============================================================================
-- SECTION 1: SLOWLY CHANGING DIMENSIONS OVERVIEW
-- ============================================================================

/*
Slowly Changing Dimensions (SCD) are dimension tables that change over time.
Different SCD types handle changes differently:

┌─────────┬─────────────────────┬─────────────────────────────────────────────┐
│ Type    │ Description         │ Use Case                                    │
├─────────┼─────────────────────┼─────────────────────────────────────────────┤
│ Type 0  │ Fixed/Passive       │ Never changes (e.g., original signup date) │
│ Type 1  │ Overwrite           │ Current value only (e.g., phone number)    │
│ Type 2  │ Add New Row         │ Full history tracking (e.g., address)      │
│ Type 3  │ Add New Column      │ Limited history (current + previous)       │
│ Type 4  │ Mini-Dimension      │ Rapidly changing attributes                │
│ Type 6  │ Hybrid (1+2+3)      │ Combines multiple approaches               │
└─────────┴─────────────────────┴─────────────────────────────────────────────┘
*/

-- ============================================================================
-- SECTION 2: SETUP - CREATE DIMENSION TABLES
-- ============================================================================

USE DataEngineerTraining;
GO

-- Create schema for dimension tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim')
    EXEC('CREATE SCHEMA dim');
GO

-- ============================================================================
-- SECTION 3: SCD TYPE 1 - OVERWRITE
-- ============================================================================

/*
SCD Type 1: Simply overwrite the old value with the new value.
- No history is maintained
- Simplest approach
- Used for corrections or non-critical attributes
*/

-- Create Type 1 Customer Dimension
CREATE TABLE dim.Customer_Type1 (
    CustomerKey         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID          INT NOT NULL UNIQUE,        -- Business Key
    CustomerName        NVARCHAR(100) NOT NULL,
    Email               NVARCHAR(100),
    Phone               NVARCHAR(20),               -- Type 1: Overwrite
    Address             NVARCHAR(200),              -- Type 1: Overwrite
    City                NVARCHAR(50),
    State               NVARCHAR(50),
    Country             NVARCHAR(50),
    CustomerSegment     NVARCHAR(50),               -- Type 1: Overwrite
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    LastModifiedDate    DATETIME2 DEFAULT GETDATE()
);
GO

-- Insert initial data
INSERT INTO dim.Customer_Type1 (CustomerID, CustomerName, Email, Phone, Address, City, State, Country, CustomerSegment)
VALUES 
    (1001, 'John Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', 'USA', 'Gold'),
    (1002, 'Jane Doe', 'jane.doe@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', 'USA', 'Silver'),
    (1003, 'Bob Johnson', 'bob.j@email.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', 'USA', 'Bronze');
GO

-- Create procedure for SCD Type 1 updates
CREATE OR ALTER PROCEDURE dim.usp_UpdateCustomer_Type1
    @CustomerID         INT,
    @CustomerName       NVARCHAR(100),
    @Email              NVARCHAR(100),
    @Phone              NVARCHAR(20),
    @Address            NVARCHAR(200),
    @City               NVARCHAR(50),
    @State              NVARCHAR(50),
    @Country            NVARCHAR(50),
    @CustomerSegment    NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if customer exists
    IF EXISTS (SELECT 1 FROM dim.Customer_Type1 WHERE CustomerID = @CustomerID)
    BEGIN
        -- SCD Type 1: Overwrite existing values
        UPDATE dim.Customer_Type1
        SET CustomerName = @CustomerName,
            Email = @Email,
            Phone = @Phone,
            Address = @Address,
            City = @City,
            State = @State,
            Country = @Country,
            CustomerSegment = @CustomerSegment,
            LastModifiedDate = GETDATE()
        WHERE CustomerID = @CustomerID;
        
        PRINT 'Customer updated (Type 1 - Overwrite)';
    END
    ELSE
    BEGIN
        -- Insert new customer
        INSERT INTO dim.Customer_Type1 (CustomerID, CustomerName, Email, Phone, Address, City, State, Country, CustomerSegment)
        VALUES (@CustomerID, @CustomerName, @Email, @Phone, @Address, @City, @State, @Country, @CustomerSegment);
        
        PRINT 'New customer inserted';
    END
END;
GO

-- ============================================================================
-- EXERCISE 1: SCD TYPE 1 IMPLEMENTATION
-- ============================================================================

/*
EXERCISE 1A: Update customer phone number (Type 1)

Scenario: John Smith (CustomerID 1001) changed his phone number to '555-9999'

Task: Execute the update and verify the old value is gone
*/

-- Your solution here:
-- EXEC dim.usp_UpdateCustomer_Type1 ...

-- Verify the update
SELECT * FROM dim.Customer_Type1 WHERE CustomerID = 1001;

/*
EXERCISE 1B: Create a Type 1 Product Dimension

Create a product dimension table with these Type 1 attributes:
- ProductKey (surrogate key)
- ProductID (business key)
- ProductName
- Category
- CurrentPrice (overwrite when price changes)
- Supplier
- IsActive

Include a stored procedure to handle inserts and updates.
*/

-- Your solution here:


-- ============================================================================
-- SECTION 4: SCD TYPE 2 - HISTORICAL TRACKING
-- ============================================================================

/*
SCD Type 2: Create a new row for each change, preserving history.
- Full history is maintained
- Requires surrogate key, effective dates, and current flag
- Most common approach for critical attributes
*/

-- Create Type 2 Customer Dimension
CREATE TABLE dim.Customer_Type2 (
    CustomerKey         INT IDENTITY(1,1) PRIMARY KEY,    -- Surrogate Key
    CustomerID          INT NOT NULL,                      -- Business Key
    CustomerName        NVARCHAR(100) NOT NULL,
    Email               NVARCHAR(100),
    Phone               NVARCHAR(20),
    Address             NVARCHAR(200),
    City                NVARCHAR(50),
    State               NVARCHAR(50),
    Country             NVARCHAR(50),
    CustomerSegment     NVARCHAR(50),
    
    -- Type 2 tracking columns
    EffectiveStartDate  DATE NOT NULL,
    EffectiveEndDate    DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent           BIT NOT NULL DEFAULT 1,
    VersionNumber       INT NOT NULL DEFAULT 1,
    
    -- Audit columns
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    LastModifiedDate    DATETIME2 DEFAULT GETDATE()
);
GO

-- Create indexes for performance
CREATE INDEX IX_Customer_Type2_BusinessKey ON dim.Customer_Type2(CustomerID, IsCurrent);
CREATE INDEX IX_Customer_Type2_EffectiveDates ON dim.Customer_Type2(EffectiveStartDate, EffectiveEndDate);
GO

-- Insert initial data
INSERT INTO dim.Customer_Type2 (CustomerID, CustomerName, Email, Phone, Address, City, State, Country, CustomerSegment, EffectiveStartDate)
VALUES 
    (1001, 'John Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', 'USA', 'Gold', '2024-01-01'),
    (1002, 'Jane Doe', 'jane.doe@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', 'USA', 'Silver', '2024-01-01'),
    (1003, 'Bob Johnson', 'bob.j@email.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', 'USA', 'Bronze', '2024-01-01');
GO

-- Create procedure for SCD Type 2 updates
CREATE OR ALTER PROCEDURE dim.usp_UpdateCustomer_Type2
    @CustomerID         INT,
    @CustomerName       NVARCHAR(100),
    @Email              NVARCHAR(100),
    @Phone              NVARCHAR(20),
    @Address            NVARCHAR(200),
    @City               NVARCHAR(50),
    @State              NVARCHAR(50),
    @Country            NVARCHAR(50),
    @CustomerSegment    NVARCHAR(50),
    @EffectiveDate      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default effective date to today
    SET @EffectiveDate = ISNULL(@EffectiveDate, CAST(GETDATE() AS DATE));
    
    DECLARE @CurrentVersion INT;
    DECLARE @HasChanges BIT = 0;
    
    -- Check if customer exists
    IF EXISTS (SELECT 1 FROM dim.Customer_Type2 WHERE CustomerID = @CustomerID AND IsCurrent = 1)
    BEGIN
        -- Check if there are actual changes
        SELECT @HasChanges = CASE 
            WHEN CustomerName != @CustomerName OR
                 ISNULL(Email, '') != ISNULL(@Email, '') OR
                 ISNULL(Phone, '') != ISNULL(@Phone, '') OR
                 ISNULL(Address, '') != ISNULL(@Address, '') OR
                 ISNULL(City, '') != ISNULL(@City, '') OR
                 ISNULL(State, '') != ISNULL(@State, '') OR
                 ISNULL(Country, '') != ISNULL(@Country, '') OR
                 ISNULL(CustomerSegment, '') != ISNULL(@CustomerSegment, '')
            THEN 1 ELSE 0 END,
            @CurrentVersion = VersionNumber
        FROM dim.Customer_Type2
        WHERE CustomerID = @CustomerID AND IsCurrent = 1;
        
        IF @HasChanges = 1
        BEGIN
            BEGIN TRANSACTION;
            
            -- Step 1: Expire the current record
            UPDATE dim.Customer_Type2
            SET EffectiveEndDate = DATEADD(DAY, -1, @EffectiveDate),
                IsCurrent = 0,
                LastModifiedDate = GETDATE()
            WHERE CustomerID = @CustomerID AND IsCurrent = 1;
            
            -- Step 2: Insert new version
            INSERT INTO dim.Customer_Type2 (
                CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
                CustomerSegment, EffectiveStartDate, EffectiveEndDate, IsCurrent, VersionNumber
            )
            VALUES (
                @CustomerID, @CustomerName, @Email, @Phone, @Address, @City, @State, @Country,
                @CustomerSegment, @EffectiveDate, '9999-12-31', 1, @CurrentVersion + 1
            );
            
            COMMIT TRANSACTION;
            
            PRINT 'Customer updated (Type 2 - New Version Created: ' + CAST(@CurrentVersion + 1 AS VARCHAR(10)) + ')';
        END
        ELSE
        BEGIN
            PRINT 'No changes detected - no update required';
        END
    END
    ELSE
    BEGIN
        -- Insert new customer
        INSERT INTO dim.Customer_Type2 (
            CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
            CustomerSegment, EffectiveStartDate
        )
        VALUES (
            @CustomerID, @CustomerName, @Email, @Phone, @Address, @City, @State, @Country,
            @CustomerSegment, @EffectiveDate
        );
        
        PRINT 'New customer inserted';
    END
END;
GO

-- ============================================================================
-- EXERCISE 2: SCD TYPE 2 IMPLEMENTATION
-- ============================================================================

/*
EXERCISE 2A: Track Address Change (Type 2)

Scenario: John Smith (CustomerID 1001) moved from New York to Boston.
New Address: '100 Harbor St', City: 'Boston', State: 'MA'
Effective Date: 2024-06-01

Task: 
1. Execute the update
2. Query to see all historical records for John Smith
*/

-- Your solution here:
-- EXEC dim.usp_UpdateCustomer_Type2 ...

-- View history
SELECT * FROM dim.Customer_Type2 WHERE CustomerID = 1001 ORDER BY VersionNumber;

/*
EXERCISE 2B: Point-in-Time Query

Create a query that retrieves customer data as it was on a specific date.
For example, get John Smith's address as of 2024-03-15.
*/

-- Your solution here:


/*
EXERCISE 2C: Create Type 2 Employee Dimension

Create an employee dimension with Type 2 tracking for:
- EmployeeID (business key)
- EmployeeName
- Department
- JobTitle
- Salary
- ManagerID

Include procedures for:
1. Insert new employee
2. Update existing employee (Type 2)
3. Point-in-time lookup
*/

-- Your solution here:


-- ============================================================================
-- SECTION 5: SCD TYPE 3 - PREVIOUS VALUE COLUMN
-- ============================================================================

/*
SCD Type 3: Keep current and previous value in separate columns.
- Limited history (usually just one previous value)
- Simple to query current vs previous
- Used when only recent history matters
*/

-- Create Type 3 Customer Dimension
CREATE TABLE dim.Customer_Type3 (
    CustomerKey             INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID              INT NOT NULL UNIQUE,
    CustomerName            NVARCHAR(100) NOT NULL,
    Email                   NVARCHAR(100),
    Phone                   NVARCHAR(20),
    
    -- Current values
    CurrentAddress          NVARCHAR(200),
    CurrentCity             NVARCHAR(50),
    CurrentState            NVARCHAR(50),
    CurrentCountry          NVARCHAR(50),
    CurrentSegment          NVARCHAR(50),
    
    -- Previous values (Type 3)
    PreviousAddress         NVARCHAR(200),
    PreviousCity            NVARCHAR(50),
    PreviousState           NVARCHAR(50),
    PreviousCountry         NVARCHAR(50),
    PreviousSegment         NVARCHAR(50),
    
    -- Tracking
    AddressChangeDate       DATE,
    SegmentChangeDate       DATE,
    
    CreatedDate             DATETIME2 DEFAULT GETDATE(),
    LastModifiedDate        DATETIME2 DEFAULT GETDATE()
);
GO

-- Insert initial data
INSERT INTO dim.Customer_Type3 (CustomerID, CustomerName, Email, Phone, CurrentAddress, CurrentCity, CurrentState, CurrentCountry, CurrentSegment)
VALUES 
    (1001, 'John Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', 'USA', 'Gold'),
    (1002, 'Jane Doe', 'jane.doe@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', 'USA', 'Silver');
GO

-- Create procedure for SCD Type 3 updates
CREATE OR ALTER PROCEDURE dim.usp_UpdateCustomer_Type3
    @CustomerID         INT,
    @CustomerName       NVARCHAR(100),
    @Email              NVARCHAR(100),
    @Phone              NVARCHAR(20),
    @Address            NVARCHAR(200),
    @City               NVARCHAR(50),
    @State              NVARCHAR(50),
    @Country            NVARCHAR(50),
    @CustomerSegment    NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM dim.Customer_Type3 WHERE CustomerID = @CustomerID)
    BEGIN
        UPDATE dim.Customer_Type3
        SET 
            -- Type 1: Simple overwrite
            CustomerName = @CustomerName,
            Email = @Email,
            Phone = @Phone,
            
            -- Type 3: Shift current to previous, then update current (Address)
            PreviousAddress = CASE WHEN CurrentAddress != @Address THEN CurrentAddress ELSE PreviousAddress END,
            PreviousCity = CASE WHEN CurrentCity != @City THEN CurrentCity ELSE PreviousCity END,
            PreviousState = CASE WHEN CurrentState != @State THEN CurrentState ELSE PreviousState END,
            PreviousCountry = CASE WHEN CurrentCountry != @Country THEN CurrentCountry ELSE PreviousCountry END,
            AddressChangeDate = CASE WHEN CurrentAddress != @Address THEN CAST(GETDATE() AS DATE) ELSE AddressChangeDate END,
            CurrentAddress = @Address,
            CurrentCity = @City,
            CurrentState = @State,
            CurrentCountry = @Country,
            
            -- Type 3: Shift current to previous (Segment)
            PreviousSegment = CASE WHEN CurrentSegment != @CustomerSegment THEN CurrentSegment ELSE PreviousSegment END,
            SegmentChangeDate = CASE WHEN CurrentSegment != @CustomerSegment THEN CAST(GETDATE() AS DATE) ELSE SegmentChangeDate END,
            CurrentSegment = @CustomerSegment,
            
            LastModifiedDate = GETDATE()
        WHERE CustomerID = @CustomerID;
        
        PRINT 'Customer updated (Type 3 - Previous values preserved)';
    END
    ELSE
    BEGIN
        INSERT INTO dim.Customer_Type3 (CustomerID, CustomerName, Email, Phone, CurrentAddress, CurrentCity, CurrentState, CurrentCountry, CurrentSegment)
        VALUES (@CustomerID, @CustomerName, @Email, @Phone, @Address, @City, @State, @Country, @CustomerSegment);
        
        PRINT 'New customer inserted';
    END
END;
GO

-- ============================================================================
-- EXERCISE 3: SCD TYPE 3 IMPLEMENTATION
-- ============================================================================

/*
EXERCISE 3A: Track Segment Change

Scenario: Jane Doe (CustomerID 1002) upgraded from Silver to Gold.

Task:
1. Execute the update
2. Write a query showing customers who recently upgraded their segment
*/

-- Your solution here:


/*
EXERCISE 3B: When to Use Type 3?

List 3 real-world scenarios where SCD Type 3 is the best choice.
Explain why Type 2 would be overkill for these scenarios.

Your answer:
1. 
2.
3.
*/


-- ============================================================================
-- SECTION 6: SCD TYPE 6 (HYBRID - 1+2+3)
-- ============================================================================

/*
SCD Type 6: Combines Types 1, 2, and 3
- Creates new rows for history (Type 2)
- Maintains current value column updated across all rows (Type 1)
- Keeps previous value for easy comparison (Type 3)
- Most flexible but most complex
*/

-- Create Type 6 Customer Dimension
CREATE TABLE dim.Customer_Type6 (
    CustomerKey             INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID              INT NOT NULL,
    CustomerName            NVARCHAR(100) NOT NULL,
    Email                   NVARCHAR(100),
    Phone                   NVARCHAR(20),
    
    -- Historical value (changes with each version)
    HistoricalAddress       NVARCHAR(200),
    HistoricalCity          NVARCHAR(50),
    HistoricalState         NVARCHAR(50),
    HistoricalSegment       NVARCHAR(50),
    
    -- Current value (Type 1 - updated on all rows)
    CurrentAddress          NVARCHAR(200),
    CurrentCity             NVARCHAR(50),
    CurrentState            NVARCHAR(50),
    CurrentSegment          NVARCHAR(50),
    
    -- Previous value (Type 3)
    PreviousAddress         NVARCHAR(200),
    PreviousCity            NVARCHAR(50),
    PreviousState           NVARCHAR(50),
    PreviousSegment         NVARCHAR(50),
    
    -- Type 2 tracking
    EffectiveStartDate      DATE NOT NULL,
    EffectiveEndDate        DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent               BIT NOT NULL DEFAULT 1,
    VersionNumber           INT NOT NULL DEFAULT 1,
    
    CreatedDate             DATETIME2 DEFAULT GETDATE()
);
GO

CREATE INDEX IX_Customer_Type6_BusinessKey ON dim.Customer_Type6(CustomerID, IsCurrent);
GO

-- Create procedure for SCD Type 6 updates
CREATE OR ALTER PROCEDURE dim.usp_UpdateCustomer_Type6
    @CustomerID         INT,
    @CustomerName       NVARCHAR(100),
    @Email              NVARCHAR(100),
    @Phone              NVARCHAR(20),
    @Address            NVARCHAR(200),
    @City               NVARCHAR(50),
    @State              NVARCHAR(50),
    @Segment            NVARCHAR(50),
    @EffectiveDate      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @EffectiveDate = ISNULL(@EffectiveDate, CAST(GETDATE() AS DATE));
    
    DECLARE @CurrentVersion INT;
    DECLARE @PreviousAddress NVARCHAR(200);
    DECLARE @PreviousCity NVARCHAR(50);
    DECLARE @PreviousState NVARCHAR(50);
    DECLARE @PreviousSegment NVARCHAR(50);
    
    IF EXISTS (SELECT 1 FROM dim.Customer_Type6 WHERE CustomerID = @CustomerID AND IsCurrent = 1)
    BEGIN
        -- Get current values for Type 3 tracking
        SELECT 
            @CurrentVersion = VersionNumber,
            @PreviousAddress = HistoricalAddress,
            @PreviousCity = HistoricalCity,
            @PreviousState = HistoricalState,
            @PreviousSegment = HistoricalSegment
        FROM dim.Customer_Type6
        WHERE CustomerID = @CustomerID AND IsCurrent = 1;
        
        BEGIN TRANSACTION;
        
        -- Type 1: Update current values on ALL rows for this customer
        UPDATE dim.Customer_Type6
        SET CurrentAddress = @Address,
            CurrentCity = @City,
            CurrentState = @State,
            CurrentSegment = @Segment
        WHERE CustomerID = @CustomerID;
        
        -- Type 2: Expire current row
        UPDATE dim.Customer_Type6
        SET EffectiveEndDate = DATEADD(DAY, -1, @EffectiveDate),
            IsCurrent = 0
        WHERE CustomerID = @CustomerID AND IsCurrent = 1;
        
        -- Type 2: Insert new version with Type 3 previous values
        INSERT INTO dim.Customer_Type6 (
            CustomerID, CustomerName, Email, Phone,
            HistoricalAddress, HistoricalCity, HistoricalState, HistoricalSegment,
            CurrentAddress, CurrentCity, CurrentState, CurrentSegment,
            PreviousAddress, PreviousCity, PreviousState, PreviousSegment,
            EffectiveStartDate, VersionNumber
        )
        VALUES (
            @CustomerID, @CustomerName, @Email, @Phone,
            @Address, @City, @State, @Segment,
            @Address, @City, @State, @Segment,
            @PreviousAddress, @PreviousCity, @PreviousState, @PreviousSegment,
            @EffectiveDate, @CurrentVersion + 1
        );
        
        COMMIT TRANSACTION;
        
        PRINT 'Customer updated (Type 6 - Hybrid Update)';
    END
    ELSE
    BEGIN
        INSERT INTO dim.Customer_Type6 (
            CustomerID, CustomerName, Email, Phone,
            HistoricalAddress, HistoricalCity, HistoricalState, HistoricalSegment,
            CurrentAddress, CurrentCity, CurrentState, CurrentSegment,
            EffectiveStartDate
        )
        VALUES (
            @CustomerID, @CustomerName, @Email, @Phone,
            @Address, @City, @State, @Segment,
            @Address, @City, @State, @Segment,
            @EffectiveDate
        );
        
        PRINT 'New customer inserted';
    END
END;
GO

-- ============================================================================
-- SECTION 7: MERGE STATEMENT FOR SCD PROCESSING
-- ============================================================================

/*
The MERGE statement is ideal for SCD processing as it handles
INSERT, UPDATE, and DELETE in a single atomic operation.
*/

-- Create staging table for incoming customer data
CREATE TABLE staging.CustomerUpdates (
    CustomerID          INT PRIMARY KEY,
    CustomerName        NVARCHAR(100),
    Email               NVARCHAR(100),
    Phone               NVARCHAR(20),
    Address             NVARCHAR(200),
    City                NVARCHAR(50),
    State               NVARCHAR(50),
    Country             NVARCHAR(50),
    CustomerSegment     NVARCHAR(50),
    LoadDate            DATETIME2 DEFAULT GETDATE()
);
GO

-- SCD Type 2 using MERGE
CREATE OR ALTER PROCEDURE dim.usp_MergeCustomers_Type2
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    
    BEGIN TRANSACTION;
    
    -- Step 1: Update changed records (expire them)
    UPDATE dim.Customer_Type2
    SET EffectiveEndDate = DATEADD(DAY, -1, @Today),
        IsCurrent = 0,
        LastModifiedDate = GETDATE()
    FROM dim.Customer_Type2 d
    INNER JOIN staging.CustomerUpdates s ON d.CustomerID = s.CustomerID
    WHERE d.IsCurrent = 1
    AND (
        d.CustomerName != s.CustomerName OR
        ISNULL(d.Address, '') != ISNULL(s.Address, '') OR
        ISNULL(d.City, '') != ISNULL(s.City, '') OR
        ISNULL(d.State, '') != ISNULL(s.State, '') OR
        ISNULL(d.CustomerSegment, '') != ISNULL(s.CustomerSegment, '')
    );
    
    -- Step 2: Insert new versions for changed records
    INSERT INTO dim.Customer_Type2 (
        CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
        CustomerSegment, EffectiveStartDate, VersionNumber
    )
    SELECT 
        s.CustomerID, s.CustomerName, s.Email, s.Phone, s.Address, s.City, s.State, s.Country,
        s.CustomerSegment, @Today, ISNULL(d.VersionNumber, 0) + 1
    FROM staging.CustomerUpdates s
    LEFT JOIN dim.Customer_Type2 d ON s.CustomerID = d.CustomerID AND d.IsCurrent = 0 
        AND d.EffectiveEndDate = DATEADD(DAY, -1, @Today)
    WHERE NOT EXISTS (
        SELECT 1 FROM dim.Customer_Type2 x 
        WHERE x.CustomerID = s.CustomerID AND x.IsCurrent = 1
    );
    
    -- Step 3: Insert brand new customers
    INSERT INTO dim.Customer_Type2 (
        CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
        CustomerSegment, EffectiveStartDate
    )
    SELECT 
        s.CustomerID, s.CustomerName, s.Email, s.Phone, s.Address, s.City, s.State, s.Country,
        s.CustomerSegment, @Today
    FROM staging.CustomerUpdates s
    WHERE NOT EXISTS (
        SELECT 1 FROM dim.Customer_Type2 d WHERE d.CustomerID = s.CustomerID
    );
    
    COMMIT TRANSACTION;
    
    -- Report results
    SELECT 
        'SCD Type 2 Merge Complete' AS Status,
        (SELECT COUNT(*) FROM dim.Customer_Type2 WHERE IsCurrent = 1) AS CurrentRecords,
        (SELECT COUNT(*) FROM dim.Customer_Type2 WHERE IsCurrent = 0) AS HistoricalRecords;
END;
GO

-- ============================================================================
-- EXERCISE 4: MERGE-BASED SCD PROCESSING
-- ============================================================================

/*
EXERCISE 4A: Process Customer Updates

1. Insert test data into staging.CustomerUpdates:
   - CustomerID 1001: Changed address to '500 New St', Boston, MA
   - CustomerID 1004: New customer 'Alice Brown', '999 First Ave', Seattle, WA, 'Platinum'

2. Execute the merge procedure
3. Verify the results in dim.Customer_Type2
*/

-- Your solution here:


/*
EXERCISE 4B: Create MERGE for SCD Type 1

Create a stored procedure that uses MERGE to process Type 1 updates
for the dim.Customer_Type1 table.
*/

-- Your solution here:


-- ============================================================================
-- SECTION 8: SCD COMPARISON AND BEST PRACTICES
-- ============================================================================

/*
CHOOSING THE RIGHT SCD TYPE:

┌─────────────────────────────────────────────────────────────────────────────┐
│ Consideration          │ Type 1 │ Type 2 │ Type 3 │ Type 6              │
├─────────────────────────────────────────────────────────────────────────────┤
│ History Needed?        │ No     │ Full   │ Limited│ Full + Easy Access  │
│ Storage Cost           │ Low    │ High   │ Medium │ Highest             │
│ Query Complexity       │ Simple │ Medium │ Simple │ Complex             │
│ ETL Complexity         │ Simple │ Medium │ Simple │ Complex             │
│ Point-in-Time Analysis │ No     │ Yes    │ Partial│ Yes                 │
│ Current Value Access   │ Direct │ Filter │ Direct │ Direct              │
└─────────────────────────────────────────────────────────────────────────────┘

BEST PRACTICES:

1. Use consistent surrogate keys across the data warehouse
2. Always use date ranges (not datetime) for effective dates
3. Use '9999-12-31' as the end date for current records
4. Include both IsCurrent flag AND date range for flexibility
5. Add version numbers for easier debugging
6. Consider using hash columns to detect changes efficiently
7. Partition large dimension tables by IsCurrent flag
8. Index on (BusinessKey, IsCurrent) for common queries
*/

-- ============================================================================
-- EXERCISE 5: COMPREHENSIVE SCD DESIGN
-- ============================================================================

/*
EXERCISE 5: Design a Product Dimension with Mixed SCD Types

Create a product dimension that uses:
- Type 0 (Fixed): ProductID, ProductCreatedDate
- Type 1 (Overwrite): ListPrice, DiscountPercent, IsActive
- Type 2 (History): Category, Subcategory, Supplier
- Type 3 (Previous): UnitCost

Requirements:
1. Create the dimension table with all necessary columns
2. Create a stored procedure to handle updates
3. Create a view that simplifies querying current records
4. Demonstrate with sample data and updates
*/

-- Your solution here:


-- ============================================================================
-- LAB SOLUTIONS
-- ============================================================================

/*
═══════════════════════════════════════════════════════════════════════════════
                              SOLUTIONS
═══════════════════════════════════════════════════════════════════════════════
*/

-- SOLUTION 1A: Update customer phone number (Type 1)
EXEC dim.usp_UpdateCustomer_Type1 
    @CustomerID = 1001,
    @CustomerName = 'John Smith',
    @Email = 'john.smith@email.com',
    @Phone = '555-9999',  -- Changed
    @Address = '123 Main St',
    @City = 'New York',
    @State = 'NY',
    @Country = 'USA',
    @CustomerSegment = 'Gold';

-- SOLUTION 2A: Track Address Change (Type 2)
EXEC dim.usp_UpdateCustomer_Type2
    @CustomerID = 1001,
    @CustomerName = 'John Smith',
    @Email = 'john.smith@email.com',
    @Phone = '555-0101',
    @Address = '100 Harbor St',
    @City = 'Boston',
    @State = 'MA',
    @Country = 'USA',
    @CustomerSegment = 'Gold',
    @EffectiveDate = '2024-06-01';

-- View history
SELECT CustomerKey, CustomerID, CustomerName, Address, City, State,
       EffectiveStartDate, EffectiveEndDate, IsCurrent, VersionNumber
FROM dim.Customer_Type2
WHERE CustomerID = 1001
ORDER BY VersionNumber;

-- SOLUTION 2B: Point-in-Time Query
DECLARE @AsOfDate DATE = '2024-03-15';

SELECT *
FROM dim.Customer_Type2
WHERE CustomerID = 1001
  AND @AsOfDate >= EffectiveStartDate
  AND @AsOfDate <= EffectiveEndDate;

-- SOLUTION 3A: Type 3 Segment Change
EXEC dim.usp_UpdateCustomer_Type3
    @CustomerID = 1002,
    @CustomerName = 'Jane Doe',
    @Email = 'jane.doe@email.com',
    @Phone = '555-0102',
    @Address = '456 Oak Ave',
    @City = 'Los Angeles',
    @State = 'CA',
    @Country = 'USA',
    @CustomerSegment = 'Gold';

-- Query customers who upgraded
SELECT CustomerID, CustomerName,
       PreviousSegment AS 'Previous', 
       CurrentSegment AS 'Current',
       SegmentChangeDate
FROM dim.Customer_Type3
WHERE PreviousSegment IS NOT NULL
  AND CurrentSegment != PreviousSegment;

-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
/*
-- Drop all created objects
DROP PROCEDURE IF EXISTS dim.usp_UpdateCustomer_Type1;
DROP PROCEDURE IF EXISTS dim.usp_UpdateCustomer_Type2;
DROP PROCEDURE IF EXISTS dim.usp_UpdateCustomer_Type3;
DROP PROCEDURE IF EXISTS dim.usp_UpdateCustomer_Type6;
DROP PROCEDURE IF EXISTS dim.usp_MergeCustomers_Type2;

DROP TABLE IF EXISTS dim.Customer_Type1;
DROP TABLE IF EXISTS dim.Customer_Type2;
DROP TABLE IF EXISTS dim.Customer_Type3;
DROP TABLE IF EXISTS dim.Customer_Type6;
DROP TABLE IF EXISTS staging.CustomerUpdates;

DROP SCHEMA IF EXISTS dim;
*/

PRINT 'Lab 62: Slowly Changing Dimensions - Complete';
GO
