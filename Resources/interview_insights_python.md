# Python for Data Engineering - Interview Insights & Tricks

## 🎯 Overview
This guide covers Python fundamentals, advanced features, and Pandas - essential skills tested in every data engineering interview.

---

## Module 10: Python Basics

### 💡 What Interviewers Really Test

Python basics questions assess:
- Understanding of data structures (not just syntax)
- Memory and performance awareness
- Pythonic code style
- Real-world problem-solving approach

### 🔥 Top Interview Tricks

#### Trick 1: List vs Tuple vs Set vs Dict (Know When to Use Each!)
```python
# LIST - Ordered, mutable, allows duplicates
# Use for: Sequences that change, maintaining order
data = [1, 2, 3, 2]
data.append(4)  # O(1)
data[0] = 10    # O(1)

# TUPLE - Ordered, immutable
# Use for: Fixed data, dict keys, function returns
point = (10, 20)
# point[0] = 5  # Error!
# INTERVIEW INSIGHT: Tuples are hashable, can be dict keys

# SET - Unordered, unique elements
# Use for: Removing duplicates, membership tests (O(1)!)
unique_ids = {1, 2, 3}
if 2 in unique_ids:  # O(1) lookup!
    print("Found")

# DICT - Key-value pairs
# Use for: Lookups by key (O(1) average)
lookup = {"a": 1, "b": 2}
value = lookup.get("c", "default")  # Safe access

# INTERVIEW QUESTION: "How to remove duplicates while preserving order?"
# Python 3.7+: dicts preserve insertion order
def remove_duplicates_ordered(items):
    return list(dict.fromkeys(items))

# Or use OrderedDict for older Python
from collections import OrderedDict
list(OrderedDict.fromkeys(items))
```

#### Trick 2: Mutable Default Arguments Trap
```python
# WRONG - Common interview gotcha
def append_to(element, target=[]):
    target.append(element)
    return target

print(append_to(1))  # [1]
print(append_to(2))  # [1, 2] - Not [2]! Same list!

# RIGHT
def append_to(element, target=None):
    if target is None:
        target = []
    target.append(element)
    return target

# INTERVIEW INSIGHT: "Default arguments are evaluated once 
# at function definition, not each call. Mutable defaults 
# are shared across calls."
```

#### Trick 3: List Comprehensions vs Generators
```python
# LIST COMPREHENSION - Creates list in memory
squares = [x**2 for x in range(1000000)]  # Allocates memory for 1M items

# GENERATOR - Lazy evaluation, memory efficient
squares_gen = (x**2 for x in range(1000000))  # Almost no memory

# WHEN TO USE WHICH:
# List comprehension: Need all values, multiple iterations
# Generator: Large data, single pass, memory-conscious

# INTERVIEW EXAMPLE: Process large file
# BAD - Loads entire file
lines = [line.strip() for line in open('huge_file.txt')]

# GOOD - Processes line by line
def process_file(filename):
    with open(filename) as f:
        for line in f:
            yield line.strip()

# INSIGHT: Generators are fundamental to data engineering - 
# they enable processing data larger than memory
```

#### Trick 4: String Formatting (Know All Methods)
```python
name = "Alice"
age = 30

# Old style (avoid)
"Hello %s, you are %d" % (name, age)

# .format() method
"Hello {}, you are {}".format(name, age)
"Hello {name}, you are {age}".format(name=name, age=age)

# f-strings (Python 3.6+) - PREFERRED
f"Hello {name}, you are {age}"
f"Next year you'll be {age + 1}"  # Expressions allowed!

# INTERVIEW QUESTION: "Format a number with thousands separator"
large_num = 1234567
f"{large_num:,}"  # "1,234,567"
f"{large_num:,.2f}"  # "1,234,567.00"
```

#### Trick 5: Exception Handling Patterns
```python
# BASIC
try:
    result = 10 / 0
except ZeroDivisionError:
    result = None

# FULL PATTERN
try:
    risky_operation()
except SpecificError as e:
    handle_error(e)
except (Error1, Error2):  # Multiple exceptions
    handle_multiple()
except Exception as e:  # Catch-all (last resort)
    log_error(e)
    raise  # Re-raise after logging
else:
    # Runs if NO exception
    success_cleanup()
finally:
    # ALWAYS runs
    cleanup()

# DATA ENGINEERING PATTERN: Retry with backoff
import time

def retry_with_backoff(func, max_retries=3, base_delay=1):
    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            delay = base_delay * (2 ** attempt)
            print(f"Attempt {attempt + 1} failed, retrying in {delay}s")
            time.sleep(delay)
```

