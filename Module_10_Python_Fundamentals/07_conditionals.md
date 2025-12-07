# Conditional Statements in Python

## 🎯 Learning Objectives
- Understand conditional logic and decision-making
- Master if, elif, and else statements
- Work with comparison and logical operators
- Use nested conditions effectively
- Apply conditional expressions (ternary operator)
- Understand truthiness and falsiness in Python

---

## 📝 What are Conditional Statements?

Conditional statements allow your program to make decisions and execute different code based on conditions.

```python
# Basic structure
if condition:
    # Code runs if condition is True
    print("Condition is True!")
```

---

## 🔍 The if Statement

Execute code only when condition is True.

```python
age = 18

if age >= 18:
    print("You are an adult")
    print("You can vote")

print("This always prints")
```

**Output:**
```
You are an adult
You can vote
This always prints
```

---

## 🔀 The if-else Statement

Execute one block if True, another if False.

```python
age = 15

if age >= 18:
    print("You are an adult")
else:
    print("You are a minor")

print("Program continues...")
```

**Output:**
```
You are a minor
Program continues...
```

---

## 🎯 The if-elif-else Statement

Test multiple conditions in sequence.

```python
score = 85

if score >= 90:
    grade = "A"
elif score >= 80:
    grade = "B"
elif score >= 70:
    grade = "C"
elif score >= 60:
    grade = "D"
else:
    grade = "F"

print(f"Your grade is: {grade}")
```

**Output:**
```
Your grade is: B
```

**How it works:**
1. First condition checked: `score >= 90` → False, skip
2. Second condition checked: `score >= 80` → True, execute and exit
3. Remaining conditions not checked
4. else block runs only if all conditions are False

---

## ⚖️ Comparison Operators

Used to compare values.

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `==` | Equal to | `5 == 5` | `True` |
| `!=` | Not equal to | `5 != 3` | `True` |
| `>` | Greater than | `5 > 3` | `True` |
| `<` | Less than | `3 < 5` | `True` |
| `>=` | Greater than or equal | `5 >= 5` | `True` |
| `<=` | Less than or equal | `3 <= 5` | `True` |

```python
x = 10
y = 20

print(x == y)   # False
print(x != y)   # True
print(x > y)    # False
print(x < y)    # True
print(x >= 10)  # True
print(y <= 20)  # True
```

---

## 🔗 Logical Operators

Combine multiple conditions.

### and - Both conditions must be True
```python
age = 25
has_license = True

if age >= 18 and has_license:
    print("You can drive")
else:
    print("You cannot drive")
```

**Truth Table for `and`:**
| Condition 1 | Condition 2 | Result |
|-------------|-------------|--------|
| True | True | True |
| True | False | False |
| False | True | False |
| False | False | False |

### or - At least one condition must be True
```python
day = "Saturday"

if day == "Saturday" or day == "Sunday":
    print("It's the weekend!")
else:
    print("It's a weekday")
```

**Truth Table for `or`:**
| Condition 1 | Condition 2 | Result |
|-------------|-------------|--------|
| True | True | True |
| True | False | True |
| False | True | True |
| False | False | False |

### not - Inverts the condition
```python
is_raining = False

if not is_raining:
    print("You don't need an umbrella")
else:
    print("Take an umbrella")
```

**Truth Table for `not`:**
| Condition | Result |
|-----------|--------|
| True | False |
| False | True |

---

## 🎨 Combining Multiple Conditions

```python
age = 25
income = 50000
credit_score = 720

# Complex condition with and/or
if age >= 21 and (income >= 40000 or credit_score >= 700):
    print("Loan approved!")
else:
    print("Loan denied")

# Parentheses control order of evaluation
# Same as: age >= 21 AND (income >= 40000 OR credit_score >= 700)
```

### Order of Operations
1. `not` (highest precedence)
2. `and`
3. `or` (lowest precedence)

```python
# Without parentheses
result = True or False and False
print(result)  # True (because 'and' evaluated first)

# With parentheses
result = (True or False) and False
print(result)  # False
```

---

## 📊 Membership Operators

Check if value exists in a sequence.

### in - Value exists in sequence
```python
fruits = ["apple", "banana", "cherry"]

if "banana" in fruits:
    print("We have bananas!")

# Works with strings too
text = "Hello World"
if "World" in text:
    print("Found 'World'")

# Dictionary membership checks keys
user = {"name": "Alice", "age": 25}
if "name" in user:
    print("Name key exists")
```

### not in - Value doesn't exist
```python
colors = ["red", "green", "blue"]

if "yellow" not in colors:
    print("We don't have yellow")
```

---

## 🎯 Identity Operators

Check if variables refer to same object.

### is - Same object in memory
```python
x = [1, 2, 3]
y = x  # y points to same list as x
z = [1, 2, 3]  # z is a new list with same values

print(x is y)  # True (same object)
print(x is z)  # False (different objects)
print(x == z)  # True (same values)

# Common use: checking for None
value = None
if value is None:
    print("Value is None")
```

