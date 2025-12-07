# Lab 04: Data Transformation and Aggregation

## Estimated Time: 90 minutes

## Objectives
- Apply transformation functions to data
- Perform group-by operations and aggregations
- Create pivot tables and cross-tabulations
- Use window functions for rolling calculations
- Build data summaries and reports

## Prerequisites
- Completed Labs 01-03
- Understanding of aggregation concepts
- Basic statistical knowledge

## Background

As a data analyst, you need to transform raw transaction data into meaningful business insights. This lab focuses on aggregating sales data, calculating metrics, creating summaries, and generating reports for stakeholders.

## Dataset

You'll work with retail transaction data containing:
- Transaction details (date, product, quantity, price)
- Customer information
- Store locations
- Product categories

## Tasks

### Task 1: GroupBy Operations (25 minutes)

**Requirements:**
1. Group by single column (category) and aggregate
2. Group by multiple columns (category, region)
3. Apply multiple aggregation functions
4. Use custom aggregation functions
5. Transform groups (normalization, ranking)
6. Filter groups based on conditions

**Example Aggregations:**
```python
# Total sales by category
# Average order value by region
# Product count by supplier
# Sales trends by month
```

### Task 2: Pivot Tables and Cross-Tabulation (25 minutes)

**Requirements:**
1. Create basic pivot table (sales by category and month)
2. Add multiple aggregation functions
3. Create multi-level pivots
4. Add row and column totals (margins)
5. Create cross-tabulation for categorical analysis
6. Reshape data between long and wide formats

### Task 3: Window Functions and Rolling Calculations (20 minutes)

**Requirements:**
1. Calculate rolling averages (7-day, 30-day)
2. Calculate cumulative sums
3. Calculate percentage changes
4. Compute expanding statistics
5. Apply ranking within groups
6. Calculate moving standard deviation

### Task 4: Advanced Transformations (20 minutes)

**Requirements:**
1. Apply element-wise functions (apply, map, applymap)
2. Create calculated columns
3. Bin continuous variables
4. Create dummy variables
5. Normalize and standardize data
6. Create composite metrics

## Starter Code

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def create_transaction_data(n_transactions=1000):
    """
    Create sample transaction dataset
    
    Args:
        n_transactions (int): Number of transactions
    
    Returns:
        pd.DataFrame: Transaction data
    """
    np.random.seed(42)
    
    # Generate dates
    start_date = datetime(2024, 1, 1)
    dates = [start_date + timedelta(days=np.random.randint(0, 365)) 
             for _ in range(n_transactions)]
    
    # Generate other fields
    categories = ['Electronics', 'Clothing', 'Food', 'Books', 'Toys']
    regions = ['North', 'South', 'East', 'West']
    products = [f'Product_{i}' for i in range(1, 51)]
    
    df = pd.DataFrame({
        'transaction_id': [f'T{i:05d}' for i in range(1, n_transactions + 1)],
        'date': dates,
        'product': np.random.choice(products, n_transactions),
        'category': np.random.choice(categories, n_transactions),
        'quantity': np.random.randint(1, 10, n_transactions),
        'unit_price': np.random.uniform(10, 500, n_transactions),
        'region': np.random.choice(regions, n_transactions),
        'customer_id': [f'C{i:04d}' for i in np.random.randint(1, 201, n_transactions)]
    })
    
    # Calculate total
    df['total_amount'] = df['quantity'] * df['unit_price']
    
    # Sort by date
    df = df.sort_values('date').reset_index(drop=True)
    
    return df

# Task 1: GroupBy Operations
def basic_groupby_analysis(df):
    """
    Perform basic groupby aggregations
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        dict: Dictionary of aggregated results
    """
    results = {}
    
    # TODO: Total sales by category
    results['sales_by_category'] = None
    
    # TODO: Average transaction amount by region
    results['avg_by_region'] = None
    
    # TODO: Transaction count by category and region
    results['count_by_cat_region'] = None
    
    # TODO: Multiple aggregations
    # Group by category: sum, mean, count, std
    results['multi_agg'] = None
    
    return results

