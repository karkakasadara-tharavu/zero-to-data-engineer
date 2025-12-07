# Section 02: SQLAlchemy Core

## Introduction

SQLAlchemy Core provides a SQL Expression Language that allows you to construct SQL queries using Python objects. It offers a middle ground between raw SQL and ORM, giving you both control and convenience.

## Engine and Connection Pools

### Creating an Engine

```python
from sqlalchemy import create_engine

# SQLite
engine = create_engine('sqlite:///myapp.db', echo=True)

# PostgreSQL
engine = create_engine('postgresql://user:password@localhost:5432/mydb')

# MySQL
engine = create_engine('mysql+pymysql://user:password@localhost:3306/mydb')

# With options
engine = create_engine(
    'postgresql://user:password@localhost/mydb',
    pool_size=10,          # Connection pool size
    max_overflow=20,       # Extra connections when pool exhausted
    pool_timeout=30,       # Timeout for getting connection
    pool_recycle=3600,     # Recycle connections after 1 hour
    echo=False             # Don't log SQL statements
)
```

### Connection Pool Configuration

```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    'postgresql://user:password@localhost/mydb',
    poolclass=QueuePool,
    pool_size=5,
    max_overflow=10
)

# Check pool status
print(f"Pool size: {engine.pool.size()}")
print(f"Checked out: {engine.pool.checkedout()}")
```

### Using Connections

```python
# Method 1: Context manager (recommended)
with engine.connect() as conn:
    result = conn.execute(text("SELECT * FROM users"))
    for row in result:
        print(row)

# Method 2: Explicit connection
conn = engine.connect()
result = conn.execute(text("SELECT * FROM users"))
conn.close()

# Method 3: Connection from pool
conn = engine.raw_connection()
conn.close()
```

## Metadata and Schema Definition

### Defining Tables

```python
from sqlalchemy import MetaData, Table, Column, Integer, String, Float, DateTime, ForeignKey
from datetime import datetime

metadata = MetaData()

# Users table
users_table = Table(
    'users',
    metadata,
    Column('id', Integer, primary_key=True, autoincrement=True),
    Column('username', String(50), unique=True, nullable=False),
    Column('email', String(100), unique=True, nullable=False),
    Column('created_at', DateTime, default=datetime.utcnow)
)

# Products table
products_table = Table(
    'products',
    metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String(200), nullable=False),
    Column('price', Float, nullable=False),
    Column('stock', Integer, default=0)
)

# Orders table with foreign key
orders_table = Table(
    'orders',
    metadata,
    Column('id', Integer, primary_key=True),
    Column('user_id', Integer, ForeignKey('users.id'), nullable=False),
    Column('product_id', Integer, ForeignKey('products.id'), nullable=False),
    Column('quantity', Integer, nullable=False),
    Column('order_date', DateTime, default=datetime.utcnow)
)

# Create all tables
metadata.create_all(engine)
```

### Column Types

```python
from sqlalchemy import Boolean, Date, Text, JSON, DECIMAL

# Common column types
columns_example = Table(
    'example',
    metadata,
    Column('int_col', Integer),
    Column('bigint_col', BigInteger),
    Column('string_col', String(100)),
    Column('text_col', Text),
    Column('float_col', Float),
    Column('decimal_col', DECIMAL(10, 2)),
    Column('bool_col', Boolean),
    Column('date_col', Date),
    Column('datetime_col', DateTime),
    Column('json_col', JSON)  # PostgreSQL/MySQL 5.7+
)
```

### Constraints

```python
from sqlalchemy import CheckConstraint, Index, UniqueConstraint

products_table = Table(
    'products',
    metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String(200), nullable=False),
    Column('price', Float, nullable=False),
    Column('stock', Integer, default=0),
    
    # Check constraint
    CheckConstraint('price > 0', name='positive_price'),
    CheckConstraint('stock >= 0', name='non_negative_stock'),
    
    # Unique constraint on multiple columns
    UniqueConstraint('name', 'price', name='unique_name_price')
)

# Create index
Index('idx_product_name', products_table.c.name)
```

