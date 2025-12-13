# DAX Deep Dive - Complete Guide

## 📚 What You'll Learn
- Understanding context
- Advanced DAX patterns
- Time intelligence
- Performance optimization
- Interview preparation

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 Understanding Evaluation Context

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DAX EVALUATION CONTEXTS                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      ROW CONTEXT                                 │   │
│   │   • Created by calculated columns                                │   │
│   │   • Iterates row by row                                          │   │
│   │   • Access column values directly                                │   │
│   │                                                                  │   │
│   │   Example:                                                       │   │
│   │   LineTotal = [Quantity] * [UnitPrice]                          │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                     FILTER CONTEXT                               │   │
│   │   • Applied by slicers, filters, visuals                        │   │
│   │   • Flows through relationships                                  │   │
│   │   • Measures respond to filter context                           │   │
│   │                                                                  │   │
│   │   Example:                                                       │   │
│   │   Total Sales = SUM(Sales[Amount])                              │   │
│   │   → Returns different values based on filters                    │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │               CONTEXT TRANSITION                                 │   │
│   │   • CALCULATE transforms row context to filter context          │   │
│   │   • Enables using measures in calculated columns                 │   │
│   │                                                                  │   │
│   │   Example:                                                       │   │
│   │   RunningSales = CALCULATE([Total Sales])                       │   │
│   │   → Within iterator, applies current row as filter               │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Core DAX Functions

### CALCULATE - The Most Important Function

```dax
-- Syntax
CALCULATE(<expression>, <filter1>, <filter2>, ...)

-- Basic usage
Online Sales = 
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Channel] = "Online"
)

-- Multiple filters (AND logic)
US Online Sales = 
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Channel] = "Online",
    Sales[Country] = "USA"
)

-- Remove existing filters
Total Sales All Products = 
CALCULATE(
    SUM(Sales[Amount]),
    ALL(Products)  -- Ignores product filters
)

-- Keep specific filter
Sales Keeping Year = 
CALCULATE(
    SUM(Sales[Amount]),
    ALLEXCEPT(Sales, 'Date'[Year])
)
```

### Filter Modifiers

```dax
-- ALL: Remove all filters from table/column
All Sales = CALCULATE(SUM(Sales[Amount]), ALL(Sales))

-- ALLEXCEPT: Keep specific filters
Grouped Sales = CALCULATE(SUM(Sales[Amount]), ALLEXCEPT(Sales, Sales[Category]))

-- ALLSELECTED: Remove visual filters but keep slicer
Visual Total = CALCULATE(SUM(Sales[Amount]), ALLSELECTED(Sales))

-- REMOVEFILTERS (cleaner syntax for ALL)
Total Sales = CALCULATE(SUM(Sales[Amount]), REMOVEFILTERS(Sales[Product]))

-- KEEPFILTERS: Add filter without replacing
Expensive Red = 
CALCULATE(
    COUNTROWS(Products),
    KEEPFILTERS(Products[Color] = "Red"),
    Products[Price] > 100
)
```

### Iterator Functions (X Functions)

```dax
-- SUMX: Sum of expression evaluated row by row
Total Revenue = SUMX(Sales, Sales[Quantity] * Sales[UnitPrice])

-- AVERAGEX: Average of expression
Avg Line Value = AVERAGEX(Sales, Sales[Quantity] * Sales[Price])

-- MAXX / MINX: Max/Min of expression
Max Order Value = MAXX(Orders, Orders[Quantity] * Orders[Price])

-- COUNTX: Count non-blank results
Valid Orders = COUNTX(FILTER(Orders, Orders[Status] = "Completed"), 1)

-- RANKX: Ranking
Product Rank = RANKX(ALL(Products), [Total Sales], , DESC, Dense)
```

---

## 📅 Time Intelligence

### Date Table Requirement

```dax
-- Mark as Date Table
-- Table Tools → Mark as Date Table → Select date column

-- Or create Date Table
DateTable = 
ADDCOLUMNS(
    CALENDAR(DATE(2020,1,1), DATE(2025,12,31)),
    "Year", YEAR([Date]),
    "Month", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMMM"),
    "Quarter", "Q" & QUARTER([Date]),
    "YearMonth", FORMAT([Date], "YYYY-MM"),
    "DayOfWeek", WEEKDAY([Date]),
    "IsWeekend", IF(WEEKDAY([Date]) IN {1,7}, TRUE, FALSE)
)
```

### Period Comparisons

