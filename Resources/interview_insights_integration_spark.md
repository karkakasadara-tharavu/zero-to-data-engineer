# Data Integration & Spark - Interview Insights & Tricks

## 🎯 Overview
This guide covers Python-SQL integration and Spark fundamentals - critical skills for data engineering roles involving pipeline development.

---

## Module 13: Python-SQL Integration

### 💡 What Interviewers Really Test

Python-SQL questions assess:
- Understanding of database connectivity patterns
- SQL injection prevention
- Connection pool management
- Transaction handling
- Error recovery strategies

### 🔥 Top Interview Tricks

#### Trick 1: Connection Management Patterns
```python
# BASIC CONNECTION (problematic!)
import pyodbc

conn = pyodbc.connect("...")
cursor = conn.cursor()
cursor.execute("SELECT * FROM users")
# What if we forget to close?

# CONTEXT MANAGER (correct!)
def get_connection():
    return pyodbc.connect("...")

with get_connection() as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    results = cursor.fetchall()
# Connection automatically closed

# CONNECTION POOLING (production pattern)
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    "mssql+pyodbc://user:pass@server/db",
    poolclass=QueuePool,
    pool_size=5,         # Maintain 5 connections
    max_overflow=10,     # Allow 10 extra under load
    pool_timeout=30,     # Wait 30s for connection
    pool_recycle=3600    # Recycle connections after 1 hour
)

# INTERVIEW INSIGHT: "In production, I use connection pooling 
# to avoid connection overhead and manage database load. 
# I also set connection recycling to handle server-side timeouts."
```

#### Trick 2: SQL Injection Prevention
```python
# VULNERABLE - NEVER DO THIS!
user_input = "'; DROP TABLE users; --"
cursor.execute(f"SELECT * FROM users WHERE name = '{user_input}'")

# SAFE - Parameterized queries
cursor.execute(
    "SELECT * FROM users WHERE name = ?",
    (user_input,)
)

# SAFE with named parameters (SQLAlchemy)
from sqlalchemy import text

with engine.connect() as conn:
    result = conn.execute(
        text("SELECT * FROM users WHERE name = :name AND age > :age"),
        {"name": user_input, "age": 18}
    )

# BUILDING DYNAMIC QUERIES SAFELY
def build_query(filters: dict):
    base_query = "SELECT * FROM products WHERE 1=1"
    params = {}
    
    if "category" in filters:
        base_query += " AND category = :category"
        params["category"] = filters["category"]
    
    if "min_price" in filters:
        base_query += " AND price >= :min_price"
        params["min_price"] = filters["min_price"]
    
    return text(base_query), params

# INTERVIEW INSIGHT: "I always use parameterized queries. 
# For dynamic filters, I build the query string separately 
# from parameters, never concatenating user input."
```

#### Trick 3: Bulk Operations
```python
# SLOW - One insert at a time
for row in data:
    cursor.execute("INSERT INTO table VALUES (?, ?, ?)", row)

# FASTER - executemany
cursor.executemany(
    "INSERT INTO table VALUES (?, ?, ?)",
    data
)

# FASTEST - Bulk insert with pandas
import pandas as pd

df.to_sql(
    'table_name',
    engine,
    if_exists='append',    # or 'replace'
    index=False,
    chunksize=10000,       # Batch size
    method='multi'         # Multiple VALUES per INSERT
)

# EVEN FASTER - Native bulk insert
# For SQL Server: BULK INSERT or bcp
# For PostgreSQL: COPY FROM

# SQLALCHEMY with fast_executemany (SQL Server)
from sqlalchemy import create_engine, event

engine = create_engine("mssql+pyodbc://...")

@event.listens_for(engine, "before_cursor_execute")
def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    if executemany:
        cursor.fast_executemany = True

# INTERVIEW INSIGHT: "For large data volumes, I use bulk operations 
# like executemany with fast_executemany for SQL Server, or COPY 
# commands for PostgreSQL. Single-row inserts don't scale."
```

