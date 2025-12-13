/*
============================================================================
LAB 58: SSIS PACKAGE CONFIGURATION, PARAMETERS & DEPLOYMENT
Module 06: ETL SSIS Fundamentals
============================================================================

OBJECTIVE:
- Master SSIS package and project parameters
- Configure environments in SSISDB catalog
- Deploy packages to SQL Server
- Implement configuration management strategies
- Schedule packages with SQL Server Agent

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)

PREREQUISITES:
- Completed Labs 53-57
- SQL Server with SSISDB catalog enabled
- SQL Server Agent access
- Understanding of deployment concepts

DATABASE: SSISDB, BookstoreETL
============================================================================
*/

USE BookstoreETL;
GO

-- ============================================================================
-- PART 1: PACKAGE PARAMETERS
-- ============================================================================
/*
PACKAGE PARAMETERS provide configuration flexibility:

TYPES:
1. Package Parameters:
   - Defined at package level
   - Specific to one package
   - Can be overridden at execution

2. Project Parameters:
   - Defined at project level
   - Shared across all packages
   - Centralized configuration

PARAMETER PROPERTIES:
- Name: Parameter name
- Data Type: String, Int32, Boolean, DateTime, etc.
- Required: Must have value (Yes/No)
- Sensitive: Encrypted storage (Yes/No)
- Value: Default value
- Description: Documentation

ACCESSING PARAMETERS:
- Expressions: @[$Package::ParameterName]
- Project: @[$Project::ParameterName]
- System: @[System::PackageName]

BENEFITS:
- Environment-specific configuration
- No code changes between DEV/TEST/PROD
- Centralized management
- Encrypted sensitive data
*/

-- Create configuration tracking table
CREATE TABLE Package_Configuration (
    ConfigID INT IDENTITY(1,1) PRIMARY KEY,
    Environment NVARCHAR(50),
    ParameterName NVARCHAR(255),
    ParameterValue NVARCHAR(MAX),
    ParameterType NVARCHAR(50),
    IsSensitive BIT,
    LastModified DATETIME DEFAULT GETDATE(),
    ModifiedBy NVARCHAR(100) DEFAULT SUSER_SNAME()
);

-- Insert sample configuration
INSERT INTO Package_Configuration (Environment, ParameterName, ParameterValue, ParameterType, IsSensitive)
VALUES
    ('DEV', 'SourceServer', 'DEV-SQL01', 'String', 0),
    ('DEV', 'SourceDatabase', 'BookstoreDB_Dev', 'String', 0),
    ('DEV', 'TargetDatabase', 'BookstoreETL_Dev', 'String', 0),
    ('DEV', 'BatchSize', '1000', 'Int32', 0),
    ('DEV', 'EmailRecipients', 'dev-team@company.com', 'String', 0),
    ('DEV', 'ConnectionPassword', '***ENCRYPTED***', 'String', 1),
    
    ('TEST', 'SourceServer', 'TEST-SQL01', 'String', 0),
    ('TEST', 'SourceDatabase', 'BookstoreDB_Test', 'String', 0),
    ('TEST', 'TargetDatabase', 'BookstoreETL_Test', 'String', 0),
    ('TEST', 'BatchSize', '5000', 'Int32', 0),
    ('TEST', 'EmailRecipients', 'test-team@company.com', 'String', 0),
    ('TEST', 'ConnectionPassword', '***ENCRYPTED***', 'String', 1),
    
    ('PROD', 'SourceServer', 'PROD-SQL01', 'String', 0),
    ('PROD', 'SourceDatabase', 'BookstoreDB', 'String', 0),
    ('PROD', 'TargetDatabase', 'BookstoreETL', 'String', 0),
    ('PROD', 'BatchSize', '10000', 'Int32', 0),
    ('PROD', 'EmailRecipients', 'etl-ops@company.com;manager@company.com', 'String', 0),
    ('PROD', 'ConnectionPassword', '***ENCRYPTED***', 'String', 1);

SELECT * FROM Package_Configuration WHERE Environment = 'PROD';

