# Quiz 01: Pandas Fundamentals

**Module**: 12 - Data Processing with Pandas  
**Duration**: 45 minutes  
**Total Points**: 25  
**Passing Score**: 70% (18/25)

---

## Section 1: Series and DataFrames (6 points)

### Question 1 (1 point)
Which method creates a Pandas Series from a Python dictionary?

A) `pd.Series(dict)`  
B) `pd.DataFrame(dict)`  
C) `pd.create_series(dict)`  
D) `pd.from_dict(dict)`

**Answer**: A  
**Explanation**: `pd.Series(dict)` creates a Series where dictionary keys become the index and values become the data.

---

### Question 2 (1 point)
What is the default index for a DataFrame created from a list?

A) Alphabetical letters  
B) Integer range starting from 1  
C) Integer range starting from 0  
D) No index is created

**Answer**: C  
**Explanation**: Pandas automatically creates a RangeIndex starting from 0 when no explicit index is provided.

---

### Question 3 (2 points)
Given `df = pd.DataFrame({'A': [1, 2, 3], 'B': [4, 5, 6]})`, what does `df['A']` return?

A) A DataFrame with column A  
B) A Series with values [1, 2, 3]  
C) A list [1, 2, 3]  
D) An error

**Answer**: B  
**Explanation**: Single bracket indexing on a DataFrame returns a Series representing that column.

---

### Question 4 (2 points)
Which statement about Series is TRUE?

A) Series can contain mixed data types  
B) Series is two-dimensional  
C) Series cannot have a custom index  
D) Series does not support vectorized operations

**Answer**: A  
**Explanation**: While not recommended, a Series can contain mixed types (object dtype). Series are one-dimensional, support custom indices, and fully support vectorized operations.

---

## Section 2: Data Selection and Filtering (7 points)

### Question 5 (1 point)
What is the difference between `loc` and `iloc`?

A) `loc` is label-based, `iloc` is position-based  
B) `iloc` is label-based, `loc` is position-based  
C) They are identical  
D) `loc` is faster than `iloc`

**Answer**: A  
**Explanation**: `loc` selects by labels (index/column names), while `iloc` selects by integer positions.

---

### Question 6 (2 points)
Given `df` with columns ['Name', 'Age', 'Salary'], which selects rows where Age > 30 AND Salary > 50000?

A) `df[df['Age'] > 30 and df['Salary'] > 50000]`  
B) `df[(df['Age'] > 30) & (df['Salary'] > 50000)]`  
C) `df[df['Age'] > 30 && df['Salary'] > 50000]`  
D) `df.filter(Age > 30, Salary > 50000)`

**Answer**: B  
**Explanation**: Use `&` for element-wise AND with parentheses around each condition. Python's `and` doesn't work with boolean arrays.

---

### Question 7 (2 points)
What does `df.iloc[2:5, 1:3]` select?

A) Rows 2-5, columns 1-3  
B) Rows 2-4 (inclusive), columns 1-2 (inclusive)  
C) Rows 3-5, columns 2-3  
D) Rows 2-4 (inclusive), columns 2-3 (inclusive)

**Answer**: B  
**Explanation**: `iloc` uses Python slicing: 2:5 means indices 2, 3, 4 (5 excluded); 1:3 means indices 1, 2 (3 excluded).

---

### Question 8 (2 points)
Which method is most efficient for filtering with complex conditions?

A) `df[boolean_expression]`  
B) `df.query('complex condition')`  
C) `df.loc[boolean_expression]`  
D) All are equally efficient

**Answer**: B  
**Explanation**: `query()` can be more efficient for complex conditions as it uses numexpr behind the scenes and has cleaner syntax.

---

## Section 3: Data Loading and I/O (5 points)

### Question 9 (1 point)
Which parameter in `read_csv()` specifies columns to parse as dates?

A) `date_cols`  
B) `parse_dates`  
C) `date_parser`  
D) `datetime_cols`

**Answer**: B  
**Explanation**: `parse_dates` parameter accepts a list of column names or indices to parse as datetime objects.

---

### Question 10 (2 points)
When reading a large CSV file (10GB), which approach is most memory-efficient?

A) `pd.read_csv(file)`  
B) `pd.read_csv(file, chunksize=10000)`  
C) `pd.read_csv(file, low_memory=True)`  
D) `pd.read_csv(file, memory_map=True)`

**Answer**: B  
**Explanation**: Using `chunksize` returns an iterator that reads the file in chunks, avoiding loading the entire file into memory.

---

### Question 11 (2 points)
Which format is best for fast serialization/deserialization of DataFrames?

A) CSV  
B) Excel  
C) JSON  
D) Parquet

**Answer**: D  
**Explanation**: Parquet is a columnar storage format optimized for fast read/write operations and efficient compression, ideal for DataFrames.

---

## Section 4: Data Cleaning (7 points)

### Question 12 (1 point)
What does `df.dropna()` do by default?

