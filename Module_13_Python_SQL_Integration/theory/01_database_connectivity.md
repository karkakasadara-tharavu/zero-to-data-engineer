# Section 01: Database Connectivity Basics

## Introduction

Database connectivity is the foundation of integrating Python with SQL databases. This section covers the DB-API 2.0 specification, connection management strategies, and how to connect to various database systems including SQLite, PostgreSQL, and MySQL.

## DB-API 2.0 Specification

The Python Database API Specification v2.0 (PEP 249) provides a standard interface for database access, ensuring consistency across different database drivers.

### Key Components

#### 1. Connection Objects
```python
import sqlite3

# Create connection
conn = sqlite3.connect('example.db')

# Connection methods
conn.cursor()      # Get cursor object
conn.commit()      # Commit transaction
conn.rollback()    # Rollback transaction
conn.close()       # Close connection
```

#### 2. Cursor Objects
```python
# Get cursor from connection
cursor = conn.cursor()

# Cursor methods
cursor.execute(sql)           # Execute single statement
cursor.executemany(sql, data) # Execute with multiple parameter sets
cursor.fetchone()             # Fetch single row
cursor.fetchall()             # Fetch all rows
cursor.fetchmany(size)        # Fetch specified number of rows
cursor.close()                # Close cursor
```

#### 3. Exception Hierarchy
```python
# DB-API 2.0 exception hierarchy
try:
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
except sqlite3.DatabaseError as e:
    print(f"Database error: {e}")
except sqlite3.IntegrityError as e:
    print(f"Integrity error: {e}")
except sqlite3.OperationalError as e:
    print(f"Operational error: {e}")
```

### DB-API 2.0 Compliance

```python
# Check driver compliance
import sqlite3

print(f"API Level: {sqlite3.apilevel}")         # Should be '2.0'
print(f"Thread Safety: {sqlite3.threadsafety}") # 0-3
print(f"Parameter Style: {sqlite3.paramstyle}") # qmark, numeric, named, format, pyformat
```

## SQLite: Getting Started

SQLite is a file-based database perfect for development, testing, and embedded applications.

### Basic Connection

```python
import sqlite3
from datetime import datetime

# Create/connect to database
conn = sqlite3.connect('myapp.db')

# Create cursor
cursor = conn.cursor()

# Create table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        created_at TEXT
    )
''')

# Insert data
cursor.execute('''
    INSERT INTO users (username, email, created_at)
    VALUES (?, ?, ?)
''', ('john_doe', 'john@example.com', datetime.now().isoformat()))

# Commit changes
conn.commit()

# Query data
cursor.execute('SELECT * FROM users')
users = cursor.fetchall()

for user in users:
    print(user)

# Clean up
cursor.close()
conn.close()
```

### In-Memory Database

```python
# In-memory database (fast, temporary)
conn = sqlite3.connect(':memory:')

# Useful for testing
def test_user_creation():
    conn = sqlite3.connect(':memory:')
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)
    ''')
    
    cursor.execute('INSERT INTO users (name) VALUES (?)', ('Alice',))
    conn.commit()
    
    cursor.execute('SELECT COUNT(*) FROM users')
    count = cursor.fetchone()[0]
    
    assert count == 1
    conn.close()
```

### Context Manager

```python
# Automatic connection management
import sqlite3

def create_user(username, email):
    with sqlite3.connect('myapp.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO users (username, email, created_at)
            VALUES (?, ?, ?)
        ''', (username, email, datetime.now().isoformat()))
        conn.commit()
        return cursor.lastrowid
    # Connection automatically closed

# Usage
user_id = create_user('jane_doe', 'jane@example.com')
print(f"Created user with ID: {user_id}")
```

### Row Factory

```python
# Return rows as dictionaries
conn = sqlite3.connect('myapp.db')
conn.row_factory = sqlite3.Row  # Enable dict-like access

cursor = conn.cursor()
cursor.execute('SELECT * FROM users WHERE id = ?', (1,))
user = cursor.fetchone()

# Access by column name
print(f"Username: {user['username']}")
print(f"Email: {user['email']}")

# Convert to dict
user_dict = dict(user)
print(user_dict)
```

## PostgreSQL Connection

PostgreSQL is an enterprise-grade database with advanced features.

### Using psycopg2

```python
import psycopg2
from psycopg2 import sql

# Connection parameters
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'myapp_db',
    'user': 'myapp_user',
    'password': 'secure_password'
}

# Connect to PostgreSQL
conn = psycopg2.connect(**DB_CONFIG)

# Create cursor
cursor = conn.cursor()

# Create table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(200) NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        quantity INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
''')

# Insert data
cursor.execute('''
    INSERT INTO products (name, price, quantity)
    VALUES (%s, %s, %s)
    RETURNING id
''', ('Laptop', 999.99, 10))

product_id = cursor.fetchone()[0]
print(f"Created product with ID: {product_id}")

# Commit and cleanup
conn.commit()
cursor.close()
conn.close()
```

