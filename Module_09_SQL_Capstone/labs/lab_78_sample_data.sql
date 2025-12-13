/*******************************************************************************
 * LAB 78: SQL Capstone - Sample Data Generation
 * Module 09: SQL Capstone Project
 * 
 * Objective: Generate realistic sample data for the GlobalMart OLTP system
 *            to simulate a real-world retail environment.
 * 
 * Duration: 4-6 hours
 * 
 * Data Volume:
 * - 5 Regions, 25 Countries, 150 Stores
 * - 20 Categories, 5000 Products
 * - 100,000 Customers
 * - 500,000 Orders with 1.5M+ order details
 ******************************************************************************/

USE GlobalMart_OLTP;
GO

/*******************************************************************************
 * PART 1: POPULATE REFERENCE DATA
 ******************************************************************************/

-- Insert Regions
INSERT INTO HR.Regions (RegionName, CurrencyCode, TimeZone) VALUES
('North America', 'USD', 'America/New_York'),
('Europe', 'EUR', 'Europe/London'),
('Asia Pacific', 'USD', 'Asia/Singapore'),
('South America', 'BRL', 'America/Sao_Paulo'),
('Australia', 'AUD', 'Australia/Sydney');

-- Insert Countries
INSERT INTO HR.Countries (CountryCode, CountryName, RegionID) VALUES
-- North America
('US', 'United States', 1),
('CA', 'Canada', 1),
('MX', 'Mexico', 1),
-- Europe
('GB', 'United Kingdom', 2),
('DE', 'Germany', 2),
('FR', 'France', 2),
('IT', 'Italy', 2),
('ES', 'Spain', 2),
('NL', 'Netherlands', 2),
('SE', 'Sweden', 2),
-- Asia Pacific
('JP', 'Japan', 3),
('CN', 'China', 3),
('SG', 'Singapore', 3),
('KR', 'South Korea', 3),
('IN', 'India', 3),
('TH', 'Thailand', 3),
-- South America
('BR', 'Brazil', 4),
('AR', 'Argentina', 4),
('CL', 'Chile', 4),
('CO', 'Colombia', 4),
-- Australia
('AU', 'Australia', 5),
('NZ', 'New Zealand', 5);

-- Insert Customer Segments
INSERT INTO Sales.CustomerSegments (SegmentName, Description, MinAnnualSpend, MaxAnnualSpend, DiscountPercent) VALUES
('Bronze', 'Entry level customers', 0, 500, 0),
('Silver', 'Regular customers', 500.01, 2000, 5),
('Gold', 'Preferred customers', 2000.01, 10000, 10),
('Platinum', 'VIP customers', 10000.01, NULL, 15);

PRINT 'Reference data inserted.';
GO

/*******************************************************************************
 * PART 2: GENERATE STORES
 ******************************************************************************/

-- Create temp table for cities
CREATE TABLE #Cities (
    CityName NVARCHAR(100),
    CountryCode CHAR(2)
);

INSERT INTO #Cities VALUES
-- US Cities
('New York', 'US'), ('Los Angeles', 'US'), ('Chicago', 'US'), ('Houston', 'US'),
('Phoenix', 'US'), ('San Francisco', 'US'), ('Seattle', 'US'), ('Boston', 'US'),
('Atlanta', 'US'), ('Miami', 'US'), ('Denver', 'US'), ('Dallas', 'US'),
-- Canada
('Toronto', 'CA'), ('Vancouver', 'CA'), ('Montreal', 'CA'), ('Calgary', 'CA'),
-- Mexico
('Mexico City', 'MX'), ('Guadalajara', 'MX'),
-- UK
('London', 'GB'), ('Manchester', 'GB'), ('Birmingham', 'GB'), ('Edinburgh', 'GB'),
-- Germany
('Berlin', 'DE'), ('Munich', 'DE'), ('Frankfurt', 'DE'), ('Hamburg', 'DE'),
-- France
('Paris', 'FR'), ('Lyon', 'FR'), ('Marseille', 'FR'),
-- Italy
('Rome', 'IT'), ('Milan', 'IT'),
-- Spain
('Madrid', 'ES'), ('Barcelona', 'ES'),
-- Netherlands
('Amsterdam', 'NL'), ('Rotterdam', 'NL'),
-- Sweden
('Stockholm', 'SE'), ('Gothenburg', 'SE'),
-- Japan
('Tokyo', 'JP'), ('Osaka', 'JP'), ('Nagoya', 'JP'),
-- China
('Shanghai', 'CN'), ('Beijing', 'CN'), ('Shenzhen', 'CN'), ('Guangzhou', 'CN'),
-- Singapore
('Singapore', 'SG'),
-- South Korea
('Seoul', 'KR'), ('Busan', 'KR'),
-- India
('Mumbai', 'IN'), ('Delhi', 'IN'), ('Bangalore', 'IN'),
-- Thailand
('Bangkok', 'TH'),
-- Brazil
('Sao Paulo', 'BR'), ('Rio de Janeiro', 'BR'), ('Brasilia', 'BR'),
-- Argentina
('Buenos Aires', 'AR'),
-- Chile
('Santiago', 'CL'),
-- Colombia
('Bogota', 'CO'),
-- Australia
('Sydney', 'AU'), ('Melbourne', 'AU'), ('Brisbane', 'AU'), ('Perth', 'AU'),
-- New Zealand
('Auckland', 'NZ'), ('Wellington', 'NZ');

