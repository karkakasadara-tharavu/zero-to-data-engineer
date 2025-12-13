# Lab 03: Spark SQL Basics

## Overview
Learn to work with structured data using Spark SQL and DataFrames - the modern, optimized API for Spark data processing.

**Duration**: 3-4 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Prerequisites
- Labs 01-02 completed
- Basic SQL knowledge

---

## Learning Objectives
- ✅ Understand the relationship between RDDs and DataFrames
- ✅ Create DataFrames from various sources
- ✅ Execute SQL queries on DataFrames
- ✅ Use DataFrame operations
- ✅ Work with schemas and data types

---

## Part 1: RDDs vs DataFrames vs Datasets

```
┌─────────────────────────────────────────────────────────┐
│                     Spark Data APIs                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   RDD (Low-Level)                                        │
│   ├── Unstructured data                                  │
│   ├── Fine-grained control                               │
│   └── No automatic optimization                          │
│                                                          │
│   DataFrame (High-Level)                                 │
│   ├── Structured data with schema                        │
│   ├── SQL-like operations                                │
│   ├── Catalyst optimizer                                 │
│   └── Tungsten execution engine                          │
│                                                          │
│   Dataset (Type-safe DataFrame - Scala/Java)             │
│   ├── Compile-time type safety                           │
│   └── Combines RDD + DataFrame benefits                  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Part 2: Creating DataFrames

### Step 2.1: Setup
```python
"""
spark_sql_basics.py
Spark SQL and DataFrame Fundamentals
"""

from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *

# Create SparkSession
spark = SparkSession.builder \
    .appName("Spark SQL Basics") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")
print("SparkSession created!")
```

### Step 2.2: Create from Python Collections
```python
# Method 1: From list of tuples (schema inferred)
data = [
    ("Alice", "Engineering", 75000),
    ("Bob", "Engineering", 80000),
    ("Charlie", "Sales", 60000),
    ("Diana", "Sales", 65000),
    ("Eve", "Marketing", 55000)
]

columns = ["name", "department", "salary"]
df = spark.createDataFrame(data, columns)

print("\n=== DataFrame from List ===")
df.show()
df.printSchema()
```

### Step 2.3: Create with Explicit Schema
```python
# Method 2: With explicit schema
schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("age", IntegerType(), True),
    StructField("salary", DoubleType(), True),
    StructField("hire_date", DateType(), True)
])

from datetime import date
data_with_schema = [
    (1, "Alice", 28, 75000.0, date(2020, 1, 15)),
    (2, "Bob", 35, 80000.0, date(2019, 3, 20)),
    (3, "Charlie", 42, 60000.0, date(2018, 7, 10)),
    (4, "Diana", 29, 65000.0, date(2021, 5, 1)),
    (5, "Eve", 31, 55000.0, date(2022, 2, 28))
]

df_schema = spark.createDataFrame(data_with_schema, schema)
print("\n=== DataFrame with Explicit Schema ===")
df_schema.show()
df_schema.printSchema()
```

### Step 2.4: Create from CSV File
```python
# Create sample CSV
csv_content = """id,name,department,salary,hire_date
1,Alice,Engineering,75000,2020-01-15
2,Bob,Engineering,80000,2019-03-20
3,Charlie,Sales,60000,2018-07-10
4,Diana,Sales,65000,2021-05-01
5,Eve,Marketing,55000,2022-02-28"""

with open("employees.csv", "w") as f:
    f.write(csv_content)

# Read CSV
df_csv = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("employees.csv")

print("\n=== DataFrame from CSV ===")
df_csv.show()
df_csv.printSchema()
```

---

## Part 3: DataFrame Operations

### Step 3.1: Select and Column Operations
```python
# Select specific columns
print("\n=== Select Columns ===")
df.select("name", "salary").show()

# Select with expressions
df.select(
    col("name"),
    col("salary"),
    (col("salary") * 1.1).alias("salary_with_raise")
).show()

# Using selectExpr for SQL-like expressions
df.selectExpr(
    "name",
    "salary",
    "salary * 1.1 as salary_with_raise"
).show()
```

### Step 3.2: Filter (Where)
```python
print("\n=== Filter Operations ===")

