# Section 01: Common Table Expressions (CTEs)

**Estimated Time**: 5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate-Advanced  
**Prerequisites**: Module 02 Subqueries complete

---

## 🎯 Learning Objectives

✅ Understand what CTEs are and when to use them  
✅ Write single and multiple CTEs  
✅ Use CTEs for improved query readability  
✅ Compare CTEs vs subqueries vs temp tables  
✅ Chain multiple CTEs together  
✅ Apply CTEs in real-world scenarios  

---

## 📚 What is a CTE?

**CTE** (Common Table Expression) = Temporary named result set that exists only during query execution.

**Think of it as**: A "named subquery" that makes complex queries more readable.

**Syntax**:
```sql
WITH CTE_Name AS (
    SELECT columns
    FROM table
    WHERE conditions
)
SELECT * FROM CTE_Name;
```

---

## 🔍 Why Use CTEs?

### ❌ Without CTE (Subquery)
```sql
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    OrderStats.TotalOrders,
    OrderStats.TotalSpent
FROM SalesLT.Customer c
INNER JOIN (
    SELECT 
        CustomerID,
        COUNT(*) AS TotalOrders,
        SUM(TotalDue) AS TotalSpent
    FROM SalesLT.SalesOrderHeader
    GROUP BY CustomerID
) AS OrderStats ON c.CustomerID = OrderStats.CustomerID;
```
**Problem**: Subquery is buried in the middle, hard to read.

### ✅ With CTE
```sql
WITH OrderStats AS (
    SELECT 
        CustomerID,
        COUNT(*) AS TotalOrders,
        SUM(TotalDue) AS TotalSpent
    FROM SalesLT.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    os.TotalOrders,
    os.TotalSpent
FROM SalesLT.Customer c
INNER JOIN OrderStats os ON c.CustomerID = os.CustomerID;
```
**Benefits**: 
- Named, reusable within query
- Reads top-to-bottom (like a recipe)
- Can be referenced multiple times
- Easier to debug

---

## 🎨 Basic CTE Examples

### Example 1: Simple CTE

```sql
-- Calculate average order value, then find orders above average
WITH AvgOrderCTE AS (
    SELECT AVG(TotalDue) AS AvgOrderValue
    FROM SalesLT.SalesOrderHeader
)
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    aoc.AvgOrderValue,
    soh.TotalDue - aoc.AvgOrderValue AS DifferenceFromAvg
FROM SalesLT.SalesOrderHeader soh
CROSS JOIN AvgOrderCTE aoc
WHERE soh.TotalDue > aoc.AvgOrderValue
ORDER BY soh.TotalDue DESC;
```

**Explanation**: CTE calculates average once, then main query uses it.

---

### Example 2: Multiple CTEs

```sql
-- Chain multiple CTEs with commas
WITH 
-- CTE 1: Customer order stats
CustomerOrders AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalDue) AS TotalSpent
    FROM SalesLT.SalesOrderHeader
    GROUP BY CustomerID
),
-- CTE 2: High-value customers (uses CTE 1)
HighValueCustomers AS (
    SELECT CustomerID, OrderCount, TotalSpent
    FROM CustomerOrders
    WHERE TotalSpent > 5000
)
-- Main query uses both CTEs
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    hvc.OrderCount,
    hvc.TotalSpent,
    hvc.TotalSpent / hvc.OrderCount AS AvgOrderValue
FROM HighValueCustomers hvc
INNER JOIN SalesLT.Customer c ON hvc.CustomerID = c.CustomerID
ORDER BY hvc.TotalSpent DESC;
```

**Key Point**: CTEs are separated by commas, defined top-to-bottom, used in main query.

---

### Example 3: CTE Referenced Multiple Times

