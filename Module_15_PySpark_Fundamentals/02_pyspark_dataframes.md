# PySpark DataFrames - Complete Guide

## 📚 What You'll Learn
- Creating DataFrames from various sources
- Schema definition and data types
- DataFrame operations and methods
- Working with columns and rows
- Reading and writing data
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is a DataFrame?

### Definition
A **DataFrame** is a distributed collection of data organized into named columns. It's conceptually equivalent to a table in a relational database or a DataFrame in Python Pandas, but with optimizations for distributed computing.

```
┌─────────────────────────────────────────────────────────────────┐
│                         DataFrame                                │
├─────────────────────────────────────────────────────────────────┤
│  Schema:   [id: int, name: string, age: int, salary: double]    │
├─────────────────────────────────────────────────────────────────┤
│              Partition 1         Partition 2        Partition 3  │
│            ┌───────────┐       ┌───────────┐      ┌───────────┐ │
│            │ Row 1-100 │       │Row 101-200│      │Row 201-300│ │
│            │ (Node 1)  │       │ (Node 2)  │      │ (Node 3)  │ │
│            └───────────┘       └───────────┘      └───────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Creating DataFrames

### Method 1: From Python Collections

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *

spark = SparkSession.builder.appName("DataFrameDemo").getOrCreate()

# Simple list of tuples
data = [
    (1, "Alice", 30, 75000.0),
    (2, "Bob", 35, 85000.0),
    (3, "Charlie", 28, 65000.0)
]

# Create DataFrame with column names
df = spark.createDataFrame(data, ["id", "name", "age", "salary"])
df.show()

# Output:
# +---+-------+---+-------+
# | id|   name|age| salary|
# +---+-------+---+-------+
# |  1|  Alice| 30|75000.0|
# |  2|    Bob| 35|85000.0|
# |  3|Charlie| 28|65000.0|
# +---+-------+---+-------+
```

### Method 2: With Explicit Schema

```python
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DoubleType

# Define schema explicitly
schema = StructType([
    StructField("id", IntegerType(), nullable=False),
    StructField("name", StringType(), nullable=True),
    StructField("age", IntegerType(), nullable=True),
    StructField("salary", DoubleType(), nullable=True)
])

df = spark.createDataFrame(data, schema)
df.printSchema()

# Output:
# root
#  |-- id: integer (nullable = false)
#  |-- name: string (nullable = true)
#  |-- age: integer (nullable = true)
#  |-- salary: double (nullable = true)
```

### Method 3: From Pandas DataFrame

```python
import pandas as pd

# Create Pandas DataFrame
pandas_df = pd.DataFrame({
    'id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [30, 35, 28]
})

# Convert to Spark DataFrame
spark_df = spark.createDataFrame(pandas_df)

# Convert back to Pandas (be careful with large data!)
pandas_again = spark_df.toPandas()
```

### Method 4: From RDD

```python
# Create RDD first
rdd = spark.sparkContext.parallelize([
    (1, "Alice", 30),
    (2, "Bob", 35)
])

# Convert to DataFrame
df = rdd.toDF(["id", "name", "age"])
# OR
df = spark.createDataFrame(rdd, ["id", "name", "age"])
```

---

## 📁 Reading Data from Files

### CSV Files

```python
# Basic read
df = spark.read.csv("data.csv", header=True, inferSchema=True)

# With options
df = spark.read \
    .option("header", True) \
    .option("inferSchema", True) \
    .option("sep", ",") \
    .option("nullValue", "NA") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv("data.csv")

# Multiple files
df = spark.read.csv(["file1.csv", "file2.csv", "file3.csv"])

# Wildcard pattern
df = spark.read.csv("data/*.csv", header=True, inferSchema=True)
```

### JSON Files

```python
# Simple JSON
df = spark.read.json("data.json")

# Multiline JSON (single object spans multiple lines)
df = spark.read.option("multiline", True).json("data.json")

# With schema
df = spark.read.schema(schema).json("data.json")
```

### Parquet Files (Columnar format)

```python
# Parquet is the preferred format for Spark
df = spark.read.parquet("data.parquet")

# Read from partitioned directory
df = spark.read.parquet("data/year=2023/month=*")
```

### Database (JDBC)

```python
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:sqlserver://server:1433;databaseName=mydb") \
    .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
    .option("dbtable", "employees") \
    .option("user", "username") \
    .option("password", "password") \
    .load()
```

