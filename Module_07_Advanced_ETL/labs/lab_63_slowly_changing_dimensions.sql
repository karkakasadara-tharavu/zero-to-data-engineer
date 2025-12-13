/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  MODULE 07: ADVANCED ETL PATTERNS                                            ║
║  LAB 63: SLOWLY CHANGING DIMENSIONS (SCD) - COMPREHENSIVE                   ║
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

USE DataEngineerTraining;
GO

-- Create schema for dimension tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim')
    EXEC('CREATE SCHEMA dim');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

-- ============================================================================
-- SECTION 2: SCD TYPE 0 - FIXED/PASSIVE ATTRIBUTES
-- ============================================================================

/*
SCD Type 0: Values that never change after initial load.
Examples: Original join date, birth date, original customer ID
*/

-- Create Type 0 example table
CREATE TABLE dim.Customer_Type0 (
    CustomerKey             INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID              INT NOT NULL UNIQUE,          -- Business Key
    CustomerName            NVARCHAR(100) NOT NULL,
    Email                   NVARCHAR(100),
    
    -- Type 0: Fixed attributes (never updated)
    OriginalSignupDate      DATE NOT NULL,                -- Fixed forever
    OriginalSourceSystem    NVARCHAR(50),                 -- Fixed forever
    DateOfBirth             DATE,                         -- Fixed forever
    
    -- Type 1: Overwritable attributes
    Phone                   NVARCHAR(20),
    CurrentAddress          NVARCHAR(200),
    
    CreatedDate             DATETIME2 DEFAULT GETDATE()
);
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
DROP TABLE IF EXISTS dim.Customer_Type1;
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
CREATE OR ALTER PROCEDURE dim.usp_ProcessCustomer_Type1
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
        
        SELECT 'UPDATE' AS OperationType, @@ROWCOUNT AS RowsAffected;
    END
    ELSE
    BEGIN
        -- Insert new customer
        INSERT INTO dim.Customer_Type1 (CustomerID, CustomerName, Email, Phone, Address, City, State, Country, CustomerSegment)
        VALUES (@CustomerID, @CustomerName, @Email, @Phone, @Address, @City, @State, @Country, @CustomerSegment);
        
        SELECT 'INSERT' AS OperationType, @@ROWCOUNT AS RowsAffected;
    END
END;
GO

-- Demonstrate Type 1 update
PRINT 'Before Type 1 Update:';
SELECT CustomerID, Phone, Address, LastModifiedDate FROM dim.Customer_Type1 WHERE CustomerID = 1001;

EXEC dim.usp_ProcessCustomer_Type1
    @CustomerID = 1001,
    @CustomerName = 'John Smith',
    @Email = 'john.smith@email.com',
    @Phone = '555-9999',          -- Changed!
    @Address = '123 Main St',
    @City = 'New York',
    @State = 'NY',
    @Country = 'USA',
    @CustomerSegment = 'Gold';

PRINT 'After Type 1 Update:';
SELECT CustomerID, Phone, Address, LastModifiedDate FROM dim.Customer_Type1 WHERE CustomerID = 1001;
GO

-- ============================================================================
-- SECTION 4: SCD TYPE 2 - HISTORICAL TRACKING
-- ============================================================================

/*
SCD Type 2: Create a new row for each change, preserving history.
- Full history is maintained
- Requires surrogate key, effective dates, and current flag
- Most common approach for critical attributes

Key columns for Type 2:
- Surrogate Key (CustomerKey)
- Business Key (CustomerID)
- Effective Start Date
- Effective End Date (9999-12-31 for current)
- IsCurrent flag (1 or 0)
- Version Number (optional but useful)
*/

