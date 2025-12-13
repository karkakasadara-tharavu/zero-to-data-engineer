# Power BI Fundamentals - Complete Guide

## 📚 What You'll Learn
- Power BI Desktop basics
- Connecting to data sources
- Creating visualizations
- DAX fundamentals
- Interview preparation

**Duration**: 3 hours  
**Difficulty**: ⭐⭐ Beginner

---

## 🎯 What is Power BI?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    POWER BI ECOSYSTEM                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    POWER BI DESKTOP                              │   │
│   │            Free Windows application                              │   │
│   │            Create reports and dashboards                         │   │
│   └──────────────────────────┬──────────────────────────────────────┘   │
│                              │                                           │
│                              ▼ Publish                                   │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    POWER BI SERVICE                              │   │
│   │            Cloud-based platform (app.powerbi.com)               │   │
│   │            Share, collaborate, schedule refresh                  │   │
│   └──────────────────────────┬──────────────────────────────────────┘   │
│                              │                                           │
│              ┌───────────────┼───────────────┐                          │
│              ▼               ▼               ▼                          │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │
│   │  Power BI    │  │   Embedded   │  │  Power BI    │                 │
│   │   Mobile     │  │    Apps      │  │   Gateway    │                 │
│   │  iOS/Android │  │  Custom apps │  │ On-prem data │                 │
│   └──────────────┘  └──────────────┘  └──────────────┘                 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Power BI Desktop Interface

