# Azure Data Engineering Guide

## 🎯 Learning Objectives
- Understand Azure data services ecosystem
- Learn key services: Azure Data Factory, Synapse, Databricks
- Master Azure storage options for data engineering
- Understand when to use each service
- Prepare for Azure Data Engineer certification (DP-203)

---

## Azure Data Engineering Ecosystem

### Service Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA SOURCES                                  │
│  On-premises DBs | SaaS Apps | IoT Devices | Files | APIs       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      INGESTION                                   │
│   Azure Data Factory | Event Hubs | IoT Hub | Logic Apps        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       STORAGE                                    │
│   Azure Data Lake Gen2 | Blob Storage | Cosmos DB | SQL DB      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PROCESSING                                     │
│   Synapse Analytics | Databricks | HDInsight | Stream Analytics │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SERVING                                      │
│   Synapse SQL | Analysis Services | Cosmos DB | SQL DB          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   VISUALIZATION                                  │
│   Power BI | Azure Dashboards | Custom Apps                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Azure Data Lake Storage Gen2

### What is ADLS Gen2?

Azure Data Lake Storage Gen2 combines:
- **Blob Storage**: Scalable, cost-effective storage
- **Hierarchical Namespace**: True directory structure for big data analytics
- **POSIX permissions**: Fine-grained access control

### Key Features

| Feature | Description |
|---------|-------------|
| Hierarchical Namespace | True folders, atomic directory operations |
| POSIX ACLs | User/group/other permissions |
| Scalability | Exabytes of data, millions of files |
| Performance | Optimized for analytics workloads |
| Cost | Hot, Cool, Archive tiers |
| Security | Encryption, firewall, private endpoints |

### Storage Structure

```
Storage Account
├── Container (Bronze)
│   ├── raw/
│   │   ├── sales/
│   │   │   ├── 2024/01/01/file1.json
│   │   │   └── 2024/01/02/file2.json
│   │   └── customers/
│   └── landing/
├── Container (Silver)
│   ├── cleaned/
│   └── validated/
└── Container (Gold)
    ├── aggregated/
    └── reports/
```

### Access Methods

```python
# Using Azure SDK
from azure.storage.filedatalake import DataLakeServiceClient

service_client = DataLakeServiceClient(
    account_url=f"https://{account_name}.dfs.core.windows.net",
    credential=credential
)

# Create container
file_system_client = service_client.create_file_system("bronze")

# Upload file
file_client = file_system_client.create_file("raw/data.json")
file_client.append_data(data, 0)
file_client.flush_data(len(data))

# Using PySpark
df = spark.read.format("parquet") \
    .load("abfss://container@account.dfs.core.windows.net/path/")
```

---

## Azure Data Factory (ADF)

### What is ADF?

Azure Data Factory is a **cloud-based ETL/ELT** service for:
- Data ingestion from 90+ sources
- Data transformation (mapping data flows)
- Orchestration and scheduling
- Monitoring and alerting

### Core Components

```
PIPELINE
├── Activities
│   ├── Copy Activity (move data)
│   ├── Data Flow Activity (transform)
│   ├── Lookup Activity (get values)
│   ├── ForEach Activity (loop)
│   ├── If Condition (branching)
│   ├── Execute Pipeline (call another pipeline)
│   └── Web Activity (call REST APIs)
├── Datasets (data structure definition)
├── Linked Services (connection strings)
└── Triggers (schedule, event, tumbling window)
```

### Copy Activity

```json
{
    "name": "CopyFromSQLToADLS",
    "type": "Copy",
    "inputs": [
        {
            "referenceName": "SqlServerDataset",
            "type": "DatasetReference"
        }
    ],
    "outputs": [
        {
            "referenceName": "ADLSDataset",
            "type": "DatasetReference"
        }
    ],
    "typeProperties": {
        "source": {
            "type": "SqlServerSource",
            "sqlReaderQuery": "SELECT * FROM Sales WHERE Date > @{pipeline().parameters.StartDate}"
        },
        "sink": {
            "type": "ParquetSink"
        }
    }
}
```

