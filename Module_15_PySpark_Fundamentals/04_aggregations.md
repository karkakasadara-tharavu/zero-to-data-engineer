# PySpark Aggregations and GroupBy - Complete Guide

## 📚 What You'll Learn
- GroupBy operations and syntax
- Built-in aggregation functions
- Multiple aggregations in one query
- Pivot tables
- Rollup and Cube for multi-level aggregations
- Interview preparation

**Duration**: 1.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Understanding Aggregations

### What is Aggregation?

Aggregation combines multiple rows into summary values. Common operations:
- **COUNT** - Number of rows
- **SUM** - Total of values
- **AVG** - Average value
- **MIN/MAX** - Extreme values
- **COLLECT_LIST/SET** - Aggregate into arrays

```
┌────────────────────────────────────────────────────────────────┐
│                      INPUT DATA                                 │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│ Department  │ Employee    │ Salary      │ Bonus               │
├─────────────┼─────────────┼─────────────┼─────────────────────┤
│ Engineering │ Alice       │ 100000      │ 10000               │
│ Engineering │ Bob         │ 95000       │ 8000                │
│ Sales       │ Charlie     │ 75000       │ 15000               │
│ Sales       │ Diana       │ 80000       │ 12000               │
│ Sales       │ Eve         │ 72000       │ 10000               │
└─────────────┴─────────────┴─────────────┴─────────────────────┘
                           │
                   groupBy("Department")
                           │
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                      OUTPUT DATA                                │
├─────────────┬─────────┬───────────┬───────────┬───────────────┤
│ Department  │ Count   │ Total_Sal │ Avg_Sal   │ Max_Bonus     │
├─────────────┼─────────┼───────────┼───────────┼───────────────┤
│ Engineering │ 2       │ 195000    │ 97500     │ 10000         │
│ Sales       │ 3       │ 227000    │ 75666.67  │ 15000         │
└─────────────┴─────────┴───────────┴───────────┴───────────────┘
```

---

## 📊 Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder.appName("Aggregations").getOrCreate()

# Create sample data
data = [
    ("Engineering", "Alice", 100000, 10000, "2022-01-15"),
    ("Engineering", "Bob", 95000, 8000, "2022-03-20"),
    ("Engineering", "Carol", 110000, 12000, "2021-06-10"),
    ("Sales", "Charlie", 75000, 15000, "2022-02-01"),
    ("Sales", "Diana", 80000, 12000, "2021-11-05"),
    ("Sales", "Eve", 72000, 10000, "2022-04-15"),
    ("HR", "Frank", 65000, 5000, "2022-01-20"),
    ("HR", "Grace", 68000, 6000, "2021-09-01"),
]

df = spark.createDataFrame(data, ["department", "name", "salary", "bonus", "hire_date"])
df.show()
```

---

## 🔧 Basic GroupBy Operations

### Simple GroupBy with Single Aggregation

```python
# Count employees per department
df.groupBy("department").count().show()

# Output:
# +-----------+-----+
# | department|count|
# +-----------+-----+
# |Engineering|    3|
# |      Sales|    3|
# |         HR|    2|
# +-----------+-----+
```

### GroupBy with Specific Aggregation

```python
# Sum of salaries per department
df.groupBy("department").sum("salary").show()

# Average salary per department
df.groupBy("department").avg("salary").show()

# Min/Max salary per department
df.groupBy("department").max("salary").show()
df.groupBy("department").min("salary").show()
```

---

## 📈 Using agg() for Multiple Aggregations

### Multiple Aggregations with Aliases

```python
from pyspark.sql.functions import sum, avg, count, max, min, round

df.groupBy("department").agg(
    count("*").alias("employee_count"),
    round(avg("salary"), 2).alias("avg_salary"),
    sum("salary").alias("total_salary"),
    max("salary").alias("max_salary"),
    min("salary").alias("min_salary"),
    sum("bonus").alias("total_bonus")
).show()

# Output:
# +-----------+--------------+----------+------------+----------+----------+-----------+
# | department|employee_count|avg_salary|total_salary|max_salary|min_salary|total_bonus|
# +-----------+--------------+----------+------------+----------+----------+-----------+
# |Engineering|             3|  101666.67|      305000|    110000|     95000|      30000|
# |      Sales|             3|   75666.67|      227000|     80000|     72000|      37000|
# |         HR|             2|   66500.00|      133000|     68000|     65000|      11000|
# +-----------+--------------+----------+------------+----------+----------+-----------+
```

### Aggregating Multiple Columns

```python
# Different aggregations on different columns
df.groupBy("department").agg(
    avg("salary").alias("avg_salary"),
    avg("bonus").alias("avg_bonus"),
    max("salary").alias("max_salary"),
    max("bonus").alias("max_bonus")
).show()
```

---

## 📚 Common Aggregation Functions

### Statistical Functions

```python
from pyspark.sql.functions import (
    count, countDistinct, approx_count_distinct,
    sum, sumDistinct,
    avg, mean,
    min, max,
    stddev, stddev_pop, stddev_samp,
    variance, var_pop, var_samp,
    skewness, kurtosis,
    first, last,
    collect_list, collect_set
)

