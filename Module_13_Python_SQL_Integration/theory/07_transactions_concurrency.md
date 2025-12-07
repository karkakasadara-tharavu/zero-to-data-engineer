# Section 07: Transactions and Concurrency

## Introduction

Transactions ensure data integrity in multi-user environments. This section covers transaction management, isolation levels, locking strategies, and connection pooling.

## Transaction Basics

### ACID Properties

- **Atomicity**: All operations succeed or all fail
- **Consistency**: Data moves from one valid state to another
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed changes persist

### Simple Transactions

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

engine = create_engine('postgresql://user:pass@localhost/db')

# Automatic transaction management
with Session(engine) as session:
    user = User(username='alice', email='alice@example.com')
    session.add(user)
    session.commit()  # Transaction committed

# Explicit rollback
with Session(engine) as session:
    user = User(username='bob', email='bob@example.com')
    session.add(user)
    session.rollback()  # Transaction rolled back, changes discarded
```

### Transaction Context Manager

```python
# Method 1: Session.begin()
with Session(engine) as session:
    with session.begin():
        user1 = User(username='alice', email='alice@example.com')
        user2 = User(username='bob', email='bob@example.com')
        session.add_all([user1, user2])
        # Automatically committed if no exception

# Method 2: engine.begin()
with engine.begin() as conn:
    conn.execute(
        users_table.insert(),
        {'username': 'alice', 'email': 'alice@example.com'}
    )
    # Automatically committed
```

### Manual Transaction Control

```python
session = Session(engine)
transaction = session.begin()

try:
    user = User(username='alice', email='alice@example.com')
    session.add(user)
    
    # Perform more operations
    product = Product(name='Laptop', price=999.99)
    session.add(product)
    
    transaction.commit()
except Exception as e:
    transaction.rollback()
    print(f"Transaction failed: {e}")
finally:
    session.close()
```

## Savepoints (Nested Transactions)

### Creating Savepoints

```python
with Session(engine) as session:
    session.add(User(username='alice', email='alice@example.com'))
    
    # Create savepoint
    savepoint = session.begin_nested()
    try:
        # This might fail
        session.add(User(username='bob', email='invalid'))
        session.flush()
        savepoint.commit()
    except Exception as e:
        # Rollback to savepoint
        savepoint.rollback()
        print(f"Savepoint rolled back: {e}")
    
    # Main transaction continues
    session.commit()
```

### Multiple Savepoints

```python
with Session(engine) as session:
    session.add(User(username='alice', email='alice@example.com'))
    
    sp1 = session.begin_nested()
    session.add(User(username='bob', email='bob@example.com'))
    
    sp2 = session.begin_nested()
    session.add(User(username='carol', email='carol@example.com'))
    
    # Roll back to sp2
    sp2.rollback()  # carol not added
    
    sp1.commit()  # bob still added
    session.commit()  # alice and bob committed
```

## Isolation Levels

### Understanding Isolation Levels

```python
from sqlalchemy import create_engine

# Set isolation level on engine
engine = create_engine(
    'postgresql://user:pass@localhost/db',
    isolation_level='REPEATABLE_READ'
)

# Isolation levels (from least to most strict):
# - READ UNCOMMITTED
# - READ COMMITTED (default for most databases)
# - REPEATABLE READ
# - SERIALIZABLE
```

### Per-Connection Isolation

```python
# Set for specific connection
with engine.connect() as conn:
    conn = conn.execution_options(isolation_level='SERIALIZABLE')
    
    # Perform operations with SERIALIZABLE isolation
    result = conn.execute(text("SELECT * FROM users"))
```

### Per-Session Isolation

```python
# Set for entire session
session = Session(engine)
session.connection(execution_options={'isolation_level': 'REPEATABLE_READ'})

try:
    # All operations use REPEATABLE_READ
    user = session.query(User).first()
    user.balance += 100
    session.commit()
finally:
    session.close()
```

### Isolation Level Examples

```python
# READ COMMITTED: Most common, prevents dirty reads
engine_rc = create_engine(
    'postgresql://user:pass@localhost/db',
    isolation_level='READ_COMMITTED'
)

# REPEATABLE READ: Prevents non-repeatable reads
engine_rr = create_engine(
    'postgresql://user:pass@localhost/db',
    isolation_level='REPEATABLE_READ'
)

