# Pandas Merging & Joining - Complete Guide

## 📚 What You'll Learn
- Merge operations (SQL-style joins)
- Join methods
- Concatenation
- Handling duplicates and missing keys
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Join Types Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    JOIN TYPES                                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   LEFT (df_A)              RIGHT (df_B)                                 │
│   ┌────┬───────┐           ┌────┬───────┐                               │
│   │ ID │ Value │           │ ID │ Info  │                               │
│   ├────┼───────┤           ├────┼───────┤                               │
│   │ 1  │  A    │           │ 2  │  X    │                               │
│   │ 2  │  B    │           │ 3  │  Y    │                               │
│   │ 3  │  C    │           │ 4  │  Z    │                               │
│   └────┴───────┘           └────┴───────┘                               │
│                                                                          │
│   INNER JOIN (how='inner'): Only matching keys                          │
│   ┌────┬───────┬───────┐                                                │
│   │ ID │ Value │ Info  │   Result: ID 2, 3 (both sides)                │
│   ├────┼───────┼───────┤                                                │
│   │ 2  │  B    │  X    │                                                │
│   │ 3  │  C    │  Y    │                                                │
│   └────┴───────┴───────┘                                                │
│                                                                          │
│   LEFT JOIN (how='left'): All from left + matching right                │
│   ┌────┬───────┬───────┐                                                │
│   │ ID │ Value │ Info  │   Result: All left IDs (1, 2, 3)              │
│   ├────┼───────┼───────┤                                                │
│   │ 1  │  A    │ NaN   │                                                │
│   │ 2  │  B    │  X    │                                                │
│   │ 3  │  C    │  Y    │                                                │
│   └────┴───────┴───────┘                                                │
│                                                                          │
│   RIGHT JOIN (how='right'): All from right + matching left              │
│   ┌────┬───────┬───────┐                                                │
│   │ ID │ Value │ Info  │   Result: All right IDs (2, 3, 4)             │
│   ├────┼───────┼───────┤                                                │
│   │ 2  │  B    │  X    │                                                │
│   │ 3  │  C    │  Y    │                                                │
│   │ 4  │ NaN   │  Z    │                                                │
│   └────┴───────┴───────┘                                                │
│                                                                          │
│   OUTER JOIN (how='outer'): All from both sides                         │
│   ┌────┬───────┬───────┐                                                │
│   │ ID │ Value │ Info  │   Result: All IDs (1, 2, 3, 4)                │
│   ├────┼───────┼───────┤                                                │
│   │ 1  │  A    │ NaN   │                                                │
│   │ 2  │  B    │  X    │                                                │
│   │ 3  │  C    │  Y    │                                                │
│   │ 4  │ NaN   │  Z    │                                                │
│   └────┴───────┴───────┘                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 pd.merge() - SQL-Style Joins

### Basic Merge

```python
import pandas as pd
import numpy as np

# Sample DataFrames
df1 = pd.DataFrame({
    'CustomerID': [1, 2, 3, 4],
    'Name': ['Alice', 'Bob', 'Carol', 'David']
})

df2 = pd.DataFrame({
    'CustomerID': [2, 3, 4, 5],
    'City': ['NYC', 'LA', 'Chicago', 'Houston']
})

# Inner join (default)
result = pd.merge(df1, df2, on='CustomerID')
#    CustomerID   Name     City
# 0           2    Bob      NYC
# 1           3  Carol       LA
# 2           4  David  Chicago

# Left join
result = pd.merge(df1, df2, on='CustomerID', how='left')

# Right join
result = pd.merge(df1, df2, on='CustomerID', how='right')

# Outer (full) join
result = pd.merge(df1, df2, on='CustomerID', how='outer')
```

### Different Column Names

