/*
============================================================================
LAB 53: SSIS INTRODUCTION & ENVIRONMENT SETUP
Module 06: ETL SSIS Fundamentals
============================================================================

OBJECTIVE:
- Understand ETL concepts and SSIS architecture
- Set up SSIS development environment
- Create your first SSIS package
- Understand SSIS project structure and components

DURATION: 90 minutes
DIFFICULTY: ⭐⭐ (Intermediate)

PREREQUISITES:
- SQL Server 2019+ installed
- Visual Studio with SSDT (SQL Server Data Tools) installed
- BookstoreDB database available
- Basic understanding of ETL concepts

DATABASE: BookstoreDB (setup scripts provided)
============================================================================
*/

USE BookstoreDB;
GO

-- ============================================================================
-- PART 1: UNDERSTANDING ETL CONCEPTS
-- ============================================================================
/*
ETL stands for Extract, Transform, Load:
- EXTRACT: Pull data from source systems (databases, files, APIs, etc.)
- TRANSFORM: Clean, validate, and convert data to meet business requirements
- LOAD: Insert transformed data into target data warehouse or database

SSIS (SQL Server Integration Services) is Microsoft's ETL platform that provides:
- Visual design interface for building data workflows
- Built-in transformations and connectors
- High-performance data movement
- Error handling and logging capabilities
- Scheduling and automation features
*/

-- Create staging database for ETL demonstrations
IF DB_ID('BookstoreETL') IS NULL
    CREATE DATABASE BookstoreETL;
GO

USE BookstoreETL;
GO

-- Create staging tables for ETL processes
-- Staging area: temporary storage for data during ETL
CREATE TABLE Staging_Customers (
    CustomerID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    JoinDate DATE,
    LoadDate DATETIME DEFAULT GETDATE(),
    LoadStatus NVARCHAR(50) DEFAULT 'PENDING'
);

CREATE TABLE Staging_Orders (
    OrderID INT,
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10, 2),
    LoadDate DATETIME DEFAULT GETDATE(),
    LoadStatus NVARCHAR(50) DEFAULT 'PENDING'
);

-- Create error logging table
CREATE TABLE ETL_ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    TaskName NVARCHAR(255),
    ErrorCode INT,
    ErrorDescription NVARCHAR(MAX),
    ErrorDate DATETIME DEFAULT GETDATE()
);

-- Create audit table for tracking ETL runs
CREATE TABLE ETL_AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    StartTime DATETIME,
    EndTime DATETIME,
    Status NVARCHAR(50),
    RowsExtracted INT,
    RowsTransformed INT,
    RowsLoaded INT,
    ErrorCount INT
);

-- ============================================================================
-- PART 2: SSIS ARCHITECTURE OVERVIEW
-- ============================================================================
/*
SSIS ARCHITECTURE COMPONENTS:

1. CONTROL FLOW:
   - Defines workflow and execution order
   - Contains tasks (Execute SQL, Data Flow, File System, etc.)
   - Implements precedence constraints and containers
   - Handles loops and conditional execution

2. DATA FLOW:
   - High-speed data transformation pipeline
   - Contains sources, transformations, and destinations
   - Processes data in memory buffers
   - Supports row-by-row or set-based operations

3. PACKAGE STRUCTURE:
   - Connection Managers: Define connections to data sources
   - Variables: Store values for dynamic package behavior
   - Event Handlers: Respond to package events
   - Parameters: Allow runtime configuration

4. DEPLOYMENT MODELS:
   - Package Deployment Model: Deploy individual packages
   - Project Deployment Model: Deploy entire projects to SSISDB catalog
*/

-- Create procedure to initialize ETL audit
CREATE PROCEDURE sp_StartETLAudit
    @PackageName NVARCHAR(255),
    @AuditID INT OUTPUT
AS
BEGIN
    INSERT INTO ETL_AuditLog (PackageName, StartTime, Status)
    VALUES (@PackageName, GETDATE(), 'RUNNING');
    
    SET @AuditID = SCOPE_IDENTITY();
