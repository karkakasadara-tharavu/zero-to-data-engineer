# Module 12: Data Processing with Pandas

## Theory Section 02: Working with DataFrames

### Learning Objectives
- Master DataFrame creation methods
- Learn data inspection techniques
- Understand column and row operations
- Practice data selection and filtering
- Handle basic data modifications

### Creating DataFrames

#### From Dictionaries

```python
import pandas as pd

# Dictionary with lists (columns as keys)
data = {
    'product': ['Laptop', 'Mouse', 'Keyboard', 'Monitor'],
    'price': [999.99, 29.99, 79.99, 299.99],
    'quantity': [5, 50, 30, 10]
}
df = pd.DataFrame(data)

# Dictionary with Series
data = {
    'A': pd.Series([1, 2, 3]),
    'B': pd.Series([4, 5, 6])
}
df = pd.DataFrame(data)

# List of dictionaries (rows as dictionaries)
data = [
    {'name': 'Alice', 'age': 25, 'city': 'NYC'},
    {'name': 'Bob', 'age': 30, 'city': 'LA'},
    {'name': 'Charlie', 'age': 35}  # Missing 'city'
]
df = pd.DataFrame(data)
# Missing values filled with NaN
```

#### From NumPy Arrays

```python
import numpy as np

# 2D array
arr = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
df = pd.DataFrame(arr, columns=['A', 'B', 'C'], index=['r1', 'r2', 'r3'])

# Random data
df = pd.DataFrame(
    np.random.randn(5, 3),
    columns=['X', 'Y', 'Z'],
    index=pd.date_range('2024-01-01', periods=5)
)
```

#### From CSV, Excel, JSON

```python
# From CSV
df = pd.read_csv('data.csv')
df = pd.read_csv('data.csv', index_col=0)  # First column as index
df = pd.read_csv('data.csv', usecols=['name', 'age'])  # Select columns

# From Excel
df = pd.read_excel('data.xlsx', sheet_name='Sheet1')
df = pd.read_excel('data.xlsx', sheet_name=0)  # First sheet

# From JSON
df = pd.read_json('data.json')
df = pd.read_json('data.json', orient='records')

# From clipboard
df = pd.read_clipboard()
```

#### From SQL Database

```python
import sqlite3

# Create connection
conn = sqlite3.connect('database.db')

# Read table
df = pd.read_sql('SELECT * FROM employees', conn)
df = pd.read_sql_query('SELECT name, salary FROM employees WHERE salary > 50000', conn)

# Read entire table
df = pd.read_sql_table('employees', conn)

conn.close()
```

### Inspecting DataFrames

#### Basic Information

```python
df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
    'age': [25, 30, 35, 28, 32],
    'salary': [50000, 60000, 70000, 55000, 65000],
    'department': ['HR', 'IT', 'IT', 'Sales', 'HR']
})

# Display first/last rows
print(df.head())        # First 5 rows
print(df.head(3))       # First 3 rows
print(df.tail(2))       # Last 2 rows

# Shape and dimensions
print(df.shape)         # (5, 4) - (rows, columns)
print(df.ndim)          # 2 - dimensions
print(df.size)          # 20 - total elements
print(len(df))          # 5 - number of rows

# Column information
print(df.columns)       # Column names
print(df.columns.tolist())  # As list
print(df.dtypes)        # Data types of each column

# Index information
print(df.index)         # Index range
```

#### DataFrame Info

```python
# Comprehensive summary
print(df.info())
# Output:
# <class 'pandas.core.frame.DataFrame'>
# RangeIndex: 5 entries, 0 to 4
# Data columns (total 4 columns):
#  #   Column      Non-Null Count  Dtype 
# ---  ------      --------------  ----- 
#  0   name        5 non-null      object
#  1   age         5 non-null      int64 
#  2   salary      5 non-null      int64 
#  3   department  5 non-null      object
# dtypes: int64(2), object(2)
# memory usage: 288.0+ bytes

# Memory usage details
print(df.memory_usage(deep=True))
```

#### Statistical Summary

