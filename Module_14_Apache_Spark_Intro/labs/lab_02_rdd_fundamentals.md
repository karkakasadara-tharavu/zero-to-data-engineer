# Lab 02: RDD Fundamentals

## Overview
Learn the fundamentals of Resilient Distributed Datasets (RDDs), the core data structure of Apache Spark.

**Duration**: 3-4 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Prerequisites
- Lab 01 completed (Spark installed and configured)
- Basic Python knowledge

---

## Learning Objectives
- ✅ Understand what RDDs are and why they matter
- ✅ Create RDDs from various sources
- ✅ Apply transformations to RDDs
- ✅ Perform actions on RDDs
- ✅ Understand lazy evaluation

---

## Part 1: Understanding RDDs

### What is an RDD?
**Resilient Distributed Dataset (RDD)** is:
- **Resilient**: Fault-tolerant, can rebuild data on failure
- **Distributed**: Data spread across multiple nodes
- **Dataset**: Collection of partitioned data

```
┌─────────────────────────────────────────────────────────┐
│                          RDD                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │Partition1│  │Partition2│  │Partition3│  │PartitionN│ │
│  │  Data    │  │  Data    │  │  Data    │  │  Data    │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
│     Node 1       Node 2        Node 3        Node N     │
└─────────────────────────────────────────────────────────┘
```

---

## Part 2: Creating RDDs

### Step 2.1: Setup Script
Create `rdd_basics.py`:

```python
"""
rdd_basics.py
RDD Fundamentals Lab
"""

from pyspark.sql import SparkSession

# Create SparkSession
spark = SparkSession.builder \
    .appName("RDD Basics") \
    .master("local[*]") \
    .getOrCreate()

# Get SparkContext from SparkSession
sc = spark.sparkContext
sc.setLogLevel("WARN")

print("SparkContext created successfully!")
print(f"Application Name: {sc.appName}")
print(f"Master: {sc.master}")
```

### Step 2.2: Create RDD from Python Collection
```python
# Method 1: parallelize() - from Python list
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
numbers_rdd = sc.parallelize(numbers)

print(f"\nRDD created from list")
print(f"Number of partitions: {numbers_rdd.getNumPartitions()}")
print(f"First element: {numbers_rdd.first()}")
print(f"Take 5 elements: {numbers_rdd.take(5)}")

# Create with specific number of partitions
numbers_rdd_4 = sc.parallelize(numbers, 4)
print(f"RDD with 4 partitions: {numbers_rdd_4.getNumPartitions()}")
```

### Step 2.3: Create RDD from Text File
```python
# First, create a sample text file
sample_text = """Hello World
Apache Spark is fast
RDDs are powerful
Data Engineering is fun
Python and Spark work great together"""

with open("sample.txt", "w") as f:
    f.write(sample_text)

# Method 2: textFile() - from file
text_rdd = sc.textFile("sample.txt")
print(f"\nRDD from text file:")
print(f"Lines: {text_rdd.collect()}")
```

---

## Part 3: RDD Transformations

Transformations are **lazy** - they don't execute until an action is called.

### Step 3.1: map() Transformation
```python
# map() - apply function to each element
numbers = sc.parallelize([1, 2, 3, 4, 5])

# Square each number
squared = numbers.map(lambda x: x ** 2)
print(f"\nOriginal: {numbers.collect()}")
print(f"Squared: {squared.collect()}")

# Convert to tuples
with_labels = numbers.map(lambda x: (f"num_{x}", x))
print(f"With labels: {with_labels.collect()}")
```

### Step 3.2: filter() Transformation
```python
# filter() - keep elements matching condition
numbers = sc.parallelize(range(1, 21))

# Keep only even numbers
evens = numbers.filter(lambda x: x % 2 == 0)
print(f"\nAll numbers: {numbers.collect()}")
print(f"Even numbers: {evens.collect()}")

# Keep numbers > 10
greater_than_10 = numbers.filter(lambda x: x > 10)
print(f"Greater than 10: {greater_than_10.collect()}")
```

