# SSIS Transformations - Complete Guide

## 📚 What You'll Learn
- Understanding transformation types
- Row transformations
- Business Intelligence transformations
- Rowset transformations
- Performance considerations
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Types of Transformations

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    TRANSFORMATION CATEGORIES                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ROW TRANSFORMATIONS (Synchronous - Fast):                             │
│   ├── Derived Column                                                     │
│   ├── Data Conversion                                                    │
│   ├── Character Map                                                      │
│   ├── Copy Column                                                        │
│   ├── OLE DB Command                                                     │
│   └── Script Component                                                   │
│                                                                          │
│   ROWSET TRANSFORMATIONS (Asynchronous - Slow):                         │
│   ├── Sort                                                               │
│   ├── Aggregate                                                          │
│   ├── Pivot / Unpivot                                                    │
│   └── Percentage Sampling                                                │
│                                                                          │
│   SPLIT AND JOIN TRANSFORMATIONS:                                        │
│   ├── Conditional Split                                                  │
│   ├── Multicast                                                          │
│   ├── Union All                                                          │
│   ├── Merge                                                              │
│   └── Merge Join                                                         │
│                                                                          │
│   BUSINESS INTELLIGENCE TRANSFORMATIONS:                                 │
│   ├── Lookup                                                             │
│   ├── Slowly Changing Dimension                                          │
│   ├── Fuzzy Lookup                                                       │
│   └── Fuzzy Grouping                                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Row Transformations

### Derived Column

Creates new columns or modifies existing ones using expressions.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DERIVED COLUMN EXAMPLES                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Expression                          Result                             │
│   ─────────────────────────────────   ─────────────────────────────     │
│   UPPER(FirstName)                    "JOHN"                             │
│   TRIM(CustomerName)                  Remove leading/trailing spaces    │
│   FirstName + " " + LastName          "John Smith"                       │
│   (DT_STR,10,1252)CustomerID          Convert to string                 │
│   ISNULL(Email) ? "N/A" : Email       Handle nulls                       │
│   YEAR(OrderDate)                     Extract year                       │
│   GETDATE()                           Current timestamp                  │
│   REPLACE(Phone,"-","")               Remove dashes                      │
│   SUBSTRING(SSN,1,3)                  First 3 characters                │
│   Price * Quantity                    Calculate total                    │
│   Amount * (TaxRate/100)              Calculate tax                      │
│                                                                          │
│   Conditional Expression:                                                │
│   Status == "A" ? "Active" :                                            │
│   Status == "I" ? "Inactive" : "Unknown"                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Common Functions:**
| Category | Functions |
|----------|-----------|
| String | UPPER, LOWER, TRIM, LTRIM, RTRIM, REPLACE, SUBSTRING, LEN |
| Date | YEAR, MONTH, DAY, GETDATE, DATEADD, DATEDIFF |
| Math | ROUND, ABS, CEILING, FLOOR, POWER |
| Null | ISNULL, NULL, REPLACENULL |
| Conversion | (DT_STR), (DT_WSTR), (DT_I4), (DT_DATE) |

### Data Conversion

Converts data types between source and destination.

```
Common Conversions:
├── String to Integer: DT_I4
├── String to Date: DT_DATE, DT_DBTIMESTAMP
├── Integer to String: DT_STR, DT_WSTR
├── Decimal precision: DT_DECIMAL, DT_NUMERIC
└── Unicode handling: DT_WSTR (Unicode), DT_STR (ANSI)

Configuration:
1. Select input column
2. Choose output alias
3. Select data type
4. Configure length/precision
5. Handle conversion errors
```

### Copy Column

Creates a copy of a column (useful for preserving original values before modification).

```
┌─────────┐         ┌─────────────┐
│ Column  │   →     │ Column      │
│         │         │ Column_Copy │
└─────────┘         └─────────────┘
```

### Character Map

Performs string operations based on character mapping.

```
Operations:
├── Lowercase
├── Uppercase
├── Byte reversal
├── Hiragana/Katakana conversion
├── Half width/Full width conversion
├── Linguistic casing
└── Simplified/Traditional Chinese
```

---

## 📊 Lookup Transformation

