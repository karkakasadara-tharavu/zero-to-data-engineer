# Lab 07: PySpark with Cloud Storage

## Overview
Learn to integrate PySpark with cloud storage services (AWS S3, Azure Blob, GCS).

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Configure cloud storage access
- ✅ Read/write data from/to S3, Azure, GCS
- ✅ Handle authentication securely
- ✅ Optimize cloud storage performance
- ✅ Work with cloud-native formats

---

## Part 1: Cloud Storage Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Cloud Storage for Data Engineering                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│ AWS S3:           s3://bucket-name/path/to/data                         │
│ Azure Blob:       wasbs://container@account.blob.core.windows.net/path  │
│ Azure ADLS Gen2:  abfss://filesystem@account.dfs.core.windows.net/path  │
│ Google Cloud:     gs://bucket-name/path/to/data                         │
│                                                                          │
│ Benefits:                                                                │
│ - Scalable, durable storage                                             │
│ - Pay-per-use pricing                                                   │
│ - Native integration with cloud services                                │
│ - Data lake architecture support                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: AWS S3 Configuration

### Step 2.1: Required Dependencies
```bash
# Install AWS SDK
pip install boto3

# Spark packages (add to spark-submit or conf)
# org.apache.hadoop:hadoop-aws:3.3.4
```

### Step 2.2: SparkSession Configuration
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("S3 Integration") \
    .master("local[*]") \
    .config("spark.jars.packages", "org.apache.hadoop:hadoop-aws:3.3.4") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.hadoop.fs.s3a.access.key", "YOUR_ACCESS_KEY") \
    .config("spark.hadoop.fs.s3a.secret.key", "YOUR_SECRET_KEY") \
    .config("spark.hadoop.fs.s3a.endpoint", "s3.amazonaws.com") \
    .getOrCreate()
```

### Step 2.3: Environment Variables (Recommended)
```python
import os

# Set credentials via environment variables
os.environ['AWS_ACCESS_KEY_ID'] = 'YOUR_ACCESS_KEY'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'YOUR_SECRET_KEY'
os.environ['AWS_REGION'] = 'us-east-1'

spark = SparkSession.builder \
    .appName("S3 Integration") \
    .config("spark.jars.packages", "org.apache.hadoop:hadoop-aws:3.3.4") \
    .config("spark.hadoop.fs.s3a.aws.credentials.provider", 
            "com.amazonaws.auth.EnvironmentVariableCredentialsProvider") \
    .getOrCreate()
```

### Step 2.4: IAM Role (Best for EMR/EC2)
```python
spark = SparkSession.builder \
    .appName("S3 Integration") \
    .config("spark.jars.packages", "org.apache.hadoop:hadoop-aws:3.3.4") \
    .config("spark.hadoop.fs.s3a.aws.credentials.provider", 
            "com.amazonaws.auth.InstanceProfileCredentialsProvider") \
    .getOrCreate()
```

### Step 2.5: Read/Write S3
```python
# Read from S3
df = spark.read.parquet("s3a://my-bucket/data/sales/")

# Read CSV with options
df = spark.read \
    .option("header", True) \
    .option("inferSchema", True) \
    .csv("s3a://my-bucket/data/customers.csv")

# Write to S3
df.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet("s3a://my-bucket/output/sales_partitioned/")

# Write with compression
df.write \
    .mode("overwrite") \
    .option("compression", "snappy") \
    .parquet("s3a://my-bucket/output/compressed/")
```

---

## Part 3: Azure Blob Storage Configuration

### Step 3.1: Required Dependencies
```bash
pip install azure-storage-blob

# Spark packages
# org.apache.hadoop:hadoop-azure:3.3.4
# com.microsoft.azure:azure-storage:8.6.6
```

### Step 3.2: Blob Storage Configuration
```python
storage_account = "your_storage_account"
access_key = "your_access_key"
container = "your_container"

spark = SparkSession.builder \
    .appName("Azure Integration") \
    .config("spark.jars.packages", 
            "org.apache.hadoop:hadoop-azure:3.3.4,com.microsoft.azure:azure-storage:8.6.6") \
    .config(f"spark.hadoop.fs.azure.account.key.{storage_account}.blob.core.windows.net", 
            access_key) \
    .getOrCreate()

# Read from Azure Blob
df = spark.read.parquet(
    f"wasbs://{container}@{storage_account}.blob.core.windows.net/data/sales/"
)
```

### Step 3.3: Azure Data Lake Storage Gen2
```python
storage_account = "your_storage_account"
filesystem = "your_filesystem"

