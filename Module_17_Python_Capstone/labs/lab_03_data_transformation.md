# Lab 03: Data Transformation Layer

## Overview
Build the data transformation layer for cleansing, enriching, and aggregating data.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Implement data cleansing functions
- ✅ Build data enrichment transformations
- ✅ Create aggregation pipelines
- ✅ Design reusable transformation classes
- ✅ Chain transformations effectively

---

## Part 1: Base Transformer Class

### Step 1.1: Abstract Transformer
```python
# src/transformation/base_transformer.py
from abc import ABC, abstractmethod
from typing import List, Optional, Callable
from pyspark.sql import DataFrame, SparkSession
import logging

logger = logging.getLogger(__name__)


class BaseTransformer(ABC):
    """Abstract base class for data transformers."""
    
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.logger = logging.getLogger(self.__class__.__name__)
        self._transformations: List[Callable[[DataFrame], DataFrame]] = []
    
    @abstractmethod
    def transform(self, df: DataFrame) -> DataFrame:
        """Apply transformations to DataFrame."""
        pass
    
    def add_transformation(self, func: Callable[[DataFrame], DataFrame]):
        """Add a transformation function to the pipeline."""
        self._transformations.append(func)
        return self
    
    def apply_all(self, df: DataFrame) -> DataFrame:
        """Apply all registered transformations."""
        result = df
        for transform in self._transformations:
            self.logger.debug(f"Applying: {transform.__name__}")
            result = transform(result)
        return result
    
    def log_stats(self, df: DataFrame, stage: str):
        """Log DataFrame statistics."""
        count = df.count()
        columns = len(df.columns)
        self.logger.info(f"[{stage}] Rows: {count}, Columns: {columns}")
```

---

## Part 2: Data Cleanser

