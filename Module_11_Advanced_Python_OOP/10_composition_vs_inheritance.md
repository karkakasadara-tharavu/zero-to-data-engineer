# Composition vs Inheritance

**கற்க கசடற - Learn Flawlessly**

## Introduction

Two fundamental approaches to code reuse in Object-Oriented Programming are **inheritance** ("is-a" relationship) and **composition** ("has-a" relationship). While inheritance is powerful, composition is often more flexible and maintainable. Understanding when to use each is crucial for good software design.

## The Principle: "Favor Composition Over Inheritance"

This famous design principle suggests that you should prefer composition when both options are available. However, both have their place.

## Inheritance: "Is-A" Relationship

Inheritance models an "is-a" relationship where a subclass is a specialized version of its parent class.

```python
class Animal:
    def __init__(self, name):
        self.name = name
    
    def eat(self):
        return f"{self.name} is eating"
    
    def sleep(self):
        return f"{self.name} is sleeping"

class Dog(Animal):  # Dog IS-A Animal
    def bark(self):
        return f"{self.name} says Woof!"

class Cat(Animal):  # Cat IS-A Animal
    def meow(self):
        return f"{self.name} says Meow!"

dog = Dog("Buddy")
print(dog.eat())    # Buddy is eating (inherited)
print(dog.bark())   # Buddy says Woof! (specific to Dog)
```

## Composition: "Has-A" Relationship

Composition models a "has-a" relationship where an object contains other objects as its parts.

```python
class Engine:
    def start(self):
        return "Engine started"
    
    def stop(self):
        return "Engine stopped"

class Wheels:
    def __init__(self, count):
        self.count = count
    
    def rotate(self):
        return f"{self.count} wheels rotating"

class Car:  # Car HAS-A Engine and HAS-A Wheels
    def __init__(self):
        self.engine = Engine()      # Composition
        self.wheels = Wheels(4)     # Composition
    
    def start(self):
        return self.engine.start()
    
    def drive(self):
        return f"{self.engine.start()}, {self.wheels.rotate()}"

car = Car()
print(car.start())  # Engine started
print(car.drive())  # Engine started, 4 wheels rotating
```

## When to Use Inheritance

### ✅ Use Inheritance When:

1. **Clear "Is-A" Relationship Exists**
```python
class Employee:  # Base class
    def work(self):
        pass

class Manager(Employee):  # Manager IS-A Employee ✓
    def manage_team(self):
        pass

class Developer(Employee):  # Developer IS-A Employee ✓
    def write_code(self):
        pass
```

2. **Liskov Substitution Principle Holds**
Subclass can be used anywhere parent class is expected.

```python
def give_work(employee: Employee):
    return employee.work()

# Works with any Employee subclass
give_work(Manager())
give_work(Developer())
```

3. **Shared Behavior Across Related Classes**
```python
class Shape:
    def __init__(self, color):
        self.color = color
    
    def area(self):
        raise NotImplementedError

class Circle(Shape):
    def __init__(self, color, radius):
        super().__init__(color)
        self.radius = radius
    
    def area(self):
        return 3.14159 * self.radius ** 2
```

## When to Use Composition

### ✅ Use Composition When:

1. **"Has-A" Relationship Exists**
```python
class Address:
    def __init__(self, street, city, country):
        self.street = street
        self.city = city
        self.country = country

class Person:
    def __init__(self, name):
        self.name = name
        self.address = None  # Person HAS-A Address ✓
    
    def set_address(self, address):
        self.address = address
```

2. **Need Flexibility to Change Behavior at Runtime**
```python
class Logger:
    def log(self, message):
        print(f"LOG: {message}")

class FileLogger:
    def log(self, message):
        print(f"FILE: {message}")

class Application:
    def __init__(self, logger):
        self.logger = logger  # Can switch logger at runtime
    
    def do_something(self):
        self.logger.log("Doing something")

# Easy to switch implementations
app = Application(Logger())
app.do_something()  # LOG: Doing something

app.logger = FileLogger()
app.do_something()  # FILE: Doing something
```

3. **Avoid Deep Inheritance Hierarchies**
```python
# BAD: Deep inheritance
class Vehicle:
    pass

class MotorVehicle(Vehicle):
    pass

class Car(MotorVehicle):
    pass

class Sedan(Car):  # Too deep!
    pass

# GOOD: Composition
class Engine:
    pass

class Transmission:
    pass

class Car:
    def __init__(self):
        self.engine = Engine()
        self.transmission = Transmission()
```

## Problems with Inheritance

### 1. Tight Coupling

