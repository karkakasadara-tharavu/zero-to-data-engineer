# PySpark & Advanced Spark - Interview Insights & Tricks

## 🎯 Overview
This guide covers advanced PySpark topics including DataFrames, window functions, performance optimization, Delta Lake, and Spark Streaming - the topics that distinguish senior data engineers.

---

## Module 15: PySpark DataFrames & Operations

### 💡 What Senior-Level Interviews Focus On

Advanced PySpark questions test:
- Complex transformation patterns
- Window function mastery
- Performance optimization strategies
- Data skew handling
- Real-world problem-solving

### 🔥 Top Interview Tricks

#### Trick 1: DataFrame Operations Mastery
```python
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import *

spark = SparkSession.builder.appName("Interview").getOrCreate()

# COLUMN OPERATIONS
df.withColumn("new_col", F.col("existing_col") * 2)
df.withColumnRenamed("old_name", "new_name")
df.drop("unnecessary_col")
df.select(F.col("*"), (F.col("amount") * 1.1).alias("with_tax"))

# CONDITIONAL COLUMNS
df.withColumn("tier",
    F.when(F.col("amount") > 1000, "gold")
     .when(F.col("amount") > 500, "silver")
     .otherwise("bronze")
)

# MULTIPLE CONDITIONS
df.withColumn("flag",
    F.when((F.col("a") > 10) & (F.col("b") < 5), True)
     .otherwise(False)
)

# ARRAY AND MAP OPERATIONS
df.withColumn("first_item", F.col("array_col").getItem(0))
df.withColumn("exploded", F.explode("array_col"))  # One row per element
df.withColumn("map_value", F.col("map_col").getItem("key"))

# STRING OPERATIONS
df.withColumn("upper", F.upper("name"))
df.withColumn("concat", F.concat_ws(" ", "first", "last"))
df.withColumn("extracted", F.regexp_extract("text", r"(\d+)", 1))
df.withColumn("replaced", F.regexp_replace("text", r"\s+", "_"))

# DATE/TIME OPERATIONS
df.withColumn("year", F.year("date_col"))
df.withColumn("month", F.month("date_col"))
df.withColumn("date_diff", F.datediff("end_date", "start_date"))
df.withColumn("next_week", F.date_add("date_col", 7))
```

#### Trick 2: Window Functions in PySpark (Interview Favorite!)
```python
from pyspark.sql.window import Window

# DEFINE WINDOW SPECIFICATIONS
# Partition + Order (for ranking, running totals)
window_spec = Window.partitionBy("department").orderBy("salary")

# Partition only (for group aggregates)
dept_window = Window.partitionBy("department")

# With frame (for rolling calculations)
rolling_window = Window.partitionBy("store").orderBy("date").rowsBetween(-6, 0)

# RANKING FUNCTIONS
df.withColumn("row_num", F.row_number().over(window_spec))
df.withColumn("rank", F.rank().over(window_spec))
df.withColumn("dense_rank", F.dense_rank().over(window_spec))
df.withColumn("percentile", F.percent_rank().over(window_spec))
df.withColumn("ntile", F.ntile(4).over(window_spec))  # Quartiles

# CLASSIC INTERVIEW: Top N per group
windowed = df.withColumn("rn", F.row_number().over(
    Window.partitionBy("category").orderBy(F.desc("sales"))
))
top3_per_category = windowed.filter(F.col("rn") <= 3)

# RUNNING CALCULATIONS
df.withColumn("running_total", F.sum("amount").over(
    Window.partitionBy("customer").orderBy("date").rowsBetween(Window.unboundedPreceding, 0)
))

df.withColumn("cumulative_count", F.count("*").over(
    Window.partitionBy("region").orderBy("date").rowsBetween(Window.unboundedPreceding, 0)
))

# MOVING AVERAGE
df.withColumn("7day_avg", F.avg("sales").over(
    Window.partitionBy("store").orderBy("date").rowsBetween(-6, 0)
))

# LAG AND LEAD
df.withColumn("prev_amount", F.lag("amount", 1).over(
    Window.partitionBy("customer").orderBy("date")
))

df.withColumn("next_amount", F.lead("amount", 1).over(
    Window.partitionBy("customer").orderBy("date")
))

# PERIOD OVER PERIOD
df.withColumn("mom_change", 
    F.col("revenue") - F.lag("revenue", 1).over(
        Window.partitionBy("product").orderBy("month")
    )
)

df.withColumn("mom_pct", 
    (F.col("revenue") - F.lag("revenue", 1).over(
        Window.partitionBy("product").orderBy("month")
    )) / F.lag("revenue", 1).over(
        Window.partitionBy("product").orderBy("month")
    ) * 100
)

# FIRST AND LAST VALUES
df.withColumn("first_purchase", F.first("order_id").over(
    Window.partitionBy("customer").orderBy("date")
))

df.withColumn("last_purchase", F.last("order_id").over(
    Window.partitionBy("customer").orderBy("date").rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)
))
```

