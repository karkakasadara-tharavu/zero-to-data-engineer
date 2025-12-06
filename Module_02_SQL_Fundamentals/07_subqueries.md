# Section 07: Subqueries

**Estimated Time**: 5 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced  

---

## 🎯 Learning Objectives

✅ Understand subquery concepts  
✅ Use scalar subqueries (single value)  
✅ Use multi-row subqueries with IN  
✅ Use correlated subqueries  
✅ Use EXISTS for existence checks  
✅ Know when to use subqueries vs JOINs  

---

## 🔍 What is a Subquery?

**Subquery** = Query inside another query.

**Use cases**:
- Compare values to aggregates
- Filter based on results from another table
- Check existence of related data

**Syntax**:
```sql
SELECT columns
FROM table
WHERE column OPERATOR (SELECT column FROM table WHERE condition);
```

---

## 1️⃣ Scalar Subqueries (Single Value)

Returns **one row, one column**.

### Example: Products Above Average Price

```sql
-- Step 1: Calculate average (scalar subquery)
SELECT AVG(ListPrice) FROM SalesLT.Product;  -- Returns 438.87

-- Step 2: Use in WHERE clause
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
WHERE ListPrice > (SELECT AVG(ListPrice) FROM SalesLT.Product)
ORDER BY ListPrice DESC;
```

### Example: Customers with Above-Average Orders

```sql
SELECT 
    CustomerID,
    SUM(TotalDue) AS TotalSpent
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
HAVING SUM(TotalDue) > (SELECT AVG(TotalDue) FROM SalesLT.SalesOrderHeader);
```

---

## 📋 Multi-Row Subqueries (IN, ANY, ALL)

Returns **multiple rows, one column**.

### IN Operator

```sql
-- Customers who placed orders
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer
WHERE CustomerID IN (
    SELECT DISTINCT CustomerID 
    FROM SalesLT.SalesOrderHeader
);
```

### NOT IN

```sql
-- Customers who NEVER ordered
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer
WHERE CustomerID NOT IN (
    SELECT CustomerID 
    FROM SalesLT.SalesOrderHeader
);
```

**⚠️ Warning**: `NOT IN` fails if subquery contains NULL!

```sql
-- ✅ SAFER: Use NOT EXISTS instead
WHERE NOT EXISTS (
    SELECT 1 
    FROM SalesLT.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID
);
```

### ANY Operator

```sql
-- Products more expensive than ANY bike
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
WHERE ListPrice > ANY (
    SELECT ListPrice 
    FROM SalesLT.Product 
    WHERE Name LIKE '%Bike%'
);
-- Same as: ListPrice > MIN(bike prices)
```

### ALL Operator

```sql
-- Products more expensive than ALL bikes
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
WHERE ListPrice > ALL (
    SELECT ListPrice 
    FROM SalesLT.Product 
    WHERE Name LIKE '%Bike%'
);
-- Same as: ListPrice > MAX(bike prices)
```

---

## 🔄 Correlated Subqueries

**Subquery references outer query** (executes for each row).

### Example: Products Above Category Average

```sql
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    pc.Name AS Category
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc 
    ON p.ProductCategoryID = pc.ProductCategoryID
WHERE p.ListPrice > (
    -- Correlated: references outer p.ProductCategoryID
    SELECT AVG(ListPrice)
    FROM SalesLT.Product p2
    WHERE p2.ProductCategoryID = p.ProductCategoryID
);
```

**How it works**: For each product, calculate average for ITS category.

---

## ✅ EXISTS Operator

**Check if subquery returns any rows** (TRUE/FALSE).

### Example: Customers with Orders

```sql
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer c
WHERE EXISTS (
    SELECT 1  -- Doesn't matter what we select (just checking existence)
    FROM SalesLT.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID
);
```

### NOT EXISTS

```sql
-- Customers without orders
WHERE NOT EXISTS (
    SELECT 1
    FROM SalesLT.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID
);
```

**Performance tip**: `EXISTS` stops at first match (faster than COUNT).

---

## 🆚 Subqueries vs JOINs

### Same Result, Different Approaches

**Using IN (Subquery)**:
```sql
SELECT CustomerID, FirstName
FROM SalesLT.Customer
WHERE CustomerID IN (SELECT CustomerID FROM SalesLT.SalesOrderHeader);
```

**Using INNER JOIN**:
```sql
SELECT DISTINCT c.CustomerID, c.FirstName
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID;
```

### When to Use Each

| Use Subquery | Use JOIN |
|--------------|----------|
| Existence checks (EXISTS) | Retrieve columns from both tables |
| Compare to aggregate | Multiple tables |
| Filter based on complex logic | Better performance (usually) |
| More readable for simple filters | Need data from related tables |

---

## 🎯 Practical Examples

### Example 1: Top Spenders (Top 10%)

```sql
-- Customers in top 10% by spending
SELECT 
    CustomerID,
    SUM(TotalDue) AS TotalSpent
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
HAVING SUM(TotalDue) >= (
    SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY TotalSpent)
    FROM (
        SELECT CustomerID, SUM(TotalDue) AS TotalSpent
        FROM SalesLT.SalesOrderHeader
        GROUP BY CustomerID
    ) AS CustomerTotals
)
ORDER BY TotalSpent DESC;
```

### Example 2: Products Ordered Multiple Times

```sql
-- Products ordered in more than 5 orders
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product p
WHERE (
    SELECT COUNT(DISTINCT SalesOrderID)
    FROM SalesLT.SalesOrderDetail sod
    WHERE sod.ProductID = p.ProductID
) > 5
ORDER BY Name;
```

### Example 3: Latest Order Per Customer

```sql
-- Each customer's most recent order
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
WHERE soh.OrderDate = (
    SELECT MAX(OrderDate)
    FROM SalesLT.SalesOrderHeader soh2
    WHERE soh2.CustomerID = c.CustomerID
);
```

---

## 📝 Lab 07: Subqueries

Complete `labs/lab_07_subqueries.sql`.

**Tasks**: Scalar subqueries, IN/NOT IN, EXISTS, correlated subqueries, complex nested queries.

---

*Next: [Section 08: String & Date Functions →](./08_functions.md)*
