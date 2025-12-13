# PySpark Joins - Complete Guide

## 📚 What You'll Learn
- Types of joins in PySpark
- Join syntax and best practices
- Handling duplicate columns
- Broadcast joins for optimization
- Common join pitfalls
- Interview preparation

**Duration**: 1.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Understanding Joins

### What is a Join?

A join combines rows from two DataFrames based on a related column.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           JOIN OPERATION                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   employees (df1)              departments (df2)                         │
│   ┌────────┬───────┐           ┌─────────┬────────────┐                 │
│   │ emp_id │ name  │           │ dept_id │ dept_name  │                 │
│   ├────────┼───────┤           ├─────────┼────────────┤                 │
│   │ 1      │ Alice │           │ 10      │ Engineering│                 │
│   │ 2      │ Bob   │           │ 20      │ Sales      │                 │
│   │ 3      │ Carol │           │ 30      │ HR         │                 │
│   └────────┴───────┘           └─────────┴────────────┘                 │
│                                                                          │
│                      ▼ INNER JOIN ON dept_id ▼                          │
│                                                                          │
│   result                                                                 │
│   ┌────────┬───────┬─────────┬────────────┐                             │
│   │ emp_id │ name  │ dept_id │ dept_name  │                             │
│   ├────────┼───────┼─────────┼────────────┤                             │
│   │ 1      │ Alice │ 10      │ Engineering│                             │
│   │ 2      │ Bob   │ 20      │ Sales      │                             │
│   └────────┴───────┴─────────┴────────────┘                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder.appName("Joins").getOrCreate()

# Employees DataFrame
employees = spark.createDataFrame([
    (1, "Alice", 10, 100000),
    (2, "Bob", 20, 90000),
    (3, "Carol", 10, 85000),
    (4, "Dave", 30, 75000),
    (5, "Eve", None, 70000),  # No department
], ["emp_id", "name", "dept_id", "salary"])

# Departments DataFrame
departments = spark.createDataFrame([
    (10, "Engineering", "Building A"),
    (20, "Sales", "Building B"),
    (30, "HR", "Building C"),
    (40, "Finance", "Building D"),  # No employees
], ["dept_id", "dept_name", "location"])

employees.show()
departments.show()
```

---

## 🔗 Join Types

### 1. Inner Join (Default)

Returns only rows that have matching values in **both** DataFrames.

```python
# Method 1: Explicit column
result = employees.join(departments, 
    employees.dept_id == departments.dept_id, 
    "inner")

# Method 2: Same column name (preferred - avoids duplicate columns)
result = employees.join(departments, "dept_id", "inner")

# Method 3: Default is inner
result = employees.join(departments, "dept_id")

result.show()
# +-------+------+-------+------+-----------+----------+
# |dept_id|emp_id|  name |salary|  dept_name|  location|
# +-------+------+-------+------+-----------+----------+
# |     10|     1| Alice |100000|Engineering|Building A|
# |     10|     3| Carol | 85000|Engineering|Building A|
# |     20|     2|   Bob | 90000|      Sales|Building B|
# |     30|     4|  Dave | 75000|         HR|Building C|
# +-------+------+-------+------+-----------+----------+
# Note: Eve (no dept) and Finance (no employees) are excluded
```

### 2. Left Join (Left Outer)

Returns all rows from **left** DataFrame and matching rows from right. NULL for no match.

```python
result = employees.join(departments, "dept_id", "left")
# OR
result = employees.join(departments, "dept_id", "left_outer")

result.show()
# +-------+------+-------+------+-----------+----------+
# |dept_id|emp_id|  name |salary|  dept_name|  location|
# +-------+------+-------+------+-----------+----------+
# |     10|     1| Alice |100000|Engineering|Building A|
# |     10|     3| Carol | 85000|Engineering|Building A|
# |     20|     2|   Bob | 90000|      Sales|Building B|
# |     30|     4|  Dave | 75000|         HR|Building C|
# |   null|     5|   Eve | 70000|       null|      null|  ← Eve included
# +-------+------+-------+------+-----------+----------+
```

### 3. Right Join (Right Outer)

Returns all rows from **right** DataFrame and matching rows from left. NULL for no match.

```python
result = employees.join(departments, "dept_id", "right")
# OR
result = employees.join(departments, "dept_id", "right_outer")