### Connection String URL

```python
import psycopg2

# Connection using URL
DATABASE_URL = "postgresql://user:password@localhost:5432/myapp_db"
conn = psycopg2.connect(DATABASE_URL)
```

### Using Context Manager

```python
from contextlib import contextmanager

@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise
    finally:
        conn.close()

# Usage
with get_db_connection() as conn:
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM products')
    products = cursor.fetchall()
    for product in products:
        print(product)
```

### Named Cursors (Server-Side Cursors)

```python
# For large result sets
with get_db_connection() as conn:
    # Named cursor fetches rows from server in batches
    cursor = conn.cursor('large_dataset_cursor')
    cursor.execute('SELECT * FROM large_table')
    
    # Fetch in chunks
    while True:
        rows = cursor.fetchmany(1000)
        if not rows:
            break
        process_rows(rows)
```

## MySQL Connection

### Using PyMySQL

```python
import pymysql

# Connection configuration
MYSQL_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'password',
    'database': 'myapp_db',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor  # Return dicts
}

# Connect to MySQL
conn = pymysql.connect(**MYSQL_CONFIG)

try:
    with conn.cursor() as cursor:
        # Create table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS orders (
                id INT AUTO_INCREMENT PRIMARY KEY,
                customer_name VARCHAR(200) NOT NULL,
                order_total DECIMAL(10, 2),
                order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_customer (customer_name)
            )
        ''')
        
        # Insert data
        cursor.execute('''
            INSERT INTO orders (customer_name, order_total)
            VALUES (%s, %s)
        ''', ('John Smith', 149.99))
        
        # Get last insert ID
        order_id = cursor.lastrowid
        print(f"Created order: {order_id}")
    
    conn.commit()
finally:
    conn.close()
```

### Connection Pooling with PyMySQL

```python
from pymysql import connect
from queue import Queue

class ConnectionPool:
    """Simple connection pool"""
    
    def __init__(self, max_connections=5, **db_config):
        self.max_connections = max_connections
        self.db_config = db_config
        self.pool = Queue(maxsize=max_connections)
        
        # Initialize pool
        for _ in range(max_connections):
            self.pool.put(self._create_connection())
    
    def _create_connection(self):
        return connect(**self.db_config)
    
    def get_connection(self):
        return self.pool.get()
    
    def release_connection(self, conn):
        self.pool.put(conn)
    
    def close_all(self):
        while not self.pool.empty():
            conn = self.pool.get()
            conn.close()

# Usage
pool = ConnectionPool(max_connections=5, **MYSQL_CONFIG)

# Get connection from pool
conn = pool.get_connection()
try:
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM orders')
    orders = cursor.fetchall()
finally:
    pool.release_connection(conn)
```

## Connection Management Best Practices

### 1. Environment Variables

```python
import os
from dotenv import load_dotenv

# Load from .env file
load_dotenv()

DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 5432)),
    'database': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD')
}

# .env file
'''
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp_db
DB_USER=myapp_user
DB_PASSWORD=secure_password_here
'''
```

### 2. Connection Class

```python
class DatabaseConnection:
    """Reusable database connection manager"""
    
    def __init__(self, db_type='sqlite', **config):
        self.db_type = db_type
        self.config = config
        self.conn = None
    
    def connect(self):
        if self.db_type == 'sqlite':
            import sqlite3
            self.conn = sqlite3.connect(self.config.get('database', ':memory:'))
        elif self.db_type == 'postgresql':
            import psycopg2
            self.conn = psycopg2.connect(**self.config)
        elif self.db_type == 'mysql':
            import pymysql
            self.conn = pymysql.connect(**self.config)
        else:
            raise ValueError(f"Unsupported database type: {self.db_type}")
        
        return self.conn
    
    def close(self):
        if self.conn:
            self.conn.close()
            self.conn = None
    
    def __enter__(self):
        return self.connect()
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.conn.rollback()
        else:
            self.conn.commit()
        self.close()

# Usage
with DatabaseConnection(db_type='postgresql', **DATABASE_CONFIG) as conn:
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users')
    users = cursor.fetchall()
```

### 3. Singleton Pattern

