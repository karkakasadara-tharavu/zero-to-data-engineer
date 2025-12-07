# Inheritance in Python

**கற்க கசடற - Learn Flawlessly**

## Introduction

Inheritance is one of the fundamental pillars of Object-Oriented Programming (OOP) that enables code reuse and establishes relationships between classes. It allows a new class (child/derived class) to inherit attributes and methods from an existing class (parent/base class), promoting the DRY (Don't Repeat Yourself) principle.

## What is Inheritance?

Inheritance models an "is-a" relationship between classes. For example:
- A `Dog` **is-a** `Animal`
- A `Manager` **is-a** `Employee`
- A `SavingsAccount` **is-a** `BankAccount`

The child class inherits all attributes and methods from the parent class and can:
1. Use inherited attributes and methods as-is
2. Override inherited methods with new implementations
3. Add new attributes and methods specific to the child class

## Basic Inheritance Syntax

```python
# Parent/Base class
class Animal:
    def __init__(self, name, species):
        self.name = name
        self.species = species
    
    def make_sound(self):
        return "Some generic sound"
    
    def info(self):
        return f"{self.name} is a {self.species}"

# Child/Derived class
class Dog(Animal):
    def __init__(self, name, breed):
        # Call parent's __init__
        super().__init__(name, "Dog")
        self.breed = breed
    
    # Override parent's method
    def make_sound(self):
        return "Woof! Woof!"
    
    # Add new method specific to Dog
    def fetch(self):
        return f"{self.name} is fetching the ball!"

# Usage
dog = Dog("Max", "Golden Retriever")
print(dog.info())         # Inherited from Animal: Max is a Dog
print(dog.make_sound())   # Overridden: Woof! Woof!
print(dog.fetch())        # New method: Max is fetching the ball!
```

## The `super()` Function

The `super()` function is used to call methods from the parent class, particularly useful in `__init__` to initialize parent attributes.

### Why Use super()?

```python
class Employee:
    def __init__(self, name, employee_id):
        self.name = name
        self.employee_id = employee_id
        self.company = "TechCorp"

class Manager(Employee):
    def __init__(self, name, employee_id, department):
        # Using super() to initialize parent attributes
        super().__init__(name, employee_id)
        self.department = department
    
    def display_info(self):
        return f"Manager: {self.name} (ID: {self.employee_id}), Department: {self.department}, Company: {self.company}"

# Without super(), you'd have to duplicate code:
class ManagerBad(Employee):
    def __init__(self, name, employee_id, department):
        # Duplicating parent's initialization - BAD!
        self.name = name
        self.employee_id = employee_id
        self.company = "TechCorp"
        self.department = department

manager = Manager("Alice Johnson", "E1001", "Engineering")
print(manager.display_info())
# Output: Manager: Alice Johnson (ID: E1001), Department: Engineering, Company: TechCorp
```

## Method Overriding

Child classes can provide their own implementation of methods inherited from the parent class.

```python
class Shape:
    def __init__(self, color):
        self.color = color
    
    def area(self):
        return 0
    
    def description(self):
        return f"A {self.color} shape"

class Rectangle(Shape):
    def __init__(self, color, width, height):
        super().__init__(color)
        self.width = width
        self.height = height
    
    # Override area method
    def area(self):
        return self.width * self.height
    
    # Override description method
    def description(self):
        return f"A {self.color} rectangle with area {self.area()} sq units"

class Circle(Shape):
    def __init__(self, color, radius):
        super().__init__(color)
        self.radius = radius
    
    # Override area method
    def area(self):
        return 3.14159 * self.radius ** 2
    
    # Override description method
    def description(self):
        return f"A {self.color} circle with area {self.area():.2f} sq units"

# Usage
rect = Rectangle("blue", 5, 10)
circle = Circle("red", 7)

print(rect.description())    # A blue rectangle with area 50 sq units
print(circle.description())  # A red circle with area 153.94 sq units
```

## Extending Parent Methods

Sometimes you want to extend (not completely replace) a parent's method. Use `super()` to call the parent's version first.

```python
class BankAccount:
    def __init__(self, account_number, balance=0):
        self.account_number = account_number
        self.balance = balance
        self.transactions = []
    
    def deposit(self, amount):
        if amount > 0:
            self.balance += amount
            self.transactions.append(f"Deposit: +${amount}")
            return True
        return False

class SavingsAccount(BankAccount):
    def __init__(self, account_number, balance=0, interest_rate=0.02):
        super().__init__(account_number, balance)
        self.interest_rate = interest_rate
    
    def deposit(self, amount):
        # Call parent's deposit first
        success = super().deposit(amount)
        
        if success:
            # Add extra functionality
            interest = amount * self.interest_rate
            self.balance += interest
            self.transactions.append(f"Interest earned: +${interest:.2f}")
            return True
        return False
    
    def apply_monthly_interest(self):
        interest = self.balance * self.interest_rate
        self.balance += interest
        self.transactions.append(f"Monthly interest: +${interest:.2f}")

# Usage
savings = SavingsAccount("SA1001", 1000, 0.03)
savings.deposit(500)

print(f"Balance: ${savings.balance:.2f}")
# Output: Balance: $1515.00 (1000 + 500 + 15 interest)

for transaction in savings.transactions:
    print(transaction)
# Output:
# Deposit: +$500
# Interest earned: +$15.00
```

## Multiple Inheritance

Python supports multiple inheritance, where a class can inherit from multiple parent classes.

```python
class Flyable:
    def fly(self):
        return "Flying through the air!"

class Swimmable:
    def swim(self):
        return "Swimming through water!"

class Duck(Animal, Flyable, Swimmable):
    def __init__(self, name):
        Animal.__init__(self, name, "Duck")
    
    def make_sound(self):
        return "Quack! Quack!"

# Usage
duck = Duck("Donald")
print(duck.info())         # From Animal
print(duck.make_sound())   # Overridden
print(duck.fly())          # From Flyable
print(duck.swim())         # From Swimmable
```

### Multiple Inheritance Caution

Multiple inheritance can lead to the "Diamond Problem" where the inheritance hierarchy forms a diamond shape and method resolution becomes ambiguous.

```python
class A:
    def method(self):
        return "Method from A"

class B(A):
    def method(self):
        return "Method from B"

class C(A):
    def method(self):
        return "Method from C"

class D(B, C):  # Diamond problem
    pass

# Python uses Method Resolution Order (MRO)
d = D()
print(d.method())          # Method from B
print(D.mro())             # Shows the resolution order
# [<class 'D'>, <class 'B'>, <class 'C'>, <class 'A'>, <class 'object'>]
```

## Method Resolution Order (MRO)

Python uses the C3 Linearization algorithm to determine the order in which classes are searched for methods and attributes.

```python
class Base:
    def greet(self):
        return "Hello from Base"

class Left(Base):
    def greet(self):
        return "Hello from Left"

class Right(Base):
    def greet(self):
        return "Hello from Right"

class Child(Left, Right):
    pass

# Check MRO
print(Child.mro())
# [<class 'Child'>, <class 'Left'>, <class 'Right'>, <class 'Base'>, <class 'object'>]

child = Child()
print(child.greet())  # Hello from Left (Left comes before Right in MRO)
```

## Practical Example: Employee Management System

```python
class Employee:
    """Base class for all employees"""
    
    company_name = "TechCorp"
    
    def __init__(self, name, employee_id, salary):
        self.name = name
        self.employee_id = employee_id
        self.salary = salary
        self.department = None
    
    def get_details(self):
        return f"Employee: {self.name}, ID: {self.employee_id}"
    
    def calculate_annual_salary(self):
        return self.salary * 12
    
    def __str__(self):
        return f"{self.name} ({self.employee_id}) - ${self.salary}/month"


class Developer(Employee):
    """Developer class inheriting from Employee"""
    
    def __init__(self, name, employee_id, salary, programming_languages):
        super().__init__(name, employee_id, salary)
        self.programming_languages = programming_languages
        self.department = "Engineering"
        self.projects = []
    
    def add_project(self, project_name):
        self.projects.append(project_name)
    
    def get_details(self):
        base_details = super().get_details()
        languages = ", ".join(self.programming_languages)
        return f"{base_details}, Languages: {languages}"
    
    def calculate_annual_salary(self):
        # Developers get 10% bonus
        base_salary = super().calculate_annual_salary()
        return base_salary * 1.10


class Manager(Employee):
    """Manager class inheriting from Employee"""
    
    def __init__(self, name, employee_id, salary, department):
        super().__init__(name, employee_id, salary)
        self.department = department
        self.team_members = []
    
    def add_team_member(self, employee):
        if isinstance(employee, Employee):
            self.team_members.append(employee)
            employee.department = self.department
    
    def get_team_size(self):
        return len(self.team_members)
    
    def calculate_annual_salary(self):
        # Managers get 20% bonus
        base_salary = super().calculate_annual_salary()
        return base_salary * 1.20
    
    def get_details(self):
        base_details = super().get_details()
        return f"{base_details}, Department: {self.department}, Team Size: {self.get_team_size()}"


class SeniorDeveloper(Developer):
    """Senior developer with mentoring capabilities"""
    
    def __init__(self, name, employee_id, salary, programming_languages, years_experience):
        super().__init__(name, employee_id, salary, programming_languages)
        self.years_experience = years_experience
        self.mentees = []
    
    def add_mentee(self, developer):
        if isinstance(developer, Developer):
            self.mentees.append(developer)
    
    def calculate_annual_salary(self):
        # Senior developers get 25% bonus
        base_salary = Employee.calculate_annual_salary(self)
        return base_salary * 1.25
    
    def get_details(self):
        base_details = super().get_details()
        return f"{base_details}, Experience: {self.years_experience} years, Mentees: {len(self.mentees)}"


# Usage Example
def main():
    # Create employees
    dev1 = Developer("Alice Smith", "D1001", 8000, ["Python", "JavaScript"])
    dev2 = Developer("Bob Johnson", "D1002", 7500, ["Java", "C++"])
    senior_dev = SeniorDeveloper("Carol White", "SD1001", 12000, 
                                  ["Python", "Go", "Rust"], 8)
    manager = Manager("David Brown", "M1001", 15000, "Engineering")
    
    # Build team structure
    manager.add_team_member(dev1)
    manager.add_team_member(dev2)
    manager.add_team_member(senior_dev)
    
    senior_dev.add_mentee(dev1)
    senior_dev.add_mentee(dev2)
    
    dev1.add_project("E-commerce Platform")
    dev1.add_project("Mobile App")
    
    # Display information
    print("=" * 70)
    print(f"Company: {Employee.company_name}")
    print("=" * 70)
    
    for employee in [dev1, dev2, senior_dev, manager]:
        print(f"\n{employee.get_details()}")
        print(f"Department: {employee.department}")
        print(f"Annual Salary: ${employee.calculate_annual_salary():,.2f}")
        
        if isinstance(employee, Developer) and not isinstance(employee, SeniorDeveloper):
            print(f"Projects: {', '.join(employee.projects) if employee.projects else 'None'}")
        
        if isinstance(employee, SeniorDeveloper):
            print(f"Projects: {', '.join(employee.projects) if employee.projects else 'None'}")
            print(f"Mentoring: {len(employee.mentees)} developers")
        
        if isinstance(employee, Manager):
            print(f"Managing: {employee.get_team_size()} team members")
    
    print("\n" + "=" * 70)

if __name__ == "__main__":
    main()
```

**Output:**
```
======================================================================
Company: TechCorp
======================================================================

Employee: Alice Smith, ID: D1001, Languages: Python, JavaScript
Department: Engineering
Annual Salary: $105,600.00
Projects: E-commerce Platform, Mobile App

Employee: Bob Johnson, ID: D1002, Languages: Java, C++
Department: Engineering
Annual Salary: $99,000.00
Projects: None

Employee: Carol White, ID: SD1001, Languages: Python, Go, Rust, Experience: 8 years, Mentees: 2
Department: Engineering
Annual Salary: $180,000.00
Projects: None
Mentoring: 2 developers

Employee: David Brown, ID: M1001, Department: Engineering, Team Size: 3
Department: Engineering
Annual Salary: $216,000.00
Managing: 3 team members

======================================================================
```

## Checking Inheritance Relationships

Python provides built-in functions to check class relationships:

```python
# isinstance() - checks if an object is an instance of a class
print(isinstance(dev1, Developer))      # True
print(isinstance(dev1, Employee))       # True
print(isinstance(dev1, Manager))        # False

# issubclass() - checks if a class is a subclass of another
print(issubclass(Developer, Employee))  # True
print(issubclass(Manager, Employee))    # True
print(issubclass(Employee, Developer))  # False

# Check class hierarchy
print(type(dev1))                       # <class '__main__.Developer'>
print(type(dev1).__bases__)             # (<class '__main__.Employee'>,)
```

## Best Practices for Inheritance

### 1. Follow the Liskov Substitution Principle
A child class should be substitutable for its parent class without breaking functionality.

```python
def give_annual_review(employee: Employee):
    """This function should work with any Employee subclass"""
    print(f"Reviewing {employee.name}")
    print(f"Annual salary: ${employee.calculate_annual_salary():,.2f}")

# Works with all Employee subclasses
give_annual_review(dev1)
give_annual_review(manager)
give_annual_review(senior_dev)
```

### 2. Prefer Composition Over Inheritance
If the relationship is "has-a" rather than "is-a", use composition instead.

```python
# GOOD: Composition (has-a relationship)
class Engine:
    def start(self):
        return "Engine started"

class Car:
    def __init__(self):
        self.engine = Engine()  # Car HAS-AN Engine
    
    def start(self):
        return self.engine.start()

# AVOID: Unnecessary inheritance
class Car(Engine):  # Car IS-AN Engine? No, this doesn't make sense!
    pass
```

### 3. Keep Inheritance Hierarchies Shallow
Deep inheritance trees are harder to understand and maintain. Try to limit depth to 2-3 levels.

### 4. Use `super()` Consistently
Always use `super()` instead of directly calling parent methods by name.

```python
# GOOD
class Child(Parent):
    def __init__(self):
        super().__init__()

# AVOID
class Child(Parent):
    def __init__(self):
        Parent.__init__(self)  # Less flexible, especially with multiple inheritance
```

## Common Mistakes

### 1. Forgetting to Call Parent's `__init__`

```python
class Parent:
    def __init__(self, name):
        self.name = name

class ChildBad(Parent):
    def __init__(self, name, age):
        # Forgot to call super().__init__()!
        self.age = age

child = ChildBad("Alice", 25)
print(child.name)  # AttributeError: 'ChildBad' object has no attribute 'name'

# CORRECT VERSION
class ChildGood(Parent):
    def __init__(self, name, age):
        super().__init__(name)  # Initialize parent's attributes
        self.age = age

child = ChildGood("Alice", 25)
print(child.name)  # Alice
```

### 2. Overusing Multiple Inheritance

```python
# AVOID: Complex multiple inheritance
class A: pass
class B(A): pass
class C(A): pass
class D(B, C): pass
class E(D): pass  # Getting too complex!

# PREFER: Simpler hierarchies or composition
```

### 3. Breaking Parent's Contract

```python
class BankAccount:
    def withdraw(self, amount):
        if amount <= self.balance:
            self.balance -= amount
            return True
        return False

class SavingsAccountBad(BankAccount):
    def withdraw(self, amount):
        # BAD: Changes behavior - always raises exception
        raise Exception("Cannot withdraw from savings!")
        # This breaks the parent's contract (should return True/False)
```

## Summary

**Key Concepts:**
- ✅ Inheritance enables code reuse and establishes "is-a" relationships
- ✅ Use `super()` to call parent class methods
- ✅ Child classes can override parent methods
- ✅ Method Resolution Order (MRO) determines method lookup in multiple inheritance
- ✅ Use `isinstance()` and `issubclass()` to check relationships
- ✅ Follow the Liskov Substitution Principle
- ✅ Prefer composition over inheritance for "has-a" relationships
- ✅ Keep inheritance hierarchies shallow and simple

**When to Use Inheritance:**
- ✅ Clear "is-a" relationship exists
- ✅ Need to reuse common functionality across related classes
- ✅ Want to establish a type hierarchy
- ✅ Child classes extend or specialize parent behavior

**When NOT to Use Inheritance:**
- ❌ Relationship is "has-a" (use composition)
- ❌ Just for code reuse (use composition or functions)
- ❌ Creating deep, complex hierarchies
- ❌ Breaking parent class contracts

In the next section, we'll explore **Polymorphism**, which allows objects of different classes to be treated uniformly through inheritance!

---

**கற்க கசடற** - Master inheritance and build flexible, maintainable class hierarchies!
