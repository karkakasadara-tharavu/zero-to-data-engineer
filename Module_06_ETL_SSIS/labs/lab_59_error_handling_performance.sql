/*
============================================================================
LAB 59: SSIS ERROR HANDLING, LOGGING & PERFORMANCE TUNING  
Module 06: ETL SSIS Fundamentals
============================================================================

OBJECTIVE:
- Implement comprehensive error handling strategies
- Configure package and data flow logging
- Monitor performance and identify bottlenecks
- Apply performance optimization techniques
- Create reusable error handling patterns

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐⭐⭐ (Expert)

PREREQUISITES:
- Completed Labs 53-58
- Understanding of all SSIS concepts
- BookstoreDB and BookstoreETL databases

DATABASE: BookstoreDB, BookstoreETL
============================================================================
*/

USE BookstoreETL;
GO

-- ============================================================================
-- PART 1: ERROR HANDLING PATTERNS
-- ============================================================================
/*
ERROR HANDLING LEVELS:
1. Package Level: OnError event handlers
2. Task Level: MaximumErrorCount, FailPackageOnFailure
3. Data Flow Level: Error outputs, row redirection
4. Connection Level: Retry logic

BEST PRACTICES:
- Log all errors to database
- Send notifications for critical failures
- Implement retry logic for transient errors
- Clean up resources in error scenarios
*/

-- Comprehensive error logging table
CREATE TABLE ETL_ErrorLog_Detailed (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID UNIQUEIDENTIFIER,
    PackageName NVARCHAR(255),
    TaskName NVARCHAR(255),
    EventType NVARCHAR(50),
    ErrorCode INT,
    ErrorDescription NVARCHAR(MAX),
    SourceComponent NVARCHAR(255),
    SourceRow NVARCHAR(MAX),
    ServerName NVARCHAR(128),
    MachineName NVARCHAR(128),
    UserName NVARCHAR(128),
    ErrorDate DATETIME DEFAULT GETDATE(),
    Severity NVARCHAR(20),
    IsNotified BIT DEFAULT 0
);

-- Stored procedure for centralized error logging
CREATE OR ALTER PROCEDURE sp_LogETLError
    @ExecutionID UNIQUEIDENTIFIER,
    @PackageName NVARCHAR(255),
    @TaskName NVARCHAR(255),
    @EventType NVARCHAR(50),
    @ErrorCode INT,
    @ErrorDescription NVARCHAR(MAX),
    @SourceComponent NVARCHAR(255) = NULL,
    @SourceRow NVARCHAR(MAX) = NULL,
    @Severity NVARCHAR(20) = 'HIGH'
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ETL_ErrorLog_Detailed (
        ExecutionID, PackageName, TaskName, EventType,
        ErrorCode, ErrorDescription, SourceComponent, SourceRow,
        ServerName, MachineName, UserName, Severity
    )
    VALUES (
        @ExecutionID, @PackageName, @TaskName, @EventType,
        @ErrorCode, @ErrorDescription, @SourceComponent, @SourceRow,
        @@SERVERNAME, HOST_NAME(), SUSER_SNAME(), @Severity
    );
    
    -- Auto-notify for HIGH severity errors
    IF @Severity = 'HIGH' AND NOT EXISTS (
        SELECT 1 FROM ETL_ErrorLog_Detailed 
        WHERE ExecutionID = @ExecutionID AND IsNotified = 1
    )
    BEGIN
        -- Set notification flag
        UPDATE ETL_ErrorLog_Detailed
        SET IsNotified = 1
        WHERE ExecutionID = @ExecutionID;
        
        -- Call notification procedure
        EXEC sp_SendETLErrorNotification @ExecutionID;
    END
END;
GO

-- Error notification procedure
CREATE OR ALTER PROCEDURE sp_SendETLErrorNotification
    @ExecutionID UNIQUEIDENTIFIER
