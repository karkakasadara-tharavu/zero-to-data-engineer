# Lab 01: Performance Optimization

## Overview
Master PySpark performance tuning for efficient large-scale data processing.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Understand Spark execution model
- ✅ Optimize partitioning strategies
- ✅ Use caching and persistence effectively
- ✅ Tune shuffle operations
- ✅ Monitor and diagnose performance issues

---

## Part 1: Understanding Spark Execution

### Step 1.1: Jobs, Stages, and Tasks
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Performance Optimization") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "8") \
    .getOrCreate()

# Generate sample data
data = [(i, f"name_{i}", i * 100, i % 10) for i in range(100000)]
df = spark.createDataFrame(data, ["id", "name", "value", "category"])

# This creates 1 job with 2 stages
result = df.groupBy("category").sum("value")
result.show()

# View in Spark UI: http://localhost:4040
```

### Step 1.2: Execution Plan Analysis
```python
# Logical and Physical Plan
df.explain()

# Extended explain (more details)
df.explain(True)

# Formatted explain (Spark 3.0+)
df.explain("formatted")

# Check optimized plan
result = df.filter("value > 5000").groupBy("category").count()
result.explain("extended")
```

---

## Part 2: Partitioning Strategies

### Step 2.1: Check Current Partitions
```python
# Number of partitions
print(f"Number of partitions: {df.rdd.getNumPartitions()}")

# Partition sizes (approximate)
def count_partitions(df):
    return df.rdd.mapPartitionsWithIndex(
        lambda idx, it: [(idx, sum(1 for _ in it))]
    ).collect()

partition_counts = count_partitions(df)
for idx, count in partition_counts:
    print(f"Partition {idx}: {count} rows")
```

### Step 2.2: Repartitioning
```python
# Repartition - full shuffle
df_repartitioned = df.repartition(10)
print(f"After repartition: {df_repartitioned.rdd.getNumPartitions()}")

# Repartition by column (for join/groupBy optimization)
df_by_category = df.repartition(10, "category")

# Coalesce - reduce partitions without shuffle
df_coalesced = df.coalesce(2)
print(f"After coalesce: {df_coalesced.rdd.getNumPartitions()}")
```

### Step 2.3: Partition Strategy Selection
```
┌─────────────────────────────────────────────────────────────┐
│ Use repartition() when:                                     │
│ - Need to increase partitions                               │
│ - Need to redistribute data evenly                          │
│ - Pre-shuffle before join/groupBy                           │
│                                                              │
│ Use coalesce() when:                                         │
│ - Need to reduce partitions                                  │
│ - After filter that reduces data size significantly          │
│ - Writing to fewer output files                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 3: Shuffle Optimization

### Step 3.1: Configure Shuffle Partitions
```python
# Default is 200 - often too many for small data
spark.conf.set("spark.sql.shuffle.partitions", "8")

# For larger datasets, use more partitions
# Rule of thumb: 2-4 partitions per CPU core
# Each partition should be 100-200 MB
```

### Step 3.2: Reduce Shuffle Data
```python
# BAD: Full shuffle then filter
result_bad = df.join(df2, "key").filter("value > 100")

# GOOD: Filter before shuffle
result_good = df.filter("value > 100").join(df2, "key")

# Use broadcast for small tables
from pyspark.sql.functions import broadcast

small_df = spark.createDataFrame([(i, f"cat_{i}") for i in range(10)], ["category", "cat_name"])
result = df.join(broadcast(small_df), "category")
```

### Step 3.3: Avoid Multiple Shuffles
```python
from pyspark.sql.functions import col

# BAD: Multiple shuffles
result = df \
    .groupBy("category").sum("value") \
    .orderBy("sum(value)") \
    .withColumn("rank", row_number().over(Window.orderBy("sum(value)")))

# BETTER: Combine operations
from pyspark.sql.window import Window
from pyspark.sql.functions import sum, row_number

window_spec = Window.orderBy(col("total").desc())
result = df \
    .groupBy("category") \
    .agg(sum("value").alias("total")) \
    .withColumn("rank", row_number().over(window_spec))
```

---

## Part 4: Caching and Persistence

### Step 4.1: When to Cache
```python
# Cache when DataFrame is reused multiple times
df_filtered = df.filter("value > 1000")

# Used multiple times
count = df_filtered.count()
avg = df_filtered.agg({"value": "avg"}).collect()
grouped = df_filtered.groupBy("category").count()

# Solution: Cache it
df_filtered.cache()  # or df_filtered.persist()

# Now operations are faster
count = df_filtered.count()  # Materializes cache
avg = df_filtered.agg({"value": "avg"}).collect()  # Uses cache
grouped = df_filtered.groupBy("category").count()  # Uses cache
```

### Step 4.2: Storage Levels
```python
from pyspark import StorageLevel

# Memory only (default for cache())
df.persist(StorageLevel.MEMORY_ONLY)

# Memory and disk
df.persist(StorageLevel.MEMORY_AND_DISK)

# Memory serialized (less memory, more CPU)
df.persist(StorageLevel.MEMORY_ONLY_SER)

# Disk only
df.persist(StorageLevel.DISK_ONLY)

# With replication
df.persist(StorageLevel.MEMORY_AND_DISK_2)
```

