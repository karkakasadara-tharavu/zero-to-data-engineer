# RDD (Resilient Distributed Dataset) Basics - Complete Guide

## 📚 What You'll Learn
- Understanding RDDs
- Creating RDDs
- Transformations and Actions
- RDD persistence
- Interview preparation

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 What is an RDD?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    RDD - RESILIENT DISTRIBUTED DATASET                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   R - RESILIENT                                                          │
│       • Fault-tolerant through lineage                                   │
│       • Can rebuild lost partitions                                      │
│                                                                          │
│   D - DISTRIBUTED                                                        │
│       • Data spread across cluster nodes                                 │
│       • Parallel processing                                              │
│                                                                          │
│   D - DATASET                                                            │
│       • Collection of partitioned data                                   │
│       • Immutable (read-only)                                           │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                          RDD                                     │   │
│   │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│   │   │Partition │  │Partition │  │Partition │  │Partition │       │   │
│   │   │    0     │  │    1     │  │    2     │  │    3     │       │   │
│   │   │  [data]  │  │  [data]  │  │  [data]  │  │  [data]  │       │   │
│   │   └──────────┘  └──────────┘  └──────────┘  └──────────┘       │   │
│   │        │              │              │              │           │   │
│   │        ▼              ▼              ▼              ▼           │   │
│   │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│   │   │ Executor │  │ Executor │  │ Executor │  │ Executor │       │   │
│   │   │  Node 1  │  │  Node 2  │  │  Node 3  │  │  Node 4  │       │   │
│   │   └──────────┘  └──────────┘  └──────────┘  └──────────┘       │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔑 RDD Properties

### 1. Immutability
- Once created, cannot be changed
- Transformations create new RDDs
- Ensures consistency in distributed environment

### 2. Lazy Evaluation
- Transformations are not executed immediately
- Execution happens only when action is called
- Allows optimization of execution plan

### 3. Partitioning
- Data divided into partitions
- Each partition processed in parallel
- Partitions can be on different nodes

### 4. Lineage (DAG)
- Tracks all transformations
- Enables fault recovery
- No need for data replication

---

## 🔧 Creating RDDs

### From Collections

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("RDDBasics").getOrCreate()
sc = spark.sparkContext

# From Python list
data = [1, 2, 3, 4, 5]
rdd = sc.parallelize(data)

# With specific number of partitions
rdd = sc.parallelize(data, numSlices=4)

# Check partitions
print(f"Number of partitions: {rdd.getNumPartitions()}")
```

### From External Data

```python
# From text file
rdd = sc.textFile("data.txt")

# From multiple files
rdd = sc.textFile("data/*.txt")

# From HDFS
rdd = sc.textFile("hdfs://namenode:9000/path/to/file")

# From S3
rdd = sc.textFile("s3a://bucket/path/to/file")

# Whole text files (filename, content pairs)
rdd = sc.wholeTextFiles("data/")
```

### From DataFrames

```python
# DataFrame to RDD
df = spark.createDataFrame([(1, "a"), (2, "b")], ["id", "value"])
rdd = df.rdd  # RDD of Row objects

# RDD to DataFrame
rdd = sc.parallelize([(1, "a"), (2, "b")])
df = rdd.toDF(["id", "value"])
```

---

## 🔄 RDD Transformations

### Narrow Transformations (No Shuffle)

```python
# map - Apply function to each element
rdd = sc.parallelize([1, 2, 3, 4, 5])
squared = rdd.map(lambda x: x ** 2)  # [1, 4, 9, 16, 25]

# flatMap - Map then flatten
rdd = sc.parallelize(["hello world", "hi there"])
words = rdd.flatMap(lambda x: x.split(" "))  # ["hello", "world", "hi", "there"]

# filter - Keep elements matching condition
rdd = sc.parallelize([1, 2, 3, 4, 5])
evens = rdd.filter(lambda x: x % 2 == 0)  # [2, 4]

# mapPartitions - Apply function to each partition
def process_partition(iterator):
    yield sum(iterator)

rdd = sc.parallelize([1, 2, 3, 4, 5], 2)
sums = rdd.mapPartitions(process_partition)  # [3, 12] (partitions summed)

# mapPartitionsWithIndex - Include partition index
def with_index(index, iterator):
    for item in iterator:
        yield (index, item)

result = rdd.mapPartitionsWithIndex(with_index)
```

### Wide Transformations (Require Shuffle)

```python
# groupByKey - Group values by key
rdd = sc.parallelize([("a", 1), ("b", 2), ("a", 3)])
grouped = rdd.groupByKey()  # [("a", [1, 3]), ("b", [2])]

# reduceByKey - Reduce values by key (preferred over groupByKey)
rdd = sc.parallelize([("a", 1), ("b", 2), ("a", 3)])
summed = rdd.reduceByKey(lambda x, y: x + y)  # [("a", 4), ("b", 2)]

