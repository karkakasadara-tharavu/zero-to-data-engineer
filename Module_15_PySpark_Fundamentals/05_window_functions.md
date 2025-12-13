# PySpark Window Functions - Complete Guide

## 📚 What You'll Learn
- Understanding window functions
- Ranking functions (row_number, rank, dense_rank)
- Aggregate functions over windows
- Running totals and moving averages
- Lead and Lag functions
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 What are Window Functions?

Window functions perform calculations across a set of rows that are **related to the current row**. Unlike GroupBy, window functions **keep all original rows** while adding computed values.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Window Function Concept                          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   GroupBy: Data → Group → Aggregate → One row per group                │
│                                                                         │
│   Window:  Data → Partition → Calculate over window → Keep all rows    │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  Original Data                  │  With Window Function                  │
├─────────────────────────────────┼───────────────────────────────────────┤
│  Dept    │ Name   │ Salary      │  Dept    │ Name   │ Salary │ Rank    │
├──────────┼────────┼─────────────┼──────────┼────────┼────────┼─────────┤
│  IT      │ Alice  │ 100000      │  IT      │ Alice  │ 100000 │ 1       │
│  IT      │ Bob    │ 90000       │  IT      │ Bob    │ 90000  │ 2       │
│  IT      │ Carol  │ 85000       │  IT      │ Carol  │ 85000  │ 3       │
│  Sales   │ Dave   │ 80000       │  Sales   │ Dave   │ 80000  │ 1       │
│  Sales   │ Eve    │ 75000       │  Sales   │ Eve    │ 75000  │ 2       │
└──────────┴────────┴─────────────┴──────────┴────────┴────────┴─────────┘
              ↑                                                    ↑
         5 rows input                                    5 rows output with rank!
```

---

## 🔧 Window Specification

### Building a Window

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import *

# Basic window partitioned by column
window = Window.partitionBy("department")

# Window with ordering
window = Window.partitionBy("department").orderBy("salary")

# Window with ordering descending
window = Window.partitionBy("department").orderBy(desc("salary"))

# Window with row specification
window = Window.partitionBy("department") \
    .orderBy("date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)
```

### Window Frame Boundaries

```
┌────────────────────────────────────────────────────────────────────────┐
│                      Window Frame Options                               │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   unboundedPreceding ←───────────────── All rows before                │
│          -3          ←───────────────── 3 rows before                  │
│          -2          ←───────────────── 2 rows before                  │
│          -1          ←───────────────── 1 row before                   │
│     currentRow (0)   ←───────────────── Current row                    │
│           1          ←───────────────── 1 row after                    │
│           2          ←───────────────── 2 rows after                   │
│           3          ←───────────────── 3 rows after                   │
│  unboundedFollowing  ←───────────────── All rows after                 │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘

Common Window Frames:
┌─────────────────────────────────────────────────────────────────────────┐
│  Use Case              │  Frame Specification                           │
├────────────────────────┼────────────────────────────────────────────────┤
│  Running Total         │  unboundedPreceding to currentRow              │
│  Moving Average (3)    │  -2 to currentRow                              │
│  Previous Row          │  -1 to -1                                      │
│  Next Row              │  1 to 1                                        │
│  Entire Partition      │  unboundedPreceding to unboundedFollowing      │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.window import Window
from pyspark.sql.functions import *

spark = SparkSession.builder.appName("WindowFunctions").getOrCreate()

# Employee data
data = [
    ("IT", "Alice", 100000, "2020-01-15"),
    ("IT", "Bob", 90000, "2020-03-20"),
    ("IT", "Carol", 85000, "2021-06-10"),
    ("IT", "Dave", 90000, "2019-11-01"),
    ("Sales", "Eve", 80000, "2020-02-01"),
    ("Sales", "Frank", 75000, "2021-11-05"),
    ("Sales", "Grace", 72000, "2020-04-15"),
    ("HR", "Helen", 65000, "2020-01-20"),
    ("HR", "Ivan", 68000, "2021-09-01"),
]

df = spark.createDataFrame(data, ["department", "name", "salary", "hire_date"])
df = df.withColumn("hire_date", to_date(col("hire_date")))
df.show()
```

