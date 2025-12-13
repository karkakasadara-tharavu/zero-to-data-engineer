# Apache Spark Architecture - Complete Guide

## 📚 What You'll Learn
- Spark ecosystem and components
- Cluster architecture and execution model
- RDDs, DataFrames, and Datasets
- Lazy evaluation and DAGs
- Spark memory management
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is Apache Spark?

### Definition
**Apache Spark** is a unified analytics engine for large-scale data processing. It provides:
- In-memory computing (100x faster than Hadoop MapReduce)
- Support for batch and streaming data
- Machine learning and graph processing
- SQL queries on distributed data

### The Spark Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                        SPARK APPLICATIONS                        │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────┤
│  Spark SQL  │ Spark       │   MLlib     │  GraphX     │Structured│
│  DataFrames │ Streaming   │   ML        │  Graph      │Streaming │
├─────────────┴─────────────┴─────────────┴─────────────┴─────────┤
│                        SPARK CORE (RDD API)                      │
├─────────────────────────────────────────────────────────────────┤
│                    CLUSTER MANAGERS                              │
│         Standalone  |  YARN  |  Mesos  |  Kubernetes             │
├─────────────────────────────────────────────────────────────────┤
│                    DATA SOURCES                                  │
│    HDFS  |  S3  |  Cassandra  |  JDBC  |  Kafka  |  Files        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Cluster Architecture

### Components

```
┌────────────────────────────────────────────────────────────────────────┐
│                           DRIVER PROGRAM                                │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      SparkContext/SparkSession                    │  │
│  │  - Creates RDDs/DataFrames                                        │  │
│  │  - Builds DAG of operations                                       │  │
│  │  - Schedules tasks                                                │  │
│  │  - Coordinates with cluster manager                               │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         CLUSTER MANAGER                                 │
│              (YARN / Mesos / Kubernetes / Standalone)                   │
│                   - Allocates resources                                 │
│                   - Manages worker nodes                                │
└────────────────────────────────────────────────────────────────────────┘
                    │                               │
                    ▼                               ▼
┌────────────────────────────┐   ┌────────────────────────────┐
│        WORKER NODE 1        │   │        WORKER NODE 2        │
│  ┌───────────────────────┐  │   │  ┌───────────────────────┐  │
│  │      EXECUTOR 1       │  │   │  │      EXECUTOR 2       │  │
│  │  ┌─────┐ ┌─────┐     │  │   │  │  ┌─────┐ ┌─────┐     │  │
│  │  │Task1│ │Task2│     │  │   │  │  │Task3│ │Task4│     │  │
│  │  └─────┘ └─────┘     │  │   │  │  └─────┘ └─────┘     │  │
│  │  ┌─────────────────┐ │  │   │  │  ┌─────────────────┐ │  │
│  │  │   CACHE         │ │  │   │  │  │   CACHE         │ │  │
│  │  └─────────────────┘ │  │   │  │  └─────────────────┘ │  │
│  └───────────────────────┘  │   │  └───────────────────────┘  │
└────────────────────────────┘   └────────────────────────────┘
```

### Component Roles

| Component | Role |
|-----------|------|
| **Driver** | Main program, creates SparkSession, orchestrates execution |
| **Cluster Manager** | Allocates resources across cluster |
| **Worker Node** | Physical/virtual machine running executors |
| **Executor** | JVM process running tasks and storing data |
| **Task** | Smallest unit of work on a partition |

---

## 📊 Data Abstractions

### Evolution of Spark APIs

```
Spark 1.0          Spark 1.3         Spark 1.6         Spark 2.0+
   │                   │                 │                  │
   ▼                   ▼                 ▼                  ▼
 ┌─────┐          ┌─────────┐       ┌─────────┐        ┌─────────┐
 │ RDD │   →      │DataFrame│   →   │ Dataset │   →    │Unified  │
 └─────┘          └─────────┘       └─────────┘        │DataFrame│
 Low-level         Optimized         Type-safe         └─────────┘
 Functional        SQL-like          Scala/Java         Best of
                                                        both
```

### RDD (Resilient Distributed Dataset)

```python
# Low-level API - full control but less optimization
rdd = sc.parallelize([1, 2, 3, 4, 5])
result = rdd.map(lambda x: x * 2).filter(lambda x: x > 4).collect()

# Key characteristics:
# - Immutable
# - Partitioned across cluster
# - Fault-tolerant (can rebuild from lineage)
# - Lazy evaluation
```

