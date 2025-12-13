# Spark Structured Streaming

## 🎯 Learning Objectives
- Understand streaming concepts and Spark Structured Streaming architecture
- Build real-time data pipelines with DataFrame API
- Implement window operations and watermarking
- Connect to streaming sources (Kafka, files, etc.)
- Handle late data and stateful processing

---

## Introduction to Stream Processing

### Batch vs Streaming

```
BATCH PROCESSING:
┌─────────┐     ┌─────────┐     ┌─────────┐
│  Data   │ --> │ Process │ --> │ Output  │
│ (Fixed) │     │ (Once)  │     │ (Once)  │
└─────────┘     └─────────┘     └─────────┘

STREAM PROCESSING:
┌─────────┐     ┌─────────┐     ┌─────────┐
│  Data   │ --> │ Process │ --> │ Output  │
│(Flowing)│     │(Continuous)│  │(Continuous)│
└─────────┘     └─────────┘     └─────────┘
```

### When to Use Streaming
- **Real-time dashboards**: Live metrics and KPIs
- **Fraud detection**: Immediate action on suspicious activity
- **IoT data**: Continuous sensor data processing
- **Log analysis**: Real-time monitoring and alerting
- **ETL pipelines**: Near-real-time data integration

---

## Structured Streaming Fundamentals

### Key Concept: Unbounded Table

Structured Streaming treats live data as an **infinite table** that keeps growing:

```
Time 1:   ┌─────────────────┐
          │ id │ value      │
          │ 1  │ 100        │
          └─────────────────┘
          
Time 2:   ┌─────────────────┐
          │ id │ value      │
          │ 1  │ 100        │
          │ 2  │ 200   <-- new data
          └─────────────────┘

Time 3:   ┌─────────────────┐
          │ id │ value      │
          │ 1  │ 100        │
          │ 2  │ 200        │
          │ 3  │ 300   <-- new data
          └─────────────────┘
```

### Basic Streaming Query

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder \
    .appName("StreamingDemo") \
    .getOrCreate()

# Read streaming data from a directory
streaming_df = spark.readStream \
    .format("json") \
    .schema(schema) \
    .option("maxFilesPerTrigger", 1) \
    .load("/data/input/")

# Transform (same as batch!)
transformed_df = streaming_df \
    .filter(col("value") > 0) \
    .groupBy("category") \
    .count()

# Write streaming output
query = transformed_df.writeStream \
    .outputMode("complete") \
    .format("console") \
    .start()

query.awaitTermination()
```

---

## Streaming Sources

### File Source

```python
# Read CSV files as they arrive
schema = StructType([
    StructField("id", IntegerType()),
    StructField("timestamp", TimestampType()),
    StructField("value", DoubleType())
])

df = spark.readStream \
    .format("csv") \
    .schema(schema) \
    .option("header", "true") \
    .option("maxFilesPerTrigger", 10) \
    .load("/data/incoming/")
```

### Kafka Source

```python
# Read from Kafka topic
df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "topic_name") \
    .option("startingOffsets", "latest") \
    .load()

# Kafka value is binary - parse it
parsed_df = df.select(
    col("key").cast("string"),
    from_json(col("value").cast("string"), schema).alias("data"),
    col("timestamp")
).select("key", "data.*", "timestamp")
```

### Rate Source (Testing)

```python
# Generate test data at specified rate
df = spark.readStream \
    .format("rate") \
    .option("rowsPerSecond", 100) \
    .load()

# Columns: timestamp, value
```

### Socket Source (Testing)

```python
# Read from TCP socket (for testing only!)
df = spark.readStream \
    .format("socket") \
    .option("host", "localhost") \
    .option("port", 9999) \
    .load()
```

---

## Output Modes

### Complete Mode
Outputs the **entire result table** every trigger. Use for aggregations.

```python
df.groupBy("category").count() \
    .writeStream \
    .outputMode("complete") \
    .format("console") \
    .start()
```

### Append Mode
Outputs only **new rows** since last trigger. Default mode.

```python
df.writeStream \
    .outputMode("append") \
    .format("parquet") \
    .option("path", "/output/") \
    .option("checkpointLocation", "/checkpoint/") \
    .start()
```

### Update Mode
Outputs only **rows that changed** since last trigger.

```python
df.groupBy("category").count() \
    .writeStream \
    .outputMode("update") \
    .format("console") \
    .start()