AS
BEGIN
    DECLARE @Subject NVARCHAR(255);
    DECLARE @Body NVARCHAR(MAX);
    
    -- Build notification email
    SELECT @Subject = 'ETL Error Alert: ' + PackageName,
           @Body = 'Error Details:' + CHAR(13) + CHAR(10) +
                   'Package: ' + PackageName + CHAR(13) + CHAR(10) +
                   'Task: ' + TaskName + CHAR(13) + CHAR(10) +
                   'Error: ' + ErrorDescription + CHAR(13) + CHAR(10) +
                   'Time: ' + CONVERT(NVARCHAR, ErrorDate, 120)
    FROM ETL_ErrorLog_Detailed
    WHERE ExecutionID = @ExecutionID
    AND ErrorID = (SELECT MIN(ErrorID) FROM ETL_ErrorLog_Detailed WHERE ExecutionID = @ExecutionID);
    
    -- Send email (configure Database Mail first)
    /*
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'ETL Notifications',
        @recipients = 'etl-team@company.com',
        @subject = @Subject,
        @body = @Body,
        @importance = 'High';
    */
    
    PRINT 'Email notification sent for ExecutionID: ' + CAST(@ExecutionID AS VARCHAR(50));
END;
GO

/*
PACKAGE CONFIGURATION FOR ERROR HANDLING:

1. PACKAGE LEVEL:
   - MaximumErrorCount: Set to appropriate value (default 1)
   - FailPackageOnFailure: TRUE for critical tasks
   - OnError Event Handler: Log and notify

2. TASK LEVEL:
   - MaximumErrorCount: Override for specific tasks
   - FailParentOnFailure: Control parent container behavior
   - IsolationLevel: Appropriate transaction isolation

3. PRECEDENCE CONSTRAINTS:
   - Success path (green)
   - Failure path (red) → Error handling tasks
   - Completion path (blue) → Cleanup tasks
*/

-- ============================================================================
-- PART 2: LOGGING CONFIGURATION
-- ============================================================================
/*
LOGGING LEVELS:
- None: No logging (not recommended)
- Basic: Minimal logging
- Performance: Includes timing information
- Verbose: Detailed logging (use in development)

LOGGING PROVIDERS:
1. SSIS Log Provider for SQL Server
2. SSIS Log Provider for Windows Event Log
3. SSIS Log Provider for Text files
4. SSIS Log Provider for XML files
*/

-- Custom logging table for package execution
CREATE TABLE ETL_ExecutionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID UNIQUEIDENTIFIER,
    PackageName NVARCHAR(255),
    TaskName NVARCHAR(255),
    EventType NVARCHAR(50),
    MessageText NVARCHAR(MAX),
    DataCode INT,
    LogTime DATETIME DEFAULT GETDATE()
);

-- Procedure to log package events
CREATE OR ALTER PROCEDURE sp_LogPackageEvent
    @ExecutionID UNIQUEIDENTIFIER,
    @PackageName NVARCHAR(255),
    @TaskName NVARCHAR(255),
    @EventType NVARCHAR(50),
    @MessageText NVARCHAR(MAX),
    @DataCode INT = 0
AS
BEGIN
    INSERT INTO ETL_ExecutionLog (
        ExecutionID, PackageName, TaskName, EventType,
        MessageText, DataCode
    )
    VALUES (
        @ExecutionID, @PackageName, @TaskName, @EventType,
        @MessageText, @DataCode
    );
END;
GO

-- Execution summary view
CREATE OR ALTER VIEW vw_ETL_ExecutionSummary
AS
SELECT 
    ExecutionID,
    PackageName,
    MIN(LogTime) AS StartTime,
    MAX(LogTime) AS EndTime,
    DATEDIFF(SECOND, MIN(LogTime), MAX(LogTime)) AS DurationSeconds,
    COUNT(*) AS EventCount,
    SUM(CASE WHEN EventType = 'OnError' THEN 1 ELSE 0 END) AS ErrorCount,
    SUM(CASE WHEN EventType = 'OnWarning' THEN 1 ELSE 0 END) AS WarningCount
FROM ETL_ExecutionLog
GROUP BY ExecutionID, PackageName;
GO

SELECT * FROM vw_ETL_ExecutionSummary ORDER BY StartTime DESC;

-- ============================================================================
-- PART 3: PERFORMANCE MONITORING
-- ============================================================================
/*
PERFORMANCE METRICS TO MONITOR:
1. Package Duration
2. Data Flow Throughput (rows/second)
3. Buffer Usage
4. Memory Consumption
5. Task Execution Times
*/