### DataFrame

```python
# High-level API - SQL-like, optimized by Catalyst
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Example").getOrCreate()

df = spark.read.csv("data.csv", header=True, inferSchema=True)
result = df.filter(df.age > 30).select("name", "age").orderBy("age")

# Key characteristics:
# - Structured (schema)
# - Optimized by Catalyst optimizer
# - Can use SQL syntax
# - Less control but better performance
```

### When to Use What?

| Use Case | Best Choice |
|----------|-------------|
| Structured data with known schema | DataFrame/Dataset |
| SQL-like operations | DataFrame |
| Need full control over data | RDD |
| Machine learning pipelines | DataFrame |
| Graph processing | GraphX (RDD-based) |
| Streaming | Structured Streaming (DataFrame) |

---

## ⚡ Lazy Evaluation

### What is Lazy Evaluation?

Spark doesn't execute operations immediately. It builds a plan (DAG) and executes only when an **action** is called.

```python
# These are TRANSFORMATIONS (lazy - nothing happens yet)
df1 = spark.read.csv("data.csv")          # Just a plan
df2 = df1.filter(df1.age > 30)            # Still just a plan
df3 = df2.select("name", "age")           # Still just a plan
df4 = df3.groupBy("age").count()          # Still just a plan

# This is an ACTION (triggers execution!)
result = df4.show()  # NOW Spark executes everything!
```

### Transformations vs Actions

| Transformations (Lazy) | Actions (Trigger Execution) |
|------------------------|----------------------------|
| `filter()`, `select()` | `show()`, `collect()` |
| `map()`, `flatMap()` | `count()`, `take()` |
| `groupBy()`, `orderBy()` | `write()`, `save()` |
| `join()`, `union()` | `first()`, `head()` |
| `distinct()`, `sample()` | `foreach()`, `reduce()` |

### Why Lazy Evaluation?

1. **Optimization**: Spark can optimize the entire plan before executing
2. **Efficiency**: Combines operations to minimize data movement
3. **Fault Tolerance**: Can rebuild from lineage if partition fails

---

## 📈 DAG (Directed Acyclic Graph)

### What is DAG?

Spark creates a DAG of operations before execution:

```
                     ┌─────────┐
                     │ read()  │
                     └────┬────┘
                          │
                     ┌────▼────┐
                     │filter() │
                     └────┬────┘
                          │
                     ┌────▼────┐
                     │select() │
                     └────┬────┘
                          │
          ┌───────────────┴───────────────┐
          │                               │
     ┌────▼────┐                     ┌────▼────┐
     │groupBy()│                     │ join()  │
     └────┬────┘                     └────┬────┘
          │                               │
     ┌────▼────┐                     ┌────▼────┐
     │ count() │                     │orderBy()│
     └────┬────┘                     └────┬────┘
          │                               │
          └───────────────┬───────────────┘
                          │
                     ┌────▼────┐
                     │ show()  │  ← ACTION triggers execution
                     └─────────┘
```

### Jobs, Stages, and Tasks

```
JOB (triggered by action)
│
├── STAGE 1 (narrow transformations - no shuffle)
│   ├── Task 1 (partition 1)
│   ├── Task 2 (partition 2)
│   └── Task 3 (partition 3)
│
├── [SHUFFLE] ← Stage boundary (data exchange between partitions)
│
└── STAGE 2 (after shuffle)
    ├── Task 1 (partition 1)
    ├── Task 2 (partition 2)
    └── Task 3 (partition 3)
```

### Narrow vs Wide Transformations

| Narrow (No Shuffle) | Wide (Shuffle Required) |
|--------------------|------------------------|
| `map()`, `filter()` | `groupBy()`, `reduceByKey()` |
| `flatMap()`, `union()` | `join()`, `repartition()` |
| Fast, parallel | Slow, network I/O |

---

## 💾 Memory Management

### Spark Memory Areas

