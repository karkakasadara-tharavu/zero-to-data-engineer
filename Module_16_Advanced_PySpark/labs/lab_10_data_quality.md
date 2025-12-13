# Lab 10: Data Quality and Validation

## Overview
Learn to implement data quality checks and validation in PySpark pipelines.

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Implement data quality rules
- ✅ Validate schemas and data types
- ✅ Handle data quality issues
- ✅ Build quality monitoring pipelines
- ✅ Use Great Expectations with PySpark

---

## Part 1: Schema Validation

### Step 1.1: Expected Schema
```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("Data Quality") \
    .getOrCreate()

# Define expected schema
expected_schema = StructType([
    StructField("customer_id", IntegerType(), nullable=False),
    StructField("email", StringType(), nullable=False),
    StructField("name", StringType(), nullable=True),
    StructField("age", IntegerType(), nullable=True),
    StructField("created_date", DateType(), nullable=False),
    StructField("amount", DoubleType(), nullable=True),
])
```

### Step 1.2: Schema Comparison
```python
def validate_schema(df, expected_schema, strict=True):
    """Validate DataFrame schema against expected schema."""
    actual_schema = df.schema
    errors = []
    
    # Check each expected field
    for expected_field in expected_schema.fields:
        actual_field = next(
            (f for f in actual_schema.fields if f.name == expected_field.name),
            None
        )
        
        if actual_field is None:
            errors.append(f"Missing field: {expected_field.name}")
            continue
        
        # Check data type
        if actual_field.dataType != expected_field.dataType:
            errors.append(
                f"Type mismatch for {expected_field.name}: "
                f"expected {expected_field.dataType}, got {actual_field.dataType}"
            )
        
        # Check nullable
        if not expected_field.nullable and actual_field.nullable:
            errors.append(f"Field {expected_field.name} should not be nullable")
    
    # Check for extra fields in strict mode
    if strict:
        expected_names = {f.name for f in expected_schema.fields}
        for actual_field in actual_schema.fields:
            if actual_field.name not in expected_names:
                errors.append(f"Unexpected field: {actual_field.name}")
    
    return len(errors) == 0, errors


# Usage
df = spark.read.parquet("data/customers.parquet")
is_valid, errors = validate_schema(df, expected_schema)

if not is_valid:
    for error in errors:
        print(f"Schema Error: {error}")
```

---

## Part 2: Data Quality Rules

### Step 2.1: Quality Rules Framework
```python
from pyspark.sql import DataFrame
from pyspark.sql import functions as F
from dataclasses import dataclass
from typing import List, Callable
from enum import Enum

class RuleSeverity(Enum):
    ERROR = "error"      # Fails the pipeline
    WARNING = "warning"  # Logs but continues
    INFO = "info"        # Informational only


@dataclass
class QualityRule:
    name: str
    description: str
    column: str
    check: Callable[[DataFrame], DataFrame]
    severity: RuleSeverity = RuleSeverity.ERROR
    threshold: float = 0.0  # Allowed failure percentage


@dataclass
class RuleResult:
    rule: QualityRule
    total_rows: int
    failed_rows: int
    pass_rate: float
    passed: bool
```