```sql
WITH ProductSales AS (
    SELECT 
        p.ProductID,
        p.Name,
        COUNT(sod.SalesOrderDetailID) AS TimesSold,
        SUM(sod.OrderQty) AS TotalQuantity,
        SUM(sod.LineTotal) AS TotalRevenue
    FROM SalesLT.Product p
    LEFT JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    GROUP BY p.ProductID, p.Name
)
SELECT 
    'Top Sellers' AS Category,
    Name,
    TotalRevenue
FROM ProductSales
WHERE TotalRevenue > (SELECT AVG(TotalRevenue) FROM ProductSales)
UNION ALL
SELECT 
    'Never Sold' AS Category,
    Name,
    TotalRevenue
FROM ProductSales
WHERE TimesSold = 0
ORDER BY Category, TotalRevenue DESC;
```

**Explanation**: `ProductSales` CTE used 3 times (main query, subquery, UNION).

---

## 🆚 CTE vs Subquery vs Temp Table

| Feature | CTE | Subquery | Temp Table |
|---------|-----|----------|------------|
| **Readability** | ✅ Excellent | ❌ Poor (nested) | ✅ Good |
| **Reusability** | ✅ Yes (in same query) | ❌ No | ✅ Yes (across queries) |
| **Performance** | ⚡ Same as subquery | ⚡ Same as CTE | ⚡ Can be faster (indexed) |
| **Scope** | 🔒 Single query | 🔒 Single query | 🌐 Session-wide |
| **Recursion** | ✅ Supported | ❌ No | ❌ No |
| **Storage** | 💾 None (virtual) | 💾 None | 💾 TempDB |
| **Use Case** | Readability, recursion | Quick one-off | Large intermediate results |

**When to use each**:
- **CTE**: Improve readability, recursive queries, query decomposition
- **Subquery**: Simple, one-time calculations
- **Temp Table**: Large intermediate results, multiple queries, indexes needed

---

## 🎯 Practical Examples

### Example 4: Sales Ranking with CTE

```sql
-- Rank products by revenue within each category
WITH ProductRevenue AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        SUM(sod.LineTotal) AS TotalRevenue,
        COUNT(DISTINCT sod.SalesOrderID) AS OrderCount
    FROM SalesLT.Product p
    INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
    LEFT JOIN SalesLT.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    GROUP BY p.ProductID, p.Name, pc.Name
)
SELECT 
    ProductName,
    CategoryName,
    TotalRevenue,
    OrderCount,
    CASE 
        WHEN TotalRevenue > 10000 THEN 'Top Seller'
        WHEN TotalRevenue > 5000 THEN 'Good'
        WHEN TotalRevenue > 0 THEN 'Average'
        ELSE 'Never Sold'
    END AS PerformanceRank
FROM ProductRevenue
ORDER BY CategoryName, TotalRevenue DESC;
```

---

### Example 5: Customer Segmentation Pipeline

```sql
-- Multi-stage customer analysis
WITH 
-- Stage 1: Calculate customer metrics
CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        COUNT(soh.SalesOrderID) AS TotalOrders,
        SUM(soh.TotalDue) AS TotalSpent,
        AVG(soh.TotalDue) AS AvgOrderValue,
        MIN(soh.OrderDate) AS FirstOrder,
        MAX(soh.OrderDate) AS LastOrder,
        DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS DaysSinceLastOrder
    FROM SalesLT.Customer c
    LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName
),
-- Stage 2: Assign segments
CustomerSegments AS (
    SELECT 
        *,
        CASE
            WHEN TotalOrders = 0 THEN 'Prospect'
            WHEN DaysSinceLastOrder > 365 THEN 'Churned'
            WHEN DaysSinceLastOrder > 180 THEN 'At Risk'
            WHEN TotalSpent > 10000 THEN 'VIP'
            WHEN TotalSpent > 5000 THEN 'High Value'
            ELSE 'Regular'
        END AS Segment
    FROM CustomerMetrics
),
-- Stage 3: Calculate segment statistics
SegmentStats AS (
    SELECT 
        Segment,
        COUNT(*) AS CustomerCount,
        AVG(TotalSpent) AS AvgLifetimeValue,
        AVG(TotalOrders) AS AvgOrders
    FROM CustomerSegments
    GROUP BY Segment
)
-- Final result: Segment summary
SELECT 
    Segment,
    CustomerCount,
    CAST(AvgLifetimeValue AS DECIMAL(10,2)) AS AvgLifetimeValue,
    CAST(AvgOrders AS DECIMAL(10,2)) AS AvgOrders,
    CAST(CustomerCount * 100.0 / SUM(CustomerCount) OVER() AS DECIMAL(5,2)) AS PercentOfTotal
FROM SegmentStats
ORDER BY AvgLifetimeValue DESC;
```