#### Trick 3: Complex Aggregations
```python
# GROUPBY WITH MULTIPLE AGGREGATIONS
df.groupBy("category", "region").agg(
    F.sum("amount").alias("total_amount"),
    F.avg("amount").alias("avg_amount"),
    F.count("*").alias("count"),
    F.countDistinct("customer_id").alias("unique_customers"),
    F.min("date").alias("first_order"),
    F.max("date").alias("last_order"),
    F.collect_list("product").alias("products"),
    F.collect_set("status").alias("statuses")
)

# CONDITIONAL AGGREGATION
df.groupBy("customer_id").agg(
    F.sum(F.when(F.col("year") == 2023, F.col("amount")).otherwise(0)).alias("sales_2023"),
    F.sum(F.when(F.col("year") == 2024, F.col("amount")).otherwise(0)).alias("sales_2024"),
    F.count(F.when(F.col("status") == "returned", True)).alias("return_count")
)

# PIVOT TABLE
df.groupBy("region").pivot("year").agg(F.sum("sales"))
# Result: region | 2022 | 2023 | 2024

# PIVOT WITH SPECIFIC VALUES (more efficient)
df.groupBy("region").pivot("year", [2022, 2023, 2024]).agg(F.sum("sales"))

# ROLLUP AND CUBE (for subtotals)
df.rollup("region", "category").agg(F.sum("sales"))  # Hierarchical subtotals
df.cube("region", "category").agg(F.sum("sales"))    # All combinations

# INTERVIEW INSIGHT: "pivot() causes a shuffle but pre-specifying 
# values makes it more efficient. For large cardinality, I might 
# use conditional aggregation instead."
```

#### Trick 4: Advanced Joins
```python
# JOIN TYPES
df1.join(df2, "key")                              # Inner (default)
df1.join(df2, "key", "left")                      # Left outer
df1.join(df2, "key", "right")                     # Right outer
df1.join(df2, "key", "outer")                     # Full outer
df1.join(df2, "key", "left_semi")                 # Left semi (exists)
df1.join(df2, "key", "left_anti")                 # Left anti (not exists)
df1.crossJoin(df2)                                # Cartesian product

# MULTIPLE JOIN COLUMNS
df1.join(df2, ["key1", "key2"])

# DIFFERENT COLUMN NAMES
df1.join(df2, df1.id == df2.customer_id)

# COMPLEX JOIN CONDITIONS
df1.join(df2, 
    (df1.date >= df2.start_date) & (df1.date <= df2.end_date),
    "left"
)

# BROADCAST JOIN (critical for performance!)
from pyspark.sql.functions import broadcast

# Small dimension table
dim_df = spark.read.parquet("dimensions/")  # < 10MB
fact_df = spark.read.parquet("facts/")      # Terabytes

# Broadcast small table to all executors
result = fact_df.join(broadcast(dim_df), "key")

# Check broadcast threshold
spark.conf.get("spark.sql.autoBroadcastJoinThreshold")  # Default: 10MB
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", 50 * 1024 * 1024)  # 50MB

# SKEWED JOIN HANDLING
# If one key has millions of rows, it creates a "hot" partition
# Solution 1: Salting
from pyspark.sql import functions as F
import random

num_buckets = 10

# Salt the large (skewed) table
large_df = large_df.withColumn("salt", (F.rand() * num_buckets).cast("int"))

# Explode the small table
small_df = small_df.withColumn("salt", F.explode(F.array([F.lit(i) for i in range(num_buckets)])))

# Join on key + salt
result = large_df.join(small_df, ["key", "salt"]).drop("salt")

# INTERVIEW INSIGHT: "I use broadcast joins for small tables 
# to avoid shuffles. For skewed data, I apply salting to 
# distribute hot keys across multiple partitions."
```

