# Pandas Fundamentals - Complete Guide

## 📚 What You'll Learn
- Introduction to Pandas
- Series and DataFrames
- Data loading and inspection
- Data selection and filtering
- Basic operations
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐ Beginner to Intermediate

---

## 🎯 What is Pandas?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PANDAS OVERVIEW                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Pandas = Panel Data + Python Data Analysis Library                    │
│                                                                          │
│   Core Data Structures:                                                  │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ SERIES (1-Dimensional)                                          │   │
│   │ ┌───────┬───────┬───────┬───────┐                              │   │
│   │ │  10   │  20   │  30   │  40   │   ← Values                   │   │
│   │ ├───────┼───────┼───────┼───────┤                              │   │
│   │ │   0   │   1   │   2   │   3   │   ← Index                    │   │
│   │ └───────┴───────┴───────┴───────┘                              │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ DATAFRAME (2-Dimensional - like a table)                        │   │
│   │         Name      Age     City                                  │   │
│   │     ┌─────────┬────────┬──────────┐                            │   │
│   │  0  │  Alice  │   25   │  NYC     │                            │   │
│   │  1  │  Bob    │   30   │  LA      │                            │   │
│   │  2  │  Carol  │   35   │  Chicago │                            │   │
│   │     └─────────┴────────┴──────────┘                            │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   Key Features:                                                          │
│   ├── Labeled data structures (index + columns)                        │
│   ├── Handles missing data (NaN)                                       │
│   ├── Read/write multiple formats (CSV, Excel, SQL, JSON)             │
│   ├── Powerful data manipulation (filter, join, group)                │
│   └── Built on NumPy (fast vectorized operations)                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Getting Started

### Installation and Import

```python
# Installation
# pip install pandas

# Standard import convention
import pandas as pd
import numpy as np

# Check version
print(pd.__version__)
```

### Creating Series

```python
# From list
s1 = pd.Series([10, 20, 30, 40])
print(s1)
# 0    10
# 1    20
# 2    30
# 3    40
# dtype: int64

# With custom index
s2 = pd.Series([10, 20, 30], index=['a', 'b', 'c'])
print(s2)
# a    10
# b    20
# c    30

# From dictionary
s3 = pd.Series({'x': 100, 'y': 200, 'z': 300})
print(s3)

# Access elements
print(s2['a'])      # 10
print(s2.loc['a'])  # 10 (label-based)
print(s2.iloc[0])   # 10 (position-based)
```

### Creating DataFrames

```python
# From dictionary
data = {
    'Name': ['Alice', 'Bob', 'Carol'],
    'Age': [25, 30, 35],
    'City': ['NYC', 'LA', 'Chicago']
}
df = pd.DataFrame(data)
print(df)
#     Name  Age     City
# 0  Alice   25      NYC
# 1    Bob   30       LA
# 2  Carol   35  Chicago

# With custom index
df = pd.DataFrame(data, index=['emp1', 'emp2', 'emp3'])

# From list of dictionaries
records = [
    {'Name': 'Alice', 'Age': 25},
    {'Name': 'Bob', 'Age': 30},
    {'Name': 'Carol', 'Age': 35}
]
df = pd.DataFrame(records)

# From NumPy array
arr = np.array([[1, 2, 3], [4, 5, 6]])
df = pd.DataFrame(arr, columns=['A', 'B', 'C'])
```

---

## 📂 Loading Data

### Reading Files

```python
# CSV files
df = pd.read_csv('data.csv')
df = pd.read_csv('data.csv', 
                 sep=',',           # Delimiter
                 header=0,          # Row number for column names
                 index_col='ID',    # Column to use as index
                 usecols=['A', 'B'], # Columns to read
                 dtype={'A': str},   # Column data types
                 na_values=['NA', 'N/A'],  # Values to treat as NaN
                 parse_dates=['Date'],     # Parse as datetime
                 nrows=1000)        # Read first n rows

# Excel files
df = pd.read_excel('data.xlsx', sheet_name='Sheet1')
df = pd.read_excel('data.xlsx', sheet_name=0)  # First sheet

# JSON files
df = pd.read_json('data.json')

# SQL databases (requires SQLAlchemy)
from sqlalchemy import create_engine
engine = create_engine('mssql+pyodbc://server/database?driver=ODBC+Driver+17+for+SQL+Server')
df = pd.read_sql('SELECT * FROM table_name', engine)
df = pd.read_sql_query('SELECT * FROM orders WHERE year = 2024', engine)
df = pd.read_sql_table('orders', engine)
```

### Writing Files

```python
# To CSV
df.to_csv('output.csv', index=False)

# To Excel
df.to_excel('output.xlsx', sheet_name='Data', index=False)

# To SQL
df.to_sql('table_name', engine, if_exists='replace', index=False)
# if_exists: 'fail', 'replace', 'append'

# To JSON
df.to_json('output.json', orient='records')
```

