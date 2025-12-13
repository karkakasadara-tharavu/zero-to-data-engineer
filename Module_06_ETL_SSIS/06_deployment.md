# SSIS Deployment - Complete Guide

## 📚 What You'll Learn
- Deployment models (Package vs Project)
- Package deployment to file system
- Project deployment to SSISDB
- Configuration management
- Environment setup
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Deployment Models Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSIS DEPLOYMENT MODELS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ PACKAGE DEPLOYMENT MODEL (Legacy)                                │   │
│   │ ├── Individual .dtsx files deployed                             │   │
│   │ ├── Deploy to MSDB database or File System                      │   │
│   │ ├── Configurations in XML or SQL Server                         │   │
│   │ ├── Each package deployed separately                            │   │
│   │ └── Used in SQL Server 2005, 2008, 2008 R2                      │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ PROJECT DEPLOYMENT MODEL (Recommended)                          │   │
│   │ ├── Entire project deployed as .ispac file                     │   │
│   │ ├── Deploy to SSISDB (Integration Services Catalog)            │   │
│   │ ├── Parameters and environments for configuration              │   │
│   │ ├── All packages deployed together                             │   │
│   │ ├── Built-in logging, versioning, permissions                  │   │
│   │ └── Default in SQL Server 2012+                                │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Package Deployment Model (Legacy)

### Deployment Options

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PACKAGE DEPLOYMENT OPTIONS                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. FILE SYSTEM                                                         │
│      └── Deploy .dtsx files to network folder                           │
│      └── Execute via dtexec.exe or SQL Agent                            │
│                                                                          │
│   2. MSDB DATABASE                                                       │
│      └── Store packages in msdb.dbo.sysssispackages                     │
│      └── Manage via SSMS (Integration Services)                         │
│                                                                          │
│   3. SSIS PACKAGE STORE                                                  │
│      └── Managed by Integration Services service                        │
│      └── Maps to file system or MSDB                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Package Configurations (Legacy)

```
Configuration Types:
├── XML Configuration File
│   └── Store connection strings, variables in XML
│
├── Environment Variable
│   └── Windows environment variable → package variable
│
├── Registry Entry
│   └── Windows registry → package variable
│
├── Parent Package Variable
│   └── Pass values from parent to child package
│
└── SQL Server Table
    └── Store configurations in database table
    
XML Configuration Example:
<?xml version="1.0"?>
<Configuration>
  <ConfigurationType>Property</ConfigurationType>
  <PackagePath>\Package.Connections[SQLConn].Properties[ConnectionString]</PackagePath>
  <ConfiguredValue>Server=PROD;Database=DW;Integrated Security=SSPI</ConfiguredValue>
</Configuration>
```

---

## 🚀 Project Deployment Model (Recommended)

### SSISDB Catalog Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSISDB CATALOG HIERARCHY                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Integration Services Catalogs                                          │
│   └── SSISDB                                                            │
│       ├── Folders                                                       │
│       │   ├── Folder_Dev                                               │
│       │   │   ├── Projects                                             │
│       │   │   │   └── ETL_Project                                      │
│       │   │   │       ├── Packages                                     │
│       │   │   │       │   ├── Load_Customers.dtsx                     │
│       │   │   │       │   ├── Load_Orders.dtsx                        │
│       │   │   │       │   └── Load_Products.dtsx                      │
│       │   │   │       └── Parameters                                   │
│       │   │   │           ├── ServerName                               │
│       │   │   │           └── DatabaseName                             │
│       │   │   └── Environments                                         │
│       │   │       ├── Dev                                              │
│       │   │       ├── QA                                               │
│       │   │       └── Prod                                             │
│       │   └── Folder_Prod                                              │
│       │       └── ...                                                  │
│       └── ...                                                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Creating SSISDB Catalog

```sql
-- Enable CLR Integration (required)
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;

-- Create Catalog (via SSMS or T-SQL)
-- Right-click "Integration Services Catalogs" → "Create Catalog"
-- Or use T-SQL:
CREATE CATALOG SSISDB WITH PASSWORD = 'StrongPassword123!';

-- The catalog:
-- ├── Creates SSISDB database
-- ├── Sets up encryption
-- ├── Creates system stored procedures
-- └── Enables catalog logging
```

### Building and Deploying Projects