```python
# Numerical columns statistics
print(df.describe())
# Output:
#              age        salary
# count   5.000000      5.000000
# mean   30.000000  60000.000000
# std     3.807887   7905.694150
# min    25.000000  50000.000000
# 25%    28.000000  55000.000000
# 50%    30.000000  60000.000000
# 75%    32.000000  65000.000000
# max    35.000000  70000.000000

# Include all columns
print(df.describe(include='all'))

# Specific percentiles
print(df.describe(percentiles=[0.1, 0.5, 0.9]))

# Individual statistics
print(df['age'].mean())      # Average age
print(df['age'].median())    # Median age
print(df['age'].std())       # Standard deviation
print(df['age'].min())       # Minimum
print(df['age'].max())       # Maximum
print(df['age'].sum())       # Sum
print(df['age'].count())     # Count of non-null values
```

#### Unique Values and Value Counts

```python
# Unique values
print(df['department'].unique())        # array(['HR', 'IT', 'Sales'])
print(df['department'].nunique())       # 3

# Value counts
print(df['department'].value_counts())
# Output:
# HR       2
# IT       2
# Sales    1

# Include percentages
print(df['department'].value_counts(normalize=True))

# Sort by value instead of count
print(df['department'].value_counts(sort=False))
```

### Selecting Data

#### Selecting Columns

```python
# Single column (returns Series)
ages = df['age']
print(type(ages))  # <class 'pandas.core.series.Series'>

# Alternative notation (if column name is valid identifier)
ages = df.age

# Multiple columns (returns DataFrame)
subset = df[['name', 'salary']]
print(type(subset))  # <class 'pandas.core.frame.DataFrame'>

# Select columns by position
first_two_cols = df.iloc[:, :2]

# Select columns by data type
numerical_cols = df.select_dtypes(include=['int64', 'float64'])
object_cols = df.select_dtypes(include=['object'])
```

#### Selecting Rows

```python
# By position (integer-location based)
first_row = df.iloc[0]          # First row
first_three = df.iloc[:3]       # First 3 rows
last_row = df.iloc[-1]          # Last row
specific_rows = df.iloc[[0, 2, 4]]  # Rows 0, 2, 4

# By label (label-based)
df_indexed = df.set_index('name')
alice_row = df_indexed.loc['Alice']
subset = df_indexed.loc[['Alice', 'Charlie']]

# By condition (boolean indexing)
young_employees = df[df['age'] < 30]
high_earners = df[df['salary'] > 60000]
it_dept = df[df['department'] == 'IT']

# Multiple conditions
young_and_rich = df[(df['age'] < 30) & (df['salary'] > 50000)]
hr_or_sales = df[(df['department'] == 'HR') | (df['department'] == 'Sales')]

# Using isin()
selected_depts = df[df['department'].isin(['HR', 'IT'])]
```

#### Selecting Rows and Columns

```python
# loc[rows, columns] - label-based
# iloc[rows, columns] - position-based

# Specific cell
value = df.loc[0, 'name']           # 'Alice'
value = df.iloc[0, 0]               # 'Alice'

# Multiple rows and columns
subset = df.loc[0:2, ['name', 'age']]
subset = df.iloc[0:3, 0:2]

# All rows, specific columns
subset = df.loc[:, ['name', 'salary']]

# Specific rows, all columns
subset = df.loc[0:2, :]

# Conditional selection with specific columns
young_names = df.loc[df['age'] < 30, ['name', 'age']]
```

#### at and iat (Fast Scalar Access)

```python
# Fast access to single value
value = df.at[0, 'name']        # Label-based
value = df.iat[0, 0]            # Position-based

# Faster than loc/iloc for single values
```

### Modifying DataFrames

#### Adding Columns

```python
# Add new column with constant value
df['country'] = 'USA'

# Add column based on calculation
df['annual_bonus'] = df['salary'] * 0.1

# Add column using apply()
df['tax_bracket'] = df['salary'].apply(lambda x: 'High' if x > 60000 else 'Low')

# Add column using conditions
df['senior'] = df['age'] >= 30

# Add multiple columns
df = df.assign(
    bonus=df['salary'] * 0.1,
    total_comp=lambda x: x['salary'] + x['bonus']
)

# Insert column at specific position
df.insert(2, 'years_employed', [2, 5, 8, 3, 6])
```

#### Modifying Columns