## SQL Expression Language

### INSERT Operations

```python
from sqlalchemy import insert

# Single insert
stmt = insert(users_table).values(
    username='john_doe',
    email='john@example.com'
)

with engine.connect() as conn:
    result = conn.execute(stmt)
    conn.commit()
    print(f"Inserted user with ID: {result.inserted_primary_key}")

# Insert multiple rows
stmt = insert(products_table)
with engine.connect() as conn:
    conn.execute(stmt, [
        {'name': 'Laptop', 'price': 999.99, 'stock': 10},
        {'name': 'Mouse', 'price': 29.99, 'stock': 50},
        {'name': 'Keyboard', 'price': 79.99, 'stock': 30}
    ])
    conn.commit()

# Insert from select
stmt = insert(users_table).from_select(
    ['username', 'email'],
    select(temp_users_table.c.username, temp_users_table.c.email)
)
```

### SELECT Operations

```python
from sqlalchemy import select, and_, or_, not_

# Simple select
stmt = select(users_table)
with engine.connect() as conn:
    result = conn.execute(stmt)
    for row in result:
        print(dict(row))

# Select specific columns
stmt = select(users_table.c.username, users_table.c.email)

# WHERE clause
stmt = select(users_table).where(users_table.c.username == 'john_doe')

# Multiple conditions with AND
stmt = select(products_table).where(
    and_(
        products_table.c.price > 50,
        products_table.c.stock > 0
    )
)

# OR conditions
stmt = select(products_table).where(
    or_(
        products_table.c.name == 'Laptop',
        products_table.c.price < 100
    )
)

# IN operator
stmt = select(users_table).where(
    users_table.c.username.in_(['john', 'jane', 'bob'])
)

# LIKE operator
stmt = select(products_table).where(
    products_table.c.name.like('%top%')
)

# BETWEEN
stmt = select(products_table).where(
    products_table.c.price.between(50, 200)
)

# IS NULL
stmt = select(users_table).where(users_table.c.email.is_(None))

# ORDER BY
stmt = select(products_table).order_by(products_table.c.price.desc())

# LIMIT and OFFSET
stmt = select(products_table).limit(10).offset(20)
```

### UPDATE Operations

```python
from sqlalchemy import update

# Simple update
stmt = update(products_table).where(
    products_table.c.name == 'Laptop'
).values(price=899.99)

with engine.connect() as conn:
    result = conn.execute(stmt)
    conn.commit()
    print(f"Updated {result.rowcount} rows")

# Update with expressions
stmt = update(products_table).where(
    products_table.c.stock < 10
).values(stock=products_table.c.stock + 50)

# Conditional update
from sqlalchemy import case

stmt = update(products_table).values(
    stock=case(
        (products_table.c.stock < 10, products_table.c.stock + 100),
        else_=products_table.c.stock
    )
)
```

### DELETE Operations

```python
from sqlalchemy import delete

# Simple delete
stmt = delete(users_table).where(users_table.c.username == 'old_user')

with engine.connect() as conn:
    result = conn.execute(stmt)
    conn.commit()
    print(f"Deleted {result.rowcount} rows")

# Delete with multiple conditions
stmt = delete(products_table).where(
    and_(
        products_table.c.stock == 0,
        products_table.c.price > 1000
    )
)
```

## Joins and Subqueries

### Inner Join

```python
# Simple join
stmt = select(
    users_table.c.username,
    orders_table.c.order_date,
    products_table.c.name
).select_from(
    users_table.join(orders_table).join(products_table)
)

# Explicit join conditions
stmt = select(users_table, orders_table).select_from(
    users_table.join(
        orders_table,
        users_table.c.id == orders_table.c.user_id
    )
)
```

### Left Outer Join

```python
stmt = select(users_table, orders_table).select_from(
    users_table.outerjoin(orders_table)
)
```

### Subqueries

