# Encapsulation and Data Hiding in Python

**கற்க கசடற - Learn Flawlessly**

## Introduction

Encapsulation is one of the fundamental principles of Object-Oriented Programming (OOP) that bundles data (attributes) and methods that operate on that data within a single unit (class). It also restricts direct access to some of an object's components, which is known as **data hiding** or **information hiding**.

Think of encapsulation like a capsule that wraps up medicine - you don't need to know the internal chemical composition, you just need to know how to use it safely.

## Why Encapsulation?

### 1. **Data Protection**
Prevent accidental or unauthorized modification of internal data.

### 2. **Implementation Hiding**
Hide internal implementation details from the outside world.

### 3. **Controlled Access**
Provide controlled access through methods (getters/setters).

### 4. **Maintainability**
Change internal implementation without breaking external code.

### 5. **Validation**
Enforce validation rules when setting attribute values.

## Access Modifiers in Python

Unlike languages like Java or C++, Python doesn't have strict access modifiers (public, private, protected). Instead, it uses **naming conventions** to indicate access levels.

### 1. Public Attributes (No Underscore)

```python
class Person:
    def __init__(self, name, age):
        self.name = name      # Public attribute
        self.age = age        # Public attribute
    
    def greet(self):          # Public method
        return f"Hello, I'm {self.name}"

person = Person("Alice", 30)
print(person.name)            # Direct access - OK
person.age = 31               # Direct modification - OK
print(person.greet())         # Direct method call - OK
```

### 2. Protected Attributes (Single Underscore `_`)

Single underscore `_` indicates that an attribute is intended for internal use only. It's a **convention**, not enforced by Python.

```python
class BankAccount:
    def __init__(self, account_number, balance):
        self.account_number = account_number
        self._balance = balance    # Protected - "internal use" hint
    
    def deposit(self, amount):
        if amount > 0:
            self._balance += amount
            return True
        return False
    
    def get_balance(self):
        return self._balance

account = BankAccount("12345", 1000)

# Still accessible, but the _ indicates "use with caution"
print(account._balance)       # Works, but discouraged

# Better approach - use the public interface
print(account.get_balance())  # Recommended
```

### 3. Private Attributes (Double Underscore `__`)

Double underscore `__` triggers name mangling, making it harder (but not impossible) to access from outside the class.

```python
class SecureAccount:
    def __init__(self, account_number, pin, balance):
        self.account_number = account_number
        self.__pin = pin          # Private attribute (name mangling)
        self.__balance = balance  # Private attribute
    
    def verify_pin(self, pin):
        return self.__pin == pin
    
    def get_balance(self, pin):
        if self.verify_pin(pin):
            return self.__balance
        return "Access denied"
    
    def withdraw(self, pin, amount):
        if not self.verify_pin(pin):
            return "Invalid PIN"
        if amount > self.__balance:
            return "Insufficient funds"
        self.__balance -= amount
        return f"Withdrew ${amount}. New balance: ${self.__balance}"

account = SecureAccount("12345", "1234", 5000)

# Direct access fails
# print(account.__pin)        # AttributeError
# print(account.__balance)    # AttributeError

# Use public methods
print(account.get_balance("1234"))     # 5000
print(account.withdraw("1234", 500))   # Withdrew $500. New balance: $4500

# Name mangling: Python internally renames __attribute to _ClassName__attribute
# Still accessible (but very discouraged!)
print(account._SecureAccount__balance)  # 4500 - but DON'T do this!
```

## Name Mangling Explained

When you use double underscore `__`, Python performs **name mangling**:

```python
class MyClass:
    def __init__(self):
        self.public = "I'm public"
        self._protected = "I'm protected (convention)"
        self.__private = "I'm private (name mangled)"

obj = MyClass()

print(obj.public)         # Works
print(obj._protected)     # Works (but discouraged)
# print(obj.__private)    # AttributeError

# Python mangles __private to _MyClass__private
print(obj._MyClass__private)  # Works, but defeats the purpose!

# See all attributes
print(dir(obj))
# [..., '_MyClass__private', '__init__', '_protected', 'public']
```

## Getters and Setters

Getters and setters provide controlled access to private attributes.

### Traditional Approach

