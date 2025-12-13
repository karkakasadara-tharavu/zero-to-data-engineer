# Pandas Data Cleaning & Transformation - Complete Guide

## 📚 What You'll Learn
- Data cleaning techniques
- String manipulation
- Date/time handling
- Data transformation
- Reshaping data
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Data Cleaning Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DATA CLEANING PIPELINE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   RAW DATA                                                               │
│   ├── Missing values                                                    │
│   ├── Duplicate records                                                 │
│   ├── Inconsistent formatting                                           │
│   ├── Invalid data types                                                │
│   ├── Outliers                                                          │
│   └── Inconsistent categories                                           │
│                                                                          │
│        ↓                                                                 │
│                                                                          │
│   CLEANING STEPS                                                         │
│   ├── 1. Assess data quality                                            │
│   ├── 2. Handle missing values                                          │
│   ├── 3. Remove duplicates                                              │
│   ├── 4. Fix data types                                                 │
│   ├── 5. Standardize formats                                            │
│   ├── 6. Handle outliers                                                │
│   └── 7. Validate results                                               │
│                                                                          │
│        ↓                                                                 │
│                                                                          │
│   CLEAN DATA → Ready for analysis                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔍 Data Quality Assessment

```python
import pandas as pd
import numpy as np

# Load sample data
df = pd.read_csv('data.csv')

# 1. Basic info
print(df.info())
print(df.shape)
print(df.dtypes)

# 2. Missing value analysis
print("\n=== Missing Values ===")
missing = df.isnull().sum()
missing_pct = (df.isnull().sum() / len(df)) * 100
missing_df = pd.DataFrame({
    'Missing Count': missing,
    'Missing %': missing_pct
})
print(missing_df[missing_df['Missing Count'] > 0])

# 3. Duplicate analysis
print(f"\nDuplicate rows: {df.duplicated().sum()}")
print(f"Duplicate by key: {df.duplicated(subset=['ID']).sum()}")

# 4. Unique value counts
for col in df.select_dtypes(include='object').columns:
    print(f"\n{col}: {df[col].nunique()} unique values")
    if df[col].nunique() < 10:
        print(df[col].value_counts())

# 5. Numeric column statistics
print("\n=== Numeric Statistics ===")
print(df.describe())

# 6. Check for potential issues
def data_quality_report(df):
    report = []
    for col in df.columns:
        report.append({
            'Column': col,
            'Type': df[col].dtype,
            'Non-Null': df[col].count(),
            'Null': df[col].isnull().sum(),
            'Null%': round(df[col].isnull().sum() / len(df) * 100, 2),
            'Unique': df[col].nunique(),
            'Sample': df[col].dropna().iloc[0] if len(df[col].dropna()) > 0 else None
        })
    return pd.DataFrame(report)

print(data_quality_report(df))
```

---

## 🔧 Handling Missing Values

### Detection

```python
# Check for nulls
df.isnull()           # Boolean DataFrame
df.isnull().sum()     # Count per column
df.isnull().any()     # Any null per column
df.isnull().sum().sum()  # Total nulls

# Check for specific values that might be "missing"
# Sometimes missing is coded as '', 'N/A', 'NULL', -999, etc.
df['Column'].replace(['', 'N/A', 'NULL', -999], np.nan, inplace=True)
```

### Deletion Strategies

```python
# Drop rows with any missing values
df_clean = df.dropna()

# Drop rows where specific columns are missing
df_clean = df.dropna(subset=['Important_Column'])

# Drop rows where ALL values are missing
df_clean = df.dropna(how='all')

# Drop rows with more than 50% missing
threshold = len(df.columns) * 0.5
df_clean = df.dropna(thresh=threshold)

# Drop columns with too many missing values
threshold_pct = 0.3  # 30%
cols_to_drop = df.columns[df.isnull().sum() / len(df) > threshold_pct]
df_clean = df.drop(columns=cols_to_drop)
```

### Imputation Strategies

