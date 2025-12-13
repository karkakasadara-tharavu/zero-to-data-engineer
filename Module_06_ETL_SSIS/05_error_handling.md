# SSIS Error Handling - Complete Guide

## 📚 What You'll Learn
- Error handling strategies
- Error outputs configuration
- Event handlers
- Logging and auditing
- Checkpoint/restart logic
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Error Handling Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSIS ERROR HANDLING LAYERS                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ CONTROL FLOW ERROR HANDLING                                     │   │
│   │ ├── Precedence Constraints (On Success, On Failure, On Complete)│   │
│   │ ├── Event Handlers (OnError, OnWarning, OnPreExecute, etc.)    │   │
│   │ ├── Transactions                                                │   │
│   │ ├── Checkpoints (restart from failure point)                   │   │
│   │ └── Try-Catch in Script Tasks                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ DATA FLOW ERROR HANDLING                                        │   │
│   │ ├── Error Outputs (redirect bad rows)                          │   │
│   │ ├── Error/Truncation Disposition                               │   │
│   │ ├── MaximumErrorCount                                          │   │
│   │ └── FailParentOnFailure                                        │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ LOGGING                                                         │   │
│   │ ├── SSIS Log Providers                                         │   │
│   │ ├── Event Logging                                               │   │
│   │ ├── Custom Logging (Script Tasks, SQL)                         │   │
│   │ └── SSISDB Catalog Logging (SQL Server 2012+)                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔀 Precedence Constraints

### Constraint Types

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PRECEDENCE CONSTRAINTS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────┐                                                            │
│   │ Task A │                                                            │
│   └────┬───┘                                                            │
│        │                                                                 │
│   ┌────┼────┬────────────────┐                                          │
│   │    │    │                │                                          │
│   ▼    ▼    ▼                ▼                                          │
│ ┌───────┐ ┌───────┐    ┌───────────┐                                   │
│ │Success│ │Failure│    │Completion │                                   │
│ │(Green)│ │(Red)  │    │(Blue)     │                                   │
│ └───────┘ └───────┘    └───────────┘                                   │
│                                                                          │
│   Evaluation Options:                                                    │
│   ├── Constraint: Success/Failure/Completion                            │
│   ├── Expression: @[User::Variable] == "Value"                         │
│   ├── Constraint AND Expression: Both must be true                     │
│   └── Constraint OR Expression: Either can be true                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Common Patterns

```
Pattern 1: Execute cleanup on failure
┌──────────────┐
│  ETL Task    │
└──────┬───────┘
       │ On Failure (Red)
       ▼
┌──────────────┐
│ Cleanup Task │
│ (Delete temp │
│  tables)     │
└──────────────┘

Pattern 2: Send notification on completion
┌──────────────┐
│  ETL Task    │
└──────┬───────┘
       │ On Completion (Blue)
       ▼
┌──────────────┐
│ Send Email   │
│ (with status)│
└──────────────┘

Pattern 3: Multiple conditions with expressions
┌──────────────┐
│  Task A      │
└──────┬───────┘
       │ Success AND @[User::ProcessType] == "Full"
       ▼
┌──────────────┐
│ Full Load    │
└──────────────┘
```

---

## 🚨 Data Flow Error Handling

### Error Output Configuration

Every Data Flow component can have an Error Output configured.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ERROR OUTPUT CONFIGURATION                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Error Disposition Options:                                             │
│   ├── Fail Component     - Stop processing immediately                  │
│   ├── Ignore Failure     - Skip row, continue processing                │
│   └── Redirect Row       - Send to error output path                    │
│                                                                          │
│   Truncation Disposition Options:                                        │
│   ├── Fail Component     - Stop on truncation                           │
│   ├── Ignore Failure     - Truncate silently                            │
│   └── Redirect Row       - Send truncated rows to error path            │
│                                                                          │
│   Error Output Columns:                                                  │
│   ├── ErrorCode          - SSIS error code                              │
│   ├── ErrorColumn        - LineageID of failing column                  │
│   └── All source columns - Original data that failed                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Error Handling Pattern

```
                    ┌─────────────┐
                    │   Source    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Transform  │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     [Error Output]   [Success Output]    │
            │              │              │
            ▼              ▼              │
    ┌───────────────┐ ┌───────────────┐   │
    │ Error Table   │ │  Destination  │   │
    │ + Error Info  │ │               │   │
    └───────────────┘ └───────────────┘   │
```

