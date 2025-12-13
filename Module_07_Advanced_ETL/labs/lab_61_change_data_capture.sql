/*
============================================================================
LAB 61: CHANGE DATA CAPTURE (CDC) FOR INCREMENTAL LOADS
Module 07: Advanced ETL Patterns
============================================================================

OBJECTIVE:
- Implement SQL Server Change Data Capture (CDC)
- Build incremental ETL processes
- Track data changes efficiently
- Handle INSERT, UPDATE, DELETE operations
- Optimize ETL performance with CDC

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)

PREREQUISITES:
- Completed Module 06
- SQL Server Enterprise/Developer Edition (CDC requires)
- Sysadmin or db_owner permissions

DATABASE: BookstoreDB, BookstoreETL
============================================================================
*/

USE BookstoreDB;
GO

-- ============================================================================
-- PART 1: ENABLE CHANGE DATA CAPTURE
-- ============================================================================
/*
CDC ARCHITECTURE:
- System tables: cdc.* tables store change data
- Capture job: Reads transaction log
- Cleanup job: Removes old change data
- LSN (Log Sequence Number): Tracks changes

PREREQUISITES:
- SQL Server Agent must be running
- Database must be in FULL or BULK_LOGGED recovery
*/

-- Check if CDC is enabled on database
SELECT 
    name AS DatabaseName,
    is_cdc_enabled,
    CASE WHEN is_cdc_enabled = 1 THEN 'Enabled' ELSE 'Disabled' END AS CDC_Status
FROM sys.databases
WHERE name = 'BookstoreDB';

-- Enable CDC on database
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BookstoreDB' AND is_cdc_enabled = 1)
BEGIN
    EXEC sys.sp_cdc_enable_db;
    PRINT 'CDC enabled on BookstoreDB';
END
ELSE
    PRINT 'CDC already enabled on BookstoreDB';
GO

-- Verify CDC system objects
SELECT 
    name, 
    type_desc,
    create_date
FROM sys.objects
WHERE schema_id = SCHEMA_ID('cdc')
ORDER BY type_desc, name;

-- ============================================================================
-- PART 2: ENABLE CDC ON TABLES
-- ============================================================================
/*
sp_cdc_enable_table PARAMETERS:
@source_schema: Schema name
@source_name: Table name
@role_name: Database role for access control (NULL = sysadmin only)
@capture_instance: Optional custom name
@supports_net_changes: Enable net change tracking (1 = yes)
@index_name: Index for net changes (required if @supports_net_changes = 1)
*/

-- Enable CDC on Customers table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Customers',
    @role_name = NULL,
    @supports_net_changes = 1;
PRINT 'CDC enabled on Customers table';
GO

-- Enable CDC on Products table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Products',
    @role_name = NULL,
    @supports_net_changes = 1;
PRINT 'CDC enabled on Products table';
GO

-- Enable CDC on Orders table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Orders',
    @role_name = NULL,
    @supports_net_changes = 1;
PRINT 'CDC enabled on Orders table';
GO

-- Enable CDC on OrderDetails table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'OrderDetails',
    @role_name = NULL,
    @supports_net_changes = 1;
PRINT 'CDC enabled on OrderDetails table';
GO

-- View CDC-enabled tables
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    ct.capture_instance,
    ct.start_lsn,
    ct.create_date,
    ct.supports_net_changes
FROM cdc.change_tables ct
INNER JOIN sys.tables t ON ct.source_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id;

-- ============================================================================
-- PART 3: UNDERSTANDING CDC CHANGE TABLES
-- ============================================================================
/*
CDC CHANGE TABLE STRUCTURE:
- __$start_lsn: Log sequence number of change
- __$end_lsn: Currently always NULL
- __$seqval: Sequence value for ordering changes
- __$operation: 1=DELETE, 2=INSERT, 3=UPDATE (before), 4=UPDATE (after)
- __$update_mask: Bitmap showing which columns changed
- [All source columns]: Values from source table
*/

-- View CDC change table structure
EXEC sp_help 'cdc.dbo_Customers_CT';

-- View sample CDC data
SELECT TOP 10 *
FROM cdc.dbo_Customers_CT
ORDER BY __$start_lsn DESC, __$seqval DESC;

-- ============================================================================
-- PART 4: GENERATE TEST DATA FOR CDC
-- ============================================================================

-- Insert new customers
INSERT INTO Customers (FirstName, LastName, Email, Phone, JoinDate, IsActive)
VALUES
    ('Alice', 'Johnson', 'alice.johnson@email.com', '555-1001', GETDATE(), 1),
    ('Bob', 'Williams', 'bob.williams@email.com', '555-1002', GETDATE(), 1),
    ('Carol', 'Martinez', 'carol.martinez@email.com', '555-1003', GETDATE(), 1);

