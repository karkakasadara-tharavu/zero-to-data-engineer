# Lab 05: ETL Pipelines with PySpark

## Overview
Build production-grade ETL pipelines using PySpark best practices.

**Duration**: 4 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Design modular ETL pipelines
- ✅ Implement extract, transform, load stages
- ✅ Handle data quality and validation
- ✅ Apply error handling patterns
- ✅ Build reusable pipeline components

---

## Part 1: ETL Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ETL Pipeline Architecture                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────┐    ┌─────────────┐    ┌─────────────┐    ┌──────────┐   │
│   │  SOURCE  │───▶│   EXTRACT   │───▶│  TRANSFORM  │───▶│   LOAD   │   │
│   │ (Files,  │    │ (Read data, │    │ (Clean,     │    │ (Write   │   │
│   │  DBs,    │    │  validate   │    │  enrich,    │    │  to DW,  │   │
│   │  APIs)   │    │  schema)    │    │  aggregate) │    │  Lake)   │   │
│   └──────────┘    └─────────────┘    └─────────────┘    └──────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    Data Quality + Monitoring                    │   │
│   └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Project Structure

```
etl_project/
├── config/
│   ├── __init__.py
│   ├── settings.py
│   └── schemas.py
├── src/
│   ├── __init__.py
│   ├── extractors/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── csv_extractor.py
│   │   └── database_extractor.py
│   ├── transformers/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── cleaner.py
│   │   └── enricher.py
│   ├── loaders/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── parquet_loader.py
│   │   └── delta_loader.py
│   └── utils/
│       ├── __init__.py
│       ├── logger.py
│       └── data_quality.py
├── jobs/
│   ├── daily_sales_etl.py
│   └── customer_dim_etl.py
└── tests/
    └── test_transformers.py
```

---

## Part 3: Configuration Management

### Step 3.1: Settings Module
```python
# config/settings.py
from dataclasses import dataclass
from typing import Dict, Any
import os

@dataclass
class SparkConfig:
    app_name: str
    master: str = "local[*]"
    shuffle_partitions: int = 8
    driver_memory: str = "4g"
    
    def to_dict(self) -> Dict[str, str]:
        return {
            "spark.sql.shuffle.partitions": str(self.shuffle_partitions),
            "spark.driver.memory": self.driver_memory,
        }

@dataclass
class PathConfig:
    raw_data: str = "data/raw"
    processed_data: str = "data/processed"
    staging_data: str = "data/staging"
    checkpoint: str = "data/checkpoint"

class Settings:
    def __init__(self, env: str = "development"):
        self.env = env
        self.spark = SparkConfig(app_name=f"ETL-{env}")
        self.paths = PathConfig()
        
    @classmethod
    def from_env(cls):
        env = os.getenv("ETL_ENV", "development")
        return cls(env)
```

### Step 3.2: Schema Definitions
```python
# config/schemas.py
from pyspark.sql.types import *

class Schemas:
    SALES = StructType([
        StructField("transaction_id", StringType(), False),
        StructField("customer_id", IntegerType(), False),
        StructField("product_id", IntegerType(), False),
        StructField("quantity", IntegerType(), False),
        StructField("unit_price", DoubleType(), False),
        StructField("transaction_date", DateType(), False),
        StructField("store_id", IntegerType(), True),
    ])
    
    CUSTOMER = StructType([
        StructField("customer_id", IntegerType(), False),
        StructField("first_name", StringType(), False),
        StructField("last_name", StringType(), False),
        StructField("email", StringType(), True),
        StructField("created_date", DateType(), False),
    ])
    
    PRODUCT = StructType([
        StructField("product_id", IntegerType(), False),
        StructField("product_name", StringType(), False),
        StructField("category", StringType(), False),
        StructField("price", DoubleType(), False),
    ])
```

---

## Part 4: Base Classes

