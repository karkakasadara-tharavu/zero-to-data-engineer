# Section 05: Advanced ORM Features

## Introduction

SQLAlchemy ORM provides advanced features for complex data modeling, including inheritance patterns, hybrid properties, validators, and event listeners.

## Table Inheritance

### Single Table Inheritance

```python
from sqlalchemy import create_engine, Column, Integer, String, Float
from sqlalchemy.orm import declarative_base, Session

Base = declarative_base()
engine = create_engine('sqlite:///inheritance.db', echo=True)

class Employee(Base):
    __tablename__ = 'employees'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    type = Column(String(20))  # Discriminator column
    
    # Polymorphic identity
    __mapper_args__ = {
        'polymorphic_identity': 'employee',
        'polymorphic_on': type
    }

class Engineer(Employee):
    programming_language = Column(String(50))
    
    __mapper_args__ = {
        'polymorphic_identity': 'engineer'
    }

class Manager(Employee):
    department = Column(String(50))
    
    __mapper_args__ = {
        'polymorphic_identity': 'manager'
    }

Base.metadata.create_all(engine)

# Usage
with Session(engine) as session:
    eng = Engineer(name='Alice', programming_language='Python')
    mgr = Manager(name='Bob', department='Engineering')
    
    session.add_all([eng, mgr])
    session.commit()
    
    # Query returns correct subclass
    employees = session.query(Employee).all()
    for emp in employees:
        print(f"{emp.name} ({emp.type})")
        if isinstance(emp, Engineer):
            print(f"  Language: {emp.programming_language}")
        elif isinstance(emp, Manager):
            print(f"  Department: {emp.department}")
```

### Joined Table Inheritance

```python
class Person(Base):
    __tablename__ = 'persons'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    type = Column(String(20))
    
    __mapper_args__ = {
        'polymorphic_identity': 'person',
        'polymorphic_on': type
    }

class Employee(Person):
    __tablename__ = 'employees'
    
    id = Column(Integer, ForeignKey('persons.id'), primary_key=True)
    employee_id = Column(String(20))
    hire_date = Column(DateTime)
    
    __mapper_args__ = {
        'polymorphic_identity': 'employee'
    }

class Customer(Person):
    __tablename__ = 'customers'
    
    id = Column(Integer, ForeignKey('persons.id'), primary_key=True)
    customer_number = Column(String(20))
    account_balance = Column(Float, default=0.0)
    
    __mapper_args__ = {
        'polymorphic_identity': 'customer'
    }

# Queries join tables automatically
with Session(engine) as session:
    persons = session.query(Person).all()  # Joins employee/customer tables
```

### Concrete Table Inheritance

```python
class BaseVehicle:
    id = Column(Integer, primary_key=True)
    make = Column(String(50))
    model = Column(String(50))
    year = Column(Integer)

class Car(Base, BaseVehicle):
    __tablename__ = 'cars'
    num_doors = Column(Integer)
    
    __mapper_args__ = {
        'concrete': True
    }

class Truck(Base, BaseVehicle):
    __tablename__ = 'trucks'
    bed_length = Column(Float)
    
    __mapper_args__ = {
        'concrete': True
    }
```

## Hybrid Properties

### Basic Hybrid Properties

```python
from sqlalchemy.ext.hybrid import hybrid_property

class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200))
    _price = Column('price', Float)
    tax_rate = Column(Float, default=0.1)
    
    @hybrid_property
    def price(self):
        """Price with tax included"""
        return self._price * (1 + self.tax_rate)
    
    @price.setter
    def price(self, value):
        self._price = value
    
    @price.expression
    def price(cls):
        """Use in queries"""
        return cls._price * (1 + cls.tax_rate)

# Usage - instance level
product = Product(name='Laptop', price=999.99, tax_rate=0.1)
print(f"Price with tax: ${product.price:.2f}")  # Uses Python method

# Usage - query level
with Session(engine) as session:
    expensive = session.query(Product)\
        .filter(Product.price > 1000)\  # Uses SQL expression
        .all()
```

### Advanced Hybrid Properties

