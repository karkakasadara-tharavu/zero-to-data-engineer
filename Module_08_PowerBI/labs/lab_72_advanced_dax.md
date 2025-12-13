# Lab 72: Advanced DAX

## Objective
Master advanced DAX concepts including iterator functions, table functions, variables, context transition, and complex calculation patterns for sophisticated analytics.

## Prerequisites
- Completion of Lab 71 (DAX Fundamentals)
- Power BI Desktop with configured data model
- Strong understanding of filter context

## Duration
120 minutes

---

## Part 1: Iterator Functions

### What Are Iterator Functions?

Iterator functions (ending in "X"):
- Iterate row by row over a table
- Create a row context for each row
- Evaluate an expression for each row
- Aggregate the results

### Common Iterator Functions

| Function | Description | Non-Iterator Equivalent |
|----------|-------------|------------------------|
| SUMX | Sum of expressions | SUM |
| AVERAGEX | Average of expressions | AVERAGE |
| COUNTX | Count of expressions | COUNT |
| MINX | Minimum expression value | MIN |
| MAXX | Maximum expression value | MAX |
| RANKX | Rank based on expression | - |
| PRODUCTX | Product of expressions | - |
| CONCATENATEX | Concatenate text | - |

### Syntax Pattern

```dax
FUNCTIONX(<table>, <expression>)
```

### Exercise 1.1: Basic Iterator Examples

```dax
// Calculate extended amount (Quantity * UnitPrice) for each row, then sum
Total Extended Amount = 
SUMX(
    FactSales,
    FactSales[Quantity] * FactSales[UnitPrice]
)

// Average revenue per transaction
Avg Revenue Per Transaction = 
AVERAGEX(
    FactSales,
    FactSales[Quantity] * FactSales[UnitPrice]
)

// Count transactions above threshold
High Value Transaction Count = 
COUNTX(
    FILTER(FactSales, FactSales[SalesAmount] > 100),
    1
)
```

### Exercise 1.2: SUMX with RELATED

```dax
// Sum of sales weighted by book price
Weighted Sales = 
SUMX(
    FactSales,
    FactSales[Quantity] * RELATED(DimBook[Price])
)

// Total profit calculation
Total Profit = 
SUMX(
    FactSales,
    FactSales[Quantity] * (RELATED(DimBook[Price]) - RELATED(DimBook[Cost]))
)
```

### Exercise 1.3: CONCATENATEX

```dax
// List of categories sold
Categories Sold = 
CONCATENATEX(
    VALUES(DimBook[Category]),
    DimBook[Category],
    ", ",
    DimBook[Category], ASC
)

// List of top 3 books by sales
Top 3 Books = 
CONCATENATEX(
    TOPN(3, 
        SUMMARIZE(FactSales, DimBook[Title], "Sales", [Total Sales]),
        [Sales], DESC
    ),
    DimBook[Title],
    ", "
)
```

---

## Part 2: RANKX Function

### Basic RANKX Syntax

```dax
RANKX(<table>, <expression>, [value], [order], [ties])
```

**Parameters:**
- **table**: Table to rank over
- **expression**: Expression to evaluate for ranking
- **value**: (Optional) Value to find rank of
- **order**: ASC or DESC (default)
- **ties**: SKIP or DENSE (how to handle ties)

### Exercise 2.1: Basic Ranking

```dax
// Rank books by sales
Book Sales Rank = 
RANKX(
    ALL(DimBook),
    [Total Sales],
    ,
    DESC,
    DENSE
)

// Rank categories by sales
Category Rank = 
RANKX(
    ALL(DimBook[Category]),
    [Total Sales],
    ,
    DESC
)

// Rank within each category
Rank Within Category = 
RANKX(
    ALLEXCEPT(DimBook, DimBook[Category]),
    [Total Sales],
    ,
    DESC
)
```

### Exercise 2.2: Dynamic Ranking

