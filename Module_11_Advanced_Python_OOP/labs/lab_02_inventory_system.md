# Lab 2: E-Commerce Inventory Management System

**கற்க கசடற - Learn Flawlessly**

**Estimated Time:** 45-60 minutes  
**Difficulty:** Intermediate  
**Topics:** Inheritance, Method Overriding, Polymorphism

## Objectives

- ✅ Implement inheritance hierarchies
- ✅ Override parent methods appropriately
- ✅ Use polymorphism with different product types
- ✅ Work with collections of related objects

## Scenario

Build an inventory system for an e-commerce platform that handles different product types: Electronics, Clothing, and Books. Each product type has specific attributes and behaviors.

## Requirements

### Part 1: Base Product Class

Create a `Product` base class:
- Attributes: `product_id`, `name`, `base_price`, `stock_quantity`, `category`
- Methods: `get_price()`, `apply_discount(percent)`, `restock(quantity)`, `sell(quantity)`, `get_info()`

### Part 2: Specialized Product Classes

**Electronics Class** (inherits from Product):
- Additional attributes: `warranty_months`, `brand`
- Override `get_price()` to include warranty cost
- Add `extend_warranty(months, cost)` method

**Clothing Class** (inherits from Product):
- Additional attributes: `size`, `color`, `material`
- Override `get_price()` for seasonal discounts
- Add `get_available_sizes()` method

**Book Class** (inherits from Product):
- Additional attributes: `author`, `isbn`, `publisher`, `publication_year`
- Override `get_price()` for bulk discounts
- Add `is_bestseller()` method

### Part 3: Inventory Manager

Create `InventoryManager` class:
- Manage collection of all products
- Add/remove products
- Search by category, price range, name
- Generate inventory reports
- Calculate total inventory value

## Starter Code

```python
class Product:
    def __init__(self, product_id, name, base_price, stock_quantity, category):
        # TODO: Implement
        pass
    
    def get_price(self):
        # TODO: Return base price
        pass
    
    def apply_discount(self, percent):
        # TODO: Apply discount
        pass
    
    def restock(self, quantity):
        # TODO: Add to stock
        pass
    
    def sell(self, quantity):
        # TODO: Reduce stock if available
        pass

class Electronics(Product):
    def __init__(self, product_id, name, base_price, stock, warranty_months, brand):
        # TODO: Call parent init and add electronics-specific attributes
        pass
    
    def get_price(self):
        # TODO: Include warranty cost (warranty_months * 2)
        pass

class Clothing(Product):
    def __init__(self, product_id, name, base_price, stock, size, color, material):
        # TODO: Implement
        pass

class Book(Product):
    def __init__(self, product_id, name, base_price, stock, author, isbn, publisher, year):
        # TODO: Implement
        pass

class InventoryManager:
    def __init__(self):
        self.products = {}
    
    def add_product(self, product):
        # TODO: Add product to inventory
        pass
    
    def get_products_by_category(self, category):
        # TODO: Return products in category
        pass
    
    def calculate_total_value(self):
        # TODO: Sum all product values
        pass
```

## Expected Output

```
=== E-Commerce Inventory System ===

Products Added: 10
  - Electronics: 4
  - Clothing: 3
  - Books: 3

=== Product Catalog ===
[E001] Laptop - $1200.00 (Electronics) - Stock: 15
[E002] Smartphone - $800.00 (Electronics) - Stock: 25
[C001] T-Shirt (Blue, M) - $25.00 (Clothing) - Stock: 50
[B001] "Python Programming" by John Doe - $45.00 (Book) - Stock: 30

=== Inventory Statistics ===
Total Products: 10
Total Value: $45,650.00
Low Stock Alerts: 2 products
Most Expensive: Laptop ($1200.00)
```

---

**Estimated completion time: 45-60 minutes**  
**Difficulty: ⭐⭐⭐ (Intermediate)**