END;
GO

-- Create procedure to complete ETL audit
CREATE PROCEDURE sp_CompleteETLAudit
    @AuditID INT,
    @Status NVARCHAR(50),
    @RowsExtracted INT = 0,
    @RowsTransformed INT = 0,
    @RowsLoaded INT = 0,
    @ErrorCount INT = 0
AS
BEGIN
    UPDATE ETL_AuditLog
    SET EndTime = GETDATE(),
        Status = @Status,
        RowsExtracted = @RowsExtracted,
        RowsTransformed = @RowsTransformed,
        RowsLoaded = @RowsLoaded,
        ErrorCount = @ErrorCount
    WHERE AuditID = @AuditID;
END;
GO

-- ============================================================================
-- PART 3: ENVIRONMENT SETUP VERIFICATION
-- ============================================================================

-- Check SQL Server version (SSIS requires SQL Server 2016+)
SELECT 
    SERVERPROPERTY('ProductVersion') AS SQLServerVersion,
    SERVERPROPERTY('ProductLevel') AS ServicePack,
    SERVERPROPERTY('Edition') AS Edition,
    CASE 
        WHEN CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)) >= '13.0'
        THEN 'SSIS Compatible'
        ELSE 'Upgrade Required'
    END AS SSISCompatibility;

-- Verify SSISDB catalog exists (Integration Services Catalog)
IF DB_ID('SSISDB') IS NOT NULL
    SELECT 'SSISDB Catalog Exists' AS Status, 
           'Project Deployment Model Available' AS DeploymentModel;
ELSE
    SELECT 'SSISDB Catalog NOT Found' AS Status,
           'Enable Integration Services Feature in SQL Server Configuration' AS Action;

-- Check if Integration Services service is running (requires xp_cmdshell)
-- Note: This requires appropriate permissions
/*
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

EXEC xp_cmdshell 'sc query MsDtsServer150'; -- For SQL Server 2019
*/

-- ============================================================================
-- PART 4: CREATING SAMPLE DATA FOR ETL PRACTICE
-- ============================================================================

USE BookstoreDB;
GO

-- Create source tables if they don't exist
IF OBJECT_ID('dbo.SourceCustomers', 'U') IS NULL
BEGIN
    CREATE TABLE SourceCustomers (
        CustomerID INT PRIMARY KEY,
        FirstName NVARCHAR(50),
        LastName NVARCHAR(50),
        Email NVARCHAR(100),
        Phone NVARCHAR(20),
        JoinDate DATE,
        IsActive BIT DEFAULT 1
    );
END;

-- Insert sample data for ETL testing
TRUNCATE TABLE SourceCustomers;

INSERT INTO SourceCustomers (CustomerID, FirstName, LastName, Email, Phone, JoinDate, IsActive)
VALUES
    (1, 'John', 'Smith', 'john.smith@email.com', '555-0101', '2024-01-15', 1),
    (2, 'Sarah', 'Johnson', 'sarah.j@email.com', '555-0102', '2024-01-20', 1),
    (3, 'Michael', 'Williams', 'mike.w@email.com', '555-0103', '2024-02-01', 1),
    (4, 'Emily', 'Brown', 'emily.b@email.com', '555-0104', '2024-02-15', 1),
    (5, 'David', 'Jones', 'david.jones@email.com', '555-0105', '2024-03-01', 1),
    (6, 'Jessica', 'Garcia', 'jess.garcia@email.com', '555-0106', '2024-03-10', 0),
    (7, 'James', 'Martinez', 'james.m@email.com', '555-0107', '2024-03-15', 1),
    (8, 'Linda', 'Rodriguez', 'linda.r@email.com', '555-0108', '2024-04-01', 1),
    (9, 'Robert', 'Wilson', 'robert.w@email.com', '555-0109', '2024-04-10', 1),
    (10, 'Mary', 'Anderson', 'mary.a@email.com', '555-0110', '2024-04-20', 1);

