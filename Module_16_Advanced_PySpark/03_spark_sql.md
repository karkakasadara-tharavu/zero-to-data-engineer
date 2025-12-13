# Advanced PySpark - Spark SQL

## 📚 What You'll Learn
- Using Spark SQL with DataFrames
- Creating and managing views
- SQL functions and expressions
- Catalog operations
- Integration with Hive
- Interview preparation

**Duration**: 1.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is Spark SQL?

Spark SQL is a module for structured data processing using SQL syntax. It allows you to:
- Query DataFrames using SQL
- Read/write various data formats
- Connect to external databases
- Integrate with Hive metastore

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SPARK SQL ECOSYSTEM                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                           YOUR QUERY                                    │
│                    (DataFrame API OR SQL)                               │
│                              │                                          │
│                              ▼                                          │
│   ┌──────────────────────────────────────────────────────────────────┐ │
│   │                    CATALYST OPTIMIZER                             │ │
│   │  - Parses SQL                                                     │ │
│   │  - Analyzes logical plan                                          │ │
│   │  - Optimizes (predicate pushdown, column pruning, etc.)          │ │
│   │  - Generates physical plan                                        │ │
│   └──────────────────────────────────────────────────────────────────┘ │
│                              │                                          │
│                              ▼                                          │
│   ┌──────────────────────────────────────────────────────────────────┐ │
│   │                    TUNGSTEN ENGINE                                │ │
│   │  - Whole-stage code generation                                    │ │
│   │  - Memory management                                              │ │
│   │  - Cache-aware computation                                        │ │
│   └──────────────────────────────────────────────────────────────────┘ │
│                              │                                          │
│                              ▼                                          │
│                      EXECUTION ON CLUSTER                               │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder \
    .appName("SparkSQL") \
    .enableHiveSupport() \
    .getOrCreate()

# Create sample DataFrames
employees = spark.createDataFrame([
    (1, "Alice", "Engineering", 100000, "2020-01-15"),
    (2, "Bob", "Engineering", 90000, "2020-03-20"),
    (3, "Carol", "Sales", 85000, "2021-06-10"),
    (4, "Dave", "Sales", 80000, "2019-11-01"),
    (5, "Eve", "HR", 70000, "2022-02-01"),
], ["id", "name", "department", "salary", "hire_date"])

departments = spark.createDataFrame([
    ("Engineering", "Building A", 50),
    ("Sales", "Building B", 30),
    ("HR", "Building C", 20),
    ("Finance", "Building D", 15),
], ["department", "location", "budget"])

employees.show()
departments.show()
```

---

## 🔧 Creating Views

### Temporary Views

```python
# Create temp view (session-scoped)
employees.createOrReplaceTempView("employees")
departments.createOrReplaceTempView("departments")

# Query using SQL
spark.sql("SELECT * FROM employees").show()

# Check if view exists
spark.catalog.tableExists("employees")  # True
```

### Global Temporary Views

```python
# Create global temp view (cross-session)
employees.createOrReplaceGlobalTempView("global_employees")

# Access with global_temp prefix
spark.sql("SELECT * FROM global_temp.global_employees").show()
```

### Drop Views

```python
# Drop temp view
spark.catalog.dropTempView("employees")

# Drop global temp view
spark.catalog.dropGlobalTempView("global_employees")
```

---

## 📝 Basic SQL Queries

### SELECT and WHERE

```python
# Basic SELECT
spark.sql("""
    SELECT name, department, salary
    FROM employees
""").show()

# WHERE clause
spark.sql("""
    SELECT * FROM employees
    WHERE salary > 80000
""").show()

# Multiple conditions
spark.sql("""
    SELECT * FROM employees
    WHERE salary > 80000 
      AND department = 'Engineering'
""").show()

# IN clause
spark.sql("""
    SELECT * FROM employees
    WHERE department IN ('Engineering', 'Sales')
""").show()

