# Lab 07: Database Migrations with Alembic

## Learning Objectives

- Initialize and configure Alembic for a project
- Create and manage database migrations
- Use autogenerate for schema detection
- Handle data migrations alongside schema changes
- Manage migration branching and merging

## Prerequisites

- Alembic installed (`pip install alembic`)
- SQLAlchemy ORM knowledge
- Completion of Labs 01-06

## Tasks

### Task 1: Project Setup and Initial Migration (20 points)

Set up Alembic for an e-commerce project.

**Requirements:**
```bash
# Initialize Alembic
alembic init alembic

# Directory structure:
# project/
#   ├── alembic/
#   │   ├── versions/
#   │   ├── env.py
#   │   ├── script.py.mako
#   │   └── README
#   ├── alembic.ini
#   ├── models.py
#   └── main.py
```

**models.py:**
```python
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(128), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    
    orders = relationship('Order', back_populates='user')

class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    description = Column(String(1000))
    price = Column(Float, nullable=False)
    stock = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

class Order(Base):
    __tablename__ = 'orders'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    order_date = Column(DateTime, default=datetime.utcnow)
    status = Column(String(20), default='pending')
    total_amount = Column(Float, default=0.0)
    
    user = relationship('User', back_populates='orders')
    items = relationship('OrderItem', back_populates='order')

class OrderItem(Base):
    __tablename__ = 'order_items'
    
    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey('orders.id'), nullable=False)
    product_id = Column(Integer, ForeignKey('products.id'), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Float, nullable=False)
    
    order = relationship('Order', back_populates='items')
    product = relationship('Product')
```

**alembic/env.py configuration:**
```python
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
import sys
import os

# Add project directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

# Import your models
from models import Base

# This is the Alembic Config object
config = context.config

# Setup logging
fileConfig(config.config_file_name)

# Set target metadata
target_metadata = Base.metadata

# TODO: Complete env.py configuration
# Add run_migrations_online() function
```

**Tasks:**
1. Configure alembic.ini with database URL
2. Set up env.py to import models
3. Generate initial migration: `alembic revision --autogenerate -m "initial schema"`
4. Apply migration: `alembic upgrade head`
5. Verify tables created

### Task 2: Schema Evolution Migrations (25 points)

Create migrations for schema changes.

**Change 1: Add new fields to User**
```python
# Modify models.py
class User(Base):
    # ... existing fields ...
    first_name = Column(String(50))
    last_name = Column(String(50))
    phone = Column(String(20))
    address = Column(String(200))

# Generate migration
# alembic revision --autogenerate -m "add user profile fields"
```

**Change 2: Add Product Categories**
```python
class Category(Base):
    __tablename__ = 'categories'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    parent_id = Column(Integer, ForeignKey('categories.id'))
    
    products = relationship('Product', back_populates='category')
    parent = relationship('Category', remote_side=[id], back_populates='children')
    children = relationship('Category', back_populates='parent')

class Product(Base):
    # ... existing fields ...
    category_id = Column(Integer, ForeignKey('categories.id'))
    category = relationship('Category', back_populates='products')

# Generate migration
# alembic revision --autogenerate -m "add product categories"
```

**Change 3: Add Indexes**
```python
# Manual migration for indexes
# alembic revision -m "add performance indexes"

# In migration file:
def upgrade():
    op.create_index('idx_user_email', 'users', ['email'])
    op.create_index('idx_product_name', 'products', ['name'])
    op.create_index('idx_order_user', 'orders', ['user_id'])
    op.create_index('idx_order_status', 'orders', ['status'])

def downgrade():
    op.drop_index('idx_order_status', 'orders')
    op.drop_index('idx_order_user', 'orders')
    op.drop_index('idx_product_name', 'products')
    op.drop_index('idx_user_email', 'users')
```

### Task 3: Data Migrations (30 points)

Implement migrations that transform data.

**Migration 1: Split Name Field**
```python
# alembic revision -m "split user name field"

from alembic import op
import sqlalchemy as sa

def upgrade():
    # Add new columns
    op.add_column('users', sa.Column('first_name', sa.String(50)))
    op.add_column('users', sa.Column('last_name', sa.String(50)))
    
    # Migrate data
    # TODO: Split existing name into first_name and last_name
    connection = op.get_bind()
    connection.execute(\"\"\"
        UPDATE users
        SET first_name = SUBSTR(name, 1, INSTR(name, ' ') - 1),
            last_name = SUBSTR(name, INSTR(name, ' ') + 1)
        WHERE name LIKE '% %'
    \"\"\")
    
    # Drop old column
    op.drop_column('users', 'name')

def downgrade():
    # Add name column back
    op.add_column('users', sa.Column('name', sa.String(100)))
    
    # Concatenate first_name and last_name
    connection = op.get_bind()
    connection.execute(\"\"\"
        UPDATE users
        SET name = first_name || ' ' || last_name
    \"\"\")
    
    # Drop split columns
    op.drop_column('users', 'last_name')
    op.drop_column('users', 'first_name')
```

