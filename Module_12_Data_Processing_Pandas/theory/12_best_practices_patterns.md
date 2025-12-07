# Module 12: Data Processing with Pandas

## Theory Section 12: Best Practices and Common Patterns

### Learning Objectives
- Follow Pandas coding best practices
- Avoid common pitfalls and anti-patterns
- Use idiomatic Pandas code
- Handle edge cases properly
- Write maintainable data processing code
- Apply design patterns for data workflows

### Code Organization

#### Modular Data Processing

```python
import pandas as pd
import numpy as np

# Good: Separate concerns into functions
def load_data(filepath, columns=None):
    """Load and perform initial data validation"""
    df = pd.read_csv(filepath, usecols=columns)
    if df.empty:
        raise ValueError("Empty DataFrame loaded")
    return df

def clean_data(df):
    """Clean and standardize data"""
    df = df.copy()  # Avoid modifying original
    df = df.drop_duplicates()
    df = df.dropna(subset=['critical_column'])
    df['name'] = df['name'].str.strip().str.lower()
    return df

def transform_data(df):
    """Apply business logic transformations"""
    df = df.copy()
    df['total'] = df['quantity'] * df['price']
    df['discount'] = df['total'] * 0.1
    df['final_amount'] = df['total'] - df['discount']
    return df

def process_pipeline(filepath):
    """Main processing pipeline"""
    df = load_data(filepath)
    df = clean_data(df)
    df = transform_data(df)
    return df

# Usage
result = process_pipeline('data.csv')
```

#### Configuration Management

```python
# Good: Separate configuration
CONFIG = {
    'data_path': 'data/',
    'output_path': 'output/',
    'date_format': '%Y-%m-%d',
    'dtypes': {
        'id': 'int32',
        'category': 'category',
        'value': 'float32'
    },
    'thresholds': {
        'min_value': 0,
        'max_value': 1000
    }
}

def load_with_config(filename):
    """Load data using configuration"""
    filepath = CONFIG['data_path'] + filename
    return pd.read_csv(filepath, dtype=CONFIG['dtypes'])

def validate_data(df):
    """Validate against configured thresholds"""
    min_val = CONFIG['thresholds']['min_value']
    max_val = CONFIG['thresholds']['max_value']
    return df[(df['value'] >= min_val) & (df['value'] <= max_val)]
```

### Method Chaining Patterns

```python
# Good: Readable method chaining
result = (
    df
    .query('age > 18')
    .assign(
        age_group=lambda x: pd.cut(x['age'], bins=[0, 25, 50, 75, 100]),
        full_name=lambda x: x['first_name'] + ' ' + x['last_name']
    )
    .sort_values('age')
    .reset_index(drop=True)
)

# Use pipe for custom functions
def remove_outliers(df, column, threshold=3):
    z = np.abs((df[column] - df[column].mean()) / df[column].std())
    return df[z < threshold]

def add_features(df):
    return df.assign(
        log_value=lambda x: np.log1p(x['value']),
        is_weekend=lambda x: x['date'].dt.dayofweek >= 5
    )

result = (
    df
    .pipe(remove_outliers, column='value', threshold=2)
    .pipe(add_features)
    .sort_values('date')
)
```

### Avoiding Common Pitfalls

#### SettingWithCopyWarning

```python
# Bad: Chained indexing
df[df['A'] > 0]['B'] = 100  # Warning!

# Good: Use loc
df.loc[df['A'] > 0, 'B'] = 100

# Bad: Working with slice
subset = df[df['A'] > 0]
subset['B'] = 100  # Might not work as expected

# Good: Explicit copy
subset = df[df['A'] > 0].copy()
subset['B'] = 100  # Safe
```

#### Inplace Operations

```python
# Inplace=True doesn't always improve performance
# and makes code harder to debug

# Avoid
df.drop('column', axis=1, inplace=True)
df.fillna(0, inplace=True)

# Prefer (more functional, easier to test)
df = df.drop('column', axis=1)
df = df.fillna(0)

# Or use method chaining
df = (df
      .drop('column', axis=1)
      .fillna(0))
```

