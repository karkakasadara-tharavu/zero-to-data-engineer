# Module 12: Data Processing with Pandas

## Theory Section 05: Data Transformation and Aggregation

### Learning Objectives
- Apply functions to transform data
- Use apply(), map(), and applymap()
- Perform groupby operations
- Create pivot tables and cross-tabulations
- Aggregate data efficiently

### Applying Functions

#### Using apply()

`apply()` applies a function along an axis of the DataFrame.

```python
import pandas as pd
import numpy as np

df = pd.DataFrame({
    'A': [1, 2, 3, 4, 5],
    'B': [10, 20, 30, 40, 50],
    'C': [100, 200, 300, 400, 500]
})

# Apply function to each column
def double_values(x):
    return x * 2

df_doubled = df.apply(double_values)

# Lambda function
df_doubled = df.apply(lambda x: x * 2)

# Apply to specific column
df['A_squared'] = df['A'].apply(lambda x: x**2)

# Apply with multiple columns
df['sum_AB'] = df.apply(lambda row: row['A'] + row['B'], axis=1)

# Complex function
def categorize_value(row):
    if row['A'] > 3:
        return 'High'
    elif row['A'] > 1:
        return 'Medium'
    else:
        return 'Low'

df['category'] = df.apply(categorize_value, axis=1)

# With additional arguments
def multiply_by(x, multiplier):
    return x * multiplier

df_multiplied = df.apply(multiply_by, multiplier=3)
```

#### Using map()

`map()` applies a function to each element of a Series.

```python
# Map with function
df['A_doubled'] = df['A'].map(lambda x: x * 2)

# Map with dictionary
mapping = {1: 'One', 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five'}
df['A_text'] = df['A'].map(mapping)

# Map with Series
mapping_series = pd.Series(['a', 'b', 'c', 'd', 'e'], index=[1, 2, 3, 4, 5])
df['A_letter'] = df['A'].map(mapping_series)
```

#### Using applymap()

`applymap()` applies a function element-wise across the entire DataFrame.

```python
# Apply to all elements
df_formatted = df.applymap(lambda x: f'${x:.2f}')

# Type conversion
df_str = df.applymap(str)
```

#### Using replace()

```python
# Replace specific values
df = df.replace(0, np.nan)
df = df.replace([1, 2], [100, 200])

# Replace with dictionary
df = df.replace({'A': {1: 100, 2: 200}, 'B': {10: 1000}})

# Replace with regex
df['text'] = df['text'].replace(r'\d+', '', regex=True)
```

### GroupBy Operations

GroupBy is one of the most powerful features in Pandas for data aggregation.

#### Basic GroupBy

```python
df = pd.DataFrame({
    'department': ['IT', 'HR', 'IT', 'Sales', 'HR', 'Sales'],
    'employee': ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank'],
    'salary': [70000, 50000, 75000, 60000, 52000, 65000],
    'years': [3, 5, 2, 4, 6, 3]
})

# Group by single column
grouped = df.groupby('department')

# Access groups
for name, group in grouped:
    print(f"\n{name}:")
    print(group)

# Get specific group
it_group = grouped.get_group('IT')

# Number of groups
print(grouped.ngroups)

# Size of each group
print(grouped.size())

# Group names
print(grouped.groups.keys())
```

#### Aggregation Functions

```python
# Single aggregation
grouped.sum()
grouped.mean()
grouped.median()
grouped.min()
grouped.max()
grouped.std()
grouped.var()
grouped.count()

# Specific column
df.groupby('department')['salary'].mean()

# Multiple columns
df.groupby('department')[['salary', 'years']].mean()

# Multiple aggregations
df.groupby('department').agg({
    'salary': ['mean', 'min', 'max'],
    'years': ['mean', 'sum']
})

# Custom aggregation
df.groupby('department')['salary'].agg(['mean', 'median', lambda x: x.max() - x.min()])

# Named aggregations
df.groupby('department').agg(
    avg_salary=('salary', 'mean'),
    total_years=('years', 'sum'),
    num_employees=('employee', 'count')
)
```

#### Multiple Group Keys

