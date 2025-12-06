# Section 3: AdventureWorks Sample Database Setup

**Estimated Time**: 60 minutes  
**Difficulty**: ⭐⭐ Beginner-Intermediate  
**Result**: Industry-standard sample database for 100+ labs

---

## 🎯 What is AdventureWorks?

**AdventureWorks** is Microsoft's official sample database that simulates a **fictional bicycle manufacturing company**. It's the gold standard for learning SQL Server.

### Why Use AdventureWorks?

✅ **Realistic data**: 70+ tables with actual business relationships  
✅ **Multiple scenarios**: Sales, HR, Production, Purchasing  
✅ **Industry standard**: Used in training worldwide  
✅ **Rich relationships**: Foreign keys, complex joins  
✅ **Different complexities**: Lightweight to full versions  
✅ **Pre-loaded data**: ~20,000+ rows across tables  

### What You'll Use It For

- **Module 02-03**: SQL query practice (SELECT, JOIN, aggregations)
- **Module 04**: Database administration tasks (indexing, optimization)
- **Module 05**: T-SQL programming (stored procedures, functions)
- **Module 06-07**: ETL source/target for SSIS packages
- **Module 08**: Power BI reporting and dashboard creation
- **Module 09**: Capstone project foundation

**Bottom line**: AdventureWorks is your training ground for becoming a data engineer! 🚀

---

## 📊 AdventureWorks Versions Explained

Microsoft provides two versions. You'll install **both** for different use cases.

### 1. AdventureWorksLT (Lightweight)

**Best For**: Quick testing, learning JOINs, simple queries

**Characteristics**:
- **Size**: ~1 MB (tiny!)
- **Tables**: 10 tables
- **Focus**: Sales data only
- **Relationships**: Simple (easy to understand)

**Tables Include**:
- `SalesLT.Customer`
- `SalesLT.Product`
- `SalesLT.SalesOrderHeader`
- `SalesLT.SalesOrderDetail`
- `SalesLT.Address`
- `SalesLT.ProductCategory`

**Use Cases**:
- ✅ Learning basic JOINs
- ✅ Quick query testing
- ✅ Simple ETL practice
- ✅ Beginner labs

---

### 2. AdventureWorks2022 (Full Version)

**Best For**: Advanced SQL, database administration, realistic projects

**Characteristics**:
- **Size**: ~45 MB
- **Tables**: 70+ tables
- **Schemas**: Sales, Production, Purchasing, HumanResources, Person
- **Relationships**: Complex (real-world scenarios)

**Key Schemas**:

**Sales**: 
- Orders, customers, territories, salesperson commissions
- `Sales.SalesOrderHeader`, `Sales.Customer`, `Sales.SalesPerson`

**Production**:
- Products, inventory, manufacturing, bills of material
- `Production.Product`, `Production.WorkOrder`, `Production.BillOfMaterials`

**HumanResources**:
- Employees, departments, pay history, shifts
- `HumanResources.Employee`, `HumanResources.Department`

**Purchasing**:
- Vendors, purchase orders, shipping
- `Purchasing.Vendor`, `Purchasing.PurchaseOrderHeader`

**Person**:
- People, addresses, phone numbers
- `Person.Person`, `Person.Address`, `Person.EmailAddress`

**Use Cases**:
- ✅ Advanced SQL queries (CTEs, window functions)
- ✅ Database administration (indexing, partitioning)
- ✅ Complex ETL scenarios
- ✅ Data modeling practice
- ✅ Capstone project

---

### Which Version Should You Install?

**Answer: BOTH!** 

- Use **AdventureWorksLT** for Modules 02-03 (learning basics)
- Use **AdventureWorks2022** for Modules 04-09 (advanced work)

Don't worry - both databases can coexist on your SQL Server!

---

## 📥 Step 1: Download AdventureWorks Backup Files

### Official Download Sources

Microsoft hosts sample databases on GitHub.

**Primary Source**:  
🔗 https://github.com/Microsoft/sql-server-samples/releases

**Direct Download Links** (December 2025 - latest):

**AdventureWorksLT2022 (Lightweight)**:  
🔗 https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak

