# Section 10: Practice Project - Sales Analysis Report

**Estimated Time**: 8 hours  
**Difficulty**: ⭐⭐⭐⭐ Comprehensive Challenge  

---

## 🎯 Project Objectives

Build a **comprehensive sales analysis report** that demonstrates mastery of all Module 02 concepts:
- Complex multi-table JOINs
- Aggregate functions with GROUP BY
- Subqueries for comparative analysis
- String and date functions
- CASE expressions for business logic
- Data filtering and sorting

---

## 📊 Business Requirements

You are a **Data Analyst** at Adventure Works. Management needs a detailed sales report with the following:

### 1. **Customer Analysis**
- Customer segmentation (VIP, High Value, Regular, Inactive)
- Total orders and revenue per customer
- Days since last order
- Customer lifetime value

### 2. **Product Performance**
- Best and worst selling products
- Products never ordered (dead inventory)
- Revenue by product category
- Profit margins

### 3. **Time-Based Trends**
- Monthly sales trends
- Year-over-year growth
- Seasonal patterns
- Order frequency analysis

### 4. **Geographic Analysis** (if address data available)
- Sales by region/state
- Top performing cities

---

## 📋 Project Deliverables

Complete **5 SQL queries** in `labs/lab_10_project.sql`:

### Query 1: Customer Segmentation Report (⭐⭐⭐⭐)

**Requirements**:
- List all customers with their order statistics
- Include: CustomerID, Name, Email, Total Orders, Total Spent, Average Order Value
- Calculate days since last order
- Assign customer tier using CASE:
  - VIP: Total spent > $10,000
  - High Value: Total spent > $5,000
  - Regular: Total spent > $0
  - Inactive: No orders
- Sort by total spent (highest first)

**Expected columns**:
```
CustomerID | CustomerName | Email | TotalOrders | TotalSpent | AvgOrderValue | DaysSinceLastOrder | CustomerTier
```

**Hints**:
- Use LEFT JOIN to include customers without orders
- Use DATEDIFF for days calculation
- Use CASE for tiering
- Handle NULL values from LEFT JOIN

---

### Query 2: Product Performance Dashboard (⭐⭐⭐⭐)

**Requirements**:
- Show all products with sales metrics
- Include: ProductID, Product Name, Category, List Price, Standard Cost
- Calculate: Times Sold, Total Quantity Sold, Total Revenue, Profit Margin %
- Identify products never sold (include them with 0 sales)
- Add status label: "Best Seller" (revenue > $10,000), "Good" (> $5,000), "Poor" (< $1,000), "Never Sold"

**Expected columns**:
```
ProductID | ProductName | Category | ListPrice | TimesSold | TotalQty | TotalRevenue | ProfitMargin% | Status
```

**Hints**:
- LEFT JOIN to include products never ordered
- COALESCE or ISNULL for handling NULLs from LEFT JOIN
- Profit margin = (Revenue - Cost) / Revenue * 100
- Watch for division by zero

---

### Query 3: Monthly Sales Trend Analysis (⭐⭐⭐⭐⭐)

**Requirements**:
- Aggregate sales by year and month
- Calculate: Total Orders, Total Revenue, Average Order Value, Unique Customers
- Compare each month to previous month (growth % or decline %)
- Add trend indicator: "Growing", "Declining", "Stable"
- Format month as "2008-Jun" (year-month name)

**Expected columns**:
```
YearMonth | TotalOrders | TotalRevenue | AvgOrderValue | UniqueCustomers | GrowthVsPreviousMonth% | Trend
```

**Hints**:
- Use FORMAT or DATENAME for month names
- LAG() window function for previous month comparison (or self-join if LAG not covered yet)
- Growth % = (Current - Previous) / Previous * 100
- CASE for trend classification

---

### Query 4: Category Performance with Subcategories (⭐⭐⭐⭐)

