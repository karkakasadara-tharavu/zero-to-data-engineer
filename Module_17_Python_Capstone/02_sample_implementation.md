# Capstone Project - Sample Implementation

## 📚 Complete E-Commerce Pipeline Example

This document provides a complete working example of the capstone project with sample data and implementations.

---

## 🎯 Sample Data Generation

### Generate Sample Data

```python
# scripts/generate_sample_data.py
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

np.random.seed(42)

# Create directories
os.makedirs('data/raw/orders', exist_ok=True)
os.makedirs('data/raw/products', exist_ok=True)
os.makedirs('data/raw/customers', exist_ok=True)

# Generate Products
products = pd.DataFrame({
    'product_id': range(1, 101),
    'product_name': [f'Product_{i}' for i in range(1, 101)],
    'category': np.random.choice(['Electronics', 'Clothing', 'Home', 'Sports', 'Books'], 100),
    'unit_price': np.round(np.random.uniform(10, 500, 100), 2),
    'supplier_id': np.random.randint(1, 21, 100)
})
products.to_csv('data/raw/products/products.csv', index=False)

# Generate Customers
customers = pd.DataFrame({
    'customer_id': range(1, 1001),
    'customer_name': [f'Customer_{i}' for i in range(1, 1001)],
    'email': [f'customer{i}@email.com' for i in range(1, 1001)],
    'city': np.random.choice(['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'], 1000),
    'state': np.random.choice(['NY', 'CA', 'IL', 'TX', 'AZ'], 1000),
    'signup_date': pd.date_range(start='2020-01-01', periods=1000, freq='D')[:1000]
})
customers.to_csv('data/raw/customers/customers.csv', index=False)

# Generate Orders (multiple daily files)
base_date = datetime(2024, 1, 1)
for day in range(30):
    date = base_date + timedelta(days=day)
    num_orders = np.random.randint(50, 200)
    
    orders = pd.DataFrame({
        'order_id': range(day * 200 + 1, day * 200 + num_orders + 1),
        'customer_id': np.random.randint(1, 1001, num_orders),
        'product_id': np.random.randint(1, 101, num_orders),
        'quantity': np.random.randint(1, 10, num_orders),
        'order_date': date.strftime('%Y-%m-%d'),
        'discount': np.round(np.random.choice([0, 0.05, 0.1, 0.15, 0.2], num_orders), 2),
        'status': np.random.choice(['completed', 'pending', 'cancelled'], num_orders, p=[0.8, 0.15, 0.05])
    })
    orders.to_csv(f'data/raw/orders/orders_{date.strftime("%Y%m%d")}.csv', index=False)

print("Sample data generated successfully!")
```

---

## 📦 Schema Definitions

```python
# src/models/schemas.py
from pyspark.sql.types import (
    StructType, StructField, StringType, IntegerType, 
    DoubleType, DateType, TimestampType
)

# Order Schema
ORDER_SCHEMA = StructType([
    StructField("order_id", IntegerType(), False),
    StructField("customer_id", IntegerType(), False),
    StructField("product_id", IntegerType(), False),
    StructField("quantity", IntegerType(), True),
    StructField("order_date", StringType(), True),
    StructField("discount", DoubleType(), True),
    StructField("status", StringType(), True)
])

# Product Schema
PRODUCT_SCHEMA = StructType([
    StructField("product_id", IntegerType(), False),
    StructField("product_name", StringType(), True),
    StructField("category", StringType(), True),
    StructField("unit_price", DoubleType(), True),
    StructField("supplier_id", IntegerType(), True)
])

# Customer Schema
CUSTOMER_SCHEMA = StructType([
    StructField("customer_id", IntegerType(), False),
    StructField("customer_name", StringType(), True),
    StructField("email", StringType(), True),
    StructField("city", StringType(), True),
    StructField("state", StringType(), True),
    StructField("signup_date", StringType(), True)
])

# Silver Layer Schemas (after transformation)
SILVER_ORDER_SCHEMA = StructType([
    StructField("order_id", IntegerType(), False),
    StructField("customer_id", IntegerType(), False),
    StructField("product_id", IntegerType(), False),
    StructField("quantity", IntegerType(), False),
    StructField("order_date", DateType(), False),
    StructField("discount", DoubleType(), False),
    StructField("status", StringType(), False),
    StructField("_processed_at", TimestampType(), False)
])
```

---

## 🔧 Complete Ingestion Layer

