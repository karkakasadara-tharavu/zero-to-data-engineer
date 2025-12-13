# Lab 06: Testing the Pipeline

## Overview
Write comprehensive tests for all pipeline components.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Set up pytest for PySpark testing
- ✅ Write unit tests for transformations
- ✅ Create integration tests
- ✅ Test error handling scenarios
- ✅ Achieve high test coverage

---

## Part 1: Test Configuration

### Step 1.1: Pytest Fixtures
```python
# tests/conftest.py
import pytest
from pyspark.sql import SparkSession
import tempfile
import shutil
from pathlib import Path


@pytest.fixture(scope="session")
def spark():
    """Create SparkSession for all tests."""
    spark = SparkSession.builder \
        .master("local[2]") \
        .appName("PipelineTests") \
        .config("spark.sql.shuffle.partitions", "2") \
        .config("spark.default.parallelism", "2") \
        .config("spark.ui.enabled", "false") \
        .config("spark.sql.warehouse.dir", tempfile.mkdtemp()) \
        .config("spark.driver.memory", "2g") \
        .getOrCreate()
    
    # Reduce logging
    spark.sparkContext.setLogLevel("WARN")
    
    yield spark
    spark.stop()


@pytest.fixture(scope="function")
def temp_dir():
    """Create temporary directory for each test."""
    temp = tempfile.mkdtemp()
    yield temp
    shutil.rmtree(temp, ignore_errors=True)


@pytest.fixture(scope="session")
def sample_config():
    """Sample configuration for tests."""
    return {
        "environment": "test",
        "paths": {
            "raw_data": "tests/data/raw",
            "processed_data": "tests/data/processed",
            "warehouse": "tests/data/warehouse",
        },
        "database": {
            "host": "localhost",
            "port": 5432,
            "name": "test_db",
            "user": "test_user",
            "password": "test_pass",
        },
        "quality": {
            "null_threshold": 0.05,
        }
    }


@pytest.fixture
def sample_orders(spark):
    """Create sample orders DataFrame."""
    from pyspark.sql import Row
    from datetime import date
    
    data = [
        Row(order_id="O001", customer_id="C001", order_date=date(2024, 1, 15),
            product_id="P001", quantity=2, unit_price=25.00),
        Row(order_id="O002", customer_id="C002", order_date=date(2024, 1, 16),
            product_id="P002", quantity=1, unit_price=50.00),
        Row(order_id="O003", customer_id="C001", order_date=date(2024, 1, 17),
            product_id="P003", quantity=3, unit_price=15.00),
    ]
    return spark.createDataFrame(data)


@pytest.fixture
def sample_customers(spark):
    """Create sample customers DataFrame."""
    from pyspark.sql import Row
    
    data = [
        Row(customer_id="C001", name="Alice Smith", email="alice@email.com", age=30),
        Row(customer_id="C002", name="Bob Jones", email="bob@email.com", age=45),
        Row(customer_id="C003", name="Charlie Brown", email="charlie@email.com", age=25),
    ]
    return spark.createDataFrame(data)


@pytest.fixture
def sample_products(spark):
    """Create sample products DataFrame."""
    from pyspark.sql import Row
    
    data = [
        Row(product_id="P001", product_name="Widget A", category="Electronics", price=25.00),
        Row(product_id="P002", product_name="Gadget B", category="Electronics", price=50.00),
        Row(product_id="P003", product_name="Tool C", category="Hardware", price=15.00),
    ]
    return spark.createDataFrame(data)
```

---

## Part 2: Testing Transformations

