# Lab 07: Pipeline Orchestration

## Overview
Build the complete pipeline orchestration with scheduling and monitoring.

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Create the main pipeline orchestrator
- ✅ Implement pipeline stages
- ✅ Add monitoring and metrics
- ✅ Handle pipeline state
- ✅ Implement scheduling

---

## Part 1: Pipeline Orchestrator

### Step 1.1: Main Pipeline Class
```python
# src/pipeline.py
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime
from pyspark.sql import SparkSession, DataFrame
import logging
import time

logger = logging.getLogger(__name__)


class PipelineStatus(Enum):
    """Pipeline execution status."""
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    PARTIAL = "partial"


@dataclass
class StageResult:
    """Result of a pipeline stage."""
    name: str
    status: PipelineStatus
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: float = 0.0
    records_processed: int = 0
    records_failed: int = 0
    error: Optional[str] = None
    metrics: Dict[str, Any] = field(default_factory=dict)


@dataclass
class PipelineResult:
    """Complete pipeline execution result."""
    pipeline_name: str
    status: PipelineStatus
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: float = 0.0
    stages: List[StageResult] = field(default_factory=list)
    metrics: Dict[str, Any] = field(default_factory=dict)


class Pipeline:
    """Main pipeline orchestrator."""
    
    def __init__(
        self,
        name: str,
        spark: SparkSession,
        config: Dict[str, Any]
    ):
        self.name = name
        self.spark = spark
        self.config = config
        self.logger = logging.getLogger(name)
        
        self.stages: List[Dict[str, Any]] = []
        self.dataframes: Dict[str, DataFrame] = {}
        self.result: Optional[PipelineResult] = None
        
        self._setup_logging()
    
    def _setup_logging(self):
        """Configure pipeline logging."""
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(name)s | %(levelname)s | %(message)s'
        ))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)
    
    def add_stage(
        self,
        name: str,
        func,
        dependencies: List[str] = None,
        critical: bool = True
    ) -> 'Pipeline':
        """
        Add a stage to the pipeline.
        
        Args:
            name: Stage name
            func: Function to execute (receives pipeline as argument)
            dependencies: List of stage names this depends on
            critical: If True, pipeline fails if this stage fails
        """
        self.stages.append({
            "name": name,
            "func": func,
            "dependencies": dependencies or [],
            "critical": critical
        })
        self.logger.info(f"Added stage: {name}")
        return self
    
    def run(self) -> PipelineResult:
        """Execute the pipeline."""
        self.logger.info(f"Starting pipeline: {self.name}")
        
        self.result = PipelineResult(
            pipeline_name=self.name,
            status=PipelineStatus.RUNNING,
            start_time=datetime.now()
        )
        
        completed_stages = set()
        failed = False
        
        for stage_config in self.stages:
            stage_name = stage_config["name"]
            
            # Check dependencies
            for dep in stage_config["dependencies"]:
                if dep not in completed_stages:
                    self.logger.warning(
                        f"Skipping {stage_name}: dependency {dep} not completed"
                    )
                    continue
            
            # Execute stage
            stage_result = self._execute_stage(stage_config)
            self.result.stages.append(stage_result)
            
            if stage_result.status == PipelineStatus.SUCCESS:
                completed_stages.add(stage_name)
            elif stage_config["critical"]:
                failed = True
                self.logger.error(f"Critical stage failed: {stage_name}")
                break
            else:
                self.logger.warning(f"Non-critical stage failed: {stage_name}")
        
        # Set final status
        self.result.end_time = datetime.now()
        self.result.duration_seconds = (
            self.result.end_time - self.result.start_time
        ).total_seconds()
        
        if failed:
            self.result.status = PipelineStatus.FAILED
        elif len(completed_stages) < len(self.stages):
            self.result.status = PipelineStatus.PARTIAL
        else:
            self.result.status = PipelineStatus.SUCCESS
        
        self.logger.info(
            f"Pipeline {self.name} completed with status: {self.result.status.value}"
        )
        
        return self.result
    
    def _execute_stage(self, stage_config: Dict) -> StageResult:
        """Execute a single stage."""
        stage_name = stage_config["name"]
        self.logger.info(f"Executing stage: {stage_name}")
        
        result = StageResult(
            name=stage_name,
            status=PipelineStatus.RUNNING,
            start_time=datetime.now()
        )
        
        try:
            # Execute the stage function
            stage_result = stage_config["func"](self)
            
            # Update result
            result.status = PipelineStatus.SUCCESS
            
            if isinstance(stage_result, dict):
                result.records_processed = stage_result.get("records", 0)
                result.metrics = stage_result.get("metrics", {})
            elif isinstance(stage_result, DataFrame):
                result.records_processed = stage_result.count()
            elif isinstance(stage_result, int):
                result.records_processed = stage_result
                
        except Exception as e:
            result.status = PipelineStatus.FAILED
            result.error = str(e)
            self.logger.exception(f"Stage {stage_name} failed: {e}")
        
        result.end_time = datetime.now()
        result.duration_seconds = (
            result.end_time - result.start_time
        ).total_seconds()
        
        self.logger.info(
            f"Stage {stage_name}: {result.status.value} "
            f"({result.duration_seconds:.2f}s)"
        )
        
        return result
    
    def get_dataframe(self, name: str) -> Optional[DataFrame]:
        """Get a cached DataFrame."""
        return self.dataframes.get(name)
    
    def set_dataframe(self, name: str, df: DataFrame, cache: bool = False):
        """Cache a DataFrame."""
        if cache:
            df = df.cache()
            df.count()  # Materialize
        self.dataframes[name] = df
    
    def get_summary(self) -> Dict[str, Any]:
        """Get pipeline execution summary."""
        if not self.result:
            return {}
        
        return {
            "pipeline_name": self.result.pipeline_name,
            "status": self.result.status.value,
            "duration_seconds": self.result.duration_seconds,
            "start_time": self.result.start_time.isoformat(),
            "end_time": self.result.end_time.isoformat() if self.result.end_time else None,
            "stages": [
                {
                    "name": s.name,
                    "status": s.status.value,
                    "duration": s.duration_seconds,
                    "records": s.records_processed,
                    "error": s.error
                }
                for s in self.result.stages
            ],
            "total_records": sum(s.records_processed for s in self.result.stages)
        }
```

