# Lab 05: Query Optimization and Performance

## Learning Objectives

- Analyze query execution plans with EXPLAIN
- Implement and use database indexes effectively
- Solve N+1 query problems
- Use bulk operations for performance
- Profile and optimize slow queries

## Prerequisites

- SQLAlchemy ORM and Core
- Understanding of database indexes
- Completion of Labs 01-04

## Tasks

### Task 1: Index Analysis and Creation (25 points)

Create a product catalog system and optimize with indexes.

**Requirements:**
```python
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Index, text
from sqlalchemy.orm import declarative_base, Session
from datetime import datetime
import time

Base = declarative_base()
engine = create_engine('sqlite:///catalog.db', echo=False)

class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    sku = Column(String(50), unique=True, nullable=False)
    name = Column(String(200), nullable=False)
    description = Column(String(1000))
    category = Column(String(50), nullable=False)
    subcategory = Column(String(50))
    price = Column(Float, nullable=False)
    stock_quantity = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # TODO: Add indexes
    # 1. Single column index on category
    # 2. Composite index on (category, subcategory)
    # 3. Index on price for range queries
    # 4. Functional index on LOWER(name) for case-insensitive search
    
    __table_args__ = (
        # Add indexes here
    )

def populate_products(session, count=100000):
    """Populate with large dataset for testing"""
    # TODO: Generate realistic test data
    # Use faker or random data
    pass

def analyze_query_performance(session, query_func, name):
    """
    Measure query execution time
    
    Args:
        session: Database session
        query_func: Function that executes query
        name: Query description
    """
    start = time.time()
    result = query_func(session)
    elapsed = time.time() - start
    
    print(f"{name}: {elapsed:.4f}s ({len(result)} results)")
    return elapsed

# Query functions to test
def query_by_category(session, category):
    """Find products by category"""
    return session.query(Product).filter_by(category=category).all()

def query_by_price_range(session, min_price, max_price):
    """Find products in price range"""
    return session.query(Product).filter(
        Product.price.between(min_price, max_price)
    ).all()

def query_by_name_partial(session, search_term):
    """Find products by partial name match"""
    return session.query(Product).filter(
        Product.name.like(f'%{search_term}%')
    ).all()

def query_composite(session, category, subcategory):
    """Find products by category and subcategory"""
    return session.query(Product).filter(
        Product.category == category,
        Product.subcategory == subcategory
    ).all()

# TODO: Implement comparison function
def compare_with_without_indexes():
    """
    Compare query performance with and without indexes
    
    1. Create table without indexes
    2. Populate data
    3. Measure query times
    4. Add indexes
    5. Measure again
    6. Show improvement percentages
    """
    pass
```

### Task 2: Solving N+1 Problems (25 points)

Implement and fix N+1 query problems.

**Requirements:**
```python
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship, selectinload, joinedload

class Author(Base):
    __tablename__ = 'authors'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    books = relationship('Book', back_populates='author')

class Book(Base):
    __tablename__ = 'books'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(200))
    author_id = Column(Integer, ForeignKey('authors.id'))
    
    author = relationship('Author', back_populates='books')
    reviews = relationship('Review', back_populates='book')

class Review(Base):
    __tablename__ = 'reviews'
    
    id = Column(Integer, primary_key=True)
    book_id = Column(Integer, ForeignKey('books.id'))
    rating = Column(Integer)
    comment = Column(String(500))
    
    book = relationship('Book', back_populates='reviews')

def demonstrate_n_plus_one(session):
    """
    Demonstrate N+1 problem
    
    Show how lazy loading causes multiple queries
    """
    print("\\n=== N+1 Problem Demo ===")
    
    # TODO: Query authors and access their books
    # Count queries executed
    # Show the problem
    
    authors = session.query(Author).all()
    print(f"Query 1: Loaded {len(authors)} authors")
    
    for i, author in enumerate(authors, 1):
        # Each access triggers a query
        book_count = len(author.books)
        print(f"Query {i+1}: Loaded {book_count} books for {author.name}")

def fix_with_joined_load(session):
    """Fix N+1 with joinedload"""
    # TODO: Use joinedload to fetch in one query
    pass

def fix_with_selectin_load(session):
    """Fix N+1 with selectinload"""
    # TODO: Use selectinload (recommended for one-to-many)
    pass

def fix_with_subquery_load(session):
    """Fix N+1 with subqueryload"""
    # TODO: Use subqueryload
    pass

def nested_n_plus_one_fix(session):
    """
    Fix nested N+1: Authors -> Books -> Reviews
    
    TODO: Load all three levels efficiently
    """
    pass

def benchmark_loading_strategies(session):
    """
    Benchmark all loading strategies
    
    Returns: Dictionary with strategy names and execution times
    """
    results = {}
    
    # TODO: Test each strategy and measure time
    # - No eager loading (lazy)
    # - joinedload
    # - selectinload
    # - subqueryload
    
    return results
```

