/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  MODULE 07: ADVANCED ETL PATTERNS                                            ║
║  LAB 64: ETL ERROR HANDLING AND RECOVERY                                     ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Learning Objectives:                                                        ║
║  • Implement robust error handling in ETL processes                         ║
║  • Design error staging and quarantine patterns                             ║
║  • Create retry logic for transient failures                                ║
║  • Build notification and alerting systems                                  ║
║  • Develop recovery procedures for failed loads                             ║
║  • Create comprehensive audit trails                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE DataEngineerTraining;
GO

-- ============================================================================
-- SECTION 1: ETL ERROR HANDLING FRAMEWORK
-- ============================================================================

/*
ETL Error Categories:
┌─────────────────────┬────────────────────────────────────────────────────────┐
│ Category            │ Examples                                               │
├─────────────────────┼────────────────────────────────────────────────────────┤
│ Data Quality        │ Invalid data types, constraint violations, nulls     │
│ Connectivity        │ Network timeouts, server unavailable                  │
│ Resource            │ Disk full, memory exhaustion, deadlocks              │
│ Business Rule       │ Duplicate keys, referential integrity                │
│ Transformation      │ Calculation errors, conversion failures              │
│ System              │ Service crashes, permissions issues                  │
└─────────────────────┴────────────────────────────────────────────────────────┘
*/

-- Create ETL management schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
    EXEC('CREATE SCHEMA etl');
GO

-- ============================================================================
-- SECTION 2: ERROR LOGGING INFRASTRUCTURE
-- ============================================================================

-- Main ETL execution log
DROP TABLE IF EXISTS etl.ExecutionLog;
CREATE TABLE etl.ExecutionLog (
    ExecutionID         INT IDENTITY(1,1) PRIMARY KEY,
    PackageName         NVARCHAR(100) NOT NULL,
    TaskName            NVARCHAR(100),
    ExecutionStatus     NVARCHAR(20) NOT NULL,  -- 'Running', 'Success', 'Failed', 'Warning'
    StartTime           DATETIME2 NOT NULL DEFAULT GETDATE(),
    EndTime             DATETIME2,
    RowsProcessed       INT,
    RowsInserted        INT,
    RowsUpdated         INT,
    RowsDeleted         INT,
    RowsErrored         INT,
    ExecutionMessage    NVARCHAR(MAX),
    ParentExecutionID   INT,
    RetryCount          INT DEFAULT 0,
    CreatedBy           NVARCHAR(128) DEFAULT SYSTEM_USER
);
GO

CREATE INDEX IX_ExecutionLog_Package ON etl.ExecutionLog(PackageName, StartTime);
CREATE INDEX IX_ExecutionLog_Status ON etl.ExecutionLog(ExecutionStatus);
GO

-- Detailed error log
DROP TABLE IF EXISTS etl.ErrorLog;
CREATE TABLE etl.ErrorLog (
    ErrorID             INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID         INT NOT NULL,
    ErrorTime           DATETIME2 NOT NULL DEFAULT GETDATE(),
    ErrorNumber         INT,
    ErrorSeverity       INT,
    ErrorState          INT,
    ErrorProcedure      NVARCHAR(200),
    ErrorLine           INT,
    ErrorMessage        NVARCHAR(MAX),
    ErrorContext        NVARCHAR(MAX),      -- Additional context (parameter values, etc.)
    SourceTable         NVARCHAR(200),
    TargetTable         NVARCHAR(200),
    RecordIdentifier    NVARCHAR(500),      -- Business key of failed record
    IsResolved          BIT DEFAULT 0,
    ResolvedDate        DATETIME2,
    ResolvedBy          NVARCHAR(128),
    ResolutionNotes     NVARCHAR(MAX)
);
GO

CREATE INDEX IX_ErrorLog_Execution ON etl.ErrorLog(ExecutionID);
CREATE INDEX IX_ErrorLog_Unresolved ON etl.ErrorLog(IsResolved) WHERE IsResolved = 0;
GO

-- Error row quarantine (for data quality issues)
DROP TABLE IF EXISTS etl.ErrorRowQuarantine;
CREATE TABLE etl.ErrorRowQuarantine (
    QuarantineID        INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID         INT NOT NULL,
    ErrorID             INT,
    SourceSystem        NVARCHAR(100) NOT NULL,
    SourceTable         NVARCHAR(200) NOT NULL,
    RecordData          NVARCHAR(MAX),          -- JSON representation of the row
    ErrorCategory       NVARCHAR(50),           -- 'DataType', 'Constraint', 'Business Rule', etc.
    ErrorDescription    NVARCHAR(MAX),
    QuarantineDate      DATETIME2 DEFAULT GETDATE(),
    RetryCount          INT DEFAULT 0,
    LastRetryDate       DATETIME2,
    Status              NVARCHAR(20) DEFAULT 'Pending',  -- 'Pending', 'Retried', 'Fixed', 'Discarded'
    FixedDate           DATETIME2,
    FixedBy             NVARCHAR(128),
    Notes               NVARCHAR(MAX)
);
GO

