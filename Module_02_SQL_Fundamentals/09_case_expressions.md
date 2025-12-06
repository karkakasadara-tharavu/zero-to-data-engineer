# Section 09: CASE Expressions

**Estimated Time**: 4 hours  
**Difficulty**: ⭐⭐⭐ Intermediate  

---

## 🎯 Learning Objectives

✅ Use simple CASE expressions  
✅ Use searched CASE expressions  
✅ Implement conditional logic in queries  
✅ Use IIF() as shorthand  
✅ Nest CASE expressions  

---

## 🔀 What is CASE?

**CASE** = SQL's "if-then-else" logic (like IF statements in programming).

**Two types**:
1. **Simple CASE**: Compare one column to multiple values
2. **Searched CASE**: Evaluate multiple conditions

---

## 1️⃣ Simple CASE

**Syntax**:
```sql
CASE column
    WHEN value1 THEN result1
    WHEN value2 THEN result2
    ELSE default_result
END
```

### Example: Size Labels

```sql
SELECT 
    ProductID,
    Name,
    Size,
    CASE Size
        WHEN 'S' THEN 'Small'
        WHEN 'M' THEN 'Medium'
        WHEN 'L' THEN 'Large'
        WHEN 'XL' THEN 'Extra Large'
        ELSE 'Unknown'
    END AS SizeLabel
FROM SalesLT.Product
WHERE Size IS NOT NULL;
```

---

## 2️⃣ Searched CASE (Most Flexible)

**Syntax**:
```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE default_result
END
```

### Example: Price Categories

```sql
SELECT 
    ProductID,
    Name,
    ListPrice,
    CASE
        WHEN ListPrice < 100 THEN 'Budget'
        WHEN ListPrice < 500 THEN 'Mid-Range'
        WHEN ListPrice < 1000 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceCategory
FROM SalesLT.Product
ORDER BY ListPrice;
```

### Example: Customer Segmentation

```sql
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    COUNT(soh.SalesOrderID) AS TotalOrders,
    SUM(soh.TotalDue) AS TotalSpent,
    CASE
        WHEN SUM(soh.TotalDue) > 10000 THEN 'VIP'
        WHEN SUM(soh.TotalDue) > 5000 THEN 'High Value'
        WHEN SUM(soh.TotalDue) > 1000 THEN 'Regular'
        ELSE 'Low Value'
    END AS CustomerTier
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;
```

---

## 🔄 CASE in Different Clauses

### In SELECT (Most Common)

```sql
SELECT 
    Name,
    CASE WHEN ListPrice > 1000 THEN 'Expensive' ELSE 'Affordable' END AS PriceTag
FROM SalesLT.Product;
```

### In WHERE

```sql
-- Filter based on CASE result
SELECT ProductID, Name, ListPrice
FROM SalesLT.Product
WHERE 
    CASE 
        WHEN Color = 'Red' THEN 1
        WHEN Color = 'Black' THEN 1
        ELSE 0
    END = 1;
```

### In ORDER BY

```sql
-- Custom sort order
SELECT ProductID, Name, Size
FROM SalesLT.Product
ORDER BY 
    CASE Size
        WHEN 'XS' THEN 1
        WHEN 'S' THEN 2
        WHEN 'M' THEN 3
        WHEN 'L' THEN 4
        WHEN 'XL' THEN 5
        ELSE 6
    END;
```

### In GROUP BY

```sql
-- Group by CASE expression
SELECT 
    CASE
        WHEN ListPrice < 500 THEN 'Under $500'
        ELSE '$500+'
    END AS PriceRange,
    COUNT(*) AS ProductCount
FROM SalesLT.Product
GROUP BY 
    CASE
        WHEN ListPrice < 500 THEN 'Under $500'
        ELSE '$500+'
    END;
```

---

## ⚡ IIF() Function (Shorthand)

**IIF()** = Simplified CASE for simple true/false.

**Syntax**: `IIF(condition, true_result, false_result)`

```sql
-- CASE version
CASE WHEN ListPrice > 1000 THEN 'Expensive' ELSE 'Affordable' END

-- IIF version (shorter)
IIF(ListPrice > 1000, 'Expensive', 'Affordable')
```

### Example: IIF in Action

```sql
SELECT 
    ProductID,
    Name,
    ListPrice,
    IIF(ListPrice > 1000, 'High', 'Low') AS PriceLevel,
    IIF(Color IS NULL, 'No Color', Color) AS ColorDisplay
FROM SalesLT.Product;
```

