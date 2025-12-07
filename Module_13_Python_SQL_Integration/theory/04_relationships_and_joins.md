# Section 04: Relationships and Joins

## Introduction

SQLAlchemy ORM relationships allow you to model connections between tables and navigate them as Python object attributes. This section covers all relationship types and loading strategies.

## One-to-Many Relationships

### Basic Setup

```python
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey
from sqlalchemy.orm import declarative_base, relationship, Session

Base = declarative_base()
engine = create_engine('sqlite:///relationships.db', echo=True)

class Author(Base):
    __tablename__ = 'authors'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    
    # Relationship
    books = relationship('Book', back_populates='author')
    
    def __repr__(self):
        return f"<Author(name='{self.name}')>"

class Book(Base):
    __tablename__ = 'books'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(200), nullable=False)
    author_id = Column(Integer, ForeignKey('authors.id'))
    
    # Relationship
    author = relationship('Author', back_populates='books')
    
    def __repr__(self):
        return f"<Book(title='{self.title}')>"

Base.metadata.create_all(engine)
```

### Using the Relationship

```python
with Session(engine) as session:
    # Create author
    author = Author(name='J.K. Rowling')
    
    # Create books
    book1 = Book(title="Harry Potter 1", author=author)
    book2 = Book(title="Harry Potter 2", author=author)
    
    session.add(author)
    session.commit()
    
    # Access books through author
    print(f"{author.name}'s books:")
    for book in author.books:
        print(f"  - {book.title}")
    
    # Access author through book
    print(f"{book1.title} by {book1.author.name}")
```

### Cascade Options

```python
class Author(Base):
    __tablename__ = 'authors'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    # Cascade delete: when author deleted, delete all books
    books = relationship(
        'Book',
        back_populates='author',
        cascade='all, delete-orphan'
    )

# Now deleting author also deletes books
with Session(engine) as session:
    author = session.query(Author).first()
    session.delete(author)  # Also deletes all books
    session.commit()
```

## Many-to-One Relationships

```python
class Department(Base):
    __tablename__ = 'departments'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    employees = relationship('Employee', back_populates='department')

class Employee(Base):
    __tablename__ = 'employees'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    department_id = Column(Integer, ForeignKey('departments.id'))
    
    department = relationship('Department', back_populates='employees')

# Usage
with Session(engine) as session:
    dept = Department(name='Engineering')
    emp1 = Employee(name='Alice', department=dept)
    emp2 = Employee(name='Bob', department=dept)
    
    session.add(dept)
    session.commit()
    
    print(f"{dept.name} department has {len(dept.employees)} employees")
```

## Many-to-Many Relationships

### With Association Table

```python
from sqlalchemy import Table

# Association table
student_course = Table(
    'student_course',
    Base.metadata,
    Column('student_id', Integer, ForeignKey('students.id')),
    Column('course_id', Integer, ForeignKey('courses.id'))
)

class Student(Base):
    __tablename__ = 'students'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    courses = relationship(
        'Course',
        secondary=student_course,
        back_populates='students'
    )

class Course(Base):
    __tablename__ = 'courses'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    students = relationship(
        'Student',
        secondary=student_course,
        back_populates='courses'
    )

# Usage
with Session(engine) as session:
    # Create students
    alice = Student(name='Alice')
    bob = Student(name='Bob')
    
    # Create courses
    math = Course(name='Mathematics')
    physics = Course(name='Physics')
    
    # Enroll students
    alice.courses.extend([math, physics])
    bob.courses.append(math)
    
    session.add_all([alice, bob, math, physics])
    session.commit()
    
    # Query
    student = session.query(Student).filter_by(name='Alice').first()
    print(f"{student.name} is enrolled in:")
    for course in student.courses:
        print(f"  - {course.name}")
```

### With Association Object

```python
from sqlalchemy import DateTime
from datetime import datetime

class Enrollment(Base):
    __tablename__ = 'enrollments'
    
    student_id = Column(Integer, ForeignKey('students.id'), primary_key=True)
    course_id = Column(Integer, ForeignKey('courses.id'), primary_key=True)
    enrolled_date = Column(DateTime, default=datetime.utcnow)
    grade = Column(String(2))
    
    # Relationships
    student = relationship('Student', back_populates='enrollments')
    course = relationship('Course', back_populates='enrollments')

class Student(Base):
    __tablename__ = 'students'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    enrollments = relationship('Enrollment', back_populates='student')

class Course(Base):
    __tablename__ = 'courses'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    enrollments = relationship('Enrollment', back_populates='course')

# Usage
with Session(engine) as session:
    alice = Student(name='Alice')
    math = Course(name='Mathematics')
    
    enrollment = Enrollment(
        student=alice,
        course=math,
        grade='A'
    )
    
    session.add(enrollment)
    session.commit()
    
    # Query with association data
    for enrollment in alice.enrollments:
        print(f"{enrollment.course.name}: Grade {enrollment.grade}")
```

## One-to-One Relationships

```python
class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True)
    
    # uselist=False makes it one-to-one
    profile = relationship('Profile', back_populates='user', uselist=False)

class Profile(Base):
    __tablename__ = 'profiles'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), unique=True)
    bio = Column(Text)
    avatar_url = Column(String(200))
    
    user = relationship('User', back_populates='profile')

# Usage
with Session(engine) as session:
    user = User(username='alice')
    profile = Profile(bio='Software Engineer', user=user)
    
    session.add(user)
    session.commit()
    
    # Access profile
    print(f"{user.username}'s bio: {user.profile.bio}")
```

## Loading Strategies

### Lazy Loading (Default)