```python
# Fill with constant
df['Column'].fillna(0, inplace=True)
df['Category'].fillna('Unknown', inplace=True)

# Fill with statistics
df['Age'].fillna(df['Age'].mean(), inplace=True)
df['Salary'].fillna(df['Salary'].median(), inplace=True)
df['City'].fillna(df['City'].mode()[0], inplace=True)

# Fill with group statistics
df['Salary'] = df.groupby('Department')['Salary'].transform(
    lambda x: x.fillna(x.mean())
)

# Forward fill (carry forward last valid value)
df['Value'].fillna(method='ffill', inplace=True)

# Backward fill
df['Value'].fillna(method='bfill', inplace=True)

# Interpolation (for numeric/time series)
df['Temperature'].interpolate(method='linear', inplace=True)
df['Temperature'].interpolate(method='time', inplace=True)  # Time-based

# Fill with specific values per column
fill_values = {
    'Age': df['Age'].median(),
    'Salary': 0,
    'City': 'Unknown'
}
df.fillna(fill_values, inplace=True)
```

---

## 📝 String Manipulation

### String Accessor Methods

```python
# Access string methods via .str accessor
df['Name'].str.lower()
df['Name'].str.upper()
df['Name'].str.title()
df['Name'].str.capitalize()

# Whitespace handling
df['Name'].str.strip()      # Both sides
df['Name'].str.lstrip()     # Left only
df['Name'].str.rstrip()     # Right only

# String length
df['Name'].str.len()

# Contains, startswith, endswith
df['Name'].str.contains('John')           # Returns boolean
df['Name'].str.contains('john', case=False)  # Case insensitive
df['Name'].str.startswith('Dr.')
df['Name'].str.endswith('Jr.')

# Replace
df['Phone'].str.replace('-', '')
df['Text'].str.replace(r'\d+', '', regex=True)  # Remove numbers

# Split
df[['First', 'Last']] = df['FullName'].str.split(' ', n=1, expand=True)

# Extract with regex
df['AreaCode'] = df['Phone'].str.extract(r'\((\d{3})\)')

# Slice
df['Initials'] = df['Name'].str[:3]

# Padding
df['ID'].str.zfill(5)       # Pad with zeros
df['ID'].str.pad(10, side='left', fillchar='0')
```

### Common Cleaning Patterns

```python
# Standardize text
df['City'] = df['City'].str.strip().str.title()

# Remove special characters
df['ProductCode'] = df['ProductCode'].str.replace(r'[^a-zA-Z0-9]', '', regex=True)

# Clean phone numbers
df['Phone'] = df['Phone'].str.replace(r'[^\d]', '', regex=True)

# Extract email domain
df['EmailDomain'] = df['Email'].str.split('@').str[1]

# Fix inconsistent categories
mapping = {
    'NY': 'New York', 'N.Y.': 'New York', 'new york': 'New York',
    'CA': 'California', 'Calif.': 'California'
}
df['State'] = df['State'].replace(mapping)

# Alternative: use str.lower() + mapping
df['State'] = df['State'].str.lower().str.strip()
df['State'] = df['State'].map(lambda x: mapping.get(x, x))
```

---

## 📅 Date and Time Handling

### Parsing Dates

```python
# Convert to datetime
df['Date'] = pd.to_datetime(df['Date'])

# With specific format
df['Date'] = pd.to_datetime(df['Date'], format='%Y-%m-%d')
df['Date'] = pd.to_datetime(df['Date'], format='%m/%d/%Y')
df['Date'] = pd.to_datetime(df['Date'], format='%d-%b-%Y')

# Handle errors
df['Date'] = pd.to_datetime(df['Date'], errors='coerce')  # Invalid → NaT
df['Date'] = pd.to_datetime(df['Date'], errors='ignore')  # Keep original

# Infer format (slower but flexible)
df['Date'] = pd.to_datetime(df['Date'], infer_datetime_format=True)
```

### Extracting Components

```python
# Extract date components
df['Year'] = df['Date'].dt.year
df['Month'] = df['Date'].dt.month
df['Day'] = df['Date'].dt.day
df['DayOfWeek'] = df['Date'].dt.dayofweek  # 0=Monday
df['DayName'] = df['Date'].dt.day_name()
df['MonthName'] = df['Date'].dt.month_name()
df['Quarter'] = df['Date'].dt.quarter
df['WeekOfYear'] = df['Date'].dt.isocalendar().week

# Extract time components
df['Hour'] = df['DateTime'].dt.hour
df['Minute'] = df['DateTime'].dt.minute
df['Second'] = df['DateTime'].dt.second

# Date flags
df['IsWeekend'] = df['Date'].dt.dayofweek >= 5
df['IsMonthEnd'] = df['Date'].dt.is_month_end
df['IsMonthStart'] = df['Date'].dt.is_month_start
```

