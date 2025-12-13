# Lab 09: User-Defined Functions (UDFs)

## Overview
Create and use custom functions to extend PySpark's built-in capabilities.

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Create and register Python UDFs
- ✅ Use UDFs with DataFrames and SQL
- ✅ Understand UDF performance implications
- ✅ Implement Pandas UDFs for efficiency
- ✅ Handle null values in UDFs

---

## Part 1: Basic UDF Creation

### Step 1.1: Simple UDF
```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import udf, col
from pyspark.sql.types import StringType, IntegerType

spark = SparkSession.builder \
    .appName("UDFs") \
    .master("local[*]") \
    .getOrCreate()

# Create sample data
data = [
    (1, "Alice Smith", 75000),
    (2, "Bob Johnson", 65000),
    (3, "Charlie Brown", 82000),
]
df = spark.createDataFrame(data, ["id", "name", "salary"])

# Define a Python function
def get_first_name(full_name):
    if full_name:
        return full_name.split()[0]
    return None

# Convert to UDF
first_name_udf = udf(get_first_name, StringType())

# Apply UDF
df.withColumn("first_name", first_name_udf(col("name"))).show()
```

### Step 1.2: UDF with Decorator
```python
from pyspark.sql.functions import udf
from pyspark.sql.types import DoubleType

@udf(returnType=DoubleType())
def calculate_bonus(salary):
    if salary:
        if salary >= 80000:
            return salary * 0.15
        elif salary >= 60000:
            return salary * 0.10
        else:
            return salary * 0.05
    return 0.0

# Apply
df.withColumn("bonus", calculate_bonus(col("salary"))).show()
```

---

## Part 2: UDF Return Types

### Step 2.1: Primitive Types
```python
from pyspark.sql.types import (
    StringType, IntegerType, LongType, 
    DoubleType, FloatType, BooleanType
)

@udf(returnType=BooleanType())
def is_high_earner(salary):
    return salary >= 75000 if salary else False

@udf(returnType=IntegerType())
def salary_tier(salary):
    if salary >= 80000:
        return 3
    elif salary >= 60000:
        return 2
    return 1

df.withColumn("high_earner", is_high_earner(col("salary"))) \
  .withColumn("tier", salary_tier(col("salary"))) \
  .show()
```

### Step 2.2: Complex Return Types
```python
from pyspark.sql.types import StructType, StructField, StringType, ArrayType

# Return a struct
@udf(returnType=StructType([
    StructField("first", StringType(), True),
    StructField("last", StringType(), True)
]))
def split_name(full_name):
    if full_name:
        parts = full_name.split()
        return (parts[0], parts[-1] if len(parts) > 1 else "")
    return (None, None)

result = df.withColumn("name_parts", split_name(col("name")))
result.select("id", "name_parts.first", "name_parts.last").show()

# Return an array
@udf(returnType=ArrayType(StringType()))
def get_name_parts(full_name):
    if full_name:
        return full_name.split()
    return []

df.withColumn("name_array", get_name_parts(col("name"))).show()
```

---

## Part 3: Register UDF for SQL

### Step 3.1: Register UDF
```python
# Method 1: Using spark.udf.register
def calculate_tax(salary):
    if salary:
        return salary * 0.25
    return 0.0

spark.udf.register("calc_tax", calculate_tax, DoubleType())

# Create temp view
df.createOrReplaceTempView("employees")

# Use in SQL
spark.sql("""
    SELECT 
        name, 
        salary,
        calc_tax(salary) as tax
    FROM employees
""").show()
```

### Step 3.2: Lambda UDF
```python
# Register lambda as UDF
spark.udf.register(
    "format_salary", 
    lambda x: f"${x:,.2f}" if x else "$0.00", 
    StringType()
)

spark.sql("""
    SELECT name, format_salary(salary) as formatted
    FROM employees
""").show()
```

---

## Part 4: Handling Null Values

```python
from pyspark.sql.functions import when, col

# Option 1: Handle in UDF
@udf(returnType=StringType())
def safe_upper(text):
    if text is None:
        return None
    return text.upper()

# Option 2: Filter nulls before UDF
@udf(returnType=StringType())
def process_name(name):
    return name.upper()

# Apply only to non-null values
df.withColumn(
    "upper_name",
    when(col("name").isNotNull(), process_name(col("name")))
    .otherwise(None)
).show()
```

---

## Part 5: Pandas UDFs (Vectorized)

Pandas UDFs are much faster than regular UDFs because they process data in batches.

### Step 5.1: Scalar Pandas UDF
```python
import pandas as pd
from pyspark.sql.functions import pandas_udf
from pyspark.sql.types import DoubleType

# Pandas scalar UDF - processes Series
@pandas_udf(DoubleType())
def pandas_bonus(salary: pd.Series) -> pd.Series:
    return salary * 0.1

df.withColumn("bonus", pandas_bonus(col("salary"))).show()
```