# sortByKey - Sort by key
rdd = sc.parallelize([("b", 2), ("a", 1), ("c", 3)])
sorted_rdd = rdd.sortByKey()  # [("a", 1), ("b", 2), ("c", 3)]

# join - Join two RDDs by key
rdd1 = sc.parallelize([("a", 1), ("b", 2)])
rdd2 = sc.parallelize([("a", "x"), ("b", "y")])
joined = rdd1.join(rdd2)  # [("a", (1, "x")), ("b", (2, "y"))]

# distinct - Remove duplicates
rdd = sc.parallelize([1, 2, 2, 3, 3, 3])
unique = rdd.distinct()  # [1, 2, 3]

# repartition - Change number of partitions
rdd = sc.parallelize([1, 2, 3, 4, 5], 2)
repartitioned = rdd.repartition(4)  # Now 4 partitions

# coalesce - Reduce partitions (no shuffle if decreasing)
rdd = sc.parallelize([1, 2, 3, 4, 5], 4)
coalesced = rdd.coalesce(2)  # Now 2 partitions
```

---

## ⚡ RDD Actions

### Basic Actions

```python
rdd = sc.parallelize([1, 2, 3, 4, 5])

# collect - Return all elements (use carefully!)
all_data = rdd.collect()  # [1, 2, 3, 4, 5]

# count - Count elements
count = rdd.count()  # 5

# first - Return first element
first = rdd.first()  # 1

# take - Return first n elements
first_three = rdd.take(3)  # [1, 2, 3]

# takeSample - Return random sample
sample = rdd.takeSample(withReplacement=False, num=3)

# top - Return top n elements
top_two = rdd.top(2)  # [5, 4]

# takeOrdered - Return n smallest
smallest = rdd.takeOrdered(2)  # [1, 2]
```

### Aggregate Actions

```python
rdd = sc.parallelize([1, 2, 3, 4, 5])

# reduce - Reduce all elements
total = rdd.reduce(lambda x, y: x + y)  # 15

# fold - Like reduce but with initial value
total = rdd.fold(0, lambda x, y: x + y)  # 15

# aggregate - More flexible aggregation
result = rdd.aggregate(
    (0, 0),  # Initial value (sum, count)
    lambda acc, val: (acc[0] + val, acc[1] + 1),  # Within partition
    lambda acc1, acc2: (acc1[0] + acc2[0], acc1[1] + acc2[1])  # Combine partitions
)
# (15, 5) - sum and count
average = result[0] / result[1]  # 3.0
```

### Key-Value Actions

```python
rdd = sc.parallelize([("a", 1), ("b", 2), ("a", 3)])

# countByKey - Count by key
counts = rdd.countByKey()  # {"a": 2, "b": 1}

# countByValue - Count by value
rdd = sc.parallelize([1, 2, 2, 3, 3, 3])
counts = rdd.countByValue()  # {1: 1, 2: 2, 3: 3}

# collectAsMap - Collect as dictionary
rdd = sc.parallelize([("a", 1), ("b", 2)])
as_map = rdd.collectAsMap()  # {"a": 1, "b": 2}

# lookup - Get values for key
rdd = sc.parallelize([("a", 1), ("b", 2), ("a", 3)])
values = rdd.lookup("a")  # [1, 3]
```

### Save Actions

```python
rdd = sc.parallelize([1, 2, 3, 4, 5])

# Save as text file
rdd.saveAsTextFile("output/text")

# Save as pickle file
rdd.saveAsPickleFile("output/pickle")

# Save with compression
rdd.saveAsTextFile("output/compressed", 
                   compressionCodecClass="org.apache.hadoop.io.compress.GzipCodec")
```

---

## 💾 RDD Persistence (Caching)

### Storage Levels

```python
from pyspark import StorageLevel

rdd = sc.parallelize(range(1000000))

# Cache in memory (default)
rdd.cache()  # Same as persist(StorageLevel.MEMORY_ONLY)

# Persist with specific level
rdd.persist(StorageLevel.MEMORY_ONLY)
rdd.persist(StorageLevel.MEMORY_AND_DISK)
rdd.persist(StorageLevel.DISK_ONLY)
rdd.persist(StorageLevel.MEMORY_ONLY_SER)  # Serialized
rdd.persist(StorageLevel.MEMORY_AND_DISK_SER)

# Unpersist
rdd.unpersist()
```

### Storage Level Options

| Level | Space | CPU | In Memory | On Disk |
|-------|-------|-----|-----------|---------|
| MEMORY_ONLY | High | Low | Yes | No |
| MEMORY_AND_DISK | High | Medium | Some | Some |
| MEMORY_ONLY_SER | Low | High | Yes (serialized) | No |
| MEMORY_AND_DISK_SER | Low | High | Some | Some |
| DISK_ONLY | Low | High | No | Yes |

### When to Cache

```python
# Cache when RDD is used multiple times
rdd = sc.textFile("large_file.txt")
processed = rdd.filter(lambda x: "error" in x).map(lambda x: x.split(","))
processed.cache()  # Cache before multiple actions

