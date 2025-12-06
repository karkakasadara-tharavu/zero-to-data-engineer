-- Lab 13: Window Ranking Functions
-- Module 03: Advanced SQL
-- Database: AdventureWorks2022
-- Difficulty: ⭐⭐⭐⭐

-- =============================================
-- SETUP
-- =============================================
USE AdventureWorks2022;
GO

-- =============================================
-- TASK 1: ROW_NUMBER for Pagination (⭐⭐⭐)
-- =============================================
-- Assign sequential row numbers to products ordered by ListPrice DESC
-- Then filter to show only rows 21-40 (page 2 of results, 20 per page)

-- Your query here:



-- Expected Result: 20 products (ranks 21-40)
-- Self-Check: First row should have RowNum = 21

-- =============================================
-- TASK 2: Top 3 Products Per Category (⭐⭐⭐⭐)
-- =============================================
-- Find top 3 most expensive products in EACH category
-- Output: Category, ProductName, ListPrice, PriceRank
-- Hint: Use PARTITION BY with ProductCategoryID

-- Your query here:



-- Expected Result: ~12 categories × 3 products = 36 rows
-- Self-Check: Each category should reset ranking to 1, 2, 3

-- =============================================
-- TASK 3: RANK vs DENSE_RANK (⭐⭐⭐)
-- =============================================
-- Compare RANK and DENSE_RANK for employees by VacationHours
-- Show: EmployeeID, VacationHours, NormalRank, DenseRank
-- Observe difference when ties occur

-- Your query here:



-- Expected Result: Same dataset with 2 rank columns
-- Self-Check: When 2 employees tie, RANK skips next number, DENSE_RANK doesn't

-- =============================================
-- TASK 4: Customer Spend Percentile (⭐⭐⭐⭐⭐)
-- =============================================
-- Calculate customer lifetime value percentile using NTILE(100)
-- Then segment customers:
--   - Top 10% (Percentile 91-100): VIP
--   - Top 25% (76-90): Premium
--   - Middle 50% (26-75): Regular  
--   - Bottom 25% (1-25): New

-- Your query here:



-- Expected Result: All customers with percentile and segment
-- Self-Check: VIP segment should have highest spenders

-- =============================================
-- TASK 5: First and Last Order Per Customer (⭐⭐⭐⭐)
-- =============================================
-- For each customer, show:
-- - First order date and amount
-- - Last order date and amount
-- - Days between first and last order
-- Use ROW_NUMBER with DESC/ASC ordering

-- Your query here:



-- Expected Result: One row per customer with 4 date/amount columns
-- Self-Check: Single-order customers should have same first/last dates

-- =============================================
-- TASK 6: Running Rank - Employee Hire Order (⭐⭐⭐)
-- =============================================
-- Rank employees by hire date within each department
-- Show: Department, EmployeeName, HireDate, HireRank
-- Use DENSE_RANK to avoid gaps

-- Your query here:



-- Expected Result: Employees ranked by seniority per department
-- Self-Check: Each department should start at rank 1

-- =============================================
-- CHALLENGE: Quartile Analysis (⭐⭐⭐⭐⭐)
-- =============================================
-- Divide products into quartiles by ListPrice
-- For each quartile, show:
--   - Quartile number (1-4)
--   - Min, Max, Avg price in that quartile
--   - Product count

-- Your query here:



-- Expected Result: 4 rows with aggregate stats per quartile
-- Self-Check: Q1 should have lowest prices, Q4 highest

-- =============================================
-- REFLECTION QUESTIONS
-- =============================================
-- 1. What's the difference between RANK and DENSE_RANK?
-- 2. When would you use NTILE instead of RANK?
-- 3. What does PARTITION BY do in window functions?

-- ANSWER 1: 

-- ANSWER 2: 

-- ANSWER 3: 
