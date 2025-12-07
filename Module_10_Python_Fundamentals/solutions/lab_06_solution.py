"""
Module 10 - Lab 06 Solution: Functions
=======================================
Complete solutions with explanations.

கற்க கசடற - Learn Flawlessly

Estimated Time: 60 minutes
Concepts: Function definition, parameters, return values, scope, docstrings
"""

# Part 1: Basic Functions (10 minutes)
print("Part 1: Basic Functions")
print("-" * 40)

def greet(name):
    """Simple greeting function."""
    return f"Hello, {name}!"

def calculate_area(length, width):
    """Calculate rectangle area."""
    return length * width

def is_even(number):
    """Check if number is even."""
    return number % 2 == 0

# Test functions
print(greet("Alice"))
print(f"Area of 5x3 rectangle: {calculate_area(5, 3)}")
print(f"Is 7 even? {is_even(7)}")
print(f"Is 10 even? {is_even(10)}")

print()

# Part 2: Default Parameters (10 minutes)
print("Part 2: Default Parameters")
print("-" * 40)

def greet_with_title(name, title="Mr."):
    """Greet with optional title."""
    return f"Hello, {title} {name}!"

def calculate_power(base, exponent=2):
    """Calculate power with default exponent 2."""
    return base ** exponent

def format_price(amount, currency="USD"):
    """Format price with currency."""
    symbols = {"USD": "$", "EUR": "€", "GBP": "£", "INR": "₹"}
    symbol = symbols.get(currency, currency)
    return f"{symbol}{amount:.2f}"

# Test with defaults
print(greet_with_title("Smith"))
print(greet_with_title("Smith", "Dr."))

print(f"3^2 = {calculate_power(3)}")
print(f"3^3 = {calculate_power(3, 3)}")

print(format_price(99.99))
print(format_price(99.99, "EUR"))
print(format_price(99.99, "INR"))

print()

# Part 3: *args and **kwargs (15 minutes)
print("Part 3: *args and **kwargs")
print("-" * 40)

def calculate_average(*numbers):
    """Calculate average of any number of arguments."""
    if not numbers:
        return 0
    return sum(numbers) / len(numbers)

def concatenate(*words, separator=" "):
    """Concatenate words with separator."""
    return separator.join(words)

def create_profile(name, age, **additional_info):
    """Create user profile with flexible attributes."""
    profile = {
        "name": name,
        "age": age
    }
    profile.update(additional_info)
    return profile

# Test *args
print(f"Average of 1,2,3: {calculate_average(1, 2, 3)}")
print(f"Average of 10,20,30,40,50: {calculate_average(10, 20, 30, 40, 50)}")

# Test with separator
print(concatenate("Python", "is", "awesome"))
print(concatenate("2024", "01", "15", separator="-"))

# Test **kwargs
profile1 = create_profile("Alice", 30, city="New York", job="Engineer")
profile2 = create_profile("Bob", 25, city="London", job="Designer", hobby="Photography")

print(f"\nProfile 1: {profile1}")
print(f"Profile 2: {profile2}")

print()

# Part 4: Lambda Functions (10 minutes)
print("Part 4: Lambda Functions")
print("-" * 40)

# Basic lambdas
square = lambda x: x ** 2
add = lambda x, y: x + y
is_adult = lambda age: age >= 18

print(f"Square of 5: {square(5)}")
print(f"Add 3 + 7: {add(3, 7)}")
print(f"Is age 20 adult? {is_adult(20)}")
print(f"Is age 15 adult? {is_adult(15)}")

# Lambda with map
numbers = [1, 2, 3, 4, 5]
squared = list(map(lambda x: x ** 2, numbers))
print(f"\nOriginal: {numbers}")
print(f"Squared: {squared}")

# Lambda with filter
evens = list(filter(lambda x: x % 2 == 0, numbers))
print(f"Evens: {evens}")

# Lambda with sorted
people = [
    {"name": "Alice", "age": 30},
    {"name": "Bob", "age": 25},
    {"name": "Charlie", "age": 35}
]
sorted_by_age = sorted(people, key=lambda p: p["age"])
print(f"\nSorted by age: {sorted_by_age}")

print()

# Part 5: Variable Scope (10 minutes)
print("Part 5: Variable Scope")
print("-" * 40)

# Global variable
global_var = "I'm global"

def scope_demo():
    """Demonstrate variable scope."""
    local_var = "I'm local"
    print(f"Inside function - global: {global_var}")
    print(f"Inside function - local: {local_var}")

scope_demo()
print(f"Outside function - global: {global_var}")
# print(local_var)  # Would cause NameError

# Modifying global
counter = 0

def increment():
    """Increment global counter."""
    global counter
    counter += 1
    return counter

print(f"\nInitial counter: {counter}")
print(f"After increment: {increment()}")
print(f"After increment: {increment()}")
print(f"After increment: {increment()}")

