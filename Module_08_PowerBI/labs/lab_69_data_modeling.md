# Lab 69: Data Modeling in Power BI

## Objective
Master data modeling concepts in Power BI including star schema implementation, relationship types, cardinality, cross-filter directions, and model optimization techniques.

## Prerequisites
- Completion of Lab 68
- Power BI Desktop installed
- SQL Server with DataWarehouse database

## Duration
90 minutes

---

## Part 1: Star Schema Fundamentals

### What is a Star Schema?

A star schema is a data modeling approach where:
- **Fact tables** contain measurable data (sales, quantities, amounts)
- **Dimension tables** contain descriptive data (products, customers, dates)
- Fact tables connect to dimension tables through foreign keys

```
                    ┌─────────────┐
                    │  DimDate    │
                    │  (when)     │
                    └──────┬──────┘
                           │
    ┌─────────────┐  ┌─────┴─────┐  ┌─────────────┐
    │ DimCustomer │──│ FactSales │──│  DimBook    │
    │   (who)     │  │  (what)   │  │  (what)     │
    └─────────────┘  └─────┬─────┘  └─────────────┘
                           │
                    ┌──────┴──────┐
                    │ DimStore    │
                    │  (where)    │
                    └─────────────┘
```

### Benefits of Star Schema in Power BI

| Benefit | Explanation |
|---------|-------------|
| Simplicity | Easy to understand and navigate |
| Performance | Optimized for aggregations |
| DAX Efficiency | Filter context works naturally |
| Consistency | Predictable behavior |
| Scalability | Handles large datasets well |

### Exercise 1.1: Review Your Data Model

1. Open your Power BI file from Lab 68
2. Go to **Model View** (left sidebar)
3. Identify:
   - Which tables are fact tables?
   - Which tables are dimension tables?
   - What relationships exist?

---

## Part 2: Understanding Relationships

### Relationship Components

Every relationship has these properties:

1. **Tables involved** - Two tables connected
2. **Columns** - Keys used to join
3. **Cardinality** - One-to-many, many-to-many, etc.
4. **Cross-filter direction** - Single or Both
5. **Active/Inactive** - Only one active path allowed

### Cardinality Types

| Cardinality | Symbol | Description | Example |
|-------------|--------|-------------|---------|
| One-to-Many | 1:* | One row matches many | Customer → Orders |
| Many-to-One | *:1 | Many rows match one | Orders → Customer |
| One-to-One | 1:1 | One row matches one | Employee → EmployeeDetails |
| Many-to-Many | *:* | Many match many | Students ↔ Courses |

### Cross-Filter Direction

| Direction | Description | Use Case |
|-----------|-------------|----------|
| Single | Filters flow one way (dim → fact) | Standard star schema |
| Both | Filters flow both ways | Special scenarios |

**Warning:** Bi-directional filtering can cause:
- Ambiguous paths
- Performance issues
- Unexpected results

### Exercise 2.1: Create Relationships

1. In Model View, ensure these relationships exist:

**FactSales to Dimensions:**
```
FactSales[DateKey]     → DimDate[DateKey]       (Many-to-One)
FactSales[CustomerKey] → DimCustomer[CustomerKey] (Many-to-One)
FactSales[BookKey]     → DimBook[BookKey]       (Many-to-One)
```

2. To create a new relationship:
   - Drag a field from one table to another, OR
   - Home → Manage Relationships → New

3. To edit a relationship:
   - Double-click the relationship line, OR
   - Home → Manage Relationships → Edit

### Exercise 2.2: Configure Relationship Properties

1. Double-click a relationship line
2. In the dialog, verify:
   - Correct columns are selected
   - Cardinality is appropriate
   - Cross-filter direction is Single
   - Make this relationship active is checked

---

## Part 3: Cardinality Deep Dive

### One-to-Many (Most Common)

The "one" side is always the dimension (lookup) table:

```
DimCustomer (1) ───────────── (*) FactSales
    │                                 │
 CustomerKey                     CustomerKey
 CustomerName                    SalesAmount
 Email                           Quantity
```

**Rule:** The "one" side must have unique values in the key column.

### Exercise 3.1: Verify Cardinality

1. Go to Data View
2. Select DimCustomer table
3. Check if CustomerKey is unique:
   - Column tools → Show distribution
   - Should show "Unique" or all distinct values

4. If there are duplicates, you'll see errors in relationships

### Many-to-Many Relationships

Use when neither side has unique values. Power BI handles this but with caveats:

```
Products (*) ───────────── (*) Categories
(A product may belong to multiple categories)
```

**When to use:**
- Bridge tables (many-to-many through a junction)
- Role-playing dimensions
- Complex business rules

