-- Lab 12: Recursive CTEs
-- Module 03: Advanced SQL
-- Database: AdventureWorks2022
-- Difficulty: ⭐⭐⭐⭐

-- =============================================
-- SETUP
-- =============================================
USE AdventureWorks2022;
GO

-- =============================================
-- TASK 1: Product Category Hierarchy (⭐⭐⭐)
-- =============================================
-- Display product category hierarchy with levels
-- Output: CategoryID, Name, ParentID, Level, HierarchyPath
-- Hint: Production.ProductCategory has ParentProductCategoryID

-- Your query here:



-- Expected Result: ~40 categories showing tree structure
-- Self-Check: Bikes should be Level 0, Mountain should be Level 1

-- =============================================
-- TASK 2: Organization Chart (⭐⭐⭐⭐)
-- =============================================
-- Show employee reporting hierarchy starting from CEO
-- Include: EmployeeID, Name, ManagerID, Level, ReportsTo path
-- Hint: HumanResources.Employee, Person.Person

-- Your query here:



-- Expected Result: ~290 employees with hierarchy levels
-- Self-Check: CEO should be Level 0 with NULL manager

-- =============================================
-- TASK 3: Bill of Materials - Complete BOM (⭐⭐⭐⭐⭐)
-- =============================================
-- Flatten the BOM for ProductAssemblyID = 749 (Road-150 Red, 62)
-- Show: Level, ComponentID, ComponentName, Quantity, TotalQuantity
-- TotalQuantity = Quantity needed accounting for nested assemblies
-- Hint: Production.BillOfMaterials, Production.Product

-- Your query here:



-- Expected Result: Multi-level parts list with quantities
-- Self-Check: Sub-components should multiply quantities correctly

-- =============================================
-- TASK 4: Number Series Generator (⭐⭐)
-- =============================================
-- Generate numbers 1 to 100 using recursive CTE
-- No Numbers table allowed!

-- Your query here:



-- Expected Result: 100 rows numbered 1-100
-- Self-Check: Should start at 1, end at 100

-- =============================================
-- TASK 5: Find All Direct and Indirect Reports (⭐⭐⭐⭐)
-- =============================================
-- For ManagerID = 16 (Ken Sanchez - CEO), find ALL employees 
-- who report directly OR indirectly
-- Show: EmployeeID, Name, Level, DirectManager

-- Your query here:



-- Expected Result: ~289 employees (everyone except CEO)
-- Self-Check: Marketing Manager should be Level 2 or 3

-- =============================================
-- CHALLENGE: Date Range Generator (⭐⭐⭐⭐⭐)
-- =============================================
-- Generate all dates between 2013-01-01 and 2013-12-31
-- Output: Date, DayOfWeek, WeekNumber, MonthName
-- Hint: Use DATEADD in recursive part

-- Your query here:



-- Expected Result: 365 dates with calendar info
-- Self-Check: January should have 31 rows

-- =============================================
-- MAXRECURSION EXERCISE
-- =============================================
-- Re-run Task 4 (number generator) but generate 1 to 500
-- What happens? Fix it with MAXRECURSION hint

-- Your query here:



-- Expected Result: 500 rows (should succeed with MAXRECURSION)
-- Self-Check: Default limit is 100, must specify OPTION (MAXRECURSION 500)

-- =============================================
-- REFLECTION QUESTIONS
-- =============================================
-- 1. What is the structure of a recursive CTE (2 parts)?
-- 2. When would you increase MAXRECURSION?
-- 3. Name 3 real-world uses for recursive CTEs

-- ANSWER 1: 

-- ANSWER 2: 

-- ANSWER 3: 
