# Lab 05: Error Handling and Data Quality

## Overview
Implement robust error handling and data quality validation for the pipeline.

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Implement comprehensive error handling
- ✅ Create data quality validators
- ✅ Build quality monitoring
- ✅ Handle and quarantine bad data
- ✅ Create alerting mechanisms

---

## Part 1: Custom Exceptions

### Step 1.1: Exception Hierarchy
```python
# src/utils/exceptions.py
from typing import Optional, Dict, Any


class PipelineException(Exception):
    """Base exception for pipeline errors."""
    
    def __init__(
        self,
        message: str,
        error_code: str = None,
        details: Dict[str, Any] = None
    ):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.details = details or {}
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "error_type": self.__class__.__name__,
            "message": self.message,
            "error_code": self.error_code,
            "details": self.details
        }


class IngestionError(PipelineException):
    """Error during data ingestion."""
    pass


class ValidationError(PipelineException):
    """Error during data validation."""
    pass


class TransformationError(PipelineException):
    """Error during data transformation."""
    pass


class LoadingError(PipelineException):
    """Error during data loading."""
    pass


class DataQualityError(PipelineException):
    """Error when data quality checks fail."""
    
    def __init__(
        self,
        message: str,
        failed_rules: list = None,
        failed_count: int = 0,
        total_count: int = 0,
        **kwargs
    ):
        super().__init__(message, **kwargs)
        self.failed_rules = failed_rules or []
        self.failed_count = failed_count
        self.total_count = total_count
        self.details.update({
            "failed_rules": self.failed_rules,
            "failed_count": self.failed_count,
            "total_count": self.total_count,
            "failure_rate": self.failure_rate
        })
    
    @property
    def failure_rate(self) -> float:
        if self.total_count == 0:
            return 0.0
        return self.failed_count / self.total_count


class ConfigurationError(PipelineException):
    """Error in pipeline configuration."""
    pass


class SchemaError(PipelineException):
    """Error in data schema."""
    pass
```

---

## Part 2: Data Validators

