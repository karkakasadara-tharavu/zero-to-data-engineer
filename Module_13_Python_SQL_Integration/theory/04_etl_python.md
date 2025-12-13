# Building ETL Pipelines with Python - Complete Guide

## 📚 What You'll Learn
- ETL pipeline architecture
- Building reusable ETL components
- Error handling and logging
- Scheduling and orchestration
- Interview preparation

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced

---

## 🎯 ETL Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PYTHON ETL PIPELINE ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        CONFIG / METADATA                        │   │
│   │   - Connection strings, paths, parameters                       │   │
│   │   - Table mappings, column definitions                          │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                   │                                      │
│                                   ▼                                      │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│   │ EXTRACT  │───▶│TRANSFORM │───▶│   LOAD   │───▶│  AUDIT   │         │
│   │          │    │          │    │          │    │          │         │
│   │ - SQL    │    │ - Clean  │    │ - Insert │    │ - Log    │         │
│   │ - CSV    │    │ - Enrich │    │ - Upsert │    │ - Count  │         │
│   │ - API    │    │ - Agg    │    │ - Replace│    │ - Stats  │         │
│   └──────────┘    └──────────┘    └──────────┘    └──────────┘         │
│        │               │               │               │                │
│        └───────────────┴───────────────┴───────────────┘                │
│                                   │                                      │
│                                   ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                     ERROR HANDLING / RETRY                       │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Basic ETL Pipeline

### Simple ETL Script

```python
import pandas as pd
from sqlalchemy import create_engine
import logging
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
SOURCE_CONN = 'postgresql://user:pass@source_host/sourcedb'
TARGET_CONN = 'mssql+pyodbc://user:pass@target_host/targetdb?driver=ODBC+Driver+17+for+SQL+Server'

def extract(engine, query):
    """Extract data from source"""
    logger.info("Starting extraction...")
    df = pd.read_sql(query, engine)
    logger.info(f"Extracted {len(df)} rows")
    return df

def transform(df):
    """Apply transformations"""
    logger.info("Starting transformation...")
    
    # Data cleaning
    df = df.dropna(subset=['customer_id'])
    df['email'] = df['email'].str.lower().str.strip()
    
    # Data enrichment
    df['processed_at'] = datetime.now()
    df['full_name'] = df['first_name'] + ' ' + df['last_name']
    
    # Type conversions
    df['order_date'] = pd.to_datetime(df['order_date'])
    df['amount'] = df['amount'].astype(float)
    
    logger.info(f"Transformed {len(df)} rows")
    return df

def load(df, engine, table_name, if_exists='append'):
    """Load data to target"""
    logger.info(f"Loading to {table_name}...")
    df.to_sql(
        table_name,
        engine,
        if_exists=if_exists,
        index=False,
        chunksize=10000
    )
    logger.info(f"Loaded {len(df)} rows to {table_name}")

def run_pipeline():
    """Execute the ETL pipeline"""
    source_engine = create_engine(SOURCE_CONN)
    target_engine = create_engine(TARGET_CONN)
    
    try:
        # Extract
        df = extract(
            source_engine,
            "SELECT * FROM orders WHERE order_date >= '2023-01-01'"
        )
        
        # Transform
        df = transform(df)
        
        # Load
        load(df, target_engine, 'processed_orders', if_exists='append')
        
        logger.info("Pipeline completed successfully")
        
    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        raise

if __name__ == "__main__":
    run_pipeline()
```

---

## 🏗️ Object-Oriented ETL Framework

### Base ETL Class

