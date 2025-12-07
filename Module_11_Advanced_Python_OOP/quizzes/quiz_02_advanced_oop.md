# Module 11 - Quiz 02: Advanced OOP Concepts

## Instructions
- Total Questions: 20
- Time: 35 minutes
- Topics: Special Methods, Properties, ABC, Composition, Design Patterns
- Answer all questions

---

## Part 1: Multiple Choice (1 point each)

### Question 1
What is the purpose of the `__str__()` method?
- A) To convert the object to an integer
- B) To provide a readable string representation for users
- C) To compare two objects
- D) To delete an object

**Answer:** B

**Explanation:** `__str__()` returns a string representation of the object intended for end-users. It's called by `str()` and `print()`.

---

### Question 2
Which special method is called when using the `+` operator?
- A) `__plus__()`
- B) `__add__()`
- C) `__sum__()`
- D) `__combine__()`

**Answer:** B

**Explanation:** The `__add__()` method defines behavior for the addition operator `+`. When you write `a + b`, Python calls `a.__add__(b)`.

---

### Question 3
What does the `@property` decorator do?
- A) Makes a method public
- B) Converts a method into a read-only attribute
- C) Creates a class variable
- D) Defines an abstract method

**Answer:** B

**Explanation:** `@property` allows you to define a method that can be accessed like an attribute, providing controlled access to private data with getter/setter logic.

---

### Question 4
Which module provides Abstract Base Classes in Python?
- A) abstract
- B) abc
- C) base
- D) interface

**Answer:** B

**Explanation:** The `abc` module (Abstract Base Classes) provides infrastructure for defining abstract base classes in Python.

---

### Question 5
What is the purpose of the `@abstractmethod` decorator?
- A) To make a method private
- B) To indicate a method must be implemented by subclasses
- C) To make a method static
- D) To cache method results

**Answer:** B

**Explanation:** `@abstractmethod` marks a method as abstract, meaning any concrete subclass must provide an implementation of that method.

---

### Question 6
What is composition in OOP?
- A) Inheriting from multiple classes
- B) Building complex objects from simpler ones (has-a relationship)
- C) Breaking down classes into smaller classes
- D) Converting object types

**Answer:** B

**Explanation:** Composition is a design principle where a class contains instances of other classes as attributes, establishing a "has-a" relationship (e.g., Car has-a Engine).

---

### Question 7
Which special method enables iteration over an object?
- A) `__iterate__()`
- B) `__loop__()`
- C) `__iter__()`
- D) `__next__()`

**Answer:** C

**Explanation:** `__iter__()` returns an iterator object. Combined with `__next__()`, it enables using an object in for loops and iteration contexts.

---

### Question 8
What does the Strategy Pattern do?
- A) Defines a family of algorithms and makes them interchangeable
- B) Creates objects without specifying their exact classes
- C) Notifies multiple objects about state changes
- D) Restricts object creation to one instance

**Answer:** A

**Explanation:** The Strategy Pattern defines a family of algorithms, encapsulates each one, and makes them interchangeable, allowing the algorithm to vary independently from clients.

---

### Question 9
Which special method is called to get the length of an object?
- A) `__size__()`
- B) `__length__()`
- C) `__len__()`
- D) `__count__()`

**Answer:** C

**Explanation:** `__len__()` is called by the built-in `len()` function to return the length of an object.

---

### Question 10
What is a descriptor in Python?
- A) A comment describing a class
- B) An object that defines `__get__()`, `__set__()`, or `__delete__()` methods
- C) A type of iterator
- D) A documentation string

**Answer:** B

**Explanation:** Descriptors are objects that define how attributes are accessed, set, or deleted through `__get__()`, `__set__()`, and `__delete__()` methods.

---

## Part 2: True/False (1 point each)

### Question 11
The `__repr__()` method should return a string that, when passed to `eval()`, recreates the object.

**Answer:** True

