# Module 12: Data Processing with Pandas

## Theory Section 09: MultiIndex and Hierarchical Data

### Learning Objectives
- Understand hierarchical indexing (MultiIndex)
- Create MultiIndex DataFrames and Series
- Select and slice with MultiIndex
- Perform operations on hierarchical data
- Stack and unstack data
- Use advanced indexing techniques

### Introduction to MultiIndex

MultiIndex (hierarchical index) allows you to have multiple levels of indices on an axis, enabling higher-dimensional data representation in a 2D DataFrame.

```python
import pandas as pd
import numpy as np

# Simple MultiIndex Series
index = pd.MultiIndex.from_tuples([
    ('A', 'X'), ('A', 'Y'), ('B', 'X'), ('B', 'Y')
])
s = pd.Series([1, 2, 3, 4], index=index)
print(s)
# Output:
# A  X    1
#    Y    2
# B  X    3
#    Y    4
```

### Creating MultiIndex

#### From Tuples

```python
# From list of tuples
index = pd.MultiIndex.from_tuples([
    ('A', 'x', 1),
    ('A', 'x', 2),
    ('A', 'y', 1),
    ('B', 'x', 1),
    ('B', 'y', 2)
], names=['first', 'second', 'third'])

s = pd.Series(np.random.randn(5), index=index)
print(s)
```

#### From Arrays

```python
# From multiple arrays
arrays = [
    ['A', 'A', 'B', 'B'],
    ['one', 'two', 'one', 'two']
]
index = pd.MultiIndex.from_arrays(arrays, names=['letter', 'number'])

df = pd.DataFrame(np.random.randn(4, 2), index=index, columns=['X', 'Y'])
print(df)
# Output:
#                X         Y
# letter number              
# A      one    0.123    -0.456
#        two    0.789     1.234
# B      one   -0.321     0.654
#        two    0.987    -0.123
```

#### From Product

```python
# Cartesian product of iterables
index = pd.MultiIndex.from_product([
    ['A', 'B'],
    ['x', 'y', 'z']
], names=['letter', 'coordinate'])

df = pd.DataFrame(np.random.randn(6, 2), index=index, columns=['value1', 'value2'])
print(df)
```

#### From DataFrame

```python
# From existing DataFrame columns
df = pd.DataFrame({
    'state': ['CA', 'CA', 'NY', 'NY'],
    'city': ['SF', 'LA', 'NYC', 'Buffalo'],
    'population': [800000, 400000, 8000000, 250000]
})

# Set MultiIndex from columns
df_multi = df.set_index(['state', 'city'])
print(df_multi)
# Output:
#               population
# state city              
# CA    SF         800000
#       LA         400000
# NY    NYC       8000000
#       Buffalo    250000
```

### MultiIndex Properties

```python
# Create MultiIndex DataFrame
index = pd.MultiIndex.from_product([
    ['Store1', 'Store2'],
    ['Q1', 'Q2', 'Q3', 'Q4']
], names=['Store', 'Quarter'])

df = pd.DataFrame({
    'Sales': np.random.randint(10000, 50000, 8),
    'Profit': np.random.randint(1000, 10000, 8)
}, index=index)

# Index properties
print(df.index.names)      # ['Store', 'Quarter']
print(df.index.levels)     # [['Store1', 'Store2'], ['Q1', 'Q2', 'Q3', 'Q4']]
print(df.index.nlevels)    # 2

# Get level values
print(df.index.get_level_values(0))  # Store level
print(df.index.get_level_values('Quarter'))  # Quarter level
```

### Indexing and Selecting

#### Basic Selection

```python
# Select outer level
df.loc['Store1']
# Output:
#          Sales  Profit
# Quarter              
# Q1       23451   4532
# Q2       34567   6234
# Q3       45678   7345
# Q4       56789   8456

# Select specific index tuple
df.loc[('Store1', 'Q1')]
# Output:
# Sales     23451
# Profit     4532

# Select multiple tuples
df.loc[[('Store1', 'Q1'), ('Store2', 'Q3')]]
```

#### Slicing with MultiIndex

```python
# Slice outer level
df.loc['Store1':'Store2']

# Slice inner level (requires sorted index)
df_sorted = df.sort_index()
df_sorted.loc[(slice(None), 'Q1'), :]
# All stores, Q1 only

# Slice both levels
df_sorted.loc[('Store1', 'Q1'):('Store2', 'Q3')]

# Using IndexSlice
idx = pd.IndexSlice
df_sorted.loc[idx[:, 'Q1':'Q2'], :]
# All stores, Q1 to Q2
```

#### Cross-Section

```python
# Get cross-section at specific level value
df.xs('Q1', level='Quarter')
# Output:
#         Sales  Profit
# Store               
# Store1  23451   4532
# Store2  34567   6543

# Get cross-section at outer level
df.xs('Store1', level='Store')

# Multiple levels
df.xs(('Store1', 'Q1'))
```

#### Boolean Indexing

```python
# Boolean indexing with MultiIndex
mask = df['Sales'] > 30000
df[mask]

# Filter by level
df[df.index.get_level_values('Quarter') == 'Q1']
```