---

## 🏆 Ranking Functions

### row_number()

Assigns unique sequential numbers within partition.

```python
window = Window.partitionBy("department").orderBy(desc("salary"))

df.withColumn("row_num", row_number().over(window)).show()

# Output:
# +----------+-----+------+----------+-------+
# |department| name|salary| hire_date|row_num|
# +----------+-----+------+----------+-------+
# |        IT|Alice|100000|2020-01-15|      1|
# |        IT|  Bob| 90000|2020-03-20|      2|  ← Tie broken arbitrarily
# |        IT| Dave| 90000|2019-11-01|      3|  ← Same salary, different number
# |        IT|Carol| 85000|2021-06-10|      4|
# |     Sales|  Eve| 80000|2020-02-01|      1|
# |     Sales|Frank| 75000|2021-11-05|      2|
# ...
```

### rank()

Same rank for ties, gaps in ranking.

```python
df.withColumn("rank", rank().over(window)).show()

# Output:
# +----------+-----+------+----------+----+
# |department| name|salary| hire_date|rank|
# +----------+-----+------+----------+----+
# |        IT|Alice|100000|2020-01-15|   1|
# |        IT|  Bob| 90000|2020-03-20|   2|  ← Same rank for tie
# |        IT| Dave| 90000|2019-11-01|   2|  ← Same rank for tie
# |        IT|Carol| 85000|2021-06-10|   4|  ← Skipped 3!
# ...
```

### dense_rank()

Same rank for ties, no gaps.

```python
df.withColumn("dense_rank", dense_rank().over(window)).show()

# Output:
# +----------+-----+------+----------+----------+
# |department| name|salary| hire_date|dense_rank|
# +----------+-----+------+----------+----------+
# |        IT|Alice|100000|2020-01-15|         1|
# |        IT|  Bob| 90000|2020-03-20|         2|  ← Same rank for tie
# |        IT| Dave| 90000|2019-11-01|         2|  ← Same rank for tie
# |        IT|Carol| 85000|2021-06-10|         3|  ← No gap!
# ...
```

### percent_rank() and ntile()

```python
window = Window.partitionBy("department").orderBy("salary")

df.withColumn("percent_rank", percent_rank().over(window)) \
  .withColumn("ntile_4", ntile(4).over(window)) \
  .show()

# percent_rank: (rank - 1) / (total_rows - 1), values 0 to 1
# ntile(n): Divides rows into n groups
```

### Comparison Summary

| Salary | row_number | rank | dense_rank |
|--------|-----------|------|------------|
| 100000 | 1 | 1 | 1 |
| 90000 | 2 | 2 | 2 |
| 90000 | 3 | 2 | 2 |
| 85000 | 4 | 4 | 3 |
| 80000 | 5 | 5 | 4 |

---

## 📈 Aggregate Window Functions

### Sum, Avg, Count, Min, Max over Window

```python
window = Window.partitionBy("department")

df.withColumn("dept_total", sum("salary").over(window)) \
  .withColumn("dept_avg", round(avg("salary").over(window), 2)) \
  .withColumn("dept_count", count("*").over(window)) \
  .withColumn("dept_max", max("salary").over(window)) \
  .withColumn("dept_min", min("salary").over(window)) \
  .show()

# Each row now has department-level aggregates
# BUT all rows are preserved!
```

### Difference from Group Average

```python
window = Window.partitionBy("department")

df.withColumn("dept_avg", avg("salary").over(window)) \
  .withColumn("diff_from_avg", col("salary") - col("dept_avg")) \
  .show()

# Shows how each person's salary compares to department average
```

---

## 🔄 Running Totals and Moving Averages

