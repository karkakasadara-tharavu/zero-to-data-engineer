# SQL Fundamentals - Interview Insights & Tricks

## 🎯 Overview
This guide covers interview strategies for SQL basics, JOINs, aggregations, and subqueries - the foundation of every data engineering interview.

---

## Module 01: SQL Basics (SELECT, WHERE, ORDER BY)

### 💡 What Interviewers Really Test

| Concept | Surface Question | What They're Actually Testing |
|---------|------------------|-------------------------------|
| SELECT * | "Get all customers" | Do you know why SELECT * is bad in production? |
| WHERE clause | "Filter by date" | NULL handling, operator precedence |
| ORDER BY | "Sort results" | Performance impact, index usage |
| DISTINCT | "Get unique values" | Understanding of GROUP BY alternative |

### 🔥 Top Interview Tricks

#### Trick 1: Always Discuss NULL Handling
```sql
-- WRONG (misses NULL values)
SELECT * FROM employees WHERE department != 'Sales';

-- RIGHT (explicitly handles NULL)
SELECT * FROM employees 
WHERE department != 'Sales' OR department IS NULL;

-- INTERVIEW GOLD: Mention COALESCE
SELECT * FROM employees 
WHERE COALESCE(department, 'Unknown') != 'Sales';
```
**Why it impresses**: Shows you understand NULL is not a value, it's the absence of value.

#### Trick 2: Demonstrate Operator Precedence Knowledge
```sql
-- What does this return?
SELECT * FROM products 
WHERE category = 'Electronics' OR category = 'Books' AND price > 100;

-- Answer: ALL Electronics (any price) + Books over $100
-- Because AND has higher precedence than OR

-- To get both categories over $100:
SELECT * FROM products 
WHERE (category = 'Electronics' OR category = 'Books') AND price > 100;
```

#### Trick 3: Show Performance Awareness
```sql
-- BEGINNER answer
SELECT * FROM orders WHERE YEAR(order_date) = 2024;

-- EXPERT answer (SARGable - can use index)
SELECT * FROM orders 
WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01';
```
**Magic phrase**: "This is SARGable, so it can leverage an index on order_date."

### 🎤 Power Phrases to Use

| Situation | Say This |
|-----------|----------|
| Asked about SELECT * | "In production, I always specify columns explicitly for performance and maintainability" |
| Asked about filtering | "I'd ensure the WHERE clause is SARGable to leverage indexes" |
| Asked about NULL | "NULL requires special handling since NULL = NULL returns NULL, not TRUE" |

### ⚠️ Common Gotchas

1. **String Comparison**: `'abc' = 'ABC'` depends on collation settings
2. **Date Filtering**: Always use ISO format `'YYYY-MM-DD'` for portability
3. **BETWEEN**: It's inclusive on both ends (`BETWEEN 1 AND 10` includes 1 and 10)

---

## Module 02: JOINs (INNER, LEFT, RIGHT, FULL, CROSS)

### 💡 The JOIN Hierarchy (Know This Cold)

```
CROSS JOIN: Every combination (Cartesian product)
    ↓ + ON condition
INNER JOIN: Only matching rows
    ↓ + Keep non-matching from left
LEFT JOIN: All from left + matches from right
    ↓ + Keep non-matching from right  
FULL JOIN: All from both sides
```

### 🔥 Top Interview Tricks

#### Trick 1: The "Find Missing Records" Pattern
```sql
-- Classic interview question: "Find customers who never ordered"

-- GOOD answer (LEFT JOIN + NULL check)
SELECT c.*
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- BETTER answer (EXISTS - often faster)
SELECT c.*
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- EXPERT comment: "I'd check execution plans for both. 
-- LEFT JOIN is intuitive but NOT EXISTS often performs better 
-- because it can stop at first match."
```

#### Trick 2: Self-Join Mastery
```sql
-- "Find employees who earn more than their manager"
SELECT e.name AS employee, e.salary AS emp_salary,
       m.name AS manager, m.salary AS mgr_salary
FROM employees e
INNER JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

-- INTERVIEW INSIGHT: "This is a self-join pattern, 
-- common for hierarchical data before CTEs became standard"
```

