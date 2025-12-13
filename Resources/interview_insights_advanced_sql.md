# Advanced SQL - Interview Insights & Tricks

## 🎯 Overview
This guide covers Window Functions, ETL/SSIS, Stored Procedures, and Query Optimization - the advanced topics that separate senior candidates from juniors.

---

## Module 05: Window Functions

### 💡 Why Window Functions Are Interview Gold

Window functions are **the #1 most asked advanced SQL topic** because they:
- Test analytical thinking
- Show performance awareness
- Reveal experience with real-world data problems

### 🔥 Top Interview Tricks

#### Trick 1: The OVER() Clause Breakdown
```sql
-- Master this syntax pattern:
function_name() OVER (
    PARTITION BY column(s)     -- Optional: Create groups
    ORDER BY column(s)         -- Optional for some functions
    ROWS/RANGE frame_clause    -- Optional: Define window frame
)

-- INTERVIEW INSIGHT: Not all combinations are valid!
-- Aggregate functions without ORDER BY = entire partition
-- Aggregate functions with ORDER BY = running calculation
```

#### Trick 2: ROW_NUMBER vs RANK vs DENSE_RANK (Always Asked!)
```sql
-- Given: Sales amounts: 100, 100, 90, 80

SELECT 
    amount,
    ROW_NUMBER() OVER (ORDER BY amount DESC) as row_num,   -- 1,2,3,4 (always unique)
    RANK() OVER (ORDER BY amount DESC) as rank_num,        -- 1,1,3,4 (skip after tie)
    DENSE_RANK() OVER (ORDER BY amount DESC) as dense_num  -- 1,1,2,3 (no skip)
FROM sales;

-- RESULTS:
-- amount | row_num | rank_num | dense_num
-- 100    |    1    |    1     |     1
-- 100    |    2    |    1     |     1
--  90    |    3    |    3     |     2  ← Notice RANK skips 2
--  80    |    4    |    4     |     3
```

**Interview Question**: "Which do you use to find top N per group?"
```sql
-- Answer depends on tie handling:
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) as rn
    FROM products
)
SELECT * FROM ranked WHERE rn <= 3;  -- Exactly 3 per category

-- vs
WITH ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY sales DESC) as dr
    FROM products
)
SELECT * FROM ranked WHERE dr <= 3;  -- Top 3 ranks (might be >3 rows if ties)
```

#### Trick 3: Running Totals and Moving Averages
```sql
-- Running total (cumulative sum)
SUM(amount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING)

-- Moving average (last 7 days)
AVG(amount) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)

-- Moving average (current +/- 3 days)
AVG(amount) OVER (ORDER BY date ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING)

-- INTERVIEW TRICK: Explain ROWS vs RANGE
-- ROWS: Physical row count
-- RANGE: Logical value range (handles duplicates differently)

SELECT order_date, amount,
    SUM(amount) OVER (ORDER BY order_date ROWS UNBOUNDED PRECEDING) as rows_sum,
    SUM(amount) OVER (ORDER BY order_date RANGE UNBOUNDED PRECEDING) as range_sum
FROM orders;
-- If duplicate dates exist, RANGE includes all of them together!
```

#### Trick 4: LAG and LEAD (Period-Over-Period Analysis)
```sql
-- Classic interview question: "Calculate month-over-month growth"
SELECT 
    month,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY month) as prev_month,
    revenue - LAG(revenue, 1) OVER (ORDER BY month) as mom_change,
    ROUND(
        (revenue - LAG(revenue, 1) OVER (ORDER BY month)) * 100.0 / 
        NULLIF(LAG(revenue, 1) OVER (ORDER BY month), 0)
    , 2) as mom_growth_pct
FROM monthly_revenue;

-- EXPERT TIP: Handle first row with COALESCE or default value
LAG(revenue, 1, 0) OVER (ORDER BY month)  -- Default to 0 if no prior row
```