-- Create Type 2 Customer Dimension
DROP TABLE IF EXISTS dim.Customer_Type2;
CREATE TABLE dim.Customer_Type2 (
    CustomerKey         INT IDENTITY(1,1) PRIMARY KEY,    -- Surrogate Key
    CustomerID          INT NOT NULL,                      -- Business Key (not unique!)
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
    
    -- Hash for change detection
    RowHash             VARBINARY(32),
    
    -- Audit columns
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    LastModifiedDate    DATETIME2 DEFAULT GETDATE()
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_Customer_Type2_BusinessKey 
    ON dim.Customer_Type2(CustomerID, IsCurrent);
    
CREATE NONCLUSTERED INDEX IX_Customer_Type2_Current 
    ON dim.Customer_Type2(IsCurrent) 
    INCLUDE (CustomerID, CustomerName, Address, City, State);
    
CREATE NONCLUSTERED INDEX IX_Customer_Type2_EffectiveDates 
    ON dim.Customer_Type2(CustomerID, EffectiveStartDate, EffectiveEndDate);
GO

-- Insert initial data with hash
INSERT INTO dim.Customer_Type2 (
    CustomerID, CustomerName, Email, Phone, Address, City, State, Country, 
    CustomerSegment, EffectiveStartDate, RowHash
)
SELECT 
    1001, 'John Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', 'USA', 'Gold',
    '2024-01-01',
    HASHBYTES('SHA2_256', CONCAT('John Smith', '|', 'john.smith@email.com', '|', '123 Main St', '|', 'New York', '|', 'NY', '|', 'Gold'))
UNION ALL SELECT 
    1002, 'Jane Doe', 'jane.doe@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', 'USA', 'Silver',
    '2024-01-01',
    HASHBYTES('SHA2_256', CONCAT('Jane Doe', '|', 'jane.doe@email.com', '|', '456 Oak Ave', '|', 'Los Angeles', '|', 'CA', '|', 'Silver'))
UNION ALL SELECT 
    1003, 'Bob Johnson', 'bob.j@email.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', 'USA', 'Bronze',
    '2024-01-01',
    HASHBYTES('SHA2_256', CONCAT('Bob Johnson', '|', 'bob.j@email.com', '|', '789 Pine Rd', '|', 'Chicago', '|', 'IL', '|', 'Bronze'));
GO

-- Create comprehensive procedure for SCD Type 2 updates
CREATE OR ALTER PROCEDURE dim.usp_ProcessCustomer_Type2
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
    SET @EffectiveDate = ISNULL(@EffectiveDate, CAST(GETDATE() AS DATE));
    
    DECLARE @CurrentVersion INT;
    DECLARE @NewHash VARBINARY(32);
    DECLARE @CurrentHash VARBINARY(32);
    
    -- Calculate hash for incoming record
    SET @NewHash = HASHBYTES('SHA2_256', 
        CONCAT(@CustomerName, '|', @Email, '|', @Address, '|', @City, '|', @State, '|', @CustomerSegment));
    
    -- Check if customer exists and get current hash
    SELECT @CurrentVersion = VersionNumber, @CurrentHash = RowHash
    FROM dim.Customer_Type2
    WHERE CustomerID = @CustomerID AND IsCurrent = 1;
    
    IF @CurrentVersion IS NOT NULL
    BEGIN
        -- Customer exists - check if there are actual changes
        IF @CurrentHash != @NewHash
        BEGIN
            BEGIN TRANSACTION;
            
            BEGIN TRY
                -- Step 1: Expire the current record
                UPDATE dim.Customer_Type2
                SET EffectiveEndDate = DATEADD(DAY, -1, @EffectiveDate),
                    IsCurrent = 0,
                    LastModifiedDate = GETDATE()
                WHERE CustomerID = @CustomerID AND IsCurrent = 1;
                
                -- Step 2: Insert new version
                INSERT INTO dim.Customer_Type2 (
                    CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
                    CustomerSegment, EffectiveStartDate, EffectiveEndDate, IsCurrent, 
                    VersionNumber, RowHash
                )
                VALUES (
                    @CustomerID, @CustomerName, @Email, @Phone, @Address, @City, @State, @Country,
                    @CustomerSegment, @EffectiveDate, '9999-12-31', 1, 
                    @CurrentVersion + 1, @NewHash
                );
                
                COMMIT TRANSACTION;
                
                SELECT 'TYPE2_UPDATE' AS OperationType, 
                       @CurrentVersion + 1 AS NewVersion,
                       'New version created' AS Message;
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION;
                THROW;
            END CATCH
        END
        ELSE
        BEGIN
            SELECT 'NO_CHANGE' AS OperationType, 
                   @CurrentVersion AS CurrentVersion,
                   'No changes detected - hash match' AS Message;
        END
    END
    ELSE
    BEGIN
        -- New customer
        INSERT INTO dim.Customer_Type2 (
            CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
            CustomerSegment, EffectiveStartDate, RowHash
        )
        VALUES (
            @CustomerID, @CustomerName, @Email, @Phone, @Address, @City, @State, @Country,
            @CustomerSegment, @EffectiveDate, @NewHash
        );
        
        SELECT 'INSERT' AS OperationType, 
               1 AS NewVersion,
               'New customer created' AS Message;
    END
END;
GO

-- Demonstrate Type 2 updates
PRINT '========== SCD Type 2 Demonstration ==========';

-- Show initial state
PRINT 'Initial state for CustomerID 1001:';
SELECT CustomerKey, CustomerID, CustomerName, Address, City, State, 
       EffectiveStartDate, EffectiveEndDate, IsCurrent, VersionNumber
FROM dim.Customer_Type2 WHERE CustomerID = 1001;

-- Update 1: John Smith moves to Boston
EXEC dim.usp_ProcessCustomer_Type2
    @CustomerID = 1001,
    @CustomerName = 'John Smith',
    @Email = 'john.smith@email.com',
    @Phone = '555-0101',
    @Address = '100 Harbor St',     -- Changed!
    @City = 'Boston',               -- Changed!
    @State = 'MA',                  -- Changed!
    @Country = 'USA',
    @CustomerSegment = 'Gold',
    @EffectiveDate = '2024-06-01';

-- Show after first update
PRINT 'After move to Boston:';
SELECT CustomerKey, CustomerID, CustomerName, Address, City, State, 
       EffectiveStartDate, EffectiveEndDate, IsCurrent, VersionNumber
FROM dim.Customer_Type2 WHERE CustomerID = 1001 ORDER BY VersionNumber;

-- Update 2: John Smith gets upgraded to Platinum
EXEC dim.usp_ProcessCustomer_Type2
    @CustomerID = 1001,
    @CustomerName = 'John Smith',
    @Email = 'john.smith@email.com',
    @Phone = '555-0101',
    @Address = '100 Harbor St',
    @City = 'Boston',
    @State = 'MA',
    @Country = 'USA',
    @CustomerSegment = 'Platinum',  -- Changed!
    @EffectiveDate = '2024-09-01';

-- Show complete history
PRINT 'Complete history for CustomerID 1001:';
SELECT CustomerKey, CustomerID, CustomerName, Address, City, State, CustomerSegment,
       EffectiveStartDate, EffectiveEndDate, IsCurrent, VersionNumber
FROM dim.Customer_Type2 WHERE CustomerID = 1001 ORDER BY VersionNumber;
GO

-- ============================================================================
-- SECTION 5: POINT-IN-TIME QUERIES FOR TYPE 2
-- ============================================================================

-- Create function for point-in-time lookup
CREATE OR ALTER FUNCTION dim.fn_GetCustomerAsOf (
    @CustomerID INT,
    @AsOfDate DATE
)
RETURNS TABLE
AS
RETURN (
    SELECT CustomerKey, CustomerID, CustomerName, Email, Phone,
           Address, City, State, Country, CustomerSegment,
           EffectiveStartDate, EffectiveEndDate, VersionNumber
    FROM dim.Customer_Type2
    WHERE CustomerID = @CustomerID
      AND @AsOfDate >= EffectiveStartDate
      AND @AsOfDate <= EffectiveEndDate
);
GO

-- Create view for current records only
CREATE OR ALTER VIEW dim.vw_Customer_Current
AS
SELECT CustomerKey, CustomerID, CustomerName, Email, Phone,
       Address, City, State, Country, CustomerSegment,
       EffectiveStartDate, VersionNumber
FROM dim.Customer_Type2
WHERE IsCurrent = 1;
GO

-- Demonstrate point-in-time queries
PRINT '========== Point-in-Time Queries ==========';

PRINT 'Customer 1001 as of 2024-03-15 (before move):';
SELECT * FROM dim.fn_GetCustomerAsOf(1001, '2024-03-15');

PRINT 'Customer 1001 as of 2024-07-15 (after Boston move, before upgrade):';
SELECT * FROM dim.fn_GetCustomerAsOf(1001, '2024-07-15');

PRINT 'Customer 1001 as of today (current):';
SELECT * FROM dim.fn_GetCustomerAsOf(1001, CAST(GETDATE() AS DATE));
GO

-- ============================================================================
-- SECTION 6: SCD TYPE 3 - PREVIOUS VALUE COLUMN
-- ============================================================================

/*
SCD Type 3: Keep current and previous value in separate columns.
- Limited history (usually just one previous value)
- Simple to query current vs previous
- Used when only recent history matters
*/

DROP TABLE IF EXISTS dim.Customer_Type3;
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
    CurrentSegment          NVARCHAR(50),
    
    -- Previous values (Type 3)
    PreviousAddress         NVARCHAR(200),
    PreviousCity            NVARCHAR(50),
    PreviousState           NVARCHAR(50),
    PreviousSegment         NVARCHAR(50),
    
    -- Change tracking dates
    AddressChangeDate       DATE,
    SegmentChangeDate       DATE,
    
    CreatedDate             DATETIME2 DEFAULT GETDATE(),
    LastModifiedDate        DATETIME2 DEFAULT GETDATE()
);
GO