**Why CTEs shine**: Each stage is clearly separated, easy to debug, reads like a data pipeline.

---

### Example 6: Year-over-Year Comparison

```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(TotalDue) AS MonthlyRevenue,
        COUNT(*) AS OrderCount
    FROM SalesLT.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    curr.OrderYear,
    curr.OrderMonth,
    curr.MonthlyRevenue AS CurrentRevenue,
    prev.MonthlyRevenue AS PreviousYearRevenue,
    curr.MonthlyRevenue - ISNULL(prev.MonthlyRevenue, 0) AS RevenueDifference,
    CASE 
        WHEN prev.MonthlyRevenue IS NULL THEN NULL
        ELSE CAST((curr.MonthlyRevenue - prev.MonthlyRevenue) / prev.MonthlyRevenue * 100 AS DECIMAL(10,2))
    END AS GrowthPercent
FROM MonthlySales curr
LEFT JOIN MonthlySales prev 
    ON curr.OrderMonth = prev.OrderMonth 
    AND curr.OrderYear = prev.OrderYear + 1
ORDER BY curr.OrderYear, curr.OrderMonth;
```

---

## ⚠️ CTE Best Practices

### ✅ DO:

```sql
-- 1. Use descriptive names
WITH HighValueCustomers AS (...) -- Good
WITH CTE1 AS (...)               -- Bad

-- 2. Break complex queries into logical steps
WITH Step1 AS (...), Step2 AS (...), Step3 AS (...)

-- 3. Add comments for complex logic
WITH CustomerMetrics AS (
    -- Calculate customer purchase behavior over last 12 months
    SELECT ...
)

-- 4. Use CTEs for readability
WITH SalesData AS (...)  -- Better than nested subquery
```

### ❌ DON'T:

```sql
-- 1. Don't use CTEs for tiny queries
WITH SmallCTE AS (SELECT * FROM Table WHERE ID = 1)
SELECT * FROM SmallCTE;
-- Just use: SELECT * FROM Table WHERE ID = 1;

-- 2. Don't nest CTEs (use multiple)
WITH Outer AS (
    SELECT * FROM (SELECT * FROM ...) AS Inner -- BAD
)
-- Instead: WITH CTE1 AS (...), CTE2 AS (...)

-- 3. Don't forget performance (CTEs aren't magic)
-- Large CTEs can be slow - consider temp tables with indexes
```

---

## 🔧 CTE Limitations

1. **Scope**: Exists only for one statement
```sql
WITH MyCTE AS (SELECT * FROM Table)
SELECT * FROM MyCTE;  -- Works
SELECT * FROM MyCTE;  -- ERROR: MyCTE doesn't exist
```

2. **No Indexes**: CTEs can't have indexes (use temp tables for that)

3. **Optimization**: SQL Server may not always optimize CTEs well (rare issue)

---

## 📝 Lab 11: CTEs

Complete tasks in `labs/lab_11_ctes.sql`.

**Tasks**:
1. Simple CTE for customer analysis
2. Multiple CTEs for product performance
3. CTE with aggregates and ranking
4. Year-over-year comparison using CTEs
5. Customer segmentation pipeline (3 CTEs)
6. CTE vs subquery performance comparison

---

## ✅ Section Summary

CTEs make complex queries **readable and maintainable**. Use them to:
- Break down complex logic into steps
- Avoid nested subqueries
- Prepare for recursive queries (next section)
- Improve code review and debugging

**Next**: [Section 02: Recursive CTEs →](./02_recursive_ctes.md)

---

*கற்க கசடற - Learn Flawlessly!*