```
Method 1: Visual Studio Deployment Wizard
1. Right-click project → Deploy
2. Select destination server
3. Choose/Create folder
4. Deploy project

Method 2: ISPAC File Deployment
1. Build project (creates .ispac in bin folder)
2. Copy .ispac to target server
3. Deploy via:
   - SSMS: Right-click folder → Deploy Project
   - PowerShell: ISDeploymentWizard.exe
   - T-SQL stored procedures

Method 3: T-SQL Deployment
DECLARE @ProjectBinary VARBINARY(MAX);
DECLARE @OperationId BIGINT;

-- Read .ispac file
SELECT @ProjectBinary = BulkColumn
FROM OPENROWSET(BULK 'C:\Deploy\MyProject.ispac', SINGLE_BLOB) AS BinaryData;

-- Deploy project
EXEC catalog.deploy_project 
    @folder_name = 'ETL',
    @project_name = 'MyProject',
    @project_stream = @ProjectBinary,
    @operation_id = @OperationId OUTPUT;
```

---

## ⚙️ Parameters and Environments

### Parameters

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSIS PARAMETERS                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Project Parameters (Project.params):                                   │
│   ├── Available to all packages in project                              │
│   ├── Common: Connection strings, file paths, email addresses          │
│   └── Set at project level, used everywhere                             │
│                                                                          │
│   Package Parameters:                                                    │
│   ├── Specific to one package                                           │
│   ├── Override from execution                                           │
│   └── Local scope only                                                   │
│                                                                          │
│   Parameter Properties:                                                  │
│   ├── Name: Unique identifier                                           │
│   ├── Data Type: String, Int32, Boolean, etc.                          │
│   ├── Value: Default value                                              │
│   ├── Sensitive: Encrypt value (passwords)                             │
│   └── Required: Must provide at execution                               │
│                                                                          │
│   Example Project Parameters:                                            │
│   ├── Conn_Source_Server (String)                                       │
│   ├── Conn_Target_Server (String)                                       │
│   ├── File_Input_Path (String)                                          │
│   ├── File_Output_Path (String)                                         │
│   ├── Email_Recipients (String)                                         │
│   └── Debug_Mode (Boolean)                                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Environments

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ENVIRONMENT CONFIGURATION                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Purpose:                                                               │
│   ├── Store server-specific values                                      │
│   ├── Switch configurations without changing package                    │
│   └── Separate Dev, QA, Prod settings                                   │
│                                                                          │
│   Environment Variables:                                                 │
│   ┌────────────────────────────────────────────────────────────────┐    │
│   │ Environment: PROD                                               │    │
│   ├────────────────────────────────────────────────────────────────┤    │
│   │ Variable          │ Type    │ Value                            │    │
│   ├───────────────────┼─────────┼──────────────────────────────────┤    │
│   │ SourceServer      │ String  │ PROD-DB-01                       │    │
│   │ TargetServer      │ String  │ PROD-DW-01                       │    │
│   │ InputPath         │ String  │ \\PROD\files\input               │    │
│   │ OutputPath        │ String  │ \\PROD\files\output              │    │
│   │ ConnectionString  │ String  │ Server=PROD;Database=DW;...      │    │
│   │ Password          │ String  │ ********** (Sensitive)           │    │
│   └───────────────────┴─────────┴──────────────────────────────────┘    │
│                                                                          │
│   Environment Reference:                                                 │
│   Project → Configure → References → Add Environment                    │
│   Then map parameters to environment variables                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### T-SQL Environment Setup

```sql
-- Create folder
EXEC catalog.create_folder @folder_name = 'ETL';

-- Create environment
EXEC catalog.create_environment 
    @folder_name = 'ETL',
    @environment_name = 'Prod';

-- Add environment variables
EXEC catalog.create_environment_variable
    @folder_name = 'ETL',
    @environment_name = 'Prod',
    @variable_name = 'SourceServer',
    @data_type = 'String',
    @sensitive = 0,
    @value = 'PROD-DB-01';

EXEC catalog.create_environment_variable
    @folder_name = 'ETL',
    @environment_name = 'Prod',
    @variable_name = 'Password',
    @data_type = 'String',
    @sensitive = 1, -- Encrypted
    @value = 'SecretPassword123';

-- Reference environment from project
EXEC catalog.create_environment_reference
    @folder_name = 'ETL',
    @project_name = 'MyProject',
    @environment_name = 'Prod',
    @reference_type = 'R'; -- R=Relative (same folder), A=Absolute

-- Map parameter to environment variable
EXEC catalog.set_object_parameter_value
    @object_type = 20, -- Project
    @folder_name = 'ETL',
    @project_name = 'MyProject',
    @parameter_name = 'SourceServer',
    @parameter_value = 'SourceServer',
    @value_type = 'R'; -- R=Referenced, V=Value
```

