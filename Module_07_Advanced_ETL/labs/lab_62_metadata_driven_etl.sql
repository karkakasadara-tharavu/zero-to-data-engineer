/*
============================================================================
LAB 62: METADATA-DRIVEN ETL FRAMEWORK
Module 07: Advanced ETL Patterns
============================================================================

OBJECTIVE:
- Build configurable, metadata-driven ETL architecture
- Eliminate hard-coded SSIS packages
- Enable dynamic source-to-target mappings
- Implement table-driven ETL orchestration
- Scale ETL processes with minimal code changes

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐⭐⭐ (Expert)

CONCEPT: Instead of creating separate SSIS packages for each table,
build ONE generic package that reads metadata tables to determine:
- What to extract
- How to transform
- Where to load

DATABASE: BookstoreETL
============================================================================
*/

USE BookstoreETL;
GO

-- ============================================================================
-- PART 1: METADATA FRAMEWORK ARCHITECTURE
-- ============================================================================
/*
METADATA-DRIVEN ETL LAYERS:

1. SOURCE SYSTEMS: Configuration for all data sources
2. TARGET SYSTEMS: Configuration for destinations
3. TABLE MAPPINGS: Source-to-target table relationships
4. COLUMN MAPPINGS: Field-level transformations
5. ORCHESTRATION: Load sequences and dependencies
6. EXECUTION LOG: Runtime tracking and monitoring
*/

-- Drop existing metadata tables
DROP TABLE IF EXISTS ETL_ColumnMapping;
DROP TABLE IF EXISTS ETL_TableMapping;
DROP TABLE IF EXISTS ETL_TargetSystems;
DROP TABLE IF EXISTS ETL_SourceSystems;
DROP TABLE IF EXISTS ETL_PackageOrchestration;
DROP TABLE IF EXISTS ETL_ExecutionLog;
GO

-- ============================================================================
-- PART 2: SOURCE SYSTEMS METADATA
-- ============================================================================

