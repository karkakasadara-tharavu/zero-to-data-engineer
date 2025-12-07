# Section 06: Query Optimization

## Introduction

Query optimization is crucial for application performance. This section covers techniques to analyze, optimize, and tune SQLAlchemy queries.

## Query Analysis with EXPLAIN

### Basic EXPLAIN

```python
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

engine = create_engine('postgresql://user:pass@localhost/db', echo=True)

# Raw SQL EXPLAIN
with engine.connect() as conn:
    result = conn.execute(text("EXPLAIN SELECT * FROM users WHERE age > 25"))
    for row in result:
        print(row)

# EXPLAIN ANALYZE (PostgreSQL)
with engine.connect() as conn:
    result = conn.execute(text("EXPLAIN ANALYZE SELECT * FROM users WHERE age > 25"))
    for row in result:
        print(row)
```

### EXPLAIN with SQLAlchemy Queries

```python
from sqlalchemy import select

stmt = select(User).where(User.age > 25)

# Get query as string
query_str = str(stmt.compile(engine))
print(f"Query: {query_str}")

# Execute EXPLAIN
with Session(engine) as session:
    explain_stmt = text(f"EXPLAIN {query_str}")
    result = session.execute(explain_stmt)
    for row in result:
        print(row)
```

## Indexes

### Creating Indexes

```python
from sqlalchemy import Index, Column, Integer, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), index=True)  # Simple index
    email = Column(String(100), unique=True)    # Unique index
    age = Column(Integer)
    city = Column(String(50))
    
    # Composite index
    __table_args__ = (
        Index('idx_age_city', 'age', 'city'),
    )

# Functional index (PostgreSQL)
class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200))
    
    __table_args__ = (
        Index('idx_lower_name', func.lower(name)),
    )
```

### Index Usage Examples

```python
# Without index - full table scan
stmt = select(User).where(User.email == 'user@example.com')

# With index on email - index scan
stmt = select(User).where(User.email == 'user@example.com')

# Composite index used
stmt = select(User).where(
    (User.age > 25) & (User.city == 'New York')
)

# Prefix of composite index used
stmt = select(User).where(User.age > 25)

# Index not used - function on indexed column
stmt = select(User).where(func.lower(User.username) == 'john')

# Index used - functional index
stmt = select(Product).where(func.lower(Product.name) == 'laptop')
```

## N+1 Query Problem

### The Problem

```python
# Bad: N+1 queries
with Session(engine) as session:
    authors = session.query(Author).all()  # 1 query
    
    for author in authors:
        for book in author.books:  # N queries (one per author)
            print(f"{author.name}: {book.title}")
```

### Solution 1: Eager Loading with joinedload

```python
from sqlalchemy.orm import joinedload

# Good: 1 query with JOIN
with Session(engine) as session:
    authors = session.query(Author)\
        .options(joinedload(Author.books))\
        .all()  # Single query with JOIN
    
    for author in authors:
        for book in author.books:  # No additional queries
            print(f"{author.name}: {book.title}")
```

### Solution 2: selectinload

```python
from sqlalchemy.orm import selectinload

# Good: 2 queries (modern approach)
with Session(engine) as session:
    authors = session.query(Author)\
        .options(selectinload(Author.books))\
        .all()  # 1 query for authors, 1 query for all books
    
    for author in authors:
        for book in author.books:
            print(f"{author.name}: {book.title}")
```

### Solution 3: subqueryload

```python
from sqlalchemy.orm import subqueryload

# Good: 2 queries with subquery
with Session(engine) as session:
    authors = session.query(Author)\
        .options(subqueryload(Author.books))\
        .all()
    
    for author in authors:
        for book in author.books:
            print(f"{author.name}: {book.title}")
```

### Nested Relationships

```python
# Load author -> books -> reviews
with Session(engine) as session:
    authors = session.query(Author)\
        .options(
            selectinload(Author.books)
            .selectinload(Book.reviews)
        )\
        .all()
```

## Batch Operations

### Bulk Insert

```python
# Method 1: bulk_insert_mappings (fast, no ORM overhead)
with Session(engine) as session:
    session.bulk_insert_mappings(
        User,
        [
            {'username': 'user1', 'email': 'user1@example.com'},
            {'username': 'user2', 'email': 'user2@example.com'},
            {'username': 'user3', 'email': 'user3@example.com'}
        ]
    )
    session.commit()

# Method 2: add_all (ORM features available)
with Session(engine) as session:
    users = [
        User(username='user1', email='user1@example.com'),
        User(username='user2', 'email': 'user2@example.com'),
        User(username='user3', email='user3@example.com')
    ]
    session.add_all(users)
    session.commit()
```

### Bulk Update

```python
# Method 1: bulk_update_mappings
with Session(engine) as session:
    session.bulk_update_mappings(
        User,
        [
            {'id': 1, 'email': 'new1@example.com'},
            {'id': 2, 'email': 'new2@example.com'},
            {'id': 3, 'email': 'new3@example.com'}
        ]
    )
    session.commit()

# Method 2: Update query
with Session(engine) as session:
    session.query(User)\
        .filter(User.age < 18)\
        .update({'is_minor': True})
    session.commit()
```

### Chunked Processing

```python
# Process large dataset in chunks
def process_users_in_chunks(session, chunk_size=1000):
    offset = 0
    while True:
        users = session.query(User)\
            .limit(chunk_size)\
            .offset(offset)\
            .all()
        
        if not users:
            break
        
        for user in users:
            # Process user
            user.processed = True
        
        session.commit()
        offset += chunk_size
```