SELECT * FROM SourceCustomers;

-- Create incremental load tracking table
IF OBJECT_ID('dbo.ETL_WaterMark', 'U') IS NULL
BEGIN
    CREATE TABLE ETL_WaterMark (
        TableName NVARCHAR(100) PRIMARY KEY,
        LastExtractDate DATETIME,
        LastExtractID INT
    );
END;

INSERT INTO ETL_WaterMark (TableName, LastExtractDate, LastExtractID)
VALUES ('SourceCustomers', '2024-01-01', 0);

-- ============================================================================
-- PART 5: SSIS PACKAGE CREATION STEPS
-- ============================================================================
/*
STEP-BY-STEP GUIDE TO CREATE YOUR FIRST SSIS PACKAGE:

1. OPEN VISUAL STUDIO:
   - Launch Visual Studio (2017, 2019, or 2022)
   - Ensure SSDT (SQL Server Data Tools) is installed

2. CREATE NEW PROJECT:
   - File → New → Project
   - Select "Integration Services Project"
   - Name: "BookstoreETL"
   - Location: Choose your workspace folder

3. PROJECT STRUCTURE:
   - Solution Explorer shows:
     * Connection Managers
     * SSIS Packages (Package.dtsx is default)
     * Project.params (project-level parameters)
     * Miscellaneous folder

4. PACKAGE DESIGNER TABS:
   - Control Flow: Main workflow design surface
   - Data Flow: Data transformation pipeline
   - Parameters: Package parameters
   - Event Handlers: Error and event handling
   - Package Explorer: Package structure tree

5. TOOLBOX:
   - Control Flow Items: Tasks and containers
   - Data Flow Sources: OLE DB, Flat File, Excel, etc.
   - Data Flow Transformations: Lookup, Derived Column, etc.
   - Data Flow Destinations: Database tables, files

6. CONNECTION MANAGERS:
   - Right-click in Connection Managers area
   - Add new connections for:
     * Source database (BookstoreDB)
     * Staging database (BookstoreETL)
     * File system connections
*/

-- Query to help configure connection strings
SELECT 
    'Data Source=' + @@SERVERNAME + ';' +
    'Initial Catalog=BookstoreDB;' +
    'Provider=SQLNCLI11.1;' +
    'Integrated Security=SSPI;' AS SourceConnectionString,
    
    'Data Source=' + @@SERVERNAME + ';' +
    'Initial Catalog=BookstoreETL;' +
    'Provider=SQLNCLI11.1;' +
    'Integrated Security=SSPI;' AS StagingConnectionString;

-- ============================================================================
-- PART 6: CREATING A SIMPLE CONTROL FLOW
-- ============================================================================
/*
FIRST PACKAGE EXAMPLE: "PKG_Simple_Extract"

CONTROL FLOW TASKS:
1. Execute SQL Task: Clear staging table
2. Data Flow Task: Extract data from source to staging
3. Execute SQL Task: Update watermark table

DESIGN STEPS:
1. Drag "Execute SQL Task" to Control Flow
   - Name: "SQL - Clear Staging"
   - Connection: BookstoreETL
   - SQL Statement: TRUNCATE TABLE Staging_Customers;

2. Drag "Data Flow Task" to Control Flow
   - Name: "DFT - Extract Customers"
   - Connect from previous task (green arrow)

3. Inside Data Flow Task:
   a. OLE DB Source:
      - Name: "SRC - Source Customers"
      - Connection Manager: BookstoreDB
      - Table: dbo.SourceCustomers
   
   b. OLE DB Destination:
      - Name: "DST - Staging Customers"
      - Connection Manager: BookstoreETL
      - Table: dbo.Staging_Customers
   
   c. Connect source to destination (blue arrow)

4. Back in Control Flow, add Execute SQL Task:
   - Name: "SQL - Update Watermark"
   - Connection: BookstoreDB
   - SQL Statement: UPDATE ETL_WaterMark 
                    SET LastExtractDate = GETDATE()
                    WHERE TableName = 'SourceCustomers';
*/

