-- Lab 14: Window Analytical Functions
-- Module 03: Advanced SQL
-- Database: AdventureWorks2022
-- Difficulty: ⭐⭐⭐⭐⭐

-- =============================================
-- SETUP
-- =============================================
USE AdventureWorks2022;
GO

-- =============================================
-- TASK 1: Running Total (⭐⭐⭐⭐)
-- =============================================
-- Calculate cumulative revenue per customer over time
-- Output: CustomerID, OrderDate, OrderTotal, RunningTotal
-- Sort by customer and order date

-- Your query here:



-- Expected Result: Running total resets for each customer
-- Self-Check: Last row per customer = total lifetime value

-- =============================================
-- TASK 2: Month-over-Month Growth (⭐⭐⭐⭐⭐)
-- =============================================
-- Calculate monthly sales and compare to previous month
-- Output: Year, Month, MonthlyRevenue, PrevMonth, Difference, Growth%
-- Use LAG function

-- Your query here:



-- Expected Result: 24+ months with MoM comparison
-- Self-Check: First month should have NULL for PrevMonth

-- =============================================
-- TASK 3: 7-Day Moving Average (⭐⭐⭐⭐)
-- =============================================
-- Calculate 7-day moving average of daily sales
-- Output: OrderDate, DailyTotal, MovingAvg7Day
-- Use ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

-- Your query here:



-- Expected Result: Smoothed trend line
-- Self-Check: First 6 days will have partial averages

-- =============================================
-- TASK 4: Compare First vs Last Order Amount (⭐⭐⭐⭐)
-- =============================================
-- For each customer, compare:
-- - First order amount (FIRST_VALUE)
-- - Last order amount (LAST_VALUE)
-- - Difference
-- Show customers where last order > first order (upsell success)

-- Your query here:



-- Expected Result: Customers with increasing order values
-- Self-Check: LAST_VALUE requires UNBOUNDED FOLLOWING frame

-- =============================================
-- TASK 5: Cumulative Percentage (⭐⭐⭐⭐⭐)
-- =============================================
-- Show products with cumulative revenue percentage
-- (What % of total revenue comes from top N products?)
-- Output: ProductID, Name, Revenue, RunningTotal, CumulativePercent

-- Your query here:



-- Expected Result: Products ordered by revenue with cumulative %
-- Self-Check: Top 20% of products often = 80% of revenue (Pareto)

-- =============================================
-- TASK 6: Employee Tenure Comparison (⭐⭐⭐⭐)
-- =============================================
-- For each employee, show:
-- - Their hire date
-- - Previous employee's hire date (LAG)
-- - Next employee's hire date (LEAD)
-- - Days between hires
-- Order by HireDate

-- Your query here:



-- Expected Result: Timeline of hiring with gaps
-- Self-Check: First/last employees will have NULL for LAG/LEAD

-- =============================================
-- CHALLENGE: Customer Lifetime Analysis (⭐⭐⭐⭐⭐)
-- =============================================
-- Comprehensive report per customer:
-- 1. First order date and amount
-- 2. Last order date and amount
-- 3. Running total of all orders
-- 4. Average order value (window avg)
-- 5. Order count
-- 6. Days since last order (use GETDATE())

-- Your query here:



-- Expected Result: Multi-column analysis per customer order
-- Self-Check: Use multiple window functions in same query

-- =============================================
-- REFLECTION QUESTIONS
-- =============================================
-- 1. What's the difference between ROWS and RANGE in window frames?
-- 2. Why does LAST_VALUE need UNBOUNDED FOLLOWING?
-- 3. How is LAG(col, 1) different from LAG(col, 2)?

-- ANSWER 1: 

-- ANSWER 2: 

-- ANSWER 3: 
