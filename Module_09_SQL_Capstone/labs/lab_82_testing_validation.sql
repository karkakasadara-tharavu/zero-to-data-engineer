/*******************************************************************************
 * LAB 82: SQL Capstone - Testing and Data Validation
 * Module 09: SQL Capstone Project
 * 
 * Objective: Implement comprehensive testing framework for the GlobalMart
 *            Data Warehouse including data quality checks, ETL validation,
 *            and automated testing procedures.
 * 
 * Duration: 4-6 hours
 * 
 * Topics Covered:
 * - Unit testing for stored procedures
 * - Data quality validation
 * - ETL reconciliation testing
 * - Automated test framework
 ******************************************************************************/

USE GlobalMart_DW;
GO

-- Create Testing schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Testing')
    EXEC('CREATE SCHEMA Testing');
GO

/*******************************************************************************
 * PART 1: TEST RESULTS TABLE
 ******************************************************************************/

-- Create test results table
IF OBJECT_ID('Testing.TestResults', 'U') IS NULL
BEGIN
    CREATE TABLE Testing.TestResults (
        TestResultID INT IDENTITY(1,1) PRIMARY KEY,
        TestSuite NVARCHAR(50) NOT NULL,
        TestName NVARCHAR(100) NOT NULL,
        TestDescription NVARCHAR(500),
        Status NVARCHAR(20) NOT NULL, -- Pass, Fail, Warning
        ExpectedValue NVARCHAR(MAX),
        ActualValue NVARCHAR(MAX),
        ErrorMessage NVARCHAR(MAX),
        ExecutionTime DATETIME DEFAULT GETDATE(),
        DurationMs INT
    );
END;
GO

-- Helper procedure to log test results
CREATE OR ALTER PROCEDURE Testing.sp_LogTestResult
    @TestSuite NVARCHAR(50),
    @TestName NVARCHAR(100),
    @TestDescription NVARCHAR(500) = NULL,
    @Status NVARCHAR(20),
    @ExpectedValue NVARCHAR(MAX) = NULL,
    @ActualValue NVARCHAR(MAX) = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @DurationMs INT = NULL
AS
BEGIN
    INSERT INTO Testing.TestResults (
        TestSuite, TestName, TestDescription, Status,
        ExpectedValue, ActualValue, ErrorMessage, DurationMs
    )
    VALUES (
        @TestSuite, @TestName, @TestDescription, @Status,
        @ExpectedValue, @ActualValue, @ErrorMessage, @DurationMs
    );
    
    -- Print result for immediate feedback
    PRINT @TestSuite + '.' + @TestName + ': ' + @Status + 
          CASE WHEN @ErrorMessage IS NOT NULL THEN ' - ' + @ErrorMessage ELSE '' END;
END;
GO

/*******************************************************************************
 * PART 2: DATA QUALITY TESTS
 ******************************************************************************/

CREATE OR ALTER PROCEDURE Testing.sp_Test_DataQuality
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TestSuite NVARCHAR(50) = 'DataQuality';
    DECLARE @ActualCount INT;
    DECLARE @StartTime DATETIME;
    
    PRINT '=== Running Data Quality Tests ===';
    PRINT '';
    
    -- Test 1: No orphan customer keys in FactSales
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM Fact.FactSales fs
    WHERE fs.CustomerKey <> -1
      AND NOT EXISTS (SELECT 1 FROM Dim.DimCustomer dc WHERE dc.CustomerKey = fs.CustomerKey);
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'NoOrphanCustomerKeys',
        @TestDescription = 'Verify all CustomerKeys in FactSales exist in DimCustomer',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 2: No orphan product keys
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM Fact.FactSales fs
    WHERE fs.ProductKey <> -1
      AND NOT EXISTS (SELECT 1 FROM Dim.DimProduct dp WHERE dp.ProductKey = fs.ProductKey);
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'NoOrphanProductKeys',
        @TestDescription = 'Verify all ProductKeys in FactSales exist in DimProduct',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 3: No null required measures
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM Fact.FactSales
    WHERE Quantity IS NULL 
       OR SalesAmount IS NULL 
       OR UnitPrice IS NULL;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'NoNullMeasures',
        @TestDescription = 'Verify required measures are not null',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 4: Positive quantities
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM Fact.FactSales
    WHERE Quantity <= 0;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'PositiveQuantities',
        @TestDescription = 'Verify all quantities are positive',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 5: SCD Type 2 - Only one current record per natural key
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM (
        SELECT CustomerID, COUNT(*) AS CurrentCount
        FROM Dim.DimCustomer
        WHERE IsCurrent = 1
        GROUP BY CustomerID
        HAVING COUNT(*) > 1
    ) dups;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'SingleCurrentCustomer',
        @TestDescription = 'Verify only one current record per customer',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 6: Date dimension coverage
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM Fact.FactSales fs
    WHERE NOT EXISTS (SELECT 1 FROM Dim.DimDate dd WHERE dd.DateKey = fs.OrderDateKey);
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'DateDimensionCoverage',
        @TestDescription = 'Verify all order dates have matching date dimension entries',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 7: Calculated column consistency (GrossProfit = Sales - Cost)
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM Fact.FactSales
    WHERE ABS(GrossProfit - (SalesAmount - CostAmount)) > 0.01;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'GrossProfitCalculation',
        @TestDescription = 'Verify GrossProfit = SalesAmount - CostAmount',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    PRINT '';
    PRINT '=== Data Quality Tests Complete ===';