df.groupBy("department").agg(
    countDistinct("name").alias("unique_employees"),
    stddev("salary").alias("salary_stddev"),
    variance("salary").alias("salary_variance"),
    skewness("salary").alias("salary_skewness"),
    first("name").alias("first_hired"),
    last("name").alias("last_hired"),
    collect_list("name").alias("all_employees"),
    collect_set("name").alias("unique_names")
).show(truncate=False)
```

### Conditional Aggregations

```python
# Count based on condition
df.groupBy("department").agg(
    count("*").alias("total"),
    count(when(col("salary") > 80000, 1)).alias("high_salary_count"),
    count(when(col("salary") <= 80000, 1)).alias("low_salary_count"),
    sum(when(col("salary") > 80000, col("salary")).otherwise(0)).alias("high_salary_total")
).show()
```

### Percentage Calculations

```python
# Calculate percentage within group
total_salary = df.agg(sum("salary")).first()[0]

df.groupBy("department").agg(
    sum("salary").alias("dept_salary")
).withColumn(
    "percentage",
    round(col("dept_salary") / total_salary * 100, 2)
).show()
```

---

## 🔄 Pivot Tables

### Basic Pivot

```python
# Sample data with year
sales_data = [
    ("Electronics", 2021, 100000),
    ("Electronics", 2022, 150000),
    ("Electronics", 2023, 180000),
    ("Clothing", 2021, 80000),
    ("Clothing", 2022, 95000),
    ("Clothing", 2023, 110000),
    ("Food", 2021, 200000),
    ("Food", 2022, 220000),
    ("Food", 2023, 250000),
]

sales_df = spark.createDataFrame(sales_data, ["category", "year", "revenue"])

# Pivot by year
sales_df.groupBy("category") \
    .pivot("year") \
    .sum("revenue") \
    .show()

# Output:
# +-----------+------+------+------+
# |   category|  2021|  2022|  2023|
# +-----------+------+------+------+
# |Electronics|100000|150000|180000|
# |   Clothing| 80000| 95000|110000|
# |       Food|200000|220000|250000|
# +-----------+------+------+------+
```

### Pivot with Specific Values

```python
# Only pivot on specific values (more efficient)
sales_df.groupBy("category") \
    .pivot("year", [2022, 2023]) \
    .sum("revenue") \
    .show()
```

### Multiple Aggregations in Pivot

```python
sales_df.groupBy("category") \
    .pivot("year") \
    .agg(
        sum("revenue").alias("total"),
        avg("revenue").alias("avg")
    ).show()
```

---

## 📊 Rollup and Cube

### Rollup (Hierarchical Subtotals)

```python
# Rollup creates subtotals for hierarchy
df.rollup("department", "name").agg(
    sum("salary").alias("total_salary"),
    count("*").alias("count")
).orderBy("department", "name").show()

# Output includes:
# - Grand total (NULL, NULL)
# - Department subtotals (department, NULL)
# - Individual rows (department, name)
```

### Cube (All Combinations)

```python
# Cube creates subtotals for all combinations
df.cube("department", "name").agg(
    sum("salary").alias("total_salary"),
    count("*").alias("count")
).orderBy("department", "name").show()

# Output includes:
# - Grand total (NULL, NULL)
# - By department (department, NULL)
# - By name (NULL, name)
# - Individual rows (department, name)
```

### Using grouping_id()

```python
# Identify aggregation level
df.cube("department", "name").agg(
    sum("salary").alias("total_salary"),
    grouping_id("department", "name").alias("level")
).show()

# level values:
# 0 = grouped by both
# 1 = grouped by department only
# 2 = grouped by name only
# 3 = grand total
```

---

## 🔀 Group By Multiple Columns

```python
# Extended data with region
extended_data = [
    ("Engineering", "West", "Alice", 100000),
    ("Engineering", "West", "Bob", 95000),
    ("Engineering", "East", "Carol", 110000),
    ("Sales", "West", "Charlie", 75000),
    ("Sales", "East", "Diana", 80000),
    ("Sales", "East", "Eve", 72000),
]

ext_df = spark.createDataFrame(extended_data, 
    ["department", "region", "name", "salary"])

# Group by multiple columns
ext_df.groupBy("department", "region").agg(
    count("*").alias("count"),
    avg("salary").alias("avg_salary")
).orderBy("department", "region").show()

