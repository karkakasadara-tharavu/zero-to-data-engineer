# Property Decorators and Descriptors

**கற்க கசடற - Learn Flawlessly**

## Introduction

Property decorators and descriptors are powerful Python features that provide fine-grained control over attribute access. They allow you to add validation, computation, and other logic when getting, setting, or deleting attributes, while maintaining a clean, Pythonic interface.

## Property Decorators

We've already seen `@property` in the encapsulation section, but let's dive deeper into its capabilities.

### Basic Property Pattern

```python
class Temperature:
    def __init__(self, celsius):
        self._celsius = celsius
    
    @property
    def celsius(self):
        """Getter"""
        return self._celsius
    
    @celsius.setter
    def celsius(self, value):
        """Setter with validation"""
        if value < -273.15:
            raise ValueError("Temperature below absolute zero!")
        self._celsius = value
    
    @celsius.deleter
    def celsius(self):
        """Deleter"""
        print("Deleting celsius attribute")
        del self._celsius

# Usage
temp = Temperature(25)
print(temp.celsius)    # Getter: 25
temp.celsius = 30      # Setter: 30
del temp.celsius       # Deleter: Deleting celsius attribute
```

### Read-Only Properties

```python
from datetime import datetime

class Person:
    def __init__(self, name, birth_year):
        self._name = name
        self._birth_year = birth_year
    
    @property
    def name(self):
        return self._name
    
    @property
    def age(self):
        """Computed read-only property"""
        current_year = datetime.now().year
        return current_year - self._birth_year
    
    @property
    def birth_year(self):
        return self._birth_year

person = Person("Alice", 1990)
print(person.age)        # Computed: 35 (in 2025)
# person.age = 30        # AttributeError: can't set attribute
```

### Cached Properties

```python
from functools import lru_cache

class DataAnalyzer:
    def __init__(self, data):
        self._data = data
        self._stats_cache = None
    
    @property
    def data(self):
        return self._data
    
    @property
    def statistics(self):
        """Expensive computation - cache result"""
        if self._stats_cache is None:
            print("Computing statistics...")
            self._stats_cache = {
                'mean': sum(self._data) / len(self._data),
                'min': min(self._data),
                'max': max(self._data),
                'count': len(self._data)
            }
        return self._stats_cache
    
    def add_value(self, value):
        self._data.append(value)
        self._stats_cache = None  # Invalidate cache

analyzer = DataAnalyzer([1, 2, 3, 4, 5])
print(analyzer.statistics)  # Computing statistics... {'mean': 3.0, ...}
print(analyzer.statistics)  # Uses cached value (no computation)

analyzer.add_value(10)
print(analyzer.statistics)  # Computing statistics... (cache invalidated)
```

### Property with Validation

```python
import re

class User:
    def __init__(self, username, email, age):
        self.username = username
        self.email = email
        self.age = age
    
    @property
    def username(self):
        return self._username
    
    @username.setter
    def username(self, value):
        if not value or len(value) < 3:
            raise ValueError("Username must be at least 3 characters")
        if not value.isalnum():
            raise ValueError("Username must be alphanumeric")
        self._username = value
    
    @property
    def email(self):
        return self._email
    
    @email.setter
    def email(self, value):
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, value):
            raise ValueError("Invalid email format")
        self._email = value
    
    @property
    def age(self):
        return self._age
    
    @age.setter
    def age(self, value):
        if not isinstance(value, int):
            raise TypeError("Age must be an integer")
        if value < 0 or value > 150:
            raise ValueError("Age must be between 0 and 150")
        self._age = value

# Usage with validation
try:
    user = User("ab", "invalid-email", -5)
except ValueError as e:
    print(f"Error: {e}")

user = User("alice123", "alice@example.com", 25)
print(f"{user.username}: {user.email}, age {user.age}")
```

## Descriptors

Descriptors are a more powerful, reusable way to manage attribute access. They allow you to define get, set, and delete behavior in a separate class that can be reused across multiple attributes and classes.

### Descriptor Protocol

A descriptor is any object that defines one or more of these methods:
- `__get__(self, instance, owner)`: Called to get the attribute value
- `__set__(self, instance, value)`: Called to set the attribute value
- `__delete__(self, instance)`: Called to delete the attribute

### Basic Descriptor Example

```python
class Descriptor:
    def __init__(self, name=None):
        self.name = name
    
    def __set_name__(self, owner, name):
        """Called automatically when descriptor is assigned to a class attribute"""
        self.name = name
    
    def __get__(self, instance, owner):
        """Called when accessing the attribute"""
        if instance is None:
            return self
        return instance.__dict__.get(self.name)
    
    def __set__(self, instance, value):
        """Called when setting the attribute"""
        instance.__dict__[self.name] = value
    
    def __delete__(self, instance):
        """Called when deleting the attribute"""
        del instance.__dict__[self.name]

class MyClass:
    attribute = Descriptor()

obj = MyClass()
obj.attribute = 42      # Calls __set__
print(obj.attribute)    # Calls __get__: 42
del obj.attribute       # Calls __delete__
```

