# Pandas File I/O - Complete Guide

## 📚 What You'll Learn
- Reading various file formats
- Writing data to files
- Database connectivity
- Handling large files
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 File Formats Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PANDAS I/O OPERATIONS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│   │     CSV      │    │    Excel     │    │   Parquet    │              │
│   │  read_csv()  │    │ read_excel() │    │read_parquet()│              │
│   │  to_csv()    │    │ to_excel()   │    │ to_parquet() │              │
│   └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                                          │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│   │     JSON     │    │     SQL      │    │    Pickle    │              │
│   │  read_json() │    │  read_sql()  │    │read_pickle() │              │
│   │  to_json()   │    │  to_sql()    │    │ to_pickle()  │              │
│   └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                                          │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│   │     HTML     │    │  Clipboard   │    │     HDF5     │              │
│   │  read_html() │    │read_clipboard│    │ read_hdf()   │              │
│   │  to_html()   │    │to_clipboard()│    │  to_hdf()    │              │
│   └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📄 CSV Files

### Reading CSV

```python
import pandas as pd

# Basic read
df = pd.read_csv('data.csv')

# Common parameters
df = pd.read_csv(
    'data.csv',
    sep=',',              # Delimiter (default: ,)
    header=0,             # Row number for header (0 = first row)
    names=['A', 'B', 'C'], # Custom column names
    index_col='ID',       # Column to use as index
    usecols=['A', 'B'],   # Only read specific columns
    dtype={'A': int, 'B': str},  # Column data types
    parse_dates=['date_column'],  # Parse as datetime
    na_values=['NA', 'N/A', ''],  # Values to treat as NaN
    encoding='utf-8',     # File encoding
    nrows=1000,           # Only read first N rows
    skiprows=10,          # Skip first N rows
    skipfooter=5,         # Skip last N rows
    engine='python',      # Use Python engine for more options
    low_memory=False      # Avoid mixed type inference
)

# Tab-separated
df = pd.read_csv('data.tsv', sep='\t')

# No header
df = pd.read_csv('data.csv', header=None, names=['col1', 'col2', 'col3'])

# Multiple files
import glob
files = glob.glob('data/*.csv')
df = pd.concat([pd.read_csv(f) for f in files], ignore_index=True)
```

### Writing CSV

```python
# Basic write
df.to_csv('output.csv')

# Common options
df.to_csv(
    'output.csv',
    sep=',',
    index=False,          # Don't write index
    header=True,          # Include header
    columns=['A', 'B'],   # Only write specific columns
    na_rep='NULL',        # Represent NaN values
    float_format='%.2f',  # Format floats
    date_format='%Y-%m-%d',  # Date format
    encoding='utf-8',
    mode='w',             # Write mode ('a' for append)
    quoting=1,            # Quote strings (csv.QUOTE_ALL)
    compression='gzip'    # Compress output
)

# Append to existing file
df.to_csv('output.csv', mode='a', header=False)
```

---

## 📊 Excel Files

### Reading Excel

```python
# Basic read
df = pd.read_excel('data.xlsx')

# Specific sheet
df = pd.read_excel('data.xlsx', sheet_name='Sales')

# Multiple sheets
sheets = pd.read_excel('data.xlsx', sheet_name=['Sales', 'Products'])
# Returns dict: {'Sales': df1, 'Products': df2}

# All sheets
sheets = pd.read_excel('data.xlsx', sheet_name=None)

# With parameters
df = pd.read_excel(
    'data.xlsx',
    sheet_name=0,         # First sheet (can use name or index)
    header=0,
    usecols='A:E',        # Column range or list
    skiprows=2,
    nrows=1000,
    dtype={'ID': str},
    engine='openpyxl'     # Engine for .xlsx files
)

# Read specific range
df = pd.read_excel('data.xlsx', usecols='B:D', skiprows=5, nrows=100)
```

### Writing Excel

```python
# Basic write
df.to_excel('output.xlsx', index=False)

# With sheet name
df.to_excel('output.xlsx', sheet_name='Results', index=False)

# Multiple sheets
with pd.ExcelWriter('output.xlsx', engine='openpyxl') as writer:
    df1.to_excel(writer, sheet_name='Sales', index=False)
    df2.to_excel(writer, sheet_name='Products', index=False)
    df3.to_excel(writer, sheet_name='Summary', index=False)

# Formatting with ExcelWriter
with pd.ExcelWriter('output.xlsx', engine='openpyxl') as writer:
    df.to_excel(writer, sheet_name='Data', index=False)
    
    # Access workbook and worksheet for formatting
    workbook = writer.book
    worksheet = writer.sheets['Data']
    
    # Adjust column width
    for column in worksheet.columns:
        worksheet.column_dimensions[column[0].column_letter].width = 15
```