### Step 2.2: Common Validation Rules
```python
class DataQualityRules:
    """Factory for common data quality rules."""
    
    @staticmethod
    def not_null(column: str, severity: RuleSeverity = RuleSeverity.ERROR) -> QualityRule:
        """Check that column has no null values."""
        return QualityRule(
            name=f"not_null_{column}",
            description=f"Column {column} should not be null",
            column=column,
            check=lambda df: df.filter(F.col(column).isNull()),
            severity=severity
        )
    
    @staticmethod
    def unique(column: str, severity: RuleSeverity = RuleSeverity.ERROR) -> QualityRule:
        """Check that column values are unique."""
        def check_unique(df):
            duplicates = df.groupBy(column).count().filter(F.col("count") > 1)
            return df.join(duplicates.select(column), column, "inner")
        
        return QualityRule(
            name=f"unique_{column}",
            description=f"Column {column} should have unique values",
            column=column,
            check=check_unique,
            severity=severity
        )
    
    @staticmethod
    def in_range(column: str, min_val, max_val, 
                 severity: RuleSeverity = RuleSeverity.ERROR) -> QualityRule:
        """Check that numeric values are within range."""
        return QualityRule(
            name=f"in_range_{column}",
            description=f"Column {column} should be between {min_val} and {max_val}",
            column=column,
            check=lambda df: df.filter(
                (F.col(column) < min_val) | (F.col(column) > max_val)
            ),
            severity=severity
        )
    
    @staticmethod
    def regex_match(column: str, pattern: str, 
                    severity: RuleSeverity = RuleSeverity.ERROR) -> QualityRule:
        """Check that string values match regex pattern."""
        return QualityRule(
            name=f"regex_{column}",
            description=f"Column {column} should match pattern {pattern}",
            column=column,
            check=lambda df: df.filter(~F.col(column).rlike(pattern)),
            severity=severity
        )
    
    @staticmethod
    def valid_email(column: str, 
                    severity: RuleSeverity = RuleSeverity.ERROR) -> QualityRule:
        """Check that values are valid email addresses."""
        email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        return DataQualityRules.regex_match(column, email_pattern, severity)
    
    @staticmethod
    def positive_value(column: str, 
                       severity: RuleSeverity = RuleSeverity.ERROR) -> QualityRule:
        """Check that numeric values are positive."""
        return QualityRule(
            name=f"positive_{column}",
            description=f"Column {column} should be positive",
            column=column,
            check=lambda df: df.filter(F.col(column) <= 0),
            severity=severity
        )
    
    @staticmethod
    def date_in_range(column: str, min_date: str, max_date: str,
                      severity: RuleSeverity = RuleSeverity.ERROR) -> QualityRule:
        """Check that dates are within range."""
        return QualityRule(
            name=f"date_range_{column}",
            description=f"Column {column} should be between {min_date} and {max_date}",
            column=column,
            check=lambda df: df.filter(
                (F.col(column) < F.lit(min_date)) | 
                (F.col(column) > F.lit(max_date))
            ),
            severity=severity
        )
```

---

## Part 3: Quality Checker

### Step 3.1: Quality Engine
```python
class DataQualityChecker:
    """Execute data quality checks on DataFrames."""
    
    def __init__(self, df: DataFrame):
        self.df = df
        self.rules: List[QualityRule] = []
        self.results: List[RuleResult] = []
    
    def add_rule(self, rule: QualityRule) -> 'DataQualityChecker':
        """Add a quality rule."""
        self.rules.append(rule)
        return self
    
    def add_rules(self, rules: List[QualityRule]) -> 'DataQualityChecker':
        """Add multiple rules."""
        self.rules.extend(rules)
        return self
    
    def run(self) -> List[RuleResult]:
        """Execute all quality rules."""
        total_rows = self.df.count()
        self.results = []
        
        for rule in self.rules:
            failed_df = rule.check(self.df)
            failed_count = failed_df.count()
            pass_rate = 1 - (failed_count / total_rows) if total_rows > 0 else 1
            
            passed = pass_rate >= (1 - rule.threshold)
            
            result = RuleResult(
                rule=rule,
                total_rows=total_rows,
                failed_rows=failed_count,
                pass_rate=pass_rate,
                passed=passed
            )
            self.results.append(result)
        
        return self.results
    
    def summary(self) -> DataFrame:
        """Get summary as DataFrame."""
        summary_data = [
            (
                r.rule.name,
                r.rule.description,
                r.rule.severity.value,
                r.total_rows,
                r.failed_rows,
                round(r.pass_rate * 100, 2),
                "PASSED" if r.passed else "FAILED"
            )
            for r in self.results
        ]
        
        schema = ["rule_name", "description", "severity", 
                  "total_rows", "failed_rows", "pass_rate_pct", "status"]
        
        return self.df.sparkSession.createDataFrame(summary_data, schema)
    
    def get_failed_records(self, rule_name: str) -> DataFrame:
        """Get records that failed a specific rule."""
        rule = next((r for r in self.rules if r.name == rule_name), None)
        if rule is None:
            raise ValueError(f"Rule not found: {rule_name}")
        return rule.check(self.df)
    
    def has_errors(self) -> bool:
        """Check if any ERROR severity rules failed."""
        return any(
            not r.passed and r.rule.severity == RuleSeverity.ERROR
            for r in self.results
        )
```

