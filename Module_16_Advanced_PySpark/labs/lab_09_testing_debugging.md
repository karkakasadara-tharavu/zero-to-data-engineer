# Lab 09: Testing and Debugging PySpark

## Overview
Learn to write tests and debug PySpark applications effectively.

**Duration**: 2.5 hours  
**Difficulty**: ⭐⭐⭐⭐ Expert

---

## Learning Objectives
- ✅ Write unit tests for PySpark code
- ✅ Use pytest with PySpark
- ✅ Debug transformations and jobs
- ✅ Handle and log errors properly
- ✅ Use local mode for testing

---

## Part 1: Testing Setup

### Step 1.1: Project Structure
```
spark_project/
├── src/
│   ├── __init__.py
│   ├── transformations.py
│   └── utils.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   └── test_transformations.py
├── requirements.txt
└── pytest.ini
```

### Step 1.2: Requirements
```txt
# requirements.txt
pyspark==3.4.0
pytest==7.4.0
pytest-cov==4.1.0
chispa==0.9.4
```

### Step 1.3: Pytest Configuration
```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
addopts = -v --tb=short
filterwarnings = ignore::DeprecationWarning
```

---

## Part 2: SparkSession Fixture

### Step 2.1: Basic Fixture
```python
# tests/conftest.py
import pytest
from pyspark.sql import SparkSession

@pytest.fixture(scope="session")
def spark():
    """Create SparkSession for testing."""
    spark = SparkSession.builder \
        .master("local[2]") \
        .appName("PySpark-Tests") \
        .config("spark.sql.shuffle.partitions", "2") \
        .config("spark.default.parallelism", "2") \
        .config("spark.ui.enabled", "false") \
        .config("spark.sql.warehouse.dir", "/tmp/spark-warehouse") \
        .getOrCreate()
    
    yield spark
    spark.stop()
```

### Step 2.2: Advanced Fixture with Delta Lake
```python
# tests/conftest.py
import pytest
from pyspark.sql import SparkSession
import tempfile
import shutil

@pytest.fixture(scope="session")
def spark():
    """Create SparkSession with Delta Lake for testing."""
    warehouse_dir = tempfile.mkdtemp()
    
    spark = SparkSession.builder \
        .master("local[2]") \
        .appName("PySpark-Tests") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .config("spark.sql.shuffle.partitions", "2") \
        .config("spark.sql.warehouse.dir", warehouse_dir) \
        .config("spark.ui.enabled", "false") \
        .getOrCreate()
    
    yield spark
    
    spark.stop()
    shutil.rmtree(warehouse_dir, ignore_errors=True)
```

---

## Part 3: Writing Unit Tests

### Step 3.1: Code to Test
```python
# src/transformations.py
from pyspark.sql import DataFrame
from pyspark.sql import functions as F

def clean_names(df: DataFrame, column: str) -> DataFrame:
    """Clean and standardize name column."""
    return df.withColumn(
        column,
        F.initcap(F.trim(F.col(column)))
    )

def calculate_total(df: DataFrame) -> DataFrame:
    """Calculate total from quantity and price."""
    return df.withColumn(
        "total",
        F.col("quantity") * F.col("price")
    )

def filter_active_users(df: DataFrame) -> DataFrame:
    """Filter only active users."""
    return df.filter(F.col("status") == "active")

def add_age_category(df: DataFrame) -> DataFrame:
    """Categorize users by age."""
    return df.withColumn(
        "age_category",
        F.when(F.col("age") < 18, "minor")
        .when(F.col("age") < 65, "adult")
        .otherwise("senior")
    )
```

