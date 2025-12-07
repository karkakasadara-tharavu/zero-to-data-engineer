# Module 12: Data Processing with Pandas

## Theory Section 04: Data Cleaning and Preparation

### Learning Objectives
- Handle missing data effectively
- Remove and handle duplicates
- Clean and transform string data
- Convert and cast data types
- Rename and reindex DataFrames

### Handling Missing Data

Missing data is represented as `NaN` (Not a Number), `None`, or `NaT` (Not a Time) in Pandas.

#### Detecting Missing Values

```python
import pandas as pd
import numpy as np

df = pd.DataFrame({
    'A': [1, 2, np.nan, 4],
    'B': [5, np.nan, np.nan, 8],
    'C': [9, 10, 11, 12]
})

# Check for missing values
print(df.isnull())          # or df.isna()
print(df.notnull())         # or df.notna()

# Count missing values per column
print(df.isnull().sum())

# Total missing values
print(df.isnull().sum().sum())

# Percentage of missing values
print((df.isnull().sum() / len(df)) * 100)

# Rows with any missing values
print(df[df.isnull().any(axis=1)])

# Columns with missing values
cols_with_missing = df.columns[df.isnull().any()].tolist()
```

#### Dropping Missing Values

```python
# Drop rows with any missing values
df_clean = df.dropna()

# Drop rows where all values are missing
df_clean = df.dropna(how='all')

# Drop rows with missing values in specific columns
df_clean = df.dropna(subset=['A', 'B'])

# Drop columns with any missing values
df_clean = df.dropna(axis=1)

# Drop if more than n missing values in row
df_clean = df.dropna(thresh=2)  # Keep rows with at least 2 non-null values

# In-place modification
df.dropna(inplace=True)
```

#### Filling Missing Values

```python
# Fill with a constant
df_filled = df.fillna(0)
df_filled = df.fillna('Unknown')

# Fill different columns with different values
df_filled = df.fillna({'A': 0, 'B': df['B'].mean(), 'C': 'N/A'})

# Forward fill (propagate last valid observation)
df_filled = df.fillna(method='ffill')  # or 'pad'

# Backward fill
df_filled = df.fillna(method='bfill')  # or 'backfill'

# Fill with limit
df_filled = df.fillna(method='ffill', limit=2)  # Fill only 2 consecutive NaNs

# Fill with statistical measures
df['A'].fillna(df['A'].mean(), inplace=True)
df['B'].fillna(df['B'].median(), inplace=True)
df['C'].fillna(df['C'].mode()[0], inplace=True)  # Most frequent value

# Interpolate (for numerical data)
df_filled = df.interpolate()
df_filled = df.interpolate(method='linear')
df_filled = df.interpolate(method='polynomial', order=2)
```

#### Advanced Missing Data Handling

```python
# Replace specific values with NaN
df = df.replace([-999, -9999], np.nan)
df = df.replace(['NA', 'N/A', 'null'], np.nan)

# Detect missing patterns
from missingno import matrix, heatmap
matrix(df)  # Visualize missing data pattern

# Imputation with scikit-learn
from sklearn.impute import SimpleImputer

imputer = SimpleImputer(strategy='mean')  # or 'median', 'most_frequent'
df[['A', 'B']] = imputer.fit_transform(df[['A', 'B']])
```

### Handling Duplicates

#### Detecting Duplicates

```python
df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie', 'Bob', 'Alice'],
    'age': [25, 30, 35, 30, 25],
    'city': ['NYC', 'LA', 'Chicago', 'LA', 'NYC']
})

# Check for duplicate rows
print(df.duplicated())

# Count duplicates
print(df.duplicated().sum())

# Show duplicate rows
print(df[df.duplicated()])

# Check duplicates based on specific columns
print(df.duplicated(subset=['name']))
print(df.duplicated(subset=['name', 'age']))

# Keep first or last occurrence
print(df.duplicated(keep='first'))   # Default
print(df.duplicated(keep='last'))
print(df.duplicated(keep=False))     # Mark all duplicates as True
```

#### Removing Duplicates

```python
# Drop duplicate rows
df_clean = df.drop_duplicates()

# Drop based on specific columns
df_clean = df.drop_duplicates(subset=['name'])

# Keep last occurrence
df_clean = df.drop_duplicates(keep='last')

# Keep no duplicates (remove all)
df_clean = df.drop_duplicates(keep=False)

# In-place modification
df.drop_duplicates(inplace=True)
```

