# Lab 04: Data Loading and Warehouse

## Overview
Build the data loading layer to persist transformed data to the warehouse.

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Load data to different destinations
- ✅ Implement upsert (merge) operations
- ✅ Build dimensional models
- ✅ Manage partitions effectively
- ✅ Create data warehouse structures

---

## Part 1: Base Loader Class

### Step 1.1: Abstract Loader
```python
# src/loading/base_loader.py
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from pyspark.sql import DataFrame, SparkSession
import logging

logger = logging.getLogger(__name__)


class BaseLoader(ABC):
    """Abstract base class for data loaders."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any]):
        self.spark = spark
        self.config = config
        self.logger = logging.getLogger(self.__class__.__name__)
    
    @abstractmethod
    def load(self, df: DataFrame, destination: str, **kwargs) -> bool:
        """Load DataFrame to destination."""
        pass
    
    @abstractmethod
    def validate_destination(self, destination: str) -> bool:
        """Validate destination is accessible."""
        pass
    
    def log_stats(self, df: DataFrame, destination: str):
        """Log loading statistics."""
        count = df.count()
        self.logger.info(f"Loading {count} rows to {destination}")
```

---

## Part 2: File Loader

### Step 2.1: Parquet and Delta Loader
```python
# src/loading/file_loader.py
from typing import Dict, Any, List, Optional
from pyspark.sql import DataFrame, SparkSession
from .base_loader import BaseLoader
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class FileLoader(BaseLoader):
    """Load data to file-based storage."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any]):
        super().__init__(spark, config)
    
    def validate_destination(self, destination: str) -> bool:
        """Validate destination path is writable."""
        try:
            # For local paths
            path = Path(destination)
            path.parent.mkdir(parents=True, exist_ok=True)
            return True
        except Exception as e:
            self.logger.error(f"Invalid destination: {e}")
            return False
    
    def load(
        self,
        df: DataFrame,
        destination: str,
        format: str = "parquet",
        mode: str = "overwrite",
        partition_by: List[str] = None,
        options: Dict[str, str] = None
    ) -> bool:
        """Load DataFrame to file storage."""
        self.log_stats(df, destination)
        
        try:
            writer = df.write.format(format).mode(mode)
            
            if partition_by:
                writer = writer.partitionBy(*partition_by)
            
            if options:
                writer = writer.options(**options)
            
            writer.save(destination)
            
            self.logger.info(f"Successfully loaded to {destination}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to load: {e}")
            raise
    
    def load_parquet(
        self,
        df: DataFrame,
        destination: str,
        mode: str = "overwrite",
        partition_by: List[str] = None,
        compression: str = "snappy"
    ) -> bool:
        """Load as Parquet format."""
        return self.load(
            df=df,
            destination=destination,
            format="parquet",
            mode=mode,
            partition_by=partition_by,
            options={"compression": compression}
        )
    
    def load_delta(
        self,
        df: DataFrame,
        destination: str,
        mode: str = "overwrite",
        partition_by: List[str] = None,
        merge_schema: bool = False
    ) -> bool:
        """Load as Delta format."""
        options = {}
        if merge_schema:
            options["mergeSchema"] = "true"
        
        return self.load(
            df=df,
            destination=destination,
            format="delta",
            mode=mode,
            partition_by=partition_by,
            options=options
        )
    
    def upsert_delta(
        self,
        df: DataFrame,
        destination: str,
        key_columns: List[str],
        partition_by: List[str] = None
    ) -> bool:
        """Upsert (merge) data into Delta table."""
        from delta.tables import DeltaTable
        
        self.logger.info(f"Upserting to {destination}")
        
        # Check if table exists
        if DeltaTable.isDeltaTable(self.spark, destination):
            # Merge into existing table
            delta_table = DeltaTable.forPath(self.spark, destination)
            
            # Build merge condition
            condition = " AND ".join(
                [f"target.{col} = source.{col}" for col in key_columns]
            )
            
            # Perform merge
            delta_table.alias("target") \
                .merge(df.alias("source"), condition) \
                .whenMatchedUpdateAll() \
                .whenNotMatchedInsertAll() \
                .execute()
            
            self.logger.info("Merge completed successfully")
        else:
            # Create new table
            self.load_delta(df, destination, partition_by=partition_by)
        
        return True
```