CREATE INDEX IX_Quarantine_Status ON etl.ErrorRowQuarantine(Status);
CREATE INDEX IX_Quarantine_Source ON etl.ErrorRowQuarantine(SourceSystem, SourceTable);
GO

-- ============================================================================
-- SECTION 3: ERROR HANDLING PROCEDURES
-- ============================================================================

-- Start ETL execution logging
CREATE OR ALTER PROCEDURE etl.usp_StartExecution
    @PackageName        NVARCHAR(100),
    @TaskName           NVARCHAR(100) = NULL,
    @ParentExecutionID  INT = NULL,
    @ExecutionID        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO etl.ExecutionLog (PackageName, TaskName, ExecutionStatus, ParentExecutionID)
    VALUES (@PackageName, @TaskName, 'Running', @ParentExecutionID);
    
    SET @ExecutionID = SCOPE_IDENTITY();
    
    -- Log start
    PRINT 'ETL Execution Started: ' + @PackageName + ' (ID: ' + CAST(@ExecutionID AS VARCHAR(10)) + ')';
END;
GO

-- Complete ETL execution (success)
CREATE OR ALTER PROCEDURE etl.usp_CompleteExecution
    @ExecutionID        INT,
    @RowsProcessed      INT = NULL,
    @RowsInserted       INT = NULL,
    @RowsUpdated        INT = NULL,
    @RowsDeleted        INT = NULL,
    @RowsErrored        INT = NULL,
    @Message            NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Status NVARCHAR(20) = 'Success';
    
    -- Check if there were errors
    IF @RowsErrored > 0
        SET @Status = 'Warning';
    
    UPDATE etl.ExecutionLog
    SET ExecutionStatus = @Status,
        EndTime = GETDATE(),
        RowsProcessed = @RowsProcessed,
        RowsInserted = @RowsInserted,
        RowsUpdated = @RowsUpdated,
        RowsDeleted = @RowsDeleted,
        RowsErrored = @RowsErrored,
        ExecutionMessage = @Message
    WHERE ExecutionID = @ExecutionID;
    
    PRINT 'ETL Execution Complete: ' + @Status + ' (ID: ' + CAST(@ExecutionID AS VARCHAR(10)) + ')';
END;
GO

-- Fail ETL execution
CREATE OR ALTER PROCEDURE etl.usp_FailExecution
    @ExecutionID        INT,
    @ErrorMessage       NVARCHAR(MAX) = NULL,
    @RowsProcessed      INT = NULL,
    @RowsErrored        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE etl.ExecutionLog
    SET ExecutionStatus = 'Failed',
        EndTime = GETDATE(),
        RowsProcessed = @RowsProcessed,
        RowsErrored = @RowsErrored,
        ExecutionMessage = @ErrorMessage
    WHERE ExecutionID = @ExecutionID;
    
    -- Also log to error table
    INSERT INTO etl.ErrorLog (
        ExecutionID, ErrorNumber, ErrorSeverity, ErrorState,
        ErrorProcedure, ErrorLine, ErrorMessage
    )
    VALUES (
        @ExecutionID, ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
        ERROR_PROCEDURE(), ERROR_LINE(), @ErrorMessage
    );
    
    PRINT 'ETL Execution FAILED (ID: ' + CAST(@ExecutionID AS VARCHAR(10)) + '): ' + @ErrorMessage;
END;
GO

-- Log individual error
CREATE OR ALTER PROCEDURE etl.usp_LogError
    @ExecutionID        INT,
    @ErrorContext       NVARCHAR(MAX) = NULL,
    @SourceTable        NVARCHAR(200) = NULL,
    @TargetTable        NVARCHAR(200) = NULL,
    @RecordIdentifier   NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO etl.ErrorLog (
        ExecutionID,
        ErrorNumber,
        ErrorSeverity,
        ErrorState,
        ErrorProcedure,
        ErrorLine,
        ErrorMessage,
        ErrorContext,
        SourceTable,
        TargetTable,
        RecordIdentifier
    )
    VALUES (
        @ExecutionID,
        ERROR_NUMBER(),
        ERROR_SEVERITY(),
        ERROR_STATE(),
        ERROR_PROCEDURE(),
        ERROR_LINE(),
        ERROR_MESSAGE(),
        @ErrorContext,
        @SourceTable,
        @TargetTable,
        @RecordIdentifier
    );
END;
GO

