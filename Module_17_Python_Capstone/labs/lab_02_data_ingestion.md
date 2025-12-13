# Lab 02: Data Ingestion Layer

## Overview
Build the data ingestion layer to extract data from multiple sources.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Ingest data from CSV files
- ✅ Extract data from REST APIs
- ✅ Connect to databases
- ✅ Handle ingestion errors
- ✅ Implement retry logic

---

## Part 1: Base Ingester Class

### Step 1.1: Abstract Base Class
```python
# src/ingestion/base_ingester.py
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.types import StructType
import logging

logger = logging.getLogger(__name__)


class BaseIngester(ABC):
    """Abstract base class for data ingesters."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any]):
        self.spark = spark
        self.config = config
        self.logger = logging.getLogger(self.__class__.__name__)
    
    @abstractmethod
    def ingest(self) -> DataFrame:
        """Ingest data and return DataFrame."""
        pass
    
    @abstractmethod
    def validate_source(self) -> bool:
        """Validate source is accessible."""
        pass
    
    def apply_schema(self, df: DataFrame, schema: StructType) -> DataFrame:
        """Apply schema to DataFrame."""
        for field in schema.fields:
            if field.name in df.columns:
                df = df.withColumn(field.name, df[field.name].cast(field.dataType))
        return df
    
    def add_metadata(self, df: DataFrame) -> DataFrame:
        """Add ingestion metadata columns."""
        from pyspark.sql import functions as F
        
        return df \
            .withColumn("_ingested_at", F.current_timestamp()) \
            .withColumn("_source", F.lit(self.__class__.__name__))
```

---

## Part 2: CSV Ingester

### Step 2.1: CSV Ingestion
```python
# src/ingestion/csv_ingester.py
from pathlib import Path
from typing import Dict, Any, List, Optional
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.types import StructType
from .base_ingester import BaseIngester
import logging

logger = logging.getLogger(__name__)


class CSVIngester(BaseIngester):
    """Ingest data from CSV files."""
    
    def __init__(
        self,
        spark: SparkSession,
        config: Dict[str, Any],
        path: str,
        schema: Optional[StructType] = None,
        options: Optional[Dict[str, str]] = None
    ):
        super().__init__(spark, config)
        self.path = path
        self.schema = schema
        self.options = options or {}
        
        # Default CSV options
        self.default_options = {
            "header": "true",
            "inferSchema": "true" if schema is None else "false",
            "mode": "PERMISSIVE",
            "columnNameOfCorruptRecord": "_corrupt_record",
        }
    
    def validate_source(self) -> bool:
        """Check if CSV file or directory exists."""
        path = Path(self.path)
        
        if path.exists():
            self.logger.info(f"Source validated: {self.path}")
            return True
        
        # For cloud paths, try to read
        try:
            self.spark.read.csv(self.path).limit(1).collect()
            return True
        except Exception as e:
            self.logger.error(f"Source validation failed: {e}")
            return False
    
    def ingest(self) -> DataFrame:
        """Ingest CSV file(s) into DataFrame."""
        self.logger.info(f"Ingesting CSV from: {self.path}")
        
        if not self.validate_source():
            raise FileNotFoundError(f"CSV source not found: {self.path}")
        
        # Merge options
        options = {**self.default_options, **self.options}
        
        # Build reader
        reader = self.spark.read.options(**options)
        
        # Apply schema if provided
        if self.schema:
            reader = reader.schema(self.schema)
        
        # Read CSV
        df = reader.csv(self.path)
        
        # Log stats
        count = df.count()
        self.logger.info(f"Ingested {count} records from CSV")
        
        # Check for corrupt records
        if "_corrupt_record" in df.columns:
            corrupt_count = df.filter(df["_corrupt_record"].isNotNull()).count()
            if corrupt_count > 0:
                self.logger.warning(f"Found {corrupt_count} corrupt records")
        
        # Add metadata
        df = self.add_metadata(df)
        
        return df
    
    def ingest_multiple(self, paths: List[str]) -> DataFrame:
        """Ingest multiple CSV files and union."""
        dfs = []
        
        for path in paths:
            self.path = path
            try:
                df = self.ingest()
                dfs.append(df)
            except Exception as e:
                self.logger.error(f"Failed to ingest {path}: {e}")
        
        if not dfs:
            raise ValueError("No files successfully ingested")
        
        # Union all DataFrames
        result = dfs[0]
        for df in dfs[1:]:
            result = result.unionByName(df, allowMissingColumns=True)
        
        return result
```

