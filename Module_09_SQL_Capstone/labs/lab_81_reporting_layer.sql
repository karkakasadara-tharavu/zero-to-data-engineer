/*******************************************************************************
 * LAB 81: SQL Capstone - Reporting Layer Implementation
 * Module 09: SQL Capstone Project
 * 
 * Objective: Create comprehensive reporting views, stored procedures, and
 *            materialized reporting tables for the GlobalMart Data Warehouse.
 * 
 * Duration: 6-8 hours
 * 
 * Topics Covered:
 * - Reporting views for BI tools
 * - Indexed views for performance
 * - Pre-aggregated reporting tables
 * - Parameterized report procedures
 ******************************************************************************/

USE GlobalMart_DW;
GO

-- Create Reports schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Reports')
    EXEC('CREATE SCHEMA Reports');
GO

/*******************************************************************************
 * PART 1: BASE REPORTING VIEWS
 ******************************************************************************/

-- Sales Detail View (Denormalized for reporting)
CREATE OR ALTER VIEW Reports.vw_SalesDetail
AS
SELECT 
    -- Date attributes
    dd.FullDate AS OrderDate,
    dd.Year AS OrderYear,
    dd.Quarter AS OrderQuarter,
    dd.MonthName AS OrderMonth,
    dd.MonthNumber AS OrderMonthNum,
    dd.WeekOfYear AS OrderWeek,
    dd.DayName AS OrderDayName,
    dd.IsWeekend,
    dd.IsHoliday,
    
    -- Customer attributes
    dc.CustomerKey,
    dc.CustomerID,
    dc.CustomerName,
    dc.Email AS CustomerEmail,
    dc.City AS CustomerCity,
    dc.State AS CustomerState,
    dc.Country AS CustomerCountry,
    dc.Region AS CustomerRegion,
    dc.Segment AS CustomerSegment,
    dc.AgeGroup AS CustomerAgeGroup,
    dc.TenureYears AS CustomerTenure,
    
    -- Product attributes
    dp.ProductKey,
    dp.ProductID,
    dp.ProductName,
    dp.ProductCode,
    dp.Category,
    dp.ParentCategory,
    dp.Brand,
    dp.Supplier,
    dp.PriceRange,
    
    -- Store attributes
    ds.StoreKey,
    ds.StoreID,
    ds.StoreName,
    ds.StoreCode,
    ds.City AS StoreCity,
    ds.Country AS StoreCountry,
    ds.Region AS StoreRegion,
    ds.StoreSize,
    
    -- Employee attributes
    de.EmployeeKey,
    de.EmployeeID,
    de.EmployeeName,
    de.Department,
    de.JobTitle,
    
    -- Promotion attributes
    dpr.PromotionKey,
    dpr.PromotionName,
    dpr.DiscountType,
    dpr.DiscountValue AS PromotionDiscount,
    
    -- Measures
    fs.OrderID,
    fs.OrderDetailID,
    fs.Quantity,
    fs.UnitPrice,
    fs.Discount,
    fs.SalesAmount,
    fs.CostAmount,
    fs.GrossProfit,
    fs.Tax,
    fs.Freight,
    fs.NetSales,
    
    -- Calculated measures
    CASE WHEN fs.SalesAmount > 0 
         THEN (fs.GrossProfit / fs.SalesAmount) * 100 
         ELSE 0 
    END AS GrossProfitMarginPct,
    fs.SalesAmount - fs.CostAmount - fs.Tax - fs.Freight AS NetProfit

FROM Fact.FactSales fs
INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
LEFT JOIN Dim.DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
LEFT JOIN Dim.DimProduct dp ON fs.ProductKey = dp.ProductKey
LEFT JOIN Dim.DimStore ds ON fs.StoreKey = ds.StoreKey
LEFT JOIN Dim.DimEmployee de ON fs.EmployeeKey = de.EmployeeKey
LEFT JOIN Dim.DimPromotion dpr ON fs.PromotionKey = dpr.PromotionKey;
GO

