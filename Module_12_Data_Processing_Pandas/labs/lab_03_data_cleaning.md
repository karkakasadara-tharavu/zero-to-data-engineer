# Lab 03: Data Cleaning and Preparation

## Estimated Time: 90 minutes

## Objectives
- Handle missing data effectively
- Remove and handle duplicates
- Clean string data
- Convert data types
- Validate and standardize data

## Prerequisites
- Completed Labs 01-02
- Understanding of data quality issues
- Basic string manipulation knowledge

## Background

Your company's data warehouse has accumulated messy data from various sources. Before analysis, you must clean and prepare the data: handling missing values, removing duplicates, standardizing formats, and validating data quality.

## Dataset

You'll work with a "dirty" customer transactions dataset containing common data quality issues:
- Missing values in critical fields
- Duplicate records
- Inconsistent string formatting
- Incorrect data types
- Outliers and invalid values

## Tasks

### Task 1: Handling Missing Data (25 minutes)

**Requirements:**
1. Load dataset with missing values
2. Identify patterns of missingness
3. Visualize missing data distribution
4. Apply different strategies:
   - Drop rows/columns with too many missing values
   - Fill with mean/median/mode
   - Forward/backward fill for time series
   - Interpolate numeric values
5. Document decisions and rationale

**Sample Data Issues:**
```
customer_id | name    | email              | age  | city      | purchase_amount
C001        | John    | john@email.com     | 25   | New York  | 150.00
C002        | NaN     | jane@email.com     | NaN  | Boston    | 200.00
C003        | Bob     | NaN                | 35   | NaN       | NaN
```

### Task 2: Duplicate Detection and Removal (20 minutes)

**Requirements:**
1. Identify exact duplicates
2. Find duplicates based on subset of columns
3. Handle near-duplicates (fuzzy matching)
4. Keep first/last/custom duplicate
5. Create deduplication report

### Task 3: String Cleaning and Standardization (25 minutes)

**Requirements:**
1. Remove leading/trailing whitespace
2. Standardize case (upper/lower/title)
3. Remove special characters
4. Extract patterns using regex
5. Replace and normalize values
6. Clean email and phone formats

**Cleaning Tasks:**
```
Names: "  JOHN DOE  " → "John Doe"
Emails: "John@EMAIL.COM" → "john@email.com"
Phones: "(123) 456-7890" → "123-456-7890"
Cities: "new york" → "New York"
States: "ny" → "NY"
```

### Task 4: Data Type Conversion and Validation (20 minutes)

**Requirements:**
1. Convert string dates to datetime
2. Convert numeric strings to numbers
3. Create categorical variables
4. Validate ranges and constraints
5. Flag invalid records

## Starter Code