### Delta Lake

```python
# Read Delta format (requires delta-spark package)
df = spark.read.format("delta").load("delta_table_path")
```

---

## 📊 PySpark Data Types

```python
from pyspark.sql.types import *

# Common data types
IntegerType()      # 4-byte signed integer
LongType()         # 8-byte signed integer
FloatType()        # 4-byte floating point
DoubleType()       # 8-byte floating point
StringType()       # String/text
BooleanType()      # True/False
DateType()         # Date without time
TimestampType()    # Date with time
BinaryType()       # Byte array
DecimalType(10,2)  # Fixed precision decimal

# Complex types
ArrayType(StringType())                    # Array of strings
MapType(StringType(), IntegerType())       # Key-value pairs
StructType([                               # Nested structure
    StructField("field1", StringType()),
    StructField("field2", IntegerType())
])
```

### Example: Complex Schema

```python
schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("address", StructType([
        StructField("street", StringType(), True),
        StructField("city", StringType(), True),
        StructField("zip", StringType(), True)
    ])),
    StructField("phone_numbers", ArrayType(StringType()), True),
    StructField("attributes", MapType(StringType(), StringType()), True)
])
```

---

## 🔧 Basic DataFrame Operations

### Viewing Data

```python
# Show first 20 rows (default)
df.show()

# Show specific number of rows
df.show(10)

# Show without truncating columns
df.show(10, truncate=False)

# Show as vertical format
df.show(5, vertical=True)

# Print schema
df.printSchema()

# Column names
df.columns  # Returns ['id', 'name', 'age', 'salary']

# Data types
df.dtypes   # Returns [('id', 'int'), ('name', 'string'), ...]

# Count rows
df.count()

# Describe statistics
df.describe().show()  # count, mean, stddev, min, max

# First row
df.first()

# Take n rows
df.take(5)

# Collect all (careful with large data!)
df.collect()
```

### Selecting Columns

```python
from pyspark.sql.functions import col, column

# Single column (returns DataFrame)
df.select("name").show()

# Multiple columns
df.select("name", "age").show()

# Using col() function
df.select(col("name"), col("age")).show()

# Using df[column] syntax
df.select(df["name"], df["age"]).show()

# Using df.column syntax
df.select(df.name, df.age).show()

# Select all columns
df.select("*").show()

# Select with expression
df.select("name", (col("salary") * 1.1).alias("new_salary")).show()
```

### Filtering Rows

```python
from pyspark.sql.functions import col

# Using filter() or where() (they're the same)
df.filter(col("age") > 30).show()
df.where(col("age") > 30).show()

# Using string expression
df.filter("age > 30").show()

# Multiple conditions (AND)
df.filter((col("age") > 30) & (col("salary") > 70000)).show()

# Multiple conditions (OR)
df.filter((col("age") < 25) | (col("age") > 40)).show()

# NOT condition
df.filter(~(col("name") == "Alice")).show()

# In list
df.filter(col("name").isin(["Alice", "Bob"])).show()

# Like pattern
df.filter(col("name").like("A%")).show()

# Is null / not null
df.filter(col("salary").isNull()).show()
df.filter(col("salary").isNotNull()).show()

# Between
df.filter(col("age").between(25, 35)).show()
```

---

## ✏️ Column Operations

### Adding Columns

```python
from pyspark.sql.functions import col, lit, when

# Add column with constant value
df = df.withColumn("country", lit("USA"))

# Add column with calculation
df = df.withColumn("annual_bonus", col("salary") * 0.1)

# Conditional column
df = df.withColumn(
    "age_group",
    when(col("age") < 30, "Young")
    .when(col("age") < 40, "Middle")
    .otherwise("Senior")
)

# Type casting
df = df.withColumn("age_double", col("age").cast("double"))
```

### Renaming Columns

```python
# Rename single column
df = df.withColumnRenamed("name", "employee_name")

# Rename multiple columns
df = df.toDF("emp_id", "emp_name", "emp_age", "emp_salary")

# Using alias in select
df.select(col("name").alias("employee_name")).show()
```

### Dropping Columns

```python
# Drop single column
df = df.drop("column_name")

# Drop multiple columns
df = df.drop("col1", "col2", "col3")

# Drop using list
columns_to_drop = ["col1", "col2"]
df = df.drop(*columns_to_drop)
```