### Step 2.1: Cleanser Tests
```python
# tests/unit/test_cleanser.py
import pytest
from pyspark.sql import Row
from pyspark.sql import functions as F
from src.transformation.cleanser import DataCleanser


class TestDataCleanser:
    """Tests for DataCleanser class."""
    
    def test_trim_strings(self, spark):
        """Test string trimming."""
        # Arrange
        data = [
            Row(name="  John Doe  ", email="  john@email.com  "),
            Row(name="Jane Smith", email="jane@email.com"),
        ]
        df = spark.createDataFrame(data)
        
        cleanser = DataCleanser(spark).trim_strings()
        
        # Act
        result = cleanser.transform(df)
        
        # Assert
        rows = result.collect()
        assert rows[0]["name"] == "John Doe"
        assert rows[0]["email"] == "john@email.com"
        assert rows[1]["name"] == "Jane Smith"
    
    def test_standardize_case_lower(self, spark):
        """Test lowercase standardization."""
        data = [Row(email="JOHN@EMAIL.COM")]
        df = spark.createDataFrame(data)
        
        cleanser = DataCleanser(spark).standardize_case(["email"], case="lower")
        result = cleanser.transform(df)
        
        assert result.collect()[0]["email"] == "john@email.com"
    
    def test_drop_nulls(self, spark):
        """Test null dropping."""
        data = [
            Row(id=1, name="Alice", email="alice@email.com"),
            Row(id=2, name=None, email="bob@email.com"),
            Row(id=3, name="Charlie", email=None),
        ]
        df = spark.createDataFrame(data)
        
        cleanser = DataCleanser(spark).drop_nulls(columns=["name", "email"])
        result = cleanser.transform(df)
        
        assert result.count() == 1
        assert result.collect()[0]["id"] == 1
    
    def test_fill_nulls(self, spark):
        """Test null filling."""
        data = [
            Row(id=1, name="Alice", phone=None),
            Row(id=2, name="Bob", phone="123-456"),
        ]
        df = spark.createDataFrame(data)
        
        cleanser = DataCleanser(spark).fill_nulls({"phone": "N/A"})
        result = cleanser.transform(df)
        
        rows = result.collect()
        assert rows[0]["phone"] == "N/A"
        assert rows[1]["phone"] == "123-456"
    
    def test_remove_duplicates(self, spark):
        """Test duplicate removal."""
        data = [
            Row(id=1, name="Alice"),
            Row(id=1, name="Alice"),
            Row(id=2, name="Bob"),
        ]
        df = spark.createDataFrame(data)
        
        cleanser = DataCleanser(spark).remove_duplicates(["id"])
        result = cleanser.transform(df)
        
        assert result.count() == 2
    
    def test_keep_latest(self, spark):
        """Test keeping latest record per partition."""
        from datetime import date
        
        data = [
            Row(id=1, updated=date(2024, 1, 1), value=100),
            Row(id=1, updated=date(2024, 1, 15), value=150),
            Row(id=2, updated=date(2024, 1, 10), value=200),
        ]
        df = spark.createDataFrame(data)
        
        cleanser = DataCleanser(spark).keep_latest(
            partition_cols=["id"],
            order_col="updated"
        )
        result = cleanser.transform(df)
        
        rows = {row["id"]: row for row in result.collect()}
        assert rows[1]["value"] == 150
        assert result.count() == 2
    
    def test_chained_transformations(self, spark):
        """Test multiple chained transformations."""
        data = [
            Row(id=1, name="  ALICE  ", email="ALICE@EMAIL.COM"),
            Row(id=2, name=None, email="BOB@EMAIL.COM"),
        ]
        df = spark.createDataFrame(data)
        
        cleanser = DataCleanser(spark) \
            .trim_strings() \
            .standardize_case(["name", "email"], case="lower") \
            .fill_nulls({"name": "Unknown"})
        
        result = cleanser.transform(df)
        rows = result.collect()
        
        assert rows[0]["name"] == "alice"
        assert rows[0]["email"] == "alice@email.com"
        assert rows[1]["name"] == "unknown"
```

