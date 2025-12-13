/*******************************************************************************
 * LAB 80: SQL Capstone - Fact Table ETL Implementation
 * Module 09: SQL Capstone Project
 * 
 * Objective: Implement ETL procedures for loading fact tables in the
 *            GlobalMart Data Warehouse with incremental processing.
 * 
 * Duration: 6-8 hours
 * 
 * Topics Covered:
 * - Fact table loading patterns
 * - Incremental ETL with watermark
 * - Dimension key lookups
 * - Aggregate fact tables
 ******************************************************************************/

USE GlobalMart_DW;
GO

/*******************************************************************************
 * PART 1: WATERMARK MANAGEMENT
 ******************************************************************************/

-- Create watermark table for incremental loads
IF OBJECT_ID('ETL.Watermark', 'U') IS NULL
BEGIN
    CREATE TABLE ETL.Watermark (
        TableName NVARCHAR(100) PRIMARY KEY,
        LastLoadDate DATETIME NOT NULL,
        LastKeyLoaded BIGINT NULL,
        UpdatedDate DATETIME DEFAULT GETDATE()
    );
    
    -- Initialize watermarks
    INSERT INTO ETL.Watermark (TableName, LastLoadDate)
    VALUES 
        ('FactSales', '2020-01-01'),
        ('FactInventory', '2020-01-01'),
        ('FactSalesAggregate', '2020-01-01');
END;
GO

-- Procedure to update watermark
CREATE OR ALTER PROCEDURE ETL.sp_UpdateWatermark
    @TableName NVARCHAR(100),
    @NewLoadDate DATETIME = NULL,
    @NewKeyLoaded BIGINT = NULL
AS
BEGIN
    UPDATE ETL.Watermark
    SET LastLoadDate = ISNULL(@NewLoadDate, GETDATE()),
        LastKeyLoaded = ISNULL(@NewKeyLoaded, LastKeyLoaded),
        UpdatedDate = GETDATE()
    WHERE TableName = @TableName;
END;
GO

/*******************************************************************************
 * PART 2: FACT TABLE STAGING
 ******************************************************************************/

-- Stage Sales Data
CREATE OR ALTER PROCEDURE ETL.sp_Stage_Sales
    @FromDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @RowCount INT;
    DECLARE @LastLoad DATETIME;
    
    -- Get last load date from watermark
    SELECT @LastLoad = ISNULL(@FromDate, LastLoadDate)
    FROM ETL.Watermark
    WHERE TableName = 'FactSales';
    
    EXEC ETL.sp_LogExecution 'Stage_Sales', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        TRUNCATE TABLE Staging.Sales;
        
        INSERT INTO Staging.Sales (
            OrderID, OrderDetailID, OrderDate, ShipDate, CustomerID, ProductID,
            StoreID, EmployeeID, PromotionID, Quantity, UnitPrice, Discount,
            LineTotal, Tax, Freight, OrderStatus, PaymentMethod
        )
        SELECT 
            o.OrderID,
            od.OrderDetailID,
            o.OrderDate,
            o.ShipDate,
            o.CustomerID,
            od.ProductID,
            o.StoreID,
            o.EmployeeID,
            od.PromotionID,
            od.Quantity,
            od.UnitPrice,
            od.Discount,
            od.LineTotal,
            o.TaxAmount / NULLIF((SELECT COUNT(*) FROM GlobalMart_OLTP.Sales.OrderDetails od2 WHERE od2.OrderID = o.OrderID), 0),
            o.FreightAmount / NULLIF((SELECT COUNT(*) FROM GlobalMart_OLTP.Sales.OrderDetails od2 WHERE od2.OrderID = o.OrderID), 0),
            o.OrderStatus,
            o.PaymentMethod
        FROM GlobalMart_OLTP.Sales.Orders o
        INNER JOIN GlobalMart_OLTP.Sales.OrderDetails od ON o.OrderID = od.OrderID
        WHERE o.ModifiedDate > @LastLoad
           OR od.ModifiedDate > @LastLoad;
        
        SET @RowCount = @@ROWCOUNT;
        
        EXEC ETL.sp_LogExecution 'Stage_Sales', 'Success', 
            @RowsExtracted = @RowCount, @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'Sales staged: ' + CAST(@RowCount AS VARCHAR) + ' rows (since ' + 
              CONVERT(VARCHAR, @LastLoad, 120) + ')';
        
    END TRY
    BEGIN CATCH
        EXEC ETL.sp_LogExecution 'Stage_Sales', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

