/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  MODULE 07: ADVANCED ETL PATTERNS                                            ║
║  LAB 66: METADATA-DRIVEN ETL FRAMEWORK                                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Learning Objectives:                                                        ║
║  • Design metadata tables for ETL configuration                             ║
║  • Build dynamic source-to-target mappings                                  ║
║  • Create generic load procedures                                           ║
║  • Implement orchestration patterns                                         ║
║  • Build self-documenting ETL systems                                       ║
║  • Master configuration-driven data integration                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

USE DataEngineerTraining;
GO

-- ============================================================================
-- SECTION 1: METADATA-DRIVEN ETL OVERVIEW
-- ============================================================================

/*
Benefits of Metadata-Driven ETL:
┌─────────────────────────────────────────────────────────────────────────────┐
│ Benefit                     │ Description                                  │
├─────────────────────────────┼──────────────────────────────────────────────┤
│ Reduced Development Time    │ Generic code handles many scenarios          │
│ Consistency                 │ Same patterns applied across all loads       │
│ Maintainability             │ Change config, not code                      │
│ Self-Documenting            │ Metadata describes the ETL process           │
│ Auditability                │ Built-in tracking and lineage                │
│ Flexibility                 │ Easy to add new sources and targets          │
│ Testability                 │ Standardized testing approach                │
└─────────────────────────────┴──────────────────────────────────────────────┘
*/

-- Create metadata schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'meta')
    EXEC('CREATE SCHEMA meta');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
    EXEC('CREATE SCHEMA etl');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

-- ============================================================================
-- SECTION 2: CORE METADATA TABLES
-- ============================================================================

-- Source Systems Registry
DROP TABLE IF EXISTS meta.SourceSystem;
CREATE TABLE meta.SourceSystem (
    SourceSystemID      INT IDENTITY(1,1) PRIMARY KEY,
    SystemCode          NVARCHAR(20) NOT NULL UNIQUE,
    SystemName          NVARCHAR(100) NOT NULL,
    SystemType          NVARCHAR(50) NOT NULL,          -- 'SQL Server', 'Oracle', 'CSV', 'API', 'Excel'
    ConnectionString    NVARCHAR(500),
    ServerName          NVARCHAR(200),
    DatabaseName        NVARCHAR(200),
    IsActive            BIT DEFAULT 1,
    CreatedDate         DATETIME2 DEFAULT GETDATE(),
    ModifiedDate        DATETIME2 DEFAULT GETDATE(),
    Notes               NVARCHAR(MAX)
);
GO

