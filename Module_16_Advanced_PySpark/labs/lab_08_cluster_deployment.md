# Lab 08: Spark Cluster Deployment

## Overview
Learn to deploy PySpark applications on cluster managers.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Understand Spark cluster architecture
- ✅ Deploy on Standalone cluster
- ✅ Submit applications with spark-submit
- ✅ Configure cluster resources
- ✅ Monitor and troubleshoot jobs

---

## Part 1: Spark Cluster Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Spark Cluster Architecture                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│                       ┌─────────────────────┐                           │
│                       │   Cluster Manager   │                           │
│                       │  (Standalone/YARN/  │                           │
│                       │   Mesos/K8s)        │                           │
│                       └─────────┬───────────┘                           │
│                                 │                                        │
│         ┌───────────────────────┼───────────────────────┐               │
│         │                       │                       │               │
│         ▼                       ▼                       ▼               │
│  ┌─────────────┐        ┌─────────────┐        ┌─────────────┐         │
│  │   Worker    │        │   Worker    │        │   Worker    │         │
│  │   Node 1    │        │   Node 2    │        │   Node 3    │         │
│  │ ┌─────────┐ │        │ ┌─────────┐ │        │ ┌─────────┐ │         │
│  │ │Executor │ │        │ │Executor │ │        │ │Executor │ │         │
│  │ │ ┌─────┐ │ │        │ │ ┌─────┐ │ │        │ │ ┌─────┐ │ │         │
│  │ │ │Task │ │ │        │ │ │Task │ │ │        │ │ │Task │ │ │         │
│  │ │ └─────┘ │ │        │ │ └─────┘ │ │        │ │ └─────┘ │ │         │
│  │ └─────────┘ │        │ └─────────┘ │        │ └─────────┘ │         │
│  └─────────────┘        └─────────────┘        └─────────────┘         │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Driver Program                              │   │
│  │                    (SparkContext/Session)                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Standalone Cluster Setup

### Step 2.1: Start Master
```bash
# Start master node
$SPARK_HOME/sbin/start-master.sh

# Master Web UI: http://localhost:8080
# Master URL: spark://hostname:7077
```

### Step 2.2: Start Workers
```bash
# Start worker on same machine
$SPARK_HOME/sbin/start-worker.sh spark://hostname:7077

# Start worker with specific resources
$SPARK_HOME/sbin/start-worker.sh spark://hostname:7077 \
    --cores 4 \
    --memory 8G
```

### Step 2.3: Configuration Files
```bash
# conf/spark-env.sh
export SPARK_MASTER_HOST=master-hostname
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
export SPARK_WORKER_CORES=4
export SPARK_WORKER_MEMORY=8g
export SPARK_WORKER_INSTANCES=1

# conf/workers (list of worker hostnames)
worker1
worker2
worker3
```

### Step 2.4: Start/Stop Cluster
```bash
# Start all (master + workers)
$SPARK_HOME/sbin/start-all.sh

# Stop all
$SPARK_HOME/sbin/stop-all.sh
```

---

## Part 3: spark-submit

### Step 3.1: Basic Usage
```bash
spark-submit \
    --master spark://hostname:7077 \
    --deploy-mode client \
    my_script.py
```

### Step 3.2: Resource Configuration
```bash
spark-submit \
    --master spark://hostname:7077 \
    --deploy-mode cluster \
    --driver-memory 4g \
    --driver-cores 2 \
    --executor-memory 8g \
    --executor-cores 4 \
    --num-executors 10 \
    --conf spark.sql.shuffle.partitions=200 \
    my_etl_job.py
```

### Step 3.3: Full Example
```bash
spark-submit \
    --master spark://master:7077 \
    --deploy-mode cluster \
    --name "Daily Sales ETL" \
    --driver-memory 4g \
    --driver-cores 2 \
    --executor-memory 8g \
    --executor-cores 4 \
    --num-executors 10 \
    --py-files dependencies.zip \
    --files config.json \
    --conf spark.sql.shuffle.partitions=200 \
    --conf spark.dynamicAllocation.enabled=true \
    --conf spark.dynamicAllocation.minExecutors=2 \
    --conf spark.dynamicAllocation.maxExecutors=20 \
    --jars mysql-connector.jar \
    --packages io.delta:delta-core_2.12:2.4.0 \
    s3://bucket/scripts/daily_sales_etl.py \
    --date 2024-01-15 \
    --env production
```

