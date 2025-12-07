# Abstract Base Classes (ABC)

**கற்க கசடற - Learn Flawlessly**

## Introduction

Abstract Base Classes (ABCs) are classes that cannot be instantiated and are designed to be subclassed. They define a contract or interface that subclasses must implement. Python's `abc` module provides infrastructure for defining ABCs.

ABCs ensure that derived classes implement particular methods from the base class, enforcing a consistent interface across different implementations.

## Why Use Abstract Base Classes?

### 1. **Define Interfaces**
Specify what methods subclasses must implement.

### 2. **Enforce Contracts**
Prevent instantiation of incomplete classes.

### 3. **Documentation**
Clearly communicate required methods to other developers.

### 4. **Type Checking**
Enable isinstance() and issubclass() checks for interfaces.

### 5. **Polymorphism**
Write code that works with any implementation of the interface.

## Basic ABC Example

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    """Abstract base class for shapes"""
    
    @abstractmethod
    def area(self):
        """Calculate area - must be implemented by subclasses"""
        pass
    
    @abstractmethod
    def perimeter(self):
        """Calculate perimeter - must be implemented by subclasses"""
        pass

# This will raise TypeError: Can't instantiate abstract class
# shape = Shape()  # TypeError!

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def area(self):
        return self.width * self.height
    
    def perimeter(self):
        return 2 * (self.width + self.height)

class Circle(Shape):
    def __init__(self, radius):
        self.radius = radius
    
    def area(self):
        return 3.14159 * self.radius ** 2
    
    def perimeter(self):
        return 2 * 3.14159 * self.radius

# Now we can instantiate concrete classes
rect = Rectangle(5, 10)
circle = Circle(7)

print(f"Rectangle area: {rect.area()}")          # 50
print(f"Circle area: {circle.area():.2f}")       # 153.94

# Type checking works
print(isinstance(rect, Shape))     # True
print(isinstance(circle, Shape))   # True
```

## Abstract Methods

### Regular Abstract Methods

```python
from abc import ABC, abstractmethod

class Vehicle(ABC):
    @abstractmethod
    def start_engine(self):
        """Start the vehicle engine"""
        pass
    
    @abstractmethod
    def stop_engine(self):
        """Stop the vehicle engine"""
        pass
    
    # Concrete method (has implementation)
    def honk(self):
        return "Beep beep!"

class Car(Vehicle):
    def start_engine(self):
        return "Car engine started"
    
    def stop_engine(self):
        return "Car engine stopped"

car = Car()
print(car.start_engine())  # Car engine started
print(car.honk())          # Beep beep!
```

### Abstract Class Methods

```python
from abc import ABC, abstractmethod

class DatabaseConnection(ABC):
    @classmethod
    @abstractmethod
    def connect(cls, connection_string):
        """Connect to database - must be implemented"""
        pass
    
    @abstractmethod
    def execute(self, query):
        """Execute query - must be implemented"""
        pass

class MySQLConnection(DatabaseConnection):
    @classmethod
    def connect(cls, connection_string):
        print(f"Connecting to MySQL: {connection_string}")
        return cls()
    
    def execute(self, query):
        return f"MySQL executing: {query}"

class PostgreSQLConnection(DatabaseConnection):
    @classmethod
    def connect(cls, connection_string):
        print(f"Connecting to PostgreSQL: {connection_string}")
        return cls()
    
    def execute(self, query):
        return f"PostgreSQL executing: {query}"

# Usage
mysql = MySQLConnection.connect("localhost:3306")
postgres = PostgreSQLConnection.connect("localhost:5432")

print(mysql.execute("SELECT * FROM users"))
print(postgres.execute("SELECT * FROM users"))
```

### Abstract Static Methods

```python
from abc import ABC, abstractmethod

class DataValidator(ABC):
    @staticmethod
    @abstractmethod
    def validate(data):
        """Validate data - must be implemented"""
        pass

class EmailValidator(DataValidator):
    @staticmethod
    def validate(data):
        return '@' in data and '.' in data

class PhoneValidator(DataValidator):
    @staticmethod
    def validate(data):
        return data.replace('-', '').replace(' ', '').isdigit()

print(EmailValidator.validate("user@example.com"))  # True
print(PhoneValidator.validate("123-456-7890"))      # True
```

### Abstract Properties

```python
from abc import ABC, abstractmethod

class Person(ABC):
    @property
    @abstractmethod
    def full_name(self):
        """Full name property - must be implemented"""
        pass
    
    @property
    @abstractmethod
    def age(self):
        """Age property - must be implemented"""
        pass

class Employee(Person):
    def __init__(self, first_name, last_name, birth_year):
        self.first_name = first_name
        self.last_name = last_name
        self.birth_year = birth_year
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    @property
    def age(self):
        from datetime import datetime
        return datetime.now().year - self.birth_year

emp = Employee("John", "Doe", 1990)
print(emp.full_name)  # John Doe
print(emp.age)        # 35 (in 2025)
```

## Practical Example: Payment System

```python
from abc import ABC, abstractmethod
from datetime import datetime