### Step 4.1: Base Extractor
```python
# src/extractors/base.py
from abc import ABC, abstractmethod
from pyspark.sql import SparkSession, DataFrame
from typing import Optional
from pyspark.sql.types import StructType

class BaseExtractor(ABC):
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.logger = self._get_logger()
    
    def _get_logger(self):
        import logging
        return logging.getLogger(self.__class__.__name__)
    
    @abstractmethod
    def extract(self, source: str, schema: Optional[StructType] = None) -> DataFrame:
        pass
    
    def validate_source(self, source: str) -> bool:
        """Validate source exists"""
        try:
            # Implementation depends on source type
            return True
        except Exception:
            return False
```

### Step 4.2: Base Transformer
```python
# src/transformers/base.py
from abc import ABC, abstractmethod
from pyspark.sql import DataFrame
from typing import Dict, Any

class BaseTransformer(ABC):
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
    
    @abstractmethod
    def transform(self, df: DataFrame) -> DataFrame:
        pass
    
    def validate_input(self, df: DataFrame) -> bool:
        """Validate input DataFrame"""
        if df is None or df.rdd.isEmpty():
            raise ValueError("Input DataFrame is empty")
        return True
```

### Step 4.3: Base Loader
```python
# src/loaders/base.py
from abc import ABC, abstractmethod
from pyspark.sql import DataFrame
from typing import List, Optional

class BaseLoader(ABC):
    def __init__(self, mode: str = "overwrite"):
        self.mode = mode
    
    @abstractmethod
    def load(self, df: DataFrame, target: str, partition_cols: Optional[List[str]] = None):
        pass
    
    def validate_target(self, target: str) -> bool:
        """Validate target location"""
        return True
```

---

## Part 5: Extractors

### Step 5.1: CSV Extractor
```python
# src/extractors/csv_extractor.py
from .base import BaseExtractor
from pyspark.sql import DataFrame
from pyspark.sql.types import StructType
from typing import Optional, Dict, Any

class CSVExtractor(BaseExtractor):
    def __init__(self, spark, options: Dict[str, Any] = None):
        super().__init__(spark)
        self.default_options = {
            "header": "true",
            "inferSchema": "false",
            "mode": "PERMISSIVE",
            "columnNameOfCorruptRecord": "_corrupt_record"
        }
        if options:
            self.default_options.update(options)
    
    def extract(self, source: str, schema: Optional[StructType] = None) -> DataFrame:
        self.logger.info(f"Extracting CSV from: {source}")
        
        reader = self.spark.read
        
        for key, value in self.default_options.items():
            reader = reader.option(key, value)
        
        if schema:
            reader = reader.schema(schema)
        
        df = reader.csv(source)
        
        self.logger.info(f"Extracted {df.count()} rows")
        return df
```

### Step 5.2: Database Extractor
```python
# src/extractors/database_extractor.py
from .base import BaseExtractor
from pyspark.sql import DataFrame
from typing import Dict, Optional

class DatabaseExtractor(BaseExtractor):
    def __init__(self, spark, jdbc_url: str, properties: Dict[str, str]):
        super().__init__(spark)
        self.jdbc_url = jdbc_url
        self.properties = properties
    
    def extract(self, source: str, schema = None) -> DataFrame:
        """Extract from database table"""
        self.logger.info(f"Extracting from table: {source}")
        
        df = self.spark.read.jdbc(
            url=self.jdbc_url,
            table=source,
            properties=self.properties
        )
        
        return df
    
    def extract_query(self, query: str) -> DataFrame:
        """Extract using SQL query"""
        self.logger.info(f"Executing query: {query[:100]}...")
        
        df = self.spark.read.jdbc(
            url=self.jdbc_url,
            table=f"({query}) as subquery",
            properties=self.properties
        )
        
        return df
```

---

## Part 6: Transformers

