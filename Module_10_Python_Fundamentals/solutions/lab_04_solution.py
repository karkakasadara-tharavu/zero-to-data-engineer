"""
Module 10 - Lab 04 Solution: Control Flow and Conditionals
==========================================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: Conditionals, comparison operators, logical operators, nested if
"""

# Part 1: Basic Conditionals (10 minutes)
# ---------------------------------------
print("Part 1: Basic Conditionals")
print("-" * 40)

# Get user's age and check if they can vote (18+)
age = 25  # Example age
if age >= 18:
    print(f"Age {age}: Eligible to vote ✓")
else:
    print(f"Age {age}: Not eligible to vote ✗")

# Check if a number is positive, negative, or zero
number = -5
if number > 0:
    print(f"{number} is positive")
elif number < 0:
    print(f"{number} is negative")
else:
    print(f"{number} is zero")

# Check if a number is even or odd
num = 42
if num % 2 == 0:
    print(f"{num} is even")
else:
    print(f"{num} is odd")

# Check if a year is a leap year
year = 2024
is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
if is_leap:
    print(f"{year} is a leap year")
else:
    print(f"{year} is not a leap year")

# Explanation: Leap year logic
# - Divisible by 4: potential leap year
# - NOT divisible by 100: leap year (except...)
# - OR divisible by 400: leap year (exception to exception)
# Examples: 2000 (yes), 1900 (no), 2024 (yes)

print()

# Part 2: Comparison Operators (10 minutes)
# -----------------------------------------
print("Part 2: Comparison Operators")
print("-" * 40)

# Compare two numbers
a, b = 10, 20
if a > b:
    print(f"{a} is greater than {b}")
elif a < b:
    print(f"{a} is less than {b}")
else:
    print(f"{a} equals {b}")

# Check if a string is equal to another (case-insensitive)
str1 = "Hello"
str2 = "hello"
if str1.lower() == str2.lower():
    print(f"'{str1}' and '{str2}' are equal (case-insensitive)")
else:
    print(f"'{str1}' and '{str2}' are different")

# Check if a value is within a range (10-20 inclusive)
value = 15
if 10 <= value <= 20:  # Chained comparison - Python feature!
    print(f"{value} is within range [10, 20]")
else:
    print(f"{value} is outside range [10, 20]")

# Check if a list is empty
my_list = []
if len(my_list) == 0:  # Explicit check
    print("List is empty (explicit check)")
if not my_list:  # Pythonic way - uses truthiness
    print("List is empty (Pythonic check)")

print()

# Part 3: Logical Operators (15 minutes)
# --------------------------------------
print("Part 3: Logical Operators")
print("-" * 40)

# Check if a number is between 1 and 100 (inclusive) using and
num = 50
if num >= 1 and num <= 100:
    print(f"{num} is between 1 and 100")
else:
    print(f"{num} is outside range")

# Better way using chained comparison
if 1 <= num <= 100:
    print(f"{num} is in range [1, 100] (chained comparison)")

# Check if a character is a vowel using or
char = 'a'
if char in 'aeiouAEIOU':  # Best way - membership test
    print(f"'{char}' is a vowel")

# Alternative using or
if char == 'a' or char == 'e' or char == 'i' or char == 'o' or char == 'u':
    print(f"'{char}' is a vowel (verbose way)")

# Check if a number is NOT divisible by 3
num = 10
if not (num % 3 == 0):  # Using not
    print(f"{num} is not divisible by 3")
if num % 3 != 0:  # Better - direct comparison
    print(f"{num} is not divisible by 3 (cleaner)")

# Check login credentials
username = "admin"
password = "secret123"
correct_user = "admin"
correct_pass = "secret123"

if username == correct_user and password == correct_pass:
    print("✓ Login successful!")
else:
    print("✗ Login failed - invalid credentials")

# More detailed feedback
if username != correct_user:
    print("  Error: Invalid username")
if password != correct_pass:
    print("  Error: Invalid password")

print()

# Part 4: Ternary Operator (10 minutes)
# -------------------------------------
print("Part 4: Ternary Operator")
print("-" * 40)

