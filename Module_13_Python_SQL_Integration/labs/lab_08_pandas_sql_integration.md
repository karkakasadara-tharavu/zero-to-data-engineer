# Lab 08: Pandas-SQL Integration

## Learning Objectives

- Use pandas to read data from databases
- Write DataFrames to SQL tables efficiently
- Handle type mapping between pandas and SQL
- Implement ETL pipelines with pandas and SQL
- Optimize chunked reading and writing for large datasets

## Prerequisites

- Pandas fundamentals
- SQLAlchemy connections
- Completion of Labs 01-07

## Tasks

### Task 1: Reading Data with pandas (25 points)

Implement various strategies for reading SQL data into DataFrames.

**Requirements:**
```python
import pandas as pd
from sqlalchemy import create_engine
import time

# Sample database schema
"""
CREATE TABLE sales (
    id INTEGER PRIMARY KEY,
    date DATE,
    product_id INTEGER,
    product_name VARCHAR(200),
    category VARCHAR(50),
    quantity INTEGER,
    unit_price FLOAT,
    total_amount FLOAT,
    customer_id INTEGER,
    region VARCHAR(50)
);

-- 1,000,000 rows
"""

def read_entire_table(engine):
    """
    Read entire table into DataFrame
    
    Args:
        engine: SQLAlchemy engine
    
    Returns:
        DataFrame with all sales data
    """
    # TODO: Use pd.read_sql_table()
    df = pd.read_sql_table('sales', engine)
    return df

def read_with_query(engine, start_date, end_date):
    """
    Read data using SQL query
    
    Args:
        engine: SQLAlchemy engine
        start_date: Start date
        end_date: End date
    
    Returns:
        Filtered DataFrame
    """
    # TODO: Use pd.read_sql_query()
    query = """
        SELECT date, product_name, category, quantity, total_amount, region
        FROM sales
        WHERE date BETWEEN :start_date AND :end_date
        ORDER BY date
    """
    df = pd.read_sql_query(query, engine, params={
        'start_date': start_date,
        'end_date': end_date
    })
    return df

def read_in_chunks(engine, chunk_size=10000):
    """
    Read large table in chunks
    
    Args:
        engine: SQLAlchemy engine
        chunk_size: Number of rows per chunk
    
    Yields:
        DataFrame chunks
    """
    # TODO: Use chunksize parameter
    query = "SELECT * FROM sales"
    
    for chunk in pd.read_sql_query(query, engine, chunksize=chunk_size):
        # Process chunk
        yield chunk

def read_with_aggregation(engine):
    """
    Read pre-aggregated data
    
    Args:
        engine: SQLAlchemy engine
    
    Returns:
        Aggregated DataFrame
    """
    # TODO: Aggregate in SQL before loading
    query = """
        SELECT 
            category,
            region,
            DATE_TRUNC('month', date) as month,
            COUNT(*) as transaction_count,
            SUM(quantity) as total_quantity,
            SUM(total_amount) as total_revenue,
            AVG(total_amount) as avg_transaction
        FROM sales
        GROUP BY category, region, DATE_TRUNC('month', date)
        ORDER BY month, category, region
    """
    df = pd.read_sql_query(query, engine)
    df['month'] = pd.to_datetime(df['month'])
    return df

def benchmark_read_methods(engine):
    """
    Compare performance of different read methods
    
    Returns:
        DataFrame with benchmark results
    """
    results = []
    
    # TODO: Time each method
    # 1. read_sql_table
    # 2. read_sql_query (simple)
    # 3. read_sql_query (filtered)
    # 4. read_sql_query (aggregated)
    # 5. Chunked reading
    
    return pd.DataFrame(results)
```

### Task 2: Writing Data to SQL (25 points)

Implement efficient strategies for writing DataFrames to databases.