**AdventureWorks2022 (Full)**:  
🔗 https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak

---

### Download Both Files

**Method 1: Browser Download**

1. **Click each link above**
2. Browser will download `.bak` files
3. **Save to**: `C:\Temp\` (create folder if it doesn't exist)

**Method 2: PowerShell Download** (faster, reliable)

```powershell
# Create download folder
New-Item -Path "C:\Temp" -ItemType Directory -Force

# Download AdventureWorksLT2022
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak" -OutFile "C:\Temp\AdventureWorksLT2022.bak"

# Download AdventureWorks2022
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak" -OutFile "C:\Temp\AdventureWorks2022.bak"

# Verify downloads
Get-ChildItem -Path "C:\Temp\*.bak" | Select-Object Name, Length
```

**Expected Output**:
```
Name                      Length
----                      ------
AdventureWorksLT2022.bak  1048576   (1 MB)
AdventureWorks2022.bak    47185920  (45 MB)
```

<!-- 🎨 PLACEHOLDER: Screenshot of PowerShell download output -->

**⏱️ Wait Time**: 2-5 minutes (depending on internet speed)

---

### What is a .bak File?

**`.bak`** = **SQL Server backup file**

**Think of it as**:
- 📦 **Compressed snapshot** of entire database
- 💾 **Contains**: All tables, data, indexes, stored procedures, functions
- 🔄 **Portable**: Can restore on any SQL Server instance

**Restore process**: SQL Server decompresses and rebuilds database from .bak file.

---

## 🗄️ Step 2: Understand Restore Process

### What Happens During Restore

1. **SQL Server reads** .bak file
2. **Extracts** database structure (tables, indexes, etc.)
3. **Imports** all data rows
4. **Rebuilds** indexes for performance
5. **Creates** data and log files (.mdf, .ldf)
6. **Registers** database in SQL Server

**Analogy**: Like unzipping a complete website backup - structure and content restored!

---

### Where Will Databases Be Created?

**Default Location** (SQL Server Express):
```
C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\
```

**Files Created**:
- `AdventureWorksLT2022.mdf` (data file)
- `AdventureWorksLT2022_log.ldf` (transaction log file)
- `AdventureWorks2022.mdf` (data file)
- `AdventureWorks2022_log.ldf` (transaction log file)

**Don't worry** - SSMS handles file paths automatically during restore!

---

## 🔧 Step 3: Restore AdventureWorksLT2022 (Lightweight) - GUI Method

### Open SSMS

1. **Launch SSMS**
2. **Connect** to `localhost\SQLEXPRESS`
3. **Expand** Object Explorer

---

### Start Restore Process

1. **Right-click "Databases"** folder (in Object Explorer)
2. **Select "Restore Database..."**

<!-- 🎨 PLACEHOLDER: Screenshot of right-click menu showing Restore Database -->

**Restore Database dialog appears**

---

### Configure Restore - General Page

**Source Section**:
- **Select**: ⚪ **Device** (radio button)
- **Click**: **[...]** button (browse button next to Device)

<!-- 🎨 PLACEHOLDER: Screenshot of Restore Database dialog, Source section -->

---

### Select Backup File

**"Select backup devices" dialog opens**:

1. **Backup media type**: File (dropdown, should be default)
2. **Click "Add"** button

<!-- 🎨 PLACEHOLDER: Screenshot of Select backup devices dialog -->

---

**"Locate Backup File" file browser opens**:

1. **Navigate to**: `C:\Temp\`
2. **Select**: `AdventureWorksLT2022.bak`
3. **Click "OK"**

<!-- 🎨 PLACEHOLDER: Screenshot of file browser with .bak file selected -->

---

**Back to "Select backup devices" dialog**:
- You should see: `C:\Temp\AdventureWorksLT2022.bak` listed
- **Click "OK"**

---

### Verify Backup Set

**Back to main "Restore Database" dialog**:

**Destination Section**:
- **Database**: Should auto-fill as `AdventureWorksLT2022`
- If not, type: `AdventureWorksLT2022`

**Backup sets to restore**:
- **Check the checkbox** next to the backup set (should be only one row)
- Columns show: Database, Backup Component, Type, Server, etc.

<!-- 🎨 PLACEHOLDER: Screenshot showing backup set selected -->

---

### Options Page (Important!)

**Click "Options"** (left side of dialog)

**File relocation section**:
- **"Restore the database files as"**: Table showing logical file names and paths
- **Two rows**:
  - `AdventureWorksLT2022_Data` → `C:\Program Files\...\AdventureWorksLT2022.mdf`
  - `AdventureWorksLT2022_Log` → `C:\Program Files\...\AdventureWorksLT2022_log.ldf`

**Check this option**:
- ✅ **"Overwrite the existing database (WITH REPLACE)"**

**Recovery state**:
- Select: ⚪ **"RESTORE WITH RECOVERY"** (default)

<!-- 🎨 PLACEHOLDER: Screenshot of Options page with settings -->

**Why "Overwrite existing database"?**  
If you're re-restoring (e.g., after mistake), this allows you to replace. Safe for first-time restore too.

---

### Execute Restore

**Click "OK"** button (bottom of dialog)

**What Happens**:
- Progress dialog appears: "Restoring database..."
- **Wait time**: 10-30 seconds (it's a small database)
- **Success message**: "Database 'AdventureWorksLT2022' restored successfully."

<!-- 🎨 PLACEHOLDER: Screenshot of success message -->

**Click "OK"** to dismiss success message.

---

### Verify Restore

**In Object Explorer**:
1. **Right-click "Databases"** folder
2. **Select "Refresh"** (or press F5)

**You should now see**:
- 📁 **AdventureWorksLT2022** (new database!)
- Expand it → **Tables** → **Tables** (not System Tables)

<!-- 🎨 PLACEHOLDER: Screenshot of Object Explorer showing AdventureWorksLT2022 expanded -->

**You should see 10 tables** under `SalesLT` schema:
- `SalesLT.Address`
- `SalesLT.Customer`
- `SalesLT.CustomerAddress`
- `SalesLT.Product`
- `SalesLT.ProductCategory`
- `SalesLT.ProductDescription`
- `SalesLT.ProductModel`
- `SalesLT.ProductModelProductDescription`
- `SalesLT.SalesOrderDetail`
- `SalesLT.SalesOrderHeader`

**🎉 Success! AdventureWorksLT2022 is ready!**

---

## 🔧 Step 4: Restore AdventureWorks2022 (Full) - GUI Method

**Repeat the same process** for the full version.

### Quick Steps (Same as Above)

1. **Right-click "Databases"** → **"Restore Database..."**
2. **Source**: ⚪ Device → **[...]** → **Add**
3. **Browse to**: `C:\Temp\AdventureWorks2022.bak` → **OK** → **OK**
4. **Destination**: `AdventureWorks2022` (auto-filled)
5. **Check** backup set checkbox
6. **Options page** → ✅ **"Overwrite existing database"**
7. **Click "OK"**

**Wait time**: 1-3 minutes (larger database)

**Success message**: "Database 'AdventureWorks2022' restored successfully."

---

### Verify Full Database

**Refresh Databases** (right-click → Refresh)

**Expand AdventureWorks2022**:
- **Schemas**: HumanResources, Person, Production, Purchasing, Sales
- **Tables**: 70+ tables total!

<!-- 🎨 PLACEHOLDER: Screenshot of Object Explorer showing AdventureWorks2022 schemas -->

**Quick count query**:
```sql
USE AdventureWorks2022;