#### Iterating Over DataFrames

```python
# Bad: Slow iteration
for i in range(len(df)):
    df.loc[i, 'result'] = df.loc[i, 'A'] + df.loc[i, 'B']

# Bad: iterrows (still slow)
for idx, row in df.iterrows():
    df.loc[idx, 'result'] = row['A'] + row['B']

# Good: Vectorization
df['result'] = df['A'] + df['B']

# When iteration is necessary, use itertuples (faster than iterrows)
for row in df.itertuples():
    # Process row
    value = row.A + row.B
```

#### Appending in Loops

```python
# Bad: Repeatedly appending (very slow)
df = pd.DataFrame()
for i in range(1000):
    new_row = pd.DataFrame({'A': [i], 'B': [i*2]})
    df = pd.concat([df, new_row])

# Good: Collect in list, then concat once
rows = []
for i in range(1000):
    rows.append({'A': i, 'B': i*2})
df = pd.DataFrame(rows)

# Or: Pre-allocate
df = pd.DataFrame(index=range(1000), columns=['A', 'B'])
for i in range(1000):
    df.loc[i] = [i, i*2]
```

### Data Validation Patterns

```python
def validate_dataframe(df, schema):
    """
    Validate DataFrame against schema
    
    schema = {
        'required_columns': ['id', 'name', 'value'],
        'dtypes': {'id': 'int64', 'value': 'float64'},
        'constraints': {
            'value': {'min': 0, 'max': 100},
            'name': {'not_null': True}
        }
    }
    """
    errors = []
    
    # Check required columns
    missing_cols = set(schema['required_columns']) - set(df.columns)
    if missing_cols:
        errors.append(f"Missing columns: {missing_cols}")
    
    # Check data types
    for col, expected_dtype in schema.get('dtypes', {}).items():
        if col in df.columns and df[col].dtype != expected_dtype:
            errors.append(f"Column {col} has dtype {df[col].dtype}, expected {expected_dtype}")
    
    # Check constraints
    for col, constraints in schema.get('constraints', {}).items():
        if col not in df.columns:
            continue
            
        if 'min' in constraints and df[col].min() < constraints['min']:
            errors.append(f"Column {col} has values below minimum {constraints['min']}")
        
        if 'max' in constraints and df[col].max() > constraints['max']:
            errors.append(f"Column {col} has values above maximum {constraints['max']}")
        
        if constraints.get('not_null') and df[col].isnull().any():
            errors.append(f"Column {col} contains null values")
    
    if errors:
        raise ValueError("Validation failed:\n" + "\n".join(errors))
    
    return True

# Usage
schema = {
    'required_columns': ['id', 'name', 'value'],
    'dtypes': {'id': 'int64'},
    'constraints': {
        'value': {'min': 0, 'max': 100},
        'name': {'not_null': True}
    }
}

try:
    validate_dataframe(df, schema)
    print("Validation passed")
except ValueError as e:
    print(f"Validation failed: {e}")
```

### Error Handling

```python
def safe_read_csv(filepath, **kwargs):
    """Safely read CSV with error handling"""
    try:
        df = pd.read_csv(filepath, **kwargs)
        if df.empty:
            raise ValueError("Empty DataFrame")
        return df
    except FileNotFoundError:
        print(f"File not found: {filepath}")
        return pd.DataFrame()
    except pd.errors.ParserError as e:
        print(f"Parse error: {e}")
        return pd.DataFrame()
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise

def safe_merge(df1, df2, **kwargs):
    """Merge with validation"""
    result = pd.merge(df1, df2, **kwargs)
    
    # Validate merge
    expected_rows = len(df1) if kwargs.get('how') == 'left' else None
    if expected_rows and len(result) != expected_rows:
        print(f"Warning: Merge produced {len(result)} rows, expected {expected_rows}")
    
    return result

def safe_groupby_agg(df, groupby_cols, agg_dict):
    """GroupBy with error handling"""
    try:
        result = df.groupby(groupby_cols).agg(agg_dict)
        return result
    except KeyError as e:
        print(f"Column not found: {e}")
        return pd.DataFrame()
    except Exception as e:
        print(f"Aggregation failed: {e}")
        raise
```

