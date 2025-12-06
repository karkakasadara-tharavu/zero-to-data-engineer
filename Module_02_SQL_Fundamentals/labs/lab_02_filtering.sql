/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                    LAB 02: FILTERING DATA WITH WHERE CLAUSE                  ║
║                        Module 02: SQL Fundamentals                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

Estimated Time: 60 minutes
Difficulty: ⭐⭐ Beginner-Intermediate
Database: AdventureWorksLT2022

📚 Skills Practiced:
- WHERE clause with comparison operators
- Logical operators (AND, OR, NOT)
- IN operator for multiple values
- BETWEEN for ranges
- LIKE for pattern matching
- IS NULL / IS NOT NULL

*/

USE AdventureWorksLT2022;
GO

-- ========================================
-- TASK 1: Products Under $200 (⭐ Easy)
-- ========================================
-- Business requirement: Show all affordable products for budget-conscious customers
-- Return: ProductID, Name, ListPrice
-- Filter: ListPrice < 200
-- Sort: Price ascending (cheapest first)

-- 🔍 Expected result: ~100+ products
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] Query runs without errors
-- [ ] All results have ListPrice < 200
-- [ ] Results sorted by price (lowest first)


-- ========================================
-- TASK 2: Search Customers by Email Pattern (⭐⭐ Medium)
-- ========================================
-- Business requirement: Find customers with "adventure" in their email
-- Return: CustomerID, FirstName, LastName, EmailAddress
-- Filter: Email contains "adventure" (case-insensitive)
-- Sort: LastName alphabetically

-- 💡 Hint: Use LIKE with % wildcard
-- 🔍 Expected result: Multiple customers
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] All email addresses contain "adventure"
-- [ ] Case-insensitive search (matches "Adventure", "ADVENTURE", etc.)
-- [ ] Sorted by LastName


-- ========================================
-- TASK 3: Orders in Date Range (⭐⭐ Medium)
-- ========================================
-- Business requirement: Analyze orders from June 2008
-- Return: SalesOrderID, OrderDate, CustomerID, TotalDue
-- Filter: OrderDate between 2008-06-01 and 2008-06-30 (inclusive)
-- Sort: OrderDate ascending

-- 💡 Hint: Use BETWEEN or >= AND <=
-- 🔍 Expected result: All June 2008 orders
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] All OrderDate values are in June 2008
-- [ ] First day (June 1) and last day (June 30) are both included
-- [ ] Sorted chronologically


-- ========================================
-- TASK 4: Multiple Color Filter (⭐⭐ Medium)
-- ========================================
-- Business requirement: Show products in Red, Black, or Silver colors
-- Return: ProductID, Name, Color, ListPrice
-- Filter: Color is Red OR Black OR Silver
-- Sort: Color (alphabetically), then Price (high to low)

-- 💡 Hint: Use IN operator
-- 🔍 Expected result: ~150+ products
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] Only Red, Black, and Silver products shown
-- [ ] Sorted first by Color, then by Price descending within each color
-- [ ] No NULL colors in result


-- ========================================
-- TASK 5: Product Name Pattern Search (⭐⭐⭐ Hard)
-- ========================================
-- Business requirement: Find all "Mountain" bikes (any Mountain-related product)
-- Return: ProductID, Name, ProductCategoryID, ListPrice
-- Filter: 
--   - Name starts with "Mountain"
--   - Price > 500
--   - NOT discontinued (SellEndDate IS NULL)
-- Sort: ListPrice descending

-- 💡 Hint: Combine LIKE with AND conditions
-- 🔍 Expected result: Several high-end mountain products
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] All product names start with "Mountain"
-- [ ] All prices are over $500
-- [ ] No discontinued products (SellEndDate is NULL)
-- [ ] Sorted by price (most expensive first)


-- ========================================
-- TASK 6: Products with Missing Data (⭐⭐ Medium)
-- ========================================
-- Business requirement: Data quality check - find products missing color or size info
-- Return: ProductID, Name, Color, Size, ListPrice
-- Filter: Color IS NULL OR Size IS NULL
-- Sort: ListPrice descending

