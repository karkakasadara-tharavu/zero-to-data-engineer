# Lab 03: DataFrame Transformations

## Overview
Master essential DataFrame transformations for data engineering pipelines.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Use select and selectExpr for column operations
- ✅ Filter data with where and filter
- ✅ Add and modify columns with withColumn
- ✅ Rename and drop columns
- ✅ Apply sorting and limiting

---

## Part 1: Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("DataFrame Transformations") \
    .master("local[*]") \
    .getOrCreate()

# Create sample employee data
data = [
    (1, "Alice", "Engineering", 75000, "2020-01-15"),
    (2, "Bob", "Marketing", 55000, "2019-03-22"),
    (3, "Charlie", "Engineering", 82000, "2018-07-10"),
    (4, "Diana", "Sales", 65000, "2021-02-28"),
    (5, "Eve", "Engineering", 90000, "2017-11-05"),
    (6, "Frank", "Marketing", 48000, "2022-06-14"),
    (7, "Grace", "Sales", 72000, "2019-09-30"),
    (8, "Henry", "HR", 58000, "2020-04-18")
]

schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("department", StringType(), False),
    StructField("salary", IntegerType(), False),
    StructField("hire_date", StringType(), False)
])

df = spark.createDataFrame(data, schema)
df.show()
```

---

## Part 2: Select Operations

### Step 2.1: Basic Select
```python
# Select specific columns
df.select("name", "department").show()

# Using col() function
from pyspark.sql.functions import col
df.select(col("name"), col("salary")).show()

# Using df[] notation
df.select(df["name"], df["salary"]).show()
```

### Step 2.2: Select with Expressions
```python
from pyspark.sql.functions import col, lit, concat

# Select with computed columns
df.select(
    col("name"),
    col("salary"),
    (col("salary") * 1.1).alias("salary_with_raise"),
    (col("salary") / 12).alias("monthly_salary")
).show()

# Using selectExpr for SQL-like expressions
df.selectExpr(
    "name",
    "salary",
    "salary * 1.1 as salary_with_raise",
    "UPPER(department) as dept_upper"
).show()
```

### Step 2.3: Select All with Modifications
```python
# Select all columns plus new ones
df.select(
    "*",
    (col("salary") * 12).alias("annual_salary")
).show()
```

---

## Part 3: Filtering Data

### Step 3.1: Basic Filtering
```python
# Using filter
df.filter(col("salary") > 60000).show()

# Using where (identical to filter)
df.where(col("salary") > 60000).show()

# String condition
df.filter("salary > 60000").show()
```

### Step 3.2: Multiple Conditions
```python
from pyspark.sql.functions import col

# AND condition
df.filter(
    (col("salary") > 60000) & 
    (col("department") == "Engineering")
).show()

# OR condition
df.filter(
    (col("department") == "Engineering") | 
    (col("department") == "Sales")
).show()

# NOT condition
df.filter(~(col("department") == "HR")).show()
```

### Step 3.3: Advanced Filtering
```python
from pyspark.sql.functions import col

# IN clause
df.filter(
    col("department").isin("Engineering", "Sales")
).show()

# LIKE pattern
df.filter(col("name").like("A%")).show()

# BETWEEN
df.filter(col("salary").between(50000, 70000)).show()

# NULL checks
df.filter(col("department").isNull()).show()
df.filter(col("department").isNotNull()).show()
```

---

## Part 4: Adding and Modifying Columns

### Step 4.1: withColumn Basics
```python
from pyspark.sql.functions import col, lit, upper, lower

# Add new column with literal value
df_with_country = df.withColumn("country", lit("USA"))
df_with_country.show()

# Add computed column
df_with_bonus = df.withColumn(
    "bonus",
    col("salary") * 0.1
)
df_with_bonus.show()
```

### Step 4.2: Multiple Columns
```python
from pyspark.sql.functions import col, lit, when, to_date

# Add multiple columns
df_enriched = df \
    .withColumn("bonus", col("salary") * 0.1) \
    .withColumn("total_comp", col("salary") + col("salary") * 0.1) \
    .withColumn("hire_date_parsed", to_date(col("hire_date"), "yyyy-MM-dd"))