# SERIALIZABLE: Strictest, prevents phantom reads
engine_ser = create_engine(
    'postgresql://user:pass@localhost/db',
    isolation_level='SERIALIZABLE'
)
```

## Locking Strategies

### Optimistic Locking with Version Column

```python
from sqlalchemy import Column, Integer, String

class Account(Base):
    __tablename__ = 'accounts'
    
    id = Column(Integer, primary_key=True)
    balance = Column(Float, nullable=False)
    version = Column(Integer, default=0, nullable=False)
    
    __mapper_args__ = {
        'version_id_col': version
    }

# Usage
with Session(engine) as session:
    account = session.query(Account).filter_by(id=1).first()
    account.balance += 100
    
    try:
        session.commit()  # Fails if version changed
    except Exception as e:
        print(f"Concurrent modification detected: {e}")
        session.rollback()
```

### Pessimistic Locking with SELECT FOR UPDATE

```python
# Row-level lock
with Session(engine) as session:
    # Lock the row for update
    account = session.query(Account)\
        .filter_by(id=1)\
        .with_for_update()\
        .first()
    
    # Modify safely
    account.balance += 100
    session.commit()  # Lock released

# Lock with NOWAIT
with Session(engine) as session:
    try:
        account = session.query(Account)\
            .filter_by(id=1)\
            .with_for_update(nowait=True)\
            .first()
    except Exception as e:
        print("Row is locked by another transaction")

# Shared lock (FOR SHARE)
with Session(engine) as session:
    account = session.query(Account)\
        .filter_by(id=1)\
        .with_for_update(read=True)\
        .first()
```

### Table-Level Locking

```python
# Lock entire table (PostgreSQL)
with engine.begin() as conn:
    conn.execute(text("LOCK TABLE accounts IN EXCLUSIVE MODE"))
    # Perform operations
    conn.execute(text("UPDATE accounts SET balance = balance * 1.05"))
```

## Concurrency Patterns

### Transfer with Locking

```python
def transfer_money(from_account_id, to_account_id, amount):
    with Session(engine) as session:
        # Lock both accounts
        from_account = session.query(Account)\
            .filter_by(id=from_account_id)\
            .with_for_update()\
            .first()
        
        to_account = session.query(Account)\
            .filter_by(id=to_account_id)\
            .with_for_update()\
            .first()
        
        # Check balance
        if from_account.balance < amount:
            raise ValueError("Insufficient funds")
        
        # Perform transfer
        from_account.balance -= amount
        to_account.balance += amount
        
        session.commit()

# Usage
try:
    transfer_money(1, 2, 100.0)
    print("Transfer successful")
except ValueError as e:
    print(f"Transfer failed: {e}")
```

### Retry Logic for Deadlocks

```python
import time
from sqlalchemy.exc import OperationalError

def retry_on_deadlock(func, max_retries=3):
    """Decorator to retry on deadlock"""
    def wrapper(*args, **kwargs):
        for attempt in range(max_retries):
            try:
                return func(*args, **kwargs)
            except OperationalError as e:
                if 'deadlock' in str(e).lower() and attempt < max_retries - 1:
                    time.sleep(0.1 * (2 ** attempt))  # Exponential backoff
                    continue
                raise
    return wrapper

@retry_on_deadlock
def update_account_balance(account_id, amount):
    with Session(engine) as session:
        account = session.query(Account)\
            .filter_by(id=account_id)\
            .with_for_update()\
            .first()
        
        account.balance += amount
        session.commit()
```

### Queue-Based Approach

```python
from queue import Queue
from threading import Thread

class DatabaseWorker(Thread):
    """Process database operations from queue"""
    
    def __init__(self, queue):
        super().__init__()
        self.queue = queue
        self.daemon = True
    
    def run(self):
        while True:
            operation = self.queue.get()
            if operation is None:
                break
            
            try:
                operation()
            except Exception as e:
                print(f"Operation failed: {e}")
            finally:
                self.queue.task_done()

# Usage
queue = Queue()
worker = DatabaseWorker(queue)
worker.start()

# Submit operations
def update_user(user_id, email):
    with Session(engine) as session:
        user = session.query(User).filter_by(id=user_id).first()
        user.email = email
        session.commit()

