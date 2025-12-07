# Module 12: Data Processing with Pandas

## Theory Section 08: Data Visualization with Pandas

### Learning Objectives
- Create visualizations directly from Pandas DataFrames
- Use built-in plotting methods
- Customize plot appearance
- Create various chart types (line, bar, scatter, histogram, box plots)
- Integrate with Matplotlib for advanced customization

### Introduction to Pandas Plotting

Pandas provides convenient plotting methods built on top of Matplotlib.

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Enable inline plotting in Jupyter
%matplotlib inline

# Set default figure size
plt.rcParams['figure.figsize'] = (10, 6)
```

### Basic Plotting

```python
# Create sample data
dates = pd.date_range('2024-01-01', periods=100)
df = pd.DataFrame({
    'A': np.random.randn(100).cumsum(),
    'B': np.random.randn(100).cumsum(),
    'C': np.random.randn(100).cumsum()
}, index=dates)

# Simple line plot
df.plot()
plt.title('Time Series Data')
plt.ylabel('Values')
plt.show()

# Plot single column
df['A'].plot()
plt.title('Column A')
plt.show()

# Plot specific columns
df[['A', 'B']].plot()
plt.show()
```

### Line Plots

```python
# Basic line plot
df.plot(kind='line')  # or df.plot.line()

# Customize line plot
df.plot(
    title='Custom Line Plot',
    xlabel='Date',
    ylabel='Value',
    style=['--', '-.', ':'],  # Line styles
    color=['red', 'green', 'blue'],
    linewidth=2,
    alpha=0.7,
    grid=True,
    legend=True,
    figsize=(12, 6)
)
plt.show()

# Multiple subplots
df.plot(subplots=True, layout=(3, 1), figsize=(10, 10))
plt.show()

# Shared y-axis
df.plot(subplots=True, sharey=True)
plt.show()
```

### Bar Charts

```python
# Sample data
data = pd.DataFrame({
    'product': ['A', 'B', 'C', 'D', 'E'],
    'sales': [150, 230, 180, 290, 210]
})

# Vertical bar chart
data.plot(x='product', y='sales', kind='bar')
plt.title('Sales by Product')
plt.ylabel('Sales ($)')
plt.show()

# Horizontal bar chart
data.plot(x='product', y='sales', kind='barh')
plt.xlabel('Sales ($)')
plt.show()

# Multiple columns
df2 = pd.DataFrame({
    'Q1': [100, 150, 120],
    'Q2': [120, 160, 140],
    'Q3': [130, 170, 150],
    'Q4': [140, 180, 160]
}, index=['Product A', 'Product B', 'Product C'])

# Grouped bar chart
df2.plot(kind='bar')
plt.title('Quarterly Sales by Product')
plt.ylabel('Sales')
plt.xticks(rotation=0)
plt.legend(title='Quarter')
plt.show()

# Stacked bar chart
df2.plot(kind='bar', stacked=True)
plt.title('Quarterly Sales (Stacked)')
plt.show()
```

### Histograms

```python
# Sample data
data = pd.Series(np.random.randn(1000))

# Basic histogram
data.plot(kind='hist')
plt.title('Distribution')
plt.xlabel('Value')
plt.ylabel('Frequency')
plt.show()

# Customize bins
data.plot(kind='hist', bins=50, alpha=0.7, color='green')
plt.show()

# Multiple histograms
df = pd.DataFrame({
    'A': np.random.randn(1000),
    'B': np.random.randn(1000) + 2,
    'C': np.random.randn(1000) - 2
})

df.plot(kind='hist', alpha=0.5, bins=30)
plt.title('Multiple Distributions')
plt.show()

# Separate subplots
df.plot(kind='hist', subplots=True, layout=(1, 3), figsize=(15, 4))
plt.show()

