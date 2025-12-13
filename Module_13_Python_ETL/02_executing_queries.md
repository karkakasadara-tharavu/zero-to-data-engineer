# Executing SQL Queries with Python - Complete Guide

## 📚 What You'll Learn
- Query execution patterns
- CRUD operations
- Batch processing
- Stored procedures
- Interview preparation

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## 🎯 Query Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SQL QUERY EXECUTION FLOW                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. CONNECT                                                             │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ conn = pyodbc.connect(conn_str)                                   │  │
│   │ cursor = conn.cursor()                                            │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                              │                                           │
│                              ▼                                           │
│   2. EXECUTE                                                             │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ cursor.execute("SELECT * FROM table WHERE id = ?", (1,))          │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                              │                                           │
│                              ▼                                           │
│   3. FETCH                                                               │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ rows = cursor.fetchall()                                          │  │
│   │ for row in rows: print(row.column_name)                           │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                              │                                           │
│                              ▼                                           │
│   4. COMMIT (for INSERT/UPDATE/DELETE)                                   │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ conn.commit()                                                     │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                              │                                           │
│                              ▼                                           │
│   5. CLOSE                                                               │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ cursor.close()                                                    │  │
│   │ conn.close()                                                      │  │
│   └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 SELECT Queries

### Basic Query Execution

```python
import pyodbc

conn_str = (
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=AdventureWorks;'
    'Trusted_Connection=yes;'
)

with pyodbc.connect(conn_str) as conn:
    cursor = conn.cursor()
    
    # Simple SELECT
    cursor.execute("SELECT TOP 10 * FROM Sales.Customer")
    
    # Fetch all rows
    rows = cursor.fetchall()
    
    for row in rows:
        print(f"ID: {row.CustomerID}, Name: {row.CustomerName}")
```

### Fetch Methods

```python
cursor.execute("SELECT * FROM Products")

# Fetch one row
row = cursor.fetchone()
print(row)

# Fetch specific number of rows
rows = cursor.fetchmany(10)

# Fetch all remaining rows
all_rows = cursor.fetchall()

# Iterate directly (memory efficient)
cursor.execute("SELECT * FROM LargeTable")
for row in cursor:
    process(row)
```

### Accessing Column Values

```python
cursor.execute("SELECT ProductID, ProductName, Price FROM Products")

for row in cursor:
    # By index
    print(row[0], row[1], row[2])
    
    # By column name
    print(row.ProductID, row.ProductName, row.Price)
    
    # Get column descriptions
    columns = [desc[0] for desc in cursor.description]
    print(columns)  # ['ProductID', 'ProductName', 'Price']
```

### Parameterized Queries

```python
# Single parameter
cursor.execute(
    "SELECT * FROM Products WHERE CategoryID = ?",
    (5,)
)

# Multiple parameters
cursor.execute(
    "SELECT * FROM Orders WHERE CustomerID = ? AND OrderDate >= ?",
    (101, '2023-01-01')
)

# Named parameters with SQLAlchemy
from sqlalchemy import text, create_engine

engine = create_engine(connection_string)
with engine.connect() as conn:
    result = conn.execute(
        text("SELECT * FROM Products WHERE Price > :min_price AND CategoryID = :cat"),
        {"min_price": 100, "cat": 5}
    )
```

---

## ➕ INSERT Operations

### Single Insert

```python
cursor.execute(
    "INSERT INTO Customers (CustomerName, City, Country) VALUES (?, ?, ?)",
    ('John Doe', 'New York', 'USA')
)
conn.commit()

# Get inserted ID (SQL Server)
cursor.execute("SELECT SCOPE_IDENTITY()")
new_id = cursor.fetchone()[0]
print(f"Inserted ID: {new_id}")

# Or use OUTPUT clause
cursor.execute("""
    INSERT INTO Customers (CustomerName, City) 
    OUTPUT INSERTED.CustomerID
    VALUES (?, ?)
""", ('Jane Doe', 'Boston'))
new_id = cursor.fetchone()[0]
```

### Bulk Insert

```python
# Insert multiple rows
data = [
    ('Product A', 10.99, 100),
    ('Product B', 20.99, 200),
    ('Product C', 30.99, 300),
]

cursor.executemany(
    "INSERT INTO Products (ProductName, Price, Stock) VALUES (?, ?, ?)",
    data
)
conn.commit()

print(f"Rows inserted: {cursor.rowcount}")
```

### Fast Bulk Insert (SQL Server)

