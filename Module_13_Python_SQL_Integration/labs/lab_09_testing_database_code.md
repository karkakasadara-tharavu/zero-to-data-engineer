# Lab 09: Testing Database Code

## Learning Objectives

- Write unit tests for database operations
- Use in-memory databases for testing
- Mock database connections and queries
- Test transactions and rollbacks
- Measure test coverage

## Prerequisites

- pytest or unittest
- SQLAlchemy ORM
- Understanding of testing principles
- Completion of Labs 01-08

## Tasks

### Task 1: Unit Testing with In-Memory Database (25 points)

Use SQLite in-memory database for fast, isolated tests.

**Requirements:**
```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from models import Base, User, Product, Order

@pytest.fixture(scope='function')
def engine():
    """Create in-memory database for each test"""
    engine = create_engine('sqlite:///:memory:', echo=False)
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()

@pytest.fixture(scope='function')
def session(engine):
    """Create session for each test"""
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    yield session
    session.rollback()
    session.close()

@pytest.fixture(scope='function')
def sample_user(session):
    """Create sample user for tests"""
    user = User(
        username='testuser',
        email='test@example.com',
        password_hash='hashed_password'
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

class TestUserModel:
    """Test User model"""
    
    def test_create_user(self, session):
        """Test user creation"""
        user = User(
            username='newuser',
            email='new@example.com',
            password_hash='hash'
        )
        session.add(user)
        session.commit()
        
        assert user.id is not None
        assert user.username == 'newuser'
        assert user.is_active is True
    
    def test_unique_username(self, session, sample_user):
        """Test username uniqueness constraint"""
        duplicate_user = User(
            username='testuser',  # Same as sample_user
            email='different@example.com',
            password_hash='hash'
        )
        session.add(duplicate_user)
        
        with pytest.raises(Exception):  # IntegrityError
            session.commit()
    
    def test_user_relationships(self, session, sample_user):
        """Test user-order relationship"""
        order = Order(
            user_id=sample_user.id,
            status='pending',
            total_amount=100.0
        )
        session.add(order)
        session.commit()
        
        assert len(sample_user.orders) == 1
        assert sample_user.orders[0].status == 'pending'

class TestProductModel:
    """Test Product model"""
    
    @pytest.fixture
    def sample_product(self, session):
        """Create sample product"""
        product = Product(
            name='Test Product',
            description='Description',
            price=29.99,
            stock=100
        )
        session.add(product)
        session.commit()
        session.refresh(product)
        return product
    
    def test_create_product(self, session):
        """Test product creation"""
        product = Product(
            name='New Product',
            price=19.99,
            stock=50
        )
        session.add(product)
        session.commit()
        
        assert product.id is not None
        assert product.stock == 50
    
    def test_price_validation(self, session):
        """Test price must be positive"""
        # TODO: Add price validation to model
        # This test should fail until validation added
        product = Product(
            name='Invalid Product',
            price=-10.0,  # Invalid
            stock=10
        )
        session.add(product)
        
        with pytest.raises(ValueError):
            session.commit()
    
    def test_stock_update(self, session, sample_product):
        """Test stock updates"""
        initial_stock = sample_product.stock
        
        # Decrease stock
        sample_product.stock -= 5
        session.commit()
        
        # Verify
        product = session.query(Product).filter_by(id=sample_product.id).first()
        assert product.stock == initial_stock - 5
```

### Task 2: Testing Repository Pattern (25 points)

Test repository implementations with proper isolation.