### Step 3.2: Usage Example
```python
# Sample data
data = [
    (1, "alice@email.com", "Alice", 25, "2024-01-01", 100.0),
    (2, "invalid-email", "Bob", -5, "2024-01-02", 200.0),
    (3, None, "Charlie", 30, "2024-01-03", -50.0),
    (4, "david@email.com", "David", 150, "2025-12-31", 300.0),
]
columns = ["customer_id", "email", "name", "age", "created_date", "amount"]
df = spark.createDataFrame(data, columns)

# Define rules
rules = [
    DataQualityRules.not_null("email"),
    DataQualityRules.valid_email("email"),
    DataQualityRules.in_range("age", 0, 120),
    DataQualityRules.positive_value("amount"),
    DataQualityRules.unique("customer_id"),
]

# Run checks
checker = DataQualityChecker(df).add_rules(rules)
results = checker.run()

# Show summary
checker.summary().show(truncate=False)

# Check for failures
if checker.has_errors():
    print("Data quality check FAILED!")
    # Get failed records for investigation
    failed_emails = checker.get_failed_records("regex_email")
    failed_emails.show()
```

---

## Part 4: Data Profiling

### Step 4.1: Column Statistics
```python
def profile_dataframe(df: DataFrame) -> DataFrame:
    """Generate data profile for DataFrame."""
    profiles = []
    
    for column in df.columns:
        col_type = str(df.schema[column].dataType)
        
        # Basic stats
        total = df.count()
        null_count = df.filter(F.col(column).isNull()).count()
        distinct_count = df.select(column).distinct().count()
        
        profile = {
            "column": column,
            "data_type": col_type,
            "total_count": total,
            "null_count": null_count,
            "null_pct": round(null_count / total * 100, 2) if total > 0 else 0,
            "distinct_count": distinct_count,
            "unique_pct": round(distinct_count / total * 100, 2) if total > 0 else 0,
        }
        
        # Numeric stats
        if "Integer" in col_type or "Double" in col_type or "Long" in col_type:
            stats = df.agg(
                F.min(column).alias("min"),
                F.max(column).alias("max"),
                F.mean(column).alias("mean"),
                F.stddev(column).alias("stddev"),
            ).collect()[0]
            
            profile.update({
                "min": stats["min"],
                "max": stats["max"],
                "mean": round(stats["mean"], 2) if stats["mean"] else None,
                "stddev": round(stats["stddev"], 2) if stats["stddev"] else None,
            })
        
        profiles.append(profile)
    
    return spark.createDataFrame(profiles)


# Usage
profile_df = profile_dataframe(df)
profile_df.show(truncate=False)
```

### Step 4.2: Value Distribution
```python
def analyze_value_distribution(df: DataFrame, column: str, top_n: int = 10):
    """Analyze value distribution for a column."""
    distribution = df.groupBy(column) \
        .count() \
        .orderBy(F.desc("count")) \
        .limit(top_n)
    
    total = df.count()
    distribution = distribution.withColumn(
        "percentage",
        F.round(F.col("count") / F.lit(total) * 100, 2)
    )
    
    return distribution


# Usage
email_dist = analyze_value_distribution(df, "email")
email_dist.show()
```

---

## Part 5: Quarantine Pattern

### Step 5.1: Separate Good and Bad Data
```python
class DataQuarantine:
    """Separate valid and invalid records."""
    
    def __init__(self, df: DataFrame):
        self.df = df
        self.rules = []
    
    def add_rule(self, rule: QualityRule):
        self.rules.append(rule)
        return self
    
    def process(self):
        """Process DataFrame and separate good/bad records."""
        # Add validation columns
        validated = self.df
        
        error_conditions = []
        for rule in self.rules:
            # Create column with validation result
            failed_df = rule.check(self.df)
            failed_ids = failed_df.select("customer_id").distinct()
            
            validated = validated.withColumn(
                f"_failed_{rule.name}",
                F.col("customer_id").isin(
                    [row["customer_id"] for row in failed_ids.collect()]
                )
            )
            error_conditions.append(F.col(f"_failed_{rule.name}"))
        
        # Combine all error conditions
        validated = validated.withColumn(
            "_has_errors",
            F.array([F.when(c, F.lit(1)).otherwise(F.lit(0)) for c in error_conditions])
        )
        validated = validated.withColumn(
            "_is_valid",
            F.expr("aggregate(_has_errors, 0, (acc, x) -> acc + x)") == 0
        )
        
        # Split into valid and quarantine
        valid_df = validated.filter(F.col("_is_valid")).drop(
            *[c for c in validated.columns if c.startswith("_")]
        )
        quarantine_df = validated.filter(~F.col("_is_valid"))
        
        return valid_df, quarantine_df
```