```python
df = pd.DataFrame({
    'department': ['IT', 'HR', 'IT', 'HR', 'IT', 'HR'],
    'location': ['NYC', 'NYC', 'LA', 'LA', 'NYC', 'NYC'],
    'salary': [70000, 50000, 75000, 52000, 72000, 51000]
})

# Group by multiple columns
grouped = df.groupby(['department', 'location'])
print(grouped.mean())

# Unstack for better visualization
print(grouped.mean().unstack())

# Aggregate with multiple keys
result = df.groupby(['department', 'location']).agg({
    'salary': ['mean', 'count']
})
```

#### Transform and Filter

```python
# Transform: return transformed values matching original shape
df['dept_avg_salary'] = df.groupby('department')['salary'].transform('mean')
df['salary_diff_from_avg'] = df['salary'] - df['dept_avg_salary']

# Normalize within group
df['normalized_salary'] = df.groupby('department')['salary'].transform(
    lambda x: (x - x.mean()) / x.std()
)

# Filter: keep groups matching condition
high_avg_depts = df.groupby('department').filter(lambda x: x['salary'].mean() > 60000)

# Keep groups with more than 2 employees
large_depts = df.groupby('department').filter(lambda x: len(x) > 2)
```

#### Apply with GroupBy

```python
# Custom function on each group
def top_earners(group, n=2):
    return group.nlargest(n, 'salary')

df.groupby('department').apply(top_earners, n=1)

# Calculate percentage of total
df['pct_of_dept'] = df.groupby('department')['salary'].apply(
    lambda x: x / x.sum() * 100
)
```

### Pivot Tables

Pivot tables are a way to reshape and summarize data.

#### Basic Pivot Table

```python
df = pd.DataFrame({
    'date': ['2024-01-01', '2024-01-01', '2024-01-02', '2024-01-02'],
    'city': ['NYC', 'LA', 'NYC', 'LA'],
    'temperature': [32, 65, 28, 70],
    'humidity': [65, 45, 70, 40]
})

# Basic pivot
pivot = df.pivot(index='date', columns='city', values='temperature')
print(pivot)
# Output:
# city        LA   NYC
# date                
# 2024-01-01  65    32
# 2024-01-02  70    28

# Pivot table with aggregation
pivot = df.pivot_table(
    values='temperature',
    index='date',
    columns='city',
    aggfunc='mean'
)

# Multiple values
pivot = df.pivot_table(
    values=['temperature', 'humidity'],
    index='date',
    columns='city'
)

# Multiple aggregation functions
pivot = df.pivot_table(
    values='temperature',
    index='date',
    columns='city',
    aggfunc=['mean', 'min', 'max']
)

# With margins (totals)
pivot = df.pivot_table(
    values='temperature',
    index='date',
    columns='city',
    aggfunc='mean',
    margins=True
)
```

#### Advanced Pivot Tables

```python
df = pd.DataFrame({
    'date': pd.date_range('2024-01-01', periods=12, freq='M'),
    'region': ['East', 'West', 'East', 'West'] * 3,
    'product': ['A', 'A', 'B', 'B'] * 3,
    'sales': np.random.randint(100, 1000, 12),
    'quantity': np.random.randint(10, 100, 12)
})

# Multi-index pivot
pivot = df.pivot_table(
    values=['sales', 'quantity'],
    index=['region', 'product'],
    columns=df['date'].dt.quarter,
    aggfunc='sum'
)

# Fill missing values
pivot = df.pivot_table(
    values='sales',
    index='product',
    columns='region',
    fill_value=0
)

# Custom aggregation
pivot = df.pivot_table(
    values='sales',
    index='product',
    columns='region',
    aggfunc={'sales': [np.mean, np.std, len]}
)
```

### Cross-Tabulation

Cross-tabulation (crosstab) computes frequency tables.