#### Trick 5: FIRST_VALUE, LAST_VALUE, NTH_VALUE
```sql
-- Get first and last order per customer
SELECT 
    customer_id,
    order_date,
    order_id,
    FIRST_VALUE(order_id) OVER (
        PARTITION BY customer_id ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as first_order,
    LAST_VALUE(order_id) OVER (
        PARTITION BY customer_id ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as last_order
FROM orders;

-- GOTCHA: LAST_VALUE default frame is "UNBOUNDED PRECEDING TO CURRENT ROW"
-- You MUST specify full frame for true last value!
```

### 🎯 Window Function Decision Tree

```
WHAT DO YOU NEED?

Ranking?
├── Unique numbers → ROW_NUMBER()
├── Skip after ties → RANK()
└── No skip → DENSE_RANK()

Previous/Next row value?
├── Previous → LAG(col, n)
└── Next → LEAD(col, n)

Running calculation?
├── Running total → SUM() OVER (ORDER BY ...)
├── Running count → COUNT() OVER (ORDER BY ...)
└── Running average → AVG() OVER (ORDER BY ...)

Moving window?
└── Use ROWS BETWEEN n PRECEDING AND m FOLLOWING

First/Last in group?
├── First → FIRST_VALUE()
├── Last → LAST_VALUE() (with proper frame!)
└── Nth → NTH_VALUE(col, n)

Percentile/Distribution?
├── Percentile rank → PERCENT_RANK()
├── Cumulative distribution → CUME_DIST()
└── Divide into buckets → NTILE(n)
```

### 🎤 Window Function Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Why window functions?" | "They calculate across rows while preserving row-level detail, unlike GROUP BY which collapses rows" |
| "Performance?" | "Generally O(n log n) due to sorting; I'd ensure ORDER BY columns are indexed" |
| "ROWS vs RANGE?" | "ROWS counts physical rows; RANGE handles duplicates together - critical for running totals with duplicate keys" |

---

## Module 06: ETL & SSIS

### 💡 ETL Interview Focus Areas

ETL questions test:
- Understanding of data pipeline design
- Error handling and logging strategies
- Performance optimization
- Data quality concepts

### 🔥 Top Interview Tricks

#### Trick 1: The ETL vs ELT Question
```
ETL (Extract-Transform-Load):
├── Transform in separate engine (SSIS, Informatica)
├── Good when: Target can't do heavy processing
├── Good when: Complex transformations needed
└── Traditional data warehouse approach

ELT (Extract-Load-Transform):
├── Transform in target database (SQL, Spark)
├── Good when: Target is powerful (cloud DW, Spark)
├── Good when: Transformations are SQL-based
└── Modern cloud data platform approach

INTERVIEW ANSWER: "It depends on the target system. For cloud 
data warehouses like Snowflake or BigQuery, I'd use ELT to 
leverage their compute power. For on-prem or when the target 
is resource-constrained, traditional ETL makes sense."
```

#### Trick 2: Incremental Load Strategies
```sql
-- Strategy 1: Watermark/High Water Mark
-- Track the last processed timestamp
DECLARE @LastLoadTime DATETIME = (SELECT MAX(load_time) FROM audit_log);

INSERT INTO target_table
SELECT * FROM source_table
WHERE modified_date > @LastLoadTime;

-- Strategy 2: Change Data Capture (CDC)
-- Database tracks changes automatically
SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_orders(
    @from_lsn, @to_lsn, 'all'
);

-- Strategy 3: Hash Comparison
-- Compare hash of key columns to detect changes
SELECT s.*
FROM source s
LEFT JOIN target t ON s.id = t.id
WHERE t.id IS NULL  -- New records
   OR HASHBYTES('SHA2_256', CONCAT(s.col1, s.col2)) != t.row_hash;  -- Changed

-- INTERVIEW INSIGHT: "I prefer CDC when available because it's 
-- reliable and captures deletes. Watermark works for append-only 
-- or when modified_date is trustworthy."
```

#### Trick 3: Error Handling Strategies
```sql
-- SSIS Pattern: Error row redirection
-- Route failed rows to error table with error details

-- SQL Pattern: TRY-CATCH with transaction
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- ETL Operations
    INSERT INTO target SELECT * FROM staging;
    
    -- Log success
    INSERT INTO etl_log (status, rows_affected)
    VALUES ('SUCCESS', @@ROWCOUNT);
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    -- Log failure
    INSERT INTO etl_log (status, error_message, error_line)
    VALUES ('FAILED', ERROR_MESSAGE(), ERROR_LINE());
    
    -- Re-raise for alerting
    THROW;
END CATCH;

-- INTERVIEW INSIGHT: "I always implement error redirection for 
-- row-level issues and transaction rollback for batch failures. 
-- The key is logging enough detail to diagnose issues."
```