### 🎤 Python Basics Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "List vs tuple?" | "Lists are mutable sequences; tuples are immutable and hashable - useful as dict keys or when data shouldn't change" |
| "Generator vs list?" | "Generators are lazy and memory-efficient for large data; lists when you need random access or multiple iterations" |
| "Exception handling?" | "Catch specific exceptions, use finally for cleanup, and implement retry logic for transient failures" |

---

## Module 11: Advanced Python

### 💡 Advanced Topics That Impress

- Decorators and closures
- Context managers
- Itertools and functional programming
- Concurrency (threading vs multiprocessing)
- Type hints

### 🔥 Top Interview Tricks

#### Trick 1: Decorators (Frequently Asked!)
```python
# BASIC DECORATOR
def timer(func):
    import time
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.time() - start:.4f}s")
        return result
    return wrapper

@timer
def slow_function():
    time.sleep(1)

# DECORATOR WITH ARGUMENTS
def retry(max_attempts=3):
    def decorator(func):
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
        return wrapper
    return decorator

@retry(max_attempts=5)
def flaky_api_call():
    pass

# PRESERVE FUNCTION METADATA
from functools import wraps

def my_decorator(func):
    @wraps(func)  # Preserves __name__, __doc__, etc.
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper

# INTERVIEW INSIGHT: "Decorators are functions that modify other 
# functions. I use them for cross-cutting concerns like logging, 
# timing, retry logic, and authentication."
```

#### Trick 2: Context Managers
```python
# USING CONTEXT MANAGERS
with open('file.txt') as f:
    data = f.read()
# File automatically closed, even if exception

# CREATING WITH CLASS
class DatabaseConnection:
    def __init__(self, connection_string):
        self.conn_string = connection_string
        self.connection = None
    
    def __enter__(self):
        self.connection = create_connection(self.conn_string)
        return self.connection
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.connection:
            self.connection.close()
        return False  # Don't suppress exceptions

# CREATING WITH DECORATOR (simpler!)
from contextlib import contextmanager

@contextmanager
def database_connection(conn_string):
    conn = create_connection(conn_string)
    try:
        yield conn
    finally:
        conn.close()

# Usage
with database_connection("postgres://...") as conn:
    conn.execute("SELECT ...")

# INTERVIEW INSIGHT: "Context managers ensure resource cleanup. 
# I use them for database connections, file handles, locks, 
# and any resource that needs explicit release."
```

#### Trick 3: Itertools for Data Processing
```python
from itertools import islice, chain, groupby, zip_longest

# PROCESS IN BATCHES (common in ETL!)
def batch_process(items, batch_size=1000):
    iterator = iter(items)
    while batch := list(islice(iterator, batch_size)):
        yield batch

# Usage
for batch in batch_process(large_dataset, 100):
    insert_to_database(batch)

# CHAIN MULTIPLE ITERABLES
all_data = chain(list1, list2, list3)  # Single iterator

# GROUP BY (data must be sorted!)
from itertools import groupby

data = [("A", 1), ("A", 2), ("B", 3), ("B", 4)]
for key, group in groupby(data, key=lambda x: x[0]):
    print(key, list(group))
# A [('A', 1), ('A', 2)]
# B [('B', 3), ('B', 4)]

# ZIP WITH DIFFERENT LENGTHS
names = ["Alice", "Bob"]
ages = [30, 25, 40]
list(zip_longest(names, ages, fillvalue=None))
# [('Alice', 30), ('Bob', 25), (None, 40)]
```

#### Trick 4: Threading vs Multiprocessing
```python
# THREADING - For I/O-bound tasks (API calls, file I/O)
from concurrent.futures import ThreadPoolExecutor

def fetch_url(url):
    return requests.get(url).text

urls = ["http://api1.com", "http://api2.com", "http://api3.com"]

with ThreadPoolExecutor(max_workers=10) as executor:
    results = list(executor.map(fetch_url, urls))

# MULTIPROCESSING - For CPU-bound tasks (data transformation)
from concurrent.futures import ProcessPoolExecutor

def heavy_computation(data):
    return sum(x**2 for x in data)

chunks = [data[i:i+1000] for i in range(0, len(data), 1000)]

with ProcessPoolExecutor() as executor:
    results = list(executor.map(heavy_computation, chunks))

# INTERVIEW INSIGHT:
# "Threading for I/O-bound (GIL doesn't block I/O waiting)
# Multiprocessing for CPU-bound (bypasses GIL with separate processes)
# In data engineering, threading for API calls, multiprocessing for transformations"

# ASYNC/AWAIT - Modern I/O concurrency
import asyncio
import aiohttp

async def fetch_all(urls):
    async with aiohttp.ClientSession() as session:
        tasks = [session.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)
        return [await r.text() for r in responses]
```