-- Count tables in database
SELECT COUNT(*) AS TotalTables
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
```

**Expected Result**: ~71 tables

**🎉 Both databases restored successfully!**

---

## 💻 Step 5: Restore via SQL Script (Alternative Method)

**Prefer code over GUI?** Here's the SQL script method (same result).

### Restore AdventureWorksLT2022

```sql
-- Restore AdventureWorksLT2022
RESTORE DATABASE AdventureWorksLT2022
FROM DISK = 'C:\Temp\AdventureWorksLT2022.bak'
WITH 
    MOVE 'AdventureWorksLT2012_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\AdventureWorksLT2022.mdf',
    MOVE 'AdventureWorksLT2012_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\AdventureWorksLT2022_log.ldf',
    REPLACE,
    RECOVERY;
GO

-- Verify
SELECT name, database_id, create_date, compatibility_level
FROM sys.databases
WHERE name = 'AdventureWorksLT2022';
GO
```

---

### Restore AdventureWorks2022

```sql
-- Restore AdventureWorks2022
RESTORE DATABASE AdventureWorks2022
FROM DISK = 'C:\Temp\AdventureWorks2022.bak'
WITH 
    MOVE 'AdventureWorks2022' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\AdventureWorks2022.mdf',
    MOVE 'AdventureWorks2022_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\AdventureWorks2022_log.ldf',
    REPLACE,
    RECOVERY;