# Filter with condition
df.filter(col("salary") > 60000).show()

# Multiple conditions
df.filter((col("salary") > 60000) & (col("department") == "Engineering")).show()

# Using where (alias for filter)
df.where("department = 'Sales' AND salary >= 60000").show()

# Using isin
df.filter(col("department").isin("Engineering", "Marketing")).show()
```

### Step 3.3: Adding and Modifying Columns
```python
print("\n=== Column Modifications ===")

# Add new column
df_with_bonus = df.withColumn("bonus", col("salary") * 0.1)
df_with_bonus.show()

# Rename column
df_renamed = df.withColumnRenamed("name", "employee_name")
df_renamed.show()

# Multiple transformations
df_transformed = df \
    .withColumn("annual_salary", col("salary") * 12) \
    .withColumn("department_upper", upper(col("department"))) \
    .withColumn("name_length", length(col("name")))
df_transformed.show()
```

### Step 3.4: Sorting
```python
print("\n=== Sorting ===")

# Sort ascending
df.orderBy("salary").show()

# Sort descending
df.orderBy(col("salary").desc()).show()

# Multiple columns
df.orderBy(col("department").asc(), col("salary").desc()).show()
```

---

## Part 4: Aggregations

### Step 4.1: Basic Aggregations
```python
print("\n=== Aggregations ===")

# Count
print(f"Total employees: {df.count()}")

# Aggregate functions
df.select(
    count("*").alias("count"),
    sum("salary").alias("total_salary"),
    avg("salary").alias("avg_salary"),
    min("salary").alias("min_salary"),
    max("salary").alias("max_salary")
).show()
```

### Step 4.2: GroupBy Aggregations
```python
print("\n=== GroupBy ===")

# Group by department
df.groupBy("department").agg(
    count("*").alias("employee_count"),
    sum("salary").alias("total_salary"),
    avg("salary").alias("avg_salary"),
    min("salary").alias("min_salary"),
    max("salary").alias("max_salary")
).show()

# Multiple grouping columns
employees_extended = [
    ("Alice", "Engineering", "Senior", 75000),
    ("Bob", "Engineering", "Junior", 55000),
    ("Charlie", "Sales", "Senior", 70000),
    ("Diana", "Sales", "Junior", 50000),
    ("Eve", "Engineering", "Senior", 80000)
]

df_ext = spark.createDataFrame(employees_extended, 
    ["name", "department", "level", "salary"])

df_ext.groupBy("department", "level").agg(
    count("*").alias("count"),
    avg("salary").alias("avg_salary")
).orderBy("department", "level").show()
```

---

## Part 5: SQL Queries

### Step 5.1: Register as Temporary View
```python
print("\n=== SQL Queries ===")

# Register DataFrame as temp view
df.createOrReplaceTempView("employees")

# Run SQL query
result = spark.sql("""
    SELECT department, 
           COUNT(*) as count,
           AVG(salary) as avg_salary
    FROM employees
    GROUP BY department
    ORDER BY avg_salary DESC
""")
result.show()
```

### Step 5.2: Complex SQL Queries
```python
# Window functions in SQL
spark.sql("""
    SELECT name, department, salary,
           RANK() OVER (ORDER BY salary DESC) as salary_rank,
           DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank
    FROM employees
""").show()

# Subqueries
spark.sql("""
    SELECT *
    FROM employees
    WHERE salary > (SELECT AVG(salary) FROM employees)
""").show()
```

### Step 5.3: Global Temporary Views
```python
# Global temp view - accessible across SparkSessions
df.createOrReplaceGlobalTempView("employees_global")

# Access with global_temp prefix
spark.sql("SELECT * FROM global_temp.employees_global").show()
```

---

## Part 6: Joins

### Step 6.1: Setup Join Data
```python
# Create department info
departments = [
    ("Engineering", "Building A", "John Manager"),
    ("Sales", "Building B", "Jane Manager"),
    ("Marketing", "Building A", "Bob Manager"),
    ("HR", "Building C", "Alice Manager")
]
df_departments = spark.createDataFrame(departments, 
    ["department", "building", "manager"])

