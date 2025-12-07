# Lab 02: SQLAlchemy Core - Schema and Queries

## Learning Objectives

By completing this lab, you will:
- Define database schemas using SQLAlchemy Core
- Execute queries using SQL Expression Language
- Perform CRUD operations with Core API
- Implement complex joins and aggregations
- Use transactions and connection management

## Prerequisites

- Python 3.8+
- SQLAlchemy 2.0+
- Completion of Lab 01
- Understanding of SQL fundamentals

## Tasks

### Task 1: E-Commerce Schema Definition (20 points)

Create a complete e-commerce database schema with tables for customers, products, orders, and order_items.

**Requirements:**
- Customers table: id, name, email, phone, address, created_at
- Products table: id, name, description, price, stock, category
- Orders table: id, customer_id, order_date, status, total_amount
- Order_items table: id, order_id, product_id, quantity, unit_price
- Proper foreign keys and constraints
- Indexes on frequently queried columns

**Starter Code:**
```python
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Float, DateTime, ForeignKey, CheckConstraint, Index
from datetime import datetime

engine = create_engine('sqlite:///ecommerce.db', echo=True)
metadata = MetaData()

# TODO: Define customers table
customers = Table(
    'customers',
    metadata,
    # Add columns here
)

# TODO: Define products table
products = Table(
    'products',
    metadata,
    # Add columns here
)

# TODO: Define orders table
orders = Table(
    'orders',
    metadata,
    # Add columns here
)

# TODO: Define order_items table
order_items = Table(
    'order_items',
    metadata,
    # Add columns here
)

# Create all tables
metadata.create_all(engine)
```

### Task 2: Data Population (20 points)

Insert sample data into all tables using SQLAlchemy Core.

**Requirements:**
- Insert at least 50 customers
- Insert at least 100 products across multiple categories
- Insert at least 200 orders
- Insert at least 500 order items
- Use bulk insert for efficiency
- Maintain referential integrity

**Starter Code:**
```python
from sqlalchemy import insert

def populate_customers(conn):
    """Insert sample customers"""
    # TODO: Generate and insert customer data
    pass

def populate_products(conn):
    """Insert sample products"""
    # TODO: Generate and insert product data
    pass

def populate_orders(conn):
    """Insert sample orders"""
    # TODO: Generate and insert order data
    pass

def populate_order_items(conn):
    """Insert sample order items"""
    # TODO: Generate and insert order item data
    pass

# Main population
with engine.begin() as conn:
    populate_customers(conn)
    populate_products(conn)
    populate_orders(conn)
    populate_order_items(conn)
```

### Task 3: Query Operations (30 points)

Implement complex queries using SQLAlchemy Expression Language.

**Requirements:**
- Find top 10 customers by total purchase amount
- Get products with low stock (< 10 units)
- Calculate monthly revenue
- Find customers who haven't ordered in 90 days
- Get best-selling products by category
- Implement pagination for product listing

**Starter Code:**
```python
from sqlalchemy import select, func, and_, or_, desc
from sqlalchemy.sql import text

def get_top_customers(conn, limit=10):
    """Get top customers by total purchase amount"""
    # TODO: Implement query with join and aggregation
    pass

def get_low_stock_products(conn, threshold=10):
    """Get products with stock below threshold"""
    # TODO: Implement query
    pass

def get_monthly_revenue(conn, year, month):
    """Calculate revenue for specific month"""
    # TODO: Implement aggregation query
    pass

def get_inactive_customers(conn, days=90):
    """Find customers with no orders in X days"""
    # TODO: Implement date-based query
    pass

def get_best_sellers_by_category(conn):
    """Get top products by category"""
    # TODO: Implement grouped aggregation
    pass

def get_products_paginated(conn, page=1, page_size=20):
    """Get paginated product list"""
    # TODO: Implement limit/offset pagination
    pass
```

### Task 4: Advanced Operations (30 points)

Implement complex business logic with transactions.

**Requirements:**
- Create order transaction (decreases product stock)
- Cancel order (restores product stock)
- Apply discount to category
- Generate invoice for order
- Update product prices with percentage increase

**Starter Code:**
```python
from sqlalchemy import update, delete

def create_order_transaction(conn, customer_id, items):
    """
    Create order with transaction
    
    Args:
        conn: Database connection
        customer_id: Customer ID
        items: List of (product_id, quantity) tuples
    
    Returns:
        Order ID
    """
    # TODO: Implement with transaction
    # 1. Check stock availability
    # 2. Create order
    # 3. Create order items
    # 4. Decrease product stock
    # 5. Calculate and update order total
    pass

def cancel_order_transaction(conn, order_id):
    """
    Cancel order and restore stock
    
    Args:
        conn: Database connection
        order_id: Order ID to cancel
    """
    # TODO: Implement with transaction
    # 1. Get order items
    # 2. Restore product stock
    # 3. Update order status to 'cancelled'
    pass

def apply_category_discount(conn, category, discount_pct):
    """Apply discount to all products in category"""
    # TODO: Implement bulk update
    pass

def generate_invoice(conn, order_id):
    """Generate invoice dictionary for order"""
    # TODO: Implement complex join query
    pass

def increase_prices(conn, percentage):
    """Increase all product prices by percentage"""
    # TODO: Implement expression-based update
    pass
```