# Enclosing scope
def outer():
    """Outer function with nested function."""
    outer_var = "I'm in outer"
    
    def inner():
        """Access enclosing scope."""
        print(f"Inner function accessing: {outer_var}")
    
    inner()

outer()

print()

# Part 6: Docstrings and Type Hints (10 minutes)
print("Part 6: Docstrings and Type Hints")
print("-" * 40)

def calculate_bmi(weight: float, height: float) -> float:
    """
    Calculate Body Mass Index.
    
    Args:
        weight: Weight in kilograms
        height: Height in meters
    
    Returns:
        BMI value as float
    
    Example:
        >>> calculate_bmi(70, 1.75)
        22.86
    """
    return weight / (height ** 2)

def get_bmi_category(bmi: float) -> str:
    """
    Get BMI category based on value.
    
    Args:
        bmi: BMI value
    
    Returns:
        Category string: Underweight, Normal, Overweight, or Obese
    """
    if bmi < 18.5:
        return "Underweight"
    elif bmi < 25:
        return "Normal"
    elif bmi < 30:
        return "Overweight"
    else:
        return "Obese"

# Test with type hints
weight, height = 70, 1.75
bmi = calculate_bmi(weight, height)
category = get_bmi_category(bmi)

print(f"Weight: {weight}kg, Height: {height}m")
print(f"BMI: {bmi:.2f}")
print(f"Category: {category}")

# Access docstring
print(f"\nFunction docstring:")
print(calculate_bmi.__doc__)

print()

# Part 7: Practical Challenge - Temperature Converter (15 minutes)
print("Part 7: Practical Challenge - Temperature Converter")
print("-" * 40)

def celsius_to_fahrenheit(celsius: float) -> float:
    """
    Convert Celsius to Fahrenheit.
    Formula: F = C * 9/5 + 32
    """
    return celsius * 9/5 + 32

def fahrenheit_to_celsius(fahrenheit: float) -> float:
    """
    Convert Fahrenheit to Celsius.
    Formula: C = (F - 32) * 5/9
    """
    return (fahrenheit - 32) * 5/9

def celsius_to_kelvin(celsius: float) -> float:
    """
    Convert Celsius to Kelvin.
    Formula: K = C + 273.15
    """
    return celsius + 273.15

def kelvin_to_celsius(kelvin: float) -> float:
    """
    Convert Kelvin to Celsius.
    Formula: C = K - 273.15
    """
    return kelvin - 273.15

def convert_temperature(value: float, from_unit: str, to_unit: str) -> float:
    """
    Universal temperature converter.
    
    Args:
        value: Temperature value
        from_unit: Source unit ('C', 'F', or 'K')
        to_unit: Target unit ('C', 'F', or 'K')
    
    Returns:
        Converted temperature
    
    Raises:
        ValueError: If units are invalid
    """
    # Normalize units
    from_unit = from_unit.upper()
    to_unit = to_unit.upper()
    
    valid_units = ['C', 'F', 'K']
    if from_unit not in valid_units or to_unit not in valid_units:
        raise ValueError(f"Units must be one of {valid_units}")
    
    # Same unit
    if from_unit == to_unit:
        return value
    
    # Convert to Celsius first
    if from_unit == 'F':
        celsius = fahrenheit_to_celsius(value)
    elif from_unit == 'K':
        celsius = kelvin_to_celsius(value)
    else:
        celsius = value
    
    # Convert from Celsius to target
    if to_unit == 'F':
        return celsius_to_fahrenheit(celsius)
    elif to_unit == 'K':
        return celsius_to_kelvin(celsius)
    else:
        return celsius

def format_temperature(value: float, unit: str) -> str:
    """Format temperature with unit symbol."""
    symbols = {'C': '°C', 'F': '°F', 'K': 'K'}
    symbol = symbols.get(unit.upper(), unit)
    return f"{value:.2f}{symbol}"

# Test conversions
print("Temperature Conversions:")
print("-" * 40)

# Water freezing/boiling points
temps = [
    (0, 'C', 'F', "Water freezes"),
    (100, 'C', 'F', "Water boils"),
    (32, 'F', 'C', "Freezing point"),
    (98.6, 'F', 'C', "Body temperature"),
    (273.15, 'K', 'C', "Absolute zero offset"),
]

for value, from_u, to_u, description in temps:
    result = convert_temperature(value, from_u, to_u)
    from_str = format_temperature(value, from_u)
    to_str = format_temperature(result, to_u)
    print(f"{description:20} {from_str:10} = {to_str:10}")

# Comprehensive conversion table
print(f"\n{'Temperature':12} {'Celsius':>10} {'Fahrenheit':>12} {'Kelvin':>10}")
print("-" * 46)