# BETWEEN
spark.sql("""
    SELECT * FROM employees
    WHERE salary BETWEEN 80000 AND 95000
""").show()

# LIKE pattern
spark.sql("""
    SELECT * FROM employees
    WHERE name LIKE 'A%'
""").show()
```

### Aggregations

```python
# COUNT, SUM, AVG
spark.sql("""
    SELECT 
        department,
        COUNT(*) as employee_count,
        SUM(salary) as total_salary,
        AVG(salary) as avg_salary,
        MAX(salary) as max_salary,
        MIN(salary) as min_salary
    FROM employees
    GROUP BY department
""").show()

# HAVING clause
spark.sql("""
    SELECT department, AVG(salary) as avg_salary
    FROM employees
    GROUP BY department
    HAVING AVG(salary) > 80000
""").show()
```

### JOINs

```python
# INNER JOIN
spark.sql("""
    SELECT e.name, e.department, d.location
    FROM employees e
    INNER JOIN departments d
    ON e.department = d.department
""").show()

# LEFT JOIN
spark.sql("""
    SELECT e.name, d.department, d.location
    FROM employees e
    LEFT JOIN departments d
    ON e.department = d.department
""").show()

# Multiple JOINs
spark.sql("""
    SELECT e.name, d.department, d.location, m.name as manager
    FROM employees e
    LEFT JOIN departments d ON e.department = d.department
    LEFT JOIN employees m ON e.manager_id = m.id
""").show()
```

### Subqueries

```python
# Scalar subquery
spark.sql("""
    SELECT name, salary,
        (SELECT AVG(salary) FROM employees) as avg_salary
    FROM employees
""").show()

# IN subquery
spark.sql("""
    SELECT * FROM employees
    WHERE department IN (
        SELECT department FROM departments WHERE budget > 20
    )
""").show()

# Correlated subquery
spark.sql("""
    SELECT name, salary, department
    FROM employees e1
    WHERE salary > (
        SELECT AVG(salary) FROM employees e2 
        WHERE e2.department = e1.department
    )
""").show()
```

### CTEs (Common Table Expressions)

```python
spark.sql("""
    WITH high_salary AS (
        SELECT * FROM employees WHERE salary > 80000
    ),
    dept_stats AS (
        SELECT department, AVG(salary) as avg_sal
        FROM employees
        GROUP BY department
    )
    SELECT h.name, h.salary, d.avg_sal
    FROM high_salary h
    JOIN dept_stats d ON h.department = d.department
""").show()
```

---

## 🔢 Window Functions in SQL

```python
# Create temp view
employees.createOrReplaceTempView("employees")

# Row number
spark.sql("""
    SELECT name, department, salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank
    FROM employees
""").show()

# Rank and Dense Rank
spark.sql("""
    SELECT name, salary,
        RANK() OVER (ORDER BY salary DESC) as rank,
        DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank
    FROM employees
""").show()

# Running total
spark.sql("""
    SELECT name, salary,
        SUM(salary) OVER (ORDER BY hire_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
    FROM employees
""").show()

