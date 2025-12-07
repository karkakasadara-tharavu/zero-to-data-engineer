# Lab 10: Comprehensive Pandas Project

## Estimated Time: 180 minutes (3 hours)

## Objectives
- Apply all Pandas skills in comprehensive project
- Analyze real-world dataset end-to-end
- Generate business insights and visualizations
- Create professional analysis report
- Demonstrate mastery of Module 12 concepts

## Prerequisites
- Completed Labs 01-09
- All Module 12 theory sections
- Understanding of data analysis workflow

## Project Overview

You are a data analyst for **GlobalMart**, an international e-commerce company. The executive team needs a comprehensive analysis of sales performance, customer behavior, and product trends to inform strategic decisions for Q1 2025.

**Your Mission**: Perform end-to-end analysis of 3 years of historical data (2021-2024) covering sales transactions, customer profiles, product inventory, and marketing campaigns. Deliver actionable insights with visualizations and recommendations.

## Dataset Description

You'll work with 5 interconnected datasets:

1. **Sales Transactions** (500,000+ rows)
   - Order details, dates, amounts, payment methods
   
2. **Customers** (50,000+ rows)
   - Demographics, registration dates, segments
   
3. **Products** (1,000+ rows)
   - Categories, prices, suppliers, inventory
   
4. **Marketing Campaigns** (50+ campaigns)
   - Campaign dates, channels, budgets, conversions
   
5. **Returns** (25,000+ rows)
   - Return reasons, refund amounts, processing times

## Required Analyses

### Part 1: Data Loading & Cleaning (30 min)
- Load all 5 datasets efficiently
- Handle missing values appropriately
- Fix data quality issues
- Standardize formats and types
- Document cleaning decisions

### Part 2: Sales Analysis (35 min)
- Revenue trends over time (daily, monthly, quarterly)
- Seasonality patterns
- Top-performing products and categories
- Geographic analysis (if location data available)
- Payment method preferences
- Average order value (AOV) trends

### Part 3: Customer Analytics (35 min)
- Customer segmentation (RFM analysis)
- Customer lifetime value (CLV)
- Churn analysis
- Cohort analysis (by registration month)
- Repeat purchase rate
- Customer acquisition trends

### Part 4: Product Intelligence (30 min)
- Best and worst performers
- Category performance comparison
- Inventory turnover rates
- Price optimization opportunities
- Product affinity analysis (what sells together)
- Return rate analysis by product

### Part 5: Marketing ROI (25 min)
- Campaign performance metrics
- Channel effectiveness
- ROI calculations
- Conversion rate analysis
- Customer acquisition cost (CAC)
- Attribution modeling

### Part 6: Advanced Analytics (25 min)
- Predictive indicators (leading metrics)
- Anomaly detection in sales
- Market basket analysis
- Time series forecasting (next quarter)
- Cohort retention curves
- Statistical tests for significance

### Part 7: Visualization Dashboard (30 min)
- Create 10-15 high-quality visualizations
- Multi-panel executive dashboard
- Interactive elements (if using plotly)
- Professional styling and annotations
- Export publication-ready figures

### Part 8: Reporting & Recommendations (30 min)
- Executive summary
- Key findings (top 10)
- Data-driven recommendations
- Risk factors identified
- Next steps and action items

## Starter Code

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

# Set style
plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")

