# Dictionaries in Python

## 🎯 Learning Objectives
- Understand dictionaries and key-value pairs
- Create and modify dictionaries
- Access, add, update, and remove items
- Use dictionary methods effectively
- Work with nested dictionaries
- Understand dictionary comprehensions

---

## 📝 What is a Dictionary?

A **dictionary** is an unordered collection of **key-value pairs**. Think of it like a real dictionary where words (keys) have definitions (values).

```python
# Creating a dictionary
student = {
    "name": "Alice Johnson",
    "age": 20,
    "major": "Computer Science",
    "gpa": 3.85
}

# Empty dictionary
empty_dict = {}
# Or
empty_dict = dict()
```

**Key Features:**
- ✅ Unordered (Python 3.7+ maintains insertion order)
- ✅ Mutable (can be changed)
- ✅ Keys must be unique and immutable
- ✅ Values can be any type
- ✅ Fast lookup by key

---

## 🔑 Keys and Values

### Valid Keys (Immutable Types):
```python
# ✅ Valid keys
data = {
    "string_key": "value",       # String
    42: "integer key",            # Integer
    3.14: "float key",            # Float
    (1, 2): "tuple key",          # Tuple
    True: "boolean key"           # Boolean
}

# ❌ Invalid keys (mutable types)
# bad_dict = {
#     [1, 2]: "value"  # List - TypeError!
#     {}: "value"      # Dict - TypeError!
# }
```

### Values Can Be Anything:
```python
flexible_dict = {
    "name": "Alice",                    # String
    "age": 25,                          # Integer
    "scores": [85, 90, 92],            # List
    "address": {"city": "NYC"},        # Dictionary
    "hobbies": ("reading", "coding"),  # Tuple
    "active": True,                     # Boolean
    "metadata": None                    # None
}
```

---

## 📊 Creating Dictionaries

### Method 1: Literal Syntax
```python
person = {
    "name": "John Doe",
    "age": 30,
    "city": "New York"
}
```

### Method 2: dict() Constructor
```python
# From keyword arguments
person = dict(name="John Doe", age=30, city="New York")

# From list of tuples
pairs = [("name", "John"), ("age", 30), ("city", "NYC")]
person = dict(pairs)

# From two lists (using zip)
keys = ["name", "age", "city"]
values = ["John", 30, "NYC"]
person = dict(zip(keys, values))
```

### Method 3: Dictionary Comprehension
```python
# Create dictionary from list
numbers = [1, 2, 3, 4, 5]
squares = {num: num**2 for num in numbers}
print(squares)  # {1: 1, 2: 4, 3: 9, 4: 16, 5: 25}
```

---

## 🔍 Accessing Dictionary Values

### Using Square Brackets
```python
student = {
    "name": "Alice",
    "age": 20,
    "major": "CS"
}

# Access values
name = student["name"]    # "Alice"
age = student["age"]      # 20

# ❌ KeyError if key doesn't exist
# grade = student["grade"]  # KeyError: 'grade'
```

### Using get() Method (Safer)
```python
# get() returns None if key doesn't exist
grade = student.get("grade")       # None
major = student.get("major")       # "CS"

# Provide default value
grade = student.get("grade", "N/A")  # "N/A"
gpa = student.get("gpa", 0.0)        # 0.0
```

---

## ➕ Adding and Updating Items

### Adding New Key-Value Pairs
```python
student = {"name": "Alice", "age": 20}

# Add new item
student["major"] = "Computer Science"
student["gpa"] = 3.85

print(student)
# {'name': 'Alice', 'age': 20, 'major': 'Computer Science', 'gpa': 3.85}
```

### Updating Existing Values
```python
student = {"name": "Alice", "age": 20, "gpa": 3.50}

# Update single value
student["gpa"] = 3.85

# Update multiple values using update()
student.update({"age": 21, "year": "Junior"})

print(student)
# {'name': 'Alice', 'age': 21, 'gpa': 3.85, 'year': 'Junior'}
```

### update() with Different Sources
```python
profile = {"name": "Bob", "age": 25}

# Update from another dictionary
profile.update({"city": "NYC", "job": "Engineer"})

# Update from list of tuples
profile.update([("salary", 75000), ("experience", 3)])

# Update from keyword arguments
profile.update(active=True, verified=True)
```

