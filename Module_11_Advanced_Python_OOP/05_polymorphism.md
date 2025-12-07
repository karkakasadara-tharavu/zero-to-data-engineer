# Polymorphism in Python

**கற்க கசடற - Learn Flawlessly**

## Introduction

Polymorphism, derived from Greek meaning "many forms," is a core principle of Object-Oriented Programming that allows objects of different classes to be treated as objects of a common parent class. It enables a single interface to represent different underlying forms (data types or classes).

In simpler terms: **Same method name, different behaviors depending on the object.**

## Types of Polymorphism in Python

Python supports several forms of polymorphism:

1. **Duck Typing** - "If it walks like a duck and quacks like a duck, it's a duck"
2. **Method Overriding** - Child class provides its own implementation
3. **Operator Overloading** - Defining custom behavior for operators
4. **Function Polymorphism** - Same function, different parameter types

## Duck Typing

Python uses duck typing: the type or class of an object is less important than the methods it defines. If an object has the required methods, it can be used, regardless of its actual type.

```python
class Dog:
    def speak(self):
        return "Woof!"

class Cat:
    def speak(self):
        return "Meow!"

class Duck:
    def speak(self):
        return "Quack!"

class Robot:
    def speak(self):
        return "Beep boop!"

# Polymorphic function - works with any object that has speak() method
def make_it_speak(animal):
    """Works with ANY object that has a speak() method"""
    print(animal.speak())

# Usage - all different classes, but same interface
dog = Dog()
cat = Cat()
duck = Duck()
robot = Robot()

make_it_speak(dog)    # Woof!
make_it_speak(cat)    # Meow!
make_it_speak(duck)   # Quack!
make_it_speak(robot)  # Beep boop!

# Even works with different types if they have the method
class Human:
    def speak(self):
        return "Hello!"

make_it_speak(Human())  # Hello!
```

## Method Overriding Polymorphism

Method overriding is when a child class provides a specific implementation of a method that is already defined in its parent class.

```python
class PaymentMethod:
    """Base class for payment methods"""
    
    def __init__(self, amount):
        self.amount = amount
    
    def process_payment(self):
        """This method will be overridden by child classes"""
        return "Processing payment..."
    
    def get_receipt(self):
        return f"Payment of ${self.amount:.2f} processed"

class CreditCard(PaymentMethod):
    def __init__(self, amount, card_number, cvv):
        super().__init__(amount)
        self.card_number = card_number
        self.cvv = cvv
    
    def process_payment(self):
        # Specific implementation for credit card
        return f"Processing credit card payment of ${self.amount:.2f}..."

class PayPal(PaymentMethod):
    def __init__(self, amount, email):
        super().__init__(amount)
        self.email = email
    
    def process_payment(self):
        # Specific implementation for PayPal
        return f"Processing PayPal payment of ${self.amount:.2f} to {self.email}..."

class Bitcoin(PaymentMethod):
    def __init__(self, amount, wallet_address):
        super().__init__(amount)
        self.wallet_address = wallet_address
    
    def process_payment(self):
        # Specific implementation for Bitcoin
        return f"Processing Bitcoin payment of ${self.amount:.2f} to wallet {self.wallet_address[:8]}..."

# Polymorphic function - treats all payment methods uniformly
def checkout(payment_method: PaymentMethod):
    """Accepts any PaymentMethod and processes it"""
    print(payment_method.process_payment())
    print(payment_method.get_receipt())
    print("-" * 50)

# Usage - same function, different behaviors
credit_card = CreditCard(99.99, "1234-5678-9012-3456", "123")
paypal = PayPal(49.99, "user@example.com")
bitcoin = Bitcoin(199.99, "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")

checkout(credit_card)
checkout(paypal)
checkout(bitcoin)
```

**Output:**
```
Processing credit card payment of $99.99...
Payment of $99.99 processed
--------------------------------------------------
Processing PayPal payment of $49.99 to user@example.com...
Payment of $49.99 processed
--------------------------------------------------
Processing Bitcoin payment of $199.99 to wallet 1A1zP1eP...
Payment of $199.99 processed
--------------------------------------------------
```

## Polymorphism with Abstract Base Classes

Using abstract base classes (ABC) from the `abc` module enforces that child classes implement specific methods.

