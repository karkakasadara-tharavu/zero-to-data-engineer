/*
============================================================================
LAB 54: SSIS CONTROL FLOW TASKS
Module 06: ETL SSIS Fundamentals
============================================================================

OBJECTIVE:
- Master Execute SQL Task for database operations
- Use File System Task for file operations
- Implement Script Task for custom logic
- Work with Foreach Loop and For Loop containers
- Create precedence constraints and conditional logic

DURATION: 90 minutes
DIFFICULTY: ⭐⭐⭐ (Intermediate-Advanced)

PREREQUISITES:
- Completed Lab 53 (SSIS Introduction)
- Visual Studio with SSDT installed
- BookstoreDB and BookstoreETL databases
- Basic C# or VB.NET knowledge (for Script Task)

DATABASE: BookstoreDB, BookstoreETL
============================================================================
*/

USE BookstoreETL;
GO

-- ============================================================================
-- PART 1: EXECUTE SQL TASK - ADVANCED USAGE
-- ============================================================================
/*
EXECUTE SQL TASK is the most commonly used task in SSIS control flow.
It can execute:
- T-SQL statements
- Stored procedures
- Parameterized queries
- Return single values, result sets, or XML

KEY PROPERTIES:
- Connection: Database connection manager
- SQLSourceType: Direct Input, File Connection, Variable
- SQL Statement: The query to execute
- ResultSet: None, Single Row, Full Result Set, XML
- Parameter Mapping: Map SSIS variables to SQL parameters
*/

-- Create stored procedures for different Execute SQL Task scenarios

-- Procedure with output parameter
CREATE OR ALTER PROCEDURE sp_GetCustomerCount
    @ActiveOnly BIT = 1,
    @CustomerCount INT OUTPUT
AS
BEGIN
    SELECT @CustomerCount = COUNT(*)
    FROM BookstoreDB.dbo.SourceCustomers
    WHERE IsActive = @ActiveOnly OR @ActiveOnly = 0;
END;
GO

-- Procedure that returns a result set
CREATE OR ALTER PROCEDURE sp_GetCustomersByDate
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        Email,
        JoinDate
    FROM BookstoreDB.dbo.SourceCustomers
    WHERE JoinDate BETWEEN @StartDate AND @EndDate
    ORDER BY JoinDate;
END;
GO

-- Procedure that returns single row
CREATE OR ALTER PROCEDURE sp_GetDailySummary
    @SummaryDate DATE
AS
BEGIN
    SELECT 
        @SummaryDate AS SummaryDate,
        COUNT(*) AS TotalCustomers,
        SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS ActiveCustomers,
        MAX(JoinDate) AS LastJoinDate
    FROM BookstoreDB.dbo.SourceCustomers
    WHERE JoinDate = @SummaryDate;
END;
GO

-- Test procedures
DECLARE @Count INT;
EXEC sp_GetCustomerCount @ActiveOnly = 1, @CustomerCount = @Count OUTPUT;
SELECT @Count AS ActiveCustomerCount;

EXEC sp_GetCustomersByDate '2024-01-01', '2024-04-30';
EXEC sp_GetDailySummary '2024-01-15';

/*
EXECUTE SQL TASK CONFIGURATIONS:

1. NONE (No Result Set):
   - Use for: INSERT, UPDATE, DELETE, TRUNCATE
   - Example: TRUNCATE TABLE Staging_Customers;

2. SINGLE ROW:
   - Returns one row with multiple columns
   - Map to variables: ResultSet → Result Name: 0 → Variable Mapping
   - Example: SELECT COUNT(*) AS Cnt, MAX(ID) AS MaxID

3. FULL RESULT SET:
   - Returns multiple rows
   - Store in Object variable
   - Process with Foreach Loop Container
   - Example: SELECT * FROM Customers WHERE Active = 1

4. XML:
   - Returns XML data
   - Store in String variable
   - Use FOR XML clause in query
   - Example: SELECT * FROM Customers FOR XML PATH('Customer'), ROOT('Customers')
*/

-- ============================================================================
-- PART 2: FILE SYSTEM TASK
-- ============================================================================
/*
FILE SYSTEM TASK performs file and directory operations:
- Copy File/Directory
- Move File/Directory
- Delete File/Directory
- Rename File
- Set Attributes
- Create Directory

COMMON USE CASES:
- Archive processed files
- Clean up old log files
- Create timestamped folders
- Move files between stages
- Organize ETL artifacts
*/