class PaymentProcessor(ABC):
    """Abstract base class for payment processors"""
    
    @abstractmethod
    def process_payment(self, amount):
        """Process payment - must be implemented"""
        pass
    
    @abstractmethod
    def refund(self, transaction_id, amount):
        """Process refund - must be implemented"""
        pass
    
    @abstractmethod
    def get_transaction_status(self, transaction_id):
        """Get transaction status - must be implemented"""
        pass
    
    # Concrete method with default implementation
    def log_transaction(self, transaction_type, amount, status):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {transaction_type}: ${amount:.2f} - {status}")

class CreditCardProcessor(PaymentProcessor):
    def __init__(self):
        self.transactions = {}
    
    def process_payment(self, amount):
        transaction_id = f"CC{len(self.transactions) + 1:06d}"
        self.transactions[transaction_id] = {
            'type': 'payment',
            'amount': amount,
            'status': 'completed',
            'timestamp': datetime.now()
        }
        self.log_transaction("Credit Card Payment", amount, "Completed")
        return transaction_id
    
    def refund(self, transaction_id, amount):
        if transaction_id in self.transactions:
            refund_id = f"RF{len(self.transactions) + 1:06d}"
            self.transactions[refund_id] = {
                'type': 'refund',
                'amount': amount,
                'original_id': transaction_id,
                'status': 'completed',
                'timestamp': datetime.now()
            }
            self.log_transaction("Credit Card Refund", amount, "Completed")
            return refund_id
        return None
    
    def get_transaction_status(self, transaction_id):
        if transaction_id in self.transactions:
            return self.transactions[transaction_id]['status']
        return "Not found"

class PayPalProcessor(PaymentProcessor):
    def __init__(self):
        self.transactions = {}
    
    def process_payment(self, amount):
        transaction_id = f"PP{len(self.transactions) + 1:06d}"
        self.transactions[transaction_id] = {
            'type': 'payment',
            'amount': amount,
            'status': 'completed'
        }
        self.log_transaction("PayPal Payment", amount, "Completed")
        return transaction_id
    
    def refund(self, transaction_id, amount):
        if transaction_id in self.transactions:
            refund_id = f"PPRF{len(self.transactions) + 1:06d}"
            self.transactions[refund_id] = {
                'type': 'refund',
                'amount': amount,
                'original_id': transaction_id,
                'status': 'pending'
            }
            self.log_transaction("PayPal Refund", amount, "Pending")
            return refund_id
        return None
    
    def get_transaction_status(self, transaction_id):
        return self.transactions.get(transaction_id, {}).get('status', 'Not found')

# Polymorphic function
def process_order(processor: PaymentProcessor, amount: float):
    """Process order using any payment processor"""
    print(f"\nProcessing ${amount:.2f} payment...")
    transaction_id = processor.process_payment(amount)
    print(f"Transaction ID: {transaction_id}")
    print(f"Status: {processor.get_transaction_status(transaction_id)}")
    return transaction_id

# Usage
cc_processor = CreditCardProcessor()
paypal_processor = PayPalProcessor()

# Both work with same interface
tx1 = process_order(cc_processor, 99.99)
tx2 = process_order(paypal_processor, 149.99)

# Refunds
print("\nProcessing refunds...")
cc_processor.refund(tx1, 99.99)
paypal_processor.refund(tx2, 149.99)
```

## Real-World Example: Data Storage Interface

```python
from abc import ABC, abstractmethod
import json

class DataStorage(ABC):
    """Abstract interface for data storage"""
    
    @abstractmethod
    def save(self, key, data):
        """Save data with key"""
        pass
    
    @abstractmethod
    def load(self, key):
        """Load data by key"""
        pass
    
    @abstractmethod
    def delete(self, key):
        """Delete data by key"""
        pass
    
    @abstractmethod
    def exists(self, key):
        """Check if key exists"""
        pass
    
    @abstractmethod
    def list_keys(self):
        """List all keys"""
        pass

class MemoryStorage(DataStorage):
    """In-memory storage implementation"""
    
    def __init__(self):
        self._storage = {}
    
    def save(self, key, data):
        self._storage[key] = data
        return True
    
    def load(self, key):
        return self._storage.get(key)
    
    def delete(self, key):
        if key in self._storage:
            del self._storage[key]
            return True
        return False
    
    def exists(self, key):
        return key in self._storage
    
    def list_keys(self):
        return list(self._storage.keys())