-- Inventory Status View
CREATE OR ALTER VIEW Reports.vw_InventoryStatus
AS
SELECT 
    dd.FullDate AS SnapshotDate,
    dd.Year,
    dd.Quarter,
    dd.MonthName,
    
    dp.ProductKey,
    dp.ProductName,
    dp.Category,
    dp.Brand,
    dp.PriceRange,
    
    ds.StoreKey,
    ds.StoreName,
    ds.StoreCity,
    ds.StoreRegion,
    
    fi.QuantityOnHand,
    fi.ReorderLevel,
    fi.QuantityOnOrder,
    fi.UnitCost,
    fi.InventoryValue,
    fi.DaysOfSupply,
    
    -- Stock status calculation
    CASE 
        WHEN fi.QuantityOnHand = 0 THEN 'Out of Stock'
        WHEN fi.QuantityOnHand <= fi.ReorderLevel THEN 'Low Stock'
        WHEN fi.DaysOfSupply > 180 THEN 'Overstock'
        ELSE 'Normal'
    END AS StockStatus,
    
    -- Reorder flag
    CASE WHEN fi.QuantityOnHand <= fi.ReorderLevel AND fi.QuantityOnOrder = 0 
         THEN 1 ELSE 0 
    END AS NeedsReorder

FROM Fact.FactInventory fi
INNER JOIN Dim.DimDate dd ON fi.DateKey = dd.DateKey
INNER JOIN Dim.DimProduct dp ON fi.ProductKey = dp.ProductKey
INNER JOIN Dim.DimStore ds ON fi.StoreKey = ds.StoreKey;
GO

-- Customer 360 View
CREATE OR ALTER VIEW Reports.vw_Customer360
AS
SELECT 
    dc.CustomerKey,
    dc.CustomerID,
    dc.CustomerName,
    dc.Email,
    dc.Phone,
    dc.City,
    dc.State,
    dc.Country,
    dc.Region,
    dc.Segment,
    dc.AgeGroup,
    dc.JoinDate,
    dc.TenureYears,
    dc.IsActive,
    
    -- Aggregated metrics
    COUNT(DISTINCT fs.OrderID) AS TotalOrders,
    COUNT(fs.OrderDetailID) AS TotalLineItems,
    SUM(fs.Quantity) AS TotalItemsPurchased,
    SUM(fs.SalesAmount) AS LifetimeValue,
    SUM(fs.GrossProfit) AS LifetimeProfit,
    AVG(fs.SalesAmount) AS AvgOrderValue,
    
    -- Date metrics
    MIN(dd.FullDate) AS FirstPurchaseDate,
    MAX(dd.FullDate) AS LastPurchaseDate,
    DATEDIFF(DAY, MAX(dd.FullDate), GETDATE()) AS DaysSinceLastPurchase,
    
    -- RFM components
    CASE 
        WHEN DATEDIFF(DAY, MAX(dd.FullDate), GETDATE()) <= 30 THEN 5
        WHEN DATEDIFF(DAY, MAX(dd.FullDate), GETDATE()) <= 90 THEN 4
        WHEN DATEDIFF(DAY, MAX(dd.FullDate), GETDATE()) <= 180 THEN 3
        WHEN DATEDIFF(DAY, MAX(dd.FullDate), GETDATE()) <= 365 THEN 2
        ELSE 1
    END AS RecencyScore,
    
    CASE 
        WHEN COUNT(DISTINCT fs.OrderID) >= 20 THEN 5
        WHEN COUNT(DISTINCT fs.OrderID) >= 10 THEN 4
        WHEN COUNT(DISTINCT fs.OrderID) >= 5 THEN 3
        WHEN COUNT(DISTINCT fs.OrderID) >= 2 THEN 2
        ELSE 1
    END AS FrequencyScore,
    
    CASE 
        WHEN SUM(fs.SalesAmount) >= 10000 THEN 5
        WHEN SUM(fs.SalesAmount) >= 5000 THEN 4
        WHEN SUM(fs.SalesAmount) >= 1000 THEN 3
        WHEN SUM(fs.SalesAmount) >= 500 THEN 2
        ELSE 1
    END AS MonetaryScore

