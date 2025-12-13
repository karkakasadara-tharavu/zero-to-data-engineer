# Lab 02: Advanced Joins and Optimization

## Overview
Master advanced join techniques and optimization strategies for complex data relationships.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Understand join strategies (broadcast, sort-merge, shuffle-hash)
- ✅ Implement broadcast hash joins
- ✅ Handle skewed joins
- ✅ Optimize multi-table joins
- ✅ Use join hints

---

## Part 1: Join Strategies Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Spark Join Strategies                                                   │
├─────────────────────────────────────────────────────────────────────────┤
│ 1. Broadcast Hash Join (BHJ)                                            │
│    - Small table broadcast to all executors                             │
│    - No shuffle, very fast                                              │
│    - Table must fit in memory                                           │
│                                                                          │
│ 2. Sort Merge Join (SMJ)                                                │
│    - Both tables shuffled and sorted by join key                        │
│    - Scalable, handles large tables                                     │
│    - More expensive (shuffle + sort)                                    │
│                                                                          │
│ 3. Shuffle Hash Join (SHJ)                                              │
│    - Both tables shuffled by join key                                   │
│    - No sort, builds hash table                                         │
│    - Less common, good for specific cases                               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Setup Sample Data

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, rand, lit

spark = SparkSession.builder \
    .appName("Advanced Joins") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "8") \
    .getOrCreate()

# Large fact table (1 million rows)
fact_data = [(i, i % 1000, i * 10.5) for i in range(1000000)]
fact_df = spark.createDataFrame(fact_data, ["id", "dim_key", "amount"])

# Small dimension table (1000 rows)
dim_data = [(i, f"category_{i}", f"region_{i % 10}") for i in range(1000)]
dim_df = spark.createDataFrame(dim_data, ["dim_key", "category", "region"])

# Medium table (100000 rows)
medium_data = [(i, i % 1000, f"value_{i}") for i in range(100000)]
medium_df = spark.createDataFrame(medium_data, ["id", "dim_key", "value"])

print(f"Fact table: {fact_df.count()} rows")
print(f"Dim table: {dim_df.count()} rows")
print(f"Medium table: {medium_df.count()} rows")
```

---

## Part 3: Broadcast Hash Join

### Step 3.1: Auto Broadcast
```python
# Check auto broadcast threshold
print(spark.conf.get("spark.sql.autoBroadcastJoinThreshold"))
# Default: 10485760 (10MB)

# Increase threshold
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "50MB")

# Join - Spark will auto-broadcast dim_df if small enough
result = fact_df.join(dim_df, "dim_key")
result.explain()  # Check for BroadcastHashJoin
```

### Step 3.2: Explicit Broadcast
```python
from pyspark.sql.functions import broadcast

# Force broadcast regardless of threshold
result = fact_df.join(broadcast(dim_df), "dim_key")
result.explain()

# Shows:
# BroadcastHashJoin [dim_key#1], [dim_key#10], Inner, BuildRight
```

### Step 3.3: Broadcast Variables
```python
# For non-DataFrame data (e.g., lookup dictionaries)
lookup_dict = {i: f"category_{i}" for i in range(1000)}
broadcast_lookup = spark.sparkContext.broadcast(lookup_dict)

# Use in UDF
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType

@udf(StringType())
def lookup_category(key):
    return broadcast_lookup.value.get(key, "Unknown")

result = fact_df.withColumn("category", lookup_category(col("dim_key")))
```

---

## Part 4: Sort Merge Join

```python
# Disable broadcast to force Sort Merge Join
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")

# Join two large tables
result = fact_df.join(medium_df, "id")
result.explain()

# Shows:
# SortMergeJoin [id#0], [id#20], Inner

# Re-enable broadcast
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "10MB")
```

### Optimize Sort Merge Join
```python
# Pre-partition data for repeated joins
fact_partitioned = fact_df.repartition(8, "dim_key")
medium_partitioned = medium_df.repartition(8, "dim_key")

# Cache if reused
fact_partitioned.cache()
medium_partitioned.cache()

# Joins will be faster as data is co-partitioned
result = fact_partitioned.join(medium_partitioned, "dim_key")
```

---

## Part 5: Join Hints (Spark 3.0+)

### Step 5.1: Available Hints
```python
# BROADCAST hint
result = fact_df.hint("broadcast").join(dim_df, "dim_key")

# MERGE hint (force sort-merge join)
result = fact_df.hint("merge").join(medium_df, "id")

# SHUFFLE_HASH hint
result = fact_df.hint("shuffle_hash").join(medium_df, "id")

# SHUFFLE_REPLICATE_NL hint (for small tables)
result = fact_df.hint("shuffle_replicate_nl").join(dim_df, "dim_key")
```

### Step 5.2: SQL Hints
```python
fact_df.createOrReplaceTempView("fact_table")
dim_df.createOrReplaceTempView("dim_table")

# Using SQL hints
result = spark.sql("""
    SELECT /*+ BROADCAST(d) */ f.*, d.category, d.region
    FROM fact_table f
    JOIN dim_table d ON f.dim_key = d.dim_key
""")

result.explain()
```

---

## Part 6: Handling Skewed Joins

### Step 6.1: Detect Skew
```python
# Check key distribution
fact_df.groupBy("dim_key").count() \
    .orderBy(col("count").desc()) \
    .show(20)

# Visualize distribution
import matplotlib.pyplot as plt

counts = fact_df.groupBy("dim_key").count().toPandas()
plt.hist(counts['count'], bins=50)
plt.title("Key Distribution")
plt.xlabel("Count")
plt.ylabel("Frequency")
plt.show()
```

### Step 6.2: Create Skewed Data
```python
from pyspark.sql.functions import when, lit

