# Section 09: Pandas and SQL Integration

## Introduction

Pandas provides powerful tools for integrating with SQL databases, allowing you to easily load data from databases into DataFrames and write DataFrames back to databases.

## Reading from Databases

### Basic read_sql

```python
import pandas as pd
from sqlalchemy import create_engine

# Create engine
engine = create_engine('postgresql://user:pass@localhost/mydb')

# Read entire table
df = pd.read_sql_table('users', engine)
print(df.head())

# Read with SQL query
query = "SELECT * FROM users WHERE age > 25"
df = pd.read_sql_query(query, engine)

# read_sql works with both tables and queries
df = pd.read_sql('users', engine)  # Table
df = pd.read_sql("SELECT * FROM users", engine)  # Query
```

### Using SQLAlchemy Expressions

```python
from sqlalchemy import select, MetaData, Table

# Reflect table
metadata = MetaData()
users = Table('users', metadata, autoload_with=engine)

# Build query
stmt = select(users).where(users.c.age > 25)

# Execute with pandas
df = pd.read_sql(stmt, engine)
```

### Chunked Reading

```python
# Read large table in chunks
chunk_size = 10000

for chunk in pd.read_sql_query(
    "SELECT * FROM large_table",
    engine,
    chunksize=chunk_size
):
    # Process each chunk
    print(f"Processing {len(chunk)} rows")
    process_chunk(chunk)

# Or collect all chunks
chunks = []
for chunk in pd.read_sql_query(query, engine, chunksize=5000):
    chunks.append(chunk)

df = pd.concat(chunks, ignore_index=True)
```

### Reading with Parameters

```python
# Parameterized query (prevents SQL injection)
query = "SELECT * FROM users WHERE city = %(city)s AND age > %(age)s"
params = {'city': 'New York', 'age': 25}

df = pd.read_sql_query(query, engine, params=params)

# With SQLAlchemy
from sqlalchemy import text

query = text("SELECT * FROM users WHERE city = :city AND age > :age")
df = pd.read_sql_query(query, engine, params={'city': 'New York', 'age': 25})
```

### Setting Index Column

```python
# Use specific column as index
df = pd.read_sql_query(
    "SELECT * FROM users",
    engine,
    index_col='id'
)

# Multiple index columns
df = pd.read_sql_query(
    "SELECT * FROM sales",
    engine,
    index_col=['year', 'month']
)
```

### Parsing Dates

```python
# Parse date columns
df = pd.read_sql_query(
    "SELECT * FROM orders",
    engine,
    parse_dates=['order_date', 'delivery_date']
)

# Custom date format
df = pd.read_sql_query(
    "SELECT * FROM logs",
    engine,
    parse_dates={'timestamp': '%Y-%m-%d %H:%M:%S'}
)
```

## Writing to Databases

### Basic to_sql

```python
import pandas as pd

# Create sample DataFrame
df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Carol'],
    'age': [25, 30, 35],
    'city': ['New York', 'San Francisco', 'Chicago']
})

# Write to database
df.to_sql('users', engine, if_exists='replace', index=False)

# if_exists options:
# - 'fail': Raise error if table exists (default)
# - 'replace': Drop and recreate table
# - 'append': Add rows to existing table
```

### Append to Existing Table

```python
# Add more rows
new_df = pd.DataFrame({
    'name': ['Dave', 'Eve'],
    'age': [40, 28],
    'city': ['Boston', 'Seattle']
})

new_df.to_sql('users', engine, if_exists='append', index=False)
```

### Specifying Data Types

```python
from sqlalchemy import Integer, String, Float

# Define column types
dtype = {
    'id': Integer(),
    'name': String(50),
    'age': Integer(),
    'salary': Float()
}

df.to_sql('employees', engine, dtype=dtype, if_exists='replace', index=False)
```

### Chunked Writing

```python
# Write large DataFrame in chunks
large_df = pd.DataFrame({
    'id': range(100000),
    'value': range(100000)
})

large_df.to_sql(
    'large_table',
    engine,
    if_exists='replace',
    index=False,
    chunksize=10000  # Write 10,000 rows at a time
)
```

