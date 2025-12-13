# Python for Data Engineering - Quick Reference

## 🎯 Purpose
A comprehensive quick reference for Python data engineering patterns. Perfect for interview prep and daily work.

---

## Data Structures

### Lists (Ordered, Mutable)
```python
# Creation
my_list = [1, 2, 3, 4, 5]
my_list = list(range(1, 6))

# Operations
my_list.append(6)           # Add to end
my_list.insert(0, 0)        # Insert at index
my_list.extend([7, 8])      # Add multiple
my_list.pop()               # Remove last (returns it)
my_list.pop(0)              # Remove at index
my_list.remove(3)           # Remove first occurrence
my_list.sort()              # Sort in place
my_list.reverse()           # Reverse in place

# Slicing
my_list[0]                  # First element
my_list[-1]                 # Last element
my_list[1:4]                # Elements 1-3
my_list[::2]                # Every 2nd element
my_list[::-1]               # Reversed

# List comprehension
squares = [x**2 for x in range(10)]
evens = [x for x in range(10) if x % 2 == 0]
```

### Dictionaries (Key-Value, Unordered)
```python
# Creation
my_dict = {'name': 'John', 'age': 30}
my_dict = dict(name='John', age=30)

# Operations
my_dict['email'] = 'john@email.com'  # Add/update
value = my_dict.get('name')           # Safe get (returns None if missing)
value = my_dict.get('phone', 'N/A')   # With default
del my_dict['age']                    # Delete key
my_dict.pop('email')                  # Remove and return

# Iteration
for key in my_dict:
    print(key, my_dict[key])
    
for key, value in my_dict.items():
    print(f"{key}: {value}")

# Dictionary comprehension
squared = {x: x**2 for x in range(5)}
```

### Sets (Unique, Unordered)
```python
# Creation
my_set = {1, 2, 3, 3, 2}  # {1, 2, 3}
my_set = set([1, 2, 3, 3])

# Operations
my_set.add(4)
my_set.remove(1)          # Raises error if not found
my_set.discard(1)         # No error if not found

# Set operations
set_a = {1, 2, 3}
set_b = {2, 3, 4}
set_a | set_b             # Union: {1, 2, 3, 4}
set_a & set_b             # Intersection: {2, 3}
set_a - set_b             # Difference: {1}
set_a ^ set_b             # Symmetric difference: {1, 4}
```

### Tuples (Ordered, Immutable)
```python
# Creation
my_tuple = (1, 2, 3)
my_tuple = 1, 2, 3        # Parentheses optional

# Unpacking
a, b, c = my_tuple
first, *rest = my_tuple   # first=1, rest=[2, 3]

# Named tuples
from collections import namedtuple
Point = namedtuple('Point', ['x', 'y'])
p = Point(3, 4)
print(p.x, p.y)
```

---

## String Operations

```python
# Basic operations
s = "Hello, World!"
len(s)                    # 13
s.upper()                 # HELLO, WORLD!
s.lower()                 # hello, world!
s.title()                 # Hello, World!
s.strip()                 # Remove whitespace
s.split(',')              # ['Hello', ' World!']
','.join(['a', 'b', 'c']) # 'a,b,c'

# Searching
s.find('World')           # 7 (index) or -1 if not found
s.index('World')          # 7 (raises error if not found)
s.count('l')              # 3
'World' in s              # True
s.startswith('Hello')     # True
s.endswith('!')           # True

# Replacing
s.replace('World', 'Python')  # Hello, Python!

# Formatting
name = "John"
age = 30
f"Name: {name}, Age: {age}"           # f-string (preferred)
"Name: {}, Age: {}".format(name, age) # format()
"Name: %s, Age: %d" % (name, age)     # % formatting

# Multiline strings
text = """
This is a
multiline string
"""
```

---

## File Operations