FROM Dim.DimCustomer dc
LEFT JOIN Fact.FactSales fs ON dc.CustomerKey = fs.CustomerKey
LEFT JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
WHERE dc.IsCurrent = 1
GROUP BY 
    dc.CustomerKey, dc.CustomerID, dc.CustomerName, dc.Email, dc.Phone,
    dc.City, dc.State, dc.Country, dc.Region, dc.Segment, dc.AgeGroup,
    dc.JoinDate, dc.TenureYears, dc.IsActive;
GO

-- Product Performance View
CREATE OR ALTER VIEW Reports.vw_ProductPerformance
AS
SELECT 
    dp.ProductKey,
    dp.ProductID,
    dp.ProductName,
    dp.ProductCode,
    dp.Category,
    dp.ParentCategory,
    dp.Brand,
    dp.Supplier,
    dp.UnitPrice AS CurrentPrice,
    dp.Cost AS CurrentCost,
    dp.PriceRange,
    dp.IsActive,
    
    -- Sales metrics
    COUNT(DISTINCT fs.OrderID) AS OrderCount,
    SUM(fs.Quantity) AS TotalQuantitySold,
    SUM(fs.SalesAmount) AS TotalRevenue,
    SUM(fs.CostAmount) AS TotalCost,
    SUM(fs.GrossProfit) AS TotalProfit,
    AVG(fs.UnitPrice) AS AvgSellingPrice,
    AVG(fs.Discount) AS AvgDiscount,
    
    -- Profitability
    CASE WHEN SUM(fs.SalesAmount) > 0 
         THEN (SUM(fs.GrossProfit) / SUM(fs.SalesAmount)) * 100 
         ELSE 0 
    END AS ProfitMarginPct,
    
    -- Inventory (latest snapshot)
    inv.TotalOnHand,
    inv.TotalInventoryValue,
    inv.AvgDaysOfSupply

FROM Dim.DimProduct dp
LEFT JOIN Fact.FactSales fs ON dp.ProductKey = fs.ProductKey
LEFT JOIN (
    SELECT 
        ProductKey,
        SUM(QuantityOnHand) AS TotalOnHand,
        SUM(InventoryValue) AS TotalInventoryValue,
        AVG(DaysOfSupply) AS AvgDaysOfSupply
    FROM Fact.FactInventory fi
    INNER JOIN Dim.DimDate dd ON fi.DateKey = dd.DateKey
    WHERE dd.FullDate = (SELECT MAX(FullDate) FROM Dim.DimDate d2 
                         INNER JOIN Fact.FactInventory f2 ON d2.DateKey = f2.DateKey)
    GROUP BY ProductKey
) inv ON dp.ProductKey = inv.ProductKey
WHERE dp.IsCurrent = 1
GROUP BY 
    dp.ProductKey, dp.ProductID, dp.ProductName, dp.ProductCode,
    dp.Category, dp.ParentCategory, dp.Brand, dp.Supplier,
    dp.UnitPrice, dp.Cost, dp.PriceRange, dp.IsActive,
    inv.TotalOnHand, inv.TotalInventoryValue, inv.AvgDaysOfSupply;
GO

/*******************************************************************************
 * PART 2: INDEXED VIEW FOR PERFORMANCE
 ******************************************************************************/

-- Daily Sales Summary (Indexed View)
CREATE OR ALTER VIEW Reports.vw_DailySalesSummary
WITH SCHEMABINDING
AS
SELECT 
    fs.OrderDateKey,
    fs.StoreKey,
    COUNT_BIG(*) AS LineItemCount,
    SUM(fs.Quantity) AS TotalQuantity,
    SUM(fs.SalesAmount) AS TotalSales,
    SUM(fs.CostAmount) AS TotalCost,
    SUM(fs.GrossProfit) AS TotalProfit
FROM Fact.FactSales fs
GROUP BY fs.OrderDateKey, fs.StoreKey;
GO

-- Create clustered index on the view
CREATE UNIQUE CLUSTERED INDEX IX_DailySalesSummary 
ON Reports.vw_DailySalesSummary (OrderDateKey, StoreKey);
GO

/*******************************************************************************
 * PART 3: PARAMETERIZED REPORT PROCEDURES
 ******************************************************************************/