/*
CREATING PACKAGE PARAMETERS:

1. IN VISUAL STUDIO:
   - Open package (.dtsx file)
   - Click "Parameters" tab
   - Click "Add Parameter" icon
   - Configure parameter properties

2. PROJECT PARAMETERS:
   - Right-click Project in Solution Explorer
   - Select "Project.params"
   - Add parameters

EXAMPLE PARAMETERS FOR ETL PACKAGE:

PACKAGE PARAMETERS:
Name                | Data Type | Required | Sensitive | Default Value
--------------------|-----------|----------|-----------|----------------
TableName           | String    | Yes      | No        | Customers
IncrementalLoad     | Boolean   | Yes      | No        | True
BatchSize           | Int32     | Yes      | No        | 5000

PROJECT PARAMETERS:
Name                | Data Type | Required | Sensitive | Default Value
--------------------|-----------|----------|-----------|----------------
SourceServer        | String    | Yes      | No        | localhost
SourceDatabase      | String    | Yes      | No        | BookstoreDB
TargetServer        | String    | Yes      | No        | localhost
TargetDatabase      | String    | Yes      | No        | BookstoreETL
EmailServer         | String    | Yes      | No        | smtp.company.com
EmailRecipients     | String    | Yes      | No        | etl@company.com
ConnectionPassword  | String    | Yes      | Yes       | (empty)

USING PARAMETERS IN PACKAGES:

1. CONNECTION STRINGS:
   - Edit Connection Manager
   - Right-click → Properties → Expressions
   - Property: ConnectionString
   - Expression: "Data Source=" + @[$Project::SourceServer] + 
                 ";Initial Catalog=" + @[$Project::SourceDatabase] +
                 ";Provider=SQLNCLI11;Integrated Security=SSPI;"

2. SQL STATEMENTS:
   - Execute SQL Task
   - SQL Source Type: Variable
   - Variable contains: "SELECT * FROM " + @[$Package::TableName]

3. FILE PATHS:
   - File Connection Manager
   - Expression on ConnectionString property
   - "C:\\ETL\\Files\\" + @[$Package::TableName] + "_" + 
     (DT_WSTR, 8) YEAR(GETDATE()) * 10000 + MONTH(GETDATE()) * 100 + DAY(GETDATE()) + ".csv"
*/

-- ============================================================================
-- PART 2: EXPRESSIONS AND PROPERTY EXPRESSIONS
-- ============================================================================
/*
EXPRESSIONS make packages dynamic:

COMMON USES:
- Dynamic connection strings
- Dynamic file names
- Dynamic SQL statements
- Conditional execution
- Runtime configuration

EXPRESSION BUILDER:
- Available in most task/component properties
- Right-click component → Properties → Expressions
- Select property to make dynamic
- Build expression with variables and parameters

EXAMPLES:
*/

-- Create table for expression examples
CREATE TABLE Expression_Examples (
    ExampleID INT IDENTITY(1,1) PRIMARY KEY,
    PropertyName NVARCHAR(100),
    ExpressionExample NVARCHAR(MAX),
    Description NVARCHAR(MAX)
);

INSERT INTO Expression_Examples (PropertyName, ExpressionExample, Description)
VALUES
    ('ConnectionString', 
     '"Data Source=" + @[$Project::ServerName] + ";Initial Catalog=" + @[$Project::DatabaseName] + ";Integrated Security=SSPI;"',
     'Dynamic connection string using project parameters'),
    
    ('FileName',
     '"C:\\ETL\\Archive\\Orders_" + (DT_WSTR, 8) DATEPART("year", GETDATE()) * 10000 + DATEPART("month", GETDATE()) * 100 + DATEPART("day", GETDATE()) + ".csv"',
     'Dynamic file name with current date (YYYYMMDD)'),
    
    ('SqlStatementSource',
     '"SELECT * FROM " + @[$Package::TableName] + " WHERE ModifiedDate > ''" + (DT_WSTR, 23) @[$Package::LastRunDate] + "''"',
     'Dynamic SQL with table name and date parameter'),
    
    ('Disable',
     '@[$Project::Environment] == "DEV" ? FALSE : TRUE',
     'Conditionally disable task based on environment'),
    
    ('DelayValidation',
     '@[$Package::DynamicObjects] == TRUE ? TRUE : FALSE',
     'Delay validation when using dynamic objects'),
    
    ('FolderPath',
     '@[$Project::RootPath] + "\\" + @[$Package::ProcessDate] + "\\" + @[$Package::Category]',
     'Build folder path from multiple parameters');

SELECT * FROM Expression_Examples;