**Requirements:**
```python
def write_dataframe_basic(df, engine, table_name):
    """
    Basic DataFrame write
    
    Args:
        df: DataFrame to write
        engine: SQLAlchemy engine
        table_name: Target table name
    """
    # TODO: Use to_sql() with different if_exists options
    # if_exists='fail': Raise error if table exists
    # if_exists='replace': Drop and recreate table
    # if_exists='append': Insert new data
    
    df.to_sql(table_name, engine, if_exists='replace', index=False)

def write_with_dtype_mapping(df, engine, table_name):
    """
    Write with explicit dtype mapping
    
    Args:
        df: DataFrame
        engine: SQLAlchemy engine
        table_name: Table name
    """
    from sqlalchemy.types import Integer, String, Float, DateTime
    
    # TODO: Define explicit dtypes
    dtypes = {
        'id': Integer,
        'date': DateTime,
        'product_name': String(200),
        'category': String(50),
        'quantity': Integer,
        'unit_price': Float,
        'total_amount': Float,
        'region': String(50)
    }
    
    df.to_sql(table_name, engine, if_exists='replace', 
              index=False, dtype=dtypes)

def write_in_chunks(df, engine, table_name, chunk_size=1000):
    """
    Write large DataFrame in chunks
    
    Args:
        df: Large DataFrame
        engine: SQLAlchemy engine
        table_name: Table name
        chunk_size: Rows per chunk
    """
    # TODO: Use chunksize parameter
    df.to_sql(table_name, engine, if_exists='replace',
              index=False, chunksize=chunk_size)

def write_with_method(df, engine, table_name):
    """
    Use different insert methods
    
    Args:
        df: DataFrame
        engine: SQLAlchemy engine
        table_name: Table name
    """
    # TODO: Compare 'multi' vs None for method parameter
    
    # Method 1: Single inserts (slow)
    start = time.time()
    df.to_sql(table_name + '_single', engine, if_exists='replace',
              index=False, method=None)
    single_time = time.time() - start
    
    # Method 2: Multi-row inserts (fast)
    start = time.time()
    df.to_sql(table_name + '_multi', engine, if_exists='replace',
              index=False, method='multi')
    multi_time = time.time() - start
    
    return {'single': single_time, 'multi': multi_time}

def bulk_insert_with_copy(df, engine, table_name):
    """
    Use PostgreSQL COPY for fastest bulk insert
    
    Args:
        df: DataFrame
        engine: SQLAlchemy engine (PostgreSQL)
        table_name: Table name
    """
    from io import StringIO
    
    # TODO: Use COPY command for PostgreSQL
    # Convert DataFrame to CSV in memory
    output = StringIO()
    df.to_csv(output, sep='\t', header=False, index=False)
    output.seek(0)
    
    # Use raw connection
    connection = engine.raw_connection()
    cursor = connection.cursor()
    
    try:
        cursor.copy_from(output, table_name, null='')
        connection.commit()
    finally:
        cursor.close()
        connection.close()
```

### Task 3: ETL Pipeline Implementation (25 points)

Build complete ETL pipelines combining pandas and SQL.

**Requirements:**
```python
class ETLPipeline:
    """ETL Pipeline for data processing"""
    
    def __init__(self, source_engine, target_engine):
        self.source_engine = source_engine
        self.target_engine = target_engine
    
    def extract(self, query, chunk_size=10000):
        """
        Extract data from source database
        
        Args:
            query: SQL query
            chunk_size: Chunk size for reading
        
        Yields:
            Data chunks
        """
        # TODO: Read data in chunks
        for chunk in pd.read_sql_query(query, self.source_engine,
                                       chunksize=chunk_size):
            yield chunk
    
    def transform(self, df):
        """
        Transform data
        
        Args:
            df: Input DataFrame
        
        Returns:
            Transformed DataFrame
        """
        # TODO: Implement transformations
        # 1. Clean data (handle nulls, outliers)
        # 2. Calculate derived columns
        # 3. Normalize/denormalize
        # 4. Aggregate if needed
        
        # Example transformations
        df = df.dropna()
        df['profit_margin'] = (df['total_amount'] - df['cost']) / df['total_amount']
        df['year_month'] = pd.to_datetime(df['date']).dt.to_period('M')
        
        return df
    
    def load(self, df, table_name, if_exists='append'):
        """
        Load data to target database
        
        Args:
            df: DataFrame to load
            table_name: Target table
            if_exists: How to handle existing table
        """
        # TODO: Write to target database
        df.to_sql(table_name, self.target_engine,
                 if_exists=if_exists, index=False,
                 method='multi', chunksize=1000)
    
    def run(self, source_query, target_table, transform_func=None):
        """
        Run complete ETL pipeline
        
        Args:
            source_query: Query to extract data
            target_table: Target table name
            transform_func: Optional custom transform function
        
        Returns:
            Statistics about the ETL run
        """
        stats = {
            'rows_extracted': 0,
            'rows_loaded': 0,
            'start_time': time.time()
        }
        
        # TODO: Implement pipeline
        for chunk in self.extract(source_query):
            stats['rows_extracted'] += len(chunk)
            
            # Transform
            if transform_func:
                chunk = transform_func(chunk)
            else:
                chunk = self.transform(chunk)
            
            # Load
            self.load(chunk, target_table)
            stats['rows_loaded'] += len(chunk)
        
        stats['end_time'] = time.time()
        stats['duration'] = stats['end_time'] - stats['start_time']
        
        return stats

# Example usage
def sales_etl_example():
    """Example ETL pipeline for sales data"""
    source = create_engine('postgresql://user:pass@source/db')
    target = create_engine('postgresql://user:pass@target/db')
    
    pipeline = ETLPipeline(source, target)
    
    # Extract query
    query = """
        SELECT s.*, p.cost
        FROM sales s
        JOIN products p ON s.product_id = p.id
        WHERE s.date >= CURRENT_DATE - INTERVAL '1 year'
    """
    
    # Custom transform
    def custom_transform(df):
        # Calculate metrics
        df['profit'] = df['total_amount'] - (df['cost'] * df['quantity'])
        df['profit_margin'] = df['profit'] / df['total_amount']
        
        # Categorize
        df['profit_category'] = pd.cut(df['profit_margin'],
                                       bins=[-float('inf'), 0, 0.2, 0.5, float('inf')],
                                       labels=['loss', 'low', 'medium', 'high'])
        
        return df
    
    # Run pipeline
    stats = pipeline.run(query, 'sales_enriched', custom_transform)
    print(f"ETL completed: {stats}")
```

