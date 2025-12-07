# Module 12: Data Processing with Pandas

## Theory Section 06: Merging, Joining, and Concatenating

### Learning Objectives
- Combine multiple DataFrames
- Understand different join types
- Use merge() for SQL-style joins
- Concatenate DataFrames vertically and horizontally
- Handle duplicate column names and indices

### Concatenating DataFrames

Concatenation stacks DataFrames along an axis (rows or columns).

#### Vertical Concatenation (Stacking Rows)

```python
import pandas as pd

df1 = pd.DataFrame({
    'A': ['A0', 'A1', 'A2'],
    'B': ['B0', 'B1', 'B2']
})

df2 = pd.DataFrame({
    'A': ['A3', 'A4', 'A5'],
    'B': ['B3', 'B4', 'B5']
})

# Stack vertically (axis=0, default)
result = pd.concat([df1, df2])
print(result)
# Output:
#     A   B
# 0  A0  B0
# 1  A1  B1
# 2  A2  B2
# 0  A3  B3
# 1  A4  B4
# 2  A5  B5

# Reset index
result = pd.concat([df1, df2], ignore_index=True)

# With keys for multi-index
result = pd.concat([df1, df2], keys=['batch1', 'batch2'])
```

#### Horizontal Concatenation (Stacking Columns)

```python
df1 = pd.DataFrame({
    'A': ['A0', 'A1', 'A2'],
    'B': ['B0', 'B1', 'B2']
})

df2 = pd.DataFrame({
    'C': ['C0', 'C1', 'C2'],
    'D': ['D0', 'D1', 'D2']
})

# Stack horizontally (axis=1)
result = pd.concat([df1, df2], axis=1)
print(result)
# Output:
#     A   B   C   D
# 0  A0  B0  C0  D0
# 1  A1  B1  C1  D1
# 2  A2  B2  C2  D2
```

#### Handling Different Indices

```python
df1 = pd.DataFrame({
    'A': ['A0', 'A1', 'A2'],
    'B': ['B0', 'B1', 'B2']
}, index=[0, 1, 2])

df2 = pd.DataFrame({
    'A': ['A3', 'A4', 'A5'],
    'B': ['B3', 'B4', 'B5']
}, index=[3, 4, 5])

# Union of indices (default)
result = pd.concat([df1, df2], axis=1)

# Intersection of indices (inner join)
result = pd.concat([df1, df2], axis=1, join='inner')

# Outer join (default) - keeps all indices
result = pd.concat([df1, df2], axis=1, join='outer')
```

#### Handling Different Columns

```python
df1 = pd.DataFrame({
    'A': ['A0', 'A1'],
    'B': ['B0', 'B1']
})

df2 = pd.DataFrame({
    'A': ['A2', 'A3'],
    'C': ['C2', 'C3']
})

# Missing columns filled with NaN
result = pd.concat([df1, df2], ignore_index=True)
print(result)
# Output:
#     A    B    C
# 0  A0   B0  NaN
# 1  A1   B1  NaN
# 2  A2  NaN   C2
# 3  A3  NaN   C3

# Keep only common columns (inner join)
result = pd.concat([df1, df2], join='inner', ignore_index=True)
```

### Merging DataFrames

Merging combines DataFrames based on common columns or indices (similar to SQL joins).

#### Basic Merge

```python
df1 = pd.DataFrame({
    'employee_id': [1, 2, 3, 4],
    'name': ['Alice', 'Bob', 'Charlie', 'David']
})

df2 = pd.DataFrame({
    'employee_id': [1, 2, 3, 5],
    'salary': [50000, 60000, 70000, 55000]
})

# Inner join (default) - keeps only matching rows
result = pd.merge(df1, df2, on='employee_id')
print(result)
# Output:
#    employee_id     name  salary
# 0            1    Alice   50000
# 1            2      Bob   60000
# 2            3  Charlie   70000
```

#### Join Types

```python
# Inner join - intersection
result = pd.merge(df1, df2, on='employee_id', how='inner')

# Left join - all from left, matching from right
result = pd.merge(df1, df2, on='employee_id', how='left')
# Output:
#    employee_id     name   salary
# 0            1    Alice  50000.0
# 1            2      Bob  60000.0
# 2            3  Charlie  70000.0
# 3            4    David      NaN

# Right join - all from right, matching from left
result = pd.merge(df1, df2, on='employee_id', how='right')

# Outer join - union (all rows from both)
result = pd.merge(df1, df2, on='employee_id', how='outer')
# Output:
#    employee_id     name   salary
# 0            1    Alice  50000.0
# 1            2      Bob  60000.0
# 2            3  Charlie  70000.0
# 3            4    David      NaN
# 4            5      NaN  55000.0
```