-- Create table to track file operations
CREATE TABLE ETL_FileOperations (
    OperationID INT IDENTITY(1,1) PRIMARY KEY,
    OperationType NVARCHAR(50),
    SourcePath NVARCHAR(500),
    DestinationPath NVARCHAR(500),
    OperationDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(50),
    ErrorMessage NVARCHAR(MAX)
);

-- Create procedure to log file operations
CREATE OR ALTER PROCEDURE sp_LogFileOperation
    @OperationType NVARCHAR(50),
    @SourcePath NVARCHAR(500),
    @DestinationPath NVARCHAR(500),
    @Status NVARCHAR(50),
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO ETL_FileOperations (
        OperationType, SourcePath, DestinationPath, 
        Status, ErrorMessage
    )
    VALUES (
        @OperationType, @SourcePath, @DestinationPath,
        @Status, @ErrorMessage
    );
END;
GO

/*
FILE SYSTEM TASK EXAMPLE PACKAGE: "PKG_FileManagement"

TASKS:
1. Create Directory: Create C:\ETL\Archive\YYYYMMDD folder
2. File System Task: Copy source file to archive
3. Execute SQL Task: Log file operation
4. File System Task: Delete original file (if copy succeeded)

VARIABLES NEEDED:
- ArchiveFolder: String = "C:\\ETL\\Archive\\"
- ArchiveDate: String = YEAR(GETDATE()) * 10000 + MONTH(GETDATE()) * 100 + DAY(GETDATE())
- SourceFile: String = "C:\\ETL\\Input\\customers.csv"
- ArchiveFile: String = @[User::ArchiveFolder] + @[User::ArchiveDate] + "\\customers.csv"
*/

-- ============================================================================
-- PART 3: SCRIPT TASK
-- ============================================================================
/*
SCRIPT TASK allows custom .NET code execution within SSIS:
- C# or VB.NET code
- Access to SSIS variables (ReadOnlyVariables, ReadWriteVariables)
- File system operations
- API calls
- Complex business logic
- Custom logging

COMMON SCENARIOS:
- Email notifications
- Complex date calculations
- String manipulations
- API integrations
- Custom validation logic
*/

-- Create table for script task logging
CREATE TABLE ETL_ScriptLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(255),
    ScriptName NVARCHAR(255),
    LogMessage NVARCHAR(MAX),
    LogLevel NVARCHAR(50),
    LogDate DATETIME DEFAULT GETDATE()
);

-- Procedure for script task to call
CREATE OR ALTER PROCEDURE sp_LogScriptExecution
    @PackageName NVARCHAR(255),
    @ScriptName NVARCHAR(255),
    @Message NVARCHAR(MAX),
    @LogLevel NVARCHAR(50) = 'INFO'
AS
BEGIN
    INSERT INTO ETL_ScriptLog (PackageName, ScriptName, LogMessage, LogLevel)
    VALUES (@PackageName, @ScriptName, @Message, @LogLevel);
END;
GO