**Explanation:** By convention, `__repr__()` should return a string that looks like a valid Python expression that could recreate the object (though this isn't always possible or practical).

---

### Question 12
You can create an instance of an abstract base class.

**Answer:** False

**Explanation:** Abstract base classes cannot be instantiated directly. You must create a concrete subclass that implements all abstract methods.

---

### Question 13
The Observer Pattern is used to notify dependent objects about state changes.

**Answer:** True

**Explanation:** The Observer Pattern defines a one-to-many dependency where when one object changes state, all its dependents are notified automatically.

---

### Question 14
Property setters can include validation logic.

**Answer:** True

**Explanation:** Property setters (`@property_name.setter`) are ideal places to include validation logic, ensuring data integrity before assignment.

---

### Question 15
Composition is generally preferred over inheritance ("composition over inheritance").

**Answer:** True

**Explanation:** Modern OOP design often favors composition because it provides more flexibility, better encapsulation, and avoids problems like fragile base class issues.

---

## Part 3: Code Analysis (2 points each)

### Question 16
What will this print?

```python
class Vector:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def __add__(self, other):
        return Vector(self.x + other.x, self.y + other.y)
    
    def __str__(self):
        return f"Vector({self.x}, {self.y})"

v1 = Vector(1, 2)
v2 = Vector(3, 4)
v3 = v1 + v2
print(v3)
```

- A) Vector(1, 2)
- B) Vector(3, 4)
- C) Vector(4, 6)
- D) Error

**Answer:** C

**Explanation:** The `__add__()` method adds corresponding components: x: 1+3=4, y: 2+4=6. `__str__()` formats the output as "Vector(4, 6)".

---

### Question 17
What happens when you try to instantiate this class?

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self):
        pass

s = Shape()
```

- A) Creates a Shape instance
- B) Raises TypeError
- C) Returns None
- D) Creates an empty object

**Answer:** B

**Explanation:** You cannot instantiate an abstract base class. Python raises `TypeError: Can't instantiate abstract class Shape with abstract method area`.

---

### Question 18
What is the output?

```python
class Temperature:
    def __init__(self, celsius):
        self._celsius = celsius
    
    @property
    def fahrenheit(self):
        return self._celsius * 9/5 + 32
    
    @fahrenheit.setter
    def fahrenheit(self, value):
        self._celsius = (value - 32) * 5/9

temp = Temperature(0)
print(temp.fahrenheit)
temp.fahrenheit = 100
print(temp.fahrenheit)
```

- A) 0, 100
- B) 32, 212
- C) 32, 100
- D) Error

**Answer:** C

**Explanation:** First print: 0°C = 32°F. After setting fahrenheit to 100, celsius becomes ~37.78, and when read back through the property, it returns 100.

---

### Question 19
What design principle is demonstrated?

```python
class Engine:
    def start(self):
        return "Engine started"

class Car:
    def __init__(self):
        self.engine = Engine()
    
    def start(self):
        return self.engine.start()
```

- A) Inheritance
- B) Composition
- C) Polymorphism
- D) Encapsulation

**Answer:** B

**Explanation:** This demonstrates composition - the `Car` class contains an `Engine` object (has-a relationship) rather than inheriting from Engine.

---

### Question 20
What will be the output?

```python
class MyList:
    def __init__(self, items):
        self.items = items
    
    def __len__(self):
        return len(self.items)
    
    def __getitem__(self, index):
        return self.items[index]

ml = MyList([1, 2, 3, 4, 5])
print(len(ml))
print(ml[2])
```

- A) 5, 2
- B) 5, 3
- C) Error, 3
- D) 4, 2

**Answer:** B

**Explanation:** `__len__()` returns 5 (number of items). `__getitem__(2)` returns the element at index 2, which is 3.

---

## Part 4: Design & Implementation (3 points each)

### Question 21
Which special methods would you implement to make a custom class work with `==` and `<` operators?

