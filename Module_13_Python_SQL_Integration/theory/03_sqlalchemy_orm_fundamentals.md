# Section 03: SQLAlchemy ORM Fundamentals

## Introduction

The SQLAlchemy ORM (Object-Relational Mapper) allows you to map Python classes to database tables and work with database records as Python objects. This provides a more intuitive and Pythonic way to interact with databases.

## Declarative Base

### Setting Up

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, Session

# Create engine
engine = create_engine('sqlite:///myapp.db', echo=True)

# Create declarative base
Base = declarative_base()

# Now you can define models
```

### Modern SQLAlchemy 2.0+ Style

```python
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass

# All models inherit from this base
```

## Defining Models

### Basic Model

```python
from sqlalchemy import Column, Integer, String, Float, DateTime
from datetime import datetime

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<User(username='{self.username}', email='{self.email}')>"

# Create tables
Base.metadata.create_all(engine)
```

### Multiple Models

```python
from sqlalchemy import ForeignKey

class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    price = Column(Float, nullable=False)
    stock = Column(Integer, default=0)
    
    def __repr__(self):
        return f"<Product(name='{self.name}', price={self.price})>"

class Order(Base):
    __tablename__ = 'orders'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    product_id = Column(Integer, ForeignKey('products.id'), nullable=False)
    quantity = Column(Integer, nullable=False)
    order_date = Column(DateTime, default=datetime.utcnow)
    status = Column(String(20), default='pending')
    
    def __repr__(self):
        return f"<Order(id={self.id}, user_id={self.user_id}, status='{self.status}')>"
```

### Column Options

```python
class AdvancedUser(Base):
    __tablename__ = 'advanced_users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    password_hash = Column(String(128), nullable=False)
    is_active = Column(Boolean, default=True)
    login_count = Column(Integer, default=0)
    last_login = Column(DateTime, onupdate=datetime.utcnow)
    
    # Server default (executed by database)
    created_at = Column(DateTime, server_default=func.now())
```

## Session Management

### Creating Sessions

```python
from sqlalchemy.orm import sessionmaker

# Create session factory
SessionLocal = sessionmaker(bind=engine)

# Create session instance
session = SessionLocal()

# Use the session
try:
    # Perform database operations
    pass
finally:
    session.close()
```

### Session Context Manager

```python
# Using context manager (recommended)
with Session(engine) as session:
    # Perform operations
    user = session.query(User).first()
    print(user.username)
    # Session automatically closed

# With explicit commit
with Session(engine) as session:
    user = User(username='john', email='john@example.com')
    session.add(user)
    session.commit()
```

### Scoped Sessions

```python
from sqlalchemy.orm import scoped_session

# Thread-local session
SessionLocal = scoped_session(sessionmaker(bind=engine))

def get_session():
    return SessionLocal()

# Use in different parts of application
session = get_session()
# ... operations ...
SessionLocal.remove()  # Clean up
```

## CRUD Operations

### Create (INSERT)

```python
# Single object
with Session(engine) as session:
    user = User(username='alice', email='alice@example.com')
    session.add(user)
    session.commit()
    
    # Access the ID after commit
    print(f"Created user with ID: {user.id}")

# Multiple objects
with Session(engine) as session:
    users = [
        User(username='bob', email='bob@example.com'),
        User(username='carol', email='carol@example.com'),
        User(username='dave', email='dave@example.com')
    ]
    session.add_all(users)
    session.commit()

# Bulk insert (more efficient)
with Session(engine) as session:
    session.bulk_insert_mappings(User, [
        {'username': 'user1', 'email': 'user1@example.com'},
        {'username': 'user2', 'email': 'user2@example.com'},
        {'username': 'user3', 'email': 'user3@example.com'}
    ])
    session.commit()
```

### Read (SELECT)

```python
with Session(engine) as session:
    # Get all
    users = session.query(User).all()
    
    # Get first
    user = session.query(User).first()
    
    # Get by primary key
    user = session.get(User, 1)
    
    # Filter
    user = session.query(User).filter_by(username='alice').first()
    
    # Filter with expressions
    from sqlalchemy import and_, or_
    users = session.query(User).filter(
        and_(
            User.username.like('a%'),
            User.created_at > datetime(2024, 1, 1)
        )
    ).all()
    
    # Count
    count = session.query(User).count()
    
    # Limit and offset
    users = session.query(User).limit(10).offset(20).all()
    
    # Order by
    users = session.query(User).order_by(User.created_at.desc()).all()
```

### Update (UPDATE)

```python
# Method 1: Query and modify
with Session(engine) as session:
    user = session.query(User).filter_by(username='alice').first()
    if user:
        user.email = 'newemail@example.com'
        session.commit()

# Method 2: Bulk update
with Session(engine) as session:
    session.query(User).filter(
        User.username.like('test%')
    ).update({'is_active': False})
    session.commit()

# Method 3: Update with expressions
with Session(engine) as session:
    session.query(Product).filter(
        Product.stock < 10
    ).update({Product.stock: Product.stock + 50})
    session.commit()
```

### Delete (DELETE)

```python
# Method 1: Get and delete
with Session(engine) as session:
    user = session.query(User).filter_by(username='old_user').first()
    if user:
        session.delete(user)
        session.commit()

# Method 2: Bulk delete
with Session(engine) as session:
    session.query(User).filter(
        User.created_at < datetime(2020, 1, 1)
    ).delete()
    session.commit()