```python
# Update entire column
df['age'] = df['age'] + 1

# Update based on condition
df.loc[df['salary'] < 60000, 'salary'] = 60000

# Update specific cells
df.at[0, 'name'] = 'Alicia'
df.iat[0, 0] = 'Alicia'

# Replace values
df['department'] = df['department'].replace('IT', 'Technology')
df = df.replace({'HR': 'Human Resources', 'IT': 'Technology'})

# Rename columns
df = df.rename(columns={'name': 'employee_name', 'salary': 'annual_salary'})
df.columns = ['col1', 'col2', 'col3', 'col4']  # Rename all
```

#### Deleting Columns

```python
# Delete column (in-place)
df.drop('country', axis=1, inplace=True)

# Delete multiple columns
df.drop(['bonus', 'tax_bracket'], axis=1, inplace=True)

# Using del
del df['senior']

# Return new DataFrame without column
df_new = df.drop('department', axis=1)
```

#### Deleting Rows

```python
# Delete by index
df = df.drop(0)                     # Drop row with index 0
df = df.drop([0, 2, 4])             # Drop multiple rows

# Delete by condition
df = df[df['age'] >= 25]            # Keep only age >= 25

# Drop duplicates
df = df.drop_duplicates()
df = df.drop_duplicates(subset=['name'])  # Based on specific column
df = df.drop_duplicates(subset=['name', 'department'], keep='first')

# Reset index after dropping
df = df.reset_index(drop=True)
```

### Sorting Data

```python
# Sort by single column
df_sorted = df.sort_values('age')                          # Ascending
df_sorted = df.sort_values('age', ascending=False)         # Descending

# Sort by multiple columns
df_sorted = df.sort_values(['department', 'salary'], ascending=[True, False])

# Sort in place
df.sort_values('age', inplace=True)

# Sort by index
df_sorted = df.sort_index()
df_sorted = df.sort_index(ascending=False)
```

### Filtering Data

```python
# Single condition
filtered = df[df['age'] > 30]

# Multiple conditions (AND)
filtered = df[(df['age'] > 25) & (df['salary'] > 55000)]

# Multiple conditions (OR)
filtered = df[(df['department'] == 'HR') | (df['department'] == 'IT')]

# NOT condition
filtered = df[~(df['age'] < 30)]

# String methods
filtered = df[df['name'].str.startswith('A')]
filtered = df[df['name'].str.contains('li')]

# Using query() method
filtered = df.query('age > 30 and salary < 70000')
filtered = df.query('department in ["HR", "IT"]')

# Filter by multiple values
departments = ['HR', 'IT']
filtered = df[df['department'].isin(departments)]

# Between
filtered = df[df['age'].between(25, 32)]
```

### Best Practices

1. **Use loc/iloc consistently:** Avoid chained indexing (`df['A'][0]`)
2. **Copy when needed:** Use `.copy()` to avoid SettingWithCopyWarning
3. **Vectorize operations:** Avoid loops, use vectorized operations
4. **Chain methods:** Use method chaining for readable code
5. **Assign vs inplace:** Prefer assignment over inplace operations for clarity

### Common Pitfalls

```python
# BAD: Chained indexing
df['age'][0] = 26  # May not work as expected

# GOOD: Use loc
df.loc[0, 'age'] = 26

# BAD: Modifying view
subset = df[df['age'] > 30]
subset['salary'] = 100000  # SettingWithCopyWarning

# GOOD: Make explicit copy
subset = df[df['age'] > 30].copy()
subset['salary'] = 100000
```

### Summary

- DataFrames can be created from dictionaries, arrays, files, and databases
- Use `.head()`, `.tail()`, `.info()`, `.describe()` for inspection
- Select columns with `df['col']` or `df[['col1', 'col2']]`
- Select rows with `.loc[]` (label) or `.iloc[]` (position)
- Filter data using boolean indexing and `.query()`
- Modify data using `.loc[]`, `.assign()`, `.replace()`
- Sort data with `.sort_values()` and `.sort_index()`

### Key Takeaways

1. `.loc[]` is label-based, `.iloc[]` is position-based
2. Boolean indexing is powerful for filtering
3. Vectorized operations are much faster than loops
4. Always be aware of views vs copies
5. Use `.copy()` when creating subsets you'll modify

---

**Practice Exercise:**

1. Create a DataFrame with employee data (at least 10 rows)
2. Display summary statistics
3. Filter employees with salary > $60,000
4. Add a bonus column (10% of salary)
5. Sort by salary descending
6. Find the average salary by department
