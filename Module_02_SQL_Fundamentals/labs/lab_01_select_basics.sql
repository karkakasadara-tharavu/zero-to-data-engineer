-- =============================================
-- Lab 01: SELECT Basics
-- Module 02: SQL Fundamentals
-- Difficulty: ⭐ Beginner
-- Estimated Time: 45 minutes
-- =============================================

-- Instructions:
-- 1. Switch to AdventureWorksLT2022 database
-- 2. Complete each task by writing SQL queries
-- 3. Execute each query and verify results
-- 4. Check your answers against expected results
-- 5. Only view solution file AFTER attempting all tasks

-- Switch to correct database
USE AdventureWorksLT2022;
GO

PRINT '========================================';
PRINT 'Lab 01: SELECT Basics';
PRINT 'Student Name: [YOUR NAME HERE]';
PRINT 'Date: [TODAY''S DATE]';
PRINT '========================================';
GO

-- =============================================
-- TASK 1: Retrieve All Columns (⭐ Easy)
-- =============================================
-- Objective: Use SELECT * to view entire Customer table
-- Expected Result: 847 rows, 10+ columns

PRINT 'Task 1: Retrieve all customer data';
GO

-- YOUR CODE HERE:




-- Expected columns: CustomerID, NameStyle, Title, FirstName, MiddleName, 
--                   LastName, Suffix, CompanyName, SalesPerson, EmailAddress, 
--                   Phone, PasswordHash, PasswordSalt, rowguid, ModifiedDate

-- ✅ Self-Check:
-- [ ] Query executes without errors
-- [ ] All columns displayed
-- [ ] 847 rows returned


-- =============================================
-- TASK 2: Select Specific Columns (⭐ Easy)
-- =============================================
-- Objective: Retrieve only ProductID, Name, and ListPrice from Product table
-- Expected Result: 295 rows, 3 columns

PRINT 'Task 2: Product ID, Name, and Price';
GO

-- YOUR CODE HERE:




-- Expected columns: ProductID, Name, ListPrice

-- ✅ Self-Check:
-- [ ] Only 3 columns displayed
-- [ ] 295 rows returned
-- [ ] Column names match: ProductID, Name, ListPrice


-- =============================================
-- TASK 3: Column Aliases (⭐⭐ Easy-Medium)
-- =============================================
-- Objective: Retrieve customer info with friendly column headers
-- Columns needed:
--   - CustomerID → "Customer ID"
--   - FirstName + LastName combined → "Full Name"
--   - EmailAddress → "Email"
-- Expected Result: 847 rows, 3 columns with custom headers

PRINT 'Task 3: Customer names with aliases';
GO

-- YOUR CODE HERE:




-- Expected columns: "Customer ID", "Full Name", "Email"

-- ✅ Self-Check:
-- [ ] 3 columns displayed
-- [ ] Column headers show aliases (Customer ID, Full Name, Email)
-- [ ] Full Name column combines FirstName and LastName with space
-- [ ] 847 rows returned


-- =============================================
-- TASK 4: Arithmetic Calculations (⭐⭐ Medium)
-- =============================================
-- Objective: Calculate profit metrics for products
-- Columns needed:
--   - ProductID
--   - Name
--   - StandardCost
--   - ListPrice
--   - Profit (calculated: ListPrice - StandardCost)
--   - Profit Percentage (calculated: (Profit / ListPrice) * 100)
-- Expected Result: 295 rows, 6 columns

PRINT 'Task 4: Product profit analysis';
GO

-- YOUR CODE HERE:




-- Expected columns: ProductID, Name, StandardCost, ListPrice, Profit, ProfitPercentage

-- ✅ Self-Check:
-- [ ] All 6 columns displayed
-- [ ] Profit = ListPrice - StandardCost
-- [ ] ProfitPercentage is a decimal/percentage value
-- [ ] 295 rows returned
-- [ ] No errors for NULL values


-- =============================================
-- TASK 5: String Concatenation (⭐⭐⭐ Medium-Hard)
-- =============================================
-- Objective: Create product label in format "Name - Color - $Price"
-- Example: "HL Road Frame - Black - $1431.50"
-- Columns needed:
--   - ProductID
--   - ProductLabel (concatenated string)
-- Expected Result: 295 rows, 2 columns
-- Challenge: Handle NULL colors gracefully (some products have no color)

PRINT 'Task 5: Product labels';
GO

-- YOUR CODE HERE:




-- Expected format: "HL Road Frame - Black - $1431.50"
-- Hint: Use CONCAT() to handle NULL colors
-- Hint: For dollar sign, use '$' in CONCAT or '+' with CAST(ListPrice AS VARCHAR)