#### Trick 5: UDFs (User Defined Functions)
```python
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType, IntegerType, ArrayType

# SIMPLE UDF
@udf(returnType=StringType())
def categorize(amount):
    if amount is None:
        return "unknown"
    if amount > 1000:
        return "high"
    elif amount > 100:
        return "medium"
    return "low"

df.withColumn("category", categorize(F.col("amount")))

# UDF WITH MULTIPLE INPUTS
@udf(returnType=DoubleType())
def calculate_discount(amount, tier):
    discounts = {"gold": 0.2, "silver": 0.1, "bronze": 0.05}
    return amount * discounts.get(tier, 0)

df.withColumn("discount", calculate_discount(F.col("amount"), F.col("tier")))

# PANDAS UDF (MUCH FASTER!)
from pyspark.sql.functions import pandas_udf
import pandas as pd

@pandas_udf(DoubleType())
def fast_calculate(amounts: pd.Series, tiers: pd.Series) -> pd.Series:
    discounts = {"gold": 0.2, "silver": 0.1, "bronze": 0.05}
    return amounts * tiers.map(lambda t: discounts.get(t, 0))

df.withColumn("discount", fast_calculate(F.col("amount"), F.col("tier")))

# GROUPED MAP PANDAS UDF (for complex group operations)
from pyspark.sql.functions import pandas_udf, PandasUDFType

@pandas_udf(schema, PandasUDFType.GROUPED_MAP)
def normalize_within_group(pdf):
    pdf['normalized'] = (pdf['value'] - pdf['value'].mean()) / pdf['value'].std()
    return pdf

df.groupBy("group").apply(normalize_within_group)

# INTERVIEW INSIGHT: "Regular UDFs serialize row by row and are 
# slow. Pandas UDFs use Arrow for vectorized execution and can 
# be 10-100x faster. I always prefer Pandas UDFs for production."
```

### 🎤 PySpark Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "UDF performance?" | "Regular UDFs are slow due to serialization. I use Pandas UDFs with Arrow for vectorized processing" |
| "Window functions?" | "I define window specs with partitionBy and orderBy, then apply ranking or running aggregate functions" |
| "Data skew?" | "I identify hot keys with count by key, then apply salting or isolate skewed keys for broadcast" |

---

## Module 16: Advanced PySpark & Performance

### 💡 Senior Engineer Topics

- Performance tuning
- Delta Lake operations
- Spark Streaming
- Production best practices

### 🔥 Top Interview Tricks

#### Trick 1: Performance Optimization
```python
# CONFIGURATION TUNING
spark.conf.set("spark.sql.shuffle.partitions", 200)        # Default, tune based on data
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", 10485760)  # 10MB
spark.conf.set("spark.sql.adaptive.enabled", "true")       # AQE - adaptive query execution

# ADAPTIVE QUERY EXECUTION (AQE) - Spark 3.0+
# Automatically:
# - Coalesces shuffle partitions
# - Converts sort-merge joins to broadcast
# - Optimizes skewed joins

spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")

# PARTITION SIZING
# Check current partitions
df.rdd.getNumPartitions()

# Repartition by key (for joins)
df.repartition(100, "join_key")

# Coalesce (reduce without shuffle)
df.coalesce(10)

# PREDICATE PUSHDOWN VERIFICATION
df.filter(F.col("date") > "2024-01-01").explain()
# Look for: PushedFilters: [GreaterThan(date, 2024-01-01)]

# COLUMN PRUNING
# Only select needed columns early
df.select("id", "amount", "date").filter(F.col("amount") > 100)

# AVOID SHUFFLES
# 1. Filter early
# 2. Select only needed columns
# 3. Use broadcast for small tables
# 4. Partition by join key ahead of time

# INTERVIEW INSIGHT: "I enable AQE for automatic optimization, 
# verify predicate pushdown in explain plans, and use broadcast 
# joins aggressively for dimension tables."
```