#### Trick 4: Data Quality Checks
```sql
-- Pre-load validation
SELECT 
    'Row Count Check' as check_name,
    CASE WHEN COUNT(*) BETWEEN @expected_min AND @expected_max 
         THEN 'PASS' ELSE 'FAIL' END as status
FROM staging_table

UNION ALL

SELECT 
    'Null Check - Required Fields',
    CASE WHEN SUM(CASE WHEN required_col IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM staging_table

UNION ALL

SELECT 
    'Duplicate Check',
    CASE WHEN COUNT(*) = COUNT(DISTINCT business_key)
         THEN 'PASS' ELSE 'FAIL' END
FROM staging_table

UNION ALL

SELECT 
    'Referential Integrity Check',
    CASE WHEN NOT EXISTS (
        SELECT 1 FROM staging_table s
        LEFT JOIN reference_table r ON s.ref_id = r.id
        WHERE r.id IS NULL
    ) THEN 'PASS' ELSE 'FAIL' END;

-- INTERVIEW INSIGHT: "Data quality gates should be automated 
-- and block bad data from entering production. I implement 
-- both technical checks and business rule validations."
```

#### Trick 5: Slowly Changing Dimensions (SCD)
```sql
-- SCD Type 1: Overwrite (no history)
UPDATE dim_customer SET address = 'New Address' WHERE id = 123;

-- SCD Type 2: Add row (full history)
-- Close current record
UPDATE dim_customer 
SET end_date = GETDATE(), is_current = 0
WHERE id = 123 AND is_current = 1;

-- Insert new version
INSERT INTO dim_customer (id, address, start_date, end_date, is_current)
VALUES (123, 'New Address', GETDATE(), '9999-12-31', 1);

-- SCD Type 3: Add column (limited history)
UPDATE dim_customer 
SET previous_address = current_address,
    current_address = 'New Address'
WHERE id = 123;

-- INTERVIEW INSIGHT: "SCD Type 2 is most common in data warehousing 
-- because it preserves full history for accurate point-in-time reporting."
```

### 🎤 ETL Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "ETL vs ELT?" | "ELT for powerful targets like cloud DWs; ETL when transformation engine is separate or more powerful" |
| "Handle failures?" | "Idempotent loads with error redirection, transaction boundaries, and detailed logging" |
| "Incremental loads?" | "CDC when available, watermark for append-only, hash comparison for detecting changes" |
| "Data quality?" | "Automated gates that block bad data, with notifications and self-healing where possible" |

---

## Module 07: Stored Procedures & Transactions

### 💡 Interview Focus Areas

Stored procedures test:
- Transaction management
- Error handling patterns
- Performance considerations
- Security awareness

### 🔥 Top Interview Tricks

#### Trick 1: ACID Properties (Know Cold!)
```
A - Atomicity:    All or nothing
C - Consistency:  Valid state to valid state
I - Isolation:    Concurrent transactions don't interfere
D - Durability:   Committed data survives failures

INTERVIEW QUESTION: "What isolation level would you use?"

READ UNCOMMITTED: Fastest, dirty reads possible
READ COMMITTED:   Default, no dirty reads
REPEATABLE READ:  Locks rows read until commit
SERIALIZABLE:     Locks entire range, slowest

ANSWER: "It depends on the use case. For reporting, READ COMMITTED 
is usually fine. For financial transactions, SERIALIZABLE ensures 
accuracy. For read-heavy workloads, I'd consider READ COMMITTED 
SNAPSHOT to avoid blocking."
```

