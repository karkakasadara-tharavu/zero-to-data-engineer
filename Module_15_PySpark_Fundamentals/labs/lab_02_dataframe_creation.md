# Lab 02: DataFrame Creation and Schema

## Overview
Master creating PySpark DataFrames and defining schemas for structured data.

**Duration**: 2 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Create DataFrames from multiple sources
- ✅ Define explicit schemas
- ✅ Understand data types
- ✅ Infer vs explicit schemas

---

## Part 1: DataFrame from Python Collections

### Step 1.1: From List of Tuples
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("DataFrame Creation") \
    .master("local[*]") \
    .getOrCreate()

# Create from tuples
data = [
    (1, "Alice", 29, 50000.0),
    (2, "Bob", 34, 65000.0),
    (3, "Charlie", 28, 48000.0)
]
columns = ["id", "name", "age", "salary"]

df = spark.createDataFrame(data, columns)
df.show()
df.printSchema()
```

**Output:**
```
+---+-------+---+-------+
| id|   name|age| salary|
+---+-------+---+-------+
|  1|  Alice| 29|50000.0|
|  2|    Bob| 34|65000.0|
|  3|Charlie| 28|48000.0|
+---+-------+---+-------+

root
 |-- id: long (nullable = true)
 |-- name: string (nullable = true)
 |-- age: long (nullable = true)
 |-- salary: double (nullable = true)
```

### Step 1.2: From List of Dictionaries
```python
data = [
    {"id": 1, "name": "Alice", "department": "Engineering"},
    {"id": 2, "name": "Bob", "department": "Marketing"},
    {"id": 3, "name": "Charlie", "department": "Sales"}
]

df = spark.createDataFrame(data)
df.show()
```

### Step 1.3: From Pandas DataFrame
```python
import pandas as pd

pandas_df = pd.DataFrame({
    "product_id": [101, 102, 103],
    "product_name": ["Laptop", "Phone", "Tablet"],
    "price": [999.99, 499.99, 299.99]
})

df = spark.createDataFrame(pandas_df)
df.show()
```

---

## Part 2: Explicit Schema Definition

### Step 2.1: Using StructType
```python
from pyspark.sql.types import (
    StructType, StructField, 
    StringType, IntegerType, DoubleType, 
    DateType, BooleanType, ArrayType
)

# Define explicit schema
schema = StructType([
    StructField("employee_id", IntegerType(), nullable=False),
    StructField("first_name", StringType(), nullable=False),
    StructField("last_name", StringType(), nullable=False),
    StructField("age", IntegerType(), nullable=True),
    StructField("salary", DoubleType(), nullable=True),
    StructField("is_active", BooleanType(), nullable=True)
])

data = [
    (1, "John", "Doe", 30, 75000.0, True),
    (2, "Jane", "Smith", 28, 68000.0, True),
    (3, "Mike", "Johnson", 35, 82000.0, False)
]

df = spark.createDataFrame(data, schema)
df.printSchema()
```

**Output:**
```
root
 |-- employee_id: integer (nullable = false)
 |-- first_name: string (nullable = false)
 |-- last_name: string (nullable = false)
 |-- age: integer (nullable = true)
 |-- salary: double (nullable = true)
 |-- is_active: boolean (nullable = true)
```

### Step 2.2: DDL String Schema
```python
# Simpler schema definition using DDL string
schema_ddl = "id INT, name STRING, email STRING, created_date DATE"

data = [
    (1, "Alice", "alice@email.com", "2024-01-15"),
    (2, "Bob", "bob@email.com", "2024-02-20")
]

df = spark.createDataFrame(data, schema_ddl)
df.printSchema()
```

---

## Part 3: Complex Schema Types

### Step 3.1: Nested Structures
```python
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

# Nested schema
address_schema = StructType([
    StructField("street", StringType(), True),
    StructField("city", StringType(), True),
    StructField("zip_code", StringType(), True)
])

person_schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("address", address_schema, True)
])

data = [
    (1, "Alice", ("123 Main St", "New York", "10001")),
    (2, "Bob", ("456 Oak Ave", "Boston", "02101"))
]

df = spark.createDataFrame(data, person_schema)
df.show(truncate=False)
```

### Step 3.2: Array Types
```python
from pyspark.sql.types import ArrayType

schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("skills", ArrayType(StringType()), True)
])

data = [
    (1, "Alice", ["Python", "SQL", "Spark"]),
    (2, "Bob", ["Java", "Scala"]),
    (3, "Charlie", ["Python", "R", "Machine Learning"])
]

df = spark.createDataFrame(data, schema)
df.show(truncate=False)
```

**Output:**
```
+---+-------+----------------------------------+
|id |name   |skills                            |
+---+-------+----------------------------------+
|1  |Alice  |[Python, SQL, Spark]              |
|2  |Bob    |[Java, Scala]                     |
|3  |Charlie|[Python, R, Machine Learning]     |
+---+-------+----------------------------------+
```

### Step 3.3: Map Types
```python
from pyspark.sql.types import MapType

schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("properties", MapType(StringType(), StringType()), True)
])

data = [
    (1, "Product A", {"color": "red", "size": "large"}),
    (2, "Product B", {"color": "blue", "weight": "2kg"})
]

df = spark.createDataFrame(data, schema)
df.show(truncate=False)
```

---

## Part 4: Common Data Types Reference

| PySpark Type | Python Type | Example |
|--------------|-------------|---------|
| `StringType()` | str | "Hello" |
| `IntegerType()` | int | 42 |
| `LongType()` | int | 9223372036854775807 |
| `DoubleType()` | float | 3.14159 |
| `FloatType()` | float | 3.14 |
| `BooleanType()` | bool | True/False |
| `DateType()` | date | 2024-01-15 |
| `TimestampType()` | datetime | 2024-01-15 10:30:00 |
| `ArrayType()` | list | [1, 2, 3] |
| `MapType()` | dict | {"key": "value"} |
| `StructType()` | tuple/Row | (1, "a") |
| `DecimalType()` | Decimal | 123.45 |
| `BinaryType()` | bytes | b"data" |

---

## Exercises

1. Create a DataFrame with 5 columns of different types
2. Define a nested schema for an order with customer and items
3. Create a DataFrame with array and map columns
4. Convert a Pandas DataFrame with dates to PySpark

---

## Summary
- Use `spark.createDataFrame()` for all creation methods
- Define explicit schemas for production code
- StructType allows complex nested structures
- DDL strings provide quick schema definition