/*
SCRIPT TASK EXAMPLE CODE (C#):

// ============================================================================
// EXAMPLE 1: Variable Manipulation
// ============================================================================
public void Main()
{
    // Read variables
    int rowCount = (int)Dts.Variables["RowCount"].Value;
    string packageName = Dts.Variables["PackageName"].Value.ToString();
    
    // Perform calculation
    bool isHighVolume = rowCount > 1000;
    
    // Write to variable
    Dts.Variables["IsHighVolume"].Value = isHighVolume;
    
    // Fire information event
    Dts.Events.FireInformation(0, "Script Task", 
        $"Processed {rowCount} rows. High Volume: {isHighVolume}", 
        "", 0, ref fireAgain);
    
    Dts.TaskResult = (int)ScriptResults.Success;
}

// ============================================================================
// EXAMPLE 2: File Operations
// ============================================================================
public void Main()
{
    try
    {
        string sourceFolder = Dts.Variables["SourceFolder"].Value.ToString();
        string archiveFolder = Dts.Variables["ArchiveFolder"].Value.ToString();
        
        // Get all CSV files
        string[] files = Directory.GetFiles(sourceFolder, "*.csv");
        
        // Store count in variable
        Dts.Variables["FileCount"].Value = files.Length;
        
        // Create archive folder if not exists
        if (!Directory.Exists(archiveFolder))
        {
            Directory.CreateDirectory(archiveFolder);
        }
        
        // Process each file
        foreach (string file in files)
        {
            FileInfo fi = new FileInfo(file);
            string archivePath = Path.Combine(archiveFolder, 
                DateTime.Now.ToString("yyyyMMdd") + "_" + fi.Name);
            
            File.Copy(file, archivePath, true);
        }
        
        Dts.TaskResult = (int)ScriptResults.Success;
    }
    catch (Exception ex)
    {
        Dts.Events.FireError(0, "Script Task", ex.Message, "", 0);
        Dts.TaskResult = (int)ScriptResults.Failure;
    }
}

// ============================================================================
// EXAMPLE 3: Database Operations
// ============================================================================
public void Main()
{
    string connectionString = Dts.Connections["BookstoreETL"]
        .ConnectionString.ToString();
    
    using (SqlConnection conn = new SqlConnection(connectionString))
    {
        conn.Open();
        
        string sql = @"
            INSERT INTO ETL_ScriptLog (PackageName, ScriptName, LogMessage)
            VALUES (@PackageName, @ScriptName, @Message)";
        
        using (SqlCommand cmd = new SqlCommand(sql, conn))
        {
            cmd.Parameters.AddWithValue("@PackageName", 
                Dts.Variables["System::PackageName"].Value);
            cmd.Parameters.AddWithValue("@ScriptName", "CustomScript");
            cmd.Parameters.AddWithValue("@Message", "Script executed successfully");
            
            cmd.ExecuteNonQuery();
        }
    }
    
    Dts.TaskResult = (int)ScriptResults.Success;
}

// ============================================================================
// EXAMPLE 4: Email Notification
// ============================================================================
public void Main()
{
    try
    {
        string errorMessage = Dts.Variables["ErrorMessage"].Value.ToString();
        string packageName = Dts.Variables["System::PackageName"].Value.ToString();
        
        MailMessage mail = new MailMessage();
        mail.From = new MailAddress("etl@company.com");
        mail.To.Add("admin@company.com");
        mail.Subject = $"SSIS Package Failed: {packageName}";
        mail.Body = $"Error Details:\n\n{errorMessage}";
        
        SmtpClient smtp = new SmtpClient("smtp.company.com", 587);
        smtp.Credentials = new NetworkCredential("username", "password");
        smtp.Send(mail);
        
        Dts.TaskResult = (int)ScriptResults.Success;
    }
    catch (Exception ex)
    {
        Dts.Events.FireWarning(0, "Email Task", 
            "Failed to send email: " + ex.Message, "", 0);
        Dts.TaskResult = (int)ScriptResults.Success; // Don't fail package
    }
}
*/

-- ============================================================================
-- PART 4: FOR LOOP CONTAINER
-- ============================================================================
/*
FOR LOOP CONTAINER executes tasks repeatedly based on a counter:
- Similar to traditional for loop in programming
- Uses InitExpression, EvalExpression, AssignExpression
- Useful for batch processing, retry logic, date ranges

CONFIGURATION:
- InitExpression: @Counter = 0
- EvalExpression: @Counter < 10
- AssignExpression: @Counter = @Counter + 1

COMMON USE CASES:
- Process data in batches
- Retry failed operations
- Generate reports for date ranges
- Partition large datasets
*/

-- Create table for batch processing demonstration
CREATE TABLE BatchProcessing (
    BatchID INT PRIMARY KEY,
    StartRow INT,
    EndRow INT,
    ProcessedDate DATETIME,
    Status NVARCHAR(50)
);

-- Insert batch configuration
TRUNCATE TABLE BatchProcessing;

INSERT INTO BatchProcessing (BatchID, StartRow, EndRow, Status)
VALUES
    (1, 1, 1000, 'PENDING'),
    (2, 1001, 2000, 'PENDING'),
    (3, 2001, 3000, 'PENDING'),
    (4, 3001, 4000, 'PENDING'),
    (5, 4001, 5000, 'PENDING');

-- Procedure to process one batch
CREATE OR ALTER PROCEDURE sp_ProcessBatch
    @BatchID INT