---

## ➖ Removing Items

### pop() - Remove and return value
```python
student = {"name": "Alice", "age": 20, "major": "CS", "gpa": 3.85}

# Remove specific key
gpa = student.pop("gpa")
print(f"Removed GPA: {gpa}")  # 3.85
print(student)  # gpa is gone

# pop() with default (if key doesn't exist)
grade = student.pop("grade", "N/A")
print(grade)  # "N/A" (no error)
```

### popitem() - Remove and return last inserted item
```python
student = {"name": "Alice", "age": 20, "major": "CS"}

# Remove last item (Python 3.7+)
key, value = student.popitem()
print(f"Removed: {key} = {value}")
```

### del - Delete specific key
```python
student = {"name": "Alice", "age": 20, "major": "CS"}

# Delete specific key
del student["age"]

# Delete entire dictionary
# del student  # Now student is undefined
```

### clear() - Remove all items
```python
student = {"name": "Alice", "age": 20, "major": "CS"}
student.clear()
print(student)  # {}
```

---

## 🔄 Dictionary Methods

### keys(), values(), items()
```python
product = {
    "id": 101,
    "name": "Laptop",
    "price": 999.99,
    "stock": 50
}

# Get all keys
keys = product.keys()
print(list(keys))  # ['id', 'name', 'price', 'stock']

# Get all values
values = product.values()
print(list(values))  # [101, 'Laptop', 999.99, 50]

# Get all key-value pairs
items = product.items()
print(list(items))
# [('id', 101), ('name', 'Laptop'), ('price', 999.99), ('stock', 50)]
```

### Iterating Over Dictionaries
```python
product = {"id": 101, "name": "Laptop", "price": 999.99}

# Iterate over keys (default)
for key in product:
    print(f"{key}: {product[key]}")

# Iterate over keys explicitly
for key in product.keys():
    print(key)

# Iterate over values
for value in product.values():
    print(value)

# Iterate over key-value pairs (best practice)
for key, value in product.items():
    print(f"{key}: {value}")
```

### copy() - Shallow Copy
```python
original = {"a": 1, "b": 2}
copy_dict = original.copy()

# Modify copy
copy_dict["a"] = 999

print(original)   # {'a': 1, 'b': 2} - unchanged
print(copy_dict)  # {'a': 999, 'b': 2}
```

### setdefault() - Get or Set Default Value
```python
config = {"host": "localhost", "port": 5432}

# Get existing key
host = config.setdefault("host", "127.0.0.1")
print(host)  # "localhost"

# Get non-existing key (sets default)
timeout = config.setdefault("timeout", 30)
print(timeout)  # 30
print(config)   # {'host': 'localhost', 'port': 5432, 'timeout': 30}
```

### fromkeys() - Create Dictionary from Keys
```python
# All values set to None
keys = ["name", "age", "city"]
person = dict.fromkeys(keys)
print(person)  # {'name': None, 'age': None, 'city': None}

# All values set to default
person = dict.fromkeys(keys, "Unknown")
print(person)  # {'name': 'Unknown', 'age': 'Unknown', 'city': 'Unknown'}
```

---

## 🔍 Checking Membership

```python
student = {"name": "Alice", "age": 20, "major": "CS"}

# Check if key exists
print("name" in student)      # True
print("grade" in student)     # False
print("grade" not in student) # True

# Check value (slower, searches all values)
print("Alice" in student.values())  # True

# Check key-value pair
print(("name", "Alice") in student.items())  # True
```

---

## 📚 Nested Dictionaries

Dictionaries can contain other dictionaries.

