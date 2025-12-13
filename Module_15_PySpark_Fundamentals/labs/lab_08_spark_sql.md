# Lab 08: Spark SQL

## Overview
Master using SQL syntax for DataFrame operations in PySpark.

**Duration**: 2 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Register DataFrames as temp views
- ✅ Execute SQL queries with spark.sql()
- ✅ Use SQL for complex transformations
- ✅ Create global and local temp views
- ✅ Integrate SQL with DataFrame API

---

## Part 1: Creating Temp Views

### Step 1.1: Local Temporary View
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Spark SQL") \
    .master("local[*]") \
    .getOrCreate()

# Create sample DataFrame
data = [
    (1, "Alice", "Engineering", 75000),
    (2, "Bob", "Marketing", 65000),
    (3, "Charlie", "Engineering", 82000),
    (4, "Diana", "Sales", 58000),
    (5, "Eve", "Engineering", 90000),
]

df = spark.createDataFrame(data, ["id", "name", "department", "salary"])

# Create local temp view
df.createOrReplaceTempView("employees")

# Query the view
spark.sql("SELECT * FROM employees").show()
```

### Step 1.2: Global Temporary View
```python
# Global temp views are visible across SparkSessions
df.createOrReplaceGlobalTempView("global_employees")

# Access with global_temp prefix
spark.sql("SELECT * FROM global_temp.global_employees").show()
```

### Step 1.3: View Management
```python
# Check if view exists
spark.catalog.tableExists("employees")  # Returns True/False

# List all tables/views
spark.catalog.listTables()

# Drop view
spark.catalog.dropTempView("employees")
spark.catalog.dropGlobalTempView("global_employees")
```

---

## Part 2: Basic SQL Queries

### Step 2.1: SELECT Statements
```python
# Recreate view
df.createOrReplaceTempView("employees")

# Basic SELECT
spark.sql("SELECT name, salary FROM employees").show()

# SELECT with alias
spark.sql("""
    SELECT 
        name AS employee_name,
        salary AS base_salary,
        salary * 1.1 AS salary_with_raise
    FROM employees
""").show()
```

### Step 2.2: WHERE Clause
```python
# Filter with WHERE
spark.sql("""
    SELECT * FROM employees
    WHERE salary > 70000
""").show()

# Multiple conditions
spark.sql("""
    SELECT * FROM employees
    WHERE department = 'Engineering'
      AND salary > 75000
""").show()
```

### Step 2.3: ORDER BY
```python
spark.sql("""
    SELECT * FROM employees
    ORDER BY salary DESC
    LIMIT 3
""").show()
```

---

## Part 3: Aggregations with SQL

### Step 3.1: GROUP BY
```python
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
    ORDER BY total_salary DESC
""").show()
```

### Step 3.2: HAVING
```python
spark.sql("""
    SELECT 
        department,
        COUNT(*) as employee_count,
        AVG(salary) as avg_salary
    FROM employees
    GROUP BY department
    HAVING AVG(salary) > 70000
""").show()
```

---

## Part 4: Joins with SQL

### Step 4.1: Setup Join Data
```python
# Departments data
dept_data = [
    ("Engineering", "NYC", 101),
    ("Marketing", "LA", 102),
    ("Sales", "CHI", 103),
    ("HR", "NYC", 104),
]

dept_df = spark.createDataFrame(dept_data, ["dept_name", "location", "dept_id"])
dept_df.createOrReplaceTempView("departments")
```

### Step 4.2: INNER JOIN
```python
spark.sql("""
    SELECT e.name, e.salary, d.dept_name, d.location
    FROM employees e
    INNER JOIN departments d
        ON e.department = d.dept_name
""").show()
```

### Step 4.3: LEFT JOIN
```python
spark.sql("""
    SELECT e.name, e.department, d.location
    FROM employees e
    LEFT JOIN departments d
        ON e.department = d.dept_name
""").show()
```

### Step 4.4: Multiple Joins
```python
# Create another table
salary_history = [
    (1, 70000, "2023-01-01"),
    (1, 75000, "2024-01-01"),
    (2, 60000, "2023-01-01"),
    (2, 65000, "2024-01-01"),
]
spark.createDataFrame(salary_history, ["emp_id", "salary", "effective_date"]) \
    .createOrReplaceTempView("salary_history")

spark.sql("""
    SELECT 
        e.name, 
        d.location,
        sh.salary as historical_salary,
        sh.effective_date
    FROM employees e
    LEFT JOIN departments d ON e.department = d.dept_name
    LEFT JOIN salary_history sh ON e.id = sh.emp_id
    ORDER BY e.name, sh.effective_date
