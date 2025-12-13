# Advanced PySpark - Performance Optimization

## 📚 What You'll Learn
- Understanding Spark execution
- Partitioning strategies
- Memory management
- Caching and persistence
- Join optimization
- Shuffle optimization
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐⭐⭐ Expert

---

## 🎯 Understanding Spark Performance

### The Execution Model

```
┌────────────────────────────────────────────────────────────────────────┐
│                      SPARK EXECUTION PIPELINE                           │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Your Code                                                            │
│       │                                                                │
│       ▼                                                                │
│   ┌──────────────────┐                                                 │
│   │ Logical Plan     │  What you want to do                            │
│   └────────┬─────────┘                                                 │
│            │                                                           │
│            ▼                                                           │
│   ┌──────────────────┐                                                 │
│   │ Catalyst         │  Optimization (predicate pushdown,              │
│   │ Optimizer        │  column pruning, join reordering)               │
│   └────────┬─────────┘                                                 │
│            │                                                           │
│            ▼                                                           │
│   ┌──────────────────┐                                                 │
│   │ Physical Plan    │  How to execute (which join algorithm, etc.)   │
│   └────────┬─────────┘                                                 │
│            │                                                           │
│            ▼                                                           │
│   ┌──────────────────┐                                                 │
│   │ DAG Scheduler    │  Divide into stages based on shuffles          │
│   └────────┬─────────┘                                                 │
│            │                                                           │
│            ▼                                                           │
│   ┌──────────────────┐                                                 │
│   │ Task Scheduler   │  Launch tasks on executors                      │
│   └────────┬─────────┘                                                 │
│            │                                                           │
│            ▼                                                           │
│   Execution on Cluster                                                 │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Using explain() to Understand Plans

```python
df = spark.read.parquet("data.parquet")
result = df.filter(col("age") > 30) \
    .groupBy("department") \
    .agg(sum("salary"))

# Show execution plan
result.explain()          # Simple plan
result.explain(True)      # Extended plan (all stages)
result.explain("formatted")  # Formatted with sections
result.explain("cost")    # With cost estimates
```

---

## 📊 Partitioning Strategies

### Understanding Partitions

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PARTITIONING                                     │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   DataFrame with 1 million rows                                        │
│                                                                         │
│   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐     │
│   │ Partition 1 │ │ Partition 2 │ │ Partition 3 │ │ Partition 4 │     │
│   │  250K rows  │ │  250K rows  │ │  250K rows  │ │  250K rows  │     │
│   │  (Task 1)   │ │  (Task 2)   │ │  (Task 3)   │ │  (Task 4)   │     │
│   └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘     │
│                                                                         │
│   Ideal: #partitions = #cores * 2-3                                    │
│   Each partition = 100MB - 1GB                                         │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Checking and Setting Partitions

```python
# Check number of partitions
print(df.rdd.getNumPartitions())

# Check partition sizes
df.rdd.mapPartitions(lambda x: [sum(1 for _ in x)]).collect()

# Key configurations
spark.conf.set("spark.sql.shuffle.partitions", 200)  # Default for shuffles
spark.conf.set("spark.default.parallelism", 100)     # Default for RDDs
```

### Repartition vs Coalesce

```python
# Repartition - full shuffle, can increase or decrease
df_repartitioned = df.repartition(100)  # 100 partitions

# Repartition by column - co-locate related data
df_repartitioned = df.repartition(100, "department")

# Coalesce - no shuffle, only decrease partitions
df_coalesced = df.coalesce(10)  # Combine partitions

# When to use which:
# - Increase partitions: repartition()
# - Decrease partitions: coalesce() (no shuffle)
# - Before join on same key: repartition(col) on both sides
# - Before write: coalesce() to reduce output files
```

### Optimal Partition Size

```python
# Calculate optimal partitions
data_size_mb = 10000  # 10 GB
target_partition_size_mb = 128
optimal_partitions = data_size_mb // target_partition_size_mb
print(f"Optimal partitions: {optimal_partitions}")  # ~78