```python
class Employee:
    def __init__(self, name, salary):
        self.__name = name
        self.__salary = salary
    
    # Getter methods
    def get_name(self):
        return self.__name
    
    def get_salary(self):
        return self.__salary
    
    # Setter methods with validation
    def set_name(self, name):
        if name and isinstance(name, str):
            self.__name = name
        else:
            raise ValueError("Name must be a non-empty string")
    
    def set_salary(self, salary):
        if salary > 0:
            self.__salary = salary
        else:
            raise ValueError("Salary must be positive")

emp = Employee("Alice", 50000)

# Using getters
print(emp.get_name())      # Alice
print(emp.get_salary())    # 50000

# Using setters
emp.set_salary(55000)
print(emp.get_salary())    # 55000

# Validation prevents invalid data
try:
    emp.set_salary(-1000)  # ValueError: Salary must be positive
except ValueError as e:
    print(f"Error: {e}")
```

## Property Decorators (Pythonic Approach)

Python's `@property` decorator provides a more elegant way to implement getters and setters.

### Basic Property Usage

```python
class Person:
    def __init__(self, name, age):
        self._name = name
        self._age = age
    
    @property
    def name(self):
        """Getter for name"""
        return self._name
    
    @name.setter
    def name(self, value):
        """Setter for name with validation"""
        if not value or not isinstance(value, str):
            raise ValueError("Name must be a non-empty string")
        self._name = value
    
    @property
    def age(self):
        """Getter for age"""
        return self._age
    
    @age.setter
    def age(self, value):
        """Setter for age with validation"""
        if not isinstance(value, int) or value < 0 or value > 150:
            raise ValueError("Age must be between 0 and 150")
        self._age = value

# Usage - looks like direct attribute access!
person = Person("Bob", 25)

# Using properties (looks like attribute access)
print(person.name)    # Uses @property getter
print(person.age)     # Uses @property getter

# Setting properties (looks like attribute assignment)
person.name = "Robert"  # Uses @name.setter
person.age = 26         # Uses @age.setter

# Validation is automatically applied
try:
    person.age = -5       # ValueError
except ValueError as e:
    print(f"Error: {e}")

try:
    person.age = 200      # ValueError
except ValueError as e:
    print(f"Error: {e}")
```

### Read-Only Properties

```python
class Circle:
    def __init__(self, radius):
        self._radius = radius
    
    @property
    def radius(self):
        """Getter for radius"""
        return self._radius
    
    @radius.setter
    def radius(self, value):
        """Setter with validation"""
        if value <= 0:
            raise ValueError("Radius must be positive")
        self._radius = value
    
    @property
    def diameter(self):
        """Read-only property (no setter)"""
        return self._radius * 2
    
    @property
    def area(self):
        """Read-only property calculated from radius"""
        return 3.14159 * self._radius ** 2
    
    @property
    def circumference(self):
        """Read-only property"""
        return 2 * 3.14159 * self._radius

# Usage
circle = Circle(5)

print(f"Radius: {circle.radius}")              # 5
print(f"Diameter: {circle.diameter}")          # 10
print(f"Area: {circle.area:.2f}")              # 78.54
print(f"Circumference: {circle.circumference:.2f}")  # 31.42

# Can modify radius
circle.radius = 10
print(f"New area: {circle.area:.2f}")          # 314.16

# Cannot modify read-only properties
try:
    circle.diameter = 20  # AttributeError: can't set attribute
except AttributeError as e:
    print(f"Error: {e}")
```

## Comprehensive Example: Temperature Class

```python
class Temperature:
    """Temperature class with multiple representations"""
    
    def __init__(self, celsius=0):
        self._celsius = celsius
    
    @property
    def celsius(self):
        """Get temperature in Celsius"""
        return self._celsius
    
    @celsius.setter
    def celsius(self, value):
        """Set temperature in Celsius with validation"""
        if value < -273.15:
            raise ValueError("Temperature below absolute zero!")
        self._celsius = value
    
    @property
    def fahrenheit(self):
        """Get temperature in Fahrenheit (calculated)"""
        return (self._celsius * 9/5) + 32
    
    @fahrenheit.setter
    def fahrenheit(self, value):
        """Set temperature using Fahrenheit"""
        celsius = (value - 32) * 5/9
        if celsius < -273.15:
            raise ValueError("Temperature below absolute zero!")
        self._celsius = celsius
    
    @property
    def kelvin(self):
        """Get temperature in Kelvin (calculated)"""
        return self._celsius + 273.15
    
    @kelvin.setter
    def kelvin(self, value):
        """Set temperature using Kelvin"""
        if value < 0:
            raise ValueError("Kelvin cannot be negative!")
        self._celsius = value - 273.15
    
    def __str__(self):
        return f"{self._celsius:.2f}°C / {self.fahrenheit:.2f}°F / {self.kelvin:.2f}K"

# Usage
temp = Temperature(25)  # 25°C
print(temp)             # 25.00°C / 77.00°F / 298.15K

# Set using Fahrenheit
temp.fahrenheit = 32    # 0°C
print(temp)             # 0.00°C / 32.00°F / 273.15K

# Set using Kelvin
temp.kelvin = 373.15    # 100°C (boiling point of water)
print(temp)             # 100.00°C / 212.00°F / 373.15K

# Validation prevents invalid values
try:
    temp.celsius = -300  # Below absolute zero
except ValueError as e:
    print(f"Error: {e}")
```

