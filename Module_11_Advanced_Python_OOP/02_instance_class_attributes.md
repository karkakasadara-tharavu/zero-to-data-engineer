# Section 02: Instance vs Class Attributes

**கற்க கசடற - Learn Flawlessly**

## Understanding Different Types of Attributes

In Python classes, there are two main types of attributes:
1. **Instance Attributes** - Unique to each object
2. **Class Attributes** - Shared across all instances of the class

Understanding when to use each is crucial for effective OOP design.

## Instance Attributes

**Instance attributes** are unique to each object. They're defined inside methods (usually `__init__`) using `self`.

```python
class Employee:
    def __init__(self, name, salary):
        self.name = name      # Instance attribute
        self.salary = salary  # Instance attribute

emp1 = Employee("Alice", 50000)
emp2 = Employee("Bob", 60000)

print(emp1.name)    # Alice
print(emp2.name)    # Bob
print(emp1.salary)  # 50000
print(emp2.salary)  # 60000
```

Each employee has their own `name` and `salary`.

## Class Attributes

**Class attributes** are shared by all instances of the class. They're defined directly in the class body, outside any methods.

```python
class Employee:
    # Class attribute - shared by all instances
    company_name = "TechCorp Inc."
    employee_count = 0
    
    def __init__(self, name, salary):
        # Instance attributes - unique to each instance
        self.name = name
        self.salary = salary
        # Increment class attribute when new employee is created
        Employee.employee_count += 1

emp1 = Employee("Alice", 50000)
emp2 = Employee("Bob", 60000)

# All employees share the same company name
print(emp1.company_name)  # TechCorp Inc.
print(emp2.company_name)  # TechCorp Inc.

# Count is shared
print(Employee.employee_count)  # 2
```

## When to Use Each Type

### Use Instance Attributes When:
- Data is unique to each object
- Values differ between instances
- You need independent state for each object

**Examples**: name, age, balance, email, phone number

### Use Class Attributes When:
- Data is shared across all instances
- Values are constant for the class
- You need class-wide configuration or counters

**Examples**: company name, tax rate, API URL, instance counter

## Accessing Attributes

```python
class Product:
    # Class attribute
    tax_rate = 0.08
    
    def __init__(self, name, price):
        # Instance attributes
        self.name = name
        self.price = price
    
    def get_total_price(self):
        """Calculate price including tax."""
        return self.price * (1 + Product.tax_rate)

product1 = Product("Laptop", 1000)
product2 = Product("Mouse", 25)

# Access via instance (looks up in instance, then class)
print(product1.tax_rate)  # 0.08

# Access via class name (recommended for class attributes)
print(Product.tax_rate)   # 0.08

# Instance attributes only via instance
print(product1.name)      # Laptop
print(product1.price)     # 1000
```

## Modifying Class Attributes

### Modifying via Class Name (affects all instances):

```python
class BankAccount:
    interest_rate = 0.03  # 3% interest
    
    def __init__(self, owner, balance):
        self.owner = owner
        self.balance = balance
    
    def apply_interest(self):
        """Apply interest to the account."""
        self.balance += self.balance * BankAccount.interest_rate

account1 = BankAccount("Alice", 1000)
account2 = BankAccount("Bob", 2000)

# Change class attribute
BankAccount.interest_rate = 0.05  # Raise to 5%

account1.apply_interest()
account2.apply_interest()

print(account1.balance)  # 1050.0
print(account2.balance)  # 2100.0
```

### Modifying via Instance (creates instance attribute):

```python
class Circle:
    pi = 3.14159  # Class attribute
    
    def __init__(self, radius):
        self.radius = radius
    
    def get_area(self):
        # Uses class attribute by default
        return Circle.pi * self.radius ** 2

circle1 = Circle(5)
circle2 = Circle(10)

print(circle1.pi)  # 3.14159
print(circle2.pi)  # 3.14159

# This creates an INSTANCE attribute (doesn't affect class attribute)
circle1.pi = 3.14  # Less precise for this specific circle

print(circle1.pi)       # 3.14 (instance attribute)
print(circle2.pi)       # 3.14159 (still class attribute)
print(Circle.pi)        # 3.14159 (class attribute unchanged)
print(circle1.__class__.pi)  # 3.14159 (accessing class attribute)
```

