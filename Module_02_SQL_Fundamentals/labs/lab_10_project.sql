/*
╔══════════════════════════════════════════════════════════════════════════════╗
║              LAB 10: PRACTICE PROJECT - SALES ANALYSIS REPORT                ║
║                        Module 02 - Final Assessment                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

⏰ Estimated Time: 8 hours (break into multiple sessions)
🎯 Difficulty: ⭐⭐⭐⭐ Comprehensive Challenge
📊 Database: AdventureWorksLT2022
📝 Pass Score: 70/100 points

INSTRUCTIONS:
1. Complete all 5 queries below
2. Test each query thoroughly
3. Add comments explaining your logic
4. Handle edge cases (NULLs, division by zero)
5. Compare with solution AFTER attempting

═══════════════════════════════════════════════════════════════════════════════
*/

USE AdventureWorksLT2022;
GO

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ QUERY 1: CUSTOMER SEGMENTATION REPORT                                       ║
║ Points: 20                                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

REQUIREMENTS:
- Show ALL customers (even those without orders)
- Calculate: Total orders, total spent, average order value
- Days since last order (NULL if never ordered)
- Assign tier: VIP (>$10K), High Value (>$5K), Regular (>$0), Inactive (no orders)
- Sort by total spent descending

EXPECTED COLUMNS:
CustomerID | CustomerName | Email | TotalOrders | TotalSpent | AvgOrderValue | 
DaysSinceLastOrder | CustomerTier

📊 Expected row count: ~847 customers
⚠️ Edge cases: Customers with no orders, NULL handling
*/

-- ✍️ YOUR SOLUTION:



/*
═══════════════════════════════════════════════════════════════════════════════
☑️ SELF-CHECK QUERY 1:
□ All 847 customers included (even those with 0 orders)?
□ TotalOrders = 0 for customers who never ordered?
□ TotalSpent and AvgOrderValue handled correctly for no orders?
□ DaysSinceLastOrder is NULL for inactive customers?
□ CustomerTier assigned correctly based on spend?
□ Sorted by TotalSpent descending?
═══════════════════════════════════════════════════════════════════════════════
*/


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ QUERY 2: PRODUCT PERFORMANCE DASHBOARD                                      ║
║ Points: 20                                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

REQUIREMENTS:
- Show ALL products (including those never sold)
- Include: ProductID, Name, Category, ListPrice, StandardCost
- Calculate: Times sold, total quantity sold, total revenue, profit margin %
- Product status: "Best Seller" (revenue>$10K), "Good" (>$5K), "Poor" (<$1K), "Never Sold"
- Sort by total revenue descending

EXPECTED COLUMNS:
ProductID | ProductName | Category | ListPrice | StandardCost | TimesSold | 
TotalQuantitySold | TotalRevenue | ProfitMargin% | ProductStatus

📊 Expected row count: ~295 products
⚠️ Edge cases: Products never sold, division by zero in profit margin
*/

-- ✍️ YOUR SOLUTION:



/*
═══════════════════════════════════════════════════════════════════════════════
☑️ SELF-CHECK QUERY 2:
□ All products included (even never sold)?
□ TimesSold = 0 for products with no sales?
□ TotalRevenue = 0 (not NULL) for never sold products?
□ Profit margin calculation handles division by zero?
□ ProductStatus assigned correctly?
□ Sorted by TotalRevenue descending?
═══════════════════════════════════════════════════════════════════════════════
*/


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ QUERY 3: MONTHLY SALES TREND ANALYSIS                                       ║
║ Points: 25                                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

REQUIREMENTS:
- Aggregate by year-month
- Calculate: Total orders, total revenue, avg order value, unique customers
- Compare to previous month (% growth or decline)
- Trend indicator: "Growing" (>5% growth), "Declining" (<-5%), "Stable" (between)
- Format YearMonth as "2008-Jun"

EXPECTED COLUMNS:
YearMonth | TotalOrders | TotalRevenue | AvgOrderValue | UniqueCustomers | 
GrowthVsPreviousMonth% | Trend

📊 Expected row count: ~3-4 months (2008 data)
⚠️ Edge cases: First month (no previous to compare), NULL handling
💡 Hint: Use LAG() window function or self-join
*/

-- ✍️ YOUR SOLUTION:



/*
═══════════════════════════════════════════════════════════════════════════════
☑️ SELF-CHECK QUERY 3:
□ Grouped by year and month correctly?
□ YearMonth formatted as "YYYY-MonthName"?
□ Previous month comparison calculated correctly?
□ First month handled (NULL or 0 for growth)?
□ Trend indicator assigned based on growth %?
□ Sorted chronologically?
═══════════════════════════════════════════════════════════════════════════════
*/


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ QUERY 4: CATEGORY PERFORMANCE ANALYSIS                                      ║
║ Points: 20                                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

REQUIREMENTS:
- Sales summary by product category
- Calculate: Product count, total revenue, avg product price
- Show % of total company revenue each category represents
- List top 3 best-selling products in each category (names concatenated)

EXPECTED COLUMNS:
CategoryName | ProductCount | CategoryRevenue | AvgProductPrice | 
CompanyRevenueShare% | Top3Products