-- Performance tracking table
CREATE TABLE ETL_PerformanceMetrics (
    MetricID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID UNIQUEIDENTIFIER,
    PackageName NVARCHAR(255),
    ComponentName NVARCHAR(255),
    ComponentType NVARCHAR(50),
    StartTime DATETIME,
    EndTime DATETIME,
    DurationMS INT,
    RowsProcessed INT,
    RowsPerSecond DECIMAL(15, 2),
    BuffersUsed INT,
    MemoryUsedMB DECIMAL(10, 2),
    RecordDate DATETIME DEFAULT GETDATE()
);

-- Procedure to log performance metrics
CREATE OR ALTER PROCEDURE sp_LogPerformanceMetrics
    @ExecutionID UNIQUEIDENTIFIER,
    @PackageName NVARCHAR(255),
    @ComponentName NVARCHAR(255),
    @ComponentType NVARCHAR(50),
    @StartTime DATETIME,
    @EndTime DATETIME,
    @RowsProcessed INT,
    @BuffersUsed INT = NULL,
    @MemoryUsedMB DECIMAL(10, 2) = NULL
AS
BEGIN
    DECLARE @DurationMS INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    DECLARE @RowsPerSecond DECIMAL(15, 2);
    
    IF @DurationMS > 0
        SET @RowsPerSecond = (@RowsProcessed * 1000.0) / @DurationMS;
    ELSE
        SET @RowsPerSecond = @RowsProcessed;
    
    INSERT INTO ETL_PerformanceMetrics (
        ExecutionID, PackageName, ComponentName, ComponentType,
        StartTime, EndTime, DurationMS, RowsProcessed,
        RowsPerSecond, BuffersUsed, MemoryUsedMB
    )
    VALUES (
        @ExecutionID, @PackageName, @ComponentName, @ComponentType,
        @StartTime, @EndTime, @DurationMS, @RowsProcessed,
        @RowsPerSecond, @BuffersUsed, @MemoryUsedMB
    );
END;
GO

-- Performance analysis queries
-- Top 10 slowest components
SELECT TOP 10
    ComponentName,
    ComponentType,
    AVG(DurationMS) AS AvgDurationMS,
    AVG(RowsPerSecond) AS AvgThroughput,
    COUNT(*) AS ExecutionCount
FROM ETL_PerformanceMetrics
WHERE RecordDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY ComponentName, ComponentType
ORDER BY AvgDurationMS DESC;

-- Performance trends
SELECT 
    CAST(RecordDate AS DATE) AS ExecutionDate,
    PackageName,
    AVG(DurationMS) AS AvgDurationMS,
    AVG(RowsPerSecond) AS AvgThroughput,
    MAX(MemoryUsedMB) AS MaxMemoryMB
FROM ETL_PerformanceMetrics
WHERE RecordDate >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(RecordDate AS DATE), PackageName
ORDER BY ExecutionDate DESC, PackageName;

-- ============================================================================
-- PART 4: PERFORMANCE OPTIMIZATION TECHNIQUES
-- ============================================================================
/*
OPTIMIZATION STRATEGIES:

1. SOURCE OPTIMIZATION:
   - Filter at source (WHERE clause)
   - Select only needed columns
   - Use indexed views for complex joins
   - Apply NOLOCK for read operations

2. DATA FLOW OPTIMIZATION:
   - Adjust buffer size (DefaultBufferSize, DefaultBufferMaxRows)
   - Minimize transformations
   - Use SQL transformations when possible
   - Avoid blocking transformations (Sort, Aggregate)

3. DESTINATION OPTIMIZATION:
   - Use Fast Load mode
   - Disable constraints during load
   - Rebuild indexes after load
   - Appropriate batch sizes

4. PARALLEL EXECUTION:
   - MaxConcurrentExecutables property
   - Parallel data flows
   - Independent task execution

5. MEMORY MANAGEMENT:
   - Optimize buffer settings
   - Stream data when possible
   - Avoid caching large datasets
*/

-- Create optimized views for better source performance
CREATE OR ALTER VIEW vw_CustomerSource_Optimized
WITH SCHEMABINDING
AS
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    c.Phone,
    c.JoinDate,
    c.IsActive
FROM dbo.BookstoreDB.dbo.Customers c WITH (NOLOCK)
WHERE c.IsActive = 1;
GO

-- Create indexed view
CREATE UNIQUE CLUSTERED INDEX IX_CustomerSource_CustomerID
ON vw_CustomerSource_Optimized(CustomerID);
GO

