# Lab 05: DataFrame Joins

## Overview
Master joining DataFrames for combining data from multiple sources.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Understand different join types
- ✅ Perform inner, outer, left, and right joins
- ✅ Handle join key naming conflicts
- ✅ Use broadcast joins for optimization
- ✅ Implement cross joins and semi/anti joins

---

## Part 1: Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("DataFrame Joins") \
    .master("local[*]") \
    .getOrCreate()

# Employees DataFrame
employees_data = [
    (1, "Alice", "E001", 101),
    (2, "Bob", "E002", 102),
    (3, "Charlie", "E003", 101),
    (4, "Diana", "E004", 103),
    (5, "Eve", "E005", None),  # No department
]

employees = spark.createDataFrame(
    employees_data, 
    ["emp_id", "name", "emp_code", "dept_id"]
)

# Departments DataFrame
departments_data = [
    (101, "Engineering", "NYC"),
    (102, "Marketing", "LA"),
    (103, "Sales", "CHI"),
    (104, "HR", "NYC"),  # No employees
]

departments = spark.createDataFrame(
    departments_data, 
    ["dept_id", "dept_name", "location"]
)

# Salaries DataFrame
salaries_data = [
    ("E001", 75000, "2024-01-01"),
    ("E002", 65000, "2024-01-01"),
    ("E003", 82000, "2024-01-01"),
    ("E004", 58000, "2024-01-01"),
    ("E006", 70000, "2024-01-01"),  # Unknown employee
]

salaries = spark.createDataFrame(
    salaries_data, 
    ["emp_code", "salary", "effective_date"]
)

print("Employees:")
employees.show()
print("Departments:")
departments.show()
print("Salaries:")
salaries.show()
```

---

## Part 2: Inner Join

Returns only matching rows from both DataFrames.

```python
# Inner join - default join type
result = employees.join(
    departments,
    employees.dept_id == departments.dept_id,
    "inner"
)
result.show()

# Simplified syntax when column names match
result = employees.join(departments, "dept_id", "inner")
result.show()
```

**Output:**
```
+------+-------+--------+-------+---------+--------+
|emp_id|   name|emp_code|dept_id|dept_name|location|
+------+-------+--------+-------+---------+--------+
|     1|  Alice|    E001|    101|Engineering|   NYC|
|     3|Charlie|    E003|    101|Engineering|   NYC|
|     2|    Bob|    E002|    102|Marketing|     LA|
|     4|  Diana|    E004|    103|    Sales|    CHI|
+------+-------+--------+-------+---------+--------+
```

Note: Eve (no dept_id) and HR (no employees) are excluded.

---

## Part 3: Left Outer Join

Returns all rows from left DataFrame plus matched rows from right.

```python
# Left outer join
result = employees.join(
    departments,
    "dept_id",
    "left"  # or "left_outer"
)
result.show()
```

**Output:**
```
+-------+------+-------+--------+---------+--------+
|dept_id|emp_id|   name|emp_code|dept_name|location|
+-------+------+-------+--------+---------+--------+
|    101|     1|  Alice|    E001|Engineering|   NYC|
|    101|     3|Charlie|    E003|Engineering|   NYC|
|    102|     2|    Bob|    E002|Marketing|     LA|
|    103|     4|  Diana|    E004|    Sales|    CHI|
|   null|     5|    Eve|    E005|     null|    null|
+-------+------+-------+--------+---------+--------+
```

Note: Eve is included with null department info.

---

## Part 4: Right Outer Join

Returns all rows from right DataFrame plus matched rows from left.

```python
# Right outer join
result = employees.join(
    departments,
    "dept_id",
    "right"  # or "right_outer"
)
result.show()
```

**Output:**
```
+-------+------+-------+--------+-----------+--------+
|dept_id|emp_id|   name|emp_code|  dept_name|location|
+-------+------+-------+--------+-----------+--------+
|    101|     1|  Alice|    E001|Engineering|     NYC|
|    101|     3|Charlie|    E003|Engineering|     NYC|
|    102|     2|    Bob|    E002|  Marketing|      LA|
|    103|     4|  Diana|    E004|      Sales|     CHI|
|    104|  null|   null|    null|         HR|     NYC|
+-------+------+-------+--------+-----------+--------+
```

Note: HR department is included with null employee info.

---

## Part 5: Full Outer Join

Returns all rows from both DataFrames.

```python
# Full outer join
result = employees.join(
    departments,
    "dept_id",
    "full"  # or "full_outer" or "outer"
)
result.show()
```

**Output:**
```
+-------+------+-------+--------+-----------+--------+
|dept_id|emp_id|   name|emp_code|  dept_name|location|
+-------+------+-------+--------+-----------+--------+
|    101|     1|  Alice|    E001|Engineering|     NYC|
|    101|     3|Charlie|    E003|Engineering|     NYC|
|    102|     2|    Bob|    E002|  Marketing|      LA|
|    103|     4|  Diana|    E004|      Sales|     CHI|
|    104|  null|   null|    null|         HR|     NYC|
|   null|     5|    Eve|    E005|       null|    null|
+-------+------+-------+--------+-----------+--------+
```

---

## Part 6: Cross Join (Cartesian Product)

Returns all possible combinations.

```python
# Cross join - use with caution!
regions = spark.createDataFrame(
    [("North",), ("South",), ("East",), ("West",)],
    ["region"]
)

