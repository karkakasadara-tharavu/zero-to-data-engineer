# PySpark Quick Reference Cheat Sheet

## 🎯 Purpose
A comprehensive quick reference for PySpark data engineering patterns. Perfect for interview prep and daily work.

---

## SparkSession Initialization

```python
from pyspark.sql import SparkSession

# Basic SparkSession
spark = SparkSession.builder \
    .appName("MyApp") \
    .getOrCreate()

# With configurations
spark = SparkSession.builder \
    .appName("MyApp") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "200") \
    .config("spark.executor.memory", "4g") \
    .config("spark.driver.memory", "2g") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

# For Delta Lake
spark = SparkSession.builder \
    .appName("DeltaApp") \
    .config("spark.jars.packages", "io.delta:delta-core_2.12:2.4.0") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

# Stop session
spark.stop()
```

---

## DataFrame Creation

```python
from pyspark.sql.types import *

# From Python data
data = [("John", 30), ("Jane", 25)]
df = spark.createDataFrame(data, ["name", "age"])

# With explicit schema
schema = StructType([
    StructField("name", StringType(), True),
    StructField("age", IntegerType(), True),
    StructField("salary", DoubleType(), True)
])
df = spark.createDataFrame(data, schema)

# From Pandas
import pandas as pd
pdf = pd.DataFrame({"name": ["John", "Jane"], "age": [30, 25]})
df = spark.createDataFrame(pdf)

# Empty DataFrame with schema
df = spark.createDataFrame([], schema)
```

---

## Reading Data

```python
# CSV
df = spark.read.csv("path/to/file.csv", header=True, inferSchema=True)
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("delimiter", ",") \
    .option("quote", '"') \
    .option("escape", "\\") \
    .option("nullValue", "NULL") \
    .csv("path/to/file.csv")

# JSON
df = spark.read.json("path/to/file.json")
df = spark.read \
    .option("multiLine", "true") \
    .json("path/to/file.json")

# Parquet (columnar, efficient)
df = spark.read.parquet("path/to/file.parquet")

# Delta Lake
df = spark.read.format("delta").load("path/to/delta")

# JDBC (Database)
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:sqlserver://server:1433;database=db") \
    .option("dbtable", "schema.table") \
    .option("user", "username") \
    .option("password", "password") \
    .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
    .load()

# With partitioning for parallel reads
df = spark.read \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "orders") \
    .option("partitionColumn", "order_id") \
    .option("lowerBound", "1") \
    .option("upperBound", "1000000") \
    .option("numPartitions", "10") \
    .load()
```

---

## Writing Data

```python
# CSV
df.write.csv("path/to/output", header=True, mode="overwrite")

# Parquet (recommended)
df.write.parquet("path/to/output", mode="overwrite")

# Delta Lake
df.write.format("delta").mode("overwrite").save("path/to/delta")

# Partitioned write
df.write \
    .partitionBy("year", "month") \
    .mode("overwrite") \
    .parquet("path/to/output")

# Write modes
# overwrite - Replace existing data
# append    - Add to existing data
# ignore    - Skip if exists
# error     - Fail if exists (default)

# JDBC write
df.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "target_table") \
    .option("user", "username") \
    .option("password", "password") \
    .mode("overwrite") \
    .save()

# Coalesce/Repartition before write
df.coalesce(1).write.csv("path/to/single_file")  # Single file
df.repartition(10).write.parquet("path")         # 10 files
```

---

## Basic DataFrame Operations

```python
# View data
df.show()                  # First 20 rows
df.show(50, truncate=False)
df.display()               # Databricks
df.printSchema()           # Schema
df.columns                 # Column names
df.dtypes                  # Column types
df.count()                 # Row count

# Select columns
df.select("col1", "col2")
df.select(df.col1, df.col2)
df.select(df["col1"], df["col2"])

from pyspark.sql.functions import col
df.select(col("col1"), col("col2"))

# Select with expressions
df.select(
    col("name"),
    col("salary") * 12,
    (col("salary") / col("hours")).alias("hourly_rate")
)

# Filter rows
df.filter(df.age > 25)
df.filter("age > 25")
df.filter((df.age > 25) & (df.city == "NYC"))
df.filter(col("name").like("%John%"))
df.filter(col("status").isin(["active", "pending"]))
df.filter(col("email").isNotNull())

# Where (alias for filter)
df.where(df.age > 25)

# Distinct
df.distinct()
df.dropDuplicates()
df.dropDuplicates(["col1", "col2"])
```