#### Trick 2: Handling Data Skew
```python
# DIAGNOSE SKEW
# Check partition sizes
df.groupBy(F.spark_partition_id()).count().orderBy(F.desc("count")).show()

# Check key distribution
df.groupBy("key").count().orderBy(F.desc("count")).show(20)

# SOLUTION 1: SALTING
# Add random suffix to skewed keys
num_salt = 10

# Salt large table
large_df = large_df.withColumn("salted_key", 
    F.concat(F.col("key"), F.lit("_"), (F.rand() * num_salt).cast("int"))
)

# Explode small table
small_df = small_df.withColumn("salted_key",
    F.explode(F.array([F.concat(F.col("key"), F.lit("_"), F.lit(i)) for i in range(num_salt)]))
)

result = large_df.join(small_df, "salted_key")

# SOLUTION 2: ISOLATE HOT KEYS
# Separate skewed keys, broadcast them
hot_keys = ["key1", "key2"]  # Known skewed keys

# Process hot keys with broadcast
hot_large = large_df.filter(F.col("key").isin(hot_keys))
hot_small = small_df.filter(F.col("key").isin(hot_keys))
hot_result = hot_large.join(broadcast(hot_small), "key")

# Process normal keys with regular join
normal_large = large_df.filter(~F.col("key").isin(hot_keys))
normal_small = small_df.filter(~F.col("key").isin(hot_keys))
normal_result = normal_large.join(normal_small, "key")

# Union results
result = hot_result.union(normal_result)

# SOLUTION 3: AQE SKEW HANDLING (Spark 3.0+)
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.skewedPartitionFactor", 5)
spark.conf.set("spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes", "256MB")
```

#### Trick 3: Delta Lake Operations
```python
from delta.tables import DeltaTable

# WRITE DELTA TABLE
df.write.format("delta").mode("overwrite").save("/path/to/delta")

# CREATE MANAGED TABLE
df.write.format("delta").saveAsTable("database.table_name")

# READ DELTA
df = spark.read.format("delta").load("/path/to/delta")

# UPSERT (MERGE) - Critical for data engineering!
delta_table = DeltaTable.forPath(spark, "/path/to/delta")

delta_table.alias("target").merge(
    source=updates_df.alias("source"),
    condition="target.id = source.id"
).whenMatchedUpdate(set={
    "name": "source.name",
    "amount": "source.amount",
    "updated_at": "current_timestamp()"
}).whenNotMatchedInsert(values={
    "id": "source.id",
    "name": "source.name",
    "amount": "source.amount",
    "created_at": "current_timestamp()"
}).execute()

# CONDITIONAL MERGE
delta_table.alias("t").merge(
    source=updates_df.alias("s"),
    condition="t.id = s.id"
).whenMatchedUpdate(
    condition="s.amount > t.amount",  # Only update if amount increased
    set={"amount": "s.amount"}
).whenMatchedDelete(
    condition="s.deleted = true"      # Delete if flagged
).whenNotMatchedInsert(
    values={"id": "s.id", "amount": "s.amount"}
).execute()

# TIME TRAVEL
# Query historical version
df = spark.read.format("delta").option("versionAsOf", 5).load("/path")
df = spark.read.format("delta").option("timestampAsOf", "2024-01-15").load("/path")

# VACUUM (clean old versions)
delta_table.vacuum(168)  # Keep 168 hours (7 days) of history

# OPTIMIZE (compact small files)
delta_table.optimize().executeCompaction()

# Z-ORDER (colocate related data)
delta_table.optimize().executeZOrderBy("date", "customer_id")

# INTERVIEW INSIGHT: "Delta Lake provides ACID transactions on 
# data lakes. MERGE enables efficient upserts, and time travel 
# supports auditing. I use OPTIMIZE + Z-ORDER for query performance."
```

#### Trick 4: Spark Structured Streaming
```python
# READ STREAMING DATA
stream_df = spark.readStream.format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "topic-name") \
    .option("startingOffsets", "earliest") \
    .load()

# PARSE JSON
from pyspark.sql.types import StructType, StringType, TimestampType

schema = StructType() \
    .add("event_type", StringType()) \
    .add("user_id", StringType()) \
    .add("timestamp", TimestampType()) \
    .add("amount", DoubleType())

parsed_df = stream_df.select(
    F.from_json(F.col("value").cast("string"), schema).alias("data")
).select("data.*")

# WINDOW AGGREGATIONS
windowed_counts = parsed_df \
    .withWatermark("timestamp", "10 minutes") \
    .groupBy(
        F.window("timestamp", "5 minutes", "1 minute"),  # 5-min window, sliding every 1 min
        "event_type"
    ).count()

# WRITE STREAMING
query = windowed_counts.writeStream \
    .format("delta") \
    .option("checkpointLocation", "/path/to/checkpoint") \
    .outputMode("update") \
    .trigger(processingTime="1 minute") \
    .start("/path/to/output")

# OUTPUT MODES
# append: Only new rows (no aggregation updates)
# update: Changed rows only
# complete: Entire result table (for aggregations)

# TRIGGERS
# .trigger(processingTime="10 seconds")   # Micro-batch every 10s
# .trigger(once=True)                      # Process once then stop
# .trigger(availableNow=True)              # Process all available, then stop
# .trigger(continuous="1 second")          # Continuous processing (experimental)

# STATEFUL OPERATIONS
# Watermarking prevents unbounded state growth
df.withWatermark("event_time", "30 minutes") \
  .groupBy(F.window("event_time", "10 minutes")) \
  .count()

# INTERVIEW INSIGHT: "Structured Streaming provides exactly-once 
# semantics with checkpointing. I use watermarks to bound state 
# and prevent memory issues in long-running jobs."
```

