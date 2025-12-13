# Spark Setup and Configuration - Complete Guide

## 📚 What You'll Learn
- Installing Spark locally
- PySpark configuration
- SparkSession creation
- Spark UI basics
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐ Beginner

---

## 🎯 Installation Options

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SPARK INSTALLATION OPTIONS                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ OPTION 1: PySpark (pip) - Easiest for Python developers        │   │
│   │                                                                  │   │
│   │   pip install pyspark                                            │   │
│   │   • All-in-one package                                           │   │
│   │   • Includes Spark, Py4J, basic jars                            │   │
│   │   • Works immediately                                            │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ OPTION 2: Full Spark Download - More control                    │   │
│   │                                                                  │   │
│   │   1. Download from spark.apache.org                              │   │
│   │   2. Extract to folder                                           │   │
│   │   3. Set SPARK_HOME environment variable                         │   │
│   │   4. Add to PATH                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ OPTION 3: Docker - Clean isolated environment                   │   │
│   │                                                                  │   │
│   │   docker run -it -p 8888:8888 jupyter/pyspark-notebook           │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ OPTION 4: Cloud Services - No setup needed                      │   │
│   │                                                                  │   │
│   │   • Databricks (Azure, AWS, GCP)                                 │   │
│   │   • Azure Synapse Analytics                                      │   │
│   │   • AWS EMR                                                      │   │
│   │   • Google Dataproc                                              │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Option 1: PySpark via pip (Recommended for Learning)

### Prerequisites

```bash
# Python 3.8+ required
python --version

# Java 8 or 11 required
java -version

# If Java not installed:
# Windows: Download from adoptopenjdk.net or Oracle
# Mac: brew install openjdk@11
# Linux: sudo apt install openjdk-11-jdk
```

### Installation

```bash
# Basic install
pip install pyspark

# With specific Spark version
pip install pyspark==3.5.0

# With optional dependencies
pip install pyspark[sql]
pip install pyspark[ml]
pip install pyspark[connect]

# For Jupyter notebook support
pip install pyspark findspark jupyter
```

### Verify Installation

```python
# Test PySpark
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Test") \
    .getOrCreate()

# Create simple DataFrame
df = spark.createDataFrame([
    (1, "Alice", 100),
    (2, "Bob", 200)
], ["id", "name", "amount"])

df.show()

# Check Spark version
print(f"Spark version: {spark.version}")

spark.stop()
```

---

## 🔧 Option 2: Full Spark Installation

### Windows

```powershell
# 1. Download Spark
# Visit: https://spark.apache.org/downloads.html
# Choose: spark-3.5.0-bin-hadoop3.tgz

# 2. Extract to C:\spark

# 3. Set environment variables
[System.Environment]::SetEnvironmentVariable("SPARK_HOME", "C:\spark", "User")
[System.Environment]::SetEnvironmentVariable("HADOOP_HOME", "C:\spark", "User")

# Add to PATH
$path = [System.Environment]::GetEnvironmentVariable("PATH", "User")
[System.Environment]::SetEnvironmentVariable("PATH", "$path;C:\spark\bin", "User")

# 4. Download winutils.exe for Windows
# Place in C:\spark\bin\
# Download from: https://github.com/steveloughran/winutils

# 5. Restart terminal and test
pyspark
```

### macOS/Linux

```bash
# 1. Download and extract
wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
tar -xzf spark-3.5.0-bin-hadoop3.tgz
sudo mv spark-3.5.0-bin-hadoop3 /opt/spark

# 2. Add to ~/.bashrc or ~/.zshrc
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# 3. Reload and test
source ~/.bashrc
pyspark
```

---

## 📝 SparkSession - Entry Point

### Basic SparkSession

```python
from pyspark.sql import SparkSession

# Create SparkSession (recommended approach)
spark = SparkSession.builder \
    .appName("MyApplication") \
    .getOrCreate()

# SparkContext is accessible through SparkSession
sc = spark.sparkContext
```

### SparkSession with Configuration

```python
spark = SparkSession.builder \
    .appName("ConfiguredApp") \
    .master("local[*]") \
    .config("spark.executor.memory", "2g") \
    .config("spark.driver.memory", "1g") \
    .config("spark.sql.shuffle.partitions", "200") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()
```

### Master URL Options