-- Insert initial data
INSERT INTO dim.Customer_Type3 (CustomerID, CustomerName, Email, Phone, 
    CurrentAddress, CurrentCity, CurrentState, CurrentSegment)
VALUES 
    (1001, 'John Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', 'Gold'),
    (1002, 'Jane Doe', 'jane.doe@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', 'Silver');
GO

-- Create procedure for SCD Type 3 updates
CREATE OR ALTER PROCEDURE dim.usp_ProcessCustomer_Type3
    @CustomerID         INT,
    @CustomerName       NVARCHAR(100),
    @Email              NVARCHAR(100),
    @Phone              NVARCHAR(20),
    @Address            NVARCHAR(200),
    @City               NVARCHAR(50),
    @State              NVARCHAR(50),
    @CustomerSegment    NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AddressChanged BIT = 0;
    DECLARE @SegmentChanged BIT = 0;
    
    IF EXISTS (SELECT 1 FROM dim.Customer_Type3 WHERE CustomerID = @CustomerID)
    BEGIN
        -- Check what changed
        SELECT 
            @AddressChanged = CASE WHEN CurrentAddress != @Address OR CurrentCity != @City OR CurrentState != @State THEN 1 ELSE 0 END,
            @SegmentChanged = CASE WHEN CurrentSegment != @CustomerSegment THEN 1 ELSE 0 END
        FROM dim.Customer_Type3
        WHERE CustomerID = @CustomerID;
        
        UPDATE dim.Customer_Type3
        SET 
            -- Type 1: Simple overwrite for non-tracked attributes
            CustomerName = @CustomerName,
            Email = @Email,
            Phone = @Phone,
            
            -- Type 3: Shift current to previous ONLY if changed (Address)
            PreviousAddress = CASE WHEN @AddressChanged = 1 THEN CurrentAddress ELSE PreviousAddress END,
            PreviousCity = CASE WHEN @AddressChanged = 1 THEN CurrentCity ELSE PreviousCity END,
            PreviousState = CASE WHEN @AddressChanged = 1 THEN CurrentState ELSE PreviousState END,
            AddressChangeDate = CASE WHEN @AddressChanged = 1 THEN CAST(GETDATE() AS DATE) ELSE AddressChangeDate END,
            CurrentAddress = @Address,
            CurrentCity = @City,
            CurrentState = @State,
            
            -- Type 3: Shift current to previous (Segment)
            PreviousSegment = CASE WHEN @SegmentChanged = 1 THEN CurrentSegment ELSE PreviousSegment END,
            SegmentChangeDate = CASE WHEN @SegmentChanged = 1 THEN CAST(GETDATE() AS DATE) ELSE SegmentChangeDate END,
            CurrentSegment = @CustomerSegment,
            
            LastModifiedDate = GETDATE()
        WHERE CustomerID = @CustomerID;
        
        SELECT 'UPDATE' AS OperationType,
               @AddressChanged AS AddressChanged,
               @SegmentChanged AS SegmentChanged;
    END
    ELSE
    BEGIN
        INSERT INTO dim.Customer_Type3 (CustomerID, CustomerName, Email, Phone, 
            CurrentAddress, CurrentCity, CurrentState, CurrentSegment)
        VALUES (@CustomerID, @CustomerName, @Email, @Phone, 
            @Address, @City, @State, @CustomerSegment);
        
        SELECT 'INSERT' AS OperationType, 0 AS AddressChanged, 0 AS SegmentChanged;
    END
