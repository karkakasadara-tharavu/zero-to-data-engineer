/*******************************************************************************
 * LAB 83: SQL Capstone - Documentation and Deployment
 * Module 09: SQL Capstone Project
 * 
 * Objective: Create comprehensive documentation and deployment scripts for
 *            the GlobalMart Data Warehouse project.
 * 
 * Duration: 4-6 hours
 * 
 * Topics Covered:
 * - Data dictionary generation
 * - Deployment scripts
 * - Operations runbook
 * - Project handoff documentation
 ******************************************************************************/

USE GlobalMart_DW;
GO

-- Create Documentation schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Documentation')
    EXEC('CREATE SCHEMA Documentation');
GO

/*******************************************************************************
 * PART 1: DATA DICTIONARY GENERATION
 ******************************************************************************/

-- Generate table documentation
CREATE OR ALTER VIEW Documentation.vw_TableDocumentation
AS
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    CASE 
        WHEN s.name = 'Dim' THEN 'Dimension Table'
        WHEN s.name = 'Fact' THEN 'Fact Table'
        WHEN s.name = 'Staging' THEN 'Staging Table'
        WHEN s.name = 'ETL' THEN 'ETL Control Table'
        WHEN s.name = 'Reports' THEN 'Reporting View'
        ELSE 'Other'
    END AS TableType,
    p.rows AS RowCount,
    CAST(ROUND((SUM(a.total_pages) * 8.0) / 1024, 2) AS DECIMAL(18,2)) AS SizeMB,
    MAX(t.create_date) AS CreatedDate,
    MAX(t.modify_date) AS LastModified
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE s.name IN ('Dim', 'Fact', 'Staging', 'ETL', 'Testing')
GROUP BY s.name, t.name, p.rows;
GO

-- Generate column documentation
CREATE OR ALTER VIEW Documentation.vw_ColumnDocumentation
AS
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    c.column_id AS ColumnOrder,
    TYPE_NAME(c.user_type_id) AS DataType,
    c.max_length AS MaxLength,
    c.precision AS Precision,
    c.scale AS Scale,
    CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END AS IsNullable,
    CASE WHEN pk.column_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsPrimaryKey,
    CASE WHEN fk.parent_column_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsForeignKey,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    dc.definition AS DefaultValue
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
LEFT JOIN sys.foreign_key_columns fk ON c.object_id = fk.parent_object_id AND c.column_id = fk.parent_column_id
LEFT JOIN sys.default_constraints dc ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE s.name IN ('Dim', 'Fact', 'Staging', 'ETL', 'Testing', 'Reports');
GO

-- Generate stored procedure documentation
CREATE OR ALTER VIEW Documentation.vw_ProcedureDocumentation
AS
SELECT 
    s.name AS SchemaName,
    p.name AS ProcedureName,
    CASE 
        WHEN s.name = 'ETL' THEN 'ETL Procedure'
        WHEN s.name = 'Reports' THEN 'Reporting Procedure'
        WHEN s.name = 'Testing' THEN 'Testing Procedure'
        ELSE 'Other'
    END AS ProcedureType,
    p.create_date AS CreatedDate,
    p.modify_date AS LastModified,
    (SELECT COUNT(*) FROM sys.parameters WHERE object_id = p.object_id) AS ParameterCount
FROM sys.procedures p
INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
WHERE s.name IN ('ETL', 'Reports', 'Testing', 'Dim', 'Fact');
GO

-- Procedure to export data dictionary
CREATE OR ALTER PROCEDURE Documentation.sp_ExportDataDictionary
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '===============================================================';
    PRINT ' GLOBALMART DATA WAREHOUSE - DATA DICTIONARY';
    PRINT ' Generated: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '===============================================================';
    PRINT '';
    
    -- Tables Summary
    PRINT '=== TABLES ===';
    SELECT * FROM Documentation.vw_TableDocumentation ORDER BY SchemaName, TableName;
    
    PRINT '';
    PRINT '=== DIMENSION TABLES ===';
    SELECT SchemaName, TableName, ColumnName, DataType, IsNullable, IsPrimaryKey
    FROM Documentation.vw_ColumnDocumentation
    WHERE SchemaName = 'Dim'
    ORDER BY TableName, ColumnOrder;
    
    PRINT '';
    PRINT '=== FACT TABLES ===';
    SELECT SchemaName, TableName, ColumnName, DataType, IsNullable, IsForeignKey, ReferencedTable
    FROM Documentation.vw_ColumnDocumentation
    WHERE SchemaName = 'Fact'
    ORDER BY TableName, ColumnOrder;
    
    PRINT '';
    PRINT '=== STORED PROCEDURES ===';
    SELECT * FROM Documentation.vw_ProcedureDocumentation ORDER BY SchemaName, ProcedureName;