```python
# Company employees database
employees = {
    "E001": {
        "name": "Alice Johnson",
        "age": 30,
        "department": "Engineering",
        "salary": 85000,
        "skills": ["Python", "SQL", "AWS"]
    },
    "E002": {
        "name": "Bob Smith",
        "age": 28,
        "department": "Marketing",
        "salary": 65000,
        "skills": ["SEO", "Analytics"]
    },
    "E003": {
        "name": "Carol White",
        "age": 35,
        "department": "Engineering",
        "salary": 95000,
        "skills": ["Java", "Docker", "Kubernetes"]
    }
}

# Access nested data
alice_salary = employees["E001"]["salary"]
print(f"Alice's salary: ${alice_salary:,}")

alice_skills = employees["E001"]["skills"]
print(f"Alice's skills: {', '.join(alice_skills)}")

# Iterate over nested dictionary
for emp_id, details in employees.items():
    print(f"\nEmployee ID: {emp_id}")
    print(f"  Name: {details['name']}")
    print(f"  Department: {details['department']}")
    print(f"  Salary: ${details['salary']:,}")
```

---

## 🎨 Dictionary Comprehensions

Create dictionaries using concise syntax.

### Basic Syntax
```python
# {key_expression: value_expression for item in iterable}

# Squares
squares = {num: num**2 for num in range(1, 6)}
print(squares)  # {1: 1, 2: 4, 3: 9, 4: 16, 5: 25}
```

### With Conditions
```python
# Even squares only
even_squares = {num: num**2 for num in range(1, 11) if num % 2 == 0}
print(even_squares)  # {2: 4, 4: 16, 6: 36, 8: 64, 10: 100}
```

### From Lists
```python
# Product names to IDs
products = ["Laptop", "Mouse", "Keyboard", "Monitor"]
product_ids = {product: idx + 1 for idx, product in enumerate(products)}
print(product_ids)
# {'Laptop': 1, 'Mouse': 2, 'Keyboard': 3, 'Monitor': 4}
```

### Transforming Dictionaries
```python
# Convert prices from dollars to euros
prices_usd = {"apple": 1.50, "banana": 0.75, "orange": 2.00}
exchange_rate = 0.85
prices_eur = {item: price * exchange_rate for item, price in prices_usd.items()}
print(prices_eur)
# {'apple': 1.275, 'banana': 0.6375, 'orange': 1.7}
```

### Filtering Dictionaries
```python
# Filter students with GPA >= 3.5
students = {
    "Alice": 3.8,
    "Bob": 3.2,
    "Carol": 3.9,
    "Dave": 3.0
}

honors = {name: gpa for name, gpa in students.items() if gpa >= 3.5}
print(honors)  # {'Alice': 3.8, 'Carol': 3.9}
```

---

## 📊 Practical Examples

### Example 1: Inventory Management
```python
# Product inventory
inventory = {
    "P001": {"name": "Laptop", "price": 999.99, "stock": 50},
    "P002": {"name": "Mouse", "price": 24.99, "stock": 200},
    "P003": {"name": "Keyboard", "price": 79.99, "stock": 150}
}

# Calculate total inventory value
total_value = 0
for product_id, details in inventory.items():
    item_value = details["price"] * details["stock"]
    total_value += item_value
    print(f"{details['name']}: ${item_value:,.2f}")

print(f"\nTotal Inventory Value: ${total_value:,.2f}")

# Find low stock items (< 100)
low_stock = {
    pid: details for pid, details in inventory.items() 
    if details["stock"] < 100
}
print(f"\nLow Stock Items: {len(low_stock)}")
```

### Example 2: Word Frequency Counter
```python
text = "the quick brown fox jumps over the lazy dog the fox was quick"
words = text.split()

# Count word frequency
word_count = {}
for word in words:
    word_count[word] = word_count.get(word, 0) + 1

# Display results
for word, count in sorted(word_count.items()):
    print(f"{word}: {count}")

# Using dictionary comprehension
word_count_v2 = {word: words.count(word) for word in set(words)}
```

### Example 3: Student Grade Book
```python
# Student grades
gradebook = {
    "Alice": [85, 90, 92, 88],
    "Bob": [78, 82, 85, 80],
    "Carol": [92, 95, 98, 96]
}

# Calculate averages
for student, grades in gradebook.items():
    average = sum(grades) / len(grades)
    print(f"{student}: {average:.2f}")

# Add new student
gradebook["Dave"] = [88, 86, 90, 87]

# Update grades
gradebook["Alice"].append(95)  # Add new grade

# Find top student
top_student = max(gradebook.items(), 
                  key=lambda x: sum(x[1])/len(x[1]))
print(f"\nTop Student: {top_student[0]}")
```

