# Lab 06: Window Functions

## Overview
Master window functions for advanced analytics without losing row-level detail.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Understand window function concepts
- ✅ Use ranking functions (row_number, rank, dense_rank)
- ✅ Apply aggregate functions over windows
- ✅ Calculate running totals and moving averages
- ✅ Use lead/lag for row comparisons

---

## Part 1: Window Function Concepts

Window functions perform calculations across a set of rows related to the current row, without collapsing rows like GROUP BY.

```
┌─────────────────────────────────────────────┐
│  Regular Aggregation (GROUP BY)             │
│  Input: 10 rows → Output: 3 rows (grouped)  │
├─────────────────────────────────────────────┤
│  Window Functions                           │
│  Input: 10 rows → Output: 10 rows (same)    │
│  Each row gets computed value from window   │
└─────────────────────────────────────────────┘
```

---

## Part 2: Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Window Functions") \
    .master("local[*]") \
    .getOrCreate()

# Employee salary data
data = [
    ("Engineering", "Alice", 75000, "2020-01-15"),
    ("Engineering", "Bob", 82000, "2019-03-22"),
    ("Engineering", "Charlie", 68000, "2021-06-10"),
    ("Marketing", "Diana", 55000, "2020-02-28"),
    ("Marketing", "Eve", 62000, "2018-11-05"),
    ("Marketing", "Frank", 58000, "2022-04-14"),
    ("Sales", "Grace", 72000, "2019-09-30"),
    ("Sales", "Henry", 65000, "2020-07-18"),
    ("Sales", "Ivy", 78000, "2017-12-01"),
]

schema = ["department", "name", "salary", "hire_date"]
emp = spark.createDataFrame(data, schema)
emp.show()
```

---

## Part 3: Window Specification

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import col

# Window partitioned by department, ordered by salary desc
window_spec = Window.partitionBy("department").orderBy(col("salary").desc())

# Window for entire dataset
global_window = Window.orderBy(col("salary").desc())

# Window with frame specification
range_window = Window.partitionBy("department") \
    .orderBy("salary") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)
```

---

## Part 4: Ranking Functions

### Step 4.1: ROW_NUMBER
Assigns unique sequential number within partition.

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number, col

# Rank employees by salary within department
window_spec = Window.partitionBy("department").orderBy(col("salary").desc())

result = emp.withColumn(
    "row_num", 
    row_number().over(window_spec)
)
result.show()
```

**Output:**
```
+-----------+-------+------+----------+-------+
| department|   name|salary| hire_date|row_num|
+-----------+-------+------+----------+-------+
|Engineering|    Bob| 82000|2019-03-22|      1|
|Engineering|  Alice| 75000|2020-01-15|      2|
|Engineering|Charlie| 68000|2021-06-10|      3|
|  Marketing|    Eve| 62000|2018-11-05|      1|
|  Marketing|  Frank| 58000|2022-04-14|      2|
|  Marketing|  Diana| 55000|2020-02-28|      3|
|      Sales|    Ivy| 78000|2017-12-01|      1|
|      Sales|  Grace| 72000|2019-09-30|      2|
|      Sales|  Henry| 65000|2020-07-18|      3|
+-----------+-------+------+----------+-------+
```

### Step 4.2: RANK vs DENSE_RANK

```python
from pyspark.sql.functions import rank, dense_rank

# Data with ties
tie_data = [
    ("Engineering", "Alice", 80000),
    ("Engineering", "Bob", 80000),
    ("Engineering", "Charlie", 75000),
    ("Engineering", "Diana", 70000),
]
tie_df = spark.createDataFrame(tie_data, ["dept", "name", "salary"])

window_spec = Window.partitionBy("dept").orderBy(col("salary").desc())

result = tie_df \
    .withColumn("row_num", row_number().over(window_spec)) \
    .withColumn("rank", rank().over(window_spec)) \
    .withColumn("dense_rank", dense_rank().over(window_spec))

result.show()
```

**Output:**
```
+-----------+-------+------+-------+----+----------+
|       dept|   name|salary|row_num|rank|dense_rank|
+-----------+-------+------+-------+----+----------+
|Engineering|  Alice| 80000|      1|   1|         1|
|Engineering|    Bob| 80000|      2|   1|         1|
|Engineering|Charlie| 75000|      3|   3|         2|  <- RANK skips, DENSE_RANK doesn't
|Engineering|  Diana| 70000|      4|   4|         3|
+-----------+-------+------+-------+----+----------+
```

### Step 4.3: NTILE
Divides rows into N buckets.

```python
from pyspark.sql.functions import ntile

# Divide employees into salary quartiles
window_spec = Window.partitionBy("department").orderBy(col("salary").desc())

result = emp.withColumn(
    "salary_quartile",
    ntile(4).over(window_spec)
)
result.show()
```

---

## Part 5: Aggregate Window Functions

### Step 5.1: SUM, AVG, COUNT Over Window
```python
from pyspark.sql.functions import sum, avg, count, max, min

window_spec = Window.partitionBy("department")

result = emp.select(
    "department", "name", "salary",
    sum("salary").over(window_spec).alias("dept_total"),
    avg("salary").over(window_spec).alias("dept_avg"),
    count("*").over(window_spec).alias("dept_count"),
    max("salary").over(window_spec).alias("dept_max"),
    min("salary").over(window_spec).alias("dept_min")
)
result.show()
```

### Step 5.2: Percentage of Department Total
```python
from pyspark.sql.functions import sum, round