```
┌─────────────────────────────────────────────────────────────────────────┐
│  File  Home  Insert  Modeling  View  Optimize  Help                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌───────────────────────────────────────────────────────────────────┐ │
│   │                                           │   Visualizations      │ │
│   │                                           │   ┌─────────────────┐ │ │
│   │                                           │   │ 📊 📈 📉 🥧 📋 │ │ │
│   │             CANVAS                        │   │ 🗺️ 📦 🎯 📍 🔢 │ │ │
│   │        (Report View)                      │   └─────────────────┘ │ │
│   │                                           │                       │ │
│   │   ┌─────────┐  ┌─────────┐               │   Fields              │ │
│   │   │ Chart 1 │  │ Chart 2 │               │   ┌─────────────────┐ │ │
│   │   │         │  │         │               │   │ □ Table1        │ │ │
│   │   └─────────┘  └─────────┘               │   │   □ Column1     │ │ │
│   │                                           │   │   □ Column2     │ │ │
│   │   ┌─────────────────────┐                │   │ □ Table2        │ │ │
│   │   │      Table          │                │   │   □ Column1     │ │ │
│   │   │                     │                │   └─────────────────┘ │ │
│   │   └─────────────────────┘                │                       │ │
│   └───────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│   ┌────────┐ ┌────────┐ ┌────────┐                                     │
│   │ Report │ │  Data  │ │ Model  │  ← Views                            │
│   └────────┘ └────────┘ └────────┘                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Three Views

1. **Report View**: Design visualizations and layout
2. **Data View**: View and edit table data
3. **Model View**: Manage table relationships

---

## 📊 Connecting to Data Sources

### Common Data Sources

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       DATA SOURCE CATEGORIES                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   FILES                    DATABASES                ONLINE SERVICES     │
│   ├── Excel               ├── SQL Server           ├── SharePoint       │
│   ├── CSV                 ├── Azure SQL            ├── Dynamics 365     │
│   ├── XML                 ├── Oracle               ├── Salesforce       │
│   ├── JSON                ├── PostgreSQL           ├── Google Analytics │
│   ├── Parquet             ├── MySQL                └── Azure Synapse    │
│   └── Text                └── Snowflake                                 │
│                                                                          │
│   AZURE                    OTHER                                        │
│   ├── Azure Blob          ├── Web API                                   │
│   ├── Azure Data Lake     ├── OData                                     │
│   ├── Azure Synapse       ├── ODBC                                      │
│   └── Dataverse           ├── R Script                                  │
│                           └── Python Script                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Connecting to SQL Server

```
Steps:
1. Home → Get Data → SQL Server
2. Enter Server name: localhost
3. Enter Database (optional): AdventureWorks
4. Choose: Import or DirectQuery
5. Select tables to load
6. Click Load or Transform Data
```

### Import vs DirectQuery

| Feature | Import | DirectQuery |
|---------|--------|-------------|
| Data Storage | In Power BI file | Stays in source |
| Refresh | Scheduled/Manual | Real-time |
| File Size | Can be large | Small |
| Performance | Fast after load | Depends on source |
| Use Case | Most scenarios | Real-time dashboards |

---

## 🔄 Power Query (ETL in Power BI)

### Common Transformations

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    POWER QUERY TRANSFORMATIONS                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   COLUMN OPERATIONS                                                      │
│   ├── Remove columns                                                     │
│   ├── Rename columns                                                     │
│   ├── Change data type                                                   │
│   ├── Split column (by delimiter)                                        │
│   ├── Merge columns                                                      │
│   └── Add conditional column                                             │
│                                                                          │
│   ROW OPERATIONS                                                         │
│   ├── Remove rows (top, bottom, errors, duplicates)                     │
│   ├── Filter rows                                                        │
│   └── Keep rows (top N, by condition)                                   │
│                                                                          │
│   TABLE OPERATIONS                                                       │
│   ├── Append queries (stack tables)                                      │
│   ├── Merge queries (join tables)                                        │
│   ├── Group by                                                           │
│   ├── Pivot / Unpivot                                                    │
│   └── Transpose                                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### M Language (Power Query Formula)

```m
// Load table and apply transformations
let
    Source = Sql.Database("localhost", "AdventureWorks"),
    Sales = Source{[Schema="Sales",Item="SalesOrderHeader"]}[Data],
    
    // Remove columns
    RemovedColumns = Table.RemoveColumns(Sales, {"RevisionNumber", "Comment"}),
    
    // Filter rows
    FilteredRows = Table.SelectRows(RemovedColumns, each [OrderDate] >= #date(2023, 1, 1)),
    
    // Change type
    ChangedType = Table.TransformColumnTypes(FilteredRows, {{"TotalDue", Currency.Type}}),
    
    // Add calculated column
    AddedColumn = Table.AddColumn(ChangedType, "Year", each Date.Year([OrderDate]))
in
    AddedColumn
```

---

## 📈 Creating Visualizations

### Chart Types and Use Cases

| Visualization | Best For |
|---------------|----------|
| Bar Chart | Comparing categories |
| Line Chart | Trends over time |
| Pie Chart | Part-to-whole (few categories) |
| Table | Detailed data |
| Card | Single KPI |
| Gauge | Progress toward goal |
| Map | Geographic data |
| Scatter Plot | Correlations |
| Treemap | Hierarchical data |
| Waterfall | Sequential changes |

### Building a Visualization

```
Steps:
1. Select visualization type from panel
2. Drag fields to Values, Axis, Legend
3. Format in Format pane:
   - Title, labels, colors
   - Data labels
   - Conditional formatting
4. Add filters (visual, page, report level)
```

### Formatting Best Practices

- Use consistent colors
- Add clear titles
- Show data labels when helpful
- Remove chart clutter
- Use appropriate number formats
- Align visualizations on grid

---

## 📐 DAX (Data Analysis Expressions)

### DAX Basics

```dax
-- Calculated Column (row context)
Total Price = [Quantity] * [UnitPrice]

-- Measure (aggregates across filter context)
Total Sales = SUM(Sales[Amount])

-- Calculated Table
Top Customers = TOPN(100, Customers, [Total Sales], DESC)
```

### Common DAX Functions

#### Aggregation Functions
```dax
-- Sum, Average, Count
Total Revenue = SUM(Sales[Revenue])
Avg Order Value = AVERAGE(Sales[OrderAmount])
Order Count = COUNT(Sales[OrderID])
Customer Count = DISTINCTCOUNT(Sales[CustomerID])
```

#### Time Intelligence
```dax
-- Year to Date
YTD Sales = TOTALYTD(SUM(Sales[Amount]), 'Date'[Date])

-- Previous Year
PY Sales = CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR('Date'[Date]))

-- Year over Year Growth
YoY Growth = DIVIDE([Total Sales] - [PY Sales], [PY Sales])

-- Running Total
Running Total = 
CALCULATE(
    SUM(Sales[Amount]),
    FILTER(
        ALL('Date'),
        'Date'[Date] <= MAX('Date'[Date])
    )
)
```

#### Filter Functions
```dax
-- CALCULATE - modify filter context
Online Sales = CALCULATE(SUM(Sales[Amount]), Sales[Channel] = "Online")

-- ALL - remove filters
% of Total = DIVIDE(SUM(Sales[Amount]), CALCULATE(SUM(Sales[Amount]), ALL(Sales)))

-- FILTER
Big Orders = CALCULATE(
    COUNTROWS(Orders),
    FILTER(Orders, Orders[Amount] > 1000)
)
```

### Variables in DAX
```dax
Profit Margin = 
VAR TotalRevenue = SUM(Sales[Revenue])
VAR TotalCost = SUM(Sales[Cost])
VAR Profit = TotalRevenue - TotalCost
RETURN
    DIVIDE(Profit, TotalRevenue)
