# Lab 01: Pandas Basics - Series and DataFrame Fundamentals

## Estimated Time: 60 minutes

## Objectives
- Create and manipulate Pandas Series
- Create DataFrames from various sources
- Perform basic data inspection
- Select and filter data
- Understand indexing fundamentals

## Prerequisites
- Python 3.8+
- Pandas library installed
- Basic Python knowledge (lists, dictionaries)

## Background

You've been hired as a data analyst for a retail company. Your first task is to work with product inventory data and sales records. You'll use Pandas to organize, inspect, and analyze this data.

## Tasks

### Task 1: Series Creation and Operations (15 minutes)

Create a Series representing daily sales for a week and perform basic operations.

**Requirements:**
1. Create a Series with sales data for 7 days (Mon-Sun)
2. Set appropriate index labels (day names)
3. Calculate total weekly sales
4. Find the day with maximum sales
5. Filter days with sales above average
6. Calculate percentage of total for each day

**Expected Output:**
```
Monday      1250.50
Tuesday     1450.75
Wednesday   1320.00
Thursday    1580.25
Friday      2100.50
Saturday    2450.00
Sunday      2200.75

Total Sales: $12,352.75
Best Day: Saturday
Days Above Average: [...]
```

### Task 2: DataFrame Creation (20 minutes)

Create a DataFrame containing product information for your inventory.

**Requirements:**
1. Create a DataFrame with at least 10 products
2. Include columns: product_id, name, category, price, stock_quantity, supplier
3. Use multiple creation methods (dict, lists, etc.)
4. Set product_id as index
5. Display DataFrame info and summary statistics

**Sample Data Structure:**
```
product_id | name          | category    | price  | stock_quantity | supplier
-----------|---------------|-------------|--------|----------------|-------------
P001       | Laptop        | Electronics | 899.99 | 15            | TechCorp
P002       | Mouse         | Electronics | 25.99  | 50            | TechCorp
...
```

### Task 3: Data Inspection (10 minutes)

Inspect and summarize the DataFrame you created.

**Requirements:**
1. Display first and last 3 rows
2. Show DataFrame shape, columns, and data types
3. Generate descriptive statistics
4. Check for missing values
5. Display memory usage

**Expected Methods to Use:**
- `head()`, `tail()`
- `shape`, `columns`, `dtypes`
- `describe()`
- `info()`
- `isnull().sum()`

### Task 4: Selection and Filtering (15 minutes)

Select specific data from your DataFrame using various methods.

**Requirements:**
1. Select single column (product names)
2. Select multiple columns (name, price, stock_quantity)
3. Select rows by index (specific product_id)
4. Select rows by position (first 5 products)
5. Filter products with price > $50
6. Filter Electronics category with stock < 20
7. Filter using multiple conditions (OR logic)

**Expected Techniques:**
- Column selection: `df['column']`, `df[['col1', 'col2']]`
- Row selection: `df.loc[]`, `df.iloc[]`
- Boolean indexing: `df[df['price'] > 50]`
- Complex filters: `df[(condition1) & (condition2)]`

## Starter Code