#### Trick 3: The Multiple JOIN Order Trap
```sql
-- Does order matter?
SELECT *
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON o.product_id = p.product_id;

-- ANSWER: Logically no, but the optimizer reorders for performance.
-- HOWEVER, with OUTER joins, order DOES matter!

-- These are DIFFERENT:
-- 1. (A LEFT JOIN B) INNER JOIN C
-- 2. A LEFT JOIN (B INNER JOIN C)
```

#### Trick 4: The Accidental Cartesian Product
```sql
-- Spot the bug (common interview trick question):
SELECT o.order_id, p.product_name, d.discount_percent
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN discounts d;  -- Missing ON clause = CROSS JOIN!

-- Always verify: "I always double-check JOIN conditions 
-- to prevent accidental Cartesian products"
```

### 🎯 JOIN Interview Decision Tree

```
Q: "Do you need ALL records from the left table?"
├── YES → LEFT JOIN
│   └── "Do you need ALL from right too?" → YES → FULL JOIN
└── NO  → "Do you need every combination?"
    ├── YES → CROSS JOIN (rare, for generating data)
    └── NO  → INNER JOIN (most common)
```

### 🎤 Power Phrases for JOINs

| Question | Expert Response |
|----------|-----------------|
| "When use LEFT vs INNER?" | "LEFT when I need to preserve all records from the driving table, even without matches" |
| "What's a Cartesian product?" | "It's every possible row combination - useful for generating test data but dangerous in production if unintended" |
| "Optimize a slow JOIN?" | "Check join column indexes, filter early with WHERE, consider join order for outer joins" |

---

## Module 03: Aggregations (GROUP BY, HAVING)

### 💡 The Execution Order Secret

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY

Key insight: 
- WHERE filters BEFORE grouping (on raw rows)
- HAVING filters AFTER grouping (on aggregated results)
```

### 🔥 Top Interview Tricks

#### Trick 1: The WHERE vs HAVING Question
```sql
-- "Show categories with average price > 100, but only for active products"

-- WRONG (inefficient)
SELECT category, AVG(price) as avg_price
FROM products
GROUP BY category
HAVING AVG(price) > 100 AND status = 'active';  -- Error! Can't use non-aggregated column

-- RIGHT
SELECT category, AVG(price) as avg_price
FROM products
WHERE status = 'active'      -- Filter rows FIRST
GROUP BY category
HAVING AVG(price) > 100;     -- Filter groups AFTER

-- EXPERT INSIGHT: "Filtering in WHERE is more efficient 
-- because it reduces rows before aggregation"
```

#### Trick 2: COUNT(*) vs COUNT(column) vs COUNT(DISTINCT)
```sql
SELECT 
    COUNT(*) as total_rows,           -- Counts all rows including NULLs
    COUNT(email) as has_email,        -- Counts non-NULL emails
    COUNT(DISTINCT email) as unique_emails,  -- Counts unique non-NULL emails
    COUNT(DISTINCT CASE WHEN status = 'active' THEN email END) as active_unique
FROM customers;

-- INTERVIEW QUESTION: "Why might COUNT(*) and COUNT(column) differ?"
-- ANSWER: "COUNT(column) excludes NULL values"
```

#### Trick 3: The Running Total Trap
```sql
-- "Calculate running total of sales" (common question)

-- WRONG approach (correlated subquery - O(n²))
SELECT order_date, amount,
    (SELECT SUM(amount) FROM orders o2 
     WHERE o2.order_date <= o1.order_date) as running_total
FROM orders o1;

-- RIGHT approach (window function - O(n log n))
SELECT order_date, amount,
    SUM(amount) OVER (ORDER BY order_date) as running_total
FROM orders;

