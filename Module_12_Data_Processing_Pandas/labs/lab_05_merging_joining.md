# Lab 05: Merging and Joining Data

## Estimated Time: 75 minutes

## Objectives
- Merge DataFrames using different join types
- Concatenate DataFrames vertically and horizontally
- Handle duplicate keys and column names
- Validate merge operations
- Combine data from multiple sources

## Prerequisites
- Completed Labs 01-04
- Understanding of SQL joins
- Knowledge of relational database concepts

## Background

Your company has data spread across multiple systems: customer data in one database, order data in another, and product information in a third. You need to combine these datasets for comprehensive analysis.

## Tasks

### Task 1: Basic Merging Operations (20 minutes)

Implement all four join types and understand their differences.

**Requirements:**
1. Inner join - keep only matching records
2. Left join - keep all from left, matching from right
3. Right join - keep all from right, matching from left
4. Outer join - keep all records from both
5. Compare results and row counts

### Task 2: Multi-Table Joins (20 minutes)

Combine data from multiple related tables.

**Requirements:**
1. Create relational dataset (customers, orders, products)
2. Join customers with orders
3. Join result with products
4. Calculate metrics across joined data
5. Handle missing relationships

### Task 3: Concatenation and Stacking (15 minutes)

Stack DataFrames vertically and horizontally.

**Requirements:**
1. Combine multiple monthly files
2. Stack with keys for identification
3. Handle different columns
4. Merge with different indices
5. Reset and manage indices

### Task 4: Advanced Join Scenarios (20 minutes)

Handle complex merge situations.

**Requirements:**
1. Merge on multiple columns
2. Handle duplicate keys (one-to-many, many-to-many)
3. Use indicator to track merge source
4. Validate merge relationships
5. Find unmatched records

## Starter Code

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def create_relational_data():
    """Create related datasets"""
    # Customers
    customers = pd.DataFrame({
        'customer_id': [f'C{i:04d}' for i in range(1, 51)],
        'name': [f'Customer {i}' for i in range(1, 51)],
        'email': [f'customer{i}@email.com' for i in range(1, 51)],
        'city': np.random.choice(['NY', 'LA', 'Chicago', 'Houston'], 50),
        'join_date': pd.date_range('2023-01-01', periods=50, freq='W')
    })
    
    # Orders
    np.random.seed(42)
    orders = pd.DataFrame({
        'order_id': [f'O{i:05d}' for i in range(1, 201)],
        'customer_id': np.random.choice(customers['customer_id'], 200),
        'order_date': [datetime(2024, 1, 1) + timedelta(days=np.random.randint(0, 180))
                      for _ in range(200)],
        'status': np.random.choice(['Pending', 'Shipped', 'Delivered'], 200)
    })
    
    # Order items
    order_items = pd.DataFrame({
        'item_id': [f'I{i:05d}' for i in range(1, 501)],
        'order_id': np.random.choice(orders['order_id'], 500),
        'product_id': [f'P{i:03d}' for i in np.random.randint(1, 31, 500)],
        'quantity': np.random.randint(1, 5, 500),
        'unit_price': np.random.uniform(10, 200, 500)
    })
    
    # Products
    products = pd.DataFrame({
        'product_id': [f'P{i:03d}' for i in range(1, 31)],
        'product_name': [f'Product {i}' for i in range(1, 31)],
        'category': np.random.choice(['Electronics', 'Clothing', 'Books'], 30),
        'cost': np.random.uniform(5, 150, 30)
    })
    
    return customers, orders, order_items, products

# Task 1: Basic Merging
def demonstrate_join_types(df1, df2):
    """Show all join types"""
    results = {}
    
    # TODO: Inner join
    results['inner'] = pd.merge(df1, df2, on='customer_id', how='inner')
    
    # TODO: Left join
    results['left'] = pd.merge(df1, df2, on='customer_id', how='left')
    
    # TODO: Right join
    results['right'] = pd.merge(df1, df2, on='customer_id', how='right')
    
    # TODO: Outer join
    results['outer'] = pd.merge(df1, df2, on='customer_id', how='outer')
    
    return results

