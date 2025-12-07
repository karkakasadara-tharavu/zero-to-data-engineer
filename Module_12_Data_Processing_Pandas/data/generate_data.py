"""
Data Generation Script for Module 12: Data Processing with Pandas
Creates realistic sample datasets for all lab exercises
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json

# Set seed for reproducibility
np.random.seed(42)

def generate_sales_data(n_rows=10000):
    """Generate sales transactions dataset"""
    print("Generating sales data...")
    
    start_date = datetime(2021, 1, 1)
    dates = [start_date + timedelta(hours=i) for i in range(n_rows)]
    
    categories = ['Electronics', 'Clothing', 'Books', 'Home', 'Sports', 'Toys', 'Food']
    products = [f'Product_{i:04d}' for i in range(1, 501)]
    regions = ['North', 'South', 'East', 'West']
    
    sales_df = pd.DataFrame({
        'order_id': range(1, n_rows + 1),
        'order_date': dates,
        'customer_id': np.random.randint(1, 1001, n_rows),
        'product_id': np.random.choice(products, n_rows),
        'category': np.random.choice(categories, n_rows),
        'quantity': np.random.randint(1, 20, n_rows),
        'unit_price': np.random.uniform(10, 500, n_rows).round(2),
        'discount': np.random.choice([0, 0.05, 0.10, 0.15, 0.20], n_rows, p=[0.5, 0.2, 0.15, 0.10, 0.05]),
        'region': np.random.choice(regions, n_rows),
        'payment_method': np.random.choice(['Credit Card', 'PayPal', 'Bank Transfer', 'Cash'], n_rows)
    })
    
    # Calculate derived fields
    sales_df['subtotal'] = (sales_df['quantity'] * sales_df['unit_price']).round(2)
    sales_df['discount_amount'] = (sales_df['subtotal'] * sales_df['discount']).round(2)
    sales_df['total'] = (sales_df['subtotal'] - sales_df['discount_amount']).round(2)
    
    # Add some missing values (5%)
    missing_indices = np.random.choice(sales_df.index, size=int(n_rows * 0.05), replace=False)
    sales_df.loc[missing_indices, 'discount'] = np.nan
    
    # Add some duplicates (1%)
    duplicate_indices = np.random.choice(sales_df.index, size=int(n_rows * 0.01), replace=False)
    duplicates = sales_df.loc[duplicate_indices].copy()
    sales_df = pd.concat([sales_df, duplicates], ignore_index=True)
    
    sales_df.to_csv('data/sales.csv', index=False)
    print(f"✓ Created sales.csv ({len(sales_df)} rows)")
    return sales_df

def generate_customer_data(n_rows=1000):
    """Generate customer profiles dataset"""
    print("Generating customer data...")
    
    first_names = ['John', 'Jane', 'Michael', 'Emily', 'David', 'Sarah', 'James', 'Emma', 'Robert', 'Olivia']
    last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Martinez', 'Wilson']
    
    registration_dates = pd.date_range(start='2020-01-01', periods=n_rows, freq='6H')
    
    customers_df = pd.DataFrame({
        'customer_id': range(1, n_rows + 1),
        'first_name': np.random.choice(first_names, n_rows),
        'last_name': np.random.choice(last_names, n_rows),
        'email': [f'customer{i}@example.com' for i in range(1, n_rows + 1)],
        'phone': [f'555-{np.random.randint(1000, 9999)}' for _ in range(n_rows)],
        'registration_date': registration_dates,
        'age': np.random.randint(18, 75, n_rows),
        'gender': np.random.choice(['M', 'F', 'Other'], n_rows, p=[0.48, 0.48, 0.04]),
        'city': np.random.choice(['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'], n_rows),
        'state': np.random.choice(['NY', 'CA', 'IL', 'TX', 'AZ'], n_rows),
        'zip_code': [f'{np.random.randint(10000, 99999)}' for _ in range(n_rows)],
        'segment': np.random.choice(['Premium', 'Standard', 'Basic'], n_rows, p=[0.2, 0.5, 0.3])
    })
    
    # Add some missing emails (3%)
    missing_indices = np.random.choice(customers_df.index, size=int(n_rows * 0.03), replace=False)
    customers_df.loc[missing_indices, 'email'] = np.nan
    
    # CSV format
    customers_df.to_csv('data/customers.csv', index=False)
    
    # JSON format (for file I/O lab)
    customers_df.to_json('data/customers.json', orient='records', indent=2)
    
    print(f"✓ Created customers.csv and customers.json ({len(customers_df)} rows)")
    return customers_df

def generate_product_data(n_rows=500):
    """Generate product catalog dataset"""
    print("Generating product data...")
    
    categories = ['Electronics', 'Clothing', 'Books', 'Home', 'Sports', 'Toys', 'Food']
    suppliers = [f'Supplier_{i}' for i in range(1, 21)]
    
    products_df = pd.DataFrame({
        'product_id': [f'Product_{i:04d}' for i in range(1, n_rows + 1)],
        'product_name': [f'Product Name {i}' for i in range(1, n_rows + 1)],
        'category': np.random.choice(categories, n_rows),
        'supplier': np.random.choice(suppliers, n_rows),
        'cost': np.random.uniform(5, 300, n_rows).round(2),
        'price': np.random.uniform(10, 500, n_rows).round(2),
        'stock_quantity': np.random.randint(0, 1000, n_rows),
        'reorder_level': np.random.randint(10, 100, n_rows),
        'discontinued': np.random.choice([True, False], n_rows, p=[0.1, 0.9])
    })
    
    # Calculate profit margin
    products_df['profit_margin'] = ((products_df['price'] - products_df['cost']) / products_df['price']).round(4)
    
    products_df.to_csv('data/products.csv', index=False)
    print(f"✓ Created products.csv ({len(products_df)} rows)")
    return products_df

def generate_time_series_data():
    """Generate time series dataset for Lab 06"""
    print("Generating time series data...")
    
    # Stock prices (minute data for 5 trading days)
    dates = pd.date_range('2024-01-01 09:30', periods=390*5, freq='min')
    stock_df = pd.DataFrame({
        'timestamp': dates,
        'open': 100 + np.random.randn(len(dates)).cumsum() * 0.5,
        'high': 100 + np.random.randn(len(dates)).cumsum() * 0.5 + 2,
        'low': 100 + np.random.randn(len(dates)).cumsum() * 0.5 - 2,
        'close': 100 + np.random.randn(len(dates)).cumsum() * 0.5,
        'volume': np.random.randint(1000, 10000, len(dates))
    })
    
    stock_df.to_csv('data/stock_prices.csv', index=False)
    print(f"✓ Created stock_prices.csv ({len(stock_df)} rows)")
    
    # Weather data (hourly)
    dates_hourly = pd.date_range('2024-01-01', periods=24*90, freq='H')
    weather_df = pd.DataFrame({
        'timestamp': dates_hourly,
        'temperature': 50 + 20*np.sin(np.arange(len(dates_hourly))*2*np.pi/24) + np.random.randn(len(dates_hourly))*5,
        'humidity': 50 + np.random.randn(len(dates_hourly))*10,
        'pressure': 1013 + np.random.randn(len(dates_hourly))*5,
        'wind_speed': np.abs(np.random.randn(len(dates_hourly)) * 10)
    })
    
    weather_df.to_csv('data/weather.csv', index=False)
    print(f"✓ Created weather.csv ({len(weather_df)} rows)")

def generate_campaign_data(n_rows=50):
    """Generate marketing campaign dataset"""
    print("Generating campaign data...")
    
    channels = ['Email', 'Social Media', 'Search', 'Display', 'TV', 'Radio']
    
    campaigns_df = pd.DataFrame({
        'campaign_id': range(1, n_rows + 1),
        'campaign_name': [f'Campaign {i}' for i in range(1, n_rows + 1)],
        'channel': np.random.choice(channels, n_rows),
        'start_date': pd.date_range('2023-01-01', periods=n_rows, freq='W'),
        'end_date': pd.date_range('2023-01-07', periods=n_rows, freq='W'),
        'budget': np.random.uniform(5000, 50000, n_rows).round(2),
        'impressions': np.random.randint(10000, 1000000, n_rows),
        'clicks': np.random.randint(100, 50000, n_rows),
        'conversions': np.random.randint(10, 1000, n_rows),
        'revenue': np.random.uniform(1000, 100000, n_rows).round(2)
    })
    
    # Calculate derived metrics
    campaigns_df['ctr'] = (campaigns_df['clicks'] / campaigns_df['impressions']).round(4)
    campaigns_df['conversion_rate'] = (campaigns_df['conversions'] / campaigns_df['clicks']).round(4)
    campaigns_df['cac'] = (campaigns_df['budget'] / campaigns_df['conversions']).round(2)
    campaigns_df['roi'] = ((campaigns_df['revenue'] - campaigns_df['budget']) / campaigns_df['budget'] * 100).round(2)
    
    campaigns_df.to_csv('data/campaigns.csv', index=False)
    print(f"✓ Created campaigns.csv ({len(campaigns_df)} rows)")
    return campaigns_df

def generate_returns_data(n_rows=2500):
    """Generate product returns dataset"""
    print("Generating returns data...")
    
    reasons = ['Defective', 'Wrong Item', 'Not as Described', 'Changed Mind', 'Too Small', 'Too Large']
    products = [f'Product_{i:04d}' for i in range(1, 501)]
    
    returns_df = pd.DataFrame({
        'return_id': range(1, n_rows + 1),
        'order_id': np.random.randint(1, 10000, n_rows),
        'product_id': np.random.choice(products, n_rows),
        'return_date': pd.date_range('2021-01-15', periods=n_rows, freq='4H'),
        'reason': np.random.choice(reasons, n_rows),
        'condition': np.random.choice(['New', 'Opened', 'Used', 'Damaged'], n_rows, p=[0.3, 0.4, 0.2, 0.1]),
        'refund_amount': np.random.uniform(10, 500, n_rows).round(2),
        'processing_days': np.random.randint(1, 15, n_rows),
        'approved': np.random.choice([True, False], n_rows, p=[0.85, 0.15])
    })
    
    returns_df.to_csv('data/returns.csv', index=False)
    print(f"✓ Created returns.csv ({len(returns_df)} rows)")
    return returns_df

def generate_excel_multisheet():
    """Generate Excel file with multiple sheets"""
    print("Generating Excel file with multiple sheets...")
    
    # Sales summary sheet
    summary = pd.DataFrame({
        'Quarter': ['Q1', 'Q2', 'Q3', 'Q4'],
        'Revenue': [250000, 300000, 280000, 350000],
        'Expenses': [150000, 180000, 170000, 200000],
        'Profit': [100000, 120000, 110000, 150000]
    })
    
    # Product performance sheet
    performance = pd.DataFrame({
        'Category': ['Electronics', 'Clothing', 'Books', 'Home', 'Sports'],
        'Units_Sold': [15000, 25000, 12000, 8000, 6000],
        'Revenue': [450000, 300000, 180000, 200000, 150000],
        'Returns': [750, 1250, 240, 160, 90]
    })
    
    # Customer metrics sheet
    metrics = pd.DataFrame({
        'Metric': ['Total Customers', 'Active Customers', 'New Customers', 'Retention Rate', 'Avg Order Value'],
        'Value': [1000, 650, 200, 0.65, 127.50]
    })
    
    with pd.ExcelWriter('data/sales_report.xlsx', engine='openpyxl') as writer:
        summary.to_excel(writer, sheet_name='Summary', index=False)
        performance.to_excel(writer, sheet_name='Performance', index=False)
        metrics.to_excel(writer, sheet_name='Metrics', index=False)
    
    print("✓ Created sales_report.xlsx (3 sheets)")

def generate_dirty_data():
    """Generate intentionally messy data for cleaning lab"""
    print("Generating dirty data for cleaning exercises...")
    
    dirty_df = pd.DataFrame({
        'Customer Name': ['  John Smith  ', 'jane DOE', 'MIKE JONES', None, '  Alice Brown'],
        'Email': ['john@email.com', 'invalid-email', 'mike@email.com', 'alice@email.com', None],
        'Age': [25, 150, 30, 28, -5],  # Invalid ages
        'Income': [50000, None, 75000, 65000, 80000],
        'Purchase Date': ['2024-01-01', '01/15/2024', '2024-02-30', '2024-03-15', None],  # Inconsistent formats
        'Amount': [100.50, 200.75, None, 150.25, 300.00],
        'Category': ['  Electronics  ', 'CLOTHING', 'electronics', 'Books', 'clothing']
    })
    
    # Add duplicates
    dirty_df = pd.concat([dirty_df, dirty_df.iloc[[0, 2]]], ignore_index=True)
    
    dirty_df.to_csv('data/dirty_data.csv', index=False)
    print(f"✓ Created dirty_data.csv ({len(dirty_df)} rows with quality issues)")

def create_readme():
    """Create README for data directory"""
    readme_content = """# Module 12: Sample Data Files

