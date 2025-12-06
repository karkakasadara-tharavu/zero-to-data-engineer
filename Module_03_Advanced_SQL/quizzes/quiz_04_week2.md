-- Quiz 04: Optimization and Advanced Techniques (Week 2)
-- Module 03: Advanced SQL
-- Time: 30 minutes | Questions: 20 | Passing: 70%

-- =============================================
-- SECTION A: Multiple Choice (1 point each)
-- =============================================

-- Q1. What does SARGable mean?
-- A) Search ARGument ABLE (can use indexes)
-- B) SQL ARGument BLE (best logic evaluation)
-- C) Scan ARGument TABLE
-- D) Systematic ARGument BASE
-- ANSWER: 

-- Q2. Which query is SARGable?
-- A) WHERE YEAR(OrderDate) = 2023
-- B) WHERE OrderDate >= '2023-01-01' AND OrderDate < '2024-01-01'
-- C) WHERE UPPER(Name) = 'BIKE'
-- D) WHERE Price * 1.1 > 100
-- ANSWER: 

-- Q3. What is a clustered index?
-- A) Index with multiple columns
-- B) Physical row order of table
-- C) Index stored separately from table
-- D) Index on foreign key
-- ANSWER: 

-- Q4. How many clustered indexes per table?
-- A) Unlimited
-- B) One per column
-- C) Only one
-- D) Two (primary and secondary)
-- ANSWER: 

-- Q5. What does an Index Seek indicate?
-- A) Fast lookup using index
-- B) Full table scan
-- C) Missing index
-- D) Slow query
-- ANSWER: 

-- Q6. What is index fragmentation?
-- A) Index corruption requiring rebuild
-- B) Scattered index pages reducing performance
-- C) Too many indexes on one table
-- D) Missing statistics
-- ANSWER: 

-- Q7. Which operator shows estimated vs actual rows in execution plan?
-- A) Table Scan
-- B) Sort
-- C) All operators
-- D) Clustered Index Seek only
-- ANSWER: 

-- Q8. What does INCLUDE do in a nonclustered index?
-- A) Adds non-key columns to leaf level
-- B) Forces index usage
-- C) Creates clustered index
-- D) Enables full-text search
-- ANSWER: 

-- Q9. Which is fastest for existence check?
-- A) IN
-- B) EXISTS
-- C) JOIN + DISTINCT
-- D) LEFT JOIN with NULL check
-- ANSWER: 

-- Q10. What does PIVOT do?
-- A) Rotates rows to columns
-- B) Sorts data
-- C) Joins tables
-- D) Creates indexed view
-- ANSWER: 

-- =============================================
-- SECTION B: Code Analysis (2 points each)
-- =============================================

-- Q11. Identify the performance issue:
SELECT * FROM Orders WHERE YEAR(OrderDate) = 2023;

-- A) SELECT *
-- B) Non-SARGable WHERE
-- C) Missing index
-- D) Both A and B
-- ANSWER: 

-- Q12. What's wrong with this index strategy?
CREATE INDEX IX_1 ON Products(Name);
CREATE INDEX IX_2 ON Products(Name, Price);
CREATE INDEX IX_3 ON Products(Name, Price, Color);

-- A) Nothing wrong
-- B) Over-indexing (too many similar indexes)
-- C) Missing clustered index
-- D) Wrong column order
-- ANSWER: 

-- Q13. Which execution plan operator is most expensive?
-- Table Scan (cost: 0.50) → Sort (cost: 0.30) → Nested Loops (cost: 0.15)

-- A) Table Scan
-- B) Sort
-- C) Nested Loops
-- D) All equal
-- ANSWER: 

-- Q14. What does this statistics output indicate?
-- Rows Read: 1,000,000 | Rows Returned: 10

-- A) Good selectivity, might need index
-- B) Bad query
-- C) Table too large
-- D) Index fragmentation
-- ANSWER: 

-- Q15. When should you rebuild an index?
-- A) Fragmentation < 10%
-- B) Fragmentation 10-30%
-- C) Fragmentation > 30%
-- D) Every day
-- ANSWER: 

-- =============================================
-- SECTION C: Practical Application (3 points each)
-- =============================================

-- Q16. Rewrite this to be SARGable:
-- SELECT * FROM Sales WHERE DATEPART(YEAR, OrderDate) = 2023



-- Q17. Write a query to check index fragmentation for table 'Orders':



-- Q18. Create a covering index for this query:
-- SELECT OrderID, CustomerID, OrderDate FROM Orders WHERE CustomerID = 100



-- Q19. Optimize this query (identify 3 improvements):
-- SELECT DISTINCT * FROM Products p
-- JOIN Categories c ON p.CategoryID = c.CategoryID
-- WHERE YEAR(p.CreatedDate) = 2023
-- ORDER BY p.Name

-- Improvement 1: 
-- Improvement 2: 
-- Improvement 3: 

-- Q20. Write a PIVOT query to show monthly sales by year:
-- Source: Orders(OrderDate, Total)
-- Output: Year | Jan | Feb | Mar | ... | Dec



-- =============================================
-- ANSWER KEY (For Instructor)
-- =============================================
-- Q1: A | Q2: B | Q3: B | Q4: C | Q5: A
-- Q6: B | Q7: C | Q8: A | Q9: B | Q10: A
-- Q11: D | Q12: B | Q13: A | Q14: A | Q15: C

-- Q16: WHERE OrderDate >= '2023-01-01' AND OrderDate < '2024-01-01'
-- Q17: SELECT avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats(...)
-- Q18: CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID) INCLUDE (OrderID, OrderDate)
-- Q19: Remove *, Remove DISTINCT, Use date range instead of YEAR()
-- Q20: Use PIVOT with MONTH(OrderDate) FOR Month IN ([1],...[12])

-- Grading:
-- 18-20: Excellent (90-100%)
-- 16-17: Good (80-89%)
-- 14-15: Pass (70-79%)
-- <14: Review material