The Lookup transformation enriches data by matching against a reference table.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LOOKUP TRANSFORMATION                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────┐                                                        │
│   │ Source Data │                                                        │
│   │ CustomerID  │                                                        │
│   │ OrderAmount │                                                        │
│   └──────┬──────┘                                                        │
│          │                                                               │
│          ▼                                                               │
│   ┌──────────────────────────────┐     ┌──────────────────┐             │
│   │      LOOKUP                  │────▶│ Reference Table  │             │
│   │  Match CustomerID            │     │ CustomerID       │             │
│   │  Get CustomerName, Region    │     │ CustomerName     │             │
│   └──────────────────────────────┘     │ Region           │             │
│          │                             └──────────────────┘             │
│          ▼                                                               │
│   ┌─────────────────────────────────┐                                   │
│   │ Output Data                      │                                   │
│   │ CustomerID, OrderAmount,         │                                   │
│   │ CustomerName, Region             │                                   │
│   └─────────────────────────────────┘                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Cache Modes:**

| Mode | Description | Use When |
|------|-------------|----------|
| Full Cache | Load entire reference table to memory | Reference table < memory, reused |
| Partial Cache | Cache matching rows as found | Large reference, few lookups |
| No Cache | Query for each row | Very large reference, unique keys |

**Error Handling:**
```
No Match Options:
├── Fail Component      - Stop on first no-match
├── Ignore Failure      - Continue, return NULLs
└── Redirect to No Match Output - Route to separate path

Common Pattern - Handle matches and no-matches:
                    ┌─────────┐
                    │ Lookup  │
                    └────┬────┘
           ┌─────────────┴─────────────┐
           ▼                           ▼
    [Match Output]              [No Match Output]
           │                           │
           ▼                           ▼
    ┌─────────────┐             ┌─────────────┐
    │   Update    │             │   Insert    │
    │   Existing  │             │   New       │
    └─────────────┘             └─────────────┘
```

---

## 🔀 Split and Join Transformations

### Conditional Split

Routes rows to different outputs based on conditions.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CONDITIONAL SPLIT                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Configuration:                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ Output Name         │ Condition                                  │   │
│   ├─────────────────────┼───────────────────────────────────────────┤   │
│   │ HighValue           │ Amount > 10000                            │   │
│   │ MediumValue         │ Amount > 1000 && Amount <= 10000          │   │
│   │ LowValue            │ Amount <= 1000                            │   │
│   │ Default Output      │ (catches everything else)                 │   │
│   └─────────────────────┴───────────────────────────────────────────┘   │
│                                                                          │
│   Example Expressions:                                                   │
│   ├── Region == "NORTH"                                                 │
│   ├── OrderDate > (DT_DATE)"2024-01-01"                                │
│   ├── ISNULL(Email)                                                     │
│   ├── LEN(CustomerName) > 0                                             │
│   └── Status == "A" || Status == "P"                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Multicast

Sends copies of data to multiple destinations (same data to multiple outputs).

```
           ┌─────────────┐
           │  Source     │
           └──────┬──────┘
                  │
           ┌──────▼──────┐
           │  Multicast  │
           └──────┬──────┘
      ┌───────────┼───────────┐
      ▼           ▼           ▼
┌───────────┐ ┌───────────┐ ┌───────────┐
│ Staging   │ │ Archive   │ │ Analytics │
│ Table     │ │ Table     │ │ Table     │
└───────────┘ └───────────┘ └───────────┘
```

### Union All

Combines multiple inputs into a single output.

```
┌───────────┐   ┌───────────┐   ┌───────────┐
│ Source 1  │   │ Source 2  │   │ Source 3  │
└─────┬─────┘   └─────┬─────┘   └─────┬─────┘
      │               │               │
      └───────────────┼───────────────┘
                      ▼
              ┌───────────────┐
              │   Union All   │
              └───────┬───────┘
                      ▼
              Combined output
              (all rows from all inputs)

Notes:
├── Column mapping by position or name
├── Does NOT require sorted inputs
├── Faster than Merge
└── Does NOT remove duplicates
```

### Merge

Combines two sorted inputs while maintaining sort order.

```
Requirements:
├── Exactly 2 inputs
├── Both inputs MUST be sorted
├── Same sort key
└── Maintains sort order in output

When to Use:
├── Need sorted output
├── Combining pre-sorted sources
└── Merge Join prerequisites
```

### Merge Join