-- Quarantine bad records
CREATE OR ALTER PROCEDURE etl.usp_QuarantineRecord
    @ExecutionID        INT,
    @SourceSystem       NVARCHAR(100),
    @SourceTable        NVARCHAR(200),
    @RecordData         NVARCHAR(MAX),
    @ErrorCategory      NVARCHAR(50),
    @ErrorDescription   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO etl.ErrorRowQuarantine (
        ExecutionID,
        SourceSystem,
        SourceTable,
        RecordData,
        ErrorCategory,
        ErrorDescription
    )
    VALUES (
        @ExecutionID,
        @SourceSystem,
        @SourceTable,
        @RecordData,
        @ErrorCategory,
        @ErrorDescription
    );
    
    RETURN SCOPE_IDENTITY();
END;
GO

-- ============================================================================
-- SECTION 4: RETRY LOGIC IMPLEMENTATION
-- ============================================================================

/*
Retry Patterns:
1. Simple Retry - Fixed number of attempts with fixed delay
2. Exponential Backoff - Increasing delay between retries
3. Circuit Breaker - Stop retrying after threshold reached
*/

-- Retry configuration table
DROP TABLE IF EXISTS etl.RetryConfiguration;
CREATE TABLE etl.RetryConfiguration (
    ConfigID            INT IDENTITY(1,1) PRIMARY KEY,
    ProcessName         NVARCHAR(100) NOT NULL UNIQUE,
    MaxRetries          INT NOT NULL DEFAULT 3,
    RetryDelaySeconds   INT NOT NULL DEFAULT 30,
    UseExponentialBackoff BIT NOT NULL DEFAULT 0,
    MaxDelaySeconds     INT DEFAULT 300,
    IsCircuitBreakerEnabled BIT DEFAULT 0,
    CircuitBreakerThreshold INT DEFAULT 5,
    CircuitBreakerResetMinutes INT DEFAULT 30
);
GO

-- Insert default configurations
INSERT INTO etl.RetryConfiguration (ProcessName, MaxRetries, RetryDelaySeconds, UseExponentialBackoff)
VALUES 
    ('CustomerLoad', 3, 30, 1),
    ('ProductLoad', 3, 15, 0),
    ('SalesLoad', 5, 60, 1),
    ('Default', 3, 30, 0);
GO

-- Circuit breaker state tracking
DROP TABLE IF EXISTS etl.CircuitBreakerState;
CREATE TABLE etl.CircuitBreakerState (
    ProcessName         NVARCHAR(100) PRIMARY KEY,
    FailureCount        INT DEFAULT 0,
    LastFailureTime     DATETIME2,
    IsOpen              BIT DEFAULT 0,     -- 1 = circuit open (stop trying)
    OpenedTime          DATETIME2,
    LastSuccessTime     DATETIME2
);
GO

-- Procedure with retry logic
CREATE OR ALTER PROCEDURE etl.usp_ExecuteWithRetry
    @ProcessName        NVARCHAR(100),
    @SQLCommand         NVARCHAR(MAX),
    @ExecutionID        INT OUTPUT,
    @Success            BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaxRetries INT, @RetryDelay INT, @UseExponential BIT, @MaxDelay INT;
    DECLARE @CurrentRetry INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    
    -- Get retry configuration
    SELECT @MaxRetries = MaxRetries,
           @RetryDelay = RetryDelaySeconds,
           @UseExponential = UseExponentialBackoff,
           @MaxDelay = MaxDelaySeconds
    FROM etl.RetryConfiguration
    WHERE ProcessName = @ProcessName;
    
    -- Use default if not found
    IF @MaxRetries IS NULL
    BEGIN
        SELECT @MaxRetries = MaxRetries,
               @RetryDelay = RetryDelaySeconds,
               @UseExponential = UseExponentialBackoff,
               @MaxDelay = MaxDelaySeconds
        FROM etl.RetryConfiguration
        WHERE ProcessName = 'Default';
    END
    
    -- Start execution logging
    EXEC etl.usp_StartExecution @PackageName = @ProcessName, @ExecutionID = @ExecutionID OUTPUT;
    
    SET @Success = 0;
    
    WHILE @CurrentRetry <= @MaxRetries AND @Success = 0
    BEGIN
        BEGIN TRY
            -- Execute the SQL command
            EXEC sp_executesql @SQLCommand;
            
            SET @Success = 1;
            
            -- Complete successfully
            EXEC etl.usp_CompleteExecution 
                @ExecutionID = @ExecutionID,
                @Message = 'Completed successfully';
            
        END TRY
        BEGIN CATCH
            SET @ErrorMessage = ERROR_MESSAGE();
            SET @CurrentRetry = @CurrentRetry + 1;
            
            -- Log the error
            EXEC etl.usp_LogError 
                @ExecutionID = @ExecutionID,
                @ErrorContext = @SQLCommand;
            
            IF @CurrentRetry <= @MaxRetries
            BEGIN
                -- Calculate delay
                DECLARE @ActualDelay INT;
                IF @UseExponential = 1
                    SET @ActualDelay = @RetryDelay * POWER(2, @CurrentRetry - 1);
                ELSE
                    SET @ActualDelay = @RetryDelay;
                
                -- Cap at max delay
                IF @ActualDelay > @MaxDelay
                    SET @ActualDelay = @MaxDelay;
                
                -- Update retry count
                UPDATE etl.ExecutionLog
                SET RetryCount = @CurrentRetry,
                    ExecutionMessage = 'Retry ' + CAST(@CurrentRetry AS VARCHAR(10)) + 
                                       ' of ' + CAST(@MaxRetries AS VARCHAR(10)) +
                                       '. Waiting ' + CAST(@ActualDelay AS VARCHAR(10)) + ' seconds...'
                WHERE ExecutionID = @ExecutionID;
                
                -- Wait before retry
                WAITFOR DELAY @ActualDelay;  -- Note: WAITFOR doesn't accept variables in seconds
                
                PRINT 'Retry ' + CAST(@CurrentRetry AS VARCHAR(10)) + ' after error: ' + @ErrorMessage;
            END
            ELSE
            BEGIN
                -- All retries exhausted
                EXEC etl.usp_FailExecution 
                    @ExecutionID = @ExecutionID,
                    @ErrorMessage = @ErrorMessage;
            END
        END CATCH
    END
    
    RETURN;