```dax
// Rank that respects current filters
Dynamic Rank = 
RANKX(
    ALLSELECTED(DimBook),
    [Total Sales],
    ,
    DESC
)

// Show only Top N (use with slicer)
Top N Filter = 
VAR CurrentRank = [Dynamic Rank]
VAR TopNValue = SELECTEDVALUE('Top N Parameter'[Value], 10)
RETURN
IF(CurrentRank <= TopNValue, [Total Sales], BLANK())
```

---

## Part 3: Table Functions

### Creating Virtual Tables

Table functions return tables that can be used in:
- Filter arguments
- Iterator functions
- Calculated tables

### SUMMARIZE Function

Creates a grouped/aggregated table.

```dax
SUMMARIZE(<table>, <groupBy_column>, [<name>, <expression>], ...)
```

### Exercise 3.1: Using SUMMARIZE

```dax
// Create summary table
Sales By Category = 
SUMMARIZE(
    FactSales,
    DimBook[Category],
    "Total Sales", SUM(FactSales[SalesAmount]),
    "Transaction Count", COUNTROWS(FactSales)
)

// Use in a measure
Avg Category Sales = 
AVERAGEX(
    SUMMARIZE(
        FactSales,
        DimBook[Category],
        "CatSales", [Total Sales]
    ),
    [CatSales]
)
```

### ADDCOLUMNS Function

Adds calculated columns to a table.

```dax
ADDCOLUMNS(<table>, <name>, <expression>, ...)
```

### Exercise 3.2: Using ADDCOLUMNS

```dax
// Enhanced book table with calculations
Book Analysis = 
ADDCOLUMNS(
    DimBook,
    "Total Sales", [Total Sales],
    "Avg Order Size", [Avg Order Value],
    "Sales Rank", [Book Sales Rank]
)

// Use for filtering
Top Performing Books = 
FILTER(
    ADDCOLUMNS(
        DimBook,
        "Sales", [Total Sales]
    ),
    [Sales] > 10000
)
```

### SELECTCOLUMNS Function

Creates a new table with specified columns.

```dax
// Select specific columns
Customer Summary = 
SELECTCOLUMNS(
    DimCustomer,
    "Customer", DimCustomer[CustomerName],
    "City", DimCustomer[City],
    "Sales", [Total Sales]
)
```

### TOPN Function

Returns top N rows.

```dax
// Top 10 customers by sales
Top10Customers = 
TOPN(
    10,
    DimCustomer,
    [Total Sales],
    DESC
)

// Measure: Sales from top 10 customers
Top 10 Customer Sales = 
CALCULATE(
    [Total Sales],
    TOPN(10, DimCustomer, [Total Sales], DESC)
)
```

### Exercise 3.3: Combine Table Functions

```dax
// Complex: Average of top 5 category sales
Avg Top 5 Category Sales = 
AVERAGEX(
    TOPN(
        5,
        ADDCOLUMNS(
            VALUES(DimBook[Category]),
            "CategorySales", [Total Sales]
        ),
        [CategorySales], DESC
    ),
    [CategorySales]
)
```

---

## Part 4: Variables in DAX

### Why Use Variables?

1. **Readability** - Easier to understand complex formulas
2. **Performance** - Expression evaluated once, reused
3. **Debugging** - Easier to troubleshoot
4. **Maintainability** - Single point of change

### Syntax

```dax
MeasureName = 
VAR variableName = <expression>
VAR anotherVariable = <expression>
RETURN
<result expression using variables>
```

### Exercise 4.1: Basic Variable Usage

```dax
// Without variables (harder to read)
YoY Growth % Old = 
DIVIDE(
    [Total Sales] - CALCULATE([Total Sales], SAMEPERIODLASTYEAR(DimDate[Date])),
    CALCULATE([Total Sales], SAMEPERIODLASTYEAR(DimDate[Date]))
)

// With variables (cleaner)
YoY Growth % = 
VAR CurrentSales = [Total Sales]
VAR PriorSales = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(DimDate[Date]))
VAR Change = CurrentSales - PriorSales
RETURN
DIVIDE(Change, PriorSales)
```

### Exercise 4.2: Variables for Complex Logic