-- Performance comparison table
CREATE TABLE Performance_Comparison (
    TestID INT IDENTITY(1,1) PRIMARY KEY,
    TestName NVARCHAR(255),
    ApproachDescription NVARCHAR(MAX),
    RowsProcessed INT,
    DurationSeconds INT,
    RowsPerSecond DECIMAL(15, 2),
    MemoryUsedMB DECIMAL(10, 2),
    OptimizationApplied NVARCHAR(MAX),
    TestDate DATETIME DEFAULT GETDATE()
);

-- Insert baseline and optimized results for comparison
INSERT INTO Performance_Comparison (TestName, ApproachDescription, RowsProcessed, DurationSeconds, RowsPerSecond, OptimizationApplied)
VALUES
    ('Customer Load - Baseline', 'Standard OLE DB Source, no optimizations', 100000, 120, 833.33, 'None'),
    ('Customer Load - Source Filter', 'WHERE clause at source', 100000, 90, 1111.11, 'Source-side filtering'),
    ('Customer Load - Fast Load', 'OLE DB Fast Load destination', 100000, 60, 1666.67, 'Fast Load mode'),
    ('Customer Load - Optimized Buffers', 'Increased buffer size to 50MB', 100000, 45, 2222.22, 'Buffer tuning'),
    ('Customer Load - Full Optimization', 'All optimizations combined', 100000, 30, 3333.33, 'Source filter + Fast Load + Buffer tuning');

SELECT * FROM Performance_Comparison ORDER BY RowsPerSecond DESC;

-- ============================================================================
-- PART 5: RETRY LOGIC IMPLEMENTATION
-- ============================================================================
/*
RETRY LOGIC FOR TRANSIENT ERRORS:
- Network timeouts
- Deadlocks
- Temporary resource unavailability
*/

-- Retry configuration table
CREATE TABLE ETL_RetryConfiguration (
    ConfigID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    TaskName NVARCHAR(255),
    MaxRetries INT DEFAULT 3,
    RetryDelaySeconds INT DEFAULT 30,
    RetryOnErrorCodes NVARCHAR(MAX),  -- Comma-separated error codes
    IsEnabled BIT DEFAULT 1
);

INSERT INTO ETL_RetryConfiguration (PackageName, TaskName, MaxRetries, RetryDelaySeconds, RetryOnErrorCodes)
VALUES
    ('PKG_Customer_Load', 'DFT_Extract_Customers', 3, 30, '-2147467259,-2146232060'),  -- Timeout errors
    ('PKG_Order_Load', 'SQL_Truncate_Staging', 5, 10, '1205'),  -- Deadlock
    ('PKG_File_Import', 'FST_Copy_File', 3, 60, '53');  -- Network path not found

/*
FOR LOOP RETRY PATTERN:

For Loop Container: "Retry Logic"
├─ InitExpression: @RetryCount = 0
├─ EvalExpression: @RetryCount < @MaxRetries && @TaskFailed == TRUE
├─ AssignExpression: @RetryCount = @RetryCount + 1
│
└─ Execute SQL Task: "Attempt Operation"
    ├─ Success → Set @TaskFailed = FALSE, exit loop
    └─ Failure → Set @TaskFailed = TRUE, WAITFOR DELAY, continue loop
*/

-- ============================================================================
-- PART 6: DATA QUALITY CHECKS
-- ============================================================================
/*
IMPLEMENT DATA QUALITY VALIDATION:
1. Row count validation
2. Null/empty checks
3. Data type validation
4. Business rule validation
5. Referential integrity checks
*/

-- Data quality results table
CREATE TABLE ETL_DataQualityResults (
    QualityID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID UNIQUEIDENTIFIER,
    PackageName NVARCHAR(255),
    ValidationName NVARCHAR(255),
    ValidationQuery NVARCHAR(MAX),
    ExpectedResult NVARCHAR(MAX),
    ActualResult NVARCHAR(MAX),
    Status NVARCHAR(20),  -- PASS, FAIL, WARNING
    CheckDate DATETIME DEFAULT GETDATE()
);

