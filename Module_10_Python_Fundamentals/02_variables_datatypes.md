# Variables and Data Types in Python

## 🎯 Learning Objectives
- Understand Python variables and naming rules
- Work with basic data types (int, float, str, bool)
- Perform type conversion
- Use type hints for better code

---

## 📝 Variables

### What is a Variable?
A variable is a named container that stores a value in memory.

```python
# Variable assignment
name = "John"
age = 25
salary = 75000.50
is_engineer = True
```

### Variable Naming Rules

✅ **Valid names:**
```python
customer_name = "Alice"
customer2 = "Bob"
_private_var = 100
CustomerID = 12345
```

❌ **Invalid names:**
```python
2customer = "Invalid"  # Can't start with number
customer-name = "Invalid"  # No hyphens
class = "Invalid"  # Reserved keyword
```

### Naming Conventions (PEP 8)
```python
# Variables and functions: snake_case
customer_name = "John"
total_amount = 1000

# Constants: UPPER_SNAKE_CASE
MAX_RETRIES = 3
DATABASE_URL = "localhost"

# Classes: PascalCase (we'll learn later)
CustomerAccount = ...
```

---

## 🔢 Data Types

### 1. Integer (int)
Whole numbers without decimals.

```python
age = 25
quantity = -10
year = 2025

# Large numbers (no size limit in Python!)
population = 8000000000

# You can use underscores for readability
salary = 75_000  # Same as 75000
```

### 2. Float (float)
Numbers with decimals.

```python
price = 19.99
temperature = -5.5
pi = 3.14159

# Scientific notation
speed_of_light = 3e8  # 3 * 10^8
```

### 3. String (str)
Text data enclosed in quotes.

```python
# Single or double quotes
name = 'Alice'
city = "New York"

# Triple quotes for multi-line
description = """
This is a multi-line
string in Python
"""

# String concatenation
first_name = "John"
last_name = "Doe"
full_name = first_name + " " + last_name  # "John Doe"

# f-strings (formatted strings) - RECOMMENDED
age = 30
message = f"My name is {full_name} and I'm {age} years old"
print(message)
# Output: My name is John Doe and I'm 30 years old
```

### 4. Boolean (bool)
True or False values.

```python
is_active = True
has_permission = False

# Boolean from comparisons
age = 25
is_adult = age >= 18  # True

# Boolean from conditions
username = "admin"
is_admin = username == "admin"  # True
```

### 5. NoneType
Represents absence of value.

```python
result = None

# Checking for None
if result is None:
    print("No result yet")
```

---

## 🔄 Type Conversion

### Checking Types
```python
age = 25
print(type(age))  # <class 'int'>

name = "Alice"
print(type(name))  # <class 'str'>
```

### Converting Types

```python
# String to Integer
age_str = "25"
age_int = int(age_str)  # 25

# String to Float
price_str = "19.99"
price_float = float(price_str)  # 19.99

# Number to String
age = 25
age_str = str(age)  # "25"

# Integer to Float
quantity = 10
quantity_float = float(quantity)  # 10.0

# Float to Integer (truncates decimal)
price = 19.99
price_int = int(price)  # 19 (not rounded!)
```

### Common Type Conversion Errors

```python
# ❌ This will fail
age = int("twenty-five")  # ValueError: invalid literal

# ❌ This will fail
price = float("19.99$")  # ValueError: could not convert

# ✅ Handle carefully
try:
    age = int("25")
except ValueError:
    print("Invalid number format")
```

---

## 📐 Operators

### Arithmetic Operators

```python
a = 10
b = 3

# Basic operations
print(a + b)   # Addition: 13
print(a - b)   # Subtraction: 7
print(a * b)   # Multiplication: 30
print(a / b)   # Division: 3.333...
print(a // b)  # Floor division: 3
print(a % b)   # Modulus (remainder): 1
print(a ** b)  # Exponentiation: 1000
```

### Comparison Operators

```python
x = 10
y = 20

print(x == y)  # Equal: False
print(x != y)  # Not equal: True
print(x > y)   # Greater than: False
print(x < y)   # Less than: True
print(x >= y)  # Greater or equal: False
print(x <= y)  # Less or equal: True
```

### Logical Operators

```python
age = 25
has_license = True

# AND - both must be True
can_drive = age >= 18 and has_license  # True

# OR - at least one must be True
is_eligible = age >= 65 or age <= 18  # False

# NOT - reverses boolean
is_not_adult = not (age >= 18)  # False
```

### Assignment Operators