### Step 2.1: Validation Rules
```python
# src/utils/validators.py
from typing import Dict, List, Any, Callable, Optional
from dataclasses import dataclass, field
from enum import Enum
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
import logging

logger = logging.getLogger(__name__)


class Severity(Enum):
    """Severity levels for validation rules."""
    ERROR = "error"      # Fails the pipeline
    WARNING = "warning"  # Logs warning but continues
    INFO = "info"        # Informational only


@dataclass
class ValidationRule:
    """Represents a data validation rule."""
    name: str
    description: str
    check_func: Callable[[DataFrame], DataFrame]
    severity: Severity = Severity.ERROR
    threshold: float = 0.0  # Allowed failure percentage
    column: Optional[str] = None


@dataclass
class ValidationResult:
    """Result of a validation check."""
    rule: ValidationRule
    passed: bool
    failed_count: int
    total_count: int
    details: Dict[str, Any] = field(default_factory=dict)
    
    @property
    def failure_rate(self) -> float:
        if self.total_count == 0:
            return 0.0
        return self.failed_count / self.total_count
    
    @property
    def pass_rate(self) -> float:
        return 1 - self.failure_rate


class DataValidator:
    """Validate DataFrames against rules."""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.rules: List[ValidationRule] = []
        self.results: List[ValidationResult] = []
        self.logger = logging.getLogger(__name__)
    
    # ==================== RULE BUILDERS ====================
    
    def add_rule(self, rule: ValidationRule) -> 'DataValidator':
        """Add a validation rule."""
        self.rules.append(rule)
        return self
    
    def not_null(
        self,
        column: str,
        severity: Severity = Severity.ERROR,
        threshold: float = 0.0
    ) -> 'DataValidator':
        """Add not-null validation."""
        rule = ValidationRule(
            name=f"not_null_{column}",
            description=f"Column {column} should not contain nulls",
            check_func=lambda df: df.filter(F.col(column).isNull()),
            severity=severity,
            threshold=threshold,
            column=column
        )
        return self.add_rule(rule)
    
    def unique(
        self,
        column: str,
        severity: Severity = Severity.ERROR
    ) -> 'DataValidator':
        """Add uniqueness validation."""
        def check_unique(df):
            duplicates = df.groupBy(column).count().filter(F.col("count") > 1)
            return df.join(duplicates.select(column), column, "inner")
        
        rule = ValidationRule(
            name=f"unique_{column}",
            description=f"Column {column} should have unique values",
            check_func=check_unique,
            severity=severity,
            column=column
        )
        return self.add_rule(rule)
    
    def in_range(
        self,
        column: str,
        min_val: Any,
        max_val: Any,
        severity: Severity = Severity.ERROR,
        threshold: float = 0.0
    ) -> 'DataValidator':
        """Add range validation."""
        rule = ValidationRule(
            name=f"range_{column}",
            description=f"Column {column} should be between {min_val} and {max_val}",
            check_func=lambda df: df.filter(
                (F.col(column) < min_val) | (F.col(column) > max_val)
            ),
            severity=severity,
            threshold=threshold,
            column=column
        )
        return self.add_rule(rule)
    
    def regex_match(
        self,
        column: str,
        pattern: str,
        severity: Severity = Severity.ERROR,
        threshold: float = 0.0
    ) -> 'DataValidator':
        """Add regex pattern validation."""
        rule = ValidationRule(
            name=f"pattern_{column}",
            description=f"Column {column} should match pattern {pattern}",
            check_func=lambda df: df.filter(~F.col(column).rlike(pattern)),
            severity=severity,
            threshold=threshold,
            column=column
        )
        return self.add_rule(rule)
    
    def valid_email(
        self,
        column: str,
        severity: Severity = Severity.ERROR,
        threshold: float = 0.0
    ) -> 'DataValidator':
        """Add email validation."""
        pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        return self.regex_match(column, pattern, severity, threshold)
    
    def foreign_key(
        self,
        column: str,
        reference_df: DataFrame,
        reference_column: str,
        severity: Severity = Severity.ERROR
    ) -> 'DataValidator':
        """Add foreign key validation."""
        def check_fk(df):
            valid_keys = reference_df.select(reference_column).distinct()
            return df.join(
                valid_keys,
                df[column] == valid_keys[reference_column],
                "left_anti"
            )
        
        rule = ValidationRule(
            name=f"fk_{column}",
            description=f"Column {column} should reference valid {reference_column}",
            check_func=check_fk,
            severity=severity,
            column=column
        )
        return self.add_rule(rule)
    
    def custom(
        self,
        name: str,
        description: str,
        check_func: Callable[[DataFrame], DataFrame],
        severity: Severity = Severity.ERROR,
        threshold: float = 0.0
    ) -> 'DataValidator':
        """Add custom validation rule."""
        rule = ValidationRule(
            name=name,
            description=description,
            check_func=check_func,
            severity=severity,
            threshold=threshold
        )
        return self.add_rule(rule)
    
    # ==================== VALIDATION EXECUTION ====================
    
    def validate(self, df: DataFrame) -> List[ValidationResult]:
        """Run all validations and return results."""
        self.results = []
        total_count = df.count()
        
        for rule in self.rules:
            self.logger.info(f"Running validation: {rule.name}")
            
            try:
                failed_df = rule.check_func(df)
                failed_count = failed_df.count()
                
                failure_rate = failed_count / total_count if total_count > 0 else 0
                passed = failure_rate <= rule.threshold
                
                result = ValidationResult(
                    rule=rule,
                    passed=passed,
                    failed_count=failed_count,
                    total_count=total_count,
                    details={"threshold": rule.threshold}
                )
                
                self.results.append(result)
                
                # Log result
                status = "PASSED" if passed else "FAILED"
                self.logger.info(
                    f"  {rule.name}: {status} "
                    f"(failed: {failed_count}/{total_count}, "
                    f"rate: {failure_rate:.2%})"
                )
                
            except Exception as e:
                self.logger.error(f"Validation error for {rule.name}: {e}")
                result = ValidationResult(
                    rule=rule,
                    passed=False,
                    failed_count=total_count,
                    total_count=total_count,
                    details={"error": str(e)}
                )
                self.results.append(result)
        
        return self.results
    
    def get_summary(self) -> Dict[str, Any]:
        """Get validation summary."""
        error_failures = [
            r for r in self.results
            if not r.passed and r.rule.severity == Severity.ERROR
        ]
        warning_failures = [
            r for r in self.results
            if not r.passed and r.rule.severity == Severity.WARNING
        ]
        
        return {
            "total_rules": len(self.results),
            "passed_rules": sum(1 for r in self.results if r.passed),
            "failed_rules": sum(1 for r in self.results if not r.passed),
            "error_failures": len(error_failures),
            "warning_failures": len(warning_failures),
            "all_passed": len(error_failures) == 0
        }
    
    def raise_on_failure(self):
        """Raise exception if any ERROR severity rules failed."""
        from .exceptions import DataQualityError
        
        error_failures = [
            r for r in self.results
            if not r.passed and r.rule.severity == Severity.ERROR
        ]
        
        if error_failures:
            failed_rules = [r.rule.name for r in error_failures]
            total_failed = sum(r.failed_count for r in error_failures)
            
            raise DataQualityError(
                message=f"Data quality check failed: {len(failed_rules)} rules failed",
                failed_rules=failed_rules,
                failed_count=total_failed,
                total_count=self.results[0].total_count if self.results else 0
            )
```

