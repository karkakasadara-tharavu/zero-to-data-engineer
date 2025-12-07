# Loops in Python

## 🎯 Learning Objectives
- Master for loops for iteration
- Understand while loops for repeated execution
- Use break, continue, and else with loops
- Work with range() function
- Iterate over sequences effectively
- Understand loop patterns and best practices

---

## 📝 What are Loops?

Loops allow you to execute code repeatedly. Python has two types of loops:
- **for loop** - Iterate over a sequence
- **while loop** - Repeat while condition is True

---

## 🔄 The for Loop

Iterate over sequences (lists, strings, ranges, etc.)

### Basic Syntax
```python
for variable in sequence:
    # Code to execute for each item
    print(variable)
```

### Iterating Over Lists
```python
fruits = ["apple", "banana", "cherry"]

for fruit in fruits:
    print(f"I like {fruit}")

# Output:
# I like apple
# I like banana
# I like cherry
```

### Iterating Over Strings
```python
word = "Python"

for letter in word:
    print(letter)

# Output:
# P
# y
# t
# h
# o
# n
```

### Iterating Over Dictionaries
```python
student = {"name": "Alice", "age": 20, "major": "CS"}

# Iterate over keys (default)
for key in student:
    print(f"{key}: {student[key]}")

# Iterate over keys explicitly
for key in student.keys():
    print(key)

# Iterate over values
for value in student.values():
    print(value)

# Iterate over key-value pairs (best practice)
for key, value in student.items():
    print(f"{key}: {value}")
```

---

## 🔢 The range() Function

Generate sequence of numbers for iteration.

### Syntax Variations
```python
# range(stop) - from 0 to stop-1
for i in range(5):
    print(i)  # 0, 1, 2, 3, 4

# range(start, stop) - from start to stop-1
for i in range(2, 7):
    print(i)  # 2, 3, 4, 5, 6

# range(start, stop, step) - with custom step
for i in range(0, 10, 2):
    print(i)  # 0, 2, 4, 6, 8

# Counting backwards
for i in range(10, 0, -1):
    print(i)  # 10, 9, 8, 7, 6, 5, 4, 3, 2, 1

# Negative numbers
for i in range(-5, 5):
    print(i)  # -5, -4, -3, -2, -1, 0, 1, 2, 3, 4
```

### Practical Examples with range()
```python
# Print multiplication table
number = 5
for i in range(1, 11):
    print(f"{number} x {i} = {number * i}")

# Sum of first 100 numbers
total = 0
for i in range(1, 101):
    total += i
print(f"Sum: {total}")  # 5050

# Generate list of squares
squares = []
for i in range(1, 11):
    squares.append(i ** 2)
print(squares)  # [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
```

---

## 📇 enumerate() - Loop with Index

Get both index and value while iterating.

```python
fruits = ["apple", "banana", "cherry"]

# Without enumerate (manual counter)
index = 0
for fruit in fruits:
    print(f"{index}: {fruit}")
    index += 1

# With enumerate (cleaner)
for index, fruit in enumerate(fruits):
    print(f"{index}: {fruit}")

# Output:
# 0: apple
# 1: banana
# 2: cherry

# Start index from 1
for index, fruit in enumerate(fruits, start=1):
    print(f"{index}. {fruit}")

# Output:
# 1. apple
# 2. banana
# 3. cherry
```

### Practical Use
```python
# Process files with line numbers
lines = ["First line", "Second line", "Third line"]

for line_num, line_text in enumerate(lines, start=1):
    print(f"Line {line_num}: {line_text}")

# Find index of specific item
students = ["Alice", "Bob", "Carol", "Dave"]
for idx, student in enumerate(students):
    if student == "Carol":
        print(f"Carol is at index {idx}")
        break
```

---

## 🔁 zip() - Iterate Multiple Sequences

Iterate over multiple sequences in parallel.

```python
names = ["Alice", "Bob", "Carol"]
ages = [25, 30, 28]
cities = ["NYC", "LA", "Chicago"]

# Zip sequences together
for name, age, city in zip(names, ages, cities):
    print(f"{name} is {age} years old and lives in {city}")

# Output:
# Alice is 25 years old and lives in NYC
# Bob is 30 years old and lives in LA
# Carol is 28 years old and lives in Chicago
```