### Step 6.1: Data Cleaner
```python
# src/transformers/cleaner.py
from .base import BaseTransformer
from pyspark.sql import DataFrame
from pyspark.sql.functions import *
from typing import List, Dict

class DataCleaner(BaseTransformer):
    def __init__(self, config: Dict = None):
        super().__init__(config)
        self.null_handling = config.get("null_handling", "drop")
        self.dedup_cols = config.get("dedup_columns", None)
    
    def transform(self, df: DataFrame) -> DataFrame:
        self.validate_input(df)
        
        # Remove duplicates
        if self.dedup_cols:
            df = df.dropDuplicates(self.dedup_cols)
        
        # Handle nulls
        if self.null_handling == "drop":
            df = df.dropna()
        elif isinstance(self.null_handling, dict):
            df = df.fillna(self.null_handling)
        
        # Trim string columns
        for field in df.schema.fields:
            if field.dataType.simpleString() == "string":
                df = df.withColumn(field.name, trim(col(field.name)))
        
        return df
    
    def remove_corrupt_records(self, df: DataFrame, corrupt_col: str = "_corrupt_record") -> DataFrame:
        """Remove records that failed parsing"""
        if corrupt_col in df.columns:
            df = df.filter(col(corrupt_col).isNull()).drop(corrupt_col)
        return df
```

### Step 6.2: Data Enricher
```python
# src/transformers/enricher.py
from .base import BaseTransformer
from pyspark.sql import DataFrame
from pyspark.sql.functions import *
from typing import Dict

class DataEnricher(BaseTransformer):
    def __init__(self, config: Dict = None):
        super().__init__(config)
    
    def transform(self, df: DataFrame) -> DataFrame:
        self.validate_input(df)
        return df
    
    def add_audit_columns(self, df: DataFrame) -> DataFrame:
        """Add standard audit columns"""
        return df \
            .withColumn("etl_timestamp", current_timestamp()) \
            .withColumn("etl_date", current_date()) \
            .withColumn("etl_source", lit(self.config.get("source_name", "unknown")))
    
    def add_derived_columns(self, df: DataFrame, derivations: Dict[str, str]) -> DataFrame:
        """Add derived columns using expressions"""
        for col_name, expression in derivations.items():
            df = df.withColumn(col_name, expr(expression))
        return df
    
    def join_dimension(self, fact_df: DataFrame, dim_df: DataFrame, 
                       key: str, select_cols: List[str]) -> DataFrame:
        """Enrich fact table with dimension attributes"""
        from pyspark.sql.functions import broadcast
        
        dim_selected = dim_df.select(key, *select_cols)
        return fact_df.join(broadcast(dim_selected), key, "left")
```

### Step 6.3: Sales Transformer (Domain Specific)
```python
# src/transformers/sales_transformer.py
from .base import BaseTransformer
from pyspark.sql import DataFrame
from pyspark.sql.functions import *
from pyspark.sql.window import Window

class SalesTransformer(BaseTransformer):
    def transform(self, df: DataFrame) -> DataFrame:
        self.validate_input(df)
        
        # Calculate total amount
        df = df.withColumn("total_amount", col("quantity") * col("unit_price"))
        
        # Add date parts
        df = df.withColumn("year", year("transaction_date"))
        df = df.withColumn("month", month("transaction_date"))
        df = df.withColumn("day_of_week", dayofweek("transaction_date"))
        
        # Add running totals per customer
        customer_window = Window.partitionBy("customer_id") \
            .orderBy("transaction_date") \
            .rowsBetween(Window.unboundedPreceding, Window.currentRow)
        
        df = df.withColumn(
            "customer_running_total",
            sum("total_amount").over(customer_window)
        )
        
        return df
    
    def aggregate_daily(self, df: DataFrame) -> DataFrame:
        """Aggregate to daily level"""
        return df.groupBy("transaction_date", "store_id") \
            .agg(
                countDistinct("transaction_id").alias("transaction_count"),
                countDistinct("customer_id").alias("unique_customers"),
                sum("quantity").alias("total_quantity"),
                sum("total_amount").alias("total_revenue"),
                avg("total_amount").alias("avg_transaction_value")
            )
```

---

## Part 7: Loaders