### Step 2.2: Usage Example
```python
from pyspark.sql import SparkSession
from pyspark.sql.types import *
from src.ingestion.csv_ingester import CSVIngester
from src.utils.config import Config

# Initialize
spark = SparkSession.builder.appName("CSVIngestion").getOrCreate()
config = Config()

# Define schema
orders_schema = StructType([
    StructField("order_id", StringType(), False),
    StructField("customer_id", StringType(), False),
    StructField("order_date", DateType(), False),
    StructField("product_id", StringType(), False),
    StructField("quantity", IntegerType(), True),
    StructField("unit_price", DoubleType(), True),
])

# Ingest
ingester = CSVIngester(
    spark=spark,
    config=config._config,
    path="data/raw/orders.csv",
    schema=orders_schema,
    options={"dateFormat": "yyyy-MM-dd"}
)

orders_df = ingester.ingest()
orders_df.show(5)
```

---

## Part 3: API Ingester

### Step 3.1: REST API Ingestion
```python
# src/ingestion/api_ingester.py
import requests
import time
from typing import Dict, Any, List, Optional
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.types import StructType
from .base_ingester import BaseIngester
import logging

logger = logging.getLogger(__name__)


class APIIngester(BaseIngester):
    """Ingest data from REST APIs."""
    
    def __init__(
        self,
        spark: SparkSession,
        config: Dict[str, Any],
        base_url: str,
        endpoint: str,
        schema: Optional[StructType] = None,
        headers: Optional[Dict[str, str]] = None,
        params: Optional[Dict[str, Any]] = None,
        auth: Optional[tuple] = None,
        pagination: Optional[Dict[str, Any]] = None
    ):
        super().__init__(spark, config)
        self.base_url = base_url.rstrip('/')
        self.endpoint = endpoint.lstrip('/')
        self.schema = schema
        self.headers = headers or {}
        self.params = params or {}
        self.auth = auth
        self.pagination = pagination
        
        # Retry configuration
        self.max_retries = config.get('api', {}).get('retry_attempts', 3)
        self.timeout = config.get('api', {}).get('timeout', 30)
        self.retry_delay = 2
    
    @property
    def url(self) -> str:
        return f"{self.base_url}/{self.endpoint}"
    
    def validate_source(self) -> bool:
        """Validate API endpoint is accessible."""
        try:
            response = requests.head(
                self.url,
                headers=self.headers,
                auth=self.auth,
                timeout=self.timeout
            )
            return response.status_code < 400
        except Exception as e:
            self.logger.error(f"API validation failed: {e}")
            return False
    
    def _make_request(self, params: Dict = None) -> Dict:
        """Make API request with retry logic."""
        request_params = {**self.params, **(params or {})}
        
        for attempt in range(self.max_retries):
            try:
                response = requests.get(
                    self.url,
                    headers=self.headers,
                    params=request_params,
                    auth=self.auth,
                    timeout=self.timeout
                )
                response.raise_for_status()
                return response.json()
                
            except requests.exceptions.RequestException as e:
                self.logger.warning(
                    f"Request failed (attempt {attempt + 1}/{self.max_retries}): {e}"
                )
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay * (attempt + 1))
                else:
                    raise
    
    def _fetch_paginated(self) -> List[Dict]:
        """Fetch all pages of paginated data."""
        all_data = []
        
        page = 1
        page_size = self.pagination.get('page_size', 100)
        page_param = self.pagination.get('page_param', 'page')
        size_param = self.pagination.get('size_param', 'limit')
        data_key = self.pagination.get('data_key', 'data')
        
        while True:
            params = {
                page_param: page,
                size_param: page_size
            }
            
            response = self._make_request(params)
            
            # Extract data
            if data_key:
                data = response.get(data_key, [])
            else:
                data = response if isinstance(response, list) else [response]
            
            if not data:
                break
            
            all_data.extend(data)
            self.logger.info(f"Fetched page {page}, records: {len(data)}")
            
            # Check for more pages
            total = response.get('total', 0)
            if len(all_data) >= total or len(data) < page_size:
                break
            
            page += 1
        
        return all_data
    
    def ingest(self) -> DataFrame:
        """Ingest data from API into DataFrame."""
        self.logger.info(f"Ingesting from API: {self.url}")
        
        # Fetch data
        if self.pagination:
            data = self._fetch_paginated()
        else:
            response = self._make_request()
            data = response if isinstance(response, list) else [response]
        
        if not data:
            self.logger.warning("No data returned from API")
            return self.spark.createDataFrame([], self.schema or StructType([]))
        
        # Create DataFrame
        if self.schema:
            df = self.spark.createDataFrame(data, schema=self.schema)
        else:
            df = self.spark.createDataFrame(data)
        
        self.logger.info(f"Ingested {df.count()} records from API")
        
        # Add metadata
        df = self.add_metadata(df)
        
        return df
```

