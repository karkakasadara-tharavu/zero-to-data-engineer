# SSIS Control Flow - Complete Guide

## 📚 What You'll Learn
- Understanding Control Flow
- Common Control Flow tasks
- Precedence constraints
- Containers for grouping
- Loops and conditional execution
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is Control Flow?

Control Flow defines the **workflow** of your SSIS package - the order in which tasks execute and the logic that determines execution paths.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       CONTROL FLOW OVERVIEW                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Control Flow = "What to do and in what order"                         │
│                                                                          │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │                                                                   │  │
│   │   ┌─────────┐                                                     │  │
│   │   │ Start   │                                                     │  │
│   │   └────┬────┘                                                     │  │
│   │        │ (Success)                                                │  │
│   │        ▼                                                          │  │
│   │   ┌─────────┐     (Failure)    ┌─────────┐                       │  │
│   │   │Truncate │─────────────────▶│  Log    │                       │  │
│   │   │ Table   │                  │ Error   │                       │  │
│   │   └────┬────┘                  └─────────┘                       │  │
│   │        │ (Success)                                                │  │
│   │        ▼                                                          │  │
│   │   ┌─────────┐                                                     │  │
│   │   │Data Flow│                                                     │  │
│   │   │  Task   │                                                     │  │
│   │   └────┬────┘                                                     │  │
│   │        │ (Success)                                                │  │
│   │        ▼                                                          │  │
│   │   ┌─────────┐                                                     │  │
│   │   │  Send   │                                                     │  │
│   │   │  Email  │                                                     │  │
│   │   └─────────┘                                                     │  │
│   │                                                                   │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Common Control Flow Tasks

### Execute SQL Task

Executes SQL statements against a database.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    EXECUTE SQL TASK                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Use Cases:                                                             │
│   - Truncate staging tables before load                                 │
│   - Execute stored procedures                                           │
│   - Run DDL statements (CREATE, ALTER)                                  │
│   - Retrieve single values into variables                               │
│   - Get row counts                                                       │
│                                                                          │
│   Configuration:                                                         │
│   - Connection: OLE DB connection manager                               │
│   - SQLSourceType: Direct input, File connection, Variable             │
│   - ResultSet: None, Single row, Full result set                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Example: Truncate and Load Pattern**
```sql
-- Execute SQL Task 1: Truncate staging
TRUNCATE TABLE dbo.Staging_Customers;

-- Execute SQL Task 2: Get last load date (to variable)
SELECT MAX(LoadDate) FROM dbo.ETL_Log WHERE TableName = 'Customers';

-- Execute SQL Task 3: Log completion
INSERT INTO dbo.ETL_Log (TableName, RowCount, LoadDate)
VALUES ('Customers', ?, GETDATE());
```

### Data Flow Task

Contains the data pipeline - sources, transformations, and destinations.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DATA FLOW TASK                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐             │
│   │  OLE DB │───▶│ Derived │───▶│  Lookup │───▶│  OLE DB │             │
│   │  Source │    │ Column  │    │         │    │  Dest   │             │
│   └─────────┘    └─────────┘    └─────────┘    └─────────┘             │
│                                                                          │
│   This is a separate design surface within Control Flow                 │
│   (Covered in detail in Data Flow module)                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Script Task

Executes custom C# or VB.NET code.

```csharp
// Example: Script Task to validate file exists
public void Main()
{
    string filePath = Dts.Variables["User::FilePath"].Value.ToString();
    
    if (System.IO.File.Exists(filePath))
    {
        Dts.Variables["User::FileExists"].Value = true;
        Dts.TaskResult = (int)ScriptResults.Success;
    }
    else
    {
        Dts.Variables["User::FileExists"].Value = false;
        Dts.TaskResult = (int)ScriptResults.Failure;
    }
}
```

### File System Task

Performs file and folder operations.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                FILE SYSTEM TASK OPERATIONS                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Copy File          - Copy file to new location                        │
│   Move File          - Move file to new location                        │
│   Delete File        - Remove file                                      │
│   Rename File        - Change file name                                 │
│   Create Directory   - Create new folder                                │
│   Delete Directory   - Remove folder                                    │
│   Delete Directory Content - Remove contents but keep folder           │
│   Set Attributes     - Set file attributes (read-only, etc.)           │
│                                                                          │
│   Common Pattern:                                                        │
│   1. Process file                                                        │
│   2. Move to Archive folder                                             │
│   3. Rename with timestamp                                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Send Mail Task

Sends email notifications.

```
Configuration:
├── SmtpConnection: SMTP connection manager
├── From: sender@company.com
├── To: team@company.com (can use variable)
├── Subject: ETL Package Completed (can use expression)
├── MessageSource: Direct input or variable
└── Attachments: Log files, reports
```

### Execute Package Task

Runs another SSIS package (child package).

