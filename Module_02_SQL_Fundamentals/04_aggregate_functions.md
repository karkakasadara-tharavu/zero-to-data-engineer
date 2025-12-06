# Section 04: Aggregate Functions

**Estimated Time**: 4 hours  
**Difficulty**: ⭐⭐ Intermediate  

---

## 🎯 Learning Objectives

✅ Use COUNT, SUM, AVG, MIN, MAX  
✅ Understand NULL handling in aggregates  
✅ Combine aggregates in single query  
✅ Use COUNT(*) vs COUNT(column)  

---

## 📊 The Five Essential Aggregates

| Function | Purpose | NULL Handling |
|----------|---------|---------------|
| COUNT() | Count rows | Ignores NULL |
| SUM() | Total of values | Ignores NULL |
| AVG() | Average | Ignores NULL |
| MIN() | Minimum value | Ignores NULL |
| MAX() | Maximum value | Ignores NULL |

---

## 🔢 COUNT Function

### COUNT(*) - Count All Rows

```sql
-- Total number of products
SELECT COUNT(*) AS TotalProducts
FROM SalesLT.Product;
```

### COUNT(column) - Count Non-NULL Values

```sql
-- Products with color specified
SELECT COUNT(Color) AS ProductsWithColor
FROM SalesLT.Product;

-- Compare with total
SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(Color) AS WithColor,
    COUNT(*) - COUNT(Color) AS WithoutColor
FROM SalesLT.Product;
```

### COUNT(DISTINCT column)

```sql
-- How many unique colors?
SELECT COUNT(DISTINCT Color) AS UniqueColors
FROM SalesLT.Product;
```

---

## ➕ SUM Function

```sql
-- Total revenue from all orders
SELECT SUM(TotalDue) AS TotalRevenue
FROM SalesLT.SalesOrderHeader;
```

### SUM with Calculation

```sql
-- Total profit across all products
SELECT SUM(ListPrice - StandardCost) AS TotalPotentialProfit
FROM SalesLT.Product;
```

---

## 📈 AVG Function

```sql
-- Average product price
SELECT AVG(ListPrice) AS AveragePrice
FROM SalesLT.Product;
```

### AVG vs SUM/COUNT

```sql
-- These are equivalent
SELECT AVG(ListPrice) AS AvgPrice
FROM SalesLT.Product;

SELECT SUM(ListPrice) / COUNT(ListPrice) AS AvgPrice
FROM SalesLT.Product;
```

---

## ⬇️ MIN and MAX Functions

```sql
-- Price range
SELECT 
    MIN(ListPrice) AS CheapestProduct,
    MAX(ListPrice) AS MostExpensive,
    MAX(ListPrice) - MIN(ListPrice) AS PriceRange
FROM SalesLT.Product;
```

### MIN/MAX with Dates

```sql
-- Order date range
SELECT 
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS DaysInBusiness
FROM SalesLT.SalesOrderHeader;
```

---

## 🎯 Combining Aggregates

```sql
-- Comprehensive product statistics
SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(Color) AS ProductsWithColor,
    COUNT(DISTINCT Color) AS UniqueColors,
    MIN(ListPrice) AS MinPrice,
    MAX(ListPrice) AS MaxPrice,
    AVG(ListPrice) AS AvgPrice,
    SUM(ListPrice) AS TotalListValue
FROM SalesLT.Product;
```

---

## ⚠️ NULL Handling

**Important**: Aggregates ignore NULL values!

```sql
-- If 3 products: $100, $200, NULL
SELECT 
    COUNT(*) AS AllRows,        -- 3
    COUNT(ListPrice) AS NonNull, -- 2
    AVG(ListPrice) AS Average   -- $150 (not $100!)
FROM Products;
```

---

## 📝 Lab 04: Aggregate Functions

Complete `labs/lab_04_aggregates.sql`.

**Tasks**: Calculate totals, averages, min/max, handle NULLs, combine multiple aggregates.

---

*Next: [Section 05: GROUP BY & HAVING →](./05_groupby_having.md)*