END;
GO

/*******************************************************************************
 * PART 2: DEPLOYMENT SCRIPTS
 ******************************************************************************/

-- Generate deployment script
CREATE OR ALTER PROCEDURE Documentation.sp_GenerateDeploymentScript
    @OutputType NVARCHAR(20) = 'Print' -- 'Print' or 'Select'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Script NVARCHAR(MAX) = '';
    
    -- Header
    SET @Script = @Script + '-- =============================================================' + CHAR(13);
    SET @Script = @Script + '-- GLOBALMART DATA WAREHOUSE - DEPLOYMENT SCRIPT' + CHAR(13);
    SET @Script = @Script + '-- Generated: ' + CONVERT(VARCHAR, GETDATE(), 120) + CHAR(13);
    SET @Script = @Script + '-- =============================================================' + CHAR(13);
    SET @Script = @Script + CHAR(13);
    
    -- Pre-deployment checks
    SET @Script = @Script + '-- PRE-DEPLOYMENT CHECKS' + CHAR(13);
    SET @Script = @Script + 'PRINT ''Starting deployment...'';' + CHAR(13);
    SET @Script = @Script + 'PRINT ''SQL Server Version: '' + @@VERSION;' + CHAR(13);
    SET @Script = @Script + 'PRINT ''Current Database: '' + DB_NAME();' + CHAR(13);
    SET @Script = @Script + CHAR(13);
    
    -- Schema creation
    SET @Script = @Script + '-- SCHEMA CREATION' + CHAR(13);
    SET @Script = @Script + 'IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = ''Dim'') EXEC(''CREATE SCHEMA Dim'');' + CHAR(13);
    SET @Script = @Script + 'IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = ''Fact'') EXEC(''CREATE SCHEMA Fact'');' + CHAR(13);
    SET @Script = @Script + 'IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = ''Staging'') EXEC(''CREATE SCHEMA Staging'');' + CHAR(13);
    SET @Script = @Script + 'IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = ''ETL'') EXEC(''CREATE SCHEMA ETL'');' + CHAR(13);
    SET @Script = @Script + 'IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = ''Reports'') EXEC(''CREATE SCHEMA Reports'');' + CHAR(13);
    SET @Script = @Script + 'IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = ''Testing'') EXEC(''CREATE SCHEMA Testing'');' + CHAR(13);
    SET @Script = @Script + 'GO' + CHAR(13);
    SET @Script = @Script + CHAR(13);
    
    -- Deployment order reference
    SET @Script = @Script + '-- DEPLOYMENT ORDER' + CHAR(13);
    SET @Script = @Script + '-- 1. lab_77_physical_design.sql - Create tables' + CHAR(13);
    SET @Script = @Script + '-- 2. lab_78_sample_data.sql - Load DimDate' + CHAR(13);
    SET @Script = @Script + '-- 3. lab_79_dimension_etl.sql - Dimension ETL procedures' + CHAR(13);
    SET @Script = @Script + '-- 4. lab_80_fact_etl.sql - Fact ETL procedures' + CHAR(13);
    SET @Script = @Script + '-- 5. lab_81_reporting_layer.sql - Reporting views' + CHAR(13);
    SET @Script = @Script + '-- 6. lab_82_testing_validation.sql - Testing framework' + CHAR(13);
    SET @Script = @Script + CHAR(13);
    
    -- Post-deployment validation
    SET @Script = @Script + '-- POST-DEPLOYMENT VALIDATION' + CHAR(13);
    SET @Script = @Script + 'EXEC Testing.sp_RunAllTests;' + CHAR(13);
    SET @Script = @Script + CHAR(13);
    
    SET @Script = @Script + 'PRINT ''Deployment complete!'';' + CHAR(13);
    
    IF @OutputType = 'Print'
        PRINT @Script;
    ELSE
        SELECT @Script AS DeploymentScript;
END;
GO

/*******************************************************************************
 * PART 3: OPERATIONS RUNBOOK
 ******************************************************************************/

-- Create operations guide view
CREATE OR ALTER VIEW Documentation.vw_DailyOperations
AS
SELECT 
    1 AS StepOrder,
    'Daily ETL' AS Operation,
    'EXEC ETL.sp_RunFullETL @FullLoad = 0;' AS Command,
    'Run incremental ETL to load new data' AS Description,
    '06:00' AS ScheduledTime