def custom_aggregations(df):
    """
    Apply custom aggregation functions
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Custom aggregations
    """
    # TODO: Define custom aggregation function
    def price_range(series):
        return series.max() - series.min()
    
    def coefficient_of_variation(series):
        return series.std() / series.mean() if series.mean() != 0 else 0
    
    # TODO: Apply custom aggregations
    result = df.groupby('category').agg({
        'total_amount': ['sum', 'mean', price_range, coefficient_of_variation]
    })
    
    return result

def transform_groups(df):
    """
    Transform data within groups
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Transformed data
    """
    df_transformed = df.copy()
    
    # TODO: Normalize amount within each category
    df_transformed['normalized_amount'] = df_transformed.groupby('category')['total_amount'].transform(
        lambda x: (x - x.mean()) / x.std()
    )
    
    # TODO: Rank transactions within each category
    df_transformed['category_rank'] = df_transformed.groupby('category')['total_amount'].rank(
        ascending=False, method='dense'
    )
    
    # TODO: Calculate percentage of category total
    df_transformed['pct_of_category'] = df_transformed.groupby('category')['total_amount'].transform(
        lambda x: x / x.sum() * 100
    )
    
    return df_transformed

def filter_groups(df):
    """
    Filter groups based on aggregate conditions
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Filtered data
    """
    # TODO: Keep only categories with total sales > $10,000
    category_sales = df.groupby('category')['total_amount'].sum()
    large_categories = category_sales[category_sales > 10000].index
    
    df_filtered = df[df['category'].isin(large_categories)]
    
    # TODO: Keep only products with >10 transactions
    
    return df_filtered

# Task 2: Pivot Tables
def create_pivot_tables(df):
    """
    Create various pivot tables
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        dict: Dictionary of pivot tables
    """
    pivots = {}
    
    # TODO: Basic pivot - sales by category and region
    pivots['category_region'] = pd.pivot_table(
        df,
        values='total_amount',
        index='category',
        columns='region',
        aggfunc='sum',
        fill_value=0
    )
    
    # TODO: Pivot with multiple aggregations
    pivots['multi_agg'] = pd.pivot_table(
        df,
        values='total_amount',
        index='category',
        columns='region',
        aggfunc=['sum', 'mean', 'count'],
        fill_value=0
    )
    
    # TODO: Pivot with margins (totals)
    pivots['with_margins'] = pd.pivot_table(
        df,
        values='total_amount',
        index='category',
        columns='region',
        aggfunc='sum',
        margins=True,
        margins_name='Total'
    )
    
    # TODO: Time-based pivot (add month column first)
    df['month'] = pd.to_datetime(df['date']).dt.to_period('M')
    pivots['monthly'] = pd.pivot_table(
        df,
        values='total_amount',
        index='month',
        columns='category',
        aggfunc='sum'
    )
    
    return pivots

def create_crosstabs(df):
    """
    Create cross-tabulations
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        dict: Dictionary of crosstabs
    """
    crosstabs = {}
    
    # TODO: Frequency table - category vs region
    crosstabs['frequency'] = pd.crosstab(
        df['category'],
        df['region'],
        margins=True
    )
    
    # TODO: Normalized crosstab (row percentages)
    crosstabs['row_pct'] = pd.crosstab(
        df['category'],
        df['region'],
        normalize='index'
    ) * 100
    
    # TODO: Crosstab with values
    crosstabs['with_values'] = pd.crosstab(
        df['category'],
        df['region'],
        values=df['total_amount'],
        aggfunc='sum'
    )
    
    return crosstabs

