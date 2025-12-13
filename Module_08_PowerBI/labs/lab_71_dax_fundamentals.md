# Lab 71: DAX Fundamentals

## Objective
Learn the fundamentals of Data Analysis Expressions (DAX) including calculated columns, measures, filter functions, and time intelligence to create powerful analytics in Power BI.

## Prerequisites
- Completion of Labs 68-70
- Power BI Desktop with data model from previous labs
- Understanding of star schema concepts

## Duration
120 minutes

---

## Part 1: Introduction to DAX

### What is DAX?

**Data Analysis Expressions (DAX)** is a formula language used in:
- Power BI
- Power Pivot (Excel)
- SQL Server Analysis Services (Tabular)

DAX is designed for:
- Creating calculations on data models
- Aggregating and analyzing data
- Defining business logic

### DAX vs Excel vs SQL

| Feature | DAX | Excel | SQL |
|---------|-----|-------|-----|
| Works on | Tables/Columns | Cells | Tables/Rows |
| Context | Row & Filter | Cell reference | Row-based |
| Aggregations | Implicit/Explicit | Formulas | GROUP BY |
| Relationships | Automatic | VLOOKUP | JOINs |

### DAX Expression Types

1. **Calculated Columns** - New column added to a table
2. **Measures** - Dynamic calculations based on context
3. **Calculated Tables** - New tables from expressions

---

## Part 2: Calculated Columns vs Measures

### Calculated Columns

**Characteristics:**
- Evaluated row by row during data refresh
- Stored in the model (uses memory)
- Has a row context
- Values fixed until refresh

**When to use:**
- Need to slice/filter by the value
- Value depends on current row only
- Creating categories or groupings

**Syntax:**
```dax
ColumnName = <expression using [columns]>
```

### Measures

**Characteristics:**
- Evaluated dynamically at query time
- Not stored (calculated on the fly)
- Has a filter context
- Values change based on filters

**When to use:**
- Aggregations (SUM, COUNT, etc.)
- Calculations that depend on filters
- Most business calculations

**Syntax:**
```dax
MeasureName = <expression returning single value>
```

### Comparison Table

| Aspect | Calculated Column | Measure |
|--------|------------------|---------|
| Evaluated | At refresh | At query time |
| Storage | Uses memory | Not stored |
| Context | Row | Filter |
| Use in slicers | Yes | No |
| Performance | Faster at query | Depends |
| Aggregation | No | Yes |

### Exercise 2.1: Create a Calculated Column

1. Go to **Data View**
2. Select the **DimBook** table (or Books)
3. In the formula bar, enter:

```dax
PriceCategory = 
IF(
    DimBook[Price] < 20, "Budget",
    IF(
        DimBook[Price] < 50, "Standard",
        IF(
            DimBook[Price] < 100, "Premium",
            "Luxury"
        )
    )
)
```

4. Press Enter
5. New column appears in the table

### Exercise 2.2: Create a Measure

1. Go to **Report View**
2. In the Fields pane, right-click **FactSales** → **New Measure**
3. Enter:

```dax
Total Sales = SUM(FactSales[SalesAmount])
```

4. Press Enter
5. Use in a Card visual to see the result

---

## Part 3: Basic Aggregation Functions

### Common Aggregation Functions

| Function | Description | Example |
|----------|-------------|---------|
| SUM | Total of column | SUM(Sales[Amount]) |
| AVERAGE | Average value | AVERAGE(Sales[Amount]) |
| COUNT | Count rows with values | COUNT(Sales[ProductID]) |
| COUNTA | Count non-blank cells | COUNTA(Customer[Name]) |
| COUNTROWS | Count rows in table | COUNTROWS(Sales) |
| COUNTBLANK | Count blank cells | COUNTBLANK(Customer[Phone]) |
| DISTINCTCOUNT | Count unique values | DISTINCTCOUNT(Sales[CustomerID]) |
| MIN | Minimum value | MIN(Sales[Date]) |
| MAX | Maximum value | MAX(Sales[Date]) |

### Exercise 3.1: Create Basic Measures

Create these measures in FactSales:

```dax
// Total Sales Amount
Total Sales = SUM(FactSales[SalesAmount])

// Total Quantity Sold
Total Quantity = SUM(FactSales[Quantity])

// Number of Transactions
Transaction Count = COUNTROWS(FactSales)

// Number of Unique Customers
Customer Count = DISTINCTCOUNT(FactSales[CustomerKey])

// Average Sale Value
Average Sale = AVERAGE(FactSales[SalesAmount])

// Average Order Value
Avg Order Value = DIVIDE([Total Sales], [Transaction Count])
```