def compare_joins(customers, orders):
    """Compare results of different joins"""
    joins = demonstrate_join_types(customers, orders)
    
    comparison = pd.DataFrame({
        'Join Type': joins.keys(),
        'Rows': [len(df) for df in joins.values()],
        'Null Count': [df.isnull().sum().sum() for df in joins.values()]
    })
    
    return comparison

# Task 2: Multi-Table Joins
def create_order_summary(customers, orders, order_items, products):
    """
    Join multiple tables to create comprehensive order view
    
    Returns:
        pd.DataFrame: Complete order information
    """
    # TODO: Join orders with customers
    orders_with_customers = pd.merge(
        orders,
        customers[['customer_id', 'name', 'city']],
        on='customer_id',
        how='left'
    )
    
    # TODO: Join order_items with orders
    items_with_orders = pd.merge(
        order_items,
        orders_with_customers,
        on='order_id',
        how='left'
    )
    
    # TODO: Join with products
    complete_data = pd.merge(
        items_with_orders,
        products[['product_id', 'product_name', 'category']],
        on='product_id',
        how='left'
    )
    
    # TODO: Calculate totals
    complete_data['line_total'] = complete_data['quantity'] * complete_data['unit_price']
    
    return complete_data

def calculate_customer_metrics(complete_data):
    """Calculate metrics from joined data"""
    metrics = complete_data.groupby('customer_id').agg({
        'order_id': 'nunique',
        'line_total': 'sum',
        'quantity': 'sum',
        'item_id': 'count'
    }).rename(columns={
        'order_id': 'total_orders',
        'line_total': 'total_spent',
        'quantity': 'total_quantity',
        'item_id': 'total_items'
    })
    
    metrics['avg_order_value'] = metrics['total_spent'] / metrics['total_orders']
    
    return metrics

# Task 3: Concatenation
def concat_monthly_data():
    """Simulate combining monthly sales files"""
    monthly_dfs = []
    
    for month in range(1, 4):
        df = pd.DataFrame({
            'date': pd.date_range(f'2024-{month:02d}-01', periods=30, freq='D'),
            'sales': np.random.uniform(1000, 5000, 30),
            'month': month
        })
        monthly_dfs.append(df)
    
    # TODO: Concatenate vertically
    combined = pd.concat(monthly_dfs, ignore_index=True)
    
    # TODO: Concatenate with keys
    combined_with_keys = pd.concat(monthly_dfs, keys=['Jan', 'Feb', 'Mar'])
    
    return combined, combined_with_keys

def concat_different_columns():
    """Concatenate DataFrames with different columns"""
    df1 = pd.DataFrame({
        'A': [1, 2, 3],
        'B': [4, 5, 6]
    })
    
    df2 = pd.DataFrame({
        'A': [7, 8, 9],
        'C': [10, 11, 12]
    })
    
    # TODO: Outer join (default)
    result_outer = pd.concat([df1, df2], ignore_index=True)
    
    # TODO: Inner join (only common columns)
    result_inner = pd.concat([df1, df2], join='inner', ignore_index=True)
    
    return result_outer, result_inner

def horizontal_concat():
    """Concatenate horizontally (add columns)"""
    df1 = pd.DataFrame({
        'A': [1, 2, 3],
        'B': [4, 5, 6]
    }, index=['a', 'b', 'c'])
    
    df2 = pd.DataFrame({
        'C': [7, 8, 9],
        'D': [10, 11, 12]
    }, index=['a', 'b', 'c'])
    
    # TODO: Concatenate along axis=1
    result = pd.concat([df1, df2], axis=1)
    
    return result

# Task 4: Advanced Scenarios
def merge_on_multiple_columns(df1, df2):
    """Merge on multiple key columns"""
    # TODO: Merge on multiple columns
    result = pd.merge(
        df1,
        df2,
        on=['customer_id', 'date'],
        how='inner'
    )
    
    return result

def handle_duplicate_columns(df1, df2):
    """Handle duplicate column names in merge"""
    # TODO: Merge with suffixes
    result = pd.merge(
        df1,
        df2,
        on='id',
        suffixes=('_left', '_right')
    )
    
    return result