---

## 🔗 Nested CASE

**CASE inside CASE** for complex logic.

### Example: Shipping Priority

```sql
SELECT 
    SalesOrderID,
    TotalDue,
    CASE
        WHEN TotalDue > 5000 THEN 'Express'
        WHEN TotalDue > 1000 THEN 
            CASE
                WHEN DATEDIFF(DAY, OrderDate, GETDATE()) < 7 THEN 'Standard'
                ELSE 'Economy'
            END
        ELSE 'Standard'
    END AS ShippingPriority
FROM SalesLT.SalesOrderHeader;
```

---

## 🎯 Practical Examples

### Example 1: Product Status Dashboard

```sql
SELECT 
    ProductID,
    Name,
    ListPrice,
    StandardCost,
    CASE
        WHEN StandardCost = 0 THEN 'Free/Promotional'
        WHEN ListPrice - StandardCost < 0 THEN 'Loss'
        WHEN ListPrice - StandardCost < 50 THEN 'Low Margin'
        WHEN ListPrice - StandardCost < 200 THEN 'Healthy Margin'
        ELSE 'High Margin'
    END AS MarginCategory,
    CASE
        WHEN SellEndDate IS NOT NULL THEN 'Discontinued'
        WHEN SellStartDate > GETDATE() THEN 'Coming Soon'
        ELSE 'Active'
    END AS ProductStatus
FROM SalesLT.Product;
```

### Example 2: Sales Performance Report

```sql
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalDue) AS MonthlyRevenue,
    CASE
        WHEN SUM(TotalDue) > 100000 THEN 'Excellent'
        WHEN SUM(TotalDue) > 50000 THEN 'Good'
        WHEN SUM(TotalDue) > 25000 THEN 'Fair'
        ELSE 'Poor'
    END AS Performance,
    IIF(SUM(TotalDue) > LAG(SUM(TotalDue)) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)), 
        'Growing', 'Declining') AS Trend
FROM SalesLT.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;
```

### Example 3: Customer Engagement Score

```sql
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    COUNT(soh.SalesOrderID) AS OrderCount,
    SUM(soh.TotalDue) AS TotalSpent,
    DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS DaysSinceLastOrder,
    -- Engagement score (0-100)
    CASE
        WHEN COUNT(soh.SalesOrderID) = 0 THEN 0
        WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 365 THEN 10
        WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 180 THEN 30
        WHEN COUNT(soh.SalesOrderID) >= 5 AND SUM(soh.TotalDue) > 5000 THEN 100
        WHEN COUNT(soh.SalesOrderID) >= 3 THEN 70
        ELSE 50
    END AS EngagementScore,
    -- Action recommendation
    CASE
        WHEN DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) > 365 THEN 'Re-engage with special offer'
        WHEN SUM(soh.TotalDue) > 10000 THEN 'Offer VIP benefits'
        WHEN COUNT(soh.SalesOrderID) = 1 THEN 'Send follow-up email'
        ELSE 'Continue normal marketing'
    END AS RecommendedAction
FROM SalesLT.Customer c
LEFT JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY EngagementScore DESC;
```

---

## ⚠️ CASE Best Practices

### 1. Always Include ELSE

```sql
-- ✅ GOOD: Handles unexpected values
CASE Size
    WHEN 'S' THEN 'Small'
    WHEN 'M' THEN 'Medium'
    ELSE 'Unknown'  -- Prevents NULL
END

-- ❌ BAD: Returns NULL if no match
CASE Size
    WHEN 'S' THEN 'Small'
    WHEN 'M' THEN 'Medium'
END
```

### 2. Order Conditions Carefully

```sql
-- ✅ GOOD: Most specific first
CASE
    WHEN Price > 1000 THEN 'Luxury'
    WHEN Price > 500 THEN 'Premium'
    WHEN Price > 100 THEN 'Mid-Range'
    ELSE 'Budget'
END

-- ❌ BAD: Never reaches other conditions
CASE
    WHEN Price > 0 THEN 'Budget'  -- Catches everything!
    WHEN Price > 500 THEN 'Premium'
END
```

---

## 📝 Lab 09: CASE Expressions

Complete `labs/lab_09_case.sql`.

**Tasks**: Simple CASE, searched CASE, nested logic, conditional aggregations, business rules.

---

*Next: [Section 10: Practice Project →](./10_practice_project.md)*