### Exercise 3.2: Test Your Measures

1. Create a Table visual
2. Add: `DimDate[Year]`, `[Total Sales]`, `[Transaction Count]`
3. Add a slicer for Category
4. Observe how measures change with filters

---

## Part 4: Understanding Context

### Row Context

**Definition:** The current row being evaluated.

**Where it exists:**
- Calculated columns
- Iterator functions (SUMX, etc.)
- Row-by-row operations

**Example:**
```dax
// Calculated column - row context exists
ExtendedAmount = FactSales[Quantity] * FactSales[UnitPrice]
```

### Filter Context

**Definition:** The set of filters applied to a calculation.

**Where it comes from:**
- Report filters
- Page filters
- Visual filters
- Slicer selections
- Cross-filtering
- Row/column headers in matrix

**Example:**
```dax
// Measure - filter context from visual
Total Sales = SUM(FactSales[SalesAmount])
// Returns different values based on what's filtered
```

### Context Visualization

```
┌─────────────────────────────────────────────────────┐
│                    REPORT FILTER                     │
│                  Year = 2024                         │
│  ┌───────────────────────────────────────────────┐  │
│  │              PAGE FILTER                       │  │
│  │           Region = "North"                     │  │
│  │  ┌─────────────────────────────────────────┐  │  │
│  │  │           VISUAL FILTER                  │  │  │
│  │  │        Category = "Fiction"              │  │  │
│  │  │  ┌─────────────────────────────────┐    │  │  │
│  │  │  │  Matrix Row: Customer = "John"  │    │  │  │
│  │  │  │                                 │    │  │  │
│  │  │  │  [Total Sales] = ???           │    │  │  │
│  │  │  │  (Filtered by all contexts)     │    │  │  │
│  │  │  └─────────────────────────────────┘    │  │  │
│  │  └─────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Exercise 4.1: Observe Filter Context

1. Create a matrix with:
   - Rows: `DimDate[Year]`, `DimDate[Quarter]`
   - Values: `[Total Sales]`

2. Add a slicer for `DimBook[Category]`

3. Notice how the same measure shows different values based on:
   - Row (Year/Quarter)
   - Slicer selection

---

## Part 5: CALCULATE Function

### The Most Important DAX Function

**CALCULATE** modifies the filter context for an expression.

**Syntax:**
```dax
CALCULATE(
    <expression>,
    <filter1>,
    <filter2>,
    ...
)
```

**How it works:**
1. Takes the current filter context
2. Applies the specified filters
3. Evaluates the expression in the new context

### Exercise 5.1: Basic CALCULATE Examples

```dax
// Sales for Fiction category only
Fiction Sales = 
CALCULATE(
    [Total Sales],
    DimBook[Category] = "Fiction"
)

// Sales in 2024 only
Sales 2024 = 
CALCULATE(
    [Total Sales],
    DimDate[Year] = 2024
)

// Sales for Fiction in 2024
Fiction Sales 2024 = 
CALCULATE(
    [Total Sales],
    DimBook[Category] = "Fiction",
    DimDate[Year] = 2024
)
```

### Exercise 5.2: CALCULATE with Context Override

```dax
// Total Sales ignoring year filter
Total Sales All Years = 
CALCULATE(
    [Total Sales],
    ALL(DimDate[Year])
)

// Percentage of Total
Sales % of Total = 
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALL(FactSales))
)
```

---

## Part 6: Filter Functions

### ALL Function Family

| Function | Description | Use Case |
|----------|-------------|----------|
| ALL | Remove all filters from table/columns | Grand totals |
| ALLEXCEPT | Remove all filters except specified | Keep one filter |
| ALLSELECTED | Remove filters from current visual | Visual totals |
| REMOVEFILTERS | Same as ALL (clearer name) | Clarity in code |

### Exercise 6.1: Using ALL Functions

```dax
// Percentage of Total Category (remove all filters from fact table)
% of Total = 
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALL(FactSales))
)

// Percentage within Category (keep category filter)
% of Category = 
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLEXCEPT(FactSales, DimBook[Category]))
)

