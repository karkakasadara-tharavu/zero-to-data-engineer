# Database Connectivity with Python - Complete Guide

## 📚 What You'll Learn
- Python database drivers and libraries
- Connection management
- Connection pooling
- Secure credential handling
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Database Connectivity Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PYTHON DATABASE CONNECTIVITY                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────┐                                               │
│   │   Python Application │                                               │
│   └──────────┬──────────┘                                               │
│              │                                                           │
│              ▼                                                           │
│   ┌─────────────────────┐                                               │
│   │     DB-API 2.0      │  ← Standard Python Database Interface         │
│   │   (PEP 249)         │                                               │
│   └──────────┬──────────┘                                               │
│              │                                                           │
│   ┌──────────┴──────────────────────────────────────┐                   │
│   │                                                  │                   │
│   ▼                  ▼                  ▼           ▼                   │
│ ┌────────┐    ┌──────────┐    ┌─────────┐    ┌──────────┐              │
│ │ pyodbc │    │ psycopg2 │    │ pymysql │    │ sqlite3  │              │
│ │(ODBC)  │    │(Postgres)│    │ (MySQL) │    │ (SQLite) │              │
│ └────┬───┘    └────┬─────┘    └────┬────┘    └────┬─────┘              │
│      │             │               │              │                     │
│      ▼             ▼               ▼              ▼                     │
│ ┌────────┐    ┌──────────┐    ┌─────────┐    ┌──────────┐              │
│ │SQL     │    │PostgreSQL│    │  MySQL  │    │  SQLite  │              │
│ │Server  │    │          │    │         │    │          │              │
│ └────────┘    └──────────┘    └─────────┘    └──────────┘              │
│                                                                          │
│   ┌─────────────────────────────────────────────────────┐               │
│   │              SQLAlchemy (ORM + Core)                │               │
│   │     Unified interface for all databases              │               │
│   └─────────────────────────────────────────────────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 pyodbc - ODBC Driver

### Installation

```bash
pip install pyodbc
```

### SQL Server Connection

```python
import pyodbc

# Connection string
conn_str = (
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=servername;'
    'DATABASE=dbname;'
    'UID=username;'
    'PWD=password;'
)

# Connect
conn = pyodbc.connect(conn_str)

# Create cursor
cursor = conn.cursor()

# Execute query
cursor.execute("SELECT * FROM Customers WHERE City = ?", ('New York',))

# Fetch results
rows = cursor.fetchall()
for row in rows:
    print(row.CustomerID, row.CustomerName)

# Close connection
cursor.close()
conn.close()
```

### Windows Authentication

```python
conn_str = (
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=servername;'
    'DATABASE=dbname;'
    'Trusted_Connection=yes;'
)
conn = pyodbc.connect(conn_str)
```

### Connection with Context Manager

```python
# Best practice - automatically closes connection
with pyodbc.connect(conn_str) as conn:
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM Products")
        for row in cursor.fetchall():
            print(row)
# Connection automatically closed
```

---

## 🐘 psycopg2 - PostgreSQL

### Installation

```bash
pip install psycopg2-binary
```

### Basic Connection

```python
import psycopg2

# Connect
conn = psycopg2.connect(
    host="localhost",
    database="mydb",
    user="username",
    password="password",
    port=5432
)

# Create cursor
cursor = conn.cursor()

# Execute query
cursor.execute("SELECT * FROM users WHERE active = %s", (True,))

# Fetch
users = cursor.fetchall()

# Clean up
cursor.close()
conn.close()
```

### Named Cursor for Large Results

```python
# Server-side cursor for large datasets
with psycopg2.connect(conn_string) as conn:
    with conn.cursor(name='large_cursor') as cursor:
        cursor.itersize = 10000  # Fetch in batches
        cursor.execute("SELECT * FROM large_table")
        for row in cursor:
            process(row)
```

---

## 🐬 pymysql - MySQL

### Installation

```bash
pip install pymysql
```

### Basic Connection

```python
import pymysql

# Connect
conn = pymysql.connect(
    host='localhost',
    user='username',
    password='password',
    database='dbname',
    charset='utf8mb4',
    cursorclass=pymysql.cursors.DictCursor  # Return rows as dicts
)

try:
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM users WHERE id = %s", (1,))
        result = cursor.fetchone()
        print(result)  # {'id': 1, 'name': 'John', ...}
finally:
    conn.close()
```