### Different Length Sequences
```python
list1 = [1, 2, 3, 4, 5]
list2 = ['a', 'b', 'c']

# zip() stops at shortest sequence
for num, letter in zip(list1, list2):
    print(f"{num} - {letter}")

# Output:
# 1 - a
# 2 - b
# 3 - c
```

### Creating Dictionaries with zip()
```python
keys = ["name", "age", "city"]
values = ["Alice", 25, "NYC"]

# Create dictionary
person = dict(zip(keys, values))
print(person)
# {'name': 'Alice', 'age': 25, 'city': 'NYC'}
```

---

## 🔄 The while Loop

Repeat while condition is True.

### Basic Syntax
```python
count = 0

while count < 5:
    print(f"Count: {count}")
    count += 1

# Output:
# Count: 0
# Count: 1
# Count: 2
# Count: 3
# Count: 4
```

### User Input Loop
```python
# Keep asking until valid input
while True:
    age = input("Enter your age: ")
    if age.isdigit() and int(age) > 0:
        age = int(age)
        break
    print("Invalid input! Please enter a positive number.")

print(f"Your age is {age}")
```

### Countdown Timer
```python
import time

countdown = 5
while countdown > 0:
    print(f"{countdown}...")
    time.sleep(1)
    countdown -= 1

print("Blast off! 🚀")
```

### Game Loop Pattern
```python
game_running = True
score = 0

while game_running:
    action = input("Action (play/quit): ").lower()
    
    if action == "play":
        score += 10
        print(f"Score: {score}")
    elif action == "quit":
        game_running = False
        print(f"Game Over! Final Score: {score}")
    else:
        print("Invalid action")
```

---

## 🛑 break Statement

Exit loop immediately.

```python
# Search for item
numbers = [1, 3, 5, 7, 9, 2, 4, 6]

target = 7
for num in numbers:
    if num == target:
        print(f"Found {target}!")
        break
    print(f"Checking {num}...")

# Output:
# Checking 1...
# Checking 3...
# Checking 5...
# Found 7!
```

### break in while Loop
```python
# Prevent infinite loop
count = 0
while True:
    print(count)
    count += 1
    if count >= 5:
        break
```

### Multiple Break Conditions
```python
# User authentication with limited attempts
attempts = 0
max_attempts = 3

while attempts < max_attempts:
    password = input("Enter password: ")
    
    if password == "secret123":
        print("✅ Access granted!")
        break
    else:
        attempts += 1
        remaining = max_attempts - attempts
        if remaining > 0:
            print(f"❌ Wrong password. {remaining} attempts left.")
        else:
            print("🔒 Account locked!")
```

---

## ⏭️ continue Statement

Skip rest of current iteration, continue with next.

```python
# Skip even numbers
for i in range(1, 11):
    if i % 2 == 0:
        continue  # Skip to next iteration
    print(i)

# Output: 1, 3, 5, 7, 9 (only odd numbers)
```

### Filtering with continue
```python
# Process valid data only
data = [10, -5, 20, 0, 15, -8, 30]

print("Positive numbers:")
for num in data:
    if num <= 0:
        continue  # Skip non-positive numbers
    print(num)

# Output: 10, 20, 15, 30
```

### Skip Specific Conditions
```python
# Process all files except hidden ones
files = [".hidden", "data.txt", ".config", "report.pdf", ".cache"]

for filename in files:
    if filename.startswith('.'):
        continue  # Skip hidden files
    print(f"Processing: {filename}")

# Output:
# Processing: data.txt
# Processing: report.pdf
```

---

## 🔄 Loop else Clause

else block executes if loop completes without break.

```python
# Search with else clause
numbers = [1, 3, 5, 7, 9]
target = 4

for num in numbers:
    if num == target:
        print(f"Found {target}!")
        break
else:
    # Executes only if break was not called
    print(f"{target} not found in list")

# Output: 4 not found in list
```

### Practical Use - Validation
```python
# Check if list contains only positive numbers
numbers = [1, 5, 10, 15, 20]

for num in numbers:
    if num <= 0:
        print("Found non-positive number!")
        break
else:
    print("All numbers are positive!")

# Output: All numbers are positive!
```