```python
# Parent class change affects all children
class Parent:
    def method(self):
        return "Parent method"

class Child(Parent):
    pass

# If Parent.method() changes, Child is affected
```

### 2. Fragile Base Class Problem

```python
class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def set_width(self, width):
        self.width = width
    
    def set_height(self, height):
        self.height = height
    
    def area(self):
        return self.width * self.height

class Square(Rectangle):
    def set_width(self, width):
        self.width = width
        self.height = width  # Keep it square
    
    def set_height(self, height):
        self.width = height
        self.height = height  # Keep it square

# Problem: Square can't substitute Rectangle properly
def process_rectangle(rect: Rectangle):
    rect.set_width(5)
    rect.set_height(10)
    assert rect.area() == 50  # Fails for Square!

square = Square(5, 5)
process_rectangle(square)  # Assertion fails!
```

### 3. Multiple Inheritance Complexity

```python
# Diamond problem
class A:
    def method(self):
        return "A"

class B(A):
    def method(self):
        return "B"

class C(A):
    def method(self):
        return "C"

class D(B, C):  # Which method() is called?
    pass

d = D()
print(d.method())  # "B" (MRO resolution, but confusing)
```

## Composition Solution

### Solving the Rectangle/Square Problem

```python
class Shape:
    def area(self):
        raise NotImplementedError

class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def area(self):
        return self.width * self.height

class Square:
    def __init__(self, side):
        self.side = side
    
    def area(self):
        return self.side ** 2

# No inheritance problems, each is independent
```

## Practical Example: Employee System

### Inheritance Approach (Can Get Messy)

```python
class Employee:
    def work(self):
        pass

class Manager(Employee):
    def manage(self):
        pass

class Programmer(Employee):
    def code(self):
        pass

# What about a Manager who codes?
class ManagerProgrammer(Manager, Programmer):  # Multiple inheritance
    pass
```

### Composition Approach (More Flexible)

```python
class WorkBehavior:
    def work(self):
        return "Working"

class ManagementBehavior:
    def manage(self):
        return "Managing team"

class ProgrammingBehavior:
    def code(self):
        return "Writing code"

class Employee:
    def __init__(self, name, behaviors=None):
        self.name = name
        self.behaviors = behaviors or []
    
    def add_behavior(self, behavior):
        self.behaviors.append(behavior)
    
    def perform_duties(self):
        results = []
        for behavior in self.behaviors:
            for method_name in dir(behavior):
                if not method_name.startswith('_'):
                    method = getattr(behavior, method_name)
                    if callable(method):
                        results.append(method())
        return results

# Easy to mix and match capabilities
manager = Employee("Alice", [WorkBehavior(), ManagementBehavior()])
programmer = Employee("Bob", [WorkBehavior(), ProgrammingBehavior()])
tech_lead = Employee("Carol", [WorkBehavior(), ManagementBehavior(), ProgrammingBehavior()])

print(f"{tech_lead.name} duties: {tech_lead.perform_duties()}")
# Carol duties: ['Working', 'Managing team', 'Writing code']
```

## Strategy Pattern (Composition)

Favor composition by using the Strategy pattern:

```python
from abc import ABC, abstractmethod

class PaymentStrategy(ABC):
    @abstractmethod
    def pay(self, amount):
        pass

class CreditCardPayment(PaymentStrategy):
    def pay(self, amount):
        return f"Paid ${amount} with credit card"

class PayPalPayment(PaymentStrategy):
    def pay(self, amount):
        return f"Paid ${amount} with PayPal"

class BitcoinPayment(PaymentStrategy):
    def pay(self, amount):
        return f"Paid ${amount} with Bitcoin"

class ShoppingCart:
    def __init__(self):
        self.items = []
        self.payment_strategy = None
    
    def add_item(self, item, price):
        self.items.append((item, price))
    
    def set_payment_strategy(self, strategy: PaymentStrategy):
        self.payment_strategy = strategy
    
    def checkout(self):
        total = sum(price for item, price in self.items)
        if self.payment_strategy:
            return self.payment_strategy.pay(total)
        return "No payment method set"

# Usage - change strategy at runtime
cart = ShoppingCart()
cart.add_item("Book", 29.99)
cart.add_item("Pen", 4.99)

cart.set_payment_strategy(CreditCardPayment())
print(cart.checkout())  # Paid $34.98 with credit card

cart.set_payment_strategy(PayPalPayment())
print(cart.checkout())  # Paid $34.98 with PayPal
```

## Comprehensive Example: Game Characters

### Inheritance Approach (Rigid)