```python
df1 = pd.DataFrame({
    'CustID': [1, 2, 3],
    'Name': ['Alice', 'Bob', 'Carol']
})

df2 = pd.DataFrame({
    'CustomerID': [1, 2, 3],
    'City': ['NYC', 'LA', 'Chicago']
})

# Specify left and right keys
result = pd.merge(df1, df2, left_on='CustID', right_on='CustomerID')
#    CustID   Name  CustomerID     City
# 0       1  Alice           1      NYC
# 1       2    Bob           2       LA
# 2       3  Carol           3  Chicago

# Drop duplicate key column
result = result.drop(columns=['CustomerID'])
```

### Multiple Join Keys

```python
df1 = pd.DataFrame({
    'Year': [2023, 2023, 2024, 2024],
    'Quarter': [1, 2, 1, 2],
    'Sales': [100, 150, 200, 180]
})

df2 = pd.DataFrame({
    'Year': [2023, 2023, 2024, 2024],
    'Quarter': [1, 2, 1, 2],
    'Target': [110, 140, 190, 200]
})

# Join on multiple columns
result = pd.merge(df1, df2, on=['Year', 'Quarter'])
#    Year  Quarter  Sales  Target
# 0  2023        1    100     110
# 1  2023        2    150     140
# 2  2024        1    200     190
# 3  2024        2    180     200
```

### Handling Duplicate Column Names

```python
df1 = pd.DataFrame({
    'ID': [1, 2, 3],
    'Value': [10, 20, 30]
})

df2 = pd.DataFrame({
    'ID': [1, 2, 3],
    'Value': [100, 200, 300]
})

# Default: _x and _y suffixes
result = pd.merge(df1, df2, on='ID')
#    ID  Value_x  Value_y
# 0   1       10      100

# Custom suffixes
result = pd.merge(df1, df2, on='ID', suffixes=('_left', '_right'))
#    ID  Value_left  Value_right
# 0   1          10          100
```

### Merge Indicator

```python
# Add indicator column showing merge result
result = pd.merge(df1, df2, on='ID', how='outer', indicator=True)
#    ID  Value_x  Value_y     _merge
# 0   1     10.0    100.0       both
# 1   2     20.0    200.0       both
# 2   3     30.0      NaN  left_only
# 3   4      NaN    400.0 right_only

# Filter by indicator
both = result[result['_merge'] == 'both']
left_only = result[result['_merge'] == 'left_only']
right_only = result[result['_merge'] == 'right_only']
```

---

## 🔗 DataFrame.join() - Index-Based Joins

```python
# join() uses index by default
df1 = pd.DataFrame({
    'Name': ['Alice', 'Bob', 'Carol']
}, index=[1, 2, 3])

df2 = pd.DataFrame({
    'City': ['NYC', 'LA', 'Chicago']
}, index=[1, 2, 3])

# Join on index
result = df1.join(df2)
#     Name     City
# 1  Alice      NYC
# 2    Bob       LA
# 3  Carol  Chicago

# Join with different index
df2 = pd.DataFrame({
    'City': ['NYC', 'LA', 'Chicago']
}, index=[2, 3, 4])

result = df1.join(df2, how='outer')
#      Name     City
# 1   Alice      NaN
# 2     Bob      NYC
# 3   Carol       LA
# 4     NaN  Chicago

# Join on column (left) to index (right)
df1 = df1.reset_index()  # Now has 'index' column
result = df1.join(df2, on='index')
```

---

## 📚 pd.concat() - Stacking DataFrames

### Vertical Concatenation (Append)

```python
df1 = pd.DataFrame({
    'A': [1, 2],
    'B': [3, 4]
})

df2 = pd.DataFrame({
    'A': [5, 6],
    'B': [7, 8]
})

# Stack vertically (axis=0, default)
result = pd.concat([df1, df2])
#    A  B
# 0  1  3
# 1  2  4
# 0  5  7  <- Note: index repeated
# 1  6  8

# Reset index
result = pd.concat([df1, df2], ignore_index=True)
#    A  B
# 0  1  3
# 1  2  4
# 2  5  7
# 3  6  8

# With keys (creates MultiIndex)
result = pd.concat([df1, df2], keys=['first', 'second'])
#           A  B
# first  0  1  3
#        1  2  4
# second 0  5  7
#        1  6  8
```

