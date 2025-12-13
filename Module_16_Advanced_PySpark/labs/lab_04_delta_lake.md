# Lab 04: Delta Lake Fundamentals

## Overview
Master Delta Lake for reliable data lakes with ACID transactions.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Understand Delta Lake architecture
- ✅ Perform ACID transactions
- ✅ Use time travel capabilities
- ✅ Implement schema evolution
- ✅ Optimize Delta tables

---

## Part 1: Delta Lake Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Delta Lake Benefits                                                      │
├─────────────────────────────────────────────────────────────────────────┤
│ ✓ ACID Transactions - Atomic writes, consistent reads                  │
│ ✓ Schema Enforcement - Prevent bad data                                │
│ ✓ Time Travel - Query historical data                                  │
│ ✓ Unified Batch/Streaming - Same table for both                        │
│ ✓ Data Versioning - Track changes over time                            │
│ ✓ Scalable Metadata - Handle billions of files                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Setup

### Step 2.1: Install Delta Lake
```bash
pip install delta-spark
```

### Step 2.2: Configure SparkSession
```python
from pyspark.sql import SparkSession
from delta import *

# Create Spark session with Delta
builder = SparkSession.builder \
    .appName("Delta Lake") \
    .master("local[*]") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .config("spark.jars.packages", "io.delta:delta-core_2.12:2.4.0")

spark = configure_spark_with_delta_pip(builder).getOrCreate()
```

---

## Part 3: Creating Delta Tables

### Step 3.1: Create from DataFrame
```python
# Sample data
data = [
    (1, "Alice", "Engineering", 75000, "2024-01-15"),
    (2, "Bob", "Marketing", 65000, "2024-01-16"),
    (3, "Charlie", "Engineering", 82000, "2024-01-17"),
    (4, "Diana", "Sales", 58000, "2024-01-18"),
]

df = spark.createDataFrame(data, ["id", "name", "department", "salary", "hire_date"])

# Write as Delta table
df.write.format("delta").mode("overwrite").save("delta_tables/employees")

# Or with partitioning
df.write.format("delta") \
    .mode("overwrite") \
    .partitionBy("department") \
    .save("delta_tables/employees_partitioned")
```

### Step 3.2: Create Table SQL
```python
spark.sql("""
    CREATE TABLE IF NOT EXISTS employee_table (
        id INT,
        name STRING,
        department STRING,
        salary DOUBLE,
        hire_date DATE
    )
    USING DELTA
    LOCATION 'delta_tables/employee_sql'
""")
```

---

## Part 4: Reading Delta Tables

```python
# Read Delta table
df = spark.read.format("delta").load("delta_tables/employees")
df.show()

# Using SQL
spark.sql("SELECT * FROM delta.`delta_tables/employees`").show()

# Register as table and query
df.createOrReplaceTempView("employees")
spark.sql("SELECT department, AVG(salary) FROM employees GROUP BY department").show()
```

---

## Part 5: CRUD Operations

### Step 5.1: INSERT (Append)
```python
new_employees = [
    (5, "Eve", "Engineering", 90000, "2024-01-20"),
    (6, "Frank", "HR", 55000, "2024-01-21"),
]

new_df = spark.createDataFrame(new_employees, ["id", "name", "department", "salary", "hire_date"])

# Append to existing table
new_df.write.format("delta").mode("append").save("delta_tables/employees")
```

### Step 5.2: UPDATE
```python
from delta.tables import DeltaTable

# Load Delta table
delta_table = DeltaTable.forPath(spark, "delta_tables/employees")

# Update records
delta_table.update(
    condition="department = 'Engineering'",
    set={"salary": "salary * 1.1"}
)

# Verify update
spark.read.format("delta").load("delta_tables/employees").show()
```

### Step 5.3: DELETE
```python
# Delete records
delta_table.delete(condition="salary < 60000")

# Verify
spark.read.format("delta").load("delta_tables/employees").show()
```

### Step 5.4: UPSERT (MERGE)
```python
# New data with updates and inserts
updates = spark.createDataFrame([
    (1, "Alice", "Engineering", 85000, "2024-01-15"),  # Update
    (7, "Grace", "Sales", 72000, "2024-01-22"),         # Insert
], ["id", "name", "department", "salary", "hire_date"])

# MERGE operation
delta_table.alias("target").merge(
    updates.alias("source"),
    "target.id = source.id"
).whenMatchedUpdate(set={
    "name": "source.name",
    "department": "source.department",
    "salary": "source.salary",
    "hire_date": "source.hire_date"
}).whenNotMatchedInsert(values={
    "id": "source.id",
    "name": "source.name",
    "department": "source.department",
    "salary": "source.salary",
    "hire_date": "source.hire_date"
}).execute()

spark.read.format("delta").load("delta_tables/employees").show()
```

---

## Part 6: Time Travel

### Step 6.1: View History
```python
# Get table history
history = delta_table.history()
history.select("version", "timestamp", "operation", "operationParameters").show(truncate=False)
```

### Step 6.2: Query Historical Versions
```python
# Read specific version
df_v0 = spark.read.format("delta") \
    .option("versionAsOf", 0) \
    .load("delta_tables/employees")

print("Version 0:")
df_v0.show()

# Read by timestamp
df_timestamp = spark.read.format("delta") \
    .option("timestampAsOf", "2024-01-15 10:00:00") \
    .load("delta_tables/employees")
```

### Step 6.3: Restore to Previous Version
```python
# Restore to version 1
delta_table.restoreToVersion(1)

# Or restore to timestamp
# delta_table.restoreToTimestamp("2024-01-15 10:00:00")

spark.read.format("delta").load("delta_tables/employees").show()
```

---