-- Sales Summary Report
CREATE OR ALTER PROCEDURE Reports.sp_SalesSummaryReport
    @StartDate DATE,
    @EndDate DATE,
    @StoreID INT = NULL,
    @CategoryName NVARCHAR(50) = NULL,
    @GroupBy NVARCHAR(20) = 'Month' -- Day, Week, Month, Quarter, Year
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CASE @GroupBy
            WHEN 'Day' THEN CONVERT(VARCHAR, dd.FullDate, 23)
            WHEN 'Week' THEN CAST(dd.Year AS VARCHAR) + '-W' + RIGHT('0' + CAST(dd.WeekOfYear AS VARCHAR), 2)
            WHEN 'Month' THEN CAST(dd.Year AS VARCHAR) + '-' + RIGHT('0' + CAST(dd.MonthNumber AS VARCHAR), 2)
            WHEN 'Quarter' THEN CAST(dd.Year AS VARCHAR) + '-Q' + CAST(dd.Quarter AS VARCHAR)
            WHEN 'Year' THEN CAST(dd.Year AS VARCHAR)
        END AS Period,
        
        COUNT(DISTINCT fs.OrderID) AS OrderCount,
        COUNT(fs.OrderDetailID) AS LineItems,
        SUM(fs.Quantity) AS TotalQuantity,
        SUM(fs.SalesAmount) AS TotalSales,
        SUM(fs.CostAmount) AS TotalCost,
        SUM(fs.GrossProfit) AS GrossProfit,
        (SUM(fs.GrossProfit) / NULLIF(SUM(fs.SalesAmount), 0)) * 100 AS ProfitMarginPct,
        SUM(fs.SalesAmount) / NULLIF(COUNT(DISTINCT fs.OrderID), 0) AS AvgOrderValue
        
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    LEFT JOIN Dim.DimStore ds ON fs.StoreKey = ds.StoreKey
    LEFT JOIN Dim.DimProduct dp ON fs.ProductKey = dp.ProductKey
    WHERE dd.FullDate BETWEEN @StartDate AND @EndDate
      AND (@StoreID IS NULL OR ds.StoreID = @StoreID)
      AND (@CategoryName IS NULL OR dp.Category = @CategoryName)
    GROUP BY 
        CASE @GroupBy
            WHEN 'Day' THEN CONVERT(VARCHAR, dd.FullDate, 23)
            WHEN 'Week' THEN CAST(dd.Year AS VARCHAR) + '-W' + RIGHT('0' + CAST(dd.WeekOfYear AS VARCHAR), 2)
            WHEN 'Month' THEN CAST(dd.Year AS VARCHAR) + '-' + RIGHT('0' + CAST(dd.MonthNumber AS VARCHAR), 2)
            WHEN 'Quarter' THEN CAST(dd.Year AS VARCHAR) + '-Q' + CAST(dd.Quarter AS VARCHAR)
            WHEN 'Year' THEN CAST(dd.Year AS VARCHAR)
        END
    ORDER BY Period;
END;
GO

-- Top Products Report
CREATE OR ALTER PROCEDURE Reports.sp_TopProductsReport
    @StartDate DATE,
    @EndDate DATE,
    @TopN INT = 10,
    @Metric NVARCHAR(20) = 'Revenue' -- Revenue, Quantity, Profit, Orders
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@TopN)
        dp.ProductName,
        dp.Category,
        dp.Brand,
        COUNT(DISTINCT fs.OrderID) AS OrderCount,
        SUM(fs.Quantity) AS QuantitySold,
        SUM(fs.SalesAmount) AS Revenue,
        SUM(fs.GrossProfit) AS Profit,
        (SUM(fs.GrossProfit) / NULLIF(SUM(fs.SalesAmount), 0)) * 100 AS ProfitMarginPct
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    INNER JOIN Dim.DimProduct dp ON fs.ProductKey = dp.ProductKey
    WHERE dd.FullDate BETWEEN @StartDate AND @EndDate
    GROUP BY dp.ProductName, dp.Category, dp.Brand
    ORDER BY 
        CASE @Metric
            WHEN 'Revenue' THEN SUM(fs.SalesAmount)
            WHEN 'Quantity' THEN SUM(fs.Quantity)
            WHEN 'Profit' THEN SUM(fs.GrossProfit)
            WHEN 'Orders' THEN COUNT(DISTINCT fs.OrderID)
        END DESC;
