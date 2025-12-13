# Lab 03: Spark Streaming Basics

## Overview
Introduction to Structured Streaming for real-time data processing.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Understand Structured Streaming concepts
- ✅ Create streaming DataFrames
- ✅ Apply transformations to streaming data
- ✅ Write to various output sinks
- ✅ Handle watermarks and late data

---

## Part 1: Streaming Concepts

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Structured Streaming: Treat stream as an unbounded table               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│ Time →                                                                   │
│ ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐                      │
│ │ Row │ Row │ Row │ Row │ Row │ Row │ Row │ ... │  ← Unbounded Table   │
│ └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘                      │
│                                                                          │
│ Query runs incrementally on new data                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Spark Streaming") \
    .master("local[*]") \
    .config("spark.sql.streaming.checkpointLocation", "/tmp/checkpoint") \
    .getOrCreate()

# Reduce logging
spark.sparkContext.setLogLevel("WARN")
```

---

## Part 3: Reading from File Source

### Step 3.1: Create Sample Data Directory
```python
import os
import json

# Create directory for streaming data
os.makedirs("streaming_data", exist_ok=True)

# Write sample JSON files
for i in range(3):
    data = [
        {"id": i*3+1, "name": f"Event_{i*3+1}", "value": 100 + i*10, "timestamp": "2024-01-15 10:00:00"},
        {"id": i*3+2, "name": f"Event_{i*3+2}", "value": 200 + i*10, "timestamp": "2024-01-15 10:01:00"},
        {"id": i*3+3, "name": f"Event_{i*3+3}", "value": 300 + i*10, "timestamp": "2024-01-15 10:02:00"},
    ]
    with open(f"streaming_data/events_{i}.json", "w") as f:
        for record in data:
            f.write(json.dumps(record) + "\n")
```

### Step 3.2: Define Schema
```python
event_schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("value", DoubleType(), True),
    StructField("timestamp", StringType(), True)
])
```

### Step 3.3: Read Stream
```python
# Read streaming data from JSON files
streaming_df = spark.readStream \
    .format("json") \
    .schema(event_schema) \
    .option("maxFilesPerTrigger", 1) \
    .load("streaming_data/")

# Check if streaming
print(f"Is streaming: {streaming_df.isStreaming}")
streaming_df.printSchema()
```

---

## Part 4: Streaming Transformations

### Step 4.1: Basic Transformations
```python
# Apply transformations (same as batch)
transformed_df = streaming_df \
    .withColumn("value_doubled", col("value") * 2) \
    .withColumn("event_time", to_timestamp("timestamp")) \
    .filter(col("value") > 100)
```

### Step 4.2: Aggregations
```python
# Streaming aggregations require output mode
agg_df = streaming_df \
    .withColumn("event_time", to_timestamp("timestamp")) \
    .groupBy(window("event_time", "1 minute")) \
    .agg(
        count("*").alias("event_count"),
        sum("value").alias("total_value"),
        avg("value").alias("avg_value")
    )
```

---

## Part 5: Output Sinks

### Step 5.1: Console Sink (Debugging)
```python
# Write to console
query = transformed_df \
    .writeStream \
    .format("console") \
    .outputMode("append") \
    .trigger(processingTime="5 seconds") \
    .start()

# Wait for some batches
import time
time.sleep(15)
query.stop()
```

### Step 5.2: File Sink
```python
# Write to Parquet files
query = transformed_df \
    .writeStream \
    .format("parquet") \
    .outputMode("append") \
    .option("path", "output/streaming_parquet") \
    .option("checkpointLocation", "/tmp/checkpoint/parquet") \
    .trigger(processingTime="10 seconds") \
    .start()

# Let it run
time.sleep(20)
query.stop()
```

### Step 5.3: Memory Sink (Testing)
```python
# Write to in-memory table
query = streaming_df \
    .writeStream \
    .format("memory") \
    .queryName("events_memory") \
    .outputMode("append") \
    .start()

time.sleep(10)

# Query the in-memory table
spark.sql("SELECT * FROM events_memory").show()

query.stop()
```

---

## Part 6: Output Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `append` | Only new rows | Simple transformations |
| `complete` | All rows | Aggregations |
| `update` | Only changed rows | Aggregations with updates |

```python
# Append mode - only new rows
query_append = transformed_df \
    .writeStream \
    .format("console") \
    .outputMode("append") \
    .start()

# Complete mode - full result table
query_complete = agg_df \
    .writeStream \
    .format("console") \
    .outputMode("complete") \
    .start()

# Update mode - only updated rows
query_update = agg_df \
    .writeStream \
    .format("console") \
    .outputMode("update") \
    .start()
```

---

## Part 7: Trigger Types

```python
# Processing time trigger (micro-batch)
query = streaming_df \
    .writeStream \
    .format("console") \
    .trigger(processingTime="10 seconds") \
    .start()

# Once trigger (process all available, then stop)
query = streaming_df \
    .writeStream \
    .format("console") \
    .trigger(once=True) \
    .start()

# Continuous trigger (low-latency, experimental)
# query = streaming_df \
#     .writeStream \
#     .format("console") \
#     .trigger(continuous="1 second") \
#     .start()

# Available now trigger (like once, but async)
query = streaming_df \
    .writeStream \
    .format("console") \
    .trigger(availableNow=True) \
    .start()
```

---

## Part 8: Watermarks and Late Data

### Step 8.1: Event Time vs Processing Time
```python
# Event time is when event occurred
# Processing time is when Spark processes it

