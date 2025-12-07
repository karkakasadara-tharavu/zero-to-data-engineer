# Module 11 - Quiz 01: OOP Fundamentals

## Instructions
- Total Questions: 20
- Time: 30 minutes
- Topics: Classes, Objects, Inheritance, Polymorphism, Encapsulation
- Answer all questions

---

## Part 1: Multiple Choice (1 point each)

### Question 1
What is the primary purpose of a class in Python?
- A) To store data permanently
- B) To serve as a blueprint for creating objects
- C) To execute functions faster
- D) To replace modules

**Answer:** B

**Explanation:** A class is a blueprint or template that defines the structure and behavior of objects. It specifies what attributes (data) and methods (functions) objects of that class will have.

---

### Question 2
Which method is automatically called when a new object is created?
- A) `__new__()`
- B) `__create__()`
- C) `__init__()`
- D) `__start__()`

**Answer:** C

**Explanation:** `__init__()` is the constructor method that Python automatically calls when creating a new instance of a class. It initializes the object's attributes.

---

### Question 3
What does `self` represent in a class method?
- A) The class itself
- B) The current instance of the class
- C) The parent class
- D) A global variable

**Answer:** B

**Explanation:** `self` is a reference to the current instance of the class. It allows you to access the instance's attributes and methods.

---

### Question 4
What is inheritance in OOP?
- A) Copying code from one file to another
- B) A mechanism where a class acquires properties from another class
- C) A way to hide implementation details
- D) A method to improve performance

**Answer:** B

**Explanation:** Inheritance allows a class (child/derived class) to inherit attributes and methods from another class (parent/base class), promoting code reuse.

---

### Question 5
Which keyword is used to inherit from a parent class?
- A) extends
- B) inherits
- C) super
- D) Parentheses with parent class name

**Answer:** D

**Explanation:** In Python, you inherit by placing the parent class name in parentheses after the child class name: `class Child(Parent):`

---

### Question 6
What is method overriding?
- A) Creating a new method with a different name
- B) Deleting a method from the parent class
- C) Redefining a parent class method in the child class
- D) Calling the same method multiple times

**Answer:** C

**Explanation:** Method overriding occurs when a child class provides a specific implementation of a method already defined in its parent class.

---

### Question 7
What is encapsulation?
- A) Creating objects from classes
- B) Bundling data and methods together, restricting direct access
- C) Inheriting from multiple classes
- D) Converting data types

**Answer:** B

**Explanation:** Encapsulation is the principle of bundling data (attributes) and methods that operate on that data within a single unit (class), while restricting direct access to some components.

---

### Question 8
How do you make an attribute private in Python?
- A) Use the `private` keyword
- B) Start the attribute name with double underscore `__`
- C) Use the `protected` keyword
- D) Wrap it in brackets

**Answer:** B

**Explanation:** In Python, prefixing an attribute name with double underscores `__` triggers name mangling, making it harder to access from outside the class (convention for private attributes).

---

### Question 9
What is polymorphism in OOP?
- A) Creating multiple objects from one class
- B) The ability of different classes to respond to the same method call
- C) Hiding implementation details
- D) Converting one data type to another

**Answer:** B

**Explanation:** Polymorphism allows objects of different classes to be treated as objects of a common base class, and to respond to the same method call in their own way.

---

### Question 10
What is the purpose of the `super()` function?
- A) To create a superclass
- B) To access methods and attributes of the parent class
- C) To delete the parent class
- D) To check if a class is a parent

**Answer:** B

**Explanation:** `super()` provides a way to call methods from the parent class, commonly used to call the parent's `__init__()` method in the child class.

---

## Part 2: True/False (1 point each)

### Question 11
A class can have multiple `__init__()` methods with different parameters.

**Answer:** False

**Explanation:** Python does not support method overloading in the traditional sense. You can only have one `__init__()` method per class. However, you can use default parameters or `*args` and `**kwargs` to handle different initialization scenarios.

---

### Question 12
Class variables are shared among all instances of a class.

**Answer:** True

**Explanation:** Class variables are defined at the class level and are shared by all instances. Changes to a class variable affect all instances.