# With density curve
ax = data.plot(kind='hist', bins=50, alpha=0.5, density=True)
data.plot(kind='kde', ax=ax, secondary_y=False)
plt.show()
```

### Box Plots

```python
# Sample data
df = pd.DataFrame({
    'A': np.random.randn(100),
    'B': np.random.randn(100) * 2,
    'C': np.random.randn(100) + 1
})

# Basic box plot
df.plot(kind='box')
plt.title('Box Plot')
plt.ylabel('Value')
plt.show()

# Horizontal box plot
df.plot(kind='box', vert=False)
plt.xlabel('Value')
plt.show()

# Grouped box plot
data = pd.DataFrame({
    'value': np.concatenate([
        np.random.randn(50),
        np.random.randn(50) + 2,
        np.random.randn(50) + 4
    ]),
    'category': ['A'] * 50 + ['B'] * 50 + ['C'] * 50
})

data.boxplot(column='value', by='category')
plt.title('Value by Category')
plt.suptitle('')  # Remove default title
plt.show()
```

### Scatter Plots

```python
# Sample data
df = pd.DataFrame({
    'x': np.random.randn(100),
    'y': np.random.randn(100),
    'size': np.random.randint(10, 100, 100),
    'color': np.random.randint(0, 100, 100)
})

# Basic scatter plot
df.plot(kind='scatter', x='x', y='y')
plt.title('Scatter Plot')
plt.show()

# With varying size
df.plot(kind='scatter', x='x', y='y', s=df['size'])
plt.title('Scatter with Size')
plt.show()

# With color mapping
df.plot(kind='scatter', x='x', y='y', c='color', cmap='viridis', s=50)
plt.title('Scatter with Color')
plt.colorbar()
plt.show()

# Multiple scatter plots
fig, ax = plt.subplots()
df.plot(kind='scatter', x='x', y='y', color='blue', label='Group 1', ax=ax)
df2 = pd.DataFrame({
    'x': np.random.randn(100) + 2,
    'y': np.random.randn(100) + 2
})
df2.plot(kind='scatter', x='x', y='y', color='red', label='Group 2', ax=ax)
plt.title('Multiple Scatter Plots')
plt.show()
```

### Area Plots

```python
# Sample data
df = pd.DataFrame({
    'A': np.random.randint(1, 10, 10),
    'B': np.random.randint(1, 10, 10),
    'C': np.random.randint(1, 10, 10)
})

# Area plot
df.plot(kind='area', alpha=0.4)
plt.title('Area Plot')
plt.ylabel('Value')
plt.show()

# Stacked area (default)
df.plot(kind='area', stacked=True, alpha=0.4)
plt.title('Stacked Area Plot')
plt.show()

# Non-stacked area
df.plot(kind='area', stacked=False, alpha=0.4)
plt.title('Non-Stacked Area Plot')
plt.show()
```

### Pie Charts

```python
# Sample data
data = pd.Series([30, 25, 20, 15, 10], 
                 index=['A', 'B', 'C', 'D', 'E'])

# Basic pie chart
data.plot(kind='pie')
plt.title('Pie Chart')
plt.ylabel('')  # Remove y-label
plt.show()

# Customized pie chart
data.plot(
    kind='pie',
    autopct='%1.1f%%',  # Show percentages
    startangle=90,
    explode=[0.1, 0, 0, 0, 0],  # Explode first slice
    shadow=True,
    figsize=(8, 8)
)
plt.title('Sales Distribution')
plt.ylabel('')
plt.show()

# Multiple pie charts (subplots)
df = pd.DataFrame({
    'Q1': [30, 25, 20, 15, 10],
    'Q2': [28, 27, 22, 13, 10]
}, index=['A', 'B', 'C', 'D', 'E'])

df.plot(kind='pie', subplots=True, figsize=(12, 6), 
        autopct='%1.1f%%', legend=False)
plt.show()
```

### Density Plots (KDE)

```python
# Sample data
data = pd.Series(np.random.randn(1000))

