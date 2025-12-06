# Section 03: Sorting & Limiting Results

**Estimated Time**: 3 hours  
**Difficulty**: ⭐ Beginner  

---

## 🎯 Learning Objectives

✅ Sort results with ORDER BY (ASC/DESC)  
✅ Sort by multiple columns  
✅ Use TOP to limit rows  
✅ Use OFFSET/FETCH for pagination  
✅ Remove duplicates with DISTINCT  

---

## 📊 ORDER BY Clause

**Syntax**:
```sql
SELECT columns
FROM table
WHERE conditions
ORDER BY column1 [ASC|DESC], column2 [ASC|DESC];
```

### Ascending Order (ASC) - Default

```sql
-- Cheapest to most expensive
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ListPrice ASC;  -- ASC is optional (default)
```

### Descending Order (DESC)

```sql
-- Most expensive to cheapest
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;
```

### Multiple Column Sort

```sql
-- Sort by Color (A-Z), then Price (high to low)
SELECT ProductID, Name, Color, ListPrice
FROM SalesLT.Product
ORDER BY Color ASC, ListPrice DESC;
```

### Sort by Column Position

```sql
-- Sort by 3rd column (ListPrice)
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY 3 DESC;
```

**Best practice**: Use column names, not positions (more readable).

---

## 🔝 TOP Clause

**Limit number of rows returned**.

### Basic TOP

```sql
-- Top 10 most expensive products
SELECT TOP 10 ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;
```

### TOP with PERCENT

```sql
-- Top 5% most expensive
SELECT TOP 5 PERCENT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;
```

### TOP with TIES

```sql
-- Include ties (products with same price as 10th)
SELECT TOP 10 WITH TIES ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ListPrice DESC;
```

---

## 📄 OFFSET/FETCH (Pagination)

**Modern alternative to TOP for pagination**.

```sql
-- Skip first 10 rows, get next 5 (page 3, size 5)
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ProductID
OFFSET 10 ROWS
FETCH NEXT 5 ROWS ONLY;
```

**Use case**: Web applications with "Next Page" buttons.

---

## ✨ DISTINCT

**Remove duplicate rows**.

```sql
-- All unique colors
SELECT DISTINCT Color
FROM SalesLT.Product
WHERE Color IS NOT NULL
ORDER BY Color;
```

### DISTINCT with Multiple Columns

```sql
-- Unique Color + Size combinations
SELECT DISTINCT Color, Size
FROM SalesLT.Product
WHERE Color IS NOT NULL AND Size IS NOT NULL
ORDER BY Color, Size;
```

---

## 🎯 Practical Examples

### Example 1: Top Customers by Total Orders

```sql
SELECT TOP 5 
    CustomerID,
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS TotalSpent
FROM SalesLT.SalesOrderHeader
GROUP BY CustomerID
ORDER BY TotalSpent DESC;
```

### Example 2: Recent Orders

```sql
SELECT TOP 20
    SalesOrderID,
    CustomerID,
    OrderDate,
    TotalDue
FROM SalesLT.SalesOrderHeader
ORDER BY OrderDate DESC;
```

### Example 3: Pagination

```sql
-- Page 1 (rows 1-10)
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY Name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Page 2 (rows 11-20)
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- Page 3 (rows 21-30)
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

## 📝 Lab 03: Sorting & Limiting

Complete `labs/lab_03_sorting.sql`.

---

*Next: [Section 04: Aggregate Functions →](./04_aggregate_functions.md)*