### Step 4.3: Unpersist When Done
```python
# Free up memory
df_filtered.unpersist()

# Check if cached
print(df_filtered.is_cached)
```

---

## Part 5: Adaptive Query Execution (AQE)

```python
# Enable AQE (default in Spark 3.2+)
spark.conf.set("spark.sql.adaptive.enabled", "true")

# Coalesce shuffle partitions automatically
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")

# Convert sort-merge join to broadcast join
spark.conf.set("spark.sql.adaptive.autoBroadcastJoinThreshold", "10MB")

# Handle skewed joins
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
```

---

## Part 6: Broadcast Joins

### Step 6.1: Auto Broadcast
```python
# Default broadcast threshold
print(spark.conf.get("spark.sql.autoBroadcastJoinThreshold"))
# 10485760 (10MB)

# Increase for larger dimension tables
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "50MB")
```

### Step 6.2: Explicit Broadcast
```python
from pyspark.sql.functions import broadcast

# Force broadcast of dimension table
large_fact = df
small_dim = spark.createDataFrame([(i, f"cat_{i}") for i in range(10)], ["category", "name"])

result = large_fact.join(broadcast(small_dim), "category")
result.explain()  # Shows BroadcastHashJoin
```

---

## Part 7: Handling Data Skew

### Step 7.1: Detect Skew
```python
# Check data distribution
df.groupBy("category").count().orderBy("count", ascending=False).show()

# Check partition sizes
df.rdd.glom().map(len).collect()
```

### Step 7.2: Salt Keys for Skewed Joins
```python
from pyspark.sql.functions import lit, concat, col, floor, rand

# Number of salt buckets
num_salts = 10

# Salt the skewed key
df_salted = df.withColumn(
    "salted_key",
    concat(col("category"), lit("_"), (rand() * num_salts).cast("int"))
)

# Explode dimension table with salt
from pyspark.sql.functions import explode, array

dim_salted = small_dim.withColumn(
    "salt", explode(array([lit(i) for i in range(num_salts)]))
).withColumn(
    "salted_key",
    concat(col("category"), lit("_"), col("salt"))
)

# Join on salted key
result = df_salted.join(dim_salted, "salted_key")
```

---

## Part 8: Memory Tuning

### Step 8.1: Key Memory Configurations
```python
# Driver memory (for collect, take operations)
# --driver-memory 4g

# Executor memory (for processing)
# --executor-memory 8g

# Memory fraction for storage vs execution
spark.conf.set("spark.memory.fraction", "0.6")
spark.conf.set("spark.memory.storageFraction", "0.5")
```

### Step 8.2: Avoid Memory Issues
```python
# BAD: Collect large data to driver
all_data = df.collect()  # Can cause OOM

# GOOD: Process in Spark, collect only results
result = df.groupBy("category").count()
small_result = result.collect()  # Much smaller

# Use toPandas() carefully
pandas_df = df.limit(1000).toPandas()  # OK
# pandas_df = df.toPandas()  # Dangerous for large data
```

---

## Part 9: Predicate and Projection Pushdown

```python
# Spark automatically pushes filters and selects to data source

# Reading Parquet with filter - only reads needed partitions
df = spark.read.parquet("data/partitioned/") \
    .filter("date = '2024-01-15'") \
    .select("id", "value")

# Check pushdown in explain
df.explain()
# Should show: PushedFilters: [IsNotNull(date), EqualTo(date,2024-01-15)]
```

---

## Part 10: Performance Monitoring

### Step 10.1: Spark UI
```
Access: http://localhost:4040

Key tabs:
- Jobs: Overall progress
- Stages: Shuffle details, task times
- Storage: Cached data
- Executors: Memory usage, GC time
- SQL: Query plans
```

### Step 10.2: Metrics Collection
```python
# Accumulator for custom metrics
counter = spark.sparkContext.accumulator(0)

def count_records(row):
    counter.add(1)
    return row

df.rdd.foreach(count_records)
print(f"Processed records: {counter.value}")
```

### Step 10.3: Query Execution Metrics
```python
# Enable query plan visualization
spark.conf.set("spark.sql.planChangeLog.level", "WARN")

# Get query execution time
from time import time

start = time()
result = df.groupBy("category").count().collect()
print(f"Execution time: {time() - start:.2f}s")
```

---

## Part 11: Optimization Checklist

| Issue | Solution |
|-------|----------|
| Slow joins | Use broadcast, handle skew |
| Too many partitions | Reduce shuffle partitions |
| Too few partitions | Repartition before processing |
| Repeated computation | Cache intermediate results |
| Large shuffles | Filter early, use narrow transforms |
| OOM on driver | Avoid collect on large data |
| OOM on executors | Increase memory, reduce partition size |

---

## Exercises

1. Profile a slow query and identify bottlenecks
2. Implement broadcast join optimization
3. Handle a skewed join using salting
4. Configure optimal partition count for your data

---

## Summary
- Understand jobs, stages, tasks in Spark
- Use `explain()` to analyze query plans
- Partition data appropriately
- Cache wisely, unpersist when done
- Enable AQE for automatic optimization
- Broadcast small tables
- Handle skew with salting
- Monitor via Spark UI