```dax
// Performance rating with multiple thresholds
Performance Rating = 
VAR CurrentSales = [Total Sales]
VAR AvgSales = CALCULATE([Total Sales], ALL()) / DISTINCTCOUNT(DimBook[BookKey])
VAR Ratio = DIVIDE(CurrentSales, AvgSales)
RETURN
SWITCH(
    TRUE(),
    Ratio >= 2, "★★★★★ Exceptional",
    Ratio >= 1.5, "★★★★ Above Average",
    Ratio >= 1, "★★★ Average",
    Ratio >= 0.5, "★★ Below Average",
    "★ Poor"
)
```

### Exercise 4.3: Variables for Debugging

```dax
// Use RETURN with a variable to debug
Debug Measure = 
VAR Step1 = [Total Sales]
VAR Step2 = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(DimDate[Date]))
VAR Step3 = Step1 - Step2
VAR Step4 = DIVIDE(Step3, Step2)
RETURN
Step4  // Change this to Step1, Step2, etc. to debug each step
```

---

## Part 5: Context Transition

### What is Context Transition?

When CALCULATE converts row context into filter context.

**Rule:** When CALCULATE wraps a measure that has row context, it filters the model by the current row's values.

### Example: Row Context

```dax
// Calculated column without context transition
Sales CC Wrong = [Total Sales]  -- This gives the SAME value for every row

// Calculated column WITH context transition
Sales CC Right = CALCULATE([Total Sales])  -- Different value per row
```

### Exercise 5.1: Understanding Context Transition

Create a calculated column in DimCustomer:

```dax
// Each customer's total sales
Customer Total Sales = CALCULATE([Total Sales])
```