---

## 🗃️ Parquet Files (Columnar Format)

```python
# Reading Parquet
df = pd.read_parquet('data.parquet')

# Specific columns (efficient - only reads requested columns)
df = pd.read_parquet('data.parquet', columns=['A', 'B'])

# Writing Parquet
df.to_parquet('output.parquet', index=False)

# With compression
df.to_parquet(
    'output.parquet',
    compression='snappy',  # snappy, gzip, brotli, etc.
    engine='pyarrow',      # or 'fastparquet'
    index=False
)

# Partitioned Parquet (for large datasets)
df.to_parquet(
    'output_directory',
    partition_cols=['year', 'month'],
    index=False
)
# Creates: output_directory/year=2023/month=01/part.parquet

# Read partitioned Parquet
df = pd.read_parquet('output_directory')
```

**Why Parquet?**
- Columnar storage = faster aggregations
- Efficient compression
- Schema preservation
- Best for analytics workloads

---

## 📝 JSON Files

```python
# Reading JSON
df = pd.read_json('data.json')

# Nested JSON (records orientation)
df = pd.read_json('data.json', orient='records')

# JSON Lines format (one JSON object per line)
df = pd.read_json('data.jsonl', lines=True)

# Writing JSON
df.to_json('output.json')

# Different orientations
df.to_json('output.json', orient='records')  # List of dicts
df.to_json('output.json', orient='split')    # {columns, index, data}
df.to_json('output.json', orient='index')    # Dict of {index: {col: val}}
df.to_json('output.json', orient='columns')  # Dict of {col: {index: val}}
df.to_json('output.json', orient='values')   # Just values (list of lists)
df.to_json('output.json', orient='table')    # JSON Table schema

# Pretty print
df.to_json('output.json', orient='records', indent=2)

# JSON Lines
df.to_json('output.jsonl', orient='records', lines=True)
```

### Handling Nested JSON

```python
import json

# Deeply nested JSON
with open('nested.json') as f:
    data = json.load(f)

# Flatten nested structure
from pandas import json_normalize
df = json_normalize(data, sep='_')

# Specific nested path
df = json_normalize(
    data,
    record_path='items',
    meta=['order_id', ['customer', 'name']]
)
```

---

## 🗄️ SQL Database Connectivity

### SQLAlchemy Connection

```python
from sqlalchemy import create_engine
import pandas as pd

# Connection strings
# SQL Server
engine = create_engine('mssql+pyodbc://user:password@server/database?driver=ODBC+Driver+17+for+SQL+Server')

# PostgreSQL
engine = create_engine('postgresql://user:password@host:5432/database')

# MySQL
engine = create_engine('mysql+pymysql://user:password@host:3306/database')

# SQLite
engine = create_engine('sqlite:///database.db')

# Reading from SQL
df = pd.read_sql('SELECT * FROM customers', engine)

# With parameters
df = pd.read_sql(
    'SELECT * FROM orders WHERE date >= :start_date',
    engine,
    params={'start_date': '2023-01-01'}
)

# Read entire table
df = pd.read_sql_table('customers', engine)

# Writing to SQL
df.to_sql(
    'output_table',
    engine,
    if_exists='replace',  # 'fail', 'replace', 'append'
    index=False,
    chunksize=1000,       # Write in chunks
    dtype={               # Specify SQL types
        'ID': 'INTEGER',
        'Name': 'VARCHAR(100)'
    }
)

# Append data
df.to_sql('existing_table', engine, if_exists='append', index=False)
```

### ODBC with pyodbc

```python
import pyodbc
import pandas as pd

# SQL Server connection
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=servername;'
    'DATABASE=dbname;'
    'UID=username;'
    'PWD=password;'
)

# Read with pandas
df = pd.read_sql('SELECT * FROM table', conn)

# Execute and fetch
cursor = conn.cursor()
cursor.execute('SELECT * FROM table')
rows = cursor.fetchall()

conn.close()
```

---

## 📦 Handling Large Files

### Chunked Reading

