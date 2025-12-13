# Lab 68: Power BI Desktop Fundamentals

## Objective
Learn the fundamentals of Power BI Desktop including interface navigation, connecting to data sources, understanding import vs DirectQuery modes, and creating your first interactive report.

## Prerequisites
- Power BI Desktop installed (free download from Microsoft)
- SQL Server with BookstoreDB and DataWarehouse databases
- Completed Modules 01-07

## Duration
90 minutes

---

## Part 1: Power BI Interface Overview

### Understanding the Workspace

Power BI Desktop has three main views:

1. **Report View** - Design visualizations and reports
2. **Data View** - Inspect and manage data tables
3. **Model View** - Design relationships between tables

### Key Interface Elements

```
┌─────────────────────────────────────────────────────────────┐
│  File  Home  Insert  Modeling  View  Help                   │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────────────────────────────┐ ┌─────────┐│
│ │Filters  │ │                                 │ │Visual-  ││
│ │Pane     │ │      Canvas Area                │ │izations ││
│ │         │ │                                 │ │Pane     ││
│ │         │ │   (Design your reports here)    │ │         ││
│ │         │ │                                 │ ├─────────┤│
│ │         │ │                                 │ │Fields   ││
│ │         │ │                                 │ │Pane     ││
│ └─────────┘ └─────────────────────────────────┘ └─────────┘│
│ [Report] [Data] [Model]         Page Tabs                   │
└─────────────────────────────────────────────────────────────┘
```

### Exercise 1.1: Explore the Interface

1. Open Power BI Desktop
2. Click through each view (Report, Data, Model)
3. Identify these elements:
   - Ribbon (top menu bar)
   - Fields pane (right side)
   - Visualizations pane (right side)
   - Filters pane (right side or left)
   - Canvas (center)
   - Page tabs (bottom)

---

## Part 2: Connecting to Data Sources

### Data Source Types

Power BI can connect to many data sources:

| Category | Examples |
|----------|----------|
| Files | Excel, CSV, XML, JSON, PDF |
| Databases | SQL Server, Oracle, MySQL, PostgreSQL |
| Azure | Azure SQL, Synapse, Data Lake |
| Online Services | SharePoint, Dynamics 365, Salesforce |
| Other | OData, ODBC, Web, Python scripts |

### Connection Methods

1. **Import** - Data is loaded into Power BI's in-memory engine
2. **DirectQuery** - Queries are sent to source in real-time
3. **Dual** - Can operate in either mode (composite models)
4. **Live Connection** - Connects to existing Analysis Services model

### Exercise 2.1: Connect to SQL Server

**Step-by-step instructions:**

1. In Power BI Desktop, click **Home** → **Get Data** → **SQL Server**

2. Enter connection details:
   - Server: `localhost` (or your server name)
   - Database: `BookstoreDB`
   - Data Connectivity mode: **Import**

3. Click **OK**

4. If prompted for credentials:
   - Select **Windows** for Windows Authentication
   - Or **Database** for SQL Server Authentication

5. In the Navigator window, select these tables:
   - `Books`
   - `Customers`
   - `Orders`
   - `OrderDetails`
   - `Authors`
   - `Categories`

6. Click **Load** (or **Transform Data** to modify first)

### Exercise 2.2: Connect to Data Warehouse

Repeat the process for the DataWarehouse database:

1. **Home** → **Get Data** → **SQL Server**
2. Server: `localhost`
3. Database: `DataWarehouse`
4. Select tables:
   - `DimDate`
   - `DimCustomer`
   - `DimBook`
   - `FactSales`
5. Click **Load**

---

## Part 3: Import vs DirectQuery

### Import Mode

**Advantages:**
- Fast query performance (data in memory)
- Full DAX functionality
- Works offline after refresh
- Supports all transformations

**Disadvantages:**
- Data can become stale between refreshes
- File size increases with data
- Memory limitations (1GB for Pro, 400GB for Premium)
- Refresh needed to see new data

**Best for:**
- Smaller datasets (< 1 million rows typically)
- Complex calculations
- Reports that don't need real-time data
- Self-service BI scenarios

### DirectQuery Mode

**Advantages:**
- Always current data
- No data storage needed
- Handles large datasets
- Meets data governance requirements

**Disadvantages:**
- Slower query performance
- Limited transformations
- Some DAX limitations
- Requires stable connection

**Best for:**
- Real-time dashboards
- Very large datasets
- Strict data governance requirements
- Near real-time reporting needs

### Comparison Table

| Feature | Import | DirectQuery |
|---------|--------|-------------|
| Data Freshness | Scheduled refresh | Real-time |
| Performance | Fast | Depends on source |
| Offline Access | Yes | No |
| Max Data Size | Memory limited | Unlimited |
| DAX Support | Full | Limited |
| Transformations | Full | Limited |

