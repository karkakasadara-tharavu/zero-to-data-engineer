# Module 12: Data Processing with Pandas

## Theory Section 03: Data Loading and File I/O

### Learning Objectives
- Master reading data from various file formats
- Learn to write DataFrames to different formats
- Understand file I/O parameters and options
- Handle large files efficiently
- Work with compressed files

### Reading CSV Files

CSV (Comma-Separated Values) is the most common format for data exchange.

#### Basic CSV Reading

```python
import pandas as pd

# Basic read
df = pd.read_csv('data.csv')

# Specify delimiter
df = pd.read_csv('data.tsv', sep='\t')     # Tab-separated
df = pd.read_csv('data.txt', sep='|')      # Pipe-separated

# Read from URL
url = 'https://example.com/data.csv'
df = pd.read_csv(url)
```

#### CSV Reading Options

```python
# Specify index column
df = pd.read_csv('data.csv', index_col=0)              # First column as index
df = pd.read_csv('data.csv', index_col='employee_id')  # Specific column

# Select specific columns
df = pd.read_csv('data.csv', usecols=['name', 'age', 'salary'])
df = pd.read_csv('data.csv', usecols=[0, 2, 3])        # By position

# Skip rows
df = pd.read_csv('data.csv', skiprows=2)               # Skip first 2 rows
df = pd.read_csv('data.csv', skiprows=[0, 2, 5])       # Skip specific rows
df = pd.read_csv('data.csv', skip_blank_lines=True)

# Limit rows
df = pd.read_csv('data.csv', nrows=1000)               # Read first 1000 rows

# Handle headers
df = pd.read_csv('data.csv', header=None)              # No header row
df = pd.read_csv('data.csv', header=0)                 # First row is header
df = pd.read_csv('data.csv', names=['A', 'B', 'C'])    # Custom column names

# Handle missing values
df = pd.read_csv('data.csv', na_values=['NA', 'N/A', 'null', ''])
df = pd.read_csv('data.csv', na_values={'col1': ['NA'], 'col2': [-999]})

# Data types
df = pd.read_csv('data.csv', dtype={'age': int, 'salary': float})
df = pd.read_csv('data.csv', dtype='str')              # All columns as strings

# Date parsing
df = pd.read_csv('data.csv', parse_dates=['date_column'])
df = pd.read_csv('data.csv', parse_dates=[0, 1])       # Multiple date columns
df = pd.read_csv('data.csv', date_parser=lambda x: pd.to_datetime(x, format='%d/%m/%Y'))

# Handle encoding
df = pd.read_csv('data.csv', encoding='utf-8')
df = pd.read_csv('data.csv', encoding='latin-1')

# Compression (automatic detection)
df = pd.read_csv('data.csv.gz')
df = pd.read_csv('data.csv.zip')
df = pd.read_csv('data.csv.bz2')
```

#### Reading Large CSV Files

```python
# Read in chunks
chunk_iter = pd.read_csv('large_file.csv', chunksize=10000)

# Process chunks
for chunk in chunk_iter:
    # Process each chunk
    result = chunk.groupby('category')['value'].sum()
    print(result)

# Combine chunks
chunks = []
for chunk in pd.read_csv('large_file.csv', chunksize=10000):
    # Filter or process chunk
    filtered = chunk[chunk['value'] > 100]
    chunks.append(filtered)

df = pd.concat(chunks, ignore_index=True)

# Use low_memory option for mixed types
df = pd.read_csv('large_file.csv', low_memory=False)
```

### Writing CSV Files

```python
# Basic write
df.to_csv('output.csv')

# Without index
df.to_csv('output.csv', index=False)

# Custom separator
df.to_csv('output.tsv', sep='\t')

# Select columns
df.to_csv('output.csv', columns=['name', 'age'])

# Handle missing values
df.to_csv('output.csv', na_rep='NULL')

# Compression
df.to_csv('output.csv.gz', compression='gzip')
df.to_csv('output.csv.zip', compression='zip')

# Encoding
df.to_csv('output.csv', encoding='utf-8')

# Append to existing file
df.to_csv('output.csv', mode='a', header=False)

# Custom float format
df.to_csv('output.csv', float_format='%.2f')
```

### Reading Excel Files

