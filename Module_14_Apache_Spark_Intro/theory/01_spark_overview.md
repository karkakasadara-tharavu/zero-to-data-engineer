# Apache Spark Overview - Complete Guide

## 📚 What You'll Learn
- What is Apache Spark
- Spark ecosystem components
- Spark vs traditional tools
- Use cases and applications
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐ Beginner

---

## 🎯 What is Apache Spark?

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          APACHE SPARK                                    │
│              Unified Analytics Engine for Big Data                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      SPARK APPLICATIONS                          │   │
│   │                                                                  │   │
│   │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │   │
│   │  │ Spark    │ │ Spark    │ │Structured│ │  MLlib   │           │   │
│   │  │   SQL    │ │Streaming │ │Streaming │ │    ML    │           │   │
│   │  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │   │
│   │                                                                  │   │
│   │  ┌──────────┐ ┌──────────────────────────────────────┐         │   │
│   │  │ GraphX   │ │         DataFrame/Dataset API        │         │   │
│   │  │  Graphs  │ │                                      │         │   │
│   │  └──────────┘ └──────────────────────────────────────┘         │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                   │                                      │
│                                   ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                         SPARK CORE                               │   │
│   │            RDD (Resilient Distributed Dataset)                   │   │
│   │         Task Scheduling, Memory Management, Fault Recovery       │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                   │                                      │
│                                   ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                     CLUSTER MANAGER                              │   │
│   │      Standalone │ YARN │ Kubernetes │ Mesos │ Local             │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                   │                                      │
│                                   ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        STORAGE                                   │   │
│   │     HDFS │ S3 │ Azure Blob │ Local FS │ Cassandra │ HBase       │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Features of Spark

### Speed
- **In-Memory Computing**: Up to 100x faster than Hadoop MapReduce
- **DAG Execution Engine**: Optimizes workflows
- **Catalyst Optimizer**: Query optimization for Spark SQL

### Ease of Use
- **High-Level APIs**: Python, Scala, Java, R, SQL
- **Interactive Shell**: spark-shell, pyspark
- **DataFrame API**: Familiar tabular operations

### Generality
- **Unified Platform**: Batch, streaming, ML, graph processing
- **Library Ecosystem**: SQL, MLlib, GraphX, Streaming
- **Single Application**: Combine multiple workloads

### Runs Everywhere
- **Cluster Managers**: Standalone, YARN, Kubernetes, Mesos
- **Data Sources**: HDFS, S3, Cassandra, HBase, JDBC, etc.
- **Deployment**: Cloud, On-Premise, Hybrid

---

## 📊 Spark Ecosystem Components

### Spark SQL
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("SparkSQL").getOrCreate()

# Read data
df = spark.read.parquet("data.parquet")

# SQL queries
df.createOrReplaceTempView("sales")
result = spark.sql("""
    SELECT region, SUM(amount) as total
    FROM sales
    GROUP BY region
    ORDER BY total DESC
""")
```

### Spark Streaming / Structured Streaming
```python
# Real-time data processing
stream_df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "host:9092") \
    .option("subscribe", "topic") \
    .load()

# Process and write
query = stream_df.writeStream \
    .format("parquet") \
    .option("path", "output/") \
    .start()
```

### MLlib (Machine Learning)
```python
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.feature import VectorAssembler

# Feature engineering
assembler = VectorAssembler(inputCols=["feature1", "feature2"], outputCol="features")
training_data = assembler.transform(df)