```python
df = pd.DataFrame({
    'gender': ['M', 'F', 'M', 'F', 'M', 'F', 'M', 'F'],
    'department': ['IT', 'IT', 'HR', 'HR', 'Sales', 'Sales', 'IT', 'HR'],
    'senior': [True, False, True, False, True, False, False, True]
})

# Basic crosstab
ct = pd.crosstab(df['gender'], df['department'])
print(ct)
# Output:
# department  HR  IT  Sales
# gender                   
# F            2   1      1
# M            1   2      1

# With multiple columns
ct = pd.crosstab(df['gender'], [df['department'], df['senior']])

# Normalize (percentages)
ct = pd.crosstab(df['gender'], df['department'], normalize='index')  # Row percentages
ct = pd.crosstab(df['gender'], df['department'], normalize='columns')  # Column percentages
ct = pd.crosstab(df['gender'], df['department'], normalize='all')  # Overall percentages

# With margins
ct = pd.crosstab(df['gender'], df['department'], margins=True)

# With values and aggregation
sales_df = pd.DataFrame({
    'gender': ['M', 'F', 'M', 'F'],
    'department': ['IT', 'IT', 'HR', 'HR'],
    'salary': [70000, 68000, 55000, 57000]
})

ct = pd.crosstab(
    sales_df['gender'],
    sales_df['department'],
    values=sales_df['salary'],
    aggfunc='mean'
)
```

### Window Functions

```python
df = pd.DataFrame({
    'date': pd.date_range('2024-01-01', periods=10),
    'value': [10, 12, 11, 13, 15, 14, 16, 18, 17, 19]
})

# Rolling mean
df['rolling_mean'] = df['value'].rolling(window=3).mean()

# Rolling sum
df['rolling_sum'] = df['value'].rolling(window=3).sum()

# Expanding window (cumulative)
df['cumsum'] = df['value'].expanding().sum()
df['cum_mean'] = df['value'].expanding().mean()

# Rolling with min_periods
df['rolling_mean'] = df['value'].rolling(window=3, min_periods=1).mean()

# Custom rolling function
df['rolling_range'] = df['value'].rolling(window=3).apply(lambda x: x.max() - x.min())

# Shift (lag/lead)
df['previous_value'] = df['value'].shift(1)      # Lag 1
df['next_value'] = df['value'].shift(-1)         # Lead 1
df['change'] = df['value'] - df['value'].shift(1)
df['pct_change'] = df['value'].pct_change()
```

### Binning and Discretization

```python
# Cut into bins
ages = [18, 25, 32, 45, 28, 52, 38, 29]
bins = [0, 25, 40, 60]
labels = ['Young', 'Middle', 'Senior']
categories = pd.cut(ages, bins=bins, labels=labels)

# Equal-width bins
scores = [65, 75, 85, 95, 55, 70, 80, 90]
categories = pd.cut(scores, bins=4)  # 4 equal-width bins

# Quantile-based bins
categories = pd.qcut(scores, q=4, labels=['Q1', 'Q2', 'Q3', 'Q4'])

# Add to DataFrame
df['age_group'] = pd.cut(df['age'], bins=[0, 30, 50, 100], labels=['Young', 'Middle', 'Senior'])
```

### Summary Statistics

```python
# Single column
df['salary'].describe()
df['salary'].mean()
df['salary'].median()
df['salary'].mode()
df['salary'].std()
df['salary'].var()
df['salary'].min()
df['salary'].max()
df['salary'].quantile([0.25, 0.5, 0.75])

# Correlation
df.corr()
df['A'].corr(df['B'])

# Covariance
df.cov()

# Custom aggregations
df.agg(['mean', 'std', 'min', 'max'])
df[['salary', 'age']].agg({
    'salary': ['mean', 'median'],
    'age': ['min', 'max']
})
```

### Summary

- Use `apply()`, `map()`, and `applymap()` for transformations
- GroupBy enables powerful aggregations by groups
- Pivot tables reshape and summarize data
- Crosstabs create frequency tables
- Window functions enable rolling calculations
- Binning discretizes continuous variables

### Key Takeaways

1. `apply()` works on Series/DataFrame, `map()` on Series only
2. GroupBy is essential for group-wise analysis
3. Pivot tables reshape data for better visualization
4. Use `transform()` to keep original DataFrame shape
5. Window functions enable time-series analysis
6. Choose the right aggregation function for your analysis

---

**Practice Exercise:**

1. Create a sales DataFrame with product, region, date, quantity, revenue
2. Group by region and calculate mean revenue
3. Create a pivot table showing total revenue by product and region
4. Add rolling 3-day average revenue
5. Bin revenue into quartiles
6. Calculate percentage of total revenue by region
