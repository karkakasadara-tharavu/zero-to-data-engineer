# Advanced PySpark - User Defined Functions (UDFs)

## 📚 What You'll Learn
- Python UDFs vs Pandas UDFs
- Creating and registering UDFs
- Performance considerations
- Vectorized UDFs (Pandas UDFs)
- Best practices
- Interview preparation

**Duration**: 1.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 What are UDFs?

**User Defined Functions (UDFs)** allow you to extend PySpark with custom logic when built-in functions aren't sufficient.

```
┌────────────────────────────────────────────────────────────────────────┐
│                         UDF Flow                                        │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   DataFrame Row (JVM/Scala)                                            │
│         │                                                               │
│         ▼                                                               │
│   Serialize to Python                                                  │
│         │                                                               │
│         ▼                                                               │
│   Execute Python Function                                              │
│         │                                                               │
│         ▼                                                               │
│   Serialize back to JVM                                                │
│         │                                                               │
│         ▼                                                               │
│   Continue Processing                                                  │
│                                                                         │
│   ⚠️ This serialization is EXPENSIVE!                                  │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Sample Data Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder.appName("UDFs").getOrCreate()

# Sample data
data = [
    (1, "Alice Smith", "alice.smith@email.com", 100000),
    (2, "Bob Jones", "BOB.JONES@EMAIL.COM", 90000),
    (3, "Carol Williams", "carol@company.org", 85000),
    (4, "Dave Brown", None, 75000),
]

df = spark.createDataFrame(data, ["id", "name", "email", "salary"])
df.show()
```

---

## 🔧 Creating Python UDFs

### Method 1: Using @udf Decorator

```python
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType

# Define UDF with decorator
@udf(returnType=StringType())
def extract_first_name(full_name):
    if full_name is None:
        return None
    return full_name.split()[0]

# Use the UDF
df.withColumn("first_name", extract_first_name(col("name"))).show()

# Output:
# +---+--------------+--------------------+------+----------+
# | id|          name|               email|salary|first_name|
# +---+--------------+--------------------+------+----------+
# |  1|   Alice Smith|alice.smith@email...|100000|     Alice|
# |  2|     Bob Jones|BOB.JONES@EMAIL.COM | 90000|       Bob|
# |  3|Carol Williams|   carol@company.org| 85000|     Carol|
# |  4|    Dave Brown|                null| 75000|      Dave|
# +---+--------------+--------------------+------+----------+
```

### Method 2: Using udf() Function

```python
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType

# Define function
def normalize_email(email):
    if email is None:
        return None
    return email.lower().strip()

# Create UDF
normalize_email_udf = udf(normalize_email, StringType())

# Use the UDF
df.withColumn("email_normalized", normalize_email_udf(col("email"))).show()
```

### Method 3: Lambda UDF

```python
# For simple transformations
double_salary = udf(lambda x: x * 2 if x else None, IntegerType())

df.withColumn("double_salary", double_salary(col("salary"))).show()
```

---

## 📝 Registering UDFs for SQL

### Register for SQL Use

```python
# Define function
def get_salary_grade(salary):
    if salary is None:
        return "Unknown"
    if salary >= 100000:
        return "A"
    elif salary >= 80000:
        return "B"
    elif salary >= 60000:
        return "C"
    else:
        return "D"

# Register for SQL
spark.udf.register("salary_grade", get_salary_grade, StringType())

# Create temp view
df.createOrReplaceTempView("employees")

# Use in SQL
spark.sql("""
    SELECT name, salary, salary_grade(salary) as grade
    FROM employees
""").show()
```

### Using with DataFrames After Registration

```python
# After registering, can use with expr()
df.withColumn("grade", expr("salary_grade(salary)")).show()
```

---

## 🔢 UDF Return Types

### Primitive Types

```python
from pyspark.sql.types import *

# String
@udf(StringType())
def to_upper(s):
    return s.upper() if s else None

# Integer
@udf(IntegerType())
def string_length(s):
    return len(s) if s else 0

# Double/Float
@udf(DoubleType())
def calculate_tax(salary):
    return salary * 0.25 if salary else 0.0

# Boolean
@udf(BooleanType())
def is_manager(title):
    return "manager" in title.lower() if title else False
```

### Complex Types