-- Stage Inventory Data
CREATE OR ALTER PROCEDURE ETL.sp_Stage_Inventory
    @FromDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @RowCount INT;
    DECLARE @LastLoad DATETIME;
    
    SELECT @LastLoad = ISNULL(@FromDate, LastLoadDate)
    FROM ETL.Watermark
    WHERE TableName = 'FactInventory';
    
    EXEC ETL.sp_LogExecution 'Stage_Inventory', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        TRUNCATE TABLE Staging.Inventory;
        
        INSERT INTO Staging.Inventory (
            ProductID, StoreID, SnapshotDate, QuantityOnHand, ReorderLevel,
            QuantityOnOrder, UnitCost, InventoryValue
        )
        SELECT 
            i.ProductID,
            i.StoreID,
            CAST(GETDATE() AS DATE),
            i.QuantityOnHand,
            i.ReorderLevel,
            i.QuantityOnOrder,
            p.Cost,
            i.QuantityOnHand * p.Cost
        FROM GlobalMart_OLTP.Products.Inventory i
        INNER JOIN GlobalMart_OLTP.Products.Products p ON i.ProductID = p.ProductID
        WHERE i.ModifiedDate > @LastLoad;
        
        SET @RowCount = @@ROWCOUNT;
        
        EXEC ETL.sp_LogExecution 'Stage_Inventory', 'Success', 
            @RowsExtracted = @RowCount, @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'Inventory staged: ' + CAST(@RowCount AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        EXEC ETL.sp_LogExecution 'Stage_Inventory', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

/*******************************************************************************
 * PART 3: FACT TABLE LOAD PROCEDURES
 ******************************************************************************/

-- Load FactSales (Incremental)
CREATE OR ALTER PROCEDURE ETL.sp_Load_FactSales
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @InsertCount INT = 0;
    DECLARE @ErrorCount INT = 0;
    DECLARE @MaxOrderDate DATETIME;
    
    EXEC ETL.sp_LogExecution 'Load_FactSales', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Delete existing records for orders being reloaded (handle updates)
        DELETE fs
        FROM Fact.FactSales fs
        WHERE EXISTS (
            SELECT 1 FROM Staging.Sales stg 
            WHERE stg.OrderID = fs.OrderID AND stg.OrderDetailID = fs.OrderDetailID
        );
        
        -- Insert fact records with dimension key lookups
        INSERT INTO Fact.FactSales (
            OrderDateKey, ShipDateKey, CustomerKey, ProductKey, StoreKey,
            EmployeeKey, PromotionKey, OrderID, OrderDetailID, Quantity,
            UnitPrice, Discount, SalesAmount, CostAmount, GrossProfit,
            Tax, Freight, NetSales
        )
        SELECT 
            -- Date dimension lookups
            ISNULL(dd_order.DateKey, -1),
            ISNULL(dd_ship.DateKey, -1),
            -- SCD Type 2 lookups (get version current at order time)
            ISNULL(dc.CustomerKey, -1),
            ISNULL(dp.ProductKey, -1),
            ISNULL(ds.StoreKey, -1),
            ISNULL(de.EmployeeKey, -1),
            ISNULL(dpr.PromotionKey, -1),
            -- Degenerate dimensions
            stg.OrderID,
            stg.OrderDetailID,
            -- Measures
            stg.Quantity,
            stg.UnitPrice,
            stg.Discount,
            stg.LineTotal,
            stg.Quantity * ISNULL(dp.Cost, 0),
            stg.LineTotal - (stg.Quantity * ISNULL(dp.Cost, 0)),
            ISNULL(stg.Tax, 0),
            ISNULL(stg.Freight, 0),
            stg.LineTotal - ISNULL(stg.Tax, 0) - ISNULL(stg.Freight, 0)
        FROM Staging.Sales stg
        -- Date dimension joins
        LEFT JOIN Dim.DimDate dd_order ON CAST(stg.OrderDate AS DATE) = dd_order.FullDate
        LEFT JOIN Dim.DimDate dd_ship ON CAST(stg.ShipDate AS DATE) = dd_ship.FullDate
        -- SCD Type 2 joins (point-in-time lookup)
        LEFT JOIN Dim.DimCustomer dc 
            ON stg.CustomerID = dc.CustomerID
            AND CAST(stg.OrderDate AS DATE) >= dc.EffectiveDate
            AND CAST(stg.OrderDate AS DATE) <= dc.ExpiryDate
        LEFT JOIN Dim.DimProduct dp 
            ON stg.ProductID = dp.ProductID
            AND CAST(stg.OrderDate AS DATE) >= dp.EffectiveDate
            AND CAST(stg.OrderDate AS DATE) <= dp.ExpiryDate
        LEFT JOIN Dim.DimStore ds 
            ON stg.StoreID = ds.StoreID
            AND CAST(stg.OrderDate AS DATE) >= ds.EffectiveDate
            AND CAST(stg.OrderDate AS DATE) <= ds.ExpiryDate
        LEFT JOIN Dim.DimEmployee de 
            ON stg.EmployeeID = de.EmployeeID
            AND CAST(stg.OrderDate AS DATE) >= de.EffectiveDate
            AND CAST(stg.OrderDate AS DATE) <= de.ExpiryDate
        LEFT JOIN Dim.DimPromotion dpr ON stg.PromotionID = dpr.PromotionID;
        
        SET @InsertCount = @@ROWCOUNT;
        
        -- Get max order date for watermark
        SELECT @MaxOrderDate = MAX(OrderDate)
        FROM Staging.Sales;
        
        -- Update watermark
        IF @MaxOrderDate IS NOT NULL
        BEGIN
            EXEC ETL.sp_UpdateWatermark 'FactSales', @MaxOrderDate;
        END
        
        COMMIT TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_FactSales', 'Success', 
            @RowsInserted = @InsertCount, @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'FactSales: ' + CAST(@InsertCount AS VARCHAR) + ' rows loaded';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_FactSales', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

-- Load FactInventory (Snapshot)
CREATE OR ALTER PROCEDURE ETL.sp_Load_FactInventory
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @InsertCount INT = 0;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    
    EXEC ETL.sp_LogExecution 'Load_FactInventory', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if today's snapshot already exists
        IF EXISTS (
            SELECT 1 FROM Fact.FactInventory fi
            INNER JOIN Dim.DimDate dd ON fi.DateKey = dd.DateKey
            WHERE dd.FullDate = @Today
        )
        BEGIN
            -- Delete today's snapshot for reload
            DELETE fi
            FROM Fact.FactInventory fi
            INNER JOIN Dim.DimDate dd ON fi.DateKey = dd.DateKey
            WHERE dd.FullDate = @Today;
        END
        
        -- Insert daily inventory snapshot
        INSERT INTO Fact.FactInventory (
            DateKey, ProductKey, StoreKey, QuantityOnHand, ReorderLevel,
            QuantityOnOrder, UnitCost, InventoryValue, DaysOfSupply
        )
        SELECT 
            ISNULL(dd.DateKey, -1),
            ISNULL(dp.ProductKey, -1),
            ISNULL(ds.StoreKey, -1),
            stg.QuantityOnHand,
            stg.ReorderLevel,
            stg.QuantityOnOrder,
            stg.UnitCost,
            stg.InventoryValue,
            -- Calculate days of supply based on average daily sales
            CASE 
                WHEN ISNULL(avg_sales.AvgDailySales, 0) > 0 
                THEN stg.QuantityOnHand / avg_sales.AvgDailySales
                ELSE 999
            END
        FROM Staging.Inventory stg
        INNER JOIN Dim.DimDate dd ON stg.SnapshotDate = dd.FullDate
        LEFT JOIN Dim.DimProduct dp 
            ON stg.ProductID = dp.ProductID AND dp.IsCurrent = 1
        LEFT JOIN Dim.DimStore ds 
            ON stg.StoreID = ds.StoreID AND ds.IsCurrent = 1
        -- Calculate average daily sales for days of supply
        OUTER APPLY (
            SELECT AVG(CAST(fs.Quantity AS FLOAT)) AS AvgDailySales
            FROM Fact.FactSales fs
            INNER JOIN Dim.DimDate d ON fs.OrderDateKey = d.DateKey
            WHERE fs.ProductKey = dp.ProductKey 
              AND fs.StoreKey = ds.StoreKey
              AND d.FullDate >= DATEADD(DAY, -90, @Today)
        ) avg_sales;
        
        SET @InsertCount = @@ROWCOUNT;
        
        -- Update watermark
        EXEC ETL.sp_UpdateWatermark 'FactInventory';
        
        COMMIT TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_FactInventory', 'Success', 
            @RowsInserted = @InsertCount, @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'FactInventory: ' + CAST(@InsertCount AS VARCHAR) + ' rows loaded';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Load_FactInventory', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

/*******************************************************************************
 * PART 4: AGGREGATE FACT TABLE
 ******************************************************************************/

-- Refresh Daily Sales Aggregate
CREATE OR ALTER PROCEDURE ETL.sp_Refresh_FactSalesAggregate
    @FromDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    DECLARE @InsertCount INT = 0;
    DECLARE @DeleteCount INT = 0;
    DECLARE @StartDate DATE;
    
    -- Default to last 7 days if not specified
    SET @StartDate = ISNULL(@FromDate, DATEADD(DAY, -7, CAST(GETDATE() AS DATE)));
    
    EXEC ETL.sp_LogExecution 'Refresh_FactSalesAggregate', 'Running', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Delete existing aggregates for the date range
        DELETE fsa
        FROM Fact.FactSalesAggregate fsa
        INNER JOIN Dim.DimDate dd ON fsa.DateKey = dd.DateKey
        WHERE dd.FullDate >= @StartDate;
        
        SET @DeleteCount = @@ROWCOUNT;
        
        -- Rebuild aggregates
        INSERT INTO Fact.FactSalesAggregate (
            DateKey, ProductKey, StoreKey, CustomerSegmentKey,
            OrderCount, LineItemCount, TotalQuantity, TotalSalesAmount,
            TotalCostAmount, TotalGrossProfit, TotalDiscount,
            AvgOrderValue, AvgItemsPerOrder
        )
        SELECT 
            fs.OrderDateKey,
            fs.ProductKey,
            fs.StoreKey,
            dc.CustomerKey AS CustomerSegmentKey,
            COUNT(DISTINCT fs.OrderID),
            COUNT(*),
            SUM(fs.Quantity),
            SUM(fs.SalesAmount),
            SUM(fs.CostAmount),
            SUM(fs.GrossProfit),
            SUM(fs.Discount * fs.Quantity),
            SUM(fs.SalesAmount) / NULLIF(COUNT(DISTINCT fs.OrderID), 0),
            CAST(COUNT(*) AS FLOAT) / NULLIF(COUNT(DISTINCT fs.OrderID), 0)
        FROM Fact.FactSales fs
        INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
        LEFT JOIN Dim.DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
        WHERE dd.FullDate >= @StartDate
        GROUP BY 
            fs.OrderDateKey,
            fs.ProductKey,
            fs.StoreKey,
            dc.CustomerKey;
        
        SET @InsertCount = @@ROWCOUNT;
        
        -- Update watermark
        EXEC ETL.sp_UpdateWatermark 'FactSalesAggregate';
        
        COMMIT TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Refresh_FactSalesAggregate', 'Success', 
            @RowsInserted = @InsertCount, @RowsUpdated = @DeleteCount, 
            @ExecutionID = @ExecutionID OUTPUT;
        
        PRINT 'FactSalesAggregate: ' + CAST(@DeleteCount AS VARCHAR) + ' deleted, ' +
              CAST(@InsertCount AS VARCHAR) + ' inserted';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        EXEC ETL.sp_LogExecution 'Refresh_FactSalesAggregate', 'Failed', 
            @ErrorMessage = ERROR_MESSAGE(), @ExecutionID = @ExecutionID OUTPUT;
        THROW;
    END CATCH
END;
GO

/*******************************************************************************
 * PART 5: MASTER FACT LOAD PROCEDURE
 ******************************************************************************/

CREATE OR ALTER PROCEDURE ETL.sp_Load_AllFacts
    @FullLoad BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartDate DATETIME = NULL;
    
    -- For full load, reset watermarks
    IF @FullLoad = 1
    BEGIN
        UPDATE ETL.Watermark SET LastLoadDate = '2020-01-01';
        SET @StartDate = '2020-01-01';
    END
    
    PRINT '=== Starting Fact Table Load ===';
    PRINT 'Mode: ' + CASE WHEN @FullLoad = 1 THEN 'Full Load' ELSE 'Incremental' END;
    PRINT 'Start Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '';
    
    -- Stage data
    PRINT '--- Staging Phase ---';
    EXEC ETL.sp_Stage_Sales @FromDate = @StartDate;
    EXEC ETL.sp_Stage_Inventory @FromDate = @StartDate;
    
    PRINT '';
    PRINT '--- Fact Load Phase ---';
    
    -- Load facts
    EXEC ETL.sp_Load_FactSales;
    EXEC ETL.sp_Load_FactInventory;
    
    PRINT '';
    PRINT '--- Aggregate Refresh Phase ---';
    EXEC ETL.sp_Refresh_FactSalesAggregate;
    
    PRINT '';
    PRINT '=== Fact Load Complete ===';
    PRINT 'End Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
END;
GO

/*******************************************************************************
 * PART 6: COMPLETE ETL ORCHESTRATION
 ******************************************************************************/

-- Master ETL procedure that runs everything
CREATE OR ALTER PROCEDURE ETL.sp_RunFullETL
    @FullLoad BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    
    PRINT '===============================================================';
    PRINT ' GLOBALMART DATA WAREHOUSE - ETL EXECUTION';
    PRINT '===============================================================';
    PRINT 'Execution Started: ' + CONVERT(VARCHAR, @StartTime, 120);
    PRINT 'Mode: ' + CASE WHEN @FullLoad = 1 THEN 'FULL LOAD' ELSE 'INCREMENTAL' END;
    PRINT '';
    
    -- Step 1: Load Dimensions
    PRINT '>>> PHASE 1: DIMENSION LOAD <<<';
    EXEC ETL.sp_Load_AllDimensions;
    
    PRINT '';
    
    -- Step 2: Load Facts
    PRINT '>>> PHASE 2: FACT LOAD <<<';
    EXEC ETL.sp_Load_AllFacts @FullLoad = @FullLoad;
    
    PRINT '';
    PRINT '===============================================================';
    PRINT ' ETL EXECUTION COMPLETE';
    PRINT '===============================================================';
    PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR) + ' seconds';
    PRINT '';