# LAG and LEAD
spark.sql("""
    SELECT name, salary,
        LAG(salary, 1) OVER (ORDER BY hire_date) as prev_salary,
        LEAD(salary, 1) OVER (ORDER BY hire_date) as next_salary
    FROM employees
""").show()
```

---

## 📌 Built-in SQL Functions

### String Functions

```python
spark.sql("""
    SELECT 
        UPPER(name) as upper_name,
        LOWER(name) as lower_name,
        LENGTH(name) as name_length,
        TRIM(name) as trimmed,
        CONCAT(name, ' - ', department) as combined,
        SUBSTRING(name, 1, 3) as first_3_chars,
        REPLACE(name, 'a', '@') as replaced
    FROM employees
""").show()
```

### Date Functions

```python
spark.sql("""
    SELECT 
        hire_date,
        YEAR(hire_date) as year,
        MONTH(hire_date) as month,
        DAY(hire_date) as day,
        DAYOFWEEK(hire_date) as day_of_week,
        QUARTER(hire_date) as quarter,
        DATE_ADD(hire_date, 30) as plus_30_days,
        DATE_SUB(hire_date, 30) as minus_30_days,
        DATEDIFF(CURRENT_DATE(), hire_date) as days_employed,
        MONTHS_BETWEEN(CURRENT_DATE(), hire_date) as months_employed
    FROM employees
""").show()
```

### Conditional Functions

```python
spark.sql("""
    SELECT name, salary,
        CASE 
            WHEN salary >= 100000 THEN 'High'
            WHEN salary >= 80000 THEN 'Medium'
            ELSE 'Low'
        END as salary_level,
        IF(salary > 90000, 'Above 90K', 'Below 90K') as salary_check,
        COALESCE(department, 'Unknown') as dept,
        NULLIF(salary, 0) as non_zero_salary,
        NVL(department, 'No Dept') as dept_nvl
    FROM employees
""").show()
```

### Aggregate Functions

```python
spark.sql("""
    SELECT 
        COUNT(*) as total_count,
        COUNT(DISTINCT department) as dept_count,
        SUM(salary) as total_salary,
        AVG(salary) as avg_salary,
        MIN(salary) as min_salary,
        MAX(salary) as max_salary,
        STDDEV(salary) as std_dev,
        VARIANCE(salary) as variance,
        COLLECT_LIST(name) as all_names,
        COLLECT_SET(department) as unique_depts
    FROM employees
""").show(truncate=False)
```

---

## 📚 Catalog Operations

### View Databases and Tables

```python
# List databases
spark.catalog.listDatabases()

# List tables in current database
spark.catalog.listTables()

# List tables in specific database
spark.catalog.listTables("my_database")

# List columns
spark.catalog.listColumns("employees")

# Check if table exists
spark.catalog.tableExists("employees")

# Get table/database info
spark.catalog.getTable("employees")
spark.catalog.getDatabase("default")
```

### Create Database and Tables

```python
# Create database
spark.sql("CREATE DATABASE IF NOT EXISTS my_database")

# Use database
spark.sql("USE my_database")

# Create table from DataFrame
employees.write.saveAsTable("my_database.employees")

# Create external table
spark.sql("""
    CREATE TABLE IF NOT EXISTS external_table (
        id INT,
        name STRING,
        salary DOUBLE
    )
    USING PARQUET
    LOCATION '/path/to/data'
""")

# Create table with partitioning
spark.sql("""
    CREATE TABLE IF NOT EXISTS partitioned_table (
        id INT,
        name STRING,
        salary DOUBLE
    )
    USING PARQUET
    PARTITIONED BY (department STRING)
""")
```

### Managed vs External Tables

```
┌────────────────────────────────────────────────────────────────────────┐
│            MANAGED vs EXTERNAL TABLES                                   │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   MANAGED TABLE:                                                        │
│   - Spark manages both metadata AND data                               │
│   - DROP TABLE deletes the data too                                    │
│   - Data stored in warehouse directory                                 │
│                                                                         │
│   EXTERNAL TABLE:                                                       │
│   - Spark manages only metadata                                        │
│   - DROP TABLE keeps the data                                          │
│   - Data stored at specified LOCATION                                  │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

```python
# Check table type
spark.sql("DESCRIBE EXTENDED my_table").show(truncate=False)
# Look for "Type" in the output
```

---

## 🔄 DataFrame API vs SQL

### Equivalent Operations