### Step 2.1: Cleansing Transformations
```python
# src/transformation/cleanser.py
from typing import Dict, List, Optional, Any
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import StringType
from .base_transformer import BaseTransformer
import logging

logger = logging.getLogger(__name__)


class DataCleanser(BaseTransformer):
    """Data cleansing transformations."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any] = None):
        super().__init__(spark)
        self.config = config or {}
    
    def transform(self, df: DataFrame) -> DataFrame:
        """Apply all cleansing transformations."""
        return self.apply_all(df)
    
    # ==================== NULL HANDLING ====================
    
    def drop_nulls(self, columns: List[str] = None, how: str = "any"):
        """Remove rows with null values."""
        def _transform(df: DataFrame) -> DataFrame:
            if columns:
                return df.dropna(how=how, subset=columns)
            return df.dropna(how=how)
        
        _transform.__name__ = "drop_nulls"
        self.add_transformation(_transform)
        return self
    
    def fill_nulls(self, value_map: Dict[str, Any]):
        """Fill null values with specified values."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.fillna(value_map)
        
        _transform.__name__ = "fill_nulls"
        self.add_transformation(_transform)
        return self
    
    def fill_with_default(self, column: str, default_value: Any):
        """Fill nulls in a column with default value."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(
                column,
                F.coalesce(F.col(column), F.lit(default_value))
            )
        
        _transform.__name__ = f"fill_{column}"
        self.add_transformation(_transform)
        return self
    
    # ==================== STRING CLEANING ====================
    
    def trim_strings(self, columns: List[str] = None):
        """Trim whitespace from string columns."""
        def _transform(df: DataFrame) -> DataFrame:
            cols = columns or [f.name for f in df.schema.fields 
                               if isinstance(f.dataType, StringType)]
            for col in cols:
                if col in df.columns:
                    df = df.withColumn(col, F.trim(F.col(col)))
            return df
        
        _transform.__name__ = "trim_strings"
        self.add_transformation(_transform)
        return self
    
    def standardize_case(self, columns: List[str], case: str = "lower"):
        """Standardize string case (lower/upper/title)."""
        def _transform(df: DataFrame) -> DataFrame:
            for col in columns:
                if col in df.columns:
                    if case == "lower":
                        df = df.withColumn(col, F.lower(F.col(col)))
                    elif case == "upper":
                        df = df.withColumn(col, F.upper(F.col(col)))
                    elif case == "title":
                        df = df.withColumn(col, F.initcap(F.col(col)))
            return df
        
        _transform.__name__ = "standardize_case"
        self.add_transformation(_transform)
        return self
    
    def remove_special_chars(self, column: str, pattern: str = r"[^a-zA-Z0-9\s]"):
        """Remove special characters from a column."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(
                column,
                F.regexp_replace(F.col(column), pattern, "")
            )
        
        _transform.__name__ = f"clean_{column}"
        self.add_transformation(_transform)
        return self
    
    # ==================== DUPLICATE HANDLING ====================
    
    def remove_duplicates(self, columns: List[str] = None):
        """Remove duplicate rows."""
        def _transform(df: DataFrame) -> DataFrame:
            if columns:
                return df.dropDuplicates(columns)
            return df.dropDuplicates()
        
        _transform.__name__ = "remove_duplicates"
        self.add_transformation(_transform)
        return self
    
    def keep_latest(self, partition_cols: List[str], order_col: str):
        """Keep only the latest record per partition."""
        def _transform(df: DataFrame) -> DataFrame:
            from pyspark.sql.window import Window
            
            window = Window.partitionBy(partition_cols).orderBy(F.desc(order_col))
            return df \
                .withColumn("_rank", F.row_number().over(window)) \
                .filter(F.col("_rank") == 1) \
                .drop("_rank")
        
        _transform.__name__ = "keep_latest"
        self.add_transformation(_transform)
        return self
    
    # ==================== DATA TYPE CLEANING ====================
    
    def clean_numeric(self, column: str, remove_chars: str = "$,"):
        """Clean numeric column by removing non-numeric characters."""
        def _transform(df: DataFrame) -> DataFrame:
            clean_col = F.col(column)
            for char in remove_chars:
                clean_col = F.regexp_replace(clean_col, f"\\{char}", "")
            return df.withColumn(column, clean_col.cast("double"))
        
        _transform.__name__ = f"clean_numeric_{column}"
        self.add_transformation(_transform)
        return self
    
    def standardize_date(self, column: str, formats: List[str]):
        """Standardize dates from multiple formats."""
        def _transform(df: DataFrame) -> DataFrame:
            parsed = F.coalesce(*[F.to_date(F.col(column), fmt) for fmt in formats])
            return df.withColumn(column, parsed)
        
        _transform.__name__ = f"standardize_date_{column}"
        self.add_transformation(_transform)
        return self
    
    # ==================== VALIDATION ====================
    
    def filter_valid(self, condition: str):
        """Filter rows based on condition."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.filter(condition)
        
        _transform.__name__ = "filter_valid"
        self.add_transformation(_transform)
        return self
    
    def replace_invalid(self, column: str, invalid_values: List, replacement: Any):
        """Replace invalid values with a default."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(
                column,
                F.when(F.col(column).isin(invalid_values), F.lit(replacement))
                .otherwise(F.col(column))
            )
        
        _transform.__name__ = f"replace_invalid_{column}"
        self.add_transformation(_transform)
        return self
```

### Step 2.2: Usage Example
```python
from src.transformation.cleanser import DataCleanser

# Create cleanser with chained transformations
cleanser = DataCleanser(spark) \
    .trim_strings() \
    .standardize_case(["email", "name"], case="lower") \
    .drop_nulls(columns=["customer_id", "email"]) \
    .remove_duplicates(["customer_id"]) \
    .fill_nulls({"phone": "N/A", "age": 0})

# Apply transformations
cleaned_df = cleanser.transform(raw_df)
cleaned_df.show()
```

---

## Part 3: Data Enricher

