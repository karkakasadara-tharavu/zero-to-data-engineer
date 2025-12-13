# Lab 75: Power BI and Data Engineering Integration

## Objective
Learn to integrate Power BI with your data engineering infrastructure including data warehouse connections, incremental refresh, composite models, aggregations, and performance optimization.

## Prerequisites
- Completion of Labs 68-74
- SQL Server with DataWarehouse database
- Understanding of ETL processes
- Power BI Pro/Premium (for some features)

## Duration
120 minutes

---

## Part 1: Connecting to Data Warehouse

### Data Warehouse Connection Best Practices

| Best Practice | Description |
|---------------|-------------|
| Use views | Create reporting views to simplify model |
| Star schema | Ensure proper dimensional model |
| Pre-aggregate | Create summary tables for large data |
| Limit columns | Import only needed columns |
| Optimize types | Use efficient data types |

### Exercise 1.1: Create Reporting Views

Create dedicated views for Power BI in SQL Server:

```sql
-- Create schema for reporting views
CREATE SCHEMA Reporting;
GO

-- Sales fact view (simplified for BI)
CREATE VIEW Reporting.vFactSales AS
SELECT 
    fs.SalesKey,
    fs.DateKey,
    fs.CustomerKey,
    fs.BookKey,
    fs.Quantity,
    fs.UnitPrice,
    fs.SalesAmount,
    fs.Cost,
    fs.Profit
FROM dbo.FactSales fs
WHERE fs.IsDeleted = 0;  -- Exclude soft-deleted rows
GO

-- Customer dimension view
CREATE VIEW Reporting.vDimCustomer AS
SELECT 
    CustomerKey,
    CustomerName,
    Email,
    City,
    State,
    Region,
    CustomerSegment,
    JoinDate
FROM dbo.DimCustomer
WHERE IsCurrent = 1;  -- Current SCD Type 2 records
GO

-- Book dimension view
CREATE VIEW Reporting.vDimBook AS
SELECT 
    BookKey,
    BookID,
    Title,
    Author,
    Category,
    SubCategory,
    Publisher,
    Price,
    Cost
FROM dbo.DimBook
WHERE IsCurrent = 1;
GO

-- Date dimension view
CREATE VIEW Reporting.vDimDate AS
SELECT 
    DateKey,
    [Date],
    [Year],
    [Quarter],
    [Month],
    [MonthName],
    [Week],
    [DayOfWeek],
    [DayName],
    IsWeekend,
    IsHoliday,
    FiscalYear,
    FiscalQuarter
FROM dbo.DimDate;
GO
```

### Exercise 1.2: Connect to Views

1. Power BI Desktop → Get Data → SQL Server
2. Server: `localhost`
3. Database: `DataWarehouse`
4. Select views from Reporting schema:
   - `Reporting.vFactSales`
   - `Reporting.vDimCustomer`
   - `Reporting.vDimBook`
   - `Reporting.vDimDate`
5. Load data

---

## Part 2: DirectQuery vs Import Strategy

### Choosing the Right Mode

| Scenario | Recommended Mode |
|----------|------------------|
| Dataset < 1GB | Import |
| Near real-time needs | DirectQuery |
| Very large dataset | DirectQuery + Aggregations |
| Complex DAX calculations | Import |
| Limited source performance | Import |
| Strict data governance | DirectQuery |
| Mixed requirements | Composite model |

### Exercise 2.1: Compare Modes

**Test Import Performance:**
1. Connect to FactSales with Import mode
2. Note load time
3. Create a report
4. Note visual response time

**Test DirectQuery Performance:**
1. Create new connection with DirectQuery
2. Create same report
3. Compare response times

### DirectQuery Optimization

For DirectQuery to perform well:

```sql
-- Create indexes for common filter columns
CREATE INDEX IX_FactSales_DateKey ON dbo.FactSales(DateKey);
CREATE INDEX IX_FactSales_CustomerKey ON dbo.FactSales(CustomerKey);
CREATE INDEX IX_FactSales_BookKey ON dbo.FactSales(BookKey);

-- Create indexed views for common aggregations
CREATE VIEW dbo.SalesSummaryByDate
WITH SCHEMABINDING
AS
SELECT 
    DateKey,
    SUM(SalesAmount) AS TotalSales,
    SUM(Quantity) AS TotalQuantity,
    COUNT_BIG(*) AS TransactionCount
FROM dbo.FactSales
GROUP BY DateKey;
GO

CREATE UNIQUE CLUSTERED INDEX IX_SalesSummaryByDate
ON dbo.SalesSummaryByDate(DateKey);
```

---

## Part 3: Incremental Refresh

### What is Incremental Refresh?

- Refresh only new/changed data
- Reduces refresh time dramatically
- Available in Premium (full) and Pro (basic)
- Requires RangeStart/RangeEnd parameters

### Exercise 3.1: Configure Incremental Refresh

**Step 1: Create Parameters in Power Query**

1. Open Power Query Editor
2. Manage Parameters → New Parameter
3. Create `RangeStart`:
   - Type: Date/Time
   - Current Value: `1/1/2020 12:00:00 AM`
4. Create `RangeEnd`:
   - Type: Date/Time
   - Current Value: Today's date

**Step 2: Filter Data with Parameters**

1. Select your fact table query
2. Filter the date column:
   - Is after or equal to: `RangeStart`
   - Is before: `RangeEnd`

**Step 3: Configure Incremental Refresh Policy**

1. Go to Model view
2. Right-click the table → Incremental refresh
3. Configure:
   - Archive data starting: 2 years
   - Incrementally refresh starting: 1 month
   - Detect data changes: Check (if column available)

```
Timeline:
[========= Archive (2 years) =========][= Refresh (1 month) =]
   ↓ Full refresh on first load           ↓ Incremental daily
```

### Exercise 3.2: Enable Change Detection

For optimal incremental refresh, use a watermark column:

```sql
-- Add LastModified column for change detection
ALTER TABLE dbo.FactSales
ADD LastModifiedDate DATETIME2 DEFAULT GETDATE();
GO

-- Create trigger to update LastModified
CREATE TRIGGER tr_FactSales_UpdateModified
ON dbo.FactSales
AFTER UPDATE
AS
BEGIN
    UPDATE fs
    SET LastModifiedDate = GETDATE()
    FROM dbo.FactSales fs
    INNER JOIN inserted i ON fs.SalesKey = i.SalesKey;
END;
GO
```

In Power BI, enable "Detect data changes" using this column.

---

## Part 4: Composite Models

### What is a Composite Model?

Mix Import and DirectQuery tables in one model:
- Dimension tables: Import (fast filtering)
- Fact tables: DirectQuery (current data)

### Exercise 4.1: Create Composite Model

**Step 1: Connect dimensions as Import**

1. Get Data → SQL Server
2. Select dimension tables
3. Choose Import mode
4. Load

**Step 2: Connect facts as DirectQuery**

1. Get Data → SQL Server
2. Select fact table
3. Choose DirectQuery mode
4. Load (may prompt about composite model)

**Step 3: Configure Storage Mode**

In Model view:
1. Select each table
2. In Properties, set Storage mode:
   - Dimensions: Import
   - Facts: DirectQuery

### Exercise 4.2: Configure Dual Mode

For tables that need both:

1. Select table
2. Set Storage mode: Dual
3. Table acts as Import when joined with Import
4. Table acts as DirectQuery when joined with DirectQuery

