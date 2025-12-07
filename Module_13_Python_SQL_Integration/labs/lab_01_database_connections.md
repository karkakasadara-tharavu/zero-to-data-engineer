# Lab 01: Database Connections and Basic Operations

## Learning Objectives

By completing this lab, you will:
- Connect to SQLite, PostgreSQL, and MySQL databases
- Execute basic SQL queries using DB-API 2.0
- Implement proper connection management and error handling
- Use context managers for resource cleanup
- Test database connectivity and handle common errors

## Prerequisites

- Python 3.8+
- Libraries: `sqlite3` (built-in), `psycopg2`, `pymysql`
- Basic SQL knowledge
- Understanding of Python context managers

## Tasks

### Task 1: SQLite Connection Manager (25 points)

Create a reusable SQLite connection class with context manager support.

**Requirements:**
- `DatabaseConnection` class that accepts database path
- Context manager implementation (`__enter__` and `__exit__`)
- Automatic connection cleanup
- Error handling for connection failures

**Starter Code:**
```python
import sqlite3
from typing import Optional

class DatabaseConnection:
    """Context manager for SQLite connections"""
    
    def __init__(self, db_path: str):
        # TODO: Initialize with database path
        pass
    
    def __enter__(self):
        # TODO: Create and return connection
        pass
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        # TODO: Close connection, commit if no errors
        pass

# Test code
with DatabaseConnection('test.db') as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT 1")
    print(cursor.fetchone())
```

### Task 2: Multi-Database Connection Factory (25 points)

Implement a factory function that creates connections to different database types.

**Requirements:**
- Support SQLite, PostgreSQL, and MySQL
- Accept connection parameters as dictionary
- Return appropriate connection object
- Handle database-specific configurations

**Starter Code:**
```python
def create_connection(db_type: str, **kwargs):
    """
    Create database connection based on type
    
    Args:
        db_type: 'sqlite', 'postgresql', or 'mysql'
        **kwargs: Connection parameters
    
    Returns:
        Database connection object
    """
    # TODO: Implement factory logic
    pass

# Test with different databases
sqlite_conn = create_connection('sqlite', database='test.db')
pg_conn = create_connection('postgresql', 
    host='localhost', 
    database='mydb',
    user='user',
    password='pass'
)
```

### Task 3: CRUD Operations Wrapper (25 points)

Create a class that simplifies CRUD operations for a users table.

**Requirements:**
- Create table if not exists
- Insert, read, update, delete operations
- Parameterized queries (prevent SQL injection)
- Return results as dictionaries

**Starter Code:**
```python
class UserManager:
    """Manage user CRUD operations"""
    
    def __init__(self, connection):
        self.conn = connection
        self.create_table()
    
    def create_table(self):
        """Create users table if not exists"""
        # TODO: Implement table creation
        pass
    
    def create_user(self, username: str, email: str):
        """Insert new user"""
        # TODO: Implement insert
        pass
    
    def get_user(self, user_id: int):
        """Get user by ID"""
        # TODO: Implement select
        pass
    
    def update_user(self, user_id: int, **updates):
        """Update user fields"""
        # TODO: Implement update
        pass
    
    def delete_user(self, user_id: int):
        """Delete user"""
        # TODO: Implement delete
        pass
```

### Task 4: Connection Pool Implementation (25 points)

Implement a simple connection pool for PostgreSQL.

**Requirements:**
- Pool size configuration
- Check out/return connections
- Connection health checking
- Proper cleanup on shutdown

**Starter Code:**
```python
import psycopg2
from queue import Queue, Empty
from contextlib import contextmanager

class ConnectionPool:
    """Simple connection pool"""
    
    def __init__(self, dsn: str, pool_size: int = 5):
        # TODO: Initialize pool
        pass
    
    @contextmanager
    def get_connection(self):
        """Get connection from pool"""
        # TODO: Implement checkout/return
        pass
    
    def close_all(self):
        """Close all connections"""
        # TODO: Implement cleanup
        pass

# Usage
pool = ConnectionPool('postgresql://user:pass@localhost/db', pool_size=3)

with pool.get_connection() as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT 1")
    print(cursor.fetchone())

pool.close_all()
```

## Testing

### Test Cases

```python
import unittest
from pathlib import Path

class TestDatabaseConnections(unittest.TestCase):
    """Test database connection functionality"""
    
    def setUp(self):
        """Set up test database"""
        self.test_db = 'test_lab01.db'
        if Path(self.test_db).exists():
            Path(self.test_db).unlink()
    
    def test_context_manager(self):
        """Test DatabaseConnection context manager"""
        with DatabaseConnection(self.test_db) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            self.assertEqual(result[0], 1)
    
    def test_user_crud(self):
        """Test UserManager CRUD operations"""
        with DatabaseConnection(self.test_db) as conn:
            manager = UserManager(conn)
            
            # Create
            user_id = manager.create_user('alice', 'alice@example.com')
            self.assertIsNotNone(user_id)
            
            # Read
            user = manager.get_user(user_id)
            self.assertEqual(user['username'], 'alice')
            
            # Update
            manager.update_user(user_id, email='newemail@example.com')
            user = manager.get_user(user_id)
            self.assertEqual(user['email'], 'newemail@example.com')
            
            # Delete
            manager.delete_user(user_id)
            user = manager.get_user(user_id)
            self.assertIsNone(user)
    
    def tearDown(self):
        """Clean up test database"""
        if Path(self.test_db).exists():
            Path(self.test_db).unlink()

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **database_connection.py**: `DatabaseConnection` class implementation
2. **connection_factory.py**: Multi-database connection factory
3. **user_manager.py**: `UserManager` class with CRUD operations
4. **connection_pool.py**: Simple connection pool implementation
5. **tests.py**: Unit tests for all components
6. **README.md**: Documentation with usage examples

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 25 | Context manager properly manages connections |
| Task 2 | 25 | Factory supports all three database types |
| Task 3 | 25 | CRUD operations work correctly with parameterized queries |
| Task 4 | 25 | Connection pool manages connections efficiently |

**Total: 100 points**

## Bonus Challenges (+20 points)

1. **Retry Logic** (+10 points): Add automatic retry with exponential backoff for transient errors
2. **Health Monitoring** (+10 points): Implement connection health checking and auto-healing

## Submission

Submit all Python files and documentation in a ZIP file named `lab01_lastname_firstname.zip`.

## Resources

- [Python DB-API 2.0](https://peps.python.org/pep-0249/)
- [sqlite3 Documentation](https://docs.python.org/3/library/sqlite3.html)
- [psycopg2 Documentation](https://www.psycopg.org/docs/)
- [PyMySQL Documentation](https://pymysql.readthedocs.io/)