```

## Query API

### Basic Queries

```python
with Session(engine) as session:
    # Select all columns
    users = session.query(User).all()
    
    # Select specific columns
    results = session.query(User.username, User.email).all()
    for username, email in results:
        print(f"{username}: {email}")
    
    # Select with label
    results = session.query(
        User.username.label('name'),
        User.email
    ).all()
```

### Filtering

```python
with Session(engine) as session:
    # Equality
    users = session.query(User).filter(User.username == 'alice').all()
    
    # Inequality
    users = session.query(User).filter(User.id != 1).all()
    
    # Comparison
    users = session.query(User).filter(User.id > 10).all()
    
    # IN
    users = session.query(User).filter(User.username.in_(['alice', 'bob'])).all()
    
    # LIKE
    users = session.query(User).filter(User.username.like('a%')).all()
    
    # IS NULL
    users = session.query(User).filter(User.email == None).all()
    
    # AND
    users = session.query(User).filter(
        User.username == 'alice',
        User.is_active == True
    ).all()
    
    # OR
    from sqlalchemy import or_
    users = session.query(User).filter(
        or_(User.username == 'alice', User.username == 'bob')
    ).all()
```

### Aggregation

```python
from sqlalchemy import func

with Session(engine) as session:
    # Count
    count = session.query(func.count(User.id)).scalar()
    
    # Sum
    total_stock = session.query(func.sum(Product.stock)).scalar()
    
    # Average
    avg_price = session.query(func.avg(Product.price)).scalar()
    
    # Min/Max
    min_price = session.query(func.min(Product.price)).scalar()
    max_price = session.query(func.max(Product.price)).scalar()
    
    # Group by
    results = session.query(
        User.username,
        func.count(Order.id).label('order_count')
    ).join(Order).group_by(User.username).all()
```

### Joins

```python
with Session(engine) as session:
    # Inner join
    results = session.query(User, Order).join(Order).all()
    
    # Left outer join
    results = session.query(User, Order).outerjoin(Order).all()
    
    # Multiple joins
    results = session.query(User, Order, Product)\
        .join(Order)\
        .join(Product)\
        .all()
    
    # Explicit join condition
    results = session.query(User, Order).join(
        Order,
        User.id == Order.user_id
    ).all()
```

## Complete Example

```python
from sqlalchemy import create_engine, Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base, Session, relationship
from datetime import datetime

# Setup
engine = create_engine('sqlite:///store.db', echo=True)
Base = declarative_base()

# Models
class Customer(Base):
    __tablename__ = 'customers'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<Customer(name='{self.name}')>"

class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    price = Column(Float, nullable=False)
    stock = Column(Integer, default=0)
    
    def __repr__(self):
        return f"<Product(name='{self.name}', price={self.price})>"

class Sale(Base):
    __tablename__ = 'sales'
    
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey('customers.id'))
    product_id = Column(Integer, ForeignKey('products.id'))
    quantity = Column(Integer, nullable=False)
    sale_date = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<Sale(id={self.id}, quantity={self.quantity})>"

# Create tables
Base.metadata.create_all(engine)

# CRUD operations
with Session(engine) as session:
    # Create customers
    customers = [
        Customer(name='Alice Johnson', email='alice@example.com'),
        Customer(name='Bob Smith', email='bob@example.com'),
        Customer(name='Carol White', email='carol@example.com')
    ]
    session.add_all(customers)
    session.commit()
    
    # Create products
    products = [
        Product(name='Laptop', price=999.99, stock=10),
        Product(name='Mouse', price=29.99, stock=50),
        Product(name='Keyboard', price=79.99, stock=30)
    ]
    session.add_all(products)
    session.commit()
    
    # Create sales
    sales = [
        Sale(customer_id=1, product_id=1, quantity=1),
        Sale(customer_id=2, product_id=2, quantity=2),
        Sale(customer_id=1, product_id=3, quantity=1)
    ]
    session.add_all(sales)
    session.commit()

# Query examples
with Session(engine) as session:
    # Get all customers
    customers = session.query(Customer).all()
    print("All customers:")
    for customer in customers:
        print(f"  {customer.name} - {customer.email}")
    
    # Get products with low stock
    low_stock = session.query(Product).filter(Product.stock < 20).all()
    print("\nLow stock products:")
    for product in low_stock:
        print(f"  {product.name}: {product.stock} units")
    
    # Get customer with most sales
    from sqlalchemy import func
    result = session.query(
        Customer.name,
        func.count(Sale.id).label('sale_count')
    ).join(Sale).group_by(Customer.name)\
     .order_by(func.count(Sale.id).desc())\
     .first()
    
    print(f"\nTop customer: {result.name} with {result.sale_count} sales")

# Update example
with Session(engine) as session:
    product = session.query(Product).filter_by(name='Laptop').first()
    product.price = 899.99
    product.stock -= 1
    session.commit()
    print(f"\nUpdated {product.name}: ${product.price}, stock: {product.stock}")

# Delete example
with Session(engine) as session:
    old_sales = session.query(Sale).filter(
        Sale.sale_date < datetime(2024, 1, 1)
    ).delete()
    session.commit()
    print(f"\nDeleted {old_sales} old sales")
```

## Summary

SQLAlchemy ORM provides:
- Pythonic database interaction
- Automatic SQL generation
- Session management
- Type safety
- Relationship handling (covered in next section)

**Next**: Section 04 - Relationships and Joins