---

## 🏃 Executing Packages

### SSMS Execution

```
1. Navigate to SSISDB → Folder → Projects → Project
2. Right-click package → Execute
3. Configure:
   - Parameters (override defaults)
   - Connection Managers
   - Advanced (32/64 bit, logging level)
   - Environment Reference (select environment)
4. Click OK to execute
5. View Execution Reports
```

### T-SQL Execution

```sql
-- Simple execution
DECLARE @execution_id BIGINT;

EXEC catalog.create_execution
    @folder_name = 'ETL',
    @project_name = 'MyProject',
    @package_name = 'Load_Customers.dtsx',
    @execution_id = @execution_id OUTPUT;

EXEC catalog.start_execution @execution_id;

-- Execution with environment
EXEC catalog.create_execution
    @folder_name = 'ETL',
    @project_name = 'MyProject',
    @package_name = 'Load_Customers.dtsx',
    @reference_id = NULL, -- or environment reference ID
    @use32bitruntime = 0,
    @execution_id = @execution_id OUTPUT;

-- Set parameter value for this execution
EXEC catalog.set_execution_parameter_value
    @execution_id = @execution_id,
    @object_type = 30, -- Package parameter
    @parameter_name = 'ProcessDate',
    @parameter_value = '2024-01-15';

-- Set logging level
EXEC catalog.set_execution_parameter_value
    @execution_id = @execution_id,
    @object_type = 50, -- System
    @parameter_name = 'LOGGING_LEVEL',
    @parameter_value = 3; -- Verbose

EXEC catalog.start_execution @execution_id;
```

### SQL Server Agent Execution

```
1. Create new SQL Agent Job
2. Add Step:
   - Type: SQL Server Integration Services Package
   - Package source: SSIS Catalog
   - Server: localhost
   - Path: \SSISDB\ETL\MyProject\Load_Customers.dtsx
3. Configuration Tab:
   - Select Environment Reference
   - Override parameters if needed
4. Schedule Job
```

### Command Line Execution (dtexec)

```powershell
# Package Deployment Model
dtexec /FILE "C:\Packages\MyPackage.dtsx" /CONFIG "C:\Config\prod.dtsConfig"

# Project Deployment Model
dtexec /ISServer "\SSISDB\ETL\MyProject\Load_Customers.dtsx" `
       /Server "localhost" `
       /Env "Prod" `
       /Par "$Project::SourceServer";"PROD-DB-01"

# Common options
# /Rep V,E,W,I  - Reporting (Verbose, Error, Warning, Info)
# /Set          - Set property value
# /Decrypt      - Package password
# /Dump         - Create dump on error
```

---

## 📊 Monitoring and Reports

### Execution Reports

```sql
-- All executions
SELECT 
    e.execution_id,
    e.folder_name,
    e.project_name,
    e.package_name,
    e.environment_name,
    e.status,
    CASE e.status
        WHEN 1 THEN 'Created'
        WHEN 2 THEN 'Running'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'Failed'
        WHEN 5 THEN 'Pending'
        WHEN 6 THEN 'Ended Unexpectedly'
        WHEN 7 THEN 'Succeeded'
        WHEN 8 THEN 'Stopping'
        WHEN 9 THEN 'Completed'
    END AS status_description,
    e.start_time,
    e.end_time,
    DATEDIFF(SECOND, e.start_time, e.end_time) AS duration_seconds
FROM catalog.executions e
ORDER BY e.start_time DESC;

-- Execution messages (errors and warnings)
SELECT 
    em.message_time,
    em.message_type,
    CASE em.message_type
        WHEN -1 THEN 'Unknown'
        WHEN 120 THEN 'Error'
        WHEN 110 THEN 'Warning'
        WHEN 70 THEN 'Information'
        WHEN 10 THEN 'Pre-validate'
        WHEN 20 THEN 'Post-validate'
        WHEN 30 THEN 'Pre-execute'
        WHEN 40 THEN 'Post-execute'
        WHEN 60 THEN 'Progress'
    END AS message_type_desc,
    em.message,
    em.message_source_name
FROM catalog.event_messages em
WHERE em.operation_id = @execution_id
  AND em.message_type IN (120, 110) -- Errors and Warnings