### Running Total

```python
window = Window.partitionBy("department") \
    .orderBy("hire_date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)

df.withColumn("running_total", sum("salary").over(window)).show()

# Running total of salaries by hire date within department
```

### Running Count

```python
window = Window.partitionBy("department") \
    .orderBy("hire_date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)

df.withColumn("cumulative_count", count("*").over(window)).show()
```

### Moving Average (Last 3 rows)

```python
window = Window.partitionBy("department") \
    .orderBy("hire_date") \
    .rowsBetween(-2, Window.currentRow)  # Current row and 2 before

df.withColumn("moving_avg_3", round(avg("salary").over(window), 2)).show()
```

### Moving Average (Time-based)

```python
# Range-based window (for dates/numbers)
# Warning: Works with numeric types, dates need conversion

# Convert to days since epoch for range
df_with_days = df.withColumn("days", datediff(col("hire_date"), lit("1970-01-01")))

window = Window.partitionBy("department") \
    .orderBy("days") \
    .rangeBetween(-30, 0)  # Last 30 days

df_with_days.withColumn("30_day_avg", avg("salary").over(window)).show()
```

---

## ⏮️⏭️ Lead and Lag Functions

### lag() - Previous Row Value

```python
window = Window.partitionBy("department").orderBy("hire_date")

df.withColumn("prev_salary", lag("salary", 1).over(window)) \
  .withColumn("prev_name", lag("name", 1).over(window)) \
  .show()

# lag(column, offset, default)
# offset: how many rows back (default 1)
# default: value if no previous row (default NULL)

df.withColumn("prev_salary", lag("salary", 1, 0).over(window)).show()
```

### lead() - Next Row Value

```python
window = Window.partitionBy("department").orderBy("hire_date")

df.withColumn("next_salary", lead("salary", 1).over(window)) \
  .withColumn("next_name", lead("name", 1).over(window)) \
  .show()

# lead(column, offset, default)
# Similar to lag but looks forward
```

### Salary Change Calculation

```python
window = Window.partitionBy("department").orderBy("hire_date")

df.withColumn("prev_salary", lag("salary", 1).over(window)) \
  .withColumn("salary_change", 
      when(col("prev_salary").isNotNull(), 
           col("salary") - col("prev_salary"))
      .otherwise(0)) \
  .show()
```

---

## 🎯 First and Last Values

### first() and last()

```python
window = Window.partitionBy("department").orderBy("hire_date") \
    .rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)

df.withColumn("first_hired", first("name").over(window)) \
  .withColumn("last_hired", last("name").over(window)) \
  .withColumn("first_salary", first("salary").over(window)) \
  .show()
```

### nth_value()

```python
# Get the nth value in the window
window = Window.partitionBy("department").orderBy(desc("salary")) \
    .rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)

df.withColumn("second_highest", nth_value("salary", 2).over(window)).show()
```

---

## 💡 Practical Examples

### Example 1: Top N Per Group

```python
# Top 2 highest paid per department
window = Window.partitionBy("department").orderBy(desc("salary"))

df.withColumn("rank", row_number().over(window)) \
  .filter(col("rank") <= 2) \
  .show()
```

### Example 2: Percentage of Department Total

```python
window = Window.partitionBy("department")

df.withColumn("dept_total", sum("salary").over(window)) \
  .withColumn("pct_of_dept", 
      round(col("salary") / col("dept_total") * 100, 2)) \
  .show()
```

### Example 3: Year-over-Year Growth

```python
# Sample time series data
ts_data = [
    ("Product A", 2020, 1000),
    ("Product A", 2021, 1200),
    ("Product A", 2022, 1500),
    ("Product B", 2020, 500),
    ("Product B", 2021, 600),
    ("Product B", 2022, 750),
]

ts_df = spark.createDataFrame(ts_data, ["product", "year", "sales"])

window = Window.partitionBy("product").orderBy("year")

ts_df.withColumn("prev_year_sales", lag("sales", 1).over(window)) \
     .withColumn("yoy_growth_pct", 
         round((col("sales") - col("prev_year_sales")) / 
               col("prev_year_sales") * 100, 2)) \
     .show()
```

