# Module 12: Data Processing with Pandas

## Theory Section 10: Advanced Operations and Features

### Learning Objectives
- Work with categorical data for memory efficiency
- Use string methods and text processing
- Apply custom functions and vectorization
- Work with sparse data structures
- Use method chaining and pipe
- Implement custom accessors and extensions

### Categorical Data

Categorical data type improves performance and memory usage for columns with limited unique values.

```python
import pandas as pd
import numpy as np

# Create regular object dtype
df = pd.DataFrame({
    'id': range(1000000),
    'category': np.random.choice(['A', 'B', 'C', 'D', 'E'], 1000000)
})

print(df['category'].dtype)  # object
print(df.memory_usage(deep=True))  # High memory usage

# Convert to categorical
df['category'] = df['category'].astype('category')
print(df['category'].dtype)  # category
print(df.memory_usage(deep=True))  # Much lower memory usage
```

#### Creating Categorical Data

```python
# Direct creation
cat = pd.Categorical(['a', 'b', 'c', 'a', 'b', 'c'])
print(cat)
# ['a', 'b', 'c', 'a', 'b', 'c']
# Categories (3, object): ['a', 'b', 'c']

# With specific categories
cat = pd.Categorical(['a', 'b', 'c'], categories=['a', 'b', 'c', 'd'])
print(cat.categories)  # Index(['a', 'b', 'c', 'd'], dtype='object')

# Ordered categories
cat = pd.Categorical(['low', 'medium', 'high', 'low'], 
                     categories=['low', 'medium', 'high'], 
                     ordered=True)
print(cat.ordered)  # True

# In DataFrame
df = pd.DataFrame({
    'grade': pd.Categorical(['A', 'B', 'C', 'B', 'A'], 
                            categories=['A', 'B', 'C', 'D', 'F'],
                            ordered=True)
})
```

#### Categorical Operations

```python
# Get categories
print(df['grade'].cat.categories)

# Add categories
df['grade'] = df['grade'].cat.add_categories(['E'])

# Remove categories
df['grade'] = df['grade'].cat.remove_categories(['E'])

# Rename categories
df['grade'] = df['grade'].cat.rename_categories({'A': 'Excellent', 'B': 'Good'})

# Reorder categories
df['grade'] = df['grade'].cat.reorder_categories(['D', 'C', 'B', 'A', 'F'])

# Set ordered
df['grade'] = df['grade'].cat.as_ordered()
df['grade'] = df['grade'].cat.as_unordered()

# Comparison (only works with ordered)
df_ordered = pd.DataFrame({
    'grade': pd.Categorical(['A', 'B', 'C'], 
                            categories=['A', 'B', 'C'],
                            ordered=True)
})
print(df_ordered[df_ordered['grade'] > 'B'])  # Grades better than B
```

#### Categorical Aggregations

```python
# Value counts includes all categories
df['grade'].value_counts()

# GroupBy with categorical
df_sales = pd.DataFrame({
    'category': pd.Categorical(['Electronics', 'Clothing', 'Electronics', 'Food'],
                               categories=['Electronics', 'Clothing', 'Food', 'Books']),
    'sales': [100, 200, 150, 300]
})

# Includes all categories in result (even with 0 count)
result = df_sales.groupby('category', observed=False).sum()
```

### String Methods

Pandas provides vectorized string operations through the `.str` accessor.

```python
# Create sample data
df = pd.DataFrame({
    'text': ['  Hello World  ', 'PYTHON pandas', 'Data Science', 'machine learning']
})

# Basic string methods
df['lower'] = df['text'].str.lower()
df['upper'] = df['text'].str.upper()
df['title'] = df['text'].str.title()
df['strip'] = df['text'].str.strip()
df['lstrip'] = df['text'].str.lstrip()
df['rstrip'] = df['text'].str.rstrip()

# String information
df['length'] = df['text'].str.len()
df['starts_with_d'] = df['text'].str.startswith('D')
df['ends_with_g'] = df['text'].str.endswith('g')
df['contains_and'] = df['text'].str.contains('and', case=False)

# String operations
df['replaced'] = df['text'].str.replace('World', 'Universe')
df['split'] = df['text'].str.split()  # Returns list
df['first_word'] = df['text'].str.split().str[0]

# Slicing
df['first_5'] = df['text'].str[:5]
df['last_5'] = df['text'].str[-5:]

# Padding
df['pad_left'] = df['text'].str.pad(20, side='left', fillchar='*')
df['pad_right'] = df['text'].str.pad(20, side='right')
df['zfill'] = df['text'].str.zfill(20)  # Zero padding
```

#### Regular Expressions