```python
# Local mode - single JVM
.master("local")        # 1 thread
.master("local[4]")     # 4 threads
.master("local[*]")     # All available cores

# Standalone cluster
.master("spark://master:7077")

# YARN
.master("yarn")

# Kubernetes
.master("k8s://https://kubernetes:443")

# Mesos
.master("mesos://host:5050")
```

---

## ⚙️ Configuration Options

### Memory Configuration

```python
spark = SparkSession.builder \
    .config("spark.driver.memory", "4g") \
    .config("spark.executor.memory", "8g") \
    .config("spark.executor.memoryOverhead", "1g") \
    .config("spark.memory.fraction", "0.6") \
    .config("spark.memory.storageFraction", "0.5") \
    .getOrCreate()
```

### Parallelism Configuration

```python
spark = SparkSession.builder \
    .config("spark.default.parallelism", "100") \
    .config("spark.sql.shuffle.partitions", "200") \
    .config("spark.executor.cores", "4") \
    .getOrCreate()
```

### Common Configurations

| Configuration | Description | Default |
|--------------|-------------|---------|
| `spark.driver.memory` | Driver memory | 1g |
| `spark.executor.memory` | Executor memory | 1g |
| `spark.executor.cores` | Cores per executor | 1 |
| `spark.sql.shuffle.partitions` | Shuffle partitions | 200 |
| `spark.default.parallelism` | Default RDD partitions | Total cores |
| `spark.sql.adaptive.enabled` | Adaptive Query Execution | true (Spark 3.2+) |
| `spark.serializer` | Serializer class | JavaSerializer |

### Runtime Configuration

```python
# Set at runtime
spark.conf.set("spark.sql.shuffle.partitions", "100")

# Get configuration
value = spark.conf.get("spark.sql.shuffle.partitions")

# Get all configurations
all_conf = spark.sparkContext.getConf().getAll()
for conf in all_conf:
    print(conf)
```

---

## 🖥️ Spark UI

### Accessing Spark UI

```python
# Default port: 4040
# URL: http://localhost:4040

# Access while SparkSession is active
spark = SparkSession.builder.appName("UIDemo").getOrCreate()
# Navigate to http://localhost:4040
```

### Spark UI Tabs

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SPARK UI (port 4040)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐           │
│   │   Jobs    │  │  Stages   │  │  Storage  │  │Environment│           │
│   │           │  │           │  │           │  │           │           │
│   │ • All jobs│  │ • Stage   │  │ • Cached  │  │ • Spark   │           │
│   │ • Status  │  │   details │  │   RDDs    │  │   props   │           │
│   │ • Timeline│  │ • Tasks   │  │ • Size    │  │ • Classpath│          │
│   └───────────┘  └───────────┘  └───────────┘  └───────────┘           │
│                                                                          │
│   ┌───────────┐  ┌───────────┐  ┌───────────┐                           │
│   │ Executors │  │    SQL    │  │ Streaming │                           │
│   │           │  │           │  │           │                           │
│   │ • Memory  │  │ • Query   │  │ • Batches │                           │
│   │ • Tasks   │  │   plans   │  │ • Latency │                           │
│   │ • GC time │  │ • Stats   │  │ • Rate    │                           │
│   └───────────┘  └───────────┘  └───────────┘                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key Metrics to Monitor

- **Job Duration**: Total time for job completion
- **Task Duration**: Time per task (identify stragglers)
- **Shuffle Read/Write**: Data movement between stages
- **GC Time**: Garbage collection overhead
- **Memory Usage**: Executor memory utilization

---

## 📓 PySpark in Jupyter Notebooks

### Setup with findspark

```python
# First cell in notebook
import findspark
findspark.init()

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("JupyterSpark") \
    .config("spark.ui.showConsoleProgress", "true") \
    .getOrCreate()
```

### Databricks Notebooks

```python
# In Databricks, spark is pre-configured
# Just use directly:
df = spark.read.parquet("/path/to/data")
display(df)
```

### Configure for Notebooks

```python
# Better display in notebooks
spark.conf.set("spark.sql.repl.eagerEval.enabled", True)
spark.conf.set("spark.sql.repl.eagerEval.maxNumRows", 20)

# Now DataFrames display automatically
df  # Shows table without .show()
```

---

