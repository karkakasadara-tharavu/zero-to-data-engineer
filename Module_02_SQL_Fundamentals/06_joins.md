# Section 06: JOINs - Combining Tables

**Estimated Time**: 6 hours  
**Difficulty**: ⭐⭐⭐ Intermediate-Advanced  

---

## 🎯 Learning Objectives

✅ Understand relational database concepts  
✅ Use INNER JOIN to combine tables  
✅ Use LEFT/RIGHT JOIN for optional matches  
✅ Use FULL OUTER JOIN  
✅ Understand JOIN types visually  
✅ Write multi-table JOINs (3+ tables)  

---

## 🔗 Why JOINs?

**Relational databases** store data in multiple tables to avoid redundancy.

**Example**: Instead of storing customer name in every order:
- **Customer table**: CustomerID, Name, Email
- **Order table**: OrderID, CustomerID, Amount

**JOIN** combines them: `Order.CustomerID = Customer.CustomerID`

---

## 🎨 JOIN Types Visual Guide

```
Table A (Customers)          Table B (Orders)
CustomerID | Name            OrderID | CustomerID | Amount
1          | Alice          101     | 1          | $500
2          | Bob            102     | 1          | $300
3          | Carol          103     | 3          | $200
```

### INNER JOIN (Intersection)
**Only matching rows from both tables**
```
Result: Alice ($500, $300), Carol ($200)
Bob excluded (no orders)
```

### LEFT JOIN (All from left + matches from right)
**All customers + their orders (NULL if no orders)**
```
Result: Alice ($500, $300), Bob (NULL), Carol ($200)
```

### RIGHT JOIN (All from right + matches from left)
**All orders + customer info**
```
Result: Same as INNER JOIN in this case
```

### FULL OUTER JOIN (Everything)
**All customers + all orders**
```
Result: Alice, Bob, Carol (all with matching orders or NULLs)
```

---

## 🔵 INNER JOIN

**Most common JOIN** - returns only matching rows.

**Syntax**:
```sql
SELECT columns
FROM table1
INNER JOIN table2 ON table1.key = table2.key;
```

### Example: Customers with Orders

```sql
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
ORDER BY c.CustomerID, soh.OrderDate;
```

**Result**: Only customers who have placed orders (some customers excluded if they never ordered).

---

## 🟢 LEFT JOIN (LEFT OUTER JOIN)

**All rows from left table** + matching rows from right (NULL if no match).

```sql
-- All customers (even those without orders)
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    soh.SalesOrderID,
    soh.TotalDue
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
ORDER BY c.CustomerID;
```

**Use case**: Find customers who NEVER ordered:

```sql
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
WHERE soh.SalesOrderID IS NULL;  -- No matching orders
```

---

## 🟡 RIGHT JOIN (RIGHT OUTER JOIN)

**All rows from right table** + matching from left.

```sql
-- Rarely used (just swap tables and use LEFT JOIN)
SELECT columns
FROM table1
RIGHT JOIN table2 ON table1.key = table2.key;

-- Same as:
SELECT columns
FROM table2
LEFT JOIN table1 ON table2.key = table1.key;
```

**Best practice**: Use LEFT JOIN instead of RIGHT JOIN (more intuitive).

---

## 🔴 FULL OUTER JOIN

**All rows from both tables** (NULLs where no match).

```sql
SELECT 
    c.CustomerID,
    c.FirstName,
    soh.SalesOrderID,
    soh.TotalDue
FROM SalesLT.Customer c
FULL OUTER JOIN SalesLT.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID;
```

**Rare in practice** - used for data reconciliation.

---

## 🔗 Multi-Table JOINs

**Chain multiple JOINs** to combine 3+ tables.

### Example: Orders with Customer and Product Details