```python
from abc import ABC, abstractmethod

class Vehicle(ABC):
    """Abstract base class for vehicles"""
    
    def __init__(self, brand, model):
        self.brand = brand
        self.model = model
    
    @abstractmethod
    def start_engine(self):
        """Must be implemented by all child classes"""
        pass
    
    @abstractmethod
    def stop_engine(self):
        """Must be implemented by all child classes"""
        pass
    
    def display_info(self):
        return f"{self.brand} {self.model}"

class Car(Vehicle):
    def start_engine(self):
        return f"{self.display_info()}: Engine started. Vroom!"
    
    def stop_engine(self):
        return f"{self.display_info()}: Engine stopped."

class ElectricCar(Vehicle):
    def start_engine(self):
        return f"{self.display_info()}: Electric motor activated. Silent start!"
    
    def stop_engine(self):
        return f"{self.display_info()}: Electric motor deactivated."

class Motorcycle(Vehicle):
    def start_engine(self):
        return f"{self.display_info()}: Motorcycle engine roaring!"
    
    def stop_engine(self):
        return f"{self.display_info()}: Engine off."

# Polymorphic function working with abstract interface
def start_journey(vehicle: Vehicle):
    """Works with any Vehicle subclass"""
    print(vehicle.start_engine())

def end_journey(vehicle: Vehicle):
    """Works with any Vehicle subclass"""
    print(vehicle.stop_engine())

# Usage
vehicles = [
    Car("Toyota", "Camry"),
    ElectricCar("Tesla", "Model 3"),
    Motorcycle("Harley-Davidson", "Street 750")
]

print("Starting all vehicles:")
for vehicle in vehicles:
    start_journey(vehicle)

print("\nStopping all vehicles:")
for vehicle in vehicles:
    end_journey(vehicle)

# This will raise TypeError because Vehicle is abstract:
# vehicle = Vehicle("Generic", "Vehicle")  # Error!
```

## Operator Overloading

Python allows you to define custom behavior for built-in operators (+, -, *, ==, etc.) through special methods (also called magic methods or dunder methods).

### Common Operator Overloading Methods

| Operator | Method | Example |
|----------|--------|---------|
| + | `__add__` | `a + b` |
| - | `__sub__` | `a - b` |
| * | `__mul__` | `a * b` |
| / | `__truediv__` | `a / b` |
| == | `__eq__` | `a == b` |
| < | `__lt__` | `a < b` |
| > | `__gt__` | `a > b` |
| <= | `__le__` | `a <= b` |
| >= | `__ge__` | `a >= b` |
| [] | `__getitem__` | `a[key]` |
| len() | `__len__` | `len(a)` |

### Example: Vector Class

```python
class Vector:
    """2D Vector with operator overloading"""
    
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def __add__(self, other):
        """Overload + operator"""
        if isinstance(other, Vector):
            return Vector(self.x + other.x, self.y + other.y)
        raise TypeError("Can only add Vector to Vector")
    
    def __sub__(self, other):
        """Overload - operator"""
        if isinstance(other, Vector):
            return Vector(self.x - other.x, self.y - other.y)
        raise TypeError("Can only subtract Vector from Vector")
    
    def __mul__(self, scalar):
        """Overload * operator for scalar multiplication"""
        if isinstance(scalar, (int, float)):
            return Vector(self.x * scalar, self.y * scalar)
        raise TypeError("Can only multiply Vector by scalar")
    
    def __eq__(self, other):
        """Overload == operator"""
        if isinstance(other, Vector):
            return self.x == other.x and self.y == other.y
        return False
    
    def __str__(self):
        """String representation"""
        return f"Vector({self.x}, {self.y})"
    
    def __repr__(self):
        """Official representation"""
        return f"Vector({self.x}, {self.y})"
    
    def magnitude(self):
        """Calculate vector magnitude"""
        return (self.x**2 + self.y**2) ** 0.5

# Usage
v1 = Vector(3, 4)
v2 = Vector(1, 2)

# Operator overloading in action
v3 = v1 + v2      # Uses __add__
print(f"{v1} + {v2} = {v3}")  # Vector(3, 4) + Vector(1, 2) = Vector(4, 6)

v4 = v1 - v2      # Uses __sub__
print(f"{v1} - {v2} = {v4}")  # Vector(3, 4) - Vector(1, 2) = Vector(2, 2)

v5 = v1 * 3       # Uses __mul__
print(f"{v1} * 3 = {v5}")     # Vector(3, 4) * 3 = Vector(9, 12)

# Comparison
print(f"{v1} == {v2}: {v1 == v2}")  # False
print(f"{v1} == Vector(3, 4): {v1 == Vector(3, 4)}")  # True

print(f"Magnitude of {v1}: {v1.magnitude():.2f}")  # 5.00
```

### Example: Money Class