""").show()
```

---

## Part 5: Subqueries

### Step 5.1: Scalar Subquery
```python
spark.sql("""
    SELECT 
        name,
        salary,
        (SELECT AVG(salary) FROM employees) as company_avg
    FROM employees
""").show()
```

### Step 5.2: IN Subquery
```python
spark.sql("""
    SELECT * FROM employees
    WHERE department IN (
        SELECT dept_name FROM departments
        WHERE location = 'NYC'
    )
""").show()
```

### Step 5.3: Correlated Subquery
```python
spark.sql("""
    SELECT 
        name,
        department,
        salary
    FROM employees e1
    WHERE salary > (
        SELECT AVG(salary) 
        FROM employees e2 
        WHERE e2.department = e1.department
    )
""").show()
```

---

## Part 6: Common Table Expressions (CTEs)

```python
spark.sql("""
    WITH dept_stats AS (
        SELECT 
            department,
            AVG(salary) as avg_salary,
            MAX(salary) as max_salary
        FROM employees
        GROUP BY department
    ),
    high_earners AS (
        SELECT * FROM employees
        WHERE salary > 70000
    )
    SELECT 
        h.name,
        h.department,
        h.salary,
        d.avg_salary as dept_avg
    FROM high_earners h
    JOIN dept_stats d ON h.department = d.department
""").show()
```

---

## Part 7: Window Functions in SQL

```python
spark.sql("""
    SELECT 
        name,
        department,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank,
        SUM(salary) OVER (PARTITION BY department) as dept_total,
        AVG(salary) OVER () as company_avg
    FROM employees
""").show()
```

---

## Part 8: CASE Statements

```python
spark.sql("""
    SELECT 
        name,
        salary,
        CASE 
            WHEN salary >= 80000 THEN 'Senior'
            WHEN salary >= 65000 THEN 'Mid'
            ELSE 'Junior'
        END as level,
        CASE department
            WHEN 'Engineering' THEN 'Tech'
            WHEN 'Marketing' THEN 'Business'
            ELSE 'Other'
        END as division
    FROM employees
""").show()
```

---

## Part 9: Built-in Functions

### Step 9.1: String Functions
```python
spark.sql("""
    SELECT 
        name,
        UPPER(name) as upper_name,
        LOWER(name) as lower_name,
        LENGTH(name) as name_length,
        CONCAT(name, ' - ', department) as full_info,
        SUBSTRING(name, 1, 3) as short_name
    FROM employees
""").show()
```

### Step 9.2: Date Functions
```python
spark.sql("""
    SELECT 
        CURRENT_DATE() as today,
        CURRENT_TIMESTAMP() as now,
        DATE_ADD(CURRENT_DATE(), 30) as next_month,
        DATE_FORMAT(CURRENT_TIMESTAMP(), 'yyyy-MM-dd') as formatted_date,
        YEAR(CURRENT_DATE()) as year,
        MONTH(CURRENT_DATE()) as month
""").show()
```

### Step 9.3: Numeric Functions
```python
spark.sql("""
    SELECT 
        salary,
        ROUND(salary / 12, 2) as monthly,
        CEIL(salary / 1000) as rounded_up_k,
        FLOOR(salary / 1000) as rounded_down_k,
        ABS(salary - 70000) as diff_from_70k
    FROM employees
""").show()
```

---

## Part 10: Mixing SQL and DataFrame API

```python
# SQL result is a DataFrame
sql_result = spark.sql("SELECT * FROM employees WHERE salary > 70000")

# Continue with DataFrame API
final_result = sql_result \
    .withColumn("bonus", sql_result.salary * 0.1) \
    .orderBy("salary", ascending=False)

final_result.show()

# DataFrame to SQL and back
df.createOrReplaceTempView("emp_v2")
spark.sql("SELECT name, salary * 1.1 as new_salary FROM emp_v2") \
    .filter("new_salary > 80000") \
    .show()
```

---

## Part 11: Performance Considerations

```python
# Enable Adaptive Query Execution
spark.conf.set("spark.sql.adaptive.enabled", "true")

# Check query plan
spark.sql("SELECT * FROM employees WHERE salary > 70000").explain()

# Use EXPLAIN for detailed plan
spark.sql("""
    EXPLAIN EXTENDED
    SELECT e.name, d.location
    FROM employees e
    JOIN departments d ON e.department = d.dept_name
""").show(truncate=False)
```

---

## Exercises

1. Write a SQL query to find top earner in each department
2. Create a CTE to calculate running totals
3. Use window functions to rank employees
4. Join multiple tables with complex conditions

---

## Summary
- Use `createOrReplaceTempView()` to register DataFrames
- `spark.sql()` returns a DataFrame
- Full SQL support: joins, subqueries, CTEs, windows
- Mix SQL and DataFrame API freely
- Use EXPLAIN to understand query plans