END;
GO

-- Store Performance Report
CREATE OR ALTER PROCEDURE Reports.sp_StorePerformanceReport
    @StartDate DATE,
    @EndDate DATE,
    @Region NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ds.StoreName,
        ds.StoreCity,
        ds.StoreCountry,
        ds.StoreRegion,
        ds.StoreSize,
        
        -- Sales metrics
        COUNT(DISTINCT fs.OrderID) AS OrderCount,
        COUNT(DISTINCT fs.CustomerKey) AS UniqueCustomers,
        SUM(fs.SalesAmount) AS TotalSales,
        SUM(fs.GrossProfit) AS TotalProfit,
        (SUM(fs.GrossProfit) / NULLIF(SUM(fs.SalesAmount), 0)) * 100 AS ProfitMarginPct,
        
        -- Efficiency metrics
        SUM(fs.SalesAmount) / ds.SquareFeet AS SalesPerSqFt,
        SUM(fs.SalesAmount) / NULLIF(COUNT(DISTINCT fs.OrderID), 0) AS AvgOrderValue,
        COUNT(DISTINCT fs.OrderID) / NULLIF(DATEDIFF(DAY, @StartDate, @EndDate) + 1, 0) AS AvgDailyOrders
        
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    INNER JOIN Dim.DimStore ds ON fs.StoreKey = ds.StoreKey
    WHERE dd.FullDate BETWEEN @StartDate AND @EndDate
      AND (@Region IS NULL OR ds.StoreRegion = @Region)
      AND ds.IsCurrent = 1
    GROUP BY 
        ds.StoreName, ds.StoreCity, ds.StoreCountry, ds.StoreRegion,
        ds.StoreSize, ds.SquareFeet
    ORDER BY TotalSales DESC;
END;
GO

-- Customer Segment Analysis
CREATE OR ALTER PROCEDURE Reports.sp_CustomerSegmentAnalysis
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        dc.Segment,
        dc.AgeGroup,
        dc.Region AS CustomerRegion,
        
        COUNT(DISTINCT dc.CustomerKey) AS CustomerCount,
        COUNT(DISTINCT fs.OrderID) AS OrderCount,
        SUM(fs.SalesAmount) AS TotalSales,
        SUM(fs.GrossProfit) AS TotalProfit,
        
        SUM(fs.SalesAmount) / NULLIF(COUNT(DISTINCT dc.CustomerKey), 0) AS AvgCustomerValue,
        COUNT(DISTINCT fs.OrderID) * 1.0 / NULLIF(COUNT(DISTINCT dc.CustomerKey), 0) AS AvgOrdersPerCustomer,
        SUM(fs.SalesAmount) / NULLIF(COUNT(DISTINCT fs.OrderID), 0) AS AvgOrderValue
        
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    INNER JOIN Dim.DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
    WHERE dd.FullDate BETWEEN @StartDate AND @EndDate
    GROUP BY dc.Segment, dc.AgeGroup, dc.Region
    ORDER BY TotalSales DESC;
END;
GO

/*******************************************************************************
 * PART 4: KPI DASHBOARD PROCEDURE
 ******************************************************************************/