### Step 3.1: Enrichment Transformations
```python
# src/transformation/enricher.py
from typing import Dict, List, Any, Callable
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import StringType
from .base_transformer import BaseTransformer
import logging

logger = logging.getLogger(__name__)


class DataEnricher(BaseTransformer):
    """Data enrichment transformations."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any] = None):
        super().__init__(spark)
        self.config = config or {}
        self.lookup_tables: Dict[str, DataFrame] = {}
    
    def transform(self, df: DataFrame) -> DataFrame:
        """Apply all enrichment transformations."""
        return self.apply_all(df)
    
    # ==================== DERIVED COLUMNS ====================
    
    def add_calculated_column(self, name: str, expression):
        """Add a calculated column."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(name, expression)
        
        _transform.__name__ = f"add_{name}"
        self.add_transformation(_transform)
        return self
    
    def add_total_amount(self, quantity_col: str, price_col: str, result_col: str = "total_amount"):
        """Calculate total amount from quantity and price."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(
                result_col,
                F.round(F.col(quantity_col) * F.col(price_col), 2)
            )
        
        _transform.__name__ = "add_total_amount"
        self.add_transformation(_transform)
        return self
    
    # ==================== DATE ENRICHMENT ====================
    
    def add_date_parts(self, date_column: str, parts: List[str] = None):
        """Extract date parts (year, month, day, etc.)."""
        parts = parts or ["year", "month", "day", "dayofweek", "quarter"]
        
        def _transform(df: DataFrame) -> DataFrame:
            if "year" in parts:
                df = df.withColumn(f"{date_column}_year", F.year(date_column))
            if "month" in parts:
                df = df.withColumn(f"{date_column}_month", F.month(date_column))
            if "day" in parts:
                df = df.withColumn(f"{date_column}_day", F.dayofmonth(date_column))
            if "dayofweek" in parts:
                df = df.withColumn(f"{date_column}_dow", F.dayofweek(date_column))
            if "quarter" in parts:
                df = df.withColumn(f"{date_column}_quarter", F.quarter(date_column))
            if "week" in parts:
                df = df.withColumn(f"{date_column}_week", F.weekofyear(date_column))
            return df
        
        _transform.__name__ = "add_date_parts"
        self.add_transformation(_transform)
        return self
    
    def add_is_weekend(self, date_column: str, result_col: str = "is_weekend"):
        """Add flag for weekend dates."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(
                result_col,
                F.dayofweek(date_column).isin([1, 7])
            )
        
        _transform.__name__ = "add_is_weekend"
        self.add_transformation(_transform)
        return self
    
    # ==================== CATEGORICAL ENRICHMENT ====================
    
    def add_category(self, column: str, bins: List, labels: List, result_col: str = None):
        """Categorize numeric column into bins."""
        result_col = result_col or f"{column}_category"
        
        def _transform(df: DataFrame) -> DataFrame:
            conditions = []
            for i, label in enumerate(labels):
                if i == 0:
                    cond = F.col(column) < bins[0]
                elif i == len(labels) - 1:
                    cond = F.col(column) >= bins[-1]
                else:
                    cond = (F.col(column) >= bins[i-1]) & (F.col(column) < bins[i])
                conditions.append((cond, label))
            
            expr = F.when(conditions[0][0], conditions[0][1])
            for cond, label in conditions[1:]:
                expr = expr.when(cond, label)
            
            return df.withColumn(result_col, expr)
        
        _transform.__name__ = f"add_category_{column}"
        self.add_transformation(_transform)
        return self
    
    def add_age_group(self, age_column: str, result_col: str = "age_group"):
        """Categorize age into groups."""
        return self.add_category(
            column=age_column,
            bins=[18, 25, 35, 45, 55, 65],
            labels=["<18", "18-24", "25-34", "35-44", "45-54", "55-64", "65+"],
            result_col=result_col
        )
    
    # ==================== LOOKUP ENRICHMENT ====================
    
    def register_lookup(self, name: str, df: DataFrame):
        """Register a lookup table."""
        self.lookup_tables[name] = df
        self.logger.info(f"Registered lookup table: {name}")
        return self
    
    def join_lookup(
        self, 
        lookup_name: str, 
        join_key: str, 
        lookup_key: str = None,
        columns: List[str] = None,
        join_type: str = "left"
    ):
        """Join with lookup table."""
        lookup_key = lookup_key or join_key
        
        def _transform(df: DataFrame) -> DataFrame:
            lookup = self.lookup_tables.get(lookup_name)
            if lookup is None:
                raise ValueError(f"Lookup table not found: {lookup_name}")
            
            # Select columns from lookup
            if columns:
                lookup_cols = [lookup_key] + [c for c in columns if c != lookup_key]
                lookup = lookup.select(lookup_cols)
            
            # Rename to avoid conflicts
            for col in lookup.columns:
                if col != lookup_key and col in df.columns:
                    lookup = lookup.withColumnRenamed(col, f"{lookup_name}_{col}")
            
            return df.join(
                lookup,
                df[join_key] == lookup[lookup_key],
                join_type
            ).drop(lookup[lookup_key])
        
        _transform.__name__ = f"join_{lookup_name}"
        self.add_transformation(_transform)
        return self
    
    # ==================== TEXT ENRICHMENT ====================
    
    def add_text_length(self, column: str, result_col: str = None):
        """Add length of text column."""
        result_col = result_col or f"{column}_length"
        
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(result_col, F.length(F.col(column)))
        
        _transform.__name__ = f"add_length_{column}"
        self.add_transformation(_transform)
        return self
    
    def add_word_count(self, column: str, result_col: str = None):
        """Add word count for text column."""
        result_col = result_col or f"{column}_word_count"
        
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(
                result_col,
                F.size(F.split(F.col(column), r"\s+"))
            )
        
        _transform.__name__ = f"add_word_count_{column}"
        self.add_transformation(_transform)
        return self
    
    # ==================== CONDITIONAL ENRICHMENT ====================
    
    def add_flag(self, name: str, condition):
        """Add boolean flag based on condition."""
        def _transform(df: DataFrame) -> DataFrame:
            return df.withColumn(name, condition)
        
        _transform.__name__ = f"add_flag_{name}"
        self.add_transformation(_transform)
        return self
    
    def add_status(self, name: str, conditions: Dict[str, Any], default: Any = "unknown"):
        """Add status column based on multiple conditions."""
        def _transform(df: DataFrame) -> DataFrame:
            expr = None
            for status, condition in conditions.items():
                if expr is None:
                    expr = F.when(condition, status)
                else:
                    expr = expr.when(condition, status)
            expr = expr.otherwise(default)
            return df.withColumn(name, expr)
        
        _transform.__name__ = f"add_status_{name}"
        self.add_transformation(_transform)
        return self
```