# Assign 'adult' or 'minor' based on age
age = 20
status = 'adult' if age >= 18 else 'minor'
print(f"Age {age}: {status}")

# Explanation: Ternary operator syntax
# value_if_true if condition else value_if_false

# Get the maximum of two numbers
x, y = 15, 23
max_val = x if x > y else y
print(f"Maximum of {x} and {y}: {max_val}")

# Better: use built-in max()
print(f"Maximum (using max()): {max(x, y)}")

# Convert boolean to 'Yes'/'No' string
is_available = True
availability = 'Yes' if is_available else 'No'
print(f"Available: {availability}")

# Multiple ternary operators (use sparingly - can be confusing)
score = 85
grade = 'A' if score >= 90 else 'B' if score >= 80 else 'C' if score >= 70 else 'F'
print(f"Score {score}: Grade {grade}")

print()

# Part 5: Nested Conditionals (15 minutes)
# ----------------------------------------
print("Part 5: Nested Conditionals")
print("-" * 40)

# Grade calculator based on score
def calculate_grade(score):
    """Calculate letter grade from score."""
    if score < 0 or score > 100:
        return "Invalid score"
    elif score >= 90:
        return 'A'
    elif score >= 80:
        return 'B'
    elif score >= 70:
        return 'C'
    elif score >= 60:
        return 'D'
    else:
        return 'F'

scores = [95, 85, 75, 65, 55, 105, -5]
print("Grade Calculator:")
for s in scores:
    print(f"  Score {s}: {calculate_grade(s)}")

# Ticket pricing based on age
def calculate_ticket_price(age):
    """Calculate ticket price based on age."""
    if age < 0:
        return "Invalid age"
    elif age < 12:
        return 10  # Child
    elif age <= 64:
        return 20  # Adult
    else:
        return 15  # Senior (65+)

ages = [5, 10, 25, 50, 65, 75]
print("\nTicket Pricing:")
for a in ages:
    price = calculate_ticket_price(a)
    category = "Child" if a < 12 else "Senior" if a >= 65 else "Adult"
    print(f"  Age {a} ({category}): ${price}")

# BMI calculator and category
def calculate_bmi_category(weight_kg, height_m):
    """Calculate BMI and return category."""
    if weight_kg <= 0 or height_m <= 0:
        return "Invalid input", 0
    
    bmi = weight_kg / (height_m ** 2)
    
    if bmi < 18.5:
        category = "Underweight"
    elif bmi < 25:
        category = "Normal weight"
    elif bmi < 30:
        category = "Overweight"
    else:
        category = "Obese"
    
    return category, round(bmi, 1)

print("\nBMI Calculator:")
people = [
    (45, 1.60),   # Underweight
    (70, 1.75),   # Normal
    (85, 1.70),   # Overweight
    (110, 1.75),  # Obese
]

for weight, height in people:
    category, bmi = calculate_bmi_category(weight, height)
    print(f"  Weight: {weight}kg, Height: {height}m → BMI: {bmi} ({category})")

print()

# Part 6: Truthiness and Falsiness (10 minutes)
# ---------------------------------------------
print("Part 6: Truthiness and Falsiness")
print("-" * 40)

# Check if a list has items (using truthiness)
items = [1, 2, 3]
if items:  # Truthy - non-empty list
    print(f"List has {len(items)} items")
else:
    print("List is empty")

empty_list = []
if not empty_list:  # Falsy - empty list
    print("List is empty (falsy check)")

# Check if a string is not empty
text = "Hello"
if text:  # Truthy - non-empty string
    print(f"Text: '{text}'")

empty_text = ""
if not empty_text:  # Falsy - empty string
    print("Text is empty")

# Check if a number is non-zero
count = 5
if count:  # Truthy - non-zero
    print(f"Count: {count}")

zero_count = 0
if not zero_count:  # Falsy - zero
    print("Count is zero")

# Use short-circuit evaluation with or
default_name = "Guest"
user_name = None
name = user_name or default_name  # If user_name is falsy, use default
print(f"Welcome, {name}!")

# With actual value
user_name = "Alice"
name = user_name or default_name
print(f"Welcome, {name}!")