---

## Part 2: Stage Definitions

### Step 2.1: Pipeline Stages
```python
# src/stages.py
from typing import Dict, Any
from pyspark.sql import functions as F
import logging

logger = logging.getLogger(__name__)


def stage_ingest_orders(pipeline) -> Dict[str, Any]:
    """Stage: Ingest orders data."""
    from src.ingestion.csv_ingester import CSVIngester
    
    ingester = CSVIngester(
        spark=pipeline.spark,
        config=pipeline.config,
        path=pipeline.config["paths"]["raw_data"] + "/orders.csv"
    )
    
    df = ingester.ingest()
    pipeline.set_dataframe("raw_orders", df, cache=True)
    
    return {"records": df.count()}


def stage_ingest_customers(pipeline) -> Dict[str, Any]:
    """Stage: Ingest customers data."""
    from src.ingestion.csv_ingester import CSVIngester
    
    ingester = CSVIngester(
        spark=pipeline.spark,
        config=pipeline.config,
        path=pipeline.config["paths"]["raw_data"] + "/customers.csv"
    )
    
    df = ingester.ingest()
    pipeline.set_dataframe("raw_customers", df, cache=True)
    
    return {"records": df.count()}


def stage_ingest_products(pipeline) -> Dict[str, Any]:
    """Stage: Ingest products data."""
    from src.ingestion.csv_ingester import CSVIngester
    
    ingester = CSVIngester(
        spark=pipeline.spark,
        config=pipeline.config,
        path=pipeline.config["paths"]["raw_data"] + "/products.csv"
    )
    
    df = ingester.ingest()
    pipeline.set_dataframe("raw_products", df, cache=True)
    
    return {"records": df.count()}


def stage_validate_orders(pipeline) -> Dict[str, Any]:
    """Stage: Validate orders data."""
    from src.utils.validators import DataValidator, Severity
    from src.utils.quarantine import QuarantineManager
    
    df = pipeline.get_dataframe("raw_orders")
    
    # Validate
    validator = DataValidator(pipeline.spark) \
        .not_null("order_id") \
        .not_null("customer_id") \
        .not_null("product_id") \
        .in_range("quantity", 1, 1000) \
        .in_range("unit_price", 0.01, 100000)
    
    results = validator.validate(df)
    summary = validator.get_summary()
    
    # Quarantine invalid records
    if not summary["all_passed"]:
        quarantine = QuarantineManager(
            pipeline.spark,
            pipeline.config["paths"]["quarantine"]
        )
        
        rules = {
            "order_id": F.col("order_id").isNotNull(),
            "customer_id": F.col("customer_id").isNotNull(),
            "quantity": F.col("quantity").between(1, 1000),
        }
        
        valid_df, invalid_df = quarantine.quarantine(df, rules, "orders")
        
        if invalid_df.count() > 0:
            quarantine.save_quarantine(invalid_df, "orders")
        
        pipeline.set_dataframe("validated_orders", valid_df)
    else:
        pipeline.set_dataframe("validated_orders", df)
    
    return {
        "records": pipeline.get_dataframe("validated_orders").count(),
        "metrics": summary
    }


def stage_transform_orders(pipeline) -> Dict[str, Any]:
    """Stage: Transform orders."""
    from src.transformation.cleanser import DataCleanser
    from src.transformation.enricher import DataEnricher
    
    orders_df = pipeline.get_dataframe("validated_orders")
    products_df = pipeline.get_dataframe("raw_products")
    customers_df = pipeline.get_dataframe("raw_customers")
    
    # Clean
    cleanser = DataCleanser(pipeline.spark) \
        .trim_strings() \
        .remove_duplicates(["order_id"])
    
    cleaned_df = cleanser.transform(orders_df)
    
    # Enrich
    enricher = DataEnricher(pipeline.spark)
    enricher.register_lookup("products", products_df)
    enricher.register_lookup("customers", customers_df)
    
    enricher \
        .add_total_amount("quantity", "unit_price") \
        .add_date_parts("order_date") \
        .join_lookup("products", "product_id", columns=["product_name", "category"]) \
        .join_lookup("customers", "customer_id", columns=["name", "email", "region"])
    
    enriched_df = enricher.transform(cleaned_df)
    
    pipeline.set_dataframe("transformed_orders", enriched_df, cache=True)
    
    return {"records": enriched_df.count()}


def stage_aggregate_sales(pipeline) -> Dict[str, Any]:
    """Stage: Create sales aggregations."""
    from src.transformation.aggregator import DataAggregator
    
    orders_df = pipeline.get_dataframe("transformed_orders")
    
    # Daily sales by category
    daily_agg = DataAggregator(pipeline.spark).aggregate(
        group_by=["order_date", "category"],
        aggregations={
            "total_amount": ["sum", "avg", "count"],
            "quantity": ["sum"]
        }
    )
    
    daily_sales = daily_agg.transform(orders_df)
    pipeline.set_dataframe("daily_sales", daily_sales)
    
    # Customer summary
    customer_agg = DataAggregator(pipeline.spark).aggregate(
        group_by=["customer_id", "name", "region"],
        aggregations={
            "total_amount": ["sum", "count"],
        }
    )
    
    customer_summary = customer_agg.transform(orders_df)
    pipeline.set_dataframe("customer_summary", customer_summary)
    
    return {
        "records": daily_sales.count() + customer_summary.count(),
        "metrics": {
            "daily_records": daily_sales.count(),
            "customer_records": customer_summary.count()
        }
    }


def stage_load_warehouse(pipeline) -> Dict[str, Any]:
    """Stage: Load to warehouse."""
    from src.loading.warehouse_loader import WarehouseLoader
    
    loader = WarehouseLoader(pipeline.spark, pipeline.config)
    
    # Load fact table
    orders_df = pipeline.get_dataframe("transformed_orders")
    loader.load_fact(
        df=orders_df,
        fact_name="sales",
        partition_columns=["order_date_year", "order_date_month"]
    )
    
    # Load dimension tables
    customers_df = pipeline.get_dataframe("raw_customers")
    loader.load_dimension(
        df=customers_df,
        dim_name="customers",
        key_column="customer_id"
    )
    
    products_df = pipeline.get_dataframe("raw_products")
    loader.load_dimension(
        df=products_df,
        dim_name="products",
        key_column="product_id"
    )
    
    # Load aggregates
    daily_sales = pipeline.get_dataframe("daily_sales")
    loader.load_aggregate(
        df=daily_sales,
        agg_name="sales_by_category",
        grain="daily"
    )
    
    return {"records": orders_df.count()}


def stage_generate_reports(pipeline) -> Dict[str, Any]:
    """Stage: Generate reports."""
    from src.loading.report_generator import ReportGenerator
    
    generator = ReportGenerator(pipeline.spark, pipeline.config)
    
    # Daily sales report
    daily_sales = pipeline.get_dataframe("daily_sales")
    generator.generate_csv_report(daily_sales, "daily_sales_report")
    
    # Customer summary report
    customer_summary = pipeline.get_dataframe("customer_summary")
    generator.generate_csv_report(customer_summary, "customer_summary_report")
    
    return {"records": daily_sales.count() + customer_summary.count()}
```