### Testing Patterns

```python
import unittest

class TestDataProcessing(unittest.TestCase):
    
    def setUp(self):
        """Create test data"""
        self.df = pd.DataFrame({
            'A': [1, 2, 3, 4, 5],
            'B': [10, 20, 30, 40, 50],
            'C': ['a', 'b', 'a', 'b', 'a']
        })
    
    def test_clean_data(self):
        """Test data cleaning function"""
        result = clean_data(self.df)
        
        # Check no duplicates
        self.assertEqual(len(result), len(result.drop_duplicates()))
        
        # Check no nulls in critical columns
        self.assertEqual(result['A'].isnull().sum(), 0)
    
    def test_transform_data(self):
        """Test transformations"""
        result = transform_data(self.df)
        
        # Check new columns created
        self.assertIn('total', result.columns)
        
        # Check calculations
        expected_total = self.df['A'] + self.df['B']
        pd.testing.assert_series_equal(result['total'], expected_total, check_names=False)
    
    def test_groupby_aggregation(self):
        """Test groupby operations"""
        result = self.df.groupby('C')['A'].sum()
        
        # Check groups
        self.assertEqual(len(result), 2)
        
        # Check values
        self.assertEqual(result['a'], 9)  # 1+3+5
        self.assertEqual(result['b'], 6)  # 2+4

# Run tests
# unittest.main(argv=[''], exit=False)
```

### Performance Patterns

```python
# Pattern: Lazy evaluation
def create_lazy_pipeline(df):
    """Return pipeline without executing"""
    return (
        df
        .query('value > 0')
        .groupby('category')
        .agg({'value': ['sum', 'mean']})
    )

# Execute when needed
# result = pipeline.compute() or just use it

# Pattern: Caching expensive operations
from functools import lru_cache

@lru_cache(maxsize=128)
def load_reference_data(filepath):
    """Cache reference data"""
    return pd.read_csv(filepath)

# Pattern: Progress tracking
from tqdm import tqdm

def process_with_progress(df, func):
    """Apply function with progress bar"""
    tqdm.pandas()
    return df.progress_apply(func)

# Or for chunks
chunks = []
for chunk in tqdm(pd.read_csv('large.csv', chunksize=10000)):
    processed = process_chunk(chunk)
    chunks.append(processed)
```

### Documentation Patterns

```python
def process_sales_data(df, start_date=None, end_date=None, min_amount=0):
    """
    Process sales data with filtering and aggregation.
    
    Parameters
    ----------
    df : pd.DataFrame
        Sales data with columns: date, product, amount, quantity
    start_date : str or datetime, optional
        Filter start date (inclusive)
    end_date : str or datetime, optional
        Filter end date (inclusive)
    min_amount : float, default 0
        Minimum transaction amount to include
    
    Returns
    -------
    pd.DataFrame
        Processed sales data with additional calculated columns:
        - total: amount * quantity
        - discount: calculated discount amount
        - final_amount: total - discount
    
    Examples
    --------
    >>> df = pd.DataFrame({
    ...     'date': pd.date_range('2024-01-01', periods=5),
    ...     'product': ['A', 'B', 'A', 'B', 'C'],
    ...     'amount': [100, 200, 150, 250, 300],
    ...     'quantity': [1, 2, 1, 3, 2]
    ... })
    >>> result = process_sales_data(df, min_amount=150)
    >>> len(result)
    4
    
    Notes
    -----
    - Removes duplicates based on date and product
    - Applies 10% discount on amounts over 200
    - Fills missing quantities with 1
    """
    df = df.copy()
    
    # Filter by date
    if start_date:
        df = df[df['date'] >= pd.to_datetime(start_date)]
    if end_date:
        df = df[df['date'] <= pd.to_datetime(end_date)]
    
    # Filter by amount
    df = df[df['amount'] >= min_amount]
    
    # Calculate fields
    df['total'] = df['amount'] * df['quantity'].fillna(1)
    df['discount'] = np.where(df['amount'] > 200, df['total'] * 0.1, 0)
    df['final_amount'] = df['total'] - df['discount']
    
    return df.drop_duplicates(subset=['date', 'product'])
```