### Step 3.2: Basic Tests
```python
# tests/test_transformations.py
import pytest
from pyspark.sql import Row
from src.transformations import (
    clean_names, 
    calculate_total, 
    filter_active_users,
    add_age_category
)

class TestCleanNames:
    """Tests for clean_names transformation."""
    
    def test_clean_names_basic(self, spark):
        # Arrange
        data = [Row(name="  john doe  "), Row(name="JANE SMITH")]
        df = spark.createDataFrame(data)
        
        # Act
        result = clean_names(df, "name")
        
        # Assert
        result_list = result.collect()
        assert result_list[0]["name"] == "John Doe"
        assert result_list[1]["name"] == "Jane Smith"
    
    def test_clean_names_empty_string(self, spark):
        data = [Row(name="")]
        df = spark.createDataFrame(data)
        
        result = clean_names(df, "name")
        
        assert result.collect()[0]["name"] == ""
    
    def test_clean_names_null(self, spark):
        data = [Row(name=None)]
        df = spark.createDataFrame(data)
        
        result = clean_names(df, "name")
        
        assert result.collect()[0]["name"] is None


class TestCalculateTotal:
    """Tests for calculate_total transformation."""
    
    def test_calculate_total(self, spark):
        data = [
            Row(product="A", quantity=2, price=10.0),
            Row(product="B", quantity=3, price=20.0),
        ]
        df = spark.createDataFrame(data)
        
        result = calculate_total(df)
        
        totals = [row["total"] for row in result.collect()]
        assert totals == [20.0, 60.0]
    
    def test_calculate_total_zero_quantity(self, spark):
        data = [Row(product="A", quantity=0, price=10.0)]
        df = spark.createDataFrame(data)
        
        result = calculate_total(df)
        
        assert result.collect()[0]["total"] == 0.0


class TestFilterActiveUsers:
    """Tests for filter_active_users transformation."""
    
    def test_filter_active_users(self, spark):
        data = [
            Row(name="Alice", status="active"),
            Row(name="Bob", status="inactive"),
            Row(name="Charlie", status="active"),
        ]
        df = spark.createDataFrame(data)
        
        result = filter_active_users(df)
        
        assert result.count() == 2
        names = [row["name"] for row in result.collect()]
        assert "Alice" in names
        assert "Charlie" in names
        assert "Bob" not in names
    
    def test_filter_active_users_none_active(self, spark):
        data = [Row(name="Bob", status="inactive")]
        df = spark.createDataFrame(data)
        
        result = filter_active_users(df)
        
        assert result.count() == 0


class TestAddAgeCategory:
    """Tests for add_age_category transformation."""
    
    @pytest.mark.parametrize("age,expected", [
        (10, "minor"),
        (17, "minor"),
        (18, "adult"),
        (64, "adult"),
        (65, "senior"),
        (90, "senior"),
    ])
    def test_age_categories(self, spark, age, expected):
        data = [Row(name="Test", age=age)]
        df = spark.createDataFrame(data)
        
        result = add_age_category(df)
        
        assert result.collect()[0]["age_category"] == expected
```

---

## Part 4: Using Chispa Library

### Step 4.1: DataFrame Comparison
```python
# tests/test_with_chispa.py
from chispa import assert_df_equality
from pyspark.sql import Row
from pyspark.sql.types import *

def test_transformation_with_chispa(spark):
    # Input
    input_data = [
        Row(id=1, value=100),
        Row(id=2, value=200),
    ]
    input_df = spark.createDataFrame(input_data)
    
    # Expected output
    expected_data = [
        Row(id=1, value=100, doubled=200),
        Row(id=2, value=200, doubled=400),
    ]
    expected_df = spark.createDataFrame(expected_data)
    
    # Actual transformation
    from pyspark.sql import functions as F
    actual_df = input_df.withColumn("doubled", F.col("value") * 2)
    
    # Assert equality
    assert_df_equality(actual_df, expected_df)


def test_ignoring_row_order(spark):
    from chispa import assert_df_equality
    
    df1 = spark.createDataFrame([Row(a=1), Row(a=2)])
    df2 = spark.createDataFrame([Row(a=2), Row(a=1)])
    
    # Ignore row order
    assert_df_equality(df1, df2, ignore_row_order=True)


def test_ignoring_column_order(spark):
    from chispa import assert_df_equality
    
    df1 = spark.createDataFrame([Row(a=1, b=2)])
    df2 = spark.createDataFrame([Row(b=2, a=1)])
    
    # Ignore column order
    assert_df_equality(df1, df2, ignore_column_order=True)


def test_approximate_equality(spark):
    from chispa import assert_approx_df_equality
    
    df1 = spark.createDataFrame([Row(a=1.0001)])
    df2 = spark.createDataFrame([Row(a=1.0002)])
    
    # Allow small differences
    assert_approx_df_equality(df1, df2, precision=0.001)
```

---

## Part 5: Testing with Schemas

### Step 5.1: Schema Validation
```python
# tests/test_schemas.py
from pyspark.sql.types import *
from pyspark.sql import Row

def test_output_schema(spark):
    # Define expected schema
    expected_schema = StructType([
        StructField("id", IntegerType(), False),
        StructField("name", StringType(), True),
        StructField("total", DoubleType(), True),
    ])
    
    # Create test data
    data = [Row(id=1, name="Test", quantity=2, price=10.0)]
    df = spark.createDataFrame(data)
    
    # Apply transformation
    from pyspark.sql import functions as F
    result = df.select(
        F.col("id"),
        F.col("name"),
        (F.col("quantity") * F.col("price")).alias("total")
    )
    
    # Validate schema
    assert result.schema == expected_schema


def test_nullable_fields(spark):
    schema = StructType([
        StructField("id", IntegerType(), nullable=False),
        StructField("value", StringType(), nullable=True),
    ])
    
    # This should work - nullable field with None
    data = [(1, None), (2, "test")]
    df = spark.createDataFrame(data, schema)
    
    assert df.count() == 2
```