### Reading Files
```python
# Basic read
with open('file.txt', 'r') as f:
    content = f.read()          # Entire file as string
    
with open('file.txt', 'r') as f:
    lines = f.readlines()       # List of lines

with open('file.txt', 'r') as f:
    for line in f:              # Line by line (memory efficient)
        print(line.strip())

# Read with encoding
with open('file.txt', 'r', encoding='utf-8') as f:
    content = f.read()
```

### Writing Files
```python
# Write (overwrite)
with open('file.txt', 'w') as f:
    f.write('Hello, World!\n')

# Append
with open('file.txt', 'a') as f:
    f.write('New line\n')

# Write multiple lines
with open('file.txt', 'w') as f:
    f.writelines(['Line 1\n', 'Line 2\n', 'Line 3\n'])
```

### JSON Files
```python
import json

# Read JSON
with open('data.json', 'r') as f:
    data = json.load(f)

# Write JSON
with open('data.json', 'w') as f:
    json.dump(data, f, indent=2)

# JSON string operations
json_string = json.dumps(data)
data = json.loads(json_string)
```

### CSV Files
```python
import csv

# Read CSV
with open('data.csv', 'r') as f:
    reader = csv.reader(f)
    for row in reader:
        print(row)

# Read CSV as dict
with open('data.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(row['column_name'])

# Write CSV
with open('output.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Name', 'Age'])
    writer.writerows([['John', 30], ['Jane', 25]])
```

---

## Functions

```python
# Basic function
def greet(name):
    return f"Hello, {name}!"

# Default parameters
def greet(name, greeting="Hello"):
    return f"{greeting}, {name}!"

# *args and **kwargs
def func(*args, **kwargs):
    print(args)    # Tuple of positional args
    print(kwargs)  # Dict of keyword args

# Type hints
def process(data: list[dict]) -> dict:
    return {"count": len(data)}

# Lambda functions
square = lambda x: x ** 2
add = lambda x, y: x + y

# Map, Filter, Reduce
numbers = [1, 2, 3, 4, 5]
squared = list(map(lambda x: x**2, numbers))
evens = list(filter(lambda x: x % 2 == 0, numbers))

from functools import reduce
total = reduce(lambda x, y: x + y, numbers)
```

---

## Classes

```python
class DataPipeline:
    """A simple data pipeline class."""
    
    # Class variable
    default_batch_size = 1000
    
    def __init__(self, name: str, source: str):
        """Initialize the pipeline."""
        self.name = name          # Instance variable
        self.source = source
        self._data = []           # Private by convention
    
    def extract(self) -> list:
        """Extract data from source."""
        # Implementation
        return self._data
    
    def transform(self, data: list) -> list:
        """Transform the data."""
        return [item.upper() for item in data]
    
    @property
    def record_count(self) -> int:
        """Property for record count."""
        return len(self._data)
    
    @classmethod
    def from_config(cls, config: dict):
        """Create instance from config dict."""
        return cls(config['name'], config['source'])
    
    @staticmethod
    def validate_data(data: list) -> bool:
        """Static method to validate data."""
        return len(data) > 0
    
    def __repr__(self):
        return f"DataPipeline(name={self.name})"

# Inheritance
class SQLPipeline(DataPipeline):
    def __init__(self, name: str, source: str, query: str):
        super().__init__(name, source)
        self.query = query
```

---

## Error Handling

```python
# Basic try-except
try:
    result = 10 / 0
except ZeroDivisionError:
    print("Cannot divide by zero!")

# Multiple exceptions
try:
    data = json.loads(invalid_json)
except (json.JSONDecodeError, TypeError) as e:
    print(f"Error: {e}")

# Full structure
try:
    result = risky_operation()
except SpecificError as e:
    logger.error(f"Specific error: {e}")
    raise
except Exception as e:
    logger.error(f"Unexpected error: {e}")
else:
    print("Success!")  # Runs if no exception
finally:
    cleanup()  # Always runs

# Raising exceptions
if not data:
    raise ValueError("Data cannot be empty")

# Custom exceptions
class PipelineError(Exception):
    """Custom exception for pipeline errors."""
    def __init__(self, message, step=None):
        self.step = step
        super().__init__(message)
```