```python
# Using fast_executemany for better performance
cursor.fast_executemany = True
cursor.executemany(
    "INSERT INTO Products (Name, Price) VALUES (?, ?)",
    large_data_list
)
conn.commit()
```

---

## ✏️ UPDATE Operations

### Simple Update

```python
cursor.execute(
    "UPDATE Products SET Price = ? WHERE ProductID = ?",
    (15.99, 1)
)
conn.commit()

print(f"Rows updated: {cursor.rowcount}")
```

### Conditional Update

```python
# Update with multiple conditions
cursor.execute("""
    UPDATE Orders 
    SET Status = ?, UpdatedAt = GETDATE()
    WHERE Status = ? AND OrderDate < ?
""", ('Archived', 'Completed', '2022-01-01'))
conn.commit()
```

### Update from List

```python
updates = [
    (10.99, 1),
    (20.99, 2),
    (30.99, 3),
]

cursor.executemany(
    "UPDATE Products SET Price = ? WHERE ProductID = ?",
    updates
)
conn.commit()
```

---

## ❌ DELETE Operations

### Simple Delete

```python
cursor.execute(
    "DELETE FROM Products WHERE ProductID = ?",
    (1,)
)
conn.commit()

print(f"Rows deleted: {cursor.rowcount}")
```

### Conditional Delete

```python
cursor.execute("""
    DELETE FROM Orders 
    WHERE Status = 'Cancelled' AND OrderDate < ?
""", ('2022-01-01',))
conn.commit()
```

### Truncate vs Delete

```python
# Delete all rows (logged, slow for large tables)
cursor.execute("DELETE FROM TempTable")

# Truncate (fast, minimal logging)
cursor.execute("TRUNCATE TABLE TempTable")
conn.commit()
```

---

## 🔄 Transaction Management

### Explicit Transactions

```python
try:
    # Disable auto-commit
    conn.autocommit = False
    
    cursor.execute("INSERT INTO Orders VALUES (...)")
    cursor.execute("UPDATE Inventory SET Stock = Stock - 1 WHERE ...")
    cursor.execute("INSERT INTO OrderHistory VALUES (...)")
    
    # All succeeded - commit
    conn.commit()
    print("Transaction committed")
    
except Exception as e:
    # Something failed - rollback
    conn.rollback()
    print(f"Transaction rolled back: {e}")
    
finally:
    conn.autocommit = True
```

### SQLAlchemy Transactions

```python
from sqlalchemy import text

# Using begin() for auto-commit/rollback
with engine.begin() as conn:
    conn.execute(text("INSERT INTO table1 VALUES (1, 'a')"))
    conn.execute(text("INSERT INTO table2 VALUES (2, 'b')"))
# Auto-committed if no exception, rolled back if exception

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

## 📦 Stored Procedures

### Calling Stored Procedures

```python
# SQL Server stored procedure
cursor.execute("{CALL GetCustomerOrders (?)}", (customer_id,))
orders = cursor.fetchall()

# With OUTPUT parameter
sql = """\
DECLARE @count INT
EXEC GetOrderCount @CustomerID = ?, @OrderCount = @count OUTPUT
SELECT @count
"""
cursor.execute(sql, (customer_id,))
count = cursor.fetchone()[0]

# Multiple result sets
cursor.execute("{CALL GetCustomerDetails (?)}", (customer_id,))

# First result set
customer = cursor.fetchone()

# Move to next result set
cursor.nextset()

# Second result set
orders = cursor.fetchall()
```

### SQLAlchemy Stored Procedures

```python
from sqlalchemy import text

with engine.connect() as conn:
    # Simple call
    result = conn.execute(text("EXEC GetProducts @Category = :cat"), {"cat": "Electronics"})
    products = result.fetchall()
    
    # With OUTPUT parameters
    result = conn.execute(text("""
        DECLARE @result INT
        EXEC CalculateTotal @OrderID = :order_id, @Total = @result OUTPUT
        SELECT @result
    """), {"order_id": 123})
    total = result.fetchone()[0]
```

---

## 🚀 Performance Optimization

### Batch Processing

```python
# Process large datasets in batches
batch_size = 1000

with open('large_data.csv', 'r') as f:
    reader = csv.reader(f)
    next(reader)  # Skip header
    
    batch = []
    for row in reader:
        batch.append((row[0], row[1], row[2]))
        
        if len(batch) >= batch_size:
            cursor.executemany(
                "INSERT INTO Table (A, B, C) VALUES (?, ?, ?)",
                batch
            )
            conn.commit()
            batch = []
    
    # Insert remaining rows
    if batch:
        cursor.executemany(
            "INSERT INTO Table (A, B, C) VALUES (?, ?, ?)",
            batch
        )
        conn.commit()