```dax
-- Previous Period
Previous Month Sales = 
CALCULATE(
    [Total Sales],
    PREVIOUSMONTH('Date'[Date])
)

-- Same Period Last Year
SPLY Sales = 
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR('Date'[Date])
)

-- Year over Year Change
YoY Change = [Total Sales] - [SPLY Sales]
YoY % = DIVIDE([YoY Change], [SPLY Sales])

-- Previous Year (parallel period)
PY Sales = 
CALCULATE(
    [Total Sales],
    PARALLELPERIOD('Date'[Date], -1, YEAR)
)
```

### Cumulative Totals

```dax
-- Year to Date
YTD Sales = TOTALYTD([Total Sales], 'Date'[Date])

-- Quarter to Date
QTD Sales = TOTALQTD([Total Sales], 'Date'[Date])

-- Month to Date
MTD Sales = TOTALMTD([Total Sales], 'Date'[Date])

-- Rolling 12 Months
Rolling 12M = 
CALCULATE(
    [Total Sales],
    DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -12, MONTH)
)

-- Running Total (within context)
Running Total = 
CALCULATE(
    [Total Sales],
    FILTER(
        ALL('Date'),
        'Date'[Date] <= MAX('Date'[Date])
    )
)
```

### Period Growth

```dax
-- Month over Month Growth %
MoM Growth = 
VAR CurrentMonth = [Total Sales]
VAR PreviousMonth = CALCULATE([Total Sales], PREVIOUSMONTH('Date'[Date]))
RETURN
    DIVIDE(CurrentMonth - PreviousMonth, PreviousMonth)

-- Quarter over Quarter
QoQ Growth = 
VAR CurrentQ = [Total Sales]
VAR PreviousQ = CALCULATE([Total Sales], PREVIOUSQUARTER('Date'[Date]))
RETURN
    DIVIDE(CurrentQ - PreviousQ, PreviousQ)
```

---

## 📊 Advanced Patterns

### Percentage Calculations

```dax
-- % of Total
% of Total = 
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALL(Sales))
)

-- % of Parent (hierarchy)
% of Category = 
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLEXCEPT(Products, Products[Category]))
)

-- % of Selected (respects slicers)
% of Selected = 
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLSELECTED(Sales))
)
```

### Dynamic Ranking

```dax
-- Basic Rank
Product Rank = 
RANKX(
    ALL(Products[ProductName]),
    [Total Sales],
    ,
    DESC,
    DENSE
)

-- Rank within Category
Category Rank = 
RANKX(
    ALLEXCEPT(Products, Products[Category]),
    [Total Sales],
    ,
    DESC
)

-- Top N Filter
Top 10 Products = 
VAR ProductRank = [Product Rank]
RETURN
    IF(ProductRank <= 10, [Total Sales], BLANK())
```

### Moving Averages

```dax
-- 3-Month Moving Average
3M Moving Avg = 
AVERAGEX(
    DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -3, MONTH),
    [Total Sales]
)

-- 7-Day Moving Average
7D Moving Avg = 
AVERAGEX(
    DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -7, DAY),
    [Daily Sales]
)
```

### Semi-Additive Measures (Snapshots)

```dax
-- Last Value (for balance/inventory)
Closing Balance = 
CALCULATE(
    MAX(Inventory[Balance]),
    LASTDATE('Date'[Date])
)

-- First Value
Opening Balance = 
CALCULATE(
    MAX(Inventory[Balance]),
    FIRSTDATE('Date'[Date])
)
```

---

## 🔄 Relationships and RELATED

### RELATED and RELATEDTABLE

```dax
-- RELATED: Get value from related table (many-to-one)
-- In Sales table (calculated column)
Product Category = RELATED(Products[Category])

-- RELATEDTABLE: Get related rows (one-to-many)
-- In Products table
Order Count = COUNTROWS(RELATEDTABLE(Sales))
```

### USERELATIONSHIP

```dax
-- Use inactive relationship
Ship Date Sales = 
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(Sales[ShipDate], 'Date'[Date])
)

-- Compare order vs ship date
Days to Ship = 
[Ship Date Sales] - [Order Date Sales]
```

### CROSSFILTER

```dax
-- Enable bidirectional filter in measure
Total with Bidirectional = 
CALCULATE(
    [Total Sales],
    CROSSFILTER(Sales[ProductID], Products[ProductID], BOTH)
)
```

---

## 🔍 Table Functions

### FILTER

```dax
-- Filter table based on condition
Large Orders = 
CALCULATE(
    [Total Sales],
    FILTER(Sales, Sales[Amount] > 1000)
)

-- Nested FILTER
Premium Customer Sales = 
CALCULATE(
    [Total Sales],
    FILTER(
        Customers,
        CALCULATE([Total Sales]) > 10000
    )
)
```

### VALUES and DISTINCT