/*
SETTING EXPRESSIONS:

1. VISUAL STUDIO:
   - Right-click task/component → Properties
   - Find "Expressions" property
   - Click [...] button
   - Select property from dropdown
   - Build expression
   - Click "Evaluate Expression" to test

2. COMMON PROPERTIES TO MAKE DYNAMIC:
   - Connection Manager: ConnectionString
   - File Connection: ConnectionString
   - Execute SQL Task: SqlStatementSource
   - Send Mail Task: MessageSource, Subject
   - Task: Disable (to skip in certain environments)
   - For Loop: EvalExpression, InitExpression

EXPRESSION FUNCTIONS:
- String: UPPER, LOWER, SUBSTRING, LEN, TRIM, REPLACE, FINDSTRING
- Date: DATEPART, DATEADD, DATEDIFF, GETDATE, YEAR, MONTH, DAY
- Math: ABS, ROUND, CEILING, FLOOR, SQRT, POWER
- Conversion: (DT_WSTR, length), (DT_I4), (DT_DBTIMESTAMP)
- Conditional: condition ? true_value : false_value
- Null: ISNULL(column, default_value)
*/

-- ============================================================================
-- PART 3: SSISDB CATALOG AND ENVIRONMENTS
-- ============================================================================
/*
SSISDB CATALOG is the deployment target for SSIS projects:

FEATURES:
- Centralized package storage
- Environment-based configuration
- Built-in logging and reporting
- Version control
- Role-based security
- Execution history

ENVIRONMENTS:
- Named configuration sets
- Contain environment variables
- Map to project/package parameters
- Separate DEV/TEST/PROD configurations

ENABLING SSISDB CATALOG:
1. Connect to SQL Server in SSMS
2. Right-click "Integration Services Catalogs"
3. Select "Create Catalog"
4. Set catalog password (for encryption)
5. Enable CLR Integration (required)
*/

-- Check if SSISDB exists
IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    PRINT 'SSISDB Catalog exists and is ready for deployment';
END
ELSE
BEGIN
    PRINT 'SSISDB Catalog not found. Please create it:';
    PRINT '1. Connect to SQL Server in SSMS';
    PRINT '2. Right-click "Integration Services Catalogs"';
    PRINT '3. Select "Create Catalog"';
    PRINT '4. Set password and enable CLR';
END;

-- Query SSISDB catalog information
IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    USE SSISDB;
    
    -- List all folders
    SELECT 
        folder_id,
        name AS FolderName,
        description,
        created_time,
        created_by
    FROM catalog.folders
    ORDER BY name;
    
    -- List all projects
    SELECT 
        f.name AS FolderName,
        p.name AS ProjectName,
        p.description AS ProjectDescription,
        p.deployed_by_name AS DeployedBy,
        p.last_deployed_time AS DeployedDate,
        p.project_format_version AS Version
    FROM catalog.projects p
    INNER JOIN catalog.folders f ON p.folder_id = f.folder_id
    ORDER BY f.name, p.name;
    
    -- List all environments
    SELECT 
        f.name AS FolderName,
        e.name AS EnvironmentName,
        e.description AS Description,
        e.created_time AS CreatedDate,
        e.created_by AS CreatedBy
    FROM catalog.environments e
    INNER JOIN catalog.folders f ON e.folder_id = f.folder_id
    ORDER BY f.name, e.name;
    
    -- List environment variables
    SELECT 
        f.name AS FolderName,
        e.name AS EnvironmentName,
        ev.variable_name AS VariableName,
        ev.type AS DataType,
        ev.sensitive AS IsSensitive,
        CASE WHEN ev.sensitive = 1 THEN '***ENCRYPTED***' ELSE CAST(ev.value AS NVARCHAR(MAX)) END AS Value,
        ev.description AS Description
    FROM catalog.environment_variables ev
    INNER JOIN catalog.environments e ON ev.environment_id = e.environment_id
    INNER JOIN catalog.folders f ON e.folder_id = f.folder_id
    ORDER BY f.name, e.name, ev.variable_name;
END;

/*
CREATING ENVIRONMENTS IN SSISDB:

1. IN SSMS:
   - Connect to Integration Services
   - Navigate to SSISDB → Folders → Your Folder
   - Right-click "Environments" → Create Environment
   - Name: DEV, TEST, PROD
   - Description: Environment-specific configuration

2. ADD ENVIRONMENT VARIABLES:
   - Right-click Environment → Properties
   - Select "Variables" page
   - Add variables matching your project parameters:
     * Name: SourceServer
     * Type: String
     * Value: DEV-SQL01
     * Sensitive: No
     * Description: Source SQL Server instance
   
   - Repeat for all configuration values

3. CREATE ENVIRONMENT REFERENCE:
   - Right-click deployed project → Configure
   - Select "References" tab
   - Click "Add" to add environment reference
   - Select environment (DEV, TEST, or PROD)
   - Click OK

4. MAP ENVIRONMENT VARIABLES TO PARAMETERS:
   - In Configure dialog → "Parameters" tab
   - For each parameter, click "..." in Value column
   - Select "Use environment variable"
   - Choose corresponding environment variable
   - Click OK
*/