📊 Expected row count: ~40 categories
⚠️ Edge cases: Categories with no sales, concatenation of product names
💡 Hint: Use SUM() OVER() for total company revenue, STRING_AGG for concatenation
*/

-- ✍️ YOUR SOLUTION:



/*
═══════════════════════════════════════════════════════════════════════════════
☑️ SELF-CHECK QUERY 4:
□ All categories included?
□ Revenue % calculated correctly (sum to 100%)?
□ Top 3 products identified per category?
□ Product names concatenated properly?
□ Sorted by category revenue descending?
═══════════════════════════════════════════════════════════════════════════════
*/


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ QUERY 5: EXECUTIVE DASHBOARD - ONE ROW SUMMARY                              ║
║ Points: 15                                                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

REQUIREMENTS:
Return ONE ROW with these metrics:
- TotalCustomers (all time)
- ActiveCustomers (ordered in last 180 days)
- InactiveCustomers (no order in 180+ days or never ordered)
- TotalProducts
- ProductsWithSales
- ProductsNeverSold
- TotalOrders (all time)
- TotalRevenue (all time)
- AvgOrderValue
- FirstOrderDate
- LastOrderDate
- DaysInBusiness
- CurrentYearRevenue (2008)
- PreviousYearRevenue (2007)
- YearOverYearGrowth%

EXPECTED: 1 row, ~15 columns
⚠️ Edge cases: Handle missing years gracefully
💡 Hint: Use subqueries in SELECT, COUNT with CASE for conditional counts
*/

-- ✍️ YOUR SOLUTION:



/*
═══════════════════════════════════════════════════════════════════════════════
☑️ SELF-CHECK QUERY 5:
□ Returns exactly 1 row?
□ All metrics calculated correctly?
□ Active/Inactive split based on 180-day threshold?
□ Revenue by year calculated correctly?
□ YoY growth % handles missing years?
═══════════════════════════════════════════════════════════════════════════════
*/


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ 💪 BONUS CHALLENGES (OPTIONAL, +15 POINTS EACH)                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

-- BONUS 1: RFM ANALYSIS (Recency, Frequency, Monetary)
-- Calculate RFM scores (1-5) for each customer
-- Score customers on: 
--   - Recency: Days since last order (lower = better, score 5)
--   - Frequency: Total orders (higher = better, score 5)
--   - Monetary: Total spent (higher = better, score 5)
-- Create combined RFM segment (e.g., "555" = best customers)

-- ✍️ YOUR SOLUTION:



-- BONUS 2: COHORT RETENTION ANALYSIS
-- Group customers by their first order month
-- Track how many customers from each cohort ordered in subsequent months
-- Show retention rate over time

-- ✍️ YOUR SOLUTION:



-- BONUS 3: PRODUCT AFFINITY (Market Basket Analysis)
-- For each product, find top 3 products frequently purchased together
-- Based on orders containing both products

-- ✍️ YOUR SOLUTION:



/*
╔══════════════════════════════════════════════════════════════════════════════╗
║ 📊 EVALUATION RUBRIC                                                         ║
╚══════════════════════════════════════════════════════════════════════════════╝

SCORING:
Query 1 (Customer Segmentation): _____ / 20
Query 2 (Product Performance):   _____ / 20
Query 3 (Monthly Trends):        _____ / 25
Query 4 (Category Analysis):     _____ / 20
Query 5 (Executive Dashboard):   _____ / 15
────────────────────────────────────────
TOTAL SCORE:                     _____ / 100

Bonus 1 (RFM):                   _____ / 15 (Optional)
Bonus 2 (Cohort):                _____ / 15 (Optional)
Bonus 3 (Affinity):              _____ / 15 (Optional)

GRADING SCALE:
90-100:  Excellent (A)  - Ready for advanced SQL
80-89:   Good (B)       - Strong foundation, minor gaps
70-79:   Pass (C)       - Meets minimum requirements
Below 70: Review needed - Revisit sections before proceeding

CRITERIA PER QUERY:
✅ Correctness (40%):      Query returns accurate results
✅ SQL Style (20%):        Proper formatting, aliases, readability
✅ Performance (15%):      Efficient joins, no redundant operations
✅ Edge Cases (15%):       Handles NULLs, division by zero, empty sets
✅ Business Value (10%):   Results are meaningful and actionable

═══════════════════════════════════════════════════════════════════════════════
🎓 AFTER COMPLETION
═══════════════════════════════════════════════════════════════════════════════

1. ✅ Test each query thoroughly
2. ✅ Check results against expected outcomes
3. ✅ Review your code for best practices
4. ✅ Compare with solutions/lab_10_project_solution.sql
5. ✅ Complete Module 02 Quiz (20 questions)
6. ✅ Celebrate! You've mastered SQL fundamentals! 🎉

NEXT STEPS:
→ Module 03: Advanced SQL (CTEs, Window Functions, Query Optimization)
→ Module 04: Database Administration
→ Continue your journey to becoming a Data Engineer!

கற்க கசடற - Learn Flawlessly!
═══════════════════════════════════════════════════════════════════════════════
*/
