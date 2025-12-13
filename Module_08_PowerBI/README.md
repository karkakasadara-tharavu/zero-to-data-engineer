![Module 08 Header](../assets/images/module_08_header.svg)

# Module 08: Power BI Reporting

**Duration**: 2 weeks (40-60 hours) | **Difficulty**: ⭐⭐⭐⭐ Advanced

## 📖 Overview
Master Power BI for data visualization: data modeling, DAX calculations, interactive dashboards, and deployment to Power BI Service.

---

## 📚 Module Structure

| Section | Topic | Labs | Time |
|---------|-------|------|------|
| 01 | Power BI Fundamentals & Setup | 1 | 4h |
| 02 | Data Modeling (Star Schema) | 3 | 7h |
| 03 | Power Query (M Language) | 3 | 6h |
| 04 | DAX Basics | 3 | 7h |
| 05 | Advanced DAX & Time Intelligence | 3 | 8h |
| 06 | Visualizations & Report Design | 2 | 6h |
| 07 | Deployment & Sharing | 1 | 4h |
| **Capstone** | Executive Sales Dashboard | 1 | 10h |

**Total**: 17 labs, 2 quizzes, 52 hours

---

## 🛠️ Prerequisites

**Install Power BI Desktop**:
- Download from Microsoft Store (free)
- Power BI Service (cloud) - sign up at powerbi.microsoft.com

---

## 🎯 Key Concepts

### Data Modeling (Star Schema)

**Fact Table**: Measures/metrics (sales, quantities)  
**Dimension Tables**: Descriptive attributes (customers, products, dates)

```
       DimCustomer
             |
             | (1:M)
             ↓
        FactSales ← (M:1) ← DimProduct
             ↓
             | (M:1)
             ↓
         DimDate
```

**Relationships**:
- One-to-Many (dimension to fact)
- Cardinality: 1:* or *:1
- Cross-filter direction: Single or Both

---

### Power Query (ETL in Power BI)

**M Language**:
```m
let
    Source = Sql.Database("localhost", "AdventureWorks2022"),
    SalesTable = Source{[Schema="Sales",Item="SalesOrderHeader"]}[Data],
    FilteredRows = Table.SelectRows(SalesTable, each [OrderDate] >= #date(2013,1,1)),
    AddedColumn = Table.AddColumn(FilteredRows, "Year", each Date.Year([OrderDate])),
    ChangedType = Table.TransformColumnTypes(AddedColumn, {{"Year", Int64.Type}})
in
    ChangedType
```

**Common Transformations**:
- Remove Columns
- Filter Rows
- Merge Queries (JOIN)
- Append Queries (UNION)
- Group By (Aggregate)
- Pivot/Unpivot

---

### DAX Basics

**Calculated Column** (row-level, stored):
```dax
FullName = Customer[FirstName] & " " & Customer[LastName]
```

**Measure** (aggregation, not stored):
```dax
Total Sales = SUM(FactSales[SalesAmount])

Average Sale = AVERAGE(FactSales[SalesAmount])

Order Count = COUNTROWS(FactSales)
```

**Key Difference**:
- Columns: Evaluated during refresh, use row context
- Measures: Evaluated on demand, use filter context

---

### Advanced DAX

**CALCULATE** (modify filter context):
```dax
Sales Last Year = 
CALCULATE(
    [Total Sales],
    DATEADD(DimDate[Date], -1, YEAR)
)

Sales in USA = 
CALCULATE(
    [Total Sales],
    DimCustomer[Country] = "USA"
)
```

**Time Intelligence**:
```dax
YTD Sales = TOTALYTD([Total Sales], DimDate[Date])

MTD Sales = TOTALMTD([Total Sales], DimDate[Date])

Sales Growth % = 
DIVIDE(
    [Total Sales] - [Sales Last Year],
    [Sales Last Year],
    0
)
```

**Filter Functions**:
```dax
Top 10 Products = 
CALCULATE(
    [Total Sales],
    TOPN(10, ALL(DimProduct), [Total Sales], DESC)
)

Active Customers = 
CALCULATE(
    DISTINCTCOUNT(FactSales[CustomerID]),
    FactSales[OrderDate] >= TODAY() - 365
)
```

---

### Visualizations

**Chart Types**:
- Bar/Column: Comparisons
- Line: Trends over time
- Pie/Donut: Composition
- Scatter: Correlation
- Map: Geographic
- Card: Single metric (KPI)
- Table/Matrix: Detailed data

**Best Practices**:
- Limit colors (3-5)
- Clear titles and labels
- Sort by value, not alphabetically
- Use drill-down for details
- Slicers for interactivity

---

### Row-Level Security (RLS)

```dax
-- Role: "Sales Person"
-- Filter: Show only their region

[Region] = USERPRINCIPALNAME()

-- In Power BI Service, assign users to roles
```

---

## 📝 Labs

**Labs 86-88**: Data modeling (relationships, star schema)  
**Labs 89-91**: Power Query transformations  
**Labs 92-94**: DAX measures (basic aggregations)  
**Labs 95-97**: Advanced DAX (time intelligence, CALCULATE)  
**Labs 98-99**: Dashboard design and visualizations  
**Lab 100**: Deploy to Power BI Service with RLS  
**Lab 101**: Capstone - Executive sales dashboard (10+ visuals, 15+ measures, drill-through)

---

## 🎓 Assessment
- Labs: 40%
- Quiz 13 (Week 1): 15%
- Quiz 14 (Week 2): 15%
- Capstone: 30%

---

## 🔗 Navigation

| Direction | Link |
|-----------|------|
| ⬅️ Previous | [Module 07: Advanced ETL](../Module_07_Advanced_ETL/) |
| ➡️ Next | [Module 09: SQL Capstone](../Module_09_SQL_Capstone/) |
| 🏠 Home | [Main Curriculum](../README.md) |
| 📚 Resources | [Study Materials](../Resources/) |
