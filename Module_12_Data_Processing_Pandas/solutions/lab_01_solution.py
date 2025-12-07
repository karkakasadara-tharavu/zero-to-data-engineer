"""
LAB 01 SOLUTION: Pandas Basics - Series and DataFrame Fundamentals
Student: Reference Implementation
Module: 12 - Data Processing with Pandas
"""

import pandas as pd
import numpy as np

# ==================== TASK 1: Series Operations ====================

def create_series_examples():
    """Create various Series with different data types"""
    
    # From list
    temperatures = pd.Series([72, 75, 68, 70, 73], name='Temperature')
    
    # From dictionary with custom index
    prices = pd.Series({
        'AAPL': 150.25,
        'GOOGL': 2800.50,
        'MSFT': 300.75,
        'AMZN': 3200.00
    }, name='Stock_Price')
    
    # From NumPy array with date index
    dates = pd.date_range('2024-01-01', periods=5)
    sales = pd.Series(np.random.randint(100, 500, 5), index=dates, name='Sales')
    
    return temperatures, prices, sales

def analyze_series(series):
    """Analyze Series with descriptive statistics"""
    
    print(f"\nSeries Analysis: {series.name}")
    print("="*50)
    print(f"Length: {len(series)}")
    print(f"Data Type: {series.dtype}")
    print(f"Mean: {series.mean():.2f}")
    print(f"Median: {series.median():.2f}")
    print(f"Min: {series.min():.2f}")
    print(f"Max: {series.max():.2f}")
    print(f"Std Dev: {series.std():.2f}")
    print(f"\nFirst 3 values:\n{series.head(3)}")
    print(f"\nLast 3 values:\n{series.tail(3)}")
    
    return {
        'mean': series.mean(),
        'median': series.median(),
        'std': series.std(),
        'min': series.min(),
        'max': series.max()
    }

# ==================== TASK 2: DataFrame Creation ====================

def create_dataframes():
    """Create DataFrames using multiple methods"""
    
    # Method 1: From dictionary
    df_dict = pd.DataFrame({
        'name': ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
        'age': [25, 30, 35, 28, 32],
        'salary': [50000, 60000, 75000, 55000, 70000],
        'department': ['HR', 'IT', 'Finance', 'IT', 'HR']
    })
    
    # Method 2: From list of dictionaries
    data = [
        {'product': 'Laptop', 'price': 1200, 'quantity': 10},
        {'product': 'Mouse', 'price': 25, 'quantity': 100},
        {'product': 'Keyboard', 'price': 75, 'quantity': 50},
        {'product': 'Monitor', 'price': 300, 'quantity': 20}
    ]
    df_list = pd.DataFrame(data)
    
    # Method 3: From NumPy array with custom columns
    np_data = np.random.randn(5, 4)
    df_numpy = pd.DataFrame(
        np_data,
        columns=['A', 'B', 'C', 'D'],
        index=['Row1', 'Row2', 'Row3', 'Row4', 'Row5']
    )
    
    # Method 4: From CSV (simulated)
    csv_data = """date,sales,expenses,profit
2024-01-01,1000,600,400
2024-01-02,1200,650,550
2024-01-03,900,550,350"""
    
    from io import StringIO
    df_csv = pd.read_csv(StringIO(csv_data), parse_dates=['date'])
    
    return df_dict, df_list, df_numpy, df_csv

