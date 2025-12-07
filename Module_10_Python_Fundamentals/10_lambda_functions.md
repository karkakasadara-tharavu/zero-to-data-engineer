# Lambda Functions and Functional Programming

## 🎯 Learning Objectives
- Understand lambda (anonymous) functions
- Use lambda with map(), filter(), and reduce()
- Master list/dict/set comprehensions
- Apply functional programming concepts
- Know when to use lambda vs regular functions

---

## 📝 What is a Lambda Function?

A **lambda function** is a small anonymous function defined with the `lambda` keyword. It's a one-liner alternative to regular functions for simple operations.

### Syntax
```python
lambda arguments: expression
```

### Lambda vs Regular Function
```python
# Regular function
def add(a, b):
    return a + b

# Lambda function (equivalent)
add_lambda = lambda a, b: a + b

# Both work the same
print(add(5, 3))         # 8
print(add_lambda(5, 3))  # 8
```

---

## 🎯 Basic Lambda Examples

### Single Parameter
```python
# Square a number
square = lambda x: x ** 2
print(square(5))  # 25

# Double a number
double = lambda x: x * 2
print(double(10))  # 20

# Check if even
is_even = lambda x: x % 2 == 0
print(is_even(4))   # True
print(is_even(7))   # False
```

### Multiple Parameters
```python
# Add two numbers
add = lambda a, b: a + b
print(add(5, 3))  # 8

# Maximum of two numbers
maximum = lambda a, b: a if a > b else b
print(maximum(10, 20))  # 20

# Calculate area
area = lambda length, width: length * width
print(area(5, 3))  # 15
```

### No Parameters
```python
# Return constant
get_pi = lambda: 3.14159
print(get_pi())  # 3.14159

# Random greeting
import random
greet = lambda: random.choice(["Hello!", "Hi!", "Hey!"])
print(greet())
```

---

## 🗺️ map() Function

Apply function to each item in an iterable.

### Basic Usage
```python
# Square all numbers
numbers = [1, 2, 3, 4, 5]
squared = map(lambda x: x ** 2, numbers)
print(list(squared))  # [1, 4, 9, 16, 25]

# Convert to uppercase
words = ["hello", "world", "python"]
uppercase = map(lambda s: s.upper(), words)
print(list(uppercase))  # ['HELLO', 'WORLD', 'PYTHON']

# Multiple iterables
nums1 = [1, 2, 3]
nums2 = [10, 20, 30]
sums = map(lambda x, y: x + y, nums1, nums2)
print(list(sums))  # [11, 22, 33]
```

### Practical Examples
```python
# Convert strings to integers
str_numbers = ["1", "2", "3", "4", "5"]
int_numbers = list(map(int, str_numbers))
print(int_numbers)  # [1, 2, 3, 4, 5]

# Format prices
prices = [19.99, 29.99, 39.99]
formatted = list(map(lambda p: f"${p:.2f}", prices))
print(formatted)  # ['$19.99', '$29.99', '$39.99']

# Extract first character
words = ["apple", "banana", "cherry"]
first_chars = list(map(lambda w: w[0], words))
print(first_chars)  # ['a', 'b', 'c']
```

### map() vs List Comprehension
```python
numbers = [1, 2, 3, 4, 5]

# Using map()
squared_map = list(map(lambda x: x ** 2, numbers))

# Using list comprehension (more Pythonic)
squared_comp = [x ** 2 for x in numbers]

print(squared_map == squared_comp)  # True
```

---

## 🔍 filter() Function

Filter items based on condition (returns True/False).

### Basic Usage
```python
# Filter even numbers
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
evens = filter(lambda x: x % 2 == 0, numbers)
print(list(evens))  # [2, 4, 6, 8, 10]

# Filter long words
words = ["hi", "hello", "hey", "goodbye", "world"]
long_words = filter(lambda w: len(w) > 3, words)
print(list(long_words))  # ['hello', 'goodbye', 'world']

# Filter positive numbers
numbers = [5, -3, 8, -1, 0, 12, -7]
positives = filter(lambda x: x > 0, numbers)
print(list(positives))  # [5, 8, 12]
```

