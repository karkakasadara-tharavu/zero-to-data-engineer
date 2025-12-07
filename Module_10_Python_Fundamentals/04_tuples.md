# Tuples in Python

## 🎯 Learning Objectives
- Understand what tuples are and when to use them
- Create and access tuple elements
- Learn about tuple immutability
- Use tuple packing and unpacking
- Work with named tuples

---

## 📝 What is a Tuple?

A **tuple** is an ordered, **immutable** collection. Once created, it cannot be modified.

```python
# Creating tuples
coordinates = (10, 20)
rgb_color = (255, 128, 0)
employee = ("John Doe", 30, "Engineer")

# Single element tuple (note the comma!)
single = (42,)  # This is a tuple
not_tuple = (42)  # This is just an integer with parentheses

# Empty tuple
empty = ()
```

---

## 🔍 Tuples vs Lists

| Feature | List | Tuple |
|---------|------|-------|
| **Syntax** | `[1, 2, 3]` | `(1, 2, 3)` |
| **Mutable** | ✅ Yes | ❌ No |
| **Performance** | Slower | Faster |
| **Use Case** | Data that changes | Data that doesn't change |
| **Memory** | More | Less |

```python
# List - mutable
my_list = [1, 2, 3]
my_list[0] = 10  # ✅ Allowed
print(my_list)   # [10, 2, 3]

# Tuple - immutable
my_tuple = (1, 2, 3)
# my_tuple[0] = 10  # ❌ TypeError: 'tuple' object does not support item assignment
```

---

## 📊 Creating Tuples

### Various ways to create tuples

```python
# With parentheses
point = (10, 20)

# Without parentheses (tuple packing)
point = 10, 20

# Using tuple() constructor
from_list = tuple([1, 2, 3])
from_string = tuple("abc")  # ('a', 'b', 'c')

# Mixed data types
person = ("Alice", 25, True, 75000.50)

# Nested tuples
nested = ((1, 2), (3, 4), (5, 6))
```

---

## 🎯 Accessing Tuple Elements

Same as lists - use indexing and slicing.

```python
employee = ("John Doe", 30, "Engineer", 75000)

# Indexing
name = employee[0]       # "John Doe"
age = employee[1]        # 30
position = employee[2]   # "Engineer"
salary = employee[3]     # 75000

# Negative indexing
last = employee[-1]      # 75000 (salary)
second_last = employee[-2]  # "Engineer"

# Slicing
info = employee[0:2]     # ("John Doe", 30)
details = employee[1:]   # (30, "Engineer", 75000)
```

---

## 📦 Tuple Packing and Unpacking

### Packing - Creating tuple without parentheses
```python
# Tuple packing
coordinates = 10, 20, 30
print(coordinates)  # (10, 20, 30)
print(type(coordinates))  # <class 'tuple'>
```

### Unpacking - Extracting values into variables
```python
# Basic unpacking
point = (10, 20)
x, y = point
print(f"x = {x}, y = {y}")  # x = 10, y = 20

# Unpacking with multiple values
person = ("Alice", 25, "Engineer")
name, age, job = person
print(f"{name} is {age} years old and works as {job}")

# Unpacking with * (rest)
numbers = (1, 2, 3, 4, 5)
first, *middle, last = numbers
print(f"First: {first}")      # 1
print(f"Middle: {middle}")    # [2, 3, 4] (as list!)
print(f"Last: {last}")        # 5

# Swapping variables using tuple unpacking
a = 10
b = 20
a, b = b, a  # Elegant swap!
print(f"a = {a}, b = {b}")  # a = 20, b = 10
```

---

## 🔄 Tuple Operations

### Concatenation
```python
tuple1 = (1, 2, 3)
tuple2 = (4, 5, 6)
combined = tuple1 + tuple2
print(combined)  # (1, 2, 3, 4, 5, 6)
```

### Repetition
```python
repeated = (0, 1) * 3
print(repeated)  # (0, 1, 0, 1, 0, 1)
```