### Sorting MultiIndex

```python
# Sort by index
df_sorted = df.sort_index()

# Sort by specific level
df_sorted = df.sort_index(level='Quarter')
df_sorted = df.sort_index(level=1)  # By position

# Sort by multiple levels
df_sorted = df.sort_index(level=['Quarter', 'Store'])

# Sort descending
df_sorted = df.sort_index(ascending=False)

# Sort by values
df_sorted = df.sort_values('Sales')
```

### Stacking and Unstacking

#### Stack (Columns to Index)

```python
# Create simple DataFrame
df = pd.DataFrame({
    'A': [1, 2, 3],
    'B': [4, 5, 6],
    'C': [7, 8, 9]
}, index=['X', 'Y', 'Z'])

# Stack - pivot columns to index
stacked = df.stack()
print(stacked)
# Output:
# X  A    1
#    B    4
#    C    7
# Y  A    2
#    B    5
#    C    8
# Z  A    3
#    B    6
#    C    9

# Result is a Series with MultiIndex
print(type(stacked))  # Series
```

#### Unstack (Index to Columns)

```python
# Unstack - pivot index level to columns
unstacked = stacked.unstack()
print(unstacked)
# Output (back to original DataFrame):
#    A  B  C
# X  1  4  7
# Y  2  5  8
# Z  3  6  9

# Unstack specific level
df_multi = pd.DataFrame({
    'value': [1, 2, 3, 4]
}, index=pd.MultiIndex.from_tuples([
    ('A', 'x'), ('A', 'y'), ('B', 'x'), ('B', 'y')
], names=['letter', 'coord']))

# Unstack inner level (default)
df_multi.unstack()
# Output:
#         value    
# coord       x  y
# letter          
# A           1  2
# B           3  4

# Unstack outer level
df_multi.unstack(level=0)
# Output:
#        value    
# letter     A  B
# coord          
# x          1  3
# y          2  4
```

#### Handling Missing Data in Stack/Unstack

```python
# DataFrame with missing values
df = pd.DataFrame({
    'A': [1, 2, np.nan],
    'B': [4, np.nan, 6],
    'C': [7, 8, 9]
}, index=['X', 'Y', 'Z'])

# Stack drops NaN by default
stacked = df.stack()

# Keep NaN values
stacked = df.stack(dropna=False)

# Unstack fills with NaN
unstacked = stacked.unstack()

# Fill NaN with specific value
unstacked = stacked.unstack(fill_value=0)
```

### Reshaping with MultiIndex

```python
# Create sample data
df = pd.DataFrame({
    'date': pd.date_range('2024-01-01', periods=6),
    'city': ['NYC', 'NYC', 'LA', 'LA', 'SF', 'SF'],
    'temperature': [32, 35, 65, 68, 58, 60],
    'humidity': [70, 68, 45, 43, 55, 53]
})

# Set MultiIndex
df_multi = df.set_index(['city', 'date'])

# Reshape: stack temperature and humidity
df_long = df_multi.stack()
print(df_long)

# Unstack city to columns
df_wide = df_multi.unstack(level='city')
print(df_wide)
```

### Swapping Levels

```python
# Create MultiIndex
index = pd.MultiIndex.from_product([
    ['A', 'B'],
    ['x', 'y']
], names=['letter', 'coord'])

df = pd.DataFrame(np.random.randn(4, 2), index=index, columns=['val1', 'val2'])

# Swap levels
df_swapped = df.swaplevel()
print(df_swapped.index.names)  # ['coord', 'letter']

# Swap specific levels
df_swapped = df.swaplevel('letter', 'coord')

# Sort after swapping
df_swapped = df.swaplevel().sort_index()
```

### Reordering Levels

```python
# Create 3-level MultiIndex
index = pd.MultiIndex.from_product([
    ['A', 'B'],
    ['x', 'y'],
    [1, 2]
], names=['first', 'second', 'third'])

df = pd.DataFrame(np.random.randn(8, 1), index=index, columns=['value'])

# Reorder levels
df_reordered = df.reorder_levels(['third', 'first', 'second'])
print(df_reordered.index.names)  # ['third', 'first', 'second']
```

### Operations on MultiIndex

#### Aggregations by Level

```python
# Create sample data
index = pd.MultiIndex.from_product([
    ['Store1', 'Store2'],
    ['Q1', 'Q2', 'Q3', 'Q4']
], names=['Store', 'Quarter'])

df = pd.DataFrame({
    'Sales': np.random.randint(10000, 50000, 8),
    'Profit': np.random.randint(1000, 10000, 8)
}, index=index)

# Sum by level
df.sum(level='Store')
# Output:
#         Sales  Profit
# Store               
# Store1  156789  23456
# Store2  167890  24567

# Mean by level
df.mean(level='Quarter')

# Multiple aggregations
df.groupby(level='Store').agg(['sum', 'mean', 'std'])
```

#### Transform by Level

```python
# Normalize by store (subtract mean)
df_normalized = df.groupby(level='Store').transform(lambda x: x - x.mean())

# Percentage of total by store
df_pct = df.groupby(level='Store').transform(lambda x: x / x.sum() * 100)
```

