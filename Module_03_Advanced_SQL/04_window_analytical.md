# Section 04: Window Analytical Functions

**Estimated Time**: 6 hours  
**Difficulty**: ⭐⭐⭐⭐⭐ Expert  

---

## 🎯 Learning Objectives

✅ Use LAG and LEAD for time-series analysis  
✅ Calculate running totals with SUM OVER  
✅ Compute moving averages  
✅ Use FIRST_VALUE and LAST_VALUE  
✅ Master window frames (ROWS/RANGE)  

---

## 📊 Aggregate Functions with OVER

Any aggregate (SUM, AVG, COUNT, MIN, MAX) can become a window function with OVER.

### Running Total Example

```sql
SELECT 
    CustomerID,
    OrderDate,
    TotalDue,
    SUM(TotalDue) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM SalesLT.SalesOrderHeader
ORDER BY CustomerID, OrderDate;
```

**Output**:
```
CustomerID | OrderDate  | TotalDue | RunningTotal
-----------|------------|----------|-------------
1          | 2008-01-01 | 500      | 500
1          | 2008-02-01 | 300      | 800  (500+300)
1          | 2008-03-01 | 200      | 1000 (500+300+200)
2          | 2008-01-05 | 400      | 400  (resets for new customer)
```

---

## ⬅️➡️ LAG and LEAD

**LAG**: Access **previous** row's value  
**LEAD**: Access **next** row's value

### Example: Month-over-Month Growth

```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(TotalDue) AS MonthlyRevenue
    FROM SalesLT.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    Year,
    Month,
    MonthlyRevenue,
    LAG(MonthlyRevenue, 1) OVER (ORDER BY Year, Month) AS PreviousMonth,
    MonthlyRevenue - LAG(MonthlyRevenue, 1) OVER (ORDER BY Year, Month) AS Difference,
    CASE 
        WHEN LAG(MonthlyRevenue, 1) OVER (ORDER BY Year, Month) IS NULL THEN NULL
        ELSE CAST((MonthlyRevenue - LAG(MonthlyRevenue, 1) OVER (ORDER BY Year, Month)) 
             / LAG(MonthlyRevenue, 1) OVER (ORDER BY Year, Month) * 100 AS DECIMAL(10,2))
    END AS GrowthPercent
FROM MonthlySales
ORDER BY Year, Month;
```

**Use cases**: Time-series, trend analysis, change detection.

---

## 📈 Moving Averages

```sql
SELECT 
    OrderDate,
    TotalDue,
    AVG(TotalDue) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3Days
FROM SalesLT.SalesOrderHeader
ORDER BY OrderDate;
```

**Explanation**: Average of current row + 2 preceding rows (3-day moving average).

---

## 🎯 FIRST_VALUE and LAST_VALUE

```sql
SELECT 
    CustomerID,
    OrderDate,
    TotalDue,
    FIRST_VALUE(TotalDue) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
    ) AS FirstOrderAmount,
    LAST_VALUE(TotalDue) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS LastOrderAmount
FROM SalesLT.SalesOrderHeader;
```

---

## 🪟 Window Frames (ROWS vs RANGE)

**Frame**: Subset of partition to include in calculation.

**Syntax**:
```sql
ROWS BETWEEN start AND end
RANGE BETWEEN start AND end
```

**Common frames**:
```sql
-- All rows from start to current
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Current + 2 preceding (3-day moving average)
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW

-- All rows in partition
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- Current row only (default for ranking functions)
ROWS BETWEEN CURRENT ROW AND CURRENT ROW
```

---

## 🎯 Practical Examples

### Example 1: Customer Retention Analysis

```sql
WITH CustomerOrders AS (
    SELECT 
        CustomerID,
        OrderDate,
        LAG(OrderDate, 1) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousOrderDate,
        DATEDIFF(DAY, 
            LAG(OrderDate, 1) OVER (PARTITION BY CustomerID ORDER BY OrderDate),
            OrderDate
        ) AS DaysSinceLastOrder
    FROM SalesLT.SalesOrderHeader
)
SELECT 
    CustomerID,
    OrderDate,
    PreviousOrderDate,
    DaysSinceLastOrder,
    CASE 
        WHEN DaysSinceLastOrder IS NULL THEN 'First Order'
        WHEN DaysSinceLastOrder <= 30 THEN 'Frequent'
        WHEN DaysSinceLastOrder <= 90 THEN 'Regular'
        ELSE 'Returning'
    END AS CustomerType
FROM CustomerOrders
ORDER BY CustomerID, OrderDate;
```

---

## 📝 Lab 14: Window Analytical Functions

Complete `labs/lab_14_window_functions.sql`.

**Tasks**:
1. Running totals per customer
2. Month-over-month growth
3. 7-day moving average
4. LAG/LEAD for time-series
5. Compare first vs last order amounts

---

**Next**: [Section 05: Query Optimization →](./05_query_optimization.md)
