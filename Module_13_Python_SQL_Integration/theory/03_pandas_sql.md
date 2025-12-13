# Pandas-SQL Integration - Complete Guide

## 📚 What You'll Learn
- Reading SQL data into DataFrames
- Writing DataFrames to SQL databases
- Query optimization
- Hybrid SQL-Pandas workflows
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Pandas SQL Functions Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PANDAS-SQL INTEGRATION                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                          pd.read_sql()                          │   │
│   │   Main function - works with both queries and tables            │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│              ┌───────────────┴───────────────┐                          │
│              ▼                               ▼                          │
│   ┌─────────────────────┐         ┌─────────────────────┐               │
│   │  pd.read_sql_query()│         │  pd.read_sql_table()│               │
│   │  Execute SQL query  │         │  Read entire table  │               │
│   └─────────────────────┘         └─────────────────────┘               │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                       df.to_sql()                               │   │
│   │   Write DataFrame to database table                              │   │
│   │   Options: replace, append, fail                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Setting Up Database Connections

### SQLAlchemy Engine (Recommended)

```python
import pandas as pd
from sqlalchemy import create_engine

# SQL Server
engine = create_engine(
    'mssql+pyodbc://username:password@server/database'
    '?driver=ODBC+Driver+17+for+SQL+Server'
)

# PostgreSQL
engine = create_engine('postgresql://user:password@host:5432/database')

# MySQL
engine = create_engine('mysql+pymysql://user:password@host:3306/database')

# SQLite
engine = create_engine('sqlite:///database.db')
```

### Using Connection URL with Credentials

```python
import os
from sqlalchemy import create_engine
from urllib.parse import quote_plus

# Handle special characters in password
password = quote_plus("P@ssw0rd!#")
engine = create_engine(f'mssql+pyodbc://user:{password}@server/db?driver=ODBC+Driver+17+for+SQL+Server')

# From environment variables
db_user = os.getenv('DB_USER')
db_pass = quote_plus(os.getenv('DB_PASSWORD'))
db_host = os.getenv('DB_HOST')
db_name = os.getenv('DB_NAME')

engine = create_engine(f'postgresql://{db_user}:{db_pass}@{db_host}/{db_name}')
```

---

## 📖 Reading Data with pd.read_sql()

### Basic Query

```python
import pandas as pd

# Read from SQL query
df = pd.read_sql("SELECT * FROM Customers", engine)

# Read from table name
df = pd.read_sql("Customers", engine)

# With WHERE clause
df = pd.read_sql(
    "SELECT * FROM Orders WHERE OrderDate >= '2023-01-01'",
    engine
)
```

### Parameterized Queries

```python
from sqlalchemy import text

# Using params dictionary
df = pd.read_sql(
    "SELECT * FROM Orders WHERE CustomerID = :cust_id AND Status = :status",
    engine,
    params={"cust_id": 101, "status": "Completed"}
)

# Or with text() for explicit SQL
df = pd.read_sql(
    text("SELECT * FROM Orders WHERE OrderDate >= :start_date"),
    engine,
    params={"start_date": "2023-01-01"}
)
```

### Column Selection and Data Types

```python
# Specify index column
df = pd.read_sql(
    "SELECT CustomerID, Name, City FROM Customers",
    engine,
    index_col='CustomerID'
)

# Parse dates
df = pd.read_sql(
    "SELECT * FROM Orders",
    engine,
    parse_dates=['OrderDate', 'ShipDate']
)

# Parse dates with format
df = pd.read_sql(
    "SELECT * FROM Orders",
    engine,
    parse_dates={
        'OrderDate': {'format': '%Y-%m-%d'},
        'ShipDate': {'format': '%Y-%m-%d %H:%M:%S'}
    }
)

# Specify column types
df = pd.read_sql(
    "SELECT * FROM Products",
    engine,
    dtype={'ProductID': 'int32', 'Category': 'category'}
)
```

### Chunked Reading for Large Tables

```python
# Read in chunks to manage memory
chunk_size = 100000
chunks = []

for chunk in pd.read_sql(
    "SELECT * FROM LargeTable",
    engine,
    chunksize=chunk_size
):
    # Process each chunk
    processed = chunk[chunk['value'] > 0]
    chunks.append(processed)

df = pd.concat(chunks, ignore_index=True)

# Or process without storing all in memory
for chunk in pd.read_sql("SELECT * FROM LargeTable", engine, chunksize=50000):
    chunk.to_csv(f'output_{chunk.index[0]}.csv', index=False)
```

---

## ✍️ Writing Data with df.to_sql()

### Basic Write