```python
# Array
@udf(ArrayType(StringType()))
def split_name(name):
    return name.split() if name else []

df.withColumn("name_parts", split_name(col("name"))).show()

# Map
@udf(MapType(StringType(), StringType()))
def create_email_map(email):
    if email is None:
        return {}
    parts = email.split("@")
    return {"user": parts[0], "domain": parts[1]} if len(parts) == 2 else {}

df.withColumn("email_map", create_email_map(col("email"))).show()

# Struct
schema = StructType([
    StructField("first", StringType(), True),
    StructField("last", StringType(), True)
])

@udf(schema)
def parse_name(name):
    if name is None:
        return (None, None)
    parts = name.split()
    if len(parts) >= 2:
        return (parts[0], parts[-1])
    return (name, None)

df.withColumn("parsed", parse_name(col("name"))) \
  .select("name", "parsed.first", "parsed.last").show()
```

---

## 🐼 Pandas UDFs (Vectorized UDFs)

Pandas UDFs are **much faster** than regular Python UDFs because they:
- Process data in batches (Arrow format)
- Leverage vectorized operations
- Minimize serialization overhead

### Types of Pandas UDFs

```
┌────────────────────────────────────────────────────────────────────────┐
│                     Pandas UDF Types (Spark 3.0+)                       │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   1. SCALAR UDF                                                        │
│      Input: pandas.Series → Output: pandas.Series                      │
│      Use: Transform column values                                      │
│                                                                         │
│   2. GROUPED MAP UDF                                                   │
│      Input: pandas.DataFrame → Output: pandas.DataFrame                │
│      Use: Apply custom logic to each group                             │
│                                                                         │
│   3. GROUPED AGG UDF                                                   │
│      Input: pandas.Series → Output: scalar                             │
│      Use: Custom aggregation functions                                 │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Scalar Pandas UDF

```python
import pandas as pd
from pyspark.sql.functions import pandas_udf

# Scalar UDF - element-wise operation
@pandas_udf(StringType())
def normalize_email_vec(emails: pd.Series) -> pd.Series:
    return emails.str.lower().str.strip()

df.withColumn("email_clean", normalize_email_vec(col("email"))).show()
```

### With Multiple Columns (Iterator)

```python
from typing import Iterator

@pandas_udf(DoubleType())
def calculate_bonus(
    salary: pd.Series, 
    performance: pd.Series
) -> pd.Series:
    return salary * (performance / 100)

# Usage
# df.withColumn("bonus", calculate_bonus(col("salary"), col("performance")))
```

### Grouped Map Pandas UDF

```python
from pyspark.sql.functions import pandas_udf, PandasUDFType

# Define output schema
output_schema = StructType([
    StructField("department", StringType(), True),
    StructField("name", StringType(), True),
    StructField("salary", IntegerType(), True),
    StructField("salary_zscore", DoubleType(), True)
])

@pandas_udf(output_schema, PandasUDFType.GROUPED_MAP)
def normalize_salaries(pdf: pd.DataFrame) -> pd.DataFrame:
    mean_sal = pdf['salary'].mean()
    std_sal = pdf['salary'].std()
    pdf['salary_zscore'] = (pdf['salary'] - mean_sal) / std_sal if std_sal > 0 else 0
    return pdf

# Usage with groupBy + applyInPandas (Spark 3.0+)
df_with_dept = spark.createDataFrame([
    ("IT", "Alice", 100000),
    ("IT", "Bob", 90000),
    ("Sales", "Carol", 80000),
    ("Sales", "Dave", 85000),
], ["department", "name", "salary"])

result = df_with_dept.groupby("department").applyInPandas(
    normalize_salaries, 
    schema=output_schema
)
result.show()
```

### Grouped Aggregate Pandas UDF

```python
@pandas_udf(DoubleType(), PandasUDFType.GROUPED_AGG)
def median_udf(values: pd.Series) -> float:
    return values.median()

# Usage
df_with_dept.groupby("department").agg(
    median_udf(col("salary")).alias("median_salary")
).show()
```

---

## ⚡ Performance Comparison

```python
import time

# Create larger dataset
large_data = [(i, f"User_{i}", f"user{i}@email.com", 50000 + (i * 100)) 
              for i in range(100000)]
large_df = spark.createDataFrame(large_data, ["id", "name", "email", "salary"])

# Regular Python UDF
@udf(StringType())
def python_upper(s):
    return s.upper() if s else None

# Pandas UDF
@pandas_udf(StringType())
def pandas_upper(s: pd.Series) -> pd.Series:
    return s.str.upper()

# Time regular UDF
start = time.time()
large_df.withColumn("upper_name", python_upper(col("name"))).count()
python_time = time.time() - start

# Time Pandas UDF
start = time.time()
large_df.withColumn("upper_name", pandas_upper(col("name"))).count()
pandas_time = time.time() - start

print(f"Python UDF: {python_time:.2f}s")
print(f"Pandas UDF: {pandas_time:.2f}s")
print(f"Speedup: {python_time/pandas_time:.2f}x")

