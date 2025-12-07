# Section 08: Database Migrations with Alembic

## Introduction

Alembic is a database migration tool for SQLAlchemy. It allows you to version control your database schema and manage changes over time.

## Installation and Setup

### Installing Alembic

```bash
pip install alembic
```

### Initializing Alembic

```bash
# Initialize in project directory
alembic init alembic

# Creates:
# alembic/
#   ├── versions/          # Migration scripts
#   ├── env.py            # Environment configuration
#   ├── script.py.mako    # Migration template
#   └── README
# alembic.ini             # Configuration file
```

### Configuration

```python
# alembic.ini
[alembic]
script_location = alembic
sqlalchemy.url = postgresql://user:pass@localhost/mydb

# Or use environment variable
# sqlalchemy.url = driver://user:pass@localhost/dbname
```

### Configure env.py

```python
# alembic/env.py
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# Import your models
from myapp.models import Base

# This is the Alembic Config object
config = context.config

# Setup logging
fileConfig(config.config_file_name)

# Set target metadata from your models
target_metadata = Base.metadata

def run_migrations_online():
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix='sqlalchemy.',
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()

run_migrations_online()
```

## Creating Migrations

### Manual Migration

```bash
# Create empty migration
alembic revision -m "create users table"
```

```python
# alembic/versions/xxx_create_users_table.py
from alembic import op
import sqlalchemy as sa

# Revision identifiers
revision = 'abc123'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    """Create users table"""
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('username', sa.String(50), nullable=False),
        sa.Column('email', sa.String(100), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now())
    )
    
    # Create index
    op.create_index('idx_username', 'users', ['username'])

def downgrade():
    """Drop users table"""
    op.drop_index('idx_username', 'users')
    op.drop_table('users')
```

### Auto-generating Migrations

```bash
# Generate migration from model changes
alembic revision --autogenerate -m "add products table"
```

```python
# Models file (models.py)
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String(50))
    email = Column(String(100))

class Product(Base):
    __tablename__ = 'products'
    id = Column(Integer, primary_key=True)
    name = Column(String(200))
    price = Column(Float)

# Alembic detects Product table is new and generates migration
```

## Running Migrations

### Apply Migrations

```bash
# Upgrade to latest revision
alembic upgrade head

# Upgrade to specific revision
alembic upgrade abc123

# Upgrade one step
alembic upgrade +1

# Downgrade one step
alembic downgrade -1

# Downgrade to specific revision
alembic downgrade abc123

# Downgrade all
alembic downgrade base
```

### Migration History

```bash
# Show current revision
alembic current

# Show migration history
alembic history

# Show pending migrations
alembic history --verbose

# Show SQL without executing
alembic upgrade head --sql
```

## Common Migration Operations

### Table Operations

```python
def upgrade():
    # Create table
    op.create_table(
        'orders',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('total', sa.Float(), nullable=False),
        sa.Column('status', sa.String(20), default='pending')
    )
    
    # Drop table
    op.drop_table('old_table')
    
    # Rename table
    op.rename_table('old_name', 'new_name')
```

### Column Operations

```python
def upgrade():
    # Add column
    op.add_column(
        'users',
        sa.Column('phone', sa.String(20), nullable=True)
    )
    
    # Drop column
    op.drop_column('users', 'old_column')
    
    # Alter column type
    op.alter_column(
        'users',
        'age',
        type_=sa.String(3),
        existing_type=sa.Integer()
    )
    
    # Rename column
    op.alter_column(
        'users',
        'username',
        new_column_name='user_name'
    )
    
    # Change column nullable
    op.alter_column(
        'users',
        'email',
        nullable=False,
        existing_type=sa.String(100)
    )
```

### Index Operations

```python
def upgrade():
    # Create index
    op.create_index(
        'idx_user_email',
        'users',
        ['email'],
        unique=True
    )
    
    # Create composite index
    op.create_index(
        'idx_user_name_email',
        'users',
        ['username', 'email']
    )
    
    # Drop index
    op.drop_index('idx_old_index', 'users')
```

### Foreign Key Operations

```python
def upgrade():
    # Add foreign key
    op.create_foreign_key(
        'fk_order_user',
        'orders',
        'users',
        ['user_id'],
        ['id'],
        ondelete='CASCADE'
    )
    
    # Drop foreign key
    op.drop_constraint('fk_order_user', 'orders', type_='foreignkey')
```

### Constraint Operations

```python
def upgrade():
    # Add unique constraint
    op.create_unique_constraint(
        'uq_user_email',
        'users',
        ['email']
    )
    
    # Add check constraint
    op.create_check_constraint(
        'ck_positive_price',
        'products',
        'price > 0'
    )
    
    # Drop constraint
    op.drop_constraint('uq_user_email', 'users')
```

## Data Migrations

### Inserting Data

