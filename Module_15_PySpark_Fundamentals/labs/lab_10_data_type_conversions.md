# Lab 10: Data Type Conversions

## Overview
Master data type conversions and casting in PySpark for data engineering pipelines.

**Duration**: 2 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Cast between data types
- ✅ Handle date and timestamp conversions
- ✅ Convert between complex types
- ✅ Parse strings to structured data
- ✅ Handle conversion errors

---

## Part 1: Basic Type Casting

### Step 1.1: Using cast()
```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, cast
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Type Conversions") \
    .master("local[*]") \
    .getOrCreate()

# Sample data with string types
data = [
    ("1", "Alice", "75000.50", "true"),
    ("2", "Bob", "65000.00", "false"),
    ("3", "Charlie", "82000.75", "true"),
]

df = spark.createDataFrame(data, ["id", "name", "salary", "active"])
df.printSchema()
```

**Output:**
```
root
 |-- id: string (nullable = true)
 |-- name: string (nullable = true)
 |-- salary: string (nullable = true)
 |-- active: string (nullable = true)
```

### Step 1.2: Cast to Correct Types
```python
# Method 1: Using cast()
df_casted = df \
    .withColumn("id", col("id").cast(IntegerType())) \
    .withColumn("salary", col("salary").cast(DoubleType())) \
    .withColumn("active", col("active").cast(BooleanType()))

df_casted.printSchema()
df_casted.show()

# Method 2: Using cast with string type names
df_casted = df \
    .withColumn("id", col("id").cast("int")) \
    .withColumn("salary", col("salary").cast("double")) \
    .withColumn("active", col("active").cast("boolean"))

# Method 3: Using selectExpr
df_casted = df.selectExpr(
    "CAST(id AS INT) as id",
    "name",
    "CAST(salary AS DOUBLE) as salary",
    "CAST(active AS BOOLEAN) as active"
)
```

---

## Part 2: Numeric Conversions

### Step 2.1: Integer Types
```python
from pyspark.sql.functions import col
from pyspark.sql.types import ByteType, ShortType, IntegerType, LongType

data = [(1, 100, 10000, 1000000000)]
df = spark.createDataFrame(data, ["tiny", "small", "medium", "large"])

# Convert to specific integer types
df_typed = df \
    .withColumn("tiny_byte", col("tiny").cast(ByteType())) \
    .withColumn("small_short", col("small").cast(ShortType())) \
    .withColumn("medium_int", col("medium").cast(IntegerType())) \
    .withColumn("large_long", col("large").cast(LongType()))

df_typed.printSchema()
```

### Step 2.2: Floating Point Types
```python
from pyspark.sql.types import FloatType, DoubleType, DecimalType

data = [(3.14159265358979, "123.456789")]
df = spark.createDataFrame(data, ["pi", "decimal_str"])

df_typed = df \
    .withColumn("pi_float", col("pi").cast(FloatType())) \
    .withColumn("pi_double", col("pi").cast(DoubleType())) \
    .withColumn("decimal_val", col("decimal_str").cast(DecimalType(10, 4)))

df_typed.show()
df_typed.printSchema()
```

### Step 2.3: Handling Precision
```python
from pyspark.sql.functions import round, floor, ceil, bround

data = [(3.14159, 2.5, 3.5)]
df = spark.createDataFrame(data, ["pi", "half1", "half2"])

df_rounded = df.select(
    round("pi", 2).alias("rounded"),
    floor("pi").alias("floored"),
    ceil("pi").alias("ceiled"),
    bround("half1", 0).alias("banker_round1"),  # Banker's rounding
    bround("half2", 0).alias("banker_round2")
)
df_rounded.show()
```

---

## Part 3: String Conversions

### Step 3.1: To String
```python
from pyspark.sql.functions import format_number, format_string, concat

data = [(12345.6789, 1000000)]
df = spark.createDataFrame(data, ["value", "count"])

df_formatted = df.select(
    col("value").cast("string").alias("as_string"),
    format_number("value", 2).alias("formatted"),  # 12,345.68
    format_string("Count: %d", "count").alias("formatted_str")
)
df_formatted.show()
```