Performs SQL-style joins between two sorted inputs.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      MERGE JOIN                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌───────────┐         ┌───────────┐                                   │
│   │ Orders    │         │ Customers │                                   │
│   │ (sorted)  │         │ (sorted)  │                                   │
│   └─────┬─────┘         └─────┬─────┘                                   │
│         │                     │                                          │
│         └──────────┬──────────┘                                          │
│                    ▼                                                     │
│            ┌───────────────┐                                             │
│            │  Merge Join   │                                             │
│            │  Join Type:   │                                             │
│            │  INNER/LEFT/  │                                             │
│            │  FULL         │                                             │
│            └───────────────┘                                             │
│                                                                          │
│   Join Types:                                                            │
│   ├── Inner Join: Only matching rows                                    │
│   ├── Left Outer: All left + matching right                             │
│   └── Full Outer: All from both sides                                   │
│                                                                          │
│   IMPORTANT: Both inputs MUST be sorted on join keys!                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📈 Aggregate Transformation

Groups rows and calculates aggregate values.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGGREGATE TRANSFORMATION                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Operations:                                                            │
│   ├── Group by: Define grouping columns                                 │
│   ├── Sum: Add numeric values                                           │
│   ├── Average: Calculate mean                                           │
│   ├── Count: Count rows                                                  │
│   ├── Count Distinct: Count unique values                               │
│   ├── Minimum: Find smallest value                                      │
│   └── Maximum: Find largest value                                       │
│                                                                          │
│   Example Configuration:                                                 │
│   ┌────────────────┬────────────────┬────────────────┐                  │
│   │ Input Column   │ Operation      │ Output Alias   │                  │
│   ├────────────────┼────────────────┼────────────────┤                  │
│   │ Region         │ Group by       │ Region         │                  │
│   │ ProductID      │ Group by       │ ProductID      │                  │
│   │ Quantity       │ Sum            │ TotalQuantity  │                  │
│   │ Amount         │ Average        │ AvgAmount      │                  │
│   │ CustomerID     │ Count          │ CustomerCount  │                  │
│   │ CustomerID     │ Count Distinct │ UniqueCustomers│                  │
│   └────────────────┴────────────────┴────────────────┘                  │
│                                                                          │
│   ⚠️ WARNING: Asynchronous - blocks until all rows processed           │
│   Consider: SQL GROUP BY at source instead                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Sort Transformation

Sorts data by one or more columns.

```
Configuration:
├── Sort columns (order matters)
├── Sort order (Ascending/Descending)
├── Comparison flags (case sensitivity)
└── Remove duplicates option

⚠️ PERFORMANCE WARNING:
├── Asynchronous transformation
├── Must buffer ALL data in memory
├── Very slow for large datasets
├── AVOID when possible!

Alternatives:
├── Sort at source (ORDER BY in SQL)
├── Use indexed tables
└── Pre-sort data in upstream process
```

---

## 📊 Pivot and Unpivot

### Pivot

Converts rows to columns.

```
Before Pivot:
┌──────────┬───────────┬──────────┐
│ Product  │ Quarter   │ Sales    │
├──────────┼───────────┼──────────┤
│ Widget A │ Q1        │ 1000     │
│ Widget A │ Q2        │ 1200     │
│ Widget A │ Q3        │ 1100     │
│ Widget A │ Q4        │ 1500     │
└──────────┴───────────┴──────────┘

After Pivot:
┌──────────┬──────┬──────┬──────┬──────┐
│ Product  │ Q1   │ Q2   │ Q3   │ Q4   │
├──────────┼──────┼──────┼──────┼──────┤
│ Widget A │ 1000 │ 1200 │ 1100 │ 1500 │
└──────────┴──────┴──────┴──────┴──────┘
```

### Unpivot

Converts columns to rows (opposite of Pivot).

```
Before Unpivot:
┌──────────┬──────┬──────┬──────┬──────┐
│ Product  │ Q1   │ Q2   │ Q3   │ Q4   │
├──────────┼──────┼──────┼──────┼──────┤
│ Widget A │ 1000 │ 1200 │ 1100 │ 1500 │
└──────────┴──────┴──────┴──────┴──────┘

After Unpivot:
┌──────────┬───────────┬──────────┐
│ Product  │ Quarter   │ Sales    │
├──────────┼───────────┼──────────┤
│ Widget A │ Q1        │ 1000     │
│ Widget A │ Q2        │ 1200     │
│ Widget A │ Q3        │ 1100     │
│ Widget A │ Q4        │ 1500     │
└──────────┴───────────┴──────────┘
```

---

## 🧠 Slowly Changing Dimension (SCD) Transformation