GO

-- Verify
SELECT name, database_id, create_date, compatibility_level
FROM sys.databases
WHERE name = 'AdventureWorks2022';
GO
```

---

### Understanding the Script

**Line-by-line breakdown**:

```sql
RESTORE DATABASE AdventureWorks2022
```
- **Command**: Restores database from backup
- **Database name**: Target name (what it'll be called)

```sql
FROM DISK = 'C:\Temp\AdventureWorks2022.bak'
```
- **Source**: Path to .bak file

```sql
WITH 
```
- **Options**: Configure restore behavior

```sql
    MOVE 'AdventureWorks2022' TO 'C:\Program Files\...\AdventureWorks2022.mdf',
```
- **MOVE**: Relocates logical file name to physical path
- Logical name (from backup) → Physical path (on your server)
- `.mdf` = **Data file** (contains tables, indexes, data)

```sql
    MOVE 'AdventureWorks2022_log' TO 'C:\Program Files\...\AdventureWorks2022_log.ldf',
```
- `.ldf` = **Log file** (transaction log for recovery)

```sql
    REPLACE,
```
- **REPLACE**: Overwrite if database already exists

```sql
    RECOVERY;
```
- **RECOVERY**: Database ready for use immediately

---

### Troubleshooting Script Errors

**Error**: "Logical file 'XYZ' is not part of database 'ABC'"

**Cause**: Logical file names in script don't match names in .bak file

**Solution**: Check actual logical names in backup:
```sql
-- View logical file names in backup
RESTORE FILELISTONLY 
FROM DISK = 'C:\Temp\AdventureWorks2022.bak';
```

**Output shows**:
| LogicalName | PhysicalName | Type |
|-------------|--------------|------|
| AdventureWorks2022 | ...\AdventureWorks2022.mdf | D (Data) |
| AdventureWorks2022_log | ...\AdventureWorks2022_log.ldf | L (Log) |

**Use these exact LogicalNames** in your MOVE commands.

---

**Error**: "Directory lookup for the file failed"

**Cause**: SQL Server can't access `C:\Temp\` folder

**Solutions**:
1. **Check file exists**: `Test-Path "C:\Temp\AdventureWorks2022.bak"` in PowerShell
2. **Grant permissions**: SQL Server service account needs read access to `C:\Temp\`
3. **Run as admin**: Open SSMS as Administrator

---

## 📊 Step 6: Explore the Databases

### AdventureWorksLT2022 - Quick Tour

```sql
USE AdventureWorksLT2022;
GO

-- View all tables
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
```

---

### Sample Queries to Try

**1. View Customers**
```sql
SELECT TOP 10
    CustomerID,
    FirstName,
    LastName,
    EmailAddress,
    Phone
FROM SalesLT.Customer
ORDER BY CustomerID;
```

**Expected Result**: 10 rows of customer data

---

**2. View Products**
```sql
SELECT TOP 10
    ProductID,
    Name,
    ProductNumber,
    Color,
    ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;
```

**Expected Result**: Top 10 most expensive products

---

**3. Sales Orders Summary**
```sql
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS TotalRevenue,
    AVG(TotalDue) AS AverageOrderValue,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder
FROM SalesLT.SalesOrderHeader;
```

**Expected Result**: Summary statistics of all orders

<!-- 🎨 PLACEHOLDER: Screenshot of query results -->

---

### AdventureWorks2022 - Schema Overview

```sql
USE AdventureWorks2022;
GO