### Step 3.3: flatMap() Transformation
```python
# flatMap() - map then flatten results
sentences = sc.parallelize([
    "Hello World",
    "Apache Spark",
    "Big Data Processing"
])

# Split each sentence into words
words = sentences.flatMap(lambda s: s.split(" "))
print(f"\nSentences: {sentences.collect()}")
print(f"Words (flatMap): {words.collect()}")

# Compare with regular map
words_map = sentences.map(lambda s: s.split(" "))
print(f"Words (map): {words_map.collect()}")  # Nested lists
```

### Step 3.4: distinct() and union()
```python
# distinct() - remove duplicates
with_duplicates = sc.parallelize([1, 2, 2, 3, 3, 3, 4])
unique = with_duplicates.distinct()
print(f"\nWith duplicates: {with_duplicates.collect()}")
print(f"Distinct: {unique.collect()}")

# union() - combine two RDDs
rdd1 = sc.parallelize([1, 2, 3])
rdd2 = sc.parallelize([3, 4, 5])
combined = rdd1.union(rdd2)
print(f"RDD1: {rdd1.collect()}")
print(f"RDD2: {rdd2.collect()}")
print(f"Union: {combined.collect()}")
print(f"Union Distinct: {combined.distinct().collect()}")
```

---

## Part 4: RDD Actions

Actions **trigger** computation and return results.

### Step 4.1: collect(), count(), first()
```python
numbers = sc.parallelize([10, 20, 30, 40, 50])

# collect() - return all elements as list
print(f"\ncollect(): {numbers.collect()}")

# count() - return number of elements
print(f"count(): {numbers.count()}")

# first() - return first element
print(f"first(): {numbers.first()}")

# take(n) - return first n elements
print(f"take(3): {numbers.take(3)}")

# takeSample(withReplacement, num)
print(f"takeSample: {numbers.takeSample(False, 3)}")
```

### Step 4.2: Aggregation Actions
```python
numbers = sc.parallelize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

# reduce() - aggregate using function
total = numbers.reduce(lambda a, b: a + b)
print(f"\nSum (reduce): {total}")

product = numbers.reduce(lambda a, b: a * b)
print(f"Product (reduce): {product}")

# sum(), max(), min(), mean()
print(f"sum(): {numbers.sum()}")
print(f"max(): {numbers.max()}")
print(f"min(): {numbers.min()}")
print(f"mean(): {numbers.mean()}")
print(f"stdev(): {numbers.stdev():.2f}")

# countByValue() - count occurrences
letters = sc.parallelize(['a', 'b', 'a', 'c', 'b', 'a'])
counts = letters.countByValue()
print(f"countByValue(): {dict(counts)}")
```

---

## Part 5: Key-Value RDDs

### Step 5.1: Creating Pair RDDs
```python
# Create key-value pairs
employees = sc.parallelize([
    ("Engineering", "Alice"),
    ("Engineering", "Bob"),
    ("Sales", "Charlie"),
    ("Sales", "Diana"),
    ("Marketing", "Eve")
])

print(f"\nPair RDD: {employees.collect()}")
print(f"Keys: {employees.keys().collect()}")
print(f"Values: {employees.values().collect()}")
```

### Step 5.2: reduceByKey()
```python
# Count words using reduceByKey
text = sc.parallelize([
    "hello world",
    "hello spark",
    "world of data"
])

word_counts = text.flatMap(lambda line: line.split(" ")) \
                  .map(lambda word: (word, 1)) \
                  .reduceByKey(lambda a, b: a + b)

print(f"\nWord Counts: {word_counts.collect()}")
```

### Step 5.3: groupByKey()
```python
# Group employees by department
employees = sc.parallelize([
    ("Engineering", "Alice"),
    ("Engineering", "Bob"),
    ("Sales", "Charlie"),
    ("Sales", "Diana"),
    ("Marketing", "Eve")
])

grouped = employees.groupByKey()
print("\nGrouped by Key:")
for dept, names in grouped.collect():
    print(f"  {dept}: {list(names)}")
```

