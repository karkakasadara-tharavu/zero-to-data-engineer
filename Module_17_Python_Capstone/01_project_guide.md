# Python Data Engineering Capstone - Project Guide

## 📚 What You'll Build
- End-to-end data pipeline
- ETL with Python and PySpark
- Data quality framework
- Production-ready code
- Portfolio-ready project

**Duration**: 20+ hours  
**Difficulty**: ⭐⭐⭐⭐⭐ Advanced

---

## 🎯 Project Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CAPSTONE PROJECT ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        DATA SOURCES                              │   │
│   │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│   │   │   CSV    │  │   API    │  │   SQL    │  │  Parquet │       │   │
│   │   │  Files   │  │  Data    │  │ Database │  │  Files   │       │   │
│   │   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │   │
│   │        │             │             │             │              │   │
│   └────────┴─────────────┴─────────────┴─────────────┴──────────────┘   │
│                                   │                                      │
│                                   ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      INGESTION LAYER                             │   │
│   │             (Python/PySpark Extract Functions)                   │   │
│   └──────────────────────────┬──────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                     RAW / BRONZE LAYER                           │   │
│   │               (Raw data as-is, minimal processing)               │   │
│   └──────────────────────────┬──────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                   TRANSFORM / SILVER LAYER                       │   │
│   │        (Cleaned, validated, conformed, standardized)            │   │
│   └──────────────────────────┬──────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    CURATED / GOLD LAYER                          │   │
│   │          (Aggregated, business-ready, analytics-optimized)      │   │
│   └──────────────────────────┬──────────────────────────────────────┘   │
│                              │                                           │
│                              ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        CONSUMERS                                 │   │
│   │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│   │   │Dashboard │  │ Reports  │  │    ML    │  │   API    │       │   │
│   │   └──────────┘  └──────────┘  └──────────┘  └──────────┘       │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Project Options

### Option A: E-Commerce Sales Pipeline
Build a complete data pipeline for an e-commerce platform.

**Data Sources:**
- Orders (CSV files, daily dumps)
- Products (SQL database)
- Customers (API endpoint)
- Website events (JSON/Parquet)

**Requirements:**
1. Ingest data from multiple sources
2. Handle incremental loading
3. Apply data quality checks
4. Build star schema for analytics
5. Create aggregated views for reporting

### Option B: IoT Sensor Data Pipeline
Process streaming sensor data from manufacturing equipment.

**Data Sources:**
- Sensor readings (CSV/Parquet, high volume)
- Equipment metadata (SQL database)
- Maintenance logs (JSON files)

**Requirements:**
1. Handle high-volume data
2. Detect anomalies
3. Calculate rolling statistics
4. Build time-series aggregations
5. Generate alerts on thresholds

### Option C: Financial Data Pipeline
Build analytics pipeline for financial transactions.

**Data Sources:**
- Transactions (CSV, millions of rows)
- Accounts (SQL database)
- Exchange rates (API)
- Reference data (Excel files)

**Requirements:**
1. Currency conversion
2. Transaction categorization
3. Fraud detection rules
4. Daily/Monthly summaries
5. Customer analytics

---

## 🏗️ Project Structure

```
capstone_project/
├── config/
│   ├── config.yaml           # Configuration settings
│   ├── logging_config.yaml   # Logging configuration
│   └── secrets.env           # Environment variables (gitignored)
├── data/
│   ├── raw/                  # Raw input data
│   ├── bronze/               # Ingested raw data
│   ├── silver/               # Cleaned data
│   └── gold/                 # Aggregated data
├── src/
│   ├── __init__.py
│   ├── ingestion/
│   │   ├── __init__.py
│   │   ├── csv_ingestor.py
│   │   ├── api_ingestor.py
│   │   └── sql_ingestor.py
│   ├── transformation/
│   │   ├── __init__.py
│   │   ├── bronze_to_silver.py
│   │   ├── silver_to_gold.py
│   │   └── transformers.py
│   ├── validation/
│   │   ├── __init__.py
│   │   ├── schema_validator.py
│   │   └── data_quality.py
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── spark_utils.py
│   │   ├── logging_utils.py
│   │   └── config_utils.py
│   └── models/
│       ├── __init__.py
│       └── schemas.py
├── tests/
│   ├── test_ingestion.py
│   ├── test_transformation.py
│   └── test_validation.py
├── notebooks/
│   ├── exploration.ipynb
│   └── analysis.ipynb
├── pipelines/
│   ├── daily_etl.py
│   └── full_refresh.py
├── docs/
│   └── README.md
├── requirements.txt
├── setup.py
└── README.md
```