Wizard-based transformation for handling dimension changes in data warehousing.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCD TYPES                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Type 0 - Fixed:                                                        │
│   └── Never change, ignore updates                                      │
│                                                                          │
│   Type 1 - Overwrite:                                                    │
│   └── Update in place, lose history                                     │
│   └── Customer address changes → update existing row                    │
│                                                                          │
│   Type 2 - Historical:                                                   │
│   └── Insert new row, expire old row                                    │
│   └── Track history with StartDate, EndDate, IsCurrent                  │
│   └── Customer status changes → new row, old row marked inactive        │
│                                                                          │
│   Type 3 - Previous Value:                                               │
│   └── Add column for previous value                                     │
│   └── Limited history (usually just one previous)                       │
│                                                                          │
│   SCD Wizard Outputs:                                                    │
│   ├── Unchanged Output: No changes detected                             │
│   ├── New Output: Insert new dimension members                          │
│   ├── Fixed Attribute Output: Attempted change to fixed column         │
│   ├── Changing Attribute Output: Type 1 updates                         │
│   ├── Historical Attribute Output: Type 2 inserts                       │
│   └── Inferred Member Output: Process inferred members                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 💡 Performance Tips

### Transformation Performance Ranking

```
FASTEST (Synchronous):
├── Derived Column
├── Data Conversion
├── Copy Column
├── Conditional Split
├── Multicast
└── Union All

SLOWER (Partially Blocking):
├── Merge Join
├── Merge
└── Lookup (Full Cache)

SLOWEST (Fully Blocking):
├── Sort                    ← AVOID if possible
├── Aggregate              ← Consider SQL GROUP BY
├── Pivot/Unpivot
└── Fuzzy Lookup/Grouping
```

### Best Practices

```
1. Filter at Source
   ❌ Source → Conditional Split (filter) → Destination
   ✅ Source (with WHERE clause) → Destination

2. Sort at Source
   ❌ Source → Sort → Merge Join
   ✅ Source (ORDER BY) → Merge Join

3. Use Full Cache for Lookups
   - Load reference data once
   - Faster than querying each row

4. Minimize Columns
   - Only select needed columns
   - Remove unused columns early

5. Prefer Union All over Merge
   - Unless sort order required

6. Consider SQL for Aggregates
   - GROUP BY in source query
   - Faster than Aggregate transformation
```

---

## 🎓 Interview Questions

### Q1: What is the difference between synchronous and asynchronous transformations?
**A:**
- **Synchronous**: Process rows in place, same buffer, fast (Derived Column, Data Conversion)
- **Asynchronous**: Create new buffers, block until complete, slow (Sort, Aggregate)

### Q2: What are the Lookup cache modes?
**A:**
- **Full Cache**: Load entire table to memory (fastest, limited by memory)
- **Partial Cache**: Cache matched rows on demand (balance)
- **No Cache**: Query database each time (slowest, unlimited reference size)

### Q3: How do you handle lookup no-matches?
**A:**
- Configure Error Output: Redirect to No Match Output
- Route to separate path for inserts
- Use for detecting new dimension members

### Q4: What is the difference between Union All and Merge?
**A:**
- **Union All**: Multiple inputs, no sort required, faster
- **Merge**: Exactly 2 inputs, both sorted, maintains sort order

### Q5: When would you use Conditional Split vs Multicast?
**A:**
- **Conditional Split**: Route different rows to different paths (each row goes to one output)
- **Multicast**: Send same rows to multiple destinations (copy data)

### Q6: What is the SCD transformation used for?
**A:** Slowly Changing Dimension - handles dimension changes in data warehousing:
- Type 1: Overwrite (lose history)
- Type 2: Add new row (keep history)
- Automatically generates complex logic for dimension updates

### Q7: Why should you avoid the Sort transformation?
**A:**
- Asynchronous - blocks until all data received
- Buffers all data in memory
- Very slow for large datasets
- **Alternative**: Sort at source with ORDER BY

### Q8: How do you create calculated columns in Data Flow?
**A:** Use **Derived Column** transformation:
- Define expression
- Create new column or replace existing
- Use SSIS expression language (different from T-SQL)

### Q9: What is the difference between Merge Join types?
**A:**
- **Inner Join**: Only matching rows
- **Left Outer Join**: All left + matching right (NULLs for no match)
- **Full Outer Join**: All from both sides

### Q10: How do you handle data type mismatches?
**A:**
1. Use **Data Conversion** transformation
2. Use **Derived Column** with casting: `(DT_I4)StringColumn`
3. Configure at source if possible
4. Handle errors with Error Output

---

## 🔗 Related Topics
- [← Data Flow](./03_data_flow.md)
- [Error Handling →](./05_error_handling.md)
- [Performance Optimization →](./06_performance.md)

---

*Next: Learn about Error Handling in SSIS*