```python
from abc import ABC, abstractmethod
import pandas as pd
from sqlalchemy import create_engine
import logging
from datetime import datetime

class BaseETL(ABC):
    """Abstract base class for ETL pipelines"""
    
    def __init__(self, source_conn, target_conn, config=None):
        self.source_engine = create_engine(source_conn)
        self.target_engine = create_engine(target_conn)
        self.config = config or {}
        self.logger = logging.getLogger(self.__class__.__name__)
        self.stats = {
            'start_time': None,
            'end_time': None,
            'rows_extracted': 0,
            'rows_transformed': 0,
            'rows_loaded': 0,
            'errors': []
        }
    
    @abstractmethod
    def extract(self) -> pd.DataFrame:
        """Extract data from source - must be implemented"""
        pass
    
    @abstractmethod
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """Transform data - must be implemented"""
        pass
    
    @abstractmethod
    def load(self, df: pd.DataFrame) -> None:
        """Load data to target - must be implemented"""
        pass
    
    def validate(self, df: pd.DataFrame) -> bool:
        """Validate data before loading"""
        return len(df) > 0
    
    def run(self):
        """Execute the ETL pipeline"""
        self.stats['start_time'] = datetime.now()
        
        try:
            # Extract
            self.logger.info("Starting extraction...")
            df = self.extract()
            self.stats['rows_extracted'] = len(df)
            
            # Transform
            self.logger.info("Starting transformation...")
            df = self.transform(df)
            self.stats['rows_transformed'] = len(df)
            
            # Validate
            if not self.validate(df):
                raise ValueError("Data validation failed")
            
            # Load
            self.logger.info("Starting load...")
            self.load(df)
            self.stats['rows_loaded'] = len(df)
            
            self.logger.info("Pipeline completed successfully")
            
        except Exception as e:
            self.stats['errors'].append(str(e))
            self.logger.error(f"Pipeline failed: {e}")
            raise
        
        finally:
            self.stats['end_time'] = datetime.now()
            self._log_stats()
    
    def _log_stats(self):
        """Log pipeline statistics"""
        duration = self.stats['end_time'] - self.stats['start_time']
        self.logger.info(f"Pipeline Statistics:")
        self.logger.info(f"  Duration: {duration}")
        self.logger.info(f"  Rows Extracted: {self.stats['rows_extracted']}")
        self.logger.info(f"  Rows Transformed: {self.stats['rows_transformed']}")
        self.logger.info(f"  Rows Loaded: {self.stats['rows_loaded']}")
        if self.stats['errors']:
            self.logger.error(f"  Errors: {self.stats['errors']}")
```

### Concrete Implementation

```python
class CustomerOrdersETL(BaseETL):
    """ETL pipeline for customer orders"""
    
    def extract(self) -> pd.DataFrame:
        query = """
            SELECT 
                o.order_id,
                c.customer_id,
                c.first_name,
                c.last_name,
                c.email,
                o.order_date,
                o.amount
            FROM orders o
            JOIN customers c ON o.customer_id = c.customer_id
            WHERE o.order_date >= :start_date
        """
        df = pd.read_sql(
            query,
            self.source_engine,
            params={'start_date': self.config.get('start_date', '2023-01-01')}
        )
        return df
    
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        # Clean email addresses
        df['email'] = df['email'].str.lower().str.strip()
        
        # Create full name
        df['full_name'] = df['first_name'] + ' ' + df['last_name']
        
        # Categorize order amounts
        df['order_size'] = pd.cut(
            df['amount'],
            bins=[0, 100, 500, float('inf')],
            labels=['Small', 'Medium', 'Large']
        )
        
        # Add metadata
        df['etl_timestamp'] = datetime.now()
        
        # Drop intermediate columns
        df = df.drop(columns=['first_name', 'last_name'])
        
        return df
    
    def load(self, df: pd.DataFrame) -> None:
        df.to_sql(
            'dim_customer_orders',
            self.target_engine,
            if_exists='append',
            index=False,
            chunksize=10000
        )
    
    def validate(self, df: pd.DataFrame) -> bool:
        # Check for required columns
        required_cols = ['customer_id', 'order_id', 'amount']
        if not all(col in df.columns for col in required_cols):
            return False
        
        # Check for nulls in key columns
        if df['customer_id'].isna().any():
            return False
        
        return True

# Usage
etl = CustomerOrdersETL(
    source_conn='postgresql://user:pass@source/db',
    target_conn='mssql+pyodbc://user:pass@target/db?driver=ODBC+Driver+17+for+SQL+Server',
    config={'start_date': '2023-06-01'}
)
etl.run()
```

---

## 🔄 Incremental Load Patterns

### Watermark-Based Incremental

```python
class IncrementalETL(BaseETL):
    """Incremental ETL using watermark"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.watermark_table = 'etl_watermarks'
        self.pipeline_name = self.config.get('pipeline_name', 'default')
    
    def get_watermark(self) -> datetime:
        """Get last successful load timestamp"""
        try:
            result = pd.read_sql(
                f"""SELECT last_value FROM {self.watermark_table}
                    WHERE pipeline_name = :name""",
                self.target_engine,
                params={'name': self.pipeline_name}
            )
            if len(result) > 0:
                return result.iloc[0]['last_value']
        except:
            pass
        return datetime(2020, 1, 1)  # Default start
    
    def update_watermark(self, new_value: datetime):
        """Update watermark after successful load"""
        with self.target_engine.begin() as conn:
            conn.execute(
                text(f"""
                    MERGE INTO {self.watermark_table} t
                    USING (SELECT :name as pipeline_name, :val as last_value) s
                    ON t.pipeline_name = s.pipeline_name
                    WHEN MATCHED THEN UPDATE SET last_value = s.last_value
                    WHEN NOT MATCHED THEN INSERT (pipeline_name, last_value)
                        VALUES (s.pipeline_name, s.last_value)
                """),
                {'name': self.pipeline_name, 'val': new_value}
            )
    
    def extract(self) -> pd.DataFrame:
        watermark = self.get_watermark()
        self.logger.info(f"Loading records after {watermark}")
        
        df = pd.read_sql(
            """SELECT * FROM source_table
               WHERE modified_at > :watermark
               ORDER BY modified_at""",
            self.source_engine,
            params={'watermark': watermark}
        )
        
        if len(df) > 0:
            self._max_watermark = df['modified_at'].max()
        
        return df
    
    def load(self, df: pd.DataFrame) -> None:
        if len(df) > 0:
            df.to_sql('target_table', self.target_engine, if_exists='append', index=False)
            self.update_watermark(self._max_watermark)
```