---

## Part 6: Debugging Techniques

### Step 6.1: Debug with show()
```python
def debug_transformation(df):
    """Add debug prints to trace transformation."""
    print("=== Input DataFrame ===")
    df.show(5, truncate=False)
    df.printSchema()
    print(f"Count: {df.count()}")
    
    # Step 1
    step1 = df.filter(df.value > 0)
    print("\n=== After Filter ===")
    step1.show(5)
    
    # Step 2
    from pyspark.sql import functions as F
    step2 = step1.withColumn("doubled", F.col("value") * 2)
    print("\n=== After Transform ===")
    step2.show(5)
    
    return step2
```

### Step 6.2: Explain Query Plan
```python
def analyze_query_plan(df):
    """Analyze and print query execution plan."""
    print("=== Simple Explain ===")
    df.explain()
    
    print("\n=== Extended Explain ===")
    df.explain(extended=True)
    
    print("\n=== Cost-Based Explain ===")
    df.explain(mode="cost")
    
    print("\n=== Formatted Explain ===")
    df.explain(mode="formatted")
```

### Step 6.3: Sample Data
```python
def debug_with_sample(df, fraction=0.1):
    """Debug using sampled data."""
    sample_df = df.sample(fraction=fraction, seed=42)
    
    print(f"Original count: {df.count()}")
    print(f"Sample count: {sample_df.count()}")
    
    sample_df.show(10)
    
    return sample_df
```

---

## Part 7: Error Handling

### Step 7.1: Try-Except Patterns
```python
# src/safe_transformations.py
from pyspark.sql import DataFrame
from pyspark.sql import functions as F
import logging

logger = logging.getLogger(__name__)

def safe_divide(df: DataFrame, numerator: str, denominator: str, result_col: str) -> DataFrame:
    """Safely divide two columns, handling division by zero."""
    return df.withColumn(
        result_col,
        F.when(F.col(denominator) != 0, F.col(numerator) / F.col(denominator))
        .otherwise(None)
    )


def safe_parse_date(df: DataFrame, date_col: str, format: str = "yyyy-MM-dd") -> DataFrame:
    """Safely parse date column, returning None for invalid dates."""
    return df.withColumn(
        f"{date_col}_parsed",
        F.to_date(F.col(date_col), format)
    )


def safe_json_parse(df: DataFrame, json_col: str, schema) -> DataFrame:
    """Safely parse JSON column with error handling."""
    try:
        return df.withColumn(
            f"{json_col}_parsed",
            F.from_json(F.col(json_col), schema)
        )
    except Exception as e:
        logger.error(f"Failed to parse JSON column {json_col}: {e}")
        raise
```

### Step 7.2: Row-Level Error Handling
```python
from pyspark.sql import functions as F
from pyspark.sql.types import *

def process_with_errors(df):
    """Process data and track errors."""
    
    # Add validation column
    validated = df.withColumn(
        "validation_errors",
        F.array_remove(
            F.array(
                F.when(F.col("email").isNull(), F.lit("Missing email")),
                F.when(F.col("age") < 0, F.lit("Invalid age")),
                F.when(F.col("amount") < 0, F.lit("Negative amount")),
            ),
            None
        )
    )
    
    # Add is_valid flag
    validated = validated.withColumn(
        "is_valid",
        F.size("validation_errors") == 0
    )
    
    # Split into valid and invalid
    valid_df = validated.filter(F.col("is_valid"))
    invalid_df = validated.filter(~F.col("is_valid"))
    
    return valid_df, invalid_df
```

---

## Part 8: Logging

### Step 8.1: Configure Logging
```python
# src/logging_config.py
import logging
import sys

def setup_logging(name: str, level: int = logging.INFO) -> logging.Logger:
    """Configure logging for PySpark application."""
    
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Console handler
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(level)
    
    # Format
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    handler.setFormatter(formatter)
    
    # Avoid duplicate handlers
    if not logger.handlers:
        logger.addHandler(handler)
    
    return logger


# Usage
logger = setup_logging("my_etl_job")
logger.info("Starting ETL job")
logger.warning("Missing data detected")
logger.error("Failed to process file")
```