### Step 3.2: Usage Example
```python
from src.transformation.enricher import DataEnricher

# Create enricher
enricher = DataEnricher(spark)

# Register lookup tables
enricher.register_lookup("products", products_df)
enricher.register_lookup("customers", customers_df)

# Chain enrichments
enricher \
    .add_total_amount("quantity", "unit_price") \
    .add_date_parts("order_date", ["year", "month", "quarter"]) \
    .add_is_weekend("order_date") \
    .join_lookup("products", join_key="product_id", columns=["product_name", "category"]) \
    .join_lookup("customers", join_key="customer_id", columns=["customer_name", "region"]) \
    .add_status(
        "order_status",
        {
            "high_value": F.col("total_amount") > 1000,
            "medium_value": F.col("total_amount") > 100,
            "low_value": F.col("total_amount") <= 100
        }
    )

# Apply transformations
enriched_df = enricher.transform(orders_df)
enriched_df.show()
```

---

## Part 4: Data Aggregator

### Step 4.1: Aggregation Transformations
```python
# src/transformation/aggregator.py
from typing import Dict, List, Any
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from pyspark.sql.window import Window
from .base_transformer import BaseTransformer
import logging

logger = logging.getLogger(__name__)


class DataAggregator(BaseTransformer):
    """Data aggregation transformations."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any] = None):
        super().__init__(spark)
        self.config = config or {}
    
    def transform(self, df: DataFrame) -> DataFrame:
        """Apply all aggregation transformations."""
        return self.apply_all(df)
    
    # ==================== BASIC AGGREGATIONS ====================
    
    def aggregate(
        self,
        group_by: List[str],
        aggregations: Dict[str, List[str]]
    ) -> 'DataAggregator':
        """
        Perform aggregations.
        
        Args:
            group_by: Columns to group by
            aggregations: Dict of column -> [agg_functions]
                e.g., {"amount": ["sum", "avg", "count"]}
        """
        def _transform(df: DataFrame) -> DataFrame:
            agg_exprs = []
            
            for column, funcs in aggregations.items():
                for func in funcs:
                    if func == "sum":
                        agg_exprs.append(F.sum(column).alias(f"{column}_sum"))
                    elif func == "avg":
                        agg_exprs.append(F.avg(column).alias(f"{column}_avg"))
                    elif func == "count":
                        agg_exprs.append(F.count(column).alias(f"{column}_count"))
                    elif func == "min":
                        agg_exprs.append(F.min(column).alias(f"{column}_min"))
                    elif func == "max":
                        agg_exprs.append(F.max(column).alias(f"{column}_max"))
                    elif func == "stddev":
                        agg_exprs.append(F.stddev(column).alias(f"{column}_stddev"))
                    elif func == "distinct_count":
                        agg_exprs.append(F.countDistinct(column).alias(f"{column}_distinct"))
            
            return df.groupBy(group_by).agg(*agg_exprs)
        
        _transform.__name__ = "aggregate"
        self.add_transformation(_transform)
        return self
    
    # ==================== DAILY AGGREGATIONS ====================
    
    def daily_summary(
        self,
        date_column: str,
        value_column: str,
        additional_group_by: List[str] = None
    ):
        """Create daily summary."""
        group_cols = [F.to_date(date_column).alias("date")]
        if additional_group_by:
            group_cols.extend(additional_group_by)
        
        def _transform(df: DataFrame) -> DataFrame:
            return df.groupBy(group_cols).agg(
                F.count("*").alias("record_count"),
                F.sum(value_column).alias("total_value"),
                F.avg(value_column).alias("avg_value"),
                F.min(value_column).alias("min_value"),
                F.max(value_column).alias("max_value")
            ).orderBy("date")
        
        _transform.__name__ = "daily_summary"
        self.add_transformation(_transform)
        return self
    
    # ==================== WINDOW AGGREGATIONS ====================
    
    def add_running_total(
        self,
        value_column: str,
        partition_by: List[str],
        order_by: str,
        result_col: str = None
    ):
        """Add running total using window function."""
        result_col = result_col or f"{value_column}_running_total"
        
        def _transform(df: DataFrame) -> DataFrame:
            window = Window \
                .partitionBy(partition_by) \
                .orderBy(order_by) \
                .rowsBetween(Window.unboundedPreceding, Window.currentRow)
            
            return df.withColumn(result_col, F.sum(value_column).over(window))
        
        _transform.__name__ = "add_running_total"
        self.add_transformation(_transform)
        return self
    
    def add_moving_average(
        self,
        value_column: str,
        partition_by: List[str],
        order_by: str,
        window_size: int = 7,
        result_col: str = None
    ):
        """Add moving average."""
        result_col = result_col or f"{value_column}_ma_{window_size}"
        
        def _transform(df: DataFrame) -> DataFrame:
            window = Window \
                .partitionBy(partition_by) \
                .orderBy(order_by) \
                .rowsBetween(-(window_size - 1), Window.currentRow)
            
            return df.withColumn(
                result_col,
                F.round(F.avg(value_column).over(window), 2)
            )
        
        _transform.__name__ = "add_moving_average"
        self.add_transformation(_transform)
        return self
    
    def add_rank(
        self,
        partition_by: List[str],
        order_by: str,
        descending: bool = True,
        result_col: str = "rank"
    ):
        """Add rank within partition."""
        def _transform(df: DataFrame) -> DataFrame:
            order = F.desc(order_by) if descending else F.asc(order_by)
            window = Window.partitionBy(partition_by).orderBy(order)
            return df.withColumn(result_col, F.rank().over(window))
        
        _transform.__name__ = "add_rank"
        self.add_transformation(_transform)
        return self
    
    def add_percent_of_total(
        self,
        value_column: str,
        partition_by: List[str],
        result_col: str = None
    ):
        """Add percentage of total within partition."""
        result_col = result_col or f"{value_column}_pct"
        
        def _transform(df: DataFrame) -> DataFrame:
            window = Window.partitionBy(partition_by)
            return df.withColumn(
                result_col,
                F.round(F.col(value_column) / F.sum(value_column).over(window) * 100, 2)
            )
        
        _transform.__name__ = "add_percent_of_total"
        self.add_transformation(_transform)
        return self
    
    # ==================== TOP N ====================
    
    def top_n(
        self,
        n: int,
        partition_by: List[str],
        order_by: str,
        descending: bool = True
    ):
        """Keep only top N records per partition."""
        def _transform(df: DataFrame) -> DataFrame:
            order = F.desc(order_by) if descending else F.asc(order_by)
            window = Window.partitionBy(partition_by).orderBy(order)
            
            return df \
                .withColumn("_rank", F.row_number().over(window)) \
                .filter(F.col("_rank") <= n) \
                .drop("_rank")
        
        _transform.__name__ = f"top_{n}"
        self.add_transformation(_transform)
        return self
    
    # ==================== PIVOT ====================
    
    def pivot_table(
        self,
        group_by: List[str],
        pivot_column: str,
        value_column: str,
        agg_func: str = "sum"
    ):
        """Create pivot table."""
        def _transform(df: DataFrame) -> DataFrame:
            grouped = df.groupBy(group_by).pivot(pivot_column)
            
            if agg_func == "sum":
                return grouped.sum(value_column)
            elif agg_func == "avg":
                return grouped.avg(value_column)
            elif agg_func == "count":
                return grouped.count()
            else:
                return grouped.sum(value_column)
        
        _transform.__name__ = "pivot_table"
        self.add_transformation(_transform)
        return self
```