-- Generate stores
DECLARE @StoreNum INT = 1;
DECLARE @City NVARCHAR(100), @CountryCode CHAR(2), @CountryID INT;

DECLARE city_cursor CURSOR FOR
    SELECT CityName, CountryCode FROM #Cities;

OPEN city_cursor;
FETCH NEXT FROM city_cursor INTO @City, @CountryCode;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @CountryID = CountryID FROM HR.Countries WHERE CountryCode = @CountryCode;
    
    -- Create 1-3 stores per city
    DECLARE @StoresInCity INT = 1 + ABS(CHECKSUM(NEWID())) % 3;
    DECLARE @i INT = 1;
    
    WHILE @i <= @StoresInCity AND @StoreNum <= 150
    BEGIN
        INSERT INTO HR.Stores (StoreName, StoreCode, CountryID, City, Address, 
            OpenDate, SquareFeet, IsActive)
        VALUES (
            @City + ' Store ' + CAST(@i AS VARCHAR),
            'ST' + RIGHT('000' + CAST(@StoreNum AS VARCHAR), 3),
            @CountryID,
            @City,
            CAST(100 + @StoreNum AS VARCHAR) + ' Main Street',
            DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 3650, GETDATE()), -- Random date in last 10 years
            5000 + ABS(CHECKSUM(NEWID())) % 45000, -- 5000-50000 sq ft
            1
        );
        
        SET @StoreNum = @StoreNum + 1;
        SET @i = @i + 1;
    END;
    
    FETCH NEXT FROM city_cursor INTO @City, @CountryCode;
END;

CLOSE city_cursor;
DEALLOCATE city_cursor;

DROP TABLE #Cities;

PRINT 'Stores generated: ' + CAST(@StoreNum - 1 AS VARCHAR);
GO

/*******************************************************************************
 * PART 3: GENERATE CATEGORIES AND BRANDS
 ******************************************************************************/

-- Parent Categories
INSERT INTO Products.Categories (CategoryName, ParentCategoryID, Description) VALUES
('Electronics', NULL, 'Electronic devices and accessories'),
('Clothing', NULL, 'Apparel and fashion'),
('Home & Garden', NULL, 'Home improvement and garden supplies'),
('Sports & Outdoors', NULL, 'Sporting goods and outdoor equipment'),
('Books & Media', NULL, 'Books, movies, and music'),
('Toys & Games', NULL, 'Toys, games, and hobbies'),
('Health & Beauty', NULL, 'Health, beauty, and personal care'),
('Food & Grocery', NULL, 'Food, beverages, and groceries'),
('Office Supplies', NULL, 'Office and school supplies'),
('Automotive', NULL, 'Auto parts and accessories');