---

## 🔍 Data Inspection

### Viewing Data

```python
# First/last rows
df.head()       # First 5 rows
df.head(10)     # First 10 rows
df.tail()       # Last 5 rows
df.tail(3)      # Last 3 rows

# Random sample
df.sample(5)    # 5 random rows
df.sample(frac=0.1)  # 10% of data

# Shape and info
print(df.shape)      # (rows, columns)
print(len(df))       # Number of rows
print(df.columns)    # Column names
print(df.dtypes)     # Column data types
print(df.info())     # Summary info

# Memory usage
print(df.memory_usage(deep=True))
```

### Statistical Summary

```python
# Describe numeric columns
print(df.describe())
#              Age       Salary
# count   100.000   100.000
# mean     35.500    75000.0
# std      10.123    15000.0
# min      22.000    40000.0
# 25%      28.000    65000.0
# 50%      35.000    75000.0
# 75%      42.000    85000.0
# max      55.000   120000.0

# Include all columns
print(df.describe(include='all'))

# Individual statistics
print(df['Age'].mean())
print(df['Age'].median())
print(df['Age'].std())
print(df['Age'].min())
print(df['Age'].max())
print(df['Age'].sum())
print(df['Age'].count())  # Non-null count
print(df['City'].value_counts())  # Frequency count
print(df['City'].nunique())  # Number of unique values
```

---

## 📊 Selecting Data

### Column Selection

```python
# Single column (returns Series)
ages = df['Age']
ages = df.Age  # Alternative (if column name is valid identifier)

# Multiple columns (returns DataFrame)
subset = df[['Name', 'Age']]
```

### Row Selection

```python
# By index label (loc)
df.loc[0]           # Row with index 0
df.loc[0:2]         # Rows 0, 1, 2 (inclusive!)
df.loc['emp1']      # Row with label 'emp1'

# By position (iloc)
df.iloc[0]          # First row
df.iloc[0:2]        # First 2 rows (exclusive end)
df.iloc[-1]         # Last row
df.iloc[[0, 2, 4]]  # Rows at positions 0, 2, 4

# Combined selection
df.loc[0, 'Name']           # Row 0, column 'Name'
df.loc[0:2, ['Name', 'Age']] # Rows 0-2, columns Name and Age
df.iloc[0, 1]               # First row, second column
df.iloc[0:2, 0:2]           # First 2 rows, first 2 columns
```

### Boolean Filtering

```python
# Single condition
df[df['Age'] > 30]
df[df['City'] == 'NYC']

# Multiple conditions (use & for AND, | for OR)
df[(df['Age'] > 30) & (df['City'] == 'NYC')]
df[(df['Age'] < 25) | (df['Age'] > 40)]

# Using isin
df[df['City'].isin(['NYC', 'LA'])]

# Using between
df[df['Age'].between(25, 35)]

# String conditions
df[df['Name'].str.startswith('A')]
df[df['Name'].str.contains('son')]
df[df['Name'].str.len() > 5]

# Query method (alternative syntax)
df.query('Age > 30 and City == "NYC"')
```

---

## ✏️ Data Manipulation

### Adding/Modifying Columns

```python
# Add new column
df['Country'] = 'USA'
df['AgeNextYear'] = df['Age'] + 1

# Calculated column
df['Bonus'] = df['Salary'] * 0.1

# Conditional column
df['AgeGroup'] = np.where(df['Age'] >= 30, 'Senior', 'Junior')

# Using apply
df['NameUpper'] = df['Name'].apply(lambda x: x.upper())
df['NameLength'] = df['Name'].apply(len)

# Using map (for series)
status_map = {'NYC': 'East', 'LA': 'West', 'Chicago': 'Central'}
df['Region'] = df['City'].map(status_map)

# Multiple columns with apply
def process_row(row):
    return row['Age'] * 2 if row['City'] == 'NYC' else row['Age']
df['Processed'] = df.apply(process_row, axis=1)
```

### Renaming Columns

```python
# Rename specific columns
df = df.rename(columns={'Age': 'Years', 'City': 'Location'})

# Rename all columns
df.columns = ['name', 'years', 'location']

# Rename using function
df.columns = df.columns.str.lower()
df.columns = df.columns.str.replace(' ', '_')
```

### Dropping Data

```python
# Drop columns
df = df.drop(columns=['TempColumn'])
df = df.drop('TempColumn', axis=1)

# Drop rows by index
df = df.drop(index=[0, 1, 2])
df = df.drop([0, 1, 2], axis=0)

# Drop duplicates
df = df.drop_duplicates()
df = df.drop_duplicates(subset=['Name'])  # Based on specific columns
df = df.drop_duplicates(keep='first')  # Keep first occurrence
df = df.drop_duplicates(keep='last')   # Keep last occurrence
df = df.drop_duplicates(keep=False)    # Remove all duplicates
```

