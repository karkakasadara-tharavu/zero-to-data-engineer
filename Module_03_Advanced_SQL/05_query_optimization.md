# Section 05: Query Optimization Basics

**Estimated Time**: 5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate-Advanced  

---

## 🎯 Learning Objectives

✅ Understand SQL Server query execution order  
✅ Write efficient WHERE clauses  
✅ Use SARGable predicates  
✅ Avoid common anti-patterns  
✅ Optimize JOINs and subqueries  
✅ Understand statistics and cardinality  

---

## ⚙️ Query Execution Order

**What you write** (Logical Order):
```sql
SELECT columns
FROM table1
JOIN table2
WHERE conditions
GROUP BY columns
HAVING group_conditions
ORDER BY columns
```

**How SQL Server executes** (Physical Order):
1. **FROM** - Load tables
2. **JOIN** - Combine tables
3. **WHERE** - Filter rows (before grouping)
4. **GROUP BY** - Aggregate
5. **HAVING** - Filter groups (after grouping)
6. **SELECT** - Choose columns
7. **DISTINCT** - Remove duplicates
8. **ORDER BY** - Sort results
9. **TOP/OFFSET** - Limit rows

**Why it matters**: Filtering early (WHERE) is faster than filtering late (HAVING on ungrouped data).

---

## 🚀 SARGable Queries

**SARGable** = Search ARGument ABLE (can use indexes efficiently)

### ❌ Non-SARGable (Slow - Can't use indexes)

```sql
-- Function on column prevents index usage
WHERE YEAR(OrderDate) = 2008

-- Calculation on column
WHERE Quantity * 2 > 100

-- Leading wildcard
WHERE Name LIKE '%Bike'

-- NOT equals (forces scan)
WHERE Status <> 'Completed'
```

### ✅ SARGable (Fast - Can use indexes)

```sql
-- Range on column (not function)
WHERE OrderDate >= '2008-01-01' AND OrderDate < '2009-01-01'

-- Calculation on value side
WHERE Quantity > 50

-- Trailing wildcard
WHERE Name LIKE 'Bike%'

-- Positive equality
WHERE Status = 'Completed' OR Status = 'Pending'
-- Better: WHERE Status IN ('Completed', 'Pending')
```

---

## ⚡ JOIN Optimization

### Best Practices

```sql
-- ✅ GOOD: Filter before JOIN
SELECT o.OrderID, c.CustomerName
FROM Orders o
INNER JOIN (SELECT CustomerID, CustomerName FROM Customers WHERE Region = 'West') c
    ON o.CustomerID = c.CustomerID;

-- ❌ BAD: Filter after JOIN (processes more rows)
SELECT o.OrderID, c.CustomerName
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.Region = 'West';
```

**Tip**: SQL Server optimizer often rewrites these the same way, but being explicit helps readability.

---

## 📊 SELECT * is Evil

```sql
-- ❌ BAD: Retrieves unnecessary data
SELECT * FROM LargeTable WHERE ID = 100;

-- ✅ GOOD: Only needed columns
SELECT ID, Name, Price FROM LargeTable WHERE ID = 100;
```

**Why**:
- Network overhead (more data transferred)
- Memory usage (larger result sets)
- Prevents covering indexes
- Breaks client code when schema changes

---

## 🎯 Subquery vs JOIN vs EXISTS

```sql
-- Goal: Find customers who placed orders

-- Option 1: IN with subquery (OK for small lists)
SELECT * FROM Customers
WHERE CustomerID IN (SELECT CustomerID FROM Orders);

-- Option 2: EXISTS (Best for large datasets)
SELECT * FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID);

-- Option 3: DISTINCT JOIN (Avoid if possible)
SELECT DISTINCT c.* 
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;
```

**Performance**:
- **EXISTS**: Stops at first match (fastest for existence checks)
- **IN**: Evaluates all subquery results
- **JOIN + DISTINCT**: Processes all joins then removes duplicates (slowest)

---

## 🔍 Statistics and Cardinality

**Statistics** = SQL Server's knowledge about data distribution.

**Cardinality** = Estimated number of rows returned.

```sql
-- Update statistics (improves query plans)
UPDATE STATISTICS SalesLT.Customer;

-- View statistics
DBCC SHOW_STATISTICS ('SalesLT.Customer', PK_Customer_CustomerID);
```

**Why it matters**: Outdated statistics → bad query plans → slow queries.

---

## 📝 Lab 15: Query Optimization

Complete `labs/lab_15_optimization.sql`.

**Tasks**:
1. Identify non-SARGable queries and fix them
2. Optimize JOINs by filtering first
3. Replace SELECT * with specific columns
4. Convert IN to EXISTS for performance
5. Rewrite function-on-column WHERE clauses

---

**Next**: [Section 06: Execution Plans →](./06_execution_plans.md)
