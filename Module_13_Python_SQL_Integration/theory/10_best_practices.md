# Section 10: Best Practices and Design Patterns

## Introduction

This section covers production-ready patterns, security considerations, testing strategies, and architectural best practices for Python-SQL applications.

## Repository Pattern

### Basic Repository

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from typing import List, Optional

class UserRepository:
    """Encapsulate database access for User entity"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return self.session.get(User, user_id)
    
    def get_all(self) -> List[User]:
        """Get all users"""
        return self.session.query(User).all()
    
    def find_by_username(self, username: str) -> Optional[User]:
        """Find user by username"""
        return self.session.query(User)\
            .filter_by(username=username)\
            .first()
    
    def save(self, user: User) -> User:
        """Save user"""
        self.session.add(user)
        self.session.flush()
        return user
    
    def delete(self, user: User) -> None:
        """Delete user"""
        self.session.delete(user)
        self.session.flush()

# Usage
with Session(engine) as session:
    repo = UserRepository(session)
    
    # Create
    user = User(username='alice', email='alice@example.com')
    repo.save(user)
    session.commit()
    
    # Read
    found_user = repo.find_by_username('alice')
    
    # Delete
    repo.delete(found_user)
    session.commit()
```

### Generic Repository

```python
from typing import TypeVar, Generic, Type

T = TypeVar('T')

class GenericRepository(Generic[T]):
    """Generic repository for any model"""
    
    def __init__(self, session: Session, model_class: Type[T]):
        self.session = session
        self.model_class = model_class
    
    def get_by_id(self, id: int) -> Optional[T]:
        return self.session.get(self.model_class, id)
    
    def get_all(self) -> List[T]:
        return self.session.query(self.model_class).all()
    
    def save(self, entity: T) -> T:
        self.session.add(entity)
        self.session.flush()
        return entity
    
    def delete(self, entity: T) -> None:
        self.session.delete(entity)
        self.session.flush()

# Usage
user_repo = GenericRepository[User](session, User)
product_repo = GenericRepository[Product](session, Product)
```

## Unit of Work Pattern

### Implementation

```python
from contextlib import contextmanager

class UnitOfWork:
    """Manage transaction scope"""
    
    def __init__(self, session_factory):
        self.session_factory = session_factory
    
    def __enter__(self):
        self.session = self.session_factory()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            self.session.rollback()
        self.session.close()
    
    def commit(self):
        """Commit transaction"""
        self.session.commit()
    
    def rollback(self):
        """Rollback transaction"""
        self.session.rollback()
    
    @property
    def users(self):
        """User repository"""
        if not hasattr(self, '_users'):
            self._users = UserRepository(self.session)
        return self._users
    
    @property
    def products(self):
        """Product repository"""
        if not hasattr(self, '_products'):
            self._products = ProductRepository(self.session)
        return self._products

# Usage
from sqlalchemy.orm import sessionmaker

SessionFactory = sessionmaker(bind=engine)

def transfer_product_ownership(from_user_id, to_user_id, product_id):
    """Transfer product ownership in single transaction"""
    with UnitOfWork(SessionFactory) as uow:
        from_user = uow.users.get_by_id(from_user_id)
        to_user = uow.users.get_by_id(to_user_id)
        product = uow.products.get_by_id(product_id)
        
        if not all([from_user, to_user, product]):
            raise ValueError("Invalid IDs")
        
        # Business logic
        product.owner_id = to_user_id
        
        uow.commit()
```

## Dependency Injection

### Setup

```python
from dependency_injector import containers, providers
from dependency_injector.wiring import inject, Provide

class Container(containers.DeclarativeContainer):
    """DI Container"""
    
    config = providers.Configuration()
    
    engine = providers.Singleton(
        create_engine,
        config.database.url
    )
    
    session_factory = providers.Factory(
        sessionmaker,
        bind=engine
    )
    
    user_repository = providers.Factory(
        UserRepository,
        session=session_factory
    )

# Usage
@inject
def create_user(
    username: str,
    email: str,
    repo: UserRepository = Provide[Container.user_repository]
):
    """Create user with injected repository"""
    user = User(username=username, email=email)
    return repo.save(user)

# Wire container
container = Container()
container.config.database.url.from_env('DATABASE_URL')
container.wire(modules=[__name__])

# Use
user = create_user('alice', 'alice@example.com')
```

## Security Best Practices

### SQL Injection Prevention

```python
# BAD: String formatting (SQL injection vulnerable)
def get_user_bad(username):
    query = f"SELECT * FROM users WHERE username = '{username}'"
    return session.execute(text(query))

# GOOD: Parameterized queries
def get_user_good(username):
    query = text("SELECT * FROM users WHERE username = :username")
    return session.execute(query, {'username': username})

# GOOD: ORM (automatically parameterized)
def get_user_orm(username):
    return session.query(User).filter_by(username=username).first()
```

### Password Hashing

```python
from passlib.hash import bcrypt
from sqlalchemy import Column, Integer, String

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50))
    password_hash = Column(String(128))
    
    def set_password(self, password: str):
        """Hash and store password"""
        self.password_hash = bcrypt.hash(password)
    
    def verify_password(self, password: str) -> bool:
        """Verify password"""
        return bcrypt.verify(password, self.password_hash)

# Usage
user = User(username='alice')
user.set_password('secret123')

# Verify
if user.verify_password('secret123'):
    print("Login successful")
```

### Connection String Security

```python
import os
from dotenv import load_dotenv

# Load from environment
load_dotenv()

# BAD: Hardcoded credentials
engine = create_engine('postgresql://user:password@localhost/db')

# GOOD: Environment variables
DATABASE_URL = os.getenv('DATABASE_URL')
engine = create_engine(DATABASE_URL)

# GOOD: Separate components
db_config = {
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME')
}

url = f"postgresql://{db_config['user']}:{db_config['password']}@{db_config['host']}:{db_config['port']}/{db_config['database']}"
engine = create_engine(url)
```

### Row-Level Security

```python
from sqlalchemy import event

class TenantMixin:
    """Mixin for multi-tenant models"""
    tenant_id = Column(Integer, nullable=False, index=True)

class Document(Base, TenantMixin):
    __tablename__ = 'documents'
    
    id = Column(Integer, primary_key=True)
    title = Column(String(200))
    content = Column(Text)

# Automatic tenant filtering
@event.listens_for(Session, 'before_compile', retval=True)
def filter_by_tenant(session):
    """Add tenant filter to all queries"""
    if hasattr(session, 'current_tenant_id'):
        def add_tenant_filter(query):
            for desc in query.column_descriptions:
                entity = desc['entity']
                if entity and hasattr(entity, 'tenant_id'):
                    query = query.filter(entity.tenant_id == session.current_tenant_id)
            return query
        
        return add_tenant_filter(session)
    return session

# Usage
session = Session(engine)
session.current_tenant_id = 1  # Set current tenant

# Automatically filters by tenant
documents = session.query(Document).all()
```

## Testing Strategies

### In-Memory Database Testing

```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

@pytest.fixture
def test_engine():
    """Create in-memory SQLite database"""
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)

@pytest.fixture
def test_session(test_engine):
    """Create test session"""
    session = Session(test_engine)
    yield session
    session.close()

def test_create_user(test_session):
    """Test user creation"""
    user = User(username='test', email='test@example.com')
    test_session.add(user)
    test_session.commit()
    
    assert user.id is not None
    assert user.username == 'test'

def test_user_repository(test_session):
    """Test repository"""
    repo = UserRepository(test_session)
    
    user = User(username='alice', email='alice@example.com')
    repo.save(user)
    test_session.commit()
    
    found = repo.find_by_username('alice')
    assert found is not None
    assert found.email == 'alice@example.com'
```

### Mocking Database

```python
from unittest.mock import Mock, MagicMock

def test_service_with_mock():
    """Test service with mocked repository"""
    # Mock repository
    mock_repo = Mock(spec=UserRepository)
    mock_repo.find_by_username.return_value = User(
        id=1,
        username='alice',
        email='alice@example.com'
    )
    
    # Test service
    service = UserService(mock_repo)
    user = service.get_user('alice')
    
    assert user.username == 'alice'
    mock_repo.find_by_username.assert_called_once_with('alice')
```

### Transaction Rollback Testing

```python
@pytest.fixture
def session_rollback(test_engine):
    """Session that rolls back after each test"""
    connection = test_engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()

def test_with_rollback(session_rollback):
    """Test that rolls back changes"""
    user = User(username='temp', email='temp@example.com')
    session_rollback.add(user)
    session_rollback.commit()
    
    assert session_rollback.query(User).count() == 1
    # Automatically rolled back after test
```

## Configuration Management

### Configuration Class

```python
from dataclasses import dataclass
from typing import Optional

@dataclass
class DatabaseConfig:
    """Database configuration"""
    host: str
    port: int
    database: str
    username: str
    password: str
    pool_size: int = 5
    max_overflow: int = 10
    echo: bool = False
    
    @property
    def url(self) -> str:
        """Build connection URL"""
        return f"postgresql://{self.username}:{self.password}@{self.host}:{self.port}/{self.database}"
    
    @classmethod
    def from_env(cls) -> 'DatabaseConfig':
        """Load from environment variables"""
        return cls(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', '5432')),
            database=os.getenv('DB_NAME'),
            username=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            pool_size=int(os.getenv('DB_POOL_SIZE', '5')),
            echo=os.getenv('DB_ECHO', 'false').lower() == 'true'
        )

# Usage
config = DatabaseConfig.from_env()
engine = create_engine(
    config.url,
    pool_size=config.pool_size,
    max_overflow=config.max_overflow,
    echo=config.echo
)
```

### Environment-Specific Configuration

```python
class Config:
    """Base configuration"""
    DEBUG = False
    TESTING = False
    DATABASE_URL = None

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    DATABASE_URL = 'postgresql://dev:dev@localhost/dev_db'

class ProductionConfig(Config):
    """Production configuration"""
    DATABASE_URL = os.getenv('DATABASE_URL')
    POOL_SIZE = 20
    MAX_OVERFLOW = 40

class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DATABASE_URL = 'sqlite:///:memory:'

# Load based on environment
ENV = os.getenv('FLASK_ENV', 'development')
config_map = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig
}
config = config_map[ENV]()
```

## Error Handling

### Custom Exceptions

```python
class DatabaseError(Exception):
    """Base database exception"""
    pass

class EntityNotFoundError(DatabaseError):
    """Entity not found"""
    def __init__(self, entity_type, entity_id):
        self.entity_type = entity_type
        self.entity_id = entity_id
        super().__init__(f"{entity_type} with ID {entity_id} not found")

class DuplicateEntityError(DatabaseError):
    """Duplicate entity"""
    pass

# Usage in repository
class UserRepository:
    def get_by_id(self, user_id: int) -> User:
        user = self.session.get(User, user_id)
        if not user:
            raise EntityNotFoundError('User', user_id)
        return user
    
    def save(self, user: User) -> User:
        try:
            self.session.add(user)
            self.session.flush()
            return user
        except IntegrityError:
            raise DuplicateEntityError(f"User with username '{user.username}' already exists")
```

### Centralized Error Handling

```python
from functools import wraps
import logging

logger = logging.getLogger(__name__)

def handle_db_errors(func):
    """Decorator for database error handling"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except EntityNotFoundError as e:
            logger.warning(f"Entity not found: {e}")
            raise
        except DuplicateEntityError as e:
            logger.warning(f"Duplicate entity: {e}")
            raise
        except OperationalError as e:
            logger.error(f"Database error: {e}")
            raise DatabaseError("Database operation failed")
        except Exception as e:
            logger.exception(f"Unexpected error: {e}")
            raise
    return wrapper