---

## Part 3: Database Loader

### Step 3.1: JDBC Loader
```python
# src/loading/db_loader.py
from typing import Dict, Any, List, Optional
from pyspark.sql import DataFrame, SparkSession
from .base_loader import BaseLoader
import logging

logger = logging.getLogger(__name__)


class DatabaseLoader(BaseLoader):
    """Load data to relational databases via JDBC."""
    
    def __init__(
        self,
        spark: SparkSession,
        config: Dict[str, Any],
        db_config: Dict[str, Any] = None
    ):
        super().__init__(spark, config)
        self.db_config = db_config or config.get('database', {})
    
    @property
    def jdbc_url(self) -> str:
        """Build JDBC URL."""
        host = self.db_config.get('host', 'localhost')
        port = self.db_config.get('port', 5432)
        database = self.db_config.get('name', 'postgres')
        db_type = self.db_config.get('type', 'postgresql')
        return f"jdbc:{db_type}://{host}:{port}/{database}"
    
    @property
    def connection_properties(self) -> Dict[str, str]:
        """Get connection properties."""
        return {
            "user": self.db_config.get('user', ''),
            "password": self.db_config.get('password', ''),
            "driver": self.db_config.get('driver', 'org.postgresql.Driver'),
        }
    
    def validate_destination(self, table: str) -> bool:
        """Validate table is accessible."""
        try:
            query = f"SELECT 1 FROM {table} LIMIT 1"
            self.spark.read.jdbc(
                url=self.jdbc_url,
                table=f"({query}) as test",
                properties=self.connection_properties
            ).collect()
            return True
        except Exception:
            # Table might not exist yet
            return True
    
    def load(
        self,
        df: DataFrame,
        destination: str,
        mode: str = "append",
        batch_size: int = 10000,
        **kwargs
    ) -> bool:
        """Load DataFrame to database table."""
        self.log_stats(df, destination)
        
        try:
            properties = {
                **self.connection_properties,
                "batchsize": str(batch_size),
            }
            
            df.write \
                .mode(mode) \
                .jdbc(
                    url=self.jdbc_url,
                    table=destination,
                    properties=properties
                )
            
            self.logger.info(f"Successfully loaded to {destination}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to load: {e}")
            raise
    
    def truncate_and_load(self, df: DataFrame, table: str) -> bool:
        """Truncate table and load fresh data."""
        self.logger.info(f"Truncating and loading {table}")
        
        # Truncate using SQL
        self.execute_sql(f"TRUNCATE TABLE {table}")
        
        # Load data
        return self.load(df, table, mode="append")
    
    def execute_sql(self, sql: str):
        """Execute raw SQL statement."""
        import psycopg2
        
        conn = psycopg2.connect(
            host=self.db_config.get('host'),
            port=self.db_config.get('port'),
            database=self.db_config.get('name'),
            user=self.db_config.get('user'),
            password=self.db_config.get('password')
        )
        
        try:
            with conn.cursor() as cursor:
                cursor.execute(sql)
            conn.commit()
        finally:
            conn.close()
```

---

## Part 4: Warehouse Loader