```
┌─────────────────────────────────────────────────────────────┐
│              COMPOSITE MODEL ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────┐        ┌─────────────────┐             │
│  │   DimCustomer   │        │    DimBook      │             │
│  │    (Import)     │        │    (Import)     │             │
│  └────────┬────────┘        └────────┬────────┘             │
│           │                          │                       │
│           └──────────┬───────────────┘                       │
│                      │                                       │
│           ┌──────────▼──────────┐                           │
│           │     FactSales       │                           │
│           │   (DirectQuery)     │◄──── Real-time data       │
│           └─────────────────────┘                           │
│                      │                                       │
│           ┌──────────▼──────────┐                           │
│           │    DimDate (Dual)   │                           │
│           └─────────────────────┘                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 5: Aggregations

### What are Aggregations?

Pre-aggregated tables that Power BI uses automatically for large datasets.

**Benefits:**
- Fast response for summary queries
- DirectQuery for detail queries
- Automatic switching

### Exercise 5.1: Create Aggregation Table

**Step 1: Create aggregation table in SQL Server**

```sql
-- Create aggregation table
CREATE TABLE dbo.FactSales_Agg_Daily AS
SELECT 
    DateKey,
    CustomerKey,
    BookKey,
    SUM(SalesAmount) AS SalesAmount,
    SUM(Quantity) AS Quantity,
    SUM(Cost) AS Cost,
    SUM(Profit) AS Profit,
    COUNT(*) AS TransactionCount
FROM dbo.FactSales
GROUP BY DateKey, CustomerKey, BookKey;
GO

