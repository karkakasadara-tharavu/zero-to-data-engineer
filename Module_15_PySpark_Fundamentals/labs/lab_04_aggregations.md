# Lab 04: Aggregations and Grouping

## Overview
Master data aggregation techniques for summarizing and analyzing large datasets.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Perform groupBy operations
- ✅ Use built-in aggregation functions
- ✅ Create pivot tables
- ✅ Apply multiple aggregations simultaneously
- ✅ Use rollup and cube for subtotals

---

## Part 1: Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Aggregations") \
    .master("local[*]") \
    .getOrCreate()

# Sales data
data = [
    (1, "Electronics", "Laptop", 999.99, 2, "2024-01-15", "North"),
    (2, "Electronics", "Phone", 599.99, 5, "2024-01-16", "South"),
    (3, "Clothing", "Shirt", 29.99, 10, "2024-01-17", "North"),
    (4, "Electronics", "Tablet", 399.99, 3, "2024-01-18", "East"),
    (5, "Clothing", "Pants", 49.99, 8, "2024-01-19", "West"),
    (6, "Electronics", "Laptop", 999.99, 1, "2024-01-20", "South"),
    (7, "Clothing", "Shirt", 29.99, 15, "2024-01-21", "East"),
    (8, "Electronics", "Phone", 599.99, 4, "2024-01-22", "North"),
    (9, "Furniture", "Chair", 199.99, 6, "2024-01-23", "West"),
    (10, "Furniture", "Table", 349.99, 2, "2024-01-24", "South")
]

schema = StructType([
    StructField("order_id", IntegerType(), False),
    StructField("category", StringType(), False),
    StructField("product", StringType(), False),
    StructField("price", DoubleType(), False),
    StructField("quantity", IntegerType(), False),
    StructField("order_date", StringType(), False),
    StructField("region", StringType(), False)
])

sales = spark.createDataFrame(data, schema)
sales = sales.withColumn("total", sales.price * sales.quantity)
sales.show()
```

---

## Part 2: Basic Aggregations

### Step 2.1: Simple Aggregation Functions
```python
from pyspark.sql.functions import (
    count, sum, avg, min, max, 
    countDistinct, stddev, variance
)

# Aggregate entire DataFrame
sales.select(
    count("*").alias("total_orders"),
    sum("total").alias("total_revenue"),
    avg("total").alias("avg_order_value"),
    min("total").alias("min_order"),
    max("total").alias("max_order")
).show()

# Count distinct
sales.select(
    countDistinct("category").alias("unique_categories"),
    countDistinct("product").alias("unique_products")
).show()
```

### Step 2.2: Using agg()
```python
from pyspark.sql.functions import sum, avg, count, round

# Multiple aggregations with agg
sales.agg(
    count("order_id").alias("order_count"),
    sum("quantity").alias("total_items"),
    round(avg("price"), 2).alias("avg_price"),
    sum("total").alias("revenue")
).show()
```

---

## Part 3: GroupBy Operations

### Step 3.1: Single Column GroupBy
```python
from pyspark.sql.functions import sum, avg, count, round

# Group by category
sales.groupBy("category") \
    .agg(
        count("*").alias("order_count"),
        sum("quantity").alias("items_sold"),
        round(sum("total"), 2).alias("total_revenue"),
        round(avg("total"), 2).alias("avg_order")
    ) \
    .orderBy("total_revenue", ascending=False) \
    .show()
```

**Output:**
```
+-----------+-----------+----------+-------------+---------+
|   category|order_count|items_sold|total_revenue|avg_order|
+-----------+-----------+----------+-------------+---------+
|Electronics|          6|        15|      7199.87|  1199.98|
|   Clothing|          3|        33|       899.67|   299.89|
|  Furniture|          2|         8|      1899.92|   949.96|
+-----------+-----------+----------+-------------+---------+
```

### Step 3.2: Multiple Column GroupBy
```python
# Group by category and region
sales.groupBy("category", "region") \
    .agg(
        count("*").alias("orders"),
        sum("total").alias("revenue")
    ) \
    .orderBy("category", "revenue", ascending=[True, False]) \
    .show()
```

### Step 3.3: Shorthand Aggregations
```python
# Quick aggregation methods
sales.groupBy("category").count().show()
sales.groupBy("category").sum("total").show()
sales.groupBy("category").avg("price").show()
sales.groupBy("category").max("quantity").show()
```

---

## Part 4: Advanced Aggregation Functions

### Step 4.1: Statistical Functions
```python
from pyspark.sql.functions import (
    stddev, stddev_pop, variance, var_pop,
    skewness, kurtosis, collect_list, collect_set
)

# Statistical aggregations
sales.groupBy("category") \
    .agg(
        round(avg("total"), 2).alias("mean"),
        round(stddev("total"), 2).alias("std_dev"),
        round(variance("total"), 2).alias("variance")
    ).show()
```

### Step 4.2: Collect Functions
```python
from pyspark.sql.functions import collect_list, collect_set, array_distinct

# Collect products per category
sales.groupBy("category") \
    .agg(
        collect_list("product").alias("all_products"),
        collect_set("product").alias("unique_products")
    ).show(truncate=False)