```
┌─────────────────────────────────────────────────────────────────────────┐
│                MASTER-CHILD PACKAGE PATTERN                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Master Package:                                                        │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │   │
│   │  │Execute Pkg: │  │Execute Pkg: │  │Execute Pkg: │              │   │
│   │  │Load_Dim_    │  │Load_Dim_    │  │Load_Fact_   │              │   │
│   │  │Customer     │  │Product      │  │Sales        │              │   │
│   │  └─────────────┘  └─────────────┘  └─────────────┘              │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   Benefits:                                                              │
│   - Modular design                                                       │
│   - Reusable packages                                                    │
│   - Parallel execution                                                   │
│   - Easier maintenance                                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Precedence Constraints

Precedence constraints connect tasks and control execution flow.

### Constraint Types

```
┌─────────────────────────────────────────────────────────────────────────┐
│                 PRECEDENCE CONSTRAINT TYPES                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────┐                                                            │
│   │ Task A  │                                                            │
│   └────┬────┘                                                            │
│        │                                                                 │
│   ┌────┴────┬────────────┬────────────┐                                 │
│   │         │            │            │                                  │
│   ▼         ▼            ▼            │                                  │
│ ┌───┐     ┌───┐        ┌───┐         │                                  │
│ │ B │     │ C │        │ D │         │                                  │
│ └───┘     └───┘        └───┘         │                                  │
│   │         │            │            │                                  │
│ Success   Failure    Completion      │                                  │
│ (Green)    (Red)      (Blue)         │                                  │
│                                       │                                  │
│                                       │                                  │
│   SUCCESS: Execute if predecessor succeeded                             │
│   FAILURE: Execute if predecessor failed                                │
│   COMPLETION: Execute regardless of result                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Multiple Constraints (AND/OR)

```
┌─────────────────────────────────────────────────────────────────────────┐
│             MULTIPLE CONSTRAINTS - LOGICAL OPERATIONS                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   AND (Logical AND):                   OR (Logical OR):                 │
│   All must be true                     Any one must be true             │
│                                                                          │
│   ┌───┐     ┌───┐                     ┌───┐     ┌───┐                   │
│   │ A │     │ B │                     │ A │     │ B │                   │
│   └─┬─┘     └─┬─┘                     └─┬─┘     └─┬─┘                   │
│     │  AND    │                         │  OR     │                     │
│     └────┬────┘                         └────┬────┘                     │
│          ▼                                   ▼                          │
│        ┌───┐                               ┌───┐                        │
│        │ C │                               │ C │                        │
│        └───┘                               └───┘                        │
│   Runs only if                         Runs if either                   │
│   A AND B succeed                      A OR B succeeds                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Expression Constraints

Add custom conditions using expressions:

```
Expression Examples:
├── @[User::RowCount] > 0           -- Only if rows found
├── @[User::FileExists] == TRUE      -- Only if file exists
├── DATEPART("dw", GETDATE()) != 1   -- Not on Sunday
├── @[User::ProcessType] == "FULL"   -- Full load only
└── @[User::ErrorCount] < 5          -- Continue if few errors
```

---

## 📦 Containers

Containers group tasks and provide scope for variables, transactions, and loops.

### Sequence Container

Groups tasks for organization and collective configuration.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SEQUENCE CONTAINER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────── Customer Load ──────────────────────┐            │
│   │                                                         │            │
│   │   ┌──────────┐   ┌──────────┐   ┌──────────┐           │            │
│   │   │ Truncate │──▶│Data Flow │──▶│  Update  │           │            │
│   │   │ Staging  │   │  Task    │   │  Status  │           │            │
│   │   └──────────┘   └──────────┘   └──────────┘           │            │
│   │                                                         │            │
│   └─────────────────────────────────────────────────────────┘            │
│                         │                                                │
│                         ▼ (Success)                                      │
│   ┌─────────────────── Product Load ───────────────────────┐            │
│   │                                                         │            │
│   │   ┌──────────┐   ┌──────────┐   ┌──────────┐           │            │
│   │   │ Truncate │──▶│Data Flow │──▶│  Update  │           │            │
│   │   │ Staging  │   │  Task    │   │  Status  │           │            │
│   │   └──────────┘   └──────────┘   └──────────┘           │            │
│   │                                                         │            │
│   └─────────────────────────────────────────────────────────┘            │
│                                                                          │
│   Benefits:                                                              │
│   - Visual organization                                                  │
│   - Transaction scope                                                    │
│   - Collective disable/enable                                           │
│   - Shared variables                                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### For Loop Container

Repeats tasks a fixed number of times.

```
For Loop Configuration:
├── InitExpression:   @Counter = 1
├── EvalExpression:   @Counter <= 10
├── AssignExpression: @Counter = @Counter + 1