-- Subcategories
INSERT INTO Products.Categories (CategoryName, ParentCategoryID, Description) VALUES
-- Electronics subs
('Smartphones', 1, 'Mobile phones'),
('Laptops', 1, 'Portable computers'),
('Tablets', 1, 'Tablet devices'),
('Audio', 1, 'Headphones, speakers'),
('Cameras', 1, 'Digital cameras'),
-- Clothing subs
('Men''s Clothing', 2, 'Men''s apparel'),
('Women''s Clothing', 2, 'Women''s apparel'),
('Kids Clothing', 2, 'Children''s apparel'),
('Shoes', 2, 'Footwear'),
('Accessories', 2, 'Fashion accessories'),
-- Home subs
('Furniture', 3, 'Home furniture'),
('Kitchen', 3, 'Kitchen appliances and tools'),
('Bedding', 3, 'Bedding and linens'),
('Garden', 3, 'Garden tools and plants'),
-- Sports subs
('Fitness', 4, 'Gym equipment'),
('Team Sports', 4, 'Team sport equipment'),
('Outdoor Recreation', 4, 'Camping, hiking'),
-- Other subs
('Fiction', 5, 'Fiction books'),
('Non-Fiction', 5, 'Non-fiction books'),
('Board Games', 6, 'Board games'),
('Video Games', 6, 'Video games'),
('Skincare', 7, 'Skin care products'),
('Supplements', 7, 'Health supplements'),
('Snacks', 8, 'Snack foods'),
('Beverages', 8, 'Drinks');

-- Brands
INSERT INTO Products.Brands (BrandName, Description) VALUES
('TechPro', 'Premium technology brand'),
('StyleMax', 'Fashion forward clothing'),
('HomeEssentials', 'Quality home products'),
('SportElite', 'Professional sports equipment'),
('ReadMore', 'Book publishing'),
('PlayFun', 'Toys and games'),
('HealthFirst', 'Health and wellness'),
('FreshChoice', 'Food and grocery'),
('OfficePro', 'Office supplies'),
('AutoParts Plus', 'Automotive'),
('GlobalBasics', 'Value brand'),
('PremiumSelect', 'Premium products'),
('EcoFriendly', 'Sustainable products'),
('KidZone', 'Children''s products'),
('OutdoorPro', 'Outdoor equipment');

PRINT 'Categories and brands created.';
GO

/*******************************************************************************
 * PART 4: GENERATE SUPPLIERS
 ******************************************************************************/

-- Create suppliers for each region
DECLARE @SupplierNum INT = 1;
DECLARE @CountryID INT;

DECLARE country_cursor CURSOR FOR
    SELECT CountryID FROM HR.Countries;

OPEN country_cursor;
FETCH NEXT FROM country_cursor INTO @CountryID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 2-4 suppliers per country
    DECLARE @SuppliersCount INT = 2 + ABS(CHECKSUM(NEWID())) % 3;
    DECLARE @s INT = 1;
    
    WHILE @s <= @SuppliersCount
    BEGIN
        INSERT INTO Products.Suppliers (CompanyName, ContactName, ContactEmail, 
            Phone, CountryID, PaymentTerms)
        VALUES (
            'Supplier ' + CAST(@SupplierNum AS VARCHAR) + ' Corp',
            'Contact Person ' + CAST(@SupplierNum AS VARCHAR),
            'supplier' + CAST(@SupplierNum AS VARCHAR) + '@email.com',
            '+1-555-' + RIGHT('0000' + CAST(@SupplierNum AS VARCHAR), 4),
            @CountryID,
            CASE ABS(CHECKSUM(NEWID())) % 3
                WHEN 0 THEN 'Net 30'
                WHEN 1 THEN 'Net 60'
                ELSE 'Net 90'
            END
        );
        
        SET @SupplierNum = @SupplierNum + 1;
        SET @s = @s + 1;
    END;
    
    FETCH NEXT FROM country_cursor INTO @CountryID;
END;

CLOSE country_cursor;
DEALLOCATE country_cursor;

PRINT 'Suppliers created: ' + CAST(@SupplierNum - 1 AS VARCHAR);
GO

/*******************************************************************************
 * PART 5: GENERATE PRODUCTS
 ******************************************************************************/

-- Generate 5000 products
DECLARE @ProductNum INT = 1;
DECLARE @CategoryID INT, @BrandID INT, @SupplierID INT;
DECLARE @BasePrice DECIMAL(10,2), @Cost DECIMAL(10,2);
DECLARE @MaxCategory INT = (SELECT MAX(CategoryID) FROM Products.Categories);
DECLARE @MaxBrand INT = (SELECT MAX(BrandID) FROM Products.Brands);
DECLARE @MaxSupplier INT = (SELECT MAX(SupplierID) FROM Products.Suppliers);

