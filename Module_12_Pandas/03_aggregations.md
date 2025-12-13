# Pandas Aggregations & GroupBy - Complete Guide

## 📚 What You'll Learn
- GroupBy operations
- Aggregation functions
- Multi-level grouping
- Transform and filter
- Window functions
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 GroupBy Concept

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SPLIT-APPLY-COMBINE                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Original DataFrame:                                                    │
│   ┌────────┬─────────────┬───────┐                                      │
│   │ Region │ Product     │ Sales │                                      │
│   ├────────┼─────────────┼───────┤                                      │
│   │ East   │ Widget      │  100  │                                      │
│   │ East   │ Gadget      │  150  │                                      │
│   │ West   │ Widget      │  200  │                                      │
│   │ West   │ Gadget      │  180  │                                      │
│   │ East   │ Widget      │  120  │                                      │
│   └────────┴─────────────┴───────┘                                      │
│                                                                          │
│   1. SPLIT by Region                                                     │
│   ┌────────┬───────┐     ┌────────┬───────┐                             │
│   │ East   │  100  │     │ West   │  200  │                             │
│   │ East   │  150  │     │ West   │  180  │                             │
│   │ East   │  120  │     └────────┴───────┘                             │
│   └────────┴───────┘                                                     │
│                                                                          │
│   2. APPLY aggregation (sum)                                             │
│   East: 100 + 150 + 120 = 370                                           │
│   West: 200 + 180 = 380                                                 │
│                                                                          │
│   3. COMBINE results                                                     │
│   ┌────────┬───────────┐                                                │
│   │ Region │ TotalSales│                                                │
│   ├────────┼───────────┤                                                │
│   │ East   │   370     │                                                │
│   │ West   │   380     │                                                │
│   └────────┴───────────┘                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Basic GroupBy

### Creating Groups

```python
import pandas as pd
import numpy as np

# Sample data
df = pd.DataFrame({
    'Region': ['East', 'East', 'West', 'West', 'East'],
    'Product': ['Widget', 'Gadget', 'Widget', 'Gadget', 'Widget'],
    'Sales': [100, 150, 200, 180, 120],
    'Quantity': [10, 15, 20, 18, 12]
})

# Create GroupBy object
grouped = df.groupby('Region')
print(type(grouped))  # <class 'pandas.core.groupby.DataFrameGroupBy'>

# GroupBy is lazy - no computation until aggregation
print(grouped)  # Just the object, not results
```

### Aggregation Methods

```python
# Single aggregation
df.groupby('Region')['Sales'].sum()
# Region
# East    370
# West    380

df.groupby('Region')['Sales'].mean()
df.groupby('Region')['Sales'].count()
df.groupby('Region')['Sales'].min()
df.groupby('Region')['Sales'].max()
df.groupby('Region')['Sales'].std()
df.groupby('Region')['Sales'].median()
df.groupby('Region')['Sales'].first()
df.groupby('Region')['Sales'].last()
df.groupby('Region')['Product'].nunique()  # Unique count

# Multiple columns
df.groupby('Region')[['Sales', 'Quantity']].sum()
```

### The agg() Method

```python
# Single function
df.groupby('Region')['Sales'].agg('sum')

# Multiple functions on one column
df.groupby('Region')['Sales'].agg(['sum', 'mean', 'count'])
#         sum    mean  count
# Region
# East    370  123.33      3
# West    380  190.00      2

# Different functions for different columns
df.groupby('Region').agg({
    'Sales': 'sum',
    'Quantity': 'mean'
})

# Multiple functions per column
df.groupby('Region').agg({
    'Sales': ['sum', 'mean', 'max'],
    'Quantity': ['sum', 'count']
})

# Named aggregations (cleaner column names)
df.groupby('Region').agg(
    TotalSales=('Sales', 'sum'),
    AvgSales=('Sales', 'mean'),
    TotalQty=('Quantity', 'sum'),
    OrderCount=('Sales', 'count')
)
```