#### Trick 2: Transaction Template (Use This Pattern)
```sql
CREATE PROCEDURE usp_ProcessOrder
    @OrderID INT,
    @Result NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- Auto-rollback on error
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validation
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @OrderID)
        BEGIN
            SET @Result = 'Order not found';
            RETURN -1;
        END
        
        -- Business logic
        UPDATE Orders SET Status = 'Processing' WHERE OrderID = @OrderID;
        UPDATE Inventory SET Quantity = Quantity - 1 WHERE ProductID = @ProductID;
        INSERT INTO OrderLog (OrderID, Action) VALUES (@OrderID, 'Processed');
        
        COMMIT TRANSACTION;
        SET @Result = 'Success';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @Result = ERROR_MESSAGE();
        
        -- Log error
        INSERT INTO ErrorLog (ProcName, ErrorMessage, ErrorLine)
        VALUES ('usp_ProcessOrder', ERROR_MESSAGE(), ERROR_LINE());
        
        RETURN -1;
    END CATCH
END;
```

#### Trick 3: Avoiding Deadlocks
```sql
-- DEADLOCK SCENARIO:
-- Session 1: Lock A, then try to lock B
-- Session 2: Lock B, then try to lock A
-- DEADLOCK!

-- PREVENTION STRATEGIES:

-- 1. Consistent lock order
-- Always access tables in same order (alphabetical)
UPDATE Customers SET ... -- First
UPDATE Orders SET ...    -- Second

-- 2. Keep transactions short
-- Don't do slow operations inside transactions

-- 3. Use appropriate isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED SNAPSHOT;

-- 4. Use NOLOCK hint for reporting (carefully!)
SELECT * FROM LargeTable WITH (NOLOCK);  -- May read uncommitted data

-- INTERVIEW INSIGHT: "I prevent deadlocks by keeping transactions 
-- short, accessing tables in consistent order, and using appropriate 
-- isolation levels. For read-heavy workloads, SNAPSHOT isolation 
-- eliminates reader-writer blocking."
```

#### Trick 4: Dynamic SQL (Security Aware)
```sql
-- WRONG: SQL Injection vulnerable
EXEC('SELECT * FROM Users WHERE Name = ''' + @UserInput + '''');

-- RIGHT: Parameterized
EXEC sp_executesql 
    N'SELECT * FROM Users WHERE Name = @Name',
    N'@Name NVARCHAR(100)',
    @Name = @UserInput;

-- INTERVIEW INSIGHT: "I always use sp_executesql with parameters 
-- for dynamic SQL. It prevents injection and allows execution plan reuse."
```

---

## Module 08: Query Optimization

### 💡 The Performance Interview

Optimization questions reveal:
- Understanding of database internals
- Real-world troubleshooting experience
- Ability to balance competing concerns

### 🔥 Top Interview Tricks

#### Trick 1: Reading Execution Plans
```
KEY OPERATORS TO KNOW:

Table Scan:        BAD - reads entire table
Index Scan:        OK - reads entire index
Index Seek:        GOOD - direct lookup
Key Lookup:        Consider - might need covering index
Hash Match:        OK for large joins
Nested Loops:      OK for small outer table
Sort:              Consider - might indicate missing index

WHAT TO LOOK FOR:
1. Thick arrows = many rows (potential problem)
2. Warnings (yellow triangle) = spills, implicit conversions
3. Estimated vs Actual rows mismatch = stats issue
```

#### Trick 2: The SARGability Rule
```sql
-- SARGABLE (Search ARGument ABLE) - Can use index
WHERE column = 'value'
WHERE column > 100
WHERE column BETWEEN 1 AND 100
WHERE column LIKE 'prefix%'
WHERE column IN (1, 2, 3)

-- NON-SARGABLE - Cannot use index efficiently
WHERE YEAR(column) = 2024           -- Function on column
WHERE column + 1 = 100              -- Expression on column
WHERE column LIKE '%suffix'         -- Leading wildcard
WHERE ISNULL(column, '') = 'value'  -- Function on column

-- FIX: Rewrite non-SARGable conditions
-- Instead of:
WHERE YEAR(order_date) = 2024
-- Use:
WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'

-- INTERVIEW PHRASE: "I always check if my WHERE conditions are 
-- SARGable because applying functions to columns prevents index usage."
```

