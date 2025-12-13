# SSIS Data Flow - Complete Guide

## 📚 What You'll Learn
- Understanding Data Flow architecture
- Source components
- Destination components
- Data Flow paths and viewers
- Buffer management
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is Data Flow?

Data Flow is where the actual **data movement and transformation** happens. It's a separate design surface within a Data Flow Task in Control Flow.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       DATA FLOW ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Control Flow                                                           │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │  ┌──────────┐    ┌───────────────────┐    ┌──────────┐           │  │
│   │  │SQL Task  │───▶│   DATA FLOW TASK  │───▶│SQL Task  │           │  │
│   │  └──────────┘    └─────────┬─────────┘    └──────────┘           │  │
│   └────────────────────────────┼─────────────────────────────────────┘  │
│                                │                                         │
│                                ▼                                         │
│   Data Flow (inside Data Flow Task)                                     │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │                                                                   │  │
│   │   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐         │  │
│   │   │ SOURCE  │──▶│TRANSFORM│──▶│TRANSFORM│──▶│  DEST   │         │  │
│   │   │         │   │         │   │         │   │         │         │  │
│   │   └─────────┘   └─────────┘   └─────────┘   └─────────┘         │  │
│   │                                                                   │  │
│   │   Data flows through BUFFERS (in-memory data blocks)             │  │
│   │                                                                   │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📤 Source Components

Sources extract data from various systems.

### OLE DB Source

Most common source for SQL Server and other databases.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       OLE DB SOURCE                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Data Access Modes:                                                     │
│                                                                          │
│   1. Table or View                                                       │
│      - Direct table access                                              │
│      - Simple but less control                                          │
│                                                                          │
│   2. Table name from variable                                           │
│      - Dynamic table selection                                          │
│      - Set at runtime                                                    │
│                                                                          │
│   3. SQL Command                                                         │
│      - Custom query                                                      │
│      - Best for filtering at source                                     │
│      - Recommended for performance                                      │
│                                                                          │
│   4. SQL Command from variable                                          │
│      - Dynamic queries                                                   │
│      - Build query at runtime                                           │
│                                                                          │
│   Example SQL Command:                                                   │
│   SELECT CustomerID, Name, Email                                        │
│   FROM Customers                                                         │
│   WHERE ModifiedDate > ?   -- Parameter from variable                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Flat File Source

Reads delimited or fixed-width text files.

```
Configuration:
├── Connection Manager: Flat File connection
├── File format: Delimited or Fixed width
├── Column delimiter: Comma, Tab, Pipe, etc.
├── Header row: First row as column names
├── Data type detection: Suggest types or define manually
└── Text qualifier: " for quoted strings

Common Issues:
├── Encoding (UTF-8, ANSI, Unicode)
├── Date format variations
├── Numeric formats (1,000 vs 1.000)
├── Null representation
└── Inconsistent row lengths
```

### Excel Source

Reads data from Excel workbooks.

```
Configuration:
├── Connection Manager: Excel connection
├── Excel version: 97-2003 (.xls) or 2007+ (.xlsx)
├── Data Access Mode: Table/View or SQL Command
├── First row: Column names or data
└── Sheet name: Specify worksheet

Limitations:
├── 64-bit compatibility issues (use 32-bit SSIS)
├── Mixed data type columns
├── Limited to single sheet per source
└── ACE driver requirements
```

### ADO.NET Source

Uses .NET data providers for connectivity.

```
Use When:
├── Need .NET specific providers
├── Entity Framework integration
├── Custom .NET data access
└── Better Unicode support than OLE DB
```

### XML Source

Reads XML files into data flow.

```
Configuration:
├── XML data location: File, Variable, or Connection
├── XSD schema: Required for structure definition
├── Output columns: Generated from XSD
└── Multiple outputs: For complex XML structures
```

---

## 📥 Destination Components

Destinations load data into target systems.

### OLE DB Destination

Most common destination for SQL Server.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    OLE DB DESTINATION                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Data Access Modes:                                                     │
│                                                                          │
│   1. Table or View                                                       │
│      - Insert into existing table                                       │
│      - Column mapping required                                          │
│                                                                          │
│   2. Table or View - Fast Load (RECOMMENDED)                            │
│      - Bulk insert for performance                                      │
│      - Options: Keep identity, Check constraints                        │
│      - Batch size configuration                                         │
│                                                                          │
│   3. Table name from variable                                           │
│      - Dynamic destination                                              │
│      - Useful with Foreach Loop                                         │
│                                                                          │
│   4. SQL Command                                                         │
│      - Custom INSERT with expressions                                   │
│      - Slower than Fast Load                                            │
│                                                                          │
│   Fast Load Options:                                                     │
│   ├── Keep Identity: Preserve source identity values                   │
│   ├── Keep Nulls: Don't use defaults for NULLs                         │
│   ├── Table Lock: Lock entire table (faster)                           │
│   ├── Check Constraints: Validate foreign keys, etc.                   │
│   ├── Rows per batch: Commit interval                                  │
│   └── Maximum insert commit size: Memory limit                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### SQL Server Destination