```

### Comparison

| Mode | Works With | Use Case |
|------|------------|----------|
| Append | No aggregations, select, filter | Simple ETL |
| Complete | Aggregations | Dashboards, full results |
| Update | Aggregations | Incremental updates |

---

## Streaming Sinks

### Console Sink (Testing)

```python
query = df.writeStream \
    .format("console") \
    .option("truncate", False) \
    .option("numRows", 50) \
    .outputMode("append") \
    .start()
```

### File Sink

```python
query = df.writeStream \
    .format("parquet") \
    .option("path", "/output/data/") \
    .option("checkpointLocation", "/output/checkpoint/") \
    .partitionBy("date") \
    .outputMode("append") \
    .start()
```

### Kafka Sink

```python
# Prepare data for Kafka (key-value format)
kafka_df = df.select(
    col("id").cast("string").alias("key"),
    to_json(struct("*")).alias("value")
)

query = kafka_df.writeStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("topic", "output_topic") \
    .option("checkpointLocation", "/checkpoint/kafka/") \
    .start()
```

### Delta Lake Sink

```python
query = df.writeStream \
    .format("delta") \
    .option("checkpointLocation", "/checkpoint/delta/") \
    .outputMode("append") \
    .start("/delta/streaming_output/")
```

### Foreach Sink (Custom)

```python
def process_row(row):
    # Custom logic for each row
    print(f"Processing: {row}")

query = df.writeStream \
    .foreach(process_row) \
    .start()

# Using ForeachBatch for micro-batch processing
def process_batch(batch_df, batch_id):
    # Process entire micro-batch
    batch_df.write.format("jdbc") \
        .option("url", jdbc_url) \
        .option("dbtable", "target_table") \
        .mode("append") \
        .save()

query = df.writeStream \
    .foreachBatch(process_batch) \
    .start()
```

---

## Triggers

### Default (Micro-batch)
Processes as fast as possible, waiting for previous batch to complete.

```python
query = df.writeStream \
    .format("console") \
    .start()  # Default trigger
```

### Fixed Interval

```python
from pyspark.sql.streaming import Trigger

# Process every 10 seconds
query = df.writeStream \
    .trigger(processingTime="10 seconds") \
    .format("console") \
    .start()
```

### Once (Batch-like)

```python
# Process once and stop (for catch-up processing)
query = df.writeStream \
    .trigger(once=True) \
    .format("parquet") \
    .option("path", "/output/") \
    .option("checkpointLocation", "/checkpoint/") \
    .start()

query.awaitTermination()  # Waits until done
```

### Available Now

```python
# Process all available data, then stop
query = df.writeStream \
    .trigger(availableNow=True) \
    .format("delta") \
    .start("/output/")
```

### Continuous (Experimental)

```python
# Millisecond latency processing
query = df.writeStream \
    .trigger(continuous="1 second") \
    .format("kafka") \
    .start()
```

---

## Window Operations

### Tumbling Windows

Non-overlapping, fixed-size windows:

```
Time:    0----5----10----15----20----25
Windows: [--0-5--] [--5-10--] [--10-15--]
```

```python
from pyspark.sql.functions import window

# 5-minute tumbling windows
windowed_df = df \
    .groupBy(
        window(col("timestamp"), "5 minutes"),
        col("category")
    ) \
    .agg(
        count("*").alias("count"),
        sum("value").alias("total")
    )
```

### Sliding Windows

Overlapping windows:

```
Time:    0----5----10----15----20
Windows: [----0-10----]
              [----5-15----]
                   [----10-20----]
```

```python
# 10-minute windows, sliding every 5 minutes
windowed_df = df \
    .groupBy(
        window(col("timestamp"), "10 minutes", "5 minutes"),
        col("category")
    ) \
    .agg(sum("value").alias("total"))
```

### Session Windows

Dynamic windows based on activity gaps:

```python
# Sessions with 10-minute gap
from pyspark.sql.functions import session_window

session_df = df \
    .groupBy(
        session_window(col("timestamp"), "10 minutes"),
        col("user_id")
    ) \
    .agg(
        count("*").alias("events_in_session"),
        min("timestamp").alias("session_start"),
        max("timestamp").alias("session_end")
    )
```

---

## Watermarking (Handling Late Data)

### The Late Data Problem

```
Event Time:  10:00   10:05   10:10   10:15   10:20
             │       │       │       │       │