-- ✅ Self-Check:
-- [ ] ProductLabel column created
-- [ ] Format matches: "Name - Color - $Price"
-- [ ] NULL colors handled (don't show "NULL" in string)
-- [ ] Dollar sign appears before price
-- [ ] 295 rows returned


-- =============================================
-- TASK 6: Date and Calculation (⭐⭐ Medium)
-- =============================================
-- Objective: Retrieve order information with sales tax calculation
-- Table: SalesLT.SalesOrderHeader
-- Columns needed:
--   - OrderDate → alias "Order Date"
--   - TotalDue → alias "Total Amount"
--   - TotalDue * 0.065 → alias "Estimated Sales Tax" (6.5% tax rate)
-- Expected Result: 32 rows, 3 columns

PRINT 'Task 6: Order information with tax';
GO

-- YOUR CODE HERE:




-- Expected columns: "Order Date", "Total Amount", "Estimated Sales Tax"

-- ✅ Self-Check:
-- [ ] All 3 columns displayed with correct aliases
-- [ ] Sales tax is 6.5% of Total Amount
-- [ ] 32 rows returned (total orders in table)


-- =============================================
-- TASK 7: Complex String Concatenation (⭐⭐⭐ Medium-Hard)
-- =============================================
-- Objective: Create personalized greeting message
-- Format: "Dear [FirstName] [LastName], your email is [EmailAddress]"
-- Example: "Dear Orlando Gee, your email is orlando.gee@adventure-works.com"
-- Columns needed:
--   - CustomerID
--   - GreetingMessage (concatenated string)
-- Expected Result: 847 rows, 2 columns

PRINT 'Task 7: Customer greeting messages';
GO

-- YOUR CODE HERE:




-- Expected format: "Dear Orlando Gee, your email is orlando.gee@adventure-works.com"

-- ✅ Self-Check:
-- [ ] GreetingMessage column created
-- [ ] Format matches exactly (punctuation, spacing)
-- [ ] FirstName and LastName separated by space
-- [ ] Email address included correctly
-- [ ] 847 rows returned


-- =============================================
-- BONUS CHALLENGE (Optional - ⭐⭐⭐⭐ Hard)
-- =============================================
-- Objective: Create a comprehensive product summary
-- Combine multiple concepts from this lab
-- 
-- Requirements:
--   - Table: SalesLT.Product
--   - Columns:
--     1. ProductNumber (alias: "SKU")
--     2. Name (alias: "Product")
--     3. Combined string: "Color: [Color] | Price: $[ListPrice]" (alias: "Details")
--     4. Calculation: ListPrice - StandardCost (alias: "Markup")
--     5. Calculation: (Markup / StandardCost) * 100 (alias: "Markup %")
--   - Handle NULL colors (show "Color: N/A" if color is NULL)
--   - Format ListPrice as currency in Details column
-- Expected Result: 295 rows, 5 columns

PRINT 'BONUS: Comprehensive product summary';
GO

-- YOUR CODE HERE:




-- Expected columns: SKU, Product, Details, Markup, Markup %

-- ✅ Self-Check:
-- [ ] All 5 columns displayed correctly
-- [ ] NULL colors show as "N/A"
-- [ ] Details column formatted correctly
-- [ ] Markup calculations correct
-- [ ] No division by zero errors


-- =============================================
-- LAB COMPLETION
-- =============================================

PRINT '';
PRINT '========================================';
PRINT '✅ Lab 01 Complete!';
PRINT '========================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Review your results against expected outputs';
PRINT '2. Check solution file if needed: solutions/lab_01_select_basics_solution.sql';
PRINT '3. Make sure you understand WHY each query works';
PRINT '4. Proceed to Section 02: Filtering Data';
PRINT '';
PRINT 'கற்க கசடற - Learn Flawlessly!';
PRINT '';
GO


-- =============================================
-- SELF-ASSESSMENT CHECKLIST
-- =============================================
-- Before moving to next section, ensure:
-- 
-- [ ] All 7 tasks completed without errors
-- [ ] Results match expected row counts
-- [ ] Column aliases applied correctly
-- [ ] Calculations produce reasonable values
-- [ ] String concatenation handles NULLs properly
-- [ ] You understand SELECT...FROM syntax
-- [ ] You can explain difference between + and CONCAT()
-- [ ] You know when to use AS for aliases
-- 
-- If you checked all boxes: CONGRATULATIONS! Move to Section 02!
-- If not: Review Section 01 material and retry incomplete tasks.
-- 
-- Remember: Struggling is LEARNING! Ask for help if stuck.
-- =============================================