```python
# src/ingestion/ingestor.py
from abc import ABC, abstractmethod
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.types import StructType
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class BaseIngestor(ABC):
    """Abstract base class for data ingestors"""
    
    def __init__(self, spark: SparkSession, schema: Optional[StructType] = None):
        self.spark = spark
        self.schema = schema
    
    @abstractmethod
    def ingest(self, source: str, **options) -> DataFrame:
        pass
    
    def validate_schema(self, df: DataFrame) -> DataFrame:
        """Validate DataFrame against expected schema"""
        if self.schema:
            expected_cols = set(f.name for f in self.schema.fields)
            actual_cols = set(df.columns)
            
            missing = expected_cols - actual_cols
            if missing:
                raise ValueError(f"Missing columns: {missing}")
        return df


class CSVIngestor(BaseIngestor):
    """Ingest CSV files"""
    
    def ingest(self, source: str, **options) -> DataFrame:
        logger.info(f"Ingesting CSV from: {source}")
        
        default_options = {
            "header": "true",
            "inferSchema": str(self.schema is None).lower()
        }
        default_options.update(options)
        
        reader = self.spark.read.format("csv")
        for key, value in default_options.items():
            reader = reader.option(key, value)
        
        if self.schema:
            reader = reader.schema(self.schema)
        
        df = reader.load(source)
        return self.validate_schema(df)


class ParquetIngestor(BaseIngestor):
    """Ingest Parquet files"""
    
    def ingest(self, source: str, **options) -> DataFrame:
        logger.info(f"Ingesting Parquet from: {source}")
        df = self.spark.read.parquet(source)
        return self.validate_schema(df)


class JDBCIngestor(BaseIngestor):
    """Ingest from JDBC database"""
    
    def __init__(self, spark: SparkSession, jdbc_url: str, 
                 user: str, password: str, schema: Optional[StructType] = None):
        super().__init__(spark, schema)
        self.jdbc_url = jdbc_url
        self.user = user
        self.password = password
    
    def ingest(self, source: str, **options) -> DataFrame:
        """source is table name or SQL query"""
        logger.info(f"Ingesting from JDBC: {source}")
        
        df = self.spark.read \
            .format("jdbc") \
            .option("url", self.jdbc_url) \
            .option("user", self.user) \
            .option("password", self.password) \
            .option("dbtable", source) \
            .load()
        
        return self.validate_schema(df)
```

---

## 🔄 Complete Transformation Layer

```python
# src/transformation/transformers.py
from pyspark.sql import DataFrame
from pyspark.sql.functions import (
    col, trim, lower, upper, to_date, to_timestamp,
    when, lit, current_timestamp, coalesce, regexp_replace,
    year, month, dayofmonth, quarter
)
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)

class DataTransformer:
    """Chainable data transformer"""
    
    def __init__(self, df: DataFrame):
        self.df = df
    
    # String Operations
    def trim_columns(self, columns: List[str]) -> 'DataTransformer':
        for col_name in columns:
            if col_name in self.df.columns:
                self.df = self.df.withColumn(col_name, trim(col(col_name)))
        return self
    
    def lowercase_columns(self, columns: List[str]) -> 'DataTransformer':
        for col_name in columns:
            if col_name in self.df.columns:
                self.df = self.df.withColumn(col_name, lower(col(col_name)))
        return self
    
    def uppercase_columns(self, columns: List[str]) -> 'DataTransformer':
        for col_name in columns:
            if col_name in self.df.columns:
                self.df = self.df.withColumn(col_name, upper(col(col_name)))
        return self
    
    # Date Operations
    def parse_dates(self, columns: Dict[str, str]) -> 'DataTransformer':
        """Parse string columns to date with specified formats"""
        for col_name, date_format in columns.items():
            if col_name in self.df.columns:
                self.df = self.df.withColumn(col_name, to_date(col(col_name), date_format))
        return self
    
    def add_date_parts(self, date_column: str, prefix: str = "") -> 'DataTransformer':
        """Extract year, month, day, quarter from date column"""
        prefix = prefix or date_column
        self.df = (self.df
            .withColumn(f"{prefix}_year", year(col(date_column)))
            .withColumn(f"{prefix}_month", month(col(date_column)))
            .withColumn(f"{prefix}_day", dayofmonth(col(date_column)))
            .withColumn(f"{prefix}_quarter", quarter(col(date_column)))
        )
        return self
    
    # Null Handling
    def fill_nulls(self, defaults: Dict[str, any]) -> 'DataTransformer':
        self.df = self.df.fillna(defaults)
        return self
    
    def coalesce_columns(self, new_column: str, columns: List[str]) -> 'DataTransformer':
        self.df = self.df.withColumn(new_column, coalesce(*[col(c) for c in columns]))
        return self
    
    # Type Casting
    def cast_columns(self, type_map: Dict[str, str]) -> 'DataTransformer':
        for col_name, data_type in type_map.items():
            if col_name in self.df.columns:
                self.df = self.df.withColumn(col_name, col(col_name).cast(data_type))
        return self
    
    # Calculated Columns
    def add_calculated_column(self, name: str, expression) -> 'DataTransformer':
        self.df = self.df.withColumn(name, expression)
        return self
    
    # Metadata
    def add_processing_timestamp(self, column_name: str = "_processed_at") -> 'DataTransformer':
        self.df = self.df.withColumn(column_name, current_timestamp())
        return self
    
    def add_source_file(self, column_name: str = "_source_file") -> 'DataTransformer':
        from pyspark.sql.functions import input_file_name
        self.df = self.df.withColumn(column_name, input_file_name())
        return self
    
    # Filtering
    def filter_rows(self, condition) -> 'DataTransformer':
        self.df = self.df.filter(condition)
        return self
    
    def drop_duplicates(self, subset: Optional[List[str]] = None) -> 'DataTransformer':
        if subset:
            self.df = self.df.dropDuplicates(subset)
        else:
            self.df = self.df.dropDuplicates()
        return self
    
    # Column Operations
    def rename_columns(self, mapping: Dict[str, str]) -> 'DataTransformer':
        for old_name, new_name in mapping.items():
            if old_name in self.df.columns:
                self.df = self.df.withColumnRenamed(old_name, new_name)
        return self
    
    def select_columns(self, columns: List[str]) -> 'DataTransformer':
        self.df = self.df.select(columns)
        return self
    
    def drop_columns(self, columns: List[str]) -> 'DataTransformer':
        self.df = self.df.drop(*columns)
        return self
    
    # Result
    def get_result(self) -> DataFrame:
        return self.df
```