END;
GO

-- Demonstrate Type 3
PRINT '========== SCD Type 3 Demonstration ==========';

PRINT 'Initial state:';
SELECT CustomerID, CurrentAddress, CurrentCity, CurrentState, CurrentSegment,
       PreviousAddress, PreviousCity, PreviousState, PreviousSegment
FROM dim.Customer_Type3 WHERE CustomerID = 1001;

-- Update: Jane Doe upgrades from Silver to Gold
EXEC dim.usp_ProcessCustomer_Type3
    @CustomerID = 1002,
    @CustomerName = 'Jane Doe',
    @Email = 'jane.doe@email.com',
    @Phone = '555-0102',
    @Address = '456 Oak Ave',
    @City = 'Los Angeles',
    @State = 'CA',
    @CustomerSegment = 'Gold';  -- Upgraded!

PRINT 'After segment upgrade:';
SELECT CustomerID, CustomerName, 
       CurrentSegment, PreviousSegment, SegmentChangeDate
FROM dim.Customer_Type3 WHERE CustomerID = 1002;
GO

-- ============================================================================
-- SECTION 7: SCD TYPE 4 - MINI-DIMENSION
-- ============================================================================

/*
SCD Type 4: Move rapidly changing attributes to a separate "mini-dimension"
- Reduces bloat in the main dimension
- Useful for attributes that change very frequently
- Main dimension keeps stable attributes
*/