# Kernel Density Estimate
data.plot(kind='kde')
plt.title('Density Plot')
plt.xlabel('Value')
plt.ylabel('Density')
plt.show()

# Multiple densities
df = pd.DataFrame({
    'A': np.random.randn(1000),
    'B': np.random.randn(1000) + 2,
    'C': np.random.randn(1000) - 2
})

df.plot(kind='kde', alpha=0.7)
plt.title('Multiple Density Plots')
plt.xlabel('Value')
plt.show()

# Density with histogram
ax = df['A'].plot(kind='hist', bins=50, alpha=0.5, density=True)
df['A'].plot(kind='kde', ax=ax, color='red', linewidth=2)
plt.title('Histogram with Density')
plt.show()
```

### Hexagonal Bin Plots

```python
# Large dataset
df = pd.DataFrame({
    'x': np.random.randn(10000),
    'y': np.random.randn(10000)
})

# Hexbin plot - good for large datasets
df.plot(kind='hexbin', x='x', y='y', gridsize=25)
plt.title('Hexbin Plot')
plt.show()

# With color scale
df.plot(kind='hexbin', x='x', y='y', gridsize=25, 
        cmap='YlOrRd', colorbar=True)
plt.show()
```

### Customization with Matplotlib

```python
# Get axes object for customization
ax = df.plot()

# Customize using Matplotlib
ax.set_xlabel('Custom X Label', fontsize=12)
ax.set_ylabel('Custom Y Label', fontsize=12)
ax.set_title('Custom Title', fontsize=14, fontweight='bold')
ax.legend(['Series 1', 'Series 2'], loc='best')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 100)
ax.set_ylim(-5, 5)

plt.show()

# Multiple subplots with custom layout
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

df['A'].plot(ax=axes[0, 0], title='Line Plot')
df['A'].plot(kind='hist', ax=axes[0, 1], bins=30, title='Histogram')
df.plot(kind='box', ax=axes[1, 0], title='Box Plot')
df.plot(kind='kde', ax=axes[1, 1], title='Density Plot')

plt.tight_layout()
plt.show()
```

### Styling

```python
# Use Matplotlib styles
plt.style.use('seaborn-v0_8')  # or 'ggplot', 'fivethirtyeight', etc.
df.plot()
plt.show()

# Custom color palette
colors = ['#FF6B6B', '#4ECDC4', '#45B7D1']
df.plot(color=colors)
plt.show()

# Set default parameters
plt.rcParams['figure.figsize'] = (12, 6)
plt.rcParams['font.size'] = 11
plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.3
```

### Time Series Plotting

```python
# Sample time series
dates = pd.date_range('2024-01-01', periods=365)
ts = pd.Series(np.random.randn(365).cumsum(), index=dates)

# Basic time series plot
ts.plot()
plt.title('Time Series')
plt.ylabel('Value')
plt.show()

# With markers
ts.plot(marker='o', markersize=2)
plt.show()

# With filled area
ax = ts.plot(color='blue', alpha=0.3)
ax.fill_between(ts.index, 0, ts.values, alpha=0.2, color='blue')
plt.title('Time Series with Fill')
plt.show()

# Multiple time series with different y-axes
fig, ax1 = plt.subplots()

ax1.set_xlabel('Date')
ax1.set_ylabel('Series 1', color='blue')
ts.plot(ax=ax1, color='blue')
ax1.tick_params(axis='y', labelcolor='blue')

ax2 = ax1.twinx()
ax2.set_ylabel('Series 2', color='red')
(ts * 2 + 10).plot(ax=ax2, color='red')
ax2.tick_params(axis='y', labelcolor='red')

