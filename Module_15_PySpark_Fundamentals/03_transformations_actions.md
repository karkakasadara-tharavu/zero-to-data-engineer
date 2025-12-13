# PySpark Transformations and Actions - Complete Guide

## 📚 What You'll Learn
- Difference between transformations and actions
- Narrow vs wide transformations
- Common transformation operations
- Common action operations
- Lazy evaluation in practice
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Understanding Lazy Evaluation

### The Execution Model

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR CODE                                 │
├─────────────────────────────────────────────────────────────────┤
│  df = spark.read.csv("data.csv")           ← Transformation     │
│  df2 = df.filter(col("age") > 30)          ← Transformation     │
│  df3 = df2.select("name", "salary")        ← Transformation     │
│  df4 = df3.groupBy("name").sum("salary")   ← Transformation     │
│                                                                  │
│  # NOTHING EXECUTED YET! Just building plan...                  │
│                                                                  │
│  df4.show()                                 ← ACTION!            │
│  # NOW Spark executes everything!                               │
└─────────────────────────────────────────────────────────────────┘
```

### Why Lazy Evaluation?

1. **Optimization**: Spark can optimize entire plan before executing
2. **Efficiency**: Combines operations, reduces data movement
3. **Resource Management**: Allocates resources only when needed
4. **Fault Tolerance**: Can rebuild from lineage if failure occurs

---

## 🔄 Transformations

### What is a Transformation?

A transformation creates a **new DataFrame/RDD** from an existing one. Transformations are **lazy** - they don't execute immediately.

### Narrow Transformations (No Shuffle)

Data stays within same partition - **fast and efficient**!

```
Partition 1 ─────▶ Partition 1'
Partition 2 ─────▶ Partition 2'
Partition 3 ─────▶ Partition 3'

(Each partition transforms independently)
```

#### 1. filter() / where()

```python
from pyspark.sql.functions import col

# Filter rows based on condition
df_filtered = df.filter(col("age") > 30)

# Multiple conditions
df_filtered = df.filter(
    (col("age") > 30) & 
    (col("salary") > 50000)
)

# Using SQL-like string
df_filtered = df.filter("age > 30 AND salary > 50000")
```

#### 2. select()

```python
# Select specific columns
df_selected = df.select("name", "age")

# With expressions
df_selected = df.select(
    col("name"),
    (col("salary") * 1.1).alias("new_salary")
)

# Using selectExpr for SQL expressions
df_selected = df.selectExpr(
    "name",
    "salary * 1.1 as new_salary",
    "age + 1 as age_next_year"
)
```

#### 3. map() (RDD-level)

```python
# For RDDs
rdd = df.rdd.map(lambda row: (row.name, row.age * 2))

# Convert back to DataFrame
df_mapped = rdd.toDF(["name", "double_age"])
```

#### 4. flatMap() (RDD-level)

```python
# Flatten nested structures
text_rdd = sc.parallelize(["hello world", "spark is great"])
words_rdd = text_rdd.flatMap(lambda line: line.split(" "))
# Result: ["hello", "world", "spark", "is", "great"]
```

#### 5. withColumn()

```python
# Add or replace column
df_new = df.withColumn("age_group", 
    when(col("age") < 30, "Young")
    .when(col("age") < 50, "Middle")
    .otherwise("Senior")
)
```

#### 6. drop()

```python
# Drop columns
df_dropped = df.drop("unwanted_column1", "unwanted_column2")
```

#### 7. sample()

```python
# Random sample (10% of data)
df_sample = df.sample(fraction=0.1, seed=42)

# Sample with replacement
df_sample = df.sample(withReplacement=True, fraction=0.1)
```

---

### Wide Transformations (Shuffle Required)

Data moves between partitions - **expensive, requires network I/O**!

```
Partition 1 ─────┐                    ┌─────▶ Partition 1'
                 ├── SHUFFLE ─────────┤
Partition 2 ─────┤                    ├─────▶ Partition 2'
                 │                    │
Partition 3 ─────┘                    └─────▶ Partition 3'

(Data is redistributed across partitions)
```

#### 1. groupBy()

```python
from pyspark.sql.functions import sum, avg, count, max, min

# Group and aggregate
df_grouped = df.groupBy("department").agg(
    count("*").alias("employee_count"),
    avg("salary").alias("avg_salary"),
    sum("salary").alias("total_salary"),
    max("salary").alias("max_salary"),
    min("salary").alias("min_salary")
)
```

#### 2. orderBy() / sort()

```python
from pyspark.sql.functions import desc, asc

# Sort ascending (default)
df_sorted = df.orderBy("age")

# Sort descending
df_sorted = df.orderBy(desc("salary"))

# Multiple columns
df_sorted = df.orderBy(desc("department"), asc("salary"))
```

#### 3. join()

```python
# Inner join (default)
df_joined = df1.join(df2, df1.id == df2.emp_id, "inner")

# Left join
df_joined = df1.join(df2, df1.id == df2.emp_id, "left")

