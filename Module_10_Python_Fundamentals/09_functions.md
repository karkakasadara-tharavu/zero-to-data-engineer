# Functions in Python

## 🎯 Learning Objectives
- Understand what functions are and why they matter
- Define functions with def keyword
- Work with parameters and arguments
- Return values from functions
- Understand variable scope
- Use default arguments and keyword arguments
- Create and use docstrings

---

## 📝 What is a Function?

A **function** is a reusable block of code that performs a specific task. Functions help you:
- ✅ Avoid code repetition (DRY principle)
- ✅ Organize code into logical units
- ✅ Make code more readable and maintainable
- ✅ Test code in isolation

```python
# Without function (repetitive)
print("Welcome!")
print("=" * 40)

print("Welcome!")
print("=" * 40)

# With function (reusable)
def print_welcome():
    print("Welcome!")
    print("=" * 40)

print_welcome()  # Call once
print_welcome()  # Call again
```

---

## 🎯 Defining Functions

Use the `def` keyword to define a function.

### Basic Syntax
```python
def function_name():
    """Docstring: describes what function does"""
    # Function body
    print("Hello from function!")

# Call the function
function_name()
```

### Function Naming Conventions
```python
# ✅ Good names (snake_case, descriptive)
def calculate_total():
    pass

def send_email():
    pass

def is_valid_password():
    pass

# ❌ Bad names
def calc():  # Too short
    pass

def CalculateTotal():  # PascalCase (use for classes)
    pass

def x():  # Not descriptive
    pass
```

---

## 📥 Function Parameters

Parameters allow functions to accept input values.

### Single Parameter
```python
def greet(name):
    """Greet a person by name"""
    print(f"Hello, {name}!")

greet("Alice")   # Output: Hello, Alice!
greet("Bob")     # Output: Hello, Bob!
```

### Multiple Parameters
```python
def add_numbers(a, b):
    """Add two numbers and print result"""
    result = a + b
    print(f"{a} + {b} = {result}")

add_numbers(5, 3)    # Output: 5 + 3 = 8
add_numbers(10, 20)  # Output: 10 + 20 = 30
```

### Parameter vs Argument
```python
def greet(name):  # 'name' is a PARAMETER (in definition)
    print(f"Hello, {name}!")

greet("Alice")    # "Alice" is an ARGUMENT (when calling)
```

---

## 📤 Return Statement

Functions can send values back to the caller.

### Returning a Value
```python
def add_numbers(a, b):
    """Add two numbers and return result"""
    result = a + b
    return result  # Send value back

# Capture returned value
total = add_numbers(5, 3)
print(f"Total: {total}")  # Total: 8

# Use directly in expression
doubled = add_numbers(4, 6) * 2
print(f"Doubled: {doubled}")  # Doubled: 20
```

### Return vs Print
```python
def add_with_print(a, b):
    print(a + b)  # Just displays

def add_with_return(a, b):
    return a + b  # Returns value

# Can't use print result in calculations
# result = add_with_print(5, 3) * 2  # TypeError! (None * 2)

# Can use return value
result = add_with_return(5, 3) * 2  # ✅ Works! (8 * 2 = 16)
print(result)  # 16
```

### Returning Multiple Values
```python
def calculate_stats(numbers):
    """Calculate min, max, and average"""
    minimum = min(numbers)
    maximum = max(numbers)
    average = sum(numbers) / len(numbers)
    return minimum, maximum, average  # Returns tuple

# Unpack returned values
min_val, max_val, avg_val = calculate_stats([10, 20, 30, 40, 50])
print(f"Min: {min_val}, Max: {max_val}, Avg: {avg_val}")
# Output: Min: 10, Max: 50, Avg: 30.0
```

### Early Return
```python
def divide(a, b):
    """Divide two numbers"""
    if b == 0:
        return "Error: Division by zero"  # Early exit
    return a / b

print(divide(10, 2))  # 5.0
print(divide(10, 0))  # Error: Division by zero
```

### Return None (Implicitly)
```python
def greet(name):
    print(f"Hello, {name}!")
    # No return statement

result = greet("Alice")
print(result)  # None (default return value)
```

---

## 🎨 Default Arguments

Provide default values for parameters.