UNION ALL SELECT 2, 'Validate ETL', 'EXEC Testing.sp_Test_ETLReconciliation;', 'Verify ETL completed successfully', '07:00'
UNION ALL SELECT 3, 'Refresh Aggregates', 'EXEC ETL.sp_Refresh_FactSalesAggregate;', 'Update pre-aggregated tables', '07:30'
UNION ALL SELECT 4, 'Check Errors', 'SELECT TOP 20 * FROM ETL.ErrorLog ORDER BY ErrorDate DESC;', 'Review any ETL errors', '08:00';
GO

-- Troubleshooting guide
CREATE OR ALTER VIEW Documentation.vw_TroubleshootingGuide
AS
SELECT 
    'ETL Failed' AS Issue,
    'Check ETL.ExecutionLog for error details' AS DiagnosticStep,
    'SELECT * FROM ETL.ExecutionLog WHERE Status = ''Failed'' ORDER BY ExecutionID DESC;' AS DiagnosticQuery,
    'Fix source data or ETL procedure, then re-run' AS Resolution
UNION ALL
SELECT 
    'Missing Dimension Keys',
    'Check for -1 keys in fact tables',
    'SELECT COUNT(*) FROM Fact.FactSales WHERE CustomerKey = -1;',
    'Ensure dimension ETL runs before fact ETL'
UNION ALL
SELECT 
    'Slow Query Performance',
    'Check for missing indexes',
    'SELECT * FROM sys.dm_db_missing_index_details;',
    'Create recommended indexes or update statistics'
UNION ALL
SELECT 
    'Data Mismatch',
    'Run reconciliation tests',
    'EXEC Testing.sp_Test_ETLReconciliation;',
    'Investigate source data or transformation logic';
GO

/*******************************************************************************
 * PART 4: MONITORING QUERIES
 ******************************************************************************/

-- ETL Monitoring Dashboard
CREATE OR ALTER PROCEDURE Documentation.sp_ETLMonitoringDashboard
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== ETL MONITORING DASHBOARD ===';
    PRINT 'Generated: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '';
    
    -- Recent ETL Executions
    PRINT '--- Recent ETL Executions ---';
    SELECT TOP 10
        PackageName,
        Status,
        RowsExtracted,
        RowsInserted,
        RowsUpdated,
        DATEDIFF(SECOND, ExecutionStartTime, ExecutionEndTime) AS DurationSec,
        ExecutionStartTime
    FROM ETL.ExecutionLog
    ORDER BY ExecutionID DESC;
    
    -- Watermark Status
    PRINT '';
    PRINT '--- Watermark Status ---';
    SELECT * FROM ETL.Watermark;
    
    -- Data Freshness
    PRINT '';
    PRINT '--- Data Freshness ---';
    SELECT 
        'FactSales' AS TableName,
        MAX(dd.FullDate) AS LatestDataDate,
        DATEDIFF(DAY, MAX(dd.FullDate), GETDATE()) AS DaysOld
    FROM Fact.FactSales fs
    INNER JOIN Dim.DimDate dd ON fs.OrderDateKey = dd.DateKey
    UNION ALL
    SELECT 
        'FactInventory',
        MAX(dd.FullDate),
        DATEDIFF(DAY, MAX(dd.FullDate), GETDATE())
    FROM Fact.FactInventory fi
    INNER JOIN Dim.DimDate dd ON fi.DateKey = dd.DateKey;
    
    -- Table Sizes
    PRINT '';
    PRINT '--- Table Sizes ---';
    SELECT * FROM Documentation.vw_TableDocumentation 
    ORDER BY SizeMB DESC;
    
    -- Recent Errors
    PRINT '';
    PRINT '--- Recent Errors (Last 24 Hours) ---';
    SELECT TOP 10 *
    FROM ETL.ErrorLog
    WHERE ErrorDate >= DATEADD(HOUR, -24, GETDATE())
    ORDER BY ErrorDate DESC;
END;
GO

/*******************************************************************************
 * PART 5: PROJECT SUMMARY
 ******************************************************************************/