# Usage
@handle_db_errors
def create_user(username, email):
    with UnitOfWork(SessionFactory) as uow:
        user = User(username=username, email=email)
        uow.users.save(user)
        uow.commit()
        return user
```

## Complete Production Example

```python
# config.py
from dataclasses import dataclass
import os

@dataclass
class AppConfig:
    DATABASE_URL: str = os.getenv('DATABASE_URL')
    POOL_SIZE: int = int(os.getenv('DB_POOL_SIZE', '10'))
    DEBUG: bool = os.getenv('DEBUG', 'false').lower() == 'true'

# database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

config = AppConfig()
engine = create_engine(
    config.DATABASE_URL,
    pool_size=config.POOL_SIZE,
    echo=config.DEBUG
)
SessionFactory = sessionmaker(bind=engine)

# repositories.py
class UserRepository:
    def __init__(self, session):
        self.session = session
    
    def get_by_id(self, user_id):
        user = self.session.get(User, user_id)
        if not user:
            raise EntityNotFoundError('User', user_id)
        return user
    
    def create(self, username, email, password):
        user = User(username=username, email=email)
        user.set_password(password)
        self.session.add(user)
        self.session.flush()
        return user

# services.py
class UserService:
    def __init__(self, repository):
        self.repository = repository
    
    @handle_db_errors
    def register_user(self, username, email, password):
        """Register new user"""
        return self.repository.create(username, email, password)
    
    @handle_db_errors
    def authenticate(self, username, password):
        """Authenticate user"""
        user = self.repository.find_by_username(username)
        if user and user.verify_password(password):
            return user
        return None

# main.py
def main():
    with UnitOfWork(SessionFactory) as uow:
        service = UserService(uow.users)
        
        # Register user
        user = service.register_user('alice', 'alice@example.com', 'secret')
        uow.commit()
        
        print(f"User created: {user.username}")

if __name__ == '__main__':
    main()
```

## Summary

Best practices include:
- **Repository Pattern**: Encapsulate data access
- **Unit of Work**: Manage transactions
- **Dependency Injection**: Loose coupling
- **Security**: Prevent SQL injection, hash passwords
- **Testing**: Use in-memory databases, mocks
- **Configuration**: Environment-based settings
- **Error Handling**: Custom exceptions, centralized handling

These patterns create maintainable, secure, and testable applications.

**Module Complete!**
