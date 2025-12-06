# Section 05: GROUP BY & HAVING

**Estimated Time**: 5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate  

---

## 🎯 Learning Objectives

✅ Group data with GROUP BY  
✅ Use aggregates with GROUP BY  
✅ Filter groups with HAVING  
✅ Understand GROUP BY vs WHERE  
✅ Use ROLLUP for subtotals  

---

## 📊 GROUP BY Basics

**Purpose**: Divide rows into groups and calculate aggregate for each group.

**Syntax**:
```sql
SELECT column1, AGGREGATE(column2)
FROM table
GROUP BY column1;
```

### Example: Count Products by Color

```sql
SELECT 
    Color,
    COUNT(*) AS ProductCount
FROM SalesLT.Product
WHERE Color IS NOT NULL
GROUP BY Color
ORDER BY ProductCount DESC;
```

**Result**:
| Color | ProductCount |
|-------|--------------|
| Black | 93 |
| Silver | 43 |
| Red | 38 |

---

## 🔑 GROUP BY Rules

1. **Every non-aggregate column in SELECT must be in GROUP BY**

```sql
-- ❌ WRONG
SELECT Color, Size, COUNT(*)
FROM SalesLT.Product
GROUP BY Color;  -- Size not in GROUP BY!

-- ✅ CORRECT
SELECT Color, Size, COUNT(*)
FROM SalesLT.Product
GROUP BY Color, Size;
```

2. **WHERE filters BEFORE grouping, HAVING filters AFTER**

---

## 🎯 Multiple Aggregates per Group

```sql
-- Sales statistics by customer
SELECT 
    CustomerID,
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS TotalSpent,
    AVG(TotalDue) AS AvgOrderValue,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
ORDER BY TotalSpent DESC;
```

---

## 🔍 HAVING Clause

**Filter groups** (like WHERE but for aggregates).

```sql
-- Customers with more than 1 order
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY OrderCount DESC;
```

### WHERE vs HAVING

```sql
SELECT 
    Color,
    COUNT(*) AS ProductCount,
    AVG(ListPrice) AS AvgPrice
FROM SalesLT.Product
WHERE ListPrice > 100           -- Filter rows BEFORE grouping
GROUP BY Color
HAVING COUNT(*) >= 10           -- Filter groups AFTER grouping
ORDER BY ProductCount DESC;
```

**Execution order**: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY

---

## 📈 GROUP BY with Multiple Columns

```sql
-- Product count by Color AND Size
SELECT 
    Color,
    Size,
    COUNT(*) AS ProductCount
FROM SalesLT.Product
WHERE Color IS NOT NULL AND Size IS NOT NULL
GROUP BY Color, Size
ORDER BY Color, Size;
```

---

## 🔄 ROLLUP (Subtotals)

**Generate subtotals and grand totals**.

```sql
-- Sales by customer with grand total
SELECT 
    CustomerID,
    SUM(TotalDue) AS TotalSales
FROM SalesLT.SalesOrderHeader
GROUP BY ROLLUP(CustomerID);
```

**Result includes**:
- Sales per customer
- Grand total (CustomerID = NULL)

---

## 🎯 Practical Examples

### Example 1: Top Product Categories

```sql
SELECT 
    pc.Name AS Category,
    COUNT(p.ProductID) AS ProductCount,
    AVG(p.ListPrice) AS AvgPrice,
    SUM(p.ListPrice) AS TotalValue
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc 
    ON p.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY ProductCount DESC;
```

### Example 2: Monthly Sales Trends

```sql
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS MonthlyRevenue
FROM SalesLT.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;
```

### Example 3: Customer Segmentation

```sql
-- High-value customers (>$5000 total spend)
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSpent,
    CASE 
        WHEN SUM(TotalDue) > 10000 THEN 'VIP'
        WHEN SUM(TotalDue) > 5000 THEN 'High Value'
        ELSE 'Regular'
    END AS CustomerSegment
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
HAVING SUM(TotalDue) > 5000
ORDER BY TotalSpent DESC;
```

---

## 📝 Lab 05: GROUP BY & HAVING

Complete `labs/lab_05_groupby.sql`.

**Tasks**: Group by single/multiple columns, use HAVING, create summary reports, calculate subtotals.

---

*Next: [Section 06: JOINs →](./06_joins.md)*