result.show()
# +-------+------+-------+------+-----------+----------+
# |dept_id|emp_id|  name |salary|  dept_name|  location|
# +-------+------+-------+------+-----------+----------+
# |     10|     1| Alice |100000|Engineering|Building A|
# |     10|     3| Carol | 85000|Engineering|Building A|
# |     20|     2|   Bob | 90000|      Sales|Building B|
# |     30|     4|  Dave | 75000|         HR|Building C|
# |     40|  null|   null|  null|    Finance|Building D|  ← Finance included
# +-------+------+-------+------+-----------+----------+
```

### 4. Full Outer Join

Returns all rows from **both** DataFrames. NULL for no match on either side.

```python
result = employees.join(departments, "dept_id", "outer")
# OR
result = employees.join(departments, "dept_id", "full")
# OR
result = employees.join(departments, "dept_id", "full_outer")

result.show()
# +-------+------+-------+------+-----------+----------+
# |dept_id|emp_id|  name |salary|  dept_name|  location|
# +-------+------+-------+------+-----------+----------+
# |     10|     1| Alice |100000|Engineering|Building A|
# |     10|     3| Carol | 85000|Engineering|Building A|
# |     20|     2|   Bob | 90000|      Sales|Building B|
# |     30|     4|  Dave | 75000|         HR|Building C|
# |   null|     5|   Eve | 70000|       null|      null|  ← Eve (no dept)
# |     40|  null|   null|  null|    Finance|Building D|  ← Finance (no emp)
# +-------+------+-------+------+-----------+----------+
```

### 5. Left Semi Join

Returns rows from **left** that have a match in right. **Only left columns returned.**

```python
result = employees.join(departments, "dept_id", "left_semi")

result.show()
# +------+-------+-------+------+
# |emp_id|  name |dept_id|salary|
# +------+-------+-------+------+
# |     1| Alice |     10|100000|
# |     2|   Bob |     20| 90000|
# |     3| Carol |     10| 85000|
# |     4|  Dave |     30| 75000|
# +------+-------+-------+------+
# Note: Only employee columns, and only those with valid departments
```

Think of it as: `WHERE dept_id IN (SELECT dept_id FROM departments)`

### 6. Left Anti Join

Returns rows from **left** that have **NO match** in right. **Only left columns returned.**

```python
result = employees.join(departments, "dept_id", "left_anti")

result.show()
# +------+-----+-------+------+
# |emp_id| name|dept_id|salary|
# +------+-----+-------+------+
# |     5|  Eve|   null| 70000|
# +------+-----+-------+------+
# Note: Only Eve (no matching department)
```

Think of it as: `WHERE dept_id NOT IN (SELECT dept_id FROM departments)`

### 7. Cross Join (Cartesian Product)

Returns every combination of rows from both DataFrames. ⚠️ **Dangerous for large datasets!**

```python
result = employees.crossJoin(departments)

result.count()  # employees.count() * departments.count() = 5 * 4 = 20 rows!

# Cross join is useful for generating combinations:
# - All product-customer combinations
# - Date scaffolding (all dates × all categories)
```

---

## 📊 Join Type Summary

| Join Type | Left Rows | Right Rows | Use Case |
|-----------|-----------|------------|----------|
| **inner** | Matching only | Matching only | Standard combine |
| **left** | All | Matching + NULL | Keep all left data |
| **right** | Matching + NULL | All | Keep all right data |
| **outer** | All + NULL | All + NULL | Keep everything |
| **left_semi** | Matching only | None | Filter by existence |
| **left_anti** | Non-matching | None | Filter by non-existence |
| **cross** | All × | × All | Cartesian product |

---

## 🔧 Join Syntax Options

### Single Column Join (Same Name)

```python
# Best approach - avoids duplicate columns
df1.join(df2, "common_column")
df1.join(df2, "common_column", "inner")
```

### Multiple Column Join (Same Names)

```python
# Join on multiple columns
df1.join(df2, ["col1", "col2"], "inner")
```

### Different Column Names

```python
# When columns have different names
df1.join(df2, df1.emp_dept_id == df2.department_id, "inner")