### Using method Parameter

```python
# Custom insert method for better performance
def psql_insert_copy(table, conn, keys, data_iter):
    """Use PostgreSQL COPY for fast bulk insert"""
    from io import StringIO
    
    # Create CSV buffer
    s_buf = StringIO()
    df_temp = pd.DataFrame(data_iter, columns=keys)
    df_temp.to_csv(s_buf, index=False, header=False)
    s_buf.seek(0)
    
    # Execute COPY
    raw_conn = conn.connection
    with raw_conn.cursor() as cur:
        cur.copy_expert(
            f"COPY {table.name} ({','.join(keys)}) FROM STDIN WITH CSV",
            s_buf
        )

# Use custom method
df.to_sql(
    'fast_table',
    engine,
    if_exists='append',
    index=False,
    method=psql_insert_copy
)
```

## Data Type Mapping

### Pandas to SQL Types

```python
import pandas as pd
import numpy as np

# Common type mappings
df = pd.DataFrame({
    'int_col': [1, 2, 3],                    # INTEGER
    'float_col': [1.5, 2.5, 3.5],           # FLOAT
    'str_col': ['a', 'b', 'c'],             # VARCHAR/TEXT
    'bool_col': [True, False, True],         # BOOLEAN
    'date_col': pd.date_range('2024-01-01', periods=3),  # DATE/TIMESTAMP
    'datetime_col': pd.to_datetime(['2024-01-01', '2024-01-02', '2024-01-03'])
})

# Explicit type specification
from sqlalchemy import Integer, String, Float, Boolean, Date, DateTime

dtype = {
    'int_col': Integer(),
    'float_col': Float(),
    'str_col': String(10),
    'bool_col': Boolean(),
    'date_col': Date(),
    'datetime_col': DateTime()
}

df.to_sql('typed_table', engine, dtype=dtype, if_exists='replace', index=False)
```

### Handling NULL Values

```python
# NaN becomes NULL in database
df = pd.DataFrame({
    'value': [1, np.nan, 3],
    'name': ['Alice', None, 'Bob']
})

df.to_sql('null_table', engine, if_exists='replace', index=False)

# Read NULL as NaN
df_read = pd.read_sql_table('null_table', engine)
print(df_read['value'].isna())  # Shows True for NULL
```

## Complex Queries with Pandas

### Joins in SQL vs Pandas

```python
# SQL join
query = """
SELECT u.name, o.order_id, o.amount
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE u.city = 'New York'
"""
df_joined = pd.read_sql_query(query, engine)

# Or join in pandas
users = pd.read_sql_table('users', engine)
orders = pd.read_sql_table('orders', engine)

df_joined = users[users['city'] == 'New York'].merge(
    orders,
    left_on='id',
    right_on='user_id',
    how='inner'
)
```

### Aggregations

```python
# SQL aggregation
query = """
SELECT city, COUNT(*) as user_count, AVG(age) as avg_age
FROM users
GROUP BY city
HAVING COUNT(*) > 10
"""
df_agg = pd.read_sql_query(query, engine)

# Pandas aggregation after loading
users = pd.read_sql_table('users', engine)
df_agg = users.groupby('city').agg({
    'id': 'count',
    'age': 'mean'
}).rename(columns={'id': 'user_count', 'age': 'avg_age'})
df_agg = df_agg[df_agg['user_count'] > 10]
```

### Window Functions

```python
# SQL window function
query = """
SELECT
    name,
    department,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank
FROM employees
"""
df = pd.read_sql_query(query, engine)

# Pandas equivalent
employees = pd.read_sql_table('employees', engine)
employees['rank'] = employees.groupby('department')['salary'].rank(
    method='min',
    ascending=False
)
```

## Performance Optimization

### Selective Column Loading

```python
# Load only needed columns
query = "SELECT id, name, email FROM users"  # Not SELECT *
df = pd.read_sql_query(query, engine)
```