### Step 4.1: Data Warehouse Structure
```python
# src/loading/warehouse_loader.py
from typing import Dict, Any, List, Optional
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from .file_loader import FileLoader
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class WarehouseLoader:
    """Manage data warehouse loading operations."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any]):
        self.spark = spark
        self.config = config
        self.base_path = config.get('paths', {}).get('warehouse', './warehouse')
        self.file_loader = FileLoader(spark, config)
        self.logger = logging.getLogger(__name__)
    
    # ==================== DIMENSION TABLES ====================
    
    def load_dimension(
        self,
        df: DataFrame,
        dim_name: str,
        key_column: str,
        scd_type: int = 1
    ) -> bool:
        """Load dimension table with SCD handling."""
        dim_path = f"{self.base_path}/dimensions/{dim_name}"
        
        if scd_type == 1:
            return self._load_scd1(df, dim_path, key_column)
        elif scd_type == 2:
            return self._load_scd2(df, dim_path, key_column)
        else:
            raise ValueError(f"Unsupported SCD type: {scd_type}")
    
    def _load_scd1(
        self,
        df: DataFrame,
        path: str,
        key_column: str
    ) -> bool:
        """SCD Type 1 - Overwrite changes."""
        return self.file_loader.upsert_delta(
            df=df,
            destination=path,
            key_columns=[key_column]
        )
    
    def _load_scd2(
        self,
        df: DataFrame,
        path: str,
        key_column: str
    ) -> bool:
        """SCD Type 2 - Maintain history."""
        from delta.tables import DeltaTable
        
        # Add SCD columns
        df = df \
            .withColumn("effective_date", F.current_date()) \
            .withColumn("end_date", F.lit(None).cast("date")) \
            .withColumn("is_current", F.lit(True))
        
        if not DeltaTable.isDeltaTable(self.spark, path):
            # First load
            return self.file_loader.load_delta(df, path)
        
        # Get existing table
        delta_table = DeltaTable.forPath(self.spark, path)
        
        # Find changed records
        existing = delta_table.toDF().filter(F.col("is_current") == True)
        
        # Identify changes
        changes = df.alias("new").join(
            existing.alias("old"),
            F.col(f"new.{key_column}") == F.col(f"old.{key_column}"),
            "left"
        ).filter(
            F.col(f"old.{key_column}").isNull() |
            (F.col("new.hash") != F.col("old.hash"))  # Assuming hash column
        ).select("new.*")
        
        # Update existing records
        delta_table.alias("target") \
            .merge(
                changes.alias("source"),
                f"target.{key_column} = source.{key_column} AND target.is_current = true"
            ) \
            .whenMatchedUpdate(set={
                "end_date": F.current_date(),
                "is_current": F.lit(False)
            }) \
            .execute()
        
        # Insert new records
        changes.write.format("delta").mode("append").save(path)
        
        return True
    
    # ==================== FACT TABLES ====================
    
    def load_fact(
        self,
        df: DataFrame,
        fact_name: str,
        partition_columns: List[str] = None,
        mode: str = "append"
    ) -> bool:
        """Load fact table."""
        fact_path = f"{self.base_path}/facts/{fact_name}"
        
        # Add load timestamp
        df = df.withColumn("_loaded_at", F.current_timestamp())
        
        return self.file_loader.load_delta(
            df=df,
            destination=fact_path,
            mode=mode,
            partition_by=partition_columns or ["year", "month"]
        )
    
    def load_fact_incremental(
        self,
        df: DataFrame,
        fact_name: str,
        key_columns: List[str],
        partition_columns: List[str] = None
    ) -> bool:
        """Load fact table with deduplication."""
        fact_path = f"{self.base_path}/facts/{fact_name}"
        
        # Add load timestamp
        df = df.withColumn("_loaded_at", F.current_timestamp())
        
        return self.file_loader.upsert_delta(
            df=df,
            destination=fact_path,
            key_columns=key_columns,
            partition_by=partition_columns
        )
    
    # ==================== AGGREGATION TABLES ====================
    
    def load_aggregate(
        self,
        df: DataFrame,
        agg_name: str,
        grain: str = "daily"
    ) -> bool:
        """Load pre-aggregated table."""
        agg_path = f"{self.base_path}/aggregates/{agg_name}_{grain}"
        
        # Add metadata
        df = df \
            .withColumn("_grain", F.lit(grain)) \
            .withColumn("_computed_at", F.current_timestamp())
        
        return self.file_loader.load_delta(
            df=df,
            destination=agg_path,
            mode="overwrite"
        )
    
    # ==================== SNAPSHOT TABLES ====================
    
    def load_snapshot(
        self,
        df: DataFrame,
        snapshot_name: str,
        snapshot_date: str = None
    ) -> bool:
        """Load point-in-time snapshot."""
        date = snapshot_date or datetime.now().strftime("%Y-%m-%d")
        snapshot_path = f"{self.base_path}/snapshots/{snapshot_name}"
        
        # Add snapshot metadata
        df = df \
            .withColumn("_snapshot_date", F.lit(date)) \
            .withColumn("_snapshot_timestamp", F.current_timestamp())
        
        return self.file_loader.load_delta(
            df=df,
            destination=snapshot_path,
            mode="append",
            partition_by=["_snapshot_date"]
        )
```