END;
GO

/*******************************************************************************
 * PART 7: EXECUTE AND VERIFY
 ******************************************************************************/

-- Execute full ETL
EXEC ETL.sp_RunFullETL @FullLoad = 1;
GO

-- Verify fact table counts
SELECT 'FactSales' AS FactTable, COUNT(*) AS RowCount FROM Fact.FactSales
UNION ALL
SELECT 'FactInventory', COUNT(*) FROM Fact.FactInventory
UNION ALL
SELECT 'FactSalesAggregate', COUNT(*) FROM Fact.FactSalesAggregate;

-- Verify watermarks
SELECT * FROM ETL.Watermark;

-- Sample data quality check
SELECT 
    'Orphan Records Check' AS CheckName,
    SUM(CASE WHEN CustomerKey = -1 THEN 1 ELSE 0 END) AS MissingCustomer,
    SUM(CASE WHEN ProductKey = -1 THEN 1 ELSE 0 END) AS MissingProduct,
    SUM(CASE WHEN StoreKey = -1 THEN 1 ELSE 0 END) AS MissingStore,
    SUM(CASE WHEN OrderDateKey = -1 THEN 1 ELSE 0 END) AS MissingDate
FROM Fact.FactSales;

PRINT '
=============================================================================
LAB 80 COMPLETE - FACT TABLE ETL IMPLEMENTED
=============================================================================

Created procedures:
- ETL.sp_Stage_Sales (Incremental staging)
- ETL.sp_Stage_Inventory (Incremental staging)
- ETL.sp_Load_FactSales (Transaction fact with SCD lookups)
- ETL.sp_Load_FactInventory (Periodic snapshot fact)
- ETL.sp_Refresh_FactSalesAggregate (Aggregate maintenance)
- ETL.sp_Load_AllFacts (Master fact loader)
- ETL.sp_RunFullETL (Complete ETL orchestration)

Key features:
- Watermark-based incremental loading
- Point-in-time SCD Type 2 lookups
- Error handling and logging
- Full/incremental load modes

Next: Lab 81 - Reporting Layer
';
GO