A) Drops columns with any missing values  
B) Drops rows with any missing values  
C) Fills missing values with 0  
D) Replaces missing values with mean

**Answer**: B  
**Explanation**: By default, `dropna()` drops any row containing at least one NaN value.

---

### Question 13 (2 points)
Given `df` with missing values, which fills numeric columns with median and categorical with mode?

A)
```python
df.fillna(df.median())
```

B)
```python
for col in df.columns:
    if df[col].dtype in ['float64', 'int64']:
        df[col].fillna(df[col].median(), inplace=True)
    else:
        df[col].fillna(df[col].mode()[0], inplace=True)
```

C)
```python
df.fillna(method='ffill')
```

D)
```python
df.interpolate()
```

**Answer**: B  
**Explanation**: This approach checks each column's data type and applies the appropriate fill strategy.

---

### Question 14 (2 points)
What does `df.drop_duplicates(subset=['A', 'B'], keep='last')` do?

A) Keeps the first occurrence of duplicates in columns A and B  
B) Keeps the last occurrence of duplicates in columns A and B  
C) Drops all duplicates including originals  
D) Drops columns A and B if they have duplicates

**Answer**: B  
**Explanation**: When duplicates are found based on columns A and B, it keeps the last occurrence and drops earlier ones.

---

### Question 15 (2 points)
Which method is best for detecting outliers using IQR (Interquartile Range)?

A)
```python
Q1 = df['col'].quantile(0.25)
Q3 = df['col'].quantile(0.75)
IQR = Q3 - Q1
outliers = (df['col'] < Q1 - 1.5*IQR) | (df['col'] > Q3 + 1.5*IQR)
```

B)
```python
outliers = df['col'] > df['col'].mean() + 3*df['col'].std()
```

C)
```python
outliers = df['col'].isnull()
```

D)
```python
outliers = df['col'].duplicated()
```

**Answer**: A  
**Explanation**: The IQR method (Q1 - 1.5*IQR to Q3 + 1.5*IQR) is a standard statistical approach for outlier detection.

---

## Coding Questions (Remaining points will be earned through practical coding)

### Question 16 (3 points)
Write code to create a DataFrame from this dictionary and add a column 'Total' that is the sum of 'A' and 'B':

```python
data = {'A': [10, 20, 30], 'B': [5, 15, 25]}
```

**Solution**:
```python
import pandas as pd
df = pd.DataFrame(data)
df['Total'] = df['A'] + df['B']
```

**Grading**:
- 1 point: Correct DataFrame creation
- 1 point: Correct column addition
- 1 point: Proper syntax and naming

---

### Question 17 (3 points)
Given a DataFrame `df` with columns ['Date', 'Sales', 'Expenses'], write code to:
1. Convert 'Date' to datetime
2. Filter rows where Sales > Expenses
3. Sort by Date descending

**Solution**:
```python
df['Date'] = pd.to_datetime(df['Date'])
profitable = df[df['Sales'] > df['Expenses']]
result = profitable.sort_values('Date', ascending=False)
```

**Grading**:
- 1 point: Correct datetime conversion
- 1 point: Correct filtering
- 1 point: Correct sorting

---

### Question 18 (2 points)
Write code to read a CSV file handling these requirements:
- File: 'data.csv'
- Parse 'date' column as datetime
- Use 'id' column as index
- Skip first 2 rows

**Solution**:
```python
df = pd.read_csv('data.csv', 
                 parse_dates=['date'],
                 index_col='id',
                 skiprows=2)
```

**Grading**:
- 0.5 points each for: parse_dates, index_col, skiprows, correct syntax

---

## Answer Key Summary

1. A (Series creation)
2. C (Default index)
3. B (Column selection returns Series)
4. A (Mixed types possible)
5. A (loc vs iloc)
6. B (Multiple conditions with &)
7. B (iloc slicing)
8. B (query efficiency)
9. B (parse_dates)
10. B (chunksize for large files)
11. D (Parquet best format)
12. B (dropna default)
13. B (Conditional filling)
14. B (drop_duplicates with keep)
15. A (IQR outlier detection)
16. Coding: DataFrame creation and column addition
17. Coding: Date conversion, filtering, sorting
18. Coding: CSV reading with parameters

---

## Scoring Guide

- **23-25 points**: Excellent (90-100%)
- **20-22 points**: Good (80-89%)
- **18-19 points**: Passing (70-79%)
- **Below 18**: Needs Review (<70%)

## Time Management

- Multiple Choice (Q1-15): 30 minutes
- Coding Questions (Q16-18): 15 minutes
- Review: 5 minutes (if time permits)

## Tips for Success

1. Read each question carefully
2. Eliminate obviously wrong answers first
3. Test your code mentally or on paper
4. Watch for syntax details (& vs and, parentheses)
5. Remember: Series vs DataFrame return types
6. Know the difference between loc and iloc
7. Understand when to use various I/O formats
8. Practice common data cleaning patterns

---

**Good luck!**