This directory contains sample datasets for all Module 12 labs.

## Files Overview

### 1. sales.csv (10,100 rows)
**Purpose**: Labs 01-05, 09, 10
**Columns**: order_id, order_date, customer_id, product_id, category, quantity, unit_price, discount, region, payment_method, subtotal, discount_amount, total
**Features**:
- Realistic e-commerce transactions
- 5% missing values in discount column
- 1% duplicate records
- Date range: 2021-2024

### 2. customers.csv / customers.json (1,000 rows)
**Purpose**: Labs 02, 05, 10
**Columns**: customer_id, first_name, last_name, email, phone, registration_date, age, gender, city, state, zip_code, segment
**Features**:
- Customer profiles with demographics
- 3% missing emails
- Available in CSV and JSON formats

### 3. products.csv (500 rows)
**Purpose**: Labs 01, 05, 10
**Columns**: product_id, product_name, category, supplier, cost, price, stock_quantity, reorder_level, discontinued, profit_margin
**Features**:
- Product catalog with pricing
- Stock levels and profitability data
- 10% discontinued products

### 4. stock_prices.csv (1,950 rows)
**Purpose**: Lab 06 (Time Series)
**Columns**: timestamp, open, high, low, close, volume
**Features**:
- Minute-level stock data
- 5 trading days
- OHLC format