---

## 🗃️ sqlite3 - SQLite (Built-in)

```python
import sqlite3

# Connect (creates file if not exists)
conn = sqlite3.connect('database.db')

# Or in-memory database
conn = sqlite3.connect(':memory:')

# Enable dict-like rows
conn.row_factory = sqlite3.Row

cursor = conn.cursor()

# Create table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE
    )
''')

# Insert
cursor.execute("INSERT INTO users (name, email) VALUES (?, ?)", 
               ('John', 'john@example.com'))
conn.commit()

# Query
cursor.execute("SELECT * FROM users")
for row in cursor:
    print(dict(row))

conn.close()
```

---

## 🏗️ SQLAlchemy - Unified Database Access

### Installation

```bash
pip install sqlalchemy
```

### Creating Engine

```python
from sqlalchemy import create_engine

# SQL Server
engine = create_engine(
    'mssql+pyodbc://user:password@server/database'
    '?driver=ODBC+Driver+17+for+SQL+Server'
)

# PostgreSQL
engine = create_engine('postgresql://user:password@host:5432/database')

# MySQL
engine = create_engine('mysql+pymysql://user:password@host:3306/database')

# SQLite
engine = create_engine('sqlite:///database.db')

# With connection parameters
engine = create_engine(
    'postgresql://user:password@host/database',
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Check connection health
    echo=True  # Log SQL statements
)
```

### Raw SQL Execution

```python
from sqlalchemy import text

# Execute with connection
with engine.connect() as conn:
    # Simple query
    result = conn.execute(text("SELECT * FROM users"))
    for row in result:
        print(row)
    
    # Parameterized query
    result = conn.execute(
        text("SELECT * FROM users WHERE city = :city"),
        {"city": "New York"}
    )
    
    # Insert with commit
    conn.execute(
        text("INSERT INTO users (name) VALUES (:name)"),
        {"name": "John"}
    )
    conn.commit()
```

### Transaction Management

```python
from sqlalchemy import text

with engine.begin() as conn:  # Auto-commit on success, rollback on error
    conn.execute(text("INSERT INTO table1 VALUES (1, 'a')"))
    conn.execute(text("INSERT INTO table2 VALUES (2, 'b')"))
# Transaction committed automatically

# Manual transaction control
with engine.connect() as conn:
    trans = conn.begin()
    try:
        conn.execute(text("INSERT INTO table1 VALUES (1, 'a')"))
        conn.execute(text("INSERT INTO table2 VALUES (2, 'b')"))
        trans.commit()
    except:
        trans.rollback()
        raise
```

---

## 🔐 Secure Credential Management

### Environment Variables

```python
import os

# Set in environment or .env file
# DB_USER=myuser
# DB_PASSWORD=mypassword

user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')

conn_str = f'mssql+pyodbc://{user}:{password}@server/database'
```

### dotenv File

```python
# .env file (never commit to git!)
# DB_HOST=localhost
# DB_USER=admin
# DB_PASSWORD=secret123

from dotenv import load_dotenv
import os

load_dotenv()  # Load from .env file

host = os.getenv('DB_HOST')
user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')
```

### Config File

```python
import configparser

# config.ini
# [database]
# host = localhost
# user = admin
# password = secret

config = configparser.ConfigParser()
config.read('config.ini')

host = config['database']['host']
user = config['database']['user']
password = config['database']['password']
```

### Azure Key Vault

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Connect to Key Vault
vault_url = "https://myvault.vault.azure.net"
credential = DefaultAzureCredential()
client = SecretClient(vault_url=vault_url, credential=credential)

# Retrieve secrets
db_password = client.get_secret("db-password").value
```

---

## 🔄 Connection Pooling

### SQLAlchemy Pool

```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    'postgresql://user:pass@host/db',
    poolclass=QueuePool,
    pool_size=10,        # Permanent connections
    max_overflow=20,     # Additional connections when needed
    pool_timeout=30,     # Seconds to wait for connection
    pool_recycle=1800,   # Recycle connections after 30 min
    pool_pre_ping=True   # Verify connection before use
)

# Connection is automatically returned to pool
with engine.connect() as conn:
    result = conn.execute(text("SELECT 1"))