### Prime Number Checker
```python
def is_prime(n):
    """Check if number is prime using for-else"""
    if n < 2:
        return False
    
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False  # Found divisor, not prime
    else:
        return True  # No divisor found, is prime

print(is_prime(17))  # True
print(is_prime(20))  # False
```

---

## 🎯 Nested Loops

Loops inside loops.

### Basic Nested Loop
```python
# Multiplication table
for i in range(1, 6):
    for j in range(1, 6):
        print(f"{i} x {j} = {i*j:2d}", end="  ")
    print()  # Newline after each row

# Output:
# 1 x 1 =  1  1 x 2 =  2  1 x 3 =  3  1 x 4 =  4  1 x 5 =  5
# 2 x 1 =  2  2 x 2 =  4  2 x 3 =  6  2 x 4 =  8  2 x 5 = 10
# ...
```

### Pattern Printing
```python
# Right triangle pattern
rows = 5
for i in range(1, rows + 1):
    for j in range(i):
        print("*", end="")
    print()

# Output:
# *
# **
# ***
# ****
# *****
```

### Iterating 2D List
```python
# Matrix traversal
matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]

for row in matrix:
    for value in row:
        print(value, end=" ")
    print()

# With indices
for i in range(len(matrix)):
    for j in range(len(matrix[i])):
        print(f"[{i}][{j}] = {matrix[i][j]}")
```

### Finding All Pairs
```python
# Find all pairs that sum to target
numbers = [1, 2, 3, 4, 5]
target_sum = 6

print(f"Pairs that sum to {target_sum}:")
for i in range(len(numbers)):
    for j in range(i + 1, len(numbers)):  # Start from i+1 to avoid duplicates
        if numbers[i] + numbers[j] == target_sum:
            print(f"{numbers[i]} + {numbers[j]} = {target_sum}")

# Output:
# 1 + 5 = 6
# 2 + 4 = 6
```

---

## 📚 List Comprehensions (Alternative to Loops)

Create lists in a single line.

### Basic List Comprehension
```python
# Traditional loop
squares = []
for i in range(1, 11):
    squares.append(i ** 2)

# List comprehension (one line)
squares = [i ** 2 for i in range(1, 11)]
print(squares)  # [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
```

### With Conditions
```python
# Even numbers only
evens = [i for i in range(20) if i % 2 == 0]
print(evens)  # [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

# Uppercase words longer than 3 chars
words = ["hi", "hello", "world", "python", "code"]
long_words = [word.upper() for word in words if len(word) > 3]
print(long_words)  # ['HELLO', 'WORLD', 'PYTHON', 'CODE']
```

### Nested List Comprehension
```python
# Create multiplication table
table = [[i * j for j in range(1, 6)] for i in range(1, 6)]

# Print formatted
for row in table:
    print(row)

# Output:
# [1, 2, 3, 4, 5]
# [2, 4, 6, 8, 10]
# [3, 6, 9, 12, 15]
# [4, 8, 12, 16, 20]
# [5, 10, 15, 20, 25]
```

---

## 📊 Practical Examples

### Example 1: Sum and Average
```python
numbers = [45, 32, 78, 91, 23, 67, 85]

# Calculate sum
total = 0
for num in numbers:
    total += num

average = total / len(numbers)
print(f"Sum: {total}")
print(f"Average: {average:.2f}")

# Using built-in functions (better)
print(f"Sum: {sum(numbers)}")
print(f"Average: {sum(numbers) / len(numbers):.2f}")
```

### Example 2: Find Maximum
```python
numbers = [45, 32, 78, 91, 23, 67, 85]

# Manual max finding
maximum = numbers[0]
for num in numbers:
    if num > maximum:
        maximum = num

print(f"Maximum: {maximum}")

# Using built-in max() (better)
print(f"Maximum: {max(numbers)}")
```

### Example 3: Count Occurrences
```python
text = "hello world hello python hello"
words = text.split()

# Count "hello"
count = 0
for word in words:
    if word == "hello":
        count += 1

print(f"'hello' appears {count} times")

# Using count() method (better)
print(f"'hello' appears {words.count('hello')} times")
```

### Example 4: Filter and Transform
```python
# Get squared values of positive numbers
numbers = [5, -3, 8, -1, 12, -7, 4]

positive_squares = []
for num in numbers:
    if num > 0:
        positive_squares.append(num ** 2)

print(positive_squares)  # [25, 64, 144, 16]

# Using list comprehension (better)
positive_squares = [num ** 2 for num in numbers if num > 0]
```