### 5. weather.csv (2,160 rows)
**Purpose**: Lab 06 (Time Series)
**Columns**: timestamp, temperature, humidity, pressure, wind_speed
**Features**:
- Hourly weather data
- 90 days of observations
- Temperature follows daily cycle

### 6. campaigns.csv (50 rows)
**Purpose**: Lab 10
**Columns**: campaign_id, campaign_name, channel, start_date, end_date, budget, impressions, clicks, conversions, revenue, ctr, conversion_rate, cac, roi
**Features**:
- Marketing campaign performance
- Multiple channels (Email, Social, Search, Display, TV, Radio)
- ROI calculations included

### 7. returns.csv (2,500 rows)
**Purpose**: Labs 05, 10
**Columns**: return_id, order_id, product_id, return_date, reason, condition, refund_amount, processing_days, approved
**Features**:
- Product return records
- Various return reasons
- 85% approval rate

### 8. sales_report.xlsx (3 sheets)
**Purpose**: Lab 02 (File I/O)
**Sheets**: Summary, Performance, Metrics
**Features**:
- Quarterly financial summary
- Category performance data
- Customer metrics

### 9. dirty_data.csv (7 rows)
**Purpose**: Lab 03 (Data Cleaning)
**Features**:
- Inconsistent formatting
- Missing values
- Invalid data (ages, dates)
- Duplicate records
- String cleaning needed