```python
from sqlalchemy import func

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    first_name = Column(String(50))
    last_name = Column(String(50))
    birth_date = Column(Date)
    
    @hybrid_property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    @full_name.expression
    def full_name(cls):
        return cls.first_name + ' ' + cls.last_name
    
    @hybrid_property
    def age(self):
        from datetime import date
        today = date.today()
        return today.year - self.birth_date.year
    
    @age.expression
    def age(cls):
        return func.date_part('year', func.age(cls.birth_date))

# Query using hybrid properties
with Session(engine) as session:
    adults = session.query(User)\
        .filter(User.age >= 18)\
        .order_by(User.full_name)\
        .all()
```

## Column Properties and Deferred Loading

```python
from sqlalchemy.orm import column_property, deferred

class Article(Base):
    __tablename__ = 'articles'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(200))
    content = Column(Text)  # Large column
    view_count = Column(Integer, default=0)
    
    # Computed column
    preview = column_property(
        func.substr(content, 1, 100)
    )
    
    # Deferred loading for large columns
    full_content = deferred(Column('content', Text))

# Load article without full_content
with Session(engine) as session:
    article = session.query(Article).first()
    print(article.preview)  # Available
    # article.full_content triggers separate query
```

## Validators

### Column-level Validation

```python
from sqlalchemy.orm import validates

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50))
    email = Column(String(100))
    age = Column(Integer)
    
    @validates('username')
    def validate_username(self, key, username):
        if len(username) < 3:
            raise ValueError("Username must be at least 3 characters")
        if not username.isalnum():
            raise ValueError("Username must be alphanumeric")
        return username.lower()
    
    @validates('email')
    def validate_email(self, key, email):
        if '@' not in email:
            raise ValueError("Invalid email address")
        return email.lower()
    
    @validates('age')
    def validate_age(self, key, age):
        if age < 0 or age > 150:
            raise ValueError("Invalid age")
        return age

# Usage
with Session(engine) as session:
    try:
        user = User(username='ab', email='invalid', age=200)  # Raises ValueError
    except ValueError as e:
        print(f"Validation error: {e}")
    
    user = User(username='Alice123', email='alice@example.com', age=25)
    session.add(user)
    session.commit()
```

### Multiple Column Validation

```python
class PasswordUser(Base):
    __tablename__ = 'password_users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50))
    password_hash = Column(String(128))
    password_confirm = Column(String(128))
    
    @validates('password_hash', 'password_confirm')
    def validate_password(self, key, value):
        if key == 'password_confirm' and hasattr(self, 'password_hash'):
            if value != self.password_hash:
                raise ValueError("Passwords do not match")
        return value
```

## Event Listeners

### Before Insert/Update

```python
from sqlalchemy import event
from datetime import datetime

class AuditedModel(Base):
    __tablename__ = 'audited'
    
    id = Column(Integer, primary_key=True)
    data = Column(String(200))
    created_at = Column(DateTime)
    updated_at = Column(DateTime)
    created_by = Column(String(50))

@event.listens_for(AuditedModel, 'before_insert')
def receive_before_insert(mapper, connection, target):
    target.created_at = datetime.utcnow()
    target.updated_at = datetime.utcnow()

@event.listens_for(AuditedModel, 'before_update')
def receive_before_update(mapper, connection, target):
    target.updated_at = datetime.utcnow()

# Usage
with Session(engine) as session:
    model = AuditedModel(data='Test')
    session.add(model)
    session.commit()  # created_at and updated_at set automatically
    
    model.data = 'Updated'
    session.commit()  # updated_at changed
```

### After Insert/Update/Delete

```python
class LoggedModel(Base):
    __tablename__ = 'logged'
    
    id = Column(Integer, primary_key=True)
    value = Column(String(100))

@event.listens_for(LoggedModel, 'after_insert')
def log_insert(mapper, connection, target):
    print(f"Inserted: {target.value}")

@event.listens_for(LoggedModel, 'after_update')
def log_update(mapper, connection, target):
    print(f"Updated: {target.value}")

@event.listens_for(LoggedModel, 'after_delete')
def log_delete(mapper, connection, target):
    print(f"Deleted: {target.value}")
```