```python
# Relationships loaded when accessed
with Session(engine) as session:
    author = session.query(Author).first()
    # No query for books yet
    
    for book in author.books:  # Query executed here
        print(book.title)
```

### Eager Loading - Joined Load

```python
from sqlalchemy.orm import joinedload

with Session(engine) as session:
    # Load authors with books in single query using JOIN
    authors = session.query(Author)\
        .options(joinedload(Author.books))\
        .all()
    
    for author in authors:
        for book in author.books:  # No additional query
            print(f"{author.name}: {book.title}")
```

### Eager Loading - Subquery Load

```python
from sqlalchemy.orm import subqueryload

with Session(engine) as session:
    # Load authors, then books in separate query
    authors = session.query(Author)\
        .options(subqueryload(Author.books))\
        .all()
    
    for author in authors:
        for book in author.books:  # No additional query
            print(f"{author.name}: {book.title}")
```

### Select IN Loading

```python
from sqlalchemy.orm import selectinload

with Session(engine) as session:
    # Modern approach: load related in separate query using IN
    authors = session.query(Author)\
        .options(selectinload(Author.books))\
        .all()
    
    for author in authors:
        for book in author.books:
            print(f"{author.name}: {book.title}")
```

### No Loading

```python
from sqlalchemy.orm import noload

with Session(engine) as session:
    # Don't load books at all
    authors = session.query(Author)\
        .options(noload(Author.books))\
        .all()
```

## Complex Joins

### Multiple Relationships

```python
class Company(Base):
    __tablename__ = 'companies'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    employees = relationship('Employee', back_populates='company')

class Employee(Base):
    __tablename__ = 'employees'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    company_id = Column(Integer, ForeignKey('companies.id'))
    
    company = relationship('Company', back_populates='employees')
    projects = relationship('Project', secondary='employee_project', back_populates='employees')

class Project(Base):
    __tablename__ = 'projects'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    
    employees = relationship('Employee', secondary='employee_project', back_populates='projects')

# Query with multiple joins
with Session(engine) as session:
    results = session.query(Company, Employee, Project)\
        .join(Employee)\
        .join(Project, Employee.projects)\
        .all()
```

### Self-Referential Relationships

```python
class TreeNode(Base):
    __tablename__ = 'tree_nodes'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(50))
    parent_id = Column(Integer, ForeignKey('tree_nodes.id'))
    
    # Self-referential relationship
    children = relationship('TreeNode', back_populates='parent')
    parent = relationship('TreeNode', back_populates='children', remote_side=[id])

# Usage
with Session(engine) as session:
    root = TreeNode(name='Root')
    child1 = TreeNode(name='Child 1', parent=root)
    child2 = TreeNode(name='Child 2', parent=root)
    grandchild = TreeNode(name='Grandchild', parent=child1)
    
    session.add(root)
    session.commit()
    
    # Navigate tree
    for child in root.children:
        print(f"  {child.name}")
        for grandchild in child.children:
            print(f"    {grandchild.name}")
```

## Complete Example

```python
from sqlalchemy import create_engine, Column, Integer, String, Float, ForeignKey, Table, DateTime
from sqlalchemy.orm import declarative_base, relationship, Session, selectinload
from datetime import datetime

Base = declarative_base()
engine = create_engine('sqlite:///ecommerce.db', echo=True)

# Many-to-many association
order_product = Table(
    'order_product',
    Base.metadata,
    Column('order_id', Integer, ForeignKey('orders.id')),
    Column('product_id', Integer, ForeignKey('products.id')),
    Column('quantity', Integer, default=1)
)

class Customer(Base):
    __tablename__ = 'customers'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    email = Column(String(100), unique=True)
    
    orders = relationship('Order', back_populates='customer', cascade='all, delete-orphan')

class Order(Base):
    __tablename__ = 'orders'
    
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey('customers.id'))
    order_date = Column(DateTime, default=datetime.utcnow)
    
    customer = relationship('Customer', back_populates='orders')
    products = relationship('Product', secondary=order_product, back_populates='orders')

class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200))
    price = Column(Float)
    
    orders = relationship('Order', secondary=order_product, back_populates='products')

Base.metadata.create_all(engine)

# Populate database
with Session(engine) as session:
    # Create customers
    alice = Customer(name='Alice', email='alice@example.com')
    bob = Customer(name='Bob', email='bob@example.com')
    
    # Create products
    laptop = Product(name='Laptop', price=999.99)
    mouse = Product(name='Mouse', price=29.99)
    keyboard = Product(name='Keyboard', price=79.99)
    
    # Create orders
    order1 = Order(customer=alice)
    order1.products.extend([laptop, mouse])
    
    order2 = Order(customer=bob)
    order2.products.append(keyboard)
    
    session.add_all([alice, bob, order1, order2])
    session.commit()

# Query with eager loading
with Session(engine) as session:
    customers = session.query(Customer)\
        .options(
            selectinload(Customer.orders)
            .selectinload(Order.products)
        )\
        .all()
    
    for customer in customers:
        print(f"\n{customer.name}'s orders:")
        for order in customer.orders:
            total = sum(p.price for p in order.products)
            print(f"  Order {order.id} (${total:.2f}):")
            for product in order.products:
                print(f"    - {product.name}: ${product.price}")
```

## Summary

- One-to-Many: Most common, uses `relationship()` and `ForeignKey`
- Many-to-Many: Uses association table or object
- One-to-One: Uses `uselist=False`
- Loading strategies optimize query performance
- Use `selectinload` for modern eager loading

**Next**: Section 05 - Advanced ORM Features