### Logging Patterns

```python
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def process_with_logging(df):
    """Process data with detailed logging"""
    logger.info(f"Starting processing with {len(df)} rows")
    
    initial_rows = len(df)
    df = df.dropna()
    logger.info(f"Removed {initial_rows - len(df)} rows with null values")
    
    df = df[df['value'] > 0]
    logger.info(f"Filtered to {len(df)} rows with positive values")
    
    try:
        result = df.groupby('category').agg({'value': ['sum', 'mean']})
        logger.info(f"Aggregated into {len(result)} groups")
        return result
    except Exception as e:
        logger.error(f"Aggregation failed: {e}")
        raise
```

### Design Patterns

#### Strategy Pattern

```python
class DataProcessor:
    """Base data processor"""
    def process(self, df):
        raise NotImplementedError

class SalesProcessor(DataProcessor):
    def process(self, df):
        return df.assign(total=lambda x: x['quantity'] * x['price'])

class InventoryProcessor(DataProcessor):
    def process(self, df):
        return df.assign(stock_value=lambda x: x['quantity'] * x['cost'])

def process_data(df, processor):
    """Process using strategy"""
    return processor.process(df)

# Usage
sales_df = process_data(df, SalesProcessor())
inventory_df = process_data(df, InventoryProcessor())
```

#### Builder Pattern

```python
class DataFrameBuilder:
    """Build DataFrame with validation"""
    
    def __init__(self):
        self.data = {}
        self.dtypes = {}
        self.validators = {}
    
    def add_column(self, name, data, dtype=None, validator=None):
        self.data[name] = data
        if dtype:
            self.dtypes[name] = dtype
        if validator:
            self.validators[name] = validator
        return self
    
    def build(self):
        df = pd.DataFrame(self.data)
        
        # Apply dtypes
        for col, dtype in self.dtypes.items():
            df[col] = df[col].astype(dtype)
        
        # Run validators
        for col, validator in self.validators.items():
            if not validator(df[col]):
                raise ValueError(f"Validation failed for column {col}")
        
        return df

# Usage
df = (DataFrameBuilder()
      .add_column('id', range(100), dtype='int32')
      .add_column('value', np.random.randn(100), 
                  validator=lambda x: x.between(-3, 3).all())
      .add_column('category', ['A', 'B'] * 50, dtype='category')
      .build())
```

### Summary

- Organize code into modular, testable functions
- Use method chaining for readable pipelines
- Avoid common pitfalls: chained indexing, loops, repeated appends
- Validate data with schema checks
- Handle errors gracefully with try-except
- Write tests for data processing logic
- Document functions with clear examples
- Log important processing steps
- Apply design patterns for maintainable code

### Key Takeaways

1. Modular code is easier to test and maintain
2. Method chaining improves readability
3. Always copy DataFrames when needed
4. Validate inputs and outputs
5. Handle errors explicitly
6. Test data processing functions
7. Document expected data shapes and types
8. Use configuration for flexibility
9. Log processing steps for debugging
10. Apply design patterns for complex workflows

---

**Practice Exercise:**

1. Refactor messy data processing code into modular functions
2. Implement comprehensive data validation
3. Add error handling and logging
4. Write unit tests for transformations
5. Create reusable processing pipeline with method chaining
6. Document functions with examples
7. Apply appropriate design patterns to your workflow
