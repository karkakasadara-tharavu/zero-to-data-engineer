# Section 02: Filtering Data with WHERE Clause

**Estimated Time**: 4 hours  
**Difficulty**: ⭐⭐ Beginner-Intermediate  
**Prerequisites**: Section 01 complete

---

## 🎯 Learning Objectives

✅ Filter rows using WHERE clause  
✅ Use comparison operators (=, <, >, <=, >=, <>, !=)  
✅ Combine conditions with AND, OR, NOT  
✅ Use IN operator for multiple values  
✅ Use BETWEEN for ranges  
✅ Use LIKE for pattern matching  
✅ Handle NULL values with IS NULL / IS NOT NULL  

---

## 📚 What is the WHERE Clause?

**WHERE** filters rows based on conditions. Only rows meeting the condition(s) are returned.

**Syntax**:
```sql
SELECT columns
FROM table
WHERE condition;
```

**Real-world example**: "Show me only products priced over $1000" or "Find customers in California".

---

## 🔍 Comparison Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equal to | `WHERE Price = 100` |
| `<>` or `!=` | Not equal | `WHERE Color <> 'Red'` |
| `>` | Greater than | `WHERE Price > 100` |
| `<` | Less than | `WHERE Price < 100` |
| `>=` | Greater or equal | `WHERE Price >= 100` |
| `<=` | Less or equal | `WHERE Price <= 100` |

### Example: Products Over $1000

```sql
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
WHERE ListPrice > 1000;
```

### Example: Specific Color

```sql
SELECT ProductID, Name, Color
FROM SalesLT.Product
WHERE Color = 'Red';
```

**Note**: String comparisons are **case-insensitive** in SQL Server by default.

---

## 🔗 Logical Operators (AND, OR, NOT)

### AND Operator

**Both conditions must be TRUE**.

```sql
-- Red products over $100
SELECT ProductID, Name, Color, ListPrice
FROM SalesLT.Product
WHERE Color = 'Red' AND ListPrice > 100;
```

### OR Operator

**At least one condition must be TRUE**.

```sql
-- Red OR Blue products
SELECT ProductID, Name, Color
FROM SalesLT.Product
WHERE Color = 'Red' OR Color = 'Blue';
```

### NOT Operator

**Negates a condition**.

```sql
-- Products that are NOT red
SELECT ProductID, Name, Color
FROM SalesLT.Product
WHERE NOT Color = 'Red';

-- Same as:
WHERE Color <> 'Red';
```

### Combining Multiple Conditions

```sql
-- (Red OR Blue) AND Price > 500
SELECT ProductID, Name, Color, ListPrice
FROM SalesLT.Product
WHERE (Color = 'Red' OR Color = 'Blue') 
  AND ListPrice > 500;
```

**Parentheses matter!** They control evaluation order.

---

## 📋 IN Operator

**Shorthand for multiple OR conditions**.

### Without IN (verbose):
```sql
WHERE Color = 'Red' OR Color = 'Blue' OR Color = 'Black'
```

### With IN (concise):
```sql
WHERE Color IN ('Red', 'Blue', 'Black')
```

### Example: Multiple States

```sql
SELECT CustomerID, FirstName, LastName, StateProvince
FROM SalesLT.Customer c
INNER JOIN SalesLT.CustomerAddress ca ON c.CustomerID = ca.CustomerID
INNER JOIN SalesLT.Address a ON ca.AddressID = a.AddressID
WHERE StateProvince IN ('CA', 'WA', 'OR');
```

### NOT IN

```sql
-- Exclude specific colors
WHERE Color NOT IN ('Red', 'Blue', 'Black')
```

---

## 📊 BETWEEN Operator

**Range filtering (inclusive)**.

### Syntax:
```sql
WHERE column BETWEEN low_value AND high_value
```

### Example: Price Range

```sql
-- Products between $100 and $500
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
WHERE ListPrice BETWEEN 100 AND 500;

-- Same as:
WHERE ListPrice >= 100 AND ListPrice <= 500;
```

### Example: Date Range

```sql
-- Orders in 2008
SELECT SalesOrderID, OrderDate, TotalDue
FROM SalesLT.SalesOrderHeader
WHERE OrderDate BETWEEN '2008-01-01' AND '2008-12-31';
```