-- Count tables by schema
SELECT 
    TABLE_SCHEMA AS SchemaName,
    COUNT(*) AS TableCount
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
GROUP BY TABLE_SCHEMA
ORDER BY TableCount DESC;
```

**Expected Result**:
| SchemaName | TableCount |
|------------|------------|
| Production | 25 |
| Sales | 17 |
| Person | 13 |
| Purchasing | 8 |
| HumanResources | 6 |
| dbo | 2 |

---

### Explore Key Tables

**Employees**:
```sql
SELECT TOP 10
    BusinessEntityID,
    JobTitle,
    BirthDate,
    HireDate,
    Gender,
    MaritalStatus
FROM HumanResources.Employee
ORDER BY HireDate;
```

---

**Products with Categories**:
```sql
SELECT TOP 10
    p.ProductID,
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    p.ListPrice,
    p.StandardCost
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
ORDER BY p.ListPrice DESC;
```

<!-- 🎨 PLACEHOLDER: Screenshot showing product category JOIN results -->

---

**Sales by Territory**:
```sql
SELECT 
    t.Name AS TerritoryName,
    COUNT(soh.SalesOrderID) AS TotalOrders,
    SUM(soh.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory t ON soh.TerritoryID = t.TerritoryID
GROUP BY t.Name
ORDER BY TotalRevenue DESC;
```

**You're already analyzing business data like a data engineer!** 📊

---

## 🗺️ Step 7: Understand Database Diagrams

### Generate Database Diagram (Visual Relationships)

**Warning**: Database Diagrams require **SQL Server Agent** (not available in Express edition).

**Alternative**: Use **SSMS** to manually view relationships.

---

### View Table Relationships Manually

**Method 1: Dependencies**

1. **Expand** AdventureWorks2022 → **Tables**
2. **Right-click** a table (e.g., `Sales.SalesOrderHeader`)
3. **Select** "View Dependencies"

<!-- 🎨 PLACEHOLDER: Screenshot of View Dependencies dialog -->

Shows:
- **Tables this table depends on** (foreign keys)
- **Tables that depend on this table** (reverse relationships)

---

**Method 2: Table Designer**

1. **Right-click** table (e.g., `Sales.SalesOrderHeader`)
2. **Select** "Design"

**You'll see**:
- Column names, data types, allow nulls
- **Key icon** (🔑) for primary key columns
- **Relationship icon** (🔗) for foreign keys

**Right-click column** → **Relationships** to see foreign key definitions

<!-- 🎨 PLACEHOLDER: Screenshot of Table Designer showing relationships -->

---

### Query-Based Relationship Discovery

**Find all foreign keys in a table**:
```sql
USE AdventureWorks2022;
GO

-- Foreign keys for SalesOrderHeader table
SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS ReferencedTable,
    cr.name AS ReferencedColumn
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
WHERE tp.name = 'SalesOrderHeader'
ORDER BY fk.name;
```

**This shows how tables connect** - critical for understanding data relationships!

---

## 🧪 Step 8: Test Data Integrity

### Verify Row Counts

**AdventureWorksLT2022**:
```sql
USE AdventureWorksLT2022;
GO

-- Row counts for all tables
SELECT 
    t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY RowCount DESC;
```

**Expected Top Tables**:
- `SalesOrderDetail`: ~500+ rows
- `Product`: ~200+ rows
- `Customer`: ~800+ rows

---

**AdventureWorks2022**:
```sql
USE AdventureWorks2022;
GO

-- Top 10 largest tables by row count
SELECT TOP 10
    t.name AS TableName,
    s.name AS SchemaName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY t.name, s.name
ORDER BY RowCount DESC;
```

**Expected Top Tables**:
- `Sales.SalesOrderDetail`: ~120,000+ rows
- `Production.TransactionHistory`: ~100,000+ rows
- `Person.Person`: ~19,000+ rows

<!-- 🎨 PLACEHOLDER: Screenshot of row count query results -->

---

### Check Data Quality

**No NULL values in critical columns**:
```sql
USE AdventureWorks2022;
GO

-- Check for NULL CustomerIDs (should be 0)
SELECT COUNT(*) AS NullCustomerCount
FROM Sales.SalesOrderHeader
WHERE CustomerID IS NULL;
```

**Expected Result**: 0 (no NULLs in primary/foreign key columns)

---

**Date ranges make sense**:
```sql
-- Check order date ranges
SELECT 
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(YEAR, MIN(OrderDate), MAX(OrderDate)) AS YearsOfData
FROM Sales.SalesOrderHeader;
```

**Expected**: ~4-5 years of historical order data

---

## 📚 Step 9: Additional AdventureWorks Resources

### Official Microsoft Documentation

**AdventureWorks Installation Guide**:  
🔗 https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure

**Database Diagram & Schema Overview**:  
🔗 https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms124825(v=sql.105)

**Sample Queries**:  
🔗 https://learn.microsoft.com/en-us/sql/samples/sql-samples-where-are

---

### Third-Party Resources

**DataCamp - AdventureWorks Tutorial**:  
🔗 https://www.datacamp.com/tutorial/sql-server-tutorial

**Stack Overflow - AdventureWorks Questions**:  
🔗 https://stackoverflow.com/questions/tagged/adventureworks

**YouTube: AdventureWorks Database Tour**:  
Search for "AdventureWorks database tutorial" - multiple video tours available

---

## 🛠️ Step 10: Backup Your Databases (Recommended)

### Why Backup?

**Protect your work**: If you accidentally delete data or drop tables during practice, you can restore!

### Create Backup

**GUI Method**:
1. **Right-click** database (e.g., AdventureWorks2022)
2. **Tasks** → **Back Up...**
3. **Backup type**: Full
4. **Destination**: `C:\Temp\AdventureWorks2022_Backup.bak`
5. **Click "OK"**

---

**SQL Method**:
```sql
-- Backup AdventureWorks2022
BACKUP DATABASE AdventureWorks2022
TO DISK = 'C:\Temp\AdventureWorks2022_Backup.bak'
WITH FORMAT, INIT, 
NAME = 'AdventureWorks2022 Full Backup',
COMPRESSION;
GO

-- Backup AdventureWorksLT2022
BACKUP DATABASE AdventureWorksLT2022
TO DISK = 'C:\Temp\AdventureWorksLT2022_Backup.bak'
WITH FORMAT, INIT,
NAME = 'AdventureWorksLT2022 Full Backup',
COMPRESSION;
GO
```

**Result**: Backup files created in `C:\Temp\`

**If you ever need to restore**: Use same process as Step 3-4, but select your backup files!

---

## ✅ Step 11: AdventureWorks Setup Verification Checklist

- [ ] Downloaded both .bak files (AdventureWorksLT2022, AdventureWorks2022)
- [ ] Restored AdventureWorksLT2022 successfully
- [ ] Restored AdventureWorks2022 successfully
- [ ] Both databases visible in Object Explorer
- [ ] AdventureWorksLT2022 has 10 tables (SalesLT schema)
- [ ] AdventureWorks2022 has 70+ tables (multiple schemas)
- [ ] Executed sample queries successfully
- [ ] Verified row counts are realistic
- [ ] Understood schema structure (Sales, Production, HR, etc.)
- [ ] Created backup files for safety

**All checked?** → ✅ **Awesome! You're ready for 100+ labs ahead!**

---

## 🎯 Summary & Next Steps

### What You Accomplished ✅

- ✅ Downloaded official AdventureWorks sample databases
- ✅ Restored both lightweight and full versions
- ✅ Explored database schemas and tables
- ✅ Ran analytical queries on business data
- ✅ Understood table relationships
- ✅ Verified data integrity
- ✅ Created backup copies for safety

### What's Next 🚀

**[Section 4: Verification Tests →](./04_verification_tests.md)**

Run comprehensive SQL scripts to verify your entire setup (SQL Server, SSMS, AdventureWorks) is production-ready!

**Estimated Time**: 30 minutes

---

**You now have real-world data to practice on - just like professional data engineers!** 📊🎉

---

*Last Updated: December 7, 2025*  
*Karka Kasadara - கற்க கசடற - Learn Flawlessly, Grow Together*