**Migration 2: Normalize Order Status**
```python
# alembic revision -m "normalize order status"

def upgrade():
    # Create status table
    op.create_table(
        'order_statuses',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('name', sa.String(20), unique=True, nullable=False)
    )
    
    # Insert standard statuses
    connection = op.get_bind()
    connection.execute(\"\"\"
        INSERT INTO order_statuses (name) VALUES
        ('pending'), ('processing'), ('shipped'), ('delivered'), ('cancelled')
    \"\"\")
    
    # Add status_id to orders
    op.add_column('orders', sa.Column('status_id', sa.Integer()))
    
    # Migrate existing data
    # TODO: Map status strings to status IDs
    
    # Add foreign key
    op.create_foreign_key('fk_order_status', 'orders', 'order_statuses',
                         ['status_id'], ['id'])
    
    # Drop old status column
    op.drop_column('orders', 'status')

def downgrade():
    # Reverse process
    pass
```

**Migration 3: Batch Update with Progress**
```python
# alembic revision -m "update product prices"

def upgrade():
    from sqlalchemy import table, column, Integer, Float
    
    # Define minimal table for data migration
    products = table('products',
        column('id', Integer),
        column('price', Float)
    )
    
    connection = op.get_bind()
    
    # Update in batches
    batch_size = 1000
    offset = 0
    
    while True:
        result = connection.execute(
            products.select().limit(batch_size).offset(offset)
        )
        rows = result.fetchall()
        
        if not rows:
            break
        
        # Update prices (10% increase)
        for row in rows:
            connection.execute(
                products.update()
                .where(products.c.id == row.id)
                .values(price=row.price * 1.1)
            )
        
        offset += batch_size
        print(f"Updated {offset} products...")

def downgrade():
    # Reverse price change (divide by 1.1)
    pass
```

### Task 4: Advanced Migration Scenarios (25 points)

Handle complex migration scenarios.

**Branching and Merging:**
```bash
# Feature branch migrations
alembic revision -m "feature: add reviews" --branch-label reviews

# Main branch continues
alembic revision -m "add shipping options"

# Merge branches
alembic merge -m "merge reviews feature" reviews_head main_head
```

**Conditional Migrations:**
```python
# alembic revision -m "conditional migration"

def upgrade():
    connection = op.get_bind()
    inspector = sa.inspect(connection)
    
    # Check if column exists
    columns = [c['name'] for c in inspector.get_columns('users')]
    
    if 'phone' not in columns:
        op.add_column('users', sa.Column('phone', sa.String(20)))
    
    # Check if index exists
    indexes = inspector.get_indexes('users')
    index_names = [idx['name'] for idx in indexes]
    
    if 'idx_user_email' not in index_names:
        op.create_index('idx_user_email', 'users', ['email'])
```

**Database-Specific Migrations:**
```python
# alembic revision -m "database specific features"

def upgrade():
    connection = op.get_bind()
    dialect = connection.dialect.name
    
    if dialect == 'postgresql':
        # PostgreSQL-specific
        op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
        op.create_index('idx_product_name_trgm', 'products',
                       ['name'], postgresql_using='gin',
                       postgresql_ops={'name': 'gin_trgm_ops'})
    
    elif dialect == 'mysql':
        # MySQL-specific
        op.execute("ALTER TABLE products ADD FULLTEXT idx_product_name (name)")
    
    elif dialect == 'sqlite':
        # SQLite-specific (limited features)
        pass
```

## Testing

```python
import unittest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

class TestMigrations(unittest.TestCase):
    """Test Alembic migrations"""
    
    def setUp(self):
        """Set up test database"""
        self.config = Config("alembic.ini")
        self.config.set_main_option("sqlalchemy.url", "sqlite:///test_migrations.db")
        self.engine = create_engine("sqlite:///test_migrations.db")
    
    def test_upgrade_downgrade(self):
        """Test upgrade and downgrade"""
        # Upgrade to head
        command.upgrade(self.config, "head")
        
        # Check tables exist
        inspector = inspect(self.engine)
        tables = inspector.get_table_names()
        self.assertIn('users', tables)
        self.assertIn('products', tables)
        
        # Downgrade to base
        command.downgrade(self.config, "base")
        
        # Check tables removed
        tables = inspector.get_table_names()
        self.assertEqual(len(tables), 0)
    
    def test_migration_history(self):
        """Test migration history"""
        command.upgrade(self.config, "head")
        
        # Get current revision
        from alembic.script import ScriptDirectory
        script = ScriptDirectory.from_config(self.config)
        head = script.get_current_head()
        
        self.assertIsNotNone(head)
    
    def tearDown(self):
        """Clean up"""
        import os
        if os.path.exists("test_migrations.db"):
            os.remove("test_migrations.db")

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **models.py**: Complete SQLAlchemy models
2. **alembic/** directory: All migration files
3. **migration_script.py**: Automated migration runner
4. **migration_guide.md**: Documentation for all migrations
5. **tests.py**: Migration test suite

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 20 | Initial setup and migration work |
| Task 2 | 25 | Schema changes migrate correctly |
| Task 3 | 30 | Data migrations preserve data integrity |
| Task 4 | 25 | Advanced scenarios handled properly |

**Total: 100 points**

## Bonus Challenges (+20 points)

1. **CI/CD Integration** (+10 points): Automate migrations in deployment pipeline
2. **Multi-Environment** (+10 points): Handle dev/staging/prod migration workflows