## Real-World Example: Banking System

```python
from datetime import datetime

class BankAccount:
    """Secure bank account with encapsulation"""
    
    # Class variable (shared by all instances)
    _account_counter = 1000
    
    def __init__(self, owner_name, initial_balance=0, pin="0000"):
        # Generate unique account number
        self.__account_number = self._generate_account_number()
        
        # Private attributes
        self.__owner_name = owner_name
        self.__balance = 0
        self.__pin = pin
        self.__transactions = []
        
        # Use setter for validation
        if initial_balance > 0:
            self.__balance = initial_balance
            self.__add_transaction("Initial deposit", initial_balance)
    
    @classmethod
    def _generate_account_number(cls):
        """Generate unique account number"""
        cls._account_counter += 1
        return f"ACC{cls._account_counter:06d}"
    
    def __add_transaction(self, description, amount):
        """Private method to record transactions"""
        self.__transactions.append({
            'timestamp': datetime.now(),
            'description': description,
            'amount': amount,
            'balance': self.__balance
        })
    
    # Public properties with getters only (read-only)
    @property
    def account_number(self):
        """Read-only account number"""
        return self.__account_number
    
    @property
    def owner_name(self):
        """Read-only owner name"""
        return self.__owner_name
    
    # Public methods with PIN verification
    def get_balance(self, pin):
        """Get balance with PIN verification"""
        if not self.__verify_pin(pin):
            return "Invalid PIN"
        return self.__balance
    
    def deposit(self, amount, pin):
        """Deposit money with PIN verification"""
        if not self.__verify_pin(pin):
            return "Invalid PIN"
        
        if amount <= 0:
            return "Deposit amount must be positive"
        
        self.__balance += amount
        self.__add_transaction("Deposit", amount)
        return f"Deposited ${amount:.2f}. New balance: ${self.__balance:.2f}"
    
    def withdraw(self, amount, pin):
        """Withdraw money with PIN verification"""
        if not self.__verify_pin(pin):
            return "Invalid PIN"
        
        if amount <= 0:
            return "Withdrawal amount must be positive"
        
        if amount > self.__balance:
            return "Insufficient funds"
        
        self.__balance -= amount
        self.__add_transaction("Withdrawal", -amount)
        return f"Withdrew ${amount:.2f}. New balance: ${self.__balance:.2f}"
    
    def transfer(self, other_account, amount, pin):
        """Transfer money to another account"""
        if not self.__verify_pin(pin):
            return "Invalid PIN"
        
        if not isinstance(other_account, BankAccount):
            return "Invalid account"
        
        if amount <= 0:
            return "Transfer amount must be positive"
        
        if amount > self.__balance:
            return "Insufficient funds"
        
        # Perform transfer
        self.__balance -= amount
        self.__add_transaction(f"Transfer to {other_account.account_number}", -amount)
        
        other_account.__balance += amount
        other_account.__add_transaction(f"Transfer from {self.__account_number}", amount)
        
        return f"Transferred ${amount:.2f} to {other_account.account_number}"
    
    def get_transaction_history(self, pin, limit=10):
        """Get recent transaction history with PIN verification"""
        if not self.__verify_pin(pin):
            return "Invalid PIN"
        
        return self.__transactions[-limit:]
    
    def change_pin(self, old_pin, new_pin):
        """Change PIN"""
        if not self.__verify_pin(old_pin):
            return "Invalid current PIN"
        
        if len(new_pin) != 4 or not new_pin.isdigit():
            return "PIN must be 4 digits"
        
        self.__pin = new_pin
        self.__add_transaction("PIN changed", 0)
        return "PIN changed successfully"
    
    def __verify_pin(self, pin):
        """Private method to verify PIN"""
        return self.__pin == pin
    
    def __str__(self):
        """Public string representation (no sensitive data)"""
        return f"Account {self.__account_number} - Owner: {self.__owner_name}"
    
    def __repr__(self):
        """Official representation"""
        return f"BankAccount('{self.__owner_name}', account='{self.__account_number}')"

# Usage Example
def main():
    # Create accounts
    alice_account = BankAccount("Alice Johnson", 1000, "1234")
    bob_account = BankAccount("Bob Smith", 500, "5678")
    
    print(alice_account)
    print(bob_account)
    print()
    
    # Deposit
    print(alice_account.deposit(500, "1234"))
    
    # Check balance
    print(f"Alice's balance: ${alice_account.get_balance('1234')}")
    
    # Withdraw
    print(alice_account.withdraw(200, "1234"))
    
    # Transfer
    print(alice_account.transfer(bob_account, 300, "1234"))
    
    # Check balances
    print(f"Alice's balance: ${alice_account.get_balance('1234')}")
    print(f"Bob's balance: ${bob_account.get_balance('5678')}")
    
    # Transaction history
    print("\nAlice's recent transactions:")
    for transaction in alice_account.get_transaction_history("1234", 5):
        print(f"  {transaction['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}: "
              f"{transaction['description']} ${transaction['amount']:+.2f} "
              f"(Balance: ${transaction['balance']:.2f})")
    
    # Try to access private attributes (fails)
    # print(alice_account.__balance)  # AttributeError
    
    # Read-only properties work
    print(f"\nAccount Number: {alice_account.account_number}")
    print(f"Owner: {alice_account.owner_name}")
    
    # Cannot modify read-only properties
    # alice_account.account_number = "HACK"  # AttributeError

if __name__ == "__main__":
    main()
```