Optimized for local SQL Server (same machine).

```
Advantages:
├── Faster than OLE DB for local loads
├── Direct memory sharing
└── Minimal network overhead

Limitations:
├── Only works with local SQL Server
├── Package must run on SQL Server machine
└── Less portable than OLE DB
```

### Flat File Destination

Writes to text files.

```
Configuration:
├── Connection Manager: Flat File connection
├── Overwrite: Replace existing file
├── Append: Add to existing file
├── Column delimiter: Configure separator
├── Text qualifier: Quote character
└── Header row: Include column names
```

### Excel Destination

Writes to Excel workbooks.

```
Limitations:
├── Overwrites entire sheet
├── 64-bit compatibility issues
├── Row limit (1,048,576 in xlsx)
└── No append mode (workaround with templates)
```

### Recordset Destination

Stores data in a memory variable.

```
Use Cases:
├── Store lookup data for later use
├── Pass data between Data Flows
├── Use in Foreach Loop for row processing
└── Cache small datasets

Configuration:
├── VariableName: Object variable to store data
└── Use ADO Enumerator in Foreach Loop
```

---

## 🔀 Data Flow Paths

### Understanding Paths

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       DATA FLOW PATHS                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Regular Path (Green arrow):                                           │
│   ┌─────────┐         ┌─────────┐                                       │
│   │ Source  │────────▶│Transform│                                       │
│   └─────────┘         └─────────┘                                       │
│       Main output → Normal data flow                                    │
│                                                                          │
│   Error Path (Red arrow):                                               │
│   ┌─────────┐         ┌─────────┐                                       │
│   │Transform│─ ─ ─ ─ ▶│  Error  │                                       │
│   └─────────┘  (red)  │  Dest   │                                       │
│       Error rows redirected for handling                                │
│                                                                          │
│   Split Paths (Multiple outputs):                                       │
│   ┌─────────────────┐                                                   │
│   │  Conditional    │                                                   │
│   │    Split        │                                                   │
│   └────────┬────────┘                                                   │
│       ┌────┴────┬────────┬────────┐                                     │
│       ▼         ▼        ▼        ▼                                     │
│   [Output1] [Output2] [Output3] [Default]                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Error Handling in Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ERROR OUTPUT CONFIGURATION                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   For each column, configure error handling:                            │
│                                                                          │
│   Error:                        Truncation:                             │
│   ├── Fail Component           ├── Fail Component                       │
│   ├── Ignore Failure           ├── Ignore Failure                       │
│   └── Redirect Row             └── Redirect Row                         │
│                                                                          │
│   Common Pattern - Log Error Rows:                                      │
│                                                                          │
│   ┌─────────┐      Success     ┌─────────┐                              │
│   │ Lookup  │─────────────────▶│  Dest   │                              │
│   └────┬────┘                  └─────────┘                              │
│        │                                                                 │
│        │ Error                                                           │
│        ▼                                                                 │
│   ┌─────────┐     ┌─────────┐                                           │
│   │ Derived │────▶│  Error  │                                           │
│   │ Column  │     │  Table  │                                           │
│   └─────────┘     └─────────┘                                           │
│   (Add error info: ErrorCode, ErrorColumn)                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Viewers

Data Viewers let you see data flowing through the pipeline during debug.

```
Types of Data Viewers:
├── Grid: Display data in a table format
├── Histogram: Show data distribution
├── Scatter Plot: Show relationship between columns
└── Column Chart: Show values as bars

Usage:
1. Right-click on path (green arrow)
2. Select "Enable Data Viewer"
3. Configure columns to display
4. Run in debug mode
5. Data pauses at viewer for inspection
```

---

## 📊 Buffer Management

### Understanding Buffers

SSIS processes data in **buffers** - memory blocks that hold rows.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       BUFFER ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Source reads rows into buffers                                        │
│                                                                          │
│   ┌───────────────────────────────────────────────────────────────────┐ │
│   │                        BUFFER (default 10MB)                       │ │
│   │  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐   │ │
│   │  │Row 1│Row 2│Row 3│Row 4│Row 5│Row 6│Row 7│Row 8│Row 9│ ... │   │ │
│   │  └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘   │ │
│   └───────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│   Transformations process entire buffers, not individual rows           │
│   (This is why SSIS is fast - batch processing)                        │
│                                                                          │
│   Synchronous Transformation:                                           │
│   - Modifies rows IN PLACE in the buffer                               │
│   - Same buffer passed through                                          │
│   - Very efficient                                                       │
│   - Examples: Derived Column, Data Conversion                           │
│                                                                          │
│   Asynchronous Transformation:                                          │
│   - Creates NEW buffers                                                  │
│   - Must wait for all input before output                               │
│   - Memory intensive                                                     │
│   - Examples: Sort, Aggregate                                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Buffer Configuration

```python
# Key Properties (Data Flow Task)
DefaultBufferSize = 10485760  # 10 MB default, max 100 MB
DefaultBufferMaxRows = 10000  # Maximum rows per buffer
EngineThreads = 10           # Parallel execution threads

# Calculate optimal settings:
# BufferSize = RowSize × RowsPerBuffer
# For wide rows (many columns): Increase buffer size
# For narrow rows: Increase max rows
```

