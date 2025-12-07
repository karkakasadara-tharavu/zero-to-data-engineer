# Lab 02 Solution: E-Commerce Inventory System

"""
Complete solution for the E-Commerce Inventory System lab.
Demonstrates: Inheritance, Method Overriding, Polymorphism

Author: Data Engineering Curriculum
Module: 11 - Advanced Python & OOP
"""

class Product:
    """Base class for all products in the inventory"""
    
    # Class variable to track total products
    _product_count = 0
    
    def __init__(self, product_id, name, base_price, quantity):
        """
        Initialize a product.
        
        Args:
            product_id (str): Unique product identifier
            name (str): Product name
            base_price (float): Base price before any discounts
            quantity (int): Quantity in stock
        """
        self.product_id = product_id
        self.name = name
        self.base_price = base_price
        self.quantity = quantity
        
        Product._product_count += 1
    
    def get_price(self):
        """
        Calculate the final price (to be overridden by subclasses).
        
        Returns:
            float: Final price after any calculations
        """
        return self.base_price
    
    def get_category(self):
        """
        Get product category (to be overridden by subclasses).
        
        Returns:
            str: Product category name
        """
        return "General"
    
    def is_in_stock(self):
        """
        Check if product is in stock.
        
        Returns:
            bool: True if quantity > 0
        """
        return self.quantity > 0
    
    def add_stock(self, amount):
        """
        Add inventory.
        
        Args:
            amount (int): Quantity to add
        """
        if amount > 0:
            self.quantity += amount
            return True
        return False
    
    def reduce_stock(self, amount):
        """
        Reduce inventory.
        
        Args:
            amount (int): Quantity to remove
            
        Returns:
            bool: True if successful, False if insufficient stock
        """
        if amount > 0 and amount <= self.quantity:
            self.quantity -= amount
            return True
        return False
    
    def get_info(self):
        """
        Get product information.
        
        Returns:
            dict: Product information dictionary
        """
        return {
            'id': self.product_id,
            'name': self.name,
            'category': self.get_category(),
            'base_price': self.base_price,
            'final_price': self.get_price(),
            'quantity': self.quantity,
            'in_stock': self.is_in_stock()
        }
    
    def __str__(self):
        """String representation"""
        price = self.get_price()
        stock_status = "In Stock" if self.is_in_stock() else "Out of Stock"
        return f"{self.name} (${price:.2f}) - {stock_status} (Qty: {self.quantity})"
    
    def __repr__(self):
        """Official representation"""
        return f"Product(id='{self.product_id}', name='{self.name}')"


class Electronics(Product):
    """Electronics products with warranty"""
    
    def __init__(self, product_id, name, base_price, quantity, warranty_months, brand):
        """
        Initialize an electronics product.
        
        Args:
            product_id (str): Product ID
            name (str): Product name
            base_price (float): Base price
            quantity (int): Stock quantity
            warranty_months (int): Warranty period in months
            brand (str): Electronics brand
        """
        super().__init__(product_id, name, base_price, quantity)
        self.warranty_months = warranty_months
        self.brand = brand
    
    def get_price(self):
        """
        Calculate price including warranty cost.
        
        Returns:
            float: Price with warranty included
        """
        # Add $5 per year of warranty
        warranty_cost = (self.warranty_months / 12) * 5.0
        return self.base_price + warranty_cost
    
    def get_category(self):
        """Return category name"""
        return "Electronics"
    
    def get_warranty_info(self):
        """
        Get warranty information.
        
        Returns:
            str: Formatted warranty information
        """
        years = self.warranty_months // 12
        months = self.warranty_months % 12
        if years > 0 and months > 0:
            return f"{years} year(s) and {months} month(s)"
        elif years > 0:
            return f"{years} year(s)"
        else:
            return f"{months} month(s)"
    
    def __str__(self):
        """String representation with brand and warranty"""
        base_str = super().__str__()
        return f"{base_str} | {self.brand} | Warranty: {self.get_warranty_info()}"