WHILE @ProductNum <= 5000
BEGIN
    -- Random category (prefer subcategories)
    SET @CategoryID = 10 + ABS(CHECKSUM(NEWID())) % (@MaxCategory - 10 + 1);
    IF @CategoryID > @MaxCategory SET @CategoryID = 11;
    
    SET @BrandID = 1 + ABS(CHECKSUM(NEWID())) % @MaxBrand;
    SET @SupplierID = 1 + ABS(CHECKSUM(NEWID())) % @MaxSupplier;
    
    -- Price based on category
    SET @BasePrice = 
        CASE 
            WHEN @CategoryID BETWEEN 11 AND 15 THEN 50 + ABS(CHECKSUM(NEWID())) % 950 -- Electronics: $50-$1000
            WHEN @CategoryID BETWEEN 16 AND 20 THEN 15 + ABS(CHECKSUM(NEWID())) % 185 -- Clothing: $15-$200
            WHEN @CategoryID BETWEEN 21 AND 24 THEN 25 + ABS(CHECKSUM(NEWID())) % 475 -- Home: $25-$500
            ELSE 10 + ABS(CHECKSUM(NEWID())) % 90 -- Others: $10-$100
        END;
    
    SET @Cost = @BasePrice * (0.4 + (ABS(CHECKSUM(NEWID())) % 30) / 100.0); -- 40-70% of price
    
    INSERT INTO Products.Products (
        ProductName, ProductCode, CategoryID, BrandID, SupplierID,
        Description, UnitPrice, Cost, Weight, Size, Color, ReorderLevel
    )
    VALUES (
        'Product ' + CAST(@ProductNum AS VARCHAR) + ' - ' + 
            (SELECT TOP 1 CategoryName FROM Products.Categories WHERE CategoryID = @CategoryID),
        'PRD' + RIGHT('00000' + CAST(@ProductNum AS VARCHAR), 5),
        @CategoryID,
        @BrandID,
        @SupplierID,
        'Description for product ' + CAST(@ProductNum AS VARCHAR),
        @BasePrice,
        @Cost,
        0.1 + ABS(CHECKSUM(NEWID())) % 100 / 10.0, -- 0.1-10 kg
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'Small'
            WHEN 1 THEN 'Medium'
            WHEN 2 THEN 'Large'
            WHEN 3 THEN 'XL'
            ELSE 'Standard'
        END,
        CASE ABS(CHECKSUM(NEWID())) % 8
            WHEN 0 THEN 'Black'
            WHEN 1 THEN 'White'
            WHEN 2 THEN 'Blue'
            WHEN 3 THEN 'Red'
            WHEN 4 THEN 'Green'
            WHEN 5 THEN 'Gray'
            WHEN 6 THEN 'Brown'
            ELSE 'Multi'
        END,
        10 + ABS(CHECKSUM(NEWID())) % 40 -- Reorder level 10-50
    );
    
    SET @ProductNum = @ProductNum + 1;
END;

PRINT 'Products created: 5000';
GO

/*******************************************************************************
 * PART 6: GENERATE CUSTOMERS
 ******************************************************************************/

-- Create temp tables for name generation
CREATE TABLE #FirstNames (FirstName NVARCHAR(50));
CREATE TABLE #LastNames (LastName NVARCHAR(50));

INSERT INTO #FirstNames VALUES 
('James'),('John'),('Robert'),('Michael'),('William'),('David'),('Richard'),('Joseph'),
('Thomas'),('Charles'),('Mary'),('Patricia'),('Jennifer'),('Linda'),('Elizabeth'),
('Barbara'),('Susan'),('Jessica'),('Sarah'),('Karen'),('Emma'),('Olivia'),('Ava'),
('Sophia'),('Isabella'),('Daniel'),('Matthew'),('Anthony'),('Mark'),('Donald'),
('Steven'),('Paul'),('Andrew'),('Joshua'),('Kenneth'),('Nancy'),('Betty'),('Margaret'),
('Sandra'),('Ashley'),('Kimberly'),('Emily'),('Donna'),('Michelle'),('Dorothy'),
('Carol'),('Amanda'),('Melissa'),('Deborah'),('Stephanie');