### Script to Decode Error Columns

```sql
-- Create mapping table from SSIS LineageID to Column Name
-- (Run during package design to capture lineage)

-- Alternative: Use Script Component to decode
-- In Script Component (C#):
public override void Input0_ProcessInputRow(Input0Buffer Row)
{
    Row.ErrorDescription = 
        ComponentMetaData.GetErrorDescription(Row.ErrorCode);
    Row.ErrorColumnName = 
        GetColumnName(Row.ErrorColumn);
}

-- Error logging table structure
CREATE TABLE ETL_Errors (
    ErrorID INT IDENTITY(1,1),
    PackageName VARCHAR(255),
    TaskName VARCHAR(255),
    ErrorCode INT,
    ErrorDescription VARCHAR(MAX),
    ErrorColumn VARCHAR(255),
    RowData NVARCHAR(MAX),
    ErrorTime DATETIME DEFAULT GETDATE()
);
```

---

## 📋 Event Handlers

Event handlers execute when specific events occur during package execution.

### Event Types

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SSIS EVENT HANDLERS                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Event Name           When Triggered                                    │
│   ─────────────────    ──────────────────────────────────────────────   │
│   OnPreExecute         Before a task starts                             │
│   OnPostExecute        After a task completes (success or failure)      │
│   OnPreValidate        Before validation                                │
│   OnPostValidate       After validation                                 │
│   OnProgress           During task execution                            │
│   OnInformation        Informational messages                           │
│   OnWarning            Warning messages                                 │
│   OnError              Error occurs                                     │
│   OnTaskFailed         Task fails                                       │
│   OnVariableValueChanged  Variable value changes                        │
│   OnQueryCancel        Query cancel requested                           │
│                                                                          │
│   Event Handler Scope:                                                   │
│   ├── Package Level: Triggers for any component                         │
│   ├── Container Level: Triggers for container contents                  │
│   └── Task Level: Triggers only for specific task                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Common Event Handler Use Cases

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    EVENT HANDLER EXAMPLES                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   OnError (Package Level):                                               │
│   ├── Log error to database                                             │
│   ├── Send email notification                                           │
│   ├── Update audit table                                                │
│   └── Execute cleanup tasks                                             │
│                                                                          │
│   OnPreExecute (Package Level):                                          │
│   ├── Log start time                                                    │
│   ├── Initialize audit record                                           │
│   └── Set variable values                                               │
│                                                                          │
│   OnPostExecute (Package Level):                                         │
│   ├── Log end time                                                      │
│   ├── Calculate duration                                                │
│   ├── Update audit record                                               │
│   └── Send completion notification                                      │
│                                                                          │
│   System Variables Available in Event Handlers:                          │
│   ├── System::ErrorCode                                                 │
│   ├── System::ErrorDescription                                          │
│   ├── System::SourceName                                                │
│   ├── System::SourceID                                                  │
│   └── System::ExecutionInstanceGUID                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Example: OnError Event Handler

```
┌─────────────────────────────────────────────────────────────────────────┐
│   OnError Event Handler                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────┐                                                   │
│   │ Execute SQL     │                                                   │
│   │ INSERT INTO     │                                                   │
│   │ ErrorLog...     │                                                   │
│   └────────┬────────┘                                                   │
│            │ Success                                                     │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │ Send Mail Task  │                                                   │
│   │ To: DBA Team    │                                                   │
│   │ Subject: Error  │                                                   │
│   │ in Package      │                                                   │
│   └─────────────────┘                                                   │
│                                                                          │
│   SQL Statement:                                                         │
│   INSERT INTO ETL_ErrorLog                                               │
│       (PackageName, TaskName, ErrorCode, ErrorDescription, ErrorTime)   │
│   VALUES                                                                 │
│       (?, ?, ?, ?, GETDATE())                                           │
│                                                                          │
│   Parameter Mapping:                                                     │
│   0 → System::PackageName                                               │
│   1 → System::SourceName                                                │
│   2 → System::ErrorCode                                                 │
│   3 → System::ErrorDescription                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📝 Logging

### SSIS Log Providers

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LOG PROVIDERS                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Provider Type         Description                                      │
│   ─────────────────     ──────────────────────────────────────────────  │
│   SQL Server            Log to sysssislog table                         │
│   Text File             Log to flat text file                           │
│   XML File              Log to XML format                               │
│   Windows Event Log     Log to Windows Application log                  │
│   SQL Server Profiler   Log for SQL Profiler analysis                   │
│                                                                          │
│   Events to Log (Configure per task/package):                           │
│   ├── OnError                                                           │
│   ├── OnWarning                                                         │
│   ├── OnInformation                                                     │
│   ├── OnPreExecute                                                      │
│   ├── OnPostExecute                                                     │
│   ├── OnPreValidate                                                     │
│   ├── OnPostValidate                                                    │
│   ├── OnProgress                                                        │
│   ├── Diagnostic                                                        │
│   └── (many more...)                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### SSISDB Catalog Logging (SQL Server 2012+)

```
Built-in logging when deployed to SSISDB:
├── Automatic execution logging
├── Operation messages
├── Execution statistics
├── Parameter values used
└── Event messages