```python
# Basic read
df = pd.read_excel('data.xlsx')

# Specify sheet
df = pd.read_excel('data.xlsx', sheet_name='Sheet1')
df = pd.read_excel('data.xlsx', sheet_name=0)         # First sheet (0-indexed)

# Read multiple sheets
sheets_dict = pd.read_excel('data.xlsx', sheet_name=None)  # All sheets
sheets_dict = pd.read_excel('data.xlsx', sheet_name=['Sheet1', 'Sheet2'])

# Iterate over sheets
for sheet_name, df in sheets_dict.items():
    print(f"Processing {sheet_name}")
    print(df.head())

# Excel-specific options
df = pd.read_excel('data.xlsx',
                   sheet_name='Data',
                   header=0,
                   index_col=0,
                   usecols='A:D',                    # Columns A to D
                   skiprows=2,
                   nrows=100)

# Requires openpyxl or xlrd
# pip install openpyxl
```

### Writing Excel Files

```python
# Basic write
df.to_excel('output.xlsx', index=False)

# Write multiple sheets
with pd.ExcelWriter('output.xlsx') as writer:
    df1.to_excel(writer, sheet_name='Sheet1', index=False)
    df2.to_excel(writer, sheet_name='Sheet2', index=False)
    df3.to_excel(writer, sheet_name='Sheet3', index=False)

# Formatting with xlsxwriter
writer = pd.ExcelWriter('output.xlsx', engine='xlsxwriter')
df.to_excel(writer, sheet_name='Data', index=False)

workbook = writer.book
worksheet = writer.sheets['Data']

# Add formatting
header_format = workbook.add_format({
    'bold': True,
    'bg_color': '#D3D3D3',
    'border': 1
})

# Apply formatting
for col_num, value in enumerate(df.columns.values):
    worksheet.write(0, col_num, value, header_format)

writer.close()
```

### Reading JSON Files

```python
# Basic read
df = pd.read_json('data.json')

# Specify orient
df = pd.read_json('data.json', orient='records')
# orient options: 'split', 'records', 'index', 'columns', 'values'

# From JSON string
json_str = '[{"name": "Alice", "age": 25}, {"name": "Bob", "age": 30}]'
df = pd.read_json(json_str)

# Normalize nested JSON
from pandas import json_normalize

nested_json = [
    {'name': 'Alice', 'info': {'age': 25, 'city': 'NYC'}},
    {'name': 'Bob', 'info': {'age': 30, 'city': 'LA'}}
]
df = json_normalize(nested_json)

# Handle complex nested structures
df = json_normalize(data,
                    record_path='employees',
                    meta=['company', 'location'])
```

### Writing JSON Files

```python
# Basic write
df.to_json('output.json')

# Specify orient
df.to_json('output.json', orient='records')
df.to_json('output.json', orient='records', lines=True)  # JSON Lines format

# Pretty print
df.to_json('output.json', orient='records', indent=4)

# Handle dates
df.to_json('output.json', date_format='iso')
df.to_json('output.json', date_unit='ms')
```

### Reading from Databases

#### SQLite

```python
import sqlite3

# Create connection
conn = sqlite3.connect('database.db')

# Read table
df = pd.read_sql('SELECT * FROM employees', conn)

# With query parameters
query = 'SELECT * FROM employees WHERE salary > ?'
df = pd.read_sql(query, conn, params=(50000,))

# Read entire table
df = pd.read_sql_table('employees', conn)

# Close connection
conn.close()
```

#### PostgreSQL/MySQL

```python
from sqlalchemy import create_engine

# PostgreSQL
engine = create_engine('postgresql://user:password@localhost:5432/database')

# MySQL
engine = create_engine('mysql+pymysql://user:password@localhost:3306/database')

# Read data
df = pd.read_sql('SELECT * FROM employees', engine)
df = pd.read_sql_query('SELECT * FROM employees WHERE salary > 50000', engine)
df = pd.read_sql_table('employees', engine)

# Write data
df.to_sql('new_table', engine, if_exists='replace', index=False)
# if_exists options: 'fail', 'replace', 'append'

# Chunk writing for large DataFrames
df.to_sql('large_table', engine, if_exists='replace', index=False, chunksize=1000)
```

### Reading HTML Tables

```python
# Read all tables from a webpage
tables = pd.read_html('https://example.com/data.html')

# First table
df = tables[0]

# With specific attributes
tables = pd.read_html('https://example.com/data.html',
                      attrs={'class': 'data-table'},
                      header=0)

# From local HTML file
tables = pd.read_html('data.html')
```

### Reading Parquet Files

Parquet is a columnar storage format optimized for analytics.

```python
# Basic read
df = pd.read_parquet('data.parquet')

# Specify engine (pyarrow or fastparquet)
df = pd.read_parquet('data.parquet', engine='pyarrow')

# Select columns
df = pd.read_parquet('data.parquet', columns=['name', 'age'])

# Write parquet
df.to_parquet('output.parquet', index=False)
df.to_parquet('output.parquet', compression='gzip')
# compression options: 'snappy', 'gzip', 'brotli', None

# Requires: pip install pyarrow or pip install fastparquet
```