### Basic Default Arguments
```python
def greet(name="Guest"):
    """Greet a person (defaults to 'Guest')"""
    print(f"Hello, {name}!")

greet("Alice")  # Hello, Alice!
greet()         # Hello, Guest! (uses default)
```

### Multiple Default Arguments
```python
def create_user(name, age=18, country="USA"):
    """Create user with optional defaults"""
    print(f"Name: {name}")
    print(f"Age: {age}")
    print(f"Country: {country}")

create_user("Alice")                    # Uses all defaults for age and country
create_user("Bob", 25)                  # Provides age, uses default country
create_user("Carol", 30, "Canada")      # Provides all values
```

### Default Must Come After Non-Default
```python
# ❌ Wrong - default parameter before non-default
# def greet(name="Guest", age):  # SyntaxError!
#     pass

# ✅ Correct - default parameters at end
def greet(age, name="Guest"):
    print(f"{name} is {age} years old")
```

### Mutable Default Arguments (⚠️ Pitfall)
```python
# ❌ Dangerous - mutable default argument
def add_item(item, items=[]):  # ⚠️ List is mutable!
    items.append(item)
    return items

# Unexpected behavior!
list1 = add_item("apple")
print(list1)  # ['apple']

list2 = add_item("banana")
print(list2)  # ['apple', 'banana'] - UNEXPECTED!

# ✅ Correct - use None as default
def add_item(item, items=None):
    if items is None:
        items = []  # Create new list each time
    items.append(item)
    return items

list1 = add_item("apple")
print(list1)  # ['apple']

list2 = add_item("banana")
print(list2)  # ['banana'] - Expected!
```

---

## 🔑 Keyword Arguments

Specify arguments by parameter name.

### Using Keyword Arguments
```python
def create_profile(name, age, city, country):
    print(f"{name}, {age}, {city}, {country}")

# Positional arguments (order matters)
create_profile("Alice", 25, "NYC", "USA")

# Keyword arguments (order doesn't matter)
create_profile(name="Bob", age=30, city="LA", country="USA")
create_profile(city="Chicago", country="USA", name="Carol", age=28)

# Mix positional and keyword (positional must come first)
create_profile("Dave", 35, city="Boston", country="USA")
```

### Benefits of Keyword Arguments
```python
# Hard to understand (what do these mean?)
send_email("john@email.com", "Hi", True, False, 5)

# Clear and readable
send_email(
    to="john@email.com",
    subject="Hi",
    urgent=True,
    send_copy=False,
    retry_count=5
)
```

---

## 🌟 *args and **kwargs

Accept variable number of arguments.

### *args - Variable Positional Arguments
```python
def calculate_sum(*numbers):
    """Sum any number of arguments"""
    total = 0
    for num in numbers:
        total += num
    return total

print(calculate_sum(1, 2, 3))           # 6
print(calculate_sum(10, 20, 30, 40))    # 100
print(calculate_sum(5))                 # 5
```

### **kwargs - Variable Keyword Arguments
```python
def print_info(**details):
    """Print any keyword arguments"""
    for key, value in details.items():
        print(f"{key}: {value}")

print_info(name="Alice", age=25, city="NYC")
# Output:
# name: Alice
# age: 25
# city: NYC

print_info(product="Laptop", price=999, brand="Dell")
# Output:
# product: Laptop
# price: 999
# brand: Dell
```

### Combining Parameters
```python
def process_order(order_id, *items, **details):
    """
    order_id: required positional
    *items: optional positional arguments
    **details: optional keyword arguments
    """
    print(f"Order ID: {order_id}")
    print(f"Items: {items}")
    print(f"Details: {details}")

process_order(
    12345,
    "Laptop", "Mouse", "Keyboard",
    customer="Alice",
    shipping="Express",
    payment="Card"
)
# Output:
# Order ID: 12345
# Items: ('Laptop', 'Mouse', 'Keyboard')
# Details: {'customer': 'Alice', 'shipping': 'Express', 'payment': 'Card'}
```

### Parameter Order Rules
```python
# Correct order:
# 1. Positional parameters
# 2. *args
# 3. Keyword parameters
# 4. **kwargs

def my_function(a, b, *args, x=10, y=20, **kwargs):
    pass

# ❌ Wrong order will cause SyntaxError
# def bad_function(a, **kwargs, *args):  # SyntaxError!
#     pass
```