```
┌────────────────────────────────────────────────────────────────┐
│                     EXECUTOR MEMORY                             │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              SPARK MEMORY (spark.memory.fraction)         │  │
│  │                        (60% default)                      │  │
│  │  ┌─────────────────────┐  ┌─────────────────────────────┐│  │
│  │  │   EXECUTION MEMORY  │  │      STORAGE MEMORY         ││  │
│  │  │   (shuffles, joins, │  │   (cached RDDs/DataFrames)  ││  │
│  │  │    sorts, aggs)     │  │                             ││  │
│  │  │        50%          │  │          50%                ││  │
│  │  └─────────────────────┘  └─────────────────────────────┘│  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  USER MEMORY (40%)                        │  │
│  │            (user data structures, UDFs)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### Key Memory Configurations

| Configuration | Description | Default |
|--------------|-------------|---------|
| `spark.executor.memory` | Total executor memory | 1g |
| `spark.memory.fraction` | Fraction for Spark operations | 0.6 |
| `spark.memory.storageFraction` | Fraction of Spark memory for storage | 0.5 |
| `spark.driver.memory` | Driver memory | 1g |

---

## 🔧 SparkSession Configuration

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MyApp") \
    .master("local[*]") \
    .config("spark.executor.memory", "4g") \
    .config("spark.driver.memory", "2g") \
    .config("spark.sql.shuffle.partitions", "200") \
    .config("spark.default.parallelism", "100") \
    .getOrCreate()

# Common configurations
# spark.executor.instances = number of executors
# spark.executor.cores = cores per executor
# spark.sql.shuffle.partitions = partitions after shuffle
# spark.default.parallelism = default RDD partitions
```

---

## 🎓 Interview Questions

### Q1: What is Apache Spark and how is it different from Hadoop MapReduce?
**A:** Spark is a distributed computing framework that:
- Processes data **in-memory** (100x faster than MapReduce for iterative algorithms)
- Supports **lazy evaluation** with DAG optimization
- Has **unified API** for batch, streaming, ML, and graph processing
- Provides **interactive queries** via Spark SQL

MapReduce writes intermediate results to disk, making it slower for iterative operations.

### Q2: Explain the Spark architecture.
**A:**
1. **Driver**: Main program that creates SparkSession, builds DAG, schedules tasks
2. **Cluster Manager**: Allocates resources (YARN, Mesos, K8s, Standalone)
3. **Workers**: Physical machines running executors
4. **Executors**: JVM processes that run tasks and cache data
5. **Tasks**: Smallest unit of work operating on partitions

### Q3: What is lazy evaluation in Spark?
**A:** Spark doesn't execute transformations immediately. It builds a DAG of operations and only executes when an action is called. Benefits:
- Allows optimization across entire plan
- Minimizes data movement
- Enables fault tolerance through lineage

### Q4: What is the difference between transformation and action?
**A:**
- **Transformation**: Creates new RDD/DataFrame from existing one (lazy, returns new dataset). Examples: map, filter, groupBy
- **Action**: Triggers computation and returns result to driver (eager). Examples: count, collect, show, write

### Q5: What is DAG in Spark?
**A:** Directed Acyclic Graph represents the sequence of computations on data. Spark builds a DAG of transformations and optimizes it before execution. DAG is divided into stages based on shuffle boundaries.

### Q6: What is the difference between narrow and wide transformations?
**A:**
- **Narrow**: Data stays on same partition, no shuffle (filter, map). Fast, parallelizable.
- **Wide**: Data moves between partitions, requires shuffle (groupBy, join). Creates stage boundary.

### Q7: What is RDD?
**A:** Resilient Distributed Dataset - the fundamental data structure in Spark:
- **Resilient**: Fault-tolerant, can rebuild from lineage
- **Distributed**: Partitioned across cluster nodes
- **Dataset**: Collection of records

### Q8: DataFrame vs RDD - when to use which?
**A:**
- **DataFrame**: Structured data, SQL-like operations, Catalyst optimization. Use for most cases.
- **RDD**: Unstructured data, fine-grained control, custom serialization. Use when DataFrame doesn't fit.

### Q9: What is a shuffle in Spark?
**A:** Shuffle is redistribution of data across partitions, required for wide transformations like groupBy, join, reduceByKey. It involves:
- Writing to disk
- Network I/O between nodes
- Creates stage boundary

Shuffles are expensive - minimize them for better performance.

### Q10: How does Spark achieve fault tolerance?
**A:** Through lineage tracking:
1. Spark records all transformations as a DAG
2. If a partition is lost, Spark replays transformations from source
3. Checkpointing can save state to avoid long lineage recomputation

---

## 🔗 Related Topics
- [PySpark DataFrames →](./02_pyspark_dataframes.md)
- [Transformations and Actions →](./03_transformations_actions.md)
- [Performance Optimization →](./04_performance.md)

---

*Next: Learn about PySpark DataFrames*