```python
class Character:
    def attack(self):
        pass

class Warrior(Character):
    def attack(self):
        return "Sword attack"

class Mage(Character):
    def attack(self):
        return "Magic attack"

# Problem: Want a warrior who can cast spells?
# Need multiple inheritance or duplicate code
```

### Composition Approach (Flexible)

```python
class AttackBehavior(ABC):
    @abstractmethod
    def attack(self):
        pass

class DefendBehavior(ABC):
    @abstractmethod
    def defend(self):
        pass

class SwordAttack(AttackBehavior):
    def attack(self):
        return "Slashing with sword"

class MagicAttack(AttackBehavior):
    def attack(self):
        return "Casting fireball"

class ShieldDefense(DefendBehavior):
    def defend(self):
        return "Blocking with shield"

class MagicBarrier(DefendBehavior):
    def defend(self):
        return "Creating magic barrier"

class Character:
    def __init__(self, name, attack_behavior, defend_behavior):
        self.name = name
        self.attack_behavior = attack_behavior
        self.defend_behavior = defend_behavior
        self.health = 100
    
    def attack(self):
        return self.attack_behavior.attack()
    
    def defend(self):
        return self.defend_behavior.defend()
    
    def change_attack(self, new_attack):
        """Change attack behavior at runtime!"""
        self.attack_behavior = new_attack
    
    def change_defense(self, new_defense):
        """Change defense behavior at runtime!"""
        self.defend_behavior = new_defense

# Create flexible character combinations
warrior = Character("Conan", SwordAttack(), ShieldDefense())
mage = Character("Gandalf", MagicAttack(), MagicBarrier())
battlemage = Character("Merlin", MagicAttack(), ShieldDefense())

print(f"{warrior.name}: {warrior.attack()}, {warrior.defend()}")
print(f"{mage.name}: {mage.attack()}, {mage.defend()}")
print(f"{battlemage.name}: {battlemage.attack()}, {battlemage.defend()}")

# Switch behaviors at runtime!
print(f"\n{warrior.name} learns magic!")
warrior.change_attack(MagicAttack())
print(f"{warrior.name}: {warrior.attack()}, {warrior.defend()}")
```

## Mixin Pattern: Best of Both Worlds

Mixins combine inheritance and composition benefits:

```python
class TimestampMixin:
    """Add timestamp functionality to any class"""
    def set_timestamp(self):
        from datetime import datetime
        self.created_at = datetime.now()

class SerializeMixin:
    """Add JSON serialization to any class"""
    def to_json(self):
        import json
        return json.dumps(self.__dict__, default=str)

class User(TimestampMixin, SerializeMixin):
    def __init__(self, name, email):
        self.name = name
        self.email = email
        self.set_timestamp()

user = User("Alice", "alice@example.com")
print(user.to_json())
# {"name": "Alice", "email": "alice@example.com", "created_at": "2025-12-07 ..."}
```

## Decision Tree

```
Is there a clear "is-a" relationship?
├─ Yes: Does Liskov Substitution Principle hold?
│  ├─ Yes: Consider Inheritance
│  └─ No: Use Composition
└─ No: Is there a "has-a" relationship?
   ├─ Yes: Use Composition
   └─ No: Need runtime behavior changes?
      ├─ Yes: Use Composition (Strategy Pattern)
      └─ No: Reconsider your design
```

## Summary

### Inheritance:
**Use When:**
- ✅ Clear "is-a" relationship
- ✅ Liskov Substitution Principle holds
- ✅ Shared behavior across related classes
- ✅ Shallow hierarchy (2-3 levels max)

**Avoid When:**
- ❌ Forcing "is-a" for code reuse
- ❌ Deep hierarchies (>3 levels)
- ❌ Multiple inheritance complexity
- ❌ Need runtime behavior changes

### Composition:
**Use When:**
- ✅ "Has-a" relationship exists
- ✅ Need runtime flexibility
- ✅ Want to avoid tight coupling
- ✅ Building complex objects from simple parts
- ✅ Reusing behavior across unrelated classes

**Avoid When:**
- ❌ True hierarchical relationship exists
- ❌ Need polymorphic behavior through type hierarchy
- ❌ Would create unnecessary complexity

### Key Principles:
1. **Favor composition over inheritance**
2. **Inheritance for specialization, composition for reuse**
3. **Keep hierarchies shallow**
4. **Use interfaces/ABCs for polymorphism**
5. **Prefer small, focused classes**

---

**கற்க கசடற** - Master composition and inheritance to build flexible, maintainable systems!
