# Section 03: Window Functions - Ranking

**Estimated Time**: 6 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced  

---

## 🎯 Learning Objectives

✅ Use ROW_NUMBER for unique row numbering  
✅ Use RANK and DENSE_RANK for ranking with ties  
✅ Use NTILE for bucketing  
✅ Understand PARTITION BY for grouped calculations  
✅ Combine window functions with ORDER BY  

---

## 🪟 What are Window Functions?

**Window Functions** = Perform calculations across a set of rows related to the current row.

**Key difference from GROUP BY**: 
- GROUP BY: Collapses rows into groups
- Window Functions: Keep all rows, add calculated columns

**Syntax**:
```sql
FUNCTION() OVER (
    PARTITION BY column  -- Optional: Group like GROUP BY
    ORDER BY column      -- Required for ranking
    ROWS/RANGE ...       -- Optional: Frame clause
)
```

---

## 🔢 ROW_NUMBER()

**Assigns unique sequential number** to each row (no ties).

### Example: Number orders per customer

```sql
SELECT 
    CustomerID,
    SalesOrderID,
    OrderDate,
    TotalDue,
    ROW_NUMBER() OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
    ) AS OrderNumber
FROM SalesLT.SalesOrderHeader
ORDER BY CustomerID, OrderDate;
```

**Output**:
```
CustomerID | SalesOrderID | OrderDate  | TotalDue | OrderNumber
-----------|--------------|------------|----------|------------
1          | 101          | 2008-01-01 | 500      | 1
1          | 102          | 2008-02-15 | 300      | 2
1          | 103          | 2008-03-20 | 700      | 3
2          | 104          | 2008-01-05 | 400      | 1
2          | 105          | 2008-06-10 | 600      | 2
```

**Use cases**: Pagination, finding 1st/last/Nth record per group.

---

## 🏆 RANK() and DENSE_RANK()

### RANK()
**Assigns rank with gaps** for ties.

```sql
SELECT 
    ProductID,
    Name,
    ListPrice,
    RANK() OVER (ORDER BY ListPrice DESC) AS PriceRank
FROM SalesLT.Product;
```

**Example**:
```
ProductID | Name    | ListPrice | PriceRank
----------|---------|-----------|----------
10        | Bike A  | 3000      | 1
20        | Bike B  | 3000      | 1  (tied)
30        | Bike C  | 2500      | 3  (skips 2)
40        | Bike D  | 2000      | 4
```

### DENSE_RANK()
**Assigns rank WITHOUT gaps** for ties.

```sql
DENSE_RANK() OVER (ORDER BY ListPrice DESC) AS DensePriceRank
```

**Example**:
```
ProductID | Name    | ListPrice | DensePriceRank
----------|---------|-----------|---------------
10        | Bike A  | 3000      | 1
20        | Bike B  | 3000      | 1  (tied)
30        | Bike C  | 2500      | 2  (no gap)
40        | Bike D  | 2000      | 3
```

**When to use which**:
- **ROW_NUMBER**: Need unique numbering (pagination, select Nth row)
- **RANK**: Traditional ranking (Olympic medals - ties share rank, skip next)
- **DENSE_RANK**: No gaps in ranks (rank products, no skipping)

---

## 📊 NTILE()

**Divides rows into N buckets** (quartiles, percentiles).

### Example: Quartile customer segments

```sql
WITH CustomerSpending AS (
    SELECT 
        CustomerID,
        SUM(TotalDue) AS TotalSpent
    FROM SalesLT.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    TotalSpent,
    NTILE(4) OVER (ORDER BY TotalSpent DESC) AS Quartile
FROM CustomerSpending;
```

**Output**:
```
CustomerID | TotalSpent | Quartile
-----------|------------|----------
10         | 50000      | 1  (Top 25%)
15         | 45000      | 1
20         | 30000      | 2
25         | 25000      | 2
30         | 15000      | 3
35         | 10000      | 3
40         | 5000       | 4  (Bottom 25%)
```

**Use cases**: A/B testing groups, customer segmentation, percentile analysis.

---

## 🔑 PARTITION BY - The Key to Power

**PARTITION BY** = "GROUP BY for window functions"

### Example: Rank products WITHIN each category