# ⚠️ This creates duplicate columns! Handle them:
result = df1.join(df2, df1.emp_dept_id == df2.department_id, "inner") \
    .drop(df2.department_id)  # Drop the duplicate
```

### Complex Join Conditions

```python
# Multiple conditions
result = df1.join(df2, 
    (df1.dept_id == df2.dept_id) & 
    (df1.year == df2.year), 
    "inner")

# With OR condition
result = df1.join(df2, 
    (df1.id == df2.id) | 
    (df1.alt_id == df2.id), 
    "left")
```

---

## 🚀 Broadcast Joins (Optimization)

### What is a Broadcast Join?

When one DataFrame is small, Spark can send it to all executors to avoid shuffle.

```
┌────────────────────────────────────────────────────────────────────────┐
│                      BROADCAST JOIN                                     │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Normal Join (Shuffle Both):                                          │
│   Large DF ───shuffle───┐                                              │
│                         ├──► JOIN ──► Result                           │
│   Small DF ───shuffle───┘                                              │
│                                                                         │
│   Broadcast Join (No Shuffle):                                         │
│   Large DF ────────────────────────┐                                   │
│                                    ├──► JOIN ──► Result                │
│   Small DF ──broadcast to all──────┘                                   │
│                                                                         │
│   Small table copied to each partition of large table                  │
│   No shuffle of large table needed!                                    │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Using Broadcast

```python
from pyspark.sql.functions import broadcast

# Broadcast small table
result = large_df.join(broadcast(small_df), "key")

# Spark automatically broadcasts tables under threshold:
# spark.sql.autoBroadcastJoinThreshold = 10MB (default)

# Disable auto-broadcast:
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", -1)
```

### When to Use Broadcast

| Scenario | Use Broadcast? |
|----------|---------------|
| One table < 10MB | Yes (automatic) |
| One table < 100MB | Yes (explicit) |
| One table < 1GB | Maybe (depends on cluster) |
| Both tables large | No - use sort-merge join |
| Memory-constrained | Be careful |

---

## ⚠️ Common Join Pitfalls

### 1. Duplicate Columns

```python
# ❌ Problem: Both DataFrames have 'dept_id'
result = employees.join(departments, 
    employees.dept_id == departments.dept_id)
# Result has TWO 'dept_id' columns!

# ✅ Solution 1: Use common column name syntax
result = employees.join(departments, "dept_id")

# ✅ Solution 2: Drop duplicate explicitly
result = employees.join(departments, 
    employees.dept_id == departments.dept_id) \
    .drop(departments.dept_id)

# ✅ Solution 3: Rename before join
departments_renamed = departments.withColumnRenamed("dept_id", "d_dept_id")
```

### 2. Ambiguous Column Reference

```python
# ❌ Problem: Can't reference 'dept_id' - it's ambiguous
result = employees.join(departments, 
    employees.dept_id == departments.dept_id)
result.select("dept_id")  # Which one?

# ✅ Solution: Use DataFrame reference
result.select(employees.dept_id)
# OR alias DataFrames
emp = employees.alias("emp")
dept = departments.alias("dept")
result = emp.join(dept, col("emp.dept_id") == col("dept.dept_id"))
```

### 3. NULL Values in Join Keys

```python
# NULLs never match in standard joins
# Row with dept_id = NULL won't join to anything

# To join NULLs, use eqNullSafe:
result = df1.join(df2, df1.key.eqNullSafe(df2.key))
```

### 4. Cartesian Product Warning

```python
# ❌ Accidental cross join (no join key specified)
result = df1.join(df2)  # This is a CROSS JOIN!

# Spark 2.x+ requires explicit cross join:
spark.conf.set("spark.sql.crossJoin.enabled", "true")
# Or use:
result = df1.crossJoin(df2)
```

### 5. Data Skew in Joins

```python
# When one key has many more values than others
# Solution: Salting

# Add random salt to skewed key
df1_salted = df1.withColumn("salt", (rand() * 10).cast("int"))
df1_salted = df1_salted.withColumn("salted_key", 
    concat(col("key"), lit("_"), col("salt")))

# Explode the dimension table with all salt values
salt_df = spark.range(0, 10).withColumnRenamed("id", "salt")
df2_exploded = df2.crossJoin(salt_df)
df2_exploded = df2_exploded.withColumn("salted_key",
    concat(col("key"), lit("_"), col("salt")))

# Now join on salted key
result = df1_salted.join(df2_exploded, "salted_key")
```