# OAuth authentication
spark = SparkSession.builder \
    .appName("ADLS Gen2 Integration") \
    .config("spark.jars.packages", "org.apache.hadoop:hadoop-azure:3.3.4") \
    .config(f"spark.hadoop.fs.azure.account.auth.type.{storage_account}.dfs.core.windows.net", 
            "OAuth") \
    .config(f"spark.hadoop.fs.azure.account.oauth.provider.type.{storage_account}.dfs.core.windows.net",
            "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider") \
    .config(f"spark.hadoop.fs.azure.account.oauth2.client.id.{storage_account}.dfs.core.windows.net",
            "YOUR_CLIENT_ID") \
    .config(f"spark.hadoop.fs.azure.account.oauth2.client.secret.{storage_account}.dfs.core.windows.net",
            "YOUR_CLIENT_SECRET") \
    .config(f"spark.hadoop.fs.azure.account.oauth2.client.endpoint.{storage_account}.dfs.core.windows.net",
            f"https://login.microsoftonline.com/YOUR_TENANT_ID/oauth2/token") \
    .getOrCreate()

# Read from ADLS Gen2
df = spark.read.parquet(
    f"abfss://{filesystem}@{storage_account}.dfs.core.windows.net/data/sales/"
)
```

---

## Part 4: Google Cloud Storage Configuration

### Step 4.1: Required Dependencies
```bash
pip install google-cloud-storage

# Spark packages
# com.google.cloud.bigdataoss:gcs-connector:hadoop3-2.2.11
```

### Step 4.2: GCS Configuration
```python
import os

# Set credentials path
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/path/to/service-account.json'

spark = SparkSession.builder \
    .appName("GCS Integration") \
    .config("spark.jars.packages", "com.google.cloud.bigdataoss:gcs-connector:hadoop3-2.2.11") \
    .config("spark.hadoop.fs.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem") \
    .config("spark.hadoop.google.cloud.auth.service.account.enable", "true") \
    .config("spark.hadoop.google.cloud.auth.service.account.json.keyfile", 
            "/path/to/service-account.json") \
    .getOrCreate()

# Read from GCS
df = spark.read.parquet("gs://my-bucket/data/sales/")

# Write to GCS
df.write \
    .mode("overwrite") \
    .parquet("gs://my-bucket/output/processed/")
```

---

## Part 5: Performance Optimization

### Step 5.1: S3 Optimization
```python
spark = SparkSession.builder \
    .appName("S3 Optimized") \
    .config("spark.hadoop.fs.s3a.fast.upload", "true") \
    .config("spark.hadoop.fs.s3a.fast.upload.buffer", "bytebuffer") \
    .config("spark.hadoop.fs.s3a.multipart.size", "104857600") \  # 100MB parts
    .config("spark.hadoop.fs.s3a.threads.max", "64") \
    .config("spark.hadoop.fs.s3a.connection.maximum", "100") \
    .config("spark.sql.files.maxPartitionBytes", "134217728") \  # 128MB
    .getOrCreate()
```

### Step 5.2: Partitioning Strategy
```python
# Write with optimal partitioning
df.repartition(100) \
    .write \
    .mode("overwrite") \
    .partitionBy("year", "month", "day") \
    .parquet("s3a://bucket/data/")

# Coalesce for fewer output files
df.coalesce(10) \
    .write \
    .mode("overwrite") \
    .parquet("s3a://bucket/output/")
```

### Step 5.3: Predicate Pushdown
```python
# Filter early - Spark pushes predicates to Parquet
df = spark.read.parquet("s3a://bucket/data/") \
    .filter("date = '2024-01-15'") \
    .select("id", "value")

# Check pushdown in explain
df.explain()
```

---

## Part 6: Delta Lake on Cloud

### Step 6.1: Delta on S3
```python
from delta import configure_spark_with_delta_pip

builder = SparkSession.builder \
    .appName("Delta on S3") \
    .config("spark.jars.packages", "io.delta:delta-core_2.12:2.4.0,org.apache.hadoop:hadoop-aws:3.3.4") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .config("spark.hadoop.fs.s3a.access.key", "YOUR_KEY") \
    .config("spark.hadoop.fs.s3a.secret.key", "YOUR_SECRET")

spark = configure_spark_with_delta_pip(builder).getOrCreate()

# Write Delta to S3
df.write.format("delta") \
    .mode("overwrite") \
    .save("s3a://bucket/delta-tables/sales/")

# Read Delta from S3
df = spark.read.format("delta").load("s3a://bucket/delta-tables/sales/")
```

### Step 6.2: S3 Locking for Delta
```python
# For multi-cluster writes, use DynamoDB for locking
spark = SparkSession.builder \
    .appName("Delta with Lock") \
    .config("spark.delta.logStore.class", 
            "org.apache.spark.sql.delta.storage.S3SingleDriverLogStore") \
    .getOrCreate()