-- Script to create environments programmatically
IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    USE SSISDB;
    
    -- Declare variables
    DECLARE @folder_name NVARCHAR(128) = 'BookstoreETL';
    DECLARE @folder_id BIGINT;
    DECLARE @environment_name NVARCHAR(128);
    DECLARE @environment_id BIGINT;
    
    -- Create folder if not exists
    IF NOT EXISTS (SELECT 1 FROM catalog.folders WHERE name = @folder_name)
    BEGIN
        EXEC catalog.create_folder 
            @folder_name = @folder_name,
            @folder_id = @folder_id OUTPUT;
        PRINT 'Created folder: ' + @folder_name;
    END
    ELSE
    BEGIN
        SELECT @folder_id = folder_id FROM catalog.folders WHERE name = @folder_name;
        PRINT 'Using existing folder: ' + @folder_name;
    END;
    
    -- Create DEV environment
    SET @environment_name = 'DEV';
    IF NOT EXISTS (SELECT 1 FROM catalog.environments WHERE folder_id = @folder_id AND name = @environment_name)
    BEGIN
        EXEC catalog.create_environment
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @environment_description = 'Development Environment Configuration',
            @environment_id = @environment_id OUTPUT;
        
        -- Add environment variables for DEV
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'SourceServer',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'DEV-SQL01',
            @description = 'Source SQL Server';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'SourceDatabase',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'BookstoreDB_Dev',
            @description = 'Source Database';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'TargetDatabase',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'BookstoreETL_Dev',
            @description = 'Target Database';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'BatchSize',
            @data_type = 'Int32',
            @sensitive = 0,
            @value = 1000,
            @description = 'Batch size for data loads';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'EmailRecipients',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'dev-team@company.com',
            @description = 'Email notification recipients';
        
        PRINT 'Created DEV environment with variables';
    END;
    
    -- Create TEST environment
    SET @environment_name = 'TEST';
    IF NOT EXISTS (SELECT 1 FROM catalog.environments WHERE folder_id = @folder_id AND name = @environment_name)
    BEGIN
        EXEC catalog.create_environment
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @environment_description = 'Test Environment Configuration',
            @environment_id = @environment_id OUTPUT;
        
        -- Add environment variables for TEST (similar to DEV but with TEST values)
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'SourceServer',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'TEST-SQL01',
            @description = 'Source SQL Server';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'SourceDatabase',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'BookstoreDB_Test',
            @description = 'Source Database';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'TargetDatabase',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'BookstoreETL_Test',
            @description = 'Target Database';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'BatchSize',
            @data_type = 'Int32',
            @sensitive = 0,
            @value = 5000,
            @description = 'Batch size for data loads';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'EmailRecipients',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'test-team@company.com',
            @description = 'Email notification recipients';
        
        PRINT 'Created TEST environment with variables';
    END;
    
    -- Create PROD environment
    SET @environment_name = 'PROD';
    IF NOT EXISTS (SELECT 1 FROM catalog.environments WHERE folder_id = @folder_id AND name = @environment_name)
    BEGIN
        EXEC catalog.create_environment
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @environment_description = 'Production Environment Configuration',
            @environment_id = @environment_id OUTPUT;
        
        -- Add environment variables for PROD
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'SourceServer',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'PROD-SQL01',
            @description = 'Source SQL Server';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'SourceDatabase',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'BookstoreDB',
            @description = 'Source Database';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'TargetDatabase',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'BookstoreETL',
            @description = 'Target Database';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'BatchSize',
            @data_type = 'Int32',
            @sensitive = 0,
            @value = 10000,
            @description = 'Batch size for data loads';
        
        EXEC catalog.create_environment_variable 
            @folder_name = @folder_name,
            @environment_name = @environment_name,
            @variable_name = 'EmailRecipients',
            @data_type = 'String',
            @sensitive = 0,
            @value = 'etl-ops@company.com;manager@company.com',
            @description = 'Email notification recipients';
        
        PRINT 'Created PROD environment with variables';
    END;
END;

