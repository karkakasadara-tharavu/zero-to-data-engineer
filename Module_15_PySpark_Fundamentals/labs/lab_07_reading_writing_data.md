# Lab 07: Reading and Writing Data

## Overview
Master reading from and writing to various file formats for data engineering pipelines.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Read CSV, JSON, and Parquet files
- ✅ Handle schema inference and explicit schemas
- ✅ Write data in different formats
- ✅ Understand partitioning strategies
- ✅ Manage write modes

---

## Part 1: Setup and Sample Data

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Reading and Writing Data") \
    .master("local[*]") \
    .config("spark.sql.parquet.compression.codec", "snappy") \
    .getOrCreate()

# Create sample data
data = [
    (1, "Alice", "Engineering", 75000, "2020-01-15"),
    (2, "Bob", "Marketing", 65000, "2019-03-22"),
    (3, "Charlie", "Engineering", 82000, "2018-07-10"),
    (4, "Diana", "Sales", 58000, "2021-02-28"),
    (5, "Eve", "Engineering", 90000, "2017-11-05"),
]

df = spark.createDataFrame(
    data,
    ["id", "name", "department", "salary", "hire_date"]
)
df.show()
```

---

## Part 2: Reading CSV Files

### Step 2.1: Basic CSV Read
```python
# Basic read with header
df = spark.read.csv("data/employees.csv", header=True)
df.show()
df.printSchema()
```

### Step 2.2: CSV with Options
```python
# Read with multiple options
df = spark.read \
    .option("header", True) \
    .option("inferSchema", True) \
    .option("sep", ",") \
    .option("nullValue", "NA") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv("data/employees.csv")

df.printSchema()
```

### Step 2.3: CSV with Explicit Schema
```python
schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("department", StringType(), True),
    StructField("salary", DoubleType(), True),
    StructField("hire_date", DateType(), True)
])

df = spark.read \
    .option("header", True) \
    .option("dateFormat", "yyyy-MM-dd") \
    .schema(schema) \
    .csv("data/employees.csv")

df.printSchema()
```

### Common CSV Options
| Option | Description | Example |
|--------|-------------|---------|
| `header` | First row is header | `True/False` |
| `inferSchema` | Infer data types | `True/False` |
| `sep` | Field delimiter | `","`, `"\t"`, `"|"` |
| `nullValue` | Null representation | `"NA"`, `"null"`, `""` |
| `dateFormat` | Date parsing format | `"yyyy-MM-dd"` |
| `quote` | Quote character | `"\""` |
| `escape` | Escape character | `"\\"` |
| `multiLine` | Allow multiline values | `True/False` |
| `encoding` | Character encoding | `"UTF-8"` |

---

## Part 3: Reading JSON Files

### Step 3.1: Basic JSON Read
```python
# Single-line JSON (one object per line)
df = spark.read.json("data/employees.json")
df.show()
df.printSchema()
```

### Step 3.2: Multiline JSON
```python
# JSON array or pretty-printed JSON
df = spark.read \
    .option("multiLine", True) \
    .json("data/employees_pretty.json")

df.show()
```

### Step 3.3: JSON with Schema
```python
schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("details", StructType([
        StructField("department", StringType(), True),
        StructField("salary", DoubleType(), True)
    ]), True)
])

df = spark.read \
    .schema(schema) \
    .json("data/employees_nested.json")

df.printSchema()
```

---

## Part 4: Reading Parquet Files

### Step 4.1: Basic Parquet Read
```python
# Parquet preserves schema
df = spark.read.parquet("data/employees.parquet")
df.show()
df.printSchema()
```

### Step 4.2: Parquet Options
```python
# Read with specific columns (predicate pushdown)
df = spark.read \
    .option("mergeSchema", True) \
    .parquet("data/employees/")

# Read multiple paths
df = spark.read.parquet(
    "data/employees_2023.parquet",
    "data/employees_2024.parquet"
)
```

---

## Part 5: Writing CSV Files

### Step 5.1: Basic CSV Write
```python
df.write \
    .option("header", True) \
    .csv("output/employees_csv")
```

### Step 5.2: CSV with Options
```python
df.write \
    .mode("overwrite") \
    .option("header", True) \
    .option("sep", ",") \
    .option("nullValue", "NA") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv("output/employees_csv")
```

### Step 5.3: Single File Output
```python
# Coalesce to single file
df.coalesce(1) \
    .write \
    .mode("overwrite") \
    .option("header", True) \
    .csv("output/employees_single")