### String Operations

#### Basic String Methods

```python
df = pd.DataFrame({
    'name': ['  Alice  ', 'bob', 'CHARLIE', 'David', None],
    'email': ['alice@email.com', 'bob@EMAIL.COM', None, 'david@email.com', 'invalid']
})

# Convert to lowercase/uppercase
df['name_lower'] = df['name'].str.lower()
df['name_upper'] = df['name'].str.upper()
df['name_title'] = df['name'].str.title()

# Strip whitespace
df['name_clean'] = df['name'].str.strip()
df['name_clean'] = df['name'].str.lstrip()   # Left strip
df['name_clean'] = df['name'].str.rstrip()   # Right strip

# Replace
df['name'] = df['name'].str.replace('Alice', 'Alicia')
df['name'] = df['name'].str.replace('  ', ' ')  # Multiple spaces to single

# Contains
mask = df['email'].str.contains('@', na=False)
df_valid = df[mask]

# Starts with / Ends with
mask = df['name'].str.startswith('A', na=False)
mask = df['email'].str.endswith('.com', na=False)

# Length
df['name_length'] = df['name'].str.len()

# Split
df[['first', 'domain']] = df['email'].str.split('@', expand=True)

# Extract with regex
df['domain'] = df['email'].str.extract(r'@(.+)')
```

#### Advanced String Operations

```python
# Regular expressions
import re

# Extract patterns
df['phone'] = df['text'].str.extract(r'(\d{3}-\d{3}-\d{4})')

# Find all occurrences
df['all_numbers'] = df['text'].str.findall(r'\d+')

# Replace with regex
df['clean_text'] = df['text'].str.replace(r'\d+', '', regex=True)

# Match pattern
mask = df['email'].str.match(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9.]+\.[a-z]+$', na=False)

# Slice strings
df['first_3'] = df['name'].str[:3]
df['last_2'] = df['name'].str[-2:]

# Pad strings
df['padded'] = df['name'].str.pad(10, side='left', fillchar='0')
df['padded'] = df['name'].str.zfill(10)  # Zero padding

# Concatenate strings
df['full_name'] = df['first_name'] + ' ' + df['last_name']
df['full_name'] = df['first_name'].str.cat(df['last_name'], sep=' ')
```

### Data Type Conversion

#### Checking Data Types

```python
print(df.dtypes)              # All column types
print(df['age'].dtype)        # Specific column type
print(df.info())              # Detailed information

# Check specific types
print(df.select_dtypes(include=['int64']))
print(df.select_dtypes(include=['object']))
print(df.select_dtypes(include=['float64', 'int64']))
print(df.select_dtypes(exclude=['object']))
```

#### Converting Data Types

```python
# Convert to specific type
df['age'] = df['age'].astype(int)
df['price'] = df['price'].astype(float)
df['category'] = df['category'].astype('category')
df['date'] = df['date'].astype('datetime64[ns]')

# Convert with error handling
df['age'] = pd.to_numeric(df['age'], errors='coerce')  # Invalid → NaN
df['age'] = pd.to_numeric(df['age'], errors='ignore')  # Keep original if fails

# Convert multiple columns
cols_to_convert = ['col1', 'col2', 'col3']
df[cols_to_convert] = df[cols_to_convert].astype(float)

# Optimize memory with smaller types
df['age'] = df['age'].astype('int8')     # -128 to 127
df['id'] = df['id'].astype('int32')      # -2B to 2B
df['price'] = df['price'].astype('float32')
```

#### Working with Dates

```python
# Convert to datetime
df['date'] = pd.to_datetime(df['date'])
df['date'] = pd.to_datetime(df['date'], format='%Y-%m-%d')
df['date'] = pd.to_datetime(df['date'], format='%d/%m/%Y')

# Handle errors in datetime conversion
df['date'] = pd.to_datetime(df['date'], errors='coerce')

# Extract date components
df['year'] = df['date'].dt.year
df['month'] = df['date'].dt.month
df['day'] = df['date'].dt.day
df['dayofweek'] = df['date'].dt.dayofweek  # Monday=0
df['quarter'] = df['date'].dt.quarter
df['weekday_name'] = df['date'].dt.day_name()

# Convert back to string
df['date_str'] = df['date'].dt.strftime('%Y-%m-%d')
```

