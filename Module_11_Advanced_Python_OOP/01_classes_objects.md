# Section 01: Classes and Objects

**கற்க கசடற - Learn Flawlessly**

## Introduction to Object-Oriented Programming

Object-Oriented Programming (OOP) is a programming paradigm that organizes code around **objects** and **classes** rather than functions and logic. It's a way of thinking about and structuring code that mirrors how we think about the real world.

### Why OOP?

Before OOP, we might write code like this:

```python
# Procedural approach
student1_name = "Alice"
student1_age = 20
student1_grades = [85, 90, 88]

student2_name = "Bob"
student2_age = 21
student2_grades = [78, 82, 85]

def calculate_average(grades):
    return sum(grades) / len(grades)

print(f"{student1_name}: {calculate_average(student1_grades)}")
print(f"{student2_name}: {calculate_average(student2_grades)}")
```

This works, but as your program grows, managing many students with many attributes becomes cumbersome. **OOP provides a better way** by grouping related data and functions together.

## What is a Class?

A **class** is a blueprint or template for creating objects. It defines:
- **Attributes**: Data that the object holds (variables)
- **Methods**: Functions that the object can perform (behavior)

Think of a class as a cookie cutter - it defines the shape, but it's not the cookie itself.

```python
class Student:
    """A class representing a student."""
    pass  # We'll add content soon
```

## What is an Object?

An **object** is a specific instance of a class. Using the cookie cutter analogy, an object is the actual cookie made from that cutter.

```python
# Creating objects (instances) from the Student class
student1 = Student()
student2 = Student()

print(type(student1))  # <class '__main__.Student'>
print(student1 is student2)  # False - they're different objects
```

## Creating Your First Class

Let's create a simple `Dog` class:

```python
class Dog:
    """A simple class representing a dog."""
    
    # This is a method (function inside a class)
    def bark(self):
        print("Woof! Woof!")

# Create an instance
my_dog = Dog()
my_dog.bark()  # Output: Woof! Woof!
```

### Understanding `self`

The `self` parameter is a reference to the current instance of the class. It's used to access attributes and methods within the class.

**Important**: You don't pass `self` when calling a method - Python does it automatically!

```python
my_dog.bark()  # Python internally does: Dog.bark(my_dog)
```

## Adding Attributes with `__init__`

The `__init__` method is a special method (called a **constructor**) that runs when you create a new object. It's used to initialize the object's attributes.

```python
class Dog:
    """A dog with a name and age."""
    
    def __init__(self, name, age):
        """Initialize the dog with name and age."""
        self.name = name  # Instance attribute
        self.age = age    # Instance attribute
    
    def bark(self):
        """Make the dog bark."""
        print(f"{self.name} says: Woof! Woof!")
    
    def get_age_in_dog_years(self):
        """Calculate age in dog years (approx 7:1 ratio)."""
        return self.age * 7

# Creating instances with different data
buddy = Dog("Buddy", 3)
luna = Dog("Luna", 5)

buddy.bark()  # Output: Buddy says: Woof! Woof!
luna.bark()   # Output: Luna says: Woof! Woof!

print(f"{buddy.name} is {buddy.get_age_in_dog_years()} in dog years.")
# Output: Buddy is 21 in dog years.
```

## Instance Attributes vs Local Variables

```python
class Example:
    def __init__(self, value):
        self.instance_attr = value  # Instance attribute - persists
        local_var = value * 2       # Local variable - exists only in __init__
    
    def show(self):
        print(self.instance_attr)   # This works
        # print(local_var)          # This would cause an error!

obj = Example(10)
obj.show()  # Output: 10
print(obj.instance_attr)  # Output: 10
```

## Accessing and Modifying Attributes

```python
class Car:
    def __init__(self, brand, model, year):
        self.brand = brand
        self.model = model
        self.year = year
        self.mileage = 0  # Default value
    
    def drive(self, miles):
        """Add miles to the car's mileage."""
        self.mileage += miles
        print(f"Drove {miles} miles. Total mileage: {self.mileage}")
    
    def get_age(self, current_year):
        """Calculate the car's age."""
        return current_year - self.year

# Create a car
my_car = Car("Toyota", "Camry", 2018)

# Access attributes
print(f"Brand: {my_car.brand}")
print(f"Model: {my_car.model}")
print(f"Year: {my_car.year}")

# Modify attributes directly (not always recommended - we'll learn better ways)
my_car.mileage = 5000
print(f"Mileage: {my_car.mileage}")

# Use methods
my_car.drive(150)  # Output: Drove 150 miles. Total mileage: 5150
print(f"Car age: {my_car.get_age(2024)} years")  # Output: Car age: 6 years
```

## Methods with Parameters

```python
class BankAccount:
    def __init__(self, owner, balance=0):
        """Initialize account with owner name and optional starting balance."""
        self.owner = owner
        self.balance = balance
    
    def deposit(self, amount):
        """Add money to the account."""
        if amount > 0:
            self.balance += amount
            print(f"Deposited ${amount}. New balance: ${self.balance}")
        else:
            print("Deposit amount must be positive!")
    
    def withdraw(self, amount):
        """Remove money from the account."""
        if amount > self.balance:
            print("Insufficient funds!")
        elif amount <= 0:
            print("Withdrawal amount must be positive!")
        else:
            self.balance -= amount
            print(f"Withdrew ${amount}. New balance: ${self.balance}")
    
    def get_balance(self):
        """Return the current balance."""
        return self.balance

# Create accounts
alice_account = BankAccount("Alice", 1000)
bob_account = BankAccount("Bob")

# Perform transactions
alice_account.deposit(500)   # Deposited $500. New balance: $1500
alice_account.withdraw(200)  # Withdrew $200. New balance: $1300
bob_account.deposit(100)     # Deposited $100. New balance: $100
bob_account.withdraw(150)    # Insufficient funds!
```