### CDC-Based Incremental

```python
def process_cdc_changes(source_engine, target_engine, table_name):
    """Process Change Data Capture records"""
    
    # Read CDC changes
    cdc_df = pd.read_sql(f"""
        SELECT 
            __$operation,  -- 1=delete, 2=insert, 4=update
            *
        FROM cdc.dbo_{table_name}_CT
        WHERE __$start_lsn > (SELECT last_lsn FROM cdc_tracking WHERE table_name = '{table_name}')
        ORDER BY __$start_lsn
    """, source_engine)
    
    if len(cdc_df) == 0:
        return
    
    # Process by operation type
    inserts = cdc_df[cdc_df['__$operation'] == 2]
    updates = cdc_df[cdc_df['__$operation'] == 4]
    deletes = cdc_df[cdc_df['__$operation'] == 1]
    
    with target_engine.begin() as conn:
        # Apply deletes
        if len(deletes) > 0:
            delete_ids = deletes['id'].tolist()
            conn.execute(
                text(f"DELETE FROM {table_name} WHERE id IN :ids"),
                {'ids': tuple(delete_ids)}
            )
        
        # Apply inserts
        if len(inserts) > 0:
            clean_inserts = inserts.drop(columns=[c for c in inserts.columns if c.startswith('__$')])
            clean_inserts.to_sql(table_name, conn, if_exists='append', index=False)
        
        # Apply updates (using MERGE/UPSERT)
        # ... implementation depends on database
```

---

## ⚠️ Error Handling and Retry

```python
import time
from functools import wraps

def retry(max_attempts=3, delay=5, backoff=2, exceptions=(Exception,)):
    """Retry decorator with exponential backoff"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            attempts = 0
            current_delay = delay
            
            while attempts < max_attempts:
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    attempts += 1
                    if attempts == max_attempts:
                        raise
                    
                    logging.warning(
                        f"Attempt {attempts} failed: {e}. "
                        f"Retrying in {current_delay} seconds..."
                    )
                    time.sleep(current_delay)
                    current_delay *= backoff
        
        return wrapper
    return decorator

class RobustETL(BaseETL):
    """ETL with comprehensive error handling"""
    
    @retry(max_attempts=3, delay=5, exceptions=(ConnectionError, TimeoutError))
    def extract(self) -> pd.DataFrame:
        return pd.read_sql("SELECT * FROM source", self.source_engine)
    
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        errors = []
        
        # Transform with error collection
        for idx, row in df.iterrows():
            try:
                df.at[idx, 'processed_value'] = self._process_row(row)
            except Exception as e:
                errors.append({'index': idx, 'error': str(e)})
                df.at[idx, 'processed_value'] = None
        
        # Log errors
        if errors:
            self.logger.warning(f"Transform errors: {len(errors)} rows failed")
            pd.DataFrame(errors).to_sql(
                'etl_errors', self.target_engine, if_exists='append', index=False
            )
        
        return df
    
    @retry(max_attempts=3, delay=10)
    def load(self, df: pd.DataFrame) -> None:
        # Transactional load with rollback on failure
        with self.target_engine.begin() as conn:
            df.to_sql('target', conn, if_exists='append', index=False)
```

---

## 📊 Data Validation