def use_merge_indicator(df1, df2):
    """Track source of merged rows"""
    # TODO: Merge with indicator
    result = pd.merge(
        df1,
        df2,
        on='customer_id',
        how='outer',
        indicator=True
    )
    
    # Count by source
    source_counts = result['_merge'].value_counts()
    
    return result, source_counts

def validate_merge(df1, df2):
    """Validate merge relationships"""
    # TODO: Try different validations
    try:
        # Should be one-to-one
        result = pd.merge(df1, df2, on='id', validate='one_to_one')
    except Exception as e:
        print(f"One-to-one validation failed: {e}")
    
    try:
        # Should be one-to-many
        result = pd.merge(df1, df2, on='id', validate='one_to_many')
    except Exception as e:
        print(f"One-to-many validation failed: {e}")
    
    return result

def find_unmatched_records(customers, orders):
    """Find records that don't match"""
    # TODO: Merge with indicator
    merged = pd.merge(
        customers,
        orders,
        on='customer_id',
        how='outer',
        indicator='source'
    )
    
    # TODO: Find customers without orders
    customers_no_orders = merged[merged['source'] == 'left_only']
    
    # TODO: Find orders without customers (data quality issue)
    orders_no_customers = merged[merged['source'] == 'right_only']
    
    return customers_no_orders, orders_no_customers

def main():
    """Main execution"""
    print("=" * 60)
    print("LAB 05: MERGING AND JOINING DATA")
    print("=" * 60)
    
    # Create data
    print("\n--- CREATING RELATIONAL DATA ---")
    customers, orders, order_items, products = create_relational_data()
    print(f"Customers: {len(customers)}")
    print(f"Orders: {len(orders)}")
    print(f"Order Items: {len(order_items)}")
    print(f"Products: {len(products)}")
    
    # Task 1: Join types
    print("\n--- TASK 1: JOIN TYPES ---")
    comparison = compare_joins(customers, orders)
    print(comparison)
    
    # Task 2: Multi-table joins
    print("\n--- TASK 2: MULTI-TABLE JOINS ---")
    complete = create_order_summary(customers, orders, order_items, products)
    print(f"Complete dataset: {complete.shape}")
    print(complete.head())
    
    metrics = calculate_customer_metrics(complete)
    print("\nTop 5 customers by total spent:")
    print(metrics.nlargest(5, 'total_spent'))
    
    # Task 3: Concatenation
    print("\n--- TASK 3: CONCATENATION ---")
    combined, combined_keys = concat_monthly_data()
    print(f"Combined data: {combined.shape}")
    print(f"With keys: {combined_keys.index.names}")
    
    # Task 4: Advanced scenarios
    print("\n--- TASK 4: ADVANCED SCENARIOS ---")
    customers_no_orders, orders_no_customers = find_unmatched_records(customers, orders)
    print(f"Customers without orders: {len(customers_no_orders)}")
    print(f"Orders without customers: {len(orders_no_customers)}")
    
    # Merge with indicator
    merged_ind, source_counts = use_merge_indicator(customers, orders)
    print("\nMerge source distribution:")
    print(source_counts)
    
    print("\n" + "=" * 60)
    print("LAB 05 COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()
```

## Expected Deliverables

1. Complete merge and join script
2. Comparison of join types with row counts
3. Multi-table join creating comprehensive dataset
4. Analysis of unmatched records
5. Documentation of join decisions

## Bonus Challenges

1. **Index-based Joins**: Merge on index instead of columns
2. **Merge Validation**: Implement comprehensive merge validation
3. **Performance**: Compare merge vs join performance
4. **Cross Join**: Create Cartesian product
5. **Conditional Merge**: Merge based on date ranges

## Common Pitfalls

- Wrong join type selection
- Not handling duplicate keys
- Forgetting to specify suffixes
- Memory issues with large merges
- Not validating merge results

## Resources

- Merge: https://pandas.pydata.org/docs/reference/api/pandas.merge.html
- Concat: https://pandas.pydata.org/docs/reference/api/pandas.concat.html
- Join: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.join.html

## Submission

Submit `lab_05_solution.py` with all merge operations and analysis of results.
