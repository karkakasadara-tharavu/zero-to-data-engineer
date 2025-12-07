# Working with Lists in Python

## 🎯 Learning Objectives
- Create and manipulate lists
- Access elements using indexing and slicing
- Use list methods (append, insert, remove, sort)
- Understand list comprehensions
- Work with nested lists

---

## 📝 What is a List?

A **list** is an ordered, mutable collection that can hold items of any type.

```python
# Creating lists
products = ["Laptop", "Mouse", "Keyboard"]
prices = [999.99, 29.99, 79.99]
mixed = [1, "Hello", 3.14, True]
empty_list = []
```

---

## 🔍 List Indexing

Lists use zero-based indexing.

```python
fruits = ["Apple", "Banana", "Cherry", "Date"]

# Positive indexing (from start)
print(fruits[0])   # Apple (first element)
print(fruits[1])   # Banana
print(fruits[3])   # Date (last element)

# Negative indexing (from end)
print(fruits[-1])  # Date (last element)
print(fruits[-2])  # Cherry (second from end)
print(fruits[-4])  # Apple (first element)

# Index out of range error
# print(fruits[10])  # IndexError!
```

---

## ✂️ List Slicing

Extract portions of a list using `[start:stop:step]`.

```python
numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

# Basic slicing [start:stop] - stop is exclusive
print(numbers[2:5])     # [2, 3, 4]
print(numbers[0:3])     # [0, 1, 2]

# Omitting start/stop
print(numbers[:4])      # [0, 1, 2, 3] (from beginning)
print(numbers[5:])      # [5, 6, 7, 8, 9] (to end)
print(numbers[:])       # [0,1,2,3,4,5,6,7,8,9] (full copy)

# Negative indices in slicing
print(numbers[-3:])     # [7, 8, 9] (last 3)
print(numbers[:-2])     # [0,1,2,3,4,5,6,7] (all except last 2)

# Step parameter
print(numbers[::2])     # [0, 2, 4, 6, 8] (every 2nd element)
print(numbers[1::2])    # [1, 3, 5, 7, 9] (odds)
print(numbers[::-1])    # [9,8,7,6,5,4,3,2,1,0] (reverse)
```

---

## ➕ Adding Elements

### append() - Add to end
```python
cart = ["Laptop"]
cart.append("Mouse")
cart.append("Keyboard")
print(cart)  # ["Laptop", "Mouse", "Keyboard"]
```

### insert() - Add at specific position
```python
cart = ["Laptop", "Keyboard"]
cart.insert(1, "Mouse")  # Insert at index 1
print(cart)  # ["Laptop", "Mouse", "Keyboard"]
```

### extend() - Add multiple elements
```python
cart = ["Laptop"]
new_items = ["Mouse", "Keyboard"]
cart.extend(new_items)
print(cart)  # ["Laptop", "Mouse", "Keyboard"]

# Alternative: using + operator
cart = ["Laptop"] + ["Mouse", "Keyboard"]
```

---

## ➖ Removing Elements

### remove() - Remove by value
```python
fruits = ["Apple", "Banana", "Cherry", "Banana"]
fruits.remove("Banana")  # Removes first occurrence
print(fruits)  # ["Apple", "Cherry", "Banana"]
```

### pop() - Remove by index (returns removed item)
```python
fruits = ["Apple", "Banana", "Cherry"]
removed = fruits.pop(1)  # Remove at index 1
print(removed)  # "Banana"
print(fruits)   # ["Apple", "Cherry"]

# pop() without argument removes last item
last = fruits.pop()
print(last)     # "Cherry"
```

### del - Delete by index or slice
```python
numbers = [0, 1, 2, 3, 4, 5]
del numbers[2]   # Delete index 2
print(numbers)   # [0, 1, 3, 4, 5]

del numbers[1:3] # Delete slice
print(numbers)   # [0, 4, 5]
```

### clear() - Remove all elements
```python
cart = ["Laptop", "Mouse"]
cart.clear()
print(cart)  # []
```

---

## 🔍 Finding Elements

### in operator - Check existence
```python
fruits = ["Apple", "Banana", "Cherry"]

print("Apple" in fruits)    # True
print("Grape" in fruits)    # False
print("Grape" not in fruits) # True
```

### index() - Find position
```python
fruits = ["Apple", "Banana", "Cherry", "Banana"]

position = fruits.index("Banana")  # First occurrence
print(position)  # 1

# Raises ValueError if not found
# position = fruits.index("Grape")  # ValueError!
```

### count() - Count occurrences
```python
numbers = [1, 2, 3, 2, 4, 2, 5]
count = numbers.count(2)
print(count)  # 3
```

---

## 🔄 Modifying Lists

### Changing elements
```python
prices = [10.99, 20.99, 30.99]
prices[1] = 25.99  # Change single element
print(prices)  # [10.99, 25.99, 30.99]

prices[0:2] = [15.99, 35.99]  # Change slice
print(prices)  # [15.99, 35.99, 30.99]
```

### sort() - Sort in place
```python
numbers = [3, 1, 4, 1, 5]
numbers.sort()  # Ascending order
print(numbers)  # [1, 1, 3, 4, 5]

numbers.sort(reverse=True)  # Descending
print(numbers)  # [5, 4, 3, 1, 1]

# For strings
names = ["Charlie", "Alice", "Bob"]
names.sort()
print(names)  # ["Alice", "Bob", "Charlie"]
```

### sorted() - Return sorted copy (doesn't modify original)
```python
numbers = [3, 1, 4]
sorted_nums = sorted(numbers)
print(numbers)      # [3, 1, 4] (unchanged)
print(sorted_nums)  # [1, 3, 4] (new list)
```