CREATE TABLE ETL_SourceSystems (
    SourceSystemID INT IDENTITY(1,1) PRIMARY KEY,
    SourceSystemName NVARCHAR(100) NOT NULL UNIQUE,
    SourceType NVARCHAR(50) NOT NULL,  -- SQL, Oracle, MySQL, FlatFile, REST_API
    ConnectionString NVARCHAR(500),
    ServerName NVARCHAR(255),
    DatabaseName NVARCHAR(255),
    Username NVARCHAR(100),
    PasswordEncrypted VARBINARY(MAX),
    FilePath NVARCHAR(500),
    APIEndpoint NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

INSERT INTO ETL_SourceSystems (SourceSystemName, SourceType, ServerName, DatabaseName, IsActive)
VALUES
    ('BookstoreDB_OLTP', 'SQL', 'localhost', 'BookstoreDB', 1),
    ('SalesFiles_Daily', 'FlatFile', NULL, NULL, 1),
    ('CustomerAPI', 'REST_API', NULL, NULL, 1);

-- ============================================================================
-- PART 3: TARGET SYSTEMS METADATA
-- ============================================================================

CREATE TABLE ETL_TargetSystems (
    TargetSystemID INT IDENTITY(1,1) PRIMARY KEY,
    TargetSystemName NVARCHAR(100) NOT NULL UNIQUE,
    TargetType NVARCHAR(50) NOT NULL,
    ConnectionString NVARCHAR(500),
    ServerName NVARCHAR(255),
    DatabaseName NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

INSERT INTO ETL_TargetSystems (TargetSystemName, TargetType, ServerName, DatabaseName, IsActive)
VALUES
    ('BookstoreETL_DW', 'SQL', 'localhost', 'BookstoreETL', 1);

-- ============================================================================
-- PART 4: TABLE MAPPING METADATA
-- ============================================================================

CREATE TABLE ETL_TableMapping (
    TableMappingID INT IDENTITY(1,1) PRIMARY KEY,
    SourceSystemID INT NOT NULL,
    TargetSystemID INT NOT NULL,
    SourceSchema NVARCHAR(50) DEFAULT 'dbo',
    SourceTable NVARCHAR(255) NOT NULL,
    TargetSchema NVARCHAR(50) DEFAULT 'dbo',
    TargetTable NVARCHAR(255) NOT NULL,
    LoadType NVARCHAR(20) NOT NULL,  -- FULL, INCREMENTAL, CDC, SCD2
    ExtractQuery NVARCHAR(MAX),  -- NULL = SELECT * FROM SourceTable
    WhereClause NVARCHAR(MAX),  -- For incremental: WHERE LastModified > ?
    IncrementalColumn NVARCHAR(100),  -- Column for incremental detection
    PrimaryKeyColumns NVARCHAR(255),  -- Comma-separated
    TruncateBeforeLoad BIT DEFAULT 0,
    LoadOrder INT DEFAULT 100,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_TableMapping_Source FOREIGN KEY (SourceSystemID) REFERENCES ETL_SourceSystems(SourceSystemID),
    CONSTRAINT FK_TableMapping_Target FOREIGN KEY (TargetSystemID) REFERENCES ETL_TargetSystems(TargetSystemID)
);

-- Configure table mappings
INSERT INTO ETL_TableMapping (
    SourceSystemID, TargetSystemID, SourceSchema, SourceTable, 
    TargetSchema, TargetTable, LoadType, IncrementalColumn, 
    PrimaryKeyColumns, TruncateBeforeLoad, LoadOrder, IsActive
)
VALUES
    -- Dimension loads (order 1)
    (1, 1, 'dbo', 'Customers', 'dbo', 'DimCustomer_SCD', 'SCD2', 'ModifiedDate', 'CustomerID', 0, 1, 1),
    (1, 1, 'dbo', 'Products', 'dbo', 'DimProduct_Full', 'SCD2', 'ModifiedDate', 'ProductID', 0, 1, 1),
    (1, 1, 'dbo', 'Categories', 'dbo', 'DimCategory', 'FULL', NULL, 'CategoryID', 1, 1, 1),
    
    -- Fact loads (order 2 - after dimensions)
    (1, 1, 'dbo', 'Orders', 'dbo', 'FactSales', 'INCREMENTAL', 'OrderDate', 'OrderID', 0, 2, 1),
    (1, 1, 'dbo', 'OrderDetails', 'dbo', 'FactSales', 'INCREMENTAL', 'OrderDate', 'OrderDetailID', 0, 2, 1);

SELECT * FROM ETL_TableMapping ORDER BY LoadOrder, TableMappingID;

-- ============================================================================
-- PART 5: COLUMN MAPPING METADATA
-- ============================================================================

CREATE TABLE ETL_ColumnMapping (
    ColumnMappingID INT IDENTITY(1,1) PRIMARY KEY,
    TableMappingID INT NOT NULL,
    SourceColumn NVARCHAR(255) NOT NULL,
    TargetColumn NVARCHAR(255) NOT NULL,
    DataType NVARCHAR(50),
    Transformation NVARCHAR(MAX),  -- SQL expression or function
    IsNullable BIT DEFAULT 1,
    DefaultValue NVARCHAR(255),
    IsPrimaryKey BIT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_ColumnMapping_Table FOREIGN KEY (TableMappingID) REFERENCES ETL_TableMapping(TableMappingID)
);

-- Customer dimension column mappings
DECLARE @CustomerMappingID INT = (SELECT TableMappingID FROM ETL_TableMapping WHERE SourceTable = 'Customers' AND TargetTable = 'DimCustomer_SCD');

INSERT INTO ETL_ColumnMapping (TableMappingID, SourceColumn, TargetColumn, DataType, Transformation, IsPrimaryKey)
VALUES
    (@CustomerMappingID, 'CustomerID', 'CustomerID', 'INT', NULL, 1),
    (@CustomerMappingID, 'FirstName', 'FirstName', 'NVARCHAR(100)', 'UPPER(FirstName)', 0),
    (@CustomerMappingID, 'LastName', 'LastName', 'NVARCHAR(100)', 'UPPER(LastName)', 0),
    (@CustomerMappingID, 'Email', 'Email', 'NVARCHAR(255)', 'LOWER(Email)', 0),
    (@CustomerMappingID, 'Phone', 'Phone', 'NVARCHAR(20)', 'REPLACE(Phone, ''-'', '''')', 0),
    (@CustomerMappingID, 'JoinDate', 'StartDate', 'DATE', NULL, 0);

-- Product dimension column mappings
DECLARE @ProductMappingID INT = (SELECT TableMappingID FROM ETL_TableMapping WHERE SourceTable = 'Products' AND TargetTable = 'DimProduct_Full');

INSERT INTO ETL_ColumnMapping (TableMappingID, SourceColumn, TargetColumn, DataType, Transformation, IsPrimaryKey)
VALUES
    (@ProductMappingID, 'ProductID', 'ProductID', 'INT', NULL, 1),
    (@ProductMappingID, 'Title', 'Title', 'NVARCHAR(255)', NULL, 0),
    (@ProductMappingID, 'ISBN', 'ISBN', 'NVARCHAR(50)', NULL, 0),
    (@ProductMappingID, 'Price', 'Price', 'DECIMAL(10,2)', NULL, 0);

SELECT * FROM ETL_ColumnMapping;

-- ============================================================================
-- PART 6: ORCHESTRATION METADATA
-- ============================================================================

CREATE TABLE ETL_PackageOrchestration (
    OrchestrationID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255) NOT NULL,
    PackageDescription NVARCHAR(MAX),
    ExecutionOrder INT NOT NULL,
    ParentPackageName NVARCHAR(255),
    DependsOnPackage NVARCHAR(255),
    IsParallel BIT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

INSERT INTO ETL_PackageOrchestration (PackageName, PackageDescription, ExecutionOrder, ParentPackageName, IsParallel, IsActive)
VALUES
    ('MASTER_ETL_Controller', 'Master orchestration package', 1, NULL, 0, 1),
    ('DIM_Customer_Load', 'Load customer dimension', 2, 'MASTER_ETL_Controller', 1, 1),
    ('DIM_Product_Load', 'Load product dimension', 2, 'MASTER_ETL_Controller', 1, 1),
    ('FACT_Sales_Load', 'Load sales fact', 3, 'MASTER_ETL_Controller', 0, 1),
    ('AGG_Daily_Summary', 'Aggregate daily summaries', 4, 'MASTER_ETL_Controller', 0, 1);

-- ============================================================================
-- PART 7: EXECUTION LOGGING
-- ============================================================================

CREATE TABLE ETL_ExecutionLog (
    ExecutionLogID INT IDENTITY(1,1) PRIMARY KEY,
    TableMappingID INT,
    ExecutionGUID UNIQUEIDENTIFIER DEFAULT NEWID(),
    StartTime DATETIME,
    EndTime DATETIME,
    DurationSeconds INT,
    RowsExtracted INT,
    RowsLoaded INT,
    RowsRejected INT,
    Status NVARCHAR(20),
    ErrorMessage NVARCHAR(MAX),
    LogDate DATETIME DEFAULT GETDATE()
);

-- ============================================================================
-- PART 8: DYNAMIC SQL GENERATION PROCEDURES
-- ============================================================================

-- Procedure: Generate dynamic SELECT statement
CREATE OR ALTER PROCEDURE sp_GenerateExtractSQL
    @TableMappingID INT,
    @SQL NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @SourceSchema NVARCHAR(50);
    DECLARE @SourceTable NVARCHAR(255);
    DECLARE @ExtractQuery NVARCHAR(MAX);
    DECLARE @WhereClause NVARCHAR(MAX);
    DECLARE @ColumnList NVARCHAR(MAX) = '';
    
    -- Get table mapping info
    SELECT 
        @SourceSchema = SourceSchema,
        @SourceTable = SourceTable,
        @ExtractQuery = ExtractQuery,
        @WhereClause = WhereClause
    FROM ETL_TableMapping
    WHERE TableMappingID = @TableMappingID;
    
    -- If custom query provided, use it
    IF @ExtractQuery IS NOT NULL
    BEGIN
        SET @SQL = @ExtractQuery;
        RETURN;
    END;
    
    -- Build column list with transformations
    SELECT @ColumnList = @ColumnList + 
        CASE 
            WHEN Transformation IS NOT NULL THEN Transformation + ' AS [' + TargetColumn + ']'
            ELSE '[' + SourceColumn + '] AS [' + TargetColumn + ']'
        END + ',' + CHAR(13)
    FROM ETL_ColumnMapping
    WHERE TableMappingID = @TableMappingID
      AND IsActive = 1
    ORDER BY ColumnMappingID;
    
    -- Remove trailing comma
    SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 2);
    
    -- Build complete SELECT statement
    SET @SQL = 'SELECT ' + CHAR(13) + @ColumnList + CHAR(13) +
               'FROM ' + @SourceSchema + '.' + @SourceTable;
    
    -- Add WHERE clause if specified
    IF @WhereClause IS NOT NULL
        SET @SQL = @SQL + CHAR(13) + 'WHERE ' + @WhereClause;
    
END;
GO

-- Test dynamic SQL generation
DECLARE @SQL NVARCHAR(MAX);
DECLARE @CustomerMappingID INT = (SELECT TableMappingID FROM ETL_TableMapping WHERE SourceTable = 'Customers');

EXEC sp_GenerateExtractSQL @CustomerMappingID, @SQL OUTPUT;
PRINT @SQL;

-- ============================================================================
-- PART 9: METADATA-DRIVEN LOAD PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_ExecuteMetadataDrivenLoad
    @TableMappingID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExecutionGUID UNIQUEIDENTIFIER = NEWID();
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @SourceSystem NVARCHAR(100);
    DECLARE @SourceTable NVARCHAR(255);
    DECLARE @TargetTable NVARCHAR(255);
    DECLARE @LoadType NVARCHAR(20);
    DECLARE @TruncateFlag BIT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ExtractSQL NVARCHAR(MAX);
    DECLARE @RowsExtracted INT = 0;
    DECLARE @RowsLoaded INT = 0;
    DECLARE @Status NVARCHAR(20) = 'SUCCESS';
    DECLARE @ErrorMsg NVARCHAR(MAX);
    
    BEGIN TRY
        -- Get mapping configuration
        SELECT 
            @SourceSystem = ss.SourceSystemName,
            @SourceTable = tm.SourceTable,
            @TargetTable = tm.TargetTable,
            @LoadType = tm.LoadType,
            @TruncateFlag = tm.TruncateBeforeLoad
        FROM ETL_TableMapping tm
        INNER JOIN ETL_SourceSystems ss ON tm.SourceSystemID = ss.SourceSystemID
        WHERE tm.TableMappingID = @TableMappingID;
        
        PRINT 'Starting load: ' + @SourceTable + ' -> ' + @TargetTable;
        PRINT 'Load Type: ' + @LoadType;
        
        -- Generate extract SQL
        EXEC sp_GenerateExtractSQL @TableMappingID, @ExtractSQL OUTPUT;
        PRINT 'Extract SQL: ' + @ExtractSQL;
        
        -- Truncate target if configured
        IF @TruncateFlag = 1
        BEGIN
            SET @SQL = 'TRUNCATE TABLE ' + @TargetTable;
            EXEC sp_executesql @SQL;
            PRINT 'Target table truncated';
        END;
        
        -- Execute load based on type
        IF @LoadType = 'FULL'
        BEGIN
            -- Simple INSERT INTO SELECT
            SET @SQL = 'INSERT INTO ' + @TargetTable + ' ' + @ExtractSQL;
            EXEC sp_executesql @SQL;
            SET @RowsLoaded = @@ROWCOUNT;
        END
        ELSE IF @LoadType = 'INCREMENTAL'
        BEGIN
            -- Insert only new/changed records
            PRINT 'Incremental load logic (simplified)';
            SET @SQL = 'INSERT INTO ' + @TargetTable + ' ' + @ExtractSQL;
            EXEC sp_executesql @SQL;
            SET @RowsLoaded = @@ROWCOUNT;
        END
        ELSE IF @LoadType = 'SCD2'
        BEGIN
            PRINT 'SCD Type 2 logic (placeholder - use CDC or MERGE)';
            -- Implement SCD Type 2 logic here
            SET @RowsLoaded = 0;
        END;
        
        PRINT 'Rows loaded: ' + CAST(@RowsLoaded AS VARCHAR);
        
        -- Log execution
        INSERT INTO ETL_ExecutionLog (
            TableMappingID, ExecutionGUID, StartTime, EndTime,
            DurationSeconds, RowsExtracted, RowsLoaded, Status
        )
        VALUES (
            @TableMappingID, @ExecutionGUID, @StartTime, GETDATE(),
            DATEDIFF(SECOND, @StartTime, GETDATE()),
            @RowsExtracted, @RowsLoaded, @Status
        );
        
        PRINT 'Load completed successfully';
        
    END TRY
    BEGIN CATCH
        SET @Status = 'FAILED';
        SET @ErrorMsg = ERROR_MESSAGE();
        
        INSERT INTO ETL_ExecutionLog (
            TableMappingID, ExecutionGUID, StartTime, EndTime,
            DurationSeconds, Status, ErrorMessage
        )
        VALUES (
            @TableMappingID, @ExecutionGUID, @StartTime, GETDATE(),
            DATEDIFF(SECOND, @StartTime, GETDATE()), @Status, @ErrorMsg
        );
        
        PRINT 'ERROR: ' + @ErrorMsg;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- PART 10: MASTER ORCHESTRATION PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_ExecuteMasterOrchestration
AS
BEGIN
    DECLARE @TableMappingID INT;
    DECLARE @LoadOrder INT;
    DECLARE @SourceTable NVARCHAR(255);
    DECLARE @TargetTable NVARCHAR(255);
    
    PRINT 'Starting Master Orchestration';
    PRINT '==============================';
    
    -- Get all active mappings ordered by LoadOrder
    DECLARE mapping_cursor CURSOR FOR
    SELECT TableMappingID, LoadOrder, SourceTable, TargetTable
    FROM ETL_TableMapping
    WHERE IsActive = 1
    ORDER BY LoadOrder, TableMappingID;
    
    OPEN mapping_cursor;
    FETCH NEXT FROM mapping_cursor INTO @TableMappingID, @LoadOrder, @SourceTable, @TargetTable;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '';
        PRINT 'Load Order ' + CAST(@LoadOrder AS VARCHAR) + ': ' + @SourceTable + ' -> ' + @TargetTable;
        PRINT '----------------------------------------';
        
        -- Execute metadata-driven load
        EXEC sp_ExecuteMetadataDrivenLoad @TableMappingID;
        
        FETCH NEXT FROM mapping_cursor INTO @TableMappingID, @LoadOrder, @SourceTable, @TargetTable;
    END;
    
    CLOSE mapping_cursor;
    DEALLOCATE mapping_cursor;
    
    PRINT '';
    PRINT 'Master Orchestration Completed';
    PRINT '==============================';
END;
GO

-- Execute master orchestration
-- EXEC sp_ExecuteMasterOrchestration;

-- View execution log
SELECT 
    tm.SourceTable,
    tm.TargetTable,
    tm.LoadType,
    el.StartTime,
    el.DurationSeconds,
    el.RowsLoaded,
    el.Status
FROM ETL_ExecutionLog el
INNER JOIN ETL_TableMapping tm ON el.TableMappingID = tm.TableMappingID
ORDER BY el.StartTime DESC;

/*
============================================================================
METADATA-DRIVEN ETL BENEFITS
============================================================================

✓ SCALABILITY: Add new tables without coding
✓ MAINTAINABILITY: Change mappings in metadata, not code
✓ STANDARDIZATION: Consistent ETL patterns
✓ MONITORING: Centralized execution logging
✓ FLEXIBILITY: Support multiple load types
✓ REUSABILITY: One package handles all tables
✓ GOVERNANCE: Metadata serves as documentation

SSIS IMPLEMENTATION:
In SSIS, create ONE package that:
1. Executes SQL to read ETL_TableMapping
2. Loops through result set (Foreach Loop Container)
3. Sets package variables from metadata
4. Builds dynamic SQL using expressions
5. Executes data flow with dynamic source/destination

NEXT STEPS:
- Implement error handling per mapping
- Add column-level data quality rules
- Support complex transformations (lookups, aggregations)
- Implement parallel execution groups
- Add SCD logic for dimension tables
- Create metadata management UI

============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Created source/target system metadata
□ Configured table mappings
□ Configured column mappings with transformations
□ Built dynamic SQL generation
□ Created metadata-driven load procedures
□ Implemented master orchestration
□ Tested with sample mappings
□ Reviewed execution logs
□ Understood benefits of metadata approach

NEXT LAB: Lab 63 - Parallel Processing & Performance Optimization
============================================================================
*/