queue.put(lambda: update_user(1, 'new@example.com'))
queue.join()  # Wait for completion
```

## Connection Pooling

### Pool Configuration

```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    'postgresql://user:pass@localhost/db',
    poolclass=QueuePool,
    pool_size=10,           # Number of connections to maintain
    max_overflow=20,        # Extra connections when pool exhausted
    pool_timeout=30,        # Seconds to wait for connection
    pool_recycle=3600,      # Recycle connections after 1 hour
    pool_pre_ping=True      # Verify connection health before use
)
```

### Pool Types

```python
from sqlalchemy.pool import NullPool, StaticPool, QueuePool

# No pooling (create new connection each time)
engine = create_engine('sqlite:///db.db', poolclass=NullPool)

# Single connection shared (SQLite)
engine = create_engine('sqlite:///db.db', poolclass=StaticPool)

# Queue-based pooling (most common)
engine = create_engine('postgresql://...', poolclass=QueuePool)
```

### Monitoring Connection Pool

```python
# Check pool status
print(f"Pool size: {engine.pool.size()}")
print(f"Checked out: {engine.pool.checkedout()}")
print(f"Overflow: {engine.pool.overflow()}")

# Pool events
from sqlalchemy import event

@event.listens_for(engine, 'connect')
def receive_connect(dbapi_conn, connection_record):
    print("New connection created")

@event.listens_for(engine, 'checkout')
def receive_checkout(dbapi_conn, connection_record, connection_proxy):
    print("Connection checked out from pool")

@event.listens_for(engine, 'checkin')
def receive_checkin(dbapi_conn, connection_record):
    print("Connection returned to pool")
```

## Complete Example

```python
from sqlalchemy import create_engine, Column, Integer, Float, String
from sqlalchemy.orm import declarative_base, Session
from sqlalchemy.exc import OperationalError
import time

Base = declarative_base()

class BankAccount(Base):
    __tablename__ = 'bank_accounts'
    
    id = Column(Integer, primary_key=True)
    account_number = Column(String(20), unique=True)
    balance = Column(Float, nullable=False)
    version = Column(Integer, default=0, nullable=False)
    
    __mapper_args__ = {
        'version_id_col': version
    }

# Engine with connection pooling
engine = create_engine(
    'postgresql://user:pass@localhost/bank',
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True
)

Base.metadata.create_all(engine)

def transfer_with_retry(from_id, to_id, amount, max_retries=3):
    """Transfer money with deadlock retry"""
    for attempt in range(max_retries):
        try:
            with Session(engine) as session:
                with session.begin():
                    # Lock both accounts (ordered by ID to prevent deadlock)
                    ids = sorted([from_id, to_id])
                    accounts = session.query(BankAccount)\
                        .filter(BankAccount.id.in_(ids))\
                        .with_for_update()\
                        .all()
                    
                    from_account = next(a for a in accounts if a.id == from_id)
                    to_account = next(a for a in accounts if a.id == to_id)
                    
                    # Validate
                    if from_account.balance < amount:
                        raise ValueError("Insufficient funds")
                    
                    # Transfer
                    from_account.balance -= amount
                    to_account.balance += amount
                    
                    # Automatically committed
                
                print(f"Transfer successful: ${amount}")
                return True
                
        except OperationalError as e:
            if 'deadlock' in str(e).lower() and attempt < max_retries - 1:
                wait_time = 0.1 * (2 ** attempt)
                print(f"Deadlock detected, retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                raise
        except Exception as e:
            print(f"Transfer failed: {e}")
            return False
    
    return False

# Create test accounts
with Session(engine) as session:
    acc1 = BankAccount(account_number='ACC001', balance=1000.0)
    acc2 = BankAccount(account_number='ACC002', balance=500.0)
    session.add_all([acc1, acc2])
    session.commit()

# Perform transfer
transfer_with_retry(1, 2, 100.0)

# Check balances
with Session(engine) as session:
    accounts = session.query(BankAccount).all()
    for account in accounts:
        print(f"{account.account_number}: ${account.balance}")
```

## Summary

Key concepts:
- **Transactions**: ACID properties ensure data integrity
- **Isolation Levels**: Control visibility of concurrent changes
- **Locking**: Optimistic (version) vs Pessimistic (FOR UPDATE)
- **Concurrency**: Handle deadlocks with retry logic
- **Connection Pooling**: Reuse connections efficiently

**Next**: Section 08 - Database Migrations with Alembic