### Date Calculations

```python
# Difference between dates
df['DaysElapsed'] = (pd.Timestamp.now() - df['Date']).dt.days
df['MonthsElapsed'] = (pd.Timestamp.now() - df['Date']) / np.timedelta64(1, 'M')

# Add/subtract time
df['NextWeek'] = df['Date'] + pd.Timedelta(days=7)
df['LastMonth'] = df['Date'] - pd.DateOffset(months=1)
df['NextQuarter'] = df['Date'] + pd.DateOffset(months=3)

# Date range
date_range = pd.date_range(start='2024-01-01', end='2024-12-31', freq='D')
date_range = pd.date_range(start='2024-01-01', periods=12, freq='M')

# Resampling time series
df.set_index('Date', inplace=True)
df_monthly = df.resample('M').sum()
df_weekly = df.resample('W').mean()
```

---

## 🔄 Data Transformation

### Apply Functions

```python
# Apply to Series
df['Salary'] = df['Salary'].apply(lambda x: x * 1.1)  # 10% raise
df['Name'] = df['Name'].apply(str.upper)

# Apply to DataFrame (row-wise)
def calculate_bonus(row):
    if row['Department'] == 'Sales':
        return row['Salary'] * 0.2
    else:
        return row['Salary'] * 0.1

df['Bonus'] = df.apply(calculate_bonus, axis=1)

# Apply with multiple return values
def split_name(name):
    parts = name.split(' ')
    return pd.Series({
        'FirstName': parts[0],
        'LastName': parts[-1] if len(parts) > 1 else ''
    })

df[['FirstName', 'LastName']] = df['Name'].apply(split_name)
```

### Map and Replace

```python
# Map values (Series)
grade_map = {'A': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'F': 0.0}
df['GradePoints'] = df['Grade'].map(grade_map)

# Replace values
df['Status'] = df['Status'].replace({'Y': 'Yes', 'N': 'No'})
df['Status'] = df['Status'].replace({'Y': 'Yes', 'N': 'No', 'U': np.nan})

# Replace with regex
df['Phone'] = df['Phone'].replace(r'\D', '', regex=True)
```

### Binning and Categorization

```python
# Cut: equal-width bins
df['AgeGroup'] = pd.cut(df['Age'], bins=5)  # 5 equal-width bins
df['AgeGroup'] = pd.cut(df['Age'], bins=[0, 18, 35, 50, 65, 100],
                        labels=['Child', 'Young', 'Middle', 'Senior', 'Elderly'])

# Qcut: equal-frequency bins (quantiles)
df['IncomeQuartile'] = pd.qcut(df['Income'], q=4, labels=['Q1', 'Q2', 'Q3', 'Q4'])
df['IncomeDecile'] = pd.qcut(df['Income'], q=10)

# Custom binning with np.select
conditions = [
    df['Score'] >= 90,
    df['Score'] >= 80,
    df['Score'] >= 70,
    df['Score'] >= 60
]
choices = ['A', 'B', 'C', 'D']
df['Grade'] = np.select(conditions, choices, default='F')
```

### One-Hot Encoding

```python
# Get dummies (one-hot encoding)
df_encoded = pd.get_dummies(df, columns=['Category'])
df_encoded = pd.get_dummies(df['Category'], prefix='Cat')

# With drop_first to avoid multicollinearity
df_encoded = pd.get_dummies(df, columns=['Category'], drop_first=True)

# Concatenate back to original
df = pd.concat([df, pd.get_dummies(df['Category'], prefix='Cat')], axis=1)
```

---

## 📊 Reshaping Data

### Pivot Tables

```python
# Basic pivot
pivot = df.pivot(index='Date', columns='Product', values='Sales')

# Pivot table with aggregation
pivot = pd.pivot_table(df, 
                       values='Sales',
                       index='Region',
                       columns='Product',
                       aggfunc='sum',
                       fill_value=0,
                       margins=True)  # Add row/column totals

# Multiple aggregations
pivot = pd.pivot_table(df,
                       values='Sales',
                       index='Region',
                       columns='Product',
                       aggfunc=['sum', 'mean', 'count'])
```