INSERT INTO #LastNames VALUES
('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),('Davis'),
('Rodriguez'),('Martinez'),('Anderson'),('Taylor'),('Thomas'),('Moore'),('Jackson'),
('Martin'),('Lee'),('Thompson'),('White'),('Harris'),('Sanchez'),('Clark'),('Ramirez'),
('Lewis'),('Robinson'),('Walker'),('Young'),('Allen'),('King'),('Wright'),('Scott'),
('Torres'),('Nguyen'),('Hill'),('Flores'),('Green'),('Adams'),('Nelson'),('Baker'),
('Hall'),('Rivera'),('Campbell'),('Mitchell'),('Carter'),('Roberts'),('Gomez'),
('Phillips'),('Evans'),('Turner'),('Diaz');

-- Generate 100,000 customers
DECLARE @CustomerNum INT = 1;
DECLARE @FirstName NVARCHAR(50), @LastName NVARCHAR(50);
DECLARE @MaxCountry INT = (SELECT MAX(CountryID) FROM HR.Countries);

WHILE @CustomerNum <= 100000
BEGIN
    -- Random names
    SELECT TOP 1 @FirstName = FirstName FROM #FirstNames ORDER BY NEWID();
    SELECT TOP 1 @LastName = LastName FROM #LastNames ORDER BY NEWID();
    
    INSERT INTO Sales.Customers (
        FirstName, LastName, Email, Phone, DateOfBirth, Gender,
        Address, City, State, PostalCode, CountryID, SegmentID, JoinDate
    )
    VALUES (
        @FirstName,
        @LastName,
        LOWER(@FirstName) + '.' + LOWER(@LastName) + CAST(@CustomerNum AS VARCHAR) + '@email.com',
        '+1-555-' + RIGHT('0000000' + CAST(ABS(CHECKSUM(NEWID())) % 10000000 AS VARCHAR), 7),
        DATEADD(YEAR, -18 - ABS(CHECKSUM(NEWID())) % 60, GETDATE()), -- 18-78 years old
        CASE ABS(CHECKSUM(NEWID())) % 2 WHEN 0 THEN 'M' ELSE 'F' END,
        CAST(ABS(CHECKSUM(NEWID())) % 9999 + 1 AS VARCHAR) + ' Street Name',
        'City ' + CAST(ABS(CHECKSUM(NEWID())) % 100 AS VARCHAR),
        'State ' + CAST(ABS(CHECKSUM(NEWID())) % 50 AS VARCHAR),
        RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 99999 AS VARCHAR), 5),
        1 + ABS(CHECKSUM(NEWID())) % @MaxCountry,
        1 + ABS(CHECKSUM(NEWID())) % 4, -- Random segment
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 3650, GETDATE()) -- Joined in last 10 years
    );
    
    IF @CustomerNum % 10000 = 0
        PRINT 'Customers created: ' + CAST(@CustomerNum AS VARCHAR);
    
    SET @CustomerNum = @CustomerNum + 1;
END;

DROP TABLE #FirstNames;
DROP TABLE #LastNames;

PRINT 'Total customers created: 100000';
GO

/*******************************************************************************
 * PART 7: GENERATE PROMOTIONS
 ******************************************************************************/

INSERT INTO Sales.Promotions (PromotionName, Description, DiscountType, DiscountValue, 
    StartDate, EndDate, MinPurchaseAmount, MaxDiscountAmount) VALUES
('Summer Sale 2023', 'Summer clearance event', 'PERCENT', 15, '2023-06-01', '2023-08-31', 50, 100),
('Black Friday 2023', 'Black Friday deals', 'PERCENT', 25, '2023-11-24', '2023-11-26', 0, 500),
('Holiday Special 2023', 'Holiday season promotion', 'PERCENT', 20, '2023-12-15', '2023-12-31', 100, 200),
('New Year Sale 2024', 'New year clearance', 'PERCENT', 30, '2024-01-01', '2024-01-15', 75, 150),
('Spring Fever 2024', 'Spring promotion', 'PERCENT', 10, '2024-03-01', '2024-04-30', 25, 50),
('Summer Blowout 2024', 'Summer clearance', 'PERCENT', 20, '2024-06-01', '2024-08-31', 50, 100),
('Back to School 2024', 'School supplies sale', 'PERCENT', 15, '2024-08-01', '2024-09-15', 30, 75),
('Flash Sale', 'Limited time offer', 'AMOUNT', 10, '2024-01-01', '2024-12-31', 50, 10),
('VIP Exclusive', 'Platinum members only', 'PERCENT', 25, '2024-01-01', '2024-12-31', 0, 500),
('Weekend Special', 'Every weekend discount', 'PERCENT', 5, '2024-01-01', '2024-12-31', 20, 25);