```python
class Money:
    """Represents money with operator overloading"""
    
    def __init__(self, amount, currency="USD"):
        self.amount = round(amount, 2)
        self.currency = currency
    
    def __add__(self, other):
        """Add two Money objects"""
        if isinstance(other, Money):
            if self.currency != other.currency:
                raise ValueError(f"Cannot add {self.currency} and {other.currency}")
            return Money(self.amount + other.amount, self.currency)
        raise TypeError("Can only add Money to Money")
    
    def __sub__(self, other):
        """Subtract two Money objects"""
        if isinstance(other, Money):
            if self.currency != other.currency:
                raise ValueError(f"Cannot subtract {self.currency} and {other.currency}")
            return Money(self.amount - other.amount, self.currency)
        raise TypeError("Can only subtract Money from Money")
    
    def __mul__(self, multiplier):
        """Multiply Money by a number"""
        if isinstance(multiplier, (int, float)):
            return Money(self.amount * multiplier, self.currency)
        raise TypeError("Can only multiply Money by number")
    
    def __truediv__(self, divisor):
        """Divide Money by a number"""
        if isinstance(divisor, (int, float)):
            if divisor == 0:
                raise ValueError("Cannot divide by zero")
            return Money(self.amount / divisor, self.currency)
        raise TypeError("Can only divide Money by number")
    
    def __eq__(self, other):
        """Check equality"""
        if isinstance(other, Money):
            return self.amount == other.amount and self.currency == other.currency
        return False
    
    def __lt__(self, other):
        """Less than comparison"""
        if isinstance(other, Money):
            if self.currency != other.currency:
                raise ValueError("Cannot compare different currencies")
            return self.amount < other.amount
        raise TypeError("Can only compare Money to Money")
    
    def __le__(self, other):
        """Less than or equal comparison"""
        return self == other or self < other
    
    def __gt__(self, other):
        """Greater than comparison"""
        if isinstance(other, Money):
            if self.currency != other.currency:
                raise ValueError("Cannot compare different currencies")
            return self.amount > other.amount
        raise TypeError("Can only compare Money to Money")
    
    def __ge__(self, other):
        """Greater than or equal comparison"""
        return self == other or self > other
    
    def __str__(self):
        """String representation"""
        return f"{self.currency} ${self.amount:.2f}"
    
    def __repr__(self):
        """Official representation"""
        return f"Money({self.amount}, '{self.currency}')"

# Usage
price1 = Money(19.99)
price2 = Money(5.50)
tax_rate = 0.08

print(f"Item 1: {price1}")
print(f"Item 2: {price2}")

# Addition
subtotal = price1 + price2
print(f"Subtotal: {subtotal}")

# Multiplication
tax = subtotal * tax_rate
print(f"Tax (8%): {tax}")

# More addition
total = subtotal + tax
print(f"Total: {total}")

# Division
split = total / 2
print(f"Split between 2 people: {split}")

# Comparison
if price1 > price2:
    print(f"{price1} is more expensive than {price2}")

# Equality
discount = Money(5.50)
if price2 == discount:
    print(f"Discount applied: {discount}")
```

## Polymorphism in Real-World Scenarios

### Example: Data Storage System

```python
from abc import ABC, abstractmethod
from datetime import datetime
import json

class DataStorage(ABC):
    """Abstract base class for different storage types"""
    
    @abstractmethod
    def save(self, data, filename):
        """Save data to storage"""
        pass
    
    @abstractmethod
    def load(self, filename):
        """Load data from storage"""
        pass
    
    @abstractmethod
    def exists(self, filename):
        """Check if file exists"""
        pass

class JSONStorage(DataStorage):
    """Store data in JSON format"""
    
    def save(self, data, filename):
        try:
            with open(f"{filename}.json", 'w') as f:
                json.dump(data, f, indent=2)
            return f"Data saved to {filename}.json"
        except Exception as e:
            return f"Error saving JSON: {e}"
    
    def load(self, filename):
        try:
            with open(f"{filename}.json", 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return None
        except Exception as e:
            return f"Error loading JSON: {e}"
    
    def exists(self, filename):
        import os
        return os.path.exists(f"{filename}.json")

class CSVStorage(DataStorage):
    """Store data in CSV format"""
    
    def save(self, data, filename):
        try:
            import csv
            with open(f"{filename}.csv", 'w', newline='') as f:
                if data:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)
            return f"Data saved to {filename}.csv"
        except Exception as e:
            return f"Error saving CSV: {e}"
    
    def load(self, filename):
        try:
            import csv
            with open(f"{filename}.csv", 'r') as f:
                reader = csv.DictReader(f)
                return list(reader)
        except FileNotFoundError:
            return None
        except Exception as e:
            return f"Error loading CSV: {e}"
    
    def exists(self, filename):
        import os
        return os.path.exists(f"{filename}.csv")

class DatabaseStorage(DataStorage):
    """Store data in database (simulated)"""
    
    def __init__(self):
        self.database = {}  # Simulated database
    
    def save(self, data, filename):
        self.database[filename] = {
            'data': data,
            'timestamp': datetime.now().isoformat()
        }
        return f"Data saved to database table: {filename}"
    
    def load(self, filename):
        if filename in self.database:
            return self.database[filename]['data']
        return None
    
    def exists(self, filename):
        return filename in self.database

# Polymorphic storage manager
class StorageManager:
    """Manages different storage backends polymorphically"""
    
    def __init__(self, storage: DataStorage):
        self.storage = storage
    
    def save_user_data(self, users, filename):
        """Save user data using any storage backend"""
        print(f"Saving with {self.storage.__class__.__name__}...")
        result = self.storage.save(users, filename)
        print(result)
    
    def load_user_data(self, filename):
        """Load user data using any storage backend"""
        print(f"Loading with {self.storage.__class__.__name__}...")
        data = self.storage.load(filename)
        if data:
            print(f"Loaded {len(data) if isinstance(data, list) else 'N/A'} records")
            return data
        else:
            print("No data found")
            return None

# Usage - same interface, different storage methods
users = [
    {"id": 1, "name": "Alice", "email": "alice@example.com"},
    {"id": 2, "name": "Bob", "email": "bob@example.com"},
    {"id": 3, "name": "Carol", "email": "carol@example.com"}
]

# JSON Storage
json_storage = StorageManager(JSONStorage())
json_storage.save_user_data(users, "users")

# CSV Storage
csv_storage = StorageManager(CSVStorage())
csv_storage.save_user_data(users, "users")

# Database Storage
db_storage = StorageManager(DatabaseStorage())
db_storage.save_user_data(users, "users")

# Loading works the same way regardless of storage type
print("\nLoading data:")
json_storage.load_user_data("users")
csv_storage.load_user_data("users")
db_storage.load_user_data("users")
```

