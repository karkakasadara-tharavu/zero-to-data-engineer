# Module 12: Data Processing with Pandas

## Theory Section 01: Introduction to Pandas

### Learning Objectives
- Understand what Pandas is and its role in data analysis
- Learn the core data structures: Series and DataFrame
- Install and import Pandas
- Explore basic Pandas operations

### What is Pandas?

**Pandas** (Python Data Analysis Library) is an open-source library providing high-performance, easy-to-use data structures and data analysis tools for Python. Created by Wes McKinney in 2008, Pandas has become the de facto standard for data manipulation in Python.

**Key Features:**
- Fast and efficient DataFrame object with integrated indexing
- Tools for reading and writing data between in-memory data structures and different file formats
- Intelligent data alignment and integrated handling of missing data
- Flexible reshaping and pivoting of datasets
- Label-based slicing, fancy indexing, and subsetting of large datasets
- Aggregation and transformation capabilities (group by functionality)
- Time series functionality

### Why Use Pandas?

1. **Ease of Use:** Intuitive API for data manipulation
2. **Performance:** Built on NumPy for speed
3. **Integration:** Works seamlessly with other Python libraries (NumPy, Matplotlib, Scikit-learn)
4. **Versatility:** Handles various data formats (CSV, Excel, SQL, JSON)
5. **Data Cleaning:** Powerful tools for handling missing data and duplicates
6. **Analysis:** Built-in statistical and aggregation functions

### Installation

```python
# Using pip
pip install pandas

# Using conda
conda install pandas

# Install with optional dependencies
pip install pandas[all]
```

### Importing Pandas

```python
import pandas as pd
import numpy as np  # Often used together

# Check version
print(pd.__version__)
```

**Convention:** The standard alias for Pandas is `pd`.

### Core Data Structures

#### 1. Series

A **Series** is a one-dimensional labeled array capable of holding any data type (integers, strings, floats, objects, etc.). It's like a column in a spreadsheet or a single column from a DataFrame.

**Creating a Series:**

```python
# From a list
s = pd.Series([1, 3, 5, np.nan, 6, 8])
print(s)
# Output:
# 0    1.0
# 1    3.0
# 2    5.0
# 3    NaN
# 4    6.0
# 5    8.0
# dtype: float64

# With custom index
s = pd.Series([10, 20, 30], index=['a', 'b', 'c'])
print(s)
# Output:
# a    10
# b    20
# c    30
# dtype: int64

# From a dictionary
d = {'a': 1, 'b': 2, 'c': 3}
s = pd.Series(d)
print(s)
# Output:
# a    1
# b    2
# c    3
# dtype: int64
```

**Series Attributes:**

```python
s = pd.Series([1, 2, 3, 4, 5])

print(s.values)    # NumPy array: [1 2 3 4 5]
print(s.index)     # Index object: RangeIndex(start=0, stop=5, step=1)
print(s.dtype)     # Data type: int64
print(s.shape)     # Shape: (5,)
print(s.size)      # Size: 5
```

#### 2. DataFrame

A **DataFrame** is a two-dimensional labeled data structure with columns of potentially different types. It's like a spreadsheet or SQL table, or a dictionary of Series objects.

**Creating a DataFrame:**

```python
# From a dictionary of lists
data = {
    'name': ['Alice', 'Bob', 'Charlie', 'David'],
    'age': [25, 30, 35, 28],
    'city': ['New York', 'Paris', 'London', 'Tokyo']
}
df = pd.DataFrame(data)
print(df)
# Output:
#       name  age      city
# 0    Alice   25  New York
# 1      Bob   30     Paris
# 2  Charlie   35    London
# 3    David   28     Tokyo

# From a list of dictionaries
data = [
    {'name': 'Alice', 'age': 25, 'city': 'New York'},
    {'name': 'Bob', 'age': 30, 'city': 'Paris'},
    {'name': 'Charlie', 'age': 35, 'city': 'London'}
]
df = pd.DataFrame(data)

# From a NumPy array
arr = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
df = pd.DataFrame(arr, columns=['A', 'B', 'C'])
print(df)
# Output:
#    A  B  C
# 0  1  2  3
# 1  4  5  6
# 2  7  8  9

# With custom index
df = pd.DataFrame(data, index=['row1', 'row2', 'row3'])
```

**DataFrame Attributes:**

```python
df = pd.DataFrame({
    'A': [1, 2, 3],
    'B': [4, 5, 6],
    'C': [7, 8, 9]
})

print(df.shape)      # (3, 3) - rows, columns
print(df.size)       # 9 - total elements
print(df.columns)    # Column names
print(df.index)      # Row indices
print(df.dtypes)     # Data types of each column
print(df.values)     # NumPy array representation
```

### Basic Operations