### Step 8.2: Log Metrics
```python
class JobMetrics:
    """Track and log job metrics."""
    
    def __init__(self, logger):
        self.logger = logger
        self.metrics = {}
    
    def record(self, name, value):
        self.metrics[name] = value
        self.logger.info(f"Metric: {name} = {value}")
    
    def log_dataframe_stats(self, df, name):
        count = df.count()
        self.record(f"{name}_count", count)
        
        # Log column stats
        for col in df.columns:
            null_count = df.filter(df[col].isNull()).count()
            self.record(f"{name}_{col}_nulls", null_count)
    
    def summary(self):
        self.logger.info("=== Job Metrics Summary ===")
        for name, value in self.metrics.items():
            self.logger.info(f"  {name}: {value}")
```

---

## Part 9: Integration Testing

### Step 9.1: End-to-End Test
```python
# tests/test_integration.py
import pytest
import tempfile
import os
from pyspark.sql import Row

class TestETLPipeline:
    """Integration tests for ETL pipeline."""
    
    @pytest.fixture
    def temp_dir(self):
        """Create temporary directory for test data."""
        temp = tempfile.mkdtemp()
        yield temp
        import shutil
        shutil.rmtree(temp)
    
    def test_full_pipeline(self, spark, temp_dir):
        # Create input data
        input_path = os.path.join(temp_dir, "input")
        output_path = os.path.join(temp_dir, "output")
        
        input_data = [
            Row(id=1, name="Alice", amount=100.0),
            Row(id=2, name="Bob", amount=200.0),
        ]
        input_df = spark.createDataFrame(input_data)
        input_df.write.parquet(input_path)
        
        # Run pipeline
        from src.pipeline import run_etl
        run_etl(spark, input_path, output_path)
        
        # Verify output
        output_df = spark.read.parquet(output_path)
        assert output_df.count() == 2
        
        # Verify transformations applied
        assert "processed_date" in output_df.columns
```

### Step 9.2: Test with Mock Data
```python
# tests/test_with_mocks.py
from unittest.mock import Mock, patch
import pytest

def test_external_api_call(spark):
    """Test function that calls external API."""
    
    # Mock the external API
    with patch('src.utils.call_api') as mock_api:
        mock_api.return_value = {"status": "success", "data": [1, 2, 3]}
        
        from src.enrichment import enrich_with_api
        
        data = [Row(id=1), Row(id=2)]
        df = spark.createDataFrame(data)
        
        result = enrich_with_api(df)
        
        assert result.count() == 2
        mock_api.assert_called()
```

---

## Part 10: Performance Testing

### Step 10.1: Benchmark Tests
```python
# tests/test_performance.py
import pytest
import time

class TestPerformance:
    """Performance benchmark tests."""
    
    def test_large_dataset_performance(self, spark):
        """Test transformation performance on large dataset."""
        # Generate large dataset
        data = [(i, f"name_{i}", i * 1.0) for i in range(100000)]
        df = spark.createDataFrame(data, ["id", "name", "value"])
        
        # Measure transformation time
        start = time.time()
        
        from pyspark.sql import functions as F
        result = df \
            .filter(F.col("value") > 50000) \
            .groupBy("name") \
            .agg(F.sum("value").alias("total"))
        
        # Force execution
        result.count()
        
        elapsed = time.time() - start
        
        print(f"Elapsed time: {elapsed:.2f}s")
        assert elapsed < 10.0  # Should complete in 10 seconds
    
    @pytest.mark.parametrize("num_partitions", [2, 10, 50])
    def test_partition_impact(self, spark, num_partitions):
        """Test impact of partition count on performance."""
        data = [(i, i * 1.0) for i in range(100000)]
        df = spark.createDataFrame(data, ["id", "value"])
        
        df = df.repartition(num_partitions)
        
        start = time.time()
        
        from pyspark.sql import functions as F
        result = df.agg(F.sum("value")).collect()
        
        elapsed = time.time() - start
        print(f"Partitions: {num_partitions}, Time: {elapsed:.2f}s")
```

---

## Part 11: CI/CD Integration

### Step 11.1: GitHub Actions
```yaml
# .github/workflows/test.yml
name: PySpark Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Set up Java
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '11'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
    
    - name: Run tests
      run: |
        pytest tests/ -v --cov=src --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: coverage.xml
```

---

## Exercises

1. Write tests for a transformation function
2. Debug a failing PySpark job
3. Implement error handling in an ETL pipeline
4. Set up logging for a Spark application

---

## Summary
- Use pytest with SparkSession fixture
- Compare DataFrames with chispa
- Debug with show(), explain(), and logging
- Handle errors gracefully
- Write integration tests
- Benchmark performance