---

## Column Operations

```python
from pyspark.sql.functions import *

# Add/Modify columns
df = df.withColumn("new_col", lit("constant"))
df = df.withColumn("double_salary", col("salary") * 2)
df = df.withColumn("age", col("age").cast("integer"))

# Multiple columns
df = df.withColumns({
    "full_name": concat(col("first"), lit(" "), col("last")),
    "year": year(col("date"))
})

# Rename column
df = df.withColumnRenamed("old_name", "new_name")

# Drop columns
df = df.drop("col1", "col2")

# Conditional columns
df = df.withColumn("category",
    when(col("amount") >= 1000, "high")
    .when(col("amount") >= 100, "medium")
    .otherwise("low")
)

# Coalesce (first non-null)
df = df.withColumn("contact", coalesce(col("email"), col("phone")))
```

---

## String Functions

```python
from pyspark.sql.functions import *

df = df.select(
    upper(col("name")),                    # UPPERCASE
    lower(col("name")),                    # lowercase
    initcap(col("name")),                  # Title Case
    trim(col("name")),                     # Remove whitespace
    ltrim(col("name")),                    # Left trim
    rtrim(col("name")),                    # Right trim
    length(col("name")),                   # String length
    substring(col("name"), 1, 3),          # First 3 chars
    concat(col("first"), lit(" "), col("last")),  # Concatenate
    concat_ws(", ", col("city"), col("state")),   # With separator
    split(col("full_name"), " "),          # Split to array
    regexp_replace(col("phone"), r"\D", ""),  # Regex replace
    regexp_extract(col("email"), r"@(.+)", 1),  # Extract domain
    locate("@", col("email")),             # Find position
    lpad(col("id"), 10, "0"),              # Left pad
    rpad(col("id"), 10, "0"),              # Right pad
    reverse(col("name")),                  # Reverse string
)
```

---

## Date/Time Functions

```python
from pyspark.sql.functions import *

df = df.select(
    current_date(),                        # Today's date
    current_timestamp(),                   # Current timestamp
    to_date(col("date_str"), "yyyy-MM-dd"),  # String to date
    to_timestamp(col("ts_str"), "yyyy-MM-dd HH:mm:ss"),
    date_format(col("date"), "yyyy/MM/dd"),  # Format date
    year(col("date")),                     # Extract year
    month(col("date")),                    # Extract month
    dayofmonth(col("date")),               # Day of month
    dayofweek(col("date")),                # Day of week (1=Sun)
    dayofyear(col("date")),                # Day of year
    quarter(col("date")),                  # Quarter (1-4)
    weekofyear(col("date")),               # Week number
    hour(col("timestamp")),                # Extract hour
    minute(col("timestamp")),              # Extract minute
    second(col("timestamp")),              # Extract second
    date_add(col("date"), 7),              # Add days
    date_sub(col("date"), 7),              # Subtract days
    add_months(col("date"), 1),            # Add months
    months_between(col("date1"), col("date2")),  # Month difference
    datediff(col("date1"), col("date2")),  # Day difference
    last_day(col("date")),                 # End of month
    trunc(col("date"), "month"),           # Start of month
    trunc(col("date"), "year"),            # Start of year
)
```

---

## Aggregations

```python
from pyspark.sql.functions import *

# Basic aggregations
df.agg(
    count("*").alias("total_rows"),
    countDistinct("customer_id").alias("unique_customers"),
    sum("amount").alias("total_amount"),
    avg("amount").alias("avg_amount"),
    min("amount").alias("min_amount"),
    max("amount").alias("max_amount"),
    first("name").alias("first_name"),
    last("name").alias("last_name"),
    collect_list("item").alias("all_items"),
    collect_set("category").alias("unique_categories"),
)

# GroupBy
df.groupBy("category").agg(
    count("*").alias("count"),
    sum("amount").alias("total"),
    avg("amount").alias("average")
)

# Multiple groupBy columns
df.groupBy("year", "month", "category").agg(
    sum("amount").alias("total"),
    count("order_id").alias("orders")
)

# Pivot
df.groupBy("year").pivot("quarter").sum("amount")

# Rollup (hierarchical subtotals)
df.rollup("year", "month").sum("amount")

# Cube (all combinations)
df.cube("year", "month").sum("amount")
```