## Usage

Each lab specification indicates which datasets to use. Most labs use multiple datasets to demonstrate real-world scenarios.

## Data Generation

All datasets are generated using `generate_data.py`. To regenerate:

```python
python generate_data.py
```

This will create fresh datasets with the same structure but different random values (seed=42 for reproducibility).

## Data Relationships

- `sales.customer_id` → `customers.customer_id`
- `sales.product_id` → `products.product_id`
- `returns.order_id` → `sales.order_id`
- `returns.product_id` → `products.product_id`

## Size Information

- Total size: ~15 MB uncompressed
- All CSV files use UTF-8 encoding
- Dates are in ISO format (YYYY-MM-DD)
- Numbers use standard formats (no currency symbols)

## Notes

- Datasets contain intentional data quality issues for cleaning labs
- Product IDs are formatted as 'Product_0001' through 'Product_0500'
- Customer IDs range from 1 to 1000
- Some datasets have overlapping date ranges for joining exercises
- All financial amounts are in USD

## License

These datasets are for educational purposes only. Feel free to modify and use for learning.
"""
    
    with open('data/README.md', 'w') as f:
        f.write(readme_content)
    
    print("✓ Created README.md")

def main():
    """Generate all sample datasets"""
    print("\n" + "="*60)
    print("GENERATING MODULE 12 SAMPLE DATA")
    print("="*60 + "\n")
    
    # Generate all datasets
    generate_sales_data(10000)
    generate_customer_data(1000)
    generate_product_data(500)
    generate_time_series_data()
    generate_campaign_data(50)
    generate_returns_data(2500)
    generate_excel_multisheet()
    generate_dirty_data()
    create_readme()
    
    print("\n" + "="*60)
    print("DATA GENERATION COMPLETE ✓")
    print("="*60)
    print("\nGenerated files in 'data/' directory:")
    print("  - sales.csv")
    print("  - customers.csv")
    print("  - customers.json")
    print("  - products.csv")
    print("  - stock_prices.csv")
    print("  - weather.csv")
    print("  - campaigns.csv")
    print("  - returns.csv")
    print("  - sales_report.xlsx")
    print("  - dirty_data.csv")
    print("  - README.md")
    print("\nTotal: 11 files ready for use in labs!")

if __name__ == "__main__":
    main()