```python
import pandas as pd
import numpy as np
import re
from datetime import datetime

def create_dirty_data():
    """Create sample dataset with data quality issues"""
    np.random.seed(42)
    
    # Generate base data
    n_rows = 100
    
    data = {
        'customer_id': [f'C{i:04d}' for i in range(1, n_rows + 1)],
        'name': [f'Customer {i}' for i in range(1, n_rows + 1)],
        'email': [f'customer{i}@email.com' for i in range(1, n_rows + 1)],
        'age': np.random.randint(18, 80, n_rows),
        'city': np.random.choice(['New York', 'Boston', 'Chicago', 'LA'], n_rows),
        'purchase_amount': np.random.uniform(10, 500, n_rows),
        'purchase_date': pd.date_range('2024-01-01', periods=n_rows, freq='D')
    }
    
    df = pd.DataFrame(data)
    
    # Introduce data quality issues
    # TODO: Add missing values (randomly set 15% to NaN)
    # TODO: Add duplicates (duplicate 10 random rows)
    # TODO: Add string issues (inconsistent case, whitespace)
    # TODO: Add type issues (convert some numbers to strings)
    
    return df

def analyze_missing_data(df):
    """
    Analyze missing data patterns
    
    Args:
        df (pd.DataFrame): Dataset to analyze
    
    Returns:
        pd.DataFrame: Missing data report
    """
    # TODO: Calculate missing counts and percentages
    missing_report = pd.DataFrame({
        'column': df.columns,
        'missing_count': df.isnull().sum().values,
        'missing_percent': (df.isnull().sum() / len(df) * 100).values
    })
    
    # TODO: Sort by missing percent
    
    return missing_report

def handle_missing_values(df, strategy='smart'):
    """
    Handle missing values using various strategies
    
    Args:
        df (pd.DataFrame): Dataset with missing values
        strategy (str): Strategy to use
    
    Returns:
        pd.DataFrame: Cleaned dataset
    """
    df_clean = df.copy()
    
    if strategy == 'drop_rows':
        # TODO: Drop rows with any missing values
        pass
    
    elif strategy == 'drop_columns':
        # TODO: Drop columns with >50% missing
        pass
    
    elif strategy == 'fill_mean':
        # TODO: Fill numeric columns with mean
        pass
    
    elif strategy == 'fill_mode':
        # TODO: Fill categorical columns with mode
        pass
    
    elif strategy == 'smart':
        # TODO: Apply intelligent strategy per column
        # - Numeric: mean or median
        # - Categorical: mode or 'Unknown'
        # - Dates: forward fill
        pass
    
    return df_clean

def remove_duplicates(df, subset=None, keep='first'):
    """
    Remove duplicate records
    
    Args:
        df (pd.DataFrame): Dataset
        subset (list): Columns to consider for duplicates
        keep (str): Which duplicate to keep
    
    Returns:
        tuple: (cleaned_df, duplicate_report)
    """
    # TODO: Find duplicates
    duplicates = df.duplicated(subset=subset, keep=False)
    duplicate_rows = df[duplicates]
    
    # TODO: Remove duplicates
    df_clean = df.drop_duplicates(subset=subset, keep=keep)
    
    # TODO: Create report
    report = {
        'total_rows': len(df),
        'duplicate_rows': duplicates.sum(),
        'unique_rows': len(df_clean),
        'removed': len(df) - len(df_clean)
    }
    
    return df_clean, report

def clean_string_columns(df):
    """
    Clean and standardize string columns
    
    Args:
        df (pd.DataFrame): Dataset
    
    Returns:
        pd.DataFrame: Cleaned dataset
    """
    df_clean = df.copy()
    
    # TODO: Clean name column
    if 'name' in df_clean.columns:
        df_clean['name'] = (df_clean['name']
                            .str.strip()
                            .str.title())
    
    # TODO: Clean email column
    if 'email' in df_clean.columns:
        df_clean['email'] = (df_clean['email']
                             .str.strip()
                             .str.lower())
    
    # TODO: Clean city column
    if 'city' in df_clean.columns:
        df_clean['city'] = (df_clean['city']
                            .str.strip()
                            .str.title())
    
    # TODO: Clean phone column (if exists)
    # Format: (123) 456-7890 → 123-456-7890
    
    return df_clean

def extract_patterns(df):
    """
    Extract information using regex
    
    Args:
        df (pd.DataFrame): Dataset
    
    Returns:
        pd.DataFrame: Dataset with extracted fields
    """
    df_extracted = df.copy()
    
    # TODO: Extract email domain
    if 'email' in df_extracted.columns:
        df_extracted['email_domain'] = df_extracted['email'].str.extract(r'@(.+)$')[0]
    
    # TODO: Extract area code from phone (if exists)
    
    # TODO: Extract title from name (Mr., Mrs., Dr., etc.)
    
    return df_extracted

def convert_data_types(df):
    """
    Convert columns to appropriate data types
    
    Args:
        df (pd.DataFrame): Dataset
    
    Returns:
        pd.DataFrame: Dataset with correct types
    """
    df_converted = df.copy()
    
    # TODO: Convert age to int (handle NaN with nullable Int64)
    if 'age' in df_converted.columns:
        df_converted['age'] = pd.to_numeric(df_converted['age'], errors='coerce').astype('Int64')
    
    # TODO: Convert purchase_amount to float
    
    # TODO: Convert purchase_date to datetime
    if 'purchase_date' in df_converted.columns:
        df_converted['purchase_date'] = pd.to_datetime(df_converted['purchase_date'], errors='coerce')
    
    # TODO: Convert categorical columns
    categorical_cols = ['city']
    for col in categorical_cols:
        if col in df_converted.columns:
            df_converted[col] = df_converted[col].astype('category')
    
    return df_converted

def validate_data(df):
    """
    Validate data against business rules
    
    Args:
        df (pd.DataFrame): Dataset to validate
    
    Returns:
        dict: Validation report
    """
    validation_report = {}
    
    # TODO: Validate age range (18-120)
    if 'age' in df.columns:
        invalid_age = df[(df['age'] < 18) | (df['age'] > 120)]
        validation_report['invalid_age'] = len(invalid_age)
    
    # TODO: Validate email format
    if 'email' in df.columns:
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        valid_email = df['email'].str.match(email_pattern, na=False)
        validation_report['invalid_email'] = (~valid_email).sum()
    
    # TODO: Validate purchase_amount (>0)
    
    # TODO: Validate required fields (not null)
    required_fields = ['customer_id', 'name', 'email']
    for field in required_fields:
        if field in df.columns:
            validation_report[f'missing_{field}'] = df[field].isnull().sum()
    
    return validation_report

def create_cleaning_pipeline(df):
    """
    Complete data cleaning pipeline
    
    Args:
        df (pd.DataFrame): Raw data
    
    Returns:
        tuple: (cleaned_df, cleaning_report)
    """
    report = {}
    
    # Step 1: Initial stats
    report['initial_rows'] = len(df)
    report['initial_columns'] = len(df.columns)
    
    # Step 2: Handle missing values
    df = handle_missing_values(df, strategy='smart')
    report['after_missing'] = len(df)
    
    # Step 3: Remove duplicates
    df, dup_report = remove_duplicates(df)
    report['duplicates_removed'] = dup_report['removed']
    
    # Step 4: Clean strings
    df = clean_string_columns(df)
    
    # Step 5: Convert types
    df = convert_data_types(df)
    
    # Step 6: Validate
    validation = validate_data(df)
    report['validation'] = validation
    
    # Step 7: Final stats
    report['final_rows'] = len(df)
    report['final_columns'] = len(df.columns)
    report['rows_removed'] = report['initial_rows'] - report['final_rows']
    report['retention_rate'] = (report['final_rows'] / report['initial_rows']) * 100
    
    return df, report

def main():
    """Main execution"""
    print("=" * 60)
    print("LAB 03: DATA CLEANING AND PREPARATION")
    print("=" * 60)
    
    # Create dirty data
    print("\n--- CREATING DIRTY DATA ---")
    df_dirty = create_dirty_data()
    print(f"Created dataset: {df_dirty.shape}")
    print(f"\nFirst few rows:")
    print(df_dirty.head(10))
    
    # Analyze missing data
    print("\n--- ANALYZING MISSING DATA ---")
    missing_report = analyze_missing_data(df_dirty)
    print(missing_report)
    
    # Clean data
    print("\n--- RUNNING CLEANING PIPELINE ---")
    df_clean, report = create_cleaning_pipeline(df_dirty)
    
    print(f"\nCleaning Report:")
    print(f"  Initial rows: {report['initial_rows']}")
    print(f"  Final rows: {report['final_rows']}")
    print(f"  Rows removed: {report['rows_removed']}")
    print(f"  Retention rate: {report['retention_rate']:.2f}%")
    print(f"  Duplicates removed: {report['duplicates_removed']}")
    
    print(f"\nValidation Issues:")
    for issue, count in report['validation'].items():
        print(f"  {issue}: {count}")
    
    # Display cleaned data
    print(f"\n--- CLEANED DATA ---")
    print(df_clean.head())
    print(f"\nData types:")
    print(df_clean.dtypes)
    
    # Save cleaned data
    df_clean.to_csv('data/cleaned_data.csv', index=False)
    print(f"\nCleaned data saved to: data/cleaned_data.csv")

if __name__ == "__main__":
    main()
```