Query execution history:
SELECT 
    e.execution_id,
    e.folder_name,
    e.project_name,
    e.package_name,
    e.status,
    e.start_time,
    e.end_time
FROM catalog.executions e
ORDER BY e.start_time DESC;

Query error messages:
SELECT 
    e.execution_id,
    em.message_time,
    em.message_type,
    em.message
FROM catalog.executions e
JOIN catalog.event_messages em 
    ON e.execution_id = em.operation_id
WHERE em.message_type = 120 -- Error messages
ORDER BY em.message_time;
```

---

## ♻️ Checkpoints (Restart Logic)

Checkpoints allow packages to restart from the point of failure.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CHECKPOINT CONFIGURATION                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Package Properties:                                                    │
│   ├── SaveCheckpoints       = True                                      │
│   ├── CheckpointFileName    = C:\Checkpoints\Package.chk                │
│   └── CheckpointUsage       = IfExists / Always / Never                 │
│                                                                          │
│   Container/Task Properties:                                             │
│   └── FailPackageOnFailure  = True                                      │
│       (Required for checkpoint to be saved)                             │
│                                                                          │
│   CheckpointUsage Options:                                               │
│   ├── Never    - Don't use checkpoints                                  │
│   ├── IfExists - Use if file exists, else start fresh                  │
│   └── Always   - Must have checkpoint file to run                       │
│                                                                          │
│   How Checkpoints Work:                                                  │
│   1. Package runs                                                        │
│   2. Task fails (FailPackageOnFailure = True)                           │
│   3. Checkpoint file created with state                                 │
│   4. Package stops                                                       │
│   5. Fix issue and re-run                                               │
│   6. Package reads checkpoint, skips completed tasks                    │
│   7. Continues from failed task                                         │
│   8. On success, checkpoint file deleted                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Checkpoint Limitations

```
DOES save:
├── Completed container/task status
├── Variable values (User:: scope)
├── For Each Loop iterator position
└── For Loop counter value

DOES NOT save:
├── Data Flow Task progress
├── Individual rows processed
├── Transaction state
└── Script Task internal state

Best Practices:
├── Use for long-running packages
├── Set FailPackageOnFailure on critical tasks
├── Use unique checkpoint file names
├── Clean up old checkpoint files
└── Consider Data Flow transactions separately
```

---

## 💼 Transactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    TRANSACTION CONFIGURATION                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   TransactionOption Property:                                            │
│   ├── NotSupported  - Never participate in transaction                  │
│   ├── Supported     - Join parent transaction if exists                 │
│   └── Required      - Require transaction (create new or join)          │
│                                                                          │
│   Example: All-or-nothing data load                                      │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ Sequence Container (TransactionOption = Required)                 │  │
│   │ ┌────────────────┐  ┌────────────────┐  ┌────────────────┐      │  │
│   │ │ Delete Staging │→ │ Load Staging   │→ │ Load Target    │      │  │
│   │ │ Table          │  │ Table          │  │ Table          │      │  │
│   │ └────────────────┘  └────────────────┘  └────────────────┘      │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│   If Load Target fails:                                                  │
│   └── All changes rolled back (Delete and Load Staging too)             │
│                                                                          │
│   Requirements:                                                          │
│   ├── MSDTC enabled on servers                                          │
│   ├── RetainSameConnection = True on connection managers                │
│   └── All tasks use same connection                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Custom Audit Framework

```sql
-- Audit Tables
CREATE TABLE ETL_Audit_Master (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    PackageName VARCHAR(255),
    PackageGUID UNIQUEIDENTIFIER,
    ExecutionID UNIQUEIDENTIFIER,
    MachineName VARCHAR(100),
    UserName VARCHAR(100),
    StartTime DATETIME,
    EndTime DATETIME,
    Status VARCHAR(20), -- Running, Success, Failed
    RowsProcessed INT,
    ErrorMessage VARCHAR(MAX)
);