### Step 5.2: Simplified Quarantine
```python
def quarantine_invalid_records(df: DataFrame, validation_rules: dict):
    """
    Quarantine records failing validation.
    
    Args:
        df: Input DataFrame
        validation_rules: Dict of column -> condition
    
    Returns:
        (valid_df, quarantine_df, error_df)
    """
    # Add validation column
    error_checks = []
    
    for rule_name, condition in validation_rules.items():
        df = df.withColumn(f"_err_{rule_name}", ~condition)
        error_checks.append(
            F.when(F.col(f"_err_{rule_name}"), F.lit(rule_name))
        )
    
    # Combine errors
    df = df.withColumn(
        "_errors",
        F.array_remove(F.array(*error_checks), None)
    )
    df = df.withColumn("_is_valid", F.size("_errors") == 0)
    
    # Split data
    valid_df = df.filter(F.col("_is_valid")).drop(
        *[c for c in df.columns if c.startswith("_")]
    )
    
    quarantine_df = df.filter(~F.col("_is_valid")).select(
        *[c for c in df.columns if not c.startswith("_err_")],
        F.col("_errors").alias("validation_errors")
    ).drop("_is_valid")
    
    return valid_df, quarantine_df


# Usage
rules = {
    "email_not_null": F.col("email").isNotNull(),
    "valid_email": F.col("email").rlike(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"),
    "positive_age": F.col("age") > 0,
    "positive_amount": F.col("amount") > 0,
}

valid_df, quarantine_df = quarantine_invalid_records(df, rules)

print("Valid records:")
valid_df.show()

print("Quarantined records:")
quarantine_df.show(truncate=False)
```

---

## Part 6: Data Quality Metrics

### Step 6.1: Quality Scores
```python
def calculate_quality_score(df: DataFrame, rules: List[QualityRule]) -> dict:
    """Calculate overall data quality score."""
    checker = DataQualityChecker(df).add_rules(rules)
    results = checker.run()
    
    total_rules = len(results)
    passed_rules = sum(1 for r in results if r.passed)
    
    # Weighted score based on severity
    severity_weights = {
        RuleSeverity.ERROR: 1.0,
        RuleSeverity.WARNING: 0.5,
        RuleSeverity.INFO: 0.1,
    }
    
    weighted_sum = 0
    weight_total = 0
    
    for result in results:
        weight = severity_weights[result.rule.severity]
        weighted_sum += result.pass_rate * weight
        weight_total += weight
    
    weighted_score = weighted_sum / weight_total if weight_total > 0 else 0
    
    return {
        "total_rules": total_rules,
        "passed_rules": passed_rules,
        "failed_rules": total_rules - passed_rules,
        "pass_rate": passed_rules / total_rules if total_rules > 0 else 1,
        "weighted_quality_score": round(weighted_score * 100, 2),
        "timestamp": datetime.now().isoformat(),
    }


# Usage
from datetime import datetime

score = calculate_quality_score(df, rules)
print(f"Data Quality Score: {score['weighted_quality_score']}%")
```

### Step 6.2: Historical Tracking
```python
def log_quality_metrics(metrics: dict, output_path: str, spark):
    """Log quality metrics for historical tracking."""
    metrics_df = spark.createDataFrame([metrics])
    
    # Append to metrics history
    metrics_df.write \
        .mode("append") \
        .partitionBy("timestamp") \
        .parquet(f"{output_path}/quality_metrics")


def get_quality_trend(metrics_path: str, spark, days: int = 30):
    """Get quality trend over time."""
    from datetime import datetime, timedelta
    
    start_date = (datetime.now() - timedelta(days=days)).isoformat()
    
    trend = spark.read.parquet(metrics_path) \
        .filter(F.col("timestamp") >= start_date) \
        .orderBy("timestamp")
    
    return trend
```