**Requirements:**
```python
from repositories import UserRepository, ProductRepository

class TestUserRepository:
    """Test UserRepository"""
    
    @pytest.fixture
    def repo(self, session):
        """Create repository instance"""
        return UserRepository(session)
    
    def test_create(self, repo):
        """Test create method"""
        user = repo.create(
            username='testuser',
            email='test@example.com',
            password='password123'
        )
        
        assert user.id is not None
        assert user.username == 'testuser'
        assert user.password_hash != 'password123'  # Should be hashed
    
    def test_get_by_id(self, repo, sample_user):
        """Test get by ID"""
        user = repo.get_by_id(sample_user.id)
        
        assert user is not None
        assert user.id == sample_user.id
        assert user.username == sample_user.username
    
    def test_get_by_username(self, repo, sample_user):
        """Test get by username"""
        user = repo.get_by_username('testuser')
        
        assert user is not None
        assert user.id == sample_user.id
    
    def test_get_by_username_not_found(self, repo):
        """Test get non-existent user"""
        user = repo.get_by_username('nonexistent')
        
        assert user is None
    
    def test_list_all(self, repo, session):
        """Test list all users"""
        # Create multiple users
        for i in range(5):
            user = User(
                username=f'user{i}',
                email=f'user{i}@example.com',
                password_hash='hash'
            )
            session.add(user)
        session.commit()
        
        users = repo.list_all()
        
        assert len(users) == 5
    
    def test_update(self, repo, sample_user):
        """Test update user"""
        repo.update(sample_user.id, email='newemail@example.com')
        
        updated_user = repo.get_by_id(sample_user.id)
        assert updated_user.email == 'newemail@example.com'
    
    def test_delete(self, repo, sample_user):
        """Test delete user"""
        user_id = sample_user.id
        
        repo.delete(user_id)
        
        deleted_user = repo.get_by_id(user_id)
        assert deleted_user is None

class TestProductRepository:
    """Test ProductRepository"""
    
    @pytest.fixture
    def repo(self, session):
        return ProductRepository(session)
    
    def test_find_by_category(self, repo, session):
        """Test finding products by category"""
        # Create products in different categories
        products_data = [
            ('Electronics', 'Laptop'),
            ('Electronics', 'Phone'),
            ('Books', 'Python Book'),
            ('Books', 'SQL Book')
        ]
        
        for category, name in products_data:
            product = Product(
                name=name,
                category=category,
                price=100.0,
                stock=10
            )
            session.add(product)
        session.commit()
        
        # Find electronics
        electronics = repo.find_by_category('Electronics')
        
        assert len(electronics) == 2
        assert all(p.category == 'Electronics' for p in electronics)
    
    def test_low_stock_products(self, repo, session):
        """Test finding low stock products"""
        # Create products with varying stock
        for i in range(5):
            product = Product(
                name=f'Product {i}',
                price=10.0,
                stock=i * 5  # 0, 5, 10, 15, 20
            )
            session.add(product)
        session.commit()
        
        # Find products with stock < 10
        low_stock = repo.find_low_stock(threshold=10)
        
        assert len(low_stock) == 2  # Stock 0 and 5
```

### Task 3: Testing Transactions and Rollbacks (25 points)

Test transaction handling and rollback behavior.

**Requirements:**
```python
class TestTransactions:
    """Test transaction behavior"""
    
    def test_commit_success(self, session):
        """Test successful commit"""
        user = User(
            username='commituser',
            email='commit@example.com',
            password_hash='hash'
        )
        session.add(user)
        session.commit()
        
        # Verify in new session
        user_check = session.query(User).filter_by(username='commituser').first()
        assert user_check is not None
    
    def test_rollback_on_error(self, session):
        """Test rollback on error"""
        user1 = User(
            username='user1',
            email='user1@example.com',
            password_hash='hash'
        )
        session.add(user1)
        session.commit()
        
        try:
            # Try to create duplicate
            user2 = User(
                username='user1',  # Duplicate
                email='user2@example.com',
                password_hash='hash'
            )
            session.add(user2)
            session.commit()
        except Exception:
            session.rollback()
        
        # Verify original user still exists
        users = session.query(User).filter_by(username='user1').all()
        assert len(users) == 1
    
    def test_nested_transactions(self, session):
        """Test nested transactions with savepoints"""
        user = User(
            username='mainuser',
            email='main@example.com',
            password_hash='hash'
        )
        session.add(user)
        session.flush()
        
        # Create savepoint
        savepoint = session.begin_nested()
        
        try:
            # Add another user
            user2 = User(
                username='nested',
                email='nested@example.com',
                password_hash='hash'
            )
            session.add(user2)
            session.flush()
            
            # Rollback to savepoint
            savepoint.rollback()
        except Exception:
            pass
        
        session.commit()
        
        # Only main user should exist
        users = session.query(User).all()
        assert len(users) == 1
        assert users[0].username == 'mainuser'
    
    def test_transfer_transaction(self, session):
        """Test money transfer transaction"""
        # Create two accounts
        from models import Account
        
        acc1 = Account(account_number='ACC1', balance=1000.0)
        acc2 = Account(account_number='ACC2', balance=500.0)
        session.add_all([acc1, acc2])
        session.commit()
        
        # Perform transfer
        try:
            acc1.balance -= 200.0
            acc2.balance += 200.0
            session.commit()
        except Exception:
            session.rollback()
            raise
        
        # Verify balances
        session.refresh(acc1)
        session.refresh(acc2)
        assert acc1.balance == 800.0
        assert acc2.balance == 700.0
```

### Task 4: Mocking and Coverage (25 points)

Use mocking for external dependencies and measure coverage.

