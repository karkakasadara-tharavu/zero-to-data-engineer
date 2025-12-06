# Section 08: String & Date Functions

**Estimated Time**: 4 hours  
**Difficulty**: ⭐⭐ Intermediate  

---

## 🎯 Learning Objectives

✅ Manipulate strings (UPPER, LOWER, LEN, SUBSTRING)  
✅ Search strings (CHARINDEX, PATINDEX)  
✅ Work with dates (GETDATE, DATEPART, DATEDIFF, DATEADD)  
✅ Format dates and strings  

---

## 🔤 String Functions

### UPPER() / LOWER()

```sql
SELECT 
    FirstName,
    UPPER(FirstName) AS Uppercase,
    LOWER(LastName) AS Lowercase
FROM SalesLT.Customer;
```

### LEN() - String Length

```sql
-- Email length
SELECT 
    EmailAddress,
    LEN(EmailAddress) AS EmailLength
FROM SalesLT.Customer;
```

### SUBSTRING() - Extract Part of String

**Syntax**: `SUBSTRING(string, start, length)`

```sql
-- Extract first 3 characters
SELECT 
    Name,
    SUBSTRING(Name, 1, 3) AS FirstThreeChars
FROM SalesLT.Product;

-- Extract domain from email
SELECT 
    EmailAddress,
    SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, 100) AS Domain
FROM SalesLT.Customer;
```

### LEFT() / RIGHT()

```sql
-- First 5 and last 5 characters
SELECT 
    Name,
    LEFT(Name, 5) AS First5,
    RIGHT(Name, 5) AS Last5
FROM SalesLT.Product;
```

### LTRIM() / RTRIM() / TRIM()

```sql
-- Remove spaces
SELECT 
    LTRIM('   Hello') AS LeftTrim,    -- 'Hello'
    RTRIM('Hello   ') AS RightTrim,   -- 'Hello'
    TRIM('   Hello   ') AS BothTrim;  -- 'Hello'
```

### REPLACE()

```sql
-- Replace text
SELECT 
    Name,
    REPLACE(Name, 'Bike', 'Bicycle') AS UpdatedName
FROM SalesLT.Product;
```

### CHARINDEX() - Find Position

**Syntax**: `CHARINDEX(search, string)`

```sql
-- Find @ position in email
SELECT 
    EmailAddress,
    CHARINDEX('@', EmailAddress) AS AtPosition
FROM SalesLT.Customer;

-- Extract everything before @
SELECT 
    EmailAddress,
    LEFT(EmailAddress, CHARINDEX('@', EmailAddress) - 1) AS Username
FROM SalesLT.Customer;
```

---

## 📅 Date Functions

### GETDATE() - Current DateTime

```sql
SELECT GETDATE() AS CurrentDateTime;
-- Returns: 2025-12-07 14:30:25.123
```

### DATEPART() - Extract Date Component

```sql
SELECT 
    OrderDate,
    DATEPART(YEAR, OrderDate) AS Year,
    DATEPART(MONTH, OrderDate) AS Month,
    DATEPART(DAY, OrderDate) AS Day,
    DATEPART(WEEKDAY, OrderDate) AS Weekday  -- 1=Sunday, 7=Saturday
FROM SalesLT.SalesOrderHeader;
```

**Shortcuts**:
```sql
YEAR(OrderDate)   -- Same as DATEPART(YEAR, OrderDate)
MONTH(OrderDate)
DAY(OrderDate)
```

### DATENAME() - Name of Date Part

```sql
SELECT 
    OrderDate,
    DATENAME(MONTH, OrderDate) AS MonthName,   -- 'January'
    DATENAME(WEEKDAY, OrderDate) AS DayName    -- 'Monday'
FROM SalesLT.SalesOrderHeader;
```

### DATEDIFF() - Difference Between Dates

**Syntax**: `DATEDIFF(unit, start, end)`

```sql
-- Days since order
SELECT 
    SalesOrderID,
    OrderDate,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysSinceOrder,
    DATEDIFF(MONTH, OrderDate, GETDATE()) AS MonthsSinceOrder,
    DATEDIFF(YEAR, OrderDate, GETDATE()) AS YearsSinceOrder
FROM SalesLT.SalesOrderHeader;
```

### DATEADD() - Add to Date

**Syntax**: `DATEADD(unit, number, date)`

```sql
-- Add 30 days to order date
SELECT 
    OrderDate,
    DATEADD(DAY, 30, OrderDate) AS DueDate,
    DATEADD(MONTH, 1, OrderDate) AS OneMonthLater,
    DATEADD(YEAR, -1, OrderDate) AS OneYearAgo
FROM SalesLT.SalesOrderHeader;
```

### FORMAT() - Custom Date Format

```sql
SELECT 
    OrderDate,
    FORMAT(OrderDate, 'yyyy-MM-dd') AS ISODate,
    FORMAT(OrderDate, 'MM/dd/yyyy') AS USDate,
    FORMAT(OrderDate, 'MMMM dd, yyyy') AS LongDate,
    FORMAT(OrderDate, 'MMM dd') AS ShortDate
FROM SalesLT.SalesOrderHeader;
```

---

## 🎯 Practical Examples

### Example 1: Email Analysis

```sql
SELECT 
    EmailAddress,
    LEFT(EmailAddress, CHARINDEX('@', EmailAddress) - 1) AS Username,
    SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, 100) AS Domain,
    LEN(EmailAddress) AS EmailLength
FROM SalesLT.Customer
WHERE EmailAddress IS NOT NULL;
```

### Example 2: Product Code Parsing

```sql
-- Extract parts of product number (e.g., 'FR-R92B-58')
SELECT 
    ProductNumber,
    LEFT(ProductNumber, 2) AS Prefix,
    SUBSTRING(ProductNumber, 4, 4) AS Code,
    RIGHT(ProductNumber, 2) AS Size
FROM SalesLT.Product
WHERE ProductNumber LIKE '__-____-__';
```

### Example 3: Sales Analysis by Month

```sql
SELECT 
    YEAR(OrderDate) AS OrderYear,
    DATENAME(MONTH, OrderDate) AS MonthName,
    COUNT(*) AS TotalOrders,
    SUM(TotalDue) AS MonthlyRevenue
FROM SalesLT.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY OrderYear, MONTH(OrderDate);
```

### Example 4: Customer Lifecycle

```sql
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    MIN(soh.OrderDate) AS FirstOrder,
    MAX(soh.OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(soh.OrderDate), MAX(soh.OrderDate)) AS CustomerLifespanDays,
    DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS DaysSinceLastOrder
FROM SalesLT.Customer c
INNER JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 180  -- Inactive 6+ months
ORDER BY DaysSinceLastOrder DESC;
```

---

## 📝 Lab 08: Functions

Complete `labs/lab_08_functions.sql`.

**Tasks**: String manipulation, date calculations, formatting, parsing complex strings.

---

*Next: [Section 09: CASE Expressions →](./09_case_expressions.md)*
