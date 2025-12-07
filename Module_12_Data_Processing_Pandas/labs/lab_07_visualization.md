# Lab 07: Data Visualization with Pandas

## Estimated Time: 90 minutes

## Objectives
- Create visualizations using Pandas plotting methods
- Customize plot appearance and styling
- Build dashboards with multiple subplots
- Visualize different data types effectively
- Export publication-ready figures

## Prerequisites
- Completed Labs 01-06
- Understanding of data visualization principles
- Basic Matplotlib knowledge helpful

## Background

Visualizing data is essential for analysis and presentation. You'll create charts for sales reports, statistical analysis, and executive dashboards using Pandas' built-in visualization capabilities.

## Tasks

### Task 1: Basic Plots (20 min)
- Line plots for trends
- Bar charts for comparisons
- Scatter plots for correlations
- Histogram for distributions

### Task 2: Advanced Charts (25 min)
- Box plots for statistical summaries
- Density plots
- Area charts
- Pie charts for proportions

### Task 3: Multi-Plot Dashboards (25 min)
- Subplots layout
- Shared axes
- Combined plot types
- Dashboard with 4-6 charts

### Task 4: Customization (20 min)
- Colors, styles, and themes
- Annotations and labels
- Grid customization
- Export high-resolution figures

## Starter Code

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

plt.style.use('seaborn-v0_8-darkgrid')

def create_visualization_datasets():
    """Create sample datasets for visualization"""
    # Sales data
    dates = pd.date_range('2024-01-01', periods=365, freq='D')
    sales_df = pd.DataFrame({
        'date': dates,
        'revenue': 10000 + np.random.randn(365).cumsum() * 500,
        'orders': np.random.randint(50, 200, 365),
        'customers': np.random.randint(30, 150, 365)
    })
    sales_df.set_index('date', inplace=True)
    
    # Category performance
    categories = ['Electronics', 'Clothing', 'Books', 'Home', 'Sports']
    category_df = pd.DataFrame({
        'category': categories,
        'revenue': np.random.randint(50000, 200000, 5),
        'profit_margin': np.random.uniform(0.15, 0.35, 5),
        'items_sold': np.random.randint(500, 2000, 5)
    })
    
    # Customer segments
    np.random.seed(42)
    segments_df = pd.DataFrame({
        'age': np.random.randint(18, 70, 1000),
        'income': np.random.randint(30000, 150000, 1000),
        'spending': np.random.randint(100, 5000, 1000),
        'satisfaction': np.random.uniform(1, 5, 1000)
    })
    
    return sales_df, category_df, segments_df

# Task 1: Basic Plots
def create_basic_plots(sales_df):
    """Create basic visualization types"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    
    # TODO: Line plot - Revenue trend
    sales_df['revenue'].plot(
        ax=axes[0, 0],
        title='Daily Revenue Trend',
        ylabel='Revenue ($)',
        color='blue'
    )
    
    # TODO: Bar chart - Monthly orders
    monthly_orders = sales_df['orders'].resample('M').sum()
    monthly_orders.plot.bar(
        ax=axes[0, 1],
        title='Monthly Orders',
        ylabel='Total Orders',
        color='green'
    )
    
    # TODO: Scatter plot - Orders vs Revenue
    sales_df.plot.scatter(
        x='orders',
        y='revenue',
        ax=axes[1, 0],
        title='Orders vs Revenue',
        alpha=0.5
    )
    
    # TODO: Histogram - Customer distribution
    sales_df['customers'].plot.hist(
        ax=axes[1, 1],
        bins=30,
        title='Customer Count Distribution',
        xlabel='Customers',
        color='orange'
    )
    
    plt.tight_layout()
    return fig

# Task 2: Advanced Charts
def create_advanced_plots(sales_df, category_df):
    """Create advanced visualization types"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    
    # TODO: Box plot - Revenue by quarter
    sales_df['quarter'] = sales_df.index.quarter
    sales_df.boxplot(column='revenue', by='quarter', ax=axes[0, 0])
    axes[0, 0].set_title('Revenue Distribution by Quarter')
    
    # TODO: Density plot
    sales_df['revenue'].plot.kde(
        ax=axes[0, 1],
        title='Revenue Density Distribution'
    )
    
    # TODO: Area chart - Cumulative metrics
    cumulative = sales_df[['revenue', 'orders']].cumsum()
    cumulative.plot.area(
        ax=axes[1, 0],
        title='Cumulative Growth',
        alpha=0.7
    )
    
    # TODO: Pie chart - Category revenue
    category_df.set_index('category')['revenue'].plot.pie(
        ax=axes[1, 1],
        title='Revenue by Category',
        autopct='%1.1f%%'
    )
    
    plt.tight_layout()
    return fig