### Step 2.2: Enricher Tests
```python
# tests/unit/test_enricher.py
import pytest
from pyspark.sql import Row
from pyspark.sql import functions as F
from src.transformation.enricher import DataEnricher


class TestDataEnricher:
    """Tests for DataEnricher class."""
    
    def test_add_total_amount(self, spark):
        """Test total amount calculation."""
        data = [
            Row(order_id="O001", quantity=2, unit_price=25.00),
            Row(order_id="O002", quantity=3, unit_price=10.00),
        ]
        df = spark.createDataFrame(data)
        
        enricher = DataEnricher(spark).add_total_amount(
            "quantity", "unit_price", "total_amount"
        )
        result = enricher.transform(df)
        
        rows = {row["order_id"]: row for row in result.collect()}
        assert rows["O001"]["total_amount"] == 50.00
        assert rows["O002"]["total_amount"] == 30.00
    
    def test_add_date_parts(self, spark):
        """Test date part extraction."""
        from datetime import date
        
        data = [Row(order_date=date(2024, 3, 15))]
        df = spark.createDataFrame(data)
        
        enricher = DataEnricher(spark).add_date_parts(
            "order_date",
            parts=["year", "month", "quarter"]
        )
        result = enricher.transform(df)
        
        row = result.collect()[0]
        assert row["order_date_year"] == 2024
        assert row["order_date_month"] == 3
        assert row["order_date_quarter"] == 1
    
    def test_add_is_weekend(self, spark):
        """Test weekend flag."""
        from datetime import date
        
        data = [
            Row(order_date=date(2024, 1, 15)),  # Monday
            Row(order_date=date(2024, 1, 14)),  # Sunday
        ]
        df = spark.createDataFrame(data)
        
        enricher = DataEnricher(spark).add_is_weekend("order_date")
        result = enricher.transform(df)
        
        rows = result.collect()
        assert rows[0]["is_weekend"] == False
        assert rows[1]["is_weekend"] == True
    
    def test_join_lookup(self, spark, sample_products):
        """Test lookup table join."""
        data = [
            Row(order_id="O001", product_id="P001"),
            Row(order_id="O002", product_id="P002"),
        ]
        df = spark.createDataFrame(data)
        
        enricher = DataEnricher(spark)
        enricher.register_lookup("products", sample_products)
        enricher.join_lookup(
            "products",
            join_key="product_id",
            columns=["product_name", "category"]
        )
        
        result = enricher.transform(df)
        
        rows = {row["order_id"]: row for row in result.collect()}
        assert rows["O001"]["product_name"] == "Widget A"
        assert rows["O002"]["category"] == "Electronics"
    
    def test_add_age_group(self, spark):
        """Test age grouping."""
        data = [
            Row(id=1, age=15),
            Row(id=2, age=25),
            Row(id=3, age=45),
            Row(id=4, age=70),
        ]
        df = spark.createDataFrame(data)
        
        enricher = DataEnricher(spark).add_age_group("age")
        result = enricher.transform(df)
        
        rows = {row["id"]: row for row in result.collect()}
        assert rows[1]["age_group"] == "<18"
        assert rows[2]["age_group"] == "25-34"
        assert rows[3]["age_group"] == "45-54"
        assert rows[4]["age_group"] == "65+"
```

