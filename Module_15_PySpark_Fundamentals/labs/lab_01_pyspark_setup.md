# Lab 01: PySpark Setup and SparkSession

## Overview
Set up PySpark for data engineering workflows and master SparkSession configuration.

**Duration**: 2 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Configure PySpark for data engineering
- ✅ Understand SparkSession vs SparkContext
- ✅ Set up optimal configurations
- ✅ Use PySpark in Jupyter notebooks

---

## Part 1: PySpark Installation

### Step 1.1: Install PySpark
```bash
# Create virtual environment
python -m venv pyspark_env
source pyspark_env/bin/activate  # Windows: pyspark_env\Scripts\activate

# Install PySpark
pip install pyspark==3.5.0
pip install jupyter pandas numpy
```

### Step 1.2: Verify Installation
```python
import pyspark
print(f"PySpark version: {pyspark.__version__}")
```

---

## Part 2: SparkSession Configuration

### Step 2.1: Basic SparkSession
```python
from pyspark.sql import SparkSession

# Basic session
spark = SparkSession.builder \
    .appName("PySpark Basics") \
    .master("local[*]") \
    .getOrCreate()

print(f"Spark Version: {spark.version}")
print(f"App Name: {spark.sparkContext.appName}")
```

### Step 2.2: Production Configuration
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Data Engineering Pipeline") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "8") \
    .config("spark.driver.memory", "4g") \
    .config("spark.executor.memory", "4g") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .getOrCreate()

# Set log level
spark.sparkContext.setLogLevel("WARN")
```

### Step 2.3: Key Configurations
| Configuration | Purpose | Default |
|---------------|---------|---------|
| `spark.sql.shuffle.partitions` | Partitions for shuffle operations | 200 |
| `spark.driver.memory` | Driver memory | 1g |
| `spark.executor.memory` | Executor memory | 1g |
| `spark.sql.adaptive.enabled` | Adaptive query execution | true |
| `spark.default.parallelism` | Default parallelism level | # cores |

---

## Part 3: SparkSession Methods

```python
# Access SparkContext
sc = spark.sparkContext

# Configuration
print(spark.conf.get("spark.sql.shuffle.partitions"))

# Catalog operations
spark.catalog.listDatabases()
spark.catalog.listTables()

# Create DataFrames
df = spark.createDataFrame([(1, "a"), (2, "b")], ["id", "value"])

# Read data
df_csv = spark.read.csv("data.csv", header=True)
df_parquet = spark.read.parquet("data.parquet")

# SQL operations
spark.sql("SELECT 1 + 1").show()

# Stop session
spark.stop()
```

---

## Exercises

1. Create a SparkSession with custom name and 4GB memory
2. Read a CSV file and display schema
3. Create a temp view and run SQL query
4. Verify the number of partitions

---

## Summary
- SparkSession is the entry point for PySpark
- Configure memory and partitions for performance
- Use `.getOrCreate()` for singleton pattern
- Always stop session when done