def inspect_dataframe(df, name):
    """Comprehensive DataFrame inspection"""
    
    print(f"\n{name} Inspection")
    print("="*60)
    print(f"Shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    print(f"Data Types:\n{df.dtypes}")
    print(f"\nFirst 3 rows:\n{df.head(3)}")
    print(f"\nInfo:\n{df.info()}")
    print(f"\nDescriptive Statistics:\n{df.describe()}")
    print(f"\nMemory Usage: {df.memory_usage(deep=True).sum() / 1024:.2f} KB")

# ==================== TASK 3: Selection and Filtering ====================

def demonstrate_selection(df):
    """Demonstrate various selection methods"""
    
    print("\nSelection Methods")
    print("="*60)
    
    # Select single column
    print("\n1. Single column (df['name']):")
    print(df['name'])
    
    # Select multiple columns
    print("\n2. Multiple columns (df[['name', 'salary']]):")
    print(df[['name', 'salary']])
    
    # Select rows by position (iloc)
    print("\n3. First 3 rows (df.iloc[:3]):")
    print(df.iloc[:3])
    
    # Select rows by label (loc)
    print("\n4. Specific rows (df.loc[0:2]):")
    print(df.loc[0:2])
    
    # Select specific cell
    print("\n5. Specific cell (df.loc[0, 'name']):")
    print(df.loc[0, 'name'])
    
    # Select with boolean indexing
    print("\n6. Boolean selection (age > 30):")
    print(df[df['age'] > 30])
    
    return df

def filter_dataframe(df):
    """Apply complex filters"""
    
    print("\nFiltering Operations")
    print("="*60)
    
    # Single condition
    high_salary = df[df['salary'] > 60000]
    print(f"\n1. Employees with salary > 60000: {len(high_salary)}")
    print(high_salary)
    
    # Multiple conditions (AND)
    it_high_salary = df[(df['department'] == 'IT') & (df['salary'] > 55000)]
    print(f"\n2. IT employees with salary > 55000: {len(it_high_salary)}")
    print(it_high_salary)
    
    # Multiple conditions (OR)
    hr_or_young = df[(df['department'] == 'HR') | (df['age'] < 30)]
    print(f"\n3. HR employees OR age < 30: {len(hr_or_young)}")
    print(hr_or_young)
    
    # isin() method
    selected_depts = df[df['department'].isin(['IT', 'Finance'])]
    print(f"\n4. IT or Finance departments: {len(selected_depts)}")
    print(selected_depts)
    
    # Query method
    query_result = df.query('age > 28 and salary < 70000')
    print(f"\n5. Using query (age > 28 AND salary < 70000): {len(query_result)}")
    print(query_result)
    
    return {
        'high_salary': high_salary,
        'it_high_salary': it_high_salary,
        'hr_or_young': hr_or_young,
        'selected_depts': selected_depts,
        'query_result': query_result
    }

# ==================== TASK 4: Modification Operations ====================

def modify_dataframe(df):
    """Demonstrate DataFrame modification"""
    
    # Make a copy to avoid modifying original
    df_modified = df.copy()
    
    print("\nModification Operations")
    print("="*60)
    
    # Add new column
    df_modified['bonus'] = df_modified['salary'] * 0.10
    print("\n1. Added 'bonus' column (10% of salary)")
    print(df_modified)
    
    # Calculate new column from existing
    df_modified['total_compensation'] = df_modified['salary'] + df_modified['bonus']
    print("\n2. Added 'total_compensation' column")
    print(df_modified[['name', 'salary', 'bonus', 'total_compensation']])
    
    # Modify existing values
    df_modified.loc[df_modified['department'] == 'IT', 'bonus'] *= 1.2
    print("\n3. Increased IT department bonus by 20%")
    print(df_modified[df_modified['department'] == 'IT'])
    
    # Apply function to column
    df_modified['years_to_retirement'] = df_modified['age'].apply(lambda x: 65 - x)
    print("\n4. Added 'years_to_retirement' column")
    print(df_modified[['name', 'age', 'years_to_retirement']])
    
    # Rename columns
    df_modified = df_modified.rename(columns={
        'name': 'employee_name',
        'salary': 'base_salary'
    })
    print("\n5. Renamed columns")
    print(df_modified.columns.tolist())
    
    # Drop columns
    df_modified = df_modified.drop(columns=['bonus'])
    print("\n6. Dropped 'bonus' column")
    print(df_modified.columns.tolist())
    
    # Sort values
    df_sorted = df_modified.sort_values('total_compensation', ascending=False)
    print("\n7. Sorted by total_compensation (descending)")
    print(df_sorted[['employee_name', 'total_compensation']])
    
    return df_modified

# ==================== TESTING ====================

def test_series_operations():
    """Test Series functionality"""
    print("\nTEST: Series Operations")
    print("="*60)
    
    temps, prices, sales = create_series_examples()
    
    assert len(temps) == 5, "Temperature series should have 5 elements"
    assert temps.name == 'Temperature', "Series name should be 'Temperature'"
    assert 'AAPL' in prices.index, "Prices should include AAPL"
    assert len(sales) == 5, "Sales series should have 5 elements"
    
    print("✓ All Series tests passed")

def test_dataframe_creation():
    """Test DataFrame creation"""
    print("\nTEST: DataFrame Creation")
    print("="*60)
    
    df_dict, df_list, df_numpy, df_csv = create_dataframes()
    
    assert df_dict.shape[0] == 5, "Employee DataFrame should have 5 rows"
    assert 'name' in df_dict.columns, "Should have 'name' column"
    assert df_list.shape[1] == 3, "Product DataFrame should have 3 columns"
    assert df_numpy.shape == (5, 4), "NumPy DataFrame should be 5x4"
    
    print("✓ All DataFrame creation tests passed")

def test_selection_filtering():
    """Test selection and filtering"""
    print("\nTEST: Selection and Filtering")
    print("="*60)
    
    df = pd.DataFrame({
        'name': ['Alice', 'Bob', 'Charlie'],
        'age': [25, 30, 35],
        'salary': [50000, 60000, 75000],
        'department': ['HR', 'IT', 'Finance']
    })
    
    # Test selections
    assert len(df[df['age'] > 28]) == 2, "Should find 2 people over 28"
    assert df.loc[0, 'name'] == 'Alice', "First name should be Alice"
    assert len(df[df['department'].isin(['IT', 'Finance'])]) == 2, "Should find 2 in IT or Finance"
    
    print("✓ All selection/filtering tests passed")

# ==================== MAIN EXECUTION ====================

def main():
    """Main execution"""
    print("\n" + "="*60)
    print("LAB 01 SOLUTION: PANDAS BASICS")
    print("="*60)
    
    # Task 1: Series
    print("\nTASK 1: SERIES OPERATIONS")
    temps, prices, sales = create_series_examples()
    analyze_series(prices)
    
    # Task 2: DataFrames
    print("\n\nTASK 2: DATAFRAME CREATION")
    df_dict, df_list, df_numpy, df_csv = create_dataframes()
    inspect_dataframe(df_dict, "Employee DataFrame")
    
    # Task 3: Selection
    print("\n\nTASK 3: SELECTION AND FILTERING")
    demonstrate_selection(df_dict)
    filter_results = filter_dataframe(df_dict)
    
    # Task 4: Modification
    print("\n\nTASK 4: MODIFICATION OPERATIONS")
    df_modified = modify_dataframe(df_dict)
    
    # Run tests
    print("\n\n" + "="*60)
    print("RUNNING TESTS")
    print("="*60)
    test_series_operations()
    test_dataframe_creation()
    test_selection_filtering()
    
    print("\n" + "="*60)
    print("LAB 01 COMPLETE ✓")
    print("="*60)

if __name__ == "__main__":
    main()