-- Verification queries to run after package execution
USE BookstoreETL;
GO

-- Check staging table contents
SELECT COUNT(*) AS StagedRecords FROM Staging_Customers;
SELECT * FROM Staging_Customers;

-- Check watermark
USE BookstoreDB;
GO
SELECT * FROM ETL_WaterMark WHERE TableName = 'SourceCustomers';

-- ============================================================================
-- PART 7: PACKAGE VARIABLES AND EXPRESSIONS
-- ============================================================================
/*
VARIABLES are used to store values that can be used throughout the package:

CREATING VARIABLES:
1. View → Other Windows → Variables (or press Ctrl+Alt+V)
2. Click "Add Variable" icon in Variables window
3. Common variable properties:
   - Name: Descriptive name (e.g., ExtractCount, LastRunDate)
   - Scope: Package or Task level
   - Data Type: Boolean, Int32, String, DateTime, Object
   - Value: Initial value

COMMON VARIABLE USES:
- Row counts
- File paths
- SQL query strings
- Configuration values
- Loop counters

EXPRESSIONS:
- Allow dynamic property values
- Use @[Variable::VariableName] syntax
- Support functions: YEAR(), MONTH(), GETDATE(), etc.
*/

-- Example: Create variables table for documentation
USE BookstoreETL;
GO

CREATE TABLE PackageVariables (
    VariableID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    VariableName NVARCHAR(100),
    DataType NVARCHAR(50),
    Purpose NVARCHAR(MAX)
);

INSERT INTO PackageVariables (PackageName, VariableName, DataType, Purpose)
VALUES
    ('PKG_Simple_Extract', 'ExtractDate', 'DateTime', 'Stores current extraction timestamp'),
    ('PKG_Simple_Extract', 'RowCount', 'Int32', 'Stores number of rows extracted'),
    ('PKG_Simple_Extract', 'SourceConnection', 'String', 'Dynamic connection string'),
    ('PKG_Simple_Extract', 'TargetTable', 'String', 'Dynamic table name for load');

-- ============================================================================
-- PART 8: PACKAGE PARAMETERS
-- ============================================================================
/*
PARAMETERS provide configuration flexibility:

PACKAGE PARAMETERS:
- Defined at package level
- Can be overridden at execution time
- Accessible via @[$Package::ParameterName]

PROJECT PARAMETERS:
- Defined at project level
- Shared across all packages
- Accessible via @[$Project::ParameterName]

CREATING PARAMETERS:
1. Click "Parameters" tab in package designer
2. Click "Add Parameter"
3. Configure:
   - Name: ServerName, DatabaseName, FilePath
   - Data Type: String, Int32, Boolean
   - Required: Yes/No
   - Sensitive: Yes (encrypted) / No
   - Default Value: Initial value

ADVANTAGES:
- Environment-specific configuration
- No package modification between DEV/TEST/PROD
- Centralized configuration management
*/

-- Query to document package parameters
INSERT INTO PackageVariables (PackageName, VariableName, DataType, Purpose)
VALUES
    ('PKG_Simple_Extract', 'ServerName', 'String (Parameter)', 'Target SQL Server instance'),
    ('PKG_Simple_Extract', 'DatabaseName', 'String (Parameter)', 'Target database name'),
    ('PKG_Simple_Extract', 'BatchSize', 'Int32 (Parameter)', 'Number of rows per batch');