### Example 4: Configuration Management
```python
# Application configuration
config = {
    "database": {
        "host": "localhost",
        "port": 5432,
        "name": "mydb",
        "user": "admin"
    },
    "cache": {
        "enabled": True,
        "ttl": 3600
    },
    "logging": {
        "level": "INFO",
        "file": "app.log"
    }
}

# Access configuration
db_host = config["database"]["host"]
cache_enabled = config["cache"]["enabled"]

# Update configuration
config["database"]["port"] = 5433
config["logging"]["level"] = "DEBUG"

# Add new section
config["email"] = {
    "smtp_host": "smtp.gmail.com",
    "smtp_port": 587
}
```

---

## 🎓 Advanced Dictionary Patterns

### Merging Dictionaries

#### Method 1: update()
```python
dict1 = {"a": 1, "b": 2}
dict2 = {"c": 3, "d": 4}

dict1.update(dict2)
print(dict1)  # {'a': 1, 'b': 2, 'c': 3, 'd': 4}
```

#### Method 2: Unpacking (Python 3.5+)
```python
dict1 = {"a": 1, "b": 2}
dict2 = {"c": 3, "d": 4}
dict3 = {"e": 5}

merged = {**dict1, **dict2, **dict3}
print(merged)  # {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5}
```

#### Method 3: Union Operator (Python 3.9+)
```python
dict1 = {"a": 1, "b": 2}
dict2 = {"c": 3, "d": 4}

merged = dict1 | dict2
print(merged)  # {'a': 1, 'b': 2, 'c': 3, 'd': 4}
```

### defaultdict (Collections Module)
```python
from collections import defaultdict

# Automatically creates default value for missing keys
word_count = defaultdict(int)  # default value: 0

words = ["apple", "banana", "apple", "cherry", "banana"]
for word in words:
    word_count[word] += 1  # No need to check if key exists!

print(dict(word_count))
# {'apple': 2, 'banana': 2, 'cherry': 1}
```

### Counter (Collections Module)
```python
from collections import Counter

# Specialized dictionary for counting
words = ["apple", "banana", "apple", "cherry", "banana", "apple"]
word_count = Counter(words)

print(word_count)  # Counter({'apple': 3, 'banana': 2, 'cherry': 1})
print(word_count.most_common(2))  # [('apple', 3), ('banana', 2)]
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Using Mutable Objects as Keys
```python
# ❌ Wrong - list is mutable
# my_dict = {[1, 2]: "value"}  # TypeError

# ✅ Correct - use tuple instead
my_dict = {(1, 2): "value"}
```

### Mistake 2: Modifying Dictionary While Iterating
```python
data = {"a": 1, "b": 2, "c": 3}

# ❌ Wrong - RuntimeError
# for key in data:
#     if data[key] == 2:
#         del data[key]

# ✅ Correct - iterate over copy
for key in list(data.keys()):
    if data[key] == 2:
        del data[key]
```

### Mistake 3: Shallow Copy Issues
```python
original = {"a": 1, "b": [2, 3]}
shallow_copy = original.copy()

# Modifying nested mutable object affects both
shallow_copy["b"].append(4)
print(original["b"])  # [2, 3, 4] - changed!

# ✅ Use deepcopy for nested structures
import copy
deep_copy = copy.deepcopy(original)
deep_copy["b"].append(5)
print(original["b"])  # [2, 3, 4] - unchanged
```

---

## ✅ Key Takeaways

1. ✅ Dictionaries store key-value pairs
2. ✅ Keys must be unique and immutable
3. ✅ Values can be any type
4. ✅ Use get() for safe access
5. ✅ Use in to check key existence
6. ✅ Iterate with items() for key-value pairs
7. ✅ Dictionary comprehensions for concise creation
8. ✅ Nested dictionaries for complex data
9. ✅ Use defaultdict for auto-initialization
10. ✅ Use Counter for frequency counting

---

**Practice**: Complete Lab 03 - Working with Dictionaries

**Next Section**: 06_sets.md

**கற்க கசடற** - Learn Flawlessly