### Step 2.3: Aggregator Tests
```python
# tests/unit/test_aggregator.py
import pytest
from pyspark.sql import Row
from pyspark.sql import functions as F
from src.transformation.aggregator import DataAggregator


class TestDataAggregator:
    """Tests for DataAggregator class."""
    
    def test_aggregate(self, spark, sample_orders):
        """Test basic aggregation."""
        aggregator = DataAggregator(spark).aggregate(
            group_by=["customer_id"],
            aggregations={"quantity": ["sum", "count"]}
        )
        
        result = aggregator.transform(sample_orders)
        
        rows = {row["customer_id"]: row for row in result.collect()}
        assert rows["C001"]["quantity_sum"] == 5  # 2 + 3
        assert rows["C001"]["quantity_count"] == 2
        assert rows["C002"]["quantity_sum"] == 1
    
    def test_add_running_total(self, spark):
        """Test running total calculation."""
        from datetime import date
        
        data = [
            Row(customer_id="C001", order_date=date(2024, 1, 1), amount=100),
            Row(customer_id="C001", order_date=date(2024, 1, 2), amount=50),
            Row(customer_id="C001", order_date=date(2024, 1, 3), amount=75),
        ]
        df = spark.createDataFrame(data)
        
        aggregator = DataAggregator(spark).add_running_total(
            value_column="amount",
            partition_by=["customer_id"],
            order_by="order_date"
        )
        
        result = aggregator.transform(df).orderBy("order_date")
        rows = result.collect()
        
        assert rows[0]["amount_running_total"] == 100
        assert rows[1]["amount_running_total"] == 150
        assert rows[2]["amount_running_total"] == 225
    
    def test_add_rank(self, spark, sample_orders):
        """Test ranking."""
        aggregator = DataAggregator(spark).add_rank(
            partition_by=["customer_id"],
            order_by="unit_price",
            descending=True
        )
        
        result = aggregator.transform(sample_orders)
        
        # C001 has 2 orders: price 25 (rank 1) and 15 (rank 2)
        c001_orders = result.filter(F.col("customer_id") == "C001") \
            .orderBy("rank").collect()
        
        assert c001_orders[0]["unit_price"] == 25.00
        assert c001_orders[0]["rank"] == 1
    
    def test_top_n(self, spark):
        """Test top N selection."""
        data = [
            Row(category="A", product="P1", sales=100),
            Row(category="A", product="P2", sales=200),
            Row(category="A", product="P3", sales=150),
            Row(category="B", product="P4", sales=300),
        ]
        df = spark.createDataFrame(data)
        
        aggregator = DataAggregator(spark).top_n(
            n=2,
            partition_by=["category"],
            order_by="sales",
            descending=True
        )
        
        result = aggregator.transform(df)
        
        cat_a = result.filter(F.col("category") == "A")
        assert cat_a.count() == 2
        
        # Should have P2 (200) and P3 (150), not P1 (100)
        products = [r["product"] for r in cat_a.collect()]
        assert "P2" in products
        assert "P3" in products
        assert "P1" not in products
```

---

## Part 3: Testing Validators