plt.title('Dual Y-Axis Plot')
plt.show()
```

### Practical Examples

#### Example 1: Sales Dashboard

```python
# Sample sales data
np.random.seed(42)
dates = pd.date_range('2023-01-01', '2024-12-31', freq='M')
sales_data = pd.DataFrame({
    'month': dates,
    'product_A': np.random.randint(1000, 5000, len(dates)),
    'product_B': np.random.randint(1500, 4500, len(dates)),
    'product_C': np.random.randint(800, 3000, len(dates))
}).set_index('month')

# Create dashboard
fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# Total sales over time
sales_data.sum(axis=1).plot(ax=axes[0, 0], marker='o')
axes[0, 0].set_title('Total Monthly Sales', fontsize=12, fontweight='bold')
axes[0, 0].set_ylabel('Sales ($)')

# Product comparison
sales_data.plot(ax=axes[0, 1])
axes[0, 1].set_title('Sales by Product', fontsize=12, fontweight='bold')
axes[0, 1].set_ylabel('Sales ($)')

# Distribution
sales_data.plot(kind='box', ax=axes[1, 0])
axes[1, 0].set_title('Sales Distribution', fontsize=12, fontweight='bold')
axes[1, 0].set_ylabel('Sales ($)')

# Market share
sales_data.sum().plot(kind='pie', ax=axes[1, 1], autopct='%1.1f%%')
axes[1, 1].set_title('Market Share', fontsize=12, fontweight='bold')
axes[1, 1].set_ylabel('')

plt.tight_layout()
plt.show()
```

#### Example 2: Stock Price Analysis

```python
# Sample stock data
dates = pd.date_range('2024-01-01', periods=252, freq='B')
stock_data = pd.DataFrame({
    'price': 100 + np.random.randn(252).cumsum(),
    'volume': np.random.randint(1000000, 5000000, 252)
}, index=dates)

# Calculate moving averages
stock_data['MA20'] = stock_data['price'].rolling(20).mean()
stock_data['MA50'] = stock_data['price'].rolling(50).mean()

# Create plot
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), 
                               gridspec_kw={'height_ratios': [3, 1]})

# Price and moving averages
stock_data[['price', 'MA20', 'MA50']].plot(ax=ax1)
ax1.set_title('Stock Price with Moving Averages', fontsize=14, fontweight='bold')
ax1.set_ylabel('Price ($)')
ax1.legend(['Price', '20-day MA', '50-day MA'])
ax1.grid(True, alpha=0.3)

# Volume
stock_data['volume'].plot(kind='bar', ax=ax2, color='gray', alpha=0.5)
ax2.set_title('Trading Volume', fontsize=12)
ax2.set_ylabel('Volume')
ax2.set_xlabel('Date')

plt.tight_layout()
plt.show()
```

### Saving Figures

```python
# Save to file
fig, ax = plt.subplots()
df.plot(ax=ax)
plt.savefig('plot.png', dpi=300, bbox_inches='tight')
plt.savefig('plot.pdf')  # Save as PDF
plt.savefig('plot.svg')  # Save as SVG

# With transparent background
plt.savefig('plot.png', transparent=True, bbox_inches='tight')
```

### Summary

- Pandas provides convenient plotting via `.plot()` method
- Built on Matplotlib for advanced customization
- Support for line, bar, scatter, histogram, box, pie, area, and more
- Use `kind` parameter or `.plot.kind()` methods
- Customize with Matplotlib's axes methods
- Save plots with `plt.savefig()`

### Key Takeaways

1. Pandas plotting is quick for exploratory analysis
2. Use `kind` parameter to specify plot type
3. Combine multiple plots in subplots for dashboards
4. Access underlying Matplotlib axes for customization
5. Time series plotting is particularly well-supported
6. Use appropriate chart types for your data

---

**Practice Exercise:**

1. Load a dataset and create a line plot of a numeric column over time
2. Create a bar chart comparing categories
3. Generate a histogram showing distribution
4. Make a scatter plot with color-coded points
5. Create a dashboard with 4 subplots showing different views
6. Customize colors, labels, and styling
7. Save the final plot as a high-resolution image