**Answer:** `__eq__()` and `__lt__()`

**Explanation:** 
- `__eq__(self, other)` defines equality comparison (`==`)
- `__lt__(self, other)` defines less-than comparison (`<`)
- Other comparison operators: `__le__()` (<=), `__gt__()` (>), `__ge__()` (>=), `__ne__()` (!=)

---

### Question 22
Explain the difference between `__str__()` and `__repr__()`.

**Answer:** 
- `__str__()`: Returns a readable, user-friendly string representation. Called by `str()` and `print()`. Intended for end users.
- `__repr__()`: Returns an unambiguous, developer-friendly representation. Called by `repr()` and in interactive shell. Should ideally be a valid Python expression to recreate the object.

**Example:**
```python
class Point:
    def __str__(self):
        return f"Point at ({self.x}, {self.y})"
    
    def __repr__(self):
        return f"Point(x={self.x}, y={self.y})"
```

---

### Question 23
What are the benefits of using composition over inheritance?

**Answer:**
1. **Flexibility:** Easier to change behavior at runtime by swapping composed objects
2. **Loose Coupling:** Classes are less dependent on each other
3. **Avoids Fragile Base Class Problem:** Changes to base class don't break derived classes
4. **Better Encapsulation:** Implementation details are hidden
5. **Multiple Behaviors:** Can compose multiple objects without multiple inheritance complexity

**Example:** A game character with pluggable components (Health, Attack, Movement) is more flexible than a deep inheritance hierarchy.

---

### Question 24
Describe the Observer Pattern and give a real-world use case.

**Answer:**
The Observer Pattern defines a one-to-many dependency between objects. When the subject's state changes, all registered observers are notified automatically.

**Components:**
- **Subject:** Maintains list of observers and notifies them of changes
- **Observer:** Defines an update interface
- **Concrete Observers:** Implement the update method to react to changes

**Real-world use case:** 
A weather station (subject) that notifies multiple displays (observers) - temperature display, humidity display, forecast display - whenever weather data changes. Each display updates independently when notified.

```python
class WeatherStation(Subject):
    def set_temperature(self, temp):
        self.temperature = temp
        self.notify_all()  # Notify all displays
```

---

### Question 25
Why would you use a Factory Pattern?

**Answer:**
The Factory Pattern provides an interface for creating objects without specifying their exact classes. 

**Benefits:**
1. **Encapsulation:** Object creation logic is centralized
2. **Flexibility:** Easy to add new product types
3. **Decoupling:** Client code doesn't depend on concrete classes
4. **Consistency:** Ensures objects are created correctly

**Example:**
```python
class VehicleFactory:
    @staticmethod
    def create_vehicle(vehicle_type):
        if vehicle_type == "car":
            return Car()
        elif vehicle_type == "truck":
            return Truck()
        # Easy to add new types
```

This allows client code to request vehicles without knowing implementation details.

---

## Scoring Guide

- **45-50 points:** Expert level - Advanced OOP mastery
- **40-44 points:** Advanced - Strong understanding
- **35-39 points:** Proficient - Good grasp of concepts
- **30-34 points:** Developing - Review advanced topics
- **Below 30:** Needs significant review of advanced concepts

---

## Key Concepts Summary

1. **Special Methods:** `__str__`, `__repr__`, `__add__`, `__len__`, `__getitem__`, `__iter__`
2. **Properties:** `@property` decorator for controlled attribute access
3. **Abstract Base Classes:** `ABC` and `@abstractmethod` for defining interfaces
4. **Composition:** Building objects from components (has-a relationship)
5. **Strategy Pattern:** Interchangeable algorithms
6. **Observer Pattern:** Automatic notification of dependent objects
7. **Factory Pattern:** Centralized object creation
8. **Descriptors:** Custom attribute access control
9. **Operator Overloading:** Defining custom behavior for operators
10. **Design Principles:** Composition over inheritance, encapsulation, loose coupling