### Task 4: Advanced Integration Patterns (25 points)

Implement advanced patterns for pandas-SQL integration.

**Requirements:**
```python
def incremental_load(engine, table_name, last_id=0):
    """
    Perform incremental data load
    
    Args:
        engine: SQLAlchemy engine
        table_name: Table name
        last_id: Last processed ID
    
    Returns:
        New data and new last_id
    """
    # TODO: Load only new records
    query = f"""
        SELECT * FROM {table_name}
        WHERE id > {last_id}
        ORDER BY id
    """
    
    df = pd.read_sql_query(query, engine)
    
    if len(df) > 0:
        new_last_id = df['id'].max()
    else:
        new_last_id = last_id
    
    return df, new_last_id

def upsert_dataframe(df, engine, table_name, key_columns):
    """
    Upsert (insert or update) DataFrame to database
    
    Args:
        df: DataFrame
        engine: SQLAlchemy engine
        table_name: Table name
        key_columns: Columns to match for updates
    """
    from sqlalchemy import MetaData, Table
    from sqlalchemy.dialects.postgresql import insert
    
    # TODO: Implement upsert logic
    # For PostgreSQL: Use ON CONFLICT DO UPDATE
    # For other databases: May need separate insert/update
    
    metadata = MetaData()
    table = Table(table_name, metadata, autoload_with=engine)
    
    with engine.begin() as connection:
        for _, row in df.iterrows():
            stmt = insert(table).values(**row.to_dict())
            
            # Create update dict (exclude key columns)
            update_dict = {c: row[c] for c in df.columns if c not in key_columns}
            
            stmt = stmt.on_conflict_do_update(
                index_elements=key_columns,
                set_=update_dict
            )
            
            connection.execute(stmt)

def parallel_load(df, engine, table_name, num_workers=4):
    """
    Load DataFrame in parallel using multiple connections
    
    Args:
        df: DataFrame to load
        engine: SQLAlchemy engine
        table_name: Table name
        num_workers: Number of parallel workers
    """
    from concurrent.futures import ThreadPoolExecutor
    import numpy as np
    
    # TODO: Split DataFrame and load in parallel
    chunks = np.array_split(df, num_workers)
    
    def load_chunk(chunk):
        chunk.to_sql(table_name, engine, if_exists='append',
                    index=False, method='multi')
        return len(chunk)
    
    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        results = list(executor.map(load_chunk, chunks))
    
    return sum(results)

def create_summary_table(engine, source_table, summary_table):
    """
    Create and maintain summary table
    
    Args:
        engine: SQLAlchemy engine
        source_table: Source data table
        summary_table: Summary table name
    """
    # TODO: Read, aggregate, and write summary
    query = f"""
        SELECT 
            category,
            DATE_TRUNC('day', date) as day,
            COUNT(*) as transaction_count,
            SUM(quantity) as total_quantity,
            SUM(total_amount) as total_revenue,
            AVG(total_amount) as avg_revenue
        FROM {source_table}
        GROUP BY category, DATE_TRUNC('day', date)
    """
    
    summary_df = pd.read_sql_query(query, engine)
    summary_df.to_sql(summary_table, engine, if_exists='replace',
                     index=False, method='multi')
    
    return summary_df

def data_quality_check(df, engine, table_name):
    """
    Perform data quality checks before loading
    
    Args:
        df: DataFrame to check
        engine: SQLAlchemy engine
        table_name: Table name
    
    Returns:
        Dict with quality metrics
    """
    quality_report = {}
    
    # TODO: Implement checks
    # 1. Check for nulls
    quality_report['null_counts'] = df.isnull().sum().to_dict()
    
    # 2. Check for duplicates
    quality_report['duplicates'] = df.duplicated().sum()
    
    # 3. Check data types
    quality_report['dtypes'] = df.dtypes.astype(str).to_dict()
    
    # 4. Check value ranges
    numeric_cols = df.select_dtypes(include=['number']).columns
    quality_report['ranges'] = {
        col: {'min': df[col].min(), 'max': df[col].max()}
        for col in numeric_cols
    }
    
    # 5. Check against existing table schema
    existing_df = pd.read_sql_table(table_name, engine, limit=1)
    quality_report['schema_match'] = list(df.columns) == list(existing_df.columns)
    
    return quality_report
```

