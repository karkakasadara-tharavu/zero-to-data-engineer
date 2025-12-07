# Module 12: Data Processing with Pandas

## Theory Section 11: Performance Optimization

### Learning Objectives
- Understand Pandas performance characteristics
- Optimize memory usage
- Use efficient data types
- Vectorize operations for speed
- Profile and benchmark code
- Apply best practices for large datasets

### Understanding Memory Usage

```python
import pandas as pd
import numpy as np

# Check DataFrame memory usage
df = pd.DataFrame({
    'int_col': range(1000000),
    'float_col': np.random.randn(1000000),
    'string_col': ['text'] * 1000000
})

# Basic memory usage (index + columns)
print(df.memory_usage())

# Deep memory usage (includes object values)
print(df.memory_usage(deep=True))

# Total memory
print(f"Total: {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")

# Per column details
for col in df.columns:
    print(f"{col}: {df[col].memory_usage(deep=True) / 1024**2:.2f} MB")
```

### Efficient Data Types

#### Integer Optimization

```python
# Default int64 uses 8 bytes per value
df = pd.DataFrame({'col': range(1000000)})
print(df['col'].dtype)  # int64
print(df.memory_usage(deep=True))

# Downcast to smaller integer type
df['col'] = pd.to_numeric(df['col'], downcast='integer')
print(df['col'].dtype)  # int32 or int16
print(df.memory_usage(deep=True))  # Less memory

# Manual type specification
df = pd.DataFrame({
    'tiny': pd.array(range(100), dtype='int8'),    # -128 to 127
    'small': pd.array(range(1000), dtype='int16'),  # -32768 to 32767
    'medium': pd.array(range(10000), dtype='int32'), # -2B to 2B
    'large': pd.array(range(10000), dtype='int64')   # -9Q to 9Q
})

# Unsigned integers (only positive values)
df['unsigned'] = pd.array(range(1000), dtype='uint16')  # 0 to 65535
```

#### Float Optimization

```python
# Float precision
df = pd.DataFrame({
    'float64': np.random.randn(1000000),  # Default: 8 bytes
})
print(df.memory_usage(deep=True))

# Downcast floats
df['float32'] = df['float64'].astype('float32')  # 4 bytes
print(df.memory_usage(deep=True))

# Note: float32 has less precision
print(df['float64'].iloc[0])  # More decimal places
print(df['float32'].iloc[0])  # Fewer decimal places
```

#### String/Object Optimization

```python
# Object dtype (high memory)
df = pd.DataFrame({
    'status': np.random.choice(['active', 'inactive', 'pending'], 1000000)
})
print(df['status'].dtype)  # object
print(df.memory_usage(deep=True))

# Convert to category (much lower memory)
df['status'] = df['status'].astype('category')
print(df['status'].dtype)  # category
print(df.memory_usage(deep=True))

# String dtype (better than object for text)
df['text'] = pd.array(['example'] * 1000000, dtype='string')
```

#### Datetime Optimization

```python
# Store dates efficiently
df = pd.DataFrame({
    'date_str': ['2024-01-15'] * 1000000  # Object dtype
})
print(df.memory_usage(deep=True))

# Convert to datetime
df['date'] = pd.to_datetime(df['date_str'])
print(df['date'].dtype)  # datetime64[ns] - fixed 8 bytes
print(df.memory_usage(deep=True))  # Lower memory

# Drop string column
df = df.drop('date_str', axis=1)
```

### Reading Data Efficiently

#### Specify Data Types

```python
# Let Pandas infer types (slower, more memory)
df = pd.read_csv('data.csv')

# Specify types upfront (faster, less memory)
dtypes = {
    'id': 'int32',
    'value': 'float32',
    'category': 'category',
    'date': 'string'
}
df = pd.read_csv('data.csv', dtype=dtypes)

# Parse dates during read
df = pd.read_csv('data.csv', 
                 dtype=dtypes,
                 parse_dates=['date'])
```

#### Read in Chunks

```python
# For files too large for memory
chunk_size = 100000
chunks = []

for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    # Process each chunk
    chunk_processed = chunk[chunk['value'] > 0]
    chunks.append(chunk_processed)

# Combine results
df = pd.concat(chunks, ignore_index=True)

# Or process without storing
total = 0
for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    total += chunk['value'].sum()
print(f"Total: {total}")
```

#### Use Columns Parameter

```python
# Read only needed columns
df = pd.read_csv('data.csv', usecols=['id', 'value', 'date'])

# Or use callable
df = pd.read_csv('data.csv', 
                 usecols=lambda col: col.startswith('sales_'))
```

#### Use nrows for Testing

```python
# Test with small sample first
df_sample = pd.read_csv('large_file.csv', nrows=1000)
# Develop and test processing logic
# Then run on full file

df = pd.read_csv('large_file.csv')
```