```

---

## Part 6: Writing JSON Files

```python
# Write JSON
df.write \
    .mode("overwrite") \
    .json("output/employees_json")

# Pretty print (not recommended for large files)
df.write \
    .mode("overwrite") \
    .option("pretty", True) \
    .json("output/employees_json_pretty")
```

---

## Part 7: Writing Parquet Files

### Step 7.1: Basic Parquet Write
```python
df.write \
    .mode("overwrite") \
    .parquet("output/employees_parquet")
```

### Step 7.2: Parquet with Compression
```python
# Available: snappy (default), gzip, lz4, zstd, uncompressed
df.write \
    .mode("overwrite") \
    .option("compression", "snappy") \
    .parquet("output/employees_parquet")
```

---

## Part 8: Partitioned Writes

### Step 8.1: Partition by Single Column
```python
# Partition by department
df.write \
    .mode("overwrite") \
    .partitionBy("department") \
    .parquet("output/employees_partitioned")

# Results in directory structure:
# output/employees_partitioned/
#   department=Engineering/
#     part-00000.parquet
#   department=Marketing/
#     part-00000.parquet
#   department=Sales/
#     part-00000.parquet
```

### Step 8.2: Multiple Partition Columns
```python
# Partition by year and month
from pyspark.sql.functions import year, month

df_with_date = df.withColumn(
    "hire_year", year("hire_date")
).withColumn(
    "hire_month", month("hire_date")
)

df_with_date.write \
    .mode("overwrite") \
    .partitionBy("hire_year", "hire_month") \
    .parquet("output/employees_date_partitioned")
```

### Step 8.3: Reading Partitioned Data
```python
# Reading respects partition pruning
df = spark.read.parquet("output/employees_partitioned")

# This only reads Engineering partition
df.filter(df.department == "Engineering").show()
```

---

## Part 9: Write Modes

| Mode | Description |
|------|-------------|
| `overwrite` | Replace existing data |
| `append` | Add to existing data |
| `ignore` | Skip if exists |
| `error`/`errorifexists` | Fail if exists (default) |

```python
# Overwrite
df.write.mode("overwrite").parquet("output/data")

# Append
df.write.mode("append").parquet("output/data")

# Ignore if exists
df.write.mode("ignore").parquet("output/data")
```

---

## Part 10: Other Formats

### Step 10.1: ORC
```python
# Read ORC
df = spark.read.orc("data/employees.orc")

# Write ORC
df.write.mode("overwrite").orc("output/employees_orc")
```

### Step 10.2: Delta Lake
```python
# Requires delta-spark package
# pip install delta-spark

# Write Delta
df.write.format("delta").mode("overwrite").save("output/employees_delta")

# Read Delta
df = spark.read.format("delta").load("output/employees_delta")
```

### Step 10.3: JDBC (Database)
```python
# Read from database
jdbc_url = "jdbc:postgresql://localhost:5432/mydb"
properties = {
    "user": "username",
    "password": "password",
    "driver": "org.postgresql.Driver"
}

df = spark.read.jdbc(jdbc_url, "employees", properties=properties)

# Write to database
df.write.jdbc(
    jdbc_url, 
    "employees_backup", 
    mode="overwrite",
    properties=properties
)
```

---

## Part 11: Best Practices

### File Format Selection
| Format | Use Case | Pros | Cons |
|--------|----------|------|------|
| CSV | Data exchange | Human readable | No schema, slow |
| JSON | Semi-structured | Flexible | Verbose, slow |
| Parquet | Analytics | Columnar, fast | Binary |
| ORC | Hive workloads | Compressed | Less common |
| Delta | Data lakes | ACID, versioning | Extra dependency |

### Schema Management
```python
# Always use explicit schemas in production
schema = StructType([...])

# Save schema
import json
schema_json = df.schema.json()
with open("schema.json", "w") as f:
    f.write(schema_json)

# Load schema
with open("schema.json", "r") as f:
    loaded_schema = StructType.fromJson(json.loads(f.read()))
```

---

## Exercises

1. Read a CSV with custom delimiter and null values
2. Write partitioned Parquet files by date
3. Compare read performance: CSV vs Parquet
4. Read JSON with nested structures

---

## Summary
- CSV for human-readable exchange
- JSON for semi-structured data
- Parquet for analytics (columnar, compressed)
- Use explicit schemas in production
- Partition data for better query performance
- Choose appropriate write mode