### Example 4: Days Since Last Event

```python
window = Window.partitionBy("department").orderBy("hire_date")

df.withColumn("prev_hire_date", lag("hire_date", 1).over(window)) \
  .withColumn("days_since_last_hire", 
      datediff(col("hire_date"), col("prev_hire_date"))) \
  .show()
```

### Example 5: Identify Duplicate Rows

```python
window = Window.partitionBy("department", "salary").orderBy("name")

df.withColumn("row_num", row_number().over(window)) \
  .filter(col("row_num") > 1) \
  .show()  # Shows duplicates
```

---

## 🎓 Interview Questions

### Q1: What is a window function and how does it differ from GroupBy?
**A:**
- **Window Function**: Performs calculations across related rows while **keeping all original rows**. Each row gets its computed value.
- **GroupBy**: Aggregates rows into groups, returning **one row per group**.

Use window when you need the original data plus computed metrics.

### Q2: What's the difference between row_number, rank, and dense_rank?
**A:**
- **row_number()**: Sequential numbers, ties get different numbers
- **rank()**: Same rank for ties, gaps after ties (1,2,2,4)
- **dense_rank()**: Same rank for ties, no gaps (1,2,2,3)

### Q3: How do you get the top N records per group?
**A:**
```python
window = Window.partitionBy("group_col").orderBy(desc("value_col"))
df.withColumn("rank", row_number().over(window)) \
  .filter(col("rank") <= N)
```

### Q4: Explain rowsBetween vs rangeBetween.
**A:**
- **rowsBetween**: Physical row offset (count of rows)
- **rangeBetween**: Logical value offset (based on ORDER BY column value)

Example: `rowsBetween(-2, 0)` = current row and 2 rows before
`rangeBetween(-10, 0)` = current value and all values within 10 of current

### Q5: How do you calculate a running total?
**A:**
```python
window = Window.partitionBy("category") \
    .orderBy("date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)
df.withColumn("running_total", sum("amount").over(window))
```

### Q6: What are lag() and lead() used for?
**A:**
- **lag()**: Access value from previous row(s)
- **lead()**: Access value from next row(s)

Use cases: Previous value comparison, row-to-row changes, fill forward/backward

### Q7: How do you calculate moving average?
**A:**
```python
# 3-row moving average
window = Window.partitionBy("category") \
    .orderBy("date") \
    .rowsBetween(-2, Window.currentRow)
df.withColumn("moving_avg", avg("value").over(window))
```

### Q8: How do you get the first and last values in a window?
**A:**
```python
window = Window.partitionBy("group") \
    .orderBy("date") \
    .rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)

df.withColumn("first_val", first("col").over(window))
df.withColumn("last_val", last("col").over(window))
```

### Q9: Can you use window functions with aggregations?
**A:** Yes, you can use both:
```python
# First aggregate, then apply window
df.groupBy("dept", "month").agg(sum("sales").alias("monthly_sales")) \
  .withColumn("cumulative", sum("monthly_sales").over(
      Window.partitionBy("dept").orderBy("month")
      .rowsBetween(Window.unboundedPreceding, Window.currentRow)))
```

### Q10: What happens if you don't specify ORDER BY in a window?
**A:**
- For ranking functions: ERROR - order is required
- For aggregate functions: Computes over entire partition (all rows get same value)
- Without ORDER BY, rowsBetween and rangeBetween are not meaningful

---

## 🔗 Related Topics
- [← Aggregations and GroupBy](./04_aggregations.md)
- [Joins →](./06_joins.md)
- [Performance Optimization →](./07_performance.md)

---

*Next: Learn about Joins in PySpark*
