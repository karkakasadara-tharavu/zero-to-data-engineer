# Lab 73: Visualizations and Reports

## Objective
Master Power BI visualization best practices, chart selection, formatting, interactivity, and professional report design for effective data storytelling.

## Prerequisites
- Completion of Labs 68-72
- Power BI Desktop with data model and measures
- Understanding of DAX basics

## Duration
90 minutes

---

## Part 1: Choosing the Right Visualization

### Visualization Selection Guide

| Data Question | Best Visualization | Alternatives |
|---------------|-------------------|--------------|
| How much? (single value) | Card, KPI | Gauge |
| How does it compare? | Bar/Column chart | Bullet chart |
| How has it changed over time? | Line chart | Area chart |
| What is the composition? | Stacked bar, Pie | Treemap, Donut |
| What is the relationship? | Scatter plot | Bubble chart |
| What is the distribution? | Histogram | Box plot |
| Where is it? | Map | Filled map |
| What are the details? | Table | Matrix |

### Chart Types in Power BI

```
┌─────────────────────────────────────────────────────────────┐
│                    VISUALIZATION CATEGORIES                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  COMPARISON          TREND               COMPOSITION         │
│  ┌─────────┐        ┌─────────┐         ┌─────────┐         │
│  │█ █ █ █  │        │    ╱╲   │         │ ██ ░░ ▒▒│         │
│  │█ █ █ █  │        │  ╱    ╲ │         │ ██ ░░ ▒▒│         │
│  │█ █ █ █  │        │╱        ╲│         │ ██ ░░ ▒▒│         │
│  └─────────┘        └─────────┘         └─────────┘         │
│  Column/Bar          Line/Area          Stacked/100%         │
│                                                              │
│  RELATIONSHIP        DISTRIBUTION        GEOGRAPHIC          │
│  ┌─────────┐        ┌─────────┐         ┌─────────┐         │
│  │  •   •  │        │  ▃▅█▅▃  │         │   🗺️    │         │
│  │•   •  • │        │  █████  │         │  📍📍   │         │
│  │  •   •  │        │  █████  │         │    📍   │         │
│  └─────────┘        └─────────┘         └─────────┘         │
│  Scatter/Bubble      Histogram          Map/Filled          │
└─────────────────────────────────────────────────────────────┘
```

### Exercise 1.1: Match Data to Visualization

For each scenario, identify the best visualization:

1. **Monthly sales trend for the past 2 years**
   - Answer: Line chart

2. **Top 10 products by revenue**
   - Answer: Horizontal bar chart

3. **Sales distribution across categories**
   - Answer: Pie/Donut or Treemap

4. **Current month sales vs target**
   - Answer: KPI or Gauge

5. **Sales by region on a map**
   - Answer: Map or Filled map

---

## Part 2: Creating Basic Visualizations

### Card Visualization

**Purpose:** Display a single important metric

**Steps:**
1. Click empty canvas
2. Select Card from Visualizations pane
3. Drag measure to Values field

**Format options:**
- Category label (on/off)
- Font size and color
- Background
- Border

### Exercise 2.1: Create KPI Cards

Create four cards across the top of your report:

```
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Total Sales  │ │   Orders     │ │  Customers   │ │  Avg Order   │
│   $1.2M      │ │    5,432     │ │    1,234     │ │    $221      │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

**Configuration:**
1. Create Card for [Total Sales]
2. Create Card for [Transaction Count]
3. Create Card for [Customer Count]
4. Create Card for [Avg Order Value]

### Column and Bar Charts

**When to use:**
- Column (vertical): Time series comparison, categories
- Bar (horizontal): Ranking, long category names

### Exercise 2.2: Create Comparison Charts

**Sales by Category (Column Chart):**
1. Select Clustered Column Chart
2. X-axis: `DimBook[Category]`
3. Y-axis: `[Total Sales]`
4. Sort descending by value

**Top 10 Books (Bar Chart):**
1. Select Clustered Bar Chart
2. Y-axis: `DimBook[Title]`
3. X-axis: `[Total Sales]`
4. Add filter: Top 10 by [Total Sales]

### Line Charts

**Best for:** Trends over time

### Exercise 2.3: Create Trend Charts

1. Select Line Chart
2. X-axis: `DimDate[Date]` (with hierarchy)
3. Y-axis: `[Total Sales]`
4. Add secondary line for [Transaction Count]

**Format:**
- Enable data labels (at max/min)
- Add trend line
- Customize line colors

---

## Part 3: Advanced Visualizations

### Combo Charts

Combine two chart types (e.g., column + line):

### Exercise 3.1: Create Combo Chart

1. Select Line and Clustered Column Chart
2. Configure:
   - Shared axis: `DimDate[Month]`
   - Column values: `[Total Sales]`
   - Line values: `[Transaction Count]`

3. Format:
   - Different Y-axis scales
   - Distinct colors

### Scatter Charts

**Purpose:** Show relationship between two metrics

### Exercise 3.2: Create Scatter Plot

Analyze relationship between quantity and sales:

1. Select Scatter Chart
2. Configure:
   - X-axis: `[Total Quantity]`
   - Y-axis: `[Total Sales]`
   - Details: `DimBook[Title]`
   - Size: `[Total Profit]` (optional)

### Matrix

**Purpose:** Cross-tabulation with hierarchies

### Exercise 3.3: Create Sales Matrix

1. Select Matrix visual
2. Configure:
   - Rows: `DimDate[Year]`, `DimDate[Quarter]`
   - Columns: `DimBook[Category]`
   - Values: `[Total Sales]`

3. Enable:
   - Stepped layout
   - Row subtotals
   - Column subtotals
   - Expand/collapse icons

### Treemap

**Purpose:** Hierarchical part-to-whole

### Exercise 3.4: Create Treemap

1. Select Treemap
2. Configure:
   - Category: `DimBook[Category]`
   - Details: `DimBook[Title]`
   - Values: `[Total Sales]`

---

## Part 4: Formatting Visualizations

### The Format Pane

Click the paint roller icon to access:
- Visual properties
- General properties
- Title, background, border
- Data labels
- Legend
- Axis settings

### Exercise 4.1: Apply Consistent Formatting

**Title Formatting:**
1. Enable title
2. Set title text: "Sales by Category"
3. Font: Segoe UI, 14pt, Bold
4. Alignment: Center
5. Background: Light gray

**Data Labels:**
1. Enable data labels
2. Position: Outside end
3. Display units: Thousands (K) or Millions (M)
4. Decimal places: 1

**Colors:**
1. Use consistent color palette
2. Apply conditional formatting for emphasis

### Conditional Formatting

### Exercise 4.2: Apply Conditional Formatting

**Background Color Rules:**
1. Select a table or matrix
2. Click column header → Conditional formatting → Background color
3. Choose:
   - Gradient (continuous)
   - Rules (categorical)

**Example rules:**
```
If Value >= 100000 → Green
If Value >= 50000 → Yellow
If Value < 50000 → Red
```

**Data Bars:**
1. Conditional formatting → Data bars
2. Choose bar color and direction

**Icons:**
1. Conditional formatting → Icons
2. Choose icon style (arrows, shapes, flags)
3. Define rules

### Exercise 4.3: Format a Complete Dashboard

Apply these standards to all visuals:
- Consistent fonts (Segoe UI)
- Uniform title style
- Coordinated colors
- Appropriate data labels
- Aligned elements

---

## Part 5: Slicers and Filters

### Slicer Types

| Type | Best For | Example |
|------|----------|---------|
| List | Few options (<10) | Categories |
| Dropdown | Many options | Products |
| Between | Numeric ranges | Price range |
| Relative date | Dynamic dates | Last 30 days |
| Tile/Button | Quick selections | Year buttons |

### Exercise 5.1: Create Different Slicers

**Dropdown Slicer:**
1. Add Slicer visual
2. Field: `DimBook[Category]`
3. Format → Slicer settings → Style: Dropdown

**Date Range Slicer:**
1. Add Slicer
2. Field: `DimDate[Date]`
3. Format → Slicer settings → Style: Between

**Button Slicer:**
1. Add Slicer
2. Field: `DimDate[Year]`
3. Format → Selection → Single select: On
4. Orientation: Horizontal

### Syncing Slicers

Sync slicers across pages:
1. Select slicer
2. View → Sync slicers
3. Check boxes for pages to sync

### Exercise 5.2: Create Slicer Panel

Design a collapsible slicer panel:

```
┌────────────────────────────────────────────────────────────┐
│ ☰ Filters                                                   │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Year: [2022] [2023] [2024]                                │
│                                                             │
│  Category: [All Categories    ▼]                           │
│                                                             │
│  Date Range: [Jan 1] to [Dec 31]                           │
│                                                             │
│  Region: ☐ North  ☐ South  ☐ East  ☐ West                 │
│                                                             │
│  [Clear All Filters]                                        │
└────────────────────────────────────────────────────────────┘
```

---

## Part 6: Interactivity

### Drill-Down and Drill-Through

**Drill-Down:** Navigate hierarchy within a visual
**Drill-Through:** Navigate to detailed page

### Exercise 6.1: Enable Drill-Down

1. Create chart with hierarchy (Year → Quarter → Month)
2. Click the double-down arrow to drill down
3. Click bar/line to drill into specific value

### Exercise 6.2: Create Drill-Through Page

**Step 1: Create detail page**
1. Add new page named "Book Details"
2. Add visuals for book-level analysis

**Step 2: Add drill-through field**
1. Drag `DimBook[Title]` to Drill-through section
2. Add "Back" button (Insert → Buttons → Back)

**Step 3: Test**
1. Right-click a book in any visual
2. Select Drill through → Book Details

### Edit Interactions

Control how visuals filter each other:

1. Select a visual
2. Format → Edit interactions
3. For each other visual, choose:
   - Filter (default)
   - Highlight
   - None

### Exercise 6.3: Configure Interactions

Set up these interaction behaviors:

| Source Visual | Target Visual | Interaction |
|--------------|---------------|-------------|
| Category Bar | Sales Line | Filter |
| Date Slicer | All visuals | Filter |
| KPI Cards | Other visuals | None |
| Matrix | Charts | Highlight |

---

## Part 7: Bookmarks and Navigation

### Bookmarks

Capture the state of a report page:
- Filters
- Slicer selections
- Visual visibility
- Spotlight

### Exercise 7.1: Create Bookmarks

**Scenario:** Create views for different regions

1. View → Bookmarks pane
2. Set slicers to "North Region"
3. Click Add bookmark
4. Name: "North Region View"
5. Repeat for other regions

### Buttons

Create navigation and action buttons:

1. Insert → Buttons
2. Choose type: Blank, Back, Navigator, etc.
3. Configure action in Format pane

### Exercise 7.2: Create Navigation

**Create a navigation bar:**

```
┌────────────────────────────────────────────────────────────┐
│  [Overview]  [Sales]  [Customers]  [Products]  [Trends]    │
└────────────────────────────────────────────────────────────┘
```

**Steps:**
1. Insert → Buttons → Blank
2. Format text: "Overview"
3. Action → Type: Page navigation
4. Action → Destination: Overview page
5. Duplicate for other pages

### Exercise 7.3: Show/Hide Panel

Create a toggle for filter panel:

1. Create a rectangle behind filters (grouped)
2. Add bookmark "Filters Visible" (panel visible)
3. Hide panel, add bookmark "Filters Hidden"
4. Create button with toggle action

---

## Part 8: Report Design Principles

### Layout Best Practices

```
┌────────────────────────────────────────────────────────────┐
│ HEADER / TITLE                                              │
│ ─────────────────────────────────────────────────────────── │
│                                                              │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│ │ KPI 1   │ │ KPI 2   │ │ KPI 3   │ │ KPI 4   │            │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘            │
│                                                              │
│ ┌──────────────────────┐ ┌──────────────────────┐          │
│ │                      │ │                      │          │
│ │   Primary Chart      │ │   Secondary Chart    │          │
│ │                      │ │                      │          │
│ └──────────────────────┘ └──────────────────────┘          │
│                                                              │
│ ┌──────────────────────────────────────────────┐           │
│ │                                              │           │
│ │            Detail Table / Matrix             │           │
│ │                                              │           │
│ └──────────────────────────────────────────────┘           │
│                                                              │
│ FOOTER / FILTERS                                            │
└────────────────────────────────────────────────────────────┘
```

### The Z-Pattern

Users scan in a Z pattern:
1. Top-left (most important)
2. Top-right
3. Bottom-left
4. Bottom-right (detail/action)

### Exercise 8.1: Design a Dashboard Layout

Create a sales dashboard with:

1. **Header:** Company logo, title, date range
2. **Top Row:** 4 KPI cards
3. **Middle Left:** Primary trend chart
4. **Middle Right:** Category breakdown
5. **Bottom:** Detail table with drill-through
6. **Right Sidebar:** Slicers

### Color Best Practices

| Guideline | Description |
|-----------|-------------|
| Limit palette | 5-7 colors maximum |
| Consistent meaning | Red = bad, Green = good |
| Accessible | Consider color blindness |
| Brand aligned | Match company colors |
| Neutral backgrounds | Gray/white for backgrounds |

### Exercise 8.2: Create Color Theme

1. View → Themes → Customize current theme
2. Define:
   - Primary color (main metrics)
   - Secondary colors (categories)
   - Background colors
   - Text colors

3. Save as JSON for reuse

---

## Part 9: Mobile Layout

### Design for Mobile

1. View → Mobile layout
2. Rearrange visuals for vertical scrolling
3. Simplify - fewer visuals per screen

### Exercise 9.1: Create Mobile View

1. Switch to Mobile layout
2. Prioritize visuals:
   - KPI cards at top
   - Primary chart below
   - Table/details at bottom
3. Resize for mobile screen

---

## Part 10: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ Choosing appropriate visualizations
2. ✅ Creating and formatting charts
3. ✅ Conditional formatting
4. ✅ Slicers and filters
5. ✅ Drill-down and drill-through
6. ✅ Bookmarks and navigation
7. ✅ Report design principles
8. ✅ Mobile layouts

### Quiz

**Question 1:** Which chart type is best for showing trends over time?
- a) Pie chart
- b) Bar chart
- c) Line chart
- d) Treemap

**Question 2:** What does drill-through do?
- a) Drills down within a hierarchy
- b) Navigates to a detailed page with context
- c) Filters all visuals
- d) Creates a new visual

**Question 3:** How do you sync slicers across pages?
- a) Copy/paste the slicer
- b) Use the Sync slicers pane
- c) Create a parameter
- d) Use bookmarks

**Question 4:** What is the Z-pattern in design?
- a) A zigzag chart type
- b) How users naturally scan a page
- c) A navigation style
- d) An error pattern

**Question 5:** Which interaction mode shows data without filtering?
- a) Filter
- b) Highlight
- c) None
- d) Drill

### Answers
1. c) Line chart
2. b) Navigates to a detailed page with context
3. b) Use the Sync slicers pane
4. b) How users naturally scan a page
5. b) Highlight

---

## Next Lab
**Lab 74: Dashboards and Deployment** - Learn to publish reports, create dashboards, and configure security.