---

## 📤 Writing Data

### CSV

```python
df.write \
    .mode("overwrite") \
    .option("header", True) \
    .csv("output.csv")
```

### Parquet (Recommended)

```python
df.write \
    .mode("overwrite") \
    .parquet("output.parquet")

# Partitioned write
df.write \
    .partitionBy("year", "month") \
    .mode("overwrite") \
    .parquet("output_partitioned")
```

### JSON

```python
df.write.mode("overwrite").json("output.json")
```

### Database

```python
df.write \
    .format("jdbc") \
    .option("url", "jdbc:sqlserver://server:1433;databaseName=mydb") \
    .option("dbtable", "output_table") \
    .option("user", "username") \
    .option("password", "password") \
    .mode("overwrite") \
    .save()
```

### Write Modes

| Mode | Description |
|------|-------------|
| `append` | Add to existing data |
| `overwrite` | Replace existing data |
| `ignore` | Ignore if data exists |
| `error` (default) | Throw error if data exists |

---

## 🎓 Interview Questions

### Q1: What is a DataFrame in PySpark?
**A:** A DataFrame is a distributed collection of data organized into named columns, similar to a table in a relational database. It provides:
- **Schema**: Structured data with known types
- **Optimization**: Catalyst optimizer for query planning
- **Distribution**: Data partitioned across cluster
- **Interoperability**: SQL, Python, Scala, R APIs

### Q2: How do you create a DataFrame in PySpark?
**A:** Multiple ways:
1. `spark.createDataFrame(data, schema)` - from Python collections
2. `spark.read.csv/json/parquet()` - from files
3. `rdd.toDF()` - from RDD
4. `spark.createDataFrame(pandas_df)` - from Pandas
5. `spark.sql("SELECT * FROM table")` - from SQL query

### Q3: What's the difference between `filter()` and `where()`?
**A:** They are identical - `where()` is an alias for `filter()`. Both filter rows based on conditions.

### Q4: What is `inferSchema` and when should you use it?
**A:** `inferSchema=True` tells Spark to scan the data and infer column types automatically. Pros: convenient. Cons: slower (requires extra pass), might infer wrong types. For production, define explicit schema.

### Q5: How do you handle null values in PySpark?
**A:**
```python
# Check for nulls
df.filter(col("column").isNull())

# Drop rows with nulls
df.dropna()  # all nulls
df.dropna(subset=["col1", "col2"])  # specific columns

# Fill nulls
df.fillna(0)  # all columns with 0
df.fillna({"col1": 0, "col2": "Unknown"})  # specific values
```

### Q6: What is the difference between `select()` and `selectExpr()`?
**A:**
- `select()`: Takes Column objects or column names
- `selectExpr()`: Takes SQL expressions as strings
```python
df.select(col("salary") * 2)
df.selectExpr("salary * 2 as double_salary")
```

### Q7: What are the write modes in PySpark?
**A:**
- **append**: Add to existing data
- **overwrite**: Replace existing data
- **ignore**: Skip if exists
- **error/errorifexists**: Throw error if exists (default)

### Q8: Why is Parquet preferred over CSV in Spark?
**A:**
- **Columnar**: Only reads needed columns
- **Compressed**: Much smaller file size
- **Schema**: Preserves data types
- **Splittable**: Can be processed in parallel
- **Predicate pushdown**: Filters at file level

### Q9: How do you convert between Spark DataFrame and Pandas DataFrame?
**A:**
```python
# Spark to Pandas (be careful with large data!)
pandas_df = spark_df.toPandas()

# Pandas to Spark
spark_df = spark.createDataFrame(pandas_df)
```

### Q10: What is partitioning in DataFrame writes?
**A:** `partitionBy()` organizes output into subdirectories based on column values:
```python
df.write.partitionBy("year", "month").parquet("output")
# Creates: output/year=2023/month=01/, output/year=2023/month=02/, etc.
```
Benefits: Efficient reading (partition pruning), organized data, parallelized writes.

---

## 🔗 Related Topics
- [← Spark Architecture](./01_spark_architecture.md)
- [Transformations and Actions →](./03_transformations_actions.md)
- [Aggregations and GroupBy →](./04_aggregations.md)

---

*Next: Learn about Transformations and Actions in PySpark*