# Task 3: Dashboard
def create_dashboard(sales_df, category_df):
    """Create comprehensive dashboard"""
    fig = plt.figure(figsize=(20, 12))
    gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
    
    # TODO: Main trend (large)
    ax1 = fig.add_subplot(gs[0, :])
    sales_df['revenue'].rolling(7).mean().plot(
        ax=ax1,
        title='7-Day Moving Average Revenue',
        color='blue',
        linewidth=2
    )
    
    # TODO: Category comparison
    ax2 = fig.add_subplot(gs[1, 0])
    category_df.plot.bar(
        x='category',
        y='revenue',
        ax=ax2,
        title='Category Revenue',
        legend=False
    )
    
    # TODO: Profit margins
    ax3 = fig.add_subplot(gs[1, 1])
    category_df.plot.barh(
        x='category',
        y='profit_margin',
        ax=ax3,
        title='Profit Margins',
        legend=False,
        color='green'
    )
    
    # TODO: Items sold
    ax4 = fig.add_subplot(gs[1, 2])
    category_df.set_index('category')['items_sold'].plot.pie(
        ax=ax4,
        title='Items Sold Distribution',
        autopct='%1.0f%%'
    )
    
    # TODO: Revenue distribution
    ax5 = fig.add_subplot(gs[2, 0])
    sales_df['revenue'].plot.hist(
        ax=ax5,
        bins=50,
        title='Revenue Distribution',
        alpha=0.7
    )
    
    # TODO: Orders trend
    ax6 = fig.add_subplot(gs[2, 1:])
    sales_df['orders'].resample('W').mean().plot(
        ax=ax6,
        title='Weekly Average Orders',
        color='orange',
        marker='o'
    )
    
    return fig

# Task 4: Customization
def customize_plot(df):
    """Create highly customized plot"""
    fig, ax = plt.subplots(figsize=(14, 8))
    
    # TODO: Plot with custom styling
    df['revenue'].plot(
        ax=ax,
        color='#2E86AB',
        linewidth=2.5,
        label='Daily Revenue'
    )
    
    # TODO: Add moving average
    df['revenue'].rolling(30).mean().plot(
        ax=ax,
        color='#A23B72',
        linewidth=2,
        linestyle='--',
        label='30-Day MA'
    )
    
    # TODO: Customize appearance
    ax.set_title('Revenue Analysis Dashboard', 
                 fontsize=16, fontweight='bold', pad=20)
    ax.set_xlabel('Date', fontsize=12, fontweight='bold')
    ax.set_ylabel('Revenue ($)', fontsize=12, fontweight='bold')
    ax.legend(loc='upper left', fontsize=11, framealpha=0.9)
    ax.grid(True, alpha=0.3, linestyle=':', linewidth=0.8)
    
    # TODO: Add annotations
    max_revenue = df['revenue'].max()
    max_date = df['revenue'].idxmax()
    ax.annotate(f'Peak: ${max_revenue:,.0f}',
                xy=(max_date, max_revenue),
                xytext=(10, 20), textcoords='offset points',
                bbox=dict(boxstyle='round,pad=0.5', fc='yellow', alpha=0.7),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0'))
    
    plt.tight_layout()
    return fig

def export_figures(figures, filenames):
    """Export figures in multiple formats"""
    for fig, filename in zip(figures, filenames):
        # TODO: Save as PNG (high resolution)
        fig.savefig(f'{filename}.png', dpi=300, bbox_inches='tight')
        
        # TODO: Save as PDF (vector)
        fig.savefig(f'{filename}.pdf', bbox_inches='tight')
        
        print(f"Exported: {filename}")

def main():
    """Main execution"""
    print("LAB 07: DATA VISUALIZATION")
    
    # Load data
    sales_df, category_df, segments_df = create_visualization_datasets()
    
    # Create visualizations
    basic_fig = create_basic_plots(sales_df)
    advanced_fig = create_advanced_plots(sales_df, category_df)
    dashboard_fig = create_dashboard(sales_df, category_df)
    custom_fig = customize_plot(sales_df)
    
    # Export
    figures = [basic_fig, advanced_fig, dashboard_fig, custom_fig]
    names = ['basic_plots', 'advanced_plots', 'dashboard', 'custom_plot']
    export_figures(figures, names)
    
    plt.show()
    print("\nAll visualizations created and exported!")

if __name__ == "__main__":
    main()
```

## Deliverables
- Visualization script with all plot types
- Dashboard with 6+ charts
- High-resolution exported figures (PNG, PDF)
- Styled and annotated visualizations

## Bonus Challenges
- Interactive plots with plotly
- Animated time series
- Heatmap correlations
- 3D surface plots
- Custom color palettes

## Common Pitfalls
- Not setting figure size appropriately
- Overlapping labels in dense plots
- Poor color choices for accessibility
- Missing axis labels or titles
- Not using tight_layout()

## Resources
- [Pandas Visualization](https://pandas.pydata.org/docs/user_guide/visualization.html)
- [Matplotlib Gallery](https://matplotlib.org/stable/gallery/index.html)
- [Color Brewer](https://colorbrewer2.org/)

## Submission
Submit `lab_07_solution.py` with complete visualization implementations and exported figures.