Arrival:     10:01   10:06   10:11   10:16   10:07 (LATE!)
                                              │
                                     Event from 10:05 arrives late!
```

### Watermarking Solution

```python
# Accept events up to 10 minutes late
df_with_watermark = df \
    .withWatermark("event_time", "10 minutes") \
    .groupBy(
        window(col("event_time"), "5 minutes"),
        col("category")
    ) \
    .count()
```

### How Watermark Works

```
Watermark = Max Event Time Seen - Threshold

If current max event time = 10:20 and threshold = 10 minutes:
Watermark = 10:10

Events with event_time < 10:10 are dropped as "too late"
```

### Choosing Watermark Duration
- **Too short**: Lose valid late data
- **Too long**: Hold state in memory longer, higher memory usage

Consider your data's typical lateness and memory constraints.

---

## Stateful Processing

### State Management

Spark automatically manages state for:
- Aggregations (running counts, sums)
- Window operations
- Deduplication
- Custom stateful operations

```python
# Stateful aggregation - Spark manages the state
running_count = df \
    .withWatermark("timestamp", "1 hour") \
    .groupBy(
        window(col("timestamp"), "1 hour"),
        col("user_id")
    ) \
    .count()
```

### Deduplication

```python
# Remove duplicates within watermark window
deduplicated_df = df \
    .withWatermark("timestamp", "10 minutes") \
    .dropDuplicates(["id", "timestamp"])
```

### Stream-Stream Joins

```python
# Join two streams with watermarks
impressions = impression_stream \
    .withWatermark("impression_time", "2 hours")

clicks = click_stream \
    .withWatermark("click_time", "3 hours")

# Join within time range
joined = impressions.join(
    clicks,
    expr("""
        impression_id = click_impression_id AND
        click_time >= impression_time AND
        click_time <= impression_time + interval 1 hour
    """),
    "leftOuter"
)
```

---

## Checkpointing

### Why Checkpointing?

Checkpointing stores:
- **Offsets**: Position in source (which data was processed)
- **State**: Aggregation results, window data
- **Metadata**: Query configuration

```python
query = df.writeStream \
    .format("parquet") \
    .option("path", "/output/data/") \
    .option("checkpointLocation", "/output/checkpoint/") \
    .start()
```

### Checkpoint Contents

```
/checkpoint/
├── commits/          # Completed batch info
├── offsets/          # Source offsets per batch
├── sources/          # Source-specific state
├── state/            # Aggregation state
└── metadata          # Query metadata
```

### Recovery

When a query restarts:
1. Reads last committed batch from checkpoint
2. Recovers state from state store
3. Continues from where it left off

**Important**: Never delete checkpoints for production queries!

---

## Complete Streaming Pipeline Example

### Real-time Sales Dashboard

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("SalesDashboard") \
    .getOrCreate()

# Define schema for sales events
sales_schema = StructType([
    StructField("transaction_id", StringType()),
    StructField("product_id", StringType()),
    StructField("category", StringType()),
    StructField("amount", DoubleType()),
    StructField("quantity", IntegerType()),
    StructField("store_id", StringType()),
    StructField("event_time", TimestampType())
])

# Read from Kafka
raw_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "sales_events") \
    .option("startingOffsets", "latest") \
    .load()

# Parse JSON
sales_stream = raw_stream \
    .select(from_json(col("value").cast("string"), sales_schema).alias("data")) \
    .select("data.*")

# Add watermark for late data handling
sales_with_watermark = sales_stream \
    .withWatermark("event_time", "10 minutes")

# Calculate real-time metrics by category and 5-minute windows
category_metrics = sales_with_watermark \
    .groupBy(
        window(col("event_time"), "5 minutes"),
        col("category")
    ) \
    .agg(
        count("transaction_id").alias("transaction_count"),
        sum("amount").alias("total_revenue"),
        avg("amount").alias("avg_transaction_value"),
        sum("quantity").alias("items_sold")
    ) \
    .select(
        col("window.start").alias("window_start"),
        col("window.end").alias("window_end"),
        col("category"),
        col("transaction_count"),
        round(col("total_revenue"), 2).alias("total_revenue"),
        round(col("avg_transaction_value"), 2).alias("avg_transaction_value"),
        col("items_sold")
    )

# Write to Delta Lake for dashboard consumption
query = category_metrics.writeStream \
    .format("delta") \
    .outputMode("complete") \
    .option("checkpointLocation", "/checkpoint/sales_dashboard/") \
    .trigger(processingTime="30 seconds") \
    .start("/delta/sales_metrics/")

query.awaitTermination()
```