### reverse() - Reverse in place
```python
numbers = [1, 2, 3]
numbers.reverse()
print(numbers)  # [3, 2, 1]
```

---

## 📊 List Operations

### len() - Get length
```python
fruits = ["Apple", "Banana", "Cherry"]
print(len(fruits))  # 3
```

### sum(), min(), max() - For numeric lists
```python
prices = [10.99, 20.99, 30.99]
print(sum(prices))  # 62.97
print(min(prices))  # 10.99
print(max(prices))  # 30.99
```

### Concatenation and repetition
```python
list1 = [1, 2, 3]
list2 = [4, 5, 6]

# Concatenation
combined = list1 + list2
print(combined)  # [1, 2, 3, 4, 5, 6]

# Repetition
repeated = [0] * 5
print(repeated)  # [0, 0, 0, 0, 0]
```

---

## 🚀 List Comprehensions

Create new lists based on existing lists (elegant and fast!).

### Basic syntax: `[expression for item in list]`

```python
# Traditional way
squares = []
for x in range(5):
    squares.append(x ** 2)
print(squares)  # [0, 1, 4, 9, 16]

# List comprehension way (BETTER!)
squares = [x ** 2 for x in range(5)]
print(squares)  # [0, 1, 4, 9, 16]
```

### With condition: `[expression for item in list if condition]`

```python
# Even numbers only
numbers = [1, 2, 3, 4, 5, 6]
evens = [x for x in numbers if x % 2 == 0]
print(evens)  # [2, 4, 6]

# Prices above $50
prices = [25.99, 75.50, 100.00, 45.00]
expensive = [p for p in prices if p > 50]
print(expensive)  # [75.50, 100.00]
```

### With transformation
```python
# Convert to uppercase
names = ["alice", "bob", "charlie"]
upper_names = [name.upper() for name in names]
print(upper_names)  # ["ALICE", "BOB", "CHARLIE"]

# Apply discount
prices = [100, 200, 300]
discounted = [p * 0.9 for p in prices]
print(discounted)  # [90.0, 180.0, 270.0]
```

---

## 📦 Nested Lists

Lists can contain other lists (2D arrays, matrices).

```python
# 2D list (list of lists)
matrix = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]

# Accessing elements
print(matrix[0])      # [1, 2, 3] (first row)
print(matrix[0][0])   # 1 (first row, first column)
print(matrix[1][2])   # 6 (second row, third column)

# Real example: Sales data
sales = [
    ["Q1", 10000, 12000],
    ["Q2", 15000, 18000],
    ["Q3", 20000, 22000]
]

# Access Q2 sales
print(f"Quarter: {sales[1][0]}")
print(f"Sales: ${sales[1][1]}")
```

---

## 💡 Practical Examples

### Example 1: Shopping Cart

```python
# Initialize cart
cart = []

# Add items
cart.append({"name": "Laptop", "price": 999.99})
cart.append({"name": "Mouse", "price": 29.99})
cart.append({"name": "Keyboard", "price": 79.99})

# Calculate total
total = sum([item["price"] for item in cart])
print(f"Cart Total: ${total:.2f}")

# Remove item
cart.pop(1)  # Remove Mouse
print(f"Items in cart: {len(cart)}")
```

### Example 2: Data Filtering

```python
# Customer ages
ages = [25, 17, 45, 19, 65, 30, 16, 55]

# Filter adults
adults = [age for age in ages if age >= 18]
print(f"Adults: {adults}")

# Filter seniors
seniors = [age for age in ages if age >= 65]
print(f"Seniors: {seniors}")

# Average age of adults
avg_age = sum(adults) / len(adults)
print(f"Average adult age: {avg_age:.1f}")
```

### Example 3: Data Transformation

```python
# Raw sales data
sales_data = ["100", "200", "150", "300"]

# Convert to integers and calculate total
sales_integers = [int(x) for x in sales_data]
total_sales = sum(sales_integers)
print(f"Total Sales: ${total_sales}")

# Apply 10% tax
with_tax = [x * 1.10 for x in sales_integers]
print(f"With Tax: {with_tax}")
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Modifying list while iterating
```python
# ❌ Wrong
numbers = [1, 2, 3, 4, 5]
for num in numbers:
    if num % 2 == 0:
        numbers.remove(num)  # Can skip elements!

# ✅ Correct
numbers = [1, 2, 3, 4, 5]
numbers = [num for num in numbers if num % 2 != 0]
```

### Mistake 2: Shallow copy issues
```python
# ❌ Wrong - both refer to same list
list1 = [1, 2, 3]
list2 = list1
list2.append(4)
print(list1)  # [1, 2, 3, 4] - CHANGED!

# ✅ Correct - create copy
list1 = [1, 2, 3]
list2 = list1.copy()  # or list2 = list1[:]
list2.append(4)
print(list1)  # [1, 2, 3] - unchanged
```

---

## ✅ Key Takeaways

1. ✅ Lists are ordered, mutable collections
2. ✅ Use [0] for first element, [-1] for last
3. ✅ Slicing: [start:stop:step]
4. ✅ append() adds to end, insert() at position
5. ✅ remove() by value, pop() by index
6. ✅ List comprehensions are powerful and elegant
7. ✅ Always copy lists when you don't want to modify original

---

**Practice**: Complete Lab 02 - Lists and List Comprehensions

**Next Section**: 04_tuples.md

**கற்க கசடற** - Learn Flawlessly