```

### Connection Pool Monitoring

```python
# Check pool status
print(f"Pool size: {engine.pool.size()}")
print(f"Connections in use: {engine.pool.checkedin()}")
print(f"Connections checked out: {engine.pool.checkedout()}")
```

---

## ⚠️ Error Handling

```python
import pyodbc
from sqlalchemy.exc import SQLAlchemyError

# pyodbc error handling
try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM nonexistent_table")
except pyodbc.Error as e:
    print(f"Database error: {e}")
except pyodbc.OperationalError as e:
    print(f"Connection error: {e}")
finally:
    if 'conn' in locals():
        conn.close()

# SQLAlchemy error handling
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError, OperationalError, IntegrityError

try:
    with engine.connect() as conn:
        conn.execute(text("INSERT INTO users VALUES (1, 'John')"))
        conn.commit()
except IntegrityError as e:
    print(f"Duplicate key or constraint violation: {e}")
except OperationalError as e:
    print(f"Connection failed: {e}")
except SQLAlchemyError as e:
    print(f"Database error: {e}")
```

---

## 📊 Best Practices

### 1. Always Use Parameterized Queries

```python
# ❌ NEVER do this - SQL Injection vulnerable!
cursor.execute(f"SELECT * FROM users WHERE name = '{user_input}'")

# ✅ Use parameterized queries
cursor.execute("SELECT * FROM users WHERE name = ?", (user_input,))
```

### 2. Use Context Managers

```python
# ✅ Auto-closes connection
with pyodbc.connect(conn_str) as conn:
    with conn.cursor() as cursor:
        cursor.execute("SELECT 1")
```

### 3. Handle Transactions Properly

```python
# ✅ Explicit commit/rollback
with engine.begin() as conn:  # Auto-rollback on error
    conn.execute(text("INSERT INTO table1 VALUES (1)"))
    conn.execute(text("INSERT INTO table2 VALUES (2)"))
```

### 4. Close Resources

```python
# ✅ Always close cursors and connections
cursor.close()
conn.close()
```

---

## 🎓 Interview Questions

### Q1: What is DB-API 2.0 (PEP 249)?
**A:** Python Database API Specification that defines a standard interface for database drivers. It specifies connection objects, cursor objects, and standard methods like `execute()`, `fetchone()`, `fetchall()`.

### Q2: What is the difference between pyodbc and SQLAlchemy?
**A:**
- **pyodbc**: Low-level ODBC driver, direct SQL execution
- **SQLAlchemy**: High-level ORM and Core API, database-agnostic, includes connection pooling and ORM capabilities

### Q3: How do you prevent SQL injection in Python?
**A:** Always use parameterized queries:
```python
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
```

### Q4: What is connection pooling and why is it important?
**A:** Connection pooling reuses database connections instead of creating new ones. It improves performance by reducing connection overhead and manages resource limits.

### Q5: How do you handle database transactions in Python?
**A:**
```python
with engine.begin() as conn:  # Auto-commit or rollback
    conn.execute(text("INSERT..."))
```

### Q6: What is the difference between fetchone(), fetchall(), and fetchmany()?
**A:**
- **fetchone()**: Returns single row
- **fetchall()**: Returns all remaining rows
- **fetchmany(n)**: Returns n rows

### Q7: How do you securely store database credentials?
**A:** Use environment variables, .env files (not in git), config files with restricted permissions, or secrets managers like Azure Key Vault.

### Q8: What is SQLAlchemy's pool_pre_ping?
**A:** Tests database connection before using it, handles dropped connections gracefully.

### Q9: How do you handle large result sets?
**A:** Use server-side cursors or fetch in batches:
```python
cursor.itersize = 10000
for row in cursor:
    process(row)
```

### Q10: What is the difference between connect() and begin() in SQLAlchemy?
**A:**
- **connect()**: Opens connection, requires explicit commit
- **begin()**: Opens connection with transaction, auto-commits on success, rolls back on error

---

## 🔗 Related Topics
- [← Pandas File I/O](../Module_12_Pandas/05_file_io.md)
- [Executing SQL Queries →](./02_executing_queries.md)
- [Pandas-SQL Integration →](./03_pandas_sql.md)

---

*Continue to Executing SQL Queries*