---

## Pandas Quick Reference

### DataFrame Creation
```python
import pandas as pd

# From dict
df = pd.DataFrame({
    'name': ['John', 'Jane'],
    'age': [30, 25]
})

# From list of dicts
df = pd.DataFrame([
    {'name': 'John', 'age': 30},
    {'name': 'Jane', 'age': 25}
])

# Read from files
df = pd.read_csv('data.csv')
df = pd.read_excel('data.xlsx')
df = pd.read_json('data.json')
df = pd.read_parquet('data.parquet')
df = pd.read_sql(query, connection)
```

### Basic Operations
```python
# Info
df.shape              # (rows, cols)
df.info()             # Column types, non-null counts
df.describe()         # Statistics
df.head(10)           # First 10 rows
df.tail(10)           # Last 10 rows
df.columns            # Column names
df.dtypes             # Data types

# Selection
df['column']          # Single column (Series)
df[['col1', 'col2']]  # Multiple columns (DataFrame)
df.loc[0]             # Row by label
df.iloc[0]            # Row by position
df.loc[0:5, 'col1']   # Rows 0-5, column 'col1'
df.iloc[0:5, 0:3]     # Rows 0-5, columns 0-2

# Filtering
df[df['age'] > 25]
df[df['name'].str.contains('John')]
df[(df['age'] > 25) & (df['city'] == 'NYC')]
df.query("age > 25 and city == 'NYC'")
```

### Data Cleaning
```python
# Missing values
df.isna().sum()                    # Count nulls per column
df.dropna()                        # Drop rows with any null
df.dropna(subset=['col1'])         # Drop if col1 is null
df.fillna(0)                       # Fill nulls with 0
df.fillna({'col1': 0, 'col2': 'Unknown'})
df['col1'].ffill()                 # Forward fill
df['col1'].bfill()                 # Backward fill

# Duplicates
df.duplicated().sum()              # Count duplicates
df.drop_duplicates()               # Remove duplicates
df.drop_duplicates(subset=['col1'])

# Data types
df['col'] = df['col'].astype(int)
df['date'] = pd.to_datetime(df['date'])
df['col'] = df['col'].astype('category')

# Renaming
df.rename(columns={'old': 'new'})
df.columns = ['new1', 'new2', 'new3']
```

### Aggregations
```python
# Basic aggregation
df['col'].sum()
df['col'].mean()
df['col'].min()
df['col'].max()
df['col'].count()

# GroupBy
df.groupby('category')['amount'].sum()
df.groupby(['cat1', 'cat2']).agg({
    'amount': 'sum',
    'quantity': 'mean',
    'order_id': 'count'
})

# Named aggregation
df.groupby('category').agg(
    total_amount=('amount', 'sum'),
    avg_quantity=('quantity', 'mean'),
    order_count=('order_id', 'count')
)

# Pivot table
pd.pivot_table(df, 
    values='amount',
    index='category',
    columns='region',
    aggfunc='sum',
    fill_value=0
)
```

### Merging
```python
# Merge (like SQL JOIN)
pd.merge(df1, df2, on='key')
pd.merge(df1, df2, on='key', how='left')
pd.merge(df1, df2, left_on='key1', right_on='key2')

# Concat (stack DataFrames)
pd.concat([df1, df2])              # Vertically
pd.concat([df1, df2], axis=1)      # Horizontally

# Join (on index)
df1.join(df2, how='left')
```

### Output
```python
df.to_csv('output.csv', index=False)
df.to_excel('output.xlsx', index=False)
df.to_parquet('output.parquet')
df.to_json('output.json', orient='records')
df.to_sql('table_name', connection, if_exists='replace')
```

---

## Database Connections