### Practical Descriptor: Type Validation

```python
class TypedProperty:
    """Descriptor that validates type"""
    
    def __init__(self, name, expected_type):
        self.name = name
        self.expected_type = expected_type
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        return instance.__dict__.get(self.name)
    
    def __set__(self, instance, value):
        if not isinstance(value, self.expected_type):
            raise TypeError(f"{self.name} must be {self.expected_type.__name__}")
        instance.__dict__[self.name] = value

class Person:
    name = TypedProperty('name', str)
    age = TypedProperty('age', int)
    
    def __init__(self, name, age):
        self.name = name
        self.age = age

# Usage
person = Person("Alice", 30)
print(f"{person.name}, {person.age}")

try:
    person.age = "thirty"  # TypeError: age must be int
except TypeError as e:
    print(f"Error: {e}")
```

### Validated Descriptor

```python
class ValidatedString:
    """Descriptor with string validation"""
    
    def __init__(self, minsize=0, maxsize=None, predicate=None):
        self.minsize = minsize
        self.maxsize = maxsize
        self.predicate = predicate
    
    def __set_name__(self, owner, name):
        self.name = name
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        return instance.__dict__.get(self.name)
    
    def __set__(self, instance, value):
        if not isinstance(value, str):
            raise TypeError(f"{self.name} must be a string")
        
        if len(value) < self.minsize:
            raise ValueError(f"{self.name} must be at least {self.minsize} characters")
        
        if self.maxsize is not None and len(value) > self.maxsize:
            raise ValueError(f"{self.name} must be at most {self.maxsize} characters")
        
        if self.predicate is not None and not self.predicate(value):
            raise ValueError(f"{self.name} failed validation")
        
        instance.__dict__[self.name] = value

class User:
    username = ValidatedString(minsize=3, maxsize=20, predicate=str.isalnum)
    password = ValidatedString(minsize=8)
    
    def __init__(self, username, password):
        self.username = username
        self.password = password

# Usage
user = User("alice123", "securepass123")
print(f"User: {user.username}")

try:
    user.username = "ab"  # ValueError: too short
except ValueError as e:
    print(f"Error: {e}")

try:
    user.username = "user@123"  # ValueError: not alphanumeric
except ValueError as e:
    print(f"Error: {e}")
```

### Number Range Descriptor

```python
class NumberRange:
    """Descriptor for numeric values within a range"""
    
    def __init__(self, minvalue=None, maxvalue=None):
        self.minvalue = minvalue
        self.maxvalue = maxvalue
    
    def __set_name__(self, owner, name):
        self.name = name
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        return instance.__dict__.get(self.name)
    
    def __set__(self, instance, value):
        if not isinstance(value, (int, float)):
            raise TypeError(f"{self.name} must be a number")
        
        if self.minvalue is not None and value < self.minvalue:
            raise ValueError(f"{self.name} must be >= {self.minvalue}")
        
        if self.maxvalue is not None and value > self.maxvalue:
            raise ValueError(f"{self.name} must be <= {self.maxvalue}")
        
        instance.__dict__[self.name] = value

class Product:
    price = NumberRange(minvalue=0)
    quantity = NumberRange(minvalue=0, maxvalue=10000)
    discount = NumberRange(minvalue=0, maxvalue=100)
    
    def __init__(self, name, price, quantity, discount=0):
        self.name = name
        self.price = price
        self.quantity = quantity
        self.discount = discount
    
    def total_value(self):
        return self.price * self.quantity * (1 - self.discount / 100)

# Usage
product = Product("Laptop", 999.99, 50, 10)
print(f"{product.name}: ${product.price} x {product.quantity} = ${product.total_value():.2f}")

try:
    product.price = -100  # ValueError: price must be >= 0
except ValueError as e:
    print(f"Error: {e}")

try:
    product.discount = 150  # ValueError: discount must be <= 100
except ValueError as e:
    print(f"Error: {e}")
```

## Comprehensive Example: Form Validation