```python
class DatabaseSingleton:
    """Ensure single database connection"""
    
    _instance = None
    _conn = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def connect(self, **config):
        if self._conn is None:
            import psycopg2
            self._conn = psycopg2.connect(**config)
        return self._conn
    
    def get_connection(self):
        if self._conn is None:
            raise RuntimeError("Not connected. Call connect() first.")
        return self._conn
    
    def close(self):
        if self._conn:
            self._conn.close()
            self._conn = None

# Usage
db = DatabaseSingleton()
db.connect(**DATABASE_CONFIG)

# Anywhere in application
conn = db.get_connection()
```

## Error Handling

### Comprehensive Error Handling

```python
import psycopg2
from psycopg2 import errorcodes

def safe_database_operation(query, params=None):
    """Execute query with comprehensive error handling"""
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG)
        cursor = conn.cursor()
        
        cursor.execute(query, params)
        
        # If SELECT
        if query.strip().upper().startswith('SELECT'):
            result = cursor.fetchall()
        else:
            conn.commit()
            result = cursor.rowcount
        
        return result
        
    except psycopg2.OperationalError as e:
        print(f"Connection error: {e}")
        print("Check database server is running and credentials are correct")
        
    except psycopg2.IntegrityError as e:
        print(f"Data integrity error: {e}")
        if e.pgcode == errorcodes.UNIQUE_VIOLATION:
            print("Duplicate key violation")
        elif e.pgcode == errorcodes.FOREIGN_KEY_VIOLATION:
            print("Foreign key constraint violation")
            
    except psycopg2.DataError as e:
        print(f"Data error: {e}")
        print("Check data types and constraints")
        
    except psycopg2.ProgrammingError as e:
        print(f"Programming error: {e}")
        print("Check SQL syntax and object names")
        
    except Exception as e:
        print(f"Unexpected error: {e}")
        
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()
    
    return None
```

### Retry Logic

```python
import time
from functools import wraps

def retry_on_failure(max_retries=3, delay=1):
    """Decorator to retry database operations"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except psycopg2.OperationalError as e:
                    if attempt == max_retries - 1:
                        raise
                    print(f"Attempt {attempt + 1} failed: {e}")
                    print(f"Retrying in {delay} seconds...")
                    time.sleep(delay)
            return None
        return wrapper
    return decorator

@retry_on_failure(max_retries=3, delay=2)
def connect_to_database():
    return psycopg2.connect(**DATABASE_CONFIG)
```

## Connection Testing

```python
def test_database_connection(db_type='postgresql', **config):
    """Test database connectivity"""
    print(f"Testing {db_type} connection...")
    
    try:
        if db_type == 'postgresql':
            import psycopg2
            conn = psycopg2.connect(**config)
            cursor = conn.cursor()
            cursor.execute('SELECT version()')
            version = cursor.fetchone()[0]
            print(f"✓ Connected successfully!")
            print(f"  Database version: {version}")
            
        elif db_type == 'mysql':
            import pymysql
            conn = pymysql.connect(**config)
            cursor = conn.cursor()
            cursor.execute('SELECT VERSION()')
            version = cursor.fetchone()[0]
            print(f"✓ Connected successfully!")
            print(f"  MySQL version: {version}")
            
        elif db_type == 'sqlite':
            import sqlite3
            conn = sqlite3.connect(config.get('database', ':memory:'))
            cursor = conn.cursor()
            cursor.execute('SELECT sqlite_version()')
            version = cursor.fetchone()[0]
            print(f"✓ Connected successfully!")
            print(f"  SQLite version: {version}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"✗ Connection failed: {e}")
        return False

# Test connections
test_database_connection('sqlite', database='test.db')
test_database_connection('postgresql', **DATABASE_CONFIG)
```

## Summary

### Key Takeaways

1. **DB-API 2.0** provides standard interface across databases
2. **SQLite** is perfect for development and testing
3. **PostgreSQL** offers enterprise features
4. **MySQL** is widely used in web applications
5. **Connection management** is critical for reliability
6. **Context managers** ensure proper resource cleanup
7. **Error handling** improves application robustness
8. **Environment variables** protect sensitive credentials

### Next Steps

- Execute queries and fetch results (Section 02)
- Learn parameter binding for security (Section 03)
- Master transaction management (Section 04)

### Best Practices

✅ Always close connections  
✅ Use context managers  
✅ Handle exceptions properly  
✅ Store credentials securely  
✅ Test connections before use  
✅ Use connection pooling for production  
✅ Implement retry logic  
✅ Log connection errors

## Practice Exercises

1. Create SQLite database with 3 tables
2. Implement PostgreSQL connection with retry logic
3. Build MySQL connection pool
4. Create unified database interface supporting all three
5. Test error handling for various failure scenarios

---

**Next**: Section 02 - SQLAlchemy Core for powerful query building
