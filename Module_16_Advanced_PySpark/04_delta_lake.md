# Delta Lake Fundamentals

## 🎯 Learning Objectives
- Understand what Delta Lake is and why it's essential for modern data engineering
- Learn ACID transactions and time travel capabilities
- Master Delta Lake operations: MERGE, UPDATE, DELETE
- Implement medallion architecture (Bronze/Silver/Gold)
- Optimize Delta tables for performance

---

## What is Delta Lake?

### Definition
Delta Lake is an **open-source storage layer** that brings ACID transactions, scalable metadata handling, and unified streaming/batch data processing to data lakes.

### The Problem Delta Lake Solves

Traditional Data Lakes suffer from:
```
┌─────────────────────────────────────────────────────────────┐
│                    Data Lake Challenges                      │
├─────────────────────────────────────────────────────────────┤
│ ❌ No ACID transactions → Partial writes, corruption        │
│ ❌ No schema enforcement → Garbage in, garbage out          │
│ ❌ No versioning → Can't rollback mistakes                  │
│ ❌ Complex streaming/batch → Separate pipelines needed      │
│ ❌ Small file problem → Poor query performance              │
└─────────────────────────────────────────────────────────────┘
```

Delta Lake Solution:
```
┌─────────────────────────────────────────────────────────────┐
│                    Delta Lake Features                       │
├─────────────────────────────────────────────────────────────┤
│ ✅ ACID Transactions → Reliable writes, no corruption       │
│ ✅ Schema Enforcement → Data quality guaranteed             │
│ ✅ Time Travel → Rollback and audit capabilities            │
│ ✅ Unified Batch/Streaming → Single pipeline                │
│ ✅ OPTIMIZE & Z-ORDER → Fast queries                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Delta Lake Architecture

### How Delta Lake Works

```
┌─────────────────────────────────────────────────────────────┐
│                     Delta Table                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   _delta_log/                    (Transaction Log)          │
│   ├── 00000000000000000000.json                             │
│   ├── 00000000000000000001.json                             │
│   ├── 00000000000000000002.json                             │
│   └── 00000000000000000010.checkpoint.parquet               │
│                                                              │
│   part-00000-xxx.parquet         (Data Files)               │
│   part-00001-xxx.parquet                                    │
│   part-00002-xxx.parquet                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Transaction Log: JSON files that record every change
- What files were added/removed
- Schema changes
- Transaction metadata
- Checkpoints every 10 commits (for faster reads)
```

---

## Basic Delta Lake Operations

### Creating Delta Tables

```python
from pyspark.sql import SparkSession
from delta import *

# Initialize Spark with Delta
spark = SparkSession.builder \
    .appName("DeltaLakeDemo") \
    .config("spark.jars.packages", "io.delta:delta-core_2.12:2.4.0") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", 
            "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

# Create sample data
data = [
    (1, "John", "Sales", 50000),
    (2, "Jane", "IT", 60000),
    (3, "Bob", "HR", 45000)
]
df = spark.createDataFrame(data, ["id", "name", "department", "salary"])

# Write as Delta table
df.write.format("delta").mode("overwrite").save("/delta/employees")

# Create managed Delta table
df.write.format("delta").saveAsTable("employees")

# Using SQL
spark.sql("""
    CREATE TABLE IF NOT EXISTS employees_sql (
        id INT,
        name STRING,
        department STRING,
        salary DOUBLE
    ) USING DELTA
    LOCATION '/delta/employees_sql'
""")
```

### Reading Delta Tables

```python
# Read Delta table
df = spark.read.format("delta").load("/delta/employees")

# Using table name
df = spark.table("employees")

# Using SQL
df = spark.sql("SELECT * FROM employees WHERE salary > 50000")
```

### Appending Data

```python
new_data = [
    (4, "Alice", "Finance", 55000),
    (5, "Charlie", "IT", 65000)
]
new_df = spark.createDataFrame(new_data, ["id", "name", "department", "salary"])

# Append mode
new_df.write.format("delta").mode("append").save("/delta/employees")
```

---

## ACID Transactions

### Atomicity Example

```python
# Transaction is all-or-nothing
try:
    # This entire operation either succeeds completely or fails completely
    df.write.format("delta").mode("overwrite").save("/delta/employees")
    print("Transaction successful")
except Exception as e:
    print(f"Transaction failed, no partial writes: {e}")
```

### Concurrent Writes

```python
# Delta Lake handles concurrent writes automatically
# Uses optimistic concurrency control