-- INSIGHT: "I'd use window functions for running calculations - 
-- they're optimized and more readable than correlated subqueries"
```

#### Trick 4: Aggregating with CASE
```sql
-- Pivot-style aggregation (very common interview question)
SELECT 
    customer_id,
    SUM(CASE WHEN YEAR(order_date) = 2023 THEN amount ELSE 0 END) as sales_2023,
    SUM(CASE WHEN YEAR(order_date) = 2024 THEN amount ELSE 0 END) as sales_2024,
    COUNT(CASE WHEN status = 'returned' THEN 1 END) as return_count
FROM orders
GROUP BY customer_id;

-- NOTE: COUNT(CASE...) - no ELSE needed, NULL is not counted
```

### 🎤 Aggregation Power Phrases

| Scenario | Expert Response |
|----------|-----------------|
| "Filter aggregates" | "I'd use HAVING for aggregate conditions, WHERE for row-level filtering before grouping" |
| "COUNT behavior" | "COUNT(*) includes NULLs, COUNT(column) excludes them, and COUNT(DISTINCT) gives unique non-NULL values" |
| "Performance" | "I always filter in WHERE when possible - reducing rows before aggregation is more efficient" |

---

## Module 04: Subqueries (Correlated, Derived Tables, CTEs)

### 💡 Subquery Types Hierarchy

```
SUBQUERY TYPES:
├── Scalar (returns single value)
│   └── Use in SELECT, WHERE with =, >, <
├── Row (returns single row, multiple columns)
│   └── Use with row constructors
├── Table (returns multiple rows/columns)
│   ├── Derived Table (in FROM clause)
│   ├── CTE (WITH clause)
│   └── Correlated (references outer query)
└── Lateral (can reference preceding FROM items)
```

### 🔥 Top Interview Tricks

#### Trick 1: Correlated vs Non-Correlated (Key Interview Topic)
```sql
-- NON-CORRELATED: Runs once, result cached
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);
-- The subquery runs once and returns a constant

-- CORRELATED: Runs for EACH outer row
SELECT * FROM products p
WHERE price > (SELECT AVG(price) FROM products WHERE category = p.category);
-- The subquery runs once per product, referencing p.category

-- INTERVIEW INSIGHT: "Correlated subqueries can be performance killers 
-- on large tables. I'd consider rewriting as a JOIN or window function"
```

#### Trick 2: Rewriting Correlated Subqueries
```sql
-- SLOW: Correlated subquery
SELECT e.name, e.salary, e.department
FROM employees e
WHERE e.salary = (
    SELECT MAX(salary) FROM employees 
    WHERE department = e.department
);

-- FAST: Window function approach
WITH ranked AS (
    SELECT name, salary, department,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rn
    FROM employees
)
SELECT name, salary, department
FROM ranked
WHERE rn = 1;

-- FAST: JOIN approach
SELECT e.name, e.salary, e.department
FROM employees e
INNER JOIN (
    SELECT department, MAX(salary) as max_sal
    FROM employees
    GROUP BY department
) dept_max ON e.department = dept_max.department 
           AND e.salary = dept_max.max_sal;
```

#### Trick 3: CTE vs Derived Table vs Temp Table
```sql
-- CTE (WITH clause) - Best for readability and recursion
WITH sales_summary AS (
    SELECT customer_id, SUM(amount) as total
    FROM orders GROUP BY customer_id
)
SELECT * FROM sales_summary WHERE total > 1000;

-- DERIVED TABLE - Inline, same performance as CTE
SELECT * FROM (
    SELECT customer_id, SUM(amount) as total
    FROM orders GROUP BY customer_id
) AS sales_summary WHERE total > 1000;

-- TEMP TABLE - When you need to reuse results multiple times
SELECT customer_id, SUM(amount) as total
INTO #sales_summary
FROM orders GROUP BY customer_id;
-- Can now use #sales_summary in multiple queries

-- INTERVIEW DECISION:
-- CTE: Readability, recursion, one-time use
-- Temp Table: Multiple references, large intermediate results
-- Derived Table: Simple inline needs
```

#### Trick 4: The EXISTS vs IN Trap
```sql
-- IN with subquery (can be slow with NULL values)
SELECT * FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- EXISTS (often faster, handles NULL better)
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- NOT IN DANGER: If subquery returns NULL, entire result is empty!
SELECT * FROM products
WHERE category_id NOT IN (SELECT category_id FROM categories);
-- If ANY category_id is NULL, returns NO rows!