```dax
-- VALUES: Unique values including blank
Product Count = COUNTROWS(VALUES(Products[ProductName]))

-- DISTINCT: Unique values
Unique Colors = COUNTROWS(DISTINCT(Products[Color]))

-- SELECTEDVALUE: Single selected value or default
Selected Year = SELECTEDVALUE('Date'[Year], "All Years")
```

### SUMMARIZE

```dax
-- Group by with calculations
Sales Summary = 
SUMMARIZE(
    Sales,
    Products[Category],
    "Total Sales", SUM(Sales[Amount]),
    "Avg Order", AVERAGE(Sales[Amount])
)
```

### ADDCOLUMNS

```dax
-- Add columns to table
Extended Products = 
ADDCOLUMNS(
    Products,
    "Sales", CALCULATE(SUM(Sales[Amount])),
    "Orders", CALCULATE(COUNTROWS(Sales))
)
```

---

## ⚡ Performance Optimization

### Best Practices

```dax
-- ✅ Use variables
Good Pattern = 
VAR TotalRev = SUM(Sales[Revenue])
VAR TotalCost = SUM(Sales[Cost])
RETURN
    DIVIDE(TotalRev - TotalCost, TotalRev)

-- ❌ Avoid repeated calculations
Bad Pattern = 
DIVIDE(
    SUM(Sales[Revenue]) - SUM(Sales[Cost]),
    SUM(Sales[Revenue])
)

-- ✅ Use DISTINCTCOUNT over COUNTROWS(VALUES())
Good = DISTINCTCOUNT(Sales[CustomerID])
Bad = COUNTROWS(DISTINCT(Sales[CustomerID]))

-- ✅ Use DIVIDE over manual division (handles divide by zero)
Good = DIVIDE([Sales], [Target])
Bad = IF([Target] = 0, BLANK(), [Sales] / [Target])
```

### Avoid These Patterns

```dax
-- ❌ FILTER with ALL on large tables
Bad = CALCULATE([Sales], FILTER(ALL(Sales), Sales[Date] = TODAY()))

-- ✅ Use simple predicates instead
Good = CALCULATE([Sales], Sales[Date] = TODAY())

-- ❌ Nested iterators without need
-- ✅ Simplify aggregation logic

-- ❌ Calculated columns for dynamic values
-- ✅ Use measures instead
```

---

## 🎓 Interview Questions

### Q1: What is the difference between row context and filter context?
**A:**
- **Row Context**: Iterates row by row (calculated columns, iterators)
- **Filter Context**: Set of filters applied to calculation (slicers, visuals, CALCULATE)

### Q2: What does CALCULATE do?
**A:** CALCULATE evaluates an expression in a modified filter context. It can add, remove, or modify filters.

### Q3: What is the difference between ALL and ALLEXCEPT?
**A:**
- **ALL**: Removes all filters from specified table/columns
- **ALLEXCEPT**: Removes all filters except specified columns

### Q4: What is context transition?
**A:** When CALCULATE is used in row context, it transforms the current row into a filter context, applying all column values as filters.

### Q5: How do you create a running total?
**A:**
```dax
Running Total = 
CALCULATE([Total Sales], FILTER(ALL('Date'), 'Date'[Date] <= MAX('Date'[Date])))
```

### Q6: What is the difference between SUMX and SUM?
**A:**
- **SUM**: Sums a single column
- **SUMX**: Sums an expression evaluated for each row (iterator)

### Q7: What is TOTALYTD?
**A:** Time intelligence function that calculates year-to-date total:
```dax
YTD Sales = TOTALYTD([Total Sales], 'Date'[Date])
```

### Q8: How do you calculate Year-over-Year growth?
**A:**
```dax
YoY = DIVIDE([Sales] - CALCULATE([Sales], SAMEPERIODLASTYEAR('Date'[Date])), 
             CALCULATE([Sales], SAMEPERIODLASTYEAR('Date'[Date])))
```

### Q9: What is SELECTEDVALUE used for?
**A:** Returns the value when filter context has single value, otherwise returns default:
```dax
Selected = SELECTEDVALUE(Products[Name], "Multiple")
```

### Q10: What are best practices for DAX performance?
**A:**
- Use variables to avoid repeated calculations
- Prefer simple predicates over FILTER
- Use DIVIDE instead of division
- Avoid nested iterators
- Use measures instead of calculated columns for dynamic values

---

## 🔗 Related Topics
- [← Power BI Fundamentals](./01_powerbi_fundamentals.md)
- [Data Modeling →](./03_data_modeling.md)
- [Report Design →](./04_report_design.md)

---

*Continue to Data Modeling*