class Clothing(Product):
    """Clothing products with size and seasonal discounts"""
    
    # Seasonal discount percentages
    SEASONAL_DISCOUNTS = {
        'spring': 0.10,  # 10% off
        'summer': 0.15,  # 15% off
        'fall': 0.10,    # 10% off
        'winter': 0.20   # 20% off
    }
    
    def __init__(self, product_id, name, base_price, quantity, size, material, season=None):
        """
        Initialize a clothing product.
        
        Args:
            product_id (str): Product ID
            name (str): Product name
            base_price (float): Base price
            quantity (int): Stock quantity
            size (str): Clothing size (S, M, L, XL, etc.)
            material (str): Fabric material
            season (str): Season for discounts (spring/summer/fall/winter)
        """
        super().__init__(product_id, name, base_price, quantity)
        self.size = size
        self.material = material
        self.season = season
    
    def get_price(self):
        """
        Calculate price with seasonal discount.
        
        Returns:
            float: Price after seasonal discount
        """
        if self.season and self.season.lower() in self.SEASONAL_DISCOUNTS:
            discount = self.SEASONAL_DISCOUNTS[self.season.lower()]
            return self.base_price * (1 - discount)
        return self.base_price
    
    def get_category(self):
        """Return category name"""
        return "Clothing"
    
    def get_discount_info(self):
        """
        Get discount information.
        
        Returns:
            str: Discount description or None
        """
        if self.season and self.season.lower() in self.SEASONAL_DISCOUNTS:
            discount_pct = self.SEASONAL_DISCOUNTS[self.season.lower()] * 100
            return f"{discount_pct:.0f}% off ({self.season.title()} Sale)"
        return "No current discount"
    
    def __str__(self):
        """String representation with size and material"""
        base_str = super().__str__()
        discount = self.get_discount_info()
        return f"{base_str} | Size: {self.size} | {self.material} | {discount}"


class Book(Product):
    """Book products with author and ISBN"""
    
    # Bulk discount thresholds
    BULK_THRESHOLD = 5  # Buy 5 or more for discount
    BULK_DISCOUNT = 0.15  # 15% off for bulk purchases
    
    def __init__(self, product_id, name, base_price, quantity, author, isbn, pages):
        """
        Initialize a book product.
        
        Args:
            product_id (str): Product ID
            name (str): Book title
            base_price (float): Base price
            quantity (int): Stock quantity
            author (str): Book author
            isbn (str): ISBN number
            pages (int): Number of pages
        """
        super().__init__(product_id, name, base_price, quantity)
        self.author = author
        self.isbn = isbn
        self.pages = pages
    
    def get_price(self, bulk_quantity=1):
        """
        Calculate price with potential bulk discount.
        
        Args:
            bulk_quantity (int): Number of copies being purchased
            
        Returns:
            float: Price per unit
        """
        if bulk_quantity >= self.BULK_THRESHOLD:
            return self.base_price * (1 - self.BULK_DISCOUNT)
        return self.base_price
    
    def get_category(self):
        """Return category name"""
        return "Books"
    
    def get_bulk_discount_info(self):
        """
        Get bulk discount information.
        
        Returns:
            str: Bulk discount description
        """
        return f"Buy {self.BULK_THRESHOLD}+ for {self.BULK_DISCOUNT*100:.0f}% off"
    
    def __str__(self):
        """String representation with author and ISBN"""
        base_str = super().__str__()
        return f"{base_str} | by {self.author} | ISBN: {self.isbn}"