```sql
SELECT 
    p.ProductID,
    p.Name,
    pc.Name AS Category,
    p.ListPrice,
    RANK() OVER (
        PARTITION BY pc.Name  -- Separate ranking per category
        ORDER BY p.ListPrice DESC
    ) AS CategoryRank
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
ORDER BY pc.Name, CategoryRank;
```

**Output**:
```
ProductID | Name       | Category | ListPrice | CategoryRank
----------|------------|----------|-----------|-------------
10        | Bike A     | Bikes    | 3000      | 1
20        | Bike B     | Bikes    | 2500      | 2
30        | Helmet A   | Helmets  | 150       | 1  (rank resets per category)
40        | Helmet B   | Helmets  | 100       | 2
```

---

## 🎯 Practical Examples

### Example 1: Top 3 Products per Category

```sql
WITH RankedProducts AS (
    SELECT 
        p.ProductID,
        p.Name,
        pc.Name AS Category,
        p.ListPrice,
        ROW_NUMBER() OVER (
            PARTITION BY pc.Name
            ORDER BY p.ListPrice DESC
        ) AS PriceRank
    FROM SalesLT.Product p
    INNER JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
)
SELECT 
    Category,
    Name,
    ListPrice,
    PriceRank
FROM RankedProducts
WHERE PriceRank <= 3
ORDER BY Category, PriceRank;
```

---

### Example 2: Find First and Last Order per Customer

```sql
SELECT 
    CustomerID,
    SalesOrderID,
    OrderDate,
    TotalDue,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS OrderSequence,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) = 1 
        THEN 'First Order'
        WHEN ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) = 1
        THEN 'Last Order'
        ELSE 'Middle Order'
    END AS OrderType
FROM SalesLT.SalesOrderHeader
ORDER BY CustomerID, OrderDate;
```

---

### Example 3: Customer Spend Percentile

```sql
WITH CustomerSpending AS (
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        ISNULL(SUM(soh.TotalDue), 0) AS TotalSpent
    FROM SalesLT.Customer c
    LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName
)
SELECT 
    CustomerID,
    CustomerName,
    TotalSpent,
    NTILE(100) OVER (ORDER BY TotalSpent DESC) AS Percentile,
    CASE 
        WHEN NTILE(100) OVER (ORDER BY TotalSpent DESC) <= 10 THEN 'Top 10%'
        WHEN NTILE(100) OVER (ORDER BY TotalSpent DESC) <= 25 THEN 'Top 25%'
        WHEN NTILE(100) OVER (ORDER BY TotalSpent DESC) <= 50 THEN 'Top 50%'
        ELSE 'Bottom 50%'
    END AS Segment
FROM CustomerSpending
ORDER BY TotalSpent DESC;
```

---

## ⚠️ Common Mistakes

### Mistake 1: Missing ORDER BY

```sql
-- ❌ WRONG: ORDER BY required for ranking
ROW_NUMBER() OVER (PARTITION BY CustomerID)  -- ERROR!

-- ✅ CORRECT:
ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate)
```

### Mistake 2: Using GROUP BY with window functions

```sql
-- ❌ WRONG: Don't use GROUP BY (defeats purpose)
SELECT CustomerID, SUM(TotalDue),
       ROW_NUMBER() OVER (ORDER BY CustomerID)
FROM Orders
GROUP BY CustomerID;  -- Unnecessary!

-- ✅ CORRECT: Window functions don't need GROUP BY
SELECT CustomerID, TotalDue,
       ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate)
FROM Orders;
```

---

## 📝 Lab 13: Window Ranking Functions

Complete `labs/lab_13_ranking.sql`.

**Tasks**:
1. Number orders per customer (ROW_NUMBER)
2. Rank products by price with RANK() and DENSE_RANK()
3. Find top 5 customers by spending per region
4. Quartile analysis with NTILE
5. First/last order per customer
6. Product ranking within categories

---

## ✅ Section Summary

Window ranking functions provide **powerful analytics without GROUP BY**:
- **ROW_NUMBER**: Unique sequential numbering
- **RANK**: Olympic-style ranking (gaps for ties)
- **DENSE_RANK**: Ranking without gaps
- **NTILE**: Divide into N equal buckets
- **PARTITION BY**: Reset calculations per group

**Next**: [Section 04: Window Analytical Functions →](./04_window_analytical.md)