## Multiple Objects, Independent Data

Each object has its own copy of the instance attributes:

```python
class Counter:
    def __init__(self):
        self.count = 0
    
    def increment(self):
        self.count += 1
    
    def get_count(self):
        return self.count

# Create two counters
counter1 = Counter()
counter2 = Counter()

# They're independent!
counter1.increment()
counter1.increment()
counter1.increment()

counter2.increment()

print(f"Counter 1: {counter1.get_count()}")  # Output: 3
print(f"Counter 2: {counter2.get_count()}")  # Output: 1
```

## Practical Example: Student Class

```python
class Student:
    """Represents a student with grades."""
    
    def __init__(self, name, student_id):
        """Initialize student with name and ID."""
        self.name = name
        self.student_id = student_id
        self.grades = []  # Empty list for grades
    
    def add_grade(self, grade):
        """Add a grade to the student's record."""
        if 0 <= grade <= 100:
            self.grades.append(grade)
            print(f"Added grade {grade} for {self.name}")
        else:
            print("Grade must be between 0 and 100!")
    
    def get_average(self):
        """Calculate and return the average grade."""
        if not self.grades:
            return 0
        return sum(self.grades) / len(self.grades)
    
    def get_letter_grade(self):
        """Return letter grade based on average."""
        avg = self.get_average()
        if avg >= 90:
            return 'A'
        elif avg >= 80:
            return 'B'
        elif avg >= 70:
            return 'C'
        elif avg >= 60:
            return 'D'
        else:
            return 'F'
    
    def display_report(self):
        """Display student report card."""
        print(f"\n{'='*40}")
        print(f"Student Report Card")
        print(f"{'='*40}")
        print(f"Name: {self.name}")
        print(f"ID: {self.student_id}")
        print(f"Grades: {self.grades}")
        print(f"Average: {self.get_average():.2f}")
        print(f"Letter Grade: {self.get_letter_grade()}")
        print(f"{'='*40}\n")

# Use the Student class
student1 = Student("Alice Johnson", "S12345")
student1.add_grade(95)
student1.add_grade(87)
student1.add_grade(92)
student1.display_report()

student2 = Student("Bob Smith", "S12346")
student2.add_grade(78)
student2.add_grade(82)
student2.add_grade(85)
student2.add_grade(80)
student2.display_report()
```

Output:
```
Added grade 95 for Alice Johnson
Added grade 87 for Alice Johnson
Added grade 92 for Alice Johnson

========================================
Student Report Card
========================================
Name: Alice Johnson
ID: S12345
Grades: [95, 87, 92]
Average: 91.33
Letter Grade: A
========================================
```

## String Representation: `__str__` and `__repr__`

These special methods control how your object is displayed:

```python
class Book:
    def __init__(self, title, author, year):
        self.title = title
        self.author = author
        self.year = year
    
    def __str__(self):
        """User-friendly string representation."""
        return f"'{self.title}' by {self.author} ({self.year})"
    
    def __repr__(self):
        """Developer-friendly representation."""
        return f"Book('{self.title}', '{self.author}', {self.year})"

book = Book("1984", "George Orwell", 1949)

print(book)        # Uses __str__: '1984' by George Orwell (1949)
print(repr(book))  # Uses __repr__: Book('1984', 'George Orwell', 1949)

# In a list, __repr__ is used
books = [book]
print(books)       # [Book('1984', 'George Orwell', 1949)]
```

## Best Practices for Classes

1. **Use descriptive class names** - Use CamelCase (e.g., `BankAccount`, not `bank_account`)
2. **Write docstrings** - Document what your class does
3. **Initialize all attributes in `__init__`** - Don't create attributes elsewhere
4. **Keep methods focused** - Each method should do one thing well
5. **Use meaningful attribute names** - `balance` is better than `b`
6. **Implement `__str__`** - Makes debugging easier
7. **Group related functionality** - Put related attributes and methods together

## Common Mistakes to Avoid

```python
# ❌ Wrong: Forgetting self
class Wrong:
    def __init__(name):  # Missing self!
        self.name = name

# ✅ Correct:
class Right:
    def __init__(self, name):
        self.name = name

# ❌ Wrong: Mutable default arguments
class Wrong:
    def __init__(self, items=[]):  # DON'T do this!
        self.items = items

# ✅ Correct:
class Right:
    def __init__(self, items=None):
        self.items = items if items is not None else []

# ❌ Wrong: Comparing class and instance
print(Dog == buddy)  # False - comparing class to instance

# ✅ Correct:
print(isinstance(buddy, Dog))  # True
print(type(buddy) == Dog)      # True
```

## Summary

- **Classes** are blueprints for creating objects
- **Objects** are instances of classes with their own data
- **`__init__`** initializes object attributes when created
- **`self`** refers to the current instance
- **Instance attributes** are unique to each object
- **Methods** are functions that operate on object data
- **`__str__`** and **`__repr__`** control object representation

## Key Takeaways

✅ Classes group related data and functions together  
✅ Objects are instances of classes with independent data  
✅ `self` is the first parameter of instance methods  
✅ `__init__` runs automatically when creating objects  
✅ Use methods to work with object data  
✅ Each object has its own copy of instance attributes  

## What's Next?

In the next section, we'll learn about:
- **Instance vs Class attributes** - When to use each
- **Class variables** shared across all instances
- **Attribute access patterns** and naming conventions

---

**Practice Time!** Go to **Lab 01: Classes and Objects** to apply what you've learned.

**கற்க கசடற** - Learn Flawlessly