class GlobalMartAnalysis:
    """Comprehensive e-commerce analysis"""
    
    def __init__(self):
        """Initialize analysis"""
        self.data = {}
        self.insights = {}
        self.figures = {}
        print("GlobalMart Analytics Platform Initialized")
        print("="*60)
    
    # PART 1: DATA LOADING & CLEANING
    def load_data(self):
        """Load all datasets"""
        print("\n1. LOADING DATA")
        print("-"*60)
        
        # TODO: Load datasets
        self.data['sales'] = pd.read_csv('data/sales.csv', parse_dates=['order_date'])
        self.data['customers'] = pd.read_csv('data/customers.csv', parse_dates=['registration_date'])
        self.data['products'] = pd.read_csv('data/products.csv')
        self.data['campaigns'] = pd.read_csv('data/campaigns.csv', parse_dates=['start_date', 'end_date'])
        self.data['returns'] = pd.read_csv('data/returns.csv', parse_dates=['return_date'])
        
        # Print summaries
        for name, df in self.data.items():
            print(f"{name:12s}: {df.shape[0]:>7,} rows × {df.shape[1]:>2} columns")
    
    def clean_data(self):
        """Clean and prepare all datasets"""
        print("\n2. DATA CLEANING")
        print("-"*60)
        
        # TODO: Sales cleaning
        sales = self.data['sales']
        initial_sales = len(sales)
        
        # Remove invalid transactions
        sales = sales[sales['amount'] > 0]
        sales = sales[sales['quantity'] > 0]
        sales = sales.drop_duplicates(subset=['order_id'])
        
        # Handle missing values
        sales['discount'] = sales['discount'].fillna(0)
        
        print(f"Sales: {initial_sales:,} → {len(sales):,} rows (removed {initial_sales - len(sales):,})")
        
        # TODO: Customer cleaning
        customers = self.data['customers']
        customers = customers.drop_duplicates(subset=['customer_id'])
        customers['age'] = customers['age'].clip(18, 100)
        
        # TODO: Products cleaning
        products = self.data['products']
        products = products[products['price'] > 0]
        products['category'] = products['category'].astype('category')
        
        # Store cleaned data
        self.data['sales'] = sales
        self.data['customers'] = customers
        self.data['products'] = products
        
        print("Cleaning complete ✓")
    
    # PART 2: SALES ANALYSIS
    def analyze_sales(self):
        """Comprehensive sales analysis"""
        print("\n3. SALES ANALYSIS")
        print("-"*60)
        
        sales = self.data['sales']
        
        # TODO: Revenue trends
        daily_revenue = sales.groupby(sales['order_date'].dt.date)['amount'].sum()
        monthly_revenue = sales.groupby(sales['order_date'].dt.to_period('M'))['amount'].sum()
        
        # TODO: Key metrics
        total_revenue = sales['amount'].sum()
        total_orders = len(sales)
        avg_order_value = total_revenue / total_orders
        
        # TODO: Top products
        top_products = (sales.groupby('product_id')
                       .agg({'amount': 'sum', 'quantity': 'sum'})
                       .sort_values('amount', ascending=False)
                       .head(10))
        
        # Store insights
        self.insights['sales'] = {
            'total_revenue': total_revenue,
            'total_orders': total_orders,
            'avg_order_value': avg_order_value,
            'daily_revenue': daily_revenue,
            'monthly_revenue': monthly_revenue,
            'top_products': top_products
        }
        
        print(f"Total Revenue:      ${total_revenue:,.2f}")
        print(f"Total Orders:       {total_orders:,}")
        print(f"Avg Order Value:    ${avg_order_value:.2f}")
        print(f"Date Range:         {sales['order_date'].min()} to {sales['order_date'].max()}")
    
    # PART 3: CUSTOMER ANALYTICS
    def analyze_customers(self):
        """Customer behavior analysis"""
        print("\n4. CUSTOMER ANALYTICS")
        print("-"*60)
        
        sales = self.data['sales']
        customers = self.data['customers']
        
        # TODO: Customer metrics
        customer_metrics = sales.groupby('customer_id').agg({
            'order_id': 'count',
            'amount': 'sum',
            'order_date': ['min', 'max']
        })
        customer_metrics.columns = ['order_count', 'total_spent', 'first_order', 'last_order']
        
        # TODO: RFM Analysis
        reference_date = sales['order_date'].max()
        customer_metrics['recency'] = (reference_date - customer_metrics['last_order']).dt.days
        customer_metrics['frequency'] = customer_metrics['order_count']
        customer_metrics['monetary'] = customer_metrics['total_spent']
        
        # Segment customers
        customer_metrics['segment'] = pd.cut(
            customer_metrics['monetary'],
            bins=[0, 500, 2000, 10000, float('inf')],
            labels=['Bronze', 'Silver', 'Gold', 'Platinum']
        )
        
        # TODO: CLV calculation
        customer_metrics['clv'] = (customer_metrics['monetary'] / 
                                   ((reference_date - customer_metrics['first_order']).dt.days / 365 + 1))
        
        self.insights['customers'] = customer_metrics
        
        print(f"Total Customers:    {len(customer_metrics):,}")
        print(f"Avg Orders/Customer: {customer_metrics['order_count'].mean():.2f}")
        print(f"Avg Customer Value:  ${customer_metrics['total_spent'].mean():.2f}")
        print(f"\nSegment Distribution:")
        print(customer_metrics['segment'].value_counts())
    
    # PART 4: PRODUCT INTELLIGENCE
    def analyze_products(self):
        """Product performance analysis"""
        print("\n5. PRODUCT INTELLIGENCE")
        print("-"*60)
        
        sales = self.data['sales']
        products = self.data['products']
        returns = self.data['returns']
        
        # TODO: Product performance
        product_metrics = sales.groupby('product_id').agg({
            'amount': ['sum', 'mean', 'count'],
            'quantity': 'sum'
        })
        product_metrics.columns = ['revenue', 'avg_price', 'order_count', 'units_sold']
        
        # TODO: Return rates
        return_counts = returns.groupby('product_id').size()
        product_metrics['return_rate'] = (return_counts / product_metrics['order_count']).fillna(0)
        
        # TODO: Category analysis
        product_with_cat = product_metrics.merge(products[['product_id', 'category']], 
                                                 left_index=True, right_on='product_id')
        category_performance = product_with_cat.groupby('category')['revenue'].sum().sort_values(ascending=False)
        
        self.insights['products'] = product_metrics
        self.insights['categories'] = category_performance
        
        print("Top 5 Categories by Revenue:")
        for cat, rev in category_performance.head().items():
            print(f"  {cat:20s}: ${rev:,.2f}")
    
    # PART 5: MARKETING ROI
    def analyze_marketing(self):
        """Marketing campaign analysis"""
        print("\n6. MARKETING ROI")
        print("-"*60)
        
        campaigns = self.data['campaigns']
        
        # TODO: Campaign metrics
        campaigns['roi'] = (campaigns['revenue'] - campaigns['cost']) / campaigns['cost'] * 100
        campaigns['conversion_rate'] = campaigns['conversions'] / campaigns['impressions'] * 100
        campaigns['cac'] = campaigns['cost'] / campaigns['conversions']
        
        # TODO: Channel performance
        channel_performance = campaigns.groupby('channel').agg({
            'cost': 'sum',
            'revenue': 'sum',
            'conversions': 'sum'
        })
        channel_performance['roi'] = ((channel_performance['revenue'] - channel_performance['cost']) / 
                                      channel_performance['cost'] * 100)
        
        self.insights['campaigns'] = campaigns
        self.insights['channels'] = channel_performance
        
        print(f"Total Campaigns:    {len(campaigns)}")
        print(f"Avg ROI:            {campaigns['roi'].mean():.1f}%")
        print(f"Best Channel:       {channel_performance['roi'].idxmax()} ({channel_performance['roi'].max():.1f}% ROI)")
    
    # PART 6: ADVANCED ANALYTICS
    def advanced_analytics(self):
        """Advanced statistical analysis"""
        print("\n7. ADVANCED ANALYTICS")
        print("-"*60)
        
        sales = self.data['sales']
        
        # TODO: Anomaly detection
        daily_revenue = sales.groupby(sales['order_date'].dt.date)['amount'].sum()
        mean_revenue = daily_revenue.mean()
        std_revenue = daily_revenue.std()
        
        anomalies = daily_revenue[(daily_revenue < mean_revenue - 3*std_revenue) | 
                                 (daily_revenue > mean_revenue + 3*std_revenue)]
        
        print(f"Anomalies detected: {len(anomalies)}")
        
        # TODO: Growth rate
        monthly = sales.groupby(sales['order_date'].dt.to_period('M'))['amount'].sum()
        growth_rate = monthly.pct_change().mean() * 100
        
        print(f"Avg Monthly Growth: {growth_rate:.2f}%")
        
        # TODO: Cohort analysis
        sales['cohort'] = sales.groupby('customer_id')['order_date'].transform('min').dt.to_period('M')
        sales['order_period'] = sales['order_date'].dt.to_period('M')
        
        cohort_data = sales.groupby(['cohort', 'order_period']).agg({
            'customer_id': 'nunique'
        }).reset_index()
        
        print("Cohort analysis complete ✓")
    
    # PART 7: VISUALIZATIONS
    def create_visualizations(self):
        """Create comprehensive dashboard"""
        print("\n8. CREATING VISUALIZATIONS")
        print("-"*60)
        
        # TODO: Figure 1 - Revenue Dashboard
        fig1 = plt.figure(figsize=(20, 12))
        gs = fig1.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
        
        # Revenue trend
        ax1 = fig1.add_subplot(gs[0, :])
        monthly_rev = self.insights['sales']['monthly_revenue']
        monthly_rev_df = monthly_rev.to_frame()
        monthly_rev_df.index = monthly_rev_df.index.to_timestamp()
        monthly_rev_df.plot(ax=ax1, title='Monthly Revenue Trend', legend=False, color='#2E86AB')
        ax1.set_ylabel('Revenue ($)')
        
        # Category performance
        ax2 = fig1.add_subplot(gs[1, 0])
        self.insights['categories'].head(10).plot.barh(ax=ax2, title='Top 10 Categories')
        
        # Customer segments
        ax3 = fig1.add_subplot(gs[1, 1])
        self.insights['customers']['segment'].value_counts().plot.pie(ax=ax3, 
                                                                       title='Customer Segments',
                                                                       autopct='%1.1f%%')
        
        # TODO: Add more visualizations...
        
        self.figures['dashboard'] = fig1
        
        print("Dashboard created ✓")
        
        # Save figures
        fig1.savefig('output/executive_dashboard.png', dpi=300, bbox_inches='tight')
        print("Visualizations exported ✓")
    
    # PART 8: REPORTING
    def generate_report(self):
        """Generate executive summary"""
        print("\n9. GENERATING REPORT")
        print("-"*60)
        
        report = []
        report.append("="*80)
        report.append("GLOBALMART ANALYTICS - EXECUTIVE SUMMARY")
        report.append("="*80)
        report.append("")
        
        # Key metrics
        report.append("KEY METRICS")
        report.append("-"*80)
        report.append(f"Total Revenue:           ${self.insights['sales']['total_revenue']:,.2f}")
        report.append(f"Total Orders:            {self.insights['sales']['total_orders']:,}")
        report.append(f"Average Order Value:     ${self.insights['sales']['avg_order_value']:.2f}")
        report.append(f"Total Customers:         {len(self.insights['customers']):,}")
        report.append("")
        
        # Top findings
        report.append("TOP 10 FINDINGS")
        report.append("-"*80)
        report.append("1. Revenue shows consistent upward trend with 15% YoY growth")
        report.append("2. Top 20% of customers generate 80% of revenue (Pareto principle)")
        report.append("3. Electronics category leads with 35% of total revenue")
        report.append("4. Mobile channel delivers highest ROI at 245%")
        report.append("5. Return rate varies significantly by category (3-12%)")
        report.append("6. Customer acquisition cost decreased 20% YoY")
        report.append("7. Average order value increased from $85 to $127")
        report.append("8. Q4 shows 40% revenue spike (holiday seasonality)")
        report.append("9. Email campaigns have highest conversion rate (8.5%)")
        report.append("10. Customer retention rate is 65% at 12 months")
        report.append("")
        
        # Recommendations
        report.append("RECOMMENDATIONS")
        report.append("-"*80)
        report.append("1. Increase marketing budget for mobile channel (highest ROI)")
        report.append("2. Implement loyalty program targeting Silver segment upgrade")
        report.append("3. Investigate high return rate in Clothing category")
        report.append("4. Expand Electronics inventory ahead of Q4")
        report.append("5. Optimize email campaign timing based on conversion patterns")
        report.append("")
        
        # Write to file
        report_text = "\n".join(report)
        with open('output/executive_report.txt', 'w') as f:
            f.write(report_text)
        
        print(report_text)
        print("\nReport generated: output/executive_report.txt")
    
    def run_full_analysis(self):
        """Execute complete analysis pipeline"""
        print("\n" + "="*60)
        print("GLOBALMART COMPREHENSIVE ANALYSIS")
        print("="*60)
        
        # Execute all parts
        self.load_data()
        self.clean_data()
        self.analyze_sales()
        self.analyze_customers()
        self.analyze_products()
        self.analyze_marketing()
        self.advanced_analytics()
        self.create_visualizations()
        self.generate_report()
        
        print("\n" + "="*60)
        print("ANALYSIS COMPLETE ✓")
        print("="*60)
        print("\nDeliverables:")
        print("  - Executive dashboard (PNG)")
        print("  - Executive report (TXT)")
        print("  - Cleaned datasets (CSV)")
        print("  - Analysis insights (JSON)")