```

### Server-Side Cursors

```python
# For very large result sets
import psycopg2

with psycopg2.connect(conn_string) as conn:
    # Named cursor = server-side
    with conn.cursor(name='server_cursor') as cursor:
        cursor.itersize = 10000  # Fetch in batches
        cursor.execute("SELECT * FROM huge_table")
        
        for row in cursor:
            process(row)
```

### Prepared Statements

```python
# Reuse query plan for repeated execution
sql = "SELECT * FROM Products WHERE CategoryID = ?"

for category_id in category_list:
    cursor.execute(sql, (category_id,))
    products = cursor.fetchall()
    process(products)
```

---

## 🔍 Dynamic SQL

### Building Dynamic Queries

```python
def build_query(table, filters=None, order_by=None):
    """Build SELECT query dynamically"""
    query = f"SELECT * FROM {table}"
    params = []
    
    if filters:
        conditions = []
        for column, value in filters.items():
            conditions.append(f"{column} = ?")
            params.append(value)
        query += " WHERE " + " AND ".join(conditions)
    
    if order_by:
        query += f" ORDER BY {order_by}"
    
    return query, params

# Usage
query, params = build_query(
    'Products',
    filters={'CategoryID': 5, 'IsActive': 1},
    order_by='ProductName'
)
cursor.execute(query, params)
```

### Safe Table/Column Names

```python
# Validate table/column names to prevent injection
ALLOWED_TABLES = {'Products', 'Orders', 'Customers'}
ALLOWED_COLUMNS = {'ProductID', 'ProductName', 'Price', 'Category'}

def safe_query(table, columns):
    if table not in ALLOWED_TABLES:
        raise ValueError(f"Invalid table: {table}")
    
    for col in columns:
        if col not in ALLOWED_COLUMNS:
            raise ValueError(f"Invalid column: {col}")
    
    cols = ", ".join(columns)
    return f"SELECT {cols} FROM {table}"
```

---

## 🎓 Interview Questions

### Q1: What is the difference between execute() and executemany()?
**A:**
- **execute()**: Runs single query
- **executemany()**: Runs same query multiple times with different parameters, more efficient for bulk operations

### Q2: How do you prevent SQL injection?
**A:** Always use parameterized queries with placeholders:
```python
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
```
Never concatenate user input into SQL strings.

### Q3: What is fast_executemany in pyodbc?
**A:** A pyodbc optimization that sends all parameters in one network round-trip instead of individual calls, significantly faster for bulk inserts.

### Q4: How do you handle transactions in Python?
**A:**
```python
try:
    conn.autocommit = False
    cursor.execute("INSERT...")
    cursor.execute("UPDATE...")
    conn.commit()
except:
    conn.rollback()
    raise
```

### Q5: What is cursor.rowcount?
**A:** Returns the number of rows affected by the last execute() for INSERT, UPDATE, DELETE. Returns -1 for SELECT in some drivers.

### Q6: How do you get the auto-generated ID after INSERT?
**A:** SQL Server: `cursor.execute("SELECT SCOPE_IDENTITY()")` or use `OUTPUT INSERTED.ID` clause.

### Q7: What is a server-side cursor?
**A:** Cursor that keeps results on database server instead of fetching all to client. Useful for very large result sets to avoid memory issues.

### Q8: How do you call a stored procedure with output parameters?
**A:**
```python
sql = "DECLARE @out INT; EXEC MyProc @in=?, @out=@out OUTPUT; SELECT @out"
cursor.execute(sql, (input_value,))
output = cursor.fetchone()[0]
```

### Q9: What is cursor.description?
**A:** Returns metadata about columns in the result set: name, type, display_size, internal_size, precision, scale, nullable.

### Q10: How do you process multiple result sets?
**A:** Use `cursor.nextset()` to move to the next result set:
```python
cursor.execute("EXEC ProcWithMultipleSelects")
first_result = cursor.fetchall()
cursor.nextset()
second_result = cursor.fetchall()
```

---

## 🔗 Related Topics
- [← Database Connectivity](./01_database_connections.md)
- [Pandas-SQL Integration →](./03_pandas_sql.md)
- [ETL with Python →](./04_etl_python.md)

---

*Continue to Pandas-SQL Integration*