```

---

## Part 7: Handling Secrets

### Step 7.1: Using Secret Managers
```python
# AWS Secrets Manager
import boto3
import json

def get_aws_secret(secret_name, region="us-east-1"):
    client = boto3.client('secretsmanager', region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

secrets = get_aws_secret("my-spark-secrets")
access_key = secrets['aws_access_key']
secret_key = secrets['aws_secret_key']
```

### Step 7.2: Azure Key Vault
```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

def get_azure_secret(vault_url, secret_name):
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=vault_url, credential=credential)
    return client.get_secret(secret_name).value

storage_key = get_azure_secret(
    "https://my-vault.vault.azure.net/", 
    "storage-account-key"
)
```

---

## Part 8: Cross-Cloud Data Movement

```python
# Read from S3, write to Azure
df_s3 = spark.read.parquet("s3a://source-bucket/data/")

df_s3.write \
    .mode("overwrite") \
    .parquet("wasbs://container@account.blob.core.windows.net/data/")

# Read from GCS, write to S3
df_gcs = spark.read.parquet("gs://source-bucket/data/")

df_gcs.write \
    .mode("overwrite") \
    .parquet("s3a://target-bucket/data/")
```

---

## Part 9: Error Handling

```python
from pyspark.sql import SparkSession
from pyspark.sql.utils import AnalysisException

def safe_read_cloud(spark, path, format="parquet"):
    """Safely read from cloud storage with error handling"""
    try:
        df = spark.read.format(format).load(path)
        return df
    except AnalysisException as e:
        if "Path does not exist" in str(e):
            print(f"Warning: Path {path} not found, returning empty DataFrame")
            return spark.createDataFrame([], schema=None)
        raise
    except Exception as e:
        print(f"Error reading from {path}: {e}")
        raise

def safe_write_cloud(df, path, mode="overwrite", format="parquet"):
    """Safely write to cloud storage with retries"""
    import time
    max_retries = 3
    
    for attempt in range(max_retries):
        try:
            df.write.format(format).mode(mode).save(path)
            return True
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"Write failed, retrying in 10s... (attempt {attempt+1}/{max_retries})")
                time.sleep(10)
            else:
                raise
```

---

## Part 10: Complete Cloud ETL Example

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
import os

# Configuration
os.environ['AWS_ACCESS_KEY_ID'] = 'your_key'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'your_secret'

spark = SparkSession.builder \
    .appName("Cloud ETL Pipeline") \
    .config("spark.jars.packages", 
            "org.apache.hadoop:hadoop-aws:3.3.4,io.delta:delta-core_2.12:2.4.0") \
    .config("spark.hadoop.fs.s3a.aws.credentials.provider",
            "com.amazonaws.auth.EnvironmentVariableCredentialsProvider") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .getOrCreate()

# Extract from S3
raw_sales = spark.read \
    .option("header", True) \
    .option("inferSchema", True) \
    .csv("s3a://raw-bucket/sales/2024/01/")

raw_products = spark.read.json("s3a://raw-bucket/products/")

# Transform
enriched_sales = raw_sales \
    .join(raw_products, "product_id") \
    .withColumn("total_amount", col("quantity") * col("price")) \
    .withColumn("processed_at", current_timestamp()) \
    .withColumn("year", year("transaction_date")) \
    .withColumn("month", month("transaction_date"))

# Load to Delta Lake on S3
enriched_sales.write \
    .format("delta") \
    .mode("append") \
    .partitionBy("year", "month") \
    .save("s3a://processed-bucket/sales-delta/")

# Create aggregated table
daily_summary = enriched_sales \
    .groupBy("transaction_date", "product_category") \
    .agg(
        count("*").alias("transaction_count"),
        sum("total_amount").alias("total_revenue")
    )

daily_summary.write \
    .mode("overwrite") \
    .parquet("s3a://analytics-bucket/daily-sales-summary/")

print("ETL Pipeline completed successfully!")
```

---

## Exercises

1. Build an ETL pipeline reading from Azure and writing to S3
2. Implement Delta Lake with time travel on cloud storage
3. Create a streaming pipeline reading from S3
4. Optimize cloud storage reads with partition pruning

---

## Summary
- Configure credentials securely (IAM roles, managed identity)
- Use appropriate URI schemes (s3a://, wasbs://, gs://)
- Optimize with proper partitioning and file sizes
- Delta Lake works across cloud providers
- Handle secrets with cloud secret managers
- Implement retry logic for reliability