# Multiple actions on same RDD
error_count = processed.count()
first_errors = processed.take(10)
processed.saveAsTextFile("output")

# Unpersist when done
processed.unpersist()
```

---

## 🔍 RDD Lineage and DAG

### Viewing Lineage

```python
rdd1 = sc.parallelize([1, 2, 3, 4, 5])
rdd2 = rdd1.map(lambda x: x * 2)
rdd3 = rdd2.filter(lambda x: x > 5)

# View lineage (debug string)
print(rdd3.toDebugString())
# (4) PythonRDD[3] at RDD at PythonRDD.scala:53 []
#  |  ParallelCollectionRDD[0] at parallelize at <stdin>:1 []
```

### DAG Visualization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          RDD LINEAGE (DAG)                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   parallelize([1,2,3,4,5])                                               │
│          │                                                               │
│          ▼                                                               │
│   ┌──────────────┐                                                      │
│   │    RDD 1     │  [1, 2, 3, 4, 5]                                     │
│   └──────┬───────┘                                                      │
│          │ map(x => x * 2)                                               │
│          ▼                                                               │
│   ┌──────────────┐                                                      │
│   │    RDD 2     │  [2, 4, 6, 8, 10]                                    │
│   └──────┬───────┘                                                      │
│          │ filter(x => x > 5)                                            │
│          ▼                                                               │
│   ┌──────────────┐                                                      │
│   │    RDD 3     │  [6, 8, 10]                                          │
│   └──────────────┘                                                      │
│                                                                          │
│   If RDD 2 partition is lost, Spark recomputes from RDD 1               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 RDD vs DataFrame

| Feature | RDD | DataFrame |
|---------|-----|-----------|
| **API Level** | Low-level | High-level |
| **Schema** | No schema | Has schema |
| **Optimization** | None | Catalyst optimizer |
| **Language** | Any | SQL-like |
| **Use Case** | Custom processing | Structured data |
| **Performance** | Lower | Higher (optimized) |
| **Type Safety** | High (Scala) | Lower |

### When to Use RDD

- Unstructured data
- Low-level transformations
- Fine-grained control
- Legacy code

### When to Use DataFrame (Preferred)

- Structured/semi-structured data
- SQL queries
- Performance critical
- New projects

---

## 🎓 Interview Questions

### Q1: What is an RDD?
**A:** RDD (Resilient Distributed Dataset) is Spark's fundamental data structure. It's an immutable, distributed collection of objects that can be processed in parallel across a cluster.

### Q2: What does "resilient" mean in RDD?
**A:** Resilient means fault-tolerant. RDDs can recover from node failures by recomputing lost partitions using lineage information (the sequence of transformations).

### Q3: What is the difference between transformation and action?
**A:**
- **Transformation**: Returns new RDD, lazy evaluation (map, filter, reduceByKey)
- **Action**: Returns result or writes to storage, triggers execution (collect, count, save)

### Q4: What is lazy evaluation?
**A:** Transformations are not executed immediately. Spark builds a DAG of transformations and only executes when an action is called. This allows optimization.

### Q5: What is the difference between map and flatMap?
**A:**
- **map**: One input → one output
- **flatMap**: One input → zero or more outputs (flattens result)
```python
rdd.map(lambda x: x.split())      # [["a", "b"], ["c"]]
rdd.flatMap(lambda x: x.split())  # ["a", "b", "c"]
```

### Q6: Why is reduceByKey preferred over groupByKey?
**A:** reduceByKey performs local aggregation before shuffle, reducing data transfer. groupByKey shuffles all data first, causing more network I/O.

### Q7: What is the difference between narrow and wide transformations?
**A:**
- **Narrow**: Each partition contributes to one output partition (no shuffle)
- **Wide**: Partitions contribute to multiple outputs (requires shuffle)

### Q8: What is RDD lineage?
**A:** The sequence of transformations used to create an RDD. Stored as DAG, used for fault recovery by recomputing lost partitions.

### Q9: When should you cache an RDD?
**A:** When the RDD is used multiple times (multiple actions or iterative algorithms). Caching avoids recomputation.

### Q10: What is the difference between cache() and persist()?
**A:**
- **cache()**: Shorthand for `persist(StorageLevel.MEMORY_ONLY)`
- **persist()**: Allows specifying storage level (MEMORY_ONLY, DISK_ONLY, etc.)

---

## 🔗 Related Topics
- [← Spark Setup](./02_spark_setup.md)
- [DataFrames →](../Module_15_PySpark/01_dataframe_basics.md)
- [Spark SQL →](../Module_15_PySpark/03_spark_sql.md)

---

*Module 14 Complete! Continue to PySpark DataFrames*