test_temps_c = [-40, 0, 25, 37, 100]
for temp_c in test_temps_c:
    temp_f = convert_temperature(temp_c, 'C', 'F')
    temp_k = convert_temperature(temp_c, 'C', 'K')
    print(f"{'':<12} {temp_c:>9.2f}°C {temp_f:>11.2f}°F {temp_k:>9.2f}K")

print()

# ============================================================================
# Verification Code
# ============================================================================

def verify_lab_06():
    """Verify that all lab exercises are completed correctly."""
    print("\n" + "="*60)
    print("Lab 06 Verification")
    print("="*60)
    
    passed = 0
    total = 7
    
    # Test basic functions
    try:
        assert greet("Test") == "Hello, Test!", "Greet function wrong"
        assert calculate_area(10, 5) == 50, "Area calculation wrong"
        assert is_even(4) == True, "Even check wrong"
        assert is_even(5) == False, "Odd check wrong"
        
        print("✅ Basic functions - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Basic functions - FAILED: {e}")
    
    # Test default parameters
    try:
        assert "Mr. Smith" in greet_with_title("Smith"), "Default title wrong"
        assert "Dr. Smith" in greet_with_title("Smith", "Dr."), "Custom title wrong"
        assert calculate_power(2) == 4, "Default exponent wrong"
        assert calculate_power(2, 3) == 8, "Custom exponent wrong"
        
        print("✅ Default parameters - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Default parameters - FAILED: {e}")
    
    # Test *args
    try:
        assert calculate_average(1, 2, 3) == 2, "Average wrong"
        assert calculate_average(10, 20) == 15, "Average of 2 wrong"
        assert concatenate("A", "B", "C") == "A B C", "Concatenation wrong"
        
        print("✅ *args - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ *args - FAILED: {e}")
    
    # Test **kwargs
    try:
        profile = create_profile("Test", 25, city="NYC")
        assert profile["name"] == "Test", "Name wrong"
        assert profile["age"] == 25, "Age wrong"
        assert profile["city"] == "NYC", "Kwargs wrong"
        
        print("✅ **kwargs - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ **kwargs - FAILED: {e}")
    
    # Test lambda functions
    try:
        assert square(4) == 16, "Lambda square wrong"
        assert add(5, 3) == 8, "Lambda add wrong"
        assert is_adult(20) == True, "Lambda is_adult wrong"
        
        nums = [1, 2, 3]
        squared = list(map(lambda x: x**2, nums))
        assert squared == [1, 4, 9], "Map lambda wrong"
        
        print("✅ Lambda functions - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Lambda functions - FAILED: {e}")
    
    # Test scope
    try:
        # Global counter should work
        initial = counter
        increment()
        assert counter == initial + 1, "Global increment wrong"
        
        print("✅ Variable scope - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Variable scope - FAILED: {e}")
    
    # Test temperature converter
    try:
        # Freezing point
        assert abs(convert_temperature(0, 'C', 'F') - 32) < 0.01, "C to F wrong"
        assert abs(convert_temperature(32, 'F', 'C') - 0) < 0.01, "F to C wrong"
        
        # Boiling point
        assert abs(convert_temperature(100, 'C', 'F') - 212) < 0.01, "Boiling C to F wrong"
        
        # Kelvin
        assert abs(convert_temperature(0, 'C', 'K') - 273.15) < 0.01, "C to K wrong"
        assert abs(convert_temperature(273.15, 'K', 'C') - 0) < 0.01, "K to C wrong"
        
        # Same unit
        assert convert_temperature(100, 'C', 'C') == 100, "Same unit conversion wrong"
        
        # BMI functions
        bmi = calculate_bmi(70, 1.75)
        assert 22 < bmi < 23, f"BMI calculation wrong: {bmi}"
        assert get_bmi_category(bmi) == "Normal", "BMI category wrong"
        
        print("✅ Temperature converter - PASSED")
        passed += 1
    except (AssertionError, NameError) as e:
        print(f"❌ Temperature converter - FAILED: {e}")
    
    print("="*60)
    print(f"Score: {passed}/{total} ({passed/total*100:.0f}%)")
    print("="*60)
    
    if passed == total:
        print("🎉 Congratulations! All tests passed!")
        print("\n📚 Key Learnings:")
        print("  1. Functions encapsulate reusable code")
        print("  2. Default parameters provide flexibility")
        print("  3. *args accepts variable positional arguments")
        print("  4. **kwargs accepts variable keyword arguments")
        print("  5. Lambda functions are anonymous one-liners")
        print("  6. Scope determines variable accessibility")
        print("  7. Docstrings document function behavior")
        print("\n🚀 Next Steps:")
        print("  - Try Lab 07: Strings and Regex")
        print("  - Review Section 09: Functions")
        print("  - Practice writing reusable functions")
    else:
        print("📝 Keep practicing! Review the sections and try again.")

# Run verification
verify_lab_06()