# Rule of thumb:
# - 2-3x number of cores for parallelism
# - Each partition 128MB - 1GB
# - Not too few (underutilized) or too many (overhead)
```

---

## 💾 Caching and Persistence

### When to Cache

Cache when:
- DataFrame is used multiple times
- DataFrame is expensive to compute
- Data fits in memory

### Cache vs Persist

```python
# Cache (MEMORY_AND_DISK by default in Spark 3.0+)
df_cached = df.cache()

# Persist with specific storage level
from pyspark import StorageLevel

df.persist(StorageLevel.MEMORY_ONLY)           # Memory only
df.persist(StorageLevel.MEMORY_AND_DISK)       # Spill to disk
df.persist(StorageLevel.DISK_ONLY)             # Disk only
df.persist(StorageLevel.MEMORY_ONLY_SER)       # Serialized (less memory)
df.persist(StorageLevel.MEMORY_AND_DISK_SER)   # Serialized with disk

# Trigger caching (cache is lazy!)
df_cached.count()  # First action triggers caching

# Check if cached
df_cached.is_cached  # Returns True/False

# Unpersist when done
df_cached.unpersist()
```

### Caching Best Practices

```python
# ✅ Good: Cache reused DataFrame
filtered_df = df.filter(col("active") == True)
filtered_df.cache()

# Use multiple times
print(filtered_df.count())
filtered_df.groupBy("dept").count().show()
filtered_df.write.parquet("output")

# Release memory
filtered_df.unpersist()

# ❌ Bad: Caching unused DataFrames
df.cache()  # Cached but never used again
df.filter(col("x") > 5).show()  # Different DataFrame!
```

### Checkpoint vs Cache

```python
# Checkpoint - saves to disk, breaks lineage
spark.sparkContext.setCheckpointDir("/tmp/checkpoints")
df.checkpoint()

# When to use checkpoint:
# - Very long lineage (prevents stack overflow)
# - After expensive operations
# - For fault tolerance in streaming
```

---

## 🔀 Shuffle Optimization

### What Causes Shuffles?

```
Shuffle-Causing Operations:
├── groupBy() / groupByKey()
├── reduceByKey() / aggregateByKey()
├── join() / cogroup()
├── repartition()
├── distinct()
├── orderBy() / sort()
└── intersection() / subtract()
```

### Minimizing Shuffles

```python
# ❌ Bad: Multiple shuffles
df.groupBy("dept").agg(sum("salary")) \
  .orderBy("dept") \
  .join(other_df, "dept")  # 3 shuffles!

# ✅ Better: Combine operations
df.join(other_df, "dept") \
  .groupBy("dept") \
  .agg(sum("salary")) \
  .orderBy("dept")  # 2 shuffles
```

### Pre-partitioning for Joins

```python
# Repartition both DataFrames on join key before join
df1 = df1.repartition(100, "key")
df2 = df2.repartition(100, "key")

# Join will be more efficient (data co-located)
result = df1.join(df2, "key")
```

### Broadcast Join

```python
from pyspark.sql.functions import broadcast

# Broadcast small table to all executors
result = large_df.join(broadcast(small_df), "key")

# Configure auto-broadcast threshold
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", 100 * 1024 * 1024)  # 100MB
```

---

## 🔧 Join Optimization

### Join Types and Performance

```
┌────────────────────────────────────────────────────────────────────────┐
│                     JOIN TYPES BY PERFORMANCE                          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   1. BROADCAST HASH JOIN (fastest)                                     │
│      - One side small enough to broadcast                              │
│      - No shuffle required                                             │
│                                                                         │
│   2. SHUFFLE HASH JOIN                                                 │
│      - Both sides shuffled by join key                                 │
│      - Hash table built on smaller side                                │
│                                                                         │
│   3. SORT-MERGE JOIN (default for large-large)                         │
│      - Both sides sorted and shuffled                                  │
│      - Merge phase walks through sorted data                           │
│                                                                         │
│   4. CARTESIAN JOIN (slowest - avoid!)                                 │
│      - Every row paired with every other row                           │
│      - Only for cross join                                             │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Force Join Strategy