PRINT 'Promotions created.';
GO

/*******************************************************************************
 * PART 8: GENERATE ORDERS AND ORDER DETAILS
 ******************************************************************************/

-- This is the most complex and time-consuming part
-- Generate 500,000 orders with 1.5M+ line items

DECLARE @OrderNum INT = 1;
DECLARE @BatchSize INT = 10000;
DECLARE @TotalOrders INT = 500000;

DECLARE @MaxCustomer INT = (SELECT MAX(CustomerID) FROM Sales.Customers);
DECLARE @MaxStore INT = (SELECT MAX(StoreID) FROM HR.Stores);
DECLARE @MaxProduct INT = (SELECT MAX(ProductID) FROM Products.Products);
DECLARE @MaxPromotion INT = (SELECT MAX(PromotionID) FROM Sales.Promotions);

WHILE @OrderNum <= @TotalOrders
BEGIN
    -- Start transaction for batch
    BEGIN TRANSACTION;
    
    DECLARE @BatchEnd INT = @OrderNum + @BatchSize - 1;
    IF @BatchEnd > @TotalOrders SET @BatchEnd = @TotalOrders;
    
    WHILE @OrderNum <= @BatchEnd
    BEGIN
        DECLARE @CustomerID INT = 1 + ABS(CHECKSUM(NEWID())) % @MaxCustomer;
        DECLARE @StoreID INT = 1 + ABS(CHECKSUM(NEWID())) % @MaxStore;
        DECLARE @OrderDate DATETIME2 = DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 1095, GETDATE()); -- Last 3 years
        DECLARE @OrderID INT;
        
        -- Insert order
        INSERT INTO Sales.Orders (
            OrderNumber, CustomerID, StoreID, OrderDate, OrderStatus, PaymentMethod
        )
        VALUES (
            'ORD' + RIGHT('00000000' + CAST(@OrderNum AS VARCHAR), 8),
            @CustomerID,
            @StoreID,
            @OrderDate,
            CASE ABS(CHECKSUM(NEWID())) % 10
                WHEN 0 THEN 'Pending'
                WHEN 1 THEN 'Cancelled'
                ELSE 'Completed'
            END,
            CASE ABS(CHECKSUM(NEWID())) % 4
                WHEN 0 THEN 'Cash'
                WHEN 1 THEN 'Credit'
                WHEN 2 THEN 'Debit'
                ELSE 'Digital'
            END
        );
        
        SET @OrderID = SCOPE_IDENTITY();
        
        -- Insert 1-5 order details
        DECLARE @LineCount INT = 1 + ABS(CHECKSUM(NEWID())) % 5;
        DECLARE @Line INT = 1;
        DECLARE @SubTotal DECIMAL(12,2) = 0;
        
        WHILE @Line <= @LineCount
        BEGIN
            DECLARE @ProductID INT = 1 + ABS(CHECKSUM(NEWID())) % @MaxProduct;
            DECLARE @Quantity INT = 1 + ABS(CHECKSUM(NEWID())) % 5;
            DECLARE @UnitPrice DECIMAL(10,2);
            DECLARE @PromotionID INT = NULL;
            DECLARE @Discount DECIMAL(10,2) = 0;
            
            SELECT @UnitPrice = UnitPrice FROM Products.Products WHERE ProductID = @ProductID;
            
            -- 20% chance of promotion
            IF ABS(CHECKSUM(NEWID())) % 5 = 0
            BEGIN
                SET @PromotionID = 1 + ABS(CHECKSUM(NEWID())) % @MaxPromotion;
                SET @Discount = @UnitPrice * @Quantity * 0.1; -- Simplified discount
            END;
            
            INSERT INTO Sales.OrderDetails (OrderID, ProductID, PromotionID, Quantity, UnitPrice, Discount)
            VALUES (@OrderID, @ProductID, @PromotionID, @Quantity, @UnitPrice, @Discount);
            
            SET @SubTotal = @SubTotal + (@UnitPrice * @Quantity - @Discount);
            SET @Line = @Line + 1;
        END;
        
        -- Update order totals
        DECLARE @TaxRate DECIMAL(5,2) = 0.08; -- 8% tax
        UPDATE Sales.Orders
        SET SubTotal = @SubTotal,
            TaxAmount = @SubTotal * @TaxRate,
            ShippingAmount = CASE WHEN @SubTotal > 100 THEN 0 ELSE 9.99 END,
            DiscountAmount = 0,
            TotalAmount = @SubTotal + (@SubTotal * @TaxRate) + CASE WHEN @SubTotal > 100 THEN 0 ELSE 9.99 END
        WHERE OrderID = @OrderID;
        
        SET @OrderNum = @OrderNum + 1;
    END;
    
    COMMIT TRANSACTION;
    
    -- Progress update
    PRINT 'Orders created: ' + CAST(@OrderNum - 1 AS VARCHAR);