---

## Part 3: Main Entry Point

### Step 3.1: Main Script
```python
# src/main.py
import sys
import argparse
from datetime import datetime
from pyspark.sql import SparkSession
from src.pipeline import Pipeline, PipelineStatus
from src.stages import (
    stage_ingest_orders,
    stage_ingest_customers,
    stage_ingest_products,
    stage_validate_orders,
    stage_transform_orders,
    stage_aggregate_sales,
    stage_load_warehouse,
    stage_generate_reports,
)
from src.utils.config import Config
from src.utils.logger import setup_logger
import logging


def create_spark_session(config: dict) -> SparkSession:
    """Create and configure SparkSession."""
    builder = SparkSession.builder \
        .appName(config.get("spark", {}).get("app_name", "ECommerce Pipeline"))
    
    master = config.get("spark", {}).get("master", "local[*]")
    builder = builder.master(master)
    
    # Apply Spark configurations
    for key, value in config.get("spark", {}).get("config", {}).items():
        builder = builder.config(key, value)
    
    return builder.getOrCreate()


def build_pipeline(spark: SparkSession, config: dict) -> Pipeline:
    """Build the complete pipeline."""
    pipeline = Pipeline(
        name="ecommerce_etl",
        spark=spark,
        config=config
    )
    
    # Ingestion stages (can run in parallel conceptually)
    pipeline.add_stage("ingest_orders", stage_ingest_orders)
    pipeline.add_stage("ingest_customers", stage_ingest_customers)
    pipeline.add_stage("ingest_products", stage_ingest_products)
    
    # Validation stage
    pipeline.add_stage(
        "validate_orders",
        stage_validate_orders,
        dependencies=["ingest_orders"]
    )
    
    # Transformation stage
    pipeline.add_stage(
        "transform_orders",
        stage_transform_orders,
        dependencies=["validate_orders", "ingest_customers", "ingest_products"]
    )
    
    # Aggregation stage
    pipeline.add_stage(
        "aggregate_sales",
        stage_aggregate_sales,
        dependencies=["transform_orders"]
    )
    
    # Loading stage
    pipeline.add_stage(
        "load_warehouse",
        stage_load_warehouse,
        dependencies=["aggregate_sales"]
    )
    
    # Reporting stage (non-critical)
    pipeline.add_stage(
        "generate_reports",
        stage_generate_reports,
        dependencies=["aggregate_sales"],
        critical=False
    )
    
    return pipeline


def main():
    """Main entry point."""
    # Parse arguments
    parser = argparse.ArgumentParser(description="E-Commerce Data Pipeline")
    parser.add_argument("--env", default="development", help="Environment name")
    parser.add_argument("--date", default=None, help="Processing date (YYYY-MM-DD)")
    args = parser.parse_args()
    
    # Setup logging
    logger = setup_logger(
        "ecommerce_pipeline",
        log_file=f"logs/pipeline_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    )
    
    logger.info(f"Starting pipeline for environment: {args.env}")
    
    try:
        # Load configuration
        config = Config(args.env)
        
        # Create Spark session
        spark = create_spark_session(config._config)
        
        # Build and run pipeline
        pipeline = build_pipeline(spark, config._config)
        result = pipeline.run()
        
        # Log summary
        summary = pipeline.get_summary()
        logger.info(f"Pipeline completed: {summary['status']}")
        logger.info(f"Duration: {summary['duration_seconds']:.2f}s")
        logger.info(f"Total records: {summary['total_records']}")
        
        for stage in summary["stages"]:
            status = "✓" if stage["status"] == "success" else "✗"
            logger.info(
                f"  {status} {stage['name']}: {stage['records']} records "
                f"({stage['duration']:.2f}s)"
            )
        
        # Exit code based on status
        if result.status == PipelineStatus.SUCCESS:
            sys.exit(0)
        elif result.status == PipelineStatus.PARTIAL:
            sys.exit(1)
        else:
            sys.exit(2)
            
    except Exception as e:
        logger.exception(f"Pipeline failed: {e}")
        sys.exit(2)
    finally:
        if 'spark' in locals():
            spark.stop()


if __name__ == "__main__":
    main()
```