### Mapping Data Flows

Visual transformation tool supporting:
- Source/Sink transformations
- Filter, Select, Derived Column
- Aggregate, Join, Union
- Lookup, Pivot/Unpivot
- Window functions
- Conditional Split

### Triggers

| Trigger Type | Use Case |
|-------------|----------|
| Schedule | Run at specific times (e.g., daily at 2 AM) |
| Tumbling Window | Process data in fixed time windows |
| Event-based | React to blob creation/deletion |
| On-demand | Manual trigger for testing |

---

## Azure Synapse Analytics

### What is Synapse?

Azure Synapse is an **integrated analytics service** combining:
- Enterprise data warehousing (Dedicated SQL Pool)
- Big data analytics (Spark Pool)
- Data integration (Synapse Pipelines ≈ ADF)
- Serverless querying (Serverless SQL Pool)

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SYNAPSE WORKSPACE                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Dedicated    │  │ Serverless   │  │   Spark      │       │
│  │ SQL Pool     │  │ SQL Pool     │  │   Pool       │       │
│  │              │  │              │  │              │       │
│  │ - MPP DW     │  │ - Query ADLS │  │ - PySpark    │       │
│  │ - Structured │  │ - Pay per TB │  │ - Scala      │       │
│  │ - Star Schema│  │ - Ad-hoc     │  │ - .NET       │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Synapse Pipelines (≈ ADF)                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Azure Data Lake Storage Gen2                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Dedicated SQL Pool (formerly SQL DW)

Massively Parallel Processing (MPP) data warehouse:

```sql
-- Create distributed table
CREATE TABLE Sales (
    SaleID INT,
    ProductID INT,
    CustomerID INT,
    Amount DECIMAL(10,2),
    SaleDate DATE
)
WITH (
    DISTRIBUTION = HASH(CustomerID),
    CLUSTERED COLUMNSTORE INDEX
);

-- Distribution types:
-- HASH: Distribute by column value (for large fact tables)
-- ROUND_ROBIN: Even distribution (for staging)
-- REPLICATE: Full copy on each node (for small dimension tables)
```

### Serverless SQL Pool

Query data directly in ADLS without loading:

```sql
-- Query Parquet files directly
SELECT 
    CustomerID,
    SUM(Amount) as TotalSales
FROM OPENROWSET(
    BULK 'https://storage.dfs.core.windows.net/container/sales/*.parquet',
    FORMAT = 'PARQUET'
) AS sales
GROUP BY CustomerID;

-- Create external table
CREATE EXTERNAL TABLE dbo.Sales (
    SaleID INT,
    Amount DECIMAL(10,2)
)
WITH (
    LOCATION = '/sales/',
    DATA_SOURCE = ADLSDataSource,
    FILE_FORMAT = ParquetFormat
);
```

### Spark Pool

Apache Spark in Synapse:

```python
# Read from ADLS
df = spark.read.parquet("abfss://container@account.dfs.core.windows.net/data/")

# Transform
result = df.groupBy("category").agg(
    sum("amount").alias("total")
)

# Write to Synapse SQL Pool
result.write \
    .format("com.databricks.spark.sqldw") \
    .option("url", jdbc_url) \
    .option("forwardSparkAzureStorageCredentials", "true") \
    .option("dbTable", "dbo.CategorySales") \
    .option("tempDir", "abfss://temp@account.dfs.core.windows.net/staging/") \
    .mode("overwrite") \
    .save()
```

---

## Azure Databricks

### What is Databricks?

Azure Databricks is a **unified analytics platform** based on Apache Spark:
- Optimized Spark runtime (3-5x faster)
- Collaborative notebooks
- MLflow integration
- Delta Lake native support
- Unity Catalog for governance

### Key Features