---

## Part 5: Report Generator

### Step 5.1: Report Output
```python
# src/loading/report_generator.py
from typing import Dict, Any, List, Optional
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
import logging
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)


class ReportGenerator:
    """Generate reports from processed data."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any]):
        self.spark = spark
        self.config = config
        self.output_path = config.get('paths', {}).get('output', './reports')
        self.logger = logging.getLogger(__name__)
    
    def generate_csv_report(
        self,
        df: DataFrame,
        report_name: str,
        include_header: bool = True,
        single_file: bool = True
    ) -> str:
        """Generate CSV report."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = f"{self.output_path}/{report_name}_{timestamp}"
        
        writer = df.write \
            .mode("overwrite") \
            .option("header", str(include_header).lower())
        
        if single_file:
            # Coalesce to single partition for single file output
            df = df.coalesce(1)
        
        writer.csv(report_path)
        
        self.logger.info(f"Generated CSV report: {report_path}")
        return report_path
    
    def generate_excel_report(
        self,
        df: DataFrame,
        report_name: str,
        sheet_name: str = "Report"
    ) -> str:
        """Generate Excel report using Pandas."""
        import pandas as pd
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = f"{self.output_path}/{report_name}_{timestamp}.xlsx"
        
        # Ensure output directory exists
        Path(self.output_path).mkdir(parents=True, exist_ok=True)
        
        # Convert to Pandas
        pdf = df.toPandas()
        
        # Write to Excel
        with pd.ExcelWriter(report_path, engine='openpyxl') as writer:
            pdf.to_excel(writer, sheet_name=sheet_name, index=False)
        
        self.logger.info(f"Generated Excel report: {report_path}")
        return report_path
    
    def generate_summary_report(
        self,
        df: DataFrame,
        report_name: str,
        group_by: List[str],
        metrics: Dict[str, str]
    ) -> DataFrame:
        """Generate summary report with aggregations."""
        # Build aggregations
        agg_exprs = []
        for col, agg_type in metrics.items():
            if agg_type == "sum":
                agg_exprs.append(F.sum(col).alias(f"total_{col}"))
            elif agg_type == "avg":
                agg_exprs.append(F.avg(col).alias(f"avg_{col}"))
            elif agg_type == "count":
                agg_exprs.append(F.count(col).alias(f"count_{col}"))
            elif agg_type == "distinct":
                agg_exprs.append(F.countDistinct(col).alias(f"distinct_{col}"))
        
        # Create summary
        summary = df.groupBy(group_by).agg(*agg_exprs)
        
        # Add report metadata
        summary = summary \
            .withColumn("_report_name", F.lit(report_name)) \
            .withColumn("_generated_at", F.current_timestamp())
        
        return summary
    
    def generate_dashboard_data(
        self,
        dataframes: Dict[str, DataFrame],
        output_format: str = "json"
    ) -> Dict[str, str]:
        """Generate data files for dashboards."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        outputs = {}
        
        for name, df in dataframes.items():
            output_path = f"{self.output_path}/dashboard/{name}_{timestamp}"
            
            if output_format == "json":
                df.coalesce(1).write.mode("overwrite").json(output_path)
            elif output_format == "parquet":
                df.write.mode("overwrite").parquet(output_path)
            
            outputs[name] = output_path
            self.logger.info(f"Generated dashboard data: {name}")
        
        return outputs
```

---

## Part 6: Loading Pipeline