### Step 3.2: Usage Example
```python
from pyspark.sql.types import *

# Define schema
products_schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("category", StringType(), True),
    StructField("price", DoubleType(), True),
    StructField("in_stock", BooleanType(), True),
])

# Create ingester
api_ingester = APIIngester(
    spark=spark,
    config=config._config,
    base_url="https://api.example.com",
    endpoint="products",
    schema=products_schema,
    headers={"Authorization": "Bearer token123"},
    pagination={
        "page_param": "page",
        "size_param": "per_page",
        "page_size": 100,
        "data_key": "products"
    }
)

# Ingest
products_df = api_ingester.ingest()
products_df.show(5)
```

---

## Part 4: Database Ingester

### Step 4.1: Database Ingestion
```python
# src/ingestion/db_ingester.py
from typing import Dict, Any, Optional, List
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.types import StructType
from .base_ingester import BaseIngester
import logging

logger = logging.getLogger(__name__)


class DatabaseIngester(BaseIngester):
    """Ingest data from databases via JDBC."""
    
    def __init__(
        self,
        spark: SparkSession,
        config: Dict[str, Any],
        table: Optional[str] = None,
        query: Optional[str] = None,
        db_config: Optional[Dict[str, Any]] = None,
        partition_column: Optional[str] = None,
        num_partitions: int = 10,
        fetch_size: int = 10000
    ):
        super().__init__(spark, config)
        self.table = table
        self.query = query
        self.db_config = db_config or config.get('database', {})
        self.partition_column = partition_column
        self.num_partitions = num_partitions
        self.fetch_size = fetch_size
        
        if not table and not query:
            raise ValueError("Either 'table' or 'query' must be provided")
    
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
            "fetchsize": str(self.fetch_size),
        }
    
    def validate_source(self) -> bool:
        """Validate database connection."""
        try:
            test_query = "SELECT 1"
            self.spark.read.jdbc(
                url=self.jdbc_url,
                table=f"({test_query}) as test",
                properties=self.connection_properties
            ).collect()
            self.logger.info("Database connection validated")
            return True
        except Exception as e:
            self.logger.error(f"Database validation failed: {e}")
            return False
    
    def _get_bounds(self) -> tuple:
        """Get min and max values for partition column."""
        if not self.partition_column:
            return None, None
        
        bounds_query = f"""
            SELECT MIN({self.partition_column}) as min_val,
                   MAX({self.partition_column}) as max_val
            FROM {self.table}
        """
        
        bounds = self.spark.read.jdbc(
            url=self.jdbc_url,
            table=f"({bounds_query}) as bounds",
            properties=self.connection_properties
        ).collect()[0]
        
        return bounds['min_val'], bounds['max_val']
    
    def ingest(self) -> DataFrame:
        """Ingest data from database."""
        source = self.table or f"({self.query}) as subquery"
        self.logger.info(f"Ingesting from database: {source}")
        
        # Build reader
        reader = self.spark.read
        
        # Add partitioning if specified
        if self.partition_column and self.table:
            lower, upper = self._get_bounds()
            
            if lower is not None and upper is not None:
                df = reader.jdbc(
                    url=self.jdbc_url,
                    table=self.table,
                    column=self.partition_column,
                    lowerBound=lower,
                    upperBound=upper,
                    numPartitions=self.num_partitions,
                    properties=self.connection_properties
                )
            else:
                df = reader.jdbc(
                    url=self.jdbc_url,
                    table=source,
                    properties=self.connection_properties
                )
        else:
            df = reader.jdbc(
                url=self.jdbc_url,
                table=source,
                properties=self.connection_properties
            )
        
        count = df.count()
        self.logger.info(f"Ingested {count} records from database")
        
        # Add metadata
        df = self.add_metadata(df)
        
        return df
    
    def ingest_incremental(
        self,
        watermark_column: str,
        watermark_value: Any
    ) -> DataFrame:
        """Ingest only new/updated records."""
        if self.query:
            raise ValueError("Incremental ingestion requires table, not query")
        
        query = f"""
            SELECT * FROM {self.table}
            WHERE {watermark_column} > '{watermark_value}'
        """
        
        self.query = query
        self.table = None
        
        return self.ingest()
```