# Falsy values in Python
print("\nFalsy values:")
falsy_values = [False, None, 0, 0.0, '', [], {}, set()]
for val in falsy_values:
    print(f"  {repr(val):15} → bool({repr(val)}) = {bool(val)}")

print()

# Part 7: Practical Challenge - User Validation System (15 minutes)
# -----------------------------------------------------------------
print("Part 7: User Validation System")
print("-" * 40)

def validate_username(username):
    """Validate username (6-20 chars, alphanumeric)."""
    if not isinstance(username, str):
        return False, "Username must be a string"
    
    if len(username) < 6:
        return False, "Username too short (minimum 6 characters)"
    
    if len(username) > 20:
        return False, "Username too long (maximum 20 characters)"
    
    if not username.isalnum():
        return False, "Username must be alphanumeric (letters and numbers only)"
    
    return True, None

def validate_password(password):
    """Validate password (8+ chars, has upper, lower, digit)."""
    if not isinstance(password, str):
        return False, "Password must be a string"
    
    if len(password) < 8:
        return False, "Password too short (minimum 8 characters)"
    
    has_upper = any(c.isupper() for c in password)
    has_lower = any(c.islower() for c in password)
    has_digit = any(c.isdigit() for c in password)
    
    if not has_upper:
        return False, "Password must contain at least one uppercase letter"
    
    if not has_lower:
        return False, "Password must contain at least one lowercase letter"
    
    if not has_digit:
        return False, "Password must contain at least one digit"
    
    return True, None

def validate_email(email):
    """Validate email (contains @ and .)."""
    if not isinstance(email, str):
        return False, "Email must be a string"
    
    if '@' not in email:
        return False, "Email must contain @"
    
    if '.' not in email:
        return False, "Email must contain a dot (.)"
    
    # Basic check: @ before .
    at_pos = email.index('@')
    dot_pos = email.rindex('.')
    
    if at_pos >= dot_pos:
        return False, "Email format invalid (@ must come before last .)"
    
    if at_pos == 0:
        return False, "Email must have characters before @"
    
    if dot_pos == len(email) - 1:
        return False, "Email must have characters after last ."
    
    return True, None

def validate_age(age):
    """Validate age (13-120)."""
    if not isinstance(age, int):
        return False, "Age must be an integer"
    
    if age < 13:
        return False, "Age must be at least 13"
    
    if age > 120:
        return False, "Age must be 120 or less"
    
    return True, None

def validate_user(username, password, email, age):
    """Validate all user information."""
    errors = []
    
    valid, error = validate_username(username)
    if not valid:
        errors.append(f"Username: {error}")
    
    valid, error = validate_password(password)
    if not valid:
        errors.append(f"Password: {error}")
    
    valid, error = validate_email(email)
    if not valid:
        errors.append(f"Email: {error}")
    
    valid, error = validate_age(age)
    if not valid:
        errors.append(f"Age: {error}")
    
    is_valid = len(errors) == 0
    return is_valid, errors

# Test cases
print("Testing User Validation System:\n")

test_users = [
    ("john123", "Pass123word", "john@email.com", 25, True),
    ("ab", "Pass123", "john@email.com", 25, False),  # Username too short
    ("john123", "short", "john@email.com", 25, False),  # Password too short
    ("john123", "Pass123", "invalid-email", 25, False),  # Invalid email
    ("john123", "Pass123", "john@email.com", 10, False),  # Age too young
    ("validuser99", "SecureP@ss1", "user@domain.co.uk", 30, True),  # All valid
]