CREATE OR ALTER PROCEDURE Documentation.sp_ProjectSummary
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '===============================================================';
    PRINT ' GLOBALMART DATA WAREHOUSE - PROJECT SUMMARY';
    PRINT '===============================================================';
    PRINT '';
    
    PRINT 'PROJECT OVERVIEW';
    PRINT '----------------';
    PRINT 'Name: GlobalMart Enterprise Data Warehouse';
    PRINT 'Database: GlobalMart_DW';
    PRINT 'Architecture: Kimball Dimensional Model';
    PRINT '';
    
    PRINT 'SCHEMAS';
    PRINT '-------';
    SELECT name AS SchemaName,
           (SELECT COUNT(*) FROM sys.tables t WHERE t.schema_id = s.schema_id) AS TableCount,
           (SELECT COUNT(*) FROM sys.procedures p WHERE p.schema_id = s.schema_id) AS ProcedureCount,
           (SELECT COUNT(*) FROM sys.views v WHERE v.schema_id = s.schema_id) AS ViewCount
    FROM sys.schemas s
    WHERE name IN ('Dim', 'Fact', 'Staging', 'ETL', 'Reports', 'Testing', 'Documentation');
    
    PRINT '';
    PRINT 'DIMENSION TABLES';
    PRINT '----------------';
    SELECT 
        t.name AS TableName,
        p.rows AS RowCount,
        CASE WHEN EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = t.object_id AND c.name = 'IsCurrent')
             THEN 'SCD Type 2' ELSE 'SCD Type 1' END AS SCDType
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
    WHERE s.name = 'Dim';
    
    PRINT '';
    PRINT 'FACT TABLES';
    PRINT '-----------';
    SELECT 
        t.name AS TableName,
        p.rows AS RowCount,
        CASE 
            WHEN t.name LIKE '%Aggregate%' THEN 'Aggregate'
            WHEN t.name LIKE '%Inventory%' THEN 'Periodic Snapshot'
            ELSE 'Transaction'
        END AS FactType
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
    WHERE s.name = 'Fact';
    
    PRINT '';
    PRINT 'ETL PROCEDURES';
    PRINT '--------------';
    SELECT name FROM sys.procedures WHERE schema_id = SCHEMA_ID('ETL') ORDER BY name;
    
    PRINT '';
    PRINT 'REPORT VIEWS';
    PRINT '------------';
    SELECT name FROM sys.views WHERE schema_id = SCHEMA_ID('Reports') ORDER BY name;
    
    PRINT '';
    PRINT '===============================================================';
    PRINT ' CAPSTONE PROJECT COMPLETE!';
    PRINT '===============================================================';
END;
GO

/*******************************************************************************
 * PART 6: EXECUTE DOCUMENTATION
 ******************************************************************************/

-- Generate all documentation
EXEC Documentation.sp_ExportDataDictionary;
EXEC Documentation.sp_GenerateDeploymentScript;
EXEC Documentation.sp_ProjectSummary;

-- View operations guides
SELECT * FROM Documentation.vw_DailyOperations ORDER BY StepOrder;
SELECT * FROM Documentation.vw_TroubleshootingGuide;

PRINT '
=============================================================================
LAB 83 COMPLETE - DOCUMENTATION AND DEPLOYMENT
=============================================================================

Documentation Created:
- vw_TableDocumentation: All tables with sizes and types
- vw_ColumnDocumentation: Complete column metadata
- vw_ProcedureDocumentation: All stored procedures
- vw_DailyOperations: Operations runbook
- vw_TroubleshootingGuide: Common issues and solutions

Procedures Created:
- sp_ExportDataDictionary: Generate complete data dictionary
- sp_GenerateDeploymentScript: Create deployment script
- sp_ETLMonitoringDashboard: Real-time ETL monitoring
- sp_ProjectSummary: Complete project overview

=============================================================================
GLOBALMART DATA WAREHOUSE CAPSTONE - ALL LABS COMPLETE!
=============================================================================

Labs Completed:
✓ Lab 76: Requirements and Design
✓ Lab 77: Physical Database Implementation
✓ Lab 78: Sample Data Generation
✓ Lab 79: Dimension ETL Implementation
✓ Lab 80: Fact Table ETL Implementation
✓ Lab 81: Reporting Layer
✓ Lab 82: Testing and Validation
✓ Lab 83: Documentation and Deployment

Skills Demonstrated:
- Database design (star schema, normalization)
- Physical implementation (tables, indexes, partitioning)
- ETL development (staging, SCD, incremental loads)
- Reporting (views, stored procedures, dashboards)
- Testing (data quality, reconciliation, performance)
- Documentation (data dictionary, runbooks)

Congratulations on completing the SQL Capstone Project!
';
GO