```

**Output:**
```
+-----------+------------------------------------+--------------------+
|category   |all_products                        |unique_products     |
+-----------+------------------------------------+--------------------+
|Electronics|[Laptop, Phone, Tablet, Laptop, ...]|[Laptop, Phone, ...]|
|Clothing   |[Shirt, Pants, Shirt]               |[Shirt, Pants]      |
|Furniture  |[Chair, Table]                      |[Chair, Table]      |
+-----------+------------------------------------+--------------------+
```

### Step 4.3: First and Last
```python
from pyspark.sql.functions import first, last

# Get first and last values per group
sales.orderBy("order_date") \
    .groupBy("category") \
    .agg(
        first("order_date").alias("first_order"),
        last("order_date").alias("last_order"),
        first("product").alias("first_product")
    ).show()
```

---

## Part 5: Pivot Tables

### Step 5.1: Basic Pivot
```python
# Pivot regions as columns
pivot_df = sales.groupBy("category") \
    .pivot("region") \
    .sum("total")

pivot_df.show()
```

**Output:**
```
+-----------+------+-------+-------+------+
|   category|  East|  North|  South|  West|
+-----------+------+-------+-------+------+
|Electronics| 1199.97|4399.95|3599.97|  null|
|   Clothing|  449.85| 299.90|   null|399.92|
|  Furniture|   null|   null| 699.98|1199.94|
+-----------+------+-------+-------+------+
```

### Step 5.2: Pivot with Specified Values
```python
# Pivot with explicit column list (more efficient)
regions = ["North", "South", "East", "West"]

pivot_df = sales.groupBy("category") \
    .pivot("region", regions) \
    .agg(
        sum("total").alias("revenue"),
        count("*").alias("orders")
    )

pivot_df.show()
```

### Step 5.3: Fill Null Values
```python
# Fill nulls in pivot table
pivot_df = sales.groupBy("category") \
    .pivot("region") \
    .sum("total") \
    .fillna(0)

pivot_df.show()
```

---

## Part 6: Rollup and Cube

### Step 6.1: Rollup (Hierarchical Subtotals)
```python
from pyspark.sql.functions import sum, count, grouping

# Rollup creates subtotals for hierarchy
rollup_df = sales.rollup("category", "region") \
    .agg(
        sum("total").alias("revenue"),
        count("*").alias("orders")
    ) \
    .orderBy("category", "region")

rollup_df.show()
```

**Output:**
```
+-----------+------+--------+------+
|   category|region| revenue|orders|
+-----------+------+--------+------+
|       null|  null| 9999.46|    10|  <- Grand total
|   Clothing|  null|  899.67|     3|  <- Category subtotal
|   Clothing|  East|  449.85|     1|
|   Clothing| North|  299.90|     1|
|   Clothing|  West|  399.92|     1|
|Electronics|  null| 7199.87|     6|  <- Category subtotal
...
+-----------+------+--------+------+
```

### Step 6.2: Cube (All Combinations)
```python
# Cube creates subtotals for all combinations
cube_df = sales.cube("category", "region") \
    .agg(
        sum("total").alias("revenue")
    ) \
    .orderBy("category", "region")

cube_df.show(20)
```

### Step 6.3: Identifying Grouping Levels
```python
from pyspark.sql.functions import grouping, grouping_id

# Use grouping to identify subtotal rows
rollup_df = sales.rollup("category", "region") \
    .agg(
        sum("total").alias("revenue"),
        grouping("category").alias("cat_grouping"),
        grouping("region").alias("reg_grouping"),
        grouping_id("category", "region").alias("grouping_id")
    )

rollup_df.show()
```

---

## Part 7: Window-Like Aggregations

### Step 7.1: Aggregation with Original Data
```python
from pyspark.sql.functions import sum, avg, col

# Add aggregated values to original rows
category_totals = sales.groupBy("category") \
    .agg(sum("total").alias("category_total"))

# Join back to get totals with original data
sales_with_totals = sales.join(category_totals, on="category")

# Calculate percentage
result = sales_with_totals.withColumn(
    "pct_of_category",
    (col("total") / col("category_total") * 100).cast("decimal(5,2)")
)

result.select(
    "category", "product", "total", 
    "category_total", "pct_of_category"
).show()
```

---

## Part 8: Complete Aggregation Pipeline

```python
from pyspark.sql.functions import (
    sum, avg, count, round, max, min,
    collect_set, when, col
)

# Comprehensive sales analysis
analysis = sales \
    .groupBy("category") \
    .agg(
        count("*").alias("order_count"),
        sum("quantity").alias("units_sold"),
        round(sum("total"), 2).alias("revenue"),
        round(avg("total"), 2).alias("avg_order_value"),
        round(min("total"), 2).alias("min_order"),
        round(max("total"), 2).alias("max_order"),
        collect_set("region").alias("regions_sold")
    ) \
    .withColumn("revenue_tier",
        when(col("revenue") > 5000, "High")
        .when(col("revenue") > 1000, "Medium")
        .otherwise("Low")
    ) \
    .orderBy(col("revenue").desc())

analysis.show(truncate=False)
```

---

## Exercises

1. Calculate average order value per region
2. Create a pivot table of product sales by month
3. Use rollup to get quarterly totals by category
4. Find the top-selling product in each category

---

## Summary
- `groupBy().agg()` for flexible aggregations
- `pivot()` for cross-tabulation
- `rollup()` and `cube()` for subtotals
- Use `collect_list/set` for array aggregations
- Chain operations for complex analysis