```python
class DataValidator:
    """Data validation helper"""
    
    def __init__(self, df: pd.DataFrame):
        self.df = df
        self.errors = []
    
    def not_null(self, columns):
        """Check columns are not null"""
        for col in columns:
            null_count = self.df[col].isna().sum()
            if null_count > 0:
                self.errors.append(f"{col}: {null_count} null values")
        return self
    
    def unique(self, columns):
        """Check columns are unique"""
        dup_count = self.df.duplicated(subset=columns).sum()
        if dup_count > 0:
            self.errors.append(f"Duplicate rows on {columns}: {dup_count}")
        return self
    
    def in_range(self, column, min_val=None, max_val=None):
        """Check values are in range"""
        if min_val is not None:
            below = (self.df[column] < min_val).sum()
            if below > 0:
                self.errors.append(f"{column}: {below} values below {min_val}")
        if max_val is not None:
            above = (self.df[column] > max_val).sum()
            if above > 0:
                self.errors.append(f"{column}: {above} values above {max_val}")
        return self
    
    def matches_pattern(self, column, pattern):
        """Check values match regex pattern"""
        non_matching = (~self.df[column].str.match(pattern, na=False)).sum()
        if non_matching > 0:
            self.errors.append(f"{column}: {non_matching} values don't match pattern")
        return self
    
    def is_valid(self) -> bool:
        return len(self.errors) == 0
    
    def get_errors(self) -> list:
        return self.errors

# Usage
validator = (DataValidator(df)
    .not_null(['customer_id', 'email'])
    .unique(['customer_id'])
    .in_range('amount', min_val=0)
    .matches_pattern('email', r'^[\w\.-]+@[\w\.-]+\.\w+$'))

if not validator.is_valid():
    for error in validator.get_errors():
        logger.error(error)
    raise ValueError("Data validation failed")
```

---

## ⏰ Scheduling

### With Schedule Library

```python
import schedule
import time

def daily_etl():
    """Run daily ETL job"""
    etl = CustomerOrdersETL(SOURCE_CONN, TARGET_CONN)
    etl.run()

def hourly_sync():
    """Run hourly sync"""
    etl = IncrementalETL(SOURCE_CONN, TARGET_CONN)
    etl.run()

# Schedule jobs
schedule.every().day.at("02:00").do(daily_etl)
schedule.every().hour.at(":30").do(hourly_sync)

# Run scheduler
while True:
    schedule.run_pending()
    time.sleep(60)
```

### With APScheduler

```python
from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger

scheduler = BlockingScheduler()

# Add jobs with cron triggers
scheduler.add_job(
    daily_etl,
    CronTrigger(hour=2, minute=0),
    id='daily_etl'
)

scheduler.add_job(
    hourly_sync,
    CronTrigger(minute=30),
    id='hourly_sync'
)

scheduler.start()
```

---

## 🎓 Interview Questions

### Q1: What are the three stages of an ETL pipeline?
**A:**
- **Extract**: Read data from source systems
- **Transform**: Clean, enrich, and restructure data
- **Load**: Write data to target system

### Q2: How do you implement incremental loading in Python?
**A:** Use watermark/timestamp tracking:
```python
last_load = get_max_loaded_timestamp()
new_data = extract_where_modified_after(last_load)
load(new_data)
update_watermark(new_data.max_timestamp)
```

### Q3: How do you handle errors in ETL pipelines?
**A:**
- Use try/except with logging
- Implement retry logic with backoff
- Store failed records for later processing
- Use transactions for atomic operations

### Q4: What is the difference between full load and incremental load?
**A:**
- **Full load**: Extract all data every time, replace target
- **Incremental load**: Extract only new/changed records, append/merge

### Q5: How do you validate data before loading?
**A:** Check for:
- Null values in required columns
- Duplicate keys
- Value ranges
- Data type conformance
- Referential integrity

### Q6: What is a watermark in ETL?
**A:** A marker (usually timestamp or ID) that tracks the last successfully processed record, used for incremental loading.

### Q7: How do you handle slowly changing dimensions in Python ETL?
**A:** Implement SCD logic:
- Type 1: Overwrite existing records
- Type 2: Add new row with effective dates, close old row
- Use merge/upsert operations

### Q8: What is connection pooling and why is it important for ETL?
**A:** Reuses database connections instead of creating new ones, reducing overhead. Important for high-volume ETL with many database operations.

### Q9: How do you parallelize ETL operations?
**A:** Use:
- `concurrent.futures.ThreadPoolExecutor` for I/O-bound
- `multiprocessing.Pool` for CPU-bound
- Dask or PySpark for distributed processing

### Q10: How do you make ETL pipelines idempotent?
**A:** Ensure running the same job multiple times produces the same result:
- Use MERGE/UPSERT instead of INSERT
- Include run timestamps
- Use transaction boundaries
- Implement delete-and-reload for target

---

## 🔗 Related Topics
- [← Pandas-SQL Integration](./03_pandas_sql.md)
- [PySpark ETL →](../Module_15_PySpark/)
- [Airflow Orchestration →](../Module_17_Capstone/)

---

*Module 13 Complete! Continue to Spark Introduction*