-- 💡 Hint: Use IS NULL with OR
-- 🔍 Expected result: Products with incomplete specifications
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] Results include products where Color is NULL or Size is NULL (or both)
-- [ ] NULL values display as NULL (not empty string)
-- [ ] Sorted by price


-- ========================================
-- TASK 7: Complex Business Filter (⭐⭐⭐⭐ Hard)
-- ========================================
-- Business requirement: Identify premium products for marketing campaign
-- Return: ProductID, Name, Color, Size, ListPrice, StandardCost
-- Filter: 
--   - (Color = 'Red' OR Color = 'Black')
--   - AND ListPrice >= 1000
--   - AND StandardCost > 0 (exclude free items)
--   - AND ProductNumber LIKE 'BK-%' (bikes category code)
--   - AND SellEndDate IS NULL (currently available)
-- Calculate: Profit = ListPrice - StandardCost
-- Sort: Profit descending

-- 💡 Hint: Use parentheses to group OR conditions
-- 🔍 Expected result: High-end bikes currently for sale
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] All products are Red OR Black (not both required)
-- [ ] All products priced $1000+
-- [ ] All ProductNumbers start with "BK-"
-- [ ] Profit calculated correctly
-- [ ] Only active products (SellEndDate IS NULL)


-- ========================================
-- 💪 BONUS CHALLENGE: Customer Search (⭐⭐⭐⭐⭐ Expert)
-- ========================================
-- Business requirement: Find customers matching multiple criteria for targeted marketing
-- Requirements:
--   1. LastName starts with 'A', 'B', or 'C' (use LIKE with brackets)
--   2. Email domain is NOT 'example.com' (extract domain after @)
--   3. Customer has CompanyName specified (not NULL)
--   4. Title is NOT NULL
-- Return: CustomerID, Title, FirstName, LastName, CompanyName, EmailAddress
-- Sort: LastName, FirstName

-- 💡 Hints: 
--   - LIKE '[ABC]%' matches names starting with A, B, or C
--   - Use SUBSTRING and CHARINDEX to extract email domain
--   - Combine multiple AND conditions
-- ✍️ Your solution:




-- ☑️ Self-check:
-- [ ] All LastNames start with A, B, or C
-- [ ] No example.com email addresses
-- [ ] All rows have non-NULL CompanyName and Title
-- [ ] Properly sorted


/*
═══════════════════════════════════════════════════════════════════════════════
📊 TESTING YOUR SOLUTIONS
═══════════════════════════════════════════════════════════════════════════════

After completing all tasks:

1. Run each query individually to verify it works
2. Check row counts against expected results
3. Verify sorting is correct
4. Look for NULL values where they shouldn't be
5. Compare your results with solution file (after attempting!)

═══════════════════════════════════════════════════════════════════════════════
🎯 KEY LEARNING POINTS
═══════════════════════════════════════════════════════════════════════════════

✅ WHERE filters rows before they're returned
✅ Comparison operators: =, <>, <, >, <=, >=
✅ AND requires ALL conditions to be TRUE
✅ OR requires ANY condition to be TRUE
✅ IN is shorthand for multiple OR conditions
✅ BETWEEN is inclusive (includes both boundaries)
✅ LIKE with % matches any sequence of characters
✅ NULL requires IS NULL / IS NOT NULL (not = NULL)
✅ Use parentheses to control evaluation order
✅ String comparisons are case-insensitive by default

═══════════════════════════════════════════════════════════════════════════════
💡 WHEN YOU'RE READY
═══════════════════════════════════════════════════════════════════════════════

Check your solutions against: solutions/lab_02_filtering_solution.sql

Next Lab: lab_03_sorting.sql (ORDER BY, TOP, OFFSET/FETCH, DISTINCT)

கற்க கசடற - Learn Flawlessly!
═══════════════════════════════════════════════════════════════════════════════
*/