-- Procedure for row count validation
CREATE OR ALTER PROCEDURE sp_ValidateRowCount
    @ExecutionID UNIQUEIDENTIFIER,
    @PackageName NVARCHAR(255),
    @SourceTable NVARCHAR(255),
    @TargetTable NVARCHAR(255),
    @Tolerance DECIMAL(5, 2) = 0.01  -- 1% tolerance
AS
BEGIN
    DECLARE @SourceCount INT, @TargetCount INT;
    DECLARE @Difference INT, @PercentDiff DECIMAL(5, 2);
    DECLARE @Status NVARCHAR(20);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Get source count
    SET @SQL = 'SELECT @Count = COUNT(*) FROM ' + @SourceTable;
    EXEC sp_executesql @SQL, N'@Count INT OUTPUT', @SourceCount OUTPUT;
    
    -- Get target count
    SET @SQL = 'SELECT @Count = COUNT(*) FROM ' + @TargetTable;
    EXEC sp_executesql @SQL, N'@Count INT OUTPUT', @TargetCount OUTPUT;
    
    -- Calculate difference
    SET @Difference = ABS(@SourceCount - @TargetCount);
    SET @PercentDiff = CASE WHEN @SourceCount > 0 
                            THEN (@Difference * 100.0) / @SourceCount 
                            ELSE 0 END;
    
    -- Determine status
    IF @PercentDiff <= @Tolerance
        SET @Status = 'PASS';
    ELSE IF @PercentDiff <= (@Tolerance * 2)
        SET @Status = 'WARNING';
    ELSE
        SET @Status = 'FAIL';
    
    -- Log result
    INSERT INTO ETL_DataQualityResults (
        ExecutionID, PackageName, ValidationName,
        ValidationQuery, ExpectedResult, ActualResult, Status
    )
    VALUES (
        @ExecutionID, @PackageName, 'Row Count Validation',
        'Source: ' + @SourceTable + ' vs Target: ' + @TargetTable,
        CAST(@SourceCount AS NVARCHAR),
        CAST(@TargetCount AS NVARCHAR) + ' (Diff: ' + CAST(@PercentDiff AS NVARCHAR) + '%)',
        @Status
    );
    
    -- Return status
    SELECT @Status AS ValidationStatus, @SourceCount AS SourceRows, @TargetCount AS TargetRows, @PercentDiff AS PercentDifference;
END;
GO

-- ============================================================================
-- PART 7: CHECKPOINT AND RESTART CAPABILITY
-- ============================================================================
/*
IMPLEMENT CHECKPOINT FOR RESTART CAPABILITY:
- Save progress at key points
- Resume from last checkpoint on restart
- Handle partial failures gracefully
*/

-- Checkpoint tracking table
CREATE TABLE ETL_Checkpoints (
    CheckpointID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID UNIQUEIDENTIFIER,
    PackageName NVARCHAR(255),
    CheckpointName NVARCHAR(255),
    CheckpointData NVARCHAR(MAX),  -- JSON or XML
    CheckpointTime DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20)  -- COMPLETED, IN_PROGRESS, FAILED
);

-- Procedure to save checkpoint
CREATE OR ALTER PROCEDURE sp_SaveCheckpoint
    @ExecutionID UNIQUEIDENTIFIER,
    @PackageName NVARCHAR(255),
    @CheckpointName NVARCHAR(255),
    @CheckpointData NVARCHAR(MAX),
    @Status NVARCHAR(20) = 'COMPLETED'
AS
BEGIN
    INSERT INTO ETL_Checkpoints (ExecutionID, PackageName, CheckpointName, CheckpointData, Status)
    VALUES (@ExecutionID, @PackageName, @CheckpointName, @CheckpointData, @Status);
END;
GO

-- Procedure to get last checkpoint
CREATE OR ALTER PROCEDURE sp_GetLastCheckpoint
    @PackageName NVARCHAR(255),
    @CheckpointName NVARCHAR(255) OUTPUT,
    @CheckpointData NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SELECT TOP 1
        @CheckpointName = CheckpointName,
        @CheckpointData = CheckpointData
    FROM ETL_Checkpoints
    WHERE PackageName = @PackageName
        AND Status = 'COMPLETED'
    ORDER BY CheckpointTime DESC;
END;
GO

-- ============================================================================
-- PART 8: PERFORMANCE BEST PRACTICES CHECKLIST
-- ============================================================================