### Horizontal Concatenation

```python
df1 = pd.DataFrame({
    'A': [1, 2, 3]
})

df2 = pd.DataFrame({
    'B': [4, 5, 6]
})

# Stack horizontally (axis=1)
result = pd.concat([df1, df2], axis=1)
#    A  B
# 0  1  4
# 1  2  5
# 2  3  6
```

### Handling Mismatched Columns

```python
df1 = pd.DataFrame({
    'A': [1, 2],
    'B': [3, 4]
})

df2 = pd.DataFrame({
    'B': [5, 6],
    'C': [7, 8]
})

# Outer join (default): includes all columns
result = pd.concat([df1, df2])
#      A  B    C
# 0  1.0  3  NaN
# 1  2.0  4  NaN
# 0  NaN  5  7.0
# 1  NaN  6  8.0

# Inner join: only common columns
result = pd.concat([df1, df2], join='inner')
#    B
# 0  3
# 1  4
# 0  5
# 1  6
```

---

## 🔍 Advanced Merge Scenarios

### Many-to-Many Joins

```python
# One-to-many: expected behavior
df_orders = pd.DataFrame({
    'OrderID': [1, 2, 3],
    'CustomerID': [101, 102, 101]
})

df_customers = pd.DataFrame({
    'CustomerID': [101, 102],
    'Name': ['Alice', 'Bob']
})

result = pd.merge(df_orders, df_customers, on='CustomerID')
# Works correctly, 3 rows

# Many-to-many: creates cartesian product for duplicates!
df_left = pd.DataFrame({
    'Key': ['A', 'A', 'B'],
    'Left': [1, 2, 3]
})

df_right = pd.DataFrame({
    'Key': ['A', 'A', 'B'],
    'Right': [10, 20, 30]
})

result = pd.merge(df_left, df_right, on='Key')
# Key=A has 2x2=4 rows!
#   Key  Left  Right
# 0   A     1     10
# 1   A     1     20
# 2   A     2     10
# 3   A     2     20
# 4   B     3     30

# Validate to catch duplicates
result = pd.merge(df_left, df_right, on='Key', validate='one_to_one')  # Raises error
result = pd.merge(df_left, df_right, on='Key', validate='one_to_many')  # Left must be unique
result = pd.merge(df_left, df_right, on='Key', validate='many_to_one')  # Right must be unique
```

### Self-Join

```python
# Employee hierarchy
employees = pd.DataFrame({
    'EmpID': [1, 2, 3, 4],
    'Name': ['Alice', 'Bob', 'Carol', 'David'],
    'ManagerID': [None, 1, 1, 2]
})

# Join employees with their managers
result = pd.merge(
    employees,
    employees[['EmpID', 'Name']],
    left_on='ManagerID',
    right_on='EmpID',
    how='left',
    suffixes=('', '_Manager')
)
#    EmpID   Name  ManagerID  EmpID_Manager Name_Manager
# 0      1  Alice        NaN            NaN          NaN
# 1      2    Bob        1.0            1.0        Alice
# 2      3  Carol        1.0            1.0        Alice
# 3      4  David        2.0            2.0          Bob
```

### Merge with Different Data Types

```python
# Common issue: merging int with float or str
df1 = pd.DataFrame({
    'ID': [1, 2, 3],
    'Value': ['A', 'B', 'C']
})

df2 = pd.DataFrame({
    'ID': ['1', '2', '4'],  # String IDs!
    'Info': ['X', 'Y', 'Z']
})

# Fix: convert to same type
df1['ID'] = df1['ID'].astype(str)
# Or
df2['ID'] = df2['ID'].astype(int)

result = pd.merge(df1, df2, on='ID')
```

---

## 📊 Practical Examples

### Data Enrichment