---

## 📊 Complete Gold Layer Aggregations

```python
# src/transformation/gold_aggregations.py
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import (
    sum, count, avg, min, max, countDistinct,
    col, when, lit, round as spark_round,
    dense_rank, row_number
)
from pyspark.sql.window import Window
import logging

logger = logging.getLogger(__name__)

class GoldLayerBuilder:
    """Build gold layer aggregations"""
    
    def __init__(self, spark: SparkSession, silver_path: str):
        self.spark = spark
        self.silver_path = silver_path
    
    def build_daily_sales_summary(self) -> DataFrame:
        """Daily sales aggregation"""
        orders = self.spark.read.parquet(f"{self.silver_path}/orders")
        products = self.spark.read.parquet(f"{self.silver_path}/products")
        
        # Join orders with products
        enriched = orders.join(products, "product_id")
        
        # Calculate line total
        enriched = enriched.withColumn(
            "line_total",
            col("quantity") * col("unit_price") * (1 - col("discount"))
        )
        
        # Aggregate by date
        daily_summary = enriched.groupBy("order_date").agg(
            count("order_id").alias("total_orders"),
            countDistinct("customer_id").alias("unique_customers"),
            sum("quantity").alias("total_units"),
            spark_round(sum("line_total"), 2).alias("total_revenue"),
            spark_round(avg("line_total"), 2).alias("avg_order_value")
        ).orderBy("order_date")
        
        return daily_summary
    
    def build_product_performance(self) -> DataFrame:
        """Product-level performance metrics"""
        orders = self.spark.read.parquet(f"{self.silver_path}/orders")
        products = self.spark.read.parquet(f"{self.silver_path}/products")
        
        enriched = orders.join(products, "product_id")
        enriched = enriched.withColumn(
            "line_total",
            col("quantity") * col("unit_price") * (1 - col("discount"))
        )
        
        product_summary = enriched.groupBy(
            "product_id", "product_name", "category"
        ).agg(
            count("order_id").alias("order_count"),
            sum("quantity").alias("units_sold"),
            spark_round(sum("line_total"), 2).alias("revenue"),
            countDistinct("customer_id").alias("unique_customers")
        )
        
        # Add ranking within category
        window = Window.partitionBy("category").orderBy(col("revenue").desc())
        product_summary = product_summary.withColumn(
            "category_rank", dense_rank().over(window)
        )
        
        return product_summary
    
    def build_customer_analytics(self) -> DataFrame:
        """Customer-level analytics"""
        orders = self.spark.read.parquet(f"{self.silver_path}/orders")
        products = self.spark.read.parquet(f"{self.silver_path}/products")
        customers = self.spark.read.parquet(f"{self.silver_path}/customers")
        
        enriched = orders.join(products, "product_id").join(customers, "customer_id")
        enriched = enriched.withColumn(
            "line_total",
            col("quantity") * col("unit_price") * (1 - col("discount"))
        )
        
        customer_summary = enriched.groupBy(
            "customer_id", "customer_name", "city", "state"
        ).agg(
            count("order_id").alias("total_orders"),
            spark_round(sum("line_total"), 2).alias("lifetime_value"),
            min("order_date").alias("first_order"),
            max("order_date").alias("last_order"),
            countDistinct("product_id").alias("unique_products")
        )
        
        # Add customer tier
        customer_summary = customer_summary.withColumn(
            "customer_tier",
            when(col("lifetime_value") >= 5000, "Platinum")
            .when(col("lifetime_value") >= 2000, "Gold")
            .when(col("lifetime_value") >= 500, "Silver")
            .otherwise("Bronze")
        )
        
        return customer_summary
    
    def build_all(self, gold_path: str):
        """Build all gold tables"""
        logger.info("Building gold layer aggregations...")
        
        self.build_daily_sales_summary().write.mode("overwrite") \
            .parquet(f"{gold_path}/daily_sales")
        logger.info("Built daily_sales")
        
        self.build_product_performance().write.mode("overwrite") \
            .parquet(f"{gold_path}/product_performance")
        logger.info("Built product_performance")
        
        self.build_customer_analytics().write.mode("overwrite") \
            .parquet(f"{gold_path}/customer_analytics")
        logger.info("Built customer_analytics")
        
        logger.info("Gold layer complete!")
```