```python
import pandas as pd
import numpy as np

# Task 1: Series Creation
def create_sales_series():
    """
    Create a Series with daily sales data
    
    Returns:
        pd.Series: Sales data indexed by day name
    """
    # TODO: Create sales data for 7 days
    sales_data = None
    days = None
    
    # TODO: Create Series with appropriate index
    sales_series = None
    
    return sales_series

def analyze_sales(sales_series):
    """
    Analyze sales series
    
    Args:
        sales_series (pd.Series): Daily sales data
    
    Returns:
        dict: Analysis results
    """
    analysis = {}
    
    # TODO: Calculate total sales
    analysis['total'] = None
    
    # TODO: Find best day
    analysis['best_day'] = None
    
    # TODO: Find average
    analysis['average'] = None
    
    # TODO: Filter days above average
    analysis['above_average'] = None
    
    # TODO: Calculate percentages
    analysis['percentages'] = None
    
    return analysis

# Task 2: DataFrame Creation
def create_inventory_df():
    """
    Create product inventory DataFrame
    
    Returns:
        pd.DataFrame: Product inventory
    """
    # TODO: Create product data
    # Method 1: From dictionary
    products = {
        'product_id': [],
        'name': [],
        'category': [],
        'price': [],
        'stock_quantity': [],
        'supplier': []
    }
    
    # TODO: Create DataFrame
    df = None
    
    # TODO: Set product_id as index
    
    return df

# Task 3: Data Inspection
def inspect_dataframe(df):
    """
    Inspect DataFrame and return summary
    
    Args:
        df (pd.DataFrame): DataFrame to inspect
    
    Returns:
        dict: Inspection results
    """
    inspection = {}
    
    # TODO: Get basic info
    inspection['shape'] = None
    inspection['columns'] = None
    inspection['dtypes'] = None
    
    # TODO: Get statistics
    inspection['statistics'] = None
    
    # TODO: Check missing values
    inspection['missing'] = None
    
    # TODO: Get memory usage
    inspection['memory'] = None
    
    return inspection

# Task 4: Selection and Filtering
def select_and_filter(df):
    """
    Perform various selections and filters
    
    Args:
        df (pd.DataFrame): Product DataFrame
    
    Returns:
        dict: Selection results
    """
    results = {}
    
    # TODO: Select single column
    results['names'] = None
    
    # TODO: Select multiple columns
    results['price_stock'] = None
    
    # TODO: Select by index
    results['product_p001'] = None
    
    # TODO: Select by position
    results['first_five'] = None
    
    # TODO: Filter by price
    results['expensive'] = None
    
    # TODO: Filter by category and stock
    results['low_stock_electronics'] = None
    
    # TODO: Complex filter
    results['complex_filter'] = None
    
    return results

def main():
    """Main execution function"""
    print("=" * 50)
    print("LAB 01: PANDAS BASICS")
    print("=" * 50)
    
    # Task 1: Series
    print("\n--- TASK 1: SERIES OPERATIONS ---")
    sales = create_sales_series()
    print("\nDaily Sales:")
    print(sales)
    
    analysis = analyze_sales(sales)
    print(f"\nTotal Sales: ${analysis['total']:,.2f}")
    print(f"Best Day: {analysis['best_day']}")
    print(f"Average: ${analysis['average']:,.2f}")
    print(f"\nDays Above Average:")
    print(analysis['above_average'])
    
    # Task 2: DataFrame Creation
    print("\n--- TASK 2: DATAFRAME CREATION ---")
    df = create_inventory_df()
    print(f"\nCreated DataFrame with {len(df)} products")
    print(df.head())
    
    # Task 3: Inspection
    print("\n--- TASK 3: DATA INSPECTION ---")
    inspection = inspect_dataframe(df)
    print(f"\nShape: {inspection['shape']}")
    print(f"Columns: {list(inspection['columns'])}")
    print(f"\nData Types:")
    print(inspection['dtypes'])
    print(f"\nDescriptive Statistics:")
    print(inspection['statistics'])
    
    # Task 4: Selection and Filtering
    print("\n--- TASK 4: SELECTION AND FILTERING ---")
    results = select_and_filter(df)
    print(f"\nProduct Names: {len(results['names'])} items")
    print(f"Expensive Products (>$50): {len(results['expensive'])} items")
    print(results['expensive'])

if __name__ == "__main__":
    main()
```

## Testing Your Solution

```python
import pandas as pd

def test_series_creation():
    """Test Series creation"""
    sales = create_sales_series()
    
    assert isinstance(sales, pd.Series), "Should return a Series"
    assert len(sales) == 7, "Should have 7 days"
    assert all(sales > 0), "Sales should be positive"
    print("✓ Series creation test passed")

def test_dataframe_creation():
    """Test DataFrame creation"""
    df = create_inventory_df()
    
    assert isinstance(df, pd.DataFrame), "Should return DataFrame"
    assert len(df) >= 10, "Should have at least 10 products"
    assert 'name' in df.columns, "Should have name column"
    assert 'price' in df.columns, "Should have price column"
    assert df.index.name == 'product_id', "Index should be product_id"
    print("✓ DataFrame creation test passed")

def test_filtering():
    """Test filtering operations"""
    df = create_inventory_df()
    results = select_and_filter(df)
    
    assert len(results['names']) == len(df), "Should have all names"
    assert all(results['expensive']['price'] > 50), "Should filter correctly"
    print("✓ Filtering test passed")

# Run tests
test_series_creation()
test_dataframe_creation()
test_filtering()
print("\nAll tests passed! ✓")
```

## Expected Deliverables

1. Completed Python script with all functions implemented
2. Output showing:
   - Series with sales data and analysis
   - DataFrame with product inventory
   - Inspection results
   - Filtered results
3. Brief comments explaining your approach

## Bonus Challenges

1. **Sort Operations**: Sort products by price (ascending and descending)
2. **Value Counts**: Count products by category
3. **Unique Values**: Find unique suppliers
4. **Custom Index**: Create MultiIndex with category and product_id
5. **Series Arithmetic**: Calculate total inventory value (price × stock_quantity)

## Common Pitfalls

- Forgetting to set index properly
- Using assignment instead of filtering (creates copy warnings)
- Not handling column names with spaces
- Confusing `loc` and `iloc`
- Using wrong boolean operators (use `&` not `and`)

## Resources

- Pandas Documentation: https://pandas.pydata.org/docs/
- Series: https://pandas.pydata.org/docs/reference/series.html
- DataFrame: https://pandas.pydata.org/docs/reference/frame.html
- Indexing and Selecting: https://pandas.pydata.org/docs/user_guide/indexing.html

## Submission

Submit your completed `lab_01_solution.py` file with all functions implemented and tested.