CREATE OR ALTER PROCEDURE Reports.sp_ExecutiveDashboard
    @AsOfDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @AsOfDate = ISNULL(@AsOfDate, CAST(GETDATE() AS DATE));
    
    DECLARE @CurrentMonthStart DATE = DATEFROMPARTS(YEAR(@AsOfDate), MONTH(@AsOfDate), 1);
    DECLARE @PriorMonthStart DATE = DATEADD(MONTH, -1, @CurrentMonthStart);
    DECLARE @PriorMonthEnd DATE = DATEADD(DAY, -1, @CurrentMonthStart);
    DECLARE @CurrentYearStart DATE = DATEFROMPARTS(YEAR(@AsOfDate), 1, 1);
    DECLARE @PriorYearStart DATE = DATEFROMPARTS(YEAR(@AsOfDate) - 1, 1, 1);
    DECLARE @PriorYearEnd DATE = DATEFROMPARTS(YEAR(@AsOfDate) - 1, 12, 31);
    
    -- Current Period Metrics
    SELECT 'Current Month' AS Period,
           SUM(fs.SalesAmount) AS TotalSales,
           SUM(fs.GrossProfit) AS GrossProfit,
           COUNT(DISTINCT fs.OrderID) AS OrderCount,
           COUNT(DISTINCT fs.CustomerKey) AS UniqueCustomers
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    WHERE dd.FullDate >= @CurrentMonthStart AND dd.FullDate <= @AsOfDate
    
    UNION ALL
    
    SELECT 'Prior Month',
           SUM(fs.SalesAmount),
           SUM(fs.GrossProfit),
           COUNT(DISTINCT fs.OrderID),
           COUNT(DISTINCT fs.CustomerKey)
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    WHERE dd.FullDate >= @PriorMonthStart AND dd.FullDate <= @PriorMonthEnd
    
    UNION ALL
    
    SELECT 'YTD',
           SUM(fs.SalesAmount),
           SUM(fs.GrossProfit),
           COUNT(DISTINCT fs.OrderID),
           COUNT(DISTINCT fs.CustomerKey)
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    WHERE dd.FullDate >= @CurrentYearStart AND dd.FullDate <= @AsOfDate
    
    UNION ALL
    
    SELECT 'Prior Year',
           SUM(fs.SalesAmount),
           SUM(fs.GrossProfit),
           COUNT(DISTINCT fs.OrderID),
           COUNT(DISTINCT fs.CustomerKey)
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    WHERE dd.FullDate >= @PriorYearStart AND dd.FullDate <= @PriorYearEnd;
    
    -- Top 5 Products This Month
    SELECT TOP 5 
        dp.ProductName,
        SUM(fs.SalesAmount) AS Sales
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    INNER JOIN Dim.DimProduct dp ON fs.ProductKey = dp.ProductKey
    WHERE dd.FullDate >= @CurrentMonthStart AND dd.FullDate <= @AsOfDate
    GROUP BY dp.ProductName
    ORDER BY Sales DESC;
    
    -- Top 5 Stores This Month
    SELECT TOP 5 
        ds.StoreName,
        SUM(fs.SalesAmount) AS Sales
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    INNER JOIN Dim.DimStore ds ON fs.StoreKey = ds.StoreKey
    WHERE dd.FullDate >= @CurrentMonthStart AND dd.FullDate <= @AsOfDate
    GROUP BY ds.StoreName
    ORDER BY Sales DESC;
END;
GO

/*******************************************************************************
 * PART 5: VERIFY REPORTING LAYER
 ******************************************************************************/

-- Test views
SELECT TOP 5 * FROM Reports.vw_SalesDetail;
SELECT TOP 5 * FROM Reports.vw_Customer360;
SELECT TOP 5 * FROM Reports.vw_ProductPerformance;

-- Test report procedures
EXEC Reports.sp_SalesSummaryReport 
    @StartDate = '2024-01-01', 
    @EndDate = '2024-12-31',
    @GroupBy = 'Month';

EXEC Reports.sp_TopProductsReport 
    @StartDate = '2024-01-01', 
    @EndDate = '2024-12-31',
    @TopN = 10,
    @Metric = 'Revenue';

EXEC Reports.sp_ExecutiveDashboard;

PRINT '
=============================================================================
LAB 81 COMPLETE - REPORTING LAYER IMPLEMENTED
=============================================================================

Created Views:
- Reports.vw_SalesDetail (Denormalized sales for BI tools)
- Reports.vw_InventoryStatus (Inventory with stock status)
- Reports.vw_Customer360 (Customer analytics with RFM)
- Reports.vw_ProductPerformance (Product metrics)
- Reports.vw_DailySalesSummary (Indexed view)

Created Procedures:
- Reports.sp_SalesSummaryReport
- Reports.sp_TopProductsReport
- Reports.sp_StorePerformanceReport
- Reports.sp_CustomerSegmentAnalysis
- Reports.sp_ExecutiveDashboard

Next: Lab 82 - Testing and Validation
';
GO