# Train model
lr = LogisticRegression(maxIter=10)
model = lr.fit(training_data)
```

### GraphX (Graph Processing)
```python
# Graph analytics (Scala/Java API primarily)
# Used for social networks, page ranking, etc.
```

---

## ⚖️ Spark vs Hadoop MapReduce

| Feature | Spark | Hadoop MapReduce |
|---------|-------|-----------------|
| **Processing** | In-memory | Disk-based |
| **Speed** | 10-100x faster | Slower |
| **Ease of Use** | High-level APIs | Low-level Java |
| **Real-time** | Yes (Streaming) | No (Batch only) |
| **ML Support** | Built-in (MLlib) | Separate (Mahout) |
| **Iterative** | Excellent | Poor |
| **Cost** | More RAM needed | More disk I/O |
| **Languages** | Python, Scala, Java, R, SQL | Java |

---

## 🔄 Spark vs Pandas

| Feature | Spark | Pandas |
|---------|-------|--------|
| **Scale** | Distributed (TB-PB) | Single machine (GB) |
| **Execution** | Lazy evaluation | Eager evaluation |
| **Memory** | Out-of-core | In-memory |
| **APIs** | Similar (DataFrame) | Native |
| **Speed (small data)** | Overhead | Faster |
| **Speed (big data)** | Much faster | Can't handle |
| **SQL Support** | Native | Via SQLite/DuckDB |
| **Streaming** | Built-in | No |

### When to Use What

**Use Pandas when:**
- Data fits in memory (< 10 GB typically)
- Interactive analysis
- Simple transformations
- Local development

**Use Spark when:**
- Data exceeds memory
- Distributed processing needed
- Real-time/streaming data
- Production pipelines
- ML at scale

---

## 🏗️ Spark Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SPARK APPLICATION                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                         DRIVER PROGRAM                           │   │
│   │                                                                  │   │
│   │    ┌────────────────┐    ┌────────────────────────────────┐    │   │
│   │    │ SparkContext   │    │     DAG Scheduler              │    │   │
│   │    │ SparkSession   │───▶│     Task Scheduler             │    │   │
│   │    │ (Entry Point)  │    │     Job Submission             │    │   │
│   │    └────────────────┘    └────────────────────────────────┘    │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                   │                                      │
│                                   ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                       CLUSTER MANAGER                            │   │
│   │              (Standalone / YARN / Kubernetes)                    │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                   │                                      │
│           ┌───────────────────────┼───────────────────────┐             │
│           ▼                       ▼                       ▼             │
│   ┌──────────────┐       ┌──────────────┐       ┌──────────────┐       │
│   │   EXECUTOR   │       │   EXECUTOR   │       │   EXECUTOR   │       │
│   │              │       │              │       │              │       │
│   │ ┌────┐┌────┐ │       │ ┌────┐┌────┐ │       │ ┌────┐┌────┐ │       │
│   │ │Task││Task│ │       │ │Task││Task│ │       │ │Task││Task│ │       │
│   │ └────┘└────┘ │       │ └────┘└────┘ │       │ └────┘└────┘ │       │
│   │   Cache      │       │   Cache      │       │   Cache      │       │
│   └──────────────┘       └──────────────┘       └──────────────┘       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Components Explained

**Driver Program**
- Main entry point
- Creates SparkContext/SparkSession
- Defines transformations and actions
- Coordinates execution

**Cluster Manager**
- Allocates resources
- Manages worker nodes
- Options: Standalone, YARN, Kubernetes, Mesos

**Executors**
- Run on worker nodes
- Execute tasks
- Store data in cache
- Report status to driver

---

## 📝 Spark Applications and Jobs

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      SPARK EXECUTION HIERARCHY                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   APPLICATION (spark-submit)                                             │
│       │                                                                  │
│       ├── JOB 1 (triggered by action like count(), save())             │
│       │      │                                                          │
│       │      ├── Stage 1 (group of tasks, separated by shuffle)        │
│       │      │      ├── Task 1.1 (runs on partition)                   │
│       │      │      ├── Task 1.2                                       │
│       │      │      └── Task 1.3                                       │
│       │      │                                                          │
│       │      └── Stage 2                                                │
│       │             ├── Task 2.1                                       │
│       │             └── Task 2.2                                       │
│       │                                                                  │
│       └── JOB 2 (another action)                                        │
│              └── ...                                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Common Use Cases

### 1. ETL / Data Processing
```python
# Large-scale data transformation
df = spark.read.parquet("s3://bucket/raw_data/")
cleaned = df.filter(df.status == "active") \
    .withColumn("year", year(df.date)) \
    .groupBy("year", "category").agg(sum("amount"))