#### Trick 3: Index Strategy
```sql
-- CLUSTERED vs NON-CLUSTERED
-- Clustered: Physical row order, one per table
-- Non-clustered: Pointer to rows, many per table

-- COVERING INDEX (very important concept!)
-- Include all columns needed by query
CREATE NONCLUSTERED INDEX IX_Orders_Customer
ON Orders (CustomerID)
INCLUDE (OrderDate, TotalAmount);

-- Query that's now "covered" (no key lookup needed)
SELECT CustomerID, OrderDate, TotalAmount
FROM Orders
WHERE CustomerID = 123;

-- INTERVIEW INSIGHT: "I use covering indexes to eliminate 
-- key lookups. The INCLUDE clause adds columns without affecting 
-- index key sort order."
```

#### Trick 4: The Optimization Checklist
```
WHEN QUERY IS SLOW:

1. EXECUTION PLAN
   □ Any table scans that should be seeks?
   □ Any key lookups that could be eliminated?
   □ Estimated vs Actual rows match?
   □ Any warnings?

2. STATISTICS
   □ Are stats up to date?
   □ UPDATE STATISTICS if needed

3. QUERY STRUCTURE
   □ All conditions SARGable?
   □ Using EXISTS vs IN where appropriate?
   □ Filtering early (in WHERE, not HAVING)?

4. INDEXES
   □ Missing indexes suggested by plan?
   □ Existing indexes being used?
   □ Consider covering indexes?

5. DESIGN
   □ Can query be rewritten?
   □ Would temp table help for complex joins?
   □ Is there a better algorithm?
```

#### Trick 5: Common Anti-Patterns and Fixes
```sql
-- ANTI-PATTERN 1: SELECT *
SELECT * FROM Orders o JOIN Customers c ON o.CustomerID = c.CustomerID;
-- FIX: Select only needed columns
SELECT o.OrderID, o.OrderDate, c.Name FROM ...

-- ANTI-PATTERN 2: Correlated subquery
SELECT *, (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID)
FROM Customers c;
-- FIX: Use JOIN or window function
SELECT c.*, o.MaxOrderDate
FROM Customers c
LEFT JOIN (
    SELECT CustomerID, MAX(OrderDate) as MaxOrderDate
    FROM Orders GROUP BY CustomerID
) o ON c.CustomerID = o.CustomerID;

-- ANTI-PATTERN 3: OR conditions on different columns
WHERE FirstName = 'John' OR LastName = 'Smith';
-- FIX: Use UNION
SELECT * FROM Customers WHERE FirstName = 'John'
UNION
SELECT * FROM Customers WHERE LastName = 'Smith';

-- ANTI-PATTERN 4: NOT IN with subquery
WHERE ID NOT IN (SELECT ID FROM Table2);
-- FIX: Use NOT EXISTS
WHERE NOT EXISTS (SELECT 1 FROM Table2 WHERE Table2.ID = Table1.ID);
```

### 🎤 Optimization Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Slow query?" | "I'd check execution plan for scans vs seeks, verify stats, ensure SARGability, consider covering indexes" |
| "Missing index?" | "I look at execution plan recommendations but evaluate trade-off with write performance" |
| "Parameter sniffing?" | "Use OPTION (RECOMPILE) for variable data distribution, or OPTIMIZE FOR UNKNOWN" |

---

## 📊 Modules 5-8 Quick Reference

### Window Functions Cheat Sheet
```sql
ROW_NUMBER()  -- Unique sequential
RANK()        -- Skip after ties
DENSE_RANK()  -- No skip
LAG/LEAD      -- Previous/next row
SUM() OVER    -- Running total
FIRST_VALUE   -- First in window
```

### ETL Principles
- Idempotent: Same input → same output
- Incremental: Process only changes
- Auditable: Full logging
- Recoverable: Can restart from failure

### Transaction Guidelines
- Keep transactions short
- Use consistent table access order
- Handle errors with TRY-CATCH
- Log everything

### Optimization Rules
1. Make WHERE conditions SARGable
2. Use covering indexes for frequent queries
3. Avoid SELECT *
4. Check execution plans
5. Keep statistics updated

---

*"Anyone can write SQL that works. Senior engineers write SQL that scales."*