### SQLAlchemy
```python
from sqlalchemy import create_engine

# SQL Server
engine = create_engine(
    "mssql+pyodbc://user:pass@server/database?driver=ODBC+Driver+17+for+SQL+Server"
)

# PostgreSQL
engine = create_engine("postgresql://user:pass@host:5432/database")

# MySQL
engine = create_engine("mysql+pymysql://user:pass@host:3306/database")

# Execute query
with engine.connect() as conn:
    result = conn.execute("SELECT * FROM table")
    for row in result:
        print(row)

# Pandas integration
df = pd.read_sql("SELECT * FROM table", engine)
df.to_sql("new_table", engine, if_exists="replace", index=False)
```

### pyodbc
```python
import pyodbc

conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=server_name;"
    "DATABASE=database_name;"
    "UID=username;"
    "PWD=password"
)

cursor = conn.cursor()
cursor.execute("SELECT * FROM table WHERE id = ?", (1,))
rows = cursor.fetchall()

# With context manager
with conn.cursor() as cursor:
    cursor.execute("INSERT INTO table (col) VALUES (?)", (value,))
    conn.commit()
```

---

## Logging

```python
import logging

# Basic setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('pipeline.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# Usage
logger.debug("Debug message")
logger.info("Processing started")
logger.warning("Data quality issue")
logger.error("Failed to connect")
logger.exception("Error with traceback")  # Includes stack trace
```

---

## Environment Variables

```python
import os
from dotenv import load_dotenv

# Load from .env file
load_dotenv()

# Get environment variables
db_host = os.getenv('DB_HOST', 'localhost')  # With default
db_pass = os.environ['DB_PASSWORD']          # Raises error if missing

# Check if exists
if 'API_KEY' in os.environ:
    api_key = os.environ['API_KEY']
```

---

## Date and Time

```python
from datetime import datetime, date, timedelta
import pytz

# Current time
now = datetime.now()
utc_now = datetime.utcnow()
today = date.today()

# Parsing
dt = datetime.strptime("2024-01-15 10:30:00", "%Y-%m-%d %H:%M:%S")

# Formatting
formatted = dt.strftime("%Y-%m-%d")
iso_format = dt.isoformat()

# Timedelta
tomorrow = today + timedelta(days=1)
last_week = today - timedelta(weeks=1)
hours_later = now + timedelta(hours=3)

# Timezone handling
tz = pytz.timezone('US/Eastern')
local_time = dt.astimezone(tz)

# Common patterns
start_of_month = today.replace(day=1)
end_of_month = (start_of_month + timedelta(days=32)).replace(day=1) - timedelta(days=1)
```

---

## Useful Patterns

### Progress Bar
```python
from tqdm import tqdm

for item in tqdm(items, desc="Processing"):
    process(item)
```

### Retry Decorator
```python
from functools import wraps
import time

def retry(max_attempts=3, delay=1):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    time.sleep(delay * (2 ** attempt))
        return wrapper
    return decorator

@retry(max_attempts=3, delay=1)
def fetch_data():
    # API call that might fail
    pass
```

### Batch Processing
```python
def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

# Usage
for batch in chunks(large_list, 1000):
    process_batch(batch)
```

### Context Manager
```python
from contextlib import contextmanager

@contextmanager
def timer(name):
    start = time.time()
    try:
        yield
    finally:
        elapsed = time.time() - start
        print(f"{name} took {elapsed:.2f} seconds")

# Usage
with timer("Data processing"):
    process_data()
```

---

## Quick Tips

| Need | Solution |
|------|----------|
| Unique values in list | `list(set(my_list))` |
| Flatten nested list | `[x for sublist in nested for x in sublist]` |
| Dictionary merge | `{**dict1, **dict2}` or `dict1 | dict2` (3.9+) |
| Check empty | `if not my_list:` (Pythonic) |
| Default dict value | `dict.get(key, default)` |
| Enumerate with index | `for i, item in enumerate(items):` |
| Zip two lists | `dict(zip(keys, values))` |
| Sort by key | `sorted(items, key=lambda x: x['date'])` |
| Reverse sort | `sorted(items, reverse=True)` |
| First match | `next((x for x in items if x > 5), None)` |