### Step 7.1: Parquet Loader
```python
# src/loaders/parquet_loader.py
from .base import BaseLoader
from pyspark.sql import DataFrame
from typing import List, Optional

class ParquetLoader(BaseLoader):
    def __init__(self, mode: str = "overwrite", compression: str = "snappy"):
        super().__init__(mode)
        self.compression = compression
    
    def load(self, df: DataFrame, target: str, partition_cols: Optional[List[str]] = None):
        writer = df.write \
            .mode(self.mode) \
            .option("compression", self.compression)
        
        if partition_cols:
            writer = writer.partitionBy(*partition_cols)
        
        writer.parquet(target)
        
        # Log stats
        row_count = df.count()
        print(f"Loaded {row_count} rows to {target}")
```

### Step 7.2: Delta Loader
```python
# src/loaders/delta_loader.py
from .base import BaseLoader
from pyspark.sql import DataFrame, SparkSession
from typing import List, Optional

class DeltaLoader(BaseLoader):
    def __init__(self, spark: SparkSession, mode: str = "overwrite"):
        super().__init__(mode)
        self.spark = spark
    
    def load(self, df: DataFrame, target: str, partition_cols: Optional[List[str]] = None):
        writer = df.write \
            .format("delta") \
            .mode(self.mode)
        
        if partition_cols:
            writer = writer.partitionBy(*partition_cols)
        
        writer.save(target)
    
    def upsert(self, df: DataFrame, target: str, key_columns: List[str]):
        """Perform upsert (merge) operation"""
        from delta.tables import DeltaTable
        
        # Check if table exists
        try:
            delta_table = DeltaTable.forPath(self.spark, target)
        except:
            # First time - just write
            df.write.format("delta").save(target)
            return
        
        # Build merge condition
        condition = " AND ".join([f"target.{c} = source.{c}" for c in key_columns])
        
        # Build update dict (all non-key columns)
        update_cols = {c: f"source.{c}" for c in df.columns if c not in key_columns}
        insert_cols = {c: f"source.{c}" for c in df.columns}
        
        delta_table.alias("target").merge(
            df.alias("source"),
            condition
        ).whenMatchedUpdate(set=update_cols) \
         .whenNotMatchedInsert(values=insert_cols) \
         .execute()
```

---

## Part 8: Data Quality

```python
# src/utils/data_quality.py
from pyspark.sql import DataFrame
from pyspark.sql.functions import *
from typing import List, Dict
from dataclasses import dataclass

@dataclass
class QualityCheckResult:
    check_name: str
    passed: bool
    details: Dict

class DataQualityChecker:
    def __init__(self, df: DataFrame):
        self.df = df
        self.results = []
    
    def check_null_rate(self, columns: List[str], threshold: float = 0.1) -> 'DataQualityChecker':
        """Check null rate is below threshold"""
        total = self.df.count()
        
        for col_name in columns:
            null_count = self.df.filter(col(col_name).isNull()).count()
            null_rate = null_count / total if total > 0 else 0
            
            passed = null_rate <= threshold
            self.results.append(QualityCheckResult(
                check_name=f"null_rate_{col_name}",
                passed=passed,
                details={"column": col_name, "null_rate": null_rate, "threshold": threshold}
            ))
        
        return self
    
    def check_unique(self, columns: List[str]) -> 'DataQualityChecker':
        """Check columns are unique"""
        total = self.df.count()
        distinct = self.df.select(columns).distinct().count()
        
        passed = total == distinct
        self.results.append(QualityCheckResult(
            check_name=f"uniqueness_{'+'.join(columns)}",
            passed=passed,
            details={"total": total, "distinct": distinct}
        ))
        
        return self
    
    def check_range(self, column: str, min_val=None, max_val=None) -> 'DataQualityChecker':
        """Check values are within range"""
        violations = self.df
        
        if min_val is not None:
            violations = violations.filter(col(column) < min_val)
        if max_val is not None:
            violations = violations.filter(col(column) > max_val)
        
        violation_count = violations.count()
        passed = violation_count == 0
        
        self.results.append(QualityCheckResult(
            check_name=f"range_{column}",
            passed=passed,
            details={"violations": violation_count, "min": min_val, "max": max_val}
        ))
        
        return self
    
    def get_report(self) -> Dict:
        """Get summary report"""
        return {
            "total_checks": len(self.results),
            "passed": sum(1 for r in self.results if r.passed),
            "failed": sum(1 for r in self.results if not r.passed),
            "details": [{"name": r.check_name, "passed": r.passed, **r.details} for r in self.results]
        }
    
    def assert_quality(self):
        """Raise exception if any check failed"""
        failed = [r for r in self.results if not r.passed]
        if failed:
            raise ValueError(f"Data quality checks failed: {[r.check_name for r in failed]}")
```