// Percentage of Visual Total
% of Visual = 
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLSELECTED())
)
```

### FILTER Function

Returns a filtered table based on condition.

**Syntax:**
```dax
FILTER(<table>, <condition>)
```

### Exercise 6.2: Using FILTER

```dax
// Sales of expensive books (>$50)
Expensive Book Sales = 
CALCULATE(
    [Total Sales],
    FILTER(
        DimBook,
        DimBook[Price] > 50
    )
)

// Sales from high-value transactions
High Value Sales = 
CALCULATE(
    [Total Sales],
    FILTER(
        FactSales,
        FactSales[SalesAmount] > 100
    )
)
```

### VALUES and SELECTEDVALUE

```dax
// Get selected category (for dynamic titles)
Selected Category = SELECTEDVALUE(DimBook[Category], "All Categories")

// Count of selected items
Selected Years = COUNTROWS(VALUES(DimDate[Year]))
```

---

## Part 7: RELATED and RELATEDTABLE

### RELATED Function

Brings a value from a related table (following the relationship).

**Use:** In calculated columns or with row context.

```dax
// In FactSales - get the book title
Book Title = RELATED(DimBook[Title])

// In FactSales - get customer name
Customer Name = RELATED(DimCustomer[CustomerName])
```

### RELATEDTABLE Function

Returns all related rows from another table.

**Use:** With aggregations in calculated columns.

```dax
// In DimCustomer - count of orders
Order Count = COUNTROWS(RELATEDTABLE(FactSales))

// In DimBook - total sales
Total Book Sales = SUMX(RELATEDTABLE(FactSales), FactSales[SalesAmount])
```

### Exercise 7.1: Use RELATED

1. Go to Data View
2. Select FactSales table
3. Create calculated column:

```dax
Category = RELATED(DimBook[Category])
```

4. Now you can slice FactSales by category without needing the relationship

---

## Part 8: Logical Functions

### IF Function

```dax
IF(<condition>, <true_result>, <false_result>)
```

### Exercise 8.1: Conditional Measures

```dax
// Sales Status
Sales Status = 
IF(
    [Total Sales] > 100000,
    "High",
    IF([Total Sales] > 50000, "Medium", "Low")
)

// Performance Indicator
Performance = 
IF(
    [Total Sales] >= [Sales Target],
    "Above Target",
    "Below Target"
)
```

### SWITCH Function

Better than nested IFs for multiple conditions:

```dax
// Using SWITCH
Sales Rating = 
SWITCH(
    TRUE(),
    [Total Sales] > 100000, "★★★★★",
    [Total Sales] > 75000, "★★★★",
    [Total Sales] > 50000, "★★★",
    [Total Sales] > 25000, "★★",
    "★"
)

// SWITCH with exact match
Day Type = 
SWITCH(
    WEEKDAY(DimDate[Date]),
    1, "Weekend",
    7, "Weekend",
    "Weekday"
)
```

### Other Logical Functions

```dax
// AND/OR
High Value Customer = 
IF(
    AND([Total Sales] > 10000, [Order Count] > 10),
    "Yes",
    "No"
)

// Alternative syntax
High Value Customer = 
IF(
    [Total Sales] > 10000 && [Order Count] > 10,
    "Yes",
    "No"
)

// COALESCE - first non-blank value
Display Name = COALESCE(Customer[NickName], Customer[FirstName], "Unknown")

// IFERROR
Safe Division = IFERROR([Total Sales] / [Order Count], 0)

// ISBLANK
Has Phone = IF(ISBLANK(Customer[Phone]), "No", "Yes")
```

---

## Part 9: Math and Statistical Functions

### Common Math Functions

```dax
// Division with error handling
Avg Order Value = DIVIDE([Total Sales], [Order Count], 0)

// Rounding
Rounded Sales = ROUND([Total Sales], 2)
Rounded Up = ROUNDUP([Total Sales], 0)
Rounded Down = ROUNDDOWN([Total Sales], 0)

// Absolute value
Absolute Variance = ABS([Actual] - [Budget])

// Power/Square root
Squared = POWER([Value], 2)
Square Root = SQRT([Value])
```

### Statistical Functions

```dax
// Median
Median Sales = MEDIAN(FactSales[SalesAmount])

// Standard Deviation
Sales StdDev = STDEV.P(FactSales[SalesAmount])

// Percentile
Sales P90 = PERCENTILE.INC(FactSales[SalesAmount], 0.9)