## Testing Your Solution

```python
def test_missing_data_handling():
    """Test missing data functions"""
    df = pd.DataFrame({
        'A': [1, 2, np.nan, 4],
        'B': [np.nan, 2, 3, 4],
        'C': [1, 2, 3, 4]
    })
    
    df_clean = handle_missing_values(df, strategy='fill_mean')
    assert df_clean['A'].isnull().sum() == 0, "Should fill missing values"
    print("✓ Missing data test passed")

def test_duplicate_removal():
    """Test duplicate detection"""
    df = pd.DataFrame({
        'A': [1, 1, 2, 3],
        'B': [1, 1, 2, 3]
    })
    
    df_clean, report = remove_duplicates(df)
    assert len(df_clean) == 3, "Should remove 1 duplicate"
    assert report['removed'] == 1, "Should report 1 removed"
    print("✓ Duplicate removal test passed")

def test_string_cleaning():
    """Test string cleaning"""
    df = pd.DataFrame({
        'name': ['  john DOE  ', 'JANE smith', 'bob JONES'],
        'email': ['JOHN@EMAIL.COM', 'jane@email.com', 'BOB@EMAIL.COM']
    })
    
    df_clean = clean_string_columns(df)
    assert all(df_clean['name'].str.istitle()), "Names should be title case"
    assert all(df_clean['email'].str.islower()), "Emails should be lowercase"
    print("✓ String cleaning test passed")

# Run tests
test_missing_data_handling()
test_duplicate_removal()
test_string_cleaning()
print("\nAll tests passed! ✓")
```

## Expected Deliverables

1. Completed cleaning pipeline script
2. Cleaned output CSV file
3. Cleaning report showing:
   - Initial vs final row counts
   - Missing data handling decisions
   - Duplicates removed
   - Validation issues found and fixed
4. Documentation of cleaning decisions

## Bonus Challenges

1. **Outlier Detection**: Use IQR or Z-score to identify outliers
2. **Fuzzy Matching**: Find near-duplicate names using fuzzy string matching
3. **Data Profiling**: Create comprehensive data quality report
4. **Custom Validators**: Build reusable validation functions
5. **Logging**: Add detailed logging of all cleaning steps

## Common Pitfalls

- Dropping too much data
- Not documenting cleaning decisions
- Incorrect imputation strategies
- Ignoring data dependencies
- Not validating after cleaning

## Resources

- Missing Data: https://pandas.pydata.org/docs/user_guide/missing_data.html
- Duplicates: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.drop_duplicates.html
- String Methods: https://pandas.pydata.org/docs/user_guide/text.html

## Submission

Submit `lab_03_solution.py` with the complete cleaning pipeline and a brief report documenting your cleaning decisions.