#### Viewing Data

```python
# Create sample DataFrame
df = pd.DataFrame({
    'A': range(100),
    'B': range(100, 200),
    'C': range(200, 300)
})

# View first/last rows
print(df.head())      # First 5 rows (default)
print(df.head(10))    # First 10 rows
print(df.tail())      # Last 5 rows
print(df.tail(3))     # Last 3 rows

# Get info about DataFrame
print(df.info())      # Summary including dtypes and memory usage
print(df.describe())  # Statistical summary for numerical columns
```

#### Selecting Data

```python
df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35],
    'salary': [50000, 60000, 70000]
})

# Select a column (returns Series)
print(df['name'])
print(df.name)  # Alternative (if column name is valid Python identifier)

# Select multiple columns (returns DataFrame)
print(df[['name', 'age']])

# Select rows by position
print(df[0:2])  # Rows 0 and 1

# Access single value
print(df.loc[0, 'name'])  # 'Alice'
print(df.iloc[0, 0])      # 'Alice'
```

#### Adding/Modifying Data

```python
# Add a new column
df['bonus'] = df['salary'] * 0.1

# Modify existing column
df['age'] = df['age'] + 1

# Add column with constant value
df['department'] = 'Engineering'

# Delete column
del df['bonus']
# Or
df = df.drop('department', axis=1)

# Add row (not recommended for large datasets)
new_row = {'name': 'David', 'age': 28, 'salary': 55000}
df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
```

### Index Object

The index provides labels for rows (and columns). It's immutable and can be of various types.

```python
# Default integer index
df = pd.DataFrame({'A': [1, 2, 3]})
print(df.index)  # RangeIndex(start=0, stop=3, step=1)

# Custom index
df = pd.DataFrame({'A': [1, 2, 3]}, index=['a', 'b', 'c'])
print(df.index)  # Index(['a', 'b', 'c'], dtype='object')

# Set index from column
df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35]
})
df = df.set_index('name')
print(df)
# Output:
#          age
# name        
# Alice     25
# Bob       30
# Charlie   35

# Reset index
df = df.reset_index()
print(df)
# Output:
#       name  age
# 0    Alice   25
# 1      Bob   30
# 2  Charlie   35
```

### Common Attributes and Methods

```python
df = pd.DataFrame({
    'A': [1, 2, 3, 4],
    'B': [5, 6, 7, 8],
    'C': [9, 10, 11, 12]
})

# Shape and size
print(df.shape)       # (4, 3)
print(df.size)        # 12
print(len(df))        # 4 (number of rows)

# Column and index information
print(df.columns)     # Column names
print(df.index)       # Row indices
print(df.dtypes)      # Data types

# Memory usage
print(df.memory_usage(deep=True))

# Check for empty DataFrame
print(df.empty)       # False

# Get column as list
print(df['A'].tolist())  # [1, 2, 3, 4]

# Get unique values in a column
print(df['A'].unique())
print(df['A'].nunique())  # Count of unique values
```

### Best Practices

1. **Use Vectorized Operations:** Avoid loops; use Pandas built-in functions
2. **Chain Operations:** Use method chaining for readable code
3. **Copy vs View:** Be aware of when operations create copies vs views
4. **Memory Management:** Use appropriate data types to reduce memory usage
5. **Meaningful Names:** Use descriptive column and index names

### Performance Tips

```python
# Bad: Iterating over rows
total = 0
for index, row in df.iterrows():
    total += row['A']

# Good: Vectorized operation
total = df['A'].sum()

# Good: Use appropriate data types
df['category'] = df['category'].astype('category')  # For categorical data

# Good: Read large files in chunks
chunks = pd.read_csv('large_file.csv', chunksize=10000)
for chunk in chunks:
    process(chunk)
```

### Summary

- **Pandas** is the primary library for data manipulation in Python
- **Series**: One-dimensional labeled array
- **DataFrame**: Two-dimensional labeled data structure (table)
- **Index**: Provides labels for rows and columns
- Operations are vectorized for performance
- Integrates seamlessly with NumPy and other Python libraries

### Key Takeaways

1. Pandas provides two main data structures: Series (1D) and DataFrame (2D)
2. DataFrames are like tables with labeled rows and columns
3. Pandas is built on NumPy for high performance
4. Vectorized operations are much faster than loops
5. The index is a core concept that enables powerful data alignment

### Next Steps

In the next section, we'll dive deeper into DataFrames, learning how to load data from various sources, inspect data, and perform basic manipulations.

---

**Practice Exercise:**

Create a DataFrame with student information (name, age, grade, major) for at least 5 students. Then:
1. Display the first 3 rows
2. Add a new column for GPA
3. Set the 'name' column as the index
4. Calculate the average age
5. Select students with age > 20