### Custom Aggregation Functions

```python
# Using lambda
df.groupby('Region')['Sales'].agg(lambda x: x.max() - x.min())

# Named function
def range_agg(x):
    return x.max() - x.min()

df.groupby('Region')['Sales'].agg(range_agg)

# Multiple custom functions
def cv(x):
    """Coefficient of variation"""
    return x.std() / x.mean() * 100

df.groupby('Region').agg({
    'Sales': ['sum', 'mean', range_agg, cv]
})

# With named aggregations
df.groupby('Region').agg(
    SalesRange=('Sales', range_agg),
    SalesCV=('Sales', cv)
)
```

---

## 📊 Multi-Level Grouping

```python
# Group by multiple columns
df.groupby(['Region', 'Product'])['Sales'].sum()
# Region  Product
# East    Gadget     150
#         Widget     220
# West    Gadget     180
#         Widget     200

# Unstack to pivot
df.groupby(['Region', 'Product'])['Sales'].sum().unstack()
# Product  Gadget  Widget
# Region
# East       150     220
# West       180     200

# Reset index to get DataFrame
result = df.groupby(['Region', 'Product'])['Sales'].sum().reset_index()
#   Region Product  Sales
# 0   East  Gadget    150
# 1   East  Widget    220
# 2   West  Gadget    180
# 3   West  Widget    200

# Using as_index=False
df.groupby(['Region', 'Product'], as_index=False)['Sales'].sum()
```

---

## 🔄 Transform

Transform returns data with the same shape as the original.

```python
# Calculate group mean and broadcast back
df['RegionAvgSales'] = df.groupby('Region')['Sales'].transform('mean')
#   Region Product  Sales  RegionAvgSales
# 0   East  Widget    100      123.333
# 1   East  Gadget    150      123.333
# 2   West  Widget    200      190.000
# 3   West  Gadget    180      190.000
# 4   East  Widget    120      123.333

# Normalize within groups
df['SalesNormalized'] = df.groupby('Region')['Sales'].transform(
    lambda x: (x - x.mean()) / x.std()
)

# Percentage of group total
df['SalesPct'] = df.groupby('Region')['Sales'].transform(
    lambda x: x / x.sum() * 100
)

# Cumulative sum within group
df['CumSales'] = df.groupby('Region')['Sales'].transform('cumsum')

# Rank within group
df['SalesRank'] = df.groupby('Region')['Sales'].transform('rank')
df['SalesRank'] = df.groupby('Region')['Sales'].rank(method='dense', ascending=False)
```

---

## 🔍 Filter Groups

Keep or remove entire groups based on condition.

```python
# Keep groups with more than 2 rows
df.groupby('Region').filter(lambda x: len(x) > 2)

# Keep groups where mean sales > 150
df.groupby('Region').filter(lambda x: x['Sales'].mean() > 150)

# Keep groups where all values meet condition
df.groupby('Region').filter(lambda x: (x['Sales'] > 100).all())

# Keep groups where any value meets condition
df.groupby('Region').filter(lambda x: (x['Sales'] > 175).any())

# Keep top N groups
top_regions = df.groupby('Region')['Sales'].sum().nlargest(2).index
df[df['Region'].isin(top_regions)]
```

---

## 🔄 Apply

Most flexible - can return any shape.

```python
# Apply custom function to each group
def normalize_group(group):
    group['NormSales'] = (group['Sales'] - group['Sales'].min()) / \
                         (group['Sales'].max() - group['Sales'].min())
    return group

df = df.groupby('Region').apply(normalize_group)

# Return different shape
def top_n_rows(group, n=2):
    return group.nlargest(n, 'Sales')

df.groupby('Region').apply(top_n_rows, n=2)

# Return scalar per group
def range_agg(group):
    return group['Sales'].max() - group['Sales'].min()

df.groupby('Region').apply(range_agg)

# Return Series
def stats_summary(group):
    return pd.Series({
        'Mean': group['Sales'].mean(),
        'Std': group['Sales'].std(),
        'CV': group['Sales'].std() / group['Sales'].mean() * 100
    })

df.groupby('Region').apply(stats_summary)
```