### Vectorization

Vectorized operations are much faster than loops or apply.

```python
# SLOW: Iterating with loops
df = pd.DataFrame({'A': range(1000000), 'B': range(1000000)})

# Bad - loop
result = []
for i in range(len(df)):
    result.append(df.loc[i, 'A'] + df.loc[i, 'B'])
df['C'] = result

# Bad - iterrows
result = []
for idx, row in df.iterrows():
    result.append(row['A'] + row['B'])
df['C'] = result

# FAST: Vectorized operations
df['C'] = df['A'] + df['B']  # 100-1000x faster!

# FAST: NumPy operations
df['D'] = np.sqrt(df['A'])
df['E'] = np.maximum(df['A'], df['B'])

# Conditional operations
df['category'] = np.where(df['A'] > 500000, 'high', 'low')

# Multiple conditions
df['category'] = np.select(
    [df['A'] < 333333, df['A'] < 666666, df['A'] >= 666666],
    ['low', 'medium', 'high']
)
```

### Efficient Apply Usage

```python
# When apply is necessary

# Apply to Series (operates on scalars)
df['result'] = df['A'].apply(lambda x: x ** 2 + 1)

# Apply to DataFrame (operates on rows/columns)
df['sum'] = df.apply(lambda row: row['A'] + row['B'], axis=1)

# Use raw=True for NumPy arrays (faster)
df['sum'] = df.apply(lambda x: x[0] + x[1], axis=1, raw=True)

# Use numba for complex functions
from numba import jit

@jit
def complex_calculation(x):
    return x ** 2 + np.log(x + 1)

df['result'] = df['A'].apply(complex_calculation)
```

### Index Optimization

```python
# Set index for repeated lookups
df = pd.DataFrame({
    'id': range(1000000),
    'value': np.random.randn(1000000)
})

# Slow: repeated boolean indexing
for i in range(100, 200):
    value = df[df['id'] == i]['value'].iloc[0]

# Fast: set index
df = df.set_index('id')
for i in range(100, 200):
    value = df.loc[i, 'value']

# Sort index for range queries
df = df.sort_index()

# Check if sorted
print(df.index.is_monotonic_increasing)
```

### Query vs Boolean Indexing

```python
# Boolean indexing
result = df[(df['A'] > 100) & (df['B'] < 500)]

# Query (can be faster for complex conditions)
result = df.query('A > 100 and B < 500')

# Query with variables
threshold = 100
result = df.query('A > @threshold')

# Complex query
result = df.query('A > 100 and B < 500 and C in ["x", "y"]')
```

### Efficient GroupBy

```python
# GroupBy optimization

# Use categorical for grouping columns
df['category'] = df['category'].astype('category')

# Group by single column
grouped = df.groupby('category')['value'].mean()

# Group by multiple columns
grouped = df.groupby(['cat1', 'cat2'])['value'].sum()

# Use transform for element-wise operations
df['normalized'] = df.groupby('category')['value'].transform(lambda x: (x - x.mean()) / x.std())

# Use numba for custom aggregations
from numba import jit

@jit
def custom_agg(values):
    return np.sum(values ** 2)

# Filter groups efficiently
filtered = df.groupby('category').filter(lambda x: len(x) > 100)
```

### Copy vs View

```python
# Understand when Pandas copies data

# View (no copy)
subset = df[['A', 'B']]  # View of columns
subset['A'] = 0  # WARNING: Might modify original!

# Explicit copy
subset = df[['A', 'B']].copy()
subset['A'] = 0  # Safe: won't modify original

# Check if view
df2 = df[['A', 'B']]
print(df2._is_view)  # True if view

# Inplace operations
df.drop('A', axis=1, inplace=True)  # No copy
df = df.drop('A', axis=1)  # Creates copy
```

### Parallel Processing

```python
# Use Dask for parallel processing
import dask.dataframe as dd

# Convert Pandas DataFrame to Dask
ddf = dd.from_pandas(df, npartitions=4)

# Operations are lazy
result = ddf.groupby('category')['value'].mean()

# Compute to execute
result = result.compute()

# Read large CSV with Dask
ddf = dd.read_csv('large_file.csv')
result = ddf[ddf['value'] > 0].compute()

# Use swifter for automatic parallelization
import swifter

df['result'] = df['column'].swifter.apply(lambda x: complex_function(x))
```

### Profiling and Benchmarking