### MultiIndex on Columns

```python
# Create DataFrame with MultiIndex columns
columns = pd.MultiIndex.from_product([
    ['Sales', 'Profit'],
    ['Q1', 'Q2', 'Q3', 'Q4']
], names=['Metric', 'Quarter'])

df = pd.DataFrame(
    np.random.randint(1000, 10000, (3, 8)),
    index=['Store1', 'Store2', 'Store3'],
    columns=columns
)

print(df)
# Output:
# Metric   Sales                    Profit                  
# Quarter     Q1    Q2    Q3    Q4     Q1    Q2    Q3    Q4
# Store1    5432  6543  7654  8765   1234  2345  3456  4567
# Store2    4321  5432  6543  7654   1123  2234  3345  4456
# Store3    3210  4321  5432  6543   1012  2123  3234  4345

# Select column level
df['Sales']
# All Sales quarters

# Select specific column
df[('Sales', 'Q1')]

# Select multiple columns
df[[('Sales', 'Q1'), ('Profit', 'Q1')]]

# Transpose to swap index and columns
df.T
```

### Reset and Set Index

```python
# Reset MultiIndex to columns
df_reset = df.reset_index()
print(df_reset.columns)  # ['Store', 'Quarter', 'Sales', 'Profit']

# Reset specific level
df_reset = df.reset_index(level='Quarter')

# Set MultiIndex from columns
df_multi = df_reset.set_index(['Store', 'Quarter'])

# Add level to existing index
df['NewLevel'] = ['A', 'B'] * 4
df_new = df.set_index('NewLevel', append=True)
```

### Practical Examples

#### Example 1: Sales Analysis

```python
# Sales data with store, year, quarter
data = {
    'Store': ['S1', 'S1', 'S1', 'S1', 'S2', 'S2', 'S2', 'S2'],
    'Year': [2023, 2023, 2024, 2024, 2023, 2023, 2024, 2024],
    'Quarter': ['Q1', 'Q2', 'Q1', 'Q2', 'Q1', 'Q2', 'Q1', 'Q2'],
    'Sales': [10000, 12000, 11000, 13000, 15000, 17000, 16000, 18000],
    'Costs': [7000, 8000, 7500, 8500, 10000, 11000, 10500, 11500]
}
df = pd.DataFrame(data)

# Create MultiIndex
df_multi = df.set_index(['Store', 'Year', 'Quarter'])

# Calculate profit
df_multi['Profit'] = df_multi['Sales'] - df_multi['Costs']

# Analyze by store
store_totals = df_multi.sum(level='Store')

# Year-over-year comparison
yoy = df_multi.xs('Q1', level='Quarter').unstack('Year')
yoy['Growth'] = (yoy[('Sales', 2024)] - yoy[('Sales', 2023)]) / yoy[('Sales', 2023)] * 100
```

#### Example 2: Time Series with Categories

```python
# Temperature data for multiple cities
dates = pd.date_range('2024-01-01', periods=90)
cities = ['NYC', 'LA', 'SF']

# Create MultiIndex
index = pd.MultiIndex.from_product([cities, dates], names=['City', 'Date'])

df = pd.DataFrame({
    'Temperature': np.random.randint(20, 80, len(index)),
    'Humidity': np.random.randint(30, 90, len(index))
}, index=index)

# Monthly averages by city
monthly = df.groupby([
    pd.Grouper(level='City'),
    pd.Grouper(level='Date', freq='M')
]).mean()

# Compare cities
city_comparison = df.groupby(level='City').mean()

# Pivot for visualization
pivot = df.reset_index().pivot(index='Date', columns='City', values='Temperature')
```

### Performance Considerations

```python
# For better performance

# 1. Sort index before operations
df_sorted = df.sort_index()

# 2. Use is_lexsorted() to check sorting
print(df.index.is_lexsorted())

# 3. Use query for complex conditions
df.query('Store == "Store1" and Quarter in ["Q1", "Q2"]')

# 4. Reset index for simpler operations if needed
df_simple = df.reset_index()
# Do operations
df_multi_again = df_simple.set_index(['Store', 'Quarter'])
```

### Summary

- MultiIndex enables hierarchical indexing
- Create with `from_tuples()`, `from_arrays()`, or `from_product()`
- Select with `.loc[]`, `.xs()`, or `IndexSlice`
- Stack/unstack to reshape between long and wide formats
- Aggregate by level with `sum(level=...)` or `groupby(level=...)`
- Can have MultiIndex on both rows and columns

### Key Takeaways

1. MultiIndex represents higher-dimensional data in 2D
2. Always sort MultiIndex for best performance
3. Use `xs()` for cross-sections
4. Stack/unstack for reshaping
5. Aggregate by level for hierarchical summaries
6. Reset index when needed for simpler operations

---

**Practice Exercise:**

1. Create a MultiIndex DataFrame with 3 levels
2. Perform selections at different levels
3. Stack and unstack to change shape
4. Calculate aggregations by each level
5. Create a pivot table with MultiIndex
6. Swap and reorder index levels
7. Handle missing data in hierarchical structure
