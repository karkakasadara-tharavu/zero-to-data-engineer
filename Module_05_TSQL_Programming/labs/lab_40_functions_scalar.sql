/*
 * Lab 40: Functions - Scalar Functions
 * Module 05: T-SQL Programming
 * 
 * Objective: Master scalar user-defined functions
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 40: Scalar Functions';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: BASIC SCALAR FUNCTIONS
 */

PRINT 'PART 1: Basic Scalar Functions';
PRINT '--------------------------------';

-- Simple calculation function
IF OBJECT_ID('dbo.fn_CalculateDiscount', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateDiscount;
GO

CREATE FUNCTION dbo.fn_CalculateDiscount (
    @Price DECIMAL(10,2),
    @DiscountPercent DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @DiscountedPrice DECIMAL(10,2);
    
    IF @DiscountPercent < 0 OR @DiscountPercent > 100
        SET @DiscountedPrice = @Price;  -- Invalid discount
    ELSE
        SET @DiscountedPrice = @Price * (1 - @DiscountPercent / 100);
    
    RETURN @DiscountedPrice;
END;
GO

PRINT '✓ Created fn_CalculateDiscount';

-- Test function
SELECT 
    BookID,
    Title,
    Price AS OriginalPrice,
    dbo.fn_CalculateDiscount(Price, 10) AS Price10Off,
    dbo.fn_CalculateDiscount(Price, 25) AS Price25Off
FROM Books;
PRINT '';

/*
 * PART 2: STRING MANIPULATION FUNCTIONS
 */

PRINT 'PART 2: String Manipulation Functions';
PRINT '---------------------------------------';

-- Format phone number
IF OBJECT_ID('dbo.fn_FormatPhone', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_FormatPhone;
GO

CREATE FUNCTION dbo.fn_FormatPhone (
    @PhoneNumber NVARCHAR(20)
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @Formatted NVARCHAR(20);
    DECLARE @Digits NVARCHAR(20);
    
    -- Extract digits only
    SET @Digits = REPLACE(REPLACE(REPLACE(REPLACE(@PhoneNumber, '-', ''), '(', ''), ')', ''), ' ', '');
    
    -- Format as (XXX) XXX-XXXX
    IF LEN(@Digits) = 10
        SET @Formatted = '(' + SUBSTRING(@Digits, 1, 3) + ') ' + 
                         SUBSTRING(@Digits, 4, 3) + '-' + 
                         SUBSTRING(@Digits, 7, 4);
    ELSE
        SET @Formatted = @PhoneNumber;  -- Return original if invalid
    
    RETURN @Formatted;
END;
GO

PRINT '✓ Created fn_FormatPhone';

-- Test formatting
SELECT 
    '5551234567' AS RawPhone,
    dbo.fn_FormatPhone('5551234567') AS FormattedPhone
UNION ALL
SELECT 
    '555-123-4567',
    dbo.fn_FormatPhone('555-123-4567');
PRINT '';

-- Initials function
IF OBJECT_ID('dbo.fn_GetInitials', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetInitials;
GO

CREATE FUNCTION dbo.fn_GetInitials (
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100)
)
RETURNS NVARCHAR(10)
AS
BEGIN
    DECLARE @Initials NVARCHAR(10);
    
    SET @Initials = UPPER(LEFT(@FirstName, 1)) + UPPER(LEFT(@LastName, 1));
    
    RETURN @Initials;
END;
GO

PRINT '✓ Created fn_GetInitials';

SELECT 
    FirstName,
    LastName,
    dbo.fn_GetInitials(FirstName, LastName) AS Initials
FROM Customers;
PRINT '';

/*
 * PART 3: DATE/TIME FUNCTIONS
 */

PRINT 'PART 3: Date/Time Functions';
PRINT '----------------------------';

-- Calculate age
IF OBJECT_ID('dbo.fn_CalculateAge', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateAge;
GO

CREATE FUNCTION dbo.fn_CalculateAge (
    @DateOfBirth DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT;
    
    SET @Age = DATEDIFF(YEAR, @DateOfBirth, GETDATE()) - 
               CASE 
                   WHEN MONTH(@DateOfBirth) > MONTH(GETDATE()) OR 
                        (MONTH(@DateOfBirth) = MONTH(GETDATE()) AND DAY(@DateOfBirth) > DAY(GETDATE()))
                   THEN 1
                   ELSE 0
               END;
    
    RETURN @Age;
END;
GO

PRINT '✓ Created fn_CalculateAge';

SELECT 
    CustomerID,
    FirstName,
    LastName,
    DateOfBirth,
    dbo.fn_CalculateAge(DateOfBirth) AS Age
FROM Customers
WHERE DateOfBirth IS NOT NULL;
PRINT '';

-- Business days between dates
IF OBJECT_ID('dbo.fn_BusinessDays', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_BusinessDays;
GO

CREATE FUNCTION dbo.fn_BusinessDays (
    @StartDate DATE,
    @EndDate DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Days INT = 0;
    DECLARE @CurrentDate DATE = @StartDate;
    
    WHILE @CurrentDate <= @EndDate
    BEGIN
        -- Count if weekday (Monday=2 to Friday=6)
        IF DATEPART(WEEKDAY, @CurrentDate) BETWEEN 2 AND 6
            SET @Days = @Days + 1;
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;
    
    RETURN @Days;
END;
GO

PRINT '✓ Created fn_BusinessDays';

SELECT 
    dbo.fn_BusinessDays('2024-01-01', '2024-01-15') AS BusinessDaysInJan,
    dbo.fn_BusinessDays('2024-12-01', '2024-12-31') AS BusinessDaysInDec;
PRINT '';

/*
 * PART 4: MATHEMATICAL FUNCTIONS
 */

PRINT 'PART 4: Mathematical Functions';
PRINT '--------------------------------';

-- Calculate sales tax
IF OBJECT_ID('dbo.fn_CalculateTax', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateTax;
GO

CREATE FUNCTION dbo.fn_CalculateTax (
    @Amount DECIMAL(10,2),
    @TaxRate DECIMAL(5,4)  -- e.g., 0.0875 for 8.75%
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN ROUND(@Amount * @TaxRate, 2);
END;
GO

PRINT '✓ Created fn_CalculateTax';

SELECT 
    BookID,
    Title,
    Price,
    dbo.fn_CalculateTax(Price, 0.0875) AS Tax,
    Price + dbo.fn_CalculateTax(Price, 0.0875) AS TotalWithTax
FROM Books;
PRINT '';

-- Compound interest
IF OBJECT_ID('dbo.fn_CompoundInterest', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CompoundInterest;
GO

CREATE FUNCTION dbo.fn_CompoundInterest (
    @Principal DECIMAL(12,2),
    @Rate DECIMAL(5,4),
    @Years INT,
    @CompoundsPerYear INT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @FutureValue DECIMAL(12,2);
    
    -- A = P(1 + r/n)^(nt)
    SET @FutureValue = @Principal * POWER((1 + @Rate / @CompoundsPerYear), @Years * @CompoundsPerYear);
    
    RETURN ROUND(@FutureValue, 2);
END;
GO

PRINT '✓ Created fn_CompoundInterest';

SELECT 
    dbo.fn_CompoundInterest(1000, 0.05, 10, 12) AS FutureValue_Monthly,
    dbo.fn_CompoundInterest(1000, 0.05, 10, 4) AS FutureValue_Quarterly;
PRINT '';

/*
 * PART 5: CONDITIONAL LOGIC FUNCTIONS
 */

PRINT 'PART 5: Conditional Logic Functions';
PRINT '-------------------------------------';

-- Customer tier based on purchases
IF OBJECT_ID('dbo.fn_GetCustomerTier', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetCustomerTier;
GO

CREATE FUNCTION dbo.fn_GetCustomerTier (
    @TotalPurchases DECIMAL(10,2)
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @Tier NVARCHAR(20);
    
    SET @Tier = CASE
        WHEN @TotalPurchases >= 5000 THEN 'Platinum'
        WHEN @TotalPurchases >= 2500 THEN 'Gold'
        WHEN @TotalPurchases >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END;
    
    RETURN @Tier;
END;
GO

PRINT '✓ Created fn_GetCustomerTier';

-- Test with sample data
SELECT 
    CustomerID,
    FirstName + ' ' + LastName AS CustomerName,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalPurchases,
    dbo.fn_GetCustomerTier(ISNULL(SUM(o.TotalAmount), 0)) AS Tier
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;
PRINT '';

-- Validate email
IF OBJECT_ID('dbo.fn_IsValidEmail', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_IsValidEmail;
GO

CREATE FUNCTION dbo.fn_IsValidEmail (
    @Email NVARCHAR(255)
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT = 0;
    
    IF @Email LIKE '%_@__%.__%'  -- Basic pattern
       AND CHARINDEX(' ', @Email) = 0  -- No spaces
       AND CHARINDEX('..', @Email) = 0  -- No consecutive dots
       AND LEFT(@Email, 1) <> '@'  -- Doesn't start with @
    BEGIN
        SET @IsValid = 1;
    END;
    
    RETURN @IsValid;
END;
GO

PRINT '✓ Created fn_IsValidEmail';

SELECT 
    'john@example.com' AS Email,
    dbo.fn_IsValidEmail('john@example.com') AS IsValid
UNION ALL
SELECT 'invalid.email', dbo.fn_IsValidEmail('invalid.email')
UNION ALL
SELECT '@example.com', dbo.fn_IsValidEmail('@example.com');
PRINT '';

/*
 * PART 6: CONVERSION FUNCTIONS
 */

PRINT 'PART 6: Conversion Functions';
PRINT '------------------------------';

-- Convert bytes to human-readable size
IF OBJECT_ID('dbo.fn_FormatBytes', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_FormatBytes;
GO

CREATE FUNCTION dbo.fn_FormatBytes (
    @Bytes BIGINT
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @Result NVARCHAR(20);
    
    IF @Bytes >= 1099511627776  -- >= 1 TB
        SET @Result = CAST(CAST(@Bytes / 1099511627776.0 AS DECIMAL(10,2)) AS NVARCHAR) + ' TB';
    ELSE IF @Bytes >= 1073741824  -- >= 1 GB
        SET @Result = CAST(CAST(@Bytes / 1073741824.0 AS DECIMAL(10,2)) AS NVARCHAR) + ' GB';
    ELSE IF @Bytes >= 1048576  -- >= 1 MB
        SET @Result = CAST(CAST(@Bytes / 1048576.0 AS DECIMAL(10,2)) AS NVARCHAR) + ' MB';
    ELSE IF @Bytes >= 1024  -- >= 1 KB
        SET @Result = CAST(CAST(@Bytes / 1024.0 AS DECIMAL(10,2)) AS NVARCHAR) + ' KB';
    ELSE
        SET @Result = CAST(@Bytes AS NVARCHAR) + ' bytes';
    
    RETURN @Result;
END;
GO

PRINT '✓ Created fn_FormatBytes';

SELECT 
    dbo.fn_FormatBytes(500) AS Bytes,
    dbo.fn_FormatBytes(15360) AS KB,
    dbo.fn_FormatBytes(5242880) AS MB,
    dbo.fn_FormatBytes(3221225472) AS GB;
PRINT '';

/*
 * PART 7: NULL HANDLING FUNCTIONS
 */

PRINT 'PART 7: NULL Handling Functions';
PRINT '---------------------------------';

-- Coalesce with default
IF OBJECT_ID('dbo.fn_GetValueOrDefault', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetValueOrDefault;
GO

CREATE FUNCTION dbo.fn_GetValueOrDefault (
    @Value NVARCHAR(MAX),
    @Default NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN ISNULL(NULLIF(@Value, ''), @Default);
END;
GO

PRINT '✓ Created fn_GetValueOrDefault';

SELECT 
    dbo.fn_GetValueOrDefault(NULL, 'N/A') AS NullValue,
    dbo.fn_GetValueOrDefault('', 'N/A') AS EmptyValue,
    dbo.fn_GetValueOrDefault('Value', 'N/A') AS ActualValue;
PRINT '';

/*
 * PART 8: BUSINESS LOGIC FUNCTIONS
 */

PRINT 'PART 8: Business Logic Functions';
PRINT '----------------------------------';

-- Calculate shipping cost
IF OBJECT_ID('dbo.fn_CalculateShipping', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateShipping;
GO

CREATE FUNCTION dbo.fn_CalculateShipping (
    @OrderAmount DECIMAL(10,2),
    @Weight DECIMAL(8,2),
    @Distance INT  -- miles
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @ShippingCost DECIMAL(10,2);
    
    -- Free shipping over $100
    IF @OrderAmount >= 100
        RETURN 0.00;
    
    -- Base rate + weight charge + distance charge
    SET @ShippingCost = 5.00 + (@Weight * 0.50) + (@Distance * 0.01);
    
    -- Minimum $5, maximum $50
    SET @ShippingCost = CASE 
        WHEN @ShippingCost < 5 THEN 5.00
        WHEN @ShippingCost > 50 THEN 50.00
        ELSE @ShippingCost
    END;
    
    RETURN ROUND(@ShippingCost, 2);
END;
GO

PRINT '✓ Created fn_CalculateShipping';

SELECT 
    dbo.fn_CalculateShipping(50, 2.5, 100) AS SmallOrder,
    dbo.fn_CalculateShipping(150, 10.0, 500) AS LargeOrder,
    dbo.fn_CalculateShipping(75, 50.0, 1000) AS HeavyOrder;
PRINT '';

/*
 * PART 9: PERFORMANCE CONSIDERATIONS
 */

PRINT 'PART 9: Performance Considerations';
PRINT '------------------------------------';
PRINT '';
PRINT 'SCALAR FUNCTION PERFORMANCE:';
PRINT '  - Called once per row (can be slow)';
PRINT '  - Cannot be parallelized';
PRINT '  - Prevents index usage (non-deterministic)';
PRINT '  - Consider inline table-valued functions instead';
PRINT '';

-- Example: Slow query with scalar function
PRINT 'Demonstrating function overhead:';
SET STATISTICS TIME ON;

SELECT COUNT(*)
FROM Books
WHERE dbo.fn_CalculateDiscount(Price, 10) > 20;

SET STATISTICS TIME OFF;
PRINT '';
PRINT '(Notice execution time - function called for every row)';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Best Practices Summary';
PRINT '---------------------------------';
PRINT '';
PRINT 'WHEN TO USE SCALAR FUNCTIONS:';
PRINT '  - Simple calculations';
PRINT '  - Reusable business logic';
PRINT '  - Formatting/conversion';
PRINT '  - CHECK constraints';
PRINT '';
PRINT 'WHEN TO AVOID:';
PRINT '  - Large result sets';
PRINT '  - Complex logic (use stored procedures)';
PRINT '  - Performance-critical queries';
PRINT '  - Need parallelism';
PRINT '';
PRINT 'TIPS:';
PRINT '  - Keep functions simple and fast';
PRINT '  - Mark SCHEMABINDING for deterministic';
PRINT '  - Consider computed columns instead';
PRINT '  - Test performance impact';
PRINT '  - Document parameters and return type';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create fn_CalculateLoanPayment (principal, rate, months)
 * 2. Create fn_MaskCreditCard (shows last 4 digits only)
 * 3. Create fn_GetQuarter (returns Q1-Q4 from date)
 * 4. Create fn_ValidateISBN (validates ISBN-10 or ISBN-13)
 * 5. Create fn_CalculateDistance (lat/long coordinates)
 * 
 * CHALLENGE:
 * Create a suite of string utility functions:
 * - fn_TitleCase: Capitalize first letter of each word
 * - fn_RemoveSpecialChars: Keep only alphanumeric
 * - fn_TruncateWithEllipsis: Limit length, add "..."
 * - fn_CountWords: Count words in string
 * - fn_ReverseString: Reverse character order
 */

PRINT '✓ Lab 40 Complete: Scalar functions mastered';
GO