## Benefits of Polymorphism

### 1. **Flexibility and Extensibility**
Add new classes without modifying existing code:

```python
# Easy to add new payment methods without changing checkout()
class ApplePay(PaymentMethod):
    def process_payment(self):
        return "Processing Apple Pay..."

# Works immediately with existing polymorphic functions
checkout(ApplePay(75.00))
```

### 2. **Code Reusability**
Write functions that work with many types:

```python
def process_all_payments(payments: list[PaymentMethod]):
    """Process any type of payment"""
    total = sum(p.amount for p in payments)
    for payment in payments:
        print(payment.process_payment())
    return total
```

### 3. **Maintainability**
Changes to specific implementations don't affect the polymorphic interface.

### 4. **Testability**
Easy to create mock objects for testing:

```python
class MockPayment(PaymentMethod):
    """Mock payment for testing"""
    def process_payment(self):
        return "Mock payment processed"

# Use in tests without touching real payment systems
```

## Common Pitfalls

### 1. Violating the Liskov Substitution Principle

```python
# BAD: Child class changes expected behavior
class SpecialPayment(PaymentMethod):
    def process_payment(self):
        raise NotImplementedError("Cannot process this payment!")
        # This breaks polymorphism - not substitutable!

# GOOD: Maintain expected behavior
class SpecialPayment(PaymentMethod):
    def process_payment(self):
        return f"Special processing for ${self.amount:.2f}"
```

### 2. Checking Types Instead of Using Polymorphism

```python
# BAD: Type checking defeats the purpose of polymorphism
def bad_checkout(payment):
    if isinstance(payment, CreditCard):
        print("Processing credit card...")
    elif isinstance(payment, PayPal):
        print("Processing PayPal...")
    elif isinstance(payment, Bitcoin):
        print("Processing Bitcoin...")

# GOOD: Use polymorphism
def good_checkout(payment: PaymentMethod):
    print(payment.process_payment())  # Let the object handle it!
```

## Summary

**Key Concepts:**
- ✅ Polymorphism allows objects of different classes to be treated uniformly
- ✅ Duck typing: "If it looks like a duck and quacks like a duck..."
- ✅ Method overriding: Child classes provide specific implementations
- ✅ Operator overloading: Define custom behavior for operators
- ✅ Abstract base classes enforce implementation contracts
- ✅ Write code once, works with many types

**Benefits:**
- ✅ Flexible and extensible code
- ✅ Improved code reusability
- ✅ Easier maintenance and testing
- ✅ Reduced code duplication
- ✅ Better abstraction

**Best Practices:**
- ✅ Design interfaces that make sense for all implementations
- ✅ Follow the Liskov Substitution Principle
- ✅ Avoid type checking - let polymorphism work
- ✅ Use abstract base classes for contracts
- ✅ Document expected behavior clearly

In the next section, we'll explore **Encapsulation and Data Hiding**, learning how to protect and control access to class internals!

---

**கற்க கசடற** - Master polymorphism and write flexible, maintainable code!