df_enriched.show()
```

### Step 4.3: Conditional Columns (CASE WHEN)
```python
from pyspark.sql.functions import when, col

# Single condition
df_with_level = df.withColumn(
    "level",
    when(col("salary") >= 80000, "Senior")
    .when(col("salary") >= 60000, "Mid")
    .otherwise("Junior")
)
df_with_level.show()
```

---

## Part 5: Renaming and Dropping Columns

### Step 5.1: Renaming Columns
```python
# Single column rename
df_renamed = df.withColumnRenamed("name", "employee_name")
df_renamed.show()

# Multiple renames
df_renamed = df \
    .withColumnRenamed("name", "employee_name") \
    .withColumnRenamed("department", "dept") \
    .withColumnRenamed("salary", "base_salary")
df_renamed.show()

# Rename all columns at once
new_names = ["emp_id", "emp_name", "dept", "sal", "start_date"]
df_all_renamed = df.toDF(*new_names)
df_all_renamed.show()
```

### Step 5.2: Dropping Columns
```python
# Drop single column
df_dropped = df.drop("hire_date")
df_dropped.show()

# Drop multiple columns
df_dropped = df.drop("hire_date", "id")
df_dropped.show()
```

---

## Part 6: Sorting Data

### Step 6.1: Basic Sorting
```python
from pyspark.sql.functions import col, asc, desc

# Ascending sort (default)
df.orderBy("salary").show()

# Descending sort
df.orderBy(col("salary").desc()).show()
df.orderBy(desc("salary")).show()
```

### Step 6.2: Multi-Column Sort
```python
# Sort by multiple columns
df.orderBy(
    col("department").asc(),
    col("salary").desc()
).show()

# Using sort (alias for orderBy)
df.sort("department", desc("salary")).show()
```

---

## Part 7: Limiting Results

```python
# Limit number of rows
df.limit(5).show()

# First N rows as Python list
first_3 = df.take(3)
print(first_3)

# First row
first = df.first()
print(first)

# Head
head_rows = df.head(5)
print(head_rows)
```

---

## Part 8: Distinct and Duplicates

```python
# Get distinct values
df.select("department").distinct().show()

# Count distinct
distinct_count = df.select("department").distinct().count()
print(f"Distinct departments: {distinct_count}")

# Drop duplicates
df_no_dups = df.dropDuplicates(["department"])
df_no_dups.show()
```

---

## Part 9: Combined Transformation Pipeline

```python
from pyspark.sql.functions import col, when, upper, to_date, round

# Complete transformation pipeline
result = df \
    .filter(col("salary") >= 50000) \
    .withColumn("dept_upper", upper(col("department"))) \
    .withColumn("level", 
        when(col("salary") >= 80000, "Senior")
        .when(col("salary") >= 60000, "Mid")
        .otherwise("Junior")) \
    .withColumn("monthly_salary", round(col("salary") / 12, 2)) \
    .select(
        "id", "name", "dept_upper", 
        "salary", "monthly_salary", "level"
    ) \
    .orderBy(desc("salary")) \
    .limit(5)

result.show()
```

**Output:**
```
+---+-------+------------+------+--------------+------+
| id|   name|  dept_upper|salary|monthly_salary| level|
+---+-------+------------+------+--------------+------+
|  5|    Eve| ENGINEERING| 90000|       7500.00|Senior|
|  3|Charlie| ENGINEERING| 82000|       6833.33|Senior|
|  1|  Alice| ENGINEERING| 75000|        6250.0|   Mid|
|  7|  Grace|       SALES| 72000|        6000.0|   Mid|
|  4|  Diana|       SALES| 65000|       5416.67|   Mid|
+---+-------+------------+------+--------------+------+
```

---

## Exercises

1. Filter employees hired after 2020 with salary > 60000
2. Add a tax column (30% of salary) and net salary column
3. Create a seniority column based on hire date
4. Find top 3 highest paid employees per department

---

## Summary
- `select()` for column selection and expressions
- `filter()/where()` for row filtering
- `withColumn()` for adding/modifying columns
- `when().otherwise()` for conditional logic
- Chain transformations for complex pipelines
