# Lab 06: Transactions and Concurrency

## Learning Objectives

- Implement ACID transactions
- Handle isolation levels and locking
- Manage concurrent database access
- Implement retry logic for deadlocks
- Use optimistic and pessimistic locking

## Prerequisites

- SQLAlchemy transactions
- Understanding of concurrency concepts
- Completion of Labs 01-05

## Tasks

### Task 1: Banking System with Transactions (25 points)

Implement a banking system with proper transaction handling.

**Requirements:**
```python
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from datetime import datetime

class Account(Base):
    __tablename__ = 'accounts'
    
    id = Column(Integer, primary_key=True)
    account_number = Column(String(20), unique=True, nullable=False)
    customer_name = Column(String(100), nullable=False)
    balance = Column(Float, nullable=False, default=0.0)
    account_type = Column(String(20))  # 'checking', 'savings'
    created_at = Column(DateTime, default=datetime.utcnow)
    version = Column(Integer, default=0, nullable=False)  # For optimistic locking
    
    transactions = relationship('Transaction', back_populates='account')
    
    __table_args__ = (
        CheckConstraint('balance >= 0', name='positive_balance'),
    )
    
    __mapper_args__ = {
        'version_id_col': version  # Enable optimistic locking
    }

class Transaction(Base):
    __tablename__ = 'transactions'
    
    id = Column(Integer, primary_key=True)
    account_id = Column(Integer, ForeignKey('accounts.id'), nullable=False)
    transaction_type = Column(String(20), nullable=False)  # 'deposit', 'withdrawal', 'transfer'
    amount = Column(Float, nullable=False)
    balance_after = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    description = Column(String(200))
    
    account = relationship('Account', back_populates='transactions')

# Transaction operations
def deposit(session, account_id, amount, description=None):
    """Deposit money with transaction"""
    # TODO: Implement with proper transaction handling
    # 1. Lock account
    # 2. Update balance
    # 3. Create transaction record
    # 4. Commit
    pass

def withdraw(session, account_id, amount, description=None):
    """Withdraw money with transaction"""
    # TODO: Similar to deposit
    # Check sufficient balance
    pass

def transfer(session, from_account_id, to_account_id, amount, description=None):
    """Transfer money between accounts"""
    # TODO: Implement transfer with transaction
    # 1. Lock both accounts (in consistent order to avoid deadlock)
    # 2. Withdraw from source
    # 3. Deposit to destination
    # 4. Create transaction records for both
    # 5. Commit all or rollback all
    pass
```

### Task 2: Isolation Levels and Locking (25 points)

Demonstrate different isolation levels and locking strategies.

**Requirements:**
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

def demo_read_uncommitted(engine):
    """
    Demonstrate READ UNCOMMITTED isolation
    
    Show dirty read problem
    """
    # TODO: Create two sessions with READ UNCOMMITTED
    # Session 1: Start transaction, update balance
    # Session 2: Read balance (should see uncommitted change)
    # Session 1: Rollback
    # Session 2: Value was dirty read
    pass

def demo_read_committed(engine):
    """
    Demonstrate READ COMMITTED isolation
    
    Show non-repeatable read
    """
    # TODO: READ COMMITTED prevents dirty reads
    # but allows non-repeatable reads
    pass

def demo_repeatable_read(engine):
    """
    Demonstrate REPEATABLE READ isolation
    
    Show phantom read problem
    """
    # TODO: REPEATABLE READ prevents non-repeatable reads
    # but may allow phantom reads
    pass

def demo_serializable(engine):
    """
    Demonstrate SERIALIZABLE isolation
    
    Show strictest isolation
    """
    # TODO: SERIALIZABLE prevents all anomalies
    # but has performance cost
    pass

def demo_pessimistic_locking(session):
    """
    Use SELECT FOR UPDATE to lock rows
    """
    # TODO: Lock account during transaction
    # account = session.query(Account).filter_by(id=1).with_for_update().first()
    # Other sessions will wait for lock release
    pass

def demo_optimistic_locking(session):
    """
    Use version column for optimistic locking
    """
    # TODO: SQLAlchemy automatically checks version
    # Raises StaleDataError if version changed
    pass
```

### Task 3: Deadlock Handling (25 points)

Implement deadlock detection and retry logic.

**Requirements:**
```python
from sqlalchemy.exc import OperationalError
import time
import random

class DeadlockRetry:
    """Decorator for automatic deadlock retry"""
    
    def __init__(self, max_retries=3, backoff_factor=0.1):
        self.max_retries = max_retries
        self.backoff_factor = backoff_factor
    
    def __call__(self, func):
        def wrapper(*args, **kwargs):
            for attempt in range(self.max_retries):
                try:
                    return func(*args, **kwargs)
                except OperationalError as e:
                    if 'deadlock' in str(e).lower() and attempt < self.max_retries - 1:
                        # Exponential backoff with jitter
                        wait_time = self.backoff_factor * (2 ** attempt) + random.uniform(0, 0.1)
                        time.sleep(wait_time)
                        continue
                    raise
        return wrapper

@DeadlockRetry(max_retries=5)
def transfer_with_retry(session, from_id, to_id, amount):
    """Transfer with automatic deadlock retry"""
    # TODO: Implement transfer
    # Lock accounts in consistent order (by ID) to minimize deadlocks
    pass