// Rank
Sales Rank = 
RANKX(
    ALL(DimBook[Category]),
    [Total Sales],
    ,
    DESC,
    DENSE
)
```

### Exercise 9.1: Create Analysis Measures

```dax
// Variance from average
Variance from Avg = [Total Sales] - [Average Sale] * [Transaction Count]

// Moving calculations using EARLIER (in calculated columns)
Running Total = 
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(DimDate),
        DimDate[Date] <= MAX(DimDate[Date])
    )
)
```

---

## Part 10: Time Intelligence Basics

### Time Intelligence Requirements

1. A date table with:
   - Contiguous dates (no gaps)
   - One row per date
   - Date column marked as Date table

2. Relationship between date table and fact table

### Mark as Date Table

1. Select your date table
2. Table tools → Mark as date table
3. Select the date column

### Basic Time Intelligence Functions

| Function | Description | Example |
|----------|-------------|---------|
| TOTALYTD | Year-to-date total | Running total for year |
| TOTALQTD | Quarter-to-date total | Running total for quarter |
| TOTALMTD | Month-to-date total | Running total for month |
| SAMEPERIODLASTYEAR | Same period last year | Year-over-year comparison |
| PREVIOUSYEAR | Previous year's period | Prior year analysis |
| PREVIOUSMONTH | Previous month | Month-over-month |
| DATEADD | Shift dates | Flexible comparisons |

### Exercise 10.1: Create Time Intelligence Measures

```dax
// Year-to-Date Sales
YTD Sales = TOTALYTD([Total Sales], DimDate[Date])

// Previous Year Sales
PY Sales = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(DimDate[Date]))

// Year-over-Year Change
YoY Change = [Total Sales] - [PY Sales]

// Year-over-Year % Change
YoY % Change = DIVIDE([YoY Change], [PY Sales])

// Month-to-Date
MTD Sales = TOTALMTD([Total Sales], DimDate[Date])

// Quarter-to-Date
QTD Sales = TOTALQTD([Total Sales], DimDate[Date])
```

### Exercise 10.2: More Time Calculations

```dax
// Last 30 days
Last 30 Days Sales = 
CALCULATE(
    [Total Sales],
    DATESINPERIOD(DimDate[Date], MAX(DimDate[Date]), -30, DAY)
)

// Same period previous quarter
Same Period Last Quarter = 
CALCULATE(
    [Total Sales],
    DATEADD(DimDate[Date], -1, QUARTER)
)

// Rolling 12 months
Rolling 12M Sales = 
CALCULATE(
    [Total Sales],
    DATESINPERIOD(DimDate[Date], MAX(DimDate[Date]), -12, MONTH)
)
```

---

## Part 11: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ DAX basics and expression types
2. ✅ Calculated columns vs measures
3. ✅ Aggregation functions
4. ✅ Row context and filter context
5. ✅ CALCULATE function
6. ✅ Filter functions (ALL, FILTER, VALUES)
7. ✅ RELATED and RELATEDTABLE
8. ✅ Logical functions (IF, SWITCH)
9. ✅ Math and statistical functions
10. ✅ Basic time intelligence

### Quiz

**Question 1:** What's the main difference between a calculated column and a measure?
- a) Calculated columns use M, measures use DAX
- b) Calculated columns are evaluated at refresh, measures at query time
- c) Calculated columns can't use functions
- d) Measures can be used in slicers

**Question 2:** Which function modifies the filter context?
- a) SUM
- b) IF
- c) CALCULATE
- d) RELATED

**Question 3:** What does ALL() do?
- a) Returns all columns
- b) Removes filters from specified table/columns
- c) Counts all rows
- d) Aggregates all values

**Question 4:** When would you use RELATED()?
- a) To create a measure
- b) To get a value from a related table in row context
- c) To calculate aggregates
- d) To filter data

**Question 5:** Which function calculates year-to-date totals?
- a) YTD()
- b) TOTALYTD()
- c) YEARTODATE()
- d) CUMULATIVE()

### Answers
1. b) Calculated columns are evaluated at refresh, measures at query time
2. c) CALCULATE
3. b) Removes filters from specified table/columns
4. b) To get a value from a related table in row context
5. b) TOTALYTD()

---

## Next Lab
**Lab 72: Advanced DAX** - Master iterator functions, table functions, variables, and advanced DAX patterns.