### Reading Other Formats

```python
# Pickle (Python binary format)
df = pd.read_pickle('data.pkl')
df.to_pickle('output.pkl')

# HDF5 (Hierarchical Data Format)
df = pd.read_hdf('data.h5', key='data')
df.to_hdf('output.h5', key='data', mode='w')

# Feather (fast binary format)
df = pd.read_feather('data.feather')
df.to_feather('output.feather')

# Clipboard
df = pd.read_clipboard()
df.to_clipboard()

# From text/string
from io import StringIO
csv_string = "name,age\nAlice,25\nBob,30"
df = pd.read_csv(StringIO(csv_string))
```

### Handling File Encoding Issues

```python
# Try different encodings
encodings = ['utf-8', 'latin-1', 'iso-8859-1', 'cp1252']

for encoding in encodings:
    try:
        df = pd.read_csv('data.csv', encoding=encoding)
        print(f"Success with {encoding}")
        break
    except UnicodeDecodeError:
        print(f"Failed with {encoding}")
        continue

# Detect encoding
import chardet

with open('data.csv', 'rb') as f:
    result = chardet.detect(f.read(100000))
    encoding = result['encoding']

df = pd.read_csv('data.csv', encoding=encoding)

# Handle errors
df = pd.read_csv('data.csv', encoding='utf-8', encoding_errors='ignore')
df = pd.read_csv('data.csv', encoding='utf-8', encoding_errors='replace')
```

### Performance Tips

```python
# 1. Specify data types (saves memory)
dtypes = {
    'id': 'int32',
    'name': 'category',  # For low-cardinality strings
    'value': 'float32'
}
df = pd.read_csv('data.csv', dtype=dtypes)

# 2. Use categorical for repeating strings
df['category'] = df['category'].astype('category')

# 3. Read only needed columns
df = pd.read_csv('data.csv', usecols=['col1', 'col2', 'col3'])

# 4. Use chunks for large files
chunks = []
for chunk in pd.read_csv('large.csv', chunksize=50000):
    # Process and filter
    processed = chunk[chunk['value'] > 0]
    chunks.append(processed)
df = pd.concat(chunks, ignore_index=True)

# 5. Use Parquet for large datasets
df.to_parquet('data.parquet', compression='snappy')  # Fast write
df = pd.read_parquet('data.parquet')  # Fast read
```

### Best Practices

1. **Use appropriate formats:**
   - CSV: Universal, human-readable
   - Parquet: Fast, compressed, typed
   - Excel: Business users, formatting
   - JSON: APIs, nested data

2. **Specify types:** Always specify dtypes when possible
3. **Handle missing values:** Define na_values explicitly
4. **Use compression:** For large files (gzip, snappy)
5. **Read only needed data:** Use usecols and nrows
6. **Close connections:** Always close database connections
7. **Validate data:** Check data after loading

### Common Patterns

```python
# Pattern 1: Load, clean, save
df = pd.read_csv('raw_data.csv')
df = df.dropna()
df = df[df['value'] > 0]
df.to_parquet('cleaned_data.parquet')

# Pattern 2: Process in chunks
def process_large_file(filename):
    chunks = []
    for chunk in pd.read_csv(filename, chunksize=10000):
        # Clean and filter
        chunk = chunk.dropna()
        chunk = chunk[chunk['value'] > 0]
        chunks.append(chunk)
    return pd.concat(chunks, ignore_index=True)

# Pattern 3: Multiple files
import glob

dfs = []
for file in glob.glob('data_*.csv'):
    df = pd.read_csv(file)
    dfs.append(df)

combined = pd.concat(dfs, ignore_index=True)
```

### Summary

- Use `read_csv()` for CSV files with many options
- Use `read_excel()` for Excel workbooks
- Use `read_json()` for JSON data
- Use `read_sql()` for databases
- Use `read_parquet()` for high-performance binary format
- Always specify encoding, dtypes, and handle missing values
- Process large files in chunks
- Use appropriate formats for your use case

### Key Takeaways

1. Pandas supports many file formats
2. CSV is most common but Parquet is more efficient
3. Specify data types to save memory
4. Use chunks for large files
5. Handle encoding issues explicitly
6. Compress output files when possible

---

**Practice Exercise:**

1. Read a CSV file with at least 3 columns
2. Write it to Excel with formatted headers
3. Write it to JSON in records format
4. Write it to Parquet with compression
5. Compare file sizes
6. Read the Parquet file and compare performance