## Part 7: Schema Evolution

### Step 7.1: Add Columns
```python
# New data with additional column
new_data = spark.createDataFrame([
    (8, "Henry", "Marketing", 68000, "2024-01-23", "henry@email.com"),
], ["id", "name", "department", "salary", "hire_date", "email"])

# Enable schema evolution
new_data.write.format("delta") \
    .mode("append") \
    .option("mergeSchema", "true") \
    .save("delta_tables/employees")

# Schema now includes email column
spark.read.format("delta").load("delta_tables/employees").printSchema()
```

### Step 7.2: Automatic Schema Evolution
```python
# Enable at table level
spark.sql("""
    ALTER TABLE delta.`delta_tables/employees`
    SET TBLPROPERTIES ('delta.columnMapping.mode' = 'name')
""")
```

---

## Part 8: Optimization

### Step 8.1: OPTIMIZE (Compaction)
```python
# Compact small files into larger ones
delta_table.optimize().executeCompaction()

# Or using SQL
spark.sql("OPTIMIZE delta.`delta_tables/employees`")
```

### Step 8.2: Z-ORDER (Data Clustering)
```python
# Cluster data by column for faster queries
delta_table.optimize().executeZOrderBy("department")

# Or using SQL
spark.sql("OPTIMIZE delta.`delta_tables/employees` ZORDER BY (department, id)")
```

### Step 8.3: VACUUM (Remove Old Files)
```python
# Remove files older than retention period (default 7 days)
delta_table.vacuum()

# Remove files older than specific hours (not recommended for production)
# delta_table.vacuum(0)  # Immediately - requires setting safety flag

# Check vacuum
spark.conf.set("spark.databricks.delta.retentionDurationCheck.enabled", "false")
delta_table.vacuum(24)  # 24 hours
```

---

## Part 9: Streaming with Delta

### Step 9.1: Stream to Delta
```python
# Write streaming data to Delta table
streaming_df = spark.readStream \
    .format("rate") \
    .option("rowsPerSecond", 10) \
    .load()

query = streaming_df \
    .writeStream \
    .format("delta") \
    .outputMode("append") \
    .option("checkpointLocation", "/tmp/delta_checkpoint") \
    .start("delta_tables/streaming_events")

import time
time.sleep(30)
query.stop()
```

### Step 9.2: Stream from Delta
```python
# Read streaming from Delta table (Change Data Capture)
streaming_df = spark.readStream \
    .format("delta") \
    .load("delta_tables/employees")

query = streaming_df \
    .writeStream \
    .format("console") \
    .outputMode("append") \
    .start()
```

---

## Part 10: Change Data Feed (CDC)

```python
# Enable Change Data Feed
spark.sql("""
    ALTER TABLE delta.`delta_tables/employees`
    SET TBLPROPERTIES (delta.enableChangeDataFeed = true)
""")

# Read changes
changes_df = spark.read.format("delta") \
    .option("readChangeFeed", "true") \
    .option("startingVersion", 0) \
    .load("delta_tables/employees")

changes_df.show()
# Shows _change_type column: insert, update_preimage, update_postimage, delete
```

---

## Part 11: Table Constraints

```python
# Add NOT NULL constraint
spark.sql("""
    ALTER TABLE delta.`delta_tables/employees`
    ALTER COLUMN id SET NOT NULL
""")

# Add CHECK constraint
spark.sql("""
    ALTER TABLE delta.`delta_tables/employees`
    ADD CONSTRAINT salary_positive CHECK (salary > 0)
""")

# View constraints
spark.sql("DESCRIBE EXTENDED delta.`delta_tables/employees`").show(truncate=False)
```

---

## Part 12: Complete Example

```python
from pyspark.sql import SparkSession
from delta import *
from delta.tables import DeltaTable
from pyspark.sql.functions import current_timestamp

# Setup
builder = SparkSession.builder \
    .appName("Delta Complete Example") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")

spark = configure_spark_with_delta_pip(builder).getOrCreate()

# Create initial data
orders = spark.createDataFrame([
    (1, 101, 100.0, "pending"),
    (2, 102, 250.0, "pending"),
    (3, 101, 75.0, "pending"),
], ["order_id", "customer_id", "amount", "status"])

# Create Delta table
orders.write.format("delta").mode("overwrite").save("delta_tables/orders")

# Simulate updates
delta_orders = DeltaTable.forPath(spark, "delta_tables/orders")

# Update status
delta_orders.update(
    condition="order_id = 1",
    set={"status": "'completed'"}
)

# Insert new order
new_order = spark.createDataFrame([(4, 103, 500.0, "pending")], 
                                   ["order_id", "customer_id", "amount", "status"])
new_order.write.format("delta").mode("append").save("delta_tables/orders")

# View current state
print("Current orders:")
spark.read.format("delta").load("delta_tables/orders").show()

# View history
print("Order history:")
delta_orders.history().select("version", "operation").show()

# Time travel - view original state
print("Original orders (version 0):")
spark.read.format("delta").option("versionAsOf", 0).load("delta_tables/orders").show()

# Optimize
delta_orders.optimize().executeCompaction()

print("Delta Lake operations complete!")
```

---

## Exercises

1. Create a slowly changing dimension with Delta Lake
2. Implement a CDC pipeline with Change Data Feed
3. Optimize a Delta table with Z-ORDER
4. Create a streaming pipeline that writes to Delta

---

## Summary
- Delta Lake adds ACID transactions to data lakes
- CRUD operations via DeltaTable API
- Time travel allows querying historical data
- Schema evolution handles changing schemas
- OPTIMIZE and VACUUM for maintenance
- Unified batch and streaming support
- Change Data Feed for CDC use cases