window_spec = Window.partitionBy("department")

result = emp.withColumn(
    "dept_total",
    sum("salary").over(window_spec)
).withColumn(
    "pct_of_dept",
    round(col("salary") / col("dept_total") * 100, 2)
)

result.select("department", "name", "salary", "dept_total", "pct_of_dept").show()
```

---

## Part 6: Running Totals and Cumulative Sums

### Step 6.1: Running Total
```python
from pyspark.sql.functions import sum
from pyspark.sql.window import Window

# Running total within department ordered by hire date
window_spec = Window.partitionBy("department") \
    .orderBy("hire_date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)

result = emp.withColumn(
    "running_total",
    sum("salary").over(window_spec)
)
result.show()
```

### Step 6.2: Global Running Total
```python
# Global running total (no partition)
window_spec = Window.orderBy("hire_date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)

result = emp.withColumn(
    "cumulative_salary",
    sum("salary").over(window_spec)
).orderBy("hire_date")

result.show()
```

---

## Part 7: Moving Averages

```python
from pyspark.sql.functions import avg, round
from pyspark.sql.window import Window

# 3-row moving average
window_spec = Window.partitionBy("department") \
    .orderBy("hire_date") \
    .rowsBetween(-1, 1)  # Previous, current, next row

result = emp.withColumn(
    "moving_avg_salary",
    round(avg("salary").over(window_spec), 2)
)
result.orderBy("department", "hire_date").show()
```

### Frame Specifications
| Frame | Description |
|-------|-------------|
| `rowsBetween(-1, 1)` | Previous, current, next |
| `rowsBetween(-2, 0)` | Two previous + current |
| `rowsBetween(0, 2)` | Current + next two |
| `rowsBetween(unboundedPreceding, 0)` | All rows before + current |
| `rowsBetween(0, unboundedFollowing)` | Current + all rows after |

---

## Part 8: Lead and Lag Functions

### Step 8.1: LAG - Previous Row Value
```python
from pyspark.sql.functions import lag

window_spec = Window.partitionBy("department").orderBy("hire_date")

result = emp.withColumn(
    "prev_salary",
    lag("salary", 1).over(window_spec)
).withColumn(
    "salary_diff",
    col("salary") - col("prev_salary")
)

result.orderBy("department", "hire_date").show()
```

### Step 8.2: LEAD - Next Row Value
```python
from pyspark.sql.functions import lead

window_spec = Window.partitionBy("department").orderBy("hire_date")

result = emp.withColumn(
    "next_salary",
    lead("salary", 1).over(window_spec)
).withColumn(
    "next_hire_date",
    lead("hire_date", 1).over(window_spec)
)

result.orderBy("department", "hire_date").show()
```

### Step 8.3: Default Values for Lead/Lag
```python
# Provide default value for NULL
result = emp.withColumn(
    "prev_salary",
    lag("salary", 1, 0).over(window_spec)  # Default to 0
)
```

---

## Part 9: First and Last Values

```python
from pyspark.sql.functions import first, last

window_spec = Window.partitionBy("department").orderBy("hire_date")

# First and last values in partition
window_full = Window.partitionBy("department") \
    .orderBy("hire_date") \
    .rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)

result = emp.withColumn(
    "first_hired",
    first("name").over(window_full)
).withColumn(
    "last_hired",
    last("name").over(window_full)
)

result.show()
```

---

## Part 10: Practical Examples

### Example 1: Top N per Group
```python
# Top 2 earners per department
window_spec = Window.partitionBy("department").orderBy(col("salary").desc())

top_2 = emp \
    .withColumn("rank", row_number().over(window_spec)) \
    .filter(col("rank") <= 2) \
    .drop("rank")

top_2.show()
```

### Example 2: Year-over-Year Growth
```python
# Monthly sales data
sales_data = [
    ("2023-01", 10000),
    ("2023-02", 12000),
    ("2023-03", 11000),
    ("2024-01", 12000),
    ("2024-02", 15000),
    ("2024-03", 14000),
]
sales = spark.createDataFrame(sales_data, ["month", "revenue"])

window_spec = Window.orderBy("month")

yoy = sales.withColumn(
    "prev_year_revenue",
    lag("revenue", 12).over(window_spec)
).withColumn(
    "yoy_growth_pct",
    round((col("revenue") - col("prev_year_revenue")) / col("prev_year_revenue") * 100, 2)
)

yoy.show()
```

### Example 3: Salary Percentile
```python
from pyspark.sql.functions import percent_rank

window_spec = Window.partitionBy("department").orderBy("salary")

result = emp.withColumn(
    "salary_percentile",
    round(percent_rank().over(window_spec) * 100, 1)
)

result.show()
```

---

## Exercises

1. Find the second highest salary in each department
2. Calculate running average of salaries ordered by hire date
3. Compare each employee's salary to department average
4. Find employees hired immediately after another

---

## Summary
- Window functions preserve row count while computing aggregates
- Use `row_number()`, `rank()`, `dense_rank()` for ranking
- `lag()`/`lead()` access previous/next rows
- Frame specifications control which rows to include
- Essential for analytics and reporting