```python
import time

# Time a single operation
start = time.time()
result = df.groupby('category')['value'].mean()
elapsed = time.time() - start
print(f"Time: {elapsed:.3f} seconds")

# Use %timeit in Jupyter
# %timeit df.groupby('category')['value'].mean()

# Profile memory usage
from memory_profiler import profile

@profile
def process_data(df):
    df['new_col'] = df['A'] + df['B']
    return df.groupby('category').mean()

# Line profiler for detailed analysis
# %lprun -f process_data process_data(df)

# Pandas profiling report
from pandas_profiling import ProfileReport

profile = ProfileReport(df)
profile.to_file("report.html")
```

### Best Practices Summary

```python
# 1. Use appropriate data types
df = pd.read_csv('data.csv', dtype={
    'id': 'int32',
    'category': 'category',
    'value': 'float32',
    'date': 'string'
})

# 2. Read only necessary columns
df = pd.read_csv('data.csv', usecols=['id', 'value', 'date'])

# 3. Use vectorized operations
df['result'] = df['A'] + df['B']  # Not apply

# 4. Set index for repeated lookups
df = df.set_index('id')

# 5. Use query for complex filters
result = df.query('value > 100 and category == "A"')

# 6. Convert to categorical
df['category'] = df['category'].astype('category')

# 7. Use method chaining
result = (df
          .query('value > 0')
          .groupby('category')
          .mean()
          .reset_index())

# 8. Read in chunks for large files
for chunk in pd.read_csv('large.csv', chunksize=100000):
    process(chunk)

# 9. Use eval for complex expressions
df.eval('result = A + B * C', inplace=True)

# 10. Profile and measure
# Always measure before and after optimization
```

### Memory Reduction Function

```python
def reduce_memory_usage(df, verbose=True):
    """
    Reduce DataFrame memory usage by optimizing dtypes
    """
    start_mem = df.memory_usage(deep=True).sum() / 1024**2
    
    for col in df.columns:
        col_type = df[col].dtype
        
        if col_type != object:
            c_min = df[col].min()
            c_max = df[col].max()
            
            if str(col_type)[:3] == 'int':
                if c_min > np.iinfo(np.int8).min and c_max < np.iinfo(np.int8).max:
                    df[col] = df[col].astype(np.int8)
                elif c_min > np.iinfo(np.int16).min and c_max < np.iinfo(np.int16).max:
                    df[col] = df[col].astype(np.int16)
                elif c_min > np.iinfo(np.int32).min and c_max < np.iinfo(np.int32).max:
                    df[col] = df[col].astype(np.int32)
            else:
                if c_min > np.finfo(np.float32).min and c_max < np.finfo(np.float32).max:
                    df[col] = df[col].astype(np.float32)
        else:
            df[col] = df[col].astype('category')
    
    end_mem = df.memory_usage(deep=True).sum() / 1024**2
    
    if verbose:
        print(f'Memory usage decreased from {start_mem:.2f} MB to {end_mem:.2f} MB '
              f'({100 * (start_mem - end_mem) / start_mem:.1f}% reduction)')
    
    return df

# Usage
df = reduce_memory_usage(df)
```

### Performance Checklist

**Memory Optimization:**
- ✓ Use appropriate integer types (int8, int16, int32)
- ✓ Use float32 instead of float64 when precision allows
- ✓ Convert repeated strings to categorical
- ✓ Use datetime64 for dates
- ✓ Read only necessary columns
- ✓ Process in chunks for large files

**Speed Optimization:**
- ✓ Use vectorized operations (avoid loops)
- ✓ Use NumPy functions when possible
- ✓ Set index for repeated lookups
- ✓ Use query() for complex filters
- ✓ Sort index before range queries
- ✓ Use categorical for groupby keys
- ✓ Consider parallel processing (Dask, swifter)

**Code Quality:**
- ✓ Profile before optimizing
- ✓ Measure performance improvements
- ✓ Use method chaining for readability
- ✓ Document performance considerations
- ✓ Test with realistic data sizes

### Summary

- Monitor memory usage with `memory_usage(deep=True)`
- Use appropriate data types: int8/16/32, float32, category
- Read data efficiently: specify dtypes, use chunks, select columns
- Prefer vectorization over loops and apply
- Set and sort index for fast lookups
- Use query() for complex filters
- Profile code to identify bottlenecks
- Consider Dask for parallel processing of large data

### Key Takeaways

1. Choose smallest data type that fits your data
2. Categorical data dramatically reduces memory
3. Vectorized operations are 100-1000x faster than loops
4. Set index for repeated lookups
5. Read only what you need from files
6. Always profile before optimizing
7. Use chunks for files larger than memory
8. Method chaining improves code clarity

---

**Practice Exercise:**

1. Load a large dataset and check memory usage
2. Optimize data types to reduce memory by 50%+
3. Compare performance: loop vs apply vs vectorized
4. Set appropriate index and measure lookup speed
5. Use chunks to process a file larger than RAM
6. Profile a complex operation and identify bottleneck
7. Implement memory reduction function for your data