## Mutable Class Attributes (Warning!)

Be careful with mutable class attributes:

```python
# ❌ Dangerous pattern
class Team:
    members = []  # Mutable class attribute - shared!
    
    def __init__(self, name):
        self.name = name
    
    def add_member(self, member):
        self.members.append(member)  # Modifies class attribute!

team1 = Team("Team A")
team2 = Team("Team B")

team1.add_member("Alice")
team2.add_member("Bob")

# Both teams share the same list!
print(team1.members)  # ['Alice', 'Bob'] - Unexpected!
print(team2.members)  # ['Alice', 'Bob'] - Unexpected!
```

**Solution**: Use instance attributes for mutable data:

```python
# ✅ Correct pattern
class Team:
    def __init__(self, name):
        self.name = name
        self.members = []  # Instance attribute - unique to each team
    
    def add_member(self, member):
        self.members.append(member)

team1 = Team("Team A")
team2 = Team("Team B")

team1.add_member("Alice")
team2.add_member("Bob")

print(team1.members)  # ['Alice']
print(team2.members)  # ['Bob'] - Correct!
```

## Attribute Lookup Order

Python follows a specific order when looking up attributes:

1. **Instance attributes** (in `__dict__`)
2. **Class attributes** (in class `__dict__`)
3. **Parent class attributes** (we'll cover inheritance later)

```python
class Example:
    class_var = "I'm a class attribute"
    
    def __init__(self):
        self.instance_var = "I'm an instance attribute"

obj = Example()

# Check what's in each namespace
print(obj.__dict__)           # {'instance_var': "I'm an instance attribute"}
print(Example.__dict__)       # {..., 'class_var': "I'm a class attribute", ...}

print(obj.instance_var)       # Instance attribute (found in step 1)
print(obj.class_var)          # Class attribute (found in step 2)
```

## Practical Example: Counting Instances

```python
class DatabaseConnection:
    """Manages database connections with connection pooling."""
    
    # Class attributes
    total_connections = 0
    max_connections = 10
    active_connections = []
    
    def __init__(self, database_name):
        """Create a new database connection."""
        if DatabaseConnection.total_connections >= DatabaseConnection.max_connections:
            raise Exception("Maximum connections reached!")
        
        # Instance attributes
        self.database_name = database_name
        self.connection_id = DatabaseConnection.total_connections + 1
        
        # Update class attributes
        DatabaseConnection.total_connections += 1
        DatabaseConnection.active_connections.append(self.connection_id)
    
    def close(self):
        """Close this connection."""
        DatabaseConnection.active_connections.remove(self.connection_id)
        print(f"Connection {self.connection_id} to {self.database_name} closed")
    
    @classmethod
    def get_stats(cls):
        """Return connection statistics."""
        return {
            'total': cls.total_connections,
            'active': len(cls.active_connections),
            'max': cls.max_connections
        }

# Create connections
conn1 = DatabaseConnection("users_db")
conn2 = DatabaseConnection("products_db")
conn3 = DatabaseConnection("orders_db")

print(DatabaseConnection.get_stats())
# {'total': 3, 'active': 3, 'max': 10}

conn1.close()
print(DatabaseConnection.get_stats())
# {'total': 3, 'active': 2, 'max': 10}
```

## Constants as Class Attributes

Class attributes are perfect for constants:

```python
class Config:
    """Application configuration."""
    
    # API settings
    API_URL = "https://api.example.com"
    API_TIMEOUT = 30
    API_MAX_RETRIES = 3
    
    # Database settings
    DB_HOST = "localhost"
    DB_PORT = 5432
    DB_NAME = "myapp"
    
    # Feature flags
    DEBUG_MODE = True
    ENABLE_LOGGING = True

# Use throughout application
print(f"Connecting to {Config.API_URL}")
print(f"Timeout: {Config.API_TIMEOUT} seconds")
```

## Class Attribute Example: Game Characters

```python
class Character:
    """Represents a game character."""
    
    # Class attributes - game rules
    max_health = 100
    max_stamina = 100
    level_up_threshold = 1000
    
    # Track all characters
    all_characters = []
    
    def __init__(self, name, character_class):
        """Create a new character."""
        # Instance attributes
        self.name = name
        self.character_class = character_class
        self.health = Character.max_health
        self.stamina = Character.max_stamina
        self.experience = 0
        self.level = 1
        
        # Add to class list
        Character.all_characters.append(self)
    
    def take_damage(self, damage):
        """Reduce health by damage amount."""
        self.health = max(0, self.health - damage)
        if self.health == 0:
            print(f"{self.name} has been defeated!")
    
    def gain_experience(self, exp):
        """Add experience and check for level up."""
        self.experience += exp
        if self.experience >= Character.level_up_threshold:
            self.level_up()
    
    def level_up(self):
        """Level up the character."""
        self.level += 1
        self.experience = 0
        self.health = Character.max_health
        print(f"{self.name} leveled up to level {self.level}!")
    
    def get_status(self):
        """Return character status."""
        return f"{self.name} ({self.character_class}) - Level {self.level}\n" \
               f"  Health: {self.health}/{Character.max_health}\n" \
               f"  Stamina: {self.stamina}/{Character.max_stamina}\n" \
               f"  Experience: {self.experience}/{Character.level_up_threshold}"
    
    @classmethod
    def show_all_characters(cls):
        """Display all characters."""
        print(f"\n=== All Characters ({len(cls.all_characters)}) ===")
        for char in cls.all_characters:
            print(f"- {char.name} (Level {char.level} {char.character_class})")

# Create characters
warrior = Character("Aragorn", "Warrior")
mage = Character("Gandalf", "Mage")
rogue = Character("Legolas", "Rogue")

print(warrior.get_status())
warrior.take_damage(30)
warrior.gain_experience(500)
print(warrior.get_status())

Character.show_all_characters()
```

## Private Attributes Convention

Python uses naming conventions to indicate "private" attributes:

```python
class Account:
    def __init__(self, owner, balance):
        self.owner = owner          # Public
        self._balance = balance     # Protected (convention: internal use)
        self.__account_number = self._generate_account_number()  # Private (name mangled)
    
    def _generate_account_number(self):
        """Internal method (protected)."""
        import random
        return random.randint(100000, 999999)
    
    def get_balance(self):
        """Public method to access balance."""
        return self._balance
    
    def __str__(self):
        return f"Account({self.owner}, {self._balance})"

account = Account("Alice", 1000)
print(account.owner)           # Public - OK
print(account._balance)        # Protected - possible but discouraged
# print(account.__account_number)  # Private - causes AttributeError!
print(account._Account__account_number)  # Name mangling - not recommended
```

**Conventions**:
- `attribute` - Public: Use freely
- `_attribute` - Protected: Internal use, but accessible
- `__attribute` - Private: Name mangled, avoid direct access

## Summary

- **Instance attributes** are unique to each object (use `self.attribute`)
- **Class attributes** are shared by all instances (define in class body)
- Access class attributes via class name: `ClassName.attribute`
- Modifying via instance creates a new instance attribute
- Be careful with mutable class attributes
- Use class attributes for constants, counters, and shared data
- Follow naming conventions for attribute visibility

## Key Takeaways

✅ Instance attributes: Unique per object (`self.x`)  
✅ Class attributes: Shared across instances  
✅ Access class attributes via `ClassName.attr`  
✅ Avoid mutable class attributes (lists, dicts)  
✅ Use class attributes for constants and counters  
✅ Follow naming conventions (_protected, __private)  

## What's Next?

In the next section, we'll explore:
- **Instance methods** in detail
- **Class methods** with `@classmethod`
- **Static methods** with `@staticmethod`
- When to use each type of method

---

**Practice Time!** Continue with your labs to reinforce these concepts.

**கற்க கசடற** - Learn Flawlessly