---

## Part 3: Error Handler

### Step 3.1: Centralized Error Handling
```python
# src/utils/error_handler.py
from typing import Callable, Any, Optional, Dict
from functools import wraps
import traceback
import logging
from datetime import datetime
from .exceptions import PipelineException

logger = logging.getLogger(__name__)


class ErrorHandler:
    """Centralized error handling for pipeline."""
    
    def __init__(self, config: Dict[str, Any] = None):
        self.config = config or {}
        self.errors = []
        self.logger = logging.getLogger(__name__)
    
    def handle(
        self,
        exception: Exception,
        context: str = None,
        reraise: bool = True
    ):
        """Handle an exception."""
        error_record = {
            "timestamp": datetime.now().isoformat(),
            "exception_type": type(exception).__name__,
            "message": str(exception),
            "context": context,
            "traceback": traceback.format_exc()
        }
        
        self.errors.append(error_record)
        
        # Log error
        self.logger.error(
            f"Error in {context}: {type(exception).__name__}: {exception}"
        )
        
        # Send alert for critical errors
        if isinstance(exception, PipelineException):
            if exception.error_code and exception.error_code.startswith("CRITICAL"):
                self._send_alert(error_record)
        
        if reraise:
            raise
    
    def _send_alert(self, error_record: Dict):
        """Send alert for critical errors."""
        # Implement alerting (email, Slack, PagerDuty, etc.)
        self.logger.critical(f"ALERT: {error_record}")
    
    def get_error_summary(self) -> Dict[str, Any]:
        """Get summary of all errors."""
        return {
            "total_errors": len(self.errors),
            "error_types": list(set(e["exception_type"] for e in self.errors)),
            "errors": self.errors
        }


def with_error_handling(
    context: str = None,
    handler: ErrorHandler = None,
    default_return: Any = None,
    reraise: bool = True
):
    """Decorator for error handling."""
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs):
            ctx = context or func.__name__
            err_handler = handler or ErrorHandler()
            
            try:
                return func(*args, **kwargs)
            except Exception as e:
                err_handler.handle(e, ctx, reraise=reraise)
                return default_return
        
        return wrapper
    return decorator


def retry(
    max_attempts: int = 3,
    delay: float = 1.0,
    backoff: float = 2.0,
    exceptions: tuple = (Exception,)
):
    """Decorator for retrying failed operations."""
    import time
    
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            current_delay = delay
            
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt < max_attempts - 1:
                        logger.warning(
                            f"Attempt {attempt + 1}/{max_attempts} failed: {e}. "
                            f"Retrying in {current_delay}s..."
                        )
                        time.sleep(current_delay)
                        current_delay *= backoff
            
            raise last_exception
        
        return wrapper
    return decorator
```