---

## Part 4: Deploy Modes

### Step 4.1: Client Mode
```bash
# Driver runs on submitting machine
spark-submit \
    --master spark://hostname:7077 \
    --deploy-mode client \
    my_script.py

# Use for:
# - Interactive development
# - Notebooks
# - When you need driver logs locally
```

### Step 4.2: Cluster Mode
```bash
# Driver runs on cluster
spark-submit \
    --master spark://hostname:7077 \
    --deploy-mode cluster \
    my_script.py

# Use for:
# - Production jobs
# - Scheduled jobs
# - Better fault tolerance
```

---

## Part 5: YARN Deployment

### Step 5.1: YARN Configuration
```bash
# Set Hadoop configuration
export HADOOP_CONF_DIR=/etc/hadoop/conf
export YARN_CONF_DIR=/etc/hadoop/conf

spark-submit \
    --master yarn \
    --deploy-mode cluster \
    my_script.py
```

### Step 5.2: YARN-Specific Options
```bash
spark-submit \
    --master yarn \
    --deploy-mode cluster \
    --queue production \
    --conf spark.yarn.submit.waitAppCompletion=true \
    --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=/usr/bin/python3 \
    --conf spark.executorEnv.PYSPARK_PYTHON=/usr/bin/python3 \
    my_script.py
```

---

## Part 6: Kubernetes Deployment

### Step 6.1: Build Docker Image
```dockerfile
# Dockerfile
FROM apache/spark-py:3.4.0

USER root

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install -r /app/requirements.txt

# Copy application
COPY my_app/ /app/

WORKDIR /app

USER 185
```

### Step 6.2: K8s Submit
```bash
spark-submit \
    --master k8s://https://kubernetes-master:6443 \
    --deploy-mode cluster \
    --name spark-etl \
    --conf spark.kubernetes.container.image=my-spark-image:latest \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
    --conf spark.kubernetes.namespace=spark-apps \
    --conf spark.executor.instances=5 \
    local:///app/my_script.py
```

---

## Part 7: Application Structure

### Step 7.1: Project Layout
```
my_spark_project/
├── src/
│   ├── __init__.py
│   ├── jobs/
│   │   ├── __init__.py
│   │   ├── daily_etl.py
│   │   └── weekly_report.py
│   ├── transformations/
│   │   ├── __init__.py
│   │   └── sales.py
│   └── utils/
│       ├── __init__.py
│       └── spark_utils.py
├── config/
│   ├── dev.json
│   └── prod.json
├── tests/
│   └── test_transformations.py
├── requirements.txt
└── setup.py
```

### Step 7.2: Packaging Dependencies
```bash
# Create zip for py-files
cd src
zip -r ../dependencies.zip .

# Submit with dependencies
spark-submit \
    --py-files dependencies.zip \
    main.py
```

### Step 7.3: Main Entry Point
```python
# main.py
import argparse
from pyspark.sql import SparkSession
from src.jobs.daily_etl import DailyETLJob

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--date", required=True)
    parser.add_argument("--env", default="dev")
    args = parser.parse_args()
    
    spark = SparkSession.builder \
        .appName(f"Daily ETL - {args.date}") \
        .getOrCreate()
    
    try:
        job = DailyETLJob(spark, args.date, args.env)
        job.run()
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
```

---

## Part 8: Resource Configuration

### Step 8.1: Memory Settings
```python
# Common memory configurations
configs = {
    # Driver memory
    "spark.driver.memory": "4g",
    "spark.driver.memoryOverhead": "1g",
    
    # Executor memory
    "spark.executor.memory": "8g",
    "spark.executor.memoryOverhead": "2g",
    
    # Memory fractions
    "spark.memory.fraction": "0.6",
    "spark.memory.storageFraction": "0.5",
}
```