-- Add indexes
CREATE CLUSTERED INDEX IX_FactSales_Agg ON dbo.FactSales_Agg_Daily(DateKey);
```

**Step 2: Import aggregation table**

1. Get Data → Import aggregation table
2. Set storage mode: Import

**Step 3: Configure aggregations**

1. Select aggregation table in Model view
2. Right-click → Manage aggregations
3. Map columns:

| Aggregation Column | Summarization | Detail Table | Detail Column |
|-------------------|---------------|--------------|---------------|
| SalesAmount | Sum | FactSales | SalesAmount |
| Quantity | Sum | FactSales | Quantity |
| Profit | Sum | FactSales | Profit |
| TransactionCount | Count | FactSales | SalesKey |
| DateKey | GroupBy | FactSales | DateKey |
| BookKey | GroupBy | FactSales | BookKey |

4. Hide aggregation table from Report view

### Exercise 5.2: Test Aggregation Hits

1. Create visuals at different grain levels
2. Open Performance Analyzer (View → Performance analyzer)
3. Start recording
4. Refresh visuals
5. Check which queries hit aggregation vs detail table

---

## Part 6: Performance Analyzer

### Using Performance Analyzer

1. View → Performance analyzer
2. Click "Start recording"
3. Refresh visuals or interact with report
4. Review metrics:
   - DAX query time
   - Direct query time
   - Visual display time

### Exercise 6.1: Analyze Report Performance

1. Open Performance analyzer
2. Refresh all visuals
3. Identify slowest visuals
4. Analyze DAX queries
5. Copy query to DAX Studio for detailed analysis

### Performance Optimization Checklist

| Issue | Solution |
|-------|----------|
| Slow DAX | Optimize measures, use variables |
| Slow DirectQuery | Add indexes, create aggregations |
| Too many visuals | Reduce visuals per page |
| Large model | Remove unused columns |
| Complex relationships | Simplify model |
| Many bi-directional | Use single direction |

---

## Part 7: Dataflows

### What are Dataflows?

Cloud-based ETL in Power BI Service:
- Power Query in the cloud
- Reusable data prep
- Computed entities
- Linked entities

### Exercise 7.1: Create a Dataflow

1. In Power BI Service, go to workspace
2. New → Dataflow
3. Choose "Define new tables"
4. Add data source (SQL Server)
5. Transform data in Power Query
6. Save dataflow

### Exercise 7.2: Use Dataflow in Desktop

1. Power BI Desktop → Get Data
2. Power BI → Power BI dataflows
3. Select your dataflow tables
4. Load into model

### Benefits for Data Engineers

- Centralized data prep
- Consistency across reports
- Reduced desktop processing
- AI insights integration
- CDM (Common Data Model) support

---

## Part 8: Deployment Pipelines

### What are Deployment Pipelines?

Manage content lifecycle:
- Development → Test → Production
- Automated deployment
- Comparison between stages

### Exercise 8.1: Create Deployment Pipeline

**Requires Premium capacity**

1. In Power BI Service, click Deployment pipelines
2. Create new pipeline
3. Name: "Sales Analytics Pipeline"
4. Assign workspaces to stages:
   - Development: Dev-Sales
   - Test: Test-Sales
   - Production: Prod-Sales

5. Deploy content between stages

### Exercise 8.2: Implement CI/CD

For advanced scenarios:
- Use Power BI REST API
- Azure DevOps integration
- Automated testing
- Source control (PBIX)

---

## Part 9: Monitoring and Administration

### Dataset Metrics

Monitor dataset health:
1. Go to workspace → Dataset settings
2. View refresh history
3. Check storage used
4. Review query performance

### Exercise 9.1: Set Up Alerts

1. On a dashboard tile, click **...** → Manage alerts
2. Set condition:
   - Alert title: "Sales Target Alert"
   - Condition: Sales < $10,000
   - Notification: Daily
3. Save

### Premium Capacity Metrics

For Premium administrators:
- Power BI Premium Capacity Metrics app
- Resource usage monitoring
- Query performance tracking
- Refresh scheduling optimization

---

## Part 10: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ Data warehouse connection best practices
2. ✅ DirectQuery vs Import strategies
3. ✅ Incremental refresh configuration
4. ✅ Composite models
5. ✅ Aggregations for large datasets
6. ✅ Performance analysis and optimization
7. ✅ Dataflows for cloud ETL
8. ✅ Deployment pipelines

### Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  COMPLETE BI ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  Source     │    │   ETL/ELT   │    │    Data     │     │
│  │  Systems    │───►│   (SSIS)    │───►│  Warehouse  │     │
│  └─────────────┘    └─────────────┘    └──────┬──────┘     │
│                                               │              │
│                          ┌────────────────────┤              │
│                          │                    │              │
│                    ┌─────▼─────┐        ┌─────▼─────┐       │
│                    │ Dataflows │        │   Direct  │       │
│                    │  (Cloud)  │        │   Query   │       │
│                    └─────┬─────┘        └─────┬─────┘       │
│                          │                    │              │
│                    ┌─────▼────────────────────▼─────┐       │
│                    │      Power BI Dataset          │       │
│                    │  (Composite Model + Aggs)      │       │
│                    └────────────────┬───────────────┘       │
│                                     │                        │
│              ┌──────────────────────┼──────────────────┐    │
│              │                      │                  │    │
│        ┌─────▼─────┐         ┌──────▼──────┐   ┌──────▼───┐│
│        │  Reports  │         │ Dashboards  │   │   Apps   ││
│        └───────────┘         └─────────────┘   └──────────┘│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Quiz

**Question 1:** What is incremental refresh?
- a) Refreshing visuals incrementally
- b) Refreshing only new/changed data
- c) Gradually loading a report
- d) Updating DAX measures

**Question 2:** What is a composite model?
- a) A model with complex relationships
- b) A model mixing Import and DirectQuery modes
- c) A model with many tables
- d) A calculated model

**Question 3:** What are aggregations used for?
- a) Summarizing data in visuals
- b) Pre-aggregated tables for faster queries on large data
- c) Aggregating multiple reports
- d) Combining data sources

**Question 4:** Which tool is used to analyze Power BI performance?
- a) DAX Analyzer
- b) Performance Monitor
- c) Performance Analyzer
- d) Query Inspector

**Question 5:** What are Power BI Dataflows?
- a) Data pipelines in Azure
- b) Cloud-based Power Query ETL
- c) Visual data flows
- d) Report navigation

### Answers
1. b) Refreshing only new/changed data
2. b) A model mixing Import and DirectQuery modes
3. b) Pre-aggregated tables for faster queries on large data
4. c) Performance Analyzer
5. b) Cloud-based Power Query ETL

---

## Module 08 Complete!

Congratulations! You have completed Module 08: Power BI for Data Engineers.

### What You've Learned:
- Power BI Desktop fundamentals
- Data modeling and relationships
- Power Query transformations
- DAX basics and advanced concepts
- Visualization best practices
- Dashboard creation and deployment
- Enterprise integration with data warehouses

### Next Steps:
- **Module 09: SQL Capstone Project** - Put everything together in a comprehensive project