CREATE TABLE Performance_BestPractices_Checklist (
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    Category NVARCHAR(50),
    BestPractice NVARCHAR(MAX),
    ImpactLevel NVARCHAR(20),  -- HIGH, MEDIUM, LOW
    ImplementationEffort NVARCHAR(20)  -- HIGH, MEDIUM, LOW
);

INSERT INTO Performance_BestPractices_Checklist (Category, BestPractice, ImpactLevel, ImplementationEffort)
VALUES
    ('Source', 'Filter data at source with WHERE clause', 'HIGH', 'LOW'),
    ('Source', 'Select only required columns', 'HIGH', 'LOW'),
    ('Source', 'Use NOLOCK hint for read operations', 'MEDIUM', 'LOW'),
    ('Source', 'Create indexed views for complex joins', 'HIGH', 'MEDIUM'),
    ('Data Flow', 'Adjust DefaultBufferSize and DefaultBufferMaxRows', 'HIGH', 'LOW'),
    ('Data Flow', 'Minimize transformations in pipeline', 'HIGH', 'MEDIUM'),
    ('Data Flow', 'Avoid Sort transformation (sort at source)', 'HIGH', 'LOW'),
    ('Data Flow', 'Use OLE DB Destination in Fast Load mode', 'HIGH', 'LOW'),
    ('Data Flow', 'Remove Data Viewers in production', 'MEDIUM', 'LOW'),
    ('Destination', 'Disable constraints during bulk load', 'HIGH', 'LOW'),
    ('Destination', 'Drop indexes before load, rebuild after', 'HIGH', 'MEDIUM'),
    ('Destination', 'Use appropriate batch sizes', 'MEDIUM', 'LOW'),
    ('Destination', 'Set Table Lock option', 'MEDIUM', 'LOW'),
    ('Package', 'Set MaxConcurrentExecutables for parallelism', 'HIGH', 'LOW'),
    ('Package', 'Use parallel data flows for independent loads', 'HIGH', 'MEDIUM'),
    ('Package', 'Implement connection retry logic', 'MEDIUM', 'MEDIUM'),
    ('Logging', 'Use Basic logging in production', 'MEDIUM', 'LOW'),
    ('Logging', 'Log to database, not text files', 'MEDIUM', 'LOW'),
    ('Memory', 'Monitor and optimize buffer memory usage', 'HIGH', 'MEDIUM'),
    ('Memory', 'Stream large datasets instead of caching', 'HIGH', 'MEDIUM');

SELECT * FROM Performance_BestPractices_Checklist ORDER BY ImpactLevel DESC, Category;

-- ============================================================================
-- EXERCISES & BEST PRACTICES SUMMARY
-- ============================================================================
/*
KEY TAKEAWAYS:

1. ERROR HANDLING:
   ✓ Log all errors to database with full context
   ✓ Implement notification for critical failures
   ✓ Use retry logic for transient errors
   ✓ Clean up resources in error scenarios
   ✓ Test error paths thoroughly

2. LOGGING:
   ✓ Use appropriate logging level (Basic in production)
   ✓ Log to SQL Server for queryability
   ✓ Include execution context (ExecutionID, timestamps)
   ✓ Monitor logs regularly
   ✓ Archive old logs periodically

3. PERFORMANCE:
   ✓ Filter at source, not in pipeline
   ✓ Select only needed columns
   ✓ Use Fast Load mode for destinations
   ✓ Optimize buffer sizes
   ✓ Avoid blocking transformations
   ✓ Enable parallel execution
   ✓ Monitor and profile regularly

4. DATA QUALITY:
   ✓ Validate row counts
   ✓ Check for nulls/empties
   ✓ Implement business rule validation
   ✓ Log validation results
   ✓ Fail gracefully on quality issues

5. MONITORING:
   ✓ Track execution metrics
   ✓ Monitor performance trends
   ✓ Set up alerts for failures
   ✓ Review logs regularly
   ✓ Optimize based on metrics
*/

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Implemented comprehensive error logging
□ Configured package and data flow logging
□ Created performance monitoring framework
□ Applied optimization techniques
□ Implemented retry logic for transient failures
□ Added data quality validation checks
□ Implemented checkpoint/restart capability
□ Reviewed performance best practices
□ Tested error scenarios
□ Documented optimization results

NEXT LAB: Lab 60 - SSIS Capstone Project
============================================================================
*/