```python
# Force broadcast
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", -1)  # Disable auto
result = df1.join(broadcast(df2), "key")

# Prefer sort-merge join
spark.conf.set("spark.sql.join.preferSortMergeJoin", True)

# Hints in Spark SQL
spark.sql("""
    SELECT /*+ BROADCAST(small_table) */ *
    FROM large_table
    JOIN small_table ON large_table.key = small_table.key
""")

# Other hints: MERGE, SHUFFLE_HASH, SHUFFLE_REPLICATE_NL
```

### Handling Skewed Joins

```python
# AQE (Adaptive Query Execution) handles some skew automatically
spark.conf.set("spark.sql.adaptive.enabled", True)
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", True)

# Manual salting for severe skew
import random

# Add salt to skewed side
df1_salted = df1.withColumn("salt", (rand() * 10).cast("int"))
df1_salted = df1_salted.withColumn("salted_key", 
    concat(col("key"), lit("_"), col("salt")))

# Explode dimension table
df2_exploded = df2.crossJoin(spark.range(0, 10).withColumnRenamed("id", "salt"))
df2_exploded = df2_exploded.withColumn("salted_key",
    concat(col("key"), lit("_"), col("salt")))

# Join on salted key
result = df1_salted.join(df2_exploded, "salted_key")
```

---

## ⚡ Adaptive Query Execution (AQE)

### Enable AQE

```python
# Enable AQE (Spark 3.0+)
spark.conf.set("spark.sql.adaptive.enabled", True)

# AQE features
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", True)  # Auto coalesce
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", True)            # Handle skew
spark.conf.set("spark.sql.adaptive.localShuffleReader.enabled", True)  # Local shuffle
```

### What AQE Does

1. **Coalesce Partitions**: Combines small partitions after shuffle
2. **Switch Join Strategy**: Changes join type based on runtime stats
3. **Handle Skew**: Splits skewed partitions
4. **Optimize Skewed Join**: Special handling for skewed data

---

## 📈 Memory Management

### Executor Memory Layout

```
┌────────────────────────────────────────────────────────────────────────┐
│                     EXECUTOR MEMORY LAYOUT                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   spark.executor.memory = 4g                                           │
│                                                                         │
│   ┌──────────────────────────────────────────────────────────────────┐ │
│   │                    JVM HEAP (4g)                                  │ │
│   │                                                                   │ │
│   │   ┌────────────────────────────────────────────────────────────┐ │ │
│   │   │            SPARK MEMORY (60% = 2.4g)                       │ │ │
│   │   │                                                             │ │ │
│   │   │   ┌─────────────────────┐ ┌─────────────────────┐          │ │ │
│   │   │   │  EXECUTION (50%)    │ │  STORAGE (50%)      │          │ │ │
│   │   │   │  Shuffles, Joins,   │ │  Cached DataFrames  │          │ │ │
│   │   │   │  Sorts, Aggregates  │ │  Broadcast vars     │          │ │ │
│   │   │   │       1.2g          │ │       1.2g          │          │ │ │
│   │   │   └─────────────────────┘ └─────────────────────┘          │ │ │
│   │   │                                                             │ │ │
│   │   └────────────────────────────────────────────────────────────┘ │ │
│   │                                                                   │ │
│   │   ┌────────────────────────────────────────────────────────────┐ │ │
│   │   │              USER MEMORY (40% = 1.6g)                      │ │ │
│   │   │              User data structures, UDFs                    │ │ │
│   │   └────────────────────────────────────────────────────────────┘ │ │
│   │                                                                   │ │
│   └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│   + spark.executor.memoryOverhead (for off-heap, default 10%)          │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Memory Configuration

```python
# Executor memory
spark.conf.set("spark.executor.memory", "8g")
spark.conf.set("spark.executor.memoryOverhead", "1g")  # For containers

# Memory fractions
spark.conf.set("spark.memory.fraction", "0.6")        # Spark memory fraction
spark.conf.set("spark.memory.storageFraction", "0.5") # Storage within Spark memory

# Off-heap memory
spark.conf.set("spark.memory.offHeap.enabled", True)
spark.conf.set("spark.memory.offHeap.size", "2g")
```

---

## 🛠️ Common Performance Issues

### 1. Small Files Problem

```python
# ❌ Problem: Too many small files
df.write.parquet("output")  # 200 small files!