#### Categorical Data

```python
# Convert to categorical
df['category'] = df['category'].astype('category')

# Benefits: Lower memory, faster operations on repeated values

# Check categories
print(df['category'].cat.categories)

# Add/remove categories
df['category'] = df['category'].cat.add_categories(['new_cat'])
df['category'] = df['category'].cat.remove_categories(['old_cat'])

# Rename categories
df['category'] = df['category'].cat.rename_categories({'old': 'new'})

# Order categories
df['size'] = pd.Categorical(df['size'], categories=['S', 'M', 'L', 'XL'], ordered=True)
```

### Renaming

```python
# Rename columns
df = df.rename(columns={'old_name': 'new_name'})
df = df.rename(columns={'col1': 'column1', 'col2': 'column2'})

# Rename using function
df = df.rename(columns=str.lower)
df = df.rename(columns=lambda x: x.replace(' ', '_'))

# Rename all columns
df.columns = ['new1', 'new2', 'new3']

# Rename index
df = df.rename(index={0: 'first', 1: 'second'})

# Rename using mapper
mapper = {0: 'a', 1: 'b', 2: 'c'}
df = df.rename(index=mapper)
```

### Reindexing

```python
# Reindex with new index
new_index = [0, 1, 2, 3, 4]
df = df.reindex(new_index)

# Fill missing with value
df = df.reindex(new_index, fill_value=0)

# Forward fill when reindexing
df = df.reindex(new_index, method='ffill')

# Reindex columns
df = df.reindex(columns=['col1', 'col2', 'col3'])

# Reset index
df = df.reset_index(drop=True)   # Drop old index
df = df.reset_index()             # Keep old index as column

# Set new index
df = df.set_index('column_name')
df = df.set_index(['col1', 'col2'])  # Multi-index
```

### Data Validation

```python
# Check for specific conditions
assert df['age'].min() >= 0, "Age cannot be negative"
assert df['salary'].notna().all(), "Salary has missing values"

# Validate data types
assert df['age'].dtype == 'int64'

# Validate ranges
assert (df['percentage'] >= 0).all() and (df['percentage'] <= 100).all()

# Check uniqueness
assert df['id'].is_unique, "ID column must be unique"

# Validate relationships
assert (df['start_date'] <= df['end_date']).all()
```

### Data Cleaning Pipeline

```python
def clean_dataframe(df):
    """Complete data cleaning pipeline"""
    
    # 1. Handle missing values
    df = df.dropna(subset=['critical_column'])
    df['optional_col'].fillna(df['optional_col'].mean(), inplace=True)
    
    # 2. Remove duplicates
    df = df.drop_duplicates(subset=['id'], keep='first')
    
    # 3. Clean strings
    string_cols = df.select_dtypes(include=['object']).columns
    for col in string_cols:
        df[col] = df[col].str.strip().str.lower()
    
    # 4. Convert types
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
    df['amount'] = pd.to_numeric(df['amount'], errors='coerce')
    
    # 5. Remove outliers (example: IQR method)
    Q1 = df['value'].quantile(0.25)
    Q3 = df['value'].quantile(0.75)
    IQR = Q3 - Q1
    df = df[(df['value'] >= Q1 - 1.5*IQR) & (df['value'] <= Q3 + 1.5*IQR)]
    
    # 6. Reset index
    df = df.reset_index(drop=True)
    
    return df

# Apply pipeline
df_clean = clean_dataframe(df)
```

### Summary

- Use `.isnull()` and `.dropna()` for missing data
- Use `.drop_duplicates()` to remove duplicates
- Use `.str` accessor for string operations
- Use `.astype()` and `pd.to_numeric()` for type conversion
- Use `.rename()` and `.reindex()` for restructuring
- Create data cleaning pipelines for consistency
- Always validate data after cleaning

### Key Takeaways

1. Missing data can be dropped or filled depending on context
2. Remove duplicates carefully based on business logic
3. String cleaning is essential for text data
4. Proper data types save memory and improve performance
5. Always validate data after transformations
6. Create reusable cleaning functions

---

**Practice Exercise:**

1. Load a dataset with missing values
2. Analyze missing data patterns
3. Fill numerical columns with mean, categorical with mode
4. Remove duplicate rows
5. Clean string columns (strip, lowercase)
6. Convert date strings to datetime
7. Validate the cleaned data