---

## Part 4: Data Quarantine

### Step 4.1: Quarantine Manager
```python
# src/utils/quarantine.py
from typing import Dict, List, Any
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class QuarantineManager:
    """Manage quarantined (invalid) records."""
    
    def __init__(self, spark: SparkSession, quarantine_path: str):
        self.spark = spark
        self.quarantine_path = quarantine_path
        self.logger = logging.getLogger(__name__)
    
    def quarantine(
        self,
        df: DataFrame,
        validation_rules: Dict[str, Any],
        source_name: str
    ) -> tuple:
        """
        Separate valid and invalid records.
        
        Args:
            df: Input DataFrame
            validation_rules: Dict of rule_name -> condition
            source_name: Name of the data source
        
        Returns:
            (valid_df, invalid_df)
        """
        # Add validation columns
        for rule_name, condition in validation_rules.items():
            df = df.withColumn(f"_failed_{rule_name}", ~condition)
        
        # Combine all failures
        failure_cols = [c for c in df.columns if c.startswith("_failed_")]
        
        # Create error array
        error_conditions = [
            F.when(F.col(c), F.lit(c.replace("_failed_", "")))
            for c in failure_cols
        ]
        
        df = df.withColumn(
            "_validation_errors",
            F.array_remove(F.array(*error_conditions), None)
        )
        
        df = df.withColumn(
            "_is_valid",
            F.size("_validation_errors") == 0
        )
        
        # Split data
        valid_df = df.filter(F.col("_is_valid")).drop(
            *failure_cols, "_validation_errors", "_is_valid"
        )
        
        invalid_df = df.filter(~F.col("_is_valid")).select(
            *[c for c in df.columns if not c.startswith("_failed_")],
        )
        
        # Add quarantine metadata
        invalid_df = invalid_df \
            .withColumn("_quarantine_source", F.lit(source_name)) \
            .withColumn("_quarantine_timestamp", F.current_timestamp()) \
            .withColumn("_quarantine_date", F.current_date())
        
        # Log stats
        valid_count = valid_df.count()
        invalid_count = invalid_df.count()
        total = valid_count + invalid_count
        
        self.logger.info(
            f"Quarantine results for {source_name}: "
            f"valid={valid_count}, invalid={invalid_count}, "
            f"rate={invalid_count/total:.2%}"
        )
        
        return valid_df, invalid_df
    
    def save_quarantine(
        self,
        df: DataFrame,
        source_name: str
    ):
        """Save quarantined records."""
        path = f"{self.quarantine_path}/{source_name}"
        
        df.write \
            .mode("append") \
            .partitionBy("_quarantine_date") \
            .parquet(path)
        
        self.logger.info(f"Saved {df.count()} records to quarantine: {path}")
    
    def get_quarantine_stats(self, source_name: str = None) -> DataFrame:
        """Get quarantine statistics."""
        if source_name:
            path = f"{self.quarantine_path}/{source_name}"
        else:
            path = self.quarantine_path
        
        try:
            df = self.spark.read.parquet(path)
            
            stats = df.groupBy(
                "_quarantine_source",
                "_quarantine_date"
            ).agg(
                F.count("*").alias("record_count"),
                F.collect_set("_validation_errors").alias("error_types")
            ).orderBy(
                "_quarantine_source",
                F.desc("_quarantine_date")
            )
            
            return stats
        except Exception as e:
            self.logger.warning(f"No quarantine data found: {e}")
            return None
    
    def reprocess_quarantine(
        self,
        source_name: str,
        date: str,
        processor_func
    ) -> DataFrame:
        """Attempt to reprocess quarantined records."""
        path = f"{self.quarantine_path}/{source_name}"
        
        df = self.spark.read.parquet(path) \
            .filter(F.col("_quarantine_date") == date)
        
        # Remove quarantine metadata
        clean_df = df.drop(
            "_validation_errors",
            "_is_valid",
            "_quarantine_source",
            "_quarantine_timestamp",
            "_quarantine_date"
        )
        
        # Attempt reprocessing
        return processor_func(clean_df)
```