-- ============================================================================
-- PART 9: EXECUTING AND DEBUGGING PACKAGES
-- ============================================================================
/*
EXECUTION METHODS:

1. DESIGN-TIME EXECUTION (Development):
   - Press F5 or click "Start" button
   - Package runs in Debug mode
   - Visual feedback with color coding:
     * Yellow: Currently executing
     * Green: Successful execution
     * Red: Failed execution
   - Output window shows execution details

2. BREAKPOINTS (Debugging):
   - Right-click task → Edit Breakpoints
   - Break on Pre-execute, Post-execute, Error
   - Inspect variable values during execution
   - Step through tasks one at a time

3. DATA VIEWERS (Data Flow Debugging):
   - Right-click data flow path (blue arrow)
   - Enable Data Viewer
   - View data in grid during execution
   - Helpful for troubleshooting transformations

4. PROGRESS/EXECUTION RESULTS:
   - Progress tab shows real-time execution
   - Displays task start/end times
   - Shows row counts for data flows
   - Displays error messages

5. LOGGING:
   - Right-click package design surface → Logging
   - Select events to log (OnError, OnWarning, OnInformation)
   - Choose log provider (SQL Server, Text File, Windows Event Log)
   - Configure log connection
*/

-- Create logging table for SSIS execution
USE BookstoreETL;
GO

CREATE TABLE SSIS_ExecutionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID UNIQUEIDENTIFIER,
    PackageName NVARCHAR(255),
    TaskName NVARCHAR(255),
    EventType NVARCHAR(50),
    Message NVARCHAR(MAX),
    SourceName NVARCHAR(255),
    SourceID UNIQUEIDENTIFIER,
    LogDate DATETIME DEFAULT GETDATE()
);

-- ============================================================================
-- PART 10: PACKAGE DEPLOYMENT BASICS
-- ============================================================================
/*
DEPLOYMENT MODELS:

1. PROJECT DEPLOYMENT MODEL (Recommended):
   - Deploy to SSISDB catalog
   - Environment-based configuration
   - Built-in execution logging
   - Version control
   
   STEPS:
   a. Build project (Build → Build Solution)
   b. Deploy project (Project → Deploy)
   c. Connect to target SQL Server
   d. Select SSISDB catalog folder
   e. Review and deploy

2. PACKAGE DEPLOYMENT MODEL (Legacy):
   - Deploy .dtsx files directly
   - Use XML configuration files
   - Less robust logging
   
   STEPS:
   a. Copy .dtsx files to server
   b. Create SQL Server Agent jobs
   c. Configure package configurations

3. EXECUTION VIA SQL SERVER AGENT:
   - Create new SQL Server Agent Job
   - Job Step Type: "SQL Server Integration Services Package"
   - Select package from SSISDB or File System
   - Configure parameters and connections
   - Set schedule (daily, hourly, etc.)
*/

-- Query to check SSISDB catalog projects and packages
IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    USE SSISDB;
    
    -- List deployed projects
    SELECT 
        folder_name AS FolderName,
        project_name AS ProjectName,
        deployed_by_name AS DeployedBy,
        last_deployed_time AS DeployedDate,
        project_description AS Description
    FROM catalog.projects
    ORDER BY last_deployed_time DESC;
    
    -- List packages in projects
    SELECT 
        p.project_name AS ProjectName,
        pk.name AS PackageName,
        pk.description AS PackageDescription,
        p.last_deployed_time AS DeployedDate
    FROM catalog.packages pk
    INNER JOIN catalog.projects p ON pk.project_id = p.project_id
    ORDER BY p.project_name, pk.name;
END;

-- ============================================================================
-- EXERCISES
-- ============================================================================

-- EXERCISE 1: Environment Setup Verification (10 minutes)
-- Verify your SSIS development environment is properly configured
/*
TASKS:
1. Open Visual Studio and verify SSDT is installed
2. Check SQL Server version is 2016 or later
3. Verify SSISDB catalog exists or create it
4. Create BookstoreETL database if not exists
5. Document your environment configuration
*/