---

## Window Functions

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import *

# Define window
window = Window.partitionBy("category").orderBy("date")

# Row number
df = df.withColumn("row_num", row_number().over(window))

# Rank (gaps after ties)
df = df.withColumn("rank", rank().over(window))

# Dense rank (no gaps)
df = df.withColumn("dense_rank", dense_rank().over(window))

# NTILE (divide into N buckets)
df = df.withColumn("quartile", ntile(4).over(window))

# Lag/Lead (previous/next row)
df = df.withColumn("prev_amount", lag("amount", 1, 0).over(window))
df = df.withColumn("next_amount", lead("amount", 1, 0).over(window))

# Running total
df = df.withColumn("running_total", 
    sum("amount").over(window.rowsBetween(Window.unboundedPreceding, Window.currentRow))
)

# Moving average
df = df.withColumn("moving_avg_7",
    avg("amount").over(window.rowsBetween(-6, 0))
)

# Percent rank
df = df.withColumn("pct_rank", percent_rank().over(window))

# First/Last value
df = df.withColumn("first_val", first("amount").over(window))
df = df.withColumn("last_val", last("amount").over(
    window.rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)
))
```

---

## Joins

```python
# Inner join
result = df1.join(df2, df1.id == df2.id, "inner")

# Left join
result = df1.join(df2, df1.id == df2.id, "left")

# Right join
result = df1.join(df2, df1.id == df2.id, "right")

# Full outer join
result = df1.join(df2, df1.id == df2.id, "outer")

# Left semi join (like EXISTS)
result = df1.join(df2, df1.id == df2.id, "left_semi")

# Left anti join (like NOT EXISTS)
result = df1.join(df2, df1.id == df2.id, "left_anti")

# Cross join
result = df1.crossJoin(df2)

# Multiple conditions
result = df1.join(df2, 
    (df1.id == df2.id) & (df1.date == df2.date), 
    "inner"
)

# Join with different column names
result = df1.join(
    df2, 
    df1.customer_id == df2.cust_id, 
    "left"
).drop(df2.cust_id)  # Avoid duplicates

# Broadcast join (small table)
from pyspark.sql.functions import broadcast
result = df1.join(broadcast(df2), df1.id == df2.id)
```

---

## Union and Set Operations

```python
# Union (stack DataFrames)
result = df1.union(df2)                    # Same column count
result = df1.unionAll(df2)                 # Alias for union
result = df1.unionByName(df2)              # Match by column name
result = df1.unionByName(df2, allowMissingColumns=True)

# Intersect (common rows)
result = df1.intersect(df2)

# Except (rows in df1 but not df2)
result = df1.except(df2)
result = df1.subtract(df2)                 # Alias
```

---

## Sorting

```python
# Ascending
df.orderBy("name")
df.orderBy(col("name").asc())

# Descending
df.orderBy(col("name").desc())

# Multiple columns
df.orderBy(col("category").asc(), col("amount").desc())

# Nulls handling
df.orderBy(col("name").asc_nulls_first())
df.orderBy(col("name").desc_nulls_last())

# Sort (alias for orderBy)
df.sort("name")
```

---

## Missing Data

```python
from pyspark.sql.functions import *

# Check for nulls
df.filter(col("name").isNull())
df.filter(col("name").isNotNull())

# Count nulls per column
df.select([count(when(col(c).isNull(), c)).alias(c) for c in df.columns])

# Drop nulls
df.na.drop()                               # Any null
df.na.drop("all")                          # All columns null
df.na.drop(subset=["col1", "col2"])        # Specific columns
df.na.drop(thresh=3)                       # At least 3 non-nulls

# Fill nulls
df.na.fill(0)                              # All numeric with 0
df.na.fill("Unknown")                      # All string with Unknown
df.na.fill({"col1": 0, "col2": "N/A"})     # Specific columns

# Replace values
df.na.replace(["old1", "old2"], ["new1", "new2"], "column")
```

---

## UDF (User Defined Functions)

```python
from pyspark.sql.functions import udf
from pyspark.sql.types import *

# Simple UDF
@udf(returnType=StringType())
def clean_name(name):
    if name:
        return name.strip().upper()
    return None