**Caution:**
- Can cause unexpected calculations
- Performance impact
- Harder to understand

### Exercise 3.2: Handle Many-to-Many

If you have a scenario where books have multiple categories:

**Option 1: Bridge Table**
```sql
-- Create a bridge table
CREATE TABLE BookCategories (
    BookKey INT,
    CategoryKey INT,
    PRIMARY KEY (BookKey, CategoryKey)
);
```

Then in Power BI:
```
DimBook (1) ← (*) BookCategories (*) → (1) DimCategory
```

**Option 2: Native Many-to-Many**
```
DimBook (*) ──────── (*) DimCategory
(Cardinality: Many-to-Many)
```

---

## Part 4: Role-Playing Dimensions

### What Are Role-Playing Dimensions?

A dimension that serves multiple purposes in the same fact table.

**Example:** Date dimension used for:
- Order Date
- Ship Date
- Delivery Date

```
FactOrders
    │
    ├── OrderDateKey   ──→ DimDate (Active)
    ├── ShipDateKey    ──→ DimDate (Inactive)
    └── DeliveryDateKey ──→ DimDate (Inactive)
```

### The Challenge

Power BI allows only ONE active relationship between two tables.

### Solutions

**Option 1: Multiple Date Tables (Recommended)**

Create separate copies of the date dimension:

```
DimOrderDate   ← FactOrders[OrderDateKey]   (Active)
DimShipDate    ← FactOrders[ShipDateKey]    (Active)
DimDeliveryDate ← FactOrders[DeliveryDateKey] (Active)
```

**Option 2: Use Inactive Relationships with USERELATIONSHIP**

Keep one active, others inactive:

```dax
// Measure for Ship Date calculations
ShippedAmount = 
CALCULATE(
    SUM(FactOrders[Amount]),
    USERELATIONSHIP(FactOrders[ShipDateKey], DimDate[DateKey])
)
```

### Exercise 4.1: Implement Role-Playing Dimensions

**Create duplicate date tables in Power Query:**

1. Open Power Query Editor
2. Right-click DimDate → Reference
3. Rename to "DimOrderDate"
4. Repeat for "DimShipDate"

5. Close & Apply
6. Create appropriate relationships
7. Hide the original DimDate from Report View

---

## Part 5: Model Optimization

### Removing Unnecessary Columns

Every column increases file size and impacts performance.

**Columns to remove:**
- Audit columns (CreatedDate, ModifiedBy)
- Technical keys not used in analysis
- Columns with very long text
- Duplicate information

### Exercise 5.1: Clean Up Your Model

1. Open Power Query Editor
2. For each table, remove columns you won't use
3. Keep only:
   - Keys for relationships
   - Attributes for filtering
   - Measures for calculations

### Hiding Fields

Hide technical fields from report view:

1. In Data or Model view
2. Right-click a column
3. Select "Hide in report view"

**Hide these types of fields:**
- Foreign keys in fact tables
- Surrogate keys in dimensions
- Intermediate calculation columns

### Exercise 5.2: Hide Technical Fields

1. In Model View, hide these fields:
   - FactSales[DateKey]
   - FactSales[CustomerKey]
   - FactSales[BookKey]
   - DimCustomer[CustomerKey] (keep visible if used for display)

### Data Type Optimization

| Data Type | Use For | Memory Impact |
|-----------|---------|--------------|
| Whole Number | Keys, counts | Low |
| Decimal | Prices, percentages | Medium |
| Text | Names, descriptions | High |
| Date | Dates only | Low |
| DateTime | Dates with times | Medium |

### Exercise 5.3: Optimize Data Types

1. Go to Data View
2. Check each column's data type
3. Change to more efficient types:
   - DateTime → Date (if time not needed)
   - Decimal → Whole Number (for quantities)
   - Reduce text column lengths in Power Query

---

## Part 6: Building a Complete Star Schema

### Exercise 6.1: Create a Complete Model

**Step 1: Import Data Warehouse Tables**

Connect to DataWarehouse and import:
- FactSales
- DimDate
- DimCustomer
- DimBook
- DimStore (if exists)

**Step 2: Verify Star Schema Structure**

Your model should look like:

```
                    DimDate
                       │
                       │ DateKey
                       │
    DimCustomer ────FactSales──── DimBook
        │         │         │         │
   CustomerKey    │    BookKey    │
                  │               │
              DimStore ───────────┘
                  StoreKey
```

**Step 3: Configure All Relationships**

Create these relationships:
1. FactSales[DateKey] → DimDate[DateKey]
2. FactSales[CustomerKey] → DimCustomer[CustomerKey]
3. FactSales[BookKey] → DimBook[BookKey]

**Step 4: Verify Relationship Properties**