### Step 6.1: Orchestrated Loading
```python
# src/loading/loading_pipeline.py
from typing import Dict, Any, List
from pyspark.sql import DataFrame, SparkSession
from .warehouse_loader import WarehouseLoader
from .report_generator import ReportGenerator
import logging

logger = logging.getLogger(__name__)


class LoadingPipeline:
    """Orchestrate data loading operations."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any]):
        self.spark = spark
        self.config = config
        self.warehouse = WarehouseLoader(spark, config)
        self.reports = ReportGenerator(spark, config)
        self.logger = logging.getLogger(__name__)
    
    def load_warehouse(
        self,
        dimensions: Dict[str, tuple],  # name -> (df, key_column)
        facts: Dict[str, tuple],        # name -> (df, partition_cols)
        aggregates: Dict[str, tuple] = None  # name -> (df, grain)
    ) -> Dict[str, bool]:
        """Load complete warehouse structure."""
        results = {}
        
        # Load dimensions
        for name, (df, key_col) in dimensions.items():
            self.logger.info(f"Loading dimension: {name}")
            try:
                results[f"dim_{name}"] = self.warehouse.load_dimension(
                    df=df,
                    dim_name=name,
                    key_column=key_col
                )
            except Exception as e:
                self.logger.error(f"Failed to load dim_{name}: {e}")
                results[f"dim_{name}"] = False
        
        # Load facts
        for name, (df, partition_cols) in facts.items():
            self.logger.info(f"Loading fact: {name}")
            try:
                results[f"fact_{name}"] = self.warehouse.load_fact(
                    df=df,
                    fact_name=name,
                    partition_columns=partition_cols
                )
            except Exception as e:
                self.logger.error(f"Failed to load fact_{name}: {e}")
                results[f"fact_{name}"] = False
        
        # Load aggregates
        if aggregates:
            for name, (df, grain) in aggregates.items():
                self.logger.info(f"Loading aggregate: {name}")
                try:
                    results[f"agg_{name}"] = self.warehouse.load_aggregate(
                        df=df,
                        agg_name=name,
                        grain=grain
                    )
                except Exception as e:
                    self.logger.error(f"Failed to load agg_{name}: {e}")
                    results[f"agg_{name}"] = False
        
        return results
    
    def generate_reports(
        self,
        reports: Dict[str, Dict[str, Any]]
    ) -> Dict[str, str]:
        """Generate multiple reports."""
        outputs = {}
        
        for name, config in reports.items():
            df = config["dataframe"]
            report_type = config.get("type", "csv")
            
            self.logger.info(f"Generating report: {name}")
            
            if report_type == "csv":
                outputs[name] = self.reports.generate_csv_report(
                    df=df,
                    report_name=name
                )
            elif report_type == "excel":
                outputs[name] = self.reports.generate_excel_report(
                    df=df,
                    report_name=name
                )
            elif report_type == "summary":
                summary_df = self.reports.generate_summary_report(
                    df=df,
                    report_name=name,
                    group_by=config["group_by"],
                    metrics=config["metrics"]
                )
                outputs[name] = self.reports.generate_csv_report(
                    df=summary_df,
                    report_name=name
                )
        
        return outputs
```

### Step 6.2: Usage Example
```python
from src.loading.loading_pipeline import LoadingPipeline

# Initialize
pipeline = LoadingPipeline(spark, config._config)

# Define warehouse loads
dimensions = {
    "customers": (customers_df, "customer_id"),
    "products": (products_df, "product_id"),
    "dates": (date_dim_df, "date_key"),
}

facts = {
    "sales": (sales_df, ["year", "month"]),
    "inventory": (inventory_df, ["date"]),
}

aggregates = {
    "sales_by_category": (category_sales_df, "daily"),
    "customer_metrics": (customer_metrics_df, "monthly"),
}

# Load warehouse
load_results = pipeline.load_warehouse(dimensions, facts, aggregates)

# Generate reports
reports = {
    "daily_sales": {
        "dataframe": daily_sales_df,
        "type": "csv"
    },
    "monthly_summary": {
        "dataframe": monthly_df,
        "type": "summary",
        "group_by": ["region", "category"],
        "metrics": {"revenue": "sum", "orders": "count"}
    }
}

report_paths = pipeline.generate_reports(reports)
```

---

## Exercises

1. Create a fact table loader with partitioning
2. Implement SCD Type 2 for customer dimension
3. Build a report generator for sales analytics
4. Create a complete loading pipeline

---

## Summary
- Built file and database loaders
- Implemented warehouse loading patterns
- Created dimension and fact table loaders
- Built report generation capabilities
- Orchestrated complete loading pipeline

---

## Next Lab
In the next lab, we'll implement error handling and data quality checks.