AS
BEGIN
    DECLARE @StartRow INT, @EndRow INT;
    
    SELECT @StartRow = StartRow, @EndRow = EndRow
    FROM BatchProcessing
    WHERE BatchID = @BatchID;
    
    -- Simulate processing
    WAITFOR DELAY '00:00:02';
    
    UPDATE BatchProcessing
    SET Status = 'COMPLETED',
        ProcessedDate = GETDATE()
    WHERE BatchID = @BatchID;
    
    SELECT @BatchID AS BatchID, 'COMPLETED' AS Status;
END;
GO

/*
FOR LOOP PACKAGE EXAMPLE: "PKG_BatchProcessor"

SETUP:
1. Variables:
   - Counter: Int32 = 0
   - MaxBatches: Int32 = 5
   - CurrentBatch: Int32

2. For Loop Container:
   - InitExpression: @Counter = 0
   - EvalExpression: @Counter < @[User::MaxBatches]
   - AssignExpression: @Counter = @Counter + 1

3. Inside Loop:
   - Execute SQL Task: SET @CurrentBatch = @Counter + 1
   - Execute SQL Task: EXEC sp_ProcessBatch @CurrentBatch
*/

-- ============================================================================
-- PART 5: FOREACH LOOP CONTAINER
-- ============================================================================
/*
FOREACH LOOP CONTAINER iterates over a collection:
- File Enumerator: Loop through files in folder
- Item Enumerator: Loop through variable collection
- ADO Enumerator: Loop through query result set
- From Variable Enumerator: Loop through variable array
- Foreach NodeList Enumerator: Loop through XML nodes
- Foreach SMO Enumerator: Loop through SQL Server objects

MOST COMMON: File Enumerator and ADO Enumerator
*/

-- Create file processing tracking table
CREATE TABLE ETL_FileProcessing (
    FileID INT IDENTITY(1,1) PRIMARY KEY,
    FileName NVARCHAR(255),
    FilePath NVARCHAR(500),
    FileSize BIGINT,
    ProcessedDate DATETIME DEFAULT GETDATE(),
    RowsImported INT,
    Status NVARCHAR(50)
);

-- Procedure to log file processing
CREATE OR ALTER PROCEDURE sp_LogFileProcessing
    @FileName NVARCHAR(255),
    @FilePath NVARCHAR(500),
    @FileSize BIGINT,
    @RowsImported INT,
    @Status NVARCHAR(50)
AS
BEGIN
    INSERT INTO ETL_FileProcessing (
        FileName, FilePath, FileSize, RowsImported, Status
    )
    VALUES (
        @FileName, @FilePath, @FileSize, @RowsImported, @Status
    );
END;
GO

/*
FOREACH LOOP - FILE ENUMERATOR EXAMPLE: "PKG_ProcessFiles"

CONFIGURATION:
1. Foreach Loop Container → Collection Tab:
   - Enumerator: Foreach File Enumerator
   - Folder: C:\ETL\Input
   - Files: *.csv
   - Retrieve file name: Fully qualified

2. Variable Mappings:
   - Variable: User::CurrentFile
   - Index: 0

3. Inside Loop:
   - Data Flow Task: Import CurrentFile to staging
   - Execute SQL Task: Log file processing

FOREACH LOOP - ADO ENUMERATOR EXAMPLE: "PKG_ProcessTables"

CONFIGURATION:
1. Execute SQL Task (before loop):
   - Result Set: Full result set
   - SQL: SELECT TableName FROM ETL_Configuration WHERE IsActive = 1
   - Result Set → Result Name: 0 → Variable: User::TableList (Object)

2. Foreach Loop Container → Collection Tab:
   - Enumerator: Foreach ADO Enumerator
   - ADO object source variable: User::TableList
   - Enumeration mode: Rows in the first table

3. Variable Mappings:
   - Variable: User::CurrentTable
   - Index: 0

4. Inside Loop:
   - Execute SQL Task: Process User::CurrentTable
*/

-- Query to get list of tables for processing
SELECT 
    SourceTable AS TableName,
    TargetTable,
    IsActive
FROM ETL_Configuration
WHERE IsActive = 1
ORDER BY ConfigID;