### Step 5.2: Multiple Columns
```python
from pyspark.sql.functions import pandas_udf, struct
from pyspark.sql.types import DoubleType
import pandas as pd

@pandas_udf(DoubleType())
def total_compensation(salary: pd.Series, bonus_rate: pd.Series) -> pd.Series:
    return salary * (1 + bonus_rate)

# Create bonus rate column
df_with_rate = df.withColumn("bonus_rate", 
    when(col("salary") >= 75000, 0.15).otherwise(0.10)
)

df_with_rate.withColumn(
    "total_comp",
    total_compensation(col("salary"), col("bonus_rate"))
).show()
```

### Step 5.3: Grouped Map Pandas UDF
```python
from pyspark.sql.functions import pandas_udf, PandasUDFType

# For operations on grouped data
@pandas_udf(df.schema, PandasUDFType.GROUPED_MAP)
def normalize_salaries(pdf: pd.DataFrame) -> pd.DataFrame:
    pdf = pdf.copy()
    avg_salary = pdf['salary'].mean()
    pdf['salary'] = pdf['salary'] / avg_salary
    return pdf

# Apply to groups (need grouping column first)
df_with_dept = spark.createDataFrame([
    (1, "Alice", "Eng", 75000),
    (2, "Bob", "Eng", 65000),
    (3, "Charlie", "Sales", 82000),
], ["id", "name", "dept", "salary"])

# This would normalize salaries within each department
```

---

## Part 6: UDF Performance Tips

### Avoid UDFs When Possible
```python
from pyspark.sql.functions import split, upper, concat_ws

# BAD: UDF for simple operations
@udf(StringType())
def make_upper(text):
    return text.upper() if text else None

# GOOD: Use built-in functions
df.withColumn("upper_name", upper(col("name")))
```

### Use Pandas UDFs for Vectorized Operations
```python
# BAD: Row-by-row UDF
@udf(DoubleType())
def slow_calculation(x):
    return x * 1.1 + 100

# GOOD: Vectorized Pandas UDF
@pandas_udf(DoubleType())
def fast_calculation(x: pd.Series) -> pd.Series:
    return x * 1.1 + 100
```

### Broadcast Variables for Lookups
```python
# Create lookup dictionary
salary_grades = {
    (0, 50000): "A",
    (50000, 75000): "B",
    (75000, 100000): "C",
    (100000, float('inf')): "D"
}

# Broadcast it
broadcast_grades = spark.sparkContext.broadcast(salary_grades)

@udf(StringType())
def get_grade(salary):
    if salary is None:
        return None
    grades = broadcast_grades.value
    for (low, high), grade in grades.items():
        if low <= salary < high:
            return grade
    return "Unknown"

df.withColumn("grade", get_grade(col("salary"))).show()
```

---

## Part 7: Error Handling in UDFs

```python
import logging

@udf(StringType())
def safe_process(value):
    try:
        # Your processing logic
        if value is None:
            return None
        return value.upper()
    except Exception as e:
        # Log the error (visible in executor logs)
        logging.error(f"Error processing value: {value}, Error: {str(e)}")
        return None

# Or return error indicator
@udf(StructType([
    StructField("result", StringType(), True),
    StructField("error", StringType(), True)
]))
def process_with_error_info(value):
    try:
        return (value.upper() if value else None, None)
    except Exception as e:
        return (None, str(e))
```

---

## Part 8: Complete Example

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import udf, col, when
from pyspark.sql.types import *
import pandas as pd
from pyspark.sql.functions import pandas_udf

spark = SparkSession.builder.appName("UDF Demo").master("local[*]").getOrCreate()

# Sample data
employees = spark.createDataFrame([
    (1, "JOHN DOE", "Engineering", 85000, "2020-01-15"),
    (2, "jane smith", "Marketing", 62000, "2019-06-22"),
    (3, "Bob Johnson", "Engineering", 78000, "2021-03-10"),
    (4, "ALICE BROWN", "Sales", 55000, "2022-08-05"),
], ["id", "name", "department", "salary", "hire_date"])

# UDF to properly capitalize names
@udf(StringType())
def proper_case(name):
    if name:
        return ' '.join(word.capitalize() for word in name.lower().split())
    return None

# Pandas UDF for efficient bonus calculation
@pandas_udf(DoubleType())
def calculate_bonus_vectorized(salary: pd.Series) -> pd.Series:
    return salary * pd.Series([
        0.15 if s >= 80000 else 0.10 if s >= 60000 else 0.05
        for s in salary
    ])

# Apply transformations
result = employees \
    .withColumn("name_formatted", proper_case(col("name"))) \
    .withColumn("bonus", calculate_bonus_vectorized(col("salary"))) \
    .withColumn("total_comp", col("salary") + col("bonus"))

result.select("id", "name_formatted", "salary", "bonus", "total_comp").show()
```

---

## Exercises

1. Create a UDF to classify employees by tenure
2. Implement a Pandas UDF for complex calculations
3. Create a UDF that returns multiple values as a struct
4. Register a UDF for use in Spark SQL

---

## Summary
- Regular UDFs are simple but slow (serialize/deserialize)
- Pandas UDFs are much faster (vectorized)
- Always define return types explicitly
- Handle null values carefully
- Use built-in functions when possible
- Register UDFs for SQL use with `spark.udf.register()`