### Step 3.1: Validator Tests
```python
# tests/unit/test_validators.py
import pytest
from pyspark.sql import Row
from pyspark.sql import functions as F
from src.utils.validators import DataValidator, Severity


class TestDataValidator:
    """Tests for DataValidator class."""
    
    def test_not_null_validation(self, spark):
        """Test not-null validation."""
        data = [
            Row(id=1, email="test@email.com"),
            Row(id=2, email=None),
            Row(id=3, email="other@email.com"),
        ]
        df = spark.createDataFrame(data)
        
        validator = DataValidator(spark).not_null("email")
        results = validator.validate(df)
        
        assert len(results) == 1
        assert results[0].failed_count == 1
        assert results[0].pass_rate == pytest.approx(2/3, rel=0.01)
    
    def test_unique_validation(self, spark):
        """Test uniqueness validation."""
        data = [
            Row(id=1, email="a@email.com"),
            Row(id=2, email="b@email.com"),
            Row(id=3, email="a@email.com"),  # Duplicate
        ]
        df = spark.createDataFrame(data)
        
        validator = DataValidator(spark).unique("email")
        results = validator.validate(df)
        
        assert results[0].failed_count == 2  # Both duplicates
        assert not results[0].passed
    
    def test_in_range_validation(self, spark):
        """Test range validation."""
        data = [
            Row(id=1, age=25),
            Row(id=2, age=150),  # Out of range
            Row(id=3, age=-5),   # Out of range
        ]
        df = spark.createDataFrame(data)
        
        validator = DataValidator(spark).in_range("age", 0, 120)
        results = validator.validate(df)
        
        assert results[0].failed_count == 2
    
    def test_valid_email_validation(self, spark):
        """Test email validation."""
        data = [
            Row(email="valid@email.com"),
            Row(email="also.valid@sub.domain.com"),
            Row(email="invalid-email"),
            Row(email="@missing.domain"),
        ]
        df = spark.createDataFrame(data)
        
        validator = DataValidator(spark).valid_email("email")
        results = validator.validate(df)
        
        assert results[0].failed_count == 2
    
    def test_threshold_validation(self, spark):
        """Test validation with threshold."""
        data = [
            Row(id=1, value="valid"),
            Row(id=2, value=None),
        ]
        df = spark.createDataFrame(data)
        
        # With 50% threshold, 1 null out of 2 should pass
        validator = DataValidator(spark).not_null("value", threshold=0.5)
        results = validator.validate(df)
        
        assert results[0].passed  # 50% failure rate equals threshold
    
    def test_severity_levels(self, spark):
        """Test different severity levels."""
        data = [Row(id=1, value=None)]
        df = spark.createDataFrame(data)
        
        validator = DataValidator(spark) \
            .not_null("id", severity=Severity.ERROR) \
            .not_null("value", severity=Severity.WARNING)
        
        results = validator.validate(df)
        summary = validator.get_summary()
        
        assert summary["error_failures"] == 0  # id is not null
        assert summary["warning_failures"] == 1  # value is null
    
    def test_foreign_key_validation(self, spark, sample_products):
        """Test foreign key validation."""
        orders = spark.createDataFrame([
            Row(order_id="O001", product_id="P001"),  # Valid
            Row(order_id="O002", product_id="P999"),  # Invalid
        ])
        
        validator = DataValidator(spark).foreign_key(
            "product_id",
            sample_products,
            "product_id"
        )
        
        results = validator.validate(orders)
        
        assert results[0].failed_count == 1
    
    def test_raise_on_failure(self, spark):
        """Test exception raising on failure."""
        from src.utils.exceptions import DataQualityError
        
        data = [Row(email=None)]
        df = spark.createDataFrame(data)
        
        validator = DataValidator(spark).not_null("email")
        validator.validate(df)
        
        with pytest.raises(DataQualityError):
            validator.raise_on_failure()
```

---

## Part 4: Integration Tests