# Create skewed fact table (80% of data has dim_key = 0)
skewed_fact = spark.range(0, 1000000).withColumn(
    "dim_key",
    when(rand() < 0.8, lit(0)).otherwise((rand() * 100).cast("int"))
).withColumn("amount", rand() * 1000)

# Check skew
skewed_fact.groupBy("dim_key").count() \
    .orderBy(col("count").desc()) \
    .show(10)
```

### Step 6.3: Salting for Skewed Joins
```python
from pyspark.sql.functions import concat, lit, floor, rand, explode, array

num_salts = 10

# Salt the fact table (add random suffix to skewed key)
salted_fact = skewed_fact.withColumn(
    "salted_key",
    concat(col("dim_key").cast("string"), lit("_"), (rand() * num_salts).cast("int").cast("string"))
)

# Replicate dimension table with all salt values
dim_with_salt = dim_df.select(
    explode(array([lit(i) for i in range(num_salts)])).alias("salt"),
    col("dim_key"),
    col("category"),
    col("region")
).withColumn(
    "salted_key",
    concat(col("dim_key").cast("string"), lit("_"), col("salt").cast("string"))
).drop("salt")

# Join on salted key
result = salted_fact.join(broadcast(dim_with_salt), "salted_key")
result.show()
```

### Step 6.4: AQE Skew Handling (Spark 3.0+)
```python
# Enable adaptive skew join handling
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.skewedPartitionFactor", "5")
spark.conf.set("spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes", "256MB")
```

---

## Part 7: Multi-Table Joins

### Step 7.1: Chain Joins
```python
# Third dimension table
dim2_data = [(i % 10, f"region_name_{i}", f"country_{i // 3}") for i in range(10)]
dim2_df = spark.createDataFrame(dim2_data, ["region_id", "region_name", "country"])

# Join multiple tables
result = fact_df \
    .join(broadcast(dim_df), "dim_key") \
    .join(broadcast(dim2_df), dim_df.region == dim2_df.region_id)

result.explain()
```

### Step 7.2: Star Schema Optimization
```python
# Enable star schema optimization
spark.conf.set("spark.sql.cbo.enabled", "true")
spark.conf.set("spark.sql.cbo.starSchemaDetection", "true")

# Compute table statistics for CBO
fact_df.createOrReplaceTempView("fact")
dim_df.createOrReplaceTempView("dim")

spark.sql("ANALYZE TABLE fact COMPUTE STATISTICS")
spark.sql("ANALYZE TABLE dim COMPUTE STATISTICS FOR COLUMNS dim_key, category")
```

### Step 7.3: Optimal Join Order
```python
# Spark CBO can reorder joins automatically
# But you can also control manually

# BAD: Large x Large first, then filter
bad_result = fact_df.join(medium_df, "id").filter("amount > 5000")

# GOOD: Filter first, then join
good_result = fact_df.filter("amount > 5000").join(medium_df, "id")
```

---

## Part 8: Self Joins

```python
from pyspark.sql.functions import col

# Employee hierarchy
employees = spark.createDataFrame([
    (1, "Alice", None),
    (2, "Bob", 1),
    (3, "Charlie", 1),
    (4, "Diana", 2),
    (5, "Eve", 2),
], ["id", "name", "manager_id"])

# Self join to get manager names
emp_with_manager = employees.alias("e").join(
    employees.alias("m"),
    col("e.manager_id") == col("m.id"),
    "left"
).select(
    col("e.id"),
    col("e.name"),
    col("m.name").alias("manager_name")
)

emp_with_manager.show()
```

---

## Part 9: Non-Equi Joins

```python
# Range-based joins
price_ranges = spark.createDataFrame([
    (0, 100, "Budget"),
    (100, 500, "Mid-Range"),
    (500, 1000, "Premium"),
    (1000, 10000, "Luxury"),
], ["min_price", "max_price", "category"])

products = spark.createDataFrame([
    (1, "Widget", 50),
    (2, "Gadget", 250),
    (3, "Device", 750),
    (4, "Machine", 2500),
], ["id", "name", "price"])

# Range join (non-equi)
result = products.join(
    price_ranges,
    (products.price >= price_ranges.min_price) & 
    (products.price < price_ranges.max_price)
)

result.show()

# Note: Non-equi joins use nested loop, can be slow
# Consider bucketing for large datasets
```

---

## Part 10: Join Performance Comparison

```python
import time

def measure_join(df1, df2, join_type, key):
    start = time.time()
    result = df1.join(df2, key)
    result.count()  # Force execution
    elapsed = time.time() - start
    return elapsed

# Compare broadcast vs shuffle
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "50MB")
broadcast_time = measure_join(fact_df, dim_df, "inner", "dim_key")

spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")
shuffle_time = measure_join(fact_df, dim_df, "inner", "dim_key")

print(f"Broadcast Join: {broadcast_time:.2f}s")
print(f"Shuffle Join: {shuffle_time:.2f}s")
print(f"Speedup: {shuffle_time/broadcast_time:.1f}x")
```

---

## Exercises

1. Implement a star schema with 4 dimension tables
2. Optimize a skewed join using salting
3. Compare performance of different join hints
4. Implement a self-join for hierarchical data

---

## Summary
- Broadcast joins are fastest for small tables
- Sort-merge joins scale for large tables
- Use hints to control join strategy
- Handle skew with salting or AQE
- Filter before joining when possible
- Pre-partition data for repeated joins
- Use CBO for automatic optimization