```python
# Extract patterns
df = pd.DataFrame({
    'email': ['user@example.com', 'admin@test.org', 'invalid-email']
})

# Extract email parts
df['username'] = df['email'].str.extract(r'([^@]+)@')
df['domain'] = df['email'].str.extract(r'@([^.]+)')

# Extract all matches
df_phones = pd.DataFrame({
    'text': ['Call 123-456-7890 or 098-765-4321', 'No phone here']
})
df_phones['phones'] = df_phones['text'].str.findall(r'\d{3}-\d{3}-\d{4}')

# Test patterns
df['is_valid_email'] = df['email'].str.match(r'^[^@]+@[^@]+\.[^@]+$')

# Replace with regex
df_text = pd.DataFrame({
    'text': ['abc123def456', 'xyz789']
})
df_text['no_digits'] = df_text['text'].str.replace(r'\d+', '', regex=True)

# Split by regex
df_split = pd.DataFrame({
    'text': ['a,b;c:d', 'x,y;z']
})
df_split['split'] = df_split['text'].str.split(r'[,;:]')
```

#### String Cleaning

```python
# Remove whitespace and normalize
df = pd.DataFrame({
    'text': ['  Hello  World  ', '\tPython\n', '  Data   Science  ']
})

# Clean whitespace
df['cleaned'] = df['text'].str.strip().str.replace(r'\s+', ' ', regex=True)

# Remove special characters
df['alphanumeric'] = df['text'].str.replace(r'[^a-zA-Z0-9\s]', '', regex=True)

# Normalize unicode
df_unicode = pd.DataFrame({
    'text': ['café', 'naïve', 'résumé']
})
df_unicode['normalized'] = df_unicode['text'].str.normalize('NFKD')
```

### Custom Functions and Vectorization

```python
# Apply function to each element
df = pd.DataFrame({
    'A': [1, 2, 3, 4, 5],
    'B': [10, 20, 30, 40, 50]
})

# Apply to column
df['A_squared'] = df['A'].apply(lambda x: x ** 2)

# Apply to row
df['sum'] = df.apply(lambda row: row['A'] + row['B'], axis=1)

# Apply custom function
def categorize(value):
    if value < 2:
        return 'Low'
    elif value < 4:
        return 'Medium'
    else:
        return 'High'

df['category'] = df['A'].apply(categorize)

# Apply to entire DataFrame
def normalize(x):
    return (x - x.min()) / (x.max() - x.min())

df_normalized = df[['A', 'B']].apply(normalize)

# Vectorized operations (faster than apply)
df['A_squared_vec'] = df['A'] ** 2  # Much faster than apply
df['sum_vec'] = df['A'] + df['B']   # Vectorized
```

#### NumPy Universal Functions

```python
# NumPy functions work on Pandas objects
df['sqrt'] = np.sqrt(df['A'])
df['log'] = np.log(df['A'])
df['exp'] = np.exp(df['A'])

# Element-wise operations
df['max_AB'] = np.maximum(df['A'], df['B'])
df['min_AB'] = np.minimum(df['A'], df['B'])

# Conditional operations
df['sign'] = np.where(df['A'] > 3, 'Positive', 'Negative')
df['value'] = np.select(
    [df['A'] < 2, df['A'] < 4, df['A'] >= 4],
    ['Low', 'Medium', 'High']
)
```

### Method Chaining

Method chaining allows sequential operations without intermediate variables.

```python
# Without chaining
df = pd.read_csv('data.csv')
df = df[df['age'] > 18]
df = df.dropna()
df = df.assign(age_group=lambda x: pd.cut(x['age'], bins=[0, 30, 60, 100]))
df = df.sort_values('age')

# With chaining
df = (pd.read_csv('data.csv')
      .query('age > 18')
      .dropna()
      .assign(age_group=lambda x: pd.cut(x['age'], bins=[0, 30, 60, 100]))
      .sort_values('age'))

# Complex example
result = (df
          .assign(
              total=lambda x: x['quantity'] * x['price'],
              discount=lambda x: x['total'] * 0.1
          )
          .query('total > 100')
          .groupby('category')
          .agg({'total': 'sum', 'discount': 'mean'})
          .reset_index()
          .sort_values('total', ascending=False))
```

### Pipe Method

The `pipe` method enables using custom functions in method chains.

```python
# Define custom functions
def remove_outliers(df, column, threshold=3):
    """Remove outliers using z-score"""
    z_scores = np.abs((df[column] - df[column].mean()) / df[column].std())
    return df[z_scores < threshold]

def add_features(df):
    """Add computed features"""
    return df.assign(
        feature1=lambda x: x['A'] * x['B'],
        feature2=lambda x: x['A'] / x['B']
    )

# Use pipe in chain
result = (df
          .pipe(remove_outliers, column='A', threshold=2)
          .pipe(add_features)
          .sort_values('feature1'))

# Pipe with lambda
result = (df
          .pipe(lambda x: x[x['A'] > 0])  # Custom filtering
          .pipe(lambda x: x.assign(log_A=np.log(x['A']))))
```

### Sparse Data Structures

Sparse data structures save memory when data contains many missing or zero values.