### Step 3.2: From String
```python
from pyspark.sql.functions import regexp_extract, regexp_replace

data = [
    ("Price: $1,234.56", "Order #12345"),
    ("Price: $999.00", "Order #67890"),
]
df = spark.createDataFrame(data, ["price_str", "order_str"])

# Extract numbers from strings
df_extracted = df \
    .withColumn(
        "price", 
        regexp_replace(
            regexp_extract("price_str", r"\$([\d,]+\.?\d*)", 1),
            ",", ""
        ).cast("double")
    ) \
    .withColumn(
        "order_num",
        regexp_extract("order_str", r"#(\d+)", 1).cast("int")
    )

df_extracted.show()
```

---

## Part 4: Date and Timestamp Conversions

### Step 4.1: String to Date
```python
from pyspark.sql.functions import to_date, to_timestamp

data = [
    ("2024-01-15", "2024-01-15 10:30:45", "01/15/2024"),
    ("2024-02-20", "2024-02-20 14:45:30", "02/20/2024"),
]
df = spark.createDataFrame(data, ["date_iso", "timestamp_str", "date_us"])

# Parse dates
df_parsed = df \
    .withColumn("date1", to_date("date_iso")) \
    .withColumn("timestamp1", to_timestamp("timestamp_str")) \
    .withColumn("date_custom", to_date("date_us", "MM/dd/yyyy"))

df_parsed.printSchema()
df_parsed.show()
```

### Step 4.2: Date to String
```python
from pyspark.sql.functions import date_format

df_formatted = df_parsed.select(
    "date1",
    date_format("date1", "MMMM dd, yyyy").alias("long_format"),
    date_format("date1", "MM/dd/yy").alias("short_format"),
    date_format("date1", "E, MMM dd").alias("weekday_format"),
    date_format("timestamp1", "yyyy-MM-dd HH:mm:ss").alias("ts_format")
)
df_formatted.show(truncate=False)
```

### Step 4.3: Unix Timestamp
```python
from pyspark.sql.functions import unix_timestamp, from_unixtime

data = [
    ("2024-01-15 10:30:00",),
    ("2024-02-20 14:45:00",),
]
df = spark.createDataFrame(data, ["timestamp_str"])

df_unix = df \
    .withColumn("unix_ts", unix_timestamp("timestamp_str")) \
    .withColumn("back_to_ts", from_unixtime("unix_ts"))

df_unix.show()
```

### Step 4.4: Date Components
```python
from pyspark.sql.functions import (
    year, month, dayofmonth, dayofweek, dayofyear,
    weekofyear, quarter, hour, minute, second
)

df_components = df_parsed.select(
    "timestamp1",
    year("timestamp1").alias("year"),
    month("timestamp1").alias("month"),
    dayofmonth("timestamp1").alias("day"),
    dayofweek("timestamp1").alias("dow"),  # 1=Sunday
    hour("timestamp1").alias("hour"),
    minute("timestamp1").alias("minute"),
    quarter("timestamp1").alias("quarter")
)
df_components.show()
```

---

## Part 5: Complex Type Conversions

### Step 5.1: Array Operations
```python
from pyspark.sql.functions import array, split, concat_ws, array_join

# String to Array
data = [
    ("apple,banana,orange",),
    ("grape,mango",),
]
df = spark.createDataFrame(data, ["fruits_str"])

df_array = df.withColumn("fruits_array", split("fruits_str", ","))
df_array.show(truncate=False)

# Array to String
df_back = df_array.withColumn(
    "fruits_joined",
    array_join("fruits_array", " | ")
)
df_back.show(truncate=False)
```

### Step 5.2: Struct Operations
```python
from pyspark.sql.functions import struct, col

data = [
    ("Alice", "Smith", 75000),
    ("Bob", "Johnson", 65000),
]
df = spark.createDataFrame(data, ["first_name", "last_name", "salary"])

# Create struct
df_struct = df.withColumn(
    "person",
    struct(
        col("first_name").alias("first"),
        col("last_name").alias("last"),
        col("salary")
    )
)
df_struct.printSchema()
df_struct.show()

# Access struct fields
df_struct.select(
    "person.first",
    "person.last",
    "person.salary"
).show()
```

### Step 5.3: JSON Operations
```python
from pyspark.sql.functions import to_json, from_json, schema_of_json

# Struct to JSON
df_json = df_struct.withColumn("person_json", to_json("person"))
df_json.select("person_json").show(truncate=False)

# JSON to Struct
json_data = [
    ('{"name": "Alice", "age": 30}',),
    ('{"name": "Bob", "age": 25}',),
]
df_with_json = spark.createDataFrame(json_data, ["json_str"])

# Define schema
json_schema = StructType([
    StructField("name", StringType(), True),
    StructField("age", IntegerType(), True)
])

df_parsed = df_with_json.withColumn(
    "parsed",
    from_json("json_str", json_schema)
)
df_parsed.select("parsed.name", "parsed.age").show()
```