END;
GO

-- ============================================================================
-- SECTION 5: ERROR ROW REDIRECTION PATTERN
-- ============================================================================

/*
Pattern: Good rows → Target table
         Bad rows → Quarantine table
*/

-- Create sample source and target tables
DROP TABLE IF EXISTS staging.SalesData;
CREATE TABLE staging.SalesData (
    RowID               INT IDENTITY(1,1),
    SaleDate            NVARCHAR(50),       -- Intentionally string for validation
    CustomerID          NVARCHAR(50),
    ProductID           NVARCHAR(50),
    Quantity            NVARCHAR(50),
    UnitPrice           NVARCHAR(50),
    TotalAmount         NVARCHAR(50),
    LoadBatchID         INT
);
GO

DROP TABLE IF EXISTS dbo.Sales;
CREATE TABLE dbo.Sales (
    SaleID              INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate            DATE NOT NULL,
    CustomerID          INT NOT NULL,
    ProductID           INT NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(10,2) NOT NULL,
    TotalAmount         DECIMAL(12,2) NOT NULL,
    LoadBatchID         INT,
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- Insert test data with some bad rows
INSERT INTO staging.SalesData (SaleDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, LoadBatchID)
VALUES 
    ('2024-01-15', '1001', '101', '5', '19.99', '99.95', 1),     -- Good
    ('2024-01-16', '1002', '102', '3', '29.99', '89.97', 1),     -- Good
    ('2024-01-17', 'ABC', '103', '2', '15.00', '30.00', 1),      -- Bad: CustomerID not numeric
    ('INVALID', '1003', '104', '1', '49.99', '49.99', 1),        -- Bad: Invalid date
    ('2024-01-18', '1004', '105', '-5', '25.00', '-125.00', 1),  -- Bad: Negative quantity
    ('2024-01-19', '1005', '106', '10', '9.99', '99.90', 1),     -- Good
    ('2024-01-20', NULL, '107', '4', '12.50', '50.00', 1),       -- Bad: NULL CustomerID
    ('2024-01-21', '1006', '108', '2', 'FREE', '0.00', 1);       -- Bad: Invalid price
GO

-- Procedure with row-level error handling
CREATE OR ALTER PROCEDURE etl.usp_LoadSalesWithErrorHandling
    @LoadBatchID    INT,
    @ExecutionID    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsProcessed INT = 0;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsErrored INT = 0;
    
    -- Start execution
    EXEC etl.usp_StartExecution 
        @PackageName = 'SalesLoad', 
        @TaskName = 'Load with Error Handling',
        @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        -- Process each row individually for granular error handling
        DECLARE @RowID INT, @SaleDate NVARCHAR(50), @CustomerID NVARCHAR(50);
        DECLARE @ProductID NVARCHAR(50), @Quantity NVARCHAR(50);
        DECLARE @UnitPrice NVARCHAR(50), @TotalAmount NVARCHAR(50);
        
        -- Cursor for row-by-row processing (use for complex validation)
        DECLARE row_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT RowID, SaleDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount
            FROM staging.SalesData
            WHERE LoadBatchID = @LoadBatchID;
        
        OPEN row_cursor;
        FETCH NEXT FROM row_cursor INTO @RowID, @SaleDate, @CustomerID, @ProductID, @Quantity, @UnitPrice, @TotalAmount;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @RowsProcessed = @RowsProcessed + 1;
            
            BEGIN TRY
                -- Validate data
                DECLARE @ErrorList NVARCHAR(MAX) = '';
                
                -- Validate date
                IF TRY_CAST(@SaleDate AS DATE) IS NULL
                    SET @ErrorList = @ErrorList + 'Invalid date format; ';
                
                -- Validate CustomerID
                IF @CustomerID IS NULL OR TRY_CAST(@CustomerID AS INT) IS NULL
                    SET @ErrorList = @ErrorList + 'Invalid or NULL CustomerID; ';
                
                -- Validate ProductID
                IF TRY_CAST(@ProductID AS INT) IS NULL
                    SET @ErrorList = @ErrorList + 'Invalid ProductID; ';
                
                -- Validate Quantity (must be positive)
                IF TRY_CAST(@Quantity AS INT) IS NULL OR CAST(@Quantity AS INT) <= 0
                    SET @ErrorList = @ErrorList + 'Invalid or non-positive Quantity; ';
                
                -- Validate UnitPrice
                IF TRY_CAST(@UnitPrice AS DECIMAL(10,2)) IS NULL
                    SET @ErrorList = @ErrorList + 'Invalid UnitPrice; ';
                
                IF LEN(@ErrorList) > 0
                BEGIN
                    -- Quarantine the bad row
                    DECLARE @RecordJSON NVARCHAR(MAX) = (
                        SELECT @SaleDate AS SaleDate, @CustomerID AS CustomerID, 
                               @ProductID AS ProductID, @Quantity AS Quantity,
                               @UnitPrice AS UnitPrice, @TotalAmount AS TotalAmount
                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                    );
                    
                    EXEC etl.usp_QuarantineRecord
                        @ExecutionID = @ExecutionID,
                        @SourceSystem = 'Sales',
                        @SourceTable = 'staging.SalesData',
                        @RecordData = @RecordJSON,
                        @ErrorCategory = 'DataValidation',
                        @ErrorDescription = @ErrorList;
                    
                    SET @RowsErrored = @RowsErrored + 1;
                END
                ELSE
                BEGIN
                    -- Insert good row
                    INSERT INTO dbo.Sales (SaleDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, LoadBatchID)
                    VALUES (
                        CAST(@SaleDate AS DATE),
                        CAST(@CustomerID AS INT),
                        CAST(@ProductID AS INT),
                        CAST(@Quantity AS INT),
                        CAST(@UnitPrice AS DECIMAL(10,2)),
                        CAST(@TotalAmount AS DECIMAL(12,2)),
                        @LoadBatchID
                    );
                    
                    SET @RowsInserted = @RowsInserted + 1;
                END
            END TRY
            BEGIN CATCH
                -- Unexpected error - quarantine
                DECLARE @UnexpectedError NVARCHAR(MAX) = ERROR_MESSAGE();
                
                EXEC etl.usp_QuarantineRecord
                    @ExecutionID = @ExecutionID,
                    @SourceSystem = 'Sales',
                    @SourceTable = 'staging.SalesData',
                    @RecordData = CONCAT('RowID:', @RowID),
                    @ErrorCategory = 'UnexpectedError',
                    @ErrorDescription = @UnexpectedError;
                
                SET @RowsErrored = @RowsErrored + 1;
            END CATCH
            
            FETCH NEXT FROM row_cursor INTO @RowID, @SaleDate, @CustomerID, @ProductID, @Quantity, @UnitPrice, @TotalAmount;
        END
        
        CLOSE row_cursor;
        DEALLOCATE row_cursor;
        
        -- Complete execution
        EXEC etl.usp_CompleteExecution
            @ExecutionID = @ExecutionID,
            @RowsProcessed = @RowsProcessed,
            @RowsInserted = @RowsInserted,
            @RowsErrored = @RowsErrored,
            @Message = 'Load complete with row-level error handling';
            
    END TRY
    BEGIN CATCH
        EXEC etl.usp_FailExecution
            @ExecutionID = @ExecutionID,
            @ErrorMessage = ERROR_MESSAGE(),
            @RowsProcessed = @RowsProcessed,
            @RowsErrored = @RowsErrored;
    END CATCH
END;
GO

-- Execute the load
DECLARE @ExecID INT;
EXEC etl.usp_LoadSalesWithErrorHandling @LoadBatchID = 1, @ExecutionID = @ExecID OUTPUT;

-- Check results
SELECT * FROM dbo.Sales;
SELECT * FROM etl.ErrorRowQuarantine;
SELECT * FROM etl.ExecutionLog WHERE ExecutionID = @ExecID;
GO

-- ============================================================================
-- SECTION 6: SET-BASED ERROR HANDLING (More Efficient)
-- ============================================================================

-- Efficient set-based approach with CASE expressions
CREATE OR ALTER PROCEDURE etl.usp_LoadSalesSetBased
    @LoadBatchID    INT,
    @ExecutionID    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    EXEC etl.usp_StartExecution @PackageName = 'SalesLoadSetBased', @ExecutionID = @ExecutionID OUTPUT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Identify and quarantine bad rows first
        INSERT INTO etl.ErrorRowQuarantine (ExecutionID, SourceSystem, SourceTable, RecordData, ErrorCategory, ErrorDescription)
        SELECT 
            @ExecutionID,
            'Sales',
            'staging.SalesData',
            (SELECT s.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            'DataValidation',
            CONCAT(
                CASE WHEN TRY_CAST(SaleDate AS DATE) IS NULL THEN 'Invalid date; ' ELSE '' END,
                CASE WHEN CustomerID IS NULL OR TRY_CAST(CustomerID AS INT) IS NULL THEN 'Invalid CustomerID; ' ELSE '' END,
                CASE WHEN TRY_CAST(ProductID AS INT) IS NULL THEN 'Invalid ProductID; ' ELSE '' END,
                CASE WHEN TRY_CAST(Quantity AS INT) IS NULL OR CAST(Quantity AS INT) <= 0 THEN 'Invalid Quantity; ' ELSE '' END,
                CASE WHEN TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NULL THEN 'Invalid UnitPrice; ' ELSE '' END
            )
        FROM staging.SalesData s
        WHERE LoadBatchID = @LoadBatchID
        AND (
            TRY_CAST(SaleDate AS DATE) IS NULL OR
            CustomerID IS NULL OR
            TRY_CAST(CustomerID AS INT) IS NULL OR
            TRY_CAST(ProductID AS INT) IS NULL OR
            TRY_CAST(Quantity AS INT) IS NULL OR
            CAST(Quantity AS INT) <= 0 OR
            TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NULL
        );
        
        DECLARE @ErrorCount INT = @@ROWCOUNT;
        
        -- Insert good rows
        INSERT INTO dbo.Sales (SaleDate, CustomerID, ProductID, Quantity, UnitPrice, TotalAmount, LoadBatchID)
        SELECT 
            CAST(SaleDate AS DATE),
            CAST(CustomerID AS INT),
            CAST(ProductID AS INT),
            CAST(Quantity AS INT),
            CAST(UnitPrice AS DECIMAL(10,2)),
            CAST(TotalAmount AS DECIMAL(12,2)),
            LoadBatchID
        FROM staging.SalesData
        WHERE LoadBatchID = @LoadBatchID
        AND TRY_CAST(SaleDate AS DATE) IS NOT NULL
        AND CustomerID IS NOT NULL
        AND TRY_CAST(CustomerID AS INT) IS NOT NULL
        AND TRY_CAST(ProductID AS INT) IS NOT NULL
        AND TRY_CAST(Quantity AS INT) IS NOT NULL
        AND CAST(Quantity AS INT) > 0
        AND TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NOT NULL;
        
        DECLARE @InsertCount INT = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        EXEC etl.usp_CompleteExecution
            @ExecutionID = @ExecutionID,
            @RowsProcessed = @InsertCount + @ErrorCount,
            @RowsInserted = @InsertCount,
            @RowsErrored = @ErrorCount;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        EXEC etl.usp_FailExecution
            @ExecutionID = @ExecutionID,
            @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END;
GO

-- ============================================================================
-- SECTION 7: RECOVERY PROCEDURES
-- ============================================================================

-- Procedure to reprocess quarantined records after fixing
CREATE OR ALTER PROCEDURE etl.usp_ReprocessQuarantinedRecords
    @SourceTable        NVARCHAR(200) = NULL,
    @MaxRecordsToProcess INT = 1000
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionID INT;
    EXEC etl.usp_StartExecution @PackageName = 'QuarantineReprocess', @ExecutionID = @ExecutionID OUTPUT;
    
    DECLARE @Processed INT = 0, @Succeeded INT = 0, @Failed INT = 0;
    
    -- Get quarantined records
    DECLARE @QuarantineID INT, @RecordData NVARCHAR(MAX);
    
    DECLARE quarantine_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP (@MaxRecordsToProcess) QuarantineID, RecordData
        FROM etl.ErrorRowQuarantine
        WHERE Status = 'Pending'
        AND (@SourceTable IS NULL OR SourceTable = @SourceTable);
    
    OPEN quarantine_cursor;
    FETCH NEXT FROM quarantine_cursor INTO @QuarantineID, @RecordData;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Processed = @Processed + 1;
        
        BEGIN TRY
            -- Parse JSON and attempt to insert
            -- This would be customized based on target table structure
            
            -- For demo, just mark as retried
            UPDATE etl.ErrorRowQuarantine
            SET Status = 'Retried',
                RetryCount = RetryCount + 1,
                LastRetryDate = GETDATE()
            WHERE QuarantineID = @QuarantineID;
            
            SET @Succeeded = @Succeeded + 1;
            
        END TRY
        BEGIN CATCH
            SET @Failed = @Failed + 1;
            
            UPDATE etl.ErrorRowQuarantine
            SET RetryCount = RetryCount + 1,
                LastRetryDate = GETDATE(),
                Notes = ISNULL(Notes, '') + CHAR(13) + 'Retry failed: ' + ERROR_MESSAGE()
            WHERE QuarantineID = @QuarantineID;
        END CATCH
        
        FETCH NEXT FROM quarantine_cursor INTO @QuarantineID, @RecordData;
    END
    
    CLOSE quarantine_cursor;
    DEALLOCATE quarantine_cursor;
    
    EXEC etl.usp_CompleteExecution
        @ExecutionID = @ExecutionID,
        @RowsProcessed = @Processed,
        @RowsInserted = @Succeeded,
        @RowsErrored = @Failed;
    
    -- Return summary
    SELECT @Processed AS Processed, @Succeeded AS Succeeded, @Failed AS Failed;
END;
GO

-- Procedure to rollback a failed execution
CREATE OR ALTER PROCEDURE etl.usp_RollbackExecution
    @ExecutionID    INT,
    @TargetTable    NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get batch ID from execution log
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @RowsDeleted INT;
    
    -- Dynamic SQL to delete rows loaded by this execution
    SET @SQL = 'DELETE FROM ' + QUOTENAME(PARSENAME(@TargetTable, 2)) + '.' + QUOTENAME(PARSENAME(@TargetTable, 1)) +
               ' WHERE LoadBatchID = ' + CAST(@ExecutionID AS VARCHAR(10));
    
    BEGIN TRY
        EXEC sp_executesql @SQL;
        SET @RowsDeleted = @@ROWCOUNT;
        
        PRINT 'Rolled back ' + CAST(@RowsDeleted AS VARCHAR(10)) + ' rows from ExecutionID ' + CAST(@ExecutionID AS VARCHAR(10));
        
        -- Update execution log
        UPDATE etl.ExecutionLog
        SET ExecutionStatus = 'Rolled Back',
            ExecutionMessage = 'Rolled back ' + CAST(@RowsDeleted AS VARCHAR(10)) + ' rows'
        WHERE ExecutionID = @ExecutionID;
        
    END TRY
    BEGIN CATCH
        PRINT 'Rollback failed: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- ============================================================================
-- SECTION 8: NOTIFICATION AND ALERTING
-- ============================================================================

-- Alert configuration
DROP TABLE IF EXISTS etl.AlertConfiguration;
CREATE TABLE etl.AlertConfiguration (
    AlertID             INT IDENTITY(1,1) PRIMARY KEY,
    AlertName           NVARCHAR(100) NOT NULL,
    AlertType           NVARCHAR(50) NOT NULL,      -- 'Email', 'Log', 'EventLog'
    Condition           NVARCHAR(200) NOT NULL,     -- 'FailureCount > 3', 'ErrorRate > 10%'
    Recipients          NVARCHAR(500),              -- Email addresses
    IsEnabled           BIT DEFAULT 1
);
GO

INSERT INTO etl.AlertConfiguration (AlertName, AlertType, Condition, Recipients)
VALUES 
    ('ETL Failure', 'Email', 'ExecutionStatus = Failed', 'etl-team@company.com'),
    ('High Error Rate', 'Email', 'ErrorRate > 10', 'data-quality@company.com'),
    ('Quarantine Threshold', 'Email', 'QuarantineCount > 100', 'data-steward@company.com');
GO

-- Procedure to check and send alerts
CREATE OR ALTER PROCEDURE etl.usp_CheckAndSendAlerts
    @ExecutionID    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for failures in last hour
    IF EXISTS (
        SELECT 1 FROM etl.ExecutionLog 
        WHERE ExecutionStatus = 'Failed' 
        AND EndTime > DATEADD(HOUR, -1, GETDATE())
    )
    BEGIN
        -- In production, this would send email via Database Mail
        PRINT '*** ALERT: ETL Failures detected in the last hour! ***';
        
        SELECT PackageName, TaskName, ExecutionMessage, EndTime
        FROM etl.ExecutionLog
        WHERE ExecutionStatus = 'Failed'
        AND EndTime > DATEADD(HOUR, -1, GETDATE())
        ORDER BY EndTime DESC;
    END
    
    -- Check quarantine threshold
    DECLARE @QuarantineCount INT;
    SELECT @QuarantineCount = COUNT(*) FROM etl.ErrorRowQuarantine WHERE Status = 'Pending';
    
    IF @QuarantineCount > 100
    BEGIN
        PRINT '*** ALERT: High quarantine count: ' + CAST(@QuarantineCount AS VARCHAR(10)) + ' pending records ***';
    END
END;
GO

-- ============================================================================
-- SECTION 9: MONITORING VIEWS AND REPORTS
-- ============================================================================

-- ETL Dashboard View
CREATE OR ALTER VIEW etl.vw_ExecutionDashboard
AS
SELECT 
    CAST(StartTime AS DATE) AS ExecutionDate,
    PackageName,
    COUNT(*) AS TotalExecutions,
    SUM(CASE WHEN ExecutionStatus = 'Success' THEN 1 ELSE 0 END) AS Succeeded,
    SUM(CASE WHEN ExecutionStatus = 'Failed' THEN 1 ELSE 0 END) AS Failed,
    SUM(CASE WHEN ExecutionStatus = 'Warning' THEN 1 ELSE 0 END) AS Warnings,
    SUM(ISNULL(RowsProcessed, 0)) AS TotalRowsProcessed,
    SUM(ISNULL(RowsErrored, 0)) AS TotalRowsErrored,
    CASE WHEN SUM(ISNULL(RowsProcessed, 0)) > 0 
         THEN CAST(SUM(ISNULL(RowsErrored, 0)) * 100.0 / SUM(ISNULL(RowsProcessed, 0)) AS DECIMAL(5,2))
         ELSE 0 END AS ErrorRate,
    AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSeconds
FROM etl.ExecutionLog
WHERE StartTime > DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(StartTime AS DATE), PackageName;
GO

-- Quarantine Summary View
CREATE OR ALTER VIEW etl.vw_QuarantineSummary
AS
SELECT 
    SourceSystem,
    SourceTable,
    ErrorCategory,
    Status,
    COUNT(*) AS RecordCount,
    MIN(QuarantineDate) AS OldestRecord,
    MAX(QuarantineDate) AS NewestRecord,
    AVG(RetryCount) AS AvgRetries
FROM etl.ErrorRowQuarantine
GROUP BY SourceSystem, SourceTable, ErrorCategory, Status;
GO

-- ============================================================================
-- SECTION 10: EXERCISES
-- ============================================================================

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 1: IMPLEMENT CIRCUIT BREAKER PATTERN                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create a procedure that:                                                    ║
║  1. Checks circuit breaker state before executing                           ║
║  2. Tracks consecutive failures                                             ║
║  3. Opens circuit after threshold reached                                   ║
║  4. Automatically resets after timeout                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 2: CREATE DATA QUALITY REPORT                                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create a stored procedure that generates a data quality report including:  ║
║  - Error counts by category                                                 ║
║  - Error trends over time                                                   ║
║  - Top error-prone source tables                                           ║
║  - Recommended actions                                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 3: IMPLEMENT DEAD LETTER QUEUE                                     ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create a system that:                                                       ║
║  1. Moves records to dead letter queue after max retries                    ║
║  2. Provides manual review interface                                        ║
║  3. Allows manual fix and resubmit                                         ║
║  4. Tracks resolution history                                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
/*
DROP TABLE IF EXISTS etl.ExecutionLog;
DROP TABLE IF EXISTS etl.ErrorLog;
DROP TABLE IF EXISTS etl.ErrorRowQuarantine;
DROP TABLE IF EXISTS etl.RetryConfiguration;
DROP TABLE IF EXISTS etl.CircuitBreakerState;
DROP TABLE IF EXISTS etl.AlertConfiguration;

DROP TABLE IF EXISTS staging.SalesData;
DROP TABLE IF EXISTS dbo.Sales;

DROP VIEW IF EXISTS etl.vw_ExecutionDashboard;
DROP VIEW IF EXISTS etl.vw_QuarantineSummary;

DROP PROCEDURE IF EXISTS etl.usp_StartExecution;
DROP PROCEDURE IF EXISTS etl.usp_CompleteExecution;
DROP PROCEDURE IF EXISTS etl.usp_FailExecution;
DROP PROCEDURE IF EXISTS etl.usp_LogError;
DROP PROCEDURE IF EXISTS etl.usp_QuarantineRecord;
DROP PROCEDURE IF EXISTS etl.usp_ExecuteWithRetry;
DROP PROCEDURE IF EXISTS etl.usp_LoadSalesWithErrorHandling;
DROP PROCEDURE IF EXISTS etl.usp_LoadSalesSetBased;
DROP PROCEDURE IF EXISTS etl.usp_ReprocessQuarantinedRecords;
DROP PROCEDURE IF EXISTS etl.usp_RollbackExecution;
DROP PROCEDURE IF EXISTS etl.usp_CheckAndSendAlerts;

DROP SCHEMA IF EXISTS etl;
DROP SCHEMA IF EXISTS staging;
*/

PRINT '═══════════════════════════════════════════════════════════════════════════';
PRINT '  Lab 64: ETL Error Handling and Recovery - Complete';
PRINT '═══════════════════════════════════════════════════════════════════════════';
GO