#### Merging on Multiple Columns

```python
df1 = pd.DataFrame({
    'employee_id': [1, 2, 3],
    'department': ['IT', 'HR', 'IT'],
    'name': ['Alice', 'Bob', 'Charlie']
})

df2 = pd.DataFrame({
    'employee_id': [1, 2, 3],
    'department': ['IT', 'HR', 'Sales'],
    'salary': [50000, 60000, 70000]
})

# Merge on multiple columns
result = pd.merge(df1, df2, on=['employee_id', 'department'])
print(result)
# Only rows 1 and 2 match on both columns
```

#### Merging with Different Column Names

```python
df1 = pd.DataFrame({
    'emp_id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie']
})

df2 = pd.DataFrame({
    'employee_id': [1, 2, 3],
    'salary': [50000, 60000, 70000]
})

# Specify left and right keys
result = pd.merge(df1, df2, left_on='emp_id', right_on='employee_id')
print(result)
# Output:
#    emp_id     name  employee_id  salary
# 0       1    Alice            1   50000
# 1       2      Bob            2   60000
# 2       3  Charlie            3   70000

# Drop duplicate column
result = result.drop('employee_id', axis=1)
```

#### Merging on Index

```python
df1 = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie']
}, index=[1, 2, 3])

df2 = pd.DataFrame({
    'salary': [50000, 60000, 70000]
}, index=[1, 2, 3])

# Merge on index
result = pd.merge(df1, df2, left_index=True, right_index=True)

# Alternative: using join()
result = df1.join(df2)
```

#### Handling Duplicate Column Names

```python
df1 = pd.DataFrame({
    'key': [1, 2, 3],
    'value': ['A', 'B', 'C']
})

df2 = pd.DataFrame({
    'key': [1, 2, 3],
    'value': ['X', 'Y', 'Z']
})

# Suffixes for duplicate columns
result = pd.merge(df1, df2, on='key', suffixes=('_left', '_right'))
print(result)
# Output:
#    key value_left value_right
# 0    1          A           X
# 1    2          B           Y
# 2    3          C           Z
```

#### Indicator Column

```python
# Add indicator column showing source of each row
result = pd.merge(df1, df2, on='key', how='outer', indicator=True)
print(result)
# _merge column shows: 'left_only', 'right_only', or 'both'

# Custom indicator name
result = pd.merge(df1, df2, on='key', how='outer', indicator='source')
```

### Joining DataFrames

The `join()` method is a convenient shortcut for merging on indices.

```python
df1 = pd.DataFrame({
    'A': ['A0', 'A1', 'A2'],
    'B': ['B0', 'B1', 'B2']
}, index=['K0', 'K1', 'K2'])

df2 = pd.DataFrame({
    'C': ['C0', 'C1', 'C2'],
    'D': ['D0', 'D1', 'D2']
}, index=['K0', 'K1', 'K2'])

# Default: left join on index
result = df1.join(df2)

# Specify join type
result = df1.join(df2, how='inner')
result = df1.join(df2, how='outer')

# Join on specific column
df1 = pd.DataFrame({
    'key': ['K0', 'K1', 'K2'],
    'A': ['A0', 'A1', 'A2']
})

df2 = pd.DataFrame({
    'C': ['C0', 'C1', 'C2']
}, index=['K0', 'K1', 'K2'])

result = df1.join(df2, on='key')
```

### Combining Multiple DataFrames

```python
# Concatenate multiple DataFrames
df1 = pd.DataFrame({'A': [1, 2]})
df2 = pd.DataFrame({'A': [3, 4]})
df3 = pd.DataFrame({'A': [5, 6]})

result = pd.concat([df1, df2, df3], ignore_index=True)

# Chain multiple merges
employees = pd.DataFrame({
    'emp_id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie']
})

salaries = pd.DataFrame({
    'emp_id': [1, 2, 3],
    'salary': [50000, 60000, 70000]
})

departments = pd.DataFrame({
    'emp_id': [1, 2, 3],
    'department': ['IT', 'HR', 'Sales']
})

# Chain merges
result = employees.merge(salaries, on='emp_id').merge(departments, on='emp_id')

# Or using reduce
from functools import reduce

dfs = [employees, salaries, departments]
result = reduce(lambda left, right: pd.merge(left, right, on='emp_id'), dfs)
```