---

## 📚 Interview Questions (10 Q&A)

### Q1: What is Spark Structured Streaming?
**Answer**: Structured Streaming is Spark's stream processing engine built on the DataFrame API. It treats streaming data as an **unbounded table** that keeps growing. Key benefits:
- Same API as batch processing
- Exactly-once processing guarantees
- Built-in fault tolerance via checkpointing
- Supports event-time processing and watermarking

### Q2: Explain the three output modes in Structured Streaming.
**Answer**:
- **Append**: Only new rows since last trigger (default). Cannot use with aggregations.
- **Complete**: Entire result table every trigger. Use for aggregations.
- **Update**: Only rows that changed. Efficient for incremental updates.

Choose based on your use case: Append for simple ETL, Complete for dashboards, Update for incremental aggregations.

### Q3: What is watermarking and why is it needed?
**Answer**: Watermarking handles **late-arriving data** in event-time processing:
```python
df.withWatermark("event_time", "10 minutes")
```
It defines how long to wait for late data. Without watermarking, Spark would maintain state indefinitely, causing memory issues. The watermark is: `Max Event Time Seen - Threshold`. Events older than the watermark are dropped.

### Q4: How does checkpointing work in Structured Streaming?
**Answer**: Checkpointing stores:
- **Offsets**: Position in the source (e.g., Kafka offsets)
- **State**: Aggregation results, window data
- **Metadata**: Query configuration

On failure, Spark recovers from the checkpoint and continues processing. This enables **exactly-once semantics**. Never delete production checkpoints!

### Q5: Explain window operations in streaming.
**Answer**: Three types of windows:
- **Tumbling**: Fixed, non-overlapping (e.g., every 5 minutes)
- **Sliding**: Overlapping windows (e.g., 10-minute window, sliding every 5 minutes)
- **Session**: Dynamic windows based on activity gaps

```python
# Tumbling
window(col("timestamp"), "5 minutes")
# Sliding
window(col("timestamp"), "10 minutes", "5 minutes")
```

### Q6: How do you handle late data in Structured Streaming?
**Answer**:
1. **Watermarking**: Define acceptable lateness threshold
2. **Window aggregations**: Aggregate by event time, not processing time
3. **Update mode**: Updates previous results when late data arrives

```python
df.withWatermark("event_time", "1 hour") \
    .groupBy(window(col("event_time"), "10 minutes")) \
    .count()
```

### Q7: What's the difference between processing time and event time?
**Answer**:
- **Event time**: When the event actually occurred (embedded in data)
- **Processing time**: When Spark processes the event

Always use event time for accurate analytics. Processing time can be misleading due to delays, batching, or out-of-order arrival.

### Q8: How do you join two streams in Structured Streaming?
**Answer**: Stream-stream joins require watermarks on both streams:
```python
stream1 = df1.withWatermark("time1", "1 hour")
stream2 = df2.withWatermark("time2", "2 hours")

joined = stream1.join(
    stream2,
    expr("id1 = id2 AND time2 BETWEEN time1 AND time1 + interval 1 hour")
)
```
The watermarks define how long to buffer each stream.

### Q9: What triggers are available in Structured Streaming?
**Answer**:
- **Default**: Process as fast as possible
- **Fixed interval**: `trigger(processingTime="10 seconds")`
- **Once**: `trigger(once=True)` - batch-like, single run
- **Available Now**: `trigger(availableNow=True)` - process all available data
- **Continuous**: `trigger(continuous="1 second")` - low-latency (experimental)

### Q10: How would you implement exactly-once processing?
**Answer**: Structured Streaming provides exactly-once with:
1. **Checkpointing**: Store offsets and state reliably
2. **Idempotent sinks**: Sinks that handle replays (Delta Lake, JDBC with upsert)
3. **Transactional sources**: Kafka with offset tracking

```python
df.writeStream \
    .format("delta") \
    .option("checkpointLocation", "/checkpoint/") \
    .start("/output/")
```

Delta Lake is ideal because it provides ACID transactions, making the sink idempotent.