---

## Part 5: Quality Monitoring

### Step 5.1: Quality Monitor
```python
# src/utils/quality_monitor.py
from typing import Dict, List, Any
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class QualityMonitor:
    """Monitor data quality metrics over time."""
    
    def __init__(self, spark: SparkSession, metrics_path: str):
        self.spark = spark
        self.metrics_path = metrics_path
        self.logger = logging.getLogger(__name__)
    
    def compute_metrics(
        self,
        df: DataFrame,
        dataset_name: str
    ) -> Dict[str, Any]:
        """Compute quality metrics for a DataFrame."""
        total_rows = df.count()
        
        metrics = {
            "dataset_name": dataset_name,
            "timestamp": datetime.now().isoformat(),
            "total_rows": total_rows,
            "columns": []
        }
        
        for column in df.columns:
            if column.startswith("_"):
                continue
            
            col_metrics = {
                "column_name": column,
                "null_count": df.filter(F.col(column).isNull()).count(),
                "distinct_count": df.select(column).distinct().count(),
            }
            
            col_metrics["null_rate"] = col_metrics["null_count"] / total_rows if total_rows > 0 else 0
            col_metrics["cardinality"] = col_metrics["distinct_count"] / total_rows if total_rows > 0 else 0
            
            # Type-specific metrics
            dtype = str(df.schema[column].dataType)
            
            if "Integer" in dtype or "Double" in dtype or "Long" in dtype:
                stats = df.agg(
                    F.min(column).alias("min"),
                    F.max(column).alias("max"),
                    F.avg(column).alias("mean"),
                    F.stddev(column).alias("stddev")
                ).collect()[0]
                
                col_metrics.update({
                    "min": float(stats["min"]) if stats["min"] else None,
                    "max": float(stats["max"]) if stats["max"] else None,
                    "mean": float(stats["mean"]) if stats["mean"] else None,
                    "stddev": float(stats["stddev"]) if stats["stddev"] else None,
                })
            
            metrics["columns"].append(col_metrics)
        
        return metrics
    
    def save_metrics(self, metrics: Dict[str, Any]):
        """Save metrics to storage."""
        # Flatten column metrics
        rows = []
        for col_metrics in metrics["columns"]:
            row = {
                "dataset_name": metrics["dataset_name"],
                "timestamp": metrics["timestamp"],
                "total_rows": metrics["total_rows"],
                **col_metrics
            }
            rows.append(row)
        
        metrics_df = self.spark.createDataFrame(rows)
        
        metrics_df.write \
            .mode("append") \
            .partitionBy("dataset_name") \
            .parquet(f"{self.metrics_path}/column_metrics")
    
    def check_anomalies(
        self,
        current_metrics: Dict[str, Any],
        thresholds: Dict[str, float] = None
    ) -> List[Dict[str, Any]]:
        """Check for quality anomalies."""
        thresholds = thresholds or {
            "null_rate_max": 0.1,
            "row_count_change_max": 0.5,
        }
        
        anomalies = []
        
        # Check column-level metrics
        for col in current_metrics["columns"]:
            if col["null_rate"] > thresholds["null_rate_max"]:
                anomalies.append({
                    "type": "high_null_rate",
                    "column": col["column_name"],
                    "value": col["null_rate"],
                    "threshold": thresholds["null_rate_max"]
                })
        
        # Check historical trends
        try:
            historical = self.spark.read.parquet(
                f"{self.metrics_path}/column_metrics"
            ).filter(
                F.col("dataset_name") == current_metrics["dataset_name"]
            ).orderBy(F.desc("timestamp")).limit(10)
            
            avg_rows = historical.agg(F.avg("total_rows")).collect()[0][0]
            
            if avg_rows:
                change = abs(current_metrics["total_rows"] - avg_rows) / avg_rows
                if change > thresholds["row_count_change_max"]:
                    anomalies.append({
                        "type": "row_count_anomaly",
                        "current": current_metrics["total_rows"],
                        "historical_avg": avg_rows,
                        "change": change
                    })
        except Exception:
            pass
        
        return anomalies
    
    def get_quality_trend(
        self,
        dataset_name: str,
        days: int = 30
    ) -> DataFrame:
        """Get quality metrics trend."""
        from datetime import timedelta
        
        start_date = (datetime.now() - timedelta(days=days)).isoformat()
        
        return self.spark.read.parquet(
            f"{self.metrics_path}/column_metrics"
        ).filter(
            (F.col("dataset_name") == dataset_name) &
            (F.col("timestamp") >= start_date)
        ).orderBy("timestamp")
```