# Late data: event_time << processing_time
# Example: Event at 10:00 arrives at 10:15
```

### Step 8.2: Watermarks
```python
# Define watermark to handle late data
streaming_with_watermark = streaming_df \
    .withColumn("event_time", to_timestamp("timestamp")) \
    .withWatermark("event_time", "10 minutes")

# Aggregate with watermark
agg_with_watermark = streaming_with_watermark \
    .groupBy(
        window("event_time", "5 minutes", "1 minute")
    ) \
    .agg(
        count("*").alias("event_count"),
        sum("value").alias("total_value")
    )

query = agg_with_watermark \
    .writeStream \
    .format("console") \
    .outputMode("update") \
    .trigger(processingTime="10 seconds") \
    .start()
```

### Step 8.3: Watermark Behavior
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Watermark = Max Event Time Seen - Threshold                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│ Example: Watermark threshold = 10 minutes                                │
│                                                                          │
│ If latest event time seen = 10:20                                        │
│ Then watermark = 10:10                                                   │
│                                                                          │
│ Events with event_time < 10:10 are dropped (too late)                   │
│ Events with event_time >= 10:10 are processed                           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 9: Stateful Operations

### Step 9.1: Deduplication
```python
# Remove duplicates based on id within watermark window
deduplicated_df = streaming_df \
    .withColumn("event_time", to_timestamp("timestamp")) \
    .withWatermark("event_time", "10 minutes") \
    .dropDuplicates(["id", "event_time"])
```

### Step 9.2: Stream-Stream Joins
```python
# Create two streams
stream1 = spark.readStream \
    .format("json") \
    .schema(event_schema) \
    .load("streaming_data1/")

stream2 = spark.readStream \
    .format("json") \
    .schema(event_schema) \
    .load("streaming_data2/")

# Add watermarks
stream1_wm = stream1 \
    .withColumn("event_time", to_timestamp("timestamp")) \
    .withWatermark("event_time", "10 minutes")

stream2_wm = stream2 \
    .withColumn("event_time", to_timestamp("timestamp")) \
    .withWatermark("event_time", "10 minutes") \
    .select(col("id").alias("id2"), col("value").alias("value2"), "event_time")

# Join streams
joined = stream1_wm.join(
    stream2_wm,
    expr("""
        id = id2 AND
        stream1_wm.event_time >= stream2_wm.event_time - interval 5 minutes AND
        stream1_wm.event_time <= stream2_wm.event_time + interval 5 minutes
    """),
    "inner"
)
```

---

## Part 10: Monitoring Streaming Queries

### Step 10.1: Query Progress
```python
query = streaming_df \
    .writeStream \
    .format("console") \
    .outputMode("append") \
    .start()

# Check status
print(f"Query ID: {query.id}")
print(f"Query Name: {query.name}")
print(f"Is Active: {query.isActive}")
print(f"Status: {query.status}")
print(f"Last Progress: {query.lastProgress}")

# Recent progress
for progress in query.recentProgress:
    print(progress)
```

### Step 10.2: Await Termination
```python
# Block until query terminates or timeout
try:
    query.awaitTermination(timeout=60)  # 60 seconds timeout
except Exception as e:
    print(f"Query stopped: {e}")
finally:
    if query.isActive:
        query.stop()
```

### Step 10.3: Exception Handling
```python
# Get exception if query failed
if query.exception():
    print(f"Query failed: {query.exception()}")

# Listen for query events
class StreamingQueryListener:
    def onQueryStarted(self, event):
        print(f"Query started: {event.id}")
    
    def onQueryProgress(self, event):
        print(f"Query progress: {event.progress.numInputRows} rows")
    
    def onQueryTerminated(self, event):
        print(f"Query terminated: {event.id}")
```

---

## Part 11: Checkpointing

```python
# Checkpointing is REQUIRED for fault tolerance

query = streaming_df \
    .writeStream \
    .format("parquet") \
    .outputMode("append") \
    .option("path", "output/streaming_output") \
    .option("checkpointLocation", "/tmp/checkpoint/my_query") \
    .start()

# Checkpoint contains:
# - Offset log (what data has been read)
# - Commit log (what data has been written)
# - State store (for stateful operations)
```

---

## Part 12: Complete Example

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Complete Streaming Example") \
    .master("local[*]") \
    .getOrCreate()

# Schema
schema = StructType([
    StructField("user_id", IntegerType()),
    StructField("action", StringType()),
    StructField("value", DoubleType()),
    StructField("timestamp", TimestampType())
])

# Read stream
stream_df = spark.readStream \
    .format("json") \
    .schema(schema) \
    .option("maxFilesPerTrigger", 1) \
    .load("events/")

# Transform with watermark
transformed = stream_df \
    .withWatermark("timestamp", "10 minutes") \
    .groupBy(
        window("timestamp", "5 minutes"),
        "action"
    ) \
    .agg(
        count("*").alias("action_count"),
        sum("value").alias("total_value"),
        countDistinct("user_id").alias("unique_users")
    )

# Write to console
query = transformed \
    .writeStream \
    .format("console") \
    .outputMode("update") \
    .trigger(processingTime="10 seconds") \
    .option("checkpointLocation", "/tmp/checkpoint/complete") \
    .start()

query.awaitTermination(120)
query.stop()
```

---

## Exercises

1. Create a streaming pipeline that reads JSON and writes Parquet
2. Implement a windowed aggregation with watermarks
3. Create a stream-to-stream join
4. Monitor query progress and handle failures

---

## Summary
- Structured Streaming treats streams as unbounded tables
- Same DataFrame API for batch and streaming
- Output modes: append, complete, update
- Watermarks handle late data
- Checkpointing ensures fault tolerance
- Monitor via query.status and query.lastProgress