### Task 3: Bulk Operations (25 points)

Implement efficient bulk insert, update, and delete operations.

**Requirements:**
```python
from sqlalchemy import update, delete

def bulk_insert_comparison(session, record_count=10000):
    """
    Compare different insert methods
    
    Methods:
    1. Individual inserts with commit each
    2. Batch inserts with single commit
    3. bulk_insert_mappings
    4. Core insert with executemany
    """
    
    def method_1_individual(data):
        """Worst: Commit after each insert"""
        # TODO: Implement and measure time
        pass
    
    def method_2_batch(data):
        """Better: Add all, commit once"""
        # TODO: Implement and measure time
        pass
    
    def method_3_bulk_mappings(data):
        """Best: Use bulk_insert_mappings"""
        # TODO: Implement and measure time
        pass
    
    def method_4_core_executemany(data):
        """Also fast: Core with executemany"""
        # TODO: Implement and measure time
        pass
    
    # TODO: Generate test data and run all methods
    # Return timing comparison
    pass

def bulk_update_comparison(session):
    """
    Compare update methods
    
    Methods:
    1. Load objects, modify, commit
    2. bulk_update_mappings
    3. Update query with filter
    4. Update with expressions
    """
    
    def method_1_orm_update():
        """Load and update objects"""
        # TODO: Implement
        pass
    
    def method_2_bulk_mappings():
        """Use bulk_update_mappings"""
        # TODO: Implement
        pass
    
    def method_3_query_update():
        """Direct update query"""
        # TODO: session.query(Product).filter(...).update({...})
        pass
    
    def method_4_expression_update():
        """Update with expression"""
        # TODO: Update price = price * 1.1
        pass
    
    # TODO: Measure and compare
    pass

def efficient_pagination(session, page_size=100):
    """
    Implement efficient pagination strategies
    
    Methods:
    1. Offset pagination (LIMIT/OFFSET)
    2. Keyset pagination (cursor-based)
    3. Seek method (using last ID)
    """
    
    def offset_pagination(page):
        """Standard offset pagination"""
        # TODO: Use limit and offset
        pass
    
    def keyset_pagination(last_id=None):
        """Cursor-based pagination"""
        # TODO: Use WHERE id > last_id ORDER BY id LIMIT n
        pass
    
    # TODO: Compare performance for large offsets
    pass
```

### Task 4: Query Profiling and Optimization (25 points)

Profile queries and implement optimizations.