### is not - Different objects
```python
a = [1, 2]
b = [1, 2]

if a is not b:
    print("Different objects")  # This prints
```

---

## 🔄 Nested Conditionals

Conditionals inside other conditionals.

```python
age = 25
has_ticket = True
has_id = True

if age >= 18:
    print("Age requirement met")
    if has_ticket:
        print("Ticket verified")
        if has_id:
            print("✅ Entry granted!")
        else:
            print("❌ ID required")
    else:
        print("❌ Ticket required")
else:
    print("❌ Must be 18 or older")
```

**Better approach - flattened conditions:**
```python
age = 25
has_ticket = True
has_id = True

if age < 18:
    print("❌ Must be 18 or older")
elif not has_ticket:
    print("❌ Ticket required")
elif not has_id:
    print("❌ ID required")
else:
    print("✅ Entry granted!")
```

---

## 💡 Conditional Expressions (Ternary Operator)

One-line if-else for simple conditions.

### Syntax
```python
value_if_true if condition else value_if_false
```

### Examples
```python
# Traditional if-else
age = 20
if age >= 18:
    status = "Adult"
else:
    status = "Minor"

# Ternary operator (more concise)
status = "Adult" if age >= 18 else "Minor"
print(status)  # "Adult"

# More examples
temperature = 25
weather = "Hot" if temperature > 30 else "Pleasant"

score = 85
result = "Pass" if score >= 60 else "Fail"

x = 10
y = 20
max_value = x if x > y else y  # Simple max function
```

### Nested Ternary (use sparingly)
```python
score = 85

grade = "A" if score >= 90 else "B" if score >= 80 else "C" if score >= 70 else "F"
print(grade)  # "B"

# Better: use if-elif-else for readability
if score >= 90:
    grade = "A"
elif score >= 80:
    grade = "B"
elif score >= 70:
    grade = "C"
else:
    grade = "F"
```

---

## 🎭 Truthiness and Falsiness

Python evaluates non-boolean values as True or False.

### Falsy Values (evaluate to False)
```python
# These all evaluate to False:
if not None:
    print("None is falsy")

if not False:
    print("False is falsy")

if not 0:
    print("Zero is falsy")

if not 0.0:
    print("Zero float is falsy")

if not "":
    print("Empty string is falsy")

if not []:
    print("Empty list is falsy")

if not {}:
    print("Empty dict is falsy")

if not set():
    print("Empty set is falsy")
```

### Truthy Values (evaluate to True)
```python
# Everything else is truthy:
if True:
    print("True is truthy")

if 42:
    print("Non-zero numbers are truthy")

if "hello":
    print("Non-empty strings are truthy")

if [1, 2, 3]:
    print("Non-empty lists are truthy")

if {"key": "value"}:
    print("Non-empty dicts are truthy")
```

### Practical Use
```python
# Check if list has items
my_list = [1, 2, 3]

# Verbose way
if len(my_list) > 0:
    print("List has items")

# Pythonic way (using truthiness)
if my_list:
    print("List has items")

# Check if string is not empty
name = "Alice"
if name:
    print(f"Hello, {name}!")

# Default values
user_input = ""
display_name = user_input if user_input else "Guest"
print(f"Welcome, {display_name}!")
```

---

## 📚 Practical Examples

### Example 1: Grade Calculator
```python
def calculate_grade(score):
    """Determine letter grade from numeric score"""
    if score < 0 or score > 100:
        return "Invalid score"
    elif score >= 90:
        return "A"
    elif score >= 80:
        return "B"
    elif score >= 70:
        return "C"
    elif score >= 60:
        return "D"
    else:
        return "F"

# Test the function
print(calculate_grade(95))   # A
print(calculate_grade(85))   # B
print(calculate_grade(50))   # F
print(calculate_grade(105))  # Invalid score
```

### Example 2: Discount Calculator
```python
def calculate_discount(price, customer_type, quantity):
    """Calculate discount based on customer type and quantity"""
    discount = 0
    
    # Customer type discounts
    if customer_type == "VIP":
        discount = 0.20  # 20%
    elif customer_type == "Premium":
        discount = 0.15  # 15%
    elif customer_type == "Regular":
        discount = 0.05  # 5%
    
    # Bulk purchase additional discount
    if quantity >= 100:
        discount += 0.10
    elif quantity >= 50:
        discount += 0.05
    
    # Cap discount at 40%
    if discount > 0.40:
        discount = 0.40
    
    discount_amount = price * quantity * discount
    final_price = (price * quantity) - discount_amount
    
    return final_price, discount_amount

# Test
price, discount = calculate_discount(100, "VIP", 75)
print(f"Final Price: ${price:.2f}")
print(f"You saved: ${discount:.2f}")
```

