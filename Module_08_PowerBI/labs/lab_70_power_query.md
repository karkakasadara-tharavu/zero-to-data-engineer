# Lab 70: Power Query Transformations

## Objective
Master Power Query Editor for advanced data transformations including column operations, row manipulations, data type conversions, combining queries, and creating reusable functions.

## Prerequisites
- Completion of Labs 68-69
- Power BI Desktop installed
- SQL Server with BookstoreDB database

## Duration
90 minutes

---

## Part 1: Power Query Editor Overview

### The M Language

Power Query uses "M" (Power Query Formula Language):
- Functional language
- Case-sensitive
- Immutable (creates new values, doesn't modify)
- Steps are recorded as M code

### Opening Power Query Editor

1. Home → Transform data, OR
2. Right-click a query → Edit query

### Interface Components

```
┌────────────────────────────────────────────────────────────────┐
│  File  Home  Transform  Add Column  View  Tools  Help          │
├────────────────────────────────────────────────────────────────┤
│ ┌────────────┐ ┌─────────────────────────┐ ┌─────────────────┐│
│ │  Queries   │ │                         │ │ Query Settings  ││
│ │            │ │   Data Preview          │ │                 ││
│ │ ☐ Books    │ │                         │ │ Properties:     ││
│ │ ☐ Orders   │ │   [Column headers with  │ │ Name: Books     ││
│ │ ☐ Customers│ │    data types shown]    │ │                 ││
│ │ ☐ Authors  │ │                         │ │ Applied Steps:  ││
│ │            │ │   Row1 | Row2 | Row3    │ │ ☑ Source        ││
│ │ Folder:    │ │   Row4 | Row5 | Row6    │ │ ☑ Navigation    ││
│ │ ▶ Sample   │ │                         │ │ ☑ Changed Type  ││
│ │ ▶ Transform│ │                         │ │                 ││
│ └────────────┘ └─────────────────────────┘ └─────────────────┘│
│                    Formula Bar (shows M code)                   │
└────────────────────────────────────────────────────────────────┘
```

### Exercise 1.1: Explore Applied Steps

1. Open Power Query Editor
2. Select a query (e.g., Books)
3. In Query Settings pane, click through each step
4. Observe how data changes at each step
5. View the formula bar to see M code

---

## Part 2: Column Operations

### Common Column Transformations

| Operation | How to Access | M Function |
|-----------|--------------|------------|
| Rename | Double-click header | Table.RenameColumns |
| Remove | Right-click → Remove | Table.RemoveColumns |
| Duplicate | Right-click → Duplicate | Table.DuplicateColumn |
| Change Type | Click type icon | Table.TransformColumnTypes |
| Replace Values | Right-click → Replace | Table.ReplaceValue |
| Split | Right-click → Split | Table.SplitColumn |
| Merge | Select columns → Merge | Table.CombineColumns |

### Exercise 2.1: Basic Column Operations

**Rename Columns:**
1. Double-click column header
2. Type new name
3. Press Enter

```m
// M Code equivalent
= Table.RenameColumns(PreviousStep, {{"OldName", "NewName"}})
```

**Remove Columns:**
1. Select column(s) to remove (Ctrl+click for multiple)
2. Right-click → Remove Columns
3. OR: Right-click → Remove Other Columns (keep selected)

```m
// M Code
= Table.RemoveColumns(PreviousStep, {"Column1", "Column2"})
// OR keep specific columns
= Table.SelectColumns(PreviousStep, {"KeepCol1", "KeepCol2"})
```

**Duplicate Column:**
1. Right-click column → Duplicate Column

```m
= Table.DuplicateColumn(PreviousStep, "ColumnName", "ColumnName - Copy")
```

### Exercise 2.2: Data Type Conversions

**Change Data Type:**
1. Click the type icon in column header
2. Select appropriate type

| Icon | Type | Example |
|------|------|---------|
| 123 | Whole Number | 42 |
| 1.2 | Decimal Number | 19.99 |
| ABC | Text | "Hello" |
| 📅 | Date | 2024-01-15 |
| 🕐 | DateTime | 2024-01-15 14:30 |
| ✓✗ | True/False | TRUE |

```m
// M Code
= Table.TransformColumnTypes(PreviousStep, {
    {"Price", type number},
    {"OrderDate", type date},
    {"IsActive", type logical}
})
```

### Exercise 2.3: Replace Values

1. Right-click column → Replace Values
2. Enter:
   - Value To Find: (old value)
   - Replace With: (new value)

```m
// M Code
= Table.ReplaceValue(
    PreviousStep,
    "Old Value",
    "New Value",
    Replacer.ReplaceText,  // or Replacer.ReplaceValue for exact match
    {"ColumnName"}
)
```

**Replace null values:**
```m
= Table.ReplaceValue(PreviousStep, null, "Unknown", Replacer.ReplaceValue, {"Category"})
```

---

## Part 3: Row Operations

### Filtering Rows

**Filter Options:**
1. Click filter arrow in column header
2. Choose filter type:
   - Text filters (contains, starts with, etc.)
   - Number filters (greater than, between, etc.)
   - Date filters (this year, last month, etc.)

### Exercise 3.1: Filter Data

**Filter by specific values:**
1. Click filter arrow on Status column
2. Uncheck values to exclude
3. Click OK

```m
= Table.SelectRows(PreviousStep, each [Status] = "Active")
```

**Filter by condition:**
1. Click filter arrow → Text/Number Filters
2. Choose condition (e.g., "greater than")
3. Enter value

```m
// Multiple conditions
= Table.SelectRows(PreviousStep, each [Price] > 20 and [Stock] > 0)
```

### Exercise 3.2: Remove Rows

**Remove top/bottom rows:**
- Transform → Remove Rows → Remove Top Rows
- Useful for removing header rows in flat files

```m
= Table.Skip(PreviousStep, 1)  // Skip first row
= Table.RemoveLastN(PreviousStep, 5)  // Remove last 5 rows
```

**Remove duplicates:**
1. Select column(s) for uniqueness check
2. Home → Remove Rows → Remove Duplicates

```m
= Table.Distinct(PreviousStep, {"CustomerID"})
```

**Remove errors:**
1. Right-click column → Remove Errors

```m
= Table.RemoveRowsWithErrors(PreviousStep, {"ColumnName"})
```

### Exercise 3.3: Keep Rows

**Keep specific rows:**
```m
// Keep top N rows
= Table.FirstN(PreviousStep, 100)

// Keep bottom N rows
= Table.LastN(PreviousStep, 50)

// Keep range
= Table.Range(PreviousStep, 10, 20)  // Start at row 10, take 20 rows
```

---

## Part 4: Adding Custom Columns

### Custom Column Types

| Type | Description | Use Case |
|------|-------------|----------|
| Custom Column | Any M expression | Complex calculations |
| Conditional Column | If/Then/Else logic | Categorization |
| Index Column | Sequential numbers | Row numbers |
| Column from Examples | AI-assisted | Pattern recognition |

### Exercise 4.1: Create Custom Column

1. Add Column → Custom Column
2. Enter column name and formula

**Example: Calculate profit margin:**
```m
// In Custom Column dialog
= [SalesAmount] - [CostAmount]
```

**Example: Full name:**
```m
= [FirstName] & " " & [LastName]
```

**Example: Extract year:**
```m
= Date.Year([OrderDate])
```

### Exercise 4.2: Conditional Column

1. Add Column → Conditional Column
2. Build conditions using the UI

```
If [Price] is less than 20 Then "Budget"
Else If [Price] is less than 50 Then "Standard"
Else If [Price] is less than 100 Then "Premium"
Else "Luxury"
```

**M Code equivalent:**
```m
= Table.AddColumn(PreviousStep, "PriceCategory", each 
    if [Price] < 20 then "Budget"
    else if [Price] < 50 then "Standard"
    else if [Price] < 100 then "Premium"
    else "Luxury"
)
```

### Exercise 4.3: Index Column

1. Add Column → Index Column
2. Choose:
   - From 0 (starts at 0)
   - From 1 (starts at 1)
   - Custom (specify start and increment)

```m
= Table.AddIndexColumn(PreviousStep, "Index", 1, 1)  // Start at 1, increment by 1
```

---

## Part 5: Text Transformations

### Common Text Functions

| Function | Description | Example |
|----------|-------------|---------|
| Text.Upper | Uppercase | "hello" → "HELLO" |
| Text.Lower | Lowercase | "HELLO" → "hello" |
| Text.Proper | Title case | "hello world" → "Hello World" |
| Text.Trim | Remove spaces | " hello " → "hello" |
| Text.Clean | Remove non-printable | Cleans control chars |
| Text.Replace | Replace substring | "hello" → "hi" |
| Text.Start | First N chars | "hello" → "hel" |
| Text.End | Last N chars | "hello" → "llo" |
| Text.Length | Character count | "hello" → 5 |

### Exercise 5.1: Text Transformations

**Clean and format text columns:**

1. Select a text column
2. Transform → Format → Choose operation

```m
// Format name properly
= Table.TransformColumns(PreviousStep, {
    {"FirstName", Text.Proper},
    {"LastName", Text.Proper}
})

// Clean and trim
= Table.TransformColumns(PreviousStep, {
    {"Email", each Text.Trim(Text.Lower(_))}
})
```

### Exercise 5.2: Extract Text

**Extract from text using Transform menu:**

```m
// Extract first 3 characters
= Table.TransformColumns(PreviousStep, {
    {"ProductCode", each Text.Start(_, 3)}
})

// Extract between delimiters
= Table.TransformColumns(PreviousStep, {
    {"Email", each Text.BeforeDelimiter(_, "@")}
})
```

### Exercise 5.3: Split Column

1. Right-click column → Split Column
2. Choose delimiter or character count

**By Delimiter:**
```m
= Table.SplitColumn(PreviousStep, "FullName", 
    Splitter.SplitTextByDelimiter(" ", QuoteStyle.Csv),
    {"FirstName", "LastName"})
```

**By Number of Characters:**
```m
= Table.SplitColumn(PreviousStep, "ProductCode",
    Splitter.SplitTextByPositions({0, 3, 6}),
    {"Category", "SubCat", "Item"})
```

---

## Part 6: Date and Time Transformations

### Date Functions

| Function | Description | Example Result |
|----------|-------------|----------------|
| Date.Year | Extract year | 2024 |
| Date.Month | Extract month (1-12) | 7 |
| Date.Day | Extract day | 15 |
| Date.MonthName | Month name | "July" |
| Date.DayOfWeek | Day number (0-6) | 1 (Monday) |
| Date.DayOfWeekName | Day name | "Monday" |
| Date.WeekOfYear | Week number | 28 |
| Date.StartOfMonth | First of month | 2024-07-01 |
| Date.EndOfMonth | Last of month | 2024-07-31 |

### Exercise 6.1: Extract Date Parts

1. Select date column
2. Add Column → Date → (choose extraction)

```m
// Add multiple date columns
= Table.AddColumn(PreviousStep, "Year", each Date.Year([OrderDate]))
= Table.AddColumn(PreviousStep, "Month", each Date.Month([OrderDate]))
= Table.AddColumn(PreviousStep, "MonthName", each Date.MonthName([OrderDate]))
= Table.AddColumn(PreviousStep, "Quarter", each Date.QuarterOfYear([OrderDate]))
```

### Exercise 6.2: Calculate Date Differences

```m
// Days between two dates
= Table.AddColumn(PreviousStep, "DaysDiff", each 
    Duration.Days([ShipDate] - [OrderDate]))

// Add days to a date
= Table.AddColumn(PreviousStep, "DueDate", each 
    Date.AddDays([OrderDate], 30))
```

### Exercise 6.3: Create Date Table

Generate a date dimension table in Power Query:

```m
// Create date table
let
    StartDate = #date(2020, 1, 1),
    EndDate = #date(2025, 12, 31),
    NumberOfDays = Duration.Days(EndDate - StartDate) + 1,
    DateList = List.Dates(StartDate, NumberOfDays, #duration(1, 0, 0, 0)),
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing()),
    RenamedColumn = Table.RenameColumns(DateTable, {{"Column1", "Date"}}),
    ChangedType = Table.TransformColumnTypes(RenamedColumn, {{"Date", type date}}),
    AddYear = Table.AddColumn(ChangedType, "Year", each Date.Year([Date])),
    AddMonth = Table.AddColumn(AddYear, "Month", each Date.Month([Date])),
    AddMonthName = Table.AddColumn(AddMonth, "MonthName", each Date.MonthName([Date])),
    AddDay = Table.AddColumn(AddMonthName, "Day", each Date.Day([Date])),
    AddDayOfWeek = Table.AddColumn(AddDay, "DayOfWeek", each Date.DayOfWeekName([Date])),
    AddQuarter = Table.AddColumn(AddDayOfWeek, "Quarter", each Date.QuarterOfYear([Date])),
    AddWeek = Table.AddColumn(AddQuarter, "WeekOfYear", each Date.WeekOfYear([Date]))
in
    AddWeek
```

---

## Part 7: Combining Queries

### Append Queries

Combine rows from multiple tables (UNION):

1. Home → Append Queries
2. Choose tables to append
3. Result: All rows combined

```m
= Table.Combine({Table1, Table2, Table3})
```

**Use cases:**
- Combine monthly data files
- Union regional data
- Stack historical data

### Exercise 7.1: Append Queries

1. Create sample tables or import multiple files
2. Home → Append Queries → Append Queries as New
3. Select tables to combine

### Merge Queries

Join tables based on matching columns (JOIN):

1. Home → Merge Queries
2. Select tables and join columns
3. Choose join type
4. Expand joined columns

### Join Types

| Join Type | Description | Returns |
|-----------|-------------|---------|
| Left Outer | All from left, matching from right | Left + Matched Right |
| Right Outer | All from right, matching from left | Right + Matched Left |
| Full Outer | All from both | All Left + All Right |
| Inner | Only matches | Matched rows only |
| Left Anti | Left not in right | Unmatched Left |
| Right Anti | Right not in left | Unmatched Right |

### Exercise 7.2: Merge Queries

**Join Orders with Customers:**

1. Select Orders query
2. Home → Merge Queries
3. Select matching columns:
   - Orders[CustomerID] ↔ Customers[CustomerID]
4. Choose Left Outer join
5. Expand to add CustomerName

```m
= Table.NestedJoin(Orders, {"CustomerID"}, Customers, {"CustomerID"}, "CustomerData", JoinKind.LeftOuter)
= Table.ExpandTableColumn(#"Merged", "CustomerData", {"CustomerName", "Email"})
```

---

## Part 8: Advanced M Techniques

### Using Variables (let...in)

```m
let
    Source = Sql.Database("localhost", "BookstoreDB"),
    BooksTable = Source{[Schema="dbo", Item="Books"]}[Data],
    FilteredRows = Table.SelectRows(BooksTable, each [Price] > 20),
    RenamedColumns = Table.RenameColumns(FilteredRows, {{"BookID", "ID"}}),
    Result = Table.AddColumn(RenamedColumns, "PriceCategory", each 
        if [Price] < 50 then "Standard" else "Premium")
in
    Result
```

### Error Handling

```m
// Try/Otherwise pattern
= Table.AddColumn(PreviousStep, "SafeCalculation", each 
    try [Value1] / [Value2] otherwise null)

// Replace errors with specific value
= Table.ReplaceErrorValues(PreviousStep, {{"Column1", 0}})
```

### Exercise 8.1: Create a Custom Function

**Create a reusable cleaning function:**

1. Create a new blank query
2. Enter this M code:

```m
(inputText as text) as text =>
let
    Trimmed = Text.Trim(inputText),
    Cleaned = Text.Clean(Trimmed),
    Proper = Text.Proper(Cleaned)
in
    Proper
```

3. Name it `CleanText`
4. Use in other queries:

```m
= Table.TransformColumns(PreviousStep, {{"CustomerName", CleanText}})
```

### Exercise 8.2: Parameterized Query

**Create a parameter for filtering:**

1. Home → Manage Parameters → New Parameter
2. Name: `MinPrice`
3. Type: Decimal Number
4. Current Value: 20

5. Use in query:
```m
= Table.SelectRows(PreviousStep, each [Price] >= MinPrice)
```

---

## Part 9: Performance Best Practices

### Query Folding

**What is Query Folding?**
Power Query pushes transformations back to the data source when possible.

**Check if folding:**
1. Right-click a step
2. Look for "View Native Query"
3. If available, step is folded

**Steps that break folding:**
- Adding index column
- Many custom columns
- Complex conditions
- Certain text operations

### Performance Tips

| Tip | Description |
|-----|-------------|
| Filter early | Reduce rows before other operations |
| Remove columns early | Less data to process |
| Avoid unnecessary steps | Each step adds overhead |
| Use native queries | Let the database do the work |
| Disable auto-detect | Set types manually |
| Fold when possible | Push to source |

### Exercise 9.1: Optimize a Query

1. Review your query steps
2. Reorder: Filter → Remove Columns → Transform
3. Check for query folding
4. Combine similar steps

---

## Part 10: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ Power Query Editor interface
2. ✅ Column operations (rename, remove, transform)
3. ✅ Row operations (filter, remove duplicates)
4. ✅ Custom and conditional columns
5. ✅ Text transformations
6. ✅ Date calculations
7. ✅ Append and merge queries
8. ✅ Advanced M techniques
9. ✅ Performance optimization

### Quiz

**Question 1:** What language does Power Query use?
- a) DAX
- b) SQL
- c) M
- d) Python

**Question 2:** Which operation combines rows from multiple tables?
- a) Merge
- b) Append
- c) Join
- d) Union

**Question 3:** What join type returns only matching rows from both tables?
- a) Left Outer
- b) Right Outer
- c) Inner
- d) Full Outer

**Question 4:** What is query folding?
- a) Collapsing query steps
- b) Pushing transformations to the data source
- c) Organizing queries into folders
- d) Compressing query results

**Question 5:** Which step typically breaks query folding?
- a) Filter Rows
- b) Add Index Column
- c) Remove Columns
- d) Change Type

### Answers
1. c) M
2. b) Append
3. c) Inner
4. b) Pushing transformations to the data source
5. b) Add Index Column

---

## Next Lab
**Lab 71: DAX Fundamentals** - Learn the basics of Data Analysis Expressions for creating powerful calculations.