### Step 4.2: Usage Example
```python
from src.transformation.aggregator import DataAggregator

# Create sales summary
aggregator = DataAggregator(spark)

# Daily sales by region
aggregator.daily_summary(
    date_column="order_date",
    value_column="total_amount",
    additional_group_by=["region"]
)

daily_sales = aggregator.transform(enriched_df)

# Product ranking by category
ranking_aggregator = DataAggregator(spark) \
    .aggregate(
        group_by=["category", "product_id"],
        aggregations={"total_amount": ["sum", "count"]}
    ) \
    .add_rank(
        partition_by=["category"],
        order_by="total_amount_sum"
    ) \
    .top_n(n=10, partition_by=["category"], order_by="total_amount_sum")

top_products = ranking_aggregator.transform(enriched_df)
```

---

## Part 5: Transformation Pipeline

### Step 5.1: Pipeline Orchestrator
```python
# src/transformation/pipeline.py
from typing import Dict, List, Any, Optional
from pyspark.sql import DataFrame, SparkSession
from .cleanser import DataCleanser
from .enricher import DataEnricher
from .aggregator import DataAggregator
import logging

logger = logging.getLogger(__name__)


class TransformationPipeline:
    """Orchestrate multiple transformation stages."""
    
    def __init__(self, spark: SparkSession, config: Dict[str, Any] = None):
        self.spark = spark
        self.config = config or {}
        self.logger = logging.getLogger(__name__)
        self.stages = []
        self.intermediate_results = {}
    
    def add_stage(
        self,
        name: str,
        transformer,
        cache: bool = False
    ):
        """Add a transformation stage."""
        self.stages.append({
            "name": name,
            "transformer": transformer,
            "cache": cache
        })
        self.logger.info(f"Added stage: {name}")
        return self
    
    def run(self, df: DataFrame) -> DataFrame:
        """Run all transformation stages."""
        result = df
        
        for stage in self.stages:
            name = stage["name"]
            transformer = stage["transformer"]
            should_cache = stage["cache"]
            
            self.logger.info(f"Running stage: {name}")
            
            # Execute transformation
            result = transformer.transform(result)
            
            # Cache if requested
            if should_cache:
                result = result.cache()
                count = result.count()  # Materialize cache
                self.logger.info(f"Cached stage {name}: {count} rows")
            
            # Store intermediate result
            self.intermediate_results[name] = result
        
        return result
    
    def get_intermediate(self, stage_name: str) -> Optional[DataFrame]:
        """Get intermediate result from a stage."""
        return self.intermediate_results.get(stage_name)
```