---

## 🔧 Implementation Steps

### Step 1: Project Setup

```python
# requirements.txt
pyspark==3.5.0
pandas>=2.0.0
numpy>=1.24.0
pyarrow>=12.0.0
pyyaml>=6.0
python-dotenv>=1.0.0
pytest>=7.0.0
great_expectations>=0.17.0
sqlalchemy>=2.0.0
pyodbc>=4.0.0
requests>=2.28.0
```

### Step 2: Configuration Management

```python
# src/utils/config_utils.py
import yaml
import os
from dotenv import load_dotenv

class Config:
    def __init__(self, config_path: str = 'config/config.yaml'):
        load_dotenv('config/secrets.env')
        with open(config_path) as f:
            self._config = yaml.safe_load(f)
    
    @property
    def spark_config(self) -> dict:
        return self._config.get('spark', {})
    
    @property
    def database_config(self) -> dict:
        config = self._config.get('database', {})
        config['password'] = os.getenv('DB_PASSWORD')
        return config
    
    @property
    def data_paths(self) -> dict:
        return self._config.get('paths', {})
```

```yaml
# config/config.yaml
spark:
  app_name: "CapstoneETL"
  master: "local[*]"
  config:
    spark.sql.shuffle.partitions: "50"
    spark.driver.memory: "4g"

database:
  host: "localhost"
  port: 1433
  database: "CapstoneDB"
  user: "etl_user"

paths:
  raw: "data/raw"
  bronze: "data/bronze"
  silver: "data/silver"
  gold: "data/gold"
```

### Step 3: Spark Session Factory

```python
# src/utils/spark_utils.py
from pyspark.sql import SparkSession
from .config_utils import Config

class SparkSessionFactory:
    _instance = None
    
    @classmethod
    def get_session(cls) -> SparkSession:
        if cls._instance is None:
            config = Config()
            builder = SparkSession.builder \
                .appName(config.spark_config.get('app_name', 'ETL')) \
                .master(config.spark_config.get('master', 'local[*]'))
            
            for key, value in config.spark_config.get('config', {}).items():
                builder = builder.config(key, value)
            
            cls._instance = builder.getOrCreate()
        
        return cls._instance
    
    @classmethod
    def stop_session(cls):
        if cls._instance:
            cls._instance.stop()
            cls._instance = None
```

### Step 4: Data Ingestion

```python
# src/ingestion/csv_ingestor.py
from pyspark.sql import DataFrame
from pyspark.sql.types import StructType
from ..utils.spark_utils import SparkSessionFactory
import logging

logger = logging.getLogger(__name__)

class CSVIngestor:
    def __init__(self, schema: StructType = None):
        self.spark = SparkSessionFactory.get_session()
        self.schema = schema
    
    def ingest(self, path: str, **options) -> DataFrame:
        """Ingest CSV files into DataFrame"""
        logger.info(f"Ingesting CSV from: {path}")
        
        reader = self.spark.read.format("csv") \
            .option("header", "true") \
            .option("inferSchema", self.schema is None)
        
        for key, value in options.items():
            reader = reader.option(key, value)
        
        if self.schema:
            reader = reader.schema(self.schema)
        
        df = reader.load(path)
        logger.info(f"Ingested {df.count()} rows")
        return df
    
    def ingest_incremental(self, path: str, watermark_col: str, 
                           last_watermark) -> DataFrame:
        """Ingest only new records based on watermark"""
        df = self.ingest(path)
        df = df.filter(df[watermark_col] > last_watermark)
        return df
```

### Step 5: Data Quality Framework