---

## Part 4: Scheduling

### Step 4.1: Cron-Based Scheduling
```python
# scripts/schedule.py
import schedule
import time
import subprocess
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("scheduler")


def run_pipeline(env: str = "production"):
    """Run the pipeline."""
    logger.info(f"Starting scheduled pipeline run at {datetime.now()}")
    
    result = subprocess.run(
        ["python", "-m", "src.main", "--env", env],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        logger.info("Pipeline completed successfully")
    else:
        logger.error(f"Pipeline failed: {result.stderr}")
        # Send alert
        send_alert(f"Pipeline failed: {result.stderr}")
    
    return result.returncode


def send_alert(message: str):
    """Send alert on failure."""
    # Implement alerting (email, Slack, etc.)
    logger.warning(f"ALERT: {message}")


def main():
    # Schedule daily run at 2 AM
    schedule.every().day.at("02:00").do(run_pipeline, env="production")
    
    # Or run every hour
    # schedule.every().hour.do(run_pipeline)
    
    logger.info("Scheduler started")
    
    while True:
        schedule.run_pending()
        time.sleep(60)


if __name__ == "__main__":
    main()
```

### Step 4.2: Airflow DAG
```python
# dags/ecommerce_pipeline.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from datetime import timedelta


default_args = {
    'owner': 'data_engineering',
    'depends_on_past': False,
    'email': ['alerts@company.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'ecommerce_pipeline',
    default_args=default_args,
    description='E-Commerce Data Pipeline',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    start_date=days_ago(1),
    catchup=False,
    tags=['etl', 'ecommerce'],
)


ingest_orders = BashOperator(
    task_id='ingest_orders',
    bash_command='spark-submit --master yarn src/stages/ingest_orders.py',
    dag=dag,
)

ingest_customers = BashOperator(
    task_id='ingest_customers',
    bash_command='spark-submit --master yarn src/stages/ingest_customers.py',
    dag=dag,
)

ingest_products = BashOperator(
    task_id='ingest_products',
    bash_command='spark-submit --master yarn src/stages/ingest_products.py',
    dag=dag,
)

validate = BashOperator(
    task_id='validate_orders',
    bash_command='spark-submit --master yarn src/stages/validate.py',
    dag=dag,
)

transform = BashOperator(
    task_id='transform',
    bash_command='spark-submit --master yarn src/stages/transform.py',
    dag=dag,
)

aggregate = BashOperator(
    task_id='aggregate',
    bash_command='spark-submit --master yarn src/stages/aggregate.py',
    dag=dag,
)

load = BashOperator(
    task_id='load_warehouse',
    bash_command='spark-submit --master yarn src/stages/load.py',
    dag=dag,
)

report = BashOperator(
    task_id='generate_reports',
    bash_command='spark-submit --master yarn src/stages/report.py',
    dag=dag,
)

# Define dependencies
[ingest_orders, ingest_customers, ingest_products] >> validate
validate >> transform >> aggregate >> load >> report
```