def simulate_concurrent_transfers(engine, num_threads=10):
    """
    Simulate concurrent transfers to test deadlock handling
    
    Args:
        engine: Database engine
        num_threads: Number of concurrent transfers
    """
    from threading import Thread
    
    def worker(worker_id):
        # TODO: Perform random transfers
        # Some should cause deadlocks
        pass
    
    # TODO: Create and start threads
    # Collect results
    # Report success/retry/failure counts
    pass
```

### Task 4: Connection Pooling and Concurrency (25 points)

Implement and test connection pool management.

**Requirements:**
```python
from sqlalchemy.pool import QueuePool, NullPool, StaticPool
from threading import Thread, Lock
import time

def test_connection_pool(pool_size=5, num_workers=20):
    """
    Test connection pool under load
    
    Args:
        pool_size: Pool size
        num_workers: Number of concurrent workers
    """
    engine = create_engine(
        'postgresql://user:pass@localhost/db',
        poolclass=QueuePool,
        pool_size=pool_size,
        max_overflow=10,
        pool_timeout=30,
        pool_pre_ping=True
    )
    
    stats = {'queries': 0, 'waits': 0, 'lock': Lock()}
    
    def worker(worker_id):
        # TODO: Perform database operations
        # Track connection wait times
        pass
    
    # TODO: Run workers concurrently
    # Collect and display statistics
    pass

def optimize_pool_settings(engine):
    """
    Test different pool settings and find optimal configuration
    
    Returns:
        Dict with optimal settings
    """
    # TODO: Test various combinations
    # - pool_size: 5, 10, 20
    # - max_overflow: 0, 10, 20
    # - pool_timeout: 10, 30, 60
    # Measure throughput and wait times
    pass

def implement_queue_based_processing():
    """
    Use queue to serialize database operations
    
    Avoids some concurrency issues by queueing requests
    """
    from queue import Queue
    
    # TODO: Create worker thread that processes queue
    # Main threads submit requests to queue
    # Worker processes them sequentially
    pass
```

## Testing

```python
import unittest
from threading import Thread
import time

class TestTransactionsAndConcurrency(unittest.TestCase):
    """Test transaction handling and concurrency"""
    
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine('sqlite:///test_transactions.db')
        Base.metadata.create_all(cls.engine)
        
        # Create test accounts
        with Session(cls.engine) as session:
            acc1 = Account(account_number='ACC001', customer_name='Alice', balance=1000.0)
            acc2 = Account(account_number='ACC002', customer_name='Bob', balance=500.0)
            session.add_all([acc1, acc2])
            session.commit()
    
    def test_deposit(self):
        """Test deposit operation"""
        with Session(self.engine) as session:
            initial = session.query(Account).filter_by(account_number='ACC001').first().balance
            deposit(session, 1, 100.0, 'Test deposit')
            session.commit()
            
            final = session.query(Account).filter_by(account_number='ACC001').first().balance
            self.assertEqual(final, initial + 100.0)
    
    def test_transfer_atomicity(self):
        """Test transfer is atomic"""
        with Session(self.engine) as session:
            try:
                # Transfer that should fail (insufficient funds)
                transfer(session, 2, 1, 1000.0)  # Bob only has 500
                session.commit()
            except Exception:
                session.rollback()
            
            # Balances should be unchanged
            acc2 = session.query(Account).filter_by(account_number='ACC002').first()
            self.assertEqual(acc2.balance, 500.0)
    
    def test_concurrent_transfers(self):
        """Test concurrent transfers don't corrupt data"""
        initial_total = 1000.0 + 500.0  # Total money in system
        
        def do_transfer():
            with Session(self.engine) as session:
                try:
                    transfer_with_retry(session, 1, 2, 50.0)
                    session.commit()
                except:
                    session.rollback()
        
        # Run 10 concurrent transfers
        threads = [Thread(target=do_transfer) for _ in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        
        # Total money should be conserved
        with Session(self.engine) as session:
            total = session.query(func.sum(Account.balance)).scalar()
            self.assertEqual(total, initial_total)
    
    def test_optimistic_locking(self):
        """Test optimistic locking prevents lost updates"""
        with Session(self.engine) as session1, Session(self.engine) as session2:
            # Both sessions read same account
            acc1 = session1.query(Account).filter_by(id=1).first()
            acc2 = session2.query(Account).filter_by(id=1).first()
            
            # Session 1 updates and commits
            acc1.balance += 100
            session1.commit()
            
            # Session 2 tries to update (should fail due to version mismatch)
            acc2.balance += 50
            with self.assertRaises(Exception):  # StaleDataError
                session2.commit()
    
    @classmethod
    def tearDownClass(cls):
        import os
        if os.path.exists('test_transactions.db'):
            os.remove('test_transactions.db')

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **banking.py**: Complete banking system
2. **isolation_demos.py**: Isolation level demonstrations
3. **deadlock_handler.py**: Deadlock retry logic
4. **pool_tester.py**: Connection pool testing
5. **concurrency_report.md**: Analysis of concurrent behavior
6. **tests.py**: Comprehensive test suite

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 25 | Transactions maintain ACID properties |
| Task 2 | 25 | Isolation levels demonstrated correctly |
| Task 3 | 25 | Deadlock handling works reliably |
| Task 4 | 25 | Connection pooling optimized |

**Total: 100 points**

## Bonus Challenges (+20 points)

1. **Distributed Transactions** (+10 points): Implement 2-phase commit
2. **Saga Pattern** (+10 points): Implement compensating transactions