```python
x = 10

# Compound assignments
x += 5   # x = x + 5  → 15
x -= 3   # x = x - 3  → 12
x *= 2   # x = x * 2  → 24
x //= 4  # x = x // 4 → 6
```

---

## 💡 Type Hints (Python 3.5+)

Type hints make code more readable and help catch errors.

```python
# Basic type hints
name: str = "Alice"
age: int = 25
salary: float = 75000.50
is_active: bool = True

# Function with type hints
def calculate_bonus(salary: float, percentage: float) -> float:
    """Calculate bonus amount"""
    return salary * (percentage / 100)

# Type hints with None
def get_customer(id: int) -> str | None:
    """Returns customer name or None if not found"""
    if id == 1:
        return "Alice"
    return None
```

---

## 🎯 Practical Examples

### Example 1: Sales Calculator

```python
"""Calculate total sales with tax"""

# Input data
product_name: str = "Laptop"
price: float = 999.99
quantity: int = 3
tax_rate: float = 0.08  # 8%

# Calculations
subtotal: float = price * quantity
tax_amount: float = subtotal * tax_rate
total: float = subtotal + tax_amount

# Output
print(f"Product: {product_name}")
print(f"Price: ${price:.2f}")
print(f"Quantity: {quantity}")
print(f"Subtotal: ${subtotal:.2f}")
print(f"Tax (8%): ${tax_amount:.2f}")
print(f"Total: ${total:.2f}")

"""
Output:
Product: Laptop
Price: $999.99
Quantity: 3
Subtotal: $2999.97
Tax (8%): $239.99
Total: $3239.96
"""
```

### Example 2: Data Type Conversion

```python
"""Converting user input"""

# Simulating user input (normally from input())
age_input = "25"
salary_input = "75000.50"

# Convert to appropriate types
age = int(age_input)
salary = float(salary_input)

# Calculations
years_to_retirement = 65 - age
projected_savings = salary * years_to_retirement * 0.1

print(f"Age: {age}")
print(f"Years to retirement: {years_to_retirement}")
print(f"Projected 10% savings: ${projected_savings:,.2f}")
```

### Example 3: Boolean Logic

```python
"""Customer eligibility checker"""

age = 30
annual_income = 80000
credit_score = 720
has_loan = False

# Eligibility criteria
is_age_eligible = age >= 21 and age <= 65
is_income_eligible = annual_income >= 50000
is_credit_eligible = credit_score >= 650
is_not_defaulter = not has_loan

# Final eligibility
is_eligible = (is_age_eligible and 
               is_income_eligible and 
               is_credit_eligible and 
               is_not_defaulter)

print(f"Eligible for loan: {is_eligible}")

if is_eligible:
    print("✅ Application approved!")
else:
    print("❌ Application denied")
```

---

## 🔍 Common Mistakes

### Mistake 1: Uninitialized Variables
```python
# ❌ Wrong
print(customer_name)  # NameError: name 'customer_name' is not defined

# ✅ Correct
customer_name = "Alice"
print(customer_name)
```

### Mistake 2: Type Mismatch
```python
# ❌ Wrong
age = "25"
age + 5  # TypeError: can only concatenate str to str

# ✅ Correct
age = int("25")
age + 5  # 30
```

### Mistake 3: Variable Shadowing
```python
# ❌ Confusing
total = 100
def calculate():
    total = 50  # Different variable!
    return total

print(total)  # Still 100

# ✅ Better
total = 100
def calculate():
    new_total = 50
    return new_total
```

---

## ✅ Practice Exercises

### Exercise 1: Variable Assignment
Create variables for a customer:
- First name: "John"
- Last name: "Doe"
- Age: 35
- Annual salary: 85000.00
- Is employed: True

Print all variables with labels.

### Exercise 2: Calculations
Given: `price = 49.99`, `quantity = 7`, `discount_rate = 0.15`

Calculate:
- Subtotal
- Discount amount
- Final total

### Exercise 3: Type Conversions
Given string values: `"123"`, `"45.67"`, `"True"`

Convert them to appropriate types and perform:
- Add 10 to the integer
- Multiply the float by 2
- Negate the boolean

---

## 🎯 Key Takeaways

1. ✅ Variables store data in memory
2. ✅ Python has dynamic typing (no declaration needed)
3. ✅ Main types: int, float, str, bool, None
4. ✅ Use `type()` to check types
5. ✅ Use `int()`, `float()`, `str()` for conversion
6. ✅ Type hints improve code readability
7. ✅ Follow PEP 8 naming conventions

---

**Next Section**: 03_lists.md

**கற்க கசடற** - Learn Flawlessly