```python
import pandas as pd

df = pd.DataFrame({
    'Name': ['Alice', 'Bob', 'Carol'],
    'City': ['NYC', 'LA', 'Chicago'],
    'Amount': [100, 200, 300]
})

# Write to new table
df.to_sql('NewTable', engine, index=False)
```

### if_exists Parameter

```python
# 'fail' - Raise error if table exists (default)
df.to_sql('MyTable', engine, if_exists='fail')

# 'replace' - Drop table and recreate
df.to_sql('MyTable', engine, if_exists='replace', index=False)

# 'append' - Add rows to existing table
df.to_sql('MyTable', engine, if_exists='append', index=False)
```

### Specifying Data Types

```python
from sqlalchemy import Integer, String, Float, DateTime

df.to_sql(
    'Products',
    engine,
    if_exists='replace',
    index=False,
    dtype={
        'ProductID': Integer(),
        'ProductName': String(100),
        'Price': Float(),
        'CreatedDate': DateTime()
    }
)
```

### Bulk Insert with chunksize

```python
# Insert large DataFrame in chunks
large_df.to_sql(
    'LargeTable',
    engine,
    if_exists='append',
    index=False,
    chunksize=10000,  # Insert 10000 rows at a time
    method='multi'     # Use multi-row INSERT
)
```

### Insert Methods

```python
# Default: one INSERT per row (slow)
df.to_sql('Table', engine)

# Multi-row INSERT (faster)
df.to_sql('Table', engine, method='multi')

# Custom callable for database-specific bulk insert
def postgres_copy(table, conn, keys, data_iter):
    """Use PostgreSQL COPY for fastest insert"""
    import csv
    from io import StringIO
    
    buf = StringIO()
    writer = csv.writer(buf)
    writer.writerows(data_iter)
    buf.seek(0)
    
    raw_conn = conn.connection.connection
    with raw_conn.cursor() as cur:
        cur.copy_from(buf, table.name, sep=',', columns=keys)

df.to_sql('Table', engine, method=postgres_copy)
```

---

## 🔄 Hybrid SQL-Pandas Workflows

### ETL Pattern

```python
import pandas as pd
from sqlalchemy import create_engine, text

source_engine = create_engine('source_connection_string')
target_engine = create_engine('target_connection_string')

# EXTRACT: Read from source
df = pd.read_sql("""
    SELECT 
        CustomerID,
        CustomerName,
        OrderDate,
        Amount
    FROM Orders o
    JOIN Customers c ON o.CustomerID = c.ID
    WHERE OrderDate >= '2023-01-01'
""", source_engine)

# TRANSFORM: Apply business logic
df['OrderYear'] = pd.to_datetime(df['OrderDate']).dt.year
df['AmountCategory'] = pd.cut(
    df['Amount'],
    bins=[0, 100, 500, float('inf')],
    labels=['Small', 'Medium', 'Large']
)
df = df.dropna()

# LOAD: Write to target
df.to_sql(
    'ProcessedOrders',
    target_engine,
    if_exists='replace',
    index=False,
    chunksize=10000
)
```

### Aggregation Pipeline

```python
# Use SQL for filtering and joining (efficient)
df = pd.read_sql("""
    SELECT 
        c.Region,
        o.ProductID,
        p.CategoryName,
        o.Quantity,
        o.UnitPrice
    FROM Orders o
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p ON o.ProductID = p.ProductID
    WHERE o.OrderDate >= '2023-01-01'
""", engine)

# Use Pandas for complex aggregations
summary = (df
    .assign(Revenue=df['Quantity'] * df['UnitPrice'])
    .groupby(['Region', 'CategoryName'])
    .agg({
        'Revenue': 'sum',
        'Quantity': 'sum',
        'ProductID': 'nunique'
    })
    .rename(columns={'ProductID': 'UniqueProducts'})
    .reset_index()
)

# Write aggregated results back
summary.to_sql('RegionalSummary', engine, if_exists='replace', index=False)
```

### Incremental Load Pattern

```python
from datetime import datetime, timedelta

# Get last processed timestamp
with engine.connect() as conn:
    result = conn.execute(text("SELECT MAX(LoadedAt) FROM ProcessedData"))
    last_load = result.scalar() or datetime(2020, 1, 1)

# Extract new records
df = pd.read_sql(
    text("""
        SELECT * FROM SourceData 
        WHERE ModifiedAt > :last_load
    """),
    engine,
    params={"last_load": last_load}
)

if not df.empty:
    # Transform
    df['LoadedAt'] = datetime.now()
    
    # Load (append)
    df.to_sql('ProcessedData', engine, if_exists='append', index=False)
    print(f"Loaded {len(df)} new records")
else:
    print("No new records to process")
```

---

## ⚡ Performance Optimization