### Example 5: Inventory Report
```python
inventory = {
    "Laptop": {"price": 999, "stock": 5},
    "Mouse": {"price": 25, "stock": 50},
    "Keyboard": {"price": 75, "stock": 30},
    "Monitor": {"price": 350, "stock": 12}
}

total_value = 0
print("Inventory Report:")
print("-" * 50)

for product, details in inventory.items():
    item_value = details["price"] * details["stock"]
    total_value += item_value
    
    print(f"{product:12} | Price: ${details['price']:>6.2f} | "
          f"Stock: {details['stock']:>3} | Value: ${item_value:>8.2f}")

print("-" * 50)
print(f"Total Inventory Value: ${total_value:,.2f}")
```

### Example 6: Fibonacci Sequence
```python
# Generate first n Fibonacci numbers
n = 10
fibonacci = []

a, b = 0, 1
for _ in range(n):
    fibonacci.append(a)
    a, b = b, a + b

print(f"First {n} Fibonacci numbers:")
print(fibonacci)
# [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

### Example 7: Grade Statistics
```python
students = {
    "Alice": [85, 92, 88, 95],
    "Bob": [78, 81, 85, 80],
    "Carol": [92, 95, 88, 91],
    "Dave": [65, 70, 68, 72]
}

print("Student Grade Report:")
print("=" * 60)

for student, grades in students.items():
    average = sum(grades) / len(grades)
    highest = max(grades)
    lowest = min(grades)
    
    print(f"\n{student}:")
    print(f"  Grades: {grades}")
    print(f"  Average: {average:.2f}")
    print(f"  Highest: {highest}")
    print(f"  Lowest: {lowest}")
    
    if average >= 90:
        print(f"  Status: ⭐ Excellent!")
    elif average >= 80:
        print(f"  Status: ✅ Good")
    elif average >= 70:
        print(f"  Status: ⚠️ Fair")
    else:
        print(f"  Status: ❌ Needs Improvement")
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Infinite While Loop
```python
# ❌ Wrong - infinite loop (forgot to update counter)
# count = 0
# while count < 5:
#     print(count)
#     # Missing: count += 1

# ✅ Correct
count = 0
while count < 5:
    print(count)
    count += 1
```

### Mistake 2: Modifying List While Iterating
```python
numbers = [1, 2, 3, 4, 5]

# ❌ Wrong - modifying list during iteration
# for num in numbers:
#     if num % 2 == 0:
#         numbers.remove(num)  # Dangerous!

# ✅ Correct - iterate over copy
for num in numbers[:]:  # Slice creates copy
    if num % 2 == 0:
        numbers.remove(num)

# ✅ Better - list comprehension
numbers = [num for num in numbers if num % 2 != 0]
```

### Mistake 3: Using Wrong Loop Type
```python
# ❌ Inefficient - while loop with manual index
i = 0
fruits = ["apple", "banana", "cherry"]
while i < len(fruits):
    print(fruits[i])
    i += 1

# ✅ Better - for loop
for fruit in fruits:
    print(fruit)
```

### Mistake 4: Not Breaking Infinite Input Loop
```python
# ❌ Wrong - no exit condition
# while True:
#     value = input("Enter number: ")
#     print(value)
#     # No break statement!

# ✅ Correct
while True:
    value = input("Enter number (or 'quit'): ")
    if value.lower() == 'quit':
        break
    print(value)
```

---

## ✅ Key Takeaways

1. ✅ Use `for` loops to iterate over sequences
2. ✅ Use `while` loops for conditional repetition
3. ✅ `range()` generates number sequences
4. ✅ `enumerate()` provides index while looping
5. ✅ `zip()` combines multiple sequences
6. ✅ `break` exits loop immediately
7. ✅ `continue` skips to next iteration
8. ✅ `else` clause runs if loop completes normally
9. ✅ List comprehensions for concise list creation
10. ✅ Be careful with infinite loops and modifying during iteration

---

**Practice**: Complete Lab 05 - Mastering Loops

**Next Section**: 09_functions.md

**கற்க கசடற** - Learn Flawlessly