---

## 🔍 Variable Scope

Where variables can be accessed.

### Local Scope
```python
def my_function():
    x = 10  # Local variable
    print(x)

my_function()  # 10
# print(x)     # NameError: x not defined (outside function)
```

### Global Scope
```python
x = 10  # Global variable

def my_function():
    print(x)  # Can read global

my_function()  # 10
print(x)       # 10
```

### Modifying Global Variables
```python
counter = 0  # Global

def increment():
    global counter  # Declare we're using global
    counter += 1

increment()
print(counter)  # 1

increment()
print(counter)  # 2
```

### Local vs Global with Same Name
```python
x = "global"

def my_function():
    x = "local"  # Creates new local variable
    print(f"Inside: {x}")

my_function()      # Inside: local
print(f"Outside: {x}")  # Outside: global (unchanged)
```

### Nested Functions and nonlocal
```python
def outer():
    x = "outer"
    
    def inner():
        nonlocal x  # Refer to outer function's variable
        x = "inner"
        print(f"Inner: {x}")
    
    inner()
    print(f"Outer: {x}")  # Changed by inner()

outer()
# Output:
# Inner: inner
# Outer: inner
```

---

## 📚 Docstrings

Document what your functions do.

### Single-Line Docstring
```python
def calculate_area(radius):
    """Calculate area of circle given radius."""
    return 3.14159 * radius ** 2

# Access docstring
print(calculate_area.__doc__)
# Output: Calculate area of circle given radius.
```

### Multi-Line Docstring
```python
def divide(a, b):
    """
    Divide two numbers with error handling.
    
    Parameters:
        a (float): The dividend
        b (float): The divisor
    
    Returns:
        float: The quotient, or None if b is zero
    
    Example:
        >>> divide(10, 2)
        5.0
    """
    if b == 0:
        return None
    return a / b
```

### Google Style Docstring
```python
def calculate_discount(price, discount_percent, customer_type="Regular"):
    """
    Calculate discounted price based on customer type.
    
    Args:
        price (float): Original price of item
        discount_percent (float): Discount percentage (0-100)
        customer_type (str, optional): Customer tier. Defaults to "Regular".
    
    Returns:
        float: Final price after discount
    
    Raises:
        ValueError: If discount_percent is not between 0 and 100
    
    Examples:
        >>> calculate_discount(100, 10)
        90.0
        >>> calculate_discount(100, 20, "VIP")
        80.0
    """
    if not 0 <= discount_percent <= 100:
        raise ValueError("Discount must be between 0 and 100")
    
    discount = price * (discount_percent / 100)
    return price - discount
```

---

## 📊 Practical Examples

### Example 1: Temperature Converter
```python
def celsius_to_fahrenheit(celsius):
    """Convert Celsius to Fahrenheit"""
    fahrenheit = (celsius * 9/5) + 32
    return round(fahrenheit, 2)

def fahrenheit_to_celsius(fahrenheit):
    """Convert Fahrenheit to Celsius"""
    celsius = (fahrenheit - 32) * 5/9
    return round(celsius, 2)

# Test
print(f"0°C = {celsius_to_fahrenheit(0)}°F")     # 32.0°F
print(f"100°C = {celsius_to_fahrenheit(100)}°F") # 212.0°F
print(f"32°F = {fahrenheit_to_celsius(32)}°C")   # 0.0°C
```

### Example 2: Validate Email
```python
def is_valid_email(email):
    """
    Check if email format is valid.
    
    Args:
        email (str): Email address to validate
    
    Returns:
        bool: True if valid, False otherwise
    """
    if not email or '@' not in email:
        return False
    
    parts = email.split('@')
    if len(parts) != 2:
        return False
    
    username, domain = parts
    if not username or not domain:
        return False
    
    if '.' not in domain:
        return False
    
    return True

# Test
print(is_valid_email("alice@example.com"))    # True
print(is_valid_email("invalid.email"))        # False
print(is_valid_email("@example.com"))         # False
```