#### Trick 4: Transaction Management
```python
# EXPLICIT TRANSACTIONS
try:
    conn.autocommit = False
    cursor = conn.cursor()
    
    # Multiple operations as atomic unit
    cursor.execute("UPDATE accounts SET balance = balance - 100 WHERE id = 1")
    cursor.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 2")
    
    # Validation before commit
    cursor.execute("SELECT SUM(balance) FROM accounts")
    if cursor.fetchone()[0] != expected_total:
        raise ValueError("Balance mismatch - rolling back")
    
    conn.commit()
    
except Exception as e:
    conn.rollback()
    raise

# SQLALCHEMY SESSION PATTERN
from sqlalchemy.orm import sessionmaker

Session = sessionmaker(bind=engine)

def transfer_funds(from_id, to_id, amount):
    session = Session()
    try:
        from_account = session.query(Account).get(from_id)
        to_account = session.query(Account).get(to_id)
        
        from_account.balance -= amount
        to_account.balance += amount
        
        session.commit()
    except:
        session.rollback()
        raise
    finally:
        session.close()

# CONTEXT MANAGER PATTERN (cleanest)
from contextlib import contextmanager

@contextmanager
def transaction():
    session = Session()
    try:
        yield session
        session.commit()
    except:
        session.rollback()
        raise
    finally:
        session.close()

with transaction() as session:
    # All operations in transaction
    pass
```

#### Trick 5: Error Handling and Retry Logic
```python
import time
from functools import wraps

def retry_on_db_error(max_retries=3, delay=1, backoff=2):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            retries = 0
            current_delay = delay
            
            while retries < max_retries:
                try:
                    return func(*args, **kwargs)
                except (
                    pyodbc.OperationalError,
                    pyodbc.DatabaseError
                ) as e:
                    retries += 1
                    if retries == max_retries:
                        raise
                    
                    error_code = getattr(e, 'args', [None])[0]
                    
                    # Retry on transient errors only
                    transient_errors = ['08S01', '08001', '40001']  # Connection, deadlock
                    if error_code not in transient_errors:
                        raise
                    
                    print(f"Attempt {retries} failed: {e}. Retrying in {current_delay}s")
                    time.sleep(current_delay)
                    current_delay *= backoff
        
        return wrapper
    return decorator

@retry_on_db_error(max_retries=5, delay=1, backoff=2)
def execute_query(query, params):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(query, params)
        return cursor.fetchall()

# INTERVIEW INSIGHT: "I implement retry logic with exponential 
# backoff for transient errors like connection drops or deadlocks. 
# Non-transient errors should fail immediately."
```

### 🎤 Python-SQL Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Prevent SQL injection?" | "Always parameterized queries, never string concatenation with user input" |
| "Handle connection issues?" | "Connection pooling with appropriate sizing, recycling, and retry logic for transient failures" |
| "Bulk loading?" | "Use native bulk operations like COPY, bcp, or at minimum executemany with batching" |

---

## Module 14: Spark Fundamentals

### 💡 Spark Interview Essentials

Spark questions test:
- Understanding of distributed computing
- RDD vs DataFrame knowledge
- Lazy evaluation concepts
- Partitioning and shuffling
- Memory management

### 🔥 Top Interview Tricks

#### Trick 1: Spark Architecture (Must Know!)
```
SPARK CLUSTER ARCHITECTURE:

┌─────────────────────────────────────────────────┐
│                    DRIVER                       │
│  ┌─────────────┐   ┌─────────────────────────┐  │
│  │ SparkContext│   │ DAG Scheduler           │  │
│  │             │   │ - Breaks job into stages│  │
│  └─────────────┘   │ - Optimizes execution   │  │
│                    └─────────────────────────┘  │
└─────────────────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ EXECUTOR │   │ EXECUTOR │   │ EXECUTOR │
    │ ┌──────┐ │   │ ┌──────┐ │   │ ┌──────┐ │
    │ │ Task │ │   │ │ Task │ │   │ │ Task │ │
    │ └──────┘ │   │ └──────┘ │   │ └──────┘ │
    │ ┌──────┐ │   │ ┌──────┐ │   │ ┌──────┐ │
    │ │ Task │ │   │ │ Task │ │   │ │ Task │ │
    │ └──────┘ │   │ └──────┘ │   │ └──────┘ │
    └──────────┘   └──────────┘   └──────────┘

KEY CONCEPTS:
- Driver: Coordinates the job, runs on one node
- Executors: Run tasks in parallel on worker nodes
- Tasks: Smallest unit of work, one per partition
- Stages: Groups of tasks separated by shuffles
```