ORDER BY em.message_time;

-- Execution statistics
SELECT 
    es.execution_id,
    es.execution_path,
    es.statistics_id,
    es.start_time,
    es.end_time,
    es.execution_result,
    CASE es.execution_result
        WHEN 0 THEN 'Success'
        WHEN 1 THEN 'Failure'
        WHEN 2 THEN 'Completion'
        WHEN 3 THEN 'Cancelled'
    END AS result_description
FROM catalog.execution_data_statistics es
WHERE es.execution_id = @execution_id;
```

---

## 🔐 Security

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSISDB SECURITY                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Database Roles:                                                        │
│   ├── ssis_admin: Full control of catalog                              │
│   ├── ssis_logreader: Read execution logs                              │
│   └── db_owner: Full database access                                    │
│                                                                          │
│   Object Permissions:                                                    │
│   ├── Folder Level:                                                     │
│   │   ├── READ: View folder, projects, environments                    │
│   │   ├── MODIFY: Create/delete projects and environments              │
│   │   └── MANAGE_PERMISSIONS: Grant permissions to others              │
│   │                                                                     │
│   ├── Project Level:                                                    │
│   │   ├── READ: View project properties                                │
│   │   ├── MODIFY: Deploy new versions                                  │
│   │   ├── EXECUTE: Run packages                                        │
│   │   └── MANAGE_PERMISSIONS: Grant permissions                        │
│   │                                                                     │
│   └── Environment Level:                                                │
│       ├── READ: View environment variables                             │
│       ├── MODIFY: Change environment variables                         │
│       └── MANAGE_PERMISSIONS: Grant permissions                        │
│                                                                          │
│   Grant Permissions:                                                     │
│   EXEC catalog.grant_permission                                         │
│       @object_type = 1, -- Folder                                       │
│       @object_id = 1,                                                   │
│       @principal_id = 2,                                                │
│       @permission_type = 2; -- EXECUTE                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🎓 Interview Questions

### Q1: What is the difference between Package and Project Deployment Models?
**A:**
- **Package**: Individual .dtsx files, deployed separately, XML configurations
- **Project**: Entire project as .ispac, deploy to SSISDB, parameters and environments

### Q2: What is SSISDB?
**A:** Integration Services Catalog database for Project Deployment Model. Stores projects, packages, parameters, environments, execution history, and logs.

### Q3: How do you handle different environments (Dev, QA, Prod)?
**A:**
- Create Environments in SSISDB for each
- Define environment variables with server-specific values
- Reference environment at execution time
- Same package works in all environments

### Q4: What are SSIS parameters?
**A:**
- **Project Parameters**: Available to all packages, common settings
- **Package Parameters**: Specific to one package
- Replace package configurations from legacy model

### Q5: How do you deploy an SSIS project?
**A:**
1. Build project (creates .ispac)
2. Deploy via Visual Studio Wizard, SSMS, PowerShell, or T-SQL
3. Configure environment references
4. Map parameters to environment variables

### Q6: How do you execute SSIS packages in SSISDB?
**A:**
- SSMS: Right-click → Execute
- T-SQL: catalog.create_execution + catalog.start_execution
- SQL Agent: SSIS Package step
- Command Line: dtexec with /ISServer

### Q7: What is the catalog.deploy_project stored procedure?
**A:** Deploys .ispac file to SSISDB folder. Takes folder name, project name, and binary stream of .ispac file.

### Q8: How do you handle sensitive data in SSIS?
**A:**
- Mark parameters as Sensitive
- Environment variables can be Sensitive
- Values encrypted in SSISDB
- Encryption key protected by master database key

### Q9: How do you monitor SSIS execution?
**A:**
- Standard Reports in SSMS
- Query catalog.executions and catalog.event_messages
- Execution statistics in catalog.execution_data_statistics
- Built-in logging at Basic, Performance, or Verbose levels

### Q10: What happens when you deploy a new version of a project?
**A:**
- Old version replaced with new
- SSISDB keeps version history (configurable retention)
- Environment references maintained
- Parameter mappings may need review if parameters changed

---

## 🔗 Related Topics
- [← Error Handling](./05_error_handling.md)
- [Performance Optimization →](./07_performance.md)
- [Module 07: Advanced ETL →](../Module_07_Advanced_ETL/)

---

*Next: Learn about SSIS Performance Optimization or continue to Advanced ETL patterns*