-- EXERCISE 2: Create Your First Package (20 minutes)
-- Create a simple package that extracts data from source to staging
/*
TASKS:
1. Create new Integration Services Project named "BookstoreETL"
2. Add connection managers for BookstoreDB and BookstoreETL
3. Create control flow with these tasks:
   - Execute SQL Task to truncate Staging_Customers
   - Data Flow Task to copy SourceCustomers to Staging_Customers
   - Execute SQL Task to log completion in ETL_AuditLog
4. Execute package and verify results
*/

-- EXERCISE 3: Add Variables (15 minutes)
-- Enhance your package with variables
/*
TASKS:
1. Add package variable "ExtractDate" (DateTime) = GETDATE()
2. Add variable "RowCountSource" (Int32)
3. Add variable "RowCountStaging" (Int32)
4. Use Execute SQL Task to populate row count variables
5. Display variable values using Script Task or logging
*/

-- EXERCISE 4: Implement Basic Logging (20 minutes)
-- Add execution logging to your package
/*
TASKS:
1. Create stored procedures for audit logging (already provided above)
2. Add Execute SQL Task at start to call sp_StartETLAudit
3. Store AuditID in variable
4. Add Execute SQL Task at end to call sp_CompleteETLAudit
5. Execute package and verify audit log entries
*/

-- EXERCISE 5: Create Package Parameters (15 minutes)
-- Make your package configurable with parameters
/*
TASKS:
1. Create package parameters:
   - SourceServer (String)
   - SourceDatabase (String)
   - TargetDatabase (String)
2. Modify connection managers to use parameters
3. Test package with different parameter values
4. Document parameter usage
*/

-- ============================================================================
-- CHALLENGE PROBLEMS
-- ============================================================================

-- CHALLENGE 1: Multi-Table Extract Package (30 minutes)
-- Create a package that extracts multiple tables in sequence
/*
REQUIREMENTS:
1. Create staging tables for Books, Orders, and OrderDetails
2. Build package with 3 Data Flow Tasks (one per table)
3. Use precedence constraints for sequential execution
4. Implement row count tracking for each table
5. Log all extracts in ETL_AuditLog with separate entries
*/

USE BookstoreDB;
GO

-- Create source tables
IF OBJECT_ID('dbo.SourceBooks', 'U') IS NULL
BEGIN
    CREATE TABLE SourceBooks (
        BookID INT PRIMARY KEY,
        Title NVARCHAR(200),
        ISBN NVARCHAR(20),
        Price DECIMAL(10, 2),
        PublishDate DATE
    );
END;

IF OBJECT_ID('dbo.SourceOrders', 'U') IS NULL
BEGIN
    CREATE TABLE SourceOrders (
        OrderID INT PRIMARY KEY,
        CustomerID INT,
        OrderDate DATETIME,
        TotalAmount DECIMAL(10, 2)
    );
END;

-- Insert sample data
INSERT INTO SourceBooks VALUES
    (1, 'SQL Server 2019 Guide', '978-1234567890', 49.99, '2024-01-15'),
    (2, 'SSIS Mastery', '978-0987654321', 59.99, '2024-02-01'),
    (3, 'Data Engineering Handbook', '978-1122334455', 69.99, '2024-03-10');

INSERT INTO SourceOrders VALUES
    (1, 1, '2024-05-01 10:30:00', 149.97),
    (2, 2, '2024-05-02 14:15:00', 59.99),
    (3, 3, '2024-05-03 09:45:00', 119.98);

-- CHALLENGE 2: Dynamic Table Extract (45 minutes)
-- Build a package that reads table names from a configuration table
/*
REQUIREMENTS:
1. Create configuration table with table names to extract
2. Use Foreach Loop Container to iterate through tables
3. Build dynamic Data Flow using variables
4. Handle different schemas automatically
5. Implement error handling for missing tables
*/

USE BookstoreETL;
GO

CREATE TABLE ETL_Configuration (
    ConfigID INT IDENTITY(1,1) PRIMARY KEY,
    SourceTable NVARCHAR(100),
    TargetTable NVARCHAR(100),
    IsActive BIT DEFAULT 1,
    LastProcessed DATETIME
);