---

## Part 5: Monitoring Dashboard

### Step 5.1: Metrics Collection
```python
# src/monitoring/metrics.py
from typing import Dict, Any, List
from datetime import datetime
import json
from pathlib import Path


class PipelineMetrics:
    """Collect and store pipeline metrics."""
    
    def __init__(self, metrics_path: str = "metrics"):
        self.metrics_path = Path(metrics_path)
        self.metrics_path.mkdir(parents=True, exist_ok=True)
    
    def save_run_metrics(self, summary: Dict[str, Any]):
        """Save pipeline run metrics."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_path = self.metrics_path / f"run_{timestamp}.json"
        
        with open(file_path, 'w') as f:
            json.dump(summary, f, indent=2, default=str)
    
    def get_recent_runs(self, n: int = 10) -> List[Dict[str, Any]]:
        """Get recent pipeline runs."""
        files = sorted(self.metrics_path.glob("run_*.json"), reverse=True)
        
        runs = []
        for file_path in files[:n]:
            with open(file_path) as f:
                runs.append(json.load(f))
        
        return runs
    
    def get_success_rate(self, days: int = 7) -> float:
        """Calculate success rate over recent days."""
        runs = self.get_recent_runs(100)
        
        if not runs:
            return 0.0
        
        success_count = sum(1 for r in runs if r.get("status") == "success")
        return success_count / len(runs)
    
    def get_average_duration(self, days: int = 7) -> float:
        """Calculate average pipeline duration."""
        runs = self.get_recent_runs(100)
        
        if not runs:
            return 0.0
        
        durations = [r.get("duration_seconds", 0) for r in runs]
        return sum(durations) / len(durations)
```

---

## Exercises

1. Add more pipeline stages
2. Implement parallel stage execution
3. Create an Airflow DAG
4. Build a monitoring dashboard

---

## Summary
- Built pipeline orchestrator
- Created modular pipeline stages
- Implemented main entry point
- Added scheduling options
- Built monitoring capabilities

---

## Next Lab
In the next lab, we'll add documentation and deploy the pipeline.