**Interview Answer**: "The driver creates the execution plan and distributes tasks to executors. Executors run in parallel across the cluster, each processing a subset of partitions."

#### Trick 2: Lazy Evaluation and Actions vs Transformations
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Interview").getOrCreate()

# TRANSFORMATIONS (lazy - build execution plan)
df = spark.read.csv("data.csv")        # Transformation
filtered = df.filter(df.age > 25)      # Transformation
selected = filtered.select("name")     # Transformation
# Nothing executed yet!

# ACTIONS (trigger execution)
selected.show()                        # Action - executes!
selected.collect()                     # Action - brings to driver
selected.count()                       # Action
selected.write.parquet("output")       # Action

# WHY LAZY EVALUATION?
# 1. Optimization: Spark can optimize the entire pipeline
# 2. Efficiency: Skips unnecessary operations
# 3. Memory: Processes data in streaming fashion

# INTERVIEW QUESTION: "What happens when you call .show()?"
# ANSWER: "Spark compiles all preceding transformations into 
# an optimized execution plan, generates stages separated by 
# shuffles, and executes tasks across the cluster."

# COMMON TRANSFORMATIONS
df.select()       # Column selection
df.filter()       # Row filtering
df.groupBy()      # Grouping
df.join()         # Joining
df.orderBy()      # Sorting

# COMMON ACTIONS
df.show()         # Display
df.collect()      # Return to driver (careful with large data!)
df.count()        # Count rows
df.first()        # First row
df.take(n)        # First n rows
df.write          # Save data
```

#### Trick 3: Partitioning (Critical for Performance!)
```python
# CHECK PARTITIONS
df.rdd.getNumPartitions()

# REPARTITION - Full shuffle, use for increasing partitions
df.repartition(100)                    # Specific number
df.repartition("year", "month")        # By column (for joins)

# COALESCE - No shuffle, only for reducing partitions
df.coalesce(10)                        # Combine partitions

# PARTITION SIZING RULES:
# - Ideal partition size: 100MB - 200MB
# - Number of partitions: 2-4x number of cores
# - Too few: Underutilized cluster, memory pressure
# - Too many: Scheduling overhead, small file problem

# WRITE WITH PARTITIONING
df.write.partitionBy("year", "month").parquet("output")
# Creates folder structure: output/year=2024/month=01/

# INTERVIEW QUESTION: "When do you repartition?"
# ANSWER: "Before expensive operations like joins (repartition 
# by join key), after filtering that reduces data significantly, 
# or before write to control output file count."

# BUCKETING (for repeated joins on same key)
df.write.bucketBy(32, "customer_id").sortBy("order_date").saveAsTable("orders")
# Pre-partitions and sorts data for efficient joins
```

#### Trick 4: Shuffles and Avoiding Them
```python
# OPERATIONS THAT CAUSE SHUFFLES:
# - groupBy + aggregation
# - join (except broadcast join)
# - distinct
# - repartition
# - orderBy (global sort)

# SHUFFLE = DATA MOVEMENT ACROSS NETWORK = SLOW

# MINIMIZE SHUFFLES:

# 1. BROADCAST JOIN (avoid shuffle for small tables)
from pyspark.sql.functions import broadcast

# Small table (< 10MB default, configurable)
small_df = spark.read.csv("small_lookup.csv")
large_df = spark.read.parquet("huge_transactions/")

# Broadcast the small table
result = large_df.join(broadcast(small_df), "key")
# Only large_df's data moves, small_df sent to all nodes

# 2. FILTER EARLY
# BAD - shuffle everything, then filter
df1.join(df2, "key").filter(df1.date > "2024-01-01")

# GOOD - filter first, shuffle less data
df1.filter(df1.date > "2024-01-01").join(df2, "key")

# 3. SELECT NEEDED COLUMNS EARLY
# BAD - carry all columns through shuffle
df1.join(df2, "key").select("col1", "col2")

# GOOD - select early
df1.select("key", "col1").join(df2.select("key", "col2"), "key")