-- ============================================================================
-- PART 6: PRECEDENCE CONSTRAINTS
-- ============================================================================
/*
PRECEDENCE CONSTRAINTS control task execution flow:

CONSTRAINT TYPES:
1. Success (Green): Execute if previous task succeeds
2. Failure (Red): Execute if previous task fails
3. Completion (Blue): Execute when previous task completes (success or failure)

EVALUATION OPTIONS:
- Constraint: Use execution result only
- Expression: Use expression only (must evaluate to True)
- Expression AND Constraint: Both must be true
- Expression OR Constraint: Either must be true

MULTIPLE CONSTRAINTS:
- Logical AND: All precedence constraints must be true
- Logical OR: Any precedence constraint must be true
*/

-- Create table for demonstrating conditional execution
CREATE TABLE DailyProcessingLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ProcessDate DATE DEFAULT CAST(GETDATE() AS DATE),
    RecordCount INT,
    ProcessType NVARCHAR(50),
    Duration INT,
    LogTime DATETIME DEFAULT GETDATE()
);

-- Insert sample data
INSERT INTO DailyProcessingLog (RecordCount, ProcessType, Duration)
VALUES
    (150, 'Incremental', 5),
    (1500, 'Full', 45),
    (200, 'Incremental', 6),
    (50, 'Incremental', 3),
    (2000, 'Full', 60);

/*
PRECEDENCE CONSTRAINT EXAMPLES:

EXAMPLE 1: Success Path vs Failure Path
┌──────────────────┐
│ Execute SQL Task │
│ (Main Process)   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Success │ Failure
    ▼         ▼
┌───────┐  ┌──────────┐
│Archive│  │Send Error│
│Files  │  │Email     │
└───────┘  └──────────┘

EXAMPLE 2: Conditional with Expression
Task 1 (Get Row Count)
    │ Success AND @RowCount > 1000
    ▼
Task 2 (Full Load)
    │
Task 1
    │ Success AND @RowCount <= 1000
    ▼
Task 3 (Incremental Load)

EXAMPLE 3: Multiple Constraints (OR)
Task A ─┐
        ├─ (Any Success) ─→ Task D
Task B ─┤
        │
Task C ─┘

EXAMPLE 4: Complex Flow
        ┌─→ Success ─→ Archive Files
Task A ─┤
        └─→ Failure ─→ Log Error ─→ Send Alert
                                    │
                        Completion ─┘
                                    │
                                    ▼
                            Cleanup Temp Files
*/

-- ============================================================================
-- PART 7: SEQUENCE CONTAINER
-- ============================================================================
/*
SEQUENCE CONTAINER groups tasks into logical units:
- Organizes complex packages
- Allows grouped error handling
- Enables transactional scope
- Simplifies package maintenance

BENEFITS:
- Visual organization
- Scope for variables
- Collective enable/disable
- Transaction boundaries

USE CASES:
- Group related data flow tasks
- Implement error handling blocks
- Create reusable task groups
- Organize by business process
*/

-- Create procedure for complex multi-step process
CREATE OR ALTER PROCEDURE sp_ComplexBusinessProcess
    @ProcessDate DATE,
    @StepNumber INT,
    @Status NVARCHAR(50) OUTPUT,
    @Message NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET @Status = 'SUCCESS';
    SET @Message = 'Step ' + CAST(@StepNumber AS VARCHAR) + ' completed';
    
    -- Simulate different steps
    IF @StepNumber = 1
        SET @Message = 'Data validation completed';
    ELSE IF @StepNumber = 2
        SET @Message = 'Data transformation completed';
    ELSE IF @StepNumber = 3
        SET @Message = 'Data load completed';
    ELSE IF @StepNumber = 4
        SET @Message = 'Post-load verification completed';
    
    -- Simulate occasional error
    IF @StepNumber = 3 AND RAND() < 0.1
    BEGIN
        SET @Status = 'ERROR';
        SET @Message = 'Data load failed - integrity constraint violation';
    END
END;
GO

/*
SEQUENCE CONTAINER EXAMPLE: "PKG_ComplexETL"

STRUCTURE:
Package
├── Sequence Container: "Data Validation"
│   ├── Execute SQL Task: Validate source data
│   ├── Execute SQL Task: Check referential integrity
│   └── Execute SQL Task: Log validation results
├── Sequence Container: "Data Transformation"
│   ├── Data Flow Task: Transform customers
│   ├── Data Flow Task: Transform orders
│   └── Execute SQL Task: Update transformation log
├── Sequence Container: "Data Load"
│   ├── Execute SQL Task: Disable indexes
│   ├── Data Flow Task: Load to production
│   ├── Execute SQL Task: Rebuild indexes
│   └── Execute SQL Task: Update statistics
└── Sequence Container: "Post-Load Verification"
    ├── Execute SQL Task: Verify row counts
    ├── Execute SQL Task: Validate business rules
    └── Execute SQL Task: Send completion notification
*/

