# Lab 02: Data Loading and File I/O

## Estimated Time: 75 minutes

## Objectives
- Read data from various file formats (CSV, Excel, JSON)
- Write DataFrames to different file formats
- Handle file I/O options and parameters
- Deal with encoding and parsing issues
- Work with large files efficiently

## Prerequisites
- Completed Lab 01
- Understanding of file paths
- Basic knowledge of CSV, Excel, JSON formats

## Background

Your retail company stores data in multiple formats across different systems. Sales data comes as CSV files, inventory is in Excel spreadsheets, and customer data is in JSON format. You need to load, process, and save data across these formats.

## Setup

Create a `data/` directory in your lab folder with the following structure:
```
lab_02/
├── lab_02_solution.py
└── data/
    ├── sales_data.csv (you'll create this)
    ├── inventory.xlsx (you'll create this)
    └── customers.json (you'll create this)
```

## Tasks

### Task 1: Working with CSV Files (20 minutes)

Read and write CSV files with various options.

**Requirements:**
1. Create sample sales data with 50+ rows
2. Write to CSV with appropriate options
3. Read CSV back with correct data types
4. Handle missing values during read
5. Parse dates automatically
6. Use different delimiters and encodings

**Sample Data Structure:**
```csv
date,product_id,quantity,price,customer_id,region
2024-01-01,P001,2,899.99,C1001,North
2024-01-01,P003,1,45.50,C1002,South
...
```

### Task 2: Working with Excel Files (20 minutes)

Read and write Excel workbooks with multiple sheets.

**Requirements:**
1. Create Excel file with multiple sheets:
   - Sheet 1: Products (at least 20 products)
   - Sheet 2: Categories
   - Sheet 3: Summary statistics
2. Read specific sheets
3. Read specific columns only
4. Skip rows and handle headers
5. Write formatted Excel output

**Data Structure:**
```
Products Sheet:
product_id | name | category | price | in_stock | reorder_level

Categories Sheet:
category_id | category_name | description

Summary Sheet:
metric | value
Total Products | 20
Total Value | $15,432.50
```

### Task 3: Working with JSON Files (20 minutes)

Read and write JSON data in different formats.

**Requirements:**
1. Create customer data with nested structure
2. Write JSON in different orientations (records, index, columns)
3. Read JSON back correctly
4. Handle nested JSON
5. Work with JSON Lines format

**Sample JSON Structure:**
```json
{
  "customers": [
    {
      "customer_id": "C1001",
      "name": "John Doe",
      "email": "john@example.com",
      "address": {
        "street": "123 Main St",
        "city": "Springfield",
        "state": "IL",
        "zip": "62701"
      },
      "purchase_history": [
        {"date": "2024-01-01", "amount": 150.00},
        {"date": "2024-01-15", "amount": 75.50}
      ]
    }
  ]
}
```

### Task 4: Advanced File Operations (15 minutes)

Handle special cases and optimize file operations.

**Requirements:**
1. Read large CSV in chunks
2. Handle encoding issues
3. Parse dates with custom formats
4. Combine multiple files
5. Export with compression

## Starter Code

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

# Task 1: CSV Operations
def create_sales_data(num_rows=50):
    """
    Create sample sales data
    
    Args:
        num_rows (int): Number of rows to generate
    
    Returns:
        pd.DataFrame: Sales data
    """
    np.random.seed(42)
    
    # TODO: Generate dates for last 50 days
    dates = None
    
    # TODO: Generate product IDs
    product_ids = None
    
    # TODO: Generate quantities, prices, customer IDs, regions
    
    # TODO: Create DataFrame
    df = pd.DataFrame({
        'date': dates,
        'product_id': product_ids,
        # Add other columns
    })
    
    return df

def write_csv(df, filepath, **kwargs):
    """
    Write DataFrame to CSV with options
    
    Args:
        df (pd.DataFrame): Data to write
        filepath (str): Output file path
        **kwargs: Additional options for to_csv
    """
    # TODO: Write to CSV
    # Consider: index, encoding, date_format
    pass

def read_csv_with_options(filepath):
    """
    Read CSV with appropriate options
    
    Args:
        filepath (str): CSV file path
    
    Returns:
        pd.DataFrame: Loaded data
    """
    # TODO: Read CSV with:
    # - Correct data types
    # - Date parsing
    # - Handling missing values
    df = None
    
    return df

