/*******************************************************************************
 * LAB 79: SQL Capstone - Dimension ETL Implementation
 * Module 09: SQL Capstone Project
 * 
 * Objective: Implement ETL procedures for loading dimension tables in the
 *            GlobalMart Data Warehouse using SCD Type 1 and Type 2 patterns.
 * 
 * Duration: 6-8 hours
 * 
 * Topics Covered:
 * - Staging layer population
 * - SCD Type 1 dimension loading
 * - SCD Type 2 dimension loading
 * - Error handling and logging
 ******************************************************************************/

USE GlobalMart_DW;
GO

/*******************************************************************************
 * PART 1: ETL HELPER PROCEDURES
 ******************************************************************************/

-- Procedure to log ETL execution
CREATE OR ALTER PROCEDURE ETL.sp_LogExecution
    @PackageName NVARCHAR(100),
    @Status NVARCHAR(20),
    @RowsExtracted INT = NULL,
    @RowsInserted INT = NULL,
    @RowsUpdated INT = NULL,
    @RowsRejected INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @ExecutionID INT OUTPUT
AS
BEGIN
    IF @Status = 'Running'
    BEGIN
        INSERT INTO ETL.ExecutionLog (PackageName, ExecutionStartTime, Status, MachineName)
        VALUES (@PackageName, GETDATE(), @Status, @@SERVERNAME);
        
        SET @ExecutionID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE ETL.ExecutionLog
        SET ExecutionEndTime = GETDATE(),
            Status = @Status,
            RowsExtracted = ISNULL(@RowsExtracted, RowsExtracted),
            RowsInserted = ISNULL(@RowsInserted, RowsInserted),
            RowsUpdated = ISNULL(@RowsUpdated, RowsUpdated),
            RowsRejected = ISNULL(@RowsRejected, RowsRejected),
            ErrorMessage = @ErrorMessage
        WHERE ExecutionID = @ExecutionID;
    END
END;
GO

-- Procedure to log ETL errors
CREATE OR ALTER PROCEDURE ETL.sp_LogError
    @ExecutionID INT,
    @SourceTable NVARCHAR(100),
    @SourceKey NVARCHAR(100),
    @ErrorCode INT,
    @ErrorMessage NVARCHAR(MAX),
    @ErrorData NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO ETL.ErrorLog (ExecutionID, SourceTable, SourceKey, ErrorCode, ErrorMessage, ErrorData)
    VALUES (@ExecutionID, @SourceTable, @SourceKey, @ErrorCode, @ErrorMessage, @ErrorData);
END;
GO

/*******************************************************************************
 * PART 2: STAGING PROCEDURES
 ******************************************************************************/