-- Table/Entity Registry
DROP TABLE IF EXISTS meta.SourceTable;
CREATE TABLE meta.SourceTable (
    SourceTableID       INT IDENTITY(1,1) PRIMARY KEY,
    SourceSystemID      INT NOT NULL REFERENCES meta.SourceSystem(SourceSystemID),
    SchemaName          NVARCHAR(128),
    TableName           NVARCHAR(128) NOT NULL,
    FullTableName       AS (ISNULL(SchemaName + '.', '') + TableName),
    TableType           NVARCHAR(50),                   -- 'Dimension', 'Fact', 'Lookup', 'Transaction'
    LoadFrequency       NVARCHAR(50),                   -- 'Daily', 'Hourly', 'RealTime'
    LoadType            NVARCHAR(50),                   -- 'Full', 'Incremental', 'CDC'
    IncrementalColumn   NVARCHAR(128),                  -- Column used for incremental loads
    LastLoadDate        DATETIME2,
    LastLoadRowCount    INT,
    IsActive            BIT DEFAULT 1,
    LoadPriority        INT DEFAULT 100,                -- Lower = higher priority
    DependsOnTableID    INT,                            -- For load ordering
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- Target Table Registry
DROP TABLE IF EXISTS meta.TargetTable;
CREATE TABLE meta.TargetTable (
    TargetTableID       INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName          NVARCHAR(128) NOT NULL,
    TableName           NVARCHAR(128) NOT NULL,
    FullTableName       AS (SchemaName + '.' + TableName),
    TableType           NVARCHAR(50),                   -- 'Dimension', 'Fact', 'Staging', 'Archive'
    LoadStrategy        NVARCHAR(50),                   -- 'Truncate', 'Append', 'Merge', 'SCD1', 'SCD2'
    PreLoadSQL          NVARCHAR(MAX),                  -- SQL to run before load
    PostLoadSQL         NVARCHAR(MAX),                  -- SQL to run after load
    IsActive            BIT DEFAULT 1,
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- Column Mappings
DROP TABLE IF EXISTS meta.ColumnMapping;
CREATE TABLE meta.ColumnMapping (
    MappingID           INT IDENTITY(1,1) PRIMARY KEY,
    SourceTableID       INT NOT NULL REFERENCES meta.SourceTable(SourceTableID),
    TargetTableID       INT NOT NULL REFERENCES meta.TargetTable(TargetTableID),
    SourceColumnName    NVARCHAR(128) NOT NULL,
    TargetColumnName    NVARCHAR(128) NOT NULL,
    SourceDataType      NVARCHAR(50),
    TargetDataType      NVARCHAR(50),
    TransformExpression NVARCHAR(MAX),                  -- Optional transformation
    IsKeyColumn         BIT DEFAULT 0,                  -- Used for MERGE matching
    IsSCDColumn         BIT DEFAULT 0,                  -- Track for SCD changes
    DefaultValue        NVARCHAR(500),
    IsNullable          BIT DEFAULT 1,
    OrdinalPosition     INT,
    IsActive            BIT DEFAULT 1,
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- ETL Jobs Registry
DROP TABLE IF EXISTS meta.ETLJob;
CREATE TABLE meta.ETLJob (
    JobID               INT IDENTITY(1,1) PRIMARY KEY,
    JobName             NVARCHAR(100) NOT NULL UNIQUE,
    JobDescription      NVARCHAR(500),
    JobType             NVARCHAR(50),                   -- 'DataLoad', 'Transform', 'Export'
    ScheduleExpression  NVARCHAR(100),                  -- Cron expression or schedule
    MaxRetries          INT DEFAULT 3,
    RetryDelaySeconds   INT DEFAULT 60,
    TimeoutMinutes      INT DEFAULT 60,
    IsEnabled           BIT DEFAULT 1,
    LastRunDate         DATETIME2,
    LastRunStatus       NVARCHAR(50),
    NextRunDate         DATETIME2,
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- Job Steps (Tasks within a Job)
DROP TABLE IF EXISTS meta.ETLJobStep;
CREATE TABLE meta.ETLJobStep (
    StepID              INT IDENTITY(1,1) PRIMARY KEY,
    JobID               INT NOT NULL REFERENCES meta.ETLJob(JobID),
    StepName            NVARCHAR(100) NOT NULL,
    StepType            NVARCHAR(50) NOT NULL,          -- 'SQL', 'Procedure', 'SSIS', 'PowerShell'
    SourceTableID       INT REFERENCES meta.SourceTable(SourceTableID),
    TargetTableID       INT REFERENCES meta.TargetTable(TargetTableID),
    ExecutionOrder      INT NOT NULL,
    SQLCommand          NVARCHAR(MAX),
    ProcedureName       NVARCHAR(200),
    Parameters          NVARCHAR(MAX),                  -- JSON format
    ContinueOnError     BIT DEFAULT 0,
    IsEnabled           BIT DEFAULT 1,
    CreatedDate         DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================================
-- SECTION 3: POPULATE METADATA
-- ============================================================================

-- Insert Source Systems
INSERT INTO meta.SourceSystem (SystemCode, SystemName, SystemType, ServerName, DatabaseName)
VALUES 
    ('ERP', 'Enterprise Resource Planning', 'SQL Server', 'erp-server.company.com', 'ERP_Production'),
    ('CRM', 'Customer Relationship Management', 'SQL Server', 'crm-server.company.com', 'CRM_Database'),
    ('POS', 'Point of Sale', 'CSV', NULL, NULL),
    ('WEB', 'E-Commerce Platform', 'API', NULL, NULL);
GO

-- Insert Source Tables
INSERT INTO meta.SourceTable (SourceSystemID, SchemaName, TableName, TableType, LoadFrequency, LoadType, IncrementalColumn)
SELECT SourceSystemID, 'dbo', 'Customers', 'Dimension', 'Daily', 'Incremental', 'ModifiedDate'
FROM meta.SourceSystem WHERE SystemCode = 'ERP'
UNION ALL
SELECT SourceSystemID, 'dbo', 'Products', 'Dimension', 'Daily', 'Full', NULL
FROM meta.SourceSystem WHERE SystemCode = 'ERP'
UNION ALL
SELECT SourceSystemID, 'dbo', 'Orders', 'Fact', 'Hourly', 'Incremental', 'OrderDate'
FROM meta.SourceSystem WHERE SystemCode = 'ERP'
UNION ALL
SELECT SourceSystemID, 'dbo', 'OrderDetails', 'Fact', 'Hourly', 'Incremental', 'OrderDate'
FROM meta.SourceSystem WHERE SystemCode = 'ERP'
UNION ALL
SELECT SourceSystemID, 'sales', 'Contacts', 'Dimension', 'Daily', 'Incremental', 'LastModified'
FROM meta.SourceSystem WHERE SystemCode = 'CRM';
GO

-- Insert Target Tables
INSERT INTO meta.TargetTable (SchemaName, TableName, TableType, LoadStrategy)
VALUES 
    ('staging', 'stg_Customers', 'Staging', 'Truncate'),
    ('staging', 'stg_Products', 'Staging', 'Truncate'),
    ('staging', 'stg_Orders', 'Staging', 'Truncate'),
    ('dim', 'Customer', 'Dimension', 'SCD2'),
    ('dim', 'Product', 'Dimension', 'SCD1'),
    ('fact', 'Sales', 'Fact', 'Append');
GO

-- Insert Column Mappings (sample for Customers)
INSERT INTO meta.ColumnMapping (SourceTableID, TargetTableID, SourceColumnName, TargetColumnName, TransformExpression, IsKeyColumn, IsSCDColumn, OrdinalPosition)
SELECT 
    st.SourceTableID, tt.TargetTableID,
    'CustomerID', 'CustomerID', NULL, 1, 0, 1
FROM meta.SourceTable st, meta.TargetTable tt
WHERE st.TableName = 'Customers' AND tt.TableName = 'stg_Customers'
UNION ALL
SELECT 
    st.SourceTableID, tt.TargetTableID,
    'CustomerName', 'CustomerName', 'UPPER(TRIM(CustomerName))', 0, 1, 2
FROM meta.SourceTable st, meta.TargetTable tt
WHERE st.TableName = 'Customers' AND tt.TableName = 'stg_Customers'
UNION ALL
SELECT 
    st.SourceTableID, tt.TargetTableID,
    'Email', 'Email', 'LOWER(Email)', 0, 1, 3
FROM meta.SourceTable st, meta.TargetTable tt
WHERE st.TableName = 'Customers' AND tt.TableName = 'stg_Customers'
UNION ALL
SELECT 
    st.SourceTableID, tt.TargetTableID,
    'City', 'City', NULL, 0, 1, 4
FROM meta.SourceTable st, meta.TargetTable tt
WHERE st.TableName = 'Customers' AND tt.TableName = 'stg_Customers'
UNION ALL
SELECT 
    st.SourceTableID, tt.TargetTableID,
    'State', 'State', NULL, 0, 1, 5
FROM meta.SourceTable st, meta.TargetTable tt
WHERE st.TableName = 'Customers' AND tt.TableName = 'stg_Customers';
GO

-- Insert ETL Jobs
INSERT INTO meta.ETLJob (JobName, JobDescription, JobType, ScheduleExpression, IsEnabled)
VALUES 
    ('Daily_Dimension_Load', 'Load all dimension tables', 'DataLoad', '0 2 * * *', 1),
    ('Hourly_Fact_Load', 'Load fact tables', 'DataLoad', '0 * * * *', 1),
    ('Nightly_Maintenance', 'Index rebuild and statistics update', 'Maintenance', '0 4 * * *', 1);
GO

-- ============================================================================
-- SECTION 4: DYNAMIC SQL GENERATOR
-- ============================================================================

-- Generate SELECT statement from mappings
CREATE OR ALTER FUNCTION meta.fn_GenerateSelectSQL (
    @SourceTableID INT,
    @TargetTableID INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = 'SELECT ';
    DECLARE @SourceTable NVARCHAR(256);
    
    -- Get source table name
    SELECT @SourceTable = st.FullTableName
    FROM meta.SourceTable st
    WHERE st.SourceTableID = @SourceTableID;
    
    -- Build column list with transformations
    SELECT @SQL = @SQL + 
        CASE WHEN TransformExpression IS NOT NULL 
             THEN TransformExpression 
             ELSE SourceColumnName 
        END + ' AS ' + TargetColumnName + ', '
    FROM meta.ColumnMapping
    WHERE SourceTableID = @SourceTableID 
      AND TargetTableID = @TargetTableID
      AND IsActive = 1
    ORDER BY OrdinalPosition;
    
    -- Remove trailing comma
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);
    
    -- Add FROM clause
    SET @SQL = @SQL + ' FROM ' + @SourceTable;
    
    RETURN @SQL;
END;
GO

-- Generate INSERT statement
CREATE OR ALTER FUNCTION meta.fn_GenerateInsertSQL (
    @SourceTableID INT,
    @TargetTableID INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TargetTable NVARCHAR(256);
    DECLARE @ColumnList NVARCHAR(MAX) = '';
    
    -- Get target table name
    SELECT @TargetTable = tt.FullTableName
    FROM meta.TargetTable tt
    WHERE tt.TargetTableID = @TargetTableID;
    
    -- Build column list
    SELECT @ColumnList = @ColumnList + TargetColumnName + ', '
    FROM meta.ColumnMapping
    WHERE SourceTableID = @SourceTableID 
      AND TargetTableID = @TargetTableID
      AND IsActive = 1
    ORDER BY OrdinalPosition;
    
    -- Remove trailing comma
    SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 1);
    
    -- Build INSERT statement
    SET @SQL = 'INSERT INTO ' + @TargetTable + ' (' + @ColumnList + ') ' +
               meta.fn_GenerateSelectSQL(@SourceTableID, @TargetTableID);
    
    RETURN @SQL;
END;
GO

-- Generate MERGE statement
CREATE OR ALTER FUNCTION meta.fn_GenerateMergeSQL (
    @SourceTableID INT,
    @TargetTableID INT,
    @StagingTable NVARCHAR(256)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TargetTable NVARCHAR(256);
    DECLARE @KeyColumns NVARCHAR(MAX) = '';
    DECLARE @UpdateColumns NVARCHAR(MAX) = '';
    DECLARE @InsertColumns NVARCHAR(MAX) = '';
    DECLARE @InsertValues NVARCHAR(MAX) = '';
    
    -- Get target table name
    SELECT @TargetTable = tt.FullTableName
    FROM meta.TargetTable tt
    WHERE tt.TargetTableID = @TargetTableID;
    
    -- Build key column match
    SELECT @KeyColumns = @KeyColumns + 't.' + TargetColumnName + ' = s.' + TargetColumnName + ' AND '
    FROM meta.ColumnMapping
    WHERE SourceTableID = @SourceTableID 
      AND TargetTableID = @TargetTableID
      AND IsKeyColumn = 1
      AND IsActive = 1;
    
    -- Remove trailing AND
    SET @KeyColumns = LEFT(@KeyColumns, LEN(@KeyColumns) - 4);
    
    -- Build update columns (non-key columns)
    SELECT @UpdateColumns = @UpdateColumns + TargetColumnName + ' = s.' + TargetColumnName + ', '
    FROM meta.ColumnMapping
    WHERE SourceTableID = @SourceTableID 
      AND TargetTableID = @TargetTableID
      AND IsKeyColumn = 0
      AND IsActive = 1;
    
    IF LEN(@UpdateColumns) > 2
        SET @UpdateColumns = LEFT(@UpdateColumns, LEN(@UpdateColumns) - 1);
    
    -- Build insert column and value lists
    SELECT 
        @InsertColumns = @InsertColumns + TargetColumnName + ', ',
        @InsertValues = @InsertValues + 's.' + TargetColumnName + ', '
    FROM meta.ColumnMapping
    WHERE SourceTableID = @SourceTableID 
      AND TargetTableID = @TargetTableID
      AND IsActive = 1
    ORDER BY OrdinalPosition;
    
    SET @InsertColumns = LEFT(@InsertColumns, LEN(@InsertColumns) - 1);
    SET @InsertValues = LEFT(@InsertValues, LEN(@InsertValues) - 1);
    
    -- Build MERGE statement
    SET @SQL = 'MERGE ' + @TargetTable + ' AS t ' +
               'USING ' + @StagingTable + ' AS s ON ' + @KeyColumns + ' ' +
               'WHEN MATCHED THEN UPDATE SET ' + @UpdateColumns + ' ' +
               'WHEN NOT MATCHED THEN INSERT (' + @InsertColumns + ') VALUES (' + @InsertValues + ');';
    
    RETURN @SQL;
END;
GO

-- ============================================================================
-- SECTION 5: GENERIC LOAD PROCEDURES
-- ============================================================================

-- Generic Staging Load Procedure
CREATE OR ALTER PROCEDURE etl.usp_LoadStaging
    @SourceTableID INT,
    @TargetTableID INT,
    @IncrementalDate DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @LoadType NVARCHAR(50);
    DECLARE @IncrementalColumn NVARCHAR(128);
    DECLARE @TargetTable NVARCHAR(256);
    DECLARE @LoadStrategy NVARCHAR(50);
    DECLARE @PreLoadSQL NVARCHAR(MAX);
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowCount INT;
    
    -- Get metadata
    SELECT @LoadType = st.LoadType, 
           @IncrementalColumn = st.IncrementalColumn
    FROM meta.SourceTable st
    WHERE st.SourceTableID = @SourceTableID;
    
    SELECT @TargetTable = tt.FullTableName,
           @LoadStrategy = tt.LoadStrategy,
           @PreLoadSQL = tt.PreLoadSQL
    FROM meta.TargetTable tt
    WHERE tt.TargetTableID = @TargetTableID;
    
    PRINT 'Starting load for: ' + @TargetTable;
    PRINT 'Load Type: ' + @LoadType;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Execute Pre-Load SQL
        IF @PreLoadSQL IS NOT NULL
        BEGIN
            EXEC sp_executesql @PreLoadSQL;
            PRINT 'Pre-load SQL executed';
        END
        
        -- Truncate if needed
        IF @LoadStrategy = 'Truncate'
        BEGIN
            SET @SQL = 'TRUNCATE TABLE ' + @TargetTable;
            EXEC sp_executesql @SQL;
            PRINT 'Table truncated';
        END
        
        -- Generate and execute INSERT
        SET @SQL = meta.fn_GenerateInsertSQL(@SourceTableID, @TargetTableID);
        
        -- Add WHERE clause for incremental loads
        IF @LoadType = 'Incremental' AND @IncrementalColumn IS NOT NULL AND @IncrementalDate IS NOT NULL
        BEGIN
            SET @SQL = @SQL + ' WHERE ' + @IncrementalColumn + ' > @IncrementalDate';
            EXEC sp_executesql @SQL, N'@IncrementalDate DATETIME2', @IncrementalDate;
        END
        ELSE
        BEGIN
            -- For demo, we'll use a simulated query since source tables may not exist
            PRINT 'Generated SQL: ' + @SQL;
            -- In production: EXEC sp_executesql @SQL;
        END
        
        SET @RowCount = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Update metadata
        UPDATE meta.SourceTable
        SET LastLoadDate = @StartTime,
            LastLoadRowCount = @RowCount
        WHERE SourceTableID = @SourceTableID;
        
        PRINT 'Load complete. Rows: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(20)) + ' seconds';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Generic Dimension Load (SCD)
CREATE OR ALTER PROCEDURE etl.usp_LoadDimension
    @SourceTableID INT,
    @TargetTableID INT,
    @SCDType INT = 2  -- 1 or 2
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @StagingTable NVARCHAR(256);
    DECLARE @TargetTable NVARCHAR(256);
    DECLARE @KeyColumns NVARCHAR(MAX) = '';
    DECLARE @SCDColumns NVARCHAR(MAX) = '';
    DECLARE @AllColumns NVARCHAR(MAX) = '';
    
    -- Get table names
    SELECT @TargetTable = tt.FullTableName
    FROM meta.TargetTable tt
    WHERE tt.TargetTableID = @TargetTableID;
    
    -- Get staging table (convention: staging table ID is same source with staging target)
    SET @StagingTable = REPLACE(@TargetTable, 'dim.', 'staging.stg_');
    
    -- Get key columns for matching
    SELECT @KeyColumns = STRING_AGG('t.' + TargetColumnName + ' = s.' + TargetColumnName, ' AND ')
    FROM meta.ColumnMapping
    WHERE SourceTableID = @SourceTableID 
      AND TargetTableID = @TargetTableID
      AND IsKeyColumn = 1
      AND IsActive = 1;
    
    -- Get SCD columns for change detection
    SELECT @SCDColumns = STRING_AGG('ISNULL(t.' + TargetColumnName + ', '''') != ISNULL(s.' + TargetColumnName + ', '''')', ' OR ')
    FROM meta.ColumnMapping
    WHERE SourceTableID = @SourceTableID 
      AND TargetTableID = @TargetTableID
      AND IsSCDColumn = 1
      AND IsActive = 1;
    
    IF @SCDType = 1
    BEGIN
        -- SCD Type 1: Simple UPDATE
        SET @SQL = 'UPDATE t SET ' +
            (SELECT STRING_AGG('t.' + TargetColumnName + ' = s.' + TargetColumnName, ', ')
             FROM meta.ColumnMapping
             WHERE SourceTableID = @SourceTableID 
               AND TargetTableID = @TargetTableID
               AND IsSCDColumn = 1
               AND IsActive = 1) +
            ' FROM ' + @TargetTable + ' t ' +
            ' INNER JOIN ' + @StagingTable + ' s ON ' + @KeyColumns +
            ' WHERE ' + @SCDColumns;
            
        PRINT 'SCD Type 1 UPDATE SQL:';
        PRINT @SQL;
    END
    ELSE IF @SCDType = 2
    BEGIN
        -- SCD Type 2: Expire and Insert
        SET @SQL = '
        -- Expire changed records
        UPDATE t
        SET EffectiveEndDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
            IsCurrent = 0
        FROM ' + @TargetTable + ' t
        INNER JOIN ' + @StagingTable + ' s ON ' + @KeyColumns + '
        WHERE t.IsCurrent = 1
          AND (' + @SCDColumns + ');
          
        -- Insert new versions
        INSERT INTO ' + @TargetTable + ' (...)
        SELECT ..., CAST(GETDATE() AS DATE), ''9999-12-31'', 1
        FROM ' + @StagingTable + ' s
        WHERE NOT EXISTS (...)
           OR EXISTS (...); -- changed records
        ';
        
        PRINT 'SCD Type 2 SQL (template):';
        PRINT @SQL;
    END
    
    -- In production: EXEC sp_executesql @SQL;
END;
GO

-- ============================================================================
-- SECTION 6: JOB ORCHESTRATION ENGINE
-- ============================================================================

-- Job Execution Log
DROP TABLE IF EXISTS etl.JobExecutionLog;
CREATE TABLE etl.JobExecutionLog (
    ExecutionID         INT IDENTITY(1,1) PRIMARY KEY,
    JobID               INT NOT NULL REFERENCES meta.ETLJob(JobID),
    StepID              INT REFERENCES meta.ETLJobStep(StepID),
    ExecutionStatus     NVARCHAR(50) NOT NULL,
    StartTime           DATETIME2 NOT NULL DEFAULT GETDATE(),
    EndTime             DATETIME2,
    RowsAffected        INT,
    ErrorMessage        NVARCHAR(MAX),
    RetryCount          INT DEFAULT 0
);
GO

-- Execute ETL Job
CREATE OR ALTER PROCEDURE etl.usp_ExecuteJob
    @JobID      INT,
    @ExecutionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @JobName NVARCHAR(100);
    DECLARE @MaxRetries INT;
    DECLARE @StepID INT;
    DECLARE @StepName NVARCHAR(100);
    DECLARE @StepType NVARCHAR(50);
    DECLARE @SQLCommand NVARCHAR(MAX);
    DECLARE @ProcedureName NVARCHAR(200);
    DECLARE @ContinueOnError BIT;
    DECLARE @StepStatus NVARCHAR(50);
    DECLARE @StepStartTime DATETIME2;
    
    -- Get job info
    SELECT @JobName = JobName, @MaxRetries = MaxRetries
    FROM meta.ETLJob
    WHERE JobID = @JobID;
    
    -- Log job start
    INSERT INTO etl.JobExecutionLog (JobID, ExecutionStatus)
    VALUES (@JobID, 'Running');
    SET @ExecutionID = SCOPE_IDENTITY();
    
    PRINT '═══════════════════════════════════════════════════════════════════════════';
    PRINT 'Starting Job: ' + @JobName;
    PRINT 'Execution ID: ' + CAST(@ExecutionID AS VARCHAR(20));
    PRINT '═══════════════════════════════════════════════════════════════════════════';
    
    -- Execute each step in order
    DECLARE step_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT StepID, StepName, StepType, SQLCommand, ProcedureName, ContinueOnError
        FROM meta.ETLJobStep
        WHERE JobID = @JobID AND IsEnabled = 1
        ORDER BY ExecutionOrder;
    
    OPEN step_cursor;
    FETCH NEXT FROM step_cursor INTO @StepID, @StepName, @StepType, @SQLCommand, @ProcedureName, @ContinueOnError;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @StepStartTime = GETDATE();
        SET @StepStatus = 'Running';
        
        PRINT '';
        PRINT '--- Step: ' + @StepName + ' ---';
        
        -- Log step start
        INSERT INTO etl.JobExecutionLog (JobID, StepID, ExecutionStatus, StartTime)
        VALUES (@JobID, @StepID, 'Running', @StepStartTime);
        DECLARE @StepExecutionID INT = SCOPE_IDENTITY();
        
        BEGIN TRY
            IF @StepType = 'SQL' AND @SQLCommand IS NOT NULL
            BEGIN
                EXEC sp_executesql @SQLCommand;
                SET @StepStatus = 'Success';
                PRINT 'SQL executed successfully';
            END
            ELSE IF @StepType = 'Procedure' AND @ProcedureName IS NOT NULL
            BEGIN
                EXEC sp_executesql @ProcedureName;
                SET @StepStatus = 'Success';
                PRINT 'Procedure executed successfully';
            END
            
            -- Update step log
            UPDATE etl.JobExecutionLog
            SET ExecutionStatus = 'Success',
                EndTime = GETDATE(),
                RowsAffected = @@ROWCOUNT
            WHERE ExecutionID = @StepExecutionID;
            
        END TRY
        BEGIN CATCH
            SET @StepStatus = 'Failed';
            
            -- Update step log
            UPDATE etl.JobExecutionLog
            SET ExecutionStatus = 'Failed',
                EndTime = GETDATE(),
                ErrorMessage = ERROR_MESSAGE()
            WHERE ExecutionID = @StepExecutionID;
            
            PRINT 'Step FAILED: ' + ERROR_MESSAGE();
            
            IF @ContinueOnError = 0
            BEGIN
                -- Stop job execution
                UPDATE etl.JobExecutionLog
                SET ExecutionStatus = 'Failed',
                    EndTime = GETDATE(),
                    ErrorMessage = 'Stopped at step: ' + @StepName
                WHERE ExecutionID = @ExecutionID AND StepID IS NULL;
                
                CLOSE step_cursor;
                DEALLOCATE step_cursor;
                RETURN;
            END
        END CATCH
        
        FETCH NEXT FROM step_cursor INTO @StepID, @StepName, @StepType, @SQLCommand, @ProcedureName, @ContinueOnError;
    END
    
    CLOSE step_cursor;
    DEALLOCATE step_cursor;
    
    -- Complete job
    UPDATE etl.JobExecutionLog
    SET ExecutionStatus = 'Success',
        EndTime = GETDATE()
    WHERE ExecutionID = @ExecutionID AND StepID IS NULL;
    
    -- Update job metadata
    UPDATE meta.ETLJob
    SET LastRunDate = GETDATE(),
        LastRunStatus = 'Success'
    WHERE JobID = @JobID;
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════════════════';
    PRINT 'Job Complete: ' + @JobName;
    PRINT '═══════════════════════════════════════════════════════════════════════════';
END;
GO

-- ============================================================================
-- SECTION 7: DOCUMENTATION AND LINEAGE
-- ============================================================================

-- Data Lineage View
CREATE OR ALTER VIEW meta.vw_DataLineage
AS
SELECT 
    ss.SystemName AS SourceSystem,
    st.SchemaName + '.' + st.TableName AS SourceTable,
    cm.SourceColumnName,
    cm.TransformExpression,
    cm.TargetColumnName,
    tt.SchemaName + '.' + tt.TableName AS TargetTable,
    st.LoadType,
    tt.LoadStrategy,
    cm.IsKeyColumn,
    cm.IsSCDColumn
FROM meta.ColumnMapping cm
INNER JOIN meta.SourceTable st ON cm.SourceTableID = st.SourceTableID
INNER JOIN meta.SourceSystem ss ON st.SourceSystemID = ss.SourceSystemID
INNER JOIN meta.TargetTable tt ON cm.TargetTableID = tt.TargetTableID
WHERE cm.IsActive = 1;
GO

-- ETL Documentation View
CREATE OR ALTER VIEW meta.vw_ETLDocumentation
AS
SELECT 
    j.JobName,
    j.JobDescription,
    j.ScheduleExpression,
    js.ExecutionOrder,
    js.StepName,
    js.StepType,
    st.TableName AS SourceTable,
    tt.TableName AS TargetTable,
    COALESCE(js.SQLCommand, js.ProcedureName) AS ExecutionCommand,
    js.ContinueOnError
FROM meta.ETLJob j
INNER JOIN meta.ETLJobStep js ON j.JobID = js.JobID
LEFT JOIN meta.SourceTable st ON js.SourceTableID = st.SourceTableID
LEFT JOIN meta.TargetTable tt ON js.TargetTableID = tt.TargetTableID
WHERE j.IsEnabled = 1 AND js.IsEnabled = 1;
GO

-- Generate documentation report
CREATE OR ALTER PROCEDURE meta.usp_GenerateDocumentation
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '╔══════════════════════════════════════════════════════════════════════════════╗';
    PRINT '║                    ETL FRAMEWORK DOCUMENTATION                               ║';
    PRINT '╚══════════════════════════════════════════════════════════════════════════════╝';
    PRINT '';
    
    -- Source Systems
    PRINT '== SOURCE SYSTEMS ==';
    SELECT SystemCode, SystemName, SystemType, ServerName, DatabaseName,
           CASE WHEN IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS Status
    FROM meta.SourceSystem;
    
    -- Source Tables
    PRINT '';
    PRINT '== SOURCE TABLES ==';
    SELECT ss.SystemCode, st.SchemaName + '.' + st.TableName AS TableName,
           st.TableType, st.LoadFrequency, st.LoadType, st.IncrementalColumn
    FROM meta.SourceTable st
    INNER JOIN meta.SourceSystem ss ON st.SourceSystemID = ss.SourceSystemID
    WHERE st.IsActive = 1
    ORDER BY ss.SystemCode, st.TableName;
    
    -- Target Tables
    PRINT '';
    PRINT '== TARGET TABLES ==';
    SELECT SchemaName + '.' + TableName AS TableName, TableType, LoadStrategy
    FROM meta.TargetTable
    WHERE IsActive = 1
    ORDER BY SchemaName, TableName;
    
    -- ETL Jobs
    PRINT '';
    PRINT '== ETL JOBS ==';
    SELECT JobName, JobDescription, ScheduleExpression,
           CASE WHEN IsEnabled = 1 THEN 'Enabled' ELSE 'Disabled' END AS Status,
           LastRunDate, LastRunStatus
    FROM meta.ETLJob
    ORDER BY JobName;
    
    -- Data Lineage Summary
    PRINT '';
    PRINT '== DATA LINEAGE SUMMARY ==';
    SELECT * FROM meta.vw_DataLineage;
END;
GO

-- Execute documentation
EXEC meta.usp_GenerateDocumentation;
GO

-- ============================================================================
-- SECTION 8: EXERCISES
-- ============================================================================

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 1: ADD NEW SOURCE TABLE                                            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Add a new source table "Inventory" from the ERP system:                     ║
║  - Table: dbo.Inventory                                                      ║
║  - Type: Fact                                                                ║
║  - Load: Incremental on LastUpdated column                                  ║
║  - Columns: InventoryID, ProductID, WarehouseID, Quantity, LastUpdated      ║
║                                                                              ║
║  Create corresponding:                                                       ║
║  1. SourceTable entry                                                        ║
║  2. TargetTable entry (staging.stg_Inventory)                               ║
║  3. ColumnMapping entries                                                    ║
║  4. Test the generated SQL                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 2: CREATE VALIDATION FRAMEWORK                                     ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create metadata tables and procedures for data validation:                  ║
║  - ValidationRule table (RuleID, TableID, RuleType, RuleExpression)         ║
║  - Procedure to execute validations                                          ║
║  - Log failed validations                                                    ║
║                                                                              ║
║  Rule types: NotNull, UniqueKey, ReferentialIntegrity, BusinessRule         ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EXERCISE 3: BUILD DEPENDENCY GRAPH                                          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Create a view that shows the dependency order for loading tables:           ║
║  - Which tables must be loaded first                                         ║
║  - Which tables depend on others                                            ║
║  - Calculate load order based on dependencies                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- Your solution here:


-- ============================================================================
-- CLEANUP (Optional)
-- ============================================================================
/*
DROP TABLE IF EXISTS etl.JobExecutionLog;
DROP TABLE IF EXISTS meta.ETLJobStep;
DROP TABLE IF EXISTS meta.ETLJob;
DROP TABLE IF EXISTS meta.ColumnMapping;
DROP TABLE IF EXISTS meta.TargetTable;
DROP TABLE IF EXISTS meta.SourceTable;
DROP TABLE IF EXISTS meta.SourceSystem;

DROP VIEW IF EXISTS meta.vw_DataLineage;
DROP VIEW IF EXISTS meta.vw_ETLDocumentation;

DROP FUNCTION IF EXISTS meta.fn_GenerateSelectSQL;
DROP FUNCTION IF EXISTS meta.fn_GenerateInsertSQL;
DROP FUNCTION IF EXISTS meta.fn_GenerateMergeSQL;

DROP PROCEDURE IF EXISTS etl.usp_LoadStaging;
DROP PROCEDURE IF EXISTS etl.usp_LoadDimension;
DROP PROCEDURE IF EXISTS etl.usp_ExecuteJob;
DROP PROCEDURE IF EXISTS meta.usp_GenerateDocumentation;

DROP SCHEMA IF EXISTS meta;
DROP SCHEMA IF EXISTS etl;
DROP SCHEMA IF EXISTS staging;
*/

PRINT '═══════════════════════════════════════════════════════════════════════════';
PRINT '  Lab 66: Metadata-Driven ETL Framework - Complete';
PRINT '═══════════════════════════════════════════════════════════════════════════';
GO