## 🔌 Adding Dependencies

### Adding Packages

```python
# Via SparkSession builder
spark = SparkSession.builder \
    .appName("WithPackages") \
    .config("spark.jars.packages", "io.delta:delta-core_2.12:2.4.0") \
    .getOrCreate()

# Multiple packages
spark = SparkSession.builder \
    .config("spark.jars.packages", 
            "io.delta:delta-core_2.12:2.4.0,"
            "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0") \
    .getOrCreate()
```

### Adding JAR Files

```python
# Via config
spark = SparkSession.builder \
    .config("spark.jars", "/path/to/driver.jar") \
    .getOrCreate()

# Via spark-submit
# spark-submit --jars /path/to/jar1.jar,/path/to/jar2.jar script.py
```

### JDBC Drivers

```python
# For database connectivity
spark = SparkSession.builder \
    .config("spark.jars", "/path/to/sqljdbc42.jar") \
    .getOrCreate()

# Read from SQL Server
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:sqlserver://server:1433;databaseName=db") \
    .option("dbtable", "schema.table") \
    .option("user", "username") \
    .option("password", "password") \
    .load()
```

---

## 🛠️ spark-submit

### Basic Usage

```bash
# Run Python script
spark-submit script.py

# With configurations
spark-submit \
    --master local[*] \
    --driver-memory 4g \
    --executor-memory 8g \
    --conf spark.sql.shuffle.partitions=200 \
    script.py

# With packages
spark-submit \
    --packages io.delta:delta-core_2.12:2.4.0 \
    script.py

# For cluster
spark-submit \
    --master spark://master:7077 \
    --deploy-mode cluster \
    --num-executors 10 \
    --executor-cores 4 \
    --executor-memory 8g \
    script.py
```

### Common spark-submit Options

| Option | Description |
|--------|-------------|
| `--master` | Cluster manager URL |
| `--deploy-mode` | client or cluster |
| `--driver-memory` | Driver memory |
| `--executor-memory` | Executor memory |
| `--executor-cores` | Cores per executor |
| `--num-executors` | Number of executors |
| `--packages` | Maven coordinates |
| `--jars` | JAR file paths |
| `--conf` | Spark configuration |
| `--py-files` | Python files to add |

---

## 🎓 Interview Questions

### Q1: What is SparkSession?
**A:** SparkSession is the unified entry point for Spark functionality since Spark 2.0. It combines SparkContext, SQLContext, and HiveContext:
```python
spark = SparkSession.builder.appName("App").getOrCreate()
```

### Q2: What is the difference between local[*] and local[4]?
**A:**
- `local[*]`: Uses all available CPU cores
- `local[4]`: Uses exactly 4 threads
- `local`: Uses 1 thread

### Q3: How do you configure Spark memory?
**A:** Through SparkSession configuration:
```python
.config("spark.driver.memory", "4g")
.config("spark.executor.memory", "8g")
```

### Q4: What is spark-submit used for?
**A:** Command-line tool to submit Spark applications to a cluster. Allows specifying master, memory, cores, packages, and other configurations.

### Q5: How do you access Spark UI?
**A:** Default URL is `http://localhost:4040` when SparkSession is active. Shows jobs, stages, executors, SQL queries, and storage info.

### Q6: What is deploy-mode in spark-submit?
**A:**
- **client**: Driver runs on submitting machine (default)
- **cluster**: Driver runs on cluster (production)

### Q7: How do you add external packages to Spark?
**A:**
- Via config: `.config("spark.jars.packages", "group:artifact:version")`
- Via spark-submit: `--packages group:artifact:version`
- Via JAR: `.config("spark.jars", "/path/to/jar")`

### Q8: What is the default number of shuffle partitions?
**A:** 200, configurable via `spark.sql.shuffle.partitions`

### Q9: What is findspark used for?
**A:** Python library that locates Spark installation and adds it to Python path, useful for Jupyter notebooks.

### Q10: How do you stop a SparkSession?
**A:** Call `spark.stop()` to release resources and terminate the session.

---

## 🔗 Related Topics
- [← Spark Overview](./01_spark_overview.md)
- [RDD Basics →](./03_rdd_basics.md)
- [DataFrames →](../Module_15_PySpark/01_dataframe_basics.md)

---

*Continue to RDD Basics*