### Practical Examples
```python
# Filter adult ages
ages = [15, 22, 17, 30, 12, 45, 19]
adults = list(filter(lambda age: age >= 18, ages))
print(adults)  # [22, 30, 45, 19]

# Filter valid emails (simple check)
emails = ["john@example.com", "invalid", "alice@email.com", "@bad.com"]
valid = list(filter(lambda e: '@' in e and '.' in e, emails))
print(valid)  # ['john@example.com', 'alice@email.com']

# Remove empty strings
data = ["hello", "", "world", "", "python"]
non_empty = list(filter(lambda s: s != "", data))
# Or even simpler:
non_empty = list(filter(None, data))  # None removes falsy values
print(non_empty)  # ['hello', 'world', 'python']
```

### filter() vs List Comprehension
```python
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Using filter()
evens_filter = list(filter(lambda x: x % 2 == 0, numbers))

# Using list comprehension (more Pythonic)
evens_comp = [x for x in numbers if x % 2 == 0]

print(evens_filter == evens_comp)  # True
```

---

## 🔄 reduce() Function

Reduce sequence to single value by applying function cumulatively.

### Import and Basic Usage
```python
from functools import reduce

# Sum all numbers
numbers = [1, 2, 3, 4, 5]
total = reduce(lambda x, y: x + y, numbers)
print(total)  # 15 (1+2=3, 3+3=6, 6+4=10, 10+5=15)

# Find maximum
numbers = [5, 2, 8, 1, 9, 3]
maximum = reduce(lambda x, y: x if x > y else y, numbers)
print(maximum)  # 9

# Concatenate strings
words = ["Hello", " ", "World", "!"]
sentence = reduce(lambda x, y: x + y, words)
print(sentence)  # "Hello World!"
```

### With Initial Value
```python
# Sum with starting value
numbers = [1, 2, 3, 4, 5]
total = reduce(lambda x, y: x + y, numbers, 100)
print(total)  # 115 (100 + 1 + 2 + 3 + 4 + 5)

# Product of numbers
numbers = [2, 3, 4]
product = reduce(lambda x, y: x * y, numbers, 1)
print(product)  # 24 (1 * 2 * 3 * 4)
```

### Practical Examples
```python
from functools import reduce

# Flatten nested list
nested = [[1, 2], [3, 4], [5, 6]]
flat = reduce(lambda x, y: x + y, nested)
print(flat)  # [1, 2, 3, 4, 5, 6]

# Count characters
words = ["hello", "world", "python"]
total_chars = reduce(lambda x, y: x + len(y), words, 0)
print(total_chars)  # 16

# Build dictionary from list of tuples
pairs = [("a", 1), ("b", 2), ("c", 3)]
dictionary = reduce(
    lambda d, pair: {**d, pair[0]: pair[1]},
    pairs,
    {}
)
print(dictionary)  # {'a': 1, 'b': 2, 'c': 3}
```

---

## 🎨 Combining map(), filter(), and reduce()

### Chaining Operations
```python
from functools import reduce

# Data processing pipeline
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Filter evens → Square them → Sum them
result = reduce(
    lambda x, y: x + y,
    map(lambda x: x ** 2,
        filter(lambda x: x % 2 == 0, numbers))
)
print(result)  # 220 (2²+4²+6²+8²+10² = 4+16+36+64+100)

# More readable with list comprehension
result = sum(x ** 2 for x in numbers if x % 2 == 0)
print(result)  # 220
```

### Real-World Pipeline
```python
# Process sales data
sales = [
    {"item": "Laptop", "price": 999, "quantity": 2},
    {"item": "Mouse", "price": 25, "quantity": 5},
    {"item": "Keyboard", "price": 75, "quantity": 3}
]

# Calculate total revenue
# 1. Map: Calculate revenue per item
# 2. Reduce: Sum all revenues
from functools import reduce

revenues = map(lambda s: s["price"] * s["quantity"], sales)
total = reduce(lambda x, y: x + y, revenues)
print(f"Total Revenue: ${total:,}")  # Total Revenue: $2,348

# More Pythonic
total = sum(s["price"] * s["quantity"] for s in sales)
print(f"Total Revenue: ${total:,}")
```

---

## 📊 List Comprehensions (Alternative to map/filter)

More Pythonic way to create lists.

### Basic Syntax
```python
# [expression for item in iterable if condition]

# Square numbers (replaces map)
numbers = [1, 2, 3, 4, 5]
squared = [x ** 2 for x in numbers]
print(squared)  # [1, 4, 9, 16, 25]

# Filter evens (replaces filter)
evens = [x for x in numbers if x % 2 == 0]
print(evens)  # [2, 4]

# Combined: square even numbers
even_squares = [x ** 2 for x in numbers if x % 2 == 0]
print(even_squares)  # [4, 16]
```