-- ============================================================================
-- PART 4: PROJECT DEPLOYMENT
-- ============================================================================
/*
DEPLOYMENT METHODS:

1. DEPLOYMENT WIZARD (Visual Studio):
   - Build solution (Build → Build Solution)
   - Generates .ispac file in bin\Development folder
   - Right-click project → Deploy
   - Follow wizard steps:
     * Select destination server
     * Select or create folder
     * Review and deploy

2. DEPLOYMENT WIZARD (SSMS):
   - Right-click SSISDB folder → Deploy Project
   - Browse to .ispac file
   - Follow wizard steps

3. PowerShell DEPLOYMENT:
   - Use Integration Services PowerShell cmdlets
   - Scriptable and automatable

4. COMMAND-LINE DEPLOYMENT:
   - Use ISDeploymentWizard.exe
   - Batch file deployment
*/

-- PowerShell deployment script (save as Deploy-SSIS.ps1)
/*
# PowerShell Script: Deploy-SSIS.ps1

param(
    [string]$IspacFile = "C:\Projects\BookstoreETL\bin\Development\BookstoreETL.ispac",
    [string]$ServerName = "localhost",
    [string]$FolderName = "BookstoreETL",
    [string]$ProjectName = "BookstoreETL"
)

# Load SSIS assembly
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null

# Connect to Integration Services
$connectionString = "Data Source=$ServerName;Initial Catalog=SSISDB;Integrated Security=SSPI;"
$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$integrationServices = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices $connection

# Get catalog
$catalog = $integrationServices.Catalogs["SSISDB"]

# Create folder if not exists
$folder = $catalog.Folders[$FolderName]
if (!$folder) {
    Write-Host "Creating folder: $FolderName"
    $folder = New-Object Microsoft.SqlServer.Management.IntegrationServices.CatalogFolder($catalog, $FolderName, "Deployment folder for $ProjectName")
    $folder.Create()
}

# Deploy project
Write-Host "Deploying project from: $IspacFile"
[byte[]]$projectFile = [System.IO.File]::ReadAllBytes($IspacFile)
$folder.DeployProject($ProjectName, $projectFile)

Write-Host "Deployment completed successfully!"
*/

-- ============================================================================
-- PART 5: EXECUTING PACKAGES
-- ============================================================================
/*
EXECUTION METHODS:

1. SQL SERVER MANAGEMENT STUDIO:
   - Navigate to deployed package
   - Right-click → Execute
   - Configure parameters and connection managers
   - Click OK to execute
   - View execution report

2. T-SQL EXECUTION:
   - Use catalog.create_execution
   - Set parameters with catalog.set_execution_parameter_value
   - Start with catalog.start_execution

3. SQL SERVER AGENT JOB:
   - Create job with SSIS Package step type
   - Select deployed package
   - Configure parameters
   - Set schedule

4. POWERSHELL:
   - Use Integration Services cmdlets
   - Scriptable automation
*/

-- T-SQL package execution script
IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    USE SSISDB;
    
    -- Example: Execute package with T-SQL
    DECLARE @execution_id BIGINT;
    DECLARE @folder_name NVARCHAR(128) = 'BookstoreETL';
    DECLARE @project_name NVARCHAR(128) = 'BookstoreETL';
    DECLARE @package_name NVARCHAR(260) = 'Package.dtsx';
    
    -- Create execution
    EXEC catalog.create_execution
        @folder_name = @folder_name,
        @project_name = @project_name,
        @package_name = @package_name,
        @use32bitruntime = 0,
        @reference_id = NULL,  -- Or specify environment reference
        @execution_id = @execution_id OUTPUT;
    
    PRINT 'Created execution ID: ' + CAST(@execution_id AS VARCHAR);
    
    -- Set parameter values (override defaults)
    EXEC catalog.set_execution_parameter_value
        @execution_id = @execution_id,
        @object_type = 50,  -- Package parameter
        @parameter_name = N'BatchSize',
        @parameter_value = 5000;
    
    -- Set logging level
    EXEC catalog.set_execution_parameter_value
        @execution_id = @execution_id,
        @object_type = 50,
        @parameter_name = N'LOGGING_LEVEL',
        @parameter_value = 3;  -- Verbose
    
    -- Start execution (synchronous)
    EXEC catalog.start_execution @execution_id;
    
    -- Check execution status
    SELECT 
        execution_id,
        folder_name,
        project_name,
        package_name,
        status,
        start_time,
        end_time,
        DATEDIFF(SECOND, start_time, end_time) AS duration_seconds
    FROM catalog.executions
    WHERE execution_id = @execution_id;
END;