#### Trick 5: Type Hints (Modern Python)
```python
from typing import List, Dict, Optional, Union, Callable, Any

# BASIC TYPES
def process_data(items: List[str], count: int = 10) -> Dict[str, int]:
    return {item: len(item) for item in items[:count]}

# OPTIONAL (can be None)
def find_user(user_id: int) -> Optional[Dict[str, Any]]:
    # Returns user dict or None
    pass

# UNION (multiple types)
def parse_input(data: Union[str, bytes]) -> Dict:
    pass

# CALLABLE
def apply_transform(
    data: List[int], 
    transform: Callable[[int], int]
) -> List[int]:
    return [transform(x) for x in data]

# TYPE ALIAS (for complex types)
DataRow = Dict[str, Union[str, int, float, None]]
DataTable = List[DataRow]

def process_table(table: DataTable) -> DataTable:
    pass

# INTERVIEW INSIGHT: "Type hints improve code readability and 
# enable static analysis with mypy. They're especially valuable 
# in data pipelines where data shape matters."
```

### 🎤 Advanced Python Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Decorators?" | "They wrap functions to add behavior without modifying the original - great for logging, timing, retry logic" |
| "GIL?" | "Global Interpreter Lock means only one thread executes Python bytecode at a time; use multiprocessing for CPU-bound work" |
| "Context managers?" | "Ensure cleanup of resources like file handles and connections, even when exceptions occur" |

---

## Module 12: Pandas for Data Engineering

### 💡 Pandas Interview Focus

Pandas questions test:
- Data manipulation fluency
- Performance awareness
- Memory management
- Real-world data cleaning skills

### 🔥 Top Interview Tricks

#### Trick 1: DataFrame Creation and Selection
```python
import pandas as pd
import numpy as np

# CREATE DATAFRAME
df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35],
    'city': ['NYC', 'LA', 'SF']
})

# SELECTION METHODS (Know the difference!)
df['name']           # Series
df[['name']]         # DataFrame (single column)
df[['name', 'age']]  # DataFrame (multiple columns)

# LOC vs ILOC (Always asked!)
df.loc[0]            # Row by label
df.loc[0, 'name']    # Specific cell by label
df.loc[0:2]          # Rows 0, 1, 2 (inclusive!)

df.iloc[0]           # Row by position
df.iloc[0, 0]        # Specific cell by position
df.iloc[0:2]         # Rows 0, 1 (exclusive, like normal Python!)

# BOOLEAN INDEXING
df[df['age'] > 25]
df[(df['age'] > 25) & (df['city'] == 'NYC')]  # Use & not 'and'!
df[df['city'].isin(['NYC', 'LA'])]

# QUERY METHOD (more readable)
df.query('age > 25 and city == "NYC"')
```

#### Trick 2: GroupBy and Aggregation
```python
# BASIC GROUPBY
df.groupby('category')['amount'].sum()
df.groupby('category')['amount'].agg(['sum', 'mean', 'count'])

# MULTIPLE COLUMNS GROUPBY
df.groupby(['category', 'region'])['amount'].sum()

# NAMED AGGREGATIONS (clean output)
df.groupby('category').agg(
    total_amount=('amount', 'sum'),
    avg_amount=('amount', 'mean'),
    order_count=('order_id', 'count'),
    unique_customers=('customer_id', 'nunique')
)

# TRANSFORM (keep original shape)
# Add column with group average
df['category_avg'] = df.groupby('category')['amount'].transform('mean')

# INTERVIEW QUESTION: "Difference between agg and transform?"
# agg: Returns one row per group (reduced)
# transform: Returns same shape as input (broadcasts group result back)

# FILTER GROUPS
df.groupby('category').filter(lambda x: x['amount'].sum() > 1000)
```

#### Trick 3: Merge and Join Operations
```python
# MERGE (SQL-like joins)
pd.merge(df1, df2, on='key')              # Inner join (default)
pd.merge(df1, df2, on='key', how='left')  # Left join
pd.merge(df1, df2, on='key', how='outer') # Full outer join

# Different column names
pd.merge(df1, df2, left_on='id', right_on='customer_id')

# Multiple keys
pd.merge(df1, df2, on=['year', 'month'])

# INDICATOR (track source of rows)
pd.merge(df1, df2, on='key', how='outer', indicator=True)
# _merge column shows: 'left_only', 'right_only', 'both'

# VALIDATE (catch data quality issues!)
pd.merge(df1, df2, on='key', validate='one_to_one')
# Options: 'one_to_one', 'one_to_many', 'many_to_one', 'many_to_many'

# INTERVIEW INSIGHT: "I always use validate parameter in production 
# to catch unexpected data relationships early."

# CONCAT (stack DataFrames)
pd.concat([df1, df2])                      # Stack vertically
pd.concat([df1, df2], axis=1)              # Stack horizontally
pd.concat([df1, df2], ignore_index=True)   # Reset index
```