---

## Part 6: Integration Example

### Step 6.1: Pipeline with Quality Checks
```python
# Example: Pipeline with comprehensive error handling and quality checks
from pyspark.sql import SparkSession
from src.utils.validators import DataValidator, Severity
from src.utils.quarantine import QuarantineManager
from src.utils.quality_monitor import QualityMonitor
from src.utils.error_handler import ErrorHandler, with_error_handling, retry
from src.utils.exceptions import DataQualityError

spark = SparkSession.builder.appName("QualityPipeline").getOrCreate()

# Initialize components
validator = DataValidator(spark)
quarantine = QuarantineManager(spark, "data/quarantine")
monitor = QualityMonitor(spark, "data/metrics")
error_handler = ErrorHandler()


@with_error_handling(context="data_ingestion")
@retry(max_attempts=3, delay=2.0)
def ingest_data(path: str):
    """Ingest data with retry logic."""
    return spark.read.csv(path, header=True, inferSchema=True)


def process_with_quality_checks(df, source_name: str):
    """Process data with quality checks."""
    
    # Step 1: Compute and save metrics
    metrics = monitor.compute_metrics(df, source_name)
    monitor.save_metrics(metrics)
    
    # Step 2: Check for anomalies
    anomalies = monitor.check_anomalies(metrics)
    if anomalies:
        for anomaly in anomalies:
            logger.warning(f"Quality anomaly detected: {anomaly}")
    
    # Step 3: Validate data
    validator \
        .not_null("customer_id") \
        .not_null("email") \
        .valid_email("email", threshold=0.05) \
        .in_range("age", 0, 120, severity=Severity.WARNING)
    
    results = validator.validate(df)
    summary = validator.get_summary()
    
    # Step 4: Quarantine invalid records
    validation_rules = {
        "customer_id_present": F.col("customer_id").isNotNull(),
        "valid_email": F.col("email").rlike(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"),
        "valid_age": F.col("age").between(0, 120),
    }
    
    valid_df, invalid_df = quarantine.quarantine(df, validation_rules, source_name)
    
    # Step 5: Save quarantine data
    if invalid_df.count() > 0:
        quarantine.save_quarantine(invalid_df, source_name)
    
    # Step 6: Check quality gate
    if not summary["all_passed"]:
        raise DataQualityError(
            message=f"Quality gate failed for {source_name}",
            failed_rules=[r.rule.name for r in results if not r.passed]
        )
    
    return valid_df


# Run pipeline
try:
    raw_df = ingest_data("data/raw/customers.csv")
    clean_df = process_with_quality_checks(raw_df, "customers")
    
    # Continue with transformation and loading
    logger.info(f"Successfully processed {clean_df.count()} valid records")
    
except DataQualityError as e:
    logger.error(f"Quality check failed: {e}")
    # Handle quality failure (alert, skip, etc.)
    
except Exception as e:
    error_handler.handle(e, "pipeline_execution")
```

---

## Exercises

1. Create custom validation rules for orders data
2. Implement quarantine with reprocessing
3. Build a quality dashboard
4. Set up alerting for anomalies

---

## Summary
- Created custom exception hierarchy
- Built comprehensive data validators
- Implemented error handling decorators
- Created quarantine management
- Built quality monitoring
- Integrated quality checks into pipeline

---

## Next Lab
In the next lab, we'll write tests for our pipeline components.