┌────────────────────────────────────────────────────┐
│   FOR (@Counter = 1; @Counter <= 10; @Counter++)   │
│   ┌────────────────────────────────────────────┐   │
│   │   ┌──────────┐   ┌──────────┐              │   │
│   │   │ Process  │──▶│  Log     │              │   │
│   │   │ Batch    │   │ Progress │              │   │
│   │   └──────────┘   └──────────┘              │   │
│   └────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────┘
```

### Foreach Loop Container

Iterates over a collection (files, rows, variables).

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FOREACH LOOP ENUMERATORS                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Foreach File Enumerator:                                              │
│   - Iterate over files in a folder                                     │
│   - Filter by pattern (*.csv, *.txt)                                   │
│   - Get file name or full path                                         │
│                                                                          │
│   Foreach ADO Enumerator:                                               │
│   - Iterate over rows in a result set                                  │
│   - Process each row with tasks                                        │
│                                                                          │
│   Foreach Item Enumerator:                                              │
│   - Iterate over a list of items                                       │
│   - Useful for configuration lists                                     │
│                                                                          │
│   Foreach Variable Enumerator:                                          │
│   - Iterate over collections in variables                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Example: Process All CSV Files**
```
Foreach Loop Container:
├── Enumerator: Foreach File Enumerator
├── Folder: C:\DataFiles\Incoming
├── Files: *.csv
├── Retrieve: Fully qualified
└── Variable mapping: User::CurrentFilePath

    Inside Container:
    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
    │  Data Flow  │──▶│    Move     │──▶│    Log     │
    │  (Load CSV) │   │  to Archive │   │  Success   │
    └─────────────┘   └─────────────┘   └─────────────┘
```

---

## 🔧 Common Patterns

### Pattern 1: Truncate and Load

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Execute    │    │  Data Flow   │    │   Execute    │
│   SQL Task   │───▶│    Task      │───▶│   SQL Task   │
│  (TRUNCATE)  │    │   (LOAD)     │    │  (LOG)       │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Pattern 2: Conditional Processing

```
                    ┌──────────────┐
                    │   Check      │
                    │   Condition  │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         │ @Condition=TRUE │                 │ @Condition=FALSE
         ▼                 │                 ▼
    ┌──────────┐           │           ┌──────────┐
    │  Full    │           │           │   Delta  │
    │  Load    │           │           │   Load   │
    └──────────┘           │           └──────────┘
                           │
                    ┌──────▼───────┐
                    │   Complete   │
                    └──────────────┘
```

### Pattern 3: Error Handling

```
    ┌──────────────┐
    │  Main Task   │
    └──────┬───────┘
           │
    ┌──────┴──────┐
    │             │
    ▼ Success     ▼ Failure
┌──────────┐  ┌──────────┐
│ Continue │  │  Log     │
│ Process  │  │  Error   │
└──────────┘  └────┬─────┘
                   │
                   ▼
              ┌──────────┐
              │  Send    │
              │  Alert   │
              └──────────┘
```

---

## 🎓 Interview Questions

### Q1: What is a Control Flow in SSIS?
**A:** Control Flow defines the workflow of a package - the sequence of tasks and the logic determining execution paths. It contains tasks (Execute SQL, Data Flow, Script, etc.) connected by precedence constraints that control when each task runs.

### Q2: What are the types of Precedence Constraints?
**A:**
- **Success (Green)**: Execute if previous task succeeded
- **Failure (Red)**: Execute if previous task failed
- **Completion (Blue)**: Execute regardless of previous result

Can also combine with expressions for conditional logic.

### Q3: What is the difference between For Loop and Foreach Loop containers?
**A:**
- **For Loop**: Repeats a fixed number of times based on counter (init, eval, increment expressions)
- **Foreach Loop**: Iterates over a collection (files, rows, items, variables)

### Q4: What is a Sequence Container used for?
**A:** Sequence Containers group related tasks for:
- Visual organization
- Transaction scope (commit/rollback together)
- Collective enable/disable
- Shared variable scope
- Common event handlers

### Q5: How do you pass parameters to a child package?
**A:** Using Execute Package Task:
1. **Project Reference**: Access parent project parameters
2. **Parameter bindings**: Map parent variables to child parameters
3. **Configurations**: Environment variables in SSIS Catalog

### Q6: What is the Execute SQL Task used for?
**A:**
- Execute SQL statements (DML, DDL)
- Run stored procedures
- Retrieve result sets into variables
- Get single values (row counts, max dates)
- Execute dynamic SQL from variables

### Q7: How do you implement error handling in Control Flow?
**A:**
1. Use **Failure precedence constraints** to route to error handling
2. Create **Event Handlers** (OnError, OnTaskFailed)
3. Use **Script Tasks** for custom error logging
4. Set **FailPackageOnFailure** property
5. Use **Sequence Containers** with transactions

### Q8: What is the difference between AND and OR in multiple precedence constraints?
**A:**
- **AND (Logical AND)**: All predecessor constraints must be satisfied
- **OR (Logical OR)**: Any one predecessor constraint satisfied is enough

Configure in constraint properties (Multiple Constraints option).

### Q9: How do you dynamically set file paths in File System Task?
**A:**
1. Create a variable for the path
2. Use expressions to build the path dynamically
3. Set File System Task to use the variable
4. Can combine with Foreach Loop for multiple files

### Q10: What is the Script Task and when would you use it?
**A:** Script Task executes custom C#/VB.NET code. Use for:
- Complex validation logic
- File operations not available in File System Task
- API calls and web services
- Custom logging
- Calculations not possible with expressions
- FTP operations with custom requirements

---

## 🔗 Related Topics
- [← SSIS Introduction](./01_ssis_introduction.md)
- [Data Flow Components →](./03_data_flow.md)
- [Transformations →](./04_transformations.md)

---

*Next: Learn about Data Flow Components*
