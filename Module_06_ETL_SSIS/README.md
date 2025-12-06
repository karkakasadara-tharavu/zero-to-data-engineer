# Module 06: ETL with SSIS

**Duration**: 2 weeks (40-60 hours) | **Difficulty**: ⭐⭐⭐⭐ Advanced

## 📖 Overview
Master SQL Server Integration Services (SSIS) for building enterprise ETL pipelines: extract data from multiple sources, transform it, and load into data warehouses.

---

## 📚 Module Structure

| Section | Topic | Labs | Time |
|---------|-------|------|------|
| 01 | SSIS Architecture & Setup | 1 | 4h |
| 02 | Control Flow Tasks | 3 | 6h |
| 03 | Data Flow Components | 4 | 8h |
| 04 | Transformations | 3 | 7h |
| 05 | Connection Managers & Configurations | 2 | 5h |
| 06 | Error Handling & Logging | 2 | 5h |
| 07 | Package Deployment | 1 | 3h |
| **Capstone** | Data Warehouse ETL Pipeline | 1 | 10h |

**Total**: 17 labs, 2 quizzes, 48 hours

---

## 🛠️ Prerequisites

**Install SQL Server Data Tools (SSDT)**:
1. Download Visual Studio 2022 Community
2. Install "SQL Server Integration Services Projects" extension
3. Create new Integration Services Project

---

## 🎯 Key Components

### Control Flow
- **Execute SQL Task**: Run T-SQL statements
- **Data Flow Task**: Extract, transform, load data
- **File System Task**: Copy, move, delete files
- **Script Task**: C# custom logic
- **Foreach Loop Container**: Iterate over files/rows
- **Sequence Container**: Group tasks
- **Precedence Constraints**: Control execution flow

### Data Flow
**Sources**:
- OLE DB Source (SQL Server)
- Flat File Source (CSV, TXT)
- Excel Source
- ADO.NET Source

**Transformations**:
- Derived Column (calculated fields)
- Lookup (reference data)
- Conditional Split (routing)
- Aggregate (GROUP BY)
- Data Conversion (data types)
- Merge Join (combine datasets)
- Sort

**Destinations**:
- OLE DB Destination (SQL Server)
- Flat File Destination
- Excel Destination

---

## 📋 Example Package

**Scenario**: Load daily sales CSV into SQL Server

**Control Flow**:
1. Execute SQL Task: Truncate staging table
2. Data Flow Task: Load CSV → Transform → Insert
3. Execute SQL Task: Merge staging to production

**Data Flow**:
```
Flat File Source (Sales.csv)
    ↓
Derived Column (Add LoadDate = GETDATE())
    ↓
Data Conversion (Convert dates, decimals)
    ↓
Conditional Split (Filter invalid records)
    ↓
OLE DB Destination (StagingSales table)
```

**Variables**:
- `FilePath`: Path to CSV file
- `LoadDate`: Current date
- `ErrorCount`: Track failures

**Logging**:
- OnError event → Write to ErrorLog table
- OnPostExecute → Record row counts

---

## 🚀 Best Practices

✅ Use staging tables before production load  
✅ Implement error handling (event handlers)  
✅ Log row counts and execution times  
✅ Parameterize connections (dev, test, prod)  
✅ Use transactions for atomic loads  
✅ Optimize buffer sizes for large datasets  
✅ Schedule with SQL Server Agent  

---

## 📝 Labs

**Labs 53-55**: Control flow (SQL tasks, loops, containers)  
**Labs 56-59**: Data flow (sources, destinations, basic transformations)  
**Labs 60-62**: Advanced transformations (Lookup, Merge Join, Aggregate)  
**Labs 63-64**: Variables, expressions, configurations  
**Labs 65-66**: Error handling and logging  
**Lab 67**: Deploy to SSIS Catalog  
**Lab 68**: Capstone - Complete ETL pipeline (CSV + SQL → Data Warehouse)

---

## 🎓 Assessment
- Labs: 40%
- Quiz 09 (Week 1): 15%
- Quiz 10 (Week 2): 15%
- Capstone: 30%

---

**Next**: [Module 07: Advanced ETL Patterns →](../Module_07_Advanced_ETL/README.md)