### Step 5.2: Complete Pipeline Example
```python
# Complete transformation pipeline
from src.transformation.pipeline import TransformationPipeline
from src.transformation import DataCleanser, DataEnricher, DataAggregator

# Initialize components
spark = SparkSession.builder.appName("Transform").getOrCreate()

# Create transformers
cleanser = DataCleanser(spark) \
    .trim_strings() \
    .drop_nulls(columns=["customer_id", "order_date"]) \
    .remove_duplicates(["order_id"])

enricher = DataEnricher(spark)
enricher.register_lookup("products", products_df)
enricher \
    .add_total_amount("quantity", "unit_price") \
    .add_date_parts("order_date") \
    .join_lookup("products", "product_id", columns=["category", "product_name"])

aggregator = DataAggregator(spark) \
    .add_running_total("total_amount", ["customer_id"], "order_date") \
    .add_rank(["category"], "total_amount")

# Build pipeline
pipeline = TransformationPipeline(spark)
pipeline \
    .add_stage("cleanse", cleanser) \
    .add_stage("enrich", enricher, cache=True) \
    .add_stage("aggregate", aggregator)

# Run pipeline
final_df = pipeline.run(raw_orders_df)
final_df.show()

# Access intermediate results
enriched_df = pipeline.get_intermediate("enrich")
```

---

## Exercises

1. Create a cleanser for customer data
2. Build an enricher that adds customer segments
3. Create daily and monthly aggregations
4. Build a complete transformation pipeline

---

## Summary
- Built modular transformation classes
- Implemented data cleansing functions
- Created enrichment transformations
- Built aggregation pipelines
- Orchestrated multi-stage transformations

---

## Next Lab
In the next lab, we'll implement the data loading layer and warehouse.