```python
# Scalar subquery
subq = select(func.max(products_table.c.price)).scalar_subquery()
stmt = select(products_table).where(products_table.c.price == subq)

# Subquery in FROM
subq = select(
    products_table.c.name,
    products_table.c.price
).where(products_table.c.stock > 0).subquery()

stmt = select(subq.c.name, subq.c.price).where(subq.c.price > 100)
```

## Aggregate Functions

```python
from sqlalchemy import func

# COUNT
stmt = select(func.count()).select_from(users_table)

# COUNT DISTINCT
stmt = select(func.count(users_table.c.email.distinct()))

# SUM, AVG, MIN, MAX
stmt = select(
    func.sum(products_table.c.stock),
    func.avg(products_table.c.price),
    func.min(products_table.c.price),
    func.max(products_table.c.price)
)

# GROUP BY
stmt = select(
    users_table.c.username,
    func.count(orders_table.c.id).label('order_count')
).select_from(
    users_table.join(orders_table)
).group_by(users_table.c.username)

# HAVING
stmt = select(
    products_table.c.name,
    func.sum(orders_table.c.quantity).label('total_sold')
).select_from(
    products_table.join(orders_table)
).group_by(products_table.c.name).having(
    func.sum(orders_table.c.quantity) > 100
)
```

## Transaction Management

```python
# Automatic commit/rollback
with engine.begin() as conn:
    conn.execute(insert(users_table).values(username='alice', email='alice@example.com'))
    conn.execute(insert(products_table).values(name='Product', price=99.99))
    # Automatically committed if no exception

# Manual transaction control
conn = engine.connect()
trans = conn.begin()
try:
    conn.execute(insert(users_table).values(username='bob', email='bob@example.com'))
    conn.execute(insert(products_table).values(name='Item', price=49.99))
    trans.commit()
except Exception as e:
    trans.rollback()
    raise
finally:
    conn.close()

# Nested transactions (savepoints)
with engine.begin() as conn:
    conn.execute(insert(users_table).values(username='carol', email='carol@example.com'))
    
    savepoint = conn.begin_nested()
    try:
        conn.execute(insert(products_table).values(name='Test', price=-10))  # Will fail
        savepoint.commit()
    except:
        savepoint.rollback()
    
    # Main transaction continues
```

## Complete Example

```python
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Float, select, insert
from datetime import datetime

# Setup
engine = create_engine('sqlite:///shop.db', echo=True)
metadata = MetaData()

# Define schema
products = Table(
    'products',
    metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String(100), nullable=False),
    Column('price', Float, nullable=False),
    Column('stock', Integer, default=0)
)

metadata.create_all(engine)

# Insert data
with engine.begin() as conn:
    # Insert products
    conn.execute(insert(products), [
        {'name': 'Laptop', 'price': 999.99, 'stock': 5},
        {'name': 'Mouse', 'price': 29.99, 'stock': 50},
        {'name': 'Keyboard', 'price': 79.99, 'stock': 30},
        {'name': 'Monitor', 'price': 299.99, 'stock': 15}
    ])

# Query data
with engine.connect() as conn:
    # All products
    result = conn.execute(select(products))
    print("\nAll products:")
    for row in result:
        print(f"  {row.name}: ${row.price}")
    
    # Expensive products
    stmt = select(products).where(products.c.price > 100)
    result = conn.execute(stmt)
    print("\nExpensive products:")
    for row in result:
        print(f"  {row.name}: ${row.price}")
    
    # Statistics
    stmt = select(
        func.count(products.c.id).label('count'),
        func.avg(products.c.price).label('avg_price'),
        func.sum(products.c.stock).label('total_stock')
    )
    result = conn.execute(stmt).first()
    print(f"\nStatistics:")
    print(f"  Total products: {result.count}")
    print(f"  Average price: ${result.avg_price:.2f}")
    print(f"  Total stock: {result.total_stock}")
```

## Summary

SQLAlchemy Core provides:
- Type-safe query construction
- Database-agnostic SQL generation
- Connection pooling
- Transaction management
- Metadata reflection
- Schema definition

**Next**: Section 03 - SQLAlchemy ORM Fundamentals
