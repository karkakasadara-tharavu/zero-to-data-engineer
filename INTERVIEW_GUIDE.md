# Data Engineering Interview Reference Guide

## Complete Technical Interview Preparation

This comprehensive guide covers all major data engineering topics with common interview questions, answers, and key concepts. Use this as your go-to reference for technical interviews.

---

## Table of Contents
1. [SQL Fundamentals](#sql-fundamentals)
2. [Advanced SQL](#advanced-sql)
3. [Database Design & Constraints](#database-design--constraints)
4. [ETL & Data Pipelines](#etl--data-pipelines)
5. [Data Warehousing](#data-warehousing)
6. [Python for Data Engineering](#python-for-data-engineering)
7. [PySpark & Big Data](#pyspark--big-data)
8. [Data Quality](#data-quality)
9. [System Design](#system-design)

---

## SQL Fundamentals

### Key Concepts

| Concept | Definition | Use Case |
|---------|------------|----------|
| SELECT | Retrieve data from tables | All queries |
| WHERE | Filter rows | Conditional filtering |
| JOIN | Combine tables | Relational queries |
| GROUP BY | Aggregate data | Summarization |
| ORDER BY | Sort results | Presentation |
| HAVING | Filter aggregates | Group-level filtering |

### Interview Questions

**Q1: What's the difference between WHERE and HAVING?**
```
WHERE: Filters rows BEFORE grouping (can't use aggregates)
HAVING: Filters groups AFTER grouping (can use aggregates)

Example:
SELECT department, AVG(salary)
FROM employees
WHERE hire_date > '2020-01-01'    -- Filters rows first
GROUP BY department
HAVING AVG(salary) > 50000;       -- Then filters groups
```

**Q2: Explain the different types of JOINs.**
```
INNER JOIN: Only matching rows from both tables
LEFT JOIN:  All rows from left + matching from right (NULL if no match)
RIGHT JOIN: All rows from right + matching from left (NULL if no match)
FULL JOIN:  All rows from both (NULL where no match)
CROSS JOIN: Cartesian product (every row × every row)
SELF JOIN:  Table joined to itself (hierarchies, comparisons)
```

**Q3: What's the order of SQL clause execution?**
```
1. FROM / JOIN    - Get the data sources
2. WHERE          - Filter rows
3. GROUP BY       - Create groups
4. HAVING         - Filter groups
5. SELECT         - Choose columns
6. DISTINCT       - Remove duplicates
7. ORDER BY       - Sort results
8. LIMIT/OFFSET   - Limit rows returned
```

**Q4: What's the difference between UNION and UNION ALL?**
```
UNION: Combines results and removes duplicates (slower)
UNION ALL: Combines results keeping all rows (faster)

Use UNION ALL when:
- You know there are no duplicates
- Performance is critical
- Duplicates are acceptable
```

**Q5: How do you handle NULL values?**
```sql
-- Check for NULL
WHERE column IS NULL
WHERE column IS NOT NULL

-- Replace NULL
COALESCE(column, 'default')     -- First non-null value
ISNULL(column, 'default')       -- SQL Server
NVL(column, 'default')          -- Oracle
IFNULL(column, 'default')       -- MySQL

-- NULL in comparisons
NULL = NULL  → NULL (not TRUE!)
NULL <> NULL → NULL (not TRUE!)
Use IS NULL or IS NOT NULL
```

---

## Advanced SQL

### CTEs (Common Table Expressions)

**What is a CTE?**
A CTE is a temporary named result set defined within a single SQL statement using the WITH clause.

```sql
WITH sales_summary AS (
    SELECT 
        region,
        SUM(amount) AS total_sales,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY region
)
SELECT * FROM sales_summary
WHERE total_sales > 100000;
```

**When to use CTEs vs Temp Tables vs Subqueries:**

| Feature | CTE | Temp Table | Subquery |
|---------|-----|------------|----------|
| Scope | Single query | Session | Single query |
| Reusable | In same query | Across queries | No |
| Indexable | No | Yes | No |
| Recursive | Yes | No | No |
| Performance | Same as subquery | Better for large data | Same as CTE |

### Window Functions

**What are window functions?**
Functions that perform calculations across a set of rows related to the current row, without collapsing them.

```sql
SELECT 
    employee_id,
    department,
    salary,
    -- Ranking functions
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK() OVER (ORDER BY salary DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank,
    
    -- Aggregate window functions
    SUM(salary) OVER (PARTITION BY department) AS dept_total,
    AVG(salary) OVER (PARTITION BY department) AS dept_avg,
    
    -- Offset functions
    LAG(salary, 1) OVER (ORDER BY hire_date) AS prev_salary,
    LEAD(salary, 1) OVER (ORDER BY hire_date) AS next_salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department ORDER BY hire_date) AS first_hire_salary
FROM employees;
```

**ROW_NUMBER vs RANK vs DENSE_RANK:**
```
Values: 100, 100, 90, 80

ROW_NUMBER: 1, 2, 3, 4 (always unique)
RANK:       1, 1, 3, 4 (skips after ties)
DENSE_RANK: 1, 1, 2, 3 (no gaps)
```

### Interview Questions - Advanced SQL

**Q1: Write a query to find the second highest salary.**
```sql
-- Method 1: Subquery
SELECT MAX(salary) 
FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Method 2: Window function
WITH ranked AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT DISTINCT salary FROM ranked WHERE rnk = 2;

-- Method 3: OFFSET
SELECT DISTINCT salary 
FROM employees 
ORDER BY salary DESC 
OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;
```

**Q2: Find employees earning more than their manager.**
```sql
SELECT e.name AS employee, e.salary AS emp_salary,
       m.name AS manager, m.salary AS mgr_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;
```

**Q3: Write a running total query.**
```sql
SELECT 
    order_date,
    amount,
    SUM(amount) OVER (ORDER BY order_date ROWS UNBOUNDED PRECEDING) AS running_total
FROM orders;
```

**Q4: Find duplicate records.**
```sql
-- Method 1: GROUP BY + HAVING
SELECT email, COUNT(*) AS count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- Method 2: Window function
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
    FROM users
)
SELECT * FROM ranked WHERE rn > 1;
```

---

## Database Design & Constraints

### The 6 Types of Constraints

| Constraint | Purpose | Example |
|------------|---------|---------|
| PRIMARY KEY | Unique row identifier | `CustomerID INT PRIMARY KEY` |
| FOREIGN KEY | Referential integrity | `REFERENCES Customers(CustomerID)` |
| UNIQUE | No duplicate values | `Email NVARCHAR(255) UNIQUE` |
| CHECK | Validate against condition | `CHECK (Price > 0)` |
| DEFAULT | Automatic value | `DEFAULT GETDATE()` |
| NOT NULL | Require a value | `Name NVARCHAR(100) NOT NULL` |

### Normalization

| Form | Rule | Example Violation |
|------|------|-------------------|
| 1NF | Atomic values, no repeating groups | `Phone1, Phone2, Phone3` columns |
| 2NF | 1NF + No partial dependencies | Non-key depending on part of composite key |
| 3NF | 2NF + No transitive dependencies | City depending on ZipCode, not PK |
| BCNF | Every determinant is a candidate key | Rare edge cases |

### Interview Questions - Database Design

**Q1: What is normalization and why is it important?**
```
Normalization is organizing tables to reduce redundancy and dependency.

Benefits:
- Reduces data redundancy
- Ensures data consistency
- Simplifies updates
- Saves storage space

Trade-off:
- More JOINs needed (can impact performance)
- Data warehouses often denormalize for query speed
```

**Q2: When would you denormalize?**
```
- Read-heavy workloads (data warehouses, reporting)
- When JOIN performance is critical
- Aggregated/pre-calculated values
- Data marts for specific use cases

Examples:
- Storing customer_name in orders table (avoid JOIN)
- Pre-calculated totals
- Flattened dimension tables
```

**Q3: Explain referential integrity.**
```
Referential integrity ensures relationships between tables remain valid:
- Child records must reference existing parent records
- Cannot delete parent if children exist (unless CASCADE)

Enforced by FOREIGN KEY constraints:
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
  ON DELETE CASCADE    -- Delete children when parent deleted
  ON DELETE SET NULL   -- Set FK to NULL when parent deleted
  ON DELETE NO ACTION  -- Block delete if children exist (default)
```

---

## ETL & Data Pipelines

### CDC (Change Data Capture)

**What is CDC?**
CDC automatically tracks INSERT, UPDATE, DELETE operations on tables and records changes for incremental processing.

**How it works:**
```
Transaction Log → CDC Capture Job → Change Tables → ETL Process
```

**Key CDC concepts:**
- **LSN (Log Sequence Number):** Unique identifier for each transaction
- **Change table:** Stores historical changes (`cdc.schema_table_CT`)
- **__$operation:** 1=DELETE, 2=INSERT, 3=UPDATE (before), 4=UPDATE (after)
- **Net changes:** Final state per row in time range

**CDC vs Full Load:**
```
Full Load:
- Process ALL records every time
- Simple but slow
- No change tracking

Incremental (CDC):
- Process only CHANGED records
- Fast (often 95%+ reduction)
- Requires setup and tracking
```

### SCD (Slowly Changing Dimensions)

**Types of SCDs:**

| Type | Behavior | Use Case |
|------|----------|----------|
| Type 0 | Never change | Fixed attributes |
| Type 1 | Overwrite | Corrections, non-historical |
| Type 2 | Add new row (history) | Full audit trail |
| Type 3 | Add column (limited history) | Previous value only |
| Type 4 | Separate history table | Performance optimization |
| Type 6 | Hybrid (1+2+3) | Current + history + previous |

**SCD Type 2 Example:**
```sql
-- Customer changes address: Chicago → New York

-- Before:
| CustomerKey | CustomerID | City    | StartDate  | EndDate    | IsCurrent |
|-------------|------------|---------|------------|------------|-----------|
| 1           | C001       | Chicago | 2020-01-01 | 9999-12-31 | 1         |

-- After:
| CustomerKey | CustomerID | City     | StartDate  | EndDate    | IsCurrent |
|-------------|------------|----------|------------|------------|-----------|
| 1           | C001       | Chicago  | 2020-01-01 | 2024-01-15 | 0         |
| 2           | C001       | New York | 2024-01-15 | 9999-12-31 | 1         |
```

### Interview Questions - ETL

**Q1: Design an ETL pipeline for daily sales data.**
```
1. EXTRACT:
   - Source: OLTP database, APIs, files
   - Method: CDC for incremental, full for small tables
   - Frequency: Nightly batch or near-real-time

2. TRANSFORM:
   - Data cleansing (nulls, duplicates, formats)
   - Business logic (calculations, derivations)
   - Surrogate key assignment
   - SCD processing

3. LOAD:
   - Staging tables first (truncate/reload)
   - Dimension tables (SCD logic)
   - Fact tables (append or merge)
   - Aggregation tables

4. MONITOR:
   - Row counts
   - Data quality checks
   - Duration tracking
   - Error alerting
```

**Q2: How do you handle data quality in ETL?**
```
1. VALIDATION:
   - Schema validation (data types, lengths)
   - Null checks on required fields
   - Referential integrity
   - Range checks (dates, amounts)

2. CLEANSING:
   - Standardize formats
   - Fix common errors
   - Handle missing values

3. QUARANTINE:
   - Route bad records to error table
   - Don't block entire load
   - Review and reprocess

4. MONITORING:
   - Quality metrics dashboard
   - Threshold alerts
   - Trend analysis
```

**Q3: Explain idempotency in ETL.**
```
Idempotent = Running the same process multiple times produces the same result.

Why it matters:
- Safe to rerun failed jobs
- No duplicate records
- Consistent results

How to achieve:
- Use MERGE (upsert) instead of INSERT
- Truncate-and-reload for small tables
- Track watermarks (last processed timestamp/ID)
- Delete-then-insert for updates
```

---

## Data Warehousing

### Dimensional Modeling

**Star Schema:**
```
        ┌─────────────┐
        │  Dim_Date   │
        └──────┬──────┘
               │
┌──────────────┼──────────────┐
│              │              │
▼              ▼              ▼
┌─────────┐ ┌─────────────┐ ┌──────────┐
│Dim_Store│◀│ Fact_Sales  │▶│Dim_Product│
└─────────┘ └─────────────┘ └──────────┘
               │
               ▼
        ┌─────────────┐
        │Dim_Customer │
        └─────────────┘
```

**Star vs Snowflake:**

| Aspect | Star Schema | Snowflake Schema |
|--------|-------------|------------------|
| Dimensions | Denormalized | Normalized |
| JOINs | Fewer | More |
| Storage | More redundancy | Less redundancy |
| Query Performance | Faster | Slower |
| Maintenance | Simpler | Complex |
| Use Case | Most DW scenarios | Very large dimensions |

### Fact Table Types

| Type | Contains | Example |
|------|----------|---------|
| Transaction | Individual events | Each sale, each click |
| Periodic Snapshot | State at intervals | Daily inventory levels |
| Accumulating Snapshot | Lifecycle metrics | Order fulfillment stages |
| Factless Fact | Events without measures | Student attendance |

### Interview Questions - Data Warehousing

**Q1: What is a surrogate key and why use it?**
```
Surrogate key: System-generated identifier (usually auto-increment integer)

Why use it:
- Business keys can change
- Consistent, simple JOINs
- Better performance (integer vs string)
- Handles SCD Type 2 (same business key, multiple rows)

Example:
| CustomerKey (Surrogate) | CustomerID (Business) | Name    |
|-------------------------|----------------------|---------|
| 1                       | C001                 | John    |
| 2                       | C001                 | John    | ← Same customer, different version
```

**Q2: Explain the grain of a fact table.**
```
Grain = The level of detail each row represents

Example grains for sales:
- Transaction grain: One row per line item
- Daily grain: One row per product per store per day
- Monthly grain: One row per product per region per month

Choosing grain:
- Start with lowest grain (most detail)
- Aggregate up as needed
- Can't drill down below the grain
```

**Q3: What are conformed dimensions?**
```
Conformed dimensions: Shared across multiple fact tables with consistent meaning

Benefits:
- Consistent reporting across subject areas
- Enable drill-across queries
- Single source of truth

Examples:
- Date dimension shared by Sales, Inventory, Orders
- Customer dimension shared by Sales, Support, Marketing
```

---

## Python for Data Engineering

### Key Libraries

| Library | Purpose | Key Functions |
|---------|---------|---------------|
| Pandas | Data manipulation | DataFrame, read_csv, merge, groupby |
| NumPy | Numerical computing | arrays, vectorized operations |
| SQLAlchemy | Database connectivity | create_engine, ORM |
| Requests | API calls | get, post, json |
| Airflow | Orchestration | DAGs, operators, scheduling |

### Pandas Operations

```python
import pandas as pd

# Reading data
df = pd.read_csv('data.csv')
df = pd.read_sql('SELECT * FROM table', connection)
df = pd.read_json('data.json')

# Data exploration
df.head()
df.info()
df.describe()
df.isnull().sum()

# Filtering
df[df['age'] > 30]
df[(df['age'] > 30) & (df['city'] == 'NYC')]
df.query('age > 30 and city == "NYC"')

# Aggregation
df.groupby('category')['amount'].agg(['sum', 'mean', 'count'])

# Joining
pd.merge(df1, df2, on='key', how='left')

# Handling missing values
df.fillna(0)
df.dropna(subset=['required_column'])

# Data transformation
df['new_col'] = df['col1'] + df['col2']
df['date'] = pd.to_datetime(df['date_str'])
```

### Interview Questions - Python

**Q1: How do you handle large datasets that don't fit in memory?**
```python
# 1. Chunking
for chunk in pd.read_csv('large.csv', chunksize=100000):
    process(chunk)

# 2. Use appropriate dtypes
df = pd.read_csv('data.csv', dtype={'id': 'int32', 'code': 'category'})

# 3. Select only needed columns
df = pd.read_csv('data.csv', usecols=['col1', 'col2'])

# 4. Use Dask for parallel processing
import dask.dataframe as dd
ddf = dd.read_csv('large.csv')

# 5. Use PySpark for distributed processing
```

**Q2: Explain the difference between apply, map, and applymap.**
```python
# map: Element-wise on Series only
df['col'].map(lambda x: x.upper())

# apply: Row/column-wise on DataFrame or Series
df['col'].apply(lambda x: x.upper())  # Series
df.apply(sum, axis=0)  # Column-wise
df.apply(sum, axis=1)  # Row-wise

# applymap: Element-wise on entire DataFrame (deprecated, use map)
df.applymap(lambda x: str(x))  # Old
df.map(lambda x: str(x))       # New (pandas 2.1+)
```

---

## PySpark & Big Data

### Core Concepts

**RDD vs DataFrame vs Dataset:**

| Feature | RDD | DataFrame | Dataset |
|---------|-----|-----------|---------|
| Type Safety | Runtime | Runtime | Compile-time |
| Optimization | No | Yes (Catalyst) | Yes (Catalyst) |
| Schema | No | Yes | Yes |
| Language | All | All | Scala/Java only |
| Performance | Lower | Higher | Higher |

### Common Operations

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, avg, when, lit

# Create session
spark = SparkSession.builder.appName("ETL").getOrCreate()

# Read data
df = spark.read.parquet("s3://bucket/data/")
df = spark.read.format("delta").load("path")

# Transformations
df.select("col1", "col2")
df.filter(col("age") > 30)
df.withColumn("new_col", col("col1") + col("col2"))
df.groupBy("category").agg(sum("amount"), avg("price"))

# Joins
df1.join(df2, "key", "left")
df1.join(df2, df1.id == df2.id, "inner")

# Window functions
from pyspark.sql.window import Window
window = Window.partitionBy("dept").orderBy("salary")
df.withColumn("rank", rank().over(window))

# Write data
df.write.mode("overwrite").partitionBy("date").parquet("output/")
```

### Interview Questions - PySpark

**Q1: Explain transformations vs actions in Spark.**
```
Transformations: Lazy operations that define computation
- select(), filter(), join(), groupBy()
- Don't execute immediately
- Build a DAG (Directed Acyclic Graph)

Actions: Trigger computation and return results
- count(), show(), collect(), write()
- Execute the DAG
- Return data to driver or write to storage

Example:
df.filter(...).select(...)  # No execution yet (transformations)
df.filter(...).select(...).count()  # Executes everything (action)
```

**Q2: How do you optimize PySpark jobs?**
```
1. PARTITIONING:
   - Right number of partitions (2-4x cores)
   - Partition by frequently filtered columns
   - Avoid data skew

2. CACHING:
   - cache() for reused DataFrames
   - persist() with storage level for control

3. BROADCAST JOINS:
   - Small table < 10MB broadcast to all nodes
   - Avoids expensive shuffle

4. AVOID:
   - collect() on large data
   - UDFs when built-in functions exist
   - Wide transformations when possible

5. FILE FORMAT:
   - Use Parquet/ORC (columnar, compressed)
   - Appropriate file sizes (128MB-1GB)
```

**Q3: What is data skew and how do you handle it?**
```
Data skew: Uneven distribution of data across partitions

Symptoms:
- One task takes much longer than others
- OOM errors on some executors

Solutions:
1. SALTING: Add random suffix to skewed keys
   df.withColumn("salted_key", concat(col("key"), lit("_"), (rand() * 10).cast("int")))

2. BROADCAST JOIN: Force small table broadcast
   df1.join(broadcast(df2), "key")

3. REPARTITION: Redistribute data
   df.repartition(100, "key")

4. ADAPTIVE QUERY EXECUTION (Spark 3.0+):
   spark.conf.set("spark.sql.adaptive.enabled", "true")
```

---

## Data Quality

### Data Quality Dimensions

| Dimension | Definition | Example Check |
|-----------|------------|---------------|
| Completeness | No missing values | NULL count < threshold |
| Accuracy | Correct values | Email format validation |
| Consistency | Same across sources | Customer ID matches |
| Timeliness | Data is current | Last update within SLA |
| Uniqueness | No duplicates | Distinct count = total count |
| Validity | Meets business rules | Age between 0 and 120 |

### Data Validation Example

```python
from great_expectations import expect

# Define expectations
expect(df).expect_column_to_exist("customer_id")
expect(df).expect_column_values_to_not_be_null("email")
expect(df).expect_column_values_to_be_unique("order_id")
expect(df).expect_column_values_to_match_regex("email", r".*@.*\..*")
expect(df).expect_column_values_to_be_between("age", 0, 120)
```

### Interview Questions - Data Quality

**Q1: How do you implement data quality checks in a pipeline?**
```
1. INGESTION LAYER:
   - Schema validation
   - Required fields check
   - Basic format validation

2. TRANSFORMATION LAYER:
   - Business rule validation
   - Cross-field validation
   - Referential integrity

3. LOAD LAYER:
   - Record counts reconciliation
   - Aggregation validation
   - Post-load data profiling

4. QUARANTINE:
   - Failed records to error table
   - Include error reason
   - Alert on threshold breaches
```

---

## System Design

### Data Pipeline Design Questions

**Q1: Design a real-time analytics dashboard for an e-commerce site.**

```
REQUIREMENTS:
- Track orders, page views, conversions
- Update every few seconds
- Historical analysis also needed

ARCHITECTURE:

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Web/App    │───▶│   Kafka     │───▶│   Flink/    │
│  Events     │    │   Topics    │    │   Spark SS  │
└─────────────┘    └─────────────┘    └──────┬──────┘
                                             │
                          ┌──────────────────┴──────────────────┐
                          │                                      │
                          ▼                                      ▼
                   ┌─────────────┐                       ┌─────────────┐
                   │   Redis     │                       │ Data Lake   │
                   │ (Real-time) │                       │ (S3/Parquet)│
                   └──────┬──────┘                       └──────┬──────┘
                          │                                      │
                          ▼                                      ▼
                   ┌─────────────┐                       ┌─────────────┐
                   │ Real-time   │                       │   Batch     │
                   │ Dashboard   │                       │  Analytics  │
                   └─────────────┘                       └─────────────┘

COMPONENTS:
- Kafka: Message queue for event streaming
- Flink/Spark Streaming: Real-time processing
- Redis: Fast cache for live metrics
- S3/Data Lake: Historical storage
- Dashboard: Grafana/custom
```

**Q2: Design a data lake architecture.**

```
┌─────────────────────────────────────────────────────────────┐
│                        DATA LAKE                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   BRONZE    │───▶│   SILVER    │───▶│    GOLD     │     │
│  │   (Raw)     │    │  (Cleaned)  │    │ (Business)  │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                              │
│  - Raw ingestion    - Data quality   - Aggregations        │
│  - No schema        - Schema applied - Star schemas        │
│  - All formats      - Standardized   - Ready for BI        │
│  - Append-only      - Deduplicated   - Feature store       │
│                                                              │
└─────────────────────────────────────────────────────────────┘

GOVERNANCE:
- Data catalog (AWS Glue, Azure Purview)
- Access control (IAM, RBAC)
- Lineage tracking
- Quality monitoring
```

---

## Quick Reference Cheat Sheet

### SQL Query Template
```sql
WITH cte AS (
    SELECT ...
    FROM ...
    WHERE ...
)
SELECT columns
FROM cte
JOIN other_table ON ...
WHERE conditions
GROUP BY columns
HAVING aggregate_conditions
ORDER BY columns
LIMIT n;
```

### PySpark Template
```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, when

spark = SparkSession.builder.getOrCreate()

result = (
    spark.read.parquet("input/")
    .filter(col("date") >= "2024-01-01")
    .groupBy("category")
    .agg(sum("amount").alias("total"))
    .orderBy(col("total").desc())
)

result.write.mode("overwrite").parquet("output/")
```

### ETL Best Practices Checklist
- [ ] Idempotent operations (safe to rerun)
- [ ] Incremental processing where possible
- [ ] Error handling and logging
- [ ] Data quality checks
- [ ] Proper partitioning
- [ ] Appropriate file formats (Parquet/ORC)
- [ ] Monitoring and alerting
- [ ] Documentation

---

## Final Interview Tips

1. **Clarify requirements** before jumping into solutions
2. **Think out loud** - explain your reasoning
3. **Start simple**, then optimize
4. **Consider trade-offs** (performance vs. cost vs. complexity)
5. **Mention monitoring** and error handling
6. **Ask about scale** - answers differ for 1GB vs 1TB vs 1PB
7. **Know your tools** - but be honest about what you don't know
8. **Practice coding** - SQL and Python on whiteboard/screen share

---

*Good luck with your interview! 🚀*