-- ============================================================================
-- PART 8: EXECUTE PACKAGE TASK
-- ============================================================================
/*
EXECUTE PACKAGE TASK allows one package to execute another:
- Modular package design
- Reusable components
- Parent-child package hierarchies
- Centralized error handling

EXECUTION OPTIONS:
- In-Process: Execute in same process
- Out-of-Process: Execute in separate process

PARAMETER PASSING:
- Parent Package Variables → Child Package Parameters
- Child Package Results → Parent Package Variables
*/

-- Create master execution log
CREATE TABLE MasterPackageLog (
    ExecutionID INT IDENTITY(1,1) PRIMARY KEY,
    MasterPackage NVARCHAR(255),
    ChildPackage NVARCHAR(255),
    StartTime DATETIME DEFAULT GETDATE(),
    EndTime DATETIME,
    Status NVARCHAR(50),
    ErrorMessage NVARCHAR(MAX)
);

-- Procedure for master package coordination
CREATE OR ALTER PROCEDURE sp_LogPackageExecution
    @MasterPackage NVARCHAR(255),
    @ChildPackage NVARCHAR(255),
    @Status NVARCHAR(50),
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO MasterPackageLog (
        MasterPackage, ChildPackage, EndTime, Status, ErrorMessage
    )
    VALUES (
        @MasterPackage, @ChildPackage, GETDATE(), @Status, @ErrorMessage
    );
END;
GO

/*
MASTER PACKAGE EXAMPLE: "PKG_Master_DailyETL"

STRUCTURE:
Master Package
├── Execute Package Task: PKG_Extract_Customers
├── Execute Package Task: PKG_Extract_Orders
├── Execute Package Task: PKG_Transform_Data
├── Execute Package Task: PKG_Load_Warehouse
└── Execute SQL Task: Log master execution

Each child package is independent and can be:
- Developed separately
- Tested independently
- Reused in other workflows
- Executed manually or from master
*/

-- ============================================================================
-- PART 9: SEND MAIL TASK
-- ============================================================================
/*
SEND MAIL TASK sends email notifications:
- Success/failure notifications
- Daily summary reports
- Error alerts
- Data quality issues

CONFIGURATION:
- SMTP Connection Manager
- From, To, CC, BCC addresses
- Subject and message body
- Attachments
- Priority (Normal, Low, High)

DYNAMIC CONTENT:
- Use expressions for subject/body
- Include variable values
- Attach files dynamically
*/

-- Create email notification configuration
CREATE TABLE EmailNotificationConfig (
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    NotificationType NVARCHAR(50),
    Recipients NVARCHAR(MAX),
    Subject NVARCHAR(255),
    MessageTemplate NVARCHAR(MAX),
    IsActive BIT DEFAULT 1
);