cleaned.write.parquet("s3://bucket/processed_data/")
```

### 2. Data Lake Analytics
```python
# Query data lake with SQL
spark.sql("""
    SELECT customer_id, SUM(amount) as lifetime_value
    FROM delta.`/data/transactions`
    WHERE year >= 2020
    GROUP BY customer_id
""")
```

### 3. Machine Learning Pipelines
```python
# Train model on billions of records
from pyspark.ml import Pipeline
from pyspark.ml.feature import VectorAssembler, StandardScaler
from pyspark.ml.classification import RandomForestClassifier

pipeline = Pipeline(stages=[assembler, scaler, rf])
model = pipeline.fit(training_data)
```

### 4. Real-Time Streaming
```python
# Process IoT sensor data in real-time
stream = spark.readStream.format("kafka").load()
processed = stream.select(json_tuple("value", "sensor_id", "reading"))
query = processed.writeStream.format("delta").start()
```

### 5. Graph Analytics
```python
# Social network analysis, fraud detection
# PageRank, Connected Components, etc.
```

---

## 🎓 Interview Questions

### Q1: What is Apache Spark?
**A:** Apache Spark is a unified analytics engine for large-scale data processing. It provides high-level APIs in Python, Scala, Java, R, and SQL, and supports batch processing, streaming, machine learning, and graph processing.

### Q2: What makes Spark faster than MapReduce?
**A:**
- In-memory processing (vs disk-based)
- DAG execution engine (optimizes job graph)
- Lazy evaluation (optimizes before execution)
- Avoids unnecessary I/O

### Q3: What is lazy evaluation in Spark?
**A:** Transformations are not executed immediately. Spark builds a DAG (Directed Acyclic Graph) of operations and only executes when an action is called (like `count()`, `collect()`, `save()`).

### Q4: What is the difference between transformation and action?
**A:**
- **Transformation**: Creates new RDD/DataFrame, lazy (e.g., `filter`, `map`, `select`)
- **Action**: Triggers execution, returns result (e.g., `count`, `show`, `save`)

### Q5: What is a SparkSession?
**A:** Entry point for Spark functionality. Combines SparkContext, SQLContext, and HiveContext into a single interface:
```python
spark = SparkSession.builder.appName("MyApp").getOrCreate()
```

### Q6: What are the components of Spark ecosystem?
**A:**
- **Spark Core**: RDDs, task scheduling
- **Spark SQL**: Structured data processing
- **Spark Streaming**: Real-time processing
- **MLlib**: Machine learning
- **GraphX**: Graph processing

### Q7: What cluster managers does Spark support?
**A:** Standalone, Apache YARN, Kubernetes, Apache Mesos, and Local mode for development.

### Q8: When would you use Spark over Pandas?
**A:** When data exceeds single machine memory, need distributed processing, require streaming, or need to integrate with big data ecosystem (HDFS, Hive, etc.).

### Q9: What is the driver and executor in Spark?
**A:**
- **Driver**: Main process that creates SparkContext, defines DAG, coordinates execution
- **Executor**: Worker processes that run tasks and cache data

### Q10: What is a Stage and Task in Spark?
**A:**
- **Stage**: Set of tasks that can run in parallel (separated by shuffles)
- **Task**: Unit of work on a single partition, runs on one executor

---

## 🔗 Related Topics
- [← Python ETL](../Module_13_Python_ETL/04_etl_python.md)
- [Spark Setup →](./02_spark_setup.md)
- [RDD Basics →](./03_rdd_basics.md)

---

*Continue to Spark Setup*