### Nested Comprehensions
```python
# 2D matrix
matrix = [[i * j for j in range(1, 4)] for i in range(1, 4)]
print(matrix)
# [[1, 2, 3], [2, 4, 6], [3, 6, 9]]

# Flatten nested list
nested = [[1, 2], [3, 4], [5, 6]]
flat = [num for sublist in nested for num in sublist]
print(flat)  # [1, 2, 3, 4, 5, 6]

# All pairs
pairs = [(x, y) for x in range(3) for y in range(3) if x != y]
print(pairs)
# [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
```

---

## 🗂️ Dictionary Comprehensions

Create dictionaries concisely.

### Basic Syntax
```python
# {key_expr: value_expr for item in iterable}

# Square numbers
numbers = [1, 2, 3, 4, 5]
squares_dict = {num: num ** 2 for num in numbers}
print(squares_dict)
# {1: 1, 2: 4, 3: 9, 4: 16, 5: 25}

# Reverse dictionary
original = {"a": 1, "b": 2, "c": 3}
reversed_dict = {v: k for k, v in original.items()}
print(reversed_dict)
# {1: 'a', 2: 'b', 3: 'c'}
```

### With Conditions
```python
# Filter and transform
numbers = range(1, 11)
even_squares = {n: n**2 for n in numbers if n % 2 == 0}
print(even_squares)
# {2: 4, 4: 16, 6: 36, 8: 64, 10: 100}

# Conditional values
numbers = [1, 2, 3, 4, 5]
parity = {n: ("even" if n % 2 == 0 else "odd") for n in numbers}
print(parity)
# {1: 'odd', 2: 'even', 3: 'odd', 4: 'even', 5: 'odd'}
```

---

## 📦 Set Comprehensions

Create sets concisely.

```python
# {expression for item in iterable}

# Unique squares
numbers = [1, 2, 2, 3, 3, 4, 4, 5]
unique_squares = {x ** 2 for x in numbers}
print(unique_squares)  # {1, 4, 9, 16, 25}

# Unique first letters
words = ["apple", "avocado", "banana", "blueberry", "cherry"]
first_letters = {word[0] for word in words}
print(first_letters)  # {'a', 'b', 'c'}

# With condition
numbers = range(1, 21)
even_squares = {x ** 2 for x in numbers if x % 2 == 0}
print(even_squares)  # {4, 16, 36, 64, 100, 144, 196, 256, 324, 400}
```

---

## 🎯 When to Use Lambda vs Regular Functions

### Use Lambda When:
```python
# ✅ Simple, one-line operations
numbers = [1, 2, 3, 4, 5]
doubled = list(map(lambda x: x * 2, numbers))

# ✅ Sorting with custom key
students = [
    {"name": "Alice", "gpa": 3.8},
    {"name": "Bob", "gpa": 3.5},
    {"name": "Carol", "gpa": 3.9}
]
sorted_students = sorted(students, key=lambda s: s["gpa"], reverse=True)

# ✅ As callback in functional programming
from functools import reduce
product = reduce(lambda x, y: x * y, numbers)
```

### Use Regular Function When:
```python
# ✅ Complex logic (multiple lines)
def calculate_discount(price, customer_type):
    if customer_type == "VIP":
        return price * 0.20
    elif customer_type == "Premium":
        return price * 0.15
    else:
        return price * 0.05

# ✅ Reused in multiple places
def validate_email(email):
    # Complex validation logic
    return '@' in email and '.' in email.split('@')[1]

# ✅ Need docstring/documentation
def process_payment(amount, method):
    """
    Process payment with specified method.
    
    Args:
        amount (float): Payment amount
        method (str): Payment method (card/cash/online)
    
    Returns:
        dict: Transaction details
    """
    # Implementation
    pass
```

---

## 📚 Practical Examples

### Example 1: Data Transformation Pipeline
```python
# Raw data
transactions = [
    {"id": 1, "amount": 100, "type": "debit"},
    {"id": 2, "amount": 50, "type": "credit"},
    {"id": 3, "amount": 200, "type": "debit"},
    {"id": 4, "amount": 75, "type": "credit"},
]

# Filter credits → Extract amounts → Calculate total
from functools import reduce

credit_total = reduce(
    lambda x, y: x + y,
    map(lambda t: t["amount"],
        filter(lambda t: t["type"] == "credit", transactions))
)
print(f"Total Credits: ${credit_total}")  # Total Credits: $125

# More Pythonic
credit_total = sum(t["amount"] for t in transactions if t["type"] == "credit")
print(f"Total Credits: ${credit_total}")
```