class InventoryManager:
    """Manages the complete product inventory"""
    
    def __init__(self, store_name):
        """
        Initialize inventory manager.
        
        Args:
            store_name (str): Name of the store
        """
        self.store_name = store_name
        self.products = {}  # Dictionary: product_id -> Product
    
    def add_product(self, product):
        """
        Add product to inventory.
        
        Args:
            product (Product): Product object to add
            
        Returns:
            bool: True if successful
        """
        if product.product_id in self.products:
            print(f"✗ Product {product.product_id} already exists")
            return False
        
        self.products[product.product_id] = product
        print(f"✓ Added: {product.name}")
        return True
    
    def remove_product(self, product_id):
        """
        Remove product from inventory.
        
        Args:
            product_id (str): Product ID to remove
            
        Returns:
            bool: True if successful
        """
        if product_id in self.products:
            product = self.products.pop(product_id)
            print(f"✓ Removed: {product.name}")
            return True
        print(f"✗ Product {product_id} not found")
        return False
    
    def get_product(self, product_id):
        """
        Get product by ID.
        
        Args:
            product_id (str): Product ID
            
        Returns:
            Product or None: Product object if found
        """
        return self.products.get(product_id)
    
    def search_by_name(self, name):
        """
        Search products by name (case-insensitive partial match).
        
        Args:
            name (str): Search term
            
        Returns:
            list: List of matching products
        """
        name_lower = name.lower()
        return [p for p in self.products.values() if name_lower in p.name.lower()]
    
    def search_by_category(self, category):
        """
        Get all products in a category.
        
        Args:
            category (str): Category name
            
        Returns:
            list: List of products in category
        """
        return [p for p in self.products.values() if p.get_category() == category]
    
    def search_by_price_range(self, min_price, max_price):
        """
        Find products within price range.
        
        Args:
            min_price (float): Minimum price
            max_price (float): Maximum price
            
        Returns:
            list: List of products in price range
        """
        return [p for p in self.products.values() 
                if min_price <= p.get_price() <= max_price]
    
    def get_total_inventory_value(self):
        """
        Calculate total value of all inventory.
        
        Returns:
            float: Total inventory value
        """
        return sum(p.get_price() * p.quantity for p in self.products.values())
    
    def get_out_of_stock_products(self):
        """
        Get list of out-of-stock products.
        
        Returns:
            list: Products with quantity 0
        """
        return [p for p in self.products.values() if not p.is_in_stock()]
    
    def get_low_stock_products(self, threshold=5):
        """
        Get products with low stock.
        
        Args:
            threshold (int): Low stock threshold
            
        Returns:
            list: Products with quantity <= threshold
        """
        return [p for p in self.products.values() 
                if p.is_in_stock() and p.quantity <= threshold]
    
    def generate_report(self):
        """Generate comprehensive inventory report"""
        print(f"\n{'='*80}")
        print(f"{self.store_name.upper()} - INVENTORY REPORT")
        print(f"{'='*80}")
        
        # Overall statistics
        total_products = len(self.products)
        total_value = self.get_total_inventory_value()
        in_stock = sum(1 for p in self.products.values() if p.is_in_stock())
        
        print(f"\n📊 OVERALL STATISTICS:")
        print(f"   Total Products: {total_products}")
        print(f"   In Stock: {in_stock}")
        print(f"   Out of Stock: {total_products - in_stock}")
        print(f"   Total Inventory Value: ${total_value:,.2f}")
        
        # Category breakdown
        print(f"\n📦 BY CATEGORY:")
        categories = {}
        for product in self.products.values():
            cat = product.get_category()
            if cat not in categories:
                categories[cat] = {'count': 0, 'value': 0}
            categories[cat]['count'] += 1
            categories[cat]['value'] += product.get_price() * product.quantity
        
        for category, stats in sorted(categories.items()):
            print(f"   {category}:")
            print(f"     Products: {stats['count']}")
            print(f"     Total Value: ${stats['value']:,.2f}")
        
        # Low stock warning
        low_stock = self.get_low_stock_products(threshold=5)
        if low_stock:
            print(f"\n⚠️  LOW STOCK ALERT ({len(low_stock)} items):")
            for product in low_stock:
                print(f"   • {product.name}: {product.quantity} units remaining")
        
        # Out of stock
        out_of_stock = self.get_out_of_stock_products()
        if out_of_stock:
            print(f"\n🚫 OUT OF STOCK ({len(out_of_stock)} items):")
            for product in out_of_stock:
                print(f"   • {product.name}")
        
        print(f"\n{'='*80}\n")
    
    def display_catalog(self):
        """Display complete product catalog"""
        print(f"\n{'='*80}")
        print(f"{self.store_name.upper()} - PRODUCT CATALOG")
        print(f"{'='*80}\n")
        
        # Group by category
        categories = {}
        for product in self.products.values():
            cat = product.get_category()
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(product)
        
        for category in sorted(categories.keys()):
            print(f"\n{category.upper()}:")
            print("-" * 80)
            for product in sorted(categories[category], key=lambda p: p.name):
                print(f"  {product}")
        
        print(f"\n{'='*80}\n")
    
    def __len__(self):
        """Return number of products"""
        return len(self.products)
    
    def __str__(self):
        """String representation"""
        return f"{self.store_name} Inventory - {len(self.products)} products"