# Right join
df_joined = df1.join(df2, df1.id == df2.emp_id, "right")

# Full outer join
df_joined = df1.join(df2, df1.id == df2.emp_id, "outer")

# Cross join (Cartesian product - be careful!)
df_joined = df1.crossJoin(df2)

# Anti join (rows in df1 not in df2)
df_joined = df1.join(df2, df1.id == df2.emp_id, "left_anti")

# Semi join (rows in df1 that exist in df2, only df1 columns)
df_joined = df1.join(df2, df1.id == df2.emp_id, "left_semi")
```

#### 4. distinct()

```python
# Remove duplicates
df_distinct = df.distinct()

# Distinct based on specific columns
df_distinct = df.select("department", "title").distinct()
```

#### 5. union() / unionAll() / unionByName()

```python
# Combine DataFrames (must have same schema)
df_combined = df1.union(df2)

# Union by column name (different column order OK)
df_combined = df1.unionByName(df2)

# Handle missing columns
df_combined = df1.unionByName(df2, allowMissingColumns=True)
```

#### 6. repartition() / coalesce()

```python
# Repartition (shuffle) - increase or decrease partitions
df_repartitioned = df.repartition(100)

# Repartition by column (co-locate related data)
df_repartitioned = df.repartition("department")

# Coalesce (no shuffle) - only decrease partitions
df_coalesced = df.coalesce(10)
```

---

## ⚡ Actions

### What is an Action?

An action **triggers execution** of the DAG and returns results to the driver or writes to external storage.

### Data Collection Actions

#### 1. collect()

```python
# Return ALL data to driver (careful with large data!)
all_data = df.collect()  # Returns list of Row objects

for row in all_data:
    print(row.name, row.age)
```

⚠️ **Warning**: Only use on small datasets! Collecting large data can crash the driver.

#### 2. take() / head() / first()

```python
# Take n rows
first_5 = df.take(5)  # Returns list of 5 Row objects

# Head (same as take)
first_10 = df.head(10)

# First row only
first_row = df.first()  # Returns single Row object
```

#### 3. show()

```python
# Print to console (doesn't return data)
df.show()           # Default 20 rows
df.show(10)         # 10 rows
df.show(truncate=False)  # Don't truncate columns
df.show(20, vertical=True)  # Vertical format
```

#### 4. toPandas()

```python
# Convert to Pandas DataFrame
pandas_df = df.toPandas()
```

⚠️ **Warning**: Collects all data to driver!

### Aggregation Actions

#### 5. count()

```python
# Count total rows
total = df.count()  # Returns integer
print(f"Total rows: {total}")
```

#### 6. describe()

```python
# Statistical summary
df.describe().show()
# Shows: count, mean, stddev, min, max for numeric columns

# Specific columns
df.describe("age", "salary").show()
```

### Write Actions

#### 7. write

```python
# Write to storage (triggers execution)
df.write.mode("overwrite").parquet("output.parquet")
df.write.csv("output.csv", header=True)
df.write.json("output.json")
```

#### 8. foreach() / foreachPartition()

```python
# Apply function to each row
def process_row(row):
    print(row.name)

df.foreach(process_row)

# Apply function to each partition (more efficient)
def process_partition(iterator):
    connection = create_connection()
    for row in iterator:
        connection.insert(row)
    connection.close()

df.foreachPartition(process_partition)
```

### RDD Actions

```python
# Reduce - aggregate all elements
total = rdd.reduce(lambda a, b: a + b)

# Aggregate with different types
result = rdd.aggregate(
    (0, 0),  # initial value
    lambda acc, val: (acc[0] + val, acc[1] + 1),  # sequence op
    lambda acc1, acc2: (acc1[0] + acc2[0], acc1[1] + acc2[1])  # combine op
)

# Save to text file
rdd.saveAsTextFile("output.txt")
```

---

## 📊 Transformation vs Action Summary

| Transformation | Description | Type |
|---------------|-------------|------|
| `filter()`, `where()` | Filter rows | Narrow |
| `select()` | Select columns | Narrow |
| `withColumn()` | Add/modify column | Narrow |
| `drop()` | Remove columns | Narrow |
| `sample()` | Random sample | Narrow |
| `map()`, `flatMap()` | Transform each element | Narrow |
| `groupBy()` | Group data | Wide |
| `orderBy()`, `sort()` | Sort data | Wide |
| `join()` | Join DataFrames | Wide |
| `distinct()` | Remove duplicates | Wide |
| `union()` | Combine DataFrames | Wide |
| `repartition()` | Change partitions | Wide |
| `coalesce()` | Reduce partitions | Narrow* |

| Action | Description | Returns |
|--------|-------------|---------|
| `collect()` | Get all data | List of Rows |
| `take(n)` | Get n rows | List of Rows |
| `first()` | Get first row | Row |
| `show()` | Print to console | None |
| `count()` | Count rows | Integer |
| `describe()` | Statistics | DataFrame |
| `write.*` | Save data | None |
| `foreach()` | Apply function | None |

---

## 💡 Best Practices

### 1. Minimize Wide Transformations

```python
# ❌ Bad: Multiple shuffles
df.groupBy("a").agg(sum("b")).groupBy("c").agg(max("sum_b"))