### Sorting

```python
# Sort by column
df = df.sort_values('Age')
df = df.sort_values('Age', ascending=False)

# Sort by multiple columns
df = df.sort_values(['City', 'Age'], ascending=[True, False])

# Sort by index
df = df.sort_index()
```

---

## 🔧 Handling Missing Data

```python
# Check for missing values
print(df.isnull())           # Boolean mask
print(df.isnull().sum())     # Count per column
print(df.isnull().any())     # Any nulls per column
print(df.isnull().sum().sum())  # Total nulls

# Drop missing values
df_clean = df.dropna()                    # Drop rows with any NaN
df_clean = df.dropna(subset=['Age'])      # Drop if Age is NaN
df_clean = df.dropna(how='all')           # Drop if ALL values are NaN
df_clean = df.dropna(thresh=2)            # Keep rows with at least 2 non-null

# Fill missing values
df['Age'] = df['Age'].fillna(0)           # Fill with value
df['Age'] = df['Age'].fillna(df['Age'].mean())  # Fill with mean
df['Age'] = df['Age'].fillna(method='ffill')    # Forward fill
df['Age'] = df['Age'].fillna(method='bfill')    # Backward fill

# Replace values
df = df.replace('Unknown', np.nan)
df = df.replace({-999: np.nan, -1: np.nan})
```

---

## 📋 Data Type Conversion

```python
# Check data types
print(df.dtypes)

# Convert data types
df['Age'] = df['Age'].astype(int)
df['Price'] = df['Price'].astype(float)
df['ID'] = df['ID'].astype(str)

# Convert to datetime
df['Date'] = pd.to_datetime(df['Date'])
df['Date'] = pd.to_datetime(df['Date'], format='%Y-%m-%d')

# Convert to categorical
df['Category'] = df['Category'].astype('category')

# Convert multiple columns
df = df.astype({'Age': int, 'Salary': float})

# Handling errors
df['Number'] = pd.to_numeric(df['Number'], errors='coerce')  # Invalid → NaN
```

---

## 🎓 Interview Questions

### Q1: What is the difference between a Series and a DataFrame?
**A:** 
- **Series**: 1-dimensional labeled array (single column)
- **DataFrame**: 2-dimensional labeled data structure (table with rows and columns)
- A DataFrame is essentially a collection of Series

### Q2: What is the difference between loc and iloc?
**A:**
- **loc**: Label-based indexing (uses index labels)
- **iloc**: Integer position-based indexing (uses positions 0, 1, 2...)
- loc[0:2] includes index 2; iloc[0:2] excludes position 2

### Q3: How do you handle missing values in Pandas?
**A:**
- Detect: `isnull()`, `notnull()`, `isna()`
- Drop: `dropna()`
- Fill: `fillna()` with value, mean, ffill, bfill

### Q4: How do you filter rows based on multiple conditions?
**A:** Use boolean indexing with `&` (AND) and `|` (OR):
```python
df[(df['Age'] > 30) & (df['City'] == 'NYC')]
```
Note: Parentheses around each condition are required.

### Q5: What is the apply() function?
**A:** Applies a function to each element (Series) or row/column (DataFrame). Useful for custom transformations when vectorized operations aren't available.

### Q6: How do you merge/join DataFrames?
**A:**
- `pd.merge(df1, df2, on='key')` - SQL-style join
- `pd.concat([df1, df2])` - Stack DataFrames
- `df1.join(df2)` - Join on index

### Q7: How do you read a large CSV file efficiently?
**A:**
- Use `chunksize` parameter to read in chunks
- Specify `dtype` to reduce memory
- Use `usecols` to select needed columns
- Consider `nrows` for sampling

### Q8: What is the difference between copy() and view?
**A:**
- Assignment `df2 = df` creates a reference (same object)
- `df2 = df.copy()` creates an independent copy
- Modifying reference affects original; copy doesn't

### Q9: How do you change column data types?
**A:** Use `astype()`, `pd.to_numeric()`, `pd.to_datetime()`:
```python
df['Age'] = df['Age'].astype(int)
df['Date'] = pd.to_datetime(df['Date'])
```

### Q10: How do you get unique values and value counts?
**A:**
```python
df['Column'].unique()        # Array of unique values
df['Column'].nunique()       # Count of unique values
df['Column'].value_counts()  # Frequency of each value
```

---

## 🔗 Related Topics
- [Data Cleaning & Transformation →](./02_data_cleaning.md)
- [Aggregations & GroupBy →](./03_aggregations.md)
- [Merging & Joining →](./04_merging.md)

---

*Next: Learn about Data Cleaning and Transformation in Pandas*