```sql
SELECT 
    soh.SalesOrderID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    p.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM SalesLT.SalesOrderHeader soh
INNER JOIN SalesLT.Customer c 
    ON soh.CustomerID = c.CustomerID
INNER JOIN SalesLT.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN SalesLT.Product p 
    ON sod.ProductID = p.ProductID
ORDER BY soh.SalesOrderID, sod.SalesOrderDetailID;
```

**Joins 4 tables**: Orders → Customers, Orders → Order Details, Details → Products

---

## 🎯 JOIN Best Practices

### 1. Use Table Aliases

```sql
-- ✅ GOOD: Short aliases
SELECT c.Name, o.OrderDate
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader o ON c.CustomerID = o.CustomerID;

-- ❌ BAD: Repetitive full names
SELECT SalesLT.Customer.Name, SalesLT.SalesOrderHeader.OrderDate
FROM SalesLT.Customer
INNER JOIN SalesLT.SalesOrderHeader 
    ON SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID;
```

### 2. Qualify All Columns

```sql
-- ✅ GOOD: Clear which table
SELECT c.CustomerID, o.OrderDate

-- ❌ BAD: Ambiguous (fails if both tables have same column name)
SELECT CustomerID, OrderDate
```

### 3. JOIN in Logical Order

```sql
-- ✅ GOOD: Follow relationships
FROM Customer c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID

-- ❌ BAD: Illogical order
FROM OrderDetails od
JOIN Customer c ON ???  -- Can't join directly!
```

---

## 🎯 Practical Examples

### Example 1: Product Sales Report

```sql
-- Products with sales data
SELECT 
    p.ProductID,
    p.Name,
    pc.Name AS Category,
    COUNT(sod.SalesOrderDetailID) AS TimesSold,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalRevenue
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc 
    ON p.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN SalesLT.SalesOrderDetail sod 
    ON p.ProductID = sod.ProductID
GROUP BY p.ProductID, p.Name, pc.Name
ORDER BY TotalRevenue DESC;
```

### Example 2: Customer Purchase History

```sql
-- Complete customer order history
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    soh.SalesOrderID,
    soh.OrderDate,
    COUNT(sod.SalesOrderDetailID) AS ItemsOrdered,
    SUM(sod.LineTotal) AS OrderTotal
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
INNER JOIN SalesLT.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName, 
         soh.SalesOrderID, soh.OrderDate
ORDER BY c.CustomerID, soh.OrderDate;
```

### Example 3: Products Never Sold

```sql
-- Identify slow-moving inventory
SELECT 
    p.ProductID,
    p.Name,
    p.ListPrice,
    pc.Name AS Category
FROM SalesLT.Product p
INNER JOIN SalesLT.ProductCategory pc 
    ON p.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN SalesLT.SalesOrderDetail sod 
    ON p.ProductID = sod.ProductID
WHERE sod.ProductID IS NULL  -- Never ordered
ORDER BY p.ListPrice DESC;
```

---

## ⚠️ Common JOIN Mistakes

### Mistake 1: Cartesian Product (Missing JOIN Condition)

```sql
-- ❌ WRONG: Produces every combination (847 customers × 32 orders = 27,104 rows!)
SELECT *
FROM SalesLT.Customer, SalesLT.SalesOrderHeader;

-- ✅ CORRECT: Add JOIN condition
SELECT *
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID;
```

### Mistake 2: Wrong JOIN Type

```sql
-- ❌ WRONG: INNER JOIN excludes customers without orders
SELECT c.CustomerID, COUNT(o.SalesOrderID) AS OrderCount
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID;

-- ✅ CORRECT: LEFT JOIN includes all customers
LEFT JOIN SalesLT.SalesOrderHeader o ON c.CustomerID = o.CustomerID
```

---

## 📝 Lab 06: JOINs

Complete `labs/lab_06_joins.sql`.

**Tasks**: 
- INNER JOIN customers + orders
- LEFT JOIN to find unmatched rows
- Multi-table JOINs (3-4 tables)
- JOIN with aggregates
- Complex business queries

---

*Next: [Section 07: Subqueries →](./07_subqueries.md)*