# Process 1: Update salaries
deltaTable = DeltaTable.forPath(spark, "/delta/employees")
deltaTable.update(
    condition="department = 'IT'",
    set={"salary": "salary * 1.1"}
)

# Process 2: Insert new records (can run concurrently!)
# Delta will handle conflicts automatically
```

---

## Time Travel

### Querying Historical Data

```python
# By version number
df_v0 = spark.read.format("delta") \
    .option("versionAsOf", 0) \
    .load("/delta/employees")

df_v2 = spark.read.format("delta") \
    .option("versionAsOf", 2) \
    .load("/delta/employees")

# By timestamp
df_yesterday = spark.read.format("delta") \
    .option("timestampAsOf", "2024-01-15 10:00:00") \
    .load("/delta/employees")

# Using SQL
spark.sql("""
    SELECT * FROM employees VERSION AS OF 0
""")

spark.sql("""
    SELECT * FROM employees TIMESTAMP AS OF '2024-01-15 10:00:00'
""")
```

### Viewing History

```python
from delta.tables import DeltaTable

deltaTable = DeltaTable.forPath(spark, "/delta/employees")

# View complete history
deltaTable.history().show()

# View last 10 operations
deltaTable.history(10).select(
    "version", "timestamp", "operation", "operationParameters"
).show(truncate=False)
```

### Restore to Previous Version

```python
# Restore to specific version
deltaTable.restoreToVersion(0)

# Restore to timestamp
deltaTable.restoreToTimestamp("2024-01-15 10:00:00")

# Using SQL
spark.sql("RESTORE TABLE employees TO VERSION AS OF 5")
```

---

## MERGE (Upsert) Operations

### Basic MERGE Pattern

```python
from delta.tables import DeltaTable

# Source: New/updated data
updates = [
    (1, "John", "Sales", 55000),     # Update existing
    (6, "Diana", "Marketing", 52000)  # Insert new
]
updates_df = spark.createDataFrame(updates, ["id", "name", "department", "salary"])

# Target: Existing Delta table
deltaTable = DeltaTable.forPath(spark, "/delta/employees")