### Example 3: Calculate Statistics
```python
def calculate_statistics(numbers):
    """
    Calculate comprehensive statistics for list of numbers.
    
    Args:
        numbers (list): List of numeric values
    
    Returns:
        dict: Dictionary containing statistics
    """
    if not numbers:
        return None
    
    return {
        'count': len(numbers),
        'sum': sum(numbers),
        'min': min(numbers),
        'max': max(numbers),
        'mean': sum(numbers) / len(numbers),
        'range': max(numbers) - min(numbers)
    }

# Test
data = [10, 20, 30, 40, 50]
stats = calculate_statistics(data)

for key, value in stats.items():
    print(f"{key.capitalize()}: {value}")

# Output:
# Count: 5
# Sum: 150
# Min: 10
# Max: 50
# Mean: 30.0
# Range: 40
```

### Example 4: Shopping Cart
```python
def calculate_total(items, tax_rate=0.08, discount=0):
    """
    Calculate shopping cart total with tax and discount.
    
    Args:
        items (list): List of item prices
        tax_rate (float, optional): Tax rate as decimal. Defaults to 0.08.
        discount (float, optional): Discount amount. Defaults to 0.
    
    Returns:
        dict: Breakdown of costs
    """
    subtotal = sum(items)
    discount_amount = min(discount, subtotal)  # Can't discount more than subtotal
    after_discount = subtotal - discount_amount
    tax = after_discount * tax_rate
    total = after_discount + tax
    
    return {
        'subtotal': round(subtotal, 2),
        'discount': round(discount_amount, 2),
        'tax': round(tax, 2),
        'total': round(total, 2)
    }

# Test
cart = [29.99, 49.99, 15.99]
result = calculate_total(cart, discount=10)

print("Order Summary:")
print(f"Subtotal: ${result['subtotal']}")
print(f"Discount: -${result['discount']}")
print(f"Tax: ${result['tax']}")
print(f"Total: ${result['total']}")
```

### Example 5: Password Generator
```python
import random
import string

def generate_password(length=12, use_uppercase=True, use_digits=True, use_special=True):
    """
    Generate random password with specified requirements.
    
    Args:
        length (int, optional): Password length. Defaults to 12.
        use_uppercase (bool, optional): Include uppercase letters. Defaults to True.
        use_digits (bool, optional): Include digits. Defaults to True.
        use_special (bool, optional): Include special characters. Defaults to True.
    
    Returns:
        str: Generated password
    """
    # Start with lowercase letters
    characters = string.ascii_lowercase
    
    # Add optional character sets
    if use_uppercase:
        characters += string.ascii_uppercase
    if use_digits:
        characters += string.digits
    if use_special:
        characters += "!@#$%^&*()_+-=[]{}|"
    
    # Generate password
    password = ''.join(random.choice(characters) for _ in range(length))
    return password

# Test
print("Simple:", generate_password(8, False, False, False))
print("Complex:", generate_password(16))
print("No special:", generate_password(12, use_special=False))
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Forgetting return
```python
# ❌ Wrong - prints but doesn't return
def add(a, b):
    print(a + b)

result = add(5, 3)  # Prints 8
print(result * 2)   # TypeError! (None * 2)

# ✅ Correct
def add(a, b):
    return a + b

result = add(5, 3)
print(result * 2)   # 16
```

### Mistake 2: Modifying mutable default argument
```python
# ❌ Wrong
def add_item(item, items=[]):
    items.append(item)
    return items

# Each call affects the same list!
list1 = add_item("a")  # ['a']
list2 = add_item("b")  # ['a', 'b'] - UNEXPECTED!

# ✅ Correct
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

### Mistake 3: Confusing scope
```python
total = 0

# ❌ Wrong - forgot global keyword
def add_to_total(value):
    total += value  # UnboundLocalError!

# ✅ Correct
def add_to_total(value):
    global total
    total += value
```

---

## ✅ Key Takeaways

1. ✅ Functions make code reusable and organized
2. ✅ Use `def` to define functions
3. ✅ Parameters accept input, return sends output
4. ✅ Default arguments provide fallback values
5. ✅ Keyword arguments improve readability
6. ✅ `*args` for variable positional, `**kwargs` for variable keyword
7. ✅ Scope determines variable visibility
8. ✅ Document functions with docstrings
9. ✅ Return values enable function composition
10. ✅ Avoid mutable default arguments

---

**Practice**: Complete Lab 06 - Working with Functions

**Next Section**: 10_lambda_functions.md

**கற்க கசடற** - Learn Flawlessly