## Testing

```python
import unittest
import pandas as pd
from sqlalchemy import create_engine

class TestPandasSQLIntegration(unittest.TestCase):
    """Test pandas-SQL integration"""
    
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine('sqlite:///test_pandas_sql.db')
        
        # Create sample data
        cls.sample_data = pd.DataFrame({
            'id': range(1, 101),
            'date': pd.date_range('2024-01-01', periods=100),
            'product': ['Product_' + str(i % 10) for i in range(100)],
            'quantity': [10 + i % 50 for i in range(100)],
            'price': [100.0 + (i % 20) * 10 for i in range(100)]
        })
        
        cls.sample_data['total'] = cls.sample_data['quantity'] * cls.sample_data['price']
    
    def test_write_and_read(self):
        """Test basic write and read"""
        # Write
        self.sample_data.to_sql('test_table', self.engine,
                               if_exists='replace', index=False)
        
        # Read
        df = pd.read_sql_table('test_table', self.engine)
        
        self.assertEqual(len(df), 100)
        self.assertListEqual(list(df.columns), list(self.sample_data.columns))
    
    def test_chunked_operations(self):
        """Test chunked read and write"""
        # Write in chunks
        for i, chunk in enumerate(np.array_split(self.sample_data, 10)):
            chunk.to_sql('test_chunks', self.engine,
                        if_exists='append' if i > 0 else 'replace',
                        index=False)
        
        # Read back
        df = pd.read_sql_table('test_chunks', self.engine)
        self.assertEqual(len(df), 100)
    
    def test_etl_pipeline(self):
        """Test ETL pipeline"""
        pipeline = ETLPipeline(self.engine, self.engine)
        
        # Write source data
        self.sample_data.to_sql('source_table', self.engine,
                               if_exists='replace', index=False)
        
        # Run ETL
        stats = pipeline.run('SELECT * FROM source_table', 'target_table')
        
        # Check results
        self.assertEqual(stats['rows_extracted'], 100)
        
        # Verify target
        df = pd.read_sql_table('target_table', self.engine)
        self.assertGreater(len(df), 0)
    
    @classmethod
    def tearDownClass(cls):
        import os
        if os.path.exists('test_pandas_sql.db'):
            os.remove('test_pandas_sql.db')

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **read_operations.py**: All read strategies
2. **write_operations.py**: All write strategies
3. **etl_pipeline.py**: Complete ETL implementation
4. **advanced_patterns.py**: Advanced integration patterns
5. **performance_report.md**: Benchmark results
6. **tests.py**: Test suite

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 25 | Reading strategies work efficiently |
| Task 2 | 25 | Writing optimized for performance |
| Task 3 | 25 | ETL pipeline complete and robust |
| Task 4 | 25 | Advanced patterns implemented |

**Total: 100 points**

## Bonus Challenges (+25 points)

1. **Dask Integration** (+10 points): Use Dask for larger-than-memory datasets
2. **Data Validation** (+10 points): Implement Great Expectations integration
3. **Monitoring** (+5 points): Add pipeline monitoring and alerting