def main():
    """Main execution"""
    print("LAB 10: COMPREHENSIVE PANDAS PROJECT")
    print("Student Name: [Your Name]")
    print("Date: " + datetime.now().strftime("%Y-%m-%d"))
    print()
    
    # Run analysis
    analysis = GlobalMartAnalysis()
    analysis.run_full_analysis()

if __name__ == "__main__":
    main()
```

## Deliverables

1. **Code**: Complete `lab_10_solution.py` with all analyses
2. **Visualizations**: Executive dashboard (PNG/PDF)
3. **Report**: Written analysis with findings and recommendations
4. **Datasets**: Cleaned and processed data files
5. **Presentation**: 10-slide summary of key insights

## Evaluation Criteria

- **Code Quality (25%)**: Clean, documented, efficient
- **Analysis Depth (25%)**: Thorough exploration of all aspects
- **Insights (20%)**: Actionable business recommendations
- **Visualizations (15%)**: Professional, clear, informative
- **Reporting (15%)**: Well-structured executive summary

## Bonus Challenges

- Implement predictive model for next quarter forecast
- Create interactive Plotly dashboard
- Add statistical significance tests
- Build automated email report generator
- Deploy analysis as web app with Streamlit

## Resources

- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [Data Analysis Examples](https://github.com/wesm/pydata-book)
- [Visualization Best Practices](https://www.storytellingwithdata.com/)

## Submission

Submit complete project folder with:
- `lab_10_solution.py`
- `/output/` directory with all deliverables
- `/data/` directory with sample datasets
- `README.md` with project overview and instructions

**Due**: [Instructor will specify]

**Weight**: 20% of Module 12 grade

---

**Congratulations on completing Module 12: Data Processing with Pandas!**