# Task 2: Excel Operations
def create_excel_workbook(filepath):
    """
    Create Excel file with multiple sheets
    
    Args:
        filepath (str): Output file path
    """
    # TODO: Create products DataFrame
    products_df = pd.DataFrame({
        'product_id': [f'P{i:03d}' for i in range(1, 21)],
        # Add other columns
    })
    
    # TODO: Create categories DataFrame
    categories_df = pd.DataFrame({
        'category_id': ['CAT001', 'CAT002', 'CAT003'],
        # Add other columns
    })
    
    # TODO: Create summary DataFrame
    summary_df = pd.DataFrame({
        'metric': ['Total Products', 'Average Price', 'Total Value'],
        'value': [20, 0, 0]  # Calculate actual values
    })
    
    # TODO: Write to Excel with multiple sheets
    with pd.ExcelWriter(filepath, engine='openpyxl') as writer:
        # Write each sheet
        pass

def read_excel_sheets(filepath):
    """
    Read specific sheets from Excel file
    
    Args:
        filepath (str): Excel file path
    
    Returns:
        dict: Dictionary of DataFrames
    """
    # TODO: Read all sheets
    sheets = {}
    
    # TODO: Read specific sheet
    # TODO: Read specific columns only
    # TODO: Skip rows if needed
    
    return sheets

# Task 3: JSON Operations
def create_customer_json(filepath):
    """
    Create customer data in JSON format
    
    Args:
        filepath (str): Output file path
    """
    # TODO: Create customer data with nested structure
    customers = []
    
    for i in range(1, 11):
        customer = {
            'customer_id': f'C{i:04d}',
            'name': f'Customer {i}',
            # Add address (nested)
            # Add purchase_history (list)
        }
        customers.append(customer)
    
    # TODO: Create DataFrame
    df = pd.DataFrame(customers)
    
    # TODO: Write to JSON
    # Try different orientations: 'records', 'index', 'columns'
    pass

def read_json_formats(filepath):
    """
    Read JSON in different formats
    
    Args:
        filepath (str): JSON file path
    
    Returns:
        pd.DataFrame: Loaded data
    """
    # TODO: Read JSON
    # Handle orient parameter
    # Handle nested data
    df = None
    
    return df

def write_json_lines(df, filepath):
    """
    Write DataFrame as JSON Lines (one JSON per line)
    
    Args:
        df (pd.DataFrame): Data to write
        filepath (str): Output file path
    """
    # TODO: Write as JSON Lines
    # Use orient='records' and lines=True
    pass

# Task 4: Advanced Operations
def read_large_csv_chunks(filepath, chunksize=10):
    """
    Read large CSV in chunks and process
    
    Args:
        filepath (str): CSV file path
        chunksize (int): Rows per chunk
    
    Returns:
        pd.DataFrame: Aggregated results
    """
    # TODO: Read in chunks
    # TODO: Process each chunk
    # TODO: Combine results
    
    chunks = []
    for chunk in pd.read_csv(filepath, chunksize=chunksize):
        # Process chunk
        processed = None  # Your processing logic
        chunks.append(processed)
    
    # TODO: Combine all chunks
    result = None
    
    return result

def handle_encoding_issues(filepath):
    """
    Read file with encoding issues
    
    Args:
        filepath (str): File path
    
    Returns:
        pd.DataFrame: Loaded data
    """
    # TODO: Try different encodings
    encodings = ['utf-8', 'latin-1', 'cp1252']
    
    for encoding in encodings:
        try:
            df = pd.read_csv(filepath, encoding=encoding)
            print(f"Successfully read with {encoding}")
            return df
        except UnicodeDecodeError:
            continue
    
    return None

def combine_multiple_files(directory, pattern='*.csv'):
    """
    Combine multiple CSV files into one DataFrame
    
    Args:
        directory (str): Directory containing files
        pattern (str): File pattern to match
    
    Returns:
        pd.DataFrame: Combined data
    """
    import glob
    
    # TODO: Find all matching files
    files = glob.glob(os.path.join(directory, pattern))
    
    # TODO: Read and combine all files
    dfs = []
    for file in files:
        df = pd.read_csv(file)
        dfs.append(df)
    
    # TODO: Concatenate all DataFrames
    combined = None
    
    return combined

def write_compressed(df, filepath):
    """
    Write DataFrame with compression
    
    Args:
        df (pd.DataFrame): Data to write
        filepath (str): Output path (should end with .gz or .zip)
    """
    # TODO: Write with compression
    # Pandas auto-detects compression from file extension
    pass