### Step 5.4: sortByKey()
```python
# Sort by key
data = sc.parallelize([
    (3, "Three"),
    (1, "One"),
    (2, "Two"),
    (5, "Five"),
    (4, "Four")
])

sorted_asc = data.sortByKey()
sorted_desc = data.sortByKey(ascending=False)

print(f"\nOriginal: {data.collect()}")
print(f"Sorted ASC: {sorted_asc.collect()}")
print(f"Sorted DESC: {sorted_desc.collect()}")
```

---

## Part 6: Understanding Lazy Evaluation

### Step 6.1: Transformations are Lazy
```python
# Create RDD and apply transformations
numbers = sc.parallelize(range(1, 1000001))

# These transformations don't execute yet!
squared = numbers.map(lambda x: x ** 2)
filtered = squared.filter(lambda x: x > 1000000)
limited = filtered.take(5)  # ACTION - this triggers execution!

print(f"\nFirst 5 squares > 1,000,000: {limited}")
```

### Step 6.2: DAG (Directed Acyclic Graph)
```python
# Spark builds a DAG of transformations
data = sc.parallelize(["hello world", "spark is great"])

result = data.flatMap(lambda x: x.split(" ")) \
             .map(lambda word: (word, 1)) \
             .reduceByKey(lambda a, b: a + b)

# View the lineage (transformation history)
print(f"\nLineage: {result.toDebugString().decode()}")

# Execute with action
print(f"Result: {result.collect()}")
```

---

## Part 7: Caching and Persistence

### Step 7.1: cache() and persist()
```python
from pyspark import StorageLevel

# Create expensive RDD
large_rdd = sc.parallelize(range(1, 100001))
processed = large_rdd.map(lambda x: x * 2).filter(lambda x: x % 4 == 0)

# Cache in memory
processed.cache()  # Same as persist(StorageLevel.MEMORY_ONLY)

# First action - computes and caches
count1 = processed.count()
print(f"\nFirst count: {count1}")

# Second action - uses cache
count2 = processed.count()
print(f"Second count (cached): {count2}")

# Unpersist when done
processed.unpersist()
```

### Storage Levels
| Level | Description |
|-------|-------------|
| MEMORY_ONLY | Store in memory as objects |
| MEMORY_AND_DISK | Spill to disk if needed |
| DISK_ONLY | Store only on disk |
| MEMORY_ONLY_SER | Store serialized in memory |

---

## Exercises

### Exercise 1: Word Count
Given the text:
```
"the quick brown fox jumps over the lazy dog the fox is quick"
```
1. Create an RDD from this text
2. Count occurrences of each word
3. Find the most common word
4. Find words that appear only once

### Exercise 2: Number Analysis
Using numbers 1-100:
1. Create an RDD of numbers 1-100
2. Filter to keep only prime numbers
3. Calculate the sum of all primes
4. Find the largest prime

### Exercise 3: Log Analysis
Given log entries:
```python
logs = [
    "ERROR 2024-01-01 Database connection failed",
    "INFO 2024-01-01 Server started",
    "WARN 2024-01-01 High memory usage",
    "ERROR 2024-01-01 Timeout error",
    "INFO 2024-01-02 Request processed"
]
```
1. Create an RDD from logs
2. Count errors, warnings, and info messages
3. Extract unique dates
4. Find all error messages

---

## Cleanup
```python
# Always stop SparkContext when done
spark.stop()
print("\nSpark session stopped.")
```

---

## Summary

In this lab, you learned:
- ✅ What RDDs are and their properties
- ✅ How to create RDDs (parallelize, textFile)
- ✅ Transformations: map, filter, flatMap, distinct, union
- ✅ Actions: collect, count, reduce, sum, max, min
- ✅ Key-Value operations: reduceByKey, groupByKey, sortByKey
- ✅ Lazy evaluation and DAG
- ✅ Caching and persistence

**Next Lab**: Lab 03 - Spark SQL Basics