**Requirements:**
```python
from unittest.mock import Mock, patch, MagicMock
import pytest

class TestWithMocking:
    """Test using mocks"""
    
    def test_mock_database_connection(self):
        """Mock database connection"""
        # Create mock engine
        mock_engine = Mock()
        mock_connection = Mock()
        mock_engine.connect.return_value = mock_connection
        
        # Use mocked engine
        with mock_engine.connect() as conn:
            result = conn.execute("SELECT 1")
        
        # Verify calls
        mock_engine.connect.assert_called_once()
        mock_connection.execute.assert_called_once()
    
    @patch('services.UserRepository')
    def test_service_with_mocked_repo(self, MockRepo):
        """Test service layer with mocked repository"""
        from services import UserService
        
        # Setup mock
        mock_repo = MockRepo.return_value
        mock_repo.get_by_username.return_value = User(
            id=1,
            username='testuser',
            email='test@example.com'
        )
        
        # Test service
        service = UserService(mock_repo)
        user = service.authenticate('testuser', 'password')
        
        # Verify
        mock_repo.get_by_username.assert_called_once_with('testuser')
        assert user is not None
    
    def test_mock_external_api(self):
        """Mock external API calls"""
        with patch('requests.get') as mock_get:
            # Setup mock response
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {'data': 'test'}
            mock_get.return_value = mock_response
            
            # Code that calls API
            import requests
            response = requests.get('https://api.example.com/data')
            
            # Verify
            assert response.status_code == 200
            assert response.json() == {'data': 'test'}
            mock_get.assert_called_once()

# Test coverage
"""
Run tests with coverage:

pytest --cov=models --cov=repositories --cov=services tests/

# Generate HTML report
pytest --cov=models --cov=repositories --cov=services --cov-report=html tests/

# Check coverage requirements
pytest --cov=models --cov-fail-under=80 tests/
"""

# Parametrized tests
class TestParametrized:
    """Parametrized tests for multiple scenarios"""
    
    @pytest.mark.parametrize("username,email,valid", [
        ("user1", "user1@example.com", True),
        ("ab", "short@example.com", False),  # Too short
        ("user" * 20, "long@example.com", False),  # Too long
        ("user3", "invalid-email", False),  # Invalid email
    ])
    def test_user_validation(self, session, username, email, valid):
        """Test user validation with multiple inputs"""
        user = User(
            username=username,
            email=email,
            password_hash='hash'
        )
        session.add(user)
        
        if valid:
            session.commit()
            assert user.id is not None
        else:
            with pytest.raises(Exception):
                session.commit()
    
    @pytest.mark.parametrize("price,stock,expected_total", [
        (10.0, 5, 50.0),
        (15.99, 3, 47.97),
        (100.0, 0, 0.0),
    ])
    def test_order_calculation(self, price, stock, expected_total):
        """Test order total calculation"""
        total = price * stock
        assert total == pytest.approx(expected_total, rel=0.01)

# Integration test fixtures
@pytest.fixture(scope='session')
def test_database():
    """Session-scoped test database"""
    engine = create_engine('sqlite:///test_integration.db')
    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)
    engine.dispose()
    
    import os
    if os.path.exists('test_integration.db'):
        os.remove('test_integration.db')

@pytest.fixture(scope='module')
def populate_test_data(test_database):
    """Populate test data once per module"""
    SessionLocal = sessionmaker(bind=test_database)
    session = SessionLocal()
    
    # Add test data
    users = [
        User(username=f'user{i}', email=f'user{i}@example.com', password_hash='hash')
        for i in range(10)
    ]
    session.add_all(users)
    session.commit()
    session.close()
```

## Testing

```python
# conftest.py - pytest configuration
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import Base

@pytest.fixture(scope='session')
def engine():
    """Create test database engine"""
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)
    return engine

@pytest.fixture(scope='function')
def session(engine):
    """Create new session for each test"""
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.rollback()
    session.close()

# Run all tests
if __name__ == '__main__':
    pytest.main(['-v', '--cov=.', '--cov-report=html'])
```

## Deliverables

1. **test_models.py**: Model unit tests
2. **test_repositories.py**: Repository tests
3. **test_services.py**: Service layer tests
4. **test_integration.py**: Integration tests
5. **conftest.py**: Pytest configuration
6. **coverage_report.html**: Coverage report

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 25 | Unit tests comprehensive and isolated |
| Task 2 | 25 | Repository tests cover all methods |
| Task 3 | 25 | Transaction tests verify ACID properties |
| Task 4 | 25 | Mocking used appropriately, >80% coverage |

**Total: 100 points**

## Bonus Challenges (+20 points)

1. **Mutation Testing** (+10 points): Use mutpy for mutation testing
2. **Property-Based Testing** (+10 points): Use hypothesis for property tests