CREATE TABLE ETL_Audit_Detail (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    AuditID INT FOREIGN KEY REFERENCES ETL_Audit_Master(AuditID),
    TaskName VARCHAR(255),
    StartTime DATETIME,
    EndTime DATETIME,
    Status VARCHAR(20),
    RowsRead INT,
    RowsWritten INT,
    ErrorMessage VARCHAR(MAX)
);

-- Start Package (OnPreExecute at Package level)
INSERT INTO ETL_Audit_Master 
    (PackageName, ExecutionID, MachineName, UserName, StartTime, Status)
VALUES 
    (@PackageName, @ExecutionInstanceGUID, @MachineName, @UserName, GETDATE(), 'Running');

-- End Package (OnPostExecute at Package level)
UPDATE ETL_Audit_Master
SET EndTime = GETDATE(),
    Status = CASE WHEN @ErrorCount = 0 THEN 'Success' ELSE 'Failed' END,
    RowsProcessed = @TotalRows
WHERE ExecutionID = @ExecutionInstanceGUID;
```

---

## 🎓 Interview Questions

### Q1: How do you handle errors in SSIS Data Flow?
**A:** 
- Configure Error Output on components
- Set Error Disposition to "Redirect Row"
- Route error rows to error handling path
- Log to error table with error code, description, and original data

### Q2: What is the difference between Event Handlers and Error Outputs?
**A:**
- **Event Handlers**: Control Flow level, respond to events like OnError, OnPreExecute
- **Error Outputs**: Data Flow level, handle row-level data errors and redirect bad rows

### Q3: How do checkpoints work in SSIS?
**A:**
- Save package state to file on failure
- Re-run skips completed tasks
- Continues from failed task
- Requires SaveCheckpoints=True and FailPackageOnFailure=True

### Q4: What events can you handle in SSIS Event Handlers?
**A:** OnPreExecute, OnPostExecute, OnError, OnWarning, OnInformation, OnProgress, OnPreValidate, OnPostValidate, OnTaskFailed, OnVariableValueChanged

### Q5: How do you implement transactions in SSIS?
**A:**
- Set TransactionOption property (Required/Supported/NotSupported)
- Use Sequence Container for transaction scope
- Ensure MSDTC is enabled
- Set RetainSameConnection=True on connection managers

### Q6: What are the SSIS log providers?
**A:**
- SQL Server (sysssislog table)
- Text File
- XML File
- Windows Event Log
- SQL Server Profiler

### Q7: How do you decode error column in Error Output?
**A:**
- ErrorColumn contains LineageID, not column name
- Use Script Component to look up column metadata
- Query ComponentMetaData.GetErrorDescription(ErrorCode)
- Map LineageID to column names at design time

### Q8: What is the difference between Fail Component and Redirect Row?
**A:**
- **Fail Component**: Stop entire Data Flow on error
- **Redirect Row**: Send bad row to error output, continue processing

### Q9: How do you build an audit framework in SSIS?
**A:**
- Create audit tables (Master and Detail)
- Use Event Handlers to log start/end times
- Capture row counts and status
- Log errors to detail table
- Use System variables for metadata

### Q10: What are checkpoint limitations?
**A:**
- Cannot save Data Flow progress (row level)
- For Each Loop position saved, but not container contents
- Script Task internal state not saved
- Transaction state not saved

---

## 🔗 Related Topics
- [← Transformations](./04_transformations.md)
- [Deployment →](./06_deployment.md)
- [Performance Optimization →](./07_performance.md)

---

*Next: Learn about SSIS Package Deployment*