### Example 2: Text Processing
```python
text = "  The Quick Brown Fox Jumps Over The Lazy Dog  "

# Clean and process text
words = (text
    .strip()                    # Remove whitespace
    .lower()                    # Convert to lowercase
    .split())                   # Split into words

# Remove short words and sort
processed = sorted(
    filter(lambda w: len(w) > 3, words),
    key=lambda w: len(w),
    reverse=True
)

print(processed)
# ['quick', 'brown', 'jumps', 'over', 'lazy']
```

### Example 3: Grade Calculator
```python
students = [
    {"name": "Alice", "scores": [85, 90, 92, 88]},
    {"name": "Bob", "scores": [78, 82, 85, 80]},
    {"name": "Carol", "scores": [92, 95, 98, 96]}
]

# Calculate averages and assign grades
def get_grade(avg):
    if avg >= 90: return "A"
    elif avg >= 80: return "B"
    elif avg >= 70: return "C"
    else: return "F"

# Add average and grade to each student
results = list(map(
    lambda s: {
        **s,
        "average": sum(s["scores"]) / len(s["scores"]),
        "grade": get_grade(sum(s["scores"]) / len(s["scores"]))
    },
    students
))

for student in results:
    print(f"{student['name']}: {student['average']:.1f} ({student['grade']})")

# Output:
# Alice: 88.8 (B)
# Bob: 81.2 (B)
# Carol: 95.2 (A)
```

### Example 4: Price Calculator with Discounts
```python
# Product catalog
products = [
    {"name": "Laptop", "price": 999, "category": "Electronics"},
    {"name": "Mouse", "price": 25, "category": "Electronics"},
    {"name": "Desk", "price": 299, "category": "Furniture"},
    {"name": "Chair", "price": 199, "category": "Furniture"},
]

# Apply category-specific discounts
discount_rules = {
    "Electronics": 0.15,  # 15% off
    "Furniture": 0.10     # 10% off
}

# Calculate discounted prices
discounted = list(map(
    lambda p: {
        **p,
        "discount": discount_rules.get(p["category"], 0),
        "final_price": p["price"] * (1 - discount_rules.get(p["category"], 0))
    },
    products
))

for product in discounted:
    print(f"{product['name']}: ${product['price']:.2f} → "
          f"${product['final_price']:.2f} "
          f"({product['discount']*100:.0f}% off)")

# Output:
# Laptop: $999.00 → $849.15 (15% off)
# Mouse: $25.00 → $21.25 (15% off)
# Desk: $299.00 → $269.10 (10% off)
# Chair: $199.00 → $179.10 (10% off)
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Complex lambda (use function instead)
```python
# ❌ Too complex for lambda
result = filter(lambda x: x > 0 and x < 100 and x % 2 == 0 and x % 3 != 0, numbers)

# ✅ Use regular function for readability
def is_valid(x):
    return x > 0 and x < 100 and x % 2 == 0 and x % 3 != 0

result = filter(is_valid, numbers)
```

### Mistake 2: Forgetting map/filter return iterators
```python
# ❌ Won't show values
numbers = [1, 2, 3]
squared = map(lambda x: x ** 2, numbers)
print(squared)  # <map object at 0x...>

# ✅ Convert to list
squared = list(map(lambda x: x ** 2, numbers))
print(squared)  # [1, 4, 9]
```

### Mistake 3: Overusing lambda when comprehension is clearer
```python
numbers = [1, 2, 3, 4, 5]

# ❌ Harder to read
result = list(filter(lambda x: x % 2 == 0, map(lambda x: x ** 2, numbers)))

# ✅ Clearer with comprehension
result = [x ** 2 for x in numbers if x % 2 == 0]
```

---

## ✅ Key Takeaways

1. ✅ Lambda functions are anonymous, one-line functions
2. ✅ `map()` applies function to each element
3. ✅ `filter()` selects elements based on condition
4. ✅ `reduce()` combines elements into single value
5. ✅ List comprehensions often clearer than map/filter
6. ✅ Dict/set comprehensions for creating dicts/sets
7. ✅ Use lambda for simple operations
8. ✅ Use regular functions for complex logic
9. ✅ Functional programming enables concise transformations
10. ✅ Comprehensions are more Pythonic than map/filter

---

**Practice**: Complete Lab 07 - Lambda and Functional Programming

**Next Section**: 11_strings.md

**கற்க கசடற** - Learn Flawlessly