### Melt (Unpivot)

```python
# Wide to long format
#   Date    ProductA  ProductB  ProductC
# 0 2024-01   100       150       200

df_long = pd.melt(df, 
                  id_vars=['Date'],
                  value_vars=['ProductA', 'ProductB', 'ProductC'],
                  var_name='Product',
                  value_name='Sales')

# Result:
#   Date       Product   Sales
# 0 2024-01   ProductA    100
# 1 2024-01   ProductB    150
# 2 2024-01   ProductC    200
```

### Stack and Unstack

```python
# Stack: columns to rows (adds level to index)
stacked = df.stack()

# Unstack: rows to columns (removes level from index)
unstacked = stacked.unstack()

# With multi-index
df_grouped = df.groupby(['Region', 'Product'])['Sales'].sum()
df_unstacked = df_grouped.unstack(level='Product')
```

---

## 🔍 Handling Outliers

```python
# Identify outliers using IQR
Q1 = df['Value'].quantile(0.25)
Q3 = df['Value'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

outliers = df[(df['Value'] < lower_bound) | (df['Value'] > upper_bound)]

# Remove outliers
df_clean = df[(df['Value'] >= lower_bound) & (df['Value'] <= upper_bound)]

# Cap outliers (winsorization)
df['Value'] = df['Value'].clip(lower=lower_bound, upper=upper_bound)

# Z-score method
from scipy import stats
z_scores = np.abs(stats.zscore(df['Value']))
df_clean = df[z_scores < 3]  # Keep within 3 standard deviations
```

---

## 🎓 Interview Questions

### Q1: How do you handle missing values in Pandas?
**A:** 
- Detect: `isnull()`, `sum()`
- Drop: `dropna()`
- Fill: `fillna()` with value, mean, median, mode, ffill, bfill
- Interpolate: `interpolate()` for numeric/time series

### Q2: What is the difference between map(), apply(), and applymap()?
**A:**
- **map()**: Element-wise on Series only
- **apply()**: Row/column-wise on DataFrame, element-wise on Series
- **applymap()**: Element-wise on entire DataFrame (deprecated, use apply)

### Q3: How do you clean and standardize text data?
**A:** Use `.str` accessor:
```python
df['col'].str.strip().str.lower().str.replace(r'[^\w\s]', '', regex=True)
```

### Q4: What is the difference between pivot() and pivot_table()?
**A:**
- **pivot()**: Reshape data, requires unique index/column combinations
- **pivot_table()**: Aggregates duplicates, supports multiple aggregation functions

### Q5: How do you convert wide format to long format?
**A:** Use `pd.melt()`:
```python
pd.melt(df, id_vars=['ID'], value_vars=['Col1', 'Col2'], 
        var_name='Variable', value_name='Value')
```

### Q6: How do you handle dates in Pandas?
**A:**
- Convert: `pd.to_datetime()`
- Extract: `.dt.year`, `.dt.month`, `.dt.day`
- Calculate: `pd.Timedelta`, `pd.DateOffset`

### Q7: How do you detect and handle outliers?
**A:**
- Detect with IQR: values outside Q1-1.5*IQR to Q3+1.5*IQR
- Or Z-score: values more than 3 standard deviations
- Handle: remove, cap (clip), or transform

### Q8: What is one-hot encoding and how to do it?
**A:** Converting categorical variables to binary columns:
```python
pd.get_dummies(df, columns=['Category'])
```

### Q9: How do you create binned/categorical data from continuous?
**A:**
- `pd.cut()`: Equal-width bins
- `pd.qcut()`: Equal-frequency bins (quantiles)

### Q10: How do you replace values conditionally?
**A:**
```python
df['col'] = np.where(condition, value_if_true, value_if_false)
df.loc[condition, 'col'] = new_value
```

---

## 🔗 Related Topics
- [← Pandas Fundamentals](./01_pandas_fundamentals.md)
- [Aggregations & GroupBy →](./03_aggregations.md)
- [Merging & Joining →](./04_merging.md)

---

*Next: Learn about Aggregations and GroupBy in Pandas*