-- Main dimension with stable attributes
DROP TABLE IF EXISTS dim.Customer_Main;
CREATE TABLE dim.Customer_Main (
    CustomerKey         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID          INT NOT NULL UNIQUE,
    CustomerName        NVARCHAR(100) NOT NULL,
    Email               NVARCHAR(100),
    DateOfBirth         DATE,
    Gender              CHAR(1),
    JoinDate            DATE,
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- Mini-dimension for rapidly changing attributes
DROP TABLE IF EXISTS dim.CustomerProfile_Mini;
CREATE TABLE dim.CustomerProfile_Mini (
    ProfileKey              INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Banded/Categorized values (not raw values)
    CreditScoreBand         NVARCHAR(20),       -- 'Excellent', 'Good', 'Fair', 'Poor'
    IncomeLevel             NVARCHAR(20),       -- 'High', 'Medium', 'Low'
    LoyaltyTier             NVARCHAR(20),       -- 'Platinum', 'Gold', 'Silver', 'Bronze'
    PurchaseFrequency       NVARCHAR(20),       -- 'High', 'Medium', 'Low'
    
    -- This is a junk/mini dimension - finite combinations
    CONSTRAINT UK_CustomerProfile UNIQUE (CreditScoreBand, IncomeLevel, LoyaltyTier, PurchaseFrequency)
);
GO

-- Fact table references both dimensions
DROP TABLE IF EXISTS fact.CustomerTransaction;
CREATE TABLE fact.CustomerTransaction (
    TransactionKey      INT IDENTITY(1,1) PRIMARY KEY,
    CustomerKey         INT NOT NULL,           -- FK to main dimension
    ProfileKey          INT NOT NULL,           -- FK to mini-dimension
    TransactionDate     DATE NOT NULL,
    Amount              DECIMAL(12,2),
    CONSTRAINT FK_Transaction_Customer FOREIGN KEY (CustomerKey) 
        REFERENCES dim.Customer_Main(CustomerKey),
    CONSTRAINT FK_Transaction_Profile FOREIGN KEY (ProfileKey) 
        REFERENCES dim.CustomerProfile_Mini(ProfileKey)
);
GO

-- Pre-populate mini-dimension with all combinations
INSERT INTO dim.CustomerProfile_Mini (CreditScoreBand, IncomeLevel, LoyaltyTier, PurchaseFrequency)
SELECT 
    cs.CreditScoreBand,
    il.IncomeLevel,
    lt.LoyaltyTier,
    pf.PurchaseFrequency
FROM (VALUES ('Excellent'), ('Good'), ('Fair'), ('Poor')) AS cs(CreditScoreBand)
CROSS JOIN (VALUES ('High'), ('Medium'), ('Low')) AS il(IncomeLevel)
CROSS JOIN (VALUES ('Platinum'), ('Gold'), ('Silver'), ('Bronze')) AS lt(LoyaltyTier)
CROSS JOIN (VALUES ('High'), ('Medium'), ('Low')) AS pf(PurchaseFrequency);

SELECT 'Mini-dimension contains', COUNT(*), 'combinations' FROM dim.CustomerProfile_Mini;
GO

-- ============================================================================
-- SECTION 8: SCD TYPE 6 (HYBRID 1+2+3)
-- ============================================================================

/*
SCD Type 6: Combines Types 1, 2, and 3
- Creates new rows for history (Type 2)
- Maintains current value column updated across all rows (Type 1)
- Keeps previous value for easy comparison (Type 3)
- Most flexible but most complex
*/

DROP TABLE IF EXISTS dim.Customer_Type6;
CREATE TABLE dim.Customer_Type6 (
    CustomerKey             INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID              INT NOT NULL,
    CustomerName            NVARCHAR(100) NOT NULL,
    Email                   NVARCHAR(100),
    
    -- Historical value (Type 2 - point in time value)
    HistoricalSegment       NVARCHAR(50),
    HistoricalAddress       NVARCHAR(200),
    
    -- Current value (Type 1 - updated on ALL rows)
    CurrentSegment          NVARCHAR(50),
    CurrentAddress          NVARCHAR(200),
    
    -- Previous value (Type 3 - one-step history)
    PreviousSegment         NVARCHAR(50),
    PreviousAddress         NVARCHAR(200),
    
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

-- Insert initial data
INSERT INTO dim.Customer_Type6 (
    CustomerID, CustomerName, Email,
    HistoricalSegment, HistoricalAddress,
    CurrentSegment, CurrentAddress,
    EffectiveStartDate
)
VALUES 
    (1001, 'John Smith', 'john@email.com', 'Gold', '123 Main St', 'Gold', '123 Main St', '2024-01-01');
GO

-- Create procedure for Type 6 updates
CREATE OR ALTER PROCEDURE dim.usp_ProcessCustomer_Type6
    @CustomerID         INT,
    @CustomerName       NVARCHAR(100),
    @Email              NVARCHAR(100),
    @Segment            NVARCHAR(50),
    @Address            NVARCHAR(200),
    @EffectiveDate      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @EffectiveDate = ISNULL(@EffectiveDate, CAST(GETDATE() AS DATE));
    
    DECLARE @CurrentVersion INT;
    DECLARE @PrevSegment NVARCHAR(50);
    DECLARE @PrevAddress NVARCHAR(200);
    
    IF EXISTS (SELECT 1 FROM dim.Customer_Type6 WHERE CustomerID = @CustomerID AND IsCurrent = 1)
    BEGIN
        -- Get current values for Type 3 tracking
        SELECT 
            @CurrentVersion = VersionNumber,
            @PrevSegment = HistoricalSegment,
            @PrevAddress = HistoricalAddress
        FROM dim.Customer_Type6
        WHERE CustomerID = @CustomerID AND IsCurrent = 1;
        
        BEGIN TRANSACTION;
        
        -- Type 1: Update current values on ALL rows for this customer
        UPDATE dim.Customer_Type6
        SET CurrentSegment = @Segment,
            CurrentAddress = @Address
        WHERE CustomerID = @CustomerID;
        
        -- Type 2: Expire current row
        UPDATE dim.Customer_Type6
        SET EffectiveEndDate = DATEADD(DAY, -1, @EffectiveDate),
            IsCurrent = 0
        WHERE CustomerID = @CustomerID AND IsCurrent = 1;
        
        -- Type 2 + Type 3: Insert new version
        INSERT INTO dim.Customer_Type6 (
            CustomerID, CustomerName, Email,
            HistoricalSegment, HistoricalAddress,
            CurrentSegment, CurrentAddress,
            PreviousSegment, PreviousAddress,
            EffectiveStartDate, VersionNumber
        )
        VALUES (
            @CustomerID, @CustomerName, @Email,
            @Segment, @Address,                      -- Historical = this version's value
            @Segment, @Address,                      -- Current = latest value
            @PrevSegment, @PrevAddress,              -- Previous = what was current before
            @EffectiveDate, @CurrentVersion + 1
        );
        
        COMMIT TRANSACTION;
        
        SELECT 'TYPE6_UPDATE' AS OperationType, @CurrentVersion + 1 AS NewVersion;
    END
    ELSE
    BEGIN
        -- New customer
        INSERT INTO dim.Customer_Type6 (
            CustomerID, CustomerName, Email,
            HistoricalSegment, HistoricalAddress,
            CurrentSegment, CurrentAddress,
            EffectiveStartDate
        )
        VALUES (
            @CustomerID, @CustomerName, @Email,
            @Segment, @Address,
            @Segment, @Address,
            @EffectiveDate
        );
        
        SELECT 'INSERT' AS OperationType, 1 AS NewVersion;
    END
END;
GO

-- Demonstrate Type 6
PRINT '========== SCD Type 6 Demonstration ==========';

-- First update: Change address
EXEC dim.usp_ProcessCustomer_Type6 
    @CustomerID = 1001, 
    @CustomerName = 'John Smith', 
    @Email = 'john@email.com',
    @Segment = 'Gold', 
    @Address = '200 Harbor St',
    @EffectiveDate = '2024-06-01';

-- Second update: Change segment
EXEC dim.usp_ProcessCustomer_Type6 
    @CustomerID = 1001, 
    @CustomerName = 'John Smith', 
    @Email = 'john@email.com',
    @Segment = 'Platinum', 
    @Address = '200 Harbor St',
    @EffectiveDate = '2024-09-01';

-- View results - notice Current columns are same across all rows
SELECT VersionNumber, 
       HistoricalSegment, HistoricalAddress,
       CurrentSegment, CurrentAddress,
       PreviousSegment, PreviousAddress,
       EffectiveStartDate, EffectiveEndDate, IsCurrent
FROM dim.Customer_Type6
WHERE CustomerID = 1001
ORDER BY VersionNumber;
GO

-- ============================================================================
-- SECTION 9: BULK SCD PROCESSING WITH MERGE
-- ============================================================================

/*
For ETL processes, MERGE is efficient for processing many records at once.
This example shows a complete Type 2 bulk processing pattern.
*/

-- Create staging table
DROP TABLE IF EXISTS staging.CustomerLoad;
CREATE TABLE staging.CustomerLoad (
    CustomerID          INT PRIMARY KEY,
    CustomerName        NVARCHAR(100),
    Email               NVARCHAR(100),
    Phone               NVARCHAR(20),
    Address             NVARCHAR(200),
    City                NVARCHAR(50),
    State               NVARCHAR(50),
    Country             NVARCHAR(50),
    CustomerSegment     NVARCHAR(50),
    RowHash             AS HASHBYTES('SHA2_256', 
        CONCAT(CustomerName, '|', Email, '|', Address, '|', City, '|', State, '|', CustomerSegment))
);
GO

-- Bulk SCD Type 2 procedure
CREATE OR ALTER PROCEDURE dim.usp_BulkLoadCustomers_Type2
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @InsertCount INT, @UpdateCount INT;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Step 1: Expire changed records
        UPDATE d
        SET d.EffectiveEndDate = DATEADD(DAY, -1, @Today),
            d.IsCurrent = 0,
            d.LastModifiedDate = GETDATE()
        FROM dim.Customer_Type2 d
        INNER JOIN staging.CustomerLoad s ON d.CustomerID = s.CustomerID
        WHERE d.IsCurrent = 1
          AND d.RowHash != s.RowHash;
        
        SET @UpdateCount = @@ROWCOUNT;
        
        -- Step 2: Insert new versions for changed records
        INSERT INTO dim.Customer_Type2 (
            CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
            CustomerSegment, EffectiveStartDate, RowHash, VersionNumber
        )
        SELECT 
            s.CustomerID, s.CustomerName, s.Email, s.Phone, s.Address, s.City, s.State, s.Country,
            s.CustomerSegment, @Today, s.RowHash, d.VersionNumber + 1
        FROM staging.CustomerLoad s
        INNER JOIN dim.Customer_Type2 d ON s.CustomerID = d.CustomerID
        WHERE d.IsCurrent = 0 
          AND d.EffectiveEndDate = DATEADD(DAY, -1, @Today);
        
        -- Step 3: Insert brand new customers
        INSERT INTO dim.Customer_Type2 (
            CustomerID, CustomerName, Email, Phone, Address, City, State, Country,
            CustomerSegment, EffectiveStartDate, RowHash
        )
        SELECT 
            s.CustomerID, s.CustomerName, s.Email, s.Phone, s.Address, s.City, s.State, s.Country,
            s.CustomerSegment, @Today, s.RowHash
        FROM staging.CustomerLoad s
        WHERE NOT EXISTS (
            SELECT 1 FROM dim.Customer_Type2 d WHERE d.CustomerID = s.CustomerID
        );
        
        SET @InsertCount = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Report results
        SELECT 
            @InsertCount AS NewCustomers,
            @UpdateCount AS UpdatedCustomers,
            (SELECT COUNT(*) FROM dim.Customer_Type2 WHERE IsCurrent = 1) AS TotalCurrentRecords,
            (SELECT COUNT(*) FROM dim.Customer_Type2 WHERE IsCurrent = 0) AS TotalHistoricalRecords;
            
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- SECTION 10: EXERCISES
-- ============================================================================

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 1: PRODUCT DIMENSION WITH MIXED SCD TYPES                         ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create a Product dimension that uses:                                       ║
║  - Type 0: ProductID, ProductCreatedDate                                    ║
║  - Type 1: ListPrice, DiscountPercent, IsActive                             ║
║  - Type 2: Category, Subcategory, Supplier                                  ║
║  - Type 3: UnitCost (track current and previous)                            ║
║                                                                              ║
║  Requirements:                                                               ║
║  1. Create the dimension table with proper columns                          ║
║  2. Create stored procedure to handle updates                               ║
║  3. Create view for current products                                        ║
║  4. Insert 5 sample products                                                ║
║  5. Demonstrate updates of each SCD type                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 2: EMPLOYEE HISTORY TRACKING                                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create an Employee dimension with Type 2 tracking:                          ║
║  - Track: Department, JobTitle, Salary, ManagerID                           ║
║                                                                              ║
║  Include:                                                                    ║
║  1. Point-in-time query function                                            ║
║  2. Salary history report                                                   ║
║  3. Department transfer history                                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 3: SCD SELECTION CHALLENGE                                         ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  For each scenario, choose the best SCD type and justify:                    ║
║                                                                              ║
║  1. Customer's marital status                                               ║
║  2. Product's packaging type                                                ║
║  3. Employee's office location                                              ║
║  4. Customer's credit score                                                 ║
║  5. Product's weight                                                        ║
║  6. Store's manager                                                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your answers:
/*
1. Customer's marital status - 
   SCD Type: ___
   Justification: 

2. Product's packaging type - 
   SCD Type: ___
   Justification: 

3. Employee's office location - 
   SCD Type: ___
   Justification: 

4. Customer's credit score - 
   SCD Type: ___
   Justification: 

5. Product's weight - 
   SCD Type: ___
   Justification: 

6. Store's manager - 
   SCD Type: ___
   Justification: 
*/


-- ============================================================================
-- SECTION 11: LAB SOLUTIONS
-- ============================================================================

/*
═══════════════════════════════════════════════════════════════════════════════
                              SOLUTIONS
═══════════════════════════════════════════════════════════════════════════════
*/

-- SOLUTION 1: Product Dimension with Mixed SCD Types
CREATE TABLE dim.Product_Mixed (
    ProductKey              INT IDENTITY(1,1) PRIMARY KEY,
    ProductID               INT NOT NULL,                    -- Business Key
    ProductName             NVARCHAR(100) NOT NULL,
    
    -- Type 0: Fixed forever
    ProductCreatedDate      DATE NOT NULL,
    OriginalSKU             NVARCHAR(50),
    
    -- Type 1: Overwrite (not tracked historically)
    ListPrice               DECIMAL(10,2),
    DiscountPercent         DECIMAL(5,2),
    IsActive                BIT DEFAULT 1,
    
    -- Type 2: Historical tracking
    Category                NVARCHAR(50),
    Subcategory             NVARCHAR(50),
    Supplier                NVARCHAR(100),
    
    -- Type 3: Current + Previous
    CurrentUnitCost         DECIMAL(10,2),
    PreviousUnitCost        DECIMAL(10,2),
    UnitCostChangeDate      DATE,
    
    -- Type 2 Tracking
    EffectiveStartDate      DATE NOT NULL,
    EffectiveEndDate        DATE NOT NULL DEFAULT '9999-12-31',
    IsCurrent               BIT NOT NULL DEFAULT 1,
    VersionNumber           INT NOT NULL DEFAULT 1,
    
    RowHash                 VARBINARY(32),
    CreatedDate             DATETIME2 DEFAULT GETDATE()
);
GO

-- SOLUTION 3: SCD Selection Answers
/*
1. Customer's marital status - 
   SCD Type: Type 2 (or Type 3)
   Justification: Marital status affects many analytics (household size, 
   purchasing patterns). Type 2 maintains full history for temporal analysis.
   Type 3 is acceptable if only current vs previous comparison needed.

2. Product's packaging type - 
   SCD Type: Type 1
   Justification: Packaging changes are typically corrections or updates
   that don't require historical tracking. The product is still the same.

3. Employee's office location - 
   SCD Type: Type 2
   Justification: Office transfers are important for historical reporting
   on regional productivity, team composition over time, etc.

4. Customer's credit score - 
   SCD Type: Type 4 (Mini-dimension with bands)
   Justification: Credit scores change frequently. Using banded values
   (Excellent/Good/Fair/Poor) in a mini-dimension prevents dimension bloat.

5. Product's weight - 
   SCD Type: Type 1
   Justification: Weight corrections don't need history. If weight changes
   due to reformulation, that's typically a new product.

6. Store's manager - 
   SCD Type: Type 2
   Justification: Manager changes are important for performance analysis,
   trend analysis (sales under Manager A vs B), and historical reporting.
*/

-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
/*
DROP TABLE IF EXISTS fact.CustomerTransaction;
DROP TABLE IF EXISTS dim.Customer_Type0;
DROP TABLE IF EXISTS dim.Customer_Type1;
DROP TABLE IF EXISTS dim.Customer_Type2;
DROP TABLE IF EXISTS dim.Customer_Type3;
DROP TABLE IF EXISTS dim.Customer_Type6;
DROP TABLE IF EXISTS dim.Customer_Main;
DROP TABLE IF EXISTS dim.CustomerProfile_Mini;
DROP TABLE IF EXISTS dim.Product_Mixed;
DROP TABLE IF EXISTS staging.CustomerLoad;

DROP VIEW IF EXISTS dim.vw_Customer_Current;
DROP FUNCTION IF EXISTS dim.fn_GetCustomerAsOf;

DROP PROCEDURE IF EXISTS dim.usp_ProcessCustomer_Type1;
DROP PROCEDURE IF EXISTS dim.usp_ProcessCustomer_Type2;
DROP PROCEDURE IF EXISTS dim.usp_ProcessCustomer_Type3;
DROP PROCEDURE IF EXISTS dim.usp_ProcessCustomer_Type6;
DROP PROCEDURE IF EXISTS dim.usp_BulkLoadCustomers_Type2;

DROP SCHEMA IF EXISTS dim;
DROP SCHEMA IF EXISTS staging;
DROP SCHEMA IF EXISTS fact;
*/

PRINT '═══════════════════════════════════════════════════════════════════════════';
PRINT '  Lab 63: Slowly Changing Dimensions (SCD) - Complete';
PRINT '═══════════════════════════════════════════════════════════════════════════';
GO