-- Wait for CDC capture job (or run manually)
WAITFOR DELAY '00:00:05';

-- Update existing customers
UPDATE Customers
SET Email = 'john.smith.updated@email.com',
    Phone = '555-9999'
WHERE FirstName = 'John' AND LastName = 'Smith';

WAITFOR DELAY '00:00:05';

-- Delete a customer
DELETE FROM Customers
WHERE Email = 'alice.johnson@email.com';

WAITFOR DELAY '00:00:05';

-- View captured changes
SELECT 
    __$start_lsn,
    __$operation AS OpCode,
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE (Before)'
        WHEN 4 THEN 'UPDATE (After)'
    END AS Operation,
    CustomerID,
    FirstName,
    LastName,
    Email,
    Phone
FROM cdc.dbo_Customers_CT
ORDER BY __$start_lsn DESC, __$seqval DESC;

-- ============================================================================
-- PART 5: QUERYING CDC DATA WITH FUNCTIONS
-- ============================================================================
/*
CDC QUERY FUNCTIONS:
1. cdc.fn_cdc_get_all_changes_<capture_instance>
   - Returns all changes (inserts, updates, deletes)
   
2. cdc.fn_cdc_get_net_changes_<capture_instance>
   - Returns net changes (final state per row)
   
3. sys.fn_cdc_map_time_to_lsn
   - Converts datetime to LSN
*/

-- Get current LSN
DECLARE @CurrentLSN BINARY(10) = sys.fn_cdc_get_max_lsn();
SELECT @CurrentLSN AS CurrentMaxLSN;

-- Get minimum LSN
DECLARE @MinLSN BINARY(10) = sys.fn_cdc_get_min_lsn('dbo_Customers');
SELECT @MinLSN AS MinimumLSN;

-- Get all changes between LSN range
DECLARE @FromLSN BINARY(10) = sys.fn_cdc_get_min_lsn('dbo_Customers');
DECLARE @ToLSN BINARY(10) = sys.fn_cdc_get_max_lsn();

SELECT 
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'
        WHEN 3 THEN 'UPDATE (Before)'
        WHEN 4 THEN 'UPDATE (After)'
    END AS Operation,
    *
FROM cdc.fn_cdc_get_all_changes_dbo_Customers(@FromLSN, @ToLSN, 'all');

-- Get net changes (final state only)
SELECT 
    CASE __$operation
        WHEN 1 THEN 'DELETE'
        WHEN 2 THEN 'INSERT'  
        WHEN 4 THEN 'UPDATE'
        WHEN 5 THEN 'MERGE'
    END AS NetOperation,
    *
FROM cdc.fn_cdc_get_net_changes_dbo_Customers(@FromLSN, @ToLSN, 'all');

-- Get changes by time range
DECLARE @StartTime DATETIME = DATEADD(HOUR, -1, GETDATE());
DECLARE @EndTime DATETIME = GETDATE();

DECLARE @StartLSN BINARY(10) = sys.fn_cdc_map_time_to_lsn('smallest greater than or equal', @StartTime);
DECLARE @EndLSN BINARY(10) = sys.fn_cdc_map_time_to_lsn('largest less than or equal', @EndTime);

SELECT 
    __$operation,
    sys.fn_cdc_map_lsn_to_time(__$start_lsn) AS ChangeTime,
    *
FROM cdc.fn_cdc_get_all_changes_dbo_Customers(@StartLSN, @EndLSN, 'all')
ORDER BY __$start_lsn;

-- ============================================================================
-- PART 6: CDC METADATA TRACKING IN ETL
-- ============================================================================

USE BookstoreETL;
GO

-- Create CDC tracking table
CREATE TABLE CDC_ETL_Tracking (
    TrackingID INT IDENTITY(1,1) PRIMARY KEY,
    SourceTable NVARCHAR(255),
    LastProcessedLSN BINARY(10),
    LastProcessedTime DATETIME,
    NextLoadLSN BINARY(10),
    RecordsProcessed INT,
    LoadDate DATETIME DEFAULT GETDATE()
);

-- Initialize tracking for source tables
INSERT INTO CDC_ETL_Tracking (SourceTable, LastProcessedLSN, LastProcessedTime, RecordsProcessed)
SELECT 
    'dbo_Customers',
    sys.fn_cdc_get_min_lsn('dbo_Customers'),
    GETDATE(),
    0
FROM BookstoreDB.sys.tables WHERE 1=0;  -- Initialize with no data