---

## 💡 Best Practices

### 1. Filter Before Joining

```python
# ❌ Bad: Join then filter
result = large_df.join(other_df, "key").filter(col("status") == "active")

# ✅ Good: Filter then join
filtered = large_df.filter(col("status") == "active")
result = filtered.join(other_df, "key")
```

### 2. Use Broadcast for Small Tables

```python
# Lookup tables, dimension tables, configuration tables
result = fact_table.join(broadcast(dim_table), "dim_key")
```

### 3. Select Only Needed Columns

```python
# ❌ Bad: Join everything
result = df1.join(df2, "key")

# ✅ Good: Select needed columns first
df1_slim = df1.select("key", "col1", "col2")
df2_slim = df2.select("key", "col3")
result = df1_slim.join(df2_slim, "key")
```

### 4. Handle Nulls Appropriately

```python
# Filter out nulls before join if they shouldn't match
df1_clean = df1.filter(col("key").isNotNull())
result = df1_clean.join(df2, "key")
```

---

## 🎓 Interview Questions

### Q1: What are the different types of joins in PySpark?
**A:**
- **inner**: Only matching rows
- **left/left_outer**: All left + matching right
- **right/right_outer**: All right + matching left
- **outer/full/full_outer**: All from both
- **left_semi**: Left rows with match (no right columns)
- **left_anti**: Left rows without match
- **cross**: Cartesian product

### Q2: What is a broadcast join and when should you use it?
**A:** Broadcast join sends the smaller table to all executors to avoid shuffling the large table. Use when:
- One table is small (< 10-100MB)
- Joining fact table with dimension table
- Want to avoid expensive shuffle

### Q3: How do you handle duplicate columns after a join?
**A:**
1. Use common column name syntax: `df1.join(df2, "col")`
2. Drop duplicates: `.drop(df2.col)`
3. Rename before join: `withColumnRenamed()`
4. Use aliases: `df1.alias("a")`, `col("a.col")`

### Q4: What is data skew and how do you handle it in joins?
**A:** Data skew occurs when some keys have many more rows than others. Solutions:
- **Salting**: Add random suffix to keys
- **Broadcast**: If one side is small enough
- **Isolate skewed keys**: Handle separately
- **Repartition**: Better distribute data

### Q5: What's the difference between left semi and left anti joins?
**A:**
- **left_semi**: Returns left rows that HAVE a match in right
- **left_anti**: Returns left rows that DON'T have a match in right
Both return only left table columns.

### Q6: How do NULLs behave in joins?
**A:** NULLs never match other NULLs in standard joins. To match NULLs, use `eqNullSafe()`:
```python
df1.join(df2, df1.key.eqNullSafe(df2.key))
```

### Q7: How do you join on multiple columns?
**A:**
```python
# Same column names
df1.join(df2, ["col1", "col2"])

# Different names
df1.join(df2, (df1.a == df2.x) & (df1.b == df2.y))
```

### Q8: What is a shuffle in context of joins?
**A:** Shuffle redistributes data across partitions so matching keys are on same node. It involves:
- Writing intermediate data to disk
- Network transfer between nodes
- Expensive operation

Broadcast joins avoid shuffle for small tables.

### Q9: How do you optimize large-to-large joins?
**A:**
1. **Partition on join key**: Co-locate data
2. **Filter before join**: Reduce data volume
3. **Select only needed columns**
4. **Handle skew with salting**
5. **Increase parallelism**: More partitions
6. **Sort-merge join**: For very large tables

### Q10: What happens in a cross join?
**A:** Every row in first table is paired with every row in second table. Result size = rows1 × rows2. Very expensive - use with caution!

---

## 🔗 Related Topics
- [← Window Functions](./05_window_functions.md)
- [Performance Optimization →](./07_performance.md)
- [Spark SQL →](./08_spark_sql.md)

---

*Next: Learn about Performance Optimization in PySpark*