### Connection and Session Events

```python
@event.listens_for(engine, 'connect')
def receive_connect(dbapi_conn, connection_record):
    print("Connected to database")

@event.listens_for(Session, 'after_commit')
def receive_after_commit(session):
    print("Transaction committed")

@event.listens_for(Session, 'after_rollback')
def receive_after_rollback(session):
    print("Transaction rolled back")
```

## Mixins

### Creating Reusable Mixins

```python
from sqlalchemy.ext.declarative import declared_attr
from datetime import datetime

class TimestampMixin:
    """Add created_at and updated_at to any model"""
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class SoftDeleteMixin:
    """Add soft delete capability"""
    
    deleted_at = Column(DateTime)
    
    @hybrid_property
    def is_deleted(self):
        return self.deleted_at is not None
    
    def soft_delete(self):
        self.deleted_at = datetime.utcnow()

class AuditMixin:
    """Add audit fields"""
    
    @declared_attr
    def created_by(cls):
        return Column(String(50))
    
    @declared_attr
    def updated_by(cls):
        return Column(String(50))

# Use mixins
class Product(Base, TimestampMixin, SoftDeleteMixin, AuditMixin):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200))
    price = Column(Float)

# Usage
with Session(engine) as session:
    product = Product(name='Laptop', price=999.99, created_by='admin')
    session.add(product)
    session.commit()
    
    print(f"Created: {product.created_at}")
    
    product.soft_delete()
    session.commit()
    
    print(f"Is deleted: {product.is_deleted}")
```

## Complete Example

```python
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, event
from sqlalchemy.orm import declarative_base, Session, validates, hybrid_property
from sqlalchemy.ext.hybrid import hybrid_property
from datetime import datetime
import hashlib

Base = declarative_base()
engine = create_engine('sqlite:///advanced.db', echo=True)

# Mixins
class TimestampMixin:
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Main model
class User(Base, TimestampMixin):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True)
    email = Column(String(100), unique=True)
    _password_hash = Column('password_hash', String(128))
    first_name = Column(String(50))
    last_name = Column(String(50))
    
    # Validators
    @validates('username')
    def validate_username(self, key, username):
        if len(username) < 3:
            raise ValueError("Username too short")
        return username.lower()
    
    @validates('email')
    def validate_email(self, key, email):
        if '@' not in email:
            raise ValueError("Invalid email")
        return email.lower()
    
    # Hybrid properties
    @hybrid_property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    @hybrid_property
    def password(self):
        raise AttributeError("Password is not readable")
    
    @password.setter
    def password(self, password):
        self._password_hash = hashlib.sha256(password.encode()).hexdigest()
    
    def verify_password(self, password):
        return self._password_hash == hashlib.sha256(password.encode()).hexdigest()
    
    def __repr__(self):
        return f"<User(username='{self.username}')>"

# Event listeners
@event.listens_for(User, 'before_insert')
def log_user_creation(mapper, connection, target):
    print(f"Creating user: {target.username}")

@event.listens_for(User, 'after_insert')
def send_welcome_email(mapper, connection, target):
    print(f"Welcome email would be sent to: {target.email}")

Base.metadata.create_all(engine)

# Usage
with Session(engine) as session:
    # Create user with validation
    user = User(
        username='Alice',
        email='alice@example.com',
        password='secret123',
        first_name='Alice',
        last_name='Johnson'
    )
    
    session.add(user)
    session.commit()
    
    print(f"Created: {user.full_name}")
    print(f"Password valid: {user.verify_password('secret123')}")
    print(f"Timestamps: {user.created_at}, {user.updated_at}")

# Query with hybrid property
with Session(engine) as session:
    users = session.query(User)\
        .filter(User.full_name.like('%John%'))\
        .all()
```

## Summary

Advanced ORM features:
- **Inheritance**: Single table, joined table, concrete table
- **Hybrid Properties**: Computed properties usable in queries
- **Validators**: Automatic data validation
- **Events**: React to model lifecycle changes
- **Mixins**: Reusable model components

**Next**: Section 06 - Query Optimization