-- ============================================================================
-- PART 6: SQL SERVER AGENT JOB CREATION
-- ============================================================================
/*
SCHEDULING PACKAGES WITH SQL SERVER AGENT:

STEPS:
1. Create Job
2. Add SSIS Package Step
3. Configure Package Source (SSISDB)
4. Set Parameters
5. Configure Schedule
6. Set Notifications
*/

-- Create SQL Server Agent job for SSIS package
USE msdb;
GO

-- Create job category if not exists
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.syscategories WHERE name = 'ETL' AND category_class = 1)
BEGIN
    EXEC msdb.dbo.sp_add_category
        @class = N'JOB',
        @type = N'LOCAL',
        @name = N'ETL';
END;

-- Create the job
DECLARE @jobId BINARY(16);
DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME;

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'ETL_Daily_Customer_Load')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name = N'ETL_Daily_Customer_Load',
        @enabled = 1,
        @description = N'Daily customer data load from source to warehouse',
        @category_name = N'ETL',
        @owner_login_name = N'sa',
        @job_id = @jobId OUTPUT;

    -- Add job step for SSIS package
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'ETL_Daily_Customer_Load',
        @step_name = N'Execute Customer Load Package',
        @step_id = 1,
        @subsystem = N'SSIS',
        @command = N'/ISSERVER "\"\SSISDB\BookstoreETL\BookstoreETL\PKG_Customer_Load.dtsx\"" /SERVER "\"' + @ServerName + '\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";3 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E',
        @retry_attempts = 3,
        @retry_interval = 5,
        @on_success_action = 1,  -- Quit with success
        @on_fail_action = 2;     -- Quit with failure

    -- Add schedule (daily at 2 AM)
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Daily_2AM',
        @enabled = 1,
        @freq_type = 4,  -- Daily
        @freq_interval = 1,
        @freq_recurrence_factor = 1,
        @active_start_time = 020000;  -- 02:00:00 AM

    EXEC msdb.dbo.sp_attach_schedule
        @job_name = N'ETL_Daily_Customer_Load',
        @schedule_name = N'Daily_2AM';

    -- Add notification on failure
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'ETL_Daily_Customer_Load',
        @operator_name = N'ETL_Operator',
        @notification_method = 1;  -- Email

    -- Add job to server
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'ETL_Daily_Customer_Load',
        @server_name = @ServerName;

    PRINT 'SQL Server Agent job created successfully';
END
ELSE
BEGIN
    PRINT 'Job already exists';
END;

-- Query to view job details
SELECT 
    j.name AS JobName,
    j.enabled AS IsEnabled,
    j.description,
    js.step_name AS StepName,
    js.subsystem,
    js.command,
    s.name AS ScheduleName,
    CASE s.freq_type
        WHEN 1 THEN 'Once'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly'
        WHEN 32 THEN 'Monthly Relative'
    END AS Frequency
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysjobschedules jsc ON j.job_id = jsc.job_id
LEFT JOIN msdb.dbo.sysschedules s ON jsc.schedule_id = s.schedule_id
WHERE j.name = 'ETL_Daily_Customer_Load';

-- ============================================================================
-- PART 7: EXECUTION MONITORING AND REPORTING
-- ============================================================================
/*
MONITORING PACKAGE EXECUTIONS IN SSISDB:

CATALOG VIEWS:
- catalog.executions: Execution instances
- catalog.execution_parameter_values: Parameter values used
- catalog.event_messages: Detailed event log
- catalog.operation_messages: Operation-level messages
- catalog.executable_statistics: Performance statistics
*/

IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    USE SSISDB;
    
    -- Recent package executions
    SELECT TOP 20
        execution_id,
        folder_name,
        project_name,
        package_name,
        CASE status
            WHEN 1 THEN 'Created'
            WHEN 2 THEN 'Running'
            WHEN 3 THEN 'Canceled'
            WHEN 4 THEN 'Failed'
            WHEN 5 THEN 'Pending'
            WHEN 6 THEN 'Ended Unexpectedly'
            WHEN 7 THEN 'Succeeded'
            WHEN 8 THEN 'Stopping'
            WHEN 9 THEN 'Completed'
        END AS Status,
        start_time,
        end_time,
        DATEDIFF(SECOND, start_time, end_time) AS duration_seconds,
        executed_as_name
    FROM catalog.executions
    ORDER BY start_time DESC;
    
    -- Execution parameters used
    SELECT 
        e.execution_id,
        e.package_name,
        epv.parameter_name,
        epv.parameter_value,
        e.start_time
    FROM catalog.execution_parameter_values epv
    INNER JOIN catalog.executions e ON epv.execution_id = e.execution_id
    WHERE e.execution_id = (SELECT MAX(execution_id) FROM catalog.executions)
    ORDER BY epv.parameter_name;
    
    -- Error messages from failed executions
    SELECT 
        e.execution_id,
        e.package_name,
        em.message_time,
        em.message_type,
        em.message_source_name,
        em.message
    FROM catalog.event_messages em
    INNER JOIN catalog.executions e ON em.operation_id = e.execution_id
    WHERE em.message_type IN (120, 130)  -- Error and Warning
        AND e.status = 4  -- Failed
    ORDER BY e.execution_id DESC, em.message_time DESC;
    
    -- Package performance statistics
    SELECT 
        e.execution_id,
        e.package_name,
        es.execution_path,
        es.execution_duration,
        es.execution_result,
        es.start_time,
        es.end_time
    FROM catalog.executable_statistics es
    INNER JOIN catalog.executions e ON es.execution_id = e.execution_id
    WHERE e.execution_id = (SELECT MAX(execution_id) FROM catalog.executions)
    ORDER BY es.start_time;
    
    -- Daily execution summary
    SELECT 
        CAST(start_time AS DATE) AS ExecutionDate,
        COUNT(*) AS TotalExecutions,
        SUM(CASE WHEN status = 7 THEN 1 ELSE 0 END) AS Succeeded,
        SUM(CASE WHEN status = 4 THEN 1 ELSE 0 END) AS Failed,
        SUM(CASE WHEN status IN (2, 5, 8) THEN 1 ELSE 0 END) AS InProgress,
        AVG(DATEDIFF(SECOND, start_time, end_time)) AS AvgDurationSeconds
    FROM catalog.executions
    WHERE start_time >= DATEADD(DAY, -7, GETDATE())
    GROUP BY CAST(start_time AS DATE)
    ORDER BY ExecutionDate DESC;
END;

-- ============================================================================
-- PART 8: PACKAGE VERSIONING
-- ============================================================================
/*
VERSION CONTROL IN SSISDB:

FEATURES:
- Every deployment creates new version
- Previous versions retained
- Can restore previous version
- Version history tracked

OPERATIONS:
- Deploy new version
- View version history
- Restore previous version
- Delete old versions
*/

IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    USE SSISDB;
    
    -- View project versions
    SELECT 
        f.name AS FolderName,
        p.name AS ProjectName,
        v.version_id,
        v.description AS VersionDescription,
        v.created_time,
        v.created_by,
        v.object_version_lsn
    FROM catalog.object_versions v
    INNER JOIN catalog.projects p ON v.object_id = p.project_id
    INNER JOIN catalog.folders f ON p.folder_id = f.folder_id
    ORDER BY f.name, p.name, v.created_time DESC;
    
    -- Restore previous version (example - DO NOT RUN without verification)
    /*
    EXEC catalog.restore_project
        @folder_name = 'BookstoreETL',
        @project_name = 'BookstoreETL',
        @object_version_lsn = 12345;  -- Specific version LSN
    */
END;

-- ============================================================================
-- PART 9: CONFIGURATION BEST PRACTICES
-- ============================================================================
/*
BEST PRACTICES:

1. PARAMETERS:
   - Use project parameters for shared configuration
   - Use package parameters for package-specific settings
   - Document all parameters thoroughly
   - Set appropriate default values
   - Mark sensitive data as Sensitive

2. ENVIRONMENTS:
   - Create separate environment for each deployment stage
   - Use consistent naming (DEV, TEST, UAT, PROD)
   - Store all environment-specific values
   - Don't hardcode connections or paths in packages

3. EXPRESSIONS:
   - Use expressions for dynamic behavior
   - Keep expressions simple and readable
   - Test expressions thoroughly
   - Document complex expressions

4. DEPLOYMENT:
   - Always deploy to SSISDB catalog (not file system)
   - Use deployment wizard or automate with PowerShell
   - Test in lower environments first
   - Maintain deployment scripts

5. SECURITY:
   - Use role-based security in SSISDB
   - Mark passwords and sensitive data as Sensitive
   - Use Windows Authentication when possible
   - Encrypt sensitive data

6. MONITORING:
   - Set appropriate logging level (Verbose in DEV, Basic in PROD)
   - Review execution reports regularly
   - Alert on failures
   - Track performance trends

7. MAINTENANCE:
   - Clean up old execution logs periodically
   - Remove unused package versions
   - Document configuration changes
   - Keep environment variables updated
*/