---

## Part 9: Pipeline Orchestration

```python
# jobs/daily_sales_etl.py
from pyspark.sql import SparkSession
import logging
from datetime import date

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DailySalesETL")

class DailySalesETL:
    def __init__(self, spark: SparkSession, run_date: date):
        self.spark = spark
        self.run_date = run_date
    
    def extract(self):
        """Extract sales data"""
        logger.info(f"Extracting data for {self.run_date}")
        
        from src.extractors.csv_extractor import CSVExtractor
        from config.schemas import Schemas
        
        extractor = CSVExtractor(self.spark)
        
        # Extract source data
        self.sales_df = extractor.extract(
            f"data/raw/sales/{self.run_date}",
            schema=Schemas.SALES
        )
        
        self.customer_df = extractor.extract(
            "data/raw/customers",
            schema=Schemas.CUSTOMER
        )
        
        self.product_df = extractor.extract(
            "data/raw/products",
            schema=Schemas.PRODUCT
        )
        
        return self
    
    def transform(self):
        """Transform sales data"""
        logger.info("Transforming data")
        
        from src.transformers.cleaner import DataCleaner
        from src.transformers.enricher import DataEnricher
        from src.transformers.sales_transformer import SalesTransformer
        
        # Clean
        cleaner = DataCleaner({"dedup_columns": ["transaction_id"]})
        self.sales_df = cleaner.transform(self.sales_df)
        
        # Transform
        sales_transformer = SalesTransformer({})
        self.sales_df = sales_transformer.transform(self.sales_df)
        
        # Enrich with dimensions
        enricher = DataEnricher({"source_name": "daily_sales"})
        self.sales_df = enricher.join_dimension(
            self.sales_df, self.customer_df, "customer_id", ["first_name", "last_name"]
        )
        self.sales_df = enricher.join_dimension(
            self.sales_df, self.product_df, "product_id", ["product_name", "category"]
        )
        self.sales_df = enricher.add_audit_columns(self.sales_df)
        
        return self
    
    def validate(self):
        """Validate data quality"""
        logger.info("Validating data quality")
        
        from src.utils.data_quality import DataQualityChecker
        
        checker = DataQualityChecker(self.sales_df)
        checker \
            .check_null_rate(["transaction_id", "customer_id"], threshold=0.01) \
            .check_unique(["transaction_id"]) \
            .check_range("total_amount", min_val=0)
        
        report = checker.get_report()
        logger.info(f"Quality report: {report['passed']}/{report['total_checks']} passed")
        
        checker.assert_quality()
        
        return self
    
    def load(self):
        """Load to target"""
        logger.info("Loading to target")
        
        from src.loaders.delta_loader import DeltaLoader
        
        loader = DeltaLoader(self.spark, mode="append")
        loader.load(
            self.sales_df,
            "data/processed/sales_enriched",
            partition_cols=["year", "month"]
        )
        
        return self
    
    def run(self):
        """Execute full pipeline"""
        try:
            self.extract().transform().validate().load()
            logger.info("Pipeline completed successfully")
        except Exception as e:
            logger.error(f"Pipeline failed: {e}")
            raise

# Main execution
if __name__ == "__main__":
    spark = SparkSession.builder \
        .appName("Daily Sales ETL") \
        .getOrCreate()
    
    etl = DailySalesETL(spark, date.today())
    etl.run()
```

---

## Exercises

1. Build an ETL pipeline for customer dimension table
2. Add email notifications for pipeline failures
3. Implement incremental loading with watermarks
4. Create a data lineage tracking system

---

## Summary
- Modular design with extractors, transformers, loaders
- Configuration management for different environments
- Data quality checks before loading
- Error handling and logging throughout
- Reusable components for multiple pipelines