```python
# Create sparse data
arr = np.random.choice([0, 1, 2], 10000, p=[0.95, 0.04, 0.01])
s_dense = pd.Series(arr)
s_sparse = pd.Series(arr, dtype=pd.SparseDtype(int, fill_value=0))

print(s_dense.memory_usage())   # High
print(s_sparse.memory_usage())  # Low

# Convert to sparse
df = pd.DataFrame({
    'A': np.random.choice([0, 1], 1000, p=[0.9, 0.1]),
    'B': np.random.choice([0, 1], 1000, p=[0.95, 0.05])
})

df_sparse = df.astype(pd.SparseDtype(int, fill_value=0))

# Sparse operations
print(df_sparse.sparse.density)  # Percentage of non-sparse values

# Convert back to dense
df_dense = df_sparse.sparse.to_dense()
```

### Extension Types

```python
# Integer with NA support
df = pd.DataFrame({
    'a': pd.array([1, 2, None, 4], dtype='Int64'),  # Capital I
    'b': pd.array([1.0, 2.0, None, 4.0], dtype='Float64')
})

print(df['a'].dtype)  # Int64
print(df.loc[2, 'a'])  # <NA>

# String type
df['text'] = pd.array(['a', 'b', None, 'd'], dtype='string')
print(df['text'].dtype)  # string

# Boolean with NA
df['flag'] = pd.array([True, False, None, True], dtype='boolean')
```

### Custom Accessors

Create custom methods for DataFrames and Series.

```python
# Define custom accessor
@pd.api.extensions.register_dataframe_accessor("custom")
class CustomAccessor:
    def __init__(self, pandas_obj):
        self._obj = pandas_obj
    
    def normalize(self):
        """Normalize all numeric columns"""
        numeric_cols = self._obj.select_dtypes(include=[np.number]).columns
        result = self._obj.copy()
        for col in numeric_cols:
            result[col] = (result[col] - result[col].min()) / (result[col].max() - result[col].min())
        return result
    
    def remove_outliers(self, threshold=3):
        """Remove outliers using z-score"""
        numeric_cols = self._obj.select_dtypes(include=[np.number]).columns
        result = self._obj.copy()
        for col in numeric_cols:
            z_scores = np.abs((result[col] - result[col].mean()) / result[col].std())
            result = result[z_scores < threshold]
        return result

# Use custom accessor
df = pd.DataFrame({
    'A': [1, 2, 3, 100],
    'B': [4, 5, 6, 7]
})

df_normalized = df.custom.normalize()
df_clean = df.custom.remove_outliers(threshold=2)
```

### Styler for Display

```python
# Apply styling to DataFrames
df = pd.DataFrame({
    'Sales': [100, 200, 150, 300],
    'Profit': [10, 25, 15, 40],
    'Margin': [0.1, 0.125, 0.1, 0.133]
})

# Highlight max values
styled = df.style.highlight_max(color='lightgreen')

# Highlight min values
styled = df.style.highlight_min(color='lightcoral')

# Color gradient
styled = df.style.background_gradient(cmap='Blues')

# Format numbers
styled = df.style.format({
    'Sales': '${:.0f}',
    'Profit': '${:.0f}',
    'Margin': '{:.1%}'
})

# Custom styling function
def color_negative_red(val):
    color = 'red' if val < 0 else 'black'
    return f'color: {color}'

styled = df.style.applymap(color_negative_red, subset=['Profit'])

# Chain styling
styled = (df.style
          .format({'Sales': '${:.0f}', 'Margin': '{:.1%}'})
          .background_gradient(subset=['Sales'], cmap='Blues')
          .highlight_max(subset=['Profit'], color='lightgreen'))

# Export styled DataFrame
styled.to_excel('styled_output.xlsx', engine='openpyxl')
```

### Options and Settings

```python
# Display options
pd.set_option('display.max_rows', 100)
pd.set_option('display.max_columns', 50)
pd.set_option('display.width', 1000)
pd.set_option('display.precision', 2)
pd.set_option('display.float_format', '{:.2f}'.format)

# Reset options
pd.reset_option('display.max_rows')
pd.reset_option('all')

# Get option
print(pd.get_option('display.max_rows'))

# Context manager for temporary options
with pd.option_context('display.max_rows', 10, 'display.max_columns', 5):
    print(df)  # Uses temporary settings
# Back to original settings

# Describe all options
pd.describe_option()
pd.describe_option('display')
```

### Summary

- Use categorical data for memory efficiency with limited unique values
- String methods via `.str` accessor for vectorized text operations
- Prefer vectorization over `apply()` for performance
- Method chaining with `pipe()` for readable code
- Sparse data structures for mostly empty/zero data
- Custom accessors extend Pandas functionality
- Styler for formatted output and Excel export

### Key Takeaways

1. Categorical data reduces memory usage significantly
2. String operations are vectorized through `.str`
3. Vectorized operations are much faster than apply
4. Method chaining improves code readability
5. Use pipe() for custom functions in chains
6. Sparse data saves memory for mostly empty data
7. Custom accessors provide reusable functionality

---

**Practice Exercise:**

1. Convert high-cardinality string columns to categorical
2. Clean and normalize text data using string methods
3. Extract information from text using regex
4. Create method chain with multiple transformations
5. Implement custom accessor with utility methods
6. Compare performance of vectorized vs apply operations
7. Style DataFrame for presentation output