### One-to-Many and Many-to-Many Merges

```python
# One-to-Many: One department, many employees
departments = pd.DataFrame({
    'dept_id': [1, 2, 3],
    'dept_name': ['IT', 'HR', 'Sales']
})

employees = pd.DataFrame({
    'emp_id': [1, 2, 3, 4, 5],
    'name': ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
    'dept_id': [1, 1, 2, 2, 3]
})

result = pd.merge(employees, departments, on='dept_id')
print(result)
# Department info repeated for each employee

# Many-to-Many: Students and Courses
students = pd.DataFrame({
    'student_id': [1, 1, 2, 2, 3],
    'course_id': ['Math', 'CS', 'Math', 'Physics', 'CS']
})

courses = pd.DataFrame({
    'course_id': ['Math', 'CS', 'Physics'],
    'instructor': ['Dr. Smith', 'Dr. Jones', 'Dr. Brown']
})

result = pd.merge(students, courses, on='course_id')
# Cartesian product for matching keys
```

### Performance Considerations

```python
# For large DataFrames

# 1. Use appropriate join type
result = pd.merge(df1, df2, on='key', how='inner')  # Faster than outer

# 2. Merge on indexed columns
df1 = df1.set_index('key')
df2 = df2.set_index('key')
result = df1.join(df2)

# 3. Use categorical data for repeated values
df['category'] = df['category'].astype('category')

# 4. Sort DataFrames before merging (for sorted=True optimization)
df1 = df1.sort_values('key')
df2 = df2.sort_values('key')
result = pd.merge(df1, df2, on='key')

# 5. For very large datasets, consider Dask or database operations
```

### Common Patterns

```python
# Pattern 1: Append new rows
new_data = pd.DataFrame({'A': [3, 4], 'B': [7, 8]})
df = pd.concat([df, new_data], ignore_index=True)

# Pattern 2: Add columns from lookup table
lookup = pd.DataFrame({
    'product_id': [1, 2, 3],
    'product_name': ['Widget', 'Gadget', 'Tool']
})
sales = pd.DataFrame({
    'sale_id': [1, 2, 3],
    'product_id': [1, 2, 1],
    'quantity': [10, 5, 15]
})
sales_with_names = pd.merge(sales, lookup, on='product_id')

# Pattern 3: Update values from another DataFrame
df1 = df1.merge(df2[['key', 'updated_value']], on='key', how='left')
df1['value'] = df1['updated_value'].fillna(df1['value'])
df1 = df1.drop('updated_value', axis=1)

# Pattern 4: Find rows only in one DataFrame
result = pd.merge(df1, df2, on='key', how='outer', indicator=True)
only_in_df1 = result[result['_merge'] == 'left_only']
```

### Validation

```python
# Validate merge relationships
result = pd.merge(df1, df2, on='key', validate='one_to_one')
# validate options: 'one_to_one', 'one_to_many', 'many_to_one', 'many_to_many'

# This will raise error if relationship doesn't match
try:
    result = pd.merge(df1, df2, on='key', validate='one_to_one')
except pd.errors.MergeError as e:
    print("Merge validation failed:", e)
```

### Summary

- `concat()` stacks DataFrames vertically or horizontally
- `merge()` performs SQL-style joins based on columns
- `join()` is a shortcut for merging on indices
- Use `how` parameter to specify join type: inner, left, right, outer
- Handle duplicate columns with `suffixes` parameter
- Use `indicator=True` to track merge sources
- Validate merges with `validate` parameter

### Key Takeaways

1. Use `concat()` for stacking, `merge()` for joining
2. Inner join keeps only matching rows
3. Left/right joins keep all from one side
4. Outer join keeps all rows from both DataFrames
5. Always check for duplicate keys in many-to-many joins
6. Use `indicator` to identify merge sources

---

**Practice Exercise:**

1. Create three DataFrames: employees, salaries, departments
2. Perform inner join between employees and salaries
3. Perform left join to add department information
4. Find employees without salary information
5. Concatenate multiple monthly sales DataFrames
6. Create a pivot table from the combined data