---

## Part 7: Great Expectations Integration

### Step 7.1: Setup
```python
# pip install great-expectations

import great_expectations as gx
from great_expectations.dataset import SparkDFDataset

# Create GX dataset from PySpark DataFrame
ge_df = SparkDFDataset(df)
```

### Step 7.2: Expectations
```python
# Define expectations
ge_df.expect_column_to_exist("customer_id")
ge_df.expect_column_values_to_not_be_null("customer_id")
ge_df.expect_column_values_to_be_unique("customer_id")

ge_df.expect_column_values_to_not_be_null("email")
ge_df.expect_column_values_to_match_regex(
    "email",
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
)

ge_df.expect_column_values_to_be_between("age", min_value=0, max_value=120)
ge_df.expect_column_values_to_be_in_set("status", ["active", "inactive", "pending"])

# Get validation results
results = ge_df.validate()

print(f"Success: {results['success']}")
for result in results['results']:
    print(f"  {result['expectation_config']['expectation_type']}: {result['success']}")
```

---

## Part 8: Automated Quality Pipeline

### Step 8.1: Complete Pipeline
```python
from pyspark.sql import SparkSession
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DataQuality")


class DataQualityPipeline:
    """Complete data quality pipeline."""
    
    def __init__(self, spark: SparkSession, config: dict):
        self.spark = spark
        self.config = config
        self.metrics = {}
    
    def run(self, input_path: str, output_path: str):
        """Run complete quality pipeline."""
        logger.info(f"Starting quality pipeline for {input_path}")
        
        # Step 1: Read data
        df = self.spark.read.parquet(input_path)
        self.metrics["input_count"] = df.count()
        logger.info(f"Read {self.metrics['input_count']} records")
        
        # Step 2: Schema validation
        schema_valid, schema_errors = validate_schema(
            df, 
            self.config["expected_schema"]
        )
        if not schema_valid:
            logger.error(f"Schema validation failed: {schema_errors}")
            raise ValueError(f"Schema validation failed: {schema_errors}")
        logger.info("Schema validation passed")
        
        # Step 3: Data quality checks
        rules = self.config["quality_rules"]
        checker = DataQualityChecker(df).add_rules(rules)
        checker.run()
        
        summary = checker.summary()
        summary.show(truncate=False)
        
        # Step 4: Quarantine bad records
        valid_df, quarantine_df = quarantine_invalid_records(
            df, 
            self.config["validation_rules"]
        )
        
        self.metrics["valid_count"] = valid_df.count()
        self.metrics["quarantine_count"] = quarantine_df.count()
        
        logger.info(f"Valid: {self.metrics['valid_count']}, "
                    f"Quarantined: {self.metrics['quarantine_count']}")
        
        # Step 5: Write outputs
        valid_df.write.mode("overwrite").parquet(f"{output_path}/valid")
        quarantine_df.write.mode("overwrite").parquet(f"{output_path}/quarantine")
        
        # Step 6: Calculate and log metrics
        self.metrics["quality_score"] = calculate_quality_score(df, rules)
        self.metrics["timestamp"] = datetime.now().isoformat()
        
        # Step 7: Check quality gate
        if checker.has_errors():
            logger.error("Quality gate FAILED")
            return False
        
        logger.info("Quality gate PASSED")
        return True


# Usage
config = {
    "expected_schema": expected_schema,
    "quality_rules": rules,
    "validation_rules": {
        "email_not_null": F.col("email").isNotNull(),
        "valid_age": F.col("age").between(0, 120),
    }
}

pipeline = DataQualityPipeline(spark, config)
success = pipeline.run("data/input", "data/output")

if not success:
    raise Exception("Data quality check failed!")
```

---

## Exercises

1. Create quality rules for a customer dataset
2. Build a profiling report for a DataFrame
3. Implement quarantine pattern for invalid records
4. Create a quality monitoring dashboard

---

## Summary
- Define and validate schemas
- Create reusable quality rules
- Profile data for insights
- Quarantine invalid records
- Track quality metrics over time
- Build automated quality pipelines
