-- Quiz 03: CTEs and Window Functions (Week 1)
-- Module 03: Advanced SQL
-- Time: 30 minutes | Questions: 20 | Passing: 70%

-- =============================================
-- SECTION A: Multiple Choice (1 point each)
-- =============================================

-- Q1. What does CTE stand for?
-- A) Common Table Expression
-- B) Computed Table Entity
-- C) Conditional Table Evaluation
-- D) Complex Transaction Engine
-- ANSWER: 

-- Q2. Which keyword introduces a CTE?
-- A) CREATE
-- B) WITH
-- C) DECLARE
-- D) DEFINE
-- ANSWER: 

-- Q3. What is the scope of a CTE?
-- A) Entire database session
-- B) Single query
-- C) Current transaction
-- D) All queries in the batch
-- ANSWER: 

-- Q4. Which function assigns unique sequential numbers?
-- A) RANK
-- B) DENSE_RANK
-- C) ROW_NUMBER
-- D) NTILE
-- ANSWER: 

-- Q5. What does PARTITION BY do in window functions?
-- A) Splits data into physical partitions
-- B) Resets calculations for each group
-- C) Creates indexed partitions
-- D) Filters rows before calculation
-- ANSWER: 

-- Q6. What's the difference between RANK and DENSE_RANK?
-- A) RANK is faster
-- B) RANK skips numbers after ties
-- C) DENSE_RANK only works with integers
-- D) No difference
-- ANSWER: 

-- Q7. How many parts does a recursive CTE have?
-- A) 1 (recursive part only)
-- B) 2 (anchor + recursive)
-- C) 3 (anchor, recursive, termination)
-- D) Variable (depends on depth)
-- ANSWER: 

-- Q8. What is the default MAXRECURSION limit?
-- A) 50
-- B) 100
-- C) 1000
-- D) Unlimited
-- ANSWER: 

-- Q9. Which window function divides rows into equal buckets?
-- A) ROW_NUMBER
-- B) RANK
-- C) PERCENTILE
-- D) NTILE
-- ANSWER: 

-- Q10. Can you reference a CTE multiple times in a query?
-- A) No, only once
-- B) Yes, unlimited times
-- C) Yes, but max 3 times
-- D) Only in recursive CTEs
-- ANSWER: 

-- =============================================
-- SECTION B: Code Analysis (2 points each)
-- =============================================

-- Q11. What will this query return?
WITH Numbers AS (
    SELECT 1 AS N
    UNION ALL
    SELECT N + 1 FROM Numbers WHERE N < 5
)
SELECT * FROM Numbers;

-- A) Error: Invalid recursion
-- B) 1, 2, 3, 4, 5
-- C) 1, 2, 3, 4
-- D) Infinite loop
-- ANSWER: 

-- Q12. What's the output for ProductID 100?
SELECT ProductID, ListPrice,
       ROW_NUMBER() OVER (ORDER BY ListPrice DESC) AS Rank
FROM Products
WHERE ProductID IN (100, 101, 102)
-- Prices: 100=$50, 101=$50, 102=$30

-- A) Rank = 1 or 2 (tie)
-- B) Rank = 1 (deterministic)
-- C) Rank = 1 or 2 (non-deterministic)
-- D) Error: duplicate prices
-- ANSWER: 

-- Q13. Identify the error:
WITH Sales AS (SELECT * FROM Orders)
SELECT * FROM Products;
SELECT * FROM Sales;

-- A) No error
-- B) CTE not referenced in first query
-- C) CTE out of scope in second query
-- D) Missing semicolon
-- ANSWER: 

-- Q14. What does PARTITION BY CustomerID do here?
SELECT CustomerID, OrderDate,
       SUM(Total) OVER (PARTITION BY CustomerID ORDER BY OrderDate)
FROM Orders;

-- A) Groups rows by customer (like GROUP BY)
-- B) Creates running total per customer
-- C) Filters only one customer
-- D) Sorts by customer then date
-- ANSWER: 

-- Q15. Which is faster for checking existence?
-- Option A: WHERE CustomerID IN (SELECT CustomerID FROM Orders)
-- Option B: WHERE EXISTS (SELECT 1 FROM Orders WHERE Orders.CustomerID = Customers.CustomerID)

-- A) Option A (IN)
-- B) Option B (EXISTS)
-- C) Same performance
-- D) Depends on data size
-- ANSWER: 

-- =============================================
-- SECTION C: Practical Application (3 points each)
-- =============================================

-- Q16. Write a CTE to find products above average price:



-- Q17. Write a query to rank employees by salary within each department:



-- Q18. Create a recursive CTE to generate numbers 1-10:



-- Q19. Find the top 3 products per category using window functions:



-- Q20. Calculate running total of sales per customer:



-- =============================================
-- ANSWER KEY (For Instructor)
-- =============================================
-- Q1: A | Q2: B | Q3: B | Q4: C | Q5: B
-- Q6: B | Q7: B | Q8: B | Q9: D | Q10: B
-- Q11: B | Q12: C | Q13: C | Q14: B | Q15: B

-- Grading:
-- 18-20: Excellent (90-100%)
-- 16-17: Good (80-89%)
-- 14-15: Pass (70-79%)
-- <14: Review material