# Output:
# +-----------+------+-----+----------+
# | department|region|count|avg_salary|
# +-----------+------+-----+----------+
# |Engineering|  East|    1|  110000.0|
# |Engineering|  West|    2|   97500.0|
# |      Sales|  East|    2|   76000.0|
# |      Sales|  West|    1|   75000.0|
# +-----------+------+-----+----------+
```

---

## 🎯 Window Functions vs GroupBy

### When to Use GroupBy
- Need to reduce rows (one output per group)
- Computing summary statistics
- Don't need original row data

### When to Use Window Functions
- Need to keep all rows
- Need to compare row to group aggregate
- Need running totals, rankings

```python
from pyspark.sql.window import Window

# GroupBy: One row per department
df.groupBy("department").agg(avg("salary").alias("avg_salary")).show()

# Window: Keep all rows, add group aggregate
window = Window.partitionBy("department")
df.withColumn("dept_avg", avg("salary").over(window)).show()
```

---

## 💡 Performance Tips

### 1. Filter Before Aggregating

```python
# ❌ Bad: Aggregate then filter
df.groupBy("department").agg(sum("salary").alias("total")).filter(col("total") > 100000)

# ✅ Good: Filter before aggregating when possible
df.filter(col("salary") > 50000).groupBy("department").agg(sum("salary"))
```

### 2. Use approx_count_distinct for Large Data

```python
# Exact count (slow for large data)
df.groupBy("department").agg(countDistinct("customer_id"))

# Approximate count (faster, ~2% error)
df.groupBy("department").agg(approx_count_distinct("customer_id"))
```

### 3. Specify Pivot Values

```python
# ❌ Bad: Spark scans data to find values
df.groupBy("category").pivot("year").sum("revenue")

# ✅ Good: Provide values explicitly
df.groupBy("category").pivot("year", [2021, 2022, 2023]).sum("revenue")
```

### 4. Cache Frequently Used Aggregations

```python
summary = df.groupBy("department").agg(
    sum("salary"), avg("salary"), count("*")
).cache()

# Use multiple times
summary.show()
summary.write.parquet("summary")
```

---

## 🎓 Interview Questions

### Q1: What is the difference between `groupBy()` and `partitionBy()` in Window functions?
**A:**
- **groupBy()**: Reduces rows, returns one row per group, used for aggregation
- **partitionBy()**: In window functions, keeps all rows, partitions data for window calculations

### Q2: How do you perform multiple aggregations in one query?
**A:** Use `agg()` with multiple aggregation expressions:
```python
df.groupBy("dept").agg(
    sum("salary").alias("total"),
    avg("salary").alias("average"),
    count("*").alias("count")
)
```

### Q3: What is the difference between `rollup()` and `cube()`?
**A:**
- **rollup()**: Hierarchical subtotals - creates aggregates at each level of the hierarchy from right to left
- **cube()**: All possible combinations - creates aggregates for all possible groupings

### Q4: How do you count distinct values in PySpark?
**A:**
```python
# Exact count
df.groupBy("dept").agg(countDistinct("customer_id"))

# Approximate (faster for large data)
df.groupBy("dept").agg(approx_count_distinct("customer_id"))
```

### Q5: What is a pivot table and how do you create one?
**A:** Pivot transforms unique values from one column into multiple columns:
```python
df.groupBy("category").pivot("year", [2021, 2022, 2023]).sum("revenue")
# Transforms year values (2021, 2022, 2023) into columns
```

### Q6: How do you handle NULL values in aggregations?
**A:**
- Most aggregation functions ignore NULLs (sum, avg, count column)
- `count("*")` counts all rows including NULLs
- Use `coalesce()` or `fillna()` to replace NULLs before aggregation
- `count(col)` counts non-NULL values

### Q7: How do you calculate running totals in PySpark?
**A:** Use window functions with unbounded preceding:
```python
window = Window.partitionBy("dept").orderBy("date").rowsBetween(Window.unboundedPreceding, 0)
df.withColumn("running_total", sum("amount").over(window))
```

### Q8: How do you find the top N records per group?
**A:** Use window function with row_number and filter:
```python
window = Window.partitionBy("department").orderBy(desc("salary"))
df.withColumn("rank", row_number().over(window)) \
  .filter(col("rank") <= 3)
```

### Q9: What is `collect_list()` vs `collect_set()`?
**A:**
- `collect_list()`: Collects all values into array (includes duplicates)
- `collect_set()`: Collects unique values into array (no duplicates)

### Q10: How do you optimize groupBy operations?
**A:**
1. **Filter before grouping** - reduce data volume
2. **Use appropriate partition size** - avoid too many/few partitions
3. **Specify pivot values** - avoid extra scan
4. **Use approximate functions** - for large data
5. **Consider broadcast joins** - if joining after grouping
6. **Cache intermediate results** - if reused

---

## 🔗 Related Topics
- [← Transformations and Actions](./03_transformations_actions.md)
- [Window Functions →](./05_window_functions.md)
- [Joins →](./06_joins.md)

---

*Next: Learn about Window Functions in PySpark*