# ✅ Good: Single groupBy when possible
df.groupBy("a", "c").agg(sum("b"), max("b"))
```

### 2. Filter Early

```python
# ❌ Bad: Filter after expensive operations
df.join(large_df).filter(col("type") == "A")

# ✅ Good: Filter before join
df.filter(col("type") == "A").join(filtered_large_df)
```

### 3. Use coalesce() Instead of repartition() to Reduce Partitions

```python
# ❌ Bad: Shuffle to reduce partitions
df.repartition(10)

# ✅ Good: No shuffle
df.coalesce(10)
```

### 4. Cache Reused DataFrames

```python
# If DataFrame is used multiple times
df_filtered = df.filter(col("active") == True)
df_filtered.cache()  # Cache in memory

# First action triggers caching
df_filtered.count()

# Subsequent actions use cache
df_filtered.show()
df_filtered.groupBy("dept").count().show()

# Don't forget to unpersist when done
df_filtered.unpersist()
```

### 5. Broadcast Small Tables in Joins

```python
from pyspark.sql.functions import broadcast

# Small table broadcast (avoids shuffle)
df_result = large_df.join(broadcast(small_df), "key")
```

---

## 🎓 Interview Questions

### Q1: What is the difference between transformation and action in Spark?
**A:**
- **Transformation**: Creates new DataFrame from existing one, lazy (not executed immediately), returns DataFrame. Examples: filter, select, join
- **Action**: Triggers execution of the DAG, returns results to driver or writes to storage. Examples: count, collect, show, write

### Q2: What is the difference between narrow and wide transformations?
**A:**
- **Narrow**: Data stays in same partition, no shuffle needed. Fast. Examples: filter, select, map
- **Wide**: Data moves between partitions, requires shuffle (network I/O). Slow. Examples: groupBy, join, orderBy

### Q3: Why is shuffle expensive?
**A:** Shuffle requires:
1. Writing intermediate data to disk
2. Network transfer between nodes
3. Reading and sorting data on receiving nodes
4. Memory pressure for aggregation
This causes disk I/O, network I/O, and CPU overhead.

### Q4: What is the difference between `repartition()` and `coalesce()`?
**A:**
- **repartition()**: Full shuffle, can increase or decrease partitions, evenly distributes data
- **coalesce()**: No shuffle (only combines existing partitions), can only decrease partitions, may result in uneven partitions

Use coalesce to reduce partitions efficiently; use repartition when even distribution is needed.

### Q5: What happens when you call `collect()`?
**A:** 
1. Triggers execution of all transformations in the DAG
2. Gathers all data from all partitions
3. Transfers data across network to driver
4. Stores all data in driver memory as list of Row objects

⚠️ Can cause OutOfMemoryError if dataset is large.

### Q6: What are the different join types in Spark?
**A:**
- **inner**: Matching rows from both (default)
- **left/left_outer**: All from left, matching from right
- **right/right_outer**: All from right, matching from left  
- **outer/full/full_outer**: All rows from both
- **left_semi**: Left rows that have match in right (only left columns)
- **left_anti**: Left rows that have NO match in right
- **cross**: Cartesian product (every row paired)

### Q7: How do you optimize joins in Spark?
**A:**
1. **Broadcast small tables**: Avoid shuffle for small tables
2. **Filter before join**: Reduce data volume
3. **Use proper join type**: Don't use outer if inner works
4. **Partition on join key**: Data co-located
5. **Sort-merge join**: For large-large joins

### Q8: What is the difference between `cache()` and `persist()`?
**A:**
- `cache()`: Stores in memory only (MEMORY_AND_DISK)
- `persist(level)`: Allows specifying storage level (MEMORY_ONLY, MEMORY_AND_DISK, DISK_ONLY, etc.)

Use cache/persist when DataFrame is used multiple times.

### Q9: What is `explain()` used for?
**A:** Shows the execution plan for a DataFrame:
```python
df.explain()          # Simple plan
df.explain(True)      # Extended plan with stages
df.explain("formatted")  # Formatted output
```
Useful for debugging and optimization.

### Q10: How would you debug slow Spark queries?
**A:**
1. Use `explain()` to understand execution plan
2. Check Spark UI for stage details
3. Look for excessive shuffles
4. Check data skew (uneven partition sizes)
5. Monitor memory usage
6. Check for spilling to disk
7. Verify broadcast join opportunities

---

## 🔗 Related Topics
- [← PySpark DataFrames](./02_pyspark_dataframes.md)
- [Aggregations and GroupBy →](./04_aggregations.md)
- [Window Functions →](./05_window_functions.md)

---

*Next: Learn about Aggregations and GroupBy in PySpark*