-- SAFE alternative
SELECT * FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.category_id = p.category_id
);

-- INTERVIEW GOLD: "I avoid NOT IN with subqueries because NULL values 
-- can cause unexpected empty results. NOT EXISTS is safer."
```

#### Trick 5: Recursive CTEs (Advanced Interview Topic)
```sql
-- "Find all employees under a manager (hierarchy)"
WITH RECURSIVE emp_hierarchy AS (
    -- Base case: Start with the manager
    SELECT employee_id, name, manager_id, 1 as level
    FROM employees
    WHERE employee_id = 100  -- Top manager
    
    UNION ALL
    
    -- Recursive case: Find direct reports
    SELECT e.employee_id, e.name, e.manager_id, eh.level + 1
    FROM employees e
    INNER JOIN emp_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM emp_hierarchy;

-- INTERVIEW INSIGHT: "Recursive CTEs are perfect for hierarchical data - 
-- org charts, bill of materials, category trees"
```

### 🎯 Subquery Decision Framework

```
CHOOSING THE RIGHT APPROACH:

Need single value comparison? 
└── Scalar subquery or JOIN with aggregate

Need to check existence?
└── EXISTS (not IN, especially with NULLs)

Need to filter on aggregate?
├── Simple case → HAVING
└── Complex case → CTE/Derived table + WHERE

Need hierarchical traversal?
└── Recursive CTE

Need to reuse intermediate result?
├── Same query, readable → CTE
└── Multiple queries → Temp table
```

### 🎤 Subquery Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Correlated vs non-correlated?" | "Non-correlated runs once; correlated runs per row - I'd rewrite expensive correlated subqueries as JOINs or window functions" |
| "CTE vs subquery?" | "CTEs improve readability and enable recursion; performance is typically identical to derived tables" |
| "IN vs EXISTS?" | "EXISTS is generally faster and handles NULLs safely; NOT IN can return empty results if subquery contains NULL" |

---

## 📊 Module 1-4 Interview Cheat Sheet

### Quick Reference: What to Say

| Topic | Key Insight to Mention |
|-------|----------------------|
| SELECT * | "Bad for production - use explicit columns" |
| NULL | "NULL comparisons need IS NULL/IS NOT NULL" |
| WHERE | "Should be SARGable for index usage" |
| JOINs | "Understand implicit Cartesian product risk" |
| LEFT JOIN + NULL | "Pattern for finding missing records" |
| Aggregations | "WHERE filters rows, HAVING filters groups" |
| COUNT | "COUNT(*) includes NULLs, COUNT(col) excludes" |
| Correlated subquery | "Consider rewriting as JOIN or window function" |
| NOT IN | "Dangerous with NULLs, use NOT EXISTS instead" |

### Red Flags Interviewers Watch For

❌ Using SELECT * in production code  
❌ Not considering NULL handling  
❌ Using functions on indexed columns in WHERE  
❌ Confusing WHERE and HAVING  
❌ Using NOT IN without NULL consideration  
❌ Not knowing correlated subquery performance impact  

### Green Flags That Impress

✅ Mentioning SARGability  
✅ Discussing execution order  
✅ Suggesting alternatives (EXISTS vs IN)  
✅ Considering edge cases (NULLs, empty sets)  
✅ Mentioning performance implications  
✅ Knowing when to use CTEs vs temp tables  

---

## 🎯 Practice Questions

### Easy
1. Write a query to find customers with no email address (NULL)
2. Get the top 5 most expensive products per category
3. Find departments where average salary exceeds company average

### Medium
4. Find customers who ordered in 2023 but not in 2024
5. Calculate each employee's salary as percentage of department total
6. List products that have never been ordered

### Hard
7. Find the second highest salary in each department (handle ties)
8. Identify customers whose order count increased month over month
9. Build an organization hierarchy showing reporting depth

---

*"The difference between a junior and senior engineer isn't knowing the syntax—it's understanding the implications."*