### Membership testing
```python
colors = ("red", "green", "blue")
print("red" in colors)     # True
print("yellow" in colors)  # False
```

### Length
```python
data = (10, 20, 30, 40)
print(len(data))  # 4
```

---

## 🔍 Tuple Methods

Tuples have only 2 methods (because they're immutable):

### count() - Count occurrences
```python
numbers = (1, 2, 3, 2, 4, 2, 5)
count = numbers.count(2)
print(count)  # 3
```

### index() - Find first occurrence
```python
fruits = ("apple", "banana", "cherry", "banana")
position = fruits.index("banana")
print(position)  # 1 (first occurrence)

# With start and end
position = fruits.index("banana", 2)  # Search from index 2
print(position)  # 3
```

---

## 🎨 When to Use Tuples

### ✅ Use Tuples When:

1. **Data shouldn't change**
```python
# Database connection config
DB_CONFIG = ("localhost", 5432, "postgres", "admin")

# RGB color values
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
```

2. **Returning multiple values from functions**
```python
def get_user_info():
    return "John", 30, "Engineer"  # Returns tuple

name, age, job = get_user_info()
```

3. **Dictionary keys** (tuples can be keys, lists cannot)
```python
# Store sales by (year, quarter)
sales = {
    (2024, "Q1"): 100000,
    (2024, "Q2"): 120000,
    (2024, "Q3"): 150000
}

print(sales[(2024, "Q2")])  # 120000
```

4. **Performance-critical code** (tuples are faster than lists)
```python
# Coordinates for millions of points
points = [(x, y) for x in range(1000) for y in range(1000)]
```

---

## 📚 Practical Examples

### Example 1: Employee Records
```python
# Employee tuple: (id, name, department, salary)
employees = [
    (101, "Alice Johnson", "Engineering", 85000),
    (102, "Bob Smith", "Marketing", 65000),
    (103, "Carol White", "Sales", 72000)
]

# Process employees
for emp_id, name, dept, salary in employees:
    print(f"ID: {emp_id}, Name: {name}, Dept: {dept}, Salary: ${salary:,}")

# Find employee by ID
target_id = 102
for employee in employees:
    if employee[0] == target_id:
        print(f"\nFound: {employee[1]} in {employee[2]}")
```

### Example 2: Database Query Results
```python
# Simulating database query result (typically returns tuples)
query_result = [
    ("Product A", 99.99, 50),
    ("Product B", 149.99, 30),
    ("Product C", 79.99, 100)
]

# Calculate total inventory value
total_value = 0
for product_name, price, quantity in query_result:
    item_value = price * quantity
    total_value += item_value
    print(f"{product_name}: ${item_value:,.2f}")

print(f"\nTotal Inventory Value: ${total_value:,.2f}")
```

### Example 3: Function Returning Multiple Values
```python
def calculate_statistics(numbers):
    """Calculate min, max, avg from list of numbers"""
    minimum = min(numbers)
    maximum = max(numbers)
    average = sum(numbers) / len(numbers)
    return minimum, maximum, average  # Returns tuple

# Use the function
data = [10, 20, 30, 40, 50]
min_val, max_val, avg_val = calculate_statistics(data)

print(f"Min: {min_val}")
print(f"Max: {max_val}")
print(f"Average: {avg_val}")
```

### Example 4: Swapping Without Temporary Variable
```python
# Old way (other languages)
a = 10
b = 20
temp = a
a = b
b = temp

# Python way (using tuple unpacking)
a, b = b, a
print(f"a = {a}, b = {b}")  # a = 20, b = 10
```

---

## 🎓 Named Tuples

Named tuples give meaning to each position and allow access by name.

```python
from collections import namedtuple

# Define a named tuple
Employee = namedtuple('Employee', ['id', 'name', 'department', 'salary'])

# Create instances
emp1 = Employee(101, "Alice", "Engineering", 85000)
emp2 = Employee(102, "Bob", "Marketing", 65000)

# Access by name (more readable!)
print(emp1.name)        # Alice
print(emp1.salary)      # 85000

# Access by index (still works)
print(emp1[0])          # 101

# Unpack like regular tuple
emp_id, name, dept, salary = emp1
print(f"{name} works in {dept}")

# Convert to dictionary
emp_dict = emp1._asdict()
print(emp_dict)
# OrderedDict([('id', 101), ('name', 'Alice'), ...])
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Forgetting comma for single-element tuple
```python
# ❌ Wrong - this is just an integer
not_tuple = (42)
print(type(not_tuple))  # <class 'int'>

# ✅ Correct - need comma
tuple_one = (42,)
print(type(tuple_one))  # <class 'tuple'>
```

### Mistake 2: Trying to modify tuple
```python
# ❌ Wrong - tuples are immutable
point = (10, 20)
# point[0] = 15  # TypeError!

# ✅ Correct - create new tuple
point = (15, 20)

# Or convert to list, modify, convert back
point_list = list(point)
point_list[0] = 15
point = tuple(point_list)
```

### Mistake 3: Mutable objects in tuples
```python
# Tuple itself is immutable, but mutable objects inside can change
tuple_with_list = (1, 2, [3, 4])
tuple_with_list[2].append(5)  # This works!
print(tuple_with_list)  # (1, 2, [3, 4, 5])

# The list inside the tuple was modified, not the tuple structure
```

---

## 🎯 Tuple vs List - Decision Guide

**Choose Tuple when:**
- ✅ Data represents a record with fixed structure
- ✅ Data should not be modified
- ✅ Need to use as dictionary key
- ✅ Performance is critical
- ✅ Returning multiple values from function

**Choose List when:**
- ✅ Collection of similar items (homogeneous)
- ✅ Size will change (add/remove elements)
- ✅ Order might change (sorting)
- ✅ Need list methods (append, extend, etc.)

---

## 💡 Real-World Use Cases

### Use Case 1: Configuration Data
```python
# Database configurations (shouldn't change at runtime)
DATABASE_CONFIGS = {
    'production': ('prod.db.com', 5432, 'prod_db'),
    'staging': ('stage.db.com', 5432, 'stage_db'),
    'development': ('localhost', 5432, 'dev_db')
}

# Get config
host, port, database = DATABASE_CONFIGS['production']
```

### Use Case 2: Geographic Coordinates
```python
# Store city locations (latitude, longitude)
cities = {
    'New York': (40.7128, -74.0060),
    'London': (51.5074, -0.1278),
    'Tokyo': (35.6762, 139.6503)
}

# Calculate distance (simplified)
ny_lat, ny_lon = cities['New York']
london_lat, london_lon = cities['London']
```

### Use Case 3: Date/Time Representations
```python
# Date as tuple: (year, month, day)
today = (2025, 12, 7)
year, month, day = today

# Time as tuple: (hour, minute, second)
current_time = (14, 30, 45)
hour, minute, second = current_time

print(f"Date: {year}-{month:02d}-{day:02d}")
print(f"Time: {hour:02d}:{minute:02d}:{second:02d}")
```

---

## ✅ Key Takeaways

1. ✅ Tuples are immutable ordered collections
2. ✅ Use parentheses `()` or just commas
3. ✅ Single element needs trailing comma: `(42,)`
4. ✅ Perfect for fixed data structures
5. ✅ Support indexing and slicing like lists
6. ✅ Only 2 methods: count() and index()
7. ✅ Great for returning multiple values
8. ✅ Can be dictionary keys (lists cannot)
9. ✅ Faster and use less memory than lists
10. ✅ Use named tuples for better readability

---

**Practice**: Complete Lab 02 - Working with Lists and Tuples

**Next Section**: 05_dictionaries.md

**கற்க கசடற** - Learn Flawlessly