### Filtering in SQL

```python
# Bad: Load all then filter in pandas
df = pd.read_sql_table('large_table', engine)
df_filtered = df[df['value'] > 1000]

# Good: Filter in SQL
query = "SELECT * FROM large_table WHERE value > 1000"
df_filtered = pd.read_sql_query(query, engine)
```

### Using Indexes

```python
# Ensure database indexes exist for filtered columns
query = """
SELECT * FROM users
WHERE city = 'New York' AND age > 25  -- Needs index on (city, age)
"""
df = pd.read_sql_query(query, engine)
```

### Batch Processing

```python
def process_large_table(engine, table_name, batch_size=10000):
    """Process large table in batches"""
    offset = 0
    results = []
    
    while True:
        query = f"""
        SELECT * FROM {table_name}
        ORDER BY id
        LIMIT {batch_size} OFFSET {offset}
        """
        
        chunk = pd.read_sql_query(query, engine)
        
        if chunk.empty:
            break
        
        # Process chunk
        processed = process_data(chunk)
        results.append(processed)
        
        offset += batch_size
    
    return pd.concat(results, ignore_index=True)
```

## Complete Example: ETL Pipeline

```python
import pandas as pd
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime
from sqlalchemy.orm import declarative_base
from datetime import datetime

# Source and destination databases
source_engine = create_engine('postgresql://user:pass@source/db')
dest_engine = create_engine('postgresql://user:pass@dest/db')

# Define destination schema
Base = declarative_base()

class ProcessedSale(Base):
    __tablename__ = 'processed_sales'
    
    id = Column(Integer, primary_key=True)
    product = Column(String(100))
    category = Column(String(50))
    total_amount = Column(Float)
    sale_count = Column(Integer)
    avg_price = Column(Float)
    last_updated = Column(DateTime)

# Create destination table
Base.metadata.create_all(dest_engine)

# Extract
print("Extracting data...")
query = """
SELECT
    product_id,
    product_name,
    category,
    price,
    quantity,
    sale_date
FROM raw_sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days'
"""
df = pd.read_sql_query(query, source_engine)

# Transform
print("Transforming data...")
df['amount'] = df['price'] * df['quantity']

df_processed = df.groupby(['product_name', 'category']).agg({
    'amount': 'sum',
    'product_id': 'count',
    'price': 'mean'
}).reset_index()

df_processed.columns = ['product', 'category', 'total_amount', 'sale_count', 'avg_price']
df_processed['last_updated'] = datetime.now()

# Load
print("Loading data...")
df_processed.to_sql(
    'processed_sales',
    dest_engine,
    if_exists='replace',
    index=False,
    chunksize=1000
)

print(f"Processed {len(df_processed)} product summaries")

# Verify
verify = pd.read_sql_query(
    "SELECT COUNT(*) as count FROM processed_sales",
    dest_engine
)
print(f"Verified: {verify['count'][0]} rows in destination")
```

## Integration with SQLAlchemy ORM

```python
from sqlalchemy.orm import Session

# Query ORM models, convert to DataFrame
with Session(engine) as session:
    users = session.query(User).all()
    
    # Convert to DataFrame
    df = pd.DataFrame([{
        'id': u.id,
        'username': u.username,
        'email': u.email,
        'created_at': u.created_at
    } for u in users])

# Process in pandas
df['email_domain'] = df['email'].str.split('@').str[1]

# Update database from DataFrame
for _, row in df.iterrows():
    with Session(engine) as session:
        user = session.get(User, row['id'])
        if user:
            user.email_domain = row['email_domain']
        session.commit()
```

## Summary

Pandas-SQL integration provides:
- **read_sql**: Load database data into DataFrames
- **to_sql**: Write DataFrames to database
- **Chunking**: Handle large datasets efficiently
- **Type mapping**: Automatic and explicit type conversion
- **Performance**: Optimize with SQL filtering and indexing
- **ETL**: Build data pipelines combining SQL and pandas

**Next**: Section 10 - Best Practices and Patterns