INSERT INTO ETL_Configuration (SourceTable, TargetTable, IsActive)
VALUES
    ('SourceCustomers', 'Staging_Customers', 1),
    ('SourceBooks', 'Staging_Books', 1),
    ('SourceOrders', 'Staging_Orders', 1);

-- CHALLENGE 3: Incremental Load Pattern (60 minutes)
-- Implement incremental load instead of full extract
/*
REQUIREMENTS:
1. Modify package to extract only new/changed records
2. Use watermark table to track last extract
3. Add timestamp column to source tables if needed
4. Update watermark after successful load
5. Handle scenario where watermark doesn't exist
6. Test with incremental inserts to source table
*/

-- Add LastModified column to source table
ALTER TABLE SourceCustomers ADD LastModified DATETIME DEFAULT GETDATE();

-- Create trigger to update LastModified
CREATE TRIGGER trg_SourceCustomers_UpdateLastModified
ON SourceCustomers
AFTER UPDATE
AS
BEGIN
    UPDATE SourceCustomers
    SET LastModified = GETDATE()
    FROM SourceCustomers sc
    INNER JOIN inserted i ON sc.CustomerID = i.CustomerID;
END;
GO

-- ============================================================================
-- BEST PRACTICES
-- ============================================================================
/*
1. NAMING CONVENTIONS:
   - Packages: PKG_<Purpose>_<Entity>
   - Tasks: <Type>_<Action> (e.g., SQL_TruncateStaging, DFT_ExtractCustomers)
   - Variables: Use PascalCase or camelCase consistently
   - Connection Managers: Descriptive names (Source_BookstoreDB, Target_Warehouse)

2. ERROR HANDLING:
   - Always implement error logging
   - Use event handlers for OnError events
   - Send notifications for critical failures
   - Implement retry logic for transient errors

3. PERFORMANCE:
   - Use appropriate batch sizes
   - Minimize lookups in data flow
   - Use SQL transformations when possible
   - Implement parallel processing where appropriate
   - Monitor buffer memory usage

4. MAINTAINABILITY:
   - Document package purpose and logic
   - Use annotations in control flow
   - Implement consistent naming conventions
   - Use parameters for environment-specific values
   - Version control SSIS projects

5. SECURITY:
   - Use Windows Authentication when possible
   - Mark sensitive parameters as "Sensitive"
   - Implement least-privilege access
   - Encrypt connection strings
   - Audit package executions

6. TESTING:
   - Test with small datasets first
   - Validate data quality after load
   - Test error scenarios
   - Verify performance with production-size data
   - Document test results
*/

-- ============================================================================
-- REFERENCE QUERIES
-- ============================================================================

-- View ETL audit history
USE BookstoreETL;
GO

SELECT 
    PackageName,
    StartTime,
    EndTime,
    DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
    Status,
    RowsExtracted,
    RowsLoaded,
    ErrorCount
FROM ETL_AuditLog
ORDER BY StartTime DESC;

-- View error log
SELECT 
    ErrorDate,
    PackageName,
    TaskName,
    ErrorCode,
    ErrorDescription
FROM ETL_ErrorLog
ORDER BY ErrorDate DESC;

-- Check staging table status
SELECT 
    LoadDate,
    COUNT(*) AS RecordCount,
    LoadStatus
FROM Staging_Customers
GROUP BY LoadDate, LoadStatus
ORDER BY LoadDate DESC;

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Verified SSIS development environment is set up correctly
□ Created BookstoreETL database with staging tables
□ Created first SSIS package with basic extract logic
□ Added connection managers for source and target databases
□ Implemented package variables for dynamic values
□ Created package parameters for configuration
□ Executed package successfully in debug mode
□ Implemented basic audit logging
□ Reviewed package execution logs
□ Completed all exercises and at least one challenge

NEXT LAB: Lab 54 - SSIS Control Flow Tasks
============================================================================
*/