## Benefits of Encapsulation

### 1. **Data Integrity**
```python
class Student:
    def __init__(self, name):
        self._name = name
        self._grades = []
    
    def add_grade(self, grade):
        # Validation ensures data integrity
        if 0 <= grade <= 100:
            self._grades.append(grade)
        else:
            raise ValueError("Grade must be between 0 and 100")
```

### 2. **Flexibility to Change Implementation**
```python
class Product:
    def __init__(self, price):
        self._price = price
    
    @property
    def price(self):
        # Can add logic without breaking external code
        return self._price
    
    @price.setter
    def price(self, value):
        # Can add validation, logging, etc.
        if value < 0:
            raise ValueError("Price cannot be negative")
        self._price = value
```

### 3. **Controlled Access**
```python
class Database:
    def __init__(self):
        self.__connection = None
    
    def connect(self, credentials):
        # Control how connection is established
        # Validate credentials, manage resources, etc.
        pass
```

## Best Practices

### 1. Use Properties for Computed Attributes
```python
class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    @property
    def area(self):
        """Computed property"""
        return self.width * self.height
```

### 2. Validate in Setters
```python
class User:
    def __init__(self, email):
        self._email = None
        self.email = email  # Use setter for validation
    
    @property
    def email(self):
        return self._email
    
    @email.setter
    def email(self, value):
        if '@' not in value:
            raise ValueError("Invalid email")
        self._email = value
```

### 3. Use Single Underscore for "Internal" Attributes
```python
class Cache:
    def __init__(self):
        self._cache = {}  # Internal implementation detail
    
    def get(self, key):
        return self._cache.get(key)
```

### 4. Use Double Underscore Sparingly
Reserve `__` for cases where you truly need name mangling (e.g., preventing accidental overrides in subclasses).

## Summary

**Key Concepts:**
- ✅ Encapsulation bundles data and methods together
- ✅ Data hiding protects internal implementation
- ✅ Public (no underscore): Accessible everywhere
- ✅ Protected (`_`): Internal use convention
- ✅ Private (`__`): Name mangling for stronger hiding
- ✅ `@property`: Pythonic way to implement getters/setters
- ✅ Properties allow validation and computed attributes

**Benefits:**
- ✅ Data integrity through validation
- ✅ Controlled access to internal state
- ✅ Flexibility to change implementation
- ✅ Easier maintenance and debugging
- ✅ Improved security

**Best Practices:**
- ✅ Use properties instead of traditional getters/setters
- ✅ Validate data in setters
- ✅ Use `_` for internal attributes (convention)
- ✅ Use `__` sparingly (only when truly needed)
- ✅ Provide public methods for controlled access

In the next section, we'll explore **Special Methods (Magic Methods)**, learning how to customize Python's built-in behaviors for your classes!

---

**கற்க கசடற** - Master encapsulation and build secure, maintainable classes!