For each relationship, ensure:
- Cardinality: Many-to-One (fact to dimension)
- Cross-filter: Single
- Active: Yes

### Exercise 6.2: Add a Hierarchy

Create hierarchies for easier navigation:

**Date Hierarchy:**
1. In Model View, select DimDate
2. Right-click Year column
3. Create Hierarchy
4. Rename to "Date Hierarchy"
5. Drag and drop in order:
   - Year
   - Quarter
   - Month
   - Day

**Category Hierarchy (if applicable):**
1. Category → Subcategory → Product

**To use hierarchies:**
- Drag the hierarchy to a visual
- Use drill-down buttons to navigate

---

## Part 7: Composite Models

### What Are Composite Models?

A model that combines:
- Import mode tables AND
- DirectQuery tables

**Use cases:**
- Add high-level aggregations (import) to detailed data (DirectQuery)
- Combine multiple data sources
- Create personal analytics on enterprise data

### Creating a Composite Model

1. Start with an existing model (Import or DirectQuery)
2. Get Data → Connect to another source
3. Choose storage mode for new tables

### Storage Modes

| Mode | Description | Relationships With |
|------|-------------|-------------------|
| Import | Data loaded into memory | Any mode |
| DirectQuery | Queries sent to source | DirectQuery, Dual |
| Dual | Acts as Import or DirectQuery | Any mode |

### Exercise 7.1: Add Aggregation Table

1. Connect to your fact table in DirectQuery mode
2. Create an aggregation table in Import mode:

```sql
-- Create pre-aggregated table in SQL Server
CREATE VIEW SalesSummary AS
SELECT 
    DateKey,
    CategoryKey,
    SUM(SalesAmount) AS TotalSales,
    COUNT(*) AS TransactionCount
FROM FactSales
GROUP BY DateKey, CategoryKey;
```

3. Import SalesSummary
4. Power BI will use aggregations when possible

---

## Part 8: Model Documentation

### Documenting Your Model

Good documentation includes:
- Table descriptions
- Column descriptions
- Relationship explanations
- Business rules

### Adding Descriptions

1. In Model View, select a table or column
2. In Properties pane, add Description
3. These descriptions appear in tooltips

### Exercise 8.1: Document Your Model

Add descriptions to key elements:

**Table Descriptions:**
- FactSales: "Central fact table containing all sales transactions"
- DimDate: "Date dimension with fiscal and calendar attributes"
- DimCustomer: "Customer master data with demographics"
- DimBook: "Book/Product catalog with categories"

**Column Descriptions:**
- SalesAmount: "Total sale price including discounts"
- CustomerKey: "Surrogate key linking to DimCustomer"

---

## Part 9: Common Modeling Mistakes

### Mistakes to Avoid

| Mistake | Problem | Solution |
|---------|---------|----------|
| Bi-directional filters everywhere | Ambiguity, performance | Use single direction |
| Too many tables | Complexity | Consolidate or denormalize |
| No star schema | DAX complications | Redesign as star |
| Calculated columns on large tables | Memory usage | Use measures instead |
| Unused relationships | Confusion | Delete or document |
| Missing descriptions | Maintenance issues | Document everything |

### Exercise 9.1: Review and Fix

1. Check your model for these issues
2. Fix any bi-directional filters not needed
3. Remove unused tables/columns
4. Verify star schema structure

---

## Part 10: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ Star schema structure in Power BI
2. ✅ Relationship types and cardinality
3. ✅ Cross-filter directions
4. ✅ Role-playing dimensions
5. ✅ Model optimization techniques
6. ✅ Composite models
7. ✅ Documentation best practices

### Quiz

**Question 1:** In a star schema, what type of table contains measurable data?
- a) Dimension table
- b) Fact table
- c) Bridge table
- d) Lookup table

**Question 2:** What is the recommended cross-filter direction for most relationships?
- a) Both
- b) Single
- c) None
- d) Automatic

**Question 3:** How do you use an inactive relationship in a DAX calculation?
- a) ACTIVATE()
- b) USERELATIONSHIP()
- c) SWITCH_RELATIONSHIP()
- d) RELATED()

**Question 4:** What is a role-playing dimension?
- a) A dimension that changes based on user role
- b) A dimension used for multiple purposes in one fact table
- c) A security dimension
- d) A calculated dimension

**Question 5:** Which storage mode allows a table to work as both Import and DirectQuery?
- a) Hybrid
- b) Mixed
- c) Dual
- d) Combined

### Answers
1. b) Fact table
2. b) Single
3. b) USERELATIONSHIP()
4. b) A dimension used for multiple purposes in one fact table
5. c) Dual

---

## Next Lab
**Lab 70: Power Query Transformations** - Master the Power Query Editor for complex data transformations.