# INTERVIEW INSIGHT: "I minimize shuffles by filtering early, 
# selecting only needed columns, using broadcast joins for 
# small tables, and pre-partitioning by join keys."
```

#### Trick 5: Caching and Persistence
```python
# CACHE - Store in memory
df.cache()  # Equivalent to persist(StorageLevel.MEMORY_ONLY)

# PERSIST - More control
from pyspark import StorageLevel

df.persist(StorageLevel.MEMORY_AND_DISK)     # Spill to disk if needed
df.persist(StorageLevel.MEMORY_ONLY_SER)     # Serialized (less memory)
df.persist(StorageLevel.DISK_ONLY)           # Only disk

# WHEN TO CACHE:
# - DataFrame used multiple times
# - After expensive computation (complex joins)
# - Iterative algorithms (ML training)

# WHEN NOT TO CACHE:
# - DataFrame used only once
# - DataFrame too large for memory
# - After simple transformations

# UNPERSIST WHEN DONE
df.unpersist()

# CHECKPOINT - Break lineage, save to reliable storage
spark.sparkContext.setCheckpointDir("hdfs://...")
df.checkpoint()
# Use for: Long lineages, fault tolerance, iterative algorithms

# INTERVIEW QUESTION: "Difference between cache and checkpoint?"
# ANSWER: "Cache stores in memory with full lineage for recomputation. 
# Checkpoint saves to disk and truncates lineage - useful for 
# very long pipelines or iterative algorithms."
```

#### Trick 6: Catalyst Optimizer
```python
# Spark's Catalyst optimizer automatically:
# - Predicate pushdown (filter early)
# - Column pruning (select only needed columns)
# - Join reordering (optimize join sequence)
# - Constant folding (precompute constants)

# EXPLAIN PLAN - See what Spark will do
df.explain()          # Physical plan
df.explain(True)      # All plans (parsed, analyzed, optimized, physical)
df.explain("cost")    # Include cost estimates

# EXAMPLE OUTPUT:
# == Physical Plan ==
# *(2) Filter (amount > 100)
# +- *(2) Project [order_id, customer_id, amount]
#    +- *(1) FileScan parquet [...]
#       - PushedFilters: [IsNotNull(amount), GreaterThan(amount, 100)]
#       - ReadSchema: struct<order_id, customer_id, amount>

# Notice: Filter is "pushed down" to FileScan

# INTERVIEW INSIGHT: "I use explain() to verify optimizations 
# like predicate pushdown and to identify stages with shuffles. 
# Wide arrows in the UI indicate data movement."
```

### 🎤 Spark Power Phrases

| Question | Expert Response |
|----------|-----------------|
| "Why is Spark fast?" | "In-memory processing, lazy evaluation enables optimization, and the Catalyst optimizer pushes down predicates and prunes columns" |
| "Shuffle performance?" | "Shuffles are network-bound. I minimize them with broadcast joins, early filtering, and pre-partitioning by join keys" |
| "Memory issues?" | "I'd check for data skew, reduce partition count, use serialized storage, or increase executor memory" |

---

## 📊 Integration & Spark Quick Reference

### Python-SQL Best Practices
```python
# Connection management
with get_connection() as conn:  # Context manager
    cursor.execute(query, params)  # Parameterized

# Bulk operations
df.to_sql(..., chunksize=10000, method='multi')

# Error handling
@retry_on_db_error(max_retries=3)
def execute_query():
    pass
```

### Spark Key Concepts
```python
# Transformations (lazy)
df.select(), df.filter(), df.groupBy(), df.join()

# Actions (execute)
df.show(), df.count(), df.collect(), df.write

# Performance
df.repartition(n)      # Increase partitions (shuffle)
df.coalesce(n)         # Decrease partitions (no shuffle)
df.cache()             # Store in memory
broadcast(small_df)    # Avoid shuffle for small tables
```

### Shuffle-Causing Operations
- `groupBy` + aggregation
- `join` (non-broadcast)
- `distinct`
- `repartition`
- `orderBy`

### Storage Levels
| Level | Description |
|-------|-------------|
| MEMORY_ONLY | Default cache |
| MEMORY_AND_DISK | Spill to disk |
| MEMORY_ONLY_SER | Compressed |
| DISK_ONLY | Disk storage |

---

*"Data engineering is about moving data efficiently. Understanding when and why data moves is the key to optimization."*