```python
# Read in chunks
chunk_size = 100000
chunks = []

for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    # Process each chunk
    processed = chunk[chunk['value'] > 0]
    chunks.append(processed)

df = pd.concat(chunks, ignore_index=True)

# Memory-efficient processing
total = 0
for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    total += chunk['amount'].sum()
```

### Optimize Memory Usage

```python
# Check memory usage
df.info(memory_usage='deep')

# Reduce memory with smaller dtypes
df['int_column'] = df['int_column'].astype('int32')  # Instead of int64
df['float_column'] = df['float_column'].astype('float32')
df['category_column'] = df['category_column'].astype('category')

# Read with optimized types
df = pd.read_csv('data.csv', dtype={
    'ID': 'int32',
    'Status': 'category',
    'Amount': 'float32'
})

# Downcast integers
df['int_col'] = pd.to_numeric(df['int_col'], downcast='integer')
df['float_col'] = pd.to_numeric(df['float_col'], downcast='float')
```

### Dask for Very Large Files

```python
import dask.dataframe as dd

# Read large file with Dask
ddf = dd.read_csv('huge_file.csv')

# Operations are lazy - computed when needed
result = ddf.groupby('category')['value'].sum().compute()

# Convert to Pandas when small enough
small_df = ddf.head(1000)
```

---

## 🌐 Other Formats

### Clipboard

```python
# Read from clipboard (copied Excel/web data)
df = pd.read_clipboard()

# Copy to clipboard
df.to_clipboard(index=False)
```

### HTML Tables

```python
# Read HTML tables from webpage
tables = pd.read_html('https://example.com/data')  # Returns list of DataFrames
df = tables[0]  # First table on page

# Read from file
tables = pd.read_html('page.html')

# Write to HTML
df.to_html('table.html', index=False)
```

### Pickle (Python Serialization)

```python
# Save DataFrame with all metadata
df.to_pickle('data.pkl')

# Load
df = pd.read_pickle('data.pkl')

# Compressed pickle
df.to_pickle('data.pkl.gz', compression='gzip')
```

### Feather (Fast Binary Format)

```python
# Write
df.to_feather('data.feather')

# Read
df = pd.read_feather('data.feather')
```

---

## 🎓 Interview Questions

### Q1: What is the difference between CSV and Parquet formats?
**A:**
- **CSV**: Text format, row-oriented, human-readable, no schema, slower
- **Parquet**: Binary, column-oriented, compressed, schema preserved, faster for analytics

### Q2: How do you handle a CSV file that's too large for memory?
**A:** Use chunked reading:
```python
for chunk in pd.read_csv('large.csv', chunksize=100000):
    process(chunk)
```
Or use Dask for distributed processing.

### Q3: How do you read multiple Excel sheets into a dictionary?
**A:**
```python
sheets = pd.read_excel('file.xlsx', sheet_name=None)  # Returns dict
```

### Q4: How do you write multiple DataFrames to different Excel sheets?
**A:**
```python
with pd.ExcelWriter('output.xlsx') as writer:
    df1.to_excel(writer, sheet_name='Sheet1')
    df2.to_excel(writer, sheet_name='Sheet2')
```

### Q5: How do you optimize memory when reading CSV?
**A:** Specify dtypes, use categories, and downcast numerics:
```python
pd.read_csv('file.csv', dtype={'col': 'int32', 'status': 'category'})
```

### Q6: How do you read/write to a SQL database with Pandas?
**A:**
```python
engine = create_engine('connection_string')
df = pd.read_sql('SELECT * FROM table', engine)
df.to_sql('table', engine, if_exists='append')
```

### Q7: What is JSON Lines format and when do you use it?
**A:** One JSON object per line, used for streaming and large files:
```python
pd.read_json('file.jsonl', lines=True)
df.to_json('output.jsonl', orient='records', lines=True)
```

### Q8: How do you append data to an existing CSV?
**A:**
```python
df.to_csv('file.csv', mode='a', header=False, index=False)
```

### Q9: What is the advantage of Parquet's partitioning?
**A:** Enables partition pruning - only reads relevant files based on filter conditions, dramatically speeding up queries on large datasets.

### Q10: How do you handle nested JSON data?
**A:** Use `json_normalize()`:
```python
from pandas import json_normalize
df = json_normalize(data, sep='_')
```

---

## 🔗 Related Topics
- [← Merging & Joining](./04_merging.md)
- [Python-SQL Integration →](../Module_13_Python_ETL/)
- [PySpark DataFrames →](../Module_15_PySpark/)

---

*Module 12 Complete! Continue to Python for ETL*