#### Trick 5: Production Best Practices
```python
# ERROR HANDLING
from pyspark.sql.utils import AnalysisException

try:
    df = spark.read.parquet("/path/that/might/not/exist")
except AnalysisException as e:
    logger.error(f"Failed to read data: {e}")
    df = spark.createDataFrame([], schema)  # Empty fallback

# DATA QUALITY CHECKS
def validate_dataframe(df, table_name):
    checks = []
    
    # Row count check
    count = df.count()
    checks.append(("row_count", count > 0, count))
    
    # Null check on critical columns
    null_counts = df.select([
        F.sum(F.when(F.col(c).isNull(), 1).otherwise(0)).alias(c)
        for c in ["id", "amount"]
    ]).collect()[0]
    
    for col in ["id", "amount"]:
        checks.append((f"null_{col}", null_counts[col] == 0, null_counts[col]))
    
    # Duplicate check
    dup_count = df.count() - df.dropDuplicates(["id"]).count()
    checks.append(("duplicates", dup_count == 0, dup_count))
    
    # Log and raise on failure
    for check_name, passed, value in checks:
        status = "PASS" if passed else "FAIL"
        logger.info(f"{table_name} - {check_name}: {status} (value: {value})")
        
    if not all(c[1] for c in checks):
        raise ValueError(f"Data quality checks failed for {table_name}")

# IDEMPOTENT WRITES
# Use overwrite with partition
df.write.mode("overwrite") \
    .partitionBy("year", "month", "day") \
    .parquet("/path/to/data")

# Or use Delta merge for upserts
# (See Delta Lake section above)

# LOGGING
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Log metrics
logger.info(f"Processed {df.count()} records")
logger.info(f"Output partitions: {df.rdd.getNumPartitions()}")

# MONITORING
# Use Spark UI for:
# - Stage timeline
# - Task distribution (check for skew)
# - Memory usage
# - Shuffle read/write sizes
```

### 🎤 Advanced PySpark Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Delta vs Parquet?" | "Delta adds ACID transactions, MERGE capability, time travel, and schema enforcement on top of Parquet" |
| "Streaming exactly-once?" | "Checkpointing + idempotent writes ensure exactly-once semantics even with failures" |
| "Performance tuning?" | "Enable AQE, verify predicate pushdown, optimize shuffle partitions, use broadcast joins, and address data skew" |

---

## 📊 PySpark Interview Quick Reference

### Window Functions Template
```python
from pyspark.sql.window import Window

# Define window
window_spec = Window.partitionBy("group").orderBy("date")

# Apply functions
F.row_number().over(window_spec)
F.rank().over(window_spec)
F.lag("col", 1).over(window_spec)
F.sum("col").over(window_spec.rowsBetween(Window.unboundedPreceding, 0))
```

### Join Types
| Type | Description |
|------|-------------|
| inner | Matching rows only |
| left | All left + matching right |
| right | All right + matching left |
| outer | All from both |
| left_semi | Left rows that have match |
| left_anti | Left rows without match |

### Delta Lake Commands
```python
# Read/Write
spark.read.format("delta").load(path)
df.write.format("delta").save(path)

# MERGE for upserts
delta_table.merge(source, condition).whenMatched...whenNotMatched...

# Maintenance
delta_table.vacuum(168)
delta_table.optimize().executeCompaction()
```

### Performance Checklist
✅ Enable Adaptive Query Execution  
✅ Use broadcast for small tables  
✅ Filter and select early  
✅ Check for data skew  
✅ Verify predicate pushdown  
✅ Use Pandas UDFs not regular UDFs  
✅ Partition by common filter/join columns  

---

*"The best Spark code is the code that doesn't shuffle."*