---

### Question 13
Instance variables must be declared before the `__init__()` method.

**Answer:** False

**Explanation:** Instance variables are typically created inside `__init__()` or other instance methods. They don't need to be declared separately before the method.

---

### Question 14
A child class can inherit from multiple parent classes in Python.

**Answer:** True

**Explanation:** Python supports multiple inheritance, allowing a class to inherit from more than one parent class: `class Child(Parent1, Parent2):`.

---

### Question 15
Private attributes cannot be accessed outside the class under any circumstances.

**Answer:** False

**Explanation:** In Python, "private" attributes (prefixed with `__`) are name-mangled but can still be accessed using `_ClassName__attribute`. Privacy is more of a convention than strict enforcement.

---

## Part 3: Code Analysis (2 points each)

### Question 16
What will be the output?

```python
class Animal:
    def __init__(self, name):
        self.name = name
    
    def speak(self):
        return "Some sound"

class Dog(Animal):
    def speak(self):
        return "Woof!"

dog = Dog("Max")
print(dog.speak())
```

- A) Some sound
- B) Woof!
- C) Error
- D) None

**Answer:** B

**Explanation:** The `Dog` class overrides the `speak()` method from `Animal`. When `dog.speak()` is called, it executes the `Dog` class's version, returning "Woof!".

---

### Question 17
What is the value of `count` after execution?

```python
class Counter:
    count = 0
    
    def __init__(self):
        Counter.count += 1

c1 = Counter()
c2 = Counter()
c3 = Counter()
print(Counter.count)
```

- A) 0
- B) 1
- C) 3
- D) Error

**Answer:** C

**Explanation:** `count` is a class variable incremented in `__init__()` for each instance. Three instances are created, so `count` becomes 3.

---

### Question 18
What is wrong with this code?

```python
class Person:
    def __init__(self, name):
        name = name

p = Person("Alice")
print(p.name)
```

- A) Nothing, it works fine
- B) Missing `self.` before `name` in assignment
- C) `__init__` should return a value
- D) Class name should be lowercase

**Answer:** B

**Explanation:** The assignment should be `self.name = name` to create an instance variable. Without `self.`, it's just a local variable that gets discarded.

---

### Question 19
What will this print?

```python
class Parent:
    def greet(self):
        return "Hello from Parent"

class Child(Parent):
    def greet(self):
        parent_msg = super().greet()
        return f"{parent_msg} and Child"

c = Child()
print(c.greet())
```

- A) Hello from Parent
- B) Hello from Parent and Child
- C) and Child
- D) Error

**Answer:** B

**Explanation:** `super().greet()` calls the parent's `greet()` method, which returns "Hello from Parent". The child then appends " and Child" to it.

---

### Question 20
How many instances of `Student` exist after this code?

```python
class Student:
    def __init__(self, name):
        self.name = name

students = [Student(f"Student{i}") for i in range(5)]
students[2] = None
```

- A) 3
- B) 4
- C) 5
- D) 0

**Answer:** B

**Explanation:** Five `Student` objects are created initially. Setting `students[2] = None` removes the reference to one object (which will be garbage collected), leaving 4 active instances.

---

## Scoring Guide

- **18-20 points:** Excellent understanding of OOP fundamentals
- **15-17 points:** Good grasp of concepts, minor review needed
- **12-14 points:** Adequate knowledge, review key topics
- **Below 12:** Needs significant review of OOP fundamentals

---

## Key Concepts Summary

1. **Classes & Objects:** Classes are blueprints; objects are instances
2. **`__init__()`:** Constructor method for initialization
3. **`self`:** Reference to the current instance
4. **Inheritance:** Mechanism for code reuse and extension
5. **Method Overriding:** Child class redefines parent's method
6. **Encapsulation:** Bundling data with methods, hiding implementation
7. **Private Attributes:** Use `__` prefix for name mangling
8. **Polymorphism:** Different classes respond to same method differently
9. **`super()`:** Access parent class methods
10. **Class vs Instance Variables:** Shared vs per-instance data