INSERT INTO CDC_ETL_Tracking (SourceTable, LastProcessedLSN, LastProcessedTime, RecordsProcessed)
VALUES
    ('dbo_Customers', 0x00000000000000000000, '2023-01-01', 0),
    ('dbo_Products', 0x00000000000000000000, '2023-01-01', 0),
    ('dbo_Orders', 0x00000000000000000000, '2023-01-01', 0),
    ('dbo_OrderDetails', 0x00000000000000000000, '2023-01-01', 0);

SELECT * FROM CDC_ETL_Tracking;

-- ============================================================================
-- PART 7: INCREMENTAL LOAD PROCEDURE USING CDC
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_IncrementalLoad_Customers
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LastLSN BINARY(10);
    DECLARE @CurrentLSN BINARY(10);
    DECLARE @RowsProcessed INT = 0;
    
    BEGIN TRY
        -- Get last processed LSN
        SELECT @LastLSN = LastProcessedLSN
        FROM CDC_ETL_Tracking
        WHERE SourceTable = 'dbo_Customers';
        
        -- Get current max LSN
        SELECT @CurrentLSN = sys.fn_cdc_get_max_lsn();
        
        -- Check if there are changes to process
        IF @LastLSN >= @CurrentLSN
        BEGIN
            PRINT 'No new changes to process';
            RETURN;
        END;
        
        PRINT 'Processing changes from LSN ' + CONVERT(VARCHAR(50), @LastLSN) + 
              ' to ' + CONVERT(VARCHAR(50), @CurrentLSN);
        
        -- Create temp table for changes
        CREATE TABLE #CustomerChanges (
            Operation NVARCHAR(10),
            CustomerID INT,
            FirstName NVARCHAR(100),
            LastName NVARCHAR(100),
            Email NVARCHAR(255),
            Phone NVARCHAR(20),
            JoinDate DATE,
            IsActive BIT
        );
        
        -- Get all changes
        INSERT INTO #CustomerChanges
        SELECT 
            CASE __$operation
                WHEN 1 THEN 'DELETE'
                WHEN 2 THEN 'INSERT'
                WHEN 4 THEN 'UPDATE'
            END AS Operation,
            CustomerID,
            FirstName,
            LastName,
            Email,
            Phone,
            JoinDate,
            IsActive
        FROM cdc.fn_cdc_get_net_changes_dbo_Customers(@LastLSN, @CurrentLSN, 'all');
        
        SET @RowsProcessed = @@ROWCOUNT;
        
        -- Process INSERTs
        INSERT INTO DimCustomer_SCD (CustomerID, FirstName, LastName, Email, Phone, StartDate, IsCurrent)
        SELECT CustomerID, FirstName, LastName, Email, Phone, GETDATE(), 1
        FROM #CustomerChanges
        WHERE Operation = 'INSERT';
        
        PRINT 'Processed ' + CAST(@@ROWCOUNT AS VARCHAR) + ' INSERTs';
        
        -- Process UPDATEs (SCD Type 2)
        UPDATE DimCustomer_SCD
        SET IsCurrent = 0, EndDate = GETDATE()
        WHERE CustomerID IN (SELECT CustomerID FROM #CustomerChanges WHERE Operation = 'UPDATE')
          AND IsCurrent = 1;
        
        INSERT INTO DimCustomer_SCD (CustomerID, FirstName, LastName, Email, Phone, StartDate, IsCurrent, RowVersion)
        SELECT 
            c.CustomerID, c.FirstName, c.LastName, c.Email, c.Phone, GETDATE(), 1,
            ISNULL((SELECT MAX(RowVersion) FROM DimCustomer_SCD WHERE CustomerID = c.CustomerID), 0) + 1
        FROM #CustomerChanges c
        WHERE Operation = 'UPDATE';
        
        PRINT 'Processed ' + CAST(@@ROWCOUNT AS VARCHAR) + ' UPDATEs';
        
        -- Process DELETEs (soft delete)
        UPDATE DimCustomer_SCD
        SET IsCurrent = 0, EndDate = GETDATE()
        WHERE CustomerID IN (SELECT CustomerID FROM #CustomerChanges WHERE Operation = 'DELETE')
          AND IsCurrent = 1;
        
        PRINT 'Processed ' + CAST(@@ROWCOUNT AS VARCHAR) + ' DELETEs';
        
        -- Update tracking table
        UPDATE CDC_ETL_Tracking
        SET LastProcessedLSN = @CurrentLSN,
            LastProcessedTime = GETDATE(),
            RecordsProcessed = @RowsProcessed,
            LoadDate = GETDATE()
        WHERE SourceTable = 'dbo_Customers';
        
        DROP TABLE #CustomerChanges;
        
        PRINT 'Incremental load completed successfully. Rows processed: ' + CAST(@RowsProcessed AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Execute incremental load
EXEC sp_IncrementalLoad_Customers;

-- Verify results
SELECT * FROM CDC_ETL_Tracking WHERE SourceTable = 'dbo_Customers';
SELECT TOP 20 * FROM DimCustomer_SCD ORDER BY StartDate DESC;

-- ============================================================================
-- PART 8: CDC MONITORING AND MAINTENANCE
-- ============================================================================

-- View CDC jobs
SELECT 
    j.name AS JobName,
    j.enabled,
    j.description,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Canceled'
        WHEN 5 THEN 'Unknown'
    END AS LastRunOutcome
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.name LIKE 'cdc.%'
ORDER BY j.name;

-- View CDC capture job status
USE BookstoreDB;
SELECT * FROM cdc.captured_columns ORDER BY column_ordinal;

-- Check CDC table sizes
SELECT 
    ct.capture_instance,
    OBJECT_NAME(ct.source_object_id) AS SourceTable,
    i.rows AS ChangeRowCount,
    (i.reserved * 8) / 1024 AS SizeMB
FROM cdc.change_tables ct
CROSS APPLY (
    SELECT SUM(rows) AS rows, SUM(reserved) AS reserved
    FROM sys.partitions p
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    WHERE p.object_id = OBJECT_ID('cdc.' + ct.capture_instance + '_CT')
) i;

-- Cleanup old CDC data (older than 3 days)
DECLARE @RetentionDays INT = 3;
DECLARE @RetentionHours INT = @RetentionDays * 24;

EXEC sys.sp_cdc_cleanup_change_table
    @capture_instance = 'dbo_Customers',
    @low_water_mark = NULL,
    @threshold = @RetentionHours;

PRINT 'CDC cleanup completed';

-- ============================================================================
-- PART 9: PERFORMANCE COMPARISON - FULL LOAD VS CDC
-- ============================================================================

USE BookstoreETL;
GO

CREATE TABLE Performance_CDC_Comparison (
    TestID INT IDENTITY(1,1) PRIMARY KEY,
    LoadType NVARCHAR(50),
    RowsProcessed INT,
    DurationSeconds INT,
    RowsPerSecond DECIMAL(15, 2),
    TestDate DATETIME DEFAULT GETDATE()
);

-- Simulate full load timing
INSERT INTO Performance_CDC_Comparison (LoadType, RowsProcessed, DurationSeconds, RowsPerSecond)
VALUES ('Full Load - 1M rows', 1000000, 180, 5555.56);

-- Simulate CDC incremental load timing
INSERT INTO Performance_CDC_Comparison (LoadType, RowsProcessed, DurationSeconds, RowsPerSecond)
VALUES ('CDC Incremental - 10K changes', 10000, 5, 2000.00);

SELECT 
    LoadType,
    RowsProcessed,
    DurationSeconds,
    RowsPerSecond,
    CAST((DurationSeconds * 100.0 / (SELECT MAX(DurationSeconds) FROM Performance_CDC_Comparison)) AS DECIMAL(5,2)) AS PercentOfMaxTime
FROM Performance_CDC_Comparison
ORDER BY DurationSeconds DESC;

/*
BENEFITS OF CDC:
✓ 95%+ reduction in ETL time for incremental loads
✓ Minimal impact on source system (uses transaction log)
✓ Captures all changes automatically
✓ No custom triggers or audit columns needed
✓ Native SQL Server feature

CONSIDERATIONS:
⚠ Requires Enterprise/Developer Edition
⚠ Transaction log must be retained longer
⚠ Additional storage for CDC tables
⚠ Regular cleanup required
⚠ SQL Server Agent must be running

BEST PRACTICES:
✓ Monitor CDC table sizes
✓ Set appropriate retention periods
✓ Run cleanup jobs regularly
✓ Test CDC impact on source system
✓ Use net changes for dimension tables
✓ Use all changes for audit requirements
✓ Track LSN in ETL metadata
✓ Handle re-initialization scenarios
*/

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Enabled CDC on database
□ Enabled CDC on source tables
□ Understanding CDC change tables structure
□ Queried CDC data using functions
□ Created CDC tracking metadata
□ Built incremental load procedures
□ Tested INSERT, UPDATE, DELETE operations
□ Monitored CDC jobs
□ Compared performance: Full vs Incremental
□ Implemented CDC cleanup procedures

NEXT LAB: Lab 62 - Metadata-Driven ETL Frameworks
============================================================================
*/