# Typical result: Pandas UDF is 3-100x faster!
```

---

## 💡 Best Practices

### 1. Prefer Built-in Functions

```python
# ❌ Bad: Using UDF for what built-in can do
@udf(StringType())
def my_upper(s):
    return s.upper() if s else None

# ✅ Good: Use built-in function
from pyspark.sql.functions import upper
df.withColumn("upper_name", upper(col("name")))
```

### 2. Use Pandas UDFs When Possible

```python
# ❌ Slow: Python UDF
@udf(DoubleType())
def slow_calc(x):
    return math.sqrt(x) if x else None

# ✅ Fast: Pandas UDF
@pandas_udf(DoubleType())
def fast_calc(x: pd.Series) -> pd.Series:
    return np.sqrt(x)
```

### 3. Handle Null Values

```python
# ❌ Bad: Crashes on NULL
@udf(StringType())
def bad_udf(s):
    return s.upper()  # NoneType has no upper()!

# ✅ Good: Handle NULL
@udf(StringType())
def good_udf(s):
    return s.upper() if s is not None else None
```

### 4. Avoid Side Effects

```python
# ❌ Bad: Side effects in UDF
results = []
@udf(IntegerType())
def bad_udf(x):
    results.append(x)  # Side effect - won't work as expected
    return x * 2

# ✅ Good: Pure function
@udf(IntegerType())
def good_udf(x):
    return x * 2 if x else None
```

### 5. Consider UDF Input/Output Overhead

```python
# ❌ Bad: Multiple UDF calls
df.withColumn("a", udf1(col("x"))) \
  .withColumn("b", udf2(col("x"))) \
  .withColumn("c", udf3(col("x")))

# ✅ Good: Single UDF returning struct
@udf(StructType([
    StructField("a", IntegerType()),
    StructField("b", StringType()),
    StructField("c", DoubleType())
]))
def combined_udf(x):
    return (x*2, str(x), float(x)/2)

result = df.withColumn("combined", combined_udf(col("x")))
```

---

## 🎓 Interview Questions

### Q1: What is a UDF in PySpark?
**A:** User Defined Function allows custom Python logic when built-in functions aren't sufficient. UDFs are applied to DataFrame columns, transforming values row by row.

### Q2: Why are Python UDFs slow?
**A:** Python UDFs require:
1. Serializing data from JVM to Python
2. Executing Python function row by row
3. Serializing results back to JVM

This serialization overhead is expensive, especially for large datasets.

### Q3: What are Pandas UDFs and why are they faster?
**A:** Pandas UDFs (vectorized UDFs) process data in batches using Arrow format:
- Data transferred in columnar batches, not row by row
- Leverage vectorized pandas/numpy operations
- Minimize serialization overhead
- Can be 3-100x faster than regular Python UDFs

### Q4: What are the types of Pandas UDFs?
**A:**
- **Scalar**: Series → Series (element-wise)
- **Grouped Map**: DataFrame → DataFrame (per group)
- **Grouped Aggregate**: Series → scalar (aggregation)

### Q5: How do you handle NULL values in UDFs?
**A:**
```python
@udf(StringType())
def safe_udf(value):
    if value is None:
        return None
    return value.upper()
```
Always check for None before processing.

### Q6: When should you use a UDF vs built-in function?
**A:** 
- **Built-in**: Always prefer when available (optimized, Catalyst-aware)
- **Pandas UDF**: For complex logic not available in built-ins
- **Python UDF**: Last resort, for simple logic with small data

### Q7: How do you register a UDF for use in Spark SQL?
**A:**
```python
spark.udf.register("my_udf", my_function, return_type)
# Then use in SQL:
spark.sql("SELECT my_udf(column) FROM table")
```

### Q8: Can UDFs return complex types?
**A:** Yes, UDFs can return:
- Arrays: `ArrayType(ElementType())`
- Maps: `MapType(KeyType(), ValueType())`
- Structs: `StructType([StructField(...), ...])`

### Q9: What are the limitations of UDFs?
**A:**
- **Performance**: Serialization overhead
- **Optimization**: Catalyst can't optimize UDF logic
- **Type Safety**: Runtime errors vs compile-time
- **Portability**: Python UDFs only work in PySpark

### Q10: How do you debug a UDF?
**A:**
1. Test function separately with sample data
2. Use `try-except` and return error info
3. Test on small DataFrame first
4. Check for NULL handling
5. Verify return type matches schema

---

## 🔗 Related Topics
- [← Joins](../Module_15_PySpark_Fundamentals/06_joins.md)
- [Spark SQL →](./02_spark_sql.md)
- [Performance Optimization →](./03_performance.md)

---

*Next: Learn about Spark SQL in depth*