-- Extract Customers to Staging
CREATE OR ALTER PROCEDURE ETL.sp_Stage_Customers
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @RowCount INT;
    
    EXEC ETL.sp_LogExecution 'Stage_Customers', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        -- Truncate staging table
        TRUNCATE TABLE Staging.Customers;
        
        -- Extract from OLTP
        INSERT INTO Staging.Customers (
            CustomerID, FirstName, LastName, Email, Phone, DateOfBirth, Gender,
            Address, City, State, PostalCode, CountryName, RegionName, 
            SegmentName, JoinDate, IsActive, SourceModifiedDate
        )
        SELECT 
            c.CustomerID,
            c.FirstName,
            c.LastName,
            c.Email,
            c.Phone,
            c.DateOfBirth,
            c.Gender,
            c.Address,
            c.City,
            c.State,
            c.PostalCode,
            co.CountryName,
            r.RegionName,
            cs.SegmentName,
            c.JoinDate,
            c.IsActive,
            c.ModifiedDate
        FROM GlobalMart_OLTP.Sales.Customers c
        LEFT JOIN GlobalMart_OLTP.HR.Countries co ON c.CountryID = co.CountryID
        LEFT JOIN GlobalMart_OLTP.HR.Regions r ON co.RegionID = r.RegionID
        LEFT JOIN GlobalMart_OLTP.Sales.CustomerSegments cs ON c.SegmentID = cs.SegmentID;
        
        SET @RowCount = @@ROWCOUNT;
        
        EXEC ETL.sp_LogExecution 'Stage_Customers', 'Success', 
            @RowsExtracted = @RowCount, @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'Customers staged: ' + CAST(@RowCount AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        EXEC ETL.sp_LogExecution 'Stage_Customers', 'Failed', 
            @ErrorMessage = @RowCount, @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

-- Extract Products to Staging
CREATE OR ALTER PROCEDURE ETL.sp_Stage_Products
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @RowCount INT;
    
    EXEC ETL.sp_LogExecution 'Stage_Products', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        TRUNCATE TABLE Staging.Products;
        
        INSERT INTO Staging.Products (
            ProductID, ProductName, ProductCode, CategoryName, ParentCategoryName,
            BrandName, SupplierName, UnitPrice, Cost, Weight, Size, Color,
            IsActive, SourceModifiedDate
        )
        SELECT 
            p.ProductID,
            p.ProductName,
            p.ProductCode,
            c.CategoryName,
            pc.CategoryName AS ParentCategoryName,
            b.BrandName,
            s.CompanyName AS SupplierName,
            p.UnitPrice,
            p.Cost,
            p.Weight,
            p.Size,
            p.Color,
            p.IsActive,
            p.ModifiedDate
        FROM GlobalMart_OLTP.Products.Products p
        LEFT JOIN GlobalMart_OLTP.Products.Categories c ON p.CategoryID = c.CategoryID
        LEFT JOIN GlobalMart_OLTP.Products.Categories pc ON c.ParentCategoryID = pc.CategoryID
        LEFT JOIN GlobalMart_OLTP.Products.Brands b ON p.BrandID = b.BrandID
        LEFT JOIN GlobalMart_OLTP.Products.Suppliers s ON p.SupplierID = s.SupplierID;
        
        SET @RowCount = @@ROWCOUNT;
        
        EXEC ETL.sp_LogExecution 'Stage_Products', 'Success', 
            @RowsExtracted = @RowCount, @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'Products staged: ' + CAST(@RowCount AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        EXEC ETL.sp_LogExecution 'Stage_Products', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

-- Extract Stores to Staging
CREATE OR ALTER PROCEDURE ETL.sp_Stage_Stores
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @RowCount INT;
    
    EXEC ETL.sp_LogExecution 'Stage_Stores', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        TRUNCATE TABLE Staging.Stores;
        
        INSERT INTO Staging.Stores (
            StoreID, StoreName, StoreCode, CountryName, RegionName,
            City, Address, OpenDate, SquareFeet, IsActive, SourceModifiedDate
        )
        SELECT 
            s.StoreID,
            s.StoreName,
            s.StoreCode,
            c.CountryName,
            r.RegionName,
            s.City,
            s.Address,
            s.OpenDate,
            s.SquareFeet,
            s.IsActive,
            s.ModifiedDate
        FROM GlobalMart_OLTP.HR.Stores s
        LEFT JOIN GlobalMart_OLTP.HR.Countries c ON s.CountryID = c.CountryID
        LEFT JOIN GlobalMart_OLTP.HR.Regions r ON c.RegionID = r.RegionID;
        
        SET @RowCount = @@ROWCOUNT;
        
        EXEC ETL.sp_LogExecution 'Stage_Stores', 'Success', 
            @RowsExtracted = @RowCount, @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'Stores staged: ' + CAST(@RowCount AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        EXEC ETL.sp_LogExecution 'Stage_Stores', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

/*******************************************************************************
 * PART 3: DIMENSION LOAD PROCEDURES - SCD TYPE 2
 ******************************************************************************/

-- Load DimCustomer (SCD Type 2)
CREATE OR ALTER PROCEDURE ETL.sp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @InsertCount INT = 0;
    DECLARE @UpdateCount INT = 0;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    
    EXEC ETL.sp_LogExecution 'Load_DimCustomer', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Step 1: Expire changed records (SCD Type 2)
        UPDATE dim
        SET dim.ExpiryDate = DATEADD(DAY, -1, @Today),
            dim.IsCurrent = 0,
            dim.ETLUpdateDate = GETDATE()
        FROM Dim.DimCustomer dim
        INNER JOIN Staging.Customers stg ON dim.CustomerID = stg.CustomerID
        WHERE dim.IsCurrent = 1
          AND (
              dim.Segment <> ISNULL(stg.SegmentName, 'Unknown')
              OR dim.City <> ISNULL(stg.City, 'Unknown')
              OR dim.State <> ISNULL(stg.State, 'Unknown')
              OR dim.Country <> ISNULL(stg.CountryName, 'Unknown')
          );
        
        SET @UpdateCount = @@ROWCOUNT;
        
        -- Step 2: Insert new versions for changed records + new records
        INSERT INTO Dim.DimCustomer (
            CustomerID, CustomerName, Email, Phone, DateOfBirth, Gender,
            Address, City, State, PostalCode, Country, Region, Segment,
            AgeGroup, JoinDate, TenureYears, IsActive, EffectiveDate, ExpiryDate, IsCurrent
        )
        SELECT 
            stg.CustomerID,
            ISNULL(stg.FirstName, '') + ' ' + ISNULL(stg.LastName, ''),
            stg.Email,
            stg.Phone,
            stg.DateOfBirth,
            CASE stg.Gender 
                WHEN 'M' THEN 'Male' 
                WHEN 'F' THEN 'Female' 
                ELSE 'Unknown' 
            END,
            stg.Address,
            ISNULL(stg.City, 'Unknown'),
            ISNULL(stg.State, 'Unknown'),
            stg.PostalCode,
            ISNULL(stg.CountryName, 'Unknown'),
            ISNULL(stg.RegionName, 'Unknown'),
            ISNULL(stg.SegmentName, 'Unknown'),
            CASE 
                WHEN stg.DateOfBirth IS NULL THEN 'Unknown'
                WHEN DATEDIFF(YEAR, stg.DateOfBirth, GETDATE()) < 25 THEN '18-24'
                WHEN DATEDIFF(YEAR, stg.DateOfBirth, GETDATE()) < 35 THEN '25-34'
                WHEN DATEDIFF(YEAR, stg.DateOfBirth, GETDATE()) < 45 THEN '35-44'
                WHEN DATEDIFF(YEAR, stg.DateOfBirth, GETDATE()) < 55 THEN '45-54'
                WHEN DATEDIFF(YEAR, stg.DateOfBirth, GETDATE()) < 65 THEN '55-64'
                ELSE '65+'
            END,
            stg.JoinDate,
            DATEDIFF(YEAR, stg.JoinDate, GETDATE()),
            stg.IsActive,
            @Today,
            '9999-12-31',
            1
        FROM Staging.Customers stg
        LEFT JOIN Dim.DimCustomer dim ON stg.CustomerID = dim.CustomerID AND dim.IsCurrent = 1
        WHERE dim.CustomerKey IS NULL; -- New or changed records (current version expired)
        
        SET @InsertCount = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_DimCustomer', 'Success', 
            @RowsInserted = @InsertCount, @RowsUpdated = @UpdateCount, 
            @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'DimCustomer: ' + CAST(@InsertCount AS VARCHAR) + ' inserted, ' + 
              CAST(@UpdateCount AS VARCHAR) + ' expired';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_DimCustomer', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

-- Load DimProduct (SCD Type 2)
CREATE OR ALTER PROCEDURE ETL.sp_Load_DimProduct
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @InsertCount INT = 0;
    DECLARE @UpdateCount INT = 0;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    
    EXEC ETL.sp_LogExecution 'Load_DimProduct', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Step 1: Expire changed records (price changes trigger new version)
        UPDATE dim
        SET dim.ExpiryDate = DATEADD(DAY, -1, @Today),
            dim.IsCurrent = 0,
            dim.ETLUpdateDate = GETDATE()
        FROM Dim.DimProduct dim
        INNER JOIN Staging.Products stg ON dim.ProductID = stg.ProductID
        WHERE dim.IsCurrent = 1
          AND (
              dim.UnitPrice <> stg.UnitPrice
              OR dim.Cost <> stg.Cost
              OR dim.Category <> ISNULL(stg.CategoryName, 'Unknown')
          );
        
        SET @UpdateCount = @@ROWCOUNT;
        
        -- Step 2: Insert new versions + new products
        INSERT INTO Dim.DimProduct (
            ProductID, ProductName, ProductCode, Category, ParentCategory,
            Brand, Supplier, UnitPrice, Cost, Weight, Size, Color,
            PriceRange, IsActive, EffectiveDate, ExpiryDate, IsCurrent
        )
        SELECT 
            stg.ProductID,
            stg.ProductName,
            stg.ProductCode,
            ISNULL(stg.CategoryName, 'Unknown'),
            ISNULL(stg.ParentCategoryName, 'Unknown'),
            ISNULL(stg.BrandName, 'Unknown'),
            ISNULL(stg.SupplierName, 'Unknown'),
            stg.UnitPrice,
            stg.Cost,
            stg.Weight,
            stg.Size,
            stg.Color,
            CASE 
                WHEN stg.UnitPrice < 25 THEN 'Budget'
                WHEN stg.UnitPrice < 100 THEN 'Mid-Range'
                WHEN stg.UnitPrice < 500 THEN 'Premium'
                ELSE 'Luxury'
            END,
            stg.IsActive,
            @Today,
            '9999-12-31',
            1
        FROM Staging.Products stg
        LEFT JOIN Dim.DimProduct dim ON stg.ProductID = dim.ProductID AND dim.IsCurrent = 1
        WHERE dim.ProductKey IS NULL;
        
        SET @InsertCount = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_DimProduct', 'Success', 
            @RowsInserted = @InsertCount, @RowsUpdated = @UpdateCount, 
            @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'DimProduct: ' + CAST(@InsertCount AS VARCHAR) + ' inserted, ' + 
              CAST(@UpdateCount AS VARCHAR) + ' expired';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_DimProduct', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

-- Load DimStore (SCD Type 2)
CREATE OR ALTER PROCEDURE ETL.sp_Load_DimStore
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @InsertCount INT = 0;
    DECLARE @UpdateCount INT = 0;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    
    EXEC ETL.sp_LogExecution 'Load_DimStore', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Expire changed stores
        UPDATE dim
        SET dim.ExpiryDate = DATEADD(DAY, -1, @Today),
            dim.IsCurrent = 0,
            dim.ETLUpdateDate = GETDATE()
        FROM Dim.DimStore dim
        INNER JOIN Staging.Stores stg ON dim.StoreID = stg.StoreID
        WHERE dim.IsCurrent = 1
          AND dim.IsActive <> stg.IsActive;
        
        SET @UpdateCount = @@ROWCOUNT;
        
        -- Insert new stores and new versions
        INSERT INTO Dim.DimStore (
            StoreID, StoreName, StoreCode, Country, Region, City, Address,
            OpenDate, SquareFeet, StoreSize, StoreAge, IsActive, 
            EffectiveDate, ExpiryDate, IsCurrent
        )
        SELECT 
            stg.StoreID,
            stg.StoreName,
            stg.StoreCode,
            ISNULL(stg.CountryName, 'Unknown'),
            ISNULL(stg.RegionName, 'Unknown'),
            stg.City,
            stg.Address,
            stg.OpenDate,
            stg.SquareFeet,
            CASE 
                WHEN stg.SquareFeet < 10000 THEN 'Small'
                WHEN stg.SquareFeet < 30000 THEN 'Medium'
                ELSE 'Large'
            END,
            DATEDIFF(YEAR, stg.OpenDate, GETDATE()),
            stg.IsActive,
            @Today,
            '9999-12-31',
            1
        FROM Staging.Stores stg
        LEFT JOIN Dim.DimStore dim ON stg.StoreID = dim.StoreID AND dim.IsCurrent = 1
        WHERE dim.StoreKey IS NULL;
        
        SET @InsertCount = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_DimStore', 'Success', 
            @RowsInserted = @InsertCount, @RowsUpdated = @UpdateCount, 
            @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'DimStore: ' + CAST(@InsertCount AS VARCHAR) + ' inserted, ' + 
              CAST(@UpdateCount AS VARCHAR) + ' expired';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_DimStore', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

-- Load DimPromotion (SCD Type 1 - overwrite)
CREATE OR ALTER PROCEDURE ETL.sp_Load_DimPromotion
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @InsertCount INT = 0;
    DECLARE @UpdateCount INT = 0;
    
    EXEC ETL.sp_LogExecution 'Load_DimPromotion', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        -- Update existing promotions (SCD Type 1)
        UPDATE dim
        SET dim.PromotionName = src.PromotionName,
            dim.Description = src.Description,
            dim.DiscountType = src.DiscountType,
            dim.DiscountValue = src.DiscountValue,
            dim.StartDate = src.StartDate,
            dim.EndDate = src.EndDate,
            dim.IsActive = src.IsActive,
            dim.ETLLoadDate = GETDATE()
        FROM Dim.DimPromotion dim
        INNER JOIN GlobalMart_OLTP.Sales.Promotions src ON dim.PromotionID = src.PromotionID
        WHERE dim.PromotionName <> src.PromotionName
           OR dim.DiscountValue <> src.DiscountValue;
        
        SET @UpdateCount = @@ROWCOUNT;
        
        -- Insert new promotions
        INSERT INTO Dim.DimPromotion (
            PromotionID, PromotionName, Description, DiscountType,
            DiscountValue, StartDate, EndDate, IsActive
        )
        SELECT 
            src.PromotionID,
            src.PromotionName,
            src.Description,
            src.DiscountType,
            src.DiscountValue,
            src.StartDate,
            src.EndDate,
            src.IsActive
        FROM GlobalMart_OLTP.Sales.Promotions src
        LEFT JOIN Dim.DimPromotion dim ON src.PromotionID = dim.PromotionID
        WHERE dim.PromotionKey IS NULL;
        
        SET @InsertCount = @@ROWCOUNT;
        
        EXEC ETL.sp_LogExecution 'Load_DimPromotion', 'Success', 
            @RowsInserted = @InsertCount, @RowsUpdated = @UpdateCount, 
            @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'DimPromotion: ' + CAST(@InsertCount AS VARCHAR) + ' inserted, ' + 
              CAST(@UpdateCount AS VARCHAR) + ' updated';
        
    END TRY
    BEGIN CATCH
        EXEC ETL.sp_LogExecution 'Load_DimPromotion', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

/*******************************************************************************
 * PART 4: MASTER DIMENSION LOAD PROCEDURE
 ******************************************************************************/

CREATE OR ALTER PROCEDURE ETL.sp_Load_AllDimensions
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== Starting Dimension Load ===';
    PRINT 'Start Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '';
    
    -- Stage data
    PRINT '--- Staging Phase ---';
    EXEC ETL.sp_Stage_Customers;
    EXEC ETL.sp_Stage_Products;
    EXEC ETL.sp_Stage_Stores;
    
    PRINT '';
    PRINT '--- Dimension Load Phase ---';
    
    -- Load dimensions
    EXEC ETL.sp_Load_DimCustomer;
    EXEC ETL.sp_Load_DimProduct;
    EXEC ETL.sp_Load_DimStore;
    EXEC ETL.sp_Load_DimPromotion;
    
    PRINT '';
    PRINT '=== Dimension Load Complete ===';
    PRINT 'End Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
END;
GO

/*******************************************************************************
 * PART 5: EXECUTE AND VERIFY
 ******************************************************************************/

-- Execute dimension load
EXEC ETL.sp_Load_AllDimensions;
GO

-- Verify dimension counts
SELECT 'DimCustomer' AS Dimension, COUNT(*) AS TotalRows, SUM(CAST(IsCurrent AS INT)) AS CurrentRows FROM Dim.DimCustomer
UNION ALL
SELECT 'DimProduct', COUNT(*), SUM(CAST(IsCurrent AS INT)) FROM Dim.DimProduct
UNION ALL
SELECT 'DimStore', COUNT(*), SUM(CAST(IsCurrent AS INT)) FROM Dim.DimStore
UNION ALL
SELECT 'DimPromotion', COUNT(*), COUNT(*) FROM Dim.DimPromotion
UNION ALL
SELECT 'DimDate', COUNT(*), COUNT(*) FROM Dim.DimDate;

-- Verify ETL execution log
SELECT TOP 10 
    ExecutionID,
    PackageName,
    Status,
    RowsExtracted,
    RowsInserted,
    RowsUpdated,
    DATEDIFF(SECOND, ExecutionStartTime, ExecutionEndTime) AS DurationSeconds
FROM ETL.ExecutionLog
ORDER BY ExecutionID DESC;

PRINT '
=============================================================================
LAB 79 COMPLETE - DIMENSION ETL IMPLEMENTED
=============================================================================

Created procedures:
- ETL.sp_Stage_Customers
- ETL.sp_Stage_Products
- ETL.sp_Stage_Stores
- ETL.sp_Load_DimCustomer (SCD Type 2)
- ETL.sp_Load_DimProduct (SCD Type 2)
- ETL.sp_Load_DimStore (SCD Type 2)
- ETL.sp_Load_DimPromotion (SCD Type 1)
- ETL.sp_Load_AllDimensions (Master procedure)

Next: Lab 80 - Fact Table ETL
';
GO