### Step 4.2: Usage Example
```python
# Database ingestion - full table
db_ingester = DatabaseIngester(
    spark=spark,
    config=config._config,
    table="customers",
    partition_column="customer_id",
    num_partitions=20
)

customers_df = db_ingester.ingest()

# Incremental ingestion
incremental_ingester = DatabaseIngester(
    spark=spark,
    config=config._config,
    table="orders"
)

new_orders = incremental_ingester.ingest_incremental(
    watermark_column="updated_at",
    watermark_value="2024-01-01"
)
```

---

## Part 5: Ingestion Pipeline

### Step 5.1: Unified Ingestion Manager
```python
# src/ingestion/ingestion_manager.py
from typing import Dict, Any, List
from pyspark.sql import DataFrame, SparkSession
from .csv_ingester import CSVIngester
from .api_ingester import APIIngester
from .db_ingester import DatabaseIngester
import logging

logger = logging.getLogger(__name__)


class IngestionManager:
    """Manage multiple data ingestion sources."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any]):
        self.spark = spark
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.ingesters = {}
        self.dataframes = {}
    
    def add_csv_source(
        self,
        name: str,
        path: str,
        schema=None,
        options: Dict = None
    ):
        """Add CSV source."""
        self.ingesters[name] = CSVIngester(
            spark=self.spark,
            config=self.config,
            path=path,
            schema=schema,
            options=options
        )
        self.logger.info(f"Added CSV source: {name}")
    
    def add_api_source(
        self,
        name: str,
        base_url: str,
        endpoint: str,
        schema=None,
        **kwargs
    ):
        """Add API source."""
        self.ingesters[name] = APIIngester(
            spark=self.spark,
            config=self.config,
            base_url=base_url,
            endpoint=endpoint,
            schema=schema,
            **kwargs
        )
        self.logger.info(f"Added API source: {name}")
    
    def add_db_source(
        self,
        name: str,
        table: str = None,
        query: str = None,
        **kwargs
    ):
        """Add database source."""
        self.ingesters[name] = DatabaseIngester(
            spark=self.spark,
            config=self.config,
            table=table,
            query=query,
            **kwargs
        )
        self.logger.info(f"Added database source: {name}")
    
    def ingest(self, name: str) -> DataFrame:
        """Ingest from a specific source."""
        if name not in self.ingesters:
            raise ValueError(f"Unknown source: {name}")
        
        self.logger.info(f"Starting ingestion: {name}")
        df = self.ingesters[name].ingest()
        self.dataframes[name] = df
        
        return df
    
    def ingest_all(self) -> Dict[str, DataFrame]:
        """Ingest from all sources."""
        for name in self.ingesters:
            try:
                self.ingest(name)
            except Exception as e:
                self.logger.error(f"Failed to ingest {name}: {e}")
        
        return self.dataframes
    
    def get_dataframe(self, name: str) -> DataFrame:
        """Get cached DataFrame."""
        if name not in self.dataframes:
            return self.ingest(name)
        return self.dataframes[name]
```

### Step 5.2: Complete Ingestion Example
```python
# src/main.py - Ingestion section
from pyspark.sql import SparkSession
from src.ingestion import IngestionManager
from src.utils.config import Config
from src.utils.logger import get_pipeline_logger

# Initialize
spark = SparkSession.builder \
    .appName("E-Commerce Pipeline") \
    .getOrCreate()

config = Config()
logger = get_pipeline_logger("ingestion")

# Create ingestion manager
ingestion = IngestionManager(spark, config._config)

# Add sources
ingestion.add_csv_source(
    name="orders",
    path=f"{config.paths['raw_data']}/orders.csv",
    schema=orders_schema
)

ingestion.add_csv_source(
    name="products",
    path=f"{config.paths['raw_data']}/products.csv",
    schema=products_schema
)

ingestion.add_db_source(
    name="customers",
    table="customers",
    partition_column="customer_id"
)

# Ingest all
dataframes = ingestion.ingest_all()

# Access data
orders_df = dataframes["orders"]
products_df = dataframes["products"]
customers_df = dataframes["customers"]

logger.info("Ingestion complete")
```

---

## Exercises

1. Create a CSV ingester for orders data
2. Implement API pagination for products
3. Set up database ingestion with partitioning
4. Build an error handling wrapper

---

## Summary
- Created abstract base ingester
- Implemented CSV file ingestion
- Built REST API ingester with pagination
- Created database ingester with JDBC
- Built unified ingestion manager

---

## Next Lab
In the next lab, we'll implement the data transformation layer.