| Feature | Description |
|---------|-------------|
| Workspace | Collaborative environment with notebooks |
| Clusters | Managed Spark compute |
| Jobs | Scheduled workflows |
| Delta Lake | ACID transactions on data lake |
| MLflow | ML lifecycle management |
| Unity Catalog | Unified data governance |

### Cluster Types

- **All-Purpose**: Interactive analysis, development
- **Job Clusters**: Automated pipelines, cost-optimized
- **SQL Warehouses**: BI queries, SQL analytics

### Delta Lake in Databricks

```python
# Create Delta table
df.write.format("delta").save("/mnt/delta/sales")

# Create managed table
df.write.format("delta").saveAsTable("sales")

# MERGE (upsert)
from delta.tables import DeltaTable

deltaTable = DeltaTable.forPath(spark, "/mnt/delta/sales")
deltaTable.alias("target").merge(
    source_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()

# Time travel
df = spark.read.format("delta").option("versionAsOf", 5).load("/mnt/delta/sales")
```

---

## Event Hubs & Stream Analytics

### Azure Event Hubs

Managed event streaming platform (like Kafka):

```python
# Send events
from azure.eventhub import EventHubProducerClient, EventData

producer = EventHubProducerClient.from_connection_string(conn_str)
event_batch = producer.create_batch()
event_batch.add(EventData('{"sensor_id": 1, "temp": 25.5}'))
producer.send_batch(event_batch)

# Receive events (using PySpark)
df = spark.readStream \
    .format("eventhubs") \
    .options(**eh_conf) \
    .load()
```

### Stream Analytics

SQL-based stream processing:

```sql
-- Real-time aggregation
SELECT 
    System.Timestamp() AS WindowEnd,
    SensorId,
    AVG(Temperature) AS AvgTemp,
    COUNT(*) AS EventCount
FROM InputEventHub TIMESTAMP BY EventTime
GROUP BY 
    SensorId,
    TumblingWindow(minute, 5)
```

---

## Service Comparison

### When to Use What?

| Scenario | Recommended Service |
|----------|-------------------|
| Simple ETL from databases | Azure Data Factory |
| Complex Spark transformations | Databricks or Synapse Spark |
| Enterprise Data Warehouse | Synapse Dedicated SQL Pool |
| Ad-hoc queries on data lake | Synapse Serverless SQL |
| Real-time streaming | Event Hubs + Stream Analytics |
| ML workloads | Databricks + MLflow |
| BI reporting | Synapse + Power BI |

### Cost Optimization Tips

1. **Use Serverless when possible**: Pay per query, not compute time
2. **Auto-pause clusters**: Databricks and Synapse support auto-pause
3. **Right-size dedicated pools**: Start small, scale as needed
4. **Use spot instances**: For non-critical workloads
5. **Archive cold data**: Use Cool/Archive tiers for old data
6. **Partition wisely**: Reduce data scanned in queries

---

## DP-203 Certification Path

### Exam Topics

| Domain | Weight |
|--------|--------|
| Design and implement data storage | 15-20% |
| Design and develop data processing | 40-45% |
| Design and implement data security | 10-15% |
| Monitor and optimize data storage and processing | 10-15% |

### Key Topics to Master

1. **Storage**
   - ADLS Gen2 structure and security
   - Partitioning strategies
   - File formats (Parquet, Delta, ORC)

2. **Processing**
   - ADF pipelines and activities
   - Synapse SQL (dedicated and serverless)
   - Spark transformations
   - Streaming with Event Hubs

3. **Security**
   - Azure AD authentication
   - Managed identities
   - Row-level security
   - Data masking

4. **Optimization**
   - Distribution strategies
   - Indexing (clustered, columnstore)
   - Caching
   - Monitoring with Azure Monitor

---

## 📚 Interview Questions (10 Q&A)