# ✅ Solution: Coalesce before write
df.coalesce(10).write.parquet("output")

# Or repartition for specific size
target_files = max(1, data_size_mb // 128)  # ~128MB per file
df.repartition(target_files).write.parquet("output")
```

### 2. Data Skew

```python
# Check for skew
df.groupBy("key").count().orderBy(desc("count")).show()

# Solutions:
# 1. Salting (covered above)
# 2. AQE skew join
# 3. Isolate and broadcast skewed keys
# 4. Filter out skewed keys and process separately
```

### 3. Spill to Disk

```python
# Increase memory or partitions
spark.conf.set("spark.executor.memory", "16g")
spark.conf.set("spark.sql.shuffle.partitions", 400)

# Use more but smaller partitions
df.repartition(1000)
```

### 4. GC Issues

```python
# Check GC time in Spark UI
# If GC > 10% of task time, try:

# Use G1GC
spark.conf.set("spark.executor.extraJavaOptions", 
    "-XX:+UseG1GC -XX:G1HeapRegionSize=16M")

# Reduce memory fraction
spark.conf.set("spark.memory.fraction", "0.5")

# Use more executors with less memory each
```

---

## 🎓 Interview Questions

### Q1: How do you identify performance bottlenecks in Spark?
**A:**
1. **Spark UI**: Check stages, tasks, shuffle read/write
2. **explain()**: View execution plan
3. **Metrics**: Task duration, GC time, spill
4. **Key indicators**: Skew (uneven task times), shuffle size, spill

### Q2: What is data skew and how do you handle it?
**A:** Data skew is when some partitions have much more data than others.
Solutions:
- **Salting**: Add random suffix to keys
- **Broadcast**: If one side small enough
- **AQE**: Enable adaptive skew join
- **Isolate**: Process skewed keys separately

### Q3: Explain the difference between repartition and coalesce.
**A:**
- **repartition()**: Full shuffle, can increase/decrease partitions, even distribution
- **coalesce()**: No shuffle, only decrease partitions, may have uneven sizes

Use coalesce to reduce partitions (efficient), repartition when even distribution needed.

### Q4: When should you cache a DataFrame?
**A:** Cache when:
- DataFrame is reused multiple times
- Computing it is expensive
- It fits in memory
- Don't cache one-time-use DataFrames

### Q5: How do you optimize joins in Spark?
**A:**
1. **Broadcast small tables**
2. **Filter before join**
3. **Partition on join key**
4. **Use appropriate join type**
5. **Enable AQE for dynamic optimization**
6. **Salt for skewed keys**

### Q6: What is Adaptive Query Execution (AQE)?
**A:** AQE (Spark 3.0+) optimizes queries at runtime based on statistics:
- Coalesces small partitions
- Switches join strategies
- Handles skewed joins
- Dynamically optimizes shuffle partitions

### Q7: How do you handle the small files problem?
**A:**
- **Coalesce** before write
- **Repartition** to target file size
- Configure `maxRecordsPerFile`
- Use Delta Lake (auto-compaction)
- Post-process with compaction job

### Q8: Explain Spark memory management.
**A:**
- **Execution Memory**: Shuffles, joins, sorts, aggregations
- **Storage Memory**: Cached data, broadcast variables
- **User Memory**: UDFs, user data structures
- Execution and storage share unified memory region with dynamic allocation

### Q9: What causes shuffles and how do you minimize them?
**A:**
**Causes**: groupBy, join, repartition, distinct, orderBy

**Minimize**:
- Pre-partition on frequently used keys
- Broadcast small tables
- Use mapPartitions instead of map+groupBy
- Combine operations
- Filter early

### Q10: How do you tune spark.sql.shuffle.partitions?
**A:**
- Default is 200 (often wrong)
- Too few: Memory pressure, task failures
- Too many: Scheduling overhead, small files
- Rule: Target 128MB-1GB per partition
- Calculate: `data_size / target_partition_size`
- Enable AQE for auto-coalesce

---

## 🔗 Related Topics
- [← UDFs](./01_udfs.md)
- [Spark SQL →](./02_spark_sql.md)
- [Streaming →](./04_streaming.md)

---

*Next: Master Spark SQL queries*