---

## 🔧 Common Data Flow Patterns

### Pattern 1: Simple Extract and Load

```
┌────────────┐    ┌────────────┐    ┌────────────┐
│  OLE DB    │───▶│   Data     │───▶│  OLE DB    │
│  Source    │    │ Conversion │    │   Dest     │
└────────────┘    └────────────┘    └────────────┘
```

### Pattern 2: Lookup and Enrich

```
┌────────────┐    ┌────────────┐    ┌────────────┐
│  Source    │───▶│  Lookup    │───▶│   Dest     │
└────────────┘    └─────┬──────┘    └────────────┘
                        │
                        │ (Reference)
                  ┌─────▼──────┐
                  │ Lookup     │
                  │  Table     │
                  └────────────┘
```

### Pattern 3: Split and Route

```
                  ┌────────────┐
                  │  Source    │
                  └─────┬──────┘
                        │
                  ┌─────▼──────┐
                  │Conditional │
                  │   Split    │
                  └─────┬──────┘
         ┌──────────────┼──────────────┐
         ▼              ▼              ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │ Insert  │    │ Update  │    │ Archive │
    │  Dest   │    │  Dest   │    │  Dest   │
    └─────────┘    └─────────┘    └─────────┘
```

### Pattern 4: Union Multiple Sources

```
┌────────────┐    ┌────────────┐    ┌────────────┐
│ Source 1   │──┐                              
└────────────┘  │                              
                ├──▶┌──────────┐───▶┌──────────┐
┌────────────┐  │   │ Union    │    │  Dest    │
│ Source 2   │──┤   │  All     │    │          │
└────────────┘  │   └──────────┘    └──────────┘
                │                              
┌────────────┐  │                              
│ Source 3   │──┘                              
└────────────┘                                 
```

---

## 🎓 Interview Questions

### Q1: What is a Data Flow in SSIS?
**A:** Data Flow is the component that handles data extraction, transformation, and loading. It runs inside a Data Flow Task in the Control Flow and contains sources, transformations, and destinations connected by paths.

### Q2: What is the difference between OLE DB Source and ADO.NET Source?
**A:**
- **OLE DB**: Uses OLE DB providers, better for SQL Server and Oracle, supports parameterized queries
- **ADO.NET**: Uses .NET providers, better Unicode support, good for .NET-specific providers

OLE DB is generally faster for SQL Server; ADO.NET is more flexible.

### Q3: What is Fast Load in OLE DB Destination?
**A:** Fast Load uses bulk insert operations for much faster loading. It bypasses row-by-row insert and uses SQL Server's bulk copy capabilities. Options include:
- Keep Identity
- Keep Nulls  
- Table Lock
- Check Constraints
- Batch size configuration

### Q4: What is the difference between synchronous and asynchronous transformations?
**A:**
- **Synchronous**: Processes rows in place using same buffer, very fast (Derived Column, Data Conversion)
- **Asynchronous**: Creates new buffers, must collect all input first, memory intensive (Sort, Aggregate)

Prefer synchronous transformations when possible.

### Q5: How do you handle errors in Data Flow?
**A:**
1. Configure **Error Output** on components
2. Options: Fail Component, Ignore Failure, Redirect Row
3. Route error rows to separate destination
4. Add columns for ErrorCode and ErrorColumn
5. Log errors for later analysis

### Q6: What is a Data Viewer?
**A:** Data Viewer is a debugging tool that displays data flowing through paths during package execution. Types include Grid, Histogram, Scatter Plot, and Column Chart. Helps troubleshoot data issues.

### Q7: What is buffer management in SSIS?
**A:** SSIS processes data in memory blocks called buffers. Key settings:
- **DefaultBufferSize**: Buffer size in bytes (default 10MB)
- **DefaultBufferMaxRows**: Max rows per buffer
- Larger buffers = fewer I/O operations but more memory

### Q8: How do you improve Data Flow performance?
**A:**
1. Use **Fast Load** for destinations
2. Prefer **synchronous** transformations
3. Increase **buffer size** for wide rows
4. Filter at **source** (SQL WHERE clause)
5. Remove **unnecessary columns**
6. Avoid **Sort** transformation (sort at source)
7. Use **parallel execution** when possible

### Q9: What is the difference between Union All and Merge?
**A:**
- **Union All**: Combines multiple inputs, no sorting required, faster
- **Merge**: Combines two sorted inputs, maintains sort order

Use Union All unless you specifically need maintained sort order.

### Q10: How do you read data from multiple files?
**A:**
1. Use **Foreach Loop Container** with File Enumerator
2. Store filename in variable
3. Configure **Flat File Connection** to use variable
4. Data Flow reads current file
5. Loop processes all files

---

## 🔗 Related Topics
- [← Control Flow](./02_control_flow.md)
- [Transformations →](./04_transformations.md)
- [Error Handling →](./05_error_handling.md)

---

*Next: Learn about SSIS Transformations*