-- Create configuration checklist table
CREATE TABLE Deployment_Checklist (
    ChecklistID INT IDENTITY(1,1) PRIMARY KEY,
    Category NVARCHAR(50),
    CheckItem NVARCHAR(MAX),
    IsRequired BIT,
    SortOrder INT
);

INSERT INTO Deployment_Checklist (Category, CheckItem, IsRequired, SortOrder)
VALUES
    ('Pre-Deployment', 'All packages build successfully without errors', 1, 1),
    ('Pre-Deployment', 'All parameters documented with descriptions', 1, 2),
    ('Pre-Deployment', 'Connection strings use parameters, not hardcoded', 1, 3),
    ('Pre-Deployment', 'Sensitive parameters marked as Sensitive', 1, 4),
    ('Pre-Deployment', 'Package tested in DEV environment', 1, 5),
    ('Pre-Deployment', 'Change request approved', 1, 6),
    ('Deployment', 'Target environment variables created/updated', 1, 7),
    ('Deployment', 'Project deployed to correct SSISDB folder', 1, 8),
    ('Deployment', 'Environment reference configured', 1, 9),
    ('Deployment', 'Parameter mappings verified', 1, 10),
    ('Deployment', 'Package executed successfully in target', 1, 11),
    ('Post-Deployment', 'SQL Server Agent job created/updated', 1, 12),
    ('Post-Deployment', 'Job schedule configured correctly', 1, 13),
    ('Post-Deployment', 'Email notifications configured', 1, 14),
    ('Post-Deployment', 'Execution logs reviewed', 1, 15),
    ('Post-Deployment', 'Runbook/documentation updated', 1, 16);

SELECT * FROM Deployment_Checklist ORDER BY SortOrder;

-- ============================================================================
-- PART 10: TROUBLESHOOTING DEPLOYMENT ISSUES
-- ============================================================================
/*
COMMON DEPLOYMENT ISSUES:

1. SSISDB CATALOG NOT FOUND:
   - Enable Integration Services feature
   - Create SSISDB catalog
   - Enable CLR integration

2. PERMISSION DENIED:
   - Grant ssis_admin role to deployment account
   - Verify folder permissions
   - Check SQL Server instance permissions

3. PACKAGE VALIDATION FAILURES:
   - Set DelayValidation = True for dynamic objects
   - Verify connection managers exist in target
   - Check parameter data types

4. CONNECTION FAILURES:
   - Verify connection strings in environment
   - Test connections from SQL Server Agent service account
   - Check firewall rules
   - Verify SQL Server authentication mode

5. PARAMETER NOT FOUND:
   - Ensure parameter exists in package
   - Verify parameter name spelling
   - Check parameter scope (Package vs Project)

6. EXECUTION TIMEOUTS:
   - Increase command timeout settings
   - Optimize package performance
   - Check for blocking/deadlocks
   - Review data volumes
*/

-- Query for troubleshooting
IF DB_ID('SSISDB') IS NOT NULL
BEGIN
    USE SSISDB;
    
    -- Recent errors
    SELECT TOP 20
        em.operation_id AS ExecutionID,
        e.package_name AS PackageName,
        em.message_time AS ErrorTime,
        em.message_source_name AS ErrorSource,
        em.message AS ErrorMessage,
        em.extended_info_id
    FROM catalog.event_messages em
    INNER JOIN catalog.executions e ON em.operation_id = e.execution_id
    WHERE em.message_type = 120  -- Error
    ORDER BY em.message_time DESC;
    
    -- Validation errors
    SELECT 
        ev.validation_id,
        ev.environment_folder_name,
        ev.environment_name,
        ev.project_name,
        em.message_time,
        em.message
    FROM catalog.validations ev
    INNER JOIN catalog.event_messages em ON ev.validation_id = em.operation_id
    WHERE em.message_type = 120
    ORDER BY em.message_time DESC;
END;

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Created package and project parameters
□ Configured property expressions for dynamic behavior
□ Set up SSISDB catalog environments (DEV/TEST/PROD)
□ Created environment variables and mapped to parameters
□ Deployed package to SSISDB catalog
□ Executed package with different environment configurations
□ Created SQL Server Agent job with schedule
□ Monitored package executions and reviewed logs
□ Implemented deployment best practices
□ Troubleshot common deployment issues

NEXT LAB: Lab 59 - Error Handling, Logging & Performance Tuning
============================================================================
*/