def main():
    """Main execution function"""
    print("=" * 60)
    print("LAB 02: DATA LOADING AND FILE I/O")
    print("=" * 60)
    
    # Create data directory
    os.makedirs('data', exist_ok=True)
    
    # Task 1: CSV Operations
    print("\n--- TASK 1: CSV OPERATIONS ---")
    sales_df = create_sales_data(50)
    print(f"Created sales data: {sales_df.shape}")
    print(sales_df.head())
    
    csv_path = 'data/sales_data.csv'
    write_csv(sales_df, csv_path, index=False, date_format='%Y-%m-%d')
    print(f"Written to {csv_path}")
    
    loaded_df = read_csv_with_options(csv_path)
    print(f"Loaded data: {loaded_df.shape}")
    print(f"Date column dtype: {loaded_df['date'].dtype}")
    
    # Task 2: Excel Operations
    print("\n--- TASK 2: EXCEL OPERATIONS ---")
    excel_path = 'data/inventory.xlsx'
    create_excel_workbook(excel_path)
    print(f"Created Excel file: {excel_path}")
    
    sheets = read_excel_sheets(excel_path)
    print(f"Read {len(sheets)} sheets")
    for sheet_name, df in sheets.items():
        print(f"  - {sheet_name}: {df.shape}")
    
    # Task 3: JSON Operations
    print("\n--- TASK 3: JSON OPERATIONS ---")
    json_path = 'data/customers.json'
    create_customer_json(json_path)
    print(f"Created JSON file: {json_path}")
    
    customers_df = read_json_formats(json_path)
    print(f"Loaded customers: {customers_df.shape}")
    print(customers_df.head())
    
    # Task 4: Advanced Operations
    print("\n--- TASK 4: ADVANCED OPERATIONS ---")
    
    # Read in chunks
    chunk_result = read_large_csv_chunks(csv_path, chunksize=10)
    print(f"Processed file in chunks: {chunk_result.shape if chunk_result is not None else 'N/A'}")
    
    # Compressed output
    compressed_path = 'data/sales_compressed.csv.gz'
    write_compressed(sales_df, compressed_path)
    print(f"Written compressed file: {compressed_path}")
    
    # Verify compressed read
    df_compressed = pd.read_csv(compressed_path)
    print(f"Read compressed file: {df_compressed.shape}")
    
    print("\n" + "=" * 60)
    print("LAB 02 COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()
```

## Testing Your Solution

```python
def test_csv_operations():
    """Test CSV read/write"""
    df = create_sales_data(10)
    write_csv(df, 'test_sales.csv', index=False)
    
    loaded = read_csv_with_options('test_sales.csv')
    assert len(loaded) == 10, "Should load all rows"
    assert 'date' in loaded.columns, "Should have date column"
    
    # Cleanup
    os.remove('test_sales.csv')
    print("✓ CSV operations test passed")

def test_excel_operations():
    """Test Excel operations"""
    create_excel_workbook('test_inventory.xlsx')
    assert os.path.exists('test_inventory.xlsx'), "File should be created"
    
    sheets = read_excel_sheets('test_inventory.xlsx')
    assert len(sheets) > 0, "Should read sheets"
    
    # Cleanup
    os.remove('test_inventory.xlsx')
    print("✓ Excel operations test passed")

def test_json_operations():
    """Test JSON operations"""
    create_customer_json('test_customers.json')
    df = read_json_formats('test_customers.json')
    
    assert len(df) > 0, "Should load customers"
    assert 'customer_id' in df.columns, "Should have customer_id"
    
    # Cleanup
    os.remove('test_customers.json')
    print("✓ JSON operations test passed")

# Run tests
test_csv_operations()
test_excel_operations()
test_json_operations()
print("\nAll tests passed! ✓")
```

## Expected Deliverables

1. Completed Python script with all functions
2. Sample data files in `data/` directory:
   - sales_data.csv
   - inventory.xlsx
   - customers.json
3. Demonstration of reading/writing each format
4. Handling of special cases (encoding, large files, compression)

## Bonus Challenges

1. **Parquet Format**: Read and write Parquet files
2. **SQL Database**: Read from and write to SQLite database
3. **URL Loading**: Load CSV from a URL
4. **Performance**: Compare read times for different formats
5. **Metadata**: Preserve and restore DataFrame metadata

## Common Pitfalls

- Not specifying `index=False` when writing CSV
- Forgetting to parse dates (use `parse_dates` parameter)
- Incorrect encoding causing garbled text
- Not handling missing values properly
- Memory issues with large files (use chunks)
- File path issues (use `os.path.join()`)

## Resources

- I/O Tools: https://pandas.pydata.org/docs/user_guide/io.html
- CSV: https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html
- Excel: https://pandas.pydata.org/docs/reference/api/pandas.read_excel.html
- JSON: https://pandas.pydata.org/docs/reference/api/pandas.read_json.html

## Submission

Submit your `lab_02_solution.py` file along with sample data files demonstrating all file I/O operations.