```python
# Create view
employees.createOrReplaceTempView("employees")

# SELECT
df_result = employees.select("name", "salary")
sql_result = spark.sql("SELECT name, salary FROM employees")

# WHERE
df_result = employees.filter(col("salary") > 80000)
sql_result = spark.sql("SELECT * FROM employees WHERE salary > 80000")

# GROUP BY
df_result = employees.groupBy("department").agg(avg("salary"))
sql_result = spark.sql("SELECT department, AVG(salary) FROM employees GROUP BY department")

# JOIN
df_result = employees.join(departments, "department")
sql_result = spark.sql("""
    SELECT * FROM employees e 
    JOIN departments d ON e.department = d.department
""")

# All produce the same execution plan!
df_result.explain()
sql_result.explain()
```

### Using expr() for SQL in DataFrame API

```python
# Mix SQL expressions in DataFrame API
employees.select(
    col("name"),
    expr("UPPER(name) as upper_name"),
    expr("salary * 1.1 as new_salary"),
    expr("CASE WHEN salary > 90000 THEN 'High' ELSE 'Low' END as level")
).show()

# selectExpr for multiple expressions
employees.selectExpr(
    "name",
    "salary * 1.1 as new_salary",
    "YEAR(hire_date) as hire_year"
).show()
```

---

## 🎓 Interview Questions

### Q1: What is Spark SQL?
**A:** Spark SQL is a Spark module for structured data processing. It allows:
- SQL queries on DataFrames
- Reading/writing various formats (Parquet, JSON, CSV, JDBC)
- Integration with Hive metastore
- Catalyst optimizer for query optimization

### Q2: What is the difference between a temporary view and global temporary view?
**A:**
- **Temporary View**: Session-scoped, only visible to current SparkSession
- **Global Temporary View**: Application-scoped, visible across SparkSessions, accessed via `global_temp` database

### Q3: How does Spark optimize SQL queries?
**A:** Catalyst Optimizer:
1. **Parsing**: SQL → Abstract Syntax Tree
2. **Analysis**: Resolve references, check types
3. **Logical Optimization**: Predicate pushdown, column pruning
4. **Physical Planning**: Choose join algorithms, generate code
5. **Code Generation**: Tungsten whole-stage code gen

### Q4: What is predicate pushdown?
**A:** Pushing filter conditions down to the data source level, so only needed data is read. Especially effective with Parquet and partitioned data.

### Q5: How do you create a UDF for use in Spark SQL?
**A:**
```python
def my_function(x):
    return x * 2

spark.udf.register("my_udf", my_function, IntegerType())
spark.sql("SELECT my_udf(column) FROM table")
```

### Q6: What is the difference between managed and external tables?
**A:**
- **Managed**: Spark controls data and metadata. DROP deletes data.
- **External**: Spark controls only metadata. DROP keeps data at LOCATION.

### Q7: How do you optimize SQL queries in Spark?
**A:**
1. **Use Parquet** for predicate pushdown
2. **Partition tables** on frequently filtered columns
3. **Use broadcast hints** for small tables
4. **Filter early** before joins
5. **Enable AQE** for runtime optimization
6. **Cache** frequently used tables

### Q8: How do you access Hive tables from Spark?
**A:**
```python
spark = SparkSession.builder \
    .appName("HiveApp") \
    .enableHiveSupport() \
    .getOrCreate()

# Now can access Hive tables
spark.sql("SELECT * FROM hive_database.hive_table")
```

### Q9: What are CTEs and why use them?
**A:** Common Table Expressions are named subqueries defined with WITH clause. Benefits:
- Improved readability
- Reuse within same query
- Better organization for complex queries
- Recursive queries (supported in Spark 3.x)

### Q10: Can you mix DataFrame API and SQL?
**A:** Yes! You can:
- Create views from DataFrames, query with SQL
- Use `expr()` for SQL expressions in DataFrame API
- Use `spark.sql()` result as DataFrame
- Both compile to same execution plan

---

## 🔗 Related Topics
- [← Performance Optimization](./02_performance.md)
- [Structured Streaming →](./04_streaming.md)
- [Delta Lake →](./05_delta_lake.md)

---

*Next: Learn about Structured Streaming*