### Step 8.2: Executor Sizing
```
Rules of thumb:
- 3-5 cores per executor (balance parallelism vs overhead)
- Memory: 4-8 GB per core
- Leave 1 core per node for YARN/OS

Example: Node with 16 cores, 64GB RAM
- 3 executors with 5 cores each
- ~20GB memory per executor
- 1 core + 4GB for overhead
```

### Step 8.3: Dynamic Allocation
```bash
spark-submit \
    --conf spark.dynamicAllocation.enabled=true \
    --conf spark.dynamicAllocation.minExecutors=2 \
    --conf spark.dynamicAllocation.maxExecutors=20 \
    --conf spark.dynamicAllocation.initialExecutors=5 \
    --conf spark.dynamicAllocation.executorIdleTimeout=60s \
    --conf spark.dynamicAllocation.schedulerBacklogTimeout=1s \
    my_script.py
```

---

## Part 9: Monitoring

### Step 9.1: Spark UI
```
Application UI: http://driver:4040
History Server: http://master:18080
Master UI: http://master:8080

Key metrics to monitor:
- Stage duration
- Task distribution
- Shuffle read/write
- Memory usage
- GC time
```

### Step 9.2: Enable History Server
```bash
# conf/spark-defaults.conf
spark.eventLog.enabled=true
spark.eventLog.dir=hdfs://namenode/spark-history
spark.history.fs.logDirectory=hdfs://namenode/spark-history

# Start history server
$SPARK_HOME/sbin/start-history-server.sh
```

### Step 9.3: Metrics
```python
# Access metrics in code
spark.sparkContext.statusTracker().getActiveJobIds()
spark.sparkContext.statusTracker().getActiveStageIds()

# Custom accumulators
counter = spark.sparkContext.accumulator(0)

def process(row):
    counter.add(1)
    return row

df.foreach(process)
print(f"Processed: {counter.value}")
```

---

## Part 10: Troubleshooting

### Step 10.1: Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| OOM on driver | Large collect() | Use take(), sample() |
| OOM on executor | Large partitions | Increase partitions, memory |
| Slow stages | Data skew | Salt keys, repartition |
| Long GC | Memory pressure | Tune memory fractions |
| Connection refused | Network issues | Check firewall, ports |

### Step 10.2: Debugging
```bash
# Check driver logs
yarn logs -applicationId application_xxx

# Check executor logs
yarn logs -applicationId application_xxx -containerId container_xxx

# Increase log level
spark-submit \
    --conf spark.driver.extraJavaOptions="-Dlog4j.logger.org.apache.spark=DEBUG" \
    my_script.py
```

### Step 10.3: Configuration Validation
```python
# Print all configurations
for conf in spark.sparkContext.getConf().getAll():
    print(f"{conf[0]} = {conf[1]}")

# Check specific settings
print(spark.conf.get("spark.executor.memory"))
print(spark.conf.get("spark.sql.shuffle.partitions"))
```

---

## Part 11: Production Best Practices

### Step 11.1: Job Template
```python
# production_job.py
import sys
import logging
from pyspark.sql import SparkSession

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)

def create_spark_session(app_name):
    return SparkSession.builder \
        .appName(app_name) \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .getOrCreate()

def main():
    logger = setup_logging()
    
    try:
        logger.info("Starting job")
        spark = create_spark_session("Production ETL")
        
        # Your job logic here
        
        logger.info("Job completed successfully")
        sys.exit(0)
        
    except Exception as e:
        logger.error(f"Job failed: {e}")
        sys.exit(1)
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
```

### Step 11.2: Configuration Management
```python
# config.py
import json
import os

class Config:
    def __init__(self, env="dev"):
        self.env = env
        self.load_config()
    
    def load_config(self):
        config_file = f"config/{self.env}.json"
        with open(config_file) as f:
            self.settings = json.load(f)
    
    @property
    def input_path(self):
        return self.settings["paths"]["input"]
    
    @property
    def output_path(self):
        return self.settings["paths"]["output"]
```

---

## Exercises

1. Set up a 3-node Standalone cluster
2. Submit a job with custom configuration
3. Configure dynamic allocation
4. Monitor a job using Spark UI

---

## Summary
- Understand cluster architecture
- Use spark-submit for job submission
- Configure resources appropriately
- Choose correct deploy mode
- Monitor with Spark UI and logs
- Follow production best practices