class FileStorage(DataStorage):
    """File-based storage implementation"""
    
    def __init__(self, directory="data"):
        self.directory = directory
        import os
        os.makedirs(directory, exist_ok=True)
    
    def _get_filepath(self, key):
        return f"{self.directory}/{key}.json"
    
    def save(self, key, data):
        filepath = self._get_filepath(key)
        with open(filepath, 'w') as f:
            json.dump(data, f)
        return True
    
    def load(self, key):
        filepath = self._get_filepath(key)
        try:
            with open(filepath, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return None
    
    def delete(self, key):
        filepath = self._get_filepath(key)
        try:
            import os
            os.remove(filepath)
            return True
        except FileNotFoundError:
            return False
    
    def exists(self, key):
        import os
        return os.path.exists(self._get_filepath(key))
    
    def list_keys(self):
        import os
        files = os.listdir(self.directory)
        return [f.replace('.json', '') for f in files if f.endswith('.json')]

# Application layer - works with any storage
class UserManager:
    def __init__(self, storage: DataStorage):
        self.storage = storage
    
    def create_user(self, user_id, name, email):
        user_data = {'name': name, 'email': email}
        self.storage.save(f"user_{user_id}", user_data)
        print(f"User created: {name}")
    
    def get_user(self, user_id):
        return self.storage.load(f"user_{user_id}")
    
    def delete_user(self, user_id):
        if self.storage.delete(f"user_{user_id}"):
            print(f"User {user_id} deleted")
            return True
        return False
    
    def list_users(self):
        keys = self.storage.list_keys()
        return [k.replace('user_', '') for k in keys if k.startswith('user_')]

# Usage - same code, different storage
print("=== Using Memory Storage ===")
memory_manager = UserManager(MemoryStorage())
memory_manager.create_user(1, "Alice", "alice@example.com")
memory_manager.create_user(2, "Bob", "bob@example.com")
print(f"Users: {memory_manager.list_users()}")
print(f"User 1: {memory_manager.get_user(1)}")

print("\n=== Using File Storage ===")
file_manager = UserManager(FileStorage())
file_manager.create_user(1, "Carol", "carol@example.com")
file_manager.create_user(2, "David", "david@example.com")
print(f"Users: {file_manager.list_users()}")
print(f"User 1: {file_manager.get_user(1)}")
```

## Checking ABC Compliance

```python
from abc import ABC, abstractmethod

class Plugin(ABC):
    @abstractmethod
    def initialize(self):
        pass
    
    @abstractmethod
    def execute(self):
        pass

# Check if class implements all abstract methods
class IncompletePlugin(Plugin):
    def initialize(self):
        pass
    # Missing execute() method!

# This will raise TypeError
try:
    plugin = IncompletePlugin()
except TypeError as e:
    print(f"Error: {e}")
    # Error: Can't instantiate abstract class IncompletePlugin 
    # with abstract method execute

# Complete implementation
class CompletePlugin(Plugin):
    def initialize(self):
        print("Plugin initialized")
    
    def execute(self):
        print("Plugin executed")

plugin = CompletePlugin()  # Works!
plugin.initialize()
plugin.execute()
```

## Virtual Subclasses

Register a class as a "virtual subclass" without inheritance:

```python
from abc import ABC

class Sized(ABC):
    @abstractmethod
    def __len__(self):
        pass

# Register list as virtual subclass
Sized.register(list)

# Now isinstance works!
print(issubclass(list, Sized))      # True
print(isinstance([1, 2, 3], Sized)) # True

# Custom class registration
class MyCollection:
    def __init__(self):
        self.items = []
    
    def __len__(self):
        return len(self.items)

Sized.register(MyCollection)
collection = MyCollection()
print(isinstance(collection, Sized))  # True
```

## Best Practices

### 1. Keep ABCs Focused
```python
# GOOD: Focused interface
class Readable(ABC):
    @abstractmethod
    def read(self):
        pass

class Writable(ABC):
    @abstractmethod
    def write(self, data):
        pass

# Combine when needed
class ReadWrite(Readable, Writable):
    pass
```

### 2. Provide Concrete Helper Methods
```python
class Collection(ABC):
    @abstractmethod
    def add(self, item):
        pass
    
    @abstractmethod
    def remove(self, item):
        pass
    
    # Concrete helper method
    def add_many(self, items):
        for item in items:
            self.add(item)
```

### 3. Document Expected Behavior
```python
class Cache(ABC):
    @abstractmethod
    def get(self, key):
        """
        Retrieve value for key.
        
        Returns:
            Value if key exists, None otherwise.
        """
        pass
```

## Summary

**Key Concepts:**
- ✅ ABCs define interfaces/contracts
- ✅ Cannot instantiate abstract classes
- ✅ Subclasses must implement all abstract methods
- ✅ Use `@abstractmethod` decorator
- ✅ Can have concrete methods alongside abstract ones
- ✅ Works with isinstance() and issubclass()

**Benefits:**
- ✅ Enforces consistent interfaces
- ✅ Prevents incomplete implementations
- ✅ Self-documenting code
- ✅ Enables polymorphism
- ✅ Catches errors at instantiation time

**Best Practices:**
- ✅ Keep ABCs focused and cohesive
- ✅ Provide concrete helper methods
- ✅ Document expected behavior
- ✅ Use for defining public APIs
- ✅ Combine with type hints for clarity

---

**கற்க கசடற** - Master abstract base classes and design robust interfaces!