**What happens:**
1. Row context exists (we're in a calculated column)
2. Current row has CustomerKey = 1
3. CALCULATE converts this to a filter: CustomerKey = 1
4. Measure [Total Sales] is evaluated with this filter

### Exercise 5.2: Context Transition in Iterators

```dax
// SUMX with context transition
Total Sales Via Iterator = 
SUMX(
    DimCustomer,
    CALCULATE([Total Sales])  -- Context transition happens here
)

// This is equivalent to
Total Sales Direct = [Total Sales]  -- Same result, more efficient
```

### When Context Transition is Useful

```dax
// Calculate something special per customer, then aggregate
Customers Above Threshold = 
VAR Threshold = 1000
RETURN
SUMX(
    DimCustomer,
    IF(CALCULATE([Total Sales]) > Threshold, 1, 0)
)

// Average customer lifetime value
Avg Customer LTV = 
AVERAGEX(
    DimCustomer,
    CALCULATE([Total Sales])
)
```

---

## Part 6: Advanced CALCULATE Patterns

### Multiple Filters

```dax
// Multiple filter conditions
Specific Sales = 
CALCULATE(
    [Total Sales],
    DimDate[Year] = 2024,
    DimBook[Category] = "Fiction",
    DimCustomer[Region] = "North"
)
```

### Filter with Logical OR

```dax
// Sales for Fiction OR Non-Fiction
FN Sales = 
CALCULATE(
    [Total Sales],
    DimBook[Category] IN {"Fiction", "Non-Fiction"}
)

// Alternative using FILTER
FN Sales Alt = 
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(DimBook[Category]),
        DimBook[Category] = "Fiction" || DimBook[Category] = "Non-Fiction"
    )
)
```

### KEEPFILTERS Modifier

Normally, CALCULATE replaces existing filters. KEEPFILTERS adds to them.

```dax
// Replace filter (default)
Fiction Sales Replace = 
CALCULATE([Total Sales], DimBook[Category] = "Fiction")

// Keep existing filter AND add new one
Fiction Sales Keep = 
CALCULATE([Total Sales], KEEPFILTERS(DimBook[Category] = "Fiction"))
```

### USERELATIONSHIP

Activate an inactive relationship:

```dax
// Shipped sales (using inactive relationship)
Shipped Sales = 
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(FactSales[ShipDateKey], DimDate[DateKey])
)
```

### Exercise 6.1: Complex CALCULATE

```dax
// Market Share: Category sales as % of all sales in same period
Category Market Share = 
VAR CurrentCategorySales = [Total Sales]
VAR TotalSalesAllCategories = 
    CALCULATE(
        [Total Sales],
        ALL(DimBook[Category])
    )
RETURN
DIVIDE(CurrentCategorySales, TotalSalesAllCategories)

// Contribution to Parent
Parent Contribution = 
VAR CurrentSales = [Total Sales]
VAR ParentSales = 
    CALCULATE(
        [Total Sales],
        ALLEXCEPT(DimBook, DimBook[Category])
    )
RETURN
DIVIDE(CurrentSales, ParentSales)
```

---

## Part 7: Advanced Time Intelligence

### Moving Averages

```dax
// 3-Month Moving Average
Moving Avg 3M = 
AVERAGEX(
    DATESINPERIOD(DimDate[Date], MAX(DimDate[Date]), -3, MONTH),
    [Total Sales]
)

// Alternative with explicit calculation
Moving Avg 3M Alt = 
VAR EndDate = MAX(DimDate[Date])
VAR StartDate = EDATE(EndDate, -2)  -- 3 months including current
RETURN
CALCULATE(
    AVERAGEX(VALUES(DimDate[Month]), [Total Sales]),
    DATESBETWEEN(DimDate[Date], StartDate, EndDate)
)
```

### Rolling Totals

```dax
// Rolling 12-Month Total
Rolling 12M = 
CALCULATE(
    [Total Sales],
    DATESINPERIOD(DimDate[Date], MAX(DimDate[Date]), -12, MONTH)
)

// Running Total for Year
Running Total YTD = 
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(DimDate),
        DimDate[Year] = MAX(DimDate[Year])
        && DimDate[Date] <= MAX(DimDate[Date])
    )
)
```

### Period Comparisons

```dax
// Month-over-Month Change
MoM Change = 
VAR CurrentMonth = [Total Sales]
VAR PriorMonth = CALCULATE([Total Sales], PREVIOUSMONTH(DimDate[Date]))
RETURN
CurrentMonth - PriorMonth

// Parallel Period (same period in prior year)
Parallel Period Sales = 
CALCULATE(
    [Total Sales],
    PARALLELPERIOD(DimDate[Date], -12, MONTH)
)

// First Day of Current Selection
Period Start = FIRSTDATE(DimDate[Date])

// Last Day of Current Selection  
Period End = LASTDATE(DimDate[Date])
```

### Exercise 7.1: Time Comparison Matrix

```dax
// Complete time analysis measure set
Current Period = [Total Sales]

Prior Period = 
CALCULATE([Total Sales], SAMEPERIODLASTYEAR(DimDate[Date]))

Period Change = [Current Period] - [Prior Period]

Period Change % = DIVIDE([Period Change], [Prior Period])

Period Status = 
IF([Period Change] > 0, "▲ Improving", 
   IF([Period Change] < 0, "▼ Declining", "— Flat"))
```

---

## Part 8: Advanced Patterns

### Pareto Analysis (80/20)

```dax
// Cumulative % of Sales
Cumulative % = 
VAR CurrentValue = [Total Sales]
VAR AllProducts = 
    ADDCOLUMNS(
        ALLSELECTED(DimBook),
        "ProductSales", [Total Sales]
    )
VAR CumulativeTotal = 
    SUMX(
        FILTER(AllProducts, [ProductSales] >= CurrentValue),
        [ProductSales]
    )
VAR GrandTotal = SUMX(AllProducts, [ProductSales])
RETURN
DIVIDE(CumulativeTotal, GrandTotal)

// Pareto Classification
Pareto Class = 
IF([Cumulative %] <= 0.8, "A - Top 80%",
   IF([Cumulative %] <= 0.95, "B - Next 15%", "C - Bottom 5%"))
```

### ABC Analysis

```dax
// ABC Classification based on sales contribution
ABC Class = 
VAR CurrentSales = [Total Sales]
VAR Rank = [Sales Rank]
VAR TotalProducts = COUNTROWS(ALLSELECTED(DimBook))
VAR Percentile = DIVIDE(Rank, TotalProducts)
RETURN
SWITCH(
    TRUE(),
    Percentile <= 0.2, "A",
    Percentile <= 0.5, "B",
    "C"
)
```

### Virtual Relationships

```dax
// Connect tables without physical relationship
Sales From Other Table = 
CALCULATE(
    SUM(OtherTable[Amount]),
    TREATAS(VALUES(DimBook[Category]), OtherTable[Category])
)
```

### Dynamic Measures

```dax
// Measure that changes based on slicer selection
Dynamic Measure = 
VAR Selected = SELECTEDVALUE(MeasureSelector[Measure])
RETURN
SWITCH(
    Selected,
    "Sales", [Total Sales],
    "Quantity", [Total Quantity],
    "Profit", [Total Profit],
    "Orders", [Transaction Count],
    [Total Sales]  -- Default
)
```

---

## Part 9: Performance Optimization

### DAX Performance Tips

| Tip | Description |
|-----|-------------|
| Use variables | Avoid recalculating the same expression |
| Avoid iterators when possible | SUM is faster than SUMX |
| Filter on dimension tables | More efficient than filtering facts |
| Use DISTINCTCOUNT carefully | Expensive operation |
| Avoid complex FILTER expressions | Push to Power Query if possible |
| Test with DAX Studio | Profile actual performance |

### Exercise 9.1: Optimize a Measure

```dax
// Before: Inefficient
Slow Measure = 
CALCULATE(
    SUMX(
        FILTER(FactSales, FactSales[SalesAmount] > 100),
        FactSales[Quantity] * RELATED(DimBook[Price])
    )
)

// After: More efficient
Fast Measure = 
SUMX(
    FILTER(
        SELECTCOLUMNS(
            FactSales,
            "Qty", FactSales[Quantity],
            "Price", RELATED(DimBook[Price]),
            "Amount", FactSales[SalesAmount]
        ),
        [Amount] > 100
    ),
    [Qty] * [Price]
)
```

### Using CALCULATE vs FILTER

```dax
// Simple filter - use CALCULATE
Sales 2024 = CALCULATE([Total Sales], DimDate[Year] = 2024)

// Complex filter - use FILTER
High Value Customer Sales = 
CALCULATE(
    [Total Sales],
    FILTER(
        DimCustomer,
        CALCULATE([Total Sales]) > 10000
    )
)
```

---

## Part 10: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ Iterator functions (SUMX, AVERAGEX, COUNTX, RANKX)
2. ✅ Table functions (SUMMARIZE, ADDCOLUMNS, TOPN)
3. ✅ Variables in DAX (VAR...RETURN)
4. ✅ Context transition
5. ✅ Advanced CALCULATE patterns
6. ✅ Advanced time intelligence
7. ✅ Analysis patterns (Pareto, ABC)
8. ✅ Performance optimization

### Quiz

**Question 1:** What does an iterator function do?
- a) Iterates through pages in a report
- b) Evaluates an expression row by row over a table
- c) Creates an infinite loop
- d) Filters data repeatedly

**Question 2:** What is the purpose of SUMMARIZE?
- a) To create a summary report
- b) To aggregate data and create a grouped table
- c) To summarize documentation
- d) To compress data

**Question 3:** What does context transition do?
- a) Changes the report page
- b) Converts row context to filter context
- c) Transitions between visuals
- d) Changes data source

**Question 4:** In VAR...RETURN, when is the variable expression evaluated?
- a) Every time it's referenced
- b) Once, when defined
- c) At the end of RETURN
- d) Never, it's just a placeholder

**Question 5:** Which modifier keeps existing filters instead of replacing them?
- a) ALLEXCEPT
- b) KEEPFILTERS
- c) PRESERVEFILTERS
- d) HOLDFILTERS

### Answers
1. b) Evaluates an expression row by row over a table
2. b) To aggregate data and create a grouped table
3. b) Converts row context to filter context
4. b) Once, when defined
5. b) KEEPFILTERS

---

## Next Lab
**Lab 73: Visualizations and Reports** - Master Power BI visualization best practices and interactive report design.