## Query Optimization Techniques

### Select Only Needed Columns

```python
# Bad: Select all columns
users = session.query(User).all()

# Good: Select specific columns
users = session.query(User.id, User.username, User.email).all()

# Or with load_only
from sqlalchemy.orm import load_only

users = session.query(User)\
    .options(load_only(User.id, User.username, User.email))\
    .all()
```

### Deferred Column Loading

```python
from sqlalchemy.orm import deferred

class Article(Base):
    __tablename__ = 'articles'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(200))
    content = deferred(Column(Text))  # Load only when accessed
    image_data = deferred(Column(LargeBinary))

# Query loads everything except deferred columns
articles = session.query(Article).all()

# Access triggers separate query
first_article_content = articles[0].content
```

### Query Result Caching

```python
from sqlalchemy.orm import query

# Enable result caching
stmt = select(User).where(User.age > 25).execution_options(
    compiled_cache={}
)

# Manual caching with dictionary
cache = {}

def get_user_by_id(session, user_id):
    if user_id in cache:
        return cache[user_id]
    
    user = session.get(User, user_id)
    cache[user_id] = user
    return user
```

### Limit Result Sets

```python
# Pagination
page = 1
page_size = 20
offset = (page - 1) * page_size

users = session.query(User)\
    .limit(page_size)\
    .offset(offset)\
    .all()

# With total count
from sqlalchemy import func

total = session.query(func.count(User.id)).scalar()
users = session.query(User)\
    .limit(page_size)\
    .offset(offset)\
    .all()

print(f"Page {page} of {(total + page_size - 1) // page_size}")
```

## Query Execution Plans

### Analyzing Slow Queries

```python
import time
from sqlalchemy import event

# Log slow queries
@event.listens_for(engine, 'before_cursor_execute')
def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    context._query_start_time = time.time()

@event.listens_for(engine, 'after_cursor_execute')
def receive_after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total_time = time.time() - context._query_start_time
    if total_time > 1.0:  # Log queries taking more than 1 second
        print(f"Slow query ({total_time:.2f}s): {statement}")
```

### Query Profiling

```python
from sqlalchemy import inspect
from sqlalchemy.orm import Query

def profile_query(query):
    """Print query execution plan"""
    compiled = query.statement.compile(engine)
    print(f"SQL: {compiled}")
    print(f"Parameters: {compiled.params}")
    
    # Execute EXPLAIN
    explain_query = f"EXPLAIN {compiled}"
    result = engine.execute(text(explain_query))
    print("\nExecution Plan:")
    for row in result:
        print(row)

# Usage
query = session.query(User).filter(User.age > 25)
profile_query(query)
```

## Complete Example

```python
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, Index, func, event, text
from sqlalchemy.orm import declarative_base, Session, relationship, selectinload
import time

Base = declarative_base()
engine = create_engine('postgresql://user:pass@localhost/db')

# Models with indexes
class Author(Base):
    __tablename__ = 'authors'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), index=True)
    country = Column(String(50))
    
    books = relationship('Book', back_populates='author')
    
    __table_args__ = (
        Index('idx_name_country', 'name', 'country'),
    )

class Book(Base):
    __tablename__ = 'books'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(200), index=True)
    author_id = Column(Integer, ForeignKey('authors.id'), index=True)
    year = Column(Integer)
    
    author = relationship('Author', back_populates='books')

Base.metadata.create_all(engine)

# Query performance monitoring
@event.listens_for(engine, 'before_cursor_execute')
def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    context._query_start_time = time.time()

@event.listens_for(engine, 'after_cursor_execute')
def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - context._query_start_time
    if total > 0.1:
        print(f"Slow query ({total:.3f}s)")

# Populate data
with Session(engine) as session:
    # Bulk insert
    authors_data = [
        {'name': f'Author {i}', 'country': 'USA' if i % 2 == 0 else 'UK'}
        for i in range(1000)
    ]
    session.bulk_insert_mappings(Author, authors_data)
    session.commit()

# Bad: N+1 problem
print("N+1 Problem:")
with Session(engine) as session:
    authors = session.query(Author).limit(10).all()
    for author in authors:
        print(f"{author.name}: {len(author.books)} books")  # Triggers N queries

# Good: Eager loading
print("\nOptimized with selectinload:")
with Session(engine) as session:
    authors = session.query(Author)\
        .options(selectinload(Author.books))\
        .limit(10)\
        .all()
    
    for author in authors:
        print(f"{author.name}: {len(author.books)} books")  # No extra queries

# Efficient pagination
def get_authors_page(page, page_size=20):
    with Session(engine) as session:
        total = session.query(func.count(Author.id)).scalar()
        
        authors = session.query(Author)\
            .order_by(Author.name)\
            .limit(page_size)\
            .offset((page - 1) * page_size)\
            .all()
        
        return authors, total

authors, total = get_authors_page(1)
print(f"\nPage 1: {len(authors)} authors of {total} total")
```

## Summary

Key optimization techniques:
- Use EXPLAIN to analyze queries
- Create appropriate indexes
- Avoid N+1 queries with eager loading
- Use bulk operations for large datasets
- Select only needed columns
- Implement pagination
- Monitor and profile slow queries

**Next**: Section 07 - Transactions and Concurrency