**Requirements**:
- Show sales by product category
- Include: Category Name, Number of Products, Total Revenue, Average Product Price
- Show top 3 best-selling products in each category (use subquery or window function)
- Calculate what % of total company revenue each category represents

**Expected columns**:
```
Category | ProductCount | CategoryRevenue | AvgProductPrice | CompanyRevenueShare% | Top3Products
```

**Hints**:
- Use window function SUM() OVER () for total company revenue
- STRING_AGG or FOR XML PATH for concatenating top products
- ROW_NUMBER() to rank products within category
- Subquery to get top 3 per category

---

### Query 5: Executive Summary - One-Page Dashboard (⭐⭐⭐⭐⭐)

**Requirements**:
Create a **single-row result** with key business metrics:
- Total customers (all time)
- Active customers (ordered in last 180 days)
- Inactive customers (no order in 180+ days)
- Total products in catalog
- Products with sales vs never sold
- Total orders (all time)
- Total revenue (all time)
- Average order value
- Date range (first order → last order)
- Current year revenue
- Previous year revenue (if data available)
- Year-over-year growth %

**Expected result**: ONE ROW with ~15 columns

**Hints**:
- Use multiple subqueries in SELECT clause
- COUNT with DISTINCT for unique customers
- CASE inside COUNT/SUM for conditional aggregations
- YEAR(OrderDate) for filtering by year

---

## 🎯 Bonus Challenges (Optional, ⭐⭐⭐⭐⭐)

### Bonus 1: RFM Analysis
Calculate **Recency, Frequency, Monetary** scores for each customer:
- Recency: Days since last order (lower is better)
- Frequency: Total orders (higher is better)
- Monetary: Total spent (higher is better)
- Assign scores 1-5 for each dimension
- Create RFM segment (e.g., "555" = best customers)

### Bonus 2: Cohort Analysis
Group customers by their first order month and track retention over time.

### Bonus 3: Product Recommendation
For each product, find 3 other products frequently purchased together (market basket analysis).

---

## 📝 Evaluation Rubric

| Criteria | Points | Details |
|----------|--------|---------|
| **Query Correctness** | 40 | Queries return accurate results |
| **SQL Best Practices** | 20 | Proper aliases, formatting, comments |
| **Performance** | 15 | Efficient joins, no unnecessary subqueries |
| **Handling Edge Cases** | 15 | NULL handling, division by zero, empty results |
| **Business Insights** | 10 | Results are meaningful and actionable |
| **TOTAL** | 100 | Pass = 70+ |

---

## ✅ Submission Checklist

Before submitting:
- [ ] All 5 queries execute without errors
- [ ] Results match expected column names and types
- [ ] NULL values handled appropriately
- [ ] Comments explain complex logic
- [ ] Code follows SQL style guide (uppercase keywords, proper indentation)
- [ ] Test queries with different date ranges
- [ ] Verify calculations (spot-check a few rows manually)

---

## 🎓 Learning Outcomes

After completing this project, you will be able to:
✅ Write complex multi-table JOINs confidently  
✅ Combine multiple SQL concepts in one query  
✅ Handle real-world data quality issues (NULLs, missing data)  
✅ Transform business requirements into SQL queries  
✅ Create production-ready analytical reports  

---

## 📚 Resources

**Review these sections if needed**:
- Section 06: JOINs
- Section 05: GROUP BY & HAVING
- Section 07: Subqueries
- Section 08: Functions
- Section 09: CASE Expressions

**Solution available**: `solutions/lab_10_project_solution.sql`

---

## 🚀 After Completion

**Congratulations!** You've completed Module 02: SQL Fundamentals. 

**Next steps**:
1. Complete Week 2 Quiz (20 questions)
2. Review your solution against provided solution
3. Optional: Tackle bonus challenges
4. Ready for Module 03: Advanced SQL (CTEs, Window Functions, Query Optimization)

---

*கற்க கசடற - Learn Flawlessly! You've got this! 💪*