---

## 📈 Window Functions

### Rolling (Moving) Windows

```python
# Create time series data
dates = pd.date_range('2024-01-01', periods=10)
ts = pd.DataFrame({
    'Date': dates,
    'Value': [10, 12, 15, 14, 18, 20, 22, 19, 25, 28]
})
ts.set_index('Date', inplace=True)

# Rolling mean (moving average)
ts['MA3'] = ts['Value'].rolling(window=3).mean()
ts['MA5'] = ts['Value'].rolling(window=5).mean()

# Rolling with minimum periods
ts['MA3_min1'] = ts['Value'].rolling(window=3, min_periods=1).mean()

# Rolling sum
ts['RollingSum'] = ts['Value'].rolling(window=3).sum()

# Rolling std, min, max
ts['RollingStd'] = ts['Value'].rolling(window=3).std()
ts['RollingMin'] = ts['Value'].rolling(window=3).min()
ts['RollingMax'] = ts['Value'].rolling(window=3).max()

# Centered rolling
ts['MA3_center'] = ts['Value'].rolling(window=3, center=True).mean()
```

### Expanding Windows

```python
# Cumulative from start
ts['CumMean'] = ts['Value'].expanding().mean()
ts['CumSum'] = ts['Value'].expanding().sum()
ts['CumMax'] = ts['Value'].expanding().max()
ts['CumMin'] = ts['Value'].expanding().min()

# Alternative cumulative methods
ts['CumSum2'] = ts['Value'].cumsum()
ts['CumMax2'] = ts['Value'].cummax()
ts['CumMin2'] = ts['Value'].cummin()
ts['CumProd'] = ts['Value'].cumprod()
```

### Grouped Window Operations

```python
# Rolling within groups
df['RollingMean'] = df.groupby('Region')['Sales'].transform(
    lambda x: x.rolling(window=2, min_periods=1).mean()
)

# Cumulative sum within groups
df['CumSales'] = df.groupby('Region')['Sales'].cumsum()

# Rank within groups
df['RankInGroup'] = df.groupby('Region')['Sales'].rank(ascending=False)

# Lag/Lead within groups
df['PrevSales'] = df.groupby('Region')['Sales'].shift(1)
df['NextSales'] = df.groupby('Region')['Sales'].shift(-1)

# Percentage change within groups
df['PctChange'] = df.groupby('Region')['Sales'].pct_change()
```

---

## 📋 Practical Examples

### Sales Analysis

```python
# Sample sales data
sales = pd.DataFrame({
    'Date': pd.date_range('2024-01-01', periods=100, freq='D').repeat(3),
    'Region': ['East', 'West', 'Central'] * 100,
    'Product': np.random.choice(['A', 'B', 'C'], 300),
    'Sales': np.random.randint(100, 1000, 300)
})

# 1. Total sales by region
sales.groupby('Region')['Sales'].sum()

# 2. Average sales by region and product
sales.groupby(['Region', 'Product'])['Sales'].mean().unstack()

# 3. Daily totals with 7-day moving average
daily = sales.groupby('Date')['Sales'].sum()
daily_ma = daily.rolling(7).mean()

# 4. Running total by region
sales['CumSales'] = sales.groupby('Region')['Sales'].cumsum()

# 5. Rank products within each region
sales['ProductRank'] = sales.groupby('Region').apply(
    lambda x: x.groupby('Product')['Sales'].sum().rank(ascending=False)
).reset_index(level=0, drop=True)

# 6. Month-over-month growth
monthly = sales.groupby(sales['Date'].dt.to_period('M'))['Sales'].sum()
monthly_growth = monthly.pct_change() * 100
```