### Example 3: Login Validator
```python
def validate_login(username, password, is_active, attempts):
    """Validate user login with multiple conditions"""
    
    if not username:
        return "Username is required"
    
    if not password:
        return "Password is required"
    
    if len(password) < 8:
        return "Password must be at least 8 characters"
    
    if attempts >= 3:
        return "Account locked due to too many failed attempts"
    
    if not is_active:
        return "Account is deactivated"
    
    # All checks passed
    return "Login successful"

# Test cases
print(validate_login("alice", "pass123456", True, 0))  # Login successful
print(validate_login("", "pass123456", True, 0))       # Username required
print(validate_login("bob", "short", True, 0))         # Password too short
print(validate_login("carol", "pass123456", True, 5))  # Account locked
```

### Example 4: Shipping Cost Calculator
```python
def calculate_shipping(weight, distance, is_express):
    """Calculate shipping cost based on weight, distance, and service"""
    
    # Base rate per kg
    if weight <= 1:
        base_rate = 5.00
    elif weight <= 5:
        base_rate = 3.50
    elif weight <= 10:
        base_rate = 2.50
    else:
        base_rate = 2.00
    
    # Distance multiplier
    if distance <= 50:
        distance_multiplier = 1.0
    elif distance <= 200:
        distance_multiplier = 1.5
    elif distance <= 500:
        distance_multiplier = 2.0
    else:
        distance_multiplier = 2.5
    
    # Calculate base cost
    shipping_cost = weight * base_rate * distance_multiplier
    
    # Express surcharge
    if is_express:
        shipping_cost *= 1.5
    
    # Minimum charge
    if shipping_cost < 10:
        shipping_cost = 10
    
    return round(shipping_cost, 2)

# Test
print(f"Shipping cost: ${calculate_shipping(3, 100, False)}")  # Standard
print(f"Express cost: ${calculate_shipping(3, 100, True)}")    # Express
```

### Example 5: Password Strength Checker
```python
def check_password_strength(password):
    """Check password strength and provide feedback"""
    
    if len(password) < 8:
        return "Weak: Password must be at least 8 characters"
    
    has_upper = any(c.isupper() for c in password)
    has_lower = any(c.islower() for c in password)
    has_digit = any(c.isdigit() for c in password)
    has_special = any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password)
    
    strength_count = sum([has_upper, has_lower, has_digit, has_special])
    
    if strength_count == 4 and len(password) >= 12:
        return "Very Strong: Excellent password!"
    elif strength_count >= 3 and len(password) >= 10:
        return "Strong: Good password"
    elif strength_count >= 2:
        return "Medium: Consider adding more variety"
    else:
        return "Weak: Add uppercase, numbers, and special characters"

# Test
print(check_password_strength("pass"))                    # Weak
print(check_password_strength("Password123"))             # Medium
print(check_password_strength("P@ssw0rd!2024"))          # Strong
print(check_password_strength("MyV3ry$tr0ng!P@ssw0rd"))  # Very Strong
```

---

## ⚠️ Common Pitfalls

### Mistake 1: Using = instead of ==
```python
x = 10

# ❌ Wrong - assignment, not comparison
# if x = 10:  # SyntaxError

# ✅ Correct
if x == 10:
    print("x is 10")
```

### Mistake 2: Floating Point Comparison
```python
# ❌ Problematic
a = 0.1 + 0.2
if a == 0.3:
    print("Equal")  # Might not print due to floating point precision!

# ✅ Better - use epsilon comparison
epsilon = 0.0001
if abs(a - 0.3) < epsilon:
    print("Equal enough")
```

### Mistake 3: Confusing is and ==
```python
# ❌ Wrong for value comparison
a = 1000
b = 1000
if a is b:  # May be False (different objects)
    print("Same")

# ✅ Correct for value comparison
if a == b:  # True (same value)
    print("Same value")

# ✅ Use 'is' only for None, True, False
if value is None:
    print("Value is None")
```

### Mistake 4: Redundant Comparisons
```python
is_active = True

# ❌ Redundant
if is_active == True:
    print("Active")

# ✅ Better (already boolean)
if is_active:
    print("Active")

# ❌ Redundant
if is_active == False:
    print("Not active")

# ✅ Better
if not is_active:
    print("Not active")
```

---

## ✅ Key Takeaways

1. ✅ Use `if`, `elif`, `else` for decision-making
2. ✅ Comparison operators: `==`, `!=`, `<`, `>`, `<=`, `>=`
3. ✅ Logical operators: `and`, `or`, `not`
4. ✅ Membership: `in`, `not in`
5. ✅ Identity: `is`, `is not` (use for `None`)
6. ✅ Ternary operator for simple conditions
7. ✅ Empty collections and 0 are falsy
8. ✅ Flatten nested conditions when possible
9. ✅ Use `==` for value comparison, `is` for identity
10. ✅ Leverage truthiness for cleaner code

---

**Practice**: Complete Lab 04 - Control Flow with Conditionals

**Next Section**: 08_loops.md

**கற்க கசடற** - Learn Flawlessly