# ==================== TESTING ====================

def main():
    """Test the complete inventory system"""
    
    print("="*80)
    print("E-COMMERCE INVENTORY SYSTEM - COMPLETE SOLUTION")
    print("="*80)
    
    # Create inventory manager
    inventory = InventoryManager("TechMart Online Store")
    print(f"\n✓ Created: {inventory}\n")
    
    # Add Electronics products
    print("="*80)
    print("ADDING ELECTRONICS")
    print("="*80)
    laptop = Electronics("ELEC001", "Gaming Laptop", 1200.00, 15, 24, "ASUS")
    phone = Electronics("ELEC002", "Smartphone Pro", 899.99, 25, 12, "Samsung")
    tablet = Electronics("ELEC003", "Tablet Air", 599.00, 10, 12, "Apple")
    
    inventory.add_product(laptop)
    inventory.add_product(phone)
    inventory.add_product(tablet)
    
    # Add Clothing products
    print(f"\n{'='*80}")
    print("ADDING CLOTHING")
    print("="*80)
    jacket = Clothing("CLO001", "Winter Jacket", 89.99, 30, "L", "Wool", "winter")
    tshirt = Clothing("CLO002", "Cotton T-Shirt", 19.99, 50, "M", "Cotton", "summer")
    jeans = Clothing("CLO003", "Denim Jeans", 59.99, 40, "32", "Denim")
    
    inventory.add_product(jacket)
    inventory.add_product(tshirt)
    inventory.add_product(jeans)
    
    # Add Books
    print(f"\n{'='*80}")
    print("ADDING BOOKS")
    print("="*80)
    python_book = Book("BOOK001", "Python Programming", 45.00, 20, "John Doe", "978-1234567890", 450)
    data_book = Book("BOOK002", "Data Science Handbook", 55.00, 15, "Jane Smith", "978-0987654321", 600)
    ml_book = Book("BOOK003", "Machine Learning Basics", 39.99, 8, "Alan Tech", "978-1122334455", 380)
    
    inventory.add_product(python_book)
    inventory.add_product(data_book)
    inventory.add_product(ml_book)
    
    # Display catalog
    inventory.display_catalog()
    
    # Search operations
    print("="*80)
    print("SEARCH OPERATIONS")
    print("="*80)
    
    print("\n🔍 Searching for 'laptop':")
    results = inventory.search_by_name("laptop")
    for product in results:
        print(f"  • {product}")
    
    print("\n🔍 Products in 'Books' category:")
    books = inventory.search_by_category("Books")
    for book in books:
        print(f"  • {book}")
    
    print("\n🔍 Products between $50 and $100:")
    mid_range = inventory.search_by_price_range(50, 100)
    for product in mid_range:
        print(f"  • {product}")
    
    # Demonstrate polymorphism - calling get_price() on different types
    print(f"\n{'='*80}")
    print("POLYMORPHISM DEMONSTRATION")
    print("="*80)
    print("\nCalling get_price() on different product types:\n")
    
    products_to_demo = [laptop, jacket, python_book]
    for product in products_to_demo:
        print(f"{product.get_category()}: {product.name}")
        print(f"  Base Price: ${product.base_price:.2f}")
        print(f"  Final Price: ${product.get_price():.2f}")
        if isinstance(product, Electronics):
            print(f"  (Includes warranty: {product.get_warranty_info()})")
        elif isinstance(product, Clothing):
            print(f"  (Discount: {product.get_discount_info()})")
        elif isinstance(product, Book):
            print(f"  (Bulk: {product.get_bulk_discount_info()})")
        print()
    
    # Generate report
    inventory.generate_report()
    
    # Modify stock
    print("="*80)
    print("STOCK MODIFICATIONS")
    print("="*80)
    print(f"\nReducing laptop stock by 10...")
    laptop.reduce_stock(10)
    print(f"New quantity: {laptop.quantity}")
    
    print(f"\nReducing ML book stock to 0...")
    ml_book.reduce_stock(8)
    print(f"New quantity: {ml_book.quantity}")
    
    # Show updated report
    inventory.generate_report()


if __name__ == "__main__":
    main()