print("\n=== Employees ===")
df.show()
print("=== Departments ===")
df_departments.show()
```

### Step 6.2: Join Types
```python
print("\n=== Inner Join ===")
df.join(df_departments, "department", "inner").show()

print("=== Left Join ===")
df.join(df_departments, "department", "left").show()

print("=== Right Join ===")
df.join(df_departments, "department", "right").show()

print("=== Full Outer Join ===")
df.join(df_departments, "department", "outer").show()

# Join with different column names
df_emp = df.withColumnRenamed("department", "dept_name")
df_emp.join(
    df_departments,
    df_emp.dept_name == df_departments.department,
    "inner"
).drop("department").show()
```

---

## Part 7: Built-in Functions

### Step 7.1: String Functions
```python
print("\n=== String Functions ===")

df.select(
    "name",
    upper("name").alias("upper_name"),
    lower("name").alias("lower_name"),
    length("name").alias("name_length"),
    concat("name", lit(" - "), "department").alias("full_info"),
    substring("name", 1, 3).alias("name_prefix")
).show()
```

### Step 7.2: Date Functions
```python
print("\n=== Date Functions ===")

df_csv.select(
    "name",
    "hire_date",
    year("hire_date").alias("hire_year"),
    month("hire_date").alias("hire_month"),
    dayofmonth("hire_date").alias("hire_day"),
    current_date().alias("today"),
    datediff(current_date(), "hire_date").alias("days_employed")
).show()
```

### Step 7.3: Conditional Functions
```python
print("\n=== Conditional Functions ===")

df.select(
    "name",
    "salary",
    when(col("salary") >= 70000, "High")
    .when(col("salary") >= 60000, "Medium")
    .otherwise("Low").alias("salary_tier")
).show()

# Using case in SQL
df.createOrReplaceTempView("employees")
spark.sql("""
    SELECT name, salary,
           CASE 
               WHEN salary >= 70000 THEN 'High'
               WHEN salary >= 60000 THEN 'Medium'
               ELSE 'Low'
           END as salary_tier
    FROM employees
""").show()
```

---

## Part 8: Saving DataFrames

### Step 8.1: Write to Various Formats
```python
# Write to Parquet (recommended for Spark)
df.write.mode("overwrite").parquet("output/employees_parquet")

# Write to CSV
df.write.mode("overwrite").option("header", "true").csv("output/employees_csv")

# Write to JSON
df.write.mode("overwrite").json("output/employees_json")

# Partitioned write
df.write.mode("overwrite").partitionBy("department").parquet("output/employees_partitioned")

print("Data written successfully!")
```

### Step 8.2: Read Back
```python
# Read parquet
df_read = spark.read.parquet("output/employees_parquet")
print("\n=== Read from Parquet ===")
df_read.show()
```

---

## Exercises

### Exercise 1: Employee Analysis
Using the employees DataFrame:
1. Find the department with the highest average salary
2. List employees earning above average
3. Calculate salary percentile for each employee
4. Find the highest-paid employee in each department

### Exercise 2: Join Challenge
1. Create a locations DataFrame (department -> city)
2. Create a projects DataFrame (name -> project_name)
3. Join all three DataFrames
4. Find employees working on projects in each city

### Exercise 3: Data Transformation
1. Create a DataFrame with sales data (product, region, amount, date)
2. Calculate monthly sales by product
3. Calculate year-over-year growth
4. Find top 3 products by region

---

## Cleanup
```python
# Clean up output files
import shutil
shutil.rmtree("output", ignore_errors=True)

spark.stop()
print("\nSpark session stopped.")
```

---

## Summary

In this lab, you learned:
- ✅ Differences between RDDs and DataFrames
- ✅ Creating DataFrames from various sources
- ✅ DataFrame operations: select, filter, withColumn
- ✅ Aggregations and groupBy
- ✅ Running SQL queries on DataFrames
- ✅ Various join types
- ✅ Built-in functions for strings, dates, conditions
- ✅ Saving DataFrames to different formats

**Next Lab**: Lab 04 - Word Count Project