### Push Down Filtering

```python
# ❌ Slow: Fetch all, then filter in Pandas
df = pd.read_sql("SELECT * FROM Orders", engine)
df = df[df['Amount'] > 1000]

# ✅ Fast: Filter in SQL (push down predicate)
df = pd.read_sql("SELECT * FROM Orders WHERE Amount > 1000", engine)
```

### Push Down Aggregations

```python
# ❌ Slow: Aggregate in Pandas
df = pd.read_sql("SELECT * FROM Sales", engine)
summary = df.groupby('Region')['Amount'].sum()

# ✅ Fast: Aggregate in SQL
df = pd.read_sql("""
    SELECT Region, SUM(Amount) as TotalAmount
    FROM Sales
    GROUP BY Region
""", engine)
```

### Select Only Needed Columns

```python
# ❌ Slow: SELECT *
df = pd.read_sql("SELECT * FROM WideTable", engine)

# ✅ Fast: Only needed columns
df = pd.read_sql("SELECT ID, Name, Value FROM WideTable", engine)
```

### Use Database Indexes

```python
# Ensure filtered columns are indexed
# Check execution plan for table scans
df = pd.read_sql("""
    SELECT * FROM Orders 
    WHERE CustomerID = 101  -- Make sure CustomerID is indexed
    AND OrderDate >= '2023-01-01'  -- And OrderDate too
""", engine)
```

---

## 🔍 Read Table vs Read Query

```python
# read_sql_table - Read entire table
df = pd.read_sql_table('Customers', engine)

# Advantages:
# - Automatic schema detection
# - Column types preserved
# - Works with table name only

# read_sql_query - Execute custom SQL
df = pd.read_sql_query("SELECT * FROM Customers WHERE Active = 1", engine)

# Advantages:
# - Full SQL flexibility
# - Can join, filter, aggregate
# - Can use CTEs, window functions

# read_sql - Unified interface (recommended)
df = pd.read_sql("Customers", engine)  # Detects table name
df = pd.read_sql("SELECT * FROM Customers", engine)  # Detects query
```

---

## 🎓 Interview Questions

### Q1: What is the difference between read_sql, read_sql_query, and read_sql_table?
**A:**
- **read_sql**: Unified wrapper, auto-detects query vs table name
- **read_sql_query**: Executes a SQL query string
- **read_sql_table**: Reads entire table by name

### Q2: What does if_exists='append' do in to_sql()?
**A:** Adds rows to existing table without deleting existing data. Options are:
- `'fail'`: Raise error if table exists
- `'replace'`: Drop and recreate table
- `'append'`: Add to existing table

### Q3: How do you handle large tables with Pandas?
**A:** Use chunked reading:
```python
for chunk in pd.read_sql("SELECT * FROM LargeTable", engine, chunksize=100000):
    process(chunk)
```

### Q4: How do you optimize read_sql performance?
**A:**
- Push filtering to SQL (WHERE clause)
- Push aggregations to SQL (GROUP BY)
- Select only needed columns
- Ensure proper indexing

### Q5: How do you specify column types in to_sql?
**A:**
```python
from sqlalchemy import Integer, String
df.to_sql('Table', engine, dtype={'ID': Integer(), 'Name': String(100)})
```

### Q6: What is the method='multi' parameter in to_sql?
**A:** Uses multi-row INSERT statements instead of one row per INSERT, significantly faster for bulk inserts.

### Q7: How do you parameterize SQL queries with read_sql?
**A:**
```python
df = pd.read_sql(
    "SELECT * FROM Orders WHERE CustomerID = :cid",
    engine,
    params={"cid": 101}
)
```

### Q8: How do you handle dates when reading SQL?
**A:** Use `parse_dates` parameter:
```python
df = pd.read_sql("SELECT * FROM Orders", engine, parse_dates=['OrderDate'])
```

### Q9: What is the advantage of SQLAlchemy engine over raw connection?
**A:** Provides connection pooling, database abstraction, dialect handling, and better integration with Pandas.

### Q10: How do you do incremental loading with Pandas?
**A:**
```python
# Get max loaded timestamp
last_ts = pd.read_sql("SELECT MAX(LoadedAt) FROM Target", engine).iloc[0, 0]
# Load only new records
df = pd.read_sql(f"SELECT * FROM Source WHERE ModifiedAt > '{last_ts}'", engine)
df.to_sql('Target', engine, if_exists='append')
```

---

## 🔗 Related Topics
- [← Executing SQL Queries](./02_executing_queries.md)
- [ETL with Python →](./04_etl_python.md)
- [PySpark DataFrame Operations →](../Module_15_PySpark/)

---

*Continue to ETL with Python*