```python
class ValidatedField:
    """Base descriptor for validated fields"""
    
    def __set_name__(self, owner, name):
        self.name = name
        self.private_name = f'_{name}'
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        return getattr(instance, self.private_name, None)
    
    def __set__(self, instance, value):
        self.validate(value)
        setattr(instance, self.private_name, value)
    
    def validate(self, value):
        """Override in subclasses"""
        pass

class StringField(ValidatedField):
    """Validated string field"""
    
    def __init__(self, minsize=0, maxsize=None):
        self.minsize = minsize
        self.maxsize = maxsize
    
    def validate(self, value):
        if not isinstance(value, str):
            raise TypeError(f"{self.name} must be a string")
        if len(value) < self.minsize:
            raise ValueError(f"{self.name} must be at least {self.minsize} characters")
        if self.maxsize and len(value) > self.maxsize:
            raise ValueError(f"{self.name} must be at most {self.maxsize} characters")

class EmailField(ValidatedField):
    """Email validation field"""
    
    def validate(self, value):
        if not isinstance(value, str):
            raise TypeError(f"{self.name} must be a string")
        if '@' not in value or '.' not in value.split('@')[-1]:
            raise ValueError(f"{self.name} must be a valid email")

class IntegerField(ValidatedField):
    """Validated integer field"""
    
    def __init__(self, minvalue=None, maxvalue=None):
        self.minvalue = minvalue
        self.maxvalue = maxvalue
    
    def validate(self, value):
        if not isinstance(value, int):
            raise TypeError(f"{self.name} must be an integer")
        if self.minvalue is not None and value < self.minvalue:
            raise ValueError(f"{self.name} must be >= {self.minvalue}")
        if self.maxvalue is not None and value > self.maxvalue:
            raise ValueError(f"{self.name} must be <= {self.maxvalue}")

class RegistrationForm:
    """Registration form with validated fields"""
    
    username = StringField(minsize=3, maxsize=20)
    email = EmailField()
    age = IntegerField(minvalue=13, maxvalue=120)
    password = StringField(minsize=8)
    
    def __init__(self, username, email, age, password):
        self.username = username
        self.email = email
        self.age = age
        self.password = password
    
    def to_dict(self):
        return {
            'username': self.username,
            'email': self.email,
            'age': self.age
        }
    
    def __repr__(self):
        return f"RegistrationForm(username='{self.username}', email='{self.email}', age={self.age})"

# Usage
try:
    form = RegistrationForm("alice123", "alice@example.com", 25, "secure123")
    print(f"Valid form: {form}")
    print(f"Data: {form.to_dict()}")
except (TypeError, ValueError) as e:
    print(f"Validation error: {e}")

# Test validation
test_cases = [
    ("ab", "alice@example.com", 25, "secure123"),  # username too short
    ("alice123", "invalid-email", 25, "secure123"),  # invalid email
    ("alice123", "alice@example.com", 10, "secure123"),  # age too low
    ("alice123", "alice@example.com", 25, "short"),  # password too short
]

for username, email, age, password in test_cases:
    try:
        form = RegistrationForm(username, email, age, password)
        print(f"✓ Valid: {form}")
    except (TypeError, ValueError) as e:
        print(f"✗ Invalid: {e}")
```

## Property vs Descriptor: When to Use Which?

### Use Properties When:
- ✅ Single attribute with simple logic
- ✅ Class-specific behavior
- ✅ Quick, one-off validation
- ✅ Computed attributes

### Use Descriptors When:
- ✅ Reusable validation logic across multiple classes
- ✅ Multiple attributes need same validation
- ✅ Complex attribute management
- ✅ Building frameworks or libraries

## Advanced: Lazy Properties

```python
class LazyProperty:
    """Property that computes value once and caches it"""
    
    def __init__(self, function):
        self.function = function
        self.name = function.__name__
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        
        # Compute value and cache it
        value = self.function(instance)
        setattr(instance, self.name, value)
        return value

class DataProcessor:
    def __init__(self, filename):
        self.filename = filename
    
    @LazyProperty
    def data(self):
        """Expensive data loading - only done once"""
        print(f"Loading data from {self.filename}...")
        # Simulate expensive operation
        return [1, 2, 3, 4, 5] * 1000
    
    @LazyProperty
    def statistics(self):
        """Expensive computation - only done once"""
        print("Computing statistics...")
        return {
            'mean': sum(self.data) / len(self.data),
            'count': len(self.data)
        }

processor = DataProcessor("data.csv")
print("Processor created")
print(processor.data[:5])       # Loading data... [1, 2, 3, 4, 5]
print(processor.data[:5])       # Uses cached value (no loading)
print(processor.statistics)     # Computing statistics...
print(processor.statistics)     # Uses cached value
```

## Summary

**Key Concepts:**
- ✅ Properties provide Pythonic attribute access with validation
- ✅ `@property`, `@setter`, `@deleter` decorators
- ✅ Descriptors offer reusable attribute management
- ✅ Descriptor protocol: `__get__`, `__set__`, `__delete__`
- ✅ Use properties for simple cases, descriptors for reusability
- ✅ Lazy properties for expensive computations

**Benefits:**
- ✅ Clean, attribute-like syntax
- ✅ Automatic validation
- ✅ Computed attributes
- ✅ Code reusability (descriptors)
- ✅ Encapsulation without ugly getters/setters

**Best Practices:**
- ✅ Validate in setters
- ✅ Use descriptors for repeated patterns
- ✅ Cache expensive computations
- ✅ Document property behavior
- ✅ Prefer properties over traditional getters/setters

---

**கற்க கசடற** - Master properties and descriptors for elegant, validated attributes!