```python
# Main data
sales = pd.DataFrame({
    'OrderID': [1, 2, 3, 4],
    'CustomerID': [101, 102, 101, 103],
    'ProductID': [201, 202, 201, 203],
    'Amount': [100, 200, 150, 300]
})

# Lookup tables
customers = pd.DataFrame({
    'CustomerID': [101, 102, 103],
    'CustomerName': ['Alice', 'Bob', 'Carol'],
    'Region': ['East', 'West', 'East']
})

products = pd.DataFrame({
    'ProductID': [201, 202, 203],
    'ProductName': ['Widget', 'Gadget', 'Gizmo'],
    'Category': ['Tools', 'Electronics', 'Tools']
})

# Enrich sales with customer and product info
enriched = (sales
    .merge(customers, on='CustomerID')
    .merge(products, on='ProductID')
)
```

### Finding Missing Relationships

```python
# Find orders without valid customers
result = pd.merge(sales, customers, on='CustomerID', how='left', indicator=True)
missing_customers = result[result['_merge'] == 'left_only']

# Find customers without orders
result = pd.merge(customers, sales, on='CustomerID', how='left', indicator=True)
inactive_customers = result[result['_merge'] == 'left_only']

# Anti-join: left table rows NOT in right table
left_only = pd.merge(df1, df2, on='Key', how='left', indicator=True)
left_only = left_only[left_only['_merge'] == 'left_only'].drop(columns='_merge')
```

### Combining Multiple DataFrames

```python
# List of DataFrames
dfs = [df1, df2, df3, df4]

# Concatenate all
combined = pd.concat(dfs, ignore_index=True)

# Merge all on common key
from functools import reduce
merged = reduce(lambda left, right: pd.merge(left, right, on='Key'), dfs)
```

---

## 🎓 Interview Questions

### Q1: What is the difference between merge() and join()?
**A:**
- **merge()**: SQL-style join on columns, more flexible
- **join()**: Primarily joins on index, simpler syntax for index-based operations

### Q2: What are the four types of joins in Pandas?
**A:**
- **inner**: Only matching keys from both
- **left**: All from left + matches from right
- **right**: All from right + matches from left
- **outer**: All from both, NaN where no match

### Q3: How do you handle duplicate column names in a merge?
**A:** Use the `suffixes` parameter:
```python
pd.merge(df1, df2, on='Key', suffixes=('_left', '_right'))
```

### Q4: What happens in a many-to-many merge?
**A:** Creates a cartesian product for duplicate keys. If key 'A' appears 2 times in left and 3 times in right, result has 6 rows for key 'A'. Use `validate` parameter to catch this.

### Q5: How do you perform an anti-join?
**A:** Merge with indicator, then filter:
```python
result = pd.merge(df1, df2, on='Key', how='left', indicator=True)
anti_join = result[result['_merge'] == 'left_only']
```

### Q6: How do you concatenate DataFrames vertically vs horizontally?
**A:**
- **Vertical**: `pd.concat([df1, df2], axis=0)` (default)
- **Horizontal**: `pd.concat([df1, df2], axis=1)`

### Q7: How do you merge on different column names?
**A:** Use `left_on` and `right_on`:
```python
pd.merge(df1, df2, left_on='CustID', right_on='CustomerID')
```

### Q8: How do you validate merge relationships?
**A:** Use `validate` parameter:
```python
pd.merge(df1, df2, on='Key', validate='one_to_one')  # Raises if duplicates
```

### Q9: How do you find rows that don't match in a join?
**A:** Use `indicator=True`:
```python
result = pd.merge(df1, df2, on='Key', how='outer', indicator=True)
no_match = result[result['_merge'] != 'both']
```

### Q10: What is the difference between concat() with axis=1 and merge()?
**A:**
- **concat(axis=1)**: Aligns on index, no key matching
- **merge()**: Matches on specified columns, SQL-style join

---

## 🔗 Related Topics
- [← Aggregations & GroupBy](./03_aggregations.md)
- [Python for ETL →](../Module_13_Python_ETL/)
- [PySpark Joins →](../Module_15_PySpark/)

---

*Module 12 Complete! Continue to Python for ETL*