products = spark.createDataFrame(
    [("Laptop",), ("Phone",), ("Tablet",)],
    ["product"]
)

cross_result = products.crossJoin(regions)
cross_result.show()
```

**Output:**
```
+-------+------+
|product|region|
+-------+------+
| Laptop| North|
| Laptop| South|
| Laptop|  East|
| Laptop|  West|
|  Phone| North|
...
+-------+------+
```

⚠️ **Warning**: Cross joins can produce very large results!

---

## Part 7: Semi and Anti Joins

### Step 7.1: Left Semi Join
Returns rows from left that have matches in right (like EXISTS).

```python
# Semi join - employees who have salary records
result = employees.join(
    salaries,
    employees.emp_code == salaries.emp_code,
    "left_semi"
)
result.show()
```

**Output:**
```
+------+-------+--------+-------+
|emp_id|   name|emp_code|dept_id|
+------+-------+--------+-------+
|     1|  Alice|    E001|    101|
|     2|    Bob|    E002|    102|
|     3|Charlie|    E003|    101|
|     4|  Diana|    E004|    103|
+------+-------+--------+-------+
```

### Step 7.2: Left Anti Join
Returns rows from left that have NO matches in right (like NOT EXISTS).

```python
# Anti join - employees without salary records
result = employees.join(
    salaries,
    employees.emp_code == salaries.emp_code,
    "left_anti"
)
result.show()
```

**Output:**
```
+------+----+--------+-------+
|emp_id|name|emp_code|dept_id|
+------+----+--------+-------+
|     5| Eve|    E005|   null|
+------+----+--------+-------+
```

---

## Part 8: Handling Column Name Conflicts

### Step 8.1: Different Column Names
```python
# When join columns have different names
result = employees.join(
    salaries,
    employees.emp_code == salaries.emp_code,
    "inner"
).drop(salaries.emp_code)  # Drop duplicate column

result.show()
```

### Step 8.2: Using Aliases
```python
from pyspark.sql.functions import col

# Alias DataFrames
emp = employees.alias("emp")
sal = salaries.alias("sal")

result = emp.join(
    sal,
    col("emp.emp_code") == col("sal.emp_code"),
    "inner"
).select(
    col("emp.emp_id"),
    col("emp.name"),
    col("emp.emp_code"),
    col("sal.salary")
)

result.show()
```

### Step 8.3: Renaming Before Join
```python
# Rename columns before joining
salaries_renamed = salaries.withColumnRenamed("emp_code", "sal_emp_code")

result = employees.join(
    salaries_renamed,
    employees.emp_code == salaries_renamed.sal_emp_code,
    "inner"
)

result.show()
```

---

## Part 9: Broadcast Joins

For joining small tables with large tables efficiently.

```python
from pyspark.sql.functions import broadcast

# Broadcast smaller table to all executors
result = employees.join(
    broadcast(departments),
    "dept_id",
    "inner"
)

result.show()

# Check broadcast threshold
print(spark.conf.get("spark.sql.autoBroadcastJoinThreshold"))
# Default: 10MB
```

---

## Part 10: Multi-Table Joins

```python
# Join multiple tables
result = employees \
    .join(departments, "dept_id", "left") \
    .join(
        salaries,
        employees.emp_code == salaries.emp_code,
        "left"
    ) \
    .select(
        employees.emp_id,
        employees.name,
        departments.dept_name,
        salaries.salary
    )

result.show()
```

**Output:**
```
+------+-------+-----------+------+
|emp_id|   name|  dept_name|salary|
+------+-------+-----------+------+
|     1|  Alice|Engineering| 75000|
|     2|    Bob|  Marketing| 65000|
|     3|Charlie|Engineering| 82000|
|     4|  Diana|      Sales| 58000|
|     5|    Eve|       null|  null|
+------+-------+-----------+------+
```

---

## Part 11: Join Types Summary

| Join Type | Description | Syntax |
|-----------|-------------|--------|
| `inner` | Matching rows only | `"inner"` |
| `left` | All left + matching right | `"left"` or `"left_outer"` |
| `right` | All right + matching left | `"right"` or `"right_outer"` |
| `full` | All rows from both | `"full"` or `"outer"` |
| `cross` | Cartesian product | `.crossJoin()` |
| `left_semi` | Left rows with match | `"left_semi"` |
| `left_anti` | Left rows without match | `"left_anti"` |

---

## Exercises

1. Find all employees with their department names and salaries
2. Find departments with no employees
3. Find employees who have no salary records
4. Create a report showing location-wise salary totals

---

## Summary
- Use `inner` join for matching rows only
- Use `left/right` for preserving one side
- Use `full outer` for preserving both sides
- Use `semi/anti` for existence checks
- Use `broadcast()` for small-large joins
- Handle column conflicts with aliases or drops