---

## 🧪 Unit Tests

```python
# tests/test_transformation.py
import pytest
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, IntegerType
from src.transformation.transformers import DataTransformer

@pytest.fixture(scope="session")
def spark():
    return SparkSession.builder \
        .master("local[*]") \
        .appName("Tests") \
        .getOrCreate()

@pytest.fixture
def sample_df(spark):
    data = [
        (1, "  JOHN DOE  ", "2024-01-15", 100),
        (2, "  jane smith  ", "2024-01-16", 200),
        (3, "BOB WILSON", "2024-01-17", None)
    ]
    schema = StructType([
        StructField("id", IntegerType()),
        StructField("name", StringType()),
        StructField("date", StringType()),
        StructField("amount", IntegerType())
    ])
    return spark.createDataFrame(data, schema)

def test_trim_columns(sample_df):
    result = DataTransformer(sample_df) \
        .trim_columns(["name"]) \
        .get_result()
    
    names = [row.name for row in result.collect()]
    assert names[0] == "JOHN DOE"
    assert names[1] == "jane smith"

def test_lowercase_columns(sample_df):
    result = DataTransformer(sample_df) \
        .trim_columns(["name"]) \
        .lowercase_columns(["name"]) \
        .get_result()
    
    names = [row.name for row in result.collect()]
    assert names[0] == "john doe"
    assert names[2] == "bob wilson"

def test_fill_nulls(sample_df):
    result = DataTransformer(sample_df) \
        .fill_nulls({"amount": 0}) \
        .get_result()
    
    amounts = [row.amount for row in result.collect()]
    assert amounts[2] == 0

def test_parse_dates(sample_df):
    result = DataTransformer(sample_df) \
        .parse_dates({"date": "yyyy-MM-dd"}) \
        .get_result()
    
    assert str(result.schema["date"].dataType) == "DateType()"
```

---

## 🚀 Running the Pipeline

```bash
# 1. Generate sample data
python scripts/generate_sample_data.py

# 2. Run the ETL pipeline
python pipelines/daily_etl.py

# 3. Run tests
pytest tests/ -v

# 4. Check outputs
python -c "
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()

print('=== BRONZE LAYER ===')
spark.read.parquet('data/bronze/orders').show(5)

print('=== SILVER LAYER ===')
spark.read.parquet('data/silver/orders').show(5)

print('=== GOLD LAYER ===')
spark.read.parquet('data/gold/daily_sales').show()
spark.read.parquet('data/gold/customer_analytics').show(5)
"
```

---

## 🔗 Related Topics
- [← Project Guide](./01_project_guide.md)
- [SQL Capstone →](../Module_09_SQL_Capstone/)
- [Career Roadmap →](../Module_00_Curriculum_Overview/04_career_roadmap.md)

---

*Capstone Complete! Your Portfolio is Ready*