END;

PRINT 'Total orders created: ' + CAST(@TotalOrders AS VARCHAR);
GO

/*******************************************************************************
 * PART 9: GENERATE INVENTORY DATA
 ******************************************************************************/

-- Populate store inventory
INSERT INTO Inventory.StoreInventory (StoreID, ProductID, QuantityOnHand, QuantityReserved, LastRestockDate)
SELECT 
    s.StoreID,
    p.ProductID,
    ABS(CHECKSUM(NEWID())) % 200, -- 0-200 units
    ABS(CHECKSUM(NEWID())) % 20,  -- 0-20 reserved
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE()) -- Last 30 days
FROM HR.Stores s
CROSS JOIN (SELECT TOP 100 ProductID FROM Products.Products ORDER BY NEWID()) p;

PRINT 'Inventory data created.';
GO

/*******************************************************************************
 * PART 10: VERIFICATION AND STATISTICS
 ******************************************************************************/

-- Summary statistics
SELECT 'Regions' AS TableName, COUNT(*) AS RowCount FROM HR.Regions
UNION ALL SELECT 'Countries', COUNT(*) FROM HR.Countries
UNION ALL SELECT 'Stores', COUNT(*) FROM HR.Stores
UNION ALL SELECT 'Categories', COUNT(*) FROM Products.Categories
UNION ALL SELECT 'Brands', COUNT(*) FROM Products.Brands
UNION ALL SELECT 'Suppliers', COUNT(*) FROM Products.Suppliers
UNION ALL SELECT 'Products', COUNT(*) FROM Products.Products
UNION ALL SELECT 'Customers', COUNT(*) FROM Sales.Customers
UNION ALL SELECT 'Promotions', COUNT(*) FROM Sales.Promotions
UNION ALL SELECT 'Orders', COUNT(*) FROM Sales.Orders
UNION ALL SELECT 'OrderDetails', COUNT(*) FROM Sales.OrderDetails
UNION ALL SELECT 'StoreInventory', COUNT(*) FROM Inventory.StoreInventory;

-- Sales summary
SELECT 
    'Total Sales' AS Metric,
    COUNT(DISTINCT o.OrderID) AS Orders,
    SUM(od.Quantity) AS ItemsSold,
    SUM(o.TotalAmount) AS TotalRevenue
FROM Sales.Orders o
JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
WHERE o.OrderStatus = 'Completed';

PRINT '
=============================================================================
LAB 78 COMPLETE - SAMPLE DATA GENERATED
=============================================================================

Your GlobalMart_OLTP database now contains:
- 5 Regions with 22 Countries
- 150+ Stores worldwide
- 35 Categories (10 parent + 25 sub)
- 15 Brands
- 60+ Suppliers
- 5,000 Products
- 100,000 Customers
- 500,000 Orders with 1.5M+ line items
- Inventory data for stores

This data simulates a realistic retail environment and is ready for
ETL development in the next labs.
';
GO
