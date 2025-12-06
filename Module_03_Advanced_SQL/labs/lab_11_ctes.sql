-- Lab 11: Common Table Expressions (CTEs)
-- Module 03: Advanced SQL
-- Database: AdventureWorks2022
-- Difficulty: ⭐⭐⭐

-- =============================================
-- SETUP: Ensure you're connected to AdventureWorks2022
-- =============================================
USE AdventureWorks2022;
GO

-- =============================================
-- TASK 1: Simple CTE for Product Analysis (⭐⭐)
-- =============================================
-- Find all products with ListPrice above the average
-- Use a CTE named AvgPrice

-- Your query here:



-- Expected Result: ~180 products above average
-- Self-Check: Does your result include ProductID, Name, ListPrice, and AvgPrice?

-- =============================================
-- TASK 2: Multiple CTEs - Customer Segmentation (⭐⭐⭐⭐)
-- =============================================
-- Create a 3-stage pipeline using CTEs:
-- 1. CustomerMetrics: Calculate TotalSpent and OrderCount per customer
-- 2. CustomerSegments: Categorize customers as VIP (>$10K), Regular ($1K-$10K), New (<$1K)
-- 3. SegmentStats: Count customers and average spent per segment

-- Your query here:



-- Expected Result: 3 segments with counts and averages
-- Self-Check: VIP segment should show highest average spend

-- =============================================
-- TASK 3: CTE with JOINs - Top Sellers (⭐⭐⭐)
-- =============================================
-- Using CTE, find top 5 products by total revenue
-- Include: ProductID, Name, Category, TotalRevenue
-- Hint: Join Product → ProductSubcategory → ProductCategory → SalesOrderDetail

-- Your query here:



-- Expected Result: 5 products with revenue > $1M
-- Self-Check: Mountain-200 series should appear in top results

-- =============================================
-- TASK 4: Year-over-Year Comparison (⭐⭐⭐⭐⭐)
-- =============================================
-- Compare monthly sales between 2013 and 2014
-- Show: Year, Month, Revenue2013, Revenue2014, Growth%
-- Use 2 CTEs: Sales2013 and Sales2014

-- Your query here:



-- Expected Result: 12 months with side-by-side comparison
-- Self-Check: Some months should show negative growth

-- =============================================
-- TASK 5: Recursive Reference (⭐⭐⭐)
-- =============================================
-- Create a CTE that finds both:
-- - Products never sold (NO order details)
-- - Top 10 best sellers (most ordered)
-- Reference the same CTE twice in final SELECT

-- Your query here:



-- Expected Result: Two result sets from one CTE
-- Self-Check: Unsold products should have 0 orders

-- =============================================
-- CHALLENGE TASK: Complex Multi-CTE Pipeline (⭐⭐⭐⭐⭐)
-- =============================================
-- Build a customer lifetime value report:
-- CTE 1: FirstOrder - first order date per customer
-- CTE 2: LastOrder - most recent order date per customer  
-- CTE 3: CustomerValue - total spent, order count, avg order
-- Final: Join all CTEs, calculate days active, orders per year

-- Your query here:



-- Expected Result: Comprehensive customer analysis
-- Self-Check: Customers with longer tenure should have more orders

-- =============================================
-- REFLECTION QUESTIONS
-- =============================================
-- 1. When would you use a CTE instead of a subquery?
-- 2. What are the limitations of CTEs compared to temp tables?
-- 3. Can you reference a CTE multiple times in the same query?

-- Save your answers as comments below:
-- ANSWER 1: 

-- ANSWER 2: 

-- ANSWER 3: 