# Task 3: Window Functions
def calculate_rolling_metrics(df):
    """
    Calculate rolling window statistics
    
    Args:
        df (pd.DataFrame): Transaction data (sorted by date)
    
    Returns:
        pd.DataFrame: Data with rolling metrics
    """
    df_rolling = df.copy()
    df_rolling = df_rolling.sort_values('date')
    
    # TODO: Daily aggregation first
    daily_sales = df_rolling.groupby('date')['total_amount'].sum().reset_index()
    daily_sales = daily_sales.set_index('date')
    
    # TODO: 7-day rolling average
    daily_sales['rolling_7d_avg'] = daily_sales['total_amount'].rolling(window=7).mean()
    
    # TODO: 30-day rolling average
    daily_sales['rolling_30d_avg'] = daily_sales['total_amount'].rolling(window=30).mean()
    
    # TODO: Rolling standard deviation
    daily_sales['rolling_7d_std'] = daily_sales['total_amount'].rolling(window=7).std()
    
    # TODO: Cumulative sum
    daily_sales['cumulative_sum'] = daily_sales['total_amount'].cumsum()
    
    # TODO: Percentage change
    daily_sales['pct_change'] = daily_sales['total_amount'].pct_change() * 100
    
    return daily_sales

def calculate_expanding_metrics(df):
    """
    Calculate expanding window statistics
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Data with expanding metrics
    """
    df_expanding = df.copy()
    df_expanding = df_expanding.sort_values('date')
    
    # Daily aggregation
    daily_sales = df_expanding.groupby('date')['total_amount'].sum()
    
    # TODO: Expanding mean (running average)
    expanding_mean = daily_sales.expanding().mean()
    
    # TODO: Expanding sum (cumulative)
    expanding_sum = daily_sales.expanding().sum()
    
    # TODO: Expanding std
    expanding_std = daily_sales.expanding().std()
    
    result = pd.DataFrame({
        'daily_sales': daily_sales,
        'expanding_mean': expanding_mean,
        'expanding_sum': expanding_sum,
        'expanding_std': expanding_std
    })
    
    return result

def rank_within_groups(df):
    """
    Rank values within groups
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Data with rankings
    """
    df_ranked = df.copy()
    
    # TODO: Rank by amount within category
    df_ranked['rank_in_category'] = df_ranked.groupby('category')['total_amount'].rank(
        ascending=False, method='dense'
    )
    
    # TODO: Percentile rank
    df_ranked['percentile_rank'] = df_ranked.groupby('category')['total_amount'].rank(
        pct=True
    ) * 100
    
    # TODO: Top N indicator
    df_ranked['is_top_10_in_category'] = df_ranked['rank_in_category'] <= 10
    
    return df_ranked

# Task 4: Advanced Transformations
def apply_functions(df):
    """
    Apply various transformation functions
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Transformed data
    """
    df_transformed = df.copy()
    
    # TODO: Apply function to Series
    df_transformed['price_category'] = df_transformed['unit_price'].apply(
        lambda x: 'Low' if x < 50 else 'Medium' if x < 200 else 'High'
    )
    
    # TODO: Apply function to DataFrame (row-wise)
    df_transformed['discount'] = df_transformed.apply(
        lambda row: row['total_amount'] * 0.1 if row['quantity'] > 5 else 0,
        axis=1
    )
    
    # TODO: Map values
    region_mapping = {'North': 'N', 'South': 'S', 'East': 'E', 'West': 'W'}
    df_transformed['region_code'] = df_transformed['region'].map(region_mapping)
    
    return df_transformed

def create_bins_and_dummies(df):
    """
    Create bins and dummy variables
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Data with bins and dummies
    """
    df_binned = df.copy()
    
    # TODO: Bin continuous variable (amount)
    df_binned['amount_bin'] = pd.cut(
        df_binned['total_amount'],
        bins=[0, 100, 500, 1000, float('inf')],
        labels=['Small', 'Medium', 'Large', 'XLarge']
    )
    
    # TODO: Quantile-based bins
    df_binned['amount_quartile'] = pd.qcut(
        df_binned['total_amount'],
        q=4,
        labels=['Q1', 'Q2', 'Q3', 'Q4']
    )
    
    # TODO: Create dummy variables
    category_dummies = pd.get_dummies(df_binned['category'], prefix='cat')
    df_binned = pd.concat([df_binned, category_dummies], axis=1)
    
    return df_binned