```python
# src/validation/data_quality.py
from pyspark.sql import DataFrame
from pyspark.sql.functions import col, count, when, isnan, isnull
from dataclasses import dataclass
from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

@dataclass
class QualityCheck:
    name: str
    passed: bool
    details: str

class DataQualityValidator:
    def __init__(self, df: DataFrame):
        self.df = df
        self.results: List[QualityCheck] = []
    
    def check_not_null(self, columns: List[str]) -> 'DataQualityValidator':
        """Check columns have no null values"""
        for column in columns:
            null_count = self.df.filter(col(column).isNull()).count()
            passed = null_count == 0
            self.results.append(QualityCheck(
                name=f"not_null_{column}",
                passed=passed,
                details=f"{null_count} null values in {column}"
            ))
        return self
    
    def check_unique(self, columns: List[str]) -> 'DataQualityValidator':
        """Check columns have unique values"""
        col_str = ", ".join(columns)
        total = self.df.count()
        distinct = self.df.select(columns).distinct().count()
        passed = total == distinct
        self.results.append(QualityCheck(
            name=f"unique_{col_str}",
            passed=passed,
            details=f"{total - distinct} duplicate rows"
        ))
        return self
    
    def check_range(self, column: str, min_val=None, max_val=None) -> 'DataQualityValidator':
        """Check values are within range"""
        violations = 0
        if min_val is not None:
            violations += self.df.filter(col(column) < min_val).count()
        if max_val is not None:
            violations += self.df.filter(col(column) > max_val).count()
        
        passed = violations == 0
        self.results.append(QualityCheck(
            name=f"range_{column}",
            passed=passed,
            details=f"{violations} values out of range [{min_val}, {max_val}]"
        ))
        return self
    
    def check_referential_integrity(self, column: str, 
                                     reference_df: DataFrame, 
                                     reference_column: str) -> 'DataQualityValidator':
        """Check foreign key references exist"""
        orphans = self.df.join(
            reference_df.select(col(reference_column).alias("_ref")),
            self.df[column] == col("_ref"),
            "left_anti"
        ).count()
        
        passed = orphans == 0
        self.results.append(QualityCheck(
            name=f"referential_{column}",
            passed=passed,
            details=f"{orphans} orphan records"
        ))
        return self
    
    def get_report(self) -> Dict:
        """Generate quality report"""
        failed = [r for r in self.results if not r.passed]
        return {
            "total_checks": len(self.results),
            "passed": len(self.results) - len(failed),
            "failed": len(failed),
            "all_passed": len(failed) == 0,
            "failed_checks": [{"name": r.name, "details": r.details} for r in failed]
        }
    
    def validate(self, fail_on_error: bool = True) -> DataFrame:
        """Return DataFrame if all checks pass"""
        report = self.get_report()
        if not report["all_passed"]:
            logger.error(f"Data quality check failed: {report['failed_checks']}")
            if fail_on_error:
                raise ValueError(f"Data quality validation failed: {report['failed_checks']}")
        return self.df
```

### Step 6: Transformation Pipeline

```python
# src/transformation/bronze_to_silver.py
from pyspark.sql import DataFrame
from pyspark.sql.functions import (
    col, trim, lower, to_timestamp, when, lit, current_timestamp
)
from ..validation.data_quality import DataQualityValidator
import logging

logger = logging.getLogger(__name__)

class BronzeToSilverTransformer:
    """Transform raw data to cleaned silver layer"""
    
    def __init__(self, df: DataFrame):
        self.df = df
    
    def clean_strings(self, columns: list) -> 'BronzeToSilverTransformer':
        """Trim and lowercase string columns"""
        for column in columns:
            self.df = self.df.withColumn(column, trim(lower(col(column))))
        return self
    
    def parse_dates(self, column: str, format: str) -> 'BronzeToSilverTransformer':
        """Parse date columns"""
        self.df = self.df.withColumn(
            column, 
            to_timestamp(col(column), format)
        )
        return self
    
    def fill_nulls(self, defaults: dict) -> 'BronzeToSilverTransformer':
        """Fill null values with defaults"""
        for column, value in defaults.items():
            self.df = self.df.fillna({column: value})
        return self
    
    def add_metadata(self) -> 'BronzeToSilverTransformer':
        """Add processing metadata"""
        self.df = self.df.withColumn("_processed_at", current_timestamp())
        return self
    
    def validate(self, required_columns: list) -> 'BronzeToSilverTransformer':
        """Run data quality checks"""
        validator = DataQualityValidator(self.df)
        validator.check_not_null(required_columns)
        self.df = validator.validate()
        return self
    
    def get_result(self) -> DataFrame:
        return self.df
```