INSERT INTO EmailNotificationConfig (NotificationType, Recipients, Subject, MessageTemplate)
VALUES
    ('SUCCESS', 'etl-team@company.com', 
     'ETL Success: {PackageName}',
     'Package {PackageName} completed successfully.
Duration: {Duration} seconds
Rows Processed: {RowCount}'),
    ('FAILURE', 'etl-team@company.com;manager@company.com',
     'ETL FAILURE: {PackageName}',
     'Package {PackageName} FAILED!
Error: {ErrorMessage}
Time: {ErrorTime}
Action Required: Review logs and restart'),
    ('WARNING', 'etl-team@company.com',
     'ETL Warning: {PackageName}',
     'Package {PackageName} completed with warnings.
Warning: {WarningMessage}');

-- ============================================================================
-- PART 10: EVENT HANDLERS
-- ============================================================================
/*
EVENT HANDLERS respond to package events:
- OnError: Task fails
- OnWarning: Warning occurs
- OnInformation: Information message
- OnPreExecute: Before task executes
- OnPostExecute: After task executes
- OnTaskFailed: Task fails
- OnProgress: Task progress update

COMMON USES:
- Error logging
- Send notifications
- Cleanup operations
- Custom auditing
- Performance monitoring
*/

-- Create detailed event log
CREATE TABLE PackageEventLog (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID UNIQUEIDENTIFIER,
    PackageName NVARCHAR(255),
    TaskName NVARCHAR(255),
    EventType NVARCHAR(50),
    EventTime DATETIME DEFAULT GETDATE(),
    EventMessage NVARCHAR(MAX),
    SourceName NVARCHAR(255),
    ErrorCode INT
);

-- Procedure for event logging
CREATE OR ALTER PROCEDURE sp_LogPackageEvent
    @ExecutionID UNIQUEIDENTIFIER,
    @PackageName NVARCHAR(255),
    @TaskName NVARCHAR(255),
    @EventType NVARCHAR(50),
    @EventMessage NVARCHAR(MAX),
    @SourceName NVARCHAR(255) = NULL,
    @ErrorCode INT = 0
AS
BEGIN
    INSERT INTO PackageEventLog (
        ExecutionID, PackageName, TaskName, EventType,
        EventMessage, SourceName, ErrorCode
    )
    VALUES (
        @ExecutionID, @PackageName, @TaskName, @EventType,
        @EventMessage, @SourceName, @ErrorCode
    );
END;
GO

/*
EVENT HANDLER EXAMPLE: OnError Event

EVENT HANDLER TASKS:
1. Execute SQL Task: Log error details
2. Script Task: Capture error context
3. Send Mail Task: Alert administrators
4. Execute SQL Task: Update audit log with failure

This automatically executes when ANY task in the package fails.
*/

-- View event log summary
SELECT 
    EventType,
    PackageName,
    COUNT(*) AS EventCount,
    MAX(EventTime) AS LastOccurrence
FROM PackageEventLog
GROUP BY EventType, PackageName
ORDER BY EventType, EventCount DESC;

-- ============================================================================
-- EXERCISES
-- ============================================================================

-- EXERCISE 1: Execute SQL Task Mastery (20 minutes)
/*
Create package "PKG_SQLTasks" with:
1. Execute SQL Task: Get customer count (store in variable)
2. Execute SQL Task: Get today's orders (full result set)
3. Execute SQL Task: Call sp_GetDailySummary (single row result)
4. Script Task: Display all retrieved values
*/

-- EXERCISE 2: File Processing Loop (25 minutes)
/*
Create package "PKG_FileLoop" with:
1. Foreach Loop Container: Iterate through CSV files in folder
2. Inside loop:
   - Data Flow Task: Import current file
   - Execute SQL Task: Log file processing
3. After loop: Send email summary
*/

-- EXERCISE 3: Conditional Execution (20 minutes)
/*
Create package "PKG_Conditional" with:
1. Execute SQL Task: Get row count from staging
2. Precedence Constraint: If count > 1000, do Full Load
3. Precedence Constraint: If count <= 1000, do Incremental Load
4. Both paths converge to: Update audit log
*/

-- EXERCISE 4: Error Handling (25 minutes)
/*
Create package "PKG_ErrorHandling" with:
1. Sequence Container: Main processing
2. OnError Event Handler: Log error and send email
3. OnPostExecute Event Handler: Log completion
4. Deliberately cause error to test handlers
*/

-- EXERCISE 5: Master-Child Packages (30 minutes)
/*
Create two packages:
Child: "PKG_Child_Extract" - Simple data extraction
Master: "PKG_Master_Orchestrator" - Executes child 3 times
   with different parameters each time
*/

-- ============================================================================
-- CHALLENGE PROBLEMS
-- ============================================================================

-- CHALLENGE 1: Dynamic Batch Processing (45 minutes)
/*
Create package that:
1. Reads batch configuration from table
2. Uses For Loop to process each batch
3. Logs start/end time for each batch
4. Implements retry logic for failed batches
5. Sends summary email at end
*/

-- CHALLENGE 2: File Processing with Archive (60 minutes)
/*
Create complete file processing solution:
1. Foreach Loop: Process all CSV files in Input folder
2. For each file:
   - Validate file format
   - Import to staging
   - Transform data
   - Load to target
   - Move file to Archive folder (date-stamped)
   - Log processing details
3. Error handling: Move bad files to Error folder
4. Send detailed summary email
*/

-- Sample archive log query
SELECT 
    FileName,
    FileSize,
    RowsImported,
    Status,
    ProcessedDate
FROM ETL_FileProcessing
WHERE ProcessedDate >= CAST(GETDATE() AS DATE)
ORDER BY ProcessedDate DESC;

-- CHALLENGE 3: Complex Workflow Orchestration (90 minutes)
/*
Create master ETL orchestration package:
1. Sequence Container: Pre-processing
   - Validate all source connections
   - Check disk space
   - Verify no other ETL is running
2. Sequence Container: Extraction (parallel execution)
   - Execute Package: Extract Customers
   - Execute Package: Extract Orders  
   - Execute Package: Extract Products
3. Sequence Container: Transformation (sequential)
   - Wait for all extractions to complete
   - Execute transformation packages in order
4. Sequence Container: Loading
   - Disable indexes
   - Load data
   - Rebuild indexes
5. Sequence Container: Post-processing
   - Verify data quality
   - Update statistics
   - Archive files
   - Send completion report

Implement comprehensive error handling and logging throughout.
*/

-- ============================================================================
-- BEST PRACTICES
-- ============================================================================
/*
1. EXECUTE SQL TASK:
   - Use parameterized queries to prevent SQL injection
   - Store complex queries in variables or files
   - Use appropriate result set types
   - Handle NULL values properly
   - Test queries outside SSIS first

2. LOOPS:
   - Set MaximumErrorCount appropriately
   - Implement loop timeout logic
   - Log each iteration
   - Handle empty collections gracefully
   - Consider performance impact of large loops

3. PRECEDENCE CONSTRAINTS:
   - Use descriptive constraint expressions
   - Avoid overly complex constraint logic
   - Document complex flows with annotations
   - Test all execution paths
   - Use colors consistently (Success=Green, Failure=Red)

4. CONTAINERS:
   - Use meaningful names
   - Group logically related tasks
   - Set appropriate transaction levels
   - Implement container-level error handling
   - Don't over-nest containers

5. ERROR HANDLING:
   - Always implement OnError event handlers
   - Log detailed error information
   - Send notifications for critical failures
   - Implement retry logic where appropriate
   - Clean up resources in error scenarios

6. PERFORMANCE:
   - Minimize loops when possible
   - Use bulk operations over row-by-row
   - Parallel execution for independent tasks
   - Proper index management during loads
   - Monitor memory usage
*/

-- ============================================================================
-- REFERENCE QUERIES
-- ============================================================================

-- Monitor package executions
SELECT 
    MasterPackage,
    ChildPackage,
    StartTime,
    EndTime,
    DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
    Status
FROM MasterPackageLog
WHERE StartTime >= DATEADD(DAY, -7, GETDATE())
ORDER BY StartTime DESC;

-- Event log analysis
SELECT 
    PackageName,
    EventType,
    COUNT(*) AS Occurrences,
    MAX(EventTime) AS LastOccurrence,
    MIN(EventTime) AS FirstOccurrence
FROM PackageEventLog
WHERE EventTime >= DATEADD(DAY, -30, GETDATE())
GROUP BY PackageName, EventType
ORDER BY PackageName, Occurrences DESC;

-- File processing statistics
SELECT 
    CAST(ProcessedDate AS DATE) AS ProcessDate,
    COUNT(*) AS FilesProcessed,
    SUM(RowsImported) AS TotalRows,
    SUM(FileSize) / 1024.0 / 1024.0 AS TotalMB,
    SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) AS SuccessCount,
    SUM(CASE WHEN Status = 'ERROR' THEN 1 ELSE 0 END) AS ErrorCount
FROM ETL_FileProcessing
GROUP BY CAST(ProcessedDate AS DATE)
ORDER BY ProcessDate DESC;

/*
============================================================================
LAB COMPLETION CHECKLIST
============================================================================
□ Mastered Execute SQL Task with different result set types
□ Implemented File System Task for file operations
□ Created Script Tasks with custom .NET code
□ Built packages using For Loop and Foreach Loop containers
□ Configured precedence constraints for conditional execution
□ Organized tasks using Sequence Containers
□ Implemented Event Handlers for error handling
□ Created master-child package hierarchies
□ Completed all exercises
□ Solved at least one challenge problem

NEXT LAB: Lab 55 - SSIS Data Flow Fundamentals
============================================================================
*/