# MERGE operation
deltaTable.alias("target").merge(
    updates_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdate(
    set={
        "name": "source.name",
        "department": "source.department",
        "salary": "source.salary"
    }
).whenNotMatchedInsert(
    values={
        "id": "source.id",
        "name": "source.name",
        "department": "source.department",
        "salary": "source.salary"
    }
).execute()
```

### Advanced MERGE with Conditions

```python
deltaTable.alias("target").merge(
    updates_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdate(
    condition="source.salary > target.salary",  # Only update if salary increased
    set={
        "salary": "source.salary"
    }
).whenMatchedDelete(
    condition="source.department = 'Terminated'"  # Delete terminated employees
).whenNotMatchedInsert(
    condition="source.department != 'Contractor'",  # Don't insert contractors
    values={
        "id": "source.id",
        "name": "source.name",
        "department": "source.department",
        "salary": "source.salary"
    }
).execute()
```

### Using SQL for MERGE

```sql
MERGE INTO target_table AS target
USING source_table AS source
ON target.id = source.id
WHEN MATCHED THEN
    UPDATE SET 
        target.name = source.name,
        target.salary = source.salary
WHEN NOT MATCHED THEN
    INSERT (id, name, department, salary)
    VALUES (source.id, source.name, source.department, source.salary)
```

---

## UPDATE and DELETE Operations

### UPDATE

```python
from delta.tables import DeltaTable

deltaTable = DeltaTable.forPath(spark, "/delta/employees")

# Update specific records
deltaTable.update(
    condition="department = 'IT'",
    set={"salary": "salary * 1.1"}
)

# Update all records
deltaTable.update(
    set={"salary": "salary * 1.05"}
)

# Using SQL
spark.sql("""
    UPDATE employees
    SET salary = salary * 1.1
    WHERE department = 'IT'
""")
```

### DELETE

```python
# Delete specific records
deltaTable.delete("department = 'Inactive'")

# Delete with complex condition
deltaTable.delete("salary < 30000 AND department = 'Temp'")

# Using SQL
spark.sql("""
    DELETE FROM employees
    WHERE department = 'Inactive'
""")
```

---

## Schema Evolution

### Enable Schema Merging

```python
# Add new columns automatically
new_data_with_bonus = [
    (7, "Eve", "Sales", 58000, 5000)  # New 'bonus' column
]
new_df = spark.createDataFrame(
    new_data_with_bonus, 
    ["id", "name", "department", "salary", "bonus"]
)

# Enable mergeSchema
new_df.write.format("delta") \
    .mode("append") \
    .option("mergeSchema", "true") \
    .save("/delta/employees")
```

### Schema Enforcement

```python
# By default, Delta enforces schema
# Writing incompatible schema will fail
try:
    wrong_schema_df.write.format("delta") \
        .mode("append") \
        .save("/delta/employees")
except Exception as e:
    print(f"Schema mismatch: {e}")

# Override schema completely
df.write.format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .save("/delta/employees")
```

---

## Performance Optimization

### OPTIMIZE (Compaction)

```python
# Compact small files
spark.sql("OPTIMIZE employees")

# Or using Python API
deltaTable.optimize().executeCompaction()

# OPTIMIZE with Z-ORDER (for faster queries on specific columns)
spark.sql("OPTIMIZE employees ZORDER BY (department, salary)")

# Python API
deltaTable.optimize().executeZOrderBy("department", "salary")
```

### VACUUM (Cleanup Old Files)

```python
# Remove files older than 7 days (default)
spark.sql("VACUUM employees")

# Remove files older than specified hours
spark.sql("VACUUM employees RETAIN 168 HOURS")  # 7 days

# Python API
deltaTable.vacuum(retentionHours=168)

# WARNING: Files removed by VACUUM cannot be used for time travel!
```

### Auto Optimization

```python
# Enable auto compaction
spark.conf.set("spark.databricks.delta.autoCompact.enabled", "true")

# Enable optimized writes
spark.conf.set("spark.databricks.delta.optimizeWrite.enabled", "true")

# Or in table properties
spark.sql("""
    ALTER TABLE employees 
    SET TBLPROPERTIES (
        'delta.autoOptimize.autoCompact' = 'true',
        'delta.autoOptimize.optimizeWrite' = 'true'
    )
""")
```

---

## Medallion Architecture

### Bronze → Silver → Gold Pattern

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   BRONZE    │     │   SILVER    │     │    GOLD     │
│  (Raw Data) │ --> │  (Cleaned)  │ --> │ (Business)  │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ - Raw ingest│     │ - Validated │     │ - Aggregated│
│ - As-is     │     │ - Deduplicated│   │ - Joined    │
│ - Append-only│    │ - Standardized│   │ - Ready for │
│             │     │ - Type-safe  │    │   Analytics │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Implementation Example

```python
# BRONZE: Raw data ingestion
def ingest_to_bronze(source_path, bronze_path):
    df = spark.read.json(source_path)
    
    # Add metadata
    df = df.withColumn("_ingestion_timestamp", current_timestamp())
    df = df.withColumn("_source_file", input_file_name())
    
    # Append to Bronze (never overwrite raw data)
    df.write.format("delta") \
        .mode("append") \
        .save(bronze_path)

# SILVER: Clean and validate
def bronze_to_silver(bronze_path, silver_path):
    bronze_df = spark.read.format("delta").load(bronze_path)
    
    silver_df = bronze_df \
        .dropDuplicates(["id"]) \
        .filter(col("id").isNotNull()) \
        .withColumn("name", trim(col("name"))) \
        .withColumn("salary", col("salary").cast("double")) \
        .withColumn("_processed_timestamp", current_timestamp())
    
    # MERGE for incremental updates
    if DeltaTable.isDeltaTable(spark, silver_path):
        deltaTable = DeltaTable.forPath(spark, silver_path)
        deltaTable.alias("target").merge(
            silver_df.alias("source"),
            "target.id = source.id"
        ).whenMatchedUpdateAll() \
         .whenNotMatchedInsertAll() \
         .execute()
    else:
        silver_df.write.format("delta").save(silver_path)

# GOLD: Business-ready aggregations
def silver_to_gold(silver_path, gold_path):
    silver_df = spark.read.format("delta").load(silver_path)
    
    gold_df = silver_df.groupBy("department").agg(
        count("*").alias("employee_count"),
        avg("salary").alias("avg_salary"),
        sum("salary").alias("total_salary"),
        max("salary").alias("max_salary")
    )
    
    gold_df.write.format("delta") \
        .mode("overwrite") \
        .save(gold_path)
```

---

## 📚 Interview Questions (10 Q&A)

### Q1: What is Delta Lake and why would you use it?
**Answer**: Delta Lake is an open-source storage layer that brings reliability to data lakes. It adds:
- **ACID transactions**: Ensures data integrity with atomic commits
- **Schema enforcement**: Prevents corrupt data from entering
- **Time travel**: Query historical versions of data
- **Unified batch/streaming**: Single pipeline for both
- **MERGE/UPDATE/DELETE**: Data lake becomes mutable like a database

Use it when you need reliable, transactional data processing at scale.

### Q2: How does Delta Lake achieve ACID transactions?
**Answer**: Delta Lake uses a **transaction log** (`_delta_log/`) that records every change:
1. Before writing, it writes a JSON file describing the change
2. Uses **optimistic concurrency control** for concurrent writes
3. If a conflict occurs, it fails the transaction (no partial writes)
4. Readers always see a consistent snapshot (isolation)
5. Checkpoints every 10 commits for faster reads

### Q3: What is Time Travel and give a use case?
**Answer**: Time Travel allows querying historical versions of data:
```python
df = spark.read.format("delta").option("versionAsOf", 5).load(path)
```

**Use cases**:
- **Audit trails**: See what data looked like at any point
- **Rollback mistakes**: Restore accidentally deleted data
- **Debugging**: Compare before/after a pipeline run
- **Reproducibility**: Recreate ML models with exact training data

### Q4: Explain the MERGE operation in Delta Lake.
**Answer**: MERGE (upsert) combines INSERT, UPDATE, and DELETE in one atomic operation:
```python
deltaTable.alias("target").merge(
    source_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdate(set={"name": "source.name"})
 .whenNotMatchedInsert(values={"id": "source.id", "name": "source.name"})
 .execute()
```

It's useful for:
- Incremental data loading
- Slowly Changing Dimensions (SCD Type 1 and 2)
- Deduplication

### Q5: What is the Medallion Architecture?
**Answer**: A data design pattern with three layers:
- **Bronze**: Raw data, append-only, preserves original
- **Silver**: Cleaned, validated, deduplicated, standardized
- **Gold**: Business-ready aggregations and joins

Benefits: Clear data lineage, easy debugging, reprocessing capability.

### Q6: How do you optimize Delta table performance?
**Answer**:
1. **OPTIMIZE**: Compacts small files into larger ones
2. **Z-ORDER**: Co-locates related data for faster filters
3. **VACUUM**: Removes old files (saves storage)
4. **Partitioning**: Partition by frequently filtered columns
5. **Auto-optimization**: Enable auto-compact and optimized writes

```python
spark.sql("OPTIMIZE table ZORDER BY (date, region)")
spark.sql("VACUUM table RETAIN 168 HOURS")
```

### Q7: What is schema evolution in Delta Lake?
**Answer**: Schema evolution allows the table schema to change over time:
- **mergeSchema**: Adds new columns automatically when appending
- **overwriteSchema**: Replaces schema entirely on overwrite

```python
df.write.format("delta").option("mergeSchema", "true").mode("append").save(path)
```

Useful when source schema changes (new fields added).

### Q8: How does Delta Lake handle concurrent writes?
**Answer**: Uses **optimistic concurrency control**:
1. Each write checks the current version
2. If version changed during write, it retries
3. If conflict can't be resolved, transaction fails
4. No data corruption from concurrent operations

This allows multiple jobs to write safely without locks.

### Q9: What is VACUUM and what are its implications?
**Answer**: VACUUM removes old data files no longer referenced by the transaction log:
```python
spark.sql("VACUUM table RETAIN 168 HOURS")  # 7 days
```

**Important implications**:
- Files removed by VACUUM cannot be used for time travel
- Default retention is 7 days (safety threshold)
- Set `spark.databricks.delta.retentionDurationCheck.enabled=false` to reduce below 7 days (dangerous!)

### Q10: How would you implement SCD Type 2 with Delta Lake?
**Answer**: Use MERGE with row versioning:
```python
deltaTable.alias("target").merge(
    source_df.alias("source"),
    "target.id = source.id AND target.is_current = true"
).whenMatchedUpdate(
    condition="target.hash != source.hash",  # Only if changed
    set={
        "is_current": "false",
        "end_date": "current_date()"
    }
).whenNotMatchedInsert(
    values={
        "id": "source.id",
        "name": "source.name",
        "is_current": "true",
        "start_date": "current_date()",
        "end_date": "lit('9999-12-31')"
    }
).execute()

# Insert new version for changed records
changed_records.write.format("delta").mode("append").save(path)
```

This maintains full history with current/historical flags.