### Q1: What is Azure Data Lake Storage Gen2?
**Answer**: ADLS Gen2 combines blob storage scalability with a **hierarchical namespace** for big data analytics. Key features:
- True directory structure (not flat blob naming)
- POSIX ACLs for fine-grained security
- Optimized for Spark and analytics workloads
- Hot/Cool/Archive tiers for cost optimization
- Integration with Synapse, Databricks, ADF

### Q2: When would you use ADF vs. Databricks for ETL?
**Answer**:
- **ADF**: Simple data movement, no-code transformations, orchestration, when source/sink are the main complexity
- **Databricks**: Complex transformations, ML integration, when Spark coding is needed, Delta Lake operations

Often used together: ADF orchestrates, Databricks transforms.

### Q3: Explain Synapse SQL Pool distribution types.
**Answer**:
- **HASH**: Distribute rows by hash of a column. Use for large fact tables; choose column with high cardinality used in JOINs
- **ROUND_ROBIN**: Even distribution. Use for staging tables or when no good hash key exists
- **REPLICATE**: Full copy on each node. Use for small dimension tables (< 2GB) to avoid data movement in JOINs

### Q4: What is the difference between Synapse Dedicated and Serverless SQL?
**Answer**:
- **Dedicated**: Provisioned compute, MPP warehouse, structured data, for consistent workloads
- **Serverless**: Pay-per-query, query ADLS directly, no provisioning, for ad-hoc exploration

Use Dedicated for production workloads, Serverless for exploration and cost-sensitive queries.

### Q5: How do you secure data in Azure Data Lake?
**Answer**:
1. **Storage Firewall**: Restrict network access
2. **Private Endpoints**: No public internet exposure
3. **RBAC**: Azure role-based access control
4. **ACLs**: POSIX permissions on folders/files
5. **Managed Identities**: No credentials in code
6. **Encryption**: At-rest and in-transit encryption
7. **Azure AD**: Centralized identity management

### Q6: What is Azure Event Hubs and when would you use it?
**Answer**: Event Hubs is a **managed event streaming platform** (similar to Kafka):
- Millions of events per second
- Partitioned for parallelism
- Capture to ADLS automatically

Use cases:
- IoT data ingestion
- Application telemetry
- Real-time analytics pipelines
- Clickstream processing

### Q7: Explain the medallion architecture in Azure.
**Answer**: A data lake design pattern with three layers:
- **Bronze**: Raw data, append-only, original format
- **Silver**: Cleaned, validated, standardized, deduplicated
- **Gold**: Business-ready aggregations, dimension/fact tables

Typically implemented with:
- ADLS Gen2 for storage
- Databricks/Synapse for processing
- Delta Lake for reliability

### Q8: How do you optimize Synapse SQL Pool performance?
**Answer**:
1. **Distribution**: Choose right strategy (HASH for facts)
2. **Indexes**: Clustered columnstore for analytics
3. **Statistics**: Keep statistics updated
4. **Result set caching**: Enable for repeated queries
5. **Materialized views**: Pre-compute aggregations
6. **Workload management**: Prioritize important queries
7. **Partition pruning**: Partition by date for time-based queries

### Q9: What is Azure Databricks Unity Catalog?
**Answer**: Unity Catalog provides **unified governance** across Databricks:
- Centralized access control
- Data lineage tracking
- Data discovery and search
- Cross-workspace sharing
- Audit logging

It's the governance layer for Databricks, similar to Purview for broader Azure.

### Q10: How would you design a real-time analytics solution in Azure?
**Answer**:
```
Architecture:
1. Ingestion: Event Hubs (high throughput) or IoT Hub
2. Processing: Stream Analytics (SQL) or Databricks Streaming
3. Storage: Delta Lake in ADLS for historical, Cosmos DB for hot data
4. Serving: Synapse Serverless for queries, Power BI for dashboards

Key considerations:
- Latency requirements (seconds vs minutes)
- Data volume and velocity
- Cost (serverless vs provisioned)
- Exactly-once processing (use Delta Lake)
```