```python
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import table, column

def upgrade():
    # Define minimal table structure
    users_table = table(
        'users',
        column('id', sa.Integer),
        column('username', sa.String),
        column('email', sa.String)
    )
    
    # Insert data
    op.bulk_insert(
        users_table,
        [
            {'username': 'admin', 'email': 'admin@example.com'},
            {'username': 'user', 'email': 'user@example.com'}
        ]
    )

def downgrade():
    op.execute("DELETE FROM users WHERE username IN ('admin', 'user')")
```

### Updating Data

```python
def upgrade():
    # Using execute
    op.execute(
        "UPDATE products SET price = price * 1.1 WHERE category = 'electronics'"
    )
    
    # Using table construct
    connection = op.get_bind()
    products = table(
        'products',
        column('id', sa.Integer),
        column('price', sa.Float),
        column('category', sa.String)
    )
    
    connection.execute(
        products.update()
        .where(products.c.category == 'electronics')
        .values(price=products.c.price * 1.1)
    )
```

### Complex Data Transformations

```python
def upgrade():
    # Get connection
    connection = op.get_bind()
    
    # Fetch data
    result = connection.execute(
        sa.text("SELECT id, old_field FROM my_table")
    )
    
    # Transform and update
    for row in result:
        new_value = transform_function(row.old_field)
        connection.execute(
            sa.text("UPDATE my_table SET new_field = :val WHERE id = :id"),
            {'val': new_value, 'id': row.id}
        )
```

## Advanced Migration Patterns

### Branching and Merging

```bash
# Create branch
alembic revision -m "feature branch" --branch-label feature

# Merge branches
alembic merge -m "merge feature" head1 head2
```

### Conditional Migrations

```python
def upgrade():
    # Check if column exists
    connection = op.get_bind()
    inspector = sa.inspect(connection)
    columns = [c['name'] for c in inspector.get_columns('users')]
    
    if 'phone' not in columns:
        op.add_column('users', sa.Column('phone', sa.String(20)))

def downgrade():
    if 'phone' in columns:
        op.drop_column('users', 'phone')
```

### Multi-Database Migrations

```python
# alembic/env.py
from alembic import context
from sqlalchemy import engine_from_config, pool

def run_migrations_online():
    # Get database URLs from config
    db_configs = {
        'main': config.get_main_option('sqlalchemy.url'),
        'analytics': config.get_main_option('analytics.url')
    }
    
    for name, url in db_configs.items():
        engine = sa.create_engine(url)
        with engine.connect() as connection:
            context.configure(
                connection=connection,
                target_metadata=metadata_map[name]
            )
            
            with context.begin_transaction():
                context.run_migrations()
```

## Testing Migrations

### Test Migration Up and Down

```python
# test_migrations.py
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

@pytest.fixture
def alembic_config():
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", "sqlite:///test.db")
    return config

def test_upgrade_downgrade(alembic_config):
    # Upgrade to head
    command.upgrade(alembic_config, "head")
    
    # Check table exists
    engine = create_engine(alembic_config.get_main_option("sqlalchemy.url"))
    inspector = inspect(engine)
    assert 'users' in inspector.get_table_names()
    
    # Downgrade
    command.downgrade(alembic_config, "base")
    
    # Check table removed
    assert 'users' not in inspector.get_table_names()
```

## Complete Example

```python
# models.py
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    orders = relationship('Order', back_populates='user')

class Product(Base):
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    price = Column(Float, nullable=False)
    stock = Column(Integer, default=0)

class Order(Base):
    __tablename__ = 'orders'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    product_id = Column(Integer, ForeignKey('products.id'), nullable=False)
    quantity = Column(Integer, nullable=False)
    order_date = Column(DateTime, default=datetime.utcnow)
    
    user = relationship('User', back_populates='orders')
```

```bash
# Initialize Alembic
alembic init alembic

# Generate initial migration
alembic revision --autogenerate -m "initial schema"

# Apply migration
alembic upgrade head

# Add new column to Product
# Modify models.py to add 'description' column to Product

# Generate migration
alembic revision --autogenerate -m "add product description"

# Review generated migration in alembic/versions/

# Apply migration
alembic upgrade head

# Rollback if needed
alembic downgrade -1
```

```python
# Generated migration example
"""add product description

Revision ID: def456
Revises: abc123
Create Date: 2024-01-15

"""
from alembic import op
import sqlalchemy as sa

revision = 'def456'
down_revision = 'abc123'

def upgrade():
    op.add_column(
        'products',
        sa.Column('description', sa.Text(), nullable=True)
    )

def downgrade():
    op.drop_column('products', 'description')
```

## Summary

Alembic provides:
- Version control for database schema
- Auto-generation from SQLAlchemy models
- Reversible migrations (upgrade/downgrade)
- Data migrations alongside schema changes
- Multiple database support
- Testing capabilities

**Next**: Section 09 - Pandas and SQL Integration