END;
GO

/*******************************************************************************
 * PART 3: ETL RECONCILIATION TESTS
 ******************************************************************************/

CREATE OR ALTER PROCEDURE Testing.sp_Test_ETLReconciliation
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TestSuite NVARCHAR(50) = 'ETLReconciliation';
    DECLARE @SourceCount INT;
    DECLARE @TargetCount INT;
    DECLARE @SourceSum DECIMAL(18,2);
    DECLARE @TargetSum DECIMAL(18,2);
    DECLARE @StartTime DATETIME;
    
    PRINT '=== Running ETL Reconciliation Tests ===';
    PRINT '';
    
    -- Test 1: Customer count reconciliation
    SET @StartTime = GETDATE();
    SELECT @SourceCount = COUNT(*) FROM GlobalMart_OLTP.Sales.Customers;
    SELECT @TargetCount = COUNT(*) FROM Dim.DimCustomer WHERE IsCurrent = 1;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'CustomerCountMatch',
        @TestDescription = 'Verify DW has all source customers',
        @Status = CASE WHEN @SourceCount = @TargetCount THEN 'Pass' 
                       WHEN @TargetCount >= @SourceCount THEN 'Warning' 
                       ELSE 'Fail' END,
        @ExpectedValue = CAST(@SourceCount AS VARCHAR),
        @ActualValue = CAST(@TargetCount AS VARCHAR),
        @ErrorMessage = CASE WHEN @SourceCount <> @TargetCount 
                             THEN 'Difference: ' + CAST(@TargetCount - @SourceCount AS VARCHAR) 
                             ELSE NULL END,
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 2: Product count reconciliation
    SET @StartTime = GETDATE();
    SELECT @SourceCount = COUNT(*) FROM GlobalMart_OLTP.Products.Products;
    SELECT @TargetCount = COUNT(*) FROM Dim.DimProduct WHERE IsCurrent = 1;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'ProductCountMatch',
        @TestDescription = 'Verify DW has all source products',
        @Status = CASE WHEN @SourceCount = @TargetCount THEN 'Pass' 
                       WHEN @TargetCount >= @SourceCount THEN 'Warning' 
                       ELSE 'Fail' END,
        @ExpectedValue = CAST(@SourceCount AS VARCHAR),
        @ActualValue = CAST(@TargetCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 3: Order detail count reconciliation
    SET @StartTime = GETDATE();
    SELECT @SourceCount = COUNT(*) FROM GlobalMart_OLTP.Sales.OrderDetails;
    SELECT @TargetCount = COUNT(*) FROM Fact.FactSales;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'FactSalesCountMatch',
        @TestDescription = 'Verify all order details loaded to fact table',
        @Status = CASE WHEN @SourceCount = @TargetCount THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = CAST(@SourceCount AS VARCHAR),
        @ActualValue = CAST(@TargetCount AS VARCHAR),
        @ErrorMessage = CASE WHEN @SourceCount <> @TargetCount 
                             THEN 'Missing: ' + CAST(@SourceCount - @TargetCount AS VARCHAR) + ' rows'
                             ELSE NULL END,
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 4: Sales amount reconciliation
    SET @StartTime = GETDATE();
    SELECT @SourceSum = SUM(LineTotal) FROM GlobalMart_OLTP.Sales.OrderDetails;
    SELECT @TargetSum = SUM(SalesAmount) FROM Fact.FactSales;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'SalesAmountMatch',
        @TestDescription = 'Verify total sales amount matches source',
        @Status = CASE WHEN ABS(ISNULL(@SourceSum, 0) - ISNULL(@TargetSum, 0)) < 1.00 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = CAST(@SourceSum AS VARCHAR),
        @ActualValue = CAST(@TargetSum AS VARCHAR),
        @ErrorMessage = CASE WHEN ABS(ISNULL(@SourceSum, 0) - ISNULL(@TargetSum, 0)) >= 1.00 
                             THEN 'Variance: $' + CAST(ABS(@SourceSum - @TargetSum) AS VARCHAR)
                             ELSE NULL END,
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 5: Check for missing date keys
    SET @StartTime = GETDATE();
    SELECT @TargetCount = COUNT(*)
    FROM Fact.FactSales
    WHERE OrderDateKey = -1;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'NoMissingDateKeys',
        @TestDescription = 'Verify no facts have unknown date key',
        @Status = CASE WHEN @TargetCount = 0 THEN 'Pass' 
                       WHEN @TargetCount < 100 THEN 'Warning' 
                       ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@TargetCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    PRINT '';
    PRINT '=== ETL Reconciliation Tests Complete ===';
END;
GO

/*******************************************************************************
 * PART 4: DIMENSION TESTS
 ******************************************************************************/

CREATE OR ALTER PROCEDURE Testing.sp_Test_Dimensions
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TestSuite NVARCHAR(50) = 'Dimensions';
    DECLARE @ActualCount INT;
    DECLARE @StartTime DATETIME;
    
    PRINT '=== Running Dimension Tests ===';
    PRINT '';
    
    -- Test 1: DimDate - Check for gaps
    SET @StartTime = GETDATE();
    WITH DateGaps AS (
        SELECT 
            FullDate,
            LAG(FullDate) OVER (ORDER BY FullDate) AS PrevDate,
            DATEDIFF(DAY, LAG(FullDate) OVER (ORDER BY FullDate), FullDate) AS DayGap
        FROM Dim.DimDate
    )
    SELECT @ActualCount = COUNT(*)
    FROM DateGaps
    WHERE DayGap > 1;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'DimDateNoGaps',
        @TestDescription = 'Verify date dimension has no gaps',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 2: DimDate - Check DateKey format
    SET @StartTime = GETDATE();
    SELECT @ActualCount = COUNT(*)
    FROM Dim.DimDate
    WHERE DateKey <> YEAR(FullDate) * 10000 + MONTH(FullDate) * 100 + DAY(FullDate);
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'DimDateKeyFormat',
        @TestDescription = 'Verify DateKey follows YYYYMMDD format',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 3: SCD Type 2 - Date continuity
    SET @StartTime = GETDATE();
    WITH CustomerVersions AS (
        SELECT 
            CustomerID,
            EffectiveDate,
            ExpiryDate,
            LEAD(EffectiveDate) OVER (PARTITION BY CustomerID ORDER BY EffectiveDate) AS NextEffective
        FROM Dim.DimCustomer
    )
    SELECT @ActualCount = COUNT(*)
    FROM CustomerVersions
    WHERE NextEffective IS NOT NULL
      AND DATEADD(DAY, 1, ExpiryDate) <> NextEffective;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'SCDDateContinuity',
        @TestDescription = 'Verify SCD Type 2 date ranges are contiguous',
        @Status = CASE WHEN @ActualCount = 0 THEN 'Pass' ELSE 'Fail' END,
        @ExpectedValue = '0',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    -- Test 4: Unknown member exists
    SET @StartTime = GETDATE();
    SELECT @ActualCount = CASE WHEN EXISTS (SELECT 1 FROM Dim.DimCustomer WHERE CustomerKey = -1) 
                               THEN 1 ELSE 0 END;
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'UnknownCustomerExists',
        @TestDescription = 'Verify unknown customer member exists',
        @Status = CASE WHEN @ActualCount = 1 THEN 'Pass' ELSE 'Warning' END,
        @ExpectedValue = '1',
        @ActualValue = CAST(@ActualCount AS VARCHAR),
        @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    PRINT '';
    PRINT '=== Dimension Tests Complete ===';
END;
GO

/*******************************************************************************
 * PART 5: PERFORMANCE TESTS
 ******************************************************************************/

CREATE OR ALTER PROCEDURE Testing.sp_Test_Performance
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TestSuite NVARCHAR(50) = 'Performance';
    DECLARE @StartTime DATETIME;
    DECLARE @DurationMs INT;
    DECLARE @RowCount INT;
    DECLARE @Threshold INT = 5000; -- 5 seconds threshold
    
    PRINT '=== Running Performance Tests ===';
    PRINT '';
    
    -- Test 1: Fact table scan time
    SET @StartTime = GETDATE();
    SELECT @RowCount = COUNT(*) FROM Fact.FactSales WITH (NOLOCK);
    SET @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'FactSalesScanTime',
        @TestDescription = 'Full table scan should complete within threshold',
        @Status = CASE WHEN @DurationMs < @Threshold THEN 'Pass' ELSE 'Warning' END,
        @ExpectedValue = '< ' + CAST(@Threshold AS VARCHAR) + ' ms',
        @ActualValue = CAST(@DurationMs AS VARCHAR) + ' ms (' + CAST(@RowCount AS VARCHAR) + ' rows)',
        @DurationMs = @DurationMs;
    
    -- Test 2: Executive dashboard response time
    SET @StartTime = GETDATE();
    EXEC Reports.sp_ExecutiveDashboard;
    SET @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'ExecutiveDashboardTime',
        @TestDescription = 'Dashboard should respond within 3 seconds',
        @Status = CASE WHEN @DurationMs < 3000 THEN 'Pass' ELSE 'Warning' END,
        @ExpectedValue = '< 3000 ms',
        @ActualValue = CAST(@DurationMs AS VARCHAR) + ' ms',
        @DurationMs = @DurationMs;
    
    -- Test 3: Indexed view usage
    SET @StartTime = GETDATE();
    SELECT SUM(TotalSales) 
    FROM Reports.vw_DailySalesSummary WITH (NOEXPAND);
    SET @DurationMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    
    EXEC Testing.sp_LogTestResult
        @TestSuite = @TestSuite,
        @TestName = 'IndexedViewPerformance',
        @TestDescription = 'Indexed view aggregation should be fast',
        @Status = CASE WHEN @DurationMs < 1000 THEN 'Pass' ELSE 'Warning' END,
        @ExpectedValue = '< 1000 ms',
        @ActualValue = CAST(@DurationMs AS VARCHAR) + ' ms',
        @DurationMs = @DurationMs;
    
    PRINT '';
    PRINT '=== Performance Tests Complete ===';
END;
GO

/*******************************************************************************
 * PART 6: MASTER TEST RUNNER
 ******************************************************************************/

CREATE OR ALTER PROCEDURE Testing.sp_RunAllTests
    @CleanPreviousResults BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    
    -- Optionally clean previous results
    IF @CleanPreviousResults = 1
        TRUNCATE TABLE Testing.TestResults;
    
    PRINT '===============================================================';
    PRINT ' GLOBALMART DATA WAREHOUSE - TEST SUITE';
    PRINT '===============================================================';
    PRINT 'Execution Started: ' + CONVERT(VARCHAR, @StartTime, 120);
    PRINT '';
    
    -- Run all test suites
    EXEC Testing.sp_Test_DataQuality;
    EXEC Testing.sp_Test_ETLReconciliation;
    EXEC Testing.sp_Test_Dimensions;
    EXEC Testing.sp_Test_Performance;
    
    -- Summary report
    PRINT '';
    PRINT '===============================================================';
    PRINT ' TEST SUMMARY';
    PRINT '===============================================================';
    
    SELECT 
        TestSuite,
        COUNT(*) AS TotalTests,
        SUM(CASE WHEN Status = 'Pass' THEN 1 ELSE 0 END) AS Passed,
        SUM(CASE WHEN Status = 'Fail' THEN 1 ELSE 0 END) AS Failed,
        SUM(CASE WHEN Status = 'Warning' THEN 1 ELSE 0 END) AS Warnings
    FROM Testing.TestResults
    WHERE ExecutionTime >= @StartTime
    GROUP BY TestSuite;
    
    -- Overall summary
    SELECT 
        COUNT(*) AS TotalTests,
        SUM(CASE WHEN Status = 'Pass' THEN 1 ELSE 0 END) AS TotalPassed,
        SUM(CASE WHEN Status = 'Fail' THEN 1 ELSE 0 END) AS TotalFailed,
        SUM(CASE WHEN Status = 'Warning' THEN 1 ELSE 0 END) AS TotalWarnings,
        CAST(SUM(CASE WHEN Status = 'Pass' THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS PassRate
    FROM Testing.TestResults
    WHERE ExecutionTime >= @StartTime;
    
    -- List failures
    IF EXISTS (SELECT 1 FROM Testing.TestResults WHERE Status = 'Fail' AND ExecutionTime >= @StartTime)
    BEGIN
        PRINT '';
        PRINT 'FAILED TESTS:';
        SELECT TestSuite, TestName, ErrorMessage
        FROM Testing.TestResults
        WHERE Status = 'Fail' AND ExecutionTime >= @StartTime;
    END
    
    PRINT '';
    PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR) + ' seconds';
    PRINT '===============================================================';
END;
GO

/*******************************************************************************
 * PART 7: EXECUTE TESTS
 ******************************************************************************/

-- Run all tests
EXEC Testing.sp_RunAllTests;

-- View detailed results
SELECT * FROM Testing.TestResults ORDER BY TestResultID;

PRINT '
=============================================================================
LAB 82 COMPLETE - TESTING FRAMEWORK IMPLEMENTED
=============================================================================

Created Test Suites:
- DataQuality: Referential integrity, null checks, calculations
- ETLReconciliation: Source/target counts and sums
- Dimensions: SCD validation, date gaps, unknown members
- Performance: Query response times, scan performance

Test Infrastructure:
- Testing.TestResults table for result storage
- Testing.sp_LogTestResult for standardized logging
- Testing.sp_RunAllTests for complete test execution

Next: Lab 83 - Documentation and Deployment
';
GO