df = df.withColumn("clean_name", clean_name(col("name")))

# UDF with multiple inputs
@udf(returnType=DoubleType())
def calculate_discount(price, quantity):
    if quantity >= 10:
        return price * 0.9
    return price

df = df.withColumn("final_price", 
    calculate_discount(col("price"), col("quantity")))

# Pandas UDF (vectorized, faster)
from pyspark.sql.functions import pandas_udf
import pandas as pd

@pandas_udf(DoubleType())
def multiply_by_two(s: pd.Series) -> pd.Series:
    return s * 2

df = df.withColumn("doubled", multiply_by_two(col("value")))
```

---

## SQL Queries

```python
# Register temp view
df.createOrReplaceTempView("my_table")

# Run SQL
result = spark.sql("""
    SELECT category, SUM(amount) as total
    FROM my_table
    WHERE status = 'active'
    GROUP BY category
    ORDER BY total DESC
""")

# Global temp view (across sessions)
df.createOrReplaceGlobalTempView("global_table")
result = spark.sql("SELECT * FROM global_temp.global_table")
```

---

## Caching and Persistence

```python
from pyspark import StorageLevel

# Cache in memory
df.cache()                                 # Default: MEMORY_AND_DISK

# Persist with storage level
df.persist(StorageLevel.MEMORY_ONLY)
df.persist(StorageLevel.MEMORY_AND_DISK)
df.persist(StorageLevel.DISK_ONLY)
df.persist(StorageLevel.MEMORY_AND_DISK_SER)

# Unpersist
df.unpersist()

# Check if cached
df.is_cached

# Checkpoint (save to disk, break lineage)
spark.sparkContext.setCheckpointDir("/tmp/checkpoints")
df = df.checkpoint()
```

---

## Performance Optimization

```python
# Repartition (full shuffle)
df = df.repartition(100)                   # By number
df = df.repartition("column")              # By column
df = df.repartition(100, "column")         # Both

# Coalesce (reduce partitions, no shuffle)
df = df.coalesce(10)

# Check partitions
df.rdd.getNumPartitions()

# Broadcast join
from pyspark.sql.functions import broadcast
result = large_df.join(broadcast(small_df), "key")

# Avoid expensive operations
# - Use filter early
# - Avoid UDFs when built-in functions exist
# - Broadcast small tables
# - Partition data appropriately

# Execution plan
df.explain()                               # Simple plan
df.explain(True)                           # Extended plan

# Enable AQE (Adaptive Query Execution)
spark.conf.set("spark.sql.adaptive.enabled", "true")
```

---

## Delta Lake Operations

```python
from delta.tables import DeltaTable

# Create Delta table
df.write.format("delta").save("/path/to/delta")

# Read Delta
df = spark.read.format("delta").load("/path/to/delta")

# ACID operations
delta_table = DeltaTable.forPath(spark, "/path/to/delta")

# Update
delta_table.update(
    condition = "category = 'old'",
    set = {"category": "'new'"}
)

# Delete
delta_table.delete("status = 'cancelled'")

# Merge (upsert)
delta_table.alias("target").merge(
    source_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()

# Time travel
df = spark.read.format("delta") \
    .option("versionAsOf", 0) \
    .load("/path/to/delta")

df = spark.read.format("delta") \
    .option("timestampAsOf", "2024-01-01") \
    .load("/path/to/delta")

# History
delta_table.history().show()

# Optimize and vacuum
spark.sql("OPTIMIZE delta.`/path/to/delta`")
spark.sql("VACUUM delta.`/path/to/delta` RETAIN 168 HOURS")
```

---

## Quick Tips

| Need | Solution |
|------|----------|
| Convert to Pandas | `df.toPandas()` |
| First row as dict | `df.first().asDict()` |
| Sample data | `df.sample(0.1)` or `df.limit(100)` |
| Rename all columns | `df.toDF(*new_names)` |
| Add row number | `row_number().over(Window.orderBy(lit(1)))` |
| Check if empty | `df.isEmpty()` or `df.count() == 0` |
| Get distinct values | `df.select("col").distinct().collect()` |
| Type conversion | `df.withColumn("col", col("col").cast("integer"))` |
| Explode array | `df.withColumn("item", explode("items"))` |
| Flatten struct | `df.select("struct_col.*")` |