### Exercise 3.1: Understand Data Mode Impact

1. Create a new Power BI file
2. Connect to BookstoreDB using **Import** mode
3. Note the time to load
4. Create another connection using **DirectQuery** mode
5. Compare:
   - Load time
   - File size
   - Available transformation options

---

## Part 4: Power Query Editor Basics

### Opening Power Query

Access Power Query Editor via:
- **Home** → **Transform data**
- Right-click a table → **Edit query**

### Power Query Interface

```
┌─────────────────────────────────────────────────────────────┐
│  File  Home  Transform  Add Column  View                    │
├─────────────────────────────────────────────────────────────┤
│ ┌───────────┐ ┌────────────────────────┐ ┌────────────────┐│
│ │ Queries   │ │                        │ │ Query          ││
│ │           │ │  Data Preview          │ │ Settings       ││
│ │ - Books   │ │                        │ │                ││
│ │ - Orders  │ │  (Shows sample data)   │ │ Properties     ││
│ │ - etc.    │ │                        │ │ Applied Steps  ││
│ │           │ │                        │ │                ││
│ └───────────┘ └────────────────────────┘ └────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Common Transformations

| Transformation | Description | How to Apply |
|---------------|-------------|--------------|
| Remove columns | Delete unwanted columns | Right-click column → Remove |
| Rename columns | Give meaningful names | Double-click header |
| Change type | Set data types | Click type icon in header |
| Filter rows | Keep/remove rows | Click filter arrow |
| Replace values | Change specific values | Right-click → Replace Values |
| Split column | Divide into multiple | Right-click → Split Column |
| Merge columns | Combine columns | Select columns → Merge |

### Exercise 4.1: Basic Transformations

1. Open Power Query Editor
2. Select the **Books** query
3. Perform these transformations:
   
   a. **Rename columns:**
   - `BookID` → `Book ID`
   - `ISBN` → `ISBN Number`
   
   b. **Change data types:**
   - Ensure `Price` is Decimal Number
   - Ensure `PublicationDate` is Date
   
   c. **Remove unnecessary columns:**
   - Remove any audit columns if present
   
4. Click **Close & Apply**

### Exercise 4.2: Create a Custom Column

1. In Power Query, select the **Books** table
2. Go to **Add Column** → **Custom Column**
3. Create a Price Category column:

```powerquery
// Custom Column Formula
if [Price] < 20 then "Budget"
else if [Price] < 50 then "Standard"
else if [Price] < 100 then "Premium"
else "Luxury"
```

4. Name it `PriceCategory`
5. Click OK

---

## Part 5: Building Your First Report

### Creating Visualizations

**Basic Steps:**
1. Click empty space on canvas
2. Select a visualization type
3. Drag fields to the visualization

### Visualization Types for Different Data

| Data Type | Recommended Visuals |
|-----------|-------------------|
| Trends over time | Line chart, Area chart |
| Comparisons | Bar chart, Column chart |
| Part-to-whole | Pie chart, Donut, Treemap |
| Single values | Card, KPI, Gauge |
| Relationships | Scatter plot |
| Geographic | Map, Filled map |
| Detailed data | Table, Matrix |

### Exercise 5.1: Create a Sales Overview Report

**Step 1: Add a Card for Total Sales**

1. Click on the canvas
2. Select **Card** visualization
3. Drag `FactSales[SalesAmount]` to the Values field
4. The card shows total sales

**Step 2: Add a Column Chart for Sales by Category**

1. Click empty space
2. Select **Clustered Column Chart**
3. Configure:
   - X-axis: `DimBook[Category]`
   - Y-axis: `FactSales[SalesAmount]`

**Step 3: Add a Line Chart for Sales Trend**

1. Add a **Line Chart**
2. Configure:
   - X-axis: `DimDate[Date]` (or `DimDate[MonthYear]`)
   - Y-axis: `FactSales[SalesAmount]`

**Step 4: Add a Table for Details**

1. Add a **Table** visualization
2. Add columns:
   - `DimBook[Title]`
   - `FactSales[Quantity]`
   - `FactSales[SalesAmount]`

### Exercise 5.2: Format Your Report

**Apply these formatting options:**

1. **Card formatting:**
   - Click the card
   - In Format pane (paint roller icon):
     - Category label: Off
     - Data label: Font size 24
     - Background: Light blue

2. **Chart formatting:**
   - Add a title: "Sales by Category"
   - Enable data labels
   - Adjust colors

3. **Page formatting:**
   - View → Page view → Fit to page
   - Format → Canvas background → Light gray

---

## Part 6: Filters and Interactions

### Filter Types

1. **Visual-level filters** - Apply to one visual only
2. **Page-level filters** - Apply to all visuals on the page
3. **Report-level filters** - Apply to all pages

### Adding Filters

1. Select a visual
2. In the Filters pane, drag fields to:
   - Filters on this visual
   - Filters on this page
   - Filters on all pages

### Exercise 6.1: Add a Date Filter

1. Expand the Filters pane
2. Drag `DimDate[Year]` to **Filters on this page**
3. Select filter type: **Basic filtering**
4. Check specific years (e.g., 2023, 2024)

### Exercise 6.2: Add a Slicer

Slicers are visual filters that users can interact with:

1. Click empty space on canvas
2. Select **Slicer** visualization
3. Add `DimDate[Year]` to the slicer
4. Format as dropdown or list

### Understanding Interactions

By default, visuals interact with each other:
- Clicking a bar in a chart filters other visuals
- This is called **cross-filtering**

**To modify interactions:**
1. Select a visual
2. Go to **Format** → **Edit interactions**
3. Choose interaction type for each visual:
   - Filter (default)
   - Highlight
   - None

---

## Part 7: Saving and Exporting

### Saving Your Work

1. **Save as .pbix file:**
   - File → Save As
   - Choose location
   - Name: `BookstoreSalesReport.pbix`

### Export Options

| Export Type | Description | How To |
|-------------|-------------|--------|
| PDF | Static report snapshot | File → Export → PDF |
| PowerPoint | Presentation format | File → Export → PowerPoint |
| Data | Export underlying data | Visual → More options → Export data |
| Template | Reusable template | File → Export → Power BI template |

### Exercise 7.1: Save Your Report

1. Save the report as `Lab68_BookstoreReport.pbix`
2. Export a page as PDF
3. Export the sales table data as CSV

---

## Part 8: Practice Exercises

### Exercise 8.1: Create a Customer Report

Create a new page with these visuals:

1. **Card** - Total number of customers
2. **Bar chart** - Customers by region/state
3. **Table** - Top 10 customers by order value
4. **Slicer** - Filter by customer segment

### Exercise 8.2: Create a Product Performance Report

Create another page with:

1. **Card** - Total products sold
2. **Treemap** - Sales by category
3. **Line chart** - Monthly sales trend
4. **Matrix** - Sales by category and month

### Exercise 8.3: Add Interactivity

1. Add slicers for:
   - Year
   - Category
   - Customer segment
2. Test cross-filtering between visuals
3. Add a "Clear all slicers" button

---

## Part 9: Best Practices

### Report Design Best Practices

1. **Layout:**
   - Use consistent alignment
   - Group related visuals
   - Leave white space
   - Important metrics at top-left

2. **Colors:**
   - Use a consistent color palette
   - Limit to 5-7 colors
   - Consider color blindness
   - Use color meaningfully

3. **Typography:**
   - Use consistent fonts
   - Hierarchy: Title > Subtitle > Body
   - Limit text on visuals

4. **Performance:**
   - Limit visuals per page (8-10 max)
   - Use aggregations
   - Remove unused columns

### Common Mistakes to Avoid

| Mistake | Why It's Bad | Solution |
|---------|--------------|----------|
| Too many visuals | Cluttered, slow | Focus on key metrics |
| 3D charts | Hard to read | Use 2D alternatives |
| Pie charts with many slices | Unreadable | Use bar chart instead |
| No titles | Confusing | Add descriptive titles |
| Rainbow colors | Distracting | Use consistent palette |
| Truncated axes | Misleading | Start at zero when appropriate |

---

## Part 10: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ Power BI interface and views
2. ✅ Connecting to SQL Server data sources
3. ✅ Import vs DirectQuery modes
4. ✅ Basic Power Query transformations
5. ✅ Creating visualizations
6. ✅ Adding filters and slicers
7. ✅ Report formatting and design

### Quiz

**Question 1:** Which view do you use to design relationships between tables?
- a) Report View
- b) Data View
- c) Model View
- d) Relationship View

**Question 2:** What is the main advantage of DirectQuery over Import mode?
- a) Faster performance
- b) Better DAX support
- c) Always current data
- d) Offline access

**Question 3:** Which pane do you use to filter data for a specific visual only?
- a) Fields pane
- b) Visualizations pane
- c) Filters pane (visual level)
- d) Format pane

**Question 4:** What file extension does Power BI Desktop use?
- a) .pbi
- b) .pbix
- c) .pbid
- d) .powerbi

**Question 5:** What is a Slicer in Power BI?
- a) A way to slice data into smaller files
- b) A visual that acts as a filter
- c) A transformation tool
- d) A data source type

### Answers
1. c) Model View
2. c) Always current data
3. c) Filters pane (visual level)
4. b) .pbix
5. b) A visual that acts as a filter

---

## Next Lab
**Lab 69: Data Modeling in Power BI** - Learn to build proper star schema models, define relationships, and optimize your data model.