## Testing

### Test Cases

```python
import unittest
from sqlalchemy import create_engine, select, func

class TestECommerceSchema(unittest.TestCase):
    """Test e-commerce database operations"""
    
    @classmethod
    def setUpClass(cls):
        """Create test database"""
        cls.engine = create_engine('sqlite:///test_ecommerce.db')
        metadata.create_all(cls.engine)
        
        # Populate test data
        with cls.engine.begin() as conn:
            populate_customers(conn)
            populate_products(conn)
            populate_orders(conn)
            populate_order_items(conn)
    
    def test_schema_created(self):
        """Test all tables exist"""
        with self.engine.connect() as conn:
            result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))
            tables = {row[0] for row in result}
            self.assertIn('customers', tables)
            self.assertIn('products', tables)
            self.assertIn('orders', tables)
            self.assertIn('order_items', tables)
    
    def test_foreign_keys(self):
        """Test foreign key constraints"""
        with self.engine.connect() as conn:
            # Try to insert order with invalid customer_id
            with self.assertRaises(Exception):
                conn.execute(
                    orders.insert(),
                    {'customer_id': 99999, 'order_date': datetime.now()}
                )
    
    def test_top_customers(self):
        """Test top customers query"""
        with self.engine.connect() as conn:
            results = get_top_customers(conn, limit=5)
            self.assertEqual(len(results), 5)
            # Verify ordering
            amounts = [r['total_amount'] for r in results]
            self.assertEqual(amounts, sorted(amounts, reverse=True))
    
    def test_create_order(self):
        """Test order creation transaction"""
        with self.engine.begin() as conn:
            # Get initial stock
            stmt = select(products.c.stock).where(products.c.id == 1)
            initial_stock = conn.execute(stmt).scalar()
            
            # Create order
            order_id = create_order_transaction(conn, 1, [(1, 5)])
            
            # Verify stock decreased
            new_stock = conn.execute(stmt).scalar()
            self.assertEqual(new_stock, initial_stock - 5)
    
    def test_cancel_order(self):
        """Test order cancellation"""
        with self.engine.begin() as conn:
            # Create order
            order_id = create_order_transaction(conn, 1, [(2, 3)])
            
            # Get stock before cancel
            stmt = select(products.c.stock).where(products.c.id == 2)
            stock_before = conn.execute(stmt).scalar()
            
            # Cancel order
            cancel_order_transaction(conn, order_id)
            
            # Verify stock restored
            stock_after = conn.execute(stmt).scalar()
            self.assertEqual(stock_after, stock_before + 3)
    
    def test_pagination(self):
        """Test product pagination"""
        with self.engine.connect() as conn:
            page1 = get_products_paginated(conn, page=1, page_size=10)
            page2 = get_products_paginated(conn, page=2, page_size=10)
            
            self.assertEqual(len(page1), 10)
            self.assertEqual(len(page2), 10)
            # Verify different results
            self.assertNotEqual(page1[0]['id'], page2[0]['id'])
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test database"""
        import os
        if os.path.exists('test_ecommerce.db'):
            os.remove('test_ecommerce.db')

if __name__ == '__main__':
    unittest.main()
```

## Deliverables

1. **schema.py**: Complete schema definition with all tables
2. **populate.py**: Data population functions
3. **queries.py**: All query implementations
4. **transactions.py**: Transaction-based business logic
5. **tests.py**: Comprehensive unit tests
6. **README.md**: Documentation with example usage

## Evaluation Criteria

| Component | Points | Criteria |
|-----------|--------|----------|
| Task 1 | 20 | Schema properly defined with constraints |
| Task 2 | 20 | Data population works with integrity |
| Task 3 | 30 | All queries return correct results |
| Task 4 | 30 | Transactions handle edge cases correctly |

**Total: 100 points**

## Bonus Challenges (+30 points)

1. **Stored Procedures** (+10 points): Create Python functions that mimic stored procedures
2. **Audit Log** (+10 points): Add audit table tracking all changes
3. **Soft Delete** (+10 points): Implement soft delete for orders and products

## Resources

- [SQLAlchemy Core Tutorial](https://docs.sqlalchemy.org/en/20/core/tutorial.html)
- [SQL Expression Language](https://docs.sqlalchemy.org/en/20/core/expression_api.html)
- [Metadata and Schema](https://docs.sqlalchemy.org/en/20/core/metadata.html)