### Step 4.1: Pipeline Integration Tests
```python
# tests/integration/test_pipeline.py
import pytest
from pyspark.sql import Row
from datetime import date
import tempfile
import os


class TestPipelineIntegration:
    """Integration tests for complete pipeline."""
    
    @pytest.fixture
    def pipeline_data(self, spark, temp_dir):
        """Create test data files."""
        # Create orders CSV
        orders_data = [
            Row(order_id="O001", customer_id="C001", order_date=date(2024, 1, 15),
                product_id="P001", quantity=2, unit_price=25.00),
            Row(order_id="O002", customer_id="C002", order_date=date(2024, 1, 16),
                product_id="P002", quantity=1, unit_price=50.00),
        ]
        orders_df = spark.createDataFrame(orders_data)
        orders_path = os.path.join(temp_dir, "orders.csv")
        orders_df.write.csv(orders_path, header=True)
        
        # Create customers CSV
        customers_data = [
            Row(customer_id="C001", name="Alice", email="alice@email.com"),
            Row(customer_id="C002", name="Bob", email="bob@email.com"),
        ]
        customers_df = spark.createDataFrame(customers_data)
        customers_path = os.path.join(temp_dir, "customers.csv")
        customers_df.write.csv(customers_path, header=True)
        
        return {
            "orders_path": orders_path,
            "customers_path": customers_path,
            "output_path": os.path.join(temp_dir, "output"),
        }
    
    def test_full_etl_pipeline(self, spark, pipeline_data, sample_config):
        """Test complete ETL pipeline."""
        from src.ingestion.csv_ingester import CSVIngester
        from src.transformation.cleanser import DataCleanser
        from src.transformation.enricher import DataEnricher
        from src.loading.file_loader import FileLoader
        
        # Step 1: Ingest
        orders_ingester = CSVIngester(
            spark=spark,
            config=sample_config,
            path=pipeline_data["orders_path"]
        )
        orders_df = orders_ingester.ingest()
        
        assert orders_df.count() == 2
        
        # Step 2: Clean
        cleanser = DataCleanser(spark) \
            .trim_strings() \
            .drop_nulls(columns=["order_id", "customer_id"])
        
        cleaned_df = cleanser.transform(orders_df)
        assert cleaned_df.count() == 2
        
        # Step 3: Enrich
        customers_df = spark.read.csv(
            pipeline_data["customers_path"],
            header=True,
            inferSchema=True
        )
        
        enricher = DataEnricher(spark)
        enricher.register_lookup("customers", customers_df)
        enricher.add_total_amount("quantity", "unit_price")
        enricher.join_lookup("customers", "customer_id", columns=["name", "email"])
        
        enriched_df = enricher.transform(cleaned_df)
        assert "total_amount" in enriched_df.columns
        assert "name" in enriched_df.columns
        
        # Step 4: Load
        loader = FileLoader(spark, sample_config)
        success = loader.load_parquet(
            enriched_df,
            pipeline_data["output_path"]
        )
        
        assert success
        
        # Verify output
        output_df = spark.read.parquet(pipeline_data["output_path"])
        assert output_df.count() == 2
    
    def test_pipeline_with_bad_data(self, spark, temp_dir, sample_config):
        """Test pipeline handles bad data correctly."""
        from src.utils.validators import DataValidator, Severity
        from src.utils.quarantine import QuarantineManager
        from pyspark.sql import functions as F
        
        # Create data with some invalid records
        data = [
            Row(id=1, email="valid@email.com", age=30),
            Row(id=2, email="invalid-email", age=25),
            Row(id=3, email=None, age=-5),
            Row(id=4, email="another@email.com", age=45),
        ]
        df = spark.createDataFrame(data)
        
        # Validate
        validator = DataValidator(spark) \
            .not_null("email") \
            .valid_email("email", threshold=0.5) \
            .in_range("age", 0, 120)
        
        results = validator.validate(df)
        summary = validator.get_summary()
        
        assert summary["total_rules"] == 3
        
        # Quarantine
        quarantine_path = os.path.join(temp_dir, "quarantine")
        quarantine = QuarantineManager(spark, quarantine_path)
        
        rules = {
            "email_not_null": F.col("email").isNotNull(),
            "valid_email": F.col("email").rlike(r"^[a-zA-Z0-9._%+-]+@"),
            "valid_age": F.col("age").between(0, 120),
        }
        
        valid_df, invalid_df = quarantine.quarantine(df, rules, "test_source")
        
        assert valid_df.count() == 2  # Only 2 fully valid records
        assert invalid_df.count() == 2  # 2 invalid records
```

---

## Part 5: Running Tests

### Step 5.1: Running with pytest
```powershell
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=src --cov-report=html

# Run specific test file
pytest tests/unit/test_cleanser.py -v

# Run specific test class
pytest tests/unit/test_cleanser.py::TestDataCleanser -v

# Run specific test
pytest tests/unit/test_cleanser.py::TestDataCleanser::test_trim_strings -v

# Run with markers
pytest tests/ -v -m "not slow"

# Run in parallel
pytest tests/ -v -n auto
```

### Step 5.2: Test Markers
```python
# pytest.ini
[pytest]
markers =
    slow: marks tests as slow
    integration: marks integration tests
    unit: marks unit tests

# Usage in tests
@pytest.mark.slow
def test_large_dataset(self):
    pass

@pytest.mark.integration
def test_full_pipeline(self):
    pass
```

---

## Exercises

1. Write tests for ingestion components
2. Create tests for error scenarios
3. Build integration tests for your pipeline
4. Achieve 80% test coverage

---

## Summary
- Set up pytest with PySpark fixtures
- Wrote unit tests for transformations
- Created validation tests
- Built integration tests
- Learned test running strategies

---

## Next Lab
In the next lab, we'll orchestrate the complete pipeline.