#### Trick 4: Handling Missing Data
```python
# DETECT
df.isna().sum()                    # Count NaN per column
df.isna().any()                    # Any NaN per column?
df.isna().sum().sum()              # Total NaN in DataFrame

# FILL
df.fillna(0)                       # Replace with constant
df.fillna(method='ffill')          # Forward fill
df.fillna(method='bfill')          # Backward fill
df.fillna(df.mean())               # Fill with column means

# FILL BY COLUMN
df.fillna({'age': df['age'].median(), 'city': 'Unknown'})

# DROP
df.dropna()                        # Drop rows with any NaN
df.dropna(how='all')               # Drop only all-NaN rows
df.dropna(subset=['critical_col']) # Drop if specific column is NaN
df.dropna(thresh=2)                # Keep if at least 2 non-NaN

# INTERVIEW QUESTION: "How would you handle missing data?"
# ANSWER: "It depends on the context:
# - If random missing: Impute with mean/median
# - If structural: Create 'Unknown' category
# - If critical: Drop or flag for review
# - Always document the approach for auditability"
```

#### Trick 5: Performance Optimization
```python
# MEMORY OPTIMIZATION
# Check memory usage
df.memory_usage(deep=True)
df.info(memory_usage='deep')

# Downcast numeric types
df['int_col'] = pd.to_numeric(df['int_col'], downcast='integer')
df['float_col'] = pd.to_numeric(df['float_col'], downcast='float')

# Use categories for low-cardinality strings
df['category'] = df['category'].astype('category')
# Can reduce memory by 10-50x for repeated strings!

# AVOID ITERATING
# SLOW
for idx, row in df.iterrows():
    df.loc[idx, 'new_col'] = row['a'] + row['b']

# FAST
df['new_col'] = df['a'] + df['b']

# WHEN YOU MUST ITERATE
# itertuples() is 10-100x faster than iterrows()
for row in df.itertuples():
    print(row.name, row.age)

# VECTORIZED OPERATIONS
# Use numpy where instead of apply
df['category'] = np.where(df['amount'] > 100, 'high', 'low')

# CHUNKED READING (for large files)
chunks = pd.read_csv('huge_file.csv', chunksize=100000)
for chunk in chunks:
    process(chunk)

# INTERVIEW INSIGHT: "For large datasets, I use categorical types, 
# avoid iteration, and read in chunks. The goal is to keep 
# operations vectorized."
```

#### Trick 6: Window Functions in Pandas
```python
# ROLLING WINDOW
df['rolling_avg'] = df['value'].rolling(window=7).mean()
df['rolling_sum'] = df['value'].rolling(window=7).sum()

# WITH GROUPBY
df['group_rolling'] = df.groupby('category')['value'].transform(
    lambda x: x.rolling(window=7).mean()
)

# EXPANDING (cumulative)
df['cumsum'] = df['value'].expanding().sum()
df['cummax'] = df['value'].expanding().max()

# RANK
df['rank'] = df.groupby('category')['value'].rank(method='dense')

# SHIFT (LAG/LEAD equivalent)
df['prev_value'] = df['value'].shift(1)      # LAG
df['next_value'] = df['value'].shift(-1)     # LEAD
df['pct_change'] = df['value'].pct_change()  # Period-over-period change
```

### 🎤 Pandas Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Large dataset?" | "Read in chunks, use appropriate dtypes, leverage categorical for strings, avoid iterrows" |
| "loc vs iloc?" | "loc for label-based access with inclusive slicing, iloc for position-based with exclusive slicing" |
| "Apply performance?" | "apply is slow - I prefer vectorized operations or np.where for conditionals" |

---

## 📊 Python Interview Quick Reference

### Data Structure Complexity
| Operation | List | Set | Dict |
|-----------|------|-----|------|
| Access | O(1) | N/A | O(1) |
| Search | O(n) | O(1) | O(1) |
| Insert | O(1)* | O(1) | O(1) |
| Delete | O(n) | O(1) | O(1) |

### Pandas Operations to Know Cold
```python
# Selection
df[['col']], df.loc[], df.iloc[], df.query()

# Aggregation
df.groupby().agg(), .transform(), .filter()

# Joins
pd.merge(..., how=, validate=), pd.concat()

# Missing data
.isna(), .fillna(), .dropna()

# Window
.rolling(), .shift(), .rank(), .expanding()
```

### Memory-Saving Tips
1. Use `category` dtype for low-cardinality strings
2. Downcast numeric types
3. Read large files in chunks
4. Use generators for processing
5. Delete intermediate DataFrames

---

*"Pythonic code isn't just about syntax—it's about leveraging the right tool for each job."*