**Requirements:**
```python
from sqlalchemy import event, func
import logging

# Set up query logging
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

class QueryProfiler:
    """Profile SQLAlchemy queries"""
    
    def __init__(self, engine):
        self.engine = engine
        self.queries = []
        self.setup_listeners()
    
    def setup_listeners(self):
        """Set up query timing listeners"""
        
        @event.listens_for(self.engine, 'before_cursor_execute')
        def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
            # TODO: Record start time
            context._query_start_time = time.time()
        
        @event.listens_for(self.engine, 'after_cursor_execute')
        def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
            # TODO: Calculate elapsed time and log
            elapsed = time.time() - context._query_start_time
            self.queries.append({
                'statement': statement,
                'parameters': parameters,
                'elapsed': elapsed
            })
    
    def get_slow_queries(self, threshold=0.1):
        """Get queries slower than threshold"""
        # TODO: Filter and return slow queries
        pass
    
    def get_summary(self):
        """Get summary statistics"""
        # TODO: Calculate total time, average, slowest query
        pass

def analyze_with_explain(session, query):
    """
    Use EXPLAIN to analyze query
    
    Args:
        session: Database session
        query: SQLAlchemy query object
    
    Returns:
        EXPLAIN output
    """
    # TODO: Execute EXPLAIN on the query
    # Show query plan
    pass

def optimize_query_example(session):
    """
    Show query optimization example
    
    1. Start with slow query
    2. Analyze with EXPLAIN
    3. Add indexes
    4. Refactor query
    5. Compare performance
    """
    
    # Slow query example
    def slow_query():
        # TODO: Complex query without optimization
        return session.query(Product).join(Author).join(Review).filter(
            Review.rating > 4,
            Product.price < 50
        ).all()
    
    # Optimized version
    def optimized_query():
        # TODO: Same query with eager loading and better filtering
        pass
    
    # TODO: Compare execution times
    pass

def identify_missing_indexes(session):
    """
    Analyze queries and suggest missing indexes
    
    Look for:
    - Columns used in WHERE clauses
    - JOIN columns
    - ORDER BY columns
    - GROUP BY columns
    """
    # TODO: Implement index suggestions
    pass
```

## Testing

```python
import unittest

class TestQueryOptimization(unittest.TestCase):
    """Test query optimization techniques"""
    
    @classmethod
    def setUpClass(cls):
        """Set up test database"""
        cls.engine = create_engine('sqlite:///test_optimization.db', echo=False)
        Base.metadata.create_all(cls.engine)
        
        # Populate with large dataset
        with Session(cls.engine) as session:
            populate_products(session, count=10000)
            session.commit()
    
    def test_index_impact(self):
        """Test that indexes improve query speed"""
        with Session(self.engine) as session:
            # Measure without index
            # Add index
            # Measure with index
            # Assert improvement
            pass
    
    def test_n_plus_one_fixed(self):
        """Test N+1 problem is resolved"""
        with Session(self.engine) as session:
            profiler = QueryProfiler(self.engine)
            
            # Use eager loading
            authors = session.query(Author).options(
                selectinload(Author.books)
            ).all()
            
            # Access books (should not trigger queries)
            for author in authors:
                _ = len(author.books)
            
            # Assert query count is reasonable
            self.assertLess(len(profiler.queries), len(authors) + 2)
    
    def test_bulk_operations(self):
        """Test bulk operations are faster"""
        with Session(self.engine) as session:
            # Generate test data
            data = [{'name': f'Product {i}', 'price': i * 10} for i in range(1000)]
            
            # Measure bulk insert
            start = time.time()
            session.bulk_insert_mappings(Product, data)
            session.commit()
            bulk_time = time.time() - start
            
            # Should complete in reasonable time
            self.assertLess(bulk_time, 1.0)  # Less than 1 second for 1000 records
    
    @classmethod
    def tearDownClass(cls):
        """Clean up"""
        import os
        if os.path.exists('test_optimization.db'):
            os.remove('test_optimization.db')

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **indexes.py**: Index implementation and analysis
2. **n_plus_one.py**: N+1 problem demonstrations and fixes
3. **bulk_ops.py**: Bulk operation implementations
4. **profiler.py**: Query profiling tools
5. **optimization_report.md**: Detailed performance analysis
6. **tests.py**: Comprehensive test suite

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 25 | Indexes correctly improve query performance |
| Task 2 | 25 | N+1 problems identified and fixed |
| Task 3 | 25 | Bulk operations significantly faster |
| Task 4 | 25 | Profiling identifies and fixes slow queries |

**Total: 100 points**

## Bonus Challenges (+25 points)

1. **Connection Pooling** (+10 points): Implement and test connection pool tuning
2. **Caching Layer** (+10 points): Add Redis caching for frequent queries
3. **Database Sharding** (+5 points): Implement simple sharding strategy