def normalize_data(df):
    """
    Normalize numeric columns
    
    Args:
        df (pd.DataFrame): Transaction data
    
    Returns:
        pd.DataFrame: Normalized data
    """
    df_norm = df.copy()
    
    # TODO: Min-max normalization
    df_norm['quantity_normalized'] = (
        (df_norm['quantity'] - df_norm['quantity'].min()) /
        (df_norm['quantity'].max() - df_norm['quantity'].min())
    )
    
    # TODO: Z-score standardization
    df_norm['amount_standardized'] = (
        (df_norm['total_amount'] - df_norm['total_amount'].mean()) /
        df_norm['total_amount'].std()
    )
    
    return df_norm

def main():
    """Main execution"""
    print("=" * 60)
    print("LAB 04: DATA TRANSFORMATION AND AGGREGATION")
    print("=" * 60)
    
    # Create data
    print("\n--- CREATING TRANSACTION DATA ---")
    df = create_transaction_data(1000)
    print(f"Created {len(df)} transactions")
    print(df.head())
    
    # Task 1: GroupBy
    print("\n--- TASK 1: GROUPBY OPERATIONS ---")
    groupby_results = basic_groupby_analysis(df)
    print("\nSales by Category:")
    print(groupby_results['sales_by_category'])
    
    custom_agg = custom_aggregations(df)
    print("\nCustom Aggregations:")
    print(custom_agg)
    
    # Task 2: Pivot Tables
    print("\n--- TASK 2: PIVOT TABLES ---")
    pivots = create_pivot_tables(df)
    print("\nSales by Category and Region:")
    print(pivots['category_region'])
    
    print("\nWith Margins:")
    print(pivots['with_margins'])
    
    # Task 3: Rolling Metrics
    print("\n--- TASK 3: WINDOW FUNCTIONS ---")
    rolling_df = calculate_rolling_metrics(df)
    print("\nRolling Metrics:")
    print(rolling_df.tail(10))
    
    # Task 4: Advanced Transformations
    print("\n--- TASK 4: ADVANCED TRANSFORMATIONS ---")
    df_transformed = apply_functions(df)
    print("\nTransformed Data:")
    print(df_transformed[['total_amount', 'price_category', 'discount']].head())
    
    df_binned = create_bins_and_dummies(df)
    print("\nBinned Data:")
    print(df_binned[['total_amount', 'amount_bin', 'amount_quartile']].head())
    
    print("\n" + "=" * 60)
    print("LAB 04 COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()
```

## Expected Deliverables

1. Complete transformation script
2. Summary reports showing:
   - Sales by category and region
   - Monthly trends with rolling averages
   - Top products by category
   - Customer segmentation
3. Pivot tables and visualizations

## Bonus Challenges

1. **Time Series Analysis**: Calculate year-over-year growth
2. **Customer Segmentation**: RFM (Recency, Frequency, Monetary) analysis
3. **Product Analysis**: ABC analysis for inventory management
4. **Cohort Analysis**: Monthly cohort retention
5. **Statistical Tests**: Chi-square test for independence

## Common Pitfalls

- Forgetting to sort before rolling calculations
- Not resetting index after groupby
- Incorrect aggregation function selection
- Memory issues with large pivot tables
- Not handling missing values in aggregations

## Resources

- GroupBy: https://pandas.pydata.org/docs/user_guide/groupby.html
- Pivot Tables: https://pandas.pydata.org/docs/reference/api/pandas.pivot_table.html
- Window Functions: https://pandas.pydata.org/docs/user_guide/window.html

## Submission

Submit `lab_04_solution.py` with all transformation functions implemented and example outputs.