### NOT BETWEEN

```sql
-- Products outside $100-$500 range
WHERE ListPrice NOT BETWEEN 100 AND 500
```

---

## 🔎 LIKE Operator (Pattern Matching)

**Search for patterns in strings**.

### Wildcards

| Wildcard | Meaning | Example | Matches |
|----------|---------|---------|---------|
| `%` | Any sequence of characters | `'Bike%'` | Bike, Bikes, Bike Rack |
| `_` | Single character | `'B_ke'` | Bike, Bake, Boke |
| `[]` | Any character in brackets | `'[ABC]%'` | Starts with A, B, or C |
| `[^]` | Not in brackets | `'[^ABC]%'` | Doesn't start with A, B, C |

### Example: Starts With

```sql
-- Products starting with "Mountain"
SELECT ProductID, Name
FROM SalesLT.Product
WHERE Name LIKE 'Mountain%';
```

### Example: Contains

```sql
-- Products containing "Bike"
SELECT ProductID, Name
FROM SalesLT.Product
WHERE Name LIKE '%Bike%';
```

### Example: Ends With

```sql
-- Products ending with "Helmet"
SELECT ProductID, Name
FROM SalesLT.Product
WHERE Name LIKE '%Helmet';
```

### Example: Specific Pattern

```sql
-- Product numbers like "FR-R92_-58"
SELECT ProductNumber, Name
FROM SalesLT.Product
WHERE ProductNumber LIKE 'FR-R92_-58';
```

### Case Sensitivity

```sql
-- Case-insensitive by default (both find "bike", "BIKE", "Bike")
WHERE Name LIKE '%bike%'
WHERE Name LIKE '%BIKE%'
```

---

## ❓ NULL Values

**NULL** = missing or unknown value (not zero, not empty string).

### IS NULL

```sql
-- Products with no color specified
SELECT ProductID, Name, Color
FROM SalesLT.Product
WHERE Color IS NULL;
```

### IS NOT NULL

```sql
-- Products with color specified
SELECT ProductID, Name, Color
FROM SalesLT.Product
WHERE Color IS NOT NULL;
```

### ⚠️ Common Mistake

```sql
-- ❌ WRONG - doesn't work with NULL
WHERE Color = NULL

-- ✅ CORRECT
WHERE Color IS NULL
```

**Why?** NULL means "unknown", so `NULL = NULL` is unknown (not TRUE).

---

## 🎯 Practical Examples

### Example 1: High-Value Orders

```sql
-- Orders over $10,000
SELECT SalesOrderID, CustomerID, OrderDate, TotalDue
FROM SalesLT.SalesOrderHeader
WHERE TotalDue > 10000
ORDER BY TotalDue DESC;
```

### Example 2: Specific Customer Search

```sql
-- Find customer by last name
SELECT CustomerID, FirstName, LastName, EmailAddress
FROM SalesLT.Customer
WHERE LastName = 'Harris';
```

### Example 3: Product Search with Multiple Criteria

```sql
-- Red or Black bikes over $1000
SELECT ProductID, Name, Color, ListPrice
FROM SalesLT.Product
WHERE (Color = 'Red' OR Color = 'Black')
  AND ListPrice > 1000
  AND Name LIKE '%Bike%';
```

### Example 4: Date-Based Filtering

```sql
-- Orders from June 2008
SELECT SalesOrderID, OrderDate, TotalDue
FROM SalesLT.SalesOrderHeader
WHERE OrderDate >= '2008-06-01' 
  AND OrderDate < '2008-07-01';
```

---

## 📝 Lab 02: Filtering Data

Complete tasks in `labs/lab_02_filtering.sql`. Solutions in `solutions/` folder.

**Tasks**:
1. Products under $200
2. Customers with emails containing "adventure"
3. Orders between specific dates
4. Products in specific color range
5. Pattern matching with LIKE
6. NULL value handling
7. Complex multi-condition filters

---

## ✅ Section Summary

You learned to filter data precisely using WHERE clause with comparison operators, logical operators (AND/OR/NOT), IN, BETWEEN, LIKE, and NULL handling. Next: Sorting results with ORDER BY!

**Next**: [Section 03: Sorting & Limiting Results →](./03_sorting_limiting.md)

---

*கற்க கசடற - Learn Flawlessly!*