---

## Part 6: Handling Conversion Errors

### Step 6.1: Safe Casting
```python
# Invalid values become NULL on cast
data = [
    ("123", "456.78"),
    ("abc", "invalid"),
    ("789", "123.45"),
]
df = spark.createDataFrame(data, ["int_str", "float_str"])

# Cast will return NULL for invalid values
df_casted = df \
    .withColumn("int_val", col("int_str").cast("int")) \
    .withColumn("float_val", col("float_str").cast("double"))

df_casted.show()
```

**Output:**
```
+-------+---------+-------+---------+
|int_str|float_str|int_val|float_val|
+-------+---------+-------+---------+
|    123|   456.78|    123|   456.78|
|    abc|  invalid|   null|     null|  <- Invalid values become NULL
|    789|   123.45|    789|   123.45|
+-------+---------+-------+---------+
```

### Step 6.2: Validate Before Cast
```python
from pyspark.sql.functions import when, col

# Check if value is numeric before casting
df_validated = df \
    .withColumn(
        "int_val",
        when(
            col("int_str").rlike("^-?\\d+$"),
            col("int_str").cast("int")
        ).otherwise(None)
    ) \
    .withColumn(
        "is_valid",
        col("int_val").isNotNull()
    )

df_validated.show()
```

### Step 6.3: Try-Parse Pattern
```python
from pyspark.sql.functions import coalesce, lit

# Try to parse date with multiple formats
data = [
    ("2024-01-15",),
    ("01/15/2024",),
    ("15-Jan-2024",),
]
df = spark.createDataFrame(data, ["date_str"])

df_parsed = df.withColumn(
    "parsed_date",
    coalesce(
        to_date("date_str", "yyyy-MM-dd"),
        to_date("date_str", "MM/dd/yyyy"),
        to_date("date_str", "dd-MMM-yyyy")
    )
)
df_parsed.show()
```

---

## Part 7: Complete Conversion Pipeline

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder.appName("Conversion Pipeline").master("local[*]").getOrCreate()

# Raw data (all strings, like from CSV)
raw_data = [
    ("1", "Alice Smith", "75000.50", "2024-01-15", "true", '{"dept":"Engineering"}'),
    ("2", "Bob Johnson", "65000.00", "2024-02-20", "false", '{"dept":"Marketing"}'),
    ("invalid", "Charlie Brown", "abc", "invalid-date", "maybe", '{"dept":"Sales"}'),
]

df = spark.createDataFrame(raw_data, 
    ["id", "name", "salary", "hire_date", "active", "metadata"])

# Define JSON schema
meta_schema = StructType([StructField("dept", StringType(), True)])

# Complete transformation
df_clean = df \
    .withColumn("id", col("id").cast("int")) \
    .withColumn("salary", col("salary").cast("double")) \
    .withColumn("hire_date", to_date("hire_date", "yyyy-MM-dd")) \
    .withColumn("active", col("active").cast("boolean")) \
    .withColumn("metadata_parsed", from_json("metadata", meta_schema)) \
    .withColumn("first_name", split("name", " ")[0]) \
    .withColumn("last_name", split("name", " ")[1]) \
    .withColumn("is_valid", 
        col("id").isNotNull() & 
        col("salary").isNotNull() & 
        col("hire_date").isNotNull()
    )

df_clean.show()
df_clean.printSchema()

# Filter valid records
df_valid = df_clean.filter("is_valid = true")
df_invalid = df_clean.filter("is_valid = false")

print(f"Valid records: {df_valid.count()}")
print(f"Invalid records: {df_invalid.count()}")
```

---

## Exercises

1. Convert a CSV with mixed date formats to standardized dates
2. Parse JSON columns into structured types
3. Handle numeric strings with currency symbols
4. Create a validation pipeline for data quality

---

## Summary
- Use `cast()` for basic type conversions
- `to_date()`/`to_timestamp()` for date parsing
- Invalid casts return NULL
- Use `coalesce()` for try-parse patterns
- `from_json()`/`to_json()` for JSON operations
- Always validate data before and after conversion