for i, (user, pwd, email, age, should_pass) in enumerate(test_users, 1):
    print(f"Test Case {i}:")
    print(f"  User: {user}, Age: {age}")
    is_valid, errors = validate_user(user, pwd, email, age)
    
    if is_valid:
        print("  ✓ All validations passed!")
    else:
        print(f"  ✗ {len(errors)} error(s) found:")
        for error in errors:
            print(f"    - {error}")
    
    # Verify test expectation
    if is_valid == should_pass:
        print("  ✓ Test result as expected")
    else:
        print(f"  ✗ Test failed! Expected: {should_pass}, Got: {is_valid}")
    
    print()

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_04():
    """Verify that all lab exercises are completed correctly."""
    print("="*60)
    print("Lab 04 Verification")
    print("="*60)
    
    passed = 0
    total = 7
    
    # Test validation functions
    try:
        # Valid username
        valid, _ = validate_username("john123")
        assert valid == True, "Valid username rejected"
        
        # Invalid username (too short)
        valid, msg = validate_username("ab")
        assert valid == False, "Short username accepted"
        assert "short" in msg.lower(), "Error message incorrect"
        
        print("✅ Username validation - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Username validation - FAILED: {e}")
    
    try:
        # Valid password
        valid, _ = validate_password("Pass123word")
        assert valid == True, "Valid password rejected"
        
        # Invalid password (too short)
        valid, msg = validate_password("short")
        assert valid == False, "Short password accepted"
        
        # No uppercase
        valid, msg = validate_password("password123")
        assert valid == False, "Password without uppercase accepted"
        
        print("✅ Password validation - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Password validation - FAILED: {e}")
    
    try:
        # Valid email
        valid, _ = validate_email("user@example.com")
        assert valid == True, "Valid email rejected"
        
        # Invalid email (no @)
        valid, _ = validate_email("invalid.email.com")
        assert valid == False, "Email without @ accepted"
        
        # Invalid email (no .)
        valid, _ = validate_email("user@example")
        assert valid == False, "Email without dot accepted"
        
        print("✅ Email validation - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Email validation - FAILED: {e}")
    
    try:
        # Valid age
        valid, _ = validate_age(25)
        assert valid == True, "Valid age rejected"
        
        # Too young
        valid, _ = validate_age(10)
        assert valid == False, "Underage accepted"
        
        # Too old
        valid, _ = validate_age(150)
        assert valid == False, "Excessive age accepted"
        
        print("✅ Age validation - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Age validation - FAILED: {e}")
    
    try:
        # Complete validation - all valid
        is_valid, errors = validate_user("john123", "Pass123word", "john@email.com", 25)
        assert is_valid == True, "Valid user rejected"
        assert len(errors) == 0, "Errors present for valid user"
        
        # Complete validation - all invalid
        is_valid, errors = validate_user("ab", "short", "bad-email", 10)
        assert is_valid == False, "Invalid user accepted"
        assert len(errors) >= 4, f"Not all errors detected (found {len(errors)}, expected 4)"
        
        print("✅ Complete validation - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Complete validation - FAILED: {e}")
    
    try:
        # Test helper functions
        grade = calculate_grade(85)
        assert grade == 'B', f"Grade calculation wrong: {grade}"
        
        price = calculate_ticket_price(25)
        assert price == 20, f"Ticket price wrong: {price}"
        
        category, bmi = calculate_bmi_category(70, 1.75)
        assert 22 <= bmi <= 23, f"BMI calculation wrong: {bmi}"
        assert category == "Normal weight", f"BMI category wrong: {category}"
        
        print("✅ Helper functions - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Helper functions - FAILED: {e}")
    except NameError as e:
        print(f"❌ Helper functions - FAILED: Function not defined")
    
    try:
        # Test truthiness understanding
        assert bool([1, 2, 3]) == True, "Non-empty list should be truthy"
        assert bool([]) == False, "Empty list should be falsy"
        assert bool("text") == True, "Non-empty string should be truthy"
        assert bool("") == False, "Empty string should be falsy"
        assert bool(5) == True, "Non-zero should be truthy"
        assert bool(0) == False, "Zero should be falsy"
        
        print("✅ Truthiness concepts - PASSED")
        passed += 1
    except AssertionError as e:
        print(f"❌ Truthiness concepts - FAILED: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. if/elif/else for decision making")
        print("  2. Comparison operators (==, !=, <, >, <=, >=)")
        print("  3. Logical operators (and, or, not)")
        print("  4. Ternary operator for concise conditions")
        print("  5. Nested conditionals for complex logic")
        print("  6. Truthiness - empty containers are falsy")
        print("  7. Input validation is critical for robust code")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 05: Loops and Iteration")
        print("  - Review Section 07: Conditionals")
        print("  - Practice more validation scenarios")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_04()