```

---

## 🔗 Data Modeling

### Star Schema

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         STAR SCHEMA                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│                    ┌──────────────────┐                                 │
│                    │    DimCustomer   │                                 │
│                    │  CustomerKey     │                                 │
│                    │  CustomerName    │                                 │
│                    │  City, Country   │                                 │
│                    └────────┬─────────┘                                 │
│                             │                                            │
│   ┌──────────────┐         │         ┌──────────────┐                   │
│   │   DimDate    │         │         │  DimProduct  │                   │
│   │  DateKey     │         │         │  ProductKey  │                   │
│   │  Date        │    ┌────┴────┐    │  ProductName │                   │
│   │  Year        │────│FactSales│────│  Category    │                   │
│   │  Month       │    │ DateKey │    │  Price       │                   │
│   │  Quarter     │    │ CustKey │    └──────────────┘                   │
│   └──────────────┘    │ ProdKey │                                       │
│                       │ Amount  │                                       │
│                       │ Quantity│                                       │
│                       └─────────┘                                       │
│                                                                          │
│   BENEFITS:                                                              │
│   • Simple, intuitive design                                             │
│   • Optimized for Power BI                                               │
│   • Fast query performance                                               │
│   • Natural filter flow (dimension → fact)                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Creating Relationships

```
Steps:
1. Go to Model View
2. Drag key from one table to another
3. Verify cardinality (1:*, *:1, 1:1)
4. Set cross-filter direction (Single or Both)
```

### Relationship Properties

| Property | Description |
|----------|-------------|
| Cardinality | 1:1, 1:*, *:* |
| Cross-filter | Single, Both, None |
| Active | Only one active per path |

---

## 📊 Filters and Slicers

### Filter Levels

1. **Visual Level**: Affects one visual
2. **Page Level**: Affects all visuals on page
3. **Report Level**: Affects all pages

### Slicer Types

- Dropdown
- List
- Date Range
- Between (numeric)
- Relative Date

### Slicer Best Practices

```
✅ Use Sync Slicers for cross-page filtering
✅ Add "Select All" option
✅ Use dropdown for many values
✅ Use buttons for few values
✅ Consider Hierarchy slicers for dates
```

---

## 🎓 Interview Questions

### Q1: What is Power BI and its main components?
**A:** Power BI is a business analytics tool by Microsoft. Components:
- **Power BI Desktop**: Create reports (free)
- **Power BI Service**: Share and collaborate (cloud)
- **Power BI Mobile**: View on mobile devices
- **Power BI Gateway**: Connect to on-premises data

### Q2: What is the difference between Import and DirectQuery?
**A:**
- **Import**: Data loaded into Power BI file, cached for fast queries
- **DirectQuery**: Queries sent to source in real-time, data stays in source

### Q3: What is DAX?
**A:** Data Analysis Expressions - a formula language for creating calculated columns, measures, and calculated tables in Power BI.

### Q4: What is the difference between a calculated column and a measure?
**A:**
- **Calculated Column**: Evaluated row by row, stored in model, static
- **Measure**: Evaluated based on filter context, dynamic, not stored

### Q5: What is a Star Schema?
**A:** Data model with central fact table(s) connected to dimension tables. Optimized for analytics and Power BI.

### Q6: What does CALCULATE do in DAX?
**A:** CALCULATE evaluates an expression in a modified filter context. It can add, modify, or remove filters.

### Q7: What is filter context?
**A:** The set of filters applied to a calculation - from slicers, visual axes, page filters, and relationships.

### Q8: How do you implement Year-over-Year comparison?
**A:** Use time intelligence functions:
```dax
PY Sales = CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR('Date'[Date]))
YoY Growth = DIVIDE([Sales] - [PY Sales], [PY Sales])
```

### Q9: What is Power Query?
**A:** The ETL engine in Power BI for connecting to data, transforming it, and loading it into the model. Uses M language.

### Q10: What are best practices for Power BI performance?
**A:**
- Use Star Schema
- Minimize columns and tables
- Use measures over calculated columns
- Remove unnecessary data in Power Query
- Use aggregations for large datasets
- Optimize DAX formulas

---

## 🔗 Related Topics
- [← Advanced ETL](../Module_07_Advanced_ETL/)
- [SQL Server Integration →](../Module_05_TSQL_Programming/)
- [Data Visualization Best Practices →](#)

---

*Module 08 Complete! Continue to SQL Capstone Project*