### Step 7: Main Pipeline

```python
# pipelines/daily_etl.py
from src.ingestion.csv_ingestor import CSVIngestor
from src.transformation.bronze_to_silver import BronzeToSilverTransformer
from src.utils.spark_utils import SparkSessionFactory
from src.utils.config_utils import Config
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def run_daily_etl():
    """Run daily ETL pipeline"""
    logger.info("Starting daily ETL pipeline")
    start_time = datetime.now()
    
    config = Config()
    spark = SparkSessionFactory.get_session()
    
    try:
        # Bronze Layer - Ingest raw data
        logger.info("=== BRONZE LAYER ===")
        orders_ingestor = CSVIngestor()
        orders_raw = orders_ingestor.ingest(f"{config.data_paths['raw']}/orders/*.csv")
        orders_raw.write.mode("overwrite").parquet(f"{config.data_paths['bronze']}/orders")
        
        # Silver Layer - Clean and validate
        logger.info("=== SILVER LAYER ===")
        orders_bronze = spark.read.parquet(f"{config.data_paths['bronze']}/orders")
        
        orders_silver = (BronzeToSilverTransformer(orders_bronze)
            .clean_strings(['customer_name', 'product_name'])
            .parse_dates('order_date', 'yyyy-MM-dd')
            .fill_nulls({'quantity': 0, 'discount': 0.0})
            .add_metadata()
            .validate(['order_id', 'customer_id', 'product_id'])
            .get_result()
        )
        
        orders_silver.write.mode("overwrite").parquet(f"{config.data_paths['silver']}/orders")
        
        # Gold Layer - Aggregate
        logger.info("=== GOLD LAYER ===")
        orders_silver = spark.read.parquet(f"{config.data_paths['silver']}/orders")
        
        daily_summary = orders_silver.groupBy("order_date").agg(
            {"amount": "sum", "order_id": "count"}
        ).withColumnRenamed("sum(amount)", "total_revenue") \
         .withColumnRenamed("count(order_id)", "order_count")
        
        daily_summary.write.mode("overwrite").parquet(f"{config.data_paths['gold']}/daily_summary")
        
        duration = datetime.now() - start_time
        logger.info(f"Pipeline completed successfully in {duration}")
        
    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        raise
    finally:
        SparkSessionFactory.stop_session()

if __name__ == "__main__":
    run_daily_etl()
```

---

## ✅ Project Checklist

### Core Requirements
- [ ] Multi-source data ingestion
- [ ] Incremental loading capability
- [ ] Data quality validation
- [ ] Bronze/Silver/Gold layer architecture
- [ ] Error handling and logging
- [ ] Configuration management
- [ ] Unit tests

### Advanced Features
- [ ] Schema evolution handling
- [ ] SCD Type 2 implementation
- [ ] Partitioning strategy
- [ ] Performance optimization
- [ ] Monitoring/alerting
- [ ] Data lineage tracking
- [ ] CI/CD pipeline

### Documentation
- [ ] README with setup instructions
- [ ] Architecture diagram
- [ ] Data dictionary
- [ ] API documentation
- [ ] Runbook for operations

---

## 🎓 Interview Preparation

### Architecture Questions
- Explain your medallion architecture
- How do you handle incremental loads?
- Describe your data quality framework
- How do you handle schema changes?

### Code Questions
- Walk through your transformation code
- How do you optimize Spark performance?
- Explain your testing strategy
- How do you handle errors?

### Design Decisions
- Why did you choose this architecture?
- How would you scale this solution?
- What would you do differently?
- How do you ensure data quality?

---

## 🔗 Related Topics
- [← Advanced PySpark](../Module_16_Advanced_PySpark/)
- [SQL Capstone →](../Module_09_SQL_Capstone/)
- [Portfolio Guide →](#)

---

*Capstone Project Complete! Build Your Portfolio*