### Customer Analysis

```python
# Customer purchase data
customers = pd.DataFrame({
    'CustomerID': [1, 1, 1, 2, 2, 3, 3, 3, 3],
    'PurchaseDate': pd.to_datetime(['2024-01-01', '2024-02-15', '2024-03-20',
                                     '2024-01-10', '2024-04-01', '2024-02-01',
                                     '2024-02-15', '2024-03-01', '2024-03-15']),
    'Amount': [100, 150, 200, 300, 250, 50, 75, 100, 125]
})

# Customer metrics
customer_metrics = customers.groupby('CustomerID').agg(
    TotalPurchases=('Amount', 'sum'),
    AvgPurchase=('Amount', 'mean'),
    PurchaseCount=('Amount', 'count'),
    FirstPurchase=('PurchaseDate', 'min'),
    LastPurchase=('PurchaseDate', 'max'),
    DaysSinceFirst=('PurchaseDate', lambda x: (x.max() - x.min()).days)
)

# Days between purchases
customers['DaysSinceLast'] = customers.groupby('CustomerID')['PurchaseDate'].diff().dt.days

# Customer lifetime value (simplified)
customers['CLV'] = customers.groupby('CustomerID')['Amount'].transform('sum')

# Top customers (Pareto)
customer_totals = customers.groupby('CustomerID')['Amount'].sum().sort_values(ascending=False)
customer_totals_cum = customer_totals.cumsum() / customer_totals.sum() * 100
top_20_pct = customer_totals_cum[customer_totals_cum <= 80].index
```

---

## 🎓 Interview Questions

### Q1: What is the split-apply-combine pattern?
**A:** GroupBy splits data into groups, applies a function to each group, and combines results. Example:
```python
df.groupby('Category')['Value'].sum()
```

### Q2: What is the difference between agg() and transform()?
**A:**
- **agg()**: Returns reduced output (one row per group)
- **transform()**: Returns same shape as input (broadcasts result back)

### Q3: How do you apply multiple aggregations to different columns?
**A:**
```python
df.groupby('Group').agg({
    'Sales': ['sum', 'mean'],
    'Quantity': 'count'
})
```
Or with named aggregations:
```python
df.groupby('Group').agg(
    TotalSales=('Sales', 'sum'),
    OrderCount=('Quantity', 'count')
)
```

### Q4: How do you calculate percentage of group total?
**A:** Use transform:
```python
df['Pct'] = df.groupby('Group')['Value'].transform(lambda x: x / x.sum() * 100)
```

### Q5: What is the difference between rolling() and expanding()?
**A:**
- **rolling()**: Fixed window size moving across data
- **expanding()**: Cumulative from start, window grows

### Q6: How do you filter entire groups based on a condition?
**A:** Use filter():
```python
df.groupby('Group').filter(lambda x: x['Value'].mean() > 100)
```

### Q7: How do you rank within groups?
**A:**
```python
df['Rank'] = df.groupby('Group')['Value'].rank(ascending=False)
```

### Q8: How do you calculate lag/lead within groups?
**A:**
```python
df['PrevValue'] = df.groupby('Group')['Value'].shift(1)
df['NextValue'] = df.groupby('Group')['Value'].shift(-1)
```

### Q9: How do you get the top N rows per group?
**A:**
```python
df.groupby('Group').apply(lambda x: x.nlargest(3, 'Value'))
# Or:
df.groupby('Group').head(3)  # First 3 per group
```

### Q10: How do you apply a custom aggregation function?
**A:**
```python
def custom_agg(x):
    return x.max() - x.min()

df.groupby('Group')['Value'].agg(custom_agg)
```

---

## 🔗 Related Topics
- [← Data Cleaning](./02_data_cleaning.md)
- [Merging & Joining →](./04_merging.md)
- [PySpark GroupBy →](../Module_15_PySpark/)

---

*Next: Learn about Merging and Joining DataFrames*
